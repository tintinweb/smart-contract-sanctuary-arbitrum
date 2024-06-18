// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


interface IDistributor {
    function distribute() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITreasuryToken {
    function mint(address to, uint256 amount) external;
    function rate() external returns (uint);
    function quoteMint(uint256 amount) external view returns (uint256 total, uint256 cost, uint256 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import './IUniswapV2Pair.sol';


interface ILPStaker {
    function totalStaked() external view returns (uint256);

    function lpToken() external view returns (address);

    function distributeRewards(uint256 rewardAmount1, uint256 rewardAmount2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUniswapV2Pair {
    function transferFrom(address from, address to, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address owner) external view returns (uint);

    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@lira-dao/token-distributor/contracts/interfaces/IDistributor.sol';
import '@lira-dao/treasury-tokens/contracts/interfaces/ITreasuryToken.sol';
import './interfaces/ILPStaker.sol';
import './interfaces/IUniswapV2Pair.sol';


/**
 * @title Reward Splitter V1
 * @author LIRA DAO Team
 * @custom:security-contact [email protected]
 *
 * To know more about the ecosystem you can find us on https://liradao.org don't trust, verify!
 */
contract RewardSplitter is Ownable2Step {
    struct RewardLiquidity {
        uint rewardAmountLdt;
        uint rewardAmountTb;
        uint liquidityLdt;
        uint liquidityTb;
    }

    struct Rewards {
        uint ldtBalance;
        uint ldtRewards;
        uint tbRewards;

        uint ldtFarmingReward;
        uint ldtTeamReward;

        uint tbFarmingReward;
        uint tbTeamReward;

        uint tbbFarmingReward;
        uint tbsFarmingReward;
        uint tbgFarmingReward;

        uint tbbTeamReward;
        uint tbsTeamReward;
        uint tbgTeamReward;

        uint tbbAmount;
        uint tbbLdtAmount;

        uint tbsAmount;
        uint tbsLdtAmount;

        uint tbgAmount;
        uint tbgLdtAmount;

        RewardLiquidity tbbLiquidity;
        RewardLiquidity tbsLiquidity;
        RewardLiquidity tbgLiquidity;
    }

    struct RewardRate {
        uint ldt;
        uint tb;
    }

    struct LdtSplit {
        uint8 farmingReward;
        uint8 stakingReward;
        uint8 teamReward;
        uint8 daoFundReward;
        uint8 ambassadorIncentiveReward;
        uint8 greenEnergyProducersReward;
        uint8 marketingReward;
    }

    struct TbSplit {
        uint8 farmingReward;
        uint8 stakingReward;
        uint8 teamReward;
        uint8 daoFundReward;
        uint8 ambassadorIncentiveReward;
        uint8 greenEnergyProducersReward;
    }

    address public ldt;

    address public tbbAddress;
    address public tbsAddress;
    address public tbgAddress;

    address public tbbFarmAddress;
    address public tbsFarmAddress;
    address public tbgFarmAddress;

    address public teamAddress;

    address public distributor;

    uint8 public tbRate = 80;

    RewardRate public tbbRewardRate = RewardRate(200, 200);
    RewardRate public tbsRewardRate = RewardRate(500, 500);
    RewardRate public tbgRewardRate = RewardRate(1000, 1000);

    RewardRate public teamRewardRate = RewardRate(1000, 1000);

    LdtSplit public ldtSplit = LdtSplit(20, 40, 10, 14, 10, 5, 1);
    TbSplit public tbSplit = TbSplit(40, 25, 10, 10, 10, 5);

    uint public constant MIN_RATE = 1;
    uint public constant MAX_RATE = 100_000;

    constructor(
        address _ldt,
        address _distributor,
        address _tbbAddress,
        address _tbbFarmAddress,
        address _tbsAddress,
        address _tbsFarmAddress,
        address _tbgAddress,
        address _tbgFarmAddress,
        address _teamAddress
    ) Ownable(msg.sender) {
        ldt = _ldt;
        distributor = _distributor;
        tbbAddress = _tbbAddress;
        tbbFarmAddress = _tbbFarmAddress;
        tbsAddress = _tbsAddress;
        tbsFarmAddress = _tbsFarmAddress;
        tbgAddress = _tbgAddress;
        tbgFarmAddress = _tbgFarmAddress;
        teamAddress = _teamAddress;
    }

    function approveTokens() public onlyOwner {
        IERC20(ldt).approve(tbbAddress, type(uint256).max);
        IERC20(ldt).approve(tbsAddress, type(uint256).max);
        IERC20(ldt).approve(tbgAddress, type(uint256).max);

        IERC20(tbbAddress).approve(tbbFarmAddress, type(uint256).max);
        IERC20(ldt).approve(tbbFarmAddress, type(uint256).max);

        IERC20(tbsAddress).approve(tbsFarmAddress, type(uint256).max);
        IERC20(ldt).approve(tbsFarmAddress, type(uint256).max);

        IERC20(tbgAddress).approve(tbgFarmAddress, type(uint256).max);
        IERC20(ldt).approve(tbgFarmAddress, type(uint256).max);
    }

    function requestDistribution() external onlyOwner {
        Rewards memory rewards = Rewards(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, RewardLiquidity(0, 0, 0, 0), RewardLiquidity(0, 0, 0, 0), RewardLiquidity(0, 0, 0, 0));

        IDistributor(distributor).distribute();

        rewards.ldtBalance = IERC20(ldt).balanceOf(address(this));

        rewards.tbRewards = (rewards.ldtBalance * tbRate) / 100;
        rewards.ldtRewards = rewards.ldtBalance - rewards.tbRewards;

        rewards.ldtFarmingReward = (rewards.ldtRewards * ldtSplit.farmingReward) / 100;
        rewards.tbFarmingReward = (rewards.tbRewards * tbSplit.farmingReward) / 100;

        rewards.tbbFarmingReward = (rewards.tbFarmingReward * 20) / 100;
        rewards.tbsFarmingReward = (rewards.tbFarmingReward * 30) / 100;
        rewards.tbgFarmingReward = rewards.tbFarmingReward - rewards.tbbFarmingReward - rewards.tbsFarmingReward;

        rewards.tbbLiquidity = calculateStakingLiquidity(tbbFarmAddress, tbbRewardRate);
        rewards.tbsLiquidity = calculateStakingLiquidity(tbsFarmAddress, tbsRewardRate);
        rewards.tbgLiquidity = calculateStakingLiquidity(tbgFarmAddress, tbgRewardRate);

        uint totalLdt = rewards.tbbLiquidity.rewardAmountLdt + rewards.tbsLiquidity.rewardAmountLdt + rewards.tbgLiquidity.rewardAmountLdt;

        if (totalLdt > rewards.ldtFarmingReward) {
            uint tbbLiquidity = getLdtLiquidity(tbbFarmAddress);
            uint tbsLiquidity = getLdtLiquidity(tbsFarmAddress);
            uint tbgLiquidity = getLdtLiquidity(tbgFarmAddress);
            uint totalLiquidity = tbbLiquidity + tbsLiquidity + tbgLiquidity;

            rewards.tbbLdtAmount = (tbbLiquidity * rewards.ldtFarmingReward) / totalLiquidity;
            rewards.tbsLdtAmount = (tbsLiquidity * rewards.ldtFarmingReward) / totalLiquidity;
            rewards.tbgLdtAmount = (tbgLiquidity * rewards.ldtFarmingReward) / totalLiquidity;
        } else {
            rewards.tbbLdtAmount = rewards.tbbLiquidity.rewardAmountLdt;
            rewards.tbsLdtAmount = rewards.tbsLiquidity.rewardAmountLdt;
            rewards.tbgLdtAmount = rewards.tbgLiquidity.rewardAmountLdt;
        }

        if (rewards.tbbLiquidity.rewardAmountTb > rewards.tbbFarmingReward / ITreasuryToken(tbbAddress).rate()) {
            ITreasuryToken(tbbAddress).mint(address(this), rewards.tbbFarmingReward / ITreasuryToken(tbbAddress).rate());
        } else {
            ITreasuryToken(tbbAddress).mint(address(this), rewards.tbbLiquidity.rewardAmountTb);
        }

        if (rewards.tbsLiquidity.rewardAmountTb > rewards.tbsFarmingReward / ITreasuryToken(tbsAddress).rate()) {
            ITreasuryToken(tbsAddress).mint(address(this), rewards.tbsFarmingReward / ITreasuryToken(tbsAddress).rate());
        } else {
            ITreasuryToken(tbsAddress).mint(address(this), rewards.tbsLiquidity.rewardAmountTb);
        }

        if (rewards.tbgLiquidity.rewardAmountTb > rewards.tbgFarmingReward / ITreasuryToken(tbgAddress).rate()) {
            ITreasuryToken(tbgAddress).mint(address(this), rewards.tbgLiquidity.rewardAmountTb / ITreasuryToken(tbgAddress).rate());
        } else {
            ITreasuryToken(tbgAddress).mint(address(this), rewards.tbgLiquidity.rewardAmountTb);
        }

        if (ldtSplit.teamReward > 0) {
            rewards.ldtTeamReward = (rewards.ldtRewards * ldtSplit.teamReward) / 100;
            rewards.tbTeamReward = (rewards.tbRewards * tbSplit.teamReward) / 100;

            rewards.tbbTeamReward = (rewards.tbTeamReward * 20) / 100;
            rewards.tbsTeamReward = (rewards.tbTeamReward * 30) / 100;
            rewards.tbgTeamReward = rewards.tbTeamReward - rewards.tbbTeamReward - rewards.tbsTeamReward;

            uint totalLdtLiquidity = rewards.tbbLiquidity.liquidityLdt + rewards.tbsLiquidity.liquidityLdt + rewards.tbgLiquidity.liquidityLdt;

            uint teamLdtReward = (totalLdtLiquidity * teamRewardRate.ldt) / MAX_RATE;

            if (teamLdtReward < rewards.ldtTeamReward) {
                rewards.ldtTeamReward = teamLdtReward;
            }

            if ((rewards.tbbLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE > rewards.tbbTeamReward / ITreasuryToken(tbbAddress).rate()) {
                ITreasuryToken(tbbAddress).mint(teamAddress, rewards.tbbTeamReward / ITreasuryToken(tbbAddress).rate());
            } else {
                ITreasuryToken(tbbAddress).mint(teamAddress, (rewards.tbbLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE);
            }

            if ((rewards.tbsLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE > rewards.tbsTeamReward / ITreasuryToken(tbsAddress).rate()) {
                ITreasuryToken(tbsAddress).mint(teamAddress, rewards.tbsTeamReward / ITreasuryToken(tbsAddress).rate());
            } else {
                ITreasuryToken(tbsAddress).mint(teamAddress, (rewards.tbsLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE);
            }

            if ((rewards.tbgLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE > rewards.tbgTeamReward / ITreasuryToken(tbgAddress).rate()) {
                ITreasuryToken(tbgAddress).mint(teamAddress, rewards.tbgTeamReward / ITreasuryToken(tbgAddress).rate());
            } else {
                ITreasuryToken(tbgAddress).mint(teamAddress, (rewards.tbgLiquidity.liquidityTb * teamRewardRate.tb) / MAX_RATE);
            }
        }

        rewards.tbbAmount = IERC20(tbbAddress).balanceOf(address(this));
        rewards.tbsAmount = IERC20(tbsAddress).balanceOf(address(this));
        rewards.tbgAmount = IERC20(tbgAddress).balanceOf(address(this));

        ILPStaker(tbbFarmAddress).distributeRewards(rewards.tbbLdtAmount, rewards.tbbAmount);
        ILPStaker(tbsFarmAddress).distributeRewards(rewards.tbsLdtAmount, rewards.tbsAmount);
        ILPStaker(tbgFarmAddress).distributeRewards(rewards.tbgLdtAmount, rewards.tbgAmount);

        IERC20(ldt).transfer(teamAddress, rewards.ldtTeamReward);

        if (IERC20(ldt).balanceOf(address(this)) > 0) {
            IERC20(ldt).transfer(distributor, IERC20(ldt).balanceOf(address(this)));
        }
    }

    function getLdtLiquidity(address _farm) public view returns (uint256 liquidity) {
        address lpToken = ILPStaker(_farm).lpToken();

        liquidity = IERC20(ldt).balanceOf(lpToken);
    }

    function calculateStakingLiquidity(address _farm, RewardRate memory _rate) public view returns (RewardLiquidity memory) {
        uint256 totalStaked = ILPStaker(_farm).totalStaked();
        address lpToken = ILPStaker(_farm).lpToken();
        uint256 lpTotalSupply = IERC20(lpToken).totalSupply();

        address t0 = IUniswapV2Pair(lpToken).token0();
        address t1 = IUniswapV2Pair(lpToken).token1();

        (address token0, address token1) = t0 == ldt ? (t0, t1) : (t1, t0);
        require(token0 == ldt, 'INVALID_TOKEN');

        uint balance0 = IERC20(token0).balanceOf(lpToken);
        uint balance1 = IERC20(token1).balanceOf(lpToken);

        uint amount0 = (totalStaked * balance0) / lpTotalSupply;
        uint amount1 = (totalStaked * balance1) / lpTotalSupply;

        return RewardLiquidity(
            (amount0 * _rate.ldt) / MAX_RATE,
            (amount1 * _rate.tb) / MAX_RATE,
            amount0,
            amount1
        );
    }

    function setTbbRewardRate(uint _ldtRate, uint _tbbRate) external onlyOwner {
        require(_ldtRate >= MIN_RATE && _ldtRate <= MAX_RATE, 'INVALID_LDT_RATE');
        require(_tbbRate >= MIN_RATE && _tbbRate <= MAX_RATE, 'INVALID_TB_RATE');

        tbbRewardRate.ldt = _ldtRate;
        tbbRewardRate.tb = _tbbRate;
    }

    function setTbsRewardRate(uint _ldtRate, uint _tbsRate) external onlyOwner {
        require(_ldtRate >= MIN_RATE && _ldtRate <= MAX_RATE, 'INVALID_LDT_RATE');
        require(_tbsRate >= MIN_RATE && _tbsRate <= MAX_RATE, 'INVALID_TB_RATE');

        tbsRewardRate.ldt = _ldtRate;
        tbsRewardRate.tb = _tbsRate;
    }

    function setTbgRewardRate(uint _ldtRate, uint _tbgRate) external onlyOwner {
        require(_ldtRate >= MIN_RATE && _ldtRate <= MAX_RATE, 'INVALID_LDT_RATE');
        require(_tbgRate >= MIN_RATE && _tbgRate <= MAX_RATE, 'INVALID_TB_RATE');

        tbgRewardRate.ldt = _ldtRate;
        tbgRewardRate.tb = _tbgRate;
    }

    function setTeamRewardRate(uint _ldtRate, uint _tbgRate) external onlyOwner {
        require(_ldtRate >= MIN_RATE && _ldtRate <= MAX_RATE, 'INVALID_LDT_RATE');
        require(_tbgRate >= MIN_RATE && _tbgRate <= MAX_RATE, 'INVALID_TB_RATE');

        teamRewardRate.ldt = _ldtRate;
        teamRewardRate.tb = _tbgRate;
    }

    function setTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;
    }

    function recoverOwnershipTbb() external onlyOwner {
        Ownable(tbbAddress).transferOwnership(owner());
    }

    function recoverOwnershipTbs() external onlyOwner {
        Ownable(tbsAddress).transferOwnership(owner());
    }

    function recoverOwnershipTbg() external onlyOwner {
        Ownable(tbgAddress).transferOwnership(owner());
    }

    function recoverOwnershipTbbFarm() external onlyOwner {
        Ownable(tbbFarmAddress).transferOwnership(owner());
    }

    function recoverOwnershipTbsFarm() external onlyOwner {
        Ownable(tbsFarmAddress).transferOwnership(owner());
    }

    function recoverOwnershipTbgFarm() external onlyOwner {
        Ownable(tbgFarmAddress).transferOwnership(owner());
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }

    function setLdtSplit(LdtSplit memory _ldtSplit) external onlyOwner {
        require(
            _ldtSplit.farmingReward +
            _ldtSplit.stakingReward +
            _ldtSplit.teamReward +
            _ldtSplit.daoFundReward +
            _ldtSplit.ambassadorIncentiveReward +
            _ldtSplit.greenEnergyProducersReward +
            _ldtSplit.marketingReward <= 100,
            'INVALID_SPLIT'
        );

        ldtSplit = _ldtSplit;
    }

    function setTbSplit(TbSplit memory _tbSplit) external onlyOwner {
        require(
            _tbSplit.farmingReward +
            _tbSplit.stakingReward +
            _tbSplit.teamReward +
            _tbSplit.daoFundReward +
            _tbSplit.ambassadorIncentiveReward +
            _tbSplit.greenEnergyProducersReward <= 100,
            'INVALID_SPLIT'
        );

        tbSplit = _tbSplit;
    }
}