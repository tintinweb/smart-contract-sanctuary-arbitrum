/**
 *Submitted for verification at Arbiscan on 2022-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface BAMMLike {
    function cBorrow() external view returns(address);
}

interface OracleLike {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

interface ComptrollerLike {
    function oracle() view external returns(OracleLike);
}

interface CTokenLike {
    function exchangeRateStored() external view returns (uint); 
}

interface CPriceFeedLike {
    function decimals() view external returns(uint);
    function getPriceFromBamm(address sender, address dst) view external returns(uint);
}

contract DegenFeed {
    CPriceFeedLike immutable priceFeed;
    address immutable ctoken;

    constructor(address _priceFeed, address _ctoken) public {
        priceFeed = CPriceFeedLike(_priceFeed);
        ctoken = _ctoken;
    }

    function decimals() view public returns(uint) {
        return priceFeed.decimals();
    }

    function latestRoundData() external view returns
     (
        uint80 /* roundId */,
        int256 answer,
        uint256 /* startedAt */,
        uint256 timestamp,
        uint80 /* answeredInRound */
    )
    {
        answer = int(priceFeed.getPriceFromBamm(msg.sender, ctoken));
        timestamp = now;
    }
}
/*
price feed for ctokens. a single feed for all ctokens.
*/
contract CPriceFeed {
    ComptrollerLike immutable comptroller;
    uint public constant decimals = 18;

    constructor(ComptrollerLike _comptroller) public {
        comptroller = _comptroller;
    }

    function getPrice(address src, address dst) public view returns(uint) {
        OracleLike oracle = comptroller.oracle();        
        uint srcUnderlyingPrice = oracle.getUnderlyingPrice(src);
        uint dstUnderlyingPrice = oracle.getUnderlyingPrice(dst);

        uint srcExchangeRate = CTokenLike(src).exchangeRateStored();
        uint dstExchangeRate = CTokenLike(dst).exchangeRateStored();

        uint price = (10 ** decimals) * dstExchangeRate * dstUnderlyingPrice / (srcExchangeRate * srcUnderlyingPrice);
        return price;

        // TODO - verify there is no overflow
    }

    function getPriceFromBamm(address sender, address dst) public view returns(uint) {
        address src = BAMMLike(sender).cBorrow();
        return getPrice(src, dst);
    }

    function generateDegenFeed(address dstCToken) public returns(address) {
        DegenFeed degenFeed =  new DegenFeed(address(this), dstCToken);
        return address(degenFeed);
    }
}