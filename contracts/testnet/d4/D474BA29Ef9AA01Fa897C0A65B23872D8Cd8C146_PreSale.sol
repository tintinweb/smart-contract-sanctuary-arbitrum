// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

interface IZooToken {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(address from, address to, uint256 value) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function referrer(address _myAddress) external view returns (address);

    function SetReferral(address _referrer, address _referral) external;
}

interface IUSDTToken {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(address from, address to, uint256 value) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract PreSale is Pausable {
    using SafeMath for uint256;

    IZooToken public ZooToken;
    IUSDTToken public UsdtToken;

    address public liquidityWallet;
    address public teamWallet;
    address public marketingWallet;
    address public slipageFeeWallet;

    uint public liquiditySharePercent; // 600/1000 = 60%
    uint public teamSharePercent; // 100/1000 = 10%
    uint public marketingSharePercent; // 235/1000 = 23.5%
    uint public slipageFeeSharePercent; // 65/1000 = 6.5%

    uint256 public USDTRaised;

    uint256 public cap;

    uint256 public mintedTokens;

    uint256 public minInvestment;

    uint256 public maxInvestment;

    uint256 public rate;

    uint256 public reffererFee;

    uint256 public ZooTokenDecimal = 1000000;

    uint256 public startTime;

    uint256 public endTime;

    mapping(address => uint256) public userBalance;

    event _startPreSale(
        address liquidityWallet,
        address teamWallet,
        address marketingWallet,
        address slipageFeeWallet,
        uint256 cap,
        uint256 rate,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 reffererFee,
        uint256 startTime,
        uint256 endTime
    );

    event _changeMinInvestment(uint256 minInvestment);
    event _changeMaxInvestment(uint256 maxInvestment);
    event _changeCap(uint256 cap);
    event _changeReffererFee(uint256 reffererFee);
    event _buyZooTokens(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 amount,
        uint256 investorsTokens,
        uint256  tokens,
        uint256 reffererTokens
    );
    event _changeZooTokenDecimal(uint256 ZooTokenDecimal);
    event _changeLiquidityWallet(address liquidityWallet);
    event _changeTeamWallet(address teamWallet);
    event _changeMarketingWallet(address marketingWallet);
    event _changeSlipageFeeWallet(address slipageFeeWallet);
    event _x(uint256 tokens);

    function startPreSale(
        address _liquidityWallet,
        address _teamWallet,
        address _marketingWallet,
        address _slipageFeeWallet,
        uint256 _cap,
        uint256 _rate,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _reffererFee,
        uint256 _endTime,
        IZooToken _ZooToken,
        IUSDTToken _UsdtToken
    ) public onlyOwner {
        require(_liquidityWallet != address(0), "liquidity wallet can not be zero address");
        require(_teamWallet != address(0), "team wallet can not be zero address");
        require(_marketingWallet != address(0), "marketing wallet can not be zero address");
        require(_slipageFeeWallet != address(0), "marketing wallet can not be zero address");
        require(_ZooToken != IZooToken(address(0)), "zoo token can not be zero address");
        require(_UsdtToken != IUSDTToken(address(0)), "usdt token can not be zero address");
        require(_rate > 0);
        require(
            _minInvestment >= _rate,
            "minimum investment should be greater than or equal to rate of token"
        );
        require(
            _minInvestment < _maxInvestment,
            "maximum investment should be greater than or equal to rate of token"
        );
        require(_reffererFee > 0);
        require(_endTime > block.timestamp, "endtime is incorrect");

        liquidityWallet = _liquidityWallet;
        teamWallet = _teamWallet;
        marketingWallet = _marketingWallet;
        slipageFeeWallet = _slipageFeeWallet;
        rate = _rate;
        minInvestment = _minInvestment; //minimum investment in wei  (=10 ether)
        maxInvestment = _maxInvestment;
        cap = _cap; //cap in tokens base units (=295257 tokens)
        reffererFee = _reffererFee;
        startTime = block.timestamp;
        endTime = _endTime;
        ZooToken = _ZooToken;
        UsdtToken = _UsdtToken;
        //set wallets share
        liquiditySharePercent = 600;
        teamSharePercent = 100;
        marketingSharePercent = 235;
        slipageFeeSharePercent = 65;

        emit _startPreSale(
            liquidityWallet,
            teamWallet,
            marketingWallet,
            slipageFeeWallet,
            cap,
            rate,
            minInvestment,
            maxInvestment,
            reffererFee,
            startTime,
            endTime
        );
    }

