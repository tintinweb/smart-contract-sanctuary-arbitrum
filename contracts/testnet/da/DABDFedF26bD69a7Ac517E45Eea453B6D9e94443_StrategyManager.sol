// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";

/// @title Interface for the Holding contract
interface IHolding {
    // @notice returns the manager address
    function managerContainer() external view returns (IManagerContainer);

    /// @notice approves a token's amount for spending on another address
    /// @dev callable only by HoldingManager or StrategyManager to avoid risky situations
    /// @param _tokenAddress token user wants to withdraw
    /// @param _destination destination address of the approval
    /// @param _amount withdrawal amount
    function approve(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) external;

    /// @notice generic caller for contract
    /// @dev callable only by HoldingManager or StrategyManager to avoid risky situations
    /// @dev used mostly for claim rewards part of the strategies as only the registered staker can harvest
    /// @param _contract the contract address for which the call will be invoked
    /// @param _call abi.encodeWithSignature data for the call
    function genericCall(address _contract, bytes calldata _call)
        external
        returns (bool success, bytes memory result);

    /// @notice method used to transfer token from the holding contract to another address
    /// @dev callable only by HoldingManager or StrategyManager to avoid risky situations
    /// @param _token token address
    /// @param _to address to move token to
    /// @param _amount transferal amount
    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice mints Pandora Token
    /// @dev callable only by HoldingManager or StrategyManager to avoid risky situations
    /// @param _minter IMinter address
    /// @param _gauge gauge to mint for
    function mint(address _minter, address _gauge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";
import "../ISwap.sol";

/// @title Interface for the HoldingManager contract
interface IHoldingManager {
    /// @notice emitted when a new holding is crated
    event HoldingCreated(address indexed user, address indexed holdingAddress);

    /// @notice emitted when rewards are sent to the holding contract
    event ReceivedRewards(
        address indexed holding,
        address indexed strategy,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when rewards were exchanged to another token
    event RewardsExchanged(
        address indexed holding,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice emitted when rewards are withdrawn by the user
    event RewardsWithdrawn(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when a deposit is created
    event Deposit(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when tokens are withdrawn from the holding
    event Withdrawal(
        address indexed holding,
        address indexed token,
        uint256 totalAmount,
        uint256 feeAmount
    );

    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool mintToUser
    );

    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool repayFromUser
    );

    /// @notice event emitted when fee is moved from liquidated holding to fee addres
    event CollateralFeeTaken(
        address token,
        address holdingFrom,
        address to,
        uint256 amount
    );

    /// @notice event emitted when borrow event happened for multiple users
    event BorrowedMultiple(
        address indexed holding,
        uint256 length,
        bool mintedToUser
    );

    /// @notice event emitted when a multiple repay operation happened
    event RepayedMultiple(
        address indexed holding,
        uint256 length,
        bool repayedFromUser
    );

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice event emitted when the user wraps native coin
    event NativeCoinWrapped(address user, uint256 amount);

    /// @notice event emitted when the user unwraps into native coin
    event NativeCoinUnwrapped(address user, uint256 amount);

    /// @notice data used for multiple borrow
    struct BorrowOrRepayData {
        address token;
        uint256 amount;
    }

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns user for holding
    function holdingUser(address holding) external view returns (address);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice returns the address of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    // -- User specific methods --

    /// @notice deposits a whitelisted token into the holding
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external;

    /// @notice wraps native coin and deposits WETH into the holding
    /// @dev this function must receive ETH in the transaction
    function wrapAndDeposit() external payable;

    /// @notice withdraws a token from the contract
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _token, uint256 _amount) external;

    /// @notice withdraws WETH from holding and unwraps it before sending it to the user
    function withdrawAndUnwrap(uint256 _amount) external;

    /// @notice mints Pandora Token
    /// @param _minter IMinter address
    /// @param _gauge gauge to mint for
    function mint(address _minter, address _gauge) external;

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _dex selected dex
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        ISwap _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice mints stablecoin to the user or to the holding contract
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    /// @param _mintDirectlyToUser if true, bypasses the holding and mints directly to EOA account
    function borrow(
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    ) external;

    /// @notice borrows from multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrowMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _token collateral token
    /// @param _amount the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    ) external;

    /// @notice repays multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repayMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _repayFromUser
    ) external;

    /// @notice creates holding for the msg sender
    /// @dev must be called from an EOA or whitelisted contract
    function createHolding() external returns (address);

    /// @notice user wraps native coin
    /// @dev this function must receive ETH in the transaction
    function wrap() external payable;

    /// @notice user unwraps wrapped native coin
    /// @param _amount the amount to unwrap
    function unwrap(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the liquidation manager is set
    event LiquidationManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the WETH is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emmited when the receipt token factory is updated
    event ReceiptTokenFactoryUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emmited when the liquidity gauge factory is updated
    event LiquidityGaugeFactoryUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emmited when the liquidator's bonus is updated
    event LiquidatorBonusUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice emmited when the liquidation fee is updated
    event LiquidationFeeUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice emitted when the vault is updated
    event VaultUpdated(address indexed oldAddress, address indexed newAddress);

    /// @notice emitted when the withdraw fee is updated
    event WithdrawalFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice event emitted when a non-withdrawable token is added
    event NonWithdrawableTokenAdded(address indexed token);

    /// @notice event emitted when a non-withdrawable token is removed
    event NonWithdrawableTokenRemoved(address indexed token);

    /// @notice event emitted when invoker is updated
    event InvokerUpdated(address indexed component, bool allowed);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns state of invoker
    function allowedInvokers(address _invoker) external view returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns vault address
    function vault() external view returns (address);

    /// @notice returns holding manager address
    function liquidationManager() external view returns (address);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice returns the address of the ReceiptTokenFactory
    function receiptTokenFactory() external view returns (address);

    /// @notice returns the address of the LiquidityGaugeFactory
    function liquidityGaugeFactory() external view returns (address);

    /// @notice USDC address
    // solhint-disable-next-line func-name-mixedcase
    function USDC() external view returns (address);

    /// @notice WETH address
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (address);

    /// @notice Fee for withdrawing from a holding
    /// @dev 2 decimals precission so 500 == 5%
    function withdrawalFee() external view returns (uint256);

    /// @notice the % amount a liquidator gets
    function liquidatorBonus() external view returns (uint256);

    /// @notice the % amount the protocol gets when a liquidation operation happens
    function liquidationFee() external view returns (uint256);

    /// @notice exchange rate precision
    // solhint-disable-next-line func-name-mixedcase
    function EXCHANGE_RATE_PRECISION() external view returns (uint256);

    /// @notice used in various operations
    // solhint-disable-next-line func-name-mixedcase
    function PRECISION() external view returns (uint256);

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidatorBonus(uint256 _val) external;

    /// @notice Sets the liquidator bonus
    /// @param _val The new value
    function setLiquidationFee(uint256 _val) external;

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice uptes the vault address
    /// @param _vault the new address
    function setVault(address _vault) external;

    /// @notice updates the liquidation manager address
    /// @param _manager liquidation manager's address
    function setLiquidationManager(address _manager) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the fee for withdrawing from a holding
    /// @param _fee fee amount
    function setWithdrawalFee(uint256 _fee) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;

    /// @notice sets invoker as allowed or forbidden
    /// @param _component invoker's address
    /// @param _allowed true/false
    function updateInvoker(address _component, bool _allowed) external;

    /// @notice returns true if the token cannot be withdrawn from a holding
    function isTokenNonWithdrawable(address _token)
        external
        view
        returns (bool);

    /// @notice adds a token to the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as non-withdrawable
    function addNonWithdrawableToken(address _token) external;

    /// @notice removes a token from the mapping of non-withdrawable tokens
    /// @param _token the token to be marked as non-withdrawable
    function removeNonWithdrawableToken(address _token) external;

    /// @notice sets the receipt token factory address
    /// @param _factory receipt token factory address
    function setReceiptTokenFactory(address _factory) external;

    /// @notice sets the liquidity factory address
    /// @param _factory liquidity factory address
    function setLiquidityGaugeFactory(address _factory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagerContainer {
    /// @notice emitted when the strategy manager is set
    event ManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice returns the manager address
    function manager() external view returns (address);

    /// @notice Updates the manager address
    /// @param _address The address of the manager
    function updateManager(address _address) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/RebaseLib.sol";

import "./IManagerContainer.sol";
import "../stablecoin/IPandoraUSD.sol";
import "../stablecoin/ISharesRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was registered by the owner
    event ForceAddedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when collateral was unregistered
    event RemovedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when collateral was unregistered by the owner
    event ForceRemovedCollateral(
        address indexed holding,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(address indexed holding, uint256 amount, bool mintToUser);
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        uint256 amount,
        address indexed burnFrom
    );

    /// @notice event emitted when a registry is added
    event RegistryAdded(address indexed token, address indexed registry);

    /// @notice event emitted when a registry is updated
    event RegistryUpdated(address indexed token, address indexed registry);

    /// @notice event emmitted when a liquidation operation happened
    event Liquidated(
        address indexed liquidatedHolding,
        address indexed liquidator,
        address indexed token,
        uint256 obtainedCollateral,
        uint256 protocolCollateral,
        uint256 liquidatedAmount
    );

    /// @notice event emitted when data is migrated to another collateral token
    event CollateralMigrated(
        address indexed holding,
        address indexed tokenFrom,
        address indexed tokenTo,
        uint256 borrowedAmount,
        uint256 collateralTo
    );

    /// @notice emitted when an existing strategy info is updated
    event RegistryConfigUpdated(address indexed registry, bool active);

    struct ShareRegistryInfo {
        bool active;
        address deployedAt;
    }

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice share -> info
    function shareRegistryInfo(address _registry)
        external
        view
        returns (bool, address);

    /// @notice total borrow per token
    function totalBorrowed(address _token) external view returns (uint256);

    /// @notice returns the address of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice Pandora project stablecoin address
    function pandoraUSD() external view returns (IPandoraUSD);

    /// @notice Returns true if user is solvent for the specified token
    /// @dev the method reverts if block.timestamp - _maxTimeRange > exchangeRateUpdatedAt
    /// @param _token the token for which the check is done
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        external
        view
        returns (bool);

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external;

    /// @notice registers new collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @dev does not check solvency status
    ///      - callable by the LiquidationManager only
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _amount the repayed pUsd amount
    /// @param _burnFrom the address to burn from
    function repay(
        address _holding,
        address _token,
        uint256 _amount,
        address _burnFrom
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vyper/IReceiptToken.sol";

/// @title Interface for a strategy
/// @author Cosmin Grigore (@gcosmintech)
interface IStrategy {
    /// @notice emitted when funds are deposited
    event Deposit(
        address indexed asset,
        address indexed tokenIn,
        uint256 assetAmount,
        uint256 tokenInAmount,
        uint256 shares,
        address indexed recipient
    );

    /// @notice emitted when funds are withdrawn
    event Withdraw(
        address indexed asset,
        address indexed recipient,
        uint256 shares,
        uint256 amount
    );

    /// @notice emitted when rewards are withdrawn
    event Rewards(
        address indexed recipient,
        uint256[] rewards,
        address[] rewardTokens
    );

    /// @notice participants info
    struct RecipientInfo {
        uint256 investedAmount;
        uint256 totalShares;
    }

    //returns investments details
    function recipients(address _recipient)
        external
        view
        returns (uint256, uint256);

    //returns the address of the token accepted by the strategy as input
    function tokenIn() external view returns (address);

    //returns the address of strategy's receipt token
    function tokenOut() external view returns (address);

    //returns the address of strategy's main reward token
    function rewardToken() external view returns (address);

    //returns the address of strategy's main reward token
    function receiptToken() external view returns (IReceiptToken);

    //returns the number of decimals of the strategy's shares
    function sharesDecimals() external view returns (uint256);

    //returns rewards amount
    function getRewards(address _recipient) external view returns (uint256);

    /// @notice returns address of the receipt token
    function getReceiptTokenAddress() external view returns (address);

    /// @notice deposits funds into the strategy
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _asset token to be invested
    /// @param _amount token's amount
    /// @param _recipient on behalf of
    /// @param _data extra data
    /// @return tokenOutAmount receipt tokens amount/obtained shares
    /// @return tokenInAmount returned token in amount
    function deposit(
        address _asset,
        uint256 _amount,
        address _recipient,
        bytes calldata _data
    ) external returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice withdraws deposited funds
    /// @dev some strategies will allow only the tokenIn to be withdrawn
    /// @dev 'assetAmount' will be equal to 'tokenInAmount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _asset token to be invested
    /// @param _shares amount to withdraw
    /// @param _recipient on behalf of
    /// @param _asset token to be withdrawn
    /// @param _data extra data
    /// @return assetAmount returned asset amoumt obtained from the operation
    /// @return tokenInAmount returned token in amount
    function withdraw(
        uint256 _shares,
        address _recipient,
        address _asset,
        bytes calldata _data
    ) external returns (uint256 assetAmount, uint256 tokenInAmount);

    /// @notice claims rewards from the strategy
    /// @param _recipient on behalf of
    /// @param _data extra data
    /// @return amounts reward tokens amounts
    /// @return tokens reward tokens addresses
    function claimRewards(address _recipient, bytes calldata _data)
        external
        returns (uint256[] memory amounts, address[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";
import "./IStrategyManagerMin.sol";

/// @title Interface for the Strategy Manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IStrategyManager is IStrategyManagerMin {
    /// @notice emitted when a new strategy is added to the whitelist
    event StrategyAdded(address indexed strategy);

    /// @notice emitted when an existing strategy is removed from the whitelist
    event StrategyRemoved(address indexed strategy);

    /// @notice emitted when an existing strategy info is updated
    event StrategyUpdated(address indexed strategy, bool active, uint256 fee);

    /// @notice emitted when added a gauge to a strategy
    event GaugeAdded(address indexed strategy, address indexed gauge);

    /// @notice emitted when removed a gauge from a strategy
    event GaugeRemoved(address indexed strategy);

    /// @notice emitted when updated a gauge to a strategy
    event GaugeUpdated(
        address indexed strategy,
        address indexed oldGauge,
        address indexed newGauge
    );

    /// @notice emitted when an investment is created
    event Invested(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 amount,
        uint256 tokenOutResult,
        uint256 tokenInResult
    );

    /// @notice emitted when an investment is withdrawn
    event InvestmentMoved(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategyFrom,
        address strategyTo,
        uint256 shares,
        uint256 tokenOutResult,
        uint256 tokenInResult
    );

    /// @notice event emitted when collateral is adjusted from a claim investment or claim rewards operation
    event CollateralAdjusted(
        address indexed holding,
        address indexed token,
        uint256 value,
        bool add
    );

    /// @notice emitted when an investment is withdrawn
    event StrategyClaim(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 shares,
        uint256 tokenAmount,
        uint256 tokenInAmount
    );

    /// @notice event emitted when performance fee is taken
    event FeeTaken(
        address indexed token,
        address indexed feeAddress,
        uint256 amount
    );

    /// @notice event emitted when rewards are claimed
    event RewardsClaimed(
        address indexed token,
        address indexed holding,
        uint256 amount
    );

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice event emitted when user stakes receipt tokens into strategy gauge
    event ReceiptTokensStaked(address indexed strategy, uint256 amount);

    /// @notice event emitted when user unstakes receipt tokens into strategy gauge
    event ReceiptTokensUnstaked(address indexed strategy, uint256 amount);

    /// @notice information about strategies
    struct StrategyInfo {
        uint256 performanceFee;
        bool active;
        bool whitelisted;
    }

    /// @notice data used for a move investment operation
    /// @param strategyFrom strategy's address where investment is taken from
    /// @param _strategyTo strategy's address to invest
    /// @param _shares shares amount
    /// @param _dataFrom extra data for claimInvestment
    /// @param _dataTo extra data for invest
    /// @param dataComponentsFrom extra data withdrawing from source related to components
    struct MoveInvestmentData {
        address strategyFrom;
        address strategyTo;
        uint256 shares;
        bytes dataFrom;
        bytes dataTo;
    }

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns the address of the gauge corresponding to any strategy
    function strategyGauges(address _strategy) external view returns (address);

    /// @notice adds a new strategy to the whitelist
    /// @param _strategy strategy's address
    function addStrategy(address _strategy) external;

    /// @notice updates an existing strategy info
    /// @param _strategy strategy's address
    /// @param _info info
    function updateStrategy(address _strategy, StrategyInfo calldata _info)
        external;

    /// @notice adds a new gauge to a strategy
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function addStrategyGauge(address _strategy, address _gauge) external;

    /// @notice removes a gauge from the strategy
    /// @param _strategy strategy's address
    function removeStrategyGauge(address _strategy) external;

    /// @notice updates the strategy's gauge
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function updateStrategyGauge(address _strategy, address _gauge) external;

    /// @notice performs several actions to config a strategy
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function configStrategy(address _strategy, address _gauge) external;

    // -- User specific methods --
    /// @notice invests in a strategy
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function invest(
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) external returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice claims investment from one strategy and invests it into another
    /// @dev callable by holding's user
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _data MoveInvestmentData object
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function moveInvestment(address _token, MoveInvestmentData calldata _data)
        external
        returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice claims a strategy investment
    /// @dev withdraws investment from a strategy
    /// @dev some strategies will allow only the tokenIn to be withdrawn
    /// @dev 'assetAmount' will be equal to 'tokenInAmount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    /// @return assetAmount returned asset amoumt obtained from the operation
    /// @return tokenInAmount returned token in amount
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) external returns (uint256 assetAmount, uint256 tokenInAmount);

    /// @notice claim rewards from strategy
    /// @param _strategy strategy's address
    /// @param _data extra data
    /// @return amounts reward amounts
    /// @return tokens reward tokens
    function claimRewards(address _strategy, bytes calldata _data)
        external
        returns (uint256[] memory amounts, address[] memory tokens);

    /// @notice invokes a generic call on holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _contract the external contract called by holding
    /// @param _call the call data
    /// @return success true/false
    /// @return result data obtained from the external call
    function invokeHolding(
        address _holding,
        address _contract,
        bytes calldata _call
    ) external returns (bool success, bytes memory result);

    /// @notice invokes an approve operation for holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _token the asset for which the approval is performed
    /// @param _on the contract's address
    /// @param _amount the approval amount
    function invokeApprove(
        address _holding,
        address _token,
        address _on,
        uint256 _amount
    ) external;

    /// @notice invokes a transfer operation for holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _token the asset for which the approval is performed
    /// @param _to the receiver address
    /// @param _amount the approval amount
    function invokeTransferal(
        address _holding,
        address _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice deposits receipt tokens into the liquidity gauge of the strategy
    /// @param _strategy strategy's address
    /// @param _amount amount of receipt tokens to stake
    function stakeReceiptTokens(address _strategy, uint256 _amount) external;

    /// @notice withdraws receipt tokens from the liquidity gauge of the strategy
    /// @param _strategy strategy's address
    /// @param _amount amount of receipt tokens to unstake
    function unstakeReceiptTokens(address _strategy, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManagerMin {
    /// @notice returns a strategy info
    function strategyInfo(address _strategy)
        external
        view
        returns (
            uint256,
            bool,
            bool
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwap {
    /// @notice calculate output amount without performin a swap
    /// @param tokenIn input token address
    /// @param amountIn amount to calculate for
    /// @param data custom DEX data like swapPath for UniswapV2, tokenIndexes for Curve or tokenOut for UniswapV3
    function getOutputAmount(
        address tokenIn,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256 amountOut);

    /// @notice swaps 'tokenIn' with 'tokenOut'
    /// @param tokenIn input token address
    /// @param tokenOut output token address
    /// @param amountIn swap amount
    /// @param to tokenOut receiver
    /// @param amountOutMin minimum amount to be received
    /// @param data custom DEX data like swapPath for UniswapV2, tokenIndexes for Curve or deadline for UniswapV3
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to,
        uint256 amountOutMin,
        bytes calldata data
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IManagerContainer.sol";

interface IPandoraUSD {
    /// @notice event emitted when the mint limit is updated
    event MintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice sets the manager address
    /// @param _limit the new mint limit
    function updateMintLimit(uint256 _limit) external;

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the max mint limitF
    function mintLimit() external view returns (uint256);

    /// @notice mint tokens
    /// @dev no need to check if '_to' is a valid address if the '_mint' method is used
    /// @param _to address of the user receiving minted tokens
    /// @param _amount the amount to be minted
    function mint(address _to, uint256 _amount) external;

    /// @notice burns token from sender
    /// @param _amount the amount of tokens to be burnt
    function burn(uint256 _amount) external;

    /// @notice burns token from an address
    /// @param _user the user to burn it from
    /// @param _amount the amount of tokens to be burnt
    function burnFrom(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../oracle/IOracle.sol";
import "../core/IManagerContainer.sol";

/// @title Interface for SharesRegistry contract
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM CauldraonV2 contract
interface ISharesRegistry {
    /// @notice event emitted when contract new ownership is accepted
    event OwnershipAccepted(address indexed newOwner);
    /// @notice event emitted when contract ownership transferal was initated
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    /// @notice event emitted when collateral was registered
    event CollateralAdded(address indexed user, uint256 share);
    /// @notice event emitted when collateral was unregistered
    event CollateralRemoved(address indexed user, uint256 share);
    /// @notice event emitted when exchange rate was updated
    event ExchangeRateUpdated(uint256 rate);
    /// @notice event emitted when the borrowing opening fee is updated
    event BorrowingOpeningFeeUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the liquidation mutiplier is updated
    event LiquidationMultiplierUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the collateralization rate is updated
    event CollateralizationRateUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when fees are accrued
    event FeesAccrued(uint256 amount);
    /// @notice event emitted when accrue was called
    event Accrued(uint256 updatedTotalBorrow, uint256 extraAmount);
    /// @notice oracle data updated
    event OracleDataUpdated();
    /// @notice emitted when new oracle data is requested
    event NewOracleDataRequested(bytes newData);
    /// @notice emitted when new oracle is requested
    event NewOracleRequested(address newOracle);
    /// @notice oracle updated
    event OracleUpdated();
    /// @notice event emitted when borrowed amount is set
    event BorrowedSet(address indexed _holding, uint256 oldVal, uint256 newVal);
    /// @notice event emitted when borrowed shares amount is set
    event BorrowedSharesSet(
        address indexed _holding,
        uint256 oldVal,
        uint256 newVal
    );
    // @notice event emitted when timelock amount is updated
    event TimelockAmountUpdated(uint256 oldVal, uint256 newVal);
    // @notice event emitted when a new timelock amount is requested
    event TimelockAmountUpdateRequested(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when interest per second is updated
    event InterestUpdated(uint256 oldVal, uint256 newVal);

    /// @notice accure info data
    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        // solhint-disable-next-line var-name-mixedcase
        uint64 INTEREST_PER_SECOND;
    }

    /// @notice borrowed amount for holding; holding > amount
    function borrowed(address _holding) external view returns (uint256);

    /// @notice info about the accrued data
    function accrueInfo()
        external
        view
        returns (
            uint64,
            uint128,
            uint64
        );

    /// @notice current timelock amount
    function timelockAmount() external view returns (uint256);

    /// @notice current owner
    function owner() external view returns (address);

    /// @notice possible new owner
    /// @dev if different than `owner` an ownership transfer is in  progress and has to be accepted by the new owner
    function temporaryOwner() external view returns (address);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the token address for which this registry was created
    function token() external view returns (address);

    /// @notice oracle contract associated with this share registry
    function oracle() external view returns (IOracle);

    /// @notice returns the up to date exchange rate
    function getExchangeRate() external view returns (uint256);

    /// @notice updates the colalteralization rate
    /// @param _newVal the new value
    function setCollateralizationRate(uint256 _newVal) external;

    /// @notice collateralization rate for token
    // solhint-disable-next-line func-name-mixedcase
    function collateralizationRate() external view returns (uint256);

    /// @notice returns the collateral shares for user
    /// @param _user the address for which the query is performed
    function collateral(address _user) external view returns (uint256);

    /// @notice requests a change for the oracle address
    /// @param _oracle the new oracle address
    function requestNewOracle(address _oracle) external;

    /// @notice sets a new value for borrowed
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowed(address _holding, uint256 _newVal) external;

    /// @notice updates the AccrueInfo object
    /// @param _totalBorrow total borrow amount
    function accrue(uint256 _totalBorrow) external returns (uint256);

    /// @notice registers collateral for token
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    function registerCollateral(address _holding, uint256 _share) external;

    /// @notice registers a collateral removal operation
    /// @param _holding the address of the user
    /// @param _share the new collateral shares
    function unregisterCollateral(address _holding, uint256 _share) external;

    /// @notice initiates the ownership transferal
    /// @param _newOwner the address of the new owner
    function transferOwnership(address _newOwner) external;

    /// @notice finalizes the ownership transferal process
    /// @dev must be called after `transferOwnership` was executed successfully, by the new temporary onwer
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Receipt token interface
interface IReceiptToken {
    function mint(address _to, uint256 _amount) external returns (bool);

    function burnFrom(address _from, uint256 _amount) external returns (bool);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _minter,
        address _owner
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice common operations
library OperationsLib {
    uint256 internal constant FEE_FACTOR = 10000;

    /// @notice gets the amount used as a fee
    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    /// @notice retrieves ratio between 2 numbers
    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice approves token for spending
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool successEmtptyApproval, ) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("approve(address,uint256)")),
                to,
                0
            )
        );
        require(
            successEmtptyApproval,
            "OperationsLib::safeApprove: approval reset failed"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("approve(address,uint256)")),
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "OperationsLib::safeApprove: approve failed"
        );
    }

    /// @notice gets the revert message string
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library RebaseLib {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && ((base * total.elastic) / total.base) < elastic) {
                base = base + 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && ((elastic * total.base) / total.elastic) < base) {
                elastic = elastic + 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic + elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic - elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/OperationsLib.sol";

import "./interfaces/core/IHolding.sol";
import "./interfaces/core/IManager.sol";
import "./interfaces/core/IStrategy.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IStablesManager.sol";
import "./interfaces/core/IStrategyManager.sol";
import "./interfaces/stablecoin/ISharesRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title StrategyManager contract
/// @author Cosmin Grigore (@gcosmintech)
contract StrategyManager is IStrategyManager, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /// @notice returns whitelisted strategies info
    mapping(address => StrategyInfo) public override strategyInfo;

    /// @notice returns the address of the gauge corresponding to any strategy
    mapping(address => address) public override strategyGauges;

    /// @notice returns the pause state of the contract
    bool public override paused;

    /// @notice contract that contains the address of the manager contract
    IManagerContainer public immutable override managerContainer;

    /// @notice creates a new StrategyManager contract
    /// @param _managerContainer contract that contains the address of the manager contract
    constructor(address _managerContainer) {
        require(_managerContainer != address(0), "3065");
        managerContainer = IManagerContainer(_managerContainer);
    }

    // -- Owner specific methods --
    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external override onlyOwner {
        emit PauseUpdated(paused, _val);
        paused = _val;
    }

    /// @notice adds a new strategy to the whitelist
    /// @param _strategy strategy's address
    function addStrategy(address _strategy)
        public
        override
        onlyOwner
        validAddress(_strategy)
    {
        require(!strategyInfo[_strategy].whitelisted, "3014");
        StrategyInfo memory info;
        info.performanceFee = _getManager().performanceFee();
        info.active = true;
        info.whitelisted = true;

        strategyInfo[_strategy] = info;

        emit StrategyAdded(_strategy);
    }

    /// @notice updates an existing strategy info
    /// @param _strategy strategy's address
    /// @param _info info
    function updateStrategy(address _strategy, StrategyInfo calldata _info)
        external
        override
        onlyOwner
        validStrategy(_strategy)
    {
        strategyInfo[_strategy] = _info;
        emit StrategyUpdated(_strategy, _info.active, _info.performanceFee);
    }

    /// @notice adds a new gauge to a strategy
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function addStrategyGauge(address _strategy, address _gauge)
        public
        override
        onlyOwner
        validStrategy(_strategy)
        validAddress(_gauge)
    {
        require(strategyGauges[_strategy] == address(0), "1103");
        strategyGauges[_strategy] = _gauge;
        emit GaugeAdded(_strategy, _gauge);
    }

    /// @notice removes a gauge from the strategy
    /// @param _strategy strategy's address
    function removeStrategyGauge(address _strategy)
        external
        override
        onlyOwner
        validStrategy(_strategy)
    {
        require(strategyGauges[_strategy] != address(0), "1104");
        strategyGauges[_strategy] = address(0);
        emit GaugeRemoved(_strategy);
    }

    /// @notice updates the strategy's gauge
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function updateStrategyGauge(address _strategy, address _gauge)
        external
        override
        onlyOwner
        validStrategy(_strategy)
        validAddress(_gauge)
    {
        require(strategyGauges[_strategy] != address(0), "1104");
        require(strategyGauges[_strategy] != _gauge, "1105");
        emit GaugeUpdated(_strategy, strategyGauges[_strategy], _gauge);
        strategyGauges[_strategy] = _gauge;
    }

    /// @notice performs several actions to config a strategy
    /// @param _strategy strategy's address
    /// @param _gauge gauge's address
    function configStrategy(address _strategy, address _gauge)
        external
        override
        onlyOwner
        validAddress(_strategy)
        validAddress(_gauge)
    {
        addStrategy(_strategy);
        addStrategyGauge(_strategy, _gauge);
        _getManager().addNonWithdrawableToken(
            IStrategy(_strategy).getReceiptTokenAddress()
        );
    }

    // -- User specific methods --

    /// @notice invests token into one of the whitelisted strategies
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function invest(
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    )
        external
        override
        validStrategy(_strategy)
        validAmount(_amount)
        validToken(_token)
        notPaused
        nonReentrant
        returns (uint256 tokenOutAmount, uint256 tokenInAmount)
    {
        address _holding = _getHoldingManager().userHolding(msg.sender);
        require(_getHoldingManager().isHolding(_holding), "3002");
        require(strategyInfo[_strategy].active, "1202");

        (tokenOutAmount, tokenInAmount) = _invest(
            _holding,
            _token,
            _strategy,
            _amount,
            _data
        );

        emit Invested(
            _holding,
            msg.sender,
            _token,
            _strategy,
            _amount,
            tokenOutAmount,
            tokenInAmount
        );
        return (tokenOutAmount, tokenInAmount);
    }

    /// @notice claims investment from one strategy and invests it into another
    /// @dev callable by holding's user
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _data MoveInvestmentData object
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function moveInvestment(address _token, MoveInvestmentData calldata _data)
        external
        override
        validStrategy(_data.strategyFrom)
        validStrategy(_data.strategyTo)
        nonReentrant
        notPaused
        returns (uint256 tokenOutAmount, uint256 tokenInAmount)
    {
        address _holding = _getHoldingManager().userHolding(msg.sender);
        require(_getHoldingManager().isHolding(_holding), "3002");

        require(strategyInfo[_data.strategyTo].active, "1202");

        (uint256 claimResult, ) = _claimInvestment(
            _holding,
            _data.strategyFrom,
            _data.shares,
            _token,
            _data.dataFrom
        );
        require(claimResult > 0, "3015");

        (tokenOutAmount, tokenInAmount) = _invest(
            _holding,
            _token,
            _data.strategyTo,
            claimResult,
            _data.dataTo
        );

        emit InvestmentMoved(
            _holding,
            msg.sender,
            _token,
            _data.strategyFrom,
            _data.strategyTo,
            _data.shares,
            tokenOutAmount,
            tokenInAmount
        );

        return (tokenOutAmount, tokenInAmount);
    }

    /// @notice claims a strategy investment
    /// @dev withdraws investment from a strategy
    /// @dev some strategies will allow only the tokenIn to be withdrawn
    /// @dev 'assetAmount' will be equal to 'tokenInAmount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    /// @return assetAmount returned asset amount obtained from the operation
    /// @return tokenInAmount returned token in amount
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    )
        external
        override
        validStrategy(_strategy)
        onlyAllowed(_holding)
        validAmount(_shares)
        nonReentrant
        notPaused
        returns (uint256 assetAmount, uint256 tokenInAmount)
    {
        require(_getHoldingManager().isHolding(_holding), "3002");

        (assetAmount, tokenInAmount) = _claimInvestment(
            _holding,
            _strategy,
            _shares,
            _asset,
            _data
        );

        emit StrategyClaim(
            _holding,
            msg.sender,
            _asset,
            _strategy,
            _shares,
            assetAmount,
            tokenInAmount
        );
    }

    /// @notice claims rewards from strategy
    /// @param _strategy strategy to invest into
    /// @param _data extra data
    /// @return rewards reward amounts
    /// @return tokens reward tokens
    function claimRewards(address _strategy, bytes calldata _data)
        external
        override
        validStrategy(_strategy)
        nonReentrant
        notPaused
        returns (uint256[] memory rewards, address[] memory tokens)
    {
        address _holding = _getHoldingManager().userHolding(msg.sender);
        require(_getHoldingManager().isHolding(_holding), "3002");

        (rewards, tokens) = IStrategy(_strategy).claimRewards(_holding, _data);

        for (uint256 i = 0; i < rewards.length; i++) {
            _accrueRewards(tokens[i], rewards[i], _holding);
        }
    }

    /// @notice invokes a generic call on holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _contract the external contract called by holding
    /// @param _call the call data
    /// @return success true/false
    /// @return result data obtained from the external call
    function invokeHolding(
        address _holding,
        address _contract,
        bytes calldata _call
    ) external override returns (bool success, bytes memory result) {
        require(_getManager().allowedInvokers(msg.sender), "1000");
        (success, result) = IHolding(_holding).genericCall(_contract, _call);
    }

    /// @notice invokes an approve operation for holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _token the asset for which the approval is performed
    /// @param _on the contract's address
    /// @param _amount the approval amount
    function invokeApprove(
        address _holding,
        address _token,
        address _on,
        uint256 _amount
    ) external override {
        require(_getManager().allowedInvokers(msg.sender), "1000");
        IHolding(_holding).approve(_token, _on, _amount);
    }

    /// @notice invokes a transfer operation for holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _token the asset for which the approval is performed
    /// @param _to the receiver address
    /// @param _amount the approval amount
    function invokeTransferal(
        address _holding,
        address _token,
        address _to,
        uint256 _amount
    ) external override {
        require(_getManager().allowedInvokers(msg.sender), "1000");
        IHolding(_holding).transfer(_token, _to, _amount);
    }

    /// @notice deposits receipt tokens into the liquidity gauge of the strategy
    /// @param _strategy strategy's address
    /// @param _amount amount of receipt tokens to stake
    function stakeReceiptTokens(address _strategy, uint256 _amount)
        external
        override
        notPaused
        validStrategy(_strategy)
    {
        address gaugeAddress = strategyGauges[_strategy];
        require(gaugeAddress != address(0), "1104");
        IHolding holding = IHolding(
            _getHoldingManager().userHolding(msg.sender)
        );
        address receiptTokenAddress = IStrategy(_strategy)
            .getReceiptTokenAddress();
        require(
            IERC20(receiptTokenAddress).balanceOf(address(holding)) >= _amount,
            "2002"
        );
        holding.approve(receiptTokenAddress, gaugeAddress, _amount);
        holding.genericCall(
            gaugeAddress,
            abi.encodeWithSignature(
                "deposit(uint256,address)",
                _amount,
                address(holding)
            )
        );
        emit ReceiptTokensStaked(_strategy, _amount);
    }

    /// @notice withdraws receipt tokens from the liquidity gauge of the strategy
    /// @param _strategy strategy's address
    /// @param _amount amount of receipt tokens to unstake
    function unstakeReceiptTokens(address _strategy, uint256 _amount)
        public
        override
        notPaused
        validStrategy(_strategy)
    {
        address gaugeAddress = strategyGauges[_strategy];
        require(gaugeAddress != address(0), "1104");
        IHolding holding = IHolding(
            _getHoldingManager().userHolding(msg.sender)
        );
        address receiptTokenAddress = IStrategy(_strategy)
            .getReceiptTokenAddress();
        uint256 oldBalance = IERC20(receiptTokenAddress).balanceOf(
            address(holding)
        );
        holding.genericCall(
            gaugeAddress,
            abi.encodeWithSignature("withdraw(uint256)", _amount)
        );
        uint256 newBalance = IERC20(receiptTokenAddress).balanceOf(
            address(holding)
        );
        require(newBalance - oldBalance == _amount, "3016");
        emit ReceiptTokensUnstaked(_strategy, _amount);
    }

    // -- Private type methods --
    /// @notice registers rewards as collateral
    function _accrueRewards(
        address _token,
        uint256 _amount,
        address _holding
    ) private {
        if (_amount > 0) {
            (, address shareRegistry) = _getStablesManager().shareRegistryInfo(
                _token
            );

            if (shareRegistry != address(0)) {
                //add collateral
                _getStablesManager().addCollateral(_holding, _token, _amount);
                emit CollateralAdjusted(_holding, _token, _amount, true);
            }
        }
    }

    /// @notice invests into a strategy
    function _invest(
        address _holding,
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) private returns (uint256 tokenOutAmount, uint256 tokenInAmont) {
        (tokenOutAmount, tokenInAmont) = IStrategy(_strategy).deposit(
            _token,
            _amount,
            _holding,
            _data
        );
        require(tokenOutAmount > 0, "3030");

        address _strategyStakingToken = IStrategy(_strategy).tokenIn();
        if (_token != _strategyStakingToken) {
            _getStablesManager().migrateDataToRegistry(
                _holding,
                _token,
                _strategyStakingToken,
                _amount,
                tokenInAmont
            );
        }
    }

    /// @notice withdraws invested amount from a strategy
    function _claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) private returns (uint256, uint256) {
        IStrategy strategyContract = IStrategy(_strategy);
        // First check if holding has enough receipt tokens to burn and unstake if necessary
        _checkReceiptTokenAvailability(strategyContract, _shares, _holding);

        (uint256 assetResult, uint256 tokenInResult) = strategyContract
            .withdraw(_shares, _holding, _asset, _data);
        require(assetResult > 0, "3016");

        // Some strategies will give rewards in the same token; we need to substract from collateral if there are any losses or add if there are any gains
        _getStablesManager().migrateDataToRegistry(
            _holding,
            strategyContract.tokenIn(),
            _asset,
            tokenInResult,
            assetResult
        );

        return (assetResult, tokenInResult);
    }

    function _checkReceiptTokenAvailability(
        IStrategy _strategy,
        uint256 _shares,
        address _holding
    ) private {
        uint256 tokenDecimals = _strategy.sharesDecimals();
        (, uint256 totalShares) = _strategy.recipients(_holding);
        uint256 rtAmount = _shares > totalShares ? totalShares : _shares;

        if (tokenDecimals > 18) {
            rtAmount = rtAmount / (10**(tokenDecimals - 18));
        } else {
            rtAmount = rtAmount * (10**(18 - tokenDecimals));
        }
        IERC20 receiptToken = IERC20(_strategy.getReceiptTokenAddress());
        uint256 holdingReceiptTokenBalance = receiptToken.balanceOf(_holding);
        if (holdingReceiptTokenBalance < rtAmount) {
            // Not enought Receipt Tokens in holding, need to unstake the difference
            unstakeReceiptTokens(
                address(_strategy),
                (rtAmount - holdingReceiptTokenBalance)
            );
        }
    }

    function _getManager() private view returns (IManager) {
        return IManager(managerContainer.manager());
    }

    function _getHoldingManager() private view returns (IHoldingManager) {
        return IHoldingManager(_getManager().holdingManager());
    }

    function _getStablesManager() private view returns (IStablesManager) {
        return IStablesManager(_getManager().stablesManager());
    }

    // @dev renounce ownership override to avoid losing contract's ownership
    function renounceOwnership() public pure override {
        revert("1000");
    }

    // -- modifiers --
    modifier validAddress(address _address) {
        require(_address != address(0), "3000");
        _;
    }

    modifier validStrategy(address _strategy) {
        require(strategyInfo[_strategy].whitelisted, "3029");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "2001");
        _;
    }

    modifier onlyAllowed(address _holding) {
        require(
            _getManager().holdingManager() == msg.sender ||
                _getManager().liquidationManager() == msg.sender ||
                _getHoldingManager().holdingUser(_holding) == msg.sender,
            "1000"
        );
        _;
    }

    modifier validToken(address _token) {
        require(_getManager().isTokenWhitelisted(_token), "3001");
        _;
    }

    modifier notPaused() {
        require(!paused, "1200");
        _;
    }
}