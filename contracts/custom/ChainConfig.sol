// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Specific data for target chain
contract ChainConfig {

    // ******** Ethereum ******** //

    // Ethereum average block time interval, 14000 milliseconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 14000;

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; //NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    //uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;

    // ******** BSC ******** //
    
    // // Ethereum average block time interval, 3000 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 3000;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 10000000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 100000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;

    // ******** Ploygon ******** //

    // // Ethereum average block time interval, 2200 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 2200;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 15000000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 150000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
}