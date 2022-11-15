/**
 *Submitted for verification at Arbiscan on 2022-11-15
*/

// File: contracts\interfaces\IRewards.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function setWeight(address _pool, uint256 _amount) external returns(bool);
    function setWeights(address[] calldata _account, uint256[] calldata _amount) external;
    function setDistributor(address _distro, bool _valid) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function addExtraReward(address) external;
    function setRewardHook(address) external;
    function user_checkpoint(address _account) external returns(bool);
    function rewardToken() external view returns(address);
    function rewardMap(address) external view returns(bool);
    function earned(address account) external view returns (uint256);
}

// File: contracts\interfaces\IRewardFactory.sol

pragma solidity 0.8.10;

interface IRewardFactory{
    function CreateMainRewards(address _crv, address _gauge, address _depositToken, uint256 _pid) external returns (address);
}

// File: contracts\interfaces\IStaker.sol

pragma solidity 0.8.10;

interface IStaker{
    function deposit(address _lp, address _gauge, uint256 _amount) external;
    function rescue(address _token, address _to) external;
    function withdraw(address, address, uint256) external;
    function withdrawAll(address, address) external;
    function createLock(uint256, uint256) external;
    function increaseAmount(uint256) external;
    function increaseTime(uint256) external;
    function release() external;
    function claimRewards(address) external;
    function claimFees(address,address) external;
    function claimCrv(address _crv, address _minter, address _gauge, address _to) external;
    function setStashAccess(address, bool) external;
    function vote(uint256,address,bool) external;
    function voteGaugeWeight(address,uint256) external;
    function balanceOfPool(address) external view returns (uint256);
    function operator() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
}

// File: contracts\interfaces\IFeeDistro.sol

pragma solidity 0.8.10;

interface IFeeDistro {
   function processFees() external;
}

// File: contracts\interfaces\IPoolFactory.sol

pragma solidity 0.8.10;

interface IPoolFactory {
    function is_valid_gauge(address) external view returns (bool);
}

// File: contracts\interfaces\IRewardManager.sol

pragma solidity 0.8.10;

interface IRewardManager {
    function rewardHook() external view returns(address);
    function cvx() external view returns(address);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin\contracts\utils\Address.sol


pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol


pragma solidity ^0.8.0;


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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\Booster.sol

pragma solidity 0.8.10;
/*
This is the main contract which will have operator role on the VoterProxy.
Handles pool creation, deposits/withdraws, as well as other managment functions like factories/managers/fees
*/
contract Booster{
    using SafeERC20 for IERC20;

    uint256 public fees = 1700; //platform fees
    uint256 public constant MaxFees = 2500; //hard code max fees
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public owner; //owner
    address public pendingOwner; //pending owner
    address public poolManager; //add and shutdown pools
    address public rescueManager; //specific role just for pulling non-lp/gauge tokens from voterproxy
    address public rewardManager; //controls rewards
    address public immutable staker; //voter proxy
    address public rewardFactory; //factory for creating main reward/staking pools
    address public feeDeposit; //address where fees are accumulated

    bool public isShutdown; //flag if booster is shutdown or not

    struct PoolInfo {
        address lptoken; //the curve lp token
        address gauge; //the curve gauge
        address rewards; //the main reward/staking contract
        bool shutdown; //is this pool shutdown?
        address factory; //a reference to the curve factory used to create this pool (needed for minting crv)
    }


    PoolInfo[] public poolInfo;//list of convex pools, index(pid) -> pool
    mapping(address => address) public factoryCrv;//map defining CRV token used by a Curve factory
    mapping(address => bool) public activeMap;//map defining if a curve gauge/lp token is already being used or not
    mapping(uint256 => uint256) public shutdownBalances; //lp balances of a shutdown pool, index(pid) -> lp balance

    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);
    event SetPendingOwner(address indexed _address);
    event OwnerChanged(address indexed _address);
    event CrvFactorySet(address indexed _factory, address _crv);

    constructor(address _staker) {
        isShutdown = false;
        staker = _staker;
        owner = msg.sender;
        poolManager = msg.sender;
        rescueManager = msg.sender;
    }


    /// SETTER SECTION ///

    //set next pending owner. owner must accept
    function setPendingOwner(address _po) external {
        require(msg.sender == owner, "!auth");
        pendingOwner = _po;
        emit SetPendingOwner(_po);
    }

