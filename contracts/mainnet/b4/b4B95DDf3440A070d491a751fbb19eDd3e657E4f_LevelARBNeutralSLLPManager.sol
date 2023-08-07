// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
pragma solidity 0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) payable external;
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILevelARBOracle {
  function getLLPPrice(address _token, bool _bool) external view returns (uint256);
  function getLLPAmountIn(
    uint256 _amtOut,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISLLP {
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool);
  function balanceOf(address _account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILevelARBNeutralSLLPVault {
  struct VaultConfig {
    // Target leverage of the vault in 1e18
    uint256 targetLeverage;
    // Management fee per second in % in 1e18
    uint256 mgmtFeePerSecond;
    // Performance fee in % in 1e18
    uint256 perfFee;
    // Max capacity of vault in 1e18
    uint256 maxCapacity;
  }

  function svTokenValue() external view returns (uint256);
  function treasury() external view returns (address);
  function vaultConfig() external view returns (VaultConfig memory);
  function totalSupply() external view returns (uint256);
  function mintMgmtFee() external;
  function togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ILevelMasterV2 {
  function pendingReward(
    uint256 _pid,
    address _user
  ) external view returns (uint256 pending);
  function userInfo(
    uint256 _pid,
    address _user
  ) external view returns (uint256, int256);
  function deposit(uint256 pid, uint256 amount, address to) external;
  function withdraw(uint256 pid, uint256 amount, address to) external;
  function harvest(uint256 pid, address to) external;
  function addLiquidity(
    uint256 pid,
    address assetToken,
    uint256 assetAmount,
    uint256 minLpAmount,
    address to
  ) external;
  function removeLiquidity(
    uint256 pid,
    uint256 lpAmount,
    address toToken,
    uint256 minOut,
    address to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ILiquidityRouter {
  function addLiquidityETH(
    address _tranche,
    uint256 _minLpAmount,
    address _to
  ) external payable;
  function addLiquidity(
    address _tranche,
    address _token,
    uint256 _amountIn,
    uint256 _minLpAmount,
    address _to
  ) external;
  function removeLiquidityETH(
    address _tranche,
    uint256 _lpAmount,
    uint256 _minOut,
    address _to
  ) external payable;
  function removeLiquidity(
    address _tranche,
    address _tokenOut,
    uint256 _lpAmount,
    uint256 _minOut,
    address _to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILVLStaking {
  function currentEpoch() external view returns (uint256);
  function stakedAmounts(address _user) external view returns (uint256);
  function stake(address _to, uint256 _amount) external;
  function unstake(address _to, uint256 _amount) external;
  function claimRewards(uint256 _epoch, address _to) external;
  function pendingRewards(uint256 _epoch, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {

  /* ========== ERRORS ========== */

  // Authorization
  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();

  // Vault deposit errors
  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositBalance();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error InsufficientLendingLiquidity();

  // Vault withdrawal errors
  error InvalidWithdrawToken();
  error EmptyWithdrawAmount();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();

  // Vault rebalance errors
  error EmptyLiquidityProviderAmount();

  // Flash loan prevention
  error WithdrawNotAllowedInSameDepositBlock();

  // Invalid Token
  error InvalidTokenIn();
  error InvalidTokenOut();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../interfaces/vaults/level/arb/ILiquidityRouter.sol";
import "../../../interfaces/vaults/level/arb/ILevelMasterV2.sol";
import "../../../interfaces/vaults/level/arb/ILVLStaking.sol";
import "../../../interfaces/vaults/level/arb/ILevelARBNeutralSLLPVault.sol";
import "../../../interfaces/tokens/ISLLP.sol";
import "../../../interfaces/lending/ILendingPool.sol";
import "../../../interfaces/oracles/ILevelARBOracle.sol";
import "../../../enum/ManagerAction.sol";
import "../../../utils/Errors.sol";

contract LevelARBNeutralSLLPManager is Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Vault contract
  ILevelARBNeutralSLLPVault public immutable vault;
  // WETH lending pool contract
  ILendingPool public immutable lendingPoolWETH;
  // WBTC lending pool contract
  ILendingPool public immutable lendingPoolWBTC;
  // USDT lending pool contract
  ILendingPool public immutable lendingPoolUSDT;
  // Level liquidity router
  ILiquidityRouter public immutable liquidityRouter;
  // SLLP stake pool to earn LVL
  ILevelMasterV2 public immutable sllpStakePool;
  // LVL stake pool to earn SLLP
  ILVLStaking public immutable lvlStakePool;
  // Steadefi deployed Level ARB oracle
  ILevelARBOracle public immutable levelARBOracle;

  /* ========== STRUCTS ========== */

  struct WorkData {
    address token; // deposit/withdraw token
    uint256 lpAmt; // lp amount to withdraw or add
    uint256 borrowWETHAmt;
    uint256 borrowWBTCAmt;
    uint256 borrowUSDTAmt;
    uint256 repayWETHAmt;
    uint256 repayWBTCAmt;
    uint256 repayUSDTAmt;
  }

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
  address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
  address public constant SLLP = 0x5573405636F4b895E511C9C54aAfbefa0E7Ee458;
  address public constant LVL = 0xB64E280e9D1B5DbEc4AcceDb2257A87b400DB149;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _lendingPoolWETH Lending pool contract
    * @param _lendingPoolWBTC Lending pool contract
    * @param _lendingPoolUSDT Lending pool contract
    * @param _liquidityRouter Level liquidity router
    * @param _sllpStakePool SLLP stake pool
    * @param _lvlStakePool LVL stake pool
    * @param _levelARBOracle Steadefi deployed Level ARB oracle
  */
  constructor(
    ILevelARBNeutralSLLPVault _vault,
    ILendingPool _lendingPoolWETH,
    ILendingPool _lendingPoolWBTC,
    ILendingPool _lendingPoolUSDT,
    ILiquidityRouter _liquidityRouter,
    ILevelMasterV2 _sllpStakePool,
    ILVLStaking _lvlStakePool,
    ILevelARBOracle _levelARBOracle
  ) {
    vault = _vault;
    lendingPoolWETH = _lendingPoolWETH;
    lendingPoolWBTC = _lendingPoolWBTC;
    lendingPoolUSDT = _lendingPoolUSDT;
    liquidityRouter = _liquidityRouter;
    sllpStakePool = _sllpStakePool;
    lvlStakePool = _lvlStakePool;
    levelARBOracle = _levelARBOracle;

    IERC20(address(WETH)).approve(address(lendingPoolWETH), type(uint256).max);
    IERC20(address(WBTC)).approve(address(lendingPoolWBTC), type(uint256).max);
    IERC20(address(USDT)).approve(address(lendingPoolUSDT), type(uint256).max);
    IERC20(address(WETH)).approve(address(liquidityRouter), type(uint256).max);
    IERC20(address(WBTC)).approve(address(liquidityRouter), type(uint256).max);
    IERC20(address(USDT)).approve(address(liquidityRouter), type(uint256).max);
    IERC20(address(SLLP)).approve(address(liquidityRouter), type(uint256).max);
    IERC20(address(SLLP)).approve(address(sllpStakePool), type(uint256).max);
    IERC20(address(LVL)).approve(address(lvlStakePool), type(uint256).max);
  }

  /* ========== MAPPINGS ========== */

  // Mapping of approved keepers
  mapping(address => bool) public keepers;

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved addresses for keepers
  */
  function onlyKeeper() private view {
    if (!keepers[msg.sender]) revert Errors.OnlyKeeperAllowed();
  }

  /**
    * Only allow approved address of vault
  */
  function onlyVault() private view {
    if (msg.sender != address(vault)) revert Errors.OnlyVaultAllowed();
  }

  /* ========== EVENTS ========== */

  event Rebalance(uint256 svTokenValueBefore, uint256 svTokenValueAfter);
  event Compound(address vault);

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Return the lp token amount held by manager
    * @return lpAmt amount of lp tokens owned by manager
  */
  function lpAmt() public view returns (uint256) {
    // SLLP pool id 0
    (uint256 amt, ) = sllpStakePool.userInfo(0, address(this));
    return amt;
  }

  /**
    * Get token debt amt from lending pool
    * @return tokenDebtAmts[] debt amt for each token
  */
  function debtAmts() public view returns (uint256, uint256, uint256) {
    return (
      lendingPoolWETH.maxRepay(address(this)),
      lendingPoolWBTC.maxRepay(address(this)),
      lendingPoolUSDT.maxRepay(address(this))
    );
  }

  /**
    * Get token debt amt from lending pool
    * @param _token address of token
    * @return tokenDebtAmt debt amt of specific token
  */
  function debtAmt(address _token) public view returns (uint256) {
    if (_token == WETH) {
      return lendingPoolWETH.maxRepay(address(this));
    } else if (_token == WBTC) {
      return lendingPoolWBTC.maxRepay(address(this));
    } else if (_token == USDT) {
      return lendingPoolUSDT.maxRepay(address(this));
    } else {
      revert("Invalid token");
    }
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * Called by keepers if rebalance conditions are triggered
    * @param _action Enum, 0 - Deposit, 1 - Withdraw, 2 - AddLiquidity, 3 - RemoveLiquidity
    * @param _data WorkData struct
  */
  function rebalance(
    ManagerAction _action,
    WorkData calldata _data
  ) external {
    onlyKeeper();

    vault.mintMgmtFee();

    uint256 svTokenValueBefore = vault.svTokenValue();

    this.work(
      _action,
      _data
    );

    emit Rebalance(svTokenValueBefore, vault.svTokenValue());
  }

  /**
    * General function for deposit, withdraw, rebalance, called by vault
    * @param _action Enum, 0 - Deposit, 1 - Withdraw, 2 - AddLiquidity, 3 - RemoveLiquidity
    * @param _data WorkData struct
  */
  function work(
    ManagerAction _action,
    WorkData calldata _data
  ) external {
    onlyKeeper();

    // ********** Deposit Flow && Rebalance: AddLiquidity Flow **********
    if (_action == ManagerAction.Deposit || _action == ManagerAction.AddLiquidity) {
      // borrow from lending pools
      _borrow(_data);
      // add liquidity
      _addLiquidity();
      // Stake SLLP
      _stake(SLLP);
    }

    // ********** Withdraw Flow **********
    if (_action == ManagerAction.Withdraw) {
      if (_data.lpAmt <= 0) revert Errors.EmptyLiquidityProviderAmount();
      // unstake SLLP
      _unstake(SLLP, _data.lpAmt);

      if (_data.token == USDT) {
        // remove LP receive USDT
        _removeLiquidity(_data);
        // repay lending pools
        _repay(_data);
        // transfer _data.token to vault for user to withdraw
        IERC20(USDT).safeTransfer(msg.sender, IERC20(USDT).balanceOf(address(this)));
      } else if (_data.token == SLLP) {
        // remove LP receive USDT, calculate remaining SLLP to withdraw
        uint256 sllpToWithdraw = _removeLiquidity(_data);
        // repay lending pools
        _repay(_data);
        // transfer staked sllpToken to vault for user to withdraw
        ISLLP(SLLP).transfer(msg.sender, sllpToWithdraw);
      }
    }

    // ********** Rebalance: Remove Liquidity Flow **********
    if (_action == ManagerAction.RemoveLiquidity) {
      if (_data.lpAmt <= 0) revert Errors.EmptyLiquidityProviderAmount();
      // unstake LP
      _unstake(SLLP, _data.lpAmt);
      // remove LP receive borrowToken
      _removeLiquidity(_data);
      // repay lending pools
      _repay(_data);
      // add liquidity if any leftover
      _addLiquidity();
      // Stake any newly minted SLLP from leftover
      _stake(SLLP);
    }
  }

  /**
    * Compound rewards, convert to more LP; called by vault or keeper
  */
  function compound() external {
    // Claim LVL rewards; pool id is 0 for SLLP pool
    if (sllpStakePool.pendingReward(0, address(this)) > 0) {
      sllpStakePool.harvest(0, address(this));

      // Stake LVL rewards for more SLLP
      _stake(LVL);
    }

    // Claim SLLP rewards
    uint256 currentLVLEpoch = lvlStakePool.currentEpoch();

    if (lvlStakePool.pendingRewards(currentLVLEpoch, address(this)) > 0) {
      lvlStakePool.claimRewards(currentLVLEpoch, address(this));

      // Transfer performance fees to treasury as SLLP
      uint256 fee = IERC20(SLLP).balanceOf(address(this))
                    * vault.vaultConfig().perfFee
                    / SAFE_MULTIPLIER;

      IERC20(SLLP).safeTransfer(vault.treasury(), fee);

      _stake(SLLP);
    }

    emit Compound(address(this));
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Internal function to convert token balances to LP tokens
  */
  function _addLiquidity() internal {
    if (IERC20(WETH).balanceOf(address(this)) > 0) {
      liquidityRouter.addLiquidity(
        SLLP, // SLLP tranche address
        WETH,
        IERC20(WETH).balanceOf(address(this)),
        0,
        address(this)
      );
    }
    if (IERC20(WBTC).balanceOf(address(this)) > 0) {
      liquidityRouter.addLiquidity(
        SLLP, // SLLP tranche address
        WBTC,
        IERC20(WBTC).balanceOf(address(this)),
        0,
        address(this)
      );
    }
    if (IERC20(USDT).balanceOf(address(this)) > 0) {
      liquidityRouter.addLiquidity(
        SLLP, // SLLP tranche address
        USDT,
        IERC20(USDT).balanceOf(address(this)),
        0,
        address(this)
      );
    }
  }

  /**
    * Internal function to withdraw LP tokens for multiple tokens
    * @param _data WorkData struct
    * @return lpAmtLeft Remaining SLLP to transfer to user
  */
  function _removeLiquidity(WorkData calldata _data) internal returns (uint256) {
    uint256 sllpAmtInForWETH;
    uint256 sllpAmtInForWBTC;
    uint256 sllpAmtInForUSDT;

    // remove lp receive enough WETH for repay
    if (_data.repayWETHAmt > 0) {
      sllpAmtInForWETH = levelARBOracle.getLLPAmountIn(_data.repayWETHAmt, SLLP, WETH);

      liquidityRouter.removeLiquidity(
        SLLP, // SLLP tranche address
        WETH,
        sllpAmtInForWETH,
        0,
        address(this)
      );
    }
    // remove lp receive enough WBTC for repay
    if (_data.repayWBTCAmt > 0) {
      sllpAmtInForWBTC = levelARBOracle.getLLPAmountIn(_data.repayWBTCAmt, SLLP, WBTC);

      liquidityRouter.removeLiquidity(
        SLLP, // SLLP tranche address
        WBTC,
        sllpAmtInForWBTC,
        0,
        address(this)
      );
    }
    // remove lp receive enough USDT for repay
    if (_data.repayUSDTAmt > 0) {
      sllpAmtInForUSDT = levelARBOracle.getLLPAmountIn(_data.repayUSDTAmt, SLLP, USDT);

      liquidityRouter.removeLiquidity(
        SLLP, // SLLP tranche address
        USDT,
        sllpAmtInForUSDT,
        0,
        address(this)
      );
    }
    // if desired withdraw token is USDT, remove remaining LP receive USDT
    // in rebalance scenario, removing LP to repay USDT debt
    if (_data.token == USDT) {
      liquidityRouter.removeLiquidity(
        SLLP, // SLLP tranche address
        USDT,
        _data.lpAmt - sllpAmtInForWETH - sllpAmtInForWBTC - sllpAmtInForUSDT,
        0,
        address(this)
      );
      return 0;
    } else if (_data.token == SLLP) {
      // else, desired withdraw token is SLLP, remove enough lp receive usdt for repay of usdt debt
       return _data.lpAmt - sllpAmtInForWETH - sllpAmtInForWBTC - sllpAmtInForUSDT;
    }
    return 0;
  }

  /**
    * Internal function to borrow from lending pools
    * @param _data   WorkData struct
  */
  function _borrow(WorkData calldata _data) internal {
    if (_data.borrowWETHAmt > 0) {
      lendingPoolWETH.borrow(_data.borrowWETHAmt);
    }
    if (_data.borrowWBTCAmt > 0) {
      lendingPoolWBTC.borrow(_data.borrowWBTCAmt);
    }
    if (_data.borrowUSDTAmt > 0) {
      lendingPoolUSDT.borrow(_data.borrowUSDTAmt);
    }
  }

  /**
    * Internal function to repay lending pools
    * @param _data   WorkData struct
  */
  function _repay(WorkData calldata _data) internal {
    if (_data.repayWETHAmt > 0) {
      lendingPoolWETH.repay(_data.repayWETHAmt);
    }
    if (_data.repayWBTCAmt > 0) {
      lendingPoolWBTC.repay(_data.repayWBTCAmt);
    }
    if (_data.repayUSDTAmt > 0) {
      lendingPoolUSDT.repay(_data.repayUSDTAmt);
    }
  }

  /**
    * Internal function to stake tokens
    * @param _token   Address of token to be staked
  */
  function _stake(address _token) internal {
    // Stake LVL rewards for more SLLP
    if (_token == LVL) {
      if (IERC20(LVL).balanceOf(address(this)) > 0) {
        lvlStakePool.stake(address(this), IERC20(LVL).balanceOf(address(this)));
      }
    }

    // Stake SLLP rewards for more LVL; pool id is 0 for SLLP pool
    if (_token == SLLP) {
      if (IERC20(SLLP).balanceOf(address(this)) > 0) {
        sllpStakePool.deposit(0, IERC20(SLLP).balanceOf(address(this)), address(this));
      }
    }
  }

  /**
    * Internal function to unstake tokens
    * @param _token   Address of token to be unstaked
    * @param _amt   Amt of token to unstake
  */
  function _unstake(address _token, uint256 _amt) internal {
    // Unstake LVL rewards for more SLLP
    if (_token == LVL) {
      lvlStakePool.unstake(address(this), _amt);
    }

    // Unstake SLLP rewards for more LVL; pool id is 0 for SLLP pool
    if (_token == SLLP) {
      sllpStakePool.withdraw(0, _amt, address(this));
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Unstake LVL from stake pool and transfer LVL to owner (manually sell for USDT)
    * only callable when vault is shut down
  */
  function unstakeAndTransferLVL() external {
    onlyVault();

    // Unstake all LVL tokens from LVL stake pool
    uint256 amt = lvlStakePool.stakedAmounts(address(this));

    if (amt > 0) {
      _unstake(LVL, amt);
    }

    IERC20(LVL).safeTransfer(owner(), IERC20(LVL).balanceOf(address(this)));
  }

  /**
    * Approve or revoke address to be a keeper for this vault
    * @param _keeper Keeper address
    * @param _approval Boolean to approve keeper or not
  */
  function updateKeeper(address _keeper, bool _approval) external onlyOwner {
    keepers[_keeper] = _approval;
  }
}