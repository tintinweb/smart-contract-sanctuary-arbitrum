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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface IWomDepositor {
    function deposit(uint256 _amount, address _stakeAddress) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

interface IWmxLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _account) external view returns (uint256 amount);

    function balances(address _account) external view returns (uint112 locked, uint32 nextUnlockIndex);

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 timestamp) external view returns (uint256 votes);

    function lockedBalances(address _user) external view returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
}

interface IBribeVoter {
    function vote(IERC20[] calldata _lpVote, int256[] calldata _deltas) external returns (uint256[][] memory bribeRewards);
    function votes(address _user, address _lpToken) external view returns (uint256);
    function infos(address _lpToken) external view returns (uint104 supplyBaseIndex, uint104 supplyVoteIndex, uint40 nextEpochStartTime, uint128 claimable, bool whitelist, address gaugeManager, address bribe);
}

interface IMasterWombatRewarder {
    function rewardTokens() external view returns (address[] memory tokens);
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface IWomDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
    function CreateBribesVotingToken() external returns(address);
}

interface IBribesRewardFactory {
    function CreateBribesRewards(address _stakingToken, address _lptoken, bool _callOperatorOnGetReward) external returns (address);
}

interface IRewards{
    function asset() external returns(address);
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function withdraw(uint256 assets, address receiver, address owner) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(address, uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address _token, address _account) external view returns (uint256);
    function updateOperatorData(address operator_, uint256 pid_) external;
    function setRewardTokenPaused(address token_, bool paused_) external;
    function balanceOf(address _account) external view returns (uint256 amount);
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (address token, uint256 periodFinish, uint256 rewardRate, uint256 lastUpdateTime, uint256 rewardPerTokenStored, uint256 queuedRewards, uint256 currentRewards, uint256 historicalRewards, bool paused);
}

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

interface INftLocker {
    function voteBoost(address _account) external view returns (uint256);
}

interface IBribeRewardsPool is IRewards {
    function withdrawAndUnwrapFrom(address _from, uint256 _amount, address _claimRecipient) external returns(bool);
    function updateBribesConfig(bool _callOperatorOnGetReward) external;
    function updateRatioConfig(uint256 _duration, uint256 _maxRewardRatio) external;
}

interface ITokenMinter is IERC20 {
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setOperator(address) external;
    function updateOperator(address) external;
    function getFactAmounMint(uint256 _amount) external view returns(uint256 amount);
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdrawLp(address, address, uint256) external returns (bool);
    function withdrawAllLp(address, address) external returns (bool);
    function lock(uint256 _lockDays) external;
    function releaseLock(uint256 _slot) external returns(uint256);
    function getGaugeRewardTokens(address _lptoken, address _gauge) external returns (address[] memory tokens);
    function claimCrv(address, uint256) external returns (address[] memory tokens, uint256[] memory balances);
    function balanceOfPool(address, address) external view returns (uint256);
    function operator() external view returns (address);
    function depositor() external view returns (address);
    function veWom() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function setDepositor(address _depositor) external;
    function setOwner(address _owner) external;
}

interface IPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);

    function addressOfAsset(address token) external view returns (address);
}

