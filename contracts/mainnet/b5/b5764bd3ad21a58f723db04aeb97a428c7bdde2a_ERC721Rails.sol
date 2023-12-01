// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {Rails} from "../../Rails.sol";
import {Ownable, Ownable} from "../../access/ownable/Ownable.sol";
import {Access} from "../../access/Access.sol";
import {ERC721} from "./ERC721.sol";
import {IERC721} from "./interface/IERC721.sol";
import {TokenMetadata} from "../TokenMetadata/TokenMetadata.sol";
import {
    ITokenURIExtension, IContractURIExtension
} from "../../extension/examples/metadataRouter/IMetadataExtensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {PermissionsStorage} from "../../access/permissions/PermissionsStorage.sol";
import {IERC721Rails} from "./interface/IERC721Rails.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

/// @notice This contract implements the Rails pattern to provide enhanced functionality for ERC721 tokens.
/// @dev ERC721A chosen for only practical solution for large token supply allocations
contract ERC721Rails is Rails, Ownable, Initializable, TokenMetadata, ERC721, IERC721Rails {
    /// @notice Declaring this contract `Initializable()` invokes `_disableInitializers()`,
    /// in order to preemptively mitigate proxy privilege escalation attack vectors
    constructor() Initializable() {}

    /// @dev Owner address is implemented using the `Ownable` contract's function
    function owner() public view override(Access, Ownable) returns (address) {
        return Ownable.owner();
    }

    /// @notice Cannot call initialize within a proxy constructor, only post-deployment in a factory
    /// @inheritdoc IERC721Rails
    function initialize(address owner_, string calldata name_, string calldata symbol_, bytes calldata initData)
        external
        initializer
    {
        ERC721._initialize();
        _setName(name_);
        _setSymbol(symbol_);
        if (initData.length > 0) {
            /// @dev if called within a constructor, self-delegatecall will not work because this address does not yet have
            /// bytecode implementing the init functions -> revert here with nicer error message
            if (address(this).code.length == 0) {
                revert CannotInitializeWhileConstructing();
            }
            // make msg.sender the owner to ensure they have all permissions for further initialization
            _transferOwnership(msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // if sender and owner arg are different, transfer ownership to desired address
            if (msg.sender != owner_) {
                _transferOwnership(owner_);
            }
        } else {
            _transferOwnership(owner_);
        }
    }

    /// @dev Override starting tokenId exposed by ERC721A, which is 0 by default
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*==============
        METADATA
    ==============*/

    /// @inheritdoc Rails
    function supportsInterface(bytes4 interfaceId) public view override(Rails, ERC721) returns (bool) {
        return Rails.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned ERC721 name string
    function name() public view override(IERC721, TokenMetadata) returns (string memory) {
        return TokenMetadata.name();
    }

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned ERC721 symbol string
    function symbol() public view override(IERC721, TokenMetadata) returns (string memory) {
        return TokenMetadata.symbol();
    }

    /// @notice Contracts inheriting ERC721A are required to implement `tokenURI()`
    /// @dev Function to return the ERC721 tokenURI using extended URI logic
    /// from the `TokenURIExtension` contract
    /// @param tokenId The token ID for which to query a URI
    /// @return _ The returned tokenURI string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return ITokenURIExtension(address(this)).ext_tokenURI(tokenId);
    }

    /// @dev Returns the contract URI for this ERC20 token, a modern standard for NFTs
    /// @notice Uses extended contract URI logic from the `ContractURIExtension` contract
    /// @return _ The returned contractURI string
    function contractURI() public view override returns (string memory) {
        // to avoid clashing selectors, use standardized `ext_` prefix
        return IContractURIExtension(address(this)).ext_contractURI();
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IERC721Rails
    function mintTo(address recipient, uint256 quantity)
        external
        onlyPermission(Operations.MINT)
        returns (uint256 mintStartTokenId)
    {
        mintStartTokenId = _nextTokenId();
        _safeMint(recipient, quantity);
    }

    /// @inheritdoc IERC721Rails
    function burn(uint256 tokenId) external {
        if (!hasPermission(Operations.BURN, msg.sender)) {
            _checkCanTransfer(ownerOf(tokenId), tokenId);
            /// @todo resolve gas inefficiency of reading ownerOf twice
        }
        _burn(tokenId);
    }

    /*===========
        GUARD
    ===========*/

    /// @dev Hook called before token transfers. Calls into the given guard.
    /// Provides one of three token operations and its accompanying data to the guard.
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        view
        override
        returns (address guard, bytes memory beforeCheckData)
    {
        bytes8 operation;
        if (from == address(0)) {
            operation = Operations.MINT;
        } else if (to == address(0)) {
            operation = Operations.BURN;
        } else {
            operation = Operations.TRANSFER;
        }
        bytes memory data = abi.encode(msg.sender, from, to, startTokenId, quantity);

        return checkGuardBefore(operation, data);
    }

    /// @dev Hook called after token transfers. Calls into the given guard.
    function _afterTokenTransfers(address guard, bytes memory checkBeforeData) internal view override {
        checkGuardAfter(guard, checkBeforeData, ""); // no execution data
    }

    /*===================
        AUTHORIZATION
    ===================*/

    /// @dev Check for `Operations.TRANSFER` permission before ownership and approval
    function _checkCanTransfer(address account, uint256 tokenId) internal virtual override {
        if (!hasPermission(Operations.TRANSFER, msg.sender)) {
            super._checkCanTransfer(account, tokenId);
        }
    }

    /// @dev Restrict Permissions write access to the `Operations.PERMISSIONS` permission
    function _checkCanUpdatePermissions() internal view override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    /// @dev Restrict Guards write access to the `Operations.GUARDS` permission
    function _checkCanUpdateGuards() internal view override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    /// @dev Restrict calls via Execute to the `Operations.EXECUTE` permission
    function _checkCanExecuteCall() internal view override {
        _checkPermission(Operations.CALL, msg.sender);
    }

    /// @dev Restrict ERC-165 write access to the `Operations.INTERFACE` permission
    function _checkCanUpdateInterfaces() internal view override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }

    /// @dev Restrict TokenMetadata write access to the `Operations.METADATA` permission
    function _checkCanUpdateTokenMetadata() internal view override {
        _checkPermission(Operations.METADATA, msg.sender);
    }

    /// @dev Only the `owner` possesses Extensions write access
    function _checkCanUpdateExtensions() internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
    }

    /// @dev Only the `owner` possesses UUPS upgrade rights
    function _authorizeUpgrade(address) internal view override {
        // changes to core functionality must be restricted to owners to protect admins overthrowing
        _checkOwner();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {Access} from "./access/Access.sol";
import {Guards} from "./guard/Guards.sol";
import {Extensions} from "./extension/Extensions.sol";
import {SupportsInterface} from "./lib/ERC165/SupportsInterface.sol";
import {Execute} from "./lib/Execute.sol";
import {Operations} from "./lib/Operations.sol";

/**
 * A Solidity framework for creating complex and evolving onchain structures.
 * All Rails-inherited contracts receive a batteries-included contract development kit.
 */
abstract contract Rails is Access, Guards, Extensions, SupportsInterface, Execute, Multicall, UUPSUpgradeable {
    /// @dev Function to return the contractURI for child contracts inheriting this one
    /// Unimplemented to abstract away this functionality and render it opt-in
    /// @return uri The returned contractURI string
    function contractURI() public view virtual returns (string memory uri) {}

    /// @inheritdoc SupportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Access, Guards, Extensions, SupportsInterface, Execute)
        returns (bool)
    {
        return Access.supportsInterface(interfaceId) || Guards.supportsInterface(interfaceId)
            || Extensions.supportsInterface(interfaceId) || SupportsInterface.supportsInterface(interfaceId)
            || Execute.supportsInterface(interfaceId);
    }

    /// @inheritdoc Execute
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        override
        returns (address guard, bytes memory checkBeforeData)
    {
        return checkGuardBefore(Operations.CALL, abi.encode(to, value, data));
    }

    /// @inheritdoc Execute
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual
        override
    {
        checkGuardAfter(guard, checkBeforeData, executeData);
    }
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

import {Permissions} from "./permissions/Permissions.sol";
import {PermissionsStorage} from "./permissions/PermissionsStorage.sol";
import {Operations} from "../lib/Operations.sol";

abstract contract Access is Permissions {
    /// @dev Supports multiple owner implementations, e.g. explicit storage vs NFT-owner (ERC-6551)
    function owner() public view virtual returns (address);

    /// @dev Function to check one of 3 permissions criterion is true: owner, admin, or explicit permission
    /// @param operation The explicit permission to check permission for
    /// @param account The account address whose permission will be checked
    /// @return _ Boolean value declaring whether or not the address possesses permission for the operation
    function hasPermission(bytes8 operation, address account) public view override returns (bool) {
        // 3 tiers: has operation permission, has admin permission, or is owner
        if (super.hasPermission(operation, account)) {
            return true;
        }
        if (operation != Operations.ADMIN && super.hasPermission(Operations.ADMIN, account)) {
            return true;
        }
        return account == owner();
    }

    /// @inheritdoc Permissions
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721, IERC721Receiver} from "./interface/IERC721.sol";
import {ERC721Storage} from "./ERC721Storage.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";

abstract contract ERC721 is Initializable, IERC721 {
    /// @dev Large batch mints of ERC721A tokens can result in high gas costs upon first transfer of high tokenIds
    /// To improve UX for token owners unaware of this fact, a mint batch size of 500 is enforced
    uint256 public constant MAX_MINT_BATCH_SIZE = 500;

    /*===========
        VIEWS
    ===========*/

    // global token values

    function totalSupply() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex - layout.burnCounter - _startTokenId();
    }

    function totalMinted() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex - _startTokenId();
    }

    function totalBurned() public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.burnCounter;
    }

    // owner values

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].balance;
    }

    function numberMinted(address owner) public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].numMinted;
    }

    function numberBurned(address owner) public view returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.owners[owner].numBurned;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _batchMarkerDataOf(tokenId).owner; // reverts if token not owned
    }

    // approvals

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return layout.tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.operatorApprovals[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return interfaceId == 0x01ffc9a7 // ERC165 interface ID for ERC165.
            || interfaceId == 0x80ac58cd // ERC165 interface ID for ERC721.
            || interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /*=============
        SETTERS
    =============*/

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _checkCanTransfer(from, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /*=================
        INITIALIZER
    =================*/

    function _initialize() internal onlyInitializing {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.currentIndex = _startTokenId();
    }

    /*===============
        INTERNALS
    ===============*/

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return layout.currentIndex;
    }

    /// @notice Returns the token data for the token marking this batch mint
    /// @dev If tokenId was minted in a batch and tokenId is not the first id in the batch,
    ///      then the returned data will be for a different tokenId.
    function _batchMarkerDataOf(uint256 tokenId) private view returns (ERC721Storage.TokenData memory) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        uint256 curr = tokenId;

        unchecked {
            if (curr >= _startTokenId()) {
                if (curr < layout.currentIndex) {
                    ERC721Storage.TokenData memory data = layout.tokens[curr];
                    // If not burned.
                    if (!data.burned) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `data.owner != address(0) && data.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `data.owner == address(0) && data.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (data.owner == address(0) && !data.burned) {
                            data = layout.tokens[--curr];
                        }
                        return data;
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        return _startTokenId() <= tokenId && tokenId < layout.currentIndex // If within bounds,
            && !layout.tokens[tokenId].burned; // and not burned.
    }

    // approvals

    function _approve(address operator, uint256 tokenId) internal {
        if (operator == address(0)) {
            revert ApprovalInvalidOperator();
        }
        address owner = ownerOf(tokenId);

        if (msg.sender != owner) {
            if (!isApprovedForAll(owner, msg.sender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        if (operator == address(0)) {
            revert ApprovalInvalidOperator();
        }
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        layout.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // token transfers

    function _mint(address to, uint256 quantity) internal {
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_BATCH_SIZE) revert ExceedsMaxMintBatchSize(quantity);
        if (to == address(0)) revert MintToZeroAddress();

        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        uint256 startTokenId = layout.currentIndex;

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // update global counters
        uint256 endTokenIndex = startTokenId + quantity;
        layout.currentIndex = endTokenIndex;

        // update owner counters
        ERC721Storage.OwnerData storage ownerData = layout.owners[to];
        /// @dev is there a clean way to combine these two operations into one write while preserving the nice syntax?
        ownerData.balance += uint64(quantity);
        ownerData.numMinted += uint64(quantity);

        // update token data
        layout.tokens[startTokenId] = ERC721Storage.TokenData(to, uint48(block.timestamp), false, quantity == 1);

        // emit events
        for (uint256 tokenId = startTokenId; tokenId < endTokenIndex; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    /// @dev approval checks are not made in this internal function, make them when wrapping in a public function
    function _burn(uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory batchMarkerData = _batchMarkerDataOf(tokenId); // reverts if tokenId is burned
        address from = batchMarkerData.owner;

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, address(0), tokenId, 1);

        // update global counters
        layout.burnCounter++;

        // update owner counters
        ERC721Storage.OwnerData storage ownerData = layout.owners[from];
        /// @dev is there a clean way to combine these two operations into one write while preserving the nice syntax?
        --ownerData.balance;
        ++ownerData.numBurned;

        // update token data
        layout.tokens[tokenId] = ERC721Storage.TokenData(from, uint48(block.timestamp), true, true);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        // set next token as new batch marker if it is in the same batch
        if (!batchMarkerData.nextInitialized) {
            // next token is potentially uninitialized
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId < layout.currentIndex) {
                // nextTokenId has been minted
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    /**
                     * next token is uninitialized so set:
                     * - owner = batch marker owner
                     * - ownerUpdatedAt = batch marker ownerUpdatedAt
                     * - burned = false
                     * - nextInitialized = false
                     */
                    layout.tokens[nextTokenId] =
                        ERC721Storage.TokenData(batchMarkerData.owner, batchMarkerData.ownerUpdatedAt, false, false);
                }
            }
        }

        // emit events
        emit Transfer(from, address(0), tokenId);

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    /// @dev approval checks are not made in this internal function, make them when wrapping in a public function
    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        ERC721Storage.TokenData memory batchMarkerData = _batchMarkerDataOf(tokenId); // reverts if tokenId is burned

        if (batchMarkerData.owner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // check before
        (address guard, bytes memory beforeCheckData) = _beforeTokenTransfers(from, to, tokenId, 1);

        // update owner counters
        --layout.owners[from].balance;
        ++layout.owners[to].balance;

        // update token data
        layout.tokens[tokenId] = ERC721Storage.TokenData(to, uint48(block.timestamp), false, true);

        // clear approval from previous owner
        delete layout.tokenApprovals[tokenId];

        // set next token as new batch marker if it is in the same batch
        if (!batchMarkerData.nextInitialized) {
            // next token is potentially uninitialized
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId < layout.currentIndex) {
                // nextTokenId has been minted
                ERC721Storage.TokenData storage nextTokenData = layout.tokens[nextTokenId];
                if (nextTokenData.owner == address(0) && !nextTokenData.burned) {
                    /**
                     * next token is uninitialized so set:
                     * - owner = batch marker owner
                     * - ownerUpdatedAt = batch marker ownerUpdatedAt
                     * - burned = false
                     * - nextInitialized = false
                     */
                    layout.tokens[nextTokenId] =
                        ERC721Storage.TokenData(batchMarkerData.owner, batchMarkerData.ownerUpdatedAt, false, false);
                }
            }
        }

        // emit events
        emit Transfer(from, to, tokenId);

        // check after
        _afterTokenTransfers(guard, beforeCheckData);
    }

    // safe token transfers

    function _safeMint(address to, uint256 quantity) internal virtual {
        ERC721Storage.Layout storage layout = ERC721Storage.layout();
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = layout.currentIndex;
                uint256 index = end - quantity;
                /// @dev why does this need to be checked in a loop versus once?
                do {
                    _checkOnERC721Received(address(0), to, index++, "");
                } while (index < end);
                // Reentrancy protection.
                if (layout.currentIndex != end) revert();
            }
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /*====================
        AUTHORIZATION
    ====================*/

    function _checkCanTransfer(address account, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != msg.sender) {
            if (!isApprovedForAll(account, msg.sender)) {
                if (getApproved(tokenId) != msg.sender) {
                    revert TransferCallerNotOwnerNorApproved();
                }
            }
        }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        returns (address guard, bytes memory beforeCheckData)
    {}

    function _afterTokenTransfers(address guard, bytes memory beforeCheckData) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721 {
    // events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // errors
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApprovalInvalidOperator();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    error MintERC2309QuantityExceedsLimit();
    error OwnershipNotInitializedForExtraData();
    error ExceedsMaxMintBatchSize(uint256 quantity);

    // ERC721 spec
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // base
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function totalBurned() external view returns (uint256);
    function numberMinted(address tokenOwner) external view returns (uint256);
    function numberBurned(address tokenOwner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenMetadata} from "./ITokenMetadata.sol";
import {TokenMetadataStorage} from "./TokenMetadataStorage.sol";

abstract contract TokenMetadata is ITokenMetadata {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc ITokenMetadata
    function name() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.name;
    }

    /// @inheritdoc ITokenMetadata
    function symbol() public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage layout = TokenMetadataStorage.layout();
        return layout.symbol;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set the name for a token implementation
    /// @param name_ The name string to set
    function setName(string calldata name_) external canUpdateTokenMetadata {
        _setName(name_);
    }

    /// @dev Function to set the symbol for a token implementation
    /// @param symbol_ The symbol string to set
    function setSymbol(string calldata symbol_) external canUpdateTokenMetadata {
        _setSymbol(symbol_);
    }

    /*===============
        INTERNALS
    ===============*/

    function _setName(string calldata name_) internal {
        TokenMetadataStorage.layout().name = name_;
        emit NameUpdated(name_);
    }

    function _setSymbol(string calldata symbol_) internal {
        TokenMetadataStorage.layout().symbol = symbol_;
        emit SymbolUpdated(symbol_);
    }

    /*====================
        AUTHORIZATION
    ====================*/

    modifier canUpdateTokenMetadata() {
        _checkCanUpdateTokenMetadata();
        _;
    }

    /// @dev Function to implement access control restricting setter functions
    function _checkCanUpdateTokenMetadata() internal view virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenURIExtension {
    /// @dev Function to extend the `tokenURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IContractURIExtension {
    /// @dev Function to extend the `contractURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_contractURI() external view returns (string memory);
}

interface IMetadataRouter {
    /// @dev Returns the token URI
    /// @return '' The returned tokenURI string
    function tokenURI(address contractAddress, uint256 tokenId) external view returns (string memory);

    /// @dev Returns the contract URI, a modern standard for NFTs
    /// @return '' The returned contractURI string
    function contractURI(address contractAddress) external view returns (string memory);
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

import {IInitializable} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializable {
    /*===========
        LOCK
    ===========*/

    /// @dev Logic implementation contract disables `initialize()` from being called
    /// to prevent privilege escalation and 'exploding kitten' attacks
    /// @notice This applies to all child contracts inheriting from this one and use its constructor
    constructor() {
        _disableInitializers();
    }

    function _disableInitializers() internal virtual {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();

        if (layout._initializing) {
            revert AlreadyInitialized();
        }
        if (layout._initialized == false) {
            layout._initialized = true;
            emit Initialized();
        }
    }

    /*===============
        MODIFIERS
    ===============*/

    modifier initializer() {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        if (layout._initialized) {
            revert AlreadyInitialized();
        }
        layout._initializing = true;

        _;

        layout._initializing = false;
        layout._initialized = true;
        emit Initialized();
    }

    modifier onlyInitializing() {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        if (!layout._initializing) {
            revert NotInitializing();
        }

        _;
    }

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IInitializable
    function initialized() public view returns (bool) {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        return layout._initialized;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuards} from "./interface/IGuards.sol";
import {GuardsInternal} from "./GuardsInternal.sol";

abstract contract Guards is GuardsInternal {
    /*===========
        VIEWS
    ===========*/

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IGuards).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set a guard contract for a given operation.
    /// @param operation The operation for which to add a guard contract.
    /// @param implementation The guard contract address containing code to hook before and after operations
    /// @notice Due to EXTCODESIZE check within `_requireContract()`, this function will revert if called
    /// during the constructor of the contract at `implementation`. Deploy `implementation` contract first.
    function setGuard(bytes8 operation, address implementation) public virtual canUpdateGuards {
        _setGuard(operation, implementation);
    }

    /// @dev Function to remove a guard for a given operation.
    /// @param operation The operation for which to remove its guard contract.
    function removeGuard(bytes8 operation) public virtual canUpdateGuards {
        _removeGuard(operation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateGuards() {
        _checkCanUpdateGuards();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set Guards
    /// @notice Should revert upon failure.
    function _checkCanUpdateGuards() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensions} from "./interface/IExtensions.sol";
import {IExtension} from "./interface/IExtension.sol";
import {ExtensionsStorage} from "./ExtensionsStorage.sol";
import {Contract} from "../lib/Contract.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Extensions - A contract for managing contract extensions via function delegation
/// @notice This abstract contract provides functionality for extending function selectors using external contracts.
abstract contract Extensions is IExtensions {
    /*==================
        CALL ROUTING
    ==================*/

    /// @dev Fallback function to delegate calls to extension contracts.
    /// @param '' The data from which `msg.sig` and `msg.data` are grabbed to craft a delegatecall
    /// @return '' The return data from using delegatecall on the extension contract.
    fallback(bytes calldata) external payable virtual returns (bytes memory) {
        // Obtain the implementation address for the function selector.
        address implementation = extensionOf(msg.sig);
        // Delegate the call to the extension contract.
        return Address.functionDelegateCall(implementation, msg.data); // library checks for target contract existence
    }

    receive() external payable virtual {}

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IExtensions
    function hasExtended(bytes4 selector) public view virtual override returns (bool) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation != address(0);
    }

    /// @inheritdoc IExtensions
    function extensionOf(bytes4 selector) public view virtual returns (address implementation) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation;
    }

    /// @inheritdoc IExtensions
    function getAllExtensions() public view virtual returns (Extension[] memory extensions) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        uint256 len = layout._selectors.length;
        extensions = new Extension[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = layout._selectors[i];
            ExtensionsStorage.ExtensionData memory extension = layout._extensions[selector];
            extensions[i] = Extension(
                selector,
                extension.implementation,
                extension.updatedAt,
                IExtension(extension.implementation).signatureOf(selector)
            );
        }
        return extensions;
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set an extension contract for a given selector.
    /// @param selector The function selector for which to add an extension contract.
    /// @param implementation The extension contract address containing code to extend a selector
    function setExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _setExtension(selector, implementation);
    }

    /// @dev Function to remove an extension for a given selector.
    /// @param selector The function selector for which to remove its extension contract.
    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    /*===============
        INTERNALS
    ===============*/

    function _setExtension(bytes4 selector, address implementation) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        Contract._requireContract(implementation);
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        address oldImplementation = oldExtension.implementation;
        if (oldImplementation != address(0)) {
            // update existing Extension, reverting if `implementation` is unchanged
            if (implementation == oldImplementation) {
                revert ExtensionUnchanged(selector, oldImplementation, implementation);
            }

            // update only necessary struct members to save on SSTOREs
            layout._extensions[selector].updatedAt = uint40(block.timestamp);
            layout._extensions[selector].implementation = implementation;
        } else {
            // add new Extension
            // new length will be `len + 1`, so this extension has index `len`
            ExtensionsStorage.ExtensionData memory extension = ExtensionsStorage.ExtensionData(
                uint24(layout._selectors.length), uint40(block.timestamp), implementation
            );

            layout._extensions[selector] = extension;
            layout._selectors.push(selector); // set new selector at index and increment length
        }

        emit ExtensionUpdated(selector, oldImplementation, implementation);
    }

    function _removeExtension(bytes4 selector) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        if (oldExtension.implementation == address(0)) revert ExtensionDoesNotExist(selector);

        uint256 lastIndex = layout._selectors.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldExtension.index < lastIndex) {
            bytes4 lastSelector = layout._selectors[lastIndex];
            ExtensionsStorage.ExtensionData memory lastExtension = layout._extensions[lastSelector];
            lastExtension.index = oldExtension.index;
            layout._selectors[oldExtension.index] = lastSelector;
            layout._extensions[lastSelector] = lastExtension;
        }
        delete layout._extensions[selector];
        layout._selectors.pop(); // delete extension in last index and decrement length

        emit ExtensionUpdated(selector, oldExtension.implementation, address(0));
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set extensions
    /// @notice Should revert upon failure.
    function _checkCanUpdateExtensions() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISupportsInterface} from "./ISupportsInterface.sol";
import {SupportsInterfaceStorage} from "./SupportsInterfaceStorage.sol";

abstract contract SupportsInterface is ISupportsInterface {
    /// @dev For explicit EIP165 compliance, the interfaceId of the standard IERC165 implementation
    /// which is derived from `bytes4(keccak256('supportsInterface(bytes4)'))`
    /// is stored directly as a constant in order to preserve Rails's ERC7201 namespace pattern
    bytes4 public constant erc165Id = 0x01ffc9a7;

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc ISupportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc ISupportsInterface
    function addInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _addInterface(interfaceId);
    }

    /// @inheritdoc ISupportsInterface
    function removeInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _removeInterface(interfaceId);
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev To remain EIP165 compliant, this function must not be called with `bytes4(type(uint32).max)`
    /// Setting `0xffffffff` as true by providing it as `interfaceId` will disable support of EIP165 in child contracts
    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        return interfaceId == erc165Id || layout._supportsInterface[interfaceId];
    }

    function _addInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (layout._supportsInterface[interfaceId]) revert InterfaceAlreadyAdded(interfaceId);
        layout._supportsInterface[interfaceId] = true;
    }

    function _removeInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (!layout._supportsInterface[interfaceId]) revert InterfaceNotAdded(interfaceId);
        delete layout._supportsInterface[interfaceId];
    }

    /*====================
        AUTHORIZATION
    ====================*/

    modifier canUpdateInterfaces() {
        _checkCanUpdateInterfaces();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set interfaces
    /// @notice Should revert upon failure.
    function _checkCanUpdateInterfaces() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Execute - A contract for executing calls to other contracts
/// @notice This abstract contract provides functionality for executing *only* calls to other contracts
abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    /// @dev Execute a call to another contract with the specified target address, value, and data.
    /// @param to The address of the target contract to call.
    /// @param value The amount of native currency to send with the call.
    /// @param data The call's data.
    /// @return executeData The return data from the executed call.
    function executeCall(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = _call(to, value, data);
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    /// @notice Temporary backwards compatibility with offchain API
    function execute(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = _call(to, value, data);
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(Execute).interfaceId;
    }

    function _call(address to, uint256 value, bytes calldata data) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @dev Internal function to check if the caller has permission to execute calls.
    function _checkCanExecuteCall() internal view virtual;

    /// @dev Hook to perform pre-call checks and return guard information.
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Hook to perform post-call checks.
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "./interface/IPermissions.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

abstract contract Permissions is IPermissions {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IPermissions
    function checkPermission(bytes8 operation, address account) public view {
        _checkPermission(operation, account);
    }

    /// @inheritdoc IPermissions
    function hasPermission(bytes8 operation, address account) public view virtual returns (bool) {
        Storage.PermissionData memory permission = Storage.layout()._permissions[Storage._packKey(operation, account)];
        return permission.exists;
    }

    /// @inheritdoc IPermissions
    function getAllPermissions() public view returns (Permission[] memory permissions) {
        Storage.Layout storage layout = Storage.layout();
        uint256 len = layout._permissionKeys.length;
        permissions = new Permission[](len);
        for (uint256 i; i < len; i++) {
            uint256 permissionKey = layout._permissionKeys[i];
            (bytes8 operation, address account) = Storage._unpackKey(permissionKey);
            Storage.PermissionData memory permission = layout._permissions[permissionKey];
            permissions[i] = Permission(operation, account, permission.updatedAt);
        }
        return permissions;
    }

    /// @inheritdoc IPermissions
    function hashOperation(string memory name) public pure returns (bytes8) {
        return Storage._hashOperation(name);
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IPermissions
    function addPermission(bytes8 operation, address account) public virtual {
        _checkCanUpdatePermissions();
        _addPermission(operation, account);
    }

    /// @inheritdoc IPermissions
    function removePermission(bytes8 operation, address account) public virtual {
        if (account != msg.sender) {
            _checkCanUpdatePermissions();
        }
        _removePermission(operation, account);
    }

    /*===============
        INTERNALS
    ===============*/

    function _addPermission(bytes8 operation, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        if (layout._permissions[permissionKey].exists) {
            revert PermissionAlreadyExists(operation, account);
        }
        // new length will be `len + 1`, so this permission has index `len`
        Storage.PermissionData memory permission =
            Storage.PermissionData(uint24(layout._permissionKeys.length), uint40(block.timestamp), true);

        layout._permissions[permissionKey] = permission;
        layout._permissionKeys.push(permissionKey); // set new permissionKey at index and increment length

        emit PermissionAdded(operation, account);
    }

    function _removePermission(bytes8 operation, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        Storage.PermissionData memory oldPermissionData = layout._permissions[permissionKey];
        if (!oldPermissionData.exists) {
            revert PermissionDoesNotExist(operation, account);
        }

        uint256 lastIndex = layout._permissionKeys.length - 1;
        // if removing item not at the end of the array, swap item with last in array
        if (oldPermissionData.index < lastIndex) {
            uint256 lastPermissionKey = layout._permissionKeys[lastIndex];
            Storage.PermissionData memory lastPermissionData = layout._permissions[lastPermissionKey];
            lastPermissionData.index = oldPermissionData.index;
            layout._permissionKeys[oldPermissionData.index] = lastPermissionKey;
            layout._permissions[lastPermissionKey] = lastPermissionData;
        }
        delete layout._permissions[permissionKey];
        layout._permissionKeys.pop(); // delete guard in last index and decrement length

        emit PermissionRemoved(operation, account);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier onlyPermission(bytes8 operation) {
        _checkPermission(operation, msg.sender);
        _;
    }

    /// @dev Function to ensure `account` has permission to carry out `operation`
    function _checkPermission(bytes8 operation, address account) internal view {
        if (!hasPermission(operation, account)) revert PermissionDoesNotExist(operation, account);
    }

    /// @dev Function to implement access control restricting setter functions
    function _checkCanUpdatePermissions() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC721Storage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.ERC721")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x47128c4db77b17da64f911b687ea48877ae0378dea32ab30dfa81e60251d2a00;

    struct Layout {
        uint256 currentIndex; // max supply is 18e18
        uint256 burnCounter;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => TokenData) tokens;
        mapping(address => OwnerData) owners;
    }

    struct TokenData {
        // ERC-721
        address owner; //         [0..159]
        // ERC-721A
        uint48 ownerUpdatedAt; // [160..207]
        bool burned; //           [208..215]
        bool nextInitialized; //  [216..223]
    }

    struct OwnerData {
        // ERC-721
        uint64 balance; //   [0..63]
        // ERC-721A
        uint64 numMinted; // [64..127]
        uint64 numBurned; // [128..191]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenMetadata {
    // events
    event NameUpdated(string name);
    event SymbolUpdated(string symbol);

    /// @dev Function to return the name of a token implementation
    /// @return _ The returned name string
    function name() external view returns (string calldata);

    /// @dev Function to return the symbol of a token implementation
    /// @return _ The returned symbol string
    function symbol() external view returns (string calldata);

    /// @dev Function to set the name for a token implementation
    /// @param name The name string to set
    function setName(string calldata name) external;

    /// @dev Function to set the symbol for a token implementation
    /// @param symbol The symbol string to set
    function setSymbol(string calldata symbol) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library TokenMetadataStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.TokenMetadata")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x4f2e116bc9c7d925ed26e4ecc4178db33477c50c415adbd68f1ed8f0d8dace00;

    struct Layout {
        string name;
        string symbol;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IInitializable {
    // events
    event Initialized();

    // errors
    error AlreadyInitialized();
    error NotInitializing();
    error CannotInitializeWhileConstructing();

    /// @dev View function to return whether a proxy contract has been initialized.
    function initialized() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library InitializableStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Initializable")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x8ca77559b51bdadaef66f8dec08105b4dd195463fda0f501696f5581b908dc00;

    struct Layout {
        bool _initialized;
        bool _initializing;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuards {
    struct Guard {
        bytes8 operation;
        address implementation;
        uint40 updatedAt;
    }

    // events
    event GuardUpdated(bytes8 indexed operation, address indexed oldGuard, address indexed newGuard);

    // errors
    error GuardDoesNotExist(bytes8 operation);
    error GuardUnchanged(bytes8 operation, address oldImplementation, address newImplementation);
    error GuardRejected(bytes8 operation, address guard);

    /// @dev Perform checks before executing a specific operation and return guard information.
    /// @param operation The operation identifier to check.
    /// @param data Additional data associated with the operation.
    /// @return guard The address of the guard contract responsible for the operation.
    /// @return checkBeforeData Additional data from the guard contract's checkBefore function.
    function checkGuardBefore(bytes8 operation, bytes calldata data)
        external
        view
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Perform checks after executing an operation.
    /// @param guard The address of the guard contract responsible for the operation.
    /// @param checkBeforeData Additional data obtained from the guard's checkBefore function.
    /// @param executionData The execution data associated with the operation.
    function checkGuardAfter(address guard, bytes calldata checkBeforeData, bytes calldata executionData)
        external
        view;

    /// @dev Get the guard contract address responsible for a specific operation.
    /// @param operation The operation identifier.
    /// @return implementation The address of the guard contract for the operation.
    function guardOf(bytes8 operation) external view returns (address implementation);

    /// @dev Get an array of all registered guard contracts.
    /// @return Guards An array containing information about all registered guard contracts.
    function getAllGuards() external view returns (Guard[] memory Guards);

    /// @dev Set a guard contract for a specific operation.
    /// @param operation The operation identifier for which to set the guard contract.
    /// @param implementation The address of the guard contract to set.
    function setGuard(bytes8 operation, address implementation) external;

    /// @dev Remove the guard contract for a specific operation.
    /// @param operation The operation identifier for which to remove the guard contract.
    function removeGuard(bytes8 operation) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuards} from "./interface/IGuards.sol";
import {IGuard} from "./interface/IGuard.sol";
import {GuardsStorage} from "./GuardsStorage.sol";
import {Contract} from "../lib/Contract.sol";

abstract contract GuardsInternal is IGuards {
    using GuardsStorage for address;
    /*===========
        HOOKS
    ===========*/

    /// @inheritdoc IGuards
    function checkGuardBefore(bytes8 operation, bytes memory data)
        public
        view
        returns (address guard, bytes memory checkBeforeData)
    {
        guard = guardOf(operation);
        if (guard.autoReject()) {
            revert GuardRejected(operation, guard);
        } else if (guard.autoApprove()) {
            return (guard, "");
        }

        checkBeforeData = IGuard(guard).checkBefore(msg.sender, data); // revert will cascade

        return (guard, checkBeforeData);
    }

    /// @inheritdoc IGuards
    function checkGuardAfter(address guard, bytes memory checkBeforeData, bytes memory executionData) public view {
        // only check guard if not autoApprove, autoReject will have already reverted
        if (!guard.autoApprove()) {
            IGuard(guard).checkAfter(checkBeforeData, executionData); // revert will cascade
        }
    }

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IGuards
    function guardOf(bytes8 operation) public view returns (address implementation) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        return layout._guards[operation].implementation;
    }

    /// @inheritdoc IGuards
    function getAllGuards() public view virtual returns (Guard[] memory guards) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        uint256 len = layout._operations.length;
        guards = new Guard[](len);
        for (uint256 i; i < len; i++) {
            bytes8 operation = layout._operations[i];
            GuardsStorage.GuardData memory guard = layout._guards[operation];
            guards[i] = Guard(operation, guard.implementation, guard.updatedAt);
        }
        return guards;
    }

    /*=============
        SETTERS
    =============*/

    function _setGuard(bytes8 operation, address implementation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        // require implementation is contract unless it is MAX_ADDRESS
        if (implementation != GuardsStorage.MAX_ADDRESS) {
            Contract._requireContract(implementation); // fails on adding address(0) here
        }

        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation != address(0)) {
            // update

            if (implementation == oldGuard.implementation) {
                revert GuardUnchanged(operation, oldGuard.implementation, implementation);
            }
            GuardsStorage.GuardData memory newGuard =
                GuardsStorage.GuardData(uint24(oldGuard.index), uint40(block.timestamp), implementation);
            layout._guards[operation] = newGuard;
        } else {
            // add

            // new length will be `len + 1`, so this guard has index `len`
            GuardsStorage.GuardData memory guard =
                GuardsStorage.GuardData(uint24(layout._operations.length), uint40(block.timestamp), implementation);
            layout._guards[operation] = guard;
            layout._operations.push(operation); // set new operation at index and increment length
        }

        emit GuardUpdated(operation, oldGuard.implementation, implementation);
    }

    function _removeGuard(bytes8 operation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);

        uint256 lastIndex = layout._operations.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldGuard.index < lastIndex) {
            bytes8 lastOperation = layout._operations[lastIndex];
            GuardsStorage.GuardData memory lastGuard = layout._guards[lastOperation];
            lastGuard.index = oldGuard.index;
            layout._operations[oldGuard.index] = lastOperation;
            layout._guards[lastOperation] = lastGuard;
        }
        delete layout._guards[operation];
        layout._operations.pop(); // delete guard in last index and decrement length

        emit GuardUpdated(operation, oldGuard.implementation, address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensions {
    struct Extension {
        bytes4 selector;
        address implementation;
        uint40 updatedAt;
        string signature;
    }

    // events
    event ExtensionUpdated(bytes4 indexed selector, address indexed oldExtension, address indexed newExtension);

    // errors
    error ExtensionDoesNotExist(bytes4 selector);
    error ExtensionAlreadyExists(bytes4 selector);
    error ExtensionUnchanged(bytes4 selector, address oldImplementation, address newImplementation);

    /// @dev Function to check whether the given selector is mapped to an extension contract
    /// @param selector The function selector to query
    /// @return '' Boolean value identifying if the given selector is extended or not
    function hasExtended(bytes4 selector) external view returns (bool);

    /// @dev Function to get the extension contract address extending a specific func selector.
    /// @param selector The function selector to query for its extension.
    /// @return implementation The address of the extension contract for the function.
    function extensionOf(bytes4 selector) external view returns (address implementation);

    /// @dev Function to get an array of all registered extension contracts.
    /// @return extensions An array containing information about all registered extensions.
    function getAllExtensions() external view returns (Extension[] memory extensions);

    /// @dev Function to set a extension contract for a specific function selector.
    /// @param selector The function selector for which to set an extension contract.
    /// @param implementation The address of the extension contract to map to a function.
    function setExtension(bytes4 selector, address implementation) external;

    /// @dev Function to remove the extension contract for a function.
    /// @param selector The function selector for which to remove its extension.
    function removeExtension(bytes4 selector) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library ExtensionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Extensions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x24b223a3be882d5d1d257152fdb15a02ae59c6d11e58bc0c17888d15a9b15b00;

    struct Layout {
        bytes4[] _selectors;
        mapping(bytes4 => ExtensionData) _extensions;
    }

    struct ExtensionData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

library Contract {
    error InvalidContract(address implementation);

    function _requireContract(address implementation) internal view {
        if (!Address.isContract(implementation)) revert InvalidContract(implementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISupportsInterface {
    // events
    event InterfaceAdded(bytes4 indexed interfaceId);
    event InterfaceRemoved(bytes4 indexed interfaceId);

    // errors
    error InterfaceAlreadyAdded(bytes4 interfaceId);
    error InterfaceNotAdded(bytes4 interfaceId);

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @dev Function to add support for a specific interface.
    /// @param interfaceId The interface identifier to add support for.
    function addInterface(bytes4 interfaceId) external;

    /// @dev Function to remove support for a specific interface.
    /// @param interfaceId The interface identifier to remove support for.
    function removeInterface(bytes4 interfaceId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SupportsInterfaceStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.SupportsInterface")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x95a5ecff3e5709ffcdce1ca934c4b897d39c8a95719755d12b7d1e124ce29700;

    struct Layout {
        mapping(bytes4 => bool) _supportsInterface;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuard {
    function checkBefore(address operator, bytes calldata data) external view returns (bytes memory checkBeforeData);
    function checkAfter(bytes calldata checkBeforeData, bytes calldata executionData) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library GuardsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Guards")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x68fdbc9be968974abe602a5cbdd43c5fd2f2d66bfde2f0188149c63e523d4d00;
    address internal constant MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    struct Layout {
        bytes8[] _operations;
        mapping(bytes8 => GuardData) _guards;
    }

    struct GuardData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }
    // thought: add parameters `bool useBefore` and `bool useAfter` to configure if a guard should use both checks or just one

    enum CheckType {
        BEFORE,
        AFTER
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev Function to check for guards that have been set to the max address,
    /// signaling automatic rejection of an operation
    function autoReject(address guard) internal pure returns (bool) {
        return guard == MAX_ADDRESS;
    }

    /// @dev Function to check for guards that have been set to the zero address,
    /// signaling automatic approval of an operation
    function autoApprove(address guard) internal pure returns (bool) {
        return guard == address(0);
    }
}