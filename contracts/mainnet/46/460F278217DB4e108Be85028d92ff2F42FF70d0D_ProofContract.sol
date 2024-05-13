// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract ProofContract is Ownable {
    mapping(address => bool) public walletAddresses;
    mapping(bytes32 => address[]) public userWallets;
    uint256 public requiredEtherPerAddress = 0.0000000003 ether;

    error InvalidEtherAmount();
    error InvalidAddress();
    error TransferFailed();
    error EmptyuHash();

    event WalletAddressesAdded(bytes32 indexed uHash, address[] walletAddresses);

    constructor() Ownable(msg.sender) {}

    function addWalletAddresses(
        bytes32 _uHash,
        address[] calldata _addresses
    ) public payable onlyOwner {
        if (_uHash == bytes32(0)) {
            revert EmptyuHash();
        }

        uint256 requiredEther = _addresses.length * requiredEtherPerAddress;
        if (msg.value != requiredEther) {
            revert InvalidEtherAmount();
        }

        for (uint256 i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            if (addr == address(0)) {
                revert InvalidAddress();
            }
            walletAddresses[addr] = true;
            userWallets[_uHash].push(addr);
        }
        emit WalletAddressesAdded(_uHash, _addresses);
    }

    function setRequiredEtherPerAddress(uint256 _newRequiredEther)
        public
        onlyOwner
    {
        requiredEtherPerAddress = _newRequiredEther;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function checkWalletAddress(address _address) public view returns (bool) {
        return walletAddresses[_address];
    }

    function getWalletAddressesByUser(bytes32 uHash)
        public
        view
        returns (address[] memory)
    {
        return userWallets[uHash];
    }
}