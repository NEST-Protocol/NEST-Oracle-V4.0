// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../lib/TransferHelper.sol";
import "../interface/INestMining.sol";
import "../interface/INestQuery.sol";
import "../interface/INTokenController.sol";
import "../interface/INestLedger.sol";
import "../interface/INToken.sol";
import "../NestBase.sol";

/// @dev This contract implemented the mining logic of nest
contract NestMining2 is NestBase, INestMining, INestQuery {

    // /// @param nestTokenAddress Address of nest token contract
    // /// @param nestGenesisBlock Genesis block number of nest
    // constructor(address nestTokenAddress, uint nestGenesisBlock) {
        
    //     NEST_TOKEN_ADDRESS = nestTokenAddress;
    //     NEST_GENESIS_BLOCK = nestGenesisBlock;

    //     // Placeholder in _accounts, the index of a real account must greater than 0
    //     _accounts.push();
    // }

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function initialize(address nestGovernanceAddress) public override {
        super.initialize(nestGovernanceAddress);
        // Placeholder in _accounts, the index of a real account must greater than 0
        _accounts.push();
    }

    /// @dev Definitions for the price sheet, include the full information. 
    /// (use 256-bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160-bits) to a 32-bits 
        // integer, support 4 billion accounts
        uint32 miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // price = priceFraction * 16 ^ priceExponent
        uint56 priceFloat;
    }

    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 priceFloat;

        // Avg Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 avgFloat;

        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }

    /// @dev Price channel
    struct PriceChannel {

        // Array of price sheets
        PriceSheet[] sheets;

        // Price information
        PriceInfo price;

        // Commission is charged for every post(post2), the commission should be deposited to NestLedger,
        // for saving gas, according to sheets.length, every increase of 256 will deposit once, 
        // The calculation formula is:
        // 
        // totalFee = fee * increment
        // 
        // In consideration of takeToken, takeEth, change postFeeUnit or miner pay more fee, the formula will be 
        // invalid, at this point, it is need to settle immediately, the details of triggering settlement logic 
        // are as follows
        // 
        // 1. When there is a bite transaction(currentFee is 0), the counter of no fee sheets will be increase 1
        // 2. If the Commission of this time is inconsistent with that of last time, deposit immediately
        // 3. When the increment of sheets.length is 256, deposit immediately
        // 4. Everyone can trigger immediate settlement by manually calling the settle() method
        // 
        // In order to realize the logic above, the following values are defined
        // 
        // 1. PriceChannel.feeInfo
        //    Low 128-bits represent last fee per post
        //    High 128-bits represent the current counter of no fee sheets (including settled)
        // 
        // 2. COLLECT_REWARD_MASK
        //    The mask of batch deposit trigger, while COLLECT_REWARD_MASK & sheets.length == COLLECT_REWARD_MASK, 
        // it will trigger deposit,
        //    COLLECT_REWARD_MASK is set to 0xF for testing (means every 16 sheets will deposit once), 
        //    and it will be set to 0xFF for mainnet (means every 256 sheets will deposit once)

        // The information of mining fee
        // Low 128-bits represent fee per post
        // High 128-bits represent the current counter of no fee sheets (including settled)
        uint feeInfo;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing 
    /// from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Account information
    struct Account {
        
        // Address of account
        address addr;

        // Balances of mining account
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    // Configuration
    Config _config;

    // Registered account information
    Account[] _accounts;

    // Mapping from address to index of account. address=>accountIndex
    mapping(address=>uint) _accountMapping;

    // Mapping from token address to price channel. tokenAddress=>PriceChannel
    mapping(address=>PriceChannel) _channels;

    // Mapping from token address to ntoken address. tokenAddress=>ntokenAddress
    mapping(address=>address) _addressCache;

    // Cache for genesis block number of ntoken. ntokenAddress=>genesisBlockNumber
    mapping(address=>uint) _genesisBlockNumberCache;

    // INestPriceFacade implementation contract address
    address _nestPriceFacadeAddress;

    // INTokenController implementation contract address
    address _nTokenControllerAddress;

    // INestLedger implementation contract address
    address _nestLedgerAddress;

    // Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether;

    // The mask of batch deposit trigger, while COLLECT_REWARD_MASK & sheets.length == COLLECT_REWARD_MASK, 
    // it will trigger deposit,
    // COLLECT_REWARD_MASK is set to 0xF for testing (means every 16 sheets will deposit once), 
    // and it will be set to 0xFF for mainnet (means every 256 sheets will deposit once)
    uint constant COLLECT_REWARD_MASK = 0xFF;

    // Ethereum average block time interval, 14 seconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    /* ========== Governance ========== */

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
            _nTokenControllerAddress  

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

    /// @dev Clear cache of token. while ntoken recreated, this method is need to call
    /// @param tokenAddress Token address
    function resetNTokenCache(address tokenAddress) external onlyGovernance {

        // Clear cache
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        _genesisBlockNumberCache[ntokenAddress] = 0;
        _addressCache[tokenAddress] = _addressCache[ntokenAddress] = address(0);
    }

    /// @dev Set the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, 
    /// means the token is disabled
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress The ntoken address
    function setNTokenAddress(address tokenAddress, address ntokenAddress) external override onlyGovernance {
        _addressCache[tokenAddress] = ntokenAddress;
    }

    /// @dev Get the ntokenAddress from tokenAddress, if ntokenAddress is equals to tokenAddress, 
    /// means the token is disabled
    /// @param tokenAddress Destination token address
    /// @return The ntoken address
    function getNTokenAddress(address tokenAddress) external view override returns (address) {
        return _addressCache[tokenAddress];
    }

    /* ========== Mining ========== */

    // Get ntoken address of from token address
    function _getNTokenAddress(address tokenAddress) private returns (address) {

        address ntokenAddress = _addressCache[tokenAddress];
        if (ntokenAddress == address(0)) {
            ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
            if (ntokenAddress != address(0)) {
                _addressCache[tokenAddress] = ntokenAddress;
            }
        }
        return ntokenAddress;
    }

    // Get genesis block number of ntoken
    function _getNTokenGenesisBlock(address ntokenAddress) private returns (uint) {

        uint genesisBlockNumber = _genesisBlockNumberCache[ntokenAddress];
        if (genesisBlockNumber == 0) {
            (genesisBlockNumber,) = INToken(ntokenAddress).checkBlockInfo();
            _genesisBlockNumberCache[ntokenAddress] = genesisBlockNumber;
        }
        return genesisBlockNumber;
    }

    /// @notice Post a price sheet for TOKEN
    /// @dev It is for TOKEN (except USDT and NTOKEN) whose NTOKEN has a total supply below a threshold 
    /// (e.g. 5,000,000 * 1e18)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(address tokenAddress, uint ethNum, uint tokenAmountPerEth) external payable override {

        tokenAmountPerEth = tokenAmountPerEth * 3;
        Config memory config = _config;

        // 1. Check arguments
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0, "NM:!price");

        // 2. Check price channel
        // Check if the token allow post()
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");
        // Unit of nest is different, but the total supply already exceeded the number of this issue. 
        // No additional judgment will be made ntoken is mint when the price sheet is closed (or withdrawn), 
        // this may be the problem that the user intentionally does not close or withdraw, which leads to 
        // the inaccurate judgment of the total amount. ignore
        require(INToken(ntokenAddress).totalSupply() < uint(config.doublePostThreshold) * 10000 ether, "NM:!post2");

        // 3. Load token channel and sheets
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // 4. Freeze assets
        uint accountIndex = _addressIndex(msg.sender);
        // Freeze token and nest
        // Because of the use of floating-point representation(fraction * 16 ^ exponent), it may bring some precision 
        // loss After assets are frozen according to tokenAmountPerEth * ethNum, the part with poor accuracy may be 
        // lost when the assets are returned, It should be frozen according to decodeFloat(fraction, exponent) * ethNum
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of
        // precision loss can be transferred out as system income in the future
        _freeze2(
            _accounts[accountIndex].balances, 
            tokenAddress, 
            tokenAmountPerEth * ethNum, 
            uint(config.pledgeNest) * 1000 ether
        );

        // 5. Deposit fee
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        uint shares = _collect(config, channel, ntokenAddress, length, msg.value - ethNum * 1 ether);
        require(shares > 0 && shares < 256, "NM:!fee");

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 6. Create token price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), uint(config.pledgeNest), shares, tokenAmountPerEth);
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously
    /// @dev Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param tokenAddress The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(
        address tokenAddress, 
        uint ethNum, 
        uint tokenAmountPerEth, 
        uint ntokenAmountPerEth
    ) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(ethNum > 0 && ethNum == uint(config.postEthUnit), "NM:!ethNum");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "NM:!price");

        // 2. Check price channel
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        require(ntokenAddress != address(0) && ntokenAddress != tokenAddress, "NM:!tokenAddress");

        // 3. Load token channel and sheets
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // 4. Freeze assets
        uint pledgeNest = uint(config.pledgeNest);
        uint accountIndex = _addressIndex(msg.sender);
        {
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            _freeze(balances, tokenAddress, ethNum * tokenAmountPerEth);
            _freeze2(balances, ntokenAddress, ethNum * ntokenAmountPerEth, pledgeNest * 2000 ether);
        }

        // 5. Deposit fee
        // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
        uint length = sheets.length;
        uint shares = _collect(config, channel, ntokenAddress, length, msg.value - ethNum * 2 ether);
        require(shares > 0 && shares < 256, "NM:!fee");

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 6. Create token price sheet
        emit Post(tokenAddress, msg.sender, length, ethNum, tokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), pledgeNest, shares, tokenAmountPerEth);

        // 7. Load ntoken channel and sheets
        channel = _channels[ntokenAddress];
        sheets = channel.sheets;

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 8. Create token price sheet
        emit Post(ntokenAddress, msg.sender, sheets.length, ethNum, ntokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(ethNum), pledgeNest, 0, ntokenAmountPerEth);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken(
        address tokenAddress,
        uint index,
        uint takeNum,
        uint newTokenAmountPerEth
    ) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0 && takeNum % uint(config.postEthUnit) == 0, "NM:!takeNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= takeNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee
        {
            // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(config, channel, ntokenAddress, sheets.length, 0);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scale sheet
            needEthNum = takeNum << 1;
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet
            needEthNum = takeNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4
            // or more, there is no logical dependence on the specific value of the contract, and the count will
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }
        require(msg.value == (needEthNum + takeNum) * 1 ether, "NM:!value");

        // Number of nest to be pledged
        //uint needNest1k = ((takeNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // sheet.ethNumBal + sheet.tokenNumBal is always two times to sheet.ethNum
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.ethNumBal) + uint(sheet.tokenNumBal));
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        {
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            uint backTokenValue = decodeFloat(sheet.priceFloat) * takeNum;
            if (needEthNum * newTokenAmountPerEth > backTokenValue) {
                _freeze2(
                    balances,
                    tokenAddress,
                    needEthNum * newTokenAmountPerEth - backTokenValue,
                    needNest1k * 1000 ether
                );
            } else {
                _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether);
                _unfreeze(balances, tokenAddress, backTokenValue - needEthNum * newTokenAmountPerEth);
            }
        }

        // 6. Update the bitten sheet
        sheet.remainNum = uint32(uint(sheet.remainNum) - takeNum);
        sheet.ethNumBal = uint32(uint(sheet.ethNumBal) + takeNum);
        sheet.tokenNumBal = uint32(uint(sheet.tokenNumBal) - takeNum);
        sheets[index] = sheet;

        // 7. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, needEthNum, newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newTokenAmountPerEth);
    }

    /// @notice Call the function to buy ETH from a posted price sheet
    /// @dev bite ETH by TOKEN(NTOKEN),  (-ethNumBal, +tokenNumBal)
    /// @param tokenAddress The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeEth(
        address tokenAddress,
        uint index,
        uint takeNum,
        uint newTokenAmountPerEth
    ) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0 && takeNum % uint(config.postEthUnit) == 0, "NM:!takeNum");
        require(newTokenAmountPerEth > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= takeNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee
        {
            // The revenue is deposited every 256 sheets, deducting the times of taking orders and the settled part
            address ntokenAddress = _getNTokenAddress(tokenAddress);
            if (tokenAddress != ntokenAddress) {
                _collect(config, channel, ntokenAddress, sheets.length, 0);
            }
        }

        // 5. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum;
        uint level = uint(sheet.level);

        // When the level of the sheet is less than 4, both the nest and the scale of the offer are doubled
        if (level < uint(config.maxBiteNestedLevel)) {
            // Double scale sheet
            needEthNum = takeNum << 1;
            ++level;
        } 
        // When the level of the sheet reaches 4 or more, nest doubles, but the scale does not
        else {
            // Single scale sheet
            needEthNum = takeNum;
            // It is possible that the length of a single chain exceeds 255. When the length of a chain reaches 4 
            // or more, there is no logical dependence on the specific value of the contract, and the count will
            // not increase after it is accumulated to 255
            if (level < 255) ++level;
        }
        require(msg.value == (needEthNum - takeNum) * 1 ether, "NM:!value");

        // Number of nest to be pledged
        //uint needNest1k = ((takeNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // sheet.ethNumBal + sheet.tokenNumBal is always two times to sheet.ethNum
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.ethNumBal) + uint(sheet.tokenNumBal));
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        _freeze2(
            _accounts[accountIndex].balances, 
            tokenAddress, 
            needEthNum * newTokenAmountPerEth + decodeFloat(sheet.priceFloat) * takeNum, 
            needNest1k * 1000 ether
        );
            
        // 6. Update the bitten sheet
        sheet.remainNum = uint32(uint(sheet.remainNum) - takeNum);
        sheet.ethNumBal = uint32(uint(sheet.ethNumBal) - takeNum);
        sheet.tokenNumBal = uint32(uint(sheet.tokenNumBal) + takeNum);
        sheets[index] = sheet;

        // 7. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 8. Create price sheet
        emit Post(tokenAddress, msg.sender, sheets.length, needEthNum, newTokenAmountPerEth);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newTokenAmountPerEth);
    }

    // Create price sheet
    function _createPriceSheet(
        PriceSheet[] storage sheets,
        uint accountIndex,
        uint32 ethNum,
        uint nestNum1k,
        uint level_shares,
        uint tokenAmountPerEth
    ) private {

        sheets.push(PriceSheet(
            uint32(accountIndex),                       // uint32 miner;
            uint32(block.number),                       // uint32 height;
            ethNum,                                     // uint32 remainNum;
            ethNum,                                     // uint32 ethNumBal;
            ethNum,                                     // uint32 tokenNumBal;
            uint24(nestNum1k),                          // uint32 nestNum1k;
            uint8(level_shares >> 8),                   // uint8 level;
            uint8(level_shares & 0xFF),
            encodeFloat(tokenAmountPerEth)
        ));
    }

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; //NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _reduction(uint delta) private pure returns (uint) {

        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed
    /// @param tokenAddress The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address tokenAddress, uint index) external override {
        
        Config memory config = _config;
        PriceChannel storage channel = _channels[tokenAddress];
        PriceSheet[] storage sheets = channel.sheets;

        // Load the price channel
        address ntokenAddress = _getNTokenAddress(tokenAddress);
        // Call _close() method to close price sheet
        (uint accountIndex, Tuple memory total) = _close(config, sheets, index, ntokenAddress);

        if (accountIndex > 0) {
            // Return eth
            if (uint(total.ethNum) > 0) {
                payable(indexAddress(accountIndex)).transfer(uint(total.ethNum) * 1 ether);
            }
            // Unfreeze assets
            _unfreeze3(
                _accounts[accountIndex].balances, 
                tokenAddress, 
                total.tokenValue, 
                ntokenAddress, 
                uint(total.ntokenValue), 
                uint(total.nestValue)
            );
        }

        // Calculate the price
        _stat(config, channel, sheets);
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address tokenAddress, uint[] memory indices) external override {
        
        // Call _closeList() method to close price sheets
        (
            uint accountIndex,
            Tuple memory total,
            address ntokenAddress
        ) = _closeList(_config, _channels[tokenAddress], tokenAddress, indices);

        // Return eth
        payable(indexAddress(accountIndex)).transfer(uint(total.ethNum) * 1 ether);
        // Unfreeze assets
        _unfreeze3(
            _accounts[accountIndex].balances,
            tokenAddress,
            uint(total.tokenValue),
            ntokenAddress,
            uint(total.ntokenValue),
            uint(total.nestValue)
        );
    }

    /// @notice Close two batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param tokenAddress The address of TOKEN1 contract
    /// @param tokenIndices A list of indices of sheets w.r.t. `token`
    /// @param ntokenIndices A list of indices of sheets w.r.t. `ntoken`
    function closeList2(
        address tokenAddress,
        uint[] memory tokenIndices,
        uint[] memory ntokenIndices
    ) external override {

        Config memory config = _config;
        mapping(address=>PriceChannel) storage channels = _channels;

        // Call _closeList() method to close price sheets
        (
            uint accountIndex1,
            Tuple memory total1,
            address ntokenAddress
        ) = _closeList(config, channels[tokenAddress], tokenAddress, tokenIndices);

        (
            uint accountIndex2,
            Tuple memory total2,
            //address ntokenAddress2
        ) = _closeList(config, channels[ntokenAddress], ntokenAddress, ntokenIndices);

        require(accountIndex1 == accountIndex2, "NM:!miner");
        //require(ntokenAddress1 == tokenAddress2, "NM:!tokenAddress");
        require(uint(total2.ntokenValue) == 0, "NM!ntokenValue");

        // Return eth
        payable(indexAddress(accountIndex1)).transfer((uint(total1.ethNum) + uint(total2.ethNum)) * 1 ether);
        // Unfreeze assets
        _unfreeze3(
            _accounts[accountIndex1].balances,
            tokenAddress,
            uint(total1.tokenValue),
            ntokenAddress,
            uint(total1.ntokenValue) + uint(total2.tokenValue)/* + uint(total2.ntokenValue) */,
            uint(total1.nestValue) + uint(total2.nestValue)
        );
    }

    // Calculation number of blocks which mined
    function _calcMinedBlocks(
        PriceSheet[] storage sheets,
        uint index,
        PriceSheet memory sheet
    ) private view returns (uint minedBlocks, uint totalShares) {

        uint length = sheets.length;
        uint height = uint(sheet.height);
        totalShares = uint(sheet.shares);

        // Backward looking for sheets in the same block
        for (uint i = index; ++i < length && uint(sheets[i].height) == height;) {
            
            // Multiple sheets in the same block is a small probability event at present, so it can be ignored
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[i].shares);
        }

        //i = index;
        // Find sheets in the same block forward
        uint prev = height;
        while (index > 0 && uint(prev = sheets[--index].height) == height) {

            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[index].shares);
        }

        if (index > 0 || height > prev) {
            minedBlocks = height - prev;
        } else {
            minedBlocks = 10;
        }
    }

    // This structure is for the _close() method to return multiple values
    struct Tuple {
        uint tokenValue;
        uint64 ethNum;
        uint96 nestValue;
        uint96 ntokenValue;
    }

    // Close price sheet
    function _close(
        Config memory config,
        PriceSheet[] storage sheets,
        uint index,
        address ntokenAddress
    ) private returns (uint accountIndex, Tuple memory value) {

        PriceSheet memory sheet = sheets[index];
        uint height = uint(sheet.height);

        // Check the status of the price sheet to see if it has reached the effective block interval or has been finished
        if ((accountIndex = uint(sheet.miner)) > 0 && (height + uint(config.priceEffectSpan) < block.number)) {

            // TMP: tmp is a polysemous name, here means sheet.shares
            uint tmp = uint(sheet.shares);
            // Mining logic
            // The price sheet which shares is zero dosen't mining
            if (tmp > 0) {

                // Currently, mined represents the number of blocks has mined
                (uint mined, uint totalShares) = _calcMinedBlocks(sheets, index, sheet);
                // nest mining
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {

                    // Since then, mined represents the amount of mining
                    // mined = (
                    //     mined 
                    //     * uint(sheet.shares) 
                    //     * _reduction(height - NEST_GENESIS_BLOCK) 
                    //     * 1 ether 
                    //     * uint(config.minerNestReward) 
                    //     / 10000 
                    //     / totalShares
                    // );
                    // The original expression is shown above. In order to save gas,
                    // the part that can be calculated in advance is calculated first
                    mined = (
                        mined
                        * tmp
                        * _reduction(height - NEST_GENESIS_BLOCK)
                        * uint(config.minerNestReward)
                        * 0.0001 ether
                        / totalShares
                    );
                }
                // ntoken mining
                else {

                    // The limit blocks can be mined
                    if (mined > uint(config.ntokenMinedBlockLimit)) {
                        mined = uint(config.ntokenMinedBlockLimit);
                    }
                    
                    // Since then, mined represents the amount of mining
                    mined = (
                        mined
                        * tmp
                        * _reduction(height - _getNTokenGenesisBlock(ntokenAddress))
                        * 0.01 ether
                        / totalShares
                    );

                    // Put this logic into withdrawn() method to reduce gas consumption
                    // ntoken bidders
                    address bidder = INToken(ntokenAddress).checkBidder();
                    // Legacy ntoken, need separate
                    if (bidder != address(this)) {

                        // Considering that multiple sheets in the same block are small probability events,
                        // we can send token to bidders in each closing operation
                        // 5% for bidder

                        // TMP: tmp is a polysemous name, here means mint ntoken amount for miner
                        tmp = mined * uint(config.minerNTokenReward) / 10000;
                        _unfreeze(
                            _accounts[_addressIndex(bidder)].balances,
                            ntokenAddress,
                            mined - tmp
                        );

                        // Miner take according proportion which set
                        mined = tmp;
                    }
                }

                value.ntokenValue = uint96(mined);
            }

            value.nestValue = uint96(uint(sheet.nestNum1k) * 1000 ether);
            value.ethNum = uint64(sheet.ethNumBal);
            value.tokenValue = decodeFloat(sheet.priceFloat) * uint(sheet.tokenNumBal);

            // Set sheet.miner to 0, express the sheet is closed
            sheet.miner = uint32(0);
            sheet.ethNumBal = uint32(0);
            sheet.tokenNumBal = uint32(0);
            sheets[index] = sheet;
        }
    }

    // Batch close sheets
    function _closeList(
        Config memory config,
        PriceChannel storage channel,
        address tokenAddress,
        uint[] memory indices
    ) private returns (uint accountIndex, Tuple memory total, address ntokenAddress) {

        ntokenAddress = _getNTokenAddress(tokenAddress);
        PriceSheet[] storage sheets = channel.sheets;
        accountIndex = 0; 

        // 1. Traverse sheets
        for (uint i = indices.length; i > 0;) {

            // Because too many variables need to be returned, too many variables will be defined, 
            // so the structure of tuple is defined
            (uint minerIndex, Tuple memory value) = _close(config, sheets, indices[--i], ntokenAddress);
            // Batch closing quotation can only close sheet of the same user
            if (accountIndex == 0) {
                // accountIndex == 0 means the first sheet, and the number of this sheet is taken
                accountIndex = minerIndex;
            } else {
                // accountIndex != 0 means that it is a follow-up sheet, and the miner number must be 
                // consistent with the previous record
                require(accountIndex == minerIndex, "NM:!miner");
            }

            total.ntokenValue += value.ntokenValue;
            total.nestValue += value.nestValue;
            total.ethNum += value.ethNum;
            total.tokenValue += value.tokenValue;
        }

        _stat(config, channel, sheets);
    }

    // Calculate price, average price and volatility
    function _stat(Config memory config, PriceChannel storage channel, PriceSheet[] storage sheets) private {

        // Load token price information
        PriceInfo memory p0 = channel.price;

        // Length of sheets
        uint length = sheets.length;
        // The index of the sheet to be processed in the sheet array
        uint index = uint(p0.index);
        // The latest block number for which the price has been calculated
        uint prev = uint(p0.height);
        // It's not necessary to load the price information in p0
        // Eth count variable used to calculate price
        uint totalEthNum = 0; 
        // Token count variable for price calculation
        uint totalTokenValue = 0; 
        // Block number of current sheet
        uint height = 0;

        // Traverse the sheets to find the effective price
        uint effectBlock = block.number - uint(config.priceEffectSpan);
        PriceSheet memory sheet;
        for (; ; ++index) {

            // Gas attack analysis, each post transaction, calculated according to post, needs to write
            // at least one sheet and freeze two kinds of assets, which needs to consume at least 30000 gas,
            // In addition to the basic cost of the transaction, at least 50000 gas is required.
            // In addition, there are other reading and calculation operations. The gas consumed by each
            // transaction is impossible less than 70000 gas, The attacker can accumulate up to 20 blocks
            // of sheets to be generated. To ensure that the calculation can be completed in one block,
            // it is necessary to ensure that the consumption of each price does not exceed 70000 / 20 = 3500 gas,
            // According to the current logic, each calculation of a price needs to read a storage unit (800)
            // and calculate the consumption, which can not reach the dangerous value of 3500, so the gas attack
            // is not considered

            // Traverse the sheets that has reached the effective interval from the current position
            bool flag = index >= length || (height = uint((sheet = sheets[index]).height)) >= effectBlock;

            // Not the same block (or flag is false), calculate the price and update it
            if (flag || prev != height) {

                // totalEthNum > 0 Can calculate the price
                if (totalEthNum > 0) {

                    // Calculate average price and Volatility
                    // Calculation method of volatility of follow-up price
                    uint tmp = decodeFloat(p0.priceFloat);
                    // New price
                    uint price = totalTokenValue / totalEthNum;
                    // Update price
                    p0.remainNum = uint32(totalEthNum);
                    p0.priceFloat = encodeFloat(price);
                    // Clear cumulative values
                    totalEthNum = 0;
                    totalTokenValue = 0;

                    if (tmp > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 90% + price[i] * 10%
                        p0.avgFloat = encodeFloat((decodeFloat(p0.avgFloat) * 9 + price) / 10);

                        // When the accuracy of the token is very high or the value of the token relative to
                        // eth is very low, the price may be very large, and there may be overflow problem,
                        // it is not considered for the moment
                        tmp = (price << 48) / tmp;
                        if (tmp > 0x1000000000000) {
                            tmp = tmp - 0x1000000000000;
                        } else {
                            tmp = 0x1000000000000 - tmp;
                        }

                        // earn = price[i] / price[i - 1] - 1;
                        // seconds = time[i] - time[i - 1];
                        // sigmaSQ[i + 1] = sigmaSQ[i] * 90% + (earn ^ 2 / seconds) * 10%
                        tmp = (
                            uint(p0.sigmaSQ) * 9 + 
                            // It is inevitable that prev greater than p0.height
                            ((tmp * tmp / ETHEREUM_BLOCK_TIMESPAN / (prev - uint(p0.height))) >> 48)
                        ) / 10;

                        // The current implementation assumes that the volatility cannot exceed 1, and
                        // corresponding to this, when the calculated value exceeds 1, expressed as 0xFFFFFFFFFFFF
                        if (tmp > 0xFFFFFFFFFFFF) {
                            tmp = 0xFFFFFFFFFFFF;
                        }
                        p0.sigmaSQ = uint48(tmp);
                    }
                    // The calculation methods of average price and volatility are different for first price
                    else {
                        // The average price is equal to the price
                        //p0.avgTokenAmount = uint64(price);
                        p0.avgFloat = p0.priceFloat;

                        // The volatility is 0
                        p0.sigmaSQ = uint48(0);
                    }

                    // Update price block number
                    p0.height = uint32(prev);
                }

                // Move to new block number
                prev = height;
            }

            if (flag) {
                break;
            }

            // Cumulative price information
            totalEthNum += uint(sheet.remainNum);
            totalTokenValue += decodeFloat(sheet.priceFloat) * uint(sheet.remainNum);
        }

        // Update price information
        if (index > uint(p0.index)) {
            p0.index = uint32(index);
            channel.price = p0;
        }
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    function stat(address tokenAddress) external override {
        PriceChannel storage channel = _channels[tokenAddress];
        _stat(_config, channel, channel.sheets);
    }

    // Collect and deposit the commission into NestLedger
    function _collect(
        Config memory config,
        PriceChannel storage channel,
        address ntokenAddress,
        uint length,
        uint currentFee
    ) private returns (uint) {

        // Commission is charged for every post(post2), the commission should be deposited to NestLedger,
        // for saving gas, according to sheets.length, every increase of 256 will deposit once, 
        // The calculation formula is:
        // 
        // totalFee = fee * increment
        // 
        // In consideration of takeToken, takeEth, change postFeeUnit or miner pay more fee, the formula will be 
        // invalid, at this point, it is need to settle immediately, the details of triggering settlement logic 
        // are as follows
        // 
        // 1. When there is a bite transaction(currentFee is 0), the counter of no fee sheets will be increase 1
        // 2. If the Commission of this time is inconsistent with that of last time, deposit immediately
        // 3. When the increment of sheets.length is 256, deposit immediately
        // 4. Everyone can trigger immediate settlement by manually calling the settle() method
        // 
        // In order to realize the logic above, the following values are defined
        // 
        // 1. PriceChannel.feeInfo
        //    Low 128-bits represent last fee per post
        //    High 128-bits represent the current counter of no fee sheets (including settled)
        // 
        // 2. COLLECT_REWARD_MASK
        //    The mask of batch deposit trigger, while COLLECT_REWARD_MASK & sheets.length == COLLECT_REWARD_MASK, 
        // it will trigger deposit,
        //    COLLECT_REWARD_MASK is set to 0xF for testing (means every 16 sheets will deposit once), 
        //    and it will be set to 0xFF for mainnet (means every 256 sheets will deposit once)

        uint feeUnit = uint(config.postFeeUnit) * DIMI_ETHER;
        require(currentFee % feeUnit == 0, "NM:!fee");
        uint feeInfo = channel.feeInfo;
        uint oldFee = feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        // length == 255 means is time to save reward
        // currentFee != oldFee means the fee is changed, need to settle
        if (length & COLLECT_REWARD_MASK == COLLECT_REWARD_MASK || (currentFee != oldFee && currentFee > 0)) {
            // Save reward
            INestLedger(_nestLedgerAddress).carveETHReward { 
                value: currentFee + oldFee * ((length & COLLECT_REWARD_MASK) - (feeInfo >> 128))
            } (ntokenAddress);
            // Update fee information
            channel.feeInfo = currentFee | (((length + 1) & COLLECT_REWARD_MASK) << 128);
        }
        // currentFee is 0, increase no fee counter
        else if (currentFee == 0) {
            // channel.feeInfo = feeInfo + (1 << 128);
            channel.feeInfo = feeInfo + 0x100000000000000000000000000000000;
        }

        // Calculate share count
        return currentFee / feeUnit;
    }

    /// @dev Settlement Commission
    /// @param tokenAddress The token address
    function settle(address tokenAddress) external override {

        address ntokenAddress = _getNTokenAddress(tokenAddress);
        // ntoken is no reward
        if (tokenAddress != ntokenAddress) {

            PriceChannel storage channel = _channels[tokenAddress];
            uint length = channel.sheets.length & COLLECT_REWARD_MASK;
            uint feeInfo = channel.feeInfo;

            // Save reward
            INestLedger(_nestLedgerAddress).carveETHReward {
                value: (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * (length - (feeInfo >> 128))
            } (ntokenAddress);

            // Manual settlement does not need to update Commission variables
            channel.feeInfo = (feeInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (length << 128);
        }
    }

    // Convert PriceSheet to PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // Index number
            uint32(index),
            // Miner address
            indexAddress(sheet.miner),
            // The block number of this price sheet packaged
            sheet.height,
            // The remain number of this price sheet
            sheet.remainNum,
            // The eth number which miner will got
            sheet.ethNumBal,
            // The eth number which equivalent to token's value which miner will got
            sheet.tokenNumBal,
            // The pledged number of nest in this sheet. (Unit: 1000nest)
            sheet.nestNum1k,
            // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses 
            // bite price sheet
            sheet.level,
            // Post fee shares
            sheet.shares,
            // Price
            uint152(decodeFloat(sheet.priceFloat))
        );
    }

    /// @dev List sheets by page
    /// @param tokenAddress Destination token address
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        address tokenAddress,
        uint offset,
        uint count,
        uint order
    ) external view override noContract returns (PriceSheetView[] memory) {

        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint length = sheets.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                result[i++] = _toPriceSheetView(sheets[index], index);
            }
        } 
        // Positive order
        else {

            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                result[i++] = _toPriceSheetView(sheets[index], index);
                ++index;
            }
        }
        return result;
    }

    /// @dev Estimated mining amount
    /// @param tokenAddress Destination token address
    /// @return Estimated mining amount
    function estimate(address tokenAddress) external view override returns (uint) {

        address ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
        if (tokenAddress != ntokenAddress) {

            PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
            uint index = sheets.length;
            while (index > 0) {

                PriceSheet memory sheet = sheets[--index];
                if (uint(sheet.shares) > 0) {

                    // Standard mining amount
                    uint standard = (block.number - uint(sheet.height)) * 1 ether;
                    // Genesis block number of ntoken
                    uint genesisBlock = NEST_GENESIS_BLOCK;

                    // Not nest, the calculation methods of standard mining amount and genesis block number 
                    // are different
                    if (ntokenAddress != NEST_TOKEN_ADDRESS) {
                        // The standard mining amount of ntoken is 1/100 of nest
                        standard /= 100;
                        // Genesis block number of ntoken is obtained separately
                        (genesisBlock,) = INToken(ntokenAddress).checkBlockInfo();
                    }

                    return standard * _reduction(block.number - genesisBlock);
                }
            }
        }

        return 0;
    }

    /// @dev Query the quantity of the target quotation
    /// @param tokenAddress Token address. The token can't mine. Please make sure you don't use 
    /// the token address when calling
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        address tokenAddress,
        uint index
    ) external view override returns (uint minedBlocks, uint totalShares) {

        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet = sheets[index];

        // The bite sheet or ntoken sheet dosen't mining
        if (uint(sheet.shares) == 0) {
            return (0, 0);
        }

        return _calcMinedBlocks(sheets, index, sheet);
    }

    /* ========== Accounts ========== */

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external override {

        // The user's locked nest and the mining pool's nest are stored together. When the nest is mined over,
        // the problem of taking the locked nest as the ore drawing will appear
        // As it will take a long time for nest to finish mining, this problem will not be considered for the time being
        UINT storage balance = _accounts[_accountMapping[msg.sender]].balances[tokenAddress];
        //uint balanceValue = balance.value;
        //require(balanceValue >= value, "NM:!balance");
        balance.value -= value;

        // ntoken mining
        uint ntokenBalance = INToken(tokenAddress).balanceOf(address(this));
        if (ntokenBalance < value) {
            // mining
            INToken(tokenAddress).increaseTotal(value - ntokenBalance);
        }

        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);
    }

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view override returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NM:!accounts");
            _accounts.push().addr = addr;
        }

        return index;
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) public view override returns (address) {
        return _accounts[index].addr;
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view override returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view override returns (uint) {
        return _accounts.length;
    }

    /* ========== Asset management ========== */

    /// @dev Freeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param value token amount
    function _freeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {

        UINT storage balance = balances[tokenAddress];
        uint balanceValue = balance.value;
        if (balanceValue < value) {
            balance.value = 0;
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), value - balanceValue);
        } else {
            balance.value = balanceValue - value;
        }
    }

    /// @dev Unfreeze token
    /// @param balances Balances ledgerBalances ledger
    /// @param tokenAddress Destination token address
    /// @param value token amount
    function _unfreeze(mapping(address=>UINT) storage balances, address tokenAddress, uint value) private {
        UINT storage balance = balances[tokenAddress];
        balance.value += value;
    }

    /// @dev freeze token and nest
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount 
    /// @param nestValue nest amount
    function _freeze2(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue, 
        uint nestValue
    ) private {

        UINT storage balance;
        uint balanceValue;

        // If tokenAddress is NEST_TOKEN_ADDRESS, add it to nestValue
        if (NEST_TOKEN_ADDRESS == tokenAddress) {
            nestValue += tokenValue;
        }
        // tokenAddress is not NEST_TOKEN_ADDRESS, unfreeze it
        else {
            balance = balances[tokenAddress];
            balanceValue = balance.value;
            if (balanceValue < tokenValue) {
                balance.value = 0;
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            } else {
                balance.value = balanceValue - tokenValue;
            }
        }

        // Unfreeze nest
        balance = balances[NEST_TOKEN_ADDRESS];
        balanceValue = balance.value;
        if (balanceValue < nestValue) {
            balance.value = 0;
            TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestValue - balanceValue);
        } else {
            balance.value = balanceValue - nestValue;
        }
    }

    /// @dev Unfreeze token, ntoken and nest
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount
    /// @param ntokenAddress Destination ntoken address
    /// @param ntokenValue ntoken amount
    /// @param nestValue nest amount
    function _unfreeze3(
        mapping(address=>UINT) storage balances,
        address tokenAddress,
        uint tokenValue,
        address ntokenAddress,
        uint ntokenValue,
        uint nestValue
    ) private {

        UINT storage balance;
        
        // If tokenAddress is ntokenAddress, add it to ntokenValue
        if (ntokenAddress == tokenAddress) {
            ntokenValue += tokenValue;
        }
        // tokenAddress is not ntokenAddress, unfreeze it
        else {
            balance = balances[tokenAddress];
            balance.value += tokenValue;
        }

        // If ntokenAddress is NEST_TOKEN_ADDRESS, add it to nestValue
        if (NEST_TOKEN_ADDRESS == ntokenAddress) {
            nestValue += ntokenValue;
        }
        // ntokenAddress is NEST_TOKEN_ADDRESS, unfreeze it
        else {
            balance = balances[ntokenAddress];
            balance.value += ntokenValue;
        }

        // Unfreeze nest
        balance = balances[NEST_TOKEN_ADDRESS];
        balance.value += nestValue;
    }

    /* ========== INestQuery ========== */
    
    // Check msg.sender
    function _check() private view {
        require(msg.sender == _nestPriceFacadeAddress || msg.sender == tx.origin);
    }

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(address tokenAddress) public view override returns (uint blockNumber, uint price) {

        _check();
        PriceInfo memory priceInfo = _channels[tokenAddress].price;

        if (uint(priceInfo.remainNum) > 0) {
            return (uint(priceInfo.height) + uint(_config.priceEffectSpan), decodeFloat(priceInfo.priceFloat));
        }
        
        return (0, 0);
    }

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(address tokenAddress) public view override returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {

        _check();
        PriceInfo memory priceInfo = _channels[tokenAddress].price;

        if (uint(priceInfo.remainNum) > 0) {
            return (
                uint(priceInfo.height) + uint(_config.priceEffectSpan),
                decodeFloat(priceInfo.priceFloat),
                decodeFloat(priceInfo.avgFloat),
                (uint(priceInfo.sigmaSQ) * 1 ether) >> 48
            );
        }

        return (0, 0, 0, 0);
    }

    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress,
        uint height
    ) external view override returns (uint blockNumber, uint price) {

        _check();
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        uint priceEffectSpan = uint(_config.priceEffectSpan);

        uint length = sheets.length;
        uint index = 0;
        uint sheetHeight;
        height -= priceEffectSpan;
        {
            // If there is no sheet in this channel, length is 0, length - 1 will overflow,
            uint right = length - 1;
            uint left = 0;
            // Find the index use Binary Search
            while (left < right) {

                index = (left + right) >> 1;
                sheetHeight = uint(sheets[index].height);
                if (height > sheetHeight) {
                    left = ++index;
                } else if (height < sheetHeight) {
                    // When index = 0, this statement will have an underflow exception, which usually 
                    // indicates that the effective block height passed during the call is lower than 
                    // the block height of the first quotation
                    right = --index;
                } else {
                    break;
                }
            }
        }

        // Calculate price
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint h = 0;
        uint remainNum;
        PriceSheet memory sheet;

        // Find sheets forward
        for (uint i = index; i < length;) {

            sheet = sheets[i++];
            sheetHeight = uint(sheet.height);
            if (height < sheetHeight) {
                break;
            }
            remainNum = uint(sheet.remainNum);
            if (remainNum > 0) {
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        // Find sheets backward
        while (index > 0) {

            sheet = sheets[--index];
            remainNum = uint(sheet.remainNum);
            if (remainNum > 0) {
                sheetHeight = uint(sheet.height);
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalEthNum += remainNum;
                totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        if (totalEthNum > 0) {
            return (h + priceEffectSpan, totalTokenValue / totalEthNum);
        }
        return (0, 0);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(address tokenAddress) public view override returns (uint blockNumber, uint price) {

        _check();
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet;

        uint priceEffectSpan = uint(_config.priceEffectSpan);
        uint h = block.number - priceEffectSpan;
        uint index = sheets.length;
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;

        for (; ; ) {

            bool flag = index == 0;
            if (flag || height != uint((sheet = sheets[--index]).height)) {
                if (totalEthNum > 0 && height <= h) {
                    return (height + priceEffectSpan, totalTokenValue / totalEthNum);
                }
                if (flag) {
                    break;
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
        }

        return (0, 0);
    }

    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(address tokenAddress, uint count) public view override returns (uint[] memory) {

        _check();
        PriceSheet[] storage sheets = _channels[tokenAddress].sheets;
        PriceSheet memory sheet;
        uint[] memory array = new uint[](count <<= 1);

        uint priceEffectSpan = uint(_config.priceEffectSpan);
        uint h = block.number - priceEffectSpan;
        uint index = sheets.length;
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;

        for (uint i = 0; i < count;) {

            bool flag = index == 0;
            if (flag || height != uint((sheet = sheets[--index]).height)) {
                if (totalEthNum > 0 && height <= h) {
                    array[i++] = height + priceEffectSpan;
                    array[i++] = totalTokenValue / totalEthNum;
                }
                if (flag) {
                    break;
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += decodeFloat(sheet.priceFloat) * remainNum;
        }

        return array;
    } 

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(address tokenAddress) external view override 
    returns (
        uint latestPriceBlockNumber,
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        (latestPriceBlockNumber, latestPriceValue) = latestPrice(tokenAddress);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = triggeredPriceInfo(tokenAddress);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(address tokenAddress, uint count) external view override 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        prices = lastPriceList(tokenAddress, count);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = triggeredPriceInfo(tokenAddress);
    }

    /// @dev Get the latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress) external view override returns (
        uint blockNumber,
        uint price,
        uint ntokenBlockNumber,
        uint ntokenPrice
    ) {
        (blockNumber, price) = triggeredPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = triggeredPrice(_addressCache[tokenAddress]);
    }

    /// @dev Get the full information of latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    ///         it means that the volatility has exceeded the range that can be expressed
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    /// @return ntokenAvgPrice Average price of ntoken
    /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo2(address tokenAddress) external view override returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ,
        uint ntokenBlockNumber,
        uint ntokenPrice,
        uint ntokenAvgPrice,
        uint ntokenSigmaSQ
    ) {
        (blockNumber, price, avgPrice, sigmaSQ) = triggeredPriceInfo(tokenAddress);
        (
            ntokenBlockNumber,
            ntokenPrice,
            ntokenAvgPrice,
            ntokenSigmaSQ
        ) = triggeredPriceInfo(_addressCache[tokenAddress]);
    }

    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress) external view override returns (
        uint blockNumber,
        uint price,
        uint ntokenBlockNumber,
        uint ntokenPrice
    ) {
        (blockNumber, price) = latestPrice(tokenAddress);
        (ntokenBlockNumber, ntokenPrice) = latestPrice(_addressCache[tokenAddress]);
    }

    /* ========== Tools and methods ========== */

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
}