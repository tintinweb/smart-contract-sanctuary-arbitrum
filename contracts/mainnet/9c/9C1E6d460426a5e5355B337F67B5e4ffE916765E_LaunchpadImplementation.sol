// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract LaunchpadImplementation {

    struct Tuple5648467 {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    struct Tuple6449688 {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        Tuple632674 fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        Tuple0343533 refundInfo;
        Tuple9075317 idoInfo;
    }

    struct Tuple632674 {
        uint256 softCap;
        uint256 hardCap;
    }

    struct Tuple0343533 {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct Tuple9075317 {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct Tuple5806339 {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct Tuple3789929 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct Tuple7459929 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }
      

   function buyTokens(uint256  tokenAmount) external payable {}

   function buyTokensWithSupercharger(Tuple5648467 memory input) external payable {}

   function checkSignature(address  wallet, uint256  tier, uint256  nonce, uint256  deadline, bytes memory signature) external view {}

   function claimTokens() external {}

   function getAllInvestors() external view returns (address[] memory) {}

   function getCurrentTier() external view returns (uint256 ) {}

   function getFeeShare() external view returns (uint256 ) {}

   function getHardCapPerTier(uint256  tier) external view returns (uint256 ) {}

   function getInvestorAddressByIndex(uint256  index) external view returns (address ) {}

   function getInvestorsLength() external view returns (uint256 ) {}

   function getLaunchPadAddress() external view returns (address ) {}

   function getLaunchPadInfo() external view returns (Tuple6449688 memory) {}

   function getMaxInvestPerWalletPerTier(uint256  tier) external view returns (uint256 ) {}

   function getNextNonce(address  user) external view returns (uint256 ) {}

   function getProjectOwnerRole() external pure returns (bytes32 ) {}

   function getPurchasedInfoByUser(address  user) external view returns (Tuple5806339 memory) {}

   function getReleaseSchedule() external view returns (Tuple3789929[] memory) {}

   function getReleasedTokensPercentage() external view returns (uint256  releasedPerc) {}

   function getTokenCreationDeadline() external view returns (uint256 ) {}

   function getTokensAvailableToBeClaimed(address  user) external view returns (uint256 ) {}

   function getTotalRaised() external view returns (uint256 ) {}

   function isSuperchargerEnabled() external view returns (bool ) {}

   function paused() external view returns (bool  status) {}

   function recoverSigner(bytes32  message, bytes memory signature) external pure returns (address ) {}

   function refund(uint256  tokenAmount) external {}

   function refundOnSoftCapFailure() external {}

   function refundOnTokenCreationExpired(uint256  tokenAmount) external {}

   function tokenDecimals() external view returns (uint256 ) {}

   function totalTokensClaimed() external view returns (uint256 ) {}

   function totalTokensSold() external view returns (uint256 ) {}

   function extendDuration(uint256  durationIncrease) external {}

   function setSupercharger(bool  enabled) external {}

   function setTokenAddress(address  tokenAddress) external {}

   function updateReleaseSchedule(Tuple7459929[] memory releaseSchedule) external {}

   function updateStartTimestamp(uint256  newStartTimestamp) external {}

   function withdrawFees() external {}

   function withdrawTokens(address  tokenAddress) external {}

   function withdrawTokensToRecipient(address  tokenAddress, address  recipient) external {}

   function DEFAULT_ADMIN_ROLE() external pure returns (bytes32 ) {}

   function MINTER_ROLE() external pure returns (bytes32 ) {}

   function PAUSER_ROLE() external pure returns (bytes32 ) {}

   function WHITELISTED_ROLE() external pure returns (bytes32 ) {}

   function WHITELIST_ADMIN_ROLE() external pure returns (bytes32 ) {}

   function getRoleAdmin(bytes32  role) external view returns (bytes32 ) {}

   function getRoleMember(bytes32  role, uint256  index) external view returns (address ) {}

   function getRoleMemberCount(bytes32  role) external view returns (uint256 ) {}

   function grantRole(bytes32  role, address  account) external {}

   function hasRole(bytes32  role, address  account) external view returns (bool ) {}

   function renounceRole(bytes32  role) external {}

   function revokeRole(bytes32  role, address  account) external {}

   function pause() external {}

   function unpause() external {}

   function facetAddress(bytes4  _functionSelector) external view returns (address  facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address  _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

   function facets() external view returns (Tuple1236461[] memory facets_) {}

   function supportsInterface(bytes4  _interfaceId) external view returns (bool ) {}

   function implementation() external view returns (address ) {}

   function setImplementation(address  _implementation) external {}
}