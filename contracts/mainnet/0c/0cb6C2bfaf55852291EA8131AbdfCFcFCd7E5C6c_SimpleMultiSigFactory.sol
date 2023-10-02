// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// from https://github.com/optionality/clone-factory
pragma solidity 0.8.18;

// This contract is used to deploy minimal proxies (EIP1167) using the CREATE2 opcode
// Resources: https://eips.ethereum.org/EIPS/eip-1167
// https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract
// https://github.com/optionality/clone-factory
contract CloneFactory {
    function createClone(address target, bytes32 salt)
    internal
    returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            // load the next free memory slot as a place to store the clone contract data
            let clone := mload(0x40)

            // The bytecode block below is responsible for contract initialization
            // during deployment, it is worth noting the proxied contract constructor will not be called during
            // the cloning procedure and that is why an initialization function needs to be called after the
            // clone is created
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            // This stores the address location of the implementation contract
            // so that the proxy knows where to delegate call logic to
            mstore(add(clone, 0x14), targetBytes)

            // The bytecode block is the actual code that is deployed for each clone created.
            // It forwards all calls to the already deployed implementation via a delegatecall
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            // deploy the contract using the CREATE2 opcode
            // this deploys the minimal proxy defined above, which will proxy all
            // calls to use the logic defined in the implementation contract `target`
            result := create2(0, clone, 0x37, salt)
        }
    }

    function isClone(address target, address query)
    internal
    view
    returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            // load the next free memory slot as a place to store the comparison clone
            let clone := mload(0x40)

            // The next three lines store the expected bytecode for a miniml proxy
            // that targets `target` as its implementation contract
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            // the next two lines store the bytecode of the contract that we are checking in memory
            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)

            // Check if the expected bytecode equals the actual bytecode and return the result
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

import "../interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

// EIP1271 errors
error InvalidSignature(); // -----------------------| 0x8baa579f
error InvalidSignaturesCount(); // -----------------| 0x7be8d111
error IsNotOwner(); // -----------------------------| 0x65b023fd
error NonUniqueOrUnsortedSignatures(); // ----------| 0x55ab471a

// .execute() errors
error InvalidExecutor(); // ------------------------| 0x710c9497
error InnerTransactionFailed(); // -----------------| 0x29df4119

// .setOwners() errors
error InvalidOwnersLength(); // --------------------| 0x518c73ff
error InvalidThreshold(); // -----------------------| 0xaabd5a09
error DuplicateOwnerAdded(); // --------------------| 0x8d0e60ed
error UnauthorizedCaller(); // ---------------------| 0x5c427cd9

