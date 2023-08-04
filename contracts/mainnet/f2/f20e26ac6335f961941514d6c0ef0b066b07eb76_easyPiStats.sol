//SPDX-License-Identifier: -- EASY-PI --

pragma solidity =0.8.18;

    interface IERC20 {
        function balanceOf(
            address _user
        )
            external
            view
            returns (uint256);

        function totalSupply()
            external
            view
            returns (uint256);
    }

   interface IGmxHelper{

        function liveAaveCollateralAmountUSD(
            address _poolAddress
        )
            external
            view
            returns (uint256);

        function liveTotalBorrowAmountUSD(
            address _poolAddress
        )
            external
            view
            returns (uint256);
    }

    interface IOracleHub{

        function getTokenAmountFromUSD(
            uint256 _amount,
            address _token
        )
            external
            view
            returns (uint256);
    }

    interface ISwapHub{

    function getGlpBalance(
        address _poolAddress
    )
        external
        view
        returns (uint256);
    }

    interface IGlpmanager {
        function getPrice(
            bool _maximize
        )
            external
            view
            returns (uint256);
    }

    interface IEasyPiStats {

        function getTvlByVaultUSD()
            external
            view
            returns (uint256);

        function getTvlByVaultInToken(
            address _vault
        )
            external
            view
            returns (uint256);

        function getTotalTvlInUSD()
            external
            view
            returns (uint256);

        function getTotalUserTvl()
            external
            view
            returns (uint256);

        function getUserTVLByVaultInUSD(
            address _vault
        )
            external
            view
            returns (uint256);
    }

error wrongVaultAddress();