    //claim ownership
    function acceptPendingOwner() external {
        require(msg.sender == pendingOwner, "!p_owner");

        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnerChanged(owner);
    }

    //set CRV token address used by a specific Curve pool factory.
    //While CRV could be set as immutable, there is no guarantee that a side chain token won't be changed.
    //(for example a new/different bridge platform is used)
    function setFactoryCrv(address _factory, address _crv) external {
        require(msg.sender == owner, "!auth");
        require(_factory != address(0) && _crv != address(0), "invalid");
        factoryCrv[_factory] = _crv;

        emit CrvFactorySet(_factory, _crv);
    }

    //set a pool manager
    //note: only the pool manager can relinquish control
    function setPoolManager(address _poolM) external {
        require(msg.sender == poolManager, "!auth");
        poolManager = _poolM;
    }

    //set a rescue manager for tokens
    //set by owner. separate role though in case something needs to be streamlined like claiming outside rewards.
    function setRescueManager(address _rescueM) external {
        require(msg.sender == owner, "!auth");
        rescueManager = _rescueM;
    }

    //set reward manager
    //can add extra rewards and reward hooks on pools
    function setRewardManager(address _rewardM) external {
        require(msg.sender == owner, "!auth");
        require(IRewardManager(_rewardM).rewardHook() != address(0), "!no hook");
        require(IRewardManager(_rewardM).cvx() != address(0), "!no cvx");

        rewardManager = _rewardM;
    }

    //set factories used when deploying new reward/token contracts
    function setRewardFactory(address _rfactory) external {
        require(msg.sender == owner, "!auth");
        
        rewardFactory = _rfactory;
    }

    //set address that receives platform fees
    function setFeeDeposit(address _deposit) external {
        require(msg.sender == owner, "!auth");
        
        feeDeposit = _deposit;
    }

    //set platform fees
    function setFees(uint256 _platformFees) external{
        require(msg.sender == owner, "!auth");
        require(_platformFees <= MaxFees, ">MaxFees");

        fees = _platformFees;
    }

    //rescue a token from the voter proxy
    //token must not be an lp or gauge token
    function rescueToken(address _token, address _to) external{
        require(msg.sender==rescueManager, "!auth");

        IStaker(staker).rescue(_token, _to);
    }

    /// END SETTER SECTION ///

