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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() {
        if (ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED)
            revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock funtions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

library BinaryVaultDataType {
    struct WithdrawalRequest {
        uint256 tokenId; // nft id
        uint256 shareAmount; // share amount
        uint256 underlyingTokenAmount; // underlying token amount
        uint256 timestamp; // request block time
        uint256 minExpectAmount; // Minimum underlying amount which user will receive
        uint256 fee;
    }

    struct BetData {
        uint256 bullAmount;
        uint256 bearAmount;
    }

    struct WhitelistedMarket {
        bool whitelisted;
        uint256 exposureBips; // % 10_000 based value. 100% => 10_000
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {IBinaryConfig} from "../../../interfaces/binary/IBinaryConfig.sol";
import {IBinaryVaultBaseFacet} from "../../../interfaces/binary/IBinaryVaultBaseFacet.sol";
import {IBinaryVaultPluginImpl} from "../../../interfaces/binary/IBinaryVaultPluginImpl.sol";
import {BinaryVaultDataType} from "../BinaryVaultDataType.sol";

library BinaryVaultFacetStorage {
    struct Layout {
        IBinaryConfig config;
        address underlyingTokenAddress;
        /// @notice Whitelisted markets, only whitelisted markets can take money out from the vault.
        mapping(address => BinaryVaultDataType.WhitelistedMarket) whitelistedMarkets;
        /// @notice share balances (token id => share balance)
        mapping(uint256 => uint256) shareBalances;
        /// @notice initial investment (tokenId => initial underlying token balance)
        mapping(uint256 => uint256) initialInvestments;
        /// @notice latest balance (token id => underlying token)
        /// @dev This should be updated when user deposits/withdraw or when take monthly management fee
        mapping(uint256 => uint256) recentSnapshots;
        // For risk management
        mapping(uint256 => BinaryVaultDataType.BetData) betData;
        // token id => request
        mapping(uint256 => BinaryVaultDataType.WithdrawalRequest) withdrawalRequests;
        mapping(address => bool) whitelistedUser;
        uint256 totalShareSupply;
        /// @notice TVL of vault. This should be updated when deposit(+), withdraw(-), trader lose (+), trader win (-), trading fees(+)
        uint256 totalDepositedAmount;
        /// @notice Watermark for risk management. This should be updated when deposit(+), withdraw(-), trading fees(+). If watermark < TVL, then set watermark = tvl
        uint256 watermark;
        // @notice Current pending withdrawal share amount. Plus when new withdrawal request, minus when cancel or execute withdraw.
        uint256 pendingWithdrawalTokenAmount;
        uint256 pendingWithdrawalShareAmount;
        uint256 withdrawalDelayTime;
        /// @dev The interval during which the maximum bet amount changes
        uint256 lastTimestampForExposure;
        uint256 currentHourlyExposureAmount;
        bool pauseNewDeposit;
        bool useWhitelist;
        // prevent to call initialize function twice
        bool initialized;

        // For credit
        address creditToken;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("balancecapital.ryze.storage.BinaryVaultFacet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

interface IVaultDiamond {
    function owner() external view returns (address);
}

contract BinaryVaultBaseFacet is IBinaryVaultBaseFacet, IBinaryVaultPluginImpl {
    uint256 private constant MAX_DELAY = 1 weeks;

    event ConfigChanged(address indexed config);
    event WhitelistMarketChanged(address indexed market, bool enabled);

    modifier onlyMarket() {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(s.whitelistedMarkets[msg.sender].whitelisted, "ONLY_MARKET");
        _;
    }

    modifier onlyOwner() {
        require(
            IVaultDiamond(address(this)).owner() == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function initialize(
        address underlyingToken_,
        address config_,
        address creditToken_
    ) external onlyOwner {
        require(underlyingToken_ != address(0), "ZERO_ADDRESS");
        require(config_ != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.underlyingTokenAddress = underlyingToken_;
        s.config = IBinaryConfig(config_);
        s.withdrawalDelayTime = 24 hours;
        s.creditToken = creditToken_;

        emit ConfigChanged(config_);
    }

    /// @notice Whitelist market on the vault
    /// @dev Only owner can call this function
    /// @param market Market contract address
    /// @param whitelist Whitelist or Blacklist
    /// @param exposureBips Exposure percent based 10_000. So 100% is 10_000
    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external virtual onlyOwner {
        require(market != address(0), "ZERO_ADDRESS");

        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(exposureBips <= s.config.FEE_BASE(), "INVALID_BIPS");

        s.whitelistedMarkets[market].whitelisted = whitelist;
        s.whitelistedMarkets[market].exposureBips = exposureBips;

        emit WhitelistMarketChanged(market, whitelist);
    }

    /// @dev set config
    function setConfig(address _config) external virtual onlyOwner {
        require(_config != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.config = IBinaryConfig(_config);

        emit ConfigChanged(_config);
    }

    function enableUseWhitelist(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.useWhitelist != value, "ALREADY_SET");
        s.useWhitelist = value;
    }

    function enablePauseDeposit(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.pauseNewDeposit != value, "ALREADY_SET");
        s.pauseNewDeposit = value;
    }

    function setWhitelistUser(address user, bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.whitelistedUser[user] != value, "ALREADY_SET");
        s.whitelistedUser[user] = value;
    }

    /// @notice Set withdrawal delay time
    /// @param _time time in seconds
    function setWithdrawalDelayTime(uint256 _time) external virtual onlyOwner {
        require(_time <= MAX_DELAY, "INVALID_TIME");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.withdrawalDelayTime = _time;
    }

    // getter functions
    function config() external view returns (address) {
        return address(BinaryVaultFacetStorage.layout().config);
    }

    function underlyingTokenAddress() external view returns (address) {
        return BinaryVaultFacetStorage.layout().underlyingTokenAddress;
    }

    function whitelistMarkets(
        address market
    ) external view returns (bool, uint256) {
        return (
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .whitelisted,
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .exposureBips
        );
    }

    function totalShareSupply() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalShareSupply;
    }

    function totalDepositedAmount() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalDepositedAmount;
    }

    function watermark() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().watermark;
    }

    function isWhitelistedUser(address user) external view returns (bool) {
        return BinaryVaultFacetStorage.layout().whitelistedUser[user];
    }

    function isUseWhitelistAndIsDepositPaused()
        external
        view
        returns (bool, bool)
    {
        return (
            BinaryVaultFacetStorage.layout().useWhitelist,
            BinaryVaultFacetStorage.layout().pauseNewDeposit
        );
    }

    function shareBalances(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().shareBalances[tokenId];
    }

    function initialInvestments(
        uint256 tokenId
    ) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().initialInvestments[tokenId];
    }

    function recentSnapshots(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().recentSnapshots[tokenId];
    }

    function withdrawalRequests(
        uint256 tokenId
    ) external view returns (BinaryVaultDataType.WithdrawalRequest memory) {
        return BinaryVaultFacetStorage.layout().withdrawalRequests[tokenId];
    }

    function pendingWithdrawalAmount()
        external
        view
        returns (uint256, uint256)
    {
        return (
            BinaryVaultFacetStorage.layout().pendingWithdrawalTokenAmount,
            BinaryVaultFacetStorage.layout().pendingWithdrawalShareAmount
        );
    }

    function withdrawalDelayTime() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().withdrawalDelayTime;
    }

    function setCreditToken(address _token) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage.layout();
        s.creditToken = _token;
    }

    function getCreditToken() external view returns (address) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage.layout();
        return s.creditToken;
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](22);
        s[0] = BinaryVaultBaseFacet.setWhitelistMarket.selector;
        s[1] = BinaryVaultBaseFacet.setConfig.selector;
        s[2] = BinaryVaultBaseFacet.enableUseWhitelist.selector;
        s[3] = BinaryVaultBaseFacet.enablePauseDeposit.selector;
        s[4] = BinaryVaultBaseFacet.setWhitelistUser.selector;
        s[5] = BinaryVaultBaseFacet.setWithdrawalDelayTime.selector;
        s[6] = BinaryVaultBaseFacet.config.selector;
        s[7] = BinaryVaultBaseFacet.underlyingTokenAddress.selector;
        s[8] = BinaryVaultBaseFacet.whitelistMarkets.selector;
        s[9] = BinaryVaultBaseFacet.totalShareSupply.selector;
        s[10] = BinaryVaultBaseFacet.totalDepositedAmount.selector;
        s[11] = BinaryVaultBaseFacet.watermark.selector;
        s[12] = BinaryVaultBaseFacet.isWhitelistedUser.selector;
        s[13] = BinaryVaultBaseFacet.isUseWhitelistAndIsDepositPaused.selector;
        s[14] = BinaryVaultBaseFacet.shareBalances.selector;
        s[15] = BinaryVaultBaseFacet.initialInvestments.selector;
        s[16] = BinaryVaultBaseFacet.recentSnapshots.selector;
        s[17] = BinaryVaultBaseFacet.withdrawalRequests.selector;
        s[18] = BinaryVaultBaseFacet.pendingWithdrawalAmount.selector;
        s[19] = BinaryVaultBaseFacet.withdrawalDelayTime.selector;
        s[20] = BinaryVaultBaseFacet.setCreditToken.selector;
        s[21] = BinaryVaultBaseFacet.getCreditToken.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IBinaryVaultBaseFacet).interfaceId;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import {IBinaryVaultPluginImpl} from "../../../interfaces/binary/IBinaryVaultPluginImpl.sol";
