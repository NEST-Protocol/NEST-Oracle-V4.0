// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../lib/TransferHelper.sol";
import "../lib/IERC20.sol";
import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestMining.sol";
import "../interface/INestPriceFacade.sol";

/// @dev Test the situation of multiple quotations in the same block through this contract
contract PostInOneBlock {

    address _nestMappingAddress;

    constructor(address nestMappingAddress) {
        //_nestMiningAddress = INestMapping(nestMappingAddress).getNestMiningAddress();
        _nestMappingAddress = nestMappingAddress;
    }

    function batchPost(address tokenAddress, uint ethNum, uint tokenAmountPerEth, uint count) public payable {

        address nestMappingAddress = _nestMappingAddress;
        (
            address nestTokenAddress,
            ,//address nestNodeAddress,
            ,//address nestLedgerAddress,
            address nestMiningAddress,
            ,//address ntokenMiningAddress,
            ,//address nestPriceFacadeAddress,
            ,//address nestVoteAddress,
            ,//address nestQueryAddress,
            ,//address nnIncomeAddress,
            //address nTokenControllerAddress
        ) = INestMapping(nestMappingAddress).getBuiltinAddress();

        IERC20(tokenAddress).approve(nestMiningAddress, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        IERC20(nestTokenAddress).approve(nestMiningAddress, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        for (uint i = 0; i < count; ++i) {
            INestMining(nestMiningAddress).post {
                value: ethNum * 1 ether + (i + 1) * 0.1 ether
            } (tokenAddress, ethNum, tokenAmountPerEth);
        }

        payable(msg.sender).transfer(address(this).balance);
    }

    /// @dev Transfer funds from current contracts
    /// @param tokenAddress Destination token address. (0 means eth) 
    /// @param to Transfer in address
    /// @param value Transfer amount
    function transfer(address tokenAddress, address to, uint value) external {
        if (tokenAddress == address(0)) {
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    receive() external payable {
    }
}