// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestOpenMining {
    
    /// @dev 开通报价通道
    /// @param channelId 报价通道编号
    /// @param token0 计价代币地址。0表示eth
    /// @param unit token0的单位
    /// @param token1 报价代币地址。0表示eth
    /// @param reward 挖矿代币地址。0表示不挖矿
    event Open(uint channelId, address token0, uint unit, address token1, address reward);

    /// @dev Post event
    /// @param channelId 报价通道编号
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale 报价规模
    event Post(uint channelId, address miner, uint index, uint scale, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // Eth number of each post. 30
        // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
        uint32 postEthUnit;

        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Proportion of miners digging(10000 based). 8000
        uint16 minerNestReward;
        
        // The proportion of token dug by miners is only valid for the token created in version 3.0
        // (10000 based). 9500
        uint16 minerNTokenReward;

        // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
        uint32 doublePostThreshold;
        
        // The limit of ntoken mined blocks. 100
        uint16 ntokenMinedBlockLimit;

        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint8 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post (Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev PriceSheetView structure
    struct PriceSheetView {
        
        // Index of the price sheet
        uint32 index;

        // Address of miner
        address miner;

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

        // The token price. (1eth equivalent to (price) token)
        uint152 price;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        uint sheetCount;

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
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // Double query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 doubleFee;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
    
    /// @dev 开通报价通道
    /// @param token0 计价代币地址。0表示eth
    /// @param unit token0的单位
    /// @param token1 报价代币地址。0表示eth
    /// @param reward 挖矿代币地址。0表示挖eth
    function open(address token0, uint unit, address token1, address reward) external;

    /// @dev 向报价通道注入矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increase(uint channelId, uint96 vault) external payable;

    /// @dev 获取报价通道信息
    /// @param channelId 报价通道
    /// @return 报价通道信息
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev 报价
    /// @param channelId 报价通道id
    /// @param scale 报价规模（token0，单位unit）
    /// @param equivalent 与单位token0等价的token1数量
    function post(uint channelId, uint scale, uint equivalent) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId 报价通道编号
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken0(uint channelId, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function takeToken1(uint channelId, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @dev List sheets by page
    /// @param channelId 报价通道编号
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(uint channelId, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed
    /// @param channelId 报价通道编号
    /// @param index The index of the price sheet w.r.t. `token`
    function close(uint channelId, uint index) external;
    
    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId 报价通道编号
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(uint channelId, uint[] memory indices) external;

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    /// @param channelId 报价通道编号
    function stat(uint channelId) external;

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external;

    /// @dev Estimated mining amount
    /// @param channelId 报价通道编号
    /// @return Estimated mining amount
    function estimate(uint channelId) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param channelId 报价通道编号
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view returns (uint minedBlocks, uint totalShares);

    /// @dev Pay
    /// @param channelId 报价通道编号
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address tokenAddress, address to, uint value) external;
}