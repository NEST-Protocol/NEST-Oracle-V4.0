// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../NestBase.sol";

contract ProxyAdminTest is NestBase {

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    /// @return adm The admin slot.
    function getAdmin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
}