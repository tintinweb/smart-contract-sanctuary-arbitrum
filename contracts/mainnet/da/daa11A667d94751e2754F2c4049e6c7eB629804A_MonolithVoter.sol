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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity 0.8.16;

interface ITokenBooster {
    function getWeek() external view returns (uint256);

    function weeklyWeight(address user, uint256 week)
        external
        view
        returns (uint256, uint256);

    function userWeight(address _user) external view returns (uint256);

    function startTime() external view returns (uint256);
}

pragma solidity 0.8.16;

interface IBaseV1Minter {
    function active_period() external view returns (uint256);
}

pragma solidity 0.8.16;

interface IBaseV1Voter {
    function bribes(address gauge) external view returns (address bribe);

    function gauges(address pool) external view returns (address gauge);

    function poolForGauge(address gauge) external view returns (address pool);

    function createGauge(address pool) external returns (address);

    function vote(
        uint256 tokenId,
        address[] calldata pools,
        int256[] calldata weights
    ) external;

    function whitelist(address token, uint256 tokenId) external;

    function listing_fee() external view returns (uint256);

    function _ve() external view returns (address);

    function isWhitelisted(address pool) external view returns (bool);

    function isGauge(address gaugeAddress) external view returns (bool);
}

pragma solidity 0.8.16;

