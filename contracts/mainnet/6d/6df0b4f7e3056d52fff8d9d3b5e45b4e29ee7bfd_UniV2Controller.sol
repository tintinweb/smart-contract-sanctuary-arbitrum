// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IController {

    /**
        @notice General function that evaluates whether the target contract can
        be interacted with using the specified calldata
        @param target Address of external protocol/interaction
        @param useEth Specifies if Eth is being sent to the target
        @param data Calldata of the call made to target
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniV2Factory {
    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IUniV2Factory} from "./IUniV2Factory.sol";

/**
    @title Uniswap V2 Controller
    @notice Controller for uniswap v2 interaction
    eth:0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
*/
contract UniV2Controller is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice swapExactTokensForTokens(uint256,uint256,address[],address,uint256)	function signature
    bytes4 constant SWAP_EXACT_TOKENS_FOR_TOKENS = 0x38ed1739;

    /// @notice swapTokensForExactTokens(uint256,uint256,address[],address,uint256)	function signature
    bytes4 constant SWAP_TOKENS_FOR_EXACT_TOKENS = 0x8803dbee;

    /// @notice swapExactETHForTokens(uint256,address[],address,uint256) function signature
    bytes4 constant SWAP_EXACT_ETH_FOR_TOKENS = 0x7ff36ab5;

    /// @notice swapTokensForExactETH(uint256,uint256,address[],address,uint256) function signature
    bytes4 constant SWAP_TOKENS_FOR_EXACT_ETH = 0x4a25d94a;

    /// @notice swapExactTokensForETH(uint256,uint256,address[],address,uint256) function signature
    bytes4 constant SWAP_EXACT_TOKENS_FOR_ETH = 0x18cbafe5;

    /// @notice swapETHForExactTokens(uint256,address[],address,uint256) function signature
    bytes4 constant SWAP_ETH_FOR_EXACT_TOKENS = 0xfb3bdb41;

    /// @notice addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256) function signature
    bytes4 constant ADD_LIQUIDITY = 0xe8e33700;

    /// @notice removeLiquidity(address,address,uint256,uint256,uint256,address,uint256) function signature
    bytes4 constant REMOVE_LIQUIDITY = 0xbaa2abde;

    /// @notice addLiquidityETH(address,uint256,uint256,uint256,address,uint256) function signature
    bytes4 constant ADD_LIQUIDITY_ETH = 0xf305d719;

    /// @notice removeLiquidityETH(address,uint256,uint256,uint256,address,uint256) function signature
    bytes4 constant REMOVE_LIQUIDITY_ETH = 0x02751cec;

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @notice WETH address
    address public immutable WETH;

    /// @notice Uniswap v2 factory
    IUniV2Factory public immutable UNIV2_FACTORY;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _WETH WETH address
        @param _uniV2Factory Uniswap V2 Factory address
    */
    constructor(
        address _WETH,
        IUniV2Factory _uniV2Factory
    ) {
        WETH = _WETH;
        UNIV2_FACTORY = _uniV2Factory;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        // Swap Functions
        if (sig == SWAP_EXACT_TOKENS_FOR_TOKENS || sig == SWAP_TOKENS_FOR_EXACT_TOKENS)
            return swapErc20ForErc20(data[4:]); // ERC20 -> ERC20
        if (sig == SWAP_EXACT_ETH_FOR_TOKENS || sig == SWAP_ETH_FOR_EXACT_TOKENS)
            return swapEthForErc20(data[4:]); // ETH -> ERC20
        if (sig == SWAP_TOKENS_FOR_EXACT_ETH || sig == SWAP_EXACT_TOKENS_FOR_ETH)
            return swapErc20ForEth(data[4:]); // ERC20 -> ETH

        // LP Functions
        if (sig == ADD_LIQUIDITY) return addLiquidity(data[4:]);
        if (sig == REMOVE_LIQUIDITY) return removeLiquidity(data[4:]);
        if (sig == ADD_LIQUIDITY_ETH) return addLiquidityEth(data[4:]);
        if (sig == REMOVE_LIQUIDITY_ETH) return removeLiquidityEth(data[4:]);

        return(false, new address[](0), new address[](0));
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Evaluates whether liquidity can be added
        @param data calldata for adding liquidity
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function addLiquidity(bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (address tokenA, address tokenB) = abi.decode(data, (address, address));

        address[] memory tokensOut = new address[](2);
        tokensOut[0] = tokenA;
        tokensOut[1] = tokenB;

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = UNIV2_FACTORY.getPair(tokenA, tokenB);

        return(true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether liquidity can be added
        @param data calldata for adding liquidity
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function addLiquidityEth(bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address token = abi.decode(data, (address));

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = token;

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = UNIV2_FACTORY.getPair(token, WETH);

        return(true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether liquidity can be removed
        @param data calldata for removing liquidity
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function removeLiquidity(bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (address tokenA, address tokenB) = abi.decode(data, (address, address));

        address[] memory tokensIn = new address[](2);
        tokensIn[0] = tokenA;
        tokensIn[1] = tokenB;

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = UNIV2_FACTORY.getPair(tokenA, tokenB);

        return(true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether liquidity can be removed
        @param data calldata for removing liquidity
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function removeLiquidityEth(bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (address token) = abi.decode(data, (address));

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = token;

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = UNIV2_FACTORY.getPair(token, WETH);

        return(true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether swap can be performed
        @param data calldata for swapping tokens
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function swapErc20ForErc20(bytes calldata data)
        internal
        pure
        returns (bool, address[] memory, address[] memory)
    {
        (,, address[] memory path,,)
                = abi.decode(data, (uint, uint, address[], address, uint));

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = path[0];

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = path[path.length - 1];

        return(
            true,
            tokensIn,
            tokensOut
        );
    }

    /**
        @notice Evaluates whether swap can be performed
        @param data calldata for swapping tokens
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function swapEthForErc20(bytes calldata data)
        internal
        pure
        returns (bool, address[] memory, address[] memory)
    {
        (, address[] memory path,,)
                = abi.decode(data, (uint, address[], address, uint));

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = path[path.length - 1];

        return (
            true,
            tokensIn,
            new address[](0)
        );
    }

    /**
        @notice Evaluates whether swap can be performed
        @param data calldata for swapping tokens
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function swapErc20ForEth(bytes calldata data)
        internal
        pure
        returns (bool, address[] memory, address[] memory)
    {
        (,, address[] memory path)
                = abi.decode(data, (uint, uint, address[]));

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = path[0];

        return (true, new address[](0), tokensOut);
    }
}