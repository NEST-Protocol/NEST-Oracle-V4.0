// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/TransferHelper.sol";

import "./interface/INestBatchPriceView.sol";
import "./interface/INestBatchPrice.sol";

import "./NestBatchMining.sol";

/// @dev This contract implemented the mining logic of nest
contract NestBatchPlatform2 is NestBatchMining, INestBatchPriceView {

    // TODO: 支持pairIndex数组，可以一次性查询多个价格

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
        return _triggeredPrice(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, uint pairIndex) external view override noContract returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return _triggeredPriceInfo(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint pairIndex,
        uint height
    ) external view override noContract returns (uint blockNumber, uint price) {
        return _findPrice(_channels[channelId].pairs[pairIndex], height);
    }

    /// @dev Get the latest effective price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
        return _latestPrice(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId].pairs[pairIndex], count);
    } 

    // /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    // /// @param channelId 报价通道编号
    // /// @param pairIndex 报价对编号
    // /// @return latestPriceBlockNumber The block number of latest price
    // /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function latestPriceAndTriggeredPriceInfo(uint channelId, uint pairIndex) external view noContract
    // returns (
    //     uint latestPriceBlockNumber,
    //     uint latestPriceValue,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // ) {
    //     return _latestPriceAndTriggeredPriceInfo(_channels[channelId].pairs[pairIndex]);
    // }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(uint channelId, uint pairIndex, uint count) external view override noContract
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        //return _lastPriceListAndTriggeredPriceInfo(_channels[channelId].pairs[pairIndex], count);
        PricePair storage pair = _channels[channelId].pairs[pairIndex];
        prices = _lastPriceList(pair, count);
        (
            triggeredPriceBlockNumber, 
            triggeredPriceValue, 
            triggeredAvgPrice, 
            triggeredSigmaSQ
        ) = _triggeredPriceInfo(pair);
    }

    // Payment of transfer fee
    function _pay(uint channelId, address payback) private returns (PriceChannel storage channel) {

        channel = _channels[channelId];
        uint fee = uint(channel.singleFee) * DIMI_ETHER;
        if (msg.value > fee) {
            //payable(payback).transfer(msg.value - fee);
            TransferHelper.safeTransferETH(payback, msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.rewards += fee;
    }

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _triggeredPrice(channel.pairs[n >> 1]);
        }
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 4 为第i个价格所在区块, i * 4 + 1 为第i个价格, i * 4 + 2 为第i个平均价格, i * 4 + 3 为第i个波动率
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (
        uint[] memory prices
    ) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint n = pairIndices.length << 2;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1], prices[n + 2], prices[n + 3]) = _triggeredPriceInfo(channel.pairs[n >> 2]);
        }
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param height Destination block number
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable returns (uint[] memory prices) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _findPrice(channel.pairs[n >> 1], height);
        }
    }

    /// @dev Get the latest effective price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function latestPrice(
        uint channelId, 
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _latestPrice(channel.pairs[n >> 1]);
        }
    }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * count * 2 到 (i + 1) * count * 2 - 1为第i组报价对的价格结果
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint row = count << 1;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;
            uint[] memory pi = _lastPriceList(channel.pairs[n / row], count);
            for (uint i = 0; i < row; ++i) {
                prices[n + i] = pi[i];
            }
        }
    }

    // /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    // /// @param channelId 报价通道编号
    // /// @param pairIndex 报价对编号
    // /// @param payback 如果费用有多余的，则退回到此地址
    // /// @return latestPriceBlockNumber The block number of latest price
    // /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function latestPriceAndTriggeredPriceInfo(uint channelId, uint pairIndex, address payback) external payable
    // returns (
    //     uint latestPriceBlockNumber,
    //     uint latestPriceValue,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // ) {
    //     PriceChannel storage channel = _channels[channelId];
    //     _pay(channel, uint(channel.singleFee), payback);
    //     return _latestPriceAndTriggeredPriceInfo(channel.pairs[pairIndex]);
    // }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 结果数组，第 i * (count * 2 + 4)到 (i + 1) * (count * 2 + 4)- 1为第i组报价对的价格结果
    ///         其中前count * 2个为最新价格，后4个依次为：触发价格区块号，触发价格，平均价格，波动率
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices) {
        PriceChannel storage channel = _pay(channelId, payback);

        uint row = (count << 1) + 4;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;

            PricePair storage pair = channel.pairs[n / row];
            uint[] memory pi = _lastPriceList(pair, count);
            for (uint i = 0; i + 4 < row; ++i) {
                prices[n + i] = pi[i];
            }
            uint j = n + row - 4;
            (
                prices[j],
                prices[j + 1],
                prices[j + 2],
                prices[j + 3]
            ) = _triggeredPriceInfo(pair);
        }
    }
}