abstract contract BaseSms is IERC1271, IERC721Receiver, IERC1155Receiver {
    string public constant VERSION = "1.3.0";

    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("Simple MultiSig")
    bytes32 constant NAME_HASH = 0xb7a0bfa1b79f2443f4d73ebb9259cddbcd510b18be6fc4da7d1aa7b1786e73e6;

    // keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
    bytes32 constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

    // Signature salt, when they create a transaction it's used to verify
    bytes32 constant SALT = 0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x1626ba7e;
    // Following reference implementation from official ERC1271 proposal
    bytes4 constant internal EIP1271_INVALID_SIGNATURE = 0xffffffff;
    uint8 constant internal MAX_OWNERS = 20;

    uint public nonce; // mutable state
    uint public threshold; // mutable state
    mapping(address => bool) isOwner; // mutable state
    address[] public ownersArr; // mutable state

    bytes32 DOMAIN_SEPARATOR; // hash for EIP712, computed from contract address

    event OwnersSet(uint threshold, address[] owners);
    event Execution(address indexed destination, uint value, bytes data, address indexed executor, uint gasLimit);
    event Deposit(address indexed sender, uint value);

    /**
        * Either called from the constructor (Base case) or init function (EIP-1167) to initialize the contract state
    */
    function contractInit(uint threshold_, address[] memory owners_, uint chainId) internal {
        setOwners_(threshold_, owners_);

        DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAINTYPE_HASH, NAME_HASH, VERSION_HASH, chainId, this, SALT));
    }

    modifier verifyExecutor(address executor) {
        if (executor != msg.sender && executor != address(0)) {
            revert InvalidExecutor();
        }
        _;
    }

    function owners() external view returns (address[] memory) {
        return ownersArr;
    }

    // Note that owners_ must be strictly increasing, in order to prevent duplicates
    function setOwners_(uint threshold_, address[] memory owners_) private {
        if (owners_.length == 0 || owners_.length > MAX_OWNERS) {
            revert InvalidOwnersLength();
        }

        if (threshold_ == 0 || threshold_ > owners_.length) {
            revert InvalidThreshold();
        }

        // remove old owners from map
        for (uint i = 0; i < ownersArr.length; i++) {
            isOwner[ownersArr[i]] = false;
        }

        // add new owners to map
        address lastAdd = address(0);
        for (uint i = 0; i < owners_.length; i++) {
            if (owners_[i] <= lastAdd) {
                revert DuplicateOwnerAdded();
            }
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }

        // set owners array and threshold
        ownersArr = owners_;
        threshold = threshold_;

        emit OwnersSet(threshold, ownersArr);
    }

    // Requires a quorum of owners to call from this contract using execute
    function setOwners(uint threshold_, address[] memory owners_) public virtual {
        if (msg.sender != address(this)) {
            revert UnauthorizedCaller();
        }
        setOwners_(threshold_, owners_);
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    // @deprecated - Use "executeWithSignatures" instead
    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) public virtual verifyExecutor(executor) {
        // Combine the legacy signature component arrays into a single bytes array
        bytes memory signatures = packSignatures(sigV, sigR, sigS);

        // Perform the execution, using the combined signatures
        _execute(signatures, destination, value, data, executor, gasLimit);
    }


    /*
        * @notice - Executes the transaction payload with the signatures provided
        * @dev - Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    */
    function executeWithSignatures(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor, uint gasLimit
    ) public virtual verifyExecutor(executor) {
        _execute(signatures, destination, value, data, executor, gasLimit);
    }


    /*
        * @notice - Helper function to executes the transaction payload with the signatures provided
        * @dev - Note when calling this function directly, the caller is responsible for validating the executor
    */
    function _execute(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) internal {
        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(
            abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit)
        );

        bytes32 totalHash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, txInputHash));

        // Check the packed signatures are valid via ecrecover
        uint validSigCount = checkNSignatures(totalHash, signatures, threshold);
        bool isValidNSignatures = validSigCount == threshold;
        if (!isValidNSignatures) {
            revert InvalidSignaturesCount();
        }

        // If we make it here all signatures are valid signatures from owners.
        // Checks, effects & interactions pattern to prevent reentrancy
        nonce = nonce + 1;
        bool success = false;

        emit Execution(destination, value, data, executor, gasLimit);

        (success, ) = destination.call{value: value, gas: gasLimit}(data);

        if (!success) {
            revert InnerTransactionFailed();
        }
    }

    // EIP1271 function
    function isValidSignature(bytes32 hash, bytes memory signature) public view override virtual returns (bytes4) {
        uint validSigCount = checkNSignatures(hash, signature, threshold);
        bool isValid = validSigCount == threshold;
        return isValid ? EIP1271_MAGIC_VALUE : EIP1271_INVALID_SIGNATURE;
    }

    /**
       * @notice Packs together the signature arguments into a single bytes array in order of R, S, V
       * @param sigV Array of v values for each signature
       * @param sigR Array of r values for each signature
       * @param sigS Array of s values for each signature
    */
    function packSignatures(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) private pure returns (bytes memory signatures) {
        // Combine sigV, sigR, sigS into a single bytes memory signatures
        signatures = new bytes(sigR.length * 65);

        for (uint i = 0; i < sigR.length; i++) {
            assembly {
            // Offset of 32 bytes into signatures array, as it is reserved for the length of bytes
                let signaturesPointer := add(add(signatures, 0x20), mul(i, 65))

            // Initial offset of 32 bytes into sigR (as length is stored in first 32 bytes)
            // Increment offset by 32 bytes for each signature, as each sigR is 32 bytes long
                let sigRPointer := add(add(sigR, 0x20), mul(i, 0x20))
                let sigRValue := mload(sigRPointer)
                mstore(signaturesPointer, sigRValue)

            // For sigS, similar to sigR above, except for storing in the slot (32 bytes) after sigR
                let sigSPointer := add(add(sigS, 0x20), mul(i, 0x20))
                let sigSValue := mload(sigSPointer)
                mstore(add(signaturesPointer, 0x20), sigSValue)

            // For sigV, despite it being a uint8[] -> each slot is still 32 bytes
            // Elements in memory arrays in Solidity always occupy multiples of 32 bytes
                let sigVPointer := add(add(sigV, 0x20), mul(i, 0x20))
            // Bit masking with 0xff is necessary to truncate bytes -> bytes1
                let sigVValue := and(mload(sigVPointer), 0xff)
            // mstore8 as "v" is only one byte
                mstore8(add(signaturesPointer, 0x40), sigVValue)
            }
        }
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
   * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
   * @param hash Hash of the data (could be either a message hash or transaction hash)
   * @param signatures Signature data that should be verified, contract signature (EIP-1271).
   * @param requiredSignatures Amount of required valid signatures.
   */
    function checkNSignatures(bytes32 hash, bytes memory signatures, uint256 requiredSignatures) internal view returns (uint256 signatureCount) {
        if (signatures.length != requiredSignatures * 65) {
            revert InvalidSignaturesCount();
        }

        uint8 v;
        bytes32 r;
        bytes32 s;

        signatureCount = 0;
        address previousAddress = address(0);

        for (uint i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);

            if (v != 27 && v != 28) {
                revert InvalidSignature();
            }

            address recoveredAddress = ecrecover(hash, v, r, s);

            // Check if address is owner
            if (!isOwner[recoveredAddress]) {
                revert IsNotOwner();
            }

            // Check for duplicate address (sorted -> ascending order)
            if (recoveredAddress <= previousAddress) {
                revert NonUniqueOrUnsortedSignatures();
            }

            previousAddress = recoveredAddress;
            signatureCount += 1;
        }
    }

    /**
       * @notice Splits signature bytes into `uint8 v, bytes32 r, bytes32 s`.
       * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
       *      The signature format is a compact form of {bytes32 r}{bytes32 s}{uint8 v}
       *      Compact means uint8 is not padded to 32 bytes.
       * @param pos Which signature to read.
       *            A prior bounds check of this parameter should be performed, to avoid out of bounds access.
       * @param signatures Concatenated {r, s, v} signatures.
       * @return v Recovery ID or Safe signature type.
       * @return r Output value r of the signature.
       * @return s Output value s of the signature.
   */
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
        /**
         * Here we are loading the last 32 bytes, including 31 bytes
         * of 's'. There is no 'mload8' to do this.
         * 'byte' is not working due to the Solidity parser, so lets
         * use the second best option, 'and'
         */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /**
        * @dev Shares supported interfaces that this contract supports
    */
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(IERC721Receiver).interfaceId
        || interfaceID == type(IERC1155Receiver).interfaceId
            || interfaceID == type(IERC165).interfaceId; // Also supporting ERC165 itself
    }

    /**
       * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
       * by `operator` from `from`, this function is called.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
       * @dev Handles the receipt of a single ERC1155 token type. This function is
       * called at the end of a `safeTransferFrom` after the balance has been updated.
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
      * @dev Handles the receipt of a multiple ERC1155 token types. This function
      * is called at the end of a `safeBatchTransferFrom` after the balances have
      * been updated.
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
import "../forwarder/Factory/CloneFactory.sol";
import "./SimpleMultiSigImpl.sol";

contract SimpleMultiSigFactory is CloneFactory {
    address public immutable implementationAddress;
    event SimpleMultiSigCreated(address newMultiSigAddress, address implementationAddress);

    constructor(address _implementationAddress) {
        implementationAddress = _implementationAddress;
    }

    // Params are the init params of MultiSigImpl
    function createSimpleMultiSig (uint threshold_, address[] memory owners_, uint chainId, bytes32 salt) external {
        address payable clone = createClone(implementationAddress, salt);
        SimpleMultiSigImpl(clone).init(threshold_, owners_, chainId);

        emit SimpleMultiSigCreated(clone, implementationAddress);
    }
}

pragma solidity 0.8.18;

import "./BaseSms.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Initializable errors
error IsNotInitialized(); // ---------| 0xc2e93857
error IsDisabled(); // ---------------| 0x09131007

contract SimpleMultiSigImpl is BaseSms, Initializable {
    modifier isInitialized() {
        if (_getInitializedVersion() == 0) {
            revert IsNotInitialized();
        }
        if (_getInitializedVersion() == type(uint8).max) {
            revert IsDisabled();
        }
        _;
    }

    /**
        * To prevent the implementation contract from being used, you should invoke the {_disableInitializers}
        * function in the constructor to automatically lock it when it is deployed:
    */
    constructor() {
        _disableInitializers();
    }

    /**
        * Initialize the contract, and sets the initial params required for the SMS Contract
        * Clones the methods from the parentAddress
    */
    function init(uint threshold_, address[] memory owners_, uint chainId) external initializer {
        super.contractInit(threshold_, owners_, chainId);
    }

    function setOwners(uint threshold_, address[] memory owners_) isInitialized public override {
        super.setOwners(threshold_, owners_);
    }

    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) isInitialized public override {
        super.execute(sigV, sigR, sigS, destination, value, data, executor, gasLimit);
    }

    function executeWithSignatures(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor, uint gasLimit
    ) isInitialized public override {
        super.executeWithSignatures(signatures, destination, value, data, executor, gasLimit);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) isInitialized public view override returns (bytes4) {
        return super.isValidSignature(hash, signature);
    }
}