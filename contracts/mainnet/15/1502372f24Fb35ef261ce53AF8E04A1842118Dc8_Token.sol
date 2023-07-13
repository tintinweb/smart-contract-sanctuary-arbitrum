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

import "../interfaces/IEmergencyMode.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC2612.sol";
import "../interfaces/IFluidClient.sol";
import "../interfaces/ILiquidityProvider.sol";
import "../interfaces/IOperatorOwned.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ITransferWithBeneficiary.sol";

import "./openzeppelin/SafeERC20.sol";

uint constant DEFAULT_MAX_UNCHECKED_REWARD = 1000;

/// @dev FEE_DENOM for the fees (ie, 10 is a 1% fee)
uint constant FEE_DENOM = 1000;

/// @title The fluid token ERC20 contract
// solhint-disable-next-line max-states-count
contract Token is
    IFluidClient,
    IERC2612,
    ITransferWithBeneficiary,
    IToken,
    IEmergencyMode,
    IOperatorOwned
{
    using SafeERC20 for IERC20;

    /* ~~~~~~~~~~ ERC20 FEATURES ~~~~~~~~~~ */

    mapping(address => uint256) private balances_;

    mapping(address => mapping(address => uint256)) private allowances_;

    uint8 private decimals_;

    uint256 private totalSupply_;

    string private name_;

    string private symbol_;

    /* ~~~~~~~~~~ HOUSEKEEPING ~~~~~~~~~~ */

    /// @dev if false, emergency mode is active - can be called by either the
    /// @dev operator, worker account or emergency council
    bool private noEmergencyMode_;

    // for migrations
    uint private version_;

    /* ~~~~~~~~~~ LIQUIDITY PROVIDER ~~~~~~~~~~ */

    // @custom:security non-reentrant
    ILiquidityProvider private pool_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    /// @dev deprecated, worker config is now handled externally
    // solhint-disable-next-line var-name-mixedcase
    address private __deprecated_1;

    /* ~~~~~~~~~~ OWNERSHIP ~~~~~~~~~~ */

    /// @dev emergency council that can activate emergency mode
    address private emergencyCouncil_;

    /// @dev account to use that created the contract (multisig account)
    address private operator_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    /// @dev deprecated, we don't track the last rewarded block for manual
    ///      rewards anymore
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_2;

    /// @dev [address] => [[block number] => [has the block been manually
    ///      rewarded by this user?]]
    /// @dev deprecated, we don't do manual rewards anymore
    // solhint-disable-nex-line var-name-mixedcase
    mapping (address => mapping(uint => uint)) private __deprecated_3;

    /// @dev amount a user has manually rewarded, to be removed from their
    ///      batched rewards
    /// @dev [address] => [amount manually rewarded]
    /// @dev deprecated, we don't do manual rewards anymore
    // solhint-disable-nex-line var-name-mixedcase
    mapping (address => uint) private __deprecated_4;

    /* ~~~~~~~~~~ SECURITY FEATURES ~~~~~~~~~~ */

    /// @dev the largest amount a reward can be to not get quarantined
    uint private maxUncheckedReward_;

    /// @dev [address] => [number of tokens the user won that have been quarantined]
    mapping (address => uint) private blockedRewards_;

    /* ~~~~~~~~~~ DEPRECATED SLOTS ~~~~~~~~~~ */

    // slither-disable-start unused-state constable-states naming-convention

    /*
     * These slots were used for the feature "mint limits" which we've
     * since entirely pulled.
     */

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    bool private __deprecated_5;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    mapping (address => uint) private __deprecated_6;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    mapping (address => uint) private __deprecated_7;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_8;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_9;

    /// @notice deprecated, mint limits no longer exist
    // solhint-disable-next-line var-name-mixedcase
    uint private __deprecated_10;

    // slither-disable-end

    /* ~~~~~~~~~~ ORACLE PAYOUTS ~~~~~~~~~~ */

    /// @dev account that can call the reward function, should be the
    ///      operator contract/
    address private oracle_;

    /* ~~~~~~~~~~ ERC2612 ~~~~~~~~~~ */

    // @dev nonces_ would be used for permit only, but it could be used for
    //      every off-chain sign if needed
    mapping (address => uint256) private nonces_;

    uint256 private initialChainId_;

    bytes32 private initialDomainSeparator_;

    /* ~~~~~~~~~~ FEE TAKING ~~~~~~~~~~ */

    /// @notice burnFee_ that's paid by the user when they burn
    uint256 private burnFee_;

    /// @notice feeRecipient_ that receives the fee paid by a user
    address private feeRecipient_;

    /// @notice burnFee_ that's paid by the user when they mint
    uint256 private mintFee_;

    /* ~~~~~~~~~~ SETUP FUNCTIONS ~~~~~~~~~~ */

    /**
     * @notice computeDomainSeparator that's used for EIP712
     */
    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function _setupEIP2612() internal {
        initialChainId_ = block.chainid;
        initialDomainSeparator_ = computeDomainSeparator();
    }

    /**
     * @notice initialiser function - sets the contract's data
     * @dev we pass in the metadata explicitly instead of sourcing from the
     * @dev underlying token because some underlying tokens don't implement
     * @dev these methods
     *
     * @param _liquidityProvider the `LiquidityProvider` contract
     *        address. Should have this contract as its owner.
     *
     * @param _decimals the fluid token's decimals (should be the same as the underlying token's)
     * @param _name the fluid token's name
     * @param _symbol the fluid token's symbol
     * @param _emergencyCouncil address that can activate emergency mode
     * @param _operator address that can release quarantine payouts and activate emergency mode
     * @param _oracle address that can call the reward function
     */
     function init(
        address _liquidityProvider,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        address _emergencyCouncil,
        address _operator,
        address _oracle
    ) public {
        require(version_ == 0, "contract is already initialised");
        require(_operator != address(0), "operator zero");
        require(_oracle != address(0), "oracle zero");

        version_ = 1;

        // remember the operator for signing off on oracle changes, large payouts
        operator_ = _operator;

        oracle_ = _oracle;

        // remember the emergency council for shutting down this token
        emergencyCouncil_ = _emergencyCouncil;

        // remember the liquidity provider to deposit tokens into
        pool_ = ILiquidityProvider(_liquidityProvider);

        // sanity check
        // slither-disable-next-line unused-return
        underlyingToken().totalSupply();

        noEmergencyMode_ = true;

        // erc20 props
        decimals_ = _decimals;
        name_ = _name;
        symbol_ = _symbol;

        // initialise mint limits
        maxUncheckedReward_ = DEFAULT_MAX_UNCHECKED_REWARD;

        _setupEIP2612();
    }

    /**
     * @notice setupEIP2612, made public to support upgrades without a new migration
     */
    function setupEIP2612() public {
        require(msg.sender == operator_, "only operator/Token");

        _setupEIP2612();
    }

    /* ~~~~~~~~~~ INTERNAL FUNCTIONS ~~~~~~~~~~ */

    /// @dev _erc20In has the possibility depending on the underlying LP
    ///      behaviour to not mint the exact amount of tokens, so it returns it
    ///      here (currently won't happen on compound/aave)
    function _erc20In(
        address _spender,
        address _beneficiary,
        uint256 _amount
    ) internal returns (uint256) {
        require(noEmergencyMode_, "emergency mode!");

        // take underlying tokens from the user

        IERC20 underlying = underlyingToken();

        uint originalBalance = underlying.balanceOf(address(this));

        underlying.safeTransferFrom(_spender, address(this), _amount);

        uint finalBalance = underlying.balanceOf(address(this));

        // ensure the token is behaving

        require(finalBalance > originalBalance, "bad token bal");

        uint realAmount = finalBalance - originalBalance;

        // add the tokens to our compound pool

        underlying.safeTransfer(address(pool_), realAmount);

        pool_.addToPool(realAmount);

        // give the user fluid tokens

        // calculate the fee to take
        uint256 feeAmount =
            (mintFee_ != 0 && realAmount > mintFee_)
                ? (realAmount * mintFee_) / FEE_DENOM
                : 0;

        // calculate the amount to give the user
        uint256 mintAmount = realAmount - feeAmount;

        _mint(_beneficiary, mintAmount);

        emit MintFluid(_beneficiary, mintAmount);

        // mint the fee to the fee recipient
        if (feeAmount > 0) _mint(feeRecipient_, feeAmount);

        return realAmount;
    }

    function _erc20Out(
        address _sender,
        address _beneficiary,
        uint256 _amount
    ) internal returns (uint256) {
        // take the user's fluid tokens

         // if the fee amount > 0 and the burn fee is greater than 0, then
         // we take burn fee% of the amount given by the user

        uint256 feeAmount =
            (burnFee_ != 0 && _amount > burnFee_)
                ? (_amount * burnFee_) / FEE_DENOM
                : 0;

        // burn burnAmount

        uint256 burnAmount = _amount - feeAmount;

        // give them erc20, if the user's amount is greater than 100, then we keep 1%

        _burn(_sender, _amount);

        pool_.takeFromPool(burnAmount);

        emit BurnFluid(_sender, _amount);

        // send out the amounts

        underlyingToken().safeTransfer(_beneficiary, burnAmount);

        if (feeAmount > 0) _mint(feeRecipient_, feeAmount);

        return burnAmount;
    }

    /**
     * @dev rewards two users from the reward pool
     * @dev mints tokens and emits the reward event
     *
     * @param firstBlock the first block in the range being rewarded for
     * @param lastBlock the last block in the range being rewarded for
     * @param winner the address being rewarded
     * @param amount the amount being rewarded
     */
    function _rewardFromPool(
        uint256 firstBlock,
        uint256 lastBlock,
        address winner,
        uint256 amount
    ) internal {
        require(noEmergencyMode_, "emergency mode!");

        if (amount > maxUncheckedReward_) {
            // quarantine the reward
            emit BlockedReward(winner, amount, firstBlock, lastBlock);

            blockedRewards_[winner] += amount;

            return;
        }

        _mint(winner, amount);

        emit Reward(winner, amount, firstBlock, lastBlock);
    }


    function _reward(address winner, uint256 amount) internal {
        require(noEmergencyMode_, "emergency mode!");

        // mint some fluid tokens from the interest we've accrued

        _mint(winner, amount);
    }

    /// @dev _transfer is implemented by OpenZeppelin
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC20: transfer from the zero address");

        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balances_[from];

        // solhint-disable-next-line reason-string
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            balances_[from] = fromBalance - amount;
        }

        balances_[to] += amount;

        emit Transfer(from, to, amount);
    }

    /// @dev _mint is implemented by OpenZeppelin
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        totalSupply_ += _amount;
        balances_[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    /// @dev _burn is implemented by OpenZeppelin
    function _burn(address _account, uint256 _amount) internal virtual {
        // solhint-disable-next-line reason-string
        require(_account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances_[_account];

        // solhint-disable-next-line reason-string
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");


        unchecked {
            balances_[_account] = accountBalance - _amount;

        }

        totalSupply_ -= _amount;

        emit Transfer(_account, address(0), _amount);
    }

    /// @dev _approve is implemented by OpenZeppelin
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "approve from zero");

        emit Approval(_owner, _spender, _amount);

        // solhint-disable-next-line reason-string
        require(_spender != address(0), "approve to zero");

        allowances_[_owner][_spender] = _amount;
    }

    /// @dev _spendAllowance is implemented by OpenZeppelin
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /* ~~~~~~~~~~ EXTRA FUNCTIONS ~~~~~~~~~~ */

    function updateOracle(address _newOracle) public {
        require(msg.sender == operator_, "only operator");

        oracle_ = _newOracle;
    }

    /**
     * @notice update the operator account to a new address
     * @param _newOperator the address of the new operator to change to
     */
    function updateOperator(address _newOperator) public {
        require(msg.sender == operator_, "operator only");
        require(_newOperator != address(0), "new operator zero");

        emit NewOperator(operator_, _newOperator);

        operator_ = _newOperator;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IOperatorOwned ~~~~~~~~~~ */

    /// @inheritdoc IOperatorOwned
    function operator() public view returns (address) { return operator_; }

    /* ~~~~~~~~~~ IMPLEMENTS IEmergencyMode ~~~~~~~~~~ */

    /// @inheritdoc IEmergencyMode
    function enableEmergencyMode() public {
        require(
            msg.sender == operator_ ||
            msg.sender == emergencyCouncil_ ||
            msg.sender == oracle_,
            "can't enable emergency mode!"
        );

        noEmergencyMode_ = false;

        emit Emergency(true);
    }

    /// @inheritdoc IEmergencyMode
    function disableEmergencyMode() public {
        require(msg.sender == operator_, "operator only");

        noEmergencyMode_ = true;

        emit Emergency(false);
    }

    function noEmergencyMode() public view returns (bool) {
        return noEmergencyMode_;
    }

    function emergencyCouncil() public view returns (address) {
        return emergencyCouncil_;
    }

    /**
     * @notice updates the emergency council address
     * @notice (operator only)
     * @param newCouncil the new council address
     */
    function updateEmergencyCouncil(address newCouncil) external {
        require(msg.sender == operator_, "operator only");

        emit NewCouncil(emergencyCouncil_, newCouncil);

        emergencyCouncil_ = newCouncil;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IToken ~~~~~~~~~~ */

    /// @inheritdoc IToken
    function oracle() public view returns (address) {
        return oracle_;
    }

    /// @inheritdoc IToken
    function underlyingToken() public view returns (IERC20) {
        return pool_.underlying_();
    }

    /// @inheritdoc IToken
    function underlyingLp() public view returns (ILiquidityProvider) {
        return pool_;
    }

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint _maxUncheckedReward) public {
        require(msg.sender == operator_, "operator only");

        maxUncheckedReward_ = _maxUncheckedReward;

        emit RewardQuarantineThresholdUpdated(_maxUncheckedReward);
    }

    /// @inheritdoc IToken
    function erc20In(uint _amount) public returns (uint) {
        return _erc20In(msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc IToken
    // slither-disable-next-line reentrancy-no-eth
    function erc20InTo(
        address _recipient,
        uint256 _amount
    ) public returns (uint256 amountOut) {
        return _erc20In(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IToken
    function erc20Out(uint256 _amount) public returns (uint256) {
        return _erc20Out(msg.sender, msg.sender,_amount);
    }

    /// @inheritdoc IToken
    function erc20OutTo(address _recipient, uint256 _amount) public returns (uint256) {
        return _erc20Out(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IToken
    function burnFluidWithoutWithdrawal(uint256 _amount) public {
        // burns fluid without taking from the liquidity provider
        // this is fine, because the amount in the liquidity provider
        // and the amount of fluid tokens are explicitly allowed to be different
        // using this will essentially add the tokens to the reward pool
        _burn(msg.sender, _amount);
    }

    /// @inheritdoc IToken
    function rewardPoolAmount() public returns (uint) {
        // XXX calling totalPoolAmount before totalSupply is load bearing to the StupidLiquidityProvider
        uint totalAmount = pool_.totalPoolAmount();
        uint totalFluid = totalSupply();
        require(totalAmount >= totalFluid, "bad underlying liq");
        return totalAmount - totalFluid;
    }

    /// @inheritdoc IToken
    function unblockReward(
        bytes32 rewardTx,
        address user,
        uint amount,
        bool payout,
        uint firstBlock,
        uint lastBlock
    ) public {
        require(noEmergencyMode_, "emergency mode!");
        require(msg.sender == operator_, "operator only");

        require(blockedRewards_[user] >= amount, "too much unblock");

        blockedRewards_[user] -= amount;

        if (payout) {
            _reward(user, amount);
            emit UnblockReward(rewardTx, user, amount, firstBlock, lastBlock);
        }
    }

    /// @inheritdoc IToken
    function maxUncheckedReward() public view returns (uint) {
        return maxUncheckedReward_;
    }

    /// @inheritdoc IToken
    function upgradeLiquidityProvider(
        ILiquidityProvider _newPool,
        uint256 _minTokenAfterShift
     ) public returns (uint256) {
      require(noEmergencyMode_, "emergency mode");
      require(msg.sender == operator_, "operator only");

      uint oldPoolAmount = pool_.totalPoolAmount();

      pool_.takeFromPool(oldPoolAmount);

      pool_ = _newPool;

      underlyingToken().safeTransfer(address(pool_), oldPoolAmount);

      pool_.addToPool(oldPoolAmount);

      uint newPoolAmount = pool_.totalPoolAmount();

      require(newPoolAmount > _minTokenAfterShift + 1, "total amount bad");

      return newPoolAmount;
    }

    /// @inheritdoc IToken
    function drainRewardPool(address _recipient, uint256 _amount) public {
        require(noEmergencyMode_, "emergency mode");
        require(msg.sender == operator_, "operator only");

        uint256 rewardPool = rewardPoolAmount();

        require(rewardPool >= _amount, "drain too high");

        _reward(_recipient, _amount);
    }

    /* ~~~~~~~~~~ IMPLEMENTS IFluidClient ~~~~~~~~~~ */

    /// @inheritdoc IFluidClient
    function batchReward(
        Winner[] memory rewards,
        uint firstBlock,
        uint lastBlock
    ) public {
        require(noEmergencyMode_, "emergency mode!");
        require(msg.sender == oracle_, "only oracle");

        uint poolAmount = rewardPoolAmount();

        for (uint i = 0; i < rewards.length; i++) {
            Winner memory winner = rewards[i];

            require(poolAmount >= winner.amount, "empty reward pool");

            poolAmount = poolAmount - winner.amount;

            _rewardFromPool(
                firstBlock,
                lastBlock,
                winner.winner,
                winner.amount
            );
        }
    }

    /// @inheritdoc IFluidClient
    function getUtilityVars() external returns (UtilityVars memory) {
        return UtilityVars({
            poolSizeNative: rewardPoolAmount(),
            tokenDecimalScale: 10**decimals(),
            exchangeRateNum: 1,
            exchangeRateDenom: 1,
            deltaWeightNum: 31536000,
            deltaWeightDenom: 1,
            customCalculationType: DEFAULT_CALCULATION_TYPE
        });
    }

    /* ~~~~~~~~~~ IMPLEMENTS ITransferWithBeneficiary ~~~~~~~~~~ */

    /// @inheritdoc ITransferWithBeneficiary
    function transferWithBeneficiary(
        address _token,
        uint256 _amount,
        address _beneficiary,
        uint64 /* data */
    ) external override returns (bool) {
        bool rc;

        rc = Token(_token).transferFrom(msg.sender, address(this), _amount);

        if (!rc) return false;

        rc = Token(_token).transfer(_beneficiary, _amount);

        return rc;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IERC2612 ~~~~~~~~~~ */

    /// @inheritdoc IERC2612
    function nonces(address _owner) public view returns (uint256) {
        return nonces_[_owner];
    }

    /// @inheritdoc IEIP712
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == initialChainId_
                ? initialDomainSeparator_
                : computeDomainSeparator();
    }

    /// @inheritdoc IERC2612
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(_deadline >= block.timestamp, "permit deadline expired");

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                EIP721_PERMIT_SELECTOR,
                                _owner,
                                _spender,
                                _value,
                                nonces_[_owner]++,
                                _deadline
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            require(recoveredAddress != address(0), "invalid signer");

            require(recoveredAddress == _owner, "invalid signer");

            allowances_[recoveredAddress][_spender] = _value;
        }
    }

    /* ~~~~~~~~~~ IMPLEMENTS IERC20 ~~~~~~~~~~ */

    // remaining functions are taken from OpenZeppelin's ERC20 implementation

    function name() public view returns (string memory) { return name_; }
    function symbol() public view returns (string memory) { return symbol_; }
    function decimals() public view returns (uint8) { return decimals_; }
    function totalSupply() public view returns (uint256) { return totalSupply_; }
    function balanceOf(address account) public view returns (uint256) {
       return balances_[account];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowances_[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        _spendAllowance(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    // not actually a part of IERC20 but we support it anyway

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            _spender,
            allowances_[msg.sender][_spender] + _addedValue
        );

        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = allowances_[msg.sender][_spender];

        // solhint-disable-next-line reason-string
        require(
            currentAllowance >= _subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        unchecked {
            _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    /* ~~~~~~~~~~ MISC OPERATOR FUNCTIONS ~~~~~~~~~~ */

    function setFeeDetails(uint256 _mintFee, uint256 _burnFee, address _recipient) public {
        require(msg.sender == operator_, "only operator");

        require(_mintFee < FEE_DENOM, "mint fee too high");
        require(_burnFee < FEE_DENOM, "burn fee too high");

        emit FeeSet(mintFee_, _mintFee, burnFee_, _burnFee);

        feeRecipient_ = _recipient;

        mintFee_ = _mintFee;
        burnFee_ = _burnFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IEIP712.sol";

/// @dev EIP721_PERMIT_SELECTOR that's needed for ERC2612
bytes32 constant EIP721_PERMIT_SELECTOR =
  keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

interface IERC2612 is IEIP712 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
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

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";

/// @title generic interface around an interest source
interface ILiquidityProvider {
    /**
     * @notice getter for the owner of the pool (account that can deposit and remove from it)
     * @return address of the owning account
     */
    function owner_() external view returns (address);
    /**
     * @notice gets the underlying token (ie, USDt)
     * @return address of the underlying token
     */
    function underlying_() external view returns (IERC20);

    /**
     * @notice adds `amount` of tokens to the pool from the amount in the LiquidityProvider
     * @notice requires that the user approve them first
     * @param amount number of tokens to add, in the units of the underlying token
     */
    function addToPool(uint amount) external;
    /**
     * @notice removes `amount` of tokens from the pool
     * @notice sends the tokens to the owner
     * @param amount number of tokens to remove, in the units of the underlying token
     */
    function takeFromPool(uint amount) external;
    /**
     * @notice returns the total amount in the pool, counting the invested amount and the interest earned
     * @return the amount of tokens in the pool, in the units of the underlying token
     */
    function totalPoolAmount() external returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.16;
pragma abicoder v2;

interface IOperatorOwned {
    event NewOperator(address old, address new_);

    function operator() external view returns (address);
}

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IFluidClient.sol";
import "./ILiquidityProvider.sol";

import "./IERC20.sol";

interface IToken is IERC20 {
    /// @notice emitted when a reward is quarantined for being too large
    event BlockedReward(
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when a blocked reward is released
    event UnblockReward(
        bytes32 indexed originalRewardTx,
        address indexed winner,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /// @notice emitted when an underlying token is wrapped into a fluid asset
    event MintFluid(address indexed addr, uint256 amount);

    /// @notice emitted when a fluid token is unwrapped to its underlying asset
    event BurnFluid(address indexed addr, uint256 amount);

    /// @notice emitted when restrictions
    event MaxUncheckedRewardLimitChanged(uint256 amount);

    /// @notice updating the reward quarantine before manual signoff
    /// @notice by the multisig (with updateRewardQuarantineThreshold)
    event RewardQuarantineThresholdUpdated(uint256 amount);

    /// @notice emitted when a user is permitted to mint on behalf of another user
    event MintApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice emitted when an operator sets the burn fee (1%)
    event FeeSet(
        uint256 _originalMintFee,
        uint256 _newMintFee,
        uint256 _originalBurnFee,
        uint256 _newBurnFee
    );

    /// @notice emitted when an operator changes the underlying over to a new token
    event NewUnderlyingAsset(IERC20 _old, IERC20 _new);

    /**
     * @notice getter for the RNG oracle provided by `workerConfig_`
     * @return the address of the trusted oracle
     *
     * @dev individual oracles are now recorded in the operator, this
     *      now should return the registry contract
     */
    function oracle() external view returns (address);

    /**
     * @notice underlyingToken that this IToken wraps
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice underlyingLp that's in use for the liquidity provider
     */
    function underlyingLp() external view returns (ILiquidityProvider);

    /// @notice updates the reward quarantine threshold if called by the operator
    function updateRewardQuarantineThreshold(uint256) external;

    /**
     * @notice wraps `amount` of underlying tokens into fluid tokens
     * @notice requires you to have called the ERC20 `approve` method
     * @notice targeting this contract first on the underlying asset
     *
     * @param _amount the number of tokens to wrap
     * @return the number of tokens wrapped
     */
    function erc20In(uint256 _amount) external returns (uint256);

    /**
     * @notice erc20InTo wraps the `amount` given and transfers the tokens to `receiver`
     *
     * @param _recipient of the wrapped assets
     * @param _amount to wrap and send to the recipient
     */
    function erc20InTo(address _recipient, uint256 _amount) external returns (uint256);

    /**
     * @notice unwraps `amount` of fluid tokens back to underlying
     *
     * @param _amount the number of fluid tokens to unwrap
     * @return amountReturned to the sender in the underlying
     */
    function erc20Out(uint256 _amount) external returns (uint256 amountReturned);

   /**
     * @notice unwraps `amount` of fluid tokens with the address as recipient
     *
     * @param _recipient to receive the underlying tokens to
     * @param _amount the number of fluid tokens to unwrap
     * @return amountReturned to the user of the underlying
     */
    function erc20OutTo(address _recipient, uint256 _amount) external returns (
        uint256 amountReturned
    );

   /**
     * @notice burns `amount` of fluid /without/ withdrawing the underlying
     *
     * @param _amount the number of fluid tokens to burn
     */
    function burnFluidWithoutWithdrawal(uint256 _amount) external;

    /**
     * @notice calculates the size of the reward pool (the interest we've earned)
     *
     * @return the number of tokens in the reward pool
     */
    function rewardPoolAmount() external returns (uint256);

    /**
     * @notice admin function, unblocks a reward that was quarantined for being too large
     * @notice allows for paying out or removing the reward, in case of abuse
     *
     * @param _user the address of the user who's reward was quarantined
     *
     * @param _amount the amount of tokens to release (in case
     *        multiple rewards were quarantined)
     *
     * @param _payout should the reward be paid out or removed?
     *
     * @param _firstBlock the first block the rewards include (should
     *        be from the BlockedReward event)
     *
     * @param _lastBlock the last block the rewards include
     */
    function unblockReward(
        bytes32 _rewardTx,
        address _user,
        uint256 _amount,
        bool _payout,
        uint256 _firstBlock,
        uint256 _lastBlock
    )
        external;

    /**
     * @notice return the max unchecked reward that's currently set
     */
    function maxUncheckedReward() external view returns (uint256);

    /**
     * @notice upgrade the underlying ILiquidityProvider to a new source
     * @param _newPool to shift the liquidity into
     * @param _minTokenAfterShift to enforce for the tokens quoted after shifting the assets over
     *
     * @return newPoolAmount returned from the underlying pool when asked with totalPoolAmount
     */
    function upgradeLiquidityProvider(
        ILiquidityProvider _newPool,
        uint256 _minTokenAfterShift
    ) external returns (uint256 newPoolAmount);

    /**
     * @notice drain the reward pool of the amount given without
     *         touching any principal amounts
     *
     * @dev this is intended to only be used to retrieve initial
     *       liquidity provided by the team OR by the DAO to allocate funds
     */
    function drainRewardPool(address _recipient, uint256 _amount) external;

    /**
     * @notice setFeeDetails for any fees that may be taken on mint or burn
     * @param _mintFee numerated so that 10 is 1% taken on minting
     * @param _burnFee numerated so that 30 is 3% taken on burning
     * @param _recipient to send fees earned to using a minting interaction
     *
     * @dev the purpose of the mint fee primarily is to facilitate the
     *      circular liquidity provider (StupidLiquidityProvider) on
     *      self-contained chains
     */
    function setFeeDetails(uint256 _mintFee, uint256 _burnFee, address _recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Interface for transferWithBeneficiary
interface ITransferWithBeneficiary {
    /**
     * @notice Make a token transfer that the *signer* is paying tokens but
     * benefits are given to the *beneficiary*
     * @param _token The contract address of the transferring token
     * @param _amount The amount of the transfer
     * @param _beneficiary The address that will receive benefits of this transfer
     * @param _data Extra data passed to the contract
     * @return Returns true for a successful transfer.
     */
    function transferWithBeneficiary(
        address _token,
        uint256 _amount,
        address _beneficiary,
        uint64 _data
    ) external returns (bool);
}