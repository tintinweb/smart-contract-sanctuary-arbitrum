// SPDX-License-Identifier: MIT
/// @title LP Staking
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC20Minter.sol";
import "./libs/PancakeLibs.sol";

import "./interfaces/INftRewards.sol";

contract LpStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Minter;

    INftRewards public nftRewardsContract;

    /* @dev struct to hold the user data */
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt.
        uint256 firstStake; // timestamp of the first time this wallet stakes
    }

    struct FeeInfo {
        uint256 feePercent;         // Percent fee that applies to this range
        uint256 timeCheck; // number of seconds from the intial stake this fee applies
    }

    /* @dev struct to hold the info for each pool */
    struct PoolInfo {
        IERC20Minter lpToken;           // Address of a token contract, LP or token.
        uint256 allocPoint;       // How many allocation points assigned to this pool. 
        uint256 lastRewardBlock;  // Last block number that distribution occurs.
        uint256 accRewardsPerShare;   // Accumulated Tokens per share, times 1e12. 
        uint directStake;      // 0 = off, 1 = buy token, 2 = pair native/token, 3 = pair token/token, 
        IERC20Minter tokenA; // leave emty if native, otherwise the token to pair with tokenB
        IERC20Minter tokenB; // the other half of the LP pair
        uint256 tierMultiplier;   // rewards * tierMultiplier is how many tier points earned
        uint256 totalStakers; // number of people staked
    }


    // Global active flag
    bool public isActive;

    // swap check
    bool isSwapping;

    // add liq check
    bool isAddingLp;

    // The Token
    IERC20Minter public rewardToken;

    // Base amount of rewards distributed per block
    uint256 public rewardsPerBlock;

    // Addresses 
    address public feeAddress;

    // Info of each user that stakes LP tokens 
    PoolInfo[] public poolInfo;

    // Info about the withdraw fees
    FeeInfo[] public feeInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools 
    uint256 public totalAllocPoint = 0;

    // The block number when rewards start 
    uint256 public startBlock;

    uint256 public minPairAmount;

    uint256 public defaultFeePercent = 100;

    // PCS router
    IPancakeRouter02 private  pancakeRouter; 

    //TODO: Change to Mainnet
    //TestNet
     address private PancakeRouter;
    //MainNet
    // address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // @dev mapping of existing pools to avoid dupes
    mapping(IERC20Minter => bool) public pollExists;

    event SetActive( bool isActive);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetFeeStructure(uint256[] feePercents, uint256[] feeTimeChecks);
    event UpdateEmissionRate(address indexed user, uint256 rewardsPerBlock);

    constructor(
        IERC20Minter _rewardToken,
        address _feeAddress,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        INftRewards _nftRewardsContract,
        address _router,
        uint256[] memory _feePercents,
        uint256[] memory  _feeTimeChecks
    ) {
        require(_feeAddress != address(0),'Invalid Address');

        PancakeRouter = address(_router);
        rewardToken = _rewardToken;
        feeAddress = _feeAddress;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;

        

        pancakeRouter = IPancakeRouter02(PancakeRouter);
        rewardToken.approve(address(pancakeRouter), type(uint256).max);

        // set the initial fee structure
        _setWithdrawFees(_feePercents ,_feeTimeChecks );

        // set the nft rewards contract
        nftRewardsContract = _nftRewardsContract;

        // add the SAS staking pool
        add(400, rewardToken,  true, 4000000000000000000, 1, IERC20Minter(address(0)), IERC20Minter(address(0)));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setWithdrawFees( uint256[] calldata _feePercents ,uint256[] calldata  _feeTimeChecks ) public onlyOwner {
        _setWithdrawFees( _feePercents , _feeTimeChecks );
    }

    function _setWithdrawFees( uint256[] memory _feePercents ,uint256[] memory  _feeTimeChecks ) private {
        delete feeInfo;
        for (uint256 i = 0; i < _feePercents.length; ++i) {
            require( _feePercents[i] <= 2500, "fee too high");
            feeInfo.push(FeeInfo({
                feePercent : _feePercents[i],
                timeCheck : _feeTimeChecks[i]
            }));
        }
        emit SetFeeStructure(_feePercents,_feeTimeChecks);
    }

    event PoolAdded(uint256 indexed pid, uint256 allocPoint, address lpToken,uint256 tierMultiplier, uint directStake, address tokenA, address tokenB);
    /* @dev Adds a new Pool. Can only be called by the owner */
    function add(
        uint256 _allocPoint, 
        IERC20Minter _lpToken, 
        bool _withUpdate,
        uint256 _tierMultiplier, 
        uint _directStake,
        IERC20Minter _tokenA,
        IERC20Minter _tokenB
    ) public onlyOwner {
        require(pollExists[_lpToken] == false, "nonDuplicated: duplicated");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        pollExists[_lpToken] = true;

        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewardsPerShare : 0,
            tokenA: _tokenA,
            tokenB: _tokenB,
            directStake: _directStake,
            tierMultiplier: _tierMultiplier,
            totalStakers: 0
        }));

        emit PoolAdded(poolInfo.length-1, _allocPoint, address(_lpToken), _tierMultiplier,_directStake, address(_tokenA), address(_tokenB));
    }

    /* @dev Update the given pool's allocation point and deposit fee. Can only be called by the owner */
    event PoolSet(uint256 indexed pid, uint256 allocPoint,uint256 tierMultiplier, uint directStake);
    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        bool _withUpdate, 
        uint256 _tierMultiplier,
        uint _directStake
    ) public onlyOwner {

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].tierMultiplier = _tierMultiplier;
        poolInfo[_pid].directStake = _directStake;

        emit PoolSet(_pid, _allocPoint,_tierMultiplier,_directStake);
    }

    /* @dev Return reward multiplier over the given _from to _to block */
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    /* @dev View function to see pending rewards on frontend.*/
    function pendingRewards(uint256 _pid, address _user)  external view returns (uint256) {
        return _pendingRewards(_pid, _user);
    }

    /* @dev calc the pending rewards */
    function _pendingRewards(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = (multiplier * rewardsPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardsPerShare = accRewardsPerShare + ((tokenReward * 1e12 / lpSupply));
        }
        return ((user.amount * accRewardsPerShare)/1e12) - user.rewardDebt;
    }

    // View function to see pending tier rewards for this pool 
    function pendingTierRewards(uint256 _pid, address _user)  external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 pending = _pendingRewards(_pid,_user);

        return pending * (pool.tierMultiplier/1 ether);
    }

    /* @dev Update reward variables for all pools. Be careful of gas spending! */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /* @dev Update reward variables of the given pool to be up-to-date */
    event PoolUpdated(uint256 indexed pid, uint256 accRewardsPerShare, uint256 lastRewardBlock);
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0 || pool.allocPoint == 0 || pool.totalStakers == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = (multiplier * rewardsPerBlock * pool.allocPoint) / totalAllocPoint;

        rewardToken.mint(feeAddress, tokenReward/10);
        rewardToken.mint(address(this), tokenReward);

        pool.accRewardsPerShare = pool.accRewardsPerShare + ((tokenReward * 1e12)/lpSupply);
        pool.lastRewardBlock = block.number;
        emit PoolUpdated(_pid, pool.accRewardsPerShare, pool.lastRewardBlock);
    }

    event Harvested(address indexed user, uint256 indexed pid, uint256 tokens, uint256 points);
    function _harvest(uint256 _pid, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending = ((user.amount * pool.accRewardsPerShare)/1e12) - user.rewardDebt;
        
        if (pending > 0) {
            uint256 points = (pending * pool.tierMultiplier)/1 ether;
            // handle updating tier points
            if(pool.tierMultiplier > 0){
                nftRewardsContract.addPoints(_user, points);
            }
            // send from the contract
            safeTokenTransfer(_user, pending);

            emit Harvested(_user,_pid,pending,points);
        }
    }

    function multiHarvest(uint256[] calldata _pids) public nonReentrant {
        _multiHarvest(msg.sender, _pids);
    }

    function _multiHarvest(address _user, uint256[] calldata _pids) private {

        for (uint256 i = 0; i < _pids.length; ++i) {
            if(userInfo[i][_user].amount > 0){
                updatePool(_pids[i]);
                _harvest(_pids[i],_user);
                userInfo[i][_user].rewardDebt = (userInfo[i][_user].amount * poolInfo[_pids[i]].accRewardsPerShare)/1e12;
            }
        }
    }

    function multiCompound(uint256[] calldata _pids) public nonReentrant {
        uint256 startBalance = rewardToken.balanceOf(msg.sender);
        for (uint256 i = 0; i < _pids.length; ++i) {
            _multiHarvest(msg.sender, _pids);
        }
        uint256 toCompound = rewardToken.balanceOf(msg.sender) - startBalance;
        _deposit(0,toCompound,msg.sender,false);
    }


    event Compounded(address indexed user, uint256 pid, uint256 amount);
    function compound(uint256 _pid) public nonReentrant {
        uint256 startBalance = rewardToken.balanceOf(msg.sender);
        _deposit(_pid,0,msg.sender,false);
        uint256 toCompound = rewardToken.balanceOf(msg.sender) - startBalance;
        _deposit(0,toCompound,msg.sender,false);
        emit Compounded(msg.sender,_pid,toCompound);
    }
   /* function compound(uint256 _pid) public nonReentrant {
        uint256 startBalance = rewardToken.balanceOf(msg.sender);
        updatePool(_pid);
         _harvest(_pid,msg.sender);
        uint256 toCompound = rewardToken.balanceOf(msg.sender) - startBalance;
        _deposit(0,toCompound,msg.sender,false);
        emit Compounded(msg.sender,_pid,toCompound);
    }*/


    /* @dev Harvest and deposit LP tokens into the pool */
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');
        _deposit(_pid,_amount,msg.sender,false);
    }

    function _deposit(uint256 _pid, uint256 _amount, address _addr, bool _isDirect) private {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_addr];

        updatePool(_pid);

        if (user.amount > 0) {
            _harvest(_pid,_addr);
        } else {
            if (_amount > 0) {
                pool.totalStakers += pool.totalStakers+1; 
            }
        }

        if (_amount > 0) {

            if(!_isDirect){
                pool.lpToken.safeTransferFrom(address(_addr), address(this), _amount);
            }
            
            user.amount = user.amount + _amount;

        }

        if(user.firstStake == 0){
            // set the timestamp for the addresses first stake
            user.firstStake = block.timestamp;
        }

        user.rewardDebt = (user.amount * pool.accRewardsPerShare)/1e12;
        emit Deposit(_addr, _pid, _amount);
    }

   

    /* @dev Harvest and withdraw LP tokens from a pool*/
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: no tokens to withdraw");
        updatePool(_pid);
        _harvest(_pid,msg.sender);

        if (_amount > 0) {
            user.amount = user.amount - _amount;

            // check and charge the withdraw fee
            uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);

            uint256 withdrawFee = (_amount * withdrawFeePercent)/10000;

            // subtract the fee from the amount we send
            uint256 toSend = _amount - withdrawFee;

            // transfer the fee
            pool.lpToken.safeTransfer(feeAddress, withdrawFee);
      
            // transfer to user 
            pool.lpToken.safeTransfer(address(msg.sender), toSend);
        }

        if(user.amount == 0){
            // decrement the total stakers
            pool.totalStakers = pool.totalStakers-1; 

            // reset this users first stake
            user.firstStake = 0;
        }
        user.rewardDebt = (user.amount * pool.accRewardsPerShare)/1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /* @dev Withdraw entire balance without caring about rewards. EMERGENCY ONLY */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
            
        // check and charge the withdraw fee
        uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);
        uint256 withdrawFee = (amount * withdrawFeePercent)/10000;

        // subtract the fee from the amount we send
        uint256 toSend = amount - withdrawFee;

        // transfer the fee
        pool.lpToken.safeTransfer(feeAddress, withdrawFee);
  
        // transfer to user 
        pool.lpToken.safeTransfer(address(msg.sender), toSend);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /* @dev Return the current fee */
    function currentFeePercent (address _addr, uint256 _pid) external view returns(uint256){
        return _currentFeePercent(_addr, _pid);
    }

    /* @dev calculate the current fee based on first stake and current timestamp */
    function _currentFeePercent (address _addr, uint256 _pid) internal view returns(uint256){
        // get the time they staked
        uint256 startTime = userInfo[_pid][_addr].firstStake;

        // get the current time
        uint256 currentTime = block.timestamp;

        // check the times
        for (uint256 i = 0; i < feeInfo.length; ++i) {
            uint256 t = startTime + feeInfo[i].timeCheck;
            if(currentTime < t){
                return feeInfo[i].feePercent;
            }
        }

        return defaultFeePercent;
    }

    event LPAddedDirect(address indexed user, uint256 indexed pid, uint directStake, uint256 amoutNativeSent, uint256 amountTokenPost, uint256 amountNativePost, uint256 amountLPPost);
    /* @dev send in any amount of Native to have it paired to LP and auto-staked */
    function directToLp(uint256 _pid) public payable nonReentrant {
        require(isActive,'Not active');
        require(poolInfo[_pid].directStake > 0 ,'No direct stake');
        require(!isSwapping,'Token swap in progress');
        require(!isAddingLp,'Add LP in progress');
        require(msg.value >= minPairAmount, "Not enough Native to swap");

        uint256 liquidity;
        uint256 _amountToken;
        uint256 _amountNative;
        uint256 _amountLP;

        // directStake 1 - stake only the token (use the LPaddress)
        if(poolInfo[_pid].directStake == 1){
            // get the current token balance
            uint256 sasContractTokenBal = poolInfo[_pid].lpToken.balanceOf(address(this));
            _swapNativeForToken(msg.value, address(poolInfo[_pid].lpToken));
            liquidity = poolInfo[_pid].lpToken.balanceOf(address(this)) - sasContractTokenBal;
            _amountToken = liquidity;
        }

        // directStake 2 - pair Native/tokenA 
        if(poolInfo[_pid].directStake == 2){
            // use half the Native to buy the token
            uint256 nativeToSpend = msg.value/2;
            uint256 nativeToPost =  msg.value - nativeToSpend;

            // get the current token balance
            uint256 contractTokenBal = poolInfo[_pid].tokenA.balanceOf(address(this));
           
            // do the swap
            _swapNativeForToken(nativeToSpend, address(poolInfo[_pid].tokenA));

            //new balance
            uint256 tokenToPost = poolInfo[_pid].tokenA.balanceOf(address(this)) - contractTokenBal;

            // add LP
            (,, uint lp) = _addLiquidity(address(poolInfo[_pid].tokenA),tokenToPost, nativeToPost);
            liquidity = lp;

            _amountToken = tokenToPost;
            _amountNative = nativeToPost;
            _amountLP = lp;
        }

        // directStake 3 - pair tokenA/tokenB
        if(poolInfo[_pid].directStake == 3){

            // split the Native
            // use half the Native to buy the tokens
            uint256 nativeForTokenA = msg.value/2;
            uint256 nativeForTokenB =  msg.value - nativeForTokenA;

            // get the current token balances
            uint256 contractTokenABal = poolInfo[_pid].tokenA.balanceOf(address(this));
            uint256 contractTokenBBal = poolInfo[_pid].tokenB.balanceOf(address(this));

            // buy both tokens
            _swapNativeForToken(nativeForTokenA, address(poolInfo[_pid].tokenA));
            _swapNativeForToken(nativeForTokenB, address(poolInfo[_pid].tokenB));

            // get the balance to post
            uint256 tokenAToPost = poolInfo[_pid].tokenA.balanceOf(address(this)) - contractTokenABal;
            uint256 tokenBToPost = poolInfo[_pid].tokenB.balanceOf(address(this)) - contractTokenBBal;

            // pair it
            (,, uint lp) =  _addLiquidityTokens( 
                address(poolInfo[_pid].tokenA), 
                address(poolInfo[_pid].tokenB), 
                tokenAToPost, 
                tokenBToPost
            );
            liquidity = lp;

            _amountToken = tokenAToPost;
            _amountNative = tokenBToPost;
            _amountLP = lp;

        }
        
        emit LPAddedDirect(msg.sender,_pid,poolInfo[_pid].directStake, msg.value,_amountToken, _amountNative, _amountLP);

        // stake it to the contract
        _deposit(_pid,liquidity,msg.sender,true);

    }


    // LP Functions
    // adds liquidity and send it to the contract
    function _addLiquidity(address token, uint256 tokenamount, uint256 nativeamount) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountToken;
        uint amountETH;
        uint liquidity;

       (amountToken, amountETH, liquidity) = pancakeRouter.addLiquidityETH{value: nativeamount}(
            address(token),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;
        return (amountToken, amountETH, liquidity);

    }

    function _addLiquidityTokens(address _tokenA, address _tokenB, uint256 _tokenAmountA, uint256 _tokenAmountB) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountTokenA;
        uint amountTokenB;
        uint liquidity;

       (amountTokenA, amountTokenB, liquidity) = pancakeRouter.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _tokenAmountA,
            _tokenAmountB,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;

        return (amountTokenA, amountTokenB, liquidity);

    }

    function _swapNativeForToken(uint256 amount, address _token) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(_token);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    function _swapTokenForToken(address _tokenA, address _tokenB, uint256 _amount) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    /* @dev Safe token transfer function, just in case if rounding error causes pool to not have enough tokens */
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bal) {
            transferSuccess = rewardToken.transfer(_to, bal);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
        emit SetActive(_isActive);
    }

    event MinPairAmountSet(uint256 minPairAmount);
    function setMinPairAmount(uint256 _minPairAmount) public onlyOwner {
        minPairAmount = _minPairAmount;
        emit MinPairAmountSet(_minPairAmount);
    }

    event DefaultFeeSet(uint256 fee);
    function setDefaultFee(uint256 _defaultFeePercent) public onlyOwner {
        require(_defaultFeePercent <= 500, "fee too high");
        defaultFeePercent = _defaultFeePercent;
        emit DefaultFeeSet(_defaultFeePercent);
    }


    function updateTokenContract(IERC20Minter _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
        rewardToken.approve(address(pancakeRouter), type(uint256).max);
    }

    function setFeeAddress(address _feeAddress) public {
        require(_feeAddress != address(0),'Invalid Address');
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _rewardsPerBlock) public onlyOwner {
        massUpdatePools();
        rewardsPerBlock = _rewardsPerBlock;
        emit UpdateEmissionRate(msg.sender, _rewardsPerBlock);
    }

    /**
     * @dev Update the LpStaking contract address only callable by the owner
     */
    function setNftRewardsContract(INftRewards _nftRewardsContract) public onlyOwner {
        nftRewardsContract = _nftRewardsContract;
    }

    // pull all the tokens out of the contract, needed for migrations/emergencies 
    function withdrawToken() public onlyOwner {
        safeTokenTransfer(feeAddress, rewardToken.balanceOf(address(this)));
    }

    // pull all the native out of the contract, needed for migrations/emergencies 
    function withdrawNative() public onlyOwner {
         (bool sent,) =address(feeAddress).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }


    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
pragma solidity >=0.8.11;

interface IPancakeERC20 {
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
}

interface IPancakeFactory {
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

interface IPancakeRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface INftRewards {
    function getUserTier(address _user)  external view returns (uint256);
    function addPoints(address _addr, uint256 _amount) external;
    function removePoints(address _addr, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Minter is IERC20 {
  function mint(
    address recipient,
    uint256 amount
  )
    external;

  function burn(
    address account,
    uint256 amount
  )
    external;

    function getCurrentTokenId() external;
    function getNextTokenID() external;
}