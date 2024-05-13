/**
 *Submitted for verification at Arbiscan.io on 2024-05-12
*/

pragma solidity ^0.8.16;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract RevShareStake is Ownable {
    mapping(address => bool) public staked;
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public stakeStartTime;

    uint256 public totalEthDeposited = 0;

    uint256 public timeLock = 7 days;

    IERC20 public stakeToken = IERC20(0x1cce00E56619dcecE0fA43C80000987A46AB4e51);

    uint256 public totalTokens = 0;

    uint256 public profitPerShare_;

    mapping(address => uint256) public payoutsTo_;

    uint256 internal constant magnitude = 2 ** 64;

    receive() external payable {
        profitPerShare_ += (msg.value * magnitude) / totalTokens;
        totalEthDeposited += msg.value;
    }

    function deposit() public payable {
        profitPerShare_ += (msg.value * magnitude) / totalTokens;
        totalEthDeposited += msg.value;
    }

    function stakeTokens(uint amount) public {
        stakeToken.transferFrom(msg.sender, address(this), amount);

        uint256 currentDivs = getDividends(msg.sender);

        tokenBalanceLedger_[msg.sender] += amount;
        staked[msg.sender] = true;

        totalTokens += amount;

        stakeStartTime[msg.sender] = block.timestamp;

        payoutsTo_[msg.sender] += (getDividends(msg.sender) - currentDivs);
    }

    function withdrawDividends() public {
        uint256 myDivs = getDividends(msg.sender);

        payoutsTo_[msg.sender] += myDivs;

        payable(msg.sender).transfer(myDivs);
    }

    function exitFromStakingPool() public {
        require(canExit(msg.sender), "Staking time is not over.");

        withdrawDividends();

        stakeToken.transfer(msg.sender, tokenBalanceLedger_[msg.sender]);

        totalTokens -= tokenBalanceLedger_[msg.sender];
        tokenBalanceLedger_[msg.sender] = 0;
        staked[msg.sender] = false;
        payoutsTo_[msg.sender] = 0;
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        stakeToken = IERC20(tokenAddress);
    }

    function changeTimeLockTime(uint256 timeInDays) public onlyOwner {
        require(timeInDays <= 15 days, "Maximum time lock is 15 days");

        timeLock = timeInDays;
    }

    function canExit(address user) public view returns (bool) {
        uint256 startTime = stakeStartTime[user];
        uint256 endTime = block.timestamp;

        uint256 timeStaked = endTime - startTime;

        if (timeStaked >= timeLock) {
            return true;
        } else {
            return false;
        }
    }

    function getDividends(address user) public view returns (uint256) {
        uint256 allDivs = (tokenBalanceLedger_[user] * profitPerShare_) /
            magnitude;

        uint256 profit = allDivs - payoutsTo_[user];

        return profit;
    }

    function getTokenBalance(address user) public view returns (uint256) {
        return tokenBalanceLedger_[user];
    }

    function getTotalEthBalance() public view returns (uint256) {
        return address(this).balance;
    }
}