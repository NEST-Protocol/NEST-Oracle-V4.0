// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the ProxyAdmin methods
interface IProxyAdmin {

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgrade(address proxy, address implementation) external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param newOwner The address of new owner
    function transferOwnership(address newOwner) external;

    /// @dev Returns the current implementation of a proxy.
    ///      This is needed because only the proxy admin can query it.
    /// @return The address of the current implementation of the proxy.
    function getProxyImplementation(address proxy) external view returns (address);
}