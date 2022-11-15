//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/IParallaxStrategy.sol";
import "../../interfaces/IParallax.sol";

import "../../extensions/TokensRescuer.sol";

import "./interfaces/ISorbettiere.sol";

import "./interfaces/ICurve.sol";

contract CurveSorbettiereStrategyUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer,
    IParallaxStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _PARALLAX;
        address _SORBETTIERE;
        address _SPELL;
        address _WETH;
        address _USDC;
        address _USDT;
        address _MIM;
        address _SUSHI_SWAP_ROUTER;
        address _USDC_USDT_POOL;
        address _MIM_USDC_USDT_LP_POOL;
        uint256 _EXPIRE_TIME;
        address initialFeesToken;
        uint256 initialCompoundMinAmount;
    }

    address public PARALLAX;

    address public SORBETTIERE;
    address public SPELL;

    address public WETH;
    address public USDC;
    address public USDT;
    address public MIM;

    address public SUSHI_SWAP_ROUTER;

    address public USDC_USDT_POOL;
    address public MIM_USDC_USDT_LP_POOL;

    uint256 public EXPIRE_TIME;

    address public feesToken;

    uint256 public compoundMinAmount;

    modifier onlyWhitelistedToken(address token) {
        require(
            IParallax(PARALLAX).tokenToWhitelisted(token),
            "CurveSorbettiereStrategy: not whitelisted token"
        );
        _;
    }

    modifier onlyParallax() {
        require(
            _msgSender() == PARALLAX,
            "CurveSorbettiereStrategy: not a Parallax"
        );
        _;
    }

    function __CurveSorbettiereStrategy_init(InitParams memory initParams)
        external
        initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __TokensRescuer_init_unchained();
        __CurveSorbettiereStrategy_init_unchained(initParams);
    }

    function __CurveSorbettiereStrategy_init_unchained(
        InitParams memory initParams
    ) public initializer {
        PARALLAX = initParams._PARALLAX;
        SORBETTIERE = initParams._SORBETTIERE;
        SPELL = initParams._SPELL;
        WETH = initParams._WETH;
        MIM = initParams._MIM;
        USDC = initParams._USDC;
        USDT = initParams._USDT;
        SUSHI_SWAP_ROUTER = initParams._SUSHI_SWAP_ROUTER;
        USDC_USDT_POOL = initParams._USDC_USDT_POOL;
        MIM_USDC_USDT_LP_POOL = initParams._MIM_USDC_USDT_LP_POOL;
        EXPIRE_TIME = initParams._EXPIRE_TIME;

        _setFeesToken(initParams.initialFeesToken);

        compoundMinAmount = initParams.initialCompoundMinAmount;
    }

    receive() external payable {}

    fallback() external payable {}

    function rescueNativeToken(uint256 amount, address receiver)
        public
        override(ITokensRescuer, TokensRescuer)
        onlyParallax
    {
        TokensRescuer.rescueNativeToken(amount, receiver);
    }

    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) public override(ITokensRescuer, TokensRescuer) onlyParallax {
        TokensRescuer.rescueERC20Token(token, amount, receiver);
    }

    function setFeesToken(address newFeesToken) external override onlyParallax {
        _setFeesToken(newFeesToken);
    }

    function setCompoundMinAmount(uint256 newCompoundMinAmount)
        external
        override
        onlyParallax
    {
        compoundMinAmount = newCompoundMinAmount;
    }

    function depositLPs(DepositLPs memory params)
        external
        override
        nonReentrant
        onlyParallax
        returns (uint256)
    {
        IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransferFrom(
            params.user,
            address(this),
            params.amount
        );

        // Deposit (stake) Curve's MIM/USDC-USDT LP tokens in the Sorbettiere staking pool
        _sorbettiereDeposit(params.amount);

        return params.amount;
    }

    function depositTokens(DepositTokens memory params)
        external
        override
        nonReentrant
        onlyParallax
        returns (uint256)
    {
        // Transfer equal amounts of USDC, USDT, and MIM tokens from a user to this contract
        IERC20Upgradeable(USDC).safeTransferFrom(
            params.user,
            address(this),
            params.amount
        );
        IERC20Upgradeable(USDT).safeTransferFrom(
            params.user,
            address(this),
            params.amount
        );
        IERC20Upgradeable(MIM).safeTransferFrom(
            params.user,
            address(this),
            params.amount * 10**12
        );

        // Deposit
        uint256 deposited = _deposit(
            DepositParams({
                usdcAmount: params.amount,
                usdtAmount: params.amount,
                mimAmount: params.amount,
                usdcUsdtLPsAmountOutMin: params.amountsOutMin[0],
                mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[1]
            })
        );

        return deposited;
    }

    function swapNativeTokenAndDeposit(SwapNativeTokenAndDeposit memory params)
        external
        payable
        override
        nonReentrant
        onlyParallax
        returns (uint256)
    {
        // Swap native tokens for USDC, USDT, and MIM tokens in equal parts
        uint256 third = msg.value / 3;
        uint256 receivedUsdc = _swapETHForTokens(
            third,
            params.amountsOutMin[0],
            params.paths[0]
        );
        uint256 receivedUsdt = _swapETHForTokens(
            third,
            params.amountsOutMin[1],
            params.paths[1]
        );
        uint256 receivedMim = _swapETHForTokens(
            third,
            params.amountsOutMin[2],
            params.paths[2]
        );

        // Deposit
        uint256 deposited = _deposit(
            DepositParams({
                usdcAmount: receivedUsdc,
                usdtAmount: receivedUsdt,
                mimAmount: receivedMim,
                usdcUsdtLPsAmountOutMin: params.amountsOutMin[3],
                mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[4]
            })
        );

        return deposited;
    }

    function swapERC20TokenAndDeposit(SwapERC20TokenAndDeposit memory params)
        external
        override
        nonReentrant
        onlyParallax
        onlyWhitelistedToken(params.token)
        returns (uint256)
    {
        // Transfer whitelisted ERC20 tokens from a user to this contract
        IERC20Upgradeable(params.token).safeTransferFrom(
            params.user,
            address(this),
            params.amount
        );

        // Swap ERC20 tokens for USDC, USDT, and MIM tokens in equal parts
        uint256 third = params.amount / 3;
        uint256 receivedUsdc = _swapTokensForTokens(
            params.token,
            third,
            params.amountsOutMin[0],
            params.paths[0]
        );
        uint256 receivedUsdt = _swapTokensForTokens(
            params.token,
            third,
            params.amountsOutMin[1],
            params.paths[1]
        );
        uint256 receivedMim = _swapTokensForTokens(
            params.token,
            third,
            params.amountsOutMin[2],
            params.paths[2]
        );

        // Deposit
        uint256 deposited = _deposit(
            DepositParams({
                usdcAmount: receivedUsdc,
                usdtAmount: receivedUsdt,
                mimAmount: receivedMim,
                usdcUsdtLPsAmountOutMin: params.amountsOutMin[3],
                mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[4]
            })
        );

        return deposited;
    }

    function withdrawLPs(WithdrawLPs memory params)
        external
        nonReentrant
        onlyParallax
    {
        // Withdraw (unstake) Curve's MIM/USDC-USDT LP tokens from the Sorbettiere staking pool
        _sorbettiereWithdraw(params.amount);

        // Calculate withdrawal fee and actual witdraw
        (
            uint256 actualWithdraw,
            uint256 withdrawalFee
        ) = _calculateActualWithdrawAndWithdrawalFee(params.amount);

        // Send tokens to the receiver and withdrawal fee to the fees receiver
        IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransfer(
            params.receiver,
            actualWithdraw
        );
        IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransfer(
            IParallax(PARALLAX).feesReceiver(),
            withdrawalFee
        );
    }

    function withdrawTokens(WithdrawTokens memory params)
        external
        nonReentrant
        onlyParallax
    {
        (
            uint256 usdcLiquidity,
            uint256 usdtLiquidity,
            uint256 mimLiquidity
        ) = _withdraw(
                WithdrawParams({
                    amount: params.amount,
                    mimAmountOutMin: params.amountsOutMin[0],
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                    usdcAmountOutMin: params.amountsOutMin[2],
                    usdtAmountOutMin: params.amountsOutMin[3]
                })
            );

        // Calculate withdrawal fee and actual witdraw
        uint256 witdrawalAmount = (
            feesToken == USDC
                ? usdcLiquidity
                : (feesToken == USDT ? usdtLiquidity : mimLiquidity)
        );
        (, uint256 withdrawalFee) = _calculateActualWithdrawAndWithdrawalFee(
            witdrawalAmount
        );

        withdrawalFee *= 3;

        // Send tokens to the receiver and withdrawal fee to the fees receiver
        IERC20Upgradeable(USDC).safeTransfer(
            params.receiver,
            feesToken == USDC ? usdcLiquidity - withdrawalFee : usdcLiquidity
        );
        IERC20Upgradeable(USDT).safeTransfer(
            params.receiver,
            feesToken == USDT ? usdtLiquidity - withdrawalFee : usdtLiquidity
        );
        IERC20Upgradeable(MIM).safeTransfer(
            params.receiver,
            feesToken == MIM ? mimLiquidity - withdrawalFee : mimLiquidity
        );
        IERC20Upgradeable(feesToken).safeTransfer(
            IParallax(PARALLAX).feesReceiver(),
            withdrawalFee
        );
    }

    function withdrawAndSwapForNativeToken(
        WithdrawAndSwapForNativeToken memory params
    ) external override nonReentrant onlyParallax {
        (
            uint256 usdcLiquidity,
            uint256 usdtLiquidity,
            uint256 mimLiquidity
        ) = _withdraw(
                WithdrawParams({
                    amount: params.amount,
                    mimAmountOutMin: params.amountsOutMin[0],
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                    usdcAmountOutMin: params.amountsOutMin[2],
                    usdtAmountOutMin: params.amountsOutMin[3]
                })
            );

        // Swap USDC, USDT, and MIM tokens for native tokens
        uint256 receivedETH = _swapTokensForETH(
            USDC,
            usdcLiquidity,
            params.amountsOutMin[4],
            params.paths[0]
        );

        receivedETH += _swapTokensForETH(
            USDT,
            usdtLiquidity,
            params.amountsOutMin[5],
            params.paths[1]
        );
        receivedETH += _swapTokensForETH(
            MIM,
            mimLiquidity,
            params.amountsOutMin[6],
            params.paths[2]
        );

        // Calculate withdrawal fee and actual witdraw
        (
            uint256 actualWithdraw,
            uint256 withdrawalFee
        ) = _calculateActualWithdrawAndWithdrawalFee(receivedETH);

        // Send tokens to the receiver and withdrawal fee to the fees receiver
        AddressUpgradeable.sendValue(payable(params.receiver), actualWithdraw);
        AddressUpgradeable.sendValue(
            payable(IParallax(PARALLAX).feesReceiver()),
            withdrawalFee
        );
    }

    function withdrawAndSwapForERC20Token(
        WithdrawAndSwapForERC20Token memory params
    )
        external
        override
        nonReentrant
        onlyParallax
        onlyWhitelistedToken(params.token)
    {
        (
            uint256 usdcLiquidity,
            uint256 usdtLiquidity,
            uint256 mimLiquidity
        ) = _withdraw(
                WithdrawParams({
                    amount: params.amount,
                    mimAmountOutMin: params.amountsOutMin[0],
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                    usdcAmountOutMin: params.amountsOutMin[2],
                    usdtAmountOutMin: params.amountsOutMin[3]
                })
            );

        // Swap USDC, USDT, and MIM tokens for ERC20 tokens
        uint256 receivedERC20 = _swapTokensForTokens(
            USDC,
            usdcLiquidity,
            params.amountsOutMin[4],
            params.paths[0]
        );

        receivedERC20 += _swapTokensForTokens(
            USDT,
            usdtLiquidity,
            params.amountsOutMin[5],
            params.paths[1]
        );
        receivedERC20 += _swapTokensForTokens(
            MIM,
            mimLiquidity,
            params.amountsOutMin[6],
            params.paths[2]
        );

        // Calculate withdrawal fee and actual witdraw
        (
            uint256 actualWithdraw,
            uint256 withdrawalFee
        ) = _calculateActualWithdrawAndWithdrawalFee(receivedERC20);

        // Send tokens to the receiver and withdrawal fee to the fees receiver
        IERC20Upgradeable(params.token).safeTransfer(
            params.receiver,
            actualWithdraw
        );
        IERC20Upgradeable(params.token).safeTransfer(
            IParallax(PARALLAX).feesReceiver(),
            withdrawalFee
        );
    }

    function compound(uint256[] memory amountsOutMin)
        public
        nonReentrant
        onlyParallax
        returns (uint256)
    {
        return _compound(amountsOutMin);
    }

    function _setFeesToken(address token) private {
        require(
            token == USDC || token == USDT || token == MIM,
            "CurveSorbettiereStrategy: invalid fees token"
        );

        feesToken = token;
    }

    function _deposit(DepositParams memory params) private returns (uint256) {
        // Add liquidity to the Curve's USDC/USDT and MIM/USDC-USDT liquidity pools
        uint256 receivedUsdcUsdtLPs = _curveAddLiquidity(
            USDC_USDT_POOL,
            USDC,
            params.usdcAmount,
            USDT,
            params.usdtAmount,
            params.usdcUsdtLPsAmountOutMin
        );
        uint256 receivedMimUsdcUsdtLPs = _curveAddLiquidity(
            MIM_USDC_USDT_LP_POOL,
            MIM,
            params.mimAmount,
            USDC_USDT_POOL,
            receivedUsdcUsdtLPs,
            params.mimUsdcUsdtLPsAmountOutMin
        );

        // Deposit (stake) Curve's MIM/USDC-USDT LP tokens in the Sorbettiere staking pool
        _sorbettiereDeposit(receivedMimUsdcUsdtLPs);

        return receivedMimUsdcUsdtLPs;
    }

    function _withdraw(WithdrawParams memory params)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Withdraw (unstake) Curve's MIM/USDC-USDT LP tokens from the Sorbettiere staking pool
        _sorbettiereWithdraw(params.amount);

        // Remove liquidity from the Curve's MIM/USDC-USDT and USDC/USDT liquidity pools
        uint256[2] memory mimUsdcUsdtLPsLiquidity = _curveRemoveLiquidity(
            MIM_USDC_USDT_LP_POOL,
            params.amount,
            params.mimAmountOutMin,
            params.usdcUsdtLPsAmountOutMin
        );
        uint256[2] memory usdcUsdtLiquidity = _curveRemoveLiquidity(
            USDC_USDT_POOL,
            mimUsdcUsdtLPsLiquidity[1],
            params.usdcAmountOutMin,
            params.usdtAmountOutMin
        );

        return (
            usdcUsdtLiquidity[0],
            usdcUsdtLiquidity[1],
            mimUsdcUsdtLPsLiquidity[0]
        );
    }

    function _harvest(uint256 swapMimAmountOutMin)
        private
        returns (uint256 receivedMim)
    {
        // Harvest rewards from the Sorbettiere (in SPELL tokens)
        _sorbettiereDeposit(0);

        uint256 spellBalance = IERC20Upgradeable(SPELL).balanceOf(
            address(this)
        );

        // Swap Sorbettiere rewards (SPELL tokens) for MIM tokens
        if (spellBalance >= compoundMinAmount) {
            receivedMim = _swapTokensForTokens(
                SPELL,
                spellBalance,
                swapMimAmountOutMin,
                _toDynamicArray([SPELL, MIM])
            );
        }
    }

    function _compound(uint256[] memory amountsOutMin)
        private
        returns (uint256)
    {
        // Harvest SPELL tokens and swap to MIM tokens
        uint256 receivedMim = _harvest(amountsOutMin[0]);

        if (receivedMim != 0) {
            // Swap one third of MIM tokens for USDC and another third for USDT
            (
                uint256 receivedUsdc,
                uint256 receivedUsdt,
                uint256 remainingMim
            ) = _swapThirdOfMimToUsdcAndThirdToUsdt(
                    receivedMim,
                    amountsOutMin[1],
                    amountsOutMin[2]
                );

            // Reinvest swapped tokens (earned rewards)
            return
                _deposit(
                    DepositParams({
                        usdcAmount: receivedUsdc,
                        usdtAmount: receivedUsdt,
                        mimAmount: remainingMim,
                        usdcUsdtLPsAmountOutMin: amountsOutMin[3],
                        mimUsdcUsdtLPsAmountOutMin: amountsOutMin[4]
                    })
                );
        }

        return 0;
    }

    function _sorbettiereDeposit(uint256 amount) private {
        ICurve(MIM_USDC_USDT_LP_POOL).approve(SORBETTIERE, amount);
        ISorbettiere(SORBETTIERE).deposit(0, amount);
    }

    function _sorbettiereWithdraw(uint256 amount) private {
        ISorbettiere(SORBETTIERE).withdraw(0, amount);
    }

    function _curveAddLiquidity(
        address pool,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        uint256 amountOutMin
    ) private returns (uint256) {
        IERC20(tokenA).approve(pool, amountA);
        IERC20(tokenB).approve(pool, amountB);

        return ICurve(pool).add_liquidity([amountA, amountB], amountOutMin);
    }

    function _curveRemoveLiquidity(
        address pool,
        uint256 amount,
        uint256 minAmountOutA,
        uint256 minAmountOutB
    ) private returns (uint256[2] memory) {
        ICurve(pool).approve(pool, amount);

        return
            ICurve(pool).remove_liquidity(
                amount,
                [minAmountOutA, minAmountOutB]
            );
    }

    function _swapThirdOfMimToUsdcAndThirdToUsdt(
        uint256 mimTokensAmount,
        uint256 usdcAmoutOutMin,
        uint256 usdtAmountOutMin
    )
        private
        returns (
            uint256 receivedUsdc,
            uint256 receivedUsdt,
            uint256 remainingMim
        )
    {
        uint256 third = mimTokensAmount / 3;
        receivedUsdc = _swapTokensForTokens(
            MIM,
            third,
            usdcAmoutOutMin,
            _toDynamicArray([MIM, WETH, USDC])
        );
        receivedUsdt = _swapTokensForTokens(
            MIM,
            third,
            usdtAmountOutMin,
            _toDynamicArray([MIM, WETH, USDT])
        );
        remainingMim = third;
    }

    function _swapETHForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) private returns (uint256 amount) {
        if (path.length == 0) {
            return 0;
        }

        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            address(this),
            _getDeadline()
        );

        return amounts[amounts.length - 1];
    }

    function _swapTokensForETH(
        address token,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) private returns (uint256 amount) {
        if (path.length == 0) {
            return 0;
        }

        IERC20Upgradeable(token).safeIncreaseAllowance(
            SUSHI_SWAP_ROUTER,
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                _getDeadline()
            );

        return amounts[amounts.length - 1];
    }

    function _swapTokensForTokens(
        address token,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) private returns (uint256 amount) {
        // Path length must be 0 when swap is not needed (ex. exchange USDT to USDT, or MIM to MIM)
        if (path.length == 0) {
            return amountIn;
        }

        IERC20Upgradeable(token).safeIncreaseAllowance(
            SUSHI_SWAP_ROUTER,
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                _getDeadline()
            );

        return amounts[amounts.length - 1];
    }

    function _calculateActualWithdrawAndWithdrawalFee(uint256 witdrawalAmount)
        private
        view
        returns (uint256 actualWithdraw, uint256 withdrawalFee)
    {
        actualWithdraw =
            (witdrawalAmount *
                (10000 - IParallax(PARALLAX).getWithdrawalFee(address(this)))) /
            10000;
        withdrawalFee = witdrawalAmount - actualWithdraw;
    }

    function _getDeadline() private view returns (uint256) {
        return block.timestamp + EXPIRE_TIME;
    }

    function _toDynamicArray(address[2] memory input)
        private
        pure
        returns (address[] memory)
    {
        address[] memory output = new address[](2);

        for (uint256 i = 0; i < input.length; ++i) {
            output[i] = input[i];
        }

        return output;
    }

    function _toDynamicArray(address[3] memory input)
        private
        pure
        returns (address[] memory)
    {
        address[] memory output = new address[](3);

        for (uint256 i = 0; i < input.length; ++i) {
            output[i] = input[i];
        }

        return output;
    }

    function _toDynamicArray(uint256[3] memory input)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](3);

        for (uint256 i = 0; i < input.length; ++i) {
            output[i] = input[i];
        }

        return output;
    }

    uint256[200] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokensRescuer.sol";

