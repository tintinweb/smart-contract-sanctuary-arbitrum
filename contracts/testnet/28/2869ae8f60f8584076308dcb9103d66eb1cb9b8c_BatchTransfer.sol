/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract BatchTransfer {
    address public owner;
    mapping(address => bool) public authorizedAddresses;

    // 硬编码的授权地址
    address constant address1 = 0x5e9B3cdBa58249aBCCc0C7B9F53391194a8f128F;
    address constant address2 = 0x905de3F6BF620FB7dD8FC15dEb394cBA0cD774d7;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Only authorized addresses can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedAddresses[msg.sender] = true;
        authorizedAddresses[address1] = true;
        authorizedAddresses[address2] = true;
    }

    function grantAccess(address toGrant) public onlyOwner {
        authorizedAddresses[toGrant] = true;
    }

    function revokeAccess(address toRevoke) public onlyOwner {
        authorizedAddresses[toRevoke] = false;
    }

    function batchTransferToken(IERC20 token, address[] memory to, uint256 amount) public onlyAuthorized {
        for (uint i=0; i<to.length; i++) {
            require(token.transfer(to[i], amount), "Token transfer failed");
        }
    }

    function batchTransferETH(address payable[] memory to, uint256 amount) public payable onlyAuthorized {
        require(msg.value >= amount * to.length, "Not enough ETH provided");
        for (uint i=0; i<to.length; i++) {
            (bool success, ) = to[i].call{value: amount}("");
            require(success, "ETH transfer failed");
        }
    }

    function batchTransferHexToMultiAddress(address[] memory to, bytes[] memory hexData) public onlyAuthorized {
        require(to.length == hexData.length, "The array lengths are not equal");
        for (uint i=0; i<to.length; i++) {
            (bool success, ) = to[i].call(hexData[i]);
            require(success, "Transfer with hex data failed");
        }
    }

    function batchTransferHexToSingleAddress(address _to, bytes[] memory _hexData) public onlyAuthorized {
        for (uint i=0; i<_hexData.length; i++) {
            (bool success, ) = _to.call(_hexData[i]);
            require(success, "Transfer with hex data failed");
        }
    }
}