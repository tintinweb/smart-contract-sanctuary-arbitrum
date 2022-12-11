//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC20.sol';
import './IERC20Metadata.sol';

import './Context.sol';
import './Ownable.sol';

contract ShibaAI is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name = 'ShibaAI';

    string private _symbol = 'SHAI';

    uint8 private _decimals = 18;

    uint256 private _totalSupply = 100_000_000_000 * 10 ** _decimals;

    address public deploymentWallet;

    address payable public operationsWallet;

    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD;

    address public immutable zeroAddress =
        0x0000000000000000000000000000000000000000;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromWalletLimit;
    mapping(address => bool) public isExcludedFromTxLimit;

    bool public enableTransactionLimit = true;
    bool public enableWalletLimit = true;

    uint256 public marketingFee = 3; // 3%
    uint256 public devFee = 2; // 2%
    uint256 public burnFee = 2; // 2%

    uint256 public maxTxAmount = (_totalSupply * 2) / 10_000; // 0.02%
    uint256 public maxWalletAmount = (_totalSupply * 2) / 10_000; // 0.02%

    uint256 public totalFee;

    constructor(address deploymentWallet_, address operationsWallet_) {
        deploymentWallet = deploymentWallet_;

        operationsWallet = payable(operationsWallet_);

        isExcludedFromFee[deploymentWallet_] = true;
        isExcludedFromFee[operationsWallet_] = true;
        isExcludedFromFee[address(this)] = true;

        isExcludedFromWalletLimit[deploymentWallet_] = true;
        isExcludedFromWalletLimit[operationsWallet_] = true;
        isExcludedFromWalletLimit[address(this)] = true;

        isExcludedFromTxLimit[deploymentWallet_] = true;
        isExcludedFromTxLimit[operationsWallet_] = true;
        isExcludedFromTxLimit[address(this)] = true;

        totalFee = marketingFee + devFee;

        _balances[deploymentWallet_] = _totalSupply;
        emit Transfer(address(0), deploymentWallet_, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(deadAddress) - balanceOf(zeroAddress);
    }

    function setOperationsWallet(address operationsWallet_) external onlyOwner {
        operationsWallet = payable(operationsWallet_);
    }

    function setIsExcludedFromFee(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function setIsExcludedFromWalletLimit(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromWalletLimit[account] = value;
    }

    function setIsExcludedFromTxLimit(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromTxLimit[account] = value;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            'Decreased allowance below zero'
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'Approve from the zero address');
        require(spender != address(0), 'Approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, 'Insufficient allowance');
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), 'Transfer from the zero address');
        require(to != address(0), 'Transfer to the zero address');

        uint256 fromBalance = _balances[from];

        if (
            !isExcludedFromTxLimit[to] &&
            !isExcludedFromTxLimit[from] &&
            enableTransactionLimit
        ) {
            require(
                amount <= maxTxAmount,
                'Transfer amount exceeds the max amount fot tx.'
            );
        }

        require(fromBalance >= amount, 'Transfer amount exceeds balance');

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        uint256 transferableAmount = (isExcludedFromFee[to] ||
            isExcludedFromFee[from])
            ? amount
            : takeFee(from, amount);

        if (enableWalletLimit && !isExcludedFromWalletLimit[to]) {
            require(
                balanceOf(to) + transferableAmount <= maxWalletAmount,
                'Amount exceed wallet max limit.'
            );
        }

        _balances[to] += transferableAmount;

        emit Transfer(from, to, transferableAmount);
    }

    function takeFee(address from, uint256 amount) internal returns (uint256) {
        uint256 feeTokens = (amount * totalFee) / 100;
        uint256 burnTokens = (amount * burnFee) / 100;

        if (feeTokens > 0) {
            _balances[operationsWallet] += feeTokens;
            emit Transfer(from, operationsWallet, feeTokens);
        }

        if (burnTokens > 0) {
            _balances[deadAddress] += burnTokens;
            emit Transfer(from, deadAddress, burnTokens);
        }

        return amount - feeTokens - burnTokens;
    }
}