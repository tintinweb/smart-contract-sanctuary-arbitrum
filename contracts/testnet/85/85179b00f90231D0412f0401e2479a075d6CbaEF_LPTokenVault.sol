/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/LPVaultV1.sol


pragma solidity ^0.8.0;




contract LPTokenVault is Ownable, Pausable {
    IERC20 public token;
    IERC20 public tokenLP;

    uint256 tokenAmountLP;
    uint256 tokenAlreadyDelegated;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balancesLP;

    mapping(address => uint256) public unlockTimesLP;
    address[] public stakers;

    event TokensDeposited(address indexed account, uint256 amount);
    event TokensWithdrawn(address indexed account, uint256 amount);
    event TokensDistributed(uint256 totalTokens);

    constructor(IERC20 _token, IERC20 _tokenLP) {
        token = _token;
        tokenLP = _tokenLP;
    }

    function depositLPTokens(uint256 amount) public whenNotPaused{
        require(amount > 0, "Amount must be greater than zero");
        require(tokenLP.balanceOf(msg.sender) >= amount, "Insufficient LP token balance");

        tokenLP.transferFrom(msg.sender, address(this), amount);
        balancesLP[msg.sender] += amount;
        tokenAmountLP += amount;
        unlockTimesLP[msg.sender] = block.timestamp + 30 days;
        stakers.push(msg.sender);

        emit TokensDeposited(msg.sender, amount);
    }

    function withdrawAllTokens() public whenNotPaused{
        uint256 amountLP = balancesLP[msg.sender];
        uint256 reward = rewards[msg.sender];

        require(amountLP > 0, "No tokens to withdraw");
        require(block.timestamp >= unlockTimesLP[msg.sender], "Tokens are still locked");

       
        tokenLP.transfer(msg.sender, amountLP);
        token.transfer(msg.sender,reward);
   
        tokenAmountLP -= amountLP;
        tokenAlreadyDelegated -= reward;

        balancesLP[msg.sender] = 0;
        rewards[msg.sender] = 0;  


        uint256 index;

        for(uint256 i = 0; i < stakers.length; i++){
            if (msg.sender == stakers[i]){
                index = i;
                break;
            }
        }

        stakers[index] = stakers[stakers.length - 1];
        stakers.pop();
        
        emit TokensWithdrawn(msg.sender, amountLP);

    }

    function withdrawAllTokensWithPenalty() public whenNotPaused{
        uint256 reward = rewards[msg.sender];
        uint256 amountLP = balancesLP[msg.sender];
        uint256 penalty = reward * 50 / 100;        
        
        require(amountLP > 0, "No tokens to withdraw");
        require(block.timestamp < unlockTimesLP[msg.sender], "Tokens are already unlocked");
        

        tokenLP.transfer(msg.sender, amountLP);
        token.transfer(msg.sender,(reward - penalty));
   
        tokenAmountLP -= amountLP;
        tokenAlreadyDelegated -= reward;

        balancesLP[msg.sender] = 0;
        rewards[msg.sender] = 0;  
        unlockTimesLP[msg.sender] = block.timestamp;

        uint256 index;

        for(uint256 i = 0; i < stakers.length; i++){
            if (msg.sender == stakers[i]){
                index = i;
                break;
            }
        }

        stakers[index] = stakers[stakers.length - 1];
        stakers.pop();

        emit TokensWithdrawn(msg.sender, amountLP);
    }
    function claimRewardTokens() public whenNotPaused{
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No tokens to withdraw");
        require(block.timestamp >= unlockTimesLP[msg.sender], "Tokens are still locked");
        tokenAlreadyDelegated -= reward;
        token.transfer(msg.sender,reward);
   
        rewards[msg.sender] = 0;        
        unlockTimesLP[msg.sender] = block.timestamp + 7 days;
  
        emit TokensWithdrawn(msg.sender, reward);

    } 
    //einfach an den contract senden...alles was bei distribute mehr drauf ist wird anhand des shares verteilt
    //distributor gets the reward
    function distributeTokens() public whenNotPaused{
        uint256 tokenForDistribution = token.balanceOf(address(this)) - tokenAlreadyDelegated;
        require(tokenForDistribution > 0, "Distribution Amount must be greater than zero");
        require(stakers.length > 0, "At least one Staker should be in the vault for distribution");

        uint256 shareForDistributor = tokenForDistribution / 100; // 1 percent for the distributor
        tokenForDistribution -= shareForDistributor;
       
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakerShare = (balancesLP[staker] * tokenForDistribution) / tokenAmountLP;
            rewards[staker] += stakerShare;
        }
        tokenAlreadyDelegated += tokenForDistribution;
        token.transfer(msg.sender, shareForDistributor);

        emit TokensDistributed(tokenForDistribution);
    }
    function getDistributionReward() public view returns (uint256 _distributionReward){
        uint256 shareForDistributor = (token.balanceOf(address(this)) - tokenAlreadyDelegated) / 100; // 1 percent for the distributor
        return shareForDistributor;
    }
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }
    function setLPTokenAddress(address _tokenAddress) public onlyOwner {
        tokenLP = IERC20(_tokenAddress);
    }
}