interface IParallaxStrategy is ITokensRescuer {
    struct DepositLPs {
        uint256 amount;
        address user;
    }

    struct DepositTokens {
        uint256[] amountsOutMin;
        uint256 amount;
        address user;
    }

    struct SwapNativeTokenAndDeposit {
        uint256[] amountsOutMin;
        address[][] paths;
    }

    struct SwapERC20TokenAndDeposit {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 amount;
        address token;
        address user;
    }

    struct DepositParams {
        uint256 usdcAmount;
        uint256 usdtAmount;
        uint256 mimAmount;
        uint256 usdcUsdtLPsAmountOutMin;
        uint256 mimUsdcUsdtLPsAmountOutMin;
    }

    struct WithdrawLPs {
        uint256 amount;
        address receiver;
    }

    struct WithdrawTokens {
        uint256[] amountsOutMin;
        uint256 amount;
        address receiver;
    }

    struct WithdrawAndSwapForNativeToken {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 amount;
        address receiver;
    }

    struct WithdrawAndSwapForERC20Token {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 amount;
        address token;
        address receiver;
    }

    struct WithdrawParams {
        uint256 amount;
        uint256 mimAmountOutMin;
        uint256 usdcUsdtLPsAmountOutMin;
        uint256 usdcAmountOutMin;
        uint256 usdtAmountOutMin;
    }

