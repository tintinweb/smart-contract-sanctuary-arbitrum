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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SushiRouter } from "./Interfaces/SushiRouter.sol";
import { IUniswapV3Router } from "./Interfaces/IUniswapV3Router.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "./Interfaces/IWETH.sol";
import { IHopPool } from "./Interfaces/IHopPool.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ArbitrumGuildTokenBundleV2 is Ownable {
    IERC20[] public tokens;
    uint256[] public amounts;

    mapping(address => address[]) public paths;
    mapping(address => bytes) public uniswapPath;
    mapping(address => address[]) public elkPaths;

    uint256 public slippage = 100;
    uint256 public constant BASE_UNIT = 10000;
    SushiRouter public sushiRouter = SushiRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    SushiRouter public elkRouter = SushiRouter(0x0A2e5A3Dc2f74E5Bfaf0Bf90685A5A899f379Cb0);
    IUniswapV3Router public uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public constant HOP_USDC_ETH_POOL = address(0x10541b07d8Ad2647Dc6cD67abd4c03575dade261);
    uint256 public usdcAmount = 1e5;
    uint256 public ethTip = 0.004 ether;

    constructor() {
        IWETH(WETH).approve(address(sushiRouter), type(uint256).max);
        IWETH(WETH).approve(address(uniswapV3Router), type(uint256).max);
        IWETH(WETH).approve(address(elkRouter), type(uint256).max);

        IERC20(USDC).approve(HOP_USDC_ETH_POOL, type(uint256).max);
        // DBL
        tokens.push(IERC20(0xd3f1Da62CAFB7E7BC6531FF1ceF6F414291F03D3));
        amounts.push(0.01 ether);

        // DPX
        tokens.push(IERC20(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55));
        amounts.push(0.0001 ether);

        // LPT
        tokens.push(IERC20(0x289ba1701C2F088cf0faf8B3705246331cB8A839));
        amounts.push(0.001 ether);

        // PLS
        tokens.push(IERC20(0x51318B7D00db7ACc4026C88c3952B66278B6A67F));
        amounts.push(0.001 ether);

        // MAGIC
        tokens.push(IERC20(0x539bdE0d7Dbd336b79148AA742883198BBF60342));
        amounts.push(0.001 ether);

        // LINK
        tokens.push(IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4));
        amounts.push(0.001 ether);

        // UMAMI
        tokens.push(IERC20(0x1622bF67e6e5747b81866fE0b85178a93C7F86e3));
        amounts.push(1000000);

        // MYC
        tokens.push(IERC20(0xC74fE4c715510Ec2F8C61d70D397B32043F55Abe));
        amounts.push(0.01 ether);

        // VSTA
        tokens.push(IERC20(0xa684cd057951541187f288294a1e1C2646aA2d24));
        amounts.push(0.01 ether);

        // JONES
        tokens.push(IERC20(0x10393c20975cF177a3513071bC110f7962CD67da));
        amounts.push(0.001 ether);

        // SPA
        tokens.push(IERC20(0x5575552988A3A80504bBaeB1311674fCFd40aD4B));
        amounts.push(0.01 ether);

        // GMX
        tokens.push(IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a));
        amounts.push(0.001 ether);

        // SYN
        tokens.push(IERC20(0x080F6AEd32Fc474DD5717105Dba5ea57268F46eb));
        amounts.push(0.01 ether);

        // HOP-LP-USDC
        tokens.push(IERC20(0xB67c014FA700E69681a673876eb8BAFAA36BFf71));
        amounts.push(0.01 ether);

        // BRC
        tokens.push(IERC20(0xB5de3f06aF62D8428a8BF7b4400Ea42aD2E0bc53));
        amounts.push(0.01 ether);
        //ELK
        tokens.push(IERC20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE));
        amounts.push(0.01 ether);
        //DBL path
        uniswapPath[address(tokens[0])] = abi.encodePacked(address(tokens[0]), uint24(3000), WETH);
        //DPX path
        paths[address(tokens[1])] = [WETH, address(tokens[1])];
        //LPT path
        uniswapPath[address(tokens[2])] = abi.encodePacked(address(tokens[2]), uint24(3000), WETH);
        //PLS path
        paths[address(tokens[3])] = [WETH, address(tokens[3])];
        // Magic path
        paths[address(tokens[4])] = [WETH, address(tokens[4])];
        // LINK path
        uniswapPath[address(tokens[5])] = bytes(
            hex"f97f4df75117a78c1a5a0dbb814af92458539fb4000bb882af49447d8a07e3bd95bd0d56f35241523fbab1"
        );
        // UMAMI path
        uniswapPath[address(tokens[6])] = abi.encodePacked(address(tokens[6]), uint24(3000), WETH);
        // MYC path
        uniswapPath[address(tokens[7])] = abi.encodePacked(address(tokens[7]), uint24(10000), WETH);
        //VSTA path
        paths[address(tokens[8])] = [WETH, address(tokens[8])];
        //JONES path
        paths[address(tokens[9])] = [WETH, address(tokens[9])];
        //SPA path
        uniswapPath[address(tokens[10])] = abi.encodePacked(address(tokens[10]), uint24(3000), WETH);
        //GMX path
        uniswapPath[address(tokens[11])] = abi.encodePacked(address(tokens[11]), uint24(3000), WETH);
        //SYN path
        uniswapPath[address(tokens[12])] = abi.encodePacked(address(tokens[12]), uint24(10000), WETH);
        //BRC path
        uniswapPath[address(tokens[14])] = abi.encodePacked(
            address(tokens[14]),
            uint24(10000),
            USDC,
            uint24(500),
            WETH
        );
        //ELK path
        paths[address(tokens[15])] = [WETH, address(tokens[15])];
    }

    function bundlePurchase() external payable {
        IWETH(WETH).deposit{ value: msg.value }();
        _handleTip();
        for (uint256 i; i < tokens.length; ) {
            if (paths[address(tokens[i])].length != 0) {
                uint256[] memory inputAmount = sushiRouter.getAmountsIn(amounts[i], paths[address(tokens[1])]);
                sushiRouter.swapTokensForExactTokens(
                    amounts[i],
                    (inputAmount[0] * (BASE_UNIT + slippage)) / BASE_UNIT,
                    paths[address(tokens[i])],
                    msg.sender,
                    block.timestamp + 1000
                );
            } else if (uniswapPath[address(tokens[i])].length != 0) {
                uint256 wethBalance = IERC20(WETH).balanceOf(address(this));

                IUniswapV3Router.ExactOutputParams memory params = IUniswapV3Router.ExactOutputParams({
                    path: uniswapPath[address(tokens[i])],
                    recipient: msg.sender,
                    deadline: block.timestamp + 1000,
                    amountOut: amounts[i],
                    amountInMaximum: wethBalance
                });
                uniswapV3Router.exactOutput(params);
            } else if (elkPaths[address(tokens[i])].length != 0) {
                uint256[] memory inputAmount = sushiRouter.getAmountsIn(amounts[i], elkPaths[address(tokens[1])]);
                sushiRouter.swapTokensForExactTokens(
                    amounts[i],
                    (inputAmount[0] * (BASE_UNIT + slippage)) / BASE_UNIT,
                    elkPaths[address(tokens[i])],
                    msg.sender,
                    block.timestamp + 1000
                );
            } else {
                uint256 wethBalance = IERC20(WETH).balanceOf(address(this));

                uniswapV3Router.exactOutputSingle(
                    IUniswapV3Router.ExactOutputSingleParams({
                        tokenIn: WETH,
                        tokenOut: USDC,
                        fee: 500,
                        recipient: address(this),
                        deadline: block.timestamp + 1000,
                        amountOut: usdcAmount,
                        amountInMaximum: wethBalance,
                        sqrtPriceLimitX96: 0
                    })
                );
                uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
                uint256[] memory amountsIn = new uint256[](2);
                amountsIn[0] = usdcBalance;
                uint256 lpReceived = IHopPool(HOP_USDC_ETH_POOL).addLiquidity(amountsIn, 0, block.timestamp + 1000);
                require(lpReceived > amounts[i], "LP amount not enough");
                tokens[i].transfer(msg.sender, lpReceived);
            }

            unchecked {
                ++i;
            }
        }

        uint256 leftOverWeth = IERC20(WETH).balanceOf(address(this));
        if (leftOverWeth > 0) {
            IWETH(WETH).withdraw(leftOverWeth);
            payable(msg.sender).transfer(leftOverWeth);
        }
    }

    function _handleTip() internal {
        uniswapV3Router.exactInputSingle(
            IUniswapV3Router.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: USDC,
                fee: 500,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountIn: ethTip,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
        IERC20(USDC).transfer(owner(), IERC20(USDC).balanceOf(address(this)));
    }

    function changeUniswapPath(address _token, bytes calldata _newPath) external onlyOwner {
        uniswapPath[_token] = _newPath;
    }

    function changeSushiPath(address _token, address[] calldata _newPath) external onlyOwner {
        paths[_token] = _newPath;
    }

    function recoverToken(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function changeLiquidityAmount(uint256 _newAmount) external onlyOwner {
        usdcAmount = _newAmount;
    }

    function addToken(address _token, uint256 _amount) external onlyOwner {
        tokens.push(IERC20(_token));
        amounts.push(_amount);
    }

    function removeToken(uint256 _index) external onlyOwner {
        tokens[_index] = tokens[tokens.length - 1];
        tokens.pop();

        amounts[_index] = amounts[amounts.length - 1];
        amounts.pop();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface IHopPool {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;
pragma abicoder v2;

interface IUniswapV3Router {
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

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface SushiRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactEthForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}