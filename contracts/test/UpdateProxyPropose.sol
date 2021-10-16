// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interface/IProxyAdmin.sol";
import "../interface/IVotePropose.sol";
import "../interface/INestVote.sol";

contract UpdateProxyPropose is IVotePropose {

    address _nestVoteAddress;
    address _proxyAdminAddress;
    address _proxyAddress;
    address _newImplAddress;

    function setAddress(
        address nestVoteAddress,
        address proxyAdminAddress,
        address proxyAddress,
        address newImplAddress
    ) public {
        _nestVoteAddress = nestVoteAddress;
        _proxyAdminAddress = proxyAdminAddress;
        _proxyAddress = proxyAddress;
        _newImplAddress = newImplAddress;
    }

    function run() external override {
        INestVote(_nestVoteAddress).upgradeProxy(_proxyAdminAddress, _proxyAddress, _newImplAddress);
        INestVote(_nestVoteAddress).transferUpgradeAuthority(_proxyAdminAddress, tx.origin);
    }
}