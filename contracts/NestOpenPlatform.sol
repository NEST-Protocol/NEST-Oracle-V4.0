// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/TransferHelper.sol";
import "./interface/INestOpenMining.sol";
import "./interface/INestQuery.sol";
import "./interface/INTokenController.sol";
import "./interface/INestLedger.sol";
import "./interface/INToken.sol";
import "./interface/INestPriceView.sol";
import "./interface/INestOpenPrice.sol";

import "./NestOpenMining.sol";

import "hardhat/console.sol";

/// @dev This contract implemented the mining logic of nest
contract NestOpenPlatform is NestOpenMining, INestPriceView, INestOpenPrice {

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId) external view override noContract returns (uint blockNumber, uint price) {
        return _triggeredPrice(_channels[channelId]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId) external view override noContract returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return _triggeredPriceInfo(_channels[channelId]);
    }

    /// @dev Find the price at block number
    /// @param channelId 报价通道编号
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint height
    ) external view override noContract returns (uint blockNumber, uint price) {
        return _findPrice(_channels[channelId], height);
    }

    /// @dev Get the latest effective price
    /// @param channelId 报价通道编号
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(uint channelId) external view override noContract returns (uint blockNumber, uint price) {
        return _latestPrice(_channels[channelId]);
    }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(uint channelId, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId], count);
    } 

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param channelId 报价通道编号
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(uint channelId) external view override noContract
    returns (
        uint latestPriceBlockNumber,
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        return _latestPriceAndTriggeredPriceInfo(_channels[channelId]);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId 报价通道编号
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(uint channelId, uint count) external view override noContract
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        return _lastPriceListAndTriggeredPriceInfo(_channels[channelId], count);
    }

    // Payment of transfer fee
    function _pay(PriceChannel storage channel, uint fee, address payback) private {

        fee = fee * DIMI_ETHER;
        if (msg.value > fee) {
            payable(payback).transfer(msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.feeInfo += fee;
    }

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        uint channelId, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _triggeredPrice(channel);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        uint channelId, 
        address payback
    ) external payable override returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _triggeredPriceInfo(channel);
    }

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
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _findPrice(channel, height);
    }

    /// @dev Get the latest effective price
    /// @param channelId 报价通道编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(
        uint channelId, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _latestPrice(channel);
    }

    /// @dev Get the last (num) effective price
    /// @param channelId 报价通道编号
    /// @param count The number of prices that want to return
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(
        uint channelId, 
        uint count, 
        address payback
    ) external payable override returns (uint[] memory) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _lastPriceList(channel, count);
    }

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
    function latestPriceAndTriggeredPriceInfo(uint channelId, address payback) external payable override
    returns (
        uint latestPriceBlockNumber,
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _latestPriceAndTriggeredPriceInfo(channel);
    }

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
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint count, 
        address payback
    ) external payable override returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        PriceChannel storage channel = _channels[channelId];
        _pay(channel, uint(channel.singleFee), payback);
        return _lastPriceListAndTriggeredPriceInfo(channel, count);
    }
}