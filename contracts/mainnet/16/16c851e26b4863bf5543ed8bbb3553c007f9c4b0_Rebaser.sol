// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { ISwapPair } from "./interfaces/ISwapPair.sol";
import { IRebaser } from "./interfaces/IRebaser.sol";

contract Rebaser is IRebaser {

    address public _token;
    address public admin;
    bool private inRebase;
    bool public rebaseEnabled;

    uint256 public liquidityUnlockTime;
    uint256 public percentToRemove = 9800; // 98%
    uint256 public divisor = 10000;
    uint256 public teamFee = 5 * 10**5; // $0.50
    address public teamAddress;

    ISwapRouter public swapRouter;
    address public immutable USDC;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public swapPair;
    ISwapPair public pair;
    address public tokenA;
    address public tokenB;

    event LiquidityLocked(uint256 lockedLiquidityAmount, uint256 liquidityLockExpiration);
    event AdminUpdated(address newAdmin);
    event AdminRenounced();

    modifier onlyAdmin {
        require(msg.sender == admin, "Caller not Admin");
        _;
    }

    modifier lockTheSwap {
        inRebase = true;
        _;
        inRebase = false;
    }

    modifier onlyToken() {
        require(msg.sender == _token, "Caller not Token"); 
        _;
    }

    constructor(address _router, address _usdc, address _admin, address _teamAddress, address _pair) {
        swapRouter = ISwapRouter(_router);
        _token = msg.sender;
        USDC = _usdc;
        admin = _admin;
        teamAddress = _teamAddress;

        swapPair = _pair;
        pair = ISwapPair(_pair);

        tokenA = pair.token0();
        tokenB = pair.token1();
    }

    receive() external payable {}
   
    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function renounceAdminRole() external onlyAdmin {
        admin = address(0);
        emit AdminRenounced();
    }

    function setRebaseEnabled(bool flag) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        rebaseEnabled = flag;
    }

    function setPercentToRemove(uint256 _percent) external onlyAdmin {
        percentToRemove = _percent;
    }

    function setTeamAddress(address _teamAddress) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        teamAddress = _teamAddress;
    }

    function setTeamFee(uint256 _amount) external onlyAdmin {
        teamFee = _amount;
    }

    function setSwapPair(address _pair) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        swapPair = _pair;
        pair = ISwapPair(_pair);

        tokenA = pair.token0();
        tokenB = pair.token1();
    }

    function depositAndLockLiquidity(uint256 _amount, uint256 _unlockTime) external onlyAdmin {
        require(liquidityUnlockTime <= _unlockTime, "Can not shorten lock time");
        IERC20(swapPair).transferFrom(msg.sender, address(this), _amount);
        liquidityUnlockTime = _unlockTime;
        emit LiquidityLocked(_amount, _unlockTime);
    }

    function rebase(
        uint256 currentPrice, 
        uint256 targetPrice
    ) external override onlyToken lockTheSwap returns (
        uint256 amountToSwap,
        uint256 amountUSDCtoAdd,
        uint256 burnAmount
    ) {
        if(rebaseEnabled){
            removeLiquidity();
            uint256 balanceUSDC = IERC20(USDC).balanceOf(address(this));
            (uint reserve0, uint reserve1,) = pair.getReserves();
            uint256 adjustment = (((targetPrice * 10**18) / currentPrice) - 10**18) / 2;
            if(pair.token0() == USDC) {  
                uint256 reserve0Needed = (reserve0 * (adjustment + 10**18)) /  10**18;
                amountToSwap = reserve0Needed - reserve0;
            } else if(pair.token1() == USDC) {
                uint256 reserve1Needed = (reserve1 * (adjustment + 10**18)) / 10**18;
                amountToSwap = reserve1Needed - reserve1;
            }
            uint256 amountUSDCAvailable = balanceUSDC - amountToSwap;
            amountUSDCtoAdd = amountUSDCAvailable - teamFee;
            buyTokens(amountToSwap, amountUSDCtoAdd);
            IERC20(USDC).transfer(teamAddress, teamFee);
            burnAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(BURN_ADDRESS, burnAmount);
        } 
    }

    // Remove bnb that is sent here by mistake
    function removeBNB(uint256 amount, address to) external onlyAdmin{
        payable(to).transfer(amount);
      }

    // Remove tokens that are sent here by mistake
    function removeToken(IERC20 token, uint256 amount, address to) external onlyAdmin {
        if (block.timestamp < liquidityUnlockTime) {
            require(token != IERC20(swapPair), "Liquidity is locked");
        }
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    function removeLiquidity() internal {
        uint256 amountToRemove = (IERC20(swapPair).balanceOf(address(this)) * percentToRemove) / divisor;
       
        IERC20(swapPair).approve(address(swapRouter), amountToRemove);
        
        // Remove the liquidity
        swapRouter.removeLiquidity(
            tokenA,
            tokenB,
            amountToRemove,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }

    function buyTokens(uint256 amountToSwap, uint256 amountUSDCtoAdd) internal {
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = _token;

        IERC20(USDC).approve(address(swapRouter), amountToSwap);

        swapRouter.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        addLiquidity(amountUSDCtoAdd); 
    }

    function addLiquidity(uint256 amountUSDCtoAdd) internal {
        uint256 amountTokenToAdd = IERC20(_token).balanceOf(address(this));
       
        IERC20(_token).approve(address(swapRouter), amountTokenToAdd);
        IERC20(USDC).approve(address(swapRouter), amountUSDCtoAdd);
        
        // Add the liquidity
        swapRouter.addLiquidity(
            _token,
            USDC,
            amountTokenToAdd,
            amountUSDCtoAdd,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IRebaser {
    function rebase(
        uint256 currentPrice, 
        uint256 targetPrice
    ) external returns (
        uint256 amountToSwap,
        uint256 amountUSDTtoAdd,
        uint256 burnAmount
    );
    function setTeamAddress(address _teamAddress) external;
    function setRebaseEnabled(bool flag) external;
    function setSwapPair(address _pair) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapPair {

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import { ISwapRouter01 } from "./ISwapRouter01.sol";

interface ISwapRouter is ISwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function factory() external pure returns (address);
}