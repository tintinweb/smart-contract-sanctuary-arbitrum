/**
 *Submitted for verification at arbiscan.io on 2022-02-05
*/

pragma solidity 0.8.10;

interface IERC20Mintable 
{
    function mint(address, uint) external returns (bool);
    function renounceMinter() external;
}

contract Sale
{
    uint constant STARTING_POINT = 5 * 10**18; // 5 eth, meaning 4M (1% of total tokens)
    uint constant WAD = 10**18;
    uint constant MAX_TOKENS_SOLD = 400 * 10**6 * 10**18;    // 400M sold implying a maximum of 1 Billion

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
        address _referrer,
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

        emit Bought(_receiver, _referrer, tokensAssigned);
    }

    function mintTokens(
            address _receiver, 
            uint _amount, 
            address _referrer)
        private 
    {
        // distrobution:
        // 40% buyer
        // 25% pools
        // 25% levr dao
        // 5% foundry (other 5% repaid in FRY burning)
        // 5% referrer (if specified, else sent to the treasury)
        // -----
        // 100% (should be the total up to this point)
        // -----

        uint perc = _amount / 40;

        tokenOnSale.mint(_receiver, _amount); // same as perc * 40, but without the potential rounding error. 

        tokenOnSale.mint(gulper, perc * 25);

        // give the the levr treasury its share
        tokenOnSale.mint(treasury, perc * 25);

        // reward the foundry treasury for it's role
        // the other half of the reward is in eth to buy back and burn fry
        tokenOnSale.mint(foundryTreasury, perc * 5);

        // reward the referrer with 5% on top of the total amount minted here
        if (_referrer == address(0))
        {
            tokenOnSale.mint(treasury, perc * 5);
        } 
        else
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

contract RenounceMinter
{
    address public owner;

    constructor(address _owner)
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        owner = _newOwner;
    }

    function renounceMinter(IERC20Mintable _token)
        public
        onlyOwner
    {
        _token.renounceMinter();
    }
}

contract ArbitrumLevrSale is Sale, RenounceMinter
{
    constructor() 
    Sale(
        1600000000000000000000000000000000000000000000000,              // incline
        IERC20Mintable(0x77De4df6F2d87Cc7708959bCEa45d58B0E8b8315),     // LEVR erc20
        0x158c793236636756e8B83B0112B2e33315d298c7,                     // splitter that feeds gulpers
        0x2A0EdcD9C46fAf8689F5dd475c2e4Da4eeb51301,                     // levr.ly treasury
        0xC38f63Aba640F390F1108A81a441F27398867722)                     // Foundry treasury on Arbitrum
    RenounceMinter(0x7040E1373d281Ec5d6972B3546EAbf2E3Db81E56)          // Gnosis multisig
    { }
}