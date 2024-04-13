// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

struct GlobalPoolEntry {
    uint256 totalPool;
    uint256 utilization;
    uint256 totalBareToken;
    uint256 poolFee;
}

struct LendingPoolEntry {
    uint256 pseudoTotalPool;
    uint256 totalDepositShares;
    uint256 collateralFactor;
}

struct BorrowRatesEntry {
    uint256 pole;
    uint256 deltaPole;
    uint256 minPole;
    uint256 maxPole;
    uint256 multiplicativeFactor;
}

struct BorrowPoolEntry {
    bool allowBorrow;
    uint256 pseudoTotalBorrowAmount;
    uint256 totalBorrowShares;
    uint256 borrowRate;
}

interface IAaveHub {

    function aaveTokenAddress(
        address _underlyingToken
    )
        external
        view
        returns (address);

    function getLendingRate(
        address _underlyingAsset
    )
        external
        view
        returns (uint256);

    function getAavePoolAPY(
        address _underlyingAsset
    )
        external
        view
        returns (uint256);
}

interface IWiseSecurity {

    function checkMinDepositValue(
        address _poolToken,
        uint256 _amount
    )
        external
        view
        returns (bool);

    function getETHBorrow(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getETHCollateral(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256);
}

interface IWiseLending {

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        external
        view
        returns (address);

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function globalPoolData(
        address _poolToken
    )
        external
        view
        returns (GlobalPoolEntry memory);

    function lendingPoolData(
        address _poolToken
    )
        external
        view
        returns (LendingPoolEntry memory);

    function borrowRatesData(
        address _poolToken
    )
        external
        view
        returns (BorrowRatesEntry memory);

    function borrowPoolData(
        address _poolToken
    )
        external
        view
        returns (BorrowPoolEntry memory);
}

contract APYViewer {

    IAaveHub public AAVE_HUB;
    IWiseSecurity public WISE_SECURITY;
    IWiseLending public WISE_LENDING;

    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;
    address internal constant ZERO_ADDRESS = address(0x0);

    struct ApyData {
        uint256 netAPY;
        uint256 ethValue;
        uint256 ethValueDebt;
        uint256 ethValueGain;
        uint256 totalEthSupply;
        uint256 totalEthBorrow;
    }

    constructor(
        address _aaveHub,
        address _wiseLending,
        address _wiseSecurity
    )
    {
        AAVE_HUB = IAaveHub(
            _aaveHub
        );

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurity
        );

        WISE_LENDING = IWiseLending(
            _wiseLending
        );
    }

    function overallNetAPYs(
        uint256 _nftId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        uint256 i;
        address token;

        ApyData memory data;

        uint256 lenBorrow = WISE_LENDING.getPositionBorrowTokenLength(
            _nftId
        );

        uint256 lenDeposit = WISE_LENDING.getPositionLendingTokenLength(
            _nftId
        );

        for (i; i < lenBorrow;) {

            token = WISE_LENDING.getPositionBorrowTokenByIndex(
                _nftId,
                i
            );

            data.ethValue = WISE_SECURITY.getETHBorrow(
                _nftId,
                token
            );

            data.totalEthBorrow += data.ethValue;

            data.ethValueDebt += WISE_SECURITY.getBorrowRate(
                token
            ) * data.ethValue;

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < lenDeposit;) {

            token = WISE_LENDING.getPositionLendingTokenByIndex(
                _nftId,
                i
            );

            data.ethValue = WISE_SECURITY.getETHCollateral(
                _nftId,
                token
            );

            address aaveToken = AAVE_HUB.aaveTokenAddress(
                token
            );

            uint256 lendingRate = aaveToken == ZERO_ADDRESS
                ? WISE_SECURITY.getLendingRate(token)
                : getLendingRateAave(token);

            data.totalEthSupply += data.ethValue;

            data.ethValueGain += data.ethValue
                * lendingRate;

            unchecked {
                ++i;
            }
        }

        uint256 netBorrowAPY = data.totalEthBorrow != 0
            ? data.ethValueDebt / data.totalEthBorrow
            : 0;

        uint256 netSupplyAPY = data.totalEthSupply != 0
            ? data.ethValueGain / data.totalEthSupply
            : 0;

        if (data.ethValueDebt > data.ethValueGain) {

            data.netAPY = (data.ethValueDebt - data.ethValueGain)
                / data.totalEthSupply;

            return (
                netBorrowAPY,
                netSupplyAPY,
                data.netAPY,
                true
            );
        }

        data.netAPY = (data.ethValueGain - data.ethValueDebt)
            / data.totalEthSupply;

        return (
            netBorrowAPY,
            netSupplyAPY,
            data.netAPY,
            false
        );
    }

