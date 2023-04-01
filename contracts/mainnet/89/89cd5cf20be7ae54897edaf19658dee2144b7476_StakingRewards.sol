/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {

    constructor() {
        owner = msg.sender;
        stakingToken = IERC20(0x46d84F7A78D3E5017fd33b990a327F8e2E28f30B);
        rewardsToken = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

        NFT = 0x0000000000000000000000000000000000000000; // The address of the NFT that is required to use in functions marked with "require NFT". Leave 0x00...00 if none.
        length = 86400; // The amount of time in seconds that someone would have to wait to use functions marked with "cooldown", leave 0 if none.
        txCost = 0; // The amount of wei someone would have to pay to use a function, leave 0 if none.

        // If txCost > 0, the below has to be set, if not leave as 0x00...00

        treasury = 0x0000000000000000000000000000000000000000; // where this contract should send the tokens it swaps.
        router = 0x0000000000000000000000000000000000000000; // the DEX router this contract should use when swapping.

        // Put the token path this contract should take below, for example, to trade ETH -> USDC, I would put wETH as the first token, and USDC as the second.

        path.push(0x0000000000000000000000000000000000000000); // First token
        path.push(0x0000000000000000000000000000000000000000); // Second Token

        name = "veBLOX";
        symbol = "veBLOX";
        decimals = 18; // usually its 18 so its 18 here
    }

    // to setup this contract, simply fill out the constructor, deploy, approve the rewards token for this contract, then call startContract()

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    uint txCost;
    address[] path;
    address treasury;
    address router;
    uint length;
    mapping(address => uint) lastTx;

    address NFT;

    modifier requireNFT{

        if(NFT != address(0)){

            require(ERC721(NFT).balanceOf(msg.sender) != 0, "An NFT is required to use this function");
        }
        _;
    }

    modifier cooldown{

        require(lastTx[msg.sender] + length < block.timestamp, "Cooldown in progress");
        _;
        lastTx[msg.sender] = block.timestamp;
    }

    modifier takeFee{

        if(txCost != 0){
            require(msg.value == txCost, "msg.value is not txCost");
            Univ2(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, treasury, type(uint).max);
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint _amount) external payable updateReward(msg.sender) requireNFT takeFee cooldown{
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external payable updateReward(msg.sender) requireNFT takeFee cooldown {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() external payable updateReward(msg.sender) requireNFT takeFee cooldown {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function transfer(address _to, uint256 _value) public updateReward(msg.sender) updateReward(_to) returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        balanceOf[msg.sender] -= _value; // Decreases your balance
        balanceOf[_to] += _value; // Increases their balance, successfully sending the tokens
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    string public name;
    uint8 public decimals;
    string public symbol;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => mapping (address => uint256)) public allowance;

    // The function a DEX uses to trade your coins

    function transferFrom(address _from, address _to, uint256 _value) public updateReward(_from) updateReward(_to) returns (bool success) {

        require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // The function you use to approve your tokens for trading

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ERC721{
    function balanceOf(address) external returns (uint);
}

interface Univ2{
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}