/**
 *Submitted for verification at Arbiscan on 2023-03-09
*/

// File: @openzeppelin/[email protected]/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/[email protected]/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/[email protected]/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/[email protected]/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/[email protected]/security/ReentrancyGuardUpgradeable.sol


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

// File: interfaces/IveSPA.sol

pragma solidity 0.8.10;

interface IveSPA {
    function getLastUserSlope(address addr) external view returns (int128);

    function getUserPointHistoryTS(address addr, uint256 idx)
        external
        view
        returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function checkpoint() external;

    function lockedEnd(address addr) external view returns (uint256);

    function depositFor(address addr, uint128 value) external;

    function createLock(
        uint128 value,
        uint256 unlockTime,
        bool autoCooldown
    ) external;

    function increaseAmount(uint128 value) external;

    function increaseUnlockTime(uint256 unlockTime) external;

    function initiateCooldown() external;

    function withdraw() external;

    function balanceOf(address addr, uint256 ts)
        external
        view
        returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOfAt(address, uint256 blockNumber)
        external
        view
        returns (uint256);

    function totalSupply(uint256 ts) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}

// File: contracts/GaugeController.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@&    (@@@@@@@@@@@@@    /@@@@@@@@@//
//@@@@@@          /@@@@@@@          /@@@@@@//
//@@@@@            (@@@@@            (@@@@@//
//@@@@@(            @@@@@(           &@@@@@//
//@@@@@@@           &@@@@@@         @@@@@@@//
//@@@@@@@@@@@@@@%    /@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@      (&@@@@@@@@@@@@//
//@@@@@@#         @@@@@@#           @@@@@@@//
//@@@@@/           %@@@@@            %@@@@@//
//@@@@@            #@@@@@            %@@@@@//
//@@@@@@          #@@@@@@@/         #@@@@@@//
//@@@@@@@@@&/ (@@@@@@@@@@@@@@&/ (&@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//




