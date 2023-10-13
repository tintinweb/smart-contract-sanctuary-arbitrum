// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHubAccessControl.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Revoked Nonce
 * @notice Contract holding revoked nonces.
 */
contract PWNRevokedNonce is PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    bytes32 immutable internal accessTag;

    /**
     * @dev Mapping of revoked nonces by an address.
     *      Every address has its own nonce space.
     *      (owner => nonce => is revoked)
     */
    mapping (address => mapping (uint256 => bool)) private revokedNonces;

    /**
     * @dev Mapping of minimal nonce value per address.
     *      (owner => minimal nonce value)
     */
    mapping (address => uint256) private minNonces;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when a nonce is revoked.
     */
    event NonceRevoked(address indexed owner, uint256 indexed nonce);


    /**
     * @dev Emitted when a new min nonce value is set.
     */
    event MinNonceSet(address indexed owner, uint256 indexed minNonce);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address hub, bytes32 _accessTag) PWNHubAccessControl(hub) {
        accessTag = _accessTag;
    }


    /*----------------------------------------------------------*|
    |*  # REVOKE NONCE                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke a nonce.
     * @dev Caller is used as a nonce owner.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonce) external {
        _revokeNonce(msg.sender, nonce);
    }

    /**
     * @notice Revoke a nonce on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonce) external onlyWithTag(accessTag) {
        _revokeNonce(owner, nonce);
    }

    function _revokeNonce(address owner, uint256 nonce) private {
        // Revoke nonce
        revokedNonces[owner][nonce] = true;

        // Emit event
        emit NonceRevoked(owner, nonce);
    }


    /*----------------------------------------------------------*|
    |*  # SET MIN NONCE                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set a minimal nonce.
     * @dev Nonce is considered revoked when smaller than minimal nonce.
     * @param minNonce New value of a minimal nonce.
     */
    function setMinNonce(uint256 minNonce) external {
        // Check that nonce is greater than current min nonce
        uint256 currentMinNonce = minNonces[msg.sender];
        if (currentMinNonce >= minNonce)
            revert InvalidMinNonce();

        // Set new min nonce value
        minNonces[msg.sender] = minNonce;

        // Emit event
        emit MinNonceSet(msg.sender, minNonce);
    }


    /*----------------------------------------------------------*|
    |*  # IS NONCE REVOKED                                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get information if owners nonce is revoked or not.
     * @dev Nonce is considered revoked if is smaller than owners min nonce value or if is explicitly revoked.
     * @param owner Address of a nonce owner.
     * @param nonce Nonce in question.
     * @return True if owners nonce is revoked.
     */
    function isNonceRevoked(address owner, uint256 nonce) external view returns (bool) {
        if (nonce < minNonces[owner])
            return true;

        return revokedNonces[owner][nonce];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHub.sol";
import "@pwn/hub/PWNHubTags.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Hub Access Control
 * @notice Implement modifiers for PWN Hub access control.
 */
abstract contract PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNHub immutable internal hub;


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyActiveLoan() {
        if (hub.hasTag(msg.sender, PWNHubTags.ACTIVE_LOAN) == false)
            revert CallerMissingHubTag(PWNHubTags.ACTIVE_LOAN);
        _;
    }

    modifier onlyWithTag(bytes32 tag) {
        if (hub.hasTag(msg.sender, tag) == false)
            revert CallerMissingHubTag(tag);
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address pwnHub) {
        hub = PWNHub(pwnHub);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;


// Access control
error CallerMissingHubTag(bytes32);

// Loan contract
error LoanDefaulted(uint40);
error InvalidLoanStatus(uint256);
error NonExistingLoan();
error CallerNotLOANTokenHolder();
error InvalidExtendedExpirationDate();

// Invalid asset
error InvalidLoanAsset();
error InvalidCollateralAsset();

// LOAN token
error InvalidLoanContractCaller();

// Vault
error UnsupportedTransferFunction();
error IncompleteTransfer();

// Nonce
error NonceAlreadyRevoked();
error InvalidMinNonce();

// Signature checks
error InvalidSignatureLength(uint256);
error InvalidSignature();

// Offer
error CallerIsNotStatedBorrower(address);
error OfferExpired();
error CollateralIdIsNotWhitelisted();

// Request
error CallerIsNotStatedLender(address);
error RequestExpired();

// Request & Offer
error InvalidDuration();

// Input data
error InvalidInputData();

// Config
error InvalidFeeValue();
error InvalidFeeCollector();

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import "@pwn/PWNErrors.sol";


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
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when tag is set for an address.
     */
    event TagSet(address indexed _address, bytes32 indexed tag, bool hasTag);


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

    string internal constant VERSION = "1.0";

    /// @dev Address can mint LOAN tokens and create LOANs via loan factory contracts.
    bytes32 internal constant ACTIVE_LOAN = keccak256("PWN_ACTIVE_LOAN");

    /// @dev Address can be used as a loan terms factory for creating simple loans.
    bytes32 internal constant SIMPLE_LOAN_TERMS_FACTORY = keccak256("PWN_SIMPLE_LOAN_TERMS_FACTORY");

    /// @dev Address can revoke loan request nonces.
    bytes32 internal constant LOAN_REQUEST = keccak256("PWN_LOAN_REQUEST");
    /// @dev Address can revoke loan offer nonces.
    bytes32 internal constant LOAN_OFFER = keccak256("PWN_LOAN_OFFER");

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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