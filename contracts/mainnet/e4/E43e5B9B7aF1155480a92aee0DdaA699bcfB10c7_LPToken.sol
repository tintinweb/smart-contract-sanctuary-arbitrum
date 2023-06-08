/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract LPToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public constant decimals = 8;
    uint256 public constant totalSupply = 50_000_000e8;
    uint256 internal constant MASK = type(uint256).max;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != MASK) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            "_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "_transferTokens: cannot transfer to the zero address"
        );
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
    }
}

library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 c = _a - _b;
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "SafeMath: division by zero");
    }

    function div(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 c = _a / _b;
        return c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return mod(_a, _b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b != 0, _errorMessage);
        return _a % _b;
    }
}