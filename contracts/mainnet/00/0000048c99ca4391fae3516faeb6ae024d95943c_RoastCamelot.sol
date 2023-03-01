/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
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

contract RoastCamelot is Ownable {
    mapping(address => uint256) private _userPosition;
    mapping(address => uint256) private _userInterestRate;
    mapping(address => uint256) private _userDepositTime;
    mapping(address => uint256) private _userEarnedInterest;
    mapping(address => uint256) private _userInvitationRewards;

    uint256 private DECIMAL = 1e10;

    address private _devWallet;

    uint256 private _devFee = (10 * DECIMAL) / 100;
    uint256 private _refRate = (10 * DECIMAL) / 100;
    uint256 private _defaultDailyAPR = (10 * DECIMAL) / 100;
    uint256 private _defaultInterestRatePerSecond;

    uint256 public launchTime = 1900000000;

    constructor() {
        _defaultInterestRatePerSecond = _defaultDailyAPR / 86400;
        _devWallet = msg.sender;
    }

    function deposit(address ref) public payable {
        require(block.timestamp > launchTime, "Not launched yet");
        require(msg.value != 0, "No deposit value found");
        require(
            _userPosition[msg.sender] == 0,
            "Each wallet can only participate once."
        );
        //msg.value  wei;
        uint256 value = msg.value;
        uint256 devFee = (value * _devFee) / DECIMAL;
        uint256 refReward = (value * _refRate) / DECIMAL;

        payable(_devWallet).transfer(devFee);

        if (ref != address(0)) {
            if (_userPosition[ref] > 0) {
                _userInvitationRewards[ref] += refReward;
            }
        }

        _userPosition[msg.sender] += value;
        _userDepositTime[msg.sender] = block.timestamp;
        _userInterestRate[msg.sender] = _defaultDailyAPR;
    }

    function interestToPosition() public {
        require(block.timestamp > launchTime, "Not launched yet");
        require(
            _userPosition[msg.sender] > 0,
            "No positions held by this address."
        );
        _calcInterest(msg.sender);
        require(_userEarnedInterest[msg.sender] > 0, "No earned interests.");

        uint256 interest = _userEarnedInterest[msg.sender];
        uint256 devFee = interest / 10;
        payable(_devWallet).transfer(devFee);

        if (
            (_userEarnedInterest[msg.sender] * 100) /
            _userPosition[msg.sender] >=
            10
        ) {
            _incrInterestRate(msg.sender);
        }

        _userPosition[msg.sender] += interest;
        _userEarnedInterest[msg.sender] = 0;
    }

    function withdraw() public {
        require(block.timestamp > launchTime, "Not launched yet");
        require(
            _userPosition[msg.sender] > 0,
            "No positions held by this address."
        );
        _calcInterest(msg.sender);
        require(_userEarnedInterest[msg.sender] > 0, "No earned interests.");
        uint256 interest = _userEarnedInterest[msg.sender];
        _userEarnedInterest[msg.sender] = 0;
        payable(msg.sender).transfer(interest);
        _decrInterestRate(msg.sender);
    }

    function withdrawInvitationRewards() public {
        require(block.timestamp > launchTime, "Not launched yet");
        require(
            _userPosition[msg.sender] > 0,
            "No positions held by this address."
        );
        require(
            _userInvitationRewards[msg.sender] > 0,
            "No invitation rewards held by this address."
        );
        uint256 rewards = _userInvitationRewards[msg.sender];
        _userInvitationRewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewards);
    }

    function getPosition(address user) public view returns (uint256) {
        return _userPosition[user];
    }

    function getWithdrawableAmount(address user) public view returns (uint256) {
        uint256 interestPeriod = block.timestamp - _userDepositTime[user];
        uint256 estimateInterest = (_userPosition[user] *
        _getInterestRatePerSecond(user) *
        interestPeriod) / DECIMAL;
        return estimateInterest;
    }

    function getInterestRate(address user) public view returns (uint256) {
        if (_userInterestRate[user] == 0) {
            return _defaultDailyAPR;
        }
        return _userInterestRate[user];
    }

    function getInvitationRewards(address user) public view returns (uint256) {
        return _userInvitationRewards[user];
    }

    function setLaunchTime(uint256 time) public onlyOwner {
        launchTime = time;
    }

    function setDevFee(uint256 rate) public onlyOwner {
        require(rate <= 30, 'WE WILL NEVER CHEAT ON YOU');
        _devFee = (rate * DECIMAL) / 100;
    }

    function setRefRate(uint256 rate) public onlyOwner {
        require(rate <= 30);
        _refRate = (rate * DECIMAL) / 100;
    }

    function setDevWallet(address wallet) public onlyOwner {
        _devWallet = wallet;
    }

    function setAPR(uint256 rate) public onlyOwner {
        _defaultDailyAPR = (rate * DECIMAL) / 100;
        _defaultInterestRatePerSecond = _defaultDailyAPR / 86400;
    }

    function _calcInterest(address user) internal {
        uint256 earnedInterest = getWithdrawableAmount(user);
        _userEarnedInterest[user] += earnedInterest;
        _userDepositTime[msg.sender] = block.timestamp;
    }

    function _incrInterestRate(address user) internal {
        uint256 newInterestRate = (_userInterestRate[user] * 102) / 100;
        _userInterestRate[user] = newInterestRate;
    }

    function _decrInterestRate(address user) internal {
        uint256 newInterestRate = (_userInterestRate[user] * 80) / 100;
        _userInterestRate[user] = newInterestRate;
    }

    function _getInterestRatePerSecond(address user) internal view returns (uint256) {
        return _userInterestRate[user] / 86400;
    }
}