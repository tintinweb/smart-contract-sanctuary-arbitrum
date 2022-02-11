/**
 *Submitted for verification at arbiscan.io on 2022-02-05
*/

pragma solidity 0.8.10;

interface ISale 
{
    function calculateTokensReceived(uint)
        external
        view
        returns (uint);

    function calculatePricePerToken(uint)
        external
        view
        returns(uint);

    function tokensSold()
        external
        view
        returns(uint);
    
    function raised()

        external
        view
        returns(uint);

    function addToRaised(uint256 _addition)
        external;

    function subractFromRaised(uint256 _sub)
        external;

    function calculatePrice(uint _tokensIssued)
        external
        view
        returns(uint);
}

contract SaleInfo 
{

    ISale public Sale;

    constructor(ISale _SaleAddress) 
    {
        Sale = _SaleAddress;
    }

    function getSaleInfo(uint _supplied)
        public
        view
    returns(
            uint _raisedBefore,
            uint _totalTokensSoldBefore,
            uint _priceBefore, 
            
            uint _raisedAfter,
            uint _totalTokensSoldAfter,
            uint _priceAfter,
            
            uint _tokensReceived,
            uint _pricePaidPerToken)
    {
        _raisedBefore = Sale.raised();
        _totalTokensSoldBefore = Sale.tokensSold();
        _priceBefore = Sale.calculatePrice(_totalTokensSoldBefore);

        _raisedAfter = _raisedBefore + _supplied;
        _tokensReceived = Sale.calculateTokensReceived(_supplied);
        _totalTokensSoldAfter = _totalTokensSoldBefore + _tokensReceived;
        _priceAfter = Sale.calculatePrice(_totalTokensSoldAfter);

        _pricePaidPerToken = Sale.calculatePricePerToken(_supplied);
    }

    function addRaised(uint _add)
        external
    {
        Sale.addToRaised(_add);
    }

    function subtractRaised(uint _sub)
        external
    {
        Sale.subractFromRaised(_sub);
    }

}

contract ArbitrumSaleInfo is SaleInfo
{
    constructor() SaleInfo(ISale(0x8e131BD8CD1D9E5bCE080bc54613d811E0425aF8))
    { }
}