/**
 *Submitted for verification at Arbiscan on 2022-06-26
*/

// SPDX-License-Identifier: LYAA

// bulk minter for _um

pragma solidity ^0.8.14;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface _um {
    function mint(address _recipient) external payable;
    function mintCost() external view returns(uint256);
}

contract _um_bulkminter {

    // _um.sol contract
    address immutable public UM;

    constructor(address _adr) {
        UM = _adr;
    }

    //** VIEW **//
    function cost() public view returns(uint256) {
        return _um(UM).mintCost();
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
        )pure external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    //** BULK MINT **//
    // _amount number of mutables to mint at once
    // _recipient array of addresses for each mint, length should be = to _amount
    // will mint as many as possible, up to to the specified _amount
    // any extra ETH is refunded
    // for simplicity, use _amount * cost() * 2 for msg.value
    // max _amount should be <500 to fit within 15M gas
    function mintMany(uint256 _amount, address[] memory _recipient) payable public {

        uint256 _balance = msg.value;
        uint256 i = 0;

        // loop until we reach _amount or run out of money
        do {
            uint256 _value = cost(); // cost increases with each mint
            _balance -= _value;

            // mint to next _recipient as long as there's more addresses
            if(i < _recipient.length) {
                _um(UM).mint{value:_value}(_recipient[i]);
            }
            // else, just mint to the very first
            // (_recipient arg with just msg.sender acts as bulk mint for msg.sender)
            else {
                _um(UM).mint{value:_value}(_recipient[0]);
            }
            i++;
        }
        while (i < _amount && _balance >= cost());

        // transfer remaining ether if any
        if(_balance > 0) {
            uint256 _remainder = _balance;
            _balance = 0;
            payable(msg.sender).transfer(_remainder);
        }
    }
}