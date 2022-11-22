// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/INFTHandler.sol";
import "./interfaces/INFTPool.sol";
import "./interfaces/INitroPoolFactory.sol";
import "./interfaces/tokens/IGrailTokenV2.sol";
import "./interfaces/tokens/IXGrailToken.sol";
import "./interfaces/INitroCustomReq.sol";


contract NitroPool is ReentrancyGuard, Ownable, INFTHandler {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeERC20 for IXGrailToken;
    using SafeERC20 for IGrailTokenV2;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 totalDepositAmount; // Save total deposit amount
        uint256 rewardDebtToken1;
        uint256 rewardDebtToken2;
        uint256 pendingRewardsToken1; // can't be harvested before harvestStartTime
        uint256 pendingRewardsToken2; // can't be harvested before harvestStartTime
    }

    struct Settings {
        uint256 startTime; // Start of rewards distribution
        uint256 endTime; // End of rewards distribution
        uint256 harvestStartTime; // (optional) Time at which stakers will be allowed to harvest their rewards
        uint256 depositEndTime; // (optional) Time at which deposits won't be allowed anymore
        uint256 lockDurationReq; // (optional) required lock duration for positions
        uint256 lockEndReq; // (optional) required lock end time for positions
        uint256 depositAmountReq; // (optional) required deposit amount for positions
        bool whitelist; // (optional) to only allow whitelisted users to deposit
        string description; // Project's description for this NitroPool
    }

    struct RewardsToken {
        IERC20 token;
        uint256 amount; // Total rewards to distribute
        uint256 remainingAmount; // Remaining rewards to distribute
        uint256 accRewardsPerShare;
    }

    struct WhitelistStatus {
        address account;
        bool status;
    }

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    INitroPoolFactory public factory; // NitroPoolFactory address
    IGrailTokenV2 public grailToken; // GRAILToken contract
    IXGrailToken public xGrailToken; // xGRAILToken contract
    INFTPool public nftPool; // NFTPool contract
    INitroCustomReq public customReqContract; // (optional) external contracts allow to handle custom requirements

    uint256 public creationTime; // Creation time of this NitroPool

    bool public published; // Is NitroPool published
    uint256 public publishTime; // Time at which the NitroPool was published

    bool public emergencyClose; // When activated, can't distribute rewards anymore

    RewardsToken public rewardsToken1; // rewardsToken1 data
    RewardsToken public rewardsToken2; // (optional) rewardsToken2 data

    // pool info
    uint256 public totalDepositAmount;
    uint256 public lastRewardTime;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => address) public tokenIdOwner; // save tokenId previous owner
    mapping(address => EnumerableSet.UintSet) private _userTokenIds; // save previous owner tokenIds

    EnumerableSet.AddressSet private _whitelistedUsers; // whitelisted users
    Settings public settings; // global and requirements settings

    constructor(
        IGrailTokenV2 grailToken_, IXGrailToken xGrailToken_, address owner_, INFTPool nftPool_,
        IERC20 rewardsToken1_, IERC20 rewardsToken2_, Settings memory settings_
    ) {
        require(address(grailToken_) != address(0) && address(xGrailToken_) != address(0) && owner_ != address(0)
            && address(nftPool_) != address(0) && address(rewardsToken1_) != address(0), "zero address");
        require(_currentBlockTimestamp() < settings_.startTime, "invalid startTime");
        require(settings_.startTime < settings_.endTime, "invalid endTime");
        require(settings_.depositEndTime == 0 || settings_.startTime <= settings_.depositEndTime, "invalid depositEndTime");
        require(settings_.harvestStartTime == 0 || settings_.startTime <= settings_.harvestStartTime, "invalid harvestStartTime");
        require(address(rewardsToken1_) != address(rewardsToken2_), "invalid tokens");

        factory = INitroPoolFactory(msg.sender);

        grailToken = grailToken_;
        xGrailToken = xGrailToken_;
        nftPool = nftPool_;
        creationTime = _currentBlockTimestamp();

        rewardsToken1.token = rewardsToken1_;
        rewardsToken2.token = rewardsToken2_;

        settings.startTime = settings_.startTime;
        settings.endTime = settings_.endTime;
        lastRewardTime = settings_.startTime;

        if (settings_.harvestStartTime == 0) settings.harvestStartTime = settings_.startTime;
        else settings.harvestStartTime = settings_.harvestStartTime;
        settings.depositEndTime = settings_.depositEndTime;

        settings.description = settings_.description;

        _setRequirements(settings_.lockDurationReq, settings_.lockEndReq, settings_.depositAmountReq, settings_.whitelist);

        Ownable.transferOwnership(owner_);
    }


    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event ActivateEmergencyClose();
    event AddRewardsToken1(uint256 amount, uint256 feeAmount);
    event AddRewardsToken2(uint256 amount, uint256 feeAmount);
    event Deposit(address indexed userAddress, uint256 tokenId, uint256 amount);
    event Harvest(address indexed userAddress, IERC20 rewardsToken, uint256 pending);
    event Publish();
    event SetDateSettings(uint256 endTime, uint256 harvestStartTime, uint256 depositEndTime);
    event SetDescription(string description);
    event SetRequirements(uint256 lockDurationReq, uint256 lockEndReq, uint256 depositAmountReq, bool whitelist);
    event SetRewardsToken2(IERC20 rewardsToken2);
    event SetCustomReqContract(address contractAddress);
    event UpdatePool();
    event WhitelistUpdated();
    event Withdraw(address indexed userAddress, uint256 tokenId, uint256 amount);
    event EmergencyWithdraw(address indexed userAddress, uint256 tokenId, uint256 amount);
    event WithdrawRewardsToken1(uint256 amount, uint256 totalRewardsAmount);
    event WithdrawRewardsToken2(uint256 amount, uint256 totalRewardsAmount);


    /**************************************************/
    /****************** PUBLIC VIEWS ******************/
    /**************************************************/

    /**
     * @dev Returns the amount of rewardsToken1 distributed every second
     */
    function rewardsToken1PerSecond() public view returns (uint256) {
        if (settings.endTime <= lastRewardTime) return 0;
        return rewardsToken1.remainingAmount.div(settings.endTime.sub(lastRewardTime));
    }

    /**
     * @dev Returns the amount of rewardsToken2 distributed every second
     */
    function rewardsToken2PerSecond() public view returns (uint256) {
        if (settings.endTime <= lastRewardTime) return 0;
        return rewardsToken2.remainingAmount.div(settings.endTime.sub(lastRewardTime));
    }

    /**
     * @dev Returns the number of whitelisted addresses
     */
    function whitelistLength() external view returns (uint256) {
        return _whitelistedUsers.length();
    }

    /**
     * @dev Returns a whitelisted address from its "index"
     */
    function whitelistAddress(uint256 index) external view returns (address) {
        return _whitelistedUsers.at(index);
    }

    /**
     * @dev Checks if "account" address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelistedUsers.contains(account);
    }

    /**
     * @dev Returns the number of tokenIds from positions deposited by "account" address
     */
    function userTokenIdsLength(address account) external view returns (uint256) {
        return _userTokenIds[account].length();
    }

    /**
     * @dev Returns a position's tokenId deposited by "account" address from its "index"
     */
    function userTokenId(address account, uint256 index) external view returns (uint256) {
        return _userTokenIds[account].at(index);
    }

    /**
     * @dev Returns pending rewards (rewardsToken1 and rewardsToken2) for "account" address
     */
    function pendingRewards(address account) external view returns (uint256 pending1, uint256 pending2) {
        UserInfo memory user = userInfo[account];

        // recompute accRewardsPerShare for rewardsToken1 & rewardsToken2 if not up to date
        uint256 accRewardsToken1PerShare_ = rewardsToken1.accRewardsPerShare;
        uint256 accRewardsToken2PerShare_ = rewardsToken2.accRewardsPerShare;

        // only if existing deposits and lastRewardTime already passed
        if (lastRewardTime < _currentBlockTimestamp() && totalDepositAmount > 0) {
            uint256 rewardsAmount = rewardsToken1PerSecond().mul(_currentBlockTimestamp().sub(lastRewardTime));
            // in case of rounding errors
            if (rewardsAmount > rewardsToken1.remainingAmount) rewardsAmount = rewardsToken1.remainingAmount;
            accRewardsToken1PerShare_ = accRewardsToken1PerShare_.add(rewardsAmount.mul(1e18).div(totalDepositAmount));

            rewardsAmount = rewardsToken2PerSecond().mul(_currentBlockTimestamp().sub(lastRewardTime));
            // in case of rounding errors
            if (rewardsAmount > rewardsToken2.remainingAmount) rewardsAmount = rewardsToken2.remainingAmount;
            accRewardsToken2PerShare_ = accRewardsToken2PerShare_.add(rewardsAmount.mul(1e18).div(totalDepositAmount));
        }
        pending1 = (user.totalDepositAmount.mul(accRewardsToken1PerShare_).div(1e18).sub(user.rewardDebtToken1)).add(user.pendingRewardsToken1);
        pending2 = (user.totalDepositAmount.mul(accRewardsToken2PerShare_).div(1e18).sub(user.rewardDebtToken2)).add(user.pendingRewardsToken2);
    }


    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    modifier isValidNFTPool(address sender) {
        require(sender == address(nftPool), "invalid NFTPool");
        _;
    }


    /*****************************************************************/
    /******************  EXTERNAL PUBLIC FUNCTIONS  ******************/
    /*****************************************************************/

    /**
     * @dev Update this NitroPool
     */
    function updatePool() external nonReentrant {
        _updatePool();
    }

    /**
     * @dev Automatically stakes transferred positions from a NFTPool
     */
    function onERC721Received(address /*operator*/, address from, uint256 tokenId, bytes calldata /*data*/) external override nonReentrant isValidNFTPool(msg.sender) returns (bytes4) {
        require(published, "not published");
        require(!settings.whitelist || _whitelistedUsers.contains(from), "not whitelisted");

        // save tokenId previous owner
        _userTokenIds[from].add(tokenId);
        tokenIdOwner[tokenId] = from;

        (uint256 amount,uint256 startLockTime, uint256 lockDuration) = _getStackingPosition(tokenId);
        _checkPositionRequirements(amount, startLockTime, lockDuration);

        _deposit(from, tokenId, amount);

        // allow depositor to interact with the staked position later
        nftPool.approve(from, tokenId);
        return _ERC721_RECEIVED;
    }

    /**
     * @dev Withdraw a position from the NitroPool
     *
     * Can only be called by the position's previous owner
     */
    function withdraw(uint256 tokenId) external virtual nonReentrant {
        require(msg.sender == tokenIdOwner[tokenId], "not allowed");

        (uint256 amount,,) = _getStackingPosition(tokenId);

        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        _harvest(user, msg.sender);

        user.totalDepositAmount = user.totalDepositAmount.sub(amount);
        totalDepositAmount = totalDepositAmount.sub(amount);

        _updateRewardDebt(user);

        // remove from previous owners info
        _userTokenIds[msg.sender].remove(tokenId);
        delete tokenIdOwner[tokenId];

        nftPool.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(msg.sender, tokenId, amount);
    }

    /**
     * @dev Withdraw a position from the NitroPool without caring about rewards, EMERGENCY ONLY
     *
     * Can only be called by position's previous owner
     */
    function emergencyWithdraw(uint256 tokenId) external virtual nonReentrant {
        require(msg.sender == tokenIdOwner[tokenId], "not allowed");

        (uint256 amount,,) = _getStackingPosition(tokenId);
        UserInfo storage user = userInfo[msg.sender];
        user.totalDepositAmount = user.totalDepositAmount.sub(amount);
        totalDepositAmount = totalDepositAmount.sub(amount);

        _updateRewardDebt(user);

        // remove from previous owners info
        _userTokenIds[msg.sender].remove(tokenId);
        delete tokenIdOwner[tokenId];

        nftPool.safeTransferFrom(address(this), msg.sender, tokenId);

        emit EmergencyWithdraw(msg.sender, tokenId, amount);
    }

    /**
     * @dev Harvest pending NitroPool rewards
     */
    function harvest() external nonReentrant {
        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        _harvest(user, msg.sender);
        _updateRewardDebt(user);
    }

    /**
     * @dev Allow stacked positions to be harvested
     *
     * "to" can be set to token's previous owner
     * "to" can be set to this address only if this contract is allowed to transfer xGRAIL
     */
    function onNFTHarvest(address operator, address to, uint256 tokenId, uint256 grailAmount, uint256 xGrailAmount) external override isValidNFTPool(msg.sender) returns (bool) {
        address owner = tokenIdOwner[tokenId];
        require(operator == owner, "not allowed");

        // if not whitelisted, the NitroPool can't transfer any xGRAIL rewards
        require(to != address(this) || xGrailToken.isTransferWhitelisted(address(this)), "cant handle rewards");

        // redirect rewards to position's previous owner
        if (to == address(this)) {
            grailToken.safeTransfer(owner, grailAmount);
            xGrailToken.safeTransfer(owner, xGrailAmount);
        }

        return true;
    }

    /**
     * @dev Allow position's previous owner to add more assets to his position
     */
    function onNFTAddToPosition(address operator, uint256 tokenId, uint256 amount) external override nonReentrant isValidNFTPool(msg.sender) returns (bool) {
        require(operator == tokenIdOwner[tokenId], "not allowed");
        _deposit(operator, tokenId, amount);
        return true;
    }

    /**
     * @dev Disallow withdraw assets from a stacked position
     */
    function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*amount*/) external pure override returns (bool){
        return false;
    }


    /*****************************************************************/
    /****************** EXTERNAL OWNABLE FUNCTIONS  ******************/
    /*****************************************************************/

    /**
     * @dev Transfer ownership of this NitroPool
     *
     * Must only be called by the owner of this contract
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _setNitroPoolOwner(newOwner);
        Ownable.transferOwnership(newOwner);
    }

    /**
     * @dev Transfer ownership of this NitroPool
     *
     * Must only be called by the owner of this contract
     */
    function renounceOwnership() public override onlyOwner {
        _setNitroPoolOwner(address(0));
        Ownable.renounceOwnership();
    }

    /**
     * @dev Add rewards to this NitroPool
     */
    function addRewards(uint256 amountToken1, uint256 amountToken2) external nonReentrant {
        require(_currentBlockTimestamp() < settings.endTime, "pool ended");
        _updatePool();

        // get active fee share for this NitroPool
        uint256 feeShare = factory.getNitroPoolFee(address(this), owner());
        address feeAddress = factory.feeAddress();
        uint256 feeAmount;

        if (amountToken1 > 0) {
            // token1 fee
            feeAmount = amountToken1.mul(feeShare).div(10000);
            amountToken1 = _transferSupportingFeeOnTransfer(rewardsToken1.token, msg.sender, amountToken1.sub(feeAmount));

            // recomputes rewards to distribute
            rewardsToken1.amount = rewardsToken1.amount.add(amountToken1);
            rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.add(amountToken1);

            emit AddRewardsToken1(amountToken1, feeAmount);

            if (feeAmount > 0) {
                rewardsToken1.token.safeTransferFrom(msg.sender, feeAddress, feeAmount);
            }
        }

        if (amountToken2 > 0) {
            require(address(rewardsToken2.token) != address(0), "rewardsToken2");

            // token2 fee
            feeAmount = amountToken2.mul(feeShare).div(10000);
            amountToken2 = _transferSupportingFeeOnTransfer(rewardsToken2.token, msg.sender, amountToken2.sub(feeAmount));

            // recomputes rewards to distribute
            rewardsToken2.amount = rewardsToken2.amount.add(amountToken2);
            rewardsToken2.remainingAmount = rewardsToken2.remainingAmount.add(amountToken2);

            emit AddRewardsToken2(amountToken2, feeAmount);

            if (feeAmount > 0) {
                rewardsToken2.token.safeTransferFrom(msg.sender, feeAddress, feeAmount);
            }
        }
    }

    /**
     * @dev Withdraw rewards from this NitroPool
     *
     * Must only be called by the owner
     * Must only be called before the publication of the Nitro Pool
     */
    function withdrawRewards(uint256 amountToken1, uint256 amountToken2) external onlyOwner nonReentrant {
        require(!published, "published");

        if (amountToken1 > 0) {
            // recomputes rewards to distribute
            rewardsToken1.amount = rewardsToken1.amount.sub(amountToken1, "too high");
            rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.sub(amountToken1, "too high");

            emit WithdrawRewardsToken1(amountToken1, rewardsToken1.amount);
            _safeRewardsTransfer(rewardsToken1.token, msg.sender, amountToken1);
        }

        if (amountToken2 > 0 && address(rewardsToken2.token) != address(0)) {
            // recomputes rewards to distribute
            rewardsToken2.amount = rewardsToken2.amount.sub(amountToken2, "too high");
            rewardsToken2.remainingAmount = rewardsToken2.remainingAmount.sub(amountToken2, "too high");

            emit WithdrawRewardsToken2(amountToken2, rewardsToken2.amount);
            _safeRewardsTransfer(rewardsToken2.token, msg.sender, amountToken2);
        }
    }

    /**
     * @dev Set the rewardsToken2
     *
     * Must only be called by the owner
     * Must only be initialized once
     */
    function setRewardsToken2(IERC20 rewardsToken2_) external onlyOwner nonReentrant {
        require(!published, "published");
        require(address(rewardsToken2.token) == address(0), "already set");
        require(rewardsToken1.token != rewardsToken2_, "invalid");
        rewardsToken2.token = rewardsToken2_;

        emit SetRewardsToken2(rewardsToken2_);
    }

    /**
     * @dev Set an external custom requirement contract
     */
    function setCustomReqContract(address contractAddress) external onlyOwner {
        // Allow to disable customReq event if pool is published
        require(!published || contractAddress == address(0), "published");
        customReqContract = INitroCustomReq(contractAddress);

        emit SetCustomReqContract(contractAddress);
    }

    /**
     * @dev Set requirements that positions must meet to be staked on this Nitro Pool
     *
     * Must only be called by the owner
     */
    function setRequirements(uint256 lockDurationReq_, uint256 lockEndReq_, uint256 depositAmountReq_, bool whitelist_) external onlyOwner {
        _setRequirements(lockDurationReq_, lockEndReq_, depositAmountReq_, whitelist_);
    }

    /**
     * @dev Set the pool's datetime settings
     *
     * Must only be called by the owner
     * Nitro duration can only be extended once already published
     * Harvest start time can only be updated if not published
     * Deposit end time can only be updated if not been published
     */
    function setDateSettings(uint256 endTime_, uint256 harvestStartTime_, uint256 depositEndTime_) external nonReentrant onlyOwner {
        require(settings.startTime < endTime_, "invalid endTime");
        require(_currentBlockTimestamp() <= settings.endTime, "pool ended");
        require(depositEndTime_ == 0 || settings.startTime <= depositEndTime_, "invalid depositEndTime");
        require(harvestStartTime_ == 0 || settings.startTime <= harvestStartTime_, "invalid harvestStartTime");

        if (published) {
            // can only be extended
            require(settings.endTime <= endTime_, "not allowed endTime");
            // can't be updated
            require(settings.depositEndTime == depositEndTime_, "not allowed depositEndTime");
            // can't be updated
            require(settings.harvestStartTime == harvestStartTime_, "not allowed harvestStartTime");
        }

        settings.endTime = endTime_;
        // updated only when not published
        if (harvestStartTime_ == 0) settings.harvestStartTime = settings.startTime;
        else settings.harvestStartTime = harvestStartTime_;
        settings.depositEndTime = depositEndTime_;

        emit SetDateSettings(endTime_, harvestStartTime_, depositEndTime_);
    }

    /**
     * @dev Set pool's description
     *
     * Must only be called by the owner
     */
    function setDescription(string calldata description) external onlyOwner {
        settings.description = description;
        emit SetDescription(description);
    }

    /**
     * @dev Set whitelisted users
     *
     * Must only be called by the owner
     */
    function setWhitelist(WhitelistStatus[] calldata whitelistStatuses) external virtual onlyOwner {
        uint256 whitelistStatusesLength = whitelistStatuses.length;
        require(whitelistStatusesLength > 0, "empty");

        for (uint256 i; i < whitelistStatusesLength; ++i) {
            if (whitelistStatuses[i].status) _whitelistedUsers.add(whitelistStatuses[i].account);
            else _whitelistedUsers.remove(whitelistStatuses[i].account);
        }

        emit WhitelistUpdated();
    }

    /**
     * @dev Fully reset the current whitelist
     *
     * Must only be called by the owner
     */
    function resetWhitelist() external onlyOwner {
        uint256 i = _whitelistedUsers.length();
        for (i; i > 0; --i) {
            _whitelistedUsers.remove(_whitelistedUsers.at(i - 1));
        }

        emit WhitelistUpdated();
    }

    /**
     * @dev Publish the Nitro Pool
     *
     * Must only be called by the owner
     */
    function publish() external onlyOwner {
        require(!published, "published");
        // this nitroPool is Stale
        require(settings.startTime > _currentBlockTimestamp(), "stale");
        require(rewardsToken1.amount > 0, "no rewards");

        published = true;
        publishTime = _currentBlockTimestamp();
        factory.publishNitroPool(address(nftPool));

        emit Publish();
    }

    /**
     * @dev Emergency close
     *
     * Must only be called by the owner
     * Emergency only: if used, the whole pool is definitely made void
     * All rewards are automatically transferred to the emergency recovery address
     */
    function activateEmergencyClose() external nonReentrant onlyOwner {
        address emergencyRecoveryAddress = factory.emergencyRecoveryAddress();

        uint256 remainingToken1 = rewardsToken1.remainingAmount;
        uint256 remainingToken2 = rewardsToken2.remainingAmount;

        rewardsToken1.amount = rewardsToken1.amount.sub(remainingToken1);
        rewardsToken1.remainingAmount = 0;

        rewardsToken2.amount = rewardsToken2.amount.sub(remainingToken2);
        rewardsToken2.remainingAmount = 0;
        emergencyClose = true;

        emit ActivateEmergencyClose();
        // transfer rewardsToken1 remaining amount if any
        _safeRewardsTransfer(rewardsToken1.token, emergencyRecoveryAddress, remainingToken1);
        // transfer rewardsToken2 remaining amount if any
        _safeRewardsTransfer(rewardsToken2.token, emergencyRecoveryAddress, remainingToken2);
    }


    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    /**
     * @dev Set requirements that positions must meet to be staked on this Nitro Pool
     */
    function _setRequirements(uint256 lockDurationReq_, uint256 lockEndReq_, uint256 depositAmountReq_, bool whitelist_) internal {
        require(lockEndReq_ == 0 || settings.startTime < lockEndReq_, "invalid lockEnd");

        if (published) {
            // Can't decrease requirements if already published
            require(lockDurationReq_ >= settings.lockDurationReq, "invalid lockDuration");
            require(lockEndReq_ >= settings.lockEndReq, "invalid lockEnd");
            require(depositAmountReq_ >= settings.depositAmountReq, "invalid depositAmount");
            require(!settings.whitelist || settings.whitelist == whitelist_, "invalid whitelist");
        }

        settings.lockDurationReq = lockDurationReq_;
        settings.lockEndReq = lockEndReq_;
        settings.depositAmountReq = depositAmountReq_;
        settings.whitelist = whitelist_;

        emit SetRequirements(lockDurationReq_, lockEndReq_, depositAmountReq_, whitelist_);
    }

    /**
     * @dev Updates rewards states of this Nitro Pool to be up-to-date
     */
    function _updatePool() internal {
        uint256 currentBlockTimestamp = _currentBlockTimestamp();

        if (currentBlockTimestamp <= lastRewardTime) return;

        // do nothing if there is no deposit
        if (totalDepositAmount == 0) {
            lastRewardTime = currentBlockTimestamp;
            emit UpdatePool();
            return;
        }

        // updates rewardsToken1 state
        uint256 rewardsAmount = rewardsToken1PerSecond().mul(currentBlockTimestamp.sub(lastRewardTime));
        // ensure we do not distribute more than what's available
        if (rewardsAmount > rewardsToken1.remainingAmount) rewardsAmount = rewardsToken1.remainingAmount;
        rewardsToken1.remainingAmount = rewardsToken1.remainingAmount.sub(rewardsAmount);
        rewardsToken1.accRewardsPerShare = rewardsToken1.accRewardsPerShare.add(rewardsAmount.mul(1e18).div(totalDepositAmount));

        // if rewardsToken2 is activated
        if (address(rewardsToken2.token) != address(0)) {
            // updates rewardsToken2 state
            rewardsAmount = rewardsToken2PerSecond().mul(currentBlockTimestamp.sub(lastRewardTime));
            // ensure we do not distribute more than what's available
            if (rewardsAmount > rewardsToken2.remainingAmount) rewardsAmount = rewardsToken2.remainingAmount;
            rewardsToken2.remainingAmount = rewardsToken2.remainingAmount.sub(rewardsAmount);
            rewardsToken2.accRewardsPerShare = rewardsToken2.accRewardsPerShare.add(rewardsAmount.mul(1e18).div(totalDepositAmount));
        }

        lastRewardTime = currentBlockTimestamp;
        emit UpdatePool();
    }

    /**
     * @dev Add a user's deposited amount into this Nitro Pool
     */
    function _deposit(address account, uint256 tokenId, uint256 amount) internal {
        require((settings.depositEndTime == 0 || settings.depositEndTime >= _currentBlockTimestamp()) && !emergencyClose, "not allowed");

        if(address(customReqContract) != address(0)){
            require(customReqContract.canDeposit(account, tokenId), "invalid customReq");
        }

        _updatePool();

        UserInfo storage user = userInfo[account];
        _harvest(user, account);

        user.totalDepositAmount = user.totalDepositAmount.add(amount);
        totalDepositAmount = totalDepositAmount.add(amount);
        _updateRewardDebt(user);

        emit Deposit(account, tokenId, amount);
    }

    /**
     * @dev Transfer to a user its pending rewards
     */
    function _harvest(UserInfo storage user, address to) internal {
        bool canHarvest = true;
        if(address(customReqContract) != address(0)){
            canHarvest = customReqContract.canHarvest(to);
        }

        // rewardsToken1
        uint256 pending = user.totalDepositAmount.mul(rewardsToken1.accRewardsPerShare).div(1e18).sub(user.rewardDebtToken1);
        // check if harvest is allowed
        if (_currentBlockTimestamp() < settings.harvestStartTime || !canHarvest) {
            // if not allowed, add to rewards buffer
            user.pendingRewardsToken1 = user.pendingRewardsToken1.add(pending);
        } else {
            // if allowed, transfer rewards
            pending = pending.add(user.pendingRewardsToken1);
            user.pendingRewardsToken1 = 0;
            _safeRewardsTransfer(rewardsToken1.token, to, pending);

            emit Harvest(to, rewardsToken1.token, pending);
        }

        // rewardsToken2 (if initialized)
        if (address(rewardsToken2.token) != address(0)) {
            pending = user.totalDepositAmount.mul(rewardsToken2.accRewardsPerShare).div(1e18).sub(user.rewardDebtToken2);
            // check if harvest is allowed
            if (_currentBlockTimestamp() < settings.harvestStartTime || !canHarvest) {
                // if not allowed, add to rewards buffer
                user.pendingRewardsToken2 = user.pendingRewardsToken2.add(pending);
            } else {
                // if allowed, transfer rewards
                pending = pending.add(user.pendingRewardsToken2);
                user.pendingRewardsToken2 = 0;
                _safeRewardsTransfer(rewardsToken2.token, to, pending);

                emit Harvest(to, rewardsToken2.token, pending);
            }
        }
    }

    /**
     * @dev Update a user's rewardDebt for rewardsToken1 and rewardsToken2
     */
    function _updateRewardDebt(UserInfo storage user) internal virtual {
        (bool succeed, uint256 result) = user.totalDepositAmount.tryMul(rewardsToken1.accRewardsPerShare);
        if(succeed) user.rewardDebtToken1 = result.div(1e18);

        (succeed, result) = user.totalDepositAmount.tryMul(rewardsToken2.accRewardsPerShare);
        if(succeed) user.rewardDebtToken2 = result.div(1e18);
    }

    /**
     * @dev Check whether a position with "tokenId" ID is meeting all of this Nitro Pool's active requirements
     */
    function _checkPositionRequirements(uint256 amount, uint256 startLockTime, uint256 lockDuration) internal virtual {
        // lock duration requirement
        if (settings.lockDurationReq > 0) {
            // for unlocked position that have not been updated yet
            require(_currentBlockTimestamp() < startLockTime.add(lockDuration) && settings.lockDurationReq <= lockDuration, "invalid lockDuration");
        }

        // lock end time requirement
        if (settings.lockEndReq > 0) {
            require(settings.lockEndReq <= startLockTime.add(lockDuration), "invalid lockEnd");
        }

        // deposit amount requirement
        if (settings.depositAmountReq > 0) {
            require(settings.depositAmountReq <= amount, "invalid amount");
        }
    }

    /**
  * @dev Handle deposits of tokens with transfer tax
  */
    function _transferSupportingFeeOnTransfer(IERC20 token, address user, uint256 amount) internal returns (uint256 receivedAmount) {
        uint256 previousBalance = token.balanceOf(address(this));
        token.safeTransferFrom(user, address(this), amount);
        return token.balanceOf(address(this)).sub(previousBalance);
    }


    /**
     * @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
     */
    function _safeRewardsTransfer(IERC20 token, address to, uint256 amount) internal virtual {
        if(amount == 0) return;

        uint256 balance = token.balanceOf(address(this));
        // cap to available balance
        if (amount > balance) {
            amount = balance;
        }
        token.safeTransfer(to, amount);
    }


    function _getStackingPosition(uint256 tokenId) internal view returns (uint256 amount, uint256 startLockTime, uint256 lockDuration) {
        (amount,, startLockTime, lockDuration,,,,) = nftPool.getStakingPosition(tokenId);
    }

    function _setNitroPoolOwner(address newOwner) internal {
        factory.setNitroPoolOwner(owner(), newOwner);
    }

    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXGrailToken is IERC20 {
  function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);

  function allocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;

  function isTransferWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGrailTokenV2 is IERC20{
  function lastEmissionTime() external view returns (uint256);

  function claimMasterRewards(uint256 amount) external returns (uint256 effectiveAmount);
  function masterEmissionRate() external view returns (uint256);
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface INitroPoolFactory {
  function emergencyRecoveryAddress() external view returns (address);
  function feeAddress() external view returns (address);
  function getNitroPoolFee(address nitroPoolAddress, address ownerAddress) external view returns (uint256);
  function publishNitroPool(address nftAddress) external;
  function setNitroPoolOwner(address previousOwner, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface INitroCustomReq {
    function canDepositDescription() external view returns (string calldata);
    function canHarvestDescription() external view returns (string calldata);

    function canDeposit(address user, uint256 tokenId) external view returns (bool);
    function canHarvest(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTPool is IERC721 {
  function exists(uint256 tokenId) external view returns (bool);
  function hasDeposits() external view returns (bool);
  function getPoolInfo() external view returns (
    address lpToken, address grailToken, address sbtToken, uint256 lastRewardTime, uint256 accRewardsPerShare,
    uint256 lpSupply, uint256 lpSupplyWithMultiplier, uint256 allocPoint
  );
  function getStakingPosition(uint256 tokenId) external view returns (
    uint256 amount, uint256 amountWithMultiplier, uint256 startLockTime,
    uint256 lockDuration, uint256 lockMultiplier, uint256 rewardDebt,
    uint256 boostPoints, uint256 totalMultiplier
  );

  function boost(uint256 userAddress, uint256 amount) external;
  function unboost(uint256 userAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INFTHandler is IERC721Receiver {
  function onNFTHarvest(address operator, address to, uint256 tokenId, uint256 grailAmount, uint256 xGrailAmount) external returns (bool);
  function onNFTAddToPosition(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);
  function onNFTWithdraw(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}