// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestPriceView.sol";
import "./interfaces/INestOpenPrice.sol";

import "./NestOpenMining.sol";

/// @dev This contract implemented the mining logic of nest
contract NestOpenPlatform is NestOpenMining, INestPriceView, INestOpenPrice {

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId) external view override noContract returns (uint blockNumber, uint price) {
        return _triggeredPrice(_channels[channelId]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
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
    /// @param channelId Target channelId
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
    /// @param channelId Target channelId
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(uint channelId) external view override noContract returns (uint blockNumber, uint price) {
        return _latestPrice(_channels[channelId]);
    }

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function lastPriceList(uint channelId, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId], count);
    } 

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber|price
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
    function _pay(uint channelId, address payback) private returns (PriceChannel storage channel) {

        channel = _channels[channelId];
        uint fee = uint(channel.singleFee) * DIMI_ETHER;
        if (msg.value > fee) {
            //payable(payback).transfer(msg.value - fee);
            TransferHelper.safeTransferETH(payback, msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.feeInfo += fee;
    }

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @param payback Address to receive refund
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        uint channelId, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        return _triggeredPrice(_pay(channelId, payback));
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param payback Address to receive refund
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
        return _triggeredPriceInfo(_pay(channelId, payback));
    }

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param height Destination block number
    /// @param payback Address to receive refund
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
        return _findPrice(_pay(channelId, payback), height);
    }

    /// @dev Get the latest effective price
    /// @param channelId Target channelId
    /// @param payback Address to receive refund
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(
        uint channelId, 
        address payback
    ) external payable override returns (
        uint blockNumber, 
        uint price
    ) {
        return _latestPrice(_pay(channelId, payback));
    }

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function lastPriceList(
        uint channelId, 
        uint count, 
        address payback
    ) external payable override returns (uint[] memory) {
        return _lastPriceList(_pay(channelId, payback), count);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber|price
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
        return _lastPriceListAndTriggeredPriceInfo(_pay(channelId, payback), count);
    }
}