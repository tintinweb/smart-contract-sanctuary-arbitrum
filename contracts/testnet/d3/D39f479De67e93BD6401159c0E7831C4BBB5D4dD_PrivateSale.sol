/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract PrivateSale {
    struct Users {
        uint256 tokenBuy;
        uint256 purchaseTime;
    }

    address public owner;
    IERC20 public constant USDTADDRESS =
        IERC20(0xEE48096aBeBbe9D4Fc355fe111dA8aEA56008F1b);
    IERC20 public constant BUSDADDRESS =
        IERC20(0x8d63CAE589F639Ea75c7c5f68217cFaEFb736Ba2);
    IERC20 public constant ORBIXADDRESS =
        IERC20(0x5298fa5953DA82B34fa5b8abf333b47968F79C96);

    // IERC20 public constant USDTADDRESS =
    //     IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
    // IERC20 public constant BUSDADDRESS =
    //     IERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
    // IERC20 public constant ORBIXADDRESS =
    //     IERC20(0xf8e81D47203A594245E36C48e151709F0C19fBe8);

    uint256 public buyPrice;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public bnbPriceInUsd;
    uint256 public maxSpend;

    mapping(address => Users) public userPrivateSaleDetails;
    mapping(address => uint256) public totalTokenBuy;
    mapping(address => uint256) public numberOfRef;
    mapping(address => uint256) public totalSpend;

    event Received(address, uint256);
    event TokensBought(address, uint256);
    event OwnershipTransferred(address);
    event SetEndTime(address, uint256);
    event SetStartTime(address, uint256);
    event SetBuyPrice(address, uint256);
    event SetBnbPrice(address, uint256);
    event SetMaxBuy(address, uint256);

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner");
        _;
    }

    modifier onlyEnoughFunds(uint256 amount) {
        require(msg.value >= amount, "not enough funds!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setPrivatesaleStartTime(uint256 time) external onlyOwner {
        startTime = block.timestamp + time;
        emit SetStartTime(msg.sender, time);
    }

    function setPrivatesaleEndTime(uint256 time) external onlyOwner {
        endTime = block.timestamp + time;
        emit SetEndTime(msg.sender, time);
    }

    function setBnbPrice(uint256 price) external onlyOwner {
        // must be in INT 400, 310, 311,
        bnbPriceInUsd = price;
        emit SetBnbPrice(msg.sender, price);
    }

    function setMaxBuy(uint256 amount) external onlyOwner {
        uint256 maxBuyToken = amount * 1 ether;
        maxSpend = maxBuyToken;
        emit SetMaxBuy(msg.sender, amount);
    }

    function setBuyUnitPrice(uint256 price) external onlyOwner {
        // must be in INT eg. 0.95 => 95, 1.20 => 120
        buyPrice = price;
        emit SetBuyPrice(msg.sender, price);
    }

    // BUY TOKEN & Referral Reward
    function buyTokenWithUsdt(
        uint256 amount
    ) external payable {
        require(amount > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice * 1 ether) / 100;
        require(
            maxSpend >= totalSpend[msg.sender] + amountInUsd,
            "you can buy max 15$ coins!"
        );
        uint256 tokens = (amountInUsd * 100) / buyPrice;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished or stopped!");

        require(
            ORBIXADDRESS.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );
        totalSpend[msg.sender] = totalSpend[msg.sender] + amountInUsd;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: tokens , //in wei
            purchaseTime: block.timestamp
        });

        require(
            USDTADDRESS.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            ORBIXADDRESS.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, tokens);
    }

    function buyTokenWithBusd(
        uint256 amount
    ) external payable {
        require(amount > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice * 1 ether) / 100;
        require(
            maxSpend >= totalSpend[msg.sender] + amountInUsd,
            "you can buy max 15$ coins!"
        );
        uint256 tokens = ((amountInUsd * 100) / buyPrice);
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished");
        require(
            ORBIXADDRESS.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );

        totalSpend[msg.sender] = totalSpend[msg.sender] + amountInUsd;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: tokens, //in wei
            purchaseTime: block.timestamp
        });

        require(
            BUSDADDRESS.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            ORBIXADDRESS.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, tokens);
    }

    function buyTokenWithBnb(
        uint256 amount
    ) external payable onlyEnoughFunds(amount) {
        require(msg.value > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        require(bnbPriceInUsd != 0, "bnbPrice not set");
        uint256 tokens = (msg.value * bnbPriceInUsd * 100) / buyPrice;

        uint256 amountInUsd = msg.value * bnbPriceInUsd;

        require(
            maxSpend >= totalSpend[msg.sender] + amountInUsd,
            "you can buy max 15$ coins!"
        );
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished");
        require(
            ORBIXADDRESS.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );
        totalSpend[msg.sender] = totalSpend[msg.sender] + amountInUsd;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;

        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: tokens, //in wei
            purchaseTime: block.timestamp
        });

        require(
            ORBIXADDRESS.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );
        emit TokensBought(msg.sender, tokens);
    }

    // Owner Token Withdraw
    function withdrawTokenUsdt() external onlyOwner returns (bool) {
        require(
            USDTADDRESS.transfer(
                msg.sender,
                USDTADDRESS.balanceOf(address(this))
            ),
            "token withdraw fail!"
        );
        return true;
    }

    function withdrawTokenBusd() external onlyOwner returns (bool) {
        require(
            BUSDADDRESS.transfer(
                msg.sender,
                BUSDADDRESS.balanceOf(address(this))
            ),
            "token withdraw fail!"
        );
        return true;
    }

    function withdrawTokenOrbix() external onlyOwner returns (bool) {
        require(
            ORBIXADDRESS.transfer(
                msg.sender,
                ORBIXADDRESS.balanceOf(address(this))
            ),
            "token withdraw fail!"
        );
        return true;
    }

    // Owner BNB Withdraw
    function withdrawBNB() external onlyOwner returns (bool) {
        payable(address(msg.sender)).transfer(address(this).balance);
        return true;
    }

    // Ownership Transfer
    function transferOwnership(address to) external onlyOwner returns (bool) {
        require(to != address(0), "can't transfer at this address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }

    function buyersDetails(
        address buyer
    )
        external
        view
        returns (uint256 noOfTokensBought, uint256 noOfRef)
    {
        return (
            totalTokenBuy[buyer],
            numberOfRef[buyer]
        );
    }

    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}