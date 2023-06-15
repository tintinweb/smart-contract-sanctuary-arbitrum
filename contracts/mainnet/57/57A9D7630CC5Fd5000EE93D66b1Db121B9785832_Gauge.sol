// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGauge.sol";
import "./CommunityFactory.sol";
import "./interfaces/ICommunity.sol";
import "./ERC20Helper.sol";
import "./NUTToken.sol";
import "./NutPower.sol";
import "./interfaces/ArbSys.sol";

contract Gauge is IGauge, Ownable, ERC20Helper, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 constant private CONSTANT_10000 = 10000;

    struct User {
        bool hasDeposited;
        uint256 amount; // NP amount
        uint256 nutAvailable;
        uint256 nutDebt;
        uint256 cTokenAvailable;
        uint256 cTokenDebt;
    }

    struct GaugeMeta {
        bool hasCreated;
        address community;
        address factory;
        address cToken;
        uint256 cTokenAcc;
        uint256 cTokenRevenue;
        uint256 lastCTokenRevenue;
        uint256 totalLockedNP;
        mapping (address => User) users;
    }

    // define the NUT distribution to 3 parts
    struct DistributionRatio {
        uint16 community;
        uint16 poolFactory;
        uint16 user;
    }
    
    // Nutbox Power addresss
    address immutable NP;
    // NUT address
    address immutable NUT;
    // Only Nutbox committee can set this. Communities which enabled this function in their pools,
    // part of the cToken rewards(dappToolsRatio / 10000 of total rewards) will be transfered
    // to gauge contract when user harvest their rewards, those rewards and NUTs would be
    // distributed based on the NP locked by user.
    uint16 public gaugeRatio;
    // Total reward nut per block, can be reset by Nutbox DAO
    uint256 public rewardNUTPerBlock;
    // Last nut reward block
    uint256 private lastRewardBlock;

    // nutAcc means how many nut will 1 NP locked earn, it departed by community/poolFactory/user
    uint256 private userNutAcc;
    uint256 private poolFactoryNutAcc;
    uint256 private communityNutAcc;

    uint256 public totalLockedNP;

    // can be rest by Nutbox DAO(Multi-sign contract held by nutbox committee), total of the ratios should be 10000
    DistributionRatio public distributionRatio;

    // communityFactory
    address immutable communityFactory;
    // all created gauges by community owner
    // pool address => gauge
    mapping (address => GaugeMeta) private gauges;

    // reward nut distribute to community and tool dev
    mapping (address => uint256) public communityTotalLockedNP;
    mapping (address => uint256) public poolFactoryTotalLockedNP;
    mapping (address => uint256) private communityAvailable;
    mapping (address => uint256) private poolFactoryAvailable;
    mapping (address => uint256) private communityDebt;
    mapping (address => uint256) private poolFactoryDebt;

    event AdminSetDappGaugeRatio(uint16 indexed gaugeRatio);
    event AdminSetNutRewardPerBlock(uint256 indexed nutRewardPerBlock);
    event AdminSetNutDistributionRatio(uint16 community, uint16 poolFactory, uint16 user);
    event AdminSetRewardNUTPerBlock(uint256 indexed rewardPerBlock);
    event CreateNewGauge(address indexed community, address indexed factory, address indexed pool);
    event UpdateLedger(address indexed community, address indexed factory, address indexed pool, uint256 amount);

    event Voted(address indexed community, address indexed factory, address indexed pool, address user, uint256 amount);
    event Unvoted(address indexed community, address indexed factory, address indexed pool, address user, uint256 amount);

    event CTokenWithdrawn(address indexed pool, address indexed recipient, uint256 amount);
    event UserWithdrewNut(address indexed pool, address indexed recipient, uint256 amount);
    event CommunityWithdrewNut(address indexed community, address indexed recipient, uint256 amount);
    event PoolFactoryWithdrewNut(address indexed poolFactory, address indexed recipient, uint256 amount);

    constructor(address _communityFactory, uint16 _gaugeRatio, DistributionRatio memory ratios, address _NP, address _nut) {
        require(_communityFactory != address(0), "Invalide community factory");
        require(ratios.community + ratios.poolFactory + ratios.user == CONSTANT_10000, "Sum of ratios should be 10000");
        distributionRatio.community = ratios.community;
        distributionRatio.poolFactory = ratios.poolFactory;
        distributionRatio.user = ratios.user;
        communityFactory = _communityFactory;
        gaugeRatio = _gaugeRatio;
        NP = _NP;
        NUT = _nut;
        emit AdminSetDappGaugeRatio(_gaugeRatio);
        emit AdminSetNutDistributionRatio(ratios.community, ratios.poolFactory, ratios.user);
    }

    function hasGaugeEnabled(address pool) external override returns (bool) {
        return gauges[pool].hasCreated;
    }

    // set the ratio of user harvest cToken
    function adminSetGaugeRatio(uint16 _gaugeRatio) external onlyOwner {
        require(_gaugeRatio <= CONSTANT_10000, "Ratio must less or equal than 10000");
        gaugeRatio = _gaugeRatio;
        emit AdminSetDappGaugeRatio(_gaugeRatio);
    }

    function getGaugeRatio() external view override returns (uint16) {
        return gaugeRatio;
    }

    function adminSetRewardNUTPerBlock(uint256 reward) external onlyOwner {
        _updateNutAcc();
        rewardNUTPerBlock = reward;
        emit AdminSetRewardNUTPerBlock(reward);
    }

    function adminSetNutDistributionRatio(DistributionRatio memory ratios) external onlyOwner {
        require(ratios.community + ratios.poolFactory + ratios.user == CONSTANT_10000, "Sum of ratios should be 10000");
        // update accs before reset the ratios
        _updateNutAcc();
        distributionRatio.community = ratios.community;
        distributionRatio.poolFactory = ratios.poolFactory;
        distributionRatio.user = ratios.user;
        emit AdminSetNutDistributionRatio(ratios.community, ratios.poolFactory, ratios.user);
    }

    // only called by community contract, from some user of community call harvestReward
    function updateLedger(address community, address pool, uint256 amount) external override {
        require(CommunityFactory(communityFactory).createdCommunity(community), "Invalid community");
        require(community == msg.sender, "Only called by community");
        require(ICommunity(community).poolActived(pool), "Pool is not exist or closed");
        require(gauges[pool].hasCreated, "Gauge has not added");

        address factory = IPool(pool).getFactory();
        
        gauges[pool].cTokenRevenue = gauges[pool].cTokenRevenue.add(amount);

        emit UpdateLedger(community, factory, pool, amount);
    }

    function addNewGauge(address community, address pool) external {
        require(Ownable(community).owner() == msg.sender, "Only community owner can call");
        require(CommunityFactory(communityFactory).createdCommunity(community), "Invalid community");
        require(ICommunity(community).poolActived(pool), "Pool is not exist or closed");
        require(!gauges[pool].hasCreated, "Gauge has added");

        address cToken = ICommunity(community).getCommunityToken();
        address factory = IPool(pool).getFactory();

        gauges[pool].hasCreated = true;
        gauges[pool].community = community;
        gauges[pool].factory = factory;
        gauges[pool].cToken = cToken;

        emit CreateNewGauge(community, factory, pool);
    }

    function vote(address pool, uint256 amount) external nonReentrant {
        require(gauges[pool].hasCreated, "Gauge not created");
        if (amount == 0) return;
        if (!gauges[pool].users[msg.sender].hasDeposited) {
            gauges[pool].users[msg.sender].hasDeposited = true;
        }

        _updateNutAcc();
        _updatePoolAcc(pool);

        address community = gauges[pool].community;
        address factory = gauges[pool].factory;

        if(gauges[pool].users[msg.sender].amount > 0) {
            // update user's reward include nut and ctoken
            uint256 pendingNut = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12).sub(gauges[pool].users[msg.sender].nutDebt);
            uint256 pendingCToken = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12).sub(gauges[pool].users[msg.sender].cTokenDebt);
            gauges[pool].users[msg.sender].nutAvailable = gauges[pool].users[msg.sender].nutAvailable.add(pendingNut);
            gauges[pool].users[msg.sender].cTokenAvailable = gauges[pool].users[msg.sender].cTokenAvailable.add(pendingCToken);
        }
        if (communityTotalLockedNP[community] > 0) {
            // update community's reward only nut
            uint256 commmunityPending = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12).sub(communityDebt[community]);
            communityAvailable[community] = communityAvailable[community].add(commmunityPending);
        }
        if (poolFactoryTotalLockedNP[factory] > 0) {
            // update tool dev's reward only nut
            uint256 poolFactoryPending = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12).sub(poolFactoryDebt[factory]);
            poolFactoryAvailable[factory] = poolFactoryAvailable[factory].add(poolFactoryPending);
        }

        // using lock method, NP is not transferable
        NutPower(NP).lock(msg.sender, amount);

        // update amount
        gauges[pool].users[msg.sender].amount = gauges[pool].users[msg.sender].amount.add(amount);
        gauges[pool].totalLockedNP = gauges[pool].totalLockedNP.add(amount);
        communityTotalLockedNP[community] = communityTotalLockedNP[community].add(amount);
        poolFactoryTotalLockedNP[factory] = poolFactoryTotalLockedNP[factory].add(amount);
        totalLockedNP = totalLockedNP.add(amount);

        // update debt
        gauges[pool].users[msg.sender].nutDebt = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12);
        gauges[pool].users[msg.sender].cTokenDebt = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12);
        communityDebt[community] = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12);
        poolFactoryDebt[factory] = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12);

        emit Voted(community, factory, pool, msg.sender, amount);
    }

    function unvote(address pool, uint256 amount) external nonReentrant {
        require(gauges[pool].users[msg.sender].hasDeposited, "Caller not a depositor");
        if (amount == 0) return;

        _updateNutAcc();
        _updatePoolAcc(pool);

        address community = gauges[pool].community;
        address factory = gauges[pool].factory;

        amount = gauges[pool].users[msg.sender].amount > amount ? amount : gauges[pool].users[msg.sender].amount;

        if(gauges[pool].users[msg.sender].amount > 0) {
            // update user's reward include nut and ctoken
            uint256 pendingNut = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12).sub(gauges[pool].users[msg.sender].nutDebt);
            uint256 pendingCToken = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12).sub(gauges[pool].users[msg.sender].cTokenDebt);
            gauges[pool].users[msg.sender].nutAvailable = gauges[pool].users[msg.sender].nutAvailable.add(pendingNut);
            gauges[pool].users[msg.sender].cTokenAvailable = gauges[pool].users[msg.sender].cTokenAvailable.add(pendingCToken);
        }
        if (communityTotalLockedNP[community] > 0) {
            // update community's reward only nut
            uint256 commmunityPending = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12).sub(communityDebt[community]);
            communityAvailable[community] = communityAvailable[community].add(commmunityPending);
        }
        if (poolFactoryTotalLockedNP[factory] > 0) {
            // update tool dev's reward only nut
            uint256 poolFactoryPending = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12).sub(poolFactoryDebt[factory]);
            poolFactoryAvailable[factory] = poolFactoryAvailable[factory].add(poolFactoryPending);
        }

        NutPower(NP).unlock(msg.sender, amount);

        // update amount
        gauges[pool].users[msg.sender].amount = gauges[pool].users[msg.sender].amount.sub(amount);
        gauges[pool].totalLockedNP = gauges[pool].totalLockedNP.sub(amount);
        communityTotalLockedNP[community] = communityTotalLockedNP[community].sub(amount);
        poolFactoryTotalLockedNP[factory] = poolFactoryTotalLockedNP[factory].sub(amount);
        totalLockedNP = totalLockedNP.sub(amount);

        // update debt
        gauges[pool].users[msg.sender].nutDebt = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12);
        gauges[pool].users[msg.sender].cTokenDebt = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12);
        communityDebt[community] = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12);
        poolFactoryDebt[factory] = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12);

        emit Unvoted(community, factory, pool, msg.sender, amount);
    }

    function userWithdrawReward(address pool) external nonReentrant {
        require(gauges[pool].users[msg.sender].hasDeposited, "Caller not a depositor");

        _updateNutAcc();
        _updatePoolAcc(pool);

        // calculate reward
        uint256 pendingNut = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12).sub(gauges[pool].users[msg.sender].nutDebt);
        uint256 pendingCToken = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12).sub(gauges[pool].users[msg.sender].cTokenDebt);
        uint256 rewardNut = gauges[pool].users[msg.sender].nutAvailable.add(pendingNut);
        uint256 rewardCToken = gauges[pool].users[msg.sender].cTokenAvailable.add(pendingCToken);

        // transfer reward
        require(NUTToken(NUT).balanceOf(address(this)) >= rewardNut, "Insufficient NUT");
        if (rewardNut > 0) 
            releaseERC20(NUT, msg.sender, rewardNut);
        
        if (rewardCToken > 0)
            releaseERC20(gauges[pool].cToken, msg.sender, rewardCToken);

        // update user data
        gauges[pool].users[msg.sender].nutAvailable = 0;
        gauges[pool].users[msg.sender].cTokenAvailable = 0;
        gauges[pool].users[msg.sender].nutDebt = gauges[pool].users[msg.sender].amount.mul(userNutAcc).div(1e12);
        gauges[pool].users[msg.sender].cTokenDebt = gauges[pool].users[msg.sender].amount.mul(gauges[pool].cTokenAcc).div(1e12);
        
        emit UserWithdrewNut(pool, msg.sender, rewardNut);
        emit CTokenWithdrawn(pool, msg.sender, rewardCToken);
    }

    function communityWithdrawNut(address community) external nonReentrant {
        require(Ownable(community).owner() == msg.sender, "Only community owner can withdraw");
    
        _updateNutAcc();

        // calculate reward
        uint256 pendingNut = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12).sub(communityDebt[community]);
        uint256 rewardNut = communityAvailable[community].add(pendingNut);

        // transfer nut
        require(NUTToken(NUT).balanceOf(address(this)) >= rewardNut, "Insufficient NUT");
        if (rewardNut > 0) 
            releaseERC20(NUT, msg.sender, rewardNut);

        //update community data
        communityAvailable[community] = 0;
        communityDebt[community] = communityTotalLockedNP[community].mul(communityNutAcc).div(1e12);

        emit CommunityWithdrewNut(community, msg.sender, rewardNut); 
    }

    function poolFactoryWithdrawNut(address factory) external nonReentrant {
        require(Ownable(factory).owner() == msg.sender, "Only poolFactory owner can withdraw");
    
        _updateNutAcc();

        // calculate reward
        uint256 pendingNut = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12).sub(poolFactoryDebt[factory]);
        uint256 rewardNut = poolFactoryAvailable[factory].add(pendingNut);

        // transfer nut
        require(NUTToken(NUT).balanceOf(address(this)) >= rewardNut, "Insufficient NUT");
        if (rewardNut > 0) 
            releaseERC20(NUT, msg.sender, rewardNut);

        //update poolFactory data
        poolFactoryAvailable[factory] = 0;
        poolFactoryDebt[factory] = poolFactoryTotalLockedNP[factory].mul(poolFactoryNutAcc).div(1e12);

        emit PoolFactoryWithdrewNut(factory, msg.sender, rewardNut); 
    }

    function getUserPendingReward(address pool, address user) external view 
        returns (uint256 rewardNut, uint256  rewardCToken) 
    {
        if (!gauges[pool].users[user].hasDeposited) {
            rewardNut = 0;
            rewardCToken = 0;
        }else {
            if (totalLockedNP == 0)
                rewardNut = gauges[pool].users[user].nutAvailable;
            else {
                (,,uint256 _userNutAcc) = _cuclateNutAcc();
                rewardNut = gauges[pool].users[user].amount.mul(_userNutAcc).div(1e12).sub(gauges[pool].users[user].nutDebt).add(gauges[pool].users[user].nutAvailable);
            }

            if (gauges[pool].totalLockedNP == 0) 
                rewardCToken = gauges[pool].users[user].cTokenAvailable;
            else {
                uint256 _cTokenAcc = gauges[pool].cTokenAcc.add(gauges[pool].cTokenRevenue.sub(gauges[pool].lastCTokenRevenue).mul(1e12).div(gauges[pool].totalLockedNP));
                rewardCToken = gauges[pool].users[user].amount.mul(_cTokenAcc).div(1e12).sub(gauges[pool].users[user].cTokenDebt).add(gauges[pool].users[user].cTokenAvailable);
            }
        }
    }

    function getUserLocked(address pool, address user) external view returns (uint256 locked) {
        if (!gauges[pool].users[user].hasDeposited) {
            locked = 0;
        }else {
            locked = gauges[pool].users[user].amount;
        }
    }

    function getLockedNpInGauge(address pool) external view returns (uint256 totalLocked) {
        totalLocked = gauges[pool].totalLockedNP;
    }

    function getCommunityPendingRewardNut(address community) external view
        returns (uint256 rewardNut)
    {
        uint256 communityLockedNP = communityTotalLockedNP[community];
        if (communityLockedNP == 0)
            rewardNut = communityAvailable[community];
        else {
            (uint256 _communityNutAcc,,) = _cuclateNutAcc();
            rewardNut = communityLockedNP.mul(_communityNutAcc).div(1e12).sub(communityDebt[community]).add(communityAvailable[community]);
        }
    }

    function getPoolFactoryPendingRewardNut(address factory) external view
        returns (uint256 rewardNut) 
    {
        uint256 poolFactoryLockedNP = poolFactoryTotalLockedNP[factory];
        if (poolFactoryLockedNP == 0)
            rewardNut = poolFactoryAvailable[factory];
        else {
            (,uint256 _poolFactoryAcc,) = _cuclateNutAcc();
            rewardNut = poolFactoryLockedNP.mul(_poolFactoryAcc).div(1e12).sub(poolFactoryDebt[factory]).add(poolFactoryAvailable[factory]);
        }
    }

    function _updateNutAcc() private {
        // start game when the first operation
        if (0 == lastRewardBlock) {
            lastRewardBlock = blockNum();
        }

        if (blockNum() <= lastRewardBlock) return;

        (communityNutAcc, poolFactoryNutAcc, userNutAcc) = _cuclateNutAcc();

        lastRewardBlock = blockNum();
    }

    function _updatePoolAcc(address pool) private {
        if (!gauges[pool].hasCreated) return;
        if (gauges[pool].lastCTokenRevenue == 0) 
            gauges[pool].lastCTokenRevenue = gauges[pool].cTokenRevenue;
        
        if (gauges[pool].lastCTokenRevenue == gauges[pool].cTokenRevenue) return;

        gauges[pool].cTokenAcc = gauges[pool].cTokenAcc.add(gauges[pool].cTokenRevenue.sub(gauges[pool].lastCTokenRevenue).mul(1e12).div(gauges[pool].totalLockedNP));

        gauges[pool].lastCTokenRevenue = gauges[pool].cTokenRevenue;
    }

    function _cuclateNutAcc() private view returns (uint256 _communityNutAcc, uint256 _poolFactoryNutAcc, uint256 _userNutAcc) {
        if (totalLockedNP == 0) {
            _communityNutAcc = communityNutAcc;
            _poolFactoryNutAcc = poolFactoryNutAcc;
            _userNutAcc = userNutAcc;
        }else {
            (uint256 communityReadyToMint, uint256 poolFactoryReadyToMint, uint256 userReadyToMint) = _calculateNutReadyToMint();
            _communityNutAcc = communityNutAcc.add(communityReadyToMint.mul(1e12).div(totalLockedNP));
            _poolFactoryNutAcc = poolFactoryNutAcc.add(poolFactoryReadyToMint.mul(1e12).div(totalLockedNP));
            _userNutAcc = userNutAcc.add(userReadyToMint.mul(1e12).div(totalLockedNP));
        }
    }

    function _calculateNutReadyToMint() private view returns (uint256 communityReadyToMint, uint256 poolFactoryReadyToMint, uint256 userReadyToMint) {
        uint256 readyToMint = (blockNum() - lastRewardBlock).mul(rewardNUTPerBlock);
        communityReadyToMint = readyToMint.mul(distributionRatio.community).div(CONSTANT_10000);
        poolFactoryReadyToMint = readyToMint.mul(distributionRatio.poolFactory).div(CONSTANT_10000);
        userReadyToMint = readyToMint.mul(distributionRatio.user).div(CONSTANT_10000);
    }

    function blockNum() public view returns (uint256) {
        return ArbSys(address(100)).arbBlockNumber();
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the pool factory.
 */
interface IPoolFactory {
    function createPool(address community, string memory name, bytes calldata meta)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the staking pool.
 */
interface IPool {
    function getFactory() external view returns (address);

    function getCommunity() external view returns (address);

    function getUserStakedAmount(address user) external view returns (uint256);

    function getTotalStakedAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IGauge {
    function updateLedger(address community, address pool, uint256 amount) external;
    function getGaugeRatio() external view returns (uint16);
    function hasGaugeEnabled(address pool) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the community token factory.
 */
interface ICommunityTokenFactory {

    function createCommunityToken(bytes calldata meta)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the staking pool.
 * All write functions should have whilist ensured
 */
interface ICommunity {
    function poolActived(address pool) external view returns (bool);

    function getShareAcc(address pool) external view returns (uint256);

    function getCommunityToken() external view returns (address);

    function getUserDebt(address pool, address user)
        external
        view
        returns (uint256);

    function appendUserReward(
        address user,
        uint256 amount
    ) external;

    function setUserDebt(
        address user,
        uint256 debt
    ) external;

    function updatePools(string memory feeType, address feePayer) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the committee.
 */
interface ICommittee {
    function setFeePayer(address payer) external;

    function getFee(string memory feeType) external view returns (uint256);

    function getNut() external view returns (address);

    function getTreasury() external view returns (address);

    function getGauge() external view returns (address);

    function updateLedger(
        string memory feeType,
        address community,
        address pool,
        address who
    ) external;

    function getRevenue(string memory feeType) external view returns (uint256);

    function verifyContract(address factory) external view returns (bool);

    function getFeeFree(address freeAddress) external view returns (bool);

    function getPoolFees(address pool) 
            external 
            view 
            returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the reward calculator.
 */
interface ICalculator {
    function calculateReward(
        address staking,
        uint256 from,
        uint256 to
    ) external view returns (uint256);

    function setDistributionEra(address staking, bytes calldata policy)
        external
        returns (bool);

    function getCurrentRewardPerBlock(address staking)
        external
        returns (uint256);

    function getStartBlock(address staking)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /**
    * @notice Send a transaction to L1
    * @param destination recipient address on L1
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);



    /**
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**
    * @notice get the value of target L2 storage slot
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract MintableERC20 is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the
     * community factory contract,
     * then community factory will grant mint role to the community.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, 
    string memory symbol, 
    uint256 initialSupply,
    address owner,
    address communityFactory) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, communityFactory);
        _mint(owner, initialSupply);
    }
    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NutPower is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant public WEEK = 604800;
    uint256 constant public PERIOD_COUNT = 7;

    enum Period {
        W1,
        W2,
        W4,
        W8,
        W16,
        W32,
        W64
    }

    struct RedeemRequest {
        uint256 nutAmount;
        uint256 claimed;
        uint256 startTime;
        uint256 endTime;
    }

    struct RequestsOfPeriod {
        uint256 index;
        RedeemRequest[] queue;
    }

    struct PowerInfo {
        // Amount of NP can be power down
        uint256 free;
        // Amount of NP has been locked, e.g. staked
        uint256 locked;
    }

    address public nut;
    // total locked nut
    uint256 public totalLockedNut;
    // total NP
    uint256 public totalSupply;

    mapping (address => PowerInfo) private powers;
    mapping (address => mapping (Period => uint256)) private depositInfos;
    uint256[7] private multipier = [1, 2, 4, 8, 16, 32, 64];
    mapping (address => mapping (Period => RequestsOfPeriod)) private requests;
    mapping (address => bool) public whitelists;

    event AdminChangeNut(address indexed oldNut, address indexed newNut);
    event AdminSetWhiteList(address indexed who, bool tag);

    event PowerUp(address indexed who, Period period, uint256 amount);
    event PowerDown(address indexed who, Period period, uint256 amount);
    event Upgrade(address indexed who, Period src, Period dest, uint256 amount);
    event Redeemd(address indexed who, uint256 amount);

    modifier onlyWhitelist {
        require(whitelists[msg.sender], "Address is not whitelisted");
        _;
    }

    constructor(address _nut) {
        require(_nut != address(0), "Invalid nut address");
        nut = _nut;
    }

    function adminSetNut(address _nut) external onlyOwner {
        require(_nut != address(0), "Invalid nut address");
        address oldNut = nut;
        nut = _nut;
        emit AdminChangeNut(oldNut, nut);
    }

    function adminSetWhitelist(address _who, bool _tag) external onlyOwner {
        require(_who != address(0), "Invalide address");
        whitelists[_who] = _tag;
        emit AdminSetWhiteList(_who, _tag);
    }

    function powerUp(uint256 _nutAmount, Period _period) external nonReentrant {
        require(_nutAmount > 0, "Invalid lock amount");
        IERC20(nut).transferFrom(msg.sender, address(this), _nutAmount);
        uint256 issuedNp = _nutAmount.mul(multipier[uint256(_period)]);
        // NUT is locked
        totalLockedNut = totalLockedNut.add(_nutAmount);
        totalSupply = totalSupply.add(issuedNp);
        powers[msg.sender].free = powers[msg.sender].free.add(issuedNp);
        depositInfos[msg.sender][_period] = depositInfos[msg.sender][_period].add(_nutAmount);

        emit PowerUp(msg.sender, _period, _nutAmount);
    }

    function powerDown(uint256 _npAmount, Period _period) external nonReentrant {
        uint256 downNut = _npAmount.div(multipier[uint256(_period)]);
        require(_npAmount > 0, "Invalid unlock NP");
        require(depositInfos[msg.sender][_period] >= downNut, "Insufficient free NUT");
        require(powers[msg.sender].free >= _npAmount, "Insufficient free NP");

        powers[msg.sender].free = powers[msg.sender].free.sub(_npAmount);
        depositInfos[msg.sender][_period] = depositInfos[msg.sender][_period].sub(downNut);
        // Add to redeem request queue
        requests[msg.sender][_period].queue.push(RedeemRequest ({
            nutAmount: downNut,
            claimed: 0,
            startTime: block.timestamp,
            endTime: block.timestamp.add(WEEK.mul(multipier[uint256(_period)]))
        }));
        totalLockedNut = totalLockedNut.sub(downNut);
        totalSupply = totalSupply.sub(_npAmount);
        emit PowerDown(msg.sender, _period, _npAmount);
    }

    function upgrade(uint256 _nutAmount, Period _src, Period _dest) external nonReentrant {
        uint256 srcLockedAmount = depositInfos[msg.sender][_src];
        require(_nutAmount > 0 && srcLockedAmount >= _nutAmount, "Invalid upgrade amount");
        require(uint256(_src) < uint256(_dest), 'Invalid period');

        depositInfos[msg.sender][_src] = depositInfos[msg.sender][_src].sub(_nutAmount);
        depositInfos[msg.sender][_dest] = depositInfos[msg.sender][_dest].add(_nutAmount);
        uint256 issuedNp = _nutAmount.mul(
                multipier[uint256(_dest)].sub(multipier[uint256(_src)])
            );
        powers[msg.sender].free = powers[msg.sender].free.add(issuedNp);
        totalSupply = totalSupply.add(issuedNp);

        emit Upgrade(msg.sender, _src, _dest, _nutAmount);
    }

    function redeem() external nonReentrant {
        uint256 avaliableRedeemNut = 0;
        for (uint256 period = 0; period < PERIOD_COUNT; period++) {
            for (uint256 idx = requests[msg.sender][Period(period)].index; idx < requests[msg.sender][Period(period)].queue.length; idx++) {
                uint256 claimable = _claimableNutOfRequest(requests[msg.sender][Period(period)].queue[idx]);
                requests[msg.sender][Period(period)].queue[idx].claimed = requests[msg.sender][Period(period)].queue[idx].claimed.add(claimable);
                // Ignore requests that has already claimed completely next time.
                if (requests[msg.sender][Period(period)].queue[idx].claimed == requests[msg.sender][Period(period)].queue[idx].nutAmount) {
                    requests[msg.sender][Period(period)].index = idx + 1;
                }

                if (claimable > 0) {
                    avaliableRedeemNut = avaliableRedeemNut.add(claimable);
                }
            }
        }

        require(IERC20(nut).balanceOf(address(this)) >= avaliableRedeemNut, "Inceficient balance of NUT");
        IERC20(nut).transfer(msg.sender, avaliableRedeemNut);
        emit Redeemd(msg.sender, avaliableRedeemNut);
    }

    function lock(address _who, uint256 _npAmount) external onlyWhitelist {
        require(powers[_who].free >= _npAmount, "Inceficient power to lock");
        powers[_who].free = powers[_who].free.sub(_npAmount);
        powers[_who].locked = powers[_who].locked.add(_npAmount);
    }

    function unlock(address _who, uint256 _npAmount) external onlyWhitelist {
        require(powers[_who].locked >= _npAmount, "Inceficient power to unlock");
        powers[_who].free = powers[_who].free.add(_npAmount);
        powers[_who].locked = powers[_who].locked.sub(_npAmount);
    }

    function name() external pure returns (string memory)  {
        return "Nut Power";
    }

    function symbol() external pure returns (string memory) {
        return "NP";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) external view returns (PowerInfo memory) {
        return powers[account];
    }

    function redeemRequestCountOfPeriod(address _who, Period _period) external view returns (uint256 len) {
        len = requests[_who][_period].queue.length - requests[_who][_period].index;
    }

    function redeemRequestsOfPeriod(address _who, Period _period) external view returns (RedeemRequest[] memory reqs) {
        reqs = new RedeemRequest[](this.redeemRequestCountOfPeriod(_who, _period));
        for (uint i = requests[_who][_period].index; i < requests[_who][_period].queue.length; i++) {
            RedeemRequest storage req = requests[_who][_period].queue[i];
            reqs[i] = req;
        }
    }

    function firstRedeemRequest(address _who, Period _period) external view returns (RedeemRequest memory req) {
        if (requests[_who][_period].queue.length > 0) {
            req = requests[_who][_period].queue[requests[_who][_period].index];
        }
    }

    function lastRedeemRequest(address _who, Period _period) external view returns (RedeemRequest memory req) {
        if (requests[_who][_period].queue.length > 0) {
            req = requests[_who][_period].queue[requests[_who][_period].queue.length - 1];
        }
    }

    function claimableNut(address _who) external view returns (uint256 amount) {
        for (uint256 period = 0; period < PERIOD_COUNT; period++) {
            for (uint256 idx = requests[_who][Period(period)].index; idx < requests[_who][Period(period)].queue.length; idx++) {
                amount = amount.add(_claimableNutOfRequest(requests[_who][Period(period)].queue[idx]));
            }
        }
    }

    function lockedNutOfPeriod(address _who, Period _period) external view returns (uint256) {
        return depositInfos[_who][_period];
    }

    function _claimableNutOfRequest(RedeemRequest memory _req) private view returns (uint256 amount) {
        if (block.timestamp >= _req.endTime) {
            amount = _req.nutAmount.sub(_req.claimed);
        } else {
            amount = _req.nutAmount
                    .mul(block.timestamp.sub(_req.startTime))
                    .div(_req.endTime.sub(_req.startTime))
                    .sub(_req.claimed);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NUTToken is Ownable, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // address => hasWhitelisted
    mapping (address => bool) public whiteList;
    bool public transferOpened;

    event SetWhiteList(address indexed contractAddress);
    event RemoveWhiteList(address indexed contractAddress);
    event EnableTransfer();
    event DisableTransfer();

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name, 
        string memory symbol, 
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        require(owner != address(0), "Receive address cant be 0");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _mint(owner, initialSupply);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    function setWhiteList(address _contract) external onlyOwner {
        require(_contract != address(0), 'Invalid contract address');
        whiteList[_contract] = true;
        emit SetWhiteList(_contract);
    }

    function removeWhiteList(address _contract) external onlyOwner {
        require(_contract != address(0), 'Invalid contract address');
        whiteList[_contract] = false;
        emit RemoveWhiteList(_contract);
    }

    function enableTransfer() external onlyOwner {
        transferOpened = true;
        emit EnableTransfer();
    }

    function disableTransfer() external onlyOwner {
        transferOpened = false;
        emit DisableTransfer();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        // before NUT enable transfer to public, only owner can make  transfer(for airdrop),
        // other NUT holders can only transfer to whitlisted recipient(join staking etc.)
        if (!transferOpened && msg.sender != owner())
            require(whiteList[recipient] || whiteList[sender], 'Permission denied: sender or recipient is not white list');
        super._transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
    @title Helper of ERC20 assets.
 */
contract ERC20Helper {
    using SafeMath for uint256;

    /**
        @notice Used to gain custody of deposited token.
        @param tokenAddress Address of ERC20 to transfer.
        @param owner Address of current token owner.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function lockERC20(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 amount
    ) internal {
        IERC20 erc20 = IERC20(tokenAddress);
        _safeTransferFrom(erc20, owner, recipient, amount);
    }

    /**
        @notice Transfers custody of token to recipient.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function releaseERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) internal {
        IERC20 erc20 = IERC20(tokenAddress);
        _safeTransfer(erc20, recipient, amount);
    }

    /**
        @notice Used to create new ERC20s.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to mint token to.
        @param amount Amount of token to mint.
     */
    function mintERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) internal {
        ERC20PresetMinterPauser erc20 = ERC20PresetMinterPauser(tokenAddress);
        erc20.mint(recipient, amount);
    }

    /**
        @notice Used to burn ERC20s.
        @param tokenAddress Address of ERC20 to burn.
        @param owner Current owner of tokens.
        @param amount Amount of tokens to burn.
     */
    function burnERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) internal {
        ERC20Burnable erc20 = ERC20Burnable(tokenAddress);
        erc20.burnFrom(owner, amount);
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) private {
        _safeCall(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param from Address to transfer token from
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) private {
        _safeCall(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
        @notice used to make calls to ERC20s safely
        @param token Token instance call targets
        @param data encoded call data
     */
    function _safeCall(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "ERC20: call failed");

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "ERC20: operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './Community.sol';
import './interfaces/ICalculator.sol';
import './interfaces/ICommittee.sol';
import "./interfaces/ICommunityTokenFactory.sol";
import "./ERC20Helper.sol";
import "./community-token/MintableERC20.sol";

/**
 * @dev Factory contract to create an StakingTemplate entity
 *
 * This is the entry contract that user start to create their own staking economy.
 */
contract CommunityFactory is ERC20Helper {

    address immutable committee;
    mapping (address => bool) public createdCommunity;

    event CommunityCreated(address indexed creator, address indexed community, address communityToken);

    constructor(address _committee) {
        require(_committee != address(0), "Invalid committee");
        committee = _committee;
    }

    // If communityToken == address(0), we would create a mintable token for cummunity by token factory,
    // thus caller should give arguments bytes
    function createCommunity (
        bool isMintable,
        address communityToken,
        address communityTokenFactory,
        bytes calldata tokenMeta,
        address rewardCalculator,
        bytes calldata distributionPolicy
    ) external {
        require(ICommittee(committee).verifyContract(rewardCalculator), 'UC'); // Unsupported calculator

        // we would create a new mintable token for community
        bool needGrantRole = false;
        if (communityToken == address(0)){
            needGrantRole = true;
            isMintable = true;
            require(ICommittee(committee).verifyContract(communityTokenFactory), 'UTC'); // Unsupported token factory
            communityToken = ICommunityTokenFactory(communityTokenFactory).createCommunityToken(tokenMeta);
        }

        Community community = new Community(msg.sender, committee, communityToken, rewardCalculator, isMintable);
       
        if (needGrantRole){
            // Token deployed by walnut need to grant mint role from community factory to sepecify community.
            MintableERC20(communityToken).grantRole(MintableERC20(communityToken).MINTER_ROLE(), address(community));
            // Token provided by user need user to grant mint role to community
            // if user set isMintable to true,
            // this action will be executed after this method completed.
        }

        if(ICommittee(committee).getFee('COMMUNITY') > 0){
            require(ERC20(ICommittee(committee).getNut()).allowance(msg.sender, address(this)) >= ICommittee(committee).getFee('COMMUNITY'), "need");
            lockERC20(ICommittee(committee).getNut(), msg.sender, ICommittee(committee).getTreasury(), ICommittee(committee).getFee('COMMUNITY'));
            ICommittee(committee).updateLedger('COMMUNITY', address(community), address(0), msg.sender);
        }

        // set staking feast rewarad distribution distributionPolicy
        ICalculator(rewardCalculator).setDistributionEra(address(community), distributionPolicy);

        // add community to fee payment whitelist
        ICommittee(committee).setFeePayer(address(community));

        createdCommunity[address(community)] = true;

        emit CommunityCreated(msg.sender, address(community), communityToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ICalculator.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/ICommittee.sol";
import "./interfaces/IGauge.sol";
import "./ERC20Helper.sol";
import "./interfaces/ArbSys.sol";

/**
 * @dev Template contract of Nutbox staking based communnity.
 *
 * Community Contract always returns an entity of this contract.
 * Support add serial staking pool into it.
 */
contract Community is ICommunity, ERC20Helper, Ownable {

    using SafeMath for uint256;
    using SafeMath for uint16;

    uint16 constant CONSTANTS_10000 = 10000;

    address immutable committee;
    // DAO fund ratio
    uint16 public feeRatio;
    // DAO fund address
    address private devFund;
    // Revenue can be withdrawn by community so far
    uint256 private retainedRevenue; 
    // pool => hasOpened
    mapping(address => bool) private openedPools;
    // pool => shareAcc
    mapping(address => uint256) private poolAcc;
    // pool => user => amount
    mapping(address => mapping(address => uint256)) private userRewards;
    // pool => user => amount
    mapping(address => mapping(address => uint256)) private userDebts;
    // pool => canUpdate, all added pools
    mapping(address => bool) private whitelists;
    // pool => ratios
    mapping(address => uint16) private poolRatios;
    // actived pools right now
    address[] public activedPools;
    // all created pools include closed pools
    address[] public createdPools;
    uint256 private lastRewardBlock;
    address immutable communityToken;
    bool immutable public isMintableCommunityToken;
    address immutable public rewardCalculator;

    // events triggered by community admin
    event AdminSetFeeRatio(uint16 ratio);
    event AdminClosePool(address indexed pool);
    event AdminSetPoolRatio(address[] pools, uint16[] ratios);
    // events triggered by user
    event WithdrawRewards(address[] pool, address indexed who, uint256 amount);
    // when user update pool, there may be some fee charge to owner's account
    event PoolUpdated(address indexed who, uint256 amount);
    event DevChanged(address indexed oldDev, address indexed newDev);
    event RevenueWithdrawn(address indexed devFund, uint256 amount);

    modifier onlyPool {
        require(whitelists[msg.sender], 'PNIW'); // Pool is not in white list
        _;
    }

    constructor(address _admin, address _committee, address _communityToken, address _rewardCalculator, bool _isMintableCommunityToken) {
        transferOwnership(_admin);
        devFund = _admin;
        committee = _committee;
        communityToken = _communityToken;
        rewardCalculator = _rewardCalculator;
        isMintableCommunityToken = _isMintableCommunityToken;
        emit DevChanged(address(0), _admin);
    }
    
    function adminSetDev(address _dev) external onlyOwner {
        require(_dev != address(0), "IA"); // Invalid address
        emit DevChanged(devFund, _dev);
        devFund = _dev;
    }
    
    function adminWithdrawRevenue() external onlyOwner {
        require(retainedRevenue > 0);
        uint256 harvestAmount = retainedRevenue;
        if (!isMintableCommunityToken){
            uint256 balance = ERC20(communityToken).balanceOf(address(this));
            harvestAmount = balance < retainedRevenue ? balance : retainedRevenue;
        }
        _unlockOrMintAsset(devFund, harvestAmount);
        retainedRevenue = retainedRevenue.sub(harvestAmount);

        emit RevenueWithdrawn(devFund, harvestAmount);
    }
    
    function adminSetFeeRatio(uint16 _ratio) external onlyOwner {
        require(_ratio <= CONSTANTS_10000, 'PR>1w');//Pool ratio exceeds 10000

        _updatePoolsWithFee("COMMUNITY", owner(), address(0));
        
        feeRatio = _ratio;
        emit AdminSetFeeRatio(_ratio);
    }
    
    function adminWithdrawReward(uint256 amount) external onlyOwner {
        releaseERC20(communityToken, msg.sender, amount);
    }
    
    function adminAddPool(string memory poolName, uint16[] memory ratios, address poolFactory, bytes calldata meta) external onlyOwner {
        require((activedPools.length + 1) == ratios.length, 'WPC');//Wrong Pool ratio count
        require(ICommittee(committee).verifyContract(poolFactory), 'UPF');//Unsupported pool factory
        _checkRatioSum(ratios);

        // create pool imstance
        address pool = IPoolFactory(poolFactory).createPool(address(this), poolName, meta);
        _updatePoolsWithFee("COMMUNITY", owner(), pool);
        openedPools[pool] = true;
        whitelists[pool] = true;
        poolAcc[pool] = 0;
        activedPools.push(pool);
        createdPools.push(pool);
        _updatePoolRatios(ratios);
    }
    
    function adminClosePool(address poolAddress, address[] memory _activedPools, uint16[] memory ratios) external onlyOwner {
        require(openedPools[poolAddress], 'PIA');// Pool is already inactived
        require(_activedPools.length == activedPools.length - 1, "WAPL");//Wrong activedPools length
        require(_activedPools.length == ratios.length, 'LDM');//Length of pools and ratios dismatch
        // check received actived pools array right
        for (uint256 i = 0; i < _activedPools.length; i ++) {
            require(openedPools[_activedPools[i]], "WP"); // Wrong active pool address
        }
        _checkRatioSum(ratios);

        _updatePoolsWithFee("COMMUNITY", owner(), poolAddress);

        // mark as inactived
        openedPools[poolAddress] = false;
        activedPools = _activedPools;
        _updatePoolRatios(ratios);

        emit AdminClosePool(poolAddress);
    }
    
    function adminSetPoolRatios(uint16[] memory ratios) external onlyOwner {
        require(activedPools.length == ratios.length, 'WL');//Wrong ratio list length
        _checkRatioSum(ratios);

        _updatePoolsWithFee("COMMUNITY", owner(), address(0));

        _updatePoolRatios(ratios);
    }

    /**
     * @dev This function would withdraw all rewards that exist in all pools which available for user
     * This function will not only travel actived pools, but also closed pools
     */
    function withdrawPoolsRewards(address[] memory poolAddresses) external {
        // game has not started
        if (lastRewardBlock == 0) return;
        require(poolAddresses.length > 0, "MHO1"); // Must harvest at least one pool

        // There are new blocks created after last updating, so update pools before withdraw
        if(blockNum() > lastRewardBlock) {
            _updatePoolsWithFee("USER", msg.sender, poolAddresses[0]);
        }

        uint256 totalAvailableRewards = 0;
        uint256 amountTransferToGauge = 0;
        address gauge = ICommittee(committee).getGauge();
        for (uint8 i = 0; i < poolAddresses.length; i++) {
            address poolAddress = poolAddresses[i];
            require(whitelists[poolAddress], "IP"); // Illegal pool
            uint256 stakedAmount = IPool(poolAddress).getUserStakedAmount(msg.sender);

            uint256 pending = stakedAmount.mul(poolAcc[poolAddress]).div(1e12).sub(userDebts[poolAddress][msg.sender]);
            uint256 pendingRewardsToGauge = 0;
            // if this pool's gauge enabled, calculate the reward and transfer c-token to gauge
            if (gauge != address(0) && IGauge(gauge).hasGaugeEnabled(poolAddress)) {
                uint16 ratio = IGauge(gauge).getGaugeRatio();
                if (ratio > 0) {
                    pendingRewardsToGauge = pending.mul(ratio).div(CONSTANTS_10000);
                    pending = pending.sub(amountTransferToGauge);
                }
            }

            if (pendingRewardsToGauge > 0){
                IGauge(gauge).updateLedger(address(this), poolAddress, pendingRewardsToGauge);
                amountTransferToGauge = amountTransferToGauge.add(pendingRewardsToGauge);
            }

            if(pending > 0) {
                userRewards[poolAddress][msg.sender] = userRewards[poolAddress][msg.sender].add(pending);
            }
            // add all pools available rewards
            totalAvailableRewards = totalAvailableRewards.add(userRewards[poolAddress][msg.sender]);
            userDebts[poolAddress][msg.sender] = stakedAmount.mul(poolAcc[poolAddress]).div(1e12);
            userRewards[poolAddress][msg.sender] = 0;
        }

        if (amountTransferToGauge > 0) {
            _unlockOrMintAsset(gauge, amountTransferToGauge);
        }
        // transfer rewards to user
        _unlockOrMintAsset(msg.sender, totalAvailableRewards);
        emit WithdrawRewards(poolAddresses, msg.sender, totalAvailableRewards);
    }

    function getPoolPendingRewards(address poolAddress, address user) public view returns(uint256) {
        // game has not started
        if (lastRewardBlock == 0) return 0;

        uint256 rewardsReadyToMintedToPools = ICalculator(rewardCalculator).calculateReward(address(this), lastRewardBlock + 1, blockNum()).mul(10000 - feeRatio).div(10000);
        // our lastRewardBlock isn't up to date, as the result, the availableRewards isn't
        // the right amount that delegator can award
        uint256 stakedAmount = IPool(poolAddress).getUserStakedAmount(user);
        if (stakedAmount == 0) return userRewards[poolAddress][user];
        uint256 totalStakedAmount = IPool(poolAddress).getTotalStakedAmount();
        uint256 _shareAcc = poolAcc[poolAddress].add(rewardsReadyToMintedToPools.mul(poolRatios[poolAddress]).mul(1e8).div(totalStakedAmount));
        uint256 pending = stakedAmount.mul(_shareAcc).div(1e12).sub(userDebts[poolAddress][user]);
        return userRewards[poolAddress][user].add(pending);
    }

    function getTotalPendingRewards(address user) external view returns(uint256) {
        uint256 rewards = 0;
        for (uint16 i = 0; i < createdPools.length; i++) {
            rewards = rewards.add(getPoolPendingRewards(createdPools[i], user));
        }
        return rewards;
    }

    function poolActived(address pool) external view override returns(bool) {
        return openedPools[pool];
    }

    function getShareAcc(address pool) external view override returns (uint256) {
        return poolAcc[pool];
    }

    function getCommunityToken() external view override returns (address) {
        return communityToken;
    }

    function getUserDebt(address pool, address user)
        external
        view
        override returns (uint256) {
        return userDebts[pool][user];
    }

    // Pool callable only
    function appendUserReward(address user, uint256 amount) external override onlyPool {
        userRewards[msg.sender][user] = userRewards[msg.sender][user].add(amount);
    }

    // Pool callable only
    function setUserDebt(address user, uint256 debt) external override onlyPool {
        userDebts[msg.sender][user] = debt;
    }

    // Pool callable only
    function updatePools(string memory feeType, address feePayer) external override onlyPool {
        _updatePoolsWithFee(feeType, feePayer, msg.sender);
    }

    function _updatePoolsWithFee(string memory feeType, address feePayer, address pool) private {

        // need pay staking fee whenever update pools
        if (!ICommittee(committee).getFeeFree(feePayer) && ICommittee(committee).getFee(feeType) > 0){
            lockERC20(ICommittee(committee).getNut(), feePayer, ICommittee(committee).getTreasury(), ICommittee(committee).getFee(feeType));
            ICommittee(committee).updateLedger(feeType, address(this), pool, feePayer);
        }

        uint256 rewardsReadyToMinted = 0;
        uint256 currentBlock = blockNum();

        if (lastRewardBlock == 0) {
            lastRewardBlock = currentBlock;
        }

        // make sure one block can only be calculated one time.
        // think about this situation that more than one deposit/withdraw/withdrowRewards transactions 
        // were exist in the same block, delegator.amout should be updated after _updateRewardInfo being 
        // invoked and it's award Rewards should be calculated next time
        if (currentBlock <= lastRewardBlock) return;

        // calculate reward Rewards under current blocks
        rewardsReadyToMinted = ICalculator(rewardCalculator).calculateReward(address(this), lastRewardBlock + 1, currentBlock);

        // save all rewards to contract temporary
        if (rewardsReadyToMinted > 0) {
            if (feeRatio > 0) {
                // only send rewards belong to community, reward belong to user would send when
                // they withdraw reward manually
                uint256 feeAmount = rewardsReadyToMinted.mul(feeRatio).div(CONSTANTS_10000);
                retainedRevenue = retainedRevenue.add(feeAmount);

                // only rewards belong to pools can used to compute shareAcc
                rewardsReadyToMinted = rewardsReadyToMinted.mul(CONSTANTS_10000.sub(feeRatio)).div(CONSTANTS_10000);
                emit PoolUpdated(feePayer, feeAmount);
            }
        }

        for (uint16 i = 0; i < activedPools.length; i++) {
            address poolAddress = activedPools[i];
            uint256 totalStakedAmount = IPool(poolAddress).getTotalStakedAmount();
            if(totalStakedAmount == 0 || poolRatios[poolAddress] == 0) continue;
            uint256 poolRewards = rewardsReadyToMinted.mul(1e12).mul(poolRatios[poolAddress]).div(CONSTANTS_10000);
            poolAcc[poolAddress] = poolAcc[poolAddress].add(poolRewards.div(totalStakedAmount));
        }

        lastRewardBlock = currentBlock;
    }

    function _checkRatioSum(uint16[] memory ratios) private pure {
        uint16 ratioSum = 0;
        for(uint8 i = 0; i < ratios.length; i++) {
            ratioSum += ratios[i];
        }
        require(ratioSum == CONSTANTS_10000 || ratioSum == 0, 'RS!=1w');//Ratio summary not equal to 10000
    }

    function _updatePoolRatios(uint16[] memory ratios) private {
        for (uint16 i = 0; i < activedPools.length; i++) {
            poolRatios[activedPools[i]] = ratios[i];
        }
        emit AdminSetPoolRatio(activedPools, ratios);
    }

    function _unlockOrMintAsset(address recipient, uint256 amount) private {
        if (isMintableCommunityToken) {
            mintERC20(communityToken, address(recipient), amount);
        } else {
            releaseERC20(communityToken, address(recipient), amount);
        }
    }

    function blockNum() public view returns (uint256) {
        return ArbSys(address(100)).arbBlockNumber();
    }
}