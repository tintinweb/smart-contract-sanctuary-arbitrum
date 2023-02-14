/**
 *Submitted for verification at Arbiscan on 2023-02-13
*/

pragma solidity ^0.4.8;

contract LockerFactory {

    address[] public contracts;

    address private owner;

    address public rewardTokenAddress;

    uint public lockCounter = 0;

    uint public tokenRewardsPerDay = 1000 * 1e18;

    mapping(address => address []) public userLocks;

    IERC20 rewardToken;


    constructor(address _rewardTokenAddress){
        owner = msg.sender;
        rewardTokenAddress = _rewardTokenAddress;
        rewardToken = IERC20(rewardTokenAddress);
    }


    function getContractCount() public constant returns(uint contractCount){
        return contracts.length;
  }

  // Deploy a new Locker Contract

    function newTokenLocker(address _tokenAddress, uint _unlockTime, uint _amount) public returns(address newContract){
        require(_unlockTime > (now + 86400), "You must lock for at least one day.");
        IERC20 lockToken = IERC20(_tokenAddress);
        address thisTokenZero = lockToken.token0();
        address thisTokenOne = lockToken.token1();
        TokenLocker c = new TokenLocker(address(this), _tokenAddress, _unlockTime, msg.sender, rewardTokenAddress, _amount, thisTokenOne, thisTokenZero);
        contracts.push(c);
        rewardToken.addMinter(c);
        lockToken.transferFrom(msg.sender, c, _amount);
        userLocks[msg.sender].push(c);
        lockCounter += 1;
        return c;
  }





    function recoverStuckLockFunds(address _locker, address _asset){
        require(msg.sender == owner, "Only the team may recover funds incorrecly sent to the protocol. If you accidentally sent these funds, please contact us at https://davyjones.app to verify and recover them.");
        TokenLocker c = TokenLocker(_locker);
        c.recoverStuckFunds(_asset);
    }

    function recoverStuckFundsSelf(address _asset, address _recipient) public{
        require(msg.sender == owner, "Only the team may recover funds incorrecly sent to the protocol. If you accidentally sent these funds, please contact us at https://davyjones.app to verify and recover them.");
        IERC20 thisAsset = IERC20(_asset);
        uint _amount = thisAsset.balanceOf(address(this));
        thisAsset.transfer(_recipient, _amount);
    }

    function updateRewardRate(uint _amount) public {
        tokenRewardsPerDay = _amount * 1e18;
    }




}


contract TokenLocker {

    address public owner;
    address public tokenAddress;
    address public lockCreator;
    address public rewardTokenAddress;
    address public token0;
    address public token1;
    IERC20 token;
    IERC20 rewardToken;

    uint public tokenBalance;
    uint public unlockTime;
    uint public lockStart;
    

    LockerFactory lockerFactory;

    constructor(address _parentContract, address _tokenAddress, uint _unlockTime, address _lockCreator, address _rewardTokenAddress, uint _lockAmount, address _token0, address _token1) {
        owner = _parentContract;

        tokenAddress = _tokenAddress;
        rewardTokenAddress = _rewardTokenAddress;

        unlockTime = _unlockTime;
        lockCreator = _lockCreator;

        token = IERC20(tokenAddress);
        rewardToken = IERC20(rewardTokenAddress);

        lockerFactory = LockerFactory(owner);

        lockStart = now;

        tokenBalance = _lockAmount;

        token0 = _token0;
        token1 = _token1;

    }

    
    function depositToken(uint _amount) public {
        require(msg.sender == lockCreator, "You do not own this lock.");
        lockStart = now;
        token.transferFrom(msg.sender, address(this), _amount);
        tokenBalance += _amount;
    }

    function withdrawToken() public {
        require (now > unlockTime, "This lock has not unlocked yet.");
        require (msg.sender == lockCreator, "You do not have permission to unlock this lock.");
        token.transfer(msg.sender, tokenBalance);
        uint rewards = getUserRewards();
        rewardToken.mint(address(this), rewards);
        rewardToken.transfer(lockCreator, rewards);
        tokenBalance = 0;
    }

    function earlyWithdraw() public{
        require (msg.sender == lockCreator, "You do not have permission to unlock this lock.");
        uint penaltyAmount = tokenBalance / 5;
        uint returnAmount = (tokenBalance / 5) * 4;
        token.transfer(lockCreator, returnAmount);
        token.transfer(owner, penaltyAmount);
        tokenBalance = 0;
    }

    function recoverStuckFunds(address _asset) public {
        require(msg.sender == owner, "Only the Factory Contract may do this.");
        IERC20 thisAsset = IERC20(_asset);
        uint _amount = thisAsset.balanceOf(address(this));
        thisAsset.transfer(owner, _amount);
    }

    function getUserRewards() public view returns (uint _rewards){
        uint rewards;
        if (tokenBalance != 0){
            uint rewardRate = lockerFactory.tokenRewardsPerDay();
            rewards = (now - lockStart) * (rewardRate / 86400);
        } else{
            rewards = 0;
        }

        return rewards;
    }

    function extendLockTime(uint _newTime){
        require(msg.sender == lockCreator, "You do not own this lock.");
        require(_newTime > now, "You cannot set the unlock date to before the current time.");
        require(_newTime > unlockTime + 86400, "You must extend by at least one day.");
        unlockTime = _newTime;
    }

}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function addMinter(address account) public;

    function mint(address to, uint256 value) public returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    
}