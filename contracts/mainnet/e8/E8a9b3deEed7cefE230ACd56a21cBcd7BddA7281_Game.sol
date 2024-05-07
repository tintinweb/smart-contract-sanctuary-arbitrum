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

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "../shared/interfaces/LinkTokenInterface.sol";

import {VRFRequestIDBase} from "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  LinkTokenInterface internal immutable LINK;
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  // solhint-disable-next-line chainlink-solidity/prefix-storage-variables-with-s-underscore
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */ private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.20;

import {IERC1155} from "./IERC1155.sol";
import {IERC1155Receiver} from "./IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "./extensions/IERC1155MetadataURI.sol";
import {Context} from "../../utils/Context.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {Arrays} from "../../utils/Arrays.sol";
import {IERC1155Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC1155Errors {
    using Arrays for uint256[];
    using Arrays for address[];

    mapping(uint256 id => mapping(address account => uint256)) private _balances;

    mapping(address account => mapping(address operator => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 /* id */) public view virtual returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts.unsafeMemoryAccess(i), ids.unsafeMemoryAccess(i));
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`. Will mint (or burn) if `from`
     * (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {IERC1155Receiver-onERC1155Received}
     *   or {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     * - `ids` and `values` must have the same length.
     *
     * NOTE: The ERC-1155 acceptance check is not performed in this function. See {_updateWithAcceptanceCheck} instead.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids.unsafeMemoryAccess(i);
            uint256 value = values.unsafeMemoryAccess(i);

            if (from != address(0)) {
                uint256 fromBalance = _balances[id][from];
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                unchecked {
                    // Overflow not possible: value <= fromBalance
                    _balances[id][from] = fromBalance - value;
                }
            }

            if (to != address(0)) {
                _balances[id][to] += value;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids.unsafeMemoryAccess(0);
            uint256 value = values.unsafeMemoryAccess(0);
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }
    }

    /**
     * @dev Version of {_update} that performs the token acceptance check by calling
     * {IERC1155Receiver-onERC1155Received} or {IERC1155Receiver-onERC1155BatchReceived} on the receiver address if it
     * contains code (eg. is a smart contract at the moment of execution).
     *
     * IMPORTANT: Overriding this function is discouraged because it poses a reentrancy risk from the receiver. So any
     * update to the contract state after this function would break the check-effect-interaction pattern. Consider
     * overriding {_update} instead.
     */
    function _updateWithAcceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = _msgSender();
            if (ids.length == 1) {
                uint256 id = ids.unsafeMemoryAccess(0);
                uint256 value = values.unsafeMemoryAccess(0);
                _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
            } else {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
            }
        }
    }

    /**
     * @dev Transfers a `value` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     * - `ids` and `values` must have the same length.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the values in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates a `value` amount of tokens of type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev Destroys a `value` amount of tokens of type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     */
    function _burn(address from, uint256 id, uint256 value) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     * - `ids` and `values` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Performs an acceptance check by calling {IERC1155-onERC1155Received} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Performs a batch acceptance check by calling {IERC1155-onERC1155BatchReceived} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Creates an array in memory with only one value for each of the elements provided.
     */
    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.20;

import {IERC1155} from "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the value of tokens of token type `id` owned by `account`.
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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.20;

import {IERC165, ERC165} from "../../../utils/introspection/ERC165.sol";
import {IERC1155Receiver} from "../IERC1155Receiver.sol";

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Arrays.sol)

pragma solidity ^0.8.20;

import {StorageSlot} from "./StorageSlot.sol";
import {Math} from "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

import "./GameLib.sol"; // Import the MatchLibrary
import "./tokens/Token.sol";      // ERC-20 staking and rewards token
import "./tokens/Cards.sol";      // ERC-1155 non-fungible token for cards
import "./Match.sol"; // NFTs to represent each match
import "./managers/FeeAccumulator.sol";

contract Game is Ownable, IERC721Receiver, ERC1155Holder, VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    Cards public cardsContract;
    address public cardsAddress;
    address private tokensAddress;
    address public feeAccumulator; 
    Token public tokenContract;
    IERC20 public gwentToken;
    Match private matchContract;

    // Set parameters for game play
    uint256 public minimumStake = 100 * 10**18;
    uint256 public requiredDeckSize = 22;
    uint256 public maximumProvision = 400;
    uint256 public maximumHeroCards = 1;
    uint256 public feePercentage = 2; // Fee percentage (e.g., 2 for 2%)

    using GameLib for GameLib.Card[];
    using GameLib for GameLib.PlayerGameFactory;

    // Maps player address to their information
    mapping(address => GameLib.PlayerGameFactory) public players;

    // Queue to manage matchmaking
    struct QueueEntry {
        address playerAddress;
        uint256 stakeAmount;
        uint256 timestamp;
    }
    QueueEntry[] public queue;

    // State variable for storing addresses of all Match instances
    address[] public matches;

    // Events declaration
    event PlayersMatched(address player1, address player2, address matchAddress, uint);
    event PlayerQueued(address player, uint256 queueTime);
    event PlayerDequeued(address player);

    event PlayerRegistered(address indexed player, uint256 stake);
    event PlayerDeregistered(address indexed player);
    event DeckUpdated(address indexed player, uint256[] newDeck);
    event PlayerRatingUpdated(address indexed player, uint256 newRating);
    event StakeAmountUpdated(uint256 newAmount);
    event DeckSizeUpdated(uint256 newAmount);
    event MaximumHeroCardsUpdated(uint256 newAmount);
    event MaximumProvisionUpdated(uint256 newAmount);
    event FeeUpdated(uint256 newFeePercentage); // Event for fee updates

    // Event to alert that a new Match instance has been created
    event MatchCreated(address indexed matchInstance, address indexed player1, address indexed player2, uint);

    // Constructor initializes contracts with addresses for tokens and cards
    constructor(
        address _tokenAddress,
        address _cardsAddress,
        address _feeAccumulator
    ) VRFConsumerBase(0x50d47e4142598E3411aA864e08a44284e471AC6f, 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E) Ownable(msg.sender) {
        // Store the Chainlink VRF configuration parameters in your contract's state
        keyHash = keyHash;
        fee = fee;
        // Initialize other variables...
        tokenContract = Token(_tokenAddress);
        cardsContract = Cards(_cardsAddress);
        gwentToken = IERC20(_tokenAddress);
        feeAccumulator = _feeAccumulator;
        tokensAddress = _tokenAddress; 
        cardsAddress = _cardsAddress;
    }

        // Request randomness
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }


    // This function ensures that the contract can safely receive ERC721 NFTs
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
            return IERC721Receiver.onERC721Received.selector;
        }
    
    // Function for players to register and start playing
    function play(GameLib.Card[] memory _deck, uint256 _stakeAmount) public {
        
        require(!isPlayerRegistered(msg.sender), "P1 not reg");
        // Check that the player has chosen one of the two allowed stake amounts
        require(
            _stakeAmount == 100 * 10**18 || _stakeAmount == 1000 * 10**18, 
            "Wrong stake amount"
        );
        require(
            gwentToken.allowance(msg.sender, address(this)) >= _stakeAmount,
            "Token not approved"
        );

        // Ensure the Game contract is approved to manage the player's cards
        require(
            cardsContract.isApprovedForAll(msg.sender, address(this)),
            "Cards not approved"
        );

        GameLib.validateDeck(_deck, cardsAddress, requiredDeckSize, maximumProvision, maximumHeroCards);

        // Create two arrays for batch transfer
        uint256[] memory cardIds = new uint256[](_deck.length);
        uint256[] memory amounts = new uint256[](_deck.length);

        // Populate card IDs and amounts for the deck
        for (uint256 i = 0; i < _deck.length; i++) {
            cardIds[i] = _deck[i].cardId;
            amounts[i] = _deck[i].amount;
        }

        // Transfer the stake from the player to the contract
        require(
            gwentToken.transferFrom(msg.sender, address(this), _stakeAmount),
            "Failed to transfer stake."
        );

        // Transfer the cards to the Game contract
        cardsContract.safeBatchTransferFrom(msg.sender, address(this), cardIds, amounts, "");

        // Register the player and add to the matchmaking queue
        registerPlayer(msg.sender, _deck, _stakeAmount);
        addToQueue(msg.sender, _stakeAmount);

        // Attempt to match players from the queue
        tryMatchPlayers();
    }



function registerPlayer(
        address player,
        GameLib.Card[] memory deck,
        uint256 stakeAmount
    ) internal {
        // Use the struct from GameLib
        GameLib.PlayerGameFactory storage playerRecord = players[player];
        playerRecord.isRegistered = true;
        playerRecord.stakeAmount = stakeAmount;

        // This line should now be correct with the using directive
        playerRecord.initDeckGameFactory(deck); // << No error expected here with the using directive

        // Finally, the PlayerRegistered event is emitted with the player and stakeAmount
        emit PlayerRegistered(player, stakeAmount);
    }

    // Adds player to the matchmaking queue
    function addToQueue(address player, uint256 stakeAmount) internal {
        queue.push(QueueEntry({
            playerAddress: player,
            stakeAmount: stakeAmount,
            timestamp: block.timestamp
        }));
        emit PlayerQueued(player, block.timestamp);
    }

    // Checks if a player has previously registered for matchmaking
    function isPlayerRegistered(address playerAddress) public view returns (bool) {
        return players[playerAddress].isRegistered;
    }

    // Function to calculate fee and remaining stake after deducting the fee
    function calculateFeeAndStakeAfterFee(uint256 totalStake) internal view returns (uint256 feeStake, uint256 stakeAfterFee) {
        feeStake = (totalStake * feePercentage) / 100;
        stakeAfterFee = totalStake - feeStake;
        return (feeStake, stakeAfterFee);
    }

    function getMemoryDeckFromPlayer(GameLib.PlayerGameFactory storage playerData) internal view returns (GameLib.Card[] memory) {
        GameLib.Card[] memory deckMemory = new GameLib.Card[](playerData.deck.length);
        for (uint256 i = 0; i < playerData.deck.length; i++) {
            deckMemory[i] = GameLib.Card({
                cardId: playerData.deck[i].cardId,
                amount: playerData.deck[i].amount,
                effectId: playerData.deck[i].effectId
            });
        }
        return deckMemory;
    }

    // Function to attempt to match players and start the match
    function tryMatchPlayers() internal {
        while (queue.length >= 2) {
            // Assuming the queue is sorted and the first two players are candidates for matching
            address player1 = queue[0].playerAddress;
            address player2 = queue[1].playerAddress;

            if (isPlayerRegistered(player1) && isPlayerRegistered(player2)) {
                GameLib.PlayerGameFactory storage player1Data = players[player1];
                GameLib.PlayerGameFactory storage player2Data = players[player2];

                // Check both players stakes are correct without transferring yet
                require(player1Data.stakeAmount == minimumStake, "P1 stake mismatch");
                require(player2Data.stakeAmount == minimumStake, "P2 stake mismatch");

                // Copy each player's deck from storage to memory
                GameLib.Card[] memory player1Deck = getMemoryDeckFromPlayer(players[player1]);
                GameLib.Card[] memory player2Deck = getMemoryDeckFromPlayer(players[player2]);

                // Create a Match contract with the memory decks
                Match newMatch = new Match(
                        player1, // address of player 1
                        player2, // address of player 2
                        player1Deck, // initial deck of cards for player 1
                        player2Deck, // initial deck of cards for player 2
                        cardsAddress, // address of the Cards contract
                        tokensAddress // address of the Game Token contract
                    );

                address matchAddress = address(newMatch);
                
                uint256 totalStake = player1Data.stakeAmount + player2Data.stakeAmount;
                // Safely calculate fee and remaining stake
                (uint256 feeStake, uint256 stakeAfterFee) = calculateFeeAndStakeAfterFee(totalStake);

                // Transfer the fee to the Fee Accumulator contract
                require(gwentToken.transfer(feeAccumulator, feeStake), "Failed to transfer fee");
                // Transfer the remaining stake to the Match contract
                require(gwentToken.transfer(matchAddress, stakeAfterFee), "Failed to transfer stake to Match");

                // Initialize arrays to store card IDs and amounts for batch transfers
                uint256[] memory cardIdsPlayer1 = new uint256[](player1Data.deck.length);
                uint256[] memory amountsPlayer1 = new uint256[](player1Data.deck.length);

                // Populate the arrays with each player's card data
                for(uint256 i = 0; i < player1Data.deck.length; i++) {
                    cardIdsPlayer1[i] = player1Data.deck[i].cardId;
                    amountsPlayer1[i] = player1Data.deck[i].amount;
                }
                // Transfer player 1's cards to the Match contract
                cardsContract.safeBatchTransferFrom(address(this), matchAddress, cardIdsPlayer1, amountsPlayer1, "");

                // Initialize arrays to store card IDs and amounts for batch transfers
                uint256[] memory cardIdsPlayer2 = new uint256[](player2Data.deck.length);
                uint256[] memory amountsPlayer2 = new uint256[](player2Data.deck.length);
                // Repeat for player 2
                for(uint256 i = 0; i < player2Data.deck.length; i++) {
                    cardIdsPlayer2[i] = player2Data.deck[i].cardId;
                    amountsPlayer2[i] = player2Data.deck[i].amount;
                }
                // Transfer player 2's cards to the Match contract
                cardsContract.safeBatchTransferFrom(address(this), matchAddress, cardIdsPlayer2, amountsPlayer2, "");

                // Emit events
                emit PlayersMatched(player1, player2, matchAddress, matches.length);
                emit MatchCreated(matchAddress, player1, player2, matches.length);

                // Store the Match contract address
                matches.push(matchAddress);
                cleanUpAfterMatchCreated(player1, player2);
            } else {
                // If either player is not registered, remove them from the queue
                if (!isPlayerRegistered(player1)) {
                    removePlayerFromQueue(0);
                }
                if (queue.length > 1 && !isPlayerRegistered(player2)) {
                    removePlayerFromQueue(1);
                }
            }
        }
    }

    // Function to clean up after a match has been created, moving the deletion logic to another function can help
    function cleanUpAfterMatchCreated(address player1, address player2) internal {
        delete players[player1];
        delete players[player2];

        removePlayerFromQueue(0);
        removePlayerFromQueue(0);
    }

    // Allow the owner of the contract to update the minimum stake required for play
    function updateMinimumStake(uint256 _newMinimumStake) public onlyOwner {
        minimumStake = _newMinimumStake;
        //emit StakeAmountUpdated(_newMinimumStake);
    }

/*     function updateMaxProvision(uint256 _newMaxProvision) public onlyOwner {
        maximumProvision = _newMaxProvision;
        //emit MaximumProvisionUpdated(maximumProvision);
    }

    function updateMaxHeroCards(uint256 _newMaxHeroCards) public onlyOwner {
        maximumHeroCards = _newMaxHeroCards;
        //emit MaximumHeroCardsUpdated(maximumHeroCards);
    }
    // Allow the owner of the contract to update the minimum stake required for play
    function updateDeckSize(uint256 _newdeckSize) public onlyOwner {
        requiredDeckSize = _newdeckSize;
        //emit DeckSizeUpdated(requiredDeckSize);
    } */
    // Allow the owner to update the fee
    function updateFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10, "Not more than 10");
        feePercentage = _newFeePercentage;
        //emit FeeUpdated(_newFeePercentage);
    }
    // Allow the owner to update the Fee Accumulator address
    function updateFeeAccumulatorAddress(address _newFeeAccumulator) public onlyOwner {
        feeAccumulator = _newFeeAccumulator;
    }

    // Function to allow a player to cancel registration before being matched
    function cancelRegistration() public {
            GameLib.PlayerGameFactory storage player = players[msg.sender];
            
            // Ensure the player is currently registered
            require(player.isRegistered, "P not registered.");

            // Remove player from the matchmaking queue if present
            for (uint256 i = 0; i < queue.length; i++) {
                if (queue[i].playerAddress == msg.sender) {
                    removePlayerFromQueue(i);
                    break; // Exit loop once the player is found and removed
                }
            }

            // Refund the staked amount to the player
            require(gwentToken.transfer(msg.sender, player.stakeAmount), "Failed to refund stake.");

            // Collect all card IDs and amounts to return
            uint256[] memory cardIds = new uint256[](player.deck.length);
            uint256[] memory amounts = new uint256[](player.deck.length);
            for (uint256 i = 0; i < player.deck.length; i++) {
                cardIds[i] = player.deck[i].cardId;
                amounts[i] = player.deck[i].amount;
            }

            // Return the cards to the player
            cardsContract.safeBatchTransferFrom(address(this), msg.sender, cardIds, amounts, "");

            // Remove player's data
            delete players[msg.sender];

            // Emit deregistration event
            emit PlayerDeregistered(msg.sender);
        }

    // Helper function to remove a player from the matchmaking queue
    function removePlayerFromQueue(uint index) internal {
        queue[index] = queue[queue.length - 1]; // Copy the last player to the slot of the player being removed
        queue.pop(); // Remove the last player as it's now duplicated
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./tokens/Cards.sol";      // ERC-1155 non-fungible token for cards

library GameLib {
    struct Card {
        uint256 cardId;
        uint256 amount;
        uint256 effectId;
    }

    struct Player {
        Card[] deck;
        Card[] hand;
        uint256 handSize;
        bool readyToPlay;
    }

    struct PlayerGameFactory {
        GameLib.Card[] deck; 
        bool isRegistered;
        uint256 stakeAmount;
    }

    enum EffectType { NoHero, DoubleScore, ReverseTurnOrder }

    struct Effects {
        mapping(EffectType => bool) status;
    }


function addCardsToHand(Player storage player, uint256 cardId, uint256 amount, uint256 effectId) internal {
        // Check if the card already exists in the hand; if so, increment the amount
        bool cardExists = false;
        for (uint256 i = 0; i < player.hand.length; i++) {
            if (player.hand[i].cardId == cardId) {
                player.hand[i].amount += amount;
                cardExists = true;
                break;
            }
        }

        // If the card doesn't exist in the hand, add it as a new card
        if (!cardExists) {
            player.hand.push(Card({
                cardId: cardId,
                amount: amount,
                effectId: effectId
            }));
        }
    }


/**
     * @dev Draws a specific number of cards from the player's deck and adds them to the hand.
     * @param player Player struct containing the player's information.
     * @param numberToDraw The number of cards to draw.
     * @param maxHandSize The maximum hand size allowed.
     */
    function drawCards(Player storage player, uint256 numberToDraw, uint256 maxHandSize) internal {
        uint256 drawn = 0;
        while (drawn < numberToDraw && player.handSize < maxHandSize) {
            if (player.deck.length == 0) break; // Exit if there are no more cards in the deck.

            Card storage lastCard = player.deck[player.deck.length - 1];

            // Increment or add the card to the hand
            addCardsToHand(player, lastCard.cardId, 1, lastCard.effectId);

            // Update deck
            if (lastCard.amount == 1) {
                player.deck.pop(); // Remove the last card in the deck if this was the only one
            } else {
                lastCard.amount--; // Decrement the amount of the last card in the deck
            }

            player.handSize++; // Increment hand size
            drawn++;
            // Emitting an event is not possible from library functions. We can return data to do it in the contract.
        }
    }

    /**
     * @dev Searches for a card in the player's hand by card ID and returns it if found.
     * @param player The player struct containing player information.
     * @param cardId The ID of the card to get from the hand.
     * @return The card with the specified ID from the player's hand.
     */
    function getCardFromHand(Player storage player, uint256 cardId) internal view returns (Card memory) {
        for (uint256 i = 0; i < player.hand.length; ++i) {
            if (player.hand[i].cardId == cardId) {
                return player.hand[i];
            }
        }
        revert("Card not found in hand");
    }

    function initDeckGameFactory(PlayerGameFactory storage player, GameLib.Card[] memory deck) internal {
            delete player.deck; // Clear existing deck
            for (uint256 i = 0; i < deck.length; ++i) {
                player.deck.push(deck[i]);
            }
        }

        /**
     * @dev Initializes the player's deck.
     * @param player Reference to the Player struct containing the player's information.
     * @param deck Array of Card structs specifying the initial deck.
     */
    function initDeck(Player storage player, Card[] memory deck) internal {
        // Clear the existing deck if needed
        delete player.deck;
        
        // Add new cards to the player's deck
        for (uint256 i = 0; i < deck.length; i++) {
            player.deck.push(deck[i]);
        }
    }

    function initPlayer(Player storage player, Card[] memory deck, uint256 initialHandSize) internal {
        player.handSize = 0; // Initialize the hand size to zero
        delete player.hand; // Ensure hand is empty before adding new cards

        initDeck(player, deck); // This line should work now; no error should be emitted

        // Draw `initialHandSize` cards from the deck to the hand
        drawCards(player, initialHandSize, initialHandSize);
    }
/**
     * @dev Adds a card to the deck, incrementing its count if it already exists.
     * @param deck Reference to the deck (array of Card).
     * @param cardId The ID of the card to add.
     * @param amount The amount of the specified card to add.
     * @param effectId The effect ID of the specified card.
     */
    function addCardToDeck(Card[] storage deck, uint256 cardId, uint256 amount, uint256 effectId) internal {
        for (uint256 i = 0; i < deck.length; i++) {
            if (deck[i].cardId == cardId) {
                deck[i].amount += amount;
                return;
            }
        }
        deck.push(Card(cardId, amount, effectId));
    }

    /**
     * @dev Determines the winner of a round based on scores.
     * @param player1Score Score of player 1.
     * @param player2Score Score of player 2.
     * @param player1 Address of player 1.
     * @param player2 Address of player 2.
     * @return The address of the round winner, or address(0) if there's a tie.
     */
    function determineRoundWinner(uint256 player1Score, uint256 player2Score, address player1, address player2) internal pure returns (address) {
        if (player1Score > player2Score) {
            return player1;
        } else if (player2Score > player1Score) {
            return player2;
        } else {
            return address(0);
        }
    }
    
/**
 * @dev Removes specified cards from the player's hand and adds them back to the deck.
 * @param player Player struct containing the player's information.
 * @param returnCardsData Array of Card structs specifying the card IDs and amounts to return.
 */
function returnCards(Player storage player, Card[] memory returnCardsData) internal {
    uint256 totalReturned = 0;

    // Remove the cards from the player's hand and add to the deck
    for (uint256 i = 0; i < returnCardsData.length; i++) {
        uint256 cardId = returnCardsData[i].cardId;
        uint256 amountToReturn = returnCardsData[i].amount;
        require(amountToReturn > 0, "Amount to return must be positive");

        removeFromHand(player.hand, cardId, amountToReturn); // Specify amount to return
        addCardToDeck(player.deck, cardId, amountToReturn, returnCardsData[i].effectId);
        totalReturned += amountToReturn;
    }

    // Adjust hand size after returning cards
    player.handSize -= totalReturned; // Ensure it does not go below zero
}

/**
 * @dev Removes specified amount of a card from a player's hand.
 * @param hand The player's hand (array of Card).
 * @param cardId The ID of the card to remove from the hand.
 * @param amount The amount of the card to remove.
 */
function removeFromHand(Card[] storage hand, uint256 cardId, uint256 amount) internal {
    bool cardFound = false;
    for (uint256 i = 0; i < hand.length; i++) {
        if (hand[i].cardId == cardId) {
            require(hand[i].amount >= amount, "Not enough cards to remove");
            hand[i].amount -= amount;
            if (hand[i].amount == 0) {
                hand[i] = hand[hand.length - 1];
                hand.pop();
            }
            cardFound = true;
            break; // Card found and removed, exit the loop
        }
    }
    require(cardFound, "Card not found in hand");
}
    /**
     * @dev Draws up to a certain number of new cards from the deck into the player's hand without exceeding the maximum hand size.
     * @param player The player struct which will be modified.
     * @param maxNewCards The maximum number of new cards that can be drawn.
     * @param maxHandSize The maximum hand size allowed.
     */
    function drawUpToNewHandCards(Player storage player, uint256 maxNewCards, uint256 maxHandSize) internal {
        uint256 cardsToDraw = maxNewCards;
        
        // Adjust the number to draw if it would exceed the hand size limit
        if (player.handSize + maxNewCards > maxHandSize) {
            cardsToDraw = maxHandSize - player.handSize;
        }
        
        // Draw cards from the deck and add them to the hand
        for (uint256 i = 0; i < cardsToDraw; i++) {
            if (player.deck.length == 0) {
                break; // Exit if no more cards in the deck
            }
            
            // Attempt to draw the last card from the deck
            Card storage cardToDraw = player.deck[player.deck.length - 1];
            
            addCardsToHand(player, cardToDraw.cardId, 1, cardToDraw.effectId); // Adds the card to the hand, or increments the amount
            
            // Update the deck size after drawing the card
            if (cardToDraw.amount > 1) {
                cardToDraw.amount--;
            } else {
                player.deck.pop(); // If we took the last copy of this card, remove it from the deck
            }
        }
    }


/**
     * @dev Validates that the given deck (_deck) complies with the game rules.
     * @param _deck Array of Card structures representing the player's deck.
     * @param cardsContractAddress Address of the Cards contract to interface with the card data.
     * @param requiredDeckSize Number of cards required in a valid deck.
     * @param maxProvision Maximum total provision allowed for a valid deck.
     * @param maxHeroCards Maximum number of Hero type cards allowed in a valid deck.
     */
    function validateDeck(
        Card[] memory _deck,
        address cardsContractAddress,
        uint256 requiredDeckSize,
        uint256 maxProvision,
        uint256 maxHeroCards
    ) internal view {
        Cards cardsContract = Cards(cardsContractAddress);
        uint256 totalProvision = 0;
        uint256 heroCount = 0;
        uint256 totalCards = 0;

        // Validate each card in the deck
        for (uint256 i = 0; i < _deck.length; i++) {
            uint256 cardId = _deck[i].cardId;
            uint256 amount = _deck[i].amount;
            totalCards += amount;

            // Ensure that the player owns enough of each card
            require(cardsContract.balanceOf(msg.sender, cardId) >= amount, "Insufficient balance for card in the deck.");

            // Fetch card attributes to determine its type and provision cost
            Cards.CardAttributes memory attrs = cardsContract.getCardAttributes(cardId);

            // Count Hero type cards
            if (attrs.cardType == Cards.CardType.Hero) {
                heroCount += amount;
            }

            // Sum up provision cost
            totalProvision += attrs.provision * amount;
        }

        // Ensure deck size, provision, and hero card limits are respected
        require(totalCards == requiredDeckSize, "Deck must exactly contain the required number of cards");
        require(totalProvision <= maxProvision, "Total provision exceeds the maximum allowed");
        require(heroCount <= maxHeroCards, "Number of Hero cards exceeds the limit allowed");
    }

   function applyEffect(Effects storage effects, EffectType effectType, bool value) internal {
        effects.status[effectType] = value;
    }

    // Make sure this function is available and has the proper visibility (internal)
    function isEffectActive(Effects storage effects, EffectType effectType) internal view returns (bool) {
        return effects.status[effectType];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/Token.sol";      // ERC-20 staking and rewards token

contract FeeAccumulator is Ownable {
    Token public tokenContract;
    IERC20 public gwentToken;
    // Event to be emitted when fees are withdrawn
    event FeesWithdrawn(address indexed tokenAddress, address indexed to, uint256 amount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
            tokenContract = Token(_tokenAddress);
            gwentToken = IERC20(_tokenAddress);
        }
    // Function to receive tokens as fees
    // This can be called by any Game contract or other contract that wants to transfer fees
    function receiveFees(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Fee transfer failed");
    }

    // Function to withdraw accumulated fees to a specific address
    function withdrawFees(address tokenAddress, address to, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(to, amount), "Fee withdrawal failed");
        emit FeesWithdrawn(tokenAddress, to, amount);
    }

    // Optional: Add a function to check the token balance of this contract.
    function balanceOf(address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GameLib.sol"; // Import the MatchLibrary
import "./tokens/Cards.sol"; //Playing Cards
import "./tokens/Token.sol"; //Game Token
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Match is ERC1155Holder {
    using GameLib for GameLib.Card;
    using GameLib for GameLib.Player;
    using GameLib for GameLib.Card[];
    using GameLib for GameLib.Effects;
    using GameLib for GameLib.EffectType;
    
    GameLib.Effects internal effects;
    address private cardsAddress;
    Cards public cardsContract;
    // Constants
    uint8 constant MAX_ROUNDS = 3; // Max number of round
    uint8 constant INITIAL_HAND_SIZE = 12; // 2 cards should be drawn at the start if 1st round
    uint8 constant MAX_HAND_SIZE = 10; // Max number of cards
    uint8 constant CARDS_TO_DRAW_NEW_ROUND = 3;

    // State variables
    address public player1;
    address public player2;
    address public currentTurn;
    uint8 public currentRound;
    uint8 public player1Wins;
    uint8 public player2Wins;
    bool public matchEnded;

    IERC20 public stakeToken;

    mapping(address => GameLib.Player) public players;
    mapping(address => GameLib.Player) public playerInfo;
    mapping(uint8 => mapping(address => uint256)) public roundsCardCount;
    mapping(uint8 => mapping(address => bool)) public hasPassed;
    mapping(uint8 => mapping(address => uint256[])) public roundsPlayedCards;
    mapping(uint8 => uint256) public roundScoresPlayer1;
    mapping(uint8 => uint256) public roundScoresPlayer2;
    mapping(address => GameLib.Card[]) public initialDecks; // Additional state variable to keep track of initial decks
    mapping(uint256 => bool) public activeEffects;    // A mapping to keep track of active effects. For simplicity, let's assume effects are integers that can be toggled on/off
    // Example of an expanded effect management system

    mapping(GameLib.EffectType => bool) public effectStatus;
    mapping(uint256 => GameLib.EffectType) public effectIdToEffectType; // Map effect IDs to `EffectType`

    // Events
    event CardDrawn(address indexed player, uint256 cardId);
    event RoundStarted(uint8 round, address player1, address player2);
    event CardPlayed(address indexed player, uint8 indexed round, uint256 cardId);
    event PlayerPasses(address indexed player, uint8 indexed round);
    event RoundEnded(uint8 round, address winner);
    event MatchEnded(address winner);
    event DebuggetStrength(uint256 cardId, uint256 rank);
    // Constructor
    constructor(
        address _player1,
        address _player2,
        GameLib.Card[] memory _player1Deck,
        GameLib.Card[] memory _player2Deck,
        address _cardsAddress,
        address _stakeTokenAddress
    ) {
        player1 = _player1;
        player2 = _player2;
        currentTurn = _player1; // Player1 starts the game
        currentRound = 1;
        matchEnded = false;
        cardsContract = Cards(_cardsAddress);
        stakeToken = IERC20(_stakeTokenAddress);
        // Initialize players

        // Update to track initial decks
        storeInitialDeck(player1, _player1Deck);
        storeInitialDeck(player2, _player2Deck);

        // Store initial decks
        for (uint256 i = 0; i < _player1Deck.length; i++) {
            GameLib.Card memory card = _player1Deck[i];
            playerInfo[_player1].deck.push(card);
        }

        for (uint256 i = 0; i < _player2Deck.length; i++) {
            GameLib.Card memory card = _player2Deck[i];
            playerInfo[_player2].deck.push(card);
        }

        // Actual initialization of players
        GameLib.Player storage player1Record = playerInfo[_player1];
        GameLib.Player storage player2Record = playerInfo[_player2];
        player1Record.initPlayer(_player1Deck, INITIAL_HAND_SIZE);
        player2Record.initPlayer(_player2Deck, INITIAL_HAND_SIZE);
    }

    /**
     * @dev Stores the initial deck provided to a player.
     * @param player The address of the player.
     * @param deck The array of cards representing the player's initial deck.
     */
    function storeInitialDeck(address player, GameLib.Card[] memory deck) private {
        // Ensure initial deck array for player is clear
        delete initialDecks[player];
        
        // Copy cards from the provided deck to the player's initial deck record
        for (uint256 i = 0; i < deck.length; i++) {
            initialDecks[player].push(deck[i]);
        }
    }

    function isEffectActive(GameLib.EffectType effectType) public view returns (bool) {
        // Correct usage of the library function by passing the 'effects' struct as an argument
        return GameLib.isEffectActive(effects, effectType);
    }

    function returnCards(GameLib.Card[] calldata returnCardsData) public {
        require(currentRound == 1, "Not 1st round");
        GameLib.Player storage playerRecord = playerInfo[msg.sender];
        require(!playerRecord.readyToPlay, "Already returned");

        // Delegate the card returning logic to GameLib
        playerRecord.returnCards(returnCardsData);

        // Mark the player as ready to play
        playerRecord.readyToPlay = true;

        // Check if both players are ready to start the round
        if (playerInfo[player1].readyToPlay && playerInfo[player2].readyToPlay) {
            startRound();
        }
    }

    /**
     * @dev Starts the round if both players are ready.
     */
    function startRound() private {
        require(playerInfo[player1].readyToPlay && playerInfo[player2].readyToPlay, "Players are not ready");
        emit RoundStarted(currentRound, player1, player2);
        currentTurn = player1;  // Player 1 makes the first move
    }

    function drawCards(address player, uint256 numberToDraw) public {
        // Delegate the card drawing logic to GameLib
        GameLib.Player storage playerRecord = playerInfo[player];
        playerRecord.drawCards(numberToDraw, MAX_HAND_SIZE);
    }


    /**
     * @dev Retrieves a card from a player's hand.
     * @param playerAddress The address of the player.
     * @param cardId The ID of the card to retrieve.
     * @return card The card retrieved from the player's hand.
     */
    function getCardFromHand(address playerAddress, uint256 cardId) internal view returns (GameLib.Card memory card) {
        return playerInfo[playerAddress].getCardFromHand(cardId);
    }

function playCard(uint256 cardId) external onlyCurrentPlayer canPlay {
    require(!matchEnded, "Match ended");
    GameLib.Card memory playedCard = playerInfo[msg.sender].getCardFromHand(cardId);

    // Assuming effectIdToEffectType exists and maps card's effectId to EffectType
    GameLib.EffectType effectType = effectIdToEffectType[playedCard.effectId];
    
    // Check if this effect is forbidden before applying
    //require(!GameLib.isEffectActive(effects, effectType), "This effect is currently forbidden");
    
    // Apply the effect using GameLib
    GameLib.applyEffect(effects, effectType, true);

    executeCardPlay(playedCard);
    
    emit CardPlayed(msg.sender, currentRound, cardId);
    updateScores();
    endTurnOrPass();
}

    function executeCardPlay(GameLib.Card memory card) internal {
        GameLib.Player storage player = playerInfo[msg.sender];

        // Call removeFromHand on the hand array and decrement player's handSize
        player.hand.removeFromHand(card.cardId, 1); // Assume we always play one card
        player.handSize--; // Decrement player's handSize as one card is played

        // Logic to execute playing a card, such as keeping track of played cards
        roundsPlayedCards[currentRound][msg.sender].push(card.cardId);
        roundsCardCount[currentRound][msg.sender]++;
    }

    /**
     * @dev Updates the scores for the current round after a card is played.
     */
    function updateScores() internal view {
        uint256 currentScorePlayer1;
        uint256 currentScorePlayer2;

        // Iterates over played cards in the current round for both players and sums their ranks
        for (uint256 i = 0; i < roundsPlayedCards[currentRound][player1].length; i++) {
            currentScorePlayer1 += cardsContract.getStrength(roundsPlayedCards[currentRound][player1][i]);
        }
        for (uint256 i = 0; i < roundsPlayedCards[currentRound][player2].length; i++) {
            currentScorePlayer2 += cardsContract.getStrength(roundsPlayedCards[currentRound][player2][i]);
        }
    }

    /**
     * @dev Allows a player to pass their turn if he played at least 1 card in current round, updating the round's scores and handling the turn transition.
     */
    function pass() external onlyCurrentPlayer canPlay {
            require(roundsCardCount[currentRound][msg.sender] > 0 && !matchEnded, "Play at least one card");
            hasPassed[currentRound][msg.sender] = true;
            emit PlayerPasses(msg.sender, currentRound);
            updateScores();
            endTurnOrPass();
        }

    /**
     * @dev Retrieves the scores for both players for a specified round.
     * @param round The round number to retrieve scores for.
     * @return player1Score The score of player1 for the round.
     * @return player2Score The score of player2 for the round.
     */
    function getScores(uint8 round) external view returns (uint256 player1Score, uint256 player2Score) {
        require(round > 0 && round <= currentRound, "Invalid round");

        player1Score = 0; // Default score is 0
        player2Score = 0; // Default score is 0

        // Calculate score for player 1 if they have played cards this round
        for (uint256 i = 0; i < roundsPlayedCards[round][player1].length; i++) {
            player1Score += cardsContract.getStrength(roundsPlayedCards[round][player1][i]);
        }

        // Calculate score for player 2 if they have played cards this round
        for (uint256 i = 0; i < roundsPlayedCards[round][player2].length; i++) {
            player2Score += cardsContract.getStrength(roundsPlayedCards[round][player2][i]);
        }

        return (player1Score, player2Score);
    }



// Update endRound to use startNextRound
function endRound() internal {
    (uint256 player1Score, uint256 player2Score) = getRoundScores(currentRound);

    address loser = player1Score < player2Score ? player1 : player2; 
    // Increment wins
    updateWins(player1Score, player2Score);

    if (shouldEndMatch() || currentRound >= MAX_ROUNDS) {
        endMatch(); // End the match if a player has won enough rounds or it is the last round
    } else {
        // Move on to the next round if the match is not over
        currentRound++;
        startNextRound(loser); // The winner of this round starts next round
    }
}

// Update startNextRound to determine the next player based on who won
function startNextRound(address loser) internal {
    drawNewHandCards(); // Draw new hand cards for the next round
    currentTurn = loser; // Set the winner of the last round as the one to start
    emit RoundStarted(currentRound, player1, player2);
}

    /**
     * @dev Updates the win count for each player after a round ends based on the scores.
     * @param player1Score The final score of player1 for the round.
     * @param player2Score The final score of player2 for the round.
     */
    function updateWins(uint256 player1Score, uint256 player2Score) private {
        if (player1Score > player2Score) {
            player1Wins++;
        } else if (player2Score > player1Score) {
            player2Wins++;
        }
        // In case of a tie, don't increment anyone's win count
    }

    /**
     * @dev Handles the end of a turn by setting the next player.
     */
    function endTurnOrPass() internal {
            if (hasPassed[currentRound][nextPlayer()]) {
                // If both players have passed, the round ends
                if (hasPassed[currentRound][msg.sender]) {
                    endRound();
                }
            } else {
                // If only the current player has passed, end the turn
                endTurn();
            }
        }

    /**
     * @dev Ends the current player's turn.
     */
    function endTurn() internal {
        currentTurn = nextPlayer();
    }

    /**
     * @dev Determines the scores for a given round.
     * @param round The round to retrieve scores for.
     * @return player1Score Player1's score for the specified round.
     * @return player2Score Player2's score for the specified round.
     */
    function getRoundScores(uint8 round) internal view returns (uint256 player1Score, uint256 player2Score) {
            // Calculate score for Player 1 by summing the ranks of cards played in the current round
            for (uint256 i = 0; i < roundsPlayedCards[round][player1].length; i++) {
                player1Score += cardsContract.getStrength(roundsPlayedCards[round][player1][i]);
            }

            // Calculate score for Player 2 by summing the ranks of cards played in the current round
            for (uint256 i = 0; i < roundsPlayedCards[round][player2].length; i++) {
                player2Score += cardsContract.getStrength(roundsPlayedCards[round][player2][i]);
            }

            return (player1Score, player2Score);
    }


/**
 * @dev Determines the winner of a round based on scores.
 * @param player1Score Score of player1.
 * @param player2Score Score of player2.
 */
function determineRoundWinner(uint256 player1Score, uint256 player2Score) internal returns (address roundWinner) {
    roundWinner = GameLib.determineRoundWinner(player1Score, player2Score, player1, player2);
    if (roundWinner == player1) {
        emit RoundEnded(currentRound, player1);
    } else if (roundWinner == player2) {
        emit RoundEnded(currentRound, player2);
    } else {
        emit RoundEnded(currentRound, address(0)); // Tie
    }
}

    /**
     * @dev Checks if the match should end based on the number of rounds won by each player.
     * @return true if the match should end, otherwise false.
     */
    function shouldEndMatch() internal view returns (bool) {
        return player1Wins >= 2 || player2Wins >= 2;
    }

    /**
     * @dev Ends the match and determines the overall winner.
     */
    function endMatch() internal {
        matchEnded = true;
        address winner = player1Wins > player2Wins ? player1 : player2;
        
        // Transfer the stake to the winner
        uint256 stake = stakeToken.balanceOf(address(this));
        require(stakeToken.transfer(winner, stake), "Stake transfer failed");

        // Return all remaining cards in the deck and hand to the appropriate players
        returnAllCards();

        // Emit the event signaling that the match has ended
        emit MatchEnded(winner);
    }

    /**
     * @dev Returns all cards from both players' decks and hands at the end of the match.
     */
    function returnAllCards() internal {
        _returnCardsToPlayer(player1);
        _returnCardsToPlayer(player2);
    }

    /**
     * @dev Returns a player's initial deck back to them at the end of the match.
     * @param player The address of the player whose cards are being returned.
     */
    function _returnCardsToPlayer(address player) private {
        // Retrieve the initial deck for the player
        GameLib.Card[] storage initialDeck = initialDecks[player];

        // Arrays to keep track of card IDs and amounts
        uint256[] memory cardIds = new uint256[](initialDeck.length);
        uint256[] memory amounts = new uint256[](initialDeck.length);

        // Fill the arrays with the initial cards and amounts
        for (uint256 i = 0; i < initialDeck.length; i++) {
            cardIds[i] = initialDeck[i].cardId;
            amounts[i] = initialDeck[i].amount;
        }

        // Execute the batch transfer, if any cards are in the deck
        if (initialDeck.length > 0) {
            // The cardsContract must implement ERC1155 and safeBatchTransferFrom correctly.
            cardsContract.safeBatchTransferFrom(address(this), player, cardIds, amounts, "");
        }

        // Once cards are returned, clear the initial deck of the player
        delete initialDecks[player];
    }

    /**
     * @dev Draws new hand cards for both players at the beginning of a new round.
     */
    function drawNewHandCards() internal {
        address[2] memory playersArray = [player1, player2];

        for (uint256 i = 0; i < playersArray.length; i++) {
            // Use the drawUpToNewHandCards function to draw up to new cards without exceeding MAX_HAND_SIZE
            playerInfo[playersArray[i]].drawUpToNewHandCards(CARDS_TO_DRAW_NEW_ROUND, MAX_HAND_SIZE);
        }
    }


    /**
     * @dev Determines the next player to take their turn.
     * @return The address of the next player.
     */
    function nextPlayer() internal view returns (address) {
        return currentTurn == player1 ? player2 : player1;
    }

    /**
     * @dev Checks if a specific card is currently in a player's hand and has at least one copy.
     * @param player Address of the player.
     * @param cardId ID of the card to check.
     * @return true if the card is in the player's hand with a non-zero amount, otherwise false.
     */
    function cardInHand(address player, uint256 cardId) internal view returns (bool) {
        GameLib.Card[] storage hand = playerInfo[player].hand;
        for (uint256 i = 0; i < hand.length; i++) {
            if (hand[i].cardId == cardId && hand[i].amount > 0) {
                return true;
            }
        }
        return false;
    }
 


    /**
     * @dev Retrieves all cards played by a specific player in the current round.
     * @param player The address of the player.
     * @return playedCards An array of card IDs that the player has played in the current round.
     */
    function getPlayedCardsCurrentRound(address player) public view returns (uint256[] memory playedCards) {
        return roundsPlayedCards[currentRound][player];
    }

    /**
     * @dev Returns the initial deck of a specific player.
     * @param player Address of the player.
     * @return cards An array of Card structs representing the initial deck of the player.
     */
    function getInitialDecks(address player) public view returns (GameLib.Card[] memory cards) {
        return initialDecks[player];
    }

    /**
     * @dev Returns the player information including their current deck and hand.
     * @param playerAddress The address of the player.
     * @return playerData A GameLib.Player struct containing the player's deck, hand, hand size, and other relevant info.
     */
    function getPlayer(address playerAddress) public view returns (GameLib.Player memory playerData) {
        GameLib.Player storage playerInfoData = playerInfo[playerAddress];

        return playerInfoData;
    }

    /**
     * @dev Decrements the amount of a specific card in a player's deck.
     * @param player Address of the player.
     * @param cardId ID of the card to decrement.
     */
    function decrementCardAmount(address player, uint256 cardId) internal {
        for (uint i = 0; i < playerInfo[player].deck.length; i++) {
            if (playerInfo[player].deck[i].cardId == cardId && playerInfo[player].deck[i].amount > 0) {
                playerInfo[player].deck[i].amount--;
                return;
            }
        }
        revert("Can't play card");
    }

    /**
     * @dev Checks if a specific card is available to be played by a player.
     * @param player Address of the player.
     * @param cardId ID of the card to check.
     * @return true if the card is available to be played, otherwise false.
     */
    function cardAvailable(address player, uint256 cardId) internal view returns (bool) {
        for (uint256 i = 0; i < playerInfo[player].deck.length; i++) {
            if (playerInfo[player].deck[i].cardId == cardId && playerInfo[player].deck[i].amount > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Ensures that actions are only taken by the current player whose turn it is.
     */
    modifier onlyCurrentPlayer() {
        require(msg.sender == currentTurn, "Not your turn");
        _;
    }
    /**
     * @dev Ensures that players have draw their 2 cards at beginning of 1st round.
     */
    modifier canPlay() {
        require(playerInfo[player1].readyToPlay && playerInfo[player2].readyToPlay, "Players must draw cards");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cards is ERC1155, Ownable {
    string public name = "Test Cards";
    enum CardType { Normal, Hero, Special } // Enum for card types

    struct CardAttributes {
        uint256 health;
        uint256 strength;
        uint256 provision;
        CardType cardType;    // Using enum directly
        uint256 effectId;
        string effect;
        string ipfsHash;      // IPFS hash for the metadata
    }

    uint256 public nextCardId = 1;
    mapping(uint256 => CardAttributes) public cardAttributesMap;

    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {}

    // mint function now accepts CardType enum directly
    function mint(
        address account,
        uint256 amount,
        uint256 health,
        uint256 strength,
        uint256 provision,
        CardType cardType,  // Use of CardType enum directly
        uint256 effectId,
        string memory effect,
        string memory ipfsHash
    ) public onlyOwner returns (uint256) {
        cardAttributesMap[nextCardId] = CardAttributes({
            health: health,
            strength: strength,
            provision: provision,
            cardType: cardType,   // Direct assignment
            effectId: effectId,
            effect: effect,
            ipfsHash: ipfsHash
        });

        _mint(account, nextCardId, amount, "");
        return nextCardId++;
    }

    // Getter for all attributes
    function getCardAttributes(uint256 tokenId) public view returns (CardAttributes memory) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId];
    }

    // Private helper function to determine if a card has been minted
    function _exists(uint256 tokenId) private view returns (bool) {
        // Here we are checking for the length of the IPFS hash, which should be non-empty if the card is minted
        return bytes(cardAttributesMap[tokenId].ipfsHash).length > 0;
    }

    // Getters for individual attributes
    function getHealth(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].health;
    }

    function getStrength(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].strength;
    }

    function getProvision(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].provision;
    }

    // Getter for card type
    function getCardType(uint256 tokenId) public view returns (CardType) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].cardType;
    }

    // Public function to return the string representation of the CardType
    function getCardTypeString(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Card not minted");
        CardType cardType = cardAttributesMap[tokenId].cardType;
        
        // Convert the enum to a string
        if (cardType == CardType.Normal) {
            return "Normal";
        } else if (cardType == CardType.Hero) {
            return "Hero";
        } else if (cardType == CardType.Special) {
            return "Special";
        } else {
            revert("Unknown card type");
        }
    }

    function getEffectId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].effectId;
    }

    function getEffect(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].effect;
    }

    function getIpfsHash(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Card not minted");
        return cardAttributesMap[tokenId].ipfsHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Token is an ERC-20 token that will be used for staking and in-game rewards.
contract Token is ERC20 {
    // The admin address that is allowed to mint new tokens (likely the game contract or deployer)
    address private _admin;

    // Modifier to check if the message sender is the admin
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Token: caller is not the admin");
        _;
    }

    // Constructor that sets up the ERC-20 token with its name and symbol.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _admin = msg.sender;
    }

    // Function to mint new tokens; only callable by the admin.
    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }

    // Function to burn tokens from a holder; only callable by the admin.
    function burn(address from, uint256 amount) public onlyAdmin {
        _burn(from, amount);
    }

    // Optional: You could also override `transfer` and `transferFrom` to add custom game-related logic.
}