// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./interfaces/IMasterOfCoin.sol";
import "./interfaces/ILegionMetadataStore.sol";

contract AtlasMine is Initializable, AccessControlEnumerableUpgradeable, ERC1155HolderUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;

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

    bytes32 public constant ATLAS_MINE_ADMIN_ROLE = keccak256("ATLAS_MINE_ADMIN_ROLE");

    uint256 public constant DAY = 1 days;
    uint256 public constant ONE_WEEK = 7 days;
    uint256 public constant TWO_WEEKS = ONE_WEEK * 2;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant THREE_MONTHS = ONE_MONTH * 3;
    uint256 public constant SIX_MONTHS = ONE_MONTH * 6;
    uint256 public constant TWELVE_MONTHS = 365 days;
    uint256 public constant ONE = 1e18;

    // Magic token addr
    IERC20Upgradeable public magic;
    IMasterOfCoin public masterOfCoin;

    bool public unlockAll;

    uint256 public totalRewardsEarned;
    uint256 public totalUndistributedRewards;
    uint256 public accMagicPerShare;
    uint256 public totalLpToken;
    uint256 public magicTotalDeposits;

    uint256 public utilizationOverride;
    EnumerableSetUpgradeable.AddressSet private excludedAddresses;

    address public legionMetadataStore;
    address public treasure;
    address public legion;

    // user => staked 1/1
    mapping(address => bool) public isLegion1_1Staked;
    uint256[][] public legionBoostMatrix;

    /// @notice user => depositId => UserInfo
    mapping(address => mapping(uint256 => UserInfo)) public userInfo;
    /// @notice user => depositId[]
    mapping(address => EnumerableSetUpgradeable.UintSet) private allUserDepositIds;
    /// @notice user => deposit index
    mapping(address => uint256) public currentId;

    // user => tokenIds
    mapping(address => EnumerableSetUpgradeable.UintSet) private legionStaked;
    // user => tokenId => amount
    mapping(address => mapping(uint256 => uint256)) public treasureStaked;
    // user => total amount staked
    mapping(address => uint256) public treasureStakedAmount;
    // user => boost
    mapping(address => uint256) public boosts;

    event Staked(address nft, uint256 tokenId, uint256 amount, uint256 currentBoost);
    event Unstaked(address nft, uint256 tokenId, uint256 amount, uint256 currentBoost);

    event Deposit(address indexed user, uint256 indexed index, uint256 amount, Lock lock);
    event Withdraw(address indexed user, uint256 indexed index, uint256 amount);
    event UndistributedRewardsWithdraw(address indexed to, uint256 amount);
    event Harvest(address indexed user, uint256 indexed index, uint256 amount);
    event LogUpdateRewards(
        uint256 distributedRewards,
        uint256 undistributedRewards,
        uint256 lpSupply,
        uint256 accMagicPerShare
    );
    event UtilizationRate(uint256 util);

    modifier updateRewards() {
        uint256 lpSupply = totalLpToken;
        if (lpSupply > 0) {
            (uint256 distributedRewards, uint256 undistributedRewards) = getRealMagicReward(
                masterOfCoin.requestRewards()
            );
            totalRewardsEarned += distributedRewards;
            totalUndistributedRewards += undistributedRewards;
            accMagicPerShare += (distributedRewards * ONE) / lpSupply;
            emit LogUpdateRewards(distributedRewards, undistributedRewards, lpSupply, accMagicPerShare);
        }

        uint256 util = utilization();
        emit UtilizationRate(util);
        _;
    }

    function init(address _magic, address _masterOfCoin) external initializer {
        magic = IERC20Upgradeable(_magic);
        masterOfCoin = IMasterOfCoin(_masterOfCoin);

        _setRoleAdmin(ATLAS_MINE_ADMIN_ROLE, ATLAS_MINE_ADMIN_ROLE);
        _grantRole(ATLAS_MINE_ADMIN_ROLE, msg.sender);

        // array follows values from ILegionMetadataStore.LegionGeneration and ILegionMetadataStore.LegionRarity
        legionBoostMatrix = [
            // GENESIS
            // LEGENDARY,RARE,SPECIAL,UNCOMMON,COMMON,RECRUIT
            [uint256(600e16), uint256(200e16), uint256(75e16), uint256(100e16), uint256(50e16), uint256(0)],
            // AUXILIARY
            // LEGENDARY,RARE,SPECIAL,UNCOMMON,COMMON,RECRUIT
            [uint256(0), uint256(25e16), uint256(0), uint256(10e16), uint256(5e16), uint256(0)],
            // RECRUIT
            // LEGENDARY,RARE,SPECIAL,UNCOMMON,COMMON,RECRUIT
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        ];

        __AccessControlEnumerable_init();
        __ERC1155Holder_init();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155ReceiverUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getStakedLegions(address _user) external view virtual returns (uint256[] memory) {
        return legionStaked[_user].values();
    }

    function getUserBoost(address _user) external view virtual returns (uint256) {
        return boosts[_user];
    }

    function getLegionBoostMatrix() external view virtual returns (uint256[][] memory) {
        return legionBoostMatrix;
    }

    function getLegionBoost(uint256 _legionGeneration, uint256 _legionRarity) public view virtual returns (uint256) {
        if (
            _legionGeneration < legionBoostMatrix.length && _legionRarity < legionBoostMatrix[_legionGeneration].length
        ) {
            return legionBoostMatrix[_legionGeneration][_legionRarity];
        }
        return 0;
    }

    function utilization() public view virtual returns (uint256 util) {
        if (utilizationOverride > 0) return utilizationOverride;

        uint256 circulatingSupply = magic.totalSupply();
        uint256 len = excludedAddresses.length();
        for (uint256 i = 0; i < len; i++) {
            circulatingSupply -= magic.balanceOf(excludedAddresses.at(i));
        }
        uint256 rewardsAmount = magic.balanceOf(address(this)) - magicTotalDeposits;
        circulatingSupply -= rewardsAmount;
        if (circulatingSupply != 0) {
            util = (magicTotalDeposits * ONE) / circulatingSupply;
        }
    }

    function getRealMagicReward(uint256 _magicReward)
        public
        view
        virtual
        returns (uint256 distributedRewards, uint256 undistributedRewards)
    {
        //Disabled for testing
        /*   uint256 util = utilization();

        if (util < 3e17) {
            distributedRewards = 0;
        } else if (util < 4e17) { // >30%
            // 50%
            distributedRewards = _magicReward * 5 / 10;
        } else if (util < 5e17) { // >40%
            // 60%
            distributedRewards = _magicReward * 6 / 10;
        } else if (util < 6e17) { // >50%
            // 80%
            distributedRewards = _magicReward * 8 / 10;
        } else { // >60%
            // 100%
            distributedRewards = _magicReward;
        }

        undistributedRewards = _magicReward - distributedRewards;   */
        distributedRewards = _magicReward;
        undistributedRewards = 0;
    }

    function getAllUserDepositIds(address _user) public view virtual returns (uint256[] memory) {
        return allUserDepositIds[_user].values();
    }

    function getExcludedAddresses() public view virtual returns (address[] memory) {
        return excludedAddresses.values();
    }

    function getLockBoost(Lock _lock) public pure virtual returns (uint256 boost, uint256 timelock) {
        if (_lock == Lock.twoWeeks) {
            // 10%
            return (10e16, TWO_WEEKS);
        } else if (_lock == Lock.oneMonth) {
            // 25%
            return (25e16, ONE_MONTH);
        } else if (_lock == Lock.threeMonths) {
            // 80%
            return (80e16, THREE_MONTHS);
        } else if (_lock == Lock.sixMonths) {
            // 180%
            return (180e16, SIX_MONTHS);
        } else if (_lock == Lock.twelveMonths) {
            // 400%
            return (400e16, TWELVE_MONTHS);
        } else {
            revert("Invalid lock value");
        }
    }

    function getVestingTime(Lock _lock) public pure virtual returns (uint256 vestingTime) {
        if (_lock == Lock.twoWeeks) {
            vestingTime = 0;
        } else if (_lock == Lock.oneMonth) {
            vestingTime = 7 days;
        } else if (_lock == Lock.threeMonths) {
            vestingTime = 14 days;
        } else if (_lock == Lock.sixMonths) {
            vestingTime = 30 days;
        } else if (_lock == Lock.twelveMonths) {
            vestingTime = 45 days;
        }
    }

    function calcualteVestedPrincipal(address _user, uint256 _depositId) public view virtual returns (uint256 amount) {
        UserInfo storage user = userInfo[_user][_depositId];
        Lock _lock = user.lock;

        uint256 vestingEnd = user.lockedUntil + getVestingTime(_lock);
        uint256 vestingBegin = user.lockedUntil;

        if (block.timestamp >= vestingEnd || unlockAll) {
            amount = user.originalDepositAmount;
        } else if (block.timestamp > user.vestingLastUpdate) {
            amount =
                (user.originalDepositAmount * (block.timestamp - user.vestingLastUpdate)) /
                (vestingEnd - vestingBegin);
        }
    }

    function pendingRewardsPosition(address _user, uint256 _depositId) public view virtual returns (uint256 pending) {
        UserInfo storage user = userInfo[_user][_depositId];
        uint256 _accMagicPerShare = accMagicPerShare;
        uint256 lpSupply = totalLpToken;

        (uint256 distributedRewards, ) = getRealMagicReward(masterOfCoin.getPendingRewards(address(this)));
        _accMagicPerShare += (distributedRewards * ONE) / lpSupply;

        pending = (((user.lpAmount * _accMagicPerShare) / ONE).toInt256() - user.rewardDebt).toUint256();
    }

    function pendingRewardsAll(address _user) external view virtual returns (uint256 pending) {
        uint256 len = allUserDepositIds[_user].length();
        for (uint256 i = 0; i < len; i++) {
            uint256 depositId = allUserDepositIds[_user].at(i);
            pending += pendingRewardsPosition(_user, depositId);
        }
    }

    function deposit(uint256 _amount, Lock _lock) public virtual updateRewards {
        (UserInfo storage user, uint256 depositId) = _addDeposit(msg.sender);
        (uint256 lockBoost, uint256 timelock) = getLockBoost(_lock);
        uint256 nftBoost = boosts[msg.sender];
        uint256 lpAmount = _amount + (_amount * (lockBoost + nftBoost)) / ONE;
        magicTotalDeposits += _amount;
        totalLpToken += lpAmount;

        user.originalDepositAmount = _amount;
        user.depositAmount = _amount;
        user.lpAmount = lpAmount;
        user.lockedUntil = block.timestamp + timelock;
        user.vestingLastUpdate = user.lockedUntil;
        user.rewardDebt = ((lpAmount * accMagicPerShare) / ONE).toInt256();
        user.lock = _lock;

        magic.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, depositId, _amount, _lock);
    }

    function withdrawPosition(uint256 _depositId, uint256 _amount) public virtual updateRewards returns (bool) {
        UserInfo storage user = userInfo[msg.sender][_depositId];
        uint256 depositAmount = user.depositAmount;
        if (depositAmount == 0) return false;

        if (_amount > depositAmount) {
            _amount = depositAmount;
        }
        // anyone can withdraw if kill swith was used
        if (!unlockAll) {
            require(block.timestamp >= user.lockedUntil, "Position is still locked");
            uint256 vestedAmount = _vestedPrincipal(msg.sender, _depositId);
            if (_amount > vestedAmount) {
                _amount = vestedAmount;
            }
        }

        // Effects
        uint256 ratio = (_amount * ONE) / depositAmount;
        uint256 lpAmount = (user.lpAmount * ratio) / ONE;

        totalLpToken -= lpAmount;
        magicTotalDeposits -= _amount;

        user.depositAmount -= _amount;
        user.lpAmount -= lpAmount;
        user.rewardDebt -= ((lpAmount * accMagicPerShare) / ONE).toInt256();

        // Interactions
        magic.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _depositId, _amount);

        return true;
    }

    function withdrawAll() public virtual {
        uint256[] memory depositIds = allUserDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            withdrawPosition(depositIds[i], type(uint256).max);
        }
    }

    function harvestPosition(uint256 _depositId) public virtual updateRewards {
        UserInfo storage user = userInfo[msg.sender][_depositId];

        int256 accumulatedMagic = ((user.lpAmount * accMagicPerShare) / ONE).toInt256();
        uint256 _pendingMagic = (accumulatedMagic - user.rewardDebt).toUint256();

        // Effects
        user.rewardDebt = accumulatedMagic;

        if (user.depositAmount == 0 && user.lpAmount == 0) {
            _removeDeposit(msg.sender, _depositId);
        }

        // Interactions
        if (_pendingMagic != 0) {
            magic.safeTransfer(msg.sender, _pendingMagic);
        }

        emit Harvest(msg.sender, _depositId, _pendingMagic);

        require(magic.balanceOf(address(this)) >= magicTotalDeposits, "Run on banks");
    }

    function harvestAll() public virtual {
        uint256[] memory depositIds = allUserDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            harvestPosition(depositIds[i]);
        }
    }

    function withdrawAndHarvestPosition(uint256 _depositId, uint256 _amount) public virtual {
        withdrawPosition(_depositId, _amount);
        harvestPosition(_depositId);
    }

    function withdrawAndHarvestAll() public virtual {
        uint256[] memory depositIds = allUserDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            withdrawAndHarvestPosition(depositIds[i], type(uint256).max);
        }
    }

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external virtual updateRewards {
        require(treasure != address(0), "Cannot stake Treasure");
        require(_amount > 0, "Amount is 0");

        treasureStaked[msg.sender][_tokenId] += _amount;
        treasureStakedAmount[msg.sender] += _amount;

        require(treasureStakedAmount[msg.sender] <= 20, "Max 20 treasures per wallet");

        uint256 boost = getNftBoost(treasure, _tokenId, _amount);
        boosts[msg.sender] += boost;

        _recalculateLpAmount(msg.sender);

        IERC1155Upgradeable(treasure).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, bytes(""));

        emit Staked(treasure, _tokenId, _amount, boosts[msg.sender]);
    }

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external virtual updateRewards {
        require(treasure != address(0), "Cannot stake Treasure");
        require(_amount > 0, "Amount is 0");
        require(treasureStaked[msg.sender][_tokenId] >= _amount, "Withdraw amount too big");

        treasureStaked[msg.sender][_tokenId] -= _amount;
        treasureStakedAmount[msg.sender] -= _amount;

        uint256 boost = getNftBoost(treasure, _tokenId, _amount);
        boosts[msg.sender] -= boost;

        _recalculateLpAmount(msg.sender);

        IERC1155Upgradeable(treasure).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, bytes(""));

        emit Unstaked(treasure, _tokenId, _amount, boosts[msg.sender]);
    }

    function stakeLegion(uint256 _tokenId) external virtual updateRewards {
        require(legion != address(0), "Cannot stake Legion");
        require(legionStaked[msg.sender].add(_tokenId), "NFT already staked");
        require(legionStaked[msg.sender].length() <= 3, "Max 3 legions per wallet");

        if (isLegion1_1(_tokenId)) {
            require(!isLegion1_1Staked[msg.sender], "Max 1 1/1 legion per wallet");
            isLegion1_1Staked[msg.sender] = true;
        }

        uint256 boost = getNftBoost(legion, _tokenId, 1);
        boosts[msg.sender] += boost;

        _recalculateLpAmount(msg.sender);

        IERC721Upgradeable(legion).transferFrom(msg.sender, address(this), _tokenId);

        emit Staked(legion, _tokenId, 1, boosts[msg.sender]);
    }

    function unstakeLegion(uint256 _tokenId) external virtual updateRewards {
        require(legionStaked[msg.sender].remove(_tokenId), "NFT is not staked");

        if (isLegion1_1(_tokenId)) {
            isLegion1_1Staked[msg.sender] = false;
        }

        uint256 boost = getNftBoost(legion, _tokenId, 1);
        boosts[msg.sender] -= boost;

        _recalculateLpAmount(msg.sender);

        IERC721Upgradeable(legion).transferFrom(address(this), msg.sender, _tokenId);

        emit Unstaked(legion, _tokenId, 1, boosts[msg.sender]);
    }

    function isLegion1_1(uint256 _tokenId) public view virtual returns (bool) {
        try ILegionMetadataStore(legionMetadataStore).metadataForLegion(_tokenId) returns (
            ILegionMetadataStore.LegionMetadata memory metadata
        ) {
            return
                metadata.legionGeneration == ILegionMetadataStore.LegionGeneration.GENESIS &&
                metadata.legionRarity == ILegionMetadataStore.LegionRarity.LEGENDARY;
        } catch Error(
            string memory /*reason*/
        ) {
            return false;
        } catch Panic(uint256) {
            return false;
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            return false;
        }
    }

    function getNftBoost(
        address _nft,
        uint256 _tokenId,
        uint256 _amount
    ) public view virtual returns (uint256) {
        if (_nft == treasure) {
            return getTreasureBoost(_tokenId, _amount);
        } else if (_nft == legion) {
            try ILegionMetadataStore(legionMetadataStore).metadataForLegion(_tokenId) returns (
                ILegionMetadataStore.LegionMetadata memory metadata
            ) {
                return getLegionBoost(uint256(metadata.legionGeneration), uint256(metadata.legionRarity));
            } catch Error(
                string memory /*reason*/
            ) {
                return 0;
            } catch Panic(uint256) {
                return 0;
            } catch (
                bytes memory /*lowLevelData*/
            ) {
                return 0;
            }
        }

        return 0;
    }

    function _recalculateLpAmount(address _user) internal virtual {
        uint256 nftBoost = boosts[_user];

        uint256[] memory depositIds = allUserDepositIds[_user].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            uint256 depositId = depositIds[i];
            UserInfo storage user = userInfo[_user][depositId];

            (uint256 lockBoost, ) = getLockBoost(user.lock);
            uint256 _amount = user.depositAmount;
            uint256 newlLpAmount = _amount + (_amount * (lockBoost + nftBoost)) / ONE;
            uint256 oldLpAmount = user.lpAmount;

            if (newlLpAmount > oldLpAmount) {
                uint256 lpDiff = newlLpAmount - oldLpAmount;
                user.rewardDebt += ((lpDiff * accMagicPerShare) / ONE).toInt256();
                totalLpToken += lpDiff;
                user.lpAmount += lpDiff;
            } else if (newlLpAmount < oldLpAmount) {
                uint256 lpDiff = oldLpAmount - newlLpAmount;
                user.rewardDebt -= ((lpDiff * accMagicPerShare) / ONE).toInt256();
                totalLpToken -= lpDiff;
                user.lpAmount -= lpDiff;
            }
        }
    }

    function addExcludedAddress(address _exclude) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) updateRewards {
        require(excludedAddresses.add(_exclude), "Address already excluded");
    }

    function removeExcludedAddress(address _excluded) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) updateRewards {
        require(excludedAddresses.remove(_excluded), "Address is not excluded");
    }

    function setUtilizationOverride(uint256 _utilizationOverride)
        external
        virtual
        onlyRole(ATLAS_MINE_ADMIN_ROLE)
        updateRewards
    {
        utilizationOverride = _utilizationOverride;
    }

    function setMagicToken(address _magic) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) {
        magic = IERC20Upgradeable(_magic);
    }

    function setTreasure(address _treasure) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) {
        treasure = _treasure;
    }

    function setLegion(address _legion) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) {
        legion = _legion;
    }

    function setLegionMetadataStore(address _legionMetadataStore) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) {
        legionMetadataStore = _legionMetadataStore;
    }

    function setLegionBoostMatrix(uint256[][] memory _legionBoostMatrix)
        external
        virtual
        onlyRole(ATLAS_MINE_ADMIN_ROLE)
    {
        legionBoostMatrix = _legionBoostMatrix;
    }

    /// @notice EMERGENCY ONLY
    function toggleUnlockAll() external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) updateRewards {
        unlockAll = unlockAll ? false : true;
    }

    function withdrawUndistributedRewards(address _to) external virtual onlyRole(ATLAS_MINE_ADMIN_ROLE) updateRewards {
        uint256 _totalUndistributedRewards = totalUndistributedRewards;
        totalUndistributedRewards = 0;

        magic.safeTransfer(_to, _totalUndistributedRewards);
        emit UndistributedRewardsWithdraw(_to, _totalUndistributedRewards);
    }

    function getTreasureBoost(uint256 _tokenId, uint256 _amount) public pure virtual returns (uint256 boost) {
        if (_tokenId == 39) {
            // Ancient Relic 8%
            boost = 75e15;
        } else if (_tokenId == 46) {
            // Bag of Rare Mushrooms 6.2%
            boost = 62e15;
        } else if (_tokenId == 47) {
            // Bait for Monsters 7.3%
            boost = 73e15;
        } else if (_tokenId == 48) {
            // Beetle-wing 0.8%
            boost = 8e15;
        } else if (_tokenId == 49) {
            // Blue Rupee 1.5%
            boost = 15e15;
        } else if (_tokenId == 51) {
            // Bottomless Elixir 7.6%
            boost = 76e15;
        } else if (_tokenId == 52) {
            // Cap of Invisibility 7.6%
            boost = 76e15;
        } else if (_tokenId == 53) {
            // Carriage 6.1%
            boost = 61e15;
        } else if (_tokenId == 54) {
            // Castle 7.3%
            boost = 71e15;
        } else if (_tokenId == 68) {
            // Common Bead 5.6%
            boost = 56e15;
        } else if (_tokenId == 69) {
            // Common Feather 3.4%
            boost = 34e15;
        } else if (_tokenId == 71) {
            // Common Relic 2.2%
            boost = 22e15;
        } else if (_tokenId == 72) {
            // Cow 5.8%
            boost = 58e15;
        } else if (_tokenId == 73) {
            // Diamond 0.8%
            boost = 8e15;
        } else if (_tokenId == 74) {
            // Divine Hourglass 6.3%
            boost = 63e15;
        } else if (_tokenId == 75) {
            // Divine Mask 5.7%
            boost = 57e15;
        } else if (_tokenId == 76) {
            // Donkey 1.2%
            boost = 12e15;
        } else if (_tokenId == 77) {
            // Dragon Tail 0.8%
            boost = 8e15;
        } else if (_tokenId == 79) {
            // Emerald 0.8%
            boost = 8e15;
        } else if (_tokenId == 82) {
            // Favor from the Gods 5.6%
            boost = 56e15;
        } else if (_tokenId == 91) {
            // Framed Butterfly 5.8%
            boost = 58e15;
        } else if (_tokenId == 92) {
            // Gold Coin 0.8%
            boost = 8e15;
        } else if (_tokenId == 93) {
            // Grain 3.2%
            boost = 32e15;
        } else if (_tokenId == 94) {
            // Green Rupee 3.3%
            boost = 33e15;
        } else if (_tokenId == 95) {
            // Grin 15.7%
            boost = 157e15;
        } else if (_tokenId == 96) {
            // Half-Penny 0.8%
            boost = 8e15;
        } else if (_tokenId == 97) {
            // Honeycomb 15.8%
            boost = 158e15;
        } else if (_tokenId == 98) {
            // Immovable Stone 7.2%
            boost = 72e15;
        } else if (_tokenId == 99) {
            // Ivory Breastpin 6.4%
            boost = 64e15;
        } else if (_tokenId == 100) {
            // Jar of Fairies 5.3%
            boost = 53e15;
        } else if (_tokenId == 103) {
            // Lumber 3%
            boost = 30e15;
        } else if (_tokenId == 104) {
            // Military Stipend 6.2%
            boost = 62e15;
        } else if (_tokenId == 105) {
            // Mollusk Shell 6.7%
            boost = 67e15;
        } else if (_tokenId == 114) {
            // Ox 1.6%
            boost = 16e15;
        } else if (_tokenId == 115) {
            // Pearl 0.8%
            boost = 8e15;
        } else if (_tokenId == 116) {
            // Pot of Gold 5.8%
            boost = 58e15;
        } else if (_tokenId == 117) {
            // Quarter-Penny 0.8%
            boost = 8e15;
        } else if (_tokenId == 132) {
            // Red Feather 6.4%
            boost = 64e15;
        } else if (_tokenId == 133) {
            // Red Rupee 0.8%
            boost = 8e15;
        } else if (_tokenId == 141) {
            // Score of Ivory 6%
            boost = 60e15;
        } else if (_tokenId == 151) {
            // Silver Coin 0.8%
            boost = 8e15;
        } else if (_tokenId == 152) {
            // Small Bird 6%
            boost = 60e15;
        } else if (_tokenId == 153) {
            // Snow White Feather 6.4%
            boost = 64e15;
        } else if (_tokenId == 161) {
            // Thread of Divine Silk 7.3%
            boost = 73e15;
        } else if (_tokenId == 162) {
            // Unbreakable Pocketwatch 5.9%
            boost = 59e15;
        } else if (_tokenId == 164) {
            // Witches Broom 5.1%
            boost = 51e15;
        }

        boost = boost * _amount;
    }

    function _vestedPrincipal(address _user, uint256 _depositId) internal virtual returns (uint256 amount) {
        amount = calcualteVestedPrincipal(_user, _depositId);
        UserInfo storage user = userInfo[_user][_depositId];
        user.vestingLastUpdate = block.timestamp;
    }

    function _addDeposit(address _user) internal virtual returns (UserInfo storage user, uint256 newDepositId) {
        // start depositId from 1
        newDepositId = ++currentId[_user];
        allUserDepositIds[_user].add(newDepositId);
        user = userInfo[_user][newDepositId];
    }

    function _removeDeposit(address _user, uint256 _depositId) internal virtual {
        require(allUserDepositIds[_user].remove(_depositId), "depositId !exists");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IMasterOfCoin {
    function requestRewards() external returns (uint256 rewardsPaid);

    function getPendingRewards(address _stream) external view returns (uint256 pendingRewards);

    function setWithdrawStamp() external;

    function setStaticAmount(bool set) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILegionMetadataStore {
    // As this will likely change in the future, this should not be used to store state, but rather
    // as parameters and return values from functions.
    struct LegionMetadata {
        LegionGeneration legionGeneration;
        LegionClass legionClass;
        LegionRarity legionRarity;
        uint8 questLevel;
        uint8 craftLevel;
        uint8[6] constellationRanks;
        uint256 oldId;
    }

    enum Constellation {
        FIRE,
        EARTH,
        WIND,
        WATER,
        LIGHT,
        DARK
    }

    enum LegionRarity {
        LEGENDARY,
        RARE,
        SPECIAL,
        UNCOMMON,
        COMMON,
        RECRUIT
    }

    enum LegionClass {
        RECRUIT,
        SIEGE,
        FIGHTER,
        ASSASSIN,
        RANGED,
        SPELLCASTER,
        RIVERMAN,
        NUMERAIRE,
        ALL_CLASS,
        ORIGIN
    }

    enum LegionGeneration {
        GENESIS,
        AUXILIARY,
        RECRUIT
    }

    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(
        address _owner,
        uint256 _tokenId,
        LegionGeneration _generation,
        LegionClass _class,
        LegionRarity _rarity,
        uint256 _oldId
    ) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(
        uint256 _tokenId,
        Constellation _constellation,
        uint8 _to
    ) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns (LegionMetadata memory);

    // Returns the tokenUri for the given token.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ILegionMetadataStore.sol";

contract LegionMetadataStore is Initializable, ILegionMetadataStore {
    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(
        address indexed _owner,
        uint256 indexed _tokenId,
        LegionGeneration _generation,
        LegionClass _class,
        LegionRarity _rarity
    );

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint256) internal idToOldId;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    mapping(LegionGeneration => mapping(LegionClass => mapping(LegionRarity => mapping(uint256 => string))))
        internal _genToClassToRarityToOldIdToUri;

    function initialize() external initializer {}

    function setInitialMetadataForLegion(
        address _owner,
        uint256 _tokenId,
        LegionGeneration _generation,
        LegionClass _class,
        LegionRarity _rarity,
        uint256 _oldId
    ) external override {
        idToGeneration[_tokenId] = _generation;
        idToClass[_tokenId] = _class;
        idToRarity[_tokenId] = _rarity;
        idToOldId[_tokenId] = _oldId;

        // Initial quest/craft level is 1.
        idToQuestLevel[_tokenId] = 1;
        idToCraftLevel[_tokenId] = 1;

        emit LegionCreated(_owner, _tokenId, _generation, _class, _rarity);
    }

    function increaseQuestLevel(uint256 _tokenId) external override {
        idToQuestLevel[_tokenId]++;

        emit LegionQuestLevelUp(_tokenId, idToQuestLevel[_tokenId]);
    }

    function increaseCraftLevel(uint256 _tokenId) external override {
        idToCraftLevel[_tokenId]++;

        emit LegionCraftLevelUp(_tokenId, idToCraftLevel[_tokenId]);
    }

    function increaseConstellationRank(
        uint256 _tokenId,
        Constellation _constellation,
        uint8 _to
    ) external override {
        idToConstellationRanks[_tokenId][uint256(_constellation)] = _to;

        emit LegionConstellationRankUp(_tokenId, _constellation, _to);
    }

    function metadataForLegion(uint256 _tokenId) external view override returns (LegionMetadata memory) {
        return
            LegionMetadata(
                idToGeneration[_tokenId],
                idToClass[_tokenId],
                idToRarity[_tokenId],
                idToQuestLevel[_tokenId],
                idToCraftLevel[_tokenId],
                idToConstellationRanks[_tokenId],
                idToOldId[_tokenId]
            );
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return
            _genToClassToRarityToOldIdToUri[idToGeneration[_tokenId]][idToClass[_tokenId]][idToRarity[_tokenId]][
                idToOldId[_tokenId]
            ];
    }

    function setTokenUriForGenClassRarityOldId(
        LegionGeneration _gen,
        LegionClass _class,
        LegionRarity _rarity,
        uint256 _oldId,
        string calldata _uri
    ) external {
        _genToClassToRarityToOldIdToUri[_gen][_class][_rarity][_oldId] = _uri;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../BattleflyFounderVaultV08.sol";
import "../interfaces/IBattleflyAtlasStakerV02.sol";
import "../interfaces/vaults/IBattleflyTreasuryFlywheelVault.sol";
import "../interfaces/IBattlefly.sol";
import "../interfaces/IAtlasMine.sol";
import "../interfaces/IBattleflyFounderVault.sol";

contract BattleflyTreasuryFlywheelVault is
    IBattleflyTreasuryFlywheelVault,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @dev Immutable states
     */
    IERC20Upgradeable public MAGIC;
    IBattleflyAtlasStakerV02 public ATLAS_STAKER;
    IBattleflyFounderVault public FOUNDER_VAULT_V2;
    address public BATTLEFLY_BOT;
    uint256 public V2_VAULT_PERCENTAGE;
    uint256 public TREASURY_PERCENTAGE;
    uint256 public DENOMINATOR;
    IAtlasMine.Lock public TREASURY_LOCK;
    EnumerableSetUpgradeable.UintSet depositIds;
    uint256 public pendingDeposits;
    uint256 public activeRestakeDepositId;
    uint256 public pendingTreasuryAmountToStake;

    /**
     * @dev User stake data
     *      { depositId } => { User stake data }
     */
    mapping(uint256 => UserStake) public userStakes;

    function initialize(
        address _magic,
        address _atlasStaker,
        address _battleflyFounderVaultV2,
        address _battleflyBot
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        require(_magic != address(0), "BattleflyTreasuryFlywheelVault: invalid address");
        require(_atlasStaker != address(0), "BattleflyTreasuryFlywheelVault: invalid address");
        require(_battleflyFounderVaultV2 != address(0), "BattleflyTreasuryFlywheelVault: invalid address");
        require(_battleflyBot != address(0), "BattleflyTreasuryFlywheelVault: invalid address");

        MAGIC = IERC20Upgradeable(_magic);
        ATLAS_STAKER = IBattleflyAtlasStakerV02(_atlasStaker);
        FOUNDER_VAULT_V2 = IBattleflyFounderVault(_battleflyFounderVaultV2);
        BATTLEFLY_BOT = _battleflyBot;

        V2_VAULT_PERCENTAGE = 5000;
        TREASURY_PERCENTAGE = 95000;
        DENOMINATOR = 100000;
        TREASURY_LOCK = IAtlasMine.Lock.twoWeeks;
        MAGIC.approve(address(ATLAS_STAKER), 2**256 - 1);
    }

    /**
     * @dev Deposit funds to AtlasStaker
     */
    function deposit(uint128 _amount) external override nonReentrant onlyOwner returns (uint256 atlasStakerDepositId) {
        MAGIC.safeTransferFrom(msg.sender, address(this), _amount);
        atlasStakerDepositId = _deposit(uint256(_amount));
    }

    /**
     * @dev Withdraw staked funds from AtlasStaker
     */
    function withdraw(uint256[] memory _depositIds, address user)
        public
        override
        nonReentrant
        onlyOwner
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            amount += _withdraw(_depositIds[i], user);
        }
    }

    /**
     * @dev Withdraw all from AtlasStaker. This is only possible when the retention period of 14 epochs has passed.
     * The retention period is started when a withdrawal for the stake is requested.
     */
    function withdrawAll(address user) public override nonReentrant onlyOwner returns (uint256 amount) {
        uint256[] memory ids = depositIds.values();
        require(ids.length > 0, "BattleflyTreasuryFlywheelVault: No deposited funds");
        for (uint256 i = 0; i < ids.length; i++) {
            if (ATLAS_STAKER.canWithdraw(ids[i])) {
                amount += _withdraw(ids[i], user);
            }
        }
    }

    /**
     * @dev Request a withdrawal from AtlasStaker. This works with a retention period of 14 epochs.
     * Once the retention period has passed, the stake can be withdrawn.
     */
    function requestWithdrawal(uint256[] memory _depositIds) public override onlyOwner {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            ATLAS_STAKER.requestWithdrawal(_depositIds[i]);
            emit RequestWithdrawal(_depositIds[i]);
        }
    }

    /**
     * @dev Claim emission from AtlasStaker
     */
    function claim(uint256 _depositId, address user) public override nonReentrant onlyOwner returns (uint256 emission) {
        emission = _claim(_depositId, user);
    }

    /**
     * @dev Claim all emissions from AtlasStaker
     */
    function claimAll(address user) external override nonReentrant onlyOwner returns (uint256 amount) {
        uint256[] memory ids = depositIds.values();
        require(ids.length > 0, "BattleflyTreasuryFlywheelVault: No deposited funds");

        for (uint256 i = 0; i < ids.length; i++) {
            amount += _claim(ids[i], user);
        }
    }

    /**
     * @dev Claim all emissions from AtlasStaker, send percentage to V2 Vault and restake.
     */
    function claimAllAndRestake() external override nonReentrant onlyBattleflyBot returns (uint256 amount) {
        uint256[] memory ids = depositIds.values();
        for (uint256 i = 0; i < ids.length; i++) {
            if (getClaimableEmission(ids[i]) > 0) {
                amount += _claim(ids[i], address(this));
            }
        }
        amount = amount + pendingDeposits;
        uint256 v2VaultAmount = (amount * V2_VAULT_PERCENTAGE) / DENOMINATOR;
        uint256 treasuryAmount = (amount * TREASURY_PERCENTAGE) / DENOMINATOR;
        if (v2VaultAmount > 0) {
            MAGIC.safeApprove(address(FOUNDER_VAULT_V2), v2VaultAmount);
            FOUNDER_VAULT_V2.topupTodayEmission(v2VaultAmount);
        }
        pendingTreasuryAmountToStake += treasuryAmount;
        if (activeRestakeDepositId == 0 && pendingTreasuryAmountToStake > 0) {
            activeRestakeDepositId = _deposit(pendingTreasuryAmountToStake);
            pendingTreasuryAmountToStake = 0;
        } else if (activeRestakeDepositId != 0 && canWithdraw(activeRestakeDepositId)) {
            uint256 withdrawn = _withdraw(activeRestakeDepositId, address(this));
            uint256 toDeposit = withdrawn + pendingTreasuryAmountToStake;
            activeRestakeDepositId = _deposit(toDeposit);
            pendingTreasuryAmountToStake = 0;
        } else if (activeRestakeDepositId != 0 && canRequestWithdrawal(activeRestakeDepositId)) {
            ATLAS_STAKER.requestWithdrawal(activeRestakeDepositId);
        }
        pendingDeposits = 0;
    }

    function topupMagic(uint256 amount) public override nonReentrant {
        require(amount > 0);
        MAGIC.safeTransferFrom(msg.sender, address(this), amount);
        pendingDeposits += amount;
        emit TopupMagic(msg.sender, amount);
    }

    // ================ INTERNAL ================

    /**
     * @dev Withdraw a stake from AtlasStaker (Only possible when the retention period has passed)
     */
    function _withdraw(uint256 _depositId, address user) internal returns (uint256 amount) {
        require(ATLAS_STAKER.canWithdraw(_depositId), "BattleflyTreasuryFlywheelVault: stake not yet unlocked");
        amount = ATLAS_STAKER.withdraw(_depositId);
        MAGIC.safeTransfer(user, amount);
        depositIds.remove(_depositId);
        delete userStakes[_depositId];
        emit WithdrawPosition(_depositId, amount);
    }

    /**
     * @dev Claim emission from AtlasStaker
     */
    function _claim(uint256 _depositId, address user) internal returns (uint256 emission) {
        emission = ATLAS_STAKER.claim(_depositId);
        MAGIC.safeTransfer(user, emission);
        emit ClaimEmission(_depositId, emission);
    }

    function _deposit(uint256 _amount) internal returns (uint256 atlasStakerDepositId) {
        atlasStakerDepositId = ATLAS_STAKER.deposit(_amount, TREASURY_LOCK);
        IBattleflyAtlasStakerV02.VaultStake memory vaultStake = ATLAS_STAKER.getVaultStake(atlasStakerDepositId);

        UserStake storage userStake = userStakes[atlasStakerDepositId];
        userStake.amount = _amount;
        userStake.lockAt = vaultStake.lockAt;
        userStake.owner = address(this);
        userStake.lock = TREASURY_LOCK;

        depositIds.add(atlasStakerDepositId);

        emit NewUserStake(atlasStakerDepositId, _amount, vaultStake.unlockAt, address(this), TREASURY_LOCK);
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
     * @dev Get the deposit ids
     */
    function getDepositIds() public view override returns (uint256[] memory ids) {
        ids = depositIds.values();
    }

    /**
     * @dev Return the name of the vault
     */
    function getName() public pure override returns (string memory) {
        return "Treasury Flywheel Vault";
    }

    // ================== MODIFIERS ==================

    modifier onlyBattleflyBot() {
        require(msg.sender == BATTLEFLY_BOT, "BattleflyTreasuryFlywheelVault: caller is not a battlefly bot");
        _;
    }

    // ================== EVENTS ==================
    event NewUserStake(uint256 depositId, uint256 amount, uint256 unlockAt, address owner, IAtlasMine.Lock lock);
    event UpdateUserStake(uint256 depositId, uint256 amount, uint256 unlockAt, address owner, IAtlasMine.Lock lock);
    event ClaimEmission(uint256 depositId, uint256 emission);
    event WithdrawPosition(uint256 depositId, uint256 amount);
    event RequestWithdrawal(uint256 depositId);
    event TopupMagic(address sender, uint256 amount);

    event AddedUser(address vault);
    event RemovedUser(address vault);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

    // ============================================ INITIALIZE ==============================================
    function initialize(
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
    }

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

        for (uint256 i = 0; i < FounderStakeOfOwner[msg.sender].length(); i++) {
            totalReward += _claimByStakeId(FounderStakeOfOwner[msg.sender].at(i));
        }

        require(totalReward > 0, "No reward to claim");
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
            totalWithdraw += FounderStakes[stakeId].amount;
            _withdrawByStakeId(stakeId);
        }
        _checkStakingAmount(totalWithdraw);
    }

    function _withdrawByStakeId(uint256 stakeId) internal {
        FounderStake storage stake = FounderStakes[stakeId];
        _claimByStakeId(stakeId);
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
        stake.lastClaimedDay = DaysSinceStart;
        magic.safeTransfer(stake.owner, totalReward);
        emit Claim(stake.owner, stakeId, totalReward);
        return totalReward;
    }

    /**
     * @dev Withdraw a list of founder tokens
     */
    function withdraw(uint256[] memory founderIds) external nonReentrant {
        require(founderIds.length > 0, "No Founder to withdraw");
        uint256 totalWithdraw = 0;
        for (uint256 i = 0; i < founderIds.length; i++) {
            uint256 stakeId = stakeIdOfFounder[founderIds[i]];
            require(FounderStakes[stakeId].owner == msg.sender, "Not your stake");
            _claimBeforeWithdraw(founderIds[i]);
            _withdraw(founderIds[i]);
            totalWithdraw++;
        }
        _checkStakingAmount(totalWithdraw);
    }

    function _checkStakingAmount(uint256 totalWithdraw) internal view {
        uint256 stakeableAmountPerFounder = founderTypeID == 150
            ? BattleflyFoundersFlywheelVault.STAKING_LIMIT_V1()
            : BattleflyFoundersFlywheelVault.STAKING_LIMIT_V2();
        uint256 currentlyRemaining = BattleflyFoundersFlywheelVault.remainingStakeableAmount(msg.sender);
        uint256 currentlyStaked = BattleflyFoundersFlywheelVault.getStakedAmount(msg.sender);
        uint256 remainingAfterSubstraction = (stakeableAmountPerFounder * totalWithdraw) <= currentlyRemaining
            ? currentlyRemaining - stakeableAmountPerFounder * totalWithdraw
            : 0;
        require(currentlyStaked <= remainingAfterSubstraction, "Pls withdraw from FlywheelVault first");
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

    function _claimAllFromStaker() private returns (uint256 amount) {
        uint256[] memory ids = depositIds.values();
        for (uint256 i = 0; i < ids.length; i++) {
            (uint256 pending, ) = BattleflyStakerV2.getClaimableEmission(ids[i]);
            if (pending > 0) {
                amount += BattleflyStakerV2.claim(ids[i]);
            }
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
    function claimDailyEmission() public onlyBattleflyBot nonReentrant {
        uint256 currentDay = DaysSinceStart + 1;

        uint256 todayTotalEmission = _claimAllFromStaker();

        uint256 todayTotalFounderNFTs = _updateTotalStakingFounders(currentDay);

        uint256 stakeBackAmount;
        uint256 v2VaultAmount;
        uint256 treasuryAmount;
        uint256 founderEmission;
        if (todayTotalEmission != 0) {
            stakeBackAmount = ((todayTotalEmission * stakeBackPercent) / PERCENT_DENOMINATOR);
            _stakeBack(stakeBackAmount + pendingFounderEmission);

            v2VaultAmount = (todayTotalEmission * v2VaultPercent) / PERCENT_DENOMINATOR;
            if (v2VaultAmount != 0) battleflyFounderVaultV2.topupTodayEmission(v2VaultAmount);

            treasuryAmount = (todayTotalEmission * treasuryPercent) / PERCENT_DENOMINATOR;
            if (treasuryAmount != 0) {
                magic.approve(address(TREASURY_VAULT), treasuryAmount);
                TREASURY_VAULT.topupMagic(treasuryAmount);
            }
            founderEmission += todayTotalEmission - stakeBackAmount - v2VaultAmount - treasuryAmount;
        } else if (pendingFounderEmission > 0) {
            _stakeBack(pendingFounderEmission);
        } else {
            _stakeBack(0);
        }
        totalEmission += founderEmission;
        DaysSinceStart = currentDay;
        DailyFounderEmissions[DaysSinceStart] = DailyFounderEmission({
            totalEmission: founderEmission,
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
    }

    /**
     * @dev Withdraw all withdrawable deposit ids from the vault in the Atlas Staker
     */
    function withdrawAllFromStaker() external onlyAdminAccess {
        uint256[] memory ids = depositIds.values();
        withdrawFromStaker(ids);
    }

    function withdrawFromStaker(uint256[] memory ids) public onlyAdminAccess {
        claimDailyEmission();
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
    function setTreasuryVault(address _treasuryAddress) external onlyAdminAccess {
        require(_treasuryAddress != address(0));
        TREASURY_VAULT = IBattleflyTreasuryFlywheelVault(_treasuryAddress);
    }

    //Must be called right after init
    /**
     * @dev Set the flywheel vault address
     */
    function setFlywheelVault(address vault) external onlyOwner {
        require(vault != address(0));
        BattleflyFoundersFlywheelVault = IBattleflyFoundersFlywheelVault(vault);
    }

    //Must be called right after init
    /**
     * @dev Set the battlefly bot address
     */
    function setBattleflyBot(address _battleflyBot) external onlyOwner {
        require(_battleflyBot != address(0));
        BattleflyBot = _battleflyBot;
    }

    //Must be called right after init
    /**
     * @dev Set the battlefly staker address
     */
    function setBattleflyStaker(address staker) external onlyOwner {
        require(staker != address(0));
        BattleflyStakerV2 = IBattleflyAtlasStakerV02(staker);
        // Approve the AtlasStaker contract to spend the magic
        magic.approve(address(BattleflyStakerV2), 2**256 - 1);
    }

    //Must be called right after init
    /**
     * @dev Set the founder vault address
     */
    function setFounderVaultV2(address founderVault) external onlyOwner {
        require(founderVault != address(0));
        battleflyFounderVaultV2 = IBattleflyFounderVault(founderVault);
        // Approve the FounderVault contract to spend the magic
        magic.approve(address(battleflyFounderVaultV2), 2**256 - 1);
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

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);

    function setPause(bool _paused) external;

    function depositIdsOfVault(address vault) external view returns (uint256[] memory depositIds);

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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IBattlefly is IERC721EnumerableUpgradeable {
    function mintBattlefly(address receiver, uint256 battleflyType) external returns (uint256);

    function mintBattleflies(
        address receiver,
        uint256 _battleflyType,
        uint256 amount
    ) external returns (uint256[] memory);

    function getBattleflyType(uint256) external view returns (uint256);
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyFlywheelVault {
    function getStakeAmount(address user) external view returns (uint256, uint256);

    function stakeableAmountPerV1() external view returns (uint256);

    function stakeableAmountPerV2() external view returns (uint256);

    function stakeableAmountPerFounder(address vault) external view returns (uint256);
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

    function remainingStakeableAmount(address user) external view returns (uint256 remaining);

    function getStakedAmount(address user) external view returns (uint256 amount);

    function getDepositIdsOfUser(address user) external view returns (uint256[] memory depositIds);

    function getName() external pure returns (string memory);

    function STAKING_LIMIT_V1() external view returns (uint256);

    function STAKING_LIMIT_V2() external view returns (uint256);
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IMod is IERC721EnumerableUpgradeable {
    function mintMod(address receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../BattleflyFounderVaultV08.sol";
import "../interfaces/IBattleflyAtlasStakerV02.sol";
import "../interfaces/vaults/IBattleflyFoundersFlywheelVault.sol";
import "../interfaces/IBattlefly.sol";
import "../interfaces/IAtlasMine.sol";
import "../interfaces/IBattleflyFounderVault.sol";

contract BattleflyFoundersFlywheelVault is
    IBattleflyFoundersFlywheelVault,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @dev Immutable states
     */
    IERC20Upgradeable public MAGIC;
    IBattleflyAtlasStakerV02 public ATLAS_STAKER;
    IBattleflyFounderVault public FOUNDER_VAULT_V1;
    IBattleflyFounderVault public FOUNDER_VAULT_V2;
    uint256 public override STAKING_LIMIT_V1;
    uint256 public override STAKING_LIMIT_V2;

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

    function initialize(
        address _magic,
        address _atlasStaker,
        address _battleflyFounderVaultV1,
        address _battleflyFounderVaultV2
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        require(_magic != address(0), "BattleflyFlywheelVault: invalid address");
        require(_atlasStaker != address(0), "BattleflyFlywheelVault: invalid address");
        require(_battleflyFounderVaultV1 != address(0), "BattleflyFlywheelVault: invalid address");
        require(_battleflyFounderVaultV2 != address(0), "BattleflyFlywheelVault: invalid address");

        MAGIC = IERC20Upgradeable(_magic);
        ATLAS_STAKER = IBattleflyAtlasStakerV02(_atlasStaker);
        FOUNDER_VAULT_V1 = IBattleflyFounderVault(_battleflyFounderVaultV1);
        FOUNDER_VAULT_V2 = IBattleflyFounderVault(_battleflyFounderVaultV2);

        STAKING_LIMIT_V1 = 20000e18;
        STAKING_LIMIT_V2 = 10000e18;
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
        if (!whitelistedUsers[msg.sender]) {
            require(
                remainingStakeableAmount(msg.sender) >= _amount,
                "BattleflyFlywheelVault: amount exceeds stakeable amount"
            );
        }
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
    function withdraw(uint256[] memory _depositIds) public override nonReentrant returns (uint256 amount) {
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
    function requestWithdrawal(uint256[] memory _depositIds) public override {
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
    function whitelistUsers(address[] memory _users) external onlyOwner {
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
    function removeUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            removeUser(_users[i]);
        }
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
     * @dev Get the remaining stakeable MAGIC amount.
     */
    function remainingStakeableAmount(address user) public view override returns (uint256 remaining) {
        uint256 v1Amount = FOUNDER_VAULT_V1.balanceOf(user);
        uint256 v2Amount = FOUNDER_VAULT_V2.balanceOf(user);
        uint256 eligible = (v1Amount * STAKING_LIMIT_V1) + (v2Amount * STAKING_LIMIT_V2);
        uint256 staked = getStakedAmount(user);
        remaining = eligible >= staked ? eligible - staked : 0;
    }

    /**
     * @dev Get the staked amount of a particular user.
     */
    function getStakedAmount(address user) public view override returns (uint256 amount) {
        uint256[] memory depositIds = depositIdByUser[user].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            amount += userStakes[depositIds[i]].amount;
        }
    }

    /**
     * @dev Get the deposit ids of a user.
     */
    function getDepositIdsOfUser(address user) public view override returns (uint256[] memory depositIds) {
        depositIds = depositIdByUser[user].values();
    }

    /**
     * @dev Return the name of the vault
     */
    function getName() public pure override returns (string memory) {
        return "Founders Flywheel Vault";
    }

    // ================== MODIFIERS ==================

    modifier onlyMembers() {
        if (!whitelistedUsers[msg.sender]) {
            require(
                FOUNDER_VAULT_V1.balanceOf(msg.sender) + FOUNDER_VAULT_V2.balanceOf(msg.sender) > 0,
                "BattleflyWheelVault: caller has no staked Founder NFTs"
            );
        }
        _;
    }

    // ================== EVENTS ==================
    event NewUserStake(uint256 depositId, uint256 amount, uint256 unlockAt, address owner, IAtlasMine.Lock lock);
    event UpdateUserStake(uint256 depositId, uint256 amount, uint256 unlockAt, address owner, IAtlasMine.Lock lock);
    event ClaimEmission(uint256 depositId, uint256 emission);
    event WithdrawPosition(uint256 depositId, uint256 amount);
    event RequestWithdrawal(uint256 depositId);

    event AddedUser(address vault);
    event RemovedUser(address vault);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/IVault.sol";
import "../interfaces/IAtlasMine.sol";
import "../interfaces/IBattleflyAtlasStakerV02.sol";
import "../interfaces/ITestERC20.sol";

contract VaultMock is IVault {
    IBattleflyAtlasStakerV02 public STAKER;

    constructor(address _staker, address _magic) {
        STAKER = IBattleflyAtlasStakerV02(_staker);
        ITestERC20(_magic).approve(_staker, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        ITestERC20(_magic).mint(100000e18, address(this));
    }

    function deposit(uint128 _amount, IAtlasMine.Lock lock) public {
        STAKER.deposit(_amount, lock);
    }

    function withdraw(uint256 depositId) public {
        STAKER.withdraw(depositId);
    }

    function requestWithdrawal(uint256 depositId) public {
        STAKER.requestWithdrawal(depositId);
    }

    function claim(uint256 depositId) public {
        STAKER.claim(depositId);
    }

    function isAutoCompounded(uint256) public pure override returns (bool) {
        return false;
    }

    function updatePosition(uint256) public override {}
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IVault {
    function isAutoCompounded(uint256) external view returns (bool);

    function updatePosition(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestERC20 is IERC20 {
    function mint(uint256 amount, address receiver) external;
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMasterOfCoin.sol";
import "../interfaces/ITestERC20.sol";

contract MasterOfCoinMock is IMasterOfCoin {
    ITestERC20 public immutable magic;
    uint256 public previousWithdrawStamp;
    bool public staticAmount;

    constructor(address magic_) {
        magic = ITestERC20(magic_);
        previousWithdrawStamp = block.timestamp;
        staticAmount = true;
    }

    function requestRewards() external override returns (uint256 rewardsPaid) {
        if (staticAmount) {
            magic.mint(500 ether, msg.sender);
            return 500 ether;
        }
        uint256 secondsPassed = block.timestamp - previousWithdrawStamp;
        uint256 rewards = secondsPassed * 11574074e8;
        previousWithdrawStamp = block.timestamp;
        magic.mint(rewards, msg.sender);
        return rewards;
    }

    function getPendingRewards(address) external view override returns (uint256 pendingRewards) {
        if (staticAmount) {
            return 500 ether;
        }
        uint256 secondsPassed = block.timestamp - previousWithdrawStamp;
        uint256 rewards = secondsPassed * 11574074e8;
        return rewards;
    }

    function setWithdrawStamp() external override {
        previousWithdrawStamp = block.timestamp;
    }

    function setStaticAmount(bool set) external override {
        staticAmount = set;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMagicToken is IERC20 {}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract TestERC20 is ERC20 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor() ERC20("TestERC20", "MAGIC") {}

    function mint(uint256 amount, address receiver) public {
        _mint(receiver, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBattlefly.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IBattleflyGame.sol";

contract RevealStaking is ERC721HolderUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(address => bool) private adminAccess;
    IBattlefly private BattleflyContract;
    IERC20Upgradeable private MagicToken;
    uint256 public MagicAmountPerBattlefly;
    IBattleflyGame private BattleflyGame;
    mapping(address => EnumerableSetUpgradeable.UintSet) private StakingBattlefliesOfOwner;
    mapping(uint256 => address) public OwnerOfStakingBattlefly;
    mapping(uint256 => uint256) public MagicAmountOfStakingBattlefly;
    mapping(uint256 => bool) public NectarClaimed;

    uint8 constant COCOON_STAGE = 0;
    uint8 constant BATTLEFLY_STAGE = 1;

    uint8 constant NECTAR_ID = 0;

    event SetAdminAccess(address indexed user, bool access);
    event BulkStakeBattlefly(uint256[] tokenIds, address indexed user, uint256 totalMagicAmount);
    event BulkUnstakeBattlefly(uint256[] tokenIds, address indexed user, uint256 totalMagicAmount);

    function initialize(
        address batteflyGameContractAddress,
        address battleflyContractAddress,
        address magicTokenAddress,
        uint256 _MagicAmountPerBattlefly
    ) public initializer {
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        BattleflyContract = IBattlefly(battleflyContractAddress);
        MagicToken = IERC20Upgradeable(magicTokenAddress);
        MagicAmountPerBattlefly = _MagicAmountPerBattlefly;
        BattleflyGame = IBattleflyGame(batteflyGameContractAddress);
    }

    // ADMIN
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    //USER
    function stakingBattlefliesOfOwner(address user) external view returns (uint256[] memory) {
        return StakingBattlefliesOfOwner[user].values();
    }

    function bulkStakeBattlefly(uint256[] memory tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            OwnerOfStakingBattlefly[tokenId] = _msgSender();
            MagicAmountOfStakingBattlefly[tokenId] = MagicAmountPerBattlefly;
            StakingBattlefliesOfOwner[_msgSender()].add(tokenId);
            BattleflyContract.safeTransferFrom(_msgSender(), address(this), tokenId);
        }
        uint256 totalMagicAmount = MagicAmountPerBattlefly.mul(tokenIds.length);
        MagicToken.safeTransferFrom(_msgSender(), address(this), totalMagicAmount);
        emit BulkStakeBattlefly(tokenIds, _msgSender(), totalMagicAmount);
    }

    function bulkUnstakeBattlefly(
        uint256[] memory tokenIds,
        uint256[] memory battleflyStages,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        uint256 totalMagicAmount = 0;
        uint256 totalNectar = 0;
        address receiver = _msgSender();
        bytes32 payloadHash = keccak256(abi.encodePacked(tokenIds, battleflyStages));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);
        require(result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin], "Require admin access");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(OwnerOfStakingBattlefly[tokenId] == _msgSender(), "Require Staking Battlefly owner access");
            OwnerOfStakingBattlefly[tokenId] = address(0);
            totalMagicAmount = totalMagicAmount.add(MagicAmountOfStakingBattlefly[tokenId]);
            MagicAmountOfStakingBattlefly[tokenId] = 0;
            StakingBattlefliesOfOwner[_msgSender()].remove(tokenId);
            if (battleflyStages[i] == BATTLEFLY_STAGE && NectarClaimed[tokenId] == false) {
                NectarClaimed[tokenId] = true;
                totalNectar = totalNectar.add(10);
            }
            BattleflyContract.safeTransferFrom(address(this), receiver, tokenId);
        }
        if (totalMagicAmount != 0) MagicToken.safeTransfer(receiver, totalMagicAmount);
        if (totalNectar != 0) BattleflyGame.mintItems(NECTAR_ID, receiver, totalNectar);
        emit BulkUnstakeBattlefly(tokenIds, receiver, totalMagicAmount);
    }

    /**
     * @dev Returns the number of staking tokens in ``owner``'s account.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return StakingBattlefliesOfOwner[owner].length();
    }

    /**
     * @dev Returns the owner of the `tokenId` staking token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return OwnerOfStakingBattlefly[tokenId];
    }

    //modifier
    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyGame {
    function mintBattlefly(address receiver, uint256 battleflyType) external returns (uint256);

    function mintSpecialNFT(address receiver, uint256 specialNFTType) external returns (uint256);

    function mintBattleflies(
        address receiver,
        uint256 battleflyType,
        uint256 amount
    ) external returns (uint256[] memory);

    function mintSpecialNFTs(
        address receiver,
        uint256 specialNFTType,
        uint256 amount
    ) external returns (uint256[] memory);

    function mintItems(
        uint256 itemId,
        address receiver,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IBattleflyGame.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

contract FounderGenesisV2Sale is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    mapping(address => bool) private adminAccess;

    IBattleflyGame Game;
    uint256 FounderGenesisV2TokenType;
    uint256 public totalSellAmount;
    uint256 public soldAmount;
    uint256 public timeStart;
    uint256 public price;
    address public fundAddress;

    uint256 public discountPrice;
    uint256 public discountSoldAmount;
    uint256 public discountTimeStart;
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public ticketUsed;
    mapping(address => uint256) public mintedOfUser;

    event MintFounderGenesisV2(
        address indexed to,
        uint256 price,
        uint256 indexed specialNFTType,
        uint256 tokenId,
        address fundAddress,
        bytes32 indexed ticket
    );

    function initialize(address battleflyGameContractAddress) public initializer {
        __Ownable_init();
        Game = IBattleflyGame(battleflyGameContractAddress);
        FounderGenesisV2TokenType = 151;
        totalSellAmount = 0;
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdminAccess {
        merkleRoot = _merkleRoot;
    }

    function mintFounderGenesisV2WithDiscount(
        uint256 amount,
        uint256 allocation,
        bytes32[] calldata proof
    ) external payable {
        address to = _msgSender();
        require(discountSoldAmount + soldAmount + amount <= totalSellAmount, "Sold out");
        require(msg.value == discountPrice.mul(amount), "Not enough ETH");
        require(block.timestamp >= discountTimeStart, "Not time yet");
        require(amount + mintedOfUser[to] <= allocation, "Not enough allocation");
        bytes32 leaf = keccak256(abi.encodePacked(to, allocation));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "Not in merkle");
        mintedOfUser[to] += amount;
        discountSoldAmount += amount;
        uint256[] memory tokenIds = Game.mintSpecialNFTs(to, FounderGenesisV2TokenType, amount);
        if (fundAddress != address(0)) {
            (bool success, ) = payable(fundAddress).call{ value: address(this).balance }("");
            require(success, "Failed to send Ether");
        }
        for (uint256 i = 0; i < amount; i++) {
            emit MintFounderGenesisV2(to, discountPrice, FounderGenesisV2TokenType, tokenIds[i], fundAddress, "");
        }
    }

    function setDiscountSaleInfo(uint256 _timeStart, uint256 _price) external onlyAdminAccess {
        discountTimeStart = _timeStart;
        discountPrice = _price;
    }

    function setSaleInfo(
        uint256 _totalSellAmount,
        uint256 _timeStart,
        uint256 _price
    ) external onlyAdminAccess {
        totalSellAmount = _totalSellAmount;
        timeStart = _timeStart;
        price = _price;
    }

    // function setfundAddress(address _fundAddress) external onlyAdminAccess {
    //     fundAddress = _fundAddress;
    // }
    function mintFounderGenesisV2(uint256 amount) external payable {
        address to = _msgSender();
        require(discountSoldAmount + soldAmount + amount <= totalSellAmount, "Sold out");
        require(msg.value == price.mul(amount), "Not enough ETH");
        require(block.timestamp >= timeStart, "Not time yet");
        soldAmount += amount;
        uint256[] memory tokenIds = Game.mintSpecialNFTs(to, FounderGenesisV2TokenType, amount);
        if (fundAddress != address(0)) {
            (bool success, ) = payable(fundAddress).call{ value: address(this).balance }("");
            require(success, "Failed to send Ether");
        }
        for (uint256 i = 0; i < amount; i++) {
            emit MintFounderGenesisV2(to, price, FounderGenesisV2TokenType, tokenIds[i], fundAddress, "");
        }
    }

    // function withdraw(uint256 amount) external onlyAdminAccess {
    //     require(amount <= address(this).balance, "Not enough balance");
    //     (bool success, ) = payable(fundAddress).call{value: amount}("");
    //     require(success, "Failed to send Ether");
    // }
    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
library MerkleProof {
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IBattleflyGame.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

contract BattleflyWhitelist is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    mapping(address => mapping(uint256 => uint256)) public hasClaimedSpecialNFT;
    mapping(address => mapping(uint256 => uint256)) public hasClaimedBattlefly;
    bytes32 public merkleRootBattlefly;
    bytes32 public merkleRootSpecialNFT;

    mapping(address => bool) private adminAccess;
    IBattleflyGame Game;
    uint256 StartTime;
    uint256 EndTime;

    event ClaimBattlefly(address indexed to, uint256 amount, uint256 indexed battleflyType);
    event ClaimSpecialNFT(address indexed to, uint256 amount, uint256 indexed specialNFTType);

    function initialize(address battleflyGameContractAddress) public initializer {
        __Ownable_init();
        Game = IBattleflyGame(battleflyGameContractAddress);
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function setMerkleRootBattlefly(bytes32 merkleRoot) external onlyAdminAccess {
        merkleRootBattlefly = merkleRoot;
    }

    function setMerkleRootSpecialNFT(bytes32 merkleRoot) external onlyAdminAccess {
        merkleRootSpecialNFT = merkleRoot;
    }

    function setHasClaimedBattlefly(
        address user,
        uint256 battleflyType,
        uint256 value
    ) external onlyAdminAccess {
        hasClaimedBattlefly[user][battleflyType] = value;
    }

    function setHasClaimedSpecialNFT(
        address user,
        uint256 specialNFTType,
        uint256 value
    ) external onlyAdminAccess {
        hasClaimedSpecialNFT[user][specialNFTType] = value;
    }

    function setMintingTime(uint256 start, uint256 end) external onlyAdminAccess {
        StartTime = start;
        EndTime = end;
    }

    function claimBattlefly(
        uint256 allocatedAmount,
        uint256 mintingAmount,
        uint256 battleflyType,
        bytes32[] calldata proof
    ) external {
        address to = _msgSender();
        if (StartTime != 0) {
            require(block.timestamp >= StartTime, "Not start yet");
        }
        if (EndTime != 0) {
            require(block.timestamp <= EndTime, "Already finished");
        }
        require(hasClaimedBattlefly[to][battleflyType] + mintingAmount <= allocatedAmount, "Not enough allocation");
        bytes32 leaf = keccak256(abi.encodePacked(to, allocatedAmount, battleflyType));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRootBattlefly, leaf);
        require(isValidLeaf, "Not in merkle");

        hasClaimedBattlefly[to][battleflyType] += mintingAmount;

        for (uint256 i = 0; i < mintingAmount; i++) {
            Game.mintBattlefly(to, battleflyType);
        }
        emit ClaimBattlefly(to, mintingAmount, battleflyType);
    }

    function claimSpecialNFT(
        uint256 allocatedAmount,
        uint256 mintingAmount,
        uint256 specialNFTType,
        bytes32[] calldata proof
    ) external {
        address to = _msgSender();
        require(hasClaimedSpecialNFT[to][specialNFTType] + mintingAmount <= allocatedAmount, "Not enough allocation");
        bytes32 leaf = keccak256(abi.encodePacked(to, allocatedAmount, specialNFTType));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRootSpecialNFT, leaf);
        require(isValidLeaf, "Not in merkle");

        hasClaimedSpecialNFT[to][specialNFTType] += mintingAmount;

        for (uint256 i = 0; i < mintingAmount; i++) {
            Game.mintSpecialNFT(to, specialNFTType);
        }
        emit ClaimSpecialNFT(to, mintingAmount, specialNFTType);
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
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

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStaker.sol";

contract MockAtlasStaker is
    IBattleflyAtlasStaker,
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
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /// @notice MAGIC token
    /// @dev functionally immutable
    IERC20Upgradeable public magic;
    /// @notice The IAtlasMine
    /// @dev functionally immutable
    IAtlasMine public mine;

    // ============= Global Staking State ==============
    uint256 public constant ONE = 1e30;

    /// @notice Whether new stakes will get staked on the contract as scheduled. For emergencies
    bool public schedulePaused;
    /// @notice The total amount of staked token
    uint256 public totalStaked;
    /// @notice The total amount of share
    uint256 public totalShare;
    /// @notice All stakes currently active
    Stake[] public stakes;
    /// @notice Deposit ID of last stake. Also tracked in atlas mine
    uint256 public lastDepositId;
    /// @notice Rewards accumulated per share
    uint256 public accRewardsPerShare;

    // ============= Vault Staking State ==============
    mapping(address => bool) public battleflyVaults;

    /// @notice Each vault stake, keyed by vault contract address => deposit ID
    mapping(address => mapping(uint256 => VaultStake)) public vaultStake;
    /// @notice All deposit IDs fro a vault, enumerated
    mapping(address => EnumerableSetUpgradeable.UintSet) private allVaultDepositIds;
    /// @notice The current ID of the vault's last deposited stake
    mapping(address => uint256) public currentId;

    // ============= NFT Boosting State ==============

    /// @notice Holder of treasures and legions
    mapping(uint256 => bool) public legionsStaked;
    mapping(uint256 => uint256) public treasuresStaked;

    // ============= Operator State ==============

    IAtlasMine.Lock[] public allowedLocks;
    /// @notice Fee to contract operator. Only assessed on rewards.
    uint256 public fee;
    /// @notice Amount of fees reserved for withdrawal by the operator.
    uint256 public feeReserve;
    /// @notice Max fee the owner can ever take - 10%
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(address => mapping(uint256 => int256)) refundedFeeDebts;
    uint256 accRefundedFeePerShare;
    uint256 totalWhitelistedFeeShare;
    EnumerableSetUpgradeable.AddressSet whitelistedFeeVaults;
    mapping(address => bool) public superAdmins;

    /// @notice deposited but unstaked
    uint256 public unstakedDeposits;
    mapping(IAtlasMine.Lock => uint256) public unstakedDepositsByLock;
    address public constant TREASURY_WALLET = 0xF5411006eEfD66c213d2fd2033a1d340458B7226;
    /// @notice Intra-tx buffer for pending payouts
    uint256 public tokenBuffer;

    // ===========================================
    // ============== Post Upgrade ===============
    // ===========================================

    // ========================================== INITIALIZER ===========================================

    /**
     * @param _magic                The MAGIC token address.
     * @param _mine                 The IAtlasMine contract.
     *                              Maps to a timelock for IAtlasMine deposits.
     */
    function initialize(
        IERC20Upgradeable _magic,
        IAtlasMine _mine,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = _magic;
        mine = _mine;
        allowedLocks = _allowedLocks;
        fee = 1000;
        // Approve the mine
        magic.safeApprove(address(mine), 2**256 - 1);
        // approveNFTs();
    }

    // ======================================== VAULT OPERATIONS ========================================

    /**
     * @notice Make a new deposit into the Staker. The Staker will collect
     *         the tokens, to be later staked in atlas mine by the owner,
     *         according to the stake/unlock schedule.
     * @dev    Specified amount of token must be approved by the caller.
     *
     * @param _amount               The amount of tokens to deposit.
     */
    function deposit(uint256 _amount, IAtlasMine.Lock lock)
        public
        virtual
        override
        onlyBattleflyVaultOrOwner
        nonReentrant
        returns (uint256)
    {
        require(!schedulePaused, "new staking paused");
        _updateRewards();
        // Collect tokens
        uint256 newDepositId = _deposit(_amount, msg.sender, lock);
        magic.safeTransferFrom(msg.sender, address(this), _amount);
        return (newDepositId);
    }

    function _deposit(
        uint256 _amount,
        address _vault,
        IAtlasMine.Lock lock
    ) internal returns (uint256) {
        require(_amount > 0, "Deposit amount 0");
        bool validLock = false;
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == lock) {
                validLock = true;
                break;
            }
        }
        require(validLock, "Lock time not allowed");
        // Add vault stake
        uint256 newDepositId = ++currentId[_vault];
        allVaultDepositIds[_vault].add(newDepositId);
        VaultStake storage s = vaultStake[_vault][newDepositId];

        s.amount = _amount;
        (uint256 boost, uint256 lockTime) = getLockBoost(lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;

        uint256 vestingTime = mine.getVestingTime(lock);
        s.unlockAt = block.timestamp + lockTime + vestingTime + 1 days;
        s.rewardDebt = ((share * accRewardsPerShare) / ONE).toInt256();
        s.lock = lock;

        // Update global accounting
        totalStaked += _amount;
        totalShare += share;
        if (whitelistedFeeVaults.contains(_vault)) {
            totalWhitelistedFeeShare += share;
            refundedFeeDebts[_vault][newDepositId] = ((share * accRefundedFeePerShare) / ONE).toInt256();
        }
        // MAGIC tokens sit in contract. Added to pending stakes
        unstakedDeposits += _amount;
        unstakedDepositsByLock[lock] += _amount;
        emit VaultDeposit(_vault, newDepositId, _amount, s.unlockAt, s.lock);
        return newDepositId;
    }

    /**
     * @notice Withdraw a deposit from the Staker contract. Calculates
     *         pro rata share of accumulated MAGIC and distributes any
     *         earned rewards in addition to original deposit.
     *         There must be enough unlocked tokens to withdraw.
     *
     * @param depositId             The ID of the deposit to withdraw from.
     *
     */
    function withdraw(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        require(block.timestamp >= s.unlockAt, "Deposit locked");

        uint256 payout = _withdraw(s, depositId);
        magic.safeTransfer(msg.sender, payout);
    }

    /**
     * @notice Withdraw all eligible deposits from the staker contract.
     *         Will skip any deposits not yet unlocked. Will also
     *         distribute rewards for all stakes via 'withdraw'.
     *
     */
    function withdrawAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];

            if (s.amount > 0 && s.unlockAt > 0 && s.unlockAt <= block.timestamp) {
                tokenBuffer += _withdraw(s, depositIds[i]);
            }
        }
        magic.safeTransfer(msg.sender, tokenBuffer);
        tokenBuffer = 0;
    }

    /**
     * @dev Logic for withdrawing a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @dev An _amount argument larger than the total deposit amount will
     *      withdraw the entire deposit.
     *
     * @param s                     The VaultStake struct to withdraw from.
     * @param depositId             The ID of the deposit to withdraw from (for event).
     */
    function _withdraw(VaultStake storage s, uint256 depositId) internal returns (uint256 payout) {
        uint256 _amount = s.amount;

        // Unstake if we need to to ensure we can withdraw
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;
        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();
        if (whitelistedFeeVaults.contains(msg.sender)) {
            accumulatedRewards += ((share * accRefundedFeePerShare) / ONE).toInt256();
            accumulatedRewards -= refundedFeeDebts[msg.sender][depositId];
            totalWhitelistedFeeShare -= share;
            refundedFeeDebts[msg.sender][depositId] = 0;
        }
        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();
        payout = _amount + reward;

        // // Update vault accounting
        // s.amount -= _amount;
        // s.rewardDebt = 0;
        ///comment Archethect: Consider deleting the VaultStake object for gas optimization. s.unlockAt and s.lock can be zeroed as well.
        delete vaultStake[msg.sender][depositId];

        // Update global accounting
        totalStaked -= _amount;

        totalShare -= share;

        // If we need to unstake, unstake until we have enough
        if (payout > _totalUsableMagic()) {
            _unstakeToTarget(payout - _totalUsableMagic());
        }
        emit VaultWithdraw(msg.sender, depositId, _amount, reward);
    }

    /**
     * @notice Claim rewards without unstaking. Will fail if there
     *         are not enough tokens in the contract to claim rewards.
     *         Does not attempt to unstake.
     *
     * @param depositId             The ID of the deposit to claim rewards from.
     *
     */
    function claim(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        uint256 reward = _claim(s, depositId);
        magic.safeTransfer(msg.sender, reward);
        return reward;
    }

    /**
     * @notice Claim all possible rewards from the staker contract.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        return 0;
    }

    /**
     * @notice Claim all possible rewards from the staker contract then restake.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAllAndRestake(IAtlasMine.Lock lock) public onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];
            uint256 reward = _claim(s, depositIds[i]);
            tokenBuffer += reward;
        }
        _deposit(tokenBuffer, msg.sender, lock);
        tokenBuffer = 0;
        return totalReward;
    }

    /**
     * @dev Logic for claiming rewards on a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @param s                     The VaultStake struct to claim from.
     * @param depositId             The ID of the deposit to claim from (for event).
     */
    function _claim(VaultStake storage s, uint256 depositId) internal returns (uint256) {
        // Update accounting
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();

        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();
        if (whitelistedFeeVaults.contains(msg.sender)) {
            int256 accumulatedRefundedFee = ((share * accRefundedFeePerShare) / ONE).toInt256();
            reward += accumulatedRefundedFee.toUint256();
            reward -= refundedFeeDebts[msg.sender][depositId].toUint256();
            refundedFeeDebts[msg.sender][depositId] = accumulatedRefundedFee;
        }
        s.rewardDebt = accumulatedRewards;

        // Unstake if we need to to ensure we can withdraw
        if (reward > _totalUsableMagic()) {
            _unstakeToTarget(reward - _totalUsableMagic());
        }

        require(reward <= _totalUsableMagic(), "Not enough rewards to claim");
        emit VaultClaim(msg.sender, depositId, reward);
        return reward;
    }

    // ======================================= SUPER ADMIN OPERATIONS ========================================

    /**
     * @notice Stake a Treasure owned by the superAdmin into the Atlas Mine.
     *         Staked treasures will boost all vault deposits.
     * @dev    Any treasure must be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdminOrOwner {
        address treasureAddr = mine.treasure();
        require(IERC1155Upgradeable(treasureAddr).balanceOf(msg.sender, _tokenId) >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] += _amount;
        // First withdraw and approve
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, bytes(""));
        mine.stakeTreasure(_tokenId, _amount);
        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Unstake a Treasure from the Atlas Mine adn transfer to receiver.
     *
     * @param _receiver              The receiver .
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function unstakeTreasure(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlySuperAdminOrOwner {
        require(treasuresStaked[_tokenId] >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] -= _amount;
        address treasureAddr = mine.treasure();
        mine.unstakeTreasure(_tokenId, _amount);
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(address(this), _receiver, _tokenId, _amount, bytes(""));
        uint256 boost = mine.boosts(address(this));
        emit UnstakeNFT(_receiver, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Stake a Legion owned by the superAdmin into the Atlas Mine.
     *         Staked legions will boost all vault deposits.
     * @dev    Any legion be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function stakeLegion(uint256 _tokenId) external onlySuperAdminOrOwner {
        address legionAddr = mine.legion();
        require(IERC721Upgradeable(legionAddr).ownerOf(_tokenId) == msg.sender, "Not owner of legion");
        legionsStaked[_tokenId] = true;
        IERC721Upgradeable(legionAddr).safeTransferFrom(msg.sender, address(this), _tokenId);

        mine.stakeLegion(_tokenId);

        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Unstake a Legion from the Atlas Mine and return it to the superAdmin.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function unstakeLegion(address _receiver, uint256 _tokenId) external onlySuperAdminOrOwner {
        require(legionsStaked[_tokenId], "No legion");
        address legionAddr = mine.legion();
        delete legionsStaked[_tokenId];
        mine.unstakeLegion(_tokenId);

        // Distribute to superAdmin
        IERC721Upgradeable(legionAddr).safeTransferFrom(address(this), _receiver, _tokenId);
        uint256 boost = mine.boosts(address(this));

        emit UnstakeNFT(_receiver, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Stake any pending stakes before the current day. Callable
     *         by anybody. Any pending stakes will unlock according
     *         to the time this method is called, and the contract's defined
     *         lock time.
     */
    function stakeScheduled() external virtual override onlySuperAdminOrOwner {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            IAtlasMine.Lock lock = allowedLocks[i];
            _stakeInMine(unstakedDepositsByLock[lock], lock);
            unstakedDepositsByLock[lock] = 0;
        }
        unstakedDeposits = 0;
    }

    /**
     * @notice Unstake everything eligible for unstaking from Atlas Mine.
     *         Callable by owner. Should only be used in case of emergency
     *         or migration to a new contract, or if there is a need to service
     *         an unexpectedly large amount of withdrawals.
     *
     *         If unlockAll is set to true in the Atlas Mine, this can withdraw
     *         all stake.
     */
    function unstakeAllFromMine() external override onlySuperAdminOrOwner {
        // Unstake everything eligible
        _updateRewards();

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp) {
                continue;
            }

            // Withdraw position - auto-harvest
            mine.withdrawPosition(s.depositId, s.amount);
        }

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @notice Let owner unstake a specified amount as needed to make sure the contract is funded.
     *         Can be used to facilitate expected future withdrawals.
     *
     * @param target                The amount of tokens to reclaim from the mine.
     */
    function unstakeToTarget(uint256 target) external override onlySuperAdminOrOwner {
        _updateRewards();
        _unstakeToTarget(target);
    }

    /**
     * @notice Withdraw any accumulated reward fees to the treasury
     */
    function withdrawFeesToTreasury() external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        magic.safeTransfer(TREASURY_WALLET, amount);
        emit WithdrawFeesToTreasury(amount);
    }

    function stakeBackFeeTreasury(IAtlasMine.Lock lock) external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        emit WithdrawFeesToTreasury(amount);
        // magic.safeTransfer(TREASURY_WALLET, amount);
        _deposit(amount, TREASURY_WALLET, lock);
    }

    /**
     * @notice Whitelist vault from fees.
     *
     * @param _vault                Vault address.
     * @param isSet                 Whether to enable or disable the vault whitelist.
     */
    function setFeeWhitelistVault(address _vault, bool isSet) external onlyOwner {
        require(_vault != address(0), "Invalid Vault");
        if (isSet) {
            whitelistedFeeVaults.add(_vault);
            totalWhitelistedFeeShare += totalShareOf(_vault);
        } else {
            whitelistedFeeVaults.remove(_vault);
            totalWhitelistedFeeShare -= totalShareOf(_vault);
        }
        emit SetFeeWhitelistVault(_vault, isSet);
    }

    // ======================================= OWNER OPERATIONS =======================================

    function setBattleflyVault(address _vaultAddress, bool isSet) external onlyOwner {
        require(_vaultAddress != address(0), "Invalid vault");
        if (isSet) {
            require(battleflyVaults[_vaultAddress] == false, "Vault already set");
            battleflyVaults[_vaultAddress] = isSet;
        } else {
            require(allVaultDepositIds[_vaultAddress].length() == 0, "Vault is still active");
            delete battleflyVaults[_vaultAddress];
        }
        emit SetBattleflyVault(_vaultAddress, isSet);
    }

    /**
     * @notice Change the designated superAdmin, the address where treasures and
     *         legions are held. Staked NFTs can only be
     *         withdrawn to the current superAdmin address, regardless of which
     *         address the superAdmin was set to when it was staked.
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the superAdmin address.
     */
    function setBoostAdmin(address _superAdmin, bool isSet) external override onlyOwner {
        require(_superAdmin != address(0), "Invalid superAdmin");

        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Change the designated super admin, who manage the fee reverse
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the super admin address.
     */
    function setSuperAdmin(address _superAdmin, bool isSet) external onlyOwner {
        require(_superAdmin != address(0), "Invalid address");
        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Approve treasures and legions for withdrawal from the atlas mine.
     *         Called on startup, and should be called again in case contract
     *         addresses for treasures and legions ever change.
     *
     */
    function approveNFTs() public override onlyOwner {
        address treasureAddr = mine.treasure();
        IERC1155Upgradeable(treasureAddr).setApprovalForAll(address(mine), true);

        address legionAddr = mine.legion();
        IERC1155Upgradeable(legionAddr).setApprovalForAll(address(mine), true);
    }

    /**
     * @notice EMERGENCY ONLY - toggle pausing new scheduled stakes.
     *         If on, vaults can deposit, but stakes won't go to Atlas Mine.
     *         Can be used in case of Atlas Mine issues or forced migration
     *         to new contract.
     */
    function toggleSchedulePause(bool paused) external virtual override onlyOwner {
        schedulePaused = paused;

        emit StakingPauseToggle(paused);
    }

    // ======================================== VIEW FUNCTIONS =========================================
    function getLockBoost(IAtlasMine.Lock _lock) public pure virtual returns (uint256 boost, uint256 timelock) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            // 10%
            return (10e16, 14 days);
        } else if (_lock == IAtlasMine.Lock.oneMonth) {
            // 25%
            return (25e16, 30 days);
        } else if (_lock == IAtlasMine.Lock.threeMonths) {
            // 80%
            return (80e16, 3 * 30 days);
        } else if (_lock == IAtlasMine.Lock.sixMonths) {
            // 180%
            return (180e16, 6 * 30 days);
        } else if (_lock == IAtlasMine.Lock.twelveMonths) {
            // 400%
            return (400e16, 365 days);
        } else {
            revert("Invalid lock value");
        }
    }

    /**
     * @notice Returns all magic either unstaked, staked, or pending rewards in Atlas Mine.
     *         Best proxy for TVL.
     *
     * @return total               The total amount of MAGIC in the staker.
     */
    function totalMagic() external view override returns (uint256) {
        return _totalControlledMagic() + mine.pendingRewardsAll(address(this));
    }

    /**
     * @notice Returns all magic that has been deposited, but not staked, and is eligible
     *         to be staked (deposit time < current day).
     *
     * @return total               The total amount of MAGIC available to stake.
     */
    // removed, will read the unstakedDeposits directly
    // function totalPendingStake() external view override returns (uint256) {
    //     return unstakedDeposits;
    // }

    /**
     * @notice Returns all magic that has been deposited, but not staked, and is eligible
     *         to be staked (deposit time < current day).
     *
     * @return total               The total amount of MAGIC that can be withdrawn.
     */
    function totalWithdrawableMagic() external view override returns (uint256) {
        uint256 totalPendingRewards;

        // IAtlasMine attempts to divide by 0 if there are no deposits
        try mine.pendingRewardsAll(address(this)) returns (uint256 _pending) {
            totalPendingRewards = _pending;
        } catch Panic(uint256) {
            totalPendingRewards = 0;
        }

        // uint256 vestedPrincipal;
        // for (uint256 i = 0; i < stakes.length; i++) {
        //     vestedPrincipal += mine.calcualteVestedPrincipal(address(this), stakes[i].depositId);
        // }

        return _totalUsableMagic() + totalPendingRewards;
    }

    /**
     * @notice Returns the details of a vault stake.
     *
     * @return vaultStake           The details of a vault stake.
     */
    function getVaultStake(address vault, uint256 depositId) external view override returns (VaultStake memory) {
        return vaultStake[vault][depositId];
    }

    /**
     * @notice Returns the total amount staked by a vault.
     *
     * @return totalStake           The total amount of MAGIC staked by a vault.
     */
    // we will read it from the subgraph
    // function vaultTotalStake(address vault) external view override returns (uint256 totalStake) {
    //     uint256[] memory depositIds = allVaultDepositIds[vault].values();
    //     for (uint256 i = 0; i < depositIds.length; i++) {
    //         VaultStake storage s = vaultStake[vault][depositIds[i]];
    //         totalStake += s.amount;
    //     }
    // }

    /**
     * @notice Returns the pending, claimable rewards for a deposit.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     * @param depositId         The specific deposit to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewards(address vault, uint256 depositId) public view override returns (uint256 reward) {
        if (totalShare == 0) {
            return 0;
        }
        VaultStake storage s = vaultStake[vault][depositId];
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        uint256 unupdatedReward = mine.pendingRewardsAll(address(this));
        (uint256 founderReward, , uint256 feeRefund) = _calculateHarvestRewardFee(unupdatedReward);
        uint256 realAccRewardsPerShare = accRewardsPerShare + (founderReward * ONE) / totalShare;
        uint256 accumulatedRewards = (share * realAccRewardsPerShare) / ONE;
        if (whitelistedFeeVaults.contains(vault) && totalWhitelistedFeeShare > 0) {
            uint256 realAccRefundedFeePerShare = accRefundedFeePerShare + (feeRefund * ONE) / totalWhitelistedFeeShare;
            uint256 accumulatedRefundedFee = (share * realAccRefundedFeePerShare) / ONE;
            accumulatedRewards = accumulatedRewards + accumulatedRefundedFee;
            accumulatedRewards -= refundedFeeDebts[vault][depositId].toUint256();
        }
        reward = accumulatedRewards - s.rewardDebt.toUint256();
    }

    /**
     * @notice Returns the pending, claimable rewards for all of a vault's deposits.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewardsAll(address vault) external view override returns (uint256 reward) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();

        for (uint256 i = 0; i < depositIds.length; i++) {
            reward += pendingRewards(vault, depositIds[i]);
        }
    }

    /**
     * @notice Returns the total Share of a vault.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return _totalShare           The total share of a vault.
     */
    function totalShareOf(address vault) public view returns (uint256 _totalShare) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            (uint256 boost, ) = getLockBoost(vaultStake[vault][depositIds[i]].lock);
            uint256 share = (vaultStake[vault][depositIds[i]].amount * (100e16 + boost)) / 100e16;
            _totalShare += share;
        }
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Stake tokens held by staker in the Atlas Mine, according to
     *      the predefined lock value. Schedules for staking will be managed by a queue.
     *
     * @param _amount               Number of tokens to stake
     */
    function _stakeInMine(uint256 _amount, IAtlasMine.Lock lock) internal {
        require(_amount <= _totalUsableMagic(), "Not enough funds");

        uint256 depositId = ++lastDepositId;
        (, uint256 lockTime) = getLockBoost(lock);
        uint256 vestingPeriod = mine.getVestingTime(lock);
        uint256 unlockAt = block.timestamp + lockTime + vestingPeriod;

        stakes.push(Stake({ amount: _amount, unlockAt: unlockAt, depositId: depositId }));

        mine.deposit(_amount, lock);
    }

    /**
     * @dev Unstakes until we have enough unstaked tokens to meet a specific target.
     *      Used to make sure we can service withdrawals.
     *
     * @param target                The amount of tokens we want to have unstaked.
     */
    function _unstakeToTarget(uint256 target) internal {
        uint256 unstaked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp && !mine.unlockAll()) {
                // This stake is not unlocked - stop looking
                continue;
            }

            // Withdraw position - auto-harvest
            uint256 preclaimBalance = _totalUsableMagic();
            uint256 targetLeft = target - unstaked;
            uint256 amount = targetLeft > s.amount ? s.amount : targetLeft;

            // Do not harvest rewards - if this is running, we've already
            // harvested in the same fn call
            mine.withdrawPosition(s.depositId, amount);
            uint256 postclaimBalance = _totalUsableMagic();

            // Increment amount unstaked
            unstaked += postclaimBalance - preclaimBalance;

            if (unstaked >= target) {
                // We unstaked enough
                break;
            }
        }

        require(unstaked >= target, "Cannot unstake enough");
        require(_totalUsableMagic() >= target, "Not enough in contract after unstaking");

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @dev Harvest rewards from the IAtlasMine and send them back to
     *      this contract.
     *
     * @return earned               The amount of rewards earned for depositors, minus the fee.
     * @return feeEearned           The amount of fees earned for the contract operator.
     */
    function _harvestMine() internal returns (uint256, uint256) {
        uint256 preclaimBalance = magic.balanceOf(address(this));

        try mine.harvestAll() {
            uint256 postclaimBalance = magic.balanceOf(address(this));

            uint256 earned = postclaimBalance - preclaimBalance;
            // Reserve the 'fee' amount of what is earned
            (, uint256 feeEarned, uint256 feeRefunded) = _calculateHarvestRewardFee(earned);
            feeReserve += feeEarned - feeRefunded;
            emit MineHarvest(earned - feeEarned, feeEarned - feeRefunded, feeRefunded);
            return (earned - feeEarned, feeRefunded);
        } catch {
            // Failed because of reward debt calculation - should be 0
            return (0, 0);
        }
    }

    function _calculateHarvestRewardFee(uint256 earned)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 feeEarned = (earned * fee) / FEE_DENOMINATOR;
        uint256 accFeePerShare = (feeEarned * ONE) / totalShare;
        uint256 feeRefunded = (accFeePerShare * totalWhitelistedFeeShare) / ONE;
        return (earned - feeEarned, feeEarned, feeRefunded);
    }

    /**
     * @dev Harvest rewards from the mine so that stakers can claim.
     *      Recalculate how many rewards are distributed to each share.
     */
    function _updateRewards() internal {
        if (totalStaked == 0 || totalShare == 0) return;
        (uint256 newRewards, uint256 feeRefunded) = _harvestMine();
        accRewardsPerShare += (newRewards * ONE) / totalShare;
        if (totalWhitelistedFeeShare > 0) accRefundedFeePerShare += (feeRefunded * ONE) / totalWhitelistedFeeShare;
    }

    /**
     * @dev After mutating a stake (by withdrawing fully or partially),
     *      get updated data from the staking contract, and update the stake amounts
     *
     * @param stakeIndex           The index of the stake in the Stakes storage array.
     *
     * @return amount              The current, updated amount of the stake.
     */
    function _updateStakeDepositAmount(uint256 stakeIndex) internal returns (uint256) {
        Stake storage s = stakes[stakeIndex];

        (, uint256 depositAmount, , , , , ) = mine.userInfo(address(this), s.depositId);
        s.amount = depositAmount;

        return s.amount;
    }

    /**
     * @dev Find stakes with zero deposit amount and remove them from tracking.
     *      Uses recursion to stop from mutating an array we are currently looping over.
     *      If a zero stake is found, it is removed, and the function is restarted,
     *      such that it is always working from a 'clean' array.
     *
     */
    function _removeZeroStakes() internal {
        bool shouldRecurse = stakes.length > 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            _updateStakeDepositAmount(i);

            Stake storage s = stakes[i];

            if (s.amount == 0) {
                _removeStake(i);
                // Stop looping and start again - we will skip
                // out of the look and recurse
                break;
            }

            if (i == stakes.length - 1) {
                // We didn't remove anything, so stop recursing
                shouldRecurse = false;
            }
        }

        if (shouldRecurse) {
            _removeZeroStakes();
        }
    }

    /**
     * @dev Calculate total amount of MAGIC usable by the contract.
     *      'Usable' means available for either withdrawal or re-staking.
     *      Counts unstaked magic less fee reserve.
     *
     * @return amount               The amount of usable MAGIC.
     */
    function _totalUsableMagic() internal view returns (uint256) {
        // Current magic held in contract
        uint256 unstaked = magic.balanceOf(address(this));

        return unstaked - tokenBuffer - feeReserve;
    }

    /**
     * @dev Calculate total amount of MAGIC under control of the contract.
     *      Counts staked and unstaked MAGIC. Does _not_ count accumulated
     *      but unclaimed rewards.
     *
     * @return amount               The total amount of MAGIC under control of the contract.
     */
    function _totalControlledMagic() internal view returns (uint256) {
        // Current magic staked in mine
        uint256 staked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            staked += stakes[i].amount;
        }

        return staked + _totalUsableMagic();
    }

    /**
     * @dev Remove a tracked stake from any position in the stakes array.
     *      Used when a stake is no longer relevant i.e. fully withdrawn.
     *      Mutates the Stakes array in storage.
     *
     * @param index                 The index of the stake to remove.
     */
    function _removeStake(uint256 index) internal {
        if (index >= stakes.length) return;

        for (uint256 i = index; i < stakes.length - 1; i++) {
            stakes[i] = stakes[i + 1];
        }

        delete stakes[stakes.length - 1];

        stakes.pop();
    }

    modifier onlySuperAdminOrOwner() {
        require(msg.sender == owner() || superAdmins[msg.sender], "Not Super Admin");
        _;
    }
    modifier onlyBattleflyVaultOrOwner() {
        require(msg.sender == owner() || battleflyVaults[msg.sender], "Not BattleflyVault");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBattleflyAtlasStaker.sol";
import "./interfaces/IAtlasMine.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IBattleflyVault.sol";

contract BattleflyVault is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ============================================ STATE ==============================================
    struct UserStake {
        uint256 amount;
        uint256 unlockAt;
        uint256 withdrawAt;
        IAtlasMine.Lock lock;
        uint256 battleflyStakerDepositId;
        address owner;
    }
    // ============= Global Immutable State ==============
    IERC20Upgradeable public magic;
    IBattleflyAtlasStaker public BattleflyStaker;
    // ============= Global Staking State ==============
    mapping(uint256 => UserStake) public userStakes;
    mapping(address => EnumerableSetUpgradeable.UintSet) private stakesOfOwner;
    uint256 nextStakeId;
    uint256 public totalStaked;

    // ============= Global Admin ==============
    mapping(address => bool) private adminAccess;
    // ============================================ EVENT ==============================================
    event Claim(address indexed user, uint256 stakeId, uint256 amount);
    event Stake(address indexed user, uint256 stakeId, uint256 amount, IAtlasMine.Lock lock);
    event Withdraw(address indexed user, uint256 stakeId, uint256 amount);
    event SetFee(uint256 oldFee, uint256 newFee, uint256 denominator);
    event WithdrawFee(address receiver, uint256 amount);

    event SetAdminAccess(address indexed user, bool access);

    // ============================================ INITIALIZE ==============================================
    function initialize(address _magicAddress, address _BattleflyStakerAddress) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = IERC20Upgradeable(_magicAddress);
        BattleflyStaker = IBattleflyAtlasStaker(_BattleflyStakerAddress);
        nextStakeId = 0;
        // Approve the AtlasStaker contract to spend the magic
        magic.safeApprove(address(BattleflyStaker), 2**256 - 1);
    }

    // ============================================ USER FUNCTIONS ==============================================
    function stake(uint256 amount, IAtlasMine.Lock lock) external {
        magic.safeTransferFrom(msg.sender, address(this), amount);
        _stake(amount, lock);
    }

    function _stake(uint256 amount, IAtlasMine.Lock lock) internal returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        uint256 battleflyStakerDepositId = BattleflyStaker.deposit(amount, lock);
        IBattleflyAtlasStaker.VaultStake memory vaultStake = BattleflyStaker.getVaultStake(
            address(this),
            battleflyStakerDepositId
        );
        UserStake storage s = userStakes[nextStakeId];
        s.amount = amount;
        s.unlockAt = vaultStake.unlockAt;
        s.lock = lock;
        s.battleflyStakerDepositId = battleflyStakerDepositId;
        s.owner = msg.sender;
        stakesOfOwner[msg.sender].add(nextStakeId);
        emit Stake(msg.sender, nextStakeId, amount, lock);
        nextStakeId++;
        totalStaked += amount;
        return nextStakeId - 1;
    }

    function claimAll() public nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (_getStakeClaimableAmount(stakeId) > 0) {
                totalReward += _claim(stakeId);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        magic.safeTransfer(msg.sender, totalReward);
    }

    function claimAllAndRestake(IAtlasMine.Lock lock) external {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (_getStakeClaimableAmount(stakeId) > 0) {
                totalReward += _claim(stakeId);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        _stake(totalReward, lock);
    }

    function claim(uint256[] memory stakeIds) external nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            UserStake storage s = userStakes[stakeIds[i]];
            require(s.owner == msg.sender, "Only the owner can claim");
            if (_getStakeClaimableAmount(stakeIds[i]) > 0) {
                totalReward += _claim(stakeIds[i]);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        magic.safeTransfer(msg.sender, totalReward);
    }

    function _claim(uint256 stakeId) internal returns (uint256) {
        UserStake memory s = userStakes[stakeId];
        uint256 claimedAmount = BattleflyStaker.claim(s.battleflyStakerDepositId);
        emit Claim(s.owner, stakeId, claimedAmount);
        return claimedAmount;
    }

    function _getStakeClaimableAmount(uint256 stakeId) internal view returns (uint256) {
        UserStake memory s = userStakes[stakeId];
        uint256 claimAmount = BattleflyStaker.pendingRewards(address(this), s.battleflyStakerDepositId);
        return claimAmount;
    }

    function getUserClaimableAmount(address user) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakesOfOwner[user].length(); i++) {
            uint256 stakeId = stakesOfOwner[user].at(i);
            total += _getStakeClaimableAmount(stakeId);
        }
        return total;
    }

    function getUserStakes(address user) external view returns (UserStake[] memory) {
        UserStake[] memory stakes = new UserStake[](stakesOfOwner[user].length());
        for (uint256 i = 0; i < stakesOfOwner[user].length(); i++) {
            uint256 stakeId = stakesOfOwner[user].at(i);
            stakes[i] = userStakes[stakeId];
        }
        return stakes;
    }

    function withdrawAll() external nonReentrant {
        require(stakesOfOwner[msg.sender].length() > 0, "No stakes to withdraw");
        uint256 receiveAmount;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (userStakes[stakeId].unlockAt < block.timestamp) {
                receiveAmount += _withdraw(stakeId);
            }
        }
        require(receiveAmount > 0, "No stakes to withdraw");
        magic.safeTransfer(msg.sender, receiveAmount);
    }

    function withdraw(uint256[] memory stakeIds) external nonReentrant {
        uint256 receiveAmount;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            UserStake storage s = userStakes[stakeIds[i]];
            require(s.owner == msg.sender, "Only the owner can withdraw");
            receiveAmount += _withdraw(stakeIds[i]);
        }
        require(receiveAmount > 0, "No stakes to withdraw");
        magic.safeTransfer(msg.sender, receiveAmount);
    }

    function _withdraw(uint256 stakeId) internal returns (uint256 withdrawAmount) {
        UserStake storage s = userStakes[stakeId];
        withdrawAmount = s.amount;
        require(s.unlockAt < block.timestamp, "Cannot withdraw before the lock time");
        uint256 claimableAmount = _getStakeClaimableAmount(stakeId);
        if (claimableAmount > 0) {
            withdrawAmount += _claim(stakeId);
        }
        BattleflyStaker.withdraw(s.battleflyStakerDepositId);
        totalStaked -= s.amount;
        stakesOfOwner[msg.sender].remove(stakeId);
        s.withdrawAt = block.timestamp;
        emit Withdraw(msg.sender, stakeId, withdrawAmount);
    }

    // ============================================ OWNER FUNCTIONS ==============================================
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    // ============================================ MODIFIER ==============================================
    modifier onlyAdminAccessOrOwner() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyVault {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBattleflyAtlasStaker.sol";
import "./interfaces/IAtlasMine.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IBattleflyVault.sol";
import "./interfaces/IBattleflyFounderVault.sol";

contract BattleflyFlywheelVault is IBattleflyVault, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ============================================ STATE ==============================================
    struct UserStake {
        uint256 amount;
        uint256 unlockAt;
        uint256 withdrawAt;
        uint256 battleflyStakerDepositId;
        address owner;
        IAtlasMine.Lock lock;
    }
    // ============= Global Immutable State ==============
    IERC20Upgradeable public magic;
    IBattleflyAtlasStaker public BattleflyStaker;
    // ============= Global Staking State ==============
    mapping(uint256 => UserStake) public userStakes;
    mapping(address => EnumerableSetUpgradeable.UintSet) private stakesOfOwner;
    uint256 public nextStakeId;
    uint256 public totalStaked;
    uint256 public totalFee;
    uint256 public totalFeeWithdrawn;
    uint256 public FEE;
    uint256 public FEE_DENOMINATOR;
    // ============= Global Admin ==============
    mapping(address => bool) private adminAccess;

    address public TREASURY_WALLET;
    IBattleflyFounderVault public founderVaultV1;
    IBattleflyFounderVault public founderVaultV2;
    uint256 public stakeableAmountPerV1;
    uint256 public stakeableAmountPerV2;
    // ============================================ EVENT ==============================================
    event Claim(address indexed user, uint256 stakeId, uint256 amount, uint256 fee);
    event Stake(address indexed user, uint256 stakeId, uint256 amount, IAtlasMine.Lock lock);
    event Withdraw(address indexed user, uint256 stakeId, uint256 amount);
    event SetFee(uint256 oldFee, uint256 newFee, uint256 denominator);
    event WithdrawFee(address receiver, uint256 amount);

    event SetAdminAccess(address indexed user, bool access);

    // ============================================ INITIALIZE ==============================================
    function initialize(
        address _magicAddress,
        address _BattleflyStakerAddress,
        uint256 _fee,
        uint256 _feeDominator,
        address _founderVaultV1Address,
        address _founderVaultV2Address,
        uint256 _stakeableAmountPerV1,
        uint256 _stakeableAmountPerV2
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = IERC20Upgradeable(_magicAddress);
        BattleflyStaker = IBattleflyAtlasStaker(_BattleflyStakerAddress);
        nextStakeId = 0;
        FEE_DENOMINATOR = _feeDominator;
        founderVaultV1 = IBattleflyFounderVault(_founderVaultV1Address);
        founderVaultV2 = IBattleflyFounderVault(_founderVaultV2Address);
        stakeableAmountPerV1 = _stakeableAmountPerV1;
        stakeableAmountPerV2 = _stakeableAmountPerV2;
        TREASURY_WALLET = 0xF5411006eEfD66c213d2fd2033a1d340458B7226;
        // Approve the AtlasStaker contract to spend the magic
        magic.safeApprove(address(BattleflyStaker), 2**256 - 1);

        _setFee(_fee);
    }

    // ============================================ USER FUNCTIONS ==============================================
    function stake(uint256 amount, IAtlasMine.Lock lock) external {
        magic.safeTransferFrom(msg.sender, address(this), amount);
        _stake(amount, lock);
    }

    function _stake(uint256 amount, IAtlasMine.Lock lock) internal returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        uint256 battleflyStakerDepositId = BattleflyStaker.deposit(amount, lock);
        IBattleflyAtlasStaker.VaultStake memory vaultStake = BattleflyStaker.getVaultStake(
            address(this),
            battleflyStakerDepositId
        );
        UserStake storage s = userStakes[nextStakeId];
        s.amount = amount;
        s.unlockAt = vaultStake.unlockAt;
        s.battleflyStakerDepositId = battleflyStakerDepositId;
        s.owner = msg.sender;
        s.lock = lock;
        stakesOfOwner[msg.sender].add(nextStakeId);
        emit Stake(msg.sender, nextStakeId, amount, lock);
        nextStakeId++;
        totalStaked += amount;
        return nextStakeId - 1;
    }

    function getStakeAmount(address user) public view returns (uint256, uint256) {
        uint256 totalStakingV1;
        uint256 totalStakingV2;
        IBattleflyFounderVault.FounderStake[] memory v1Stakes = founderVaultV1.stakesOf(user);
        IBattleflyFounderVault.FounderStake[] memory v2Stakes = founderVaultV2.stakesOf(user);
        for (uint256 i = 0; i < v1Stakes.length; i++) {
            totalStakingV1 += v1Stakes[i].amount;
        }
        for (uint256 i = 0; i < v2Stakes.length; i++) {
            totalStakingV2 += v2Stakes[i].amount;
        }
        uint256 totalUserStaking = 0;
        for (uint256 i = 0; i < stakesOfOwner[user].length(); i++) {
            uint256 stakeId = stakesOfOwner[user].at(i);
            totalUserStaking += userStakes[stakeId].amount;
        }
        uint256 stakedAmount = totalStakingV1 * stakeableAmountPerV1 + totalStakingV2 * stakeableAmountPerV2;
        return (stakedAmount, totalUserStaking);
    }

    function claimAll() public nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (_getStakeClaimableAmount(stakeId) > 0) {
                totalReward += _claim(stakeId);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        magic.safeTransfer(msg.sender, totalReward);
    }

    function claimAllAndRestake(IAtlasMine.Lock lock) external {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (_getStakeClaimableAmount(stakeId) > 0) {
                totalReward += _claim(stakeId);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        _stake(totalReward, lock);
    }

    function claim(uint256[] memory stakeIds) external nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            UserStake storage s = userStakes[stakeIds[i]];
            require(s.owner == msg.sender, "Only the owner can claim");
            if (_getStakeClaimableAmount(stakeIds[i]) > 0) {
                totalReward += _claim(stakeIds[i]);
            }
        }
        require(totalReward > 0, "No rewards to claim");
        magic.safeTransfer(msg.sender, totalReward);
    }

    function _claim(uint256 stakeId) internal returns (uint256) {
        UserStake memory s = userStakes[stakeId];
        uint256 claimedAmount = BattleflyStaker.claim(s.battleflyStakerDepositId);
        uint256 fee = (claimedAmount * FEE) / FEE_DENOMINATOR;
        uint256 userClaimAmount = claimedAmount - fee;
        totalFee += fee;
        emit Claim(s.owner, stakeId, userClaimAmount, fee);
        return userClaimAmount;
    }

    function _getStakeClaimableAmount(uint256 stakeId) internal view returns (uint256) {
        UserStake memory s = userStakes[stakeId];
        uint256 claimAmount = BattleflyStaker.pendingRewards(address(this), s.battleflyStakerDepositId);
        uint256 fee = (claimAmount * FEE) / FEE_DENOMINATOR;
        uint256 userClaimAmount = claimAmount - fee;
        return userClaimAmount;
    }

    function getUserClaimableAmount(address user) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakesOfOwner[user].length(); i++) {
            uint256 stakeId = stakesOfOwner[user].at(i);
            total += _getStakeClaimableAmount(stakeId);
        }
        return total;
    }

    function getUserStakes(address user) external view returns (UserStake[] memory) {
        UserStake[] memory stakes = new UserStake[](stakesOfOwner[user].length());
        for (uint256 i = 0; i < stakesOfOwner[user].length(); i++) {
            uint256 stakeId = stakesOfOwner[user].at(i);
            stakes[i] = userStakes[stakeId];
        }
        return stakes;
    }

    function withdrawAll() external nonReentrant {
        require(stakesOfOwner[msg.sender].length() > 0, "No stakes to withdraw");
        uint256 receiveAmount;
        for (uint256 i = 0; i < stakesOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = stakesOfOwner[msg.sender].at(i);
            if (userStakes[stakeId].unlockAt < block.timestamp) {
                receiveAmount += _withdraw(stakeId);
            }
        }
        require(receiveAmount > 0, "No stakes to withdraw");
        magic.safeTransfer(msg.sender, receiveAmount);
    }

    function withdraw(uint256[] memory stakeIds) external nonReentrant {
        uint256 receiveAmount;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            UserStake storage s = userStakes[stakeIds[i]];
            require(s.owner == msg.sender, "Only the owner can withdraw");
            receiveAmount += _withdraw(stakeIds[i]);
        }
        require(receiveAmount > 0, "No stakes to withdraw");
        magic.safeTransfer(msg.sender, receiveAmount);
    }

    function _withdraw(uint256 stakeId) internal returns (uint256 withdrawAmount) {
        UserStake storage s = userStakes[stakeId];
        withdrawAmount = s.amount;
        require(s.unlockAt < block.timestamp, "Cannot withdraw before the lock time");
        uint256 claimableAmount = _getStakeClaimableAmount(stakeId);
        if (claimableAmount > 0) {
            withdrawAmount += _claim(stakeId);
        }
        BattleflyStaker.withdraw(s.battleflyStakerDepositId);
        totalStaked -= s.amount;
        stakesOfOwner[msg.sender].remove(stakeId);
        s.withdrawAt = block.timestamp;
        emit Withdraw(msg.sender, stakeId, withdrawAmount);
    }

    function stakeableAmountPerFounder(address vault) external view returns (uint256) {
        if (vault == address(founderVaultV1)) {
            return stakeableAmountPerV1;
        }
        if (vault == address(founderVaultV2)) {
            return stakeableAmountPerV2;
        }
        return 0;
    }

    // ============================================ ADMIN FUNCTIONS ==============================================
    function setFee(uint256 _fee) external onlyAdminAccessOrOwner {
        _setFee(_fee);
        require(totalStaked == 0, "Fee can only be updated without any stakers");
        emit SetFee(FEE, _fee, FEE_DENOMINATOR);
    }

    function _setFee(uint256 _fee) private {
        require(_fee < FEE_DENOMINATOR, "Fee must be less than the fee dominator");

        FEE = _fee;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyAdminAccessOrOwner {
        TREASURY_WALLET = _treasuryWallet;
    }

    function withdrawFeeToTreasury() external onlyAdminAccessOrOwner {
        uint256 amount = totalFee - totalFeeWithdrawn;
        require(amount > 0, "No fee to withdraw");
        totalFeeWithdrawn += amount;
        magic.safeTransfer(TREASURY_WALLET, amount);
        emit WithdrawFee(TREASURY_WALLET, amount);
    }

    // ============================================ OWNER FUNCTIONS ==============================================
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    // ============================================ MODIFIER ==============================================
    modifier onlyAdminAccessOrOwner() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import "./interfaces/ISpecialNFT.sol";

contract SpecialNFTRouter {
    ISpecialNFT token;

    constructor(address _tokenAddress) {
        token = ISpecialNFT(_tokenAddress);
    }

    function getAllBalance(address owner) external view returns (uint256[] memory, uint256[] memory) {
        uint256 balance = token.balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory tokenTypes = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = token.tokenOfOwnerByIndex(owner, i);
            tokenTypes[i] = token.getSpecialNFTType(tokenIds[i]);
        }
        return (tokenIds, tokenTypes);
    }

    function getBalanceOf(address owner, uint256 typeId) external view returns (uint256[] memory) {
        uint256 balance = token.balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 count = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = token.tokenOfOwnerByIndex(owner, i);
            uint256 tokenType = token.getSpecialNFTType(tokenId);
            if (tokenType == typeId) {
                tokenIds[count] = tokenId;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tokenIds[i];
        }
        return (result);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IHyperdome.sol";
import "./interfaces/IBattlefly.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IMod.sol";
import "./interfaces/IScrapToken.sol";
import "./interfaces/IItem.sol";

contract BattleflyGame is OwnableUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) private adminAccess;
    IHyperdome private HyperdomeContract; //removed
    IBattlefly private BattleflyContract;
    ISpecialNFT private SpecialNFTContract;
    IMod private ModContract; // removed
    IERC20Upgradeable private MagicToken;
    IScrapToken private ScrapToken; // removed
    IItem private ItemContract;

    mapping(uint256 => bool) public ProcessedTransactions;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_BATTLEFLY = 0;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_MAGIC = 1;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_ITEM = 2;

    event DepositHyperdome(uint256 indexed tokenId, address indexed user, uint256 timestamp);
    event WithdrawHyperdome(uint256 indexed tokenId, address indexed receiver, uint256 timestamp);

    event DepositBattlefly(uint256 indexed tokenId, address indexed user, uint256 timestamp);
    event WithdrawBattlefly(uint256 indexed tokenId, address indexed receiver, uint256 timestamp);

    event DepositItems(uint256 indexed tokenId, address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawItems(uint256 indexed tokenId, address indexed receiver, uint256 amount, uint256 timestamp);

    event DepositMagic(uint256 amount, address indexed user, uint256 timestamp);
    event WithdrawMagic(uint256 amount, address indexed receiver, uint256 timestamp);

    event MintHyperdome(address indexed receiver, uint256 tokenId);
    event MintBattlefly(address indexed receiver, uint256 tokenId, uint256 battleflyType);
    event MintBattleflies(address[] receivers, uint256[] tokenIds, uint256[] battleflyTypes);

    event MintSpecialNFT(address indexed receiver, uint256 tokenId, uint256 specialNFTType);
    event MintSpecialNFTs(address[] receivers, uint256[] tokenIds, uint256[] specialNFTTypes);

    event MintMod(address indexed receiver, uint256 tokenId);

    event SetAdminAccess(address indexed user, bool access);
    event MintItems(uint256 indexed itemId, address indexed receiver, uint256 amount);

    function initialize(
        address hyperdomeContractAddress,
        address battleflyContractAddress,
        address specialNFTContractAddress,
        address modContractAddress,
        address magicTokenAddress,
        address scrapTokenAddress
    ) public initializer {
        __Ownable_init();
        HyperdomeContract = IHyperdome(hyperdomeContractAddress);
        BattleflyContract = IBattlefly(battleflyContractAddress);
        SpecialNFTContract = ISpecialNFT(specialNFTContractAddress);
        ModContract = IMod(modContractAddress);
        MagicToken = IERC20Upgradeable(magicTokenAddress);
        ScrapToken = IScrapToken(scrapTokenAddress);
    }

    function initializeUpgrade(address itemContractAddress) external onlyOwner {
        ItemContract = IItem(itemContractAddress);
    }

    function setMagic(address magicAddress) external onlyOwner {
        MagicToken = IERC20Upgradeable(magicAddress);
    }

    function getBattlefliesOfOwner(address user) external view returns (uint256[] memory) {
        uint256 balance = BattleflyContract.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = BattleflyContract.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    function getSpecialNFTsOfOwner(address user) external view returns (uint256[] memory) {
        uint256 balance = SpecialNFTContract.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = SpecialNFTContract.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    // ADMIN
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    function mintSpecialNFT(address receiver, uint256 specialNFTType) external onlyAdminAccess returns (uint256) {
        uint256 tokenId = SpecialNFTContract.mintSpecialNFT(receiver, specialNFTType);
        emit MintSpecialNFT(receiver, tokenId, specialNFTType);
        return tokenId;
    }

    function mintSpecialNFTs(
        address receiver,
        uint256 specialNFTType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = SpecialNFTContract.mintSpecialNFTs(receiver, specialNFTType, amount);
        for (uint256 i = 0; i < amount; i++) {
            emit MintSpecialNFT(receiver, tokenIds[i], specialNFTType);
        }
        return tokenIds;
    }

    function mintItems(
        uint256 itemId,
        address receiver,
        uint256 amount
    ) external onlyAdminAccess {
        ItemContract.mintItems(itemId, receiver, amount, "");
        emit MintItems(itemId, receiver, amount);
    }

    function mintBattlefly(address receiver, uint256 battleflyType) external onlyAdminAccess returns (uint256) {
        uint256 tokenId = BattleflyContract.mintBattlefly(receiver, battleflyType);
        emit MintBattlefly(receiver, tokenId, battleflyType);
        return tokenId;
    }

    function mintBattleflies(
        address receiver,
        uint256 battleflyType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = BattleflyContract.mintBattleflies(receiver, battleflyType, amount);
        for (uint256 i = 0; i < amount; i++) {
            emit MintBattlefly(receiver, tokenIds[i], battleflyType);
        }
        return tokenIds;
    }

    // Battlefly
    function bulkDepositBattlefly(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            depositBattlefly(tokenIds[i]);
        }
    }

    function depositBattlefly(uint256 tokenId) public {
        BattleflyContract.safeTransferFrom(_msgSender(), address(this), tokenId);
        emit DepositBattlefly(tokenId, _msgSender(), block.timestamp);
    }

    function withdrawBattlefly(uint256 tokenId, address receiver) external onlyAdminAccess {
        BattleflyContract.safeTransferFrom(address(this), receiver, tokenId);
        emit WithdrawBattlefly(tokenId, receiver, block.timestamp);
    }

    function claimWithdrawBattleflies(
        uint256[] memory tokenIds,
        uint256 transactionId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ProcessedTransactions[transactionId] == false, "Transaction have been processed");
        ProcessedTransactions[transactionId] = true;
        bytes32 payloadHash = keccak256(
            abi.encodePacked(_msgSender(), tokenIds, transactionId, TRANSACTION_TYPE_WITHDRAW_BATTLEFLY)
        );
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);
        require(result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin], "Require admin access");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            BattleflyContract.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
            emit WithdrawBattlefly(tokenIds[i], _msgSender(), block.timestamp);
        }
    }

    //Magic token
    function depositMagic(uint256 amount) external {
        MagicToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit DepositMagic(amount, _msgSender(), block.timestamp);
    }

    function withdrawMagic(uint256 amount, address receiver) external onlyAdminAccess {
        MagicToken.safeTransfer(receiver, amount);
        emit WithdrawMagic(amount, receiver, block.timestamp);
    }

    function claimWithdrawMagic(
        uint256 amount,
        uint256 transactionId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ProcessedTransactions[transactionId] == false, "Transaction have been processed");
        ProcessedTransactions[transactionId] = true;
        bytes32 payloadHash = keccak256(
            abi.encodePacked(_msgSender(), amount, transactionId, TRANSACTION_TYPE_WITHDRAW_MAGIC)
        );
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);
        require(result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin], "Require admin access");
        MagicToken.safeTransfer(_msgSender(), amount);
        emit WithdrawMagic(amount, _msgSender(), block.timestamp);
    }

    //Item
    function depositItems(uint256 itemId, uint256 amount) external {
        ItemContract.safeTransferFrom(_msgSender(), address(this), itemId, amount, "");
        emit DepositItems(itemId, _msgSender(), amount, block.timestamp);
    }

    function withdrawItems(
        uint256 itemId,
        uint256 amount,
        address receiver
    ) external onlyAdminAccess {
        ItemContract.safeTransferFrom(address(this), receiver, itemId, amount, "");
        emit WithdrawItems(itemId, receiver, amount, block.timestamp);
    }

    function claimWithdrawItems(
        uint256 itemId,
        uint256 amount,
        uint256 transactionId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ProcessedTransactions[transactionId] == false, "Transaction have been processed");
        ProcessedTransactions[transactionId] = true;
        bytes32 payloadHash = keccak256(
            abi.encodePacked(_msgSender(), itemId, amount, transactionId, TRANSACTION_TYPE_WITHDRAW_ITEM)
        );
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);
        require(result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin], "Require admin access");
        ItemContract.safeTransferFrom(address(this), _msgSender(), itemId, amount, "");
        emit WithdrawItems(itemId, _msgSender(), amount, block.timestamp);
    }

    //modifier
    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./IBattlefly.sol";

