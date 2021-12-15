// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interfaces/INestBatchPrice2.sol";
import "hardhat/console.sol";

contract QueryTest {

    address _nestBatchPlatform2;

    constructor(address nestBatchPlatform2) {
        _nestBatchPlatform2 = nestBatchPlatform2;
    }

    function query() external payable {
        uint[] memory idxes = new uint[](1);
        //idxes[0] = 0;
        idxes[0] = 1;
        uint[] memory prices = INestBatchPrice2(_nestBatchPlatform2).latestPrice { value: msg.value } (0, idxes, msg.sender);
        for (uint i = 0; i < prices.length; ++i) {
            console.log("query-prices", prices[i]);
        }

        uint v = 0x1000000000000000000000000;
        for (uint i = 0; i < 5; ++i) {
            console.log("query-v", uint(uint96(v - i)));
        }
    }
}