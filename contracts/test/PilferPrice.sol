// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interface/INestMining.sol";

/// @dev Base contract of nest
contract PilferPrice {

    address _nestMining;

    constructor() { }

    function setNestMining(address nestMining) external {
        _nestMining = nestMining;
    }

    // /// @dev List sheets by page
    // /// @param tokenAddress Destination token address
    // /// @param offset Skip previous (offset) records
    // /// @param count Return (count) records
    // /// @param order Order. 0 reverse order, non-0 positive order
    // /// @return List of price sheets
    // function list(address tokenAddress, uint offset, uint count, uint order) external view returns (PriceSheetView[] memory);

    function pilfer(address tokenAddress) external view returns (uint blockNumber, uint price) {
        INestMining.PriceSheetView[] memory sheets = INestMining(_nestMining).list(tokenAddress, 0, 10, 0);
        INestMining.PriceSheetView memory sheet;

        uint priceEffectSpan = 20;
        uint h = block.number - priceEffectSpan;
        uint index = 0;
        uint totalEthNum = 0;
        uint totalTokenValue = 0;
        uint height = 0;

        for (; ; ) {

            bool flag = index == sheets.length;
            if (flag || height != uint((sheet = sheets[index++]).height)) {
                if (totalEthNum > 0 && height <= h) {
                    return (height + priceEffectSpan, totalTokenValue / totalEthNum);
                }
                if (flag) {
                    break;
                }
                totalEthNum = 0;
                totalTokenValue = 0;
                height = uint(sheet.height);
            }

            uint remainNum = uint(sheet.remainNum);
            totalEthNum += remainNum;
            totalTokenValue += uint(sheet.price) * remainNum;
        }

        return (0, 0);
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
}