/**
 *Submitted for verification at Arbiscan.io on 2024-04-24
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Presale is Ownable {
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 public vestingStartTime;
    uint256 public tokensToSell;
    uint256[] public tokenPerUsdPrice;
    uint256 public totalStages;
    uint8 public tokenDecimals;
    uint256 public totalStakedAmount;

    uint256 public percentDivider = 100_00;
    uint256 public RefRewardPercent = 1_00;

    AggregatorV3Interface public priceFeed;

    struct Phase {
        uint256 tokenPerUsdPrice;
    }

    uint256 public currentStage;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public amountRaisedUSDT;
    uint256 public amountRaisedUSDC;
    uint256 public uniqueBuyers;
    address payable public fundReceiver;

    bool public presaleStatus;
    bool public isPresaleEnded;

    address[] public UsersAddresses;
    struct User {
        uint256 native_balance;
        uint256 usdt_balance;
        uint256 usdc_balance;
        uint256 refReward;
        uint256 claimedAmount;
        uint256 claimAbleAmount;
    }
    mapping(address => User) public users;
    mapping(uint256 => Phase) public phases;
    mapping(address => bool) public isExist;
    mapping(address => address) public referral;
    mapping(address => uint256) public referralCount;

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address _user, uint256 indexed _amount);
    event UpdatePrice(uint256 _oldPrice, uint256 _newPrice);

    constructor( address _fundReceiver) {
        fundReceiver = payable(_fundReceiver);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        tokenDecimals = 18;
        tokensToSell = 150_000_000 * 10**tokenDecimals;
        tokenPerUsdPrice = [
            200 * 10**(tokenDecimals),
            18181 * 10**(tokenDecimals - 2),
            1666 * 10**(tokenDecimals - 1),
            15384 * 10**(tokenDecimals - 2),
            14285 * 10**(tokenDecimals - 2),
            13333 * 10**(tokenDecimals - 2),
            125 * 10**(tokenDecimals),
            11764 * 10**(tokenDecimals - 2),
            11111 * 10**(tokenDecimals - 2),
            10526 * 10**(tokenDecimals - 2)
        ];
        for (uint256 i = 0; i < tokenPerUsdPrice.length; i++) {
            phases[i].tokenPerUsdPrice = tokenPerUsdPrice[i];
        }
        totalStages = tokenPerUsdPrice.length;
    }

    // update a presale
    function updatePresale(uint256 _phaseId, uint256 _tokenPerUsdPrice)
        public
        onlyOwner
    {
        phases[_phaseId].tokenPerUsdPrice = _tokenPerUsdPrice;
    }

    // to get real time price of ETH
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with ETH => for web3 use

    function buyToken(address _refAddress) public payable {
        require(_refAddress != msg.sender, "can't ref yourself");
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }
        fundReceiver.transfer(msg.value);

        uint256 numberOfTokens;
        numberOfTokens = nativeToToken(msg.value, currentStage);
        require(
            soldToken + numberOfTokens <=
                tokensToSell,
            "Phase Limit Reached"
        );
        if (referral[msg.sender] == address(0) && isExist[_refAddress]) {
            referral[msg.sender] = _refAddress;
            referralCount[_refAddress] += 1;
            users[_refAddress].refReward +=
                (numberOfTokens * RefRewardPercent) /
                percentDivider;
        }

        soldToken = soldToken + (numberOfTokens);
        amountRaised = amountRaised + msg.value;

        users[msg.sender].native_balance =
            users[msg.sender].native_balance +
            (msg.value);
        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;
    }

    // to buy token during preSale time with USDT => for web3 use
    function buyTokenUSDT(uint256 amount, address _refAddress) public {
        require(_refAddress != msg.sender, "can't ref yourself");
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }
        USDT.transferFrom(msg.sender, address(this), amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount, currentStage);
        require(
            soldToken + numberOfTokens <=
                tokensToSell,
            "Phase Limit Reached"
        );
        if (referral[msg.sender] == address(0) && isExist[_refAddress]) {
            referral[msg.sender] = _refAddress;
            referralCount[_refAddress] += 1;
            users[_refAddress].refReward +=
                (numberOfTokens * RefRewardPercent) /
                percentDivider;
        }
        soldToken = soldToken + numberOfTokens;
        amountRaisedUSDT = amountRaisedUSDT + amount;

        users[msg.sender].usdt_balance += amount;
        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;
    }

    // to buy token during preSale time with USDC => for web3 use
    function buyTokenUSDC(uint256 amount, address _refAddress) public {
        require(_refAddress != msg.sender, "can't ref yourself");
        require(!isPresaleEnded, "Presale ended!");
        require(presaleStatus, " Presale is Paused, check back later");
        if (!isExist[msg.sender]) {
            isExist[msg.sender] = true;
            uniqueBuyers++;
            UsersAddresses.push(msg.sender);
        }
        USDC.transferFrom(msg.sender, address(this), amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount, currentStage);
        require(
            soldToken + numberOfTokens <=
                tokensToSell,
            "Phase Limit Reached"
        );
        if (referral[msg.sender] == address(0) && isExist[_refAddress]) {
            referral[msg.sender] = _refAddress;
            referralCount[_refAddress] += 1;
            users[_refAddress].refReward +=
                (numberOfTokens * RefRewardPercent) /
                percentDivider;
        }
        soldToken = soldToken + numberOfTokens;
        amountRaisedUSDC = amountRaisedUSDC + amount;

        users[msg.sender].usdc_balance += amount;
        users[msg.sender].claimAbleAmount =
            users[msg.sender].claimAbleAmount +
            numberOfTokens;
    }

    function getPhaseDetail(uint256 phaseInd)
        external
        view
        returns (
            uint256 priceUsd
        )
    {
        Phase memory phase = phases[phaseInd];
        return (
            phase.tokenPerUsdPrice
        );
    }

    function setPresaleStatus(bool _status) external onlyOwner {
        presaleStatus = _status;
    }

    function endPresale() external onlyOwner {
        require(!isPresaleEnded, "Already ended");
        isPresaleEnded = true;
        vestingStartTime = block.timestamp;
    }

    // to check number of token for given ETH
    function nativeToToken(uint256 _amount, uint256 phaseId)
        public
        view
        returns (uint256)
    {
        uint256 ethToUsd = (_amount * (getLatestPrice())) / (1 ether);
        uint256 numberOfTokens = (ethToUsd * phases[phaseId].tokenPerUsdPrice) /
            (1e8);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function usdtToToken(uint256 _amount, uint256 phaseId)
        public
        view
        returns (uint256)
    {
        uint256 numberOfTokens = (_amount * phases[phaseId].tokenPerUsdPrice) /
            (1e6);
        return numberOfTokens;
    }

    function updateInfos(
        uint256 _sold,
        uint256 _raised,
        uint256 _raisedInUsdt
    ) external onlyOwner {
        soldToken = _sold;
        amountRaised = _raised;
        amountRaisedUSDT = _raisedInUsdt;
    }

    //change tokens for buy
    //change tokens for buy
    function updateStableTokens(IERC20 _USDT, IERC20 _USDC) external onlyOwner {
        USDT = IERC20(_USDT);
        USDC = IERC20(_USDC);
    }

    // to withdraw funds for liquidity
    function initiateTransfer(uint256 _value) external onlyOwner {
        fundReceiver.transfer(_value);
    }

    function totalUsersCount() external view returns (uint256) {
        return UsersAddresses.length;
    }

    // to withdraw funds for liquidity
    function changeFundReciever(address _addr) external onlyOwner {
        fundReceiver = payable(_addr);
    }

    // to withdraw funds for liquidity
    function updatePriceFeed(AggregatorV3Interface _priceFeed)
        external
        onlyOwner
    {
        priceFeed = _priceFeed;
    }

    // funtion is used to change the stage of presale
    function setCurrentStage(uint256 _stageNum) public onlyOwner {
        currentStage = _stageNum;
    }

    // to withdraw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(fundReceiver, _value);
    }
        function changeRefRewardPercent(uint256 _per) public onlyOwner {
        RefRewardPercent = _per;
    }
}