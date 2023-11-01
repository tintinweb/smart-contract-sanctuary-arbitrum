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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "./chainlinkHelper/VRFConsumerBaseV2.sol";

interface arbiBallTreasuryInterface {
	function depositFromRaffle(uint32 _raffleId) external payable;
	function withdrawFromRaffle(address payable _user, uint32 _raffleId, uint256 _amount) external;
	function getFundsAccumulatedInRaffle(uint32 _raffleId) external view returns(uint256);
}


contract arbiBall is OwnableUpgradeable , VRFConsumerBaseV2 {

	event NewRaffle(uint256 raffleId);
	event PurchasedTicket(address player, uint256 raffleId, uint256 ticketsPurchased);
	event WinningTicket(uint256 raffleId, Ticket ticket);
	event JackpotClaimed(uint256 raffleId, address player, uint256 amount);
	VRFCoordinatorV2Interface COORDINATOR;
	
	struct Ticket {
		uint8 a;
		uint8 b;
		uint8 c;
		uint8 d;
		uint8 e;
	}
	
	uint32 public raffleId;
	uint8 private turns;
	uint256 public entryFee;
	uint256 public ownerAccumulated;
	
	address public treasuryVault;
	address private vrfCoordinator;
	bytes32 private keyHash;
	uint16 public jackpotCut;
	uint16 private requestConfirmations;
	uint32 private callbackGasLimit;
	uint32 private numWords;
	uint64 private s_subscriptionId;
	uint256 private s__raffleId;
	
	
	mapping (bytes32 => Ticket[]) public players;
	mapping (uint256 => address[]) public raffleEntries;
	mapping (uint256 => Ticket) public winningValues;
	mapping (bytes32 => bool) public hasEntered;
	mapping (bytes32 => bool) public hasClaimed;
	mapping (uint32 => bool) public hasJackpotBeenClaimed;
	mapping (uint32 => uint32) public raffleStartTime;
	mapping (uint32 => bool) public isRaffleOver;
	mapping (address => bool) public isController;
	mapping (uint256 => uint32) private raffleEndReq;
	mapping (uint32 => uint32) public raffleEndTime;

	modifier onlyController {
		require(isController[msg.sender], "Caller is not a controller");
		_;
	}
	
	function initialize(address _vrfCoordinatorAddress, uint64 subscriptionId) public initializer {
		__Ownable_init();
		__VRFConsumerBaseV2_init(_vrfCoordinatorAddress);
		COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
		
		//chainLink Setup
		s_subscriptionId = subscriptionId;
		vrfCoordinator = _vrfCoordinatorAddress;
		keyHash = 0x08ba8f62ff6c40a58877a106147661db43bc58dabfb814793847a839aa03367f;
		callbackGasLimit = 250000;
		requestConfirmations = 3;
		jackpotCut = 75;
	}
	
	function buyTicket(uint32 _raffleId, uint256 numberOfTickets, Ticket[] memory ticket) external payable {
		require(msg.value == entryFee * numberOfTickets, "Incorrect numberOfTickets of ETH sent");
		require(raffleEndTime[_raffleId] > block.timestamp, "Raffle has ended");
		require(raffleStartTime[_raffleId] < block.timestamp, "Raffle has not started yet");
		unchecked {
		for (uint256 i = 0; i < numberOfTickets; i++) {
			players[keccak256(abi.encodePacked(_raffleId, msg.sender))].push(ticket[i]);
		}
		if (hasEntered[keccak256(abi.encodePacked(_raffleId, msg.sender))] == false) {
			raffleEntries[_raffleId].push(msg.sender);
			hasEntered[keccak256(abi.encodePacked(_raffleId,msg.sender))] = true;
		}
	}
		arbiBallTreasuryInterface(treasuryVault).depositFromRaffle{value: msg.value}(_raffleId);
		
		emit PurchasedTicket(msg.sender, _raffleId, numberOfTickets);
	}
	
	function redeemPrize(uint32 _raffleId) external {
		require(!hasClaimed[keccak256(abi.encodePacked(_raffleId,msg.sender))], "Error: Already Prize Claimed");
		require(isRaffleOver[_raffleId], "Raffle is not over yet");
		uint256 ticketsBought = players[keccak256(abi.encodePacked(_raffleId,msg.sender))].length;
		uint256 prize = 0;
		for (uint256 i =0; i < ticketsBought; i++) {
			if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].c == winningValues[_raffleId].c &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].d == winningValues[_raffleId].d &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].e == winningValues[_raffleId].e
			) {
				if (!hasJackpotBeenClaimed[_raffleId]) {
					uint256 jackpotAmount = arbiBallTreasuryInterface(treasuryVault).getFundsAccumulatedInRaffle(_raffleId) * jackpotCut / 100;
					prize += jackpotAmount;
					hasJackpotBeenClaimed[_raffleId] = true;
					emit JackpotClaimed(_raffleId, msg.sender, jackpotAmount);
				}
			}
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].c == winningValues[_raffleId].c &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].d == winningValues[_raffleId].d
			) {
				prize += 0.24891 ether;
			}
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].c == winningValues[_raffleId].c &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].e == winningValues[_raffleId].e
			) {
				prize += 0.0497864 ether;
			}
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].c == winningValues[_raffleId].c
			) {
				prize += 0.00497863 ether;
			}
			
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].e == winningValues[_raffleId].e
			) {
				prize += 0.00248931 ether;
			}
			
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].b == winningValues[_raffleId].b
			) {
				prize += 0.0001 ether;
			}
			
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].a == winningValues[_raffleId].a &&
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].e == winningValues[_raffleId].e
			) {
				prize += 0.0001 ether;
			}
			
			else if (
				players[keccak256(abi.encodePacked(_raffleId,msg.sender))][i].e == winningValues[_raffleId].e
			) {
				prize += 0.0001 ether;
			}
		}
		hasClaimed[keccak256(abi.encodePacked(_raffleId,msg.sender))] = true;
		arbiBallTreasuryInterface(treasuryVault).withdrawFromRaffle(payable(msg.sender),_raffleId,prize);
	}
	
	
	// Owner Functions
	function startRaffle(uint32 endTime) external onlyController {
		startNewRaffle(endTime);
	}
	
	function setEntryFee(uint256 fee) external onlyController {
		entryFee = fee;
	}
	
	function endRaffle(uint32[] calldata _raffleIds) public onlyController {
		for (uint256 i = 0; i < _raffleIds.length; i++) {
			require(raffleEndTime[_raffleIds[i]] < uint32(block.timestamp), "Raffle has not ended yet");
			s__raffleId = COORDINATOR.requestRandomWords(
				keyHash,
				s_subscriptionId,
				requestConfirmations,
				callbackGasLimit * 1,
				1
			);
			raffleEndReq[s__raffleId] = _raffleIds[i];
		}
	}
	
	function setController(address _controller) external onlyOwner {
		isController[_controller] = true;
	}
	
	function setTreasuryVault(address _treasuryVault) external onlyOwner {
		treasuryVault = _treasuryVault;
	}
	
	function setJackpotCut(uint16 _jackpotCut) external onlyOwner {
		jackpotCut = _jackpotCut;
	}
	
	function setWinningNumbers(uint32 _raffleId, Ticket memory winningNumbers) external onlyController {
		winningValues[_raffleId] = winningNumbers;
		isRaffleOver[_raffleId] = true;
		emit WinningTicket(_raffleId, winningValues[_raffleId]);
	}
	
	function prefillRaffle(uint32 _raffleId) external payable onlyController {
		arbiBallTreasuryInterface(treasuryVault).depositFromRaffle{value: msg.value}(_raffleId);
	}
	
	// Getter Functions
	
	function getTickets( uint32 _raffleId, address player ) public view returns(Ticket[] memory) {
		uint256 length =  players[keccak256(abi.encodePacked(_raffleId, player))].length;
		Ticket[] memory tickets = new Ticket[](length);
		for(uint256 i = 0; i < length; i++) {
			tickets[i] = players[keccak256(abi.encodePacked(_raffleId, player))][i];
		}
		return tickets;
	}
	
	function getRaffleEntries(uint256 raffle) public view returns(address[] memory) {
		return raffleEntries[raffle];
	}
	
	function getTotalRaffleEntries(uint256 raffle) public view returns(uint256) {
		return raffleEntries[raffle].length;
	}
	
	function getRaffleEntriesByIndex(uint256 raffle, uint256 index) public view returns(address) {
		return raffleEntries[raffle][index];
	}
	
	function getRafflesToFinalise(uint32 from, uint32 to) public view returns(uint32[] memory) {
		uint32[] memory raffleIds = new uint32[](raffleId);
		for(uint32 i = from; i < to; i++) {
			if(raffleEndTime[i] < uint32(block.timestamp) && !isRaffleOver[i]) {
				raffleIds[i] = i;
			}
		}
		return raffleIds;
	}
	
	// internal functions
	// Contract Internal Functions
	function fulfillRandomWords(
		uint256 _requestId,
		uint256[] memory randomWords
	) internal override {
		inHouseRandomizer(randomWords[0], raffleEndReq[_requestId]);
	}
	
	function inHouseRandomizer(uint256 randomNumber, uint32 _raffleId) internal {
		uint8[5] memory winningNumbers;
		winningNumbers[0] = uint8(uint256(keccak256(abi.encode(randomNumber,block.timestamp, _raffleId))) % 41);
		winningNumbers[1] = uint8(uint256(keccak256(abi.encode(randomNumber, winningNumbers[0],block.timestamp, _raffleId))) % 41);
		if (
			winningNumbers[1] == winningNumbers[0] ||
			winningNumbers[1] == 0
		) {
			turns++;
			inHouseRandomizer(randomNumber+turns, _raffleId);
		}
		winningNumbers[2] = uint8(
			uint256(
				keccak256(
					abi.encode(
						randomNumber,
						winningNumbers[1],
						winningNumbers[0],
						block.timestamp,
						_raffleId
					)
				)
			)
			% 41
		);
		if (
			winningNumbers[2] == winningNumbers[1] ||
			winningNumbers[2] == winningNumbers[0] ||
			winningNumbers[2] == 0
		) {
			turns++;
			inHouseRandomizer(randomNumber+turns, _raffleId);
		}
		winningNumbers[3] = uint8(
			uint256(
				keccak256(
					abi.encode(
						randomNumber,
						winningNumbers[2],
						winningNumbers[1],
						winningNumbers[0],
						block.timestamp,
						_raffleId
					)
				)
			) % 41
		);
		if (
			winningNumbers[3] == winningNumbers[2] ||
			winningNumbers[3] == 0
		) {
			turns++;
			inHouseRandomizer(randomNumber+turns, _raffleId);
		}
		winningNumbers[4] = uint8(
			uint256(
				keccak256(
					abi.encode(
						randomNumber,
						winningNumbers[3],
						winningNumbers[2],
						winningNumbers[1],
						winningNumbers[0],
						block.timestamp,
						_raffleId
					)
				)
			) % 10
		);
		winningValues[_raffleId] =  Ticket(
			winningNumbers[0],
			winningNumbers[1],
			winningNumbers[2],
			winningNumbers[3],
			winningNumbers[4]
		);
		
		isRaffleOver[_raffleId] = true;
		turns = 0;
		emit WinningTicket(_raffleId, winningValues[_raffleId]);
	}
	
	function startNewRaffle(uint32 endTime) internal {
		++raffleId;
		raffleStartTime[raffleId] = uint32(block.timestamp);
		raffleEndTime[raffleId] = uint32(endTime);
		emit NewRaffle(raffleId);
	}
}

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
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
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
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
   */
    //  constructor(address _vrfCoordinator) {
    //    vrfCoordinator = _vrfCoordinator;
    //  }

    function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal {
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