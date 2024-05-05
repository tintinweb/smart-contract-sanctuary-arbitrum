// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
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
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

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
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../lib/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev The sender is not authorized to perform the action
    error OwnableUnauthorized();

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OwnableUnauthorized();
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert OwnableUnauthorized();
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

/// @author thirdweb, OpenZeppelin Contracts (v4.9.0)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "@solady/src/utils/MerkleProofLib.sol";
import "@solady/src/utils/ECDSA.sol";
import "@solady/src/utils/EIP712.sol";
import "@solady/src/utils/SafeTransferLib.sol";
import "@solady/src/utils/SignatureCheckerLib.sol";

import { Initializable } from "../../../extension/Initializable.sol";
import { Ownable } from "../../../extension/Ownable.sol";

import "../../../eip/interface/IERC20.sol";
import "../../../eip/interface/IERC721.sol";
import "../../../eip/interface/IERC1155.sol";

contract Airdrop is EIP712, Initializable, Ownable {
    /*///////////////////////////////////////////////////////////////
                            State, constants & structs
    //////////////////////////////////////////////////////////////*/

    /// @dev token contract address => conditionId
    mapping(address => uint256) public tokenConditionId;
    /// @dev token contract address => merkle root
    mapping(address => bytes32) public tokenMerkleRoot;
    /// @dev conditionId => hash(claimer address, token address, token id [1155]) => has claimed
    mapping(uint256 => mapping(bytes32 => bool)) private claimed;
    /// @dev Mapping from request UID => whether the request is processed.
    mapping(bytes32 => bool) public processed;

    struct AirdropContentERC20 {
        address recipient;
        uint256 amount;
    }

    struct AirdropContentERC721 {
        address recipient;
        uint256 tokenId;
    }

    struct AirdropContentERC1155 {
        address recipient;
        uint256 tokenId;
        uint256 amount;
    }

    struct AirdropRequestERC20 {
        bytes32 uid;
        address tokenAddress;
        uint256 expirationTimestamp;
        AirdropContentERC20[] contents;
    }

    struct AirdropRequestERC721 {
        bytes32 uid;
        address tokenAddress;
        uint256 expirationTimestamp;
        AirdropContentERC721[] contents;
    }

    struct AirdropRequestERC1155 {
        bytes32 uid;
        address tokenAddress;
        uint256 expirationTimestamp;
        AirdropContentERC1155[] contents;
    }

    bytes32 private constant CONTENT_TYPEHASH_ERC20 =
        keccak256("AirdropContentERC20(address recipient,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC20 =
        keccak256(
            "AirdropRequestERC20(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC20[] contents)AirdropContentERC20(address recipient,uint256 amount)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC721 =
        keccak256("AirdropContentERC721(address recipient,uint256 tokenId)");
    bytes32 private constant REQUEST_TYPEHASH_ERC721 =
        keccak256(
            "AirdropRequestERC721(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC721[] contents)AirdropContentERC721(address recipient,uint256 tokenId)"
        );

    bytes32 private constant CONTENT_TYPEHASH_ERC1155 =
        keccak256("AirdropContentERC1155(address recipient,uint256 tokenId,uint256 amount)");
    bytes32 private constant REQUEST_TYPEHASH_ERC1155 =
        keccak256(
            "AirdropRequestERC1155(bytes32 uid,address tokenAddress,uint256 expirationTimestamp,AirdropContentERC1155[] contents)AirdropContentERC1155(address recipient,uint256 tokenId,uint256 amount)"
        );

    address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*///////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/

    error AirdropInvalidProof();
    error AirdropAlreadyClaimed();
    error AirdropNoMerkleRoot();
    error AirdropValueMismatch();
    error AirdropRequestExpired(uint256 expirationTimestamp);
    error AirdropRequestAlreadyProcessed();
    error AirdropRequestInvalidSigner();

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Airdrop(address token);
    event AirdropWithSignature(address token);
    event AirdropClaimed(address token, address receiver);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) external initializer {
        _setupOwner(_defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop Push
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract-owner send native token (eth) to a list of addresses.
     *  @dev             Owner should send total airdrop amount as msg.value.
     *                   Can only be called by contract owner.
     *
     *  @param _contents List containing recipients and amounts to airdrop
     */
    function airdropNativeToken(AirdropContentERC20[] calldata _contents) external payable onlyOwner {
        uint256 len = _contents.length;
        uint256 nativeTokenAmount;

        for (uint256 i = 0; i < len; i++) {
            nativeTokenAmount += _contents[i].amount;

            SafeTransferLib.safeTransferETH(_contents[i].recipient, _contents[i].amount);
        }

        if (nativeTokenAmount != msg.value) {
            revert AirdropValueMismatch();
        }

        emit Airdrop(NATIVE_TOKEN_ADDRESS);
    }

    /**
     *  @notice          Lets contract owner send ERC20 tokens to a list of addresses.
     *  @dev             The token-owner should approve total airdrop amount to this contract.
     *                   Can only be called by contract owner.
     *
     *  @param _tokenAddress Address of the ERC20 token being airdropped
     *  @param _contents     List containing recipients and amounts to airdrop
     */
    function airdropERC20(address _tokenAddress, AirdropContentERC20[] calldata _contents) external onlyOwner {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; i++) {
            SafeTransferLib.safeTransferFrom(_tokenAddress, msg.sender, _contents[i].recipient, _contents[i].amount);
        }

        emit Airdrop(_tokenAddress);
    }

    /**
     *  @notice          Lets contract owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve airdrop tokenIds to this contract.
     *                   Can only be called by contract owner.
     *
     *  @param _tokenAddress Address of the ERC721 token being airdropped
     *  @param _contents     List containing recipients and tokenIds to airdrop
     */
    function airdropERC721(address _tokenAddress, AirdropContentERC721[] calldata _contents) external onlyOwner {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; i++) {
            IERC721(_tokenAddress).safeTransferFrom(msg.sender, _contents[i].recipient, _contents[i].tokenId);
        }

        emit Airdrop(_tokenAddress);
    }

    /**
     *  @notice          Lets contract owner send ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve airdrop tokenIds and amounts to this contract.
     *                   Can only be called by contract owner.
     *
     *  @param _tokenAddress Address of the ERC1155 token being airdropped
     *  @param _contents     List containing recipients, tokenIds, and amounts to airdrop
     */
    function airdropERC1155(address _tokenAddress, AirdropContentERC1155[] calldata _contents) external onlyOwner {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(
                msg.sender,
                _contents[i].recipient,
                _contents[i].tokenId,
                _contents[i].amount,
                ""
            );
        }

        emit Airdrop(_tokenAddress);
    }

    /*///////////////////////////////////////////////////////////////
                        Airdrop With Signature
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract owner send ERC20 tokens to a list of addresses with EIP-712 signature.
     *  @dev             The token-owner should approve airdrop amounts to this contract.
     *                   Signer should be the contract owner.
     *
     *  @param req          Struct containing airdrop contents, uid, and expiration timestamp
     *  @param signature    EIP-712 signature to perform the airdrop
     */
    function airdropERC20WithSignature(AirdropRequestERC20 calldata req, bytes calldata signature) external {
        // verify expiration timestamp
        if (req.expirationTimestamp < block.timestamp) {
            revert AirdropRequestExpired(req.expirationTimestamp);
        }

        if (processed[req.uid]) {
            revert AirdropRequestAlreadyProcessed();
        }

        // verify data
        if (!_verifyRequestSignerERC20(req, signature)) {
            revert AirdropRequestInvalidSigner();
        }

        processed[req.uid] = true;

        uint256 len = req.contents.length;
        address _from = owner();

        for (uint256 i = 0; i < len; i++) {
            SafeTransferLib.safeTransferFrom(
                req.tokenAddress,
                _from,
                req.contents[i].recipient,
                req.contents[i].amount
            );
        }

        emit AirdropWithSignature(req.tokenAddress);
    }

    /**
     *  @notice          Lets contract owner send ERC721 tokens to a list of addresses with EIP-712 signature.
     *  @dev             The token-owner should approve airdrop tokenIds to this contract.
     *                   Signer should be the contract owner.
     *
     *  @param req          Struct containing airdrop contents, uid, and expiration timestamp
     *  @param signature    EIP-712 signature to perform the airdrop
     */
    function airdropERC721WithSignature(AirdropRequestERC721 calldata req, bytes calldata signature) external {
        // verify expiration timestamp
        if (req.expirationTimestamp < block.timestamp) {
            revert AirdropRequestExpired(req.expirationTimestamp);
        }

        if (processed[req.uid]) {
            revert AirdropRequestAlreadyProcessed();
        }

        // verify data
        if (!_verifyRequestSignerERC721(req, signature)) {
            revert AirdropRequestInvalidSigner();
        }

        processed[req.uid] = true;

        address _from = owner();
        uint256 len = req.contents.length;

        for (uint256 i = 0; i < len; i++) {
            IERC721(req.tokenAddress).safeTransferFrom(_from, req.contents[i].recipient, req.contents[i].tokenId);
        }

        emit AirdropWithSignature(req.tokenAddress);
    }

    /**
     *  @notice          Lets contract owner send ERC1155 tokens to a list of addresses with EIP-712 signature.
     *  @dev             The token-owner should approve airdrop tokenIds and amounts to this contract.
     *                   Signer should be the contract owner.
     *
     *  @param req          Struct containing airdrop contents, uid, and expiration timestamp
     *  @param signature    EIP-712 signature to perform the airdrop
     */
    function airdropERC1155WithSignature(AirdropRequestERC1155 calldata req, bytes calldata signature) external {
        // verify expiration timestamp
        if (req.expirationTimestamp < block.timestamp) {
            revert AirdropRequestExpired(req.expirationTimestamp);
        }

        if (processed[req.uid]) {
            revert AirdropRequestAlreadyProcessed();
        }

        // verify data
        if (!_verifyRequestSignerERC1155(req, signature)) {
            revert AirdropRequestInvalidSigner();
        }

        processed[req.uid] = true;

        address _from = owner();
        uint256 len = req.contents.length;

        for (uint256 i = 0; i < len; i++) {
            IERC1155(req.tokenAddress).safeTransferFrom(
                _from,
                req.contents[i].recipient,
                req.contents[i].tokenId,
                req.contents[i].amount,
                ""
            );
        }

        emit AirdropWithSignature(req.tokenAddress);
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop Claimable
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets allowlisted addresses claim ERC20 airdrop tokens.
     *  @dev             The token-owner should approve total airdrop amount to this contract,
     *                   and set merkle root of allowlisted address for this airdrop.
     *
     *  @param _token       Address of ERC20 airdrop token
     *  @param _receiver    Allowlisted address for which the token is being claimed
     *  @param _quantity    Allowlisted quantity of tokens to claim
     *  @param _proofs      Merkle proofs for allowlist verification
     */
    function claimERC20(address _token, address _receiver, uint256 _quantity, bytes32[] calldata _proofs) external {
        bytes32 claimHash = _getClaimHashERC20(_receiver, _token);
        uint256 conditionId = tokenConditionId[_token];

        if (claimed[conditionId][claimHash]) {
            revert AirdropAlreadyClaimed();
        }

        bytes32 _tokenMerkleRoot = tokenMerkleRoot[_token];
        if (_tokenMerkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid = MerkleProofLib.verifyCalldata(
            _proofs,
            _tokenMerkleRoot,
            keccak256(abi.encodePacked(_receiver, _quantity))
        );
        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed[conditionId][claimHash] = true;

        SafeTransferLib.safeTransferFrom(_token, owner(), _receiver, _quantity);

        emit AirdropClaimed(_token, _receiver);
    }

    /**
     *  @notice          Lets allowlisted addresses claim ERC721 airdrop tokens.
     *  @dev             The token-owner should approve airdrop tokenIds to this contract,
     *                   and set merkle root of allowlisted address for this airdrop.
     *
     *  @param _token       Address of ERC721 airdrop token
     *  @param _receiver    Allowlisted address for which the token is being claimed
     *  @param _tokenId     Allowlisted tokenId to claim
     *  @param _proofs      Merkle proofs for allowlist verification
     */
    function claimERC721(address _token, address _receiver, uint256 _tokenId, bytes32[] calldata _proofs) external {
        bytes32 claimHash = _getClaimHashERC721(_receiver, _token, _tokenId);
        uint256 conditionId = tokenConditionId[_token];

        if (claimed[conditionId][claimHash]) {
            revert AirdropAlreadyClaimed();
        }

        bytes32 _tokenMerkleRoot = tokenMerkleRoot[_token];
        if (_tokenMerkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid = MerkleProofLib.verifyCalldata(
            _proofs,
            _tokenMerkleRoot,
            keccak256(abi.encodePacked(_receiver, _tokenId))
        );
        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed[conditionId][claimHash] = true;

        IERC721(_token).safeTransferFrom(owner(), _receiver, _tokenId);

        emit AirdropClaimed(_token, _receiver);
    }

    /**
     *  @notice          Lets allowlisted addresses claim ERC1155 airdrop tokens.
     *  @dev             The token-owner should approve tokenIds and total airdrop amounts to this contract,
     *                   and set merkle root of allowlisted address for this airdrop.
     *
     *  @param _token       Address of ERC1155 airdrop token
     *  @param _receiver    Allowlisted address for which the token is being claimed
     *  @param _tokenId     Allowlisted tokenId to claim
     *  @param _quantity    Allowlisted quantity of tokens to claim
     *  @param _proofs      Merkle proofs for allowlist verification
     */
    function claimERC1155(
        address _token,
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external {
        bytes32 claimHash = _getClaimHashERC1155(_receiver, _token, _tokenId);
        uint256 conditionId = tokenConditionId[_token];

        if (claimed[conditionId][claimHash]) {
            revert AirdropAlreadyClaimed();
        }

        bytes32 _tokenMerkleRoot = tokenMerkleRoot[_token];
        if (_tokenMerkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid = MerkleProofLib.verifyCalldata(
            _proofs,
            _tokenMerkleRoot,
            keccak256(abi.encodePacked(_receiver, _tokenId, _quantity))
        );
        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed[conditionId][claimHash] = true;

        IERC1155(_token).safeTransferFrom(owner(), _receiver, _tokenId, _quantity, "");

        emit AirdropClaimed(_token, _receiver);
    }

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract owner set merkle root (allowlist) for claim based airdrops.
     *
     *  @param _token             Address of airdrop token
     *  @param _tokenMerkleRoot   Merkle root of allowlist
     *  @param _resetClaimStatus  Reset claim status / amount claimed so far to zero for all recipients
     */
    function setMerkleRoot(address _token, bytes32 _tokenMerkleRoot, bool _resetClaimStatus) external onlyOwner {
        if (_resetClaimStatus || tokenConditionId[_token] == 0) {
            tokenConditionId[_token] += 1;
        }
        tokenMerkleRoot[_token] = _tokenMerkleRoot;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns claim status of a receiver for a claim based airdrop
    function isClaimed(address _receiver, address _token, uint256 _tokenId) external view returns (bool) {
        uint256 _conditionId = tokenConditionId[_token];

        bytes32 claimHash = keccak256(abi.encodePacked(_receiver, _token, _tokenId));
        if (claimed[_conditionId][claimHash]) {
            return true;
        }

        claimHash = keccak256(abi.encodePacked(_receiver, _token));
        if (claimed[_conditionId][claimHash]) {
            return true;
        }

        return false;
    }
    /// @dev Checks whether contract owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Domain name and version for EIP-712
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "Airdrop";
        version = "1";
    }

    /// @dev Keccak256 hash of receiver and token addresses, for claim based airdrop status tracking
    function _getClaimHashERC20(address _receiver, address _token) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_receiver, _token));
    }

    /// @dev Keccak256 hash of receiver, token address and tokenId, for claim based airdrop status tracking
    function _getClaimHashERC721(address _receiver, address _token, uint256 _tokenId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_receiver, _token, _tokenId));
    }

    /// @dev Keccak256 hash of receiver, token address and tokenId, for claim based airdrop status tracking
    function _getClaimHashERC1155(address _receiver, address _token, uint256 _tokenId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_receiver, _token, _tokenId));
    }

    /// @dev Hash nested struct within AirdropRequest___
    function _hashContentInfoERC20(AirdropContentERC20[] calldata contents) private pure returns (bytes32) {
        bytes32[] memory contentHashes = new bytes32[](contents.length);
        for (uint256 i = 0; i < contents.length; i++) {
            contentHashes[i] = keccak256(abi.encode(CONTENT_TYPEHASH_ERC20, contents[i].recipient, contents[i].amount));
        }
        return keccak256(abi.encodePacked(contentHashes));
    }

    /// @dev Hash nested struct within AirdropRequest___
    function _hashContentInfoERC721(AirdropContentERC721[] calldata contents) private pure returns (bytes32) {
        bytes32[] memory contentHashes = new bytes32[](contents.length);
        for (uint256 i = 0; i < contents.length; i++) {
            contentHashes[i] = keccak256(
                abi.encode(CONTENT_TYPEHASH_ERC721, contents[i].recipient, contents[i].tokenId)
            );
        }
        return keccak256(abi.encodePacked(contentHashes));
    }

    /// @dev Hash nested struct within AirdropRequest___
    function _hashContentInfoERC1155(AirdropContentERC1155[] calldata contents) private pure returns (bytes32) {
        bytes32[] memory contentHashes = new bytes32[](contents.length);
        for (uint256 i = 0; i < contents.length; i++) {
            contentHashes[i] = keccak256(
                abi.encode(CONTENT_TYPEHASH_ERC1155, contents[i].recipient, contents[i].tokenId, contents[i].amount)
            );
        }
        return keccak256(abi.encodePacked(contentHashes));
    }

    /// @dev Verify EIP-712 signature
    function _verifyRequestSignerERC20(
        AirdropRequestERC20 calldata req,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 contentHash = _hashContentInfoERC20(req.contents);
        bytes32 structHash = keccak256(
            abi.encode(REQUEST_TYPEHASH_ERC20, req.uid, req.tokenAddress, req.expirationTimestamp, contentHash)
        );

        bytes32 digest = _hashTypedData(structHash);

        return SignatureCheckerLib.isValidSignatureNowCalldata(owner(), digest, signature);
    }

    /// @dev Verify EIP-712 signature
    function _verifyRequestSignerERC721(
        AirdropRequestERC721 calldata req,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 contentHash = _hashContentInfoERC721(req.contents);
        bytes32 structHash = keccak256(
            abi.encode(REQUEST_TYPEHASH_ERC721, req.uid, req.tokenAddress, req.expirationTimestamp, contentHash)
        );

        bytes32 digest = _hashTypedData(structHash);

        return SignatureCheckerLib.isValidSignatureNowCalldata(owner(), digest, signature);
    }

    /// @dev Verify EIP-712 signature
    function _verifyRequestSignerERC1155(
        AirdropRequestERC1155 calldata req,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 contentHash = _hashContentInfoERC1155(req.contents);
        bytes32 structHash = keccak256(
            abi.encode(REQUEST_TYPEHASH_ERC1155, req.uid, req.tokenAddress, req.expirationTimestamp, contentHash)
        );

        bytes32 digest = _hashTypedData(structHash);

        return SignatureCheckerLib.isValidSignatureNowCalldata(owner(), digest, signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
///
/// @dev Note:
/// - The recovery functions use the ecrecover precompile (0x1).
/// - As of Solady version 0.0.68, the `recover` variants will revert upon recovery failure.
///   This is for more safety by default.
///   Use the `tryRecover` variants if you need to get the zero address back
///   upon recovery failure instead.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The signature is invalid.
    error InvalidSignature();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recover(bytes32 hash, bytes memory signature) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TRY-RECOVER OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // WARNING!
    // These functions will NOT revert upon recovery failure.
    // Instead, they will return the zero address upon recovery failure.
    // It is critical that the returned address is NEVER compared against
    // a zero address (e.g. an uninitialized address variable).

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
///
/// @dev Note, this implementation:
/// - Uses `address(this)` for the `verifyingContract` field.
/// - Does NOT use the optional EIP-712 salt.
/// - Does NOT use any EIP-712 extensions.
/// This is for simplicity and to save gas.
/// If you need to customize, please fork / modify accordingly.
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    uint256 private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedNameHash;
    bytes32 private immutable _cachedVersionHash;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() {
        _cachedThis = uint256(uint160(address(this)));
        _cachedChainId = block.chainid;

        string memory name;
        string memory version;
        if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
        bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
        bytes32 versionHash =
            _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        if (!_domainNameAndVersionMayChange()) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40) // Load the free memory pointer.
                mstore(m, _DOMAIN_TYPEHASH)
                mstore(add(m, 0x20), nameHash)
                mstore(add(m, 0x40), versionHash)
                mstore(add(m, 0x60), chainid())
                mstore(add(m, 0x80), address())
                separator := keccak256(m, 0xa0)
            }
        }
        _cachedDomainSeparator = separator;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the domain name and version.
    /// ```
    ///     function _domainNameAndVersion()
    ///         internal
    ///         pure
    ///         virtual
    ///         returns (string memory name, string memory version)
    ///     {
    ///         name = "Solady";
    ///         version = "1";
    ///     }
    /// ```
    ///
    /// Note: If the returned result may change after the contract has been deployed,
    /// you must override `_domainNameAndVersionMayChange()` to return true.
    function _domainNameAndVersion()
        internal
        view
        virtual
        returns (string memory name, string memory version);

    /// @dev Returns if `_domainNameAndVersion()` may change
    /// after the contract has been deployed (i.e. after the constructor).
    /// Default: false.
    function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        if (_domainNameAndVersionMayChange()) {
            separator = _buildDomainSeparator();
        } else {
            separator = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        if (_domainNameAndVersionMayChange()) {
            digest = _buildDomainSeparator();
        } else {
            digest = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-5267 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator() private view returns (bytes32 separator) {
        // We will use `separator` to store the name hash to save a bit of gas.
        bytes32 versionHash;
        if (_domainNameAndVersionMayChange()) {
            (string memory name, string memory version) = _domainNameAndVersion();
            separator = keccak256(bytes(name));
            versionHash = keccak256(bytes(version));
        } else {
            separator = _cachedNameHash;
            versionHash = _cachedVersionHash;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), separator) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        uint256 cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            MERKLE PROOF VERIFICATION OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(proof) {
                // Initialize `offset` to the offset of `proof` elements in memory.
                let offset := add(proof, 0x20)
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(offset, shl(5, mload(proof)))
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, mload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), mload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    ///
    /// Note:
    /// - Breaking the invariant `flags.length == (leaves.length - 1) + proof.length`
    ///   will always return false.
    /// - The sum of the lengths of `proof` and `leaves` must never overflow.
    /// - Any non-zero word in the `flags` array is treated as true.
    /// - The memory offset of `proof` must be non-zero
    ///   (i.e. `proof` is not pointing to the scratch space).
    function verifyMultiProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32[] memory leaves,
        bool[] memory flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the lengths of the arrays.
            let leavesLength := mload(leaves)
            let proofLength := mload(proof)
            let flagsLength := mload(flags)

            // Advance the pointers of the arrays to point to the data.
            leaves := add(0x20, leaves)
            proof := add(0x20, proof)
            flags := add(0x20, flags)

            // If the number of flags is correct.
            for {} eq(add(leavesLength, proofLength), add(flagsLength, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flagsLength) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    isValid := eq(mload(xor(leaves, mul(xor(proof, leaves), proofLength))), root)
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := add(proof, shl(5, proofLength))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                leavesLength := shl(5, leavesLength)
                for { let i := 0 } iszero(eq(i, leavesLength)) { i := add(i, 0x20) } {
                    mstore(add(hashesFront, i), mload(add(leaves, i)))
                }
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, leavesLength)
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flagsLength := add(hashesBack, shl(5, flagsLength))

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(mload(flags)) {
                        // Loads the next proof.
                        b := mload(proof)
                        proof := add(proof, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag.
                    flags := add(flags, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flagsLength)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required.
                        eq(proofEnd, proof)
                    )
                break
            }
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    ///
    /// Note:
    /// - Breaking the invariant `flags.length == (leaves.length - 1) + proof.length`
    ///   will always return false.
    /// - Any non-zero word in the `flags` array is treated as true.
    /// - The calldata offset of `proof` must be non-zero
    ///   (i.e. `proof` is from a regular Solidity function with a 4-byte selector).
    function verifyMultiProofCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leaves.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leaves.offset, mul(xor(proof.offset, leaves.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := add(proof.offset, shl(5, proof.length))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                calldatacopy(hashesFront, leaves.offset, shl(5, leaves.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leaves.length))
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required.
                        eq(proofEnd, proof.offset)
                    )
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes32 array.
    function emptyProof() internal pure returns (bytes32[] calldata proof) {
        /// @solidity memory-safe-assembly
        assembly {
            proof.length := 0
        }
    }

    /// @dev Returns an empty calldata bytes32 array.
    function emptyLeaves() internal pure returns (bytes32[] calldata leaves) {
        /// @solidity memory-safe-assembly
        assembly {
            leaves.length := 0
        }
    }

    /// @dev Returns an empty calldata bool array.
    function emptyFlags() internal pure returns (bool[] calldata flags) {
        /// @solidity memory-safe-assembly
        assembly {
            flags.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Permit2 operations from (https://github.com/Uniswap/permit2/blob/main/src/libraries/Permit2Lib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The Permit2 operation has failed.
    error Permit2Failed();

    /// @dev The Permit2 amount must be less than `2**160 - 1`.
    error Permit2AmountOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR =
        0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet.
    address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The canonical Permit2 address.
    /// [Github](https://github.com/Uniswap/permit2)
    /// [Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function trySafeTransferFrom(address token, address from, address to, uint256 amount)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            success :=
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul( // The arguments of `mul` are evaluated from right to left.
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// If the initial attempt fails, try to use Permit2 to transfer the token.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function safeTransferFrom2(address token, address from, address to, uint256 amount) internal {
        if (!trySafeTransferFrom(token, from, to, amount)) {
            permit2TransferFrom(token, from, to, amount);
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to` via Permit2.
    /// Reverts upon failure.
    function permit2TransferFrom(address token, address from, address to, uint256 amount)
        internal
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x74), shr(96, shl(96, token)))
            mstore(add(m, 0x54), amount)
            mstore(add(m, 0x34), to)
            mstore(add(m, 0x20), shl(96, from))
            // `transferFrom(address,address,uint160,address)`.
            mstore(m, 0x36c78516000000000000000000000000)
            let p := mul(PERMIT2, iszero(shr(160, amount)))
            if iszero(mul(call(gas(), p, 0, add(m, 0x10), 0x84, codesize(), 0x00), extcodesize(p)))
            {
                mstore(0x00, 0x7939f4248757f0fd) // `TransferFromFailed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(p))), 0x04)
            }
        }
    }

    /// @dev Permit a user to spend a given amount of
    /// another user's tokens via native EIP-2612 permit if possible, falling
    /// back to Permit2 if native permit fails or is not implemented on the token.
    function permit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            for {} shl(96, xor(token, WETH9)) {} {
                mstore(0x00, 0x3644e515) // `DOMAIN_SEPARATOR()`.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        lt(iszero(mload(0x00)), eq(returndatasize(), 0x20)), // Returns 1 non-zero word.
                        // Gas stipend to limit gas burn for tokens that don't refund gas when
                        // an non-existing function is called. 5K should be enough for a SLOAD.
                        staticcall(5000, token, 0x1c, 0x04, 0x00, 0x20)
                    )
                ) { break }
                let m := mload(0x40)
                mstore(add(m, 0x34), spender)
                mstore(add(m, 0x20), shl(96, owner))
                mstore(add(m, 0x74), deadline)
                if eq(mload(0x00), DAI_DOMAIN_SEPARATOR) {
                    mstore(0x14, owner)
                    mstore(0x00, 0x7ecebe00000000000000000000000000) // `nonces(address)`.
                    mstore(add(m, 0x94), staticcall(gas(), token, 0x10, 0x24, add(m, 0x54), 0x20))
                    mstore(m, 0x8fcbaf0c000000000000000000000000) // `IDAIPermit.permit`.
                    // `nonces` is already at `add(m, 0x54)`.
                    // `1` is already stored at `add(m, 0x94)`.
                    mstore(add(m, 0xb4), and(0xff, v))
                    mstore(add(m, 0xd4), r)
                    mstore(add(m, 0xf4), s)
                    success := call(gas(), token, 0, add(m, 0x10), 0x104, codesize(), 0x00)
                    break
                }
                mstore(m, 0xd505accf000000000000000000000000) // `IERC20Permit.permit`.
                mstore(add(m, 0x54), amount)
                mstore(add(m, 0x94), and(0xff, v))
                mstore(add(m, 0xb4), r)
                mstore(add(m, 0xd4), s)
                success := call(gas(), token, 0, add(m, 0x10), 0xe4, codesize(), 0x00)
                break
            }
        }
        if (!success) simplePermit2(token, owner, spender, amount, deadline, v, r, s);
    }

    /// @dev Simple permit on the Permit2 contract.
    function simplePermit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0x927da105) // `allowance(address,address,address)`.
            {
                let addressMask := shr(96, not(0))
                mstore(add(m, 0x20), and(addressMask, owner))
                mstore(add(m, 0x40), and(addressMask, token))
                mstore(add(m, 0x60), and(addressMask, spender))
                mstore(add(m, 0xc0), and(addressMask, spender))
            }
            let p := mul(PERMIT2, iszero(shr(160, amount)))
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x5f), // Returns 3 words: `amount`, `expiration`, `nonce`.
                    staticcall(gas(), p, add(m, 0x1c), 0x64, add(m, 0x60), 0x60)
                )
            ) {
                mstore(0x00, 0x6b836e6b8757f0fd) // `Permit2Failed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(p))), 0x04)
            }
            mstore(m, 0x2b67b570) // `Permit2.permit` (PermitSingle variant).
            // `owner` is already `add(m, 0x20)`.
            // `token` is already at `add(m, 0x40)`.
            mstore(add(m, 0x60), amount)
            mstore(add(m, 0x80), 0xffffffffffff) // `expiration = type(uint48).max`.
            // `nonce` is already at `add(m, 0xa0)`.
            // `spender` is already at `add(m, 0xc0)`.
            mstore(add(m, 0xe0), deadline)
            mstore(add(m, 0x100), 0x100) // `signature` offset.
            mstore(add(m, 0x120), 0x41) // `signature` length.
            mstore(add(m, 0x140), r)
            mstore(add(m, 0x160), s)
            mstore(add(m, 0x180), shl(248, v))
            if iszero(call(gas(), p, 0, add(m, 0x1c), 0x184, codesize(), 0x00)) {
                mstore(0x00, 0x6b836e6b) // `Permit2Failed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
///
/// @dev Note:
/// - The signature checking functions use the ecrecover precompile (0x1).
/// - The `bytes memory signature` variants use the identity precompile (0x4)
///   to copy memory internally.
/// - Unlike ECDSA signatures, contract signatures are revocable.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library SignatureCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                // Copy the `signature` over.
                let n := add(0x20, mload(signature))
                pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(returndatasize(), 0x44), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // `r`, `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), signature.length)
                // Copy the `signature` over.
                calldatacopy(add(m, 0x64), signature.offset, signature.length)
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, add(shr(255, vs), 27)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, shr(1, shl(1, vs))) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), mload(0x60)) // `s`.
                mstore8(add(m, 0xa4), mload(0x20)) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, and(v, 0xff)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, s) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), s) // `s`.
                mstore8(add(m, 0xa4), v) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            // Copy the `signature` over.
            let n := add(0x20, mload(signature))
            pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(returndatasize(), 0x44), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), shr(1, shl(1, vs))) // `s`.
            mstore8(add(m, 0xa4), add(shr(255, vs), 27)) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), s) // `s`.
            mstore8(add(m, 0xa4), v) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}