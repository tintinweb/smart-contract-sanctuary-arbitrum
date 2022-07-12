// SPDX-License-Identifier: UNLICENSED

/// @summary: Contract stakes DPX/WETH lp claim rewards weekly, converts DPX claimed to USDC, adds USDC
///           to curve 2pool, gets 2CRV, uses 2CRV to purchase puts and write puts.
/// @title: Dopex Strategy
/// @author: c-n-o-t-e

pragma solidity ^0.8.9;

import "./interface/ISSOV.sol";
import "./interface/I2Pool.sol";
import "./interface/IDpxEthLpFarm.sol";
import "./interface/ISushiSwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error DopexStrategy_NotOwner();
error DopexStrategy_EpochExpired();
error DopexStrategy_NotUpToAWeek();
error DopexStrategy_InvalidStike();
error DopexStrategy_AmountAboveBalance();
error DopexStrategy_ReducePurchasePercent();
error DopexStrategy_ContractHasNoDpxToken();
error DopexStrategy_ContractHasNo2crvToken();
error DopexStrategy_ContractHasNoUsdcToken();

contract DopexStrategy {
    using SafeERC20 for IERC20;
    event StrategyExecuted(
        uint256 contractDpxBalanceBeforeTx,
        uint256 contractUsdcBalanceBeforeTx,
        uint256 contract2PoolBalanceBeforeTx,
        uint256 purchaseAmount,
        uint256 writeAmount
    );

    // s indicating variables are stored in storage
    uint256 public s_timer;
    address public s_owner;

    I2Pool public immutable pool;
    ISushiSwapRouter public immutable router;
    IDpxEthLpFarm public immutable dpxEthLpFarm;

    address constant dpx = 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55;
    address constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant twoPool = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address constant DpxEthLp = 0x0C1Cf6883efA1B496B01f654E247B9b419873054;

    constructor(
        address _dpxEthLpFarm,
        address _sushiRouter,
        address _curvePool
    ) {
        s_owner = msg.sender;

        pool = I2Pool(_curvePool);
        router = ISushiSwapRouter(_sushiRouter);
        dpxEthLpFarm = IDpxEthLpFarm(_dpxEthLpFarm);

        // IERC20(usdc).safeApprove(twoPool, type(uint256).max);
        // IERC20(dpx).safeApprove(address(router), type(uint256).max);
        // IERC20(DpxEthLp).safeApprove(_dpxEthLpFarm, type(uint256).max);
    }

    /// @notice deposits DPX/WETH lp and stake in dpxEthLpFarm
    /// - this contract must be whitelisted by the dpxEthLpFarm contract
    /// - this contract must have been approved _amount
    /// - set timer if it's the first interaction
    /// @param _amount amount of DPX/WETH pair
    function deposit(uint256 _amount) external {
        if (_amount > IERC20(DpxEthLp).balanceOf(msg.sender))
            revert DopexStrategy_AmountAboveBalance();
        IERC20(DpxEthLp).safeTransferFrom(msg.sender, address(this), _amount);

        dpxEthLpFarm.stake(_amount);

        // making this unchecked to save gas used for checking arithmetic operations
        unchecked {
            if (s_timer == 0) s_timer = block.timestamp + 7 days;
        }
    }

    /// @notice runs strategy
    /// - this contract must be whitelisted by the SSOV contract
    /// - only works when timer is below block.timestamp
    /// @param _strikeIndex strikeIndex Index of strike
    /// @param _sushiSlippage minimum slippage when using the _swap function....i.e 95% will be 950
    /// @param _curveSlippage minimum slippage when using the _get2poolToken function....i.e 95% will be 950
    /// @param _purchasePercent percentage you wish to purchase put with excluding premium and total fee
    /// @param _ssovAddress address of SSOV to purchase and write puts
    function runStrategy(
        uint256 _strikeIndex,
        uint256 _sushiSlippage,
        uint256 _curveSlippage,
        uint256 _purchasePercent,
        address _ssovAddress
    ) external {
        if (s_timer > block.timestamp) revert DopexStrategy_NotUpToAWeek();
        dpxEthLpFarm.claim();

        uint256 contractDpxBalanceBeforeTx = _getBalance(dpx);
        _swap(_sushiSlippage);

        uint256 contractUsdcBalanceBeforeTx = _getBalance(usdc);
        _get2poolToken(IERC20(usdc).balanceOf(address(this)), _curveSlippage);

        uint256 contract2PoolBalanceBeforeTx = _getBalance(twoPool);
        (uint256 purchaseAmount, uint256 writeAmount) = _excuteStrategy(
            _ssovAddress,
            _strikeIndex,
            _purchasePercent
        );

        unchecked {
            s_timer = block.timestamp + 7 days;
        }

        emit StrategyExecuted(
            contractDpxBalanceBeforeTx,
            contractUsdcBalanceBeforeTx,
            contract2PoolBalanceBeforeTx,
            purchaseAmount,
            writeAmount
        );
    }

    /// @notice withdraws token
    /// - only owner can call this function
    /// @param _token token to withdraw from
    /// @param _to receivers address
    /// @param _amount amount to withdraw
    function withdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_amount > IERC20(_token).balanceOf(address(this)))
            revert DopexStrategy_AmountAboveBalance();
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice checks this contract balance
    /// - checks balance and revert if equals to 0
    /// @param _token contract address to get balance from
    function _getBalance(address _token)
        internal
        view
        returns (uint256 contractBalance)
    {
        contractBalance = IERC20(_token).balanceOf(address(this));
        if (contractBalance < 0 && _token == dpx)
            revert DopexStrategy_ContractHasNoDpxToken();
        if (contractBalance < 0 && _token == usdc)
            revert DopexStrategy_ContractHasNoUsdcToken();
        if (contractBalance < 0 && _token == twoPool)
            revert DopexStrategy_ContractHasNo2crvToken();
    }

    /// @notice swaps DPX to USDC
    /// @param _sushiSlippage minimum slippage when using the _swap function....i.e 95% will be 950
    function _swap(uint256 _sushiSlippage) internal {
        address[] memory path = new address[](3);
        path[0] = dpx;
        path[1] = weth;
        path[2] = usdc;

        uint256[] memory amountsMin = router.getAmountsOut(
            IERC20(dpx).balanceOf(address(this)),
            path
        );
        uint256 sushiSlippage = (amountsMin[path.length - 1] * _sushiSlippage) /
            1000;

        router.swapExactTokensForTokens(
            IERC20(dpx).balanceOf(address(this)),
            sushiSlippage,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice add contract USDC to curve 2pool
    /// @param _contractUsdcBalance USDC balance of this contract
    /// @param _curveSlippage minimum slippage when using the _get2poolToken function....i.e 95% will be 950
    function _get2poolToken(
        uint256 _contractUsdcBalance,
        uint256 _curveSlippage
    ) internal {
        uint256[2] memory deposit_amounts;
        uint256 amountMin;

        if (pool.coins(0) == usdc) {
            deposit_amounts[0] = _contractUsdcBalance;
            deposit_amounts[1] = 0;
        } else if (pool.coins(1) == usdc) {
            deposit_amounts[0] = 0;
            deposit_amounts[1] = _contractUsdcBalance;
        }

        amountMin = pool.calc_token_amount(deposit_amounts, true);
        uint256 curveSlippage = (amountMin * _curveSlippage) / 1000;
        pool.add_liquidity(deposit_amounts, curveSlippage);
    }

    /// @notice excutes strategy
    /// - this contract must be whitelisted by the SSOV contract
    /// - only works when timer is below block.timestamp
    /// @param _ssovAddress address of SSOV to purchase and write puts
    /// @param _strikeIndex strikeIndex Index of strike
    /// @param _purchasePercent percentage you wish to purchase put with excluding premium and total fee
    function _excuteStrategy(
        address _ssovAddress,
        uint256 _strikeIndex,
        uint256 _purchasePercent
    ) internal returns (uint256 purchaseAmount, uint256 writeAmount) {
        uint256 epoch = ISSOV(_ssovAddress).currentEpoch();
        (, uint256 epochExpiry) = ISSOV(_ssovAddress).getEpochTimes(epoch);

        if (block.timestamp > epochExpiry) revert DopexStrategy_EpochExpired();

        uint256[] memory strikes = ISSOV(_ssovAddress).getEpochStrikes(epoch);
        if (strikes[_strikeIndex] <= 0) revert DopexStrategy_InvalidStike();

        purchaseAmount =
            (IERC20(twoPool).balanceOf(address(this)) * _purchasePercent) /
            1000;
        uint256 premium = ISSOV(_ssovAddress).calculatePremium(
            strikes[_strikeIndex],
            purchaseAmount,
            epochExpiry
        );

        uint256 fee = ISSOV(_ssovAddress).calculatePurchaseFees(
            strikes[_strikeIndex],
            purchaseAmount
        );
        if (premium + fee > IERC20(twoPool).balanceOf(address(this)))
            revert DopexStrategy_ReducePurchasePercent();

        IERC20(twoPool).safeApprove(
            _ssovAddress,
            IERC20(twoPool).balanceOf(address(this))
        );
        ISSOV(_ssovAddress).purchase(
            _strikeIndex,
            purchaseAmount,
            address(this)
        );

        uint256 contract2crvBalanceLeft = IERC20(twoPool).balanceOf(
            address(this)
        );

        if (contract2crvBalanceLeft > 0) writeAmount = contract2crvBalanceLeft;
        ISSOV(_ssovAddress).deposit(_strikeIndex, writeAmount, address(this));
    }

    modifier onlyOwner() {
        if (msg.sender == s_owner) revert DopexStrategy_NotOwner();
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface ISSOV {
    function purchase(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256 premium, uint256 totalFee);

    function deposit(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256 tokenId);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function currentEpoch() external view returns (uint256 epoch);

    function calculatePurchaseFees(uint256 strike, uint256 amount)
        external
        view
        returns (uint256);

    function getEpochStrikes(uint256 epoch)
        external
        view
        returns (uint256[] memory);

    function getEpochTimes(uint256 epoch)
        external
        view
        returns (uint256 start, uint256 end);

    function addToContractWhitelist(address owner) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface I2Pool {
    function coins(uint256 arg0) external returns (address);

    function calc_token_amount(uint256[2] calldata amounts, bool _h)
        external
        returns (uint256);

    function add_liquidity(
        uint256[2] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IDpxEthLpFarm {
    function claim() external;

    function stake(uint256 amount) external;

    function addToContractWhitelist(address owner) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface ISushiSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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