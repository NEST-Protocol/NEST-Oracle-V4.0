// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestBatchPriceView.sol";
import "./interfaces/INestBatchPrice.sol";

import "./NestBatchMining.sol";

/// @dev This contract implemented the mining logic of nest
contract NestBatchPlatform is NestBatchMining, INestBatchPriceView, INestBatchPrice {

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

    // /// @dev Get the latest effective price
    // /// @param channelId 报价通道编号
    // /// @param pairIndex 报价对编号
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
    //     return _latestPrice(_channels[channelId].pairs[pairIndex]);
    // }

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

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        uint channelId,
        uint pairIndex, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        return _triggeredPrice(_pay(channelId, payback).pairs[pairIndex]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        uint channelId, 
        uint pairIndex,
        address payback
    ) external payable override returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return _triggeredPriceInfo(_pay(channelId, payback).pairs[pairIndex]);
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param height Destination block number
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint pairIndex,
        uint height, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        return _findPrice(_pay(channelId, payback).pairs[pairIndex], height);
    }

    // /// @dev Get the latest effective price
    // /// @param channelId 报价通道编号
    // /// @param pairIndex 报价对编号
    // /// @param payback 如果费用有多余的，则退回到此地址
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(
    //     uint channelId, 
    //     uint pairIndex,
    //     address payback
    // ) external payable override returns (
    //     uint blockNumber, 
    //     uint price
    // ) {
    //     return _latestPrice(_pay(channelId, payback).pairs[pairIndex]);
    // }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(
        uint channelId, 
        uint pairIndex,
        uint count, 
        address payback
    ) external payable override returns (uint[] memory) {
        return _lastPriceList(_pay(channelId, payback).pairs[pairIndex], count);
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
    /// @param pairIndex 报价对编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint pairIndex,
        uint count, 
        address payback
    ) external payable override returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        PricePair storage pair = _pay(channelId, payback).pairs[pairIndex];
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
            payable(payback).transfer(msg.value - fee);
            // TODO: BSC上采用的是老的gas计算策略，直接转账可能导致代理合约gas超出，要改用下面的方式转账
            //TransferHelper.safeTransferETH(payback, msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.rewards += _toUInt96(fee);
    }
}