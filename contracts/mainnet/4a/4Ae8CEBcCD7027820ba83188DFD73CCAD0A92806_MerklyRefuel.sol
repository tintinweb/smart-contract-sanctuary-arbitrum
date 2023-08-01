// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NonblockingLzApp.sol";


contract MerklyRefuel is NonblockingLzApp {
    using BytesLib for bytes;

    uint public constant NO_EXTRA_GAS = 0;
 
    // packet type
    uint16 public constant PT_SEND = 0;

    bool public useCustomAdapterParams = true;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function estimateSendFee(uint16 _dstChainId, bytes memory payload, bytes memory _adapterParams) public view virtual returns (uint nativeFee, uint zroFee) {
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, _adapterParams);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        // empty
    }

    function bridgeGas(uint16 _dstChainId, bytes memory _toAddress, bytes memory _adapterParams) public payable virtual {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (uint nativeFee,) = estimateSendFee(_dstChainId, _toAddress, _adapterParams);
        require(msg.value >= nativeFee, "Not enough gas to send");
        
        _lzSend(_dstChainId, _toAddress, payable(0x0), address(0x0), _adapterParams, nativeFee);
    }

    function _checkAdapterParams(uint16 _dstChainId, uint16 _pkType, bytes memory _adapterParams, uint _extraGas) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}