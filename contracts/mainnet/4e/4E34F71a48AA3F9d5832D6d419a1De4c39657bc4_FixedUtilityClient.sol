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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// Adjusted to use our local IERC20 interface instead of OpenZeppelin's

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

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
            "approve from non-zero"
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
            require(oldAllowance >= value, "allowance went below 0");
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
            require(abi.decode(returndata, (bool)), "erc20 op failed");
        }
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "../../interfaces/IFluidClient.sol";
import "../../interfaces/IEmergencyMode.sol";
import "../../interfaces/IERC20.sol";

import "../openzeppelin/SafeERC20.sol";

// BaseUtilityClient provides a utility client that can batchreward, drain, and supports emergency mode
// it does not provide getUtilityVars
abstract contract BaseUtilityClient is IFluidClient, IEmergencyMode {
    using SafeERC20 for IERC20;

    event DustCollected(address destination, uint amount);

    IERC20 immutable token_;

    address immutable dustCollector_;

    address internal oracle_;
    address internal operator_;
    address internal emergencyCouncil_;

    bool internal noEmergencyMode_;

    constructor(
        IERC20 _token,
        address _dustCollector,
        address _oracle,
        address _operator,
        address _council
    ) {
        token_ = _token;

        dustCollector_ = _dustCollector;
        oracle_ = _oracle;
        operator_ = _operator;
        emergencyCouncil_ = _council;

        noEmergencyMode_ = true;
    }

    function drain() external {
        require(msg.sender == operator_, "only operator");

        uint balance = token_.balanceOf(address(this));

        token_.safeTransfer(dustCollector_, balance);

        emit DustCollected(dustCollector_, balance);
    }

    // implements IFluidClient

    /// @inheritdoc IFluidClient
    function batchReward(Winner[] memory _rewards, uint _firstBlock, uint _lastBlock) external {
        require(noEmergencyMode_, "emergency mode!");
        require(msg.sender == oracle_, "only oracle");

        uint poolAmount = token_.balanceOf(address(this));

        for (uint i = 0; i < _rewards.length; i++) {
            Winner memory winner = _rewards[i];

            require(poolAmount >= winner.amount, "empty reward pool");

            poolAmount = poolAmount - winner.amount;

            token_.safeTransfer(winner.winner, winner.amount);
            emit Reward(
                winner.winner,
                winner.amount,
                _firstBlock,
                _lastBlock
            );
        }
    }

    /// @inheritdoc IFluidClient
    function getUtilityVars() external virtual view returns (UtilityVars memory);

    // implements IEmergencyMode

    /// @inheritdoc IEmergencyMode
    function enableEmergencyMode() external {
        require(msg.sender == emergencyCouncil_ || msg.sender == operator_, "not allowed");

        noEmergencyMode_ = false;

        emit Emergency(true);
    }

    /// @inheritdoc IEmergencyMode
    function disableEmergencyMode() external {
        require(msg.sender == operator_, "not allowed");

        noEmergencyMode_ = true;

        emit Emergency(false);
    }

    /// @inheritdoc IEmergencyMode
    function noEmergencyMode() external view returns (bool) {
        return noEmergencyMode_;
    }

    /// @inheritdoc IEmergencyMode
    function emergencyCouncil() external view returns (address) {
        return emergencyCouncil_;
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./BaseUtilityClient.sol";
import "../openzeppelin/SafeERC20.sol";

contract FixedUtilityClient is BaseUtilityClient {
    event ExchangeRateUpdated(uint256 num, uint256 denom);

    uint256 immutable deltaWeightNum_;
    uint256 immutable deltaWeightDenom_;

    uint256 private exchangeRateNum_;
    uint256 private exchangeRateDenom_;

    constructor(
        IERC20 _token,
        uint256 _deltaWeightNum,
        uint256 _deltaWeightDenom,
        uint256 _exchangeRateNum,
        uint256 _exchangeRateDenom,
        address _dustCollector,
        address _oracle,
        address _operator,
        address _council
    ) BaseUtilityClient(
        _token,
        _dustCollector,
        _oracle,
        _operator,
        _council
    ) {
        deltaWeightNum_ = _deltaWeightNum;
        deltaWeightDenom_ = _deltaWeightDenom;

        exchangeRateNum_ = _exchangeRateNum;
        exchangeRateDenom_ = _exchangeRateDenom;

        emit ExchangeRateUpdated(exchangeRateNum_, exchangeRateDenom_);
    }

    function updateExchangeRate(uint256 num, uint256 denom) external {
        require(msg.sender == operator_, "only operator");

        exchangeRateNum_ = num;
        exchangeRateDenom_ = denom;

        emit ExchangeRateUpdated(num, denom);
    }

    // implements IFluidClient

    /// @inheritdoc IFluidClient
    function getUtilityVars() external override view returns (UtilityVars memory) {
        require(noEmergencyMode_, "emergency mode!");

        return UtilityVars({
            poolSizeNative: token_.balanceOf(address(this)),
            tokenDecimalScale: 10**token_.decimals(),
            exchangeRateNum: exchangeRateNum_,
            exchangeRateDenom: exchangeRateDenom_,
            deltaWeightNum: deltaWeightNum_,
            deltaWeightDenom: deltaWeightDenom_,
            // this is a constant that the offchain worker knows !
            customCalculationType: "worker config overrides"
        });
    }
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

interface IEmergencyMode {
    /// @notice emitted when the contract enters emergency mode!
    event Emergency(bool indexed status);

    /// @notice should be emitted when the emergency council changes
    ///         if this implementation supports that
    event NewCouncil(address indexed oldCouncil, address indexed newCouncil);

    /**
     * @notice enables emergency mode preventing the swapping in of tokens,
     * @notice and setting the rng oracle address to null
     */
    function enableEmergencyMode() external;

    /**
     * @notice disables emergency mode, following presumably a contract upgrade
     * @notice (operator only)
     */
    function disableEmergencyMode() external;

    /**
     * @notice emergency mode status (true if everything is okay)
     */
    function noEmergencyMode() external view returns (bool);

    /**
     * @notice emergencyCouncil address that can trigger emergency functions
     */
    function emergencyCouncil() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
     * @dev Returns the number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

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

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

/// @dev parameter for the batchReward function
struct Winner {
    address winner;
    uint256 amount;
}

/// @dev returned from the getUtilityVars function to calculate distribution amounts
struct UtilityVars {
    uint256 poolSizeNative;
    uint256 tokenDecimalScale;
    uint256 exchangeRateNum;
    uint256 exchangeRateDenom;
    uint256 deltaWeightNum;
    uint256 deltaWeightDenom;
    string customCalculationType;
}

// DEFAULT_CALCULATION_TYPE to use as the value for customCalculationType if
// your utility doesn't have a worker override
string constant DEFAULT_CALCULATION_TYPE = "";

interface IFluidClient {

    /// @notice MUST be emitted when any reward is paid out
    event Reward(
        address indexed winner,
        uint amount,
        uint startBlock,
        uint endBlock
    );

    /**
     * @notice pays out several rewards
     * @notice only usable by the trusted oracle account
     *
     * @param rewards the array of rewards to pay out
     */
    function batchReward(Winner[] memory rewards, uint firstBlock, uint lastBlock) external;

    /**
     * @notice gets stats on the token being distributed
     * @return the variables for the trf
     */
    function getUtilityVars() external returns (UtilityVars memory);
}