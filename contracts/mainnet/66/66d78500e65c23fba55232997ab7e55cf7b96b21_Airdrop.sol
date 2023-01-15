// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/erc20/IFrabricERC20.sol";
import "../interfaces/unsafe/IAirdrop.sol";

contract Airdrop is IAirdrop {
    using SafeERC20 for IFrabricERC20;
    uint64 public expiryDate;
    address public token;

    mapping(address => uint256) private _claims;
    constructor(uint8 daysUntilExpiry, address erc20, address [] memory claimants, uint256 [] memory amounts){
        expiryDate = uint64(block.timestamp) + (daysUntilExpiry * 1 days);
        token = erc20;
        if (claimants.length != amounts.length) {
            revert DifferentLengths(claimants.length, amounts.length);
        }

        for (uint64 i = 0; i < claimants.length; i++) {
            _claims[claimants[i]] = amounts[i];
        }
    }


    /*
    * @dev Claim your tokens from the airdrop.
    * @notice This function will revert if the airdrop has expired, or if the claimant has already claimed.
    * @notice This function will send only the available tokens to the recipient if the airdrop contract does not have enough tokens to fulfill the claim.
    */

    function claim() external {
        if (block.timestamp > expiryDate) {
            revert Expired();
        }
        uint256 claim = _claims[msg.sender];
        if (claim == 0) {
            revert AlreadyClaimed(msg.sender);
        }
        _claims[msg.sender] = 0;
        uint256 finalAmount = _claims[msg.sender] > IFrabricERC20(token).balanceOf(address(this)) ? IFrabricERC20(token).balanceOf(address(this)) : claim;
        IFrabricERC20(token).safeTransfer(msg.sender, finalAmount);
        emit ClaimRedeemed(finalAmount, msg.sender);
    }

    /**
     * @dev Burns all remaining tokens in the contract.
     * This function can be called by anyone after the expiry date.
     */

    function expire() external {
        if (block.timestamp <= expiryDate) {
            revert StillActive();
        }
        uint256 balance = IFrabricERC20(token).balanceOf(address(this));
        IFrabricERC20(token).burn(balance);
        emit BurnedTokens(balance);
    }

    /**
    * @dev Returns the amount of tokens that a claimant can claim.
    * @param claimant The address of the claimant.
    * @return The amount of tokens that the claimant can claim.
    */

    function viewClaim(address claimant) external view returns (uint256) {
        if (block.timestamp > expiryDate) {
            return 0;
        } else {
            return (_claims[claimant]);
        }
    }

}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

interface IAirdrop {
    event ClaimRedeemed(uint256 amount, address claimant);
    event BurnedTokens(uint256 amount);

    function claim() external;

    function viewClaim(address claimant) external view returns (uint256);

    function expire() external;

    error Expired();
    error StillActive();
    error AlreadyClaimed(address claimant);
    error DifferentLengths(uint256 lengthA, uint256 lengthB);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "./IDistributionERC20.sol";
import "./IFrabricWhitelist.sol";
import "./IIntegratedLimitOrderDEX.sol";

interface IRemovalFee {
  function removalFee(address person) external view returns (uint8);
}

interface IFreeze {
  event Freeze(address indexed person, uint64 until);

  function frozenUntil(address person) external view returns (uint64);
  function frozen(address person) external returns (bool);

  function freeze(address person, uint64 until) external;
  function triggerFreeze(address person) external;
}

interface IFrabricERC20 is IDistributionERC20, IFrabricWhitelist, IRemovalFee, IFreeze, IIntegratedLimitOrderDEX {
  event Removal(address indexed person, uint256 balance);

  function auction() external view returns (address);

  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;

  function remove(address participant, uint8 fee) external;
  function triggerRemoval(address person) external;

