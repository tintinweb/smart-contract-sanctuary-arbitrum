//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "./IERC20.sol";
import {ReentrancyGuardUpgradeable} from "./ReentrancyGuardUpgradeable.sol";
import {IOFT} from "./IOFT.sol";

import {LzAppSend} from "./LzAppSend.sol";
import {ILayerZeroEndpoint} from "./ILayerZeroEndpoint.sol";
import {ExcessivelySafeCall} from "./ExcessivelySafeCall.sol";
import {BytesLib} from "./BytesLib.sol";


contract MultichainDeposit is LzAppSend, ReentrancyGuardUpgradeable {
    using ExcessivelySafeCall for address;
    using BytesLib for bytes;

    // packet type
    uint16 public constant PT_SEND_AND_CALL = 1;
    uint16 public destChainId;

    IERC20 public constant AURA = IERC20(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address public multichainReceiver;

    bool public useCustomAdapterParams;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */
    function initialize(address _multichainReceiver, address _lzEndpoint, uint16 _destChainId) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        multichainReceiver = _multichainReceiver;
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        destChainId = _destChainId;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    PUBLIC                                  */
    /* -------------------------------------------------------------------------- */
    function estimateSendAndCallFee(address _from, uint256 _amount, bytes calldata _adapterParams)
        public
        view
        returns (uint256 nativeFee, uint256 zroFee)
    {
        // mock the payload for sendAndCall()
        bytes memory lzPayload = abi.encodePacked(_from, _amount);
        return lzEndpoint.estimateFees(destChainId, address(this), lzPayload, false, _adapterParams);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  EXTERNAL                                  */
    /* -------------------------------------------------------------------------- */
    function multiChainDeposits(
        address _receiver,
        uint256 _amount,
        bytes memory _auraAdapterParams,
        bytes memory _adapterParams
    ) external payable nonReentrant {
        address thisAddress = address(this);

        AURA.transferFrom(msg.sender, thisAddress, _amount);

        address zeroAddress = address(0);
        address aura = address(AURA);
        AURA.approve(aura, _amount);

        // Bridge Aura to mainnet
        IOFT(aura).sendFrom{value: msg.value}(
            thisAddress,
            destChainId,
            abi.encodePacked(multichainReceiver),
            _amount,
            payable(thisAddress),
            zeroAddress,
            _auraAdapterParams
        );

        // Send zero layer msg to mainnet receiver contract
        _sendAndCall(_receiver, destChainId, uint64(thisAddress.balance), zeroAddress, _adapterParams);
    }

    function lzReceive(uint16, bytes calldata, uint64, bytes calldata) external override {}

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                                    PRIVATE                                 */
    /* -------------------------------------------------------------------------- */

    function _sendAndCall(
        address _from,
        uint256 _amount,
        uint64 _dstGasForCall,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) private {
        _checkAdapterParams(destChainId, PT_SEND_AND_CALL, _adapterParams, _dstGasForCall);

        bytes memory lzPayload = abi.encodePacked(_from, _amount);
        _lzSend(
            destChainId,
            lzPayload,
            multichainReceiver,
            payable(_from),
            _zroPaymentAddress,
            _adapterParams,
            _dstGasForCall
        );

        emit CrossChainDeposit(destChainId, _from, _amount);
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint256 _extraGas)
        private
        view
    {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OWNER                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyOwner {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function setMultichainReceiver(address _multichainReceiver) external onlyOwner {
        multichainReceiver = _multichainReceiver;
    }

    function setDstChainId(uint16 _destChainId) external onlyOwner {
        destChainId = _destChainId;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event CrossChainDeposit(uint16 _dstChainId, address _from, uint256 _amount);
    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error FailSendETH();
}