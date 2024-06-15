/**
 *Submitted for verification at Arbiscan.io on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
            uint256 stTokenPresaleedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 stTokenPresaleedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Presale is Ownable {
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public claimableBalances;
    mapping(address => uint256) public totalSales;

    uint256 public priceDecimal = 3;
    uint256[] public pricePerUSDT = [
        300,
        350,
        400
    ];
    uint256[] public tokenLimit = [
        1260000000000000000000000,
        1260000000000000000000000,
        1680000000000000000000000
    ];
    uint256[] public tokenSold = [
        0,
        0,
        0
    ];
    uint256 public minBuyUSDT = 50000000000000000000;
    uint256 public maxBuyUSDT = 10000000000000000000000;

    IERC20 public TokenPresale;
    IERC20 public USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    uint256 public stage = 0;

    bool public isPresaleOpen = true;
    bool public isClaimable = false;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        );
    }

    function getCurrentPresaleInfo() public view returns (uint256, bool, bool, uint256, uint256, uint256, uint256, uint256) {
        return (
            stage,
            isPresaleOpen,
            isClaimable,
            pricePerUSDT[stage],
            minBuyUSDT,
            maxBuyUSDT,
            tokenSold[stage],
            tokenLimit[stage]
        );
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price / 100000000;
    }

    function editPriceAtStage(uint256 _stage, uint256 _newPrice) public onlyOwner {
        require(stage < pricePerUSDT.length, "Index out of bounds");
        pricePerUSDT[_stage] = _newPrice;
    }

    function editTokenLimit(uint256 _stage, uint256 _newLimit) public onlyOwner {
        require(stage < tokenLimit.length, "Index out of bounds");
        tokenLimit[_stage] = _newLimit;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        TokenPresale = IERC20(_tokenAddress);
    }

    function nextStage() public onlyOwner {
        require(stage < 2, "Index out of bounds");
        stage += 1;
    }

    function buyWithUSDT(uint256 usdtAmount, address referral) public {
        require(isPresaleOpen, "Presale closed");
        require(usdtAmount >= minBuyUSDT, "Minimum purchase amount has not been reached");
        require(usdtAmount <= maxBuyUSDT, "Exceeded maximum purchase amount"); 

        uint256 receivedTokens = (usdtAmount * 10 ** priceDecimal) / pricePerUSDT[stage];
        
        require(receivedTokens + tokenSold[stage] <= tokenLimit[stage], "Out of Tokens");

        tokenSold[stage] += receivedTokens;
        balances[msg.sender] += receivedTokens;
        claimableBalances[msg.sender] += receivedTokens * 2 / 100; // 2% of tokens

        uint256 amountToTransfer = usdtAmount;
        uint256 referralBonus = 0;

        if (referral != address(0) && referral != msg.sender) {
            referralBonus = usdtAmount * 5 / 100; // 5% bonus for the referral
            amountToTransfer = usdtAmount - referralBonus;
            totalSales[referral] += usdtAmount;
            USDT.transferFrom(msg.sender, referral , referralBonus);
        }

        USDT.transferFrom(msg.sender, owner(), amountToTransfer);
    }

    function buyWithNative(address referral) public payable {
        require(isPresaleOpen, "Presale end");

        int256 latestPrice = getLatestPrice();
        uint256 usdtAmount = msg.value * uint256(latestPrice);

        require(usdtAmount >= minBuyUSDT, "Minimum purchase amount has not been reached");
        require(usdtAmount <= maxBuyUSDT, "Exceeded maximum purchase amount"); 

        uint256 receivedTokens = (usdtAmount * 10 ** priceDecimal) / pricePerUSDT[stage];
        
        require(receivedTokens + tokenSold[stage] <= tokenLimit[stage], "Out of Tokens");

        tokenSold[stage] += receivedTokens;
        balances[msg.sender] += receivedTokens;
        claimableBalances[msg.sender] += receivedTokens * 2 / 100; // 2% of tokens

        uint256 amountToTransfer = msg.value;
        uint256 referralBonus = 0;

        if (referral != address(0) && referral != msg.sender) {
            referralBonus = msg.value * 5 / 100; // 5% bonus for the referral
            amountToTransfer = msg.value - referralBonus;
           
            address payable referralAdd = payable(referral);
            referralAdd.transfer(referralBonus);

            totalSales[referral] += usdtAmount;
        }

        address payable owner = payable(owner());
        owner.transfer(amountToTransfer);
    }

    function claimTokens() public {
        require(isClaimable, "Claim Not allowed at this moment");
        require(claimableBalances[msg.sender] > 0, "No tokens to claim");

        uint256 claimableBalance = claimableBalances[msg.sender];
        claimableBalances[msg.sender] = 0;

        require(
            TokenPresale.balanceOf(address(this)) >= claimableBalance,
            "Not enough tokens available"
        );

        require(
            TokenPresale.transfer(msg.sender, claimableBalance),
            "Token transfer failed"
        );
        
    }

    function endPresale(bool status) public onlyOwner {
        isPresaleOpen = status;
    }

    function setClaim(bool status) public onlyOwner {
        isClaimable = status;
    }

    function withdrawLeftover() external onlyOwner {
        uint256 balance = TokenPresale.balanceOf(address(this));
        require(balance > 0, "No token available");
        TokenPresale.transfer(owner(), balance);
    }

    function emergencyWithdrawToken(address _token, uint256 _value) public onlyOwner returns (bool ok) {
        return IERC20(_token).transfer(owner(),_value);
    }
}