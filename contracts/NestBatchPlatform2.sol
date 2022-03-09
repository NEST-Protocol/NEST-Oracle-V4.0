// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestBatchPriceView.sol";
import "./interfaces/INestBatchPrice2.sol";

import "./NestBatchMining.sol";

/// @dev This contract implemented the query logic of nest
contract NestBatchPlatform2 is NestBatchMining, INestBatchPriceView, INestBatchPrice2 {

    /* ========== INestBatchPriceView ========== */

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(uint channelId, uint pairIndex) external view override noContract returns (uint blockNumber, uint price) {
        return _triggeredPrice(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
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
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
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

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId].pairs[pairIndex], count);
    } 

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber|price
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

    /* ========== INestBatchPrice ========== */

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _triggeredPrice(pairs[pairIndices[n >> 1]]);
        }
    }

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 4 is the block where the ith price is located, i * 4 + 1 is the ith price,
    /// i * 4 + 2 is the ith average price and i * 4 + 3 is the ith volatility
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 2;
        prices = new uint[](n);
        while (n > 0) {
            n -= 4;
            (prices[n], prices[n + 1], prices[n + 2], prices[n + 3]) = _triggeredPriceInfo(pairs[pairIndices[n >> 2]]);
        }
    }

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param height Destination block number
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _findPrice(pairs[pairIndices[n >> 1]], height);
        }
    }

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices Result array, i * count * 2 to (i + 1) * count * 2 - 1 are 
    /// the price results of group i quotation pairs
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint row = count << 1;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;
            uint[] memory pi = _lastPriceList(pairs[pairIndices[n / row]], count);
            for (uint i = 0; i < row; ++i) {
                prices[n + i] = pi[i];
            }
        }
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices result of group i quotation pair. Among them, the first two count * are the latest prices, 
    /// and the last four are: trigger price block number, trigger price, average price and volatility
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint row = (count << 1) + 4;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;

            PricePair storage pair = pairs[pairIndices[n / row]];
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

    // Payment of transfer fee
    function _pay(uint channelId, address payback) private returns (PriceChannel storage channel) {

        channel = _channels[channelId];
        uint fee = uint(channel.singleFee) * DIMI_ETHER;
        if (msg.value > fee) {
            payable(payback).transfer(msg.value - fee);
            // BSC adopts the old gas calculation strategy. Direct transfer may lead to the excess of gas 
            // in the agency contract. The following methods should be used for transfer
            //TransferHelper.safeTransferETH(payback, msg.value - fee);
        } else {
            require(msg.value == fee, "NOP:!fee");
        }

        channel.rewards += _toUInt96(fee);
    }
}