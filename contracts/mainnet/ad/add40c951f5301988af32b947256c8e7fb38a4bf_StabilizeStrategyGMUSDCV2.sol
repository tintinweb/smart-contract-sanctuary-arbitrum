/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function onlyGovernance() internal view {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual {
        onlyGovernance();
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

// File: contracts/strategies/StabilizeStrategyGMUSDCV2.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

// This is an index strategy for a basket of GM tokens offered by GMX v2. Markets that yield the highest return are selected as desirable for deposits

interface StabilizeBank{
    function depositSTBZ(address _credit, uint256 amount) external;
}

interface SushiLikeRouter {
    function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory); // For a value in, it calculates value out
}

interface UniswapV3Router{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(UniswapV3Router.ExactInputSingleParams calldata params) external returns (uint256 amountOut);
    function quoteExactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint160 sqrtPriceLimitX96) external returns (uint256 amountOut);
    function quoteExactOutputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint160 sqrtPriceLimitX96) external returns (uint256 amountIn);
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface zsToken {
    function getCurrentStrategy() external view returns (address); 
    function finalizeRedeem(address _user) external;
    function cancelRedeem(address _user) external;
}

interface ChainLinkOracle{
    function latestAnswer() external view returns (int256);
}

interface GMXReader {
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
    struct MarketPoolValueInfoProps {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;

        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;

        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;

        uint256 impactPoolAmount;
    }
    struct MarketPrices {
        GMXReader.PriceProps indexTokenPrice;
        GMXReader.PriceProps longTokenPrice;
        GMXReader.PriceProps shortTokenPrice;
    }
    function getMarketTokenPrice(
        address dataStore,
        GMXReader.MarketProps calldata market,
        GMXReader.PriceProps calldata indexTokenPrice,
        GMXReader.PriceProps calldata longTokenPrice,
        GMXReader.PriceProps calldata shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, GMXReader.MarketPoolValueInfoProps memory);
    function getWithdrawalAmountOut(
        address dataStore,
        GMXReader.MarketProps calldata market,
        GMXReader.MarketPrices calldata prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
    function getMarket(address dataStore, address gmAddress) external view returns (GMXReader.MarketProps memory);
}

interface GMXRouter{
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }
    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }
    function dataStore() external view returns (address);
    function depositHandler() external view returns (address);
    function withdrawalHandler() external view returns (address);
    function createDeposit(
        GMXRouter.CreateDepositParams calldata params
    ) external payable returns (bytes32); // Returns unique key for deposit
    function createWithdrawal(
        GMXRouter.CreateWithdrawalParams calldata params
    ) external payable returns (bytes32); // Returns unique key for deposit
    function cancelDeposit(bytes32 key) external payable;
    function cancelWithdrawal(bytes32 key) external payable;
}

interface DepositHandler{
    function depositVault() external view returns (address);
}

interface WithdrawalHandler{
    function withdrawalVault() external view returns (address);
}

interface DataStore{
    function getUint(bytes32 key) external view returns (uint256);
}

interface ICallbackReceiver {
    struct Flags {
        bool shouldUnwrapNativeToken;
    }

    struct DepositNumbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct DepositAddresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct WithdrawalNumbers {
        uint256 marketTokenAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct WithdrawalAddresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct DepositProps {
        ICallbackReceiver.DepositAddresses addresses;
        ICallbackReceiver.DepositNumbers numbers;
        ICallbackReceiver.Flags flags;
    }

    struct WithdrawalProps {
        ICallbackReceiver.WithdrawalAddresses addresses;
        ICallbackReceiver.WithdrawalNumbers numbers;
        ICallbackReceiver.Flags flags;
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

    struct AddressItems {
        ICallbackReceiver.AddressKeyValue[] items;
        ICallbackReceiver.AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        ICallbackReceiver.UintKeyValue[] items;
        ICallbackReceiver.UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        ICallbackReceiver.IntKeyValue[] items;
        ICallbackReceiver.IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        ICallbackReceiver.BoolKeyValue[] items;
        ICallbackReceiver.BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        ICallbackReceiver.Bytes32KeyValue[] items;
        ICallbackReceiver.Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        ICallbackReceiver.BytesKeyValue[] items;
        ICallbackReceiver.BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        ICallbackReceiver.StringKeyValue[] items;
        ICallbackReceiver.StringArrayKeyValue[] arrayItems;
    }

    struct EventLogData {
        ICallbackReceiver.AddressItems addressItems;
        ICallbackReceiver.UintItems uintItems;
        ICallbackReceiver.IntItems intItems;
        ICallbackReceiver.BoolItems boolItems;
        ICallbackReceiver.Bytes32Items bytes32Items;
        ICallbackReceiver.BytesItems bytesItems;
        ICallbackReceiver.StringItems stringItems;
    }
}

interface StabilizeStrategy {
    struct MarketInfo {
        address marketAddress; // GM market address
        address chainlinkOracleAddress;
        uint256 chainlinkOracleAddedDecimals;
        uint256 gmTokenAmount;
        uint256 lastComparedPrice;
        uint256 recentPrice;
        int256 priceDelta; // Can be negative or positive
    }
    function recognizedUSDCBalance() external view returns (uint256);
    function currentInterestDebt() external view returns (uint256);
    function lastActionBalance() external view returns (uint256);
    function MarketList(uint256) external view returns (StabilizeStrategy.MarketInfo memory);
    function marketListCount() external view returns (uint256);
}

contract StabilizeStrategyGMUSDCV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public propAddress; // The address that contains properties for the strategy

    uint256 constant DIVISION_FACTOR = 100000;
    uint256 public lastTradeTime = 0;

    // Strategy information
    uint256 public currentInterestDebt = 0; // This accrues as the interest is collected
    uint256 public currentCushion = 0; // USDC amount of current cushion, a method used to lock in gains
    uint256 public recognizedUSDCBalance; // USDC recognized by the strategy as part of the strategy, excludes USDC sent directly
    uint256 private lastMarketCheck;
    uint256 public lastActionBalance; // The value (in USD with 18 decimals) of the strategy at the last calculation (deposit, withdraw, rebalance), used to calculate profit
    uint256 public bestGMMarket = 0;
    uint256 private worstGMMarket = 0;

    // Callback variables
    mapping(bytes32 => CallbackInfo) private authorizedCallbackHashMap;
    uint256 public numberOfPendingCallbacks = 0; // This needs to be greater than 0 for the strategy to accept the callback

    // Related to withdrawal callback
    uint256 private totalWithdrawalUsdcCost; // The total cost of the consecutive withdrawals 
    uint256 private postWithdrawalAction; // Determines what to do
    uint256 private postWithdrawalTarget;
    bool private postWithdrawTakeAll;
    address private postWithdrawUser;

    event WithdrawToUserFee(address recipient, uint256 withdrawUSDC, uint256 withdrawGasFeeUSDC, uint256 netWithdrawUSDC);

    struct CallbackInfo {
        bool authorized;
        uint256 gmMarket;
    }
    
    // Token information
    // This strategy accepts fsGLP
    struct TokenInfo {
        IERC20 token; // Reference of token
        uint256 decimals; // Decimals of token
    }
    
    TokenInfo[] private tokenList; // An array of tokens accepted as deposits

    struct MarketInfo {
        address marketAddress; // GM market address
        address chainlinkOracleAddress;
        uint256 chainlinkOracleAddedDecimals;
        uint256 gmTokenAmount;
        uint256 lastComparedPrice;
        uint256 recentPrice; // A more recent price
        int256 priceDelta; // Can be negative or positive
    }

    MarketInfo[] public MarketList;

    // Strategy specific variables
    address constant SUSHI_ROUTER = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant GMX_EXCHANGE_ROUTER = address(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);

    //Uniswap Tiers
    uint24 constant UNISWAPV3_FEE_LOW_PERCENT = 500; // 0.05%
    
    address constant WETH_ADDRESS = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address constant STBZ_ADDRESS = address(0x2C110867CA90e43D372C1C2E92990B00EA32818b);
    address constant ARB_ADDRESS = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    
    constructor(
        address _prop
    ) public {
        propAddress = _prop;
        setupWithdrawTokens();
        setupGMXMarkets();
    }

    // Initialization functions
    
    receive() external payable {
        
    }
    
