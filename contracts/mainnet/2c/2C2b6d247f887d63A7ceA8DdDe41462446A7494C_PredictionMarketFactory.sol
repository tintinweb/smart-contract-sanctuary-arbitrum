/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// File: contracts/IUniswapV2Router.sol


pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
}

// File: contracts/IUniswapV2Factory.sol


pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/Gelato/Types.sol


pragma solidity ^0.8.12;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IGelato {
    function feeCollector() external view returns (address);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: contracts/Gelato/AutomateReady.sol


pragma solidity ^0.8.14;



/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
// solhint-disable private-vars-leading-underscore
abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable feeCollector;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
        0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        IGelato gelato = IGelato(IAutomate(_automate).gelato());

        feeCollector = gelato.feeCollector();

        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = feeCollector.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), feeCollector, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = automate.getFeeDetails();
    }
}

// File: contracts/Gelato/AutomateTaskCreator.sol


pragma solidity ^0.8.14;


/**
 * @dev Inherit this contract to allow your smart contract
 * to be a task creator and create tasks.
 */
abstract contract AutomateTaskCreator is AutomateReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(
        address _automate,
        address _fundsOwner
    ) AutomateReady(_automate, address(this)) {
        fundsOwner = _fundsOwner;
        taskTreasury = automate.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(
            payable(fundsOwner),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            _amount
        );
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value: ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
            automate.createTask(
                _execAddress,
                _execDataOrSelector,
                _moduleData,
                _feeToken
            );
    }

    function _cancelTask(bytes32 _taskId) internal {
        automate.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(
        uint256 _startTime,
        uint256 _interval
    ) internal pure returns (bytes memory) {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// File: contracts/0xGBridgeProtocol.sol






pragma solidity >=0.8.0;

interface ICircleBridge {
    function depositForBurn(
        uint256 _amount,
        uint64 _dstChid,
        bytes32 _mintRecipient,
        address _burnToken
    ) external returns (uint64 _nonce);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

contract OxGambitBridgeProtocol is Ownable, AutomateTaskCreator {
    address public cBridge;
    address public ethDestAddress;

    bytes32 public taskId;

    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    IWETH private weth = IWETH(WETH);
    IERC20 private usdc = IERC20(USDC);

    event CounterTaskCreated(bytes32 taskId);

    constructor(
        address _automate,
        address _fundsOwner,
        address _bridgeAddress,
        address _ethDestAddress
    ) payable AutomateTaskCreator(_automate, _fundsOwner) {
        cBridge = _bridgeAddress;
        ethDestAddress = _ethDestAddress;

        depositFunds(msg.value);

        createTask();
    }

    receive() external payable {}

    function depositFunds(uint256 _amount) public payable {
        taskTreasury.depositFunds{value: _amount}(
            address(this),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            _amount
        );
    }

    function createTask() public {
        require(taskId == bytes32(""), "Already started task");

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(
            address(this),
            abi.encode(this.bridgeToEth.selector),
            moduleData,
            address(0)
        );

        taskId = id;
        emit CounterTaskCreated(id);
    }

    function checker()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (address(this).balance >= 0.1 ether) {
            canExec = true;
        } else canExec = false;

        execPayload = abi.encodeCall(this.bridgeToEth, ());
    }

    function wethDeposit() public {
        weth.deposit{value: address(this).balance}();
    }

    function swapToUsdc() public returns (uint amountOut) {
        wethDeposit();

        uint balanceToSwap = IERC20(WETH).balanceOf(address(this));
        IERC20(WETH).approve(address(router), balanceToSwap);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: USDC,
                fee: 500,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: balanceToSwap,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function addressToBytes32(address _address) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function bridgeToEth() public {
        swapToUsdc();

        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));

        IERC20(USDC).approve(cBridge, usdcBalance);

        ICircleBridge(cBridge).depositForBurn(
            usdcBalance,
            1,
            addressToBytes32(ethDestAddress),
            USDC
        );
    }

    function setEthDestAddress(address _newEthDestAddress) external onlyOwner {
        require(_newEthDestAddress != address(0), "Invalid address");
        ethDestAddress = _newEthDestAddress;
    }

    function withdrawAllTokens(address tokenAddress) external {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(
            IERC20(tokenAddress).transfer(msg.sender, balance),
            "Transfer failed"
        );
    }

    function withdrawAllETH() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// File: contracts/PredictionMarket.sol


pragma solidity ^0.8.0;









interface IERC20Balance {
    function decimals() external view returns (uint8);
}

interface IPredictionFactory {
    function addEthPayout(uint256 value) external;

    function addEntries(
        address _user,
        uint256 _bull,
        uint256 _bear,
        uint256 _ethWon
    ) external;

    function owner() external view returns (address);
}

contract PredictionMarket is Ownable, ReentrancyGuard, AutomateTaskCreator {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    event BetBear(address indexed user, uint256 indexed round, uint256 amount);
    event BetBull(address indexed user, uint256 indexed round, uint256 amount);
    event BullClaimed(
        address indexed user,
        uint256 roundId,
        uint256 amountClaimed
    );
    event BearClaimed(
        address indexed user,
        uint256 roundId,
        uint256 amountClaimed
    );
    event CounterTaskCreated(bytes32 taskId);

    receive() external payable {}

    address public predictionFactory;

    AggregatorV3Interface internal dataFeed;

    bytes32 public taskId;

    address private _refProgramCodeGenerator;
    bool public isRefProgramOpen;

    mapping(address => EnumerableSet.UintSet) private _userActivatedCodes;
    mapping(address => EnumerableSet.UintSet) private _userGeneratedCodes;
    mapping(uint256 => EnumerableSet.AddressSet) private _CodeClaimedAddresses;
    uint256 public totalCodesUsed;

    address public dextTrackableAddress;
    address public bridgeWallet;

    uint256 public roundID;
    uint256 public roundPeriod = 15 minutes;
    uint256 public bufferTime = 3 minutes;

    uint256 public minimumBet = 0.01 ether;
    uint256 public minimumToStartRound = 0.05 ether;
    mapping(uint256 => uint256) public roundOpenTimestamp; // roundID => timestamp
    uint256 public poolFee = 700;
    bool public isStopped;

    struct Round {
        uint256 startTimestamp;
        uint256 expireTimestamp;
        uint256 openPrice;
        uint256 closePrice;
        uint256 bearBetsAmount;
        uint256 bullBetsAmount;
        uint256 totalEthBets;
        bool roundClosed;
    }

    mapping(uint256 => Round) private rounds;

    struct UserEntries {
        uint256 bullEntries;
        uint256 bearEntries;
        uint256 totalEthBetted;
        uint256 totalEthWon;
        bool bullClaimed;
        bool bearClaimed;
    }

    mapping(address => mapping(uint256 => UserEntries)) private userEntries;
    mapping(address => EnumerableSet.UintSet) private _userBetRounds;

    uint256 public totalEthPayoutsMade;

    constructor(
        address _automate,
        address _fundsOwner,
        address _chainLinkAggregator,
        address _dextTrackableAddress,
        address _bridgeAddress
    ) payable AutomateTaskCreator(_automate, _fundsOwner) {
        dataFeed = AggregatorV3Interface(_chainLinkAggregator);

        bridgeWallet = _bridgeAddress;
        predictionFactory = msg.sender;
        dextTrackableAddress = _dextTrackableAddress;

        depositFunds(msg.value);
        createTask();
    }

    function setPoolFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 2_000, "Fee too high");
        poolFee = _newFee;
    }

    function setRoundPeriod(uint256 _newRoundPeriod) public onlyOwner {
        roundPeriod = _newRoundPeriod;
    }

    function depositFunds(uint256 _amount) public payable {
        taskTreasury.depositFunds{value: _amount}(
            address(this),
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            _amount
        );
    }

    function createTask() public {
        require(taskId == bytes32(""), "Already started task");

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.checker, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        bytes32 id = _createTask(
            address(this),
            abi.encode(this.updateRound.selector),
            moduleData,
            address(0)
        );

        taskId = id;
        emit CounterTaskCreated(id);
    }

    function getRoundInfo(
        uint256 roundId
    )
        public
        view
        returns (
            uint256 startTimestamp,
            uint256 expireTimestamp,
            uint256 openPrice,
            uint256 closePrice,
            uint256 bearBetsAmount,
            uint256 bullBetsAmount,
            uint256 totalEthBets,
            bool roundClosed
        )
    {
        Round storage round = rounds[roundId];
        return (
            round.startTimestamp,
            round.expireTimestamp,
            round.openPrice,
            round.closePrice,
            round.bearBetsAmount,
            round.bullBetsAmount,
            round.totalEthBets,
            round.roundClosed
        );
    }

    function getUserEntries(
        address user,
        uint256 roundId
    )
        public
        view
        returns (
            uint256 bullEntries,
            uint256 bearEntries,
            uint256 totalEthBetted,
            uint256 totalEthWon,
            bool bullClaimed,
            bool bearClaimed
        )
    {
        UserEntries storage entries = userEntries[user][roundId];
        return (
            entries.bullEntries,
            entries.bearEntries,
            entries.totalEthBetted,
            entries.totalEthWon,
            entries.bullClaimed,
            entries.bearClaimed
        );
    }

    function getUserRounds(
        address user
    ) public view returns (uint256[] memory) {
        return _userBetRounds[user].values();
    }

    function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function getPriceUSD() public view returns (uint256) {
        uint256 feedPrice = uint256(getChainlinkDataFeedLatestAnswer());

        return feedPrice;
    }

    function checker()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        Round storage currentRound = rounds[roundID];
        Round storage nextRound = rounds[roundID + 1];

        if (
            roundOpenTimestamp[roundID + 1] <= block.timestamp &&
            nextRound.bullBetsAmount >= minimumToStartRound &&
            nextRound.bearBetsAmount >= minimumToStartRound &&
            !isStopped &&
            nextRound.startTimestamp == 0
        ) {
            canExec = true;
        } else if (
            currentRound.expireTimestamp != 0 &&
            currentRound.expireTimestamp <= block.timestamp &&
            !currentRound.roundClosed
        ) {
            canExec = true;
        } else {
            canExec = false;
        }

        execPayload = abi.encodeCall(this.updateRound, ());
    }

    function stop() public {
        require(
            msg.sender == owner() ||
                msg.sender == IPredictionFactory(predictionFactory).owner()
        );
        isStopped = !isStopped;
    }

    function newRoundStartable() public view returns (bool canExec) {
        Round storage roundData = rounds[roundID];

        if (roundID == 0 && roundData.startTimestamp == 0) {
            canExec = true;
        } else if (!isStopped) {
            canExec = roundData.expireTimestamp < block.timestamp;
        }
    }

    function updateRound() public {
        require(newRoundStartable(), "Round not ended");

        Round storage currentRound = rounds[roundID];
        Round storage nextRound = rounds[roundID + 1];

        //Open round
        if (
            roundOpenTimestamp[roundID + 1] <= block.timestamp &&
            nextRound.bullBetsAmount >= minimumToStartRound &&
            nextRound.bearBetsAmount >= minimumToStartRound &&
            nextRound.startTimestamp == 0
        ) {
            nextRound.startTimestamp = block.timestamp;
            nextRound.expireTimestamp = block.timestamp + roundPeriod;
            nextRound.openPrice = getPriceUSD();

            roundID++;
        }

        // Close round
        if (
            currentRound.expireTimestamp != 0 &&
            currentRound.expireTimestamp <= block.timestamp &&
            !currentRound.roundClosed
        ) {
            currentRound.closePrice = getPriceUSD();
            currentRound.roundClosed = true;
        }
    }

    function roundResult(uint256 _roundID) public view returns (bool isBull) {
        Round storage roundData = rounds[_roundID];
        return (roundData.openPrice < roundData.closePrice);
    }

    function isEven(uint256 _roundID) public view returns (bool) {
        Round storage roundData = rounds[_roundID];
        return (roundData.openPrice == roundData.closePrice);
    }

    function bettingOpen() public view returns (bool) {
        return
            roundOpenTimestamp[roundID + 1] > block.timestamp ||
            roundOpenTimestamp[roundID + 1] == 0;
    }

    function enterBull(uint256 amount) public payable {
        require(amount == msg.value, "Amount incorrect");
        require(msg.value >= minimumBet, "Bet more");
        UserEntries storage userData = userEntries[msg.sender][roundID + 1];
        require(
            userData.bearEntries == 0 && userData.bullEntries == 0,
            "Already entered"
        );
        bool canBet = bettingOpen();
        require(canBet);

        Round storage roundData = rounds[roundID + 1];
        uint256 feeForGas = 200;
        uint256 communityFee = poolFee - feeForGas;
        uint256 revenuSharingFee = (amount * communityFee) / 10_000;
        uint256 gasFee = (amount * feeForGas) / 10_000;
        bool success;

        (success, ) = address(bridgeWallet).call{value: revenuSharingFee}("");

        depositFunds(gasFee);

        amount -= revenuSharingFee + gasFee;
        roundData.bullBetsAmount += amount;
        roundData.totalEthBets += amount;

        userData.bullEntries += amount;
        userData.totalEthBetted += amount;
        _userBetRounds[msg.sender].add(roundID + 1);

        IPredictionFactory(predictionFactory).addEntries(
            msg.sender,
            amount,
            0,
            0
        );

        if (
            roundData.bullBetsAmount >= minimumToStartRound &&
            roundData.bearBetsAmount >= minimumToStartRound &&
            roundOpenTimestamp[roundID + 1] == 0
        ) {
            roundOpenTimestamp[roundID + 1] = block.timestamp + bufferTime;
        }

        emit BetBull(msg.sender, roundID + 1, amount);
    }

    function enterBear(uint256 amount) public payable {
        require(amount == msg.value, "Amount incorrect");
        require(msg.value >= minimumBet, "Bet more");
        UserEntries storage userData = userEntries[msg.sender][roundID + 1];
        require(
            userData.bullEntries == 0 || userData.bearEntries == 0,
            "Already entered"
        );
        bool canBet = bettingOpen();
        require(canBet);

        Round storage roundData = rounds[roundID + 1];
        uint256 feeForGas = 200;
        uint256 communityFee = poolFee - feeForGas;
        uint256 revenuSharingFee = (amount * communityFee) / 10_000;
        uint256 gasFee = (amount * feeForGas) / 10_000;
        bool success;

        (success, ) = address(bridgeWallet).call{value: revenuSharingFee}("");

        depositFunds(gasFee);

        amount -= revenuSharingFee + gasFee;
        roundData.bearBetsAmount += amount;
        roundData.totalEthBets += amount;

        userData.bearEntries += amount;
        userData.totalEthBetted += amount;
        _userBetRounds[msg.sender].add(roundID + 1);

        IPredictionFactory(predictionFactory).addEntries(
            msg.sender,
            0,
            amount,
            0
        );

        if (
            roundData.bullBetsAmount >= minimumToStartRound &&
            roundData.bearBetsAmount >= minimumToStartRound &&
            roundOpenTimestamp[roundID + 1] == 0
        ) {
            roundOpenTimestamp[roundID + 1] = block.timestamp + bufferTime;
        }

        emit BetBear(msg.sender, roundID + 1, amount);
    }

    function bullShare(
        address user,
        uint256 _roundID
    ) public view returns (uint256 share) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];

        uint256 bullAmnt = roundData.bullBetsAmount;
        uint256 betAmnt = userData.bullEntries;

        if (betAmnt > 0) {
            share = (betAmnt * 10_000) / bullAmnt;
        } else {
            share = 0;
        }
    }

    function bearShare(
        address user,
        uint256 _roundID
    ) public view returns (uint256 share) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];

        uint256 bearAmnt = roundData.bearBetsAmount;
        uint256 betAmnt = userData.bearEntries;

        if (betAmnt > 0) {
            share = (betAmnt * 10_000) / bearAmnt;
        } else {
            share = 0;
        }
    }

    function bullMutiplier(uint256 _roundID) public view returns (uint256) {
        Round storage roundData = rounds[_roundID];
        uint256 bulls = roundData.bullBetsAmount;
        uint256 bears = roundData.bearBetsAmount;
        uint256 multipiler;

        if (bulls > 0 && bears > 0) {
            multipiler = 10_000 + ((bears * 10_000) / bulls);
        } else if (bears > 0 && bulls == 0) {
            multipiler = 10_000 + ((bears * 10_000) / minimumBet);
        } else {
            multipiler = 10_000;
        }

        return multipiler;
    }

    function bearMutiplier(uint256 _roundID) public view returns (uint256) {
        Round storage roundData = rounds[_roundID];
        uint256 bulls = roundData.bullBetsAmount;
        uint256 bears = roundData.bearBetsAmount;
        uint256 multipiler;

        if (bears > 0 && bulls > 0) {
            multipiler = 10_000 + ((bulls * 10_000) / bears);
        } else if (bulls > 0 && bears == 0) {
            multipiler = 10_000 + ((bulls * 10_000) / minimumBet);
        } else {
            multipiler = 10_000;
        }

        return multipiler;
    }

    function rewardBullsClaimableAmntsView(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClosed &&
            roundResult(_roundID);

        amountClaimable = 0;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            !roundResult(_roundID) &&
            roundData.bearBetsAmount == 0 &&
            userShare > 0
        ) {
            amountClaimable = userData.bullEntries;
        }
    }

    function rewardBearsClaimableAmntsView(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClosed &&
            !roundResult(_roundID);

        amountClaimable = 0;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            roundResult(_roundID) &&
            roundData.bullBetsAmount == 0 &&
            roundData.roundClosed &&
            userShare > 0
        ) {
            amountClaimable = userData.bearEntries;
        }
    }

    function rewardBullsClaimableAmnts(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClosed &&
            roundResult(_roundID) &&
            !userData.bullClaimed;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            !roundResult(_roundID) &&
            roundData.bearBetsAmount == 0 &&
            userShare > 0 &&
            roundData.roundClosed &&
            !userData.bullClaimed
        ) {
            amountClaimable = userData.bullEntries;
        }
    }

    function rewardBearsClaimableAmnts(
        address user,
        uint256 _roundID
    ) public view returns (uint256 amountClaimable) {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        uint256 totalEthPot = roundData.totalEthBets;
        bool isClaimable = totalEthPot > 0 &&
            userShare > 0 &&
            roundData.roundClosed &&
            !roundResult(_roundID) &&
            !userData.bearClaimed;

        if (isClaimable) {
            amountClaimable = (totalEthPot * userShare) / 10_000;
        } else if (
            roundResult(_roundID) &&
            roundData.bullBetsAmount == 0 &&
            userShare > 0 &&
            !userData.bearClaimed
        ) {
            amountClaimable = userData.bearEntries;
        }
    }

    function claimBull(
        address user,
        uint256 _roundID
    ) internal returns (uint256 amntClaimed) {
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bullShare(user, _roundID);
        require(userShare > 0, "No claims");
        require(!userData.bullClaimed, "already claimed");
        require(!isEven(_roundID));

        uint256 totalAmntWon = rewardBullsClaimableAmnts(user, _roundID);

        bool success;

        (success, ) = address(user).call{value: totalAmntWon}("");

        userData.totalEthWon += totalAmntWon;
        userData.bullClaimed = true;
        IPredictionFactory(predictionFactory).addEthPayout(totalAmntWon);

        amntClaimed = totalAmntWon;

        IPredictionFactory(predictionFactory).addEntries(
            msg.sender,
            0,
            0,
            amntClaimed
        );

        emit BullClaimed(user, _roundID, totalAmntWon);
    }

    function claimBear(
        address user,
        uint256 _roundID
    ) internal returns (uint256 amntClaimed) {
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userShare = bearShare(user, _roundID);
        require(userShare > 0, "No claims");
        require(!userData.bearClaimed, "already claimed");
        require(!isEven(_roundID));

        uint256 totalAmntWon = rewardBearsClaimableAmnts(user, _roundID);

        bool success;

        (success, ) = address(user).call{value: totalAmntWon}("");

        userData.totalEthWon += totalAmntWon;
        userData.bearClaimed = true;
        IPredictionFactory(predictionFactory).addEthPayout(totalAmntWon);

        amntClaimed = totalAmntWon;

        IPredictionFactory(predictionFactory).addEntries(
            msg.sender,
            0,
            0,
            amntClaimed
        );

        emit BearClaimed(user, _roundID, totalAmntWon);
    }

    function claimWinnings(address user, uint256 _roundID) public nonReentrant {
        Round storage roundData = rounds[_roundID];
        UserEntries storage userData = userEntries[user][_roundID];
        uint256 userBullShare = bullShare(user, _roundID);
        uint256 userBearShare = bearShare(user, _roundID);

        require(roundData.roundClosed, "Round is not closed");
        require(userBullShare > 0 || userBearShare > 0, "Nothing to claim");

        if (roundResult(_roundID) && !isEven(_roundID) && userBullShare > 0) {
            totalEthPayoutsMade += claimBull(user, _roundID);
        } else if (
            !roundResult(_roundID) && !isEven(_roundID) && userBearShare > 0
        ) {
            totalEthPayoutsMade += claimBear(user, _roundID);
        } else if (isEven(_roundID)) {
            if (userBullShare > 0) {
                bool success;
                (success, ) = address(user).call{value: userData.bullEntries}(
                    ""
                );
                totalEthPayoutsMade += userData.bullEntries;
                userData.totalEthWon += userData.bullEntries;
                userData.bullClaimed = true;

                IPredictionFactory(predictionFactory).addEthPayout(
                    userData.bullEntries
                );

                IPredictionFactory(predictionFactory).addEntries(
                    msg.sender,
                    0,
                    0,
                    userData.bullEntries
                );

                emit BullClaimed(user, _roundID, userData.bullEntries);
            } else if (userBearShare > 0) {
                bool success;
                (success, ) = address(user).call{value: userData.bearEntries}(
                    ""
                );

                totalEthPayoutsMade += userData.bearEntries;
                userData.totalEthWon += userData.bearEntries;
                userData.bearClaimed = true;

                IPredictionFactory(predictionFactory).addEthPayout(
                    userData.bearEntries
                );

                IPredictionFactory(predictionFactory).addEntries(
                    msg.sender,
                    0,
                    0,
                    userData.bearEntries
                );

                emit BearClaimed(user, _roundID, userData.bullEntries);
            }
        }

        if (
            userBullShare > 0 &&
            roundData.bearBetsAmount == 0 &&
            !roundResult(_roundID) &&
            !userData.bullClaimed
        ) {
            totalEthPayoutsMade += claimBull(user, _roundID);
        }

        if (
            userBearShare > 0 &&
            roundData.bullBetsAmount == 0 &&
            roundResult(_roundID) &&
            !userData.bearClaimed
        ) {
            totalEthPayoutsMade += claimBear(user, _roundID);
        }
    }
}

