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
    uint256 public ethPriceInUsd;

    mapping(address => Users) public userPrivateSaleDetails;
    mapping(address => uint256) public numberOfRef;
    mapping(address => bool) public isValidRefAddress;
    mapping(address => bool) public alreadyBoughtToken;

    event Received(address, uint256);
    event TokensBought(address, uint256);
    event OwnershipTransferred(address);
    event SetEndTime(address, uint256);
    event SetStartTime(address, uint256);
    event SetBuyPrice(address, uint256);
    event SetEthPrice(address, uint256);


    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner");
        _;
    }

    modifier onlyEnoughFunds() {
        uint256 amount = 15 ether;
        uint256 requireCoin = (amount) * (1 ether / ethPriceInUsd); 
        require(msg.value >= requireCoin, "not enough funds!");
        _;
    }

    modifier onlyNewBuyer(){
        require(!alreadyBoughtToken[msg.sender], "user already bought tokens");
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

    function setEthPrice(uint256 price) external onlyOwner {
        // must be in INT 400, 310, 311,
        ethPriceInUsd = price;
        emit SetEthPrice(msg.sender, price);
    }

   
    function setBuyUnitPrice(uint256 price) external onlyOwner {
        // must be in INT eg. 0.95 => 95, 1.20 => 120
        buyPrice = price;
        emit SetBuyPrice(msg.sender, price);
    }

    // BUY TOKEN & Referral Reward
    function buyTokenWithUsdt(
        address refAddress
    ) external payable onlyNewBuyer {
        uint256 amount = 15 ether;
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice) / 100;
        // uint256 tokens = amount;

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished or stopped!");

        require(
            ORBIXADDRESS.balanceOf(address(this)) >= amount,
            "Not enough balance on contract"
        );
        if (!isValidRefAddress[msg.sender]){
            isValidRefAddress[msg.sender] = true;
        }
        
        if(isValidRefAddress[refAddress] && refAddress != msg.sender){
            numberOfRef[refAddress]++;
        }
        alreadyBoughtToken[msg.sender] = true;
        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: amount , //in wei
            purchaseTime: block.timestamp
        });

        require(
            USDTADDRESS.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            ORBIXADDRESS.transfer(msg.sender, amount),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, amount);
    }

    function buyTokenWithBusd(
        address refAddress
    ) external payable onlyNewBuyer{
        uint256 amount = 15 ether;
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice) / 100;

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished");
        require(
            ORBIXADDRESS.balanceOf(address(this)) >= amount,
            "Not enough balance on contract"
        );

        if (!isValidRefAddress[msg.sender]){
            isValidRefAddress[msg.sender] = true;
        }
        
        if(isValidRefAddress[refAddress] && refAddress != msg.sender){
            numberOfRef[refAddress]++;
        }
        alreadyBoughtToken[msg.sender] = true;
        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: amount, //in wei
            purchaseTime: block.timestamp
        });

        require(
            BUSDADDRESS.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            ORBIXADDRESS.transfer(msg.sender, amount),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, amount);
    }

    function buyTokenWithEth(
        address refAddress
    ) external payable onlyNewBuyer onlyEnoughFunds{
        uint256 amount = 15 ether;
        require(msg.value > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        require(ethPriceInUsd != 0, "eth Price not set");
        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet");
        require(block.timestamp < endTime, "Private Sale finished");
        require(
            ORBIXADDRESS.balanceOf(address(this)) >= amount,
            "Not enough balance on contract"
        );

        if (!isValidRefAddress[msg.sender]){
            isValidRefAddress[msg.sender] = true;
        }
        
        if(isValidRefAddress[refAddress] && refAddress != msg.sender){
            numberOfRef[refAddress]++;
        }
        alreadyBoughtToken[msg.sender] = true;

        userPrivateSaleDetails[msg.sender] = Users({
            tokenBuy: amount, //in wei
            purchaseTime: block.timestamp
        });

        require(
            ORBIXADDRESS.transfer(msg.sender, amount),
            "transfer token to user failed!"
        );
        emit TokensBought(msg.sender, amount);
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

    // Owner ETH Withdraw
    function withdrawETH() external onlyOwner returns (bool) {
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

    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}