/**
 *Submitted for verification at Arbiscan on 2023-05-01
*/

//SPDX-License-Identifier: -- EASY-PI --

pragma solidity =0.8.18;

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

contract TotalValueCalculator{
    IGmxHelper public immutable GMX_HELPER;
    IOracleHub public immutable ORACLE_HUB;
    ISwapHub public immutable SWAP_HUB;
    IGlpmanager public immutable GLPMANAGER;

    mapping (address => uint256) public startBalance;
    mapping (uint256 => address) public tokenAddresses;
    mapping (address => uint256) public startTime;
    mapping (address => address) public associatedTokenForVault;

    address[] public vaultAddresses;

    uint256 public vaultsAdded;

    uint256 public constant PRECISION_FACTOR_30 = 10 ** 30;

    constructor(
        address _gmxHelperAddress,
        address _oracleHubAddress,
        address[] memory _tokenAddress,
        address _swapHub,
        address _glpManager,
        address[] memory _vaults
    )
    {
        associatedTokenForVault[_vaults[0]] = _tokenAddress[0];

        tokenAddresses[0] = _tokenAddress[0];
        vaultsAdded += 1;

        GMX_HELPER = IGmxHelper(_gmxHelperAddress);
        ORACLE_HUB = IOracleHub(_oracleHubAddress);
        SWAP_HUB = ISwapHub(
            _swapHub
        );
        GLPMANAGER = IGlpmanager(
            _glpManager
        );
        startBalance[_vaults[0]] = calcTokenAmount(
            _vaults[0]
        );

        vaultAddresses.push(_vaults[0]);

        startTime[_vaults[0]] = block.timestamp;
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
        returns (uint256,bool)
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
            numerator * yearsPassedPrecisionInverse / 1 ether,
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
        uint256 amountUSD = GMX_HELPER.liveAaveCollateralAmountUSD(
            _poolAddress
        )
            - GMX_HELPER.liveTotalBorrowAmountUSD(
                _poolAddress
            )
            + (
                SWAP_HUB.getGlpBalance(
                _poolAddress
                )
                    * GLPMANAGER.getPrice(
                        false
                )
                / PRECISION_FACTOR_30
                );

        uint256 tokenAmountNow = ORACLE_HUB.getTokenAmountFromUSD(
            amountUSD,
            associatedTokenForVault[_poolAddress]
        );

        return tokenAmountNow;
    }
}