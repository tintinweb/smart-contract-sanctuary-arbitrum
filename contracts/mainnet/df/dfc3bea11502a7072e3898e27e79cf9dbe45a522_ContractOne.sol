/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ContractOne {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferToken(address _tokenAddress, address _recipient, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_recipient != address(0), "Invalid recipient address");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");

        require(token.transfer(_recipient, _amount), "Token transfer failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}