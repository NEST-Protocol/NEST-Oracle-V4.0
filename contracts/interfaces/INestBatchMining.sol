// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestBatchMining {
    
    /// @dev 开通报价通道
    /// @param channelId 报价通道编号
    /// @param token0 计价代币地址。0表示eth
    /// @param unit token0的单位
    /// @param reward 挖矿代币地址。0表示不挖矿
    event Open(uint channelId, address token0, uint unit, address reward);

    /// @dev Post event
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale 报价规模
    event Post(uint channelId, uint pairIndex, address miner, uint index, uint scale, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
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

    // 报价通道配置
    struct ChannelConfig {
        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        // 出矿代币地址
        address reward;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币总量
        //uint96 vault;

        // 管理地址
        //address governance;
        // 创世区块
        //uint32 genesisBlock;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;

        address[] tokens;
    }

    /// @dev 报价对视图
    struct PairView {
        // 报价代币地址
        address target;
        // 报价单数量
        uint96 sheetCount;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        // 出矿代币地址
        address reward;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 矿币总量
        uint128 vault;
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // 报价对数量
        uint16 count;

        // 管理地址
        address governance;
        // 创世区块
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;
        
        // 报价对信息
        PairView[] pairs;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);
    
    /// @dev 开通报价通道
    /// @param config 报价通道配置
    function open(ChannelConfig calldata config) external;

    /// @dev 向报价通道注入矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function increase(uint channelId, uint128 vault) external payable;

    /// @dev 从报价通道取出矿币
    /// @param channelId 报价通道
    /// @param vault 注入矿币数量
    function decrease(uint channelId, uint128 vault) external;

    /// @dev 获取报价通道信息
    /// @param channelId 报价通道
    /// @return 报价通道信息
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev 报价
    /// @param channelId 报价通道id
    /// @param scale 报价规模（token0，单位unit）
    /// @param equivalents 价格数组，索引和报价对一一对应
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号。吃单方向为拿走计价代币时，直接传报价对编号，吃单方向为拿走报价代币时，报价对编号加65536
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(uint channelId, uint pairIndex, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @dev List sheets by page
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId, 
        uint pairIndex, 
        uint offset, 
        uint count, 
        uint order
    ) external view returns (PriceSheetView[] memory);

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId 报价通道编号
    /// @param indices 报价单二维数组，外层对应通道号，内层对应报价单号，如果仅关闭后面的报价对，则前面的报价对数组传空数组
    function close(uint channelId, uint[][] calldata indices) external;

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

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId 报价通道编号
    function totalETHRewards(uint channelId) external view returns (uint);

    /// @dev Pay
    /// @param channelId 报价通道编号
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external;

    /// @dev 向DAO捐赠
    /// @param channelId 报价通道
    /// @param value Amount to receive
    function donate(uint channelId, uint value) external;
}