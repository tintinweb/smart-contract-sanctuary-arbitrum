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

/*
                  ███▄▄▄                               ,▄▄███▄
                  ████▀`                      ,╓▄▄▄████████████▄
                  ███▌             ,╓▄▄▄▄█████████▀▀▀▀▀▀╙└`
                  ███▌       ▀▀▀▀▀▀▀▀▀▀╙└└-  ████L
                  ███▌                      ████`               ╓██▄
                  ███▌    ╓▄    ╓╓╓╓╓╓╓╓╓╓╓████▄╓╓╓╓╓╓╓╓╓╓╓╓╓╓▄███████▄
                  ███▌  ▄█████▄ ▀▀▀▀▀▀▀▀▀▀████▀▀▀▀▀▀██▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
         ███████████████████████_       ▄███▀        ██µ
                 ▐███▌                ,███▀           ▀██µ
                 ████▌               ▄███▌,           ▄████▄
                ▐████▌             ▄██▀████▀▀▀▀▀▀▀▀▀▀█████▀███▄
               ,█████▌          ,▄██▀_ ▓███          ▐███_  ▀████▄▄
               ██████▌,       ▄██▀_    ▓███          ▐███_    ▀███████▄-
              ███▀███▌▀███▄  ╙"        ▓███▄▄▄▄▄▄▄▄▄▄▄███_      `▀███└
             ▄██^ ███▌  ^████▄         ▓███▀▀▀▀▀▀▀▀▀▀▀███_         `
            ▄██_  ███▌    ╙███         ▓██▀          └▀▀_        ▄,
           ██▀    ███▌      ▀└ ▐███▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄████▄µ
          ██^     ███▌         ▐███▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀██████▀
        ╓█▀       ███▌         ▐███⌐      µ          ╓          ▐███
        ▀         ███▌         ▐███⌐      ███▄▄▄▄▄▄▄████▄       ▐███
                  ███▌         ▐███⌐      ████▀▀▀▀▀▀▀████▀      ▐███
                  ███▌         ▐███⌐      ███▌      J███M       ▐███
                  ███▌         ▐███⌐      ███▌      J███M       ▐███
                  ███▌         ▐███⌐      ████▄▄▄▄▄▄████M       ▐███
                  ███▌         ▐███⌐      ███▌      ▐███M       ▐███
                  ███▌         ▐███⌐      ███▌       ▀▀_        ████
                  ███▌         ▐███⌐      ▀▀_             ▀▀▀███████
                  ███^         ▐███_                          ▐██▀▀　

                                           Made with ❤️ by Gnosis Guild
*/
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import { IOracleAdapter } from "./interfaces/IOracleAdapter.sol";

