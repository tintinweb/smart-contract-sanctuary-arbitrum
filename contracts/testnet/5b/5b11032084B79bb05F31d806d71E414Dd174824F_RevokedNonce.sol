/**
 *Submitted for verification at Arbiscan on 2023-08-16
*/

// Sources flattened with hardhat v2.17.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File lib/openzeppelin-contracts/contracts/utils/Context.sol

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

// File lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}

// File src/error/Error.sol

pragma solidity ^0.8.17;

/// -----------------------------------------------------------------------
/// Pool Custom Errors
/// -----------------------------------------------------------------------

error CVaultNotExist();
error GivenAssetNotMatchUnderlyingAsset();
error UnderlyingAssetExisted(address);
error InvalidVaultDeicmals(uint8);

/// -----------------------------------------------------------------------
/// Portfolio Custom Errors
/// -----------------------------------------------------------------------

error SellerExisted();
error SellerNotExisted();
error PortfolioNotExisted();
error IsolatedPortfolioAlreadyOpenTDSContract();
error TransferCollateralAssetError(string);
error PermissionDenied();
error AmountTooSmall();
error ExceedWarningRatio(uint256);
error VaultNotAllowed(address);
error InsufficientWithdrawAmount(uint256);
error InsufficientRepayAmount(uint256);

/// -----------------------------------------------------------------------
/// SignatureChecker Custom Errors
/// -----------------------------------------------------------------------

error InvalidSignatureLength(uint256);
error InvalidSignature();

/// -----------------------------------------------------------------------
/// TDSContract Custom Errors
/// -----------------------------------------------------------------------

error RequestExpire();
error InvalidPaymentInterval(uint256, uint256);
error BuyerInsufficientBalance(uint256);
error InvalidTDSContractCaller(address);
error ExecuteBorrowError(string);
error ExecuteRepayError(string);
error InvalidDecimal(uint8);
error TDSContractNotOpen(uint256);
error AlreadyPayAllPremium(uint256);
error NotReachPaymentDateYet(uint256);
error TDSContractNotDefault(uint256);
error EventDefaultValidatioError(string);
error ClaimPaymentWhenDefaultError(string);
error InvalidProof();
error InvalidPriceOracleRoundId(string);
error InvalidPriceOracleTime();

/// -----------------------------------------------------------------------
/// Nonce Custom Errors
/// -----------------------------------------------------------------------

error InvalidSellerNonce();
error InvalidBuyerNonce();
error InvalidReferenceEvent(uint256);
error InvalidDefaultTrigger();
error InvalidMinNonce();
error InvalidSender();

/// -----------------------------------------------------------------------
/// Oracle Custom Errors
/// -----------------------------------------------------------------------

error AssetNotSupported(address);
error ReportNotFound();
error TDSContractIsDefault();
error TDSContractUnderReporting();
error TDSContractReportTimeout();
error TDSContractAlreadyReported();

/// -----------------------------------------------------------------------
/// Reference Event Custom Errors
/// -----------------------------------------------------------------------

error InvalidEventType();

// File src/interface/IRevokedNonce.sol

pragma solidity 0.8.17;

interface IRevokedNonce {
    event NonceRevoked(address indexed owner, uint256 indexed nonce);

    event MinNonceSet(address indexed owner, uint256 indexed minNonce);

    function name() external view returns (string memory);

    function isNonceRevoked(
        address owner,
        uint256 nonce
    ) external view returns (bool);

    function minNonces(address owner) external view returns (uint256);

    function revokeNonce(address owner, uint256 nonce) external;

    function setMinNonce(address owner, uint256 minNonce) external;
}

// File src/nonce/RevokedNonce.sol

pragma solidity 0.8.17;

/// @title  Revoked Nonce
/// @notice Contract holding revoked nonces.
contract RevokedNonce is IRevokedNonce, Ownable {
    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    address internal _tdsContractFactory;

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @dev Mapping of revoked nonces by an address.
    ///     Every address has its own nonce space.
    ///     (owner => nonce => is revoked)
    mapping(address => mapping(uint256 => bool)) private _revokedNonces;

    /// @dev Mapping of minimal nonce value per address.
    ///     (owner => minimal nonce value)
    mapping(address => uint256) private _minNonces;

    /// @dev name of revoked nonce contract
    string internal _name;

    constructor(string memory name_) {
        _name = name_;
    }

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------

    modifier onlyTDSContractFactory() {
        if (msg.sender != _tdsContractFactory) revert InvalidSender();
        _;
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function name() external view override returns (string memory) {
        return _name;
    }

    function minNonces(address owner) external view override returns (uint256) {
        return _minNonces[owner];
    }

    /// @notice Get information if owners nonce is revoked or not.
    /// @dev Nonce is considered revoked if is smaller than owners min nonce value or if is explicitly revoked.
    /// @param owner Address of a nonce owner.
    /// @param nonce Nonce in question.
    /// @return True if owners nonce is revoked.
    function isNonceRevoked(
        address owner,
        uint256 nonce
    ) external view override returns (bool) {
        if (nonce < _minNonces[owner]) return true;

        return _revokedNonces[owner][nonce];
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function setTDSContractFactory(
        address tdsContractFactory_
    ) external onlyOwner {
        _tdsContractFactory = tdsContractFactory_;
    }

    /// @notice Revoke a nonce on behalf of an owner.
    /// @param owner Owner address of a revoking nonce.
    /// @param nonce Nonce to be revoked.
    function revokeNonce(
        address owner,
        uint256 nonce
    ) external override onlyTDSContractFactory {
        _revokeNonce(owner, nonce);
    }

    function _revokeNonce(address owner, uint256 nonce) private {
        // Revoke nonce
        _revokedNonces[owner][nonce] = true;

        // Emit event
        emit NonceRevoked(owner, nonce);
    }

    /// @notice Set a minimal nonce.
    /// @dev Nonce is considered revoked when smaller than minimal nonce.
    /// @param minNonce New value of a minimal nonce.
    function setMinNonce(
        address owner,
        uint256 minNonce
    ) external override onlyTDSContractFactory {
        // Check that nonce is greater than current min nonce
        uint256 currentMinNonce = _minNonces[owner];
        if (currentMinNonce >= minNonce) revert InvalidMinNonce();

        // Set new min nonce value
        _minNonces[owner] = minNonce;

        // Emit event
        emit MinNonceSet(owner, minNonce);
    }
}