// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../periphery/interfaces/IBribe.sol";

struct VeBribeReward {
   address bribeAddress;
   address[] tokenAddresses;
   uint256[] rewardAmounts;
}

contract VeHelper {
   constructor() {}

   function getRewardsForBribes(
      uint256[] memory tokenIds,
      address[] memory _bribes
   ) public view returns (VeBribeReward memory bribeRewardData) {
      for (uint256 index = 0; index < _bribes.length; index++) {
         IBribe bribe = IBribe(_bribes[index]);
         uint256 rewardsListLength = bribe.rewardsListLength();
         bribeRewardData = VeBribeReward(
            _bribes[index],
            new address[](rewardsListLength),
            new uint256[](rewardsListLength)
         );
         for (uint256 rewardIndex = 0; rewardIndex < rewardsListLength; rewardIndex++) {
            address rewardToken = bribe.rewards(rewardIndex);
            bribeRewardData.tokenAddresses[rewardIndex] = rewardToken;
            for (uint256 tokenIndex = 0; tokenIndex < tokenIds.length; tokenIndex++) {
               uint256 tokenId = tokenIds[tokenIndex];
               uint256 earned = bribe.earned(rewardToken, tokenId);
               bribeRewardData.rewardAmounts[rewardIndex] += earned;
            }
         }
      }
   }

   function getRewardsForBribesAllTokens(
      uint256 maxTokenId,
      address[] memory _bribes
   ) public view returns (VeBribeReward memory bribeRewardData) {
      for (uint256 index = 0; index < _bribes.length; index++) {
         IBribe bribe = IBribe(_bribes[index]);
         uint256 rewardsListLength = bribe.rewardsListLength();
         bribeRewardData = VeBribeReward(
            _bribes[index],
            new address[](rewardsListLength),
            new uint256[](rewardsListLength)
         );
         for (uint256 rewardIndex = 0; rewardIndex < rewardsListLength; rewardIndex++) {
            address rewardToken = bribe.rewards(rewardIndex);
            bribeRewardData.tokenAddresses[rewardIndex] = rewardToken;
            for (uint256 tokenIndex = 0; tokenIndex < maxTokenId; tokenIndex++) {
               uint256 tokenId = tokenIndex;
               uint256 earned = bribe.earned(rewardToken, tokenId);
               bribeRewardData.rewardAmounts[rewardIndex] += earned;
            }
         }
      }
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
   function notifyRewardAmount(address token, uint amount) external;

   function left(address token) external view returns (uint);

   function _deposit(uint amount, uint tokenId) external;

   function _withdraw(uint amount, uint tokenId) external;

   function getRewardForOwner(uint tokenId, address[] memory tokens) external;

   function balanceOf(uint tokenId) external view returns (uint);

   function earned(address token, uint tokenId) external view returns (uint);

   function batchRewardPerToken(address token, uint maxRuns) external;

   function swapOutReward(uint i, address oldToken, address newToken) external;

   function totalSupply() external view returns (uint);

   function rewardsListLength() external view returns (uint);

   function rewards(uint256 r) external view returns (address);
}