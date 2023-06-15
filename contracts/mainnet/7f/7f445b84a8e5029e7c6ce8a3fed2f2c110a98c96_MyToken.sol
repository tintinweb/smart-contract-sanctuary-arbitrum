/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    address private owner;
    
    uint256 private constant TOKENS_PER_MINT = 1000;
    uint256 private constant MAX_SUPPLY = 100000000 * 10**18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    
    constructor() {
        name = "My Token";
        symbol = "MTK";
        decimals = 18;
        totalSupply = 0;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid address");
        
        balances[msg.sender] -= value;
        balances[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid address");
        
        allowances[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowances[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Invalid address");
        
        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function mint() public payable {
        require(msg.value >= 0.0001 ether, "Insufficient payment");
        
        uint256 supplyAfterMint = totalSupply + TOKENS_PER_MINT;
        require(supplyAfterMint <= MAX_SUPPLY, "Exceeded maximum supply");
        
        balances[msg.sender] += TOKENS_PER_MINT;
        totalSupply += TOKENS_PER_MINT;
        
        emit Transfer(address(0), msg.sender, TOKENS_PER_MINT);
        emit Mint(msg.sender, TOKENS_PER_MINT);
    }
    
    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        
        payable(owner).transfer(address(this).balance);
    }
}