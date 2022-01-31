/**
 *Submitted for verification at arbiscan.io on 2022-01-30
*/

pragma solidity 0.8.10;

interface IERC20Mintable 
{
    function mint(address, uint) external returns (bool);
}

contract Sale
{
    uint constant ONE_PERC = 10**16;
    uint constant ONE_HUNDRED_PERC = 10**18;
    uint constant STARTING_POINT = 5000505357194460000;     // 3.5M (1% of total tokens)
    uint constant WAD = 10**18;
    uint constant MAX_TOKENS_SOLD = 350 * 10**6 * 10**18;    // 350M

    uint public raised = STARTING_POINT; //used this to spare one storage slot and simplify later code                      
    uint public tokensSold;                       
    uint public inclineWAD;                         

    IERC20Mintable public tokenOnSale;

    // gulpers
    address public gulper;

    address public treasury;
    address public foundryTreasury;

    constructor(
            uint _inclineWAD,              
            IERC20Mintable _tokenOnSale,
            address _gulper, 
            address _treasury, 
            address _foundryTreasury)
    {
        inclineWAD = _inclineWAD;
        tokenOnSale = _tokenOnSale;
        gulper = _gulper;
        treasury = _treasury;
        foundryTreasury = _foundryTreasury;
        tokensSold = pureCalculateSupply(inclineWAD, STARTING_POINT);
    }

    event Bought
    (
        address _receiver,
        uint _amount
    );

    receive()
        payable
        external
    {
        buy(msg.sender, address(0));
    }

    function buy(address _receiver, address _referrer)
        public
        payable
    {
        uint tokensAssigned = calculateTokensReceived(msg.value);
        require(tokensSold + tokensAssigned <= MAX_TOKENS_SOLD, "Tokens sold out");
        
        (bool success,) = gulper.call{value:msg.value}("");
        require(success, "gulper malfunction");

        tokensSold = tokensSold + tokensAssigned;
        raised = raised + msg.value;

        mintTokens(_receiver, tokensAssigned, _referrer);

        emit Bought(_receiver, tokensAssigned);
    }

    function mintTokens(
            address _receiver, 
            uint _amount, 
            address _referrer)
        private 
    {
        // distrobution:
        // 35% buyer
        // 25% pools
        // 35% levr dao
        // 10% foundry (other repaid in FRY burning)
        // -----
        // 100% (should be the total up to this point)
        // 5% referrer (optional)

        uint perc = _amount / 100;

        tokenOnSale.mint(_receiver, perc * 35);

        // Only 71% of the amount issued to the buyer, 
        // this is to make the price slightly higher and compensate for the dEh arbitrage that's going to occur.
        tokenOnSale.mint(gulper, perc * 25);

        // give the the levr treasury its share
        tokenOnSale.mint(treasury, perc * 35);

        // reward the foundry treasury for it's role
        // the other half of the reward is in eth to buy back and burn fry
        tokenOnSale.mint(foundryTreasury, perc * 5);

        // reward the referrer with 5% of the sold amount
        if (_referrer != address(0))
        {
            tokenOnSale.mint(_referrer, perc * 5);
        }
    }

    function pureCalculateSupply(uint _inclineWAD, uint _raised)
        public
        pure
        returns(uint _tokens)
    {
        // (2*incline*raised)^0.5 
        _tokens = sqrt(uint(2) * _inclineWAD * _raised / WAD);
    }

    function pureCalculateTokensRecieved(uint _inclineWAD, uint _alreadyRaised, uint _supplied) 
        public
        pure
        returns (uint _tokensReturned)
    {
        _tokensReturned = pureCalculateSupply(_inclineWAD, _alreadyRaised + _supplied) - pureCalculateSupply(_inclineWAD, _alreadyRaised);
    }

    function calculateTokensReceived(uint _supplied)
        public
        view
        returns (uint _tokensReturned)
    {
        _tokensReturned = pureCalculateTokensRecieved(inclineWAD, raised, _supplied);       
    }

    function pureCalculatePrice(uint _inclineWAD, uint _tokensSold)
        public
        pure
        returns(uint _price)
    {
        // TODO: double check this with Elmer
        _price = (_tokensSold * WAD * WAD) / _inclineWAD;
    }

    function calculatePrice(uint _tokensSold)
        public
        view
        returns(uint _price)
    {
        _price = pureCalculatePrice(inclineWAD, _tokensSold);
    }

    function getCurrentPrice()
        public
        view
        returns(uint _price)
    {
        _price = calculatePrice(tokensSold);
    }

    function pureCalculatePricePerToken(uint _inclineWAD, uint _alreadyRaised, uint _supplied)              
        public
        pure
        returns(uint _price)
    {
        _price = _supplied * WAD / pureCalculateTokensRecieved(_inclineWAD, _alreadyRaised, _supplied);
    }

    function calculatePricePerToken(uint _supplied)
        public
        view
        returns(uint _price)
    {
        _price = pureCalculatePricePerToken(inclineWAD, raised, _supplied);
    }

    function pointPriceWAD()
        public
        view
        returns(uint _price)
    {
        _price = raised * WAD / tokensSold;
    }

    // babylonian method
    function sqrt(uint x) 
        public 
        pure
        returns (uint y) 
    {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x/z + z) / 2;
            (x/z + z)/2;
        }
    }
}

contract ArbitrumLevrSale is Sale
{
    constructor() Sale(
        1224876200000000000000000000000000000000000000000,              // incline?
        IERC20Mintable(0x7A416Afc042537f290CB44A7c2C269Caf0Edc93C),     // LEVR erc20
        0x91ABD747E28AD2D28bE910C8b8B965cfB1AD92eE,                     // splitter that feeds gulpers
        0x2A0EdcD9C46fAf8689F5dd475c2e4Da4eeb51301,                     // levr.ly treasury
        0xC38f63Aba640F390F1108A81a441F27398867722)                     // Foundry treasury on Arbitrum
    { }
}