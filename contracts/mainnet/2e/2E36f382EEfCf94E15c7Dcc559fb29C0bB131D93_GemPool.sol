/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: not owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'e0');
        (bool success,) = recipient.call{value : amount}('');
        require(success, 'e1');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'e0');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'e0');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'e0');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'e0');
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: BEP20 operation did not succeed");
        }
    }
}

interface CakeToken {
    function mint(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

contract GemPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public chefManager;
    address public devAddress;
    bool public hasUserLimit;
    bool public isInitialized;
    uint256 public accCakePerShare;
    uint256 public bonusEndBlock;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public poolLimitPerUser;
    uint256 public rewardPerBlock;
    uint256 public precisionFactor;
    uint256 public stakingFee = 0;
    uint256 public withdrawFee = 0;
    uint256 public stakingStockLength;

    IERC20 public stakedToken;
    CakeToken public rewardToken;

    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public pending_list;
    mapping(address => uint256) public staking_first_time;
    mapping(address => uint256) public staking_last_time;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor() {
        chefManager = _msgSender();
        devAddress = _msgSender();
    }

    function initialize(
        IERC20 _stakedToken,
        CakeToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser
    ) external {
        require(!isInitialized, "Already initialized");
        require(_msgSender() == chefManager, "Not factory");

        isInitialized = true;
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }
        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must less than 30");
        precisionFactor = uint256(10 ** (uint256(30) - decimalsRewardToken));
        lastRewardBlock = startBlock;
    }

    function poolState() public view returns (bool) {
        return block.number >= startBlock && block.number < bonusEndBlock;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(poolState(), "not open");
        
        address account = _msgSender();
        UserInfo storage user = userInfo[account];
        if (staking_first_time[account] == 0) {
            staking_first_time[account] = block.timestamp;
        }
        staking_last_time[account] = block.timestamp;

        uint256 stakingFeeAmout = _amount * stakingFee / 100;
        uint256 leftAmout = _amount - stakingFeeAmout;
        if (hasUserLimit) {
            require(leftAmout + user.amount <= poolLimitPerUser, "above limit");
        }
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount * accCakePerShare / precisionFactor - user.rewardDebt;
            if (pending > 0) {
                pending_list[account] = pending_list[account] + pending;
            }
        }
        if (_amount > 0) {
            user.amount = user.amount + leftAmout;
            stakedToken.safeTransferFrom(account, address(this), _amount);
            if (stakingFeeAmout > 0) {
                stakedToken.safeTransfer(devAddress, stakingFeeAmout);
            }
        }
        user.rewardDebt = user.amount * accCakePerShare / precisionFactor;
        emit Deposit(account, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        address account = _msgSender();
        UserInfo storage user = userInfo[account];
        require(user.amount >= _amount, "no more");
        _updatePool();

        uint256 pending = user.amount * accCakePerShare / precisionFactor - user.rewardDebt;
        if (pending > 0) {
            pending_list[account] = pending_list[account] + pending;
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            uint256 withdrawAmount = _amount * withdrawFee / 100;
            uint256 leftAmount = _amount - withdrawAmount;
            if (withdrawAmount > 0) {
                stakedToken.safeTransfer(devAddress, withdrawAmount);
            }
            stakedToken.safeTransfer(account, leftAmount);
        }
        user.rewardDebt = user.amount * accCakePerShare / precisionFactor;
        emit Withdraw(account, _amount);
    }

    function emergencyWithdraw() external nonReentrant {
        address account = _msgSender();
        UserInfo storage user = userInfo[account];
        require(user.amount > 0, "no deposit");

        uint256 fee = user.amount * withdrawFee / 100;
        uint256 leftAmount = user.amount - fee;
        if (fee > 0) {
            stakedToken.safeTransfer(devAddress, fee);
        }
        stakedToken.safeTransfer(account, leftAmount);
        user.amount = 0;
        user.rewardDebt = 0;
        pending_list[account] = 0;
        emit EmergencyWithdraw(account, user.amount);
    }

    function canHarvest(address _user) public view returns (bool) {
        return
            block.number >= startBlock &&
            block.timestamp > staking_last_time[_user] + stakingStockLength;
    }

    function harvest() public nonReentrant isHuman {
        address account = _msgSender();
        require(canHarvest(account), 'time limit');

        UserInfo storage user = userInfo[account];
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount * accCakePerShare / precisionFactor - user.rewardDebt;
            if (pending > 0) {
                pending_list[account] = pending_list[account] + pending;
            }
        }
        user.rewardDebt = user.amount * accCakePerShare / precisionFactor;
        uint256 reward = pending_list[account];
        require(reward > 0, 'no rewards');

        pending_list[account] = 0;
        safeCakeTransfer(account, reward);
        emit Harvest(account, reward);
    }

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        safeCakeTransfer(_msgSender(), _amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        IERC20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function setFees(uint256 _stakingFee, uint256 _withdrawFee) public onlyOwner {
        require(_stakingFee < 50 && _withdrawFee < 50, 'too high');
        stakingFee = _stakingFee;
        withdrawFee = _withdrawFee;
    }

    function setStakingStocklength(uint256 _length) public onlyOwner {
        stakingStockLength = _length;
    }

    function updatePoolLimit(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        if (_hasUserLimit) {
            require(_poolLimitPerUser > 0, "zero");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            poolLimitPerUser = 0;
        }
        hasUserLimit = _hasUserLimit;
        emit NewPoolLimit(poolLimitPerUser);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        lastRewardBlock = startBlock;
        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 pending = pending_list[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accCakePerShare + (cakeReward * precisionFactor / stakedTokenSupply);
            return pending + (user.amount * adjustedTokenPerShare / precisionFactor - user.rewardDebt);
        } else {
            return pending + (user.amount * accCakePerShare / precisionFactor - user.rewardDebt);
        }
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier * rewardPerBlock;
        if (cakeReward > 0) {
            rewardToken.mint(address(this), cakeReward);
        }
        accCakePerShare = accCakePerShare + (cakeReward * precisionFactor / stakedTokenSupply);
        lastRewardBlock = block.number;
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function safeCakeTransfer(address _to, uint256 _amount) internal {
        uint256 cakeBal = rewardToken.balanceOf(address(this));
        if (_amount > cakeBal) {
            rewardToken.transfer(_to, cakeBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    function setdev(address _devaddr) public {
        require(_msgSender() == devAddress || _msgSender() == owner(), "cannot");
        devAddress = _devaddr;
    }
}