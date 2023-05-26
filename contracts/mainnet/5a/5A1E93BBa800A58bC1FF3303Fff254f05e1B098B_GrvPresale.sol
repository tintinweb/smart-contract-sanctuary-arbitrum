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

interface IGrvPresale {
    struct MarketInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 totalTokens;
        uint256 commitmentCap;
    }

    struct MarketStatus {
        uint256 commitmentsTotal;
        uint256 minimumCommitmentAmount;
        bool finalized;
    }

    event AuctionTokenDeposited(uint256 amount);
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    event EndTimeUpdated(uint256 endTime);
    event AuctionPriceUpdated(uint256 minimumCommitmentAmount);
    event AuctionTreasuryUpdated(address treasury);
    event LockerUpdated(address locker);

    event AddedCommitment(address addr, uint256 commitment);
    event AuctionFinalized();
    event AuctionCancelled();

    function commitETH(address payable _beneficiary) external payable;
    function commitTokens(uint256 _amount) external;

    function after6Month(uint256 timestamp) external pure returns (uint256);
    function tokenPrice() external view returns (uint256);

    function withdrawTokens(address payable beneficiary) external;
    function withdrawToLocker() external;
    function setNickname(address _addr, string calldata _name) external;

    function tokensClaimable(address _user) external view returns (uint256);
    function tokensLockable(address _user) external view returns (uint256);

    function finalized() external view returns (bool);
    function auctionSuccessful() external view returns (bool);
    function auctionEnded() external view returns (bool);

    function getBaseInformation() external view returns (uint256 startTime, uint256 endTime, bool marketFinalized);
    function getTotalTokens() external view returns (uint256);

    function commitments(address user) external view returns (uint256);
    function claimed(address user) external view returns (uint256);

    function nicknames(address user) external view returns (string memory);

    function startReleaseTimestamp() external view returns (uint256);
    function endReleaseTimestamp() external view returns (uint256);

    function auctionToken() external view returns (address);
    function paymentCurrency() external view returns (address);

    function marketStatus() external view returns (uint256, uint256, bool);
    function marketInfo() external view returns (uint256, uint256, uint256, uint256);
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

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../library/SafeToken.sol";

import "../interfaces/IGrvPresale.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IBEP20.sol";

