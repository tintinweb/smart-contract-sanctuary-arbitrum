// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../interfaces/IFeePolicy.sol";
import "../libraries/Multicall.sol";
import "../libraries/Calldata.sol";
import "../Gateway.sol";
import "./QuotaStorage.sol";

contract ManagedController is Multicall, Initializable, OwnableUpgradeable, QuotaStorage {
    Gateway public immutable gateway;

    IFeePolicy public feePolicy;
    bool public quotaStorageDisabled; // might possibly disable in L1 if gas is too costly
    mapping(address => bool) public isOperator;

    event FeePolicyChanged(address indexed feePolicy);
    event OperatorChanged(address indexed account, bool isOperator);

    constructor(address _gateway) {
        gateway = Gateway(_gateway);
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice Execute a charge. Can only be called by whitelisted operator.
    function charge(Quota memory quota, bytes memory quotaSignature, uint160 amount) public {
        require(isOperator[msg.sender], "not operator");

        if (!quotaStorageDisabled) _storeQuota(quota);

        address destination = address(uint160(uint256(quota.controllerRefId)));
        gateway.charge({
            quota: quota,
            quotaSignature: quotaSignature,
            recipient: destination,
            amount: amount,
            fees: address(feePolicy) == address(0) ? new Fee[](0) : feePolicy.getFees(quota, amount, msg.sender),
            extraEventData: abi.encode(msg.sender)
        });
    }

    /// @dev Note that this is the on-chain status only. Off-chain the product owner can decide not to charge
    /// even if the on-chain status says the quota is "pending next charge".
    function getQuotaStatus(Quota memory quota) public view returns (QuotaStatus status) {
        return gateway.getQuotaStatus(quota);
    }

    // ----- admin functions -----

    function setOperator(address account, bool _isOperator) external onlyOwner {
        isOperator[account] = _isOperator;
        emit OperatorChanged(account, _isOperator);
    }

    function setFeePolicy(address newFeePolicy) external onlyOwner {
        feePolicy = IFeePolicy(newFeePolicy);
        emit FeePolicyChanged(newFeePolicy);
    }

    function setQuotaStorageDisabled(bool disabled) external onlyOwner {
        quotaStorageDisabled = disabled;
    }

    // ----- packed calldata -----

    /// @notice Execute charge with packed calldata
    function charge__packedData() external {
        _unpackAndCharge(CalldataCursor(4, msg.data.length));
    }

    /// @notice Execute multiple charges with packed calldata
    function chargeBatch__packedData() external {
        CalldataCursor memory cursor = CalldataCursor(4, msg.data.length);
        uint256 count = cursor.shiftUint8();
        for (uint256 i = 0; i < count; i++) {
            _unpackAndCharge(cursor);
        }
    }

    function _unpackAndCharge(CalldataCursor memory cursor) internal {
        uint256 flags = cursor.shiftUint8();
        bool useFullQuotaData = (flags & 1) != 0; //    mask: 0b00000001
        bool use2612Permit = (flags & 2) != 0; //       mask: 0b00000010
        bool useDAIPermit = (flags & 4) != 0; //        mask: 0b00000100
        bool usePermitAmount = (flags & 8) != 0; //     mask: 0b00001000
        bool useChargeAmount = (flags & 16) != 0; //    mask: 0b00010000

        Quota memory quota;
        if (useFullQuotaData) {
            address payer = cursor.shiftAddress();
            quota = Quota({
                payer: payer,
                payerNonce: gateway.payerNonces(payer),
                token: cursor.shiftAddress(),
                amount: cursor.shiftUint160(),
                startTime: cursor.shiftUint40(),
                endTime: cursor.shiftUint40(),
                interval: cursor.shiftUint40(),
                chargeWindow: cursor.shiftUint40(),
                controller: address(this),
                controllerRefId: cursor.shiftBytes32()
            });
        } else {
            quota = QuotaStorage.getQuotaById(cursor.shiftUint24());
        }

        if (use2612Permit) {
            permitERC20({
                token: quota.token,
                owner: quota.payer,
                spender: address(gateway),
                value: usePermitAmount ? cursor.shiftUint160() : type(uint256).max,
                deadline: cursor.shiftUint32(),
                v: cursor.shiftUint8(),
                r: cursor.shiftBytes32(),
                s: cursor.shiftBytes32()
            });
        } else if (useDAIPermit) {
            permitDAI({
                dai: quota.token,
                owner: quota.payer,
                spender: address(gateway),
                deadline: cursor.shiftUint32(),
                v: cursor.shiftUint8(),
                r: cursor.shiftBytes32(),
                s: cursor.shiftBytes32()
            });
        }

        uint160 amount = useChargeAmount ? cursor.shiftUint160() : quota.amount;
        bytes memory quotaSignature = useFullQuotaData ? cursor.shiftBytes(cursor.shiftUint8()) : new bytes(0);

        charge(quota, quotaSignature, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../libraries/QuotaLib.sol";

/**
 * Two-way mapping between quota and quota id
 */
abstract contract QuotaStorage {
    /// @notice Get quota id by its hash
    mapping(bytes32 quotaHash => uint64 quotaId) public quotaIdsByHash;

    /// @dev Quota details by id
    mapping(uint64 quotaId => Quota quota) internal _quotasById;

    uint64 internal _quotaCounter;

    /// @notice Get quota by its hash
    function getQuotaByHash(bytes32 quotaHash) public view returns (Quota memory quota) {
        return _quotasById[quotaIdsByHash[quotaHash]];
    }

    /// @notice Get quota by its id
    function getQuotaById(uint64 quotaId) public view returns (Quota memory quota) {
        return _quotasById[quotaId];
    }

    /// @dev Store quota and assign an ID, if it's not already stored
    function _storeQuota(Quota memory quota) internal {
        bytes32 quotaHash = QuotaLib.hash(quota);
        if (quotaIdsByHash[quotaHash] == 0) {
            _quotasById[quotaIdsByHash[quotaHash] = (++_quotaCounter)] = quota;
        }
    }

    /// @dev Reserved space for future storage layout upgrades
    uint256[47] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {SafeTransferLib, ERC20} from "lib/solmate/src/utils/SafeTransferLib.sol";
import "./interfaces/IFeePolicy.sol";
import "./libraries/Multicall.sol";
import "./libraries/EIP712.sol";
import "./libraries/QuotaLib.sol";

contract Gateway is EIP712("Gateway"), Multicall {
    using SafeTransferLib for ERC20;
    using QuotaLib for Quota;

    /// @dev Quota state
    mapping(bytes32 quotaHash => QuotaState state) internal _quotaStates;

    /// @notice Payer nonce, for bulk-canceling quotas (not for EIP712)
    mapping(address payer => uint96 payerNonce) public payerNonces;

    /// @notice Emit when a quota is validated
    /// @param controllerHash Hash of abi.encode(controller, controllerRefId)
    event QuotaValidated(
        bytes32 indexed quotaHash,
        address indexed payer,
        bytes32 indexed controllerHash,
        Quota quota,
        bytes quotaSignature
    );

    /// @notice Emit when a payer cancels a quota. Note that we do not check the quota's validity when it's cancelled.
    event QuotaCancelled(bytes32 indexed quotaHash);

    /// @notice Emit when a payer increments their nonce, i.e. bulk-canceling existing quotas
    event PayerNonceIncremented(address indexed payer, uint96 newNonce);

    /// @notice Emit when a charge is made
    event Charge(
        bytes32 indexed quotaHash,
        address recipient,
        uint160 amount,
        uint40 indexed cycleStartTime,
        uint160 cycleAmountUsed,
        uint24 chargeCount,
        bytes32 indexed receipt,
        Fee[] fees,
        bytes extraEventData
    );

    /// @notice Quota typehash, used for EIP712 signature
    bytes32 public constant _QUOTA_TYPEHASH = QuotaLib._QUOTA_TYPEHASH;

    /// @notice Get the state of a quota by its hash
    function getQuotaState(bytes32 quotaHash) external view returns (QuotaState memory state) {
        return _quotaStates[quotaHash];
    }

    /// @notice Validate the quota parameters with its signature.
    /// @param quota Quota
    /// @param quotaSignature Quota signature signed by the payer
    function validate(Quota memory quota, bytes memory quotaSignature) public {
        bytes32 quotaHash = quota.hash();
        QuotaState storage state = _quotaStates[quotaHash];

        if (!state.validated) {
            require(quota.payerNonce == payerNonces[quota.payer], "INVALID_PAYER_NONCE");
            if (msg.sender != quota.payer || quotaSignature.length != 0) {
                EIP712._verifySignature(quotaSignature, quotaHash, quota.payer);
            }
            state.validated = true;

            bytes32 controllerHash = keccak256(abi.encode(quota.controller, quota.controllerRefId));
            emit QuotaValidated(quotaHash, quota.payer, controllerHash, quota, quotaSignature);
        }
    }

    /// @notice Cancel quota. Only the payer or taker can cancel it.
    /// @param quota Quota. It can be not validated yet.
    function cancel(Quota memory quota) external {
        require(msg.sender == quota.payer, "NOT_ALLOWED");

        bytes32 quotaHash = quota.hash();
        _quotaStates[quotaHash].cancelled = true;
        emit QuotaCancelled(quotaHash);
    }

    /// @notice Increment a payer's nonce to bulk-cancel quotas which he/she approved to pay
    function incrementPayerNonce() external {
        payerNonces[msg.sender] += uint96(uint256(blockhash(block.number - 1)) >> 232); // add a quasi-random 24-bit number
        emit PayerNonceIncremented(msg.sender, payerNonces[msg.sender]);
    }

    /// @notice Pull token from payer to taker. Can only be called by the controller.
    /// @param quota Quota
    /// @param quotaSignature Quota signature signed by the payer. Can be empty if the quota is already validated.
    /// @param recipient Recipient of the charge
    /// @param amount Amount to charge
    /// @param fees Fees
    /// @param extraEventData Extra event data to emit
    /// @return receipt Receipt of the charge
    function charge(
        Quota memory quota,
        bytes memory quotaSignature,
        address recipient,
        uint160 amount,
        Fee[] calldata fees,
        bytes calldata extraEventData
    ) external returns (bytes32 receipt) {
        validate(quota, quotaSignature);

        require(msg.sender == quota.controller, "NOT_CONTROLLER");
        require(block.timestamp >= quota.startTime, "BEFORE_START_TIME");
        require(block.timestamp < quota.endTime, "REACHED_END_TIME");
        require(payerNonces[quota.payer] == quota.payerNonce, "PAYER_NONCE_INVALIDATED"); // ensure payer didn't bulk-cancel quota

        bytes32 quotaHash = quota.hash();
        QuotaState storage state = _quotaStates[quotaHash];

        require(!state.cancelled, "QUOTA_CANCELLED"); // ensure payer didn't cancel quota
        require(!quota.didMissCycle(state), "CYCLE_MISSED"); // ensure controller hasn't missed billing cycle

        // reset usage if new cycle starts
        if (state.chargeCount == 0 || block.timestamp - state.cycleStartTime >= quota.interval) {
            state.cycleStartTime = quota.latestCycleStartTime();
            state.cycleAmountUsed = 0;
        }
        require(uint256(state.cycleAmountUsed) + amount <= quota.amount, "EXCEEDED_QUOTA");

        // record usage
        state.cycleAmountUsed += amount;
        state.chargeCount++;

        // return a receipt (used for searching logs off-chain)
        receipt = keccak256(abi.encode(block.chainid, address(this), quotaHash, state.chargeCount));

        // emit event first, since there could be reentrancy later, and we want to keep the event order correct.
        emit Charge({
            quotaHash: quotaHash,
            recipient: recipient,
            amount: amount,
            cycleStartTime: state.cycleStartTime,
            cycleAmountUsed: state.cycleAmountUsed,
            chargeCount: state.chargeCount,
            receipt: receipt,
            fees: fees,
            extraEventData: extraEventData
        });

        // note that there could be reentrancy below, but it's safe since we already did all state changes.
        if (fees.length == 0) {
            // transfer token directly from payer to recipient if no fees
            ERC20(quota.token).safeTransferFrom(quota.payer, recipient, amount);
        } else {
            // transfer token from payer to this contract first.
            ERC20(quota.token).safeTransferFrom(quota.payer, address(this), amount);

            // send fees
            uint256 totalFees = 0;
            for (uint256 i = 0; i < fees.length; i++) {
                if (fees[i].amount == 0) continue;
                totalFees += fees[i].amount;
                require(totalFees <= amount, "INVALID_FEES");
                ERC20(quota.token).safeTransfer(fees[i].to, fees[i].amount);
            }

            // send remaining to recipient
            ERC20(quota.token).safeTransfer(recipient, amount - totalFees);
        }
    }

    /// @notice Get the status of a quota
    /// @dev Note that a quota can be cancelled but, if it's used for subscription, the subscription could still be
    // not ended yet if the current cycle has not ended yet. It depends on how the subscription implements.
    function getQuotaStatus(Quota calldata quota) public view returns (QuotaStatus status) {
        QuotaState memory state = _quotaStates[quota.hash()];

        // forgefmt:disable-next-item
        bool isCancelled = block.timestamp >= quota.endTime
            || quota.didMissCycle(state)
            || state.cancelled
            || payerNonces[quota.payer] > quota.payerNonce;

        if (isCancelled) return QuotaStatus.Cancelled;
        if (block.timestamp < quota.startTime) return QuotaStatus.NotStarted;
        if (quota.didChargeLatestCycle(state)) return QuotaStatus.Active;
        return state.chargeCount == 0 ? QuotaStatus.PendingFirstCharge : QuotaStatus.PendingNextCharge;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../libraries/QuotaLib.sol";

struct Fee {
    address to;
    uint160 amount;
}

interface IFeePolicy {
    function getFees(Quota calldata quota, uint160 chargeAmount, address chargeCaller)
        external
        view
        returns (Fee[] memory fees);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

using {
    shiftBytes,
    shiftBytes32,
    shiftAddress,
    shiftUint160,
    shiftUint40,
    shiftUint32,
    shiftUint24,
    shiftUint8
} for CalldataCursor global;

struct CalldataCursor {
    uint256 offset; // in bytes
    uint256 maxOffset; // in bytes
}

/// @dev Returns right-aligned value
/// @param cursor Calldata cursor
/// @param size Size of the value in bytes. Assuming the given value must be <=32.
function shift(CalldataCursor memory cursor, uint256 size) pure returns (uint256 value) {
    require(cursor.offset + size <= cursor.maxOffset, "Calldata: out of bounds");
    assembly ("memory-safe") {
        value := shr(sub(256, mul(8, size)), calldataload(mload(cursor)))
    }
    unchecked {
        cursor.offset += size;
    }
}

function shiftBytes(CalldataCursor memory cursor, uint256 size) pure returns (bytes memory value) {
    require(cursor.offset + size <= cursor.maxOffset, "Calldata: out of bounds");
    value = new bytes(size);
    assembly ("memory-safe") {
        calldatacopy(add(value, 32), mload(cursor), size)
    }
    unchecked {
        cursor.offset += size;
    }
}

function shiftBytes32(CalldataCursor memory cursor) pure returns (bytes32 value) {
    return bytes32(shift(cursor, 32));
}

function shiftAddress(CalldataCursor memory cursor) pure returns (address value) {
    return address(uint160(shift(cursor, 20)));
}

function shiftUint160(CalldataCursor memory cursor) pure returns (uint160 value) {
    return uint160(shift(cursor, 20));
}

function shiftUint40(CalldataCursor memory cursor) pure returns (uint40 value) {
    return uint40(shift(cursor, 5));
}

function shiftUint32(CalldataCursor memory cursor) pure returns (uint32 value) {
    return uint32(shift(cursor, 4));
}

function shiftUint24(CalldataCursor memory cursor) pure returns (uint24 value) {
    return uint24(shift(cursor, 3));
}

function shiftUint8(CalldataCursor memory cursor) pure returns (uint8 value) {
    return uint8(shift(cursor, 1));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @notice EIP712 helpers
 * @dev Modified fork from Uniswap (https://github.com/Uniswap/permit2/blob/main/src/EIP712.sol)
 */
abstract contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    bytes32 private immutable _HASHED_NAME;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    constructor(string memory name) {
        _HASHED_NAME = keccak256(bytes(name));
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Builds a domain separator using the current chainId and contract address.
    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, block.chainid, address(this)));
    }

    /// @notice Creates an EIP-712 typed data hash
    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    }

    /// @notice Verify signature for EIP-712 typed data
    function _verifySignature(bytes memory signature, bytes32 dataHash, address claimedSigner) internal view {
        SignatureVerification.verify(signature, _hashTypedData(dataHash), claimedSigner);
    }
}

/**
 * @dev Direct fork from Uniswap (https://github.com/Uniswap/permit2/blob/main/src/libraries/SignatureVerification.sol)
 */
library SignatureVerification {
    /// @notice Thrown when the passed in signature is not a valid length
    error InvalidSignatureLength();

    /// @notice Thrown when the recovered signer is equal to the zero address
    error InvalidSignature();

    /// @notice Thrown when the recovered signer does not equal the claimedSigner
    error InvalidSigner();

    /// @notice Thrown when the recovered contract signature is incorrect
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    function verify(bytes memory signature, bytes32 digest, address claimedSigner) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(digest, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(digest, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
        }
    }
}

interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

abstract contract Multicall {
    error CallError(uint256 index, bytes errorData);

    /// @notice Call multiple methods in a single transaction
    /// @param data Array of encoded function calls
    /// @return results Array of returned data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            bool success;
            (success, results[i]) = address(this).delegatecall(data[i]);
            if (!success) revert CallError(i, results[i]);
        }
    }

    // ----- common utils to use in multicall -----

    /// @notice Permit any ERC20 token
    function permitERC20(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        ERC20(token).permit(owner, spender, value, deadline, v, r, s);
    }

    /// @notice Permit DAI
    function permitDAI(
        address dai, //
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        IDAIPermit(dai).permit(owner, spender, ERC20(dai).nonces(owner), deadline, true, v, r, s);
    }

    /// @notice Get value of a storage slot
    function getStorageSlot(bytes32 slot) public view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(slot)
        }
    }
}

interface IDAIPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
 * `Quota` is a token allowance that a payer grants to a controller. The controller can pull token from the payer
 * address periodically according to the schedule defined in the quota.
 *
 * To protect payers, if the controller misses a charge cycle, the quota will be automatically cancelled.
 * Also, payers can revoke their approved quotas at any time.
 */
struct Quota {
    // payer info
    address payer; //           slot 0
    uint96 payerNonce;
    // token amount
    address token; //           slot 1
    uint160 amount; //          slot 2
    // charge schedule
    uint40 startTime;
    uint40 endTime;
    uint40 interval; //         slot 3
    uint40 chargeWindow;
    // controller info
    address controller;
    bytes32 controllerRefId; // slot 4
}

struct QuotaState {
    bool validated;
    bool cancelled; // by payer
    uint40 cycleStartTime;
    uint160 cycleAmountUsed;
    uint24 chargeCount;
}

enum QuotaStatus {
    NotStarted,
    PendingFirstCharge,
    Active,
    PendingNextCharge,
    Cancelled
}

library QuotaLib {
    bytes32 internal constant _QUOTA_TYPEHASH = keccak256(
        "Quota(address payer,uint96 payerNonce,address token,uint160 amount,uint40 startTime,uint40 endTime,uint40 interval,uint40 chargeWindow,address controller,bytes32 controllerRefId)"
    );

    function hash(Quota memory quota) internal pure returns (bytes32 quotaHash) {
        return keccak256(abi.encode(_QUOTA_TYPEHASH, quota));
    }

    /// @notice Calculate the start time of the quota's latest possible cycle
    /// @dev Assumed now >= quota.startTime, or else it reverts. Also, end time is not checked here.
    function latestCycleStartTime(Quota memory quota) internal view returns (uint40) {
        return quota.startTime + (((uint40(block.timestamp) - quota.startTime) / quota.interval) * quota.interval);
    }

    /// @notice Check whether the quota's latest cycle has been charged once
    function didChargeLatestCycle(Quota memory quota, QuotaState memory state) internal view returns (bool) {
        return state.chargeCount != 0 && uint256(state.cycleStartTime) + quota.interval > block.timestamp;
    }

    /// @notice Check whether the quota has missed any billing cycle
    function didMissCycle(Quota memory quota, QuotaState memory state) internal view returns (bool) {
        return state.chargeCount == 0
            ? uint256(quota.startTime) + quota.chargeWindow <= block.timestamp
            : uint256(state.cycleStartTime) + quota.interval + quota.chargeWindow <= block.timestamp;
    }

    /// @notice Calcuate the end time of the quota's current cycle, i.e. the cycle that the last charge happened in.
    function currentCycleEndTime(Quota memory quota, QuotaState memory state) internal pure returns (uint40) {
        uint256 endTime = uint256(state.cycleStartTime) + quota.interval;
        return endTime > type(uint40).max ? type(uint40).max : uint40(endTime); // truncate to uint40
    }
}