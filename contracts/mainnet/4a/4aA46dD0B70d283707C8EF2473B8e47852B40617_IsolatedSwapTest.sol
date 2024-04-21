// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAdapterV1, Account, SwapData} from "./interfaces/IAdapterV1.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {IOneInchV5AggregationRouter, SwapDescription} from "./interfaces/IOneInchV5AggregationRouter.sol";
import {IRamsesFactory, IRamsesRouter, IRamsesPair} from "./interfaces/IRamses.sol";

contract IsolatedSwapTest {
    constructor() {}

    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant PSM_TOKEN_ADDRESS =
        0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS =
        0x1111111254EEB25477B68fb85Ed929f73A960582;
    address constant RAMSES_FACTORY_ADDRESS =
        0xAAA20D08e59F6561f242b08513D36266C5A29415;
    address constant RAMSES_ROUTER_ADDRESS =
        0xAAA87963EFeB6f7E0a2711F397663105Acb1805e;

    IERC20 PSM = IERC20(PSM_TOKEN_ADDRESS);
    IERC20 constant WETH = IERC20(WETH_ADDRESS);

    IOneInchV5AggregationRouter public constant ONE_INCH_V5_AGGREGATION_ROUTER =
        IOneInchV5AggregationRouter(
            ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS
        ); // Interface of 1inchRouter
    IRamsesFactory public constant RAMSES_FACTORY =
        IRamsesFactory(RAMSES_FACTORY_ADDRESS); // Interface of Ramses Factory
    IRamsesRouter public constant RAMSES_ROUTER =
        IRamsesRouter(RAMSES_ROUTER_ADDRESS); // Interface of Ramses Router

    function resuceToken(address _token) external {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, balance);
    }

    /////////////////////////
    /////////////////////////
    // This function takes PSM from caller, then triggers 1Inch swap or LP pooling
    // Amount of PSM taken is _amountInputPE
    function sellPortalEnergy(
        address payable _recipient,
        uint256 _amountInputPE,
        uint256 _minReceived,
        uint256 _deadline,
        uint256 _mode,
        bytes calldata _actionData
    ) external {
        if (_mode > 2) revert ErrorsLib.InvalidMode();

        /// @dev Assemble the swap data from API to use 1Inch Router
        SwapData memory swap = SwapData(
            _recipient,
            _amountInputPE,
            _actionData
        );

        // use the variables to avoid warning
        _minReceived = 1;
        _deadline = block.timestamp;

        // transfer PSM from caller to contract to then be used in swap
        PSM.safeTransferFrom(msg.sender, address(this), _amountInputPE);

        /// @dev Add liquidity, or exchange on 1Inch and transfer output token
        if (_mode == 1) {
            addLiquidity(swap);
        } else {
            swapOneInch(swap, false);
        }
    }

    /// @dev This internal function assembles the swap via the 1Inch router from API data
    function swapOneInch(SwapData memory _swap, bool _forLiquidity) internal {
        /// @dev decode the data for getting _executor, _description, _data.
        (
            address _executor,
            SwapDescription memory _description,
            bytes memory _data,
            ,

        ) = abi.decode(
                _swap.actionData,
                (address, SwapDescription, bytes, uint256, uint256)
            );

        /// @dev Swap via the 1Inch Router
        /// @dev Allowance is increased in separate function to save gas
        (, uint256 spentAmount_) = ONE_INCH_V5_AGGREGATION_ROUTER.swap(
            _executor,
            _description,
            "",
            _data
        );

        /// @dev Send remaining tokens back to user if not called from addLiquidity
        if (!_forLiquidity) {
            uint256 remainAmount = _swap.psmAmount - spentAmount_;
            if (remainAmount > 0) PSM.safeTransfer(msg.sender, remainAmount);
        }
    }

    /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @dev This is used to determine how many assets must be supplied to a Pool2 LP
    function quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert ErrorsLib.InvalidAmount();
        if (reserveA == 0 || reserveB == 0)
            revert ErrorsLib.InsufficientReserves();

        amountB = (amountA * reserveB) / reserveA;
    }

    /// @dev This function is called when mode = 1 in sellPortalEnergy
    /// @dev Sell some amount of PSM for WETH, then pair in Ramses Pool2
    function addLiquidity(SwapData memory _swap) internal {
        swapOneInch(_swap, true);

        /// @dev Decode the swap data for getting minPSM and minWETH.
        (, , , uint256 minPSM, uint256 minWeth) = abi.decode(
            _swap.actionData,
            (address, SwapDescription, bytes, uint256, uint256)
        );

        /// @dev This contract shouldn't hold any token, so we pass all tokens.
        uint256 PSMBalance = PSM.balanceOf(address(this));
        uint256 WETHBalance = WETH.balanceOf(address(this));

        /// @dev Get the correct amount of PSM and WETH to add to the Ramses Pool2
        (uint256 amountPSM, uint256 amountWETH) = _addLiquidity(
            PSMBalance,
            WETHBalance,
            minPSM,
            minWeth
        );

        /// @dev Get the pair address of the ETH/PSM Pool2 LP
        address pair = RAMSES_FACTORY.getPair(
            PSM_TOKEN_ADDRESS,
            WETH_ADDRESS,
            false
        );

        /// @dev Transfer tokens to the LP and mint LP shares to the user
        /// @dev Uses the low level mint function of the pair implementation
        /// @dev Assumes that the pair already exists which is the case
        PSM.safeTransfer(pair, amountPSM);
        WETH.safeTransfer(pair, amountWETH);
        IRamsesPair(pair).mint(_swap.recevier);
    }

    /// @dev Calculate the required token amounts of PSM and WETH to add liquidity
    function _addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (amountADesired < amountAMin) revert ErrorsLib.InvalidAmount();
        if (amountBDesired < amountBMin) revert ErrorsLib.InvalidAmount();

        /// @dev Get the pair address
        address pair = RAMSES_FACTORY.getPair(
            PSM_TOKEN_ADDRESS,
            WETH_ADDRESS,
            false
        );

        /// @dev Get the reserves of the pair
        (uint256 reserveA, uint256 reserveB, ) = IRamsesPair(pair)
            .getReserves();

        /// @dev Calculate how much PSM and WETH are required
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin)
                    revert ErrorsLib.InvalidAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                if (amountAOptimal > amountADesired)
                    revert ErrorsLib.InvalidAmount();
                if (amountAOptimal < amountAMin)
                    revert ErrorsLib.InvalidAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @dev Increase token spending allowances of Adapter holdings
    function increaseAllowances() external {
        PSM.approve(ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS, MAX_UINT);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IRamsesPair {
    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );
}

