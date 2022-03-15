/**
 *Submitted for verification at Arbiscan on 2022-03-15
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

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
        timestamp = block.timestamp;
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