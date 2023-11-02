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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

pragma solidity ^0.8.17;

enum DCSOptionType {
    BuyLow,
    SellHigh
}

enum SettlementStatus {
    NotAuctioned,
    Auctioned,
    InitialPremiumPaid,
    AwaitingSettlement,
    Settled,
    Defaulted
}

struct DCSProductCreationParams {
    uint128 maxDepositAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    address quoteAssetAddress;
    address baseAssetAddress;
    DCSOptionType dcsOptionType;
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
}

struct DCSProduct {
    uint32 id;
    bool isDepositQueueOpen;
    uint128 maxDepositAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 sumVaultUnderlyingAmounts; //revisit later
    address[] vaults;
    DCSOptionType dcsOptionType;
    address quoteAssetAddress; // should be immutable
    address baseAssetAddress; // should be immutable
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
}

struct DCSVault {
    SettlementStatus settlementStatus;
    bool isPayoffInDepositAsset;
    uint256 aprBps;
    uint256 initialSpotPrice;
    uint256 strikePrice;
    uint256 totalYield;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Withdrawer, VaultStatus } from "../../../Structs.sol";
import {
    DCSProductCreationParams,
    DCSProduct,
    SettlementStatus
} from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

interface IDCSProductEntry {
    // FUNCTIONS

    function getDCSProduct(
        uint32 productId
    ) external view returns (DCSProduct memory);

    function getDCSLatestProductId() external view returns (uint32);

    function getDCSProductDepositAsset(
        uint32 productId
    ) external view returns (address);

    function getDCSDepositQueue(
        uint32 productId
    )
        external
        view
        returns (
            address[] memory depositors,
            uint128[] memory amounts,
            uint128 totalAmount
        );

    function getDCSWithdrawalQueue(
        address vaultAddress
    )
        external
        view
        returns (
            Withdrawer[] memory withdrawers,
            uint256[] memory amounts,
            uint256 totalAmount
        );

    function isDCSWithdrawalPossible(
        address vaultAddress
    ) external view returns (bool);

