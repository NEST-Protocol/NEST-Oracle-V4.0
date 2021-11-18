// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/TransferHelper.sol";
import "./interface/INestGovernance.sol";
import "./interface/INestLedger.sol";

/// @dev Base contract of nest
contract NestBase {

    // Address of nest token contract
    //address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    address NEST_TOKEN_ADDRESS;

    // Genesis block number of nest
    // NEST token contract is created at block height 6913517. However, because the mining algorithm of nest1.0
    // is different from that at present, a new mining algorithm is adopted from nest2.0. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the nest begins to decay. According to the circulation when nest2.0 is online, the new mining
    // algorithm is used to deduce and convert the nest, and the new algorithm is used to mine the nest2.0
    // on-line flow, the actual block is 5120000
    //uint constant NEST_GENESIS_BLOCK = 0;

    /// @dev To support open-zeppelin/upgrades
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function initialize(address nestGovernanceAddress) public virtual {
        require(_governance == address(0), "NEST:!initialize");
        _governance = nestGovernanceAddress;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) public virtual {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = nestGovernanceAddress;

        NEST_TOKEN_ADDRESS = INestGovernance(nestGovernanceAddress).getNestTokenAddress();
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = INestGovernance(_governance).getNestLedgerAddress();
        if (tokenAddress == address(0)) {
            INestLedger(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}