interface IWombatRouter {
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * Note: This function should be used as estimation only. The actual swap amount might
     * be different due to precision error (the error is typically under 1e-6)
     */
    function getAmountIn(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256[] memory haircuts);

    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeForTokens(
        address[] calldata tokenPath, // the first address should be WBNB
        address[] calldata poolPath,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForNative(
        address[] calldata tokenPath, // the last address should be WBNB
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidityNative(
        IPool pool,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external payable returns (uint256 liquidity);

    function removeLiquidityNative(
        IPool pool,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityFromOtherAssetAsNative(
        IPool pool,
        address fromToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    function crv() external view returns (address);
    function owner() external view returns (address);
    function voterProxy() external view returns (address);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function depositFor(uint256 _pid, uint256 _amount, bool _stake, address _receiver) external returns (bool);
    function setOwner(address _owner) external;
    function setPoolManager(address _poolManager) external;
    function voterProxyClaimRewards(uint256 _pid, address[] memory pendingTokens) external returns (uint256[] memory pendingRewards);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function approveDistribution(address _distro, address[] memory _distributionTokens, uint256 _amount) external;
    function approvePoolsCrvRewardsDistribution(address _token) external;
    function distributeRewards(uint256 _pid, address _lpToken, address _rewardToken, address[] memory _transferTo, uint256[] memory _transferAmount, bool[] memory _callQueue) external;
    function lpPendingRewards(address _lptoken, address _token) external returns (uint256);
    function earmarkRewards(uint256 _pid) external;
    function shutdownPool(uint256 _pid) external returns (bool);
    function forceShutdownPool(uint256 _pid) external returns (bool);
    function gaugeMigrate(address _newGauge, uint256[] memory migratePids) external;
    function voteExecute(address _voting, uint256 _value, bytes calldata _data) external returns (bytes memory);
    function mintRatio() external view returns (uint256);
    function customMintRatio(uint256 _pid) external view returns (uint256);
    function crvLockRewards() external view returns (address);
    function cvxLocker() external view returns (address);
}

interface IBoosterEarmark {
    function earmarkIncentive() external view returns (uint256);
    function distributionByTokenLength(address _token) external view returns (uint256);
    function distributionByTokens(address, uint256) external view returns (address, uint256, bool);
    function distributionTokenList() external view returns (address[] memory);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
}

interface ISwapRouter {
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);
}

interface IWomSwapDepositor {
    function pool() external view returns (address);
    function deposit(uint256 _amount, address _stakeAddress, uint256 _minAmountOut, uint256 _deadline) external returns (bool);
}

/**
 * @dev Interface of the MasterWombatV2
 */
interface IMasterWombatV2 {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
    external
    view
    returns (
        uint256 pendingRewards,
        IERC20[] memory bonusTokenAddresses,
        string[] memory bonusTokenSymbols,
        uint256[] memory pendingBonusRewards
    );

    function rewarderBonusTokenInfo(uint256 _pid)
    external
    view
    returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
    external
    returns (
        uint256 transfered,
        uint256[] memory rewards,
        uint256[][] memory additionalRewards
    );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

/**
 * @title   WomDepositor
 * @notice  Deposit WOM in staker contract once in smartLockPeriod.
            Have customLockDays mapping for instant custom deposits with specific days count.
 */
contract WomDepositor is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public wom;
    address public staker;
    address public minter;
    address public booster;
    uint256 public earmarkPid;

    uint256 public lockDays;
    uint256 public smartLockPeriod;

    uint256 public checkOldSlot;
    uint256 public currentSlot;
    uint256 public lastLockAt;
    bool public executing;

    mapping(uint256 => uint256) public slotEnds;
    mapping(address => uint256) public customLockDays;
    mapping(address => uint256) public customLockMinAmount;
    mapping(uint256 => bool) public lockedCustomSlots;
    mapping(uint256 => bool) public releasedCustomSlots;

    address[] public customLockAccounts;

    struct SlotInfo {
        uint256 number;
        uint256 amount;
    }
    mapping(address => SlotInfo[]) public customLockSlots;

    event UpdateOperator(address operator);
    event SetLockConfig(uint256 lockDays, uint256 smartLockPeriod);
    event SetBooster(address booster, uint256 pid);
    event SetCustomLockDays(address indexed account, uint256 lockDays, uint256 minAmount);
    event Deposit(address indexed account, address stakeAddress, uint256 amount);
    event SmartLockReleased(address indexed sender, uint256 indexed slot);
    event SmartLockCheck(address indexed sender, uint256 indexed checkOldSlot, bool isLockedCustomSlot);
    event SmartLock(address indexed sender, bool indexed customLockDays, uint256 indexed slot, uint256 amountToLock, uint256 senderLockDays, uint256 currentSlot, uint256 checkOldSlot);
    event ReleaseCustomLock(address indexed sender, uint256 index, uint256 indexed slot, uint256 amount);

    /**
     * @param _wom              WOM Token address
     * @param _staker           Voter Proxy address
     * @param _minter           Minter
     */
    constructor(
        address _wom,
        address _staker,
        address _minter,
        address _booster
    ) public {
        wom = _wom;
        staker = _staker;
        minter = _minter;
        booster = _booster;
    }

    function setLockConfig(uint256 _lockDays, uint256 _smartLockPeriod) external onlyOwner {
        require(_smartLockPeriod <= 7 days, "MAX_SMART_LOCK_PERIOD");
        lockDays = _lockDays;
        smartLockPeriod = _smartLockPeriod;

        emit SetLockConfig(_lockDays, _smartLockPeriod);
    }

    function setBooster(address _booster, uint256 _earmarkPid) external onlyOwner {
        booster = _booster;
        earmarkPid = _earmarkPid;

        emit SetBooster(_booster, _earmarkPid);
    }

    function updateMinterOperator() external onlyOwner {
        address depositor = IStaker(staker).depositor();
        ITokenMinter(minter).setOperator(depositor);
        emit UpdateOperator(depositor);
    }

    /**
     * @notice  Set custom lock options for specific account
     * @param _account      Account of spender
     * @param _lockDays     Specific days to lock WOM amount
     * @param _minAmount    Minimum amount to lock by spender
     */
    function setCustomLock(address _account, uint256 _lockDays, uint256 _minAmount) external onlyOwner {
        _setCustomLock(_account, _lockDays, _minAmount);
    }

    function _setCustomLock(address _account, uint256 _lockDays, uint256 _minAmount) internal {
        if (customLockMinAmount[_account] == 0) {
            customLockAccounts.push(_account);
        }
        customLockDays[_account] = _lockDays;
        customLockMinAmount[_account] = _minAmount;

        emit SetCustomLockDays(_account, _lockDays, _minAmount);
    }

    function deposit(
        uint256 _amount,
        uint256,
        bool,
        address _stakeAddress
    ) external {
        deposit(_amount, _stakeAddress);
    }

    function deposit(
        uint256 _amount,
        bool,
        address _stakeAddress
    ) external {
        deposit(_amount, _stakeAddress);
    }

    /**
     * @notice  Deposit tokens into the VeWom and mint WmxWom to depositors.
     * @param _amount  Amount WOM to deposit
     * @param _stakeAddress  Staker to deposit WmxWom
     */
    function deposit(uint256 _amount, address _stakeAddress) public returns (bool) {
        require(customLockDays[msg.sender] == 0, "custom");

        _smartLock(_amount);

        bool depositOnly = _stakeAddress == address(0);
        if(depositOnly){
            //mint for to
            ITokenMinter(minter).mint(msg.sender, _amount);
        }else{
            //mint here
            ITokenMinter(minter).mint(address(this), _amount);
            //stake for to
            IERC20(minter).safeApprove(_stakeAddress, 0);
            IERC20(minter).safeApprove(_stakeAddress, _amount);
            IRewards(_stakeAddress).stakeFor(msg.sender, _amount);
        }
        emit Deposit(msg.sender, _stakeAddress, _amount);
        return true;
    }

    /**
     * @notice  Trying to releaseLock every time on deposit and lock cumulative balance once in smartLockPeriod.
     * @param _amount  Amount WOM to deposit
     */
    function _smartLock(uint256 _amount) internal virtual {
        IERC20(wom).transferFrom(msg.sender, address(this), _amount);

        if (currentSlot > 1 && checkOldSlot >= currentSlot - 1) {
            checkOldSlot = 0;
        }

        if (slotEnds[checkOldSlot] != 0 && slotEnds[checkOldSlot] < block.timestamp) {
            if (!lockedCustomSlots[checkOldSlot]) {
                IStaker(staker).releaseLock(checkOldSlot);
                slotEnds[checkOldSlot] = slotEnds[currentSlot - 1];
                currentSlot = currentSlot - 1;
                emit SmartLockReleased(msg.sender, checkOldSlot);
            }
            checkOldSlot = checkOldSlot + 1;
            emit SmartLockCheck(msg.sender, checkOldSlot, lockedCustomSlots[checkOldSlot]);
        }

        if (executing || (lastLockAt + smartLockPeriod > block.timestamp && customLockDays[msg.sender] == 0)) {
            return;
        }
        executing = true;

        uint256 slot = currentSlot;
        currentSlot = currentSlot + 1;

        uint256 senderLockDays = lockDays;
        uint256 amountToLock = _amount;
        if (customLockDays[msg.sender] > 0) {
            senderLockDays = customLockDays[msg.sender];
            customLockSlots[msg.sender].push(SlotInfo(slot, _amount));
            lockedCustomSlots[slot] = true;
        } else {
            amountToLock = IERC20(wom).balanceOf(address(this));
        }

        if (IERC20(wom).balanceOf(staker) > 0) {
            IBooster(booster).earmarkRewards(earmarkPid);
        }

        IERC20(wom).safeTransfer(staker, amountToLock);
        IStaker(staker).lock(senderLockDays);

        slotEnds[slot] = block.timestamp + senderLockDays * 86400;

        lastLockAt = block.timestamp;

        executing = false;
        emit SmartLock(msg.sender, customLockDays[msg.sender] > 0, slot, amountToLock, senderLockDays, currentSlot, checkOldSlot);
    }

    /**
     * @notice  Deposit tokens into the VeWom by custom lock options.
     * @param _amount  Amount WOM to deposit
     */
    function depositCustomLock(uint256 _amount) public {
        require(customLockDays[msg.sender] > 0, "!custom");
        require(_amount >= customLockMinAmount[msg.sender], "<customLockMinAmount");
        _smartLock(_amount);
    }

    /**
     * @notice  Release locked tokens from specific slot
     * @param _index  Index of account slots
     */
    function releaseCustomLock(uint256 _index) public {
        SlotInfo memory slot = customLockSlots[msg.sender][_index];

        require(slotEnds[slot.number] < block.timestamp, "!ends");

        IStaker(staker).releaseLock(slot.number);
        IERC20(wom).safeTransfer(msg.sender, slot.amount);

        lockedCustomSlots[slot.number] = false;
        slotEnds[slot.number] = slotEnds[currentSlot - 1];

        checkOldSlot = slot.number + 1;

        uint256 len = customLockSlots[msg.sender].length;
        if (_index != len - 1) {
            customLockSlots[msg.sender][_index] = customLockSlots[msg.sender][len - 1];
        }
        customLockSlots[msg.sender].pop();

        currentSlot = currentSlot - 1;

        emit ReleaseCustomLock(msg.sender, _index, slot.number, slot.amount);
    }

    function getCustomLockAccounts() public view returns (address[] memory) {
        return customLockAccounts;
    }

    function getCustomLockSlotsLength(address _account) public view returns (uint256) {
        return customLockSlots[_account].length;
    }

    /**
     * @notice  Rescue all tokens but wom from contract
     * @param _tokens       Tokens addresses
     * @param _recipient    Recipient address
     */
    function rescueTokens(address[] memory _tokens, address _recipient) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            require(_tokens[i] != wom, "!wom");
            IERC20(_tokens[i]).safeTransfer(_recipient, IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./WomDepositor.sol";

contract WomDepositorV2 is WomDepositor {

    event Migrated(uint256 currentSlot, uint256 checkOldSlot, uint256 customLockAccountsLen, uint256 lockDays, uint256 smartLockPeriod, uint256 lastLockAt);

    WomDepositor public oldDepositor;
    bool public migrated;

    constructor(
        address _wom,
        address _staker,
        address _minter,
        address _booster,
        address _oldDepositor
    ) public WomDepositor(_wom, _staker, _minter, _booster) {
        if (_oldDepositor == address(0)) {
            migrated = true;
        } else {
            oldDepositor = WomDepositor(_oldDepositor);
        }
    }

    function _smartLock(uint256 _amount) internal override {
        require(migrated, "!migrated");

        super._smartLock(_amount);
    }

    function migrate(address[] memory _oldCustomLockAccounts, uint256[] memory _oldCustomLockSlotLengths) public onlyOwner {
        require(!migrated, "migrated");
        require(_oldCustomLockAccounts.length == _oldCustomLockSlotLengths.length, "length_mismatch");

        uint256 oldCurrentSlot = oldDepositor.currentSlot();

        for (uint256 i = currentSlot; i < oldCurrentSlot; i++) {
            slotEnds[i] = oldDepositor.slotEnds(i);
            currentSlot++;
        }

        require(oldCurrentSlot == currentSlot, "!current_slot");

        for (uint256 i = 0; i < _oldCustomLockAccounts.length; i++) {
            address account = _oldCustomLockAccounts[i];
            _setCustomLock(account, oldDepositor.customLockDays(account), oldDepositor.customLockMinAmount(account));

            uint256 length = _oldCustomLockSlotLengths[i];
            for (uint256 j = 0; j < length; j++) {
                (uint256 number, uint256 amount) = oldDepositor.customLockSlots(account, j);
                customLockSlots[account].push(SlotInfo(number, amount));
                lockedCustomSlots[number] = oldDepositor.lockedCustomSlots(number);
                releasedCustomSlots[number] = oldDepositor.releasedCustomSlots(number);
            }
        }

        lockDays = oldDepositor.lockDays();
        smartLockPeriod = oldDepositor.smartLockPeriod();
        checkOldSlot = oldDepositor.checkOldSlot();
        lastLockAt = oldDepositor.lastLockAt();
        migrated = true;

        emit Migrated(currentSlot, checkOldSlot, customLockAccounts.length, lockDays, smartLockPeriod, lastLockAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./WomDepositorV2.sol";

contract WomDepositorV3 is WomDepositorV2 {

    mapping(address => bool) public mintManagers;

    event SetMintManager(address minter, bool active);
    event Mint(address indexed to, uint256 amount, address indexed minter);

    constructor(
        address _wom,
        address _staker,
        address _minter,
        address _booster,
        address _oldDepositor
    ) public WomDepositorV2(_wom, _staker, _minter, _booster, _oldDepositor) {

    }

    function setMintManager(address _mintManager, bool _active) external onlyOwner {
        mintManagers[_mintManager] = _active;
        emit SetMintManager(_mintManager, _active);
    }

    function mint(address _to, uint256 _amount) external {
        require(mintManagers[msg.sender], "!mintManager");
        ITokenMinter(minter).mint(_to, _amount);
        emit Mint(_to, _amount, msg.sender);
    }
}