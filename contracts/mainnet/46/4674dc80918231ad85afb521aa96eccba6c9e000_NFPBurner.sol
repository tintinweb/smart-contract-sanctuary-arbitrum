/**
 *Submitted for verification at Arbiscan.io on 2023-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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

    function getRewardForOwner(uint256 _tokenID, address[] calldata _tokens)
        external;
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

    ///@notice verify if the msg.sender is the owner of the NFP
    function _verifyOwnership(uint256 _tokenID) internal view returns (bool) {
        return nfpManager.ownerOf(_tokenID) == msg.sender;
    }

    ///@notice verify approval
    function _verifyApproval() internal view returns (bool) {
        return nfpManager.isApprovedForAll(msg.sender, address(this));
    }

    ///@notice verifies if there is any liquidity in the NFP
    function _verifyLiquidity(uint256 _tokenID) internal view returns (bool) {
        (, , , , , , , uint256 liquidityInNFP, , , , ) = nfpManager.positions(
            _tokenID
        );
        return liquidityInNFP == 0;
    }

    ///@notice Batch burn NFPs and claim any pending rewards
    ///@param _tokenIDs = the NFP IDs
    function batchBurnNFPs(uint256[] calldata _tokenIDs) external {
        require(_verifyApproval(), "!APPROVED");
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            uint256 tempID = _tokenIDs[i];
            require(
                _verifyOwnership(tempID) && _verifyLiquidity(tempID),
                "!VALID"
            );
            (
                ,
                ,
                address token0,
                address token1,
                uint24 fee,
                ,
                ,
                ,
                ,
                ,
                ,

            ) = nfpManager.positions(tempID);
            if (
                voter.gauges(factory.getPool(token0, token1, fee)) != address(0)
            ) {
                IClGauge _gauge = IClGauge(
                    voter.gauges(factory.getPool(token0, token1, fee))
                );
                address[] memory rewardTokens = _gauge.getRewardTokens();
                _gauge.getRewardForOwner(tempID, rewardTokens);

                nfpManager.burn(tempID);
            } else {
                nfpManager.burn(tempID);
            }
        }
    }
}