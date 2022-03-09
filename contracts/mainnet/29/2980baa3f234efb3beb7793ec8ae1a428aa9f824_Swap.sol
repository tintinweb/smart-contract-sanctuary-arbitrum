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

interface OwnershipLike {
    function transferOwnership(address newOwner) external;
    function addCollateral(address ctoken, address feed) external;
}

contract CollateralAdder {
    function add(address[] calldata ctokens, OwnershipLike bamm, CPriceFeed cFeed) external {
        require(msg.sender == 0x23cBF6d1b738423365c6930F075Ed6feEF7d14f3, "invalid owner");

        for(uint i = 0 ; i < ctokens.length ; i++) {
            address ctoken = ctokens[i];
            address feed = cFeed.generateDegenFeed(ctoken);
            bamm.addCollateral(ctokens[i], feed);
        }

        bamm.transferOwnership(msg.sender);
    }
}


interface BAMMSwapLike {
    function swap(uint lusdAmount, address returnToken, uint minReturn, address dest, bytes memory data) external returns(uint);
}

interface ICToken {
    function balanceOf(address a) external view returns (uint);
    function underlying() external view returns(IERC20);
    function redeem(uint redeemAmount) external returns (uint);
    function mint(uint amount) external returns(uint);
}

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract Swap {
    function swap(address bamm, uint underlyingAmount, address ctokenOutput, uint minOutputUnerlyingAmount) public {
        address cBorrow = BAMMLike(bamm).cBorrow();
        IERC20 erc20 = IERC20(ICToken(cBorrow).underlying());
        erc20.transferFrom(msg.sender, address(this), underlyingAmount);
        erc20.approve(cBorrow, underlyingAmount);
        ICToken(cBorrow).mint(underlyingAmount);
        uint cBalance = IERC20(cBorrow).balanceOf(address(this));
        IERC20(cBorrow).approve(bamm, cBalance);
        bytes memory empty;
        uint ctokenOutBalance = BAMMSwapLike(bamm).swap(cBalance, ctokenOutput, 0, address(this), empty);

        IERC20 erc20Out = IERC20(ICToken(ctokenOutput).underlying());
        ICToken(ctokenOutput).redeem(ctokenOutBalance);

        uint outBalance = erc20Out.balanceOf(address(this));
        require(outBalance >= minOutputUnerlyingAmount, "swap: return amount too small");

        erc20Out.transfer(msg.sender, outBalance);
    }
}