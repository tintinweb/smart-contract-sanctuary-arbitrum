// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
pragma solidity ^0.8.13;

interface IFeeDistributor {
    function _deposit(uint amount, uint tokenId) external;

    function _withdraw(uint amount, uint tokenId) external;

    function getRewardForOwner(uint tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint amount) external;

    function getRewardTokens() external view returns (address[] memory);

    function earned(
        address token,
        uint256 tokenId
    ) external view returns (uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint claimed0, uint claimed1);

    function left(address token) external view returns (uint);

    function isForPair() external view returns (bool);

    function whitelistNotifiedRewards(address token) external;

    function removeRewardWhitelist(address token) external;

    function rewardsListLength() external view returns (uint256);

    function rewards(uint256 index) external view returns (address);

    function earned(
        address token,
        address account
    ) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function derivedBalances(address) external view returns (uint256);

    function rewardRate(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "contracts/interfaces/IRewardsDistributor.sol";

interface IMinter {
    function update_period() external returns (uint);

    function active_period() external view returns (uint);

    function _rewards_distributor() external view returns (IRewardsDistributor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13 || =0.7.6;

interface IPair {
    function initialize(
        address _token0,
        address _token1,
        bool _stable
    ) external;

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        );

    function claimFees() external returns (uint256, uint256);

    function tokens() external view returns (address, address);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function fees() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPairFactory {
    function allPairsLength() external view returns (uint);

    function isPair(address pair) external view returns (bool);

    function pairCodeHash() external view returns (bytes32);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);

    function voter() external view returns (address);

    function allPairs(uint256) external view returns (address);

    function pairFee(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRewardsDistributor {
    function checkpoint_token() external;

    function checkpoint_total_supply() external;

    function claimable(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVoter {
    function _ve() external view returns (address);

    function governor() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function attachTokenToGauge(uint _tokenId, address account) external;

    function detachTokenFromGauge(uint _tokenId, address account) external;

    function emitDeposit(uint _tokenId, address account, uint amount) external;

    function emitWithdraw(uint _tokenId, address account, uint amount) external;

    function isWhitelisted(address token) external view returns (bool);

    function notifyRewardAmount(uint amount) external;

    function distribute(address _gauge) external;

    function gauges(address pool) external view returns (address);

    function feeDistributers(address gauge) external view returns (address);

    function gaugefactory() external view returns (address);

    function feeDistributorFactory() external view returns (address);

    function minter() external view returns (address);

    function factory() external view returns (address);

    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function token() external view returns (address);

    function team() external returns (address);

    function epoch() external view returns (uint);

    function point_history(uint loc) external view returns (Point memory);

    function user_point_history(
        uint tokenId,
        uint loc
    ) external view returns (Point memory);

    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function isApprovedOrOwner(address, uint) external view returns (bool);

    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;

    function abstain(uint tokenId) external;

    function attach(uint tokenId) external;

    function detach(uint tokenId) external;

    function checkpoint() external;

    function deposit_for(uint tokenId, uint value) external;

    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);

    function balanceOfNFTAt(uint, uint) external view returns (uint);

    function totalSupply() external view returns (uint);

    function locked__end(uint) external view returns (uint);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address,
        uint256
    ) external view returns (uint256);

    function locked(uint256) external view returns (LockedBalance memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IPairFactory.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IGauge.sol";
import "contracts/interfaces/IRewardsDistributor.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RamsesLens is Initializable {
    IVoter voter;
    IVotingEscrow ve;
    IMinter minter;

    address public router; // router address

    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0;
        address token1;
        address gauge;
        address feeDistributor;
        address pairFees;
        uint pairBps;
    }

    struct ProtocolMetadata {
        address veAddress;
        address ramAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
    }

    struct vePosition {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct tokenRewardData {
        address token;
        uint rewardRate;
    }

    struct gaugeRewardsData {
        address gauge;
        tokenRewardData[] rewardData;
    }

    // user earned per token
    struct userGaugeTokenData {
        address token;
        uint earned;
    }

    struct userGaugeRewardData {
        address gauge;
        uint balance;
        uint derivedBalance;
        userGaugeTokenData[] userRewards;
    }

    // user earned per token for feeDist
    struct userBribeTokenData {
        address token;
        uint earned;
    }

    struct userFeeDistData {
        address feeDistributor;
        userBribeTokenData[] bribeData;
    }
    // the amount of nested structs for bribe lmao
    struct userBribeData {
        uint tokenId;
        userFeeDistData[] feeDistRewards;
    }

    struct userVeData {
        uint tokenId;
        uint lockedAmount;
        uint votingPower;
        uint lockEnd;
    }

    struct Earned {
        address poolAddress;
        address token;
        uint256 amount;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IVoter _voter, address _router) external initializer {
        voter = _voter;
        router = _router;
        ve = IVotingEscrow(voter._ve());
        minter = IMinter(voter.minter());
    }

    /**
     * @notice returns the pool factory address
     */
    function poolFactory() public view returns (address pool) {
        pool = voter.factory();
    }

    /**
     * @notice returns the gauge factory address
     */
    function gaugeFactory() public view returns (address _gaugeFactory) {
        _gaugeFactory = voter.gaugefactory();
    }

    /**
     * @notice returns the fee distributor factory address
     */
    function feeDistributorFactory()
        public
        view
        returns (address _gaugeFactory)
    {
        _gaugeFactory = voter.feeDistributorFactory();
    }

    /**
     * @notice returns ram address
     */
    function ramAddress() public view returns (address ram) {
        ram = ve.token();
    }

    /**
     * @notice returns the voter address
     */
    function voterAddress() public view returns (address _voter) {
        _voter = address(voter);
    }

    /**
     * @notice returns rewardsDistributor address
     */
    function rewardsDistributor()
        public
        view
        returns (address _rewardsDistributor)
    {
        _rewardsDistributor = address(minter._rewards_distributor());
    }

    /**
     * @notice returns the minter address
     */
    function minterAddress() public view returns (address _minter) {
        _minter = address(minter);
    }

    /**
     * @notice returns Ramses core contract addresses
     */
    function protocolMetadata()
        external
        view
        returns (ProtocolMetadata memory)
    {
        return
            ProtocolMetadata({
                veAddress: voter._ve(),
                voterAddress: voterAddress(),
                ramAddress: ramAddress(),
                poolsFactoryAddress: poolFactory(),
                gaugesFactoryAddress: gaugeFactory(),
                minterAddress: minterAddress()
            });
    }

    /**
     * @notice returns all Ramses pool addresses
     */
    function allPools() public view returns (address[] memory pools) {
        IPairFactory _factory = IPairFactory(poolFactory());
        uint len = _factory.allPairsLength();

        pools = new address[](len);
        for (uint i; i < len; ++i) {
            pools[i] = _factory.allPairs(i);
        }
    }

    /**
     * @notice returns all Ramses pools that have active gauges
     */
    function allActivePools() public view returns (address[] memory pools) {
        uint len = voter.length();
        pools = new address[](len);

        for (uint i; i < len; ++i) {
            pools[i] = voter.pools(i);
        }
    }

    /**
     * @notice returns the gauge address for a pool
     * @param pool pool address to check
     */
    function gaugeForPool(address pool) public view returns (address gauge) {
        gauge = voter.gauges(pool);
    }

    /**
     * @notice returns the feeDistributor address for a pool
     * @param pool pool address to check
     */
    function feeDistributorForPool(
        address pool
    ) public view returns (address feeDistributor) {
        address gauge = gaugeForPool(pool);
        feeDistributor = voter.feeDistributers(gauge);
    }

    /**
     * @notice returns current fee rate of a ramses pool
     * @param pool pool address to check
     */
    function pairBps(address pool) public view returns (uint bps) {
        bps = IPairFactory(poolFactory()).pairFee(pool);
    }

    /**
     * @notice returns useful information for a pool
     * @param pool pool address to check
     */
    function poolInfo(
        address pool
    ) public view returns (Pool memory _poolInfo) {
        IPair pair = IPair(pool);
        _poolInfo.id = pool;
        _poolInfo.symbol = pair.symbol();
        (_poolInfo.token0, _poolInfo.token1) = pair.tokens();
        _poolInfo.gauge = gaugeForPool(pool);
        _poolInfo.feeDistributor = feeDistributorForPool(pool);
        _poolInfo.pairFees = pair.fees();
        _poolInfo.pairBps = pairBps(pool);
    }

    /**
     * @notice returns useful information for all Ramses pools
     */
    function allPoolsInfo() public view returns (Pool[] memory _poolsInfo) {
        address[] memory pools = allPools();
        uint len = pools.length;

        _poolsInfo = new Pool[](len);
        for (uint i; i < len; ++i) {
            _poolsInfo[i] = poolInfo(pools[i]);
        }
    }

    /**
     * @notice returns the gauge address for all active pairs
     */
    function allGauges() public view returns (address[] memory gauges) {
        address[] memory pools = allActivePools();
        uint len = pools.length;
        gauges = new address[](len);

        for (uint i; i < len; ++i) {
            gauges[i] = gaugeForPool(pools[i]);
        }
    }

    /**
     * @notice returns the feeDistributor address for all active pairs
     */
    function allFeeDistributors()
        public
        view
        returns (address[] memory feeDistributors)
    {
        address[] memory pools = allActivePools();
        uint len = pools.length;
        feeDistributors = new address[](len);

        for (uint i; i < len; ++i) {
            feeDistributors[i] = feeDistributorForPool(pools[i]);
        }
    }

    /**
     * @notice returns all reward tokens for the fee distributor of a pool
     * @param pool pool address to check
     */
    function bribeRewardsForPool(
        address pool
    ) public view returns (address[] memory rewards) {
        IFeeDistributor feeDist = IFeeDistributor(feeDistributorForPool(pool));
        rewards = feeDist.getRewardTokens();
    }

    /**
     * @notice returns all reward tokens for the gauge of a pool
     * @param pool pool address to check
     */
    function gaugeRewardsForPool(
        address pool
    ) public view returns (address[] memory rewards) {
        IGauge gauge = IGauge(gaugeForPool(pool));
        if (address(gauge) == address(0)) return rewards;

        uint len = gauge.rewardsListLength();
        rewards = new address[](len);
        for (uint i; i < len; ++i) {
            rewards[i] = gauge.rewards(i);
        }
    }

    /**
     * @notice returns all token id's of a user
     * @param user account address to check
     */
    function veNFTsOf(address user) public view returns (uint[] memory NFTs) {
        uint len = ve.balanceOf(user);
        NFTs = new uint[](len);

        for (uint i; i < len; ++i) {
            NFTs[i] = ve.tokenOfOwnerByIndex(user, i);
        }
    }

    /**
     * @notice returns bribes data of a token id per pool
     * @param tokenId the veNFT token id to check
     * @param pool the pool address
     */
    function bribesPositionOf(
        uint tokenId,
        address pool
    ) public view returns (userFeeDistData memory rewardsData) {
        IFeeDistributor feeDist = IFeeDistributor(feeDistributorForPool(pool));
        if (address(feeDist) == address(0)) {
            return rewardsData;
        }

        address[] memory rewards = bribeRewardsForPool(pool);
        uint len = rewards.length;

        rewardsData.feeDistributor = address(feeDist);
        userBribeTokenData[] memory _userRewards = new userBribeTokenData[](
            len
        );

        for (uint i; i < len; ++i) {
            _userRewards[i].token = rewards[i];
            _userRewards[i].earned = feeDist.earned(rewards[i], tokenId);
        }
        rewardsData.bribeData = _userRewards;
    }

    /**
     * @notice returns gauge reward data for a Ramses pool
     * @param pool Ramses pool address
     */
    function poolRewardsData(
        address pool
    ) public view returns (gaugeRewardsData memory rewardData) {
        address gauge = gaugeForPool(pool);
        if (gauge == address(0)) {
            return rewardData;
        }

        address[] memory rewards = gaugeRewardsForPool(pool);
        uint len = rewards.length;
        tokenRewardData[] memory _rewardData = new tokenRewardData[](len);

        for (uint i; i < len; ++i) {
            _rewardData[i].token = rewards[i];
            _rewardData[i].rewardRate = IGauge(gauge).rewardRate(rewards[i]);
        }
        rewardData.gauge = gauge;
        rewardData.rewardData = _rewardData;
    }

    /**
     * @notice returns gauge reward data for multiple ramses pools
     * @param pools Ramses pools addresses
     */
    function poolsRewardsData(
        address[] memory pools
    ) public view returns (gaugeRewardsData[] memory rewardsData) {
        uint len = pools.length;
        rewardsData = new gaugeRewardsData[](len);

        for (uint i; i < len; ++i) {
            rewardsData[i] = poolRewardsData(pools[i]);
        }
    }

    /**
     * @notice returns gauge reward data for all ramses pools
     */
    function allPoolsRewardData()
        public
        view
        returns (gaugeRewardsData[] memory rewardsData)
    {
        address[] memory pools = allActivePools();
        rewardsData = poolsRewardsData(pools);
    }

    /**
     * @notice returns veNFT lock data for a token id
     * @param user account address of the user
     */
    function vePositionsOf(
        address user
    ) public view returns (userVeData[] memory veData) {
        uint[] memory ids = veNFTsOf(user);
        uint len = ids.length;
        veData = new userVeData[](len);

        for (uint i; i < len; ++i) {
            veData[i].tokenId = ids[i];
            IVotingEscrow.LockedBalance memory _locked = ve.locked(ids[i]);
            veData[i].lockedAmount = uint(int(_locked.amount));
            veData[i].lockEnd = _locked.end;
            veData[i].votingPower = ve.balanceOfNFT(ids[i]);
        }
    }

    function tokenIdEarned(
        uint256 tokenId,
        address[] memory poolAddresses,
        address[][] memory rewardTokens,
        uint256 maxReturn
    ) external view returns (Earned[] memory earnings) {
        earnings = new Earned[](maxReturn);
        uint256 earningsIndex = 0;
        uint256 amount;

        for (uint256 i; i < poolAddresses.length; ++i) {
            IGauge gauge = IGauge(voter.gauges(poolAddresses[i]));

            if (address(gauge) != address(0)) {
                IFeeDistributor feeDistributor = IFeeDistributor(
                    voter.feeDistributers(address(gauge))
                );

                for (uint256 j; j < rewardTokens[i].length; ++j) {
                    amount = feeDistributor.earned(rewardTokens[i][j], tokenId);
                    if (amount > 0) {
                        earnings[earningsIndex++] = Earned({
                            poolAddress: poolAddresses[i],
                            token: rewardTokens[i][j],
                            amount: amount
                        });
                        require(
                            earningsIndex < maxReturn,
                            "Increase maxReturn"
                        );
                    }
                }
            }
        }
    }

    function addressEarned(
        address user,
        address[] memory poolAddresses,
        uint256 maxReturn
    ) external view returns (Earned[] memory earnings) {
        earnings = new Earned[](maxReturn);
        uint256 earningsIndex = 0;
        uint256 amount;

        for (uint256 i; i < poolAddresses.length; ++i) {
            IGauge gauge = IGauge(voter.gauges(poolAddresses[i]));

            if (address(gauge) != address(0)) {
                uint256 tokensCount = gauge.rewardsListLength();
                for (uint256 j; j < tokensCount; ++j) {
                    address token = gauge.rewards(j);
                    amount = gauge.earned(token, user);
                    if (amount > 0) {
                        earnings[earningsIndex++] = Earned({
                            poolAddress: poolAddresses[i],
                            token: token,
                            amount: amount
                        });
                        require(
                            earningsIndex < maxReturn,
                            "Increase maxReturn"
                        );
                    }
                }
            }
        }
    }

    function tokenIdRebase(
        uint256 tokenId
    ) external view returns (uint256 rebase) {
        rebase = IRewardsDistributor(rewardsDistributor()).claimable(tokenId);
    }
}