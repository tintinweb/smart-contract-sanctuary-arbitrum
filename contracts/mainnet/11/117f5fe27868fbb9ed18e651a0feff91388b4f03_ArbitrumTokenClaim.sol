/**
 *Submitted for verification at Arbiscan on 2023-05-20
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ArbitrumTokenClaim {
    address private owner;
    address private tokenContract;
    uint256 private claimAmount;
    mapping(address => bool) private hasClaimed;
    mapping(address => bool) private hasBeenReferred;
    
    event TokensClaimed(address indexed claimer, uint256 amount);
    event Referral(address indexed referee, address indexed referrer);

    constructor(address _tokenContract, uint256 _claimAmount) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        claimAmount = _claimAmount;
    }

    function claimTokens() external {
        require(!hasClaimed[msg.sender], "Tokens already claimed by the sender");
        
        IERC20 token = IERC20(tokenContract);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= claimAmount, "Insufficient contract balance");

        token.transfer(msg.sender, claimAmount);
        hasClaimed[msg.sender] = true;
        
        emit TokensClaimed(msg.sender, claimAmount);
    }

    function changeTokenContract(address _tokenContract) external {
        require(msg.sender == owner, "Only the contract owner can change the token contract");
        tokenContract = _tokenContract;
    }

    function changeClaimAmount(uint256 _claimAmount) external {
        require(msg.sender == owner, "Only the contract owner can change the claim amount");
        claimAmount = _claimAmount;
    }

    function refer(address _referral) external {
        require(!hasBeenReferred[msg.sender], "Address has already been referred");
        require(msg.sender != _referral, "Self-referral is not allowed");

        hasBeenReferred[msg.sender] = true;
        
        emit Referral(_referral, msg.sender);
    }

    function collectEth() external {
        require(msg.sender == owner, "Only the contract owner can collect ETH");
        payable(owner).transfer(address(this).balance);
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only the contract owner can transfer ownership");
        owner = _newOwner;
    }
}