// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./NestBase.sol";

/// @dev The contract is for nest builtin contract address mapping
abstract contract NestMapping is NestBase, INestMapping {

    /// @dev Address of nest token contract
    address _nestTokenAddress;

    /// @dev Address of nest node contract
    address _nestNodeAddress;

    /// @dev INestLedger implementation contract address
    address _nestLedgerAddress;

    /// @dev INestMining implementation contract address for nest
    address _nestMiningAddress;

    /// @dev INestMining implementation contract address for ntoken
    address _ntokenMiningAddress;

    /// @dev INestPriceFacade implementation contract address
    address _nestPriceFacadeAddress;

    /// @dev INestVote implementation contract address
    address _nestVoteAddress;

    /// @dev INestQuery implementation contract address
    address _nestQueryAddress;

    /// @dev NNIncome contract address
    address _nnIncomeAddress;

    /// @dev INTokenController implementation contract address
    address _nTokenControllerAddress;
    
    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implementation contract address
    /// @param nestMiningAddress INestMining implementation contract address for nest
    /// @param ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @param nestVoteAddress INestVote implementation contract address
    /// @param nestQueryAddress INestQuery implementation contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implementation contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external override onlyGovernance {
        
        if (nestTokenAddress != address(0)) {
            _nestTokenAddress = nestTokenAddress;
        }
        if (nestNodeAddress != address(0)) {
            _nestNodeAddress = nestNodeAddress;
        }
        if (nestLedgerAddress != address(0)) {
            _nestLedgerAddress = nestLedgerAddress;
        }
        if (nestMiningAddress != address(0)) {
            _nestMiningAddress = nestMiningAddress;
        }
        if (ntokenMiningAddress != address(0)) {
            _ntokenMiningAddress = ntokenMiningAddress;
        }
        if (nestPriceFacadeAddress != address(0)) {
            _nestPriceFacadeAddress = nestPriceFacadeAddress;
        }
        if (nestVoteAddress != address(0)) {
            _nestVoteAddress = nestVoteAddress;
        }
        if (nestQueryAddress != address(0)) {
            _nestQueryAddress = nestQueryAddress;
        }
        if (nnIncomeAddress != address(0)) {
            _nnIncomeAddress = nnIncomeAddress;
        }
        if (nTokenControllerAddress != address(0)) {
            _nTokenControllerAddress = nTokenControllerAddress;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implementation contract address
    /// @return nestMiningAddress INestMining implementation contract address for nest
    /// @return ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @return nestVoteAddress INestVote implementation contract address
    /// @return nestQueryAddress INestQuery implementation contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implementation contract address
    function getBuiltinAddress() external view override returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) {
        return (
            _nestTokenAddress,
            _nestNodeAddress,
            _nestLedgerAddress,
            _nestMiningAddress,
            _ntokenMiningAddress,
            _nestPriceFacadeAddress,
            _nestVoteAddress,
            _nestQueryAddress,
            _nnIncomeAddress,
            _nTokenControllerAddress
        );
    }

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view override returns (address) { return _nestTokenAddress; }

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view override returns (address) { return _nestNodeAddress; }

    /// @dev Get INestLedger implementation contract address
    /// @return INestLedger implementation contract address
    function getNestLedgerAddress() external view override returns (address) { return _nestLedgerAddress; }

    /// @dev Get INestMining implementation contract address for nest
    /// @return INestMining implementation contract address for nest
    function getNestMiningAddress() external view override returns (address) { return _nestMiningAddress; }

    /// @dev Get INestMining implementation contract address for ntoken
    /// @return INestMining implementation contract address for ntoken
    function getNTokenMiningAddress() external view override returns (address) { return _ntokenMiningAddress; }

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacadeAddress() external view override returns (address) { return _nestPriceFacadeAddress; }

    /// @dev Get INestVote implementation contract address
    /// @return INestVote implementation contract address
    function getNestVoteAddress() external view override returns (address) { return _nestVoteAddress; }

    /// @dev Get INestQuery implementation contract address
    /// @return INestQuery implementation contract address
    function getNestQueryAddress() external view override returns (address) { return _nestQueryAddress; }

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view override returns (address) { return _nnIncomeAddress; }

    /// @dev Get INTokenController implementation contract address
    /// @return INTokenController implementation contract address
    function getNTokenControllerAddress() external view override returns (address) { return _nTokenControllerAddress; }

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external override onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view override returns (address) {
        return _registeredAddress[key];
    }
}