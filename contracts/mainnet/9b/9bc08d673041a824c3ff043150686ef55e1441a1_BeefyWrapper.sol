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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVeloPair.sol";
import "./interfaces/IVeloRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWETH.sol";

// import "forge-std/console2.sol";

contract BeefyWrapper {
    // Use SafeMath library for safe arithmetic operations
    using SafeMath for uint256;

    address public immutable admin;
    uint256 public fee;
    // address constant routerAddress = 0x9c12939390052919aF3155f41Bf4160Fd3666A6f;
    address public immutable wethAddress;

    uint256 constant minBalanceRequired = 0.003 ether;

    // IVeloRouter internal immutable router;
    IWETH public immutable weth;

    event FeeUpdated(uint256 v);
    event LogMessage(string m);

    modifier onlyOwner() {
        require(msg.sender == admin, "AD");
        _;
    }

    constructor(address _admin, address _wethAddress, uint256 _fee) {
        require(_admin != address(0), "A0");
        admin = _admin;
        fee = _fee;
        wethAddress = _wethAddress;
        weth = IWETH(_wethAddress);
        // router = IVeloRouter(routerAddress);
    }

    // address user, address token,
    function swapETHAndDeposit(
        address gaugeAddress,
        address pairAddress,
        address routerAddress,
        IVeloRouter.route[] calldata routes0,
        IVeloRouter.route[] calldata routes1
    ) external payable returns (uint256) {
        require(routes0.length >= 1 && routes1.length >= 1, "IP");
        uint256 etherAmount = msg.value;
        uint256 maxAmount = 2 ** 256 - 1;
        IVeloRouter router = IVeloRouter(routerAddress);

        // Get the pair details
        (, , , , bool stable, address token0, address token1) = IVeloPair(
            pairAddress
        ).metadata();

        // swap 50% ETH to token0
        // if token0 is WETH, then no need to swap
        if (token0 != wethAddress) {
            // console2.log("swap token0", token0, wethAddress);
            uint256[] memory expectedOutput0 = router.getAmountsOut(
                etherAmount.div(2),
                routes0
            );
            require(
                router
                .swapExactETHForTokens{value: etherAmount.div(2)}(
                    expectedOutput0[1],
                    routes0,
                    address(this),
                    block.timestamp
                ).length >= 2,
                "Revert due to swapExactETHForTokens0 failur"
            );
            emit LogMessage("swap token0");
        } else {
            // console2.log("deposit weth0");
            weth.deposit{value: etherAmount.div(2)}();
            require(weth.transfer(address(this), etherAmount.div(2)), "TF0");
            emit LogMessage("deposit weth0");
        }

        // swap 50% ETH to token1
        // if token1 is WETH, then no need to swap
        if (token1 != wethAddress) {
            // console2.log("swap token1");
            uint256[] memory expectedOutput1 = router.getAmountsOut(
                etherAmount.div(2),
                routes1
            );
            require(
                router
                .swapExactETHForTokens{value: etherAmount.div(2)}(
                    expectedOutput1[1],
                    routes1,
                    address(this),
                    block.timestamp
                ).length >= 2,
                "Revert due to swapExactETHForTokens1 failur"
            );
            emit LogMessage("swap token1");
        } else {
            // console2.log("deposit weth1");
            weth.deposit{value: etherAmount.div(2)}();
            require(weth.transfer(address(this), etherAmount.div(2)), "TF1");
            emit LogMessage("deposit weth1");
        }

        // get the token amounts
        uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));

        // 1. Allow the router to spend the pairs
        require(IERC20(token0).approve(routerAddress, maxAmount), "A0");
        require(IERC20(token1).approve(routerAddress, maxAmount), "A1");
        // console2.log("approve router");
        // 2. add to liquidity the pairs using the router
        (uint256 estimateAmount0, uint256 estimateAmount1, ) = router
            .quoteAddLiquidity(
                token0,
                token1,
                stable,
                token0Amount,
                token1Amount
            );
        // console2.log("quoteAddLiquidity");
        (, , uint256 liquidity) = router.addLiquidity(
            token0,
            token1,
            stable,
            estimateAmount0,
            estimateAmount1,
            estimateAmount0.mul(98).div(100),
            estimateAmount1.mul(98).div(100),
            // msg.sender,
            address(this),
            block.timestamp
        );
        require(liquidity > 0, "LA");
        emit LogMessage("Added to liquidity");

        // 3. deposit the LP tokens to the vault
        require(IERC20(pairAddress).approve(gaugeAddress, maxAmount), "A0");
        IVault(gaugeAddress).depositAll();

        // 4. move the LP tokens to the user
        // console2.log("transfer liquidity to user");
        require(IERC20(gaugeAddress).approve(address(this), maxAmount), "A0");
        uint256 LpBalance = IERC20(gaugeAddress).balanceOf(address(this));
        bool success = IERC20(gaugeAddress).transferFrom(
            address(this),
            msg.sender,
            LpBalance
        );
        require(success, "LT");
        emit LogMessage("transfer liquidity to user");
        // console2.log("transfer liquidity to user");

        // if there is a balance in the contract of token0 then send it to the user
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        if (token0Balance > 0) {
            require(IERC20(token0).transfer(msg.sender, token0Balance), "T06");
            emit LogMessage("transfer token0 balance to user");
        }
        // if there is a balance in the contract of token1 then send it to the user
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));
        if (token1Balance > 0) {
            require(IERC20(token1).transfer(msg.sender, token1Balance), "T16");
            emit LogMessage("transfer token1 balance to user");
        }
        // if there is a balance in the contract of ETH then send it to the user
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(msg.sender).transfer(ethBalance);
            emit LogMessage("transfer ETH balance to user");
        }
        return LpBalance;
    }

    function withdrawAndSwap(
        uint256 amount,
        uint256 rewards,
        address gaugeAddress,
        address pairAddress,
        address routerAddress,
        IVeloRouter.route[] calldata routes0,
        IVeloRouter.route[] calldata routes1
    ) external {
        require(routes0.length >= 1 && routes1.length >= 1, "IP");
        uint256 maxAmount = 2 ** 256 - 1;
        IVeloRouter router = IVeloRouter(routerAddress);

        // Get the pair details
        (, , , , bool stable, address token0, address token1) = IVeloPair(
            pairAddress
        ).metadata();

        // 1. Transfer mooTokens from the user to the contract
        bool success2 = IERC20(gaugeAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success2, "LT2");

        // 2. Withdraw the LP tokens from the vault
        IVault(gaugeAddress).withdraw(amount);

        // 3. Transfer fee service if rewards are greater than 0
        if (rewards > 0) {
            bool success = IERC20(pairAddress).transferFrom(
                msg.sender,
                0xc06323174D132363A3A1c36C8da7c7Cb7ceBb392,
                rewards.mul(fee).div(100)
            );
            require(success, "VT");
        }

        // 4. Allow the router to spend the LP tokens
        require(IERC20(pairAddress).approve(routerAddress, maxAmount), "RA");

        // 5. Withdraw tokens pair from liquidity using the router
        (uint256 estimateAmount0, uint256 estimateAmount1) = router
            .quoteRemoveLiquidity(token0, token1, stable, amount);
        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            token0,
            token1,
            stable,
            amount,
            estimateAmount0.mul(98).div(100),
            estimateAmount1.mul(98).div(100),
            address(this),
            block.timestamp
        );
        emit LogMessage("Removed liquidity");

        // 6. Allow the router to spend the pair
        require(IERC20(token0).approve(routerAddress, maxAmount), "TA0");
        require(IERC20(token1).approve(routerAddress, maxAmount), "TA1");

        // 7. swap the tokens for ETH and send it to the user
        // if token0 is WETH, then no need to swap
        if (token0 != wethAddress) {
            uint256[] memory expectedOutput0 = router.getAmountsOut(
                amount0,
                routes0
            );
            require(
                router
                    .swapExactTokensForETH(
                        amount0,
                        expectedOutput0[1],
                        routes0,
                        msg.sender,
                        block.timestamp
                    )
                    .length >= 2,
                "Revert due to swapExactETHForTokens0 failure"
            );
            emit LogMessage("Swap token0");
        } else {
            // if token0 is WETH, then send it to the user
            bool success = IERC20(wethAddress).transfer(msg.sender, amount0);
            require(success, "WT0");
            emit LogMessage("Withdraw WETH0");
        }

        // if token1 is WETH, then no need to swap
        if (token1 != wethAddress) {
            uint256[] memory expectedOutput1 = router.getAmountsOut(
                amount1,
                routes1
            );
            require(
                router
                    .swapExactTokensForETH(
                        amount1,
                        expectedOutput1[1],
                        routes1,
                        msg.sender,
                        block.timestamp
                    )
                    .length >= 2,
                "Revert due to swapExactETHForTokens1 failure"
            );
            emit LogMessage("Swap token1");
        } else {
            // if token1 is WETH, then send it to the user
            bool success = IERC20(wethAddress).transfer(msg.sender, amount1);
            require(success, "WT1");
            emit LogMessage("Withdraw WETH1");
        }

        // if there is a balance in the contract of token0 then send it to the user
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        if (token0Balance > 0) {
            require(IERC20(token0).transfer(msg.sender, token0Balance), "T06");
            emit LogMessage("transfer token0 balance to user");
        }
        // if there is a balance in the contract of token1 then send it to the user
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));
        if (token1Balance > 0) {
            require(IERC20(token1).transfer(msg.sender, token1Balance), "T16");
            emit LogMessage("transfer token1 balance to user");
        }
        // if there is a balance in the contract of ETH then send it to the user
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(msg.sender).transfer(ethBalance);
            emit LogMessage("transfer ETH balance to user");
        }
    }

    function updateFee(uint256 newFee) external onlyOwner {
        require(newFee <= 50, "UF");
        fee = newFee;
        emit FeeUpdated(newFee);
    }

    function transferAll(address token) external onlyOwner {
        if (token == address(0)) {
            uint256 nativeBalance = address(this).balance;
            if (nativeBalance > 0) {
                payable(admin).transfer(nativeBalance);
            }
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(IERC20(token).transfer(admin, balance), "TAT");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVault {
    function balanceOf(address) external view returns (uint256);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function deposit(uint256 amount) external;

    function depositAll() external;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVeloPair {
    // event Approval(address indexed owner, address indexed spender, uint256 amount);
    // event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    // event Claim(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1);
    // event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    // event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    // event Swap(
    //     address indexed sender,
    //     uint256 amount0In,
    //     uint256 amount1In,
    //     uint256 amount0Out,
    //     uint256 amount1Out,
    //     address indexed to
    // );
    // event Sync(uint256 reserve0, uint256 reserve1);
    // event Transfer(address indexed from, address indexed to, uint256 amount);
    // struct Observation {
    //     uint256 timestamp;
    //     uint256 reserve0Cumulative;
    //     uint256 reserve1Cumulative;
    // }
    // function allowance(address, address) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function balanceOf(address) external view returns (uint256);
    // function blockTimestampLast() external view returns (uint256);
    // function burn(address to) external returns (uint256 amount0, uint256 amount1);
    // function claimFees() external returns (uint256 claimed0, uint256 claimed1);
    // function claimable0(address) external view returns (uint256);
    // function claimable1(address) external view returns (uint256);
    // function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
    // function currentCumulativePrices()
    //     external
    //     view
    //     returns (
    //         uint256 reserve0Cumulative,
    //         uint256 reserve1Cumulative,
    //         uint256 blockTimestamp
    //     );
    // function decimals() external view returns (uint8);
    // function fees() external view returns (address);
    // function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
    // function getReserves()
    //     external
    //     view
    //     returns (
    //         uint256 _reserve0,
    //         uint256 _reserve1,
    //         uint256 _blockTimestampLast
    //     );
    // function index0() external view returns (uint256);
    // function index1() external view returns (uint256);
    // function lastObservation() external view returns (Observation memory);
    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        );

    // function mint(address to) external returns (uint256 liquidity);
    // function name() external view returns (string memory);
    // function nonces(address) external view returns (uint256);
    // function observationLength() external view returns (uint256);
    // function observations(uint256)
    //     external
    //     view
    //     returns (
    //         uint256 timestamp,
    //         uint256 reserve0Cumulative,
    //         uint256 reserve1Cumulative
    //     );
    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;
    // function prices(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 points
    // ) external view returns (uint256[] memory);
    // function quote(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 granularity
    // ) external view returns (uint256 amountOut);
    // function reserve0() external view returns (uint256);
    // function reserve0CumulativeLast() external view returns (uint256);
    // function reserve1() external view returns (uint256);
    // function reserve1CumulativeLast() external view returns (uint256);
    // function sample(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 points,
    //     uint256 window
    // ) external view returns (uint256[] memory);
    // function skim(address to) external;
    // function stable() external view returns (bool);
    // function supplyIndex0(address) external view returns (uint256);
    // function supplyIndex1(address) external view returns (uint256);
    // function swap(
    //     uint256 amount0Out,
    //     uint256 amount1Out,
    //     address to,
    //     bytes memory data
    // ) external;
    // function symbol() external view returns (string memory);
    // function sync() external;
    // function token0() external view returns (address);
    // function token1() external view returns (address);
    // function tokens() external view returns (address, address);
    // function totalSupply() external view returns (uint256);
    // function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVeloRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }

    // function UNSAFE_swapExactTokensForTokens(
    //     uint256[] memory amounts,
    //     route[] memory routes,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory);
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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    // function addLiquidityETH(
    //     address token,
    //     bool stable,
    //     uint256 amountTokenDesired,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // )
    //     external
    //     payable
    //     returns (
    //         uint256 amountToken,
    //         uint256 amountETH,
    //         uint256 liquidity
    //     );
    // function factory() external view returns (address);
    // function getAmountOut(
    //     uint256 amountIn,
    //     address tokenIn,
    //     address tokenOut
    // ) external view returns (uint256 amount, bool stable);
    function getAmountsOut(uint256 amountIn, route[] memory routes)
        external
        view
        returns (uint256[] memory amounts);

    // function getReserves(
    //     address tokenA,
    //     address tokenB,
    //     bool stable
    // ) external view returns (uint256 reserveA, uint256 reserveB);
    // function isPair(address pair) external view returns (bool);
    // function pairFor(
    //     address tokenA,
    //     address tokenB,
    //     bool stable
    // ) external view returns (address pair);
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // function removeLiquidityETH(
    //     address token,
    //     bool stable,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountToken, uint256 amountETH);
    // function removeLiquidityETHWithPermit(
    //     address token,
    //     bool stable,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountToken, uint256 amountETH);
    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     bool stable,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountA, uint256 amountB);
    // function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function swapExactETHForTokens(
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] memory routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    // function swapExactTokensForTokens(
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     route[] memory routes,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory amounts);
    // function swapExactTokensForTokensSimple(
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address tokenFrom,
    //     address tokenTo,
    //     bool stable,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256[] memory amounts);
    // function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}