// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import "./NestBase.sol";
import "./interface/INNIncome.sol";

/// @dev NestNode mining contract
contract NNIncome is NestBase, INNIncome {

    // /// @param nestNodeAddress Address of nest node contract
    // /// @param nestTokenAddress Address of nest token contract
    // /// @param nestGenesisBlock Genesis block number of nest
    // constructor(address nestNodeAddress, address nestTokenAddress, uint nestGenesisBlock) {
        
    //     NEST_NODE_ADDRESS = nestNodeAddress;
    //     NEST_TOKEN_ADDRESS = nestTokenAddress;
    //     NEST_GENESIS_BLOCK = nestGenesisBlock;

    //     _blockCursor = block.number;
    // }

    // /// @dev To support open-zeppelin/upgrades
    // /// @param nestGovernanceAddress INestGovernance implementation contract address
    // function initialize(address nestGovernanceAddress) public override {
    //     super.initialize(nestGovernanceAddress);
    // }

    /// @dev Reset the blockCursor
    /// @param blockCursor blockCursor value
    function setBlockCursor(uint blockCursor) external override onlyGovernance {
        _blockCursor = blockCursor;
    }

    // Total supply of nest node
    uint constant NEST_NODE_TOTALSUPPLY = 1500;

    // Address of nest node contract
    address constant NEST_NODE_ADDRESS = 0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e;

    // Generated nest
    uint _generatedNest;
    
    // Latest block number of operated
    uint _blockCursor;

    // Personal ledger
    mapping(address=>uint) _infoMapping;

    //---------transaction---------

    /// @dev Nest node transfer settlement. This method is triggered during nest node transfer and must be called 
    /// by nest node contract
    /// @param from Transfer from address
    /// @param to Transfer to address
    function nodeCount(address from, address to) external {
        settle(from, to);
    }

    /// @dev Nest node transfer settlement. This method is triggered during nest node transfer and must be called 
    /// by nest node contract
    /// @param from Transfer from address
    /// @param to Transfer to address
    function settle(address from, address to) public override {

        require(msg.sender == NEST_NODE_ADDRESS, "NNIncome:!nestNode");
        
        // Check balance
        IERC20 nn = IERC20(NEST_NODE_ADDRESS);
        uint balanceFrom = nn.balanceOf(from);
        require(balanceFrom > 0, "NNIncome:!balance");

        // Calculation of ore drawing increment
        uint generatedNest = _generatedNest = _generatedNest + increment();

        // Update latest block number of operated
        _blockCursor = block.number;

        mapping(address=>uint) storage infoMapping = _infoMapping;
        // Calculation mining amount for (from)
        uint thisAmountFrom = (generatedNest - infoMapping[from]) * balanceFrom / NEST_NODE_TOTALSUPPLY;
        infoMapping[from] = generatedNest;

        if (thisAmountFrom > 0) {
            require(IERC20(NEST_TOKEN_ADDRESS).transfer(from, thisAmountFrom), "NNIncome:!transfer from");
        }

        // Calculation mining amount for (to)
        uint balanceTo = nn.balanceOf(to);
        if (balanceTo > 0) {
            uint thisAmountTo = (generatedNest - infoMapping[to]) * balanceTo / NEST_NODE_TOTALSUPPLY;
            infoMapping[to] = generatedNest;

            if (thisAmountTo > 0) {
                require(IERC20(NEST_TOKEN_ADDRESS).transfer(to, thisAmountTo), "NNIncome:!transfer to");
            }
        } else {
            infoMapping[to] = generatedNest;
        }
    }

    /// @dev Claim nest
    function claim() external override noContract {
        
        // Check balance
        IERC20 nn = IERC20(NEST_NODE_ADDRESS);
        uint balance = nn.balanceOf(msg.sender);
        require(balance > 0, "NNIncome:!balance");

        // Calculation of ore drawing increment
        uint generatedNest = _generatedNest = _generatedNest + increment();

        // Update latest block number of operated
        _blockCursor = block.number;

        // Calculation for current mining
        uint thisAmount = (generatedNest - _infoMapping[msg.sender]) * balance / NEST_NODE_TOTALSUPPLY;

        _infoMapping[msg.sender] = generatedNest;

        require(IERC20(NEST_TOKEN_ADDRESS).transfer(msg.sender, thisAmount), "NNIncome:!transfer");
    }

    //---------view----------------

    /// @dev Calculation of ore drawing increment
    /// @return Ore drawing increment
    function increment() public view override returns (uint) {
        //return _reduction(block.number - NEST_GENESIS_BLOCK) * (block.number - _blockCursor) * 15 ether / 100;
        return _reduction(block.number - 13827379) * (block.number - _blockCursor) * 4.5 ether / 400;
    }

    /// @dev Query the current available nest
    /// @param owner Destination address
    /// @return Number of nest currently available
    function earned(address owner) external view override returns (uint) {
        uint balance = IERC20(NEST_NODE_ADDRESS).balanceOf(owner);
        return (_generatedNest + increment() - _infoMapping[owner]) * balance / NEST_NODE_TOTALSUPPLY;
    }

    /// @dev Get generatedNest value
    /// @return GeneratedNest value
    function getGeneratedNest() external view override returns (uint) {
        return _generatedNest;
    }

    /// @dev Get blockCursor value
    /// @return blockCursor value
    function getBlockCursor() external view override returns (uint) {
        return _blockCursor;
    }

    // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2400000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 24 million blocks, 
    // about 10 years
    uint constant NEST_REDUCTION_LIMIT = 24000000; // NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _reduction(uint delta) private pure returns (uint) {
        
        if (delta < NEST_REDUCTION_LIMIT) {
            return (NEST_REDUCTION_STEPS >> ((delta / NEST_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (NEST_REDUCTION_STEPS >> 160) & 0xFFFF;
    }
}