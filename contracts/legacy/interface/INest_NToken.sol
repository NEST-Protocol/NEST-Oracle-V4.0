// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/IERC20.sol";

interface INest_NToken is IERC20 {
    
    /**
    * @dev 重置投票合约方法
    * @param voteFactory 投票合约地址
    */
    function changeMapping (address voteFactory) external;
    
    /**
    * @dev 增发
    * @param value 增发数量
    */
    function increaseTotal(uint256 value) external;

    // /**
    // * @dev 查询token总量
    // * @return token总量
    // */
    // function totalSupply() external view returns (uint256);

    // /**
    // * @dev 查询地址余额
    // * @param owner 要查询的地址
    // * @return 返回对应地址的余额
    // */
    // function balanceOf(address owner) external view returns (uint256);
    
    /**
    * @dev 查询区块信息
    * @return createBlock 初始区块数
    * @return recentlyUsedBlock 最近挖矿增发区块
    */
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);

    // /**
    //  * @dev 查询 owner 对 spender 的授权额度
    //  * @param owner 发起授权的地址
    //  * @param spender 被授权的地址
    //  * @return 已授权的金额
    //  */
    // function allowance(address owner, address spender) external view override returns (uint256);

    // /**
    // * @dev 转账方法
    // * @param to 转账目标
    // * @param value 转账金额
    // * @return 转账是否成功
    // */
    // function transfer(address to, uint256 value) external returns (bool);

    // /**
    //  * @dev 授权方法
    //  * @param spender 授权目标
    //  * @param value 授权数量
    //  * @return 授权是否成功
    //  */
    // function approve(address spender, uint256 value) external returns (bool);

    // /**
    //  * @dev 已授权状态下，从 from地址转账到to地址
    //  * @param from 转出的账户地址 
    //  * @param to 转入的账户地址
    //  * @param value 转账金额
    //  * @return 授权转账是否成功
    //  */
    // function transferFrom(address from, address to, uint256 value) external returns (bool);

    // /**
    //  * @dev 增加授权额度
    //  * @param spender 授权目标
    //  * @param addedValue 增加的额度
    //  * @return 增加授权额度是否成功
    //  */
    // function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    // /**
    //  * @dev 减少授权额度
    //  * @param spender 授权目标
    //  * @param subtractedValue 减少的额度
    //  * @return 减少授权额度是否成功
    //  */
    // function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
    * @dev 查询创建者
    * @return 创建者地址
    */
    function checkBidder() external view returns(address);
    
    /**
    * @dev 转让创建者
    * @param bidder 新创建者地址
    */
    function changeBidder(address bidder) external;
}