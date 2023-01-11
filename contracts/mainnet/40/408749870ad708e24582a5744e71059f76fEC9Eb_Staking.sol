/**
 *Submitted for verification at Arbiscan on 2023-01-11
*/

pragma solidity ^0.6.12;

interface IPancakeSwapFactory {
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);

		function feeTo() external view returns (address);
		function feeToSetter() external view returns (address);

		function getPair(address tokenA, address tokenB) external view returns (address pair);
		function allPairs(uint) external view returns (address pair);
		function allPairsLength() external view returns (uint);

		function createPair(address tokenA, address tokenB) external returns (address pair);

		function setFeeTo(address) external;
		function setFeeToSetter(address) external;
}

interface IPancakeSwapPair {
		event Approval(address indexed owner, address indexed spender, uint value);
		event Transfer(address indexed from, address indexed to, uint value);

		function name() external pure returns (string memory);
		function symbol() external pure returns (string memory);
		function decimals() external pure returns (uint8);
		function totalSupply() external view returns (uint);
		function balanceOf(address owner) external view returns (uint);
		function allowance(address owner, address spender) external view returns (uint);

		function approve(address spender, uint value) external returns (bool);
		function transfer(address to, uint value) external returns (bool);
		function transferFrom(address from, address to, uint value) external returns (bool);

		function DOMAIN_SEPARATOR() external view returns (bytes32);
		function PERMIT_TYPEHASH() external pure returns (bytes32);
		function nonces(address owner) external view returns (uint);

		function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

		event Mint(address indexed sender, uint amount0, uint amount1);
		event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
		event Swap(
				address indexed sender,
				uint amount0In,
				uint amount1In,
				uint amount0Out,
				uint amount1Out,
				address indexed to
		);
		event Sync(uint112 reserve0, uint112 reserve1);

		function MINIMUM_LIQUIDITY() external pure returns (uint);
		function factory() external view returns (address);
		function token0() external view returns (address);
		function token1() external view returns (address);
		function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
		function price0CumulativeLast() external view returns (uint);
		function price1CumulativeLast() external view returns (uint);
		function kLast() external view returns (uint);

		function mint(address to) external returns (uint liquidity);
		function burn(address to) external returns (uint amount0, uint amount1);
		function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
		function skim(address to) external;
		function sync() external;

		function initialize(address, address) external;
}

interface IPancakeSwapRouter{
		function factory() external pure returns (address);
		function WETH() external pure returns (address);

