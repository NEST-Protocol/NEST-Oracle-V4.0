// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/INToken.sol";
import "./interfaces/INestGovernance.sol";
import "./NestBase.sol";

// The contract is based on Nest_NToken from Nest Protocol v3.0. Considering compatibility, the interface
// keeps the same. 
/// @dev ntoken contract
contract NToken is NestBase, INToken {

    /// @notice Constructor
    /// @dev Given the address of NestPool, NToken can get other contracts by calling addr Of xxx()
    /// @param _name The name of NToken
    /// @param _symbol The symbol of NToken
    constructor (string memory _name, string memory _symbol) {

        GENESIS_BLOCK_NUMBER = block.number;
        name = _name;                                                               
        symbol = _symbol;
        _state = block.number;
    }

    // INestMining implementation contract address
    address _ntokenMiningAddress;
    
    // token information: name
    string public name;

    // token information: symbol
    string public symbol;

    // token information: decimals
    uint8 constant public decimals = 18;

    // token state, high 128 bits represent _totalSupply, low 128 bits represent latestMintAtHeight
    uint256 _state;
    
    // Balances ledger
    mapping (address=>uint) private _balances;

    // Approve ledger
    mapping (address=>mapping(address=>uint)) private _allowed;

    // ntoken genesis block number
    uint256 immutable public GENESIS_BLOCK_NUMBER;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _ntokenMiningAddress = INestGovernance(newGovernance).getNTokenMiningAddress();
    }

    /// @dev Mint 
    /// @param value The amount of NToken to add
    function increaseTotal(uint256 value) public override {

        require(msg.sender == _ntokenMiningAddress, "NToken:!Auth");
        
        // Increases balance for target address
        _balances[msg.sender] += value;

        // Increases total supply
        uint totalSupply_ = (_state >> 128) + value;
        require(totalSupply_ < 0x100000000000000000000000000000000, "NToken:!totalSupply");
        // Total supply and latest mint height share one storage unit
        _state = (totalSupply_ << 128) | block.number;
    }
        
    /// @notice The view of variables about minting 
    /// @dev The naming follows nest v3.0
    /// @return createBlock The block number where the contract was created
    /// @return recentlyUsedBlock The block number where the last minting went
    function checkBlockInfo() 
        public view override 
        returns(uint256 createBlock, uint256 recentlyUsedBlock) 
    {
        return (GENESIS_BLOCK_NUMBER, _state & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining
    /// @return The address of bidder
    function checkBidder() public view override returns(address) {
        return _ntokenMiningAddress;
    }

    /// @notice The view of totalSupply
    /// @return The total supply of ntoken
    function totalSupply() public view override returns (uint256) {
        // The high 128 bits means total supply
        return _state >> 128;
    }

    /// @dev The view of balances
    /// @param owner The address of an account
    /// @return The balance of the account
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) 
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool) 
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) 
    {
        mapping(address=>uint) storage allowed = _allowed[from];
        allowed[msg.sender] -= value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        mapping(address=>uint) storage allowed = _allowed[msg.sender];
        allowed[spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        mapping(address=>uint) storage allowed = _allowed[msg.sender];
        allowed[spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }
}