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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RngCommitmentManagerInterface {
  struct NewCommitment {
    bytes32 commitmentId;
    bytes32[] commitmentHashes;
  }

  struct CommitmentSecret {
    bytes32 commitmentHash;
    uint256[] coefficients;
    uint256[2] point;
    string salt;
  }

  struct RevealedCommitment {
    CommitmentSecret[] secrets;
    uint256 prime;
    uint16 k;
  }

  /**
   * Read only function to check if commitment exist
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   */
  function isCommitmentExists(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external view returns (bool);

  /**
   * Function to get list of available commitments
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @return commitemts bytes32[]
   */
  function getAvailbleCommitments(
    uint64 subId,
    address consumer
  ) external view returns (bytes32[] memory);

  /**
   * Function to get list of selected commitments
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @return commitemts bytes32[]
   */
  function getSelectedCommitments(
    uint64 subId,
    address consumer
  ) external view returns (bytes32[] memory);

  /**
   * Read only function to get commitment details
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   * @return bytes32[] commitment hashes list
   * @return uint256 prime number set for commitment
   * @return uint16 threshold Set for commitment
   * @return bool commitment available state
   * @return bool commitment exist state
   */
  function getCommitment(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external view returns (bytes32[] memory, uint256, uint16, bool, bool);

  /**
   * Function to add new decommit request
   * @param subId subscription Id
   * @param consumer data consumer address
   * @param commitmentId commitment hash
   */
  function addDecommitRequest(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external;

  /**
   * Read only function to get commitment details
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   * @return uint256 decommit request block number
   */
  function getDecommitRequest(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external view returns (uint256);

  /**
   * Function to add new commitments for a consumer
   * @param subId subscription Id
   * @param consumer consumer address
   * @param prime prime used for commitments
   * @param k threshold used for commitments
   * @param commitments commitments list with hashes
   * @return bytes32[] new commtment Ids
   * @return uint16 newly added commitments length
   * @return uint256 total commitments length
   */
  function addCommitments(
    uint64 subId,
    address consumer,
    uint256 prime,
    uint16 k,
    NewCommitment[] calldata commitments
  ) external returns (bytes32[] memory, uint16, uint256);

  /**
   * Function to delete commitment, decommit reqeust cache
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   */
  function clearCommitment(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RngConsumerInterface {
  /**
   * @notice Callback function called by the gateway when new commiments are generated
   * @param commitments - list of new commitment IDs
   */
  function receiveNewCommitments(bytes32[] memory commitments) external;

  /**
   * @notice Callback function called by the gateway when decommit request is completed
   * @param commitmentId - commitment ID
   * @param randomNumber - generated random number for the commitment
   * @param rangeMaxPrime - prime number set for the commitment
   */
  function revealRequestedCommitment(
    bytes32 commitmentId,
    uint256 randomNumber,
    uint256 rangeMaxPrime
  ) external;

  /**
   * @notice Callback function called by the gateway when a decommit request is timedout
   * @param commitmentId - commitment ID of timed out decommit
   */
  function receiveTimeoutNotification(bytes32 commitmentId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RngCommitmentManagerInterface.sol";

interface RngMPCInterface {
  /**
   * Function to reveal the commitment secrets and calculate the random number
   * @param subId subscription Id
   * @param consumer consumer address
   * @param commitmentId commitment hash
   * @param commitments revealed commitments data
   * @return uint256 random number
   * @return uint256 prime number used
   */
  function revealRandomNumber(
    uint64 subId,
    address consumer,
    bytes32 commitmentId,
    RngCommitmentManagerInterface.RevealedCommitment calldata commitments
  ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RngCommitmentManagerInterface.sol";

interface RngNodeGatewayInterface {
  /**
   * Function to request for new commitments from latest gateway version
   * @param subId subscription Id
   * @param count num of commitments
   */
  function requestCommitments(
    uint64 subId,
    address consumer,
    uint16 count
  ) external;

  /**
   * Function to request decommit from latest gateway version
   * @param subId subscription Id
   * @param commitmentId commitment hash
   */
  function requestDecommit(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RngSubscriptionManagerInterface {
  /**
   * Function to add new client
   * @param teamSize size of node team to be used
   * @param ownerAddress subscription owner address
   */
  function addRngClient(
    uint16 teamSize,
    address ownerAddress
  ) external returns (uint64);

  /**
   * Function to authorize node
   * @param subId subscription Id
   * @param teamSize new team size
   */
  function authorizeNodesForCustomer(uint64 subId, uint16 teamSize) external;

  /**
   * Add nodes to client allow list
   * @param subId subscription Id
   * @param nodeAddresses list of node account address
   */
  function setTeamNodeAddresses(
    uint64 subId,
    address[] calldata nodeAddresses
  ) external;

  /**
   * Function to authorize consumers for a subscription
   * @param subId subscription Id
   * @param consumer consumer contract address
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * Function to deauthorize consumer for a subscription
   * @param subId subscription Id
   * @param consumer consumer contract address
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * Function to set/update prime number used
   * @param subId subscription Id
   * @param prime uint prime number
   */
  function setPrime(uint64 subId, uint256 prime) external;

  /**
   * Function to set threshold (k) value
   * @param subId subscription Id
   * @param k min threshold
   */
  function setThreshold(uint64 subId, uint16 k) external;

  /**
   * Function to update timeout blocks threshold
   * @param subId subscription Id
   * @param numBlocks blocks threshold
   */
  function setTimeoutBlocks(uint64 subId, uint64 numBlocks) external;

  /**
   *	Read only function to check if consumer is authorized
   * @param subId subscription Id
   * @param consumer consumer contract address
   */
  function isConsumerAuthorized(
    uint64 subId,
    address consumer
  ) external view returns (bool);

  /**
   *	Read only function to check if nodes is authorized
   * @param subId subscription Id
   * @param nodeAddress node account address
   */
  function isNodeAuthorized(
    uint64 subId,
    address nodeAddress
  ) external view returns (bool);

  /**
   *	Read only function to get client subscription details
   * @param subId subscription Id
   */
  function getClientRngConfig(
    uint64 subId
  ) external view returns (uint16, uint16, uint256, uint64);

  /**
   *	Read only function to get subscription owner address
   * @param subId subscription Id
   */
  function getSubscriptionOwner(uint64 subId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/RngSubscriptionManagerInterface.sol";
import "./interfaces/RngCommitmentManagerInterface.sol";
import "./interfaces/RngNodeGatewayInterface.sol";
import "./interfaces/RngMPCInterface.sol";
import "./interfaces/RngConsumerInterface.sol";

contract RngGateway is Initializable, OwnableUpgradeable {
  address rngCommitmentAddress;
  RngCommitmentManagerInterface rngCommitmentManager;

  address rngSubscriptionAddress;
  RngSubscriptionManagerInterface rngSubscriptionManager;

  address rngMPCAddress;
  RngMPCInterface rngMPC;

  mapping(string => address) rngGatewayVersionAddress;
  mapping(address => bool) rngGatewayAddress;
  mapping(string => RngNodeGatewayInterface) rngNodeGateways;
  string latestVersion;

  event RevealedCommitment(
    bytes32 commitmentId,
    bytes32[] commitmentHashes,
    RngCommitmentManagerInterface.RevealedCommitment revealedCommitment
  );

  mapping(address => bool) adminAllowList;

  modifier onlyAdmin() {
    require(adminAllowList[msg.sender], "OnlyAdmins");
    _;
  }

  modifier onlyConsumer(uint64 subId) {
    require(
      rngSubscriptionManager.isConsumerAuthorized(subId, msg.sender),
      "ConsumnerNotAuthorized"
    );
    _;
  }

  modifier onlyAuthorizedNodeGateways() {
    require(rngGatewayAddress[msg.sender], "onlyAuthorizedNodeGateways");
    _;
  }

  modifier onlySubscriptionOwner(uint64 subId) {
    require(
      rngSubscriptionManager.getSubscriptionOwner(subId) == msg.sender,
      "onlySubscriptionOwnerAllowed"
    );
    _;
  }

  event NewHashesAvailable(
    bytes32[] commitmentId,
    uint256 newlyReceived,
    uint256 total
  );

  function initialize() public initializer {
    __Ownable_init();
    adminAllowList[owner()] = true;
  }

  /**
   * Function to set commitment manager contract address
   * @param _rngCommitmentAddress contract address
   */
  function setNewCommitmentStorage(
    address _rngCommitmentAddress
  ) external onlyOwner {
    rngCommitmentAddress = _rngCommitmentAddress;
    rngCommitmentManager = RngCommitmentManagerInterface(rngCommitmentAddress);
  }

  /**
   * Function to set subscription manager contract address
   * @param _rngSubscriptionAddress contract address
   */
  function setNewSubscriptionStorage(
    address _rngSubscriptionAddress
  ) external onlyOwner {
    rngSubscriptionAddress = _rngSubscriptionAddress;
    rngSubscriptionManager = RngSubscriptionManagerInterface(
      rngSubscriptionAddress
    );
  }

  /**
   * Function to set MPC contract address
   * @param _rngMPCAddress contract address
   */
  function setNewMPC(address _rngMPCAddress) external onlyOwner {
    rngMPCAddress = _rngMPCAddress;
    rngMPC = RngMPCInterface(rngMPCAddress);
  }

  /**
   * Function to add new gateway  version
   * @param version gateway version number
   * @param gatewayAddress contract address
   */
  function addNewRngGatewayVersion(
    string calldata version,
    address gatewayAddress
  ) external onlyOwner {
    rngGatewayVersionAddress[version] = gatewayAddress;
    rngNodeGateways[version] = RngNodeGatewayInterface(gatewayAddress);
    // add to allow list
    rngGatewayAddress[gatewayAddress] = true;
    latestVersion = version;
  }

  /**
   * Function to add admin to allow list
   * @param adminAddress admin account address
   */
  function addAdmin(address adminAddress) external onlyOwner {
    adminAllowList[adminAddress] = true;
  }

  /**
   * Function to add admin to allow list
   * @param adminAddress admin account address
   */
  function removeAdmin(address adminAddress) external onlyOwner {
    delete adminAllowList[adminAddress];
  }

  /**
   * Function to register new customer
   * @param initialTeamSize team size
   * @param subscriptionOwner  subscription owner address
   * @return uint64 subscription Id
   */
  function registerCustomer(
    uint16 initialTeamSize,
    address subscriptionOwner
  ) external onlyAdmin returns (uint64) {
    return
      rngSubscriptionManager.addRngClient(initialTeamSize, subscriptionOwner);
  }

  /**
   * Function to authorize node
   * @param subId subscription Id
   * @param teamSize new team size
   */
  function authorizeNodesForCustomer(
    uint64 subId,
    uint16 teamSize
  ) external onlyAdmin {
    rngSubscriptionManager.authorizeNodesForCustomer(subId, teamSize);
  }

  /**
   * Add nodes to client allow list
   * @param subId subscription Id
   * @param nodeAddresses list of node account address
   */
  function setTeamNodeAddresses(
    uint64 subId,
    address[] calldata nodeAddresses
  ) external onlyAdmin {
    rngSubscriptionManager.setTeamNodeAddresses(subId, nodeAddresses);
  }

  /**
   * Function to authorize consumers for a subscription
   * @param subId subscription Id
   * @param consumer consumer contract address
   */
  function addConsumer(
    uint64 subId,
    address consumer
  ) external onlySubscriptionOwner(subId) {
    rngSubscriptionManager.addConsumer(subId, consumer);
  }

  /**
   * Function to deauthorize consumer for a subscription
   * @param subId subscription Id
   * @param consumer consumer contract address
   */
  function removeConsumer(
    uint64 subId,
    address consumer
  ) external onlySubscriptionOwner(subId) {
    rngSubscriptionManager.removeConsumer(subId, consumer);
  }

  /**
   * Function to set/update prime number used
   * @param subId subscription Id
   * @param prime uint prime number
   */
  function setPrime(
    uint64 subId,
    uint256 prime
  ) external onlySubscriptionOwner(subId) {
    rngSubscriptionManager.setPrime(subId, prime);
  }

  /**
   * Function to set threshold (k) value
   * @param subId subscription Id
   * @param k min threshold
   */
  function setThreshold(
    uint64 subId,
    uint16 k
  ) external onlySubscriptionOwner(subId) {
    rngSubscriptionManager.setThreshold(subId, k);
  }

  /**
   * Function to update timeout blocks threshold
   * @param subId subscription Id
   * @param numBlocks blocks threshold
   */
  function setTimeoutBlocks(
    uint64 subId,
    uint64 numBlocks
  ) external onlySubscriptionOwner(subId) {
    rngSubscriptionManager.setTimeoutBlocks(subId, numBlocks);
  }

  /**
   * Function to request for new commitments from latest gateway version
   * @param subId subscription Id
   * @param count num of commitments
   */
  function requestCommitments(
    uint64 subId,
    uint16 count
  ) external onlyConsumer(subId) {
    rngNodeGateways[latestVersion].requestCommitments(subId, msg.sender, count);
  }

  /**
   * Function to request for new commitments from given gateway version
   * @param subId subscription Id
   * @param count num of commitments
   * @param gatewayVersion gateway version to use
   */
  function requestCommitments(
    uint64 subId,
    uint16 count,
    string calldata gatewayVersion
  ) external onlyConsumer(subId) {
    rngNodeGateways[gatewayVersion].requestCommitments(
      subId,
      msg.sender,
      count
    );
  }

  /**
   * Function to request decommit from latest gateway version
   * @param subId subscription Id
   * @param commitmentId commitment hash
   */
  function requestDecommit(
    uint64 subId,
    bytes32 commitmentId
  ) external onlyConsumer(subId) {
    rngCommitmentManager.addDecommitRequest(subId, msg.sender, commitmentId);
    rngNodeGateways[latestVersion].requestDecommit(
      subId,
      msg.sender,
      commitmentId
    );
  }

  /**
   * Function to request decommit from given gateway version
   * @param subId subscription Id
   * @param commitmentId commitment hash
   * @param gatewayVersion gateway version to use
   */
  function requestDecommit(
    uint64 subId,
    bytes32 commitmentId,
    string memory gatewayVersion
  ) external onlyConsumer(subId) {
    rngCommitmentManager.addDecommitRequest(subId, msg.sender, commitmentId);
    rngNodeGateways[gatewayVersion].requestDecommit(
      subId,
      msg.sender,
      commitmentId
    );
  }

  /**
   * Function to add new commitments for the consumer
   * Called by Node Gateway
   * Uses proxy to send new commitments through consumer callback
   * @param subId subscription Id
   * @param consumer consumer address
   * @param prime prime number used
   * @param k threshold used
   */
  function addCommitments(
    uint64 subId,
    address consumer,
    uint256 prime,
    uint16 k,
    RngCommitmentManagerInterface.NewCommitment[] memory commitments
  ) external onlyAuthorizedNodeGateways {
    (uint16 N, , , ) = rngSubscriptionManager.getClientRngConfig(subId);
    uint16 count;

    for (uint16 i = 0; i < commitments.length; i++) {
      bytes32 commitmentId = commitments[i].commitmentId;
      (, , , , bool isExists) = rngCommitmentManager.getCommitment(
        subId,
        consumer,
        commitmentId
      );

      if (isExists) continue;
      if (commitments[i].commitmentHashes.length != N) continue;

      string memory commitmentHashString = "";
      for (uint16 j = 0; j < commitments[i].commitmentHashes.length; j++) {
        if (j < commitments[i].commitmentHashes.length - 1) {
          commitmentHashString = string(
            abi.encodePacked(
              commitmentHashString,
              bytesToHex(abi.encodePacked(commitments[i].commitmentHashes[j])),
              ","
            )
          );
        } else {
          commitmentHashString = string(
            abi.encodePacked(
              commitmentHashString,
              bytesToHex(abi.encodePacked(commitments[i].commitmentHashes[j]))
            )
          );
        }
      }

      bytes32 commitmentHash = sha256(abi.encodePacked(commitmentHashString));
      if (commitmentHash != commitmentId) continue;
      count++;
    }

    (
      bytes32[] memory newCommitments,
      uint16 newCount,
      uint256 total
    ) = rngCommitmentManager.addCommitments(
        subId,
        consumer,
        prime,
        k,
        commitments
      );

    // callback through proxy
    RngConsumerInterface(consumer).receiveNewCommitments(newCommitments);

    emit NewHashesAvailable(newCommitments, newCount, total);
  }

  /**
   * Function to reveal the commitment secrets and calculate random number
   * Called by Node Gateway
   * Uses proxy to send random number through consumer callback
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   * @param commitments commitment secrets
   */
  function decommit(
    uint64 subId,
    address consumer,
    bytes32 commitmentId,
    RngCommitmentManagerInterface.RevealedCommitment calldata commitments
  ) external onlyAuthorizedNodeGateways {
    (
      bytes32[] memory commitmentHashes,
      ,
      ,
      bool availableState,
      bool isExists
    ) = rngCommitmentManager.getCommitment(subId, consumer, commitmentId);

    require(isExists && !availableState, "InvalidCommitment");

    (uint256 randomNumber, uint256 prime) = rngMPC.revealRandomNumber(
      subId,
      consumer,
      commitmentId,
      commitments
    );

    rngCommitmentManager.clearCommitment(subId, consumer, commitmentId);

    // callback through proxy
    RngConsumerInterface(consumer).revealRequestedCommitment(
      commitmentId,
      randomNumber,
      prime
    );

    emit RevealedCommitment(commitmentId, commitmentHashes, commitments);
  }

  /**
   * Function to notify the consumer about timed out commitment
   * Called by Node Gateway
   * Uses proxy to send notification through consumer callback
   * @param subId subscription Id
   * @param consumer consumer contract address
   * @param commitmentId commitment hash
   */
  function sendTimeoutNotification(
    uint64 subId,
    address consumer,
    bytes32 commitmentId
  ) external onlyAuthorizedNodeGateways {
    rngCommitmentManager.clearCommitment(subId, consumer, commitmentId);

    // callback through proxy
    RngConsumerInterface(consumer).receiveTimeoutNotification(commitmentId);
  }

  /**
   * Function to convert bytes to hex string
   * @param buffer bytes data
   * @return string converted hex string
   */
  function bytesToHex(
    bytes memory buffer
  ) private pure returns (string memory) {
    // Fixed buffer size for hexadecimal convertion
    bytes memory converted = new bytes(buffer.length * 2);
    bytes memory _base = "0123456789abcdef";

    for (uint256 i = 0; i < buffer.length; i++) {
      converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
      converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
    }

    return string(abi.encodePacked("0x", converted));
  }

  function checkTimeout(
    uint64 subId,
    address consumer,
    bytes32 commitmentId,
    uint64 timeoutBlocks
  ) private {
    uint256 blockNumber = rngCommitmentManager.getDecommitRequest(
      subId,
      consumer,
      commitmentId
    );

    if (block.number - blockNumber > timeoutBlocks) {
      // callback through proxy
      RngConsumerInterface(consumer).receiveTimeoutNotification(commitmentId);

      rngCommitmentManager.clearCommitment(subId, consumer, commitmentId);
    }
  }

  /**
   * Function to check if the decommit request is timed out
   * @param subId subscription Id
   * @param commitmentId commitment hash
   */
  function checkTimedOutDecommit(
    uint64 subId,
    bytes32 commitmentId
  ) public onlyConsumer(subId) {
    (, , , uint64 timeoutBlocks) = rngSubscriptionManager.getClientRngConfig(
      subId
    );
    uint256 blockNumber = rngCommitmentManager.getDecommitRequest(
      subId,
      msg.sender,
      commitmentId
    );

    if (block.number - blockNumber > timeoutBlocks) {
      // callback through proxy
      RngConsumerInterface(msg.sender).receiveTimeoutNotification(commitmentId);
      rngCommitmentManager.clearCommitment(subId, msg.sender, commitmentId);
    }
  }

  /**
   * Function to check all timed out decommits
   * @param subId subscription Id
   */
  function checkAllTimedOutDecommitsForSubscription(
    uint64 subId
  ) public onlyConsumer(subId) {
    bytes32[] memory commitments = rngCommitmentManager.getSelectedCommitments(
      subId,
      msg.sender
    );

    for (uint16 i = 0; i < commitments.length; i++) {
      checkTimedOutDecommit(subId, commitments[i]);
    }
  }
}