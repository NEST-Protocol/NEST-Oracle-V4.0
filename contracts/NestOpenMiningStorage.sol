// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/INestBatchMining.sol";
import "./interfaces/INestLedger.sol";
import "./interfaces/INToken.sol";

import "./custom/ChainConfig.sol";
import "./custom/NestFrequentlyUsed.sol";

/// @dev This contract implemented the mining logic of nest
abstract contract NestOpenMiningStorage is ChainConfig, NestFrequentlyUsed, INestBatchMining {

    /// @dev Definitions for the price sheet, include the full information. 
    /// (use 256-bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160-bits) to a 32-bits 
        // integer, support 4 billion accounts
        uint32 miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // price = priceFraction * 16 ^ priceExponent
        uint56 priceFloat;
    }

    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 priceFloat;

        // Avg Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 avgFloat;

        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }

    /// @dev Price channel
    struct PriceChannelOld {

        // Array of price sheets
        PriceSheet[] sheets;

        // Price information
        PriceInfo price;

        // The information of mining fee
        // Low 128-bits represent fee per post
        // High 128-bits represent the current counter of no fee sheets (including settled)
        uint feeInfo;

        // 计价代币地址, 0表示eth
        address token0;
        // 计价代币单位
        uint96 unit;

        // 报价代币地址，0表示eth
        address token1;
        // 每个区块的标准出矿量
        uint96 rewardPerBlock;

        // 出矿代币地址
        address reward;
        // 矿币总量
        uint96 vault;

        // 管理地址
        address governance;
        // 创世区块
        uint32 genesisBlock;
        // Post fee(0.0001eth，DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // 衰减系数，万分制。8000
        uint16 reductionRate;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing 
    /// from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Account information
    struct Account {
        
        // Address of account
        address addr;

        // Balances of mining account
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    // Configuration
    Config _config;

    // Registered account information
    Account[] _accounts;

    // Mapping from address to index of account. address=>accountIndex
    mapping(address=>uint) _accountMapping;

    // 报价通道映射，通过此映射避免重复添加报价通道
    //mapping(uint=>uint) _channelMapping;

    // 报价通道
    PriceChannelOld[] _oldChannels;

    // Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether;
}