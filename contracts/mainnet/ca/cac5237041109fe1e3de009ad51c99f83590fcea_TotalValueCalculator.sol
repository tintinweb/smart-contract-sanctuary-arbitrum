/**
 *Submitted for verification at Arbiscan on 2023-01-29
*/

//SPDX-License-Identifier: -- EASY-PI --

pragma solidity =0.8.17;

   interface IGmxHelper{

        function liveTotalCollateralAmountUSD()
            external 
            view
            returns (uint256);

        function liveTotalBorrowAmountUSD()
            external 
            view
            returns (uint256);
    }

    interface IOracleHub{
        function getPriceGLPBackup()
            external 
            view
            returns (uint256);
    }

    interface IGlpFeePlusStaked{
        function balanceOf(
            address _user
        )
            external 
            view 
            returns (uint256);
    }

contract TotalValueCalculator{
    IGmxHelper public immutable GMX_HELPER;
    IOracleHub public immutable ORACLE_HUB;
    IGlpFeePlusStaked public immutable GLP_FEE_PLUS_STAKED;

    address public immutable easyPiAddress;

    address public constant GlpFeePlusStaked = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
  
    constructor(
        address _gmxHelperAddress,
        address _oracleHubAddress,
        address _easyPiAddress
    )
    {
        easyPiAddress = _easyPiAddress;
        GLP_FEE_PLUS_STAKED = IGlpFeePlusStaked(GlpFeePlusStaked);
        GMX_HELPER = IGmxHelper(_gmxHelperAddress);
        ORACLE_HUB = IOracleHub(_oracleHubAddress);
    }

    function totalValue()
        external 
        view 
        returns(uint256)
    {
        uint256 price = GMX_HELPER.liveTotalCollateralAmountUSD()
            - GMX_HELPER.liveTotalBorrowAmountUSD()
            + GLP_FEE_PLUS_STAKED.balanceOf(easyPiAddress)
                 * ORACLE_HUB.getPriceGLPBackup()
                 / 1 ether;
        
        return price;
    }
}