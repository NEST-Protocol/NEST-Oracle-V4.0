// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import './lib/TransferHelper.sol';
import "./interface/INTokenController.sol";
import "./interface/INToken.sol";
import "./NToken.sol";
import "./NestBase.sol";

/// @dev NToken Controller, management for ntoken
contract NTokenController is NestBase, INTokenController {

    // /// @param nestTokenAddress Address of nest token contract
    // constructor(address nestTokenAddress)
    // {
    //     NEST_TOKEN_ADDRESS = nestTokenAddress;
    // }

    // Configuration
    Config _config;

    // ntoken information array
    NTokenTag[] _nTokenTagList;

    // A mapping for all ntoken
    mapping(address=>uint) public _nTokenTags;

    /* ========== Governance ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        require(uint(config.state) <= 1, "NTokenController:!value");
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Set the token mapping
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress Destination ntoken address
    /// @param state status for this map
    function setNTokenMapping(address tokenAddress, address ntokenAddress, uint state) external override onlyGovernance {
        
        uint index = _nTokenTags[tokenAddress];
        if (index == 0) {

            _nTokenTagList.push(NTokenTag(
                // address ntokenAddress;
                ntokenAddress,
                // uint96 nestFee;
                uint96(0),
                // address tokenAddress;
                tokenAddress,
                // uint40 index;
                uint40(_nTokenTagList.length),
                // uint48 startTime;
                uint48(block.timestamp),
                // uint8 state;  
                uint8(state)
            ));
            _nTokenTags[tokenAddress] = _nTokenTags[ntokenAddress] = _nTokenTagList.length;
        } else {

            NTokenTag memory tag = _nTokenTagList[index - 1];
            tag.ntokenAddress = ntokenAddress;
            tag.tokenAddress = tokenAddress;
            tag.index = uint40(index - 1);
            tag.startTime = uint48(block.timestamp);
            tag.state = uint8(state);

            _nTokenTagList[index - 1] = tag;
            _nTokenTags[tokenAddress] = _nTokenTags[ntokenAddress] = index;
        }
    }

    /// @dev Get token address from ntoken address
    /// @param ntokenAddress Destination ntoken address
    /// @return token address
    function getTokenAddress(address ntokenAddress) external view override returns (address) {

        uint index = _nTokenTags[ntokenAddress];
        if (index > 0) {
            return _nTokenTagList[index - 1].tokenAddress;
        }
        return address(0);
    }

    /// @dev Get ntoken address from token address
    /// @param tokenAddress Destination token address
    /// @return ntoken address
    function getNTokenAddress(address tokenAddress) public view override returns (address) {

        uint index = _nTokenTags[tokenAddress];
        if (index > 0) {
            return _nTokenTagList[index - 1].ntokenAddress;
        }
        return address(0);
    }

    /* ========== ntoken management ========== */
    
    /// @dev Bad tokens should be banned 
    function disable(address tokenAddress) external override onlyGovernance
    {
        // When tokenAddress does not exist, _nTokenTags[tokenAddress] - 1 will overflow error
        _nTokenTagList[_nTokenTags[tokenAddress] - 1].state = uint8(0);
        emit NTokenDisabled(tokenAddress);
    }

    /// @dev enable ntoken
    function enable(address tokenAddress) external override onlyGovernance
    {
        // When tokenAddress does not exist, _nTokenTags[tokenAddress] - 1 will overflow error
        _nTokenTagList[_nTokenTags[tokenAddress] - 1].state = uint8(1);
        emit NTokenEnabled(tokenAddress);
    }

    /// @notice Open a NToken for a token by anyone (contracts aren't allowed)
    /// @dev Create and map the (Token, NToken) pair in NestPool
    /// @param tokenAddress The address of token contract
    function open(address tokenAddress) external override noContract
    {
        Config memory config = _config;
        require(uint(config.state) == 1, "NTokenController:!state");

        // Check token mapping
        require(getNTokenAddress(tokenAddress) == address(0), "NTokenController:!exists");

        // Check token state
        uint index = _nTokenTags[tokenAddress];
        require(index == 0 || uint(_nTokenTagList[index - 1].state) == 0, "NTokenController:!active");

        uint ntokenCounter = _nTokenTagList.length;

        // Create ntoken contract
        string memory sn = _getAddressStr(ntokenCounter);
        NToken ntoken = new NToken(_strConcat("NToken", sn), _strConcat("N", sn));

        address governance = _governance;
        ntoken.initialize(address(this));
        ntoken.update(governance);

        // Is token valid ?
        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), 1);
        require(IERC20(tokenAddress).balanceOf(address(this)) >= 1, "NTokenController:!transfer");
        TransferHelper.safeTransfer(tokenAddress, msg.sender, 1);

        // Pay nest
        IERC20(NEST_TOKEN_ADDRESS).transferFrom(msg.sender, governance, uint(config.openFeeNestAmount));

        _nTokenTags[tokenAddress] = _nTokenTags[address(ntoken)] = ntokenCounter + 1;
        _nTokenTagList.push(NTokenTag(
            // address ntokenAddress;
            address(ntoken),
            // uint96 nestFee;
            config.openFeeNestAmount,
            // address tokenAddress;
            tokenAddress,
            // uint40 index;
            uint40(_nTokenTagList.length),
            // uint48 startTime;
            uint48(block.timestamp),
            // uint8 state;  
            1
        ));

        emit NTokenOpened(tokenAddress, address(ntoken), msg.sender);
    }

    /* ========== VIEWS ========== */

    /// @dev Get ntoken information
    /// @param tokenAddress Destination token address
    /// @return ntoken information
    function getNTokenTag(address tokenAddress) external view override returns (NTokenTag memory) 
    {
        return _nTokenTagList[_nTokenTags[tokenAddress] - 1];
    }

    /// @dev Get opened ntoken count
    /// @return ntoken count
    function getNTokenCount() external view override returns (uint) {
        return _nTokenTagList.length;
    }

    /// @dev List ntoken information by page
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return ntoken information by page
    function list(uint offset, uint count, uint order) external view override returns (NTokenTag[] memory) {
        
        NTokenTag[] storage nTokenTagList = _nTokenTagList;
        NTokenTag[] memory result = new NTokenTag[](count);
        uint length = nTokenTagList.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                result[i++] = nTokenTagList[--index];
            }
        } 
        // Positive order
        else {
            
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                result[i++] = nTokenTagList[index++];
            }
        }

        return result;
    }

    /* ========== HELPERS ========== */

    /// @dev from NESTv3.0
    function _strConcat(string memory _a, string memory _b) private pure returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        } 
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        } 
        return string(ret);
    } 
    
    /// @dev Convert number into a string, if less than 4 digits, make up 0 in front, from NestV3.0
    function _getAddressStr(uint256 iv) private pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint256 index = 0;
        do {
            buf[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0 || index < 4);
        bytes memory str = new bytes(index);
        for(uint256 i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }
}