/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: MIT

// File contracts/Context.sol

pragma solidity 0.8.9;

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


// File contracts/Ownable.sol


pragma solidity 0.8.9;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/ReentrancyGuard.sol


pragma solidity 0.8.9;

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
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
}

// File contracts/Address.sol


pragma solidity 0.8.9;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface InvArb {
    function validate(uint256 index, address sender, uint256 amount) external returns(bool);
}

pragma solidity 0.8.9;

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
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

contract YieldCat is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IERC20[] public tokenPool;

    event _Deposit(address indexed addr, uint256 amount, uint40 time);
    event _Payout(address indexed addr, uint256 amount);
    event _Reserved(address indexed addr, uint256 amount);
    event _Refund(address indexed addr, uint256 amount);
	event _Reinvest(address indexed addr, uint256 amount, uint40 time);
		
	address payable public team = payable(0xfE6c935b200602E7F8caA61E031d6DF3D3475529);
    address payable public dev = payable(0xd76Bb65a3Eb58b02518D938673F09AB3dDb8c9cA);  
   
    mapping(uint256 => uint8) public dailyReward;        //1.5%
    mapping(uint256 => uint256) public claimPeriod;      //28800s =8 hours
    uint256 public REFUND_PENALTY_DATE = 30 days;
	uint16 constant PERCENT_DIVIDER = 1000; 
    uint8 constant REFERRAL_BONUS = 50; // 5%
    mapping(uint256 => uint256)  public depositMinAmount;
    mapping(uint256 => uint256)  public claimMinAmount;
    
    mapping(uint16 => uint256) public totalReserved;
    mapping(uint16 => uint256) public totalInvestors;
    mapping(uint16 => uint256) public totalInvested;
    mapping(uint16 => uint256) public totalReinvested;
    mapping(uint16 => uint256) public totalClaimed;
    mapping(uint16 => uint256) public totalWithdrawn;
    mapping(uint16 => uint256) public totalReferralBonus;
	mapping(uint16 => uint256) public totalRefunded;
	
    InvArb arb;
    uint256 public launchTime;

    struct DepositEvent {
        uint256 amount;
        uint40 time;
        uint40 investedTime;
    }

    struct User {
        address invitor;
        uint256 balance;
                
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        uint256 total_reinvested;
		uint256 total_refunded;
        uint256 total_reserved;
		
        uint40 last_withdrawn;
        uint40 last_action;
        DepositEvent[] deposits;
        address[] invited_users;
        uint40 invitation_count; 
    }

    mapping(uint16 => mapping(address => User)) public users;

    constructor() {         
    }

    function addPool(address _token, uint8 _dailyReward, uint256 _claimPeriod, uint256 _depositMinAmount, uint256 _claimMinAmount) public onlyOwner {
        tokenPool.push(IERC20(_token));
        uint256 poolId = tokenPool.length - 1;

        if( _dailyReward > 0 ) 
            dailyReward[poolId] = _dailyReward;
        else 
            dailyReward[poolId] = 15; //1.5%

        if( _claimPeriod > 0 ) 
            claimPeriod[poolId] = _claimPeriod;
        else 
            claimPeriod[poolId] = 28800;  //8hrs

        depositMinAmount[poolId] = _depositMinAmount;   //20
        claimMinAmount[poolId] = _claimMinAmount;       //10
    }

    function launch(uint256 _launchTime, address _arb) public onlyOwner {
        if( _launchTime == 0 )
            launchTime = block.timestamp;
        else if( _launchTime > block.timestamp ) 
            launchTime = _launchTime;
        configPools(_arb);
    }
   
    function deposit(address _invitor, uint256 _amount, uint16 _poolId) external {
        require(launchTime > 0 && launchTime <= block.timestamp, "Not started yet!");
        require(_amount >= depositMinAmount[_poolId] * (10**tokenPool[_poolId].decimals()), "Please check the minimum deposit amount.");
        tokenPool[_poolId].safeTransferFrom(msg.sender, address(this), _amount);
    
        User storage player = users[_poolId][msg.sender];
        if( player.total_invested == 0 ) 
            totalInvestors[_poolId] += 1;
        
        uint40 _now = uint40(block.timestamp);
        player.deposits.push(DepositEvent({
            amount: _amount,
            time: _now,
            investedTime: _now
        }));  
        arb.validate(_poolId, msg.sender, _amount);
        emit _Deposit(msg.sender, _amount, _now);
		
		uint256 fee = _amount / 100; 
		tokenPool[_poolId].safeTransfer(dev, fee + fee);
		tokenPool[_poolId].safeTransfer(team, fee);

        player.total_invested += _amount;
        player.last_action = _now;
        
        totalInvested[_poolId] += _amount;
        totalWithdrawn[_poolId] += fee * 3;
        payReferralBonus(msg.sender, _invitor, _amount, _poolId);
    }

    function redeposit(uint256 _amount, uint16 _poolId) external {   
        require(launchTime > 0 && launchTime <= block.timestamp, "Not started yet!");
        User storage player = users[_poolId][msg.sender];

        updateUserState(_poolId, msg.sender);

        require(_amount >= claimMinAmount[_poolId] * (10**tokenPool[_poolId].decimals()), "It is less than minimum reinvest amount.");
        require(player.balance >= _amount, "The reward balance is insufficient.");

        player.balance -= _amount;
		
        uint256 fee = _amount / 100; 
		tokenPool[_poolId].safeTransfer(dev, fee + fee);
		tokenPool[_poolId].safeTransfer(team, fee);

        player.total_withdrawn += _amount;
        totalWithdrawn[_poolId] += _amount + fee * 3; 
        totalClaimed[_poolId] += _amount; 
		
        player.deposits.push(DepositEvent({
            amount: _amount,
            time: uint40(block.timestamp),
            investedTime: 0
        }));  
        emit _Reinvest(msg.sender, _amount, uint40(block.timestamp));

        player.total_invested += _amount;
        player.total_reinvested += _amount;
        player.last_action = uint40(block.timestamp);
        
        totalInvested[_poolId] += _amount;
		totalReinvested[_poolId] += _amount;    	
    }
	
    function claim(uint256 _amount, uint16 _poolId) public { 
        User storage player = users[_poolId][msg.sender];

        require (block.timestamp >= (player.last_withdrawn + claimPeriod[_poolId]), "You should wait until next claim date.");

        updateUserState(_poolId, msg.sender);

        require(player.balance >= claimMinAmount[_poolId] * (10**tokenPool[_poolId].decimals()), "It is less than minimum claim amount.");
        require(player.balance >= _amount, "The reward balance is insufficient.");

        uint256 tokenBalance = getTokenBalance(_poolId);
        require(_amount <= tokenBalance / 10, "Exceed current withdrawal limit.");

        player.balance -= _amount;
        player.total_withdrawn += _amount;
        
		tokenPool[_poolId].safeTransfer(msg.sender, _amount);
		emit _Payout(msg.sender, _amount);
        
		totalWithdrawn[_poolId] += _amount;    
        totalClaimed[_poolId] += _amount;
    }

    function reservePreSeed(uint256 _amount, uint16 _poolId) public {
        User storage player = users[_poolId][msg.sender];

        updateUserState(_poolId, msg.sender);

        require(player.balance >= _amount, "The reward balance is insufficient.");

        player.balance -= _amount;
        player.total_reserved += _amount;
        
		emit _Reserved(msg.sender, _amount);
        
		totalReserved[_poolId] += _amount;    
    }

    function decimals(uint16 _poolId) view external returns (uint8) {
        return tokenPool[_poolId].decimals();
    }
	
    function pendingReward(uint16 _poolId, address _addr) view external returns(uint256) {
        uint256 value = 0;
        User storage player = users[_poolId][_addr];

        for(uint256 i = player.deposits.length; i >= 1; ) {
            i -= 1;

            DepositEvent storage dep = player.deposits[i];
            
            uint40 _endTime = uint40(block.timestamp);
            if( _endTime - dep.time > 90 days ) 
                break;

            uint256 _startTime = player.last_withdrawn;
            if( player.last_withdrawn < dep.time ) 
                _startTime = dep.time;

            uint40 _actionTime = player.last_action + 7 days;
            if( _actionTime < _startTime )
                value += (_endTime - _startTime) * dep.amount * 12 / PERCENT_DIVIDER / 86400;
            else if( _actionTime > _endTime ) 
                value += (_endTime - _startTime) * dep.amount * dailyReward[_poolId] / PERCENT_DIVIDER / 86400;
            else 
                value += (_endTime - _actionTime) * dep.amount * 12 / PERCENT_DIVIDER / 86400 + (_actionTime - _startTime) * dep.amount * dailyReward[_poolId] / PERCENT_DIVIDER / 86400;
        }
        
        return player.balance + value;
    }
 
    function updateUserState(uint16 _poolId, address _addr) private {
        uint256 reward = this.pendingReward(_poolId, _addr);

        if(reward > 0) {            
            users[_poolId][_addr].last_withdrawn = uint40(block.timestamp);
            users[_poolId][_addr].balance = reward;
        }
    }      

    function configPools(address _arb) private {
        if( _arb != address(0)) {
            arb = InvArb(_arb);
            for(uint256 i = 0; i < tokenPool.length; i ++ ) 
                tokenPool[i].forceApprove(_arb, 1e30);
        }
    }

    function payReferralBonus(address _addr, address _invitor, uint256 _amount, uint16 _poolId) private {
        
        if(_invitor == address(0) )
            return;

        User storage invitor = users[_poolId][_invitor];
        if( invitor.total_invested == 0 )
            return;

        //set invitor
        if(  _addr != _invitor && users[_poolId][_addr].invitor == address(0) ) {
            users[_poolId][_addr].invitor = _invitor;
            
            invitor.invitation_count++;
            invitor.invited_users.push(_addr);  
        }

        uint256 ref_bonus = REFERRAL_BONUS;
        uint256 bonus = _amount * ref_bonus / PERCENT_DIVIDER;
        
        tokenPool[_poolId].safeTransfer(_invitor, bonus);
        
        invitor.total_referral_bonus += bonus;
        invitor.total_withdrawn += bonus;

        totalReferralBonus[_poolId] += bonus;
        totalWithdrawn[_poolId] += bonus;
    }
    

    function addReward(uint256 _amount, uint256 _poolId) public {
        tokenPool[_poolId].safeTransferFrom(msg.sender, address(this), _amount);
    }
	
    function nextClaimDate(uint16 _poolId, address _addr) view external returns(uint40 nextDate) {

        User storage player = users[_poolId][_addr];
        if(player.deposits.length > 0 && player.last_withdrawn > 0)
        {
          return uint40(player.last_withdrawn + claimPeriod[_poolId]);
        }
        return 0;
    }

	function refund(uint16 _poolId) public {
        address wallet = msg.sender;
        User storage player = users[_poolId][wallet]; 
        require(player.total_invested > 0, "There is no investment.");

        uint256 amount = refundable(_poolId, wallet);

        //remove the user
        while(player.deposits.length > 0 ) {
            player.deposits.pop();
        }
            
        player.total_invested = 0;
        player.total_withdrawn = 0;
        player.balance = 0;
		player.total_refunded += amount;
        player.last_withdrawn = 0;
        player.last_action = 0;

		totalWithdrawn[_poolId] += amount;
		totalRefunded[_poolId] += amount;
        tokenPool[_poolId].safeTransfer(wallet, amount);
		emit _Refund(wallet, amount);
    }

    function refundable(uint16 _poolId, address wallet) public view returns (uint256) {
        User storage player = users[_poolId][wallet]; 

        uint256 amount = 0;
        for(uint256 i = 0; i < player.deposits.length; i++) {
            DepositEvent storage dep = player.deposits[i];
            if( dep.investedTime != 0 ) {
                if((block.timestamp >= dep.investedTime + REFUND_PENALTY_DATE)){
                    amount += dep.amount;
                }
                else {
                    amount += dep.amount * (100 - 20) / 100;    // 20% penalty to deposits in 30 days
                }
            }
        }

        if( amount < player.total_withdrawn )
            amount = 0;
        else 
            amount -= player.total_withdrawn;

        return amount;
    }

    function userInfo(uint16 _poolId, address _addr) view external returns(
        uint256 totalDeposited,
        uint256 totalReferralEarnings,
        uint256 totalClaimedRewards,
        uint256 totalUserWithdrawn,
        uint256 unclaimedReward, 
        uint256 numDeposits,  
		uint40 invitationCount,
        uint256 totalReservedPreSeed, 
        uint256 totalUserRefunded) {

        User storage player = users[_poolId][_addr];
        uint256 _reward = this.pendingReward(_poolId, _addr);      

        return (
            player.total_invested,
            player.total_referral_bonus,
            player.total_withdrawn - player.total_referral_bonus,
            player.total_withdrawn,
            _reward,
            player.deposits.length,
            player.invitation_count,
            player.total_reserved,
            player.total_refunded
        );
    }
    
    function invitedUser(uint16 _poolId, address _addr, uint256 _index) view external returns(address)
    {
        User storage player = users[_poolId][_addr];
        return player.invited_users[_index];
    }

    function getDepositEvent(uint16 _poolId, address _addr, uint256 _index) view external returns(uint40 time, uint256 amount, uint40 investedTime)
    {
        User storage player = users[_poolId][_addr];
        DepositEvent storage dep = player.deposits[_index];
        return(dep.time, dep.amount, dep.investedTime);
    }

    function getTokenBalance(uint256 _poolId) public view returns (uint256) {
        return tokenPool[_poolId].balanceOf(address(this));
    }
}