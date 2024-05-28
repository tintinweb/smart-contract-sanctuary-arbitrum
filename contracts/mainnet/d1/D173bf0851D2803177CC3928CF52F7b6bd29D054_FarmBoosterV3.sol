// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-4.5.0/contracts/security/ReentrancyGuard.sol";
import "./libraries/IterateMapping.sol";
import "./interfaces/IVECake.sol";
import "./interfaces/IMasterChefV3.sol";
import "./interfaces/IPancakeV3Pool.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IPancakeV3Factory.sol";

// Vecake user can delegate VECake to another address for boosting in MasterChef V3 in FarmBooster version three.
contract FarmBoosterV3 is Ownable, ReentrancyGuard {
    using IterableMapping for ItMap;

    /// @notice VECake.
    address public immutable VECake;
    /// @notice VECake caller, this smart contract will trigger depositFor and unlock.
    address public VECakeCaller;
    /// @notice MasterChef V3 contract.
    IMasterChefV3 public immutable MASTER_CHEF_V3;

    /// @notice NonfungiblePositionManager contract.
    INonfungiblePositionManager public immutable NonfungiblePositionManager;

    /// @notice PancakeV3Factory contract.
    IPancakeV3Factory public immutable PancakeV3Factory;

    /// @notice Record user token position liquidity
    /// @dev Only record the positions which have updated after fram booster set in MasterChef V3.
    mapping(address => mapping(uint256 => uint256)) public userPositionLiquidity;

    /// @notice Record user total liquidity in MasterChef V3 pool
    mapping(address => mapping(uint256 => uint256)) public userPoolTotalLiquidity;

    /// @notice limit max boost
    uint256 public cA;
    /// @notice include 1e4
    uint256 public constant MIN_CA = 1e4;
    /// @notice include 1e5
    uint256 public constant MAX_CA = 1e5;
    /// @notice cA precision
    uint256 public constant CA_PRECISION = 1e5;
    /// @notice controls difficulties
    uint256 public cB;
    /// @notice not include 0
    uint256 public constant MIN_CB = 0;
    /// @notice include 50
    uint256 public constant MAX_CB = 1e8;
    /// @notice cB precision
    uint256 public constant CB_PRECISION = 1e4;
    /// @notice MCV3 basic boost factor, none boosted user"s boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice MCV3 Hard limit for maximum boost factor
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;

    /// @notice Override global cB for special pool pid.
    mapping(uint256 => uint256) public cBOverride;

    /// @notice The whitelist of pools allowed for farm boosting.
    mapping(uint256 => bool) public whiteList;

    /// @notice Record whether the farm booster has been turned on, in order to save gas.
    mapping(uint256 => bool) public everBoosted;

    /// @notice Info of each pool user.
    mapping(address => ItMap) public userInfo;

    /// @notice VECake delegator address in MasterChef V3.
    /// @dev User can delegate VECake to another address for boosted in MasterChef V3.
    /// Mapping from VECake account to MasterChef V3 delegator account.
    mapping(address => address) public delegator;

    /// @notice The MasterChef V3 account which was delegated by VECake account.
    /// Mapping from MasterChef V3 delegator account to VECake account.
    mapping(address => address) public delegated;

    /// @notice Gives permission to VECake account.
    /// @dev Avoid malicious attacks.
    /// The approval is cleared when the delegator was setted.
    /// Mapping from MasterChef V3 delegator account to VECake account.
    mapping(address => address) public delegatorApprove;

    event UpdateCA(uint256 oldCA, uint256 newCA);
    event UpdateCB(uint256 oldCB, uint256 newCB);
    event UpdateCBOverride(uint256 pid, uint256 oldCB, uint256 newCB);
    event UpdateBoostFarms(uint256 pid, bool status);
    event UpdatePoolBoostMultiplier(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed tokenId,
        uint256 oldMultiplier,
        uint256 newMultiplier
    );
    event UpdateVECakeCaller(address VECakeCaller);
    event UpdateDelegator(address indexed user, address indexed oldDelegator, address indexed delegator);
    event Approve(address indexed delegator, address indexed VECakeUser);

    /// @param _VECake VECake contract address.
    /// @param _v3 MasterChefV3 contract address.
    /// @param _cA Limit max boost.
    /// @param _cB Controls difficulties.
    constructor(
        address _VECake,
        IMasterChefV3 _v3,
        uint256 _cA,
        uint256 _cB
    ) {
        require(_cA >= MIN_CA && _cA <= MAX_CA && _cB > MIN_CB && _cB <= MAX_CB, "Invalid parameter");
        VECake = _VECake;
        MASTER_CHEF_V3 = _v3;
        cA = _cA;
        cB = _cB;

        NonfungiblePositionManager = INonfungiblePositionManager(MASTER_CHEF_V3.nonfungiblePositionManager());

        PancakeV3Factory = IPancakeV3Factory(NonfungiblePositionManager.factory());
    }

    /// @notice Checks if the msg.sender is the MasterChef V3.
    modifier onlyMasterChefV3() {
        require(msg.sender == address(MASTER_CHEF_V3), "Not MasterChef V3");
        _;
    }

    /// @notice Checks if the msg.sender is the vecake caller.
    modifier onlyVECakeCaller() {
        require(msg.sender == VECakeCaller, "Not vecake caller");
        _;
    }

    struct DelegatorConfig {
        address VECakeUser;
        address delegator;
    }

    /// @notice set VECake delegators.
    /// @dev In case VECake partner contract can not upgrade, owner can set delegator.
    /// The delegator address can not have any position in MasterChef V3.
    /// The old delegator address can not have any position in MasterChef V3.
    /// @param _delegatorConfigs VECake delegator config.
    function setDelegators(DelegatorConfig[] calldata _delegatorConfigs) external onlyOwner {
        for (uint256 i = 0; i < _delegatorConfigs.length; i++) {
            DelegatorConfig memory delegatorConfig = _delegatorConfigs[i];
            require(
                delegatorConfig.VECakeUser != address(0) && delegatorConfig.delegator != address(0),
                "Invalid address"
            );
            // The delegator need to approve VECake contract.
            require(delegatorApprove[delegatorConfig.delegator] == delegatorConfig.VECakeUser, "Not approved");

            address oldDelegator = delegatorConfig.VECakeUser;
            if (delegator[delegatorConfig.VECakeUser] != address(0)) {
                oldDelegator = delegator[delegatorConfig.VECakeUser];
            }
            // clear old delegated information
            delegated[oldDelegator] = address(0);

            uint256 oldDelegatorBalanceInMCV3 = MASTER_CHEF_V3.balanceOf(oldDelegator);
            uint256 delegatorBalanceInMCV3 = MASTER_CHEF_V3.balanceOf(delegatorConfig.delegator);
            require(
                oldDelegatorBalanceInMCV3 == 0 && delegatorBalanceInMCV3 == 0,
                "Please withdraw all positions in MasterChef V3"
            );

            delegator[delegatorConfig.VECakeUser] = delegatorConfig.delegator;
            delegated[delegatorConfig.delegator] = delegatorConfig.VECakeUser;
            delegatorApprove[delegatorConfig.delegator] = address(0);
            emit UpdateDelegator(delegatorConfig.VECakeUser, oldDelegator, delegatorConfig.delegator);
        }
    }

    /// @notice Gives permission to VECake account.
    /// @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
    /// The approval is cleared when the delegator is set.
    /// @param _VECakeUser VECake account address.
    function approveToVECakeUser(address _VECakeUser) external nonReentrant {
        require(delegated[msg.sender] == address(0), "Delegator already has VECake account");

        delegatorApprove[msg.sender] = _VECakeUser;
        emit Approve(msg.sender, _VECakeUser);
    }

    /// @notice set VECake delegator address for MasterChef V3.
    /// @dev The delegator address can not have any position in MasterChef V3.
    /// The old delegator address can not have any position in MasterChef V3.
    /// @param _delegator MasterChef V3 delegator address.
    function setDelegator(address _delegator) external nonReentrant {
        require(_delegator != address(0), "Invalid address");
        // The delegator need to approve VECake contract.
        require(delegatorApprove[_delegator] == msg.sender, "Not approved");

        address oldDelegator = msg.sender;
        if (delegator[msg.sender] != address(0)) {
            oldDelegator = delegator[msg.sender];
        }
        // clear old delegated information
        delegated[oldDelegator] = address(0);

        uint256 oldDelegatorBalanceInMCV3 = MASTER_CHEF_V3.balanceOf(oldDelegator);
        uint256 delegatorBalanceInMCV3 = MASTER_CHEF_V3.balanceOf(_delegator);
        require(
            oldDelegatorBalanceInMCV3 == 0 && delegatorBalanceInMCV3 == 0,
            "Please withdraw all positions in MasterChef V3"
        );

        delegator[msg.sender] = _delegator;
        delegated[_delegator] = msg.sender;
        delegatorApprove[_delegator] = address(0);

        emit UpdateDelegator(msg.sender, oldDelegator, _delegator);
    }

    /// @notice Remove VECake delegator address for MasterChef V3.
    /// @dev The old delegator address can not have any position in MasterChef V3.
    function removeDelegator() external nonReentrant {
        address oldDelegator = delegator[msg.sender];
        require(oldDelegator != address(0), "No delegator");
        uint256 oldDelegatorBalanceInMCV3 = MASTER_CHEF_V3.balanceOf(oldDelegator);
        require(oldDelegatorBalanceInMCV3 == 0, "Please withdraw all positions in MasterChef V3");

        delegated[oldDelegator] = address(0);
        delegator[msg.sender] = address(0);
        emit UpdateDelegator(msg.sender, oldDelegator, address(0));
    }

    /// @notice set VECake caller.
    /// @param _VECakeCaller VECake caller.
    function setVECakeCaller(address _VECakeCaller) external onlyOwner {
        VECakeCaller = _VECakeCaller;
        emit UpdateVECakeCaller(_VECakeCaller);
    }

    struct BoosterFarmConfig {
        uint256 pid;
        bool status;
    }

    /// @notice Only allow whitelisted pids for farm boosting.
    /// @param _boosterFarms Booster farms config
    function setBoosterFarms(BoosterFarmConfig[] calldata _boosterFarms) external onlyOwner {
        for (uint256 i = 0; i < _boosterFarms.length; i++) {
            BoosterFarmConfig memory farm = _boosterFarms[i];
            if (farm.status && !everBoosted[farm.pid]) everBoosted[farm.pid] = true;
            whiteList[farm.pid] = farm.status;
            emit UpdateBoostFarms(farm.pid, farm.status);
        }
    }

    /// @notice Limit max boost.
    /// @param _cA Max boost.
    function setCA(uint256 _cA) external onlyOwner {
        require(_cA >= MIN_CA && _cA <= MAX_CA, "Invalid cA");
        uint256 temp = cA;
        cA = _cA;
        emit UpdateCA(temp, cA);
    }

    /// @notice Controls difficulties.
    /// @param _cB Difficulties.
    function setCB(uint256 _cB) external onlyOwner {
        require(_cB > MIN_CB && _cB <= MAX_CB, "Invalid cB");
        uint256 temp = cB;
        cB = _cB;
        emit UpdateCB(temp, cB);
    }

    /// @notice Set cBOverride.
    /// @param _pid Pool pid.
    /// @param _cB Difficulties.
    function setCBOverride(uint256 _pid, uint256 _cB) external onlyOwner {
        // Can set cBOverride[pid] 0 when need to remove override value.
        require((_cB > MIN_CB && _cB <= MAX_CB) || _cB == 0, "Invalid cB");
        uint256 temp = cB;
        cBOverride[_pid] = _cB;
        emit UpdateCBOverride(_pid, temp, cB);
    }

    /// @notice Update user pool liquidity.
    /// @dev This will update the user total liquidity in pool.
    /// @param _user User address.
    /// @param _tokenId token id.
    /// @param _pid pool id.
    /// @param _liquidity token liquidity.
    function updateUserPoolLiquidity(
        address _user,
        uint256 _tokenId,
        uint256 _pid,
        uint256 _liquidity
    ) internal {
        // update total liquidity in this pool
        userPoolTotalLiquidity[_user][_pid] =
            userPoolTotalLiquidity[_user][_pid] -
            userPositionLiquidity[_user][_tokenId] +
            _liquidity;
        userPositionLiquidity[_user][_tokenId] = _liquidity;
    }

    /// @notice Update user boost multiplier, only for MasterChef V3.
    /// @param _tokenId Token Id of position NFT.
    function updatePositionBoostMultiplier(uint256 _tokenId) external onlyMasterChefV3 returns (uint256 _multiplier) {
        (
            uint128 liquidity,
            uint128 boostLiquidity,
            ,
            ,
            ,
            ,
            address user,
            uint256 pid,
            uint256 boostMultiplier
        ) = MASTER_CHEF_V3.userPositionInfos(_tokenId);
        // Do not allow user to increase liquidity after removed all liquidity in MasterChef V3.
        if (boostLiquidity == 0 && boostMultiplier > 0) {
            revert();
        }
        // Set default multiplier
        _multiplier = BOOST_PRECISION;
        // In order to save gas, no need to check the farms which have never been boosted.
        if (everBoosted[pid]) {
            updateUserPoolLiquidity(user, _tokenId, pid, liquidity);

            ItMap storage itmap = userInfo[user];
            uint256 prevMultiplier = itmap.data[_tokenId];

            if (!whiteList[pid]) {
                if (itmap.contains(_tokenId)) {
                    itmap.remove(_tokenId);
                }
            } else {
                _multiplier = _boostCalculate(user, pid, userPoolTotalLiquidity[user][pid], 0, true);
                itmap.insert(_tokenId, _multiplier);
            }
            emit UpdatePoolBoostMultiplier(user, pid, _tokenId, prevMultiplier, _multiplier);
        }
    }

    /// @notice Remove user boost multiplier when user withdraw or burn in MasterChef V3.
    /// @param _user User address.
    /// @param _tokenId Token Id of position NFT.
    /// @param _pid Id of MasterChef V3 farm pool.
    function removeBoostMultiplier(
        address _user,
        uint256 _tokenId,
        uint256 _pid
    ) external onlyMasterChefV3 {
        // In order to save gas, no need to check the farms which have never been boosted.
        if (everBoosted[_pid]) {
            updateUserPoolLiquidity(_user, _tokenId, _pid, 0);

            ItMap storage itmap = userInfo[_user];
            if (itmap.contains(_tokenId)) {
                itmap.remove(_tokenId);
            }
        }
    }

    /// @notice VECake operation(deposit/withdraw) automatically call this function.
    /// @param _for User address.
    /// @param _amount The amount to deposit
    /// @param _unlockTime New time to unlock Cake. Pass 0 if no change.
    /// @param _prevLockedAmount Existed locks[_for].amount
    /// @param _prevLockedEnd Existed locks[_for].end
    /// @param _actionType The action that user did as this internal function shared among
    /// @param _isCakePoolUser This user is cake pool user or not
    function depositFor(
        address _for,
        uint256 _amount,
        uint256 _unlockTime,
        int128 _prevLockedAmount,
        uint256 _prevLockedEnd,
        uint256 _actionType,
        bool _isCakePoolUser
    ) external onlyVECakeCaller {
        _updateUserAllBoostMultiplier(_for);
    }

    /// @notice Function to perform withdraw and unlock Cake for a user
    /// @param _user The address to be unlocked
    /// @param _prevLockedAmount Existed locks[_user].amount
    /// @param _prevLockedEnd Existed locks[_user].end
    /// @param _withdrawAmount Cake amount
    function unlock(
        address _user,
        int128 _prevLockedAmount,
        uint256 _prevLockedEnd,
        uint256 _withdrawAmount
    ) external onlyVECakeCaller {
        _updateUserAllBoostMultiplier(_user);
    }

    function _updateUserAllBoostMultiplier(address _user) internal {
        ItMap storage itmap = userInfo[_user];
        uint256 length = itmap.keys.length;
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 tokenId = itmap.keys[i];
                (, address user, uint256 pid, ) = getUserPositionInfo(tokenId);
                if (_user == user) _updateBoostMultiplier(itmap, user, pid, tokenId);
            }
        }
    }

    /// @param _user user address.
    /// @param _pid pool id.
    /// @param _tokenId token id.
    function _updateBoostMultiplier(
        ItMap storage itmap,
        address _user,
        uint256 _pid,
        uint256 _tokenId
    ) internal {
        // Used to be boosted farm pool and current is not, remove from mapping
        if (!whiteList[_pid]) {
            if (itmap.data[_tokenId] > BOOST_PRECISION) {
                // reset to BOOST_PRECISION
                MASTER_CHEF_V3.updateBoostMultiplier(_tokenId, BOOST_PRECISION);
            }
            itmap.remove(_tokenId);
            return;
        }

        (, , , uint256 prevMultiplier) = getUserPositionInfo(_tokenId);
        uint256 multiplier = _boostCalculate(_user, _pid, userPoolTotalLiquidity[_user][_pid], 0, true);

        if (multiplier < BOOST_PRECISION) {
            multiplier = BOOST_PRECISION;
        } else if (multiplier > MAX_BOOST_PRECISION) {
            multiplier = MAX_BOOST_PRECISION;
        }

        // Update multiplier to MCV3
        if (multiplier != prevMultiplier) {
            MASTER_CHEF_V3.updateBoostMultiplier(_tokenId, multiplier);
        }
        itmap.insert(_tokenId, multiplier);

        emit UpdatePoolBoostMultiplier(_user, _pid, _tokenId, prevMultiplier, multiplier);
    }

    /// @notice Whether position boosted specific farm pool.
    /// @param _tokenId Token Id of position NFT.
    function isBoostedPool(uint256 _tokenId) external view returns (bool, uint256) {
        (, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        return (userInfo[user].contains(_tokenId), pid);
    }

    /// @notice Actived position list.
    /// @param _user user address.
    function activedPositions(address _user) external view returns (uint256[] memory positions) {
        ItMap storage itmap = userInfo[_user];
        if (itmap.keys.length == 0) return positions;

        positions = new uint256[](itmap.keys.length);
        // solidity for-loop not support multiple variables initialized by "," separate.
        for (uint256 index = 0; index < itmap.keys.length; index++) {
            positions[index] = itmap.keys[index];
        }
    }

    function getUserPositionInfo(uint256 _tokenId)
        internal
        view
        returns (
            uint128 liquidity,
            address user,
            uint256 pid,
            uint256 boostMultiplier
        )
    {
        (liquidity, , , , , , user, pid, boostMultiplier) = MASTER_CHEF_V3.userPositionInfos(_tokenId);
    }

    /// @notice Anyone can call this function, if you find some guys effected multiplier is not fair
    /// for other users, just call "updateLiquidity" function in MasterChef V3.
    /// @param _tokenId Token Id of position NFT.
    /// @dev If return value not in range [BOOST_PRECISION, MAX_BOOST_PRECISION]
    /// the actual effected multiplier will be the close to side boundry value.
    function getUserMultiplier(uint256 _tokenId) external view returns (uint256) {
        (uint256 liquidity, address user, uint256 pid, ) = getUserPositionInfo(_tokenId);
        // Default is true
        bool isStaked = true;
        // positions did not stake in MasterChefV3 when pid is equal to 0.
        // Check positions in NonfungiblePositionManager
        if (pid == 0) {
            (
                ,
                ,
                address token0,
                address token1,
                uint24 fee,
                ,
                ,
                uint128 positionLiquidity,
                ,
                ,
                ,

            ) = NonfungiblePositionManager.positions(_tokenId);

            liquidity = uint256(positionLiquidity);
            user = NonfungiblePositionManager.ownerOf(_tokenId);
            address v3PoolAddress = PancakeV3Factory.getPool(token0, token1, fee);
            pid = MASTER_CHEF_V3.v3PoolAddressPid(v3PoolAddress);

            if (pid > 0) {
                isStaked = false;
            }
        }
        if (!whiteList[pid]) {
            return BOOST_PRECISION;
        } else {
            uint256 totalLiquidityInPool = userPoolTotalLiquidity[user][pid] -
                userPositionLiquidity[user][_tokenId] +
                liquidity;
            return _boostCalculate(user, pid, totalLiquidityInPool, liquidity, isStaked);
        }
    }

    /// @notice Get the total liquidity.
    /// @dev Will use the smaller value between MasterChefV3 pool totalLiquidity and V3 pool liquidity.
    /// @param _pid pool id(MasterchefV3 pool).
    /// @param _positionLiquidity Position liquidity of tokenId
    /// @param _isStaked The position had staked in MasterChefV3 or not
    function _getTotalLiquidity(
        uint256 _pid,
        uint256 _positionLiquidity,
        bool _isStaked
    ) internal view returns (uint256) {
        (, address v3Pool, , , , uint256 totalLiquidity, ) = MASTER_CHEF_V3.poolInfo(_pid);
        if (!_isStaked) {
            totalLiquidity += _positionLiquidity;
        }
        uint256 v3PoolLiquidity = IPancakeV3Pool(v3Pool).liquidity();
        if (totalLiquidity > v3PoolLiquidity) {
            totalLiquidity = v3PoolLiquidity;
        }
        return totalLiquidity;
    }

    /// @param _user user address.
    /// @param _pid pool id(MasterchefV3 pool).
    /// @param _userTotalLiquidity User total liquidity in MasterChef V3 pool
    /// @param _positionLiquidity Position liquidity of tokenId
    /// @param _isStaked The position had staked in MasterChefV3 or not
    function _boostCalculate(
        address _user,
        uint256 _pid,
        uint256 _userTotalLiquidity,
        uint256 _positionLiquidity,
        bool _isStaked
    ) internal view returns (uint256) {
        // If this user has delegator , but the delegator is not the same user in MasterChef V3, use default boost factor.
        if (delegator[_user] != address(0) && delegator[_user] != _user) {
            return BOOST_PRECISION;
        }

        // If MasterChef V3 user has delegated VECake account, use delegated VECake account balance to calculate boost factor.
        address VEcakeUser = _user;
        if (delegated[_user] != address(0)) {
            VEcakeUser = delegated[_user];
        }

        uint256 dB = (cA * _userTotalLiquidity) / CA_PRECISION;
        // dB == 0 means _liquidity close to 0
        if (dB == 0) return BOOST_PRECISION;

        uint256 totalLiquidity = _getTotalLiquidity(_pid, _positionLiquidity, _isStaked);

        // will use cBOverride[pid] If cBOverride[pid] is greater than 0 , or will use global cB.
        uint256 realCB = cBOverride[_pid] > 0 ? cBOverride[_pid] : cB;
        uint256 totalSupplyInVECake = IVECake(VECake).totalSupply();
        if (totalSupplyInVECake == 0) return BOOST_PRECISION;

        uint256 aB = (totalLiquidity * IVECake(VECake).balanceOf(VEcakeUser) * realCB) /
            totalSupplyInVECake /
            CB_PRECISION;
        return ((_userTotalLiquidity <= (dB + aB) ? _userTotalLiquidity : (dB + aB)) * BOOST_PRECISION) / dB;
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
pragma solidity ^0.8.9;

struct ItMap {
    // pid => boost
    mapping(uint256 => uint256) data;
    // pid => index
    mapping(uint256 => uint256) indexs;
    // array of pid
    uint256[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableMapping {
    function insert(
        ItMap storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 keyIndex = self.indexs[key];
        self.data[key] = value;
        if (keyIndex > 0) return;
        else {
            self.indexs[key] = self.keys.length + 1;
            self.keys.push(key);
            return;
        }
    }

    function remove(ItMap storage self, uint256 key) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return;
        uint256 lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.data[key];
        delete self.indexs[key];
        self.keys.pop();
    }

    function contains(ItMap storage self, uint256 key) internal view returns (bool) {
        return self.indexs[key] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVECake {
    function userInfo(address user)
        external
        view
        returns (
            address cakePoolProxy, // Proxy Smart Contract for users who had locked in cake pool.
            uint128 cakeAmount, //  Cake amount locked in cake pool.
            uint48 lockEndTime, // Record the lockEndTime in cake pool.
            uint48 migrationTime, // Record the migration time.
            uint16 cakePoolType, // 1: Migration, 2: Delegation.
            uint16 withdrawFlag // 0: Not withdraw, 1 : withdrew.
        );

    function isCakePoolProxy(address _user) external view returns (bool);

    /// @dev Return the max epoch of the given "_user"
    function userPointEpoch(address _user) external view returns (uint256);

    /// @dev Return the max global epoch
    function epoch() external view returns (uint256);

    /// @dev Trigger global check point
    function checkpoint() external;

    /// @notice Return the proxy balance of VECake at a given "_blockNumber"
    /// @param _user The proxy owner address to get a balance of VECake
    /// @param _blockNumber The speicific block number that you want to check the balance of VECake
    function balanceOfAtForProxy(address _user, uint256 _blockNumber) external view returns (uint256);

    /// @notice Return the balance of VECake at a given "_blockNumber"
    /// @param _user The address to get a balance of VECake
    /// @param _blockNumber The speicific block number that you want to check the balance of VECake
    function balanceOfAt(address _user, uint256 _blockNumber) external view returns (uint256);

    /// @notice Return the voting weight of a givne user's proxy
    /// @param _user The address of a user
    function balanceOfForProxy(address _user) external view returns (uint256);

    /// @notice Return the voting weight of a givne user
    /// @param _user The address of a user
    function balanceOf(address _user) external view returns (uint256);

    /// @notice Calculate total supply of VECake (voting power)
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMasterChefV3 {
    function balanceOf(address user) external view returns (uint256);

    function userPositionInfos(uint256 _tokenId)
        external
        view
        returns (
            uint128,
            uint128,
            int24,
            int24,
            uint256,
            uint256,
            address,
            uint256,
            uint256
        );

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            uint256,
            address,
            address,
            address,
            uint24,
            uint256,
            uint256
        );

    function v3PoolAddressPid(address _pool) external view returns (uint256);

    function updateBoostMultiplier(uint256 _tokenId, uint256 _newMultiplier) external;

    function updateLiquidity(uint256 _tokenId) external;

    function nonfungiblePositionManager() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeV3Pool {
    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function ownerOf(uint256 tokenId) external view returns (address);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPancakeV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
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