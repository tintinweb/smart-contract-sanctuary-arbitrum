// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXRouter {
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);
    function compound() external;
    function claimFees() external;
    function feeGlpTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function glpManager() external view returns (address);
    function glp() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILodeReward {
    function claim() external returns (uint256);
}

interface ILodeComp {
    function mint(uint256 mintAmount) external returns(uint);
    function redeem(uint256 redeemAmount) external returns(uint);
    function borrow(uint256 borrowAmount) external returns(uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

interface ILodeTroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint); 
    function claimComp(address holder) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IOpenOceanExchange {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPendleMarket {
    function redeemRewards(address user) external returns (uint256[] memory);
    function getRewardTokens() external view returns (address[] memory);
    function mint(
        address receiver,
        uint256 netSyDesired,
        uint256 netPtDesired
    )
        external

        returns (
            uint256 netLpOut,
            uint256 netSyUsed,
            uint256 netPtUsed
        );
}


interface IPendleRouter {
    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain; // pass 0 in to skip this variable
        uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
        uint256 eps;
    }
    struct TokenInput {
        // Token/Sy data
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }
    struct TokenOutput {
        // Token/Sy data
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netSyFee);
    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);
    function addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy
    ) external returns (uint256 netLpOut, uint256 netSyFee);
    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy
    ) external returns (uint256 netPtOut, uint256 netSyFee);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPirex {
    /**
        @notice Deposit GMX for pxGMX
        @param  amount         uint256  GMX amount
        @param  receiver       address  pxGMX receiver
        @return postFeeAmount  uint256  pxGMX minted for the receiver
        @return feeAmount      uint256  pxGMX distributed as fees
     */
    function depositGmx(uint256 amount, address receiver) external returns (uint256 postFeeAmount, uint256 feeAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ITenderComp {
    function mint(uint256 mintAmount) external returns(uint);
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns(uint);
    function borrow(uint256 borrowAmount) external returns(uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

interface ITenderTroller {
    function enterMarkets(address[] calldata cTokens)  external returns (uint[] memory);
    function exitMarket(address cToken)  external returns (uint); 
    function claimComp(address holder) external;
}

interface ITenderInstantVester{
    function instantVest(uint256 amount) external;
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { IOpenOceanExchange, IOpenOceanCaller } from '../interfaces/IOpenOceanExchange.sol';
import { IPendleRouter } from '../interfaces/IPendle.sol';
import { IGMXRouter } from '../interfaces/gmx/IGMXRouter.sol';
import { ILodeComp, ILodeTroller } from '../interfaces/ILodeStar.sol';
import { IPirex } from '../interfaces/IPirex.sol';
import { ITenderComp, ITenderTroller } from '../interfaces/ITender.sol';

interface IGlpVault {
    function whitelistedTokens(address _token) external returns (bool);
}

interface ISiloRouter {
    // @notice Action types that are supported
    enum ActionType {
        Deposit,
        Withdraw,
        Borrow,
        Repay
    }

    struct Action {
        // what do you want to do?
        uint8 actionType;
        // which Silo are you interacting with?
        address silo;
        // what asset do you want to use?
        address asset;
        // how much asset do you want to use?
        uint256 amount;
        // is it an action on collateral only?
        bool collateralOnly;
    }

    function execute(Action[] calldata _actions) external payable;
}

contract Zap is Ownable {

    uint256 constant TOLERANCE = 10000;  // 10000 represents 1% in a 10^6 (six decimals) based number
    uint256 constant ONE = 1000000;  // 100% in six decimals

    error NOT_WHITELISTED(); // 0xbffbc6be

    error WRONG_TOKEN_IN(); // 0xf6b8648c

    error WRONG_TOKEN_OUT(); // 0x5e8f1f5b

    error WRONG_AMOUNT(); // 0xc6ea1a16

    error WRONG_DST(); // 0xcb0b65a6

    error SWAP_ERROR(); // 0xcbe60bba

    error SWAP_METHOD_NOT_IDENTIFIED(); // 0xc257a710

    address public uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public openOceanRouter = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;
    address public siloRouter = 0x9992f660137979C1ca7f8b119Cd16361594E3681;
    address public plpRouter = 0x0000000001E4ef00d069e71d6bA041b0A16F7eA0;

    address public wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public rETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

    event Zapped(address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    function getGLP(address _token, uint256 _amount, bytes calldata _data, uint256 _minOut) external returns (uint256) {
        address GLPRouter = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
        address GLPManager = 0x3963FfC9dff443c2A94f21b129D429891E32ec18;
        address GLPVault = 0x489ee077994B6658eAfA855C308275EAd8097C4A;

        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

        require(_token != sGLP, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (!IGlpVault(GLPVault).whitelistedTokens(_token)) {
            swapOpenOcean(_token, USDCe, _amount, _data);
            _token = USDCe;
            _amount = IERC20(USDCe).balanceOf(address(this));
        }

        IERC20(_token).approve(GLPManager, _amount);
        uint256 glpAmount = IGMXRouter(GLPRouter).mintAndStakeGlp(_token, _amount, 0, _minOut);
        IERC20(sGLP).transfer(msg.sender, glpAmount);
        emit Zapped(_token, _amount, sGLP, glpAmount);
        return glpAmount;
    }

    function returnGLP(address _token, uint256 _amount, address _to, bytes calldata _data, uint256 _minOut) external returns (uint256) {
        address GLPRouter = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
        address GLPVault = 0x489ee077994B6658eAfA855C308275EAd8097C4A;

        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

        require(_token != sGLP, "cannot swap token to itself");
        IERC20(sGLP).transferFrom(msg.sender, address(this), _amount);

        uint256 tokenAmount;

        if (!IGlpVault(GLPVault).whitelistedTokens(_token)) {
            uint256 usdceAmount = IGMXRouter(GLPRouter).unstakeAndRedeemGlp(USDCe, _amount, 0, address(this));
            swapOpenOcean(USDCe, _token, usdceAmount, _data);
            tokenAmount = IERC20(USDCe).balanceOf(address(this));
            IERC20(_token).transfer(_to, tokenAmount);
        } else {
            tokenAmount = IGMXRouter(GLPRouter).unstakeAndRedeemGlp(_token, _amount, _minOut, _to);
        }
        emit Zapped(sGLP, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getwstPLP(address _token, uint256 _amount, bytes calldata _data, uint256 _minOut) external payable returns (uint256) {
        address ptwstETH = 0x1255638EFeca62e12E344E0b6B22ea853eC6e2c7;
        address wstPLP = 0x08a152834de126d2ef83D612ff36e4523FD0017F;

        require(_token != wstPLP, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (_token != wstETH) {
            swapOpenOcean(_token, wstETH, _amount, _data);
            _amount = IERC20(wstETH).balanceOf(address(this));
        }

        IPendleRouter.SwapData memory swapData = IPendleRouter.SwapData({
            swapType: IPendleRouter.SwapType.NONE,
            extRouter: address(0),
            extCalldata: '0x',
            needScale: false
        });
        IPendleRouter.TokenInput memory tokenInput = IPendleRouter.TokenInput({
            tokenIn: wstETH,
            netTokenIn: _amount,
            tokenMintSy: wstETH,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });
        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0, // pass 0 in to skip this variable
            maxIteration: 256, // every iteration, the diff between guessMin and guessMax will be divided by 2
            eps: 1e15
        });

        IERC20(wstETH).approve(plpRouter, _amount);
        (uint256 netOut, ) = IPendleRouter(plpRouter).swapExactTokenForPt(address(this), wstPLP, 0, approx, tokenInput);

        IERC20(ptwstETH).approve(plpRouter, netOut);
        (uint256 plpAmount, ) = IPendleRouter(plpRouter).addLiquiditySinglePt(address(this), wstPLP, netOut, _minOut, approx);

        IERC20(wstPLP).transfer(msg.sender, plpAmount);
        emit Zapped(_token, _amount, wstPLP, plpAmount);
        return plpAmount;
    }

    function returnwstPLP(address _token, uint256 _amount, address _to, bytes calldata _data, uint256 _minOut) external payable returns (uint256) {
        address ptwstETH = 0x1255638EFeca62e12E344E0b6B22ea853eC6e2c7;
        address wstPLP = 0x08a152834de126d2ef83D612ff36e4523FD0017F;

        require(_token != wstPLP, "cannot swap token to itself");
        IERC20(wstPLP).transferFrom(msg.sender, address(this), _amount);
        IERC20(wstPLP).approve(plpRouter, _amount);

        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0, // pass 0 in to skip this variable
            maxIteration: 256, // every iteration, the diff between guessMin and guessMax will be divided by 2
            eps: 1e15
        });
        (uint256 ptwstETHAmount, ) = IPendleRouter(plpRouter).removeLiquiditySinglePt(address(this), wstPLP, _amount, _minOut, approx);

        IPendleRouter.SwapData memory swapData = IPendleRouter.SwapData({
            swapType: IPendleRouter.SwapType.NONE,
            extRouter: address(0),
            extCalldata: '0x',
            needScale: false
        });
        IPendleRouter.TokenOutput memory tokenOutput = IPendleRouter.TokenOutput({
            tokenOut: wstETH,
            minTokenOut: 0,
            tokenRedeemSy: wstETH,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });
        IERC20(ptwstETH).approve(plpRouter, ptwstETHAmount);
        (uint256 tokenAmount, ) = IPendleRouter(plpRouter).swapExactPtForToken(address(this), wstPLP, ptwstETHAmount, tokenOutput);

        if (_token != wstETH) {
            swapOpenOcean(wstETH, _token, tokenAmount, _data);
            tokenAmount = IERC20(_token).balanceOf(address(this));
        }

        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(wstPLP, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getrPLP(address _token, uint256 _amount, bytes calldata _data, uint256 _minOut) external payable returns (uint256) {
        address ptrETH = 0x685155D3BD593508Fe32Be39729810A591ED9c87;
        address rPLP = 0x14FbC760eFaF36781cB0eb3Cb255aD976117B9Bd;

        require(_token != rPLP, "cannot swap token to itself"); 
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (_token != rETH) {
            swapOpenOcean(_token, rETH, _amount, _data);
            _amount = IERC20(rETH).balanceOf(address(this));
        }

        IPendleRouter.SwapData memory swapData = IPendleRouter.SwapData({
            swapType: IPendleRouter.SwapType.NONE,
            extRouter: address(0),
            extCalldata: '0x',
            needScale: false
        });
        IPendleRouter.TokenInput memory tokenInput = IPendleRouter.TokenInput({
            tokenIn: rETH,
            netTokenIn: _amount,
            tokenMintSy: rETH,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });
        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0, // pass 0 in to skip this variable
            maxIteration: 256, // every iteration, the diff between guessMin and guessMax will be divided by 2
            eps: 1e15
        });

        IERC20(rETH).approve(plpRouter, _amount);
        (uint256 netOut, ) = IPendleRouter(plpRouter).swapExactTokenForPt(address(this), rPLP, 0, approx, tokenInput);

        IERC20(ptrETH).approve(plpRouter, netOut);
        (uint256 plpAmount, ) = IPendleRouter(plpRouter).addLiquiditySinglePt(address(this), rPLP, netOut, _minOut, approx);

        IERC20(rPLP).transfer(msg.sender, plpAmount);
        emit Zapped(_token, _amount, rPLP, plpAmount);
        return plpAmount;
    }

    function returnrPLP(address _token, uint256 _amount, address _to, bytes calldata _data, uint256 _minOut) external returns (uint256) {
        address ptrETH = 0x685155D3BD593508Fe32Be39729810A591ED9c87;
        address rPLP = 0x14FbC760eFaF36781cB0eb3Cb255aD976117B9Bd;

        require(_token != rPLP, "cannot swap token to itself"); 
        IERC20(rPLP).transferFrom(msg.sender, address(this), _amount);
        IERC20(rPLP).approve(plpRouter, _amount);

        IPendleRouter.ApproxParams memory approx = IPendleRouter.ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0, // pass 0 in to skip this variable
            maxIteration: 256, // every iteration, the diff between guessMin and guessMax will be divided by 2
            eps: 1e15
        });
        (uint256 ptrETHAmount, ) = IPendleRouter(plpRouter).removeLiquiditySinglePt(address(this), rPLP, _amount, _minOut, approx);

        IPendleRouter.SwapData memory swapData = IPendleRouter.SwapData({
            swapType: IPendleRouter.SwapType.NONE,
            extRouter: address(0),
            extCalldata: '0x',
            needScale: false
        });
        IPendleRouter.TokenOutput memory tokenOutput = IPendleRouter.TokenOutput({
            tokenOut: rETH,
            minTokenOut: 0,
            tokenRedeemSy: rETH,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });
        IERC20(ptrETH).approve(plpRouter, ptrETHAmount);
        (uint256 tokenAmount, ) = IPendleRouter(plpRouter).swapExactPtForToken(address(this), rPLP, ptrETHAmount, tokenOutput);

        if (_token != rETH) {
            swapOpenOcean(rETH, _token, tokenAmount, _data);
            tokenAmount = IERC20(_token).balanceOf(address(this));
        }

        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(rPLP, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getJOE(address _token, uint256 _amount, bytes calldata _data) external payable returns (uint256) {
        address JOE = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;

        require(_token != JOE, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        swapOpenOcean(_token, JOE, _amount, _data);
        uint256 joeAmount = IERC20(JOE).balanceOf(address(this));
        IERC20(JOE).transfer(msg.sender, joeAmount);
        emit Zapped(_token, _amount, JOE, joeAmount);
        return joeAmount;
    }

    function returnJOE(address _token, uint256 _amount, address _to, bytes calldata _data) external returns (uint256) {
        address JOE = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;

        require(_token != JOE, "cannot swap token to itself");
        IERC20(JOE).transferFrom(msg.sender, address(this), _amount);

        swapOpenOcean(JOE, _token, _amount, _data);
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(JOE, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getSiloGMX(address _token, uint256 _amount, bytes calldata _data) external payable returns (uint256) {
        address sUSDC_GMX = 0x96E1301bd2536A3C56EBff8335FD892dD9bD02dC;
        address siloGMX = 0xDe998E5EeF06dD09fF467086610B175F179A66A0;
        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != sUSDC_GMX, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (_token != USDCe) {
            swapOpenOcean(_token, USDCe, _amount, _data);
            _token = USDCe;
            _amount = IERC20(USDCe).balanceOf(address(this));
        }
        IERC20(_token).approve(siloRouter, _amount);
        ISiloRouter.Action[] memory _actions = new ISiloRouter.Action[](1);
        _actions[0] = ISiloRouter.Action({
            actionType: 0,
            silo: siloGMX,
            asset: USDCe,
            amount: _amount,
            collateralOnly: false
        });
        ISiloRouter(siloRouter).execute(_actions);
        uint256 sUsdGmxAmount = IERC20(sUSDC_GMX).balanceOf(address(this));
        IERC20(sUSDC_GMX).transfer(msg.sender, sUsdGmxAmount);
        emit Zapped(_token, _amount, sUSDC_GMX, sUsdGmxAmount);
        return sUsdGmxAmount;
    }

    function returnSiloGMX(address _token, uint256 _amount, address _to, bytes calldata _data) external returns (uint256) {
        address sUSDC_GMX = 0x96E1301bd2536A3C56EBff8335FD892dD9bD02dC;
        address siloGMX = 0xDe998E5EeF06dD09fF467086610B175F179A66A0;
        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != sUSDC_GMX, "cannot swap token to itself");
        IERC20(sUSDC_GMX).transferFrom(msg.sender, address(this), _amount);
        IERC20(sUSDC_GMX).approve(siloRouter, _amount);

        ISiloRouter.Action[] memory _actions = new ISiloRouter.Action[](1);
        _actions[0] = ISiloRouter.Action({
            actionType: 1,
            silo: siloGMX,
            asset: USDCe,
            amount: _amount,
            collateralOnly: false
        });
        ISiloRouter(siloRouter).execute(_actions);
        
        if (_token != USDCe) {
            uint256 usdceAmount = IERC20(USDCe).balanceOf(address(this));
            swapOpenOcean(USDCe, _token, usdceAmount, _data);
        }
        
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(sUSDC_GMX, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getSiloARB(address _token, uint256 _amount, bytes calldata _data) external payable returns (uint256) {
        address sUSDC_ARB = 0x55ADE3B74abef55bF379FF6Ae61CB77a405Eb4A8;
        address siloARB = 0x0696E6808EE11a5750733a3d821F9bB847E584FB;
        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != sUSDC_ARB, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (_token != USDCe) {
            swapOpenOcean(_token, USDCe, _amount, _data);
            _token = USDCe;
            _amount = IERC20(USDCe).balanceOf(address(this));
        }
        IERC20(_token).approve(siloRouter, _amount);
        ISiloRouter.Action[] memory _actions = new ISiloRouter.Action[](1);
        _actions[0] = ISiloRouter.Action({
            actionType: 0,
            silo: siloARB,
            asset: USDCe,
            amount: _amount,
            collateralOnly: false
        });
        ISiloRouter(siloRouter).execute(_actions);
        uint256 sUsdArbAmount = IERC20(sUSDC_ARB).balanceOf(address(this));
        IERC20(sUSDC_ARB).transfer(msg.sender, sUsdArbAmount);
        emit Zapped(_token, _amount, sUSDC_ARB, sUsdArbAmount);
        return sUsdArbAmount;
    }

    function returnSiloARB(address _token, uint256 _amount, address _to, bytes calldata _data) external returns (uint256) {
        address sUSDC_ARB = 0x55ADE3B74abef55bF379FF6Ae61CB77a405Eb4A8;
        address siloARB = 0x0696E6808EE11a5750733a3d821F9bB847E584FB;
        address USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != sUSDC_ARB, "cannot swap token to itself");
        IERC20(sUSDC_ARB).transferFrom(msg.sender, address(this), _amount);
        
        IERC20(sUSDC_ARB).approve(siloRouter, _amount);
        
        ISiloRouter.Action[] memory _actions = new ISiloRouter.Action[](1);
        _actions[0] = ISiloRouter.Action({
            actionType: 1,
            silo: siloARB,
            asset: USDCe,
            amount: _amount,
            collateralOnly: false
        });
        ISiloRouter(siloRouter).execute(_actions);
        
        if (_token != USDCe) {
            uint256 usdceAmount = IERC20(USDCe).balanceOf(address(this));
            swapOpenOcean(USDCe, _token, usdceAmount, _data);
        }
        
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(sUSDC_ARB, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getLodeUSDC(address _token, uint256 _amount, bytes calldata _data) external returns (uint256) {
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address lodeComp = 0x1ca530f02DD0487cef4943c674342c5aEa08922F;
        address lodeUniTroller = 0xa86DD95c210dd186Fa7639F93E4177E97d057576;
        address lodeUSDC = 0x1ca530f02DD0487cef4943c674342c5aEa08922F;
        require(_token != lodeUSDC, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (_token != usdc) {
            swapOpenOcean(_token, usdc, _amount, _data);
            _token = usdc;
            _amount = IERC20(usdc).balanceOf(address(this));
        }
        address[] memory path = new address[](1);
        path[0] = usdc;
        ILodeTroller(lodeUniTroller).enterMarkets(path);
        IERC20(usdc).approve(lodeComp, _amount);
        ILodeComp(lodeComp).mint(_amount);
        uint256 lodeUSDCAmount = IERC20(lodeUSDC).balanceOf(address(this));
        IERC20(lodeUSDC).transfer(msg.sender, lodeUSDCAmount);
        emit Zapped(_token, _amount, lodeUSDC, lodeUSDCAmount);
        return lodeUSDCAmount;
    }

    function returnLodeUSDC(
        address _token,
        uint256 _amount,
        address _to,
        bytes calldata _data
    ) external returns (uint256) {
        address lodeUSDC = 0x1ca530f02DD0487cef4943c674342c5aEa08922F;
        address lodeComp = 0x1ca530f02DD0487cef4943c674342c5aEa08922F;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != lodeUSDC, "cannot swap token to itself");
        IERC20(lodeUSDC).transferFrom(msg.sender, address(this), _amount);
        ILodeComp(lodeComp).redeem(_amount);
        if (_token != usdc) {
            swapOpenOcean(usdc, _token, IERC20(usdc).balanceOf(address(this)), _data);
        }
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(lodeUSDC, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getTenderUSDC(address _token, uint256 _amount, bytes calldata _data) external returns (uint256) {
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address tenderComp = 0x068485a0f964B4c3D395059a19A05a8741c48B4E;
        address tenderUniTroller = 0xeed247Ba513A8D6f78BE9318399f5eD1a4808F8e;
        address tenderUSDC = 0x068485a0f964B4c3D395059a19A05a8741c48B4E;
        require(_token != tenderUSDC, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (_token != usdc) {
            swapOpenOcean(_token, usdc, _amount, _data);
            _token = usdc;
            _amount = IERC20(usdc).balanceOf(address(this));
        }
        address[] memory path = new address[](1);
        path[0] = usdc;
        ILodeTroller(tenderUniTroller).enterMarkets(path);
        IERC20(usdc).approve(tenderComp, _amount);
        ITenderComp(tenderComp).mint(_amount);
        uint256 tenderUSDCAmount = IERC20(tenderUSDC).balanceOf(address(this));
        IERC20(tenderUSDC).transfer(msg.sender, tenderUSDCAmount);
        emit Zapped(_token, _amount, tenderUSDC, tenderUSDCAmount);
        return tenderUSDCAmount;
    }

    function returnTenderUSDC(
        address _token,
        uint256 _amount,
        address _to,
        bytes calldata _data
    ) external returns (uint256) {
        address tenderComp = 0x068485a0f964B4c3D395059a19A05a8741c48B4E;
        address tenderUSDC = 0x068485a0f964B4c3D395059a19A05a8741c48B4E;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

        require(_token != tenderUSDC, "cannot swap token to itself");
        IERC20(tenderUSDC).transferFrom(msg.sender, address(this), _amount);
        ITenderComp(tenderComp).redeem(_amount);

        if (_token != usdc) {
            swapOpenOcean(usdc, _token, IERC20(usdc).balanceOf(address(this)), _data);
        }
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(tenderUSDC, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function getPxGmx(address _token, uint256 _amount, bytes calldata _data) external returns (uint256) {
        address pirexGmx = 0xb0E54CdE03E37414672D69687b212388566BA856;
        address pxGmx = 0x9A592B4539E22EeB8B2A3Df679d572C7712Ef999;
        address gmx = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

        require(_token != pxGmx, "cannot swap token to itself");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if (_token != gmx) {
            swapOpenOcean(_token, gmx, _amount, _data);
            _amount = IERC20(gmx).balanceOf(address(this));
        }

        IERC20(gmx).approve(pirexGmx, _amount);
        IPirex(pirexGmx).depositGmx(_amount, address(this));
        uint256 pxGmxAmount = IERC20(pxGmx).balanceOf((address(this)));
        IERC20(pxGmx).transfer(msg.sender, pxGmxAmount);
        emit Zapped(_token, _amount, pxGmx, pxGmxAmount);
        return pxGmxAmount;
    }

    function returnPxGmx(
        address _token,
        uint256 _amount,
        address _to,
        bytes calldata _data
    ) external returns (uint256) {
        address pxGmx = 0x9A592B4539E22EeB8B2A3Df679d572C7712Ef999;

        require(_token != pxGmx, "cannot swap token to itself");
        IERC20(pxGmx).transferFrom(msg.sender, address(this), _amount);
        swapOpenOcean(pxGmx, _token, _amount, _data);
        uint256 tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, tokenAmount);
        emit Zapped(pxGmx, _amount, _token, tokenAmount);
        return tokenAmount;
    }

    function isCloseEnough(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b <= (a * TOLERANCE) / ONE;
        } else {
            return b - a <= (a * TOLERANCE) / ONE;
        }
    }

    function swapOpenOcean(address tokenIn, address tokenOut, uint256 amount, bytes calldata data) internal {
        IERC20(tokenIn).approve(address(openOceanRouter), amount);

        bytes4 method = _getMethod(data);

        // swap
        if (
            method ==
            bytes4(
                keccak256(
                    'swap(address,(address,address,address,address,uint256,uint256,uint256,uint256,address,bytes),(uint256,uint256,uint256,bytes)[])'
                )
            )
        ) {
            (, IOpenOceanExchange.SwapDescription memory desc, ) = abi.decode(
                data[4:],
                (IOpenOceanCaller, IOpenOceanExchange.SwapDescription, IOpenOceanCaller.CallDescription[])
            );

            if (tokenIn != address(desc.srcToken)) revert WRONG_TOKEN_IN();
            if (tokenOut != address(desc.dstToken)) revert WRONG_TOKEN_OUT();
            if (!isCloseEnough(amount, desc.amount)) revert WRONG_AMOUNT();
            if (address(this) != desc.dstReceiver) revert WRONG_DST();

            _callOpenOcean(data);
        }
        // uniswapV3SwapTo
        else if (method == bytes4(keccak256('uniswapV3SwapTo(address,uint256,uint256,uint256[])'))) {
            (address recipient, uint256 swapAmount, , ) = abi.decode(data[4:], (address, uint256, uint256, uint256[]));
            if (address(this) != recipient) revert WRONG_DST();
            if (!isCloseEnough(amount, swapAmount)) revert WRONG_AMOUNT();

            _callOpenOcean(data);
        }
        // callUniswapTo
        else if (method == bytes4(keccak256('callUniswapTo(address,uint256,uint256,bytes32[],address)'))) {
            (address srcToken, uint256 swapAmount, , , address recipient) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[], address)
            );
            if (tokenIn != srcToken) revert WRONG_TOKEN_IN();
            if (!isCloseEnough(amount, swapAmount)) revert WRONG_AMOUNT();
            if (address(this) != recipient) revert WRONG_DST();

            _callOpenOcean(data);
        } else {
            revert SWAP_METHOD_NOT_IDENTIFIED();
        }
    }

    function _getMethod(bytes memory data) internal pure returns (bytes4 method) {
        assembly {
            method := mload(add(data, add(32, 0)))
        }
    }

    function _callOpenOcean(bytes memory data) internal {
        (bool success, bytes memory result) = address(openOceanRouter).call(data);
        if (!success) {
            if (result.length < 68) revert SWAP_ERROR();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}