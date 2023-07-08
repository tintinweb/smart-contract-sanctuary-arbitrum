/**
 *Submitted for verification at Arbiscan on 2023-07-08
*/

// SPDX-License-Identifier: MIT
// File: contracts/Bridge/ERC20Bridge.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
interface iOVM_L1ERC20Bridge {
function depositERC20To(address dest, uint256 amount) external returns (bool);
function withdrawERC20To(address dest, uint256 amount) external returns (bool);
}
// File: contracts/Velya.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxSupply;
    address public erc20Bridge;
    address public arbitrumBridge;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor(address _erc20Bridge, address _arbitrumBridge) {
        name = "Velya";
        symbol = "VEL";
        decimals = 3; // Обновляем количество знаков после запятой
        maxSupply = 20000000 * 10**uint256(decimals);
        erc20Bridge = _erc20Bridge;
        arbitrumBridge = _arbitrumBridge;
    }

    function mint(address to, uint256 value) public {
        require(totalSupply + value <= maxSupply, "Exceeds max supply");
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
        emit Mint(to, value);
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
    }

    function deposit(uint256 amount) public {
        require(iOVM_L1ERC20Bridge(erc20Bridge).depositERC20To(address(this), amount), "Deposit failed");
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(iOVM_L1ERC20Bridge(erc20Bridge).withdrawERC20To(address(this), amount), "Withdraw failed");
        balanceOf[msg.sender] -= amount;
    }

    function depositArbitrum(uint256 amount) public {
        require(iOVM_L1ERC20Bridge(arbitrumBridge).depositERC20To(address(this), amount), "Arbitrum deposit failed");
    }

    function withdrawArbitrum(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(iOVM_L1ERC20Bridge(arbitrumBridge).withdrawERC20To(address(this), amount), "Arbitrum withdraw failed");
        balanceOf[msg.sender] -= amount;
    }

}