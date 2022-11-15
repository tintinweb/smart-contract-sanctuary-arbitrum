// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IVault, IAsset} from "./IVault.sol";

/**
    @title Balancer V2 Controller
    @notice Balance v2 controller for join/exit/swap/batchSwap (multiHop)
*/
contract BalancerController is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice joinPool(bytes32,address,address,(address[],uint256[],bytes,bool))
    bytes4 constant JOIN = 0xb95cac28;

    /// @notice exitPool(bytes32,address,address,(address[],uint256[],bytes,bool))
    bytes4 constant EXIT = 0x8bdb3913;

    /// @notice swap((bytes32,uint8,address,address,uint256,bytes),(address,bool,address,bool),uint256,uint256)
    bytes4 constant SWAP = 0x52bbbe29;
    bytes4 constant BATCH_SWAP = 0x945bcec9;

    /* -------------------------------------------------------------------------- */
    /*                              EXTERNAL FUNCTIONS                            */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address target, bool useEth, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == JOIN)
            return canJoin(target, useEth, data[4:]);
        if (sig == EXIT)
            return canExit(target, useEth, data[4:]);
        if (sig == SWAP)
            return canSwap(target, useEth, data[4:]);
        if (sig == BATCH_SWAP)
            return canBatchSwap(target, useEth, data[4:]);
        return (false, new address[](0), new address[](0));
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function canJoin(address target, bool, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (
            bytes32 poolId,
            ,
            ,
            IVault.JoinPoolRequest memory request
        ) = abi.decode(data, (
                bytes32, address, address, IVault.JoinPoolRequest
            )
        );
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](request.assets.length);

        uint i; uint j;
        while(i < request.assets.length) {
            if (
                request.maxAmountsIn[i] > 0 &&
                address(request.assets[i]) != address(0)
            )
                tokensOut[j++] = address(request.assets[i]);
            unchecked { ++i; }
        }
        assembly { mstore(tokensOut, j) }

        (tokensIn[0],) = IVault(target).getPool(poolId);

        return (
            true,
            tokensIn,
            tokensOut
        );
    }

    function canExit(address target, bool, bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (
            bytes32 poolId,
            ,
            ,
            IVault.ExitPoolRequest memory request
        ) = abi.decode(data, (
                bytes32, address, address, IVault.ExitPoolRequest
            )
        );
        address[] memory tokensOut = new address[](1);
        address[] memory tokensIn = new address[](request.assets.length);

        uint i; uint j;
        while(i < request.assets.length) {
            if (address(request.assets[i]) != address(0))
                tokensIn[j++] = address(request.assets[i]);
            unchecked { ++i; }
        }
        assembly { mstore(tokensIn, j) }

        (tokensOut[0],) = IVault(target).getPool(poolId);

        return (
            true,
            tokensIn,
            tokensOut
        );
    }

    function canSwap(address, bool, bytes calldata data)
        internal
        pure
        returns (bool, address[] memory, address[] memory)
    {
        (
            IVault.SingleSwap memory swap,
            ,
            ,
        ) = abi.decode(data, (
                IVault.SingleSwap, IVault.FundManagement, uint256, uint256
            )
        );

        address[] memory tokensIn;
        address[] memory tokensOut;

        if (address(swap.assetIn) == address(0)) {
            tokensIn = new address[](1);
            tokensIn[0] = address(swap.assetOut);
            return (
                true,
                tokensIn,
                new address[](0)
            );
        }

        if (address(swap.assetOut) == address(0)) {
            tokensOut = new address[](1);
            tokensOut[0] = address(swap.assetIn);
            return (
                true,
                new address[](0),
                tokensOut
            );
        }

        tokensIn = new address[](1);
        tokensOut = new address[](1);
        tokensOut[0] = address(swap.assetIn);
        tokensIn[0] = address(swap.assetOut);

        return (
            true,
            tokensIn,
            tokensOut
        );
    }

    function canBatchSwap(address, bool, bytes calldata data)
        internal
        pure
        returns (bool, address[] memory, address[] memory)
    {
        (
            IVault.SwapKind kind,
            IVault.BatchSwapStep[] memory swaps,
            IAsset[] memory assets,
            ,
            ,
        ) = abi.decode(data, (
                IVault.SwapKind,
                IVault.BatchSwapStep[],
                IAsset[],
                IVault.FundManagement,
                uint256[],
                uint256
            )
        );

        uint tokenInIndex;
        uint tokenOutIndex;

        if (kind == IVault.SwapKind.GIVEN_IN) {
            if (!isMultiHopSwapGivenIn(swaps))
                return (false, new address[](0), new address[](0));
            tokenInIndex = swaps[swaps.length - 1].assetOutIndex;
            tokenOutIndex = swaps[0].assetInIndex;
        } else {
            if (!isMultiHopSwapGivenOut(swaps))
                return (false, new address[](0), new address[](0));
            tokenOutIndex = swaps[swaps.length - 1].assetInIndex;
            tokenInIndex = swaps[0].assetOutIndex;
        }

        address[] memory tokensIn;
        address[] memory tokensOut;

        if (address(assets[tokenOutIndex]) == address(0)) {
            tokensIn = new address[](1);
            tokensIn[0] = address(assets[tokenInIndex]);
            return (
                true,
                tokensIn,
                new address[](0)
            );
        }

        if (address(assets[tokenInIndex]) == address(0)) {
            tokensOut = new address[](1);
            tokensOut[0] = address(assets[tokenOutIndex]);
            return (
                true,
                new address[](0),
                tokensOut
            );
        }

        tokensIn = new address[](1);
        tokensOut = new address[](1);
        tokensOut[0] = address(assets[tokenOutIndex]);
        tokensIn[0] = address(assets[tokenInIndex]);

        return (
            true,
            tokensIn,
            tokensOut
        );
    }

    function isMultiHopSwapGivenIn(IVault.BatchSwapStep[] memory swaps)
        internal
        pure
        returns (bool)
    {
        uint steps = swaps.length;
        for (uint i; i < steps - 1; i++) {
            if (
                swaps[i].assetOutIndex != swaps[i+1].assetInIndex ||
                swaps[i+1].amount > 0
            )
                return false;
        }
        return true;
    }

    function isMultiHopSwapGivenOut(IVault.BatchSwapStep[] memory swaps)
        internal
        pure
        returns (bool)
    {
        uint steps = swaps.length;
        for (uint i; i < steps - 1; i++) {
            if (
                swaps[i].assetInIndex != swaps[i+1].assetOutIndex ||
                swaps[i+1].amount > 0
            )
                return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAsset {}

interface IVault {

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }
}

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