contract easyPiStats{

    IGmxHelper public immutable GMX_HELPER;
    IOracleHub public immutable ORACLE_HUB;
    ISwapHub public immutable SWAP_HUB;
    IGlpmanager public immutable GLPMANAGER;

    mapping (address => uint256) public startBalance;
    mapping (uint256 => address) public tokenAddresses;
    mapping (address => uint256) public startTime;
    mapping (address => address) public associatedTokenForVault;

    address[] public vaultAddresses;
    IERC20[] public shareTokens;

    uint256 public vaultsAdded;

    uint256 public constant PRECISION_FACTOR_30 = 10 ** 30;

    constructor(
        address _gmxHelperAddress,
        address _oracleHubAddress,
        address[] memory _tokenAddress,
        address _swapHub,
        address _glpManager,
        address[] memory _vaults,
        IERC20[] memory _shareTokens
    )
    {
        require(
            _vaults.length == _tokenAddress.length,
            "Mismatched lengths of _vaults and _tokenAddress"
        );

        require(
            _vaults.length == _shareTokens.length,
            "Mismatched lengths of _vaults and _shareTokens"
        );

        GMX_HELPER = IGmxHelper(_gmxHelperAddress);
        ORACLE_HUB = IOracleHub(_oracleHubAddress);
        SWAP_HUB = ISwapHub(_swapHub);
        GLPMANAGER = IGlpmanager(_glpManager);

        for (uint256 i = 0; i < _vaults.length; i++) {
            associatedTokenForVault[_vaults[i]] = _tokenAddress[i];
            tokenAddresses[i] = _tokenAddress[i];
            vaultsAdded += 1;
            startBalance[_vaults[i]] = calcTokenAmount(_vaults[i]);
            vaultAddresses.push(_vaults[i]);
            startTime[_vaults[i]] = block.timestamp;
            shareTokens.push(_shareTokens[i]);
        }
    }

    function resetVaultTracking(
        address _poolAddress
    )
        external
    {
        startTime[_poolAddress] = block.timestamp;
        startBalance[_poolAddress] = calcTokenAmount(
            _poolAddress
        );
    }

    function getApy(
        address _poolAddress
    )
        external
        view
        returns (
            uint256,
            bool
        )
    {
        uint256 timePassed = block.timestamp - startTime[_poolAddress];
        uint256 yearsPassedPrecisionInverse = 52 weeks
            * 1 ether
            / timePassed;
        (,uint256 currentTotalValue) = totalValue(
            _poolAddress
        );
        bool inProfit = currentTotalValue > 1 ether;
        uint256 numerator = inProfit
            ? currentTotalValue - 1 ether
            : 1 ether - currentTotalValue;

        return (
            numerator
             * yearsPassedPrecisionInverse
             / 1 ether,
            inProfit
        );
    }

    function addVault(
        address _tokenAddress,
        address _poolAddress
    )
        external
    {
        associatedTokenForVault[_poolAddress] = _tokenAddress;
        tokenAddresses[vaultsAdded + 1] = _tokenAddress;
        startBalance[_poolAddress] = calcTokenAmount(
            _poolAddress
        );
        vaultsAdded += 1;

        vaultAddresses.push(_poolAddress);
        startTime[_poolAddress] = block.timestamp;
    }

    function totalValue(
        address _poolAddress
    )
        public
        view
        returns(
            uint256,
            uint256
        )
    {
        uint256 tokenAmount = calcTokenAmount(
            _poolAddress
        );

        return (
            tokenAmount,
            tokenAmount
                * 1 ether
                / startBalance[_poolAddress]
        );
    }

    function calcTokenAmount(
        address _poolAddress
    )
        internal
        view
        returns (uint256)
    {
        uint256 tokenAmountNow = ORACLE_HUB.getTokenAmountFromUSD(
            getTvlByVaultUSD(_poolAddress),
            associatedTokenForVault[_poolAddress]
        );

        return tokenAmountNow;
    }

    function getTvlByVaultUSD(
        address _vault
    )
        public
        view
        returns (uint256)
    {
        uint256 amountCollateralUSD = GMX_HELPER.liveAaveCollateralAmountUSD(
            _vault
        )
            - GMX_HELPER.liveTotalBorrowAmountUSD(
                _vault
            );

        uint256 amountInGlpUSD =
            SWAP_HUB.getGlpBalance(
                _vault
            )
             * GLPMANAGER.getPrice(
                false
            )
            / PRECISION_FACTOR_30;

        return amountCollateralUSD
            + amountInGlpUSD;
    }

    function getTvlByVaultInToken(
        address _vault
    )
        external
        view
        returns (uint256)
    {
        return calcTokenAmount(
            _vault
        );
    }

    function getTotalTvlInUSD()
        external
        view
        returns (uint256 totalTvlInUsd)
    {
        for (uint8 i = 0; i < vaultAddresses.length; i++) {
            totalTvlInUsd += getTvlByVaultUSD(
                vaultAddresses[i]
            );
        }
    }

    function getTotalUserTvl(
        address _user
    )
        external
        view
        returns (uint256 totalUserTvl)
    {

        for (uint8 i = 0; i < vaultAddresses.length; i++) {

            totalUserTvl += _calcUserTvlByVaultInUsd(
                _user,
                i
            );
        }
    }

    function getUserTVLByVaultInUSD(
        address _user,
        address _vault
    )
        public
        view
        returns (uint256)
    {
        uint256 matchedIndex;
        uint256 length = vaultAddresses.length;

        for (uint8 i = 0; i < length; i++) {
            if (_vault == vaultAddresses[i]) {
                matchedIndex = i;
                break;
            }

            if (i == length - 1) {
                revert wrongVaultAddress();
            }
        }

        return _calcUserTvlByVaultInUsd(
            _user,
            matchedIndex
        );
    }

    function _calcUserTvlByVaultInUsd(
        address _user,
        uint256 _index
    )
        internal
        view
        returns (uint256)
    {
        uint256 userBalance = shareTokens[_index].balanceOf(
            _user
        );

        uint256 totalBalance = shareTokens[_index].totalSupply();
        if (totalBalance == 0) {
            return 0;
        }
        uint256 percentage = userBalance
            * PRECISION_FACTOR_30
            / totalBalance;

        return percentage
            * getTvlByVaultUSD(
                vaultAddresses[_index]
            )
            / PRECISION_FACTOR_30;
    }

}