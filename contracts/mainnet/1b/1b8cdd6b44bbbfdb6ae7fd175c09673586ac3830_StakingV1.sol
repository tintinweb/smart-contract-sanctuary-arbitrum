// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

/*
 * Fluidity Money takes security seriously.
 *
 * If you find anything, or there's anything you think we should know, contact us
 * immediately with https://docs.fluidity.money/docs/security/contactable-team .
 *
 * If you find something urgent, and you think funds are immediately at risk, we encourage
 * you to exploit the vulnerability if there is no other choice and to move the funds into
 * one of our our dropboxes at https://docs.fluidity.money/docs/security/dropboxes .
 *
 * At the time of writing, the Arbtirum dropbox is
 * 0xfA763219492AE371b35c524655D8972F2D2AF197. Assets moved here will set off alarm bells.
 */

pragma solidity 0.8.16;
pragma abicoder v2;

import "./openzeppelin/SafeERC20.sol";

import "../interfaces/IEmergencyMode.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IOperatorOwned.sol";
import "../interfaces/IERC20ERC2612.sol";

uint8 constant STAKING_DECIMALS = 1;

string constant STAKING_NAME = "Staked FLY";

string constant STAKING_SYMBOL = "sFLY";

uint256 constant UNBONDING_PERIOD = 7 days;

uint constant MAX_STAKING_POSITIONS = 100;

struct StakedPrivate {
    // receivedBonus for the day 1 staking?
    bool receivedBonus;

    // flyVested supplied by users.
    uint256 flyVested;

    // depositTimestamp when the staking was completed.
    uint256 depositTimestamp;
}

struct UnstakingPrivate {
    // flyAmount that was staked originally.
    uint256 flyAmount;

    // unstakedTimestamp to use as the final timestamp that the amount is
    // fully unstaked by (ie, 7 days + the future timestamp when unstaking happens)
    uint256 unstakedTimestamp;
}