		function addLiquidity(
				address tokenA,
				address tokenB,
				uint amountADesired,
				uint amountBDesired,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB, uint liquidity);
		function addLiquidityETH(
				address token,
				uint amountTokenDesired,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external payable returns (uint amountToken, uint amountETH, uint liquidity);
		function removeLiquidity(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETH(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external returns (uint amountToken, uint amountETH);
		function removeLiquidityWithPermit(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETHWithPermit(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountToken, uint amountETH);
		function swapExactTokensForTokens(
				uint amountIn,
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapTokensForExactTokens(
				uint amountOut,
				uint amountInMax,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
				external
				payable
				returns (uint[] memory amounts);
		function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
				external
				returns (uint[] memory amounts);
		function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
				external
				returns (uint[] memory amounts);
		function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
				external
				payable
				returns (uint[] memory amounts);

		function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
		function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
		function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
		function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
		function removeLiquidityETHSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountETHMin,
			address to,
			uint deadline
		) external returns (uint amountETH);
		function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
			address token,
			uint liquidity,
			uint amountTokenMin,
			uint amountETHMin,
			address to,
			uint deadline,
			bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountETH);
	
		function swapExactTokensForTokensSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
		function swapExactETHForTokensSupportingFeeOnTransferTokens(
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external payable;
		function swapExactTokensForETHSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
}
// File: staking.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "ds-math-mul-overflow");
        c = a / b;
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function burn(uint amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(uint256 amount) external returns (bool);
}

// each staking instance mapping to each pool
contract Staking is Ownable {
    using SafeMath for uint256;
    event Stake(address staker, uint256 amount);
    event Reward(address staker, uint256 amount_1);
    event Withdraw(address staker, uint256 amount);
    //staker inform
    struct Staker {
        uint referal;
        uint256 stakingAmount; // staking token amount
        uint256 lastUpdateTime; // last amount updatetime
        uint256 lastStakeUpdateTime; // last Stake updatetime
        uint256 stake; // stake amount
        uint256 rewards_1; // stake amount
    }
    //stakeToken is
    address public rewardTokenAddress_1;
    address public stakeTokenAddress; //specify farming token when contract created

    address public marketingAddress;

    uint256 public totalStakingAmount; // total staking token amount
    uint256 public lastUpdateTime; // total stake amount and reward update time
    uint256 public totalStake; // total stake amount

    uint256 public stakerNum;

    IPancakeSwapRouter public PancakeSwapRouter;

    mapping(address => Staker) public stakers;

    constructor(address _stakeTokenAddress, address _rewardTokenAddress_1)
        public
    {
        rewardTokenAddress_1 = _rewardTokenAddress_1;
        stakeTokenAddress = _stakeTokenAddress;
        lastUpdateTime = block.timestamp;
    }

    /* ----------------- total counts ----------------- */

    function countTotalStake() public view returns (uint256 _totalStake) {
        _totalStake =
            totalStake +
            totalStakingAmount.mul((block.timestamp).sub(lastUpdateTime));
    }

    function countTotalReward() public view returns (uint256 _totalReward_1) {
        _totalReward_1 = IERC20(rewardTokenAddress_1).balanceOf(address(this));
    }

    function updateTotalStake() internal {
        uint256 _rewardableAmount_1 = getRewardableAmount();
        if (_rewardableAmount_1 > 1e1 * 1e18) {
            swapTokenForReward();
        }

        totalStake = countTotalStake();
        lastUpdateTime = block.timestamp;
    }

    function APY() external view returns (uint) {
        uint256 _totalStakte = countTotalStake();
        if (_totalStakte == 0) return 0;
        uint256 _reward1 = countTotalReward();

        uint256 rewardable1;
        if (_reward1 > 1e15) {
            address[] memory path_1 = new address[](2);
            path_1[0] = stakeTokenAddress;
            path_1[1] = rewardTokenAddress_1;

            uint256[] memory d1 = PancakeSwapRouter.getAmountsIn(
                _reward1,
                path_1
            );

            rewardable1 = d1[0];
        }

        uint256 _totalReward = rewardable1 +
            IERC20(stakeTokenAddress).balanceOf(address(this)) -
            totalStakingAmount;

        return (_totalReward * 1000000 * 365 days) / _totalStakte;
    }

    /* ----------------- personal counts ----------------- */

    function getStakeInfo(address stakerAddress)
        public
        view
        returns (
            uint256 _total,
            uint256 _staking,
            uint256 _rewardable_1,
            uint256 _rewards_1
        )
    {
        _total = totalStakingAmount;
        _staking = stakers[stakerAddress].stakingAmount;
        (_rewardable_1) = EstimateReward(stakerAddress);
        _rewards_1 = stakers[stakerAddress].rewards_1;
    }

    function countStake(address stakerAddress)
        public
        view
        returns (uint256 _stake)
    {
        Staker memory _staker = stakers[stakerAddress];
        if (_staker.lastUpdateTime == 0) return 0;
        _stake =
            _staker.stake +
            ((block.timestamp).sub(_staker.lastUpdateTime)).mul(
                _staker.stakingAmount
            );
    }

    function countReward(address stakerAddress)
        public
        view
        returns (uint256 _reward_1)
    {
        uint256 _totalStake = countTotalStake();
        uint256 _totalReward1 = countTotalReward();
        uint256 stake = countStake(stakerAddress) +
            stakers[stakerAddress].referal;
        _reward_1 = _totalStake == 0
            ? 0
            : _totalReward1.mul(stake).div(_totalStake);
    }

    function EstimateReward(address stakerAddress)
        public
        view
        returns (uint256 _reward_1)
    {
        uint256 _totalStake = countTotalStake();
        uint256 _totalReward1 = countTotalReward();

        uint256 rewardableAmount = (getRewardableAmount() * 94) / 100;
        if (rewardableAmount > 1e17) {
            address[] memory path_1 = new address[](2);
            path_1[0] = stakeTokenAddress;
            path_1[1] = rewardTokenAddress_1;

            uint256[] memory d1 = PancakeSwapRouter.getAmountsOut(
                rewardableAmount,
                path_1
            );

            _totalReward1 += d1[1];
        }

        uint256 stake = countStake(stakerAddress) +
            stakers[stakerAddress].referal;
        _reward_1 = _totalStake == 0
            ? 0
            : _totalReward1.mul(stake).div(_totalStake);
    }

    function countFee(address stakerAddress)
        public
        view
        returns (uint256 _fee)
    {
        if (
            block.timestamp.sub(stakers[stakerAddress].lastStakeUpdateTime) <
            14 days
        ) {
            _fee = 140;
        } else _fee = 0;
    }

    /* ----------------- actions ----------------- */

    function stake(uint256 amount, address referrar) external {
        updateTotalStake();
        address stakerAddress = msg.sender;
        if (stakers[stakerAddress].lastUpdateTime == 0) stakerNum++;

        stakers[stakerAddress].stake = countStake(stakerAddress);

        stakers[stakerAddress].stakingAmount += amount.mul(990).div(1000);
        stakers[stakerAddress].lastUpdateTime = block.timestamp;
        stakers[stakerAddress].lastStakeUpdateTime = block.timestamp;

        if (referrar != address(0) && referrar != stakerAddress) {
            uint referalReward = amount * 1 days;
            stakers[referrar].referal += referalReward;
            totalStake += referalReward;
        }

        IERC20(stakeTokenAddress).transferFrom(
            stakerAddress,
            address(this),
            amount.mul(995).div(1000)
        );

        IERC20(stakeTokenAddress).transferFrom(
            stakerAddress,
            marketingAddress,
            amount.mul(5).div(1000)
        );

        totalStakingAmount = totalStakingAmount + amount.mul(995).div(1000);
        emit Stake(stakerAddress, amount);
    }

    function unstaking() external {
        address stakerAddress = msg.sender;
        uint256 amount = stakers[stakerAddress].stakingAmount;
        require(0 <= amount, "staking : amount over stakeAmount");
        uint256 withdrawFee = countFee(stakerAddress);

        stakers[stakerAddress].stake = countStake(stakerAddress);
        stakers[stakerAddress].stakingAmount -= amount;
        stakers[stakerAddress].lastUpdateTime = block.timestamp;
        stakers[stakerAddress].lastStakeUpdateTime = block.timestamp;

        updateTotalStake();
        totalStakingAmount = totalStakingAmount - amount;

        if (withdrawFee > 0) {
            IERC20(stakeTokenAddress).burn(amount.mul(20).div(1000));

            IERC20(stakeTokenAddress).transfer(
                marketingAddress,
                amount.mul(40).div(1000)
            );
        }

        IERC20(stakeTokenAddress).transfer(
            stakerAddress,
            amount.mul(1000 - withdrawFee).div(1000)
        );
        emit Withdraw(stakerAddress, amount);
    }

    function claimRewards() external {
        address stakerAddress = msg.sender;
        require(
            block.timestamp - stakers[stakerAddress].lastUpdateTime >= 24 hours,
            "claim lock for 24 hours"
        );
        updateTotalStake();
        uint256 _stake = countStake(stakerAddress) +
            stakers[stakerAddress].referal;
        uint256 _reward_1 = countReward(stakerAddress);

        require(_reward_1 > 0, "staking : reward amount is 0");
        IERC20 rewardToken_1 = IERC20(rewardTokenAddress_1);

        rewardToken_1.transfer(stakerAddress, _reward_1);

        stakers[stakerAddress].rewards_1 += _reward_1;
        totalStake -= _stake;

        stakers[stakerAddress].stake = 0;
        stakers[stakerAddress].referal = 0;
        stakers[stakerAddress].lastUpdateTime = block.timestamp;

        emit Reward(stakerAddress, _reward_1);
    }

    function getClaimAbleTime(address stakerAddress)
        external
        view
        returns (uint)
    {
        if (block.timestamp - stakers[stakerAddress].lastUpdateTime >= 24 hours)
            return 0;
        return
            24 hours + stakers[stakerAddress].lastUpdateTime - block.timestamp;
    }

    /* ----------------- swap for token ----------------- */

    function setInitialAddresses(
        address _RouterAddress,
        address _marketingAddress
    ) external onlyOwner {
        marketingAddress = _marketingAddress;
        IPancakeSwapRouter _PancakeSwapRouter = IPancakeSwapRouter(
            _RouterAddress
        );
        PancakeSwapRouter = _PancakeSwapRouter;
    }

    function getRewardableAmount()
        public
        view
        returns (uint256 _rewardableAmount_1)
    {
        uint rewardable = IERC20(stakeTokenAddress).balanceOf(address(this)) -
            totalStakingAmount;
        _rewardableAmount_1 = rewardable;
    }

    function swapTokenForReward() public {
        uint256 _rewardableAmount_1 = getRewardableAmount();
        swapTokensForRewardToken(_rewardableAmount_1);
    }

    function swapTokensForRewardToken(uint256 tokenAmount_1) internal {
        address[] memory path_1 = new address[](2);
        path_1[0] = stakeTokenAddress;
        path_1[1] = rewardTokenAddress_1;
        IERC20(stakeTokenAddress).approve(
            address(PancakeSwapRouter),
            tokenAmount_1
        );

        // make the swap

        PancakeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount_1,
                0, // accept any amount of usdt
                path_1,
                address(this),
                block.timestamp
            );
    }
}