    function setupWithdrawTokens() internal {
        // Start with USDC native
        IERC20 _token = IERC20(address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals()
            })
        );
    }

    function determineInitialMarketPrices() external {
        onlyGovernance();
        if(MarketList[0].lastComparedPrice != 0) { return; }
        for(uint256 it = 0; it < MarketList.length; it++){
            MarketList[it].lastComparedPrice = StabilizeStrategyProperties(propAddress).getGMTokenPrice(address(this), it);
            MarketList[it].recentPrice = MarketList[it].lastComparedPrice;
        }
    }

    function createNewMarket(address _market, address _chainlinOracle) internal {
        MarketList.push(
            MarketInfo({
                marketAddress: _market,
                chainlinkOracleAddress: _chainlinOracle,
                chainlinkOracleAddedDecimals: 10,
                gmTokenAmount: 0,
                lastComparedPrice: 0,
                recentPrice: 0,
                priceDelta: 0
            })
        );
    }

    function setupGMXMarkets() internal {
        // Market WETH/USDC
        createNewMarket(address(0x70d95587d40A2caf56bd97485aB3Eec10Bee6336), address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612));

        // Market ARB/USDC
        createNewMarket(address(0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407), address(0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6));

        // Market BTC/USDC
        createNewMarket(address(0x47c031236e19d024b42f8AE6780E44A573170703), address(0x6ce185860a4963106506C203335A2910413708e9));

        // Market LINK/USDC
        createNewMarket(address(0x7f1fa204bb700853D36994DA19F830b6Ad18455C), address(0x86E53CF1B870786351Da77A57575e79CB55812CB));

        // Market UNI/USDC
        createNewMarket(address(0xc7Abb2C5f3BF3CEB389dF0Eecd6120D451170B50), address(0x9C917083fDb403ab5ADbEC26Ee294f6EcAda2720));

        // Market SOL/USDC
        createNewMarket(address(0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9), address(0x24ceA4b8ce57cdA5058b924B9B9987992450590c));

        // Governance can add more vaults if needed
    }
    
    // Modifier
    function onlyZSToken() internal view {
        require(StabilizeStrategyProperties(propAddress).zsTokenAddress() == _msgSender(), "E1");
    }
    
    // Read functions
    
    function rewardTokensCount() external view returns (uint256) {
        return tokenList.length;
    }
    
    function rewardTokenAddress(uint256 _pos) external view returns (address) {
        require(_pos < tokenList.length,"E2");
        return address(tokenList[_pos].token);
    }

    function marketListCount() external view returns (uint256) {
        return MarketList.length;
    }

    function checkEmergencyWithdraw() internal view {
        require(StabilizeStrategyProperties(propAddress).emergencyWithdrawMode() == false, "E28");
    }

    function checkPendingCallbacks() internal view {
        require(numberOfPendingCallbacks == 0, "E3"); // Make sure there are no pending callbacks right now
    }
    
    function balance() public view returns (uint256) {
        checkPendingCallbacks();
        return StabilizeStrategyProperties(propAddress).balance(address(this));
    }
    
    function withdrawTokenReserves() public view returns (address, uint256) {
        return (address(tokenList[0].token), lastActionBalance);
    }

    function canTransfer() external view returns (bool) {
        if(numberOfPendingCallbacks > 0){return false;} // Can't transfer tokens if pending callbacks exist
        return true;
    }
    
    // Write functions
    
    function enter() external {
        onlyZSToken();
        deposit(false, 0);
    }
    
    function exit() external {
        // The ZS token vault is removing all tokens from this strategy
        onlyZSToken();
        withdraw(_msgSender(),1,1, false);
    }
    
    function deposit(bool nonContract, uint256 usdcDeposited) public {
        nonContract;
        onlyZSToken();
        checkEmergencyWithdraw(); // Can't move funds when this is activated
        checkPendingCallbacks();
        compoundInterest();
        require(lastActionBalance.add(usdcDeposited.mul(1e18).div(10**tokenList[0].decimals)) < StabilizeStrategyProperties(propAddress).maxTVL(), "E27"); // Too much value locked in this contract for more deposits
        if(recognizedUSDCBalance == 0){
            (bestGMMarket, worstGMMarket) = determineBestAndWorstMarkets();
            lastMarketCheck = block.timestamp;
        }

        // Only the ZS token can call the function
        if(usdcDeposited == 0){
            recognizedUSDCBalance = tokenList[0].token.balanceOf(address(this)); // This will only occur when admin changes strategy
        }else{
            require(usdcDeposited > StabilizeStrategyProperties(propAddress).usdcMinMovement().mul(10 ** tokenList[0].decimals), "E5");
            recognizedUSDCBalance += usdcDeposited;
        }
        payInterestThenNextStep(1, usdcDeposited, address(0), address(0));
    }

    function withdraw(address _depositor, uint256 _share, uint256 _total, bool nonContract) public returns (uint256) {
        nonContract;
        onlyZSToken();
        checkEmergencyWithdraw(); // Can't move funds when this is activated
        checkPendingCallbacks();
        compoundInterest();
        uint256 _balance = balance();
        require(_balance > 0, "E7");
        uint256 withdrawAmountUsdc = 0;
        bool takeAll = false;
        StabilizeStrategyProperties prop = StabilizeStrategyProperties(propAddress);
        address zsTokenAddress = prop.zsTokenAddress();
        if(_share < _total){
            withdrawAmountUsdc = _balance.mul(_share).div(_total);
            require(withdrawAmountUsdc > prop.usdcMinMovement().mul(10 ** tokenList[0].decimals).mul(1e18).div(10 ** tokenList[0].decimals), "E8"); // Too little being withdrawn
        }else{
            // We are all shares, transfer all
            sweepEthToUsdc(); // Also include the tied up ETH
            withdrawAmountUsdc = _balance; // The _balance will be slightly less than the actual balance but doesn't matter
            takeAll = true;
        }
        if(_depositor != zsTokenAddress){
            // Removing too much at once
            require(withdrawAmountUsdc < prop.usdMaxMovement().mul(MarketList.length), "E9");
        }
        withdrawAmountUsdc = withdrawAmountUsdc.mul(10 ** tokenList[0].decimals).div(1e18);
        postWithdrawTakeAll = takeAll;
        bool finalize = payInterestThenNextStep(2, withdrawAmountUsdc, address(0), _depositor);
        if(finalize == true){
            // We have enough USDC to send to the user right now
            bool ok = finalizeWithdraw(_depositor, withdrawAmountUsdc, takeAll);
            if(ok == true){
                if(_depositor == zsTokenAddress){
                    zsToken(zsTokenAddress).finalizeRedeem(_depositor); // We are removing from the strategy back to the vault
                }
                lastActionBalance = prop.untaxBalance(address(this), true);
                return withdrawAmountUsdc;
            }
            revert("E10");
        }
        return 0; // Do not burn the tokens yet
    }

    function finalizeWithdraw(address _receiver, uint256 _usdcAmount, bool takeAll) internal returns (bool) {
        if(takeAll == true){
            // Simply just send it all to the user as they are the last depositor
            if(recognizedUSDCBalance > 0){
                tokenList[0].token.safeTransfer(_receiver, recognizedUSDCBalance);
            }
            emit WithdrawToUserFee(_receiver, recognizedUSDCBalance, 0, recognizedUSDCBalance);
            recognizedUSDCBalance = 0;
            return true;
        }
        if(recognizedUSDCBalance >= _usdcAmount){
            // Send this balance minus the withdraw fees
            if(_usdcAmount <= totalWithdrawalUsdcCost){
                // User fees greater than withdrawn amount
                emit WithdrawToUserFee(_receiver, _usdcAmount, totalWithdrawalUsdcCost, 0);
            }else{
                recognizedUSDCBalance = recognizedUSDCBalance.sub(_usdcAmount.sub(totalWithdrawalUsdcCost));
                tokenList[0].token.safeTransfer(_receiver, _usdcAmount.sub(totalWithdrawalUsdcCost));
                emit WithdrawToUserFee(_receiver, _usdcAmount, totalWithdrawalUsdcCost, _usdcAmount.sub(totalWithdrawalUsdcCost));
            }
        }else{
            // Check to see if the balance is close to what we should have
            if(recognizedUSDCBalance < _usdcAmount.mul(DIVISION_FACTOR.sub(StabilizeStrategyProperties(propAddress).maxTradeSlippage())).div(DIVISION_FACTOR)){
                return false; // This will cancel a burn process
            }
            if(recognizedUSDCBalance > totalWithdrawalUsdcCost){
                recognizedUSDCBalance = totalWithdrawalUsdcCost;
                tokenList[0].token.safeTransfer(_receiver, recognizedUSDCBalance.sub(totalWithdrawalUsdcCost));
                emit WithdrawToUserFee(_receiver, _usdcAmount, totalWithdrawalUsdcCost, recognizedUSDCBalance.sub(totalWithdrawalUsdcCost));
            }else{
                emit WithdrawToUserFee(_receiver, _usdcAmount, totalWithdrawalUsdcCost, 0);
            }
        }
        return true;
    }

    function compoundInterest() internal {
        for(uint256 it = 0; it < MarketList.length; it++){
            MarketList[it].recentPrice = StabilizeStrategyProperties(propAddress).getGMTokenPrice(address(this), it); // Update the recent prices
        }
        uint256 currentBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false);
        if(currentBalance > lastActionBalance){
            uint256 newInterest = currentBalance.sub(lastActionBalance).mul(DIVISION_FACTOR.sub(StabilizeStrategyProperties(propAddress).percentDepositor())).div(DIVISION_FACTOR);
            lastActionBalance = currentBalance; // Reset the interest
            currentInterestDebt = currentInterestDebt.add(newInterest);
        }
    }

    function payInterestThenNextStep(uint256 nextStepFlag, uint256 amountUsdcMovedForUser, address _executor, address _user) internal returns (bool) {
        // When nextStepFlag is 1, add interest to debt then deposit up to max
        // When nextStepFlag is 2, the order will be withdraw amount of interest plus amountNeeded for user
        // When nextStepFlag is 3, the order will be withdraw amount of interest plus balance of smallest gmToken up to max, then deposit up to max
        // Executor is only needed for stepflag 1 or 3, it is paid out from minReserve

        uint256 extraUsdc = StabilizeStrategyProperties(propAddress).calculateExtraUsdc(address(this));
        uint256 usdcNeeded;
        if(currentInterestDebt > StabilizeStrategyProperties(propAddress).usdMinInterest()){
            // Time to payout the interest, so add that to the usdc needed

            // Remove the cushion factor
            if(extraUsdc > currentCushion){
                // Hold onto the cushion until explicitly used
                extraUsdc = extraUsdc.sub(currentCushion);
            }else{
                extraUsdc = 0;
            }

            usdcNeeded = currentInterestDebt.mul(10**tokenList[0].decimals).div(1e18);
            if(extraUsdc >= usdcNeeded){
                // Do the buyback and reset the interest
                performUsdcBuybacks(usdcNeeded);
                currentInterestDebt = 0;
                usdcNeeded = 0;
            }else if(extraUsdc > 0){
                // Partial interest payment ok too
                performUsdcBuybacks(extraUsdc);
                currentInterestDebt = currentInterestDebt.sub(extraUsdc.mul(1e18).div(10**tokenList[0].decimals));
                usdcNeeded = currentInterestDebt.mul(10**tokenList[0].decimals).div(1e18);
            }
        }

        if(nextStepFlag == 1){ // Deposit only
            payExecutor(_executor); // Paid from minReserve
            postWithdrawalAction = 1;
            extraUsdc = StabilizeStrategyProperties(propAddress).calculateExtraUsdc(address(this));
            if(extraUsdc > currentCushion){
                // Hold onto the cushion until explicitly used
                extraUsdc = extraUsdc.sub(currentCushion);
            }else{
                extraUsdc = 0;
            }
            if(extraUsdc > 0){
                requestGMDeposit(extraUsdc);
            }else{
                lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), true);
            }
            return true;
        }else if(nextStepFlag == 2){
            // Initiate user withdraw up to limit
            extraUsdc = StabilizeStrategyProperties(propAddress).calculateExtraUsdc(address(this));

            usdcNeeded = usdcNeeded.add(amountUsdcMovedForUser);
            if(extraUsdc >= usdcNeeded){
                if(currentCushion > usdcNeeded){
                    currentCushion = currentCushion.sub(usdcNeeded); // We are pulling from the cushion as well for this withdrawal
                }else{
                    currentCushion = 0; // We've used up all the cushion for this withdrawal
                }
                totalWithdrawalUsdcCost = 0;
                return true; // True indicates to do the withdraw now for user as we have already taken the interest
            }else{
                currentCushion = 0; // We will use up all the cushion for this withdrawal
                bool gmExists = false;
                for(uint256 it = 0; it < MarketList.length; it++){
                    if(MarketList[it].gmTokenAmount > 0){
                        gmExists = true;
                    }
                }
                totalWithdrawalUsdcCost = 0; // Reset this, will subtract from user balance received at the end
                if(gmExists == false) { return true; } // No more GM tokens
                // We need to extract more usdc, so do that before paying out potential interest
                postWithdrawUser = _user;
                postWithdrawalAction = 2;
                postWithdrawalTarget = usdcNeeded; // The total amount we need
                requestGMWithdraw(usdcNeeded.sub(extraUsdc), true);
                return false;
            }
        }else if(nextStepFlag == 3){
            // No user actions but rather a pool rebalance, can pay out interest and funds to executor
            payExecutor(_executor); // Paid from minReserve
            // Now remove funds from least performing pool before moving them to best performing pool
            postWithdrawUser = address(0);
            postWithdrawalAction = 3;
            totalWithdrawalUsdcCost = 0; // Reset this but not used
            requestGMWithdraw(StabilizeStrategyProperties(propAddress).usdMaxMovement().mul(10 ** tokenList[0].decimals).div(1e18), false);
            return true;
        }
    }

    function requestGMWithdraw(uint256 _usdcAmountRemaining, bool _doMultiple) internal {
        // Will pull USDC from GM pools (and do swaps if needed), concurrently starting from GM pool with most negative price change

        while(true){ // Infinite loop possible
            // Will potentially do simultaneous withdrawals
            uint256 _usdcAmount = _usdcAmountRemaining;
            {
                // Cannot withdraw more than the max movement at once, will need to do a repeat withdraw to get more than this
                uint256 maxUsdcWithdraw = StabilizeStrategyProperties(propAddress).usdMaxMovement().mul(10 ** tokenList[0].decimals).div(1e18);
                if(_usdcAmount > maxUsdcWithdraw){
                    _usdcAmount = maxUsdcWithdraw;
                }
            }

            uint256 targetMarket = 0;

            if(_doMultiple == true){
                int256 priceChange;
                int256 indexMarket = -1;
                // Take from the market with the most negative price change (losing markets)
                for(uint256 it = 0; it < MarketList.length; it++){
                    if(MarketList[it].gmTokenAmount > 0){
                        // Only look at pools with a balance
                        if(MarketList[it].priceDelta < priceChange || indexMarket == -1){
                            indexMarket = int256(it);
                            priceChange = MarketList[it].priceDelta;
                        }
                    }
                }
                if(indexMarket < 0) { break; } // No gm Tokens remain to withdraw
                targetMarket = uint256(indexMarket);
            }else{
                // Or take from the worst performer
                targetMarket = worstGMMarket;
                if(MarketList[targetMarket].gmTokenAmount == 0){break;} // No tokens
            }

            GMXRouter.CreateWithdrawalParams memory _withdraw;
            _withdraw.receiver = address(this);
            _withdraw.callbackContract = address(this);
            _withdraw.uiFeeReceiver = address(0);
            _withdraw.market = MarketList[targetMarket].marketAddress;

            // Just convert all long tokens to USDC and hold it
            _withdraw.longTokenSwapPath = new address[](1);
            _withdraw.longTokenSwapPath[0] = MarketList[targetMarket].marketAddress;

            //if(targetMarket != 0){
                // Initial long token will need to be swapped for WETH

                //_withdraw.longTokenSwapPath[1] = MarketList[0].marketAddress;
            //}

            _withdraw.shouldUnwrapNativeToken = false;
            _withdraw.callbackGasLimit = StabilizeStrategyProperties(propAddress).callbackGasLimit();

            address withdrawalVault = WithdrawalHandler(GMXRouter(GMX_EXCHANGE_ROUTER).withdrawalHandler()).withdrawalVault(); // This is where we send the funds
            {
                uint256 gmNeeded = 0;
                uint256 gmPrice = StabilizeStrategyProperties(propAddress).getGMTokenPrice(address(this), targetMarket);
                // Convert USDC to USD to determine how many GM tokens we need to extract
                gmNeeded = _usdcAmount.mul(1e18).div(10 ** tokenList[0].decimals);
                // Take out slightly more than what we need
                gmNeeded = gmNeeded.mul(1e18).div(gmPrice).mul(StabilizeStrategyProperties(propAddress).maxTradeSlippage().add(DIVISION_FACTOR)).div(DIVISION_FACTOR);
                if(gmNeeded > MarketList[targetMarket].gmTokenAmount){
                    gmNeeded = MarketList[targetMarket].gmTokenAmount; // Take all the tokens out
                }
                require(gmNeeded > 0, "E11");
                _usdcAmount = gmNeeded.mul(gmPrice).div(1e18).mul(10 ** tokenList[0].decimals).div(1e18); // We will recalculate usdc that will be returned based on this

                MarketList[targetMarket].gmTokenAmount = MarketList[targetMarket].gmTokenAmount.sub(gmNeeded);
                IERC20(MarketList[targetMarket].marketAddress).safeTransfer(withdrawalVault, gmNeeded);
                // This accounts for slippage
                _withdraw.minLongTokenAmount = 1;
                ( , _withdraw.minShortTokenAmount) = StabilizeStrategyProperties(propAddress).getGMTokenWithdrawlAmountWithSlippage(address(this), targetMarket, gmNeeded);
            }

            {
                address datastoreAddress = GMXRouter(GMX_EXCHANGE_ROUTER).dataStore();
                _withdraw.executionFee = GasUtils(propAddress).estimateExecuteWithdrawalGasLimit(datastoreAddress, _withdraw);
                _withdraw.executionFee = GasUtils(propAddress).adjustGasLimitForEstimate(datastoreAddress, _withdraw.executionFee) + 200000; // Add 200k buffer
                if(tx.gasprice > 0){
                    _withdraw.executionFee = _withdraw.executionFee * tx.gasprice;
                }
                require(_withdraw.callbackGasLimit <= GasUtils(propAddress).getMaxCallbackGasLimit(datastoreAddress), "E12");
            }

            // Calculate first the execution cost
            uint256 gasCost;
            {
                gasCost = StabilizeStrategyProperties(propAddress).calculateUniswapV3Input(address(tokenList[0].token), WETH_ADDRESS, _withdraw.executionFee, UNISWAPV3_FEE_LOW_PERCENT);
                require(recognizedUSDCBalance > gasCost, "E13");
                // Now swap USDC for WETH
                totalWithdrawalUsdcCost += gasCost;
                if(_usdcAmount >= _usdcAmountRemaining){
                    // Take an additional gas cost one-time due to the fact that deposits also require a non-factored in gas expense
                    totalWithdrawalUsdcCost += gasCost;
                }
                recognizedUSDCBalance = recognizedUSDCBalance.sub(gasCost);
                gasCost = swapViaUniswapV3(address(tokenList[0].token), WETH_ADDRESS, gasCost, UNISWAPV3_FEE_LOW_PERCENT);
                IERC20(WETH_ADDRESS).safeTransfer(withdrawalVault, gasCost); // Send WETH directly to the handler
            }

            {
                numberOfPendingCallbacks = numberOfPendingCallbacks.add(1);
                bytes32 key = GMXRouter(GMX_EXCHANGE_ROUTER).createWithdrawal(_withdraw);
                CallbackInfo memory info;
                info.authorized = true;
                info.gmMarket = targetMarket; // If cancelled, the gm token returns to the market
                authorizedCallbackHashMap[key] = info;
            }

            if(_usdcAmountRemaining > _usdcAmount){
                _usdcAmountRemaining.sub(_usdcAmount);
            }else{
                _usdcAmountRemaining = 0;
            }

            if(_usdcAmountRemaining == 0){break;} // No more withdrawals concurrent withdrawals to create
            if(_doMultiple == false){break;} // Only pull from one pool
        }
    }

    function requestGMDeposit(uint256 _usdcAmountForDeposit) internal {
        if(StabilizeStrategyProperties(propAddress).interactGMMarkets() == false) { return; }
        if(StabilizeStrategyProperties(propAddress).checkMarketFull(address(this), bestGMMarket) == true) { return; } // Cannot go into a full market

        {
            uint256 maxUsdcDeposit = StabilizeStrategyProperties(propAddress).usdMaxMovement().mul(10 ** tokenList[0].decimals).div(1e18);
            if(_usdcAmountForDeposit > maxUsdcDeposit){
                _usdcAmountForDeposit = maxUsdcDeposit;
            }
        }

        // This takes USDC, splits it in half for deposit then inserts it into pool
        GMXRouter.CreateDepositParams memory _deposit;
        _deposit.receiver = address(this);
        _deposit.callbackContract = address(this);
        _deposit.uiFeeReceiver = address(0);
        _deposit.market = MarketList[bestGMMarket].marketAddress;
        _deposit.initialLongToken = WETH_ADDRESS;
        _deposit.initialShortToken = address(tokenList[0].token);
        if(bestGMMarket != 0){
            // Initial long token (WETH) will need to be swapped for something else
            _deposit.longTokenSwapPath = new address[](2);
            _deposit.longTokenSwapPath[0] = MarketList[0].marketAddress;
            _deposit.longTokenSwapPath[1] = MarketList[bestGMMarket].marketAddress;
        }
        _deposit.shouldUnwrapNativeToken = false;
        _deposit.callbackGasLimit = StabilizeStrategyProperties(propAddress).callbackGasLimit();
        {
            address datastoreAddress = GMXRouter(GMX_EXCHANGE_ROUTER).dataStore();
            _deposit.executionFee = GasUtils(propAddress).estimateExecuteDepositGasLimit(datastoreAddress, _deposit, 1, 1);
            _deposit.executionFee = GasUtils(propAddress).adjustGasLimitForEstimate(datastoreAddress, _deposit.executionFee) + 200000; // Add 200k buffer
            if(tx.gasprice > 0){
                _deposit.executionFee = _deposit.executionFee * tx.gasprice;
            }
            require(_deposit.callbackGasLimit <= GasUtils(propAddress).getMaxCallbackGasLimit(datastoreAddress), "E15");
        }

        // Calculate first the execution cost
        uint256 gasCost;
        address depositVault = DepositHandler(GMXRouter(GMX_EXCHANGE_ROUTER).depositHandler()).depositVault(); // This is where we send the funds
        {
            gasCost = StabilizeStrategyProperties(propAddress).calculateUniswapV3Input(address(tokenList[0].token), WETH_ADDRESS, _deposit.executionFee, UNISWAPV3_FEE_LOW_PERCENT);
            require(recognizedUSDCBalance.sub(_usdcAmountForDeposit) > gasCost, "E16");
            // Now swap USDC for WETH then convert to ETH
            recognizedUSDCBalance = recognizedUSDCBalance.sub(gasCost);
            gasCost = swapViaUniswapV3(address(tokenList[0].token), WETH_ADDRESS, gasCost, UNISWAPV3_FEE_LOW_PERCENT);
            IERC20(WETH_ADDRESS).safeTransfer(depositVault, gasCost); // Deposit straight into the vault
        }

        {
            // Determine the maximum amount of slippage allowed for the deposit
            _deposit.minMarketTokens = _usdcAmountForDeposit.mul(1e18).div(10 ** tokenList[0].decimals);
            _deposit.minMarketTokens = _deposit.minMarketTokens.mul(1e18).div(StabilizeStrategyProperties(propAddress).getGMTokenPrice(address(this), bestGMMarket));
            _deposit.minMarketTokens = _deposit.minMarketTokens.mul(DIVISION_FACTOR.sub(StabilizeStrategyProperties(propAddress).maxTradeSlippage())).div(DIVISION_FACTOR);

            recognizedUSDCBalance = recognizedUSDCBalance.sub(_usdcAmountForDeposit);
            // Now convert half of USDC to WETH
            uint256 wethIn = _usdcAmountForDeposit.div(2);
            _usdcAmountForDeposit = _usdcAmountForDeposit.sub(wethIn);
            wethIn = swapViaUniswapV3(address(tokenList[0].token), WETH_ADDRESS, wethIn, UNISWAPV3_FEE_LOW_PERCENT);
            // Then send to ExchangeRouter for further swaps
            IERC20(WETH_ADDRESS).safeTransfer(depositVault, wethIn);
            tokenList[0].token.safeTransfer(depositVault, _usdcAmountForDeposit);
        }

        {
            // Initiate the deposit request
            numberOfPendingCallbacks = numberOfPendingCallbacks.add(1);
            postWithdrawalAction = 0;
            bytes32 key = GMXRouter(GMX_EXCHANGE_ROUTER).createDeposit(_deposit);
            CallbackInfo memory info;
            info.authorized = true;
            info.gmMarket = bestGMMarket;
            authorizedCallbackHashMap[key] = info;
        }
    }

    function determineBestAndWorstMarkets() internal returns (uint256, uint256) {
        // Returns the best apr performer since last time and the worst apr performer
        // Worst apr performer must be a pool we are already in
        int256 bestChange = 0;
        int256 bestIndex = -1;
        int256 worstChange = 0;
        int256 worstIndex = bestIndex;
        for(uint256 it = 0; it < MarketList.length; it++){
            uint256 cPrice = StabilizeStrategyProperties(propAddress).getGMTokenPrice(address(this), it);
            uint256 rewardFactor = StabilizeStrategyProperties(propAddress).marketRewardsInfo(it).mul(DIVISION_FACTOR).div(IERC20(MarketList[it].marketAddress).totalSupply()); // Normalize the reward
            if(cPrice > MarketList[it].lastComparedPrice){
                MarketList[it].priceDelta = int256(cPrice.sub(MarketList[it].lastComparedPrice).mul(DIVISION_FACTOR).div(MarketList[it].lastComparedPrice)) + int256(rewardFactor);
            }else{
                MarketList[it].priceDelta = -int256(MarketList[it].lastComparedPrice.sub(cPrice).mul(DIVISION_FACTOR).div(MarketList[it].lastComparedPrice)) + int256(rewardFactor);
            }
            MarketList[it].lastComparedPrice = cPrice;
            MarketList[it].recentPrice = MarketList[it].lastComparedPrice;
            if(StabilizeStrategyProperties(propAddress).checkMarketFull(address(this), it) == false){
                // Can only deposit into not full markets
                if(MarketList[it].priceDelta > bestChange || bestIndex == -1){
                    bestChange = MarketList[it].priceDelta;
                    bestIndex = int256(it);
                }
            }
            if(MarketList[it].gmTokenAmount > 0){
                if(MarketList[it].priceDelta < worstChange || worstIndex == -1){
                    worstChange = MarketList[it].priceDelta;
                    worstIndex = int256(it);
                }
            }
        }
        if(worstIndex == -1){
            worstIndex = bestIndex;
        }
        return (uint256(bestIndex), uint256(worstIndex));
    }
    
    function swapViaUniswapV3(address inputAddress, address outputAddress, uint256 _amount, uint24 _fee) internal returns (uint256) {
        IERC20(inputAddress).safeTransfer(propAddress, _amount); // Send the tokens
        return StabilizeStrategyProperties(propAddress).swapViaUniswapV3(inputAddress, outputAddress, address(this), _amount, _fee); // Then receive the tokens back
    }

    // Handling of callback functions
    // @dev called after a deposit execution
    // @param key the key of the deposit
    // @param deposit the deposit that was executed
    function afterDepositExecution(bytes32 key, ICallbackReceiver.DepositProps calldata _deposit, ICallbackReceiver.EventLogData calldata eventData) external {
        _deposit;
        checkAndUpdateAuthorizedCallback(key, GMXRouter(GMX_EXCHANGE_ROUTER).depositHandler());
        uint256 gmReceived = eventData.uintItems.items[0].value;
        if(gmReceived > 0){
            MarketList[authorizedCallbackHashMap[key].gmMarket].gmTokenAmount += gmReceived;
        }
        if(numberOfPendingCallbacks == 0){
            lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false); // Using recent prices vs current
        }
    }

    // @dev called after a deposit cancellation
    // @param key the key of the deposit
    // @param deposit the deposit that was cancelled
    function afterDepositCancellation(bytes32 key, ICallbackReceiver.DepositProps calldata _deposit, ICallbackReceiver.EventLogData calldata eventData) external {
        _deposit;
        eventData;
        checkAndUpdateAuthorizedCallback(key, GMXRouter(GMX_EXCHANGE_ROUTER).depositHandler());
        recognizedUSDCBalance = recognizedUSDCBalance.add(_deposit.numbers.initialShortTokenAmount);
        if(numberOfPendingCallbacks == 0){
            lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false); // Using recent prices vs current
        }
    }

    function afterWithdrawalExecution(bytes32 key, ICallbackReceiver.WithdrawalProps calldata _withdraw, ICallbackReceiver.EventLogData calldata eventData) external {
        _withdraw;
        checkAndUpdateAuthorizedCallback(key, GMXRouter(GMX_EXCHANGE_ROUTER).withdrawalHandler());
        recognizedUSDCBalance += eventData.uintItems.items[0].value; // We converted long token to USDC
        recognizedUSDCBalance += eventData.uintItems.items[1].value; // Should be USDC from swaps

        // Now the next actions depends on what we wanted to do previously
        if(postWithdrawalAction == 2){
            if(numberOfPendingCallbacks == 0){
                // We are done extracting, we need to withdraw to user, burn the overlying tokens, and update the balance.
                // Withdraw to user
                bool ok = finalizeWithdraw(postWithdrawUser, postWithdrawalTarget, postWithdrawTakeAll);
                // Burn user tokens
                if(ok == true){
                    zsToken(StabilizeStrategyProperties(propAddress).zsTokenAddress()).finalizeRedeem(postWithdrawUser); // This will burn the user's tokens
                }else{
                    zsToken(StabilizeStrategyProperties(propAddress).zsTokenAddress()).cancelRedeem(postWithdrawUser); // Something happened, maybe too much slippage, cancel the burn
                }
                lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false);
            }
        }else{
            // Do nothing but allow the bot to trade again for a one-time deposit
            if(numberOfPendingCallbacks == 0){
                lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false);
            }
            if(postWithdrawalAction == 4){
                // Attach this balance removed to the cushion, meaning don't deposit it right away, save for later time or different pool
                currentCushion += eventData.uintItems.items[0].value.add(eventData.uintItems.items[1].value);
            }
        }
    }

    // @dev called after a deposit cancellation
    // @param key the key of the deposit
    // @param deposit the deposit that was cancelled
    function afterWithdrawalCancellation(bytes32 key, ICallbackReceiver.WithdrawalProps calldata _withdraw, ICallbackReceiver.EventLogData calldata eventData) external {
        _withdraw;
        eventData;
        checkAndUpdateAuthorizedCallback(key, GMXRouter(GMX_EXCHANGE_ROUTER).withdrawalHandler());
        MarketList[authorizedCallbackHashMap[key].gmMarket].gmTokenAmount = IERC20(MarketList[authorizedCallbackHashMap[key].gmMarket].marketAddress).balanceOf(address(this));
        // Something happened unexpectedly
        if(numberOfPendingCallbacks == 0){
            if(postWithdrawalAction == 2){
                zsToken(StabilizeStrategyProperties(propAddress).zsTokenAddress()).cancelRedeem(postWithdrawUser); // Cancel the redeem if that was the initial action
            }
            lastActionBalance = StabilizeStrategyProperties(propAddress).untaxBalance(address(this), false);
        }
    }

    function checkAndUpdateAuthorizedCallback(bytes32 key, address handler) internal {
        // Determines if the handler is sending the message
        require(_msgSender() == handler, "E17");
        require(authorizedCallbackHashMap[key].authorized == true, "E18");
        require(numberOfPendingCallbacks > 0, "E19");
        authorizedCallbackHashMap[key].authorized = false;
        numberOfPendingCallbacks = numberOfPendingCallbacks.sub(1);
        sweepEthToUsdc();
    }

    function sweepEthToUsdc() internal {
        if(address(this).balance > 0){
            WETH(WETH_ADDRESS).deposit{value: address(this).balance}(); // Convert any ETH to WETH
        }
        uint256 gasReturned = IERC20(WETH_ADDRESS).balanceOf(address(this));
        if(gasReturned > 0){
            recognizedUSDCBalance += swapViaUniswapV3(WETH_ADDRESS, address(tokenList[0].token), gasReturned, UNISWAPV3_FEE_LOW_PERCENT);
        }
    }

    // Buyback features

    function performUsdcBuybacks(uint256 _totalUsdc) internal {
        recognizedUSDCBalance = recognizedUSDCBalance.sub(_totalUsdc);
        uint256 wethAmount = swapViaUniswapV3(address(tokenList[0].token), WETH_ADDRESS, _totalUsdc, UNISWAPV3_FEE_LOW_PERCENT);
        if(wethAmount > 0){
            doSTBZBuyback(wethAmount);
        }
    }

    function doSTBZBuyback(uint256 _amount) internal {
        // Transfer WETH then perform swap
        IERC20(WETH_ADDRESS).safeTransfer(propAddress, _amount);
        StabilizeStrategyProperties(propAddress).doSTBZBuyback(_amount);
    }

    // Executor functions
    function payExecutor(address _executor) internal {
        // Executor is paid from minReserve
        if(_executor == address(0)) {return;}
        uint256 gasFee = StabilizeStrategyProperties(propAddress).getGasFee();

        // Calculate how much usdc we need to pay the executor
        uint256 usdcNeeded = StabilizeStrategyProperties(propAddress).calculateUniswapV3Input(address(tokenList[0].token), WETH_ADDRESS, gasFee, UNISWAPV3_FEE_LOW_PERCENT);
        if(usdcNeeded > recognizedUSDCBalance){
            usdcNeeded = recognizedUSDCBalance;
        }
        require(recognizedUSDCBalance > 0, "E20");
        recognizedUSDCBalance = recognizedUSDCBalance.sub(usdcNeeded);
        gasFee = swapViaUniswapV3(address(tokenList[0].token), WETH_ADDRESS, usdcNeeded, UNISWAPV3_FEE_LOW_PERCENT);
        WETH(WETH_ADDRESS).withdraw(gasFee); // WETH -> ETH
        payable(_executor).transfer(gasFee); // Transfer to executor
    }

    function checkExecutorPayoutCode() internal returns (uint256) {
        if(numberOfPendingCallbacks > 0) { return 0; }

        // Determine if we have enough funds to pay
        uint256 gasFee = StabilizeStrategyProperties(propAddress).getGasFee();

        // Calculate how much usdc we need to pay the executor
        uint256 usdcNeeded = StabilizeStrategyProperties(propAddress).calculateUniswapV3Input(address(tokenList[0].token), WETH_ADDRESS, gasFee, UNISWAPV3_FEE_LOW_PERCENT);
        if(usdcNeeded > recognizedUSDCBalance){
            return 0;
        }

        if(postWithdrawalAction != 3){
            if(block.timestamp < lastMarketCheck.add(StabilizeStrategyProperties(propAddress).minMarketCheckInterval())) { return 0; }
            lastMarketCheck = block.timestamp;
            (bestGMMarket, worstGMMarket) = determineBestAndWorstMarkets();
            if(worstGMMarket != bestGMMarket){
                // Continuously move funds from the worst performing market to the best market
                return 1;
            }
            return 0;
        }else{
            // Executor should finish the action of depositing
            return 2;
        }
    }

    function expectedProfit() external returns (uint256){
        uint256 code = checkExecutorPayoutCode();
        if(code == 0) { return 0;}
        uint256 gasFee = StabilizeStrategyProperties(propAddress).getGasFee();
        return gasFee;
    }

    function checkAndSwapTokens(address _executor) internal {
        compoundInterest();
        uint256 code = checkExecutorPayoutCode();
        if(code == 0) { return;}
        if(code == 1){
            // Do a withdraw
            payInterestThenNextStep(3, 0, _executor, address(0));
        }else if(code == 2){
            // Do the deposit
            payInterestThenNextStep(1, 0, _executor, address(0));
        }
    }

    function executorSwapTokens(address _executor, uint256 _minSecSinceLastTrade, uint256 _deadlineTime) external {
        // Function designed to promote trading with incentive
        require(block.timestamp <= _deadlineTime, "E21");
        require(block.timestamp.sub(lastTradeTime) > _minSecSinceLastTrade, "E22");
        require(_msgSender() == tx.origin, "E23"); // Prevent contracts from interacting
        lastTradeTime = block.timestamp;
        checkAndSwapTokens(_executor);
    }

    // Governance functions
    // This function is used in case tokens get stuck in strategy, it is used for experimental strategies to prevent any-cause loss of funds (after 24 hour timelock)
    function governanceEmergencyWithdrawToken(address _token, uint256 _amount) external {
        onlyGovernance();
        require(StabilizeStrategyProperties(propAddress).emergencyWithdrawMode() == true, "E24");
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function governanceDistributeArbdrop() external {
        onlyGovernance();
        sweepEthToUsdc();
        // This will take the Arb token airdropped to the strategy and convert it to USDC, then convert it to GM token
        uint256 _bal = IERC20(ARB_ADDRESS).balanceOf(address(this));
        if(_bal > 0){
            _bal = swapViaUniswapV3(ARB_ADDRESS, address(tokenList[0].token), _bal, UNISWAPV3_FEE_LOW_PERCENT);
            if(_bal > 0){
                recognizedUSDCBalance = recognizedUSDCBalance.add(_bal);
                compoundInterest();
                payInterestThenNextStep(1, 0, address(0), address(0));
            }
        }
    }

    function governanceMarketAction(uint256 _action, uint256 _marketIndex) external {
        onlyGovernance();
        compoundInterest();
        // 0 = action is withdrawal from best performing market a certain percentage (cushion percentage)
        // 1 - action is depositing cushion into indicated market (outside of interest payment)
        // 2 - liquidate market from requested market
        if(_action == 0 || _action == 2){
            uint256 usdcEquivalent;
            uint256 worst = worstGMMarket;
            if(_action == 0){
                usdcEquivalent = lastActionBalance.mul(10 ** tokenList[0].decimals).div(1e18); // Convert to USDC units
                if(usdcEquivalent > currentCushion){
                    usdcEquivalent = usdcEquivalent.sub(currentCushion);
                }
                usdcEquivalent = usdcEquivalent.mul(StabilizeStrategyProperties(propAddress).cushionPercent()).div(DIVISION_FACTOR);  
                // We'll try to pull the equivalent of this as a cushion
                postWithdrawalAction = 4;
                worstGMMarket = bestGMMarket;
            }else{
                postWithdrawalAction = 1;
                worstGMMarket = _marketIndex;
                usdcEquivalent = StabilizeStrategyProperties(propAddress).usdMaxMovement().mul(10 ** tokenList[0].decimals).div(1e18);
            }
            totalWithdrawalUsdcCost = 0;
            requestGMWithdraw(usdcEquivalent, false);
            worstGMMarket = worst;
        }else if(_action == 1 && currentCushion > 0){
            // Deposit only the cushion into pool
            uint256 best = bestGMMarket;
            bestGMMarket = _marketIndex;
            uint256 depositCushion = currentCushion;
            currentCushion = 0; // Reset the cushion
            payInterestThenNextStep(1, depositCushion, address(0), address(0));
            bestGMMarket = best;
        }
    }

    function governanceCancelRequest(bytes32 _key, uint256 _type) external payable {
        // Performed in cases of stuck tokens in the vaults
        onlyGovernance();
        if(_type == 0){
            // Cancel a deposit request
            GMXRouter(GMX_EXCHANGE_ROUTER).cancelDeposit{value: msg.value}(_key);
        }else{
            // Cancel a withdrawal request
            GMXRouter(GMX_EXCHANGE_ROUTER).cancelWithdrawal{value: msg.value}(_key);
        }
    }

    // ---------------------
    // Test functions
    /*
    function testPumpUSDC() external payable {
        WETH(WETH_ADDRESS).deposit{value: msg.value}();
        swapViaUniswapV3(WETH_ADDRESS, address(tokenList[0].token), msg.value, UNISWAPV3_FEE_LOW_PERCENT);
    }

    function testShowUSDC() external view returns (uint256) {
        return tokenList[0].token.balanceOf(address(this));
    }
    */
    // ----------
    
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 1 days; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[2] private _timelock_data;
    
    function timelockConditionsMet(uint256 _type) private {
        require(_timelockType == _type, "E25");
        _timelockType = 0; // Reset the type once the timelock is used
        if(balance() > 0){ // Timelock only applies when balance exists
            require(block.timestamp >= _timelockStart + TIMELOCK_DURATION, "E26");
        }
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external {
        onlyGovernance();
        timelockConditionsMet(1);
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the properties address
    // --------------------
    function startChangeProperties(address _address) external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeProperties() external {
        onlyGovernance();
        timelockConditionsMet(2);
        propAddress = _timelock_address;
    }
    // --------------------
}

// Inherited contracts
contract GasUtils {
    uint256 public constant FLOAT_PRECISION = 10 ** 30;
    bytes32 constant KEY_ESTIMATED_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
    bytes32 constant KEY_ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));
    bytes32 constant KEY_SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    bytes32 constant KEY_DEPOSIT_GAS_LIMIT_TRUE = keccak256(abi.encode(keccak256(abi.encode("DEPOSIT_GAS_LIMIT")), true));
    bytes32 constant KEY_DEPOSIT_GAS_LIMIT_FALSE = keccak256(abi.encode(keccak256(abi.encode("DEPOSIT_GAS_LIMIT")), false));
    bytes32 constant KEY_WITHDRAWAL_GAS_LIMIT = keccak256(abi.encode(keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT")))); // Double encoded for some reason
    bytes32 constant KEY_MAX_CALLBACK_GAS_LIMIT = keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));

    function getMaxCallbackGasLimit(address datastoreAddress) external view returns (uint256) {
        DataStore dataStore = DataStore(datastoreAddress);
        uint256 gasLimit = dataStore.getUint(KEY_MAX_CALLBACK_GAS_LIMIT);
        return gasLimit;
    }

    function adjustGasLimitForEstimate(address datastoreAddress, uint256 estimatedGasLimit) external view returns (uint256) {
        DataStore dataStore = DataStore(datastoreAddress);
        uint256 baseGasLimit = dataStore.getUint(KEY_ESTIMATED_GAS_FEE_BASE_AMOUNT);
        uint256 multiplierFactor = dataStore.getUint(KEY_ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR);
        uint256 gasLimit = baseGasLimit + estimatedGasLimit * multiplierFactor / FLOAT_PRECISION;
        return gasLimit;
    }

    function estimateExecuteDepositGasLimit(address datastoreAddress, GMXRouter.CreateDepositParams calldata deposit, uint256 initialLong, uint256 initialShort) external view returns (uint256) {
        DataStore dataStore = DataStore(datastoreAddress);
        uint256 gasPerSwap = dataStore.getUint(KEY_SINGLE_SWAP_GAS_LIMIT);
        uint256 swapCount = deposit.longTokenSwapPath.length + deposit.shortTokenSwapPath.length;
        uint256 gasForSwaps = swapCount * gasPerSwap;

        if (initialLong == 0 || initialShort == 0) {
            return dataStore.getUint(KEY_DEPOSIT_GAS_LIMIT_TRUE) + deposit.callbackGasLimit + gasForSwaps;
        }

        return dataStore.getUint(KEY_DEPOSIT_GAS_LIMIT_FALSE) + deposit.callbackGasLimit + gasForSwaps;
    }

    function estimateExecuteWithdrawalGasLimit(address datastoreAddress, GMXRouter.CreateWithdrawalParams calldata withdrawal) external view returns (uint256) {
        DataStore dataStore = DataStore(datastoreAddress);
        uint256 gasPerSwap = dataStore.getUint(KEY_SINGLE_SWAP_GAS_LIMIT);
        uint256 swapCount = withdrawal.longTokenSwapPath.length + withdrawal.shortTokenSwapPath.length;
        uint256 gasForSwaps = swapCount * gasPerSwap;

        return dataStore.getUint(KEY_WITHDRAWAL_GAS_LIMIT) + withdrawal.callbackGasLimit + gasForSwaps;
    }
}

