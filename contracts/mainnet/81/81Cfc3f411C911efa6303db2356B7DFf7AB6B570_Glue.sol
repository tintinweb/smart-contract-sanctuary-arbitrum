// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";
import "./TransferHelper.sol";
import "./BridgeBase.sol";
import "./SwapBase.sol";
	
contract Glue is Ownable, ReentrancyGuard {
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(string => uint256) public fee;
    address public feeAddress;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Glue: EXPIRED");
        _;
    }

    struct SwapBridgeDex {
        address dex;
        bool isEnabled;
    }

    SwapBridgeDex[] public swapDexs;
    SwapBridgeDex[] public bridgeDexs;

    constructor() {}

    receive() external payable {}

    event NewSwapDexAdded(address dex, bool isEnabled);
    event NewBridgeDexAdded(address dex, bool isEnabled);
    event SwapDexDisabled(uint256 dexID);
    event BridgeDexDisabled(uint256 dexID);
    event SetFee(string channel, uint256 fee);
    event SetFeeAddress(address feeAddress);
    event WithdrawETH(uint256 amount);
    event Withdraw(address token, uint256 amount);

    struct SwapBridgeRequest {
        uint256 id;
        uint256 nativeAmount;
        address inputToken;
        bytes data;
    }

    // **** USER REQUEST ****
    struct UserSwapRequest {
        address receiverAddress;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        string channel;
        uint256 deadline;
    }

    struct UserBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest bridgeRequest;
        string channel;
        uint256 deadline;
    }

    struct UserSwapBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        SwapBridgeRequest bridgeRequest;
        string channel;
        uint256 deadline;
    }

    // **** SWAP ****
    function swap(UserSwapRequest calldata _userRequest)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );
        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        require(
            msg.value == nativeSwapAmount,
            Errors.VALUE_NOT_EQUAL_TO_AMOUNT
        );

        // fee
        uint256 _channelFee;
        if (feeAddress != address(0)) {
            _channelFee = fee[_userRequest.channel] == 0
                ? 3000
                : fee[_userRequest.channel];
        }

        // swap
        SwapBase(swapInfo.dex).swap{value: nativeSwapAmount}(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.swapRequest.data,
            _channelFee,
            feeAddress
        );
    }

    // **** BRIDGE ****
    function bridge(UserBridgeRequest calldata _userRequest)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];

        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        // fee
        uint256 _channelFee;
        if (feeAddress != address(0)) {
            _channelFee = fee[_userRequest.channel] == 0
                ? 3000
                : fee[_userRequest.channel];
        }

        // bridge
        BridgeBase(bridgeInfo.dex).bridge{value: msg.value}(
            msg.sender,
            _userRequest.bridgeRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            _channelFee,
            feeAddress
        );
    }

    // **** SWAP AND BRIDGE ****
    function swapAndBridge(UserSwapBridgeRequest calldata _userRequest)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);

        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];
        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        uint256 _amountOut = SwapBase(swapInfo.dex).swap{
            value: nativeSwapAmount
        }(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            address(this),
            _userRequest.swapRequest.data,
            0,
            feeAddress
        );

        uint256 nativeInput = _userRequest.bridgeRequest.nativeAmount;

        if (_userRequest.bridgeRequest.inputToken != NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeApprove(
                _userRequest.bridgeRequest.inputToken,
                bridgeInfo.dex,
                _amountOut
            );
        } else {
            nativeInput = _amountOut + _userRequest.bridgeRequest.nativeAmount;
        }

        // fee
        uint256 _channelFee;
        if (feeAddress != address(0)) {
            _channelFee = fee[_userRequest.channel] == 0
                ? 3000
                : fee[_userRequest.channel];
        }

        BridgeBase(bridgeInfo.dex).bridge{value: nativeInput}(
            address(this),
            _userRequest.bridgeRequest.inputToken,
            _amountOut,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            _channelFee,
            feeAddress
        );
    }

    // **** ONLY OWNER ****
    function addSwapDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        swapDexs.push(_dex);
        emit NewSwapDexAdded(_dex.dex, _dex.isEnabled);
    }

    function addBridgeDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        bridgeDexs.push(_dex);
        emit NewBridgeDexAdded(_dex.dex, _dex.isEnabled);
    }

    function disableSwapDex(uint256 _dexId) external onlyOwner {
        swapDexs[_dexId].isEnabled = false;
        emit SwapDexDisabled(_dexId);
    }

    function disableBridgeDex(uint256 _dexId) external onlyOwner {
        bridgeDexs[_dexId].isEnabled = false;
        emit BridgeDexDisabled(_dexId);
    }

    function setFee(string memory _channel, uint256 _fee) external onlyOwner {
        fee[_channel] = _fee;
        emit SetFee(_channel, _fee);
    }

    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
        emit SetFeeAddress(_newFeeAddress);
    }

    function withdraw(
        address _token,
        address _receiverAddress,
        uint256 _amount
    ) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount)
        external
        onlyOwner
    {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }
}