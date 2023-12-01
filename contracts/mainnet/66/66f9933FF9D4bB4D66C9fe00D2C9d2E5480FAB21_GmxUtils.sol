// SPDX-License-Identifier: MIT

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
interface IERC165 {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IDataStore {
  function getUint(bytes32 key) external view returns (uint256);
  function getBool(bytes32 key) external view returns (bool);
  function getAddress(bytes32 key) external view returns (address);
  function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./StructData.sol";

interface IExchangeRouter {
  function sendWnt(address receiver, uint256 amount) external payable;
  function sendTokens(address token, address receiver, uint256 amount) external payable;
  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);
  function cancelOrder(bytes32 key) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "../../libraries/Order.sol";

struct EventLogData {
  AddressItems addressItems;
  UintItems uintItems;
  IntItems intItems;
  BoolItems boolItems;
  Bytes32Items bytes32Items;
  BytesItems bytesItems;
  StringItems stringItems;
}

struct AddressItems {
  AddressKeyValue[] items;
  AddressArrayKeyValue[] arrayItems;
}

struct UintItems {
  UintKeyValue[] items;
  UintArrayKeyValue[] arrayItems;
}

struct IntItems {
  IntKeyValue[] items;
  IntArrayKeyValue[] arrayItems;
}

struct BoolItems {
  BoolKeyValue[] items;
  BoolArrayKeyValue[] arrayItems;
}

struct Bytes32Items {
  Bytes32KeyValue[] items;
  Bytes32ArrayKeyValue[] arrayItems;
}

struct BytesItems {
  BytesKeyValue[] items;
  BytesArrayKeyValue[] arrayItems;
}

struct StringItems {
  StringKeyValue[] items;
  StringArrayKeyValue[] arrayItems;
}

struct AddressKeyValue {
  string key;
  address value;
}

struct AddressArrayKeyValue {
  string key;
  address[] value;
}

struct UintKeyValue {
  string key;
  uint256 value;
}

struct UintArrayKeyValue {
  string key;
  uint256[] value;
}

struct IntKeyValue {
  string key;
  int256 value;
}

struct IntArrayKeyValue {
  string key;
  int256[] value;
}

struct BoolKeyValue {
  string key;
  bool value;
}

struct BoolArrayKeyValue {
  string key;
  bool[] value;
}

struct Bytes32KeyValue {
  string key;
  bytes32 value;
}

struct Bytes32ArrayKeyValue {
  string key;
  bytes32[] value;
}

struct BytesKeyValue {
  string key;
  bytes value;
}

struct BytesArrayKeyValue {
  string key;
  bytes[] value;
}

struct StringKeyValue {
  string key;
  string value;
}

struct StringArrayKeyValue {
  string key;
  string[] value;
}

// @title IOrderCallbackReceiver
// @dev interface for an order callback contract
interface IOrderCallbackReceiver {
  // @dev called after an order execution
  // @param key the key of the order
  // @param order the order that was executed
  function afterOrderExecution(bytes32 key, Order.Props memory order, EventLogData memory eventData) external;

  // @dev called after an order cancellation
  // @param key the key of the order
  // @param order the order that was cancelled
  function afterOrderCancellation(bytes32 key, Order.Props memory order, EventLogData memory eventData) external;

  // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
  // @param key the key of the order
  // @param order the order that was frozen
  function afterOrderFrozen(bytes32 key, Order.Props memory order, EventLogData memory eventData) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IDataStore.sol";
import "./StructData.sol";
import "../../libraries/Position.sol";
import "../../libraries/Order.sol";

interface IReader {
  function getMarket(address dataStore, address key) external view returns (MarketProps memory);
  // function getMarkets(IDataStore dataStore, uint256 start, uint256 end) external view returns (MarketProps[] memory);
  function getPosition(address dataStore, bytes32 key) external view returns (Position.Props memory);
  function getAccountOrders(
    address dataStore,
    address account,
    uint256 start,
    uint256 end
  ) external view returns (Order.Props[] memory);
  function getPositionInfo(
    address dataStore,
    address referralStorage,
    bytes32 positionKey,
    MarketPrices memory prices,
    uint256 sizeDeltaUsd,
    address uiFeeReceiver,
    bool usePositionSizeAsSizeDeltaUsd
  ) external view returns (PositionInfo memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "../../libraries/Position.sol";
import "../../libraries/Order.sol";

struct MarketProps {
  address marketToken;
  address indexToken;
  address longToken;
  address shortToken;
}

struct PriceProps {
  uint256 min;
  uint256 max;
}

struct MarketPrices {
  PriceProps indexTokenPrice;
  PriceProps longTokenPrice;
  PriceProps shortTokenPrice;
}

struct PositionFees {
  PositionReferralFees referral;
  PositionFundingFees funding;
  PositionBorrowingFees borrowing;
  PositionUiFees ui;
  PriceProps collateralTokenPrice;
  uint256 positionFeeFactor;
  uint256 protocolFeeAmount;
  uint256 positionFeeReceiverFactor;
  uint256 feeReceiverAmount;
  uint256 feeAmountForPool;
  uint256 positionFeeAmountForPool;
  uint256 positionFeeAmount;
  uint256 totalCostAmountExcludingFunding;
  uint256 totalCostAmount;
}

// @param affiliate the referral affiliate of the trader
// @param traderDiscountAmount the discount amount for the trader
// @param affiliateRewardAmount the affiliate reward amount
struct PositionReferralFees {
  bytes32 referralCode;
  address affiliate;
  address trader;
  uint256 totalRebateFactor;
  uint256 traderDiscountFactor;
  uint256 totalRebateAmount;
  uint256 traderDiscountAmount;
  uint256 affiliateRewardAmount;
}

struct PositionBorrowingFees {
  uint256 borrowingFeeUsd;
  uint256 borrowingFeeAmount;
  uint256 borrowingFeeReceiverFactor;
  uint256 borrowingFeeAmountForFeeReceiver;
}

// @param fundingFeeAmount the position's funding fee amount
// @param claimableLongTokenAmount the negative funding fee in long token that is claimable
// @param claimableShortTokenAmount the negative funding fee in short token that is claimable
// @param latestLongTokenFundingAmountPerSize the latest long token funding
// amount per size for the market
// @param latestShortTokenFundingAmountPerSize the latest short token funding
// amount per size for the market
struct PositionFundingFees {
  uint256 fundingFeeAmount;
  uint256 claimableLongTokenAmount;
  uint256 claimableShortTokenAmount;
  uint256 latestFundingFeeAmountPerSize;
  uint256 latestLongTokenClaimableFundingAmountPerSize;
  uint256 latestShortTokenClaimableFundingAmountPerSize;
}

struct PositionUiFees {
  address uiFeeReceiver;
  uint256 uiFeeReceiverFactor;
  uint256 uiFeeAmount;
}

struct ExecutionPriceResult {
  int256 priceImpactUsd;
  uint256 priceImpactDiffUsd;
  uint256 executionPrice;
}

struct PositionInfo {
  Position.Props position;
  PositionFees fees;
  ExecutionPriceResult executionPriceResult;
  int256 basePnlUsd;
  int256 uncappedBasePnlUsd;
  int256 pnlAfterPriceImpactUsd;
}

// @param addresses address values
// @param numbers number values
// @param orderType for order.orderType
// @param decreasePositionSwapType for order.decreasePositionSwapType
// @param isLong for order.isLong
// @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
struct CreateOrderParams {
  CreateOrderParamsAddresses addresses;
  CreateOrderParamsNumbers numbers;
  Order.OrderType orderType;
  Order.DecreasePositionSwapType decreasePositionSwapType;
  bool isLong;
  bool shouldUnwrapNativeToken;
  bytes32 referralCode;
}

// @param receiver for order.receiver
// @param callbackContract for order.callbackContract
// @param market for order.market
// @param initialCollateralToken for order.initialCollateralToken
// @param swapPath for order.swapPath
struct CreateOrderParamsAddresses {
  address receiver;
  address callbackContract;
  address uiFeeReceiver;
  address market;
  address initialCollateralToken;
  address[] swapPath;
}

// @param sizeDeltaUsd for order.sizeDeltaUsd
// @param triggerPrice for order.triggerPrice
// @param acceptablePrice for order.acceptablePrice
// @param executionFee for order.executionFee
// @param callbackGasLimit for order.callbackGasLimit
// @param minOutputAmount for order.minOutputAmount
struct CreateOrderParamsNumbers {
  uint256 sizeDeltaUsd;
  uint256 initialCollateralDeltaAmount;
  uint256 triggerPrice;
  uint256 acceptablePrice;
  uint256 executionFee;
  uint256 callbackGasLimit;
  uint256 minOutputAmount;
}

enum PROTOCOL {
  UNISWAP,
  GMX
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "../interfaces/gmx/IReader.sol";
import "../interfaces/IManager.sol";

interface IGmxUtils {
  struct PositionData {
    uint256 sizeInUsd;
    uint256 sizeInTokens;
    uint256 collateralAmount;
    uint256 netValueInCollateralToken;
    bool isLong;
  }

  struct OrderData {
    address market;
    address indexToken;
    address initialCollateralToken;
    address[] swapPath;
    bool isLong;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 amountIn;
    uint256 callbackGasLimit;
  }

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }
  function getPositionInfo(bytes32 key, MarketPrices memory prices) external view returns (PositionData memory);
  function getPositionSizeInUsd(bytes32 key) external view returns (uint256 sizeInUsd);
  function getExecutionGasLimit(OrderType orderType, uint256 callbackGasLimit) external view returns (uint256 executionGasLimit);
  function tokenToUsdMin(address token, uint256 balance) external view returns (uint256);
  function usdToTokenAmount(address token, uint256 usd) external view returns (uint256);
  function setEnvVars(address perpVault, address manager) external;
  function createOrder(OrderType orderType, OrderData memory orderData, MarketPrices memory prices) external returns (bytes32);
  function createDecreaseOrder(bytes32 key, address market, bool isLong, uint256 sl, uint256 tp, uint256 callbackGaslimit, MarketPrices memory prices) external;
  function withdrawEth() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IManager is IERC721Enumerable {
  function vaultMap(uint256 vaultId) external view returns (address);
  function maxVaultsPerUser() external view returns (uint256);
  function keeperRegistry() external view returns (address);
  function perpVaults(address hypervisor) external view returns (address);
  function getTokenPrice(address token) external view returns (uint256);
  function treasury() external view returns (address);
  function getPath(address token0, address token1) external view returns (address, bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "./IGmxUtils.sol";
import "../libraries/Order.sol";

interface IPerpetualVault {
  function deposit(uint256 amount) external;
  function withdraw(address recipient, uint256 amount) external returns (bool);
  function shares(address account) external view returns (uint256);
  function lookback() external view returns (uint256);
  function name() external view returns (string memory);
  function indexToken() external view returns (address);
  function collateralToken() external view returns (address);
  function isLong() external view returns (bool);
  function isNextAction() external view returns (bool);
  function isLock() external view returns (bool);
  function isWithdrawing() external view returns (bool);
  function afterOrderExecution(bytes32 key, Order.OrderType, bool, bytes32) external;
  function afterOrderCancellation(bytes32 key, Order.OrderType, bool, bytes32) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Position.sol";
import "./Order.sol";
import "../interfaces/gmx/IDataStore.sol";
import "../interfaces/gmx/IReader.sol";
import "../interfaces/IManager.sol";
import "../interfaces/gmx/IOrderCallbackReceiver.sol";
import "../interfaces/IPerpetualVault.sol";
import "../interfaces/gmx/IExchangeRouter.sol";
import "../interfaces/IGmxUtils.sol";

/**
 * @title GMXUtils
 * @dev Contract for GMX Data Access
 */

contract GmxUtils is IOrderCallbackReceiver {
  using SafeERC20 for IERC20;
  using Position for Position.Props;

  struct PositionData {
    uint256 sizeInUsd;
    uint256 sizeInTokens;
    uint256 collateralAmount;
    uint256 netValueInCollateralToken;
    bool isLong;
  }

  bytes32 public constant COLLATERAL_TOKEN = keccak256(abi.encode("COLLATERAL_TOKEN"));

  bytes32 public constant SIZE_IN_USD = keccak256(abi.encode("SIZE_IN_USD"));
  bytes32 public constant SIZE_IN_TOKENS = keccak256(abi.encode("SIZE_IN_TOKENS"));
  bytes32 public constant COLLATERAL_AMOUNT = keccak256(abi.encode("COLLATERAL_AMOUNT"));
  bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
  bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));
  bytes32 public constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
  bytes32 public constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
  bytes32 public constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
  bytes32 public constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
  
  bytes32 public constant IS_LONG = keccak256(abi.encode("IS_LONG"));
  
  bytes32 public constant referralCode = bytes32(0);
  uint256 public constant PRECISION = 1e30;
  uint256 public constant BASIS_POINTS_DIVISOR = 10_000;

  address public constant orderHandler = address(0x352f684ab9e97a6321a13CF03A61316B681D9fD2);
  IExchangeRouter public constant gExchangeRouter = IExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
  IDataStore public constant dataStore = IDataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
  address public constant orderVault = address(0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5);
  IReader public constant reader = IReader(0xf60becbba223EEA9495Da3f606753867eC10d139);
  address public constant referralStorage = address(0xe6fab3F0c7199b0d34d7FbE83394fc0e0D06e99d);
  
  address public perpVault;
  IManager public manager;

  modifier onlyOwner() {
    require(perpVault == address(0) || msg.sender == perpVault, "!owner");
    _;
  }

  receive() external payable {}

  function getPositionInfo(
    bytes32 key,
    MarketPrices memory prices
  ) public view returns (PositionData memory) {
    PositionInfo memory positionInfo = reader.getPositionInfo(
      address(dataStore),
      referralStorage,
      key,
      prices,
      uint256(0),
      address(0),
      true
    );
    uint256 netValueInCollateralToken;    // need to consider positive funding fee. it's claimable amount
    if (positionInfo.pnlAfterPriceImpactUsd >= 0) {
      netValueInCollateralToken = positionInfo.position.numbers.collateralAmount + 
        uint256(positionInfo.pnlAfterPriceImpactUsd) / prices.shortTokenPrice.max
        - positionInfo.fees.borrowing.borrowingFeeUsd / prices.shortTokenPrice.max
        - positionInfo.fees.funding.fundingFeeAmount
        - positionInfo.fees.positionFeeAmount;
    } else {
      netValueInCollateralToken = positionInfo.position.numbers.collateralAmount - 
        (uint256(-positionInfo.pnlAfterPriceImpactUsd) + positionInfo.fees.borrowing.borrowingFeeUsd) / prices.shortTokenPrice.max
        - positionInfo.fees.funding.fundingFeeAmount
        - positionInfo.fees.positionFeeAmount;
    }

    return PositionData({
      sizeInUsd: positionInfo.position.numbers.sizeInUsd,
      sizeInTokens: positionInfo.position.numbers.sizeInTokens,
      collateralAmount: positionInfo.position.numbers.collateralAmount,
      netValueInCollateralToken: netValueInCollateralToken,
      isLong: positionInfo.position.flags.isLong
    });
  }

  function getPositionSizeInUsd(bytes32 key) external view returns (uint256 sizeInUsd) {
    sizeInUsd = dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_USD)));
  }

  function getExecutionGasLimit(Order.OrderType orderType, uint256 _callbackGasLimit) internal view returns (uint256 executionGasLimit) {
    uint256 baseGasLimit = dataStore.getUint(ESTIMATED_GAS_FEE_BASE_AMOUNT);
    uint256 multiplierFactor = dataStore.getUint(ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR);
    uint256 gasPerSwap = dataStore.getUint(SINGLE_SWAP_GAS_LIMIT);
    uint256 estimatedGasLimit;
    if (orderType == Order.OrderType.MarketIncrease) {
      estimatedGasLimit = dataStore.getUint(INCREASE_ORDER_GAS_LIMIT) + gasPerSwap;
    } else if (orderType == Order.OrderType.MarketDecrease) {
      estimatedGasLimit = dataStore.getUint(DECREASE_ORDER_GAS_LIMIT) + gasPerSwap;
    } else if (orderType == Order.OrderType.LimitDecrease) {
      estimatedGasLimit = dataStore.getUint(DECREASE_ORDER_GAS_LIMIT) + gasPerSwap;
    } else if (orderType == Order.OrderType.StopLossDecrease) {
      estimatedGasLimit = dataStore.getUint(DECREASE_ORDER_GAS_LIMIT) + gasPerSwap;
    } else if (orderType == Order.OrderType.MarketSwap) {
      estimatedGasLimit = dataStore.getUint(SWAP_ORDER_GAS_LIMIT) + gasPerSwap;
    }
    // multiply 1.2 (add some buffer) to ensure that the creation transaction does not revert.
    executionGasLimit = baseGasLimit + (estimatedGasLimit + _callbackGasLimit) * multiplierFactor / PRECISION;
  }

  function tokenToUsdMin(address token, uint256 balance) external view returns (uint256) {
    return manager.getTokenPrice(token) * balance;
  }

  function usdToTokenAmount(address token, uint256 usd) external view returns (uint256) {
    return usd / manager.getTokenPrice(token);
  }

  function afterOrderExecution(bytes32 key, Order.Props memory order, EventLogData memory /* eventData */) external override {
    require(msg.sender == address(orderHandler), "invalid caller");
    bytes32 positionKey = keccak256(abi.encode(address(this), order.addresses.market, order.addresses.initialCollateralToken, order.flags.isLong));
    IPerpetualVault(perpVault).afterOrderExecution(key, order.numbers.orderType, order.flags.isLong, positionKey);
  }

  function afterOrderCancellation(bytes32 key, Order.Props memory order, EventLogData memory /* eventData */) external override {
    require(msg.sender == address(orderHandler), "invalid caller");
    IPerpetualVault(perpVault).afterOrderCancellation(key, order.numbers.orderType, order.flags.isLong, bytes32(0));
  }

  function afterOrderFrozen(bytes32 key, Order.Props memory order, EventLogData memory /* eventData */) external override {}

  function setEnvVars(address _perpVault, address _manager) external onlyOwner {
    perpVault = _perpVault;
    manager = IManager(_manager);
  }

  function createOrder(
    Order.OrderType orderType,
    IGmxUtils.OrderData memory orderData,
    MarketPrices memory prices
  ) external returns (bytes32) {
    uint256 positionExecutionFee = getExecutionGasLimit(orderType, orderData.callbackGasLimit) * tx.gasprice;
    require(address(this).balance >= positionExecutionFee, "insufficient eth balance");
    gExchangeRouter.sendWnt{value: positionExecutionFee}(orderVault, positionExecutionFee);
    if (
      orderType == Order.OrderType.MarketSwap ||
      orderType == Order.OrderType.MarketIncrease
    ) {
      IERC20(orderData.initialCollateralToken).safeApprove(address(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6), orderData.amountIn);
      gExchangeRouter.sendTokens(orderData.initialCollateralToken, orderVault, orderData.amountIn);
    }
    CreateOrderParamsAddresses memory paramsAddresses = CreateOrderParamsAddresses({
      receiver: address(this),
      callbackContract: address(this),
      uiFeeReceiver: address(0),
      market: orderData.market,
      initialCollateralToken: orderData.initialCollateralToken,
      swapPath: orderData.swapPath
    });
    uint256 acceptablePrice;
    if (orderType != Order.OrderType.MarketSwap) {
      if (orderData.isLong) {
        acceptablePrice = prices.indexTokenPrice.min * (BASIS_POINTS_DIVISOR - 30) / BASIS_POINTS_DIVISOR;   // apply 0.3% offset
      } else {
        acceptablePrice = prices.indexTokenPrice.max * (BASIS_POINTS_DIVISOR + 30) / BASIS_POINTS_DIVISOR;   // apply 0.3% offset
      }
    }

    CreateOrderParamsNumbers memory paramsNumber = CreateOrderParamsNumbers({
      sizeDeltaUsd: orderData.sizeDeltaUsd,
      initialCollateralDeltaAmount: orderData.initialCollateralDeltaAmount,
      triggerPrice: 0,      // this param is an opening trigger price. not closing trigger price
      acceptablePrice: acceptablePrice,
      executionFee: positionExecutionFee,
      callbackGasLimit: orderData.callbackGasLimit,
      minOutputAmount: 0      // this param is used when swapping. is not used in opening position even though swap involved.
    });
    CreateOrderParams memory params = CreateOrderParams({
      addresses: paramsAddresses,
      numbers: paramsNumber,
      orderType: orderType,
      decreasePositionSwapType: Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
      isLong: orderData.isLong,
      shouldUnwrapNativeToken: false,
      referralCode: referralCode
    });
    bytes32 requestKey = gExchangeRouter.createOrder(params);
    return requestKey;
  }

  function createDecreaseOrder(
    bytes32 key,
    address market,
    bool isLong,
    uint256 sl,
    uint256 tp,
    uint256 callbackGasLimit,
    MarketPrices memory prices
  ) external {
    MarketProps memory marketInfo = reader.getMarket(address(dataStore), market);
    PositionData memory positionData = getPositionInfo(key, prices);

    uint256 acceptablePrice = isLong ?
      prices.indexTokenPrice.min * (BASIS_POINTS_DIVISOR - 30) / BASIS_POINTS_DIVISOR :
      prices.indexTokenPrice.max * (BASIS_POINTS_DIVISOR + 30) / BASIS_POINTS_DIVISOR;
    
    address[] memory swapPath;
    CreateOrderParamsAddresses memory paramsAddresses = CreateOrderParamsAddresses({
      receiver: address(this),
      callbackContract: address(this),
      uiFeeReceiver: address(0),
      market: market,
      initialCollateralToken: marketInfo.shortToken,
      swapPath: swapPath
    });
    uint256 positionExecutionFee = getExecutionGasLimit(Order.OrderType.LimitDecrease, callbackGasLimit) * tx.gasprice;
    require(address(this).balance >= positionExecutionFee, "too low execution fee");
    gExchangeRouter.sendWnt{value: positionExecutionFee}(orderVault, positionExecutionFee);
    CreateOrderParamsNumbers memory paramsNumber = CreateOrderParamsNumbers({
      sizeDeltaUsd: positionData.sizeInUsd,
      initialCollateralDeltaAmount: positionData.collateralAmount,
      triggerPrice: tp,      // this param is an opening trigger price. not closing trigger price
      acceptablePrice: acceptablePrice,
      executionFee: positionExecutionFee,
      callbackGasLimit: callbackGasLimit,
      minOutputAmount: 0      // this param is used when swapping. is not used in opening position even though swap involved.
    });
    CreateOrderParams memory params = CreateOrderParams({
      addresses: paramsAddresses,
      numbers: paramsNumber,
      orderType: Order.OrderType.LimitDecrease,
      decreasePositionSwapType: Order.DecreasePositionSwapType.NoSwap,
      isLong: isLong,
      shouldUnwrapNativeToken: false,
      referralCode: referralCode
    });
    gExchangeRouter.createOrder(params);

    positionExecutionFee = getExecutionGasLimit(Order.OrderType.StopLossDecrease, callbackGasLimit) * tx.gasprice;
    require(address(this).balance >= positionExecutionFee, "too low execution fee");
    gExchangeRouter.sendWnt{value: positionExecutionFee}(orderVault, positionExecutionFee);
    paramsNumber = CreateOrderParamsNumbers({
      sizeDeltaUsd: positionData.sizeInUsd,
      initialCollateralDeltaAmount: positionData.collateralAmount,
      triggerPrice: sl,      // this param is an opening trigger price. not closing trigger price
      acceptablePrice: acceptablePrice,
      executionFee: positionExecutionFee,
      callbackGasLimit: callbackGasLimit,
      minOutputAmount: 0      // this param is used when swapping. is not used in opening position even though swap involved.
    });

    params = CreateOrderParams({
      addresses: paramsAddresses,
      numbers: paramsNumber,
      orderType: Order.OrderType.StopLossDecrease,
      decreasePositionSwapType: Order.DecreasePositionSwapType.NoSwap,
      isLong: isLong,
      shouldUnwrapNativeToken: false,
      referralCode: referralCode
    });
    gExchangeRouter.createOrder(params);
  }

  function withdrawEth() external onlyOwner returns (uint256) {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    return balance;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// @title Order
// @dev Struct for orders
library Order {
  using Order for Props;

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
  struct Numbers {
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
    uint256 updatedAtBlock;
  }

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// @title Position
// @dev Stuct for positions
//
// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the position's account
  // @param market the position's market
  // @param collateralToken the position's collateralToken
  struct Addresses {
    address account;
    address market;
    address collateralToken;
  }

  // @param sizeInUsd the position's size in USD
  // @param sizeInTokens the position's size in tokens
  // @param collateralAmount the amount of collateralToken for collateral
  // @param borrowingFactor the position's borrowing factor
  // @param fundingFeeAmountPerSize the position's funding fee per size
  // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
  // for the market.longToken
  // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
  // for the market.shortToken
  // @param increasedAtBlock the block at which the position was last increased
  // @param decreasedAtBlock the block at which the position was last decreased
  struct Numbers {
    uint256 sizeInUsd;
    uint256 sizeInTokens;
    uint256 collateralAmount;
    uint256 borrowingFactor;
    uint256 fundingFeeAmountPerSize;
    uint256 longTokenClaimableFundingAmountPerSize;
    uint256 shortTokenClaimableFundingAmountPerSize;
    uint256 increasedAtBlock;
    uint256 decreasedAtBlock;
  }

  // @param isLong whether the position is a long or short
  struct Flags {
    bool isLong;
  }
}