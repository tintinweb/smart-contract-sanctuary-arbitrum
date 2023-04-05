/**
 *Submitted for verification at Arbiscan on 2023-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IArbiDexRouter {
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (
        uint[] memory amounts
    );
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin,
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (
        uint[] memory amounts
    );
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB, 
        uint liquidity
    );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB
    );
}

interface IArbiDexZapV1 {
    function estimateZapInSwap(
        address _tokenToZap, 
        uint256 _tokenAmountIn, 
        address _lpToken
    ) external view returns (
        uint256 swapAmountIn,
        uint256 swapAmountOut,
        address swapTokenOut
    );
    function estimateZapOutSwap(
        address _tokenToZap, 
        uint256 _tokenAmountIn, 
        address _lpToken
    ) external view returns (
        uint256 swapAmountIn,
        uint256 swapAmountOut,
        address swapTokenOut
    );
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 arxRewardDebt; // Reward debt. See explanation below.
        uint256 WETHRewardDebt; // Reward debt. See explanation below.
    }
    function userInfo(address user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract AutoCompound {
    // The owner of the contract (Admin)
    address public owner;

    // The address of the treasury where all of the deposit and performance fees are sent
    address public treasury = 0x9E90E79103D7E5446765135BCA64AaEA77F0C630;

    // The address of the router
    address public router = 0x3E48298A5Fe88E4d62985DFf65Dee39a25914975;

    // The address of the zapper that is used for conducting zaps
    address public zapper = 0xaaA79f00a7a2D224307f7753eD8493d64e9f1824;

    // The address of the masterchef
    address public masterchef = 0xd2bcFd6b84E778D2DE5Bb6A167EcBBef5D053A06;

    // The pool id of the pool where the underlying deposits and withdrawals are made
    uint256 public pid = 1;

    // The ARX token
    address ARX = 0xD5954c3084a1cCd70B4dA011E67760B8e78aeE84;

    // The WETH token
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // The USDC token
    address USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    // The ArbDex-LP token for ARX-USDC
    address lpToken = 0xA6efAE0C9293B4eE340De31022900bA747eaA92D;

    // The current take profit percentage
    uint256 public takeProfit = 50;

    // The total supply of staked tokens, that have be deposited by users
    uint256 public totalSupply;

    constructor() {
        owner = msg.sender;
        IERC20(lpToken).approve(masterchef, type(uint256).max);
        IERC20(lpToken).approve(router, type(uint256).max);
        IERC20(USDC).approve(router, type(uint256).max);
        IERC20(ARX).approve(router, type(uint256).max);
        IERC20(WETH).approve(router, type(uint256).max);
    }

    event Deposit(address indexed user, uint256 amount);
    event TokenRecovery(address indexed token, uint256 amount);
    event WithdrawAll(address indexed user, uint256 amount);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function harvestProfit(uint256 ARXTakeProfit, uint256 WETHTakeProfit) internal {
        // The path for swapping ARX to USDC
        address[] memory swapPath;
        swapPath[0] = ARX;
        swapPath[1] = USDC;
        // Lets compute the amount we would get out for swapping ARX to USDC
        uint256[] memory swapAmountsOut = IArbiDexRouter(router).getAmountsOut(ARXTakeProfit, swapPath);
        // Lets execute the swap and get USDC out, that way all of our tokens are in USDC
        IArbiDexRouter(router).swapExactTokensForTokens(ARXTakeProfit, swapAmountsOut[swapAmountsOut.length-1], swapPath, treasury, block.timestamp+120);

        // The path for swapping WETH to USDC
        address[] memory swapPath2;
        swapPath[0] = WETH;
        swapPath[1] = USDC;
        // Lets compute the amount we would get out for swapping WETH to USDC
        uint256[] memory swapAmountsOut2 = IArbiDexRouter(router).getAmountsOut(WETHTakeProfit, swapPath2);
        // Lets execute the swap and get USDC out, that way all of our tokens are in USDC
        IArbiDexRouter(router).swapExactTokensForTokens(WETHTakeProfit, swapAmountsOut2[swapAmountsOut2.length-1], swapPath2, treasury, block.timestamp+120);
    }

    function harvest() public {
        IMasterChef(masterchef).deposit(pid, 0);

        uint256 harvestedARX = IERC20(ARX).balanceOf(address(this));
        uint256 harvestedWETH = IERC20(WETH).balanceOf(address(this));

        // Calculate the take profit fee for ARX
        uint256 ARXFeeAmount = (harvestedARX * takeProfit)/100;
        harvestedARX = harvestedARX - ARXFeeAmount;
        // Calculate the take profit fee for WETH
        uint256 WETHFeeAmount = (harvestedWETH * takeProfit)/100;
        harvestedWETH = harvestedWETH - WETHFeeAmount;
        // Have a seperate function actually take the profit
        harvestProfit(ARXFeeAmount, WETHFeeAmount);

        // The path for swapping WETH to ARX
        address[] memory swapPath;
        swapPath[0] = WETH;
        swapPath[1] = ARX;
        // Lets compute the amount we would get out for swapping WETH for ARX
        uint256[] memory swapAmountsOut = IArbiDexRouter(router).getAmountsOut(harvestedWETH, swapPath);
        // Lets execute the swap and get ARX out, that way all of our tokens are in ARX
        IArbiDexRouter(router).swapExactTokensForTokens(harvestedWETH, swapAmountsOut[swapAmountsOut.length-1], swapPath, address(this), block.timestamp+120);

        (uint256 amountIn, uint256 amountOut,) = IArbiDexZapV1(zapper).estimateZapInSwap(ARX, IERC20(ARX).balanceOf(address(this)), lpToken);
        address[] memory path;
        path[0] = ARX; path[1] = USDC;
        IArbiDexRouter(router).swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp+120);
        IArbiDexRouter(router).addLiquidity(ARX, USDC, amountIn, amountOut, ((amountIn*90)/100), ((amountOut*90)/100), address(this), block.timestamp+120);

        totalSupply += IERC20(lpToken).balanceOf(address(this));
        IMasterChef(masterchef).deposit(pid, IERC20(lpToken).balanceOf(address(this)));
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount to deposit must be greater than zero");

        harvest();

        IERC20(USDC).transferFrom(address(msg.sender), address(this), _amount);

        (uint256 amountIn, uint256 amountOut,) = IArbiDexZapV1(zapper).estimateZapInSwap(USDC, IERC20(USDC).balanceOf(address(this)), lpToken);
        address[] memory path;
        path[0] = USDC; path[1] = ARX;
        IArbiDexRouter(router).swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp+120);
        IArbiDexRouter(router).addLiquidity(ARX, USDC, amountIn, amountOut, ((amountIn*90)/100), ((amountOut*90)/100), address(this), block.timestamp+120);

        totalSupply += IERC20(lpToken).balanceOf(address(this));
        IMasterChef(masterchef).deposit(pid, IERC20(lpToken).balanceOf(address(this)));

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw all staked tokens, collect reward tokens, and withdraw all as LP
     */
    function withdrawAll() external onlyOwner {
        harvest();

        IMasterChef(masterchef).withdraw(pid, totalSupply);
        IERC20(lpToken).transfer(treasury, totalSupply);
        totalSupply = 0;

        emit WithdrawAll(msg.sender, totalSupply);
    }

    /*
     * @notce Recover a token that was accidentally sent to this contract
     * @param _percent: The take profit percentage
    */
    function setTakeProfit(uint256 _percent) external onlyOwner {
        require(_percent >= 0, "Operations: Percent cannot be below zero");
        require(_percent <= 100, "Operations: Percent too large");
        takeProfit = _percent;
    }

    /*
     * @notce Recover a token that was accidentally sent to this contract
     * @param _token: The token that needs to be retrieved
     * @param _amount: The amount of tokens to be recovered
    */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Operations: Cannot be zero address");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Operations: Amount to transfer too high");
        IERC20(_token).transfer(treasury, _amount);
    }
}