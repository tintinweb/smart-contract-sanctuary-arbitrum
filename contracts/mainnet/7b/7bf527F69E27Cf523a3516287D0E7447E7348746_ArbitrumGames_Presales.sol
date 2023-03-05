// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";

contract ArbitrumGames_Presales is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint128 public startTime;
    uint128 public endTime;
    uint256 maxTier1Contributions;
    uint128 maxTier1ContributionPerWallet;
    uint256 public tokensTier1PerWei;
    uint256 public totalTier1Contributions;
    uint256 maxTier2Contributions;
    uint128 maxTier2ContributionPerWallet;
    uint256 public tokensTier2PerWei;
    uint256 public totalTier2Contributions;

    mapping(address => bool) public whiteLists;
    mapping(address => uint256) public contributed;
    mapping(address => uint256) public tier1Pending;
    mapping(address => uint256) public tier2Pending;

    uint128 public endTimeWhiteList = 2 hours;
    uint128 public constant startClaimAt = 4 hours;
    uint128 public constant claimPeriod = 14 days;
    uint128 public claimTime1st;
    uint128 public claimTime2nd;
    uint128 public claimTime3rd;
    uint128 public claimTime4th;
    mapping(address => bool) public claimTime1;
    mapping(address => bool) public claimTime2;
    mapping(address => bool) public claimTime3;
    mapping(address => bool) public claimTime4;
    IERC20 public immutable tokenForSale;
    address public transferTo;

    constructor(IERC20 _tokenForSale, address _owner, address _transferTo) {
        require(address(_tokenForSale) != address(0) && _owner != address(0),"zeroAddr");

        tokenForSale = _tokenForSale;

        transferTo = _transferTo;

        _transferOwnership(_owner);
    }

    function addWhiteList(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;

        for (uint256 i; i < len; ) {
            if (!whiteLists[_users[i]]) whiteLists[_users[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    function RemoveWhiteList(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;

        for (uint256 i; i < len; ) {
            if (whiteLists[_users[i]]) whiteLists[_users[i]] = false;

            unchecked {
                ++i;
            }
        }
    }

    function startSale(uint128 _maxTier1ContributionPerWallet, uint256 _maxTier1Contributions, uint256 _tokensTier1PerWei, uint128 _maxTier2ContributionPerWallet, uint256 _maxTier2Contributions, uint256 _tokensTier2PerWei, uint128 _startTime, uint128 _endTime) external onlyOwner {
        
        require(startTime == 0, "Started");

        require(_endTime > _startTime && _startTime > block.timestamp, "Dates");

        require(_endTime > _startTime + endTimeWhiteList, "Round");

        maxTier1ContributionPerWallet = _maxTier1ContributionPerWallet;

        maxTier1Contributions = _maxTier1Contributions;

        tokensTier1PerWei = _tokensTier1PerWei;

        maxTier2ContributionPerWallet = _maxTier2ContributionPerWallet;

        maxTier2Contributions = _maxTier2Contributions;

        tokensTier2PerWei = _tokensTier2PerWei;

        startTime = _startTime;

        endTime = _endTime;

        claimTime1st = _endTime + startClaimAt;

        claimTime2nd = _endTime + startClaimAt + claimPeriod;

        claimTime3rd = _endTime + startClaimAt + claimPeriod * 2;

        claimTime4th = _endTime + startClaimAt + claimPeriod * 3;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance");
        payable(msg.sender).transfer(balance);
    }

    function retrieve() external onlyOwner {
        require(block.timestamp > claimTime4th + claimPeriod, "Ongoing");

        uint256 balance = tokenForSale.balanceOf(address(this));

        tokenForSale.safeTransfer(msg.sender, balance);
    }

    function claimFor(address[] calldata _users) external onlyOwner {
        require(block.timestamp > claimTime4th + claimPeriod, "Ongoing");

        uint256 len = _users.length;

        for (uint256 i; i < len; ) {
            uint256 pendingTokens;

            if (block.timestamp > claimTime4th) {
                if (!claimTime4[_users[i]]) {
                    pendingTokens = (contributed[_users[i]] * 10) / 100;

                    claimTime4[_users[i]] = true;

                    if (!claimTime3[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 10) / 100;

                        claimTime3[_users[i]] = true;
                    }

                    if (!claimTime2[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 10) / 100;

                        claimTime2[_users[i]] = true;
                    }

                    if (!claimTime1[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 70) / 100;

                        claimTime1[_users[i]] = true;
                    }
                }
            } else if (block.timestamp > claimTime3rd) {
                if (!claimTime3[_users[i]]) {
                    pendingTokens = (contributed[_users[i]] * 10) / 100;

                    claimTime3[_users[i]] = true;

                    if (!claimTime2[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 10) / 100;

                        claimTime2[_users[i]] = true;
                    }

                    if (!claimTime1[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 70) / 100;

                        claimTime1[_users[i]] = true;
                    }
                }
            } else if (block.timestamp > claimTime2nd) {
                if (!claimTime2[_users[i]]) {
                    pendingTokens = (contributed[_users[i]] * 10) / 100;

                    claimTime2[_users[i]] = true;

                    if (!claimTime1[_users[i]]) {
                        pendingTokens += (contributed[_users[i]] * 70) / 100;

                        claimTime1[_users[i]] = true;
                    }
                }
            } else if (block.timestamp > claimTime1st) {
                if (!claimTime1[_users[i]]) {
                    pendingTokens = (contributed[_users[i]] * 70) / 100;

                    claimTime1[_users[i]] = true;
                }
            }

            if (pendingTokens > 0) {
                tokenForSale.safeTransfer(_users[i], pendingTokens);
            }

            unchecked {
                ++i;
            }
        }
    }

    function purchase() external payable nonReentrant returns (uint256) {
        require(block.timestamp > startTime && startTime > 0, "Not Started");
        require(block.timestamp < endTime, "Sale Ended");
        require(msg.value > 0, "Amount");
        if (block.timestamp <= startTime + endTimeWhiteList) {
            require(whiteLists[msg.sender], "Only White List");

            uint256 _totalTier1Contributions = totalTier1Contributions;

            require(
                _totalTier1Contributions < maxTier1Contributions,
                "Sale Max Tier 1"
            );

            require(
                tier1Pending[msg.sender] + msg.value <=
                    maxTier1ContributionPerWallet,
                "Max Sale Per Wallet Tier 1"
            );

            uint256 purchaseTier1WeiAmount = (_totalTier1Contributions +
                msg.value >
                maxTier1Contributions)
                ? maxTier1Contributions - _totalTier1Contributions
                : msg.value;

            uint256 tokensTier1ToPurchase = purchaseTier1WeiAmount *
                tokensTier1PerWei;

            tier1Pending[msg.sender] += purchaseTier1WeiAmount;

            totalTier1Contributions += purchaseTier1WeiAmount;

            contributed[msg.sender] += tokensTier1ToPurchase;

            uint256 refund = msg.value - purchaseTier1WeiAmount;

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            payable(transferTo).transfer(purchaseTier1WeiAmount);

            return tokensTier1ToPurchase;
        } else {
            uint256 _totalTier2Contributions = totalTier2Contributions;

            require(
                _totalTier2Contributions < maxTier2Contributions,
                "Sale Max Tier 2"
            );

            require(
                tier2Pending[msg.sender] + msg.value <=
                    maxTier2ContributionPerWallet,
                "Max Sale Per Wallet Tier 2"
            );

            uint256 purchaseTier2WeiAmount = (_totalTier2Contributions +
                msg.value >
                maxTier2Contributions)
                ? maxTier2Contributions - _totalTier2Contributions
                : msg.value;

            uint256 tokensTier2ToPurchase = purchaseTier2WeiAmount *
                tokensTier2PerWei;

            tier2Pending[msg.sender] += purchaseTier2WeiAmount;

            totalTier2Contributions += purchaseTier2WeiAmount;

            contributed[msg.sender] += tokensTier2ToPurchase;

            uint256 refund = msg.value - purchaseTier2WeiAmount;

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            payable(transferTo).transfer(purchaseTier2WeiAmount);

            return tokensTier2ToPurchase;
        }
    }

    function claim() external nonReentrant returns (uint256) {
        uint256 pendingTokens;

        if (block.timestamp > claimTime4th) {
            require(!claimTime4[msg.sender], "Claimed");

            pendingTokens = (contributed[msg.sender] * 10) / 100;

            claimTime4[msg.sender] = true;

            if (!claimTime3[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 10) / 100;

                claimTime3[msg.sender] = true;
            }

            if (!claimTime2[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 10) / 100;

                claimTime2[msg.sender] = true;
            }

            if (!claimTime1[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 70) / 100;

                claimTime1[msg.sender] = true;
            }
        } else if (block.timestamp > claimTime3rd) {
            require(!claimTime3[msg.sender], "Claimed");

            pendingTokens = (contributed[msg.sender] * 10) / 100;

            claimTime3[msg.sender] = true;

            if (!claimTime2[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 10) / 100;

                claimTime2[msg.sender] = true;
            }

            if (!claimTime1[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 70) / 100;

                claimTime1[msg.sender] = true;
            }
        } else if (block.timestamp > claimTime2nd) {
            require(!claimTime2[msg.sender], "Claimed");

            pendingTokens = (contributed[msg.sender] * 10) / 100;

            claimTime2[msg.sender] = true;

            if (!claimTime1[msg.sender]) {
                pendingTokens += (contributed[msg.sender] * 70) / 100;

                claimTime1[msg.sender] = true;
            }
        } else if (block.timestamp > claimTime1st) {
            require(!claimTime1[msg.sender], "Claimed");

            pendingTokens = (contributed[msg.sender] * 70) / 100;

            claimTime1[msg.sender] = true;
        } else {
            revert("Phase");
        }

        require(pendingTokens > 0, "No Pending");

        tokenForSale.safeTransfer(msg.sender, pendingTokens);

        return pendingTokens;
    }

    function claimState(address _address) public view returns (bool, bool, bool, bool)
    {
        return (claimTime1[_address], claimTime2[_address], claimTime3[_address], claimTime4[_address]);
    }
    function tokenPending(address _address) public view returns (uint256, uint256){
        return (tier1Pending[_address],tier2Pending[_address]);
    }
}