    function calculateDCSVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint256);

    function createDCSProduct(
        DCSProductCreationParams calldata creationParams
    ) external returns (uint32);

    function addToDCSDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function processDCSDepositQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    function addToDCSWithdrawalQueue(
        address vault,
        uint256 sharesAmount,
        uint32 nextProductId
    ) external;

    function processDCSWithdrawalQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    function checkDCSTradeExpiry(address vaultAddress) external;

    function checkDCSSettlementDefault(address vaultAddress) external;

    function collectDCSVaultFees(address vaultAddress) external;

    function submitDispute(address vaultAddress) external;

    function processTradeDispute(
        address vaultAddress,
        uint256 newPrice
    ) external;

    function overrideOraclePrice(
        address vaultAddress,
        uint64 timestamp,
        uint256 newPrice
    ) external;

    function getOraclePriceOverride(
        address vaultAddress,
        uint64 timestamp
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IProductViewEntry {
    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracleEntry {
    enum DataSource {
        None,
        Pyth
    }

    event DataSourceAdapterSet(DataSource dataSource, address adapter);

    /// @notice Gets `asset` price at `timestamp` in terms of USD using `dataSource`
    function getSinglePrice(
        address asset,
        uint64 timestamp,
        DataSource dataSource
    ) external view returns (uint256);

    /// @notice Gets `baseAsset` price at `timestamp` in terms of `quoteAsset` using `dataSource`
    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint64 timestamp,
        DataSource dataSource
    ) external view returns (uint256);

    /// @notice Sets data source adapter
    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external;

    function getTargetDecimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRedepositManager {
    function redeposit(
        uint32 productId,
        address asset,
        uint128 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IProductViewEntry } from "../common/interfaces/IProductViewEntry.sol";
import {
    IDCSProductEntry
} from "../cega-strategies/dcs/interfaces/IDCSProductEntry.sol";
import { Transfers } from "../utils/Transfers.sol";
import { IRedepositManager } from "./interfaces/IRedepositManager.sol";

contract RedepositManager {
    using Transfers for address;

    // CONSTANTS

    uint32 public constant DCS_STRATEGY_ID = 1;

    address public immutable cegaEntry;

    // MODIFIERS

    modifier onlyCegaEntry() {
        require(msg.sender == cegaEntry, "400:NotCegaEntry");
        _;
    }

    // CONSTRUCTOR

    constructor(address _cegaEntry) {
        cegaEntry = _cegaEntry;
    }

    // FUNCTIONS

    receive() external payable {}

    function redeposit(
        uint32 productId,
        address asset,
        uint128 amount,
        address receiver
    ) external onlyCegaEntry {
        uint32 strategyId = IProductViewEntry(cegaEntry).getStrategyOfProduct(
            productId
        );

        if (strategyId == DCS_STRATEGY_ID) {
            address productDepositAsset = IDCSProductEntry(cegaEntry)
                .getDCSProductDepositAsset(productId);
            if (productDepositAsset == asset) {
                // Redeposit
                uint256 value = asset.ensureApproval(cegaEntry, amount);
                IDCSProductEntry(cegaEntry).addToDCSDepositQueue{
                    value: value
                }(productId, amount, receiver);
            } else {
                // Incompatible asset, transfer to receiver
                asset.transfer(receiver, amount);
            }
        } else {
            // Impossible to redeposit, transfer to receiver
            asset.transfer(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { DCSProduct, DCSVault } from "./cega-strategies/dcs/DCSStructs.sol";
import { IOracleEntry } from "./oracle-entry/interfaces/IOracleEntry.sol";

uint32 constant DCS_STRATEGY_ID = 1;

struct DepositQueue {
    uint128 queuedDepositsTotalAmount;
    mapping(address => uint128) amounts;
    address[] depositors;
}

struct Withdrawer {
    address account;
    uint32 nextProductId;
}

struct WithdrawalQueue {
    uint256 queuedWithdrawalSharesAmount;
    mapping(address => mapping(uint32 => uint256)) amounts;
    Withdrawer[] withdrawers;
}

struct CegaGlobalStorage {
    // Global information
    uint32 strategyIdCounter;
    uint32 productIdCounter;
    uint32[] strategyIds;
    mapping(uint32 => uint32) strategyOfProduct;
    mapping(address => Vault) vaults;
    // DCS information
    mapping(uint32 => DCSProduct) dcsProducts;
    mapping(uint32 => DepositQueue) dcsDepositQueues;
    mapping(address => DCSVault) dcsVaults;
    mapping(address => WithdrawalQueue) dcsWithdrawalQueues;
    // vaultAddress => (timestamp => price)
    mapping(address => mapping(uint64 => uint256)) oraclePriceOverride;
}

struct Vault {
    uint32 productId;
    uint256 yieldFeeBps;
    uint256 managementFeeBps;
    uint256 vaultStartDate;
    uint40 tradeStartDate;
    address auctionWinner;
    address underlyingAsset;
    uint256 totalAssets;
    VaultStatus vaultStatus;
    uint256 auctionWinnerTokenId;
    IOracleEntry.DataSource dataSource;
    bool isInDispute;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct MMNFTMetadata {
    address vaultAddress;
    uint40 tradeStartDate;
    uint40 tradeEndDate;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Transfers {
    using SafeERC20 for IERC20;

    function receiveTo(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256 nativeValueReceived) {
        if (asset == address(0)) {
            require(msg.value >= amount, "400:ValueTooSmall");
            (bool success, ) = to.call{ value: amount }("");
            if (!success) {
                revert("500:TransferFailed");
            }
            return amount;
        } else {
            IERC20(asset).safeTransferFrom(msg.sender, to, amount);
            return 0;
        }
    }

    function transfer(address asset, address to, uint256 amount) internal {
        if (asset == address(0)) {
            (bool success, ) = payable(to).call{ value: amount }("");
            if (!success) {
                revert("500:TransferFailed");
            }
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }

    /// @notice Adds if needed, and returns required value to pass
    /// @param asset Asset to ensure
    /// @param to Spender
    /// @param amount Amount to ensure
    /// @return Native value to pass
    function ensureApproval(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (asset != address(0)) {
            uint256 allowance = IERC20(asset).allowance(address(this), to);
            if (allowance < type(uint256).max) {
                IERC20(asset).approve(to, type(uint256).max);
            }
            return 0;
        } else {
            return amount;
        }
    }
}