    /**
     * Low level token purchse function
     * @param beneficiary will recieve the tokens.
     */
    function buyZooTokens(
        address beneficiary,
        address _refer,
        uint256 _inputAmount
    ) public whenNotPaused {
        //checking address and minimum investment
        require(beneficiary != address(0), "beneficiary can not be zero address");
        require(_inputAmount >= minInvestment);
        require(block.timestamp < endTime,"sale has ended");

        //checking cap
        uint256 tokens = ((_inputAmount * ZooTokenDecimal) / rate);
        require(tokens + mintedTokens <= cap,"you are exceeding the cap");

        // checking maximum
        require(userBalance[beneficiary] <= maxInvestment, "you have purchased maximum tokens");

        UsdtToken.transferFrom(beneficiary, address(this), _inputAmount);

        // update USDTRaised
        USDTRaised = USDTRaised.add(_inputAmount);
        mintedTokens += tokens;

        //updating user balance
        userBalance[beneficiary] += _inputAmount ;

        //tokens for referrer
        uint256 referrerTokens;
        address referrer = ZooToken.referrer(beneficiary);
        if (referrer != address(0)) {
            referrerTokens = ((reffererFee / 100) * tokens) / ZooTokenDecimal;
            ZooToken.mint(referrer, referrerTokens);
        }else{
            if(_refer != address(0)){
               ZooToken.SetReferral(_refer, beneficiary);
               referrerTokens = ((reffererFee / 100) * tokens) / ZooTokenDecimal;
               ZooToken.mint(_refer, referrerTokens);
            }
        }
        
        // tokens for beneficiary
        uint256 investorsTokens = tokens - referrerTokens;
        
        ZooToken.mint(beneficiary, investorsTokens);

        //move usd to the wallets
        uint liquidityShareAmount = (liquiditySharePercent*_inputAmount)/1000;
        uint teamShareAmount = (teamSharePercent*_inputAmount)/1000;
        uint marketingShareAmount = (marketingSharePercent*_inputAmount)/1000;
        uint slipageFeeShareAmount = (slipageFeeSharePercent*_inputAmount)/1000;
        UsdtToken.transfer(liquidityWallet, liquidityShareAmount);
        UsdtToken.transfer(teamWallet, teamShareAmount);
        UsdtToken.transfer(marketingWallet, marketingShareAmount);
        UsdtToken.transfer(slipageFeeWallet, slipageFeeShareAmount);

        emit _buyZooTokens(msg.sender, beneficiary, _inputAmount, investorsTokens,tokens,referrerTokens);
        
    }
     
    function changeReffererFee(uint256 fee) public onlyOwner {
        require(fee > 0);
        reffererFee = fee;
        emit _changeReffererFee(reffererFee);
    }

    function changeCap(uint256 _cap) public onlyOwner {
        require(_cap > 0);
        require(_cap > mintedTokens);
        cap = _cap;
        emit _changeCap(cap);
    }

    function changeMinInvestment(uint256 _minInvestment) public onlyOwner {
        require(_minInvestment >= rate, "minimum investment should be more than rate");

        minInvestment = _minInvestment;
        emit _changeMinInvestment(minInvestment);
    }

    function changeMaxInvestment(uint256 _maxInvestment) public onlyOwner {
        require(_maxInvestment > minInvestment, "max investment should be more than min investment");

        maxInvestment = _maxInvestment;
        emit _changeMaxInvestment(maxInvestment);
    }

    function changeLiquidityWallet(address _liquidityWallet) public onlyOwner {
        require(_liquidityWallet != address(0),"liquidity wallet can not be zero address");
        liquidityWallet = _liquidityWallet;
        emit _changeLiquidityWallet(liquidityWallet);
    }

    function changeTeamWallet(address _teamWallet) public onlyOwner {
        require(_teamWallet != address(0), "team wallet can not be zero address");
        teamWallet = _teamWallet;
        emit _changeTeamWallet(teamWallet);
    }

    function changeMarketingWallet(address _marketingWallet) public onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can not be zero address");
        marketingWallet = _marketingWallet;
        emit _changeMarketingWallet(marketingWallet);
    }

    function changeSlipageFeeWallet(address _slipageFeeWallet) public onlyOwner {
        require(_slipageFeeWallet != address(0), "slipage wallet can not be zero address");
        slipageFeeWallet = _slipageFeeWallet;
        emit _changeSlipageFeeWallet(slipageFeeWallet);
    }

    function changeWalletsShare(uint _liquiditySharePercent, uint _teamSharePercent, uint _marketingSharePercent, uint _slipageFeeSharePercent) public onlyOwner {
        require(_liquiditySharePercent + _teamSharePercent + _marketingSharePercent + _slipageFeeSharePercent == 1000, "total of all percents is not 1000");
        liquiditySharePercent = _liquiditySharePercent;
        teamSharePercent = _teamSharePercent;
        marketingSharePercent = _marketingSharePercent;
        slipageFeeSharePercent = _slipageFeeSharePercent;
    }

    function hasEnded() public view returns (bool) {
        bool capReached = (mintedTokens >= cap) || block.timestamp > endTime;
        return capReached;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getTotalMinted() public view returns (uint256) {
        return mintedTokens;
    }
    function getPriceOfToken() public view returns (uint256) {
        return rate;
    }
    function getMinInvestment() public view returns (uint256) {
        return minInvestment;
    }
    function getMaxInvestment() public view returns (uint256) {
        return maxInvestment;
    }
    function getUserBalance(address user) public view returns (uint256) {
        return userBalance[user];
    }
    function getCap() public view returns (uint256) {
        return cap;
    }

}