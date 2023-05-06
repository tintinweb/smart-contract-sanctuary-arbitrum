/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

pragma solidity ^0.8.18;

interface ARB {
    function _airdrop(address addr) view external returns (uint256);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract XGAirdrop {
    uint256 amount = 20000000 * 1e18;
    address public owner;
    mapping(address => uint256) public claimed;
    mapping(address => bool) public white;
    bool public open;

    ARB ref ;
    IERC20 public xqdog = IERC20(0xB07d1A2c55E4973723b11278d6ffaa7C04B73a2E);
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor(address r){
        owner = msg.sender;
        ref = ARB(r);
        open = true;
    }

    function mint() public {
        require(open, "Not Open");
        require(ref._airdrop(msg.sender) == 1 || white[msg.sender], "Not Allow");
        require(claimed[msg.sender] == 0, "Claimed");
        claimed[msg.sender] = 1;
        xqdog.transfer(msg.sender, amount);
    }

    function toggle() public onlyOwner {
        open = !open;
    }

    function addwhitelist(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            white[addrs[i]] = true;
        }
    }

    function canmint(address addr) public view returns (bool) {
        return ref._airdrop(addr) == 1 || white[addr];
    }

    function change(uint256 a) public onlyOwner {
        amount = a;
    }

    function withdraw() public onlyOwner {
        xqdog.transfer(msg.sender, xqdog.balanceOf(address(this)));
    }
}