// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateEthVault.sol";

contract RouterETH {
    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    address public immutable stargateEthVault;
    IStargateRouter public immutable stargateRouter;
    uint16 public immutable poolId;

    constructor(address _stargateEthVault, address _stargateRouter, uint16 _poolId) {
        require(_stargateEthVault != address(0x0), "RouterETH: _stargateEthVault cant be 0x0");
        require(_stargateRouter != address(0x0), "RouterETH: _stargateRouter cant be 0x0");
        stargateEthVault = _stargateEthVault;
        stargateRouter = IStargateRouter(_stargateRouter);
        poolId = _poolId;
    }

    function addLiquidityETH() external payable {
        require(msg.value > 0, "Stargate: msg.value is 0");

        uint256 amountLD = msg.value;

        // wrap the ETH into WETH
        IStargateEthVault(stargateEthVault).deposit{value: amountLD}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), amountLD);

        // addLiquidity using the WETH that was just wrapped,
        // and mint the LP token to the msg.sender
        stargateRouter.addLiquidity(poolId, amountLD, msg.sender);
    }

    ///@notice compose stargate to swap ETH on the source to ETH on the destination and arbitrary call
    function swapETHAndCall(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        SwapAmount memory _swapAmount, // the amount and the minimum swap amount
        IStargateRouter.lzTxObj memory _lzTxParams, // the LZ tx params
        bytes calldata _payload // the payload to send to the destination
    ) external payable {
        require(msg.value > _swapAmount.amountLD, "Stargate: msg.value must be > _swapAmount.amountLD");

        IStargateEthVault(stargateEthVault).deposit{value: _swapAmount.amountLD}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), _swapAmount.amountLD);

        stargateRouter.swap{value: (msg.value - _swapAmount.amountLD)}(
            _dstChainId, // destination Stargate chainId
            poolId, // WETH Stargate poolId on source
            poolId, // WETH Stargate poolId on destination
            _refundAddress, // message refund address if overpaid
            _swapAmount.amountLD, // the amount in Local Decimals to swap()
            _swapAmount.minAmountLD, // the minimum amount swap()er would allow to get out (ie: slippage)
            _lzTxParams, // the LZ tx params
            _toAddress, // address on destination to send to
            _payload // payload to send to the destination
        );
    }

    // this contract needs to accept ETH
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

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

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IStargateEthVault {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function approve(address guy, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}