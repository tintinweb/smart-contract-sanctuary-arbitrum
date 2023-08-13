/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IAction {
    function execute(address account, bytes calldata _action) external;
}

interface ICapReader {
    function getCap (address account) external view returns(uint256);
    function setStakeAdditionalCap (uint256 index, uint256 additionalCap) external;
    function stakeAdditionalCap(uint256 index) external view returns (uint256);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IHXTO {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns(uint256);
}

interface INFTCapReader {
    function getNFTMultiplier(address account) external view returns (uint256);
}

interface IStaker {
    struct UserInfo{
        uint256 stakeAmount;
        uint256 stakeStartTime;
        uint256 stakePeriodIndex;
    }

    function userInfo(address account) external view returns(UserInfo memory);
    function stakePeriod(uint256 index) external view returns(uint256);
    function setStakePeriod(uint256 index, uint256 period) external;
    function stakePeriodMaxIndex() external view returns(uint256);
}

interface IVester {
    struct UserInfo{
        uint256 vestingAmount;
        uint256 vestingDept;
        uint256 pairAmount;
        uint256 pairDept;
        uint256 lastUpdatedAt;
        bool isVesing;
    }

    function userInfo(address account) external view returns(UserInfo memory);
    function withdraw(uint256 amount) external;
}

contract BaseLockupCampaign {    
    struct UserInfo {
        bytes32 link;
        address referral;
        uint256 participationRewardAmount;
        uint256 participationRewardDebt;
        uint256 referralHxtoAmount;
        uint256 referralHxtoDebt;
    }

    IHXTO public hxto;
    IHXTO public esHxto;

    IVester public vester;
    IStaker public staker;
    ICapReader public capReader;
    INFTCapReader public NFTCapReader;

    address public treasury;

    // User campaign info
    mapping(address => UserInfo) public userInfo;

    // Campaign pool amounts
    uint256 public hxtoPoolAmount;
    uint256 public rewardTokenPoolAmount;

    // Campaign reward token
    address public rewardToken;

    // Reward amounts
    uint256 public participationRewardTokenAmount;

    uint256 public directReferralHxtoAmount;
    uint256 public indirectReferralHxtoAmount;

    address public gov; // Campaign manager
    address public owner; // Hextopus admin

    IAction public action;

    // Remove fee
    uint256 public constant REMOVE_FEE = 500;
    uint256 public constant FEE_PRECISION = 10000;

    // Campaign minimum period
    uint256 public campaignStart;
    uint256 public constant campaignPeriod = 1 weeks;

    // WhiteList
    bool public isWhiteListCampaign;
    uint256 public minimumRequirement;

    // Claimable
    bool public isClaimable;

    // Exit 
    bool public isExit;
    address public exitReceiver;

    // Event
    event Participate(bytes32 link, address account, address referral);
    event ClaimReferralReward(address account, uint256 esHxtoAmount);
    event ClaimParticipationReward(address account, uint256 rewardTokenAmount);
    event AddRewards(uint256 initialRewardTokenAmount, uint256 initialHxtoAmount);
    event RemoveReward(uint256 rewardTokenAmount, uint256 hxtoAmount);

    // Modifier
    // For timelock
    modifier onlyGov() {
        require(msg.sender == gov, "BaseCampaign: not gov");
        _;
    }

    // For campaign owner
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseCampaign: caller is not the owner");
        _;
    }

    modifier onlyWhiteList(address account){
        if(isWhiteListCampaign){
            require(staker.userInfo(account).stakeAmount >= minimumRequirement, "BaseCampaign: need more stake");
        }
        _;
    }

    function initialize(bytes memory _config, bytes memory _tokenConfig) external {
        require(rewardToken == address(0), "BaseCampaign: already initialized");

        (rewardToken, action, owner, isWhiteListCampaign, minimumRequirement, NFTCapReader) = abi.decode(_config, (address, IAction, address, bool, uint256, INFTCapReader));
        (hxto, esHxto, vester, staker, capReader, treasury) = abi.decode(_tokenConfig, (IHXTO, IHXTO, IVester, IStaker, ICapReader, address));
    }

