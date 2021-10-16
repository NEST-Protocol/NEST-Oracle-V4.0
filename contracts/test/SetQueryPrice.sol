// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interface/IVotePropose.sol";
import "../interface/INestMapping.sol";
import "../interface/INestPriceFacade.sol";

/// @dev The test modifies the price call parameter configuration by voting
contract SetQueryPrice is IVotePropose {

    address _nestMappingAddress;

    constructor(address nestMappingAddress) {
        _nestMappingAddress = nestMappingAddress;
    }

    /// @dev Methods to be called after approved
    function run() external override {

        // /// @dev Set the built-in contract address of the system
        // /// @return nestTokenAddress Address of nest token contract
        // /// @return nestNodeAddress Address of nest node contract
        // /// @return nestLedgerAddress INestLedger implementation contract address
        // /// @return nestMiningAddress INestMining implementation contract address for nest
        // /// @return ntokenMiningAddress INestMining implementation contract address for ntoken
        // /// @return nestPriceFacadeAddress INestPriceFacade implementation contract address
        // /// @return nestVoteAddress INestVote implementation contract address
        // /// @return nestQueryAddress INestQuery implementation contract address
        // /// @return nnIncomeAddress NNIncome contract address
        // /// @return nTokenControllerAddress INTokenController implementation contract address
        // (
        //     , //address nestTokenAddress,
        //     , //address nestNodeAddress,
        //     , //address nestLedgerAddress,
        //     , //address nestMiningAddress,
        //     , //address ntokenMiningAddress,
        //     address nestPriceFacadeAddress,
        //     , //address nestVoteAddress,
        //     , //address nestQueryAddress,
        //     , //address nnIncomeAddress,
        //       //address nTokenControllerAddress
        // ) = INestMapping(_nestMappingAddress).getBuiltinAddress();

        address nestPriceFacadeAddress = INestMapping(_nestMappingAddress).getNestPriceFacadeAddress();

        INestPriceFacade(nestPriceFacadeAddress).setConfig(INestPriceFacade.Config(
            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            uint16(200),
            // Double query fee (0.0001 ether, DIMI_ETHER). 100
            uint16(400),
            // The normal state flag of the call address. 0
            uint8(0)
        ));
    }
}