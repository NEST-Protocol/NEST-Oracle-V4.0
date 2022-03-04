// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/IERC20.sol";

import "./interfaces/INestVote.sol";
import "./interfaces/IVotePropose.sol";
import "./interfaces/INestGovernance.sol";
import "./interfaces/IProxyAdmin.sol";

import "./custom/ChainConfig.sol";
import "./custom/NestFrequentlyUsed.sol";

/// @dev nest voting contract, implemented the voting logic
contract NestVote is ChainConfig, NestFrequentlyUsed, INestVote {
    
    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing 
    /// from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Proposal information
    struct Proposal {

        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal. 0: proposed | 1: accepted | 2: cancelled
        uint32 state;

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is 
        // limited by the contract itself
    }
    
    // Configuration
    Config _config;

    // Array for proposals
    Proposal[] public _proposalList;

    // Staked ledger
    mapping(uint =>mapping(address =>UINT)) public _stakedLedger;
    
    address _nestLedgerAddress;
    //address _nestTokenAddress;
    address _nestMiningAddress;
    address _nnIncomeAddress;

    uint32 constant PROPOSAL_STATE_PROPOSED = 0;
    uint32 constant PROPOSAL_STATE_ACCEPTED = 1;
    uint32 constant PROPOSAL_STATE_CANCELLED = 2;

    uint constant NEST_TOTAL_SUPPLY = 10000000000 ether;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) public override {
        super.update(nestGovernanceAddress);

        (
            //address nestTokenAddress
            ,//_nestTokenAddress, 
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            _nestMiningAddress, 
            //address ntokenMiningAddress
            ,
            //address nestPriceFacadeAddress
            ,
            //address nestVoteAddress
            ,
            //address nestQueryAddress
            ,
            //address nnIncomeAddress
            _nnIncomeAddress, 
            //address nTokenControllerAddress
              
        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        require(uint(config.acceptance) <= 10000, "NestVote:!value");
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /* ========== VOTE ========== */
    
    /// @dev Initiate a voting proposal
    /// @param contractAddress The contract address which will be executed when the proposal is approved. 
    /// (Must implemented IVotePropose)
    /// @param brief Brief of this propose
    function propose(address contractAddress, string memory brief) external override noContract
    {
        // The target address cannot already have governance permission to prevent the governance permission 
        // from being covered
        require(!INestGovernance(_governance).checkGovernance(contractAddress, 0), "NestVote:!governance");
     
        Config memory config = _config;
        uint index = _proposalList.length;

        // Create voting structure
        _proposalList.push(Proposal(
        
            // Brief of this propose
            //string brief;
            brief,

            // The contract address which will be executed when the proposal is approved. 
            // (Must implemented IVotePropose)
            //address contractAddress;
            contractAddress,

            // Voting start time
            //uint48 startTime;
            uint48(block.timestamp),

            // Voting stop time
            //uint48 stopTime;
            uint48(block.timestamp + uint(config.voteDuration)),

            // Proposer
            //address proposer;
            msg.sender,

            config.proposalStaking,

            uint96(0), 
            
            PROPOSAL_STATE_PROPOSED, 

            address(0)
        ));

        // Stake nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), uint(config.proposalStaking));

        emit NIPSubmitted(msg.sender, contractAddress, index);
    }

    /// @dev vote
    /// @param index Index of proposal
    /// @param value Amount of nest to vote
    function vote(uint index, uint value) external override noContract
    {
        // 1. Load the proposal
        Proposal memory p = _proposalList[index];

        // 2. Check
        // Check time region
        // Note: stop time is not include stopTime
        require(block.timestamp >= uint(p.startTime) && block.timestamp < uint(p.stopTime), "NestVote:!time");
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");

        // 3. Update voting ledger
        UINT storage balance = _stakedLedger[index][msg.sender];
        balance.value += value;

        // 4. Update voting information
        _proposalList[index].gainValue = uint96(uint(p.gainValue) + value);

        // 5. Stake nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), value);

        emit NIPVote(msg.sender, index, value);
    }

    /// @dev Withdraw the nest of the vote. If the target vote is in the voting state, the corresponding 
    /// number of votes will be cancelled
    /// @param index Index of the proposal
    function withdraw(uint index) external override noContract
    {
        // 1. Update voting ledger
        UINT storage balance = _stakedLedger[index][msg.sender];
        uint balanceValue = balance.value;
        balance.value = 0;

        // 2. In the proposal state, the number of votes obtained needs to be updated
        if (_proposalList[index].state == PROPOSAL_STATE_PROPOSED) {
            _proposalList[index].gainValue = uint96(uint(_proposalList[index].gainValue) - balanceValue);
        }

        // 3. Return staked nest
        IERC20(NEST_TOKEN_ADDRESS).transfer(msg.sender, balanceValue);
    }

    /// @dev Execute the proposal
    /// @param index Index of the proposal
    function execute(uint index) external override noContract
    {
        Config memory config = _config;

        // 1. Load proposal
        Proposal memory p = _proposalList[index];

        // 2. Check status
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");
        require(block.timestamp < uint(p.stopTime), "NestVote:!time");
        // The target address cannot already have governance permission to prevent the governance 
        // permission from being covered
        address governance = _governance;
        require(!INestGovernance(governance).checkGovernance(p.contractAddress, 0), "NestVote:!governance");

        // 3. Check the gain rate
        IERC20 nest = IERC20(NEST_TOKEN_ADDRESS);

        // Calculate the circulation of nest
        uint nestCirculation = _getNestCirculation(nest);
        require(uint(p.gainValue) * 10000 >= nestCirculation * uint(config.acceptance), "NestVote:!gainValue");

        // 3. Temporarily grant execution permission
        INestGovernance(governance).setGovernance(p.contractAddress, 1);

        // 4. Execute
        _proposalList[index].state = PROPOSAL_STATE_ACCEPTED;
        _proposalList[index].executor = msg.sender;
        IVotePropose(p.contractAddress).run();

        // 5. Delete execution permission
        INestGovernance(governance).setGovernance(p.contractAddress, 0);
        
        // Return nest
        nest.transfer(p.proposer, uint(p.staked));

        emit NIPExecute(msg.sender, index);
    }

    /// @dev Cancel the proposal
    /// @param index Index of the proposal
    function cancel(uint index) external override noContract {

        // 1. Load proposal
        Proposal memory p = _proposalList[index];

        // 2. Check state
        require(p.state == PROPOSAL_STATE_PROPOSED, "NestVote:!state");
        require(block.timestamp >= uint(p.stopTime), "NestVote:!time");

        // 3. Update status
        _proposalList[index].state = PROPOSAL_STATE_CANCELLED;

        // 4. Return staked nest
        IERC20(NEST_TOKEN_ADDRESS).transfer(p.proposer, uint(p.staked));
    }

    // Convert PriceSheet to PriceSheetView
    //function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {
    function _toProposalView(
        Proposal memory proposal, 
        uint index, 
        uint nestCirculation
    ) private pure returns (ProposalView memory) {

        return ProposalView(
            // Index of the proposal
            index,
            // Brief of proposal
            //string brief;
            proposal.brief,
            // The contract address which will be executed when the proposal is approved. 
            // (Must implemented IVotePropose)
            //address contractAddress;
            proposal.contractAddress,
            // Voting start time
            //uint48 startTime;
            proposal.startTime,
            // Voting stop time
            //uint48 stopTime;
            proposal.stopTime,
            // Proposer
            //address proposer;
            proposal.proposer,
            // Staked nest amount
            //uint96 staked;
            proposal.staked,
            // Gained value
            // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the 
            // total number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of 
            // votes
            //uint96 gainValue;
            proposal.gainValue,
            // The state of this proposal
            //uint32 state;  // 0: proposed | 1: accepted | 2: cancelled
            proposal.state,
            // The executor of this proposal
            //address executor;
            proposal.executor,

            // Circulation of nest
            uint96(nestCirculation)
        );
    }

    /// @dev Get proposal information
    /// @param index Index of the proposal
    /// @return Proposal information
    function getProposeInfo(uint index) external view override returns (ProposalView memory) {
        return _toProposalView(_proposalList[index], index, getNestCirculation());
    }

    /// @dev Get the cumulative number of voting proposals
    /// @return The cumulative number of voting proposals
    function getProposeCount() external view override returns (uint) {
        return _proposalList.length;
    }

    /// @dev List proposals by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price proposals
    function list(uint offset, uint count, uint order) external view override returns (ProposalView[] memory) {
        
        Proposal[] storage proposalList = _proposalList;
        ProposalView[] memory result = new ProposalView[](count);
        uint nestCirculation = getNestCirculation();
        uint length = proposalList.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                result[i++] = _toProposalView(proposalList[index], index, nestCirculation);
            }
        } 
        // Positive sequence
        else {
            
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                result[i++] = _toProposalView(proposalList[index], index, nestCirculation);
                ++index;
            }
        }

        return result;
    }

    // Get Circulation of nest
    function _getNestCirculation(IERC20 nest) private view returns (uint) {

        return NEST_TOTAL_SUPPLY 
            - nest.balanceOf(_nestMiningAddress)
            - nest.balanceOf(_nnIncomeAddress)
            - nest.balanceOf(_nestLedgerAddress)
            - nest.balanceOf(address(0x1));
    }

    /// @dev Get Circulation of nest
    /// @return Circulation of nest
    function getNestCirculation() public view override returns (uint) {
        return _getNestCirculation(IERC20(NEST_TOKEN_ADDRESS));
    }

    /// @dev Upgrades a proxy to the newest implementation of a contract
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param proxy Proxy to be upgraded
    /// @param implementation the address of the Implementation
    function upgradeProxy(address proxyAdmin, address proxy, address implementation) external override onlyGovernance {
        IProxyAdmin(proxyAdmin).upgrade(proxy, implementation);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`)
    ///      Can only be called by the current owner
    /// @param proxyAdmin The address of ProxyAdmin
    /// @param newOwner The address of new owner
    function transferUpgradeAuthority(address proxyAdmin, address newOwner) external override onlyGovernance {
        IProxyAdmin(proxyAdmin).transferOwnership(newOwner);
    }
}