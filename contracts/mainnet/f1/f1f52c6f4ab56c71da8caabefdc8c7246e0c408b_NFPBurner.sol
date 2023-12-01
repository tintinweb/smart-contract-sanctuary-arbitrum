/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@notice helper contract to batch-burn excess NFPs

interface INFP {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96,
            address,
            address,
            address,
            uint24,
            int24,
            int24,
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        );

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function ownerOf(uint256 _tokenID) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;

    function burn(uint256 tokenID) external payable;
}

contract NFPBurner {
    INFP public nfpManager;

    constructor(address _nfpManager) {
        nfpManager = INFP(_nfpManager);
    }

    ///@dev internal function to verify the owner of an NFP is the msg.sender
    function _verifyOwnership(uint256 _tokenID) internal view returns (bool) {
        if (nfpManager.ownerOf(_tokenID) == msg.sender) return true;
        return false;
    }

    ///@dev internal function to verify if the msg.sender has all NFPs approved to this contract
    function _verifyApproval() internal view returns (bool) {
        if (!(nfpManager.isApprovedForAll(msg.sender, address(this))))
            return false;
        return true;
    }

    ///@dev internal function to verify the liquidity in a NFP = 0
    function _verifyLiquidity(uint256 _tokenID) internal view returns (bool) {
        (, , , , , , , uint256 liquidityInNFP, , , , ) = nfpManager.positions(
            _tokenID
        );
        if (!(liquidityInNFP == 0)) return false;
        return true;
    }

    ///@dev call boolean checks for verification and loop through burning all eligible NFPs
    function batchBurnNFPs(uint256[] calldata _tokenIDs) external {
        require(_verifyApproval(), "!APPROVED");
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            require(
                _verifyOwnership(_tokenIDs[i]) &&
                    _verifyLiquidity(_tokenIDs[i]),
                "!VALID"
            );
            nfpManager.burn(_tokenIDs[i]);
        }
    }
}