import {BinaryVaultDataType} from "../BinaryVaultDataType.sol";
import {BinaryVaultFacetStorage, IVaultDiamond} from "./BinaryVaultBaseFacet.sol";
import {ICreditToken} from "../../../interfaces/binary/ICreditToken.sol";
import {IBinaryVaultBetFacet} from "../../../interfaces/binary/IBinaryVaultBetFacet.sol";

contract BinaryVaultBetFacet is
    ReentrancyGuard,
    IBinaryVaultBetFacet,
    IBinaryVaultPluginImpl
{
    using SafeERC20 for IERC20;

    event VaultChangedFromMarket(
        uint256 prevTvl,
        uint256 totalDepositedAmount,
        uint256 watermark
    );

    modifier onlyMarket() {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(s.whitelistedMarkets[msg.sender].whitelisted, "ONLY_MARKET");
        _;
    }

    modifier onlyOwner() {
        require(
            IVaultDiamond(address(this)).owner() == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    /// @notice Transfer underlying token from user to vault. Update vault state for risk management
    /// @param amount bet amount
    /// @param from originating user
    /// @param endTime round close time
    /// @param position bull if 0, bear if 1 for binary options
    /// @param creditUsed if bet is using credit or not
    /// @param creditTokenIds credit token id from erc1155
    function onPlaceBet(
        uint256 amount,
        address from,
        uint256 endTime,
        uint8 position,
        bool creditUsed,
        uint256[] memory creditTokenIds,
        uint256[] memory creditTokenAmounts,
        address feeWallet,
        uint256 feeAmount
    ) external virtual onlyMarket {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        
        if (feeAmount > 0) {
            // Send fee amount to fee wallet
            IERC20(s.underlyingTokenAddress).safeTransferFrom(from, feeWallet, feeAmount);
        }
        if (!creditUsed) {
            IERC20(s.underlyingTokenAddress).safeTransferFrom(
                from,
                address(this),
                amount
            );
        } else {
            ICreditToken(s.creditToken).burnBatch(from, creditTokenIds, creditTokenAmounts);
        }
        BinaryVaultDataType.BetData storage data = s.betData[endTime];

        if (position == 0) {
            data.bullAmount += amount;
        } else {
            data.bearAmount += amount;
        }
    }

    /// @dev This function is used to update total deposited amount from user betting
    /// @param wonAmount amount won from user perspective (lost from vault perspective)
    /// @param loseAmount amount lost from user perspective (won from vault perspective)
    function onRoundExecuted(uint256 wonAmount, uint256 loseAmount, uint256 wonCreditAmount, uint256 loseCreditAmount)
        external
        virtual
        override
        onlyMarket
    {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 tradingFeeBips = s.config.tradingFee();
        uint256 fee1 = ((wonAmount - wonCreditAmount) * tradingFeeBips) / s.config.FEE_BASE();
        uint256 fee2 = ((loseAmount - loseCreditAmount) * tradingFeeBips) / s.config.FEE_BASE();

        uint256 tradingFee = fee1 + fee2;

        uint256 depositAmountTotal = wonAmount + loseAmount - (wonCreditAmount + loseCreditAmount);
        uint256 claimAmountTotal = ((2 * wonAmount * (s.config.FEE_BASE() - s.config.tradingFee())) /
                s.config.FEE_BASE());
        uint256 outAmountTotal = claimAmountTotal + tradingFee;
        
        uint256 prevTvl = s.totalDepositedAmount;

        if (depositAmountTotal > outAmountTotal) {
            s.totalDepositedAmount += depositAmountTotal - outAmountTotal;
        } else {
            uint256 escapeAmount = outAmountTotal - depositAmountTotal;
            s.totalDepositedAmount = s.totalDepositedAmount >= escapeAmount
                ? s.totalDepositedAmount - escapeAmount
                : 0;
        }

        // Update watermark
        if (s.totalDepositedAmount > s.watermark) {
            s.watermark = s.totalDepositedAmount;
        }

        if (tradingFee > 0) {
            IERC20(s.underlyingTokenAddress).safeTransfer(
                s.config.treasuryForReferrals(),
                tradingFee
            );
        }

        emit VaultChangedFromMarket(
            prevTvl,
            s.totalDepositedAmount,
            s.watermark
        );
    }

    /// @notice Claim winning rewards from the vault
    /// In this case, we charge fee from win traders.
    /// @dev Only markets can call this function
    /// @param user Address of winner
    /// @param amount Amount of rewards to claim
    /// @param isRefund whether its refund
    /// @return claim amount
    function claimBettingRewards(
        address user,
        uint256 amount,
        bool isRefund,
        bool creditUsed,
        uint256[] memory creditTokenIds,
        uint256[] memory creditTokenAmounts
    ) external virtual onlyMarket returns (uint256) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        uint256 claimAmount = isRefund
            ? amount
            : ((2 * amount * (s.config.FEE_BASE() - s.config.tradingFee())) /
                s.config.FEE_BASE());
        
        if (creditUsed && isRefund) {
            ICreditToken(s.creditToken).mintBatch(user, creditTokenIds, creditTokenAmounts);
        } else {
            IERC20(s.underlyingTokenAddress).safeTransfer(user, claimAmount);
        }

        return claimAmount;
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](3);
        s[0] = BinaryVaultBetFacet.onPlaceBet.selector;
        s[1] = BinaryVaultBetFacet.onRoundExecuted.selector;
        s[2] = BinaryVaultBetFacet.claimBettingRewards.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IBinaryVaultBetFacet).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryConfig {
    // solhint-disable-next-line
    function FEE_BASE() external view returns (uint256);

    function treasury() external view returns (address);

    function treasuryForReferrals() external view returns (address);

    function tradingFee() external view returns (uint256);

    function treasuryBips() external view returns (uint256);

    function maxVaultRiskBips() external view returns (uint256);

    function maxHourlyExposure() external view returns (uint256);

    function maxWithdrawalBipsForFutureBettingAvailable()
        external
        view
        returns (uint256);

    function binaryVaultImageTemplate() external view returns (string memory);

    function tokenLogo(address _token) external view returns (string memory);

    function vaultDescription() external view returns (string memory);

    function futureBettingTimeUpTo() external view returns (uint256);

    function bettingAmountBips() external view returns (uint256);

    function intervalForExposureUpdate() external view returns (uint256);

    function multiplier() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {BinaryVaultDataType} from "../../binary/vault/BinaryVaultDataType.sol";

interface IBinaryVaultBaseFacet {
    function whitelistMarkets(
        address market
    ) external view returns (bool, uint256);

    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external;

    function totalShareSupply() external view returns (uint256);

    function totalDepositedAmount() external view returns (uint256);
    function setWhitelistUser(address user, bool value) external;
    function enableUseWhitelist(bool value) external;
    function setCreditToken(address) external;
    function underlyingTokenAddress() external view returns(address);
    function getCreditToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVaultBetFacet {
    function onPlaceBet(
        uint256 amount,
        address from,
        uint256 endTime,
        uint8 position,
        bool creditUsed,
        uint256[] memory creditTokenIds,
        uint256[] memory creditTokenAmounts,
        address feeWallet,
        uint256 feeAmount
    ) external;

    function onRoundExecuted(uint256 wonAmount, uint256 loseAmount, uint256 wonCreditAmount, uint256 loseCreditAmount) external;
    function claimBettingRewards(
            address user,
            uint256 amount,
            bool isRefund,
            bool creditUsed,
            uint256[] memory creditTokenIds,
            uint256[] memory creditTokenAmounts
        ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVaultPluginImpl {
    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ICreditToken {
   function burn(address account, uint256 id, uint256 value) external;
   function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
   function mint(address to, uint256 id, uint256 value) external;
   function mintBatch(
      address to,
      uint256[] memory ids,
      uint256[] memory amounts
   ) external;
   function balanceOf(address user, uint256 tokenId) external view returns(uint256);
}