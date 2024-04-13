// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


interface ISubscriptions0xVPN {
    function extendSubscription(address subscriber, uint256 addedTimeInSeconds) external;
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract Subscriptions0xVPN is Ownable {

    mapping (address => uint256) public expirationTimestamps;
    mapping (address => bool) public isManager;
    address[] public subscribers;
    event Subscription(address indexed subscriber, uint256 expirationTimestamp);
    string public constant version = "1.0.0";
    IUniswapV2Router02 public uniswapRouter;
    address public usdToken;
    uint256 public pricePerHourUSDBps = 7; // 0.007 USD/hr

    constructor(address _uniswapRouter, address _usdToken) Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        usdToken = _usdToken;
    }
    
    function _extendSubscription(address subscriber, uint256 addedTimeInSeconds) private {
        
        if (expirationTimestamps[subscriber] == 0) {
            subscribers.push(subscriber);
        }
        if (expirationTimestamps[subscriber] < block.timestamp) {
            expirationTimestamps[subscriber] = block.timestamp + addedTimeInSeconds;
        } else{
            expirationTimestamps[subscriber] += addedTimeInSeconds;
        }
        emit Subscription(subscriber, expirationTimestamps[subscriber]);
    }

    function _revoke(address subscriber) private {
        expirationTimestamps[subscriber] = 0;
    }

    function getSubscribers() external view returns (address[] memory) {
        return subscribers;
    }

    function subscribe() public payable {
        require(msg.value > 0, "Payment required");
        uint256 hourlyNativePrice = getHourlyNativePrice();
        uint256 hoursToAdd = msg.value / hourlyNativePrice;
        require(hoursToAdd > 0, "Not enough native token");
        uint256 addedTimeInSeconds = hoursToAdd * 3600;

        _extendSubscription(msg.sender, addedTimeInSeconds);
    }

    function getHourlyNativePrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = usdToken;
        if (address(uniswapRouter) == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4) {
            path[1] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        } else {
            path[1] = uniswapRouter.WETH();
        }

        uint256 usdtDecimals = IERC20(usdToken).decimals();
        uint256 usdtAmount = pricePerHourUSDBps * 10**usdtDecimals / 1000;
        uint[] memory amounts = uniswapRouter.getAmountsOut(usdtAmount, path);

        return amounts[1];
    }
 

    // Admin and Manager functions
    function setManagerRole(address manager, bool flag) external onlyOwner {
        isManager[manager] = flag;
    }

    function setPricePerHourUSD(uint256 _pricePerHourUSDBps) external onlyOwner {
        pricePerHourUSDBps = _pricePerHourUSDBps;
    }

    function withdraw() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: contractETHBalance}("");
        require(sent, "Failed to send Eth");
    }

    function extendSubscription(address subscriber, uint256 addedTimeInSeconds) external {
        require(isManager[msg.sender], "Only managers");
        _extendSubscription(subscriber, addedTimeInSeconds);
    }

    function revoke(address subscriber) external {
        require(isManager[msg.sender], "Only managers");
        _revoke(subscriber);
    }


    //fallback function to receive ether triggers subscribe
    receive() external payable {
        subscribe();
    }
    
}