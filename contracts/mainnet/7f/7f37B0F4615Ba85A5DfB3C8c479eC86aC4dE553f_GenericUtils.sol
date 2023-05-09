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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.8.11;

import "../utils/Types.sol";

    
interface IFeesManager {

    enum FeeType{
        NOT_SET,
        FIXED,
        LINEAR_DECAY_WITH_AUCTION
    }


    struct RateData{
        FeeType rateType;
        uint48 startRate;
        uint48 endRate;
        uint48 auctionStartDate;
        uint48 auctionEndDate;
        uint48 poolExpiry;
    }

    error ZeroAddress();
    error NotAPool();
    error NoPermission();
    error InvalidType();
    error InvalidExpiry();
    error InvalidFeeRate();
    error InvalidFeeDates();

    event ChangeFee(address indexed pool, FeeType rateType, uint48 startRate, uint48 endRate, uint48 auctionStartDate, uint48 auctionEndDate);

    function setPoolRates(
        address _lendingPool,
        bytes32 _ratesAndType,
        uint48 _expiry,
        uint48 _protocolFee
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../utils/Types.sol";
interface IGenericPool {

    error TransferFailed();

    function getPoolSettings() external view returns (GeneralPoolSettings memory);
    function deposit(
        uint256 _depositAmount
    ) external;
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

interface IOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

import "../utils/Types.sol";

interface IPoolFactory {
    
    event DeployPool(
        address poolAddress,
        address deployer,
        address implementation,
        FactoryParameters factorySettings,
        GeneralPoolSettings poolSettings
    );

    error InvalidPauseTime();
    error OperationsPaused();
    error LendTokenNotSupported();
    error ColTokenNotSupported();
    error InvalidTokenPair();
    error LendRatio0();
    error InvalidExpiry();
    error ImplementationNotWhitelisted();
    error StrategyNotWhitelisted();
    error TokenNotSupportedWithStrategy();
    error ZeroAddress();
    error InvalidParameters();
    error NotGranted();
    error NotOwner();
    error NotAuthorized();



    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function protocolFee() external view returns (uint48);

    function repaymentsPaused() external view returns (bool);

    function isPoolPaused(address _pool, address _lendTokenAddr, address _colTokenAddr) external view returns (bool);

    function allowUpgrade() external view returns (bool);

    function implementations(PoolType _type) external view returns (address);

}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */



pragma solidity ^0.8.11;
interface IStrategy {
    error NotAPool();

    function getDestination() external view returns (address);
    function currentBalance() external view returns (uint256);
    function beforeLendTokensSent(uint256 _amount) external;
    function afterLendTokensReceived(uint256 _amount) external;
    function beforeColTokensSent(uint256 _amount) external;
    function afterColTokensReceived(uint256 _amount) external;
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IPoolFactory.sol";
import "../interfaces/IFeesManager.sol";
import "../interfaces/IGenericPool.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IOracle.sol";
import "./Types.sol";

library GenericUtils {
    using SafeERC20 for IERC20;

    uint256 internal constant HUNDRED_PERCENT = 100_0000;
    bytes32 private constant APPROVE_LEND = 0x1000000000000000000000000000000000000000000000000000000000000000; //1<<255
    bytes32 private constant APPROVE_COL = 0x0100000000000000000000000000000000000000000000000000000000000000; //2<<255
    bytes32 private constant APPROVE_LEND_STRATEGY = 0x0010000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant APPROVE_COL_STRATEGY = 0x0001000000000000000000000000000000000000000000000000000000000000;
   
    /* ========== EVENTS ========== */
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== ERRORS ========== */
    error OracleNotSet();

    /* ========== FUNCTIONS ========== */
    
    /// @notice                Makes required strategy approvals based off whether the collateral or lend token is being used.
    /// @param _strategy       The key used with the strategy.
    /// @param _lendToken      The address of lend token being used. 
    /// @param _colToken      The address of collateral token being used. 
    function initiateStrategy(bytes32 _strategy, IERC20 _lendToken, IERC20 _colToken) external returns (
        IStrategy strategy
    ){
        address strategyAddress = address(uint160(uint256(_strategy)));
        strategy = IStrategy(strategyAddress);
        // Allow strategy to manage the lend vault tokens on behalf of the pool. Useful with strategies that wrap EIP4626 vaults.
        if ((_strategy & APPROVE_LEND_STRATEGY) == APPROVE_LEND_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL_STRATEGY) == APPROVE_COL_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        }
        if ((_strategy & APPROVE_LEND) == APPROVE_LEND) {
            _lendToken.approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL) == APPROVE_COL) {
            _colToken.approve(strategyAddress, type(uint256).max);
        }
    }
  
    /// @notice                  Check if col price is valid based off of LTV requirement
    /// @dev                     We need to ensure that 1 unit of collateral is worth more than what 1 unit of collateral allows to borrow
    /// @param _priceFeed        Address of the oracle to use
    /// @param _colToken         Address of the collateral token
    /// @param _lendToken        Address of the lend token
    /// @param _mintRatio        Mint ratio of the pool
    /// @param _ltv              Dictated as minLTV or maxLTV dependent on _poolType
    /// @param _poolType         The type of pool calling this function
    function isValidPrice(
        IOracle _priceFeed,
        IERC20 _colToken,
        IERC20 _lendToken,
        uint256 _mintRatio,
        uint48 _ltv,
        PoolType _poolType
    ) external view returns (bool) {
        if (address(_priceFeed) == address(0)) revert OracleNotSet();
        int256 priceLend = _priceFeed.getPriceUSD(address(_lendToken));
        int256 priceCol = _priceFeed.getPriceUSD(address(_colToken));
        if (priceLend > 0 && priceCol > 0) { // Check that -1 or other invalid value was not returned for both assets
            if (_poolType == PoolType.LENDING_ONE_TO_MANY) {
                uint256 maxLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return maxLendValue >= ((_mintRatio * uint256(priceLend)) / 1e18);
            } else if (_poolType == PoolType.BORROWING_ONE_TO_MANY) {
                uint256 minLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return minLendValue <= ((_mintRatio * uint256(priceLend)) / 1e18);
            }
        }
        return false;
    }

    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _mintRatio           MintRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    // Amount of collateral to return is always computed as:
    //                                 lendTokenAmount
    // amountOfCollateralReturned  =   ---------------
    //                                    mintRatio
    // 
    // We also need to ensure that the correct amount of decimals are used. Output should always be in
    // collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _mintRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _mintRatio;
        }
    }

