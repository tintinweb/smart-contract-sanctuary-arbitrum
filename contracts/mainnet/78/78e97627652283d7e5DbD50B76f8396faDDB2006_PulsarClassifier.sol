// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface ChainlinkPriceFeed {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);
}

contract PulsarClassifier {
    ChainlinkPriceFeed internal nativeTokenPriceOracle;

    uint256 private povertyThresholdUsd = 1000;
    uint256 private decimalPlaceFactor = 10 ** 2; // Precision: 0.01%

    mapping(address => bool) private isConservative;
    mapping(uint8 => uint8) private badgerTypeIndexesPercentages;

    constructor(
        address[] memory conservativeTokenAddresses,
        address _nativeTokenPriceOracle
    ) {
        nativeTokenPriceOracle = ChainlinkPriceFeed(_nativeTokenPriceOracle);
        for (uint256 i = 0; i < conservativeTokenAddresses.length; i++) {
            isConservative[conservativeTokenAddresses[i]] = true;
        }
        badgerTypeIndexesPercentages[1] = 50;
        badgerTypeIndexesPercentages[2] = 50;
        badgerTypeIndexesPercentages[3] = 50;
        badgerTypeIndexesPercentages[4] = 90;
    }

    function classifyWallet(
        address wallet,
        address[] memory _tokens,
        uint256[] memory _tokenBalances,
        uint256[] memory _tokenPrices,
        uint8[] memory _tokenDecimals,
        uint8[] memory _priceDecimals,
        uint256[] memory _defiContractUSDBalances,
        uint256[] memory _nftUSDBalances
    ) external view returns (uint8) {
        uint256 _totalUsdTokenBalance = _getTotalUsdTokenBalance(
            wallet,
            _tokenBalances,
            _tokenPrices,
            _tokenDecimals,
            _priceDecimals
        );
        uint256 _totalUsdDefiBalance = _sumUsdBalances(
            _defiContractUSDBalances
        );
        uint256 _totalUsdConservativeTokenBalance = _getTotalUsdConservativeTokenBalance(
                wallet,
                _tokens,
                _tokenBalances,
                _tokenPrices,
                _tokenDecimals,
                _priceDecimals
            );
        uint256 _totalUsdNftBalance = _sumUsdBalances(_nftUSDBalances);
        uint256 _totalUsdGlobalBalance = _totalUsdTokenBalance +
            _totalUsdDefiBalance +
            _totalUsdNftBalance;
        return
            this.classifyBalances(
                _totalUsdGlobalBalance,
                _totalUsdTokenBalance,
                _totalUsdConservativeTokenBalance,
                _totalUsdDefiBalance,
                _totalUsdNftBalance
            );
    }

    function _getTotalUsdTokenBalance(
        address wallet,
        uint256[] memory _tokenBalances,
        uint256[] memory _tokenPrices,
        uint8[] memory _tokenDecimals,
        uint8[] memory _priceDecimals
    ) internal view returns (uint256) {
        uint256 totalUsdTokenBalance = 0;
        for (uint256 i = 0; i < _tokenBalances.length; i++) {
            totalUsdTokenBalance =
                totalUsdTokenBalance +
                ((_tokenBalances[i] * _tokenPrices[i]) /
                    (10 ** (_tokenDecimals[i] + _priceDecimals[i])));
        }
        uint256 nativeUsdBalance = this.getNativeUsdBalance(wallet);
        totalUsdTokenBalance = totalUsdTokenBalance + nativeUsdBalance;
        return totalUsdTokenBalance;
    }

    function _sumUsdBalances(
        uint256[] memory _usdTokenBalances
    ) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _usdTokenBalances.length; i++) {
            sum = sum + _usdTokenBalances[i];
        }
        return sum;
    }

    function getNativeUsdBalance(
        address wallet
    ) external view returns (uint256) {
        uint256 nativeTokenPrice = uint256(
            nativeTokenPriceOracle.latestAnswer()
        );
        uint8 priceDecimals = nativeTokenPriceOracle.decimals();
        return (wallet.balance * nativeTokenPrice) / 10 ** (18 + priceDecimals);
    }

    // enum BadgeType {
    //     0-POOR,
    //     1-LOW_CAP_DEGEN,
    //     2-NFT_DEGEN,
    //     3-DEFI_DEGEN,
    //     4-CONSERVATIVE
    //     5-BOLD,
    // }
    function classifyBalances(
        uint256 _totalUsdGlobalBalance,
        uint256 _totalUsdTokenBalance,
        uint256 _totalUsdConservativeTokenBalance,
        uint256 _totalUsdDefiBalance,
        uint256 _totalUsdNftBalance
    ) external view returns (uint8) {
        if (_totalUsdGlobalBalance < povertyThresholdUsd) {
            return 0;
        }
        uint256 _conservativeTokenShare = (_totalUsdConservativeTokenBalance *
            decimalPlaceFactor) / _totalUsdGlobalBalance;
        if (_conservativeTokenShare >= badgerTypeIndexesPercentages[4]) {
            return 4;
        }
        uint256 _defiShare = (_totalUsdDefiBalance * decimalPlaceFactor) /
            _totalUsdGlobalBalance;
        if (_defiShare >= badgerTypeIndexesPercentages[3]) {
            return 3;
        }
        uint256 _nftShare = (_totalUsdNftBalance * decimalPlaceFactor) /
            _totalUsdGlobalBalance;
        if (_nftShare >= badgerTypeIndexesPercentages[2]) {
            return 2;
        }
        uint256 _otherTokenShare = (
            ((_totalUsdTokenBalance - _totalUsdConservativeTokenBalance) *
                decimalPlaceFactor)
        ) / _totalUsdGlobalBalance;
        if (_otherTokenShare >= badgerTypeIndexesPercentages[1]) {
            return 1;
        }
        return 5;
    }

    function _getTotalUsdConservativeTokenBalance(
        address wallet,
        address[] memory _tokens,
        uint256[] memory _tokenBalances,
        uint256[] memory _tokenPrices,
        uint8[] memory _tokenDecimals,
        uint8[] memory _priceDecimals
    ) internal view returns (uint256) {
        uint256 usdConservativeTokensBalance = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (isConservative[_tokens[i]]) {
                usdConservativeTokensBalance =
                    usdConservativeTokensBalance +
                    ((_tokenBalances[i] * _tokenPrices[i]) /
                        (10 ** (_tokenDecimals[i] + _priceDecimals[i])));
            }
        }
        uint256 NativeUsdBalance = this.getNativeUsdBalance(wallet);
        usdConservativeTokensBalance =
            usdConservativeTokensBalance +
            NativeUsdBalance;
        return usdConservativeTokensBalance;
    }
}