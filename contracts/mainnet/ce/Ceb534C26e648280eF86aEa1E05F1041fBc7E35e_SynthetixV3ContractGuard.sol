// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2023 dHEDGE DAO
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";

import {ITxTrackingGuard} from "../../../interfaces/guards/ITxTrackingGuard.sol";
import {IERC721VerifyingGuard} from "../../../interfaces/guards/IERC721VerifyingGuard.sol";
import {IAccountModule} from "../../../interfaces/synthetixV3/IAccountModule.sol";
import {ICollateralModule} from "../../../interfaces/synthetixV3/ICollateralModule.sol";
import {ICollateralConfigurationModule} from "../../../interfaces/synthetixV3/ICollateralConfigurationModule.sol";
import {IIssueUSDModule} from "../../../interfaces/synthetixV3/IIssueUSDModule.sol";
import {IPoolConfigurationModule} from "../../../interfaces/synthetixV3/IPoolConfigurationModule.sol";
import {IRewardDistributor} from "../../../interfaces/synthetixV3/IRewardDistributor.sol";
import {IRewardsManagerModule} from "../../../interfaces/synthetixV3/IRewardsManagerModule.sol";
import {IVaultModule} from "../../../interfaces/synthetixV3/IVaultModule.sol";
import {IERC721Enumerable} from "../../../interfaces/IERC721Enumerable.sol";
import {IHasAssetInfo} from "../../../interfaces/IHasAssetInfo.sol";
import {IHasSupportedAsset} from "../../../interfaces/IHasSupportedAsset.sol";
import {IPoolFactory} from "../../../interfaces/IPoolFactory.sol";
import {IPoolManagerLogic} from "../../../interfaces/IPoolManagerLogic.sol";
import {ITransactionTypes} from "../../../interfaces/ITransactionTypes.sol";
import {SynthetixV3Structs} from "../../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";
import {WeeklyWindowsHelper} from "../../../utils/synthetixV3/libraries/WeeklyWindowsHelper.sol";
import {DhedgeNftTrackerStorage} from "../../../utils/tracker/DhedgeNftTrackerStorage.sol";
import {PrecisionHelper} from "../../../utils/PrecisionHelper.sol";
import {TxDataUtils} from "../../../utils/TxDataUtils.sol";