  function paused() external view returns (bool);
  function pause() external;
}

interface IFrabricERC20Initializable is IFrabricERC20 {
  function initialize(
    string memory name,
    string memory symbol,
    uint256 supply,
    address parent,
    address tradeToken,
    address auction
  ) external;
}

error SupplyExceedsInt112(uint256 supply, int112 max);
error Frozen(address person);
error NothingToRemove(address person);
// Not Paused due to an overlap with the event
error CurrentlyPaused();
error Locked(address person, uint256 balanceAfterTransfer, uint256 lockedBalance);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IFrabricWhitelistCore is IComposable {
  event Whitelisted(address indexed person, bool indexed whitelisted);

  // The ordinal value of the enum increases with accreditation
  enum Status {
    Null,
    Removed,
    Whitelisted,
    KYC
  }

  function parent() external view returns (address);

  function setParent(address parent) external;
  function whitelist(address person) external;
  function setKYC(address person, bytes32 hash, uint256 nonce) external;

  function whitelisted(address person) external view returns (bool);
  function hasKYC(address person) external view returns (bool);
  function removed(address person) external view returns (bool);
  function status(address person) external view returns (Status);
}

interface IFrabricWhitelist is IFrabricWhitelistCore {
  event ParentChange(address oldParent, address newParent);
  // Info shouldn't be indexed when you consider it's unique per-person
  // Indexing it does allow retrieving the address of a person by their KYC however
  // It's also just 750 gas on an infrequent operation
  event KYCUpdate(address indexed person, bytes32 indexed oldInfo, bytes32 indexed newInfo, uint256 nonce);
  event GlobalAcceptance();

  function global() external view returns (bool);

  function kyc(address person) external view returns (bytes32);
  function kycNonces(address person) external view returns (uint256);
  function explicitlyWhitelisted(address person) external view returns (bool);
  function removedAt(address person) external view returns (uint256);
}

error AlreadyWhitelisted(address person);
error Removed(address person);
error NotWhitelisted(address person);
error NotRemoved(address person);
error NotKYC(address person);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IDistributionERC20 is IVotesUpgradeable, IERC20, IComposable {
  event Distribution(uint256 indexed id, address indexed token, uint112 amount);
  event Claim(uint256 indexed id, address indexed person, uint112 amount);

  function claimed(uint256 id, address person) external view returns (bool);

  function distribute(address token, uint112 amount) external returns (uint256 id);
  function claim(uint256 id, address person) external;
}

error Delegation();
error FeeOnTransfer(address token);
error AlreadyClaimed(uint256 id, address person);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IIntegratedLimitOrderDEXCore {
  enum OrderType { Null, Buy, Sell }

  event Order(OrderType indexed orderType, uint256 indexed price);
  event OrderIncrease(address indexed trader, uint256 indexed price, uint256 amount);
  event OrderFill(address indexed orderer, uint256 indexed price, address indexed executor, uint256 amount);
  event OrderCancelling(address indexed trader, uint256 indexed price);
  event OrderCancellation(address indexed trader, uint256 indexed price, uint256 amount);

  // Part of core to symbolize amount should always be whole while price is atomic
  function atomic(uint256 amount) external view returns (uint256);

  function tradeToken() external view returns (address);

  // sell is here as the FrabricDAO has the ability to sell tokens on their integrated DEX
  // That means this function API can't change (along with cancelOrder which FrabricDAO also uses)
  // buy is meant to be used by users, offering greater flexibility, especially as it has a router for a frontend
  function sell(uint256 price, uint256 amount) external returns (uint256);
  function cancelOrder(uint256 price, uint256 i) external returns (bool);
}

interface IIntegratedLimitOrderDEX is IComposable, IIntegratedLimitOrderDEXCore {
  function tradeTokenBalance() external view returns (uint256);
  function tradeTokenBalances(address trader) external view returns (uint256);
  function locked(address trader) external view returns (uint256);

  function withdrawTradeToken(address trader) external;

  function buy(
    address trader,
    uint256 price,
    uint256 minimumAmount
  ) external returns (uint256);

  function pointType(uint256 price) external view returns (IIntegratedLimitOrderDEXCore.OrderType);
  function orderQuantity(uint256 price) external view returns (uint256);
  function orderTrader(uint256 price, uint256 i) external view returns (address);
  function orderAmount(uint256 price, uint256 i) external view returns (uint256);
}

error LessThanMinimumAmount(uint256 amount, uint256 minimumAmount);
error NotEnoughFunds(uint256 required, uint256 balance);
error NotOrderTrader(address caller, address trader);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IComposable is IERC165Upgradeable {
  function contractName() external returns (bytes32);
  // Returns uint256 max if not upgradeable
  function version() external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

error UnhandledEnumCase(string label, uint256 enumValue);

error ZeroPrice();
error ZeroAmount();

error UnsupportedInterface(address contractAddress, bytes4 interfaceID);

error ExternalCallFailed(address called, bytes4 selector, bytes error);

error Unauthorized(address caller, address user);
error Replay(uint256 nonce, uint256 expected);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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