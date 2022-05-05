// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interfaces/INestGovernance.sol";
import "../NestBase.sol";

/// @dev Base contract of nest
contract NestFrequentlyUsed is NestBase {

    // Address of nest token contract
    address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // Genesis block number of nest
    // NEST token contract is created at block height 6913517. However, because the mining algorithm of nest1.0
    // is different from that at present, a new mining algorithm is adopted from nest2.0. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the nest begins to decay. According to the circulation when nest2.0 is online, the new mining
    // algorithm is used to deduce and convert the nest, and the new algorithm is used to mine the nest2.0
    // on-line flow, the actual block is 5120000
    //uint constant NEST_GENESIS_BLOCK = 0;

    // /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    // ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    // /// @param newGovernance IHedgeGovernance implementation contract address
    // function update(address newGovernance) public virtual override {
    //     super.update(newGovernance);
    //     NEST_TOKEN_ADDRESS = INestGovernance(newGovernance).getNestTokenAddress();
    // }
}
