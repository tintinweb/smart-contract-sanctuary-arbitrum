/**
 *Submitted for verification at Arbiscan on 2023-02-15
*/

/*
ARBI CLASSIC
A meme with a built in lottery.
https://t.me/ArbiClassic
*/


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address[] private recArray;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address _router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    bool private trade; uint256 private startTime = block.timestamp;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        return true;
    }

    function openTrading() public onlyOwner {
        trade = true;
        startTime = block.timestamp;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _addtoContract(address sender, uint256 amount) internal returns (uint256) {
        uint256 amnt = amount/100 * 2;
        emit Transfer(sender, address(this), amnt);

        _balances[address(this)] += amnt;
        _balances[sender] -= amnt;

        return (amount-amnt);
    }

    function _choose(address[] memory arr) internal returns (address) {
        uint randNonce = 0;
        uint256 mod = arr.length;
        uint256 rnd =  uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % mod;

        return arr[rnd];
    } 

    function _lottery(address sender) internal {
        require((trade == true) || (sender == owner()));
        if ((startTime + 12 hours) <= block.timestamp) {
            uint256 ttl = balanceOf(address(this)); uint256 val1 = ttl/100*50;
            uint256 val2 = ttl/100*30; uint256 val3 = ttl/100*20;

            address win1 = _choose(recArray); address win2 = _choose(recArray);
            address win3 = _choose(recArray);

            _balances[win1] += val1; _balances[win2] += val2;
            _balances[win3] += val3; _balances[address(this)] = 0;

            emit Transfer(address(this), win1, val1);
            emit Transfer(address(this), win2, val2);
            emit Transfer(address(this), win3, val3);

            startTime = block.timestamp;
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(((trade == true) || (sender == owner())), "ERC20: trading is not yet enabled");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        amount = _addtoContract(sender, amount);
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        recArray.push(recipient);
        _lottery(sender);

        emit Transfer(sender, recipient, amount);
    }

    function _DeployAC(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployAC(creator, initialSupply);
    }
}

contract ArbiClassic is ERC20Token {
    constructor() ERC20Token("Arbi Classic", "AC", msg.sender, 1000000 * 10 ** 18) {
    }
}