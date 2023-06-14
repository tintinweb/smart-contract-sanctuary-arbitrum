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
pragma solidity 0.8.11;

interface IRewardPool4626 {
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function processIdleRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRewardStaking {
    function getReward(address _account, bool _claimExtras) external;

    function getReward(address _account) external;

    function getReward(address _account, address _token) external;

    function stakeFor(address, uint256) external;

    function processIdleRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title IAuraOFT
 * @author  AuraFinance
 */
interface IAuraOFT {
    function lock(
        address receiver,
        uint256 _cvxAmount,
        address zroPaymentAddress
    ) external payable;

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable;

    function canonicalChainId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { AuraMath } from "../../utils/AuraMath.sol";
import { IRewardStaking } from "../../interfaces/IRewardStaking.sol";
import { IRewardPool4626 } from "../../interfaces/IRewardPool4626.sol";
import { IAuraOFT } from "../interfaces/IAuraOFT.sol";

/**
 * @title   SidechainClaimZap
 * @author  AuraFinance
 * @notice  Claim zap to bundle various reward claims
 * @dev     Claims from all pools, Bridges/Locks to L1 if Wanted and compounds if needed.
 *
 */
contract SidechainClaimZap {
    using SafeERC20 for IERC20;
    using AuraMath for uint256;

    receive() external payable {}

    address public cvx;
    address public cvxCrv;
    address public compounder;
    address public owner;
    uint16 public canonicalChainID;

    /**
     * @dev Claim rewards amounts.
     * - depositCvxMaxAmount    The max amount of CVX to deposit if locking CVX on L1
     * - depositCvxCrvMaxAmount The max amount of CvxCrv to deposit if compounding
     * - bridgeCvxMaxAmount     The max amount of cvx to bridge to L1
     */
    struct ClaimRewardsAmounts {
        uint256 lockCvxMaxAmount;
        uint256 depositCvxCrvMaxAmount;
        uint256 bridgeCvxMaxAmount;
    }

    /**
     * @dev options.
     * - useAllWalletFunds       Flag: lock rewards and existing balance
     * - sendCvxToL1             Flag: Bridge CVX to L1
     * - lockCvxL1               Flag: Lock CVX on L1
     * - useCompounder           Flag: Deposit CvxCrv into L2 compounder
     * - refundEth               Flag: Send Eth Remainder Back to Sender
     * - overrideL1Receiver      Flag: Override receiving L1 Address
     * - l1Receiever             Flag: L1 Address to receive to
     * - zro                     Flag: Zro address passed by user
     * - adapterParams           Flag: adapter params passed by user
     */
    struct Options {
        bool useAllWalletFunds;
        bool sendCvxToL1;
        bool lockCvxL1;
        bool useCompounder;
        bool refundEth;
        bool overrideL1Receiver;
        address l1Receiever;
        address zro;
        bytes adapterParams;
    }

    function initialize(
        address _owner,
        address _cvx,
        address _cvxCrv,
        address _compounder
    ) external {
        require(cvx == address(0), "already initialized");
        owner = _owner;
        cvx = _cvx;
        cvxCrv = _cvxCrv;
        compounder = _compounder;
        canonicalChainID = IAuraOFT(_cvx).canonicalChainId();
    }

    /**
     * @notice Returns meta data of contract
     */
    function getName() external pure returns (string memory) {
        return "Sidechain ClaimZap V1.0";
    }

    /**
     * @notice Approve spending of:
     *          cvxCrv  -> Compounder
     */
    function setApprovals() external {
        require(msg.sender == owner, "!auth");
        _approveToken(cvxCrv, compounder);
    }

    /**
     * @notice Allows a spender to spend a token
     * @param _token     Token that will be spend
     * @param _spender   Address that will be spending
     */
    function _approveToken(address _token, address _spender) internal {
        IERC20(_token).safeApprove(address(_spender), 0);
        IERC20(_token).safeApprove(address(_spender), type(uint256).max);
    }

    /**
     * @notice Claim all the rewards
     * @param rewardContracts        Array of addresses for LP token rewards
     * @param extraRewardContracts   Array of addresses for extra rewards
     * @param tokenRewardContracts   Array of addresses for token rewards e.g vlCvxExtraRewardDistribution
     * @param tokenRewardTokens      Array of token reward addresses to use with tokenRewardContracts
     * @param amounts                Claim rewards amounts.
     * @param options                Claim options
     */
    function claimRewards(
        address zroPaymentAddress,
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        ClaimRewardsAmounts calldata amounts,
        Options calldata options
    ) external payable {
        require(tokenRewardContracts.length == tokenRewardTokens.length, "!parity");

        //Read balances prior to reward claims only if required
        uint256 cvxBalance;
        uint256 cvxCrvBalance;
        if (!options.useAllWalletFunds && _callOptions(options)) {
            cvxBalance = IERC20(cvx).balanceOf(msg.sender);
            cvxCrvBalance = IERC20(cvxCrv).balanceOf(msg.sender);
        }

        //claim from main curve LP pools
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            IRewardStaking(rewardContracts[i]).getReward(msg.sender, true);
        }
        //claim from extra rewards
        for (uint256 i = 0; i < extraRewardContracts.length; i++) {
            IRewardStaking(extraRewardContracts[i]).getReward(msg.sender);
        }
        //claim from multi reward token contract
        for (uint256 i = 0; i < tokenRewardContracts.length; i++) {
            IRewardStaking(tokenRewardContracts[i]).getReward(msg.sender, tokenRewardTokens[i]);
        }

        // deposit/lock/stake
        if (_callOptions(options)) {
            _handleRewards(cvxBalance, cvxCrvBalance, zroPaymentAddress, amounts, options);
        }

        if (options.refundEth) {
            (bool sent, ) = payable(msg.sender).call{ value: address(this).balance }("");
            require(sent, "!refund");
        }
    }

    /**
     * @notice returns a bool if handling of rewards should occur
     * @param options                Claim options
     */
    function _callOptions(Options calldata options) internal pure returns (bool) {
        return (options.lockCvxL1 || options.sendCvxToL1 || options.useCompounder);
    }

    /**
     * @notice  Bridge Rewards to L1 or Lock cvxCrv into compounders
     * @param removeCvxBalance       cvxBalance to ignore and not redeposit (starting Cvx balance)
     * @param removeCvxCrvBalance    cvxCrvBalance to ignore and not redeposit (starting CvxCrv balance)
     * @param amounts                Claim rewards amoutns.
     * @param options                see claimRewards
     */
    // prettier-ignore
    function _handleRewards( // solhint-disable-line 
        uint256 removeCvxBalance,   
        uint256 removeCvxCrvBalance,       
        address zroPaymentAddress,
        ClaimRewardsAmounts calldata amounts, 
        Options calldata options
    ) internal {

        address _l1receiver = options.overrideL1Receiver ? options.l1Receiever : msg.sender;

        //Either lock cvx
        if(options.lockCvxL1){
            (uint256 cvxBalance, bool continued) = _checkBalanceAndPullToken(
                cvx,
                removeCvxBalance, 
                amounts.lockCvxMaxAmount
            );
            if (continued) IAuraOFT(cvx).lock{value: msg.value}(_l1receiver, cvxBalance, zroPaymentAddress);
        }
        //or bridge it back to l1
        else if (options.sendCvxToL1) {
            (uint256 cvxBalance, bool continued) = _checkBalanceAndPullToken(
                cvx,
                removeCvxBalance, 
                amounts.bridgeCvxMaxAmount
            );

            if (continued) IAuraOFT(cvx).sendFrom{value: msg.value}(
                address(this), 
                canonicalChainID, 
                abi.encodePacked(_l1receiver), 
                cvxBalance,
                payable(_l1receiver), 
                options.zro, 
                options.adapterParams
            );
        }

        //deposit to l2 compounder
        if(options.useCompounder) {
            (uint256 cvxCrvBalance, bool continued) = _checkBalanceAndPullToken(
                cvxCrv,
                removeCvxCrvBalance, 
                amounts.depositCvxCrvMaxAmount
            );
            if (continued) IRewardPool4626(compounder).deposit(cvxCrvBalance, msg.sender);
        }
        
    }

    /**
     * @notice  Calculates the amount of a token to pull in, if this is above 0 then pulls token
     * @param _token                 the token to evaluate and pull
     * @param _removeAmount          quantity of token to ignore and not redeposit (ie starting balance)
     * @param _maxAmount             the maximum amount of a token
     */
    // prettier-ignore
    function _checkBalanceAndPullToken(
        address _token,
        uint256 _removeAmount,
        uint256 _maxAmount
    ) internal returns (uint256 _balance, bool continued) {
        _balance = IERC20(_token).balanceOf(msg.sender).sub(_removeAmount);
        _balance = AuraMath.min(_balance, _maxAmount);
        if (_balance > 0) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _balance);
            continued = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library AuraMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "AuraMath: uint224 Overflow");
        c = uint224(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "AuraMath: uint128 Overflow");
        c = uint128(a);
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        require(a <= type(uint112).max, "AuraMath: uint112 Overflow");
        c = uint112(a);
    }

    function to96(uint256 a) internal pure returns (uint96 c) {
        require(a <= type(uint96).max, "AuraMath: uint96 Overflow");
        c = uint96(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "AuraMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library AuraMath32 {
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint112.
library AuraMath112 {
    function add(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a + b;
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library AuraMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        c = a + b;
    }
}