contract StakingV1 is IStaking, IERC20, IEmergencyMode, IOperatorOwned {
    using SafeERC20 for IERC20ERC2612;

    event NewMerkleDistributor(address old, address _new);

    /* ~~~~~~~~~~ HOUSEKEEPING ~~~~~~~~~~ */

    /// @dev if false, emergency mode is active - can be called by either the
    ///      operator or emergency council
    bool private noEmergencyMode_;

    // for migrations
    uint private version_;

    /* ~~~~~~~~~~ OWNERSHIP ~~~~~~~~~~ */

    /// @dev emergency council that can activate emergency mode
    address private emergencyCouncil_;

    /// @dev account to use that created the contract (multisig account)
    address private operator_;

    /* ~~~~~~~~~~ GLOBAL STORAGE ~~~~~~~~~~ */

    IERC20ERC2612 private flyToken_;

    address private merkleDistributor_;

    // used for future upgrades
    // solhint-disable-next-line var-name-mixedcase
    uint256[64] private __bookmark_1;

    /* ~~~~~~~~~~ USER STORAGE ~~~~~~~~~~ */

    /// @dev stakedStorage_ per user with their staked accounts in each item.
    mapping(address => StakedPrivate[]) private stakedStorage_;

    /// @dev unstakingStorage_ amounts that are waiting to be collected
    /// in the future from being unstaked.
    mapping(address => UnstakingPrivate[]) private unstakingStorage_;

    /* ~~~~~~~~~~ SETUP FUNCTIONS ~~~~~~~~~~ */

    /**
     * @notice init the contract, setting up the ownership, and the location of the
     *         MerkleDistributor contract.
     *
     * @param _flyToken to take for staking from the user.
     * @param _merkleDistributor to support for the stakeFor function.
     * @param _emergencyCouncil to give the power to freeze the contract.
     * @param _operator to use as the special privilege for retroactively awarding/admin power.
     */
    function init(
        IERC20ERC2612 _flyToken,
        address _merkleDistributor,
        address _emergencyCouncil,
        address _operator
    ) public {
        require(version_ == 0, "contract is already initialised");

        version_ = 1;
        noEmergencyMode_ = true;

        emergencyCouncil_ = _emergencyCouncil;
        operator_ = _operator;

        flyToken_ = _flyToken;
        merkleDistributor_ = _merkleDistributor;

        emit NewMerkleDistributor(address(0), merkleDistributor_);
    }

    /* ~~~~~~~~~~ INTERNAL FUNCTIONS ~~~~~~~~~~ */

    function _calcDay1Points(uint256 _flyAmount) internal pure returns (uint256 points) {
        return (_flyAmount * 4 * 7 days * 3) / 1e12; // 1e12 to reduce the fly amount too
    }

    function calculatePoints(uint256 curTimestamp, StakedPrivate memory _staked) public pure returns (uint256 points) {
        /*
         * Calculate the points earned by the user, using the math:

a = x * (seconds_since_start * 0.0000000000001)
if day_1_staked_bonus: a += fly_staked * 0.0000000000001 * (24*7*60*60)
return a

        */

        points = _staked.flyVested * ((curTimestamp - _staked.depositTimestamp)) / 1e12;
        if (_staked.receivedBonus) points += _calcDay1Points(_staked.flyVested);
    }

    /**
     * @notice calculatePointsAddSecs external helper function to get an idea of points earned for staking.
     * @param _seconds to add to the staked struct passed as an argument.
     * @param _staked to use as the staked structure.
     */
    function calculatePointsAddSecs(uint256 _seconds, StakedPrivate memory _staked) external pure returns (uint256 points) {
        return calculatePoints(_staked.depositTimestamp + _seconds, _staked);
    }

    function _stake(
        address _spender,
        address _recipient,
        uint256 _flyAmount,
        bool _claimAndStakeBonus
    ) internal returns (uint256 _flyStaked) {
        require(noEmergencyMode_, "emergency mode!");
        require(_flyAmount > 0, "zero fly");

        require(
            stakedStorage_[_recipient].length < MAX_STAKING_POSITIONS,
            "too many staked positions"
        );

        stakedStorage_[_recipient].push(StakedPrivate({
            receivedBonus: _claimAndStakeBonus,
            flyVested: _flyAmount,
            depositTimestamp: block.timestamp
        }));

        // take the ERC20 from the spender.
        flyToken_.safeTransferFrom(_spender, address(this), _flyAmount);

        return _flyAmount;
    }

    function _popStakedPosition(address _spender, uint i) internal {
        // if the amount of staked positions from the user exceeds 1,
        // then we can replace them with the last item in the array, then
        // pop them.
        // make sure to always iterate the opposite direction through
        // this list.
        uint256 len = stakedStorage_[_spender].length;
        if (len > 1) {
            StakedPrivate storage x = stakedStorage_[_spender][len - 1];
            stakedStorage_[_spender][i] = x;
        }
        stakedStorage_[_spender].pop();
    }

    function _popUnstakingPosition(address _spender, uint i) internal {
        // see the _popStakedPosition function for how this works (same design.)
        uint256 len = unstakingStorage_[_spender].length;
        if (len > 1) {
            UnstakingPrivate storage x = unstakingStorage_[_spender][len - 1];
            unstakingStorage_[_spender][i] = x;
        }
        unstakingStorage_[_spender].pop();
    }

    /* ~~~~~~~~~~ INFORMATIONAL ~~~~~~~~~~ */

    function stakingPositionsLen(address _account) public view returns (uint) {
        return stakedStorage_[_account].length;
    }

    function stakedPositionInfo(address _account, uint _i) public view returns (bool receivedBonus, uint256 flyVested, uint256 depositTimestamp) {
        StakedPrivate storage s = stakedStorage_[_account][_i];
        receivedBonus = s.receivedBonus;
        flyVested = s.flyVested;
        depositTimestamp = s.depositTimestamp;
    }

    function unstakingPositionsLen(address _account) public view returns (uint) {
        return unstakingStorage_[_account].length;
    }

    function unstakingPositionInfo(address _account, uint _i) public view returns (uint256 flyAmount, uint256 unstakedTimestamp) {
        UnstakingPrivate storage s = unstakingStorage_[_account][_i];
        flyAmount = s.flyAmount;
        unstakedTimestamp = s.unstakedTimestamp;
    }

    /// @inheritdoc IStaking
    function stakingDetails(address _account) public view returns (uint256 flyStaked, uint256 points) {
        for (uint i = 0; i < stakedStorage_[_account].length; i++) {
            StakedPrivate storage s = stakedStorage_[_account][i];
            points += calculatePoints(block.timestamp, s);
            flyStaked += s.flyVested;
        }
    }

    /// @inheritdoc IStaking
    function merkleDistributor() public view returns (address) {
        return merkleDistributor_;
    }

    /// @inheritdoc IStaking
    function minFlyAmount() public pure returns (uint256 flyAmount) {
        return 0;
    }

    /* ~~~~~~~~~~ NORMAL USER PUBLIC ~~~~~~~~~~ */

    /// @inheritdoc IStaking
    function stake(uint256 _flyAmount) public returns (uint256 flyStaked) {
        return _stake(msg.sender, msg.sender, _flyAmount, false);
    }

    /// @inheritdoc IStaking
    function stakePermit(
        uint256 _flyAmount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (uint256 flyStaked) {
        flyToken_.permit(msg.sender, address(this), _flyAmount, _deadline, _v, _r, _s);
        return stake(_flyAmount);
    }

    /// @inheritdoc IStaking
    function stakeFor(address _recipient, uint256 _flyAmount) public returns (
        uint256 flyStaked,
        uint256 day1Points
    ) {
        require(msg.sender == merkleDistributor_, "not merkle distributor");
        flyStaked = _stake(msg.sender, _recipient, _flyAmount, true);
        return (flyStaked, _calcDay1Points(_flyAmount));
    }

    /// @inheritdoc IStaking
    function beginUnstake(
        uint256 _flyToUnstake
    ) external returns (uint256 flyRemaining, uint256 unstakedBy) {
        // for every staked position created by the user, attempt to take
        // amounts from the user with them asking. if they get to 0, then we destroy
        // the position, then move on.
        flyRemaining = _flyToUnstake;
        uint len = stakedStorage_[msg.sender].length;
        unstakedBy = block.timestamp;
        if (len == 0) revert("no fly unstaked");
        unstakedBy += UNBONDING_PERIOD;
        // it's important to always break here if we're at 0.
        for (uint i = len - 1; i >= 0; i--) {
            if (flyRemaining == 0) break;
            StakedPrivate storage s = stakedStorage_[msg.sender][i];
            if (flyRemaining >= s.flyVested) {
                // the FLY staked in this position is less than the amount requested.
                // take the full amount for this position, pop the staked amount, reduce
                // the fly remaining, then move on.
                flyRemaining -= s.flyVested;
                unstakingStorage_[msg.sender].push(UnstakingPrivate({
                    flyAmount: s.flyVested,
                    unstakedTimestamp: unstakedBy
                }));
                _popStakedPosition(msg.sender, i);
                if (i == 0) break;
            } else {
                // the FLY staked in this position is more than what's remaining. so we
                // can update the existing staked amount to reduce the FLY that they
                // requested, then we can just return here.
                stakedStorage_[msg.sender][i].flyVested -= flyRemaining;
                unstakingStorage_[msg.sender].push(UnstakingPrivate({
                    flyAmount: flyRemaining,
                    unstakedTimestamp: unstakedBy
                }));
                flyRemaining = 0;
                break;
            }
        }
        require(_flyToUnstake > flyRemaining, "no fly unstaked");
        return (flyRemaining, unstakedBy);
    }

    /// @inheritdoc IStaking
    function amountUnstaking(address _owner) public view returns (uint256 flyAmount) {
        for (uint i = 0; i < unstakingStorage_[_owner].length; i++) {
            flyAmount += unstakingStorage_[_owner][i].flyAmount;
        }
    }

    /// @inheritdoc IStaking
    function secondsUntilSoonestUnstake(
        address _spender
    ) public view returns (uint256 shortestSecs) {
        for (uint i = 0; i < unstakingStorage_[_spender].length; i++) {
            uint256 ts = unstakingStorage_[_spender][i].unstakedTimestamp;
            if (ts > block.timestamp) {
                uint256 remaining =  ts - block.timestamp;
                // if we haven't set the shortest number of seconds, we
                // set it to whatever we can, or we set it to the
                // smallest value.
                if (shortestSecs == 0 || remaining < shortestSecs) shortestSecs = remaining;
            }
        }
    }

    /// @inheritdoc IStaking
    function finaliseUnstake() public returns (uint256 flyReturned) {
        // iterate through all the unstaking positions, and, if the unstaked
        // timestamp is greater than the block timestamp, then remove their
        // unstaked position, and increase the fly returned. then pop them from
        // the unstaking list.
        uint len = unstakingStorage_[msg.sender].length;
        if (len == 0) return 0;
        for (uint i = len - 1; i >= 0; i--) {
            UnstakingPrivate storage s = unstakingStorage_[msg.sender][i];
            // if the timestamp for the time that we need to unstake is more than the
            // current, break out.
            if (s.unstakedTimestamp > block.timestamp) {
              if (i == 0) break;
              else continue;
            }
            // unstake now.
            flyReturned += s.flyAmount;
            _popUnstakingPosition(msg.sender, i);
            if (i == 0) break;
        }
        // now we can use ERC20 to send the token back, if they got more than 0 back.
        if (flyReturned == 0) revert("no fly returned");
        flyToken_.safeTransfer(msg.sender, flyReturned);
    }

    /* ~~~~~~~~~~ OPERATOR ~~~~~~~~~~ */

    function updateMerkleDistributor(address _old, address _new) public {
        require(msg.sender == operator_, "operator only");
        require(merkleDistributor_ == _old, "incorrect order");
        merkleDistributor_ = _new;
        emit NewMerkleDistributor(_old, _new);
    }

    /* ~~~~~~~~~~ EMERGENCY FUNCTIONS ~~~~~~~~~~ */

    /// @inheritdoc IStaking
    function emergencyWithdraw() external {
	// take out whatever we can for the user, assuming that if we're
	// at this point, the contract is junk, and is needing a code
	// upgrade. so we keep the implementation of this as simple as
	// possible, without using the popping function from earlier.
        require(!noEmergencyMode_, "not emergency");
        uint256 flyAmount = 0;
        for (uint i = 0; i < stakedStorage_[msg.sender].length; i++) {
            flyAmount += stakedStorage_[msg.sender][i].flyVested;
            stakedStorage_[msg.sender][i].flyVested = 0;
        }
        for (uint i = 0; i < unstakingStorage_[msg.sender].length; i++) {
            flyAmount += unstakingStorage_[msg.sender][i].flyAmount;
            unstakingStorage_[msg.sender][i].flyAmount = 0;
        }
        flyToken_.safeTransfer(msg.sender, flyAmount);
    }

    /* ~~~~~~~~~~ IMPLEMENTS IOperatorOwned ~~~~~~~~~~ */

    /// @inheritdoc IOperatorOwned
    function operator() public view returns (address) {
        return operator_;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IEmergencyMode ~~~~~~~~~~ */

    /// @inheritdoc IEmergencyMode
    function enableEmergencyMode() public {
        require(
            msg.sender == operator_ || msg.sender == emergencyCouncil_,
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

    /// @inheritdoc IEmergencyMode
    function noEmergencyMode() public view returns (bool) {
        return noEmergencyMode_;
    }

    /// @inheritdoc IEmergencyMode
    function emergencyCouncil() public view returns (address) {
        return emergencyCouncil_;
    }

    /* ~~~~~~~~~~ IMPLEMENTS IERC20 ~~~~~~~~~~ */

    function allowance(address /* owner */, address /* spender */) external pure returns (uint256) {
        return 0;
    }

    function approve(address /* spender */, uint256 /* amount */) external pure returns (bool) {
        return false;
    }

    function balanceOf(address account) external view returns (uint256) {
        (, uint256 points) = stakingDetails(account);
        return points;
    }

    function decimals() external pure returns (uint8) {
        return STAKING_DECIMALS;
    }

    function name() external pure returns (string memory) {
        return STAKING_NAME;
    }

    function symbol() external pure returns (string memory) {
        return STAKING_SYMBOL;
    }

    function totalSupply() external pure returns (uint256) {
        return type(uint256).max;
    }

    function transfer(address /* to */, uint256 /* amount */) external pure returns (bool) {
        revert("no transfer");
    }

    function transferFrom(
        address /* from */,
        address /* to */,
        uint256 /* amount */
    ) external pure returns (bool) {
        revert("no transfer");
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

// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.16;
pragma abicoder v2;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IERC20ERC2612 is IERC20, IERC2612 {}

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

struct Staked {
    address account;
    uint256 points;
}

/*
 * IStaking is a simple staking contract with a 7 day unbonding period that requires manual
 * intervention to access after the interaction has begun. The user has their points
 * zeroed when they begin unstaking. In the interim, the UI displays them as "lost".
 * Not intended to be used as a voting contract or anything similar, so it lacks the facilities
 * for this.
 *
 * The user's deposit time and the seconds since are recorded in the contract, and a simple
 * getter method is provided to accumulate the points and amounts staked for simplicity,
 * which should be called infrequently owing to it's gas profile, perhaps only simulated.
 *
 * The Staking contract pretends to be a ERC20 amount, though the transfer and allowance
 * functions are broken.
 *
 * A function is added for an operator to retroactievely provide the signup bonus based on
 * the lag between the claim and the stake (in some cases.)
 *
 * An extra function called "emergencyWithdraw" is provided for users to pull their staked
 * amounts out in an emergency mode stake.
*/
interface IStaking {
    /* ~~~~~~~~~~ SIMPLE GETTER ~~~~~~~~~~ */

    /// @notice merkleDistributor that's in use for the stakeFor function.
    function merkleDistributor() external view returns (address);

    /// @notice minFlyAmount that must be supplied for staking.
    function minFlyAmount() external pure returns (uint256 flyAmount);

    /* ~~~~~~~~~~ NORMAL USER ~~~~~~~~~~ */

    /**
     * @notice stake the amount given.
     * @param _flyAmount to take from the msg.sender.
     */
    function stake(uint256 _flyAmount) external returns (uint256 flyStaked);

    /**
     * @notice stake the amount given, using the permit router for approvals beforehand.
     * @param _flyAmount to take from the msg.sender.
     * @param _deadline as the expiration date for the permit call to the contract.
     * @param _v recovery ID for the signature.
     * @param _r point on the elliptic curve
     * @param _s point on the elliptic curve for address derivation using a signature.
     */
    function stakePermit(
        uint256 _flyAmount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 flyStaked);

    /**
     * @notice stakeFor a user using tokens from msg.sender. Currently gated for the
     *         merkle distributor, so as to prevent abuse.
     * @param _spender to stake on behalf of.
     * @param _amount to take from the msg.sender, to stake on behalf of the user.
     */
    function stakeFor(address _spender, uint256 _amount) external returns (
        uint256 flyStaked,
        uint256 day1Points
    );

    /**
     * @notice stakingDetails for a specific user.
     * @param _account to check.
     */
    function stakingDetails(address _account) external view returns (
        uint256 flyStaked,
        uint256 points
    );

    /**
     * @notice beginUnstake for the address given, unstaking from the leftmost position
     *         until we unstake the amount requested.
     * @param _flyToUnstake the amount to request to unstake for the user.
     * @return flyRemaining from the unstaking process.
     * @return unstakedBy the timestamp by which every position is fully unstaked.
     */
    function beginUnstake(
        uint256 _flyToUnstake
    ) external returns (uint256 flyRemaining, uint256 unstakedBy);

    /**
     * @notice amountUnstaking that the user has requested in the past, cumulatively.
     * @param _owner of the amounts that are unstaking to check.
     */
    function amountUnstaking(address _owner) external view returns (uint256 flyAmount);

    /**
     * @notice secondsUntilSoonestUnstake for the soonest amount of seconds until a unstake is possible.
     * @param _spender of the fully unstaking process.
     */
    function secondsUntilSoonestUnstake(address _spender) external view returns (uint256 shortestSecs);

    /**
     * @notice finaliseUnstake for a user, if they're past the unbonding period.
     */
    function finaliseUnstake() external returns (uint256 flyReturned);

    /**
     * @notice emergencyWithdraw the sender's balance, if the contract is in a state of emergency.
     */
    function emergencyWithdraw() external;
}