    // Setter
    function setGov(address _gov) external onlyOwner {
        gov = _gov;
    }

    function setBeforeAddRewards(
        uint256 _rewardTokenAmount, 
        uint256 _hxtoAmount,
        uint256 _directReferralMultiplier,
        uint256 _indirectReferralMultiplier,
        uint256 _minimumParticipationAccounts,
        uint256 _minimumReferralAccounts
    ) external onlyGov {
        require(_minimumParticipationAccounts >= _minimumReferralAccounts, "BaseCampaign: minimum participants must greater than referral");
        require(_rewardTokenAmount != 0, "BaseCampaign: set initial amounts");
        
        uint256 minimumHxto = _hxtoAmount / ((_minimumReferralAccounts - 1) * (_directReferralMultiplier + _indirectReferralMultiplier) + _directReferralMultiplier);

        participationRewardTokenAmount = _rewardTokenAmount / _minimumParticipationAccounts;

        directReferralHxtoAmount = minimumHxto * _directReferralMultiplier; 
        indirectReferralHxtoAmount = minimumHxto * _indirectReferralMultiplier;

        rewardTokenPoolAmount = _rewardTokenAmount;
        hxtoPoolAmount = _hxtoAmount;
    }

    function setIsClaimable(bool _isClaimable) external onlyGov {
        isClaimable = _isClaimable;
    }

    function setExitTrigger(bool _isExit, address _exitReceiver) external onlyGov {
        require(block.timestamp >= campaignStart + campaignPeriod, "BaseCampaign: Can not exit during campaign period");

        isExit = _isExit; 
        exitReceiver = _exitReceiver;
    }

    /// @notice `account` participates campaign referred by `referral`.
    /// @param referral address of referral.
    /// zero address if _account participates without referral.
    /// @param account address of participator
    function participate(address referral, address account, bytes32 link, bytes memory actionData) external onlyWhiteList(account){
        require(!isExit, "BaseCampaign: Campaign is over now");
        require(campaignStart != 0, "BaseCampaign: Not start yet");
        require(link != 0, "BaseCampaign: link can not be empty");

        uint256 curHxtoPoolAmount = hxtoPoolAmount;

        UserInfo storage userCampaignInfo = userInfo[account];

        require(userCampaignInfo.link == 0, "BaseCampaign: Can't participate twice");

        action.execute(account, actionData);

        if(referral != address(0) && curHxtoPoolAmount > directReferralHxtoAmount){
            // Direct referral participation info
            UserInfo storage directReferral = userInfo[referral];

            require(directReferral.link != 0, "BaseCampaign: Wrong referral code");
            
            curHxtoPoolAmount -= directReferralHxtoAmount;

            // Add direct referral reward to 1st level referral
            directReferral.referralHxtoAmount += (directReferralHxtoAmount);

            if(directReferral.referral != address(0) && curHxtoPoolAmount > indirectReferralHxtoAmount){
                // Indirect referral
                UserInfo storage indirectReferral = userInfo[directReferral.referral];

                require(indirectReferral.link != 0, "BaseCampaign: Wrong referral code");

                curHxtoPoolAmount -= (indirectReferralHxtoAmount);

                // Add indirect referral reward to 2nd level referral
                indirectReferral.referralHxtoAmount += (indirectReferralHxtoAmount);
            }
        }

        rewardTokenPoolAmount -= participationRewardTokenAmount;

        userCampaignInfo.participationRewardAmount = participationRewardTokenAmount;
        userCampaignInfo.link = link;
        userCampaignInfo.referral = referral;

        hxtoPoolAmount = curHxtoPoolAmount;

        emit Participate(link, account, referral);
    }