    //get pool count
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //create a new pool
    function addPool(address _lptoken, address _gauge, address _factory) external returns(bool){
        //only manager
        require(msg.sender==poolManager && !isShutdown, "!add");
        //basic checks
        require(_gauge != address(0) && _lptoken != address(0) && _factory != address(0),"!param");
        //crv check
        require(factoryCrv[_factory] != address(0), "!crv");
        //an unused pool
        require(!activeMap[_gauge] && !activeMap[_lptoken],"already reg");

        //check that the given factory is indeed tied with the gauge
        require(IPoolFactory(_factory).is_valid_gauge(_gauge),"!factory gauge");

        //the next pool's pid
        uint256 pid = poolInfo.length;

        //create a reward contract for rewards
        address newRewardPool = IRewardFactory(rewardFactory).CreateMainRewards(factoryCrv[_factory],_gauge,_lptoken,pid);

        //add the new pool
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                gauge: _gauge,
                rewards: newRewardPool,
                shutdown: false,
                factory: _factory
            })
        );
        
        //set gauge as being used
        activeMap[_gauge] = true;
        //also set the lp token as used
        activeMap[_lptoken] = true;

        //set gauge redirect
        setGaugeRedirect(_gauge, newRewardPool);

        return true;
    }

    //shutdown pool, only call from pool manager
    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==poolManager, "!auth");
        return _shutdownPool(_pid);
    }

    //shutdown pool internal call
    function _shutdownPool(uint256 _pid) internal returns(bool){
        
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.shutdown){
            //already shut down
            return false;
        }  

        uint256 lpbalance = IERC20(pool.lptoken).balanceOf(address(this));

        //withdraw from gauge
        try IStaker(staker).withdrawAll(pool.lptoken,pool.gauge){
        }catch{}

        //lp difference
        lpbalance = IERC20(pool.lptoken).balanceOf(address(this)) - lpbalance;

        //record how many lp tokens were returned
        //this is important to prevent a fake gauge attack which inflates deposit tokens
        //in order to withdraw another pool's legitamate lp tokens
        shutdownBalances[_pid] = lpbalance;

        //flag pool as shutdown
        pool.shutdown = true;
        //reset active map
        activeMap[pool.gauge] = false;
        activeMap[pool.lptoken] = false;
        return true;
    }

    //shutdown this contract.
    //  unstake and pull all lp tokens to this address
    //  only allow withdrawals
    function shutdownSystem() external{
        require(msg.sender == owner, "!auth");
        //flag system as shutdown
        isShutdown = true;

        //shutdown all pools.
        //gas cost could grow too large to do all, in which case individual pools should be shutdown first
        for(uint i=0; i < poolInfo.length; i++){
            _shutdownPool(i);
        }
    }


    //deposit lp tokens and stake
    function deposit(uint256 _pid, uint256 _amount) public returns(bool){
        require(!isShutdown,"shutdown");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        //send to proxy to stake
        address lptoken = pool.lptoken;
        IERC20(lptoken).safeTransferFrom(msg.sender, staker, _amount);

        //stake
        address gauge = pool.gauge;
        require(gauge != address(0),"!gauge setting");
        IStaker(staker).deposit(lptoken,gauge,_amount);

        //mint reward tokens for user
        IRewards(pool.rewards).stakeFor(msg.sender,_amount);
        
        
        emit Deposited(msg.sender, _pid, _amount);
        return true;
    }

    //deposit all lp tokens and stake
    function depositAll(uint256 _pid) external returns(bool){
        address lptoken = poolInfo[_pid].lptoken;
        uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
        deposit(_pid,balance);
        return true;
    }

    //withdraw lp tokens
    function _withdraw(uint256 _pid, uint256 _amount, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address gauge = pool.gauge;


        //pull from gauge if not shutdown
        if (!pool.shutdown) {
            //get prev balance to double check difference
            uint256 lpbalance = IERC20(lptoken).balanceOf(address(this));

            //because of activeMap, a gauge and its lp token can only be assigned to a single unique pool
            //thus claims for withdraw here are enforced to be the correct pair
            IStaker(staker).withdraw(lptoken, gauge, _amount);

            //also check that the amount returned was correct
            //which will safegaurd pools that have been shutdown
            require(IERC20(lptoken).balanceOf(address(this)) - lpbalance >= _amount, "withdraw amount fail");
        }else{
            //if shutdown, tokens will be held in this contract
            //remove from shutdown balances. revert if not enough
            //would only revert if something was wrong with the pool
            //and shutdown didnt return lp tokens
            //thus this is a catch to stop other pools with same lp token from
            //being affected
            shutdownBalances[_pid] -= _amount;
        }

        //return lp tokens
        IERC20(lptoken).safeTransfer(_to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    //allow reward contracts to withdraw directly to user
    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns(bool){
        //require sender to be the reward contract for a given pool
        address rewardContract = poolInfo[_pid].rewards;
        require(msg.sender == rewardContract,"!auth");

        //trust is on the reward contract to properly bookkeep deposit token balance
        //since the reward contract is now the deposit token itself
        _withdraw(_pid,_amount,_to);
        return true;
    }

    //claim crv for a pool from the pool's factory and send to rewards
    function claimCrv(uint256 _pid, address _gauge) external{
        //can only be called by the pool's reward contract
        address rewardContract = poolInfo[_pid].rewards;
        require(msg.sender == rewardContract,"!auth");

        //claim crv and redirect to the reward contract
        address _factory = poolInfo[_pid].factory;
        IStaker(staker).claimCrv(factoryCrv[_factory], _factory, _gauge, rewardContract);
    }

    //set a gauge's redirect setting to claim extra rewards directly to a reward contract 
    //instead of being pulled to the voterproxy/staker contract 
    function setGaugeRedirect(address _gauge, address _rewards) internal returns(bool){
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("set_rewards_receiver(address)")), _rewards);
        IStaker(staker).execute(_gauge,uint256(0),data);
        return true;
    }

    //given an amount of crv, calculate fees
    function calculatePlatformFees(uint256 _amount) external view returns(uint256){
        uint256 _fees = _amount * fees / FEE_DENOMINATOR;
        return _fees;
    }
}