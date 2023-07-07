// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../Ownable.sol";

contract FUKFERC is ERC20, Ownable {
    uint256 MaxtotalSupply = 1000000000000 * 10 ** decimals();
    mapping(address => uint256) public Claimable; 

    constructor(address fund_address) ERC20("FUKFERC2.0", "fferc2.0"){
         _mint(msg.sender, 100000000000 * 10 ** decimals());
         _mint(fund_address, 216720000000 * 10 ** decimals());
    }
    
    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function claim() public {
        require(Claimable[msg.sender]>0,"There's nothing to claim");
        require(Claimable[msg.sender]+totalSupply()<MaxtotalSupply,"Exceeded the maximum");
        _mint(msg.sender,Claimable[msg.sender]);
        Claimable[msg.sender] = 0;
    }

    function Set_Claimable(address[] calldata _addresses,uint256[] calldata _amounts) public onlyOwner {
        require(_addresses.length == _amounts.length,"Lengths of Addresses and Amounts NOT EQUAL");
        for (uint256 i; i < _addresses.length; i++) {
            Claimable[_addresses[i]] = _amounts[i];
        }
    }

}