    function getBorrowRate(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_SECURITY.getBorrowRate(
            _poolToken
        );
    }

    function getLendingRate(
        address _poolToken
    )
        external
        view
        returns (uint256)
    {
        return WISE_SECURITY.getLendingRate(
            _poolToken
        );
    }

    function getLendingRateAave(
        address _underlyingAsset
    )
        public
        view
        returns (uint256)
    {
        address aToken = AAVE_HUB.aaveTokenAddress(
            _underlyingAsset
        );

        uint256 lendingRate = WISE_SECURITY.getLendingRate(
            aToken
        );

        uint256 aaveRate = AAVE_HUB.getAavePoolAPY(
            _underlyingAsset
        );

        uint256 utilization = WISE_LENDING.globalPoolData(
            aToken
        ).utilization;

        return (aaveRate * (PRECISION_FACTOR_E18 - utilization)
            + lendingRate * utilization)
            / PRECISION_FACTOR_E18;
    }

    function getPredictedBorrowRate(
        address _poolToken,
        uint256 _borrowAmount
    )
        external
        view
        returns (uint256)
    {
        uint256 decrease = WISE_LENDING.globalPoolData(_poolToken).totalPool
            - _borrowAmount;

        uint256 utilization = PRECISION_FACTOR_E18 - (
            PRECISION_FACTOR_E18
            * decrease
            / WISE_LENDING.lendingPoolData(_poolToken).pseudoTotalPool
        );

        uint256 pole = WISE_LENDING.borrowRatesData(_poolToken).pole;

        uint256 baseDivider = pole
            * (pole - utilization);

        return WISE_LENDING.borrowRatesData(_poolToken).multiplicativeFactor
            * PRECISION_FACTOR_E18
            * utilization
            / baseDivider;
    }

    function getPredictLendingRate(
        address _poolToken,
        uint256 _supplyAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 totalPoolAmount = WISE_LENDING.globalPoolData(_poolToken).totalPool;
        uint256 pseudoPoolAmount = WISE_LENDING.lendingPoolData(_poolToken).pseudoTotalPool;

        uint256 utilization = PRECISION_FACTOR_E18 - (totalPoolAmount + _supplyAmount)
            * PRECISION_FACTOR_E18
            / (pseudoPoolAmount + _supplyAmount);

        uint256 pole = WISE_LENDING.borrowRatesData(_poolToken).pole;

        uint256 baseDivider = pole
            * (pole - utilization);

        uint256 borroRate = WISE_LENDING.borrowRatesData(_poolToken).multiplicativeFactor
            * PRECISION_FACTOR_E18
            * utilization
            / baseDivider;

        uint256 lendingRate = borroRate
            * (PRECISION_FACTOR_E18 - WISE_LENDING.globalPoolData(_poolToken).poolFee)
            / PRECISION_FACTOR_E18;

        return lendingRate
            * WISE_LENDING.borrowPoolData(_poolToken).pseudoTotalBorrowAmount
            / (pseudoPoolAmount + _supplyAmount);
    }

    function getPredictAaveLendingRate(
        address _poolToken,
        uint256 _supplyAmount
    )
        external
        view
        returns (uint256)
    {
        uint256 totalPoolAmount = WISE_LENDING.globalPoolData(_poolToken).totalPool;
        uint256 pseudoPoolAmount = WISE_LENDING.lendingPoolData(_poolToken).pseudoTotalPool;

        uint256 utilization = PRECISION_FACTOR_E18 - (totalPoolAmount + _supplyAmount)
            * PRECISION_FACTOR_E18
            / (pseudoPoolAmount + _supplyAmount);

        return (getLendingRateAave(_poolToken) * (PRECISION_FACTOR_E18 - utilization)
            + getPredictLendingRate(_poolToken, _supplyAmount ) * utilization)
            / PRECISION_FACTOR_E18;
    }
}