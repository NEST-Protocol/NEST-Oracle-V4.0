// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../lib/IERC20.sol";
import "./Nest_3_VoteFactory.sol";
import "../interface/INest_NToken.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library NewSafeMath2 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Nest_NToken is INest_NToken {
    using NewSafeMath2 for uint256;
    
    mapping (address => uint256) private _balances;                                 //  账本
    mapping (address => mapping (address => uint256)) private _allowed;             //  授权账本
    uint256 private _totalSupply = 0 ether;                                         //  总量
    string public name;                                                             //  名称
    string public symbol;                                                           //  简称
    uint8 public decimals = 18;                                                     //  精度
    uint256 public _createBlock;                                                    //  创建区块
    uint256 public _recentlyUsedBlock;                                              //  最近使用区块
    Nest_3_VoteFactory _voteFactory;                                                //  投票合约
    address _bidder;                                                                //  拥有者
    
    /**
    * @dev 初始化方法
    * @param _name token名称
    * @param _symbol token简称
    * @param voteFactory 投票合约地址
    * @param bidder 中标者地址
    */
    constructor (string memory _name, string memory _symbol, address voteFactory, address bidder) {
        name = _name;                                                               
        symbol = _symbol;
        _createBlock = block.number;
        _recentlyUsedBlock = block.number;
        _voteFactory = Nest_3_VoteFactory(address(voteFactory));
        _bidder = bidder;
    }
    
    /**
    * @dev 重置投票合约方法
    * @param voteFactory 投票合约地址
    */
    function changeMapping (address voteFactory) public override onlyOwner {
        _voteFactory = Nest_3_VoteFactory(address(voteFactory));
    }
    
    /**
    * @dev 增发
    * @param value 增发数量
    */
    function increaseTotal(uint256 value) public override {
        address offerMain = address(_voteFactory.checkAddress("nest.nToken.offerMain"));
        require(msg.sender == offerMain, "No authority");
        _balances[offerMain] = _balances[offerMain].add(value);
        _totalSupply = _totalSupply.add(value);
        _recentlyUsedBlock = block.number;
    }

    /**
    * @dev 查询token总量
    * @return token总量
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev 查询地址余额
    * @param owner 要查询的地址
    * @return 返回对应地址的余额
    */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }
    
    /**
    * @dev 查询区块信息
    * @return createBlock 初始区块数
    * @return recentlyUsedBlock 最近挖矿增发区块
    */
    function checkBlockInfo() public view override returns(uint256 createBlock, uint256 recentlyUsedBlock) {
        return (_createBlock, _recentlyUsedBlock);
    }

    /**
     * @dev 查询 owner 对 spender 的授权额度
     * @param owner 发起授权的地址
     * @param spender 被授权的地址
     * @return 已授权的金额
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev 转账方法
    * @param to 转账目标
    * @param value 转账金额
    * @return 转账是否成功
    */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev 授权方法
     * @param spender 授权目标
     * @param value 授权数量
     * @return 授权是否成功
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev 已授权状态下，从 from地址转账到to地址
     * @param from 转出的账户地址 
     * @param to 转入的账户地址
     * @param value 转账金额
     * @return 授权转账是否成功
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev 增加授权额度
     * @param spender 授权目标
     * @param addedValue 增加的额度
     * @return 增加授权额度是否成功
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev 减少授权额度
     * @param spender 授权目标
     * @param subtractedValue 减少的额度
     * @return 减少授权额度是否成功
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev 转账方法
    * @param to 转账目标
    * @param value 转账金额
    */
    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    /**
    * @dev 查询创建者
    * @return 创建者地址
    */
    function checkBidder() public view override returns(address) {
        return _bidder;
    }
    
    /**
    * @dev 转让创建者
    * @param bidder 新创建者地址
    */
    function changeBidder(address bidder) public override {
        require(msg.sender == _bidder);
        _bidder = bidder; 
    }
    
    // 仅限管理员操作
    modifier onlyOwner(){
        require(_voteFactory.checkOwners(msg.sender));
        _;
    }
}