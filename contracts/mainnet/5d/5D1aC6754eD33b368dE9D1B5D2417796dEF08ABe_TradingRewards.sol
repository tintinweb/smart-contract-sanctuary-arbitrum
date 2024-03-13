// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface xTIG {
    function feesGenerated(uint256, address) external view returns (uint256);
    function epochFeesGenerated(uint256) external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TradingRewards {

    event RewardsClaimed(address user, uint256 tigClaimed, uint256 usdtClaimed);
    event RewardsAdded(address owner, uint256 tigPerDay, uint256 usdtPerDay, uint256 duration, uint256 startAt);

    struct Rewards {
        uint256 tig;
        uint256 usdt;
    }

    uint256 public constant EPOCH_PERIOD = 1 days;

    IERC20 public tig;
    IERC20 public usdt;

    xTIG public xtig;
    uint256 public startEpoch;
    address public owner;

    mapping(uint256 => Rewards) public rewardsPerEpoch;
    mapping(address => uint256) public claimedEpochsPerUser;

    constructor(address _xtig) {
        xtig = xTIG(_xtig);
        startEpoch = currentEpoch()-1;
        owner = msg.sender;

        tig = IERC20(0x3A33473d7990a605a88ac72A78aD4EFC40a54ADB);
        usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    }

    function claimRewards() external {
        Rewards memory claimable = claimableRewards(msg.sender);
        if(claimable.tig == 0 && claimable.usdt == 0) return;

        claimedEpochsPerUser[msg.sender] = currentEpoch();

        tig.transfer(msg.sender, claimable.tig);
        usdt.transfer(msg.sender, claimable.usdt);

        emit RewardsClaimed(msg.sender, claimable.tig, claimable.usdt);
    }

    function claimableRewards(address user) public view returns(Rewards memory totalRewards) {
        uint256 _currentEpoch = currentEpoch();
        if(startEpoch > _currentEpoch) return Rewards(0, 0);
        if(claimedEpochsPerUser[user] == _currentEpoch) return Rewards(0, 0);

        uint start = claimedEpochsPerUser[user] < startEpoch ? startEpoch : claimedEpochsPerUser[user];

        Rewards memory _epochRewards;
        totalRewards = Rewards(0, 0);
        for (uint i=start; i<_currentEpoch; i++) {
            _epochRewards = getSharePerEpoch(i, user);
            totalRewards.tig += _epochRewards.tig;
            totalRewards.usdt += _epochRewards.usdt;
        }
    }

    function estimatedRewardsForCurrentEpoch(address _user) external view returns(Rewards memory epochRewards) {
        uint256 _epoch = currentEpoch();
        return getSharePerEpoch(_epoch, _user);
    }

    function getSharePerEpoch(uint256 epoch, address user) public view returns(Rewards memory epochRewards) {
        epochRewards = rewardsPerEpoch[epoch];
        uint256 _epochFees = xtig.epochFeesGenerated(epoch);
        uint256 _userFees = xtig.feesGenerated(epoch, user);
        epochRewards.tig = epochRewards.tig * _userFees / _epochFees;
        epochRewards.usdt = epochRewards.usdt * _userFees / _epochFees;
    }

    // duration is in epochs
    function addRewards(uint256 _tigPerDay, uint256 _usdtPerDay, uint256 duration, uint256 startAt) external onlyOwner() {
        require(startAt >= currentEpoch(), "Can't add to past epochs");

        tig.transferFrom(msg.sender, address(this), _tigPerDay * duration);
        usdt.transferFrom(msg.sender, address(this), _usdtPerDay * duration);

        for(uint i=startAt; i<duration+startAt; i++) {
            Rewards storage r = rewardsPerEpoch[i];
            require(r.tig == 0 && r.usdt == 0, "!override");
            r.tig = _tigPerDay;
            r.usdt = _usdtPerDay;
        }

        emit RewardsAdded(msg.sender, _tigPerDay, _usdtPerDay, duration, startAt);
    }

    function currentEpoch() public view returns(uint256 epoch) {
        epoch = block.timestamp / EPOCH_PERIOD;
    }

    function changeOwner(address _new) external onlyOwner() {
        owner = _new;
    }

    function recoverTokensFromEpochs(uint256 startAt, uint256 numberOfEpochs) external onlyOwner() {
        require(startAt >= currentEpoch(), "Cannot recover from past epochs");
        Rewards memory _epochRewards;
        for(uint i=startAt; i<numberOfEpochs+startAt; i++) {
            _epochRewards = rewardsPerEpoch[i];
            if (_epochRewards.tig == 0 && _epochRewards.usdt == 0) continue;
            delete rewardsPerEpoch[i];
            tig.transfer(msg.sender, _epochRewards.tig);
            usdt.transfer(msg.sender, _epochRewards.usdt);
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }
}