// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPrice2 {

    /// @dev Get the latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 2 为第i个价格所在区块, i * 2 + 1 为第i个价格
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the full information of latest trigger price
    /// @param channelId 报价通道编号
    /// @param pairIndices 报价对编号
    /// @param payback 如果费用有多余的，则退回到此地址
    /// @return prices 价格数组, i * 4 为第i个价格所在区块, i * 4 + 1 为第i个价格, 
    ///         i * 4 + 2 为第i个平均价格, i * 4 + 3 为第i个波动率
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);

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
    ) external payable returns (uint[] memory prices);

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
    ) external payable returns (uint[] memory prices);

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
    ) external payable returns (uint[] memory prices);
}