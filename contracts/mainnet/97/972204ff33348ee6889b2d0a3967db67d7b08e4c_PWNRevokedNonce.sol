// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { AddressMissingHubTag } from "pwn/PWNErrors.sol";


/**
 * @title PWN Revoked Nonce
 * @notice Contract holding revoked nonces.
 */
contract PWNRevokedNonce {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Access tag that needs to be assigned to a caller in PWN Hub
     *         to call functions that revoke nonces on behalf of an owner.
     */
    bytes32 public immutable accessTag;

    /**
     * @notice PWN Hub contract.
     * @dev Addresses revoking nonces on behalf of an owner need to have an access tag in PWN Hub.
     */
    PWNHub public immutable hub;

    /**
     * @notice Mapping of revoked nonces by an address. Every address has its own nonce space.
     *         (owner => nonce space => nonce => is revoked)
     */
    mapping (address => mapping (uint256 => mapping (uint256 => bool))) private _revokedNonce;

    /**
     * @notice Mapping of current nonce space for an address.
     */
    mapping (address => uint256) private _nonceSpace;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when a nonce is revoked.
     */
    event NonceRevoked(address indexed owner, uint256 indexed nonceSpace, uint256 indexed nonce);

    /**
     * @notice Emitted when a nonce is revoked.
     */
    event NonceSpaceRevoked(address indexed owner, uint256 indexed nonceSpace);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when trying to revoke a nonce that is already revoked.
     */
    error NonceAlreadyRevoked(address addr, uint256 nonceSpace, uint256 nonce);

    /**
     * @notice Thrown when nonce is currently not usable.
     * @dev Maybe nonce is revoked or not in the current nonce space.
     */
    error NonceNotUsable(address addr, uint256 nonceSpace, uint256 nonce);


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyWithHubTag() {
        if (!hub.hasTag(msg.sender, accessTag))
            revert AddressMissingHubTag({ addr: msg.sender, tag: accessTag });
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _hub, bytes32 _accessTag) {
        accessTag = _accessTag;
        hub = PWNHub(_hub);
    }


    /*----------------------------------------------------------*|
    |*  # NONCE                                                 *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke callers nonce in the current nonce space.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonce) external {
        _revokeNonce(msg.sender, _nonceSpace[msg.sender], nonce);
    }

    /**
     * @notice Revoke multiple caller nonces in the current nonce space.
     * @param nonces List of nonces to be revoked.
     */
    function revokeNonces(uint256[] calldata nonces) external {
        for (uint256 i; i < nonces.length; ++i) {
            _revokeNonce(msg.sender, _nonceSpace[msg.sender], nonces[i]);
        }
    }

    /**
     * @notice Revoke caller nonce in a nonce space.
     * @param nonceSpace Nonce space where a nonce will be revoked.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external {
        _revokeNonce(msg.sender, nonceSpace, nonce);
    }

    /**
     * @notice Revoke a nonce in the current nonce space on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonce) external onlyWithHubTag {
        _revokeNonce(owner, _nonceSpace[owner], nonce);
    }

    /**
     * @notice Revoke a nonce in a nonce space on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonceSpace Nonce space where a nonce will be revoked.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonceSpace, uint256 nonce) external onlyWithHubTag {
        _revokeNonce(owner, nonceSpace, nonce);
    }

    /**
     * @notice Internal function to revoke a nonce in a nonce space.
     */
    function _revokeNonce(address owner, uint256 nonceSpace, uint256 nonce) private {
        if (_revokedNonce[owner][nonceSpace][nonce]) {
            revert NonceAlreadyRevoked({ addr: owner, nonceSpace: nonceSpace, nonce: nonce });
        }
        _revokedNonce[owner][nonceSpace][nonce] = true;
        emit NonceRevoked(owner, nonceSpace, nonce);
    }

    /**
     * @notice Return true if owners nonce is revoked in the given nonce space.
     * @dev Do not use this function to check if nonce is usable.
     *      Use `isNonceUsable` instead, which checks nonce space as well.
     * @param owner Address of a nonce owner.
     * @param nonceSpace Value of a nonce space.
     * @param nonce Value of a nonce.
     * @return True if nonce is revoked.
     */
    function isNonceRevoked(address owner, uint256 nonceSpace, uint256 nonce) external view returns (bool) {
        return _revokedNonce[owner][nonceSpace][nonce];
    }

    /**
     * @notice Return true if owners nonce is usable. Nonce is usable if it is not revoked and in the current nonce space.
     * @param owner Address of a nonce owner.
     * @param nonceSpace Value of a nonce space.
     * @param nonce Value of a nonce.
     * @return True if nonce is usable.
     */
    function isNonceUsable(address owner, uint256 nonceSpace, uint256 nonce) external view returns (bool) {
        if (_nonceSpace[owner] != nonceSpace)
            return false;

        return !_revokedNonce[owner][nonceSpace][nonce];
    }


    /*----------------------------------------------------------*|
    |*  # NONCE SPACE                                           *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke all nonces in the current nonce space and increment nonce space.
     * @dev Caller is used as a nonce owner.
     * @return New nonce space.
     */
    function revokeNonceSpace() external returns (uint256) {
        emit NonceSpaceRevoked(msg.sender, _nonceSpace[msg.sender]);
        return ++_nonceSpace[msg.sender];
    }

    /**
     * @notice Return current nonce space for an address.
     * @param owner Address of a nonce owner.
     * @return Current nonce space.
     */
    function currentNonceSpace(address owner) external view returns (uint256) {
        return _nonceSpace[owner];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";


/**
 * @title PWN Hub
 * @notice Connects PWN contracts together into protocol via tags.
 */
contract PWNHub is Ownable2Step {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @dev Mapping of address tags. (contract address => tag => is tagged)
     */
    mapping (address => mapping (bytes32 => bool)) private tags;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when tag is set for an address.
     */
    event TagSet(address indexed _address, bytes32 indexed tag, bool hasTag);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when `PWNHub.setTags` inputs lengths are not equal.
     */
    error InvalidInputData();


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable2Step() {

    }


    /*----------------------------------------------------------*|
    |*  # TAG MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set tag to an address.
     * @dev Tag can be added or removed via this functions. Only callable by contract owner.
     * @param _address Address to which a tag is set.
     * @param tag Tag that is set to an `_address`.
     * @param _hasTag Bool value if tag is added or removed.
     */
    function setTag(address _address, bytes32 tag, bool _hasTag) public onlyOwner {
        tags[_address][tag] = _hasTag;
        emit TagSet(_address, tag, _hasTag);
    }

    /**
     * @notice Set list of tags to an address.
     * @dev Tags can be added or removed via this functions. Only callable by contract owner.
     * @param _addresses List of addresses to which tags are set.
     * @param _tags List of tags that are set to an `_address`.
     * @param _hasTag Bool value if tags are added or removed.
     */
    function setTags(address[] memory _addresses, bytes32[] memory _tags, bool _hasTag) external onlyOwner {
        if (_addresses.length != _tags.length)
            revert InvalidInputData();

        uint256 length = _tags.length;
        for (uint256 i; i < length;) {
            setTag(_addresses[i], _tags[i], _hasTag);
            unchecked { ++i; }
        }
    }


    /*----------------------------------------------------------*|
    |*  # TAG GETTER                                            *|
    |*----------------------------------------------------------*/

    /**
     * @dev Return if an address is associated with a tag.
     * @param _address Address that is examined for a `tag`.
     * @param tag Tag that should an `_address` be associated with.
     * @return True if given address has a tag.
     */
    function hasTag(address _address, bytes32 tag) external view returns (bool) {
        return tags[_address][tag];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

library PWNHubTags {

    string internal constant VERSION = "1.2";

    /// @dev Address can mint LOAN tokens and create LOANs via loan factory contracts.
    bytes32 internal constant ACTIVE_LOAN = keccak256("PWN_ACTIVE_LOAN");
    /// @dev Address can call loan contracts to create and/or refinance a loan.
    bytes32 internal constant LOAN_PROPOSAL = keccak256("PWN_LOAN_PROPOSAL");
    /// @dev Address can revoke nonces on other addresses behalf.
    bytes32 internal constant NONCE_MANAGER = keccak256("PWN_NONCE_MANAGER");

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;


/**
 * @notice Thrown when an address is missing a PWN Hub tag.
 */
error AddressMissingHubTag(address addr, bytes32 tag);

/**
 * @notice Thrown when a proposal is expired.
 */
error Expired(uint256 current, uint256 expiration);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}