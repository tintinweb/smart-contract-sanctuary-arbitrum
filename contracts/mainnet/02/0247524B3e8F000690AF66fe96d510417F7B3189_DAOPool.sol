/**
 *Submitted for verification at Arbiscan.io on 2024-03-12
*/

// SPDX-License-Identifier: MIT
// https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=berlin&version=soljson-v0.8.22+commit.4fc1097e.js
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DAOPool {
    address public DAO;

    constructor(address _DAO) {
        DAO = _DAO; 
    }

    modifier onlyDAO() {
        require(msg.sender == DAO, "Only DAO can call this function.");
        _;
    }

    receive() external payable {}

    function transferEther(address payable to, uint amount) public onlyDAO {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    function transferERC20(address token, address to, uint amount) public onlyDAO {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getERC20Balance(address token) public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function changeDAO(address newDAO) public onlyDAO {
        DAO = newDAO;
    }
}