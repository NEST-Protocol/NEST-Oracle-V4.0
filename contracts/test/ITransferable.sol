// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Base contract of nest
interface ITransferable {

    /// @dev Transfer funds from current contracts
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param to Transfer in address
    /// @param value Transfer amount
    function transfer(address tokenAddress, address to, uint value) external;
}