interface IHyperdome is IERC721EnumerableUpgradeable {
    function mintHyperdome(address receiver) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IScrapToken is IERC20 {
    function mint(uint256 amount, address receiver) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IItem is IERC1155Upgradeable {
    function mintItems(
        uint256 itemId,
        address receiver,
        uint256 amount,
        bytes memory data
    ) external;
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
import "./interfaces/IAtlasMine.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IBattleflyFounderVault.sol";
import "./interfaces/IBattleflyFlywheelVault.sol";

contract BattleflyFounderVault is
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

    // ============================================ INITIALIZE ==============================================
    function initialize(
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

        require(stakeBackPercent + treasuryPercent + v2VaultPercent < PERCENT_DENOMINATOR);

        // Approve the AtlasStaker contract to spend the magic
        magic.safeApprove(address(BattleflyStaker), 2**256 - 1);
    }

    // ============================================ USER OPERATIONS ==============================================
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

    function setTokenClaimedPastEmission(uint256[] memory tokenIds, bool isClaimed) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimedPastEmission[tokenIds[i]] = isClaimed;
        }
    }

    function setPastEmission(uint256 amount) external onlyOwner {
        pastEmissionPerFounder = amount;
    }

    function stakesOf(address owner) public view returns (FounderStake[] memory, uint256[][] memory) {
        FounderStake[] memory stakes = new FounderStake[](FounderStakeOfOwner[owner].length());
        uint256[][] memory _founderIDsOfStake = new uint256[][](FounderStakeOfOwner[owner].length());
        for (uint256 i = 0; i < FounderStakeOfOwner[owner].length(); i++) {
            stakes[i] = FounderStakes[FounderStakeOfOwner[owner].at(i)];
            _founderIDsOfStake[i] = stakingFounderOfStakeId[FounderStakeOfOwner[owner].at(i)].values();
        }
        return (stakes, _founderIDsOfStake);
    }

