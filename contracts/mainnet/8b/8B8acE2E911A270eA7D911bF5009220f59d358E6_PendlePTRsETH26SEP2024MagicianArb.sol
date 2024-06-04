// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity >=0.7.6 <0.9.0;

/// @notice Extension for the Liquidation helper to support such operations as unwrapping
interface IMagician {
    /// @notice Operates to unwrap an `_asset`
    /// @param _asset Asset to be unwrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the `tokenOut` that we received
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);

    /// @notice Performs operation opposit to `towardsNative`
    /// @param _asset Asset to be wrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the quote token that we spent to get `_amoun` of the `_asset`
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICamelotSwapRouterLike {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

     function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IStandardizedYield.sol";
import "./IPPrincipalToken.sol";
import "./IPYieldToken.sol";

// solhint-disable var-name-mixedcase

interface IPMarket {
    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactPt(
        address receiver,
        uint256 exactPtOut,
        bytes calldata data
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function readTokens()
        external
        view
        returns (IStandardizedYield _SY, IPPrincipalToken _PT, IPYieldToken _YT);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IPPrincipalToken {
    function transfer(address user, uint256 amount) external;
    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IPYieldToken {
    function redeemPY(address receiver) external returns (uint256 amountSyOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IStandardizedYield {
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMagician.sol";
import "./PendleMagician.sol";
import "./interfaces/camelot/ICamelotSwapRouterLike.sol";

abstract contract PendleCamelotMagicianV2 is PendleMagician, IMagician {
    // solhint-disable
    ICamelotSwapRouterLike public constant ROUTER = ICamelotSwapRouterLike(0x1F721E2E82F6676FCE4eA07A5958cF098D339e18);
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public immutable UNDERLYING;
    // solhint-enable

    constructor(
        address _asset,
        address _market,
        address _underlying
    ) PendleMagician(_asset, _market) {
        UNDERLYING = _underlying;
    }

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address asset, uint256 amount) {
        if (_asset != address(PENDLE_TOKEN)) revert InvalidAsset();

        uint256 amountUnderlying = _sellPtForUnderlying(_amount, UNDERLYING);

        IERC20(UNDERLYING).approve(address(ROUTER), amountUnderlying);

        asset = WETH;
        amount = _camelotSwap(amountUnderlying);
    }

    /// @inheritdoc IMagician
    // solhint-disable-next-line named-return-values
    function towardsAsset(address, uint256) external pure returns (address, uint256) {
        revert Unsupported();
    }

    function _camelotSwap(uint256 _amountIn) internal returns (uint256 amountWeth) {
        ICamelotSwapRouterLike.ExactInputSingleParams memory params = ICamelotSwapRouterLike.ExactInputSingleParams({
            tokenIn: UNDERLYING,
            tokenOut: WETH,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 1,
            limitSqrtPrice: 0
        });

        return ROUTER.exactInputSingle(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IStandardizedYield.sol";
import "./interfaces/IPPrincipalToken.sol";
import "./interfaces/IPYieldToken.sol";
import "./interfaces/IPMarket.sol";

abstract contract PendleMagician {
    // solhint-disable
    address public immutable PENDLE_TOKEN;
    address public immutable PENDLE_MARKET;
    // solhint-enable

    bytes internal constant _EMPTY_BYTES = abi.encode();

    error InvalidAsset();
    error Unsupported();

    constructor(address _asset, address _market) {
        PENDLE_TOKEN = _asset;
        PENDLE_MARKET = _market;
    }

    function _sellPtForUnderlying(uint256 _netPtIn, address _tokenOut) internal returns (uint256 netTokenOut) {
        // solhint-disable-next-line var-name-mixedcase
        (IStandardizedYield SY, IPPrincipalToken PT, IPYieldToken YT) = IPMarket(PENDLE_MARKET)
            .readTokens();

        uint256 netSyOut;
        if (PT.isExpired()) {
            PT.transfer(address(YT), _netPtIn);
            netSyOut = YT.redeemPY(address(SY));
        } else {
            // safeTransfer not required
            PT.transfer(PENDLE_MARKET, _netPtIn);
            (netSyOut, ) = IPMarket(PENDLE_MARKET).swapExactPtForSy(
                address(SY), // better gas optimization to transfer SY directly to itself and burn
                _netPtIn,
                _EMPTY_BYTES
            );
        }

        // solhint-disable-next-line func-named-parameters
        netTokenOut = SY.redeem(address(this), netSyOut, _tokenOut, 0, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./PendleCamelotMagicianV2.sol";

contract PendlePTRsETH26SEP2024MagicianArb is PendleCamelotMagicianV2 {
    constructor() PendleCamelotMagicianV2(
        0x30c98c0139B62290E26aC2a2158AC341Dcaf1333, // PT Token
        0xED99fC8bdB8E9e7B8240f62f69609a125A0Fbf14, // PT Market
        0x4186BFC76E2E237523CBC30FD220FE055156b41F  // Underlying
    ) {}
}