// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestOpenMining {
    
    /// @dev PriceChannel open event
    /// @param channelId Target channelId
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param token1 Address of token1, 0 means eth
    /// @param reward Reward token address
    event Open(uint channelId, address token0, uint unit, address token1, address reward);

    /// @dev Post event
    /// @param channelId Target channelId
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale Scale of this post. (Which times of unit)
    event Post(uint channelId, address miner, uint index, uint scale, uint price);

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

    // PriceChannel configuration
    struct ChannelConfig {

        // Reward per block standard
        uint96 rewardPerBlock;

        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        uint sheetCount;

        // The information of mining fee
        // Low 128-bits represent fee per post
        // High 128-bits represent the current counter of no fee sheets (including settled)
        uint feeInfo;

        // Address of token0, use to mensuration, 0 means eth
        address token0;
        // Unit of token0
        uint96 unit;

        // Address of token1, 0 means eth
        address token1;
        // Reward per block standard
        uint96 rewardPerBlock;

        // Reward token address
        address reward;
        // Reward total
        uint96 vault;

        // Governance address of this channel
        address governance;
        // Genesis block of this channel
        uint32 genesisBlock;
        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Open price channel
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    /// @param token1 Address of token1, 0 means eth
    /// @param config Channel configuration
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address token1, 
        ChannelConfig calldata config
    ) external;

    /// @dev Modify channel configuration
    /// @param channelId Target channelId
    /// @param config Channel configuration
    function modify(uint channelId, ChannelConfig calldata config) external;

    /// @dev Increase vault to channel
    /// @param channelId Target channelId
    /// @param vault Total to increase
    function increase(uint channelId, uint96 vault) external payable;

    /// @dev Decrease vault from channel
    /// @param channelId Target channelId
    /// @param vault Total to decrease
    function decrease(uint channelId, uint96 vault) external;

    /// @dev Get channel information
    /// @param channelId Target channelId
    /// @return Information of channel
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev Post price
    /// @param channelId Target channelId
    /// @param scale Scale of this post. (Which times of unit)
    /// @param equivalent Amount of token1 which equivalent to token0
    function post(uint channelId, uint scale, uint equivalent) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId Target price channelId
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
    /// @param channelId Target channelId
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(uint channelId, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId Target channelId
    /// @param indices A list of indices of sheets w.r.t. `token`
    function close(uint channelId, uint[] memory indices) external;

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    /// @param channelId Target channelId
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
    /// @param channelId Target channelId
    /// @return Estimated mining amount
    function estimate(uint channelId) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param channelId Target channelId
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view returns (uint minedBlocks, uint totalShares);

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId Target channelId
    function totalETHRewards(uint channelId) external view returns (uint);

    /// @dev Pay
    /// @param channelId Target channelId
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external;

    /// @dev Donate to dao
    /// @param channelId Target channelId
    /// @param value Amount to receive
    function donate(uint channelId, uint value) external;
}