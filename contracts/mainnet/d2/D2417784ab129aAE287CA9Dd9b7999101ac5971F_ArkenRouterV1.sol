// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.16;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../token/interfaces/IArkenOptionRewarder.sol';

import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IArkenPairLongTerm.sol';
import './interfaces/IArkenRouter.sol';
import './interfaces/IUniswapV2Factory.sol';
import './libraries/ArkenLPLibrary.sol';

// import 'hardhat/console.sol';

contract ArkenRouterV1 is Ownable, IArkenRouter {
    using SafeERC20 for IERC20;

    address public immutable WETH;
    address public factory;
    address public factoryLongTerm;
    address public rewarder;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ArkenRouter: EXPIRED');
        _;
    }

    constructor(
        address weth_,
        address factory_,
        address factoryLongTerm_,
        address rewarder_
    ) {
        WETH = weth_;
        factory = factory_;
        factoryLongTerm = factoryLongTerm_;
        rewarder = rewarder_;
    }

    function updateRewarder(address rewarder_) external onlyOwner {
        rewarder = rewarder_;
    }

    function updateFactory(address factory_) external onlyOwner {
        factory = factory_;
    }

    function updateFactoryLongTerm(
        address factoryLongTerm_
    ) external onlyOwner {
        factoryLongTerm = factoryLongTerm_;
    }

    function _swapForLiquidity(
        address tokenIn,
        uint256 amountIn,
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (address token0, address token1) = ArkenLPLibrary.sortTokens(
            tokenA,
            tokenB
        );
        if (tokenIn == token0) {
            (uint256 amount0In, uint256 amount1Out) = ArkenLPLibrary
                .getAmountSwapRetainRatio(pair, tokenIn, amountIn);
            IERC20(token0).safeTransferFrom(msg.sender, pair, amount0In);
            IUniswapV2Pair(pair).swap(0, amount1Out, address(this), '');
            IERC20(token0).safeTransferFrom(
                msg.sender,
                pair,
                amountIn - amount0In
            );
            IERC20(token1).safeTransfer(pair, amount1Out);
            (amountA, amountB) = tokenA == token0
                ? (amountIn - amount0In, amount1Out)
                : (amount1Out, amountIn - amount0In);
        } else {
            (uint256 amount1In, uint256 amount0Out) = ArkenLPLibrary
                .getAmountSwapRetainRatio(pair, tokenIn, amountIn);
            IERC20(token1).safeTransferFrom(msg.sender, pair, amount1In);
            IUniswapV2Pair(pair).swap(amount0Out, 0, address(this), '');
            IERC20(token0).safeTransfer(pair, amount0Out);
            IERC20(token1).safeTransferFrom(
                msg.sender,
                pair,
                amountIn - amount1In
            );
            (amountA, amountB) = tokenA == token0
                ? (amount0Out, amountIn - amount1In)
                : (amountIn - amount1In, amount0Out);
        }
        require(amountAMin <= amountA, 'ArkenRouter: INSUFFICIENT_A_AMOUNT');
        require(amountBMin <= amountB, 'ArkenRouter: INSUFFICIENT_B_AMOUNT');
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        uint256 reserveA,
        uint256 reserveB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ArkenLPLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    'ArkenRouter: INSUFFICIENT_B_AMOUNT'
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ArkenLPLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    'ArkenRouter: INSUFFICIENT_A_AMOUNT'
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        AddLiquidityData calldata data,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (uint reserveA, uint reserveB) = ArkenLPLibrary.getReserves(
            factory,
            data.tokenA,
            data.tokenB
        );
        (amountA, amountB) = _addLiquidity(
            reserveA,
            reserveB,
            data.amountADesired,
            data.amountBDesired,
            data.amountAMin,
            data.amountBMin
        );
        require(
            data.amountAMin <= amountA,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            data.amountBMin <= amountB,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
        address pair = ArkenLPLibrary.pairFor(
            factory,
            data.tokenA,
            data.tokenB
        );
        IERC20(data.tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(data.tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(data.to);
    }

    function addLiquiditySingle(
        AddLiquiditySingleData calldata data,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        require(
            data.tokenIn == data.tokenA || data.tokenIn == data.tokenB,
            'ArkenRouter: INVALID_TOKEN_IN'
        );
        address pair = ArkenLPLibrary.pairFor(
            factory,
            data.tokenA,
            data.tokenB
        );
        (amountA, amountB) = _swapForLiquidity(
            data.tokenIn,
            data.amountIn,
            pair,
            data.tokenA,
            data.tokenB,
            data.amountAMin,
            data.amountBMin
        );
        liquidity = IUniswapV2Pair(pair).mint(data.to);
    }

    function addLiquidityLongTerm(
        AddLiquidityData calldata addData,
        AddLongTermInputData calldata longtermData,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (AddLongTermOutputData memory outputData)
    {
        (uint reserveA, uint reserveB) = ArkenLPLibrary.getReserves(
            factoryLongTerm,
            addData.tokenA,
            addData.tokenB
        );
        (outputData.amountA, outputData.amountB) = _addLiquidity(
            reserveA,
            reserveB,
            addData.amountADesired,
            addData.amountBDesired,
            addData.amountAMin,
            addData.amountBMin
        );
        require(
            addData.amountAMin <= outputData.amountA,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            addData.amountBMin <= outputData.amountB,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
        address pair = ArkenLPLibrary.pairFor(
            factoryLongTerm,
            addData.tokenA,
            addData.tokenB
        );
        IERC20(addData.tokenA).safeTransferFrom(
            msg.sender,
            pair,
            outputData.amountA
        );
        IERC20(addData.tokenB).safeTransferFrom(
            msg.sender,
            pair,
            outputData.amountB
        );
        (outputData.liquidity, outputData.positionTokenId) = IArkenPairLongTerm(
            pair
        ).mint(rewarder, longtermData.lockTime);
        IArkenOptionRewarder(rewarder).rewardLongTerm(
            addData.to,
            pair,
            outputData.positionTokenId,
            longtermData.rewardData
        );
    }

    function addLiquidityLongTermSingle(
        AddLiquiditySingleData calldata addData,
        AddLongTermInputData calldata longtermData,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (AddLongTermOutputData memory outputData)
    {
        require(
            addData.tokenIn == addData.tokenA ||
                addData.tokenIn == addData.tokenB,
            'ArkenRouter: INVALID_TOKEN_IN'
        );
        address pair = ArkenLPLibrary.pairFor(
            factoryLongTerm,
            addData.tokenA,
            addData.tokenB
        );
        (outputData.amountA, outputData.amountB) = _swapForLiquidity(
            addData.tokenIn,
            addData.amountIn,
            pair,
            addData.tokenA,
            addData.tokenB,
            addData.amountAMin,
            addData.amountBMin
        );
        (outputData.liquidity, outputData.positionTokenId) = IArkenPairLongTerm(
            pair
        ).mint(rewarder, longtermData.lockTime);
        IArkenOptionRewarder(rewarder).rewardLongTerm(
            addData.to,
            pair,
            outputData.positionTokenId,
            longtermData.rewardData
        );
    }

    /**
     * REMOVE LIQUIDITY
     */
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        address pair = ArkenLPLibrary.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = ArkenLPLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
    }

    function _removeLiquidityLongTerm(
        address tokenA,
        address tokenB,
        uint256 positionTokenId,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        address pair = ArkenLPLibrary.pairFor(factoryLongTerm, tokenA, tokenB);
        IArkenPairLongTerm(pair).transferFrom(
            msg.sender,
            pair,
            positionTokenId
        ); // send token to pair
        (uint amount0, uint amount1) = IArkenPairLongTerm(pair).burn(
            to,
            positionTokenId
        );
        (address token0, ) = ArkenLPLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
    }

    function _returnLiquiditySingle(
        address tokenOut,
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountALiquidity,
        uint256 amountBLiquidity,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        amountA = amountALiquidity;
        amountB = amountBLiquidity;
        (address token0, ) = ArkenLPLibrary.sortTokens(tokenA, tokenB);
        uint256 reserveA;
        uint256 reserveB;
        if (tokenA == token0) {
            (reserveA, reserveB, ) = IUniswapV2Pair(pair).getReserves();
        } else {
            (reserveB, reserveA, ) = IUniswapV2Pair(pair).getReserves();
        }
        uint256 amountOut;
        if (tokenA == tokenOut) {
            amountOut = ArkenLPLibrary.getAmountOut(
                amountB,
                reserveB,
                reserveA
            );
            IERC20(tokenA).safeTransfer(to, amountA);
            IERC20(tokenB).safeTransfer(pair, amountB);
            amountA = amountA + amountOut;
            amountB = 0;
        } else {
            amountOut = ArkenLPLibrary.getAmountOut(
                amountA,
                reserveA,
                reserveB
            );
            IERC20(tokenA).safeTransfer(pair, amountA);
            IERC20(tokenB).safeTransfer(to, amountB);
            amountA = 0;
            amountB = amountB + amountOut;
        }
        if (token0 == tokenOut) {
            IUniswapV2Pair(pair).swap(amountOut, 0, to, '');
        } else {
            IUniswapV2Pair(pair).swap(0, amountOut, to, '');
        }
    }

    function removeLiquidity(
        RemoveLiquidityData calldata data,
        uint256 liquidity,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _removeLiquidity(
            data.tokenA,
            data.tokenB,
            liquidity,
            data.to
        );
        require(
            amountA >= data.amountAMin,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            amountB >= data.amountBMin,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
    }

    function removeLiquiditySingle(
        RemoveLiquidityData calldata data,
        address tokenOut,
        uint256 liquidity,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        require(
            tokenOut == data.tokenA || tokenOut == data.tokenB,
            'ArkenRouter: INVALID_TOKEN_OUT'
        );
        (amountA, amountB) = _removeLiquidity(
            data.tokenA,
            data.tokenB,
            liquidity,
            address(this)
        );
        address pair = ArkenLPLibrary.pairFor(
            factory,
            data.tokenA,
            data.tokenB
        );
        (amountA, amountB) = _returnLiquiditySingle(
            tokenOut,
            data.tokenA,
            data.tokenB,
            pair,
            amountA,
            amountB,
            data.to
        );
        require(
            amountA >= data.amountAMin,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            amountB >= data.amountBMin,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
    }

    function removeLiquidityLongTerm(
        RemoveLiquidityData calldata data,
        uint256 positionTokenId,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _removeLiquidityLongTerm(
            data.tokenA,
            data.tokenB,
            positionTokenId,
            data.to
        );
        require(
            amountA >= data.amountAMin,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            amountB >= data.amountBMin,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
    }

    function removeLiquidityLongTermSingle(
        RemoveLiquidityData calldata data,
        address tokenOut,
        uint256 positionTokenId,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        require(
            tokenOut == data.tokenA || tokenOut == data.tokenB,
            'ArkenRouter: INVALID_TOKEN_OUT'
        );
        (amountA, amountB) = _removeLiquidityLongTerm(
            data.tokenA,
            data.tokenB,
            positionTokenId,
            address(this)
        );
        address pair = ArkenLPLibrary.pairFor(
            factoryLongTerm,
            data.tokenA,
            data.tokenB
        );
        (amountA, amountB) = _returnLiquiditySingle(
            tokenOut,
            data.tokenA,
            data.tokenB,
            pair,
            amountA,
            amountB,
            data.to
        );
        require(
            amountA >= data.amountAMin,
            'ArkenRouter: INSUFFICIENT_A_AMOUNT'
        );
        require(
            amountB >= data.amountBMin,
            'ArkenRouter: INSUFFICIENT_B_AMOUNT'
        );
    }
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

pragma solidity >0.8.0;

interface IArkenOptionRewarder {
    error NoPosition();
    error PositionRewarded(uint256 positionTokenId);
    error InvalidExerciseAmountMinLength(
        uint256 length,
        uint256 expectedLength
    );
    error InsufficientRemainingArken();
    error InsufficientExerciseAmount(uint256 amount, uint256 amountMin);
    error InsufficientLockTime(uint256 lockTime, uint256 minimumLockTime);
    error NotSupportedPair(address pair);
    error InsufficientTotalReward(
        uint256 totalRewardArken,
        uint256 rewardedArken
    );

    event SetConfiguration(
        address indexed pair,
        address sender,
        RewardConfiguration[] configs
    );
    event DeleteConfiguration(address indexed pair, address sender);
    event SetTotalRewardArken(uint256 totalRewardArken, address sender);
    event RewardOptionNFT(
        uint256 tokenId,
        address pair,
        uint256 unlockedAt,
        uint256 expiredAt,
        uint256 unlockPrice,
        uint256 exercisePrice,
        uint256 exerciseAmount
    );

    function arken() external view returns (address);

    function optionNFT() external view returns (address);

    function totalRewardArken() external view returns (uint256);

    function rewardedArken() external view returns (uint256);

    function setTotalRewardArken(uint256) external;

    struct RewardConfiguration {
        uint256 lockTime;
        uint256 expiredTime;
        uint256 unlockPrice;
        uint256 exercisePrice;
        uint256 exerciseAmountFactor;
        uint256 optionType;
    }

    function setConfiguration(
        address pair,
        RewardConfiguration[] memory configs
    ) external;

    function deleteConfiguration(address pair) external;

    function configurations(
        address pair
    ) external view returns (RewardConfiguration[] memory);

    function configuration(
        address pair,
        uint256 idx
    ) external view returns (RewardConfiguration memory);

    struct RewardLongTermData {
        uint256[] exerciseAmountMins;
    }

    function rewardLongTerm(
        address to,
        address pair,
        uint256 positionTokenId,
        bytes calldata data
    ) external returns (uint256[] memory tokenIds);
}

// SPDX-License-Identifier: GPL-3.0-or-later

//solhint-disable-next-line compiler-version
pragma solidity >=0.5.0;

//solhint-disable func-name-mixedcase

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './IUniswapV2ERC721.sol';

interface IArkenPairLongTerm is IUniswapV2ERC721 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function MINIMUM_LOCK_TIME() external pure returns (uint256);

    function mintedAt(uint256 tokenId) external view returns (uint256);

    function unlockedAt(uint256 tokenId) external view returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(
        address to,
        uint256 lockTime
    ) external returns (uint256 liquidity, uint256 tokenId);

    function burn(
        address to,
        uint256 tokenId
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function getLiquidity(
        uint256 tokenId
    )
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function pauser() external view returns (address);

    function pause() external;

    function unpause() external;

    function setPauser(address newPauser) external;
}

pragma solidity >0.8.0;

interface IArkenRouter {
    function WETH() external view returns (address);

    function factory() external view returns (address);

    function factoryLongTerm() external view returns (address);

    function rewarder() external view returns (address);

    struct AddLiquidityData {
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
    }

    struct AddLiquiditySingleData {
        address tokenIn;
        uint256 amountIn;
        address tokenA;
        address tokenB;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
    }

    struct RemoveLiquidityData {
        address tokenA;
        address tokenB;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
    }

    // Short Term
    function addLiquidity(
        AddLiquidityData calldata data,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquiditySingle(
        AddLiquiditySingleData calldata data,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        RemoveLiquidityData calldata data,
        uint256 liquidity,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquiditySingle(
        RemoveLiquidityData calldata data,
        address tokenOut,
        uint256 liquidity,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // Long Term
    struct AddLongTermInputData {
        uint256 lockTime;
        bytes rewardData;
    }

    struct AddLongTermOutputData {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        uint256 positionTokenId;
    }

    function addLiquidityLongTerm(
        AddLiquidityData calldata addData,
        AddLongTermInputData calldata longtermData,
        uint256 deadline
    ) external returns (AddLongTermOutputData memory outputData);

    function addLiquidityLongTermSingle(
        AddLiquiditySingleData calldata addData,
        AddLongTermInputData calldata longtermData,
        uint256 deadline
    ) external returns (AddLongTermOutputData memory outputData);

    function removeLiquidityLongTerm(
        RemoveLiquidityData calldata data,
        uint256 positionTokenId,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityLongTermSingle(
        RemoveLiquidityData calldata data,
        address tokenOut,
        uint256 positionTokenId,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: GPL-3.0-or-later

//solhint-disable-next-line compiler-version
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

//solhint-disable reason-string

// import 'hardhat/console.sol';

import '../../lib/Babylonian.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';

library ArkenLPLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(
            reserveA > 0 && reserveB > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(
            reserveIn > 0 && reserveOut > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        uint256 amountInWithFee = amountIn * 997; // af = h * 1000
        uint256 numerator = amountInWithFee * reserveOut; // n = h * y
        uint256 denominator = reserveIn * 1000 + amountInWithFee; // d = x * 1000 + af
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(
            reserveIn > 0 && reserveOut > 0,
            'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountSwapRetainRatio(
        address pair,
        address tokenIn,
        uint256 amountIn
    ) internal view returns (uint256 amountInSwap, uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pair)
            .getReserves();
        if (IUniswapV2Pair(pair).token1() == tokenIn)
            (reserveIn, reserveOut) = (reserveOut, reserveIn);

        uint256 nominator = Babylonian.sqrt(
            (3988000 * amountIn + 3988009 * reserveIn) * reserveIn
        ) - (1997 * reserveIn);
        uint256 denominator = 1994;
        amountInSwap = nominator / denominator;
        amountOut = getAmountOut(amountInSwap, reserveIn, reserveOut);
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

// SPDX-License-Identifier: GPL-3.0-or-later

//solhint-disable-next-line compiler-version
pragma solidity >=0.5.0;

//solhint-disable func-name-mixedcase
interface IUniswapV2ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

interface IUniswapV2ERC721 is IERC721, IERC721Metadata {
    function decimals() external view returns (uint8);

    function liquidityOf(uint256 tokenId) external view returns (uint256);

    function totalLiquidityOf(address owner) external view returns (uint256);

    function tokenIdCounter() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}