// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIceCreamNFT {
    function lickTime(uint256) external view returns (uint256);

    function lick(uint256 tokenId_) external;
}

contract IceCreamNFTResolver {
    IIceCreamNFT public immutable iceCreamNFT;

    constructor(IIceCreamNFT _iceCreamNft) {
        iceCreamNFT = _iceCreamNft;
    }

    function checker(uint256 _tokenId, uint256 _interval)
        external
        view
        returns (bool, bytes memory)
    {
        uint256 lickTime = iceCreamNFT.lickTime(_tokenId);

        if (block.timestamp >= lickTime + _interval) {
            bytes memory lickPayload = abi.encodeWithSelector(
                IIceCreamNFT.lick.selector,
                _tokenId
            );
            return (true, lickPayload);
        } else {
            return (false, bytes("Time not elapsed"));
        }
    }
}