contract MarketUtils {
    bytes32 constant KEY_POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    bytes32 constant KEY_MAX_POOL_AMOUNT = keccak256(abi.encode("MAX_POOL_AMOUNT"));

    function poolAmountKey(address market, address token) private pure returns (bytes32) {
        return keccak256(abi.encode(
            KEY_POOL_AMOUNT,
            market,
            token
        ));
    }

    function maxPoolAmountKey(address market, address token) private pure returns (bytes32) {
        return keccak256(abi.encode(
            KEY_MAX_POOL_AMOUNT,
            market,
            token
        ));
    }

    // this is used to divide the values of getPoolAmount and getOpenInterest
    // if the longToken and shortToken are the same, then these values have to be divided by two
    // to avoid double counting
    function getPoolDivisor(address longToken, address shortToken) private pure returns (uint256) {
        return longToken == shortToken ? 2 : 1;
    }

    // @dev get the amount of tokens in the pool
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the amount of tokens in the pool
    function getPoolAmount(address datastoreAddress, GMXReader.MarketProps memory market, address token) internal view returns (uint256) {
        /* Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress); */
        // if the longToken and shortToken are the same, return half of the token amount, so that
        // calculations of pool value, etc would be correct
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        DataStore dataStore = DataStore(datastoreAddress);
        return dataStore.getUint(poolAmountKey(market.marketToken, token)) / divisor;
    }

    // @dev get the max amount of tokens allowed to be in the pool
    // @param dataStore DataStore
    // @param market the market to check
    // @param token the token to check
    // @return the max amount of tokens that are allowed in the pool
    function getMaxPoolAmount(address datastoreAddress, GMXReader.MarketProps memory market, address token) internal view returns (uint256) {
        DataStore dataStore = DataStore(datastoreAddress);
        return dataStore.getUint(maxPoolAmountKey(market.marketToken, token));
    }
}

