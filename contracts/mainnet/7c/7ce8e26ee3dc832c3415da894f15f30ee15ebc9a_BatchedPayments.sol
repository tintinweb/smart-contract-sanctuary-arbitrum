/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

pragma solidity ^0.5.2;
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = 0xb7858aFc194e1C355fB4c4475c25a9d4224020FA; // replace by your public address in pool.config.json (paymentsConfig.publicAddress)
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/*
The owner (or anyone) will deposit tokens in here
The owner calls the multisend method to send out payments
*/
contract BatchedPayments is Ownable {

    mapping(bytes32 => bool) successfulPayments;


    function paymentSuccessful(bytes32 paymentId) public view returns (bool){
        return (successfulPayments[paymentId] == true);
    }

    //withdraw any eth inside
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function send(address _tokenAddr, address dest, uint value)
    public onlyOwner
    returns (bool)
    {
     return ERC20(_tokenAddr).transfer(dest, value);
    }

    function multisend(address _tokenAddr, bytes32 paymentId, address[] memory dests, uint256[] memory values)
    public onlyOwner
    returns (uint256)
     {

        require(dests.length > 0);
        require(values.length >= dests.length);
        require(successfulPayments[paymentId] != true);

        uint256 i = 0;
        while (i < dests.length) {
           require(ERC20(_tokenAddr).transfer(dests[i], values[i]));
           i += 1;
        }

        successfulPayments[paymentId] = true;

        return (i);

    }



}