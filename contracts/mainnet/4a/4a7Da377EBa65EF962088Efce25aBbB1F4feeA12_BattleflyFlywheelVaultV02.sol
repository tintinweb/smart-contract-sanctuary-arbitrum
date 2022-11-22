// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./BattleflyFounderVaultV08.sol";
import "./interfaces/IBattleflyAtlasStakerV02.sol";
import "./interfaces/IBattleflyFlywheelVaultV02.sol";
import "./interfaces/IAtlasMine.sol";

contract BattleflyFlywheelVaultV02 is
    IBattleflyFlywheelVaultV02,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @dev Immutable states
     */
    IERC20Upgradeable public MAGIC;
    IBattleflyAtlasStakerV02 public ATLAS_STAKER;

    string public name;

    /**
     * @dev User stake data
     *      { depositId } => { User stake data }
     */
    mapping(uint256 => UserStake) public userStakes;

    /**
     * @dev User's depositIds
     *      { user } => { depositIds }
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) private depositIdByUser;

    /**
     * @dev Whitelisted users
     *      { user } => { is whitelisted }
     */
    mapping(address => bool) public whitelistedUsers;

    // ========== CONTRACT UPGRADE FOR GFLY DYNAMICS ======= //

    IFlywheelEmissions public FLYWHEEL_EMISSIONS;

    function initialize(address _atlasStaker, string memory _name) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        require(_atlasStaker != address(0), "BattleflyFlywheelVault: invalid address");
        require(bytes(_name).length > 0, "BattleflyFlywheelVault: invalid name");

        ATLAS_STAKER = IBattleflyAtlasStakerV02(_atlasStaker);
        MAGIC = ATLAS_STAKER.MAGIC();

        name = _name;
    }

    /**
     * @dev Deposit funds to AtlasStaker
     */
    function deposit(uint128 _amount, IAtlasMine.Lock _lock)
        external
        override
        nonReentrant
        onlyMembers
        returns (uint256 atlasStakerDepositId)
    {
        MAGIC.safeTransferFrom(msg.sender, address(this), _amount);
        MAGIC.safeApprove(address(ATLAS_STAKER), _amount);

        atlasStakerDepositId = ATLAS_STAKER.deposit(uint256(_amount), _lock);
        IBattleflyAtlasStakerV02.VaultStake memory vaultStake = ATLAS_STAKER.getVaultStake(atlasStakerDepositId);

        UserStake storage userStake = userStakes[atlasStakerDepositId];
        userStake.amount = _amount;
        userStake.lockAt = vaultStake.lockAt;
        userStake.owner = msg.sender;
        userStake.lock = _lock;

        depositIdByUser[msg.sender].add(atlasStakerDepositId);

        emit NewUserStake(atlasStakerDepositId, _amount, vaultStake.unlockAt, msg.sender, _lock);
    }

    /**
     * @dev Withdraw staked funds from AtlasStaker
     */
    function withdraw(uint256[] calldata _depositIds) public override nonReentrant returns (uint256 amount) {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            amount += _withdraw(_depositIds[i]);
        }
    }

    /**
     * @dev Withdraw all from AtlasStaker. This is only possible when the retention period of 14 epochs has passed.
     * The retention period is started when a withdrawal for the stake is requested.
     */
    function withdrawAll() public override nonReentrant returns (uint256 amount) {
        uint256[] memory depositIds = depositIdByUser[msg.sender].values();
        require(depositIds.length > 0, "BattleflyFlywheelVault: No deposited funds");
        for (uint256 i = 0; i < depositIds.length; i++) {
            if (ATLAS_STAKER.canWithdraw(depositIds[i])) {
                amount += _withdraw(depositIds[i]);
            }
        }
    }

    /**
     * @dev Request a withdrawal from AtlasStaker. This works with a retention period of 14 epochs.
     * Once the retention period has passed, the stake can be withdrawn.
     */
    function requestWithdrawal(uint256[] calldata _depositIds) public override {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            UserStake memory userStake = userStakes[_depositIds[i]];
            require(userStake.owner == msg.sender, "BattleflyFlywheelVault: caller is not the owner");
            ATLAS_STAKER.requestWithdrawal(_depositIds[i]);
            emit RequestWithdrawal(_depositIds[i]);
        }
    }

    /**
     * @dev Claim emission from AtlasStaker
     */
    function claim(uint256 _depositId) public override nonReentrant returns (uint256 emission) {
        emission = _claim(_depositId);
    }

    /**
     * @dev Claim all emissions from AtlasStaker
     */
    function claimAll() external override nonReentrant returns (uint256 amount) {
        uint256[] memory depositIds = depositIdByUser[msg.sender].values();
        require(depositIds.length > 0, "BattleflyFlywheelVault: No deposited funds");

        for (uint256 i = 0; i < depositIds.length; i++) {
            amount += _claim(depositIds[i]);
        }
    }

    /**
     * @dev Claim all emissions from new Flywheel emissions contract
     */
    function claimAllFlywheel(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) external override nonReentrant onlyOwner returns (uint256 amount) {
        uint256 beforeClaim = MAGIC.balanceOf(address(this));
        FLYWHEEL_EMISSIONS.claim(
            index,
            epoch,
            cumulativeFlywheelAmount,
            cumulativeHarvesterAmount,
            flywheelClaimableAtEpoch,
            harvesterClaimableAtEpoch,
            individualMiningPower,
            totalMiningPower,
            merkleProof
        );
        uint256 afterClaim = MAGIC.balanceOf(address(this));
        amount = afterClaim - beforeClaim;
        MAGIC.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Whitelist user
     */
    function whitelistUser(address _who) public onlyOwner {
        require(!whitelistedUsers[_who], "BattlefalyWheelVault: Already whitelisted");
        whitelistedUsers[_who] = true;
        emit AddedUser(_who);
    }

    /**
     * @dev Whitelist users
     */
    function whitelistUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistUser(_users[i]);
        }
    }

    /**
     * @dev Remove user from whitelist
     */
    function removeUser(address _who) public onlyOwner {
        require(whitelistedUsers[_who], "BattlefalyWheelVault: Not whitelisted yet");
        whitelistedUsers[_who] = false;
        emit RemovedUser(_who);
    }

    /**
     * @dev Remove users from whitelist
     */
    function removeUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            removeUser(_users[i]);
        }
    }

    /**
     * @dev Set the name of the vault
     */
    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    /**
     * @dev Set the flywheel emissions contract
     */
    function setFlywheelEmissions(address flywheelEmissions) external onlyOwner {
        require(flywheelEmissions != address(0));
        FLYWHEEL_EMISSIONS = IFlywheelEmissions(flywheelEmissions);
    }

    // ================ INTERNAL ================

    /**
     * @dev Withdraw a stake from AtlasStaker (Only possible when the retention period has passed)
     */
    function _withdraw(uint256 _depositId) internal returns (uint256 amount) {
        UserStake memory userStake = userStakes[_depositId];
        require(userStake.owner == msg.sender, "BattleflyFlywheelVault: caller is not the owner");
        require(ATLAS_STAKER.canWithdraw(_depositId), "BattleflyFlywheelVault: stake not yet unlocked");

        amount = ATLAS_STAKER.withdraw(_depositId);
        MAGIC.safeTransfer(msg.sender, amount);
        depositIdByUser[msg.sender].remove(_depositId);
        delete userStakes[_depositId];
        emit WithdrawPosition(_depositId, amount);
    }

    /**
     * @dev Claim emission from AtlasStaker
     */
    function _claim(uint256 _depositId) internal returns (uint256 emission) {
        UserStake memory userStake = userStakes[_depositId];
        require(userStake.owner == msg.sender, "BattleflyFlywheelVault: caller is not the owner");

        emission = ATLAS_STAKER.claim(_depositId);
        MAGIC.safeTransfer(msg.sender, emission);
        emit ClaimEmission(_depositId, emission);
    }

    // ================== VIEW ==================

    /**
     * @dev Get allowed lock periods from AtlasStaker
     */
    function getAllowedLocks() public view override returns (IAtlasMine.Lock[] memory) {
        return ATLAS_STAKER.getAllowedLocks();
    }

    /**
     * @dev Get claimed emission
     */
    function getClaimableEmission(uint256 _depositId) public view override returns (uint256 emission) {
        (emission, ) = ATLAS_STAKER.getClaimableEmission(_depositId);
    }

    /**
     * @dev Check if a vaultStake is eligible for requesting a withdrawal.
     * This is 14 epochs before the end of the initial lock period.
     */
    function canRequestWithdrawal(uint256 _depositId) public view override returns (bool requestable) {
        return ATLAS_STAKER.canRequestWithdrawal(_depositId);
    }

    /**
     * @dev Check if a vaultStake is eligible for a withdrawal
     * This is when the retention period has passed
     */
    function canWithdraw(uint256 _depositId) public view override returns (bool withdrawable) {
        return ATLAS_STAKER.canWithdraw(_depositId);
    }

    /**
     * @dev Check the epoch in which the initial lock period of the vaultStake expires.
     * This is at the end of the lock period
     */
    function initialUnlock(uint256 _depositId) public view override returns (uint64 epoch) {
        return ATLAS_STAKER.getVaultStake(_depositId).unlockAt;
    }

    /**
     * @dev Check the epoch in which the retention period of the vaultStake expires.
     * This is 14 epochs after the withdrawal request has taken place
     */
    function retentionUnlock(uint256 _depositId) public view override returns (uint64 epoch) {
        return ATLAS_STAKER.getVaultStake(_depositId).retentionUnlock;
    }

    /**
     * @dev Get the currently active epoch
     */
    function getCurrentEpoch() public view override returns (uint64 epoch) {
        return ATLAS_STAKER.currentEpoch();
    }

    /**
     * @dev Get the depositIds of a user
     */
    function depositIdsOfUser(address user) public view override returns (uint256[] memory depositIds) {
        return depositIdByUser[user].values();
    }

    /**
     * @dev Return the name of the vault
     */
    function getName() public view override returns (string memory) {
        return name;
    }

    // ================== MODIFIERS ==================

    modifier onlyMembers() {
        require(whitelistedUsers[msg.sender], "BattleflyWheelVault: caller is not a whitelisted member");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBattleflyAtlasStaker.sol";
import "./interfaces/IBattleflyAtlasStakerV02.sol";
import "./interfaces/IAtlasMine.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IBattleflyFounderVault.sol";
import "./interfaces/IBattleflyFlywheelVault.sol";
import "./interfaces/vaults/IBattleflyFoundersFlywheelVault.sol";
import "./interfaces/vaults/IBattleflyTreasuryFlywheelVault.sol";
import "./interfaces/IBattleflyHarvesterEmissions.sol";
import "./interfaces/IFlywheelEmissions.sol";
import "./interfaces/gFly/IGFly.sol";
import "./interfaces/gFly/IGFlyStaking.sol";

contract BattleflyFounderVaultV08 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ============================================ STATE ==============================================
    struct FounderStake {
        uint256 amount;
        uint256 stakeTimestamp;
        address owner;
        uint256 lastClaimedDay;
    }
    struct DailyFounderEmission {
        uint256 totalEmission;
        uint256 totalFounders;
    }
    // ============= Global Immutable State ==============

    /// @notice MAGIC token
    /// @dev functionally immutable
    IERC20Upgradeable public magic;
    ISpecialNFT public founderNFT;
    uint256 public founderTypeID;
    // ---- !!! Not Used Anymore !!! ----
    IBattleflyAtlasStaker public BattleflyStaker;
    uint256 public startTimestamp;
    // ============= Global mutable State ==============
    uint256 totalEmission;
    uint256 claimedEmission;
    uint256 pendingFounderEmission;

    mapping(address => EnumerableSetUpgradeable.UintSet) private FounderStakeOfOwner;
    uint256 lastStakeTimestamp;
    mapping(uint256 => FounderStake) public FounderStakes;
    uint256 lastStakeId;
    mapping(address => bool) private adminAccess;
    uint256 public DaysSinceStart;
    mapping(uint256 => DailyFounderEmission) public DailyFounderEmissions;

    uint256 withdrawnOldFounder;
    uint256 unupdatedStakeIdFrom;

    uint256 public stakeBackPercent;
    uint256 public treasuryPercent;
    uint256 public v2VaultPercent;

    IBattleflyFounderVault battleflyFounderVaultV2;
    // ---- !!! Not Used Anymore !!! ----
    IBattleflyFlywheelVault battleflyFlywheelVault;
    // ============= Constant ==============
    address public constant TREASURY_WALLET = 0xF5411006eEfD66c213d2fd2033a1d340458B7226;
    uint256 public constant PERCENT_DENOMINATOR = 10000;
    IAtlasMine.Lock public constant DEFAULT_STAKE_BACK_LOCK = IAtlasMine.Lock.twoWeeks;

    mapping(uint256 => bool) public claimedPastEmission;
    uint256 public pastEmissionPerFounder;
    mapping(uint256 => uint256) public stakeIdOfFounder;
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) stakingFounderOfStakeId;

    // ============================================ EVENTS ==============================================
    event ClaimDailyEmission(
        uint256 dayTotalEmission,
        uint256 totalFounderEmission,
        uint256 totalFounders,
        uint256 stakeBackAmount,
        uint256 treasuryAmount,
        uint256 v2VaultAmount
    );
    event Claim(address user, uint256 stakeId, uint256 amount);
    event Withdraw(address user, uint256 stakeId, uint256 founderId);
    event Stake(address user, uint256 stakeId, uint256[] founderNFTIDs);
    event TopupMagicToStaker(address user, uint256 amount, IAtlasMine.Lock lock);
    event TopupTodayEmission(address user, uint256 amount);
    event ClaimPastEmission(address user, uint256 amount, uint256[] tokenIds);

    // Upgrade Atlas Staker Start

    bool public claimingIsPaused;

    EnumerableSetUpgradeable.UintSet depositIds;
    // ---- !!! New Versions !!! ----
    IBattleflyAtlasStakerV02 public BattleflyStakerV2;
    IBattleflyFoundersFlywheelVault public BattleflyFoundersFlywheelVault;
    IBattleflyTreasuryFlywheelVault public TREASURY_VAULT;

    uint256 public activeDepositId;
    uint256 public activeRestakeDepositId;
    uint256 public pendingStakeBackAmount;
    address public BattleflyBot;

    event WithdrawalFromStaker(uint256 depositId);
    event RequestWithdrawalFromStaker(uint256 depositId);

    // Upgrade Atlas Staker End

    IBattleflyHarvesterEmissions public BattleflyHarvesterEmissions;

    address public OPEX;

    // Upgrade for gFly dynamics

    struct DailyFounderGFlyEmission {
        uint256 totalEmission;
        uint256 totalFounders;
    }

    IFlywheelEmissions public FLYWHEEL_EMISSIONS;
    IGFly public GFLY;
    IGFlyStaking public GFLY_STAKING;
    uint256 claimedGFlyEmission;
    uint256 totalGFlyEmission;
    mapping(uint256 => DailyFounderGFlyEmission) public DailyFounderGFlyEmissions;

    event ClaimGFly(address user, uint256 stakeId, uint256 amount);
    event TopupGFlyToStaker(address user, uint96 amount, uint16 lock);
    event ClaimDailyGFlyEmission(uint256 totalGFlyEmission, uint256 totalFounders);

    // ============================================ INITIALIZE ==============================================
  /*  function initialize(
        address _magicAddress,
        address _BattleflyStakerAddress,
        uint256 _founderTypeID,
        address _founderNFTAddress,
        uint256 _startTimestamp,
        address _battleflyFounderVaultV2Address,
        uint256 _stakeBackPercent,
        uint256 _treasuryPercent,
        uint256 _v2VaultPercent
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = IERC20Upgradeable(_magicAddress);
        BattleflyStaker = IBattleflyAtlasStaker(_BattleflyStakerAddress);
        founderNFT = (ISpecialNFT(_founderNFTAddress));
        founderTypeID = _founderTypeID;
        lastStakeTimestamp = block.timestamp;
        lastStakeId = 0;
        startTimestamp = _startTimestamp;
        DaysSinceStart = 0;
        stakeBackPercent = _stakeBackPercent;
        treasuryPercent = _treasuryPercent;
        v2VaultPercent = _v2VaultPercent;
        if (_battleflyFounderVaultV2Address == address(0))
            battleflyFounderVaultV2 = IBattleflyFounderVault(address(this));
        else battleflyFounderVaultV2 = IBattleflyFounderVault(_battleflyFounderVaultV2Address);

        require(stakeBackPercent + treasuryPercent + v2VaultPercent <= PERCENT_DENOMINATOR);

        // Approve the AtlasStaker contract to spend the magic
        magic.safeApprove(address(BattleflyStaker), 2**256 - 1);
    }*/

    // ============================================ USER OPERATIONS ==============================================

    /**
     * @dev Claim past emissions for all owned founders tokens
     */
    function claimPastEmission() external {
        require(pastEmissionPerFounder != 0, "No past founder emission to claim");
        uint256[] memory tokenIds = getPastEmissionClaimableTokens(msg.sender);
        require(tokenIds.length > 0, "No tokens to claim");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimedPastEmission[tokenIds[i]] = true;
        }
        magic.safeTransfer(msg.sender, pastEmissionPerFounder * tokenIds.length);
        emit ClaimPastEmission(msg.sender, pastEmissionPerFounder * tokenIds.length, tokenIds);
    }

    /**
     * @dev get all tokens eligible for cliaming past emissions
     */
    function getPastEmissionClaimableTokens(address user) public view returns (uint256[] memory) {
        uint256 balance = founderNFT.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 countClaimable = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = founderNFT.tokenOfOwnerByIndex(user, i);
            uint256 tokenType = founderNFT.getSpecialNFTType(tokenId);
            if (tokenType == founderTypeID && claimedPastEmission[tokenId] == false) {
                tokenIds[countClaimable] = tokenId;
                countClaimable++;
            }
        }
        (, uint256[][] memory stakeTokens) = stakesOf(user);
        uint256 countClaimableStaked = 0;
        uint256 balanceStaked = 0;
        for (uint256 i = 0; i < stakeTokens.length; i++) {
            balanceStaked += stakeTokens[i].length;
        }
        uint256[] memory stakingTokenIds = new uint256[](balanceStaked);
        for (uint256 i = 0; i < stakeTokens.length; i++) {
            uint256[] memory stakeTokenIds = stakeTokens[i];
            for (uint256 j = 0; j < stakeTokenIds.length; j++) {
                uint256 tokenId = stakeTokenIds[j];
                uint256 tokenType = founderNFT.getSpecialNFTType(tokenId);
                if (tokenType == founderTypeID && claimedPastEmission[tokenId] == false) {
                    stakingTokenIds[countClaimableStaked] = tokenId;
                    countClaimableStaked++;
                }
            }
        }

        uint256[] memory result = new uint256[](countClaimable + countClaimableStaked);
        for (uint256 i = 0; i < countClaimable; i++) {
            result[i] = tokenIds[i];
        }
        for (uint256 i = countClaimable; i < countClaimable + countClaimableStaked; i++) {
            result[i] = stakingTokenIds[i - countClaimable];
        }
        return result;
    }

    /**
     * @dev set founder tokens that can claim past emissions
     */
    function setTokenClaimedPastEmission(uint256[] memory tokenIds, bool isClaimed) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimedPastEmission[tokenIds[i]] = isClaimed;
        }
    }

    /**
     * @dev set the amount of past emissions per founder token
     */
    function setPastEmission(uint256 amount) external onlyOwner {
        pastEmissionPerFounder = amount;
    }

    /**
     * @dev returns the stake objects and the corresponding founder tokens in the stakes of a specific owner
     */
    function stakesOf(address owner) public view returns (FounderStake[] memory, uint256[][] memory) {
        FounderStake[] memory stakes = new FounderStake[](FounderStakeOfOwner[owner].length());
        uint256[][] memory _founderIDsOfStake = new uint256[][](FounderStakeOfOwner[owner].length());
        for (uint256 i = 0; i < FounderStakeOfOwner[owner].length(); i++) {
            stakes[i] = FounderStakes[FounderStakeOfOwner[owner].at(i)];
            _founderIDsOfStake[i] = stakingFounderOfStakeId[FounderStakeOfOwner[owner].at(i)].values();
        }
        return (stakes, _founderIDsOfStake);
    }

    function isOwner(address owner, uint256 tokenId) public view returns (bool) {
        (, uint256[][] memory tokensPerStake) = stakesOf(owner);
        for (uint256 i = 0; i < tokensPerStake.length; i++) {
            for (uint256 j = 0; j < tokensPerStake[i].length; j++) {
                if (tokensPerStake[i][j] == tokenId) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev Returns the founder tokens balance of an owner
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint256 balanceOfUser = 0;
        uint256 founderStakeCount = FounderStakeOfOwner[owner].length();

        for (uint256 i = 0; i < founderStakeCount; i++) {
            balanceOfUser += FounderStakes[FounderStakeOfOwner[owner].at(i)].amount;
        }

        return balanceOfUser;
    }

    /**
     * @dev Stake a list of founder tokens
     */
    function stakeFounderNFT(uint256[] memory ids) external {
        require(ids.length != 0, "Must provide at least one founder NFT ID");
        for (uint256 i = 0; i < ids.length; i++) {
            require(founderNFT.getSpecialNFTType(ids[i]) == founderTypeID, "Not valid founder NFT");
            founderNFT.safeTransferFrom(msg.sender, address(this), ids[i]);
        }
        uint256 currentDay = DaysSinceStart;
        lastStakeId++;
        FounderStakes[lastStakeId] = (
            FounderStake({
                amount: ids.length,
                stakeTimestamp: block.timestamp,
                owner: msg.sender,
                lastClaimedDay: currentDay
            })
        );
        for (uint256 i = 0; i < ids.length; i++) {
            stakeIdOfFounder[ids[i]] = lastStakeId;
            stakingFounderOfStakeId[lastStakeId].add(ids[i]);
        }
        FounderStakeOfOwner[msg.sender].add(lastStakeId);
        emit Stake(msg.sender, lastStakeId, ids);
    }

    /**
     * @dev Indicates if claiming is paused
     */
    function isPaused() external view returns (bool) {
        return claimingIsPaused;
    }

    /**
     * @dev Claim all emissions for the founder tokens owned by the sender
     */
    function claimAll() external nonReentrant {
        if (claimingIsPaused) {
            revert("Claiming is currently paused, please try again later");
        }

        uint256 totalReward = 0;
        uint256 totalRewardGFly = 0;

        for (uint256 i = 0; i < FounderStakeOfOwner[msg.sender].length(); i++) {
            totalReward += _claimByStakeId(FounderStakeOfOwner[msg.sender].at(i));
            totalRewardGFly += _claimGFlyByStakeId(FounderStakeOfOwner[msg.sender].at(i));
        }

        require(totalReward > 0 || totalRewardGFly > 0, "No reward to claim");
    }

    /**
     * @dev Withdraw all founder tokens of the sender
     */
    function withdrawAll() external nonReentrant {
        require(FounderStakeOfOwner[msg.sender].length() > 0, "No STAKE to withdraw");
        uint256 totalWithdraw = 0;
        uint256[] memory stakeIds = FounderStakeOfOwner[msg.sender].values();
        for (uint256 i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            _claimByStakeId(stakeId);
            _claimGFlyByStakeId(stakeId);
            totalWithdraw += FounderStakes[stakeId].amount;
            _withdrawByStakeId(stakeId);
        }
    }

    function _withdrawByStakeId(uint256 stakeId) internal {
        FounderStake storage stake = FounderStakes[stakeId];
        _claimByStakeId(stakeId);
        _claimGFlyByStakeId(stakeId);
        for (uint256 i = 0; i < stakingFounderOfStakeId[stakeId].length(); i++) {
            founderNFT.safeTransferFrom(address(this), stake.owner, stakingFounderOfStakeId[stakeId].at(i));
            emit Withdraw(stake.owner, stakeId, stakingFounderOfStakeId[stakeId].at(i));
        }
        if (stake.stakeTimestamp < (startTimestamp + (DaysSinceStart) * 24 hours - 24 hours)) {
            withdrawnOldFounder += stakingFounderOfStakeId[stakeId].length();
        }
        FounderStakeOfOwner[stake.owner].remove(stakeId);
        delete FounderStakes[stakeId];
        delete stakingFounderOfStakeId[stakeId];
    }

    function _claimByStakeId(uint256 stakeId) internal returns (uint256) {
        require(stakeId != 0, "No stake to claim");
        FounderStake storage stake = FounderStakes[stakeId];
        uint256 totalReward = _getClaimableEmissionOf(stakeId);
        claimedEmission += totalReward;
        //stake.lastClaimedDay = DaysSinceStart;
        magic.safeTransfer(stake.owner, totalReward);
        emit Claim(stake.owner, stakeId, totalReward);
        return totalReward;
    }

    function _claimGFlyByStakeId(uint256 stakeId) internal returns (uint256) {
        require(stakeId != 0, "No stake to claim");
        FounderStake storage stake = FounderStakes[stakeId];
        uint256 totalReward = _getClaimableGFlyEmissionOf(stakeId);
        claimedGFlyEmission += totalReward;
        stake.lastClaimedDay = DaysSinceStart;
        GFLY.transfer(stake.owner, totalReward);
        emit ClaimGFly(stake.owner, stakeId, totalReward);
        return totalReward;
    }

    /**
     * @dev Withdraw a list of founder tokens
     */
    function withdraw(uint256[] memory founderIds) external nonReentrant {
        require(founderIds.length > 0, "No Founder to withdraw");
        for (uint256 i = 0; i < founderIds.length; i++) {
            uint256 stakeId = stakeIdOfFounder[founderIds[i]];
            require(FounderStakes[stakeId].owner == msg.sender, "Not your stake");
            _claimBeforeWithdraw(founderIds[i]);
            _claimGFlyBeforeWithdraw(founderIds[i]);
            _withdraw(founderIds[i]);
        }
    }

    function _claimBeforeWithdraw(uint256 founderId) internal returns (uint256) {
        uint256 stakeId = stakeIdOfFounder[founderId];
        FounderStake storage stake = FounderStakes[stakeId];
        uint256 founderReward = _getClaimableEmissionOf(stakeId) / stake.amount;
        claimedEmission += founderReward;
        magic.safeTransfer(stake.owner, founderReward);
        emit Claim(stake.owner, stakeId, founderReward);
        return founderReward;
    }

    function _claimGFlyBeforeWithdraw(uint256 founderId) internal returns (uint256) {
        uint256 stakeId = stakeIdOfFounder[founderId];
        FounderStake storage stake = FounderStakes[stakeId];
        uint256 founderReward = _getClaimableGFlyEmissionOf(stakeId) / stake.amount;
        claimedGFlyEmission += founderReward;
        GFLY.transfer(stake.owner, founderReward);
        emit ClaimGFly(stake.owner, stakeId, founderReward);
        return founderReward;
    }

    /**
     * @dev Get the emissions claimable by a certain user
     */
    function getClaimableEmissionOf(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < FounderStakeOfOwner[user].length(); i++) {
            totalReward += _getClaimableEmissionOf(FounderStakeOfOwner[user].at(i));
        }
        return totalReward;
    }

    /**
     * @dev Get the gFly emissions claimable by a certain user
     */
    function getClaimableGFlyEmissionOf(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < FounderStakeOfOwner[user].length(); i++) {
            totalReward += _getClaimableGFlyEmissionOf(FounderStakeOfOwner[user].at(i));
        }
        return totalReward;
    }

    function _getClaimableEmissionOf(uint256 stakeId) internal view returns (uint256) {
        uint256 totalReward = 0;
        FounderStake memory stake = FounderStakes[stakeId];

        if (stake.lastClaimedDay == DaysSinceStart) return 0;

        for (uint256 j = stake.lastClaimedDay + 1; j <= DaysSinceStart; j++) {
            if (DailyFounderEmissions[j].totalFounders == 0 || stake.amount == 0) continue;
            totalReward +=
                (DailyFounderEmissions[j].totalEmission / DailyFounderEmissions[j].totalFounders) *
                stake.amount;
        }
        return totalReward;
    }

    function _getClaimableGFlyEmissionOf(uint256 stakeId) internal view returns (uint256) {
        uint256 totalReward = 0;
        FounderStake memory stake = FounderStakes[stakeId];

        if (stake.lastClaimedDay == DaysSinceStart) return 0;

        for (uint256 j = stake.lastClaimedDay + 1; j <= DaysSinceStart; j++) {
            if (DailyFounderGFlyEmissions[j].totalFounders == 0 || stake.amount == 0) continue;
            totalReward +=
                (DailyFounderGFlyEmissions[j].totalEmission / DailyFounderGFlyEmissions[j].totalFounders) *
                stake.amount;
        }
        return totalReward;
    }

    function _withdraw(uint256 founderId) internal {
        uint256 stakeId = stakeIdOfFounder[founderId];
        FounderStake storage stake = FounderStakes[stakeId];

        founderNFT.safeTransferFrom(address(this), stake.owner, founderId);

        stake.amount--;
        delete stakeIdOfFounder[founderId];
        stakingFounderOfStakeId[stakeId].remove(founderId);
        if (stake.stakeTimestamp < (startTimestamp + (DaysSinceStart) * 24 hours - 24 hours)) {
            withdrawnOldFounder += 1;
        }
        if (stake.amount == 0) {
            FounderStakeOfOwner[stake.owner].remove(stakeId);
            delete FounderStakes[stakeId];
        }
        emit Withdraw(stake.owner, stakeId, founderId);
    }

    function _depositToStaker(uint256 amount, IAtlasMine.Lock lock) internal returns (uint256 depositId) {
        depositId = BattleflyStakerV2.deposit(amount, lock);
        depositIds.add(depositId);
    }

    function _updateTotalStakingFounders(uint256 currentDay) private returns (uint256) {
        uint256 result = DailyFounderEmissions[DaysSinceStart].totalFounders - withdrawnOldFounder;
        withdrawnOldFounder = 0;
        uint256 to = startTimestamp + currentDay * 24 hours;
        uint256 i = unupdatedStakeIdFrom;
        for (; i <= lastStakeId; i++) {
            if (FounderStakes[i].stakeTimestamp == 0) {
                continue;
            }
            if (FounderStakes[i].stakeTimestamp > to) {
                break;
            }
            result += FounderStakes[i].amount;
        }
        unupdatedStakeIdFrom = i;
        return result;
    }

    function _claimAllFromStaker(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) private returns (uint256 amount) {
        if (BattleflyStakerV2.currentEpoch() <= BattleflyStakerV2.transitionEpoch()) {
            uint256[] memory ids = depositIds.values();
            for (uint256 i = 0; i < ids.length; i++) {
                (uint256 pending, ) = BattleflyStakerV2.getClaimableEmission(ids[i]);
                if (pending > 0) {
                    amount += BattleflyStakerV2.claim(ids[i]);
                }
            }
            amount += BattleflyHarvesterEmissions.claim(address(this));
        } else {
            uint256 beforeClaim = magic.balanceOf(address(this));
            FLYWHEEL_EMISSIONS.claim(
                index,
                epoch,
                cumulativeFlywheelAmount,
                cumulativeHarvesterAmount,
                flywheelClaimableAtEpoch,
                harvesterClaimableAtEpoch,
                individualMiningPower,
                totalMiningPower,
                merkleProof
            );
            uint256 afterClaim = magic.balanceOf(address(this));
            amount = amount + (afterClaim - beforeClaim);
        }
    }

    function _claimAllGFlyEmissions() private returns (uint256 amount) {
        if (BattleflyStakerV2.currentEpoch() > BattleflyStakerV2.transitionEpoch()) {
            uint256 beforeClaim = GFLY.balanceOf(address(this));
            GFLY_STAKING.claimAll();
            uint256 afterClaim = GFLY.balanceOf(address(this));
            amount = afterClaim - beforeClaim;
            GFLY_STAKING.extendLockPeriodOfAllStakes(365);
        }
    }

    function _stakeBack(uint256 stakeBackAmount) internal {
        pendingStakeBackAmount += stakeBackAmount;
        if (activeRestakeDepositId == 0 && pendingStakeBackAmount > 0) {
            activeRestakeDepositId = _depositToStaker(pendingStakeBackAmount, DEFAULT_STAKE_BACK_LOCK);
            pendingStakeBackAmount = 0;
        } else if (activeRestakeDepositId > 0 && BattleflyStakerV2.canWithdraw(activeRestakeDepositId)) {
            uint256 withdrawn = BattleflyStakerV2.withdraw(activeRestakeDepositId);
            depositIds.remove(activeRestakeDepositId);
            uint256 toDeposit = withdrawn + pendingStakeBackAmount;
            activeRestakeDepositId = _depositToStaker(toDeposit, DEFAULT_STAKE_BACK_LOCK);
            depositIds.add(activeRestakeDepositId);
            pendingStakeBackAmount = 0;
        } else if (activeRestakeDepositId > 0 && BattleflyStakerV2.canRequestWithdrawal(activeRestakeDepositId)) {
            BattleflyStakerV2.requestWithdrawal(activeRestakeDepositId);
        }
        pendingFounderEmission = 0;
    }

    /**
     * @dev Return the name of the vault
     */
    function getName() public view returns (string memory) {
        if (founderTypeID == 150) {
            return "V1 Stakers Vault";
        } else {
            return "V2 Stakers Vault";
        }
    }

    // ============================================ ADMIN OPERATIONS ==============================================

    /**
     * @dev Topup magic directly to the atlas staker
     */
    function topupMagicToStaker(uint256 amount, IAtlasMine.Lock lock) external onlyAdminAccess {
        require(amount > 0);
        magic.safeTransferFrom(msg.sender, address(this), amount);
        _depositToStaker(amount, lock);
        emit TopupMagicToStaker(msg.sender, amount, lock);
    }

    /**
     * @dev Topup gFly directly to the gFly Staking contract
     */
    function topupGFlyToStaker(uint96 amount, uint16 lock) external onlyAdminAccess {
        require(amount > 0);
        GFLY.transferFrom(msg.sender, address(this), amount);
        GFLY.approve(address(GFLY_STAKING),amount);
        GFLY_STAKING.stake(amount, lock);
        emit TopupGFlyToStaker(msg.sender, amount, lock);
    }

    /**
     * @dev Topup magic to be staked in the daily emission batch
     */
    function topupTodayEmission(uint256 amount) external onlyAdminAccess {
        require(amount > 0);
        magic.safeTransferFrom(msg.sender, address(this), amount);
        pendingFounderEmission += amount;
        emit TopupTodayEmission(msg.sender, amount);
    }

    // to support initial staking period, only to be run after staking period is over
    function setFounderStakesToStart() public onlyAdminAccess nonReentrant {
        uint256 length = lastStakeId;

        for (uint256 i = 0; i <= length; i++) {
            FounderStakes[i].stakeTimestamp = startTimestamp;
            FounderStakes[i].lastClaimedDay = 0;
        }
    }

    /**
     * @dev Update the claimed founder emission for a certain day
     */
    function updateClaimedFounderEmission(uint256 amount, uint256 currentDay) external onlyAdminAccess {
        DaysSinceStart = currentDay;
        uint256 todayTotalFounderNFTs = _updateTotalStakingFounders(currentDay);
        DailyFounderEmissions[DaysSinceStart] = DailyFounderEmission({
            totalEmission: amount,
            totalFounders: todayTotalFounderNFTs
        });
    }

    /**
     * @dev Get the current day
     */
    function getCurrentDay() public view onlyAdminAccess returns (uint256) {
        return DaysSinceStart;
    }

    /**
     * @dev Get the daily founder emission for a specific day
     */
    function getDailyFounderEmission(uint256 currentDay) public view onlyAdminAccess returns (uint256[2] memory) {
        return [DailyFounderEmissions[currentDay].totalEmission, DailyFounderEmissions[currentDay].totalFounders];
    }

    /**
     * @dev set the start timestamp
     */
    function setStartTimestamp(uint256 newTimestamp) public onlyAdminAccess {
        startTimestamp = newTimestamp;
    }

    /**
     * @dev Simulate a claim for a specific token id
     */
    function simulateClaim(uint256 tokenId) public view onlyAdminAccess returns (uint256) {
        uint256 stakeId = stakeIdOfFounder[tokenId];
        return _getClaimableEmissionOf(stakeId);
    }

    /**
     * @dev Pause or unpause claiming
     */
    function pauseClaim(bool doPause) external onlyAdminAccess {
        claimingIsPaused = doPause;
    }

    /**
     * @dev Reduce the total emission
     */
    function reduceTotalEmission(uint256 amount) external onlyAdminAccess {
        totalEmission -= amount;
    }

    /**
     * @dev Increase the total emission
     */
    function increaseTotalEmission(uint256 amount) external onlyAdminAccess {
        totalEmission += amount;
    }

    /**
     * @dev Recalculate the total amount of founders to be included for every day starting from a specific day
     */
    function recalculateTotalFounders(uint256 dayToStart) external onlyAdminAccess {
        uint256 base = DailyFounderEmissions[dayToStart].totalFounders;

        for (uint256 index = dayToStart + 1; index <= DaysSinceStart; index++) {
            DailyFounderEmission storage daily = DailyFounderEmissions[index];

            daily.totalFounders += base;
        }
    }

    /**
     * @dev Claim daily emissions from AtlasStaker and distribute over founder token stakers
     */
    function claimDailyEmission(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) public onlyBattleflyBot nonReentrant {
        uint256 currentDay = DaysSinceStart + 1;

        uint256 todayTotalEmission = _claimAllFromStaker(
            index,
            epoch,
            cumulativeFlywheelAmount,
            cumulativeHarvesterAmount,
            flywheelClaimableAtEpoch,
            harvesterClaimableAtEpoch,
            individualMiningPower,
            totalMiningPower,
            merkleProof
        );

        uint256 gFlyEmission = _claimAllGFlyEmissions();

        uint256 todayTotalFounderNFTs = _updateTotalStakingFounders(currentDay);

        uint256 stakeBackAmount;
        uint256 v2VaultAmount;
        uint256 treasuryAmount;
        uint256 founderEmission;
        if (todayTotalEmission != 0) {
            stakeBackAmount = ((todayTotalEmission * stakeBackPercent) / PERCENT_DENOMINATOR);
            _stakeBack(stakeBackAmount + pendingFounderEmission);

            v2VaultAmount = (todayTotalEmission * v2VaultPercent) / PERCENT_DENOMINATOR;
            if (v2VaultAmount != 0) {
                magic.approve(address(battleflyFounderVaultV2), v2VaultAmount);
                battleflyFounderVaultV2.topupTodayEmission(v2VaultAmount);
            }

            treasuryAmount = (todayTotalEmission * treasuryPercent) / PERCENT_DENOMINATOR;
            if (treasuryAmount != 0) {
                uint256 opexAmount = (treasuryAmount * 9500) / PERCENT_DENOMINATOR;
                uint256 v2Amount = (treasuryAmount * 500) / PERCENT_DENOMINATOR;
                magic.safeTransfer(OPEX, opexAmount);
                magic.approve(address(battleflyFounderVaultV2), v2Amount);
                battleflyFounderVaultV2.topupTodayEmission(v2Amount);
            }
            founderEmission += todayTotalEmission - stakeBackAmount - v2VaultAmount - treasuryAmount;
        } else if (pendingFounderEmission > 0) {
            _stakeBack(pendingFounderEmission);
        } else {
            _stakeBack(0);
        }
        totalEmission += founderEmission;
        totalGFlyEmission += gFlyEmission;
        DaysSinceStart = currentDay;
        DailyFounderEmissions[DaysSinceStart] = DailyFounderEmission({
            totalEmission: founderEmission,
            totalFounders: todayTotalFounderNFTs
        });
        DailyFounderGFlyEmissions[DaysSinceStart] = DailyFounderGFlyEmission({
            totalEmission: gFlyEmission,
            totalFounders: todayTotalFounderNFTs
        });
        emit ClaimDailyEmission(
            todayTotalEmission,
            founderEmission,
            todayTotalFounderNFTs,
            stakeBackAmount,
            treasuryAmount,
            v2VaultAmount
        );
        emit ClaimDailyGFlyEmission(gFlyEmission, todayTotalFounderNFTs);
    }

    /**
     * @dev Withdraw all withdrawable deposit ids from the vault in the Atlas Staker
     */
    function withdrawAllFromStaker(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) external onlyAdminAccess {
        uint256[] memory ids = depositIds.values();
        withdrawFromStaker(
            ids,
            index,
            epoch,
            cumulativeFlywheelAmount,
            cumulativeHarvesterAmount,
            flywheelClaimableAtEpoch,
            harvesterClaimableAtEpoch,
            individualMiningPower,
            totalMiningPower,
            merkleProof
        );
    }

    function withdrawFromStaker(
        uint256[] memory ids,
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) public onlyAdminAccess {
        claimDailyEmission(
            index,
            epoch,
            cumulativeFlywheelAmount,
            cumulativeHarvesterAmount,
            flywheelClaimableAtEpoch,
            harvesterClaimableAtEpoch,
            individualMiningPower,
            totalMiningPower,
            merkleProof
        );
        require(ids.length > 0, "BattleflyFlywheelVault: No deposited funds");
        for (uint256 i = 0; i < ids.length; i++) {
            if (BattleflyStakerV2.canWithdraw(ids[i])) {
                BattleflyStakerV2.withdraw(ids[i]);
                depositIds.remove(ids[i]);
                emit WithdrawalFromStaker(ids[i]);
            }
        }
    }

    /**
     * @dev Request a withdrawal from Atlas Staker for all claimable deposit ids
     */
    function requestWithdrawAllFromStaker() external onlyAdminAccess {
        uint256[] memory ids = depositIds.values();
        requestWithdrawFromStaker(ids);
    }

    /**
     * @dev Request a withdrawal from Atlas Staker for specific deposit ids
     */
    function requestWithdrawFromStaker(uint256[] memory ids) public onlyAdminAccess {
        for (uint256 i = 0; i < ids.length; i++) {
            if (BattleflyStakerV2.canRequestWithdrawal(ids[i])) {
                BattleflyStakerV2.requestWithdrawal(ids[i]);
                emit RequestWithdrawalFromStaker(ids[i]);
            }
        }
    }

    function setDaysSinceStart(uint256 daysSince) public onlyAdminAccess {
        DaysSinceStart = daysSince;
    }

    /**
     * @dev Withdraw a specific magic amount from the vault and send it to a receiver
     */
    function withdrawFromVault(address receiver, uint256 amount) external onlyAdminAccess {
        magic.safeTransfer(receiver, amount);
    }

    /**
     * @dev Set the daily founder emissions for a specific day
     */
    function setDailyFounderEmissions(
        uint256 day,
        uint256 amount,
        uint256 stakers
    ) external onlyAdminAccess {
        DailyFounderEmissions[day] = DailyFounderEmission(amount, stakers);
    }

    /**
     * @dev Set the treasury vault address
     */
   /* function setTreasuryVault(address _treasuryAddress) external onlyAdminAccess {
        require(_treasuryAddress != address(0));
        TREASURY_VAULT = IBattleflyTreasuryFlywheelVault(_treasuryAddress);
    }*/

    //Must be called right after init
    /**
     * @dev Set the flywheel vault address
     */
    /*function setFlywheelVault(address vault) external onlyOwner {
        require(vault != address(0));
        BattleflyFoundersFlywheelVault = IBattleflyFoundersFlywheelVault(vault);
    }*/

    //Must be called right after init
    /**
     * @dev Set the battlefly bot address
     */
    /*function setBattleflyBot(address _battleflyBot) external onlyOwner {
        require(_battleflyBot != address(0));
        BattleflyBot = _battleflyBot;
    }*/

    //Must be called right after init
    /**
     * @dev Set the battlefly staker address
     */
   /* function setBattleflyStaker(address staker) external onlyOwner {
        require(staker != address(0));
        BattleflyStakerV2 = IBattleflyAtlasStakerV02(staker);
        // Approve the AtlasStaker contract to spend the magic
        magic.approve(address(BattleflyStakerV2), 2**256 - 1);
    }*/

    //Must be called right after init
    /**
     * @dev Set the founder vault address
     */
   /* function setFounderVaultV2(address founderVault) external onlyOwner {
        require(founderVault != address(0));
        battleflyFounderVaultV2 = IBattleflyFounderVault(founderVault);
        // Approve the FounderVault contract to spend the magic
        magic.approve(address(battleflyFounderVaultV2), 2**256 - 1);
    }*/

    /**
     * @dev Set the harvester emissions contract
     */
   /* function setHarvesterEmission(address _harvesterEmission) external onlyOwner {
        require(_harvesterEmission != address(0));
        BattleflyHarvesterEmissions = IBattleflyHarvesterEmissions(_harvesterEmission);
    }*/

    /**
     * @dev Set the OPEX address
     */
   /* function setOpex(address _opex) external onlyOwner {
        require(_opex != address(0));
        OPEX = _opex;
    }*/

    /**
     * @dev Set the flywheel emissions contract
     */
    function setFlywheelEmissions(address flywheelEmissions) external onlyOwner {
        require(flywheelEmissions != address(0));
        FLYWHEEL_EMISSIONS = IFlywheelEmissions(flywheelEmissions);
    }

    /**
     * @dev Set the gFly contract
     */
    function setGFly(address gFly) external onlyOwner {
        require(gFly != address(0));
        GFLY = IGFly(gFly);
    }

    /**
     * @dev Set the gFly staking contract
     */
    function setGFlyStaking(address gFlyStaking) external onlyOwner {
        require(gFlyStaking != address(0));
        GFLY_STAKING = IGFlyStaking(gFlyStaking);
    }

    //Must be called right after init
    /**
     * @dev Set the distribution percentages
     */
    function setPercentages(
        uint256 _stakeBackPercent,
        uint256 _treasuryPercent,
        uint256 _v2VaultPercent
    ) external onlyOwner {
        require(_stakeBackPercent + _treasuryPercent + _v2VaultPercent <= PERCENT_DENOMINATOR);
        stakeBackPercent = _stakeBackPercent;
        treasuryPercent = _treasuryPercent;
        v2VaultPercent = _v2VaultPercent;
    }

    /**
     * @dev Set admin access for a specific user
     */
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] || _msgSender() == owner(), "Require admin access");
        _;
    }

    modifier onlyBattleflyBot() {
        require(msg.sender == BattleflyBot, "Require battlefly bot");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IAtlasMine.sol";

interface IBattleflyAtlasStakerV02 {
    struct Vault {
        uint16 fee;
        uint16 claimRate;
        bool enabled;
    }

    struct VaultStake {
        uint64 lockAt;
        uint64 unlockAt;
        uint64 retentionUnlock;
        uint256 amount;
        uint256 paidEmission;
        address vault;
        IAtlasMine.Lock lock;
    }

    function MAGIC() external returns (IERC20Upgradeable);

    function deposit(uint256, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function claim(uint256) external returns (uint256);

    function requestWithdrawal(uint256) external returns (uint64);

    function currentDepositId() external view returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getVaultStake(uint256) external view returns (VaultStake memory);

    function getClaimableEmission(uint256) external view returns (uint256, uint256);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function currentEpoch() external view returns (uint64 epoch);

    function transitionEpoch() external view returns (uint64 epoch);

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);

    function setPause(bool _paused) external;

    function depositIdsOfVault(address vault) external view returns (uint256[] memory depositIds);

    function activeAtlasPositionSize() external view returns (uint256);

    function totalStakedAtEpochForLock(IAtlasMine.Lock lock, uint64 epoch) external view returns (uint256);

    function totalPerShareAtEpochForLock(IAtlasMine.Lock lock, uint64 epoch) external view returns (uint256);

    function FEE_DENOMINATOR() external pure returns (uint96);

    function pausedUntil() external view returns (uint256);

    function getVault(address _vault) external view returns (Vault memory);

    function getTotalClaimableEmission(uint256 _depositId) external view returns (uint256 emission, uint256 fee);

    function getApyAtEpochIn1000(uint64 epoch) external view returns (uint256);

    // ========== Events ==========
    event AddedSuperAdmin(address who);
    event RemovedSuperAdmin(address who);

    event AddedVault(address indexed vault, uint16 fee, uint16 claimRate);
    event RemovedVault(address indexed vault);

    event StakedTreasure(address staker, uint256 tokenId, uint256 amount);
    event UnstakedTreasure(address staker, uint256 tokenId, uint256 amount);

    event StakedLegion(address staker, uint256 tokenId);
    event UnstakedLegion(address staker, uint256 tokenId);

    event SetTreasury(address treasury);
    event SetBattleflyBot(address bot);

    event NewDeposit(address indexed vault, uint256 amount, uint256 unlockedAt, uint256 indexed depositId);
    event WithdrawPosition(address indexed vault, uint256 amount, uint256 indexed depositId);
    event ClaimEmission(address indexed vault, uint256 amount, uint256 indexed depositId);
    event RequestWithdrawal(address indexed vault, uint64 withdrawalEpoch, uint256 indexed depositId);

    event DepositedAllToMine(uint256 amount);

    event SetPause(bool paused);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./IAtlasMine.sol";

interface IBattleflyFlywheelVaultV02 {
    struct UserStake {
        uint64 lockAt;
        uint256 amount;
        address owner;
        IAtlasMine.Lock lock;
    }

    function deposit(uint128, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256[] calldata _depositIds) external returns (uint256);

    function withdrawAll() external returns (uint256);

    function requestWithdrawal(uint256[] calldata _depositIds) external;

    function claim(uint256) external returns (uint256);

    function claimAll() external returns (uint256);

    function claimAllFlywheel(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) external returns (uint256 amount);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getClaimableEmission(uint256) external view returns (uint256);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function initialUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function retentionUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function getCurrentEpoch() external view returns (uint64 epoch);

    function depositIdsOfUser(address user) external view returns (uint256[] memory depositIds);

    function getName() external view returns (string memory);

    // ================== EVENTS ==================
    event NewUserStake(
        uint256 indexed depositId,
        uint256 amount,
        uint256 unlockAt,
        address indexed owner,
        IAtlasMine.Lock lock
    );
    event UpdateUserStake(
        uint256 indexed depositId,
        uint256 amount,
        uint256 unlockAt,
        address indexed owner,
        IAtlasMine.Lock lock
    );
    event ClaimEmission(uint256 indexed depositId, uint256 emission);
    event WithdrawPosition(uint256 indexed depositId, uint256 amount);
    event RequestWithdrawal(uint256 indexed depositId);

    event AddedUser(address indexed vault);
    event RemovedUser(address indexed vault);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(address user, uint256 depositId)
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./IMod.sol";

interface ISpecialNFT is IERC721EnumerableUpgradeable {
    function mintSpecialNFT(address receiver, uint256 specialNFTType) external returns (uint256);

    function mintSpecialNFTs(
        address receiver,
        uint256 _specialNFTType,
        uint256 amount
    ) external returns (uint256[] memory);

    function getSpecialNFTType(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "./IAtlasMine.sol";

interface IBattleflyAtlasStaker {
    // ============= Events ==============

    event VaultDeposit(
        address indexed vault,
        uint256 indexed depositId,
        uint256 amount,
        uint256 unlockAt,
        IAtlasMine.Lock lock
    );
    event VaultWithdraw(address indexed vault, uint256 indexed depositId, uint256 amount, uint256 reward);
    event VaultClaim(address indexed vault, uint256 indexed depositId, uint256 reward);
    event MineStake(uint256 currentDepositId, uint256 unlockTime);
    event MineHarvest(uint256 earned, uint256 feeEarned, uint256 feeRefunded);
    event StakeNFT(address indexed vault, address indexed nft, uint256 tokenId, uint256 amount, uint256 currentBoost);
    event UnstakeNFT(address indexed vault, address indexed nft, uint256 tokenId, uint256 amount, uint256 currentBoost);
    event StakingPauseToggle(bool paused);
    event WithdrawFeesToTreasury(uint256 amount);
    event SetFeeWhitelistVault(address vault, bool isSet);
    event SetBattleflyVault(address vault, bool isSet);

    // ================= Data Types ==================

    struct Stake {
        uint256 amount;
        uint256 unlockAt;
        uint256 depositId;
    }

    struct VaultStake {
        uint256 amount;
        uint256 unlockAt;
        int256 rewardDebt;
        IAtlasMine.Lock lock;
    }
    struct VaultOwner {
        uint256 share;
        int256 rewardDebt;
        address owner;
        uint256 unclaimedReward;
    }

    // =============== View Functions ================

    function getVaultStake(address vault, uint256 depositId) external returns (VaultStake memory);

    // function vaultTotalStake(address vault) external returns (uint256);

    function pendingRewards(address vault, uint256 depositId) external view returns (uint256);

    function pendingRewardsAll(address vault) external returns (uint256);

    function totalMagic() external returns (uint256);

    // function totalPendingStake() external returns (uint256);

    function totalWithdrawableMagic() external returns (uint256);

    // ============= Staking Operations ==============

    function deposit(uint256 _amount, IAtlasMine.Lock lock) external returns (uint256);

    function withdraw(uint256 depositId) external;

    function withdrawAll() external;

    function claim(uint256 depositId) external returns (uint256);

    function claimAll() external returns (uint256);

    // function withdrawEmergency() external;

    function stakeScheduled() external;

    // ============= Owner Operations ==============

    function unstakeAllFromMine() external;

    function unstakeToTarget(uint256 target) external;

    // function emergencyUnstakeAllFromMine() external;

    function setBoostAdmin(address _hoard, bool isSet) external;

    function approveNFTs() external;

    // function revokeNFTApprovals() external;

    // function setMinimumStakingWait(uint256 wait) external;

    function toggleSchedulePause(bool paused) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "./IAtlasMine.sol";

interface IBattleflyFounderVault {
    struct FounderStake {
        uint256 amount;
        uint256 stakeTimestamp;
        address owner;
        uint256[] founderNFTIDs;
        uint256 lastClaimedDay;
    }

    function topupTodayEmission(uint256 amount) external;

    function topupMagicToStaker(uint256 amount, IAtlasMine.Lock lock) external;

    function depositToStaker(uint256 amount, IAtlasMine.Lock lock) external;

    function stakesOf(address owner) external view returns (FounderStake[] memory);

    function isOwner(address owner, uint256 tokenId) external view returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);

    function getName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IAtlasMine.sol";

interface IBattleflyHarvesterEmissions {
    struct HarvesterEmission {
        uint256 amount;
        uint256 harvesterMagic;
        uint256 additionalFlywheelMagic;
    }

    function topupHarvesterEmissions(
        uint256 _amount,
        uint256 _harvesterMagic,
        uint256 _additionalFlywheelMagic
    ) external;

    function setVaultHarvesterStake(uint256 _amount, address _vault) external;

    function getClaimableEmission(uint256 _depositId) external view returns (uint256 emission, uint256 fee);

    function getClaimableEmission(address _vault) external view returns (uint256 emission, uint256 fee);

    function claim(uint256 _depositId) external returns (uint256);

    function claim(address _vault) external returns (uint256);

    function claimVault(address _vault) external returns (uint256);

    function getApyAtEpochIn1000(uint64 epoch) external view returns (uint256);

    // ========== Events ==========
    event topupHarvesterMagic(uint256 amount, uint256 harvesterMagic, uint256 additionalFlywheelMagic, uint64 epoch);
    event ClaimHarvesterEmission(address user, uint256 emission, uint256 depositId);
    event ClaimHarvesterEmissionFromVault(address user, uint256 emission, address vault);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyFlywheelVault {
    function getStakeAmount(address user) external view returns (uint256, uint256);

    function stakeableAmountPerV1() external view returns (uint256);

    function stakeableAmountPerV2() external view returns (uint256);

    function stakeableAmountPerFounder(address vault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFlywheelEmissions {
    struct HarvesterEmission {
        uint256 amount;
        uint256 harvesterMagic;
        uint256 additionalFlywheelMagic;
    }

    struct ContractAddresses {
        address magic;
        address gFly;
        address gFlyStaking;
        address atlasStaker;
        address treasuryVault;
        address opex;
        address vault1;
        address vault2;
        address cheese;
        address digi;
        address battleflyBot;
        address dao;
    }

    function setGFlyGameAddress(address vault, address gFlyGameAddress) external;

    function setGFlyMagicSwap(address gFlyMagicSwap) external;

    function topupHarvesterEmissions(
        uint256 amount,
        uint256 harvesterMagic,
        uint256 additionalFlywheelMagic
    ) external;

    function topupFlywheelEmissions(uint256 amount) external;

    function setVaultHarvesterStake(uint256 _amount, address _vault) external;

    function claim(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) external;

    function setMerkleRoot(bytes32 root) external;

    function getClaimableFor(
        address account,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount
    ) external view returns (uint256 claimable);

    function getClaimedFor(address account) external view returns (uint256);

    function getApyInBPS(
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 totalStaked
    ) external pure returns (uint256 apyInBPS);

    function getActivatedRewardsInBPS() external view returns (uint256 rewardsActivated);

    // ========== Events ==========
    event GFlyGameAddressSet(address indexed vault, address indexed gFlyGameAddress);
    event HarvesterEmissionsToppedUp(
        uint256 amount,
        uint256 harvesterMagic,
        uint256 additionalFlywheelMagic,
        uint256 v1VaultHarvesterStake,
        uint256 v2vaultHarvesterStake,
        uint256 cheeseHarvesterStake,
        uint256 digiHarvesterStake,
        uint64 indexed epoch,
        uint256 activatedRewardsInBPS
    );
    event FlywheelEmissionsToppedUp(uint64 indexed epoch, uint256 amount);
    event Claimed(address indexed account, uint256 claimable, uint256 indexed epoch);
    event MerkleRootSet(bytes32 root, uint256 indexed emissionsEpoch);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "../IAtlasMine.sol";

interface IBattleflyFoundersFlywheelVault {
    struct UserStake {
        uint64 lockAt;
        uint256 amount;
        address owner;
        IAtlasMine.Lock lock;
    }

    function deposit(uint128, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256[] memory _depositIds) external returns (uint256);

    function withdrawAll() external returns (uint256);

    function requestWithdrawal(uint256[] memory _depositIds) external;

    function claim(uint256) external returns (uint256);

    function claimAll() external returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getClaimableEmission(uint256) external view returns (uint256);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function initialUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function retentionUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function getCurrentEpoch() external view returns (uint64 epoch);

    function getStakedAmount(address user) external view returns (uint256 amount);

    function getDepositIdsOfUser(address user) external view returns (uint256[] memory depositIds);

    function getName() external pure returns (string memory);

    function STAKING_LIMIT_V1() external view returns (uint256);

    function STAKING_LIMIT_V2() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "../IAtlasMine.sol";

interface IBattleflyTreasuryFlywheelVault {
    struct UserStake {
        uint64 lockAt;
        uint256 amount;
        address owner;
        IAtlasMine.Lock lock;
    }

    function deposit(uint128 _amount) external returns (uint256 atlasStakerDepositId);

    function withdraw(uint256[] memory _depositIds, address user) external returns (uint256 amount);

    function withdrawAll(address user) external returns (uint256 amount);

    function requestWithdrawal(uint256[] memory _depositIds) external;

    function claim(uint256 _depositId, address user) external returns (uint256 emission);

    function claimAll(address user) external returns (uint256 amount);

    function claimAllAndRestake() external returns (uint256 amount);

    function topupMagic(uint256 amount) external;

    function withdrawLiquidAmount(uint256 amount) external;

    function setRestake(bool restake_) external;

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getClaimableEmission(uint256) external view returns (uint256);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function initialUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function retentionUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function getCurrentEpoch() external view returns (uint64 epoch);

    function getDepositIds() external view returns (uint256[] memory ids);

    function getName() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../gFly/GFly.sol";

interface IGFlyStaking {
    struct GFlyStake {
        address owner;
        uint256 amount;
        uint16 lock;
        uint16 unlockEpoch;
        uint256 pendingRewards;
        uint16 lastProcessEpoch;
    }

    event Staked(address indexed account, uint256 indexed stakeId, uint256 amount, uint16 lock, uint16 unlockEpoch);
    event UnStaked(address indexed account, uint256 indexed stakeId, uint256 amount);
    event StakeTransfered(
        address indexed owner,
        uint256 indexed stakeId,
        address indexed newOwner,
        uint256 newStakeId,
        uint256 amount
    );
    event LockExtended(address indexed account, uint256 indexed stakeId, uint16 lock, uint16 unlockEpoch);
    event Claimed(address indexed account, uint256 indexed stakeId, uint256 amount);
    event ClaimedAndRestaked(address indexed account, uint256 indexed stakeId, uint256 amount);
    event Paused(bool state);
    event EmissionsDistributed(uint256 totalMiningPower, uint16 currentEpoch);

    function distributeEmissions() external;

    function stake(uint256 amount, uint16 lock) external returns (uint256);

    function addToStake(uint256 amount, uint256 stakeId) external;

    function unStake(uint256 stakeId) external;

    function unStakeAll() external;

    function claim(uint256 stakeId) external;

    function claimAll() external;

    function extendLockPeriod(uint256 stakeId, uint16 lock) external;

    function extendLockPeriodOfAllStakes(uint16 lock) external;

    function claimableById(uint256 stakeId) external view returns (uint256 total);

    function claimableByAddress(address account) external view returns (uint256 total);

    function getStakesOfAddress(address account) external view returns (uint256[] memory);

    function getStake(uint256 stakeId) external view returns (GFlyStake memory);

    function setPause(bool state) external;

    function setNextCron(uint256 nextCron_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGFly is IERC20 {
    function MAX_SUPPLY() external returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IMod is IERC721EnumerableUpgradeable {
    function mintMod(address receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/gFly/IGFly.sol";
import "../interfaces/gFly/IVestedGFly.sol";

//MMMMWKl.                                            .:0WMMMM//
//MMMWk,                                                .dNMMM//
//MMNd.                                                  .lXMM//
//MWd.    .','''....                         .........    .lXM//
//Wk.     ';......'''''.                ..............     .dW//
//K;     .;,         ..,'.            ..'..         ...     'O//
//d.     .;;.           .''.        ..'.            .'.      c//
//:       .','.           .''.    ..'..           ....       '//
//'         .';.            .''...'..           ....         .//
//.           ';.             .''..             ..           .//
//.            ';.                             ...           .//
//,            .,,.                           .'.            .//
//c             .;.                           '.             ;//
//k.            .;.             .             '.            .d//
//Nl.           .;.           .;;'            '.            :K//
//MK:           .;.          .,,',.           '.           'OW//
//MM0;          .,,..       .''  .,.       ...'.          'kWM//
//MMMK:.          ..'''.....'..   .'..........           ,OWMM//
//MMMMXo.             ..'...        ......             .cKMMMM//
//MMMMMWO:.                                          .,kNMMMMM//
//MMMMMMMNk:.                                      .,xXMMMMMMM//
//MMMMMMMMMNOl'.                                 .ckXMMMMMMMMM//

contract GFly is AccessControl, ERC20, IGFly {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    uint256 public constant override MAX_SUPPLY = 1e7 * 1 ether;

    IVestedGFly public vestedGFly;

    constructor(address dao, address vestedGFly_) ERC20("gFLY", "GFLY") {
        require(dao != address(0), "GFly:INVALID_ADDRESS");
        require(vestedGFly_ != address(0), "GFly:INVALID_ADDRESS");

        vestedGFly = IVestedGFly(vestedGFly_);

        _setupRole(MINTER_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "GFly:MINT_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFly:ACCESS_DENIED");
        _;
    }

    function mint(address account, uint256 amount) external override onlyMinter {
        require(
            vestedGFly.unminted() + vestedGFly.totalSupply() + totalSupply() + amount <= MAX_SUPPLY,
            "GFly:SUPPLY_OVERFLOW"
        );
        _mint(account, amount);
    }

    function burn(uint256 amount) external override onlyAdmin {
        _burn(msg.sender, amount);
    }

    function addMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestedGFly is IERC20 {
    struct VestingPosition {
        bool burnable;
        bool minted;
        address owner;
        uint256 startTime;
        uint256 lastBurnTime;
        uint256 employmentTimestamp;
        uint256 remainingAllocation;
        uint256 initialAllocation;
        uint256 initialUnlockable;
        uint256 burnt;
        uint256 vestedAtLastBurn;
        uint256 employeeBurnt;
    }

    function addVestingPosition(
        address owner,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 employmentTimestamp
    ) external;

    function mint() external;

    function burn(uint256 vestingId, uint256 amount) external;

    function burnAll(uint256 vestingId) external;

    function transferVestingPosition(
        uint256 vestingId,
        uint256 amount,
        address newOwner
    ) external;

    function claimAllGFly() external;

    function claimGFly(uint256 vestingId) external;

    function totalVestedOf(address account) external view returns (uint256 total);

    function vestedOf(uint256 vestingId) external view returns (uint256);

    function totalClaimableOf(address account) external view returns (uint256 total);

    function claimableOf(uint256 vestingId) external view returns (uint256);

    function totalClaimedOf(address account) external view returns (uint256 total);

    function claimedOf(uint256 vestingId) external view returns (uint256);

    function totalBalance(address account) external view returns (uint256 total);

    function balanceOfVesting(uint256 vestingId) external view returns (uint256);

    function getVestingIdsOfAddress(address account) external view returns (uint256[] memory);

    function maxBurnable(uint256 vestingId) external view returns (uint256 burnable);

    function claimableOfAtTimestamp(uint256 vestingId, uint256 timestamp) external view returns (uint256);

    function unminted() external returns (uint256);

    event VestingPositionAdded(
        address indexed owner,
        uint256 indexed vestingId,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 startTime
    );
    event Minted(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event Burned(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event GFlyClaimed(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event VestingPositionTransfered(
        address indexed owner,
        uint256 indexed vestingId,
        address indexed newOwner,
        uint256 newVestingId,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}