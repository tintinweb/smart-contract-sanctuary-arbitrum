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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface IThemisProject {
   
    event ProjectCreated(
        uint256 signId,
        uint256 projectId,
        address creater,
        address tokenAddr,
        uint256 tokenAmount,
        address themisRaffleTicketAddr,
        uint32 winningAmount,
        uint64[] timestamps,
        string winUri,
        string loseUri
    );

    event TimestampModified(
        uint256 projectId,
        address operator,
        uint64 newStartCampaign,
        uint64 newEndCampaign,
        uint64 newStartRaffle,
        uint64 newEndRaffle,
        uint64 newStartClaim,
        uint64 newEndClaim
    );

    event WinningAmountModified(
        uint256 projectId,
        address operator,
        uint32 newWinningAmount
    );

    event AirDropModified(
        uint256 projectId,
        address operator,
        address newTokenAddr,
        uint256 newTokenAmount
    );

    event AirDropInjected(
        uint256 projectId,
        address injector,
        address tokenAddr,
        uint256 tokenAmount
    );

    event VoteUploaded(
        uint256 projectId,
        uint256 signId,
        address user,
        uint32 latestVoteId,
        uint256 latestIndex,
        uint256 newVoteAmount
    );

    event RequestRandom(uint256 projectId, uint256 requestId);

    event FulfillRandomWord(uint256 projectId, uint256 randomWord);

    event ResultClaimed(
        uint256 projectId,
        address user,
        uint256 claimAmount,
        uint256 successAmount,
        uint256[] numberSuccesses
    );

    event RepeatAmountUpdated(uint256 projectId, uint24 repeatAmount);

    event TokenWithdrew(
        uint256 projectId,
        address tokenAddr,
        uint256 tokenAmount
    );

    event RaffleDurationSet(uint64 newRaffleDuration);

    event SignDurationSet(uint64 newSignDuration);

    event VaultSet(address newVault);

    event FeeSet(uint256 newfee);

    event ThemisRaffleTicketSet(address newThemisRaffleTicket);

    event ExecutorSet(address executorAddr, bool isAllowed);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IThemisRaffleTicket {
    event NameSet(string newName);

    event SymbolSet(string newSymbol);

    event BaseURISet(string newBaseURI);

    event UriSet(uint256 id, string winUri, string loseUri);

    event UriModified(uint256 id, string newWinUri, string newLoseUri);

    event ExecutorSet(address executorAddr, bool isAllowed);

    function mint(address to, uint256 tokenId, uint256 tokenAmount) external;

    function replace(address to, uint256 tokenId, uint256 tokenAmount) external;

    function setTokenUri(
        uint256 id,
        string calldata winUri,
        string calldata lossUri
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IThemisService {
    event UploadForPlatform(uint256 projectId);

    event DataURISet(string dataURI);

    event PlatformSet(address platformAddr, bool isAllowed);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ThemisStruct.sol";
import "./interfaces/IThemisProject.sol";
import "./interfaces/IThemisRaffleTicket.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract ThemisProject is VRFConsumerBaseV2, Ownable, IThemisProject {
    using ECDSA for bytes32;

    using Counters for Counters.Counter;
    Counters.Counter public projectIdCounter;

    uint64 private _raffleDuration;
    uint64 private _signDuration;

    address public themisRaffleTicket;

    address private _vault;

    uint256 private _fee;

    mapping(address => bool) private _executors;

    mapping(uint256 => Project) public projects;

    // projectId => AirDrop
    mapping(uint256 => AirDrop) public airDrops;

    //ProjectSignature verification
    mapping(uint256 => bool) private _isUsedProjectSignature;
    //UploadSignature verification
    mapping(uint256 => bool) private _isUsedUploadSignature;

    // projectId => user => userNumbers
    mapping(uint256 => mapping(address => uint32[])) private _userNumbers;

    //ChainLink VRF
    ChainLinkVrfParam public chainLinkVrfParam;
    // requestId => ProjectId
    mapping(uint256 => uint256) private _requestId2Project;

    constructor(
        uint64 raffleDuration_,
        uint64 signDuration_,
        address executor_,
        address vault_,
        address themisRaffleTicket_,
        uint256 fee_,
        address vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        chainLinkVrfParam = ChainLinkVrfParam({
            vrfCoordinator: VRFCoordinatorV2Interface(vrfCoordinator_),
            requestConfirmations: 3,
            callbackGasLimit: 1000000,
            numWords: 1,
            subscriptionId: subscriptionId_,
            keyHash: keyHash_
        });
        setRaffleDuration(raffleDuration_);
        setSignDuration(signDuration_);
        setExecutor(executor_, true);
        setVault(vault_);
        setThemisRaffleTicket(themisRaffleTicket_);
        setFee(fee_);
    }

    modifier onlyExecutor() {
        require(isExecutor(_msgSender()), "Themis: Only executors");
        _;
    }

    modifier verifyModify(uint256 projectId, bytes calldata signature) {
        require(
            projects[projectId].winningAmount > 0,
            "Themis: Project not exist"
        );

        address signer = keccak256(
            abi.encodePacked("MODIFY", projectId, _msgSender())
        ).toEthSignedMessageHash().recover(signature);

        require(isExecutor(signer), "Themis: signer is wrong.");
        _;
    }

    /**
     * @notice  The first step of the entire project, including setting the airdrop information,
     *          setting the required parameters for the project (time, total number of winning votes)
     */
    function createProject(ProjectInfo calldata projectInfo) external {
        //Step 1: verify signature
        require(
            _isUsedProjectSignature[projectInfo.signId] == false,
            "Themis: signature is used"
        );
        _isUsedProjectSignature[projectInfo.signId] = true;

        address signer = keccak256(
            abi.encodePacked("CREATE", projectInfo.signId, _msgSender())
        ).toEthSignedMessageHash().recover(projectInfo.signature);
        require(isExecutor(signer), "Themis: signer is wrong.");

        //Step 2: create project
        projectIdCounter.increment();
        uint256 projectId = projectIdCounter.current();

        require(
            projectInfo.tokenAmount > 0 && projectInfo.winningAmount > 0,
            "Themis: Amount error"
        );

        airDrops[projectId] = AirDrop({
            ready: false,
            tokenAddr: projectInfo.tokenAddr,
            tokenAmount: projectInfo.tokenAmount,
            remainingAmount: projectInfo.tokenAmount
        });

        require(
            block.timestamp < projectInfo.startCampaign &&
                projectInfo.startCampaign < projectInfo.endCampaign &&
                projectInfo.endCampaign < projectInfo.startRaffle &&
                projectInfo.startRaffle + raffleDuration() <
                projectInfo.endRaffle &&
                projectInfo.endRaffle < projectInfo.startClaim &&
                projectInfo.startClaim < projectInfo.endClaim,
            "Themis: Timestamp error"
        );

        projects[projectId] = Project({
            isRequested: false,
            isRaffled: false,
            repeatAmount: 0,
            winningAmount: projectInfo.winningAmount,
            currentVoteId: 0,
            startCampaign: projectInfo.startCampaign,
            endCampaign: projectInfo.endCampaign,
            startRaffle: projectInfo.startRaffle,
            endRaffle: projectInfo.endRaffle,
            startClaim: projectInfo.startClaim,
            endClaim: projectInfo.endClaim,
            raffleTicketAddr: themisRaffleTicket,
            randomWord: 0
        });

        
        //Step 3: Configure result credential uri
        IThemisRaffleTicket(themisRaffleTicket).setTokenUri(
            projectId,
            projectInfo.winUri,
            projectInfo.loseUri
        );

        projectIdCounter.increment(); // projectId is an odd growth

        uint64[] memory timestamps = new uint64[](6);
        timestamps[0] = projectInfo.startCampaign;
        timestamps[1] = projectInfo.endCampaign;
        timestamps[2] = projectInfo.startRaffle;
        timestamps[3] = projectInfo.endRaffle;
        timestamps[4] = projectInfo.startClaim;
        timestamps[5] = projectInfo.endClaim;

        emit ProjectCreated(
            projectInfo.signId,
            projectId,
            _msgSender(),
            projectInfo.tokenAddr,
            projectInfo.tokenAmount,
            themisRaffleTicket,
            projectInfo.winningAmount,
            timestamps,
            projectInfo.winUri,
            projectInfo.loseUri
        );
    }
    
    function modifyTimestamp(
        TimestampInfo calldata timestampInfo
    ) external verifyModify(timestampInfo.projectId, timestampInfo.signature) {
        require(
            block.timestamp < timestampInfo.startCampaign &&
                timestampInfo.startCampaign < timestampInfo.endCampaign &&
                timestampInfo.endCampaign < timestampInfo.startRaffle &&
                timestampInfo.startRaffle + raffleDuration() <
                timestampInfo.endRaffle &&
                timestampInfo.endRaffle < timestampInfo.startClaim &&
                timestampInfo.startClaim < timestampInfo.endClaim,
            "Themis: timestamp error"
        );

        uint256 projectId = timestampInfo.projectId;

        if(airDrops[projectId].ready){
            require(
                block.timestamp < projects[projectId].startCampaign,
                "Themis: Campaign started"
            );
        }

        projects[projectId].startCampaign = timestampInfo.startCampaign;
        projects[projectId].endCampaign = timestampInfo.endCampaign;
        projects[projectId].startRaffle = timestampInfo.startRaffle;
        projects[projectId].endRaffle = timestampInfo.endRaffle;
        projects[projectId].startClaim = timestampInfo.startClaim;
        projects[projectId].endClaim = timestampInfo.endClaim;

        emit TimestampModified(
            projectId,
            _msgSender(),
            timestampInfo.startCampaign,
            timestampInfo.endCampaign,
            timestampInfo.startRaffle,
            timestampInfo.endRaffle,
            timestampInfo.startClaim,
            timestampInfo.endClaim
        );
    }

    function modifyWinningAmount(
        uint256 projectId,
        uint32 newWinningAmount,
        bytes calldata signature
    ) external verifyModify(projectId, signature) {
        require(newWinningAmount > 0, "Themis: Amount error");

        require(
            block.timestamp < projects[projectId].startCampaign,
            "Themis: Campaign started"
        );

        projects[projectId].winningAmount = newWinningAmount;

        emit WinningAmountModified(projectId, _msgSender(), newWinningAmount);
    }

    function modifyAirDrop(
        uint256 projectId,
        address newTokenAddr,
        uint256 newTokenAmount,
        bytes calldata signature
    ) external verifyModify(projectId, signature) {
        require(newTokenAmount > 0, "Themis: newTokenAmount error");

        require(
            !airDrops[projectId].ready && airDrops[projectId].tokenAmount > 0,
            "Themis: Injected or project not created"
        );

        airDrops[projectId] = AirDrop({
            ready: false,
            tokenAddr: newTokenAddr,
            tokenAmount: newTokenAmount,
            remainingAmount: newTokenAmount
        });

        emit AirDropModified(
            projectId,
            _msgSender(),
            newTokenAddr,
            newTokenAmount
        );
    }

    /**
     * @notice After the project is created, the project team needs to inject airdrop tokens into the contract,
     *         which is one of the conditions for project initiation
     * @param tokenAddr   The contract address for airdrop tokens (requires ERC20), if airdrop native tokens,
     *                     please enter a zero address
     * @param tokenAmount Total number of airdropped tokens
     */
    function injectAirDrop(
        uint256 projectId,
        address tokenAddr,
        uint256 tokenAmount
    ) external payable {
        AirDrop memory airDrop = airDrops[projectId];

        require(
            !airDrop.ready && airDrop.tokenAmount > 0,
            "Themis: Injected or project not created"
        );
        require(
            block.timestamp < projects[projectId].startCampaign,
            "Themis: Exceeding startCampaign"
        );

        address injector = _msgSender();
        if (airDrop.tokenAddr != address(0)) {
            // airDrop erc20
            require(
                airDrop.tokenAddr == tokenAddr &&
                    airDrop.tokenAmount == tokenAmount &&
                    fee() == msg.value,
                "Themis: Token mismatch"
            );
            IERC20(tokenAddr).transferFrom(
                injector,
                address(this),
                tokenAmount
            );
            payable(vault()).transfer(fee());
        } else {
            // airDrop eth
            require(
                airDrop.tokenAddr == tokenAddr &&
                    airDrop.tokenAmount + fee() == msg.value,
                "Themis: Token mismatch"
            );
            payable(vault()).transfer(fee());
        }

        airDrops[projectId].ready = true;

        emit AirDropInjected(projectId, injector, tokenAddr, tokenAmount);
    }

    function requestRandom(uint256 projectId) external {
        require(airDrops[projectId].ready, "Themis: airdrop not ready");

        Project memory project = projects[projectId];
        uint256 timestamp = block.timestamp;
        require(
            timestamp > project.startRaffle && timestamp < project.endRaffle,
            "Themis: Not in raffle time"
        );
        require(!project.isRequested, "Themis: Request sent");

        projects[projectId].isRequested = true;
        uint256 requestId = chainLinkVrfParam.vrfCoordinator.requestRandomWords(
            chainLinkVrfParam.keyHash,
            chainLinkVrfParam.subscriptionId,
            chainLinkVrfParam.requestConfirmations,
            chainLinkVrfParam.callbackGasLimit,
            chainLinkVrfParam.numWords
        );

        _requestId2Project[requestId] = projectId;

        emit RequestRandom(projectId, requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        uint256 projectId = _requestId2Project[requestId];
        projects[projectId].randomWord = randomWords[0];
        projects[projectId].isRaffled = true;

        emit FulfillRandomWord(projectId, randomWords[0]);
    }

    function updateRepeatAmount(
        uint256 projectId,
        uint24 repeatAmount
    ) external onlyExecutor {
        require(
            projects[projectId].isRaffled,
            "Themis: The draw was not completed"
        );
        projects[projectId].repeatAmount = repeatAmount;

        emit RepeatAmountUpdated(projectId, repeatAmount);
    }

    /**
     * @notice Themis platform users obtain tickets for completing tasks offline and upload them to the contract
     * @param startTimestamp The timestamp when issuing signatures on the offline platform, used for the validity period of signatures
     * @param voteAmount  Number of votes to be uploaded given to users offline (new votes)
     */
    function uploadVote(
        uint256 signId,
        uint256 projectId,
        uint64 startTimestamp,
        uint256 voteAmount, // new votes
        bytes calldata signature
    ) external {
        require(airDrops[projectId].ready, "Themis: airdrop not ready");

        Project memory project = projects[projectId];
        uint256 timestamp = block.timestamp;
        require(
            timestamp <= startTimestamp + signDuration(),
            "Themis: Signature has timed out"
        );
        require(
            timestamp > project.startCampaign &&
                timestamp < project.endCampaign,
            "Themis: Not within time"
        );

        //Step 1: Verify
        require(
            _isUsedUploadSignature[signId] == false,
            "Themis: signature is used"
        );
        _isUsedUploadSignature[signId] = true;
        address user = _msgSender();

        address signer = keccak256(
            abi.encodePacked(
                "THEMIS",
                signId,
                startTimestamp,
                projectId,
                user,
                voteAmount
            )
        ).toEthSignedMessageHash().recover(signature);
        require(isExecutor(signer), "Themis: signer is wrong.");

        //Step 2: Count the votes
        uint32 currentVoteId = project.currentVoteId;

        require(voteAmount > 0, "Themis: No new votes added");

        for (uint256 i = 0; i < voteAmount; ++i) {
            currentVoteId++;
            _userNumbers[projectId][user].push(currentVoteId);
        }
        projects[projectId].currentVoteId = currentVoteId;

        // Step 3: mint1155
        IThemisRaffleTicket(project.raffleTicketAddr).mint(
            user,
            projectId + 1,
            voteAmount
        );

        uint256 latestIndex = _userNumbers[projectId][user].length - 1;

        emit VoteUploaded(
            projectId,
            signId,
            user,
            currentVoteId,
            latestIndex,
            voteAmount
        );
    }

    // -----------------------------------------------------------------------------------------------------------------------
    // ｜ Lottery rules
    // ｜ The winningAmount is set before the lottery, which represents the final number of winning votes.
    // ｜ The winning numbers are determined by a combination of random numbers randomWord and luckCode, luckCode starts
    // ｜ from 1 until the number of winning numbers reaches winningAmount (skipped if repeated).
    // ｜ The number owned by a user. If the number is the same as the generated winning number, the user can exchange the number.
    // ｜
    // ｜
    // ｜ luckCode  0 1 2 3 4 5 6 .............. winningAmount+repeatAmount-1
    // ｜           luckNumber1 luckNumber2 luckNumber3 luckNumber4 ..............
    // ----------------------------------------------------------------------------------------------------------------------
    /**
     * @notice The user claims the result credentials, mint ERC721
     * @param userNumberIndexs The user's winning draw number stores the index of the array on the chain
     * @param luckCodes  The luckcode used for validation.
     */
    function claimResult(
        uint256 projectId,
        uint256[] calldata userNumberIndexs,
        uint256[] calldata luckCodes
    ) external {
        uint256 luckCodesLength = luckCodes.length;
        require(
            luckCodesLength > 0 && userNumberIndexs.length == luckCodesLength,
            "Themis: Empty List or list length error"
        );

        Project memory project = projects[projectId];
        require(project.isRaffled, "Themis: The draw was not completed");

        uint256 timestamp = block.timestamp;
        require(
            timestamp > project.startClaim && timestamp < project.endClaim,
            "Themis: Not within time"
        );

        address user = _msgSender();
        uint256 luckNumber;
        uint256 successAmount;
        uint256[] memory numberSuccesses = new uint256[](luckCodesLength);

        for (uint256 i = 0; i < luckCodesLength; ++i) {
            require(
                luckCodes[i] < project.winningAmount + project.repeatAmount
            );
            luckNumber =
                (uint256(
                    keccak256(
                        abi.encodePacked(project.randomWord, luckCodes[i])
                    )
                ) % project.currentVoteId) +
                1;

            if (
                _userNumbers[projectId][user][userNumberIndexs[i]] == luckNumber
            ) {
                delete _userNumbers[projectId][user][userNumberIndexs[i]];
                successAmount++;
                numberSuccesses[i] = luckNumber;
            }
        }
        require(successAmount != 0, "Themis: No winning number");

        IThemisRaffleTicket(project.raffleTicketAddr).replace(
            user,
            projectId,
            successAmount
        );

        uint256 airdropAmount = _airdroping(
            projectId,
            project.winningAmount,
            successAmount
        );

        emit ResultClaimed(
            projectId,
            user,
            airdropAmount,
            successAmount,
            numberSuccesses
        );
    }

    function getLuckNumber(
        uint256 projectId,
        uint256[] calldata luckCodes
    ) external view returns (uint256[] memory) {
        uint256 luckCodesLength = luckCodes.length;
        require(luckCodesLength > 0, "Themis: Empty List");

        Project memory project = projects[projectId];
        require(project.isRaffled, "Themis: The draw was not completed");

        uint256[] memory luckNumbers = new uint256[](luckCodesLength);
        for (uint256 i = 0; i < luckCodesLength; ++i) {
            require(
                luckCodes[i] < project.winningAmount + project.repeatAmount,
                "Themis: luck code error"
            );

            luckNumbers[i] =
                (uint256(
                    keccak256(
                        abi.encodePacked(project.randomWord, luckCodes[i])
                    )
                ) % project.currentVoteId) +
                1;
        }
        return luckNumbers;
    }

    function getUserNumbers(
        uint256 projectId,
        address user
    ) external view returns (uint32[] memory) {
        return _userNumbers[projectId][user];
    }

    /**
     * @notice After the end of the claim phase, the remaining airdrop tokens
     *         can be withdrawn to the pre-set vault address
     */
    function withdrawToken(uint256 projectId) external {

        require(
            block.timestamp > projects[projectId].endClaim,
            "Themis: Not yet due for withdrawal"
        );

        AirDrop memory airDrop = airDrops[projectId];
        
        delete airDrops[projectId].remainingAmount;

        if (airDrop.tokenAddr != address(0)) {
            
            IERC20(airDrop.tokenAddr).transfer(
                vault(),
                airDrop.remainingAmount
            );
        } else {
            payable(vault()).transfer(airDrop.remainingAmount);
        }

        emit TokenWithdrew(
            projectId,
            airDrop.tokenAddr,
            airDrop.remainingAmount
        );
    }

    function _airdroping(
        uint256 projectId,
        uint48 winningAmount,
        uint256 successAmount
    ) private returns (uint256) {
        address tokenAddr = airDrops[projectId].tokenAddr;
        uint256 totalAmount = (airDrops[projectId].tokenAmount /
            winningAmount) * successAmount;

        if (tokenAddr != address(0)) {
            IERC20(tokenAddr).transfer(_msgSender(), totalAmount);
        } else {
            payable(_msgSender()).transfer(totalAmount);
        }

        airDrops[projectId].remainingAmount -= totalAmount;

        return totalAmount;
    }

    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    //                                                setting
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    function raffleDuration() internal view returns (uint64) {
        return _raffleDuration;
    }

    function setRaffleDuration(uint64 newRaffleDuration) public onlyOwner {
        _raffleDuration = newRaffleDuration;
        emit RaffleDurationSet(newRaffleDuration);
    }

    function signDuration() internal view returns (uint64) {
        return _signDuration;
    }

    function setSignDuration(uint64 newSignDuration) public onlyOwner {
        _signDuration = newSignDuration;
        emit SignDurationSet(newSignDuration);
    }

    function vault() internal view returns (address) {
        return _vault;
    }

    function setVault(address newVault) public onlyOwner {
        _vault = newVault;
        emit VaultSet(newVault);
    }

    function fee() public view returns (uint256) {
        return _fee;
    }

    function setFee(uint256 newfee) public onlyOwner {
        _fee = newfee;
        emit FeeSet(newfee);
    }

    function setThemisRaffleTicket(
        address newThemisRaffleTicket
    ) public onlyOwner {
        themisRaffleTicket = newThemisRaffleTicket;
        emit ThemisRaffleTicketSet(newThemisRaffleTicket);
    }

    function isExecutor(address executorAddr) internal view returns (bool) {
        return _executors[executorAddr];
    }

    function setExecutor(
        address executorAddr,
        bool isAllowed
    ) public onlyOwner {
        require(_executors[executorAddr] != isAllowed, "Themis: Duplicate");
        _executors[executorAddr] = isAllowed;
        emit ExecutorSet(executorAddr, isAllowed);
    }

    function updateVrfParam(
        ChainLinkVrfParam memory _chainLinkVrfParam
    ) external onlyOwner {
        if (
            chainLinkVrfParam.numWords == 0 ||
            chainLinkVrfParam.callbackGasLimit == 0 ||
            chainLinkVrfParam.requestConfirmations == 0 ||
            address(chainLinkVrfParam.vrfCoordinator) == address(0)
        ) {
            revert("InvalidChainLinkVrfParam");
        }

        chainLinkVrfParam = _chainLinkVrfParam;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IThemisService.sol";
import "./ThemisProject.sol";

contract ThemisService is ThemisProject, IThemisService {
    string private _dataURI;

    // projectId => PlatformData
    mapping(uint256 => PlatformData) private _platformDatas;

    mapping(address => bool) private _platforms;

    constructor(
        uint64 raffleDuration_,
        uint64 signDuration_,
        address executor_,
        address vault_,
        address themisRaffleTicket_,
        uint256 fee_,
        address vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_
    )
        ThemisProject(
            raffleDuration_,
            signDuration_,
            executor_,
            vault_,
            themisRaffleTicket_,
            fee_,
            vrfCoordinator_,
            subscriptionId_,
            keyHash_
        )
    {}

    modifier onlyPlatform() {
        require(isPlatform(_msgSender()), "Themis: Only platforms");
        _;
    }

    function uploadForPlatform(
        uint256 projectId,
        uint128 totalAmount,
        uint128 winningAmount,
        string calldata cid
    ) external onlyPlatform {
        uint256 timestamp = block.timestamp;
        Project memory project = projects[projectId];
        require(
            timestamp > project.startCampaign &&
                timestamp < project.endCampaign,
            "ThemisService: Not within time"
        );

        require(totalAmount > 0 && winningAmount > 0, "Themis: Amount error");

        _platformDatas[projectId] = PlatformData({
            totalAmount: totalAmount,
            winningAmount: winningAmount,
            cid: cid
        });

        emit UploadForPlatform(projectId);
    }

    function getPlatformData(
        uint256 projectId
    ) external view returns (PlatformData memory) {
        PlatformData memory platformData = _platformDatas[projectId];
        require(
            platformData.totalAmount != 0,
            "ThemisService: Data does not exist"
        );
        return platformData;
    }

    function getPlatformDataURI(
        uint256 projectId
    ) external view returns (string memory) {
        string memory cid = _platformDatas[projectId].cid;
        require(bytes(cid).length != 0, "ThemisService: Cid does not exist");

        return string.concat(_dataURI, cid);
    }

    function isPlatform(address platformAddr) internal view returns (bool) {
        return _platforms[platformAddr];
    }

    function setPlatform(
        address platformAddr,
        bool isAllowed
    ) public onlyOwner {
        _platforms[platformAddr] = isAllowed;
        emit PlatformSet(platformAddr, isAllowed);
    }

    function setDataURI(string calldata dataURI) external onlyPlatform {
        _dataURI = dataURI;
        emit DataURISet(dataURI);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

struct Project {
    bool isRequested;
    bool isRaffled;
    uint32 repeatAmount;
    uint32 winningAmount;
    uint32 currentVoteId;
    uint64 startCampaign;
    uint64 endCampaign;
    uint64 startRaffle;
    uint64 endRaffle;
    uint64 startClaim;
    uint64 endClaim;
    address raffleTicketAddr;
    uint256 randomWord;
}

struct AirDrop {
    bool ready;
    address tokenAddr;
    uint256 tokenAmount;
    uint256 remainingAmount;
}

struct ProjectInfo {
    uint32 winningAmount;
    uint64 startCampaign;
    uint64 endCampaign;
    uint64 startRaffle;
    uint64 endRaffle;
    uint64 startClaim;
    uint64 endClaim;
    address tokenAddr;
    uint256 tokenAmount;
    uint256 signId;
    bytes signature;
    string winUri;
    string loseUri;
}

struct TimestampInfo {
    uint256 projectId;
    uint64 startCampaign;
    uint64 endCampaign;
    uint64 startRaffle;
    uint64 endRaffle;
    uint64 startClaim;
    uint64 endClaim;
    bytes signature;
}

struct PlatformData {
    uint128 totalAmount;
    uint128 winningAmount;
    string cid;
}

struct ChainLinkVrfParam {
    VRFCoordinatorV2Interface vrfCoordinator;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    uint64 subscriptionId;
    bytes32 keyHash;
}