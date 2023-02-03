/**
 *Submitted for verification at Arbiscan on 2023-02-03
*/

pragma solidity ^0.8.0;

contract TokenDisperser2_0 {
  address owner;
  address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    constructor() public {
        owner = msg.sender;
    }
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function disperseETH(address payable[] memory _recipients)external payable{
        uint value = msg.value/_recipients.length;
        // Iterate through the recipients and send the corresponding amount of ETH
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(value);
        }
    }
    function disperseUSDC(address payable[] memory recepients)external{
        uint256 busd_val = IERC20(USDC).balanceOf(address(this));
        uint value = busd_val/recepients.length;
        for (uint256 i = 0; i < recepients.length; i++) {
            IERC20(USDC).transfer(recepients[i],value);
        }
    }
    function EmergencyWithdraw(address payable _receiver) external payable {
      
        require(msg.sender == owner, "You are not the owner.");
        _receiver.transfer(this.getBalance());
    }
    function setUSDCAddress(address _token) public {
        require(msg.sender == owner, "You are not the owner.");
        WETH = _token;
    }    
    
}
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}