contract GrvPresale is IGrvPresale, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ========== STATE VARIABLES ========== */

    MarketInfo public override marketInfo;
    MarketStatus public override marketStatus;
    ILocker public locker;

    uint256 public override startReleaseTimestamp;
    uint256 public override endReleaseTimestamp;
    mapping(address => uint256) public lastUnlockTimestamp;

    address public override auctionToken;
    address public override paymentCurrency;
    address payable public treasury;

    mapping(address => uint256) public override commitments;
    mapping(address => uint256) public override claimed;
    mapping(address => string) public override nicknames;
    mapping(address => bool) public blacklist;

    /* ========== INITIALIZER ========== */

    function initialize(address _token, address _locker, uint256 _totalTokens, uint256 _startTime,
        uint256 _endTime, address _paymentCurrency, uint256 _minimumCommitmentAmount,
        uint256 _commitmentCap, address payable _treasury, uint256 _startReleaseTimestamp,
        uint256 _endReleaseTimestamp) external initializer {
        require(_startTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_startTime >= block.timestamp, "GrvPresale: start time is before current time");
        require(_endTime > _startTime, "GrvPresale: end time must be older than start time");
        require(_totalTokens > 0, "GrvPresale: total tokens must be greater than zero");
        require(_treasury != address(0), "GrvPresale: treasury is the zero address");
        require(_endReleaseTimestamp > _startReleaseTimestamp, "GrvPresale: endReleaseTimestamp < startReleaseTimestamp");

        require(IBEP20(_token).decimals() == 18, "GrvPresale: Token does not have 18 decimals");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IBEP20(_paymentCurrency).decimals() > 0, "GrvPresale: Payment currency is not ERC20");
        }

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        marketStatus.minimumCommitmentAmount = _minimumCommitmentAmount;

        marketInfo.startTime = _startTime;
        marketInfo.endTime = _endTime;
        marketInfo.totalTokens = _totalTokens;
        marketInfo.commitmentCap = _commitmentCap;

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        treasury = _treasury;

        locker = ILocker(_locker);
        startReleaseTimestamp = _startReleaseTimestamp;
        endReleaseTimestamp = _endReleaseTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositAuctionToken(address _funder) external onlyOwner {
        auctionToken.safeTransferFrom(_funder, address(this), marketInfo.totalTokens);
        emit AuctionTokenDeposited(marketInfo.totalTokens);
    }

    function finalize() external onlyOwner {
        require(!marketStatus.finalized, "GrvPresale: Auction has already finalized");
        require(block.timestamp > marketInfo.endTime, "GrvPresale: Auction has not finished yet");
        if (auctionSuccessful()) {
            // Successful auction
            // Transfer contributed tokens to treasury.
            _safeTokenPayment(paymentCurrency, treasury, marketStatus.commitmentsTotal);
        } else {
            // Failed auction
            // Return auction tokens back to treasury.
            auctionToken.safeTransfer(treasury, marketInfo.totalTokens);
        }
        marketStatus.finalized = true;
        emit AuctionFinalized();
    }

    function cancelAuction() external onlyOwner nonReentrant {
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "GrvPresale: already finalized");
        require(status.commitmentsTotal == 0, "GrvPresale: Funds already raised");

        auctionToken.safeTransfer(treasury, marketInfo.totalTokens);
        status.finalized = true;
        emit AuctionCancelled();
    }

    function setAuctionTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_endTime < 10000000000, "GrvPresale: enter an unix timestamp in seconds, not miliseconds");
        require(_startTime >= block.timestamp, "GrvPresale: start time is before current time");
        require(_endTime > _startTime, "GrvPresale: end time must be older than start price");

        require(marketStatus.commitmentsTotal == 0, "GrvPresale: auction cannot have already started");

        marketInfo.startTime = _startTime;
        marketInfo.endTime = _endTime;

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    function setAuctionPrice(uint256 _minimumCommitmentAmount) external onlyOwner {
        require(marketStatus.commitmentsTotal == 0, "GrvPresale: auction cannot have already started");
        marketStatus.minimumCommitmentAmount = _minimumCommitmentAmount;
        emit AuctionPriceUpdated(_minimumCommitmentAmount);
    }

    function setAuctionTreasury(address payable _treasury) external onlyOwner {
        require(_treasury != address(0), "GrvPresale: treasury is the zero address");
        treasury = _treasury;
        emit AuctionTreasuryUpdated(_treasury);
    }

    function setLocker(address _locker) external onlyOwner {
        require(_locker != address(0), "GrvPresale: locker is the zero address");
        locker = ILocker(_locker);
        emit LockerUpdated(_locker);
    }

    function setBlacklist(address _addr, bool isBlackUser) external onlyOwner {
        require(_addr != address(0), "GrvPresale: address is zero address");
        blacklist[_addr] = isBlackUser;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function commitETH(address payable _beneficiary) external payable override nonReentrant {
        require(paymentCurrency == ETH_ADDRESS, "GrvPresale: Payment currency is not ETH");
        require(msg.value > 0, "GrvPresale: value must be higher than 0");
        require(marketStatus.commitmentsTotal < marketInfo.commitmentCap, "GrvPresale: commitment cap full");

        _addCommitment(_beneficiary, msg.value);
        if (lastUnlockTimestamp[_beneficiary] < startReleaseTimestamp) {
            lastUnlockTimestamp[_beneficiary] = startReleaseTimestamp;
        }
        // Revert if commitmentsTotal exceeds the balance
        require(marketStatus.commitmentsTotal <= address(this).balance, "GrvPresale: The committed GRV exceeds the balance");
    }

    function commitTokens(uint256 _amount) external override nonReentrant {
        _commitTokensFrom(msg.sender, _amount);
    }

    function withdrawTokens(address payable beneficiary) external override nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "GrvPresale: not finalized");
            // Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "GrvPresale: No tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);

            auctionToken.safeTransfer(beneficiary, tokensToClaim);
            lastUnlockTimestamp[beneficiary] = block.timestamp;
        } else {
            // auction did not meet reserve price
            // return committed funds back to user
            require(block.timestamp > marketInfo.endTime, "GrvPresale: Auction has not finished yet");
            uint256 fundsCommitted = commitments[beneficiary];
            require(fundsCommitted > 0, "GrvPresale: No funds committed");
            commitments[beneficiary] = 0; // Stop multiple withdrawals
            _safeTokenPayment(paymentCurrency, beneficiary, fundsCommitted);
        }
    }

    function withdrawToLocker() external override nonReentrant {
        require(marketStatus.finalized, "GrvPresale: not finalized");
        require(auctionSuccessful(), "GrvPresale: auction failed");
        uint256 tokensToLockable = tokensLockable(msg.sender);
        require(tokensToLockable > 0, "GrvPresale: No tokens to Lock");
        require(locker.expiryOf(msg.sender) == 0 || locker.expiryOf(msg.sender) > after6Month(block.timestamp),
            "GrvPresale: locker lockup period less than 6 months");

        claimed[msg.sender] = claimed[msg.sender].add(tokensToLockable);

        auctionToken.safeApprove(address(locker), tokensToLockable);
        locker.depositBehalf(msg.sender, tokensToLockable, after6Month(block.timestamp));
        auctionToken.safeApprove(address(locker), 0);
    }

    function setNickname(address _addr, string calldata _name) external override {
        require(_addr != address(0), "GrvPresale: address is zero address");
        require(blacklist[msg.sender] == false, "GrvPresale: Blacklist user");
        require(msg.sender == _addr || msg.sender == owner(), "GrvPresale: do not have permission to set a name");
        nicknames[_addr] = _name;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _commitTokensFrom(address payable _from, uint256 _amount) private {
        require(paymentCurrency != ETH_ADDRESS, "GrvPresale: Payment currency is not a token");
        require(_amount > 0, "GrvPresale: Value must be higher than 0");
        require(marketStatus.commitmentsTotal < marketInfo.commitmentCap, "GrvPresale: commitment cap full");

        _safeTransferFrom(paymentCurrency, msg.sender, _amount);
        _addCommitment(_from, _amount);
        if (lastUnlockTimestamp[_from] < startReleaseTimestamp) {
            lastUnlockTimestamp[_from] = startReleaseTimestamp;
        }
    }

    function _addCommitment(address payable _addr, uint256 _commitment) private {
        require(block.timestamp >= marketInfo.startTime && block.timestamp <= marketInfo.endTime, "GrvPresale: outside auction hours");
        require(!marketStatus.finalized, "GrvPresale: has been finalized");

        if (_commitment.add(marketStatus.commitmentsTotal) > marketInfo.commitmentCap) {
            uint256 _canCommitmentAmount = marketInfo.commitmentCap.sub(marketStatus.commitmentsTotal);
            uint256 _refundAmount = _commitment.sub(_canCommitmentAmount);
            _commitment = _canCommitmentAmount;
            _safeTokenPayment(paymentCurrency, _addr, _refundAmount);
        }

        uint256 newCommitment = commitments[_addr].add(_commitment);
        commitments[_addr] = newCommitment;
        marketStatus.commitmentsTotal = marketStatus.commitmentsTotal.add(_commitment);
        emit AddedCommitment(_addr, _commitment);
    }

    // calculates amount of auction tokens for user to receive.
    function _getTokenAmount(uint256 amount) private view returns (uint256) {
        if (marketStatus.commitmentsTotal == 0) {
            return 0;
        }
        return _getAdjustedAmount(paymentCurrency, amount).mul(1e18).div(tokenPrice());
    }

    function _canUnlockAmount(address _user, uint256 _unclaimedTokenAmount) private view returns (uint256) {
        if (block.timestamp < startReleaseTimestamp) {
            return 0;
        } else if (block.timestamp >= endReleaseTimestamp) {
            return _unclaimedTokenAmount;
        } else {
            uint256 releasedTimestamp = block.timestamp.sub(lastUnlockTimestamp[_user]);
            uint256 timeLeft = endReleaseTimestamp.sub(lastUnlockTimestamp[_user]);
            return _unclaimedTokenAmount.mul(releasedTimestamp).div(timeLeft);
        }
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        (bool success, bytes memory data) =
        token.call(
        // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(address token, address from, uint256 amount) private {
        (bool success, bytes memory data) =
        token.call(
        // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _getAdjustedAmount(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return amount;
        } else {
            uint256 defaultDecimal = 18;
            uint256 tokenDecimal = IBEP20(token).decimals();

            if (tokenDecimal == defaultDecimal) {
                return amount;
            } else if (tokenDecimal < defaultDecimal) {
                return amount * (10**(defaultDecimal - tokenDecimal));
            } else {
                return amount / (10**(tokenDecimal - defaultDecimal));
            }
        }
    }

    /* ========== VIEWS ========== */

    function after6Month(uint256 timestamp) public pure override returns (uint256) {
        timestamp = timestamp + 180 days;
        return ((timestamp.add(1 weeks) / 1 weeks) * 1 weeks);
    }

    function tokenPrice() public view override returns (uint256) {
        return _getAdjustedAmount(paymentCurrency, marketStatus.commitmentsTotal).mul(1e18).div(marketInfo.totalTokens);
    }

    function tokensClaimable(address _user) public view override returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        claimerCommitment = _canUnlockAmount(_user, claimerCommitment);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    function tokensLockable(address _user) public view override returns (uint256 claimerCommitment) {
        if (commitments[_user] == 0) {
            return 0;
        }
        uint256 unclaimedTokens = IBEP20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    function finalized() external view override returns (bool) {
        return marketStatus.finalized;
    }

    function auctionSuccessful() public view override returns (bool) {
        return marketStatus.commitmentsTotal >= marketStatus.minimumCommitmentAmount && marketStatus.commitmentsTotal > 0;
    }

    function auctionEnded() external view override returns (bool) {
        return block.timestamp > marketInfo.endTime;
    }

    function getBaseInformation() external view override returns (uint256 startTime, uint256 endTime, bool marketFinalized) {
        startTime = marketInfo.startTime;
        endTime = marketInfo.endTime;
        marketFinalized = marketStatus.finalized;
    }

    function getTotalTokens() external view override returns(uint256) {
        return marketInfo.totalTokens;
    }
}