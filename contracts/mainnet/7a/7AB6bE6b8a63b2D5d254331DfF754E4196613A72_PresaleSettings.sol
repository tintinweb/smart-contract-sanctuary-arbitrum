// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

// Settings to initialize presale contracts and edit fees.

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

interface IPresaleAllowedReferrers {
    function allowedReferrersLength() external view returns (uint256);
    function getReferrerAtIndex(uint256 _index) external view returns (address);
    function referrerIsValid(address _referrer) external view returns (bool);
    function getReferrer01() external view returns (address);
}

contract PresaleSettings is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private EARLY_ACCESS_TOKENS;
    mapping(address => uint256) public EARLY_ACCESS_MAP;
    
    IPresaleAllowedReferrers public ALLOWED_REFERRERS;
    
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        uint256 REFERRAL_FEE; // a referrals percentage of the presale profits divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable NON_ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        address payable UNCL_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 ROUND1_LENGTH; // length of round 1 in blocks
        uint256 MAX_PRESALE_LENGTH; // maximum difference between start and endblock
        address UNCL_ADDRESS;
        uint256 UNCL_ALLOCATION_AMOUNT; // amount of UNCL required for guaranteed allocation
        uint256 ROUND_ZERO_OFFSET; // how many blocks after presale creation to kick of round 0
    }

    struct Settings2 {
        uint128 MINIMUM_PARTICIPANTS;
        uint128 WHITELIST_PERCENTAGE;
        uint128 UNCL_PERCENTAGE;
        uint256 REFERRAL_FEE_SPLIT; // second referral fee split divided by 100
    }
    
    Settings public SETTINGS;
    Settings2 public SETTINGS2;
    
    constructor(address _unclAddress, address _presaleAllowedReferrers) {
        ALLOWED_REFERRERS = IPresaleAllowedReferrers(_presaleAllowedReferrers);
        SETTINGS.BASE_FEE = 20; // 2%
        SETTINGS.TOKEN_FEE = 20; // 2%
        SETTINGS.REFERRAL_FEE = 100; // 10%
        SETTINGS.ETH_CREATION_FEE = 2e17;
        SETTINGS.ETH_FEE_ADDRESS = payable(0x04bDa42de3bc32Abb00df46004204424d4Cf8287);
        SETTINGS.NON_ETH_FEE_ADDRESS = payable(0x04bDa42de3bc32Abb00df46004204424d4Cf8287);
        SETTINGS.TOKEN_FEE_ADDRESS = payable(0x04bDa42de3bc32Abb00df46004204424d4Cf8287);
        SETTINGS.UNCL_FEE_ADDRESS = payable(0x04bDa42de3bc32Abb00df46004204424d4Cf8287);
        SETTINGS.ROUND1_LENGTH = 0; // 553 blocks = 2 hours
        SETTINGS.MAX_PRESALE_LENGTH = 518400; // 2 weeks
        SETTINGS.UNCL_ADDRESS = _unclAddress;
        SETTINGS.UNCL_ALLOCATION_AMOUNT = 2e18;
        SETTINGS.ROUND_ZERO_OFFSET = 0;
        // Settings 2
        SETTINGS2.MINIMUM_PARTICIPANTS = 1; // set this to 100
        SETTINGS2.WHITELIST_PERCENTAGE = 100; // set this to 20
        SETTINGS2.UNCL_PERCENTAGE = 0; // set this to 40
        SETTINGS2.REFERRAL_FEE_SPLIT = 60; // 60%
    }

    function getSettings () external view returns (Settings memory, Settings2 memory) {
        return (SETTINGS, SETTINGS2);
    }

    function getWhitelistPercentage () external view returns (uint128) {
      return SETTINGS2.WHITELIST_PERCENTAGE;
    }

    function getUNCLPercentage () external view returns (uint128) {
      return SETTINGS2.UNCL_PERCENTAGE;
    }

    function getMinimumParticipants () external view returns (uint128) {
      return SETTINGS2.MINIMUM_PARTICIPANTS;
    }

    function getUNCLInfo () external view returns (address, uint256, address) {
      return (SETTINGS.UNCL_ADDRESS, SETTINGS.UNCL_ALLOCATION_AMOUNT, SETTINGS.UNCL_FEE_ADDRESS);
    }
    
    function getRound1Length () external view returns (uint256) {
        return SETTINGS.ROUND1_LENGTH;
    }

    function getRound0Offset () external view returns (uint256) {
        return SETTINGS.ROUND_ZERO_OFFSET;
    }

    function getMaxPresaleLength () external view returns (uint256) {
        return SETTINGS.MAX_PRESALE_LENGTH;
    }
    
    function getBaseFee () external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    function getTokenFee () external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function getReferralFee () external view returns (uint256) {
        return SETTINGS.REFERRAL_FEE;
    }

    function getReferralSplitFee () external view returns (uint256) {
        return SETTINGS2.REFERRAL_FEE_SPLIT;
    }
    
    function getEthCreationFee () external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }
    
    function getEthAddress () external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }

    function getNonEthAddress () external view returns (address payable) {
        return SETTINGS.NON_ETH_FEE_ADDRESS;
    }
    
    function getTokenAddress () external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _nonEthAddress, address payable _tokenFeeAddress, address payable _unclFeeAddress) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.NON_ETH_FEE_ADDRESS = _nonEthAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
        SETTINGS.UNCL_FEE_ADDRESS = _unclFeeAddress;
    }

    function setAllocations(uint128 _minimumParticipants, uint128 _whitelistPercentage, uint128 _unclPercentage) external onlyOwner {
        SETTINGS2.MINIMUM_PARTICIPANTS = _minimumParticipants; // e.g. 100
        SETTINGS2.WHITELIST_PERCENTAGE = _whitelistPercentage; // e.g. 15 = 15%
        SETTINGS2.UNCL_PERCENTAGE = _unclPercentage; // e.g. 40 = 40%
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee, uint256 _referralFee, uint256 _referralFeeSplit) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.REFERRAL_FEE = _referralFee;
        SETTINGS2.REFERRAL_FEE_SPLIT = _referralFeeSplit;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }

    function setUNCLAllocationAmount(uint256 _amount) external onlyOwner {
        SETTINGS.UNCL_ALLOCATION_AMOUNT = _amount;
    }
    
    function setRound1Length(uint256 _round1Length) external onlyOwner {
        SETTINGS.ROUND1_LENGTH = _round1Length;
    }

    function setRound0Offset(uint256 _roundZeroOffset) external onlyOwner {
        SETTINGS.ROUND_ZERO_OFFSET = _roundZeroOffset;
    }

    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        SETTINGS.MAX_PRESALE_LENGTH = _maxLength;
    }
    
    function editEarlyAccessTokens(address _token, uint256 _holdAmount, bool _allow) external onlyOwner {
        if (_allow) {
            EARLY_ACCESS_TOKENS.add(_token);
        } else {
            EARLY_ACCESS_TOKENS.remove(_token);
        }
        EARLY_ACCESS_MAP[_token] = _holdAmount;
    }
    
    // there will never be more than 10 items in this array. Care for gas limits will be taken.
    // We are aware too many tokens in this unbounded array results in out of gas errors.
    function userHoldsSufficientRound1Token (address _user) external view returns (bool) {
        if (earlyAccessTokensLength() == 0) {
            return true;
        }
        for (uint i = 0; i < earlyAccessTokensLength(); i++) {
          (address token, uint256 amountHold) = getEarlyAccessTokenAtIndex(i);
          if (IERC20(token).balanceOf(_user) >= amountHold) {
              return true;
          }
        }
        return false;
    }
    
    function getEarlyAccessTokenAtIndex(uint256 _index) public view returns (address, uint256) {
        address tokenAddress = EARLY_ACCESS_TOKENS.at(_index);
        return (tokenAddress, EARLY_ACCESS_MAP[tokenAddress]);
    }
    
    function earlyAccessTokensLength() public view returns (uint256) {
        return EARLY_ACCESS_TOKENS.length();
    }
    
    // Referrers
    function allowedReferrersLength() external view returns (uint256) {
        return ALLOWED_REFERRERS.allowedReferrersLength();
    }
    
    function getReferrerAtIndex(uint256 _index) external view returns (address) {
        return ALLOWED_REFERRERS.getReferrerAtIndex(_index);
    }
    
    function referrerIsValid(address _referrer) external view returns (bool) {
        return ALLOWED_REFERRERS.referrerIsValid(_referrer);
    }

    function getReferrer01() external view returns (address) {
        return ALLOWED_REFERRERS.getReferrer01();
    }
    
}