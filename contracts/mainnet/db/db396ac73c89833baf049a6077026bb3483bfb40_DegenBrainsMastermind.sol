/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
}
interface RewardsPool {
    function mint(uint256 amount, IERC20 token, address recipient) external;
}
interface Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract DegenBrainsMastermind is Ownable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 amount;
        uint256 startTimestamp;
        uint256 releasedTokens;
    }
    struct VestingPool {
        bool enabled;
        uint256 multiplier;
        uint256 period;
    }

    IERC20 public USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 public DBF = IERC20(0x38A896c29Eb54c566A3fD593f559174520Dc6F75);
    IERC20 public DBX = IERC20(0x0b257fe969d8782fAcb4ec790682C1d4d3dF1551);
    IERC20 public VDBX = IERC20(0xc71E4a725c10B38Ddb35BE8aB3d1D77fEd89093F);
    RewardsPool public rewardsPool = RewardsPool(0xb6B72F2a5FF537C0F0B21580B2BD644325411094);
    Router public router = Router(0x565C093907E5D8148e5964A6cae76780140c3004);
    address public teamWallet = 0xc1e351b1156b55a611b77e2bF3B60DED44db28b3;
    uint256 public bonus = 120;
    uint256 public totalPools = 0;
    uint256 public dbfMultiplier = 0;

    mapping(address => mapping (uint => VestingSchedule[])) public vestingSchedules;
    mapping(uint => VestingPool) public vestingPools;
    
    event Buy(address indexed from, uint256 amountIn, uint256 amountOut);
    event BonusSet(address indexed from, uint256 bonus);
    event Vest(address indexed from, uint id, uint256 amountIn);
    event Withdraw(address indexed from, uint256 amountOut);
    event PoolCreated(address indexed from, uint id, uint256 multiplier, uint256 period);
    event PoolEnabled(address indexed from, uint id);
    event PoolDisabled(address indexed from, uint id);
    event MultiplierSet(address indexed from, uint id, uint256 multiplier);

    constructor() {
        createPool(10,0);
        createPool(55,2592000);
        createPool(70,7776000);
        createPool(85,10368000);
        createPool(100,15552000);
        createPool(130,31104000);
        createPool(145,46656000);
        createPool(180,62208000);
    }

    function setTeamWallet(address _newWallet) public onlyOwner {
        teamWallet = _newWallet;
    }
    function setBonus(uint256 _newBonus) public onlyOwner {
        bonus = _newBonus;
        emit BonusSet(msg.sender, _newBonus);
    }
    function createPool(uint256 multiplier, uint256 period) public onlyOwner {
        vestingPools[totalPools] = VestingPool(true, multiplier, period);
        totalPools = totalPools.add(1);
        emit PoolCreated(msg.sender, totalPools, multiplier, period);
    }
    function setMultiplier(uint id, uint256 multiplier) public onlyOwner {
        vestingPools[id].multiplier = multiplier;
        emit MultiplierSet(msg.sender, id, multiplier);
    }
    function setDBFMultiplier(uint256 multiplier) public onlyOwner {
        dbfMultiplier = multiplier;
    }
    function enablePool(uint id) public onlyOwner {
        vestingPools[id].enabled = true;
        emit PoolEnabled(msg.sender, id);
    }
    function disablePool(uint id) public onlyOwner {
        vestingPools[id].enabled = false;
        emit PoolDisabled(msg.sender, id);
    }

    function getPool(uint id) public view returns (VestingPool memory) {
        return vestingPools[id];
    }
    function getPools() public view returns (VestingPool[] memory) {
        VestingPool[] memory pools = new VestingPool[](totalPools);
        for (uint i = 0; i < totalPools; i++) {
            pools[i] = getPool(i);
        }
        return pools;
    }
    function getTotalPools() public view returns (uint256) {
        return totalPools;
    }
    function totalVested(address account) public view returns (uint256) {
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < totalPools; i++) {
            VestingSchedule[] memory schedules = vestingSchedules[account][i];
            for (uint256 x = 0; x < schedules.length; x++) {
                VestingSchedule memory schedule = schedules[x];
                totalTokens += schedule.amount - schedule.releasedTokens;
            }
        }
        return totalTokens;
    }
    function estimate(address account) public view returns(uint256) {
        uint256 totalAvailableTokens = 0;
        for (uint256 i = 0; i < totalPools; i++) {
            VestingSchedule[] memory schedules = vestingSchedules[account][i];
            uint256 vestingPeriod = vestingPools[i].period;
            for (uint256 x = 0; x < schedules.length; x++) {
                VestingSchedule memory schedule = schedules[x];
                    uint256 elapsedTime = block.timestamp - schedule.startTimestamp;
                    if (elapsedTime > 0) {
                        if (elapsedTime > vestingPeriod) { elapsedTime = vestingPeriod; }
                        uint256 vestedTokens = (schedule.amount.mul(elapsedTime)).div(vestingPeriod);
                        uint256 availableTokens = vestedTokens.sub(schedule.releasedTokens);

                        if (availableTokens > 0) {
                            totalAvailableTokens = totalAvailableTokens.add(availableTokens);
                        }
                    }
            }
        }
        return totalAvailableTokens;
    }
    
    function buy(uint256 amountIn) public {
        require(DBX.balanceOf(msg.sender) >= amountIn, "bal low");
        require(DBX.allowance(msg.sender, address(this)) >= amountIn, "allowance low");
        DBX.transferFrom(msg.sender, teamWallet, amountIn);
        rewardsPool.mint(amountIn.mul(bonus).div(100), VDBX, msg.sender);
        emit Buy(msg.sender, amountIn, amountIn.mul(bonus).div(100));
    }
    function buyUSDC(uint256 amountIn) public {
        require(USDC.balanceOf(msg.sender) >= amountIn, "bal low");
        require(USDC.allowance(msg.sender, address(this)) >= amountIn, "allowance low");
        USDC.transferFrom(msg.sender, teamWallet, amountIn);
        
        address[] memory path;
        path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(DBX);
        uint256[] memory amountOut = router.getAmountsOut(amountIn.mul(bonus).div(100), path);
        
        rewardsPool.mint(amountOut[1], VDBX, msg.sender);
        emit Buy(msg.sender, amountIn, amountOut[1]);
    }
    function buyDBF(uint256 amountIn) public {
        require(dbfMultiplier > 0, "DBF disabled");
        require(DBF.balanceOf(msg.sender) >= amountIn, "bal low");
        require(DBF.allowance(msg.sender, address(this)) >= amountIn, "allowance low");
        DBF.transferFrom(msg.sender, teamWallet, amountIn);
        amountIn = amountIn.mul(dbfMultiplier).div(100);
        rewardsPool.mint(amountIn.mul(bonus).div(100), VDBX, msg.sender);
        emit Buy(msg.sender, amountIn.mul(bonus).div(100), amountIn);
    }
    function vest(uint id, uint256 amount) public {
        require(amount > 0, "Invalid amount");
        require(vestingPools[id].enabled, "this vesting pool is disable");
        require(VDBX.balanceOf(msg.sender) >= amount, "bal low");
        require(VDBX.allowance(msg.sender, address(this)) >= amount, "allowance low");
        VDBX.transferFrom(msg.sender, address(rewardsPool), amount);
        amount = amount.mul(vestingPools[id].multiplier).div(100);
        if (vestingPools[id].period == 0) {
            rewardsPool.mint(amount, DBX, msg.sender);
        } else {
            vestingSchedules[msg.sender][id].push(VestingSchedule(amount, block.timestamp, 0));
        }
        emit Vest(msg.sender, id, amount);
    }
    function withdraw() public {
        uint256 totalAvailableTokens;
        for (uint256 i = 0; i < totalPools; i++) {
            VestingSchedule[] storage schedules = vestingSchedules[msg.sender][i];
            uint256 vestingPeriod = vestingPools[i].period;
            for (uint256 x = 0; x < schedules.length; x++) {
                uint256 elapsedTime = block.timestamp.sub(schedules[x].startTimestamp);
                if (elapsedTime > 0) {
                    if (elapsedTime > vestingPeriod) { elapsedTime = vestingPeriod; }
                    uint256 vestedTokens = (schedules[x].amount.mul(elapsedTime)).div(vestingPeriod);
                    uint256 availableTokens = vestedTokens.sub(schedules[x].releasedTokens);
                    if (availableTokens > 0) {
                        totalAvailableTokens += availableTokens;
                        schedules[x].releasedTokens += availableTokens;
                    }
                    if (schedules[x].amount == schedules[x].releasedTokens) {
                        uint256 lastIndex = schedules.length - 1;
                        schedules[x] = schedules[lastIndex];
                        schedules.pop();
                        x--;
                    }
                }
            }
        }

        require(totalAvailableTokens > 0, "vDBX: No tokens available for release");
        rewardsPool.mint(totalAvailableTokens, DBX, msg.sender);
        emit Withdraw(msg.sender, totalAvailableTokens);
    }
}