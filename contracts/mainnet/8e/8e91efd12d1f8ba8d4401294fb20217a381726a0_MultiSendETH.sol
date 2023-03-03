/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

pragma solidity ^0.4.26;

contract MultiSendETH {

  address public owner = 0x774D1b373cDa09bc098B7F8c9B5254e465d2DFCF;

  function multiSendEth(address[] addresses) public payable {
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(msg.value / addresses.length);
    }
    msg.sender.transfer(address(this).balance);
  }

	function recoverETH() public {
		owner.transfer(address(this).balance);
	}

	function recoverToken(IERC20 token) public {
		uint balance = token.balanceOf(address(this));
		token.transfer(owner, balance);
		}	

}

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}