    function setFeesToken(address token) external;

    function setCompoundMinAmount(uint256 compoundMinAmount) external;

    function depositLPs(DepositLPs memory params) external returns (uint256);

    function depositTokens(DepositTokens memory params)
        external
        returns (uint256);

    function swapNativeTokenAndDeposit(SwapNativeTokenAndDeposit memory params)
        external
        payable
        returns (uint256);

    function swapERC20TokenAndDeposit(SwapERC20TokenAndDeposit memory params)
        external
        returns (uint256);

    function withdrawLPs(WithdrawLPs memory params) external;

    function withdrawTokens(WithdrawTokens memory params) external;

    function withdrawAndSwapForNativeToken(
        WithdrawAndSwapForNativeToken memory params
    ) external;

    function withdrawAndSwapForERC20Token(
        WithdrawAndSwapForERC20Token memory params
    ) external;

    function compound(uint256[] memory amountsOutMin)
        external
        returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ITokensRescuer.sol";

abstract contract TokensRescuer is Initializable, ITokensRescuer {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokensRescuer_init_unchained() internal initializer {}

    function rescueNativeToken(uint256 amount, address receiver)
        public
        virtual
    {
        AddressUpgradeable.sendValue(payable(receiver), amount);
    }

    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) public virtual {
        IERC20Upgradeable(token).transfer(receiver, amount);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IParallax {
    struct Deposit0 {
        uint256[] compoundAmountsOutMin;
        uint256 strategyId;
        uint256 positionId;
        uint256 amount;
    }

    struct Deposit1 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        uint256 strategyId;
        uint256 positionId;
        uint256 amount;
    }

    struct Deposit2 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
    }

    struct Deposit3 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
        uint256 amount;
        address token;
    }

    struct Withdraw0 {
        uint256[] compoundAmountsOutMin;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
    }

    struct Withdraw1 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
    }

    struct Withdraw2 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
    }

    struct Withdraw3 {
        uint256[] compoundAmountsOutMin;
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
        address token;
    }

    function feesReceiver() external view returns (address);

    function getWithdrawalFee(address strategy) external view returns (uint256);

    function tokenToWhitelisted(address token) external view returns (bool);
}

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.15;

interface ISorbettiere {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 remainingIceTokenReward;
    }

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function userInfo(uint256 pid, address user)
        external
        view
        returns (UserInfo memory);

    function pendingIce(uint256 pid, address user)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.15;

interface ICurve is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 minMintAmount)
        external
        returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] calldata minAmounts)
        external
        returns (uint256[2] memory);

    function calc_token_amount(uint256[2] calldata amounts, bool isDeposit)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITokensRescuer {
    function rescueNativeToken(uint256 amount, address receiver) external;

    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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
interface IERC20PermitUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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