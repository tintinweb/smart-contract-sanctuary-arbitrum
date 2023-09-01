// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "../interfaces/IERC20.sol";

contract RDSToken is IERC20 {
    uint256 private constant TOTAL_SUPPLY = 50_000_000 ether;

    string public constant name = "RDS Token";
    string public constant symbol = "RDS";
    uint256 public constant decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function totalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Invalid Spender");
        require(msg.sender != spender, "Require Approver != Spender");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0), "Invalid Sender");

        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function _mint(address account, uint256 amount) internal {
        unchecked {
            _balances[account] = amount;
        }

        emit Transfer(address(0), account, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "Invalid Receiver");
        require(from != to, "Require Sender != Receiver");
        require(_balances[from] >= amount, "Insufficient balance");

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        require(_allowances[owner][spender] >= amount, "Insufficient allowance");

        unchecked {
            _allowances[owner][spender] -= amount;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}