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

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/guards/IGuard.sol";

// This should be the base for all AssetGuards that are not ERC20 or are ERC20 but should not be transferrable
abstract contract ClosedAssetGuard is TxDataUtils, IGuard, IAssetGuard {
  /// @notice Doesn't allow any transactions uses separate contract guard that should be migrated here
  /// @dev Parses the manager transaction data to ensure transaction is valid
  /// @return txType transaction type described in PoolLogic
  /// @return isPublic if the transaction is public or private
  function txGuard(
    address,
    address,
    bytes calldata
  )
    external
    pure
    virtual
    override
    returns (
      uint16 txType, // transaction type
      bool // isPublic
    )
  {
    return (txType, false);
  }

  /// @notice Returns the balance of the managed asset
  /// @dev May include any external balance in staking contracts
  /// @return balance The asset balance of given pool for the given asset
  function getBalance(address, address) public view virtual override returns (uint256) {
    revert("not implemented");
  }

  /// @notice Necessary check for remove asset
  /// @param pool Address of the pool
  /// @param asset Address of the remove asset
  function removeAssetCheck(address pool, address asset) public view virtual override {
    uint256 balance = getBalance(pool, asset);
    require(balance == 0, "cannot remove non-empty asset");
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/guards/IGuard.sol";
import "../../interfaces/IERC20Extended.sol"; // includes decimals()
import "../../interfaces/IPoolManagerLogic.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasGuardInfo.sol";
import "../../interfaces/IManaged.sol";

/// @title Generic ERC20 asset guard
/// @dev Asset type = 0
/// @dev A generic ERC20 guard asset is Not stakeable ie. no 'getWithdrawStakedTx()' function
contract ERC20Guard is TxDataUtils, IGuard, IAssetGuard {
  using SafeMathUpgradeable for uint256;

  event Approve(address fundAddress, address manager, address spender, uint256 amount, uint256 time);

  /// @notice Transaction guard for approving assets
  /// @dev Parses the manager transaction data to ensure transaction is valid
  /// @param _poolManagerLogic Pool address
  /// @param data Transaction call data attempt by manager
  /// @return txType transaction type described in PoolLogic
  /// @return isPublic if the transaction is public or private
  function txGuard(
    address _poolManagerLogic,
    address, // to
    bytes calldata data
  )
    external
    override
    returns (
      uint16 txType, // transaction type
      bool // isPublic
    )
  {
    bytes4 method = getMethod(data);

    if (method == bytes4(keccak256("approve(address,uint256)"))) {
      address spender = convert32toAddress(getInput(data, 0));
      uint256 amount = uint256(getInput(data, 1));

      IPoolManagerLogic poolManagerLogic = IPoolManagerLogic(_poolManagerLogic);

      address factory = poolManagerLogic.factory();
      address spenderGuard = IHasGuardInfo(factory).getContractGuard(spender);
      require(spenderGuard != address(0) && spenderGuard != address(this), "unsupported spender approval"); // checks that the spender is an approved address

      emit Approve(
        poolManagerLogic.poolLogic(),
        IManaged(_poolManagerLogic).manager(),
        spender,
        amount,
        block.timestamp
      );

      txType = 1; // 'Approve' type
    }

    return (txType, false);
  }

  /// @notice Creates transaction data for withdrawing tokens
  /// @dev Withdrawal processing is not applicable for this guard
  /// @return withdrawAsset and
  /// @return withdrawBalance are used to withdraw portion of asset balance to investor
  /// @return transactions is used to execute the withdrawal transaction in PoolLogic
  function withdrawProcessing(
    address pool,
    address asset,
    uint256 portion,
    address // to
  )
    external
    virtual
    override
    returns (
      address withdrawAsset,
      uint256 withdrawBalance,
      MultiTransaction[] memory transactions
    )
  {
    withdrawAsset = asset;
    uint256 totalAssetBalance = getBalance(pool, asset);
    withdrawBalance = totalAssetBalance.mul(portion).div(10**18);
    return (withdrawAsset, withdrawBalance, transactions);
  }

  /// @notice Returns the balance of the managed asset
  /// @dev May include any external balance in staking contracts
  /// @return balance The asset balance of given pool
  function getBalance(address pool, address asset) public view virtual override returns (uint256 balance) {
    // The base ERC20 guard has no externally staked tokens
    balance = IERC20(asset).balanceOf(pool);
  }

  /// @notice Returns the decimal of the managed asset
  /// @param asset Address of the managed asset
  /// @return decimals The decimal of given asset
  function getDecimals(address asset) external view virtual override returns (uint256 decimals) {
    decimals = IERC20Extended(asset).decimals();
  }

  /// @notice Necessary check for remove asset
  /// @param pool Address of the pool
  /// @param asset Address of the remove asset
  function removeAssetCheck(address pool, address asset) public view virtual override {
    uint256 balance = getBalance(pool, asset);
    require(balance == 0, "cannot remove non-empty asset");
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ClosedAssetGuard.sol";
import "../contractGuards/LyraOptionMarketWrapperContractGuard.sol";
import "../../utils/lyra/DhedgeOptionMarketWrapperForLyra.sol";
import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/lyra/IOptionMarketViewer.sol";
import "../../interfaces/lyra/IOptionGreekCache.sol";
import "../../interfaces/lyra/ISynthetixAdapter.sol";
import "../../interfaces/lyra/ILiquidityPool.sol";
import "../../interfaces/lyra/IOptionMarket.sol";

/// @title Lyra OptionMarketWrapper asset guard
/// @dev Asset type = 100
contract LyraOptionMarketWrapperAssetGuard is ClosedAssetGuard {
  using SafeMath for uint256;

  DhedgeOptionMarketWrapperForLyra public immutable dhedgeLyraWrapper;
  uint256 public constant PRICE_GWAV_DURATION = 10 minutes;
  uint256 public constant CHECK_GWAV_DURATION = 6 hours;
  uint256 public constant GWAV_DIVERGENCE_CB_AMOUNT_DENOMINATOR = 1000;
  // 5%
  uint256 public constant GWAV_DIVERGENCE_CB_AMOUNT_NUMERATOR = (GWAV_DIVERGENCE_CB_AMOUNT_DENOMINATOR / 100) * 5;

  constructor(DhedgeOptionMarketWrapperForLyra _dhedgeLyraWrapper) {
    dhedgeLyraWrapper = _dhedgeLyraWrapper;
  }

  function marketViewer() public view returns (IOptionMarketViewer) {
    return dhedgeLyraWrapper.getOptionMarketViewer();
  }

  function getGWAVCallPrice(address optionMarket, uint256 strikeId) public view returns (uint256 callPrice) {
    ILyraRegistry.OptionMarketAddresses memory c = dhedgeLyraWrapper.lyraRegistry().getMarketAddresses(optionMarket);

    (callPrice, ) = IGWAVOracle(c.gwavOracle).optionPriceGWAV(strikeId, PRICE_GWAV_DURATION);
    (uint256 checkCallPrice, ) = IGWAVOracle(c.gwavOracle).optionPriceGWAV(strikeId, CHECK_GWAV_DURATION);

    assertNoGWAVDivergence(callPrice, checkCallPrice);
  }

  function getGWAVPutPrice(address optionMarket, uint256 strikeId) public view returns (uint256 putPrice) {
    ILyraRegistry.OptionMarketAddresses memory c = dhedgeLyraWrapper.lyraRegistry().getMarketAddresses(optionMarket);

    (, putPrice) = IGWAVOracle(c.gwavOracle).optionPriceGWAV(strikeId, PRICE_GWAV_DURATION);
    (, uint256 checkPutPrice) = IGWAVOracle(c.gwavOracle).optionPriceGWAV(strikeId, CHECK_GWAV_DURATION);

    assertNoGWAVDivergence(putPrice, checkPutPrice);
  }

  function assertNoGWAVDivergence(uint256 price1, uint256 price2) public pure {
    uint256 difference = price1 > price2 ? price1 - price2 : price2 - price1;
    uint256 acceptableDifference = price1.mul(GWAV_DIVERGENCE_CB_AMOUNT_NUMERATOR).div(
      GWAV_DIVERGENCE_CB_AMOUNT_DENOMINATOR
    );
    require(difference <= acceptableDifference, "gwav divergence too high");
  }

  /// @notice Creates transaction data for withdrawing staked tokens
  /// @dev The same interface can be used for other types of stakeable tokens
  /// @param pool Pool address
  /// @param asset lyra option market wrapper contract address
  /// @param portion The fraction of total staked asset to withdraw
  /// @return withdrawAsset and
  /// @return withdrawBalance are used to withdraw portion of asset balance to investor
  /// @return transactions is used to execute the staked withdrawal transaction in PoolLogic
  function withdrawProcessing(
    address pool,
    address asset,
    uint256 portion,
    address to
  )
    external
    virtual
    override
    returns (
      address withdrawAsset,
      uint256 withdrawBalance,
      MultiTransaction[] memory transactions
    )
  {
    // settle expired positions
    address lyraOptionMarketWrapperContractGuard = IHasGuardInfo(IPoolLogic(pool).factory()).getContractGuard(asset);
    LyraOptionMarketWrapperContractGuard(lyraOptionMarketWrapperContractGuard).settleExpiredAndFilterActivePositions(
      pool
    );

    // get active positions
    LyraOptionMarketWrapperContractGuard.OptionPosition[] memory positions = LyraOptionMarketWrapperContractGuard(
      lyraOptionMarketWrapperContractGuard
    ).getOptionPositions(pool);

    // create the transactions array
    transactions = new MultiTransaction[](positions.length * 2);
    uint256 txCount;
    for (uint256 i = 0; i < positions.length; i++) {
      // Transfer the Option NFT ownership to the wrapper contract.
      // We need to do this because before we call `forceClose` on a position we don't know exactly how much the withdrawer will receive back.
      IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
        positions[i].optionMarket
      );
      transactions[txCount].to = address(optionMarketAddresses.optionToken);
      transactions[txCount].txData = abi.encodeWithSelector(
        IERC721.transferFrom.selector,
        pool,
        dhedgeLyraWrapper,
        positions[i].positionId
      );
      txCount++;

      // DhedgeOptionMarketWrapperForLyra will return the nft after forceClosing the withdrawers portion
      transactions[txCount].to = address(dhedgeLyraWrapper);
      transactions[txCount].txData = abi.encodeWithSelector(
        DhedgeOptionMarketWrapperForLyra.tryCloseAndForceClosePosition.selector,
        positions[i],
        portion,
        to // recipient
      );
      txCount++;
    }

    return (withdrawAsset, withdrawBalance, transactions);
  }

  /// @notice Returns decimal of the Lyra option market asset
  /// @dev Returns decimal 18
  function getDecimals(address) external pure override returns (uint256 decimals) {
    decimals = 18;
  }

  /// @notice Returns the balance of the managed asset
  /// @dev May include any external balance in staking contracts
  /// @param pool address of the pool
  /// @param asset lyra option market wrapper contract address
  /// @return balance The asset balance of given pool
  function getBalance(address pool, address asset) public view override returns (uint256 balance) {
    address factory = IPoolLogic(pool).factory();
    address lyraContractGuard = IHasGuardInfo(factory).getContractGuard(asset);

    LyraOptionMarketWrapperContractGuard.OptionPosition[] memory positions = LyraOptionMarketWrapperContractGuard(
      lyraContractGuard
    ).getOptionPositions(pool);

    for (uint256 i = 0; i < positions.length; i++) {
      IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
        positions[i].optionMarket
      );

      IOptionToken.OptionPosition memory position = IOptionToken(optionMarketAddresses.optionToken).positions(
        positions[i].positionId
      );

      if (position.state == IOptionToken.PositionState.ACTIVE) {
        uint256 basePrice = dhedgeLyraWrapper.getSynthetixAdapter().getSpotPriceForMarket(positions[i].optionMarket);
        (uint256 strikePrice, uint256 priceAtExpiry, uint256 ammShortCallBaseProfitRatio) = IOptionMarket(
          positions[i].optionMarket
        ).getSettlementParameters(position.strikeId);

        uint256 marketValue;
        if (priceAtExpiry != 0) {
          // option is expired
          if (position.optionType == IOptionMarket.OptionType.LONG_CALL) {
            marketValue = (priceAtExpiry > strikePrice)
              ? position.amount.mul(priceAtExpiry.sub(strikePrice)).div(1e18)
              : 0;
          } else if (position.optionType == IOptionMarket.OptionType.LONG_PUT) {
            marketValue = (strikePrice > priceAtExpiry)
              ? position.amount.mul(strikePrice.sub(priceAtExpiry)).div(1e18)
              : 0;
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_CALL_BASE) {
            uint256 ammProfit = position.amount.mul(ammShortCallBaseProfitRatio).div(1e18);
            marketValue = position.collateral > ammProfit
              ? (position.collateral.sub(ammProfit)).mul(basePrice).div(1e18)
              : 0;
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_CALL_QUOTE) {
            uint256 ammProfit = (priceAtExpiry > strikePrice)
              ? position.amount.mul(priceAtExpiry.sub(strikePrice)).div(1e18)
              : 0;
            marketValue = position.collateral > ammProfit ? position.collateral.sub(ammProfit) : 0;
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_PUT_QUOTE) {
            uint256 ammProfit = (strikePrice > priceAtExpiry)
              ? position.amount.mul(strikePrice.sub(priceAtExpiry)).div(1e18)
              : 0;
            marketValue = position.collateral > ammProfit ? position.collateral.sub(ammProfit) : 0;
          } else {
            revert("invalid option type");
          }
        } else {
          if (position.optionType == IOptionMarket.OptionType.LONG_CALL) {
            // position.amount.multiplyDecimal(callPrice)
            marketValue = position.amount.mul(getGWAVCallPrice(positions[i].optionMarket, position.strikeId)).div(1e18);
          } else if (position.optionType == IOptionMarket.OptionType.LONG_PUT) {
            // position.amount.multiplyDecimal(putPrice)
            marketValue = position.amount.mul(getGWAVPutPrice(positions[i].optionMarket, position.strikeId)).div(1e18);
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_CALL_BASE) {
            // position.collateral.multiplyDecimal(basePrice) - position.amount.multiplyDecimal(callPrice)
            uint256 collateralValue = position.collateral.mul(basePrice).div(1e18);
            uint256 callValue = position.amount.mul(getGWAVCallPrice(positions[i].optionMarket, position.strikeId)).div(
              1e18
            );
            marketValue = collateralValue > callValue ? collateralValue.sub(callValue) : 0;
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_CALL_QUOTE) {
            // position.collateral - position.amount.multiplyDecimal(callPrice)
            uint256 collateralValue = position.collateral;
            uint256 callValue = position.amount.mul(getGWAVCallPrice(positions[i].optionMarket, position.strikeId)).div(
              1e18
            );
            marketValue = collateralValue > callValue ? collateralValue.sub(callValue) : 0;
          } else if (position.optionType == IOptionMarket.OptionType.SHORT_PUT_QUOTE) {
            // position.collateral - position.amount.multiplyDecimal(putPrice)
            uint256 collateralValue = position.collateral;
            uint256 putValue = position.amount.mul(getGWAVPutPrice(positions[i].optionMarket, position.strikeId)).div(
              1e18
            );
            marketValue = collateralValue > putValue ? collateralValue.sub(putValue) : 0;
          } else {
            revert("invalid option type");
          }
        }
        balance = balance.add(marketValue);
      }
    }
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../ERC20Guard.sol";
import "../../../interfaces/velodrome/IVelodromePair.sol";
import "../../../interfaces/velodrome/IVelodromeGauge.sol";
import "../../../interfaces/velodrome/IVelodromeVoter.sol";
import "../../../interfaces/IHasAssetInfo.sol";
import "../../../interfaces/IPoolLogic.sol";

/// @title Velodrome LP token asset guard
/// @dev Asset type = 15
contract VelodromeLPAssetGuard is ERC20Guard {
  using SafeMathUpgradeable for uint256;

  IVelodromeVoter public voter;

  constructor(address _voter) {
    voter = IVelodromeVoter(_voter);
  }

  /// @notice Creates transaction data for withdrawing Velodrome LP tokens
  /// @dev The same interface can be used for other types of stakeable tokens
  /// @param pool Pool address
  /// @param asset Velodrome LP asset
  /// @param portion The fraction of total Velodrome LP asset to withdraw
  /// @param to The investor address to withdraw to
  /// @return withdrawAsset and
  /// @return withdrawBalance are used to withdraw portion of asset balance to investor
  /// @return transactions is used to execute the Velodrome LP withdrawal transaction in PoolLogic
  function withdrawProcessing(
    address pool,
    address asset,
    uint256 portion,
    address to
  )
    external
    view
    virtual
    override
    returns (
      address withdrawAsset,
      uint256 withdrawBalance,
      MultiTransaction[] memory transactions
    )
  {
    withdrawAsset = asset;
    withdrawBalance = IERC20(asset).balanceOf(pool).mul(portion).div(10**18);

    IVelodromeGauge gauge = IVelodromeGauge(voter.gauges(asset));
    uint256 rewardsListLength = address(gauge) == address(0) ? 0 : gauge.rewardsListLength();

    uint256 txCount = 0;
    transactions = new MultiTransaction[](5 + rewardsListLength);

    // up-to 3 transactions for LP withdraw processing
    {
      uint256 feeAmount0 = IVelodromePair(asset).claimable0(pool);
      uint256 feeAmount1 = IVelodromePair(asset).claimable1(pool);
      if (feeAmount0 > 0 || feeAmount1 > 0) {
        transactions[txCount].to = asset;
        transactions[txCount].txData = abi.encodeWithSelector(bytes4(keccak256("claimFees()")));
        txCount = txCount.add(1);

        // withdraw claimable fees directly to the user
        if (feeAmount0 > 0) {
          transactions[txCount].to = IVelodromePair(asset).token0();
          transactions[txCount].txData = abi.encodeWithSelector(
            bytes4(keccak256("transfer(address,uint256)")),
            to,
            feeAmount0.mul(portion).div(10**18)
          );
          txCount = txCount.add(1);
        }
        if (feeAmount1 > 0) {
          transactions[txCount].to = IVelodromePair(asset).token1();
          transactions[txCount].txData = abi.encodeWithSelector(
            bytes4(keccak256("transfer(address,uint256)")),
            to,
            feeAmount1.mul(portion).div(10**18)
          );
          txCount = txCount.add(1);
        }
      }
    }

    // up-to 2 + rewardsListLength transactions for gauge withdraw processing
    if (address(gauge) != address(0)) {
      {
        // include to gauge withdraw transaction
        uint256 gaugeLpBalance = gauge.balanceOf(pool);
        if (gaugeLpBalance > 0) {
          uint256 portionBalance = gaugeLpBalance.mul(portion).div(10**18);

          transactions[txCount].to = address(gauge);
          transactions[txCount].txData = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256)")), portionBalance);
          txCount = txCount.add(1);
        }
      }

      {
        // include gauge reward claim transaction
        address[] memory rewardTokens = new address[](rewardsListLength);
        for (uint256 i = 0; i < rewardsListLength; i++) {
          rewardTokens[i] = gauge.rewards(i);
        }

        transactions[txCount].to = address(gauge);
        transactions[txCount].txData = abi.encodeWithSelector(
          bytes4(keccak256("getReward(address,address[])")),
          pool,
          rewardTokens
        );
        txCount = txCount.add(1);

        // withdraw gauge rewards directly to the user
        for (uint256 i = 0; i < rewardsListLength; i++) {
          uint256 rewardAmount = gauge.earned(rewardTokens[i], pool);
          if (rewardAmount > 0) {
            transactions[txCount].to = rewardTokens[i];
            transactions[txCount].txData = abi.encodeWithSelector(
              bytes4(keccak256("transfer(address,uint256)")),
              to,
              rewardAmount.mul(portion).div(10**18)
            );
            txCount = txCount.add(1);
          }
        }
      }
    }

    // Remove empty items from array
    uint256 reduceLength = (transactions.length).sub(txCount);
    assembly {
      mstore(transactions, sub(mload(transactions), reduceLength))
    }
  }

  function _assetValue(
    address factory,
    address poolManager,
    address token,
    uint256 amount
  ) internal view returns (uint256) {
    if (IHasAssetInfo(factory).isValidAsset(token) && amount > 0) {
      return IPoolManagerLogic(poolManager).assetValue(token, amount);
    } else {
      return 0;
    }
  }

  /// @notice Returns the balance of the managed asset
  /// @dev May include claimable fees & gauge lp/rewards
  /// @param pool address of the pool
  /// @param asset address of the asset
  /// @return balance The asset balance of given pool in lp price
  function getBalance(address pool, address asset) public view override returns (uint256 balance) {
    IVelodromeGauge gauge = IVelodromeGauge(voter.gauges(asset));

    // include lp balances
    balance = IERC20(asset).balanceOf(pool);
    if (address(gauge) != address(0)) {
      balance = balance.add(gauge.balanceOf(pool));
    }

    uint256 rewardsValue; // 18 decimals
    // include fee balance
    address factory = IPoolLogic(pool).factory();
    address poolManagerLogic = IPoolLogic(pool).poolManagerLogic();
    {
      address token0 = IVelodromePair(asset).token0();
      uint256 feeAmount0 = IVelodromePair(asset).claimable0(pool);
      rewardsValue = rewardsValue.add(_assetValue(factory, poolManagerLogic, token0, feeAmount0)); // 18 decimals
    }
    {
      address token1 = IVelodromePair(asset).token1();
      uint256 feeAmount1 = IVelodromePair(asset).claimable1(pool);
      rewardsValue = rewardsValue.add(_assetValue(factory, poolManagerLogic, token1, feeAmount1)); // 18 decimals
    }

    // include gauge rewards
    if (address(gauge) != address(0)) {
      uint256 rewardsListLength = gauge.rewardsListLength();
      for (uint256 i = 0; i < rewardsListLength; i++) {
        address rewardToken = gauge.rewards(i);
        uint256 rewardAmount = gauge.earned(rewardToken, pool);
        rewardsValue = rewardsValue.add(_assetValue(factory, poolManagerLogic, rewardToken, rewardAmount)); // 18 decimals
      }
    }

    // convert rewards value in lp price
    balance = balance.add(rewardsValue.mul(10**18).div(IHasAssetInfo(factory).getAssetPrice(asset)));
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
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../utils/TxDataUtils.sol";
import "../../utils/tracker/DhedgeNftTrackerStorage.sol";
import "../../interfaces/guards/ITxTrackingGuard.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IPoolManagerLogic.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/lyra/IOptionMarket.sol";
import "../../interfaces/lyra/IOptionMarketViewer.sol";
import "../../interfaces/lyra/IOptionMarketWrapper.sol";
import "../../interfaces/lyra/IShortCollateral.sol";
import "../../interfaces/lyra/ILyraRegistry.sol";
import "../../interfaces/synthetix/IAddressResolver.sol";

/// @title Transaction guard for Lyra OptionMarketWrapper
contract LyraOptionMarketWrapperContractGuard is TxDataUtils, ITxTrackingGuard {
  using SafeMathUpgradeable for uint256;

  bytes32 public constant NFT_TYPE = keccak256("LYRA_NFT_TYPE");
  address public immutable nftTracker;
  uint256 public immutable maxPositionCount;

  bytes32 public constant MARKET_VIEWER = "MARKET_VIEWER";
  bytes32 public constant MARKET_WRAPPER = "MARKET_WRAPPER";
  bytes32 public constant SYNTHETIX_ADAPTER = "SYNTHETIX_ADAPTER";

  struct OptionPosition {
    address optionMarket;
    uint256 positionId;
  }

  bool public override isTxTrackingGuard = true;
  ILyraRegistry public immutable lyraRegistry;

  constructor(
    ILyraRegistry _lyraRegistry,
    address _nftTracker,
    uint256 _maxPositionCount
  ) {
    lyraRegistry = _lyraRegistry;
    nftTracker = _nftTracker;
    maxPositionCount = _maxPositionCount;
  }

  function marketViewer() public view returns (IOptionMarketViewer) {
    return IOptionMarketViewer(lyraRegistry.getGlobalAddress(MARKET_VIEWER));
  }

  function marketWrapper() public view returns (address) {
    return lyraRegistry.getGlobalAddress(MARKET_WRAPPER);
  }

  function getOptionPositions(address poolLogic) public view returns (OptionPosition[] memory optionPositions) {
    bytes[] memory data = DhedgeNftTrackerStorage(nftTracker).getAllData(NFT_TYPE, poolLogic);
    optionPositions = new OptionPosition[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      optionPositions[i] = abi.decode(data[i], (OptionPosition));
    }
  }

  /// @notice Transaction guard for OptionMarketWrapper - used for Toros
  /// @dev It supports close/open/forceClose position
  /// @param _poolManagerLogic the pool manager logic
  /// @param data the transaction data
  /// @return txType the transaction type of a given transaction data.
  /// @return isPublic if the transaction is public or private
  function txGuard(
    address _poolManagerLogic,
    address to,
    bytes calldata data
  )
    public
    virtual
    override
    returns (
      uint16 txType,
      bool // isPublic
    )
  {
    IHasSupportedAsset poolManagerLogicAssets = IHasSupportedAsset(_poolManagerLogic);
    require(poolManagerLogicAssets.isSupportedAsset(to), "lyra not enabled");

    settleExpiredAndFilterActivePositions(IPoolManagerLogic(_poolManagerLogic).poolLogic());

    bytes4 method = getMethod(data);
    if (method == IOptionMarketWrapper.openPosition.selector) {
      IOptionMarketWrapper.OptionPositionParams memory params = abi.decode(
        getParams(data),
        (IOptionMarketWrapper.OptionPositionParams)
      );

      _checkSupportedAsset(poolManagerLogicAssets, params.optionType, address(params.optionMarket));
      txType = 26;

      settleExpiredAndFilterActivePositions(IPoolManagerLogic(_poolManagerLogic).poolLogic());
    } else if (method == IOptionMarketWrapper.closePosition.selector) {
      IOptionMarketWrapper.OptionPositionParams memory params = abi.decode(
        getParams(data),
        (IOptionMarketWrapper.OptionPositionParams)
      );

      _checkSupportedAsset(poolManagerLogicAssets, params.optionType, address(params.optionMarket));
      txType = 27;

      settleExpiredAndFilterActivePositions(IPoolManagerLogic(_poolManagerLogic).poolLogic());
    } else if (method == IOptionMarketWrapper.forceClosePosition.selector) {
      IOptionMarketWrapper.OptionPositionParams memory params = abi.decode(
        getParams(data),
        (IOptionMarketWrapper.OptionPositionParams)
      );

      _checkSupportedAsset(poolManagerLogicAssets, params.optionType, address(params.optionMarket));
      txType = 28;

      settleExpiredAndFilterActivePositions(IPoolManagerLogic(_poolManagerLogic).poolLogic());
    }

    return (txType, false);
  }

  function _checkSupportedAsset(
    IHasSupportedAsset poolManagerLogic,
    IOptionMarket.OptionType optionType,
    address optionMarket
  ) internal view {
    IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
      optionMarket
    );

    // if short-call-base option type, check base asset
    if (optionType == IOptionMarket.OptionType.SHORT_CALL_BASE) {
      require(poolManagerLogic.isSupportedAsset(address(optionMarketAddresses.baseAsset)), "unsupported base asset");
    } else {
      // otherwise, check quote asset
      require(poolManagerLogic.isSupportedAsset(address(optionMarketAddresses.quoteAsset)), "unsupported quote asset");
    }
  }

  /// @notice This function is called after execution transaction (used to track transactions)
  /// @dev It supports close/open/forceClose position
  /// @param _poolManagerLogic the pool manager logic
  /// @param data the transaction data
  function afterTxGuard(
    address _poolManagerLogic,
    address to,
    bytes calldata data
  ) public virtual override {
    address poolLogic = IPoolManagerLogic(_poolManagerLogic).poolLogic();
    require(msg.sender == poolLogic, "not pool logic");

    IOptionMarketWrapper.OptionPositionParams memory params = abi.decode(
      getParams(data),
      (IOptionMarketWrapper.OptionPositionParams)
    );
    afterTxGuardHandle(to, poolLogic, address(params.optionMarket), params.positionId);
  }

  function afterTxGuardHandle(
    address contractGuarded,
    address poolLogic,
    address optionMarket,
    uint256 positionId
  ) internal {
    IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
      optionMarket
    );
    // If the manager is not specifying a positionId it means he must be creating a new position
    // We use the optionMakets "nextId" to determine the last Id created and store that for the pool
    // "nextId" starts from 1 so the positionId starts from 1.
    if (positionId == 0) {
      // New position created, We use the nextId sub 1 as this code runs after the creation of the option.
      DhedgeNftTrackerStorage(nftTracker).addData(
        contractGuarded,
        NFT_TYPE,
        poolLogic,
        abi.encode(
          OptionPosition({
            optionMarket: optionMarket,
            positionId: IOptionToken(optionMarketAddresses.optionToken).nextId().sub(1)
          })
        )
      );

      require(
        DhedgeNftTrackerStorage(nftTracker).getDataCount(NFT_TYPE, poolLogic) <= maxPositionCount,
        "exceed maximum position count"
      );

      // If the manager is specifying a positionId it must mean he is trying to make changes to an existing one
      // We detect if it is closed and remove it from storage
    } else {
      IOptionToken.PositionState positionState = IOptionToken(optionMarketAddresses.optionToken).getPositionState(
        positionId
      );

      // find option position from nft tracker
      OptionPosition[] memory optionPositions = getOptionPositions(poolLogic);
      uint256 i;
      for (i = 0; i < optionPositions.length; i++) {
        if (optionPositions[i].optionMarket == optionMarket && optionPositions[i].positionId == positionId) {
          break;
        }
      }

      require(i < optionPositions.length, "position is not in track");

      if (positionState != IOptionToken.PositionState.ACTIVE) {
        // If the position is not active remove it from nft tracker
        DhedgeNftTrackerStorage(nftTracker).removeData(contractGuarded, NFT_TYPE, poolLogic, i);
      }
    }
  }

  function removeClosedPosition(
    address poolLogic,
    address optionMarket,
    uint256 positionId
  ) external {
    OptionPosition[] memory optionPositions = getOptionPositions(poolLogic);
    // We need to find which array index is the position we want to delete
    for (uint256 i = 0; i < optionPositions.length; i++) {
      if (optionPositions[i].optionMarket == optionMarket && optionPositions[i].positionId == positionId) {
        IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
          optionMarket
        );

        // Once we find it we check to make sure the postion is not active
        require(
          IOptionToken(optionMarketAddresses.optionToken).getPositionState(positionId) !=
            IOptionToken.PositionState.ACTIVE,
          "not closed position"
        );

        DhedgeNftTrackerStorage(nftTracker).removeData(marketWrapper(), NFT_TYPE, poolLogic, i);
        break;
      }
    }
  }

  /// @notice Function for settling expired options and filtering active options
  /// @dev Used when interacting with the OptionMarketWrapper contract
  function settleExpiredAndFilterActivePositions(address poolLogic) public {
    _settleExpiredAndFilterActivePositions(poolLogic, marketWrapper());
  }

  /// @notice Public function for settling expired options and filtering active options
  /// @dev Includes a guardecContract input for handling calls directly through the OptionMarket contract (not wrapper)
  function settleExpiredAndFilterActivePositions(address poolLogic, address guardedContract) public {
    _settleExpiredAndFilterActivePositions(poolLogic, guardedContract);
  }

  function _settleExpiredAndFilterActivePositions(address poolLogic, address guardedContract) internal {
    IHasSupportedAsset poolManagerLogicAssets = IHasSupportedAsset(IPoolLogic(poolLogic).poolManagerLogic());

    OptionPosition[] memory optionPositions = getOptionPositions(poolLogic);

    // 1. we filter active option positions
    // 2. we settle expired option positions
    // 3. we removed expired/inactive option positions from nft tracker
    for (uint256 i = optionPositions.length; i > 0; i--) {
      uint256 index = i - 1;
      IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer().marketAddresses(
        optionPositions[index].optionMarket
      );
      IOptionToken.OptionPosition memory position = IOptionToken(optionMarketAddresses.optionToken).positions(
        optionPositions[index].positionId
      );
      if (position.state == IOptionToken.PositionState.ACTIVE) {
        (, uint256 priceAtExpiry, ) = IOptionMarket(optionPositions[index].optionMarket).getSettlementParameters(
          position.strikeId
        );

        if (priceAtExpiry == 0) {
          continue;
        }

        // settlement will return base or quote asset back to the pool
        // we check if quote/base asset is supported for option position type
        _checkSupportedAsset(poolManagerLogicAssets, position.optionType, optionPositions[index].optionMarket);

        uint256[] memory positionsToSettle = new uint256[](1);
        positionsToSettle[0] = optionPositions[index].positionId;
        IShortCollateral(optionMarketAddresses.shortCollateral).settleOptions(positionsToSettle);
      }

      DhedgeNftTrackerStorage(nftTracker).removeData(guardedContract, NFT_TYPE, poolLogic, index);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILendingPool {
  struct UserConfigurationMap {
    uint256 data;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  function flashLoan(
    address receiverAddress,
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory modes,
    address onBehalfOf,
    bytes memory params,
    uint16 referralCode
  ) external;

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  function rebalanceStableBorrowRate(address asset, address user) external;

  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);

  function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);

  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IArrakisVaultV1 {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function pool() external view returns (address);

  function getPositionId() external view returns (bytes32);

  function getUnderlyingBalances() external view returns (uint256 amount0Current, uint256 amount1Current);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ILiquidityGaugeV4 {
  // solhint-disable-next-line func-name-mixedcase
  function reward_count() external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function reward_tokens(uint256 index) external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function reward_data(address tokenInput)
    external
    view
    returns (
      address token,
      address distributor,
      // solhint-disable-next-line var-name-mixedcase
      uint256 period_finish,
      uint256 rate,
      // solhint-disable-next-line var-name-mixedcase
      uint256 last_update,
      uint256 integral
    );

  // solhint-disable-next-line func-name-mixedcase
  function claimable_reward(address user, address rewardToken) external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function staking_token() external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards() external;

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards(address user) external;

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards(address user, address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBalancerPool {
  function totalSupply() external view returns (uint256);

  function getPoolId() external view returns (bytes32);

  function getVault() external view returns (address);

  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBalancerV2Vault {
  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
  }

  enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
  }

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  function getPool(bytes32 poolId) external view returns (address pool);

  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256 amountCalculated);

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    address[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest memory request
  ) external;

  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IRewardsContract {
  // solhint-disable-next-line func-name-mixedcase
  function reward_count() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IRewardsOnlyGauge {
  // solhint-disable-next-line func-name-mixedcase
  function lp_token() external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function reward_tokens(uint256 index) external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function reward_contract() external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function balanceOf(address user) external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function claimable_reward(address user, address rewardToken) external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function claimable_reward_write(address user, address rewardToken) external returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards() external;

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards(address user) external;

  // solhint-disable-next-line func-name-mixedcase
  function claim_rewards(address user, address receiver) external;

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address user) external;

  function deposit(
    uint256 amount,
    address onBehalf,
    bool isClaimRewards
  ) external;

  function withdraw(uint256 amount) external;

  function withdraw(uint256 amount, bool isClaimRewards) external;
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

import "../IHasSupportedAsset.sol";

interface IAssetGuard {
  struct MultiTransaction {
    address to;
    bytes txData;
  }

  function withdrawProcessing(
    address pool,
    address asset,
    uint256 withdrawPortion,
    address to
  )
    external
    returns (
      address,
      uint256,
      MultiTransaction[] memory transactions
    );

  function getBalance(address pool, address asset) external view returns (uint256 balance);

  function getDecimals(address asset) external view returns (uint256 decimals);

  function removeAssetCheck(address poolLogic, address asset) external view;
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

  function afterTxGuard(
    address poolManagerLogic,
    address to,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

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

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IManaged {
  function manager() external view returns (address);

  function trader() external view returns (address);

  function managerName() external view returns (string memory);
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

interface IPoolLogic {
  function factory() external view returns (address);

  function poolManagerLogic() external view returns (address);

  function setPoolManagerLogic(address _poolManagerLogic) external returns (bool);

  function availableManagerFee() external view returns (uint256 fee);

  function tokenPrice() external view returns (uint256 price);

  function tokenPriceWithoutManagerFee() external view returns (uint256 price);

  function mintManagerFee() external;

  function deposit(address _asset, uint256 _amount) external returns (uint256 liquidityMinted);

  function depositFor(
    address _recipient,
    address _asset,
    uint256 _amount
  ) external returns (uint256 liquidityMinted);

  function depositForWithCustomCooldown(
    address _recipient,
    address _asset,
    uint256 _amount,
    uint256 _cooldown
  ) external returns (uint256 liquidityMinted);

  function withdraw(uint256 _fundTokenAmount) external;

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address owner) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function symbol() external view returns (string memory);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function getExitRemainingCooldown(address sender) external view returns (uint256 remaining);
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

  function getFee()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function minDepositUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transfer(address dst, uint256 wad) external returns (bool);

  function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

interface IGWAVOracle {
  function deltaGWAV(uint256 strikeId, uint256 secondsAgo) external view returns (int256 callDelta);

  function optionPriceGWAV(uint256 strikeId, uint256 secondsAgo)
    external
    view
    returns (uint256 callPrice, uint256 putPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ILiquidityPool {
  // solhint-disable-next-line func-name-mixedcase
  function CBTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionToken.sol";
import "./IOptionMarket.sol";
import "./IOptionGreekCache.sol";

interface ILyraRegistry {
  struct OptionMarketAddresses {
    address liquidityPool;
    address liquidityToken;
    IOptionGreekCache greekCache;
    IOptionMarket optionMarket;
    address optionMarketPricer;
    IOptionToken optionToken;
    address poolHedger;
    address shortCollateral;
    address gwavOracle;
    IERC20 quoteAsset;
    IERC20 baseAsset;
  }

  function getMarketAddresses(address market) external view returns (OptionMarketAddresses memory);

  function getGlobalAddress(bytes32 contractName) external view returns (address globalContract);

  function optionMarkets(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IOptionMarket.sol";

interface IOptionGreekCache {
  function isGlobalCacheStale(uint256 spotPrice) external view returns (bool);

  function isBoardCacheStale(uint256 boardId) external view returns (bool);

  function updateBoardCachedGreeks(uint256 boardId) external;

  function getMinCollateral(
    IOptionMarket.OptionType optionType,
    uint256 strikePrice,
    uint256 expiry,
    uint256 spotPrice,
    uint256 amount
  ) external view returns (uint256 minCollateral);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IOptionMarket {
  enum TradeDirection {
    OPEN,
    CLOSE,
    LIQUIDATE
  }

  enum OptionType {
    LONG_CALL,
    LONG_PUT,
    SHORT_CALL_BASE,
    SHORT_CALL_QUOTE,
    SHORT_PUT_QUOTE
  }

  struct TradeInputParameters {
    // id of strike
    uint256 strikeId;
    // OptionToken ERC721 id for position (set to 0 for new positions)
    uint256 positionId;
    // number of sub-orders to break order into (reduces slippage)
    uint256 iterations;
    // type of option to trade
    OptionType optionType;
    // number of contracts to trade
    uint256 amount;
    // final amount of collateral to leave in OptionToken position
    uint256 setCollateralTo;
    // revert trade if totalCost is below this value
    uint256 minTotalCost;
    // revert trade if totalCost is above this value
    uint256 maxTotalCost;
  }

  struct Strike {
    // strike listing identifier
    uint256 id;
    // strike price
    uint256 strikePrice;
    // volatility component specific to the strike listing (boardIv * skew = vol of strike)
    uint256 skew;
    // total user long call exposure
    uint256 longCall;
    // total user short call (base collateral) exposure
    uint256 shortCallBase;
    // total user short call (quote collateral) exposure
    uint256 shortCallQuote;
    // total user long put exposure
    uint256 longPut;
    // total user short put (quote collateral) exposure
    uint256 shortPut;
    // id of board to which strike belongs
    uint256 boardId;
  }

  function getStrike(uint256 strikeId) external view returns (Strike memory);

  function getStrikeAndExpiry(uint256 strikeId) external view returns (uint256 strikePrice, uint256 expiry);

  function getSettlementParameters(uint256 strikeId)
    external
    view
    returns (
      uint256 strikePrice,
      uint256 priceAtExpiry,
      uint256 strikeToBaseReturned
    );

  ///

  function addCollateral(uint256 positionId, uint256 amountCollateral) external;

  function liquidatePosition(uint256 positionId, address rewardBeneficiary) external;

  function closePosition(TradeInputParameters memory params) external;

  function forceClosePosition(TradeInputParameters memory params) external;

  function openPosition(TradeInputParameters memory params) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionToken.sol";
import "./IOptionMarket.sol";
import "./IOptionGreekCache.sol";

interface IOptionMarketViewer {
  struct MarketOptionPositions {
    address market;
    IOptionToken.OptionPosition[] positions;
  }

  struct OptionMarketAddresses {
    address liquidityPool;
    address liquidityTokens;
    IOptionGreekCache greekCache;
    IOptionMarket optionMarket;
    address optionMarketPricer;
    IOptionToken optionToken;
    address shortCollateral;
    address poolHedger;
    IERC20 quoteAsset;
    IERC20 baseAsset;
  }

  function synthetixAdapter() external view returns (address);

  function getOwnerPositions(address owner) external view returns (IOptionToken.OptionPosition[] memory);

  function getMarketAddresses() external view returns (OptionMarketAddresses[] memory);

  function marketAddresses(address market) external view returns (OptionMarketAddresses memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionMarket.sol";
import "./IOptionToken.sol";

interface IOptionMarketWrapper {
  struct OptionMarketContracts {
    IERC20 quoteAsset;
    IERC20 baseAsset;
    IOptionToken optionToken;
  }

  struct OptionPositionParams {
    IOptionMarket optionMarket;
    uint256 strikeId; // The id of the relevant OptionListing
    uint256 positionId;
    uint256 iterations;
    uint256 setCollateralTo;
    uint256 currentCollateral;
    IOptionMarket.OptionType optionType; // Is the trade a long/short & call/put?
    uint256 amount; // The amount the user has requested to close
    uint256 minCost; // Min amount for the cost of the trade
    uint256 maxCost; // Max amount for the cost of the trade
    uint256 inputAmount; // Amount of stable coins the user can use
    IERC20 inputAsset; // Address of coin user wants to open with
  }

  struct ReturnDetails {
    address market;
    uint256 positionId;
    address owner;
    uint256 amount;
    uint256 totalCost;
    uint256 totalFee;
    int256 swapFee;
    address token;
  }

  function openPosition(OptionPositionParams memory params) external returns (ReturnDetails memory returnDetails);

  function closePosition(OptionPositionParams memory params) external returns (ReturnDetails memory returnDetails);

  function forceClosePosition(OptionPositionParams memory params) external returns (ReturnDetails memory returnDetails);

  function marketContracts(IOptionMarket market) external view returns (OptionMarketContracts memory);

  function idToMarket(uint8 id) external view returns (address optionMarket);

  function idToERC(uint8 id) external view returns (address token);

  function openLong(uint256 params) external returns (uint256 totalCost);

  function addLong(uint256 params) external returns (uint256 totalCost);

  function reduceLong(uint256 params) external returns (uint256 totalReceived);

  function closeLong(uint256 params) external returns (uint256 totalReceived);

  function openShort(uint256 params) external returns (uint256 totalReceived);

  function addShort(uint256 params) external returns (uint256 totalReceived);

  function reduceShort(uint256 params) external returns (uint256 totalCost);

  function closeShort(uint256 params) external returns (uint256 totalCost);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

import "./IOptionMarket.sol";

interface IOptionToken is IERC721Enumerable {
  enum PositionState {
    EMPTY,
    ACTIVE,
    CLOSED,
    LIQUIDATED,
    SETTLED,
    MERGED
  }

  enum PositionUpdatedType {
    OPENED,
    ADJUSTED,
    CLOSED,
    SPLIT_FROM,
    SPLIT_INTO,
    MERGED,
    MERGED_INTO,
    SETTLED,
    LIQUIDATED,
    TRANSFER
  }

  struct OptionPosition {
    uint256 positionId;
    uint256 strikeId;
    IOptionMarket.OptionType optionType;
    uint256 amount;
    uint256 collateral;
    PositionState state;
  }

  struct PositionWithOwner {
    uint256 positionId;
    uint256 strikeId;
    IOptionMarket.OptionType optionType;
    uint256 amount;
    uint256 collateral;
    PositionState state;
    address owner;
  }

  function nextId() external view returns (uint256);

  function getOwnerPositions(address target) external view returns (OptionPosition[] memory);

  function positions(uint256 positionId) external view returns (OptionPosition memory);

  function getPositionState(uint256 positionId) external view returns (PositionState);

  function getPositionWithOwner(uint256 positionId) external view returns (PositionWithOwner memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

interface IShortCollateral {
  function settleOptions(uint256[] memory positionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionMarket.sol";
import "../synthetix/IExchanger.sol";

interface ISynthetixAdapter {
  function synthetix() external view returns (address);

  function exchanger() external view returns (IExchanger);

  function addressResolver() external view returns (address);

  function quoteKey(address) external view returns (bytes32);

  function baseKey(address) external view returns (bytes32);

  function getSpotPriceForMarket(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IAddressResolver {
  function getSynth(bytes32 key) external view returns (address);

  function getAddress(bytes32 name) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IExchanger {
  function settle(address from, bytes32 currencyKey)
    external
    returns (
      uint256 reclaimed,
      uint256 refunded,
      uint256 numEntries
    );

  function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

  function getAmountsForExchange(
    uint256 sourceAmount,
    bytes32 sourceCurrencyKey,
    bytes32 destinationCurrencyKey
  )
    external
    view
    returns (
      uint256 amountReceived,
      uint256 fee,
      uint256 exchangeFeeRate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISynthTarget {
  function currencyKey() external view returns (bytes32);
}

interface ISynthAddressProxy {
  function target() external view returns (ISynthTarget synthAsset);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISynthetix {
  function exchange(
    bytes32 sourceCurrencyKey,
    uint256 sourceAmount,
    bytes32 destinationCurrencyKey
  ) external returns (uint256 amountReceived);

  function exchangeWithTracking(
    bytes32 sourceCurrencyKey,
    uint256 sourceAmount,
    bytes32 destinationCurrencyKey,
    address originator,
    bytes32 trackingCode
  ) external returns (uint256 amountReceived);

  function synths(bytes32 key) external view returns (address synthTokenAddress);

  function synthsByAddress(address asset) external view returns (bytes32 key);

  function settle(bytes32 currencyKey)
    external
    returns (
      uint256 reclaimed,
      uint256 refunded,
      uint256 numEntriesSettled
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV2Router {
  function factory() external pure returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function WETH() external view returns (address);

  function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV2RouterSwapOnly {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVelodromeGauge {
  function balanceOf(address user) external view returns (uint256);

  function stake() external view returns (address);

  function left(address token) external view returns (uint256);

  function isForPair() external view returns (bool);

  function rewardsListLength() external view returns (uint256);

  function rewards(uint256 index) external view returns (address);

  function earned(address token, address account) external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function external_bribe() external view returns (address);

  // solhint-disable-next-line func-name-mixedcase
  function internal_bribe() external view returns (address);

  function notifyRewardAmount(address token, uint256 amount) external;

  function getReward(address account, address[] memory tokens) external;

  function claimFees() external returns (uint256 claimed0, uint256 claimed1);

  function deposit(uint256 amount, uint256 tokenId) external;

  function depositAll(uint256 tokenId) external;

  function withdraw(uint256 amount) external;

  function withdrawAll() external;

  function withdrawToken(uint256 amount, uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

interface IVelodromePair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function claimable0(address user) external view returns (uint256);

  function claimable1(address user) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function claimFees() external returns (uint256 claimed0, uint256 claimed1);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVelodromeV2Gauge {
  function balanceOf(address user) external view returns (uint256);

  function rewardPerToken() external view returns (uint256 _rewardPerToken);

  /// @notice Returns the last time the reward was modified or periodFinish if the reward has ended
  function lastTimeRewardApplicable() external view returns (uint256 _time);

  /// @notice Returns accrued balance to date from last claim / first deposit.
  function earned(address _account) external view returns (uint256 _earned);

  function left() external view returns (uint256 _left);

  /// @notice Returns if gauge is linked to a legitimate Velodrome pool
  function isPool() external view returns (bool _isPool);

  function stakingToken() external view returns (address _pool);

  function rewardToken() external view returns (address _token);

  /// @notice Retrieve rewards for an address.
  /// @dev Throws if not called by same address or voter.
  /// @param _account .
  function getReward(address _account) external;

  /// @notice Deposit LP tokens into gauge for msg.sender
  /// @param _amount .
  function deposit(uint256 _amount) external;

  /// @notice Deposit LP tokens into gauge for any user
  /// @param _amount .
  /// @param _recipient Recipient to give balance to
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Withdraw LP tokens for user
  /// @param _amount .
  function withdraw(uint256 _amount) external;

  /// @dev Notifies gauge of gauge rewards. Assumes gauge reward tokens is 18 decimals.
  ///      If not 18 decimals, rewardRate may have rounding issues.
  function notifyRewardAmount(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IVelodromeVoter {
  function gauges(address pool) external view returns (address gauge);
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
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IPoolManagerLogic.sol";
import "../../interfaces/IManaged.sol";
import "../../interfaces/uniswapV2/IUniswapV2RouterSwapOnly.sol";
import "./EasySwapperWithdrawer.sol";
import "./EasySwapperStructs.sol";
import "./EasySwapperSwap.sol";

contract DhedgeEasySwapper is OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

  event Deposit(
    address pool,
    address depositor,
    address depositAsset,
    uint256 amount,
    address poolDepositAsset,
    uint256 liquidityMinted
  );

  address payable public feeSink;
  uint256 public feeNumerator;
  uint256 public feeDenominator;

  mapping(address => bool) public allowedPools;
  mapping(address => bool) public managerFeeBypass;

  EasySwapperStructs.WithdrawProps public withdrawProps;

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  // solhint-disable-next-line no-empty-blocks
  fallback() external payable {}

  modifier isPoolAllowed(address _address) {
    require(allowedPools[_address], "no-go");
    _;
  }

  /// @param _feeSink Address of the fee recipient
  /// @param _feeNumerator Fee numerator ie 1
  /// @param _feeDenominator Fee denominator ie 100
  function initialize(
    address payable _feeSink,
    uint256 _feeNumerator,
    uint256 _feeDenominator
  ) external initializer {
    __Ownable_init();

    feeSink = _feeSink;
    feeNumerator = _feeNumerator;
    feeDenominator = _feeDenominator;
  }

  /// @notice Sets the WithdrawProps
  /// @param _withdrawProps the new withdrawProps
  function setWithdrawProps(EasySwapperStructs.WithdrawProps calldata _withdrawProps) external onlyOwner {
    withdrawProps = _withdrawProps;
  }

  /// @notice Allows the swap router to be updated
  /// @param _swapRouter the address of a UniV2 compatible router
  function setSwapRouter(IUniswapV2RouterSwapOnly _swapRouter) external onlyOwner {
    withdrawProps.swapRouter = _swapRouter;
  }

  /// @notice Sets if a pool is allowed to use the custom cooldown deposit functions
  /// @param pool the pool for the setting
  /// @param allowed if the pool is allowed, can be used to remove pool
  function setPoolAllowed(address pool, bool allowed) external onlyOwner {
    allowedPools[pool] = allowed;
  }

  /// @notice Sets the deposit fee, thats charged to the user
  /// @dev 50:10000 50bp
  /// @param numerator the numerator ie 1
  /// @param denominator he denominator ie 100
  function setFee(uint256 numerator, uint256 denominator) external onlyOwner {
    require(feeDenominator >= feeNumerator, "nmr<=dnmr");
    feeNumerator = numerator;
    feeDenominator = denominator;
  }

  /// @notice Sets where the deposit fee is sent
  /// @param sink the address of the fee receipient
  function setFeeSink(address payable sink) external onlyOwner {
    feeSink = sink;
  }

  /// @notice Bypasses the fee for a pool manager
  /// @param manager Manager to bypass the fee for
  /// @param bypass Enable / disable bypass
  function setManagerFeeBypass(address manager, bool bypass) external onlyOwner {
    managerFeeBypass[manager] = bypass;
  }

  /// @notice deposit into underlying pool and receive tokens with normal lockup
  /// @param pool the pool to deposit into
  /// @param depositAsset the asset the user wants to deposit
  /// @param amount the amount of the deposit asset
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param expectedLiquidityMinted the expected amount of pool tokens to receive (slippage protection)
  /// @return liquidityMinted the number of wrapper tokens allocated
  function deposit(
    address pool,
    IERC20Extended depositAsset,
    uint256 amount,
    IERC20Extended poolDepositAsset,
    uint256 expectedLiquidityMinted
  ) external returns (uint256 liquidityMinted) {
    // Transfer the users funds to this contract
    IERC20Extended(address(depositAsset)).transferFrom(msg.sender, address(this), amount);

    return _deposit(pool, depositAsset, amount, poolDepositAsset, expectedLiquidityMinted, false);
  }

  /// @notice deposit into underlying pool and receive tokens with 15 minutes lockup
  /// @dev function name mimics the naming of PoolLogic's function
  /// @param pool the pool to deposit into
  /// @param depositAsset the asset the user wants to deposit
  /// @param amount the amount of the deposit asset
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param expectedLiquidityMinted the expected amount of pool tokens to receive (slippage protection)
  /// @return liquidityMinted the number of wrapper tokens allocated
  function depositWithCustomCooldown(
    address pool,
    IERC20Extended depositAsset,
    uint256 amount,
    IERC20Extended poolDepositAsset,
    uint256 expectedLiquidityMinted
  ) external isPoolAllowed(pool) returns (uint256 liquidityMinted) {
    // Transfer the users funds to this contract
    IERC20Extended(address(depositAsset)).transferFrom(msg.sender, address(this), amount);

    return _deposit(pool, depositAsset, amount, poolDepositAsset, expectedLiquidityMinted, true);
  }

  /// @notice deposit native asset into underlying pool and receive tokens with normal lockup
  /// @param pool the pool to deposit into
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param expectedLiquidityMinted the expected amount of pool tokens to receive (slippage protection)
  /// @return liquidityMinted the number of wrapper tokens allocated
  function depositNative(
    address pool,
    IERC20Extended poolDepositAsset,
    uint256 expectedLiquidityMinted
  ) external payable returns (uint256 liquidityMinted) {
    // wrap native asset
    uint256 amount = msg.value;
    IERC20Extended depositAsset = withdrawProps.nativeAssetWrapper;
    IWETH(address(depositAsset)).deposit{value: amount}();

    return _deposit(pool, depositAsset, amount, poolDepositAsset, expectedLiquidityMinted, false);
  }

  /// @notice deposit native asset into underlying pool and receive tokens with 15 minutes lockup
  /// @dev Function name mimics the naming of PoolLogic's function
  /// @param pool the pool to deposit into
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param expectedLiquidityMinted the expected amount of pool tokens to receive (slippage protection)
  /// @return liquidityMinted the number of wrapper tokens allocated
  function depositNativeWithCustomCooldown(
    address pool,
    IERC20Extended poolDepositAsset,
    uint256 expectedLiquidityMinted
  ) external payable isPoolAllowed(pool) returns (uint256 liquidityMinted) {
    // wrap native asset
    uint256 amount = msg.value;
    IERC20Extended depositAsset = withdrawProps.nativeAssetWrapper;
    IWETH(address(depositAsset)).deposit{value: amount}();

    return _deposit(pool, depositAsset, amount, poolDepositAsset, expectedLiquidityMinted, true);
  }

  /// @notice Swaps deposit asset into pool deposit asset and deposits into the pool
  /// @dev Boolean flag is used as last param not to exceed contract size limit
  /// @param pool the pool to deposit into
  /// @param depositAsset the asset the user wants to deposit
  /// @param amount the amount of the deposit asset
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param expectedLiquidityMinted the expected amount of pool tokens to receive (slippage protection)
  /// @param customCooldown boolean to choose between normal deposit and custom cooldown deposit
  /// @return liquidityMinted the number of wrapper tokens allocated
  function _deposit(
    address pool,
    IERC20Extended depositAsset,
    uint256 amount,
    IERC20Extended poolDepositAsset,
    uint256 expectedLiquidityMinted,
    bool customCooldown
  ) private returns (uint256 liquidityMinted) {
    // Sweep fee to sink
    uint256 fee = getFee(pool, amount);
    if (fee > 0 && customCooldown) {
      depositAsset.transfer(feeSink, fee);
    }

    if (depositAsset != poolDepositAsset) {
      EasySwapperSwap.swapThat(withdrawProps.swapRouter, depositAsset, poolDepositAsset);
    }

    // Approve the pool to take the funds
    poolDepositAsset.approve(address(pool), poolDepositAsset.balanceOf(address(this)));

    if (customCooldown) {
      liquidityMinted = IPoolLogic(pool).depositForWithCustomCooldown(
        msg.sender,
        address(poolDepositAsset),
        poolDepositAsset.balanceOf(address(this)),
        15 minutes
      );
    } else {
      liquidityMinted = IPoolLogic(pool).depositFor(
        msg.sender,
        address(poolDepositAsset),
        poolDepositAsset.balanceOf(address(this))
      );
    }
    require(liquidityMinted >= expectedLiquidityMinted, "slippage");

    emit Deposit(pool, msg.sender, address(depositAsset), amount, address(poolDepositAsset), liquidityMinted);
  }

  /// @notice calculates the fee based on the settings
  /// @dev fee bypass is for cases like Toros pool manager wants to buy other Toros products (dSNX has USDy)
  /// @param pool the pool to check
  /// @param amount the net amount
  function getFee(address pool, uint256 amount) internal view returns (uint256 fee) {
    if (feeNumerator > 0 && feeDenominator > 0 && feeSink != address(0)) {
      fee = amount.mul(feeNumerator).div(feeDenominator);
    }

    IPoolLogic poolLogic = IPoolLogic(pool);
    (, , uint256 entryFeeNumerator, ) = IPoolManagerLogic(poolLogic.poolManagerLogic()).getFee();
    // Do not charge Swapper's fee if the pool has an entry fee set
    if (entryFeeNumerator > 0) {
      fee = 0;
    }

    // Fee bypass
    if (IPoolFactory(poolLogic.factory()).isPool(msg.sender)) {
      IManaged poolManagerLogic = IManaged(IPoolLogic(msg.sender).poolManagerLogic());
      address manager = poolManagerLogic.manager();
      if (managerFeeBypass[manager]) {
        fee = 0;
      }
    }
  }

  /// @notice calculates how many tokens the user should receive on deposit based on current swap conditions
  /// @param pool the pool to deposit into
  /// @param depositAsset the asset the user wants to deposit
  /// @param amount the amount of the deposit asset
  /// @param poolDepositAsset the asset that the pool accepts
  /// @param customCooldown quote required for custom cooldown deposit method or not
  /// @return expectedLiquidityMinted the expected amount of pool tokens to receive inclusive of slippage
  function depositQuote(
    address pool,
    IERC20Extended depositAsset,
    uint256 amount,
    IERC20Extended poolDepositAsset,
    bool customCooldown
  ) external view returns (uint256 expectedLiquidityMinted) {
    uint256 tokenPrice = IPoolLogic(pool).tokenPrice();
    uint256 depositAmount = amount;
    if (customCooldown) {
      depositAmount = depositAmount - getFee(pool, amount);
    }

    if (depositAsset != poolDepositAsset) {
      address[] memory path = new address[](2);
      path[0] = address(depositAsset);
      path[1] = address(poolDepositAsset);
      uint256[] memory amountsOut = withdrawProps.swapRouter.getAmountsOut(depositAmount, path);
      depositAmount = amountsOut[amountsOut.length - 1];
    }
    IPoolManagerLogic managerLogic = IPoolManagerLogic(IPoolLogic(pool).poolManagerLogic());
    uint256 depositValue = managerLogic.assetValue(address(poolDepositAsset), depositAmount);

    if (tokenPrice == 0) {
      expectedLiquidityMinted = depositValue;
    } else {
      expectedLiquidityMinted = depositValue.mul(10**18).div(tokenPrice);
    }

    (, , uint256 entryFeeNumerator, uint256 denominator) = managerLogic.getFee();
    if (entryFeeNumerator > 0) {
      expectedLiquidityMinted = expectedLiquidityMinted.mul(denominator.sub(entryFeeNumerator)).div(denominator);
    }
  }

  /// @notice withdraw underlying value of tokens in expectedWithdrawalAssetOfUser
  /// @dev Swaps the underlying pool withdrawal assets to expectedWithdrawalAssetOfUser
  /// @param pool dhedgepool to withdraw from
  /// @param fundTokenAmount the amount to withdraw
  /// @param withdrawalAsset must have direct pair to all pool.supportedAssets on swapRouter
  /// @param expectedAmountOut the amount of value in the withdrawalAsset expected (slippage protection)
  function withdraw(
    address pool,
    uint256 fundTokenAmount,
    IERC20Extended withdrawalAsset,
    uint256 expectedAmountOut
  ) external {
    IERC20Extended(pool).transferFrom(msg.sender, address(this), fundTokenAmount);
    EasySwapperWithdrawer.withdraw(
      msg.sender,
      pool,
      fundTokenAmount,
      withdrawalAsset,
      expectedAmountOut,
      withdrawProps
    );
  }

  /// @notice Withdraw underlying value of tokens into intermediate asset and then swap to susd
  /// @dev Helper function for dsnx
  /// @param pool dhedgepool to withdraw from
  /// @param fundTokenAmount the dhedgepool amount to withdraw
  /// @param intermediateAsset must have direct pair to all pool.supportedAssets on swapRouter and to SUSD
  /// @param expectedAmountSUSD the amount of value in susd expected (slippage protection)
  function withdrawSUSD(
    address pool,
    uint256 fundTokenAmount,
    IERC20Extended intermediateAsset,
    uint256 expectedAmountSUSD
  ) external {
    withdrawIntermediate(
      pool,
      fundTokenAmount,
      intermediateAsset,
      IERC20Extended(address(withdrawProps.synthetixProps.sUSDProxy)),
      expectedAmountSUSD
    );
  }

  /// @notice Withdraw underlying value of tokens into intermediate asset and then swap to final asset
  /// @param pool dhedgepool to withdraw from
  /// @param fundTokenAmount the dhedgepool amount to withdraw
  /// @param intermediateAsset must have direct pair to all pool.supportedAssets on swapRouter
  /// @param finalAsset must have direct pair to intermediate asset
  /// @param expectedAmountFinalAsset the amount of value in final asset expected (slippage protection)
  function withdrawIntermediate(
    address pool,
    uint256 fundTokenAmount,
    IERC20Extended intermediateAsset,
    IERC20Extended finalAsset,
    uint256 expectedAmountFinalAsset
  ) public {
    IERC20Extended(pool).transferFrom(msg.sender, address(this), fundTokenAmount);
    EasySwapperWithdrawer.withdrawWithIntermediate(
      msg.sender,
      pool,
      fundTokenAmount,
      intermediateAsset,
      finalAsset,
      expectedAmountFinalAsset,
      withdrawProps
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IHasAssetInfo.sol";

import "../../interfaces/arrakis/ILiquidityGaugeV4.sol";
import "../../interfaces/arrakis/IArrakisVaultV1.sol";

library EasySwapperArrakisHelpers {
  /// @notice Determines which assets the swapper will have received when withdrawing from the pool
  /// @dev The pool unrolls arrakis assets into the underlying assets and transfers them directly to the withdrawer, we need to know which assets the swapper received
  /// @param arrakisAsset the address of the arrakis gauge
  function getArrakisAssets(address arrakisAsset) internal view returns (address[] memory assets) {
    ILiquidityGaugeV4 gauge = ILiquidityGaugeV4(arrakisAsset);
    IArrakisVaultV1 vault = IArrakisVaultV1(gauge.staking_token());

    uint256 rewardCount = gauge.reward_count();

    assets = new address[](2 + rewardCount);
    assets[0] = vault.token0();
    assets[1] = vault.token1();

    for (uint256 i = 0; i < rewardCount; i++) {
      assets[2 + i] = gauge.reward_tokens(i);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/balancer/IBalancerV2Vault.sol";
import "../../interfaces/balancer/IBalancerPool.sol";
import "../../interfaces/balancer/IRewardsOnlyGauge.sol";
import "../../interfaces/balancer/IRewardsContract.sol";
import "../../interfaces/IPoolManagerLogic.sol";

library EasySwapperBalancerV2Helpers {
  function unrollBalancerGaugeAndGetUnsupportedLpAssets(
    address poolManagerLogic,
    address balancerGauge,
    address withdrawalAsset,
    address weth
  ) internal returns (address[] memory assets) {
    address lpToken = IRewardsOnlyGauge(balancerGauge).lp_token();
    address[] memory lpAssets;
    // If the pool also has the LP enabled, it will be unrolled upstream
    // beceause it has a lower assetType, so we skip.
    if (!IHasSupportedAsset(poolManagerLogic).isSupportedAsset(lpToken)) {
      lpAssets = unrollBalancerLpAndGetUnsupportedLpAssets(poolManagerLogic, lpToken, withdrawalAsset, weth);
    }

    uint256 rewardCount = IRewardsContract(IRewardsOnlyGauge(balancerGauge).reward_contract()).reward_count();
    assets = new address[](lpAssets.length + rewardCount);
    for (uint256 i = 0; i < rewardCount; i++) {
      assets[i] = IRewardsOnlyGauge(balancerGauge).reward_tokens(i);
    }

    for (uint256 i = 0; i < lpAssets.length; i++) {
      assets[rewardCount + i] = lpAssets[i];
    }
  }

  /// @notice Unrolls a multi asset balancer lp
  /// @dev Either unrolls to a single asset or all assets in the lp
  /// @param poolManagerLogic poolManagerLogic of the pool the swapper is withdrawing from
  /// @param balancerPool address of the LP
  /// @param withdrawalAsset the asset the user wants to withdraw to
  /// @param weth the address of weth
  function unrollBalancerLpAndGetUnsupportedLpAssets(
    address poolManagerLogic,
    address balancerPool,
    address withdrawalAsset,
    address weth
  ) internal returns (address[] memory assets) {
    uint256 balance = IERC20Extended(balancerPool).balanceOf(address(this));
    if (balance > 0) {
      IBalancerV2Vault vault = IBalancerV2Vault(IBalancerPool(balancerPool).getVault());
      bytes32 poolId = IBalancerPool(balancerPool).getPoolId();

      (address[] memory tokens, , ) = vault.getPoolTokens(poolId);
      address[] memory filteredTokens = filterLPAsset(tokens, balancerPool);

      uint8 withdrawalAssetIndex;
      uint8 hasWethIndex;
      uint8 supportedAssetIndex;

      for (uint8 i = 0; i < filteredTokens.length; ++i) {
        if (withdrawalAsset == filteredTokens[i]) {
          withdrawalAssetIndex = i + 1;
          // We break here because this is the optimal outcome
          break;
        } else if (weth == filteredTokens[i]) {
          hasWethIndex = i + 1;
        } else if (IHasSupportedAsset(poolManagerLogic).isSupportedAsset(filteredTokens[i])) {
          supportedAssetIndex = i + 1;
        }
      }

      bytes memory userData;
      if (withdrawalAssetIndex > 0) {
        userData = abi.encode(
          IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
          balance,
          withdrawalAssetIndex - 1
        );
        assets = new address[](0);
      } else if (hasWethIndex > 0) {
        userData = abi.encode(IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, balance, hasWethIndex - 1);
        assets = new address[](0);
      } else if (supportedAssetIndex > 0) {
        userData = abi.encode(IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, balance, 0);
        assets = new address[](0);
      } else {
        userData = abi.encode(IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, balance);
        assets = filteredTokens;
      }

      vault.exitPool(
        poolId,
        address(this),
        payable(address(this)),
        IBalancerV2Vault.ExitPoolRequest({
          assets: tokens,
          minAmountsOut: new uint256[](tokens.length),
          userData: userData,
          toInternalBalance: false
        })
      );
    }
  }

  /// @notice Composable pools include the lpAsset in the pool but don't count it as apart of the asset array when encoding userData
  /// @param assets all the assets in the pool
  /// @param lpAsset the lpAsset to filter
  /// @return newAssets all the assets in the pool except the lpAsset
  function filterLPAsset(address[] memory assets, address lpAsset) internal pure returns (address[] memory newAssets) {
    newAssets = new address[](assets.length);
    uint256 hits = 0;

    for (uint256 i = 0; i < assets.length; i++) {
      if (assets[i] != lpAsset) {
        newAssets[hits] = assets[i];
        hits++;
      }
    }
    uint256 reduceLength = newAssets.length - hits;
    assembly {
      mstore(newAssets, sub(mload(newAssets), reduceLength))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/synthetix/ISynthetix.sol";
import "../../interfaces/synthetix/ISynthAddressProxy.sol";
import "../../interfaces/uniswapV2/IUniswapV2RouterSwapOnly.sol";
import "../../interfaces/uniswapV2/IUniswapV2Router.sol";

library EasySwapperStructs {
  struct WithdrawProps {
    IUniswapV2RouterSwapOnly swapRouter;
    SynthetixProps synthetixProps;
    IERC20Extended weth;
    IERC20Extended nativeAssetWrapper;
  }

  struct SynthetixProps {
    ISynthetix snxProxy;
    IERC20Extended swapSUSDToAsset; // usdc or dai
    ISynthAddressProxy sUSDProxy;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/uniswapV2/IUniswapV2RouterSwapOnly.sol";
import "../../interfaces/IERC20Extended.sol";

library EasySwapperSwap {
  /// @notice Swaps from an asset to another asset
  /// @param swapRouter the swapRouter to use
  /// @param from asset to swap from
  /// @param to asset to swap to
  function swapThat(
    IUniswapV2RouterSwapOnly swapRouter,
    IERC20Extended from,
    IERC20Extended to
  ) internal {
    if (from == to) {
      return;
    }

    uint256 balance = from.balanceOf(address(this));

    if (balance > 0) {
      from.approve(address(swapRouter), balance);
      address[] memory path = new address[](2);
      path[0] = address(from);
      path[1] = address(to);
      swapRouter.swapExactTokensForTokens(balance, 0, path, address(this), uint256(-1));
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../guards/assetGuards/LyraOptionMarketWrapperAssetGuard.sol";
import "../../guards/contractGuards/LyraOptionMarketWrapperContractGuard.sol";

import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/synthetix/ISynthAddressProxy.sol";
import "../../interfaces/lyra/IOptionMarketViewer.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IHasSupportedAsset.sol";

import "./EasySwapperSwap.sol";
import "./EasySwapperStructs.sol";
import "./EasySwapperSynthetixHelpers.sol";

library EasySwapperSynthetixHelpers {
  /// @notice Determines which assets the swapper will have received when withdrawing from the pool
  /// @dev The pool unrolls lyra assets into the underlying assets and transfers them directly to the withdrawer, we need to know which assets the swapper received
  /// @param lyraOptionMarketWrapper the address of the lyra option market wrapper contract
  /// @param poolLogic used to determine if a rewardds token would have been received
  function getLyraWithdrawAssets(
    address lyraOptionMarketWrapper,
    address poolLogic,
    IERC20Extended withdrawalAsset,
    EasySwapperStructs.WithdrawProps memory withdrawProps
  ) internal returns (address[] memory assets) {
    address poolFactory = IPoolLogic(poolLogic).factory();
    IOptionMarketViewer marketViewer = LyraOptionMarketWrapperAssetGuard(
      IHasGuardInfo(poolFactory).getAssetGuard(lyraOptionMarketWrapper) // lyraAssetGuard
    ).marketViewer();
    LyraOptionMarketWrapperContractGuard.OptionPosition[] memory positions = LyraOptionMarketWrapperContractGuard(
      IHasGuardInfo(poolFactory).getContractGuard(lyraOptionMarketWrapper) // lyraContractGuard
    ).getOptionPositions(poolLogic);

    assets = new address[](positions.length * 2);
    uint256 hits = 0;

    for (uint256 i = 0; i < positions.length; i++) {
      IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = marketViewer.marketAddresses(
        positions[i].optionMarket
      );

      address[] memory assetOutQuote = EasySwapperSynthetixHelpers.getSynthetixOut(
        address(optionMarketAddresses.quoteAsset),
        withdrawalAsset,
        IHasAssetInfo(poolFactory),
        withdrawProps
      );
      if (assetOutQuote.length > 0) {
        assets[hits] = address(assetOutQuote[0]);
        hits++;
      }
      address[] memory assetOutBase = EasySwapperSynthetixHelpers.getSynthetixOut(
        address(optionMarketAddresses.baseAsset),
        withdrawalAsset,
        IHasAssetInfo(poolFactory),
        withdrawProps
      );
      if (assetOutBase.length > 0) {
        assets[hits] = address(assetOutBase[0]);
        hits++;
      }
    }

    uint256 reduceLength = assets.length - hits;
    assembly {
      mstore(assets, sub(mload(assets), reduceLength))
    }
  }

  /// @notice The logic for swapping synths to the withdrawalAsset
  /// @dev If withdrawing to a synth swap to it using Synthetix swap, otherwise swap to sUSD and then swap to withdrawalAsset
  /// @param synthAsset the address of the synth
  /// @param withdrawalAsset The withrawers expected out asset
  /// @return assets the intermidiary asset that the synth is exchanged to, that needs to be swapped upstream
  function getSynthetixOut(
    address synthAsset,
    IERC20Extended withdrawalAsset,
    IHasAssetInfo poolFactory,
    EasySwapperStructs.WithdrawProps memory withdrawProps
  ) internal returns (address[] memory assets) {
    uint256 balance = IERC20Extended(synthAsset).balanceOf(address(this));
    if (balance > 0) {
      // If withdrawalAsset is synth asset
      // We swap directly to the withdrawalAsset
      uint256 assetType = poolFactory.getAssetType(address(withdrawalAsset));
      if (assetType == 1 || assetType == 14) {
        if (synthAsset != address(withdrawalAsset)) {
          withdrawProps.synthetixProps.snxProxy.exchange(
            ISynthAddressProxy(synthAsset).target().currencyKey(),
            balance,
            ISynthAddressProxy(address(withdrawalAsset)).target().currencyKey()
          );
        }
        // Otherwise we swap first to sUSD (has most liquidity)
        // Then swap to the swapSUSDToAsset which shoudl be configured to an
        // asset that has good liquidity
      } else {
        if (address(withdrawProps.synthetixProps.sUSDProxy) != synthAsset) {
          withdrawProps.synthetixProps.snxProxy.exchange(
            ISynthAddressProxy(synthAsset).target().currencyKey(),
            balance,
            withdrawProps.synthetixProps.sUSDProxy.target().currencyKey()
          );
        }
        EasySwapperSwap.swapThat(
          withdrawProps.swapRouter,
          IERC20Extended(address(withdrawProps.synthetixProps.sUSDProxy)),
          withdrawProps.synthetixProps.swapSUSDToAsset
        );
        assets = new address[](1);
        assets[0] = address(withdrawProps.synthetixProps.swapSUSDToAsset);
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/uniswapV2/IUniswapV2Pair.sol";

library EasySwapperV2LpHelpers {
  using SafeMathUpgradeable for uint256;

  /// @notice Unrolls univ2 compatible LP to the underlying assets
  /// @dev Returns the underlying asset addresses so that can be swapped upstream
  /// @param lpAddress The address of the lp asset
  /// @return assets the assets in the v2 lp, that need to be swapped upstream
  function unrollLpsAndGetUnsupportedLpAssets(address lpAddress) internal returns (address[] memory assets) {
    uint256 bal = IERC20Extended(lpAddress).balanceOf(address(this));
    if (bal > 0) {
      address token0 = IUniswapV2Pair(lpAddress).token0();
      address token1 = IUniswapV2Pair(lpAddress).token1();
      IERC20Extended(lpAddress).transfer(lpAddress, bal);
      IUniswapV2Pair(lpAddress).burn(address(this));

      assets = new address[](2);
      assets[0] = token0;
      assets[1] = token1;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IPoolLogic.sol";

library EasySwapperV3Helpers {
  /// @notice Determines which assets the swapper will have received when withdrawing from the pool
  /// @dev The pool unrolls v3 lps into the underlying assets and transfers them directly to the withdrawer, we need to know which assets the swapper received
  /// @param pool the pool the swapper is withdrawing from
  /// @param nonfungiblePositionManager the uni v3 nonfungiblePositionManager
  /// @return assets the assets that the pool has/had in v3 lping positions, that need to be swapper upstream
  function getUnsupportedV3Assets(address pool, address nonfungiblePositionManager)
    internal
    view
    returns (address[] memory assets)
  {
    uint256 nftCount = INonfungiblePositionManager(nonfungiblePositionManager).balanceOf(pool);
    // Each position has two assets
    assets = new address[](nftCount * 2);
    for (uint256 i = 0; i < nftCount; ++i) {
      uint256 tokenId = INonfungiblePositionManager(nonfungiblePositionManager).tokenOfOwnerByIndex(pool, i);
      (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(nonfungiblePositionManager)
        .positions(tokenId);

      assets[i * 2] = token0;
      assets[i * 2 + 1] = token1;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasGuardInfo.sol";
import "../../interfaces/uniswapV2/IUniswapV2Pair.sol";
import "../../interfaces/velodrome/IVelodromeGauge.sol";
import "../../interfaces/velodrome/IVelodromeV2Gauge.sol";
import "../../guards/assetGuards/velodrome/VelodromeLPAssetGuard.sol";

library EasySwapperVelodromeLPHelpers {
  using SafeMathUpgradeable for uint256;

  /// @notice Unrolls univ2 compatible LP to the underlying assets
  /// @dev Returns the underlying asset addresses so that can be swapped upstream
  /// @param poolFactory The pool factory address
  /// @param lpAddress The address of the lp asset
  /// @param isV2 Whether the lp is a v2 lp or not
  /// @return assets the assets in the lp, that need to be swapped upstream, and the rewards tokens
  function unrollLpAndGetUnsupportedLpAssetsAndRewards(
    address poolFactory,
    address lpAddress,
    bool isV2
  ) internal returns (address[] memory assets) {
    uint256 lpBalance = IERC20Extended(lpAddress).balanceOf(address(this));
    if (lpBalance > 0) {
      address token0 = IUniswapV2Pair(lpAddress).token0();
      address token1 = IUniswapV2Pair(lpAddress).token1();
      // Burn is removeLiquidity.
      IERC20Extended(lpAddress).transfer(lpAddress, lpBalance);
      IUniswapV2Pair(lpAddress).burn(address(this));

      address gauge = VelodromeLPAssetGuard(IHasGuardInfo(poolFactory).getAssetGuard(lpAddress)).voter().gauges(
        lpAddress
      );
      uint256 rewardsListLength;
      if (gauge != address(0)) {
        // in Velodrome V2 gauges, there is only one reward token. Velodrome V1 gauges could have multiple reward tokens.
        rewardsListLength = isV2 ? 1 : IVelodromeGauge(gauge).rewardsListLength();
      }

      assets = new address[](2 + rewardsListLength);
      uint256 hits;

      assets[hits] = token0;
      hits++;

      assets[hits] = token1;
      hits++;

      if (gauge != address(0)) {
        if (isV2) {
          address rewardToken = IVelodromeV2Gauge(gauge).rewardToken();
          uint256 rewardBalance = IERC20Extended(rewardToken).balanceOf(address(this));
          if (rewardBalance > 0) {
            assets[hits] = rewardToken;
            hits++;
          }
        } else {
          for (uint256 i = 0; i < rewardsListLength; i++) {
            address rewardToken = IVelodromeGauge(gauge).rewards(i);
            uint256 rewardBalance = IERC20Extended(rewardToken).balanceOf(address(this));
            if (rewardBalance > 0) {
              assets[hits] = rewardToken;
              hits++;
            }
          }
        }

        uint256 reduceLength = assets.length.sub(hits);
        assembly {
          mstore(assets, sub(mload(assets), reduceLength))
        }
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Extended.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IPoolFactory.sol";
import "./EasySwapperV3Helpers.sol";
import "./EasySwapperV2LpHelpers.sol";
import "./EasySwapperSwap.sol";
import "./EasySwapperBalancerV2Helpers.sol";
import "./EasySwapperSynthetixHelpers.sol";
import "./EasySwapperVelodromeLPHelpers.sol";
import "./EasySwapperArrakisHelpers.sol";
import "./EasySwapperStructs.sol";

library EasySwapperWithdrawer {
  using SafeMathUpgradeable for uint160;
  using SafeMathUpgradeable for uint256;

  event Withdraw(
    address pool,
    uint256 fundTokenAmount,
    address withdrawalAsset,
    uint256 amountWithdrawnInWithdrawalAsset
  );

  /// @notice Withdraw underlying value of tokens into intermediate asset and then swap to susd
  /// @dev Helper function for dsnx
  /// @param recipient Who should receive the withdrawAsset
  /// @param pool dhedgepool to withdraw from
  /// @param fundTokenAmount the dhedgepool amount to withdraw
  /// @param intermediateAsset must have direct pair to all pool.supportedAssets on swapRouter and to SUSD
  /// @param finalAsset must have direct pair to withdrawWithIntermediate
  /// @param expectedAmountFinalAsset the amount of value in susd expected (slippage protection)
  /// @param withdrawProps passed down from the storage of the EasySwapper
  function withdrawWithIntermediate(
    address recipient,
    address pool,
    uint256 fundTokenAmount,
    IERC20Extended intermediateAsset,
    IERC20Extended finalAsset,
    uint256 expectedAmountFinalAsset,
    EasySwapperStructs.WithdrawProps memory withdrawProps
  ) internal {
    withdraw(address(this), pool, fundTokenAmount, intermediateAsset, 0, withdrawProps);

    EasySwapperSwap.swapThat(withdrawProps.swapRouter, intermediateAsset, finalAsset);

    uint256 balanceAfterSwaps = finalAsset.balanceOf(address(this));

    require(balanceAfterSwaps >= expectedAmountFinalAsset, "Withdraw Slippage detected");
    finalAsset.transfer(recipient, balanceAfterSwaps);
    emit Withdraw(pool, fundTokenAmount, address(finalAsset), balanceAfterSwaps);
  }

  /// @notice withdraw underlying value of tokens in expectedWithdrawalAssetOfUser
  /// @dev Swaps the underlying pool withdrawal assets to expectedWithdrawalAssetOfUser
  /// @param recipient Who should receive the withdrawAsset
  /// @param pool dhedgepool to withdraw from
  /// @param fundTokenAmount the dhedgepool amount to withdraw
  /// @param withdrawalAsset must have direct pair to all pool.supportedAssets on swapRouter
  /// @param expectedAmountOut the amount of value in the withdrawalAsset expected (slippage protection)
  /// @param withdrawProps passed down from the storage of the EasySwapper
  function withdraw(
    address recipient,
    address pool,
    uint256 fundTokenAmount,
    IERC20Extended withdrawalAsset,
    uint256 expectedAmountOut,
    EasySwapperStructs.WithdrawProps memory withdrawProps
  ) internal {
    IPoolLogic(pool).withdraw(fundTokenAmount);

    IHasSupportedAsset.Asset[] memory supportedAssets = IHasSupportedAsset(IPoolLogic(pool).poolManagerLogic())
      .getSupportedAssets();

    // What in all mother of hell is going on here?
    // Before we start swapping into our withdrawalAsset
    // We must unroll quick lps, sushi lps and balancer lps.
    // We must also return the assets these lp's are unrolled to
    // So that we can swap them also into our withdrawalAsset.
    // We also must detect which assets the pool had v3 lp in and
    // swap those into our withdrawalAsset.
    // We also must deal with pools that hold dUSD or toros.
    // We also must deal with pools that holder bal-dusd-usdc

    // We support balancer lp's with upto 5 assets :\
    // ie. USDC-LINK-WETH-BAL-AAVE

    address[] memory allBasicErc20s = new address[](supportedAssets.length * 5);
    uint8 hits;

    // Pools that have aave enabled withdraw weth to the user. This isnt in supportedAssets somestimes :(
    if (!IHasSupportedAsset(IPoolLogic(pool).poolManagerLogic()).isSupportedAsset(address(withdrawProps.weth))) {
      allBasicErc20s[hits] = address(withdrawProps.weth);
      hits++;
    }

    for (uint256 i = 0; i < supportedAssets.length; i++) {
      address asset = supportedAssets[i].asset;
      uint16 assetType = IHasAssetInfo(IPoolLogic(pool).factory()).getAssetType(asset);
      address[] memory unrolledAssets;

      // erc20 + lendingEnabled
      if (assetType == 0 || assetType == 4) {
        unrolledAssets = erc20Helper(asset, pool, withdrawalAsset, withdrawProps);
      }
      // Synthetix & Synthetix+LendingEnabled
      else if (assetType == 1 || assetType == 14) {
        // Can only withdraw into single Synth if all assets in pool are synths.
        // Can withdraw into non synth asset if mixed pool
        unrolledAssets = EasySwapperSynthetixHelpers.getSynthetixOut(
          asset,
          withdrawalAsset,
          IHasAssetInfo(IPoolLogic(pool).factory()),
          withdrawProps
        );
      }
      // Sushi V2 lp and Quick V2 lp
      else if (assetType == 2 || assetType == 5) {
        unrolledAssets = EasySwapperV2LpHelpers.unrollLpsAndGetUnsupportedLpAssets(asset);
      }
      // solhint-disable-next-line no-empty-blocks
      else if (assetType == 3 || assetType == 8) {
        // Aave do nothing
      }
      // Balancer Lp
      else if (assetType == 6) {
        unrolledAssets = EasySwapperBalancerV2Helpers.unrollBalancerLpAndGetUnsupportedLpAssets(
          IPoolLogic(pool).poolManagerLogic(),
          asset,
          address(withdrawalAsset),
          address(withdrawProps.weth)
        );
      }
      // Uni V3 Lp - already unrolled, just need the assets
      else if (assetType == 7) {
        unrolledAssets = EasySwapperV3Helpers.getUnsupportedV3Assets(pool, asset);
      } else if (assetType == 9) {
        unrolledAssets = EasySwapperArrakisHelpers.getArrakisAssets(asset);
      } else if (assetType == 10) {
        unrolledAssets = EasySwapperBalancerV2Helpers.unrollBalancerGaugeAndGetUnsupportedLpAssets(
          IPoolLogic(pool).poolManagerLogic(),
          asset,
          address(withdrawalAsset),
          address(withdrawProps.weth)
        );
        // Velo V1 and Ramses
      } else if (assetType == 15 || assetType == 20) {
        unrolledAssets = EasySwapperVelodromeLPHelpers.unrollLpAndGetUnsupportedLpAssetsAndRewards(
          IPoolLogic(pool).factory(),
          asset,
          false
        );
        // Velo V2
      } else if (assetType == 25) {
        unrolledAssets = EasySwapperVelodromeLPHelpers.unrollLpAndGetUnsupportedLpAssetsAndRewards(
          IPoolLogic(pool).factory(),
          asset,
          true
        );
        // Futures
      } else if (assetType == 101 || assetType == 102) {
        // All futures are settled in sUSD
        unrolledAssets = _arr(address(withdrawProps.synthetixProps.sUSDProxy));
      } else {
        revert("assetType not handled");
      }

      for (uint256 y = 0; y < unrolledAssets.length; y++) {
        allBasicErc20s[hits] = unrolledAssets[y];
        hits++;
      }
    }

    uint256 reduceLength = allBasicErc20s.length.sub(hits);
    assembly {
      mstore(allBasicErc20s, sub(mload(allBasicErc20s), reduceLength))
    }

    for (uint256 i = 0; i < allBasicErc20s.length; i++) {
      EasySwapperSwap.swapThat(withdrawProps.swapRouter, IERC20Extended(allBasicErc20s[i]), withdrawalAsset);
    }

    uint256 balanceAfterSwaps = withdrawalAsset.balanceOf(address(this));
    require(balanceAfterSwaps >= expectedAmountOut, "Withdraw Slippage detected");

    if (recipient != address(this)) {
      if (balanceAfterSwaps > 0) {
        IERC20Extended(address(withdrawalAsset)).transfer(recipient, balanceAfterSwaps);
      }
      emit Withdraw(pool, fundTokenAmount, address(withdrawalAsset), balanceAfterSwaps);
    }
  }

  /// @notice Unrolls internal dhedge pools or returns the asset
  /// @dev Because dhedge assets are type 0 we need to check all type 0 to see if it is a pool
  /// @param asset The address of the asset
  /// @param pool The top level dhedge pool being withdrew from
  /// @return unrolledAssets returns nothing when a dhedge pool, returns erc20 address otherwise
  function erc20Helper(
    address asset,
    address pool,
    IERC20Extended withdrawalAsset,
    EasySwapperStructs.WithdrawProps memory withdrawProps
  ) internal returns (address[] memory unrolledAssets) {
    uint256 balance = IPoolLogic(asset).balanceOf(address(this));
    if (balance > 0) {
      if (IPoolFactory(IPoolLogic(pool).factory()).isPool(asset) == true) {
        EasySwapperWithdrawer.withdraw(address(this), address(asset), balance, withdrawalAsset, 0, withdrawProps);
      } else {
        unrolledAssets = _arr(asset);
      }
    }
  }

  function _arr(address a) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = a;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../../guards/contractGuards/LyraOptionMarketWrapperContractGuard.sol";
import "../../interfaces/aave/v2/ILendingPool.sol";
import "../../interfaces/lyra/ILyraRegistry.sol";
import "../../interfaces/lyra/IOptionMarketViewer.sol";
import "../../interfaces/lyra/IOptionMarketWrapper.sol";
import "../../interfaces/lyra/IOptionToken.sol";
import "../../interfaces/lyra/ISynthetixAdapter.sol";
import "../../interfaces/lyra/IGWAVOracle.sol";
import "../../interfaces/synthetix/ISynthetix.sol";
import "../../interfaces/synthetix/IExchanger.sol";
import "../../interfaces/IPoolLogic.sol";
import "../../interfaces/IHasGuardInfo.sol";

contract DhedgeOptionMarketWrapperForLyra {
  using SafeMath for uint256;

  bytes32 public constant MARKET_VIEWER = "MARKET_VIEWER";
  bytes32 public constant MARKET_WRAPPER = "MARKET_WRAPPER";
  bytes32 public constant SYNTHETIX_ADAPTER = "SYNTHETIX_ADAPTER";

  ILyraRegistry public immutable lyraRegistry;
  ILendingPool public immutable aaveLendingPool;

  constructor(ILyraRegistry _lyraRegistry, address _aaveLendingPool) {
    lyraRegistry = _lyraRegistry;
    aaveLendingPool = ILendingPool(_aaveLendingPool);
  }

  function getOptionMarketViewer() public view returns (IOptionMarketViewer) {
    return IOptionMarketViewer(lyraRegistry.getGlobalAddress(MARKET_VIEWER));
  }

  function getOptionMarketWrapper() public view returns (IOptionMarketWrapper) {
    return IOptionMarketWrapper(lyraRegistry.getGlobalAddress(MARKET_WRAPPER));
  }

  function getSynthetixAdapter() public view returns (ISynthetixAdapter) {
    return ISynthetixAdapter(lyraRegistry.getGlobalAddress(SYNTHETIX_ADAPTER));
  }

  function _encodeCloseParams(
    IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses,
    IOptionToken.OptionPosition memory position,
    uint256 portion
  ) internal pure returns (IOptionMarketWrapper.OptionPositionParams memory params) {
    return
      IOptionMarketWrapper.OptionPositionParams({
        optionMarket: IOptionMarket(optionMarketAddresses.optionMarket),
        strikeId: position.strikeId,
        positionId: position.positionId,
        iterations: 1,
        currentCollateral: position.collateral,
        setCollateralTo: position.collateral.sub(position.collateral.mul(portion).div(10**18)),
        optionType: position.optionType,
        amount: position.amount.mul(portion).div(10**18),
        minCost: 0,
        maxCost: type(uint256).max,
        inputAmount: 0,
        inputAsset: IERC20(optionMarketAddresses.quoteAsset)
      });
  }

  /// @notice This function is to close lyra option position - called from PoolLogic contract
  /// @dev the original Lyra close/forceClose position functions doesn't accept recipient address
  ///      this function will accept a recipient address and withdraw the funds to the recipient directly.
  /// @param dhedgeStoredPosition the position information dhedge stores
  /// @param portion the portion of the withdrawer
  /// @param recipient the recipient address for withdrawn funds
  function tryCloseAndForceClosePosition(
    LyraOptionMarketWrapperContractGuard.OptionPosition memory dhedgeStoredPosition,
    uint256 portion,
    address recipient
  ) external {
    IOptionMarketViewer.OptionMarketAddresses memory optionMarketAddresses = getOptionMarketViewer().marketAddresses(
      address(dhedgeStoredPosition.optionMarket)
    );
    IOptionToken.OptionPosition memory position = optionMarketAddresses.optionToken.positions(
      dhedgeStoredPosition.positionId
    );

    IOptionMarketWrapper.OptionPositionParams memory closeParams = _encodeCloseParams(
      optionMarketAddresses,
      position,
      portion
    );

    if (
      closeParams.optionType == IOptionMarket.OptionType.SHORT_CALL_BASE ||
      closeParams.optionType == IOptionMarket.OptionType.SHORT_CALL_QUOTE ||
      closeParams.optionType == IOptionMarket.OptionType.SHORT_PUT_QUOTE
    ) {
      // check minimum collateral amount after withdraw
      (uint256 strikePrice, uint256 expiry) = closeParams.optionMarket.getStrikeAndExpiry(position.strikeId);
      uint256 spotPrice = getSynthetixAdapter().getSpotPriceForMarket(address(closeParams.optionMarket));
      uint256 minCollateralAfterWithdraw = optionMarketAddresses.greekCache.getMinCollateral(
        closeParams.optionType,
        strikePrice,
        expiry,
        spotPrice,
        position.amount.sub(closeParams.amount)
      );

      // check if the position collateral is less than the minimum collateral amount
      // then it will close position fully and withdraw to the pool address directly
      if (closeParams.setCollateralTo < minCollateralAfterWithdraw) {
        closeParams.setCollateralTo = 0;
        closeParams.amount = position.amount;
        recipient = msg.sender;
      }
    }

    IOptionMarketWrapper optionMarketWrapper = getOptionMarketWrapper();

    optionMarketAddresses.optionToken.approve(address(optionMarketWrapper), closeParams.positionId);
    if (closeParams.optionType == IOptionMarket.OptionType.SHORT_CALL_BASE) {
      // to close SHORT_CALL_BASE options, it requires to provide option fees in quote asset.
      // 1. we flashloan quote asset from Aave
      // 2. close option position
      // 3. we get base asset once we close the option position.
      // 4. we swap base asset into quote asset to repay flahsloan amount + premium

      uint256 amountToFlashloan = getAmountOfQuoteToBorrow(closeParams);

      address[] memory borrowAssets = new address[](1);
      borrowAssets[0] = address(optionMarketAddresses.quoteAsset);
      uint256[] memory borrowAmounts = new uint256[](1);
      borrowAmounts[0] = amountToFlashloan;
      uint256[] memory modes = new uint256[](1);
      bytes memory flashloanParams = abi.encode(closeParams);
      aaveLendingPool.flashLoan(address(this), borrowAssets, borrowAmounts, modes, address(this), flashloanParams, 196);
    } else {
      // solhint-disable-next-line no-empty-blocks
      try optionMarketWrapper.closePosition(closeParams) {} catch {
        optionMarketWrapper.forceClosePosition(closeParams);
      }
    }

    // transfer withdrawn assets to recipient
    optionMarketAddresses.quoteAsset.transfer(recipient, optionMarketAddresses.quoteAsset.balanceOf(address(this)));
    optionMarketAddresses.baseAsset.transfer(recipient, optionMarketAddresses.baseAsset.balanceOf(address(this)));

    // transfer position nft back to msg.sender
    if (
      optionMarketAddresses.optionToken.getPositionState(closeParams.positionId) == IOptionToken.PositionState.ACTIVE
    ) {
      optionMarketAddresses.optionToken.transferFrom(address(this), msg.sender, closeParams.positionId);
    } else {
      address poolLogic = msg.sender;
      address factory = IPoolLogic(poolLogic).factory();
      address lyraOptionMarketWrapperContractGuard = IHasGuardInfo(factory).getContractGuard(
        address(optionMarketWrapper)
      );
      LyraOptionMarketWrapperContractGuard(lyraOptionMarketWrapperContractGuard).removeClosedPosition(
        poolLogic,
        address(closeParams.optionMarket),
        closeParams.positionId
      );
    }
  }

  /// @notice execute function of aave flash loan
  /// @dev This function is called after your contract has received the flash loaned amount
  /// @param assets the loaned assets
  /// @param amounts the loaned amounts per each asset
  /// @param premiums the additional owed amount per each asset
  /// @param originator the origin caller address of the flash loan
  /// @param params Variadic packed params to pass to the receiver as extra information
  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address originator,
    bytes memory params
  ) external returns (bool success) {
    require(msg.sender == address(aaveLendingPool) && originator == address(this), "invalid flashloan origin");
    require(assets.length == 1 && amounts.length == 1 && premiums.length == 1, "invalid length");

    IOptionMarketWrapper optionMarketWrapper = getOptionMarketWrapper();
    IOptionMarketWrapper.OptionPositionParams memory closeParams = abi.decode(
      params,
      (IOptionMarketWrapper.OptionPositionParams)
    );
    IOptionMarketWrapper.OptionMarketContracts memory optionMarketAddresses = optionMarketWrapper.marketContracts(
      closeParams.optionMarket
    );

    require(assets[0] == address(optionMarketAddresses.quoteAsset), "invalid asset");

    // close option position
    {
      optionMarketAddresses.quoteAsset.approve(address(optionMarketWrapper), amounts[0]);
      closeParams.inputAmount = amounts[0];
      // solhint-disable-next-line no-empty-blocks
      try optionMarketWrapper.closePosition(closeParams) {} catch {
        optionMarketWrapper.forceClosePosition(closeParams);
      }
    }

    // swap base assets to quote assets
    {
      uint256 baseAssetAmount = optionMarketAddresses.baseAsset.balanceOf(address(this));
      ISynthetixAdapter synthetixAdapter = getSynthetixAdapter();
      bytes32 synthQuoteKey = synthetixAdapter.quoteKey(address(closeParams.optionMarket));
      bytes32 synthBaseKey = synthetixAdapter.baseKey(address(closeParams.optionMarket));
      address synthetix = synthetixAdapter.synthetix();
      optionMarketAddresses.baseAsset.approve(synthetix, baseAssetAmount);
      ISynthetix(synthetix).exchange(synthBaseKey, baseAssetAmount, synthQuoteKey);
    }

    // payback amounts + premiums
    {
      optionMarketAddresses.quoteAsset.approve(address(aaveLendingPool), amounts[0].add(premiums[0]));
    }

    return true;
  }

  function getAmountOfQuoteToBorrow(IOptionMarketWrapper.OptionPositionParams memory closeParams)
    public
    view
    returns (uint256)
  {
    uint256 expectedCollateralReturned = closeParams.currentCollateral - closeParams.setCollateralTo;
    ISynthetixAdapter synthetixAdapter = getSynthetixAdapter();
    bytes32 synthQuoteKey = synthetixAdapter.quoteKey(address(closeParams.optionMarket));
    bytes32 synthBaseKey = synthetixAdapter.baseKey(address(closeParams.optionMarket));
    IExchanger exchanger = synthetixAdapter.exchanger();
    (uint256 amountReceived, , ) = exchanger.getAmountsForExchange(
      expectedCollateralReturned,
      synthBaseKey,
      synthQuoteKey
    );
    // we return 99% because we need a margin to cover flash fees
    return amountReceived.mul(99).div(100);
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
  function _addData(
    bytes32 _nftType,
    address _pool,
    bytes memory _data
  ) private {
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
  function _removeData(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) private {
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
  function getData(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external view returns (bytes memory) {
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

  function removeDataByUintId(
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external onlyOwner {
    bytes[] memory data = getAllData(_nftType, _pool);
    for (uint256 i = 0; i < data.length; i++) {
      if (abi.decode(data[i], (uint256)) == _nftID) {
        _removeData(_nftType, _pool, i);
        return;
      }
    }
    revert("not found");
  }

  function removeDataByIndex(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external onlyOwner {
    _removeData(_nftType, _pool, _index);
  }

  function addDataByUintId(
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external onlyOwner {
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

  function getBytes(
    bytes memory data,
    uint8 inputNum,
    uint256 offset
  ) public pure returns (bytes memory) {
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

  function getArrayIndex(
    bytes memory data,
    uint8 inputNum,
    uint8 arrayIndex
  ) public pure returns (bytes32) {
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

  function read32(
    bytes memory data,
    uint256 offset,
    uint256 length
  ) public pure returns (bytes32 o) {
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