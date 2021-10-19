// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestOpenPrice {
    
    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId, address payback) external payable returns (uint blockNumber, uint price);

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, address payback) external payable returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    );

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param height Destination block number
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint height, 
        address payback
    ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the latest effective price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(uint channelId, address payback) external payable returns (uint blockNumber, uint price);

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(uint channelId, uint count, address payback) external payable returns (uint[] memory);

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(uint channelId, address payback) external payable 
    returns (
        uint latestPriceBlockNumber,
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(uint channelId, uint count, address payback) external payable 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    );
}