// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Node is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public kong;

    struct NodeEntity {
        uint8 nodeType;
        uint16 periodStaking;
        address owner;
        uint256 id;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 startStaking;
    }

    struct User {
        uint256[] nodesIds;
        uint256[] nodesTypesAmount;
    }

    uint8 public malusPeriodStaking;
    uint8[] rewardPerDayPerType;
    uint8[] feesChancesMeeting;
    uint8[] feesAmountMeeting;
    uint8[] feesAmountKong;
    uint8[] boostAPR; // divide by 10
    uint256 public maxRewards;

    uint256 public stakingPeriod = 1 days;
    uint256 public totalNodesCreated;
    uint256[] totalNodesPerType = [0, 0, 0];

    mapping(address => User) nodesOf;
    mapping(uint256 => NodeEntity) public nodesById;

    event BoostAPRChanged(uint8[] boostAPR);
    event MaxRewardsChanged(uint256 maxRewards);
    event NodeCreated(address to, uint256 idNode);
    event StakingPeriodChanged(uint256 stakingPeriod);
    event FeesAmountKongChanged(uint8[] feesAmountKong);
    event MalusPeriodStakingChanged(uint8 malusPeriodStaking);
    event FeesAmountMeetingChanged(uint8[] feesAmountMeeting);
    event FeesChancesMeetingChanged(uint8[] feesChancesMeeting);
    event RewardPerDayPerTypeChanged(uint8[] rewardPerDayPerType);
    event NodeUpgraded(address to, uint256 idNode, uint8 nodeType);
    event NodeStaked(address from, uint256 idNode, uint16 periodStaking);

    error WrongWay();
    error NotStaked();
    error RewardZero();
    error NotOwnerNode();
    error AlreadyStaked();
    error NotEnoughTime();
    error LengthMismatch();
    error NodeDoesnotExist();
    error NotAllowedStakingPeriod();

    constructor(
        address _kong,
        uint8 _malusPeriodStaking,
        uint8[] memory _rewardPerDayPerType,
        uint8[] memory _feesChancesMeeting,
        uint8[] memory _feesAmountMeeting,
        uint8[] memory _feesAmountKong,
        uint8[] memory _boostAPR,
        uint256 _maxRewards
    ) {
        kong = IERC20(_kong);
        malusPeriodStaking = _malusPeriodStaking;
        rewardPerDayPerType = _rewardPerDayPerType;
        feesChancesMeeting = _feesChancesMeeting;
        feesAmountMeeting = _feesAmountMeeting;
        feesAmountKong = _feesAmountKong;
        boostAPR = _boostAPR;
        maxRewards = _maxRewards;
    }

    modifier onlyKong() {
        if (msg.sender != address(kong) && msg.sender != owner())
            revert WrongWay();
        _;
    }

    function _getRandom(
        uint256 _limit,
        uint256 _nonce
    ) private view returns (bool) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    totalNodesCreated,
                    _nonce
                )
            )
        ) % 100;
        return random < _limit;
    }

    function setToken(address _kong) external onlyOwner {
        kong = IERC20(_kong);
    }

    function setMalusPeriodStaking(
        uint8 _malusPeriodStaking
    ) external onlyOwner {
        malusPeriodStaking = _malusPeriodStaking;
        emit MalusPeriodStakingChanged(_malusPeriodStaking);
    }

    function setMaxRewards(uint256 _maxRewards) external onlyOwner {
        maxRewards = _maxRewards;
        emit MaxRewardsChanged(_maxRewards);
    }

    function setRewardPerDayPerType(
        uint8[] memory _rewardPerDayPerType
    ) external onlyOwner {
        if (_rewardPerDayPerType.length != 3) revert LengthMismatch();
        rewardPerDayPerType = _rewardPerDayPerType;
        emit RewardPerDayPerTypeChanged(_rewardPerDayPerType);
    }

    function setFeesChancesMeeting(
        uint8[] memory _feesChancesMeeting
    ) external onlyOwner {
        if (_feesChancesMeeting.length != 3) revert LengthMismatch();
        feesChancesMeeting = _feesChancesMeeting;
        emit FeesChancesMeetingChanged(_feesChancesMeeting);
    }

    function setFeesAmountMeeting(
        uint8[] memory _feesAmountMeeting
    ) external onlyOwner {
        if (_feesAmountMeeting.length != 3) revert LengthMismatch();
        feesAmountMeeting = _feesAmountMeeting;
        emit FeesAmountMeetingChanged(_feesAmountMeeting);
    }

    function setFeesAmountKong(
        uint8[] memory _feesAmountKong
    ) external onlyOwner {
        if (_feesAmountKong.length != 4) revert LengthMismatch();
        feesAmountKong = _feesAmountKong;
        emit FeesAmountKongChanged(_feesAmountKong);
    }

    function setBoostAPR(uint8[] memory _boostAPR) external onlyOwner {
        if (_boostAPR.length != 3) revert LengthMismatch();
        boostAPR = _boostAPR;
        emit BoostAPRChanged(_boostAPR);
    }

    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner {
        stakingPeriod = _stakingPeriod;
        emit StakingPeriodChanged(_stakingPeriod);
    }

    // BUY NODE & UPGRADE
    function buyNode(address _to, bool _stake) external onlyKong {
        User storage user = nodesOf[_to];
        uint8 period;
        uint256 start;

        if (_stake) {
            period = 5;
            start = block.timestamp;
        }

        uint256 idNode = totalNodesCreated;
        nodesById[idNode] = NodeEntity({
            nodeType: 1,
            periodStaking: period,
            owner: _to,
            id: idNode,
            creationTime: block.timestamp,
            lastClaimTime: 0,
            startStaking: start
        });
        if (user.nodesTypesAmount.length == 0) {
            user.nodesTypesAmount = [0, 0, 0];
        }
        user.nodesIds.push(idNode);
        user.nodesTypesAmount[0]++;
        totalNodesPerType[0]++;
        totalNodesCreated++;
        emit NodeCreated(_to, idNode);
    }

    function upgradeNode(address _to, uint256 _nodeId) external onlyKong {
        NodeEntity storage node = nodesById[_nodeId];
        uint8 actualNodeType = node.nodeType;
        User storage user = nodesOf[_to];

        node.nodeType++;
        node.creationTime = block.timestamp;
        user.nodesTypesAmount[actualNodeType - 1]--;
        totalNodesPerType[actualNodeType - 1]--;
        user.nodesTypesAmount[actualNodeType]++;
        totalNodesPerType[actualNodeType]++;
        emit NodeUpgraded(_to, _nodeId, actualNodeType + 1);
    }

    // STAKE & UNSTAKE
    function stake(
        uint256 _nodeId,
        address _from,
        uint16 _periodStaking
    ) external onlyKong {
        NodeEntity storage node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.startStaking > 0) revert AlreadyStaked();

        node.startStaking = block.timestamp;
        node.periodStaking = _periodStaking;
        emit NodeStaked(_from, _nodeId, _periodStaking);
    }

    function unstake(
        uint256 _nodeId,
        address _from
    ) external onlyKong returns (uint256[3] memory) {
        NodeEntity storage node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.startStaking == 0) revert NotStaked();

        uint256[3] memory rewards = getRewards(_nodeId, 0);
        if (rewards[0] == 0) revert RewardZero();
        node.lastClaimTime = block.timestamp;
        node.startStaking = 0;
        node.periodStaking = 0;
        return rewards;
    }

    // REWARDS
    function claimRewards(
        address _from,
        uint256 _nodeId
    ) external onlyKong returns (uint256[3] memory) {
        NodeEntity memory node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.periodStaking > 0) revert NotAllowedStakingPeriod();
        if (node.startStaking == 0) revert NotStaked();
        uint256[3] memory rewards = getRewards(_nodeId, 0);
        if (rewards[0] == 0) revert RewardZero();
        nodesById[_nodeId].lastClaimTime = block.timestamp;
        return rewards;
    }

    function claimAllRewards(
        address _from
    ) external onlyKong returns (uint256[3] memory) {
        uint256[3] memory totalRewards;
        uint256[] memory nodesIds = nodesOf[_from].nodesIds;

        for (uint256 i; i < nodesIds.length; ++i) {
            // To solve potential revert NotEnoughTime, NotStaked and NotAllowedStakingPeriod
            NodeEntity memory node = nodesById[nodesIds[i]];
            if (node.owner != _from) revert NotOwnerNode();
            uint256 startTime;
            if (node.startStaking > node.lastClaimTime) {
                startTime = node.startStaking;
            } else {
                startTime = node.lastClaimTime;
            }
            uint256 stakedPeriod = (block.timestamp - startTime) /
                stakingPeriod;

            if (
                stakedPeriod > 0 &&
                node.startStaking > 0 &&
                node.periodStaking == 0
            ) {
                uint256[3] memory rewards = getRewards(nodesIds[i], i);
                if (rewards[0] > 0) {
                    totalRewards[0] += rewards[0];
                    totalRewards[1] += rewards[1];
                    totalRewards[2] += rewards[2];
                    nodesById[nodesIds[i]].lastClaimTime = block.timestamp;
                }
            }
        }

        if (totalRewards[0] == 0) revert RewardZero();
        return totalRewards;
    }

    function getRewardsWithoutRandomFees(
        uint256 _nodeId
    ) public view returns (uint256, uint256) {
        NodeEntity memory node = nodesById[_nodeId];
        if (node.owner == address(0)) revert NodeDoesnotExist();
        if (node.startStaking == 0) revert NotStaked();

        uint8 percentageKongFees;
        uint256 kongFees;
        uint256 stakedPeriod;
        uint256 rewards;
        uint256 startTime;

        if (node.startStaking > node.lastClaimTime) {
            startTime = node.startStaking;
        } else {
            startTime = node.lastClaimTime;
        }

        stakedPeriod = (block.timestamp - startTime) / stakingPeriod;
        if (stakedPeriod < 1) revert NotEnoughTime();

        uint period = node.periodStaking;
        if (period > 0 && stakedPeriod > period) {
            stakedPeriod = period;
        }

        rewards = stakedPeriod * rewardPerDayPerType[node.nodeType - 1];

        // BoostAPR and MalusVesting
        if (period > 0) {
            if (stakedPeriod >= period) {
                rewards = (rewards * boostAPR[node.nodeType - 1]) / 10;
            } else {
                rewards -= (rewards * malusPeriodStaking) / 100;
            }
        } else {
            if (rewards > maxRewards) rewards = maxRewards;
        }

        // KongFees
        if (stakedPeriod == 1) {
            percentageKongFees = feesAmountKong[0];
        } else if (stakedPeriod == 2) {
            percentageKongFees = feesAmountKong[1];
        } else if (stakedPeriod == 3) {
            percentageKongFees = feesAmountKong[2];
        } else {
            percentageKongFees = feesAmountKong[3];
        }
        kongFees = (rewards * percentageKongFees) / 100;

        return (rewards, kongFees);
    }

    function getRewards(
        uint256 _nodeId,
        uint256 _nonce
    ) private view returns (uint256[3] memory) {
        uint8 percentageMeetingFees;
        uint256 rewards;
        uint256 kongFees;
        uint256 meetingFees;

        NodeEntity memory node = nodesById[_nodeId];

        (rewards, kongFees) = getRewardsWithoutRandomFees(_nodeId);

        // MeetingFees
        bool isMet = _getRandom(feesChancesMeeting[node.nodeType - 1], _nonce);
        if (isMet) {
            percentageMeetingFees = feesAmountMeeting[node.nodeType - 1];
            meetingFees = (rewards * percentageMeetingFees) / 100;
        }

        rewards -= meetingFees + kongFees;

        return [rewards, meetingFees, kongFees];
    }

    // NODES INFORMATIONS
    function getNodesDataOf(
        address account
    ) external view returns (uint256[] memory, uint256[] memory) {
        return (nodesOf[account].nodesIds, nodesOf[account].nodesTypesAmount);
    }

    function getAllNodesOf(
        address account
    ) external view returns (NodeEntity[] memory) {
        uint256[] memory nodesIds = nodesOf[account].nodesIds;
        uint256 numberOfNodes = nodesOf[account].nodesIds.length;
        NodeEntity[] memory nodes = new NodeEntity[](numberOfNodes);
        for (uint256 i; i < numberOfNodes; ++i) {
            nodes[i] = nodesById[nodesIds[i]];
        }
        return nodes;
    }

    function getRewardPerDayPerType() external view returns (uint8[] memory) {
        return rewardPerDayPerType;
    }

    function getTotalNodesPerType() external view returns (uint256[] memory) {
        return totalNodesPerType;
    }
}