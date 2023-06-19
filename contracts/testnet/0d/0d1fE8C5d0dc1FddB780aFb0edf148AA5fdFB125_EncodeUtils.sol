/**
 *Submitted for verification at Arbiscan on 2023-06-19
*/

pragma solidity ^0.8.0;

contract EncodeUtils {
    constructor(){
    }

    bytes32 internal constant CROSS_CALL_EVENT_SIGNATURE =
        keccak256("CrossCall(bytes32,uint256,address,uint256,address,bytes)");

    function encode(
        uint256 _blockchainId,
        address _cbcAddress,
        bytes calldata _eventData
    ) external pure returns (bytes32) {
        return getMessageHash(abi.encodePacked(
            _blockchainId,
            _cbcAddress,
            CROSS_CALL_EVENT_SIGNATURE,
            _eventData
        ));
    }

    function getMessageHash(
        bytes memory _signedEventInfo
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_signedEventInfo));
    }
}