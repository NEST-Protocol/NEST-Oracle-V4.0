// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/**
 * @title 投票工厂+ 映射
 * @dev 创建与投票方法
 */
contract Nest_3_VoteFactory {
    
    mapping(string => address) _contractAddress;                    //  投票合约映射
    mapping(address => bool) _modifyAuthority;                      //  修改权限

    /**
    * @dev 初始化方法
    */
    constructor () {
        _modifyAuthority[msg.sender] = true;
    }
    
    //  查询地址
    function checkAddress(string memory name) public view returns (address contractAddress) {
        return _contractAddress[name];
    }
    
    //  添加合约映射地址
    function addContractAddress(string memory name, address contractAddress) public onlyOwner {
        _contractAddress[name] = contractAddress;
    }
    
    //  增加管理地址
    function addSuperMan(address superMan) public onlyOwner {
        _modifyAuthority[superMan] = true;
    }
    function addSuperManPrivate(address superMan) private {
        _modifyAuthority[superMan] = true;
    }
    
    //  删除管理地址
    function deleteSuperMan(address superMan) public onlyOwner {
        _modifyAuthority[superMan] = false;
    }
    function deleteSuperManPrivate(address superMan) private {
        _modifyAuthority[superMan] = false;
    }
    
    //  查看是否管理员
    function checkOwners(address man) public view returns (bool) {
        return _modifyAuthority[man];
    }
    
    //  仅限管理员操作
    modifier onlyOwner() {
        require(checkOwners(msg.sender), "No authority");
        _;
    }
}
