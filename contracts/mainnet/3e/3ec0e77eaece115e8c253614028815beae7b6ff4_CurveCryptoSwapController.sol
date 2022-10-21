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

import {IController} from "../core/IController.sol";
import {IStableSwapPool} from "./IStableSwapPool.sol";

/**
    @title Curve Crypto Swap Controller
    @notice Controller for curve crypto swap interaction
    arbi:0x960ea3e3C7FB317332d990873d354E18d7645590
*/
contract CurveCryptoSwapController is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice exchange(uint256,uint256,uint256,uint256,bool) function signature
    bytes4 public constant EXCHANGE = 0x394747c5;

    /// @notice add_liquidity(uint256[3],uint256) function signature
    bytes4 public constant ADD_LIQUIDITY = 0x4515cef3;

    /// @notice remove_liquidity(uint256,uint256[3]) function signature
    bytes4 public constant REMOVE_LIQUIDITY = 0xecb586a5;

    /// @notice remove_liquidity_one_coin(uint256,uint256,uint256) function signature
    bytes4 public constant REMOVE_LIQUIDITY_ONE_COIN = 0xf1dc3cc9;

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address target, bool useEth, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == ADD_LIQUIDITY) return canAddLiquidity(target, data);
        if (sig == REMOVE_LIQUIDITY_ONE_COIN)
            return canRemoveLiquidityOneCoin(target, data);
        if (sig == REMOVE_LIQUIDITY) return canRemoveLiquidity(target);
        if (sig == EXCHANGE) return canExchange(target, useEth, data);

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
        tokensIn[0] = IStableSwapPool(target).token();

        uint i; uint j;
        (uint[3] memory amounts) = abi.decode(data[4:], (uint[3]));
        address[] memory tokensOut = new address[](3);
        while(i < 3) {
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
        (,uint256 i, uint256 min_amount) = abi.decode(
            data[4:],
            (uint256, uint256, uint256)
        );

        if (min_amount == 0)
            return (false, new address[](0), new address[](0));

        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);

        tokensIn[0] = IStableSwapPool(target).coins(i);
        tokensOut[0] = IStableSwapPool(target).token();

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
        tokensOut[0] = IStableSwapPool(target).token();

        address[] memory tokensIn = new address[](3);
        tokensIn[0] = IStableSwapPool(target).coins(0);
        tokensIn[1] = IStableSwapPool(target).coins(1);
        tokensIn[2] = IStableSwapPool(target).coins(2);

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
    function canExchange(address target, bool useEth, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (uint256 i, uint256 j) = abi.decode(
            data[4:],
            (uint256, uint256)
        );

        address[] memory tokensIn = new address[](1);
        tokensIn[0] = IStableSwapPool(target).coins(j);

        if (useEth)
            return (
                true,
                tokensIn,
                new address[](0)
            );

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = IStableSwapPool(target).coins(i);

        return (
            true,
            tokensIn,
            tokensOut
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStableSwapPool {
    function coins(uint256 i) external view returns (address);
    function token() external view returns (address);
}