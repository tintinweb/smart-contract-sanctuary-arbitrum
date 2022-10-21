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

interface IStableSwapPool {
    function coins(uint256 i) external view returns (address);
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IStableSwapPool} from "./IStableSwapPool.sol";

/**
    @title Curve stable Swap Controller
    @notice Controller for curve stable swap 2 pool interaction
    arbi:0x7f90122BF0700F9E7e1F688fe926940E8839F353
*/
contract StableSwap2PoolController is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice exchange(int128,int128,uint256,uint256)	function signature
    bytes4 public constant EXCHANGE = 0x3df02124;

    /// @notice add_liquidity(uint256[2],uint256) function signature
    bytes4 public constant ADD_LIQUIDITY = 0x0b4c7e4d;

    /// @notice remove_liquidity(uint256,uint256[2]) function signature
    bytes4 public constant REMOVE_LIQUIDITY = 0x5b36389c;

    /// @notice remove_liquidity_one_coin(uint256,int128,uint256) function signature
    bytes4 public constant REMOVE_LIQUIDITY_ONE_COIN = 0x1a4d01d2;

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address target, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == ADD_LIQUIDITY) return canAddLiquidity(target, data);
        if (sig == REMOVE_LIQUIDITY_ONE_COIN)
            return canRemoveLiquidityOneCoin(target, data);
        if (sig == REMOVE_LIQUIDITY) return canRemoveLiquidity(target);
        if (sig == EXCHANGE) return canExchange(target, data);

        return (false, new address[](0), new address[](0));
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Evaluates whether protocol can add liquidity to the target contract
        @param target External protocol address
        @param data calldata of the interaction with the target address
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canAddLiquidity(address target, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address[] memory tokensIn = new address[](1);
        tokensIn[0] = target;

        uint i; uint j;
        (uint[2] memory amounts) = abi.decode(data[4:], (uint[2]));
        address[] memory tokensOut = new address[](2);
        while(i < 2) {
            if(amounts[i] > 0)
                tokensOut[j++] = IStableSwapPool(target).coins(i);
            unchecked { ++i; }
        }
        assembly { mstore(tokensOut, j) }

        return (true, tokensIn, tokensOut);
    }


    /**
        @notice Evaluates whether protocol can remove liquidity from the target contract
        @param target External protocol address
        @param data calldata of the interaction with the target address
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canRemoveLiquidityOneCoin(address target, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (,int128 i, uint256 min_amount) = abi.decode(
            data[4:],
            (uint256, int128, uint256)
        );

        if (min_amount == 0)
            return (false, new address[](0), new address[](0));

        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        tokensIn[0] = IStableSwapPool(target).coins(uint128(i));
        tokensOut[0] = target;

        return (true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether protocol can remove liquidity from the target contract
        @param target External protocol address
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canRemoveLiquidity(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address[] memory tokensOut = new address[](1);
        tokensOut[0] = target;

        address[] memory tokensIn = new address[](2);
        tokensIn[0] = IStableSwapPool(target).coins(0);
        tokensIn[1] = IStableSwapPool(target).coins(1);

        return (true, tokensIn, tokensOut);
    }

    /**
        @notice Evaluates whether protocol can perform a swap using the target contract
        @param target External protocol address
        @param data calldata of the interaction with the target address
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canExchange(address target, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (int128 i, int128 j,,) = abi.decode(
            data[4:],
            (int128, int128, uint256, uint256)
        );

        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);
        tokensIn[0] = IStableSwapPool(target).coins(uint128(j));
        tokensOut[0] = IStableSwapPool(target).coins(uint128(i));

        return (
            true,
            tokensIn,
            tokensOut
        );
    }
}