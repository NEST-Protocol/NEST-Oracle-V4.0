// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Interface to be implemented for voting contract
interface IVotePropose {

    /// @dev Methods to be called after approved
    function run() external;
}