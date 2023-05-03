/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Airdrop {
    struct User {
        uint256 lastClaimed;
        bool isWhitelisted;
        uint256 percentClaimed;
        uint256 totalClaimed;
    }

    mapping(address => User) public users;

    uint256 public MAX_PER_ADDRESS;
    uint256 public totalClaimed;

    uint256 public monthlyClaimPercent;
    uint256 public startClaim;

    IERC20Burnable public token;
    address public owner;

    event TokensClaimed(address indexed user, uint256 amount);
    event Burn(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(
        address _tokenAddress,
        uint256 _maxperaddress,
        uint256 _monthlyClaimPercent,
        uint256 _startClaim
    ) {
        token = IERC20Burnable(_tokenAddress);
        owner = msg.sender;
        MAX_PER_ADDRESS = _maxperaddress;
        monthlyClaimPercent = _monthlyClaimPercent;
        startClaim = _startClaim;
    }

    function whitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]].isWhitelisted = true;
        }
    }

    function changeMonthlyClaimPercent(uint256 _monthlyClaimPercent)
        public
        onlyOwner
    {
        monthlyClaimPercent = _monthlyClaimPercent;
    }

    function changeStartClaim(uint256 _startClaim) public onlyOwner {
        startClaim = _startClaim;
    }

    function claimTokens() public {
        User storage user = users[msg.sender];
        require(user.isWhitelisted, "User is not whitelisted");

        require(block.timestamp > startClaim, "Claim has not start yet !");

        uint256 tokensToClaim = calculateTokensToClaim();

        require(
            token.balanceOf(address(this)) >= tokensToClaim,
            "Not enough tokens in contract"
        );

        require(
            token.transfer(msg.sender, tokensToClaim),
            "Token transfer failed"
        );

        totalClaimed += tokensToClaim;
        user.lastClaimed = block.timestamp;
        user.totalClaimed += tokensToClaim;
        user.percentClaimed += monthlyClaimPercent;

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    function burn(uint256 _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= _amount,
            "Not enough tokens in contract"
        );
        require(token.burn(_amount), "Burn failed");
        emit Burn(_amount);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= _amount,
            "Not enough tokens in contract"
        );
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    function calculateTokensToClaim() private view returns (uint256) {
        User memory user = users[msg.sender];
        if (user.lastClaimed == 0) {
            //first claim

            return (MAX_PER_ADDRESS * monthlyClaimPercent) / 100;
        }
        uint256 timeSinceLastClaimed = block.timestamp - user.lastClaimed;

        uint256 maxClaimPercent = monthlyClaimPercent *
            (timeSinceLastClaimed / 30 days);

        if (maxClaimPercent == 0 || maxClaimPercent>=(100-user.percentClaimed)) return 0;

        uint256 tokensToClaim = (MAX_PER_ADDRESS * maxClaimPercent) / 100;
      
        return tokensToClaim;
    }
}