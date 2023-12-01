/**
 *Submitted for verification at Arbiscan.io on 2023-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IVoter {
    function claimClGaugeRewards(
        address[] memory _gauges,
        address[][] memory _tokens,
        uint256[][] memory _nfpTokenIds
    ) external;

    function gauges(address _pool) external view returns (address);
}

interface IClFactory {
    function getPool(
        address,
        address,
        uint24
    ) external view returns (address);
}

interface IClGauge {
    function earned(address token, uint256 tokenID)
        external
        view
        returns (uint256);

    function getRewardTokens()
        external
        view
        returns (address[] calldata _tokens);
}

contract NFPBurner {
    INFP public nfpManager;
    IVoter public voter;
    IClFactory public factory;

    constructor(
        address _nfpManager,
        address _voter,
        address _factory
    ) {
        nfpManager = INFP(_nfpManager);
        voter = IVoter(_voter);
        factory = IClFactory(_factory);
    }

    function _verifyOwnership(uint256 _tokenID) internal view returns (bool) {
        return nfpManager.ownerOf(_tokenID) == msg.sender;
    }

    function _verifyApproval() internal view returns (bool) {
        return nfpManager.isApprovedForAll(msg.sender, address(this));
    }

    function _verifyLiquidity(uint256 _tokenID) internal view returns (bool) {
        (, , , , , , , uint256 liquidityInNFP, , , , ) = nfpManager.positions(_tokenID);
        return liquidityInNFP == 0;
    }

    function batchBurnNFPs(uint256[] calldata _tokenIDs) external {
        require(_verifyApproval(), "!APPROVED");
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            uint256 tempID = _tokenIDs[i];
            require(_verifyOwnership(tempID) && _verifyLiquidity(tempID), "!VALID");
            (, , address token0, address token1, uint24 fee, , , , , , , ) = nfpManager.positions(tempID);
            if (voter.gauges(factory.getPool(token0, token1, fee)) != address(0)) {
                IClGauge _gauge = IClGauge(voter.gauges(factory.getPool(token0, token1, fee)));
                address[] memory rewardTokens = _gauge.getRewardTokens();

                address[][] memory rewardTokensArray = new address[][](1);
                rewardTokensArray[0] = rewardTokens;

                uint256[][] memory tokenIDsArray = new uint256[][](1);
                tokenIDsArray[0] = new uint256[](1);
                tokenIDsArray[0][0] = tempID;

                address[] memory gaugesArray = new address[](1);
                gaugesArray[0] = address(_gauge);

                voter.claimClGaugeRewards(gaugesArray, rewardTokensArray, tokenIDsArray);
                nfpManager.burn(tempID);
            }
            else {
                nfpManager.burn(tempID);
            }
        }
    }
}