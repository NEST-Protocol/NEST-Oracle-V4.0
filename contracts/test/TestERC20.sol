// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../libs/ERC20_LIB.sol";

contract TestERC20 is ERC20_LIB {

    constructor (string memory name, string memory symbol, uint8 decimals) ERC20_LIB (name, symbol) {
        //_name = name;
        //_symbol = symbol;
        //_decimals = decimals;
        _setupDecimals(decimals);
    }

    function transfer(address to, uint value) public override returns (bool) {
        
        if(value > 0 && balanceOf(msg.sender) == 0) {
            //require(value <= 100000000 ether, "TestERC20: mint value can not greater than 100000000 ether");
            require(value < 0x1000000000000000000000000000000000000000000000000, "TestERC20:value to large");
            _mint(msg.sender, value);
        }
        super.transfer(to, value);
        
        return true;
    }
}
