// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20_Bridge_Logic_Restricted} from "./ERC20_Bridge_Logic_Restricted.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidReceiver {
  using SafeERC20 for IERC20;

  IERC20_Bridge_Logic_Restricted public bridge;

  mapping(address => mapping(IERC20 => uint256)) public deposits;

  constructor(IERC20_Bridge_Logic_Restricted _bridge) {
    bridge = _bridge;
    bridge.exempt_depositor();
  }

  function deposit(IERC20 asset, uint256 amount, bytes32 vegaPubkey, address recovery) public {
    asset.safeTransferFrom(msg.sender, address(this), amount);

    try bridge.deposit_asset(address(asset), amount, vegaPubkey) {
      // success
    } catch {
      deposits[recovery][asset] += amount;
    }
  }

  function recover(IERC20 asset) external {
    uint256 amount = deposits[msg.sender][asset];
    deposits[msg.sender][asset] = 0;
    asset.safeTransfer(msg.sender, amount);
  }

  function approve(IERC20 token) external {
    token.approve(address(bridge), type(uint256).max);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC20.sol";
import "./IERC20_Bridge_Logic_Restricted.sol";
import "./IMultisigControl.sol";
import "./ERC20_Asset_Pool.sol";

/// @title ERC20 Bridge Logic
/// @author Vega Protocol
/// @notice This contract is used by Vega network users to deposit and withdraw ERC20 tokens to/from Vega.
// @notice All funds deposited/withdrawn are to/from the assigned ERC20_Asset_Pool
contract ERC20_Bridge_Logic_Restricted is IERC20_Bridge_Logic_Restricted {
    address payable public erc20_asset_pool_address;
    // asset address => is listed
    mapping(address => bool) listed_tokens;
    // Vega asset ID => asset_source
    mapping(bytes32 => address) vega_asset_ids_to_source;
    // asset_source => Vega asset ID
    mapping(address => bytes32) asset_source_to_vega_asset_id;

    /// @param erc20_asset_pool Initial Asset Pool contract address
    constructor(address payable erc20_asset_pool) {
        require(erc20_asset_pool != address(0), "invalid asset pool address");
        erc20_asset_pool_address = erc20_asset_pool;
    }

    function multisig_control_address() internal view returns (address) {
        return ERC20_Asset_Pool(erc20_asset_pool_address).multisig_control_address();
    }

    /***************************FUNCTIONS*************************/
    /// @notice This function lists the given ERC20 token contract as valid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param vega_asset_id Vega-generated asset ID for internal use in Vega Core
    /// @param lifetime_limit Initial lifetime deposit limit *RESTRICTION FEATURE*. Setting this to type(uint256).max will disable the per address deposit limit counter
    /// @param withdraw_threshold Amount at which the withdraw delay goes into effect *RESTRICTION FEATURE*
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Listed if successful
    function list_asset(
        address asset_source,
        bytes32 vega_asset_id,
        uint256 lifetime_limit,
        uint256 withdraw_threshold,
        uint256 nonce,
        bytes memory signatures
    ) external override {
        require(asset_source != address(0), "invalid asset source");
        require(!listed_tokens[asset_source], "asset already listed");
        bytes memory message = abi.encode(
            asset_source,
            vega_asset_id,
            lifetime_limit,
            withdraw_threshold,
            nonce,
            "list_asset"
        );
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        listed_tokens[asset_source] = true;
        vega_asset_ids_to_source[vega_asset_id] = asset_source;
        asset_source_to_vega_asset_id[asset_source] = vega_asset_id;
        asset_deposit_lifetime_limit[asset_source] = lifetime_limit;
        withdraw_thresholds[asset_source] = withdraw_threshold;
        emit Asset_Listed(asset_source, vega_asset_id, nonce);
    }

    /// @notice This function removes from listing the given ERC20 token contract. This marks the token as invalid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Removed if successful
    function remove_asset(
        address asset_source,
        uint256 nonce,
        bytes memory signatures
    ) external override {
        require(listed_tokens[asset_source], "asset not listed");
        bytes memory message = abi.encode(asset_source, nonce, "remove_asset");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        listed_tokens[asset_source] = false;
        emit Asset_Removed(asset_source, nonce);
    }

    /************************RESTRICTIONS***************************/
    // user => asset_source => deposit total
    mapping(address => mapping(address => uint256)) user_lifetime_deposits;
    // asset_source => deposit_limit
    mapping(address => uint256) asset_deposit_lifetime_limit;
    uint256 public default_withdraw_delay = 432000;
    // asset_source => threshold
    mapping(address => uint256) withdraw_thresholds;
    bool public is_stopped;

    // depositor => is exempt from deposit limits
    mapping(address => bool) exempt_depositors;

    /// @notice This function sets the lifetime maximum deposit for a given asset
    /// @param asset_source Contract address for given ERC20 token
    /// @param lifetime_limit Deposit limit for a given ethereum address. Setting this to type(uint256).max will disable the per address deposit limit counter
    /// @param threshold Withdraw size above which the withdraw delay goes into effect
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev asset must first be listed
    function set_asset_limits(
        address asset_source,
        uint256 lifetime_limit,
        uint256 threshold,
        uint256 nonce,
        bytes calldata signatures
    ) external override {
        require(listed_tokens[asset_source], "asset not listed");
        bytes memory message = abi.encode(asset_source, lifetime_limit, threshold, nonce, "set_asset_limits");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        asset_deposit_lifetime_limit[asset_source] = lifetime_limit;
        withdraw_thresholds[asset_source] = threshold;

        emit Asset_Limits_Updated(asset_source, lifetime_limit, threshold);
    }

    /// @notice This view returns the lifetime deposit limit for the given asset
    /// @param asset_source Contract address for given ERC20 token
    /// @return Lifetime limit for the given asset
    function get_asset_deposit_lifetime_limit(address asset_source) external view override returns (uint256) {
        return asset_deposit_lifetime_limit[asset_source];
    }

    /// @notice This view returns the given token's withdraw threshold above which the withdraw delay goes into effect
    /// @param asset_source Contract address for given ERC20 token
    /// @return Withdraw threshold
    function get_withdraw_threshold(address asset_source) external view override returns (uint256) {
        return withdraw_thresholds[asset_source];
    }

    /// @notice This function sets the withdraw delay for withdrawals over the per-asset set thresholds
    /// @param delay Amount of time to delay a withdrawal
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    function set_withdraw_delay(
        uint256 delay,
        uint256 nonce,
        bytes calldata signatures
    ) external override {
        bytes memory message = abi.encode(delay, nonce, "set_withdraw_delay");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        default_withdraw_delay = delay;
        emit Bridge_Withdraw_Delay_Set(delay);
    }

    /// @notice This function triggers the global bridge stop that halts all withdrawals and deposits until it is resumed
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev bridge must not be stopped already
    /// @dev emits Bridge_Stopped if successful
    function global_stop(uint256 nonce, bytes calldata signatures) external override {
        require(!is_stopped, "bridge already stopped");
        bytes memory message = abi.encode(nonce, "global_stop");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        is_stopped = true;
        emit Bridge_Stopped();
    }

    /// @notice This function resumes bridge operations from the stopped state
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev bridge must be stopped
    /// @dev emits Bridge_Resumed if successful
    function global_resume(uint256 nonce, bytes calldata signatures) external override {
        require(is_stopped, "bridge not stopped");
        bytes memory message = abi.encode(nonce, "global_resume");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        is_stopped = false;
        emit Bridge_Resumed();
    }

    /// @notice this function allows the sender to exempt themselves from the deposit limits
    /// @notice this feature is specifically for liquidity and rewards providers
    /// @dev emits Depositor_Exempted if successful
    function exempt_depositor() external override {
        require(!exempt_depositors[msg.sender], "sender already exempt");
        exempt_depositors[msg.sender] = true;
        emit Depositor_Exempted(msg.sender);
    }

    /// @notice this function allows the exemption_lister to revoke a depositor's exemption from deposit limits
    /// @notice this feature is specifically for liquidity and rewards providers
    /// @dev emits Depositor_Exemption_Revoked if successful
    function revoke_exempt_depositor() external override {
        require(exempt_depositors[msg.sender], "sender not exempt");
        exempt_depositors[msg.sender] = false;
        emit Depositor_Exemption_Revoked(msg.sender);
    }

    /// @notice this view returns true if the given despoitor address has been exempted from deposit limits
    /// @param depositor The depositor to check
    /// @return true if depositor is exempt
    function is_exempt_depositor(address depositor) external view override returns (bool) {
        return exempt_depositors[depositor];
    }

    /***********************END RESTRICTIONS*************************/

    /// @notice This function withdraws assets to the target Ethereum address
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of ERC20 tokens to withdraw
    /// @param target Target Ethereum address to receive withdrawn ERC20 tokens
    /// @param creation Timestamp of when requestion was created *RESTRICTION FEATURE*
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits Asset_Withdrawn if successful
    function withdraw_asset(
        address asset_source,
        uint256 amount,
        address target,
        uint256 creation,
        uint256 nonce,
        bytes memory signatures
    ) external override {
        require(!is_stopped, "bridge stopped");
        require(
            withdraw_thresholds[asset_source] > amount || creation + default_withdraw_delay <= block.timestamp,
            "large withdraw is not old enough"
        );
        bytes memory message = abi.encode(asset_source, amount, target, creation, nonce, "withdraw_asset");
        require(
            IMultisigControl(multisig_control_address()).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        ERC20_Asset_Pool(erc20_asset_pool_address).withdraw(asset_source, target, amount);
        emit Asset_Withdrawn(target, asset_source, amount, nonce);
    }

    /// @notice This function allows a user to deposit given ERC20 tokens into Vega
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of tokens to be deposited into Vega
    /// @param vega_public_key Target Vega public key to be credited with this deposit
    /// @dev emits Asset_Deposited if successful
    /// @dev ERC20 approve function should be run before running this
    /// @notice ERC20 approve function should be run before running this
    function deposit_asset(
        address asset_source,
        uint256 amount,
        bytes32 vega_public_key
    ) external override {
        require(!is_stopped, "bridge stopped");

        // Cache SLOAD
        uint256 _limit = asset_deposit_lifetime_limit[asset_source];

        // Check limit first as that's the most likely branch, then check if exempt
        if (_limit < type(uint256).max && !exempt_depositors[msg.sender]) {
            require(user_lifetime_deposits[msg.sender][asset_source] + amount <= _limit, "deposit over lifetime limit");
            user_lifetime_deposits[msg.sender][asset_source] += amount;
        }

        require(listed_tokens[asset_source], "asset not listed");

        (bool success, bytes memory returndata) = asset_source.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                erc20_asset_pool_address,
                amount
            )
        );
        require(success, "token transfer failed");

        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "token transfer failed");
        }

        emit Asset_Deposited(msg.sender, asset_source, amount, vega_public_key);
    }

    /***************************VIEWS*****************************/
    /// @notice This view returns true if the given ERC20 token contract has been listed valid for deposit
    /// @param asset_source Contract address for given ERC20 token
    /// @return True if asset is listed
    function is_asset_listed(address asset_source) external view override returns (bool) {
        return listed_tokens[asset_source];
    }

    /// @return current multisig_control_address
    function get_multisig_control_address() external view override returns (address) {
        return multisig_control_address();
    }

    /// @param asset_source Contract address for given ERC20 token
    /// @return The assigned Vega Asset Id for given ERC20 token
    function get_vega_asset_id(address asset_source) external view override returns (bytes32) {
        return asset_source_to_vega_asset_id[asset_source];
    }

    /// @param vega_asset_id Vega-assigned asset ID for which you want the ERC20 token address
    /// @return The ERC20 token contract address for a given Vega Asset Id
    function get_asset_source(bytes32 vega_asset_id) external view override returns (address) {
        return vega_asset_ids_to_source[vega_asset_id];
    }

    function is_contract(address addr) internal view returns (bool) {
        uint256 code_size;
        assembly {
            code_size := extcodesize(addr)
        }
        return code_size > 0;
    }
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Bridge Logic Interface
/// @author Vega Protocol
/// @notice Implementations of this interface are used by Vega network users to deposit and withdraw ERC20 tokens to/from Vega.
// @notice All funds deposited/withdrawn are to/from the ERC20_Asset_Pool
abstract contract IERC20_Bridge_Logic_Restricted {
    /***************************EVENTS****************************/
    event Asset_Withdrawn(address indexed user_address, address indexed asset_source, uint256 amount, uint256 nonce);
    event Asset_Deposited(
        address indexed user_address,
        address indexed asset_source,
        uint256 amount,
        bytes32 vega_public_key
    );
    event Asset_Listed(address indexed asset_source, bytes32 indexed vega_asset_id, uint256 nonce);
    event Asset_Removed(address indexed asset_source, uint256 nonce);
    event Asset_Limits_Updated(address indexed asset_source, uint256 lifetime_limit, uint256 withdraw_threshold);
    event Bridge_Withdraw_Delay_Set(uint256 withdraw_delay);
    event Bridge_Stopped();
    event Bridge_Resumed();
    event Depositor_Exempted(address indexed depositor);
    event Depositor_Exemption_Revoked(address indexed depositor);

    /***************************FUNCTIONS*************************/
    /// @notice This function lists the given ERC20 token contract as valid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param vega_asset_id Vega-generated asset ID for internal use in Vega Core
    /// @param lifetime_limit Initial lifetime deposit limit *RESTRICTION FEATURE*
    /// @param withdraw_threshold Amount at which the withdraw delay goes into effect *RESTRICTION FEATURE*
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev MUST emit Asset_Listed if successful
    function list_asset(
        address asset_source,
        bytes32 vega_asset_id,
        uint256 lifetime_limit,
        uint256 withdraw_threshold,
        uint256 nonce,
        bytes memory signatures
    ) external virtual;

    /// @notice This function removes from listing the given ERC20 token contract. This marks the token as invalid for deposit to this bridge
    /// @param asset_source Contract address for given ERC20 token
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev MUST emit Asset_Removed if successful
    function remove_asset(
        address asset_source,
        uint256 nonce,
        bytes memory signatures
    ) external virtual;

    /// @notice This function sets the lifetime maximum deposit for a given asset
    /// @param asset_source Contract address for given ERC20 token
    /// @param lifetime_limit Deposit limit for a given ethereum address
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev asset must first be listed
    function set_asset_limits(
        address asset_source,
        uint256 lifetime_limit,
        uint256 threshold,
        uint256 nonce,
        bytes calldata signatures
    ) external virtual;

    /// @notice This function sets the withdraw delay for withdrawals over the per-asset set thresholds
    /// @param delay Amount of time to delay a withdrawal
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    function set_withdraw_delay(
        uint256 delay,
        uint256 nonce,
        bytes calldata signatures
    ) external virtual;

    /// @notice This function triggers the global bridge stop that halts all withdrawals and deposits until it is resumed
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev bridge must not be stopped already
    /// @dev MUST emit Bridge_Stopped if successful
    function global_stop(uint256 nonce, bytes calldata signatures) external virtual;

    /// @notice This function resumes bridge operations from the stopped state
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @dev bridge must be stopped
    /// @dev MUST emit Bridge_Resumed if successful
    function global_resume(uint256 nonce, bytes calldata signatures) external virtual;

    /// @notice this function allows the exemption_lister to exempt a depositor from the deposit limits
    /// @notice this feature is specifically for liquidity and rewards providers
    /// @dev MUST emit Depositor_Exempted if successful
    function exempt_depositor() external virtual;

    /// @notice this function allows the exemption_lister to revoke a depositor's exemption from deposit limits
    /// @notice this feature is specifically for liquidity and rewards providers
    /// @dev MUST emit Depositor_Exemption_Revoked if successful
    function revoke_exempt_depositor() external virtual;

    /// @notice This function withdrawals assets to the target Ethereum address
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of ERC20 tokens to withdraw
    /// @param target Target Ethereum address to receive withdrawn ERC20 tokens
    /// @param creation Timestamp of when requestion was created *RESTRICTION FEATURE*
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev MUST emit Asset_Withdrawn if successful
    function withdraw_asset(
        address asset_source,
        uint256 amount,
        address target,
        uint256 creation,
        uint256 nonce,
        bytes memory signatures
    ) external virtual;

    /// @notice this view returns true if the given despoitor address has been exempted from deposit limits
    /// @param depositor The depositor to check
    /// @return true if depositor is exempt
    function is_exempt_depositor(address depositor) external view virtual returns (bool);

    /// @notice This function allows a user to deposit given ERC20 tokens into Vega
    /// @param asset_source Contract address for given ERC20 token
    /// @param amount Amount of tokens to be deposited into Vega
    /// @param vega_public_key Target Vega public key to be credited with this deposit
    /// @dev MUST emit Asset_Deposited if successful
    /// @dev ERC20 approve function should be run before running this
    /// @notice ERC20 approve function should be run before running this
    function deposit_asset(
        address asset_source,
        uint256 amount,
        bytes32 vega_public_key
    ) external virtual;

    /***************************VIEWS*****************************/
    /// @notice This view returns true if the given ERC20 token contract has been listed valid for deposit
    /// @param asset_source Contract address for given ERC20 token
    /// @return True if asset is listed
    function is_asset_listed(address asset_source) external view virtual returns (bool);

    /// @notice This view returns the lifetime deposit limit for the given asset
    /// @param asset_source Contract address for given ERC20 token
    /// @return Lifetime limit for the given asset
    function get_asset_deposit_lifetime_limit(address asset_source) external view virtual returns (uint256);

    /// @notice This view returns the given token's withdraw threshold above which the withdraw delay goes into effect
    /// @param asset_source Contract address for given ERC20 token
    /// @return Withdraw threshold
    function get_withdraw_threshold(address asset_source) external view virtual returns (uint256);

    /// @return current multisig_control_address
    function get_multisig_control_address() external view virtual returns (address);

    /// @param asset_source Contract address for given ERC20 token
    /// @return The assigned Vega Asset ID for given ERC20 token
    function get_vega_asset_id(address asset_source) external view virtual returns (bytes32);

    /// @param vega_asset_id Vega-assigned asset ID for which you want the ERC20 token address
    /// @return The ERC20 token contract address for a given Vega Asset ID
    function get_asset_source(bytes32 vega_asset_id) external view virtual returns (address);
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title MultisigControl Interface
/// @author Vega Protocol
/// @notice Implementations of this interface are used by the Vega network to control smart contracts without the need for Vega to have any Ethereum of its own.
/// @notice To do this, the Vega validators sign a MultisigControl order to construct a signature bundle. Any interested party can then take that signature bundle and pay the gas to run the command on Ethereum
abstract contract IMultisigControl {
    /***************************EVENTS****************************/
    event SignerAdded(address new_signer, uint256 nonce);
    event SignerRemoved(address old_signer, uint256 nonce);
    event ThresholdSet(uint16 new_threshold, uint256 nonce);
    event NonceBurnt(uint256 nonce);

    /**************************FUNCTIONS*********************/
    /// @notice Sets threshold of signatures that must be met before function is executed.
    /// @param new_threshold New threshold value
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @notice Ethereum has no decimals, threshold is % * 10 so 50% == 500 100% == 1000
    /// @notice signatures are OK if they are >= threshold count of total valid signers
    /// @dev MUST emit ThresholdSet event
    function set_threshold(
        uint16 new_threshold,
        uint256 nonce,
        bytes calldata signatures
    ) external virtual;

    /// @notice Adds new valid signer and adjusts signer count.
    /// @param new_signer New signer address
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev MUST emit 'SignerAdded' event
    function add_signer(
        address new_signer,
        uint256 nonce,
        bytes calldata signatures
    ) external virtual;

    /// @notice Removes currently valid signer and adjusts signer count.
    /// @param old_signer Address of signer to be removed.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev MUST emit 'SignerRemoved' event
    function remove_signer(
        address old_signer,
        uint256 nonce,
        bytes calldata signatures
    ) external virtual;

    /// @notice Burn an nonce before it gets used by a user. Useful in case the validators needs to prevents a malicious user to do un-permitted action.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits 'NonceBurnt' event
    function burn_nonce(uint256 nonce, bytes calldata signatures) external virtual;

    /// @notice Verifies a signature bundle and returns true only if the threshold of valid signers is met,
    /// @notice this is a function that any function controlled by Vega MUST call to be securely controlled by the Vega network
    /// @notice message to hash to sign follows this pattern:
    /// @notice abi.encode( abi.encode(param1, param2, param3, ... , nonce, function_name_string), validating_contract_or_submitter_address);
    /// @notice Note that validating_contract_or_submitter_address is the the submitting party. If on MultisigControl contract itself, it's the submitting ETH address
    /// @notice if function on bridge that then calls Multisig, then it's the address of that contract
    /// @notice Note also the embedded encoding, this is required to verify what function/contract the function call goes to
    /// @return MUST return true if valid signatures are over the threshold
    function verify_signatures(
        bytes calldata signatures,
        bytes memory message,
        uint256 nonce
    ) public virtual returns (bool);

    /**********************VIEWS*********************/
    /// @return Number of valid signers
    function get_valid_signer_count() external view virtual returns (uint8);

    /// @return Current threshold
    function get_current_threshold() external view virtual returns (uint16);

    /// @param signer_address target potential signer address
    /// @return true if address provided is valid signer
    function is_valid_signer(address signer_address) external view virtual returns (bool);

    /// @param nonce Nonce to lookup
    /// @return true if nonce has been used
    function is_nonce_used(uint256 nonce) external view virtual returns (bool);
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IMultisigControl.sol";
import "./IERC20.sol";

/// @title ERC20 Asset Pool
/// @author Vega Protocol
/// @notice This contract is the target for all deposits to the ERC20 Bridge via ERC20_Bridge_Logic
contract ERC20_Asset_Pool {
    event Multisig_Control_Set(address indexed new_address);
    event Bridge_Address_Set(address indexed new_address);

    /// @return Current MultisigControl contract address
    address public multisig_control_address;

    /// @return Current ERC20_Bridge_Logic contract address
    address public erc20_bridge_address;

    /// @param multisig_control The initial MultisigControl contract address
    /// @notice Emits Multisig_Control_Set event
    constructor(address multisig_control) {
        require(multisig_control != address(0), "invalid MultisigControl address");
        multisig_control_address = multisig_control;
        emit Multisig_Control_Set(multisig_control);
    }

    /// @notice this contract is not intended to accept ether directly
    receive() external payable {
        revert("this contract does not accept ETH");
    }

    /// @param new_address The new MultisigControl contract address.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed set_multisig_control order
    /// @notice See MultisigControl for more about signatures
    /// @notice Emits Multisig_Control_Set event
    function set_multisig_control(
        address new_address,
        uint256 nonce,
        bytes memory signatures
    ) external {
        require(new_address != address(0), "invalid MultisigControl address");
        require(is_contract(new_address), "new address must be contract");

        bytes memory message = abi.encode(new_address, nonce, "set_multisig_control");
        require(
            IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        multisig_control_address = new_address;
        emit Multisig_Control_Set(new_address);
    }

    /// @param new_address The new ERC20_Bridge_Logic contract address.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed set_bridge_address order
    /// @notice See MultisigControl for more about signatures
    /// @notice Emits Bridge_Address_Set event
    function set_bridge_address(
        address new_address,
        uint256 nonce,
        bytes memory signatures
    ) external {
        bytes memory message = abi.encode(new_address, nonce, "set_bridge_address");
        require(
            IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        erc20_bridge_address = new_address;
        emit Bridge_Address_Set(new_address);
    }

    /// @notice This function can only be run by the current "multisig_control_address" and, if available, will send the target tokens to the target
    /// @param token_address Contract address of the ERC20 token to be withdrawn
    /// @param target Target Ethereum address that the ERC20 tokens will be sent to
    /// @param amount Amount of ERC20 tokens to withdraw
    /// @dev amount is in whatever the lowest decimal value the ERC20 token has. For instance, an 18 decimal ERC20 token, 1 "amount" == 0.000000000000000001
    function withdraw(
        address token_address,
        address target,
        uint256 amount
    ) external {
        require(msg.sender == erc20_bridge_address, "msg.sender not authorized bridge");

        (bool success, bytes memory returndata) = token_address.call(
            abi.encodeWithSignature("transfer(address,uint256)", target, amount)
        );
        require(success, "token transfer failed");

        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "token transfer failed");
        }
    }

    function is_contract(address addr) internal view returns (bool) {
        uint256 code_size;
        assembly {
            code_size := extcodesize(addr)
        }
        return code_size > 0;
    }
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}