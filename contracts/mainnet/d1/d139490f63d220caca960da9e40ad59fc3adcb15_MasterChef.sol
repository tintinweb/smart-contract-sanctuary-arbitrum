// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./XB.sol";

// MasterChef is the master of XB. He can make XB and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once XB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of XB
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accxbPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accxbPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. XB to distribute per second.
        uint256 lastRewardTimestamp;  // Last timestamp that XB distribution occurs.
        uint256 accxbPerShare;   // Accumulated XB per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The XB TOKEN!
    XB public xb;
    // Dev address.
    address public devaddr;
    // XB tokens created per second.
    uint256 public xbPerSec;
    // Deposit Fee address
    address public feeAddress1;
    address public feeAddress2;
    address public feeAddress3;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when xb mining starts.
    uint256 public startTimestamp = 1678291200;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress1(address indexed user, address indexed newAddress);
    event SetFeeAddress2(address indexed user, address indexed newAddress);
    event SetFeeAddress3(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 xbPerSec);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);

    constructor(
        XB _xb,
        address _devaddr,
        address _feeAddress1,
        address _feeAddress2,
        address _feeAddress3,
        uint256 _xbPerSec
    ) public {
        xb = _xb;
        devaddr = _devaddr;
        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;
        feeAddress3 = _feeAddress3;
        xbPerSec = _xbPerSec;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 200, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accxbPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's XB allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 200, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending XB on frontend.
    function pendingxb(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accxbPerShare = pool.accxbPerShare;
        if (block.timestamp > pool.lastRewardTimestamp && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 xbReward = multiplier.mul(xbPerSec).mul(pool.allocPoint).div(totalAllocPoint);
            accxbPerShare = accxbPerShare.add(xbReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accxbPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 xbReward = multiplier.mul(xbPerSec).mul(pool.allocPoint).div(totalAllocPoint);
        xb.mint(devaddr, xbReward.div(10));
        xb.mint(address(this), xbReward);
        pool.accxbPerShare = pool.accxbPerShare.add(xbReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for XB allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accxbPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeXBTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress1, depositFee.div(3));
                pool.lpToken.safeTransfer(feeAddress2, depositFee.div(3));
                pool.lpToken.safeTransfer(feeAddress3, depositFee.div(3));
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accxbPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accxbPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeXBTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accxbPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >= amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe XB transfer function, just in case if rounding error causes pool to not have enough XB.
    function safeXBTransfer(address _to, uint256 _amount) internal {
        uint256 xbBal = xb.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > xbBal) {
            transferSuccess = xb.transfer(_to, xbBal);
        } else {
            transferSuccess = xb.transfer(_to, _amount);
        }
        require(transferSuccess, "safeXBTransfer: transfer failed");
    }

    function setup() external onlyOwner {
        require(poolInfo.length == 0, "setup already called!");

        add(4500, IBEP20(0xb9994776199e40d31d095Eb858786039cF455aB4), 0, false); // XB-USDC                                                 0
        add(1500, IBEP20(0xE273F44272A6f8d6561591566f17087291695392), 0, false); // XB-WETH                                                 1
        add(1000, xb, 0, false); // XB                                                              2

        add(200, IBEP20(0x84652bb2539513BAf36e225c930Fdd8eaa63CE27), 200, false); // USDC-WETH      3
        add(200, IBEP20(0x87425D8812f44726091831a9A109f4bDc3eA34b4), 200, false); // USDC-GRAIL     4
        add(400, IBEP20(0x5201f6482EEA49c90FE609eD9d8F69328bAc8ddA), 200, false); // wstETH-WETH    5
        add(150, IBEP20(0x01efEd58B534d7a7464359A6F8d14D986125816B), 200, false); // USDC-DAI       6
        add(150, IBEP20(0x913398d79438e8D709211cFC3DC8566F6C67e1A8), 200, false); // USDC-GMX       7
        add(150, IBEP20(0x1C31fB3359357f6436565cCb3E982Bc6Bf4189ae), 200, false); // USDC-USDT      8
        add(150, IBEP20(0x4c0A68dd92449Fc06c1A651E9eb1dFfB61D64e18), 200, false); // WETH-VELA      9
        add(100, IBEP20(0x3FEe6E8FBDE48B727f82C55639ed2dD0cd9BA642), 200, false); // WETH-LUSD      10  
        add(200, IBEP20(0x96059759C6492fb4e8a9777b65f307F2C811a34F), 200, false); // WETH-WBTC      11

        add(200, IBEP20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1), 200, false); // WETH           12
        add(200, IBEP20(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8), 200, false); // GRAIL          13
        add(300, IBEP20(0x5979D7b546E38E414F7E9822514be443A4800529), 200, false); // wstWETH        14
        add(200, IBEP20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a), 200, false); // GMX            15
        add(150, IBEP20(0x088cd8f5eF3652623c22D48b1605DCfE860Cd704), 200, false); // VELA           16  
        add(150, IBEP20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1), 200, false); // DAI            17
        add(100, IBEP20(0x93b346b6BC2548dA6A1E7d98E9a421B42541425b), 200, false); // LUSD           18

    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress1(address _feeAddress1) external {
        require(msg.sender == feeAddress1, "setFeeAddress1: FORBIDDEN");
        require(_feeAddress1 != address(0), "!nonzero");
        feeAddress1 = _feeAddress1;
        emit SetFeeAddress1(msg.sender, _feeAddress1);
    }

    function setFeeAddress2(address _feeAddress2) external {
        require(msg.sender == feeAddress2, "setFeeAddress2: FORBIDDEN");
        require(_feeAddress2 != address(0), "!nonzero");
        feeAddress2 = _feeAddress2;
        emit SetFeeAddress2(msg.sender, _feeAddress2);
    }

    function setFeeAddress3(address _feeAddress3) external {
        require(msg.sender == feeAddress3, "setFeeAddress3: FORBIDDEN");
        require(_feeAddress3 != address(0), "!nonzero");
        feeAddress3 = _feeAddress3;
        emit SetFeeAddress3(msg.sender, _feeAddress3);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _xbPerSec) external onlyOwner {
        massUpdatePools();
        xbPerSec = _xbPerSec;
        emit UpdateEmissionRate(msg.sender, _xbPerSec);
    }
}