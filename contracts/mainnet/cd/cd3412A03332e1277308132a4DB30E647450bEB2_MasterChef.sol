pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import './FarmerLandNFT.sol';

// MasterChef is the master of Plush. He can make Plush and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PLUSH is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // max NFTs a single user can stake in a pool. This is to ensure finite gas usage on emergencyWithdraw.
    uint public MAX_NFT_COUNT = 150;

    // Stores which nft series are currently allowed.
    EnumerableSet.AddressSet internal nftAddressAllowListSet;
    // Stores which nft series has ever been allowed, even if once removed.
    EnumerableSet.AddressSet internal nftAddressAllowListSetHistoric;

    // How much weighting an NFT has in the pool, before their ability boost is added.
    mapping(address => uint) internal baseWeightingMap;

    // Mapping of user address to total nfts staked.
    mapping(address => uint) public userStakeCounts;

    function hasUserStakedNFT(address _user, address _series, uint _tokenId) external view returns (bool) {
        return userStakedMap[_user][_series][_tokenId];
    }

    // Mapping of NFT contract address to which NFTs a user has staked.
    mapping(address => mapping(address => mapping(uint => bool))) public userStakedMap;
    // Mapping of NFT contract address to NFTs ability at the time a user has staked for the user.
    mapping(address => mapping(address => mapping(uint => uint))) public userAbilityOnStakeMap;
    // Mapping of NFT contract address to array of NFT IDs a user has staked.
    mapping(address => mapping(address => EnumerableSet.UintSet)) private userNftIdsMapArray;


    IERC20 public constant usdcCurrency = IERC20(0x2C6874f2600310CB35853e2D35a3C2150FB1e8d0);
    IERC20 public immutable wheatCurrency;

    uint public totalUSDCCollected = 0;
    uint public totalWHEATCollected = 0;

    uint public accDepositUSDCRewardPerShare = 0;
    uint public accDepositWHEATRewardPerShare = 0;


    uint public promisedUSDC = 0;
    uint public promisedWHEAT = 0;

    // default to 12 hours
    uint public usdcDistributionTimeFrameSeconds = 12 hours;
    uint public wheatDistributionTimeFrameSeconds = 12 hours;

    // Info of each user.
    struct UserInfo {
        uint amount;         // How many LP tokens the user has provided.
        uint usdcRewardDebt;     // Reward debt
        uint wheatRewardDebt;     // Reward debt
    }

    // Info of each pool.
    struct PoolInfo {
        uint lastRewardTimestamp;  // Last block timestamp that USDC and WHEAT distribution occurs.
        uint totalLocked;      // total units locked in the pool
    }

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // The block timestamp when emmissions start.
    uint public startTimestamp;

    event Deposit(address indexed user, bool isHarvest, address series, uint tokenId);
    event Withdraw(address indexed user, address series, uint tokenId);
    event EmergencyWithdraw(address indexed user,uint amount);
    event USDCTransferredToUser(address recipient, uint usdcAmount);
    event WHEATTransferredToUser(address recipient, uint usdcAmount);
    event SetUSDCDistributionTimeFrame(uint distributionTimeFrameSeconds);
    event SetWHEATDistributionTimeFrame(uint distributionTimeFrameSeconds);
    event NftAddressAllowListSet(address series, bool allowed);
    event NFTStakeAbilityRefreshed(address _user, address _series, uint _tokenId);

    constructor(
        uint _startTimestamp,
        address _wheatAddress
    ) public {
        poolInfo.lastRewardTimestamp = _startTimestamp;
        wheatCurrency = IERC20(_wheatAddress);
    }

    // View function to see pending USDCs on frontend.
    function pendingUSDC(address _user) external view returns (uint) {
        UserInfo storage user = userInfo[_user];

        return ((user.amount * accDepositUSDCRewardPerShare) / (1e24)) - user.usdcRewardDebt;
    }

    // View function to see pending USDCs on frontend.
    function pendingWHEAT(address _user) external view returns (uint) {
        UserInfo storage user = userInfo[_user];

        return ((user.amount * accDepositWHEATRewardPerShare) / (1e24)) - user.wheatRewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.timestamp <= pool.lastRewardTimestamp)
            return;

        if (pool.totalLocked > 0) {
            uint usdcRelease = getUSDCDrip();

            if (usdcRelease > 0) {
                accDepositUSDCRewardPerShare = accDepositUSDCRewardPerShare + ((usdcRelease * 1e24) / pool.totalLocked);
                totalUSDCCollected = totalUSDCCollected + usdcRelease;
            }

            uint wheatRelease = getWHEATDrip();

            if (wheatRelease > 0) {
                accDepositWHEATRewardPerShare = accDepositWHEATRewardPerShare + ((wheatRelease * 1e24) / pool.totalLocked);
                totalWHEATCollected = totalWHEATCollected + wheatRelease;
            }
        }

        pool.lastRewardTimestamp = block.timestamp;
    }

    function updateAbilityForDeposit(address _userAddress, address _series, uint _tokenId) external nonReentrant {
        require(isNftSeriesAllowed(_series), "nftNotAllowed to be staked!");
        require(userStakedMap[_userAddress][_series][_tokenId], "nft not staked by specified user");

        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_userAddress];

        updatePool();

        payPendingUSDCWHEATRewards(_userAddress);

        uint oldAbility = userAbilityOnStakeMap[_userAddress][_series][_tokenId];

        user.amount = user.amount - oldAbility;
        pool.totalLocked = pool.totalLocked - oldAbility;

        uint newAbility = FarmerLandNFT(_series).getAbility(_tokenId);

        userAbilityOnStakeMap[_userAddress][_series][_tokenId] = newAbility;

        user.amount = user.amount + newAbility;
        pool.totalLocked = pool.totalLocked + newAbility;

        user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);
        user.wheatRewardDebt = ((user.amount * accDepositWHEATRewardPerShare) / 1e24);

        emit NFTStakeAbilityRefreshed(_userAddress, _series, _tokenId);
    }

    // Deposit NFTs to MasterChef
    function deposit(address _series, uint _tokenId, bool isHarvest) public nonReentrant {
        require(isNftSeriesAllowed(_series), "nftNotAllowed to be staked!");
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        payPendingUSDCWHEATRewards(msg.sender);

        if (!isHarvest) {
            userStakeCounts[msg.sender]++;
            require(userStakeCounts[msg.sender] <= MAX_NFT_COUNT,
                "you have aleady reached the maximum amount of NFTs you can stake in this pool");
            IERC721(_series).safeTransferFrom(msg.sender, address(this), _tokenId);

            userStakedMap[msg.sender][_series][_tokenId] = true;

            userNftIdsMapArray[msg.sender][_series].add(_tokenId);

            uint ability = FarmerLandNFT(_series).getAbility(_tokenId);

            userAbilityOnStakeMap[msg.sender][_series][_tokenId] = ability;

            user.amount = user.amount + baseWeightingMap[_series] + ability;
            pool.totalLocked = pool.totalLocked + baseWeightingMap[_series] + ability;
        }

        user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);
        user.wheatRewardDebt = ((user.amount * accDepositWHEATRewardPerShare) / 1e24);

        emit Deposit(msg.sender, isHarvest, _series, _tokenId);
    }

    // Withdraw NFT from MasterChef.
    function withdraw(address _series, uint _tokenId) external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        payPendingUSDCWHEATRewards(msg.sender);

        uint withdrawQuantity = 0;

        require(userStakedMap[msg.sender][_series][_tokenId], "nft not staked");

        userStakeCounts[msg.sender]--;

        userStakedMap[msg.sender][_series][_tokenId] = false;

        userNftIdsMapArray[msg.sender][_series].remove(_tokenId);

        withdrawQuantity = userAbilityOnStakeMap[msg.sender][_series][_tokenId];

        user.amount = user.amount - baseWeightingMap[_series] - withdrawQuantity;
        pool.totalLocked = pool.totalLocked - baseWeightingMap[_series] - withdrawQuantity;

        userAbilityOnStakeMap[msg.sender][_series][_tokenId] = 0;

        user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);
        user.wheatRewardDebt = ((user.amount * accDepositWHEATRewardPerShare) / 1e24);

        IERC721(_series).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Withdraw(msg.sender, _series, _tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        uint amount = user.amount;

        for (uint i = 0;i<nftAddressAllowListSetHistoric.length();i++) {
            address series = nftAddressAllowListSetHistoric.at(i);
            EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[msg.sender][series];

            for (uint j = 0;j < nftStakedCollection.length();j++) {
                uint nftId = nftStakedCollection.at(j);

                userAbilityOnStakeMap[msg.sender][series][nftId] = 0;

                userStakedMap[msg.sender][series][nftId] = false;

                IERC721(series).safeTransferFrom(address(this), msg.sender, nftId);
            }

            // empty user nft Ids array
            delete userNftIdsMapArray[msg.sender][series];
        }

        user.amount = 0;
        user.usdcRewardDebt = 0;
        user.wheatRewardDebt = 0;

        userStakeCounts[msg.sender] = 0;

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >=  amount)
            pool.totalLocked = pool.totalLocked - amount;
        else
            pool.totalLocked = 0;

        emit EmergencyWithdraw(msg.sender, amount);
    }

    function viewStakerUserNFTs(address _series, address userAddress) public view returns (uint[] memory){
        EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[userAddress][_series];

        uint[] memory nftStakedArray = new uint[](nftStakedCollection.length());

        for (uint i = 0;i < nftStakedCollection.length();i++)
           nftStakedArray[i] = nftStakedCollection.at(i);

        return nftStakedArray;
    }

    // Pay pending USDC and WHEAT.
    function payPendingUSDCWHEATRewards(address _user) internal {
        UserInfo storage user = userInfo[_user];

        uint usdcPending = ((user.amount * accDepositUSDCRewardPerShare) / 1e24) - user.usdcRewardDebt;

        if (usdcPending > 0) {
            // send rewards
            transferUSDCToUser(_user, usdcPending);
        }

        uint wheatPending = ((user.amount * accDepositWHEATRewardPerShare) / 1e24) - user.wheatRewardDebt;

        if (wheatPending > 0) {
            // send rewards
            transferWHEATToUser(_user, wheatPending);
        }
    }

    function isNftSeriesAllowed(address _series) public view returns (bool){
        return nftAddressAllowListSet.contains(_series);
    }

    /**
     * @dev set which Nfts are allowed to be staked
     * Can only be called by the current operator.
     */
    function setNftAddressAllowList(address _series, bool allowed, uint baseWeighting) external onlyOwner {
        require(_series != address(0), "_series cant be 0 address");

        bool wasOnceAdded = nftAddressAllowListSetHistoric.contains(_series);
        require(wasOnceAdded || baseWeighting > 0 && baseWeighting <= 200e4, "baseWeighting out of range!");

        if (!wasOnceAdded) {
            baseWeightingMap[_series] = baseWeighting;

            if (allowed)
                nftAddressAllowListSetHistoric.add(_series);
        }

        bool alreadyIsAdded = nftAddressAllowListSet.contains(_series);

        if (allowed) {
            if (!alreadyIsAdded) {
                nftAddressAllowListSet.add(_series);
            }
        } else {
            if (alreadyIsAdded) {
                nftAddressAllowListSet.remove(_series);
            }
        }

        emit NftAddressAllowListSet(_series, allowed);
    }

    /**
     * @dev set the maximum amount of NFTs a user is allowed to stake, useful if
     * too much gas is used by emergencyWithdraw
     * Can only be called by the current operator.
     */
    function set_MAX_NFT_COUNT(uint new_MAX_NFT_COUNT) external onlyOwner {
        require(new_MAX_NFT_COUNT >= 20, "MAX_NFT_COUNT must be greater than 0");
        require(new_MAX_NFT_COUNT <= 150, "MAX_NFT_COUNT must be less than 150");

        MAX_NFT_COUNT = new_MAX_NFT_COUNT;
    }

    /**
     * Get the rate of USDC the masterchef is emitting
     */
    function getUSDCDripRate() external view returns (uint) {
        uint usdcBalance = usdcCurrency.balanceOf(address(this));
        if (promisedUSDC > usdcBalance)
            return 0;
        else
            return (usdcBalance - promisedUSDC) / usdcDistributionTimeFrameSeconds;
    }

    /**
     * Get the rate of WHEAT the masterchef is emitting
     */
    function getWHEATDripRate() external view returns (uint) {
        uint wheatBalance = wheatCurrency.balanceOf(address(this));
        if (promisedWHEAT > wheatBalance)
            return 0;
        else
            return (wheatBalance - promisedWHEAT) / wheatDistributionTimeFrameSeconds;
    }

    /**
     * get the amount of new USDC we have taken account for, and update lastUSDCDistroTimestamp and promisedUSDC
     */
    function getUSDCDrip() internal returns (uint) {
        uint usdcBalance = usdcCurrency.balanceOf(address(this));
        if (promisedUSDC > usdcBalance)
            return 0;

        uint usdcAvailable = usdcBalance - promisedUSDC;

        // only provide a drip if there has been some seconds passed since the last drip
        uint blockSinceLastDistro = block.timestamp > poolInfo.lastRewardTimestamp ? block.timestamp - poolInfo.lastRewardTimestamp : 0;

        // We distribute the usdc assuming the old usdc balance wanted to be distributed over usdcDistributionTimeFrameSeconds seconds.
        uint usdcRelease = (blockSinceLastDistro * usdcAvailable) / usdcDistributionTimeFrameSeconds;

        usdcRelease = usdcRelease > usdcAvailable ? usdcAvailable : usdcRelease;

        promisedUSDC += usdcRelease;

        return usdcRelease;
    }

    /**
     * get the amount of new WHEAT we have taken account for, and update lastWHEATDistroTimestamp and promisedWHEAT
     */
    function getWHEATDrip() internal returns (uint) {
        uint wheatBalance = wheatCurrency.balanceOf(address(this));
        if (promisedWHEAT > wheatBalance)
            return 0;

        uint wheatAvailable = wheatBalance - promisedWHEAT;

        // only provide a drip if there has been some seconds passed since the last drip
        uint blockSinceLastDistro = block.timestamp > poolInfo.lastRewardTimestamp ? block.timestamp - poolInfo.lastRewardTimestamp : 0;

        // We distribute the wheat assuming the old wheat balance wanted to be distributed over wheatDistributionTimeFrameSeconds seconds.
        uint wheatRelease = (blockSinceLastDistro * wheatAvailable) / wheatDistributionTimeFrameSeconds;

        wheatRelease = wheatRelease > wheatAvailable ? wheatAvailable : wheatRelease;

        promisedWHEAT += wheatRelease;

        return wheatRelease;
    }

    /**
     * @dev send usdc to a user
     */
    function transferUSDCToUser(address recipient, uint amount) internal {
        uint usdcBalance = usdcCurrency.balanceOf(address(this));
        if (usdcBalance < amount)
            amount = usdcBalance;

        promisedUSDC -= amount;

        usdcCurrency.safeTransfer(recipient, amount);

        emit USDCTransferredToUser(recipient, amount);
    }

    /**
     * @dev send wheat to a user
     * Can only be called by the current operator.
     */
    function transferWHEATToUser(address recipient, uint amount) internal {
        uint wheatBalance = wheatCurrency.balanceOf(address(this));
        if (wheatBalance < amount)
            amount = wheatBalance;

        promisedWHEAT -= amount;

        require(wheatCurrency.transfer(recipient, amount), "transfer failed!");

        emit WHEATTransferredToUser(recipient, amount);
    }

    /**
     * @dev set the number of seconds we should use to calculate the USDC drip rate.
     * Can only be called by the current operator.
     */
    function setUSDCDistributionTimeFrame(uint _usdcDistributionTimeFrame) external onlyOwner {
        require(_usdcDistributionTimeFrame > 0, "_usdcDistributionTimeFrame out of range!");
        require(_usdcDistributionTimeFrame < 32 days, "_usdcDistributionTimeFrame out of range!");

        usdcDistributionTimeFrameSeconds = _usdcDistributionTimeFrame;

        emit SetUSDCDistributionTimeFrame(usdcDistributionTimeFrameSeconds);
    }

    /**
     * @dev set the number of seconds we should use to calculate the WHEAT drip rate.
     * Can only be called by the current operator.
     */
    function setWHEATDistributionTimeFrame(uint _wheatDistributionTimeFrame) external onlyOwner {
        require(_wheatDistributionTimeFrame > 0, "_wheatDistributionTimeFrame out of range!");
        require(_wheatDistributionTimeFrame < 32 days, "_usdcDistributionTimeFrame out of range!");

        wheatDistributionTimeFrameSeconds = _wheatDistributionTimeFrame;

        emit SetWHEATDistributionTimeFrame(wheatDistributionTimeFrameSeconds);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./WHEAT.sol";

contract FarmerLandNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeERC20 for WHEAT;

    mapping(address => uint) public userRoostingsCount;

    uint public immutable MAX_ELEMENTS;
    uint public maticPrice = 0 * 1e18;
    uint public wheatPrice = 3 * 1e18;

    WHEAT public immutable wheatToken;

    mapping(address => bool) public admins;

    address public constant founder = 0xa54eD6cfD0D78d7Ea308Bcc5b9c5E819e8Eebd3D;

    bool public paused = true;
    uint public startTime;

    uint public constant MAX_CONCURRENT_MINT = 50;
    uint public immutable MAX_LEVEL;
    uint public constant MAX_ABILITY = 999e4;
    uint public immutable ABILITY_SCALAR;

    mapping(uint => uint) private level;
    mapping(uint => uint) private ability;

    uint public immutable nftType;

    string public baseTokenURI;

    // Timers for how long an nftId has been roosted
    mapping(uint => uint) public foreverRoostingTimer;
    mapping(uint => uint) public startOfCurrentRoosting;

    // Whitelist for people to get one free mint (promo)
    mapping(address => bool) public freeMintWhitelist;

    event AbilitySet(uint tokenId, uint oldAbility, uint newAbility);
    event LevelSet(uint tokenId, uint oldLevel, uint newLevel);
    event WithdrawGas(address destination, uint gasBalance);
    event WithdrawWHEAT(address destination, uint wheatBalance);
    event AddToWhiteList(uint numberOfAllocations);
    event BaseURISet(string oldURI, string newURI);

    event Paused(bool currentPausedStatus);
    event StartTimeChanged(uint newStartTime);
    event WHEATPriceSet(uint price);
    event MATICPriceSet(uint price);
    event AdminSet(address admin, bool value);
    event NFTRoosted(uint indexed id);
    event NFTUnRoosted(uint indexed id);
    event CreateFarmerLandNFT(uint indexed id);
    constructor(uint  _startTime, uint _nftType, uint _MAX_ELEMENTS,  uint _MAX_LEVEL, uint _ABILITY_SCALAR, WHEAT _WHEAT, string memory name1, string memory name2) ERC721(name1, name2) {
        require(_MAX_ELEMENTS%2 == 0, "max elements must be even");
        require(_MAX_LEVEL <= 200, "_ABILITY_SCALAR out of range");
        require(_ABILITY_SCALAR > 0 && _ABILITY_SCALAR <= 10, "_ABILITY_SCALAR out of range");

        MAX_ELEMENTS = _MAX_ELEMENTS;
        MAX_LEVEL =_MAX_LEVEL;
        ABILITY_SCALAR = _ABILITY_SCALAR;

        wheatToken = _WHEAT;

        startTime = _startTime;
        nftType = _nftType;

        admins[founder] = true;
        admins[msg.sender] = true;
    }

    mapping(uint256 => uint256) private _tokenIdsCache;

    function availableSupply() public view returns (uint) {
        return MAX_ELEMENTS - totalSupply();
    }
    function _getNextRandomNumber() private returns (uint256 index) {
        uint _availableSupply = availableSupply();
        require(_availableSupply > 0, "Invalid _remaining");

        uint256 i = (MAX_ELEMENTS + uint(keccak256(abi.encode(block.timestamp, tx.origin, blockhash(block.number-1))))) %
            _availableSupply;

        // if there's a cache at _tokenIdsCache[i] then use it
        // otherwise use i itself
        index = _tokenIdsCache[i] == 0 ? i : _tokenIdsCache[i];

        // grab a number from the tail
        _tokenIdsCache[i] = _tokenIdsCache[_availableSupply - 1] == 0
            ? _availableSupply - 1
            : _tokenIdsCache[_availableSupply - 1];
    }

    function getUsersNumberOfRoostings(address user) external view returns (uint) {
        return userRoostingsCount[user];
    }

    function getAbility(uint tokenId) external view returns (uint) {
        return ability[tokenId];
    }

    function setAbility(uint tokenId, uint _ability) external {
        require(admins[msg.sender], "sender not admin!");
        require(_ability <= MAX_ABILITY, "ability too high!");

        uint oldAbility = ability[tokenId];

        ability[tokenId] = _ability;

        emit AbilitySet(tokenId, oldAbility, _ability);
    }

    function getLevel(uint tokenId) external view returns (uint) {
        return level[tokenId];
    }

    function setLevel(uint tokenId, uint _level) external {
        require(admins[msg.sender], "sender not admin!");
        require(_level <= MAX_LEVEL, "level too high!");

        uint oldLevel = level[tokenId];

        level[tokenId] = _level;

         emit LevelSet(tokenId, oldLevel, _level);
    }

    function mint(address _to, uint _count) external payable nonReentrant {
        require(!paused, "Minting is paused!");
        require(startTime < block.timestamp, "Minting not started yet!");
        require(admins[msg.sender] || _count <= MAX_CONCURRENT_MINT, "Can only mint 50!");

        uint total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");

        if (!freeMintWhitelist[msg.sender]) {
            require(msg.value >= getMATICPrice(_count) ||
                    admins[msg.sender], "Value below price");
            if (!admins[msg.sender])
                wheatToken.safeTransferFrom(msg.sender, address(this), getWHEATPrice(_count));
        } else {
            require(msg.value >= getMATICPrice(_count - 1) ||
                    admins[msg.sender], "Value below price");
            if (!admins[msg.sender])
                wheatToken.safeTransferFrom(msg.sender, address(this), getWHEATPrice(_count - 1));
            freeMintWhitelist[msg.sender] = false;
        }

        for (uint i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _getNextRandomNumber() + 1;

        // intentionally predictable
        uint abilityRNG = uint(keccak256(abi.encode(id * MAX_ELEMENTS))) % 10;

        if (abilityRNG == 0) {
            ability[id] = 4e4; // 10% probability
        } else if (abilityRNG <= 3) {
            ability[id] = 3e4; // 30% probability
        } else if (abilityRNG <= 6) {
            ability[id] = 2e4; // 30% probability
        } else {
            ability[id] = 1e4; // 30% probability
        }

        ability[id] = ability[id] * ABILITY_SCALAR;

        emit CreateFarmerLandNFT(id);

        _mint(_to, id);
    }
    function getMATICPrice(uint _count) public view returns (uint) {
        return maticPrice * _count;
    }
    function getWHEATPrice(uint _count) public view returns (uint) {
        return wheatPrice * _count;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) external onlyOwner {
        emit BaseURISet(baseTokenURI, baseURI);

        baseTokenURI = baseURI;
    }
    function withdrawGas() public payable onlyOwner {
        uint gasBalance = address(this).balance;
        require(gasBalance > 0, "zero balance");

        _withdraw(founder, gasBalance);

        emit WithdrawGas(founder, gasBalance);
    }

    function withdrawWHEAT() public onlyOwner {
        uint wheatBalance = wheatToken.balanceOf(address(this));
        require(wheatBalance > 0, "zero balance");

        wheatToken.safeTransfer(founder, wheatBalance);

        emit WithdrawWHEAT(founder, wheatBalance);
    }

    function walletOfOwner(address _owner, uint startIndex, uint count) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint[] memory tokensId = new uint[](tokenCount);
        for (uint i = startIndex; i < tokenCount && i - startIndex < count; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    function _withdraw(address _address, uint _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    /// @dev overrides transfer function to enable roosting!
    function _transfer(address from, address to, uint tokenId) internal override {
        if (isNftIdRoosting(tokenId)) {
            foreverRoostingTimer[tokenId]+= block.timestamp - startOfCurrentRoosting[tokenId];
            startOfCurrentRoosting[tokenId] = 0;

            userRoostingsCount[from]--;

            emit NFTUnRoosted(tokenId);
        }

        super._transfer( from, to, tokenId );
    }
    function isNftIdRoosting(uint nftId) public view returns (bool) {
        return startOfCurrentRoosting[nftId] > 0;
    }
    function isNftIdRoostingWithOwner(address owner, uint nftId) external view returns (bool) {
        return ownerOf(nftId) == owner && startOfCurrentRoosting[nftId] > 0;
    }
    function roostNftId(uint nftId) external {
        require(ownerOf(nftId) == msg.sender, "owner of NFT isn't sender!");
        require(nftId <= MAX_ELEMENTS, "invalid NFTId!");
        require(startOfCurrentRoosting[nftId] == 0, "nft is aready roosting!");

        startOfCurrentRoosting[nftId] = block.timestamp;

        userRoostingsCount[msg.sender]++;

        emit NFTRoosted(nftId);
    }
    function unroostNftId(uint nftId) public {
        require(ownerOf(nftId) == msg.sender, "owner of NFT isn't sender!");
        require(nftId <= MAX_ELEMENTS, "invalid NFTId!");
        require(startOfCurrentRoosting[nftId] > 0, "nft isnt currently roosting!");

        foreverRoostingTimer[nftId]+= block.timestamp - startOfCurrentRoosting[nftId];
        startOfCurrentRoosting[nftId] = 0;

        userRoostingsCount[msg.sender]--;

        emit NFTUnRoosted(nftId);
    }
    function addToWhiteList(address[] calldata participants) external onlyOwner {
        for (uint i = 0;i<participants.length;i++) {
            freeMintWhitelist[participants[i]] = true;
        }

        emit AddToWhiteList(participants.length);
    }
    function setMATICPrice(uint _newPrice) public onlyOwner {
        maticPrice = _newPrice;

        emit MATICPriceSet(maticPrice);
    }
    function setWHEATPrice(uint _newPrice) public onlyOwner {
        wheatPrice = _newPrice;

        emit WHEATPriceSet(wheatPrice);
    }
   function pause() external onlyOwner {
        paused = !paused;

        emit Paused(paused);
    }
   function setStartTime(uint _newStartTime) external onlyOwner {
        require(startTime == 0 || block.timestamp < startTime, "Minting has already started!");
        require(_newStartTime > startTime, "new start time must be in future!");
        startTime = _newStartTime;

        emit StartTimeChanged(_newStartTime);
    }
    function setAdmins(address _newAdmin, bool status) public onlyOwner {
        admins[_newAdmin] = status;

        emit AdminSet(_newAdmin, status);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { FarmerLandNFT } from "./FarmerLandNFT.sol";

contract WHEAT is ERC20, Ownable, ReentrancyGuard {
    ERC20 public constant token_USDC = ERC20(0x2C6874f2600310CB35853e2D35a3C2150FB1e8d0);

    struct RoostInfo {
        address series;
        uint tokenId;
    }

    mapping(address => RoostInfo) public minotaurNFTRoost;

    mapping(address => RoostInfo) public farmerNFTRoost;
    mapping(address => RoostInfo) public landNFTRoost;
    mapping(address => RoostInfo) public toolNFTRoost;

    // Mapping of NFT contract address to which NFTs a user has staked.
    mapping(address => bool) public nftAddressAllowList;

    mapping(address => uint256) public stakeCounts;

    event PercentOfLobbyToBePooledChanged(uint oldPercent, uint newPercent);
    event MCAddressSet(address oldAddress, address newAddress);
    event DaoAddressSet(address oldAddress, address newAddress);
    event LotteryShareSet(uint oldValue, uint newValue);
    event DaoUSDCWHEATShares(uint oldUSDCShare, uint oldUWHEATShare, uint newUSDCShare, uint newWHEATShare);
    event MCUSDCWHEATShares(uint oldUSDCShare, uint oldUWHEATShare, uint newUSDCShare, uint newWHEATShare);
    event LastLobbySet(uint oldValue, uint newValue);
    event DividensPoolCalDaysSet(uint oldValue, uint newValue);
    event LoaningStatusSwitched(bool oldValue, bool newValue);
    event VirtualBalanceEnteringSwitched(bool oldValue, bool newValue);
    event StakeSellingStatusSwitched(bool oldValue, bool newValue);
    event LottyPoolFlushed(address destination, uint amount);
    event DevShareOfStakeSellsFlushed(address destination, uint amount);

    event UserStake(address indexed addr, uint rawAmount, uint duration, uint stakeId);

    event UserStakeCollect(address indexed addr, uint rawAmount, uint stakeId, uint bonusAmount);

    event UserLobby(address indexed addr, uint rawAmount, uint extraAmount, address referrer);

    event UserLobbyCollect(address indexed addr, uint rawAmount, uint day, uint boostedAmount, uint masterchefWHEATShare, uint daoWHEATShare, uint ref_bonus_NR, uint ref_bonus_NRR);

    event StakeSellRequest(address indexed addr, uint price, uint rawAmount, uint stakeId);

    event CancelStakeSellRequest(address indexed addr, uint stakeId);

    event StakeBuyRequest(address indexed seller, uint sellerStakeId, address indexed buyer, uint buyerStakeId, uint tradeAmount);

    event StakeLoanRequest(address indexed addr, uint rawAmount, uint returnAmount, uint duration, uint stakeId);

    event CancelStakeLoanRequest(address indexed addr, uint stakeId);

    event StakeLend(address indexed addr, uint lendId, address indexed loaner, uint stakeId, uint amount);

    event StakeLoanFinished(address indexed lender, uint lendId, address indexed loaner, uint stakeId, uint amount);

    event DayLobbyEntry(uint day, uint value);

    event LotteryWinner(address indexed addr, uint amount, uint lastRecord);

    event LotteryUpdate(uint newPool, uint lastRecord);

    event WithdrawSoldStakeFunds(address indexed addr, uint amount);

    event WithdrawLoanedFunds(address indexed addr, uint amount);

    event NftAddressAllowListSet(address series, bool allowed);

    event NFTRoosted(address series, uint tokenId, uint prevTokenId);

    constructor(
        uint launchTime
    ) ERC20("WHEAT", "WHEAT") {
        LAUNCH_TIME = launchTime;
        _mint(msg.sender, 8500 * 1e18); // 8k for breading event, 500 for promos.
        _updatePercentOfLobbyToBePooled();
    }

    function set_nftMasterChefAddress(address _nftMasterChefAddress) external onlyOwner() {
        require(_nftMasterChefAddress != address(0), "!0");

        address oldNftMasterChefAddress = nftMasterChefAddress;

        nftMasterChefAddress = _nftMasterChefAddress;

        emit  MCAddressSet(oldNftMasterChefAddress, _nftMasterChefAddress);
    }

    /* change team wallets address % */
    function changeDaoAddress(address _daoAddress) external onlyOwner() {
        require(_daoAddress != address(0), "!0");

        address oldDaoAddress = daoAddress;

        daoAddress = _daoAddress;

        emit  DaoAddressSet(oldDaoAddress, _daoAddress);
    }

    address public nftMasterChefAddress;
    address public daoAddress = 0x994aF05EB0eA1Bb37dfEBd2EA279133C8059ffa7; // 10% WHEAT, 5% USDC

    // 2% of lobby entried goto lottery pot
    uint public lottery_share_percentage = 200;

    /* Time of contract launch */
    uint internal immutable LAUNCH_TIME;
    uint public currentDay;

    function _updatePercentOfLobbyToBePooled() private {
        uint oldPercentOfLobbyToBePooled = percentOfLobbyToBePooled;
        percentOfLobbyToBePooled = 10000 - (lottery_share_percentage + masterchefUSDCShare + daoUSDCShare);

        emit PercentOfLobbyToBePooledChanged(oldPercentOfLobbyToBePooled, percentOfLobbyToBePooled);
    }

    function set_lottery_share_percentage(uint _lottery_share_percentage) external onlyOwner() {
        // Max 10%
        require(_lottery_share_percentage <= 1000);

        uint oldLotterySharePercentage = lottery_share_percentage;

        lottery_share_percentage = _lottery_share_percentage;

        _updatePercentOfLobbyToBePooled();

        emit LotteryShareSet(oldLotterySharePercentage, _lottery_share_percentage);
    }

    function set_masterchefUSDCWHEATShare(uint _masterchefUSDCShare, uint _masterchefWHEATShare) external onlyOwner() {
        require(_masterchefUSDCShare <= 1000 && _masterchefWHEATShare <= 1000);

        uint oldMasterchefUSDCShare = masterchefUSDCShare;
        uint oldMasterchefWHEATShare = masterchefWHEATShare;

        masterchefUSDCShare = _masterchefUSDCShare;
        masterchefWHEATShare = _masterchefWHEATShare;

        _updatePercentOfLobbyToBePooled();
        
        emit MCUSDCWHEATShares(oldMasterchefUSDCShare, oldMasterchefWHEATShare, _masterchefUSDCShare, _masterchefWHEATShare);
    }

    function set_daoUSDCWHEATShares(uint _daoUSDCShare, uint _daoWHEATShare) external onlyOwner() {
        require(_daoUSDCShare <= 1000 && _daoWHEATShare <= 1000);

        uint oldDaoUSDCShare = daoUSDCShare;
        uint oldDaoWHEATShare = daoWHEATShare;

        daoUSDCShare = _daoUSDCShare;
        daoWHEATShare = _daoWHEATShare;

        _updatePercentOfLobbyToBePooled();

        emit DaoUSDCWHEATShares(oldDaoUSDCShare, oldDaoWHEATShare, _daoUSDCShare, _daoWHEATShare);
    }

    uint public masterchefUSDCShare = 500;
    uint public masterchefWHEATShare = 1000;

    uint public daoUSDCShare = 500;
    uint public daoWHEATShare = 1000;

    function set_lastLobbyPool(uint _lastLobbyPool) external onlyOwner() {
        uint oldLastLobbyPool = lastLobbyPool;

        lastLobbyPool = _lastLobbyPool;

        emit LastLobbySet(oldLastLobbyPool, _lastLobbyPool);
    }


    mapping(uint => uint) public lobbyPool;
    /* last amount of lobby pool that are minted daily to be distributed between lobby participants which starts from 5k */
    uint public lastLobbyPool = 5050505050505050505051;

    /* Every day's lobby pool is % lower than previous day's */
    uint internal constant lobby_pool_decrease_percentage = 100; // 1%

    /* % of every day's lobby entry to be pooled as divs, default 89.5% = 100% - (5% dao + 5% nft staking + 0.5% lottery) */
    uint public percentOfLobbyToBePooled;

    /* The ratio num for calculating stakes bonus tokens */
    uint internal constant bonus_calc_ratio = 310;

    /* Max staking days */
    uint public constant max_stake_days = 180;

    /* Ref bonus NR 3%*/
    uint public constant ref_bonus_NR = 300;

    /* Refered person bonus NR 2%*/
    uint public constant ref_bonus_NRR = 200;

    function set_dividendsPoolCapDays(uint _dividendsPoolCapDays) external onlyOwner() {
        require(_dividendsPoolCapDays > 0 && _dividendsPoolCapDays <= 300);

        uint oldDividendsPoolCapDays = dividendsPoolCapDays;

        dividendsPoolCapDays = _dividendsPoolCapDays;

        emit DividensPoolCalDaysSet(oldDividendsPoolCapDays, _dividendsPoolCapDays);
    }

    /* dividends pool caps at 50 days, meaning that the lobby entery of days > 50 will only devide for next 60 days and no more */
    uint public dividendsPoolCapDays = 50;

    /* Loaning feature is paused? */
    bool public loaningIsPaused = false;

    /* Stake selling feature is paused? */
    bool public stakeSellingIsPaused = false;

    /* virtual Entering feature is paused? */
    bool public virtualBalanceEnteringIsPaused = false;

    // the last referrer per user
    mapping(address => address) public usersLastReferrer;

    /* ------------------ for the sake of UI statistics ------------------ */
    // lobby memebrs overall data
    struct memberLobby_overallData {
        uint overall_collectedTokens;
        uint overall_lobbyEnteries;
        uint overall_stakedTokens;
        uint overall_collectedDivs;
    }

    // total lobby entry
    uint public overall_lobbyEntry;
    // total staked tokens
    uint public overall_stakedTokens;
    // total lobby token collected
    uint public overall_collectedTokens;
    // total stake divs collected
    uint public overall_collectedDivs;
    // total bonus token collected
    uint public overall_collectedBonusTokens;
    // total referrer bonus paid to an address
    mapping(address => uint) public referrerBonusesPaid;
    // counting unique (unique for every day only) lobby enteries for each day
    mapping(uint => uint) public usersCountDaily;
    // counting unique (unique for every day only) users
    uint public usersCount = 0;
    /* Total ever entered as stake tokens */
    uint public saveTotalToken;
    /* ------------------ for the sake of UI statistics ------------------ */

    /* lobby memebrs data */
    struct memberLobby {
        uint extraVirtualTokens;
        uint entryAmount;
        uint entryDay;
        bool collected;
        address referrer;
    }

    function getMapMemberLobbyEntryByDay(address user, uint day) external view returns (uint) {
        return mapMemberLobby[user][day].entryAmount;
    }

    /* new map for every entry (users are allowed to enter multiple times a day) */
    mapping(address => mapping(uint => memberLobby)) public mapMemberLobby;

    /* day's total lobby entry */
    mapping(uint => uint) public lobbyEntry;

    /* User stakes struct */
    struct memberStake {
        address userAddress;
        uint tokenValue;
        uint startDay;
        uint endDay;
        uint stakeId;
        uint price; // use: sell stake
        uint loansReturnAmount; // total of the loans return amount that have been taken on this stake
        bool collected;
        bool hasSold; // stake been sold ?
        bool forSell; // currently asking to sell stake ?
        bool hasLoan; // is there an active loan on stake ?
        bool forLoan; // currently asking for a loan on the stake ?
    }

    /* A map for each user */
    mapping(address => mapping(uint => memberStake)) public mapMemberStake;

    /* Owner switching the loaning feature status */
    function switchLoaningStatus() external onlyOwner() {
        loaningIsPaused = !loaningIsPaused;

        emit LoaningStatusSwitched(!loaningIsPaused, loaningIsPaused);
    }

    /* Owner switching the virtualBalanceEntering feature status */
    function switchVirtualBalanceEntering() external onlyOwner() {
        virtualBalanceEnteringIsPaused = !virtualBalanceEnteringIsPaused;

        emit VirtualBalanceEnteringSwitched(!virtualBalanceEnteringIsPaused, virtualBalanceEnteringIsPaused);
    }

    /* Owner switching the stake selling feature status */
    function switchStakeSellingStatus() external onlyOwner() {
        stakeSellingIsPaused = !stakeSellingIsPaused;
    
        emit StakeSellingStatusSwitched(!stakeSellingIsPaused, stakeSellingIsPaused);
    }

    /* Flushed lottery pool*/
    function flushLottyPool() external onlyOwner() nonReentrant {
        if (lottery_Pool > 0) {
            uint256 amount = lottery_Pool;
            lottery_Pool = 0;
            token_USDC.transfer(daoAddress, amount);
        
            emit LottyPoolFlushed(daoAddress, amount);
        }
    }

    /**
     * @dev flushes the dev share from stake sells
     */
    function flushDevShareOfStakeSells() external onlyOwner() nonReentrant {
        require(devShareOfStakeSellsAndLoanFee > 0);

        token_USDC.transfer(address(daoAddress), devShareOfStakeSellsAndLoanFee);

        uint oldDevShareOfStakeSellsAndLoanFee = devShareOfStakeSellsAndLoanFee;

        devShareOfStakeSellsAndLoanFee = 0;

        emit DevShareOfStakeSellsFlushed(daoAddress, oldDevShareOfStakeSellsAndLoanFee);
    }

    function _clcDay() public view returns (uint) {
        if (block.timestamp <= LAUNCH_TIME) return 0;
        return (block.timestamp - LAUNCH_TIME) / 10 minutes;
    }

    function updateDaily() public {
        // this is true once a day
        uint _currentDay = _clcDay();
        if (currentDay != _currentDay) {
            if (currentDay < dividendsPoolCapDays) {
                for (uint _day = currentDay + 1; _day <= (currentDay * 2 + 1); _day++) {
                    dayUSDCPool[_day] += currentDay > 0 ? (lobbyEntry[currentDay] * percentOfLobbyToBePooled) / ((currentDay + 1) * 10000) : 0;
                }
            } else {
                for (uint _day = currentDay + 1; _day <= currentDay + dividendsPoolCapDays; _day++) {
                    dayUSDCPool[_day] += (lobbyEntry[currentDay] * percentOfLobbyToBePooled) / (dividendsPoolCapDays * 10000);
                }
            }

            currentDay = _currentDay;
            _updateLobbyPool();
            lobbyPool[currentDay] = lastLobbyPool;

            // total of 12% from every day's lobby entry goes to:
            // 5% dao + 5% nft masterchef
            _sendShares();
            // 2% lottery
            checkLottery();

            emit DayLobbyEntry(currentDay, lobbyEntry[currentDay - 1]);
        }
    }

    /* Every day's lobby pool reduces by a % */
    function _updateLobbyPool() internal {
        lastLobbyPool -= ((lastLobbyPool * lobby_pool_decrease_percentage) /10000);
    }

    /* Gets called once a day */
    function _sendShares() internal {
        require(currentDay > 0);

        if (daoAddress != address(0)) {
            // daoUSDCShare = 5% of every day's lobby entry
            uint daoUSDCRawShare = (lobbyEntry[currentDay - 1] * daoUSDCShare) /10000;
            token_USDC.transfer(address(daoAddress), daoUSDCRawShare);
        }

        if (nftMasterChefAddress != address(0))  {
            // masterchefUSDCShare = 5% of every day's lobby entry
            uint masterchefUSDCRawShare = (lobbyEntry[currentDay - 1] * masterchefUSDCShare) /10000;
            token_USDC.transfer(address(nftMasterChefAddress), masterchefUSDCRawShare);
        }
    }
    /**
     * @dev User enters lobby with all of his finished stake divs and receives 10% extra virtual coins
     * @param referrerAddr address of referring user (optional; 0x0 for no referrer)
     * @param stakeId id of the Stake
     */
    function virtualBalanceEnteringLobby(address referrerAddr, uint stakeId) external nonReentrant {
        require(virtualBalanceEnteringIsPaused == false, "paused");
        require(mapMemberStake[msg.sender][stakeId].endDay <= currentDay, "Locked stake");

        DoEndStake(stakeId, true);

        uint profit = calcStakeCollecting(msg.sender, stakeId);

        // enter lobby with 10% extra virtual USDC
        DoEnterLobby(referrerAddr, profit + ((profit * 10) /100), ((profit * 10) /100));
    }

    /**
     * @dev External function for entering the auction lobby for the current day
     * @param referrerAddr address of referring user (optional; 0x0 for no referrer)
     * @param amount amount of USDC entrying to lobby
     */
    function EnterLobby(address referrerAddr, uint amount) external {
        DoEnterLobby(referrerAddr, amount, 0);
    }

    /**
     * @dev entering the auction lobby for the current day
     * @param referrerAddr address of referring user (optional; 0x0 for no referrer)
     * @param amount amount of USDC entrying to lobby
     * @param virtualExtraAmount the virtual amount of tokens
     */
    function DoEnterLobby(
        address referrerAddr,
        uint amount,
        uint virtualExtraAmount
    ) internal {
        uint rawAmount = amount;
        require(rawAmount > 0, "!0");

        // transfer USDC from user wallet if stake profits have already sent to user
        if (virtualExtraAmount == 0) {
            token_USDC.transferFrom(msg.sender, address(this), amount);
        }

        updateDaily();

        require(currentDay > 0, "lobby disabled on day 0!");

        if (mapMemberLobby[msg.sender][currentDay].entryAmount == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        // raw amount is added by 10% virtual extra, since we don't want that 10% to be in the dividends calculation we remove it
        if (virtualExtraAmount > 0) {
            lobbyEntry[currentDay] += (rawAmount - virtualExtraAmount);
            overall_lobbyEntry += (rawAmount - virtualExtraAmount);

            mapMemberLobby[msg.sender][currentDay].extraVirtualTokens += virtualExtraAmount;
        } else {
            lobbyEntry[currentDay] += rawAmount;
            overall_lobbyEntry += rawAmount;
        }

        // mapMemberLobby[msg.sender][currentDay].memberLobbyAddress = msg.sender;
        mapMemberLobby[msg.sender][currentDay].entryAmount += rawAmount;


        if (mapMemberLobby[msg.sender][currentDay].entryAmount > lottery_topBuy_today) {
            // new top buyer
            lottery_topBuy_today = mapMemberLobby[msg.sender][currentDay].entryAmount;
            lottery_topBuyer_today = msg.sender;
        }

        mapMemberLobby[msg.sender][currentDay].entryDay = currentDay;
        mapMemberLobby[msg.sender][currentDay].collected = false;

        if ((referrerAddr == address(0) || referrerAddr == msg.sender) &&
            usersLastReferrer[msg.sender] != address(0) && usersLastReferrer[msg.sender] != msg.sender) {
            mapMemberLobby[msg.sender][currentDay].referrer = usersLastReferrer[msg.sender];
        } else if (referrerAddr != msg.sender && referrerAddr != address(0)) {
            usersLastReferrer[msg.sender] = referrerAddr;
            /* No Self-referred */
            mapMemberLobby[msg.sender][currentDay].referrer = referrerAddr;
        }

        emit UserLobby(msg.sender, rawAmount, virtualExtraAmount, mapMemberLobby[msg.sender][currentDay].referrer);
    }

    /**
     * @dev set which Nfts are allowed to be staked
     * Can only be called by the current operator.
     */
    function setNftAddressAllowList(address _series, bool allowed) external onlyOwner() {
        nftAddressAllowList[_series] = allowed;
    
        emit NftAddressAllowListSet(_series, allowed);
    }

    function getNFTType(address series) internal view returns (uint) {
        return FarmerLandNFT(series).nftType();
    }

    function setUserNFTRoostings(address series, uint tokenId) external nonReentrant {
        require(nftAddressAllowList[series]);
        require(tokenId == 0 || isNftIdRoostingWithOwner(msg.sender, series, tokenId), "!roosted");

        uint nftType = getNFTType(series);

        uint prevTokenId;
        if (nftType == 1) {
            prevTokenId = farmerNFTRoost[msg.sender].tokenId;
            farmerNFTRoost[msg.sender].series = series;
            farmerNFTRoost[msg.sender].tokenId = tokenId;
        } else if (nftType == 2) {
            prevTokenId = landNFTRoost[msg.sender].tokenId;
            landNFTRoost[msg.sender].series = series;
            landNFTRoost[msg.sender].tokenId = tokenId;
        } else if (nftType == 3) {
            prevTokenId = toolNFTRoost[msg.sender].tokenId;
            toolNFTRoost[msg.sender].series = series;
            toolNFTRoost[msg.sender].tokenId = tokenId;
        } else if (nftType == 4) {
            prevTokenId = minotaurNFTRoost[msg.sender].tokenId;
            minotaurNFTRoost[msg.sender].series = series;
            minotaurNFTRoost[msg.sender].tokenId = tokenId;
        }

        emit NFTRoosted(series, tokenId, prevTokenId);
    }

    function isNftIdRoostingWithOwner(address owner, address series, uint tokenId) internal view returns (bool) {
        if (series != address(0))
            return FarmerLandNFT(series).isNftIdRoostingWithOwner(owner, tokenId);
        else
            return false;
    }

    function getNFTAbility(address series, uint tokenId) internal view returns (uint) {
        return FarmerLandNFT(series).getAbility(tokenId);
    }

    // _clcNFTBoost = amount * (1.05 + ability * 0.003)
    function _clcNFTBoost(uint amount, uint ability /* basis points 1e4 */) internal pure returns (uint) {
        return (amount * (1e12 * 105 / 100 + (((1e12 * ability * 3) / 1000) / 1e4))) / 1e12;
    }

    function getNFTRoostingBoostedAmount(uint tokenAmount) public view returns (uint) {
        if (isNftIdRoostingWithOwner(msg.sender, farmerNFTRoost[msg.sender].series, farmerNFTRoost[msg.sender].tokenId)) {
            tokenAmount = _clcNFTBoost(
                tokenAmount,
                getNFTAbility(farmerNFTRoost[msg.sender].series, farmerNFTRoost[msg.sender].tokenId)
            );
            // A Tool NFT can only be used as boost if a farmer is also roosting...
            if (isNftIdRoostingWithOwner(msg.sender, toolNFTRoost[msg.sender].series, toolNFTRoost[msg.sender].tokenId)) {
                tokenAmount = _clcNFTBoost(
                    tokenAmount,
                    getNFTAbility(toolNFTRoost[msg.sender].series, toolNFTRoost[msg.sender].tokenId)
                );
            }
        }

        if (isNftIdRoostingWithOwner(msg.sender, landNFTRoost[msg.sender].series, landNFTRoost[msg.sender].tokenId)) {
            tokenAmount = _clcNFTBoost(
                tokenAmount,
                getNFTAbility(landNFTRoost[msg.sender].series, landNFTRoost[msg.sender].tokenId)
            );
        }

        if (isNftIdRoostingWithOwner(msg.sender, minotaurNFTRoost[msg.sender].series, minotaurNFTRoost[msg.sender].tokenId)) {
            tokenAmount = _clcNFTBoost(
                tokenAmount,
                getNFTAbility(minotaurNFTRoost[msg.sender].series, minotaurNFTRoost[msg.sender].tokenId)
            );
        }

        return tokenAmount;
    }

    /**
     * @dev External function for leaving the lobby / collecting the tokens
     * @param targetDay Target day of lobby to collect
     */
    function ExitLobby(uint targetDay) external {
        require(mapMemberLobby[msg.sender][targetDay].collected == false, "Already collected");
        updateDaily();
        require(targetDay < currentDay);

        uint tokensToPay = clcTokenValue(msg.sender, targetDay);

        uint exitLobbyWHEATAmount = getNFTRoostingBoostedAmount(tokensToPay);

        mapMemberLobby[msg.sender][targetDay].collected = true;

        overall_collectedTokens += exitLobbyWHEATAmount;

        _mint(msg.sender, exitLobbyWHEATAmount);

        if (nftMasterChefAddress != address(0) && exitLobbyWHEATAmount > 0 && masterchefWHEATShare > 0)
            _mint(nftMasterChefAddress, (exitLobbyWHEATAmount * masterchefWHEATShare) /10000);
        if (daoAddress != address(0) && exitLobbyWHEATAmount > 0 && daoWHEATShare > 0)
            _mint(daoAddress, (exitLobbyWHEATAmount * daoWHEATShare) /10000);

        address referrerAddress = mapMemberLobby[msg.sender][targetDay].referrer;
        if (referrerAddress != address(0)) {
            /* there is a referrer, pay their % ref bonus of tokens */
            uint refBonus = (tokensToPay * ref_bonus_NR) /10000;

            referrerBonusesPaid[referrerAddress] += refBonus;

            _mint(referrerAddress, refBonus);

            /* pay the referred user bonus */
            _mint(msg.sender, (tokensToPay * ref_bonus_NRR) /10000);
        }

        emit UserLobbyCollect(msg.sender, tokensToPay, targetDay, exitLobbyWHEATAmount, masterchefWHEATShare, daoWHEATShare, ref_bonus_NR, ref_bonus_NRR);
    }

    /**
     * @dev Calculating user's share from lobby based on their entry value
     * @param _day The lobby day
     */
    function clcTokenValue(address _address, uint _day) public view returns (uint) {
        require(_day != 0, "lobby disabled on day 0!");
        uint _tokenValue;
        uint entryDay = mapMemberLobby[_address][_day].entryDay;

        if (entryDay != 0 && entryDay < currentDay) {
            _tokenValue = (lobbyPool[_day] * mapMemberLobby[_address][_day].entryAmount) / lobbyEntry[entryDay];
        } else {
            _tokenValue = 0;
        }

        return _tokenValue;
    }

    mapping(uint => uint) public dayUSDCPool;
    mapping(uint => uint) public enterytokenMath;
    mapping(uint => uint) public totalTokensInActiveStake;

    /**
     * @dev External function for users to create a stake
     * @param amount Amount of WHEAT tokens to stake
     * @param stakingDays Stake duration in days
     */

    function EnterStake(uint amount, uint stakingDays) external {
        require(amount > 0, "Can't be zero wheat");
        require(stakingDays >= 1, "Staking days < 1");
        require(stakingDays <= max_stake_days, "Staking days > max_stake_days");
        require(balanceOf(msg.sender) >= amount, "!userbalance");

        /* On stake WHEAT tokens get burned */
        _burn(msg.sender, amount);

        updateDaily();
        uint stakeId = stakeCounts[msg.sender];
        stakeCounts[msg.sender]++;

        overall_stakedTokens += amount;

        mapMemberStake[msg.sender][stakeId].stakeId = stakeId;
        mapMemberStake[msg.sender][stakeId].userAddress = msg.sender;
        mapMemberStake[msg.sender][stakeId].tokenValue = amount;
        mapMemberStake[msg.sender][stakeId].startDay = currentDay + 1;
        mapMemberStake[msg.sender][stakeId].endDay = currentDay + 1 + stakingDays;
        mapMemberStake[msg.sender][stakeId].collected = false;
        mapMemberStake[msg.sender][stakeId].hasSold = false;
        mapMemberStake[msg.sender][stakeId].hasLoan = false;
        mapMemberStake[msg.sender][stakeId].forSell = false;
        mapMemberStake[msg.sender][stakeId].forLoan = false;
        // stake calcs for days: X >= startDay && X < endDay
        // startDay included / endDay not included

        for (uint i = currentDay + 1; i <= currentDay + stakingDays; i++) {
            totalTokensInActiveStake[i] += amount;
        }

        saveTotalToken += amount;

        emit UserStake(msg.sender, amount, stakingDays, stakeId);
    }

    /**
     * @dev External function for collecting a stake
     * @param stakeId Id of the Stake
     */
    function EndStake(uint stakeId) external nonReentrant {
        DoEndStake(stakeId, false);
    }

    /**
     * @dev Collecting a stake
     * @param stakeId Id of the Stake
     * @param doNotSendDivs do or not do sent the stake's divs to the user (used when re entring the lobby using the stake's divs)
     */
    function DoEndStake(uint stakeId, bool doNotSendDivs) internal {
        require(mapMemberStake[msg.sender][stakeId].endDay <= currentDay, "Locked stake");
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender);
        require(mapMemberStake[msg.sender][stakeId].collected == false);
        require(mapMemberStake[msg.sender][stakeId].hasSold == false);

        updateDaily();

        /* if the stake is for sell, set it false since it's collected */
        mapMemberStake[msg.sender][stakeId].forSell = false;
        mapMemberStake[msg.sender][stakeId].forLoan = false;

        /* clc USDC divs */
        uint profit = calcStakeCollecting(msg.sender, stakeId);
        overall_collectedDivs += profit;

        mapMemberStake[msg.sender][stakeId].collected = true;

        if (doNotSendDivs == false) {
            token_USDC.transfer(address(msg.sender), profit);
        }

        /* if the stake has loan on it automatically pay the lender and finish the loan */
        if (mapMemberStake[msg.sender][stakeId].hasLoan == true) {
            updateFinishedLoan(
                mapRequestingLoans[msg.sender][stakeId].lenderAddress,
                msg.sender,
                mapRequestingLoans[msg.sender][stakeId].lenderLendId,
                stakeId
            );
        }

        uint stakeReturn = mapMemberStake[msg.sender][stakeId].tokenValue;

        /* Pay the bonus token and stake return, if any, to the staker */
        uint bonusAmount;
        if (stakeReturn != 0) {
            bonusAmount = calcBonusToken(mapMemberStake[msg.sender][stakeId].endDay - mapMemberStake[msg.sender][stakeId].startDay, stakeReturn);
            bonusAmount = getNFTRoostingBoostedAmount(bonusAmount);

            overall_collectedBonusTokens += bonusAmount;

            uint endStakeWHEATMintAmount = stakeReturn + bonusAmount;

            _mint(msg.sender, endStakeWHEATMintAmount);

            if (nftMasterChefAddress != address(0) && bonusAmount > 0 && masterchefWHEATShare > 0)
                _mint(nftMasterChefAddress, (bonusAmount * masterchefWHEATShare) /10000);
            if (daoAddress != address(0) && bonusAmount > 0 && daoWHEATShare > 0)
                _mint(daoAddress, (bonusAmount * daoWHEATShare) /10000);
        }

        emit UserStakeCollect(msg.sender, profit, stakeId, bonusAmount);
    }

    /**
     * @dev Calculating a stakes USDC divs payout value by looping through each day of it
     * @param _address User address
     * @param _stakeId Id of the Stake
     */
    function calcStakeCollecting(address _address, uint _stakeId) public view returns (uint) {
        uint userDivs;
        uint _endDay = mapMemberStake[_address][_stakeId].endDay;
        uint _startDay = mapMemberStake[_address][_stakeId].startDay;
        uint _stakeValue = mapMemberStake[_address][_stakeId].tokenValue;

        for (uint _day = _startDay; _day < _endDay && _day < currentDay; _day++) {
            userDivs += (dayUSDCPool[_day] * _stakeValue * 1e6) / totalTokensInActiveStake[_day];
        }

        userDivs /= 1e6;

        return (userDivs - mapMemberStake[_address][_stakeId].loansReturnAmount);
    }

    /**
     * @dev Calculating a stakes Bonus WHEAT tokens based on stake duration and stake amount
     * @param StakeDuration The stake's days
     * @param StakeAmount The stake's WHEAT tokens amount
     */
    function calcBonusToken(uint StakeDuration, uint StakeAmount) public pure returns (uint) {
        require(StakeDuration <= max_stake_days, "Staking days > max_stake_days");

        uint _bonusAmount = (StakeAmount * (StakeDuration**2) * bonus_calc_ratio) / 1e7;
        // 1.5% big payday bonus every 30 days
        _bonusAmount+= (StakeAmount * (StakeDuration/30) * 150) / 1e4;

        return _bonusAmount;
    }

    /**
     * @dev calculating user dividends for a specific day
     */

    uint public devShareOfStakeSellsAndLoanFee;
    uint public totalStakesSold;
    uint public totalTradeAmount;

    /* withdrawable funds for the stake seller address */
    mapping(address => uint) public soldStakeFunds;

    /**
     * @dev User putting up their stake for sell or user changing the previously setted sell price of their stake
     * @param stakeId stake id
     * @param price sell price for the stake
     */
    function sellStakeRequest(uint stakeId, uint price) external {
        updateDaily();

        require(stakeSellingIsPaused == false, "paused");
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender, "!auth");
        require(mapMemberStake[msg.sender][stakeId].hasLoan == false, "Has active loan");
        require(mapMemberStake[msg.sender][stakeId].hasSold == false, "Stake sold");
        require(mapMemberStake[msg.sender][stakeId].endDay > currentDay, "Has ended");

        /* if stake is for loan, remove it from loan requests */
        if (mapMemberStake[msg.sender][stakeId].forLoan == true) {
            cancelStakeLoanRequest(stakeId);
        }

        require(mapMemberStake[msg.sender][stakeId].forLoan == false);

        mapMemberStake[msg.sender][stakeId].forSell = true;
        mapMemberStake[msg.sender][stakeId].price = price;

        emit StakeSellRequest(msg.sender, price, mapMemberStake[msg.sender][stakeId].tokenValue, stakeId);
    }

    function sellStakeCancelRequest(uint stakeId) external {
        updateDaily();

        require(stakeSellingIsPaused == false, "paused");

        cancelSellStakeRequest(stakeId);
    }

    /**
     * @dev A user buying a stake
     * @param sellerAddress stake seller address (current stake owner address)
     * @param stakeId stake id
     */
    function buyStakeRequest(
        address sellerAddress,
        uint stakeId,
        uint amount
    ) external {
        updateDaily();

        require(stakeSellingIsPaused == false, "paused");
        require(mapMemberStake[sellerAddress][stakeId].userAddress != msg.sender, "no self buy");
        require(mapMemberStake[sellerAddress][stakeId].userAddress == sellerAddress, "!auth");
        require(mapMemberStake[sellerAddress][stakeId].hasSold == false, "Stake sold");
        require(mapMemberStake[sellerAddress][stakeId].forSell == true, "!for sell");
        uint priceP = amount;
        require(mapMemberStake[sellerAddress][stakeId].price == priceP, "!funds");
        require(mapMemberStake[sellerAddress][stakeId].endDay > currentDay);

        token_USDC.transferFrom(msg.sender, address(this), amount);

        /* 10% stake sell fee ==> 2% dev share & 8% buy back to the current day's lobby */
        uint pc90 = (mapMemberStake[sellerAddress][stakeId].price * 90) /100;
        uint pc10 = mapMemberStake[sellerAddress][stakeId].price - pc90;
        uint pc2 = pc10 / 5;
        lobbyEntry[currentDay] += pc10 - pc2;
        devShareOfStakeSellsAndLoanFee += pc2;

        /* stake seller gets 90% of the stake's sold price */
        soldStakeFunds[sellerAddress] += pc90;

        /* setting data for the old owner */
        mapMemberStake[sellerAddress][stakeId].hasSold = true;
        mapMemberStake[sellerAddress][stakeId].forSell = false;
        mapMemberStake[sellerAddress][stakeId].collected = true;

        totalStakesSold += 1;
        totalTradeAmount += priceP;

        /* new stake & stake ID for the new stake owner (the stake buyer) */
        uint newStakeId = stakeCounts[msg.sender];
        stakeCounts[msg.sender]++;
        mapMemberStake[msg.sender][newStakeId].userAddress = msg.sender;
        mapMemberStake[msg.sender][newStakeId].tokenValue = mapMemberStake[sellerAddress][stakeId].tokenValue;
        mapMemberStake[msg.sender][newStakeId].startDay = mapMemberStake[sellerAddress][stakeId].startDay;
        mapMemberStake[msg.sender][newStakeId].endDay = mapMemberStake[sellerAddress][stakeId].endDay;
        mapMemberStake[msg.sender][newStakeId].loansReturnAmount = mapMemberStake[sellerAddress][stakeId].loansReturnAmount;
        mapMemberStake[msg.sender][newStakeId].stakeId = newStakeId;
        mapMemberStake[msg.sender][newStakeId].collected = false;
        mapMemberStake[msg.sender][newStakeId].hasSold = false;
        mapMemberStake[msg.sender][newStakeId].hasLoan = false;
        mapMemberStake[msg.sender][newStakeId].forSell = false;
        mapMemberStake[msg.sender][newStakeId].forLoan = false;
        mapMemberStake[msg.sender][newStakeId].price = 0;

        emit StakeBuyRequest(sellerAddress, stakeId, msg.sender, newStakeId, amount);
    }

    /**
     * @dev User asking to withdraw their funds from their sold stake
     */
    function withdrawSoldStakeFunds() external nonReentrant {
        require(soldStakeFunds[msg.sender] > 0, "!funds");

        uint toBeSend = soldStakeFunds[msg.sender];
        soldStakeFunds[msg.sender] = 0;

        token_USDC.transfer(address(msg.sender), toBeSend);

        emit WithdrawSoldStakeFunds(msg.sender, toBeSend);
    }

    struct loanRequest {
        address loanerAddress; // address
        address lenderAddress; // address (sets after loan request accepted by a lender)
        uint stakeId; // id of the stakes that is being loaned on
        uint lenderLendId; // id of the lends that a lender has given out (sets after loan request accepted by a lender)
        uint loanAmount; // requesting loan USDC amount
        uint returnAmount; // requesting loan USDC return amount
        uint duration; // duration of loan (days)
        uint lend_startDay; // lend start day (sets after loan request accepted by a lender)
        uint lend_endDay; // lend end day (sets after loan request accepted by a lender)
        bool hasLoan;
        bool loanIsPaid; // gets true after loan due date is reached and loan is paid
    }

    struct lendInfo {
        address lenderAddress;
        address loanerAddress;
        uint lenderLendId;
        uint loanAmount;
        uint returnAmount;
        uint endDay;
        bool loanIsPaid;
    }

    /* withdrawable funds for the loaner address */
    mapping(address => uint) public LoanedFunds;
    mapping(address => uint) public LendedFunds;

    uint public totalLoanedAmount;
    uint public totalLoanedCount;

    mapping(address => mapping(uint => loanRequest)) public mapRequestingLoans;
    mapping(address => mapping(uint => lendInfo)) public mapLenderInfo;
    mapping(address => uint) public lendersPaidAmount; // total amounts of paid to lender

    /**
     * @dev User submiting a loan request on their stake or changing the previously setted loan request data
     * @param stakeId stake id
     * @param loanAmount amount of requesting USDC loan
     * @param returnAmount amount of USDC loan return
     * @param loanDuration duration of requesting loan
     */
    function getLoanOnStake(
        uint stakeId,
        uint loanAmount,
        uint returnAmount,
        uint loanDuration
    ) external {
        updateDaily();

        require(loaningIsPaused == false, "paused");
        require(loanAmount < returnAmount, "need loanAmount < returnAmount");
        //require(loanDuration >= 4, "lowest loan duration is 4 days");
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender, "!auth");
        require(mapMemberStake[msg.sender][stakeId].hasLoan == false, "Has active loan");
        require(mapMemberStake[msg.sender][stakeId].hasSold == false, "Stake sold");
        require(mapMemberStake[msg.sender][stakeId].endDay > currentDay + loanDuration);

        /* calc stake divs */
        uint stakeDivs = calcStakeCollecting(msg.sender, stakeId);

        /* max amount of possible stake return can not be higher than stake's divs */
        require(returnAmount <= stakeDivs);

        /* if stake is for sell, remove it from sell requests */
        if (mapMemberStake[msg.sender][stakeId].forSell == true) {
            cancelSellStakeRequest(stakeId);
        }

        require(mapMemberStake[msg.sender][stakeId].forSell == false);

        mapMemberStake[msg.sender][stakeId].forLoan = true;

        /* data of the requesting loan */
        mapRequestingLoans[msg.sender][stakeId].loanerAddress = msg.sender;
        mapRequestingLoans[msg.sender][stakeId].stakeId = stakeId;
        mapRequestingLoans[msg.sender][stakeId].loanAmount = loanAmount;
        mapRequestingLoans[msg.sender][stakeId].returnAmount = returnAmount;
        mapRequestingLoans[msg.sender][stakeId].duration = loanDuration;
        mapRequestingLoans[msg.sender][stakeId].loanIsPaid = false;

        emit StakeLoanRequest(msg.sender, loanAmount, returnAmount, loanDuration, stakeId);
    }

    /**
     * @dev Canceling loan request
     * @param stakeId stake id
     */
    function cancelStakeLoanRequest(uint stakeId) public {
        require(mapMemberStake[msg.sender][stakeId].hasLoan == false);
        mapMemberStake[msg.sender][stakeId].forLoan = false;

        emit CancelStakeLoanRequest(msg.sender, stakeId);
    }

    /**
     * @dev User asking to their stake's sell request
     */
    function cancelSellStakeRequest(uint stakeId) internal {
        require(mapMemberStake[msg.sender][stakeId].userAddress == msg.sender);
        require(mapMemberStake[msg.sender][stakeId].forSell == true);
        require(mapMemberStake[msg.sender][stakeId].hasSold == false);

        mapMemberStake[msg.sender][stakeId].forSell = false;

        emit CancelStakeSellRequest(msg.sender, stakeId);
    }

    /**
     * @dev User filling loan request (lending)
     * @param loanerAddress address of loaner aka the person who is requesting for loan
     * @param stakeId stake id
     * @param amount lend amount that is transferred to the contract
     */
    function lendOnStake(
        address loanerAddress,
        uint stakeId,
        uint amount
    ) external nonReentrant {
        updateDaily();

        require(loaningIsPaused == false, "paused");
        require(mapMemberStake[loanerAddress][stakeId].userAddress != msg.sender, "no self lend");
        require(mapMemberStake[loanerAddress][stakeId].hasLoan == false, "Has active loan");
        require(mapMemberStake[loanerAddress][stakeId].forLoan == true, "!requesting a loan");
        require(mapMemberStake[loanerAddress][stakeId].hasSold == false, "Stake is sold");
        require(mapMemberStake[loanerAddress][stakeId].endDay > currentDay, "Stake finished");

        uint loanAmount = mapRequestingLoans[loanerAddress][stakeId].loanAmount;
        uint returnAmount = mapRequestingLoans[loanerAddress][stakeId].returnAmount;
        uint rawAmount = amount;

        require(rawAmount == mapRequestingLoans[loanerAddress][stakeId].loanAmount);

        token_USDC.transferFrom(msg.sender, address(this), amount);

        /* 2% loaning fee, taken from loaner's stake dividends, 1% buybacks to current day's lobby, 1% dev fee */
        uint theLoanFee = (rawAmount * 2) /100;
        devShareOfStakeSellsAndLoanFee += theLoanFee - (theLoanFee /2);
        lobbyEntry[currentDay] += theLoanFee /2;

        mapMemberStake[loanerAddress][stakeId].loansReturnAmount += returnAmount;
        mapMemberStake[loanerAddress][stakeId].hasLoan = true;
        mapMemberStake[loanerAddress][stakeId].forLoan = false;

        uint lenderLendId = clcLenderLendId(msg.sender);

        mapRequestingLoans[loanerAddress][stakeId].hasLoan = true;
        mapRequestingLoans[loanerAddress][stakeId].loanIsPaid = false;
        mapRequestingLoans[loanerAddress][stakeId].lenderAddress = msg.sender;
        mapRequestingLoans[loanerAddress][stakeId].lenderLendId = lenderLendId;
        mapRequestingLoans[loanerAddress][stakeId].lend_startDay = currentDay;
        mapRequestingLoans[loanerAddress][stakeId].lend_endDay = currentDay + mapRequestingLoans[loanerAddress][stakeId].duration;

        mapLenderInfo[msg.sender][lenderLendId].lenderAddress = msg.sender;
        mapLenderInfo[msg.sender][lenderLendId].loanerAddress = loanerAddress;
        mapLenderInfo[msg.sender][lenderLendId].lenderLendId = lenderLendId; // not same with the stake id on "mapRequestingLoans"
        mapLenderInfo[msg.sender][lenderLendId].loanAmount = loanAmount;
        mapLenderInfo[msg.sender][lenderLendId].returnAmount = returnAmount;
        mapLenderInfo[msg.sender][lenderLendId].endDay = mapRequestingLoans[loanerAddress][stakeId].lend_endDay;

        uint resultAmount = rawAmount - theLoanFee;
        LoanedFunds[loanerAddress] += resultAmount;
        LendedFunds[msg.sender] += resultAmount;
        totalLoanedAmount += resultAmount;
        totalLoanedCount += 1;

        emit StakeLend(msg.sender, lenderLendId, loanerAddress, stakeId, rawAmount);
    }

    /**
     * @dev User asking to withdraw their loaned funds
     */
    function withdrawLoanedFunds() external nonReentrant {
        require(LoanedFunds[msg.sender] > 0, "!funds");

        uint toBeSend = LoanedFunds[msg.sender];
        LoanedFunds[msg.sender] = 0;

        token_USDC.transfer(address(msg.sender), toBeSend);

        emit WithdrawLoanedFunds(msg.sender, toBeSend);
    }

    /**
     * @dev returns a unique id for the lend by lopping through the user's lends and counting them
     * @param _address the lender user address
     */
    function clcLenderLendId(address _address) public view returns (uint) {
        uint stakeCount = 0;

        for (uint i = 0; mapLenderInfo[_address][i].lenderAddress == _address; i++) {
            stakeCount += 1;
        }

        return stakeCount;
    }

    /* 
        after a loan's due date is reached there is no automatic way in contract to pay the lender and set the lend data as finished (for the sake of performance and gas)
        so either the lender user calls the "collectLendReturn" function or the loaner user automatically call the  "updateFinishedLoan" function by trying to collect their stake 
    */

    /**
     * @dev Lender requesting to collect their return amount from their finished lend
     * @param stakeId id of a loaner's stake for that the loaner requested a loan and received a lend
     * @param lenderLendId id of the lends that a lender has given out (different from stakeId)
     */
    function collectLendReturn(uint stakeId, uint lenderLendId) external nonReentrant {
        updateFinishedLoan(msg.sender, mapLenderInfo[msg.sender][lenderLendId].loanerAddress, lenderLendId, stakeId);
    }

    /**
     * @dev Checks if the loan on loaner's stake is finished
     * @param lenderAddress lender address
     * @param loanerAddress loaner address
     * @param lenderLendId id of the lends that a lender has given out (different from stakeId)
     * @param stakeId id of a loaner's stake for that the loaner requested a loan and received a lend
     */
    function updateFinishedLoan(
        address lenderAddress,
        address loanerAddress,
        uint lenderLendId,
        uint stakeId
    ) internal {
        updateDaily();

        require(mapMemberStake[loanerAddress][stakeId].hasLoan == true, "Stake has no active loan");
        require(currentDay >= mapRequestingLoans[loanerAddress][stakeId].lend_endDay, "Due date not yet reached");
        require(mapLenderInfo[lenderAddress][lenderLendId].loanIsPaid == false);
        require(mapRequestingLoans[loanerAddress][stakeId].loanIsPaid == false);
        require(mapRequestingLoans[loanerAddress][stakeId].hasLoan == true);
        require(mapRequestingLoans[loanerAddress][stakeId].lenderAddress == lenderAddress);
        require(mapRequestingLoans[loanerAddress][stakeId].lenderLendId == lenderLendId);

        mapMemberStake[loanerAddress][stakeId].hasLoan = false;
        mapLenderInfo[lenderAddress][lenderLendId].loanIsPaid = true;
        mapRequestingLoans[loanerAddress][stakeId].hasLoan = false;
        mapRequestingLoans[loanerAddress][stakeId].loanIsPaid = true;

        uint toBePaid = mapRequestingLoans[loanerAddress][stakeId].returnAmount;
        lendersPaidAmount[lenderAddress] += toBePaid;

        mapRequestingLoans[loanerAddress][stakeId].returnAmount = 0;

        token_USDC.transfer(address(lenderAddress), toBePaid);

        emit StakeLoanFinished(lenderAddress, lenderLendId, loanerAddress, stakeId, toBePaid);
    }

    /* top lottery buyer of the day (so far) */
    uint public lottery_topBuy_today;
    address public lottery_topBuyer_today;

    /* latest top lottery bought amount*/
    uint public lottery_topBuy_latest;

    /* lottery reward pool */
    uint public lottery_Pool;

    /**
     * @dev Runs once a day and checks for lottry winner
     */
    function checkLottery() internal {
        if (lottery_topBuy_today > lottery_topBuy_latest) {
            // we have a winner
            // 50% of the pool goes to the winner

            lottery_topBuy_latest = lottery_topBuy_today;

            if (currentDay >= 7) {
                uint winnerAmount = (lottery_Pool * 50) /100;
                lottery_Pool -= winnerAmount;
                token_USDC.transfer(address(lottery_topBuyer_today), winnerAmount);

                emit LotteryWinner(lottery_topBuyer_today, winnerAmount, lottery_topBuy_latest);
            }
        } else {
            // no winner, reducing the record by 20%
            lottery_topBuy_latest -= (lottery_topBuy_latest * 200) /1000;
        }

        // 2% of lobby entry of each day goes to lottery_Pool
        lottery_Pool += (lobbyEntry[currentDay - 1] * lottery_share_percentage) /10000;

        lottery_topBuyer_today = address(0);
        lottery_topBuy_today = 0;

        emit LotteryUpdate(lottery_Pool, lottery_topBuy_latest);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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