import "./interfaces/monolith/ITokenBooster.sol";
import "./interfaces/solidly/IBaseV1Voter.sol";
import "./interfaces/solidly/IBaseV1Minter.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MonolithVoter is Initializable, OwnableUpgradeable {
    uint256 public tokenID;

    IBaseV1Voter public solidlyVoter;
    IBaseV1Minter public solidlyMinter;
    uint256 public solidlyMinterActivePeriod;

    ITokenBooster public tokenBooster;
    address public poolSetter;
    address public veDepositor;

    uint256 public constant WEEK = 1 weeks;
    uint256 public startTime;

    // the maximum number of pools to submit a vote for
    // must be low enough that `submitVotes` can submit the vote
    // data without the call reaching the block gas limit
    uint256 public constant MAX_SUBMITTED_VOTES = 50;

    // beyond the top `MAX_SUBMITTED_VOTES` pools, we also record several
    // more highest-voted pools. this mitigates against inaccuracies
    // in the lower end of the vote weights that can be caused by negative voting.
    uint256 public constant MAX_VOTES_WITH_BUFFER = MAX_SUBMITTED_VOTES + 10;

    // token -> week -> weight allocated
    mapping(address => mapping(uint256 => int256)) public poolVotes;
    // user -> week -> weight used
    mapping(address => mapping(uint256 => uint256)) public userVotes;

    // user -> week -> Votes
    mapping(address => mapping(uint256 => Vote[])) public userPoolVotes;

    address[2] public fixedVotePools;

    // [uint24 id][int40 poolVotes]
    // handled as an array of uint64 to allow memory-to-storage copy
    mapping(uint256 => uint64[MAX_VOTES_WITH_BUFFER]) public topVotes;

    address[] public poolAddresses;
    mapping(address => PoolData) public poolData;

    uint256 public lastWeek; // week of the last received vote (+1)
    uint256 public topVotesLength; // actual number of items stored in `topVotes`
    uint256 public minTopVote; // smallest vote-weight for pools included in `topVotes`
    uint256 public minTopVoteIndex; // `topVotes` index where the smallest vote is stored (+1)

    struct ProtectionData {
        address[2] pools;
        uint40 lastUpdate;
    }
    struct Vote {
        address pool;
        int256 weight;
    }
    struct PoolData {
        uint24 addressIndex;
        uint16 currentWeek;
        uint8 topVotesIndex;
    }

    event VotedForPoolIncentives(
        address indexed voter,
        address[] pools,
        int256[] voteWeights,
        uint256 usedWeight,
        uint256 totalWeight
    );
    event PoolProtectionSet(
        address address1,
        address address2,
        uint40 lastUpdate
    );
    event SubmittedVote(address caller, address[] pools, int256[] weights);

    function initialize(IBaseV1Voter _voter, IBaseV1Minter _minter)
        public
        initializer
    {
        __Ownable_init();

        solidlyVoter = _voter;
        solidlyMinter = _minter;
        solidlyMinterActivePeriod = solidlyMinter.active_period();

        // position 0 is empty so that an ID of 0 can be interpreted as unset
        poolAddresses.push(address(0));
    }

    function setAddresses(
        ITokenBooster _tokenLocker,
        address _poolSetter,
        address _veDepositor,
        address[2] calldata _fixedVotePools
    ) external onlyOwner {
        tokenBooster = _tokenLocker;
        poolSetter = _poolSetter;
        veDepositor = _veDepositor;
        startTime = _tokenLocker.startTime();

        // hardcoded pools always receive 5% of the vote
        // and cannot receive negative vote weights
        fixedVotePools = _fixedVotePools;
    }

    function setTokenID(uint256 _tokenID) external returns (bool) {
        require(msg.sender == veDepositor);
        tokenID = _tokenID;
        return true;
    }

    function getWeek() public view returns (uint256) {
        if (startTime == 0) return 0;
        return (block.timestamp - startTime) / 604800;
    }

    /**
        @notice The current pools and weights that would be submitted
                when calling `submitVotes`
     */
    function getCurrentVotes() external view returns (Vote[] memory votes) {
        (address[] memory pools, int256[] memory weights) = _currentVotes();
        votes = new Vote[](pools.length);
        for (uint256 i = 0; i < votes.length; i++) {
            votes[i] = Vote({pool: pools[i], weight: weights[i]});
        }
        return votes;
    }

    function getCurrentUserVotes(address _user)
        external
        view
        returns (Vote[] memory votes)
    {
        return userPoolVotes[_user][getWeek()];
    }

    /**
        @notice Get an account's unused vote weight for for the current week
        @param _user Address to query
        @return uint Amount of unused weight
     */
    function availableVotes(address _user) external view returns (uint256) {
        uint256 week = getWeek();
        uint256 usedWeight = userVotes[_user][week];
        uint256 totalWeight = tokenBooster.userWeight(_user) / 1e18;
        return totalWeight - usedWeight;
    }

    function _updateUserPoolVotes(
        address[] memory _pools,
        int256[] memory _weights
    ) internal {
        for (uint256 i = 0; i < _pools.length; i++) {
            userPoolVotes[msg.sender][getWeek()].push(
                Vote({pool: _pools[i], weight: _weights[i]})
            );
        }
    }

    function clearVotes() external {
        Vote[] memory votes = userPoolVotes[msg.sender][getWeek()];
        address[] memory pools = new address[](votes.length);
        int256[] memory weights = new int256[](votes.length);

        for (uint256 i = 0; i < votes.length; i++) {
            pools[i] = votes[i].pool;
            weights[i] = -votes[i].weight;
        }

        voteForPools(pools, weights);

        delete userPoolVotes[msg.sender][getWeek()];
    }

    /**
        @notice Vote for one or more pools
        @dev Vote-weights received via this function are aggregated but not sent to Solidly.
             To submit the vote to solidly you must call `submitVotes`.
             Voting does not carry over between weeks, votes must be resubmitted.
        @param _pools Array of pool addresses to vote for
        @param _weights Array of vote weights. Votes can be negative, the total weight calculated
                        from absolute values.
     */
    function voteForPools(address[] memory _pools, int256[] memory _weights)
        public
    {
        require(
            _pools.length == _weights.length,
            "_pools.length != _weights.length"
        );
        require(_pools.length > 0, "Must vote for at least one pool");

        _updateUserPoolVotes(_pools, _weights);

        uint256 week = getWeek();
        uint256 totalUserWeight = userVotes[msg.sender][week];

        // copy these values into memory to avoid repeated SLOAD / SSTORE ops
        uint256 _topVotesLengthMem = topVotesLength;
        uint256 _minTopVoteMem = minTopVote;
        uint256 _minTopVoteIndexMem = minTopVoteIndex;
        uint64[MAX_VOTES_WITH_BUFFER] memory t = topVotes[week];

        if (week + 1 > lastWeek) {
            _topVotesLengthMem = 0;
            _minTopVoteMem = 0;
            lastWeek = week + 1;
        }
        for (uint256 x = 0; x < _pools.length; x++) {
            address _pool = _pools[x];
            int256 _weight = _weights[x];

            // so user can take his votes back by negative weight
            totalUserWeight = uint256(int256(totalUserWeight) + _weight);

            require(_weight != 0, "Cannot vote zero");

            // update accounting for this week's votes
            int256 poolWeight = poolVotes[_pool][week];
            uint256 id = poolData[_pool].addressIndex;
            if (poolWeight == 0 || poolData[_pool].currentWeek <= week) {
                require(
                    solidlyVoter.gauges(_pool) != address(0),
                    "Pool has no gauge"
                );
                if (id == 0) {
                    id = poolAddresses.length;
                    poolAddresses.push(_pool);
                }
                poolData[_pool] = PoolData({
                    addressIndex: uint24(id),
                    currentWeek: uint16(week + 1),
                    topVotesIndex: 0
                });
            }

            int256 newPoolWeight = poolWeight + _weight;
            require(newPoolWeight >= 0, "Pool weight cannot be negative");

            uint256 absNewPoolWeight = abs(newPoolWeight);
            assert(absNewPoolWeight < 2**39); // this should never be possible

            poolVotes[_pool][week] = newPoolWeight;

            if (poolData[_pool].topVotesIndex > 0) {
                // pool already exists within the list
                uint256 voteIndex = poolData[_pool].topVotesIndex - 1;

                if (newPoolWeight == 0) {
                    // pool has a new vote-weight of 0 and so is being removed
                    poolData[_pool] = PoolData({
                        addressIndex: uint24(id),
                        currentWeek: 0,
                        topVotesIndex: 0
                    });
                    _topVotesLengthMem -= 1;
                    if (voteIndex == _topVotesLengthMem) {
                        delete t[voteIndex];
                    } else {
                        t[voteIndex] = t[_topVotesLengthMem];
                        uint256 addressIndex = t[voteIndex] >> 40;
                        poolData[poolAddresses[addressIndex]]
                            .topVotesIndex = uint8(voteIndex + 1);
                        delete t[_topVotesLengthMem];
                        if (_minTopVoteIndexMem > _topVotesLengthMem) {
                            // the value we just shifted was the minimum weight
                            _minTopVoteIndexMem = voteIndex + 1;
                            // continue here to avoid iterating to locate the new min index
                            continue;
                        }
                    }
                } else {
                    // modify existing record for this pool within `topVotes`
                    t[voteIndex] = pack(id, newPoolWeight);
                    if (absNewPoolWeight < _minTopVoteMem) {
                        // if new weight is also the new minimum weight
                        _minTopVoteMem = absNewPoolWeight;
                        _minTopVoteIndexMem = voteIndex + 1;
                        // continue here to avoid iterating to locate the new min voteIndex
                        continue;
                    }
                }
                if (voteIndex == _minTopVoteIndexMem - 1) {
                    // iterate to find the new minimum weight
                    (_minTopVoteMem, _minTopVoteIndexMem) = _findMinTopVote(
                        t,
                        _topVotesLengthMem
                    );
                }
            } else if (_topVotesLengthMem < MAX_VOTES_WITH_BUFFER) {
                // pool is not in `topVotes`, and `topVotes` contains less than
                // MAX_VOTES_WITH_BUFFER items, append
                t[_topVotesLengthMem] = pack(id, newPoolWeight);
                _topVotesLengthMem += 1;
                poolData[_pool].topVotesIndex = uint8(_topVotesLengthMem);
                if (absNewPoolWeight < _minTopVoteMem || _minTopVoteMem == 0) {
                    // new weight is the new minimum weight
                    _minTopVoteMem = absNewPoolWeight;
                    _minTopVoteIndexMem = poolData[_pool].topVotesIndex;
                }
            } else if (absNewPoolWeight > _minTopVoteMem) {
                // `topVotes` contains MAX_VOTES_WITH_BUFFER items,
                // pool is not in the array, and weight exceeds current minimum weight

                // replace the pool at the current minimum weight index
                uint256 addressIndex = t[_minTopVoteIndexMem - 1] >> 40;
                poolData[poolAddresses[addressIndex]] = PoolData({
                    addressIndex: uint24(addressIndex),
                    currentWeek: 0,
                    topVotesIndex: 0
                });
                t[_minTopVoteIndexMem - 1] = pack(id, newPoolWeight);
                poolData[_pool].topVotesIndex = uint8(_minTopVoteIndexMem);

                // iterate to find the new minimum weight
                (_minTopVoteMem, _minTopVoteIndexMem) = _findMinTopVote(
                    t,
                    MAX_VOTES_WITH_BUFFER
                );
            }
        }

        // make sure user has not exceeded available weight
        uint256 totalWeight = tokenBooster.userWeight(msg.sender) / 1e18;
        require(totalUserWeight <= totalWeight, "Available votes exceeded");

        // write memory vars back to storage
        topVotes[week] = t;
        topVotesLength = _topVotesLengthMem;
        minTopVote = _minTopVoteMem;
        minTopVoteIndex = _minTopVoteIndexMem;
        userVotes[msg.sender][week] = totalUserWeight;

        emit VotedForPoolIncentives(
            msg.sender,
            _pools,
            _weights,
            totalUserWeight,
            totalWeight
        );
    }

    /**
        @notice Submit the current votes to Solidly
        @dev This function is unguarded and so votes may be submitted at any time.
             Solidly has no restriction on the frequency that an account may vote,
             however emissions are only calculated from the active votes at the
             beginning of each epoch week.
     */
    function submitVotes() external returns (bool) {
        (address[] memory pools, int256[] memory weights) = _currentVotes();
        solidlyVoter.vote(tokenID, pools, weights);
        emit SubmittedVote(msg.sender, pools, weights);
        return true;
    }

    function _currentVotes()
        internal
        view
        returns (address[] memory pools, int256[] memory weights)
    {
        uint256 week = getWeek();
        uint256 length = 2; // length is always +2 to ensure room for the hardcoded gauges
        if (
            week + 1 == lastWeek &&
            solidlyMinter.active_period() > solidlyMinterActivePeriod
        ) {
            // `lastWeek` only updates on a call to `voteForPool`
            // if the current week is > `lastWeek`, there have not been any votes this week
            length += topVotesLength;
        }

        uint256[MAX_VOTES_WITH_BUFFER] memory absWeights;
        pools = new address[](length);
        weights = new int256[](length);

        // unpack `topVotes`
        for (uint256 i = 0; i < length - 2; i++) {
            (uint256 id, int256 weight) = unpack(topVotes[week][i]);
            pools[i] = poolAddresses[id];
            weights[i] = weight;
            absWeights[i] = abs(weight);
        }

        // if more than `MAX_SUBMITTED_VOTES` pools have votes, discard the lowest weights
        if (length > MAX_SUBMITTED_VOTES + 2) {
            while (length > MAX_SUBMITTED_VOTES + 2) {
                uint256 minValue = type(uint256).max;
                uint256 minIndex = 0;
                for (uint256 i = 0; i < length - 2; i++) {
                    uint256 weight = absWeights[i];
                    if (weight < minValue) {
                        minValue = weight;
                        minIndex = i;
                    }
                }
                uint256 idx = length - 3;
                weights[minIndex] = weights[idx];
                pools[minIndex] = pools[idx];
                absWeights[minIndex] = absWeights[idx];
                delete weights[idx];
                delete pools[idx];
                length -= 1;
            }
            assembly {
                mstore(pools, length)
                mstore(weights, length)
            }
        }

        // calculate absolute total weight and find the indexes for the hardcoded pools
        uint256 totalWeight;
        uint256[2] memory fixedVoteIds;
        address[2] memory _fixedVotePools = fixedVotePools;
        for (uint256 i = 0; i < length - 2; i++) {
            totalWeight += absWeights[i];
            if (pools[i] == _fixedVotePools[0]) fixedVoteIds[0] = i + 1;
            else if (pools[i] == _fixedVotePools[1]) fixedVoteIds[1] = i + 1;
        }

        // add 5% hardcoded vote
        int256 fixedWeight = int256((totalWeight * 11) / 200);
        if (fixedWeight == 0) fixedWeight = 1;
        length -= 2;
        for (uint256 i = 0; i < 2; i++) {
            if (fixedVoteIds[i] == 0) {
                pools[length + i] = _fixedVotePools[i];
                weights[length + i] = fixedWeight;
            } else {
                weights[fixedVoteIds[i] - 1] += fixedWeight;
            }
        }

        return (pools, weights);
    }

    function _findMinTopVote(
        uint64[MAX_VOTES_WITH_BUFFER] memory t,
        uint256 length
    ) internal pure returns (uint256, uint256) {
        uint256 _minTopVoteMem = type(uint256).max;
        uint256 _minTopVoteIndexMem;
        for (uint256 i = 0; i < length; i++) {
            uint256 value = t[i] % 2**39;
            if (value < _minTopVoteMem) {
                _minTopVoteMem = value;
                _minTopVoteIndexMem = i + 1;
            }
        }
        return (_minTopVoteMem, _minTopVoteIndexMem);
    }

    function abs(int256 value) internal pure returns (uint256) {
        return uint256(value > 0 ? value : -value);
    }

    function pack(uint256 id, int256 weight) internal pure returns (uint64) {
        // tightly pack as [uint24 id][int40 weight] for storage in `topVotes`
        uint64 value = uint64((id << 40) + abs(weight));
        if (weight < 0) value += 2**39;
        return value;
    }

    function unpack(uint256 value)
        internal
        pure
        returns (uint256 id, int256 weight)
    {
        // unpack a value in `topVotes`
        id = (value >> 40);
        weight = int256(value % 2**40);
        if (weight > 2**39) weight = -(weight % 2**39);
        return (id, weight);
    }
}