// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IVestingCustom.sol";

/**
 * @title VestingCustom
 * @author Enjinstarter
 */
contract VestingCustom is Pausable, IVestingCustom {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct CustomVestingScheduleEntry {
        uint256 percentRelease; // Percentage of grant amount to be released
        uint256 startTimestamp; // Start timestamp
        uint256 durationDays; // Duration in days
        uint256 endTimestamp; // End timestamp
    }

    struct VestingGrant {
        uint256 grantAmount; // Total number of tokens granted
        bool isRevocable; // true if vesting grant is revocable (a gift), false if irrevocable (purchased)
        bool isRevoked; // true if vesting grant has been revoked
        bool isActive; // true if vesting grant is active
    }

    uint256 public constant BATCH_MAX_NUM = 100;
    uint256 public constant SCHEDULE_MAX_ENTRIES = 100;
    uint256 public constant TOKEN_MAX_DECIMALS = 18;
    uint256 public constant PERCENT_100_WEI = 100 ether;
    uint256 public constant SECONDS_IN_DAY = 86400;

    address public governanceAccount;
    address public vestingAdmin;
    address public tokenAddress;
    uint256 public tokenDecimals;
    uint256 public totalGrantAmount;
    uint256 public totalReleasedAmount;
    bool public allowAccumulate;
    uint256 public numVestingScheduleEntries;

    mapping(uint256 => CustomVestingScheduleEntry) private _vestingSchedule;
    mapping(address => VestingGrant) private _vestingGrants;
    mapping(address => uint256) private _released;

    constructor(
        address tokenAddress_,
        uint256 tokenDecimals_,
        bool allowAccumulate_
    ) {
        require(
            tokenAddress_ != address(0),
            "VestingCustom: zero token address"
        );
        require(
            tokenDecimals_ <= TOKEN_MAX_DECIMALS,
            "VestingCustom: token decimals exceed 18"
        );

        governanceAccount = msg.sender;
        vestingAdmin = msg.sender;

        tokenAddress = tokenAddress_;
        tokenDecimals = tokenDecimals_;

        allowAccumulate = allowAccumulate_;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "VestingCustom: sender unauthorized");
        _;
    }

    /**
     * @dev isRevocable will be ignored if grant already added but amount allowed to accumulate.
     */
    function addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) external override onlyBy(vestingAdmin) {
        _addVestingGrant(account, grantAmount, isRevocable);
    }

    function revokeVestingGrant(address account)
        external
        override
        onlyBy(vestingAdmin)
    {
        _revokeVestingGrant(account);
    }

    function release() external override whenNotPaused {
        uint256 releasableAmount = releasableAmountFor(msg.sender);

        _release(msg.sender, releasableAmount);
    }

    function transferUnusedTokens()
        external
        override
        onlyBy(governanceAccount)
    {
        uint256 balanceInDecimals = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        uint256 balanceInWei = scaleDecimalsToWei(
            balanceInDecimals,
            tokenDecimals
        );

        uint256 unusedAmount = balanceInWei.add(totalReleasedAmount).sub(
            totalGrantAmount
        );
        require(unusedAmount > 0, "VestingCustom: nothing to transfer");

        uint256 transferAmount = scaleWeiToDecimals(
            unusedAmount,
            tokenDecimals
        );
        IERC20(tokenAddress).safeTransfer(governanceAccount, transferAmount);
    }

    function addVestingGrantsBatch(
        address[] memory accounts,
        uint256[] memory grantAmounts,
        bool[] memory isRevocables
    ) external override onlyBy(vestingAdmin) {
        require(accounts.length > 0, "VestingCustom: empty");
        require(accounts.length <= BATCH_MAX_NUM, "VestingCustom: exceed max");
        require(
            grantAmounts.length == accounts.length,
            "VestingCustom: grant amounts length different"
        );
        require(
            isRevocables.length == accounts.length,
            "VestingCustom: is revocables length different"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _addVestingGrant(accounts[i], grantAmounts[i], isRevocables[i]);
        }
    }

    function revokeVestingGrantsBatch(address[] memory accounts)
        external
        override
        onlyBy(vestingAdmin)
    {
        require(accounts.length > 0, "VestingCustom: empty");
        require(accounts.length <= BATCH_MAX_NUM, "VestingCustom: exceed max");

        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeVestingGrant(accounts[i]);
        }
    }

    function setVestingSchedule(
        uint256[] calldata startTimestamps,
        uint256[] calldata percentReleases,
        uint256[] calldata durationsDays
    ) external override onlyBy(vestingAdmin) {
        require(startTimestamps.length > 0, "VestingCustom: empty");
        require(
            startTimestamps.length <= SCHEDULE_MAX_ENTRIES,
            "VestingCustom: exceed max"
        );
        require(
            percentReleases.length == startTimestamps.length,
            "VestingCustom: percent length different"
        );
        require(
            durationsDays.length == startTimestamps.length,
            "VestingCustom: duration length different"
        );
        require(
            numVestingScheduleEntries == 0 ||
                block.timestamp < _vestingSchedule[0].startTimestamp,
            "VestingCustom: already started"
        );

        uint256 minTimestamp = block.timestamp;
        uint256 totalPercentRelease = 0;

        for (uint256 i = 0; i < startTimestamps.length; i++) {
            require(percentReleases[i] > 0, "VestingCustom: zero percent");
            require(
                startTimestamps[i] >= minTimestamp,
                "VestingCustom: invalid start timestamp"
            );

            totalPercentRelease = totalPercentRelease.add(percentReleases[i]);
            require(
                totalPercentRelease <= PERCENT_100_WEI,
                "VestingCustom: exceed 100%"
            );

            if (durationsDays[i] > 0) {
                minTimestamp = startTimestamps[i].add(
                    durationsDays[i].mul(SECONDS_IN_DAY)
                );
            } else {
                minTimestamp = startTimestamps[i];
            }

            _vestingSchedule[i] = CustomVestingScheduleEntry({
                percentRelease: percentReleases[i],
                startTimestamp: startTimestamps[i],
                durationDays: durationsDays[i],
                endTimestamp: minTimestamp
            });
        }

        require(
            totalPercentRelease == PERCENT_100_WEI,
            "VestingCustom: not 100%"
        );

        numVestingScheduleEntries = startTimestamps.length;

        emit ScheduleSet(
            msg.sender,
            startTimestamps,
            percentReleases,
            durationsDays
        );
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "VestingCustom: zero account");

        governanceAccount = account;
    }

    function setVestingAdmin(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "VestingCustom: zero account");

        vestingAdmin = account;
    }

    function pause() external onlyBy(vestingAdmin) {
        _pause();
    }

    function unpause() external onlyBy(vestingAdmin) {
        _unpause();
    }

    function getVestingSchedule()
        external
        view
        override
        returns (
            uint256[] memory startTimestamps,
            uint256[] memory percentReleases,
            uint256[] memory durationsDays,
            uint256[] memory endTimestamps
        )
    {
        startTimestamps = new uint256[](numVestingScheduleEntries);
        percentReleases = new uint256[](numVestingScheduleEntries);
        durationsDays = new uint256[](numVestingScheduleEntries);
        endTimestamps = new uint256[](numVestingScheduleEntries);

        if (numVestingScheduleEntries > 0) {
            for (uint256 i = 0; i < numVestingScheduleEntries; i++) {
                startTimestamps[i] = _vestingSchedule[i].startTimestamp;
                percentReleases[i] = _vestingSchedule[i].percentRelease;
                durationsDays[i] = _vestingSchedule[i].durationDays;
                endTimestamps[i] = _vestingSchedule[i].endTimestamp;
            }
        }
    }

    function vestingGrantFor(address account)
        external
        view
        override
        returns (
            uint256 grantAmount,
            bool isRevocable,
            bool isRevoked,
            bool isActive
        )
    {
        require(account != address(0), "VestingCustom: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        grantAmount = vestingGrant.grantAmount;
        isRevocable = vestingGrant.isRevocable;
        isRevoked = vestingGrant.isRevoked;
        isActive = vestingGrant.isActive;
    }

    function unvestedAmountFor(address account)
        external
        view
        override
        returns (uint256 unvestedAmount)
    {
        require(account != address(0), "VestingCustom: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "VestingCustom: inactive");

        if (revoked(account)) {
            unvestedAmount = 0;
        } else {
            unvestedAmount = vestingGrant.grantAmount.sub(
                vestedAmountFor(account)
            );
        }
    }

    function revoked(address account)
        public
        view
        override
        returns (bool isRevoked)
    {
        require(account != address(0), "VestingCustom: zero account");

        isRevoked = _vestingGrants[account].isRevoked;
    }

    function releasedAmountFor(address account)
        public
        view
        override
        returns (uint256 releasedAmount)
    {
        require(account != address(0), "VestingCustom: zero account");

        releasedAmount = _released[account];
    }

    function releasableAmountFor(address account)
        public
        view
        override
        returns (uint256 releasableAmount)
    {
        require(account != address(0), "VestingCustom: zero account");
        require(
            numVestingScheduleEntries > 0 &&
                _vestingSchedule[0].startTimestamp > 0,
            "VestingCustom: undefined schedule"
        );
        require(
            block.timestamp >= _vestingSchedule[0].startTimestamp,
            "VestingCustom: not started"
        );
        require(!revoked(account), "VestingCustom: revoked");

        uint256 vestedAmount = vestedAmountFor(account);
        releasableAmount = scaleDecimalsToWei(
            scaleWeiToDecimals(vestedAmount, tokenDecimals),
            tokenDecimals
        ).sub(releasedAmountFor(account));
    }

    function vestedAmountFor(address account)
        public
        view
        override
        returns (uint256 vestedAmount)
    {
        require(account != address(0), "VestingCustom: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "VestingCustom: inactive");

        if (
            numVestingScheduleEntries == 0 ||
            _vestingSchedule[0].startTimestamp == 0
        ) {
            return 0;
        }

        if (block.timestamp < _vestingSchedule[0].startTimestamp) {
            return 0;
        }

        if (revoked(account)) {
            return releasedAmountFor(account);
        }

        if (
            block.timestamp >=
            _vestingSchedule[numVestingScheduleEntries - 1].endTimestamp
        ) {
            return vestingGrant.grantAmount;
        }

        uint256 totalPercentRelease = 0;

        for (uint256 i = 0; i < numVestingScheduleEntries; i++) {
            if (block.timestamp < _vestingSchedule[i].startTimestamp) {
                break;
            }

            if (block.timestamp >= _vestingSchedule[i].endTimestamp) {
                totalPercentRelease = totalPercentRelease.add(
                    _vestingSchedule[i].percentRelease
                );
            } else {
                uint256 durationSeconds = _vestingSchedule[i].durationDays.mul(
                    SECONDS_IN_DAY
                );
                uint256 percentRelease = block
                    .timestamp
                    .sub(_vestingSchedule[i].startTimestamp)
                    .mul(_vestingSchedule[i].percentRelease);

                totalPercentRelease = totalPercentRelease
                    .mul(durationSeconds)
                    .add(percentRelease)
                    .div(durationSeconds);
                break;
            }
        }

        vestedAmount = vestingGrant.grantAmount.mul(totalPercentRelease).div(
            PERCENT_100_WEI
        );
    }

    function scaleWeiToDecimals(uint256 weiAmount, uint256 decimals)
        public
        pure
        returns (uint256 decimalsAmount)
    {
        require(
            decimals <= TOKEN_MAX_DECIMALS,
            "VestingCustom: decimals exceed 18"
        );

        if (decimals < TOKEN_MAX_DECIMALS && weiAmount > 0) {
            uint256 decimalsDiff = uint256(TOKEN_MAX_DECIMALS).sub(decimals);
            decimalsAmount = weiAmount.div(10**decimalsDiff);
        } else {
            decimalsAmount = weiAmount;
        }
    }

    function scaleDecimalsToWei(uint256 decimalsAmount, uint256 decimals)
        public
        pure
        returns (uint256 weiAmount)
    {
        require(
            decimals <= TOKEN_MAX_DECIMALS,
            "VestingCustom: decimals exceed 18"
        );

        if (decimals < TOKEN_MAX_DECIMALS && decimalsAmount > 0) {
            uint256 decimalsDiff = uint256(TOKEN_MAX_DECIMALS).sub(decimals);
            weiAmount = decimalsAmount.mul(10**decimalsDiff);
        } else {
            weiAmount = decimalsAmount;
        }
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
    // slither-disable-next-line calls-loop
    function _addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) private {
        require(account != address(0), "VestingCustom: zero account");
        require(grantAmount > 0, "VestingCustom: zero grant amount");

        require(
            numVestingScheduleEntries == 0 ||
                block.timestamp < _vestingSchedule[0].startTimestamp,
            "VestingCustom: already started"
        );

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(
            allowAccumulate || !vestingGrant.isActive,
            "VestingCustom: already added"
        );
        require(!revoked(account), "VestingCustom: already revoked");

        // https://github.com/crytic/slither/wiki/Detector-Documentation#costly-operations-inside-a-loop
        // slither-disable-next-line costly-loop
        totalGrantAmount = totalGrantAmount.add(grantAmount);
        uint256 balanceInDecimals = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        require(balanceInDecimals > 0, "VestingCustom: zero balance");
        uint256 balanceInWei = scaleDecimalsToWei(
            balanceInDecimals,
            tokenDecimals
        );
        require(
            totalGrantAmount <= balanceInWei,
            "VestingCustom: total grant amount exceed balance"
        );

        if (vestingGrant.isActive) {
            _vestingGrants[account].grantAmount = vestingGrant.grantAmount.add(
                grantAmount
            );
            // _vestingGrants[account].isRevocable = isRevocable;
        } else {
            _vestingGrants[account] = VestingGrant({
                grantAmount: grantAmount,
                isRevocable: isRevocable,
                isRevoked: false,
                isActive: true
            });
        }

        emit VestingGrantAdded(account, grantAmount, isRevocable);
    }

    function _revokeVestingGrant(address account) private {
        require(account != address(0), "VestingCustom: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "VestingCustom: inactive");
        require(vestingGrant.isRevocable, "VestingCustom: not revocable");
        require(!revoked(account), "VestingCustom: already revoked");

        uint256 releasedAmount = releasedAmountFor(account);
        uint256 remainderAmount = vestingGrant.grantAmount.sub(releasedAmount);
        // https://github.com/crytic/slither/wiki/Detector-Documentation#costly-operations-inside-a-loop
        // slither-disable-next-line costly-loop
        totalGrantAmount = totalGrantAmount.sub(remainderAmount);
        _vestingGrants[account].isRevoked = true;

        emit VestingGrantRevoked(
            account,
            remainderAmount,
            vestingGrant.grantAmount,
            releasedAmount
        );
    }

    function _release(address account, uint256 amount) private {
        require(account != address(0), "VestingCustom: zero account");
        require(amount > 0, "VestingCustom: zero amount");

        uint256 transferDecimalsAmount = scaleWeiToDecimals(
            amount,
            tokenDecimals
        );
        uint256 transferWeiAmount = scaleDecimalsToWei(
            transferDecimalsAmount,
            tokenDecimals
        );

        _released[account] = _released[account].add(transferWeiAmount);
        totalReleasedAmount = totalReleasedAmount.add(transferWeiAmount);

        emit TokensReleased(account, transferWeiAmount);

        IERC20(tokenAddress).safeTransfer(account, transferDecimalsAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title IVestingCustom
 * @author Enjinstarter
 */
interface IVestingCustom {
    event VestingGrantAdded(
        address indexed account,
        uint256 indexed grantAmount,
        bool isRevocable
    );

    event VestingGrantRevoked(
        address indexed account,
        uint256 remainderAmount,
        uint256 grantAmount,
        uint256 releasedAmount
    );

    event TokensReleased(address indexed account, uint256 amount);

    event ScheduleSet(
        address indexed account,
        uint256[] startTimestamps,
        uint256[] percentReleases,
        uint256[] durationsDays
    );

    function addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) external;

    function revokeVestingGrant(address account) external;

    function release() external;

    function transferUnusedTokens() external;

    function addVestingGrantsBatch(
        address[] memory accounts,
        uint256[] memory grantAmounts,
        bool[] memory isRevocables
    ) external;

    function revokeVestingGrantsBatch(address[] memory accounts) external;

    function setVestingSchedule(
        uint256[] calldata startTimestamps,
        uint256[] calldata percentReleases,
        uint256[] calldata durationsDays
    ) external;

    function setGovernanceAccount(address account) external;

    function setVestingAdmin(address account) external;

    function getVestingSchedule()
        external
        view
        returns (
            uint256[] memory startTimestamps,
            uint256[] memory percentReleases,
            uint256[] memory durationsDays,
            uint256[] memory endTimestamps
        );

    function vestingGrantFor(address account)
        external
        view
        returns (
            uint256 grantAmount,
            bool isRevocable,
            bool isRevoked,
            bool isActive
        );

    function revoked(address account) external view returns (bool isRevoked);

    function releasedAmountFor(address account)
        external
        view
        returns (uint256 releasedAmount);

    function releasableAmountFor(address account)
        external
        view
        returns (uint256 unreleasedAmount);

    function vestedAmountFor(address account)
        external
        view
        returns (uint256 vestedAmount);

    function unvestedAmountFor(address account)
        external
        view
        returns (uint256 unvestedAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}