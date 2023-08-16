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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmingPoolV2 is Ownable {
    using SafeERC20 for IERC20;

    struct Reward {
        uint256 virtualRewards;
        uint256 claimed;
        uint256 tokensPerDay;
        uint256 lockedRate;
        uint256 startTime;
        uint256 oldRate;
        uint256 lockedPeriod;
        uint256 nextReward;
    }

    struct Stake {
        uint256 rate;
        uint256 unclaimed;
        uint256 lockedUnstaked;
    }

    address[] public assets;
    uint256 public totalLp;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public lastUnstake;
    mapping(address => uint256) public userLocked;
    mapping(address => uint256) public userTotalStaked;
    mapping(address => Reward) public assetToReward;
    uint256 public totalLocked;
    uint256 public totalWithdraw;
    uint256 public updateTime;
    uint256 public protocolStartTime;
    IERC20 public immutable stakingAsset;
    uint256 public immutable claimPeriod;
    mapping(address => mapping(address => Stake)) public userStakes;
    uint256 public constant MULTIPLICATOR = 10 ** 30;

    constructor(
        IERC20 _stakingAsset,
        uint256 _startTime,
        uint256 _claimPeriod,
        uint256 _lockedPeriod,
        address[] memory _assets,
        uint256[] memory _tokensPerDay
    ) {
        uint256 length = _assets.length;
        require(length == _tokensPerDay.length, "Wrong arguments");

        assets = _assets;
        claimPeriod = _claimPeriod;

        for (uint i; i < length;) {
            assetToReward[_assets[i]] = Reward({
            virtualRewards : 0,
            tokensPerDay : _tokensPerDay[i],
            claimed : 0,
            lockedRate : 0,
            startTime : _startTime,
            lockedPeriod : _lockedPeriod,
            oldRate : 0,
            nextReward : 0
            });
        unchecked {
            ++i;
        }
        }

        protocolStartTime = _startTime;
        updateTime = block.timestamp;
        stakingAsset = _stakingAsset;
    }

    modifier updateState() {
        uint256 prevCycle = getGlobalCycleTime();
        uint256 length = assets.length;

        if (updateTime < prevCycle) {
            for (uint i; i < length;) {
                Reward storage rewardAsset = assetToReward[assets[i]];
                uint256 claimed = rewardAsset.claimed +
                (rewardAsset.lockedRate * totalWithdraw) /
                MULTIPLICATOR;
                rewardAsset.virtualRewards +=
                (rewardAsset.lockedRate * totalLocked) /
                MULTIPLICATOR;

                if (rewardAsset.virtualRewards >= claimed) {
                    rewardAsset.virtualRewards -= claimed;
                    rewardAsset.claimed = 0;
                } else {
                    rewardAsset.claimed = claimed;
                }

            unchecked {
                i++;
            }
            }

            totalLp = totalLp + totalLocked - totalWithdraw;
            totalLocked = 0;
            totalWithdraw = 0;

            for (uint i; i < length;) {
                Reward storage rewardAsset = assetToReward[assets[i]];

                if (rewardAsset.nextReward != 0) {
                    uint256 updatedCycle = getCycleTime(rewardAsset, updateTime, true);
                    uint256 updatedRate = getRateForDate(rewardAsset, updatedCycle);

                    rewardAsset.oldRate = updatedRate;
                    rewardAsset.startTime = updatedCycle;
                    rewardAsset.lockedPeriod = 0;
                    rewardAsset.tokensPerDay = rewardAsset.nextReward;
                    rewardAsset.virtualRewards = 0;
                    rewardAsset.claimed = 0;
                    rewardAsset.nextReward = 0;
                }

                uint256 nextCycle = getCycleTime(rewardAsset, block.timestamp, true);
                uint256 nextRate = getRateForDate(rewardAsset, nextCycle);
                rewardAsset.lockedRate = nextRate;

            unchecked {
                i++;
            }
            }
        }
        updateTime = block.timestamp;
        _;
    }

    function changeRewards(address _asset, uint256 _tokensPerDay) external onlyOwner updateState {
        assetToReward[_asset].nextReward = _tokensPerDay;
    }

    function addRewardAsset(address _asset, uint256 _tokensPerDay, uint256 _lockedPeriod, uint256 _startTime) external onlyOwner {
        uint256 length = assets.length;

        for (uint i = 0; i < length;) {
            require(assets[i] != _asset, "Asset already exists");

        unchecked {
            ++i;
        }
        }

        assets.push(_asset);

        assetToReward[_asset] = Reward({
        virtualRewards : 0,
        tokensPerDay : _tokensPerDay,
        claimed : 0,
        startTime : _startTime,
        lockedPeriod : _lockedPeriod,
        oldRate : assetToReward[_asset].oldRate,
        lockedRate : _lockedPeriod,
        nextReward : 0
        });
    }


    function removeAsset(address _asset) external onlyOwner updateState {
        uint256 length = assets.length;

        for (uint i = 0; i < length;) {
            if (_asset == assets[i]) {
                Reward memory rewardAsset = assetToReward[_asset];
                uint256 nextCycle = getCycleTime(rewardAsset, block.timestamp, true);
                uint256 nextRate = getRateForDate(rewardAsset, nextCycle);
                assetToReward[_asset].oldRate = nextRate;

                assets[i] = assets[length - 1];
                assets.pop();
                break;
            }

        unchecked {
            ++i;
        }
        }
    }

    function stakeTokens(uint256 amount) external updateState {
        require(amount > 0, "Amount must be greater than 0");

        uint256 stakedAmount = userTotalStaked[msg.sender];
        uint256 newStakedAmount = stakedAmount + amount;
        uint256 length = assets.length;

        for (uint i; i < length;) {
            address asset = assets[i];
            Reward memory rewardAsset = assetToReward[asset];

            uint256 nextCycle = getCycleTime(rewardAsset, block.timestamp, true);
            uint256 prevCycle = getCycleTime(rewardAsset, block.timestamp, false);

            uint256 nextRate = getRateForDate(rewardAsset, nextCycle);
            uint256 prevRate = getRateForDate(rewardAsset, prevCycle);

            Stake storage stake = userStakes[asset][msg.sender];

            if (stake.rate < prevRate) {
                // if rate lower than prev rate, then user has earned some reward and we need to save it,
                //than calculate new rate using previous rate to not lose rewards from current cycle
                stake.unclaimed += (stakedAmount * (prevRate - stake.rate)) / MULTIPLICATOR;
                stake.rate =
                nextRate - ((nextRate - prevRate) * stakedAmount /
                newStakedAmount);
            } else {
                // increasing rate to save rewards from previous cycles
                stake.rate =
                nextRate -
                ((nextRate - stake.rate) * stakedAmount /
                newStakedAmount);
            }

        unchecked {
            i++;
        }
        }

        totalLocked += amount;
        userTotalStaked[msg.sender] = newStakedAmount;
        stakingAsset.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstakeRequest(uint256 amount) external updateState {
        require(amount > 0, "Invalid amount");

        uint256 totalStaked = userTotalStaked[msg.sender];
        require(amount <= totalStaked, "Invalid balance");

        uint256 length = assets.length;

        for (uint i; i < length;) {
            address asset = assets[i];
            Reward memory rewardAsset = assetToReward[asset];
            uint256 nextCycle = getCycleTime(rewardAsset, block.timestamp, true);
            uint256 nextRate = getRateForDate(rewardAsset, nextCycle);

            Stake storage stake = userStakes[asset][msg.sender];
            stake.lockedUnstaked +=
            (amount * (nextRate - stake.rate)) /
            MULTIPLICATOR;

        unchecked {
            i++;
        }
        }

        uint256 prevCycle = getGlobalCycleTime();

        if(prevCycle > lastUnstake[msg.sender]) {
            stakingAsset.safeTransfer(msg.sender, userLocked[msg.sender]);
            userLocked[msg.sender] = 0;
        }

        userTotalStaked[msg.sender] -= amount;
        totalWithdraw += amount;
        userLocked[msg.sender] += amount;
        lastUnstake[msg.sender] = block.timestamp;
    }

    function confirmUnstake() external {
        uint256 prevCycle = getGlobalCycleTime();

        require(
            prevCycle > lastUnstake[msg.sender],
            "Cycle hasn't finished yet"
        );

        stakingAsset.safeTransfer(msg.sender, userLocked[msg.sender]);
        userLocked[msg.sender] = 0;
    }

    function claim() external updateState {
        uint256 totalStaked = userTotalStaked[msg.sender];
        uint256 length = assets.length;
        uint256 claimCycle = getClaimCycleTime();

        require(
            lastClaim[msg.sender] < claimCycle,
            "Claim isn't available yet"
        );

        lastClaim[msg.sender] = claimCycle;

        for (uint i; i < length;) {
            address asset = assets[i];
            Stake storage stake = userStakes[asset][msg.sender];
            Reward memory rewardAsset = assetToReward[asset];
            uint256 prevCycle = getCycleTime(rewardAsset, block.timestamp, false);
            uint256 prevRate = getRateForDate(rewardAsset, prevCycle);
            uint256 reward = stake.unclaimed;

            if (prevCycle > lastUnstake[msg.sender]) {
                reward += stake.lockedUnstaked;
                stake.lockedUnstaked = 0;
            }

            if (prevRate > stake.rate) {
                reward += totalStaked * (prevRate - stake.rate) / MULTIPLICATOR;
                stake.rate = prevRate;
            }

            stake.unclaimed = 0;
            IERC20(asset).safeTransfer(msg.sender, reward);

        unchecked {
            i++;
        }
        }
    }

    function availableToClaim(
        address asset,
        address user
    ) external view returns (uint256) {
        Reward memory rewardAsset = assetToReward[asset];
        uint256 prevCycle = getCycleTime(rewardAsset, block.timestamp, false);

        uint256 rate = getUpdatedRateForDate(rewardAsset, prevCycle);
        Stake memory stake = userStakes[asset][user];
        uint256 reward = stake.unclaimed;

        if (prevCycle > lastUnstake[msg.sender]) {
            reward += stake.lockedUnstaked;
        }

        if (rate <= stake.rate) {
            return reward;
        }

        return
        reward +
        (userTotalStaked[user] * (rate - stake.rate)) /
        MULTIPLICATOR;
    }

    function availableToUnstake(address user) external view returns (uint256 amount) {
        uint256 prevCycle = getGlobalCycleTime();

        if(prevCycle > lastUnstake[user]) {
            amount = userLocked[msg.sender];
        }
    }

    function getRewardAssets() external view returns (address[] memory) {
        return assets;
    }

    function getClaimCycleTime() public view returns (uint256) {
        uint256 currentCycle = (block.timestamp - protocolStartTime) / claimPeriod;

        return protocolStartTime + claimPeriod * (currentCycle + 1);
    }

    function getCycleTime(
        Reward memory rewardAsset,
        uint256 timestamp,
        bool next
    ) public pure returns (uint256) {
        uint256 totalTime = (timestamp - rewardAsset.startTime);

        if (totalTime > rewardAsset.lockedPeriod) {
            uint256 currentCycle = (totalTime - rewardAsset.lockedPeriod) / 1 days;
            return
            rewardAsset.startTime +
            rewardAsset.lockedPeriod +
            (currentCycle + (next ? 1 : 0)) *
            1 days;
        }

        return rewardAsset.startTime + rewardAsset.lockedPeriod;
    }

    function getGlobalCycleTime() public view returns (uint256) {
        uint256 totalTime = (block.timestamp - protocolStartTime);
        uint256 currentCycle = totalTime / 1 days;

        return protocolStartTime + currentCycle * 1 days;
    }

    function getRateForDate(
        Reward memory rewardAsset,
        uint256 time
    ) public view returns (uint256) {
        uint256 totalTime = (time - rewardAsset.startTime);

        if (totalTime <= rewardAsset.lockedPeriod) {
            return rewardAsset.oldRate;
        }

        uint256 totalDays = (totalTime - rewardAsset.lockedPeriod) / 1 days;

        return rewardAsset.oldRate + (MULTIPLICATOR *
        (rewardAsset.virtualRewards +
        totalDays *
        rewardAsset.tokensPerDay -
        rewardAsset.claimed)) / totalLp;
    }

    function getUpdatedRateForDate(
        Reward memory rewardAsset,
        uint256 prevCycle
    ) public view returns (uint256) {
        uint256 rewards = rewardAsset.virtualRewards;
        uint256 claimed = rewardAsset.claimed;
        uint256 amountLp = totalLp;

        if (updateTime < prevCycle) {
            rewards += (rewardAsset.lockedRate * totalLocked) / MULTIPLICATOR;
            claimed += (rewardAsset.lockedRate * totalWithdraw) / MULTIPLICATOR;
            amountLp = amountLp + totalLocked - totalWithdraw;

            if (rewardAsset.nextReward != 0) {
                uint256 updatedCycle = getCycleTime(rewardAsset, updateTime, true);
                uint256 updatedRate = getRateForDate(rewardAsset, updatedCycle);

                rewardAsset.oldRate = updatedRate;
                rewardAsset.startTime = updatedCycle;
                rewardAsset.lockedPeriod = 0;
                rewardAsset.tokensPerDay = rewardAsset.nextReward;
                rewards = 0;
                claimed = 0;
            }
        }

        uint256 totalTime = (prevCycle - rewardAsset.startTime);

        if (totalTime <= rewardAsset.lockedPeriod) {
            return rewardAsset.oldRate;
        }

        uint256 totalDays = (totalTime - rewardAsset.lockedPeriod) / 1 days;

        return
        rewardAsset.oldRate + (MULTIPLICATOR *
        (rewards +
        totalDays *
        rewardAsset.tokensPerDay -
        claimed)) / amountLp;
    }
}