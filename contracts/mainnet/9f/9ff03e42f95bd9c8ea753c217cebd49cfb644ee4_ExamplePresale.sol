/**
 *Submitted for verification at Arbiscan on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


contract ExamplePresale is Ownable {
    uint256 public constant HARD_CAP = 634 ether;
    uint256 public constant SOFT_CAP = 16 ether;
    uint256 public constant MAX_PURCHASE = 1000000 * 1000000000000000000; //maximum of 1million PLACE per presale participant
    uint256 public constant TOTAL_TOKENS_SOLD = 20000000 * 1000000000000000000; //total tokens allocated for the presale: 20 million PLACE

    enum Stage {A, B, C, D}
    Stage public currentStage = Stage.A;

    struct StageInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 tokensSold;
        uint256 maxTokens;
        uint256 tokenPrice;
        bool whitelistEnabled;
    }

    mapping(Stage => StageInfo) public stageInfo;
    mapping(address => bool) public stageAWhitelist;
    mapping(address => uint256) public userTokenPurchases;
    mapping(address => uint256) public userEthDeposits;

    IERC20 public exampleToken;
    uint256 public mainStartTime;
    uint256 public mainEndTime;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public tokensSold;
    uint256 public ethCollected;

    // Vesting related variables
    uint256 public constant VESTING_DURATION = 10 days;
    uint256 public constant VESTING_PERCENTAGE = 10;
    mapping(address => uint256) public userVestedTokens;
    mapping(address => uint256) public userLastVestingClaim;
    mapping(address => uint256) public userVestingPeriodsLeft;

    bool public withdrawnUnsold = false ;


     // Set up the stage information
    constructor(address _exampleToken, uint256 _setStartTime) {
        exampleToken = IERC20(_exampleToken);

        mainStartTime = _setStartTime;
        mainEndTime = mainStartTime + 40 days;

        stageInfo[Stage.A] = StageInfo({
            startTime: mainStartTime,
            endTime: mainStartTime + 10 days,
            tokensSold: 0,
            maxTokens: 2000000 * 1000000000000000000,
            tokenPrice: 0.00002 ether,
            whitelistEnabled: true
        });

        stageInfo[Stage.B] = StageInfo({
            startTime: mainStartTime + 10 days,
            endTime: mainStartTime + 20 days,
            tokensSold: 0,
            maxTokens: 6000000 * 1000000000000000000,
            tokenPrice: 0.0000265 ether,
            whitelistEnabled: false
        });

        stageInfo[Stage.C] = StageInfo({
            startTime: mainStartTime + 20 days,
            endTime: mainStartTime + 30 days,
            tokensSold: 0,
            maxTokens: 6000000 * 1000000000000000000,
            tokenPrice: 0.000033 ether,
            whitelistEnabled: false
        });

        stageInfo[Stage.D] = StageInfo({
            startTime: mainStartTime + 30 days,
            endTime: mainEndTime,
            tokensSold: 0,
            maxTokens: 6000000 * 1000000000000000000,
            tokenPrice: 0.0000395 ether,
            whitelistEnabled: false
        });
        
        
    }

    function addToWhitelist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            stageAWhitelist[users[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            stageAWhitelist[users[i]] = false;
        }
    }

    function claimRefund() external {
        require(block.timestamp > mainEndTime, "Presale is still active");
        require(ethCollected < SOFT_CAP, "Softcap reached, no refunds");
        uint256 refundAmount = userEthDeposits[msg.sender];
        require(refundAmount > 0, "No refund available");
        payable(msg.sender).transfer(refundAmount);
         userEthDeposits[msg.sender] = 0;
    }

    function updateStage() internal {
    if (currentStage == Stage.D) {
        return;  // Already in the final stage, no need to update
    }

    uint256 currentTime = block.timestamp;

    // Check if the current stage has ended
    if (currentTime > stageInfo[currentStage].endTime) {
        // Check if there are more stages after the current one
        if (currentStage == Stage.C) {
            currentStage = Stage.D;  // Transition to the final stage
        } else {
            currentStage = Stage(uint256(currentStage) + 1);  // Transition to the next stage
        }
    }
}


    function buyTokens() external payable {
        updateStage();
        require(block.timestamp >= mainStartTime && block.timestamp <=  mainEndTime, "Presale is not active");
        if (currentStage == Stage.A) {
            require(stageAWhitelist[msg.sender], "Not whitelisted for Stage A");
        }
        require(stageInfo[currentStage].tokensSold < stageInfo[currentStage].maxTokens, "Stage is sold out");
        require(msg.value > 0, "No ETH sent");
        require(msg.value % stageInfo[currentStage].tokenPrice == 0, "Sent ETH amount is not divisible by token price");

        uint256 tokensToBuy =(msg.value / stageInfo[currentStage].tokenPrice) * 1000000000000000000;
         uint256 tokensLeftInStage = stageInfo[currentStage].maxTokens - stageInfo[currentStage].tokensSold;
       

require(tokensToBuy <= tokensLeftInStage, "Exeeds available tokens for this stage");
uint256 newTotalPurchase = userTokenPurchases[msg.sender] + tokensToBuy;
         require(newTotalPurchase <= MAX_PURCHASE, "Exceeds maximum purchase per user");
        stageInfo[currentStage].tokensSold += tokensToBuy;
        userTokenPurchases[msg.sender] = newTotalPurchase;
        userEthDeposits[msg.sender] += msg.value;
        tokensSold += tokensToBuy;
        ethCollected += msg.value;
userVestingPeriodsLeft[msg.sender] = 10;
       
    }

    function claimVestedTokens() external {
        require(block.timestamp > mainEndTime, "Presale is still active");
        require(ethCollected >= SOFT_CAP, "Softcap not reached, get your refund");
        require(userVestedTokens[msg.sender] < userTokenPurchases[msg.sender], "No tokens left, you already finished withdrawing vested Tokens");
        uint256 elapsedTime = block.timestamp - mainEndTime;
        uint256 vestingPeriodsPassed = elapsedTime / VESTING_DURATION;
        uint256 totalVestedTokens = (userTokenPurchases[msg.sender] * vestingPeriodsPassed * VESTING_PERCENTAGE) / 100;
        uint256 tokensToClaim = totalVestedTokens - userVestedTokens[msg.sender];

        require(tokensToClaim > 0, "No tokens available to claim");
        if(tokensToClaim + userVestedTokens[msg.sender] > userTokenPurchases[msg.sender]) {
            tokensToClaim = userTokenPurchases[msg.sender]-userVestedTokens[msg.sender];
            userVestedTokens[msg.sender] += tokensToClaim;
        exampleToken.transfer(msg.sender, tokensToClaim);
        } else {
        userVestedTokens[msg.sender] += tokensToClaim;
        exampleToken.transfer(msg.sender, tokensToClaim);
    }}


    function withdrawEth() external onlyOwner {
        require(ethCollected >= SOFT_CAP, "Softcap not reached");
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() external onlyOwner {
        require(block.timestamp > mainEndTime, "Presale is still active");
        require(ethCollected >= SOFT_CAP, "Softcap not reached. Need to withdraw all");
        require(!withdrawnUnsold,"Unsold Tokens already withdrawn");
        uint256 unsoldTokens = TOTAL_TOKENS_SOLD - tokensSold;
        withdrawnUnsold = true ;
        exampleToken.transfer(owner(), unsoldTokens);
    }

    function withdrawAll()external onlyOwner {
      require(block.timestamp > mainEndTime, "Presale is still active");
    require(ethCollected < SOFT_CAP, "Softcap reached. Only Unsold Tokens are withdrawable");
    exampleToken.transfer(owner(), address(this).balance);
    }
}
 //[0xd79fCD42f1cA2832dBd75aaB43E3Fbd8CDbc49d5,0xebDd474f45eEADcAaa1fbF98Fd221446e2854DB4]