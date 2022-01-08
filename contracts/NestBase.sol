// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./interfaces/INestGovernance.sol";
import "./interfaces/INestLedger.sol";

/// @dev Base contract of nest
contract NestBase {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "NEST:!initialize");
        _governance = governance;
    }

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual {
        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = newGovernance;
    }

    // /// @dev Migrate funds from current contract to NestLedger
    // /// @param tokenAddress Destination token address.(0 means eth)
    // /// @param value Migrate amount
    // function migrate(address tokenAddress, uint value) external onlyGovernance {

    //     address to = INestGovernance(_governance).getNestLedgerAddress();
    //     if (tokenAddress == address(0)) {
    //         INestLedger(to).addETHReward { value: value } (0);
    //     } else {
    //         TransferHelper.safeTransfer(tokenAddress, to, value);
    //     }
    // }

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