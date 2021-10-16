// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev ntoken interface
interface INToken {
        
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Mint 
    /// @param value The amount of NToken to add
    function increaseTotal(uint256 value) external;

    /// @notice The view of variables about minting 
    /// @dev The naming follows nest v3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);

    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining
    /// @return The address of bidder
    function checkBidder() external view returns(address);
    
    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() external view returns (uint256);

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256); 

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}