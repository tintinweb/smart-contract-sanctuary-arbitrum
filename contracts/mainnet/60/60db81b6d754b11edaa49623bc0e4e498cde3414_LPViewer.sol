// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

interface WiseLending {

    function cashoutAmount(
        address _pendleChild,
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function getPositionLendingShares(
        uint256 _nftId,
        address _pendleChild
    )
        external
        view
        returns (uint256);
}

interface PendleChild {

    function previewAmountWithdrawShares(
        uint256 _shares,
        uint256 _underlyingLpAssetsCurrent
    )
        external
        view
        returns (uint256);

    function underlyingLpAssetsCurrent()
        external
        view
        returns (uint256);
}

interface PendlePowerFarm {

    function farmingKeys(
        uint256 _keyId
    )
        external
        view
        returns (uint256);

    function PENDLE_CHILD()
        external
        view
        returns (address);
}

contract LPViewer {

    WiseLending public immutable WISE_LENDNG;

    constructor(
        address _wiseLending
    ) {
        WISE_LENDNG = WiseLending(
            _wiseLending
        );
    }

    function getAmountLP(
        uint256 _keyId,
        PendlePowerFarm _powerFarm
    )
        external
        view
        returns (uint256)
    {
        PendleChild pendleChild = PendleChild(
            _powerFarm.PENDLE_CHILD()
        );

        uint256 wiseLendingNFT = _powerFarm.farmingKeys(
            _keyId
        );

        return pendleChild.previewAmountWithdrawShares(
            WISE_LENDNG.cashoutAmount(
                address(pendleChild),
                WISE_LENDNG.getPositionLendingShares(
                    wiseLendingNFT,
                    address(pendleChild)
                )
            ),
            pendleChild.underlyingLpAssetsCurrent()
        );
    }
}