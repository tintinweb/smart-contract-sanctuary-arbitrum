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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title DropFactory.sol - Core contract for metadrop NFT drop creation.
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice This contract performs the following roles:
 * - Storage of drop data that has been submitted to metadrop for approval.
 *   This information is held in hash format, and compared with sent data
 *   to create the drop.
 * - Drop creation. This factory will create the required NFT contracts for
 *   an approved drop using the approved confirmation.
 * - Platform Utilities. This contract holds core platform data accessed by other
 *   on-chain elements of the metadrop ecosystem. For example, VRF functionality.
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../NFT/INFTByMetadrop.sol";
import "../PrimaryVesting/IPrimaryVestingByMetadrop.sol";
import "../PrimarySaleModules/IPrimarySaleModule.sol";
import "../RoyaltyPaymentSplitter/IRoyaltyPaymentSplitterByMetadrop.sol";
import "./IDropFactory.sol";
import "../Global/AuthorityModel.sol";

/**
 *
 * @dev Inheritance details:
 *      IDropFactory            Interface definition for the metadrop drop factory
 *      Ownable                 OZ ownable implementation - provided for backwards compatibility
 *                              with any infra that assumes a project owner.
 *      AccessControl           OZ access control implementation - used for authority control
 *      VRFConsumerBaseV2       This contract will call chainlink VRF on behalf of deployed NFT
 *                              contracts, relaying the returned result to the NFT contract
 *
 */

