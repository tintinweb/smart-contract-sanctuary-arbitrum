// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@equilibria/root/attribute/Instance.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProviderFactory.sol";
import "./interfaces/IOracle.sol";

/// @title Oracle
/// @notice The top-level oracle contract that implements an oracle provider interface.
/// @dev Manages swapping between different underlying oracle provider interfaces over time.
contract Oracle is IOracle, Instance {
    /// @notice A historical mapping of underlying oracle providers
    mapping(uint256 => Epoch) public oracles;

    /// @notice The global state of the oracle
    Global public global;

    /// @notice Initializes the contract state
    /// @param initialProvider The initial oracle provider
    function initialize(IOracleProvider initialProvider) external initializer(1) {
        __Instance__initialize();
        _updateCurrent(initialProvider);
        _updateLatest(initialProvider.latest());
    }

    /// @notice Updates the current oracle provider
    /// @dev Both the current and new oracle provider must have the same current
    /// @param newProvider The new oracle provider
    function update(IOracleProvider newProvider) external {
        if (msg.sender != address(factory())) revert OracleNotFactoryError();
        _updateCurrent(newProvider);
        _updateLatest(newProvider.latest());
    }

    /// @notice Requests a new version at the current timestamp
    /// @param account Original sender to optionally use for callbacks
    function request(address account) external onlyAuthorized {
        (OracleVersion memory latestVersion, uint256 currentTimestamp) = oracles[global.current].provider.status();

        oracles[
            (currentTimestamp > oracles[global.latest].timestamp) ? global.current : global.latest
        ].provider.request(account);

        oracles[global.current].timestamp = uint96(currentTimestamp);
        _updateLatest(latestVersion);
    }

    /// @notice Returns the latest committed version as well as the current timestamp
    /// @return latestVersion The latest committed version
    /// @return currentTimestamp The current timestamp
    function status() external view returns (OracleVersion memory latestVersion, uint256 currentTimestamp) {
        (latestVersion, currentTimestamp) = oracles[global.current].provider.status();
        latestVersion = _handleLatest(latestVersion);
    }

    /// @notice Returns the latest committed version
    function latest() public view returns (OracleVersion memory) {
        return _handleLatest(oracles[global.current].provider.latest());
    }

    /// @notice Returns the current value
    function current() public view returns (uint256) {
        return oracles[global.current].provider.current();
    }

    /// @notice Returns the oracle version at a given timestamp
    /// @param timestamp The timestamp to query
    /// @return atVersion The oracle version at the given timestamp
    function at(uint256 timestamp) public view returns (OracleVersion memory atVersion) {
        if (timestamp == 0) return atVersion;
        IOracleProvider provider = oracles[global.current].provider;
        for (uint256 i = global.current - 1; i > 0; i--) {
            if (timestamp > uint256(oracles[i].timestamp)) break;
            provider = oracles[i].provider;
        }
        return provider.at(timestamp);
    }

    /// @notice Handles update the oracle to the new provider
    /// @param newProvider The new oracle provider
    function _updateCurrent(IOracleProvider newProvider) private {
        // oracle must not already be updating
        if (global.current != global.latest) revert OracleOutOfSyncError();

        // if the latest version of the underlying oracle is further ahead than its latest request update its timestamp
        if (global.current != 0) {
            OracleVersion memory latestVersion = oracles[global.current].provider.latest();
            if (latestVersion.timestamp > oracles[global.current].timestamp)
                oracles[global.current].timestamp = uint96(latestVersion.timestamp);
        }

        // add the new oracle registration
        oracles[++global.current] = Epoch(newProvider, uint96(newProvider.current()));
        emit OracleUpdated(newProvider);
    }

    /// @notice Handles updating the latest oracle to the current if it is ready
    /// @param currentOracleLatestVersion The latest version from the current oracle
    function _updateLatest(OracleVersion memory currentOracleLatestVersion) private {
        if (_latestStale(currentOracleLatestVersion)) global.latest = global.current;
    }

    /// @notice Handles overriding the latest version
    /// @dev Applicable if we haven't yet switched over to the current oracle from the latest oracle
    /// @param currentOracleLatestVersion The latest version from the current oracle
    /// @return latestVersion The latest version
    function _handleLatest(
        OracleVersion memory currentOracleLatestVersion
    ) private view returns (OracleVersion memory latestVersion) {
        if (global.current == global.latest) return currentOracleLatestVersion;

        bool isLatestStale = _latestStale(currentOracleLatestVersion);
        latestVersion = isLatestStale ? currentOracleLatestVersion : oracles[global.latest].provider.latest();

        uint256 latestOracleTimestamp =
            uint256(isLatestStale ? oracles[global.current].timestamp : oracles[global.latest].timestamp);
        if (!isLatestStale && latestVersion.timestamp > latestOracleTimestamp)
            return at(latestOracleTimestamp);
    }

    /// @notice Returns whether the latest oracle is ready to be updated
    /// @param currentOracleLatestVersion The latest version from the current oracle
    /// @return Whether the latest oracle is ready to be updated
    function _latestStale(OracleVersion memory currentOracleLatestVersion) private view returns (bool) {
        if (global.current == global.latest) return false;
        if (global.latest == 0) return true;

        if (uint256(oracles[global.latest].timestamp) > oracles[global.latest].provider.latest().timestamp) return false;
        if (uint256(oracles[global.latest].timestamp) >= currentOracleLatestVersion.timestamp) return false;

        return true;
    }

    /// @dev Only if the caller is authorized by the factory
    modifier onlyAuthorized {
        if (!IOracleProviderFactory(address(factory())).authorized(msg.sender))
            revert OracleProviderUnauthorizedError();
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProvider.sol";

interface IOracle is IOracleProvider, IInstance {
    // sig: 0xb9d5b7c9
    error OracleNotFactoryError();
    // sig: 0x8852e53b
    error OracleOutOfSyncError();
    // sig: 0x0f7338e5
    error OracleOutOfOrderCommitError();

    event OracleUpdated(IOracleProvider newProvider);

    /// @dev The state for a single epoch
    struct Epoch {
        /// @dev The oracle provider for this epoch
        IOracleProvider provider;

        /// @dev The last timestamp that this oracle provider is valid
        uint96 timestamp;
    }

    /// @dev The global state for oracle
    struct Global {
        /// @dev The current epoch
        uint128 current;

        /// @dev The latest epoch
        uint128 latest;
    }

    function initialize(IOracleProvider initialProvider) external;
    function update(IOracleProvider newProvider) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../types/OracleVersion.sol";

/// @dev OracleVersion Invariants
///       - Each newly requested version must be increasing, but does not need to incrementing
///         - We recommend using something like timestamps or blocks for versions so that intermediary non-requested
///           versions may be posted for the purpose of expedient liquidations
///       - Versions are allowed to "fail" and will be marked as .valid = false
///       - Versions must be committed in order, i.e. all requested versions prior to latestVersion must be available
///       - Non-requested versions may be committed, but will not receive a keeper reward
///         - This is useful for immediately liquidating an account with a valid off-chain price in between orders
///         - Satisfying the above constraints, only versions more recent than the latest version may be committed
///       - Current must always be greater than Latest, never equal
///       - Request must register the same current version that was returned by Current within the same transaction
interface IOracleProvider {
    // sig: 0x652fafab
    error OracleProviderUnauthorizedError();

    event OracleProviderVersionRequested(uint256 indexed version);
    event OracleProviderVersionFulfilled(uint256 indexed version);

    function request(address account) external;
    function status() external view returns (OracleVersion memory, uint256);
    function latest() external view returns (OracleVersion memory);
    function current() external view returns (uint256);
    function at(uint256 timestamp) external view returns (OracleVersion memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../types/OracleVersion.sol";
import "./IOracleProvider.sol";

interface IOracleProviderFactory {
    event OracleCreated(IOracleProvider indexed oracle, bytes32 indexed id);

    function oracles(bytes32 id) external view returns (IOracleProvider);
    function authorized(address caller) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";

/// @dev A singular oracle version with its corresponding data
struct OracleVersion {
    /// @dev the timestamp of the oracle update
    uint256 timestamp;

    /// @dev The oracle price of the corresponding version
    Fixed6 price;

    /// @dev Whether the version is valid
    bool valid;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IInitializable.sol";
import "../storage/Storage.sol";

/**
 * @title Initializable
 * @notice Library to manage the initialization lifecycle of upgradeable contracts
 * @dev `Initializable.sol` allows the creation of pseudo-constructors for upgradeable contracts. One
 *      `initializer` should be declared per top-level contract. Child contracts can use the `onlyInitializer`
 *      modifier to tag their internal initialization functions to ensure that they can only be called
 *      from a top-level `initializer` or a constructor.
 */
abstract contract Initializable is IInitializable {
    /// @dev The initialized flag
    Uint256Storage private constant _version = Uint256Storage.wrap(keccak256("equilibria.root.Initializable.version"));

    /// @dev The initializing flag
    BoolStorage private constant _initializing = BoolStorage.wrap(keccak256("equilibria.root.Initializable.initializing"));

    /// @dev Can only be called once per version, `version` is 1-indexed
    modifier initializer(uint256 version) {
        if (version == 0) revert InitializableZeroVersionError();
        if (_version.read() >= version) revert InitializableAlreadyInitializedError(version);

        _version.store(version);
        _initializing.store(true);

        _;

        _initializing.store(false);
        emit Initialized(version);
    }

    /// @dev Can only be called from an initializer or constructor
    modifier onlyInitializer() {
        if (!_constructing() && !_initializing.read()) revert InitializableNotInitializingError();
        _;
    }

    /**
     * @notice Returns whether the contract is currently being constructed
     * @dev {Address.isContract} returns false for contracts currently in the process of being constructed
     * @return Whether the contract is currently being constructed
     */
    function _constructing() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../storage/Storage.sol";
import "./interfaces/IInstance.sol";
import "./Initializable.sol";

/// @title Instance
/// @notice An abstract contract that is created and managed by a factory
abstract contract Instance is IInstance, Initializable {
    /// @dev The factory address storage slot
    AddressStorage private constant _factory = AddressStorage.wrap(keccak256("equilibria.root.Instance.factory"));

    /// @notice Returns the factory that created this instance
    /// @return The factory that created this instance
    function factory() public view returns (IFactory) { return IFactory(_factory.read()); }

    /// @notice Initializes the contract setting `msg.sender` as the factory
    function __Instance__initialize() internal onlyInitializer {
        _factory.store(msg.sender);
    }

    /// @notice Only allow the owner defined by the factory to call the function
    modifier onlyOwner {
        if (msg.sender != factory().owner()) revert InstanceNotOwnerError(msg.sender);
        _;
    }

    /// @notice Only allow the function to be called when the factory is not paused
    modifier whenNotPaused {
        if (factory().paused()) revert InstancePausedError();
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "./IPausable.sol";
import "./IInstance.sol";

interface IFactory is IBeacon, IOwnable, IPausable {
    event InstanceRegistered(IInstance indexed instance);

    error FactoryNotInstanceError();

    function instances(IInstance instance) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IInitializable {
    error InitializableZeroVersionError();
    error InitializableAlreadyInitializedError(uint256 version);
    error InitializableNotInitializingError();

    event Initialized(uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IFactory.sol";
import "./IInitializable.sol";

interface IInstance is IInitializable {
    error InstanceNotOwnerError(address sender);
    error InstancePausedError();

    function factory() external view returns (IFactory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";

interface IOwnable is IInitializable {
    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error OwnableNotOwnerError(address sender);
    error OwnableNotPendingOwnerError(address sender);

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updatePendingOwner(address newPendingOwner) external;
    function acceptOwner() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";
import "./IOwnable.sol";

interface IPausable is IInitializable, IOwnable {
    event PauserUpdated(address indexed newPauser);
    event Paused();
    event Unpaused();

    error PausablePausedError();
    error PausableNotPauserError(address sender);

    function pauser() external view returns (address);
    function paused() external view returns (bool);
    function updatePauser(address newPauser) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

/**
 * @title NumberMath
 * @notice Library for additional math functions that are not included in the OpenZeppelin libraries.
 */
library NumberMath {
    error DivisionByZero();

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return Math.ceilDiv(a, b);
    }

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(int256 a, int256 b) internal pure returns (int256) {
        return sign(a) * sign(b) * int256(divOut(SignedMath.abs(a), SignedMath.abs(b)));
    }

    /**
     * @notice Returns the sign of an int256
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a int256 to find the sign of
     * @return Sign of the int256
     */
    function sign(int256 a) internal pure returns (int256) {
        if (a > 0) return 1;
        if (a < 0) return -1;
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed18.wrap(-1 * Fixed18.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldivOut(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), Fixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev Fixed6 type
type Fixed6 is int256;
using Fixed6Lib for Fixed6 global;
type Fixed6Storage is bytes32;
using Fixed6StorageLib for Fixed6Storage global;

/**
 * @title Fixed6Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed6Lib {
    error Fixed6OverflowError(uint256 value);

    int256 private constant BASE = 1e6;
    Fixed6 public constant ZERO = Fixed6.wrap(0);
    Fixed6 public constant ONE = Fixed6.wrap(BASE);
    Fixed6 public constant NEG_ONE = Fixed6.wrap(-1 * BASE);
    Fixed6 public constant MAX = Fixed6.wrap(type(int256).max);
    Fixed6 public constant MIN = Fixed6.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (Fixed6) {
        uint256 value = UFixed6.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed6OverflowError(value);
        return Fixed6.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed6 m) internal pure returns (Fixed6) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed6.wrap(-1 * Fixed6.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a, bool roundOut) internal pure returns (Fixed6) {
        return roundOut ? Fixed6.wrap(NumberMath.divOut(Fixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed6 a) internal pure returns (bool) {
        return Fixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) + Fixed6.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) - Fixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * BASE / Fixed6.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldiv(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldivOut(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / Fixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), Fixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed6 a, Fixed6 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed6.unwrap(a), Fixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.min(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.max(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed6 a) internal pure returns (int256) {
        return Fixed6.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed6 a) internal pure returns (int256) {
        if (Fixed6.unwrap(a) > 0) return 1;
        if (Fixed6.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed6 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(SignedMath.abs(Fixed6.unwrap(a)));
    }
}

library Fixed6StorageLib {
    function read(Fixed6Storage self) internal view returns (Fixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed6Storage self, Fixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * BASE, UFixed18.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldivOut(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), UFixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev UFixed6 type
type UFixed6 is uint256;
using UFixed6Lib for UFixed6 global;
type UFixed6Storage is bytes32;
using UFixed6StorageLib for UFixed6Storage global;

/**
 * @title UFixed6Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed6Lib {
    error UFixed6UnderflowError(int256 value);

    uint256 private constant BASE = 1e6;
    UFixed6 public constant ZERO = UFixed6.wrap(0);
    UFixed6 public constant ONE = UFixed6.wrap(BASE);
    UFixed6 public constant MAX = UFixed6.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (UFixed6) {
        int256 value = Fixed6.unwrap(a);
        if (value < 0) revert UFixed6UnderflowError(value);
        return UFixed6.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a, bool roundOut) internal pure returns (UFixed6) {
        return roundOut ? UFixed6.wrap(NumberMath.divOut(UFixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed6 a) internal pure returns (bool) {
        return UFixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) + UFixed6.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) - UFixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * BASE / UFixed6.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * BASE, UFixed6.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldiv(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldivOut(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / UFixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), UFixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed6 a, UFixed6 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed6.unwrap(a), UFixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.min(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.max(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed6 a) internal pure returns (uint256) {
        return UFixed6.unwrap(a) / BASE;
    }
}

library UFixed6StorageLib {
    function read(UFixed6Storage self) internal view returns (UFixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed6Storage self, UFixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed18.sol";

/// @dev Stored boolean slot
type BoolStorage is bytes32;
using BoolStorageLib for BoolStorage global;

/// @dev Stored uint256 slot
type Uint256Storage is bytes32;
using Uint256StorageLib for Uint256Storage global;

/// @dev Stored int256 slot
type Int256Storage is bytes32;
using Int256StorageLib for Int256Storage global;

/// @dev Stored address slot
type AddressStorage is bytes32;
using AddressStorageLib for AddressStorage global;

/// @dev Stored bytes32 slot
type Bytes32Storage is bytes32;
using Bytes32StorageLib for Bytes32Storage global;

/**
 * @title BoolStorageLib
 * @notice Library to manage storage and retrieval of a boolean at a fixed storage slot
 */
library BoolStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bool value
     */
    function read(BoolStorage self) internal view returns (bool value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value boolean value to store
     */
    function store(BoolStorage self, bool value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Uint256StorageLib
 * @notice Library to manage storage and retrieval of an uint256 at a fixed storage slot
 */
library Uint256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored uint256 value
     */
    function read(Uint256Storage self) internal view returns (uint256 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value uint256 value to store
     */
    function store(Uint256Storage self, uint256 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Int256StorageLib
 * @notice Library to manage storage and retrieval of an int256 at a fixed storage slot
 */
library Int256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored int256 value
     */
    function read(Int256Storage self) internal view returns (int256 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value int256 value to store
     */
    function store(Int256Storage self, int256 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title AddressStorageLib
 * @notice Library to manage storage and retrieval of an address at a fixed storage slot
 */
library AddressStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored address value
     */
    function read(AddressStorage self) internal view returns (address value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value address value to store
     */
    function store(AddressStorage self, address value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Bytes32StorageLib
 * @notice Library to manage storage and retrieval of a bytes32 at a fixed storage slot
 */
library Bytes32StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bytes32 value
     */
    function read(Bytes32Storage self) internal view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value bytes32 value to store
     */
    function store(Bytes32Storage self, bytes32 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}