/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This `Split_payment` struct
// hold a single address and how much percentage to send
// in this address. Say we have set 3 account for split payment
// this struct will hold 1 account address and how much % to send
// to this address.
struct Split_Payment {
	address addr;
	uint per;
}

struct Token_Details {
  address owner;
  uint chain_id;
  uint price;
  uint standard; // 721,1155
  uint total_split_payment_accounts;
  uint amount;
  bool is_listed;
  bool is_exist;
  bool has_split_payment;
  mapping( uint => Split_Payment ) index_to_split_payment;
}

struct STORAGE {
	mapping( address => mapping( address => mapping( uint256 => Token_Details ) ) ) con_user_id_details;
	mapping( address => mapping( uint256 => uint256 ) ) con_id_royalty;
	mapping( address => mapping( uint256 => address ) ) con_id_creator;
	mapping( address => mapping( address => mapping( uint256 => bool ) ) ) con_user_id_secondSale;
}



contract Proxy {
	STORAGE S; 
	address public Implementation;
	address public admin;

	 constructor() {
        admin = msg.sender;
    }

    function setImplementation (address _implementation) public {
        require( _implementation != address(0), "address zero" );
        require( msg.sender == admin, "Access restricted for admin");

        Implementation = _implementation;
    }

    function getImplementation() public view returns(address){
        return Implementation;
    }

    function getBalance() public view returns(uint256){
       return address(this).balance;
    }

    function withdrawBalance() public {
      require( msg.sender == admin, "Access restricted for admin");
      payable(admin).transfer(address(this).balance);
    }


    fallback() external payable {
        address _implementation = Implementation;

        assembly {
            let _target := _implementation
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch  result 
            case 0 {
              revert(0, returndatasize())
            } 
            default {
              return (0, returndatasize())
            }
        }
  }

  receive() external payable{} //dummy function does nothing 

}