// Deploy as a separate contract, needed as main contract is too large
contract StabilizeStrategyProperties is Ownable, GasUtils, MarketUtils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public bankAddress; // Address to the STBZ buyback bank
    address public zsTokenAddress; // The address of the controlling zs-Token
    
    // Depositor info
    uint256 public percentDepositor = 90000; // 1000 = 1%, depositors earn 90% of all gains
    // Anything left over goes towards buyback bank

    // Strategy information
    uint256 public maxTradeSlippage = 1000; // 1000 / 100000 = 1%
    uint256 public usdcMinMovement = 10; // The minimum amount that a user can move around (deposit or withdraw, no decimals). Some of the USDC is used to pay the execution cost
    uint256 public usdcMinReserve = 30; // The smallest amount of USDC (no decimals) that will be stored for reserve, used for gas costs
    uint256 public usdMinInterest = 0; // Minimum amount of interest needed to send it to the reserves
    uint256 public usdMaxMovement = 50000e18; // The maximum amount (in USD with 18 decimals) that can be deposited or withdrawn from a GM market at a time
    uint256 public cushionPercent = 20000; // A mechanisim used to lock in gains from growth in token prices
    uint256 public maxTVL = 200000e18; // Strategy max value locked
    uint256 public callbackGasLimit = 2000000; // Gas limit used for callback
    uint256 public minMarketCheckInterval = 6 days; // The time in between market checks that can be performed

    bool public interactGMMarkets = true; // Strategist can turn off GM market deposits
    bool public emergencyWithdrawMode = false; // Activated in case tokens get stuck in strategy after 24 hour timelock

    mapping(uint256 => uint256) public marketRewardsInfo;

    // Executor info
    uint256 public gasPrice = 200000000; // 0.2 Gwei, governance can change
    uint256 public gasStipend = 3000000; // This is the gas units that are covered by executing a trade taken from the WETH profit

    address constant USDC_ADDRESS = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address constant WETH_ADDRESS = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address constant STBZ_ADDRESS = address(0x2C110867CA90e43D372C1C2E92990B00EA32818b);

    address constant GMX_EXCHANGE_READER = address(0xf60becbba223EEA9495Da3f606753867eC10d139);
    address constant GMX_EXCHANGE_ROUTER = address(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
    uint256 constant DIVISION_FACTOR = 100000;

    address constant UNISWAP_ROUTER_V3 = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address constant UNISWAP_QUOTER_V3 = address(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    address constant SUSHI_ROUTER = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    constructor(
        address _bank,
        address _zsToken
    ) public {
        bankAddress = _bank;
        zsTokenAddress = _zsToken;
    }

    function calculateExtraUsdc(address stratAddress) external view returns (uint256) {
        uint256 extraUsdc = 0;
        if(StabilizeStrategy(stratAddress).recognizedUSDCBalance() > usdcMinReserve.mul(10**uint256(IERC20(USDC_ADDRESS).decimals()))){
            extraUsdc = StabilizeStrategy(stratAddress).recognizedUSDCBalance().sub(usdcMinReserve.mul(10**uint256(IERC20(USDC_ADDRESS).decimals())));
        }
        return extraUsdc;
    }

    // Add some getters here too
    function getGasFee() external view returns (uint256) {
        uint256 gasFee = gasPrice.mul(gasStipend); // This is gas stipend in wei
        gasFee = gasFee.mul(2);
        return gasFee;
    }

    function untaxBalance(address stratAddress, bool useFresh) public view returns (uint256) {
        uint256 marketLength = StabilizeStrategy(stratAddress).marketListCount();
        // Calculate the current balance in USD
        uint256 currentBalance = StabilizeStrategy(stratAddress).recognizedUSDCBalance().mul(1e18).div(10 ** uint256(IERC20(USDC_ADDRESS).decimals()));
        for(uint256 it = 0; it < marketLength; it++){
            StabilizeStrategy.MarketInfo memory market = StabilizeStrategy(stratAddress).MarketList(it);
            uint256 amount = market.gmTokenAmount;
            if(amount > 0){
                uint256 price;
                if(useFresh == true){
                    price = getGMTokenPrice(stratAddress, it);
                }else{
                    price = market.recentPrice; // Less expensive function
                }
                amount = amount.mul(price).div(1e18);
                currentBalance += amount;
            }
        }
        return currentBalance;
    }
    
    function balance(address stratAddress) external view returns (uint256) {
        uint256 currentBalance = untaxBalance(stratAddress, true);
        if(currentBalance > StabilizeStrategy(stratAddress).lastActionBalance().add(StabilizeStrategy(stratAddress).currentInterestDebt())){
            // Strategy will tax balance to STBZ buybacks everytime there is an interaction with the contract
            return StabilizeStrategy(stratAddress).lastActionBalance().add(currentBalance.sub(StabilizeStrategy(stratAddress).lastActionBalance()).mul(percentDepositor).div(DIVISION_FACTOR)).sub(StabilizeStrategy(stratAddress).currentInterestDebt());
        }else{
            // Current balance has decreased since last time
            if(currentBalance > StabilizeStrategy(stratAddress).currentInterestDebt()){
                return currentBalance.sub(StabilizeStrategy(stratAddress).currentInterestDebt());
            }else{
                return 0; // Balance is not enough to cover debt
            }
        }
    }

    function checkMarketFull(address stratAddress, uint256 gmTokenIndex) external view returns (bool) {
        StabilizeStrategy.MarketInfo memory market = StabilizeStrategy(stratAddress).MarketList(gmTokenIndex);
        address datastoreAddress = GMXRouter(GMX_EXCHANGE_ROUTER).dataStore();
        GMXReader reader = GMXReader(GMX_EXCHANGE_READER);
        GMXReader.MarketProps memory _marketProp = reader.getMarket(datastoreAddress, market.marketAddress);
        uint256 cPoolAmount = getPoolAmount(datastoreAddress, _marketProp, USDC_ADDRESS);
        uint256 maxPoolAmount = getMaxPoolAmount(datastoreAddress, _marketProp, USDC_ADDRESS);
        if(cPoolAmount.add(usdMaxMovement.mul(10 ** uint256(IERC20(USDC_ADDRESS).decimals())).div(1e18)) >= maxPoolAmount){
            // Market cannot support an additional usdMaxamount
            return true;
        }
        return false;
    }

    function getLongTokenPrice(address stratAddress, uint256 gmTokenIndex) internal view returns (uint256) {
        StabilizeStrategy.MarketInfo memory market = StabilizeStrategy(stratAddress).MarketList(gmTokenIndex);
        ChainLinkOracle oracle = ChainLinkOracle(market.chainlinkOracleAddress);
        uint256 price = uint256(oracle.latestAnswer());
        return price.mul(10 ** market.chainlinkOracleAddedDecimals); // Should be normalized to 18 decimals
        // The short token USDC is assumed to have a price of $1 for sake of this strategy
    }

    function getGMTokenPrice(address stratAddress, uint256 gmTokenIndex) public view returns (uint256) {
        StabilizeStrategy.MarketInfo memory market = StabilizeStrategy(stratAddress).MarketList(gmTokenIndex);
        address datastoreAddress = GMXRouter(GMX_EXCHANGE_ROUTER).dataStore();
        GMXReader reader = GMXReader(GMX_EXCHANGE_READER);
        GMXReader.MarketProps memory _marketProp = reader.getMarket(datastoreAddress, market.marketAddress);
        bytes32 pnlFactor = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS")); // Use this pnl cap for all token price calculations
        GMXReader.PriceProps memory longPrice;
        {
            uint256 price = getLongTokenPrice(stratAddress, gmTokenIndex);
            // Adjust the price to normalize it for GMX
            // Adjust to 30 decimals then subtract amount of decimals in token
            price = price.mul(10**12).div(10 ** uint256(IERC20(_marketProp.longToken).decimals()));
            longPrice.max = price;
            longPrice.min = price;
        }
        GMXReader.PriceProps memory shortPrice;
        {
            // USDC is assummed $1 price
            uint256 price = uint256(1e30).div(10 ** uint256(IERC20(USDC_ADDRESS).decimals()));
            shortPrice.max = price;
            shortPrice.min = price;
        }
        (int256 price, ) = reader.getMarketTokenPrice(datastoreAddress, _marketProp, longPrice, longPrice, shortPrice, pnlFactor, true);
        if(price < 0){
            return 0;
        }else{
            return uint256(price).div(1e12); // Price has 30 decimals, normalize back to 18
        }
    }

    function getGMTokenWithdrawlAmountWithSlippage(address stratAddress, uint256 gmTokenIndex, uint256 gmTokenAmount) external view returns (uint256, uint256) {
        // Returns the min output amounts including the slippage
        StabilizeStrategy.MarketInfo memory market = StabilizeStrategy(stratAddress).MarketList(gmTokenIndex);
        address datastoreAddress = GMXRouter(GMX_EXCHANGE_ROUTER).dataStore();
        GMXReader reader = GMXReader(GMX_EXCHANGE_READER);
        GMXReader.MarketProps memory _marketProp = reader.getMarket(datastoreAddress, market.marketAddress);

        GMXReader.PriceProps memory longPrice;
        {
            uint256 price = getLongTokenPrice(stratAddress, gmTokenIndex);
            // Adjust the price to normalize it for GMX
            // Adjust to 30 decimals then subtract amount of decimals in token
            price = price.mul(10**12).div(10 ** uint256(IERC20(_marketProp.longToken).decimals()));
            longPrice.max = price;
            longPrice.min = price;
        }
        GMXReader.PriceProps memory shortPrice;
        {
            // USDC is assummed $1 price
            uint256 price = uint256(1e30).div(10 ** uint256(IERC20(USDC_ADDRESS).decimals()));
            shortPrice.max = price;
            shortPrice.min = price;
        }

        GMXReader.MarketPrices memory mPrices;
        mPrices.indexTokenPrice = longPrice;
        mPrices.longTokenPrice = longPrice;
        mPrices.shortTokenPrice = shortPrice;

        gmTokenAmount = gmTokenAmount.mul(DIVISION_FACTOR.sub(maxTradeSlippage)).div(DIVISION_FACTOR); // Add the slippage

        return reader.getWithdrawalAmountOut(datastoreAddress, _marketProp, mPrices, gmTokenAmount, address(0));
    }

    // Uniswap Utils
    function calculateUniswapV3Return(address inputAddress, address outputAddress, uint256 _amount, uint24 _fee) external returns (uint256) {
        uint160 sqrtPriceLimitX96 = 0;
        UniswapV3Router quoter = UniswapV3Router(UNISWAP_QUOTER_V3);
        return quoter.quoteExactInputSingle(inputAddress, outputAddress, _fee, _amount, sqrtPriceLimitX96);
    }

    function calculateUniswapV3Input(address inputAddress, address outputAddress, uint256 _amountOut, uint24 _fee) external returns (uint256) {
        uint160 sqrtPriceLimitX96 = 0;
        UniswapV3Router quoter = UniswapV3Router(UNISWAP_QUOTER_V3);
        return quoter.quoteExactOutputSingle(inputAddress, outputAddress, _fee, _amountOut, sqrtPriceLimitX96);
    }

    // Write functions
    
    function swapViaUniswapV3(address inputAddress, address outputAddress, address destination, uint256 _amount, uint24 _fee) external returns (uint256) {
        uint160 sqrtPriceLimitX96 = 0;
        UniswapV3Router router = UniswapV3Router(UNISWAP_ROUTER_V3);
        UniswapV3Router.ExactInputSingleParams memory params = UniswapV3Router.ExactInputSingleParams(
            inputAddress,
            outputAddress,
            _fee,
            address(this),
            block.timestamp.add(60),
            _amount,
            1,
            sqrtPriceLimitX96
        );
        uint256 _bal = IERC20(outputAddress).balanceOf(address(this));
        IERC20(inputAddress).safeApprove(UNISWAP_ROUTER_V3, 0);
        IERC20(inputAddress).safeApprove(UNISWAP_ROUTER_V3, _amount);
        router.exactInputSingle(params);
        _bal = IERC20(outputAddress).balanceOf(address(this)).sub(_bal);
        // Now transfer the balance to the destination
        IERC20(outputAddress).safeTransfer(destination, _bal);
        return _bal;
    }

    function doSTBZBuyback(uint256 _amount) external {
        SushiLikeRouter router = SushiLikeRouter(SUSHI_ROUTER);
        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = STBZ_ADDRESS;
        IERC20(WETH_ADDRESS).safeApprove(address(router), 0);
        IERC20(WETH_ADDRESS).safeApprove(address(router), _amount);
        router.swapExactTokensForTokens(_amount, 1, path, address(this), block.timestamp.add(60)); // Get STBZ
        uint256 _bal = IERC20(STBZ_ADDRESS).balanceOf(address(this));
        if(_bal > 0){
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, 0);
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, _bal);  
            StabilizeBank(bankAddress).depositSTBZ(zsTokenAddress, _bal); // This will pull the balance
        }
        return;
    }

    // Governance functions
    function governanceChangeStrategyProperties(
        bool enableDeposit, 
        uint256 _maxMove, 
        uint256 _minInterest, 
        uint256 _maxSlippage,
        uint256 _cushion, 
        uint256 _minMove, 
        uint256 _minRes, 
        uint256 _minInterval,
        uint256 _maxTvl,
        uint256 _callbackLimit) external {
            onlyGovernance();
            interactGMMarkets = enableDeposit;
            usdMaxMovement = _maxMove;
            maxTradeSlippage = _maxSlippage;
            usdcMinMovement = _minMove;
            usdcMinReserve = _minRes;
            usdMinInterest = _minInterest;
            minMarketCheckInterval = _minInterval;
            maxTVL = _maxTvl;
            callbackGasLimit = _callbackLimit;
            cushionPercent = _cushion;
    }

    function governanceChangeGasProperties(
        uint256 _maxStipend,
        uint256 _gasPrice) external {
            onlyGovernance();
            gasStipend = _maxStipend;
            gasPrice = _gasPrice;
    }

    // Reward data should be formatted 30% = 30e18, 5% = 5e18
    function governanceUpdateRewardsInfo(uint256[] calldata posID, uint256[] calldata info) external {
        onlyGovernance();
        require(posID.length > 0 && posID.length == info.length, "Lengths do not match");
        for(uint256 it = 0; it < posID.length; it++){
            marketRewardsInfo[posID[it]] = info[it];
        }
    }

    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 1 days; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[1] private _timelock_data;
    
    function timelockConditionsMet(uint256 _type) private {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        require(block.timestamp >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external {
        onlyGovernance(); timelockConditionsMet(1);
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the ba address
    // --------------------
    function startChangeBank(address _address) external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeBank() external {
        onlyGovernance(); timelockConditionsMet(2);
        bankAddress = _timelock_address;
    }
    // --------------------
    
    // Change the zsToken address
    // --------------------
    function startChangeZSToken(address _address) external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeZSToken() external {
        onlyGovernance(); timelockConditionsMet(3);
        zsTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the strategy allocations between the parties
    // --------------------
    
    function startChangeStrategyAllocations(uint256 _pDepositors) external {
        // Changes strategy allocations in one call
        onlyGovernance();
        require(_pDepositors <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = block.timestamp;
        _timelockType = 4;
        _timelock_data[0] = _pDepositors;
    }
    
    function finishChangeStrategyAllocations() external {
        onlyGovernance(); timelockConditionsMet(4);
        percentDepositor = _timelock_data[0];
    }
    // --------------------

    // Going into emergency withdraw mode in case of strategy failures, requires timelock
    // --------------------
    function startActivateEmergencyWithdrawMode() external {
        onlyGovernance();
        _timelockStart = block.timestamp;
        _timelockType = 5;
    }
    
    function finishActivateEmergencyWithdrawMode() external {
        onlyGovernance(); timelockConditionsMet(5);
        emergencyWithdrawMode = true;
    }
    // --------------------
}