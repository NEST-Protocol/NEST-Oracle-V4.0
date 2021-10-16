// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/TransferHelper.sol";
import "./interface/INestLedger.sol";
import "./NestBase.sol";

/// @dev Nest ledger contract
contract NestLedger is NestBase, INestLedger {

    // /// @param nestTokenAddress Address of nest token contract
    // constructor(address nestTokenAddress) {
    //     NEST_TOKEN_ADDRESS = nestTokenAddress;
    // }

    /// @dev Structure is used to represent a storage location. 
    /// Storage variable can be used to avoid indexing from mapping many times
    struct UINT {
        uint value;
    }

    // Configuration
    Config _config;

    // nest ledger
    uint _nestLedger;

    // ntoken ledger
    mapping(address=>UINT) _ntokenLedger;

    // DAO applications
    mapping(address=>uint) _applications;

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        require(uint(config.nestRewardScale) <= 10000, "NestLedger:!value");
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external override onlyGovernance {
        _applications[addr] = flag;
        emit ApplicationChanged(addr, flag);
    }

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view override returns (uint) {
        return _applications[addr];
    }

    /// @dev Carve reward
    /// @param ntokenAddress Destination ntoken address
    function carveETHReward(address ntokenAddress) external payable override {

        // nest not carve
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        }
        // ntoken need carve
        else {

            Config memory config = _config;
            UINT storage balance = _ntokenLedger[ntokenAddress];

            // Calculate nest reward
            uint nestReward = msg.value * uint(config.nestRewardScale) / 10000;
            // The part of ntoken is msg.value - nestReward
            balance.value += msg.value - nestReward;
            // nest reward
            _nestLedger += nestReward;
        }
    }

    /// @dev Add reward
    /// @param ntokenAddress Destination ntoken address
    function addETHReward(address ntokenAddress) external payable override {

        // Ledger for nest is independent
        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            _nestLedger += msg.value;
        }
        // Ledger for ntoken is in a mapping
        else {
            UINT storage balance = _ntokenLedger[ntokenAddress];
            balance.value += msg.value;
        }
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param ntokenAddress The ntoken address
    function totalETHRewards(address ntokenAddress) external view override returns (uint) {

        if (ntokenAddress == NEST_TOKEN_ADDRESS) {
            return _nestLedger;
        }
        return _ntokenLedger[ntokenAddress].value;
    }

    /// @dev Pay
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address ntokenAddress, address tokenAddress, address to, uint value) external override {

        require(_applications[msg.sender] == 1, "NestLedger:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // nest ledger
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                _nestLedger -= value;
            }
            // ntoken ledger
            else {
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value -= value;
            }
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    /// @dev Settlement
    /// @param ntokenAddress Destination ntoken address. Indicates which ntoken to settle with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address ntokenAddress, address tokenAddress, address to, uint value) external payable override {

        require(_applications[msg.sender] == 1, "NestLedger:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // nest ledger
            if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                // If msg.value is not 0, add to ledger
                _nestLedger = _nestLedger + msg.value - value;
            }
            // ntoken ledger
            else {
                // If msg.value is not 0, add to ledger
                UINT storage balance = _ntokenLedger[ntokenAddress];
                balance.value = balance.value + msg.value - value;
            }
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // If msg.value is not 0, add to ledger
            if (msg.value > 0) {
                if (ntokenAddress == NEST_TOKEN_ADDRESS) {
                    _nestLedger += msg.value;
                } else {
                    UINT storage balance = _ntokenLedger[ntokenAddress];
                    balance.value += msg.value;
                }
            }
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    } 
}