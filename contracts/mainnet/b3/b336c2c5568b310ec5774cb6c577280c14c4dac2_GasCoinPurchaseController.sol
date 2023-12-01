// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Rails} from "0xrails/cores/ERC721/interface/IERC721Rails.sol";
import {IPermissions} from "0xrails/access/permissions/interface/IPermissions.sol";
import {Operations} from "0xrails/lib/Operations.sol";

import {SetupController} from "src/lib/module/SetupController.sol";
import {PermitController} from "src/lib/module/PermitController.sol";
import {FeeController} from "src/lib/module/FeeController.sol";
import {PayoutAddressExtension} from "src/membership/extensions/PayoutAddress/PayoutAddressExtension.sol";

/// @title Station Network GasCoinPurchaseController Contract
/// @author symmetry (@symmtry69), frog (@0xmcg), 👦🏻👦🏻.eth
/// @dev Provides a modular contract to handle collections who wish for their membership mints to be
/// paid in the native currency of the chain this contract is deployed to

contract GasCoinPurchaseController is SetupController, PermitController, FeeController {
    /*=============
        STORAGE
    =============*/

    /// @dev collection => permits disabled, permits are enabled by default
    mapping(address => bool) internal _disablePermits;
    /// @dev Mapping of collections to their mint's native currency price
    mapping(address => uint256) public prices;

    /*============
        EVENTS
    ============*/

    /// @dev Events share names but differ in parameters to differentiate them between controllers
    event SetUp(address indexed collection, uint256 price, bool indexed enablePermits);

    /*============
        CONFIG
    ============*/

    /// @param _newOwner The owner of the FeeControllerV2, an address managed by Station Network
    /// @param _feeManager The FeeManager's address
    constructor(address _newOwner, address _feeManager) PermitController() FeeController(_newOwner, _feeManager) {}

    /// @dev Function to set up and configure a new collection's purchase prices
    /// @param collection The new collection to configure
    /// @param price The price in this chain's native currency for this collection's mints
    /// @param enablePermits A boolean to represent whether this collection will repeal or support grant functionality
    function setUp(address collection, uint256 price, bool enablePermits) public canSetUp(collection) {
        if (prices[collection] != price) {
            prices[collection] = price;
        }
        if (_disablePermits[collection] != !enablePermits) {
            _disablePermits[collection] = !enablePermits;
        }

        emit SetUp(collection, price, enablePermits);
    }

    /// @dev convenience function for setting up when creating collections, relies on auth done in public setUp
    function setUp(uint256 price, bool enablePermits) external {
        setUp(msg.sender, price, enablePermits);
    }

    /*==========
        MINT
    ==========*/

    /// @dev Function to get a collection's mint price in native currency price
    function priceOf(address collection) public view returns (uint256 price) {
        price = prices[collection];
        require(price > 0, "NO_PRICE");
    }

    /// @dev Function to mint a single collection token to the caller, ie a user
    function mint(address collection) external payable {
        _batchMint(collection, msg.sender, 1);
    }

    /// @dev Function to mint a single collection token to a specified recipient
    function mintTo(address collection, address recipient) external payable {
        _batchMint(collection, recipient, 1);
    }

    /// @dev Function to mint collection tokens in batches to the caller, ie a user
    /// @notice returned tokenId range is inclusive
    function batchMint(address collection, uint256 quantity) external payable {
        _batchMint(collection, msg.sender, quantity);
    }

    /// @dev Function to mint collection tokens in batches to a specified recipient
    /// @notice returned tokenId range is inclusive
    function batchMintTo(address collection, address recipient, uint256 quantity) external payable {
        _batchMint(collection, recipient, quantity);
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Internal function to which all external user + client facing batchMint functions are routed.
    /// @param collection The token collection to mint from
    /// @param recipient The recipient of successfully minted tokens
    /// @param quantity The quantity of tokens to mint
    /// @notice returned tokenId range is inclusive
    function _batchMint(address collection, address recipient, uint256 quantity)
        internal
        usePermits(_encodePermitContext(collection))
    {
        require(quantity > 0, "ZERO_QUANTITY");

        // prevent accidentally unset payoutAddress
        address payoutAddress = PayoutAddressExtension(collection).payoutAddress();
        require(payoutAddress != address(0), "MISSING_PAYOUT_ADDRESS");

        // reverts if collection has not been setUp()
        uint256 unitPrice = priceOf(collection);

        // calculate fee, require fee sent to this contract, transfer collection's revenue to payoutAddress
        _collectFeeAndForwardCollectionRevenue(collection, payoutAddress, address(0), recipient, quantity, unitPrice);

        // mint NFTs
        IERC721Rails(collection).mintTo(recipient, quantity);
    }

    /*============
        PERMIT
    ============*/

    function _encodePermitContext(address collection) internal pure returns (bytes memory context) {
        return abi.encode(collection);
    }

    function _decodePermitContext(bytes memory context) internal pure returns (address collection) {
        return abi.decode(context, (address));
    }

    function signerCanPermit(address signer, bytes memory context) public view override returns (bool) {
        address collection = _decodePermitContext(context);
        return IPermissions(collection).hasPermission(Operations.MINT_PERMIT, signer);
    }

    function requirePermits(bytes memory context) public view override returns (bool) {
        address collection = _decodePermitContext(context);
        return !_disablePermits[collection];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core token logic
interface IERC721Rails {
    /// @dev Function to mint ERC721Rails tokens to a recipient
    /// @param recipient The address of the recipient to receive the minted tokens.
    /// @param quantity The amount of tokens to mint and transfer to the recipient.
    function mintTo(address recipient, uint256 quantity) external returns (uint256 mintStartTokenId);

    /// @dev Burn ERC721Rails tokens from the caller.
    /// @param tokenId The ID of the token to burn from the sender's balance.
    function burn(uint256 tokenId) external;

    /// @dev Initialize the ERC721Rails contract with the given owner, name, symbol, and initialization data.
    /// @param owner The initial owner of the contract.
    /// @param name The name of the ERC721 token.
    /// @param symbol The symbol of the ERC721 token.
    /// @param initData Additional initialization data if required by the contract.
    function initialize(address owner, string calldata name, string calldata symbol, bytes calldata initData)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PermissionsStorage} from "../PermissionsStorage.sol";

interface IPermissions {
    struct Permission {
        bytes8 operation;
        address account;
        uint40 updatedAt;
    }

    // events
    event PermissionAdded(bytes8 indexed operation, address indexed account);
    event PermissionRemoved(bytes8 indexed operation, address indexed account);

    // errors
    error PermissionAlreadyExists(bytes8 operation, address account);
    error PermissionDoesNotExist(bytes8 operation, address account);

    /// @dev Function to hash an operation's `name` and typecast it to 8-bytes
    function hashOperation(string memory name) external view returns (bytes8);

    /// @dev Function to check that an address retains the permission for an operation
    /// @param operation An 8-byte value derived by hashing the operation name and typecasting to bytes8
    /// @param account The address to query against storage for permission
    function hasPermission(bytes8 operation, address account) external view returns (bool);

    /// @dev Function to get an array of all existing Permission structs.
    function getAllPermissions() external view returns (Permission[] memory permissions);

    /// @dev Function to add permission for an address to carry out an operation
    /// @param operation The operation to permit
    /// @param account The account address to be granted permission for the operation
    function addPermission(bytes8 operation, address account) external;

    /// @dev Function to remove permission for an address to carry out an operation
    /// @param operation The operation to restrict
    /// @param account The account address whose permission to remove
    function removePermission(bytes8 operation, address account) external;

    /// @dev Function to provide reverts when checks for `hasPermission()` fails
    /// @param operation The operation to check
    /// @param account The account address whose permission to check
    function checkPermission(bytes8 operation, address account) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Operations {
    bytes8 constant ADMIN = 0xfd45ddde6135ec42; // hashOperation("ADMIN");
    bytes8 constant MINT = 0x38381131ea27ecba; // hashOperation("MINT");
    bytes8 constant BURN = 0xf951edb3fd4a16a3; // hashOperation("BURN");
    bytes8 constant TRANSFER = 0x5cc15eb80ba37777; // hashOperation("TRANSFER");
    bytes8 constant METADATA = 0x0e5de49ee56c0bd3; // hashOperation("METADATA");
    bytes8 constant PERMISSIONS = 0x96bbcfa480f6f1a8; // hashOperation("PERMISSIONS");
    bytes8 constant GUARDS = 0x53cbed5bdabf52cc; // hashOperation("GUARDS");
    bytes8 constant VALIDATOR = 0xa95257aebefccffa; // hashOperation("VALIDATOR");
    bytes8 constant CALL = 0x706a455ca44ffc9f; // hashOperation("CALL");
    bytes8 constant INTERFACE = 0x4a9bf2931aa5eae4; // hashOperation("INTERFACE");
    bytes8 constant INITIALIZE_ACCOUNT = 0x18b11501aca1cd5e; // hashOperation("INITIALIZE_ACCOUNT");

    // TODO: deprecate and find another way versus anti-pattern
    // permits are enabling the permission, but only through set up modules/extension logic
    // e.g. someone can approve new members to mint, but cannot circumvent the module for taking payment
    bytes8 constant MINT_PERMIT = 0x0b6c53f325d325d3; // hashOperation("MINT_PERMIT");
    bytes8 constant BURN_PERMIT = 0x6801400fea7cd7c7; // hashOperation("BURN_PERMIT");
    bytes8 constant TRANSFER_PERMIT = 0xa994951607abf93b; // hashOperation("TRANSFER_PERMIT");
    bytes8 constant CALL_PERMIT = 0xc8d1733b0840734c; // hashOperation("CALL_PERMIT");
    bytes8 constant INITIALIZE_ACCOUNT_PERMIT = 0x449384b01ca84f74; // hashOperation("INITIALIZE_ACCOUNT_PERMIT");

    /// @dev Function to provide the signature string corresponding to an 8-byte operation
    /// @param name The signature string for an 8-byte operation. Empty for unrecognized operations.
    function nameOperation(bytes8 operation) public pure returns (string memory name) {
        if (operation == ADMIN) {
            return "ADMIN";
        } else if (operation == MINT) {
            return "MINT";
        } else if (operation == BURN) {
            return "BURN";
        } else if (operation == TRANSFER) {
            return "TRANSFER";
        } else if (operation == METADATA) {
            return "METADATA";
        } else if (operation == PERMISSIONS) {
            return "PERMISSIONS";
        } else if (operation == GUARDS) {
            return "GUARDS";
        } else if (operation == VALIDATOR) {
            return "VALIDATOR";
        } else if (operation == CALL) {
            return "CALL";
        } else if (operation == INTERFACE) {
            return "INTERFACE";
        } else if (operation == MINT_PERMIT) {
            return "MINT_PERMIT";
        } else if (operation == BURN_PERMIT) {
            return "BURN_PERMIT";
        } else if (operation == TRANSFER_PERMIT) {
            return "TRANSFER_PERMIT";
        } else if (operation == CALL_PERMIT) {
            return "CALL_PERMIT";
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "0xrails/access/permissions/interface/IPermissions.sol";
import {Operations} from "0xrails/lib/Operations.sol";

abstract contract SetupController {
    error SetUpUnauthorized(address collection, address account);

    modifier canSetUp(address collection) {
        if (collection != msg.sender && !IPermissions(collection).hasPermission(Operations.ADMIN, msg.sender)) {
            revert SetUpUnauthorized(collection, msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SignatureChecker, ECDSA} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {NonceBitMap} from "src/lib/NonceBitMap.sol";

/// @title PermitController: EIP-712 Signature Module for Permit-Based Function Authentication
/// @dev This contract provides a framework for permit-based function authentication using EIP-712 signatures.
/// It allows callers to execute functions on behalf of authorized signers by presenting a valid permit
/// containing an EIP-712 signature. This contract also includes reentrancy protection
abstract contract PermitController is NonceBitMap {
    /// @dev Struct of Permit data to be hashed and signed for meta-transactions.
    /// @param signer The authorized signer's address.
    /// @param sender The address of the sender.
    /// @param expiration The expiration timestamp of the permit.
    /// @param nonce A unique nonce to prevent replay attacks.
    /// @param data The data to be executed as part of the function call.
    /// @param signature The EIP-712 signature generated by the authorized signer.
    struct Permit {
        address signer; // take signer as explicit argument to support smart contract signers with EIP1271
        address sender;
        uint48 expiration;
        uint256 nonce;
        bytes data;
        bytes signature;
    }

    /*============
        ERRORS
    ============*/

    error Reentrancy();
    error PermitSignerInvalid(address signer);
    error PermitExpired(uint48 expiration, uint48 current);
    error PermitSenderMismatch(address expected, address sender);
    error PermitInvalidSignature(address signer, bytes32 permitHash, bytes signature);
    error PermitCallFailed(bytes data);
    error PermitCallUnprotected();

    /*=============
        STORAGE
    =============*/

    // signatures
    bytes32 private constant GRANT_TYPE_HASH =
        keccak256("Permit(address sender,uint48 expiration,uint256 nonce,bytes data)");
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME_HASH = keccak256("GroupOS");
    bytes32 private constant VERSION_HASH = keccak256("0.0.1");
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    uint256 internal immutable INITIAL_CHAIN_ID;

    // authentication handoff
    address private constant UNVERIFIED = address(1);
    uint256 private constant UNLOCKED = 1;
    uint256 private constant LOCKED = 2;
    address private verifiedSigner = UNVERIFIED;
    uint256 private lock = UNLOCKED;

    constructor() {
        INITIAL_DOMAIN_SEPARATOR = _domainSeparator();
        INITIAL_CHAIN_ID = block.chainid;
    }

    /*====================
        CORE UTILITIES
    ====================*/

    /// @notice Authenticate module functions for collections with permits and reentrancy protection
    modifier usePermits(bytes memory context) {
        address signer = verifiedSigner;
        // validate permits are required, signer is verified, and signer can permit
        if (requirePermits(context) && (signer == UNVERIFIED || !signerCanPermit(signer, context))) {
            revert PermitSignerInvalid(signer);
        }
        // reentrancy protection
        if (lock != UNLOCKED) revert Reentrancy();
        // lock
        lock = LOCKED;
        // function execution
        _;
        // unlock
        lock = UNLOCKED;
    }

    /// @notice Authenticate permit and make a self-call
    /// @dev Can only be used on functions that are protected with onlyPermited
    function callWithPermit(Permit calldata permit) external payable {
        if (permit.expiration < block.timestamp) revert PermitExpired(permit.expiration, uint48(block.timestamp));
        if (permit.sender != address(0) && permit.sender != msg.sender) {
            revert PermitSenderMismatch(permit.sender, msg.sender);
        }
        // use nonce, reverts if already used
        _useNonce(permit.signer, permit.nonce);
        // verify signer, reverts if invalid
        _verifySigner(permit);
        // set signer as verified state to be used in "real" call
        verifiedSigner = permit.signer;
        // make authenticated call
        Address.functionDelegateCall(address(this), permit.data);
        // reset verified signer
        verifiedSigner = UNVERIFIED;
    }

    /// @notice Override to customize which signers are allowed
    function signerCanPermit(address, bytes memory) public view virtual returns (bool);

    /// @notice Override to support disabling permits
    function requirePermits(bytes memory) public view virtual returns (bool);

    /*=====================
        PRIVATE HELPERS
    =====================*/

    /// @notice Verify the signer, signature, and data align and revert otherwise
    function _verifySigner(Permit memory permit) private view {
        // hash permit values
        bytes32 valuesHash = keccak256(
            abi.encode(
                GRANT_TYPE_HASH,
                permit.sender,
                permit.expiration,
                permit.nonce,
                // per EIP712 spec, need to hash variable length data to 32-bytes value first
                keccak256(permit.data)
            )
        );
        // hash domain with permit values
        bytes32 permitHash = ECDSA.toTypedDataHash(
            INITIAL_CHAIN_ID == block.chainid ? INITIAL_DOMAIN_SEPARATOR : _domainSeparator(), valuesHash
        );
        // verify signer, revert if invalid
        if (!SignatureChecker.isValidSignatureNow(permit.signer, permitHash, permit.signature)) {
            revert PermitInvalidSignature(permit.signer, permitHash, permit.signature);
        }
    }

    function _domainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "0xrails/access/ownable/Ownable.sol";
import {FeeManager} from "./FeeManager.sol";

/// @title Station Network Fee Manager Contract
/// @author symmetry (@symmtry69), frog (@0xmcg), 👦🏻👦🏻.eth
/// @dev This contract enables payment by handling funds when charging base and variable fees on each Membership's mints
/// @notice The FeeController is intended to be inherited by all purchase modules to abstract all payment logic
/// and handle fees for every client's desired Membership implementation
abstract contract FeeController is Ownable {
    // using SafeERC20 for covering USDT no-return and other transfer issues
    using SafeERC20 for IERC20Metadata;

    /*============
        ERRORS
    ============*/

    error InvalidFee(uint256 expected, uint256 received);

    /*============
        EVENTS
    ============*/

    event FeePaid(
        address indexed collection,
        address indexed buyer,
        address indexed paymentToken,
        uint256 unitPrice,
        uint256 quantity,
        uint256 totalFee
    );
    event FeeWithdrawn(address indexed recipient, address indexed token, uint256 amount);
    event FeeManagerUpdated(address indexed oldFeeManager, address indexed newFeeManager);

    /*=============
        STORAGE
    =============*/

    /// @dev Address of the deployed FeeManager contract which stores state for all collections' fee information
    /// @dev The FeeManager serves a Singleton role as central fee ledger for modules to read from
    address internal feeManager;

    /*==============
        SETTINGS
    ==============*/

    /// @param _newOwner The initialization of the contract's owner address, managed by Station
    /// @param _feeManager This chain's address for the FeeManager, Station's central fee management ledger
    constructor(address _newOwner, address _feeManager) {
        _transferOwnership(_newOwner);
        feeManager = _feeManager;
    }

    /// @dev Function to set a new FeeManager
    /// @param newFeeManager The new FeeManager address to write to storage
    function setNewFeeManager(address newFeeManager) external onlyOwner {
        require(newFeeManager != address(0) && newFeeManager != feeManager, "INVALID_FEE_MANAGER");
        emit FeeManagerUpdated(feeManager, newFeeManager);
        feeManager = newFeeManager;
    }

    /*==============
        WITHDRAW
    ==============*/

    /// @dev Function to withdraw the total balances of accrued base and variable eth fees collected from mints
    /// @dev Sends fees to the module's owner address, which is managed by Station Network
    /// @dev Access control enforced for tax implications
    /// @param paymentTokens The token addresses to call, where address(0) represents network token
    function withdrawFees(address[] calldata paymentTokens) external onlyOwner {
        address recipient = owner();
        for (uint256 i; i < paymentTokens.length; ++i) {
            uint256 amount;
            if (paymentTokens[i] == address(0)) {
                amount = address(this).balance;
                (bool success,) = recipient.call{value: amount}("");
                require(success);
            } else {
                amount = IERC20Metadata(paymentTokens[i]).balanceOf(address(this));
                IERC20Metadata(paymentTokens[i]).transfer(recipient, amount);
            }
            emit FeeWithdrawn(recipient, paymentTokens[i], amount);
        }
    }

    /*=============
        COLLECT
    =============*/

    /// @dev Function to collect fees for owner and collection in both network token and ERC20s
    /// @dev Called only by child contracts inheriting this one
    /// @param collection The token collection to mint from
    /// @param payoutAddress The address to send payment for the collection
    /// @param paymentToken The token address being used for payment
    /// @param recipient The recipient of successfully minted tokens
    /// @param quantity The number of items being minted, used to calculate the total fee payment required
    /// @param unitPrice The price per token to mint
    function _collectFeeAndForwardCollectionRevenue(
        address collection,
        address payoutAddress,
        address paymentToken,
        address recipient,
        uint256 quantity,
        uint256 unitPrice
    ) internal returns (uint256 paidFee) {
        // feeTotal is handled as either ETH or ERC20 stablecoin payment accordingly by FeeManager
        paidFee = FeeManager(feeManager).getFeeTotals(collection, paymentToken, recipient, quantity, unitPrice);
        uint256 total = quantity * unitPrice + paidFee;

        // for ETH context, accept funds only if the msg.value sent matches the FeeManager's calculation
        if (paymentToken == address(0x0)) {
            // collect fees- baseFee is still applied in FreeMintController context
            if (msg.value != total) revert InvalidFee(total, msg.value);

            // only perform external call + value to `payoutAddress` if called in GasCoinPurchaseController context
            if (unitPrice != 0) {
                // forward revenue to payoutAddress
                (bool success,) = payoutAddress.call{value: quantity * unitPrice}("");
                require(success, "PAYMENT_FAIL");
            }
        } else {
            // collect fees
            // transfer total to this contract first to update ERC20 approval storage
            // approval must have been made prior to top-level mint call
            IERC20Metadata(paymentToken).safeTransferFrom(msg.sender, address(this), total);
            // forward revenue to payoutAddress
            IERC20Metadata(paymentToken).safeTransfer(payoutAddress, quantity * unitPrice);
        }

        // emit event for accounting
        emit FeePaid(collection, recipient, paymentToken, unitPrice, quantity, paidFee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extension} from "0xrails/extension/Extension.sol";
import {PayoutAddress} from "./PayoutAddress.sol";

contract PayoutAddressExtension is PayoutAddress, Extension {
    /*===============
        EXTENSION
    ===============*/

    /// @inheritdoc Extension
    function getAllSelectors() public pure override returns (bytes4[] memory selectors) {
        selectors = new bytes4[](3);
        selectors[0] = this.payoutAddress.selector;
        selectors[1] = this.updatePayoutAddress.selector;
        selectors[2] = this.removePayoutAddress.selector;

        return selectors;
    }

    /// @inheritdoc Extension
    function signatureOf(bytes4 selector) public pure override returns (string memory) {
        if (selector == this.payoutAddress.selector) {
            return "payoutAddress()";
        } else if (selector == this.updatePayoutAddress.selector) {
            return "updatePayoutAddress(address)";
        } else if (selector == this.removePayoutAddress.selector) {
            return "removePayoutAddress()";
        } else {
            return "";
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PermissionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Permissions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x9c5c344d590e19b509d94e6539bcccae12bdf46ca0b9e14840beae558bd13e00;

    struct Layout {
        uint256[] _permissionKeys;
        mapping(uint256 => PermissionData) _permissions;
    }

    struct PermissionData {
        uint24 index; //              [0..23]
        uint40 updatedAt; //          [24..63]
        bool exists; //              [64-71]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    /* 
    .  Here is a rundown demonstrating the packing mechanic for `_packKey(adminOp, address(type(uint160).max))`:
    .  ```return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);```     
    .  Left-pack account by typecasting to uint256: 
    .  ```addressToUint == 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff```
    .  Shift left 64 bits, ie 8 bytes, which in hex is 16 digits: 
    .  ```leftShift64 == 0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000```
    .  Left-pack operation by typecasting to uint256: 
    .  ```op == 0x000000000000000000000000000000000000000000000000df8b4c520ffe197c```
    .  Or packed operation against packed + shifted account: 
    .  ```_packedKey == 0x00000000ffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c```
    */
    function _packKey(bytes8 operation, address account) internal pure returns (uint256) {
        // `operation` cast to uint64 to keep it on the small Endian side, packed with account to its left; leftmost 4 bytes remain empty
        return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);
    }

    function _unpackKey(uint256 key) internal pure returns (bytes8 operation, address account) {
        operation = bytes8(uint64(key));
        account = address(uint160(key >> 64));
        return (operation, account);
    }

    function _hashOperation(string memory name) internal pure returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(name)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

/// @title NonceBitMap: Address-Keyed Nonce Bitmap for Signature Replay Protection
/// @author symmetry (@symmtry69)
/// @notice Utility for making address-keyed nonce bitmaps for parallelized signature replay protection
abstract contract NonceBitMap {
    /*=============
        STORAGE
    =============*/

    // account => bitmap for tracking nonces, bitmaps used for gas efficient parallel processing
    mapping(address => mapping(uint256 => uint256)) internal _usedNonces;

    /*============
        EVENTS
    ============*/

    event NonceUsed(address indexed account, uint256 indexed nonce);

    /*===========
        ERRORS
    ===========*/

    error NonceAlreadyUsed(address account, uint256 nonce);

    /*==================
        VERIFICATION
    ==================*/

    /// @dev Check if a nonce has been used for a specific account.
    /// @param account The address for which to check nonce usage.
    /// @param nonce The nonce to check.
    /// @return '' Whether the nonce has been used or not.
    function isNonceUsed(address account, uint256 nonce) public view returns (bool) {
        (, uint256 word, uint256 mask) = _split(account, nonce);
        return word & mask != 0;
    }

    /// @dev Mark a `nonce` as used for a specific `account`, preventing potential replay attacks.
    function _useNonce(address account, uint256 nonce) internal {
        (uint256 wordId, uint256 word, uint256 mask) = _split(account, nonce);
        if (word & mask != 0) revert NonceAlreadyUsed(account, nonce);
        _usedNonces[account][wordId] = word | mask;
        emit NonceUsed(account, nonce);
    }

    /// @dev Split a nonce into `wordId`, `word`, and `mask` for efficient storage and verification.
    function _split(address account, uint256 nonce) private view returns (uint256 wordId, uint256 word, uint256 mask) {
        wordId = nonce >> 8;
        mask = 1 << (nonce & 0xff);
        word = _usedNonces[account][wordId];
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IOwnable} from "./interface/IOwnable.sol";
import {OwnableStorage} from "./OwnableStorage.sol";

/// @title 0xRails Ownable contract
/// @dev This contract provides access control by defining an owner address,
/// which can be updated through a two-step pending acceptance system or even revoked if desired.
abstract contract Ownable is IOwnable {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IOwnable
    function owner() public view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    /// @inheritdoc IOwnable
    function pendingOwner() public view virtual returns (address) {
        return OwnableStorage.layout().pendingOwner;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _startOwnershipTransfer(newOwner);
    }

    /// @inheritdoc IOwnable
    function acceptOwnership() public virtual {
        _acceptOwnership();
    }

    /*===============
        INTERNALS
    ===============*/

    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage.Layout storage layout = OwnableStorage.layout();
        emit OwnershipTransferred(layout.owner, newOwner);
        layout.owner = newOwner;
        delete layout.pendingOwner;
    }

    function _startOwnershipTransfer(address newOwner) internal virtual {
        if (newOwner == address(0)) {
            revert OwnerInvalidOwner(address(0));
        }
        OwnableStorage.Layout storage layout = OwnableStorage.layout();
        layout.pendingOwner = newOwner;
        emit OwnershipTransferStarted(layout.owner, newOwner);
    }

    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage layout = OwnableStorage.layout();
        address newOwner = layout.pendingOwner;
        if (newOwner != msg.sender) {
            revert OwnerUnauthorizedAccount(msg.sender);
        }
        _transferOwnership(newOwner);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnerUnauthorizedAccount(msg.sender);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/// @title Station Network Fee Manager Contract
/// @author 👦🏻👦🏻.eth

/// @dev This contract stores state for all fees set on both default and per-collection basis
/// Handles fee calculations when called by modules inquiring about the total fees involved in a mint, including ERC20 support
contract FeeManager is Ownable {
    /// @dev Struct of fee data, including FeeSetting enum and both base and variable fees, all packed into 1 slot
    /// Since `type(uint120).max` ~= 1.3e36, it suffices for fees of up to 1.3e18 ETH or ERC20 tokens, far beyond realistic scenarios.
    /// @param exist boolean indicating whether the fee values exist
    /// @param baseFee The flat fee charged by Station Network on a per item basis
    /// @param variableFee The variable fee (in BPS) charged by Station Network on volume basis
    /// Accounts for each item's cost and total amount of items
    struct Fees {
        bool exist;
        uint120 baseFee;
        uint120 variableFee;
    }

    /*============
        ERRORS
    ============*/

    error FeesNotSet();

    /*============
        EVENTS
    ============*/

    event DefaultFeesUpdated(Fees fees);
    event TokenFeesUpdated(address indexed token, Fees fees);
    event CollectionFeesUpdated(address indexed collection, address indexed token, Fees fees);

    /*=============
        STORAGE
    =============*/

    /// @dev Denominator used to calculate variable fee on a BPS basis
    /// @dev Not actually kept in storage as it is marked `constant`, saving gas by putting its value in contract bytecode instead
    uint256 private constant bpsDenominator = 10_000;

    /// @dev Baseline fee struct that serves as a stand in for all token addresses that have been registered
    /// in a stablecoin purchase module but not had their default fees set
    Fees internal defaultFees;

    /// @dev Mapping that stores default fees associated with a given token address
    mapping(address => Fees) internal tokenFees;

    /// @dev Mapping that stores override fees associated with specific collections, i.e. for discounts
    mapping(address => mapping(address => Fees)) internal collectionFees;

    /*================
        FEEMANAGER
    ================*/

    /// @notice Constructor will be deprecated in favor of an initialize() UUPS proxy call once logic is finalized & approved
    /// @param _newOwner The initialization of the contract's owner address, managed by Station
    /// @param _defaultBaseFee The initialization of default baseFees for all token addresses that have not (yet) been given defaults
    /// @param _defaultVariableFee The initialization of default variableFees for all token addresses that have not (yet) been given defaults
    /// @param _networkTokenBaseFee The initialization of default baseFees for the network's token
    /// @param _networkTokenVariableFee The initialization of default variableFees for the network's token
    constructor(
        address _newOwner,
        uint120 _defaultBaseFee,
        uint120 _defaultVariableFee,
        uint120 _networkTokenBaseFee,
        uint120 _networkTokenVariableFee
    ) {
        Fees memory _defaultFees = Fees(true, _defaultBaseFee, _defaultVariableFee);
        defaultFees = _defaultFees;
        emit DefaultFeesUpdated(_defaultFees);

        Fees memory _networkTokenFees = Fees(true, _networkTokenBaseFee, _networkTokenVariableFee);
        tokenFees[address(0x0)] = _networkTokenFees;
        emit TokenFeesUpdated(address(0x0), _networkTokenFees);

        _transferOwnership(_newOwner);
    }

    /// @dev Function to set baseline base and variable fees across all collections without specified defaults
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param baseFee The new baseFee to apply as default
    /// @param variableFee The new variableFee to apply as default
    function setDefaultFees(uint120 baseFee, uint120 variableFee) external onlyOwner {
        Fees memory fees = Fees(true, baseFee, variableFee);
        defaultFees = fees;
        emit DefaultFeesUpdated(fees);
    }

    /// @dev Function to set base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param token The token for which to set new base and variable fees
    /// @param baseFee The new baseFee to apply to the token
    /// @param variableFee The new variableFee to apply to the token
    function setTokenFees(address token, uint120 baseFee, uint120 variableFee) external onlyOwner {
        Fees memory fees = Fees(true, baseFee, variableFee);
        tokenFees[token] = fees;
        emit TokenFeesUpdated(token, fees);
    }

    /// @dev Function to remove base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param token The token for which to remove fees
    function removeTokenFees(address token) external onlyOwner {
        Fees memory fees = Fees(false, 0, 0);
        tokenFees[token] = fees;
        emit TokenFeesUpdated(token, fees);
    }

    /// @dev Function to set override base and variable fees on a per-collection basis
    /// @param collection The collection for which to set override fees
    /// @param token The token for which to set new base and variable fees
    /// @param baseFee The new baseFee to apply to the collection and token
    /// @param variableFee The new variableFee to apply to the collection and token
    function setCollectionFees(address collection, address token, uint120 baseFee, uint120 variableFee)
        external
        onlyOwner
    {
        Fees memory fees = Fees(true, baseFee, variableFee);
        collectionFees[collection][token] = fees;
        emit CollectionFeesUpdated(collection, token, fees);
    }

    /// @dev Function to remove base and variable fees for a specific token
    /// @dev Only callable by contract owner, an address managed by Station
    /// @param collection The collection for which to remove fees
    /// @param token The token for which to remove fees
    function removeCollectionFees(address collection, address token) external onlyOwner {
        Fees memory fees = Fees(false, 0, 0);
        tokenFees[token] = fees;
        emit CollectionFeesUpdated(collection, token, fees);
    }

    /*============
        VIEWS
    ============*/

    /// @dev Function to get collection fees
    /// @param collection The collection whose fees will be read, including checks for client-specific fee discounts
    /// @param paymentToken The ERC20 token address used to pay fees. Will use base currency (ETH, MATIC, etc) when == address(0)
    /// @param /*recipient*/ The address to mint to. Included to support future discounts on a per user basis
    /// @param quantity The amount of tokens for which to compute total baseFee
    /// @param unitPrice The price of each token, used to compute subtotal on which to apply variableFee
    /// @param feeTotal The returned total incl fees for the given collection.
    function getFeeTotals(
        address collection,
        address paymentToken,
        address, /*recipient*/
        uint256 quantity,
        uint256 unitPrice
    ) external view returns (uint256 feeTotal) {
        // get existing fees, first checking for override fees or discounts if they have already been set
        Fees memory fees = getFees(collection, paymentToken);

        // if being called in free mint context results in only base fee
        (uint256 baseFeeTotal, uint256 variableFeeTotal) =
            calculateFees(fees.baseFee, fees.variableFee, quantity, unitPrice);
        return baseFeeTotal + variableFeeTotal;
    }

    /// @dev Function to get baseline fees for all tokens
    function getDefaultFees() public view returns (Fees memory fees) {
        fees = defaultFees;
    }

    /// @dev Function to get default fees for a token if they have been set
    /// @param token The token address to query against tokenFees mapping
    function getTokenFees(address token) public view returns (Fees memory fees) {
        fees = tokenFees[token];
        if (!fees.exist) revert FeesNotSet();
    }

    /// @dev Function to get override fees for a collection and token if they have been set
    /// @param collection The collection address to query against collectionFees mapping
    /// @param token The token address to query against collectionFees mapping
    function getCollectionFees(address collection, address token) public view returns (Fees memory fees) {
        fees = collectionFees[collection][token];
        if (!fees.exist) revert FeesNotSet();
    }

    /// @dev Function to evaluate whether override fees have been set for a specific collection
    /// and whether default fees have been set for the given token
    function getFees(address _collection, address _token) public view returns (Fees memory fees) {
        // if collectionFees exist, return overrides
        Fees memory collectionOverrides = collectionFees[_collection][_token];
        if (collectionOverrides.exist) {
            return collectionOverrides;
        }
        // if tokenFees exist, return overrides
        Fees memory tokenOverrides = tokenFees[_token];
        if (tokenOverrides.exist) {
            return tokenOverrides;
        }
        // no overrides set, return defaults
        return defaultFees;
    }

    /// @dev Function to calculate fees using base and variable fee structures, agnostic to ETH or ERC20 values
    /// @param baseFee The base fee denominated either in ETH or ERC20 tokens
    /// @param variableFee The variable fee denominated either in ETH or ERC20 tokens
    /// @param quantity The number of tokens being minted
    /// @param unitPrice The price per unit of tokens being minted
    function calculateFees(uint256 baseFee, uint256 variableFee, uint256 quantity, uint256 unitPrice)
        public
        pure
        returns (uint256 baseFeeTotal, uint256 variableFeeTotal)
    {
        // calculate baseFee total (quantity * unitPrice), set to baseFee
        baseFeeTotal = quantity * baseFee;
        // apply variable fee on total volume
        variableFeeTotal = unitPrice * quantity * variableFee / bpsDenominator;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtension} from "./interface/IExtension.sol";

abstract contract Extension is IExtension {
    constructor() {
        getAllSignatures(); // verify selectors properly synced
    }

    /// @inheritdoc IExtension
    function signatureOf(bytes4 selector) public pure virtual returns (string memory signature) {}

    /// @inheritdoc IExtension
    function getAllSelectors() public pure virtual returns (bytes4[] memory selectors) {}

    /// @inheritdoc IExtension
    function getAllSignatures() public pure returns (string[] memory signatures) {
        bytes4[] memory selectors = getAllSelectors();
        uint256 len = selectors.length;
        signatures = new string[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = selectors[i];
            string memory signature = signatureOf(selector);
            require(bytes4(keccak256(abi.encodePacked(signature))) == selector, "SELECTOR_SIGNATURE_MISMATCH");
            signatures[i] = signature;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Operations} from "0xrails/lib/Operations.sol";
import {IPermissions} from "0xrails/access/permissions/interface/IPermissions.sol";
import {IPayoutAddress} from "./IPayoutAddress.sol";
import {PayoutAddressStorage} from "./PayoutAddressStorage.sol";

/// @dev This contract provides utilities to manage collections' payout address
/// @notice It is not to be instantiated directly, but inherited by eg. PayoutAddressExtension
abstract contract PayoutAddress is IPayoutAddress {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IPayoutAddress
    function payoutAddress() public view virtual returns (address) {
        PayoutAddressStorage.Layout storage layout = PayoutAddressStorage.layout();
        return layout.payoutAddress;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IPayoutAddress
    function updatePayoutAddress(address newPayoutAddress) external virtual {
        _checkCanUpdatePayoutAddress();
        if (newPayoutAddress == address(0)) revert PayoutAddressIsZero();
        _updatePayoutAddress(newPayoutAddress);
    }

    /// @inheritdoc IPayoutAddress
    function removePayoutAddress() external virtual {
        _checkCanUpdatePayoutAddress();
        _updatePayoutAddress(address(0));
    }

    function _updatePayoutAddress(address newPayoutAddress) internal {
        PayoutAddressStorage.Layout storage layout = PayoutAddressStorage.layout();
        emit PayoutAddressUpdated(layout.payoutAddress, newPayoutAddress);
        layout.payoutAddress = newPayoutAddress;
    }

    /*====================
        AUTHORIZATION
    ====================*/

    /// @notice This function is meant to be invoked in the context of `delegatecall`
    function _checkCanUpdatePayoutAddress() internal virtual {
        IPermissions(address(this)).checkPermission(Operations.ADMIN, msg.sender);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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

pragma solidity ^0.8.8;

interface IOwnable {
    // events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    // errors
    error OwnerUnauthorizedAccount(address account);
    error OwnerInvalidOwner(address owner);

    /// @dev Function to return the address of the current owner
    function owner() external view returns (address);

    /// @dev Function to return the address of the pending owner, in queued state
    function pendingOwner() external view returns (address);

    /// @dev Function to commence ownership transfer by setting `newOwner` as pending
    /// @param newOwner The intended new owner to be set as pending, awaiting acceptance
    function transferOwnership(address newOwner) external;

    /// @dev Function to accept an offer of ownership, intended to be called
    /// only by the address that is currently set as `pendingOwner`
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Owner")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0xf3c239b52c8c2d34fdf8aafa68bc754708c9395be7e6fed11d1fb0f4f4168c00;

    struct Layout {
        address owner;
        address pendingOwner;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtension {
    /// @dev Function to get the signature string for a specific function selector.
    /// @param selector The function selector to query.
    /// @return signature The signature string for the given function.
    function signatureOf(bytes4 selector) external pure returns (string memory signature);

    /// @dev Function to get an array of all recognized function selectors.
    /// @return selectors An array containing all 4-byte function selectors.
    function getAllSelectors() external pure returns (bytes4[] memory selectors);

    /// @dev Function to get an array of all recognized function signature strings.
    /// @return signatures An array containing all function signature strings.
    function getAllSignatures() external pure returns (string[] memory signatures);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPayoutAddress {
    // events
    event PayoutAddressUpdated(address oldPayoutAddress, address newPayoutAddress);

    // errors
    error PayoutAddressIsZero();

    /// @dev Returns the address of the current `payoutAddress` in storage
    function payoutAddress() external view returns (address);

    /// @dev Updates the current payout address to the provided `payoutAddress`
    function updatePayoutAddress(address payoutAddress) external;

    /// @dev Removes the current payout address, replacing it with address(0x0)
    function removePayoutAddress() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library PayoutAddressStorage {
    // `keccak256(abi.encode(uint256(keccak256("groupos.PayoutAddress")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x6f6b6396a67f685820b27036440227e08d5018166d641c2de98d9ec56a7a9200;

    struct Layout {
        address payoutAddress;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
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