// File: @openzeppelin/contracts/utils/Create2.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// File: contracts/PredictionMarketFactory.sol


pragma solidity ^0.8.0;







contract PredictionMarketFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    event MarketCreated(address indexed tokenAddress);

    address public constant _automate =
        0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

    EnumerableSet.AddressSet private _markets;
    EnumerableSet.AddressSet private _tokens;
    EnumerableSet.AddressSet private _users;

    address public bridge;
    uint256 public totalEthPaidOut;

    struct userData {
        uint256 bullEntries;
        uint256 bearEntries;
        uint256 totalEthWon;
    }

    mapping(address => userData) private _userData;

    modifier onlyMarket() {
        require(_markets.contains(msg.sender), "Not an allowed market");
        _;
    }

    constructor(
        address automate,
        address cBridge,
        address ethDestAddress
    ) payable {
        OxGambitBridgeProtocol oxGambitBridgeProtocol = new OxGambitBridgeProtocol{
                value: msg.value
            }(automate, msg.sender, cBridge, ethDestAddress);
        bridge = address(oxGambitBridgeProtocol);
    }

    function addEthPayout(uint256 value) public onlyMarket {
        totalEthPaidOut += value;
    }

    function addEntries(
        address _user,
        uint256 _bull,
        uint256 _bear,
        uint256 _ethWon
    ) public onlyMarket {
        if (_bull > 0) {
            _userData[_user].bullEntries += _bull;
        }

        if (_bear > 0) {
            _userData[_user].bearEntries += _bear;
        }

        if (_ethWon > 0) {
            _userData[_user].totalEthWon += _ethWon;
        }

        if (!_users.contains(_user)) {
            _users.add(_user);
        }
    }

    function getUserData(
        address _user
    ) public view returns (uint256, uint256, uint256) {
        return (
            _userData[_user].bullEntries,
            _userData[_user].bearEntries,
            _userData[_user].totalEthWon
        );
    }

    function getPlayers() public view returns (address[] memory) {
        return _users.values();
    }

    function removeMarket(address market) public onlyOwner {
        _markets.remove(market);
    }

    function deployMarket(
        address _owner,
        address aggregator,
        address dextTrackableAddress
    ) public payable onlyOwner {
        require(msg.value >= 0 ether, "Not enough gas to pay rounds");
        require(!_tokens.contains(dextTrackableAddress), "Makret already exists");

        PredictionMarket predictionMarket = new PredictionMarket{
            value: msg.value
        }(_automate, _owner, aggregator, dextTrackableAddress, bridge);

        predictionMarket.transferOwnership(_owner);
        _markets.add(address(predictionMarket));
        _tokens.add(dextTrackableAddress);

        emit MarketCreated(address(predictionMarket));
    }

    function getAllMarkets() public view returns (address[] memory) {
        return _markets.values();
    }
}