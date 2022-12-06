// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender)
    external
    view
    returns (uint256 remaining);

  function approve(address spender, uint256 value)
    external
    returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue)
    external
    returns (bool success);

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

pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
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
  function _fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant _USER_SEED_PLACEHOLDER = 0;

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
  function _requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal
    returns (bytes32 requestId)
  {
    _link.transferAndCall(
      _vrfCoordinator,
      _fee,
      abi.encode(_keyHash, _USER_SEED_PLACEHOLDER)
    );
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = _makeVRFInputSeed(
      _keyHash,
      _USER_SEED_PLACEHOLDER,
      address(this),
      _nonces[_keyHash]
    );
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    _nonces[_keyHash] += 1;
    return _makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable _link;
  address private immutable _vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private _nonces;

  /**
   * @param vrfCoordinator_ address of VRFCoordinator contract
   * @param link_ address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address vrfCoordinator_, address link_) {
    _vrfCoordinator = vrfCoordinator_;
    _link = LinkTokenInterface(link_);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
    external
  {
    require(msg.sender == _vrfCoordinator, "Only VRFCoordinator can fulfill");
    _fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: AGPL-3.0

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
  function _makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return
      uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
  function _makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

pragma solidity ^0.8.0;

import "../chainlink/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract BoosterValidator is VRFConsumerBase, Ownable, IMintValidator {
  struct Drop {
    uint256[] odds;
    uint256[] ids;
    address paymentToken;
    uint256 packCost;
    uint64 startTime;
    uint64 endTime;
    // do we want a start block?
    uint64 endBlock;
  }

  struct Request {
    uint256 dropID;
    uint256 quantity;
    address recipient;
  }

  bytes32 internal _keyHash;
  uint256 internal _fee;
  mapping(bytes32 => Request) public requests;
  mapping(uint256 => bool) public usedIds;
  mapping(uint256 => Drop) public drops;
  uint256 public dropCount;
  // initialize with token and track state there
  //mapping(uint256 => bool) public claimed;

  IFabricator public core;

  event RequestId(bytes32 requestId);

  /**
   * Constructor inherits VRFConsumerBase
   *
   * Network: Kovan
   * Chainlink VRF Coordinator address:  0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
   * LINK token address:                 0xa36085F69e2889c224210F603D836748e7dC0088
   * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
   */
  constructor(
    IFabricator _core,
    address coordinator,
    address link
  )
    VRFConsumerBase(
      coordinator, // VRF Coordinator
      link // LINK Token
    )
  {
    _keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    _fee = 0; //0.1 * 10**18; // 0.1 LINK (Varies by network)
    core = _core;
  }

  /**
   * Requests randomness from a user-provided seed
   */
  function getRandomNumber() public returns (bytes32 requestId) {
    require(_link.balanceOf(address(this)) >= _fee, "BOOST_LINK_BALLANCE_LOW");
    return _requestRandomness(_keyHash, _fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function _fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    Drop memory drop = drops[requests[requestId].dropID];
    uint256[] memory odds = drop.odds;
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    uint256 totalOdds;
    uint256 currentChance = odds[0];
    for (uint256 i = 0; i < odds.length; i++) {
      totalOdds += odds[i];
    }
    uint256 randomResult = randomness % totalOdds;
    uint256 j = 0;
    for (j; currentChance < randomResult; j++) {
      currentChance += odds[j];
    }
    idReturn[0] = drop.ids[j];
    quantityReturn[0] = requests[requestId].quantity;
    core.modularMintCallback(
      requests[requestId].recipient,
      idReturn,
      quantityReturn,
      ""
    );
  }

  // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract

  function validate(
    address recipient,
    uint256 _dropID, /* _dropId*/
    uint256[] memory _requestedAmounts, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    Drop memory drop = drops[_dropID];
    // 0. validate that blocknumber or timestamp have not passed
    require(block.timestamp > drop.startTime, "BOOST_DROP_TIME_EARLY");
    require(block.timestamp <= drop.endTime, "BOOST_DROP_TIME_EXPIRED_Poop");
    require(block.number <= drop.endBlock, "BOOST_DROP_BLOCK_PASSED");
    // 2. validate that the indicated quantity is available
    require(_requestedAmounts.length == 1, "BOOST_DROP_REQUEST_AMOUNTS_LENGTH");
    bytes32 requestId = getRandomNumber();
    requests[requestId] = Request(_dropID, _requestedAmounts[0], recipient);
    emit RequestId(requestId);
  }

  function createDrop(
    uint256[] memory _collectibleIds,
    uint256[] memory _odds,
    address _paymentToken,
    uint256 _packCost,
    uint64 _startTime,
    uint64 _endTime,
    uint16 _endBlock
  ) external onlyOwner {
    /*
   1. ?split startId in type and index
   2.
   */
    for (uint256 i; i < _collectibleIds.length; i++) {
      require(!usedIds[_collectibleIds[i]], "BOOST_DROP_DUPLICATE_DROP");
      usedIds[_collectibleIds[i]] = true;
    }
    drops[dropCount] = Drop(
      _odds,
      _collectibleIds,
      _paymentToken,
      _packCost,
      _startTime,
      _endTime,
      _endBlock
    );
    dropCount += 1;
    // Log a drop created event with some tangible identifiers to latch onto
  }

  function getDropIds(uint256 drop) external view returns (uint256[] memory) {
    return drops[drop].ids;
  }

  function getDropOdds(uint256 drop) external view returns (uint256[] memory) {
    return drops[drop].odds;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

interface IMintValidator {
  function validate(
    address _recipient,
    uint256 _dropId,
    uint256[] memory _requestedQty,
    string calldata _metadata,
    bytes memory _data
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "./IMintValidator.sol";

interface IFabricator {
  function modularMintInit(
    uint256 _dropId,
    address _to,
    uint256[] memory _requestedAmounts,
    bytes memory _data,
    IMintValidator _validator,
    string calldata _metadata
  ) external;

  function modularMintCallback(
    address recipient,
    uint256[] memory _ids,
    uint256[] memory _requestedAmounts,
    bytes memory _data
  ) external;

  function quantityMinted(uint256 collectibleId) external returns (uint256);

  function idToValidator(uint256 collectibleId) external returns (address);
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "../interfaces/IFabricator.sol";

contract SignatureValidator is Auth {
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  struct Target {
    uint256 chainId;
    uint256 tokenId;
    address wallet;
    uint256 amount;
  }
  IFabricator public core;

  event SignerSet(address newSigner);

  using ECDSA for bytes32;

  bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  bytes32 private constant _TARGET_TYPEHASH =
    keccak256(
      "Target(uint256 chainId,uint256 cycle,address wallet,uint256 amount)"
    );

  bytes32 private immutable _domainSeparator;

  address public validationSigner;

  constructor(
    address signer,
    IFabricator _core,
    Authority authority
  ) Auth(msg.sender, authority) {
    validationSigner = signer;
    core = _core;
    _domainSeparator = _hashDomain(
      EIP712Domain({
        name: "SYNTH Validator",
        version: "1",
        chainId: _getChainID(),
        verifyingContract: address(this)
      })
    );
  }

  function _hashDomain(EIP712Domain memory eip712Domain)
    private
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          _EIP712_DOMAIN_TYPEHASH,
          keccak256(bytes(eip712Domain.name)),
          keccak256(bytes(eip712Domain.version)),
          eip712Domain.chainId,
          eip712Domain.verifyingContract
        )
      );
  }

  function _hashRecipient(Target memory recipient)
    private
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          _TARGET_TYPEHASH,
          recipient.chainId,
          recipient.tokenId,
          recipient.wallet,
          recipient.amount
        )
      );
  }

  function _hash(Target memory recipient) private view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          _domainSeparator,
          _hashRecipient(recipient)
        )
      );
  }

  function _getChainID() private view returns (uint256) {
    uint256 id;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      id := chainid()
    }
    return id;
  }

  function setSigner(address signer) external requiresAuth {
    validationSigner = signer;
    emit SignerSet(signer);
  }

  function claim(
    Target calldata recipient,
    uint8 v,
    bytes32 r,
    bytes32 s // bytes calldata signature
  ) external {
    address signatureSigner = _hash(recipient).recover(v, r, s);
    require(signatureSigner == validationSigner, "Invalid Signature");
    require(recipient.chainId == _getChainID(), "Invalid chainId");
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    // 3. Call Callback Mint Function
    idReturn[0] = recipient.tokenId;
    quantityReturn[0] = recipient.amount;
    core.modularMintCallback(recipient.wallet, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ICharacter.sol";
import "../interfaces/IWearables.sol";
import "../interfaces/ICore1155.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "../lib/LegacyPills.sol";

// Note: try to minimize the contract depth that mutative actions have to take
contract WearablesValidator is Context, Auth, IWearables {
  ICore1155 public core;
  ICharacter public character;
  mapping(uint256 => bool) public wearableExists;
  uint8 public slotCount;
  mapping(uint256 => string) public cid;
  mapping(string => uint32) public id;
  mapping(uint256 => string[]) public legacyPill;
  mapping(string => Wearable) public wearables;
  mapping(uint256 => bool) public isEgodeth;

  struct Wearable {
    uint16 slot;
    uint8 form;
    uint8 rarity;
  }

  // Change to initialize call
  constructor(
    ICharacter _character,
    ICore1155 _core,
    Authority auth
  ) Auth(msg.sender, auth) {
    core = _core;
    character = _character;
  }

  function equipSkeleton(uint256 id, uint16 slotID) external {
    require(uint16(id) == slotID, "This doesn't fit in this slot");
    character.equipSkeleton(slotID, id, msg.sender);
  }

  function unequipSkeleton(uint8 slotID) external {
    character.unequipSkeleton(slotID, msg.sender);
  }

  function addWearable(
    uint16 slot,
    uint8 form,
    uint8 rarity,
    string calldata _cid
  ) external requiresAuth {
    wearableExists[convertToWearableUUID(slot, form, rarity)] = true;
    wearables[_cid] =  Wearable(slot, form, rarity);
  }

  function getSlot(string calldata _cid) external view returns (uint16 slot) {
    slot = wearables[_cid].slot;
  }

  function removeWearable(
    uint16 slot,
    uint8 form,
    uint8 rarity
  ) external requiresAuth {
    wearableExists[convertToWearableUUID(slot, form, rarity)] = false;
  }

  function setIdtoStringPill(uint256 pillId, uint256 form, string calldata _cid) external {
    uint256 subType = LegacyPills.getSubTypeFromId(pillId);
    uint256 pillType = LegacyPills.getTypeFromId(pillId);
    uint256 egoDethShift = isEgodeth[subType] ? 1 : 0;
    if(pillType == 1 && egoDethShift == 1) {
      pillType = LegacyPills.getRootIdFromId(pillId);
    }
    legacyPill[pillType + (256 * (form+1)) + (1024 * (egoDethShift+1))].push(_cid);
  }

  function removeIdfromStringPill(uint256 pillId, uint256 form, uint256 index) external {
    uint256 subType = LegacyPills.getSubTypeFromId(pillId);
    uint256 pillType = LegacyPills.getTypeFromId(pillId);
    uint256 egoDethShift = isEgodeth[subType] ? 1 : 0;
    if(pillType == 1 && egoDethShift == 1) {
      pillType = LegacyPills.getRootIdFromId(pillId);
    }
    string[] storage arr = legacyPill[pillType + (256 * (form+1)) + (1024 * (egoDethShift+1))];
    arr[index] = arr[arr.length - 1];
    arr.pop();
  }

  function getEquipmentFromPill(uint256 pillId, uint256 form) public view returns (string[] memory) {
    uint256 subType = LegacyPills.getSubTypeFromId(pillId);
    uint256 pillType = LegacyPills.getTypeFromId(pillId);
    uint256 egoDethShift = isEgodeth[subType] ? 1 : 0;
    if(pillType == 1 && egoDethShift == 1) {
      pillType = LegacyPills.getRootIdFromId(pillId);
    }
    return legacyPill[pillType + (256 * (form+1)) + (1024 * (egoDethShift+1))];
  }

  function setEgodeth(uint256 subType, bool isEgo) external {
    isEgodeth[subType] = isEgo;
  }

  // Unclear if slot should be at the top, or the bottom of this config?
  function convertToWearableUUID(
    uint16 slot,
    uint8 form,
    uint8 rarity
  ) public pure returns (uint256 id) {
    //solhint-disable-next-line
    assembly {
      // Bitshift and Pack series, rarity, and slot into ID -- [series][rarity][slot]
      id := add(add(slot, mul(rarity, 0x100)), mul(form, 0x10000))
    }
  }

  function setCID(uint32 _id, string calldata _cid) external {
    cid[_id] = _cid;
    id[_cid] = _id;
  }

  function uri(uint32 _id) external view returns (string memory) {
    return core.uri(_id);
  }

  function mintEquipment(address target, uint256 item) external {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = item;
    quantityReturn[0] = 1;
    core.modularMintCallback(target, idReturn, quantityReturn, "");
  } 

}

// SPDX-License-Identifier: AGPL-3.0


import "../lib/CharacterLibrary.sol";

interface ICharacter {
  function equipSkeleton(
    uint16 slotID,
    uint256 id,
    address _player
  ) external;

  function equipOutfit(
    uint32 id,
    uint16 slotID,
    address _player
  ) external;

  function unequipSkeleton(uint16 slotID, address _player) external;

  function unequipOutfit(uint16 slotID, address _player) external;

  function addPlayer(
    uint256 _id,
    address _player,
    uint256[] calldata legacyPills,
    uint256[] calldata collabPills,
    string[] calldata traitsPlus
  ) external;

  function removePlayer(uint256 _id, address _player) external;

  function getSkeleton(uint256 tokenID) external view returns (Skeleton memory);

  function getOutfit(uint256 tokenID) external view returns (Outfit memory);

  function getCharacter(uint256 tokenID)
    external
    view
    returns (Character memory);

  function setSkeleton(uint256 tokenID, Skeleton calldata skeleton) external;

  function setOutfit(uint256 tokenID, Outfit calldata outfit) external;
  function setOutfitSlot(
    uint256 _characterID,
    uint16 slotID,
    uint32 value) external;
}

// Dev Note: collapse these down into composable interfaces?
interface IWearables {

  function id(string calldata cid) external returns(uint32);
  
  function getSlot(string calldata _cid) external returns(uint16);

  function getEquipmentFromPill(uint256 pillId, uint256 form) external view returns (string[] memory);
  
  function mintEquipment(address target, uint256 item) external;

}

// write interface for
//Interface
interface ICore1155 {

  function uri(uint256 id) external view returns (string memory);

  function modularMintCallback(
    address recipient,
    uint256[] calldata _ids,
    uint256[] calldata _requestedAmounts,
    bytes calldata _data
  ) external;
  function modularMintCallbackSingle(
    address recipient,
    uint256 _id,
    bytes calldata _data
  ) external;
}

library LegacyPills {
  uint256 constant _NF_BIT_MASK =
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint256 constant _TYPE_BIT_MASK =
    0x7fffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant _SUB_TYPE_BIT_MASK =
    0x00000000000000000000000000000000ffffffffffffffff0000000000000000;
  uint256 constant _ROOT_ID_BIT_MASK =
    0x000000000000000000000000000000000000000000000000ffffffffffffffff;

  function getTypeFromId(uint256 id) public pure returns (uint256) {
    return (id & _TYPE_BIT_MASK) >> 128;
  }

  function getSubTypeFromId(uint256 id) public pure returns (uint256) {
    return (id & _SUB_TYPE_BIT_MASK) >> 64;
  }

  function getRootIdFromId(uint256 id) public pure returns (uint256) {
    return (id & _ROOT_ID_BIT_MASK);
  }

  function removeNFBit(uint256 id) public pure returns (uint256) {
    return id & _NF_BIT_MASK;
  }
}

// Player Information
struct Player {
  uint256 id;
}
// Character Information
// TODO: Confirm optimal struct ordering
struct Character {
  uint256 characterId;
  address player;
  uint256 class;
  string description;
  string name;
  string form;
  string origin;
  string upbringing;
  string gift;
  string faction;
  uint256[] legacyPills;
  uint256[] collabPills;
}


// Note: We probably wantt o abstract out/push out the character logic from the validator logic and just have the single validator reach into the other state holding contracts
// Can we create the 1155 asset the first time we _unequip_ the 1155?
// TODO: Probably need to change this from a uint8, is 256 really enough?
// TODO: This should just be a fucking array? Am I crazy? That's more flexible
struct Skeleton {
  uint256 head;
  uint256 torso;
  uint256 lArm;
  uint256 rArm;
  uint256 lLeg;
  uint256 rLeg;
  uint256 mouth;
  uint256 eyes;
  uint256 color;
  uint256 marking;
  uint256 crown;
}
struct Outfit {
  uint256 head;
  uint256 torso;
  uint256 lArm;
  uint256 rArm;
  uint256 lLeg;
  uint256 rLeg;
  uint256 floating;
}

library CharacterLibrary {
  uint256 public constant MAX_INT = 2**256 - 1;

  function getSkeletonSlot(uint256 slotID, Skeleton memory skeleton)
    public
    pure
    returns (uint256)
  {
    if (slotID == 0) {
      return skeleton.head;
    } else if (slotID == 1) {
      return skeleton.torso;
    } else if (slotID == 2) {
      return skeleton.lArm;
    } else if (slotID == 3) {
      return skeleton.rArm;
    } else if (slotID == 4) {
      return skeleton.lLeg;
    } else if (slotID == 5) {
      return skeleton.rLeg;
    } else if (slotID == 6) {
      return skeleton.mouth;
    } else if (slotID == 7) {
      return skeleton.eyes;
    } else if (slotID == 8) {
      return skeleton.color;
    } else if (slotID == 9) {
      return skeleton.marking;
    } else if (slotID == 10) {
      return skeleton.crown;
    }
    return MAX_INT;
  }

  function getOutfitSlot(uint256 slotID, Outfit memory outfit)
    public
    pure
    returns (uint256)
  {
    if (slotID == 0) {
      return outfit.head;
    } else if (slotID == 1) {
      return outfit.torso;
    } else if (slotID == 2) {
      return outfit.lArm;
    } else if (slotID == 3) {
      return outfit.rArm;
    } else if (slotID == 4) {
      return outfit.lLeg;
    } else if (slotID == 5) {
      return outfit.rLeg;
    } else if (slotID == 6) {
      return outfit.floating;
    }
    return MAX_INT;
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;
import "../lib/LegacyPills.sol";
//Interface

interface IToken {
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);
}

contract SelectableOptions {
  string private constant _HASHMONK_FORM = "Hashmonk";
  string private constant _PEPEL_FORM = "Pepel";
  string private constant _MOUTH = "Mouth";
  string private constant _EYES = "Eyes";
  string private constant _TYPE = "Type";
  string private constant _MARKINGS = "Markings";
  string private constant _CROWN = "Crown";
  string private constant _HEAD = "Head";
  string private constant _TORSO = "Torso";
  string private constant _LARM = "LeftArm";
  string private constant _RARM = "RightArm";
  string private constant _LLEG = "LeftLeg";
  string private constant _RLEG = "RightLeg";

  enum Requirement {
    None,
    HasEth,
    HasLegacyPill,
    HasCollabPill,
    HasTrait,
    HasNotTrait
  }
  // Extremely unwieldly struct; do better?
  struct Option {
    Requirement req; // 1 = HAS ETH, 2 = HAS PILL, 3 = Has TRAIT, 4 = HAS NOT TRAIT
    uint256 form;
    string name;
    string slot;
    string option;
  }

  string[] private _forms = [_HASHMONK_FORM, _PEPEL_FORM];

  // For each option what exactly are we checking?
  mapping(uint256 => uint256) private _idToEthCost;
  mapping(uint256 => uint256) private _idToLegacyPillReq;
  mapping(uint256 => uint256) public legacyPillToId;
  mapping(uint256 => uint256) private _idToCollabPillReq;
  mapping(uint256 => uint256) private collabPillToId;

  mapping(uint256 => string) private _idToTraitReq;

  // Mapping between the string rep of the selected character option and the fully qualified option requirements
  mapping(uint256 => Option) private _options;

  mapping(string => uint256) private _optionToId;
  uint256 private _optionCount;
  uint256 private _optionIndex = 65;

  address private _legacyPills;
  address private _collabPills;

  constructor(address legacyPills_, address collabPills_) {
    _legacyPills = legacyPills_;
    _collabPills = collabPills_;
  }


  function validateFaction(string calldata _faction, uint256 legacyPillId, address target) public view returns (bool) {
    uint256 id = _optionToId[_faction];
    require(id != 0, "Invalid faction");
    if(_options[id].req == Requirement.HasLegacyPill){
          require(
            IToken(_legacyPills).balanceOf(target, legacyPillId) > 0 &&
              _idToLegacyPillReq[id] == LegacyPills.getTypeFromId(legacyPillId),
            "You do not have the required Legacy pill"
          );
    }
    return true;
  }

  // TODO: Slim this THE FUCK down; use split functions for each index this is trash
  function validateOption(
    string[] calldata options,
    uint256 index,
    uint256 ethValue,
    uint256[] calldata legacyPillId,
    address target
  ) external view returns (uint256) {
    uint256 id = _optionToId[options[index]];
    Option memory op = _options[id];
    Requirement req = op.req;
    string memory form = _forms[op.form]; // Hashmonk or Pepel
    require(_compareCall(options[0], form), "Forms don't match");
    // TODO: Is there a smarter/more efficient/more extensible version of this?
    // Can probably convert this to an ASS switch
    if (_compareMem(form, _PEPEL_FORM)) {
      if (index == 5) {
        require(_compareMem(op.slot, _MOUTH), "invalid mouth");
      } else if (index == 6) {
        require(_compareMem(op.slot, _EYES), "invalid eyes");
      } else if (index == 7) {
        require(_compareMem(op.slot, _TYPE), "invalid type");
      } else if (index == 8) {
        require(_compareMem(op.slot, _MARKINGS), "invalid markings");
      } else {
        revert("invalid index");
      }
    } else if (_compareMem(form, _HASHMONK_FORM)) {
      if (index == 5) {
        require(_compareMem(op.slot, _HEAD), "invalid head");
      } else if (index == 6) {
        require(_compareMem(op.slot, _TORSO), "invalid torso");
      } else if (index == 7) {
        require(_compareMem(op.slot, _LARM), "invalid left arm");
      } else if (index == 8) {
        require(_compareMem(op.slot, _RARM), "invalid right arm");
      } else if (index == 9) {
        require(_compareMem(op.slot, _LLEG), "invalid left leg");
      } else if (index == 10) {
        require(_compareMem(op.slot, _RLEG), "invalid right leg");
      } else if (index == 11) {
        require(_compareMem(op.slot, _TYPE), "invalid color");
      } else if (index == 12) {
        require(_compareMem(op.slot, _CROWN), "invalid crown");
      } else {
        revert("invalid index");
      }
    }

    // HAS ETH
    if (req == Requirement.HasEth) {
      _checkHasEth(id, ethValue);
    }
    // HAS LEGACY PILL
    else if (req == Requirement.HasLegacyPill) {
      _checkHasLegacyPill(id, legacyPillId, target);
    }
    // HAS COLLAB PILL
    else if (req == Requirement.HasCollabPill) {
      _checkHasCollabPill(id, target);
    }
    // HAS TRAIT
    else if (req == Requirement.HasTrait) {
      _checkHasTrait(id, options);
    }
    // HAS NOT TRAIT
    else if (req == Requirement.HasNotTrait) {
      _checkHasNotTrait(id, options);
    }
    return id;
  }

  function getOption(string calldata option)
    external
    view
    returns (Option memory op)
  {
    op = _options[_optionToId[option]];
  }

  function getOptionId(string calldata option) external view returns (uint256) {
    return _optionToId[option];
  }

  // TODO: Put this somewhere better plx; memory vs calldata mismatch
  function _compareCall(string calldata a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  // TODO: Issue with overload? Potentially rename; has caused issues before
  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  // TODO: Issue with overload? Potentially rename; has caused issues before
  function _compareMem2Call(string memory a, string calldata b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function addOptionWithId(
    string calldata option,
    uint256 id,
    string calldata name,
    string calldata slot,
    uint256 form
  ) public {
    _addOption(option, id, name, slot, form);
  }

  function getOptionStringFromId(uint256 id) public view returns (string memory op) {
    op = _options[id].option;
  }

  function getSlotFromId(uint256 id) external view returns (string memory op) {
    op = _options[id].slot;
  }

  function getFormFromId(uint256 id) external view returns (uint256 op) {
    op = _options[id].form;
  }

  function addOption(
    string calldata option,
    string calldata name,
    string calldata slot,
    uint256 form
  ) public {
      unchecked {
      _optionIndex = _optionIndex + 1;
    }
    _addOption(option, _optionIndex, name, slot, form);

  }

  function _addOption(
    string calldata optionID,
    uint256 id,
    string calldata name,
    string calldata slot,
    uint256 form
  ) internal {
    _optionToId[optionID] = id;
    _options[id] = Option(
      Requirement.None,
      form,
      name,
      slot,
      optionID
    );
  }

  function setEthRequirement(uint256 id, uint256 cost) external {
    _options[id].req = Requirement.HasEth;
    _idToEthCost[id] = cost;
  }

  function setLegacyPillRequirement(uint256 id, uint256 reqId) external {
    _options[id].req = Requirement.HasLegacyPill;
    _idToLegacyPillReq[id] = reqId;
    legacyPillToId[reqId] = id;
  }

  function setCollabPillRequirement(uint256 id, uint256 reqId) external {
    _options[id].req = Requirement.HasCollabPill;
    _idToCollabPillReq[id] = reqId;
    collabPillToId[reqId] = id;
  }

  function setTraitRequirement(uint256 id, string calldata trait) external {
    _options[id].req = Requirement.HasTrait;
    _idToTraitReq[id] = trait;
  }

  function setNotTraitRequirement(uint256 id, string calldata trait) external {
    _options[id].req = Requirement.HasNotTrait;
    _idToTraitReq[id] = trait;
  }

  function getCostFromOption(string calldata option)
    external
    view
    returns (uint256)
  {
    uint256 id = _optionToId[option];
    Option memory optionStruct = _options[id];
    if (optionStruct.req != Requirement.HasEth) {
      return 0;
    }
    return _idToEthCost[id];
  }

  function _checkHasEth(uint256 id, uint256 ethValue) internal view {
    require(ethValue >= _idToEthCost[id], "not enough ETH");
  }

  function _checkHasCollabPill(uint256 id, address target) internal view {
    //Could be optimized
    require(
      IToken(_collabPills).balanceOf(target, _idToCollabPillReq[id]) > 0,
      "You do not have the required collab pill"
    );
  }

  function _checkHasLegacyPill(
    uint256 id,
    uint256[] calldata legacyPillId,
    address target
  ) internal view {
    // Could be optimized
    bool found = false;
    for (uint256 index = 0; index < legacyPillId.length && found==false; index++) {
      // TODO: move the balance check/transfer higher up in the function processing
      found = IToken(_legacyPills).balanceOf(target, legacyPillId[index]) > 0 &&
        _idToLegacyPillReq[id] == LegacyPills.getTypeFromId(legacyPillId[index]);
    }
    require(found, "You do not have the required Legacy pill");
  }

  function getStringFromLegacyPill(uint256 pillId) external view returns (string memory) {
    uint256 pillType = LegacyPills.getTypeFromId(pillId);
    uint256 id = legacyPillToId[pillType];
    return getOptionStringFromId(id);
  }
  
  function getStringFromCollabPill(uint256 pillId) external view returns (string memory) {
    return getOptionStringFromId(collabPillToId[pillId]);
  }

  function _checkHasTrait(uint256 id, string[] calldata options) internal view {
    require(
      _findTrait(id, options) == true,
      "You don't have the correct trait"
    );
  }

  function _checkHasNotTrait(uint256 id, string[] calldata options)
    internal
    view
  {
    require(_findTrait(id, options) == false, "You have an incompatible trait");
  }

  function _findTrait(uint256 id, string[] calldata options)
    internal
    view
    returns (bool traitFound)
  {
    string memory trait = _idToTraitReq[id];
    for (uint256 i = 0; i < 5 && !traitFound; i++) {
      traitFound = _compareMem2Call(trait, options[i]);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "../characters/SelectableOptions.sol";
import "../interfaces/IWearables.sol";
import "../interfaces/IAugments.sol";
import "../interfaces/ICharacter.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/ICore1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// TODO: Put these in a single place, these are also located in the Characters contract


//Slot to ID mapping
// SKELETON
// Head = 1
// Torso = 2
// larm = 3
// rarm = 4
// lleg = 5
// rleg = 6
// mouth = 7
// eyes = 8
// color = 9
// marking = 10
// crown = 11
// OUTFIT
// Head = 33
// Torso = 34
// larm = 35
// rarm = 36
// lleg = 37
// rleg = 38
// floating = 39
contract CharacterValidator is Ownable {
  uint256 public constant MAX_INT = 2**256 - 1;
  address private _zeroAddress = 0x0000000000000000000000000000000000000000;
  // Instance of core
  ICore public core;
  ICore1155 public _boosters;
  IWearables public wearables;
  SelectableOptions public selectableOptions;
  IWearables public wearableOptions;
  IAugments public augmentOptions;
  ICharacter public character;
  IERC1155 private _collabPills;
  IERC1155 private _legacyPills;
  uint256 public nextId = 0;

  uint256[] private _charIdQueue;
  uint32 private _charPerCall;
  uint256 private _qOffset;
  mapping(uint256 => uint256) private _request2Offset;
  Skeleton public defaultSkeleton = Skeleton(
    1,2,3,4,5,6,7,8,9,10,11
  );
  Outfit public defaultOutfit = Outfit(
    33,34,35,36,37,38,39
  );

  event CharacterCreated(address indexed _owner, uint indexed _id);

  /**
   * @dev
   */
  constructor(
    ICore _core,
    SelectableOptions _selectableOptions,
    IWearables _wearableOptions,
    IAugments _augmentOptions,
    ICharacter _character,
    uint32 charPerCall_,
    IERC1155 collabPills_,
    IERC1155 legacyPills_,
    ICore1155 boosters_
  ) {
    // TODO: create setter for this, otherwise we could have some #BadVibes with the gassage
    core = _core;
    _charPerCall = charPerCall_;
    selectableOptions = _selectableOptions;
    wearableOptions = _wearableOptions;
    augmentOptions = _augmentOptions;
    character = _character;
    _collabPills = collabPills_;
    _legacyPills = legacyPills_;
    _boosters = boosters_;
  }

  /**
      Things we're setting in the character generation process: Form, Class, origin, traits, pillboosts and name 
      param pillboosts - An addresses prescence in this array is indicitive of the user _using_ the pillboost. Still check if it's held!

      // String Array Taxonomy?

      For the time being I'm collapsing all of the strings that this function consumes into a single array for the sake of not
      getting fucked by the compiler. When I have a better solution I'll implement it. For now this is the format:

      [0] = form
      [1-X] = traits
      [Y-Z] = character selectable options

      For Launch this looks something like...

      [0] = form
      [1] = origin
      [2] = upbringing
      [3] = gift
      [4] = faction
      [5] = mask[hashmonk] or mouth[pepel]
      [6] = water type[hashmonk] or eyes[pepel]
      [7] = frog type[pepel]
      [8] = marking type[pepel]

      Need a "termination" string for the traits?

      We may need to further encode the traits slots to clarify backgrounds etc.
    /// @notice generate a character for PACE
    /// @param legacyPills Array of the ID of all legacy pills being used
    /// @param collabPills Array of the ID of all collab pills being used
    /// @param traitsPlus Every character option selected during character creation
  */
  function createCharacter(
    uint256[] calldata legacyPills,
    uint256[] calldata collabPills,
    string[] calldata traitsPlus
  ) external payable {
    // Confirm address holds all the pills they claim to hold
    _createCharacter(
      legacyPills,
      collabPills,
      traitsPlus,
      ++nextId,
      msg.sender
    );
    for (uint256 index = 0; index < legacyPills.length; index++) {
      if(legacyPills[index] != 0){
        _legacyPills.safeTransferFrom(msg.sender, _zeroAddress, legacyPills[index], 1, "");
      }
    }
  }

  function createCharacterL1(
    uint256[] calldata legacyPills,
    uint256[] calldata collabPills,
    string[] calldata traitsPlus,
    address target
  ) external payable {
    // Confirm address holds all the COLLAB pills they claim to hold
    _createCharacter(legacyPills, collabPills, traitsPlus, ++nextId, target);
  }

  // This is the part that needs to be converted to make the skeletons extensible
  function _createCharacter(
    uint256[] calldata legacyPills,
    uint256[] calldata collabPills,
    string[] calldata traitsPlus,
    uint256 characterId,
    address target
  ) internal {
    Skeleton memory newSkeleton;
    selectableOptions.validateFaction(traitsPlus[4], legacyPills[0], target);
    uint8 form = _compareMem(traitsPlus[0], "Pepel") ? 1 : 2;
    if (form == 1) {
      newSkeleton = defaultSkeleton;
      newSkeleton.mouth = selectableOptions.validateOption(
        traitsPlus,
        5,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.eyes = selectableOptions.validateOption(
        traitsPlus,
        6,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.color = selectableOptions.validateOption(
        traitsPlus,
        7,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.marking = selectableOptions.validateOption(
        traitsPlus,
        8,
        msg.value,
        legacyPills,
        target
      );
    } else if (form == 2) {
      newSkeleton.head = selectableOptions.validateOption(
        traitsPlus,
        5,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.torso = selectableOptions.validateOption(
        traitsPlus,
        6,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.lArm = selectableOptions.validateOption(
        traitsPlus,
        7,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.rArm = selectableOptions.validateOption(
        traitsPlus,
        8,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.lLeg = selectableOptions.validateOption(
        traitsPlus,
        9,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.rLeg = selectableOptions.validateOption(
        traitsPlus,
        10,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.color = selectableOptions.validateOption(
        traitsPlus,
        11,
        msg.value,
        legacyPills,
        target
      );
      newSkeleton.crown = selectableOptions.validateOption(
        traitsPlus,
        12,
        msg.value,
        legacyPills,
        target
      );
      
    } else {
      revert("Invalid form");
    }
    core.modularMintCallback(msg.sender, characterId, "");
    // Start by adding the player into the characters contract
    character.addPlayer(
      characterId,
      msg.sender,
      legacyPills,
      collabPills,
      traitsPlus
    );
    if (_compareMem(traitsPlus[0], "Hashmonk")){
      character.setOutfitSlot(characterId, 0, uint32(selectableOptions.getOptionId(traitsPlus[13])));
    }
    character.setSkeleton(characterId, newSkeleton);

    for (uint256 index = 0; index < collabPills.length; index++) {
      if(collabPills[index] != 0) {
        _collabPills.safeTransferFrom(msg.sender, _zeroAddress, collabPills[index], 1, "");
      }
    }
    string[] memory equipment = _processEquipment(legacyPills, collabPills, form);
    for(uint256 index = 0; index < equipment.length; index++) {
      if(_compareMem(equipment[index], "" ) == false) {
        character.setOutfitSlot(characterId, wearableOptions.getSlot(equipment[index]), wearableOptions.id(equipment[index]));
      }
    }
    _boosters.modularMintCallbackSingle(msg.sender, equipment.length, "");

    emit CharacterCreated(msg.sender, characterId);
  }

  function settings(    
    ICore _core,
    SelectableOptions _selectableOptions,
    IWearables _wearableOptions,
    IAugments _augmentOptions,
    ICharacter _character,
    uint32 charPerCall_,
    IERC1155 collabPills_,
    IERC1155 legacyPills_
  ) external onlyOwner{
    // TODO: create setter for this, otherwise we could have some #BadVibes with the gassage
    core = _core;
    _charPerCall = charPerCall_;
    selectableOptions = _selectableOptions;
    wearableOptions = _wearableOptions;
    augmentOptions = _augmentOptions;
    character = _character;
    _collabPills = collabPills_;
    _legacyPills = legacyPills_;
  }

  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function _getSubRandom(uint256 index, uint256 source)
    internal
    pure
    returns (uint8)
  {
    if (index == 0) {
      return uint8(source);
    }
    return uint8(source / (256 * index));
  }

  /// @notice Collects and sends an amount of ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  /// @param value Amount of ETH (in wei) to transfer
  function collectEth(address target, uint256 value) external onlyOwner {
    _sendEth(target, value);
  }

  /// @notice Collects all ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  function collectAllEth(address target) external onlyOwner {
    _sendEth(target, address(this).balance);
  }

  function _sendEth(address target, uint256 value) internal {
    (bool success, ) = target.call{value: value}("");
    require(success, "Transfer failed.");
  }

  function getEquipment(uint256 characterId) public view returns (string[] memory equipment){
      Character memory characterInstance = character.getCharacter(characterId);
      uint8 form = _compareMem(characterInstance.form, "Pepel") ? 1 : 2;
      equipment = _processEquipment(characterInstance.legacyPills, characterInstance.collabPills, form);
  }

  function _processEquipment(uint256[] memory legacyPills, uint256[] memory collabPills, uint8 form) internal view returns (string[] memory equipment){
      equipment = new string[](10);
      string[] memory equipmentArray;
      uint8 equipmentIndex = 0;
      for(uint32 i = 0; i < 5; i++){
        equipmentArray = new string[](0);
        if(legacyPills[i] != 0){
          console.log(legacyPills[i], "legacyPills[i]");
          equipmentArray =  wearableOptions.getEquipmentFromPill(legacyPills[i], form);
        }
        if(collabPills[i] != 0){
          console.log(collabPills[i], "collabPills[i]");
          equipmentArray =  wearableOptions.getEquipmentFromPill(collabPills[i], form);
        }
        for(uint32 j = 0; j < equipmentArray.length; j++){
          console.log(equipmentArray[j], equipmentIndex);
          equipment[equipmentIndex++] = equipmentArray[j];
        }
      }
  }



  function _getTraitFromIndex(uint256 index, Character memory char)
    internal
    pure
    returns (string memory)
  {
    if (index == 0) {
      return char.origin;
    }
    if (index == 1) {
      return char.upbringing;
    }
    if (index == 2) {
      return char.gift;
    }
    if (index == 3) {
      return char.faction;
    }
    return "";
  }

  function _getRarityFromRoll(uint8 roll) internal pure returns (uint8 rarity) {
    if (roll > 230) {
      rarity = 3;
    } else if (roll > 153) {
      rarity = 2;
    } else {
      rarity = 1;
    }
  }
}

// Dev Note: collapse these down into composable interfaces?
interface IAugments {
  function getAugmentIDByOption(
    string memory option,
    uint8 form,
    uint8 rarity,
    uint8 slot
  ) external view returns (uint256);

  function getAugmentIDBySeries(
    uint32 series,
    uint8 form,
    uint8 rarity,
    uint8 slot
  ) external view returns (uint256);
}

// write interface for
//Interface
interface ICore {
  function ownerOf(uint256 id) external view returns (address);

  function uri(uint256 id) external view returns (string memory);

  function modularMintInit(
    uint256 _dropId,
    address _to,
    bytes memory _data,
    address _validator,
    string calldata _metadata
  ) external;

  function modularMintCallback(
    address recipient,
    uint256 _id,
    bytes calldata _data
  ) external;
}

pragma solidity ^0.8.0;


/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _value
  );

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _values
  );

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _id);

  /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes calldata _data
  ) external;

  /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes calldata _data
  ) external;

  /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

  /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "../characters/SelectableOptionsV2.sol";
import "../interfaces/IWearables.sol";
import "../interfaces/ICharacterV2.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/ICore1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// TODO: Put these in a single place, these are also located in the Characters contract


//Slot to ID mapping
// SKELETON
// Head = 1
// Torso = 2
// larm = 3
// rarm = 4
// lleg = 5
// rleg = 6
// mouth = 7
// eyes = 8
// color = 9
// marking = 10
// crown = 11
// OUTFIT
// Head = 33
// Torso = 34
// larm = 35
// rarm = 36
// lleg = 37
// rleg = 38
// floating = 39
contract CharacterValidatorV2 is Ownable {
  uint256 public constant MAX_INT = 2**256 - 1;
  address private _zeroAddress = 0x0000000000000000000000000000000000000000;
  // Instance of core
  ICore public core;
  ICore1155 public _boosters;
  IWearables public wearables;
  SelectableOptionsV2 public selectableOptions;
  IWearables public wearableOptions;
  ICharacter public character;
  IERC1155 private _collabPills;
  IERC1155 private _legacyPills;
  uint256 public nextId = 0;

  uint256[] private _charIdQueue;
  uint32 private _charPerCall;
  uint256 private _qOffset;
  mapping(uint256 => uint256) private _request2Offset;
  Skeleton public defaultSkeleton = Skeleton(
    1,2,3,4,5,6,7,8,9,10,11
  );
  Outfit public defaultOutfit = Outfit(
    33,34,35,36,37,38,39
  );

  event CharacterCreated(address indexed _owner, uint indexed _id);

  /**
   * @dev
   */
  constructor(
    ICore _core,
    SelectableOptionsV2 _selectableOptions,
    IWearables _wearableOptions,
    ICharacter _character,
    uint32 charPerCall_
  ) {
    // TODO: create setter for this, otherwise we could have some #BadVibes with the gassage
    core = _core;
    _charPerCall = charPerCall_;
    selectableOptions = _selectableOptions;
    wearableOptions = _wearableOptions;
    character = _character;
  }

  /**
      Things we're setting in the character generation process: Form, Class, origin, traits, and name 

      // String Array Taxonomy?

      For the time being I'm collapsing all of the strings that this function consumes into a single array for the sake of not
      getting fucked by the compiler. When I have a better solution I'll implement it. For now this is the format:

      [0] = form
      [1-X] = traits
      [Y-Z] = character selectable options

      For Launch this looks something like...

      [0] = form
      [1] = origin
      [2] = upbringing
      [3] = gift
      [4] = faction
      [5] = mask[hashmonk] or mouth[pepel]
      [6] = water type[hashmonk] or eyes[pepel]
      [7] = frog type[pepel]
      [8] = marking type[pepel]

      Need a "termination" string for the traits?

      We may need to further encode the traits slots to clarify backgrounds etc.
    /// @notice generate a character for PACE
    /// @param traitsPlus Every character option selected during character creation
  */
  function createCharacter(
    string[] calldata traitsPlus
  ) external payable {
    _createCharacter(
      traitsPlus,
      ++nextId,
      msg.sender
    );
  }

  function createCharacterL1(
    string[] calldata traitsPlus,
    address target
  ) external payable {
    _createCharacter(traitsPlus, ++nextId, target);
  }

  // This is the part that needs to be converted to make the skeletons extensible
  function _createCharacter(
    string[] calldata traitsPlus,
    uint256 characterId,
    address target
  ) internal {
    Skeleton memory newSkeleton;
    uint8 form = _compareMem(traitsPlus[0], "Pepel") ? 1 : 2;
    if (form == 1) {
      newSkeleton = defaultSkeleton;
      newSkeleton.mouth = selectableOptions.validateOption(
        traitsPlus,
        5,
        msg.value,
        target
      );
      newSkeleton.eyes = selectableOptions.validateOption(
        traitsPlus,
        6,
        msg.value,
        target
      );
      newSkeleton.color = selectableOptions.validateOption(
        traitsPlus,
        7,
        msg.value,
        target
      );
      newSkeleton.marking = selectableOptions.validateOption(
        traitsPlus,
        8,
        msg.value,
        target
      );
    } else if (form == 2) {
      newSkeleton.head = selectableOptions.validateOption(
        traitsPlus,
        5,
        msg.value,
        target
      );
      newSkeleton.torso = selectableOptions.validateOption(
        traitsPlus,
        6,
        msg.value,
        target
      );
      newSkeleton.lArm = selectableOptions.validateOption(
        traitsPlus,
        7,
        msg.value,
        target
      );
      newSkeleton.rArm = selectableOptions.validateOption(
        traitsPlus,
        8,
        msg.value,
        target
      );
      newSkeleton.lLeg = selectableOptions.validateOption(
        traitsPlus,
        9,
        msg.value,
        target
      );
      newSkeleton.rLeg = selectableOptions.validateOption(
        traitsPlus,
        10,
        msg.value,
        target
      );
      newSkeleton.color = selectableOptions.validateOption(
        traitsPlus,
        11,
        msg.value,
        target
      );
      newSkeleton.crown = selectableOptions.validateOption(
        traitsPlus,
        12,
        msg.value,
        target
      );
      
    } else {
      revert("Invalid form");
    }
    core.modularMintCallback(msg.sender, characterId, "");
    // Start by adding the player into the characters contract
    character.addPlayer(
      characterId,
      traitsPlus
    );
    if (_compareMem(traitsPlus[0], "Hashmonk")){
      character.setOutfitSlot(characterId, 0, uint32(selectableOptions.getOptionId(traitsPlus[13])));
    }
    character.setSkeleton(characterId, newSkeleton);
    emit CharacterCreated(msg.sender, characterId);
  }

  function settings(    
    ICore _core,
    SelectableOptionsV2 _selectableOptions,
    IWearables _wearableOptions,
    ICharacter _character,
    uint32 charPerCall_,
    IERC1155 collabPills_,
    IERC1155 legacyPills_
  ) external onlyOwner{
    // TODO: create setter for this, otherwise we could have some #BadVibes with the gassage
    core = _core;
    _charPerCall = charPerCall_;
    selectableOptions = _selectableOptions;
    wearableOptions = _wearableOptions;
    character = _character;
    _collabPills = collabPills_;
    _legacyPills = legacyPills_;
  }

  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function _getSubRandom(uint256 index, uint256 source)
    internal
    pure
    returns (uint8)
  {
    if (index == 0) {
      return uint8(source);
    }
    return uint8(source / (256 * index));
  }

  /// @notice Collects and sends an amount of ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  /// @param value Amount of ETH (in wei) to transfer
  function collectEth(address target, uint256 value) external onlyOwner {
    _sendEth(target, value);
  }

  /// @notice Collects all ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  function collectAllEth(address target) external onlyOwner {
    _sendEth(target, address(this).balance);
  }

  function _sendEth(address target, uint256 value) internal {
    (bool success, ) = target.call{value: value}("");
    require(success, "Transfer failed.");
  }

  function getEquipment(uint256 characterId) public view returns (string[] memory equipment){
      Character memory characterInstance = character.getCharacter(characterId);
      uint8 form = _compareMem(characterInstance.form, "Pepel") ? 1 : 2;
      equipment = _processEquipment(characterInstance.legacyPills, characterInstance.collabPills, form);
  }

  function _processEquipment(uint256[] memory legacyPills, uint256[] memory collabPills, uint8 form) internal view returns (string[] memory equipment){
      equipment = new string[](10);
      string[] memory equipmentArray;
      uint8 equipmentIndex = 0;
      for(uint32 i = 0; i < 5; i++){
        equipmentArray = new string[](0);
        if(legacyPills[i] != 0){
          console.log(legacyPills[i], "legacyPills[i]");
          equipmentArray =  wearableOptions.getEquipmentFromPill(legacyPills[i], form);
        }
        if(collabPills[i] != 0){
          console.log(collabPills[i], "collabPills[i]");
          equipmentArray =  wearableOptions.getEquipmentFromPill(collabPills[i], form);
        }
        for(uint32 j = 0; j < equipmentArray.length; j++){
          console.log(equipmentArray[j], equipmentIndex);
          equipment[equipmentIndex++] = equipmentArray[j];
        }
      }
  }



  function _getTraitFromIndex(uint256 index, Character memory char)
    internal
    pure
    returns (string memory)
  {
    if (index == 0) {
      return char.origin;
    }
    if (index == 1) {
      return char.upbringing;
    }
    if (index == 2) {
      return char.gift;
    }
    if (index == 3) {
      return char.faction;
    }
    return "";
  }

  function _getRarityFromRoll(uint8 roll) internal pure returns (uint8 rarity) {
    if (roll > 230) {
      rarity = 3;
    } else if (roll > 153) {
      rarity = 2;
    } else {
      rarity = 1;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;
import "../lib/CharacterLibrary.sol";
//Interface

interface IToken {
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);
}

contract SelectableOptionsV2 {
  string private constant _HASHMONK_FORM = "Hashmonk";
  string private constant _PEPEL_FORM = "Pepel";
  string private constant _MOUTH = "Mouth";
  string private constant _EYES = "Eyes";
  string private constant _TYPE = "Type";
  string private constant _MARKINGS = "Markings";
  string private constant _CROWN = "Crown";
  string private constant _HEAD = "Head";
  string private constant _TORSO = "Torso";
  string private constant _LARM = "LeftArm";
  string private constant _RARM = "RightArm";
  string private constant _LLEG = "LeftLeg";
  string private constant _RLEG = "RightLeg";

  enum Requirement {
    None,
    HasEth,
    HasTrait,
    HasNotTrait
  }
  // Extremely unwieldly struct; do better?
  struct Option {
    Requirement req; // 1 = HAS ETH, 2 = HAS PILL, 3 = Has TRAIT, 4 = HAS NOT TRAIT
    uint256 form;
    string name;
    string slot;
    string option;
  }

  string[] private _forms = [_HASHMONK_FORM, _PEPEL_FORM];

  // For each option what exactly are we checking?
  mapping(uint256 => uint256) private _idToEthCost;
  mapping(uint256 => uint256) private _idToCollabPillReq;
  mapping(uint256 => uint256) private collabPillToId;

  mapping(uint256 => string) private _idToTraitReq;

  // Mapping between the string rep of the selected character option and the fully qualified option requirements
  mapping(uint256 => Option) private _options;

  mapping(string => uint256) private _optionToId;
  uint256 private _optionCount;
  uint256 private _optionIndex = 65;


  // TODO: Slim this THE FUCK down; use split functions for each index this is trash
  function validateOption(
    string[] calldata options,
    uint256 index,
    uint256 ethValue,
    address target
  ) external view returns (uint256) {
    uint256 id = _optionToId[options[index]];
    Option memory op = _options[id];
    Requirement req = op.req;
    string memory form = _forms[op.form]; // Hashmonk or Pepel
    require(_compareCall(options[0], form), "Forms don't match");
    // TODO: Is there a smarter/more efficient/more extensible version of this?
    // Can probably convert this to an ASS switch
    if (_compareMem(form, _PEPEL_FORM)) {
      if (index == 5) {
        require(_compareMem(op.slot, _MOUTH), "invalid mouth");
      } else if (index == 6) {
        require(_compareMem(op.slot, _EYES), "invalid eyes");
      } else if (index == 7) {
        require(_compareMem(op.slot, _TYPE), "invalid type");
      } else if (index == 8) {
        require(_compareMem(op.slot, _MARKINGS), "invalid markings");
      } else {
        revert("invalid index");
      }
    } else if (_compareMem(form, _HASHMONK_FORM)) {
      if (index == 5) {
        require(_compareMem(op.slot, _HEAD), "invalid head");
      } else if (index == 6) {
        require(_compareMem(op.slot, _TORSO), "invalid torso");
      } else if (index == 7) {
        require(_compareMem(op.slot, _LARM), "invalid left arm");
      } else if (index == 8) {
        require(_compareMem(op.slot, _RARM), "invalid right arm");
      } else if (index == 9) {
        require(_compareMem(op.slot, _LLEG), "invalid left leg");
      } else if (index == 10) {
        require(_compareMem(op.slot, _RLEG), "invalid right leg");
      } else if (index == 11) {
        require(_compareMem(op.slot, _TYPE), "invalid color");
      } else if (index == 12) {
        require(_compareMem(op.slot, _CROWN), "invalid crown");
      } else {
        revert("invalid index");
      }
    }

    // HAS ETH
    if (req == Requirement.HasEth) {
      _checkHasEth(id, ethValue);
    }

    // HAS TRAIT
    else if (req == Requirement.HasTrait) {
      _checkHasTrait(id, options);
    }
    // HAS NOT TRAIT
    else if (req == Requirement.HasNotTrait) {
      _checkHasNotTrait(id, options);
    }
    return id;
  }

  function getOption(string calldata option)
    external
    view
    returns (Option memory op)
  {
    op = _options[_optionToId[option]];
  }

  function getOptionId(string calldata option) external view returns (uint256) {
    return _optionToId[option];
  }

  // TODO: Put this somewhere better plx; memory vs calldata mismatch
  function _compareCall(string calldata a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  // TODO: Issue with overload? Potentially rename; has caused issues before
  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  // TODO: Issue with overload? Potentially rename; has caused issues before
  function _compareMem2Call(string memory a, string calldata b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function addOptionWithId(
    string calldata option,
    uint256 id,
    string calldata name,
    string calldata slot,
    uint256 form
  ) public {
    _addOption(option, id, name, slot, form);
  }

  function getOptionStringFromId(uint256 id) public view returns (string memory op) {
    op = _options[id].option;
  }

  function getSlotFromId(uint256 id) external view returns (string memory op) {
    op = _options[id].slot;
  }

  function getFormFromId(uint256 id) external view returns (uint256 op) {
    op = _options[id].form;
  }

  function addOption(
    string calldata option,
    string calldata name,
    string calldata slot,
    uint256 form
  ) public {
      unchecked {
      _optionIndex = _optionIndex + 1;
    }
    _addOption(option, _optionIndex, name, slot, form);

  }

  function _addOption(
    string calldata optionID,
    uint256 id,
    string calldata name,
    string calldata slot,
    uint256 form
  ) internal {
    _optionToId[optionID] = id;
    _options[id] = Option(
      Requirement.None,
      form,
      name,
      slot,
      optionID
    );
  }

  function setEthRequirement(uint256 id, uint256 cost) external {
    _options[id].req = Requirement.HasEth;
    _idToEthCost[id] = cost;
  }

  function setTraitRequirement(uint256 id, string calldata trait) external {
    _options[id].req = Requirement.HasTrait;
    _idToTraitReq[id] = trait;
  }

  function setNotTraitRequirement(uint256 id, string calldata trait) external {
    _options[id].req = Requirement.HasNotTrait;
    _idToTraitReq[id] = trait;
  }

  function getCostFromOption(string calldata option)
    external
    view
    returns (uint256)
  {
    uint256 id = _optionToId[option];
    Option memory optionStruct = _options[id];
    if (optionStruct.req != Requirement.HasEth) {
      return 0;
    }
    return _idToEthCost[id];
  }

  function _checkHasEth(uint256 id, uint256 ethValue) internal view {
    require(ethValue >= _idToEthCost[id], "not enough ETH");
  }

  function _checkHasTrait(uint256 id, string[] calldata options) internal view {
    require(
      _findTrait(id, options) == true,
      "You don't have the correct trait"
    );
  }

  function _checkHasNotTrait(uint256 id, string[] calldata options)
    internal
    view
  {
    require(_findTrait(id, options) == false, "You have an incompatible trait");
  }

  function _findTrait(uint256 id, string[] calldata options)
    internal
    view
    returns (bool traitFound)
  {
    string memory trait = _idToTraitReq[id];
    for (uint256 i = 0; i < 5 && !traitFound; i++) {
      traitFound = _compareMem2Call(trait, options[i]);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


import "../lib/CharacterLibrary.sol";

interface ICharacter {
  function equipSkeleton(
    uint16 slotID,
    uint256 id,
    address _player
  ) external;

  function equipOutfit(
    uint32 id,
    uint16 slotID,
    address _player
  ) external;

  function unequipSkeleton(uint16 slotID, address _player) external;

  function unequipOutfit(uint16 slotID, address _player) external;

  function addPlayer(
    uint256 _id,
    string[] calldata traitsPlus
  ) external;

  function removePlayer(uint256 _id, address _player) external;

  function getSkeleton(uint256 tokenID) external view returns (Skeleton memory);

  function getOutfit(uint256 tokenID) external view returns (Outfit memory);

  function getCharacter(uint256 tokenID)
    external
    view
    returns (Character memory);

  function setSkeleton(uint256 tokenID, Skeleton calldata skeleton) external;

  function setOutfit(uint256 tokenID, Outfit calldata outfit) external;
  function setOutfitSlot(
    uint256 _characterID,
    uint16 slotID,
    uint32 value) external;
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";

contract SequenceValidator is Ownable, IMintValidator {
  struct Drop {
    uint256 collectibleId;
    uint128 quantityAvailable;
    uint64 startTime;
    uint64 endTime;
    // do we want a start block?
    uint64 endBlock;
  }

  mapping(uint256 => Drop) public drops;
  // initialize with token and track state there
  //mapping(uint256 => bool) public claimed;
  // This should really be an interface
  IFabricator public core;

  constructor(IFabricator _core) {
    core = _core;
  }

  function validate(
    address _recipient,
    uint256 _dropID, /* _dropId*/
    uint256[] calldata quantity, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    Drop memory drop = drops[_dropID];
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    // 0. validate that blocknumber or timestamp have not passed
    require(block.timestamp > drop.startTime, "SEQ_DROP_TIME_EARLY");
    require(block.timestamp <= drop.endTime, "SEQ_DROP_TIME_EXPIRED");
    require(block.number <= drop.endBlock, "SEQ_DROP_BLOCK_PASSED");
    // 2. validate that the indicated quantity is available
    require(
      core.quantityMinted(drop.collectibleId) + quantity[0] <=
        drop.quantityAvailable,
      "SEQ_DROP_MAX_QUANTITY"
    );
    require(quantity[0] == 1, "SEQ_DROP_LIMIT_ONE");

    // 3. Call Callback Mint Function
    idReturn[0] = drop.collectibleId;
    quantityReturn[0] = 1;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }

  function createDrop(
    uint256 _collectibleId,
    uint16 _quantityAvailable,
    uint64 _startTime,
    uint64 _endTime,
    uint16 _endBlock
  ) external onlyOwner {
    /*
     1. ?split startId in type and index
     2.
     */
    require(
      drops[_collectibleId].collectibleId == 0,
      "SEQ_DROP_DUPLICATE_DROP"
    );
    drops[_collectibleId] = Drop(
      _collectibleId,
      _quantityAvailable,
      _startTime,
      _endTime,
      _endBlock
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "../interfaces/IMintValidator.sol";
import "../interfaces/IMintPipe.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title PaymentValidator
/// @notice Basic validator that takes payment in ETH and mints out an mount of tokens in the initialized ID
/// @dev Plz don't use this it's not meant for you
contract PaymentValidatorV2 is IMintValidator, Auth {
  uint256 private immutable _id;
  // This is the instance of core we call home to for the minty minty
  IMintPipe public core;
  uint256 private _cost;
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public perTxLimit;

  /// @param _core we use this to trigger the token mints
  /// @param id_ This ID must be registered in core, this is the ID that portalpills will mint into
  /// @param cost_ Cost in WEI (ETH) required _per 1155_
  constructor(
    IMintPipe _core,
    uint256 id_,
    uint256 cost_,
    uint256 _supply,
    Authority authority
  ) Auth(msg.sender, authority) {
    _id = id_;
    core = _core;
    _cost = cost_;
    totalSupply = _supply;
    perTxLimit = totalSupply;
  }

  function setCore(IMintPipe _core) public requiresAuth {
    core = _core;
  }

  /// @notice DO NOT USE
  /// @dev prevents calls from the main core instance since this validation requires payments
  function validate(
    address,
    uint256, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    revert("Use payable validator");
  }

  /// @notice Purchase PortalPills directly
  /// @param _recipient Target account to receieve the purchased Portal Pills
  /// @param _qty Number of PortalPills to purchase
  function directSale(address _recipient, uint256 _qty) external payable {
    uint256 newTotal;
    require(_qty <= perTxLimit, "Not enough supply");
    // Quantity + total minted will never overflow
    unchecked {
      newTotal = _qty + totalMinted;
    }
    require(newTotal <= totalSupply, "Not enough supply");
    require(msg.value / _cost >= _qty, "Sorry not enough ETH provided");
    _validate(_recipient, _qty);
    totalMinted = newTotal;
  }

  /// @notice Collects and sends an amount of ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  /// @param value Amount of ETH (in wei) to transfer
  function collectEth(address target, uint256 value) external requiresAuth {
    _sendEth(target, value);
  }

  /// @notice Sets a limit on the number of pills that can be purchased in a single transaction
  /// @param limit New token limit per transaction
  function newLimit(uint256 limit) external requiresAuth {
    require(limit < totalSupply, "Limit must be under supply total");
    perTxLimit = limit;
  }

  /// @notice Collects all ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  function collectAllEth(address target) external requiresAuth {
    _sendEth(target, address(this).balance);
  }

  function _sendEth(address target, uint256 value) internal {
    (bool success, ) = target.call{value: value}("");
    require(success, "Transfer failed.");
  }

  function _validate(address _recipient, uint256 _qty) internal {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = _id;
    quantityReturn[0] = _qty;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

interface IMintPipe {
  function modularMintCallback(
    address recipient,
    uint256[] memory _ids,
    uint256[] memory _requestedAmounts,
    bytes memory _data
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IMintPipe.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title CheckerValidator
/// @notice Validator is meant to check whether or not a specific NFT is held, and then spit out a corrsponding NFT.
///         For our use case we use it to allow people with a legacy pill to receive a portalpill. Main issues we've seen so far with this
///         has been in tracking
/// @dev Plz don't use this it's not meant for you
contract CheckerValidatorV2 is Context, IMintValidator, Auth {
  // This is the token we "check" against. Understand that the collection you're point this to
  // has a tremendous amount of control over the token ID this checker instance is registered with in core
  IERC1155 public originalToken;
  uint256 immutable _newId;
  // initialize with token and track state there
  mapping(uint256 => bool) public redeemed;
  mapping(address => uint256) public remaining;
  // This is the instance of core we call home to for the minty minty
  IMintPipe public core;

  /// @param _core we use this to trigger the token mints
  /// @param _original Token whose balance we check for mints; implier 1;1 1155s plzz
  /// @param newId_ This ID must be registered in core, 1155s of the old system will
  constructor(
    IMintPipe _core,
    IERC1155 _original,
    uint256 newId_,
    Authority authority
  ) Auth(msg.sender, authority) {
    _newId = newId_;
    core = _core;
    originalToken = _original;
  }

  function setCore(IMintPipe _core) public requiresAuth {
    core = _core;
  }

  function checkAllRedemption(uint256[] calldata ids)
    external
    view
    returns (bool[] memory)
  {
    bool[] memory redemptionStatus = new bool[](ids.length);
    for (uint256 i = 0; i < redemptionStatus.length; i++) {
      redemptionStatus[i] = _checkRedemption(ids[i]);
    }
    return redemptionStatus;
  }

  function _checkRedemption(uint256 id) internal view returns (bool) {
    return redeemed[id];
  }

  function redeemAll(uint256[] calldata ids) public {
    for (uint256 i = 0; i < ids.length; i++) {
      _redeem(ids[i], _msgSender());
    }
    _validate(_msgSender());
  }

  function _redeem(uint256 id, address target) internal {
    require(
      originalToken.balanceOf(target, id) > 0,
      "Sender must hold all tokens for migration"
    );
    require(redeemed[id] == false, "Token has already been redeemed");
    redeemed[id] = true;
    remaining[target] += 1;
  }

  function validate(
    address _recipient,
    uint256, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    _validate(_recipient);
  }

  function _validate(address _recipient) internal {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = _newId;
    quantityReturn[0] = remaining[_recipient];
    remaining[_recipient] = 0;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ICharacter.sol";
import "../interfaces/ICore.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

// Note: try to minimize the contract depth that mutative actions have to take
contract AugmentsValidator is Context, Auth {
  ICore public core;
  ICharacter public character;
  mapping(uint256 => bool) public augmentExists;
  uint16 public slotCount;
  mapping(uint256 => string) public cid;
  mapping(string => uint256) public id;

  // Change to initialize call
  constructor(
    ICharacter _character,
    ICore _core,
    Authority auth
  ) Auth(msg.sender, auth) {
    core = _core;
    character = _character;
  }

  function equipSkeleton(uint256 id, uint16 slotID) external {
    require(uint8(id) == uint8(slotID), "This doesn't fit in this slot");
    character.equipSkeleton(slotID, id, msg.sender);
  }

  function unequipSkeleton(uint16 slotID) external {
    character.unequipSkeleton(slotID, msg.sender);
  }

  function addAugment(
    uint32 series,
    uint16 slot,
    uint8 form,
    uint8 rarity
  ) external requiresAuth {
    augmentExists[convertToAugmentUUID(series, slot, form, rarity)] = true;
  }

  function removeAugment(
    uint32 series,
    uint16 slot,
    uint8 form,
    uint8 rarity
  ) external requiresAuth {
    augmentExists[convertToAugmentUUID(series, slot, form, rarity)] = false;
  }

  // Unclear if slot should be at the top, or the bottom of this config?
  function convertToAugmentUUID(
    uint32 series,
    uint16 slot,
    uint8 form,
    uint8 rarity
  ) public pure returns (uint256 id) {
    //solhint-disable-next-line
    assembly {
      // Bitshift and Pack series, rarity, and slot into ID -- [series][rarity][slot]
      id := add(
        add(add(slot, mul(rarity, 0x10000)), mul(form, 0x1000000)),
        mul(series, 0x100000000)
      )
    }
  }

  function setCID(uint256 _id, string calldata _cid) external {
    cid[_id] = _cid;
    id[_cid] = _id;
  }

  function uri(uint256 id) external view returns (string memory) {
    return core.uri(id);
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

// Note: This is a really heavy contract to implement directly. We want more of a centralized approach here
import "../interfaces/ICore.sol";
import "../interfaces/IWearables.sol";
import "./SelectableOptions.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "../lib/CharacterLibraryV2.sol";

// Note: try to minimize the contract depth that mutative actions have to take

contract CharactersV2 is Auth {
  // Instance of core
  ICore public core;
  IWearables public wearables;
  SelectableOptions public selectableOptions;
  address private _validator;
  string private _defaultDescription;
  string private _defaultName;

  // Need to replace with the solmate access control
  modifier onlyWearables() {
    require(address(wearables) == msg.sender, "WEARABLES");
    _;
  }
  modifier onlyValidator() {
    require(address(_validator) == msg.sender, "VALIDATOR");
    _;
  }

  // Note: For these two structs, we could also setup the data as a series of mappings, or as a combination between a struct and a bunch of mappings; worth exploring tradeoffs re:gas optimization

  // Looking players up can happen one of two ways;
  // 1. We use address lookup (as is being done here)
  // 2. We use token id lookup (not done here)
  // If we want _both_ mappings this is an option but we need to consider gas
  // mapping(address => uint256) public playerAddr2Id;
  // // Once we lookup a player, we start to index into character elements
  // // These rough structs could be broken down into smaller objects and mappings if needed.
  mapping(uint256 => Character) public characters;
  mapping(uint256 => Skeleton) public skeletons;
  mapping(uint256 => Outfit) public outfits;

  /**
   * @dev
   */
  constructor(
    ICore _core,
    SelectableOptions _selectableOptions,
    Authority auth
  ) Auth(msg.sender, auth) {
    core = _core;
    selectableOptions = _selectableOptions;
  }

  function setWearables(IWearables _wearables) external requiresAuth {
    wearables = _wearables;
  }

    function setDefaultDescription(string memory _description)
    public
    requiresAuth
  {
    _defaultDescription = _description;
  }

  function setDefaultName(string memory _name) public requiresAuth {
    _defaultName = _name;
  }


  function setCharacter(Character memory character, uint256 _id) public requiresAuth {
    characters[_id] = character;
  }

  
  function _setSkeletonSlot(
    uint16 slotID,
    Skeleton storage skeleton,
    uint32 value
  ) internal {
    if (slotID == 0) {
      // TODO: This needs to mint the collision not error
      skeleton.head = value;
    } else if (slotID == 1) {
      // require(skeleton.mouth == 0, "Slot must be empty to equip into");
      skeleton.mouth = value;
    } else if (slotID == 2) {
      // require(skeleton.eyes == 0, "Slot must be empty to equip into");
      skeleton.eyes = value;
    } else if (slotID == 3) {
      // require(skeleton.torso == 0, "Slot must be empty to equip into");
      skeleton.torso = value;
    } else if (slotID == 4) {
      // require(skeleton.lArm == 0, "Slot must be empty to equip into");
      skeleton.lArm = value;
    } else if (slotID == 5) {
      // require(skeleton.rArm == 0, "Slot must be empty to equip into");
      skeleton.rArm = value;
    } else if (slotID == 6) {
      // require(skeleton.rLeg == 0, "Slot must be empty to equip into");
      skeleton.rLeg = value;
    } else if (slotID == 7) {
      // require(skeleton.lLeg == 0, "Slot must be empty to equip into");
      skeleton.lLeg = value;
    } else if (slotID == 8) {
      // require(skeleton.color == 0, "Slot must be empty to equip into");
      skeleton.color = value;
    } else if (slotID == 9) {
      // require(skeleton.marking == 0, "Slot must be empty to equip into");
      skeleton.marking = value;
    } else if (slotID == 10) {
      // require(skeleton.crown == 0, "Slot must be empty to equip into");
      skeleton.crown = value;
    }
  }

  function _setOutfitSlot(
    uint16 slotID,
    Outfit storage outfit,
    uint32 value,
    address player
  ) internal {
    if (slotID == 0) {
      // TODO: This needs to mint the collision not error
      if(outfit.head != 0) {
        wearables.mintEquipment(player, outfit.head);
      }
      outfit.head = value;
    } else if (slotID == 1) {
      if(outfit.torso != 0) {
        wearables.mintEquipment(player, outfit.torso);
      }
      outfit.torso = value;
    } else if (slotID == 2) {
      if(outfit.lArm != 0) {
        wearables.mintEquipment(player, outfit.lArm);
      }
      outfit.lArm = value;
    } else if (slotID == 3) {
      if(outfit.rArm != 0) {
        wearables.mintEquipment(player, outfit.rArm);
      }
      outfit.rArm = value;
    } else if (slotID == 4) {
      if(outfit.rLeg != 0) {
        wearables.mintEquipment(player, outfit.rLeg);
      }
      outfit.rLeg = value;
    } else if (slotID == 5) {
      if(outfit.lLeg != 0) {
        wearables.mintEquipment(player, outfit.lLeg);
      }
      outfit.lLeg = value;
    } else if (slotID == 6) {
      if(outfit.floating != 0) {
        wearables.mintEquipment(player, outfit.floating);
      }
      outfit.floating = value;
    }
  }

  function setOutfitSlot(
    uint256 _characterID,
    uint16 slotID,
    uint32 value
  ) external onlyValidator {
    _setOutfitSlot(slotID, outfits[_characterID], value, characters[_characterID].player);
  }

  function setOutfit(uint256 _characterID, Outfit calldata outfit)
    external
    onlyValidator
  {
    outfits[_characterID] = outfit;
  }

  function setSkeleton(uint256 _characterID, Skeleton calldata skeleton)
    external
    onlyValidator
  {
    skeletons[_characterID] = skeleton;
  }

  // Todo: set auth
  function setValidator(address validator_) public requiresAuth {
    _validator = validator_;
  }

    function getSkeleton(uint256 tokenID)
    external
    view
    returns (Skeleton memory)
  {
    return skeletons[tokenID];
  }

  function getOutfit(uint256 tokenID) external view returns (Outfit memory) {
    return outfits[tokenID];
  }

  function getOptions(uint256 tokenID)
    external
    view
    returns (
      string memory form,
      string memory name,
      string memory origin,
      string memory upbringing,
      string memory gift,
      string memory faction,
      string memory color
    )
  {
    Character memory char = characters[tokenID];
    Skeleton memory skeleton = skeletons[tokenID];
    form = char.form;
    name = getName(tokenID);
    origin = char.origin;
    upbringing = char.upbringing;
    gift = char.gift;
    faction = char.faction;
    color = selectableOptions.getOptionStringFromId(skeleton.color);
  }

  function getDescription(uint256 tokenID)
    external
    view
    returns (string memory)
  {
    return
      _compareMem(characters[tokenID].description, "")
        ? _defaultDescription
        : characters[tokenID].description;
  }

  function getName(uint256 tokenID) public view returns (string memory) {
    return
      _compareMem(characters[tokenID].name, "")
        ? _defaultName
        : characters[tokenID].name;
  }


  function setName(uint256 tokenID, string calldata name) public {
    require(core.ownerOf(tokenID) == msg.sender, "Player must be holding character");
    characters[tokenID].name = name;
  }

  function getCharacter(uint256 tokenID)
    external
    view
    returns (Character memory)
  {
    return characters[tokenID];
  }

  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

    /**
   * @dev Do we want to make this validator protected? onlyValidator
   */
  // [0] = form
  // [1] = origin
  // [2] = upbringing
  // [3] = gift
  // [4] = faction
  function addPlayer(
    uint256 _id,
    string[] calldata traitsPlus
  ) external onlyValidator {
    // TODO: better checks here, probably don't want to fuck with like collisions or w/e here
    characters[_id] = Character(
      _id,
      msg.sender,
      CharacterLibraryV2.MAX_INT,
      "",
      "",
      traitsPlus[0],
      traitsPlus[1],
      traitsPlus[2],
      traitsPlus[3],
      traitsPlus[4]
    );
  }
}

// Player Information
struct Player {
  uint256 id;
}
// Character Information
// TODO: Confirm optimal struct ordering
struct Character {
  uint256 characterId;
  address player;
  uint256 class;
  string description;
  string name;
  string form;
  string origin;
  string upbringing;
  string gift;
  string faction;
}


// Note: We probably wantt o abstract out/push out the character logic from the validator logic and just have the single validator reach into the other state holding contracts
// Can we create the 1155 asset the first time we _unequip_ the 1155?
// TODO: Probably need to change this from a uint8, is 256 really enough?
// TODO: This should just be a fucking array? Am I crazy? That's more flexible
struct Skeleton {
  uint256 head;
  uint256 torso;
  uint256 lArm;
  uint256 rArm;
  uint256 lLeg;
  uint256 rLeg;
  uint256 mouth;
  uint256 eyes;
  uint256 color;
  uint256 marking;
  uint256 crown;
}
struct Outfit {
  uint256 head;
  uint256 torso;
  uint256 lArm;
  uint256 rArm;
  uint256 lLeg;
  uint256 rLeg;
  uint256 floating;
}

library CharacterLibraryV2 {
  uint256 public constant MAX_INT = 2**256 - 1;

  function getSkeletonSlot(uint256 slotID, Skeleton memory skeleton)
    public
    pure
    returns (uint256)
  {
    if (slotID == 0) {
      return skeleton.head;
    } else if (slotID == 1) {
      return skeleton.torso;
    } else if (slotID == 2) {
      return skeleton.lArm;
    } else if (slotID == 3) {
      return skeleton.rArm;
    } else if (slotID == 4) {
      return skeleton.lLeg;
    } else if (slotID == 5) {
      return skeleton.rLeg;
    } else if (slotID == 6) {
      return skeleton.mouth;
    } else if (slotID == 7) {
      return skeleton.eyes;
    } else if (slotID == 8) {
      return skeleton.color;
    } else if (slotID == 9) {
      return skeleton.marking;
    } else if (slotID == 10) {
      return skeleton.crown;
    }
    return MAX_INT;
  }

  function getOutfitSlot(uint256 slotID, Outfit memory outfit)
    public
    pure
    returns (uint256)
  {
    if (slotID == 0) {
      return outfit.head;
    } else if (slotID == 1) {
      return outfit.torso;
    } else if (slotID == 2) {
      return outfit.lArm;
    } else if (slotID == 3) {
      return outfit.rArm;
    } else if (slotID == 4) {
      return outfit.lLeg;
    } else if (slotID == 5) {
      return outfit.rLeg;
    } else if (slotID == 6) {
      return outfit.floating;
    }
    return MAX_INT;
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
// Note: This is a really heavy contract to implement directly. We want more of a centralized approach here
import "../interfaces/ICore.sol";
import "../interfaces/IWearables.sol";
import "./SelectableOptions.sol";
import "../lib/CharacterLibrary.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

// Note: try to minimize the contract depth that mutative actions have to take

contract Characters is Context, Auth {
  // Instance of core
  ICore public core;
  IWearables public wearables;
  SelectableOptions public selectableOptions;
  uint256 private _nextId = 0;
  address private _validator;
  string private _defaultDescription;
  string private _defaultName;

  // Need to replace with the solmate access control
  modifier onlyWearables() {
    require(address(wearables) == msg.sender, "WEARABLES");
    _;
  }
  modifier onlyValidator() {
    require(address(_validator) == msg.sender, "VALIDATOR");
    _;
  }

  // Note: For these two structs, we could also setup the data as a series of mappings, or as a combination between a struct and a bunch of mappings; worth exploring tradeoffs re:gas optimization

  // Looking players up can happen one of two ways;
  // 1. We use address lookup (as is being done here)
  // 2. We use token id lookup (not done here)
  // If we want _both_ mappings this is an option but we need to consider gas
  mapping(address => uint256) public playerAddr2Id;
  // Once we lookup a player, we start to index into character elements
  // These rough structs could be broken down into smaller objects and mappings if needed.
  mapping(uint256 => Character) public characters;
  mapping(uint256 => Skeleton) public skeletons;
  mapping(uint256 => Outfit) public outfits;

  /**
   * @dev
   */
  constructor(
    ICore _core,
    SelectableOptions _selectableOptions,
    Authority auth
  ) Auth(msg.sender, auth) {
    core = _core;
    selectableOptions = _selectableOptions;
  }

  function setWearables(IWearables _wearables) external requiresAuth {
    wearables = _wearables;
  }


  /**
   * @dev Do we want to make this validator protected? onlyValidator
   */
  // [0] = form
  // [1] = origin
  // [2] = upbringing
  // [3] = gift
  // [4] = faction
  function addPlayer(
    uint256 _id,
    address _player,
    uint256[] calldata legacyPills,
    uint256[] calldata collabPills,
    string[] calldata traitsPlus
  ) public {
    // TODO: better checks here, probably don't want to fuck with like collisions or w/e here
    require(core.ownerOf(_id) == _player, "Player must be holding character");
    playerAddr2Id[_player] = _id;
    characters[_id] = Character(
      _id,
      _player,
      CharacterLibrary.MAX_INT,
      "",
      "",
      traitsPlus[0],
      traitsPlus[1],
      traitsPlus[2],
      traitsPlus[3],
      traitsPlus[4],
      legacyPills,
      collabPills
    );
  }

  function removePlayer(uint256 _id, address _player) public {
    // Give removing player XP
    // Reset the removed players XP
    playerAddr2Id[_player] = CharacterLibrary.MAX_INT;
  }

  function setDefaultDescription(string memory _description)
    public
    requiresAuth
  {
    _defaultDescription = _description;
  }

  function setDefaultName(string memory _name) public requiresAuth {
    _defaultName = _name;
  }

  /**
   * @dev
   */
  function setPlayer(uint256 _id, address _player) external {
    require(core.ownerOf(_id) == _player, "Player must be holding character");
    require(
      playerAddr2Id[_player] != CharacterLibrary.MAX_INT,
      "Player must not have a character already"
    );
    playerAddr2Id[_player] = _id;
  }

  function setCharacter(Character memory character, uint256 _id) public requiresAuth {
    characters[_id] = character;
  }

  function equipSkeleton(
    uint32 id,
    uint16 slotID,
    address _player
  ) external requiresAuth {
    _setSkeletonSlot(slotID, skeletons[getIdFromAddress(_player)], id);
  }

  function equipOutfit(
    uint32 id,
    uint16 slotID,
    address _player
  ) external requiresAuth {
    _setOutfitSlot(slotID, outfits[getIdFromAddress(_player)], id, _player);
  }

  function unequipSkeleton(uint16 slotID, address _player)
    external
    requiresAuth
    returns (uint256 returnID)
  {
    Skeleton storage skeleton = skeletons[getIdFromAddress(_player)];
    returnID = CharacterLibrary.getSkeletonSlot(slotID, skeleton);
    _setSkeletonSlot(slotID, skeleton, 0);
  }

  function unequipOutfit(uint16 slotID, address _player)
    external
    requiresAuth
    returns (uint256 returnID)
  {
    Outfit storage outfit = outfits[getIdFromAddress(_player)];
    returnID = CharacterLibrary.getOutfitSlot(slotID, outfit);
    _setOutfitSlot(slotID, outfit, 0, _player);
    wearables.mintEquipment(_player, returnID);
  }

  function _setSkeletonSlot(
    uint16 slotID,
    Skeleton storage skeleton,
    uint32 value
  ) internal {
    if (slotID == 0) {
      // TODO: This needs to mint the collision not error
      skeleton.head = value;
    } else if (slotID == 1) {
      // require(skeleton.mouth == 0, "Slot must be empty to equip into");
      skeleton.mouth = value;
    } else if (slotID == 2) {
      // require(skeleton.eyes == 0, "Slot must be empty to equip into");
      skeleton.eyes = value;
    } else if (slotID == 3) {
      // require(skeleton.torso == 0, "Slot must be empty to equip into");
      skeleton.torso = value;
    } else if (slotID == 4) {
      // require(skeleton.lArm == 0, "Slot must be empty to equip into");
      skeleton.lArm = value;
    } else if (slotID == 5) {
      // require(skeleton.rArm == 0, "Slot must be empty to equip into");
      skeleton.rArm = value;
    } else if (slotID == 6) {
      // require(skeleton.rLeg == 0, "Slot must be empty to equip into");
      skeleton.rLeg = value;
    } else if (slotID == 7) {
      // require(skeleton.lLeg == 0, "Slot must be empty to equip into");
      skeleton.lLeg = value;
    } else if (slotID == 8) {
      // require(skeleton.color == 0, "Slot must be empty to equip into");
      skeleton.color = value;
    } else if (slotID == 9) {
      // require(skeleton.marking == 0, "Slot must be empty to equip into");
      skeleton.marking = value;
    } else if (slotID == 10) {
      // require(skeleton.crown == 0, "Slot must be empty to equip into");
      skeleton.crown = value;
    }
  }

  function _setOutfitSlot(
    uint16 slotID,
    Outfit storage outfit,
    uint32 value,
    address player
  ) internal {
    if (slotID == 0) {
      // TODO: This needs to mint the collision not error
      if(outfit.head != 0) {
        wearables.mintEquipment(player, outfit.head);
      }
      outfit.head = value;
    } else if (slotID == 1) {
      if(outfit.torso != 0) {
        wearables.mintEquipment(player, outfit.torso);
      }
      outfit.torso = value;
    } else if (slotID == 2) {
      if(outfit.lArm != 0) {
        wearables.mintEquipment(player, outfit.lArm);
      }
      outfit.lArm = value;
    } else if (slotID == 3) {
      if(outfit.rArm != 0) {
        wearables.mintEquipment(player, outfit.rArm);
      }
      outfit.rArm = value;
    } else if (slotID == 4) {
      if(outfit.rLeg != 0) {
        wearables.mintEquipment(player, outfit.rLeg);
      }
      outfit.rLeg = value;
    } else if (slotID == 5) {
      if(outfit.lLeg != 0) {
        wearables.mintEquipment(player, outfit.lLeg);
      }
      outfit.lLeg = value;
    } else if (slotID == 6) {
      if(outfit.floating != 0) {
        wearables.mintEquipment(player, outfit.floating);
      }
      outfit.floating = value;
    }
  }

  function setOutfitSlot(
    uint256 _characterID,
    uint16 slotID,
    uint32 value
  ) external onlyValidator {
    _setOutfitSlot(slotID, outfits[_characterID], value, characters[_characterID].player);
  }

  function setOutfit(uint256 _characterID, Outfit calldata outfit)
    external
    onlyValidator
  {
    outfits[_characterID] = outfit;
  }

  function setSkeleton(uint256 _characterID, Skeleton calldata skeleton)
    external
    onlyValidator
  {
    skeletons[_characterID] = skeleton;
  }

  // Todo: set auth
  function setValidator(address validator_) public requiresAuth {
    _validator = validator_;
  }

  function getSkeleton(uint256 tokenID)
    external
    view
    returns (Skeleton memory)
  {
    return skeletons[tokenID];
  }

  function getOutfit(uint256 tokenID) external view returns (Outfit memory) {
    return outfits[tokenID];
  }

  function getOptions(uint256 tokenID)
    external
    view
    returns (
      string memory form,
      string memory name,
      string memory origin,
      string memory upbringing,
      string memory gift,
      string memory faction,
      string memory color
    )
  {
    Character memory char = characters[tokenID];
    Skeleton memory skeleton = skeletons[tokenID];
    form = char.form;
    name = getName(tokenID);
    origin = char.origin;
    upbringing = char.upbringing;
    gift = char.gift;
    faction = char.faction;
    color = selectableOptions.getOptionStringFromId(skeleton.color);
  }

  function getDescription(uint256 tokenID)
    external
    view
    returns (string memory)
  {
    return
      _compareMem(characters[tokenID].description, "")
        ? _defaultDescription
        : characters[tokenID].description;
  }

  function getName(uint256 tokenID) public view returns (string memory) {
    return
      _compareMem(characters[tokenID].name, "")
        ? _defaultName
        : characters[tokenID].name;
  }


  function setName(uint256 tokenID, string calldata name) public {
    require(core.ownerOf(tokenID) == msg.sender, "Player must be holding character");
    characters[tokenID].name = name;
  }

  function getCharacter(uint256 tokenID)
    external
    view
    returns (Character memory)
  {
    return characters[tokenID];
  }

  function getIdFromAddress(address _addr) public view returns (uint256) {
    return playerAddr2Id[_addr];
  }

  // TODO: Put this somewhere better plx; memory vs calldata mismatch
  function _compareMem(string memory a, string memory b)
    internal
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }
}

pragma solidity ^0.8.0;
import "../characters/Characters.sol";

// Mocked endpoint for all of the basic distro flows
// In production this will be three seperate contracts, so build accordingly.
// This contract is simply meant to provide a clean mocked version of the primary endpointss
// needed for the basic distribution apps. Some functions _may_ change slightly, but generally
// integrating based on these mocks should allow us to integrate the completed contracts with little to no friction
// and provide a more stable, modular and accesible testing option for front-end testing.

contract CharacterGenMock is Characters {
  constructor(
    ICore _core,
    SelectableOptions _selectableOptions,
    Authority auth
  ) Characters(_core, _selectableOptions, auth) {}

  function equipOutfitAdmin(
    uint16 slotID,
    uint32 id,
    address _player
  ) external requiresAuth {
    _setOutfitSlot(slotID, outfits[getIdFromAddress(_player)], id, _player);
  }

  function equipSkeletonAdmin(
    uint16 slotID,
    uint32 id,
    address _player
  ) external requiresAuth {
    _setSkeletonSlot(slotID, skeletons[getIdFromAddress(_player)], id);
  }
}

// SPDX-License-Identifier: AGPL-3.0

import "../../interfaces/ICharacter.sol";
import "../../interfaces/IXferHook.sol";

pragma solidity ^0.8.0;

contract CharacterXfer is IXferHook {
  ICharacter private _character;

  constructor(ICharacter character_) {
    _character = character_;
  }

  function xferHook(
    address from,
    address,
    uint256 id
  ) external override {
    _character.removePlayer(id, from);
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

interface IXferHook {
  function xferHook(
    address from,
    address to,
    uint256 id
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0

import "../../interfaces/ICharacter.sol";
import "../../interfaces/IXferHook.sol";

pragma solidity ^0.8.0;

contract BalanceHook is IXferHook {
  ICharacter private _character;

  mapping(address => uint256[]) private _balance;
  mapping(uint256 => uint256) private _idIndex;


  function getTokens(address player) public view returns (uint256[] memory) {
    return _balance[player];
  }

  function xferHook(
    address from,
    address to,
    uint256 id
  ) external override {
    if(from == address(0)) {
      _balance[to].push(id);
      _idIndex[id] = _balance[to].length - 1;
    } else if(to == address(0)) {
      uint256 index = _idIndex[id];
      _balance[from][index] = _balance[from][_balance[from].length - 1];
    } else {
      _balance[to].push(id);
      _idIndex[id] = _balance[to].length - 1;
      uint256 index = _idIndex[id];
      _balance[from][index] = _balance[from][_balance[from].length - 1];
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Experiment with solmate 721?
import "../tokens/abstract/ERC721.sol";
import "../interfaces/IMintValidator721.sol";
import "../interfaces/IXferHook.sol";
import "../interfaces/IFabricator721.sol";
import "../interfaces/IReadMetadata.sol";

import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title Core721
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details//Interface
contract Core721 is Context, ERC721, IFabricator721, Auth {
  using Strings for uint256;
  event Validator(IMintValidator721 indexed validator, bool indexed active);

  mapping(IMintValidator721 => bool) public isValidator;
  mapping(IMintValidator721 => uint256[]) public validatorToIds;
  mapping(uint256 => address) public override idToValidator;
  mapping(uint256 => uint256) public override quantityMinted;
  mapping(uint256 => address) public idToTransferHook;
  // URI base; NOT the whole uri.
  string private _baseURI;
  IReadMetadata private _registry;

  /**
   * @dev intializes the core ERC1155 logic, and sets the original URI base
   */
  constructor(
    string memory baseUri_,
    IReadMetadata registry_,
    Authority authority
  ) ERC721("PILLS AVATARS", "AVAPILL") Auth(msg.sender, authority) {
    _registry = registry_;
    _baseURI = baseUri_;
  }

  modifier onlyValidator() {
    bool isActive = isValidator[IMintValidator721(msg.sender)];
    require(isActive, "VALIDATOR_INACTIVE");
    _;
  }

  /**
   * @dev query URI for a token Id. Queries the Metadata registry on the backend
   */
  function uri(uint256 _id) public view returns (string memory) {
    // Use the underlying metadata contract?
    return string(abi.encodePacked(_baseURI, _id.toString()));
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setBaseURI(string calldata _newBaseUri) external requiresAuth {
    _baseURI = _newBaseUri;
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setNewRegistry(IReadMetadata registry_) external requiresAuth {
    _registry = registry_;
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addValidator(IMintValidator721 _validator, uint256[] memory ids)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(!isActive, "VALIDATOR_ACTIVE");
    for (uint256 i; i < ids.length; i++) {
      require(idToValidator[ids[i]] == address(0x0), "INVALID_VALIDATOR_IDS");
      idToValidator[ids[i]] = address(_validator);
    }
    isValidator[_validator] = true;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addTransferHook(IXferHook hooker, uint256[] memory ids)
    external
    virtual
    requiresAuth
  {
    for (uint256 i; i < ids.length; i++) {
      require(idToTransferHook[ids[i]] == address(0x0), "INVALID_HOOK_IDS");
      idToTransferHook[ids[i]] = address(hooker);
    }
  }

  /**
   * @dev Remove Validators that are no longer needed to remove attack surfaces
   */
  function removeValidator(IMintValidator721 _validator)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_validator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(0x0);
    }
    isValidator[_validator] = false;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Upgrade the validator responsible for a certain
   */
  function upgradeValidator(
    IMintValidator721 _oldValidator,
    IMintValidator721 _newValidator
  ) external virtual requiresAuth {
    bool isActive = isValidator[_oldValidator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_oldValidator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(_newValidator);
    }
    isValidator[_oldValidator] = false;
    emit Validator(_oldValidator, !isActive);
    isValidator[_newValidator] = true;
    emit Validator(_newValidator, !isActive);
  }

  /**
   * @dev Mint mulitiple tokens at different quantities. This is an requiresAuth
          function and is meant basically as a sudo-command. Auth should be 
   */
  function mint(
    address _to,
    uint256 _id,
    bytes memory _data
  ) external virtual requiresAuth {
    _safeMint(_to, _id, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintInit(
    uint256 _dropId,
    address _to,
    bytes memory _data,
    address _validator,
    string calldata _metadata
  ) public virtual override {
    IMintValidator721 validator = IMintValidator721(_validator);
    require(isValidator[validator], "BAD_VALIDATOR");
    validator.validate(_to, _dropId, _metadata, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintCallback(
    address recipient,
    uint256 _id,
    bytes calldata _data
  ) public virtual override onlyValidator {
    require(idToValidator[_id] == address(msg.sender), "INVALID_MINT");
    _safeMint(recipient, _id, _data);
  }

  // OPTIMIZATION: No need for numbers to be readable, so this could be optimized
  // but gas cost here doesn't matter so we go for the standard approach
  function tokenURI(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, _id.toString()));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 id
  ) internal override {
    if (idToTransferHook[id] != address(0x0)) {
      IXferHook(idToTransferHook[id]).xferHook(from, to, id);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
  /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 id) public virtual {
    address owner = ownerOf[id];

    require(
      msg.sender == owner || isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    require(from == ownerOf[id], "WRONG_FROM");

    require(
      msg.sender == from ||
        msg.sender == getApproved[id] ||
        isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );
    _beforeTokenTransfer(from, to, id);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;

      balanceOf[to]++;
    }

    ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "INVALID_RECIPIENT");

    require(ownerOf[id] == address(0), "ALREADY_MINTED");
    _beforeTokenTransfer(address(0), to, id);

    // Counter overflow is incredibly unrealistic.
    unchecked {
      balanceOf[to]++;
    }

    ownerOf[id] = to;

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = ownerOf[id];

    require(ownerOf[id] != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner, address(0), id);

    // Ownership check above ensures no underflow.
    unchecked {
      balanceOf[owner]--;
    }

    delete ownerOf[id];

    delete getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          ""
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          data
        ) ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

interface IMintValidator721 {
  function validate(
    address _recipient,
    uint256 _dropId,
    string calldata _metadata,
    bytes memory _data
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "./IMintValidator721.sol";

interface IFabricator721 {
  function modularMintInit(
    uint256 _dropId,
    address _to,
    bytes memory _data,
    address _validator,
    string calldata _metadata
  ) external;

  function modularMintCallback(
    address recipient,
    uint256 _id,
    bytes memory _data
  ) external;

  function quantityMinted(uint256 collectibleId) external returns (uint256);

  function idToValidator(uint256 collectibleId) external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IReadMetadata {
  function get(uint256 _id) external view returns (string memory metadata);
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";
import "../interfaces/IReadMetadata.sol";

// write interface for
//Interface

contract Core is Context, ERC1155Burnable, Ownable, IFabricator {
  event Validator(IMintValidator indexed validator, bool indexed active);

  mapping(IMintValidator => bool) public isValidator;
  mapping(IMintValidator => uint256[]) public validatorToIds;
  mapping(uint256 => address) public override idToValidator;
  mapping(uint256 => uint256) public override quantityMinted;
  // URI base; NOT the whole uri.
  string private _uri;
  IReadMetadata private _registry;

  /**
   * @dev intializes the core ERC1155 logic, and sets the original URI base
   */
  constructor(string memory baseUri_, IReadMetadata registry_)
    ERC1155(baseUri_)
  {
    _registry = registry_;
    _uri = baseUri_;
  }

  modifier onlyValidator() {
    bool isActive = isValidator[IMintValidator(msg.sender)];
    require(isActive, "VALIDATOR_INACTIVE");
    _;
  }

  /**
   * @dev query URI for a token Id. Queries the Metadata registry on the backend
   */
  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_uri, _registry.get(_id)));
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    _setURI(_newBaseUri);
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setNewRegistry(IReadMetadata registry_) external onlyOwner {
    _registry = registry_;
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addValidator(IMintValidator _validator, uint256[] memory ids)
    external
    virtual
    onlyOwner
  {
    bool isActive = isValidator[_validator];
    require(!isActive, "VALIDATOR_ACTIVE");
    for (uint256 i; i < ids.length; i++) {
      require(idToValidator[ids[i]] == address(0x0), "INVALID_VALIDATOR_IDS");
      idToValidator[ids[i]] = address(_validator);
    }
    isValidator[_validator] = true;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Remove Validators that are no longer needed to remove attack surfaces
   */
  function removeValidator(IMintValidator _validator)
    external
    virtual
    onlyOwner
  {
    bool isActive = isValidator[_validator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_validator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(0x0);
    }
    isValidator[_validator] = false;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Upgrade the validator responsible for a certain
   */
  function upgradeValidator(
    IMintValidator _oldValidator,
    IMintValidator _newValidator
  ) external virtual onlyOwner {
    bool isActive = isValidator[_oldValidator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_oldValidator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(_newValidator);
    }
    isValidator[_oldValidator] = false;
    emit Validator(_oldValidator, !isActive);
    isValidator[_newValidator] = true;
    emit Validator(_newValidator, !isActive);
  }

  /**
   * @dev Mint mulitiple tokens at different quantities. This is an onlyOwner-guareded
          function and is meant basically as a sudo-command.
   */
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external virtual onlyOwner {
    _mintBatch(_to, _ids, _amounts, _data);
    _updateMintedQuantities(_ids, _amounts);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintInit(
    uint256 _dropId,
    address _to,
    uint256[] memory _requestedAmounts,
    bytes memory _data,
    IMintValidator _validator,
    string calldata _metadata
  ) public virtual override {
    require(isValidator[_validator], "BAD_VALIDATOR");
    _validator.validate(_to, _dropId, _requestedAmounts, _metadata, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintCallback(
    address recipient,
    uint256[] calldata _ids,
    uint256[] calldata _requestedAmounts,
    bytes calldata _data
  ) public virtual override onlyValidator {
    for (uint256 i; i < _ids.length; i++) {
      require(idToValidator[_ids[i]] == address(msg.sender), "INVALID_MINT");
    }
    _mintBatch(recipient, _ids, _requestedAmounts, _data);
    _updateMintedQuantities(_ids, _requestedAmounts);
  }

  function _updateMintedQuantities(
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    require(_ids.length == _amounts.length, "MINT_QUANTITY_MISMATCH");
    for (uint256 i = 0; i < _ids.length; i++) {
      quantityMinted[_ids[i]] += _amounts[i];
    }
  }

  function _updateMintedQuantity(uint256 _id, uint256 _amount) internal {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;
    _updateMintedQuantities(ids, amounts);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Basic1155 is ERC1155 {
  constructor() ERC1155("") {}

  function mint(
    uint256 id,
    address target,
    uint256 amount
  ) public {
    _mint(target, id, amount, "");
  }
}

// SPDX-License-Identifier: AGPL-3.0

// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Compiler will pack this into a single 256bit word.
  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
  }

  // Compiler will pack this into a single 256bit word.
  struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
  }

  // The tokenId of the next token to be minted.
  uint256 internal _currentIndex;

  // The number of tokens burned.
  uint256 internal _burnCounter;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) internal _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _currentIndex = _startTokenId();
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
   */
  function totalSupply() public view returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than _currentIndex - _startTokenId() times
    unchecked {
      return _currentIndex - _burnCounter - _startTokenId();
    }
  }

  /**
   * Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view returns (uint256) {
    // Counter underflow is impossible as _currentIndex does not decrement,
    // and it is initialized to _startTokenId()
    unchecked {
      return _currentIndex - _startTokenId();
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return uint256(_addressData[owner].balance);
  }

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    if (owner == address(0)) revert MintedQueryForZeroAddress();
    return uint256(_addressData[owner].numberMinted);
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    if (owner == address(0)) revert BurnedQueryForZeroAddress();
    return uint256(_addressData[owner].numberBurned);
  }

  /**
   * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    if (owner == address(0)) revert AuxQueryForZeroAddress();
    return _addressData[owner].aux;
  }

  /**
   * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal {
    if (owner == address(0)) revert AuxQueryForZeroAddress();
    _addressData[owner].aux = aux;
  }

  /**
   * Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around in the collection over time.
   */
  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    uint256 curr = tokenId;

    unchecked {
      if (_startTokenId() <= curr && curr < _currentIndex) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (!ownership.burned) {
          if (ownership.addr != address(0)) {
            return ownership;
          }
          // Invariant:
          // There will always be an ownership that has an address and is not burned
          // before an ownership that does not have an address and is not burned.
          // Hence, curr will not underflow.
          while (true) {
            curr--;
            ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
              return ownership;
            }
          }
        }
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    _transfer(from, to, tokenId);
    if (
      to.isContract() &&
      !_checkContractOnERC721Received(from, to, tokenId, _data)
    ) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return
      _startTokenId() <= tokenId &&
      tokenId < _currentIndex &&
      !_ownerships[tokenId].burned;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    _mint(to, quantity, _data, true);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 quantity,
    bytes memory _data,
    bool safe
  ) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
    // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
    unchecked {
      _addressData[to].balance += uint64(quantity);
      _addressData[to].numberMinted += uint64(quantity);

      _ownerships[startTokenId].addr = to;
      _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

      uint256 updatedIndex = startTokenId;
      uint256 end = updatedIndex + quantity;

      if (safe && to.isContract()) {
        do {
          emit Transfer(address(0), to, updatedIndex);
          if (
            !_checkContractOnERC721Received(
              address(0),
              to,
              updatedIndex++,
              _data
            )
          ) {
            revert TransferToNonERC721ReceiverImplementer();
          }
        } while (updatedIndex != end);
        // Reentrancy protection
        if (_currentIndex != startTokenId) revert();
      } else {
        do {
          emit Transfer(address(0), to, updatedIndex++);
        } while (updatedIndex != end);
      }
      _currentIndex = updatedIndex;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      isApprovedForAll(prevOwnership.addr, _msgSender()) ||
      getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    // Underflow of the sender"s balance is impossible because we check for
    // ownership above and the recipient"s balance can"t realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;

      _ownerships[tokenId].addr = to;
      _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

      // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId < _currentIndex) {
          _ownerships[nextTokenId].addr = prevOwnership.addr;
          _ownerships[nextTokenId].startTimestamp = prevOwnership
            .startTimestamp;
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    // Underflow of the sender"s balance is impossible because we check for
    // ownership above and the recipient"s balance can"t realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      _addressData[prevOwnership.addr].balance -= 1;
      _addressData[prevOwnership.addr].numberBurned += 1;

      // Keep track of who burned the token, and the timestamp of burning.
      _ownerships[tokenId].addr = prevOwnership.addr;
      _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
      _ownerships[tokenId].burned = true;

      // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId < _currentIndex) {
          _ownerships[nextTokenId].addr = prevOwnership.addr;
          _ownerships[nextTokenId].startTimestamp = prevOwnership
            .startTimestamp;
        }
      }
    }

    emit Transfer(prevOwnership.addr, address(0), tokenId);
    _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try
      IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
    returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`"s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   * And also called after one token has been burned.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`"s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IFabricator.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title RaffleValidator
/// @author Ping
/// @notice Handles minting of PortalPills using either a direct sale, or raffle dependant on parcipants. In order to deposit, the signer must provide sign-off on your account.
/// @dev Explain to a developer any extra details
contract RaffleValidator is VRFConsumerBaseV2, Auth {
  VRFCoordinatorV2Interface private _coordinator;
  // WL SIGNING STATE
  // Everything for the WL signing
  // process.
  // In order to "Whitelist" somebody the validation signer
  // account has to sign on behalf of the account being whitelisted.
  // This Signature then needs to be provided along with the deposit in order
  // for the participant to add a deposit to the raffle.
  // Triggering the "whitelist disabled" circumvents this behavior.
  using ECDSA for bytes32;
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }
  struct Target {
    uint256 chainId;
    address wallet;
  }
  bytes32 private immutable _domainSeparator;
  bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
  bytes32 private constant _TARGET_TYPEHASH =
    keccak256("Target(uint256 chainId,address wallet)");
  address private _validationSigner;

  // RAFFLE STATE
  uint256 private _tokenId;
  // Core instannce to eventuall mind the tokens to
  IFabricator public core;
  uint256 private _raffleCost;
  // Count of how many winners have already been selected
  uint256 private _winnersSelected;
  // Flag to prevent multiple randomness requests at once
  bool private _awaitingRandomness;
  address[] private _raffleTickets;
  // Basic boolean state handlers
  // Whether the raffle has concluded
  bool private _raffleEnded;
  // True if there were enough participants to run the raffle
  bool private _runRaffle;
  bool private _whitelistDisabled;
  // Total number of entries needed to trigger a raffle
  uint32 private immutable _raffleTrigger;
  mapping(address => uint256) public count;
  mapping(address => bool) public hasWon;
  mapping(address => bool) public hasClaimed;

  // RANDOMNESS STATE
  // TODO: Setup setters/getters for this
  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 public callbackGasLimit = 100000;
  // The default is 3, but you can set this higher.
  uint16 public requestConfirmations = 3;
  event RequestId(bytes32 requestId);
  uint64 public subscriptionId;
  bytes32 private _keyHash;

  constructor(
    IFabricator _core,
    address coordinator_,
    address signer_,
    uint256 raffleCost_,
    uint256 id,
    Authority auth,
    uint32 raffleTrigger_
  )
    VRFConsumerBaseV2(
      coordinator_ // VRF Coordinator
    )
    Auth(msg.sender, auth)
  {
    _tokenId = id;
    _raffleCost = raffleCost_;
    _coordinator = VRFCoordinatorV2Interface(coordinator_);
    core = _core;
    _validationSigner = signer_;
    _raffleTrigger = raffleTrigger_;
    _domainSeparator = _hashDomain(
      EIP712Domain({
        name: "SYNTH Validator",
        version: "1",
        chainId: _getChainID(),
        verifyingContract: address(this)
      })
    );
    //Create a new subscription when you deploy the contract.
  }

  // DEPOSIT FUNCTIONS

  /// @notice Deposit funds into the raffle.
  /// @param recipient A Target structure containing a wallet and chain ID for the whitelisted account
  /// @param v recovery identifier
  /// @param r signature part 1
  /// @param s signature part 2
  function addDeposit(
    Target calldata recipient,
    uint8 v,
    bytes32 r,
    bytes32 s // bytes calldata signature
  ) external payable {
    require(msg.value > _raffleCost, "Sorry, that's not enough for the raffle");
    require(!_raffleEnded, "Sorry raffle has ended");
    address signatureSigner = _hash(recipient).recover(v, r, s);
    require(signatureSigner == _validationSigner, "Invalid Signature");
    // prevent replay
    require(recipient.chainId == _getChainID(), "Invalid chainId");
    uint256 ticketCount = msg.value / _raffleCost;
    unchecked {
      for (uint8 i; i < ticketCount; i++) {
        _raffleTickets.push(recipient.wallet);
      }
      count[recipient.wallet] += ticketCount;
    }
  }

  /// @notice Adds a deposit without whitelist
  /// @param recipient target address to give raffle tickets to
  function addDepositNoWL(address recipient) external payable {
    require(!_raffleEnded, "Sorry raffle has ended");
    require(_whitelistDisabled, "Sorry, whitelist is enabled");
    uint256 ticketCount = msg.value / _raffleCost;
    unchecked {
      for (uint8 i; i < ticketCount; i++) {
        _raffleTickets.push(recipient);
      }
      count[recipient] += ticketCount;
    }
  }

  /// @notice Refund a series of raffle tickets
  /// @dev Neccesary to know what indices the tickets were added into
  /// @param indices List of tickets to refund
  function removeDeposits(uint256[] calldata indices) external {
    require(!hasWon[msg.sender], "Sorry, no refunds for winners");
    unchecked {
      for (uint8 i; i < indices.length; i++) {
        _removeDeposit(indices[i]);
      }
    }
    uint256 baseCost = indices.length * _raffleCost;
    uint256 returnValue = _raffleEnded ? baseCost - _raffleCost : baseCost;
    (bool success, ) = msg.sender.call{value: returnValue}("");
    require(success, "Transfer failed.");
  }

  // CLAIM FUNCTIONS

  /// @notice Gives the raffle winner their portalpill
  /// @dev Explain to a developer any extra details
  /// @param winner Account to claim winning portalpills to
  function claim(address winner) external {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    require(hasWon[winner], "Can only claim for winners");
    require(!hasClaimed[winner], "Can only claim once");
    idReturn[0] = _tokenId;
    quantityReturn[0] = 1;
    core.modularMintCallback(winner, idReturn, quantityReturn, "");
    hasClaimed[winner] = true;
  }

  /// @notice If raffle doesn't run, allows direct redemption of portalpills
  /// @dev Explain to a developer any extra details
  function directClaim() external {
    require(
      _runRaffle == false && _raffleEnded == true,
      "Direct claim only valid if raffle didn't run"
    );
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    require(!hasClaimed[msg.sender], "Can only claim once");
    idReturn[0] = _tokenId;
    quantityReturn[0] = count[msg.sender];
    core.modularMintCallback(msg.sender, idReturn, quantityReturn, "");
    hasClaimed[msg.sender] = true;
  }

  // ADMIN FUNCTIONS

  function endRaffle() external requiresAuth {
    if (_raffleTickets.length > _raffleTrigger) {
      _runRaffle = true;
    }
    _raffleEnded = true;
  }

  function disableWhitelist() external requiresAuth {
    _whitelistDisabled = true;
  }

  function setChainlink(
    bytes32 keyHash_,
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint64 _subscriptionId
  ) public requiresAuth {
    _keyHash = keyHash_;
    callbackGasLimit = _callbackGasLimit;
    requestConfirmations = _requestConfirmations;
    subscriptionId = _subscriptionId;
  }

  /// @notice Called from Admin to process _count winners in the raffle.
  /// @dev Explain to a developer any extra details
  /// @param _count Number of winners to select
  function processRaffle(uint32 _count) public requiresAuth {
    require(_runRaffle, "Must have enough to run raffle");
    require(
      _winnersSelected + _count <= _raffleTrigger,
      "Too many winners would be selected"
    );
    require(
      _awaitingRandomness == false,
      "Wait until randomness has been processed to request more"
    );
    _coordinator.requestRandomWords(
      _keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      _count
    );
    _awaitingRandomness = true;
  }

  /// INTERNAL FUNCTIONS

  function _hash(Target memory recipient) internal view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          _domainSeparator,
          _hashRecipient(recipient)
        )
      );
  }

  function _hashRecipient(Target memory recipient)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(_TARGET_TYPEHASH, recipient.chainId, recipient.wallet)
      );
  }

  function _removeDeposit(uint256 index) internal {
    require(
      msg.sender == _raffleTickets[index],
      "Sorry you're requesting a refund for a ticket you didn't buy"
    );
    count[msg.sender] -= 1;
    _raffleTickets[index] = _raffleTickets[_raffleTickets.length - 1];
    _raffleTickets.pop();
  }

  // Extract eip721 into abstraction
  function _hashDomain(EIP712Domain memory eip712Domain)
    private
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          _EIP712_DOMAIN_TYPEHASH,
          keccak256(bytes(eip712Domain.name)),
          keccak256(bytes(eip712Domain.version)),
          eip712Domain.chainId,
          eip712Domain.verifyingContract
        )
      );
  }

  function _getChainID() private view returns (uint256) {
    uint256 id;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      id := chainid()
    }
    return id;
  }

  // solhint-disable-next-line
  function fulfillRandomWords(uint256, uint256[] memory randomWords)
    internal
    override
  {
    require(_awaitingRandomness == true, "Must trigger processRaffle first");
    // TODO: Confirm abscence of over/under flow states
    for (uint8 i; i < randomWords.length; i++) {
      uint256 winner = ((randomWords[i] % _raffleTickets.length) -
        _winnersSelected) + _winnersSelected;
      if (hasWon[_raffleTickets[winner]]) {
        _raffleTickets[winner] = _raffleTickets[_raffleTickets.length - 1];
        _raffleTickets.pop();
      } else {
        _raffleTickets[_winnersSelected] = _raffleTickets[winner];
        _winnersSelected++;
        hasWon[_raffleTickets[winner]] = true;
      }
    }
    _awaitingRandomness == false;
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../interfaces/IInbox.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "../chainlink/VRFRequester.sol";
import "../chainlink/VRFConsumerLite.sol";

contract RandomnessRelayL2 is Auth, VRFRequester {
  address private _l1Target;
  IInbox private _inbox;
  uint256 private _requestIDs;
  mapping(uint256 => address) private _idToAddr;

  event RetryableTicketCreated(uint256 indexed ticketId);

  constructor(
    address l1Target_,
    address inbox_,
    Authority authority
  ) Auth(msg.sender, authority) {
    _l1Target = l1Target_;
    _inbox = IInbox(inbox_);
  }

  function updateL2Target(address l1Target_) external requiresAuth {
    _l1Target = l1Target_;
  }

  /// @notice only l1Target can update greeting
  function requestRandomness(uint32 wordCount)
    external
    override
    requiresAuth
    returns (uint256 requestId)
  {
    unchecked {
      _requestIDs++;
    }
    _idToAddr[_requestIDs] = msg.sender;
    // Send randomness request to ranomness relay on L1 including word count and requestID
  }

  // This is the function that should be called from the L1 to give the randomness back
  function fulfillRandomness(uint256 requestId, uint32[] memory randomWords)
    external
    requiresAuth
  {
    VRFConsumerLite(_idToAddr[requestId]).fulfillRandomWords(
      requestId,
      randomWords
    );
  }
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
  function sendL2Message(bytes calldata messageData) external returns (uint256);

  function sendUnsignedTransaction(
    uint256 maxGas,
    uint256 gasPriceBid,
    uint256 nonce,
    address destAddr,
    uint256 amount,
    bytes calldata data
  ) external returns (uint256);

  function sendContractTransaction(
    uint256 maxGas,
    uint256 gasPriceBid,
    address destAddr,
    uint256 amount,
    bytes calldata data
  ) external returns (uint256);

  function sendL1FundedUnsignedTransaction(
    uint256 maxGas,
    uint256 gasPriceBid,
    uint256 nonce,
    address destAddr,
    bytes calldata data
  ) external payable returns (uint256);

  function sendL1FundedContractTransaction(
    uint256 maxGas,
    uint256 gasPriceBid,
    address destAddr,
    bytes calldata data
  ) external payable returns (uint256);

  function createRetryableTicket(
    address destAddr,
    uint256 arbTxCallValue,
    uint256 maxSubmissionCost,
    address submissionRefundAddress,
    address valueRefundAddress,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes calldata data
  ) external payable returns (uint256);

  function depositEth(uint256 maxSubmissionCost)
    external
    payable
    returns (uint256);

  function bridge() external view returns (IBridge);

  function pauseCreateRetryables() external;

  function unpauseCreateRetryables() external;

  function startRewriteAddress() external;

  function stopRewriteAddress() external;
}

pragma solidity ^0.8.0;

interface VRFRequester {
  function requestRandomness(uint32 wordCount)
    external
    returns (uint256 requestId);
}

pragma solidity ^0.8.0;

interface VRFConsumerLite {
  function fulfillRandomWords(uint256 requestId, uint32[] memory randomWords)
    external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IBridge {
  event MessageDelivered(
    uint256 indexed messageIndex,
    bytes32 indexed beforeInboxAcc,
    address inbox,
    uint8 kind,
    address sender,
    bytes32 messageDataHash
  );

  event BridgeCallTriggered(
    address indexed outbox,
    address indexed destAddr,
    uint256 amount,
    bytes data
  );

  event InboxToggle(address indexed inbox, bool enabled);

  event OutboxToggle(address indexed outbox, bool enabled);

  function deliverMessageToInbox(
    uint8 kind,
    address sender,
    bytes32 messageDataHash
  ) external payable returns (uint256);

  function executeCall(
    address destAddr,
    uint256 amount,
    bytes calldata data
  ) external returns (bool success, bytes memory returnData);

  // These are only callable by the admin
  function setInbox(address inbox, bool enabled) external;

  function setOutbox(address inbox, bool enabled) external;

  // View functions

  function activeOutbox() external view returns (address);

  function allowedInboxes(address inbox) external view returns (bool);

  function allowedOutboxes(address outbox) external view returns (bool);

  function inboxAccs(uint256 index) external view returns (bytes32);

  function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IMessageProvider {
  event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

  event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../interfaces/IInbox.sol";
import "../interfaces/IOutbox.sol";
import "../interfaces/IBridge.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "../chainlink/VRFRequesterL1.sol";

contract RandomnessRelay is Auth, VRFRequesterL1 {
  VRFCoordinatorV2Interface private _coordinator;
  LinkTokenInterface private _linkToken;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 _keyHash =
    0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 _wordsPerCall = 2;

  // Storage parameters
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public subID;
  address _owner;

  address public l2Target;
  IInbox public inbox;

  event RetryableTicketCreated(uint256 indexed ticketId);

  constructor(
    address _l2Target,
    address _inbox,
    Authority authority
  ) Auth(msg.sender, authority) {
    l2Target = _l2Target;
    inbox = IInbox(_inbox);
  }

  function updateL2Target(address _l2Target) public {
    l2Target = _l2Target;
  }

  /// @notice only l2Target can update greeting
  function requestRandomness(uint256 requestId) public override {
    requestId = _coordinator.requestRandomWords(
      _keyHash,
      subID,
      requestConfirmations,
      callbackGasLimit,
      _wordsPerCall
    );
  }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.0;

interface IOutbox {
  event OutboxEntryCreated(
    uint256 indexed batchNum,
    uint256 outboxEntryIndex,
    bytes32 outputRoot,
    uint256 numInBatch
  );
  event OutBoxTransactionExecuted(
    address indexed destAddr,
    address indexed l2Sender,
    uint256 indexed outboxEntryIndex,
    uint256 transactionIndex
  );

  function l2ToL1Sender() external view returns (address);

  function l2ToL1Block() external view returns (uint256);

  function l2ToL1EthBlock() external view returns (uint256);

  function l2ToL1Timestamp() external view returns (uint256);

  function l2ToL1BatchNum() external view returns (uint256);

  function l2ToL1OutputId() external view returns (bytes32);

  function processOutgoingMessages(
    bytes calldata sendsData,
    uint256[] calldata sendLengths
  ) external;

  function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

pragma solidity ^0.8.0;

interface VRFRequesterL1 {
  function requestRandomness(uint256 requestId) external;
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "../interfaces/IInbox.sol";
import "../interfaces/IOutbox.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/IMintValidator721.sol";

contract L1Mint {
  /*address public l2Target;
    IInbox public inbox;

    event RetryableTicketCreated(uint256 indexed ticketId);

    constructor(
        address _l2Target,
        address _inbox
    ) public Greeter(_greeting) {
        l2Target = _l2Target;
        inbox = IInbox(_inbox);
    }

    function updateL2Target(address _l2Target) public {
        l2Target = _l2Target;
    }

    function setGreetingInL2(
        string memory _greeting,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        bytes memory data = abi.encodeWithSelector(Greeter.setGreeting.selector, _greeting);
        uint256 ticketID = inbox.createRetryableTicket{ value: msg.value }(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        emit RetryableTicketCreated(ticketID);
        return ticketID;
    }

    /// @notice only l2Target can update greeting
    function setGreeting(string memory _greeting) public override {
        IBridge bridge = inbox.bridge();
        // this prevents reentrancies on L2 to L1 txs
        require(msg.sender == address(bridge), "NOT_BRIDGE");
        IOutbox outbox = IOutbox(bridge.activeOutbox());
        address l2Sender = outbox.l2ToL1Sender();
        require(l2Sender == l2Target, "Greeting only updateable by L2");

        Greeter.setGreeting(_greeting);
    } */
}

// SPDX-License-Identifier: AGPL-3.0

// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/*
https://docs.chain.link/docs/vrf-contracts/#configurations
*/
contract VRFv2SubscriptionManager {
  VRFCoordinatorV2Interface public coordinator;
  LinkTokenInterface public link;

  // Storage parameters
  uint256[] private _randomWords;
  uint64 private _subscriptionId;
  address private _owner;

  constructor(address _coordinator, address _link) {
    coordinator = VRFCoordinatorV2Interface(_coordinator);
    link = LinkTokenInterface(_link);
    _owner = msg.sender;
    //Create a new subscription when you deploy the contract.
    _createNewSubscription();
  }

  // Create a new subscription when the contract is initially deployed.
  function _createNewSubscription() private onlyOwner {
    // Create a subscription with a new subscription ID.
    _subscriptionId = coordinator.createSubscription();
    // Add this contract as a consumer of its own subscription.
    coordinator.addConsumer(_subscriptionId, address(this));
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription(uint256 amount) external onlyOwner {
    link.transferAndCall(
      address(coordinator),
      amount,
      abi.encode(_subscriptionId)
    );
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    // Add a consumer contract to the subscription.
    coordinator.addConsumer(_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    coordinator.removeConsumer(_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    coordinator.cancelSubscription(_subscriptionId, receivingWallet);
    _subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    link.transfer(to, amount);
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
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
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

import "@openzeppelin/contracts/access/AccessControl.sol";

// Dev Note: collapse these down into composable interfaces?
interface IAttribute {
  function attribute(uint256 characterId) external view returns (uint256);

  function adjustAttribute(uint256 newAttribute, uint256 characterId) external;

  function name() external view returns (string memory);

  function getURI() external view returns (uint256);
}

// Generics pattern? Right now having these general shapes that
// apply to both ITrait and IAttribute is clunky, but the string vs uint difference
// means we can't really collapse these into a single interface, think through a better pattern
interface ITrait {
  function trait(uint256 characterId) external view returns (string memory);

  function adjustTrait(string memory newTrait, uint256 characterId) external;

  function name() external view returns (string memory);

  // What are the use cases where we need this on the trait interface?
  // Are there other things we need for this interface?
  function getURI() external view returns (uint256);
}

contract Attributes is AccessControl {
  // Attributes Variables

  // Array representation of all attributes
  uint256 private _attributeCount;
  mapping(uint256 => IAttribute) private _attributesIndex;
  // Mapping from the "name" of the attribute to the "property" of the attribute.
  mapping(string => IAttribute) private _attributesMap;
  // Mapping from the "name" of the attribute to whether the attribute already exists on this character.
  mapping(string => bool) private _attributesAdded;

  bytes32 public constant ATTRIBUTE_ADDER = keccak256("ATTRIBUTE_ADDER");
  bytes32 public constant TRAIT_ADDER = keccak256("TRAIT_ADDER");

  // Note: Can we reduce these redundant mappings? There has to be a better way to store/access this information or something lighter.
  // What about a mapping from string to uint256 or something, that should be less storage, although it's two reads.

  // Array representation of all traits
  uint256 private _traitCount;

  // Philosophy: What is the actual difference between a trait and an attribute? Can we just store these as a single thing?

  // We may want this to be enum, how are we accessing this?
  mapping(uint256 => ITrait) private _traitsIndex;
  // Mapping from the "name" of the trait to the "property" of the trait.
  mapping(string => ITrait) private _traitsMap;
  // Mapping from the "name" of the attribute to whether the trait already exists on this character.
  mapping(string => bool) private _traitsAdded;

  /**
   * @dev
   */
  function attachTrait(ITrait trait) external {
    require(
      hasRole(TRAIT_ADDER, msg.sender),
      "Caller is not a valid attibute adder"
    );
    require(
      _traitsAdded[trait.name()],
      "Attribute already exists on character"
    );
    _traitsAdded[trait.name()] = true;
    _traitsMap[trait.name()] = trait;
    _traitsIndex[_traitCount] = trait;
    _traitCount += 1;
  }

  /**
   * @dev
   */
  function attachAttribute(IAttribute attribute) external {
    require(
      hasRole(TRAIT_ADDER, msg.sender),
      "Caller is not a valid attibute adder"
    );
    require(
      _traitsAdded[attribute.name()],
      "Attribute already exists on character"
    );
    _attributesAdded[attribute.name()] = true;
    _attributesMap[attribute.name()] = attribute;
    _attributesIndex[_attributeCount] = attribute;
    _attributeCount += 1;
  }

  /**
   * @dev
   */
  function getAttribute(string calldata name)
    external
    view
    returns (IAttribute)
  {
    return _attributesMap[name];
  }

  function getAttribute(uint256 index) external view returns (IAttribute) {
    return _attributesIndex[index];
  }

  function getTrait(string calldata name) external view returns (ITrait) {
    return _traitsMap[name];
  }

  function getIndex(uint256 index) external view returns (ITrait) {
    return _traitsIndex[index];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// lift up this zeppelin util for use in our tests
contract CollectibleHolder is ERC1155Holder {

}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "../tokens/ERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";
import "../registries/MetadataRegistry.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

// write interface for
//Interface

contract Core1155 is Context, ERC1155, Auth, IFabricator {
  event Validator(IMintValidator indexed validator, bool indexed active);

  mapping(IMintValidator => bool) public isValidator;
  mapping(IMintValidator => uint256[]) public validatorToIds;
  mapping(uint256 => address) public override idToValidator;
  mapping(uint256 => uint256) public override quantityMinted;
  // URI base; NOT the whole uri.
  string private _uri;
  IReadMetadata private _registry;

  /**
   * @dev intializes the core ERC1155 logic, and sets the original URI base
   */
  constructor(
    string memory baseUri_,
    IReadMetadata registry_,
    Authority authority
  ) ERC1155(baseUri_) Auth(msg.sender, authority) {
    _registry = registry_;
    _uri = baseUri_;
  }

  modifier onlyValidator() {
    bool isActive = isValidator[IMintValidator(msg.sender)];
    require(isActive, "VALIDATOR_INACTIVE");
    _;
  }

  /**
   * @dev query URI for a token Id. Queries the Metadata registry on the backend
   */
  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(_uri, _registry.get(_id)));
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setBaseURI(string calldata _newBaseUri) external requiresAuth {
    _setURI(_newBaseUri);
  }

  /**
   * @dev change the URI base address after construction.
   */
  function setNewRegistry(IReadMetadata registry_) external requiresAuth {
    _registry = registry_;
  }

  /**
   * @dev An active Validator is necessary to enable `modularMint`
   */
  function addValidator(IMintValidator _validator, uint256[] memory ids)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(!isActive, "VALIDATOR_ACTIVE");
    for (uint256 i; i < ids.length; i++) {
      require(idToValidator[ids[i]] == address(0x0), "INVALID_VALIDATOR_IDS");
      idToValidator[ids[i]] = address(_validator);
    }
    isValidator[_validator] = true;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Remove Validators that are no longer needed to remove attack surfaces
   */
  function removeValidator(IMintValidator _validator)
    external
    virtual
    requiresAuth
  {
    bool isActive = isValidator[_validator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_validator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(0x0);
    }
    isValidator[_validator] = false;
    emit Validator(_validator, !isActive);
  }

  /**
   * @dev Upgrade the validator responsible for a certain
   */
  function upgradeValidator(
    IMintValidator _oldValidator,
    IMintValidator _newValidator
  ) external virtual requiresAuth {
    bool isActive = isValidator[_oldValidator];
    require(isActive, "VALIDATOR_INACTIVE");
    uint256[] memory ids = validatorToIds[_oldValidator];
    for (uint256 i; i < ids.length; i++) {
      idToValidator[ids[i]] = address(_newValidator);
    }
    isValidator[_oldValidator] = false;
    emit Validator(_oldValidator, !isActive);
    isValidator[_newValidator] = true;
    emit Validator(_newValidator, !isActive);
  }

  /**
   * @dev Mint mulitiple tokens at different quantities. This is an onlyOwner-guareded
          function and is meant basically as a sudo-command.
   */
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external virtual requiresAuth {
    _mintBatch(_to, _ids, _amounts, _data);
    _updateMintedQuantities(_ids, _amounts);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintInit(
    uint256 _dropId,
    address _to,
    uint256[] memory _requestedAmounts,
    bytes memory _data,
    IMintValidator _validator,
    string calldata _metadata
  ) public virtual override {
    require(isValidator[_validator], "BAD_VALIDATOR");
    _validator.validate(_to, _dropId, _requestedAmounts, _metadata, _data);
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintCallback(
    address recipient,
    uint256[] calldata _ids,
    uint256[] calldata _requestedAmounts,
    bytes calldata _data
  ) public virtual override onlyValidator {
    for (uint256 i; i < _ids.length; i++) {
      require(idToValidator[_ids[i]] == address(msg.sender), "INVALID_MINT");
    }
    _mintBatch(recipient, _ids, _requestedAmounts, _data);
    _updateMintedQuantities(_ids, _requestedAmounts);
  }
  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *      At least one Validator must be active in order to utilized this interface.
   */
  function modularMintCallbackSingle(
    address recipient,
    uint256 _id,
    bytes calldata _data
  ) public virtual onlyValidator {
      require(idToValidator[_id] == address(msg.sender), "INVALID_MINT");
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = 1;
    _mintBatch(recipient, ids, amounts, _data);
    _updateMintedQuantities(ids, amounts);
  }

  function _updateMintedQuantities(
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    require(_ids.length == _amounts.length, "MINT_QUANTITY_MISMATCH");
    for (uint256 i = 0; i < _ids.length; i++) {
      quantityMinted[_ids[i]] += _amounts[i];
    }
  }

  function _updateMintedQuantity(uint256 _id, uint256 _amount) internal {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;
    _updateMintedQuantities(ids, amounts);
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;
//pragma abicoder v2;

import "@rari-capital/solmate/src/auth/Auth.sol";
import "../interfaces/IReadMetadata.sol";

contract MetadataRegistry is IReadMetadata, Auth {
  event Register(uint256 id, string metadata);
  event UnRegister(uint256 id);

  mapping(uint256 => string) public idToMetadata;

  constructor(Authority auth) Auth(msg.sender, auth) {}

  function set(uint256 _id, string calldata _metadata) public requiresAuth {
    idToMetadata[_id] = _metadata;
    emit Register(_id, _metadata);
  }

  function get(uint256 _id)
    public
    view
    override
    returns (string memory metadata)
  {
    metadata = idToMetadata[_id];
    require(bytes(metadata).length > 0, "MISSING_URI");
  }

  function setMultiple(uint256[] calldata _ids, string[] calldata _metadatas)
    external
    requiresAuth
  {
    require(_ids.length == _metadatas.length, "SET_MULTIPLE_LENGTH_MISMATCH");
    for (uint256 i = 0; i < _ids.length; i++) {
      set(_ids[i], _metadatas[i]);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";

/// @title CheckerValidator
/// @notice Validator is meant to check whether or not a specific NFT is held, and then spit out a corrsponding NFT.
///         For our use case we use it to allow people with a legacy pill to receive a portalpill. Main issues we've seen so far with this
///         has been in tracking
/// @dev Plz don't use this it's not meant for you
contract CheckerValidator is Context, IMintValidator {
  // This is the token we "check" against. Understand that the collection you're point this to
  // has a tremendous amount of control over the token ID this checker instance is registered with in core
  IERC1155 public originalToken;
  uint256 immutable _newId;
  // initialize with token and track state there
  mapping(uint256 => bool) public redeemed;
  mapping(address => uint256) public remaining;
  // This is the instance of core we call home to for the minty minty
  IFabricator public core;

  /// @param _core we use this to trigger the token mints
  /// @param _original Token whose balance we check for mints; implier 1;1 1155s plzz
  /// @param newId_ This ID must be registered in core, 1155s of the old system will
  constructor(
    IFabricator _core,
    IERC1155 _original,
    uint256 newId_
  ) {
    _newId = newId_;
    core = _core;
    originalToken = _original;
  }

  function checkAllRedemption(uint256[] calldata ids)
    external
    view
    returns (bool[] memory)
  {
    bool[] memory redemptionStatus = new bool[](ids.length);
    for (uint256 i = 0; i < redemptionStatus.length; i++) {
      redemptionStatus[i] = _checkRedemption(ids[i]);
    }
    return redemptionStatus;
  }

  function _checkRedemption(uint256 id) internal view returns (bool) {
    return redeemed[id];
  }

  function redeemAll(uint256[] calldata ids) public {
    for (uint256 i = 0; i < ids.length; i++) {
      _redeem(ids[i], _msgSender());
    }
    _validate(_msgSender());
  }

  function _redeem(uint256 id, address target) internal {
    require(
      originalToken.balanceOf(target, id) > 0,
      "Sender must hold all tokens for migration"
    );
    require(redeemed[id] == false, "Token has already been redeemed");
    redeemed[id] = true;
    remaining[target] += 1;
  }

  function validate(
    address _recipient,
    uint256, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    _validate(_recipient);
  }

  function _validate(address _recipient) internal {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = _newId;
    quantityReturn[0] = remaining[_recipient];
    remaining[_recipient] = 0;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMintValidator.sol";

contract MerkleValidator is Ownable, IMintValidator {
  struct Drop {
    bytes32 _merkleRoot;
    uint16 _blocks;
    uint64 _endTime;
  }

  mapping(uint256 => Drop) public drops;
  mapping(uint256 => bool) public claimed;

  // This is a pull only pattern?
  function validate(
    address, /* _operator*/
    uint256, /* _dropId*/
    uint256[] memory, /*_requestedQty*/
    string calldata, /*  _metadata*/
    bytes memory /* _data*/
  ) external pure override {
    // 0: validate that blocknumber or timestamp have not passed
    // 1. lookup merkle root and ensure drop is valid
    // 2. generate hash using input params
    // 3. verify hash
    // 4. mark as claimed? probably better to check this on the token contract
    // 5. Trigger callback function
  }

  function seedAllocations(
    uint256 _dropKey,
    bytes32 _merkleRoot,
    uint16 _blocks,
    uint64 _endTime
  ) external onlyOwner {
    require(drops[_dropKey]._merkleRoot == bytes32(0), "cannot rewrite a drop");
    drops[_dropKey] = Drop(_merkleRoot, _blocks, _endTime);
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;
// Is there a better MerkleProof library?
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";
// Replace with solmate auth? Maybe we make it ownable _by_ an auth instance
import "@openzeppelin/contracts/access/Ownable.sol";

// note: add auth structure, needs to use a commit reveal pattern
/*
  We create a drop that will allow users to deposit funds in order to receive raffle tickets.
  At the end of the drop some of the people get a token, others don't.
*/
contract AuctionValidator is IMintValidator, Ownable {
  uint256 public depositCost = 8;
  struct Drop {
    uint256 collectibleId;
    uint128 quantityAvailable;
    uint64 startTime;
    uint64 endTime;
    // do we want a start block?
    uint64 endBlock;
    bytes32 acceptedBid;
  }

  mapping(uint256 => Drop) public drops;

  IFabricator public core;
  // Is it okay to have this universal? Do we need to bundle this into the drop struct?
  // We handle this by mapping a _hash_ of dropID and bidder
  mapping(bytes32 => uint256) public bids;

  constructor(IFabricator _core) {
    core = _core;
  }

  function getBid(uint256 _dropID, address bidder)
    external
    view
    returns (uint256)
  {
    bytes32 hashIndex = keccak256(abi.encodePacked(_dropID, bidder));
    return bids[hashIndex];
  }

  function addBid(uint256 _dropID, address bidder) external payable {
    Drop storage drop = drops[_dropID];
    require(
      msg.value > depositCost,
      "Sorry, that's not enough for the deposit"
    );
    // TODO: Consolidate these to save gas when we don't need seperate errors for testing?
    require(block.timestamp > drop.startTime, "SEQ_DROP_TIME_EARLY");
    require(block.timestamp <= drop.endTime, "SEQ_DROP_TIME_EXPIRED");
    require(block.number <= drop.endBlock, "SEQ_DROP_BLOCK_PASSED");
    // Use dropID + bidder to form primary key for bid
    bytes32 hashIndex = keccak256(abi.encodePacked(_dropID, bidder));
    bids[hashIndex] += msg.value;
    // Raffle tickets can only be acquired during the drop time

    // If the auction is close to ending extend it (fuck off frontrunners < 3)
    if (drop.endTime - block.timestamp < 300) {
      drop.endTime = 300;
    }
  }

  function setWinner(uint256 _dropID, address bidder) external onlyOwner {
    Drop storage drop = drops[_dropID];
    require(block.timestamp > drop.endTime, "SEQ_DROP_TIME_EARLY");
    require(drop.acceptedBid == 0, "Winner can only be set once");
    bytes32 hashIndex = keccak256(abi.encodePacked(_dropID, bidder));
    drop.acceptedBid = hashIndex;
  }

  function claimAuction(uint256 _dropID) external {
    _claimAuction(_dropID, msg.sender);
  }

  function validate(
    address _recipient,
    uint256 _dropID, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    _claimAuction(_dropID, _recipient);
  }

  function _claimAuction(uint256 _dropID, address _recipient) internal {
    Drop memory drop = drops[_dropID];
    bytes32 hashIndex = keccak256(abi.encodePacked(_dropID, _recipient));
    uint256 minBid = bids[drop.acceptedBid];
    uint256 userBid = bids[hashIndex];
    require(
      userBid >= minBid,
      "Sorry your bid is not a winner bb, get ur weight up"
    );
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = drop.collectibleId;
    quantityReturn[0] = 1;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }

  function createDrop(
    uint256 _collectibleId,
    uint16 _quantityAvailable,
    uint64 _startTime,
    uint64 _endTime,
    uint16 _endBlock
  ) external {
    /*
     1. ?split startId in type and index
     2.
     */
    require(
      drops[_collectibleId].collectibleId == 0,
      "SEQ_DROP_DUPLICATE_DROP"
    );
    require(
      core.idToValidator(_collectibleId) == address(this),
      "Stop hitting yourself"
    );
    drops[_collectibleId] = Drop(
      _collectibleId,
      _quantityAvailable,
      _startTime,
      _endTime,
      _endBlock,
      0
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC677Receiver.sol";

// lift up this zeppelin util for use in our tests
contract LinkMock is ERC20 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data
  );

  function mint(address account, uint256 amount) external virtual {
    _mint(account, amount);
  }

  constructor(string memory name_, string memory symbol_)
    ERC20(name_, symbol_)
  {}

  //ERC677 functions

  /**
   * @dev transfer token to a contract address with additional data if the recipient is a contact.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   * @param _data The extra data to be passed to the receiving contract.
   */
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes memory _data
  ) public returns (bool success) {
    super.transfer(_to, _value);
    emit Transfer(msg.sender, _to, _value, _data);
    if (_isContract(_to)) {
      _contractFallback(_to, _value, _data);
    }
    return true;
  }

  // PRIVATE

  function _contractFallback(
    address _to,
    uint256 _value,
    bytes memory _data
  ) private {
    IERC677Receiver receiver = IERC677Receiver(_to);
    receiver.onTokenTransfer(msg.sender, _value, _data);
  }

  function _isContract(address _addr) private view returns (bool hasCode) {
    uint256 length;
    assembly {
      length := extcodesize(_addr)
    }
    return length > 0;
  }
}

pragma solidity ^0.8.0;

interface IERC677Receiver {
  function onTokenTransfer(
    address _sender,
    uint256 _value,
    bytes memory _data
  ) external;
}

import "../../interfaces/IAttribute.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// What are the tradeoffs of having many contracts (one level contract per player) vs 1 contract (one level contract period)
// The assumption is this is going to be much more fuel efficient on _access_ but less eficient on _creation_
// Where do we make compromises for creation time vs access time?
contract Level is IAttribute, ERC20 {
  // Not sure the URI is actually needed? What are we using this for?
  uint256 public uri = 10;

  // This needs to be exploded out into it's own ERC20
  uint256 public currentXP = 100;

  uint256 public currentLvl = 1;

  uint256 public lastTime = 0;

  uint256 public maxXPDaily = 10;

  uint256[] public requiredXp;
  uint256 private _dripRate;
  uint256 private _maxAmount;
  IERC20 private _requiredToken;

  uint256 private constant _BASE = 10000;

  mapping(address => bool) private _senderWhitelist;

  mapping(address => uint256) private _balances;

  // EXP calculations per level are handled off-chain, and updated
  constructor(
    uint256[] memory _requiredXp,
    IERC20 requiredToken_,
    uint256 maxAmount_,
    uint256 dripRate_
  ) ERC20("Level", "LVL") {
    _dripRate = dripRate_;
    lastTime = block.timestamp;
    requiredXp = _requiredXp;
    _maxAmount = maxAmount_;
    _requiredToken = requiredToken_;
  }

  function stake(uint256 amount) external {
    _accrueXP();
    require(
      _balances[msg.sender] + amount <= _maxAmount,
      "Sorry that exceeds the max staking amount"
    );
    _balances[msg.sender] += amount;
    _requiredToken.transferFrom(msg.sender, address(this), amount);
  }

  function unstake(uint256 amount) external {
    _accrueXP();
    _requiredToken.transferFrom(address(this), msg.sender, amount);
    _balances[msg.sender] -= amount;
  }

  function getURI() external view override returns (uint256) {
    return uri;
  }

  function attribute() external view override returns (uint256) {
    return currentLvl;
  }

  function adjustAttribute(uint256 newAttribute) external override {
    _accrueXP();
  }

  // Obviously needs permissions
  // Need to make it so that we can make this append only
  function setXPRequiremenets(uint256[] memory _requiredXp) external {
    requiredXp = _requiredXp;
  }

  function setSpecificLevel(uint256 newRequirement, uint256 index) external {
    requiredXp[index] = newRequirement;
  }

  function _accrueXP() internal {
    uint256 timePassed = block.timestamp - lastTime;
    // Make this calculation more precise; I think we're "shaving off" some of the XP so to speak; maybe that's just tought titties
    // (Balance of sender * total time passed sincce last accrual in blocks * drip rate) /
    currentXP +=
      (_balances[msg.sender] * (timePassed * _dripRate) * _BASE) /
      (_maxAmount * _BASE);
    // I think this accounts for the lost precision but double-check plz
    lastTime = block.timestamp;
  }

  // Need to tweak this; as this stands if we change XP requirements the level will be maintained
  // What's the desired result if we change the XP requirements? Should people be able to lose levels? Probably not, that sounds lame
  function level() public {
    _accrueXP();
    // Should revert if the player doesn't have sufficient XP
    currentXP -= requiredXp[currentLvl];
    currentLvl += 1;
  }

  function getLevel() public {}

  function _beforeTokenTransfer(
    address from,
    address,
    uint256
  ) internal view override {
    require(_senderWhitelist[from] == true, "Sender must be whitelisted");
  }
}

// Dev Note: collapse these down into composable interfaces?
interface IAttribute {
  function attribute() external view returns (uint256);

  function adjustAttribute(uint256 newAttribute) external;

  function getURI() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "../interfaces/IMintPipe.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title AirdropValidator
/// @notice Validator is meant to check whether or not a specific NFT is held, and then spit out a corrsponding NFT.
///         For our use case we use it to allow people with a legacy pill to receive a portalpill. Main issues we've seen so far with this
///         has been in tracking
/// @dev Plz don't use this it's not meant for you
contract AirdropValidator is Auth {
  // This is the token we "check" against. Understand that the collection you're point this to
  // has a tremendous amount of control over the token ID this checker instance is registered with in core

  // This is the instance of core we call home to for the minty minty
  IMintPipe public core;

  /// @param _core we use this to trigger the token mints
  constructor(
    IMintPipe _core,
    Authority authority
  ) Auth(msg.sender, authority) {
    core = _core;
  }

  function setCore(IMintPipe _core) public requiresAuth {
    core = _core;
  }


  // Assumes _recipient and _amounts are the same length
  function drop(address[] calldata _recipient, uint256[] calldata  _amounts, uint256 id) external requiresAuth {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = id;
    for (uint256 index = 0; index < _recipient.length; index++) {
      quantityReturn[0] = _amounts[index];
      core.modularMintCallback(_recipient[index], idReturn, quantityReturn, "");      
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "../interfaces/IMintPipe.sol";
import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";

/// @title AggregateValidator
/// @notice Basic validator allows several other validators to create tokens based on role authorities
/// @dev Plz don't use this it's not meant for you
contract AggregateValidator is IMintValidator, Auth, IMintPipe {
  uint256 private immutable _id;
  // This is the instance of core we call home to for the minty minty
  IFabricator public core;
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public perTxLimit;

  /// @param _core we use this to trigger the token mints
  /// @param id_ This ID must be registered in core, this is the ID that portalpills will mint into
  /// @param _supply This is the total supply of tokens that will be minted
  constructor(
    IFabricator _core,
    uint256 id_,
    uint256 _supply,
    Authority authority
  ) Auth(msg.sender, authority) {
    _id = id_;
    core = _core;
    totalSupply = _supply;
    perTxLimit = totalSupply;
  }

  /// @notice DO NOT USE
  /// @dev prevents calls from the main core instance since this validation requires payments
  function validate(
    address,
    uint256, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    revert("Use payable validator");
  }

  /// @notice Sets a limit on the number of pills that can be purchased in a single transaction
  /// @param limit New token limit per transaction
  function newLimit(uint256 limit) external requiresAuth {
    require(limit < totalSupply, "Limit must be under supply total");
    perTxLimit = limit;
  }

  /// @notice Sets a limit on the total number of pills that can be purchased
  /// @param supply New token limit per transaction
  function newSupply(uint256 supply) external requiresAuth {
    require(supply < totalSupply, "Supply must be under supply total");
    totalSupply = supply;
  }

  function modularMintCallback(
    address recipient,
    uint256[] memory _ids,
    uint256[] memory _requestedAmounts,
    bytes memory _data
  ) external override requiresAuth {
    core.modularMintCallback(recipient, _ids, _requestedAmounts, _data);
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";

// A validator that always prints 1 collectible of given ID
// For Testing only
contract BasicValidator is IMintValidator {
  uint256 private _id;
  IFabricator public watcher;

  constructor(uint256 id_, IFabricator _watcher) {
    _id = id_;
    watcher = _watcher;
  }

  function validate(
    address recipient,
    uint256, /* _dropId*/
    uint256[] memory quantities, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = _id;
    quantityReturn[0] = quantities[0];
    watcher.modularMintCallback(recipient, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

//                       .,,,,.
//               ,(%%%%%%%%%%%%%%%%%%#,
//           .#%%%%%%%%%%%%%%%%%%%%%%%%%%#,
//         (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(.
//       (%%%%%%%%%%%%%%%%%%%%%%%#*,,*/#%%%%%%%*
//     ,%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,*#%%%%%(.
//    *%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,*#%%%%%*
//   ,%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,/%%%%%(.
//   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,*#%%%%%*
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,,/%%%%%(.
//   (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,,,*#%%%%%*
//   *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,,,(%%%%%#.
//    (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,,,(%%%%%%*
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,,,,,,,,,,,,,*%%%&&&#.
//      *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,,,,,,,,,,,*%&&&==&*
//        (%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,,,,,,,*#&=====(.
//          *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,,,,,,,,,,,/%=====&*
//            .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%/,,,,,,,,,,,,/%&=====#.
//               *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%#*,,,,,,,,,,,*#======&*
//                 .(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&=====&%(,,,,,,,,,,,*#%======#.
//                    *%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&===========%/,,,,,,,,,,,(%======&*
//                      .(%%%%%%%%%%%%%%%%%%%%&&&&&================&#*,,,,,,,,,,/%=======#.
//                         *%%%%%%%%%%%%%%%&&&&&&=====================%(,,,,,,,,,,*%&======&*
//                           .(%%%%%%%%%%&&&&&==========================&%/,,,,,,,,,*%========/
//                              *%%%%%&&&&&&===============================%#*,,,,,,,,(%=======%,
//                                .(&&&&&=====================================%#*,,,,,*%&=======&,
//                                  *%==========================================&%%##%==========%,
//                                     .(=========================================================(
//                                        *%======================================================%.
//                                          .(====================================================#.
//                                             *%=================================================(
//                                               .(==============================================%.
//                                                  *%==========================================&,
//                                                    .(=======================================%.
//                                                       *%===================================*
//                                                         .(==============================%,
//                                                            .(&=======================#,
//                                                                ,(%&===========%#*

import "../interfaces/IMintValidator.sol";
import "../interfaces/IFabricator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PaymentValidator
/// @notice Basic validator that takes payment in ETH and mints out an mount of tokens in the initialized ID
/// @dev Plz don't use this it's not meant for you
contract PaymentValidator is IMintValidator, Ownable {
  uint256 private immutable _id;
  // This is the instance of core we call home to for the minty minty
  IFabricator public core;
  uint256 private _cost;
  uint256 public totalSupply;
  uint256 public totalMinted;
  uint256 public perTxLimit;

  /// @param _core we use this to trigger the token mints
  /// @param id_ This ID must be registered in core, this is the ID that portalpills will mint into
  /// @param cost_ Cost in WEI (ETH) required _per 1155_
  constructor(
    IFabricator _core,
    uint256 id_,
    uint256 cost_,
    uint256 _supply
  ) {
    _id = id_;
    core = _core;
    _cost = cost_;
    totalSupply = _supply;
    perTxLimit = totalSupply;
  }

  /// @notice DO NOT USE
  /// @dev prevents calls from the main core instance since this validation requires payments
  function validate(
    address,
    uint256, /* _dropId*/
    uint256[] calldata, /* _qty*/
    string calldata, /* _metadata*/
    bytes memory /* _data*/
  ) external override {
    revert("Use payable validator");
  }

  /// @notice Purchase PortalPills directly
  /// @param _recipient Target account to receieve the purchased Portal Pills
  /// @param _qty Number of PortalPills to purchase
  function directSale(address _recipient, uint256 _qty) external payable {
    uint256 newTotal;
    require(_qty <= perTxLimit, "Not enough supply");
    // Quantity + total minted will never overflow
    unchecked {
      newTotal = _qty + totalMinted;
    }
    require(newTotal <= totalSupply, "Not enough supply");
    require(msg.value / _cost >= _qty, "Sorry not enough ETH provided");
    _validate(_recipient, _qty);
    totalMinted = newTotal;
  }

  /// @notice Collects and sends an amount of ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  /// @param value Amount of ETH (in wei) to transfer
  function collectEth(address target, uint256 value) external onlyOwner {
    _sendEth(target, value);
  }

  /// @notice Sets a limit on the number of pills that can be purchased in a single transaction
  /// @param limit New token limit per transaction
  function newLimit(uint256 limit) external onlyOwner {
    require(limit < totalSupply, "Limit must be under supply total");
    perTxLimit = limit;
  }

  /// @notice Collects all ETH to the selected target from this validator
  /// @param target Address to send requested ETH to
  function collectAllEth(address target) external onlyOwner {
    _sendEth(target, address(this).balance);
  }

  function _sendEth(address target, uint256 value) internal {
    (bool success, ) = target.call{value: value}("");
    require(success, "Transfer failed.");
  }

  function _validate(address _recipient, uint256 _qty) internal {
    uint256[] memory idReturn = new uint256[](1);
    uint256[] memory quantityReturn = new uint256[](1);
    idReturn[0] = _id;
    quantityReturn[0] = _qty;
    core.modularMintCallback(_recipient, idReturn, quantityReturn, "");
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Auth, Authority} from "../Auth.sol";

/// @notice Flexible and target agnostic role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/MultiRolesAuthority.sol)
contract MultiRolesAuthority is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                       CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    /*///////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(bytes4 => bool) public isCapabilityPublic;

    mapping(bytes4 => bytes32) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(uint8 role, bytes4 functionSig) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        Authority customAuthority = getTargetCustomAuthority[target];

        if (address(customAuthority) != address(0)) return customAuthority.canCall(user, target, functionSig);

        return
            isCapabilityPublic[functionSig] || bytes32(0) != getUserRoles[user] & getRolesWithCapability[functionSig];
    }

    /*///////////////////////////////////////////////////////////////
               CUSTOM TARGET AUTHORITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setTargetCustomAuthority(address target, Authority customAuthority) public virtual requiresAuth {
        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, customAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }
}

// This is just a lazy way to get the typechain shit generated ~`*_*`~
import "@rari-capital/solmate/src/auth/authorities/RolesAuthority.sol";
import "@rari-capital/solmate/src/auth/authorities/MultiRolesAuthority.sol";

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Auth, Authority} from "../Auth.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../chainlink/VRFConsumerBase.sol";

contract VRFCoordinatorMock {
  LinkTokenInterface public link;
  uint256 private _requestId = 10;

  address private _consumer;

  event RandomnessRequest(
    address indexed sender,
    bytes32 indexed keyHash,
    uint256 indexed seed
  );

  constructor(address linkAddress) {
    link = LinkTokenInterface(linkAddress);
  }

  function onTokenTransfer(
    address sender,
    uint256,
    bytes memory _data
  ) public onlyLINK {
    (bytes32 keyHash, uint256 seed) = abi.decode(_data, (bytes32, uint256));
    emit RandomnessRequest(sender, keyHash, seed);
  }

  function setConsumer(address consumer) public {
    _consumer = consumer;
  }

  function callBackWithRandomness(
    bytes32 requestId,
    uint256 randomness,
    address consumerContract
  ) public {
    VRFConsumerBase v;
    bytes memory resp = abi.encodeWithSelector(
      v.rawFulfillRandomness.selector,
      requestId,
      randomness
    );
    uint256 b = 206000;
    require(gasleft() >= b, "not enough gas for consumer");
    (bool success, ) = consumerContract.call(resp);
    require(success, "Issue with call");
  }

  modifier onlyLINK() {
    require(msg.sender == address(link), "Must use LINK token");
    _;
  }
}

pragma solidity ^0.8.0;

interface IAchievement {
  function getAchievement() external view returns (string memory);

  function hasAchievement(uint256 characterId) external view returns (bool);

  function unlockAchievement(uint256 characterId) external view;
}

interface IEXP {
  function getXP(uint256 characterId) external view returns (uint256);

  function getLVL(uint256 characterId) external view returns (uint256);
}

interface IREP {
  function getREP(uint256 characterId) external view;

  function getRNK(uint256 characterId) external view returns (uint256);
}

pragma solidity ^0.8.0;

contract MetaDataStringMock {
  function getMetadataString(uint256 id) external view returns (string memory) {
    return "{'trait_type': 'Personality', 'value': 'Sad'}";
  }
}

// SPDX-License-Identifier: AGPL-3.0


pragma solidity ^0.8.0;

// Mocked endpoint for all of the basic distro flows
// In production this will be three seperate contracts, so build accordingly.
// This contract is simply meant to provide a clean mocked version of the primary endpointss
// needed for the basic distribution apps. Some functions _may_ change slightly, but generally
// integrating based on these mocks should allow us to integrate the completed contracts with little to no friction
// and provide a more stable, modular and accesible testing option for front-end testing.

contract ValidatorMock {
  // RAFFLE VARIABLES
  address public depositor = address(0x0);
  uint256 public deposit = 0;
  // Min = .08 ETH
  uint256 public depositMin = 80000000000000000;
  bool public raffleClaimed = false;

  // EXCHANGE VARIABLES
  bool public exchangeClaimed = false;

  // AUCTION VARIABLES
  bool public auctionClaimed = false;
  uint256 deadline = 0;
  address bidder = address(0x0);
  uint256 bid = 0;
  // This will be nested in the drop struct in prod, and will be set when drop is set
  uint256 dropSize = 20000;

  // *********************************************************************************************************
  // RAFFLE
  // *********************************************************************************************************

  /// @notice This function takes a message value greater than the minimum deposit for the raffle.
  /// @dev    We give the user 1 "ticket" for each valid deposit of depositMin. For example, if deposit min is 1
  ///         submitting a deposit of 2 would yield 2 "tickets" to the raffle. Losing tickets can remove their deposit.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @param recipient Whichever account you want to be _credited_ with the deposit is the recipient, generally msg.sender.
  function addDeposit(uint256 _dropID, address recipient) external payable {
    require(msg.value >= depositMin, " Insufficient Deposit");
    depositor = recipient;
    deposit = msg.value;
    raffleClaimed = false;
  }

  /// @notice This function takes a message value greater than the minimum deposit for the raffle.
  /// @dev    We give the user 1 "ticket" for each valid deposit of depositMin. For example, if deposit min is 1
  ///         submitting a deposit of 2 would yield 2 "tickets" to the raffle. Losing tickets can remove their deposit.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  function addDeposit(uint256 _dropID) external payable {
    require(msg.value >= depositMin, " Insufficient Deposit");
    depositor = msg.sender;
    deposit = msg.value;
    raffleClaimed = false;
  }

  /// @notice Returns the deposit you currently have to the recipient of this function.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @param recipient Whichever account you want the deposit returned tois the recipient, generally msg.sender.
  function removeDeposit(uint256 _dropID, address payable recipient) external {
    depositor = address(0x0);
    deposit = 0;
  }

  /// @notice Sends the raffle winnings to the recipient address.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @param recipient Whichever account you want the winnings sent to is the recipient, generally msg.sender.
  function claimRaffle(uint256 _dropID, address recipient) external {
    raffleClaimed = true;
  }

  /// @notice Returns the deposit that's currently held by the recipient of this function.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @param recipient Whichever account you want to check the deposit of.
  /// @return Current deposit that the supplied recipient has saved for the raffle indicated in _dropID.
  function getDeposit(uint256 _dropID, address recipient)
    external
    view
    returns (uint256)
  {
    return deposit;
  }

  /// @notice Returns the deposit that's currently held by the sender of this function.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @return Current deposit that the supplied recipient has saved for the raffle indicated in _dropID.
  function getDeposit(uint256 _dropID) external view returns (uint256) {
    return deposit;
  }

  /// @notice Returns the minimum deposit required to receive a raffle ticket.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @return Current deposit minimum that must be supplied to secure a rafle ticket.
  function getDepositMin(uint256 _dropID) external view returns (uint256) {
    return deposit;
  }

  /// @notice Get the total number of tokens that will be released in a given drop.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @return Current deposit that the supplied recipient has saved for the raffle indicated in _dropID.
  function getDropSize(uint256 _dropID) external view returns (uint256) {
    return dropSize;
  }

  /// @notice Returns the current number of raffle tickets held by a given raffle partipant.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @param participant Account to check raffle tickets holdings of.
  /// @return Current deposit minimum that must be supplied to secure a rafle ticket.
  function getTicketsCount(uint256 _dropID, address participant)
    external
    view
    returns (uint256)
  {
    // Lazy precision... Good enough for mock but not _accurate_
    return deposit / depositMin;
  }

  /// @notice Returns the total number of raffle tickets purchased by all participants.
  /// @param _dropID This is an entrenal identifier that represents a specific raffle, or "drop".
  /// @return Total of all raffle tickets purchased.
  function getTotalTicketsCount(uint256 _dropID)
    external
    view
    returns (uint256)
  {
    // Lazy precision... Good enough for mock but not _accurate_
    return deposit / depositMin;
  }

  // *********************************************************************************************************
  // TOKEN EXCHANGE
  // *********************************************************************************************************

  /// @notice Allows somebody holding a specific token to receive another token based on holding that token.
  /// @param _dropID This is an entrenal identifier that represents a specific exchange, or "drop". This holds information
  ///                relevant to _which_ token is being exchanged _for which_ token.
  /// @param recipient Whichever account you want the new token sent to is the recipient, generally msg.sender.
  function claimExchange(uint256 _dropID, address recipient) external {}

  /// @notice Informs us whether a specific account has claimed their token for a specific drop.
  /// @param _dropID This is an entrenal identifier that represents a specific exchange, or "drop". This holds information
  ///                relevant to _which_ token is being exchanged _for which_ token.
  /// @param recipient Account we're checking the claim status on.
  function hasClaimed(uint256 _dropID, address recipient)
    external
    view
    returns (bool)
  {
    return exchangeClaimed;
  }

  // *********************************************************************************************************
  // AUCTION
  // *********************************************************************************************************

  /// @notice Take a message value and adds it to the bidders current bid.
  /// @dev    This is strictly additive, the msg.value is _always_ compounded with this function.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @param bidder Whichever account you want to be _credited_ with the bid is the bidder, generally msg.sender.
  function addBid(uint256 _dropID, address bidder) external payable {
    bidder = bidder;
    bid = msg.value;
  }

  /// @notice Take a message value and adds it to the bidders current bid.
  /// @dev    This is strictly additive, the msg.value is _always_ compounded with this function.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  function addBid(uint256 _dropID) external payable {
    bidder = msg.sender;
    bid = msg.value;
  }

  /// @notice Returns the bid sender currently has to the recipient of this function.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @param recipient Whichever account you want the bid returned to is the recipient, generally msg.sender.
  function removeBid(uint256 _dropID, address recipient) external {
    bidder = address(0x0);
    bid = 0;
  }

  /// @notice Sends the auction winnings to the recipient address.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @param recipient Whichever account you want the winnings sent to is the recipient, generally msg.sender.
  function claimAuction(uint256 _dropID, address recipient) external {
    auctionClaimed = true;
  }

  /// @notice Sends the auction winnings to the senders address.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  function claimAuction(uint256 _dropID) external {
    auctionClaimed = true;
  }

  /// @notice Get the time remaining for the given drop.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @return Current time remaining in the selected auction.
  function timeRemaining(uint256 _dropID) external view returns (uint256) {
    return deadline - block.timestamp;
  }

  /// @notice Get the current bid of the requested bidder.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @param bidder Whichever account you want to check the bid of.
  /// @return Current bid of the requested bidder.
  function getBid(uint256 _dropID, address bidder)
    external
    view
    returns (uint256)
  {
    return bid;
  }

  /// @notice Set a new deadline for a given auction.
  /// @dev In prod this will be protected - leaving it open for development just to make things easier.
  /// @param _dropID This is an entrenal identifier that represents a specific auction, or "drop".
  /// @param _deadline Auction deadline supplied in _seconds since epoch_
  function setDeadline(uint256 _dropID, uint256 _deadline) external {
    deadline = _deadline;
  }
}



// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

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

// // SPDX-License-Identifier: AGPL-3.0-only




// pragma solidity >=0.8.0;

// /// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
// /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
// /// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
// abstract contract ERC721 {
//   /*///////////////////////////////////////////////////////////////
//                                  EVENTS
//     //////////////////////////////////////////////////////////////*/

//   event Transfer(address indexed from, address indexed to, uint256 indexed id);

//   event Approval(
//     address indexed owner,
//     address indexed spender,
//     uint256 indexed id
//   );

//   event ApprovalForAll(
//     address indexed owner,
//     address indexed operator,
//     bool approved
//   );

//   /*///////////////////////////////////////////////////////////////
//                           METADATA STORAGE/LOGIC
//     //////////////////////////////////////////////////////////////*/

//   string public name;

//   string public symbol;

//   function tokenURI(uint256 id) public view virtual returns (string memory);

//   /*///////////////////////////////////////////////////////////////
//                             ERC721 STORAGE                        
//     //////////////////////////////////////////////////////////////*/

//   mapping(address => uint256) public balanceOf;

//   mapping(uint256 => address) public ownerOf;

//   mapping(uint256 => address) public getApproved;

//   mapping(address => mapping(address => bool)) public isApprovedForAll;

//   /*///////////////////////////////////////////////////////////////
//                               CONSTRUCTOR
//     //////////////////////////////////////////////////////////////*/

//   constructor(string memory _name, string memory _symbol) {
//     name = _name;
//     symbol = _symbol;
//   }

//   /*///////////////////////////////////////////////////////////////
//                               ERC721 LOGIC
//     //////////////////////////////////////////////////////////////*/

//   function approve(address spender, uint256 id) public virtual {
//     address owner = ownerOf[id];

//     require(
//       msg.sender == owner || isApprovedForAll[owner][msg.sender],
//       "NOT_AUTHORIZED"
//     );

//     getApproved[id] = spender;

//     emit Approval(owner, spender, id);
//   }

//   function setApprovalForAll(address operator, bool approved) public virtual {
//     isApprovedForAll[msg.sender][operator] = approved;

//     emit ApprovalForAll(msg.sender, operator, approved);
//   }

//   function transferFrom(
//     address from,
//     address to,
//     uint256 id
//   ) public virtual {
//     require(from == ownerOf[id], "WRONG_FROM");

//     require(to != address(0), "INVALID_RECIPIENT");

//     require(
//       msg.sender == from ||
//         msg.sender == getApproved[id] ||
//         isApprovedForAll[from][msg.sender],
//       "NOT_AUTHORIZED"
//     );
//     _beforeTokenTransfer(from, to, id);

//     // Underflow of the sender's balance is impossible because we check for
//     // ownership above and the recipient's balance can't realistically overflow.
//     unchecked {
//       balanceOf[from]--;

//       balanceOf[to]++;
//     }

//     ownerOf[id] = to;

//     delete getApproved[id];

//     emit Transfer(from, to, id);
//   }

//   function safeTransferFrom(
//     address from,
//     address to,
//     uint256 id
//   ) public virtual {
//     transferFrom(from, to, id);

//     require(
//       to.code.length == 0 ||
//         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
//         ERC721TokenReceiver.onERC721Received.selector,
//       "UNSAFE_RECIPIENT"
//     );
//   }

//   function safeTransferFrom(
//     address from,
//     address to,
//     uint256 id,
//     bytes memory data
//   ) public virtual {
//     transferFrom(from, to, id);

//     require(
//       to.code.length == 0 ||
//         ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
//         ERC721TokenReceiver.onERC721Received.selector,
//       "UNSAFE_RECIPIENT"
//     );
//   }

//   /*///////////////////////////////////////////////////////////////
//                               ERC165 LOGIC
//     //////////////////////////////////////////////////////////////*/

//   function supportsInterface(bytes4 interfaceId)
//     public
//     pure
//     virtual
//     returns (bool)
//   {
//     return
//       interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
//       interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
//       interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
//   }

//   /*///////////////////////////////////////////////////////////////
//                        INTERNAL MINT/BURN LOGIC
//     //////////////////////////////////////////////////////////////*/

//   function _mint(address to, uint256 id) internal virtual {
//     require(to != address(0), "INVALID_RECIPIENT");

//     require(ownerOf[id] == address(0), "ALREADY_MINTED");
//     _beforeTokenTransfer(address(0), to, id);

//     // Counter overflow is incredibly unrealistic.
//     unchecked {
//       balanceOf[to]++;
//     }

//     ownerOf[id] = to;

//     emit Transfer(address(0), to, id);
//   }

//   function _burn(uint256 id) internal virtual {
//     address owner = ownerOf[id];

//     require(ownerOf[id] != address(0), "NOT_MINTED");
//     _beforeTokenTransfer(owner, address(0), id);

//     // Ownership check above ensures no underflow.
//     unchecked {
//       balanceOf[owner]--;
//     }

//     delete ownerOf[id];

//     delete getApproved[id];

//     emit Transfer(owner, address(0), id);
//   }

//   /*///////////////////////////////////////////////////////////////
//                        INTERNAL SAFE MINT LOGIC
//     //////////////////////////////////////////////////////////////*/

//   function _safeMint(address to, uint256 id) internal virtual {
//     _mint(to, id);

//     require(
//       to.code.length == 0 ||
//         ERC721TokenReceiver(to).onERC721Received(
//           msg.sender,
//           address(0),
//           id,
//           ""
//         ) ==
//         ERC721TokenReceiver.onERC721Received.selector,
//       "UNSAFE_RECIPIENT"
//     );
//   }

//   function _safeMint(
//     address to,
//     uint256 id,
//     bytes memory data
//   ) internal virtual {
//     _mint(to, id);

//     require(
//       to.code.length == 0 ||
//         ERC721TokenReceiver(to).onERC721Received(
//           msg.sender,
//           address(0),
//           id,
//           data
//         ) ==
//         ERC721TokenReceiver.onERC721Received.selector,
//       "UNSAFE_RECIPIENT"
//     );
//   }

//   /**
//    * @dev Hook that is called before any token transfer. This includes minting
//    * and burning.
//    *
//    * Calling conditions:
//    *
//    * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
//    * transferred to `to`.
//    * - When `from` is zero, `tokenId` will be minted for `to`.
//    * - When `to` is zero, ``from``'s `tokenId` will be burned.
//    * - `from` and `to` are never both zero.
//    *
//    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//    */
//   function _beforeTokenTransfer(
//     address from,
//     address to,
//     uint256 tokenId
//   ) internal virtual {}
// }

// /// @notice A generic interface for a contract which properly accepts ERC721 tokens.
// /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
// interface ERC721TokenReceiver {
//   function onERC721Received(
//     address operator,
//     address from,
//     uint256 id,
//     bytes calldata data
//   ) external returns (bytes4);
// }

// pragma solidity ^0.8.0;
// interface IMintValidator721 {
//   function validate(
//     address _recipient,
//     uint256 _dropId,
//     string calldata _metadata,
//     bytes memory _data
//   ) external;
// }

// pragma solidity ^0.8.0;



// interface IFabricator721 {
//   function modularMintInit(
//     uint256 _dropId,
//     address _to,
//     bytes memory _data,
//     address _validator,
//     string calldata _metadata
//   ) external;

//   function modularMintCallback(
//     address recipient,
//     uint256 _id,
//     bytes memory _data
//   ) external;

//   function quantityMinted(uint256 collectibleId) external returns (uint256);

//   function idToValidator(uint256 collectibleId) external returns (address);
// }

// pragma solidity ^0.8.0;

// interface IXferHook {
//   function xferHook(
//     address from,
//     address to,
//     uint256 id
//   ) external;
// }



// /**
//  * @dev String operations.
//  */
// library Strings {
//     bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

//     /**
//      * @dev Converts a `uint256` to its ASCII `string` decimal representation.
//      */
//     function toString(uint256 value) internal pure returns (string memory) {
//         // Inspired by OraclizeAPI's implementation - MIT licence
//         // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

//         if (value == 0) {
//             return "0";
//         }
//         uint256 temp = value;
//         uint256 digits;
//         while (temp != 0) {
//             digits++;
//             temp /= 10;
//         }
//         bytes memory buffer = new bytes(digits);
//         while (value != 0) {
//             digits -= 1;
//             buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
//             value /= 10;
//         }
//         return string(buffer);
//     }

//     /**
//      * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
//      */
//     function toHexString(uint256 value) internal pure returns (string memory) {
//         if (value == 0) {
//             return "0x00";
//         }
//         uint256 temp = value;
//         uint256 length = 0;
//         while (temp != 0) {
//             length++;
//             temp >>= 8;
//         }
//         return toHexString(value, length);
//     }

//     /**
//      * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
//      */
//     function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
//         bytes memory buffer = new bytes(2 * length + 2);
//         buffer[0] = "0";
//         buffer[1] = "x";
//         for (uint256 i = 2 * length + 1; i > 1; --i) {
//             buffer[i] = _HEX_SYMBOLS[value & 0xf];
//             value >>= 4;
//         }
//         require(value == 0, "Strings: hex length insufficient");
//         return string(buffer);
//     }
// }

// // OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



// /**
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         return msg.data;
//     }
// }


// // Experiment with solmate 721?



// /// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
// /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
// /// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
// abstract contract Auth {
//     event OwnerUpdated(address indexed user, address indexed newOwner);

//     event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

//     address public owner;

//     Authority public authority;

//     constructor(address _owner, Authority _authority) {
//         owner = _owner;
//         authority = _authority;

//         emit OwnerUpdated(msg.sender, _owner);
//         emit AuthorityUpdated(msg.sender, _authority);
//     }

//     modifier requiresAuth() {
//         require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

//         _;
//     }

//     function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
//         Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

//         // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
//         // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
//         return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
//     }

//     function setAuthority(Authority newAuthority) public virtual {
//         // We check if the caller is the owner first because we want to ensure they can
//         // always swap out the authority even if it's reverting or using up a lot of gas.
//         require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

//         authority = newAuthority;

//         emit AuthorityUpdated(msg.sender, newAuthority);
//     }

//     function setOwner(address newOwner) public virtual requiresAuth {
//         owner = newOwner;

//         emit OwnerUpdated(msg.sender, newOwner);
//     }
// }

// /// @notice A generic interface for a contract which provides authorization data to an Auth instance.
// /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
// /// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
// interface Authority {
//     function canCall(
//         address user,
//         address target,
//         bytes4 functionSig
//     ) external view returns (bool);
// }

// pragma solidity ^0.8.0;
// //pragma abicoder v2;


// interface IReadMetadata {
//   function get(uint256 _id) external view returns (string memory metadata);
// }

// contract MetadataRegistry is IReadMetadata, Auth {
//   event Register(uint256 id, string metadata);
//   event UnRegister(uint256 id);

//   mapping(uint256 => string) public idToMetadata;

//   constructor(Authority auth) Auth(msg.sender, auth) {}

//   function set(uint256 _id, string calldata _metadata) public requiresAuth {
//     idToMetadata[_id] = _metadata;
//     emit Register(_id, _metadata);
//   }

//   function get(uint256 _id)
//     public
//     view
//     override
//     returns (string memory metadata)
//   {
//     metadata = idToMetadata[_id];
//     require(bytes(metadata).length > 0, "MISSING_URI");
//   }

//   function setMultiple(uint256[] calldata _ids, string[] calldata _metadatas)
//     external
//     requiresAuth
//   {
//     require(_ids.length == _metadatas.length, "SET_MULTIPLE_LENGTH_MISMATCH");
//     for (uint256 i = 0; i < _ids.length; i++) {
//       set(_ids[i], _metadatas[i]);
//     }
//   }
// }

// /// @title Core721
// /// @author The name of the author
// /// @notice Explain to an end user what this does
// /// @dev Explain to a developer any extra details//Interface
// contract Core721 is Context, ERC721, IFabricator721, Auth {
//   using Strings for uint256;
//   event Validator(IMintValidator721 indexed validator, bool indexed active);

//   mapping(IMintValidator721 => bool) public isValidator;
//   mapping(IMintValidator721 => uint256[]) public validatorToIds;
//   mapping(uint256 => address) public override idToValidator;
//   mapping(uint256 => uint256) public override quantityMinted;
//   mapping(uint256 => address) public idToTransferHook;
//   // URI base; NOT the whole uri.
//   string private _baseURI;
//   IReadMetadata private _registry;

//   /**
//    * @dev intializes the core ERC1155 logic, and sets the original URI base
//    */
//   constructor(
//     string memory baseUri_,
//     IReadMetadata registry_,
//     Authority authority
//   ) ERC721("PILLS AVATARS", "AVAPILL") Auth(msg.sender, authority) {
//     _registry = registry_;
//     _baseURI = baseUri_;
//   }

//   modifier onlyValidator() {
//     bool isActive = isValidator[IMintValidator721(msg.sender)];
//     require(isActive, "VALIDATOR_INACTIVE");
//     _;
//   }

//   /**
//    * @dev query URI for a token Id. Queries the Metadata registry on the backend
//    */
//   function uri(uint256 _id) public view returns (string memory) {
//     // Use the underlying metadata contract?
//     return string(abi.encodePacked(_baseURI, _id.toString()));
//   }

//   /**
//    * @dev change the URI base address after construction.
//    */
//   function setBaseURI(string calldata _newBaseUri) external requiresAuth {
//     _baseURI = _newBaseUri;
//   }

//   /**
//    * @dev change the URI base address after construction.
//    */
//   function setNewRegistry(IReadMetadata registry_) external requiresAuth {
//     _registry = registry_;
//   }

//   /**
//    * @dev An active Validator is necessary to enable `modularMint`
//    */
//   function addValidator(IMintValidator721 _validator, uint256[] memory ids)
//     external
//     virtual
//     requiresAuth
//   {
//     bool isActive = isValidator[_validator];
//     require(!isActive, "VALIDATOR_ACTIVE");
//     for (uint256 i; i < ids.length; i++) {
//       require(idToValidator[ids[i]] == address(0x0), "INVALID_VALIDATOR_IDS");
//       idToValidator[ids[i]] = address(_validator);
//     }
//     isValidator[_validator] = true;
//     emit Validator(_validator, !isActive);
//   }

//   /**
//    * @dev An active Validator is necessary to enable `modularMint`
//    */
//   function addTransferHook(IXferHook hooker, uint256[] memory ids)
//     external
//     virtual
//     requiresAuth
//   {
//     for (uint256 i; i < ids.length; i++) {
//       require(idToTransferHook[ids[i]] == address(0x0), "INVALID_HOOK_IDS");
//       idToTransferHook[ids[i]] = address(hooker);
//     }
//   }

//   /**
//    * @dev Remove Validators that are no longer needed to remove attack surfaces
//    */
//   function removeValidator(IMintValidator721 _validator)
//     external
//     virtual
//     requiresAuth
//   {
//     bool isActive = isValidator[_validator];
//     require(isActive, "VALIDATOR_INACTIVE");
//     uint256[] memory ids = validatorToIds[_validator];
//     for (uint256 i; i < ids.length; i++) {
//       idToValidator[ids[i]] = address(0x0);
//     }
//     isValidator[_validator] = false;
//     emit Validator(_validator, !isActive);
//   }

//   /**
//    * @dev Upgrade the validator responsible for a certain
//    */
//   function upgradeValidator(
//     IMintValidator721 _oldValidator,
//     IMintValidator721 _newValidator
//   ) external virtual requiresAuth {
//     bool isActive = isValidator[_oldValidator];
//     require(isActive, "VALIDATOR_INACTIVE");
//     uint256[] memory ids = validatorToIds[_oldValidator];
//     for (uint256 i; i < ids.length; i++) {
//       idToValidator[ids[i]] = address(_newValidator);
//     }
//     isValidator[_oldValidator] = false;
//     emit Validator(_oldValidator, !isActive);
//     isValidator[_newValidator] = true;
//     emit Validator(_newValidator, !isActive);
//   }

//   /**
//    * @dev Mint mulitiple tokens at different quantities. This is an requiresAuth
//           function and is meant basically as a sudo-command. Auth should be 
//    */
//   function mint(
//     address _to,
//     uint256 _id,
//     bytes memory _data
//   ) external virtual requiresAuth {
//     _safeMint(_to, _id, _data);
//   }

//   /**
//    * @dev Creates `amount` new tokens for `to`, of token type `id`.
//    *      At least one Validator must be active in order to utilized this interface.
//    */
//   function modularMintInit(
//     uint256 _dropId,
//     address _to,
//     bytes memory _data,
//     address _validator,
//     string calldata _metadata
//   ) public virtual override {
//     IMintValidator721 validator = IMintValidator721(_validator);
//     require(isValidator[validator], "BAD_VALIDATOR");
//     validator.validate(_to, _dropId, _metadata, _data);
//   }

//   /**
//    * @dev Creates `amount` new tokens for `to`, of token type `id`.
//    *      At least one Validator must be active in order to utilized this interface.
//    */
//   function modularMintCallback(
//     address recipient,
//     uint256 _id,
//     bytes calldata _data
//   ) public virtual override onlyValidator {
//     require(idToValidator[_id] == address(msg.sender), "INVALID_MINT");
//     _safeMint(recipient, _id, _data);
//   }

//   // OPTIMIZATION: No need for numbers to be readable, so this could be optimized
//   // but gas cost here doesn't matter so we go for the standard approach
//   function tokenURI(uint256 _id) public view override returns (string memory) {
//     return string(abi.encodePacked(_baseURI, _id.toString()));
//   }

//   function _beforeTokenTransfer(
//     address from,
//     address to,
//     uint256 id
//   ) internal override {
//     if (idToTransferHook[id] != address(0x0)) {
//       IXferHook(idToTransferHook[id]).xferHook(from, to, id);
//     }
//   }
// }

// SPDX-License-Identifier: AGPL-3.0

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}