contract SynthetixV3ContractGuard is TxDataUtils, ITxTrackingGuard, ITransactionTypes, IERC721VerifyingGuard {
  using Math for uint256;
  using SafeMath for uint256;
  using SafeCast for uint256;
  using WeeklyWindowsHelper for SynthetixV3Structs.Window;
  using WeeklyWindowsHelper for SynthetixV3Structs.WeeklyWindows;
  using PrecisionHelper for address;

  /// @dev Hardcoded limit of Synthetix V3 NFT account per pool
  uint256 public constant MAX_ACCOUNT_LIMIT = 1;

  DhedgeNftTrackerStorage public immutable nftTracker;

  mapping(address => SynthetixV3Structs.VaultSetting) public dHedgeVaultsWhitelist;

  SynthetixV3Structs.WeeklyWindows public windows;

  SynthetixV3Structs.WeeklyWithdrawalLimit public withdrawalLimit;

  bool public override isTxTrackingGuard = true;

  /// @dev For the sake of simplicity, setting configurational parameters during init instead of getting from Synthetix V3 Core contract
  /// @param _nftTracker dHEDGE system NFT tracker contract address
  /// @param _whitelisteddHedgeVaults dHEDGE vaults that are allowed to use Synthetix V3, each with own parameters we are going to support
  /// @param _snxV3Core Synthetix V3 Core contract address
  /// @param _windows Periods when specific actions are allowed
  /// @param _withdrawalLimit Params for withdrawal limit
  constructor(
    address _nftTracker,
    SynthetixV3Structs.VaultSetting[] memory _whitelisteddHedgeVaults,
    address _snxV3Core,
    SynthetixV3Structs.WeeklyWindows memory _windows,
    SynthetixV3Structs.WeeklyWithdrawalLimit memory _withdrawalLimit
  ) {
    require(_nftTracker != address(0), "invalid nftTracker");
    require(_snxV3Core != address(0), "invalid snxV3Core");

    nftTracker = DhedgeNftTrackerStorage(_nftTracker);

    address poolFactory = DhedgeNftTrackerStorage(_nftTracker).poolFactory();
    for (uint256 i; i < _whitelisteddHedgeVaults.length; ++i) {
      SynthetixV3Structs.VaultSetting memory vaultSetting = _whitelisteddHedgeVaults[i];
      _validateVaultSetting(
        _snxV3Core,
        poolFactory,
        vaultSetting.poolLogic,
        vaultSetting.collateralAsset,
        vaultSetting.debtAsset,
        vaultSetting.snxLiquidityPoolId
      );
      dHedgeVaultsWhitelist[vaultSetting.poolLogic] = vaultSetting;
    }

    _windows.validateWindows();
    windows = _windows;

    withdrawalLimit = _withdrawalLimit;
  }

  /// @notice Returns Synthetix Account NFT ID associated with the pool stored in dHEDGE NFT Tracker contract
  /// @dev Assumes that in our inner tracking system the pool always holds only one Synthetix V3 NFT
  /// @param _poolLogic Pool address
  /// @param _to Synthetix V3 Core address
  /// @return tokenId Synthetix Account NFT ID
  function getAccountNftTokenId(address _poolLogic, address _to) public view returns (uint128 tokenId) {
    uint256[] memory tokenIds = nftTracker.getAllUintIds(
      _getNftType(IAccountModule(_to).getAccountTokenAddress()),
      _poolLogic
    );

    if (tokenIds.length == 1) {
      tokenId = tokenIds[0].toUint128();
    }
  }

  /// @notice Helper function to check if the vault is whitelisted
  /// @param _wanted PoolLogic address of interest
  /// @return isWhitelisted If the address is whitelisted
  function isVaultWhitelisted(address _wanted) public view returns (bool) {
    require(_wanted != address(0), "invalid pool logic");
    return dHedgeVaultsWhitelist[_wanted].poolLogic == _wanted;
  }

  /// @notice Helper function to calculate withdrawal limit
  /// @param _totalCollateralD18 Total collateral deposited, denominated with 18 decimals of precision
  /// @param _collateralType Collateral asset address
  /// @param _poolManagerLogic Pool manager logic address
  /// @return limitD18 Amount of withdrawal limit
  function calculateWithdrawalLimit(
    uint256 _totalCollateralD18,
    address _collateralType,
    IPoolManagerLogic _poolManagerLogic
  ) public view returns (uint256 limitD18) {
    // Pass the amount, denominated with asset's native decimal representation
    uint256 amountToPass = _totalCollateralD18.div(_collateralType.getPrecisionForConversion());
    // Calculate how much USD is percent limit
    uint256 percentUsdLimit = _poolManagerLogic.assetValue(
      _collateralType,
      amountToPass.mul(withdrawalLimit.percent).div(10 ** 18)
    );
    // Pick the biggest one
    uint256 usdLimit = percentUsdLimit.max(withdrawalLimit.usdValue);
    // Get the limit in collateral tokens, denominated with 18 decimals of precision
    limitD18 = usdLimit.mul(10 ** 18).div(IHasAssetInfo(_poolManagerLogic.factory()).getAssetPrice(_collateralType));
  }

  /// @notice Transaction guard for Synthetix V3 Core
  /// @dev Supports general flow for Synthetix V3 Protocol
  /// @dev Can be called only by PoolLogic during execTransaction
  /// @dev Includes account creation, collateral deposit/withdrawal, delegate collateral, mint/burn snxUSD
  /// @param _poolManagerLogic Pool manager logic address
  /// @param _to Synthetix V3 Core address
  /// @param _data Transaction data
  /// @return txType Transaction type
  /// @return isPublic If the transaction is public or private
  function txGuard(
    address _poolManagerLogic,
    address _to,
    bytes memory _data
  ) external override returns (uint16 txType, bool isPublic) {
    address poolLogic = IPoolManagerLogic(_poolManagerLogic).poolLogic();

    require(msg.sender == poolLogic, "not pool logic");

    require(isVaultWhitelisted(poolLogic), "dhedge vault not whitelisted");

    IHasSupportedAsset poolManagerLogicAssets = IHasSupportedAsset(_poolManagerLogic);

    // Not allowing anything before enabling Synthetix V3 position asset (which is basically Synthetix V3 Core address)
    require(poolManagerLogicAssets.isSupportedAsset(_to), "enable synthetix v3 asset");

    SynthetixV3Structs.VaultSetting storage vaultSetting = dHedgeVaultsWhitelist[poolLogic];

    bytes4 method = getMethod(_data);
    bytes memory params = getParams(_data);

    if (method == bytes4(keccak256("createAccount()")) || method == bytes4(keccak256("createAccount(uint128)"))) {
      address snxAccountNft = IAccountModule(_to).getAccountTokenAddress();
      // Revert if pool already has associated Synthetix V3 NFT account
      require(nftTracker.getDataCount(_getNftType(snxAccountNft), poolLogic) == 0, "only one account allowed");

      txType = uint16(TransactionType.SynthetixV3CreateAccount);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == ICollateralModule.deposit.selector) {
      (uint128 accountId, address collateralType) = abi.decode(params, (uint128, address));

      // Collateral deposited into pool's Synthetix V3 account must be the one we support
      require(
        collateralType == vaultSetting.collateralAsset || collateralType == vaultSetting.debtAsset,
        "unsupported collateral type"
      );
      // Deposit must happen only into the account owned by the pool
      // We check not by ownership of the nft, but using our inner tracking system not to count airdropped NFTs
      require(getAccountNftTokenId(poolLogic, _to) == accountId, "account not owned by pool");

      txType = uint16(TransactionType.SynthetixV3DepositCollateral);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == ICollateralModule.withdraw.selector) {
      (, address collateralType) = abi.decode(params, (uint128, address));

      // Must match collateral we support
      require(
        collateralType == vaultSetting.collateralAsset || collateralType == vaultSetting.debtAsset,
        "unsupported collateral type"
      );
      // Upon withdrawing from its account, pool must have collateral asset enabled as it's going to receive it
      require(poolManagerLogicAssets.isSupportedAsset(collateralType), "collateral asset must be enabled");

      txType = uint16(TransactionType.SynthetixV3WithdrawCollateral);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IVaultModule.delegateCollateral.selector) {
      (txType, isPublic) = _verifyDelegateCollateral(params, poolLogic, _to, _poolManagerLogic, vaultSetting);
    } else if (method == IIssueUSDModule.mintUsd.selector) {
      (uint128 accountId, uint128 poolId, address collateralType) = abi.decode(params, (uint128, uint128, address));

      // Minting should happen only from the account owned by the pool
      require(getAccountNftTokenId(poolLogic, _to) == accountId, "account not owned by pool");
      // Must mint snxUSD against liquidity pool we support
      require(vaultSetting.snxLiquidityPoolId == poolId, "lp not allowed");
      // Must match collateral we support
      require(collateralType == vaultSetting.collateralAsset, "unsupported collateral type");
      // Only allowed during predefined so-called "delegation period"
      require(windows.delegationWindow.isWithinAllowedWindow(block.timestamp), "outside delegation window");

      txType = uint16(TransactionType.SynthetixV3MintUSD);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IIssueUSDModule.burnUsd.selector) {
      (uint128 accountId, uint128 poolId, address collateralType) = abi.decode(params, (uint128, uint128, address));

      // Burning should happen only from the account owned by the pool
      require(getAccountNftTokenId(poolLogic, _to) == accountId, "account not owned by pool");
      // Must burn snxUSD against liquidity pool we support
      require(vaultSetting.snxLiquidityPoolId == poolId, "lp not allowed");
      // Must match collateral we support
      require(collateralType == vaultSetting.collateralAsset, "unsupported collateral type");
      // Not allowed outside of delegation and undelegation windows. To undelegate, positive debt must be burned first
      require(
        windows.delegationWindow.isWithinAllowedWindow(block.timestamp) ||
          windows.undelegationWindow.isWithinAllowedWindow(block.timestamp),
        "outside allowed windows"
      );

      txType = uint16(TransactionType.SynthetixV3BurnUSD);

      emit SynthetixV3Event(poolLogic, txType);
    } else if (method == IRewardsManagerModule.claimRewards.selector) {
      (uint128 accountId, uint128 poolId, address collateralType, address distributor) = abi.decode(
        params,
        (uint128, uint128, address, address)
      );

      require(getAccountNftTokenId(poolLogic, _to) == accountId, "account not owned by pool");

      require(vaultSetting.snxLiquidityPoolId == poolId, "lp not allowed");

      require(
        collateralType == vaultSetting.collateralAsset || collateralType == vaultSetting.debtAsset,
        "unsupported collateral type"
      );

      require(
        poolManagerLogicAssets.isSupportedAsset(IRewardDistributor(distributor).token()),
        "unsupported reward asset"
      );

      txType = uint16(TransactionType.SynthetixV3ClaimReward);

      emit SynthetixV3Event(poolLogic, txType);
    }

    return (txType, isPublic);
  }

  function verifyERC721(
    address,
    address _from,
    uint256,
    bytes calldata
  ) external pure override returns (bool verified) {
    // Most likely it's an overkill. Checks that the NFT is minted, not transferred
    require(_from == address(0), "can't accept foreign NFTs");

    verified = true;
  }

  /// @dev Required because we need to track minted Synthetix V3 NFT Account IDs
  /// @dev Can be called only by PoolLogic during execTransaction
  /// @param _poolManagerLogic Pool manager logic address
  /// @param _to Synthetix V3 Core address
  /// @param _data Transaction data
  function afterTxGuard(address _poolManagerLogic, address _to, bytes memory _data) external override {
    address poolLogic = IPoolManagerLogic(_poolManagerLogic).poolLogic();

    require(msg.sender == poolLogic, "not pool logic");

    require(isVaultWhitelisted(poolLogic), "dhedge vault not whitelisted");

    bytes4 method = getMethod(_data);

    // Runs only after Synthetix V3 Core contract calls related to account creation
    // Handles both createAccount() and createAccount(uint128) methods
    if (method == bytes4(keccak256("createAccount(uint128)"))) {
      // Id was passed in advance, see https://docs.synthetix.io/v/v3/for-developers/smart-contracts#createaccount
      uint128 id = abi.decode(getParams(_data), (uint128));
      _afterTxGuardHelper(id, poolLogic, _to);
    } else if (method == bytes4(keccak256("createAccount()"))) {
      address snxAccountNft = IAccountModule(_to).getAccountTokenAddress();
      // Id was assigned by Synthetix V3 System and we're getting it from the Synthetix V3 Account NFT
      uint256 balance = IERC721Enumerable(snxAccountNft).balanceOf(poolLogic);
      require(balance > 0, "no minted nft");
      // Most recent minted NFT is the last one
      uint256 id = IERC721Enumerable(snxAccountNft).tokenOfOwnerByIndex(poolLogic, balance - 1);
      _afterTxGuardHelper(id, poolLogic, _to);
    }
  }

  /// @notice Helper function to track minted Synthetix V3 NFT Account IDs
  /// @dev We are tracking minted Synthetix V3 NFT Account IDs in dHEDGE NFT Tracker contract
  /// @param _id Synthetix V3 NFT Account ID associated with the pool
  /// @param _poolLogic Pool logic address
  /// @param _to Synthetix V3 Core address
  function _afterTxGuardHelper(uint256 _id, address _poolLogic, address _to) internal {
    bytes32 nftType = _getNftType(IAccountModule(_to).getAccountTokenAddress());
    // Storing Synthetix V3 NFT Account ID associated with the pool in dHEDGE NFT Tracker contract by NFT type
    // It ensures that max positions limit is not breached
    nftTracker.addUintId(_to, nftType, _poolLogic, _id, MAX_ACCOUNT_LIMIT);
  }

  /// @notice Helper function to build NFT type
  /// @dev NFT type is a keccak256 hash of Synthetix V3 Account NFT address
  /// @param _accountNftToken Synthetix V3 Account NFT address
  /// @return nftType NFT type
  function _getNftType(address _accountNftToken) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_accountNftToken));
  }

  /// @notice Handles delegation and undelegation
  /// @dev Limits execution according to predefined time periods
  /// @param _params Transaction parameters
  /// @param _poolLogic Pool logic address
  /// @param _to Synthetix V3 Core address
  /// @param _poolManagerLogic Pool manager logic address
  /// @param _vaultSetting Vault setting
  /// @return txType Transaction type
  /// @return isPublic If the transaction is public or private
  function _verifyDelegateCollateral(
    bytes memory _params,
    address _poolLogic,
    address _to,
    address _poolManagerLogic,
    SynthetixV3Structs.VaultSetting storage _vaultSetting
  ) internal returns (uint16 txType, bool isPublic) {
    (uint128 accountId, uint128 poolId, address collateralType, uint256 newCollateralAmountD18, uint256 leverage) = abi
      .decode(_params, (uint128, uint128, address, uint256, uint256));
    // Delegate should happen only from the account owned by the pool
    require(getAccountNftTokenId(_poolLogic, _to) == accountId, "account not owned by pool");
    // Make sure leverage is 1, as it can change in the future
    require(leverage == 10 ** 18, "unsupported leverage");
    // Must delegate collateral only to allowed liquidity pool
    require(_vaultSetting.snxLiquidityPoolId == poolId, "lp not allowed");
    // Must match collateral we support
    require(collateralType == _vaultSetting.collateralAsset, "unsupported collateral type");

    // During delegation window manager is free to do anything
    if (windows.delegationWindow.isWithinAllowedWindow(block.timestamp)) {
      txType = uint16(TransactionType.SynthetixV3DelegateCollateral);

      emit SynthetixV3Event(_poolLogic, txType);
      // During undelegation window anyone is allowed to undelegate only
    } else if (windows.undelegationWindow.isWithinAllowedWindow(block.timestamp)) {
      // Total deposited = total available + total assigned
      (uint256 totalDepositedD18, uint256 totalAssignedD18, ) = ICollateralModule(_to).getAccountCollateral(
        accountId,
        collateralType
      );
      // Forbidden to delegate more during undelegation window
      require(newCollateralAmountD18 < totalAssignedD18, "only undelegation allowed");

      uint256 totalAvailableD18 = totalDepositedD18.sub(totalAssignedD18);
      uint256 amountToUndelegateD18 = totalAssignedD18.sub(newCollateralAmountD18);
      // Can proceed only if total available for withdrawal + amount to be undelegated is less than withdrawal limit
      require(
        totalAvailableD18.add(amountToUndelegateD18) <=
          calculateWithdrawalLimit(totalDepositedD18, collateralType, IPoolManagerLogic(_poolManagerLogic)),
        "undelegation limit breached"
      );

      txType = uint16(TransactionType.SynthetixV3UndelegateCollateral);
      isPublic = true;

      emit SynthetixV3Event(_poolLogic, txType);
      // Outside of delegation and undelegation windows nothing is allowed
    } else {
      revert("outside allowed windows");
    }
  }

  /// @notice Helper function to validate vault setting
  /// @dev Can call getPoolCollateralConfiguration for additional checks
  /// @param _snxV3Core Synthetix V3 Core contract address
  /// @param _poolFactory dHEDGE PoolFactory address
  /// @param _poolLogic PoolLogic address
  /// @param _collateralAsset Collateral asset address
  /// @param _debtAsset Debt asset address
  function _validateVaultSetting(
    address _snxV3Core,
    address _poolFactory,
    address _poolLogic,
    address _collateralAsset,
    address _debtAsset,
    uint128 _snxLiquidityPoolId
  ) internal view {
    require(_poolLogic != address(0) && IPoolFactory(_poolFactory).isPool(_poolLogic), "invalid pool logic");
    require(
      _collateralAsset != address(0) &&
        IHasAssetInfo(_poolFactory).isValidAsset(_collateralAsset) &&
        ICollateralConfigurationModule(_snxV3Core).getCollateralConfiguration(_collateralAsset).depositingEnabled,
      "invalid collateral asset"
    );
    require(_debtAsset != address(0), "invalid debt asset");

    // Currently is set to 1
    uint128 poolId = IPoolConfigurationModule(_snxV3Core).getPreferredPool();
    // Currently this list is empty, so to make things work we need to check both preferred pool and approved pools
    uint256[] memory poolIds = IPoolConfigurationModule(_snxV3Core).getApprovedPools();
    // First check preferred pool
    bool isPoolValid = _snxLiquidityPoolId == poolId;
    // if not found in preferred pool, check approved pools
    if (!isPoolValid) {
      for (uint256 i; i < poolIds.length; ++i) {
        if (_snxLiquidityPoolId == poolIds[i]) {
          isPoolValid = true;
          break;
        }
      }
    }
    require(isPoolValid, "invalid snx liquidity pool id");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IERC721VerifyingGuard {
  function verifyERC721(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata
  ) external returns (bool verified);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGuard {
  event ExchangeFrom(address fundAddress, address sourceAsset, uint256 sourceAmount, address dstAsset, uint256 time);
  event ExchangeTo(address fundAddress, address sourceAsset, address dstAsset, uint256 dstAmount, uint256 time);

  function txGuard(
    address poolManagerLogic,
    address to,
    bytes calldata data
  ) external returns (uint16 txType, bool isPublic); // TODO: eventually update `txType` to be of enum type as per ITransactionTypes
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IGuard.sol";

interface ITxTrackingGuard is IGuard {
  function isTxTrackingGuard() external view returns (bool);

  function afterTxGuard(address poolManagerLogic, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <=0.8.10;

// With aditional optional views

interface IERC20Extended {
  // ERC20 Optional Views
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  // Views
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function scaledBalanceOf(address user) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  // Mutative functions
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   *
   * Requirements:
   * - `owner` must be a valid address
   * - `index` must be less than the balance of the tokens for the owner
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <=0.8.10;

interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetType(address asset) external view returns (uint16);

  function getMaximumSupportedAssetCount() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasGuardInfo {
  // Get guard
  function getContractGuard(address extContract) external view returns (address);

  // Get asset guard
  function getAssetGuard(address extContract) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

interface IHasSupportedAsset {
  struct Asset {
    address asset;
    bool isDeposit;
  }

  function getSupportedAssets() external view returns (Asset[] memory);

  function isSupportedAsset(address asset) external view returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolFactory {
  function governanceAddress() external view returns (address);

  function isPool(address pool) external view returns (bool);

  function customCooldownWhitelist(address from) external view returns (bool);

  function receiverWhitelist(address to) external view returns (bool);

  function emitPoolEvent() external;

  function emitPoolManagerEvent() external;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolManagerLogic {
  function poolLogic() external view returns (address);

  function isDepositAsset(address asset) external view returns (bool);

  function validateAsset(address asset) external view returns (bool);

  function assetValue(address asset) external view returns (uint256);

  function assetValue(address asset, uint256 amount) external view returns (uint256);

  function assetBalance(address asset) external view returns (uint256 balance);

  function factory() external view returns (address);

  function setPoolLogic(address fundAddress) external returns (bool);

  function totalFundValue() external view returns (uint256);

  function totalFundValueMutable() external returns (uint256);

  function isMemberAllowed(address member) external view returns (bool);

  function getFee() external view returns (uint256, uint256, uint256, uint256);

  function minDepositUSD() external view returns (uint256);
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Transaction type events used in pool execTransaction() contract guards
/// @dev Gradually migrate to these events as we update / add new contract guards
interface ITransactionTypes {
  // Transaction Types in execTransaction()
  // 1. Approve: Approving a token for spending by different address/contract
  // 2. Exchange: Exchange/trade of tokens eg. Uniswap, Synthetix
  // 3. AddLiquidity: Add liquidity
  event AddLiquidity(address poolLogic, address pair, bytes params, uint256 time);
  // 4. RemoveLiquidity: Remove liquidity
  event RemoveLiquidity(address poolLogic, address pair, bytes params, uint256 time);
  // 5. Stake: Stake tokens into a third party contract (eg. Sushi yield farming)
  event Stake(address poolLogic, address stakingToken, address to, uint256 amount, uint256 time);
  // 6. Unstake: Unstake tokens from a third party contract (eg. Sushi yield farming)
  event Unstake(address poolLogic, address stakingToken, address to, uint256 amount, uint256 time);
  // 7. Claim: Claim rewards tokens from a third party contract (eg. SUSHI & MATIC rewards)
  event Claim(address poolLogic, address stakingContract, uint256 time);
  // 8. UnstakeAndClaim: Unstake tokens and claim rewards from a third party contract
  // 9. Deposit: Aave deposit tokens -> get Aave Interest Bearing Token
  // 10. Withdraw: Withdraw tokens from Aave Interest Bearing Token
  // 11. SetUserUseReserveAsCollateral: Aave set reserve asset to be used as collateral
  // 12. Borrow: Aave borrow tokens
  // 13. Repay: Aave repay tokens
  // 14. SwapBorrowRateMode: Aave change borrow rate mode (stable/variable)
  // 15. RebalanceStableBorrowRate: Aave rebalance stable borrow rate
  // 16. JoinPool: Balancer join pool
  // 17. ExitPool: Balancer exit pool
  // 18. Deposit: EasySwapper Deposit
  // 19. Withdraw: EasySwapper Withdraw
  // 20. Mint: Uniswap V3 Mint position
  // 21. IncreaseLiquidity: Uniswap V3 increase liquidity position
  // 22. DecreaseLiquidity: Uniswap V3 decrease liquidity position
  // 23. Burn: Uniswap V3 Burn position
  // 24. Collect: Uniswap V3 collect fees
  // 25. Multicall: Uniswap V3 Multicall
  // 26. Lyra: open position
  // 27. Lyra: close position
  // 28. Lyra: force close position
  // 29. Futures: Market
  // 30. AddLiquidity: Single asset add liquidity (eg. Stargate)
  event AddLiquiditySingle(address fundAddress, address asset, address liquidityPool, uint256 amount, uint256 time);
  // 31. RemoveLiquidity: Single asset remove liquidity (eg. Stargate)
  event RemoveLiquiditySingle(address fundAddress, address asset, address liquidityPool, uint256 amount, uint256 time);
  // 32. Redeem Deprecated Synths into sUSD
  event SynthRedeem(address poolAddress, IERC20[] synthProxies);
  // 33. Synthetix V3 transactions
  event SynthetixV3Event(address poolLogic, uint256 txType);
  // 34. Sonne: Mint
  event SonneMintEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 35. Sonne: Redeem
  event SonneRedeemEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 36. Sonne: Redeem Underlying
  event SonneRedeemUnderlyingEvent(
    address indexed fundAddress,
    address asset,
    address cToken,
    uint256 amount,
    uint256 time
  );
  // 37. Sonne: Borrow
  event SonneBorrowEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 38. Sonne: Repay
  event SonneRepayEvent(address indexed fundAddress, address asset, address cToken, uint256 amount, uint256 time);
  // 39. Sonne: Comptroller Enter Markets
  event SonneEnterMarkets(address indexed poolLogic, address[] cTokens, uint256 time);
  // 40. Sonne: Comptroller Exit Market
  event SonneExitMarket(address indexed poolLogic, address cToken, uint256 time);

  // Enum representing Transaction Types
  enum TransactionType {
    NotUsed, // 0
    Approve, // 1
    Exchange, // 2
    AddLiquidity, // 3
    RemoveLiquidity, // 4
    Stake, // 5
    Unstake, // 6
    Claim, // 7
    UnstakeAndClaim, // 8
    AaveDeposit, // 9
    AaveWithdraw, // 10
    AaveSetUserUseReserveAsCollateral, // 11
    AaveBorrow, // 12
    AaveRepay, // 13
    AaveSwapBorrowRateMode, // 14
    AaveRebalanceStableBorrowRate, // 15
    BalancerJoinPool, // 16
    BalancerExitPool, // 17
    EasySwapperDeposit, // 18
    EasySwapperWithdraw, // 19
    UniswapV3Mint, // 20
    UniswapV3IncreaseLiquidity, // 21
    UniswapV3DecreaseLiquidity, // 22
    UniswapV3Burn, // 23
    UniswapV3Collect, // 24
    UniswapV3Multicall, // 25
    LyraOpenPosition, // 26
    LyraClosePosition, // 27
    LyraForceClosePosition, // 28
    KwentaFuturesMarket, // 29
    AddLiquiditySingle, // 30
    RemoveLiquiditySingle, // 31
    MaiTx, // 32
    LyraAddCollateral, // 33
    LyraLiquidatePosition, // 34
    KwentaPerpsV2Market, // 35
    RedeemSynth, // 36
    SynthetixV3CreateAccount, // 37
    SynthetixV3DepositCollateral, // 38
    SynthetixV3WithdrawCollateral, // 39
    SynthetixV3DelegateCollateral, // 40
    SynthetixV3MintUSD, // 41
    SynthetixV3BurnUSD, // 42
    SynthetixV3Multicall, // 43
    XRamCreateVest, // 44
    XRamExitVest, // 45
    SynthetixV3Wrap, // 46
    SynthetixV3Unwrap, // 47
    SynthetixV3BuySynth, // 48
    SynthetixV3SellSynth, // 49
    SonneMint, // 50
    SonneRedeem, // 51
    SonneRedeemUnderlying, // 52
    SonneBorrow, // 53
    SonneRepay, // 54
    SonneComptrollerEnterMarkets, // 55
    SonneComptrollerExitMarket, // 56
    SynthetixV3UndelegateCollateral, // 57
    AaveMigrateToV3, // 58
    FlatMoneyStableDeposit, // 59
    FlatMoneyStableWithdraw, // 60
    FlatMoneyCancelOrder, // 61
    SynthetixV3ClaimReward, // 62
    VelodromeCLStake, // 63
    VelodromeCLUnstake, // 64
    VelodromeCLMint, // 65
    VelodromeCLIncreaseLiquidity, // 66
    VelodromeCLDecreaseLiquidity, // 67
    VelodromeCLBurn, // 68
    VelodromeCLCollect, // 69
    VelodromeCLMulticall, // 70
    FlatMoneyLeverageOpen, // 71
    FlatMoneyLeverageAdjust, // 72
    FlatMoneyLeverageClose // 73
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Module for managing accounts.
 * @notice Manages the system's account token NFT. Every user will need to register an account before being able to interact with the system.
 */
interface IAccountModule {
  /**
   * @dev Data structure for tracking each user's permissions.
   */
  struct AccountPermissions {
    address user;
    bytes32[] permissions;
  }

  /**
   * @notice Returns an array of `AccountPermission` for the provided `accountId`.
   * @param accountId The id of the account whose permissions are being retrieved.
   * @return accountPerms An array of AccountPermission objects describing the permissions granted to the account.
   */
  function getAccountPermissions(uint128 accountId) external view returns (AccountPermissions[] memory accountPerms);

  /**
   * @notice Mints an account token with id `requestedAccountId` to `msg.sender`.
   * @param requestedAccountId The id requested for the account being created. Reverts if id already exists.
   *
   * Requirements:
   *
   * - `requestedAccountId` must not already be minted.
   * - `requestedAccountId` must be less than type(uint128).max / 2
   *
   * Emits a {AccountCreated} event.
   */
  function createAccount(uint128 requestedAccountId) external;

  /**
   * @notice Mints an account token with an available id to `msg.sender`.
   *
   * Emits a {AccountCreated} event.
   */
  function createAccount() external returns (uint128 accountId);

  /**
   * @notice Called by AccountTokenModule to notify the system when the account token is transferred.
   * @dev Resets user permissions and assigns ownership of the account token to the new holder.
   * @param to The new holder of the account NFT.
   * @param accountId The id of the account that was just transferred.
   *
   * Requirements:
   *
   * - `msg.sender` must be the account token.
   */
  function notifyAccountTransfer(address to, uint128 accountId) external;

  /**
   * @notice Grants `permission` to `user` for account `accountId`.
   * @param accountId The id of the account that granted the permission.
   * @param permission The bytes32 identifier of the permission.
   * @param user The target address that received the permission.
   *
   * Requirements:
   *
   * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
   *
   * Emits a {PermissionGranted} event.
   */
  function grantPermission(uint128 accountId, bytes32 permission, address user) external;

  /**
   * @notice Revokes `permission` from `user` for account `accountId`.
   * @param accountId The id of the account that revoked the permission.
   * @param permission The bytes32 identifier of the permission.
   * @param user The target address that no longer has the permission.
   *
   * Requirements:
   *
   * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
   *
   * Emits a {PermissionRevoked} event.
   */
  function revokePermission(uint128 accountId, bytes32 permission, address user) external;

  /**
   * @notice Revokes `permission` from `msg.sender` for account `accountId`.
   * @param accountId The id of the account whose permission was renounced.
   * @param permission The bytes32 identifier of the permission.
   *
   * Emits a {PermissionRevoked} event.
   */
  function renouncePermission(uint128 accountId, bytes32 permission) external;

  /**
   * @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
   * @param accountId The id of the account whose permission is being queried.
   * @param permission The bytes32 identifier of the permission.
   * @param user The target address whose permission is being queried.
   * @return hasPermission A boolean with the response of the query.
   */
  function hasPermission(uint128 accountId, bytes32 permission, address user) external view returns (bool);

  /**
   * @notice Returns `true` if `target` is authorized to `permission` for account `accountId`.
   * @param accountId The id of the account whose permission is being queried.
   * @param permission The bytes32 identifier of the permission.
   * @param target The target address whose permission is being queried.
   * @return isAuthorized A boolean with the response of the query.
   */
  function isAuthorized(uint128 accountId, bytes32 permission, address target) external view returns (bool);

  /**
   * @notice Returns the address for the account token used by the module.
   * @return accountNftToken The address of the account token.
   */
  function getAccountTokenAddress() external view returns (address accountNftToken);

  /**
   * @notice Returns the address that owns a given account, as recorded by the system.
   * @param accountId The account id whose owner is being retrieved.
   * @return owner The owner of the given account id.
   */
  function getAccountOwner(uint128 accountId) external view returns (address owner);

  /**
   * @notice Returns the last unix timestamp that a permissioned action was taken with this account
   * @param accountId The account id to check
   * @return timestamp The unix timestamp of the last time a permissioned action occured with the account
   */
  function getAccountLastInteraction(uint128 accountId) external view returns (uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title Module for configuring system wide collateral.
 * @notice Allows the owner to configure collaterals at a system wide level.
 */
interface ICollateralConfigurationModule {
  struct CollateralConfiguration {
    bool depositingEnabled;
    uint256 issuanceRatioD18;
    uint256 liquidationRatioD18;
    uint256 liquidationRewardD18;
    bytes32 oracleNodeId;
    address tokenAddress;
    uint256 minDelegationD18;
  }

  /**
   * @notice Returns a list of detailed information pertaining to all collateral types registered in the system.
   * @dev Optionally returns only those that are currently enabled.
   * @param hideDisabled Wether to hide disabled collaterals or just return the full list of collaterals in the system.
   * @return collaterals The list of collateral configuration objects set in the system.
   */
  function getCollateralConfigurations(
    bool hideDisabled
  ) external view returns (CollateralConfiguration[] memory collaterals);

  /**
   * @notice Returns detailed information pertaining the specified collateral type.
   * @param collateralType The address for the collateral whose configuration is being queried.
   * @return collateral The configuration object describing the given collateral.
   */
  function getCollateralConfiguration(
    address collateralType
  ) external view returns (CollateralConfiguration memory collateral);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module for managing user collateral.
 * @notice Allows users to deposit and withdraw collateral from the system.
 */
interface ICollateralModule {
  /**
   * @notice Deposits `tokenAmount` of collateral of type `collateralType` into account `accountId`.
   * @dev Anyone can deposit into anyone's active account without restriction.
   * @param accountId The id of the account that is making the deposit.
   * @param collateralType The address of the token to be deposited.
   * @param tokenAmount The amount being deposited, denominated in the token's native decimal representation.
   *
   * Emits a {Deposited} event.
   */
  function deposit(uint128 accountId, address collateralType, uint256 tokenAmount) external;

  /**
   * @notice Withdraws `tokenAmount` of collateral of type `collateralType` from account `accountId`.
   * @param accountId The id of the account that is making the withdrawal.
   * @param collateralType The address of the token to be withdrawn.
   * @param tokenAmount The amount being withdrawn, denominated in the token's native decimal representation.
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `WITHDRAW` permission.
   *
   * Emits a {Withdrawn} event.
   *
   */
  function withdraw(uint128 accountId, address collateralType, uint256 tokenAmount) external;

  /**
   * @notice Returns the total values pertaining to account `accountId` for `collateralType`.
   * @param accountId The id of the account whose collateral is being queried.
   * @param collateralType The address of the collateral type whose amount is being queried.
   * @return totalDeposited The total collateral deposited in the account, denominated with 18 decimals of precision.
   * @return totalAssigned The amount of collateral in the account that is delegated to pools, denominated with 18 decimals of precision.
   * @return totalLocked The amount of collateral in the account that cannot currently be undelegated from a pool, denominated with 18 decimals of precision.
   */
  function getAccountCollateral(
    uint128 accountId,
    address collateralType
  ) external view returns (uint256 totalDeposited, uint256 totalAssigned, uint256 totalLocked);

  /**
   * @notice Returns the amount of collateral of type `collateralType` deposited with account `accountId` that can be withdrawn or delegated to pools.
   * @param accountId The id of the account whose collateral is being queried.
   * @param collateralType The address of the collateral type whose amount is being queried.
   * @return amountD18 The amount of collateral that is available for withdrawal or delegation, denominated with 18 decimals of precision.
   */
  function getAccountAvailableCollateral(
    uint128 accountId,
    address collateralType
  ) external view returns (uint256 amountD18);

  /**
   * @notice Clean expired locks from locked collateral arrays for an account/collateral type. It includes offset and items to prevent gas exhaustion. If both, offset and items, are 0 it will traverse the whole array (unlimited).
   * @param accountId The id of the account whose locks are being cleared.
   * @param collateralType The address of the collateral type to clean locks for.
   * @param offset The index of the first lock to clear.
   * @param count The number of slots to check for cleaning locks. Set to 0 to clean all locks at/after offset
   * @return cleared the number of locks that were actually expired (and therefore cleared)
   */
  function cleanExpiredLocks(
    uint128 accountId,
    address collateralType,
    uint256 offset,
    uint256 count
  ) external returns (uint256 cleared);

  /**
   * @notice Create a new lock on the given account. you must have `admin` permission on the specified account to create a lock.
   * @dev Collateral can be withdrawn from the system if it is not assigned or delegated to a pool. Collateral locks are an additional restriction that applies on top of that. I.e. if collateral is not assigned to a pool, but has a lock, it cannot be withdrawn.
   * @dev Collateral locks are initially intended for the Synthetix v2 to v3 migration, but may be used in the future by the Spartan Council, for example, to create and hand off accounts whose withdrawals from the system are locked for a given amount of time.
   * @param accountId The id of the account for which a lock is to be created.
   * @param collateralType The address of the collateral type for which the lock will be created.
   * @param amount The amount of collateral tokens to wrap in the lock being created, denominated with 18 decimals of precision.
   * @param expireTimestamp The date in which the lock will become clearable.
   */
  function createLock(uint128 accountId, address collateralType, uint256 amount, uint64 expireTimestamp) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module for the minting and burning of stablecoins.
 */
interface IIssueUSDModule {
  /**
   * @notice Mints {amount} of snxUSD with the specified liquidity position.
   * @param accountId The id of the account that is minting snxUSD.
   * @param poolId The id of the pool whose collateral will be used to back up the mint.
   * @param collateralType The address of the collateral that will be used to back up the mint.
   * @param amount The amount of snxUSD to be minted, denominated with 18 decimals of precision.
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `MINT` permission.
   * - After minting, the collateralization ratio of the liquidity position must not be below the target collateralization ratio for the corresponding collateral type.
   *
   * Emits a {UsdMinted} event.
   */
  function mintUsd(uint128 accountId, uint128 poolId, address collateralType, uint256 amount) external;

  /**
   * @notice Burns {amount} of snxUSD with the specified liquidity position.
   * @param accountId The id of the account that is burning snxUSD.
   * @param poolId The id of the pool whose collateral was used to back up the snxUSD.
   * @param collateralType The address of the collateral that was used to back up the snxUSD.
   * @param amount The amount of snxUSD to be burnt, denominated with 18 decimals of precision.
   *
   * Emits a {UsdMinted} event.
   */
  function burnUsd(uint128 accountId, uint128 poolId, address collateralType, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module that allows the system owner to mark official pools.
 */
interface IPoolConfigurationModule {
  /**
   * @notice Retrieves the unique system preferred pool.
   * @return poolId The id of the pool that is currently set as preferred in the system.
   */
  function getPreferredPool() external view returns (uint128 poolId);

  /**
   * @notice Retrieves the pool that are approved by the system owner.
   * @return poolIds An array with all of the pool ids that are approved in the system.
   */
  function getApprovedPools() external view returns (uint256[] calldata poolIds);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @title Interface a reward distributor.
interface IRewardDistributor {
  /// @notice Address to ERC-20 token distributed by this distributor, for display purposes only
  /// @dev Return address(0) if providing non ERC-20 rewards
  function token() external view returns (address);

  function precision() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Module for connecting rewards distributors to vaults.
 */
interface IRewardsManagerModule {
  /**
   * @notice Allows a user with appropriate permissions to claim rewards associated with a position.
   * @param accountId The id of the account that is to claim the rewards.
   * @param poolId The id of the pool to claim rewards on.
   * @param collateralType The address of the collateral used in the pool's rewards.
   * @param distributor The address of the rewards distributor associated with the rewards being claimed.
   * @return amountClaimedD18 The amount of rewards that were available for the account and thus claimed.
   */
  function claimRewards(
    uint128 accountId,
    uint128 poolId,
    address collateralType,
    address distributor
  ) external returns (uint256 amountClaimedD18);

  /**
   * @notice Returns the amount of claimable rewards for a given accountId for a vault distributor.
   * @param accountId The id of the account to look up rewards on.
   * @param poolId The id of the pool to claim rewards on.
   * @param collateralType The address of the collateral used in the pool's rewards.
   * @param distributor The address of the rewards distributor associated with the rewards being claimed.
   * @return rewardAmount The amount of available rewards that are available for the provided account.
   */
  function getAvailableRewards(
    uint128 accountId,
    uint128 poolId,
    address collateralType,
    address distributor
  ) external view returns (uint256 rewardAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title Allows accounts to delegate collateral to a pool.
 * @dev Delegation updates the account's position in the vault that corresponds to the associated pool and collateral type pair.
 * @dev A pool contains one vault for each collateral type it supports, and vaults are not shared between pools.
 */
interface IVaultModule {
  /**
   * @notice Updates an account's delegated collateral amount for the specified pool and collateral type pair.
   * @param accountId The id of the account associated with the position that will be updated.
   * @param poolId The id of the pool associated with the position.
   * @param collateralType The address of the collateral used in the position.
   * @param amount The new amount of collateral delegated in the position, denominated with 18 decimals of precision.
   * @param leverage The new leverage amount used in the position, denominated with 18 decimals of precision.
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the account, have the `ADMIN` permission, or have the `DELEGATE` permission.
   * - If increasing the amount delegated, it must not exceed the available collateral (`getAccountAvailableCollateral`) associated with the account.
   * - If decreasing the amount delegated, the liquidity position must have a collateralization ratio greater than the target collateralization ratio for the corresponding collateral type.
   *
   * Emits a {DelegationUpdated} event.
   */
  function delegateCollateral(
    uint128 accountId,
    uint128 poolId,
    address collateralType,
    uint256 amount,
    uint256 leverage
  ) external;

  /**
   * @notice Returns the collateralization ratio of the specified liquidity position. If debt is negative, this function will return 0.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev The return value is a percentage with 18 decimals places.
   * @param accountId The id of the account whose collateralization ratio is being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return ratioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
   */
  function getPositionCollateralRatio(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  ) external returns (uint256 ratioD18);

  /**
   * @notice Returns the debt of the specified liquidity position. Credit is expressed as negative debt.
   * @dev This is not a view function, and actually updates the entire debt distribution chain.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return debtD18 The amount of debt held by the position, denominated with 18 decimals of precision.
   */
  function getPositionDebt(uint128 accountId, uint128 poolId, address collateralType) external returns (int256 debtD18);

  /**
   * @notice Returns the amount and value of the collateral associated with the specified liquidity position.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev collateralAmount is represented as an integer with 18 decimals.
   * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
   * @return collateralValueD18 The value of collateral used in the position, denominated with 18 decimals of precision.
   */
  function getPositionCollateral(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  ) external view returns (uint256 collateralAmountD18, uint256 collateralValueD18);

  /**
   * @notice Returns all information pertaining to a specified liquidity position in the vault module.
   * @param accountId The id of the account being queried.
   * @param poolId The id of the pool in which the account's position is held.
   * @param collateralType The address of the collateral used in the queried position.
   * @return collateralAmountD18 The amount of collateral used in the position, denominated with 18 decimals of precision.
   * @return collateralValueD18 The value of the collateral used in the position, denominated with 18 decimals of precision.
   * @return debtD18 The amount of debt held in the position, denominated with 18 decimals of precision.
   * @return collateralizationRatioD18 The collateralization ratio of the position (collateral / debt), denominated with 18 decimals of precision.
   **/
  function getPosition(
    uint128 accountId,
    uint128 poolId,
    address collateralType
  )
    external
    returns (
      uint256 collateralAmountD18,
      uint256 collateralValueD18,
      int256 debtD18,
      uint256 collateralizationRatioD18
    );

  /**
   * @notice Returns the total debt (or credit) that the vault is responsible for. Credit is expressed as negative debt.
   * @dev This is not a view function, and actually updates the entire debt distribution chain.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @param poolId The id of the pool that owns the vault whose debt is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return debtD18 The overall debt of the vault, denominated with 18 decimals of precision.
   **/
  function getVaultDebt(uint128 poolId, address collateralType) external returns (int256 debtD18);

  /**
   * @notice Returns the amount and value of the collateral held by the vault.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev collateralAmount is represented as an integer with 18 decimals.
   * @dev collateralValue is represented as an integer with the number of decimals specified by the collateralType.
   * @param poolId The id of the pool that owns the vault whose collateral is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return collateralAmountD18 The collateral amount of the vault, denominated with 18 decimals of precision.
   * @return collateralValueD18 The collateral value of the vault, denominated with 18 decimals of precision.
   */
  function getVaultCollateral(
    uint128 poolId,
    address collateralType
  ) external returns (uint256 collateralAmountD18, uint256 collateralValueD18);

  /**
   * @notice Returns the collateralization ratio of the vault. If debt is negative, this function will return 0.
   * @dev Call this function using `callStatic` to treat it as a view function.
   * @dev The return value is a percentage with 18 decimals places.
   * @param poolId The id of the pool that owns the vault whose collateralization ratio is being queried.
   * @param collateralType The address of the collateral of the associated vault.
   * @return ratioD18 The collateralization ratio of the vault, denominated with 18 decimals of precision.
   */
  function getVaultCollateralRatio(uint128 poolId, address collateralType) external returns (uint256 ratioD18);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/* https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol */
library DateTime {
  uint256 public constant SECONDS_PER_HOUR = 60 * 60;
  uint256 public constant SECONDS_PER_DAY = SECONDS_PER_HOUR * 24;
  int256 public constant OFFSET19700101 = 2440588;

  /// @notice 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  /// @notice 0...23
  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  /// @notice 1 = Monday, 7 = Sunday
  function validateDayOfWeek(uint8 dayOfWeek) internal pure {
    require(dayOfWeek > 0 && dayOfWeek < 8, "invalid day of week");
  }

  /// @notice 0...23
  function validateHour(uint8 hour) internal pure {
    require(hour < 24, "invalid hour");
  }

  function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
    require(year >= 1970, "1970 and later only");
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IERC20Extended} from "../interfaces/IERC20Extended.sol";

library PrecisionHelper {
  function getPrecisionForConversion(address _token) internal view returns (uint256 precision) {
    precision = 10 ** (18 - (IERC20Extended(_token).decimals()));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library SynthetixV3Structs {
  struct VaultSetting {
    address poolLogic;
    address collateralAsset;
    address debtAsset;
    uint128 snxLiquidityPoolId;
  }

  /// @dev Couldn't find a way to get a mapping from synthAddress to its markedId, so storing it in guard's storage
  /// @dev Was looking for something like getSynth() but reversed
  struct AllowedMarket {
    uint128 marketId;
    address collateralSynth;
    address collateralAsset;
  }

  struct TimePeriod {
    uint8 dayOfWeek;
    uint8 hour;
  }

  struct Window {
    TimePeriod start;
    TimePeriod end;
  }

  struct WeeklyWindows {
    Window delegationWindow;
    Window undelegationWindow;
  }

  struct WeeklyWithdrawalLimit {
    uint256 usdValue;
    uint256 percent;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";
import "../../../utils/DateTime.sol";

library WeeklyWindowsHelper {
  using DateTime for uint8;
  using DateTime for uint256;

  /// @notice Helper function to check if the timestamp is within allowed window
  /// @param _window Window of interest
  /// @param _timestamp Timestamp of interest
  /// @return isWithinAllowedWindow If the timestamp is within allowed window
  function isWithinAllowedWindow(
    SynthetixV3Structs.Window calldata _window,
    uint256 _timestamp
  ) external pure returns (bool) {
    uint256 currentDayOfWeek = _timestamp.getDayOfWeek();
    uint256 currentHour = _timestamp.getHour();

    if (currentDayOfWeek < _window.start.dayOfWeek || currentDayOfWeek > _window.end.dayOfWeek) {
      return false;
    }

    if (currentDayOfWeek == _window.start.dayOfWeek && currentHour < _window.start.hour) {
      return false;
    }

    if (currentDayOfWeek == _window.end.dayOfWeek && currentHour > _window.end.hour) {
      return false;
    }

    return true;
  }

  /// @notice Helper function to validate windows
  /// @param _windows Windows of interest
  function validateWindows(SynthetixV3Structs.WeeklyWindows memory _windows) external pure {
    _validateWindow(_windows.delegationWindow);
    _validateWindow(_windows.undelegationWindow);
  }

  /// @notice Helper function to validate window
  /// @param _window Window of interest
  function _validateWindow(SynthetixV3Structs.Window memory _window) internal pure {
    _validateTimePeriod(_window.start);
    _validateTimePeriod(_window.end);
  }

  /// @notice Helper function to validate time period
  /// @param _timePeriod Time period of interest
  function _validateTimePeriod(SynthetixV3Structs.TimePeriod memory _timePeriod) internal pure {
    _timePeriod.dayOfWeek.validateDayOfWeek();
    _timePeriod.hour.validateHour();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IHasGuardInfo.sol";

contract DhedgeNftTrackerStorage is OwnableUpgradeable {
  address public poolFactory; // dhedge pool factory
  mapping(bytes32 => mapping(address => bytes[])) internal _nftTrackData; // keccak of NFT_TYPE -> poolAddress -> data[]

  // solhint-disable-next-line no-empty-blocks
  function initialize(address _poolFactory) external initializer {
    __Ownable_init();
    poolFactory = _poolFactory;
  }

  modifier checkContractGuard(address _guardedContract) {
    require(IHasGuardInfo(poolFactory).getContractGuard(_guardedContract) == msg.sender, "not correct contract guard");

    _;
  }

  /**
   * @notice record new NFT data
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _data the nft track data to be recorded in storage
   */
  function addData(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    bytes memory _data
  ) external checkContractGuard(_guardedContract) {
    _addData(_nftType, _pool, _data);
  }

  /**
   * @notice record new NFT data
   * @dev only called by authorized guard
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _data the nft track data to be recorded in storage
   */
  function _addData(bytes32 _nftType, address _pool, bytes memory _data) private {
    _nftTrackData[_nftType][_pool].push(_data);
  }

  /**
   * @notice delete NFT data
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the nft track data index to be removed from storage
   */
  function removeData(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external checkContractGuard(_guardedContract) {
    _removeData(_nftType, _pool, _index);
  }

  /**
   * @notice delete NFT data
   * @dev only called by authorized guard
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the nft track data index to be removed from storage
   */
  function _removeData(bytes32 _nftType, address _pool, uint256 _index) private {
    uint256 length = _nftTrackData[_nftType][_pool].length;
    require(_index < length, "invalid index");

    _nftTrackData[_nftType][_pool][_index] = _nftTrackData[_nftType][_pool][length - 1];
    _nftTrackData[_nftType][_pool].pop();
  }

  /**
   * @notice returns tracked nft by index
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the index of nft track data
   * @return data the nft track data of given NFT_TYPE & poolLogic & index
   */
  function getData(bytes32 _nftType, address _pool, uint256 _index) external view returns (bytes memory) {
    return _nftTrackData[_nftType][_pool][_index];
  }

  /**
   * @notice returns all tracked nfts by NFT_TYPE & poolLogic
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return data all tracked nfts of given NFT_TYPE & poolLogic
   */
  function getAllData(bytes32 _nftType, address _pool) public view returns (bytes[] memory) {
    return _nftTrackData[_nftType][_pool];
  }

  /**
   * @notice returns all tracked nfts by NFT_TYPE & poolLogic
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return count all tracked nfts count of given NFT_TYPE & poolLogic
   */
  function getDataCount(bytes32 _nftType, address _pool) public view returns (uint256) {
    return _nftTrackData[_nftType][_pool].length;
  }

  /**
   * @notice returns all tracked nft ids by NFT_TYPE & poolLogic if stored as uint256
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return tokenIds all tracked nfts of given NFT_TYPE & poolLogic
   */
  function getAllUintIds(bytes32 _nftType, address _pool) public view returns (uint256[] memory tokenIds) {
    bytes[] memory data = getAllData(_nftType, _pool);
    tokenIds = new uint256[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      tokenIds[i] = abi.decode(data[i], (uint256));
    }
  }

  /**
   * @notice record new NFT uint256 id
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _nftID the nft id recorded in storage
   */
  function addUintId(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _nftID,
    uint256 _maxPositions
  ) external checkContractGuard(_guardedContract) {
    _addData(_nftType, _pool, abi.encode(_nftID));
    require(getDataCount(_nftType, _pool) <= _maxPositions, "max position reached");
  }

  /**
   * @notice record new NFT uint256 id
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _nftID the nft id recorded in storage
   */
  function removeUintId(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external checkContractGuard(_guardedContract) {
    bytes[] memory data = getAllData(_nftType, _pool);
    for (uint256 i = 0; i < data.length; i++) {
      if (abi.decode(data[i], (uint256)) == _nftID) {
        _removeData(_nftType, _pool, i);
        return;
      }
    }

    revert("not found");
  }

  function removeDataByUintId(bytes32 _nftType, address _pool, uint256 _nftID) external onlyOwner {
    bytes[] memory data = getAllData(_nftType, _pool);
    for (uint256 i = 0; i < data.length; i++) {
      if (abi.decode(data[i], (uint256)) == _nftID) {
        _removeData(_nftType, _pool, i);
        return;
      }
    }
    revert("not found");
  }

  function removeDataByIndex(bytes32 _nftType, address _pool, uint256 _index) external onlyOwner {
    _removeData(_nftType, _pool, _index);
  }

  function addDataByUintId(bytes32 _nftType, address _pool, uint256 _nftID) external onlyOwner {
    _addData(_nftType, _pool, abi.encode(_nftID));
  }
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@uniswap/v3-periphery/contracts/libraries/BytesLib.sol";

contract TxDataUtils {
  using BytesLib for bytes;
  using SafeMathUpgradeable for uint256;

  function getMethod(bytes memory data) public pure returns (bytes4) {
    return read4left(data, 0);
  }

  function getParams(bytes memory data) public pure returns (bytes memory) {
    return data.slice(4, data.length - 4);
  }

  function getInput(bytes memory data, uint8 inputNum) public pure returns (bytes32) {
    return read32(data, 32 * inputNum + 4, 32);
  }

  function getBytes(bytes memory data, uint8 inputNum, uint256 offset) public pure returns (bytes memory) {
    require(offset < 20, "invalid offset"); // offset is in byte32 slots, not bytes
    offset = offset * 32; // convert offset to bytes
    uint256 bytesLenPos = uint256(read32(data, 32 * inputNum + 4 + offset, 32));
    uint256 bytesLen = uint256(read32(data, bytesLenPos + 4 + offset, 32));
    return data.slice(bytesLenPos + 4 + offset + 32, bytesLen);
  }

  function getArrayLast(bytes memory data, uint8 inputNum) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);
    require(arrayLen > 0, "input is not array");
    return read32(data, uint256(arrayPos) + 4 + (uint256(arrayLen) * 32), 32);
  }

  function getArrayLength(bytes memory data, uint8 inputNum) public pure returns (uint256) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    return uint256(read32(data, uint256(arrayPos) + 4, 32));
  }

  function getArrayIndex(bytes memory data, uint8 inputNum, uint8 arrayIndex) public pure returns (bytes32) {
    bytes32 arrayPos = read32(data, 32 * inputNum + 4, 32);
    bytes32 arrayLen = read32(data, uint256(arrayPos) + 4, 32);
    require(arrayLen > 0, "input is not array");
    require(uint256(arrayLen) > arrayIndex, "invalid array position");
    return read32(data, uint256(arrayPos) + 4 + ((1 + uint256(arrayIndex)) * 32), 32);
  }

  function read4left(bytes memory data, uint256 offset) public pure returns (bytes4 o) {
    require(data.length >= offset + 4, "Reading bytes out of bounds");
    assembly {
      o := mload(add(data, add(32, offset)))
    }
  }

  function read32(bytes memory data, uint256 offset, uint256 length) public pure returns (bytes32 o) {
    require(data.length >= offset + length, "Reading bytes out of bounds");
    assembly {
      o := mload(add(data, add(32, offset)))
      let lb := sub(32, length)
      if lb {
        o := div(o, exp(2, mul(lb, 8)))
      }
    }
  }

  function convert32toAddress(bytes32 data) public pure returns (address o) {
    return address(uint160(uint256(data)));
  }

  function sliceUint(bytes memory data, uint256 start) internal pure returns (uint256) {
    require(data.length >= start + 32, "slicing out of range");
    uint256 x;
    assembly {
      x := mload(add(data, add(0x20, start)))
    }
    return x;
  }
}