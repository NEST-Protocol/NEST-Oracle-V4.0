// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the methods for redeeming
interface INestRedeeming {

    /// @dev Redeem configuration structure
    struct Config {

        // Redeem activate threshold, when the circulation of token exceeds this threshold, 
        // activate redeem (Unit: 10000 ether). 500 
        uint32 activeThreshold;

        // The number of nest redeem per block. 1000
        uint16 nestPerBlock;

        // The maximum number of nest in a single redeem. 300000
        uint32 nestLimit;

        // The number of ntoken redeem per block. 10
        uint16 ntokenPerBlock;

        // The maximum number of ntoken in a single redeem. 3000
        uint32 ntokenLimit;

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 500
        uint16 priceDeviationLimit;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Redeem ntoken for ethers
    /// @notice Eth fee will be charged
    /// @param ntokenAddress The address of ntoken
    /// @param amount The amount of ntoken
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeem(address ntokenAddress, uint amount, address paybackAddress) external payable;

    /// @dev Get the current amount available for repurchase
    /// @param ntokenAddress The address of ntoken
    function quotaOf(address ntokenAddress) external view returns (uint);
}