// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ICore {
    /* ========== Event ========== */
    event MarketSupply(address user, address gToken, uint256 uAmount);
    event MarketRedeem(address user, address gToken, uint256 uAmount);

    event MarketListed(address gToken);
    event MarketEntered(address gToken, address account);
    event MarketExited(address gToken, address account);

    event CloseFactorUpdated(uint256 newCloseFactor);
    event CollateralFactorUpdated(address gToken, uint256 newCollateralFactor);
    event LiquidationIncentiveUpdated(uint256 newLiquidationIncentive);
    event SupplyCapUpdated(address indexed gToken, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gToken, uint256 newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event NftCoreUpdated(address newNftCore);
    event ValidatorUpdated(address newValidator);
    event GRVDistributorUpdated(address newGRVDistributor);
    event RebateDistributorUpdated(address newRebateDistributor);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    function nftCore() external view returns (address);

    function validator() external view returns (address);

    function rebateDistributor() external view returns (address);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address gToken) external view returns (Constant.MarketInfo memory);

    function checkMembership(address account, address gToken) external view returns (bool);

    function accountLiquidityOf(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function closeFactor() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function enterMarkets(address[] memory gTokens) external;

    function exitMarket(address gToken) external;

    function supply(address gToken, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address gToken, uint256 gTokenAmount) external returns (uint256 redeemed);

    function redeemUnderlying(address gToken, uint256 underlyingAmount) external returns (uint256 redeemed);

    function borrow(address gToken, uint256 amount) external;

    function nftBorrow(address gToken, address user, uint256 amount) external;

    function repayBorrow(address gToken, uint256 amount) external payable;

    function nftRepayBorrow(address gToken, address user, uint256 amount) external payable;

    function repayBorrowBehalf(address gToken, address borrower, uint256 amount) external payable;

    function liquidateBorrow(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external payable;

    function claimGRV() external;

    function claimGRV(address market) external;

    function compoundGRV() external;

    function firstDepositGRV(uint256 expiry) external;

    function transferTokens(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IDashboard {
    struct VaultData {
        uint256 totalCirculation;
        uint256 totalLockedGrv;
        uint256 totalVeGrv;
        uint256 averageLockDuration;
        uint256 accruedGrv;
        uint256 claimedGrv;
        uint256[] thisWeekRebatePoolAmounts;
        address[] thisWeekRebatePoolMarkets;
        uint256 thisWeekRebatePoolValue;
        Constant.EcoZone ecoZone;
        uint256 claimTax;
        uint256 ppt;
        uint256 ecoDR;
        uint256 lockedBalance;
        uint256 lockDuration;
        uint256 firstLockTime;
        uint256 myVeGrv;
        uint256 vp;
        RebateData rebateData;
    }

    struct RebateData {
        uint256 weeklyProfit;
        uint256 unClaimedRebateValue;
        address[] unClaimedMarkets;
        uint256[] unClaimedRebatesAmount;
        uint256 claimedRebateValue;
        address[] claimedMarkets;
        uint256[] claimedRebatesAmount;
    }
    struct CompoundData {
        ExpectedTaxData taxData;
        ExpectedEcoScoreData ecoScoreData;
        ExpectedVeGrv veGrvData;
        BoostedAprData boostedAprData;
        uint256 accruedGrv;
        uint256 lockDuration;
        uint256 nextLockDuration;
    }

    struct LockData {
        ExpectedEcoScoreData ecoScoreData;
        ExpectedVeGrv veGrvData;
        BoostedAprData boostedAprData;
        uint256 lockedGrv;
        uint256 lockDuration;
        uint256 nextLockDuration;
    }

    struct ClaimData {
        ExpectedEcoScoreData ecoScoreData;
        ExpectedTaxData taxData;
        uint256 accruedGrv;
    }

    struct ExpectedTaxData {
        uint256 prevPPTRate;
        uint256 nextPPTRate;
        uint256 prevClaimTaxRate;
        uint256 nextClaimTaxRate;
        uint256 discountTaxRate;
        uint256 afterTaxesGrv;
    }

    struct ExpectedEcoScoreData {
        Constant.EcoZone prevEcoZone;
        Constant.EcoZone nextEcoZone;
        uint256 prevEcoDR;
        uint256 nextEcoDR;
    }

    struct ExpectedVeGrv {
        uint256 prevVeGrv;
        uint256 prevVotingPower;
        uint256 nextVeGrv;
        uint256 nextVotingPower;
        uint256 nextWeeklyRebate;
        uint256 prevWeeklyRebate;
    }

    struct BoostedAprParams {
        address account;
        uint256 amount;
        uint256 expiry;
        Constant.EcoScorePreviewOption option;
    }

    struct BoostedAprData {
        BoostedAprDetails[] boostedAprDetailList;
    }
    struct BoostedAprDetails {
        address market;
        uint256 currentSupplyApr;
        uint256 currentBorrowApr;
        uint256 expectedSupplyApr;
        uint256 expectedBorrowApr;
    }

    function getCurrentGRVPrice() external view returns (uint256);
    function getVaultInfo(address account) external view returns (VaultData memory);
    function getLockUnclaimedGrvModalInfo(address account) external view returns (CompoundData memory);

    function getInitialLockUnclaimedGrvModalInfo(
        address account,
        uint256 expiry
    ) external view returns (CompoundData memory);

    function getLockModalInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (LockData memory);

    function getClaimModalInfo(address account) external view returns (ClaimData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IEcoScore {
    event SetGRVDistributor(address newGRVDistributor);
    event SetPriceProtectionTaxCalculator(address newPriceProtectionTaxCalculator);
    event SetPriceCalculator(address priceCalculator);
    event SetLendPoolLoan(address lendPoolLoan);
    event SetEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event SetAccountCustomEcoPolicy(
        address indexed account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] _pptTax
    );
    event RemoveAccountCustomEcoPolicy(address indexed account);
    event ExcludeAccount(address indexed account);
    event IncludeAccount(address indexed account);
    event SetEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    );
    event SetPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4);

    function setGRVDistributor(address _grvDistributor) external;

    function setPriceProtectionTaxCalculator(address _priceProtectionTaxCalculator) external;

    function setPriceCalculator(address _priceCalculator) external;

    function setLendPoolLoan(address _lendPoolLoan) external;

    function setEcoPolicyInfo(
        Constant.EcoZone _zone,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setAccountCustomEcoPolicy(
        address account,
        uint256 _boostMultiple,
        uint256 _maxBoostCap,
        uint256 _boostBase,
        uint256 _redeemFee,
        uint256 _claimTax,
        uint256[] calldata _pptTax
    ) external;

    function setEcoZoneStandard(
        uint256 _minExpiryOfGreenZone,
        uint256 _minExpiryOfLightGreenZone,
        uint256 _minDrOfGreenZone,
        uint256 _minDrOfLightGreenZone,
        uint256 _minDrOfYellowZone,
        uint256 _minDrOfOrangeZone
    ) external;

    function setPPTPhaseInfo(uint256 _phase1, uint256 _phase2, uint256 _phase3, uint256 _phase4) external;

    function removeAccountCustomEcoPolicy(address account) external;

    function excludeAccount(address account) external;

    function includeAccount(address account) external;

    function calculateEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculateEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) external view returns (uint256);

    function calculatePreEcoBoostedSupply(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculatePreEcoBoostedBorrow(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore,
        Constant.EcoZone ecoZone
    ) external view returns (uint256);

    function calculateCompoundTaxes(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function calculateClaimTaxes(
        address account,
        uint256 value
    ) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function getClaimTaxRate(
        address account,
        uint256 value,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256);

    function getDiscountTaxRate(address account) external view returns (uint256);

    function getPptTaxRate(Constant.EcoZone ecoZone) external view returns (uint256 pptTaxRate, uint256 gapPercent);

    function getEcoZone(uint256 ecoDRpercent, uint256 remainExpiry) external view returns (Constant.EcoZone ecoZone);

    function updateUserClaimInfo(address account, uint256 amount) external;

    function updateUserCompoundInfo(address account, uint256 amount) external;

    function updateUserEcoScoreInfo(address account) external;

    function accountEcoScoreInfoOf(address account) external view returns (Constant.EcoScoreInfo memory);

    function ecoPolicyInfoOf(Constant.EcoZone zone) external view returns (Constant.EcoPolicyInfo memory);

    function calculatePreUserEcoScoreInfo(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (Constant.EcoZone ecoZone, uint256 ecoDR, uint256 userScore);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGRVDistributor {
    /* ========== EVENTS ========== */
    event SetCore(address core);
    event SetPriceCalculator(address priceCalculator);
    event SetEcoScore(address ecoScore);
    event SetTaxTreasury(address treasury);
    event GRVDistributionSpeedUpdated(address indexed gToken, uint256 supplySpeed, uint256 borrowSpeed);
    event GRVClaimed(address indexed user, uint256 amount);
    event GRVCompound(
        address indexed account,
        uint256 amount,
        uint256 adjustedValue,
        uint256 taxAmount,
        uint256 expiry
    );
    event SetDashboard(address dashboard);
    event SetLendPoolLoan(address lendPoolLoan);

    function approve(address _spender, uint256 amount) external returns (bool);

    function accruedGRV(address[] calldata markets, address account) external view returns (uint256);

    function distributionInfoOf(address market) external view returns (Constant.DistributionInfo memory);

    function accountDistributionInfoOf(
        address market,
        address account
    ) external view returns (Constant.DistributionAccountInfo memory);

    function apyDistributionOf(address market, address account) external view returns (Constant.DistributionAPY memory);

    function boostedRatioOf(
        address market,
        address account
    ) external view returns (uint256 boostedSupplyRatio, uint256 boostedBorrowRatio);

    function notifySupplyUpdated(address market, address user) external;

    function notifyBorrowUpdated(address market, address user) external;

    function notifyTransferred(address gToken, address sender, address receiver) external;

    function claimGRV(address[] calldata markets, address account) external;

    function compound(address[] calldata markets, address account) external;

    function firstDeposit(address[] calldata markets, address account, uint256 expiry) external;

    function kick(address user) external;
    function kicks(address[] calldata users) external;

    function updateAccountBoostedInfo(address user) external;
    function updateAccountBoostedInfos(address[] calldata users) external;

    function getTaxTreasury() external view returns (address);

    function getPreEcoBoostedInfo(
        address market,
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256 boostedSupply, uint256 boostedBorrow);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface IGToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint256);

    function accountSnapshot(address account) external view returns (Constant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function _totalBorrow() external view returns (uint256);

    function totalReserve() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function lastAccruedTime() external view returns (uint256);

    function accInterestIndex() external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getCash() external view returns (uint256);

    function getRateModel() external view returns (address);

    function getAccInterestIndex() external view returns (uint256);

    function accruedAccountSnapshot(address account) external returns (Constant.AccountSnapshot memory);

    function accruedBorrowBalanceOf(address account) external returns (uint256);

    function accruedTotalBorrow() external returns (uint256);

    function accruedExchangeRate() external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function supply(address account, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address account, uint256 gTokenAmount) external returns (uint256);

    function redeemUnderlying(address account, uint256 underlyingAmount) external returns (uint256);

    function borrow(address account, uint256 amount) external returns (uint256);

    function repayBorrow(address account, uint256 amount) external payable returns (uint256);

    function repayBorrowBehalf(address payer, address borrower, uint256 amount) external payable returns (uint256);

    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    ) external payable returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function seize(address liquidator, address borrower, uint256 gTokenAmount) external;

    function withdrawReserves() external;

    function transferTokensInternal(address spender, address src, address dst, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ILendPoolLoan {
    /* ========== Event ========== */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    );

    event LoanUpdated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amountAdded,
        uint256 amountTaken
    );

    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 bidBorrowAmount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice,
        uint256 floorPrice
    );

    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 repayAmount
    );

    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event AuctionDurationUpdated(
        uint256 newAuctionDuration
    );

    event MinBidFineUpdated(
        uint256 newMinBidFine
    );

    event RedeemFineRateUpdated(
        uint256 newRedeemFineRate
    );

    event RedeemThresholdUpdated(
        uint256 newRedeemThreshold
    );

    event BorrowRateMultiplierUpdated(
        uint256 borrowRateMultiplier
    );

    event AuctionFeeRateUpdated(
        uint256 auctionFeeRate
    );

    function createLoan(
        address to,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    ) external returns (uint256);

    function updateLoan(
        uint256 loanId,
        uint256 amountAdded,
        uint256 amountTaken
    ) external;

    function repayLoan(
        uint256 loanId,
        address gNft,
        uint256 amount
    ) external;

    function auctionLoan(
        address bidder,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    function redeemLoan(
        uint256 loanId,
        uint256 amountTaken
    ) external;

    function liquidateLoan(
        address gNft,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function initNft(address nftAsset, address gNft) external;
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);
    function getNftCollateralAmount(address nftAsset) external view returns (uint256);
    function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);
    function getLoan(uint256 loanId) external view returns (Constant.LoanData memory loanData);

    function borrowBalanceOf(uint256 loanId) external view returns (uint256);
    function userBorrowBalance(address user) external view returns (uint256);
    function marketBorrowBalance(address gNft) external view returns (uint256);
    function marketAccountBorrowBalance(address gNft, address user) external view returns (uint256);
    function accrueInterest() external;
    function totalBorrow() external view returns (uint256);
    function currentLoanId() external view returns (uint256);
    function getAccInterestIndex() external view returns (uint256);

    function auctionDuration() external view returns (uint256);
    function minBidFine() external view returns (uint256);
    function redeemFineRate() external view returns (uint256);
    function redeemThreshold() external view returns (uint256);

    function auctionFeeRate() external view returns (uint256);
    function accInterestIndex() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/Constant.sol";

interface ILocker {
    event GRVDistributorUpdated(address newGRVDistributor);

    event RebateDistributorUpdated(address newRebateDistributor);

    event Pause();

    event Unpause();

    event Deposit(address indexed account, uint256 amount, uint256 expiry);

    event ExtendLock(address indexed account, uint256 nextExpiry);

    event Withdraw(address indexed account);

    event WithdrawAndLock(address indexed account, uint256 expiry);

    event DepositBehalf(address caller, address indexed account, uint256 amount, uint256 expiry);

    event WithdrawBehalf(address caller, address indexed account);

    event WithdrawAndLockBehalf(address caller, address indexed account, uint256 expiry);

    function scoreOfAt(address account, uint256 timestamp) external view returns (uint256);

    function lockInfoOf(address account) external view returns (Constant.LockInfo[] memory);

    function firstLockTimeInfoOf(address account) external view returns (uint256);

    function setGRVDistributor(address _grvDistributor) external;

    function setRebateDistributor(address _rebateDistributor) external;

    function pause() external;

    function unpause() external;

    function totalBalance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function expiryOf(address account) external view returns (uint256);

    function availableOf(address account) external view returns (uint256);

    function getLockUnitMax() external view returns (uint256);

    function totalScore() external view returns (uint256 score, uint256 slope);

    function scoreOf(address account) external view returns (uint256);

    function truncateExpiry(uint256 time) external view returns (uint256);

    function deposit(uint256 amount, uint256 unlockTime) external;

    function extendLock(uint256 expiryTime) external;

    function withdraw() external;

    function withdrawAndLock(uint256 expiry) external;

    function depositBehalf(address account, uint256 amount, uint256 unlockTime) external;

    function withdrawBehalf(address account) external;

    function withdrawAndLockBehalf(address account, uint256 expiry) external;

    function preScoreOf(
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view returns (uint256);

    function remainExpiryOf(address account) external view returns (uint256);

    function preRemainExpiryOf(uint256 expiry) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IPriceCalculator {
    struct ReferenceData {
        uint256 lastData;
        uint256 lastUpdated;
    }

    function priceOf(address asset) external view returns (uint256);

    function pricesOf(address[] memory assets) external view returns (uint256[] memory);

    function priceOfETH() external view returns (uint256);

    function getUnderlyingPrice(address gToken) external view returns (uint256);

    function getUnderlyingPrices(address[] memory gTokens) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library Constant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;
    uint256 public constant LIQUIDATION_THRESHOLD_MAX = 9e17;
    uint256 public constant LIQUIDATION_BONUS_MAX = 5e17;
    uint256 public constant AUCTION_DURATION_MAX = 7 days;
    uint256 public constant MIN_BID_FINE_MAX = 100 ether;
    uint256 public constant REDEEM_FINE_RATE_MAX = 5e17;
    uint256 public constant REDEEM_THRESHOLD_MAX = 9e17;
    uint256 public constant BORROW_RATE_MULTIPLIER_MAX = 1e19;
    uint256 public constant AUCTION_FEE_RATE_MAX = 5e17;

    enum EcoZone {
        RED,
        ORANGE,
        YELLOW,
        LIGHTGREEN,
        GREEN
    }

    enum EcoScorePreviewOption {
        LOCK,
        CLAIM,
        EXTEND,
        LOCK_MORE
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address gNft;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowAmount;
        uint256 interestIndex;

        uint256 bidStartTimestamp;
        address bidderAddress;
        uint256 bidPrice;
        uint256 bidBorrowAmount;
        uint256 floorPrice;
        uint256 bidCount;
        address firstBidderAddress;
    }

    struct MarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct NftMarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 gTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct AccrueLoanSnapshot {
        uint256 totalBorrow;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedGRV; // Unclaimed GRV rewards amount
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 apyAccountSupplyGRV;
        uint256 apyAccountBorrowGRV;
    }

    struct EcoScoreInfo {
        uint256 claimedGrv;
        uint256 ecoDR;
        EcoZone ecoZone;
        uint256 compoundGrv;
        uint256 changedEcoZoneAt;
    }

    struct BoostConstant {
        uint256 boost_max;
        uint256 boost_portion;
        uint256 ecoBoost_portion;
    }

    struct RebateCheckpoint {
        uint256 timestamp;
        uint256 totalScore;
        uint256 adminFeeRate;
        mapping(address => uint256) amount;
    }

    struct RebateClaimInfo {
        uint256 timestamp;
        address[] markets;
        uint256[] amount;
        uint256[] prices;
        uint256 value;
    }

    struct LockInfo {
        uint256 timestamp;
        uint256 amount;
        uint256 expiry;
    }

    struct EcoPolicyInfo {
        uint256 boostMultiple;
        uint256 maxBoostCap;
        uint256 boostBase;
        uint256 redeemFee;
        uint256 claimTax;
        uint256[] pptTax;
    }

    struct EcoZoneStandard {
        uint256 minExpiryOfGreenZone;
        uint256 minExpiryOfLightGreenZone;
        uint256 minDrOfGreenZone;
        uint256 minDrOfLightGreenZone;
        uint256 minDrOfYellowZone;
        uint256 minDrOfOrangeZone;
    }

    struct PPTPhaseInfo {
        uint256 phase1;
        uint256 phase2;
        uint256 phase3;
        uint256 phase4;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/SafeToken.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/IGRVDistributor.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/ICore.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IEcoScore.sol";
import "../interfaces/IDashboard.sol";
import "../interfaces/ILendPoolLoan.sol";

contract GRVDistributor is IGRVDistributor, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 private constant LAUNCH_TIMESTAMP = 1681117200;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    ILocker public locker;
    IPriceCalculator public priceCalculator;
    IEcoScore public ecoScore;
    IDashboard public dashboard;
    ILendPoolLoan public lendPoolLoan;

    mapping(address => Constant.DistributionInfo) public distributions; // Market => DistributionInfo
    mapping(address => mapping(address => Constant.DistributionAccountInfo)) // Market => Account => DistributionAccountInfo
        public accountDistributions; // 토큰별, 유저별 distribution 정보
    mapping(address => uint256) public kickInfo; // user kick count stored

    address public GRV;
    address public taxTreasury;

    /* ========== MODIFIERS ========== */

    /// @notice timestamp에 따른 distribution 정보 갱신
    /// @dev 마지막 time과 비교하여 시간이 지난 경우 해당 시간만큼 쌓인 이자를 계산하여 accPerShareSupply 값을 갱신시켜준다.
    /// @param market gToken address
    modifier updateDistributionOf(address market) {
        Constant.DistributionInfo storage dist = distributions[market];
        if (dist.accruedAt == 0) {
            dist.accruedAt = block.timestamp;
        }

        uint256 timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (timeElapsed > 0) {
            if (dist.totalBoostedSupply > 0) {
                dist.accPerShareSupply = dist.accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );
            }
            if (dist.totalBoostedBorrow > 0) {
                dist.accPerShareBorrow = dist.accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );
            }
        }
        dist.accruedAt = block.timestamp;
        _;
    }

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyCore() {
        require(msg.sender == address(core), "GRVDistributor: caller is not Core");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize(
        address _grvTokenAddress,
        address _core,
        address _locker,
        address _priceCalculator
    ) external initializer {
        require(_grvTokenAddress != address(0), "GRVDistributor: grv address can't be zero");
        require(_core != address(0), "GRVDistributor: core address can't be zero");
        require(address(locker) == address(0), "GRVDistributor: locker already set");
        require(address(core) == address(0), "GRVDistributor: core already set");
        require(_locker != address(0), "GRVDistributor: locker address can't be zero");
        require(_priceCalculator != address(0), "GRVDistributor: priceCalculator address can't be zero");

        __Ownable_init();
        __ReentrancyGuard_init();

        GRV = _grvTokenAddress;
        core = ICore(_core);
        locker = ILocker(_locker);
        priceCalculator = IPriceCalculator(_priceCalculator);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function approve(address _spender, uint256 amount) external override onlyOwner returns (bool) {
        GRV.safeApprove(_spender, amount);
        return true;
    }

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) public onlyOwner {
        require(_core != address(0), "GRVDistributor: invalid core address");
        require(address(core) == address(0), "GRVDistributor: core already set");
        core = ICore(_core);

        emit SetCore(_core);
    }

    /// @notice priceCalculator address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _priceCalculator priceCalculator contract address
    function setPriceCalculator(address _priceCalculator) public onlyOwner {
        require(_priceCalculator != address(0), "GRVDistributor: invalid priceCalculator address");
        priceCalculator = IPriceCalculator(_priceCalculator);

        emit SetPriceCalculator(_priceCalculator);
    }

    /// @notice EcoScore address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    /// @param _ecoScore EcoScore contract address
    function setEcoScore(address _ecoScore) public onlyOwner {
        require(_ecoScore != address(0), "GRVDistributor: invalid ecoScore address");
        ecoScore = IEcoScore(_ecoScore);

        emit SetEcoScore(_ecoScore);
    }

    /// @notice dashboard contract 변경
    /// @dev owner address 에서만 요청 가능
    /// @param _dashboard dashboard contract address
    function setDashboard(address _dashboard) public onlyOwner {
        require(_dashboard != address(0), "GRVDistributor: invalid dashboard address");
        dashboard = IDashboard(_dashboard);

        emit SetDashboard(_dashboard);
    }

    function setTaxTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "GRVDistributor: Tax Treasury can't be zero address");
        taxTreasury = _treasury;
        emit SetTaxTreasury(_treasury);
    }

    /// @notice gToken 의 supplySpeed, borrowSpeed 설정
    /// @dev owner 만 실행 가능
    /// @param gToken gToken address
    /// @param supplySpeed New supply speed
    /// @param borrowSpeed New borrow speed
    function setGRVDistributionSpeed(
        address gToken,
        uint256 supplySpeed,
        uint256 borrowSpeed
    ) external onlyOwner updateDistributionOf(gToken) {
        require(gToken != address(0), "GRVDistributor: setGRVDistributionSpeedL: gToken can't be zero address");
        require(supplySpeed > 0, "GRVDistributor: setGRVDistributionSpeedL: supplySpeed can't be zero");
        require(borrowSpeed > 0, "GRVDistributor: setGRVDistributionSpeedL: borrowSpeed can't be zero");
        Constant.DistributionInfo storage dist = distributions[gToken];
        dist.supplySpeed = supplySpeed;
        dist.borrowSpeed = borrowSpeed;
        emit GRVDistributionSpeedUpdated(gToken, supplySpeed, borrowSpeed);
    }

    function setLendPoolLoan(address _lendPoolLoan) external onlyOwner {
        require(_lendPoolLoan != address(0), "GRVDistributor: lendPoolLoan can't be zero address");
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
        emit SetLendPoolLoan(_lendPoolLoan);
    }

    /* ========== VIEWS ========== */

    function accruedGRV(address[] calldata markets, address account) external view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_accruedGRV(markets[i], account));
        }
        return amount;
    }

    /// @notice 토큰의 distribition 정보 전달
    /// @param market gToken address
    function distributionInfoOf(address market) external view override returns (Constant.DistributionInfo memory) {
        return distributions[market];
    }

    /// @notice 해당 토큰의 유저 distribition 정보 전달
    /// @param market gToken address
    /// @param account user address
    function accountDistributionInfoOf(
        address market,
        address account
    ) external view override returns (Constant.DistributionAccountInfo memory) {
        return accountDistributions[market][account];
    }

    /// @notice 해당 토큰 및 유저의 apy 정보 전달
    /// @param market gToken address
    /// @param account user address
    function apyDistributionOf(
        address market,
        address account
    ) external view override returns (Constant.DistributionAPY memory) {
        (uint256 apySupplyGRV, uint256 apyBorrowGRV) = _calculateMarketDistributionAPY(market);
        (uint256 apyAccountSupplyGRV, uint256 apyAccountBorrowGRV) = _calculateAccountDistributionAPY(market, account);
        return Constant.DistributionAPY(apySupplyGRV, apyBorrowGRV, apyAccountSupplyGRV, apyAccountBorrowGRV);
    }

    /// @notice 특정 유저의 해당 토큰의 boost 비율값 전달
    /// @dev 토큰 담보양, 토큰 대출양(이자인덱스 고려), boostedSupplyRatio= 개인의 부스트 비율에 자신의 담보양을 나눠 계산, boostedBorrowRatio= 개인의 부스트 비율에 자신의 대출양을 나눠 계산
    /// @param market gToken address
    /// @param account user address
    function boostedRatioOf(
        address market,
        address account
    ) external view override returns (uint256 boostedSupplyRatio, uint256 boostedBorrowRatio) {
        uint256 accountSupply = IGToken(market).balanceOf(account);
        uint256 accountBorrow = IGToken(market).borrowBalanceOf(account).mul(1e18).div(
            IGToken(market).getAccInterestIndex()
        );

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            uint256 nftAccountBorrow = lendPoolLoan.userBorrowBalance(account).mul(1e18).div(nftAccInterestIndex);
            accountBorrow = accountBorrow.add(nftAccountBorrow);
        }

        boostedSupplyRatio = accountSupply > 0
            ? accountDistributions[market][account].boostedSupply.mul(1e18).div(accountSupply)
            : 0;
        boostedBorrowRatio = accountBorrow > 0
            ? accountDistributions[market][account].boostedBorrow.mul(1e18).div(accountBorrow)
            : 0;
    }

    function getTaxTreasury() external view override returns (address) {
        return taxTreasury;
    }

    function getPreEcoBoostedInfo(
        address market,
        address account,
        uint256 amount,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) external view override returns (uint256 boostedSupply, uint256 boostedBorrow) {
        uint256 expectedUserScore = locker.preScoreOf(account, amount, expiry, option);
        (uint256 totalScore, ) = locker.totalScore();
        uint256 userScore = locker.scoreOf(account);

        uint256 incrementUserScore = expectedUserScore > userScore ? expectedUserScore.sub(userScore) : 0;

        uint256 expectedTotalScore = totalScore.add(incrementUserScore);
        (Constant.EcoZone ecoZone, , ) = ecoScore.calculatePreUserEcoScoreInfo(account, amount, expiry, option);
        boostedSupply = ecoScore.calculatePreEcoBoostedSupply(
            market,
            account,
            expectedUserScore,
            expectedTotalScore,
            ecoZone
        );
        boostedBorrow = ecoScore.calculatePreEcoBoostedBorrow(
            market,
            account,
            expectedUserScore,
            expectedTotalScore,
            ecoZone
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Supply 또는 redeem 발생시 해당 유저의 boostedSupply, accruedGRV, accPerShareSupply값을 갱신 -> 시간에 따른 GRV 토큰 보상 업데이트
    /// @param market gToken address
    /// @param user user address
    function notifySupplyUpdated(
        address market,
        address user
    ) external override nonReentrant onlyCore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(user);
        uint256 boostedSupply = ecoScore.calculateEcoBoostedSupply(market, user, userScore, totalScore);

        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    /// @notice Borrow 또는 Repay 발생시 해당 유저의 boostedBorrow, accruedGRV, accPerShareBorrow 갱신 -> 시간에 따른 GRV 토큰 보상 업데이트
    /// @param market gToken address
    /// @param user user address
    function notifyBorrowUpdated(
        address market,
        address user
    ) external override nonReentrant onlyCore updateDistributionOf(market) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint256 accGRVPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(user);
        uint256 boostedBorrow = ecoScore.calculateEcoBoostedBorrow(market, user, userScore, totalScore);

        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    /// @notice 특정 토큰 전송시 이자 내용 업데이트
    /// @dev 전송자와 수신자의 각각의 남은 보상 이자를 처리한 후 각자의 부스트율 업데이트
    /// @param gToken gToken address
    /// @param sender sender address
    /// @param receiver receiver address
    function notifyTransferred(
        address gToken,
        address sender,
        address receiver
    ) external override nonReentrant onlyCore updateDistributionOf(gToken) {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        require(sender != receiver, "GRVDistributor: invalid transfer");
        Constant.DistributionInfo storage dist = distributions[gToken];
        Constant.DistributionAccountInfo storage senderInfo = accountDistributions[gToken][sender];
        Constant.DistributionAccountInfo storage receiverInfo = accountDistributions[gToken][receiver];

        if (senderInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(senderInfo.accPerShareSupply);
            senderInfo.accruedGRV = senderInfo.accruedGRV.add(accGRVPerShare.mul(senderInfo.boostedSupply).div(1e18));
        }
        senderInfo.accPerShareSupply = dist.accPerShareSupply;

        if (receiverInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(receiverInfo.accPerShareSupply);
            receiverInfo.accruedGRV = receiverInfo.accruedGRV.add(
                accGRVPerShare.mul(receiverInfo.boostedSupply).div(1e18)
            );
        }
        receiverInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 senderScore = locker.scoreOf(sender);
        uint256 receiverScore = locker.scoreOf(receiver);
        (uint256 totalScore, ) = locker.totalScore();

        ecoScore.updateUserEcoScoreInfo(sender);
        ecoScore.updateUserEcoScoreInfo(receiver);
        uint256 boostedSenderSupply = ecoScore.calculateEcoBoostedSupply(gToken, sender, senderScore, totalScore);
        uint256 boostedReceiverSupply = ecoScore.calculateEcoBoostedSupply(gToken, receiver, receiverScore, totalScore);
        dist.totalBoostedSupply = dist
            .totalBoostedSupply
            .add(boostedSenderSupply)
            .add(boostedReceiverSupply)
            .sub(senderInfo.boostedSupply)
            .sub(receiverInfo.boostedSupply);
        senderInfo.boostedSupply = boostedSenderSupply;
        receiverInfo.boostedSupply = boostedReceiverSupply;
    }

    /// @notice 토큰별로 소유하고 있는 보상 토큰을 모두 합하여 유저에게 전달
    /// @param markets gToken address
    /// @param account user address
    function claimGRV(address[] calldata markets, address account) external override onlyCore {
        require(account != address(0), "GRVDistributor: claimGRV: User account can't be zero address");
        require(taxTreasury != address(0), "GRVDistributor: claimGRV: TaxTreasury can't be zero address");
        uint256 amount = 0;
        uint256 userScore = locker.scoreOf(account);
        (uint256 totalScore, ) = locker.totalScore();

        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_claimGRV(markets[i], account, userScore, totalScore));
        }
        require(amount > 0, "GRVDistributor: claimGRV: Can't claim amount of zero");
        (uint256 adjustedValue, uint256 taxAmount) = ecoScore.calculateClaimTaxes(account, amount);

        ecoScore.updateUserClaimInfo(account, amount);
        _updateAccountBoostedInfo(account);

        adjustedValue = Math.min(adjustedValue, IBEP20(GRV).balanceOf(address(this)));
        GRV.safeTransfer(account, adjustedValue);

        taxAmount = Math.min(taxAmount, IBEP20(GRV).balanceOf(address(this)));
        GRV.safeTransfer(taxTreasury, taxAmount);
        emit GRVClaimed(account, amount);
    }

    /// @notice 현재까지 쌓인 유저의 보상 GRV를 전부 재락업한다
    /// @dev GRV 재락업시 Claim tax와 Discount tax를 고려한 양만큼만 재락업한다.
    /// @param markets gToken address
    /// @param account user address
    function compound(address[] calldata markets, address account) external override onlyCore {
        require(account != address(0), "GRVDistributor: compound: User account can't be zero address");
        uint256 expiryOfAccount = locker.expiryOf(account);
        _compound(markets, account, expiryOfAccount, Constant.EcoScorePreviewOption.LOCK_MORE);
    }

    /// @notice 아직 GRV Lock한적이 없는 유저의 경우 쌓인 보상 GRV를 바로 Lock 할 수 있도록 하는 함수
    /// @param account user address
    function firstDeposit(address[] calldata markets, address account, uint256 expiry) external override onlyCore {
        require(account != address(0), "GRVDistributor: firstDeposit: User account can't be zero address");
        uint256 balanceOfLockedGrv = locker.balanceOf(account);
        require(balanceOfLockedGrv == 0, "GRVDistributor: firstDeposit: User already deposited");

        _compound(markets, account, expiry, Constant.EcoScorePreviewOption.LOCK);
    }

    /// @notice 특정 유저의 score가 0이 될 경우 해당 유저의 부스트 점수를 없애고 초기 담보량으로 업데이트한다.
    /// @param user user address
    function kick(address user) external override nonReentrant {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;
        _kick(user);
    }

    function kicks(address[] calldata users) external override nonReentrant {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;
        for (uint256 i = 0; i < users.length; i++) {
            _kick(users[i]);
        }
    }

    function _kick(address user) private {
        uint256 userScore = locker.scoreOf(user);
        require(userScore == 0, "GRVDistributor: kick not allowed");
        (uint256 totalScore, ) = locker.totalScore();

        address[] memory markets = core.allMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];
            if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
            if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);
        }
        kickInfo[msg.sender] += 1;
    }

    /// @notice 유저가 locker에 deposit 후 boostedSupply, boostedBorrow 정보 업데이트를 위해 호출하는 함수
    /// @param user user address
    function updateAccountBoostedInfo(address user) external override {
        require(user != address(0), "GRVDistributor: compound: User account can't be zero address");
        _updateAccountBoostedInfo(user);
    }

    function updateAccountBoostedInfos(address[] calldata users) external override {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] != address(0)) {
                _updateAccountBoostedInfo(users[i]);
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice 유저가 locker에 deposit 후 boostedSupply, boostedBorrow 정보 업데이트를 위해 호출하는 내부 함수
    /// @param user user address
    function _updateAccountBoostedInfo(address user) private {
        if (block.timestamp < LAUNCH_TIMESTAMP) return;

        uint256 userScore = locker.scoreOf(user);
        (uint256 totalScore, ) = locker.totalScore();
        ecoScore.updateUserEcoScoreInfo(user);

        address[] memory markets = core.allMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];
            if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
            if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);
        }
    }

    /// @notice 축적된 보상 토큰 반환
    /// @dev time에 따라 그동안 축적된 보상 토큰 수량을 계산하여 반환한다
    /// @param market gToken address
    /// @param user user address
    function _accruedGRV(address market, address user) private view returns (uint256) {
        Constant.DistributionInfo memory dist = distributions[market];
        Constant.DistributionAccountInfo memory userInfo = accountDistributions[market][user];

        uint256 amount = userInfo.accruedGRV;
        uint256 accPerShareSupply = dist.accPerShareSupply;
        uint256 accPerShareBorrow = dist.accPerShareBorrow;

        uint256 timeElapsed = block.timestamp > dist.accruedAt ? block.timestamp.sub(dist.accruedAt) : 0;
        if (
            timeElapsed > 0 ||
            (accPerShareSupply != userInfo.accPerShareSupply) ||
            (accPerShareBorrow != userInfo.accPerShareBorrow)
        ) {
            if (dist.totalBoostedSupply > 0) {
                accPerShareSupply = accPerShareSupply.add(
                    dist.supplySpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedSupply)
                );

                uint256 pendingGRV = userInfo.boostedSupply.mul(accPerShareSupply.sub(userInfo.accPerShareSupply)).div(
                    1e18
                );
                amount = amount.add(pendingGRV);
            }

            if (dist.totalBoostedBorrow > 0) {
                accPerShareBorrow = accPerShareBorrow.add(
                    dist.borrowSpeed.mul(timeElapsed).mul(1e18).div(dist.totalBoostedBorrow)
                );

                uint256 pendingGRV = userInfo.boostedBorrow.mul(accPerShareBorrow.sub(userInfo.accPerShareBorrow)).div(
                    1e18
                );
                amount = amount.add(pendingGRV);
            }
        }
        return amount;
    }

    /// @notice 유저의 축적된 보상 토큰 반환 및 0으로 초기화
    /// @dev time에 따라 그동안 축적된 보상 토큰수량을 계산하여 반환한다
    /// @param market gToken address
    /// @param user user address
    function _claimGRV(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private returns (uint256 amount) {
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) _updateSupplyOf(market, user, userScore, totalScore);
        if (userInfo.boostedBorrow > 0) _updateBorrowOf(market, user, userScore, totalScore);

        amount = amount.add(userInfo.accruedGRV);
        userInfo.accruedGRV = 0;

        return amount;
    }

    /// @notice 특정 토큰의 담보 및 대출 APY 계산 후 반환
    /// @dev (담보스피드 X 365일 X 거버넌스토큰 가격 / 전체 담보 부스트 X 토큰 교환비 X 토큰가격 ) X 1e36
    /// @param market gToken address
    function _calculateMarketDistributionAPY(
        address market
    ) private view returns (uint256 apySupplyGRV, uint256 apyBorrowGRV) {
        uint256 decimals = _getDecimals(market);
        // base supply GRV APY == average supply GRV APY * (Total balance / total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base supply GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerSupply = distributions[market].supplySpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomSupply = distributions[market]
                .totalBoostedSupply
                .mul(10 ** (18 - decimals))
                .mul(IGToken(market).exchangeRate())
                .mul(priceCalculator.getUnderlyingPrice(market))
                .div(1e36);
            apySupplyGRV = denomSupply > 0 ? numerSupply.div(denomSupply) : 0;
        }

        // base borrow GRV APY == average borrow GRV APY * (Total balance / total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total balance * exchangeRate * price of asset) * (Total balance / Total Boosted balance)
        // base borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset)
        {
            uint256 numerBorrow = distributions[market].borrowSpeed.mul(365 days).mul(dashboard.getCurrentGRVPrice());
            uint256 denomBorrow = distributions[market]
                .totalBoostedBorrow
                .mul(10 ** (18 - decimals))
                .mul(IGToken(market).getAccInterestIndex())
                .mul(priceCalculator.getUnderlyingPrice(market))
                .div(1e36);
            apyBorrowGRV = denomBorrow > 0 ? numerBorrow.div(denomBorrow) : 0;
        }
    }

    /// @notice 특정 토큰의 유저의 담보 및 대출 APY 계산 후 반환
    /// @dev
    /// @param market gToken address
    function _calculateAccountDistributionAPY(
        address market,
        address account
    ) private view returns (uint256 apyAccountSupplyGRV, uint256 apyAccountBorrowGRV) {
        if (account == address(0)) return (0, 0);
        (uint256 apySupplyGRV, uint256 apyBorrowGRV) = _calculateMarketDistributionAPY(market);

        // user supply GRV APY == ((GRVRate * 365 days * price Of GRV) / (Total boosted balance * exchangeRate * price of asset) ) * my boosted balance  / my balance
        uint256 accountSupply = IGToken(market).balanceOf(account);
        apyAccountSupplyGRV = accountSupply > 0
            ? apySupplyGRV.mul(accountDistributions[market][account].boostedSupply).div(accountSupply)
            : 0;

        // user borrow GRV APY == (GRVRate * 365 days * price Of GRV) / (Total boosted balance * interestIndex * price of asset) * my boosted balance  / my balance
        uint256 accountBorrow = IGToken(market).borrowBalanceOf(account).mul(1e18).div(
            IGToken(market).getAccInterestIndex()
        );

        if (IGToken(market).underlying() == address(0)) {
            uint256 nftAccInterestIndex = lendPoolLoan.getAccInterestIndex();
            accountBorrow = accountBorrow.add(
                lendPoolLoan.userBorrowBalance(account).mul(1e18).div(nftAccInterestIndex)
            );
        }

        apyAccountBorrowGRV = accountBorrow > 0
            ? apyBorrowGRV.mul(accountDistributions[market][account].boostedBorrow).div(accountBorrow)
            : 0;
    }

    /// @notice kick, Claim용 update supply
    /// @dev user score가 0인 경우 boostedSupply 값을 초기 담보금으로 업데이트 하기 위함
    /// @param market gToken address
    function _updateSupplyOf(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private updateDistributionOf(market) {
        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedSupply > 0) {
            uint256 accGRVPerShare = dist.accPerShareSupply.sub(userInfo.accPerShareSupply);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedSupply).div(1e18));
        }
        userInfo.accPerShareSupply = dist.accPerShareSupply;

        uint256 boostedSupply = ecoScore.calculateEcoBoostedSupply(market, user, userScore, totalScore);
        dist.totalBoostedSupply = dist.totalBoostedSupply.add(boostedSupply).sub(userInfo.boostedSupply);
        userInfo.boostedSupply = boostedSupply;
    }

    function _updateBorrowOf(
        address market,
        address user,
        uint256 userScore,
        uint256 totalScore
    ) private updateDistributionOf(market) {
        Constant.DistributionInfo storage dist = distributions[market];
        Constant.DistributionAccountInfo storage userInfo = accountDistributions[market][user];

        if (userInfo.boostedBorrow > 0) {
            uint256 accGRVPerShare = dist.accPerShareBorrow.sub(userInfo.accPerShareBorrow);
            userInfo.accruedGRV = userInfo.accruedGRV.add(accGRVPerShare.mul(userInfo.boostedBorrow).div(1e18));
        }
        userInfo.accPerShareBorrow = dist.accPerShareBorrow;

        uint256 boostedBorrow = ecoScore.calculateEcoBoostedBorrow(market, user, userScore, totalScore);
        dist.totalBoostedBorrow = dist.totalBoostedBorrow.add(boostedBorrow).sub(userInfo.boostedBorrow);
        userInfo.boostedBorrow = boostedBorrow;
    }

    function _compound(
        address[] calldata markets,
        address account,
        uint256 expiry,
        Constant.EcoScorePreviewOption option
    ) private {
        require(taxTreasury != address(0), "GRVDistributor: _compound: TaxTreasury can't be zero address");
        uint256 amount = 0;
        uint256 userScore = locker.scoreOf(account);
        (uint256 totalScore, ) = locker.totalScore();

        for (uint256 i = 0; i < markets.length; i++) {
            amount = amount.add(_claimGRV(markets[i], account, userScore, totalScore));
        }
        (uint256 adjustedValue, uint256 taxAmount) = ecoScore.calculateCompoundTaxes(account, amount, expiry, option);

        locker.depositBehalf(account, adjustedValue, expiry);
        ecoScore.updateUserCompoundInfo(account, adjustedValue);

        taxAmount = Math.min(taxAmount, IBEP20(GRV).balanceOf(address(this)));
        if (taxAmount > 0) {
            GRV.safeTransfer(taxTreasury, taxAmount);
        }

        emit GRVCompound(account, amount, adjustedValue, taxAmount, expiry);
    }

    function _getDecimals(address gToken) internal view returns (uint256 decimals) {
        address underlying = IGToken(gToken).underlying();
        if (underlying == address(0)) {
            decimals = 18;
            // ETH
        } else {
            decimals = IBEP20(underlying).decimals();
        }
    }
}