// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their respective initializer as
 * @dev shown:
 *
 * @dev   import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
 * @dev   contract VRFConsumer is Initializable, VRFConsumerBaseV2Upgradeable {
 * @dev     initialize(<other arguments>, address _vrfCoordinator) public initializer {
 * @dev         __VRFConsumerBaseV2_init(_vrfCoordinator);
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev The VRFConsumerBaseV2Upgradable is an upgradable variant of VRFConsumerBaseV2
 * @dev (see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable).
 * @dev It's semantics are identical to VRFConsumerBaseV2 and can be inherited from
 * @dev to create an upgradeable VRF consumer contract.
*/
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private vrfCoordinator;

  // See https://github.com/OpenZeppelin/openzeppelin-sdk/issues/37.
  // Each uint256 covers a single storage slot, see https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html.
  uint256[49] private __gap;

  /**
   * @param _vrfCoordinator the VRFCoordinatorV2 address.
   * @dev See https://docs.chain.link/docs/vrf/v2/supported-networks/ for coordinator
   * @dev addresses on your preferred network.
   */
  function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal onlyInitializing {
    if (_vrfCoordinator == address(0)) {
      revert("must give valid coordinator address");
    }

    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./interface/IHiLo.sol";
import "./libraries/FixedMath.sol";
import "./utils/OwnableUpgradeable.sol";
import "./utils/VRFConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @title HiLo
 * @notice This contract represents the implementation of the HiLo betting game.
 */
contract HiLo is VRFConsumer, OwnableUpgradeable, IHiLo {
    using FixedMath for *;

    uint256 constant CORNER_ODDS = 1025000000000; // odds for corner cards
    uint8 constant FIRST_CARD_INDEX = 27; // eight spides card
    uint8 constant RANKS = 13; // ranks count
    uint8 constant SUITS = 4; // suits count
    uint8 constant ALL_CARDS = RANKS * SUITS; // cards count in deck

    uint256 lastGameId; // last id of created game
    uint128 public lockedLiquidity; // Amount of liquidity locked in the contract
    address public payableToken;
    uint64 public resultPeriod; // Time after which bets can be refunded

    uint256[52] public cards; // deck cards
    Deck[] public decks; // added decks for games

    /**
     * cards odds
     * first 44 bits for hi next for lo
     */
    uint256[13] public odds;

    mapping(address => mapping(uint256 => uint256)) public availableFreebets; // player => deckIndex => freebets count
    mapping(uint256 => GameBonuses) public bonuses; // gameId => GameBonuses
    mapping(uint256 => Game) public games; // gameId => Game
    mapping(address => mapping(uint256 => uint256[])) ownedDeckGames; // player => deckIndex => gameId[]
    mapping(uint256 => Prediction) public predictions; // requestId => Prediction

    /**
     * @notice See {IHiLo-initialize}.
     */
    function initialize(
        address vrf,
        uint64 consumerId_,
        bytes32 keyHash_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_,
        address payableToken_,
        uint64 resultPeriod_
    ) external virtual initializer {
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrf);

        coordinator = VRFCoordinatorV2Interface(vrf);
        consumerId = consumerId_;
        keyHash = keyHash_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;
        numWords = 1;

        payableToken = payableToken_;
        resultPeriod = resultPeriod_;

        uint8 counter;
        for (uint8 rankIndex = 0; rankIndex < RANKS; ++rankIndex) {
            for (uint8 suitIndex = 0; suitIndex < SUITS; ++suitIndex) {
                uint8 suit = suitIndex;
                uint8 rank = rankIndex << 2;
                cards[counter++] = suit | rank;
            }
        }

        odds[0] = CORNER_ODDS;
        odds[12] = CORNER_ODDS << 44;
        for (uint8 rank = 1; rank <= 6; ++rank) {
            uint256 hiCards = (RANKS - rank - 1) * SUITS;
            uint256 hiCardsOdds = hiCards.div(ALL_CARDS - 1);

            uint256 loCards = rank * SUITS;
            uint256 loCardsOdds = loCards.div(ALL_CARDS - 1);

            uint256 hiOdds = FixedMath.ONE.div(
                hiCardsOdds.div(hiCardsOdds + loCardsOdds)
            );
            uint256 loOdds = FixedMath.ONE.div(
                loCardsOdds.div(hiCardsOdds + loCardsOdds)
            );

            // odds for 1 - 6 ranks
            odds[rank] = hiOdds | (loOdds << 44);

            // mirrored odds for 7 - 11 ranks
            if (rank != 6) {
                odds[RANKS - rank - 1] = (hiOdds << 44) | loOdds;
            }
        }
    }

    /**
     * @notice Adds new deck in decks array
     * @param newDeck the new deck data
     */
    function addDeck(Deck calldata newDeck) external onlyOwner {
        if (newDeck.minBet == 0) revert IncorrectDeckMinBet();
        decks.push(newDeck);
        emit DeckAdded(newDeck);
    }

    /**
     * @notice Changes existing deck data
     * @param index the index of deck in decks array
     * @param newDeck the new deck data
     */
    function changeDeck(uint8 index, Deck calldata newDeck) external onlyOwner {
        if (index >= decks.length) revert IncorrectDeckIndex();
        if (newDeck.minBet == 0) revert IncorrectDeckMinBet();
        decks[index] = newDeck;
        emit DeckChanged(index, newDeck);
    }

    /**
     * @notice Changes the result period in seconds
     * @param newResultPeriod the new result period in seconds
     */
    function changeResultPeriod(uint64 newResultPeriod) external onlyOwner {
        if (newResultPeriod == 0) revert IncorrectResultPeriod();
        resultPeriod = newResultPeriod;
        emit ResultPeriodChanged(newResultPeriod);
    }

    /**
     * @notice Changes the vrf
     * @param newVrf the new vrf coordinator
     * @param newConsumerId the new consumer id
     */
    function changeVrf(
        address newVrf,
        uint64 newConsumerId,
        uint16 newRequestConfirmations,
        bytes32 newKeyHash
    ) external onlyOwner {
        if (newVrf == address(0)) revert IncorrectVrf();
        if (newConsumerId == 0) revert IncorrectConsumerId();
        if (
            newRequestConfirmations < MINREQUESTCONFIRMATIONS ||
            newRequestConfirmations > MAXREQUESTCONFIRMATIONS
        ) revert IncorrectRequestConfirmations();

        coordinator = VRFCoordinatorV2Interface(newVrf);
        consumerId = newConsumerId;
        requestConfirmations = newRequestConfirmations;
        keyHash = newKeyHash;
        emit VrfChanged(
            newVrf,
            newConsumerId,
            newRequestConfirmations,
            newKeyHash
        );
    }

    /**
     * @notice Withdraws all available liquidity from the contact
     * @param to withdraw the liquidity to
     */
    function withdrawAllAvailableLiquidity(address to) external onlyOwner {
        uint128 availableLiquidity = getAvailableLiquidity();
        if (availableLiquidity == 0) revert ZeroLiquidity();

        TransferHelper.safeTransfer(payableToken, to, availableLiquidity);
        emit LiquidityWithdrawn(to, availableLiquidity);
    }

    /**
     * @notice Adds liquidity for contract
     * @param amount the amount of provided liquidity
     */
    function addLiquidity(uint128 amount) external {
        TransferHelper.safeTransferFrom(
            payableToken,
            msg.sender,
            address(this),
            amount
        );

        emit LiquidityAdded(msg.sender, amount);
    }

    /**
     * @notice Places a new bet
     * @param gameId the game id
     * @param value the prediction value
     */
    function bet(uint256 gameId, PredictionValue value) external {
        Game storage game = _getGame(gameId);

        if (game.owner != msg.sender) revert NotGameOwner();
        if (game.requestId != 0) revert AwaitingVRF(game.requestId);

        uint256 predictionOdds = getPredictionOdds(game.cardIndex, value);

        if (predictionOdds == 0) revert IncorrectPredictionValue();

        uint128 betAmount;
        GameBonuses storage gameBonuses = bonuses[gameId];

        if (gameBonuses.isFreebet) {
            betAmount = game.betAmount;
            gameBonuses.isFreebet = false;
        } else if (game.bank > 0) {
            betAmount = game.bank;
        } else {
            betAmount = game.betAmount;

            TransferHelper.safeTransferFrom(
                payableToken,
                msg.sender,
                address(this),
                betAmount
            );
        }

        uint256 requestId = requestRandomWords();
        uint128 possiblePayout = uint128(
            betAmount.mul(predictionOdds) - game.bank
        );
        uint128 lockedAmount = possiblePayout;

        Deck storage deck = decks[game.deckIndex];

        uint8 x2CardIndex = deck.x2.cardIndex;

        if (
            deck.x2.isEnabled &&
            _isCardInPredictionRange(value, x2CardIndex, game)
        ) {
            lockedAmount *= 2;
        }

        if (lockedAmount > getAvailableLiquidity()) revert BetTooBig();

        lockedLiquidity += lockedAmount;

        Prediction memory prediction = Prediction(
            gameId,
            possiblePayout,
            lockedAmount,
            uint64(block.timestamp + resultPeriod),
            value
        );

        predictions[requestId] = prediction;
        game.requestId = requestId;

        emit NewBet(msg.sender, gameId, game, prediction);
    }

    /**
     * @notice Creates a game with freebet
     * @param deckIndex the deck index of decks array
     */
    function createFreebetGame(uint8 deckIndex) external {
        if (availableFreebets[msg.sender][deckIndex] == 0)
            revert FreebetNotExist();

        uint256 gameId = _createGame(decks[deckIndex].minBet, deckIndex);
        --availableFreebets[msg.sender][deckIndex];
        bonuses[gameId] = GameBonuses(0, true);
    }

    /**
     * @notice Creates a new game game
     * @param betAmount the bet amount
     * @param deckIndex the deck index of decks array
     */
    function createGame(uint128 betAmount, uint8 deckIndex) external {
        _createGame(betAmount, deckIndex);
    }

    /**
     * @notice Get added decks
     * @return result the decks
     */
    function getDecks() external view returns (Deck[] memory result) {
        result = new Deck[](decks.length);

        for (uint256 i = 0; i < decks.length; ++i) {
            result[i] = decks[i];
        }
    }

    /**
     * @notice Get odds for all ranks
     * @return odds array
     */
    function getOdds() external view returns (uint256[13] memory) {
        return odds;
    }

    /**
     * @notice Get created user game ids
     * @return game ids
     */
    function getUserGames(address user, uint256 deckIndex)
        external
        view
        returns (uint256[] memory)
    {
        return ownedDeckGames[user][deckIndex];
    }

    /**
     * @notice Withdraw the payout for a won and refunded bet
     */
    function withdrawPayout(uint256 gameId) external {
        Game storage game = _getGame(gameId);

        if (game.owner != msg.sender) revert NotGameOwner();

        uint128 payout;

        if (game.requestId != 0) {
            Prediction storage prediction = predictions[game.requestId];

            if (
                prediction.refundAfter != 0 &&
                prediction.refundAfter > block.timestamp
            ) revert AwaitingVRF(game.requestId);

            payout += game.betAmount;
            lockedLiquidity -= prediction.lockedAmount;

            delete predictions[game.requestId];
            game.requestId = 0;
        }

        if (game.bank != 0) {
            payout += game.bank;

            game.bank = 0;
            lockedLiquidity -= payout;
        }

        if (payout == 0) revert ZeroPayout();

        TransferHelper.safeTransfer(payableToken, msg.sender, payout);

        emit WithdrawPayout(msg.sender, payout);
    }

    /**
     * @notice Get the amount of available liquidity in the contract
     * @return the available liquidity amount
     */
    function getAvailableLiquidity() public view returns (uint128) {
        return
            uint128(
                IERC20(payableToken).balanceOf(address(this)) - lockedLiquidity
            );
    }

    /**
     * @notice Get an odds for provided card and prediction
     * @param cardIndex the card index of cards array
     * @param value the prediction value
     * @return predictionOdds
     */
    function getPredictionOdds(uint8 cardIndex, PredictionValue value)
        public
        view
        returns (uint256 predictionOdds)
    {
        uint256 card = cards[cardIndex];
        uint256 rank = card >> 2;

        uint256 oddsNum = odds[rank];

        if (value == PredictionValue.Hi) {
            uint256 bitMask = 17592186044415; // 44 bits
            predictionOdds = oddsNum & bitMask;
        } else {
            predictionOdds = oddsNum >> 44;
        }
    }

    /**
     * @notice Fulfills the requested number of random words for the game's result
     * @param requestId the ID of the Chainlink request
     * @param randomWords_ the random words to fulfill the request
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords_
    ) internal override {
        Prediction storage prediction = predictions[requestId];
        Game storage game = games[prediction.gameId];

        uint8 randomCardIndex = uint8(randomWords_[0] % ALL_CARDS);

        if (randomCardIndex == game.cardIndex) {
            if (game.cardIndex == ALL_CARDS - 1) {
                randomCardIndex = 0;
            } else {
                ++randomCardIndex;
            }
        }

        Deck storage deck = decks[game.deckIndex];
        GameBonuses storage gameBonuses = bonuses[prediction.gameId];

        bool isSameRank = cards[randomCardIndex] >> 2 ==
            cards[game.cardIndex] >> 2;

        bool isWin = !isSameRank &&
            _isCardInPredictionRange(prediction.value, randomCardIndex, game);

        bool isX2 = deck.x2.isEnabled && randomCardIndex == deck.x2.cardIndex;

        bool isInsurance = deck.insurance.isEnabled &&
            randomCardIndex == deck.insurance.cardIndex;

        bool isFreebet = deck.freebet.isEnabled &&
            randomCardIndex == deck.freebet.cardIndex;

        if (isInsurance) {
            ++gameBonuses.insurances;
        }

        if (isFreebet) {
            ++availableFreebets[game.owner][game.deckIndex];
        }

        uint128 payout;
        uint128 lockedLiquidityChange = prediction.lockedAmount;

        if (isWin) {
            payout = prediction.possiblePayout;
        } else if (gameBonuses.insurances > 0) {
            payout = prediction.possiblePayout;
            --gameBonuses.insurances;
        }

        if (payout == 0) {
            if (game.bank > 0) {
                lockedLiquidityChange += game.bank;
                game.bank = 0;
            }
        } else {
            if (isX2) {
                payout *= 2;
            }

            game.bank += payout;
            lockedLiquidityChange -= payout;
        }

        if (lockedLiquidityChange > 0) {
            lockedLiquidity -= lockedLiquidityChange;
        }

        delete predictions[requestId];
        game.requestId = 0;

        emit GameResultFulfilled(
            requestId,
            game.owner,
            game.cardIndex,
            randomCardIndex,
            game.bank,
            payout,
            isFreebet,
            isInsurance,
            isX2
        );
        
        game.cardIndex = randomCardIndex;
    }

    /**
     * @notice Creates and stores a new game
     * @param betAmount the bet amount
     * @param deckIndex the deck index of decks array
     * @return newGameId the id of new game
     */
    function _createGame(uint128 betAmount, uint8 deckIndex)
        internal
        returns (uint256)
    {
        if (deckIndex > decks.length - 1) revert IncorrectDeckIndex();

        Deck storage deck = decks[deckIndex];
        if (deck.isDisabled) revert DeckDisabled();
        if (betAmount < deck.minBet) revert TooSmallBetAmount();

        // prevent game creation if we don't have liquidity for first bet
        uint128 possiblePayout = uint128(
            betAmount.mul(
                getPredictionOdds(FIRST_CARD_INDEX, PredictionValue.Hi)
            )
        );
        if (possiblePayout > getAvailableLiquidity()) revert BetTooBig();

        uint256 newGameId = ++lastGameId;

        ownedDeckGames[msg.sender][deckIndex].push(newGameId);

        Game storage game = games[newGameId];
        game.cardIndex = FIRST_CARD_INDEX;
        game.deckIndex = deckIndex;
        game.betAmount = betAmount;
        game.owner = msg.sender;

        emit NewGameCreated(msg.sender, newGameId, game);

        return newGameId;
    }

    /**
     * @notice Get game by game id
     * @param gameId the game id
     * @return game
     */
    function _getGame(uint256 gameId)
        internal
        view
        returns (Game storage game)
    {
        game = games[gameId];
        if (game.betAmount == 0) revert GameNotExist();
    }

    /**
     * @notice Check if card in prediction range for game
     * @param value the prediction value
     * @param cardIndex the verifiable index of card
     * @param game the user's game
     * @return bool
     */
    function _isCardInPredictionRange(
        PredictionValue value,
        uint256 cardIndex,
        Game storage game
    ) internal view returns (bool) {
        return
            (value == PredictionValue.Hi && cardIndex > game.cardIndex) ||
            (value == PredictionValue.Lo && cardIndex < game.cardIndex);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IOwnable.sol";

interface IHiLo is IOwnable {
    /**
     * @dev This enum represents a next card prediction.
     */
    enum PredictionValue {
        Hi,
        Lo
    }

    /**
     * @dev This struct represents a deck bonus.
     */
    struct Bonus {
        uint8 cardIndex; // card index of cards array
        bool isEnabled; // enable/disable bonus
    }

    /**
     * @dev This struct represents a deck for game.
     */
    struct Deck {
        uint128 minBet; // minimum bet amount
        bool isDisabled; // enable/disable deck for new game creation
        Bonus freebet; // freebet bonus
        Bonus insurance; // insurance bonus
        Bonus x2; // x2 bonus
    }

    /**
     * @dev This struct represents a game played by a player.
     */
    struct Game {
        address owner; // game owner
        uint8 cardIndex; // last generated card index of cards array
        uint8 deckIndex; // deck index of decks array
        uint128 betAmount; // amount of a bet
        uint128 bank; // available game bank for bet or withdraw
        uint256 requestId; // request id of Chainlink request
    }

    /**
     * @dev This struct represents a game bonuses.
     */
    struct GameBonuses {
        uint8 insurances; // number of received insurances
        bool isFreebet; // indicates freebet available
    }

    /**
     * @dev This struct represents a prediction for next card.
     */
    struct Prediction {
        uint256 gameId; // game id
        uint128 possiblePayout; // potential payout for winning
        uint128 lockedAmount; // reserved liquidity for payout
        uint64 refundAfter; // refund date
        PredictionValue value; // next card prediction
    }

    event GameResultFulfilled(
        uint256 indexed requestId,
        address indexed player,
        uint8 prevCardIndex,
        uint8 cardIndex,
        uint128 bank,
        uint128 payout,
        bool isFreebet,
        bool isInsurance,
        bool isX2
    );
    event LiquidityWithdrawn(address indexed user, uint128 amount);

    event NewBet(
        address player,
        uint256 indexed gameId,
        Game game,
        Prediction prediction
    );
    event WithdrawPayout(address player, uint128 payout);

    event DeckAdded(Deck newDeck);
    event DeckChanged(uint8 index, Deck newDeck);
    event LiquidityAdded(address account, uint128 amount);
    event NewGameCreated(address player, uint256 gameId, Game game);
    event ResultPeriodChanged(uint64 newResultPeriod);
    event VrfChanged(
        address indexed newVrf,
        uint64 newCondumerId,
        uint16 newRequestConfirmations,
        bytes32 newKeyHash
    );

    error AwaitingVRF(uint256 requestID);
    error FreebetNotExist();
    error DeckDisabled();
    error GameNotExist();
    error NotGameOwner();

    error IncorrectConsumerId();
    error IncorrectDeckIndex();
    error IncorrectDeckMinBet();
    error IncorrectPredictionValue();
    error IncorrectRequestConfirmations();
    error IncorrectResultPeriod();
    error IncorrectVrf();

    error BetTooBig();
    error TooSmallBetAmount();
    error ZeroPayout();
    error ZeroLiquidity();

    /**
     * @dev Initializes the contract
     * @param vrf address of the VRF coordinator contract
     * @param consumerId_ consumer ID used for VRF requests
     * @param keyHash_ key hash used for VRF requests
     * @param requestConfirmations_ number of VRF request confirmations
     * @param callbackGasLimit_ gas limit for VRF request callbacks
     * @param payableToken_ betting token
     * @param resultPeriod_ time after which bets can be refunded
     */
    function initialize(
        address vrf,
        uint64 consumerId_,
        bytes32 keyHash_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_,
        address payableToken_,
        uint64 resultPeriod_
    ) external;

    function addDeck(Deck memory newDeck) external;

    function addLiquidity(uint128 amount) external;

    function bet(uint256 gameId, PredictionValue value) external;

    function changeDeck(uint8 index, Deck memory newDeck) external;

    function changeResultPeriod(uint64 newResultPeriod) external;

    function changeVrf(
        address newVrf,
        uint64 newConsumerId,
        uint16 newRequestConfirmations,
        bytes32 newKeyHash
    ) external;

    function createFreebetGame(uint8 deckIndex) external;

    function createGame(uint128 betAmount, uint8 deckIndex) external;

    function getDecks() external view returns (Deck[] memory result);

    function getOdds() external view returns (uint256[13] memory);

    function getUserGames(address user, uint256 deckIndex)
        external
        view
        returns (uint256[] memory);

    function withdrawAllAvailableLiquidity(address to) external;

    function withdrawPayout(uint256 gameId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function checkOwner(address account) external view;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Fixed-point math tools
library FixedMath {
    uint256 constant ONE = 1e12;

    /**
     * @notice Get the ratio of `self` and `other` that is larger than 'ONE'.
     */
    function ratio(uint256 self, uint256 other)
        internal
        pure
        returns (uint256)
    {
        return self > other ? div(self, other) : div(other, self);
    }

    function mul(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * other) / ONE;
    }

    function div(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * ONE) / other;
    }

    /**
     * @notice Implementation of the sigmoid function.
     * @notice The sigmoid function is commonly used in machine learning to limit output values within a range of 0 to 1.
     */
    function sigmoid(uint256 self) internal pure returns (uint256) {
        return (self * ONE) / (self + ONE);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interface/IOwnable.sol";

/**
 * @dev Forked from OpenZeppelin contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/ae03ee04ae226526abad6731cf4024134f46ae28/contracts/access/OwnableUpgradeable.sol
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
abstract contract OwnableUpgradeable is
    IOwnable,
    Initializable,
    ContextUpgradeable
{
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the account is not the owner.
     */
    function checkOwner(address account) public view virtual override {
        require(owner() == account, "Ownable: account is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBaseV2Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

abstract contract VRFConsumer is VRFConsumerBaseV2Upgradeable {
    uint16 public constant MAXREQUESTCONFIRMATIONS = 200;
    uint16 public constant MINREQUESTCONFIRMATIONS = 3;

    VRFCoordinatorV2Interface public coordinator;

    uint64 public consumerId;
    bytes32 public keyHash;
    uint32 public numWords;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = coordinator.requestRandomWords(
            keyHash,
            consumerId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        return requestId;
    }
}