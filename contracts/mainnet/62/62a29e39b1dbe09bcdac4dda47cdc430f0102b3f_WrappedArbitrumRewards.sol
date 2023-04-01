/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address owner);
}

contract WrappedArbitrumRewards is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) _rewardsToClaim;
    uint256 public UNFREEZE_TIMESPAN = 7 days;
    uint256 private lastActionTimestampInSec;

    constructor () Ownable(msg.sender) {
        lastActionTimestampInSec = block.timestamp;
    }

    function addRewards(uint[] calldata shares, address[] calldata addresses) external payable onlyOwner {
        require(shares.length == addresses.length, 'Arrays diffs');

        uint256 totalShares;
        for (uint i = 0; i < shares.length; i++) {
            totalShares = totalShares.add(shares[i]);
        }
        for (uint i = 0; i < shares.length; i++) {
            _rewardsToClaim[addresses[i]] = _rewardsToClaim[addresses[i]].add(msg.value.mul(shares[i]).div(totalShares));
        }
    }

    function getRewardsToClaim(address wallet) external view onlyOwner returns (uint256) {
        return _getRewardsToClaim(wallet);
    }

    function getMyRewardsToClaim() external view returns (uint256) {
        return _getRewardsToClaim(msg.sender);
    }

    function _getRewardsToClaim(address wallet) internal view returns (uint256) {
        return _rewardsToClaim[wallet];
    }

    function claimMyRewards() external returns (bool) {
        uint rewardsToClaim = _getRewardsToClaim(msg.sender);
        require(rewardsToClaim > 0, "Nothing to claim");
        _rewardsToClaim[msg.sender] = 0;

        if(!payable(msg.sender).send(rewardsToClaim)) {
            _rewardsToClaim[msg.sender] = rewardsToClaim;
            return false;
        }

        lastActionTimestampInSec = block.timestamp;
        return true;
    }

    function unfreezeContractBalance() public onlyOwner {
        uint256 unfreezeTimestamp = lastActionTimestampInSec.add(UNFREEZE_TIMESPAN);
        require(unfreezeTimestamp < block.timestamp, "Too early");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable { }

}