/// @title GaugeController
/// @notice This contract is the solidity version of curves GaugeController.
/// Ref: https://etherscan.io/address/0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB#code
contract GaugeController is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VoteData {
        uint256 slope;
        uint256 power;
        uint256 end;
        uint256 voteTime;
    }

    struct GaugeData {
        uint128 gType; // Gauge type
        address bribe; // Bribe contract for the gauge
        uint256 wtUpdateTime; // latest weight schedule time
        uint256 w0; // base weight for the gauge.
    }

    uint256 public constant MULTIPLIER = 1e18;
    uint256 public constant WEEK = 604800;
    uint256 public constant PREC = 10000;
    uint256 constant MAX_NUM = 1e9;
    uint256 constant MAX_NUM_GAUGES = 1e4;
    // # Cannot change weight votes more often than once in 7 days
    uint256 public constant WEIGHT_VOTE_DELAY = 7 * 86400;
    address public votingEscrow;
    uint128 public nGaugeTypes;
    uint128 public nGauges;
    // last scheduled time;
    uint256 public timeTotal;

    address[] public gauges;
    // type_id -> last scheduled time
    uint256[MAX_NUM] public timeSum;
    // type_id -> time
    uint256[MAX_NUM] public lastTypeWtTime;

    // time -> total weight
    mapping(uint256 => uint256) public totalWtAtTime;

    // user -> gauge_addr -> VoteData
    mapping(address => mapping(address => VoteData)) public userVoteData;
    // Total vote power used by user
    mapping(address => uint256) public userVotePower;

    // gauge_addr => type_id
    mapping(address => GaugeData) gaugeData;
    // gauge_addr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public gaugePoints;
    // gauge_addr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) public gaugeSlopeChanges;

    // Track gauge name
    mapping(uint128 => string) public typeNames;
    // type_id -> time -> Point
    mapping(uint128 => mapping(uint256 => Point)) public typePoints;
    // type_id -> time -> slope
    mapping(uint128 => mapping(uint256 => uint256)) public typeSlopeChanges;
    // type_id -> time -> type weight
    mapping(uint128 => mapping(uint256 => uint256)) public typeWtAtTime;

    event TypeAdded(string name, uint128 typeId);
    event TypeWeightUpdated(
        uint128 typeId,
        uint256 time,
        uint256 weight,
        uint256 totalWeight
    );
    event GaugeWeightUpdated(
        address indexed gAddr,
        uint256 time,
        uint256 weight,
        uint256 totalWeight
    );
    event GaugeVoted(
        uint256 time,
        address indexed user,
        address indexed gAddr,
        uint256 weight
    );
    event GaugeAdded(address indexed addr, uint128 gType, uint256 weight);
    event BribeContractUpdated(address indexed gAddr, address newBribeContract);

    constructor() initializer {}

    function initialize(address _veSPA) external initializer {
        _isNonZeroAddr(_veSPA);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        timeTotal = _getWeek(block.timestamp);
        votingEscrow = _veSPA;
    }

    /// @notice Add gauge type with name `_name` and weight `weight`
    /// @param _typeName Name of gauge type
    /// @param _weight Weight of gauge type
    function addType(string memory _typeName, uint256 _weight)
        external
        onlyOwner
    {
        uint128 gType = nGaugeTypes;
        typeNames[gType] = _typeName;
        nGaugeTypes = gType + 1;
        if (_weight != 0) {
            _changeTypeWeight(gType, _weight);
        }
        emit TypeAdded(_typeName, gType);
    }

    /// @notice Add gauge `gAddr` of type `gauge_type` with weight `weight`
    /// @param _gAddr Gauge address
    /// @param _gType Gauge type
    /// @param _weight Gauge weight
    function addGauge(
        address _gAddr,
        uint128 _gType,
        uint256 _weight
    ) external onlyOwner {
        _isNonZeroAddr(_gAddr);
        require(_gType < nGaugeTypes, "Invalid gauge type");
        require(gaugeData[_gAddr].gType == 0, "Gauge already registered"); /// @dev can't add the same gauge twice
        require(nGauges < MAX_NUM_GAUGES, "Can't add more gauges");
        gauges.push(_gAddr);
        nGauges += 1;

        uint256 nextTime = _getWeek(block.timestamp + WEEK);

        if (_weight > 0) {
            uint256 typeWeight = _getTypeWeight(_gType);
            uint256 oldSum = _getSum(_gType);
            uint256 oldTotal = _getTotal();

            typePoints[_gType][nextTime].bias = _weight + oldSum;
            timeSum[_gType] = nextTime;
            totalWtAtTime[nextTime] = oldTotal + typeWeight * _weight;
            timeTotal = nextTime;

            gaugePoints[_gAddr][nextTime].bias = _weight;
        }

        if (timeSum[_gType] == 0) {
            timeSum[_gType] = nextTime;
        }
        gaugeData[_gAddr] = GaugeData({
            gType: _gType + 1,
            bribe: address(0),
            wtUpdateTime: nextTime,
            w0: _weight
        });

        emit GaugeAdded(_gAddr, _gType, _weight);
    }

    /// @notice Change gauge type `_gType` weight to `_weight`
    /// @param _gType Gauge type id
    /// @param _weight New Gauge weight
    function changeTypeWeight(uint128 _gType, uint256 _weight)
        external
        onlyOwner
    {
        _changeTypeWeight(_gType, _weight);
    }

    /// @notice Change weight of gauge `_gAddr` to `_weight`
    /// @param _gAddr `GaugeController` contract address
    /// @param _weight New Gauge weight
    function changeGaugeWeight(address _gAddr, uint256 _weight)
        external
        onlyOwner
    {
        _changeGaugeWeight(_gAddr, _weight);
    }

    /// @notice Update the bribe contract for a gauge.
    /// @param _gAddr Address of the gauge.
    /// @param _newBribeContract Address of the new deployed bribe contract.
    /// @dev Do ensure the _newBribeContract is compatible with the bribe interface.
    function changeGaugeBribeContract(address _gAddr, address _newBribeContract)
        external
        onlyOwner
    {
        require(gaugeData[_gAddr].gType > 0, "Gauge not added");
        _isNonZeroAddr(_newBribeContract);
        gaugeData[_gAddr].bribe = _newBribeContract;
        emit BribeContractUpdated(_gAddr, _newBribeContract);
    }

    /// @notice Checkpoint to fill data common for all gauges
    function checkpoint() external {
        _getTotal();
    }

    /// @notice checkpoints gauge weight for missing weeks
    function checkpointGauge(address _gAddr) external {
        _getWeight(_gAddr);
        _getTotal();
    }

    /// @notice Allocate voting power for changing pool weights
    /// @param _gAddr Gauge which `msg.sender` votes for
    /// @param _userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
    function voteForGaugeWeight(address _gAddr, uint256 _userWeight)
        external
        nonReentrant
    {
        require(
            _userWeight >= 0 && _userWeight <= PREC,
            "All voting power used"
        );

        // Get user's latest veSPA stats
        uint256 slope = uint256(
            uint128(IveSPA(votingEscrow).getLastUserSlope(msg.sender))
        );
        uint256 lockEnd = IveSPA(votingEscrow).lockedEnd(msg.sender);

        uint256 nextTime = _getWeek(block.timestamp + WEEK);

        require(lockEnd > nextTime, "Lock expires before next cycle");

        // Prepare slopes and biases in memory
        VoteData memory oldVoteData = userVoteData[msg.sender][_gAddr];
        require(
            block.timestamp >= oldVoteData.voteTime + WEIGHT_VOTE_DELAY,
            "Can't vote so often"
        );

        VoteData memory newVoteData = VoteData({
            slope: (slope * _userWeight) / PREC,
            end: lockEnd,
            power: _userWeight,
            voteTime: block.timestamp
        });
        // Check and update powers (weights) used
        _updateUserPower(oldVoteData.power, newVoteData.power);

        _updateScheduledChanges(
            oldVoteData,
            newVoteData,
            nextTime,
            lockEnd,
            _gAddr
        );

        _getTotal();
        userVoteData[msg.sender][_gAddr] = newVoteData;

        emit GaugeVoted(block.timestamp, msg.sender, _gAddr, _userWeight);
    }

    /// @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    //         values for type and gauge records
    /// @dev Any address can call, however nothing is recorded if the values are filled already
    /// @param _gAddr Gauge address
    /// @param _time Relative weight at the specified timestamp in the past or present
    /// @return Value of relative weight normalized to 1e18
    function gaugeRelativeWeightWrite(address _gAddr, uint256 _time)
        external
        returns (uint256)
    {
        _getWeight(_gAddr);
        _getTotal();
        return _gaugeRelativeWeight(_gAddr, _time);
    }

    function gaugeRelativeWeightWrite(address _gAddr)
        external
        returns (uint256)
    {
        _getWeight(_gAddr);
        _getTotal();
        return _gaugeRelativeWeight(_gAddr, block.timestamp);
    }

    /// @notice Get gauge type for address
    /// @param _gAddr Gauge address
    /// @return Gauge type id
    function gaugeType(address _gAddr) external view returns (uint128) {
        return _getGaugeType(_gAddr);
    }

    /// @notice Get the bribe contract for the gauge.
    /// @param _gAddr Gauge address.
    /// @return bribe contract address.
    function gaugeBribe(address _gAddr) external view returns (address) {
        return gaugeData[_gAddr].bribe;
    }

    /// @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
    //         (e.g. 1.0 == 1e18). Inflation which will be received by it is
    //         inflation_rate * relative_weight / 1e18
    /// @param _gAddr Gauge address
    /// @param _time Relative weight at the specified timestamp in the past or present
    /// @return Value of relative weight normalized to 1e18
    function gaugeRelativeWeight(address _gAddr, uint256 _time)
        external
        view
        returns (uint256)
    {
        return _gaugeRelativeWeight(_gAddr, _time);
    }

    function gaugeRelativeWeight(address _gAddr)
        external
        view
        returns (uint256)
    {
        return _gaugeRelativeWeight(_gAddr, block.timestamp);
    }

    /// @notice Get current gauge weight
    /// @dev Gets the gauge weight based on last checkpoint.
    /// @param _gAddr Gauge address
    /// @return Gauge weight
    function getGaugeWeight(address _gAddr) external view returns (uint256) {
        return gaugePoints[_gAddr][gaugeData[_gAddr].wtUpdateTime].bias;
    }

    /// @notice Get the gauge weight at a provided week timestamp.
    /// @param _gAddr Gauge address
    /// @param _time Required week timestamp
    /// @dev _time should be in ((time / WEEK) * WEEK) value.
    /// @return Returns gauge weight for a week.
    function getGaugeWeight(address _gAddr, uint256 _time)
        external
        view
        returns (uint256)
    {
        return _getGaugeWeightReadOnly(_gAddr, _time);
    }

    /// @notice Get the gaugeWeight - w0 (base weight)
    /// @param _gAddr gauge address
    /// @param _time timestamp
    /// @return returns only the vote weight for the gauge.
    function getUserVotesWtForGauge(address _gAddr, uint256 _time)
        external
        view
        returns (uint256)
    {
        return _getGaugeWeightReadOnly(_gAddr, _time) - gaugeData[_gAddr].w0;
    }

    /// @notice Get current type weight
    /// @param _gType Type id
    /// @return Type weight
    function getTypeWeight(uint128 _gType) external view returns (uint256) {
        return typeWtAtTime[_gType][lastTypeWtTime[_gType]];
    }

    /// @notice Get current total (type-weighted) weight
    /// @return Total weight
    function getTotalWeight() external view returns (uint256) {
        return totalWtAtTime[timeTotal];
    }

    /// @notice Get sum of gauge weights per type
    /// @param _gType Type id
    /// @return Sum of gauge weights
    function getWeightsSumPerType(uint128 _gType)
        external
        view
        returns (uint256)
    {
        return typePoints[_gType][timeSum[_gType]].bias;
    }

    /// @notice Returns address of all registered gauges.
    function getGaugeList() external view returns (address[] memory) {
        return gauges;
    }

    /// @notice Fill historic type weights week-over-week for missed check-points
    ///         and return the type weight for the future week
    /// @param _gType Gauge type id
    /// @return Type weight
    function _getTypeWeight(uint128 _gType) private returns (uint256) {
        uint256 t = lastTypeWtTime[_gType];
        if (t > 0) {
            uint256 w = typeWtAtTime[_gType][t];
            for (uint8 i = 0; i < 100; ) {
                if (t > block.timestamp) {
                    lastTypeWtTime[_gType] = t;
                    break;
                }
                t += WEEK;
                typeWtAtTime[_gType][t] = w;
                unchecked {
                    ++i;
                }
            }
            return w;
        }
        return 0;
    }

    /// @notice Fill sum of gauge weights for the same type week-over-week for
    //         missed checkpoints and return the sum for the future week
    /// @param _gType Gauge type id
    /// @return Sum of weights
    function _getSum(uint128 _gType) private returns (uint256) {
        uint256 t = timeSum[_gType];
        if (t > 0) {
            Point memory pt = typePoints[_gType][t];
            for (uint8 i = 0; i < 100; ) {
                if (t > block.timestamp) {
                    timeSum[_gType] = t;
                    break;
                }
                t += WEEK;
                uint256 dBias = pt.slope * WEEK;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    pt.slope -= typeSlopeChanges[_gType][t];
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                typePoints[_gType][t] = pt;
                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        }
        return 0;
    }

    /// @notice Fill historic total weights week-over-week for missed checkins
    //         and return the total for the future week
    /// @return Total weight
    function _getTotal() private returns (uint256) {
        uint256 t = timeTotal;
        uint128 numTypes = nGaugeTypes;
        if (t > block.timestamp) {
            t -= WEEK;
        }

        // Updating type related data
        for (uint8 i = 0; i < 100; ) {
            if (i == numTypes) break;
            _getSum(i);
            _getTypeWeight(i);
            unchecked {
                ++i;
            }
        }

        uint256 pt = totalWtAtTime[t];

        for (uint256 i = 0; i < 100; ) {
            if (t > block.timestamp) {
                timeTotal = t;
                break;
            }
            t += WEEK;
            pt = 0;

            for (uint128 gType = 0; gType < 100; ) {
                if (gType == numTypes) break;
                uint256 typeSum = typePoints[gType][t].bias;
                uint256 typeWeight = typeWtAtTime[gType][t];
                pt += typeSum * typeWeight;
                unchecked {
                    ++gType;
                }
            }
            totalWtAtTime[t] = pt;
            unchecked {
                ++i;
            }
        }
        return pt;
    }

    /// @notice Fill historic gauge weights week-over-week for missed checkins
    //         and return the total for the future week
    /// @param _gAddr Address of the gauge
    /// @return Gauge weight
    function _getWeight(address _gAddr) private returns (uint256) {
        uint256 t = gaugeData[_gAddr].wtUpdateTime;
        if (t > 0) {
            Point memory pt = gaugePoints[_gAddr][t];
            for (uint8 i = 0; i < 100; ) {
                if (t > block.timestamp) {
                    gaugeData[_gAddr].wtUpdateTime = t;
                    break;
                }
                t += WEEK;
                uint256 dBias = pt.slope * WEEK;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    pt.slope -= gaugeSlopeChanges[_gAddr][t];
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                gaugePoints[_gAddr][t] = pt;
                unchecked {
                    ++i;
                }
            }
            return pt.bias;
        }
        return 0;
    }

    /// @notice Change type weight
    /// @param _gType Type id
    /// @param _weight New type weight
    function _changeTypeWeight(uint128 _gType, uint256 _weight) private {
        uint256 oldWeight = _getTypeWeight(_gType);
        uint256 oldSum = _getSum(_gType);
        uint256 totalWeight = _getTotal();
        uint256 nextTime = _getWeek(block.timestamp + WEEK);

        totalWeight = totalWeight + (oldSum * _weight) - (oldSum * oldWeight);
        totalWtAtTime[nextTime] = totalWeight;
        typeWtAtTime[_gType][nextTime] = _weight;
        timeTotal = nextTime;
        lastTypeWtTime[_gType] = nextTime;

        emit TypeWeightUpdated(_gType, nextTime, _weight, totalWeight);
    }

    /// @notice Change gauge weight
    /// @param _gAddr Gauge Address
    /// @param _weight for gauge.
    function _changeGaugeWeight(address _gAddr, uint256 _weight) private {
        uint128 gType = _getGaugeType(_gAddr);
        uint256 oldGaugeWeight = _getWeight(_gAddr);
        uint256 oldW0 = gaugeData[_gAddr].w0;
        uint256 typeWeight = _getTypeWeight(gType);
        uint256 oldSum = _getSum(gType);
        uint256 totalWeight = _getTotal();
        uint256 nextTime = _getWeek(block.timestamp + WEEK);

        gaugePoints[_gAddr][nextTime].bias = oldGaugeWeight + _weight - oldW0;
        gaugeData[_gAddr].wtUpdateTime = nextTime;
        gaugeData[_gAddr].w0 = _weight;

        uint256 newSum = oldSum + _weight - oldGaugeWeight;
        typePoints[gType][nextTime].bias = newSum;
        timeSum[gType] = nextTime;

        totalWeight += (newSum - oldSum) * typeWeight;
        totalWtAtTime[nextTime] = totalWeight;
        timeTotal = nextTime;
        emit GaugeWeightUpdated(_gAddr, block.timestamp, _weight, totalWeight);
    }

    /// @notice Update user power.
    /// @param _oldPow current power used.
    /// @param _newPow updated power.
    function _updateUserPower(uint256 _oldPow, uint256 _newPow) private {
        // Check and update powers (weights) used
        uint256 powerUsed = userVotePower[msg.sender];
        powerUsed = powerUsed + _newPow - _oldPow;
        userVotePower[msg.sender] = powerUsed;
        require(powerUsed >= 0 && powerUsed <= PREC, "Power beyond boundaries");
    }

    /// @notice Update the vote data and scheduled slope changes.
    /// @param _oldVoteData user's old vote data.
    /// @param _newVoteData user's new vote data.
    /// @param _nextTime timestamp for next cycle.
    /// @param _lockEnd the expiry ts for user's veSPA position.
    /// @param _gAddr address of the gauge.
    function _updateScheduledChanges(
        VoteData memory _oldVoteData,
        VoteData memory _newVoteData,
        uint256 _nextTime,
        uint256 _lockEnd,
        address _gAddr
    ) private {
        uint128 gType = _getGaugeType(_gAddr);

        // Calculate the current bias based on the oldVoteData.
        uint256 old_dt = 0;
        if (_oldVoteData.end > _nextTime) {
            old_dt = _oldVoteData.end - _nextTime;
        }
        uint256 oldBias = _oldVoteData.slope * old_dt;

        // Calculate the new bias.
        uint256 new_dt = _lockEnd - _nextTime;
        uint256 newBias = _newVoteData.slope * new_dt;

        uint256 oldGaugeSlope = gaugePoints[_gAddr][_nextTime].slope;
        uint256 oldTypeSlope = typePoints[gType][_nextTime].slope;

        {
            // restrict scope of below variables (resolves, stack too deep)
            uint256 oldWtBias = _getWeight(_gAddr);
            uint256 oldSumBias = _getSum(gType);
            // Remove old and schedule new slope changes
            // Remove slope changes for old slopes
            // Schedule recording of initial slope for _nextTime.
            gaugePoints[_gAddr][_nextTime].bias =
                _max(oldWtBias + newBias, oldBias) -
                oldBias;
            typePoints[gType][_nextTime].bias =
                _max(oldSumBias + newBias, oldBias) -
                oldBias;
        }

        if (_oldVoteData.end > _nextTime) {
            gaugePoints[_gAddr][_nextTime].slope =
                _max(oldGaugeSlope + _newVoteData.slope, _oldVoteData.slope) -
                _oldVoteData.slope;
            typePoints[gType][_nextTime].slope =
                _max(oldTypeSlope + _newVoteData.slope, _oldVoteData.slope) -
                _oldVoteData.slope;
        } else {
            gaugePoints[_gAddr][_nextTime].slope += _newVoteData.slope;
            typePoints[gType][_nextTime].slope += _newVoteData.slope;
        }

        if (_oldVoteData.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            gaugeSlopeChanges[_gAddr][_oldVoteData.end] -= _oldVoteData.slope;
            typeSlopeChanges[gType][_oldVoteData.end] -= _oldVoteData.slope;
        }

        // Add slope changes for new slopes
        gaugeSlopeChanges[_gAddr][_newVoteData.end] += _newVoteData.slope;
        typeSlopeChanges[gType][_newVoteData.end] += _newVoteData.slope;
    }

    /// @notice Returns the gauge weight based on the last check-pointed data
    /// @param _gAddr Address of the gauge.
    /// @param _time Required timestamp.
    /// @dev Returns weight based on the Week start of the provided time
    /// @return Returns the weight of the gauge.
    function _getGaugeWeightReadOnly(address _gAddr, uint256 _time)
        private
        view
        returns (uint256)
    {
        uint256 lastUpdateTime = gaugeData[_gAddr].wtUpdateTime;

        // Gauge wt is check-pointed for the time stamp
        if (_time <= lastUpdateTime) {
            return gaugePoints[_gAddr][_time].bias;
        }

        // Calculate estimated gauge weight based on lastUpdateTime
        Point memory lastPoint = gaugePoints[_gAddr][lastUpdateTime];
        uint256 delta = lastPoint.slope *
            WEEK *
            ((_time - lastUpdateTime) / WEEK);

        // all the votes have expired
        if (delta > lastPoint.bias) return 0;

        // return the estimated weight.
        return lastPoint.bias - delta;
    }

    /// @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
    //         (e.g. 1.0 == 1e18). Inflation which will be received by it is
    //         inflation_rate * relative_weight / 1e18
    /// @param _gAddr Gauge address
    /// @param _time Relative weight at the specified timestamp in the past or present
    /// @return Value of relative weight normalized to 1e18
    function _gaugeRelativeWeight(address _gAddr, uint256 _time)
        private
        view
        returns (uint256)
    {
        uint128 gType = _getGaugeType(_gAddr);
        uint256 t = _getWeek(_time);
        uint256 totalWeight = totalWtAtTime[t];

        if (totalWeight > 0) {
            uint256 typeWeight = typeWtAtTime[gType][t];
            uint256 gaugeWeight = gaugePoints[_gAddr][t].bias;
            return (MULTIPLIER * typeWeight * gaugeWeight) / totalWeight;
        }
        return 0;
    }

    function _getGaugeType(address _gAddr) private view returns (uint128) {
        uint128 gType = gaugeData[_gAddr].gType;
        require(gType > 0, "Gauge not added");
        return gType - 1;
    }

    /// @notice Get the based on the ts.
    /// @param _ts arbitrary time stamp.
    /// @return returns the 00:00 am UTC for THU after _ts
    function _getWeek(uint256 _ts) private pure returns (uint256) {
        return (_ts / WEEK) * WEEK;
    }

    function _max(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a > _b) return _a;
        return _b;
    }

    /// @notice Validate address
    function _isNonZeroAddr(address _addr) private pure {
        require(_addr != address(0), "Invalid address");
    }
}