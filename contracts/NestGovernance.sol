// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/INestGovernance.sol";
import "./NestMapping.sol";

/// @dev Nest governance contract
contract NestGovernance is NestMapping, INestGovernance {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public override {

        // While initialize NestGovernance, governance is address(this),
        // So must let governance to 0
        require(governance == address(0), "NestGovernance:!address");

        // governance is address(this)
        super.initialize(address(this));

        // Add msg.sender to governance
        _governanceMapping[msg.sender] = GovernanceInfo(msg.sender, uint96(0xFFFFFFFFFFFFFFFFFFFFFFFF));
    }

    /// @dev Structure of governance address information
    struct GovernanceInfo {
        address addr;
        uint96 flag;
    }

    /// @dev Governance address information
    mapping(address=>GovernanceInfo) _governanceMapping;

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external override onlyGovernance {
        
        if (flag > 0) {
            _governanceMapping[addr] = GovernanceInfo(addr, uint96(flag));
        } else {
            _governanceMapping[addr] = GovernanceInfo(address(0), uint96(0));
        }
    }

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view override returns (uint) {
        return _governanceMapping[addr].flag;
    }

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than 
    /// this weight to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) public view override returns (bool) {
        return _governanceMapping[addr].flag > flag;
    }

    /// @dev This method is for ntoken in created in nest3.0
    /// @param addr Destination address
    /// @return True indicates permission
    function checkOwners(address addr) external view returns (bool) {
        return checkGovernance(addr, 0);
    }
}