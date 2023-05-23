// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRaffleChef} from "../interfaces/IRaffleChef.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";
import {IRandomProvider} from "./IRandomProvider.sol";

/// @title FairyRaffle (VRF)
/// @author kevincharm
/// @notice The "classic" Fairymint raffler:
///     * Off-chain collection
///         Collect your participants off-chain. All this contract needs is a
///         final merkle root of all the participants. This provides
///         _transparency_: participants can verify that they are included in
///         the participants list and that the merkle root correctly
///         represents a publicly-provided participants list.
///     * On-chain raffle
///         The drawing of random numbers & picking of winners is performed
///         entirely on-chain. This provides _immutability_ and
///         _trustlessness_: the resulting list of winners must be drawn
///         according to the random number and algorithm and therefore is
///         impossible to manipulate, given the random number source is also
///         secure. The algorithm, while efficient enough for on-chain
///         execution, is based on secure cryptographic building blocks: Merkle
///         trees and Feistel ciphers.
///     * Off-chain distribution
///         The winners of the raffle can be computed from the results of the
///         on-chain raffle. As with off-chain collection, this provides
///         _transparency_: participants can verify that the list of winners
///         is indeed correct given the results of the on-chain raffle.
///     Customised for FVM: sourcing randomness from built-in drand
contract FairyRaffle is
    IRandomiserCallback,
    TypeAndVersion,
    OwnableUpgradeable
{
    /// @notice RaffleChef
    address public raffleChef;
    /// @notice Randomiser
    address public randomiser;
    /// @notice FairyRaffleFactory
    address public factory;

    /// @notice Merkle root (commitment) of raffle participants
    bytes32 public participantsMerkleRoot;
    /// @notice Number of raffle participants
    uint256 public nParticipants;
    /// @notice Number of winners that should be drawn during raffle
    uint256 public nWinners;
    /// @notice For record of provenance; could be e.g. an IPFS content hash
    ///     of participants list. This is not used on-chain.
    string public provenance;

    /// @notice The requestId returned by the randomiser
    uint256 public requestId;
    /// @notice The raffleId returned by RaffleChef
    uint256 public raffleId;
    /// @notice Callback gas limit for receiving random numbers
    uint32 public constant CALLBACK_GAS_LIMIT = 500_000;

    constructor() {
        _disableInitializers();
    }

    function typeAndVersion() external pure override returns (string memory) {
        return "FairyRaffle 1.0.0";
    }

    /// @notice Commit to a participants list and start the raffle by
    ///     requesting a random number from drand.
    /// @dev Assumes this is called by the factory.
    /// @param minBlocksToWait How many (minimum) block confirmations before
    ///     the VRF
    function init(
        address raffleChef_,
        address randomiser_,
        bytes32 participantsMerkleRoot_,
        uint256 nParticipants_,
        uint256 nWinners_,
        string calldata provenance_,
        uint16 minBlocksToWait
    ) public payable initializer {
        __Ownable_init();

        raffleChef = raffleChef_;
        randomiser = randomiser_;

        participantsMerkleRoot = participantsMerkleRoot_;
        nParticipants = nParticipants_;
        nWinners = nWinners_;
        provenance = provenance_;

        factory = msg.sender;
        requestId = IRandomProvider(msg.sender).getRandomNumber{
            value: msg.value
        }(500_000, minBlocksToWait);
    }

    /// @notice See {IRandomiserCallback-receiveRandomWords}
    /// @notice When this function is called by the randomiser, the raffle is
    ///     finalised with a random seed on the RaffleChef, and the winners
    ///     may instantly be queried on the RaffleChef.
    function receiveRandomWords(
        uint256 requestId_,
        uint256[] calldata randomWords
    ) external {
        require(msg.sender == randomiser, "Only randomiser may call");
        uint256 rid = requestId;
        require(rid != 0, "Not rolled yet");
        require(requestId_ == rid, "Request ID mismatch");
        require(raffleId == 0, "Raffle already finalised");

        raffleId = IRaffleChef(raffleChef).commit(
            participantsMerkleRoot,
            nParticipants,
            nWinners,
            provenance,
            randomWords[0]
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {IRandomProvider} from "./IRandomProvider.sol";
import {Sets} from "../vendor/Sets.sol";
import {Withdrawable} from "../vendor/Withdrawable.sol";
import {FairyRaffle} from "./FairyRaffle.sol";
import {LinklessVRF} from "../randomisers/LinklessVRF.sol";

/// @title FairyRaffleFactory
/// @author kevincharm
/// @notice Deploys classic raffles!
contract FairyRaffleFactory is
    TypeAndVersion,
    Initializable,
    IRandomProvider,
    UUPSUpgradeable,
    OwnableUpgradeable,
    Withdrawable
{
    using Sets for Sets.Set;
    /// @notice Set of deployed rafflers
    Sets.Set private rafflers;
    /// @notice Master copy of ClassicRaffler
    address public rafflerMasterCopy;
    /// @notice RaffleChef
    address public raffleChef;
    /// @notice Randomiser
    address public randomiser;
    /// @notice User nonces
    mapping(address => uint256) public nonces;
    /// @notice Fee for creating a raffle
    uint256 public fee;

    uint256[44] private __ClassicRafflerFactory_gap;

    event RafflerMasterCopyUpdated(address oldRaffler, address newRaffler);
    event RaffleChefUpdated(address oldRaffleChef, address newRaffleChef);
    event RandomiserUpdated(address oldRandomiser, address newRandomiser);
    event RafflerDeployed(address raffler);
    event FeeChanged(uint256 oldFee, uint256 newFee);
    event FeePaid(uint256 fee);
    error InsufficientFeePayment(uint256 amountOffered, uint256 amountRequired);

    constructor() {
        _disableInitializers();
    }

    function init(
        uint256 fee_,
        address rafflerMasterCopy_,
        address raffleChef_,
        address randomiser_
    ) public initializer {
        __Ownable_init();
        rafflers.init();
        fee = fee_;
        rafflerMasterCopy = rafflerMasterCopy_;
        raffleChef = raffleChef_;
        randomiser = randomiser_;
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "FairyRaffleFactory 1.0.0";
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _authoriseWithdrawal() internal override onlyOwner {}

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function setFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = fee;
        fee = newFee;
        emit FeeChanged(oldFee, newFee);
    }

    function setRafflerMasterCopy(address newRafflerMasterCopy)
        external
        onlyOwner
    {
        address oldMasterCopy = rafflerMasterCopy;
        rafflerMasterCopy = newRafflerMasterCopy;
        emit RafflerMasterCopyUpdated(oldMasterCopy, newRafflerMasterCopy);
    }

    function setRaffleChef(address newRaffleChef) external onlyOwner {
        address oldRaffleChef = raffleChef;
        raffleChef = newRaffleChef;
        emit RaffleChefUpdated(oldRaffleChef, newRaffleChef);
    }

    function setRandomiser(address newRandomiser) external onlyOwner {
        address oldRandomiser = randomiser;
        randomiser = newRandomiser;
        emit RandomiserUpdated(oldRandomiser, newRandomiser);
    }

    /// @notice See {IRandomProvider-computeRandomNumberRequestCost}
    function computeRandomNumberRequestCost(uint32 callbackGasLimit)
        public
        view
        returns (uint256)
    {
        return
            LinklessVRF(payable(randomiser)).computeTotalRequestCostETH(
                callbackGasLimit
            );
    }

    /// @notice See {IRandomProvider-getRandomNumber}
    function getRandomNumber(uint32 callbackGasLimit, uint16 minBlocksToWait)
        external
        payable
        returns (uint256)
    {
        require(isRaffler(msg.sender), "Caller must be a raffler");
        LinklessVRF rand = LinklessVRF(payable(randomiser));
        uint256 totalRequestETH = rand.computeTotalRequestCostETH(
            callbackGasLimit
        );
        if (msg.value < totalRequestETH) {
            revert InsufficientFeePayment(msg.value, totalRequestETH);
        }
        return
            LinklessVRF(payable(randomiser)).getRandomNumber{
                value: totalRequestETH
            }(msg.sender, callbackGasLimit, minBlocksToWait, 1);
    }

    /// @notice Create a raffler!
    function createRaffle(
        bytes32 participantsMerkleRoot_,
        uint256 nParticipants_,
        uint256 nWinners_,
        string calldata provenance_,
        uint16 minBlocksToWait
    ) external payable returns (address) {
        uint256 vrfRequestCostETH = computeRandomNumberRequestCost(
            FairyRaffle(rafflerMasterCopy).CALLBACK_GAS_LIMIT()
        );
        require(fee >= vrfRequestCostETH, "VRF request cost too high");
        require(msg.value >= fee, "Insufficient fee payment");
        emit FeePaid(msg.value);

        address rafflerProxy = Clones.clone(rafflerMasterCopy);
        rafflers.add(rafflerProxy);
        FairyRaffle(rafflerProxy).init{value: vrfRequestCostETH}(
            raffleChef,
            randomiser,
            participantsMerkleRoot_,
            nParticipants_,
            nWinners_,
            provenance_,
            minBlocksToWait
        );
        FairyRaffle(rafflerProxy).transferOwnership(msg.sender);
        emit RafflerDeployed(rafflerProxy);
        return rafflerProxy;
    }

    /// @notice Returns true if `raffler` was deployed by this factory
    /// @param raffler Contract address of deployed raffler
    function isRaffler(address raffler) public view returns (bool) {
        return rafflers.has(raffler);
    }

    /// @notice Fetch paginated list of deployed rafflers
    /// @param startFrom Raffle address to start fetching from
    /// @param pageSize Maximum size of returned list
    function getRafflersPaginated(address startFrom, uint256 pageSize)
        external
        view
        returns (address[] memory out, address next)
    {
        out = new address[](pageSize);

        address element = rafflers.ll[startFrom];
        uint256 i;
        if (startFrom > address(0x1) && element != address(0)) {
            out[i] = startFrom;
            unchecked {
                ++i;
            }
        }
        for (
            ;
            i < pageSize && element != address(0) && element != address(0x1);
            ++i
        ) {
            out[i] = element;
            element = rafflers.prev(element);
        }
        assembly {
            // Change size of output arrays to number of fetched addresses
            mstore(out, i)
        }
        return (out, element);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ChainlinkVRFV2Randomiser} from "../randomisers/ChainlinkVRFV2Randomiser.sol";

interface IRandomProvider {
    /// @notice Compute the required ETH to get a random number
    /// @param callbackGasLimit Gas limit to use for callback
    function computeRandomNumberRequestCost(uint32 callbackGasLimit)
        external
        returns (uint256);

    /// @notice Get a random number from
    /// @param callbackGasLimit Gas limit to use for callback
    /// @param minBlocksToWait Minimum confirmations to wait
    function getRandomNumber(uint32 callbackGasLimit, uint16 minBlocksToWait)
        external
        payable
        returns (uint256 requestId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

interface IRaffleChef {
    event RaffleCreated(uint256 indexed raffleId);
    event RaffleCommitted(uint256 indexed raffleId);

    error RaffleNotRolled(uint256 raffleId);
    error InvalidCommitment(
        uint256 raffleId,
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        uint256 randomness,
        string provenance
    );
    error Unauthorised(address unauthorisedUser);
    error StartingRaffleIdTooLow(uint256 raffleId);
    error InvalidProof(bytes32 leaf, bytes32[] proof);

    /// @dev Descriptive state of a raffle based on its variables that are set/unset
    enum RaffleState {
        /// @dev Default state
        Unknown,
        /// @dev Done
        Committed
    }

    /// @notice Structure of every raffle; presence of certain elements indicate the raffle state
    struct Raffle {
        bytes32 participantsMerkleRoot;
        uint256 nParticipants;
        uint256 nWinners;
        uint256 randomSeed;
        address owner;
        string provenance;
    }

    /// @notice Publish a commitment (the merkle root of the finalised participants list, and
    ///     the number of winners to draw, and the random seed). Only call this function once
    ///     the random seed and list of raffle participants has finished being collected.
    /// @param participantsMerkleRoot Merkle root constructed from finalised participants list
    /// @param nWinners Number of winners to draw
    /// @param provenance IPFS CID of this raffle's provenance including full participants list
    /// @param randomness Random seed for the raffle
    /// @return Raffle ID that can be used to lookup the raffle results, when
    ///     the raffle is finalised.
    function commit(
        bytes32 participantsMerkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        string calldata provenance,
        uint256 randomness
    ) external returns (uint256);

    /// @notice Get the nth-drawn winner of the raffle with raffleId.
    ///     NB: 0-based.
    /// @param raffleId ID of the raffle to check
    /// @param n nth winner
    function getNthWinner(uint256 raffleId, uint256 n)
        external
        view
        returns (uint256);

    /// @notice Get a list of winners in a range.
    /// @param raffleId ID of the raffle to check
    /// @param from Winner index to start from (0-based)
    /// @param to Winner index to stop at (exclusive)
    function getWinners(
        uint256 raffleId,
        uint256 from,
        uint256 to
    ) external view returns (uint256[] memory);

    /// @notice Verify that an account is in the winners list for a specific raffle
    ///     using a merkle proof and the raffle's previous public commitments. This is
    ///     a view-only function that does not record if a winner has already claimed
    ///     their win; that is left up to the caller to handle.
    /// @param raffleId ID of the raffle to check against
    /// @param leafHash Hash of the leaf value that represents the participant
    /// @param proof Merkle subproof (hashes)
    /// @param originalIndex Original leaf index in merkle tree, part of merkle proof
    /// @return isWinner true if claiming account is indeed a winner
    /// @return permutedIndex winning (shuffled) index
    function verifyWinner(
        uint256 raffleId,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 originalIndex
    ) external view returns (bool isWinner, uint256 permutedIndex);

    /// @notice Get an existing raffle
    /// @param raffleId ID of raffle to get
    /// @return raffle data, if it exists
    function getRaffle(uint256 raffleId) external view returns (Raffle memory);

    /// @notice Get the current state of raffle, given a `raffleId`
    /// @param raffleId ID of raffle to get
    /// @return See {RaffleState} enum
    function getRaffleState(uint256 raffleId)
        external
        view
        returns (RaffleState);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

interface IRandomiserCallback {
    /// @notice Receive random words from a randomiser.
    /// @dev Ensure that proper access control is enforced on this function;
    ///     only the designated randomiser may call this function and the
    ///     requestId should be as expected from the randomness request.
    /// @param requestId The identifier for the original randomness request
    /// @param randomWords An arbitrary array of random numbers
    function receiveRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title WETH9
interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
/**
    The MIT License (MIT)

    Copyright (c) 2018 SmartContract ChainLink, Ltd.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

pragma solidity ^0.8;

abstract contract TypeAndVersion {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {Authorised} from "../vendor/Authorised.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";

/// @title ChainlinkVRFV2Randomiser
/// @author kevincharm
/// @notice Consume Chainlink's subscription-managed VRFv2 wrapper to return a
///     random number.
/// @dev NB: Not audited.
contract ChainlinkVRFV2Randomiser is
    TypeAndVersion,
    Authorised,
    VRFConsumerBaseV2
{
    /// --- VRF SHIT ---
    /// @notice VRF Coordinator (V2)
    /// @dev https://docs.chain.link/vrf/v2/subscription/supported-networks
    address public immutable vrfCoordinator;
    /// @notice LINK token (make sure it's the ERC-677 one)
    /// @dev PegSwap: https://pegswap.chain.link
    address public immutable linkToken;
    /// @notice LINK token unit
    uint256 public immutable juels;
    /// @dev VRF Coordinator LINK premium per request
    uint256 public immutable linkPremium;
    /// @notice Each gas lane has a different key hash; each gas lane
    ///     determines max gwei that will be used for the callback
    bytes32 public immutable gasLaneKeyHash;
    /// @notice Max gas price for gas lane used in gasLaneKeyHash
    /// @dev This is used purely for gas estimation
    uint256 public immutable gasLaneMaxWei;
    /// @notice Absolute gas limit for callbacks
    uint32 public immutable callbackGasLimit;
    /// @notice VRF subscription ID; created during deployment
    uint64 public immutable subId;

    /// @notice requestId => contract to callback
    /// @dev contract must implement IRandomiserCallback
    mapping(uint256 => address) public callbackTargets;

    event RandomNumberRequested(uint256 indexed requestId);
    event RandomNumberFulfilled(uint256 indexed requestId, uint256 randomness);

    error InvalidFeedConfig(address feed, uint8 decimals);
    error InvalidFeedAnswer(
        int256 price,
        uint256 latestRoundId,
        uint256 updatedAt
    );

    constructor(
        address vrfCoordinator_,
        address linkToken_,
        uint256 linkPremium_,
        bytes32 gasLaneKeyHash_,
        uint256 gasLaneMaxWei_,
        uint32 callbackGasLimit_,
        uint64 subId_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        vrfCoordinator = vrfCoordinator_;
        linkToken = linkToken_;
        juels = 10**LinkTokenInterface(linkToken_).decimals();
        linkPremium = linkPremium_;
        gasLaneKeyHash = gasLaneKeyHash_;
        gasLaneMaxWei = gasLaneMaxWei_;
        callbackGasLimit = callbackGasLimit_;
        // NB: This contract must be added as a consumer to this subscription
        subId = subId_;
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "ChainlinkVRFV2Randomiser 1.0.0";
    }

    /// @notice Request a random number
    /// @param callbackContract Target contract to callback with random numbers
    /// @param minConfirmations Number of block confirmations to wait.
    function getRandomNumber(address callbackContract, uint16 minConfirmations)
        public
        onlyAuthorised
        returns (uint256 requestId)
    {
        requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                gasLaneKeyHash,
                subId,
                minConfirmations,
                callbackGasLimit,
                1
            );
        callbackTargets[requestId] = callbackContract;
        emit RandomNumberRequested(requestId);
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness)
        internal
        override
    {
        address target = callbackTargets[requestId];
        delete callbackTargets[requestId];
        IRandomiserCallback(target).receiveRandomWords(requestId, randomness);
        emit RandomNumberFulfilled(requestId, randomness[0]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {Authorised} from "../vendor/Authorised.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LinklessVRF
/// @author kevincharm
/// @notice Make VRF requests using ETH instead of LINK.
/// @dev Contract charges a 150 bps cut of the total request cost. Send the
///     right amount of ETH because the contract does not refund any excess.
/// @dev The gaslane is hardcoded.
contract LinklessVRF is TypeAndVersion, Authorised, VRFConsumerBaseV2 {
    /// --- VRF SHIT ---
    /// @notice Max gas used to verify VRF proofs; always 200k according to:
    ///     https://docs.chain.link/vrf/v2/subscription#minimum-subscription-balance
    uint256 public constant MAX_VERIFICATION_GAS = 200_000;
    /// @notice Extra gas overhead for fulfilling randomness
    uint256 public constant FULFILMENT_OVERHEAD_GAS = 30_000;
    /// @notice VRF Coordinator (V2)
    /// @dev https://docs.chain.link/vrf/v2/subscription/supported-networks
    address public immutable vrfCoordinator;
    /// @notice LINK token (make sure it's the ERC-677 one)
    /// @dev PegSwap: https://pegswap.chain.link
    address public immutable linkToken;
    /// @notice LINK token unit
    uint256 public immutable juels;
    /// @dev VRF Coordinator LINK premium per request
    uint256 public immutable linkPremium;
    /// @notice Each gas lane has a different key hash; each gas lane
    ///     determines max gwei that will be used for the callback
    bytes32 public immutable gasLaneKeyHash;
    /// @notice Max gas price for gas lane used in gasLaneKeyHash
    /// @dev This is used purely for gas estimation
    uint256 public immutable gasLaneMaxWei;
    /// @notice VRF subscription ID; created during deployment
    uint64 public subId;

    /// --- PRICE FEED SHIT ---
    /// @notice Period until a feed is considered stale
    /// @dev Check heartbeat parameters on data.chain.link
    uint256 public constant MAX_AGE = 60 minutes;
    /// @notice Internal prices shall be scaled according to this constant
    uint256 public constant EXP_SCALE = 10**8;
    /// @notice LINK/USD chainlink price feed
    address public immutable feedLINKUSD;
    /// @notice ETH/USD chainlink price feed
    address public immutable feedETHUSD;

    /// --- UNISWAMP ---
    /// @notice WETH address used in UniV3 pool
    address public immutable weth;
    /// @notice UniV3 swap router (NB: SwapRouter v1!)
    address public immutable swapRouter;
    /// @notice UniV3 LINK/ETH pool fee
    uint24 public immutable uniV3PoolFee;

    /// --- THE PROTOCOL ---
    /// @notice Protocol fee per request
    uint256 public immutable protocolFeeBps;
    /// @notice High watermark at which a rebalance of LINK->ETH becomes
    ///     possible. (Intended to be upkept by a Keeper)
    uint256 public subLINKBalanceHighWatermark;
    /// @notice requestId => contract to callback
    /// @dev contract must implement IRandomiserCallback
    mapping(uint256 => address) public callbackTargets;

    event RandomnessRequested(
        uint256 indexed requestId,
        uint256 vrfRequestCost,
        uint256 protocolFeePaid
    );
    event RandomnessFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event Rebalanced(
        uint64 oldSubId,
        uint64 newSubId,
        uint256 dumpedLINK,
        uint256 receivedETH
    );
    event SubscriptionRenewed(uint64 oldSubId, uint64 newSubId);
    event Withdrawn(address token, address recipient, uint256 amount);

    error InvalidFeedConfig(address feed, uint8 decimals);
    error InvalidFeedAnswer(
        int256 price,
        uint256 latestRoundId,
        uint256 updatedAt
    );
    error InsufficientFeePayment(
        uint32 callbackGasLimit,
        uint256 amountOffered,
        uint256 amountRequired
    );
    error RebalanceNotAvailable(uint256 currentBalance, uint256 highWatermark);
    error TransferFailed();

    struct RandomiserInitOpts {
        address vrfCoordinator;
        address linkToken;
        uint256 linkPremium;
        bytes32 gasLaneKeyHash;
        uint256 gasLaneMaxWei;
        address feedLINKUSD;
        address feedETHUSD;
        address weth;
        address swapRouter;
        uint24 uniV3PoolFee;
        uint256 protocolFeeBps;
        uint256 subLINKBalanceHighWatermark;
    }

    constructor(RandomiserInitOpts memory opts)
        VRFConsumerBaseV2(opts.vrfCoordinator)
    {
        vrfCoordinator = opts.vrfCoordinator;
        linkToken = opts.linkToken;
        juels = 10**LinkTokenInterface(opts.linkToken).decimals();
        linkPremium = opts.linkPremium;
        gasLaneKeyHash = opts.gasLaneKeyHash;
        gasLaneMaxWei = opts.gasLaneMaxWei;

        feedLINKUSD = opts.feedLINKUSD;
        feedETHUSD = opts.feedETHUSD;
        weth = opts.weth;
        swapRouter = opts.swapRouter;
        uniV3PoolFee = opts.uniV3PoolFee;
        protocolFeeBps = opts.protocolFeeBps;
        subLINKBalanceHighWatermark = opts.subLINKBalanceHighWatermark;

        // Create new subscription on the coordinator & add self as consumer
        subId = VRFCoordinatorV2Interface(opts.vrfCoordinator)
            .createSubscription();
        VRFCoordinatorV2Interface(opts.vrfCoordinator).addConsumer(
            subId,
            address(this)
        );
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "LinklessVRF 1.0.0";
    }

    receive() external payable {
        // Do nothing. This contract will be receiving ETH from unwrapping WETH.
    }

    /// @notice Get latest feed price, checking correct configuration and that
    ///     the price is fresh.
    /// @param feed_ Address of AggregatorV2V3Interface price feed
    function getLatestFeedPrice(address feed_)
        internal
        view
        returns (uint256 price, uint8 decimals)
    {
        AggregatorV2V3Interface feed = AggregatorV2V3Interface(feed_);
        decimals = feed.decimals();
        if (decimals == 0) {
            revert InvalidFeedConfig(feedLINKUSD, decimals);
        }
        (uint80 roundId, int256 answer, , uint256 updatedAt, ) = feed
            .latestRoundData();
        if (answer <= 0 || ((block.timestamp - updatedAt) > MAX_AGE)) {
            revert InvalidFeedAnswer(answer, roundId, updatedAt);
        }
        return (uint256(answer), decimals);
    }

    /// @notice Get LINK/USD
    function getLINKUSD()
        internal
        view
        returns (uint256 price, uint8 decimals)
    {
        return getLatestFeedPrice(feedLINKUSD);
    }

    /// @notice get ETH/USD
    function getETHUSD() internal view returns (uint256 price, uint8 decimals) {
        return getLatestFeedPrice(feedETHUSD);
    }

    /// @notice Compute ETH/LINK price
    /// @return ETHLINK price upscaled to EXP_SCALE
    function getETHLINK() internal view returns (uint256) {
        (uint256 priceETHUSD, uint8 decETHUSD) = getETHUSD();
        (uint256 priceLINKUSD, uint8 decLINKUSD) = getLINKUSD();

        // Assumptions: price > 0, decimals > 0
        return
            (EXP_SCALE * priceETHUSD * (10**decLINKUSD)) /
            (priceLINKUSD * (10**decETHUSD));
    }

    /// @notice Compute LINK/ETH price
    /// @return LINKETH price upscaled to EXP_SCALE
    function getLINKETH() internal view returns (uint256) {
        (uint256 priceETHUSD, uint8 decETHUSD) = getETHUSD();
        (uint256 priceLINKUSD, uint8 decLINKUSD) = getLINKUSD();

        // Assumptions: price > 0, decimals > 0
        return
            (EXP_SCALE * priceLINKUSD * (10**decETHUSD)) /
            (priceETHUSD * (10**decLINKUSD));
    }

    /// @notice Estimate request gas cost by computing the maximum amount of
    ///     gas that may be consumed according to the max gwei for the
    ///     configured gas lane.
    /// @dev See:
    ///     https://docs.chain.link/vrf/v2/subscription#minimum-subscription-balance
    /// @return Maximum gas that could be consumed in this request, in wei
    function maxRequestGasCost(uint32 callbackGasLimit)
        internal
        view
        returns (uint256)
    {
        return
            gasLaneMaxWei *
            (MAX_VERIFICATION_GAS + FULFILMENT_OVERHEAD_GAS + callbackGasLimit);
    }

    /// @notice Estimate how much ETH is necessary to fulfill a request
    /// @param callbackGasLimit Gas limit for callback
    /// @return Amount of wei required for VRF request
    function estimateRequestCostETH(uint32 callbackGasLimit)
        internal
        view
        returns (uint256)
    {
        uint256 linkPremiumETH = (linkPremium * getLINKETH()) / EXP_SCALE;
        uint256 requestGasCostETH = maxRequestGasCost(callbackGasLimit);
        return requestGasCostETH + linkPremiumETH;
    }

    /// @notice Total request cost including protocol fee, in ETH (wei)
    /// @param callbackGasLimit Gas limit to use for the callback function
    /// @return totalRequestCostETH Amount of wei required to request a random
    ///     number from this protocol.
    /// @return requestGasCostETH Amount of estimated wei required to complete
    ///     the VRF call.
    function _computeTotalRequestCostETH(uint32 callbackGasLimit)
        internal
        view
        returns (uint256 totalRequestCostETH, uint256 requestGasCostETH)
    {
        requestGasCostETH = estimateRequestCostETH(callbackGasLimit);
        uint256 protocolFee = (requestGasCostETH * protocolFeeBps) / 10000;
        totalRequestCostETH = requestGasCostETH + protocolFee;
    }

    /// @notice Total request cost including protocol fee, in ETH (wei)
    /// @param callbackGasLimit Gas limit to use for the callback function
    /// @return Amount of wei required to request a random number from this
    ///     protocol.
    function computeTotalRequestCostETH(uint32 callbackGasLimit)
        public
        view
        returns (uint256)
    {
        (uint256 requestGasCostETH, ) = _computeTotalRequestCostETH(
            callbackGasLimit
        );
        return requestGasCostETH;
    }

    /// @notice Swap LINK to ETH via Uniswap V3, using a Chainlink feed to
    ///     calculate the rate, and asserts a maximum amount of slippage.
    /// @param linkAmount Amount of ETH to swap
    /// @return Amount of ETH received
    function swapLINKToETH(uint256 linkAmount, uint16 maxSlippageBps)
        internal
        returns (uint256)
    {
        // Get rate for ETH->LINK using feed
        uint256 amountETHAtRate = (linkAmount * EXP_SCALE) / getETHLINK();
        uint256 maxSlippageDelta = (amountETHAtRate * maxSlippageBps) / 10000;
        // Minimum ETH output taking into account max allowable slippage
        uint256 amountOutMinimum = amountETHAtRate - maxSlippageDelta;

        // Approve LINK to SwapRouter
        LinkTokenInterface(linkToken).approve(swapRouter, linkAmount);

        // Swap ETH->LINK
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: linkToken,
                tokenOut: weth,
                fee: uniV3PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: linkAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(params);

        // Unwrap WETH->ETH
        IWETH9(weth).withdraw(amountOut);

        return amountOut;
    }

    /// @notice Swap ETH to LINK via Uniswap V3, using a Chainlink feed to
    ///     calculate the rate, and asserts a maximum amount of slippage.
    /// @param ethAmount Amount of ETH to swap
    /// @return Amount of LINK received
    function swapETHToLINK(uint256 ethAmount, uint16 maxSlippageBps)
        internal
        returns (uint256)
    {
        // Get rate for ETH->LINK using feed
        uint256 amountLINKAtRate = (ethAmount * EXP_SCALE) / getLINKETH();
        uint256 maxSlippageDelta = (amountLINKAtRate * maxSlippageBps) / 10000;
        // Minimum LINK output taking into account max allowable slippage
        uint256 amountOutMinimum = amountLINKAtRate - maxSlippageDelta;

        // Wrap ETH->WETH & approve amount for UniV3 swap router
        IWETH9(weth).deposit{value: ethAmount}();
        IWETH9(weth).approve(swapRouter, ethAmount);

        // Swap ETH->LINK
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: weth,
                tokenOut: linkToken,
                fee: uniV3PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        return ISwapRouter(swapRouter).exactInputSingle(params);
    }

    /// @notice Request a random number
    /// @param callbackContract Target contract to callback
    /// @param callbackGasLimit Maximum amount of gas that can be consumed by
    ///     the callback function
    /// @param minConfirmations Number of block confirmations to wait before
    ///     the VRF request can be fulfilled
    /// @return requestId Request ID from VRF Coordinator
    function getRandomNumber(
        address callbackContract,
        uint32 callbackGasLimit,
        uint16 minConfirmations,
        uint32 numWords
    ) public payable returns (uint256 requestId) {
        (
            uint256 totalRequestCostETH,
            uint256 requestGasCostETH
        ) = _computeTotalRequestCostETH(callbackGasLimit);
        if (msg.value < totalRequestCostETH) {
            revert InsufficientFeePayment(
                callbackGasLimit,
                msg.value,
                totalRequestCostETH
            );
        }
        // Swap ETH to LINK
        uint256 amountLINKReceived = swapETHToLINK(
            requestGasCostETH,
            60 /** NB: Hardcoded -0.6% max slippage */
        );
        // Fund subscription with swapped LINK
        uint64 subId_ = subId;
        LinkTokenInterface(linkToken).transferAndCall(
            vrfCoordinator,
            amountLINKReceived,
            abi.encode(subId_)
        );
        // Finally, make the VRF request
        requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                gasLaneKeyHash,
                subId_,
                minConfirmations,
                callbackGasLimit,
                numWords
            );
        callbackTargets[requestId] = callbackContract;
        emit RandomnessRequested(
            requestId,
            requestGasCostETH,
            totalRequestCostETH - requestGasCostETH
        );
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address target = callbackTargets[requestId];
        delete callbackTargets[requestId];

        IRandomiserCallback(target).receiveRandomWords(requestId, randomWords);
        emit RandomnessFulfilled(requestId, randomWords);
    }

    /// @notice Set new high watermark at which a rebalance operation becomes
    ///     possible.
    /// @param newHighWatermark New high watermark
    function setRebalanceHighWatermark(uint256 newHighWatermark)
        public
        onlyAuthorised
    {
        subLINKBalanceHighWatermark = newHighWatermark;
    }

    /// @notice Perform upkeep by cancelling the subscription iff sub balance
    ///     is above the high watermark. By cancelling the sub, LINK is
    ///     returned to this contract. This contract will then buy ETH with
    ///     excess LINK. A new subscription is then created to replace the
    ///     existing subscription.
    /// @dev Keeper-executed function
    function rebalance() public {
        uint64 oldSubId = subId;
        VRFCoordinatorV2Interface coord = VRFCoordinatorV2Interface(
            vrfCoordinator
        );
        uint256 subLINKBalanceHighWatermark_ = subLINKBalanceHighWatermark;
        (uint96 balance, , , ) = coord.getSubscription(oldSubId);
        if (balance < subLINKBalanceHighWatermark_) {
            revert RebalanceNotAvailable(balance, subLINKBalanceHighWatermark_);
        }

        // Cancel subscription and receive LINK refund to this contract
        coord.cancelSubscription(oldSubId, address(this));
        // Create new subscription
        uint64 newSubId = coord.createSubscription();
        coord.addConsumer(newSubId, address(this));
        subId = newSubId;
        emit SubscriptionRenewed(oldSubId, newSubId);

        // Dump LINK
        uint256 ownLINKBalance = LinkTokenInterface(linkToken).balanceOf(
            address(this)
        );
        uint256 receivedETH = swapLINKToETH(
            ownLINKBalance,
            50 /** NB: Hardcoded -0.5% max slippage */
        );
        emit Rebalanced(oldSubId, newSubId, ownLINKBalance, receivedETH);
    }

    /// @notice Cancel a subscription to receive a refund; then create a new
    ///     one and add self as consumer.
    /// @dev This is here in case we need to manually withdraw LINK to TWAP;
    ///     which may be necessary if a `rebalance()` would move the Uniswap
    ///     pool price so much that it becomes impossible to execute with the
    ///     hardcoded max slippage.
    function renewSubscription()
        external
        onlyAuthorised
        returns (uint64 oldSubId, uint64 newSubId)
    {
        VRFCoordinatorV2Interface coord = VRFCoordinatorV2Interface(
            vrfCoordinator
        );
        oldSubId = subId;
        coord.cancelSubscription(oldSubId, address(this));
        newSubId = coord.createSubscription();
        coord.addConsumer(newSubId, address(this));
        subId = newSubId;
        emit SubscriptionRenewed(oldSubId, newSubId);
    }

    /// @notice Fund the subscription managed by this contract. This is not
    ///     actually *needed* since we should be able to arbitrarily fund any
    ///     subscription, but is here for convenience. The required LINK amount
    ///     must be already in this contract's balance.
    /// @param amount Amount of LINK to fund the subscription with. This amount
    ///     of LINK must already be in the contract balance.
    function fundSubscription(uint256 amount) external {
        LinkTokenInterface(linkToken).transferAndCall(
            vrfCoordinator,
            amount,
            abi.encode(subId)
        );
    }

    /// @notice Withdraw ERC-20 tokens
    /// @param token Address of ERC-20
    /// @param amount Amount to withdraw, withdraws entire balance if 0
    function withdrawERC20(address token, uint256 amount)
        external
        onlyAuthorised
    {
        if (amount == 0) {
            amount = IERC20(token).balanceOf(address(this));
        }
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawn(token, msg.sender, amount);
    }

    /// @notice Withdraw ETH
    /// @param amount Amount to withdraw, withdraws entire balance if 0
    function withdrawETH(uint256 amount) external onlyAuthorised {
        if (amount == 0) {
            amount = address(this).balance;
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        emit Withdrawn(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            msg.sender,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

/// @title Authorised
/// @notice Restrict functions to whitelisted admins with the `onlyAdmin`
///     modifier. Deployer of contract is automatically added as an admin.
contract Authorised {
    /// @notice Whitelisted admins
    mapping(address => bool) public isAuthorised;

    error NotAuthorised(address culprit);

    constructor() {
        isAuthorised[msg.sender] = true;
    }

    /// @notice Restrict function to whitelisted admins only
    modifier onlyAuthorised() {
        if (!isAuthorised[msg.sender]) {
            revert NotAuthorised(msg.sender);
        }
        _;
    }

    /// @notice Set authorisation of a specific account
    /// @param toggle `true` to authorise account as an admin
    function authorise(address guy, bool toggle) public onlyAuthorised {
        isAuthorised[guy] = toggle;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8 <0.9;

/// @title Sets
/// @author kevincharm
/// @notice Implementation of sets via circular linked list.
///     * Don't use address(0x1) as it is used as a special "head" pointer
///     * Use like this:
///         using Sets for Sets.Set;
///         Sets.Set internal animals;
///         ...
///         animals.init();
///         animals.add(0xd8da6bf26964af9d7eed9e03e53415d37aa96045);
library Sets {
    struct Set {
        mapping(address => address) ll;
        uint256 size;
    }

    address public constant OUROBOROS = address(0x1);

    error SetAlreadyInitialised();
    error SetNotInitialised();
    error ElementInvalid(address element);
    error ElementExists(address element);
    error ConsecutiveElementsRequired(address prevElement, address element);
    error ElementDoesNotExist(address element);
    error EmptySet();

    function _isInitialised(Set storage set) private view returns (bool) {
        return set.ll[OUROBOROS] != address(0);
    }

    function init(Set storage set) internal {
        if (_isInitialised(set)) {
            revert SetAlreadyInitialised();
        }

        set.ll[OUROBOROS] = OUROBOROS;
    }

    function tail(Set storage set) internal view returns (address) {
        address t = set.ll[OUROBOROS];
        if (t == address(0)) revert SetNotInitialised();
        if (t == OUROBOROS) revert EmptySet();
        return t;
    }

    function prev(
        Set storage set,
        address element
    ) internal view returns (address) {
        if (element == address(0)) revert ElementInvalid(element);
        return set.ll[element];
    }

    function add(Set storage set, address element) internal {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        if (element == address(0) || element == OUROBOROS) {
            revert ElementInvalid(element);
        }
        if (set.ll[element] != address(0)) {
            revert ElementExists(element);
        }
        set.ll[element] = set.ll[OUROBOROS];
        set.ll[OUROBOROS] = element;
        ++set.size;
    }

    function del(
        Set storage set,
        address prevElement,
        address element
    ) internal {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        if (element != set.ll[prevElement]) {
            revert ConsecutiveElementsRequired(prevElement, element);
        }
        if (element == address(0) || element == OUROBOROS) {
            revert ElementInvalid(element);
        }

        set.ll[prevElement] = set.ll[element];
        set.ll[element] = address(0);
        --set.size;
    }

    function has(
        Set storage set,
        address element
    ) internal view returns (bool) {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        return set.ll[element] != address(0);
    }

    function toArray(Set storage set) internal view returns (address[] memory) {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }

        if (set.size == 0) {
            return new address[](0);
        }

        address[] memory array = new address[](set.size);
        address element = set.ll[OUROBOROS];
        for (uint256 i; i < array.length; ++i) {
            array[i] = element;
            element = set.ll[element];
        }
        return array;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Withdrawable
/// @author kevincharm
abstract contract Withdrawable {
    event ETHWithdrawn(address to, uint256 amount);
    event ERC20Withdrawn(address to, address token, uint256 amount);
    event ERC721Withdrawn(address to, address token, uint256 tokenId);
    event ERC1155Withdrawn(
        address to,
        address token,
        uint256 tokenId,
        uint256 amount
    );

    function _authoriseWithdrawal() internal virtual;

    function withdrawETH(address to, uint256 amount) external {
        _authoriseWithdrawal();
        payable(to).transfer(amount);
        emit ETHWithdrawn(to, amount);
    }

    function withdrawERC20(address token, address to, uint256 amount) external {
        _authoriseWithdrawal();
        IERC20(token).transfer(to, amount);
        emit ERC20Withdrawn(to, token, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external {
        _authoriseWithdrawal();
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
        emit ERC721Withdrawn(to, token, tokenId);
    }

    function withdrawERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _authoriseWithdrawal();
        IERC1155(token).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            bytes("")
        );
        emit ERC1155Withdrawn(to, token, tokenId, amount);
    }
}