    function stakeFounderNFT(uint256[] memory ids) external {
        require(ids.length != 0, "Must provide at least one founder NFT ID");
        for (uint256 i = 0; i < ids.length; i++) {
            require(founderNFT.getSpecialNFTType(ids[i]) == founderTypeID, "Not valid founder NFT");
            founderNFT.safeTransferFrom(msg.sender, address(this), ids[i]);
        }
        uint256 currentDay = (block.timestamp - startTimestamp) / 24 hours;
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

    function claimAll() external nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < FounderStakeOfOwner[msg.sender].length(); i++) {
            totalReward += _claimByStakeId(FounderStakeOfOwner[msg.sender].at(i));
        }
        require(totalReward > 0, "No reward to claim");
    }

    function withdrawAll() external nonReentrant {
        require(FounderStakeOfOwner[msg.sender].length() > 0, "No STAKE to withdraw");
        uint256 totalWithdraw = 0;
        for (uint256 i = 0; i < FounderStakeOfOwner[msg.sender].length(); i++) {
            uint256 stakeId = FounderStakeOfOwner[msg.sender].at(i);
            _claimByStakeId(stakeId);
            totalWithdraw += FounderStakes[stakeId].amount;
            _withdrawByStakeId(stakeId);
        }
        (uint256 stakeableAmount, uint256 stakingAmount) = battleflyFlywheelVault.getStakeAmount(msg.sender);
        uint256 stakeableAmountPerFounder = battleflyFlywheelVault.stakeableAmountPerFounder(address(this));
        require(
            stakingAmount <= stakeableAmount - stakeableAmountPerFounder * totalWithdraw,
            "Pls withdraw FlywheelVault first"
        );
    }

    function _withdrawByStakeId(uint256 stakeId) internal {
        FounderStake storage stake = FounderStakes[stakeId];
        _claimByStakeId(stakeId);
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
        stake.lastClaimedDay = DaysSinceStart;
        magic.safeTransfer(stake.owner, totalReward);
        emit Claim(stake.owner, stakeId, totalReward);
        return totalReward;
    }

    function withdraw(uint256[] memory founderIds) external nonReentrant {
        require(founderIds.length > 0, "No Founder to withdraw");
        uint256 totalWithdraw = 0;
        for (uint256 i = 0; i < founderIds.length; i++) {
            uint256 stakeId = stakeIdOfFounder[founderIds[i]];
            require(FounderStakes[stakeId].owner == msg.sender, "Not your stake");
            _claimBeforeWithdraw(founderIds[i]);
            _withdraw(founderIds[i]);
            totalWithdraw++;
        }
        // (uint256 stakeableAmount, uint256 stakingAmount) = battleflyFlywheelVault.getStakeAmount(msg.sender);
        // uint256 stakeableAmountPerFounder = battleflyFlywheelVault.stakeableAmountPerFounder(address(this));
        // require(stakingAmount <= stakeableAmount - stakeableAmountPerFounder * totalWithdraw, "Pls withdraw FlywheelVault first");
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

    function getClaimableEmissionOf(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < FounderStakeOfOwner[user].length(); i++) {
            totalReward += _getClaimableEmissionOf(FounderStakeOfOwner[user].at(i));
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

    function _withdraw(uint256 founderId) internal {
        uint256 stakeId = stakeIdOfFounder[founderId];
        FounderStake storage stake = FounderStakes[stakeId];
        // _claim(founderId);
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

    // ============================================ ADMIN OPERATIONS ==============================================
    function topupMagicToStaker(uint256 amount, IAtlasMine.Lock lock) external onlyAdminAccess {
        require(amount > 0);
        magic.safeTransferFrom(msg.sender, address(this), amount);
        _depositToStaker(amount, lock);
        emit TopupMagicToStaker(msg.sender, amount, lock);
    }

    function topupTodayEmission(uint256 amount) external onlyAdminAccess {
        require(amount > 0);
        magic.safeTransferFrom(msg.sender, address(this), amount);
        pendingFounderEmission += amount;
        emit TopupTodayEmission(msg.sender, amount);
    }

    function depositToStaker(uint256 amount, IAtlasMine.Lock lock) external onlyAdminAccess {
        require(magic.balanceOf(address(this)) >= amount);
        require(amount > 0);
        _depositToStaker(amount, lock);
    }

    function _depositToStaker(uint256 amount, IAtlasMine.Lock lock) internal {
        BattleflyStaker.deposit(amount, lock);
    }

    function claimDailyEmission() public onlyAdminAccess nonReentrant {
        uint256 currentDay = (block.timestamp - startTimestamp) / 24 hours;
        require(currentDay > DaysSinceStart, "Cant claim again for today");
        uint256 todayTotalEmission = BattleflyStaker.claimAll();
        uint256 todayTotalFounderNFTs = _updateTotalStakingFounders(currentDay);

        uint256 stakeBackAmount;
        uint256 v2VaultAmount;
        uint256 treasuryAmount;
        uint256 founderEmission;
        if (todayTotalEmission != 0) {
            stakeBackAmount = (todayTotalEmission * stakeBackPercent) / PERCENT_DENOMINATOR;
            if (stakeBackAmount != 0) _depositToStaker(stakeBackAmount, DEFAULT_STAKE_BACK_LOCK);

            v2VaultAmount = (todayTotalEmission * v2VaultPercent) / PERCENT_DENOMINATOR;
            if (v2VaultAmount != 0) battleflyFounderVaultV2.topupMagicToStaker(v2VaultAmount, DEFAULT_STAKE_BACK_LOCK);

            treasuryAmount = (todayTotalEmission * treasuryPercent) / PERCENT_DENOMINATOR;
            if (treasuryAmount != 0) magic.safeTransfer(TREASURY_WALLET, treasuryAmount);

            founderEmission += todayTotalEmission - stakeBackAmount - v2VaultAmount - treasuryAmount;
        }
        if (pendingFounderEmission > 0) {
            founderEmission += pendingFounderEmission;
            pendingFounderEmission = 0;
        }
        totalEmission += founderEmission;
        DaysSinceStart = currentDay;
        DailyFounderEmissions[DaysSinceStart] = DailyFounderEmission({
            totalEmission: founderEmission,
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
    }

    function withdrawAllFromStaker() external onlyAdminAccess {
        claimDailyEmission();
        BattleflyStaker.withdrawAll();
    }

    function withdrawFromVault(address receiver, uint256 amount) external onlyAdminAccess {
        magic.safeTransfer(receiver, amount);
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

    //Must be called right after init
    function setFlywheelVault(address vault) external onlyOwner {
        require(vault != address(0));
        battleflyFlywheelVault = IBattleflyFlywheelVault(vault);
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] || _msgSender() == owner(), "Require admin access");
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

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStakerV02.sol";
import "./interfaces/IVault.sol";
import "./libraries/BattleflyAtlasStakerUtils.sol";
import "./interfaces/vaults/IBattleflyTreasuryFlywheelVault.sol";

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract BattleflyAtlasStakerV02 is
    IBattleflyAtlasStakerV02,
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ========== CONSTANTS ==========

    uint96 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant ONE = 1e28;
    address public BATTLEFLY_BOT;

    IERC20Upgradeable public override MAGIC;
    IAtlasMine public ATLAS_MINE;
    IBattleflyTreasuryFlywheelVault public TREASURY_VAULT;

    IAtlasMine.Lock[] public LOCKS;
    IAtlasMine.Lock[] public allowedLocks;

    // ========== Operator States ==========
    uint256 public override currentDepositId;
    uint64 public override currentEpoch;
    uint256 public pausedUntil;
    uint256 public nextExecution;

    /**
     * @dev active positionIds in AtlasMine for this contract.
     *
     */
    EnumerableSetUpgradeable.UintSet private activePositionIds;

    /**
     * @dev Total emissions harvested from Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { emissions }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) private totalEmissionsAtEpochForLock;

    /**
     * @dev Total amount of magic staked in Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { magic }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) private totalStakedAtEpochForLock;

    /**
     * @dev Total amount of emissions per share in magic for a particular lock period and epoch
     *      { lock } => { epoch } => { emissionsPerShare }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) private totalPerShareAtEpochForLock;

    /**
     * @dev Total amount of unstaked Magic at a particular epoch
     *      { epoch } => { unstaked magic }
     */
    mapping(uint64 => uint256) private unstakeAmountAtEpoch;

    /**
     * @dev Legion ERC721 NFT stakers data
     *      { tokenId } => { depositor }
     */
    mapping(uint256 => address) public legionStakers;

    /**
     * @dev TREASURE ERC1155 NFT stakers data
     *      { tokenId } => { depositor } => { deposit amount }
     */
    mapping(uint256 => mapping(address => uint256)) public treasureStakers;

    /**
     * @dev Vaultstakes per depositId
     *      { depositId } => { VaultStake }
     */
    mapping(uint256 => VaultStake) public vaultStakes;

    /**
     * @dev Vaults' all deposits
     *      { address } => { depositId }
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) private depositIdByVault;

    /**
     * @dev Magic amount that is not staked to AtlasMine
     *      { Lock } => { unstaked amount }
     */
    mapping(IAtlasMine.Lock => uint256) public unstakedAmount;

    // ========== Access Control States ==========
    mapping(address => bool) public superAdmins;

    /**
     * @dev Whitelisted vaults
     *      { vault address } => { Vault }
     */
    mapping(address => Vault) public vaults;

    function initialize(
        address _magic,
        address _atlasMine,
        address _treasury,
        address _battleflyBot,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        require(_magic != address(0), "BattleflyAtlasStaker: invalid address");
        require(_atlasMine != address(0), "BattleflyAtlasStaker: invalid address");
        MAGIC = IERC20Upgradeable(_magic);
        ATLAS_MINE = IAtlasMine(_atlasMine);

        superAdmins[msg.sender] = true;
        LOCKS = [
            IAtlasMine.Lock.twoWeeks,
            IAtlasMine.Lock.oneMonth,
            IAtlasMine.Lock.threeMonths,
            IAtlasMine.Lock.sixMonths,
            IAtlasMine.Lock.twelveMonths
        ];

        nextExecution = block.timestamp;

        setTreasury(_treasury);
        setBattleflyBot(_battleflyBot);
        setAllowedLocks(_allowedLocks);

        approveLegion(true);
        approveTreasure(true);
    }

    // ============================== Vault Operations ==============================

    /**
     * @dev deposit an amount of MAGIC in the AtlasStaker for a particular lock period
     */
    function deposit(uint256 _amount, IAtlasMine.Lock _lock)
        external
        override
        onlyWhitelistedVaults
        nonReentrant
        whenNotPaused
        onlyAvailableLock(_lock)
        returns (uint256)
    {
        require(_amount > 0, "BattflyAtlasStaker: cannot deposit 0");
        // Transfer MAGIC from Vault
        MAGIC.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 newDepositId = ++currentDepositId;
        _deposit(newDepositId, _amount, _lock);
        return newDepositId;
    }

    /**
     * @dev withdraw a vaultstake from the AtlasStaker with a specific depositId
     */
    function withdraw(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        // withdraw can only happen if the retention period has passed.
        require(canWithdraw(_depositId), "BattleflyAtlasStaker: position is locked");

        amount = vaultStake.amount;
        // Withdraw MAGIC to user
        MAGIC.safeTransfer(msg.sender, amount);

        // claim remaining emissions
        (uint256 emission, ) = getClaimableEmission(_depositId);
        if (emission > 0) {
            amount += _claim(_depositId);
        }

        // Reset vault stake data
        delete vaultStakes[_depositId];
        depositIdByVault[msg.sender].remove(_depositId);
        emit WithdrawPosition(msg.sender, amount, _depositId);
    }

    /**
     * @dev Claim emissions from a vaultstake in the AtlasStaker with a specific depositId
     */
    function claim(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        amount = _claim(_depositId);
    }

    /**
     * @dev Request a withdrawal for a specific depositId. This is required because the vaultStake will be restaked in blocks of 2 weeks after the unlock period has passed.
     * This function is used to notify the AtlasStaker that it should not restake the vaultStake on the next iteration and the initial stake becomes unlocked.
     */
    function requestWithdrawal(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint64) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        require(vaultStake.retentionUnlock == 0, "BattleflyAtlasStaker: withdrawal already requested");
        // Every epoch is 1 day; We can start requesting for a withdrawal 14 days before the unlock period.
        require(currentEpoch >= (vaultStake.unlockAt - 14), "BattleflyAtlasStaker: position not yet unlockable");

        // We set the retention period before the withdrawal can happen to the nearest epoch in the future
        uint64 retentionUnlock = currentEpoch < vaultStake.unlockAt
            ? vaultStake.unlockAt
            : currentEpoch + (14 - ((currentEpoch - vaultStake.unlockAt) % 14));
        vaultStake.retentionUnlock = retentionUnlock - 1 == currentEpoch ? retentionUnlock + 14 : retentionUnlock;
        unstakeAmountAtEpoch[vaultStake.retentionUnlock - 1] += vaultStake.amount;
        emit RequestWithdrawal(msg.sender, vaultStake.retentionUnlock, _depositId);
        return vaultStake.retentionUnlock;
    }

    // ============================== Super Admin Operations ==============================

    /**
     * @dev Execute the daily cron job to deposit funds to AtlasMine & claim emissions from AtlasMine
     *      The Battlefly CRON BOT will use this function to execute deposit/claim.
     */
    function executeAll() external onlyBattleflyBot {
        require(block.timestamp >= nextExecution, "BattleflyAtlasStaker: Executed less than 24h ago");
        // set to 24 hours - 5 minutes to take blockchain tx delays into account.
        nextExecution = block.timestamp + 86100;

        // Harvest all positions from AtlasMine
        _executeHarvestAll();

        // Withdraw all positions from AtlasMine
        _executeWithdrawAll();

        // Possibly correct the amount to be deposited due to users withdrawing their stake.
        _correctForUserWithdrawals();

        // Stake all funds to AtlasMine
        _executeDepositAll();
    }

    /**
     * @dev Approve TREASURE ERC1155 NFT transfer to deposit into AtlasMine contract
     */
    function approveTreasure(bool _approve) public onlySuperAdmin {
        getTREASURE().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Approve LEGION ERC721 NFT transfer to deposit into AtlasMine contract
     */
    function approveLegion(bool _approve) public onlySuperAdmin {
        getLEGION().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Stake TREASURE ERC1155 NFT
     */
    function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");

        // Caller's balance check already implemented in _safeTransferFrom() in ERC1155Upgradeable contract
        getTREASURE().safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] += _amount;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeTreasure(_tokenId, _amount);
        emit StakedTreasure(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Unstake TREASURE ERC1155 NFT
     */
    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");
        require(treasureStakers[_tokenId][msg.sender] >= _amount, "BattleflyAtlasStaker: Invalid TREASURE amount");
        // Unstake TREASURE from AtlasMine
        ATLAS_MINE.unstakeTreasure(_tokenId, _amount);

        // Transfer TREASURE to the staker
        getTREASURE().safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] -= _amount;
        emit UnstakedTreasure(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Stake LEGION ERC721 NFT
     */
    function stakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        // TokenId ownership validation is already implemented in safeTransferFrom function
        getLEGION().safeTransferFrom(msg.sender, address(this), _tokenId, "");
        legionStakers[_tokenId] = msg.sender;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeLegion(_tokenId);
        emit StakedLegion(msg.sender, _tokenId);
    }

    /**
     * @dev Unstake LEGION ERC721 NFT
     */
    function unstakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        require(legionStakers[_tokenId] == msg.sender, "BattleflyAtlasStaker: Invalid staker");
        // Unstake LEGION from AtlasMine
        ATLAS_MINE.unstakeLegion(_tokenId);

        // Transfer LEGION to the staker
        getLEGION().safeTransferFrom(address(this), msg.sender, _tokenId, "");
        legionStakers[_tokenId] = address(0);
        emit UnstakedLegion(msg.sender, _tokenId);
    }

    // ============================== Owner Operations ==============================

    /**
     * @dev Add super admin permission
     */
    function addSuperAdmin(address _admin) public onlyOwner {
        require(!superAdmins[_admin], "BattleflyAtlasStaker: admin already exists");
        superAdmins[_admin] = true;
        emit AddedSuperAdmin(_admin);
    }

    /**
     * @dev Batch adding super admin permission
     */
    function addSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            addSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Remove super admin permission
     */
    function removeSuperAdmin(address _admin) public onlyOwner {
        require(superAdmins[_admin], "BattleflyAtlasStaker: admin does not exist");
        superAdmins[_admin] = false;
        emit RemovedSuperAdmin(_admin);
    }

    /**
     * @dev Batch removing super admin permission
     */
    function removeSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            removeSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Add vault address
     */
    function addVault(address _vault, Vault calldata _vaultData) public onlyOwner {
        require(!vaults[_vault].enabled, "BattleflyAtlasStaker: vault is already added");
        require(_vaultData.fee + _vaultData.claimRate == FEE_DENOMINATOR, "BattleflyAtlasStaker: invalid vault info");

        Vault storage vault = vaults[_vault];
        vault.fee = _vaultData.fee;
        vault.claimRate = _vaultData.claimRate;
        vault.enabled = true;
        emit AddedVault(_vault, vault.fee, vault.claimRate);
    }

    /**
     * @dev Remove vault address
     */
    function removeVault(address _vault) public onlyOwner {
        Vault storage vault = vaults[_vault];
        require(vault.enabled, "BattleflyAtlasStaker: vault does not exist");
        vault.enabled = false;
        emit RemovedVault(_vault);
    }

    /**
     * @dev Set allowed locks
     */
    function setAllowedLocks(IAtlasMine.Lock[] memory _locks) public onlyOwner {
        allowedLocks = _locks;
    }

    /**
     * @dev Set treasury wallet address
     */
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "BattleflyAtlasStaker: invalid address");
        TREASURY_VAULT = IBattleflyTreasuryFlywheelVault(_treasury);
        emit SetTreasury(_treasury);
    }

    /**
     * @dev Set daily bot address
     */
    function setBattleflyBot(address _battleflyBot) public onlyOwner {
        require(_battleflyBot != address(0), "BattleflyAtlasStaker: invalid address");
        BATTLEFLY_BOT = _battleflyBot;
        emit SetBattleflyBot(_battleflyBot);
    }

    function setPause(bool _paused) external override onlyOwner {
        pausedUntil = _paused ? block.timestamp + 48 hours : 0;
        emit SetPause(_paused);
    }

    // ============================== VIEW ==============================

    /**
     * @dev Validate the lock period
     */
    function isValidLock(IAtlasMine.Lock _lock) public view returns (bool) {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == _lock) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get AtlasMine TREASURE ERC1155 NFT address
     */
    function getTREASURE() public view returns (IERC1155Upgradeable) {
        return IERC1155Upgradeable(ATLAS_MINE.treasure());
    }

    /**
     * @dev Get AtlasMine LEGION ERC721 NFT address
     */
    function getLEGION() public view returns (IERC721Upgradeable) {
        return IERC721Upgradeable(ATLAS_MINE.legion());
    }

    /**
     * @dev Get Unstaked MAGIC amount
     */
    function getUnstakedAmount() public view returns (uint256 amount) {
        IAtlasMine.Lock[] memory locks = LOCKS;
        for (uint256 i = 0; i < locks.length; i++) {
            amount += unstakedAmount[locks[i]];
        }
    }

    /**
     * @dev Get claimable MAGIC emission.
     * Emissions are:
     *      Emissions from normal lock period +
     *      Emissions from retention period -
     *      Already received emissions
     */
    function getClaimableEmission(uint256 _depositId) public view override returns (uint256 emission, uint256 fee) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        if (currentEpoch > 0) {
            uint64 retentionLock = vaultStake.retentionUnlock == 0 ? currentEpoch + 1 : vaultStake.retentionUnlock;
            uint64 x = vaultStake.retentionUnlock == 0 || vaultStake.retentionUnlock != vaultStake.unlockAt ? 0 : 1;
            emission =
                _getEmissionsForPeriod(vaultStake.amount, vaultStake.lockAt, vaultStake.unlockAt - x, vaultStake.lock) +
                _getEmissionsForPeriod(vaultStake.amount, vaultStake.unlockAt, retentionLock, vaultStake.lock) -
                vaultStake.paidEmission;
        }
        Vault memory vault = vaults[vaultStake.vault];
        fee = (emission * vault.fee) / FEE_DENOMINATOR;
        emission -= fee;
    }

    /**
     * @dev Get staked amount
     */
    function getDepositedAmount(uint256[] memory _depositIds) public view returns (uint256 amount) {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            amount += vaultStakes[_depositIds[i]].amount;
        }
    }

    /**
     * @dev Get allowed locks
     */
    function getAllowedLocks() public view override returns (IAtlasMine.Lock[] memory) {
        return allowedLocks;
    }

    /**
     * @dev Get vault staked data
     */
    function getVaultStake(uint256 _depositId) public view override returns (VaultStake memory) {
        return vaultStakes[_depositId];
    }

    /**
     * @dev Gets the lock period in epochs
     */
    function getLockPeriod(IAtlasMine.Lock _lock) external view override returns (uint64 epoch) {
        return BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days;
    }

    /**
     * @dev Check if a vaultStake can be withdrawn
     */
    function canWithdraw(uint256 _depositId) public view override returns (bool withdrawable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        withdrawable = (vaultStake.retentionUnlock > 0) && (vaultStake.retentionUnlock <= currentEpoch);
    }

    /**
     * @dev Check if a vaultStake can request a withdrawal
     */
    function canRequestWithdrawal(uint256 _depositId) public view override returns (bool requestable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        requestable = (vaultStake.retentionUnlock == 0) && (currentEpoch >= (vaultStake.unlockAt - 14));
    }

    /**
     * @dev Get the depositIds of a user
     */
    function depositIdsOfVault(address vault) public view override returns (uint256[] memory depositIds) {
        return depositIdByVault[vault].values();
    }

    // ============================== Internal ==============================

    /**
     * @dev recalculate and update the emissions per share per lock period and per epoch
     *      1 share is 1 wei of Magic.
     */
    function _updateEmissionsForEpoch() private returns (uint256 totalEmission) {
        uint256[] memory positionIds = activePositionIds.values();

        // Total emissions of the current epoch are at least as much as the total emissions of the previous epoch
        for (uint256 i = 0; i < LOCKS.length; i++) {
            totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch] = currentEpoch > 0
                ? totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch - 1]
                : 0;
        }

        // Calculate the total amount of pending emissions and the total deposited amount for each lock period in the current epoch
        for (uint256 j = 0; j < positionIds.length; j++) {
            uint256 pendingRewards = ATLAS_MINE.pendingRewardsPosition(address(this), positionIds[j]);
            (, uint256 currentAmount, , , , , IAtlasMine.Lock _lock) = ATLAS_MINE.userInfo(
                address(this),
                positionIds[j]
            );
            totalEmission += pendingRewards;
            totalEmissionsAtEpochForLock[_lock][currentEpoch] += pendingRewards;
            totalStakedAtEpochForLock[_lock][currentEpoch] += currentAmount;
        }

        // Calculate the accrued emissions per share by (totalEmission * 1e18) / totalStaked
        // Set the total emissions to the accrued emissions of the current epoch + the previous epochs
        for (uint256 k = 0; k < LOCKS.length; k++) {
            uint256 totalStaked = totalStakedAtEpochForLock[LOCKS[k]][currentEpoch];
            if (totalStaked > 0) {
                uint256 accruedRewardsPerShare = (totalEmission * ONE) / totalStaked;
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1] + accruedRewardsPerShare
                    : accruedRewardsPerShare;
            } else {
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1]
                    : 0;
            }
        }
    }

    /**
     * @dev get the total amount of emissions of a certain period between two epochs.
     */
    function _getEmissionsForPeriod(
        uint256 amount,
        uint64 startEpoch,
        uint64 stopEpoch,
        IAtlasMine.Lock lock
    ) private view returns (uint256 emissions) {
        if (stopEpoch >= startEpoch && currentEpoch >= startEpoch) {
            uint256 totalEmissions = (amount * totalPerShareAtEpochForLock[lock][currentEpoch - 1]);
            uint256 emissionsTillExclusion = (amount * totalPerShareAtEpochForLock[lock][stopEpoch - 1]);
            uint256 emissionsTillInclusion = (amount * totalPerShareAtEpochForLock[lock][startEpoch - 1]);
            uint256 emissionsFromExclusion = emissionsTillExclusion > 0 ? (totalEmissions - emissionsTillExclusion) : 0;
            emissions = (totalEmissions - emissionsFromExclusion - emissionsTillInclusion) / ONE;
        }
    }

    /**
     * @dev Deposit MAGIC to AtlasMine
     */
    function _deposit(
        uint256 _depositId,
        uint256 _amount,
        IAtlasMine.Lock _lock
    ) private returns (uint256) {
        // We only deposit to AtlasMine in the next epoch. We can unlock after the lock period has passed.
        uint64 lockAt = currentEpoch + 1;
        uint64 unlockAt = currentEpoch + 1 + (BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days);

        vaultStakes[_depositId] = VaultStake(lockAt, unlockAt, 0, _amount, 0, msg.sender, _lock);
        // Updated unstaked MAGIC amount
        unstakedAmount[_lock] += _amount;
        depositIdByVault[msg.sender].add(_depositId);
        emit NewDeposit(msg.sender, _amount, unlockAt, _depositId);
        return unlockAt;
    }

    /**
     * @dev Claim emissions for a depositId
     */
    function _claim(uint256 _depositId) internal returns (uint256) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");

        (uint256 emission, uint256 fee) = getClaimableEmission(_depositId);
        if (emission > 0) {
            MAGIC.safeTransfer(msg.sender, emission);
            if (fee > 0) {
                MAGIC.approve(address(TREASURY_VAULT), fee);
                TREASURY_VAULT.topupMagic(fee);
            }
            uint256 amount = emission + fee;
            vaultStake.paidEmission += amount;
            emit ClaimEmission(msg.sender, emission, _depositId);
        }
        return emission;
    }

    /**
     * @dev Execute the daily cron job to harvest all emissions from AtlasMine
     */
    function _executeHarvestAll() internal {
        uint256 pendingHarvest = _updateEmissionsForEpoch();
        uint256 preHarvest = MAGIC.balanceOf(address(this));
        for (uint64 i = 0; i < activePositionIds.length(); i++) {
            ATLAS_MINE.harvestPosition(activePositionIds.at(i));
        }
        uint256 harvested = MAGIC.balanceOf(address(this)) - preHarvest;
        require(pendingHarvest == harvested, "BattleflyAtlasStaker: pending harvest and actual harvest are not equal");
        // Increment the epoch
        currentEpoch++;
    }

    /**
     * @dev Possibly correct the amount to be deposited due to users withdrawing their stake.
     */
    function _correctForUserWithdrawals() internal {
        if (unstakedAmount[IAtlasMine.Lock.twoWeeks] >= unstakeAmountAtEpoch[currentEpoch]) {
            unstakedAmount[IAtlasMine.Lock.twoWeeks] -= unstakeAmountAtEpoch[currentEpoch];
        } else {
            //If not enough withdrawals available from current epoch, request more from the next epoch
            unstakeAmountAtEpoch[currentEpoch + 1] += (unstakeAmountAtEpoch[currentEpoch] -
                unstakedAmount[IAtlasMine.Lock.twoWeeks]);
            unstakedAmount[IAtlasMine.Lock.twoWeeks] = 0;
        }
    }

    /**
     * @dev Execute the daily cron job to deposit all to AtlasMine
     */
    function _executeDepositAll() internal {
        uint256 unstaked;
        for (uint256 i = 0; i < LOCKS.length; i++) {
            uint256 amount = unstakedAmount[LOCKS[i]];
            if (amount > 0) {
                unstaked += amount;
                MAGIC.safeApprove(address(ATLAS_MINE), amount);
                ATLAS_MINE.deposit(amount, LOCKS[i]);
                activePositionIds.add(ATLAS_MINE.currentId(address(this)));
                unstakedAmount[LOCKS[i]] = 0;
            }
        }
        emit DepositedAllToMine(unstaked);
    }

    /**
     * @dev Execute the daily cron job to withdraw all positions from AtlasMine
     */
    function _executeWithdrawAll() internal {
        uint256[] memory depositIds = activePositionIds.values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            (uint256 amount, , , uint256 lockedUntil, , , IAtlasMine.Lock lock) = ATLAS_MINE.userInfo(
                address(this),
                depositIds[i]
            );
            uint256 totalLockedPeriod = lockedUntil + ATLAS_MINE.getVestingTime(lock);

            // If the position is available to withdraw
            if (totalLockedPeriod <= block.timestamp) {
                ATLAS_MINE.withdrawPosition(depositIds[i], type(uint256).max);
                activePositionIds.remove(depositIds[i]);
                // Directly register for restaking, unless a withdrawal is requested (we correct this in _correctForUserWithdrawals())
                unstakedAmount[IAtlasMine.Lock.twoWeeks] += uint256(amount);
            }
        }
    }

    // ============================== Modifiers ==============================

    modifier onlySuperAdmin() {
        require(superAdmins[msg.sender], "BattleflyAtlasStaker: caller is not a super admin");
        _;
    }

    modifier onlyWhitelistedVaults() {
        require(vaults[msg.sender].enabled, "BattleflyAtlasStaker: caller is not whitelisted");
        _;
    }

    modifier onlyAvailableLock(IAtlasMine.Lock _lock) {
        require(isValidLock(_lock), "BattleflyAtlasStaker: invalid lock period");
        _;
    }

    modifier onlyBattleflyBot() {
        require(msg.sender == BATTLEFLY_BOT, "BattleflyAtlasStaker: caller is not a battlefly bot");
        _;
    }

    modifier whenNotPaused() {
        require(block.timestamp > pausedUntil, "BattleflyAtlasStaker: contract paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAtlasMine.sol";

library BattleflyAtlasStakerUtils {
    /**
     * @dev Get lock period
     *      Need to consider about adding 1 more day to lock period regarding the daily cron job
     */
    function getLockPeriod(IAtlasMine.Lock _lock, IAtlasMine ATLAS_MINE) external pure returns (uint64) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            return 14 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.oneMonth) {
            return 30 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.threeMonths) {
            return 90 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.sixMonths) {
            return 180 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.twelveMonths) {
            return 365 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }

        revert("BattleflyAtlasStaker: Invalid Lock");
    }
}

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract HyperdomeContract is ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(address => bool) private adminAccess;

    function initialize() public initializer {
        __ERC721_init("HyperdomeLand", "Hyperdome");
        __Ownable_init();
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function mintHyperdome(address receiver) external onlyAdminAccess returns (uint256) {
        uint256 nextTokenId = _getNextTokenId();
        _mint(receiver, nextTokenId);
        return nextTokenId;
    }

    function _getNextTokenId() private view returns (uint256) {
        return (_tokenIdCounter.current());
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721Upgradeable) {
        super._mint(to, tokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract SpecialNFTContract is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    mapping(address => bool) private adminAccess;
    mapping(uint256 => uint256) private specialNFTTypes;

    CountersUpgradeable.Counter private _tokenIdCounter;
    event SetAdminAccess(address indexed user, bool access);

    function initialize() public initializer {
        __ERC721Enumerable_init();
        __ERC721_init("Battlefly Special NFTs", "BattleflySNFT");
        __Ownable_init();
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    function mintSpecialNFTs(
        address receiver,
        uint256 _specialNFTType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 nextTokenId = _getNextTokenId();
            _mint(receiver, nextTokenId);
            specialNFTTypes[nextTokenId] = _specialNFTType;
            tokenIds[i] = nextTokenId;
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://api.battlefly.game/specials/", tokenId.toString(), "/metadata"));
    }

    function mintSpecialNFT(address receiver, uint256 specialNFTType) external onlyAdminAccess returns (uint256) {
        uint256 nextTokenId = _getNextTokenId();
        _mint(receiver, nextTokenId);
        specialNFTTypes[nextTokenId] = specialNFTType;
        return nextTokenId;
    }

    function getSpecialNFTType(uint256 tokenId) external view returns (uint256) {
        return specialNFTTypes[tokenId];
    }

    function _getNextTokenId() private view returns (uint256) {
        return (_tokenIdCounter.current() + 1);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721Upgradeable) {
        super._mint(to, tokenId);
        _tokenIdCounter.increment();
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ModContract is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    mapping(address => bool) private adminAccess;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(uint256 => Mod) private mods;

    struct Mod {
        uint256 modId;
        uint256 item;
        uint256 mountType;
    }

    function initialize() public initializer {
        __ERC721Enumerable_init();
        __ERC721_init("Mod", "Mod");
        __Ownable_init();
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function mintMod(address receiver, Mod memory mod) external onlyAdminAccess returns (uint256) {
        uint256 nextTokenId = _getNextTokenId();
        _mint(receiver, nextTokenId);
        mod.modId = nextTokenId;
        mods[nextTokenId] = mod;
        return nextTokenId;
    }

    function _getNextTokenId() private view returns (uint256) {
        return (_tokenIdCounter.current() + 1);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721Upgradeable) {
        super._mint(to, tokenId);
        _tokenIdCounter.increment();
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ItemContract is OwnableUpgradeable, ERC1155Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping(address => bool) private adminAccess;
    event SetAdminAccess(address indexed user, bool access);
    string _contractURI;

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
    }

    function name() public view virtual returns (string memory) {
        return "Battlefly Items";
    }

    function symbol() public view virtual returns (string memory) {
        return "Battlefly ITEM";
    }

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function mintItems(
        uint256 itemId,
        address receiver,
        uint256 amount,
        bytes memory data
    ) external onlyAdminAccess {
        _mint(receiver, itemId, amount, data);
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IBattleflyGame.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BattleflyPublicMint is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    mapping(address => bool) public HasMinted;

    bytes32 public merkleRootBattlefly;

    mapping(address => bool) private adminAccess;
    IBattleflyGame Game;
    uint256 public StartTime;
    uint256 public EndTime;
    uint256 public BattleflyType;
    uint256 public MinMagicAmountHolder;
    ERC20 MagicToken;
    mapping(bytes32 => bool) public HasMintedTicket;

    event PublicMintBattlefly(address indexed to, uint256 battleflyType, uint256 battleflyId, bytes32 indexed ticket);

    function initialize(address battleflyGameContractAddress, address magicTokenAddress) public initializer {
        __Ownable_init();
        Game = IBattleflyGame(battleflyGameContractAddress);
        MagicToken = ERC20(magicTokenAddress);
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function setMerkleRootBattlefly(bytes32 merkleRoot) external onlyAdminAccess {
        merkleRootBattlefly = merkleRoot;
    }

    function setHasMinted(address user, bool value) external onlyAdminAccess {
        HasMinted[user] = value;
    }

    function setMinting(
        uint256 start,
        uint256 end,
        uint256 minMagicAmountHolder,
        uint256 battleflyType
    ) external onlyAdminAccess {
        StartTime = start;
        EndTime = end;
        MinMagicAmountHolder = minMagicAmountHolder;
        BattleflyType = battleflyType;
    }

    function mintBattlefly(bytes32 ticket, bytes32[] calldata proof) external {
        address to = _msgSender();
        require(block.timestamp >= StartTime, "Not start yet");
        require(block.timestamp <= EndTime, "Already finished");
        require(HasMinted[to] == false, "Already minted");
        require(HasMintedTicket[ticket] == false, "Already minted - ticket");

        if (MinMagicAmountHolder != 0)
            require(MagicToken.balanceOf(_msgSender()) >= MinMagicAmountHolder, "You must hold an amount of Magic");

        bytes32 leaf = keccak256(abi.encodePacked(ticket));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRootBattlefly, leaf);
        require(isValidLeaf, "Not in merkle");

        HasMinted[to] = true;
        HasMintedTicket[ticket] = true;
        uint256 battleflyId = Game.mintBattlefly(to, BattleflyType);

        emit PublicMintBattlefly(to, BattleflyType, battleflyId, ticket);
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract BattleflyContract is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    mapping(address => bool) private adminAccess;
    mapping(uint256 => uint256) private battleflyTypes;

    CountersUpgradeable.Counter private _tokenIdCounter;
    event SetAdminAccess(address indexed user, bool access);

    function initialize() public initializer {
        __ERC721Enumerable_init();
        __ERC721_init("Battlefly", "Battlefly");
        __Ownable_init();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://api.battlefly.game/battleflies/", tokenId.toString(), "/metadata"));
    }

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    function mintBattlefly(address receiver, uint256 battleflyType) external onlyAdminAccess returns (uint256) {
        uint256 nextTokenId = _getNextTokenId();
        battleflyTypes[nextTokenId] = battleflyType;
        _mint(receiver, nextTokenId);
        return nextTokenId;
    }

    function mintBattleflies(
        address receiver,
        uint256 _battleflyType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 nextTokenId = _getNextTokenId();
            battleflyTypes[nextTokenId] = _battleflyType;
            tokenIds[i] = nextTokenId;
            _mint(receiver, nextTokenId);
        }
        return tokenIds;
    }

    function getBattleflyType(uint256 tokenId) external view returns (uint256) {
        return battleflyTypes[tokenId];
    }

    function _getNextTokenId() private view returns (uint256) {
        return (_tokenIdCounter.current() + 1);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721Upgradeable) {
        super._mint(to, tokenId);
        _tokenIdCounter.increment();
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
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

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStaker.sol";

import "hardhat/console.sol";

contract BattleflyAtlasStakerV01 is
    IBattleflyAtlasStaker,
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
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /// @notice MAGIC token
    /// @dev functionally immutable
    IERC20Upgradeable public magic;
    /// @notice The IAtlasMine
    /// @dev functionally immutable
    IAtlasMine public mine;

    // ============= Global Staking State ==============
    uint256 public constant ONE = 1e30;

    /// @notice Whether new stakes will get staked on the contract as scheduled. For emergencies
    bool public schedulePaused;
    /// @notice The total amount of staked token
    uint256 public totalStaked;
    /// @notice The total amount of share
    uint256 public totalShare;
    /// @notice All stakes currently active
    Stake[] public stakes;
    /// @notice Deposit ID of last stake. Also tracked in atlas mine
    uint256 public lastDepositId;
    /// @notice Rewards accumulated per share
    uint256 public accRewardsPerShare;

    // ============= Vault Staking State ==============
    mapping(address => bool) public battleflyVaults;

    /// @notice Each vault stake, keyed by vault contract address => deposit ID
    mapping(address => mapping(uint256 => VaultStake)) public vaultStake;
    /// @notice All deposit IDs fro a vault, enumerated
    mapping(address => EnumerableSetUpgradeable.UintSet) private allVaultDepositIds;
    /// @notice The current ID of the vault's last deposited stake
    mapping(address => uint256) public currentId;

    // ============= NFT Boosting State ==============

    /// @notice Holder of treasures and legions
    mapping(uint256 => bool) public legionsStaked;
    mapping(uint256 => uint256) public treasuresStaked;

    // ============= Operator State ==============

    IAtlasMine.Lock[] public allowedLocks;
    /// @notice Fee to contract operator. Only assessed on rewards.
    uint256 public fee;
    /// @notice Amount of fees reserved for withdrawal by the operator.
    uint256 public feeReserve;
    /// @notice Max fee the owner can ever take - 10%
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(address => mapping(uint256 => int256)) refundedFeeDebts;
    uint256 accRefundedFeePerShare;
    uint256 totalWhitelistedFeeShare;
    EnumerableSetUpgradeable.AddressSet whitelistedFeeVaults;
    mapping(address => bool) public superAdmins;

    /// @notice deposited but unstaked
    uint256 public unstakedDeposits;
    mapping(IAtlasMine.Lock => uint256) public unstakedDepositsByLock;
    address public constant TREASURY_WALLET = 0xF5411006eEfD66c213d2fd2033a1d340458B7226;
    /// @notice Intra-tx buffer for pending payouts
    uint256 public tokenBuffer;

    // ===========================================
    // ============== Post Upgrade ===============
    // ===========================================

    // ========================================== INITIALIZER ===========================================

    /**
     * @param _magic                The MAGIC token address.
     * @param _mine                 The IAtlasMine contract.
     *                              Maps to a timelock for IAtlasMine deposits.
     */
    function initialize(
        IERC20Upgradeable _magic,
        IAtlasMine _mine,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = _magic;
        mine = _mine;
        allowedLocks = _allowedLocks;
        fee = 1000;
        // Approve the mine
        magic.safeApprove(address(mine), 2**256 - 1);
    }

    // ======================================== VAULT OPERATIONS ========================================

    /**
     * @notice Make a new deposit into the Staker. The Staker will collect
     *         the tokens, to be later staked in atlas mine by the owner,
     *         according to the stake/unlock schedule.
     * @dev    Specified amount of token must be approved by the caller.
     *
     * @param _amount               The amount of tokens to deposit.
     */
    function deposit(uint256 _amount, IAtlasMine.Lock lock)
        public
        virtual
        override
        onlyBattleflyVaultOrOwner
        nonReentrant
        returns (uint256)
    {
        require(!schedulePaused, "new staking paused");
        _updateRewards();
        // Collect tokens
        uint256 newDepositId = _deposit(_amount, msg.sender, lock);
        magic.safeTransferFrom(msg.sender, address(this), _amount);
        return (newDepositId);
    }

    function _deposit(
        uint256 _amount,
        address _vault,
        IAtlasMine.Lock lock
    ) internal returns (uint256) {
        require(_amount > 0, "Deposit amount 0");
        bool validLock = false;
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == lock) {
                validLock = true;
                break;
            }
        }
        require(validLock, "Lock time not allowed");
        // Add vault stake
        uint256 newDepositId = ++currentId[_vault];
        allVaultDepositIds[_vault].add(newDepositId);
        VaultStake storage s = vaultStake[_vault][newDepositId];

        s.amount = _amount;
        (uint256 boost, uint256 lockTime) = getLockBoost(lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;

        uint256 vestingTime = mine.getVestingTime(lock);
        s.unlockAt = block.timestamp + lockTime + vestingTime + 1 days;
        s.rewardDebt = ((share * accRewardsPerShare) / ONE).toInt256();
        s.lock = lock;

        // Update global accounting
        totalStaked += _amount;
        totalShare += share;
        if (whitelistedFeeVaults.contains(_vault)) {
            totalWhitelistedFeeShare += share;
            refundedFeeDebts[_vault][newDepositId] = ((share * accRefundedFeePerShare) / ONE).toInt256();
        }
        // MAGIC tokens sit in contract. Added to pending stakes
        unstakedDeposits += _amount;
        unstakedDepositsByLock[lock] += _amount;
        emit VaultDeposit(_vault, newDepositId, _amount, s.unlockAt, s.lock);
        return newDepositId;
    }

    /**
     * @notice Withdraw a deposit from the Staker contract. Calculates
     *         pro rata share of accumulated MAGIC and distributes any
     *         earned rewards in addition to original deposit.
     *         There must be enough unlocked tokens to withdraw.
     *
     * @param depositId             The ID of the deposit to withdraw from.
     *
     */
    function withdraw(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        require(block.timestamp >= s.unlockAt, "Deposit locked");

        uint256 payout = _withdraw(s, depositId);
        magic.safeTransfer(msg.sender, payout);
    }

    /**
     * @notice Withdraw all eligible deposits from the staker contract.
     *         Will skip any deposits not yet unlocked. Will also
     *         distribute rewards for all stakes via 'withdraw'.
     *
     */
    function withdrawAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];

            if (s.amount > 0 && s.unlockAt > 0 && s.unlockAt <= block.timestamp) {
                tokenBuffer += _withdraw(s, depositIds[i]);
            }
        }
        magic.safeTransfer(msg.sender, tokenBuffer);
        tokenBuffer = 0;
    }

    /**
     * @dev Logic for withdrawing a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @dev An _amount argument larger than the total deposit amount will
     *      withdraw the entire deposit.
     *
     * @param s                     The VaultStake struct to withdraw from.
     * @param depositId             The ID of the deposit to withdraw from (for event).
     */
    function _withdraw(VaultStake storage s, uint256 depositId) internal returns (uint256 payout) {
        uint256 _amount = s.amount;

        // Unstake if we need to to ensure we can withdraw
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;
        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();
        if (whitelistedFeeVaults.contains(msg.sender)) {
            accumulatedRewards += ((share * accRefundedFeePerShare) / ONE).toInt256();
            accumulatedRewards -= refundedFeeDebts[msg.sender][depositId];
            totalWhitelistedFeeShare -= share;
            refundedFeeDebts[msg.sender][depositId] = 0;
        }
        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();
        payout = _amount + reward;

        delete vaultStake[msg.sender][depositId];

        // Update global accounting
        totalStaked -= _amount;

        totalShare -= share;

        // If we need to unstake, unstake until we have enough
        if (payout > _totalUsableMagic()) {
            _unstakeToTarget(payout - _totalUsableMagic());
        }
        emit VaultWithdraw(msg.sender, depositId, _amount, reward);
    }

    /**
     * @notice Claim rewards without unstaking. Will fail if there
     *         are not enough tokens in the contract to claim rewards.
     *         Does not attempt to unstake.
     *
     * @param depositId             The ID of the deposit to claim rewards from.
     *
     */
    function claim(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        uint256 reward = _claim(s, depositId);
        magic.safeTransfer(msg.sender, reward);
        return reward;
    }

    /**
     * @notice Claim all possible rewards from the staker contract.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];
            uint256 reward = _claim(s, depositIds[i]);
            totalReward += reward;
        }
        magic.safeTransfer(msg.sender, totalReward);
        return totalReward;
    }

    /**
     * @notice Claim all possible rewards from the staker contract then restake.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAllAndRestake(IAtlasMine.Lock lock) public onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];
            uint256 reward = _claim(s, depositIds[i]);
            totalReward += reward;
        }
        _deposit(totalReward, msg.sender, lock);
        return totalReward;
    }

    /**
     * @dev Logic for claiming rewards on a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @param s                     The VaultStake struct to claim from.
     * @param depositId             The ID of the deposit to claim from (for event).
     */
    function _claim(VaultStake storage s, uint256 depositId) internal returns (uint256) {
        // Update accounting
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();

        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();

        if (whitelistedFeeVaults.contains(msg.sender)) {
            int256 accumulatedRefundedFee = ((share * accRefundedFeePerShare) / ONE).toInt256();
            reward += accumulatedRefundedFee.toUint256();
            reward -= refundedFeeDebts[msg.sender][depositId].toUint256();
            refundedFeeDebts[msg.sender][depositId] = accumulatedRefundedFee;
        }

        s.rewardDebt = accumulatedRewards;

        // Unstake if we need to to ensure we can withdraw
        if (reward > _totalUsableMagic()) {
            _unstakeToTarget(reward - _totalUsableMagic());
        }

        require(reward <= _totalUsableMagic(), "Not enough rewards to claim");
        emit VaultClaim(msg.sender, depositId, reward);
        return reward;
    }

    // ======================================= SUPER ADMIN OPERATIONS ========================================

    /**
     * @notice Stake a Treasure owned by the superAdmin into the Atlas Mine.
     *         Staked treasures will boost all vault deposits.
     * @dev    Any treasure must be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdminOrOwner {
        address treasureAddr = mine.treasure();
        require(IERC1155Upgradeable(treasureAddr).balanceOf(msg.sender, _tokenId) >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] += _amount;
        // First withdraw and approve
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, bytes(""));
        mine.stakeTreasure(_tokenId, _amount);
        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Unstake a Treasure from the Atlas Mine adn transfer to receiver.
     *
     * @param _receiver              The receiver .
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function unstakeTreasure(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlySuperAdminOrOwner {
        require(treasuresStaked[_tokenId] >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] -= _amount;
        address treasureAddr = mine.treasure();
        mine.unstakeTreasure(_tokenId, _amount);
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(address(this), _receiver, _tokenId, _amount, bytes(""));
        uint256 boost = mine.boosts(address(this));
        emit UnstakeNFT(_receiver, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Stake a Legion owned by the superAdmin into the Atlas Mine.
     *         Staked legions will boost all vault deposits.
     * @dev    Any legion be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function stakeLegion(uint256 _tokenId) external onlySuperAdminOrOwner {
        address legionAddr = mine.legion();

        require(IERC721Upgradeable(legionAddr).ownerOf(_tokenId) == msg.sender, "Not owner of legion");

        legionsStaked[_tokenId] = true;
        IERC721Upgradeable(legionAddr).safeTransferFrom(msg.sender, address(this), _tokenId);

        mine.stakeLegion(_tokenId);

        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Unstake a Legion from the Atlas Mine and return it to the superAdmin.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function unstakeLegion(address _receiver, uint256 _tokenId) external onlySuperAdminOrOwner {
        require(legionsStaked[_tokenId], "No legion");
        address legionAddr = mine.legion();
        delete legionsStaked[_tokenId];
        mine.unstakeLegion(_tokenId);

        // Distribute to superAdmin
        IERC721Upgradeable(legionAddr).safeTransferFrom(address(this), _receiver, _tokenId);
        uint256 boost = mine.boosts(address(this));

        emit UnstakeNFT(_receiver, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Stake any pending stakes before the current day. Callable
     *         by anybody. Any pending stakes will unlock according
     *         to the time this method is called, and the contract's defined
     *         lock time.
     */
    function stakeScheduled() external virtual override onlySuperAdminOrOwner {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            IAtlasMine.Lock lock = allowedLocks[i];
            _stakeInMine(unstakedDepositsByLock[lock], lock);
            unstakedDepositsByLock[lock] = 0;
        }
        unstakedDeposits = 0;
    }

    /**
     * @notice Unstake everything eligible for unstaking from Atlas Mine.
     *         Callable by owner. Should only be used in case of emergency
     *         or migration to a new contract, or if there is a need to service
     *         an unexpectedly large amount of withdrawals.
     *
     *         If unlockAll is set to true in the Atlas Mine, this can withdraw
     *         all stake.
     */
    function unstakeAllFromMine() external override onlySuperAdminOrOwner {
        // Unstake everything eligible
        _updateRewards();

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp) {
                continue;
            }

            // Withdraw position - auto-harvest
            mine.withdrawPosition(s.depositId, s.amount);
        }

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @notice Let owner unstake a specified amount as needed to make sure the contract is funded.
     *         Can be used to facilitate expected future withdrawals.
     *
     * @param target                The amount of tokens to reclaim from the mine.
     */
    function unstakeToTarget(uint256 target) external override onlySuperAdminOrOwner {
        _updateRewards();
        _unstakeToTarget(target);
    }

    /**
     * @notice Withdraw any accumulated reward fees to the treasury
     */
    function withdrawFeesToTreasury() external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        magic.safeTransfer(TREASURY_WALLET, amount);
        emit WithdrawFeesToTreasury(amount);
    }

    function stakeBackFeeTreasury(IAtlasMine.Lock lock) external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        emit WithdrawFeesToTreasury(amount);
        _deposit(amount, TREASURY_WALLET, lock);
    }

    /**
     * @notice Whitelist vault from fees.
     *
     * @param _vault                Vault address.
     * @param isSet                 Whether to enable or disable the vault whitelist.
     */
    function setFeeWhitelistVault(address _vault, bool isSet) external onlyOwner {
        require(_vault != address(0), "Invalid Vault");
        if (isSet) {
            whitelistedFeeVaults.add(_vault);
            totalWhitelistedFeeShare += totalShareOf(_vault);
        } else {
            whitelistedFeeVaults.remove(_vault);
            totalWhitelistedFeeShare -= totalShareOf(_vault);
        }
        emit SetFeeWhitelistVault(_vault, isSet);
    }

    // ======================================= OWNER OPERATIONS =======================================

    function setBattleflyVault(address _vaultAddress, bool isSet) external onlyOwner {
        require(_vaultAddress != address(0), "Invalid vault");
        if (isSet) {
            require(battleflyVaults[_vaultAddress] == false, "Vault already set");
            battleflyVaults[_vaultAddress] = isSet;
        } else {
            require(allVaultDepositIds[_vaultAddress].length() == 0, "Vault is still active");
            delete battleflyVaults[_vaultAddress];
        }
        emit SetBattleflyVault(_vaultAddress, isSet);
    }

    /**
     * @notice Change the designated superAdmin, the address where treasures and
     *         legions are held. Staked NFTs can only be
     *         withdrawn to the current superAdmin address, regardless of which
     *         address the superAdmin was set to when it was staked.
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the superAdmin address.
     */
    function setBoostAdmin(address _superAdmin, bool isSet) external override onlyOwner {
        require(_superAdmin != address(0), "Invalid superAdmin");

        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Change the designated super admin, who manage the fee reverse
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the super admin address.
     */
    function setSuperAdmin(address _superAdmin, bool isSet) external onlyOwner {
        require(_superAdmin != address(0), "Invalid address");
        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Approve treasures and legions for withdrawal from the atlas mine.
     *         Called on startup, and should be called again in case contract
     *         addresses for treasures and legions ever change.
     *
     */
    function approveNFTs() public override onlyOwner {
        address treasureAddr = mine.treasure();
        IERC1155Upgradeable(treasureAddr).setApprovalForAll(address(mine), true);

        address legionAddr = mine.legion();
        IERC1155Upgradeable(legionAddr).setApprovalForAll(address(mine), true);
    }

    /**
     * @notice EMERGENCY ONLY - toggle pausing new scheduled stakes.
     *         If on, vaults can deposit, but stakes won't go to Atlas Mine.
     *         Can be used in case of Atlas Mine issues or forced migration
     *         to new contract.
     */
    function toggleSchedulePause(bool paused) external virtual override onlyOwner {
        schedulePaused = paused;

        emit StakingPauseToggle(paused);
    }

    // ======================================== VIEW FUNCTIONS =========================================
    function getLockBoost(IAtlasMine.Lock _lock) public pure virtual returns (uint256 boost, uint256 timelock) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            // 10%
            return (10e16, 14 days);
        } else if (_lock == IAtlasMine.Lock.oneMonth) {
            // 25%
            return (25e16, 30 days);
        } else if (_lock == IAtlasMine.Lock.threeMonths) {
            // 80%
            return (80e16, 13 weeks);
        } else if (_lock == IAtlasMine.Lock.sixMonths) {
            // 180%
            return (180e16, 23 weeks);
        } else if (_lock == IAtlasMine.Lock.twelveMonths) {
            // 400%
            return (400e16, 365 days);
        } else {
            revert("Invalid lock value");
        }
    }

    /**
     * @notice Returns all magic either unstaked, staked, or pending rewards in Atlas Mine.
     *         Best proxy for TVL.
     *
     * @return total               The total amount of MAGIC in the staker.
     */
    function totalMagic() external view override returns (uint256) {
        return _totalControlledMagic() + mine.pendingRewardsAll(address(this));
    }

    /**
     * @notice Returns all magic that has been deposited, but not staked, and is eligible
     *         to be staked (deposit time < current day).
     *
     * @return total               The total amount of MAGIC that can be withdrawn.
     */
    function totalWithdrawableMagic() external view override returns (uint256) {
        uint256 totalPendingRewards;

        // IAtlasMine attempts to divide by 0 if there are no deposits
        try mine.pendingRewardsAll(address(this)) returns (uint256 _pending) {
            totalPendingRewards = _pending;
        } catch Panic(uint256) {
            totalPendingRewards = 0;
        }

        return _totalUsableMagic() + totalPendingRewards;
    }

    /**
     * @notice Returns the details of a vault stake.
     *
     * @return vaultStake           The details of a vault stake.
     */
    function getVaultStake(address vault, uint256 depositId) external view override returns (VaultStake memory) {
        return vaultStake[vault][depositId];
    }

    /**
     * @notice Returns the pending, claimable rewards for a deposit.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     * @param depositId         The specific deposit to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewards(address vault, uint256 depositId) public view override returns (uint256 reward) {
        if (totalShare == 0) {
            return 0;
        }
        VaultStake storage s = vaultStake[vault][depositId];
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        uint256 unupdatedReward = mine.pendingRewardsAll(address(this));
        (uint256 founderReward, , uint256 feeRefund) = _calculateHarvestRewardFee(unupdatedReward);
        uint256 realAccRewardsPerShare = accRewardsPerShare + (founderReward * ONE) / totalShare;
        uint256 accumulatedRewards = (share * realAccRewardsPerShare) / ONE;
        if (whitelistedFeeVaults.contains(vault) && totalWhitelistedFeeShare > 0) {
            uint256 realAccRefundedFeePerShare = accRefundedFeePerShare + (feeRefund * ONE) / totalWhitelistedFeeShare;
            uint256 accumulatedRefundedFee = (share * realAccRefundedFeePerShare) / ONE;
            accumulatedRewards = accumulatedRewards + accumulatedRefundedFee;
            accumulatedRewards -= refundedFeeDebts[vault][depositId].toUint256();
        }
        reward = accumulatedRewards - s.rewardDebt.toUint256();
    }

    /**
     * @notice Returns the pending, claimable rewards for all of a vault's deposits.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewardsAll(address vault) external view override returns (uint256 reward) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();

        for (uint256 i = 0; i < depositIds.length; i++) {
            reward += pendingRewards(vault, depositIds[i]);
        }
    }

    /**
     * @notice Returns the total Share of a vault.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return _totalShare           The total share of a vault.
     */
    function totalShareOf(address vault) public view returns (uint256 _totalShare) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            (uint256 boost, ) = getLockBoost(vaultStake[vault][depositIds[i]].lock);
            uint256 share = (vaultStake[vault][depositIds[i]].amount * (100e16 + boost)) / 100e16;
            _totalShare += share;
        }
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Stake tokens held by staker in the Atlas Mine, according to
     *      the predefined lock value. Schedules for staking will be managed by a queue.
     *
     * @param _amount               Number of tokens to stake
     */
    function _stakeInMine(uint256 _amount, IAtlasMine.Lock lock) internal {
        require(_amount <= _totalUsableMagic(), "Not enough funds");

        uint256 depositId = ++lastDepositId;
        (, uint256 lockTime) = getLockBoost(lock);
        uint256 vestingPeriod = mine.getVestingTime(lock);
        uint256 unlockAt = block.timestamp + lockTime + vestingPeriod;

        stakes.push(Stake({ amount: _amount, unlockAt: unlockAt, depositId: depositId }));

        mine.deposit(_amount, lock);
    }

    /**
     * @dev Unstakes until we have enough unstaked tokens to meet a specific target.
     *      Used to make sure we can service withdrawals.
     *
     * @param target                The amount of tokens we want to have unstaked.
     */
    function _unstakeToTarget(uint256 target) internal {
        uint256 unstaked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp && !mine.unlockAll()) {
                // This stake is not unlocked - stop looking
                continue;
            }

            // Withdraw position - auto-harvest
            uint256 preclaimBalance = _totalUsableMagic();
            uint256 targetLeft = target - unstaked;
            uint256 amount = targetLeft > s.amount ? s.amount : targetLeft;

            // Do not harvest rewards - if this is running, we've already
            // harvested in the same fn call
            mine.withdrawPosition(s.depositId, amount);
            uint256 postclaimBalance = _totalUsableMagic();

            // Increment amount unstaked
            unstaked += postclaimBalance - preclaimBalance;

            if (unstaked >= target) {
                // We unstaked enough
                break;
            }
        }

        require(unstaked >= target, "Cannot unstake enough");
        require(_totalUsableMagic() >= target, "Not enough in contract after unstaking");

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @dev Harvest rewards from the IAtlasMine and send them back to
     *      this contract.
     *
     * @return earned               The amount of rewards earned for depositors, minus the fee.
     * @return feeEearned           The amount of fees earned for the contract operator.
     */
    function _harvestMine() internal returns (uint256, uint256) {
        uint256 preclaimBalance = magic.balanceOf(address(this));

        try mine.harvestAll() {
            uint256 postclaimBalance = magic.balanceOf(address(this));

            uint256 earned = postclaimBalance - preclaimBalance;
            // Reserve the 'fee' amount of what is earned
            (, uint256 feeEarned, uint256 feeRefunded) = _calculateHarvestRewardFee(earned);
            feeReserve += feeEarned - feeRefunded;
            emit MineHarvest(earned - feeEarned, feeEarned - feeRefunded, feeRefunded);
            return (earned - feeEarned, feeRefunded);
        } catch {
            // Failed because of reward debt calculation - should be 0
            return (0, 0);
        }
    }

    function _calculateHarvestRewardFee(uint256 earned)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 feeEarned = (earned * fee) / FEE_DENOMINATOR;
        uint256 accFeePerShare = (feeEarned * ONE) / totalShare;
        uint256 feeRefunded = (accFeePerShare * totalWhitelistedFeeShare) / ONE;
        return (earned - feeEarned, feeEarned, feeRefunded);
    }

    /**
     * @dev Harvest rewards from the mine so that stakers can claim.
     *      Recalculate how many rewards are distributed to each share.
     */
    function _updateRewards() internal {
        if (totalStaked == 0 || totalShare == 0) return;
        (uint256 newRewards, uint256 feeRefunded) = _harvestMine();
        accRewardsPerShare += (newRewards * ONE) / totalShare;
        if (totalWhitelistedFeeShare > 0) accRefundedFeePerShare += (feeRefunded * ONE) / totalWhitelistedFeeShare;
    }

    /**
     * @dev After mutating a stake (by withdrawing fully or partially),
     *      get updated data from the staking contract, and update the stake amounts
     *
     * @param stakeIndex           The index of the stake in the Stakes storage array.
     *
     * @return amount              The current, updated amount of the stake.
     */
    function _updateStakeDepositAmount(uint256 stakeIndex) internal returns (uint256) {
        Stake storage s = stakes[stakeIndex];

        (, uint256 depositAmount, , , , , ) = mine.userInfo(address(this), s.depositId);
        s.amount = depositAmount;

        return s.amount;
    }

    /**
     * @dev Find stakes with zero deposit amount and remove them from tracking.
     *      Uses recursion to stop from mutating an array we are currently looping over.
     *      If a zero stake is found, it is removed, and the function is restarted,
     *      such that it is always working from a 'clean' array.
     *
     */
    function _removeZeroStakes() internal {
        bool shouldRecurse = stakes.length > 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            _updateStakeDepositAmount(i);

            Stake storage s = stakes[i];

            if (s.amount == 0) {
                _removeStake(i);
                // Stop looping and start again - we will skip
                // out of the look and recurse
                break;
            }

            if (i == stakes.length - 1) {
                // We didn't remove anything, so stop recursing
                shouldRecurse = false;
            }
        }

        if (shouldRecurse) {
            _removeZeroStakes();
        }
    }

    /**
     * @dev Calculate total amount of MAGIC usable by the contract.
     *      'Usable' means available for either withdrawal or re-staking.
     *      Counts unstaked magic less fee reserve.
     *
     * @return amount               The amount of usable MAGIC.
     */
    function _totalUsableMagic() internal view returns (uint256) {
        // Current magic held in contract
        uint256 unstaked = magic.balanceOf(address(this));

        return unstaked - tokenBuffer - feeReserve;
    }

    /**
     * @dev Calculate total amount of MAGIC under control of the contract.
     *      Counts staked and unstaked MAGIC. Does _not_ count accumulated
     *      but unclaimed rewards.
     *
     * @return amount               The total amount of MAGIC under control of the contract.
     */
    function _totalControlledMagic() internal view returns (uint256) {
        // Current magic staked in mine
        uint256 staked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            staked += stakes[i].amount;
        }

        return staked + _totalUsableMagic();
    }

    /**
     * @dev Remove a tracked stake from any position in the stakes array.
     *      Used when a stake is no longer relevant i.e. fully withdrawn.
     *      Mutates the Stakes array in storage.
     *
     * @param index                 The index of the stake to remove.
     */
    function _removeStake(uint256 index) internal {
        if (index >= stakes.length) return;

        for (uint256 i = index; i < stakes.length - 1; i++) {
            stakes[i] = stakes[i + 1];
        }

        delete stakes[stakes.length - 1];

        stakes.pop();
    }

    modifier onlySuperAdminOrOwner() {
        require(msg.sender == owner() || superAdmins[msg.sender], "Not Super Admin");
        _;
    }
    modifier onlyBattleflyVaultOrOwner() {
        require(msg.sender == owner() || battleflyVaults[msg.sender], "Not BattleflyVault");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IBattleflyFounderVault.sol";
import "./interfaces/IBattleflyStaker.sol";
import "./interfaces/IBattleflyComic.sol";

contract BattleflyComic is
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155SupplyUpgradeable,
    IBattleflyComic
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public currentComicId;

    IBattleflyFounderVault public FounderVaultV1;
    IBattleflyFounderVault public FounderVaultV2;
    IBattleflyStaker public BattleflyStaker;
    IERC20Upgradeable public Magic;

    mapping(uint256 => Comic) public comicIdToComic;
    mapping(uint256 => mapping(uint256 => bool)) public usedTokens;
    mapping(uint256 => mapping(address => uint256)) public paidMints;
    mapping(address => bool) public admins;

    function initialize(
        address _magic,
        address _founderVaultV1,
        address _founderVaultV2,
        address _battleflyStake
    ) external initializer {
        __ERC1155_init("");
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC1155Supply_init();

        require(_magic != address(0), "BattleflyComic: invalid address");
        require(_founderVaultV1 != address(0), "BattleflyComic: invalid address");
        require(_founderVaultV2 != address(0), "BattleflyComic: invalid address");
        require(_battleflyStake != address(0), "BattleflyComic: invalid address");

        admins[msg.sender] = true;

        Magic = IERC20Upgradeable(_magic);
        FounderVaultV1 = IBattleflyFounderVault(_founderVaultV1);
        FounderVaultV2 = IBattleflyFounderVault(_founderVaultV2);
        BattleflyStaker = IBattleflyStaker(_battleflyStake);
    }

    // ---------------- Public methods ----------------- //

    /**
     * @dev Mint comic(s) with staked founders tokens.
     */
    function mintFounders(uint256[] memory tokenIds, uint256 id) public override nonReentrant {
        require(comicIdToComic[id].active, "BattleflyComic: This comic cannot be minted as it is currently paused");
        require(
            comicIdToComic[id].mintType == 1,
            "BattleflyComic: This comic cannot be minted by using founders tokens"
        );
        require(
            comicIdToComic[id].maxMints == 0 || totalSupply(id) + tokenIds.length <= comicIdToComic[id].maxMints,
            "BattleflyComic: Max amount of mints reached for this comic"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                FounderVaultV1.isOwner(msg.sender, tokenIds[i]) || FounderVaultV2.isOwner(msg.sender, tokenIds[i]),
                "BattleflyComic: Founders token not staked by minter"
            );
            require(!usedTokens[id][tokenIds[i]], "BattleflyComic: Founders token cannot be used twice for minting");
        }
        _mint(msg.sender, id, tokenIds.length, "");
        emit MintComicWithFounder(msg.sender, id, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            usedTokens[id][tokenIds[i]] = true;
        }
    }

    /**
     * @dev Mint comic(s) with staked battlefly tokens.
     */
    function mintBattlefly(uint256[] memory tokenIds, uint256 id) public override nonReentrant {
        require(comicIdToComic[id].active, "BattleflyComic: This comic cannot be minted as it is currently paused");
        require(
            comicIdToComic[id].mintType == 2,
            "BattleflyComic: This comic cannot be minted by using battlefly tokens"
        );
        require(
            comicIdToComic[id].maxMints == 0 || totalSupply(id) + tokenIds.length <= comicIdToComic[id].maxMints,
            "BattleflyComic: Max amount of mints reached for this comic"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                BattleflyStaker.ownerOf(tokenIds[i]) == msg.sender,
                "BattleflyComic: Battlefly token not staked by minter"
            );
            require(!usedTokens[id][tokenIds[i]], "BattleflyComic: Battlefly token cannot be used twice for minting");
        }
        _mint(msg.sender, id, tokenIds.length, "");
        emit MintComicWithBattlefly(msg.sender, id, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            usedTokens[id][tokenIds[i]] = true;
        }
    }

    /**
     * @dev Mint comic(s) by paying Magic.
     */
    function mintPaid(uint256 amount, uint256 id) public override nonReentrant {
        require(comicIdToComic[id].active, "BattleflyComic: This comic cannot be minted as it is currently paused");
        require(
            comicIdToComic[id].mintType == 1 || comicIdToComic[id].mintType == 2,
            "BattleflyComic: This comic cannot be minted as paid mint"
        );
        require(
            comicIdToComic[id].maxMints == 0 || totalSupply(id) + amount <= comicIdToComic[id].maxMints,
            "BattleflyComic: Max amount of mints reached for this comic"
        );
        require(
            comicIdToComic[id].maxPaidMintsPerWallet == 0 ||
                paidMints[id][msg.sender] + amount <= comicIdToComic[id].maxPaidMintsPerWallet,
            "BattleflyComic: Max mints per address for this comic reached"
        );
        require(
            Magic.balanceOf(msg.sender) >= (amount * comicIdToComic[id].priceInWei),
            "BattleflyComic: Not enough MAGIC in wallet"
        );
        Magic.transferFrom(msg.sender, address(this), amount * comicIdToComic[id].priceInWei);
        _mint(msg.sender, id, amount, "");
        emit MintComicWithPayment(msg.sender, id, amount);
        paidMints[id][msg.sender] = paidMints[id][msg.sender] + amount;
    }

    /**
     * @dev Mint comic(s) by burning other comics.
     */
    function burn(
        uint256 burnId,
        uint256 amount,
        uint256 mintId
    ) public override nonReentrant {
        require(comicIdToComic[mintId].active, "BattleflyComic: This comic cannot be minted as it is currently paused");
        require(comicIdToComic[mintId].mintType == 3, "BattleflyComic: This comic cannot be used for burning");
        require(comicIdToComic[burnId].burnableIn == mintId, "BattleflyComic: This comic cannot be used for burning");
        require(
            balanceOf(msg.sender, burnId) >= comicIdToComic[burnId].burnAmount * amount,
            "BattleflyComic: Not enough comics in wallet to burn"
        );
        safeTransferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            burnId,
            comicIdToComic[burnId].burnAmount * amount,
            ""
        );
        _mint(msg.sender, mintId, amount, "");
        emit MintComicByBurning(msg.sender, burnId, amount, mintId);
    }

    // ---------------- Admin methods ----------------- //

    /**
     * @dev Add a new comic cover
     */
    function addComic(Comic memory comic) public onlyAdmin {
        currentComicId++;
        Comic memory newComic = Comic(
            currentComicId,
            comic.active,
            comic.mintType,
            comic.priceInWei,
            comic.burnableIn,
            comic.burnAmount,
            comic.maxPaidMintsPerWallet,
            comic.maxMints,
            comic.name,
            comic.uri
        );
        comicIdToComic[currentComicId] = newComic;
        emit NewComicAdded(
            currentComicId,
            comic.active,
            comic.mintType,
            comic.priceInWei,
            comic.burnableIn,
            comic.burnAmount,
            comic.maxPaidMintsPerWallet,
            comic.maxMints,
            comic.name,
            comic.uri
        );
    }

    /**
     * @dev Mint comic(s) and send them to the treasury address.
     */
    function mintTreasury(
        uint256 amount,
        uint256 id,
        address treasury
    ) public onlyAdmin nonReentrant {
        require(comicIdToComic[id].active, "BattleflyComic: This comic cannot be minted as it is currently paused");
        require(comicIdToComic[id].mintType == 4, "BattleflyComic: This comic cannot be minted as treasury mint");
        require(
            comicIdToComic[id].maxMints == 0 || totalSupply(id) + amount <= comicIdToComic[id].maxMints,
            "BattleflyComic: Max amount of mints reached for this comic"
        );
        _mint(treasury, id, amount, "");
        emit MintComicWithTreasury(treasury, id, amount);
    }

    /**
     * @dev Withdraw Magic
     */
    function withdrawMagic(uint256 amount, address receiver) public onlyAdmin {
        Magic.transfer(receiver, amount);
    }

    /**
     * @dev Update a comic URI
     */
    function updateURI(uint256 _comicId, string memory _newUri) public override onlyAdmin {
        comicIdToComic[_comicId].uri = _newUri;
        emit UpdateComicURI(_comicId, _newUri);
    }

    /**
     * @dev Activate or deactivate the comic
     */
    function activateComic(uint256 _comicId, bool _activate) public onlyAdmin {
        comicIdToComic[_comicId].active = _activate;
        emit ComicActivated(_comicId, _activate);
    }

    /**
     * @dev Update comic.
     */
    function updateComic(uint256 _comicId, Comic memory _comic) public onlyAdmin {
        require(_comicId > 0 && _comicId <= currentComicId, "BattleflyComic: Invalid comic id");
        _comic.id = _comicId;
        comicIdToComic[_comicId] = _comic;
        emit ComicUpdated(
            _comicId,
            _comic.active,
            _comic.mintType,
            _comic.priceInWei,
            _comic.burnableIn,
            _comic.burnAmount,
            _comic.maxPaidMintsPerWallet,
            _comic.maxMints,
            _comic.name,
            _comic.uri
        );
    }

    /**
     * @dev Batch adding admin permission
     */
    function addAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    /**
     * @dev Batch removing admin permission
     */
    function removeAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = false;
        }
    }

    // ---------------- View methods ----------------- //

    /**
     * @dev et the URI of a comic.
     */
    function uri(uint256 _comicId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IBattleflyComic)
        returns (string memory)
    {
        return comicIdToComic[_comicId].uri;
    }

    // ---------------- Internal methods ----------------- //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "BattleflyComic: caller is not an admin");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyStaker {
    function stakingBattlefliesOfOwner(address user) external view returns (uint256[] memory);

    function bulkStakeBattlefly(uint256[] memory tokenIds) external;

    function bulkUnstakeBattlefly(
        uint256[] memory tokenIds,
        uint256[] memory battleflyStages,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

interface IBattleflyComic {
    struct Comic {
        uint256 id;
        bool active;
        // 1 = V1/V2 staked + buyable, 2 = battlefly staked + buyable, 3 = burn result, 4 only mintable by treasury
        uint256 mintType;
        uint256 priceInWei;
        uint256 burnableIn;
        uint256 burnAmount;
        uint256 maxPaidMintsPerWallet;
        uint256 maxMints;
        string name;
        string uri;
    }

    function uri(uint256 _comicId) external view returns (string memory);

    function updateURI(uint256 _comicId, string memory _newUri) external;

    function mintFounders(uint256[] memory tokenIds, uint256 id) external;

    function mintBattlefly(uint256[] memory tokenIds, uint256 id) external;

    function mintPaid(uint256 amount, uint256 id) external;

    function burn(
        uint256 burnId,
        uint256 amount,
        uint256 mintId
    ) external;

    event MintComicWithFounder(address indexed sender, uint256 indexed comicId, uint256[] usedFounderIds);
    event MintComicWithBattlefly(address indexed sender, uint256 indexed comicId, uint256[] usedBattleflyIds);
    event MintComicWithPayment(address indexed sender, uint256 indexed comicId, uint256 amount);
    event MintComicByBurning(
        address indexed sender,
        uint256 indexed comicToBeBurnt,
        uint256 amount,
        uint256 indexed comicId
    );
    event MintComicWithTreasury(address indexed treasury, uint256 indexed comicId, uint256 amount);
    event NewComicAdded(
        uint256 indexed comicId,
        bool active,
        uint256 mintType,
        uint256 priceInWei,
        uint256 burnableIn,
        uint256 burnAmount,
        uint256 maxPaidMintsPerWallet,
        uint256 maxMints,
        string name,
        string uri
    );
    event UpdateComicURI(uint256 indexed comicId, string newUri);
    event ComicActivated(uint256 indexed comicId, bool activated);
    event ComicUpdated(
        uint256 comicId,
        bool active,
        uint256 mintType,
        uint256 priceInWei,
        uint256 burnableIn,
        uint256 burnAmount,
        uint256 maxPaidMintsPerWallet,
        uint256 maxMints,
        string name,
        string uri
    );
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

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStaker.sol";

contract BattleflyAtlasStaker is
    IBattleflyAtlasStaker,
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
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /// @notice MAGIC token
    /// @dev functionally immutable
    IERC20Upgradeable public magic;
    /// @notice The IAtlasMine
    /// @dev functionally immutable
    IAtlasMine public mine;

    // ============= Global Staking State ==============
    uint256 public constant ONE = 1e30;

    /// @notice Whether new stakes will get staked on the contract as scheduled. For emergencies
    bool public schedulePaused;
    /// @notice The total amount of staked token
    uint256 public totalStaked;
    /// @notice The total amount of share
    uint256 public totalShare;
    /// @notice All stakes currently active
    Stake[] public stakes;
    /// @notice Deposit ID of last stake. Also tracked in atlas mine
    uint256 public lastDepositId;
    /// @notice Rewards accumulated per share
    uint256 public accRewardsPerShare;

    // ============= Vault Staking State ==============
    mapping(address => bool) public battleflyVaults;

    /// @notice Each vault stake, keyed by vault contract address => deposit ID
    mapping(address => mapping(uint256 => VaultStake)) public vaultStake;
    /// @notice All deposit IDs fro a vault, enumerated
    mapping(address => EnumerableSetUpgradeable.UintSet) private allVaultDepositIds;
    /// @notice The current ID of the vault's last deposited stake
    mapping(address => uint256) public currentId;

    // ============= NFT Boosting State ==============

    /// @notice Holder of treasures and legions
    mapping(uint256 => bool) public legionsStaked;
    mapping(uint256 => uint256) public treasuresStaked;

    // ============= Operator State ==============

    IAtlasMine.Lock[] public allowedLocks;
    /// @notice Fee to contract operator. Only assessed on rewards.
    uint256 public fee;
    /// @notice Amount of fees reserved for withdrawal by the operator.
    uint256 public feeReserve;
    /// @notice Max fee the owner can ever take - 10%
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(address => mapping(uint256 => int256)) refundedFeeDebts;
    uint256 accRefundedFeePerShare;
    uint256 totalWhitelistedFeeShare;
    EnumerableSetUpgradeable.AddressSet whitelistedFeeVaults;
    mapping(address => bool) public superAdmins;

    /// @notice deposited but unstaked
    uint256 public unstakedDeposits;
    mapping(IAtlasMine.Lock => uint256) public unstakedDepositsByLock;
    address public constant TREASURY_WALLET = 0xF5411006eEfD66c213d2fd2033a1d340458B7226;
    /// @notice Intra-tx buffer for pending payouts
    uint256 public tokenBuffer;

    // ===========================================
    // ============== Post Upgrade ===============
    // ===========================================

    // ========================================== INITIALIZER ===========================================

    /**
     * @param _magic                The MAGIC token address.
     * @param _mine                 The IAtlasMine contract.
     *                              Maps to a timelock for IAtlasMine deposits.
     */
    function initialize(
        IERC20Upgradeable _magic,
        IAtlasMine _mine,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        magic = _magic;
        mine = _mine;
        allowedLocks = _allowedLocks;
        fee = 1000;
        // Approve the mine
        magic.safeApprove(address(mine), 2**256 - 1);
        // approveNFTs();
    }

    // ======================================== VAULT OPERATIONS ========================================

    /**
     * @notice Make a new deposit into the Staker. The Staker will collect
     *         the tokens, to be later staked in atlas mine by the owner,
     *         according to the stake/unlock schedule.
     * @dev    Specified amount of token must be approved by the caller.
     *
     * @param _amount               The amount of tokens to deposit.
     */
    function deposit(uint256 _amount, IAtlasMine.Lock lock)
        public
        virtual
        override
        onlyBattleflyVaultOrOwner
        nonReentrant
        returns (uint256)
    {
        require(!schedulePaused, "new staking paused");
        _updateRewards();
        // Collect tokens
        uint256 newDepositId = _deposit(_amount, msg.sender, lock);
        magic.safeTransferFrom(msg.sender, address(this), _amount);
        return (newDepositId);
    }

    function _deposit(
        uint256 _amount,
        address _vault,
        IAtlasMine.Lock lock
    ) internal returns (uint256) {
        require(_amount > 0, "Deposit amount 0");
        bool validLock = false;
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == lock) {
                validLock = true;
                break;
            }
        }
        require(validLock, "Lock time not allowed");
        // Add vault stake
        uint256 newDepositId = ++currentId[_vault];
        allVaultDepositIds[_vault].add(newDepositId);
        VaultStake storage s = vaultStake[_vault][newDepositId];

        s.amount = _amount;
        (uint256 boost, uint256 lockTime) = getLockBoost(lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;

        uint256 vestingTime = mine.getVestingTime(lock);
        s.unlockAt = block.timestamp + lockTime + vestingTime + 1 days;
        s.rewardDebt = ((share * accRewardsPerShare) / ONE).toInt256();
        s.lock = lock;

        // Update global accounting
        totalStaked += _amount;
        totalShare += share;
        if (whitelistedFeeVaults.contains(_vault)) {
            totalWhitelistedFeeShare += share;
            refundedFeeDebts[_vault][newDepositId] = ((share * accRefundedFeePerShare) / ONE).toInt256();
        }
        // MAGIC tokens sit in contract. Added to pending stakes
        unstakedDeposits += _amount;
        unstakedDepositsByLock[lock] += _amount;
        emit VaultDeposit(_vault, newDepositId, _amount, s.unlockAt, s.lock);
        return newDepositId;
    }

    /**
     * @notice Withdraw a deposit from the Staker contract. Calculates
     *         pro rata share of accumulated MAGIC and distributes any
     *         earned rewards in addition to original deposit.
     *         There must be enough unlocked tokens to withdraw.
     *
     * @param depositId             The ID of the deposit to withdraw from.
     *
     */
    function withdraw(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        require(block.timestamp >= s.unlockAt, "Deposit locked");

        uint256 payout = _withdraw(s, depositId);
        magic.safeTransfer(msg.sender, payout);
    }

    /**
     * @notice Withdraw all eligible deposits from the staker contract.
     *         Will skip any deposits not yet unlocked. Will also
     *         distribute rewards for all stakes via 'withdraw'.
     *
     */
    function withdrawAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant {
        // Distribute tokens
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];

            if (s.amount > 0 && s.unlockAt > 0 && s.unlockAt <= block.timestamp) {
                tokenBuffer += _withdraw(s, depositIds[i]);
            }
        }
        magic.safeTransfer(msg.sender, tokenBuffer);
        tokenBuffer = 0;
    }

    /**
     * @dev Logic for withdrawing a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @dev An _amount argument larger than the total deposit amount will
     *      withdraw the entire deposit.
     *
     * @param s                     The VaultStake struct to withdraw from.
     * @param depositId             The ID of the deposit to withdraw from (for event).
     */
    function _withdraw(VaultStake storage s, uint256 depositId) internal returns (uint256 payout) {
        uint256 _amount = s.amount;

        // Unstake if we need to to ensure we can withdraw
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (_amount * (100e16 + boost)) / 100e16;
        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();
        if (whitelistedFeeVaults.contains(msg.sender)) {
            accumulatedRewards += ((share * accRefundedFeePerShare) / ONE).toInt256();
            accumulatedRewards -= refundedFeeDebts[msg.sender][depositId];
            totalWhitelistedFeeShare -= share;
            refundedFeeDebts[msg.sender][depositId] = 0;
        }
        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();
        payout = _amount + reward;

        // // Update vault accounting
        // s.amount -= _amount;
        // s.rewardDebt = 0;
        ///comment Archethect: Consider deleting the VaultStake object for gas optimization. s.unlockAt and s.lock can be zeroed as well.
        delete vaultStake[msg.sender][depositId];

        // Update global accounting
        totalStaked -= _amount;

        totalShare -= share;

        // If we need to unstake, unstake until we have enough
        if (payout > _totalUsableMagic()) {
            _unstakeToTarget(payout - _totalUsableMagic());
        }
        emit VaultWithdraw(msg.sender, depositId, _amount, reward);
    }

    /**
     * @notice Claim rewards without unstaking. Will fail if there
     *         are not enough tokens in the contract to claim rewards.
     *         Does not attempt to unstake.
     *
     * @param depositId             The ID of the deposit to claim rewards from.
     *
     */
    function claim(uint256 depositId) public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        VaultStake storage s = vaultStake[msg.sender][depositId];
        require(s.amount > 0, "No deposit");
        uint256 reward = _claim(s, depositId);
        magic.safeTransfer(msg.sender, reward);
        return reward;
    }

    /**
     * @notice Claim all possible rewards from the staker contract.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAll() public virtual override onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];
            uint256 reward = _claim(s, depositIds[i]);
            tokenBuffer += reward;
        }
        magic.safeTransfer(msg.sender, tokenBuffer);
        totalReward = tokenBuffer;
        tokenBuffer = 0;
        return totalReward;
    }

    /**
     * @notice Claim all possible rewards from the staker contract then restake.
     *         Will apply to both locked and unlocked deposits.
     *
     */
    function claimAllAndRestake(IAtlasMine.Lock lock) public onlyBattleflyVaultOrOwner nonReentrant returns (uint256) {
        _updateRewards();
        uint256[] memory depositIds = allVaultDepositIds[msg.sender].values();
        uint256 totalReward = 0;
        for (uint256 i = 0; i < depositIds.length; i++) {
            VaultStake storage s = vaultStake[msg.sender][depositIds[i]];
            uint256 reward = _claim(s, depositIds[i]);
            tokenBuffer += reward;
        }
        _deposit(tokenBuffer, msg.sender, lock);
        tokenBuffer = 0;
        return totalReward;
    }

    /**
     * @dev Logic for claiming rewards on a deposit. Calculates pro rata share of
     *      accumulated MAGIC and dsitributed any earned rewards in addition
     *      to original deposit.
     *
     * @param s                     The VaultStake struct to claim from.
     * @param depositId             The ID of the deposit to claim from (for event).
     */
    function _claim(VaultStake storage s, uint256 depositId) internal returns (uint256) {
        // Update accounting
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        int256 accumulatedRewards = ((share * accRewardsPerShare) / ONE).toInt256();

        uint256 reward = (accumulatedRewards - s.rewardDebt).toUint256();
        if (whitelistedFeeVaults.contains(msg.sender)) {
            int256 accumulatedRefundedFee = ((share * accRefundedFeePerShare) / ONE).toInt256();
            reward += accumulatedRefundedFee.toUint256();
            reward -= refundedFeeDebts[msg.sender][depositId].toUint256();
            refundedFeeDebts[msg.sender][depositId] = accumulatedRefundedFee;
        }
        s.rewardDebt = accumulatedRewards;

        // Unstake if we need to to ensure we can withdraw
        if (reward > _totalUsableMagic()) {
            _unstakeToTarget(reward - _totalUsableMagic());
        }

        require(reward <= _totalUsableMagic(), "Not enough rewards to claim");
        emit VaultClaim(msg.sender, depositId, reward);
        return reward;
    }

    // ======================================= SUPER ADMIN OPERATIONS ========================================

    /**
     * @notice Stake a Treasure owned by the superAdmin into the Atlas Mine.
     *         Staked treasures will boost all vault deposits.
     * @dev    Any treasure must be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdminOrOwner {
        address treasureAddr = mine.treasure();
        require(IERC1155Upgradeable(treasureAddr).balanceOf(msg.sender, _tokenId) >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] += _amount;
        // First withdraw and approve
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, bytes(""));
        mine.stakeTreasure(_tokenId, _amount);
        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Unstake a Treasure from the Atlas Mine adn transfer to receiver.
     *
     * @param _receiver              The receiver .
     * @param _tokenId              The tokenId of the specified treasure.
     * @param _amount               The amount of treasures to stake.
     */
    function unstakeTreasure(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlySuperAdminOrOwner {
        require(treasuresStaked[_tokenId] >= _amount, "Not enough treasures");
        treasuresStaked[_tokenId] -= _amount;
        address treasureAddr = mine.treasure();
        mine.unstakeTreasure(_tokenId, _amount);
        IERC1155Upgradeable(treasureAddr).safeTransferFrom(address(this), _receiver, _tokenId, _amount, bytes(""));
        uint256 boost = mine.boosts(address(this));
        emit UnstakeNFT(_receiver, treasureAddr, _tokenId, _amount, boost);
    }

    /**
     * @notice Stake a Legion owned by the superAdmin into the Atlas Mine.
     *         Staked legions will boost all vault deposits.
     * @dev    Any legion be approved for withdrawal by the caller.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function stakeLegion(uint256 _tokenId) external onlySuperAdminOrOwner {
        address legionAddr = mine.legion();
        require(IERC721Upgradeable(legionAddr).ownerOf(_tokenId) == msg.sender, "Not owner of legion");
        legionsStaked[_tokenId] = true;
        IERC721Upgradeable(legionAddr).safeTransferFrom(msg.sender, address(this), _tokenId);

        mine.stakeLegion(_tokenId);

        uint256 boost = mine.boosts(address(this));

        emit StakeNFT(msg.sender, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Unstake a Legion from the Atlas Mine and return it to the superAdmin.
     *
     * @param _tokenId              The tokenId of the specified legion.
     */
    function unstakeLegion(address _receiver, uint256 _tokenId) external onlySuperAdminOrOwner {
        require(legionsStaked[_tokenId], "No legion");
        address legionAddr = mine.legion();
        delete legionsStaked[_tokenId];
        mine.unstakeLegion(_tokenId);

        // Distribute to superAdmin
        IERC721Upgradeable(legionAddr).safeTransferFrom(address(this), _receiver, _tokenId);
        uint256 boost = mine.boosts(address(this));

        emit UnstakeNFT(_receiver, legionAddr, _tokenId, 1, boost);
    }

    /**
     * @notice Stake any pending stakes before the current day. Callable
     *         by anybody. Any pending stakes will unlock according
     *         to the time this method is called, and the contract's defined
     *         lock time.
     */
    function stakeScheduled() external virtual override onlySuperAdminOrOwner {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            IAtlasMine.Lock lock = allowedLocks[i];
            _stakeInMine(unstakedDepositsByLock[lock], lock);
            unstakedDepositsByLock[lock] = 0;
        }
        unstakedDeposits = 0;
    }

    /**
     * @notice Unstake everything eligible for unstaking from Atlas Mine.
     *         Callable by owner. Should only be used in case of emergency
     *         or migration to a new contract, or if there is a need to service
     *         an unexpectedly large amount of withdrawals.
     *
     *         If unlockAll is set to true in the Atlas Mine, this can withdraw
     *         all stake.
     */
    function unstakeAllFromMine() external override onlySuperAdminOrOwner {
        // Unstake everything eligible
        _updateRewards();

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp) {
                continue;
            }

            // Withdraw position - auto-harvest
            mine.withdrawPosition(s.depositId, s.amount);
        }

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @notice Let owner unstake a specified amount as needed to make sure the contract is funded.
     *         Can be used to facilitate expected future withdrawals.
     *
     * @param target                The amount of tokens to reclaim from the mine.
     */
    function unstakeToTarget(uint256 target) external override onlySuperAdminOrOwner {
        _updateRewards();
        _unstakeToTarget(target);
    }

    /**
     * @notice Withdraw any accumulated reward fees to the treasury
     */
    function withdrawFeesToTreasury() external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        magic.safeTransfer(TREASURY_WALLET, amount);
        emit WithdrawFeesToTreasury(amount);
    }

    function stakeBackFeeTreasury(IAtlasMine.Lock lock) external virtual onlySuperAdminOrOwner {
        uint256 amount = feeReserve;
        feeReserve = 0;
        emit WithdrawFeesToTreasury(amount);
        // magic.safeTransfer(TREASURY_WALLET, amount);
        _deposit(amount, TREASURY_WALLET, lock);
    }

    /**
     * @notice Whitelist vault from fees.
     *
     * @param _vault                Vault address.
     * @param isSet                 Whether to enable or disable the vault whitelist.
     */
    function setFeeWhitelistVault(address _vault, bool isSet) external onlyOwner {
        require(_vault != address(0), "Invalid Vault");
        if (isSet) {
            whitelistedFeeVaults.add(_vault);
            totalWhitelistedFeeShare += totalShareOf(_vault);
        } else {
            whitelistedFeeVaults.remove(_vault);
            totalWhitelistedFeeShare -= totalShareOf(_vault);
        }
        emit SetFeeWhitelistVault(_vault, isSet);
    }

    // ======================================= OWNER OPERATIONS =======================================

    function setBattleflyVault(address _vaultAddress, bool isSet) external onlyOwner {
        require(_vaultAddress != address(0), "Invalid vault");
        if (isSet) {
            require(battleflyVaults[_vaultAddress] == false, "Vault already set");
            battleflyVaults[_vaultAddress] = isSet;
        } else {
            require(allVaultDepositIds[_vaultAddress].length() == 0, "Vault is still active");
            delete battleflyVaults[_vaultAddress];
        }
        emit SetBattleflyVault(_vaultAddress, isSet);
    }

    /**
     * @notice Change the designated superAdmin, the address where treasures and
     *         legions are held. Staked NFTs can only be
     *         withdrawn to the current superAdmin address, regardless of which
     *         address the superAdmin was set to when it was staked.
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the superAdmin address.
     */
    function setBoostAdmin(address _superAdmin, bool isSet) external override onlyOwner {
        require(_superAdmin != address(0), "Invalid superAdmin");

        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Change the designated super admin, who manage the fee reverse
     *
     * @param _superAdmin                The new superAdmin address.
     * @param isSet                 Whether to enable or disable the super admin address.
     */
    function setSuperAdmin(address _superAdmin, bool isSet) external onlyOwner {
        require(_superAdmin != address(0), "Invalid address");
        superAdmins[_superAdmin] = isSet;
    }

    /**
     * @notice Approve treasures and legions for withdrawal from the atlas mine.
     *         Called on startup, and should be called again in case contract
     *         addresses for treasures and legions ever change.
     *
     */
    function approveNFTs() public override onlyOwner {
        address treasureAddr = mine.treasure();
        IERC1155Upgradeable(treasureAddr).setApprovalForAll(address(mine), true);

        address legionAddr = mine.legion();
        IERC1155Upgradeable(legionAddr).setApprovalForAll(address(mine), true);
    }

    /**
     * @notice EMERGENCY ONLY - toggle pausing new scheduled stakes.
     *         If on, vaults can deposit, but stakes won't go to Atlas Mine.
     *         Can be used in case of Atlas Mine issues or forced migration
     *         to new contract.
     */
    function toggleSchedulePause(bool paused) external virtual override onlyOwner {
        schedulePaused = paused;

        emit StakingPauseToggle(paused);
    }

    // ======================================== VIEW FUNCTIONS =========================================
    function getLockBoost(IAtlasMine.Lock _lock) public pure virtual returns (uint256 boost, uint256 timelock) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            // 10%
            return (10e16, 14 days);
        } else if (_lock == IAtlasMine.Lock.oneMonth) {
            // 25%
            return (25e16, 30 days);
        } else if (_lock == IAtlasMine.Lock.threeMonths) {
            // 80%
            return (80e16, 13 weeks);
        } else if (_lock == IAtlasMine.Lock.sixMonths) {
            // 180%
            return (180e16, 26 weeks);
        } else if (_lock == IAtlasMine.Lock.twelveMonths) {
            // 400%
            return (400e16, 365 days);
        } else {
            revert("Invalid lock value");
        }
    }

    /**
     * @notice Returns all magic either unstaked, staked, or pending rewards in Atlas Mine.
     *         Best proxy for TVL.
     *
     * @return total               The total amount of MAGIC in the staker.
     */
    function totalMagic() external view override returns (uint256) {
        return _totalControlledMagic() + mine.pendingRewardsAll(address(this));
    }

    /**
     * @notice Returns all magic that has been deposited, but not staked, and is eligible
     *         to be staked (deposit time < current day).
     *
     * @return total               The total amount of MAGIC that can be withdrawn.
     */
    function totalWithdrawableMagic() external view override returns (uint256) {
        uint256 totalPendingRewards;

        // IAtlasMine attempts to divide by 0 if there are no deposits
        try mine.pendingRewardsAll(address(this)) returns (uint256 _pending) {
            totalPendingRewards = _pending;
        } catch Panic(uint256) {
            totalPendingRewards = 0;
        }

        return _totalUsableMagic() + totalPendingRewards;
    }

    /**
     * @notice Returns the details of a vault stake.
     *
     * @return vaultStake           The details of a vault stake.
     */
    function getVaultStake(address vault, uint256 depositId) external view override returns (VaultStake memory) {
        return vaultStake[vault][depositId];
    }

    /**
     * @notice Returns the pending, claimable rewards for a deposit.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     * @param depositId         The specific deposit to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewards(address vault, uint256 depositId) public view override returns (uint256 reward) {
        if (totalShare == 0) {
            return 0;
        }
        VaultStake storage s = vaultStake[vault][depositId];
        (uint256 boost, ) = getLockBoost(s.lock);
        uint256 share = (s.amount * (100e16 + boost)) / 100e16;

        uint256 unupdatedReward = mine.pendingRewardsAll(address(this));
        (uint256 founderReward, , uint256 feeRefund) = _calculateHarvestRewardFee(unupdatedReward);
        uint256 realAccRewardsPerShare = accRewardsPerShare + (founderReward * ONE) / totalShare;
        uint256 accumulatedRewards = (share * realAccRewardsPerShare) / ONE;
        if (whitelistedFeeVaults.contains(vault) && totalWhitelistedFeeShare > 0) {
            uint256 realAccRefundedFeePerShare = accRefundedFeePerShare + (feeRefund * ONE) / totalWhitelistedFeeShare;
            uint256 accumulatedRefundedFee = (share * realAccRefundedFeePerShare) / ONE;
            accumulatedRewards = accumulatedRewards + accumulatedRefundedFee;
            accumulatedRewards -= refundedFeeDebts[vault][depositId].toUint256();
        }
        reward = accumulatedRewards - s.rewardDebt.toUint256();
    }

    /**
     * @notice Returns the pending, claimable rewards for all of a vault's deposits.
     * @dev    This does not update rewards, so out of date if rewards not recently updated.
     *         Needed to maintain 'view' function type.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return reward           The total amount of MAGIC reward pending.
     */
    function pendingRewardsAll(address vault) external view override returns (uint256 reward) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();

        for (uint256 i = 0; i < depositIds.length; i++) {
            reward += pendingRewards(vault, depositIds[i]);
        }
    }

    /**
     * @notice Returns the total Share of a vault.
     *
     * @param vault              The vault to check rewards for.
     *
     * @return _totalShare           The total share of a vault.
     */
    function totalShareOf(address vault) public view returns (uint256 _totalShare) {
        uint256[] memory depositIds = allVaultDepositIds[vault].values();
        for (uint256 i = 0; i < depositIds.length; i++) {
            (uint256 boost, ) = getLockBoost(vaultStake[vault][depositIds[i]].lock);
            uint256 share = (vaultStake[vault][depositIds[i]].amount * (100e16 + boost)) / 100e16;
            _totalShare += share;
        }
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Stake tokens held by staker in the Atlas Mine, according to
     *      the predefined lock value. Schedules for staking will be managed by a queue.
     *
     * @param _amount               Number of tokens to stake
     */
    function _stakeInMine(uint256 _amount, IAtlasMine.Lock lock) internal {
        require(_amount <= _totalUsableMagic(), "Not enough funds");

        uint256 depositId = ++lastDepositId;
        (, uint256 lockTime) = getLockBoost(lock);
        uint256 vestingPeriod = mine.getVestingTime(lock);
        uint256 unlockAt = block.timestamp + lockTime + vestingPeriod;

        stakes.push(Stake({ amount: _amount, unlockAt: unlockAt, depositId: depositId }));

        mine.deposit(_amount, lock);
    }

    /**
     * @dev Unstakes until we have enough unstaked tokens to meet a specific target.
     *      Used to make sure we can service withdrawals.
     *
     * @param target                The amount of tokens we want to have unstaked.
     */
    function _unstakeToTarget(uint256 target) internal {
        uint256 unstaked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake memory s = stakes[i];

            if (s.unlockAt > block.timestamp && !mine.unlockAll()) {
                // This stake is not unlocked - stop looking
                continue;
            }

            // Withdraw position - auto-harvest
            uint256 preclaimBalance = _totalUsableMagic();
            uint256 targetLeft = target - unstaked;
            uint256 amount = targetLeft > s.amount ? s.amount : targetLeft;

            // Do not harvest rewards - if this is running, we've already
            // harvested in the same fn call
            mine.withdrawPosition(s.depositId, amount);
            uint256 postclaimBalance = _totalUsableMagic();

            // Increment amount unstaked
            unstaked += postclaimBalance - preclaimBalance;

            if (unstaked >= target) {
                // We unstaked enough
                break;
            }
        }

        require(unstaked >= target, "Cannot unstake enough");
        require(_totalUsableMagic() >= target, "Not enough in contract after unstaking");

        // Only check for removal after, so we don't mutate while looping
        _removeZeroStakes();
    }

    /**
     * @dev Harvest rewards from the IAtlasMine and send them back to
     *      this contract.
     *
     * @return earned               The amount of rewards earned for depositors, minus the fee.
     * @return feeEearned           The amount of fees earned for the contract operator.
     */
    function _harvestMine() internal returns (uint256, uint256) {
        uint256 preclaimBalance = magic.balanceOf(address(this));

        try mine.harvestAll() {
            uint256 postclaimBalance = magic.balanceOf(address(this));

            uint256 earned = postclaimBalance - preclaimBalance;
            // Reserve the 'fee' amount of what is earned
            (, uint256 feeEarned, uint256 feeRefunded) = _calculateHarvestRewardFee(earned);
            feeReserve += feeEarned - feeRefunded;
            emit MineHarvest(earned - feeEarned, feeEarned - feeRefunded, feeRefunded);
            return (earned - feeEarned, feeRefunded);
        } catch {
            // Failed because of reward debt calculation - should be 0
            return (0, 0);
        }
    }

    function _calculateHarvestRewardFee(uint256 earned)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 feeEarned = (earned * fee) / FEE_DENOMINATOR;
        uint256 accFeePerShare = (feeEarned * ONE) / totalShare;
        uint256 feeRefunded = (accFeePerShare * totalWhitelistedFeeShare) / ONE;
        return (earned - feeEarned, feeEarned, feeRefunded);
    }

    /**
     * @dev Harvest rewards from the mine so that stakers can claim.
     *      Recalculate how many rewards are distributed to each share.
     */
    function _updateRewards() internal {
        if (totalStaked == 0 || totalShare == 0) return;
        (uint256 newRewards, uint256 feeRefunded) = _harvestMine();
        accRewardsPerShare += (newRewards * ONE) / totalShare;
        if (totalWhitelistedFeeShare > 0) accRefundedFeePerShare += (feeRefunded * ONE) / totalWhitelistedFeeShare;
    }

    /**
     * @dev After mutating a stake (by withdrawing fully or partially),
     *      get updated data from the staking contract, and update the stake amounts
     *
     * @param stakeIndex           The index of the stake in the Stakes storage array.
     *
     * @return amount              The current, updated amount of the stake.
     */
    function _updateStakeDepositAmount(uint256 stakeIndex) internal returns (uint256) {
        Stake storage s = stakes[stakeIndex];

        (, uint256 depositAmount, , , , , ) = mine.userInfo(address(this), s.depositId);
        s.amount = depositAmount;

        return s.amount;
    }

    /**
     * @dev Find stakes with zero deposit amount and remove them from tracking.
     *      Uses recursion to stop from mutating an array we are currently looping over.
     *      If a zero stake is found, it is removed, and the function is restarted,
     *      such that it is always working from a 'clean' array.
     *
     */
    function _removeZeroStakes() internal {
        bool shouldRecurse = stakes.length > 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            _updateStakeDepositAmount(i);

            Stake storage s = stakes[i];

            if (s.amount == 0) {
                _removeStake(i);
                // Stop looping and start again - we will skip
                // out of the look and recurse
                break;
            }

            if (i == stakes.length - 1) {
                // We didn't remove anything, so stop recursing
                shouldRecurse = false;
            }
        }

        if (shouldRecurse) {
            _removeZeroStakes();
        }
    }

    /**
     * @dev Calculate total amount of MAGIC usable by the contract.
     *      'Usable' means available for either withdrawal or re-staking.
     *      Counts unstaked magic less fee reserve.
     *
     * @return amount               The amount of usable MAGIC.
     */
    function _totalUsableMagic() internal view returns (uint256) {
        // Current magic held in contract
        uint256 unstaked = magic.balanceOf(address(this));

        return unstaked - tokenBuffer - feeReserve;
    }

    /**
     * @dev Calculate total amount of MAGIC under control of the contract.
     *      Counts staked and unstaked MAGIC. Does _not_ count accumulated
     *      but unclaimed rewards.
     *
     * @return amount               The total amount of MAGIC under control of the contract.
     */
    function _totalControlledMagic() internal view returns (uint256) {
        // Current magic staked in mine
        uint256 staked = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            staked += stakes[i].amount;
        }

        return staked + _totalUsableMagic();
    }

    /**
     * @dev Remove a tracked stake from any position in the stakes array.
     *      Used when a stake is no longer relevant i.e. fully withdrawn.
     *      Mutates the Stakes array in storage.
     *
     * @param index                 The index of the stake to remove.
     */
    function _removeStake(uint256 index) internal {
        if (index >= stakes.length) return;

        for (uint256 i = index; i < stakes.length - 1; i++) {
            stakes[i] = stakes[i + 1];
        }

        delete stakes[stakes.length - 1];

        stakes.pop();
    }

    modifier onlySuperAdminOrOwner() {
        require(msg.sender == owner() || superAdmins[msg.sender], "Not Super Admin");
        _;
    }
    modifier onlyBattleflyVaultOrOwner() {
        require(msg.sender == owner() || battleflyVaults[msg.sender], "Not BattleflyVault");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MagicTokenContract is ERC20, Ownable {
    mapping(address => bool) private adminAccess;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
    }

    function mint(uint256 amount, address receiver) external onlyAdminAccess {
        _mint(receiver, amount);
    }

    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ERC721BulkTransfer is Context {
    mapping(address => bool) private adminAccess;

    constructor() {}

    function bulkTransferERC721(
        uint256[] memory tokenIds,
        address[] memory receivers,
        address tokenAddress
    ) external {
        IERC721 token = IERC721(tokenAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.transferFrom(_msgSender(), receivers[i], tokenIds[i]);
        }
    }

    function transferWithAmount(
        address receiver,
        uint256 amount,
        address tokenAddress
    ) external {
        IERC721Enumerable token = IERC721Enumerable(tokenAddress);
        uint256 balance = token.balanceOf(_msgSender());
        require(amount <= balance, "Not enough balance");
        for (uint256 i = 0; i < amount; i++) {
            token.transferFrom(_msgSender(), receiver, token.tokenOfOwnerByIndex(_msgSender(), 0));
        }
    }

    function bulkTransferWithAmount(
        address[] memory receivers,
        uint256[] memory amounts,
        address tokenAddress
    ) external {
        IERC721Enumerable token = IERC721Enumerable(tokenAddress);
        require(receivers.length == amounts.length, "Wrong input");
        for (uint256 i = 0; i < receivers.length; i++) {
            for (uint256 j = 0; j < amounts[i]; j++) {
                token.transferFrom(_msgSender(), receivers[i], token.tokenOfOwnerByIndex(_msgSender(), 0));
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{ value: msg.value }(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITestERC1155 is IERC1155 {
    function mint(
        uint256 amount,
        uint256 id,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/ITestERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155, ITestERC1155 {
    constructor() ERC1155("TestToken ERC1155") {}

    function mint(
        uint256 amount,
        uint256 id,
        address receiver
    ) public override {
        _mint(receiver, id, amount, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721Enumerable {
    uint256 public tokenId;

    constructor() ERC721("TestToken ERC721", "TTERC721") {
        tokenId = 1;
    }

    function mint(address receiver) public {
        _safeMint(receiver, tokenId);
        tokenId++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ITestERC721 is IERC721Enumerable {
    function mint(address receiver) external;
}