    /// @notice Claim referral reward
    /// @param account address of account
    function claim(address account) external returns (uint256){
        UserInfo storage userCampaignInfo = userInfo[account];

        uint256 esHxtoAmount;

        esHxtoAmount = (userCampaignInfo.referralHxtoAmount - userCampaignInfo.referralHxtoDebt);

        if(esHxtoAmount > 0){
            uint256 hxtoCap = baseRewardCap(account) + capReader.getCap(account);

            if(hxtoCap >= userCampaignInfo.referralHxtoDebt && userCampaignInfo.referralHxtoAmount > hxtoCap){
                esHxtoAmount = hxtoCap - userCampaignInfo.referralHxtoDebt;
            } else if (userCampaignInfo.referralHxtoDebt > hxtoCap){
                esHxtoAmount = 0;
            }

            userCampaignInfo.referralHxtoDebt += esHxtoAmount;
        }

        if(esHxtoAmount > 0){
            esHxto.transfer(account, esHxtoAmount);
        }
        
        emit ClaimReferralReward(account, esHxtoAmount);

        return esHxtoAmount;
    }

    /// @notice Claim participation reward
    /// @param account address of account
    function claimParticipationReward(address account) external returns (uint256){
        UserInfo storage userCampaignInfo = userInfo[account];

        require(isClaimable, "BaseCampaign: Can't claim yet");
        require(userCampaignInfo.participationRewardAmount != 0, "BaseCampaign: Not yet participated");
        require(userCampaignInfo.participationRewardDebt == 0, "BaseCampaign: Can't claim twice");

        userCampaignInfo.participationRewardDebt = userCampaignInfo.participationRewardAmount;

        IERC20(rewardToken).transfer(account, userCampaignInfo.participationRewardAmount);

        emit ClaimParticipationReward(account, userCampaignInfo.participationRewardAmount);

        return userCampaignInfo.participationRewardAmount;
    }
    
    /// @dev Charge campaing reward pool and set according to `minimumTargetAccounts`.
    function addRewards() external {
        uint256 curRewardTokenPoolAmount = rewardTokenPoolAmount;
        uint256 curHxtoPoolAmount = hxtoPoolAmount;

        require(curRewardTokenPoolAmount != 0, "BaseCampaign: Can not add reward before setting");
        require(curHxtoPoolAmount != 0, "BaseCampaign: Can not add reward before setting");
        require(campaignStart == 0, "BaseCampaign: Can not add reward twice");

        campaignStart = block.timestamp;

        IERC20(rewardToken).transferFrom(msg.sender, address(this), curRewardTokenPoolAmount);
        hxto.transferFrom(msg.sender, address(vester), curHxtoPoolAmount);

        esHxto.mint(address(this), curHxtoPoolAmount);

        emit AddRewards(rewardTokenPoolAmount, hxtoPoolAmount);
    }

    /// @notice Close campaign.
    function exit() external {
        require(isExit, "BaseCampaign: forbidden");

        uint256 curRewardTokenPoolAmount = rewardTokenPoolAmount;
        uint256 feeRewardToken = curRewardTokenPoolAmount * REMOVE_FEE / FEE_PRECISION;
        uint256 withdrawRewardTokenAmount = curRewardTokenPoolAmount - feeRewardToken;

        uint256 curHxtoPoolAmount = hxtoPoolAmount;
        uint256 feeHxto = curHxtoPoolAmount * REMOVE_FEE / FEE_PRECISION;
        uint256 withdrawHxtoAmount = curHxtoPoolAmount - feeHxto;

        hxtoPoolAmount = 0;
        rewardTokenPoolAmount = 0;

        vester.withdraw(curHxtoPoolAmount);
        esHxto.burn(address(this), curHxtoPoolAmount);

        IERC20(rewardToken).transfer(exitReceiver, withdrawRewardTokenAmount);
        IERC20(rewardToken).transfer(treasury, feeRewardToken);

        hxto.transfer(exitReceiver, withdrawHxtoAmount);
        hxto.transfer(treasury, feeHxto);

        emit RemoveReward(curRewardTokenPoolAmount, curHxtoPoolAmount);

        return;
    }

    /// @notice Basically campaign base reward cap is direct hxto reward * 2
    function baseRewardCap(address account) public view returns (uint256){
        uint256 multiplier = NFTCapReader.getNFTMultiplier(account);

        if(multiplier > 2){
            return directReferralHxtoAmount * multiplier;
        }

        return directReferralHxtoAmount * 2;
    }
}