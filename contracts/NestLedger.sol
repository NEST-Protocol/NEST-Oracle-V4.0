// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./interfaces/INestLedger.sol";
import "./NestBase.sol";

/// @dev Nest ledger contract
contract NestLedger is NestBase, INestLedger {

    /// @dev Structure is used to represent a storage location. 
    /// Storage variable can be used to avoid indexing from mapping many times
    struct UINT {
        uint value;
    }

    // ntoken ledger. channelId=>value
    mapping(uint=>UINT) _ntokenLedger;

    // DAO applications
    mapping(address=>uint) _applications;

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

    /// @dev Add reward
    /// @param channelId Target channelId
    function addETHReward(uint channelId) external payable override {
        UINT storage balance = _ntokenLedger[channelId];
        balance.value += msg.value;
    }

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId Target channelId
    function totalETHRewards(uint channelId) external view override returns (uint) {
        return _ntokenLedger[channelId].value;
    }

    /// @dev Pay
    /// @param channelId Target channelId
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address tokenAddress, address to, uint value) external override {

        require(_applications[msg.sender] == 1, "NestLedger:!app");

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            UINT storage balance = _ntokenLedger[channelId];
            balance.value -= value;
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }
}