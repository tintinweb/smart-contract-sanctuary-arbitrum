pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED


/** 
 * Tales of Elleria
*/
contract WithdrawalTest {

  address private ownerAddress;

  constructor() {
      ownerAddress = msg.sender;
    }
    
    function _onlyOwner() private view {
      require(msg.sender == ownerAddress, "O");
    }

    modifier onlyOwner() {
      _onlyOwner();
      _;
    }

    /**
  *  Allows batch minting of Heroes! (for presales only).
  */
  function mintPresales () public payable {
  }

  /**
    * Allows the ownership of the contract to be transferred to a safer multi-sig wallet once deployed.
    */ 
  function TransferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0));
    ownerAddress = _newOwner;
  }

  /* 
   * Allows the withdrawal of presale funds into the owner's wallet.
   * For fund allocation, refer to the whitepaper.
   */
  function withdraw() public onlyOwner {
    (bool success, ) = (msg.sender).call{value:address(this).balance}("");
    require(success, "2");
  }
}