// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {DepositTrait} from "./traits/DepositTrait.sol";
import {WETHTrait} from "./traits/WETHTrait.sol";
import {ZapperBase} from "./ZapperBase.sol";

/// @title WETH deposit zapper
/// @notice Zapper that allows to deposit ETH directly into a WETH pool
contract WETHDepositZapper is WETHTrait, DepositTrait {
    constructor(address pool) ZapperBase(pool) {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IFarmingPool} from "@1inch/farming/contracts/interfaces/IFarmingPool.sol";
import {ZapperBase} from "../ZapperBase.sol";

/// @title Deposit trait
/// @dev Provides empty shares <-> tokenOut conversion functions implementation for zappers with pool as output token
abstract contract DepositTrait is ZapperBase {
    /// @inheritdoc ZapperBase
    /// @dev Returns pool address
    function tokenOut() public view override returns (address) {
        return pool;
    }

    /// @inheritdoc ZapperBase
    /// @dev Does nothing
    function _previewSharesToTokenOut(uint256 shares) internal view override returns (uint256 tokenOutAmount) {}

    /// @inheritdoc ZapperBase
    /// @dev Does nothing
    function _previewTokenOutToShares(uint256 tokenOutAmount) internal view override returns (uint256 shares) {}

    /// @inheritdoc ZapperBase
    /// @dev Does nothing
    function _sharesToTokenOut(uint256 shares, address receiver) internal override returns (uint256 tokenOutAmount) {}

    /// @inheritdoc ZapperBase
    /// @dev Does nothing
    function _tokenOutToShares(uint256 tokenOutAmount, address owner) internal override returns (uint256 shares) {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IWETH} from "@gearbox-protocol/core-v2/contracts/interfaces/external/IWETH.sol";
import {ReceiveIsNotAllowedException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import {ETHZapperBase} from "../ETHZapperBase.sol";
import {ZapperBase} from "../ZapperBase.sol";

/// @title WETH trait
/// @notice Implements tokenIn <-> underlying conversion functions for WETH pool zappers with ETH as input token
abstract contract WETHTrait is ETHZapperBase {
    using Address for address payable;

    /// @notice Allows this contract to unwrap WETH and forbids receiving ETH in other ways
    receive() external payable {
        if (msg.sender != underlying) revert ReceiveIsNotAllowedException();
    }

    /// @inheritdoc ZapperBase
    function _previewTokenInToUnderlying(uint256 tokenInAmount) internal pure override returns (uint256 assets) {
        assets = tokenInAmount;
    }

    /// @inheritdoc ZapperBase
    function _previewUnderlyingToTokenIn(uint256 assets) internal pure override returns (uint256 tokenInAmount) {
        tokenInAmount = assets;
    }

    /// @inheritdoc ZapperBase
    function _tokenInToUnderlying(uint256 tokenInAmount) internal override returns (uint256 assets) {
        IWETH(underlying).deposit{value: tokenInAmount}();
        assets = tokenInAmount;
    }

    /// @inheritdoc ZapperBase
    function _underlyingToTokenIn(uint256 assets, address receiver) internal override returns (uint256 tokenInAmount) {
        tokenInAmount = assets;
        IWETH(underlying).withdraw(tokenInAmount);
        payable(receiver).sendValue(tokenInAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IZapper} from "../interfaces/zappers/IZapper.sol";

/// @title Zapper base
/// @notice Base contract for zappers that combine depositing/redeeming funds to/from a Gearbox pool
///         and other operations, such as wrapping tokens or staking pool shares, into a single call
abstract contract ZapperBase is IZapper {
    using SafeERC20 for IERC20;

    /// @notice Pool this zapper is connected to
    address public immutable pool;

    /// @notice `pool`'s underlying token
    address public immutable underlying;

    /// @notice Constructor
    /// @param pool_ Pool to connect a new zapper to
    constructor(address pool_) {
        pool = pool_; // U:[ZB-1]
        underlying = IPoolV3(pool_).underlyingToken(); // U:[ZB-1]
        _resetAllowance(underlying, pool); // U:[ZB-1]
    }

    /// @notice Zapper's input token
    function tokenIn() public view virtual returns (address);

    /// @notice Zapper's output token
    function tokenOut() public view virtual returns (address);

    // ------- //
    // PREVIEW //
    // ------- //

    /// @notice Returns the amount of `tokenOut` one would receive by depositing `tokenInAmount` of `tokenIn`
    function previewDeposit(uint256 tokenInAmount) external view returns (uint256 tokenOutAmount) {
        uint256 assets = tokenIn() == underlying ? tokenInAmount : _previewTokenInToUnderlying(tokenInAmount); // U:[ZB-2]
        uint256 shares = IPoolV3(pool).previewDeposit(assets); // U:[ZB-2]
        tokenOutAmount = tokenOut() == pool ? shares : _previewSharesToTokenOut(shares); // U:[ZB-2]
    }

    /// @notice Returns the amount of `tokenIn` one would receive by redeeming `tokenOutAmount` of `tokenOut`
    function previewRedeem(uint256 tokenOutAmount) external view returns (uint256 tokenInAmount) {
        uint256 shares = tokenOut() == pool ? tokenOutAmount : _previewTokenOutToShares(tokenOutAmount); // U:[ZB-3]
        uint256 assets = IPoolV3(pool).previewRedeem(shares); // U:[ZB-3]
        tokenInAmount = tokenIn() == underlying ? assets : _previewUnderlyingToTokenIn(assets); // U:[ZB-3]
    }

    /// @dev Returns the amount of `underlying` one would receive by converting `tokenInAmount` of `tokenIn`
    function _previewTokenInToUnderlying(uint256 tokenInAmount) internal view virtual returns (uint256 assets);

    /// @dev Returns the amount of `tokenIn` one would receive by converting `assets` of `underlying`
    function _previewUnderlyingToTokenIn(uint256 assets) internal view virtual returns (uint256 tokenInAmount);

    /// @dev Returns the amount of `tokenOut` one would receive by converting `shares` of `pool`'s shares
    function _previewSharesToTokenOut(uint256 shares) internal view virtual returns (uint256 tokenOutAmount);

    /// @dev Returns the amount of `pool`'s shares one would receive by converting `tokenOutAmount` of `tokenOut`
    function _previewTokenOutToShares(uint256 tokenOutAmount) internal view virtual returns (uint256 shares);

    // --- //
    // ZAP //
    // --- //

    /// @notice Performs redeem zap:
    ///         - receives `tokenOut` from `msg.sender` and converts it to `pool`'s shares
    ///         - redeems `pool`'s shares for `underlying`
    ///         - converts `underlying` to `tokenIn` and sends it to `receiver`
    /// @dev Requires approval from `msg.sender` for `tokenOut` to this contract
    function redeem(uint256 tokenOutAmount, address receiver) external returns (uint256 tokenInAmount) {
        tokenInAmount = _redeem(tokenOutAmount, receiver, msg.sender);
    }

    /// @notice Performs redeem zap using signed EIP-2612 permit message for zapper's output token:
    ///         - receives `tokenOut` from `msg.sender` and converts it to `pool`'s shares
    ///         - redeems `pool`'s shares for `underlying`
    ///         - converts `underlying` to `tokenIn` and sends it to `receiver`
    /// @dev `v`, `r`, `s` must be a valid signature of the permit message from `msg.sender` for `tokenOut` to this contract
    function redeemWithPermit(uint256 tokenOutAmount, address receiver, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint256 tokenInAmount)
    {
        try IERC20Permit(tokenOut()).permit(msg.sender, address(this), tokenOutAmount, deadline, v, r, s) {} catch {} // U:[ZB-5]
        tokenInAmount = _redeem(tokenOutAmount, receiver, msg.sender);
    }

    /// @dev `deposit` and `depositWithReferral` implementation
    /// @dev If `tokenOut` is `pool`, skips `_sharesToTokenOut` and mints shares directly to `receiver` on deposit
    function _deposit(uint256 tokenInAmount, address receiver, bool withReferral, uint256 referralCode)
        internal
        virtual
        returns (uint256 tokenOutAmount)
    {
        bool tokenOutIsPool = tokenOut() == pool;
        uint256 assets = _tokenInToUnderlying(tokenInAmount); // U:[ZB-4]
        uint256 shares = withReferral
            ? IPoolV3(pool).depositWithReferral(assets, tokenOutIsPool ? receiver : address(this), referralCode)
            : IPoolV3(pool).deposit(assets, tokenOutIsPool ? receiver : address(this)); // U:[ZB-4]
        tokenOutAmount = tokenOutIsPool ? shares : _sharesToTokenOut(shares, receiver); // U:[ZB-4]
    }

    /// @dev `redeem` and `redeemWithReferral` implementation
    /// @dev If `tokenOut` is `pool`, skips `_tokenOutToShares` and burns shares directly from `owner` on redeem
    /// @dev If `tokenIn` is `underlying`, skips `_underlyingToTokenIn` and sends tokens directly to `receiver` on redeem
    function _redeem(uint256 tokenOutAmount, address receiver, address owner)
        internal
        virtual
        returns (uint256 tokenInAmount)
    {
        bool tokenOutIsPool = tokenOut() == pool;
        bool tokenInIsUnderlying = tokenIn() == underlying;
        uint256 shares = tokenOutIsPool ? tokenOutAmount : _tokenOutToShares(tokenOutAmount, owner); // U:[ZB-5]
        uint256 assets = IPoolV3(pool).redeem({
            shares: shares,
            receiver: tokenInIsUnderlying ? receiver : address(this),
            owner: tokenOutIsPool ? owner : address(this)
        }); // U:[ZB-5]
        tokenInAmount = tokenInIsUnderlying ? assets : _underlyingToTokenIn(assets, receiver); // U:[ZB-5]
    }

    /// @dev Receives `tokenInAmount` of `tokenIn` from `msg.sender` and converts it to `underlying`
    function _tokenInToUnderlying(uint256 tokenInAmount) internal virtual returns (uint256 assets);

    /// @dev Converts `assets` of `underlying` to `tokenIn` and sends it to `receiver`
    function _underlyingToTokenIn(uint256 assets, address receiver) internal virtual returns (uint256 tokenInAmount);

    /// @dev Converts `shares` of `pool`'s shares to `tokenOut` and sends it to `receiver`
    function _sharesToTokenOut(uint256 shares, address receiver) internal virtual returns (uint256 tokenOutAmount);

    /// @dev Receives `tokenOutAmount` of `tokenOut` from `owner` and converts it to `pool`'s shares
    function _tokenOutToShares(uint256 tokenOutAmount, address owner) internal virtual returns (uint256 shares);

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Gives `spender` max allowance for this contract's `token`
    function _resetAllowance(address token, address spender) internal {
        IERC20(token).forceApprove(spender, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FarmAccounting } from "../accounting/FarmAccounting.sol";

interface IFarmingPool is IERC20 {
    event DistributorChanged(address oldDistributor, address newDistributor);
    event RewardUpdated(uint256 reward, uint256 duration);

    // View functions
    function distributor() external view returns(address);
    function farmInfo() external view returns(FarmAccounting.Info memory);
    function farmed(address account) external view returns(uint256);

    // User functions
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claim() external;
    function exit() external;

    // Owner functions
    function setDistributor(address distributor_) external;

    // Distributor functions
    function startFarming(uint256 amount, uint256 period) external;
    function rescueFunds(IERC20 token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IWETH {
    /// @dev Deposits native ETH into the contract and mints WETH
    function deposit() external payable;

    /// @dev Transfers WETH to another account
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Burns WETH from msg.sender and send back native ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZapperBase} from "./ZapperBase.sol";
import {IETHZapperDeposits, ETH_ADDRESS} from "../interfaces/zappers/IETHZapperDeposits.sol";

/// @title ETH zapper base
/// @notice Base contract for zappers with ETH as input token
abstract contract ETHZapperBase is ZapperBase, IETHZapperDeposits {
    /// @inheritdoc ZapperBase
    /// @dev Returns special address denoting ETH
    function tokenIn() public pure override returns (address) {
        return ETH_ADDRESS;
    }

    /// @notice Performs deposit zap:
    ///         - receives ETH from `msg.sender` and converts it to `underlying`
    ///         - deposits `underlying` into `pool`
    ///         - converts `pool`'s shares to `tokenOutAmount` of `tokenOut` and sends it to `receiver`
    function deposit(address receiver) external payable returns (uint256 tokenOutAmount) {
        tokenOutAmount = _deposit(msg.value, receiver, false, 0);
    }

    /// @notice Same as `deposit` but allows specifying the `referralCode` when depositing into the pool
    function depositWithReferral(address receiver, uint256 referralCode)
        external
        payable
        returns (uint256 tokenOutAmount)
    {
        tokenOutAmount = _deposit(msg.value, receiver, true, referralCode);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../interfaces/IPermit2.sol";
import "../interfaces/IWETH.sol";
import "../libraries/RevertReasonForwarder.sol";

/// @title Implements efficient safe methods for ERC20 interface.
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();
    error Permit2TransferAmountTooHigh();

    address private constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes4 private constant _PERMIT_LENGTH_ERROR = 0x68275857;  // SafePermitBadLength.selector
    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    function safeBalanceOf(
        IERC20 token,
        address account
    ) internal view returns(uint256 tokenBalance) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            mstore(0x00, selector)
            mstore(0x04, account)
            let success := staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20)
            tokenBalance := mload(0)

            if or(iszero(success), lt(returndatasize(), 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFromUniversal(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        bool permit2
    ) internal {
        if (permit2) {
            safeTransferFromPermit2(token, from, to, amount);
        } else {
            safeTransferFrom(token, from, to, amount);
        }
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Permit2 version of safeTransferFrom above.
    function safeTransferFromPermit2(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > type(uint160).max) revert Permit2TransferAmountTooHigh();
        bytes4 selector = IPermit2.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            mstore(add(data, 0x64), token)
            success := call(gas(), _PERMIT2, 0, data, 0x84, 0x0, 0x0)
            if success {
                success := gt(extcodesize(_PERMIT2), 0)
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /// @dev If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry.
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /// @dev Allowance increase with safe math check.
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /// @dev Allowance decrease with safe math check.
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, msg.sender, address(this), permit)) RevertReasonForwarder.reRevert();
    }

    function safePermit(IERC20 token, address owner, address spender, bytes calldata permit) internal {
        if (!tryPermit(token, owner, spender, permit)) RevertReasonForwarder.reRevert();
    }

    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool success) {
        return tryPermit(token, msg.sender, address(this), permit);
    }

    function tryPermit(IERC20 token, address owner, address spender, bytes calldata permit) internal returns(bool success) {
        bytes4 permitSelector = IERC20Permit.permit.selector;
        bytes4 daiPermitSelector = IDaiLikePermit.permit.selector;
        bytes4 permit2Selector = IPermit2.permit.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            switch permit.length
            case 100 {
                mstore(ptr, permitSelector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), spender)

                // Compact IERC20Permit.permit(uint256 value, uint32 deadline, uint256 r, uint256 vs)
                {  // stack too deep
                    let deadline := shr(224, calldataload(add(permit.offset, 0x20)))
                    let vs := calldataload(add(permit.offset, 0x44))

                    calldatacopy(add(ptr, 0x44), permit.offset, 0x20) // value
                    mstore(add(ptr, 0x64), sub(deadline, 1))
                    mstore(add(ptr, 0x84), add(27, shr(255, vs)))
                    calldatacopy(add(ptr, 0xa4), add(permit.offset, 0x24), 0x20) // r
                    mstore(add(ptr, 0xc4), shr(1, shl(1, vs)))
                }
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            case 72 {
                mstore(ptr, daiPermitSelector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), spender)

                // Compact IDaiLikePermit.permit(uint32 nonce, uint32 expiry, uint256 r, uint256 vs)
                {  // stack too deep
                    let expiry := shr(224, calldataload(add(permit.offset, 0x04)))
                    let vs := calldataload(add(permit.offset, 0x28))

                    mstore(add(ptr, 0x44), shr(224, calldataload(permit.offset)))
                    mstore(add(ptr, 0x64), sub(expiry, 1))
                    mstore(add(ptr, 0x84), true)
                    mstore(add(ptr, 0xa4), add(27, shr(255, vs)))
                    calldatacopy(add(ptr, 0xc4), add(permit.offset, 0x08), 0x20) // r
                    mstore(add(ptr, 0xe4), shr(1, shl(1, vs)))
                }
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            case 224 {
                mstore(ptr, permitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            case 256 {
                mstore(ptr, daiPermitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            case 96 {
                // Compact IPermit2.permit(uint160 amount, uint32 expiration, uint32 nonce, uint32 sigDeadline, uint256 r, uint256 vs)
                mstore(ptr, permit2Selector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), token)
                calldatacopy(add(ptr, 0x50), permit.offset, 0x14) // amount
                mstore(add(ptr, 0x64), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x14))), 1))) // expiration
                mstore(add(ptr, 0x84), shr(224, calldataload(add(permit.offset, 0x18)))) // nonce
                mstore(add(ptr, 0xa4), spender)
                mstore(add(ptr, 0xc4), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x1c))), 1))) // sigDeadline
                mstore(add(ptr, 0xe4), 0x100)
                mstore(add(ptr, 0x104), 0x40)
                calldatacopy(add(ptr, 0x124), add(permit.offset, 0x20), 0x20) // r
                calldatacopy(add(ptr, 0x144), add(permit.offset, 0x40), 0x20) // vs
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            case 352 {
                mstore(ptr, permit2Selector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            default {
                mstore(ptr, _PERMIT_LENGTH_ERROR)
                revert(ptr, 4)
            }
        }
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function safeDeposit(IWETH weth, uint256 amount) internal {
        if (amount > 0) {
            bytes4 selector = IWETH.deposit.selector;
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(0, selector)
                if iszero(call(gas(), weth, amount, 0, 4, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function safeWithdraw(IWETH weth, uint256 amount) internal {
        bytes4 selector = IWETH.withdraw.selector;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(0, selector)
            mstore(4, amount)
            if iszero(call(gas(), weth, 0, 0, 0x24, 0, 0)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    function safeWithdrawTo(IWETH weth, uint256 amount, address to) internal {
        safeWithdraw(weth, amount);
        if (to != address(this)) {
            assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                if iszero(call(_RAW_CALL_GAS_LIMIT, to, amount, 0, 0, 0, 0)) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;
pragma abicoder v1;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

interface IPoolV3Events {
    /// @notice Emitted when depositing liquidity with referral code
    event Refer(address indexed onBehalfOf, uint256 indexed referralCode, uint256 amount);

    /// @notice Emitted when credit account borrows funds from the pool
    event Borrow(address indexed creditManager, address indexed creditAccount, uint256 amount);

    /// @notice Emitted when credit account's debt is repaid to the pool
    event Repay(address indexed creditManager, uint256 borrowedAmount, uint256 profit, uint256 loss);

    /// @notice Emitted when incurred loss can't be fully covered by burning treasury's shares
    event IncurUncoveredLoss(address indexed creditManager, uint256 loss);

    /// @notice Emitted when new interest rate model contract is set
    event SetInterestRateModel(address indexed newInterestRateModel);

    /// @notice Emitted when new pool quota keeper contract is set
    event SetPoolQuotaKeeper(address indexed newPoolQuotaKeeper);

    /// @notice Emitted when new total debt limit is set
    event SetTotalDebtLimit(uint256 limit);

    /// @notice Emitted when new credit manager is connected to the pool
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when new debt limit is set for a credit manager
    event SetCreditManagerDebtLimit(address indexed creditManager, uint256 newLimit);

    /// @notice Emitted when new withdrawal fee is set
    event SetWithdrawFee(uint256 fee);
}

/// @title Pool V3 interface
interface IPoolV3 is IVersion, IPoolV3Events, IERC4626, IERC20Permit {
    function addressProvider() external view returns (address);

    function underlyingToken() external view returns (address);

    function treasury() external view returns (address);

    function withdrawFee() external view returns (uint16);

    function creditManagers() external view returns (address[] memory);

    function availableLiquidity() external view returns (uint256);

    function expectedLiquidity() external view returns (uint256);

    function expectedLiquidityLU() external view returns (uint256);

    // ---------------- //
    // ERC-4626 LENDING //
    // ---------------- //

    function depositWithReferral(uint256 assets, address receiver, uint256 referralCode)
        external
        returns (uint256 shares);

    function mintWithReferral(uint256 shares, address receiver, uint256 referralCode)
        external
        returns (uint256 assets);

    // --------- //
    // BORROWING //
    // --------- //

    function totalBorrowed() external view returns (uint256);

    function totalDebtLimit() external view returns (uint256);

    function creditManagerBorrowed(address creditManager) external view returns (uint256);

    function creditManagerDebtLimit(address creditManager) external view returns (uint256);

    function creditManagerBorrowable(address creditManager) external view returns (uint256 borrowable);

    function lendCreditAccount(uint256 borrowedAmount, address creditAccount) external;

    function repayCreditAccount(uint256 repaidAmount, uint256 profit, uint256 loss) external;

    // ------------- //
    // INTEREST RATE //
    // ------------- //

    function interestRateModel() external view returns (address);

    function baseInterestRate() external view returns (uint256);

    function supplyRate() external view returns (uint256);

    function baseInterestIndex() external view returns (uint256);

    function baseInterestIndexLU() external view returns (uint256);

    function lastBaseInterestUpdate() external view returns (uint40);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotaRevenue() external view returns (uint256);

    function lastQuotaRevenueUpdate() external view returns (uint40);

    function updateQuotaRevenue(int256 quotaRevenueDelta) external;

    function setQuotaRevenue(uint256 newQuotaRevenue) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setInterestRateModel(address newInterestRateModel) external;

    function setPoolQuotaKeeper(address newPoolQuotaKeeper) external;

    function setTotalDebtLimit(uint256 newLimit) external;

    function setCreditManagerDebtLimit(address creditManager, uint256 newLimit) external;

    function setWithdrawFee(uint256 newWithdrawFee) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

interface IZapper {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    function tokenIn() external view returns (address);

    function tokenOut() external view returns (address);

    function previewDeposit(uint256 tokenInAmount) external view returns (uint256 tokenOutAmount);

    function previewRedeem(uint256 tokenOutAmount) external view returns (uint256 tokenInAmount);

    function redeem(uint256 tokenOutAmount, address receiver) external returns (uint256 tokenInAmount);

    function redeemWithPermit(uint256 tokenOutAmount, address receiver, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint256 tokenInAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library FarmAccounting {
    error ZeroDuration();
    error DurationTooLarge();
    error AmountTooLarge();

    struct Info {
        uint40 finished;
        uint32 duration;
        uint184 reward;
        uint256 balance;
    }

    uint256 internal constant _MAX_REWARD_AMOUNT = 1e32;  // 108 bits
    uint256 internal constant _SCALE = 1e18;  // 60 bits

    /// @dev Requires extra 18 decimals for precision, result fits in 168 bits
    function farmedSinceCheckpointScaled(Info storage info, uint256 checkpoint) internal view returns(uint256 amount) {
        unchecked {
            (uint40 finished, uint32 duration, uint184 reward) = (info.finished, info.duration, info.reward);
            if (duration > 0) {
                uint256 elapsed = Math.min(block.timestamp, finished) - Math.min(checkpoint, finished);
                // size of (type(uint32).max * _MAX_REWARD_AMOUNT * _SCALE) is less than 200 bits, so there is no overflow
                return elapsed * reward * _SCALE / duration;
            }
        }
    }

    function startFarming(Info storage info, uint256 amount, uint256 period) internal returns(uint256) {
        if (period == 0) revert ZeroDuration();
        if (period > type(uint32).max) revert DurationTooLarge();

        // If something left from prev farming add it to the new farming
        (uint40 finished, uint32 duration, uint184 reward, uint256 balance) = (info.finished, info.duration, info.reward, info.balance);
        if (block.timestamp < finished) {
            amount += reward - farmedSinceCheckpointScaled(info, finished - duration) / _SCALE;
        }

        if (amount > _MAX_REWARD_AMOUNT) revert AmountTooLarge();

        (info.finished, info.duration, info.reward, info.balance) = (
            uint40(block.timestamp + period),
            uint32(period),
            uint184(amount),
            balance + amount
        );
        return amount;
    }

    function stopFarming(Info storage info) internal returns(uint256 leftover) {
        leftover = info.reward - farmedSinceCheckpointScaled(info, info.finished - info.duration) / _SCALE;
        (info.finished, info.duration, info.reward, info.balance) = (
            uint40(block.timestamp),
            uint32(0),
            uint184(0),
            info.balance - leftover
        );
    }

    function claim(Info storage info, uint256 amount) internal {
        info.balance -= amount;
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

/// @dev Special address that denotes pure ETH
address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

interface IETHZapperDeposits {
    function deposit(address receiver) external payable returns (uint256 tokenOutAmount);

    function depositWithReferral(address receiver, uint256 referralCode)
        external
        payable
        returns (uint256 tokenOutAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDaiLikePermit {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPermit2 {
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }
    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    /// @notice Packed allowance
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    function transferFrom(address user, address spender, uint160 amount, address token) external;

    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    function allowance(address user, address token, address spender) external view returns (PackedAllowance memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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