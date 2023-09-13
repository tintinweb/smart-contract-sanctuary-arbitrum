/**
 *Submitted for verification at Arbiscan.io on 2023-09-08
*/

// SPDX-License-Identifier: BUSL-1.1 AND MIT
pragma solidity ^0.8.0;

// FORKED FROM https://github.com/stargate-protocol/stargate/blob/main/contracts/interfaces/IStargateRouter.sol

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}


contract SgHelper {
    /// Call reverted (0x44666d3c)
    error Revert(bytes _data);
    /// Insufficient balance for call (0xcf479181)
    error InsufficientBalance(uint256 _balance, uint256 _value);
    /// Negative balance change after swap (0x2d1a1e67)
    error NegativeOutput(uint256 _preBalance, uint256 _postBalance);

    struct SgSwapParams {
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address payable refundAddress;
        uint256 minAmountLD;
        IStargateRouter.lzTxObj lzTxParams;
        bytes to;
        bytes payload;
    }

    /// Calls _callee with given _data (swaps tokens),
    /// gets token balance and passes it to StargateRouter.swap
    /// @notice MUST be called via delegatecall (because of approve)
    /// @notice MUST be paybale because quite always called from payable function
    function swap(
        address _callee,
        bytes calldata _data,
        IERC20 _token,
        IStargateRouter _router,
        uint256 _layerZeroFee,
        SgSwapParams calldata _p
    ) external payable {
        uint256 amountLD;
        {
            uint256 balance = address(this).balance;
            if (balance < _layerZeroFee) {
                revert InsufficientBalance(balance, _layerZeroFee);
            }
            balance = _token.balanceOf(address(this));
            (bool success, bytes memory data) = _callee.call(_data);
            if (!success) {
                revert Revert(data);
            }
            uint256 postBalance = _token.balanceOf(address(this));
            if (postBalance < balance) {
                revert NegativeOutput(balance, postBalance);
            }
            unchecked {
                amountLD = postBalance - balance;
            }
        }
        _router.swap{value: _layerZeroFee}(
            _p.dstChainId,
            _p.srcPoolId,
            _p.dstPoolId,
            _p.refundAddress,
            amountLD,
            _p.minAmountLD,
            _p.lzTxParams,
            _p.to,
            _p.payload
        );
    }
}