interface IRamsesFactory {
    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);
}

interface IRamsesRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function quoteAddLiquidity(
        address _tokenA,
        address _tokenB,
        bool _stable,
        uint256 _amountADesired,
        uint256 _amountBDesired
    )
        external
        view
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function quoteRemoveLiquidity(
        address _tokenA,
        address _tokenB,
        bool _stable,
        uint256 _liquidity
    ) external view returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

struct SwapDescription {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IOneInchV5AggregationRouter {
    /// @notice Performs a swap, delegating all calls encoded in `data` to `_executor`.
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param _executor Aggregation _executor that executes calls described in `data`
    /// @param _desc Swap description
    /// @param _permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param _data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount_ Resulting token amount
    /// @return spentAmount_ Source token amount
    function swap(
        address _executor,
        SwapDescription calldata _desc,
        bytes calldata _permit,
        bytes calldata _data
    ) external payable returns (uint256 returnAmount_, uint256 spentAmount_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

// ============================================
// ==          CUSTOM ERROR MESSAGES         ==
// ============================================
library ErrorsLib {
    error DeadlineExpired();
    error DurationLocked();
    error DurationTooLow();
    error EmptyAccount();
    error InsufficientBalance();
    error InsufficientReceived();
    error InsufficientStakeBalance();
    error InsufficientToWithdraw();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidConstructor();
    error NativeTokenNotAllowed();
    error TokenExists();
    error FailedToSendNativeToken();

    error InvalidMode();
    error InsufficientReserves();
    error notOwner();
    error isMigrating();
    error notMigrating();
    error migrationVotePending();
    error notCalledByDestination();
    error TokenNotSet();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

struct Account {
    uint256 lastUpdateTime;
    uint256 lastMaxLockDuration;
    uint256 stakedBalance;
    uint256 maxStakeDebt;
    uint256 portalEnergy;
}

struct SwapData {
    address recevier;
    uint256 psmAmount;
    bytes actionData;
}

interface IAdapterV1 {
    function stake(address _receiver, uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function mintPortalEnergyToken(
        address _recipient,
        uint256 _amount
    ) external;

    function burnPortalEnergyToken(
        address _recipient,
        uint256 _amount
    ) external;

    function buyPortalEnergy(
        address _user,
        uint256 _amount,
        uint256 _minReceived,
        uint256 _deadline
    ) external;

    function sellPortalEnergy(
        address payable _receiver,
        uint256 _amount,
        uint256 _minReceivedPSM,
        uint256 _deadline,
        uint256 _mode,
        bytes calldata _actionData
    ) external;

    function addLiquidity(
        address _receiver,
        uint256 amountPSMDesired,
        uint256 amountWETHDesired,
        uint256 amountPSMMin,
        uint256 amountWETHMin,
        uint256 _deadline
    )
        external
        returns (uint256 amountPSM, uint256 amountWETH, uint256 liquidity);

    function addLiquidityETH(
        address _receiver,
        uint256 _amountPSMDesired,
        uint256 _amountPSMMin,
        uint256 _amountETHMin,
        uint256 _deadline
    )
        external
        payable
        returns (uint256 amountPSM, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address _receiver,
        uint256 _liquidity,
        uint256 _amountPSMMin,
        uint256 _amountWETHMin,
        uint256 _deadline
    ) external returns (uint256 amountPSM, uint256 amountWETH);

    function removeLiquidityETH(
        address _receiver,
        uint256 _liquidity,
        uint256 _amountPSMMin,
        uint256 _amountETHMin,
        uint256 _deadline
    ) external returns (uint256 amountPSM, uint256 amountETH);

    function getUpdateAccount(
        address _user,
        uint256 _amount
    )
        external
        view
        returns (address, uint256, uint256, uint256, uint256, uint256, uint256);

    function quoteforceUnstakeAll(
        address _user
    ) external view returns (uint256 portalEnergyTokenToBurn);

    function quoteBuyPortalEnergy(
        uint256 _amountInput
    ) external view returns (uint256);

    function quoteSellPortalEnergy(
        uint256 _amountInput
    ) external view returns (uint256);

    function quoteAddLiquidity(
        uint256 _amountADesired,
        uint256 _amountBDesired
    )
        external
        view
        returns (
            uint256 _amountPSMDesired,
            uint256 _amountWETHDesired,
            uint256 liquidity
        );

    function quoteRemoveLiquidity(
        uint256 _liquidity
    ) external view returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IWETH {
    function deposit() external payable;

    function withdrawTo(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

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