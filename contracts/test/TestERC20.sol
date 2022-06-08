// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../libs/SimpleERC20.sol";

contract TestERC20 is SimpleERC20 {
    string _name;
    string _symbol;
    uint8 _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function transfer(address to, uint value) public override returns (bool) {
        
        if(value > 0 && _balances[msg.sender] == 0) {
            require(value <= 10000000000000000 ether, 
                "TestERC20: mint value can not greater than 10000000000000000 ether");
            //require(value < 0x1000000000000000000000000000000000000000000000000, "TestERC20:value to large");
            _mint(msg.sender, value);
        }
        super._transfer(msg.sender, to, value);
        
        return true;
    }
}
