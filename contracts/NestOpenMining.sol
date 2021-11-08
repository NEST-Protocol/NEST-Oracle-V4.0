// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import "./lib/TransferHelper.sol";

import "./interface/INestOpenMining.sol";
import "./interface/INToken.sol";

import "./NestBase.sol";

import "hardhat/console.sol";

/// @dev This contract implemented the mining logic of nest
contract NestOpenMining is NestBase, INestOpenMining {

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

        // The information of mining fee
        // Low 128-bits represent fee per post
        // High 128-bits represent the current counter of no fee sheets (including settled)
        uint feeInfo;

        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 报价代币地址，0表示eth
        address token1;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        // 出矿代币地址
        address reward;
        // 矿币总量
        uint96 vault;

        // 管理地址
        address governance;
        // 创世区块
        uint32 genesisBlock;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;

        // TODO: 抵押代币也需要可以设置，不一定用NEST
        // TODO：确定抵押代币是全局设置，还是单独设置
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

    // 报价通道映射，通过此映射避免重复添加报价通道
    mapping(uint=>uint) _channelMapping;

    // 报价通道
    PriceChannel[] _channels;

    // Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether;

    // Ethereum average block time interval, 14 seconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14;

    /* ========== Governance ========== */

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

    /// @dev 开通报价通道
    /// @param config 报价通道配置
    function open(ChannelConfig calldata config) external override {

        address token0 = config.token0;
        address token1 = config.token1;
        address reward = config.reward;

        // 限制同一个报价对重复开通
        uint key = uint(keccak256(abi.encodePacked(token0, token1)));
        require(_channelMapping[key] == 0, "NOM:exists");

        require(token0 != token1, "NOM:token0 can't equal token1");
        emit Open(_channels.length, token0, config.unit, token1, reward);
        PriceChannel storage channel = _channels.push();
        channel.token0 = token0;
        channel.unit = config.unit;
        channel.token1 = token1;
        channel.rewardPerBlock = config.rewardPerBlock;
        channel.reward = reward;
        // 管理地址
        channel.governance = msg.sender;
        // 创世区块
        channel.genesisBlock = uint32(block.number);
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        channel.postFeeUnit = config.postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        channel.singleFee = config.singleFee;
        // 衰减系数，万分制。8000
        channel.reductionRate = config.reductionRate;

        _channelMapping[key] = _channels.length;

        // 测试token地址是否可以正常转账
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, msg.sender, address(this), 1);
            require(IERC20(token0).balanceOf(address(this)) >= 1, "NOM:token0 error");
            TransferHelper.safeTransfer(token0, msg.sender, 1);
        }
        if (token1 != address(0)) {
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), 1);
            require(IERC20(token1).balanceOf(address(this)) >= 1, "NOM:token1 error");
            TransferHelper.safeTransfer(token1, msg.sender, 1);
        }
        // TODO: 考虑到ntoken挖矿，可以不检查
        if (reward != address(0)) {
            TransferHelper.safeTransferFrom(reward, msg.sender, address(this), 1);
            require(IERC20(reward).balanceOf(address(this)) >= 1, "NOM:reward error");
            TransferHelper.safeTransfer(reward, msg.sender, 1);
        }

        // TODO: 收取的NEST到哪里去?
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), 1000 ether);
    }

    /// @dev 向报价通道注入矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increase(uint channelId, uint96 vault) external payable override {
        PriceChannel storage channel = _channels[channelId];
        address reward = channel.reward;
        if (reward == address(0)) {
            require(msg.value == vault, "NOM:vault error");
        } else {
            TransferHelper.safeTransferFrom(reward, msg.sender, address(this), vault);
        }
        channel.vault += vault;
    }

    /// @dev 向报价通道注入NToken矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increaseNToken(uint channelId, uint96 vault) external onlyGovernance {
        PriceChannel storage channel = _channels[channelId];
        INToken(channel.reward).increaseTotal(vault);
        channel.vault += vault;
    }

    /// @dev 修改治理权限地址
    /// @param channelId 报价通道
    /// @param newGovernance 新治理权限地址
    function changeGovernance(uint channelId, address newGovernance) external {
        PriceChannel storage channel = _channels[channelId];
        require(channel.governance == msg.sender, "NOM:not governance");
        channel.governance = newGovernance;
    }

    /// @dev 获取报价通道信息
    /// @param channelId 报价通道
    /// @return 报价通道信息
    function getChannelInfo(uint channelId) external view override returns (PriceChannelView memory) {
        PriceChannel storage channel = _channels[channelId];
        return PriceChannelView (
            channelId,

            channel.sheets.length,

            // The information of mining fee
            // Low 128-bits represent fee per post
            // High 128-bits represent the current counter of no fee sheets (including settled)
            channel.feeInfo,

            // 计价代币地址, 0表示eth
            channel.token0,
            // 计价代币单位
            channel.unit,

            // 报价代币地址，0表示eth
            channel.token1,
            // 每个区块的标准出矿量
            channel.rewardPerBlock,

            // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
            // 出矿代币地址
            channel.reward,
            // 矿币总量
            channel.vault,

            // 管理地址
            channel.governance,
            // 创世区块
            channel.genesisBlock,
            // Post fee(0.0001eth，DIMI_ETHER). 1000
            channel.postFeeUnit,
            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            channel.singleFee,
            // 衰减系数，万分制。8000
            channel.reductionRate
        );
    }

    /* ========== Mining ========== */

    /// @dev 报价
    /// @param channelId 报价通道id
    /// @param scale 报价规模（token0，单位unit）
    /// @param equivalent 与单位token0等价的token1数量
    function post(uint channelId, uint scale, uint equivalent) external payable override {

        // 0. 加载配置
        Config memory config = _config;

        // 1. Check arguments
        require(scale == 1, "NOM:!scale");

        // 2. Check price channel
        // 3. Load token channel and sheets
        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.sheets;

        // 4. Freeze assets
        uint accountIndex = _addressIndex(msg.sender);
        // Freeze token and nest
        // Because of the use of floating-point representation(fraction * 16 ^ exponent), it may bring some precision 
        // loss After assets are frozen according to tokenAmountPerEth * ethNum, the part with poor accuracy may be 
        // lost when the assets are returned, It should be frozen according to decodeFloat(fraction, exponent) * ethNum
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of
        // precision loss can be transferred out as system income in the future
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

        uint fee = msg.value;
        // 冻结token0
        fee = _freeze(balances, channel.token0, uint(channel.unit) * scale, fee);
        // 冻结token1
        fee = _freeze(balances, channel.token1, scale * equivalent, fee);
        // 冻结nest
        fee = _freeze(balances, NEST_TOKEN_ADDRESS, uint(config.pledgeNest) * 1000 ether, fee);
    
        // 5. Deposit fee
        // 只有配置了报价佣金时才检查fee
        uint postFeeUnit = uint(channel.postFeeUnit);
        if (postFeeUnit > 0) {
            require(fee >= postFeeUnit * DIMI_ETHER + tx.gasprice * 400000, "NM:!fee");
        }
        if (fee > 0) {
            channel.feeInfo += fee;
        }

        // Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, channel, sheets);

        // 6. Create token price sheet
        emit Post(channelId, msg.sender, sheets.length, scale, equivalent);
        _createPriceSheet(sheets, accountIndex, uint32(scale), uint(config.pledgeNest), 1, equivalent);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId 报价通道编号
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken0(uint channelId, uint index, uint takeNum, uint newEquivalent) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0, "NM:!takeNum");
        require(newEquivalent > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= takeNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee
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

        // Number of nest to be pledged
        //uint needNest1k = ((takeNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // sheet.ethNumBal + sheet.tokenNumBal is always two times to sheet.ethNum
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.ethNumBal) + uint(sheet.tokenNumBal));
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        {
            // 冻结资产：token0, token1, nest
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            uint fee = msg.value;

            // 冻结token0
            fee = _freeze(balances, channel.token0, (needEthNum - takeNum) * uint(channel.unit), fee);
            // 冻结token1
            fee = _freeze(
                balances, 
                channel.token1, 
                needEthNum * newEquivalent + _decodeFloat(sheet.priceFloat) * takeNum, 
                fee
            );
            // 冻结nest
            fee = _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether, fee);
            require(fee == 0, "NOM:!fee");
        }

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
        emit Post(channelId, msg.sender, sheets.length, needEthNum, newEquivalent);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newEquivalent);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken1(uint channelId, uint index, uint takeNum, uint newEquivalent) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0, "NM:!takeNum");
        require(newEquivalent > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.sheets;
        PriceSheet memory sheet = sheets[index];

        // 3. Check state
        require(uint(sheet.remainNum) >= takeNum, "NM:!remainNum");
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");

        // 4. Deposit fee

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

        // Number of nest to be pledged
        //uint needNest1k = ((takeNum << 1) / uint(config.postEthUnit)) * uint(config.pledgeNest);
        // sheet.ethNumBal + sheet.tokenNumBal is always two times to sheet.ethNum
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.ethNumBal) + uint(sheet.tokenNumBal));
        // Freeze nest and token
        uint accountIndex = _addressIndex(msg.sender);
        {
            // 冻结资产：token0, token1, nest
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

            uint fee = msg.value;
            // 冻结token0
            fee = _freeze(balances, channel.token0, (needEthNum + takeNum) * uint(channel.unit), fee);
            // 冻结token1
            uint backTokenValue = _decodeFloat(sheet.priceFloat) * takeNum;
            if (needEthNum * newEquivalent > backTokenValue) {
                fee = _freeze(balances, channel.token1, needEthNum * newEquivalent - backTokenValue, fee);
            } else {
                _unfreeze(balances, channel.token1, backTokenValue - needEthNum * newEquivalent, msg.sender);
            }
            fee = _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether, fee);
            require(fee == 0, "NOM:!fee");
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
        emit Post(channelId, msg.sender, sheets.length, needEthNum, newEquivalent);
        _createPriceSheet(sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newEquivalent);
    }

    /// @dev List sheets by page
    /// @param channelId 报价通道编号
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId,
        uint offset,
        uint count,
        uint order
    ) external view override noContract returns (PriceSheetView[] memory) {

        PriceSheet[] storage sheets = _channels[channelId].sheets;
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

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId 报价通道编号
    /// @param indices A list of indices of sheets w.r.t. `token`
    function close(uint channelId, uint[] memory indices) external override {
        
        PriceChannel storage channel = _channels[channelId];

        // Call _closeList() method to close price sheets
        (
            uint accountIndex,
            Tuple memory total
        ) = _closeList(_config, channel, indices);

        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

        // 解冻token0
        _unfreeze(balances, channel.token0, uint(total.ethNum) * uint(channel.unit), accountIndex);
        // 解冻token1
        _unfreeze(balances, channel.token1, uint(total.tokenValue), accountIndex);
        // 解冻nest
        _unfreeze(balances, NEST_TOKEN_ADDRESS, uint(total.nestValue), accountIndex);

        uint vault = uint(channel.vault);
        uint ntokenValue = uint(total.ntokenValue);
        if (ntokenValue > vault) {
            ntokenValue = vault;
        }
        // 记录每个通道矿币的数量，防止开通者不打币，直接用资金池内的资金
        channel.vault = uint96(vault - ntokenValue);
        // 奖励矿币
        _unfreeze(balances, channel.reward, ntokenValue, accountIndex);
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    /// @param channelId 报价通道编号
    function stat(uint channelId) external override {
        PriceChannel storage channel = _channels[channelId];
        _stat(_config, channel, channel.sheets);
    }

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view override returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

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

        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);
    }

    /// @dev Estimated mining amount
    /// @param channelId 报价通道编号
    /// @return Estimated mining amount
    function estimate(uint channelId) external view override returns (uint) {

        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.sheets;
        uint index = sheets.length;
        uint blocks = 10;
        while (index > 0) {

            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.shares) > 0) {
                blocks = block.number - uint(sheet.height);
                break;
            }
        }

        return 
            blocks
            * uint(channel.rewardPerBlock) 
            * _reduction(block.number - uint(channel.genesisBlock), uint(channel.reductionRate))
            / 400;
    }

    /// @dev Query the quantity of the target quotation
    /// @param channelId 报价通道编号
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view override returns (uint minedBlocks, uint totalShares) {

        PriceSheet[] storage sheets = _channels[channelId].sheets;
        PriceSheet memory sheet = sheets[index];

        // The bite sheet or ntoken sheet dosen't mining
        if (uint(sheet.shares) == 0) {
            return (0, 0);
        }

        return _calcMinedBlocks(sheets, index, sheet);
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId 报价通道编号
    function totalETHRewards(uint channelId) external view override returns (uint) {
        return _channels[channelId].feeInfo;
    }

    /// @dev Pay
    /// @param channelId 报价通道编号
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address tokenAddress, address to, uint value) external override {

        PriceChannel storage channel = _channels[channelId];
        require(channel.governance == msg.sender, "NOM:!governance");
        channel.feeInfo -= value;

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) public view returns (address) {
        return _accounts[index].addr;
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint) {
        return _accounts.length;
    }

    // Convert PriceSheet to PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // Index number
            uint32(index),
            // Miner address
            _indexAddress(sheet.miner),
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
            uint152(_decodeFloat(sheet.priceFloat))
        );
    }

    // Create price sheet
    function _createPriceSheet(
        PriceSheet[] storage sheets,
        uint accountIndex,
        uint32 ethNum,
        uint nestNum1k,
        uint level_shares,
        uint equivalent
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
            _encodeFloat(equivalent)
        ));
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
                    uint tmp = _decodeFloat(p0.priceFloat);
                    // New price
                    uint price = totalTokenValue / totalEthNum;
                    // Update price
                    p0.remainNum = uint32(totalEthNum);
                    p0.priceFloat = _encodeFloat(price);
                    // Clear cumulative values
                    totalEthNum = 0;
                    totalTokenValue = 0;

                    if (tmp > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 90% + price[i] * 10%
                        p0.avgFloat = _encodeFloat((_decodeFloat(p0.avgFloat) * 9 + price) / 10);

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
            totalTokenValue += _decodeFloat(sheet.priceFloat) * uint(sheet.remainNum);
        }

        // Update price information
        if (index > uint(p0.index)) {
            p0.index = uint32(index);
            channel.price = p0;
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
        uint rewardPerBlock,
        uint genesisBlock,
        uint reductionRate
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
                // TODO: 出矿逻辑
                value.ntokenValue = uint96(
                    mined
                    * tmp
                    * _reduction(height - genesisBlock, reductionRate)
                    * rewardPerBlock
                    / totalShares / 400
                );
            }

            value.nestValue = uint96(uint(sheet.nestNum1k) * 1000 ether);
            value.ethNum = uint64(sheet.ethNumBal);
            value.tokenValue = _decodeFloat(sheet.priceFloat) * uint(sheet.tokenNumBal);

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
        uint[] memory indices
    ) private returns (uint accountIndex, Tuple memory total) {

        PriceSheet[] storage sheets = channel.sheets;
        accountIndex = 0; 

        uint rewardPerBlock = uint(channel.rewardPerBlock);
        uint genesisBlock = uint(channel.genesisBlock);
        uint reductionRate = uint(channel.reductionRate);

        // 1. Traverse sheets
        for (uint i = indices.length; i > 0;) {

            // Because too many variables need to be returned, too many variables will be defined, 
            // so the structure of tuple is defined
            (uint minerIndex, Tuple memory value) = _close(
                config, 
                sheets, 
                indices[--i], 
                rewardPerBlock,
                genesisBlock,
                reductionRate
            );
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

    /// @dev freeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount
    /// @param value 剩余的eth数量
    function _freeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint value
    ) private returns (uint) {
        if (tokenAddress == address(0)) {
            return value - tokenValue;
        } else {
            // Unfreeze nest
            UINT storage balance = balances[tokenAddress];
            uint balanceValue = balance.value;
            if (balanceValue < tokenValue) {
                balance.value = 0;
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            } else {
                balance.value = balanceValue - tokenValue;
            }
            return value;
        }
    }

    function _unfreeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint accountIndex
    ) private {
        if (tokenValue > 0) {
            if (tokenAddress == address(0)) {
                payable(_indexAddress(accountIndex)).transfer(tokenValue);
            } else {
                balances[tokenAddress].value += tokenValue;
            }
        }
    }

    function _unfreeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        address owner
    ) private {
        if (tokenValue > 0) {
            if (tokenAddress == address(0)) {
                payable(owner).transfer(tokenValue);
            } else {
                balances[tokenAddress].value += tokenValue;
            }
        }
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function _indexAddress(uint index) public view returns (address) {
        return _accounts[index].addr;
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

    // // Calculation of attenuation gradient
    // function _reduction(uint delta) private pure returns (uint) {

    //     if (delta < NEST_REDUCTION_LIMIT) {
    //         return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
    //     }
    //     return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    // }

    function _reduction(uint delta, uint reductionRate) private pure returns (uint) {
        // TODO: 实现衰减参数算法
        if (delta < NEST_REDUCTION_LIMIT) {
            uint n = delta / NEST_REDUCTION_SPAN;
            return 400 * reductionRate ** n / 10000 ** n;
        }
        return 400 * reductionRate ** 10 / 10000 ** 10;
    }

    /* ========== Tools and methods ========== */

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint56) {

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
    function _decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    /* ========== 价格查询 ========== */
    
    /// @dev Get the latest trigger price
    /// @param channel 报价通道
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _triggeredPrice(PriceChannel storage channel) internal view returns (uint blockNumber, uint price) {

        PriceInfo memory priceInfo = channel.price;

        if (uint(priceInfo.remainNum) > 0) {
            return (uint(priceInfo.height) + uint(_config.priceEffectSpan), _decodeFloat(priceInfo.priceFloat));
        }
        
        return (0, 0);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channel 报价通道
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function _triggeredPriceInfo(PriceChannel storage channel) internal view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {

        PriceInfo memory priceInfo = channel.price;

        if (uint(priceInfo.remainNum) > 0) {
            return (
                uint(priceInfo.height) + uint(_config.priceEffectSpan),
                _decodeFloat(priceInfo.priceFloat),
                _decodeFloat(priceInfo.avgFloat),
                (uint(priceInfo.sigmaSQ) * 1 ether) >> 48
            );
        }

        return (0, 0, 0, 0);
    }

    /// @dev Find the price at block number
    /// @param channel 报价通道
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _findPrice(
        PriceChannel storage channel,
        uint height
    ) internal view returns (uint blockNumber, uint price) {

        PriceSheet[] storage sheets = channel.sheets;
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
                totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
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
                totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
            }
        }

        if (totalEthNum > 0) {
            return (h + priceEffectSpan, totalTokenValue / totalEthNum);
        }
        return (0, 0);
    }

    /// @dev Get the latest effective price
    /// @param channel 报价通道
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _latestPrice(PriceChannel storage channel) internal view returns (uint blockNumber, uint price) {

        PriceSheet[] storage sheets = channel.sheets;
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
            totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
        }

        return (0, 0);
    }

    /// @dev Get the last (num) effective price
    /// @param channel 报价通道
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function _lastPriceList(PriceChannel storage channel, uint count) internal view returns (uint[] memory) {

        PriceSheet[] storage sheets = channel.sheets;
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
            totalTokenValue += _decodeFloat(sheet.priceFloat) * remainNum;
        }

        return array;
    } 

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param channel 报价通道
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function _latestPriceAndTriggeredPriceInfo(PriceChannel storage channel) internal view 
    returns (
        uint latestPriceBlockNumber,
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        (latestPriceBlockNumber, latestPriceValue) = _latestPrice(channel);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = _triggeredPriceInfo(channel);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channel 报价通道
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function _lastPriceListAndTriggeredPriceInfo(PriceChannel storage channel, uint count) internal view
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        prices = _lastPriceList(channel, count);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = _triggeredPriceInfo(channel);
    }
}