contract Hashi {
    error NoOracleAdaptersGiven(address emitter);
    error OracleDidNotReport(address emitter, IOracleAdapter oracleAdapter);
    error OraclesDisagree(address emitter, IOracleAdapter oracleOne, IOracleAdapter oracleTwo);

    /// @dev Returns the hash reported by a given oracle for a given ID.
    /// @param oracleAdapter Address of the oracle adapter to query.
    /// @param domain Id of the domain to query.
    /// @param id ID for which to return a hash.
    /// @return hash Hash reported by the given oracle adapter for the given ID number.
    function getHashFromOracle(
        IOracleAdapter oracleAdapter,
        uint256 domain,
        uint256 id
    ) public view returns (bytes32 hash) {
        hash = oracleAdapter.getHashFromOracle(domain, id);
    }

    /// @dev Returns the hash for a given ID reported by a given set of oracles.
    /// @param oracleAdapters Array of address for the oracle adapters to query.
    /// @param domain ID of the domain to query.
    /// @param id ID for which to return hashs.
    /// @return hashes Array of hash reported by the given oracle adapters for the given ID.
    function getHashesFromOracles(
        IOracleAdapter[] memory oracleAdapters,
        uint256 domain,
        uint256 id
    ) public view returns (bytes32[] memory) {
        if (oracleAdapters.length == 0) revert NoOracleAdaptersGiven(address(this));
        bytes32[] memory hashes = new bytes32[](oracleAdapters.length);
        for (uint256 i = 0; i < oracleAdapters.length; i++) {
            hashes[i] = getHashFromOracle(oracleAdapters[i], domain, id);
        }
        return hashes;
    }

    /// @dev Returns the hash unanimously agreed upon by a given set of oracles.
    /// @param domain ID of the domain to query.
    /// @param id ID for which to return hash.
    /// @param oracleAdapters Array of address for the oracle adapters to query.
    /// @return hash Hash agreed on by the given set of oracle adapters.
    /// @notice MUST revert if oracles disagree on the hash or if an oracle does not report.
    function getHash(
        uint256 domain,
        uint256 id,
        IOracleAdapter[] memory oracleAdapters
    ) public view returns (bytes32 hash) {
        if (oracleAdapters.length == 0) revert NoOracleAdaptersGiven(address(this));
        bytes32[] memory hashes = getHashesFromOracles(oracleAdapters, domain, id);
        hash = hashes[0];
        if (hash == bytes32(0)) revert OracleDidNotReport(address(this), oracleAdapters[0]);
        for (uint256 i = 1; i < hashes.length; i++) {
            if (hashes[i] == bytes32(0)) revert OracleDidNotReport(address(this), oracleAdapters[i]);
            if (hash != hashes[i]) revert OraclesDisagree(address(this), oracleAdapters[i - 1], oracleAdapters[i]);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

struct Domain {
    uint256 threshold;
    uint256 count;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

interface IOracleAdapter {
    event HashStored(uint256 indexed id, bytes32 indexed hashes);

    error InvalidBlockHeaderLength(uint256 length);
    error InvalidBlockHeaderRLP();
    error ConflictingBlockHeader(uint256 blockNumber, bytes32 reportedBlockHash, bytes32 storedBlockHash);

    /// @dev Returns the hash for a given ID, as reported by the oracle.
    /// @param domain Identifier for the domain to query.
    /// @param id Identifier for the ID to query.
    /// @return hash Bytes32 hash reported by the oracle for the given ID on the given domain.
    /// @notice MUST return bytes32(0) if the oracle has not yet reported a hash for the given ID.
    function getHashFromOracle(uint256 domain, uint256 id) external view returns (bytes32 hash);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import { Hashi, IOracleAdapter, ShuSo, OwnableUpgradeable } from "./ShuSo.sol";
import { Domain } from "../interfaces/IDomain.sol";

contract ShoyuBashi is ShuSo {
    constructor(address _owner, address _hashi) ShuSo(_owner, _hashi) {}

    /// @dev Sets the address of the Hashi contract.
    /// @param _hashi Address of the hashi contract.
    /// @notice Only callable by the owner of this contract.
    function setHashi(Hashi _hashi) public override {
        _setHashi(_hashi);
    }

    /// @dev Sets the threshold of adapters required for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set the threshold.
    /// @param threshold Uint256 threshold to set for the given domain.
    /// @notice Only callable by the owner of this contract.
    /// @notice Reverts if threshold is already set to the given value.
    function setThreshold(uint256 domain, uint256 threshold) public {
        _setThreshold(domain, threshold);
    }

    /// @dev Enables the given adapters for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set oracle adapters.
    /// @param _adapters Array of oracleAdapter addresses.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Only callable by the owner of this contract.
    function enableOracleAdapters(uint256 domain, IOracleAdapter[] memory _adapters) public {
        _enableOracleAdapters(domain, _adapters);
    }

    /// @dev Disables the given adapters for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set oracle adapters.
    /// @param _adapters Array of oracleAdapter addresses.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Only callable by the owner of this contract.
    function disableOracleAdapters(uint256 domain, IOracleAdapter[] memory _adapters) public {
        _disableOracleAdapters(domain, _adapters);
    }

    /// @dev Returns the hash unanimously agreed upon by ALL of the enabled oraclesAdapters.
    /// @param domain Uint256 identifier for the domain to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by the oracles for the given domain.
    /// @notice Reverts if oracles disagree.
    /// @notice Reverts if oracles have not yet reported the hash for the given ID.
    /// @notice Reverts if no oracles are set for the given domain.
    function getUnanimousHash(uint256 domain, uint256 id) public view returns (bytes32 hash) {
        hash = _getUnanimousHash(domain, id);
    }

    /// @dev Returns the hash agreed upon by a threshold of the enabled oraclesAdapters.
    /// @param domain Uint256 identifier for the domain to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by a threshold of the oracles for the given domain.
    /// @notice Reverts if no threshold is not reached.
    /// @notice Reverts if no oracles are set for the given domain.
    function getThresholdHash(uint256 domain, uint256 id) public view returns (bytes32 hash) {
        hash = _getThresholdHash(domain, id);
    }

    /// @dev Returns the hash unanimously agreed upon by all of the given oraclesAdapters..
    /// @param domain Uint256 identifier for the domain to query.
    /// @param _adapters Array of oracle adapter addresses to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by the oracles for the given domain.
    /// @notice _adapters must be in numberical order from smallest to largest and contain no duplicates.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Reverts if oracles disagree.
    /// @notice Reverts if oracles have not yet reported the hash for the given ID.
    /// @notice Reverts if no oracles are set for the given domain.
    function getHash(uint256 domain, uint256 id, IOracleAdapter[] memory _adapters) public view returns (bytes32 hash) {
        hash = _getHash(domain, id, _adapters);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import { Hashi, IOracleAdapter } from "../Hashi.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Domain } from "../interfaces/IDomain.sol";

struct Link {
    IOracleAdapter previous;
    IOracleAdapter next;
}

abstract contract ShuSo is OwnableUpgradeable {
    IOracleAdapter internal constant LIST_END = IOracleAdapter(address(0x1));

    Hashi public hashi;
    mapping(uint256 => mapping(IOracleAdapter => Link)) public adapters;
    mapping(uint256 => Domain) public domains;

    event HashiSet(address indexed emitter, Hashi indexed hashi);
    event Init(address indexed emitter, address indexed owner, Hashi indexed hashi);
    event OracleAdaptersEnabled(address indexed emitter, uint256 indexed domain, IOracleAdapter[] adapters);
    event OracleAdaptersDisabled(address indexed emitter, uint256 indexed domain, IOracleAdapter[] adapters);
    event ThresholdSet(address indexed emitter, uint256 domain, uint256 threshold);

    error AdapterNotEnabled(address emitter, IOracleAdapter adapter);
    error AdapterAlreadyEnabled(address emitter, IOracleAdapter adapter);
    error DuplicateHashiAddress(address emitter, Hashi hashi);
    error DuplicateOrOutOfOrderAdapters(address emitter, IOracleAdapter adapterOne, IOracleAdapter adapterTwo);
    error DuplicateThreashold(address emitter, uint256 threshold);
    error InvalidAdapter(address emitter, IOracleAdapter adapter);
    error NoAdaptersEnabled(address emitter, uint256 domain);
    error NoAdaptersGiven(address emitter);
    error ThresholdNotMet(address emitter);

    constructor(address _owner, address _hashi) {
        bytes memory initParams = abi.encode(_owner, _hashi);
        init(initParams);
    }

    function init(bytes memory initParams) public initializer {
        (address _owner, Hashi _hashi) = abi.decode(initParams, (address, Hashi));
        __Ownable_init();
        setHashi(_hashi);
        transferOwnership(_owner);
        emit Init(address(this), _owner, _hashi);
    }

    function setHashi(Hashi _hashi) public virtual;

    /// @dev Sets the address of the Hashi contract.
    /// @param _hashi Address of the hashi contract.
    /// @notice Only callable by the owner of this contract.
    function _setHashi(Hashi _hashi) internal onlyOwner {
        if (hashi == _hashi) revert DuplicateHashiAddress(address(this), _hashi);
        hashi = _hashi;
        emit HashiSet(address(this), hashi);
    }

    /// @dev Sets the threshold of adapters required for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set the threshold.
    /// @param threshold Uint256 threshold to set for the given domain.
    /// @notice Only callable by the owner of this contract.
    /// @notice Reverts if threshold is already set to the given value.
    function _setThreshold(uint256 domain, uint256 threshold) internal onlyOwner {
        if (domains[domain].threshold == threshold) revert DuplicateThreashold(address(this), threshold);
        domains[domain].threshold = threshold;
        emit ThresholdSet(address(this), domain, threshold);
    }

    /// @dev Enables the given adapters for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set oracle adapters.
    /// @param _adapters Array of oracleAdapter addresses.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Only callable by the owner of this contract.
    function _enableOracleAdapters(uint256 domain, IOracleAdapter[] memory _adapters) internal onlyOwner {
        if (adapters[domain][LIST_END].next == IOracleAdapter(address(0))) {
            adapters[domain][LIST_END].next = LIST_END;
            adapters[domain][LIST_END].previous = LIST_END;
        }
        if (_adapters.length == 0) revert NoAdaptersGiven(address(this));
        for (uint256 i = 0; i < _adapters.length; i++) {
            IOracleAdapter adapter = _adapters[i];
            if (adapter == IOracleAdapter(address(0)) || adapter == LIST_END)
                revert InvalidAdapter(address(this), adapter);
            if (adapters[domain][adapter].next != IOracleAdapter(address(0)))
                revert AdapterAlreadyEnabled(address(this), adapter);
            IOracleAdapter previous = adapters[domain][LIST_END].previous;
            adapters[domain][previous].next = adapter;
            adapters[domain][adapter].previous = previous;
            adapters[domain][LIST_END].previous = adapter;
            adapters[domain][adapter].next = LIST_END;
            domains[domain].count++;
        }
        emit OracleAdaptersEnabled(address(this), domain, _adapters);
    }

    /// @dev Disables the given adapters for a given domain.
    /// @param domain Uint256 identifier for the domain for which to set oracle adapters.
    /// @param _adapters Array of oracleAdapter addresses.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Only callable by the owner of this contract.
    function _disableOracleAdapters(uint256 domain, IOracleAdapter[] memory _adapters) internal onlyOwner {
        if (domains[domain].count == 0) revert NoAdaptersEnabled(address(this), domain);
        if (_adapters.length == 0) revert NoAdaptersGiven(address(this));
        for (uint256 i = 0; i < _adapters.length; i++) {
            IOracleAdapter adapter = _adapters[i];
            if (adapter == IOracleAdapter(address(0)) || adapter == LIST_END)
                revert InvalidAdapter(address(this), adapter);
            Link memory current = adapters[domain][adapter];
            if (current.next == IOracleAdapter(address(0))) revert AdapterNotEnabled(address(this), adapter);
            IOracleAdapter next = current.next;
            IOracleAdapter previous = current.previous;
            adapters[domain][next].previous = previous;
            adapters[domain][previous].next = next;
            delete adapters[domain][adapter].next;
            delete adapters[domain][adapter].previous;
            domains[domain].count--;
        }
        emit OracleAdaptersDisabled(address(this), domain, _adapters);
    }

    /// @dev Returns an array of enabled oracle adapters for a given domain.
    /// @param domain Uint256 identifier for the domain for which to list oracle adapters.
    function getOracleAdapters(uint256 domain) public view returns (IOracleAdapter[] memory) {
        IOracleAdapter[] memory _adapters = new IOracleAdapter[](domains[domain].count);
        IOracleAdapter currentAdapter = adapters[domain][LIST_END].next;
        for (uint256 i = 0; i < _adapters.length; i++) {
            _adapters[i] = currentAdapter;
            currentAdapter = adapters[domain][currentAdapter].next;
        }
        return _adapters;
    }

    /// @dev Returns the threshold and count for a given domain
    /// @param domain Uint256 identifier for the domain.
    /// @return threshold Uint256 oracle threshold for the given domain.
    /// @return count Uint256 oracle count for the given domain.
    /// @notice If the threshold for a domain has not been set, or is explicitly set to 0, this function will return a
    /// threshold equal to the oracle count for the given domain.
    function getThresholdAndCount(uint256 domain) public view returns (uint256 threshold, uint256 count) {
        threshold = domains[domain].threshold;
        count = domains[domain].count;
        if (threshold == 0) threshold = count;
    }

    function checkAdapterOrderAndValidity(uint256 domain, IOracleAdapter[] memory _adapters) public view {
        for (uint256 i = 0; i < _adapters.length; i++) {
            IOracleAdapter adapter = _adapters[i];
            if (i > 0 && adapter <= _adapters[i - 1])
                revert DuplicateOrOutOfOrderAdapters(address(this), adapter, _adapters[i - 1]);
            if (adapters[domain][adapter].next == IOracleAdapter(address(0)))
                revert InvalidAdapter(address(this), adapter);
        }
    }

    /// @dev Returns the hash unanimously agreed upon by ALL of the enabled oraclesAdapters.
    /// @param domain Uint256 identifier for the domain to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by the oracles for the given domain.
    /// @notice Reverts if oracles disagree.
    /// @notice Reverts if oracles have not yet reported the hash for the given ID.
    /// @notice Reverts if no oracles are set for the given domain.
    function _getUnanimousHash(uint256 domain, uint256 id) internal view returns (bytes32 hash) {
        IOracleAdapter[] memory _adapters = getOracleAdapters(domain);
        (uint256 threshold, uint256 count) = getThresholdAndCount(domain);
        if (count == 0) revert NoAdaptersEnabled(address(this), domain);
        if (_adapters.length < threshold) revert ThresholdNotMet(address(this));
        hash = hashi.getHash(domain, id, _adapters);
    }

    /// @dev Returns the hash agreed upon by a threshold of the enabled oraclesAdapters.
    /// @param domain Uint256 identifier for the domain to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by a threshold of the oracles for the given domain.
    /// @notice Reverts if no threshold is not reached.
    /// @notice Reverts if no oracles are set for the given domain.
    function _getThresholdHash(uint256 domain, uint256 id) internal view returns (bytes32 hash) {
        IOracleAdapter[] memory _adapters = getOracleAdapters(domain);
        (uint256 threshold, uint256 count) = getThresholdAndCount(domain);
        if (count == 0) revert NoAdaptersEnabled(address(this), domain);
        if (_adapters.length < threshold) revert ThresholdNotMet(address(this));

        // get hashes
        bytes32[] memory hashes = new bytes32[](_adapters.length);
        for (uint i = 0; i < _adapters.length; i++) {
            try _adapters[i].getHashFromOracle(domain, id) returns (bytes32 currentHash) {
                hashes[i] = currentHash;
            } catch {}
        }

        // find a hash agreed on by a threshold of oracles
        for (uint i = 0; i < hashes.length; i++) {
            bytes32 baseHash = hashes[i];
            if (baseHash == bytes32(0)) continue;

            // increment num for each instance of the curent hash
            uint256 num = 1;
            for (uint j = 0; j < hashes.length; j++) {
                if (baseHash == hashes[j] && i != j) {
                    num++;
                    // return current hash if num equals threshold
                    if (num == threshold) return hashes[i];
                }
            }
        }
        revert ThresholdNotMet(address(this));
    }

    /// @dev Returns the hash unanimously agreed upon by all of the given oraclesAdapters..
    /// @param domain Uint256 identifier for the domain to query.
    /// @param _adapters Array of oracle adapter addresses to query.
    /// @param id Uint256 identifier to query.
    /// @return hash Bytes32 hash agreed upon by the oracles for the given domain.
    /// @notice _adapters must be in numberical order from smallest to largest and contain no duplicates.
    /// @notice Reverts if _adapters are out of order or contain duplicates.
    /// @notice Reverts if oracles disagree.
    /// @notice Reverts if oracles have not yet reported the hash for the given ID.
    /// @notice Reverts if no oracles are set for the given domain.
    function _getHash(
        uint256 domain,
        uint256 id,
        IOracleAdapter[] memory _adapters
    ) internal view returns (bytes32 hash) {
        (uint256 threshold, uint256 count) = getThresholdAndCount(domain);
        if (_adapters.length == 0) revert NoAdaptersGiven(address(this));
        if (count == 0) revert NoAdaptersEnabled(address(this), domain);
        if (_adapters.length < threshold) revert ThresholdNotMet(address(this));
        checkAdapterOrderAndValidity(domain, _adapters);
        hash = hashi.getHash(domain, id, _adapters);
    }
}