contract DropFactory is
  IDropFactory,
  Ownable,
  AuthorityModel,
  VRFConsumerBaseV2
{
  using Address for address;
  using Clones for address payable;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint32 public constant MAX_NUM_WORDS = 500;

  // The number of days that must have passed before the details for a drop held on chain can be deleted.
  uint32 public dropExpiryInDays;

  // Pause should not be allowed indefinitely
  uint8 public pauseCutOffInDays;

  // Address for all platform fee payments
  address private platformTreasury;

  // Metadrop trusted oracle address
  address public metadropOracleAddress;

  // Primary sale metadrop basis Points
  uint256 private defaultMetadropPrimaryShareBasisPoints;

  // Royalty metadrop percentage
  uint256 private defaultMetadropRoyaltyBasisPoints;

  // Fee for drop submission (default is zero)
  uint256 public dropFeeETH;

  // The oracle signed message validity period:
  uint80 public messageValidityInSeconds = 600;

  // Chainlink config
  VRFCoordinatorV2Interface public immutable vrfCoordinatorInterface;
  uint64 public vrfSubscriptionId;
  bytes32 public vrfKeyHash;
  uint32 public vrfCallbackGasLimit;
  uint16 public vrfRequestConfirmations;
  uint32 public vrfNumWords;

  // Array of templates:
  // Note that this means that templates can be updated as the metadrop NFT evolves.
  // Using a new one will mean that all drops from that point forward will use the new contract template.
  // All deployed NFT contracts are NOT upgradeable and will continue to use the contract as deployed
  // At the time of drop.

  Template[] public contractTemplates;

  // Map the dropId to the Drop object
  //   struct DropApproval {
  //   DropStatus status;
  //   uint32 lastChangedDate;
  //   address dropOwnerAddress;
  //   bytes32 configHash;
  // }
  mapping(string => DropApproval) private dropDetailsByDropId;

  // Map to store any primary fee overrides on a drop by drop basis
  //   struct NumericOverride {
  //   bool isSet;
  //   uint248 overrideValue;
  // }
  mapping(string => NumericOverride) private primaryFeeOverrideByDrop;

  // Map to store any vesting period overrides on a drop by drop basis
  //   struct NumericOverride {
  //   bool isSet;
  //   uint248 overrideValue;
  // }

  mapping(string => NumericOverride) private metadropRoyaltyOverrideByDrop;

  // Map to store deployed NFT addresses:
  mapping(address => bool) public deployedNFTContracts;

  // Map to store VRF request IDs:
  mapping(uint256 => address) public addressForVRFRequestId;

  /** ====================================================================================================================
   *                                                    CONSTRUCTOR
   * =====================================================================================================================

  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_                                     The address that can add and remove user authority roles. Will
   *                                                        also be added as the first platform admin.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reviewAdmin_                                    The address for the review admin. Review admins can approve 
   *                                                        drops.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_                               The address of the platform treasury. This will be used on 
   *                                                        primary vesting for the platform share of funds and on the 
   *                                                        royalty payment splitter for the platform share.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropPrimaryShareBasisPoints_         This is the default metadrop share of primary sales proceeds
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropRoyaltyBasisPoints_              The default royalty share in basis points for the platform
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCoordinator_                                 The address of the VRF coordinator
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_             The VRF key hash to determine the gas channel to use for VRF calls (i.e. the max gas 
   *                                you are willing to supply on the VRF call)
   *                                - Mainnet 200 gwei: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
   *                                - Goerli 150 gwei 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_      The subscription ID that chainlink tokens are consumed from for VRF calls
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_  The address of the metadrop oracle signer
   * ---------------------------------------------------------------------------------------------------------------------   
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address superAdmin_,
    address reviewAdmin_,
    address platformTreasury_,
    uint256 defaultMetadropPrimaryShareBasisPoints_,
    uint256 defaultMetadropRoyaltyBasisPoints_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    uint64 vrfSubscriptionId_,
    address metadropOracleAddress_
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    // The initial instance owner is set as the Ownable owner on all cloned contracts:
    if (superAdmin_ == address(0)) {
      revert SuperAdminCannotBeAddressZero();
    }
    superAdmin = superAdmin_;

    // DEFAULT_ADMIN_ROLE can grant and revoke all other roles. This address MUST be secured:
    _grantRole(DEFAULT_ADMIN_ROLE, superAdmin_);

    // PLATFORM_ADMIN is used for elevated access functionality:
    grantPlatformAdmin(superAdmin_);

    // PLATFORM_ADMIN can also review drops:
    grantReviewAdmin(superAdmin_);

    // REVIEW_ADMIN can approve drops but nothing else:
    if (reviewAdmin_ == address(0)) {
      revert ReviewAdminCannotBeAddressZero();
    }
    grantReviewAdmin(reviewAdmin_);

    // Set platform treasury:
    if (platformTreasury_ == address(0)) {
      revert PlatformTreasuryCannotBeAddressZero();
    }
    platformTreasury = platformTreasury_;

    // Set the default platform primary fee percentage:
    defaultMetadropPrimaryShareBasisPoints = defaultMetadropPrimaryShareBasisPoints_;

    // Set the default platform royalty fee percentage:
    defaultMetadropRoyaltyBasisPoints = defaultMetadropRoyaltyBasisPoints_;

    // Set default VRF details
    if (vrfCoordinator_ == address(0)) {
      revert VRFCoordinatorCannotBeAddressZero();
    }
    vrfCoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    vrfSubscriptionId = vrfSubscriptionId_;
    vrfCallbackGasLimit = 150000;
    vrfRequestConfirmations = 3;
    vrfNumWords = 1;

    pauseCutOffInDays = 90;

    if (metadropOracleAddress_ == address(0)) {
      revert MetadropOracleCannotBeAddressZero();
    }
    metadropOracleAddress = metadropOracleAddress_;
  }

  /** ====================================================================================================================
   *                                                      GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_)
  {
    return (platformTreasury);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string memory dropId_
  ) external view returns (DropApproval memory dropDetails_) {
    return (dropDetailsByDropId[dropId_]);
  }

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getDefaultMetadropPrimaryShareBasisPoints   Getter for the default platform primary fee basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return defaultMetadropPrimaryShareBasisPoints_   The metadrop primary share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDefaultMetadropPrimaryShareBasisPoints()
    external
    view
    onlyPlatformAdmin
    returns (uint256 defaultMetadropPrimaryShareBasisPoints_)
  {
    return (defaultMetadropPrimaryShareBasisPoints);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyBasisPoints   Getter for the metadrop royalty share in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyBasisPoints_   The metadrop royalty share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyBasisPoints()
    external
    view
    onlyPlatformAdmin
    returns (uint256 metadropRoyaltyBasisPoints_)
  {
    return (defaultMetadropRoyaltyBasisPoints);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getPrimaryFeeOverrideByDrop    Getter for any drop specific primary fee override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                      The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                      If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryFeeOverrideByDrop_   The primary fee override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPrimaryFeeOverrideByDrop(
    string memory dropId_
  )
    external
    view
    onlyPlatformAdmin
    returns (bool isSet_, uint256 primaryFeeOverrideByDrop_)
  {
    return (
      primaryFeeOverrideByDrop[dropId_].isSet,
      primaryFeeOverrideByDrop[dropId_].overrideValue
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyOverrideByDrop    Getter for any drop specific royalty basis points override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                               The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                               If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyOverrideByDrop_       Royalty basis points override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyOverrideByDrop(
    string memory dropId_
  )
    external
    view
    onlyPlatformAdmin
    returns (bool isSet_, uint256 metadropRoyaltyOverrideByDrop_)
  {
    return (
      metadropRoyaltyOverrideByDrop[dropId_].isSet,
      metadropRoyaltyOverrideByDrop[dropId_].overrideValue
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) getPauseCutOffInDays    Getter for the default pause cutoff period
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPauseCutOffInDays()
    external
    view
    onlyPlatformAdmin
    returns (uint8 pauseCutOffInDays_)
  {
    return (pauseCutOffInDays);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(
    uint64 vrfSubscriptionId_
  ) public onlyPlatformAdmin {
    vrfSubscriptionId = vrfSubscriptionId_;
    emit vrfSubscriptionIdSet(vrfSubscriptionId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyPlatformAdmin {
    vrfKeyHash = vrfKeyHash_;
    emit vrfKeyHashSet(vrfKeyHash_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(
    uint32 vrfCallbackGasLimit_
  ) external onlyPlatformAdmin {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
    emit vrfCallbackGasLimitSet(vrfCallbackGasLimit_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(
    uint16 vrfRequestConfirmations_
  ) external onlyPlatformAdmin {
    if (vrfRequestConfirmations_ > MAX_REQUEST_CONFIRMATIONS) {
      revert ValueExceedsMaximum();
    }
    vrfRequestConfirmations = vrfRequestConfirmations_;
    emit vrfRequestConfirmationsSet(vrfRequestConfirmations_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external onlyPlatformAdmin {
    if (vrfNumWords_ > MAX_NUM_WORDS) {
      revert ValueExceedsMaximum();
    }
    vrfNumWords = vrfNumWords_;
    emit vrfNumWordsSet(vrfNumWords_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(
    address metadropOracleAddress_
  ) external onlyPlatformAdmin {
    if (metadropOracleAddress_ == address(0)) {
      revert MetadropOracleCannotBeAddressZero();
    }
    metadropOracleAddress = metadropOracleAddress_;
    emit metadropOracleAddressSet(metadropOracleAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInSeconds  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInSeconds(
    uint80 messageValidityInSeconds_
  ) external onlyPlatformAdmin {
    messageValidityInSeconds = messageValidityInSeconds_;
    emit messageValidityInSecondsSet(messageValidityInSeconds_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setpauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setpauseCutOffInDays(
    uint8 pauseCutOffInDays_
  ) external onlyPlatformAdmin {
    pauseCutOffInDays = pauseCutOffInDays_;

    emit pauseCutOffInDaysSet(pauseCutOffInDays_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external onlyPlatformAdmin {
    uint256 oldDropFee = dropFeeETH;
    dropFeeETH = fee_;
    emit SubmissionFeeETHUpdated(oldDropFee, fee_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the default
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(
    address platformTreasury_
  ) external onlyPlatformAdmin {
    if (platformTreasury_ == address(0)) {
      revert PlatformTreasuryCannotBeAddressZero();
    }
    platformTreasury = platformTreasury_;

    emit PlatformTreasurySet(platformTreasury_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDefaultMetadropPrimaryShareBasisPoints    Setter for the metadrop primary basis points fee
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropPrimaryShareBasisPoints_    New default meradrop primary share
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultMetadropPrimaryShareBasisPoints(
    uint32 defaultMetadropPrimaryShareBasisPoints_
  ) external onlyPlatformAdmin {
    defaultMetadropPrimaryShareBasisPoints = defaultMetadropPrimaryShareBasisPoints_;

    emit DefaultMetadropPrimaryShareBasisPointsSet(
      defaultMetadropPrimaryShareBasisPoints_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyBasisPoints   Setter for the metadrop royalty percentate in
   *                                                basis points i.e. 100 = 1%
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropRoyaltyBasisPoints_      New default royalty basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyBasisPoints(
    uint32 defaultMetadropRoyaltyBasisPoints_
  ) external onlyPlatformAdmin {
    defaultMetadropRoyaltyBasisPoints = defaultMetadropRoyaltyBasisPoints_;

    emit DefaultMetadropRoyaltyBasisPointsSet(
      defaultMetadropRoyaltyBasisPoints_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyOverrideByDrop   Setter to override royalty basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                  The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyBasisPoints_      Royalty basis points verride
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyOverrideByDrop(
    string memory dropId_,
    uint256 royaltyBasisPoints_
  ) external onlyPlatformAdmin {
    metadropRoyaltyOverrideByDrop[dropId_].isSet = true;
    metadropRoyaltyOverrideByDrop[dropId_].overrideValue = uint248(
      royaltyBasisPoints_
    );

    emit RoyaltyBasisPointsOverrideByDropSet(dropId_, royaltyBasisPoints_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPrimaryFeeOverrideByDrop   Setter for the metadrop primary percentage fee, in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_           The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param basisPoints_      The basis points override
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPrimaryFeeOverrideByDrop(
    string memory dropId_,
    uint256 basisPoints_
  ) external onlyPlatformAdmin {
    primaryFeeOverrideByDrop[dropId_].isSet = true;
    primaryFeeOverrideByDrop[dropId_].overrideValue = uint248(basisPoints_);

    emit PrimaryFeeOverrideByDropSet(dropId_, basisPoints_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(
    uint32 dropExpiryInDays_
  ) external onlyPlatformAdmin {
    dropExpiryInDays = dropExpiryInDays_;

    emit DropExpiryInDaysSet(dropExpiryInDays_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external onlyPlatformAdmin {
    (bool success, ) = platformTreasury.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(
    IERC20 token_,
    uint256 amount_
  ) external onlyPlatformAdmin {
    token_.safeTransfer(platformTreasury, amount_);
  }

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external {
    // Can only be called by a deployed collection:
    if (deployedNFTContracts[msg.sender] = true) {
      addressForVRFRequestId[
        vrfCoordinatorInterface.requestRandomWords(
          vrfKeyHash,
          vrfSubscriptionId,
          vrfRequestConfirmations,
          vrfCallbackGasLimit,
          vrfNumWords
        )
      ] = msg.sender;
    } else {
      revert MetadropOnly();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle with randomness. We then forward
   * this to the requesting NFT
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) internal override {
    INFTByMetadrop(addressForVRFRequestId[requestId_]).fulfillRandomWords(
      requestId_,
      randomWords_
    );
  }

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string memory templateDescription_
  ) public onlyPlatformAdmin {
    if (address(contractAddress_) == address(0)) {
      revert TemplateCannotBeAddressZero();
    }

    uint256 nextTemplateNumber = contractTemplates.length;
    contractTemplates.push(
      Template(
        TemplateStatus.live,
        uint16(nextTemplateNumber),
        uint32(block.timestamp),
        contractAddress_,
        templateDescription_
      )
    );

    emit TemplateAdded(
      TemplateStatus.live,
      nextTemplateNumber,
      block.timestamp,
      contractAddress_,
      templateDescription_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(
    uint16 templateNumber_
  ) external onlyPlatformAdmin {
    contractTemplates[templateNumber_].status = TemplateStatus.terminated;

    emit TemplateTerminated(templateNumber_);
  }

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(
    string memory dropId_
  ) external onlyReviewAdmin {
    // Drop ID must exist:
    require(
      dropDetailsByDropId[dropId_].lastChangedDate != 0,
      "Drop Review: drop ID does not exist"
    );

    // Last changed date must be the expiry period in the past (or greater)
    require(
      dropDetailsByDropId[dropId_].lastChangedDate <
        (block.timestamp - (dropExpiryInDays * 1 days)),
      "Drop Review: drop ID does not exist"
    );

    delete dropDetailsByDropId[dropId_];

    emit DropDetailsDeleted(dropId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string memory dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external onlyReviewAdmin {
    if (projectOwner_ == address(0)) {
      revert ProjectOwnerCannotBeAddressZero();
    }
    dropDetailsByDropId[dropId_] = DropApproval(
      DropStatus.approved,
      uint32(block.timestamp),
      projectOwner_,
      dropConfigHash_
    );

    emit DropApproved(dropId_, projectOwner_, dropConfigHash_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[3] memory collectionURIs_
  ) external payable {
    // Check the fee:
    require(msg.value == dropFeeETH, "Incorrect ETH payment");

    // Get the details from storage:
    DropApproval memory currentDrop = dropDetailsByDropId[dropId_];

    // We can only proceed if this drop is set to 'approved'
    require(
      currentDrop.status == DropStatus.approved,
      "Drop creation: must be approved"
    );

    // We can only proceed if this is being called by the project owner:
    require(
      currentDrop.dropOwnerAddress == msg.sender,
      "Drop creation: must be submitted by project owner"
    );

    dropDetailsByDropId[dropId_].status = DropStatus.deployed;

    // We can only proceed if the hash of the passed configuration matches that stored
    // on chain from the project approval
    require(
      configHashMatches(
        dropId_,
        vestingModule_,
        nftModule_,
        primarySaleModulesConfig_,
        royaltyPaymentSplitterModule_,
        salesPageHash_,
        customNftAddress_
      ),
      "Drop creation: passed config does not match approved"
    );

    // ---------------------------------------------
    //
    // VESTING
    //
    // ---------------------------------------------

    // Create the vesting contract clone instance:
    address newVestingInstance = _createVestingContract(
      vestingModule_,
      dropId_
    );

    // ---------------------------------------------
    //
    // ROYALTY
    //
    // ---------------------------------------------

    // Create the royalty payment splitter contract clone instance:
    (
      address newRoyaltyPaymentSplitterInstance,
      uint96 royaltyFromSalesInBasisPoints
    ) = _createRoyaltyPaymentSplitterContract(
        royaltyPaymentSplitterModule_,
        dropId_
      );

    // ---------------------------------------------
    //
    // PRIMARY SALE MODULES
    //
    // ---------------------------------------------
    //

    // Array to hold addresses of created primary sale modules:
    PrimarySaleModuleInstance[]
      memory primarySaleModuleInstances = new PrimarySaleModuleInstance[](
        primarySaleModulesConfig_.length
      );

    // Iterate over the received primary sale modules, instansiate and initialise:
    for (uint256 i = 0; i < primarySaleModulesConfig_.length; i++) {
      primarySaleModuleInstances[i].instanceAddress = payable(
        contractTemplates[primarySaleModulesConfig_[i].templateId]
          .templateAddress
      ).clone();

      primarySaleModuleInstances[i].instanceDescription = contractTemplates[
        primarySaleModulesConfig_[i].templateId
      ].templateDescription;

      // Initialise storage data:
      _initialisePrimarySaleModule(
        primarySaleModuleInstances[i].instanceAddress,
        msg.sender,
        newVestingInstance,
        primarySaleModulesConfig_[i].configData
      );
    }

    // ---------------------------------------------
    //
    // NFT
    //
    // ---------------------------------------------
    //

    // Create the NFT clone instance:
    address newNFTInstance = _createNFTContract(
      msg.sender,
      primarySaleModuleInstances,
      nftModule_,
      newRoyaltyPaymentSplitterInstance,
      royaltyFromSalesInBasisPoints,
      customNftAddress_,
      collectionURIs_
    );

    // Iterate over the primary sale modules, and add the NFT address
    for (uint256 i = 0; i < primarySaleModuleInstances.length; i++) {
      IPrimarySaleModule(primarySaleModuleInstances[i].instanceAddress)
        .setNFTAddress(newNFTInstance);
    }

    emit DropDeployed(
      dropId_,
      newNFTInstance,
      newVestingInstance,
      primarySaleModuleInstances,
      newRoyaltyPaymentSplitterInstance
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _initialisePrimarySaleModule  Load initial values to a sale module
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param instanceAddress_           The module to be initialised
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropCreator_           The project owner calling createDrop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newVestingInstance_           The vesting contract for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_           The configuration data for this module
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialisePrimarySaleModule(
    address instanceAddress_,
    address dropCreator_,
    address newVestingInstance_,
    bytes memory configData_
  ) internal {
    IPrimarySaleModule(instanceAddress_).initialisePrimarySaleModule(
      superAdmin,
      getPlatformAdmins(),
      dropCreator_, // project owner
      newVestingInstance_,
      configData_,
      pauseCutOffInDays,
      metadropOracleAddress,
      messageValidityInSeconds
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _platformPrimaryShare  Return the platform primary share for this drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _platformPrimaryShare(
    string memory dropId_
  ) internal view returns (uint256 platformPrimaryShare_) {
    // See if there is any primary share override for this drop:
    if (primaryFeeOverrideByDrop[dropId_].isSet) {
      platformPrimaryShare_ = primaryFeeOverrideByDrop[dropId_].overrideValue;
    } else {
      // No override, set to default:
      platformPrimaryShare_ = defaultMetadropPrimaryShareBasisPoints;
    }
    return (platformPrimaryShare_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _projectRoyaltyBasisPoints  Return the metadrop royalty basis points for this drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _projectRoyaltyBasisPoints(
    string memory dropId_
  ) internal view returns (uint256 projectRoyaltyBasisPoints_) {
    // See if there is any project royalty basis points override for this drop:
    if (metadropRoyaltyOverrideByDrop[dropId_].isSet) {
      projectRoyaltyBasisPoints_ = metadropRoyaltyOverrideByDrop[dropId_]
        .overrideValue;
    } else {
      // No override, set to default:
      projectRoyaltyBasisPoints_ = defaultMetadropRoyaltyBasisPoints;
    }
    return (projectRoyaltyBasisPoints_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _createVestingContract  Create the vesting contract for primary funds.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_           The configuration data for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _createVestingContract(
    VestingModuleConfig memory vestingModule_,
    string memory dropId_
  ) internal returns (address) {
    // Template type(uint16).max indicates this module is not required
    if (vestingModule_.templateId == type(uint16).max) {
      return (address(0));
    }

    address payable targetVestingTemplate = contractTemplates[
      vestingModule_.templateId
    ].templateAddress;

    // Create the clone vesting contract:
    address newVestingInstance = targetVestingTemplate.clone();

    IPrimaryVestingByMetadrop(payable(newVestingInstance))
      .initialisePrimaryVesting(
        vestingModule_,
        platformTreasury,
        _platformPrimaryShare(dropId_)
      );

    return newVestingInstance;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _createRoyaltyPaymentSplitterContract  Create the royalty payment splitter.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyModule_           The configuration data for the royalty module
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _createRoyaltyPaymentSplitterContract(
    RoyaltySplitterModuleConfig memory royaltyModule_,
    string memory dropId_
  )
    internal
    returns (
      address newRoyaltySplitterInstance_,
      uint96 totalRoyaltyPercentage_
    )
  {
    // Template type(uint16).max indicates this module is not required
    if (royaltyModule_.templateId == type(uint16).max) {
      return (address(0), 0);
    }

    address payable targetRoyaltySplitterTemplate = contractTemplates[
      royaltyModule_.templateId
    ].templateAddress;

    // Create the clone vesting contract:
    address newRoyaltySplitterInstance = targetRoyaltySplitterTemplate.clone();

    uint96 royaltyFromSalesInBasisPoints = IRoyaltyPaymentSplitterByMetadrop(
      payable(newRoyaltySplitterInstance)
    ).initialiseRoyaltyPaymentSplitter(
        royaltyModule_,
        platformTreasury,
        _projectRoyaltyBasisPoints(dropId_)
      );

    return (newRoyaltySplitterInstance, royaltyFromSalesInBasisPoints);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _createNFTContract  Create the NFT contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_          An array of primary sale module addresses for this NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                   A struct containing configuration information for this NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_      Address of the royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param totalRoyaltyPercentage_      Total royalty percentage for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_              An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * @return nftContract_                The address of the deployed NFT contract clone
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _createNFTContract(
    address caller_,
    PrimarySaleModuleInstance[] memory primarySaleModules_,
    NFTModuleConfig memory nftModule_,
    address royaltyPaymentSplitter_,
    uint96 totalRoyaltyPercentage_,
    address customNftAddress_,
    string[3] memory collectionURIs_
  ) internal returns (address nftContract_) {
    // Template type(uint16).max indicates this module is not required
    if (nftModule_.templateId == type(uint16).max) {
      return (customNftAddress_);
    }

    address payable targetTemplate = contractTemplates[nftModule_.templateId]
      .templateAddress;
    address newNFTInstance = targetTemplate.clone();

    // Initialise storage data:
    INFTByMetadrop(newNFTInstance).initialiseNFT(
      superAdmin,
      getPlatformAdmins(),
      caller_,
      primarySaleModules_,
      nftModule_,
      royaltyPaymentSplitter_,
      totalRoyaltyPercentage_,
      collectionURIs_,
      pauseCutOffInDays
    );

    return newNFTInstance;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) public view returns (bool matches_) {
    // Create the hash of the passed data for comparison:
    bytes32 passedConfigHash = createConfigHash(
      dropId_,
      vestingModule_,
      nftModule_,
      primarySaleModulesConfig_,
      royaltyPaymentSplitterModule_,
      salesPageHash_,
      customNftAddress_
    );
    // Must equal the stored hash:
    return (passedConfigHash == dropDetailsByDropId[dropId_].configHash);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) public pure returns (bytes32 configHash_) {
    // Hash the primary sales module data
    for (uint256 i = 0; i < primarySaleModulesConfig_.length; i++) {
      configHash_ = keccak256(
        abi.encodePacked(
          configHash_,
          primarySaleModulesConfig_[i].templateId,
          primarySaleModulesConfig_[i].configData
        )
      );
    }

    configHash_ = keccak256(
      // Hash remaining items:
      abi.encodePacked(
        configHash_,
        dropId_,
        vestingModule_.templateId,
        vestingModule_.configData,
        nftModule_.templateId,
        nftModule_.configData,
        royaltyPaymentSplitterModule_.templateId,
        royaltyPaymentSplitterModule_.configData,
        salesPageHash_,
        customNftAddress_
      )
    );

    return (configHash_);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

pragma solidity 0.8.19;

import "../Global/IConfigStructures.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDropFactory is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event DefaultMetadropPrimaryShareBasisPointsSet(
    uint256 defaultPrimaryFeeBasisPoints
  );
  event DefaultMetadropRoyaltyBasisPointsSet(
    uint256 defaultMetadropRoyaltyBasisPoints
  );
  event PrimaryFeeOverrideByDropSet(string dropId, uint256 percentage);
  event RoyaltyBasisPointsOverrideByDropSet(
    string dropId,
    uint256 royaltyBasisPoints
  );
  event PlatformTreasurySet(address platformTreasury);
  event TemplateAdded(
    TemplateStatus status,
    uint256 templateNumber,
    uint256 loadedDate,
    address templateAddress,
    string templateDescription
  );
  event TemplateTerminated(uint16 templateNumber);
  event DropApproved(
    string indexed dropId,
    address indexed dropOwner,
    bytes32 dropHash
  );
  event DropDetailsDeleted(string indexed dropId);
  event DropExpiryInDaysSet(uint32 expiryInDays);
  event pauseCutOffInDaysSet(uint8 cutOffInDays);
  event SubmissionFeeETHUpdated(uint256 oldFee, uint256 newFee);
  event DropDeployed(
    string dropId,
    address nftInstance,
    address vestingInstance,
    PrimarySaleModuleInstance[],
    address royaltySplitterInstance
  );
  event vrfSubscriptionIdSet(uint64 vrfSubscriptionId_);
  event vrfKeyHashSet(bytes32 vrfKeyHash);
  event vrfCallbackGasLimitSet(uint32 vrfCallbackGasLimit);
  event vrfRequestConfirmationsSet(uint16 vrfRequestConfirmations);
  event vrfNumWordsSet(uint32 vrfNumWords);
  event metadropOracleAddressSet(address metadropOracleAddress);
  event messageValidityInSecondsSet(uint80 messageValidityInSeconds);

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error MetadropOnly();
  error ValueExceedsMaximum();
  error TemplateCannotBeAddressZero();
  error ProjectOwnerCannotBeAddressZero();
  error PlatformTreasuryCannotBeAddressZero();
  error SuperAdminCannotBeAddressZero();
  error MetadropOracleCannotBeAddressZero();
  error VRFCoordinatorCannotBeAddressZero();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string memory dropId_
  ) external view returns (DropApproval memory dropDetails_);

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInSeconds  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInSeconds(
    uint80 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getDefaultMetadropPrimaryShareBasisPoints   Getter for the default platform primary fee basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return defaultMetadropPrimaryShareBasisPoints_   The metadrop primary share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDefaultMetadropPrimaryShareBasisPoints()
    external
    view
    returns (uint256 defaultMetadropPrimaryShareBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyBasisPoints   Getter for the metadrop royalty share in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyBasisPoints_   The metadrop royalty share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyBasisPoints()
    external
    view
    returns (uint256 metadropRoyaltyBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getPrimaryFeeOverrideByDrop    Getter for any drop specific primary fee override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                      The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                      If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryFeeOverrideByDrop_   The primary fee override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPrimaryFeeOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 primaryFeeOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyOverrideByDrop    Getter for any drop specific royalty basis points override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                               The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                               If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyOverrideByDrop_       Royalty basis points override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 metadropRoyaltyOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) getPauseCutOffInDays    Getter for the default pause cutoff period
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPauseCutOffInDays()
    external
    view
    returns (uint8 pauseCutOffInDays_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setpauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setpauseCutOffInDays(uint8 pauseCutOffInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the default
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDefaultMetadropPrimaryShareBasisPoints    Setter for the metadrop primary basis points fee
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropPrimaryShareBasisPoints_    New default meradrop primary share
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultMetadropPrimaryShareBasisPoints(
    uint32 defaultMetadropPrimaryShareBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyBasisPoints   Setter for the metadrop royalty percentate in
   *                                                basis points i.e. 100 = 1%
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropRoyaltyBasisPoints_      New default royalty basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyBasisPoints(
    uint32 defaultMetadropRoyaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPrimaryFeeOverrideByDrop   Setter for the metadrop primary percentage fee, in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_           The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param basisPoints_      The basis points override
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPrimaryFeeOverrideByDrop(
    string memory dropId_,
    uint256 basisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyOverrideByDrop   Setter to override royalty basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                  The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyBasisPoints_      Royalty basis points verride
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyOverrideByDrop(
    string memory dropId_,
    uint256 royaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(uint32 dropExpiryInDays_) external;

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external;

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string memory templateDescription_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(uint16 templateNumber_) external;

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(string memory dropId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string memory dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[3] memory collectionURIs_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external view returns (bool matches_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external pure returns (bytes32 configHash_);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * =======================================================================
 * Metadrop Access control, OpenZeppelin AccessControl with string usage
 * replaced with custom errors
 * =======================================================================
 *
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  error AccountDoesNotHaveRole(address account, bytes32 role);
  error CanOnlyRenounceForSelf();

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(
    bytes32 role,
    address account
  ) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      // revert(
      //     string(
      //         abi.encodePacked(
      //             "AccessControl: account ",
      //             Strings.toHexString(account),
      //             " is missing role ",
      //             Strings.toHexString(uint256(role), 32)
      //         )
      //     )
      // );
      revert AccountDoesNotHaveRole(account, role);
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(
    bytes32 role
  ) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    if (account != _msgSender()) {
      revert CanOnlyRenounceForSelf();
    }

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * May emit a {RoleGranted} event.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   *
   * NOTE: This function is deprecated in favor of {_grantRole}.
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title AuthorityModel.sol. Library for global authority components
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

/**
 *
 * @dev Inheritance details:
 *      AccessControl           OZ access control implementation - used for authority control
 *
 */

import "./AccessControlM.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AuthorityModel is AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  // Platform admin: The role for platform admins. Platform admins can be added. These addresses have privileged
  // access to maintain configuration like the platform fee.
  bytes32 internal constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

  // Review admin: access to perform reviews of drops, in this case the authority to maintain the drop status parameter, and
  // set it from review to editable (when sending back to the project owner), or from review to approved (when)
  // the drop is ready to go).
  bytes32 internal constant REVIEW_ADMIN = keccak256("REVIEW_ADMIN");

  // Project owner: This is the role for the project itself, i.e. the team that own this drop.
  bytes32 internal constant PROJECT_OWNER = keccak256("PROJECT_OWNER");

  // Address for the factory:
  address internal factory;

  // The super admin can grant and revoke roles
  address public superAdmin;

  // The project owner. Only applicable if inheritor is a Drop or a project.
  address public projectOwner;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _platformAdmins;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _reviewAdmins;

  /** ====================================================================================================================
   *                                                        ERRORS
   * =====================================================================================================================
   */
  error CallerIsNotDefaultAdmin(address caller);
  error CallerIsNotPlatformAdmin(address caller);
  error CallerIsNotReviewAdmin(address caller);
  error CallerIsNotPlatformAdminOrProjectOwner(address caller);
  error CallerIsNotPlatformAdminOrFactory(address caller);
  error CallerIsNotProjectOwner(address caller);
  error MustHaveAPlatformAdmin();
  error PlatformAdminCannotBeAddressZero();
  error ReviewAdminCannotBeAddressZero();
  error CannotGrantOrRevokeDirectly();

  /** ====================================================================================================================
   *                                                       MODIFIERS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlySuperAdmin. The associated action can only be taken by the super admin (an address with the
   * default admin role).
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlySuperAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
      revert CallerIsNotDefaultAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdmin() {
    if (!hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyReviewAdmin. The associated action can only be taken by an address with the
   * review admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyReviewAdmin() {
    if (!hasRole(REVIEW_ADMIN, msg.sender))
      revert CallerIsNotReviewAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdminOrProjectOwner. The associated action can only be taken by an address with the
   * platform admin role or project owner role
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdminOrProjectOwner() {
    if (
      !hasRole(PLATFORM_ADMIN, msg.sender) &&
      !hasRole(PROJECT_OWNER, msg.sender)
    ) revert CallerIsNotPlatformAdminOrProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyProjectOwner. The associated action can only be taken by an address with the
   * project owner role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyProjectOwner() {
    if (!hasRole(PROJECT_OWNER, msg.sender))
      revert CallerIsNotProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyFactoryOrPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role or the factory.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyFactoryOrPlatformAdmin() {
    if (msg.sender != factory && !hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdminOrFactory(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformAdmins   Getter for the enumerable list of platform admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformAdmins_  A list of platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformAdmins()
    public
    view
    returns (address[] memory platformAdmins_)
  {
    return (_platformAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getReviewAdmins   Getter for the enumerable list of review admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return reviewAdmins_  A list of review admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getReviewAdmins()
    public
    view
    returns (address[] memory reviewAdmins_)
  {
    return (_reviewAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantPlatformAdmin  Allows the super user Default Admin to add an address to the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_              The address of the new platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantPlatformAdmin(address newPlatformAdmin_) public onlySuperAdmin {
    if (newPlatformAdmin_ == address(0)) {
      revert PlatformAdminCannotBeAddressZero();
    }

    _grantRole(PLATFORM_ADMIN, newPlatformAdmin_);
    // Add this to the enumerated list:
    _platformAdmins.add(newPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantReviewAdmin  Allows the super user Default Admin to add an address to the review admin group.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newReviewAdmin_              The address of the new review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantReviewAdmin(address newReviewAdmin_) public onlySuperAdmin {
    if (newReviewAdmin_ == address(0)) {
      revert ReviewAdminCannotBeAddressZero();
    }
    _grantRole(REVIEW_ADMIN, newReviewAdmin_);
    // Add this to the enumerated list:
    _reviewAdmins.add(newReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokePlatformAdmin  Allows the super user Default Admin to revoke from the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldPlatformAdmin_              The address of the old platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokePlatformAdmin(
    address oldPlatformAdmin_
  ) external onlySuperAdmin {
    _revokeRole(PLATFORM_ADMIN, oldPlatformAdmin_);
    // Remove this from the enumerated list:
    _platformAdmins.remove(oldPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeReviewAdmin  Allows the super user Default Admin to revoke an address to the review admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldReviewAdmin_              The address of the old review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokeReviewAdmin(address oldReviewAdmin_) external onlySuperAdmin {
    _revokeRole(REVIEW_ADMIN, oldReviewAdmin_);
    // Remove this from the enumerated list:
    _reviewAdmins.remove(oldReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferSuperAdmin  Allows the super user Default Admin to transfer this right to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newSuperAdmin_              The address of the new default admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferSuperAdmin(address newSuperAdmin_) external onlySuperAdmin {
    _grantRole(DEFAULT_ADMIN_ROLE, newSuperAdmin_);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // Update storage of this address:
    superAdmin = newSuperAdmin_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferProjectOwner  Allows the current project owner to transfer this role to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_   New project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(
    address newProjectOwner_
  ) external onlyProjectOwner {
    _grantRole(PROJECT_OWNER, newProjectOwner_);
    _revokeRole(PROJECT_OWNER, msg.sender);
    projectOwner = newProjectOwner_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */
  function grantRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */

  function revokeRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) _initialiseAuthorityModel  Set intial authorities and roles
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_        The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_    Array of Platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_      Project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseAuthorityModel(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_
  ) internal {
    if (platformAdmins_.length == 0) {
      revert MustHaveAPlatformAdmin();
    }

    // DEFAULT_ADMIN_ROLE can grant and revoke all other roles. This address MUST be secured:
    _grantRole(DEFAULT_ADMIN_ROLE, superAdmin_);
    superAdmin = superAdmin_;

    // Setup the project owner address
    _grantRole(PROJECT_OWNER, projectOwner_);
    projectOwner = projectOwner_;

    // Setup the platform admin addresses
    for (uint256 i = 0; i < platformAdmins_.length; ) {
      _grantRole(PLATFORM_ADMIN, platformAdmins_[i]);
      // Add this to the enumerated list:
      _platformAdmins.add(platformAdmins_[i]);

      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IConfigStructures.sol. Interface for common config structures used accross the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IConfigStructures {
  enum DropStatus {
    approved,
    deployed,
    cancelled
  }

  enum TemplateStatus {
    live,
    terminated
  }

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PrimarySaleModuleInstance {
    address instanceAddress;
    string instanceDescription;
  }

  struct NFTModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct PrimarySaleModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct VestingModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct RoyaltySplitterModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModules {
    InLifeModuleConfig[] modules;
  }

  struct NFTConfig {
    uint256 supply;
    uint256 mintingMethod;
    string name;
    string symbol;
    bytes32 positionProof;
  }

  struct DropApproval {
    DropStatus status;
    uint32 lastChangedDate;
    address dropOwnerAddress;
    bytes32 configHash;
  }

  struct Template {
    TemplateStatus status;
    uint16 templateNumber;
    uint32 loadedDate;
    address payable templateAddress;
    string templateDescription;
  }

  struct NumericOverride {
    bool isSet;
    uint248 overrideValue;
  }

  error AlreadyInitialised();
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title INFTByMetadrop.sol. Interface for metadrop NFT standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Global/IConfigStructures.sol";

interface INFTByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event Revealed();
  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);
  event PositionProofSet(bytes32 positionProof);
  event MetadropMint(
    address indexed allowanceAddress,
    address indexed recipientAddress,
    address callerAddress,
    address primarySaleModuleAddress,
    uint256 unitPrice,
    uint256[] tokenIds
  );

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error MetadataIsLocked();
  error InvalidAddress();
  error IncorrectConfirmationValue();
  error MintingIsClosedForever();
  error VRFAlreadySet();
  error PositionProofAlreadySet();
  error MetadropFactoryOnly();
  error InvalidRecipient();
  error PauseCutOffHasPassed();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_              The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_          An array of platform admin addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_       The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_ The primary sale modules for this drop. These are the contract addresses that are
   *                            authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_          The drop specific configuration for this NFT. This is decoded and used to set
   *                            configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_  The address of the deployed royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param totalRoyaltyPercentage_  The total royalty percentage (project + metadrop) for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    address royaltyPaymentSplitter_,
    uint96 totalRoyaltyPercentage_,
    string[3] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_);

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view returns (uint256 totalSupply_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() external view returns (uint256 totalUnminted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view returns (uint256 totalMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view returns (uint256 totalBurned_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param preRevealURI_   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param arweaveURI_     The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * @param ipfsURI_     The URI for IPFS
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(
    string calldata preRevealURI_,
    string calldata arweaveURI_,
    string calldata ipfsURI_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_   The confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(string calldata confirmation_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner OR platform admin to set minting
   *                                                          complete
   *
   * @notice Enter confirmation value of "MintingComplete" to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_  Confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    string calldata confirmation_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setUseArweave  Guards against either arweave or IPFS being no more
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param useArweave_   Boolean to indicate whether arweave should be used or not (true = use arweave, false = use IPFS)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setUseArweave(bool useArweave_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(address recipient_, uint96 fraction_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_   The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_        The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setStartPosition  Get the metadata start position for use on reveal of this collection
   * _____________________________________________________________________________________________________________________
   */
  function setStartPosition() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IPrimarySaleModule.sol. Interface for base primary sale module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "../NFT/INFTByMetadrop.sol";
import "../ThirdParty/EPS/EPSDelegationRegister/IEPSDelegationRegister.sol";

interface IPrimarySaleModule is IConfigStructures {
  /** ====================================================================================================================
   *                                                       ERRORS
   * =====================================================================================================================
   */
  error AddressAlreadySet();
  error ThisMintIsClosed();
  error IncorrectPayment();
  error InvalidOracleSignature();
  error QuantityExceedsPhaseRemainingSupply(
    uint256 requested,
    uint256 remaining
  );
  error ParametersDoNotMatchSignedMessage();
  error TransferFailed();
  error OracleSignatureHasExpired();
  error CannotSetToZeroAddress();

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Defined here and must be overriden in child contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_            The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_        The platform admins for this contract, used to set platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_          The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vesting_               The vesting contract used for sales proceeds from this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_            The drop specific configuration for this module. This is decoded and used to set
   *                               configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_     The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_ The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimarySaleModule(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_,
    address vesting_,
    bytes calldata configData_,
    uint256 pauseCutoffInDays_,
    address metadropOracleAddress_,
    uint80 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) setNFTAddress    Set the NFT contract for this drop
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftContract_           The deployed NFT contract
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setNFTAddress(address nftContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) phaseMintStatus    The status of the deployed primary sale module
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferETHToBeneficiary    A transfer function to allow ETH to be withdrawn to the vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             The amount to transfer
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferETHToBeneficiary(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferETHBalanceToBeneficiary   A transfer function to allow  all ETH to be withdrawn
   *                                                           to vesting.
   * _____________________________________________________________________________________________________________________
   */
  function transferETHBalanceToBeneficiary() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferERC20ToBeneficiary     A transfer function to allow ERC20s to be withdrawn to the
   *                                                vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_             The token to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferERC20ToBeneficiary(IERC20 token_, uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setMetadropOracleAddress   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_         The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setVestingContractAddress     Allow platform admin to update vesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingContract_         The new vesting contract address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setProposedVestingContractAddress(address vestingContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) approveProposedVestingContractAddress     Allow project owner to authorise update vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveProposedVestingContractAddress() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn off anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn ON anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOn() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn off EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn ON EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOn() external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IPrimaryVestingByMetadrop.sol. Interface for base primary vesting module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Global/IConfigStructures.sol";

interface IPrimaryVestingByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    ENUMS AND STRUCTS
   * =====================================================================================================================
   */
  struct VestingConfig {
    uint256 start;
    uint256 projectUpFrontShare;
    uint256 projectVestedShare;
    uint256 vestingPeriodInDays;
    uint256 vestingCliff;
    ProjectBeneficiary[] projectPayees;
  }

  struct ProjectBeneficiary {
    address payable payeeAddress;
    uint256 payeeShares;
  }

  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */
  event PayeeAdded(
    address account,
    uint256 shares,
    uint256 vestingPeriodInDays
  );
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimaryVesting  Initialise data on the vesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_    Configuration object for this instance of vesting
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAddress_  The address for payments to the platform
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimaryVesting(
    VestingModuleConfig calldata vestingModule_,
    address platformAddress_,
    uint256 platformShare_
  ) external;

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable;

  /**
   * @dev Getter for the total shares held by payees.
   */
  function sharesTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the platform.
   */
  function sharesPlatform() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are vested.
   */
  function sharesProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are upfront.
   */
  function sharesProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function releasedETHTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of Ether already released to the platform.
   */
  function releasedETHPlatform() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project vested.
   */
  function releasedETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project upfront.
   */
  function releasedETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
   * contract.
   */
  function releasedERC20Total(IERC20 token) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the platform. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20Platform(IERC20 token) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project vested. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project upfront. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for platform address
   */
  function platformAddress() external view returns (address);

  /**
   * @dev Getter for project address
   */
  function projectAddresses()
    external
    view
    returns (ProjectBeneficiary[] memory);

  /**
   * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountEth(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountERC20(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of the platform's releasable Ether.
   */
  function releasableETHPlatform() external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable Ether.
   */
  function releasableETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of the project's upfront releasable Ether.
   */
  function releasableETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the amount of platform's releasable `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20Platform(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's releasable upfront `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Triggers a transfer to the platform of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function releasePlatformETH() external;

  /**
   * @dev Triggers a transfer to the project of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function releaseProjectETH(uint256 gasLimit_) external;

  /**
   * @dev Triggers a transfer to the platform of the amount of `token` tokens they are owed, according to their
   * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
   * contract.
   */
  function releasePlatformERC20(IERC20 token) external;

  /**
   * @dev Triggers a transfer to the project of the amount of `token` tokens they are owed, according to their
   * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
   * contract.
   */
  function releaseProjectERC20(IERC20 token) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IRoyaltyPaymentSplitterByMetadrop.sol. Interface for royalty module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Global/IConfigStructures.sol";

interface IRoyaltyPaymentSplitterByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    ENUMS AND STRUCTS
   * =====================================================================================================================
   */
  struct RoyaltyPaymentSplitterConfig {
    address projectRoyaltyAddress;
    uint256 royaltyFromSalesInBasisPoints;
  }

  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /** ====================================================================================================================
   *                                                       FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseRoyaltyPaymentSplitter  Initialise data on the royalty contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyModule_                        Configuration object for this instance of vesting
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_                     The address for payments to the platform
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformRoyaltyPercentInBasisPoints_  The basis point share for the platform
   * ---------------------------------------------------------------------------------------------------------------------
   * @return royaltyFromSalesInBasisPoints_       The royalty share from sales in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseRoyaltyPaymentSplitter(
    RoyaltySplitterModuleConfig calldata royaltyModule_,
    address platformTreasury_,
    uint256 platformRoyaltyPercentInBasisPoints_
  ) external returns (uint96 royaltyFromSalesInBasisPoints_);
}

// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS Delegation Register - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../EPSRewardToken/IOAT.sol";
import "../EPSRewardToken/IERCOmnReceiver.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSDelegationRegister {
  // ======================================================
  // ENUMS and STRUCTS
  // ======================================================

  // Scope of a delegation: global, collection or token
  enum DelegationScope {
    global,
    collection,
    token
  }

  // Time limit of a delegation: eternal or time limited
  enum DelegationTimeLimit {
    eternal,
    limited
  }

  // The Class of a delegation: primary, secondary or rental
  enum DelegationClass {
    primary,
    secondary,
    rental
  }

  // The status of a delegation:
  enum DelegationStatus {
    live,
    pending
  }

  // Data output format for a report (used to output both hot and cold
  // delegation details)
  struct DelegationReport {
    address hot;
    address cold;
    DelegationScope scope;
    DelegationClass class;
    DelegationTimeLimit timeLimit;
    address collection;
    uint256 tokenId;
    uint40 startDate;
    uint40 endDate;
    bool validByDate;
    bool validBilaterally;
    bool validTokenOwnership;
    bool[25] usageTypes;
    address key;
    uint96 controlInteger;
    bytes data;
    DelegationStatus status;
  }

  // Delegation record
  struct DelegationRecord {
    address hot;
    uint96 controlInteger;
    address cold;
    uint40 startDate;
    uint40 endDate;
    DelegationStatus status;
  }

  // If a delegation is for a collection, or has additional data, it will need to read the delegation metadata
  struct DelegationMetadata {
    address collection;
    uint256 tokenId;
    bytes data;
  }

  // Details of a hot wallet lock
  struct LockDetails {
    uint40 lockStart;
    uint40 lockEnd;
  }

  // Validity dates when checking a delegation
  struct ValidityDates {
    uint40 start;
    uint40 end;
  }

  // Delegation struct to hold details of a new delegation
  struct Delegation {
    address hot;
    address cold;
    address[] targetAddresses;
    uint256 tokenId;
    bool tokenDelegation;
    uint8[] usageTypes;
    uint40 startDate;
    uint40 endDate;
    uint16 providerCode;
    DelegationClass delegationClass;
    uint96 subDelegateKey;
    bytes data;
    DelegationStatus status;
  }

  // Addresses associated with a delegation check
  struct DelegationCheckAddresses {
    address hot;
    address cold;
    address targetCollection;
  }

  // Classes associated with a delegation check
  struct DelegationCheckClasses {
    bool secondary;
    bool rental;
    bool token;
  }

  // Migrated record data
  struct MigratedRecord {
    address hot;
    address cold;
  }

  // ======================================================
  // CUSTOM ERRORS
  // ======================================================

  error UsageTypeAlreadyDelegated(uint256 usageType);
  error CannotDeleteValidDelegation();
  error CannotDelegatedATokenYouDontOwn();
  error IncorrectAdminLevel(uint256 requiredLevel);
  error OnlyParticipantOrAuthorisedSubDelegate();
  error HotAddressIsLockedAndCannotBeDelegatedTo();
  error InvalidDelegation();
  error ToMuchETHForPendingPayments(uint256 sent, uint256 required);
  error UnknownAmount();
  error InvalidERC20Payment();
  error IncorrectProxyRegisterFee();
  error UnrecognisedEPSAPIAmount();
  error CannotRevokeAllForRegisterAdminHierarchy();

  // ======================================================
  // EVENTS
  // ======================================================

  event DelegationMade(
    address indexed hot,
    address indexed cold,
    address targetAddress,
    uint256 tokenId,
    bool tokenDelegation,
    uint8[] usageTypes,
    uint40 startDate,
    uint40 endDate,
    uint16 providerCode,
    DelegationClass delegationClass,
    uint96 subDelegateKey,
    bytes data,
    DelegationStatus status
  );
  event DelegationRevoked(address hot, address cold, address delegationKey);
  event DelegationPaid(address delegationKey);
  event AllDelegationsRevokedForHot(address hot);
  event AllDelegationsRevokedForCold(address cold);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   *
   *
   * @dev getDelegationRecord
   *
   *
   */
  function getDelegationRecord(address delegationKey_)
    external
    view
    returns (DelegationRecord memory);

  /**
   *
   *
   * @dev isValidDelegation
   *
   *
   */
  function isValidDelegation(
    address hot_,
    address cold_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (bool isValid_);

  /**
   *
   *
   * @dev getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   *
   *
   */
  function getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (address[] memory addresses_);

  /**
   *
   *
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance
   *
   *
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address contractAddress_,
    uint256 usageType_,
    bool erc1155_,
    uint256 id_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (uint256 balance_);

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(
    address collection_,
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    external
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    );

  /**
   *
   *
   * @dev delegationFromColdExists - check a cold delegation exists
   *
   *
   */
  function delegationFromColdExists(address cold_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev delegationFromHotExists - check a hot delegation exists
   *
   *
   */
  function delegationFromHotExists(address hot_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev getAllForHot - Get all delegations at a hot address, formatted nicely
   *
   *
   */
  function getAllForHot(address hot_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev getAllForCold - Get all delegations at a cold address, formatted nicely
   *
   *
   */
  function getAllForCold(address cold_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev makeDelegation - A direct call to setup a new proxy record
   *
   *
   */
  function makeDelegation(
    address hot_,
    address cold_,
    address[] memory targetAddresses_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint8[] memory usageTypes_,
    uint40 startDate_,
    uint40 endDate_,
    uint16 providerCode_,
    DelegationClass delegationClass_, //0 = primary, 1 = secondary, 2 = rental
    uint96 subDelegateKey_,
    bytes memory data_
  ) external payable;

  /**
   *
   *
   * @dev getDelegationKey - get the link hash to the delegation metadata
   *
   *
   */
  function getDelegationKey(
    address hot_,
    address cold_,
    address targetAddress_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint96 controlInteger_,
    uint40 startDate_,
    uint40 endDate_
  ) external pure returns (address);

  /**
   *
   *
   * @dev getHotAddressLockDetails
   *
   *
   */
  function getHotAddressLockDetails(address hot_)
    external
    view
    returns (LockDetails memory, address[] memory);

  /**
   *
   *
   * @dev lockAddressUntilDate
   *
   *
   */
  function lockAddressUntilDate(uint40 unlockDate_) external;

  /**
   *
   *
   * @dev lockAddress
   *
   *
   */
  function lockAddress() external;

  /**
   *
   *
   * @dev unlockAddress
   *
   *
   */
  function unlockAddress() external;

  /**
   *
   *
   * @dev addLockBypassAddress
   *
   *
   */
  function addLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev removeLockBypassAddress
   *
   *
   */
  function removeLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev revokeRecord: Revoking a single record with Key
   *
   *
   */
  function revokeRecord(address delegationKey_, uint96 subDelegateKey_)
    external;

  /**
   *
   *
   * @dev revokeGlobalAll
   *
   *
   */
  function revokeRecordOfGlobalScopeForAllUsages(address participant2_)
    external;

  /**
   *
   *
   * @dev revokeAllForCold: Cold calls and revokes ALL
   *
   *
   */
  function revokeAllForCold(address cold_, uint96 subDelegateKey_) external;

  /**
   *
   *
   * @dev revokeAllForHot: Hot calls and revokes ALL
   *
   *
   */
  function revokeAllForHot() external;

  /**
   *
   *
   * @dev deleteExpired: ANYONE can delete expired records
   *
   *
   */
  function deleteExpired(address delegationKey_) external;

  /**
   *
   *
   * @dev setRegisterFee: set the fee for accepting a registration:
   *
   *
   */
  function setRegisterFees(
    uint256 registerFee_,
    address erc20_,
    uint256 erc20Fee_
  ) external;

  /**
   *
   *
   * @dev setRewardTokenAndRate
   *
   *
   */
  function setRewardTokenAndRate(address rewardToken_, uint88 rewardRate_)
    external;

  /**
   *
   *
   * @dev lockRewardRate
   *
   *
   */
  function lockRewardRate() external;

  /**
   *
   *
   * @dev setLegacyOff
   *
   *
   */
  function setLegacyOff() external;

  /**
   *
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   *
   */
  function setENSName(string memory ensName_) external;

  /**
   *
   *
   * @dev setENSReverseRegistrar
   *
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_) external;

  /**
   *
   *
   * @dev setTreasuryAddress: set the treasury address:
   *
   *
   */
  function setTreasuryAddress(address treasuryAddress_) external;

  /**
   *
   *
   * @dev setDecimalsAndBalance
   *
   *
   */
  function setDecimalsAndBalance(uint8 decimals_, uint256 balance_) external;

  /**
   *
   *
   * @dev withdrawETH: withdraw eth to the treasury:
   *
   *
   */
  function withdrawETH(uint256 amount_) external returns (bool success_);

  /**
   *
   *
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   *
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   *
   *
   * @dev isLevelAdmin
   *
   *
   */
  function isLevelAdmin(
    address receivedAddress_,
    uint256 level_,
    uint96 key_
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IERCOmnReceiver - Interface

 */

pragma solidity 0.8.19;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IOAT - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev OAT interface
 */
interface IOAT is IERC20 {
  /**
   *
   * @dev emitToken
   *
   */
  function emitToken(address receiver_, uint256 amount_) external;

  /**
   *
   * @dev addEmitter
   *
   */
  function addEmitter(address emitter_) external;

  /**
   *
   * @dev removeEmitter
   *
   */
  function removeEmitter(address emitter_) external;

  /**
   *
   * @dev setTreasury
   *
   */
  function setTreasury(address treasury_) external;
}