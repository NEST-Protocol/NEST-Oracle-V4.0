// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import "./interface/INestLedger.sol";
import "./interface/INestPriceFacade.sol";
import "./interface/INestRedeeming.sol";
import "./NestBase.sol";

/// @dev The contract is for redeeming nest token and getting ETH in return
contract NestRedeeming is NestBase, INestRedeeming {

    /// @dev Redeeming information
    struct RedeemInfo {
        
        // Redeem quota consumed
        // block.number * quotaPerBlock - quota
        uint128 quota;

        // Redeem threshold by circulation of ntoken, when this value equal to config.activeThreshold, 
        // redeeming is enabled without checking the circulation of the ntoken
        // When config.activeThreshold modified, it will check whether repo is enabled again 
        // according to the circulation
        uint32 threshold;
    }

    // Configuration
    Config _config;

    // Redeeming ledger
    mapping(address=>RedeemInfo) _redeemLedger;

    address _nestLedgerAddress;
    address _nestPriceFacadeAddress;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) public override {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            ,
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            ,
            //address ntokenMiningAddress
            ,
            //address nestPriceFacadeAddress
            _nestPriceFacadeAddress, 
            //address nestVoteAddress
            ,
            //address nestQueryAddress
            , 
            //address nnIncomeAddress
            ,
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Redeem ntoken for ethers
    /// @notice Eth fee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeem(address ntokenAddress, uint amount, address paybackAddress) external payable override {
        
        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeeming stat
        RedeemInfo storage redeemInfo = _redeemLedger[ntokenAddress];
        RedeemInfo memory ri = redeemInfo;
        if (ri.threshold != config.activeThreshold) {
            // Since nest has started redeeming and has a large circulation, 
            // we will not check its circulation separately here
            require(
                IERC20(ntokenAddress).totalSupply() >= uint(config.activeThreshold) * 10000 ether, 
                "NestRedeeming:!totalSupply"
            );
            redeemInfo.threshold = config.activeThreshold;
        }

        // 3. Query price
        (
            /* uint latestPriceBlockNumber */, 
            uint latestPriceValue,
            /* uint triggeredPriceBlockNumber */,
            /* uint triggeredPriceValue */,
            uint triggeredAvgPrice,
            /* uint triggeredSigma */
        ) = INestPriceFacade(_nestPriceFacadeAddress).latestPriceAndTriggeredPriceInfo { 
            value: msg.value
        } (ntokenAddress, paybackAddress);

        // 4. Calculate the number of eth that can be exchanged for redeem
        uint value = amount * 1 ether / latestPriceValue;

        // 5. Calculate redeem quota
        (uint quota, uint scale) = _quotaOf(config, ri, ntokenAddress);
        redeemInfo.quota = uint128(scale - (quota - amount));

        // 6. Check the redeeming amount and price deviation
        // This check is not required
        // require(quota >= amount, "NestRedeeming:!amount");
        require(
            latestPriceValue * 10000 <= triggeredAvgPrice * (10000 + uint(config.priceDeviationLimit)) && 
            latestPriceValue * 10000 >= triggeredAvgPrice * (10000 - uint(config.priceDeviationLimit)), 
            "NestRedeeming:!price"
        );
        
        // 7. Ntoken transferred to redeem
        address nestLedgerAddress = _nestLedgerAddress;
        TransferHelper.safeTransferFrom(ntokenAddress, msg.sender, nestLedgerAddress, amount);
        
        // 8. Settlement
        // If a token is not a real token, it should also have no funds in the account book and cannot complete the 
        // settlement. Therefore, it is no longer necessary to check whether the token is a legal token
        INestLedger(nestLedgerAddress).pay(ntokenAddress, address(0), msg.sender, value);
    }

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) public view override returns (uint) {

        // 1. Load configuration
        Config memory config = _config;

        // 2. Check redeem state
        RedeemInfo storage redeemInfo = _redeemLedger[ntokenAddress];
        RedeemInfo memory ri = redeemInfo;
        if (ri.threshold != config.activeThreshold) {
            // Since nest has started redeeming and has a large circulation, we will not check its circulation 
            // separately here
            if (IERC20(ntokenAddress).totalSupply() < uint(config.activeThreshold) * 10000 ether) 
            {
                return 0;
            }
        }

        // 3. Calculate redeem quota
        (uint quota, ) = _quotaOf(config, ri, ntokenAddress);
        return quota;
    }

    // Calculate redeem quota
    function _quotaOf(
        Config memory config, 
        RedeemInfo memory ri, 
        address ntokenAddress
    ) private view returns (
        uint quota, 
        uint scale
    ) {

        // Calculate redeem quota
        uint quotaPerBlock;
        uint quotaLimit;
        // nest config
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            quotaPerBlock = uint(config.nestPerBlock);
            quotaLimit = uint(config.nestLimit);
        } 
        // ntoken config
        else {
            quotaPerBlock = uint(config.ntokenPerBlock);
            quotaLimit = uint(config.ntokenLimit);
        }
        // Calculate
        scale = block.number * quotaPerBlock * 1 ether;
        quota = scale - ri.quota;
        if (quota > quotaLimit * 1 ether) {
            quota = quotaLimit * 1 ether;
        }
    }
}