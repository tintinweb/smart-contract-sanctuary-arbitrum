/**
 *Submitted for verification at Arbiscan.io on 2023-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InterfaceDAO {
    function bridgeMint(uint256 _amount) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Bridge {
    address public admin;
    InterfaceDAO public DAO;
    IERC20 public token;

    constructor() {
        admin = msg.sender;
        DAO = InterfaceDAO(0x8d833F96809758B70862F65cbb3F8FeA1fCc7283);
        token = IERC20(0xEacEd2e6f3eE6019ed6E245046330BFeA7160F1c);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this.");
        _;
    }

    function bridgeMintToUser(uint256 _amount, address _user) public onlyAdmin {
        DAO.bridgeMint(_amount);
        token.transfer(_user, _amount);
    }

     function setAdmin(address _user) public onlyAdmin {
        admin = _user;
    }


}