    /// @notice               Used when xfering tokens to an address from a pool.
    /// @param _token         Address of token that is to be xfered.
    /// @param _account       Address to send tokens to.
    /// @param _amount        Amount of tokens to xfer.
    function safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) external{
        if (_amount > 0){
            _token.safeTransfer(_account, _amount);
            emit BalanceChange(address(_token), _account, false, _amount);
        }
    }

    /// @notice              Used when xfering tokens on an addresses behalf. Approval must be done in a seperate transaction.
    /// @param _token        Address of token that is to be xfered.
    /// @param _from         Address of the sender.
    /// @param _to           Address of the recipient.
    /// @param _amount       Amount of tokens to xfer.
    /// @return received     Actual amount of tokens that _to receives.
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256 received){
        if (_amount > 0){
            uint256 initialBalance = _token.balanceOf(_to);
            _token.safeTransferFrom(_from, _to, _amount);
            received = _token.balanceOf(_to) - initialBalance;
            emit BalanceChange(address(_token), _to, true, received);
        }
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

enum PoolType{
    LENDING_ONE_TO_MANY,
    BORROWING_ONE_TO_MANY
}

/* ========== STRUCTS ========== */
struct DeploymentParameters {
    uint256 lendRatio;
    address colToken;
    address lendToken;
    bytes32 feeRatesAndType;
    PoolType poolType;
    bytes32 strategy;
    address[] allowlist;
    uint256 initialDeposit;
    uint48 expiry;
    uint48 ltv;
    uint48 pauseTime;
}

struct FactoryParameters {
    address feesManager;
    bytes32 strategy;
    address oracle;
    address treasury;
    address posTracker;
}

struct GeneralPoolSettings {
    PoolType poolType;
    address owner;
    uint48 expiry;
    IERC20 colToken;
    uint48 protocolFee;
    IERC20 lendToken;
    uint48 ltv;
    uint48 pauseTime;
    uint256 lendRatio;
    address[] allowlist;
    bytes32 feeRatesAndType;
}