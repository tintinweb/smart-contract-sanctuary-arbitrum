/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// ███╗░░░███╗██╗░██████╗░██╗░░██╗████████╗  ░█████╗░███████╗  ███╗░░░███╗███████╗███╗░░░███╗███████╗░██████╗
// ████╗░████║██║██╔════╝░██║░░██║╚══██╔══╝  ██╔══██╗██╔════╝  ████╗░████║██╔════╝████╗░████║██╔════╝██╔════╝
// ██╔████╔██║██║██║░░██╗░███████║░░░██║░░░  ██║░░██║█████╗░░  ██╔████╔██║█████╗░░██╔████╔██║█████╗░░╚█████╗░
// ██║╚██╔╝██║██║██║░░╚██╗██╔══██║░░░██║░░░  ██║░░██║██╔══╝░░  ██║╚██╔╝██║██╔══╝░░██║╚██╔╝██║██╔══╝░░░╚═══██╗
// ██║░╚═╝░██║██║╚██████╔╝██║░░██║░░░██║░░░  ╚█████╔╝██║░░░░░  ██║░╚═╝░██║███████╗██║░╚═╝░██║███████╗██████╔╝
// ╚═╝░░░░░╚═╝╚═╝░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░  ░╚════╝░╚═╝░░░░░  ╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;



contract Token is ERC20  {

    address public pair;
    uint public burnAmount;
    address[] public opterators = [
        0xB9333b8007De801d68d809067DC58f96e017d084,
        0x7f44c4c07A78ACb40939dbD0baF53112075d0990,
        0xCc8A0171e46f14C57B9DBE7682622410BA7b5640,
        0x354EaBAF5e392D912DA2D255aFaeb5f4F818D226,
        0x851Ee4E2241bF69F5c746c5B35b08819c9eb8C76
    ];
    

    constructor(
        address _factory,
        address _pairToken
        ) ERC20("MightOfMemes", "MOM") {

        pair = IUniswapV2Factory(_factory).createPair(address(this), _pairToken);
        _mint(msg.sender, 10000e8 * 10 ** decimals());
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(from == pair){
            // buy
            _buy(from, to, amount);
        }else if(to  == pair){
            // sell
            _sell(from, to, amount);
        }else{
            // others
            super._transfer(from, to, amount);
        }
    }

    function _buy(address from, address to, uint256 amount) internal {


        burnAmount += amount * 10 / 10000;
        super._transfer(from, to, amount);
        
    }

    function _sell(address from, address to, uint256 amount) internal {

        burnAmount += amount * 10 / 10000;
        super._transfer(from, to, amount);
    }

    function rebase() public onlyOperator {
        uint limit = getPoolAmount() * 29 / 10000;
        uint amount = burnAmount;
        if(amount > limit) {
            amount = limit;
        }
        _burn(pair, amount);
        IUniswapV2Pair(pair).sync();
        burnAmount -= amount;
    }


    function getPoolAmount() internal view returns (uint) {
        (uint amount0, uint amount1, uint _t) = IUniswapV2Pair(pair).getReserves();
        return IUniswapV2Pair(pair).token0() == address(this) ? amount0 : amount1;
    }

    modifier onlyOperator {
        require(isOperator(),"not operator");
        _;
    }

    function isOperator() internal view returns (bool) {
        for (uint i = 0; i < opterators.length; i++) {
            if(msg.sender == opterators[i]){
                return true;
            }
        }
        return false;
    }

    

}