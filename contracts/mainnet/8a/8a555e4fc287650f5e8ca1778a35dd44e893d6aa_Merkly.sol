// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFT.sol";

contract Merkly is OFT {
    uint public fee = 0.0000025 ether;

    constructor(address _layerZeroEndpoint) OFT("Merkly OFT", "MERK", _layerZeroEndpoint) {}

    function mint(address _to, uint256 _amount) external payable {
        require(_amount * fee <= msg.value, "Not enough ether");
        _mint(_to, _amount * 10 ** decimals());
    }

    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}