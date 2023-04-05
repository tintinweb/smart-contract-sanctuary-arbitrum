/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IArbiDexRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface ISmartChefInitializable {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }
    function userInfo(address user) external view returns (uint256, uint256);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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

contract AutoCompound is Ownable, ReentrancyGuard {
    // The address of the treasury where all of the deposit and performance fees are sent
    address public treasury;

    // The address of the router that is used for conducting swaps
    address public router;

    // The address of the underlying staker where the deposits and withdrawals are made
    address public staker;

    // The reward token
    address public rewardToken;

    // The staked token
    address public stakedToken;

    // The address of the USDC token
    address USDC;

    // The fee associated with depositing into the Auto Compounder
    uint256 public depositFee = 100;

    // The performance fee associated whenever the farm/pool is Auto Compounded
    uint256 public performanceFee = 450;

    // The total supply of staked tokens, that have be deposited by users
    uint256 totalSupply;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
    }

    constructor(
        address _treasury,
        address _router,
        address _staker,
        address _usdc,
        address _rewardToken,
        address _stakedToken
    ) {
        treasury = _treasury;
        router = _router;
        staker = _staker;
        USDC = _usdc;
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;

        // Generate approvals
        IERC20(_stakedToken).approve(staker, type(uint256).max);
        IERC20(_stakedToken).approve(router, type(uint256).max);
        IERC20(_rewardToken).approve(router, type(uint256).max);
    }

    event Deposit(address indexed user, uint256 amount);
    event TokenRecovery(address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function harvest() public {
        if (totalSupply <= 0) {return;}
        ISmartChefInitializable(staker).withdraw(0);

        uint256 harvested = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeAmount = (harvested * performanceFee)/1000;
        harvested = harvested - feeAmount;
        IERC20(rewardToken).transfer(treasury, feeAmount);

        address[] memory path;
        if (rewardToken != USDC) {
            path[0] = rewardToken; path[1] = USDC; path[2] = stakedToken;
        } else {
            path[0] = rewardToken; path[1] = stakedToken;
        }

        uint256[] memory amounts = IArbiDexRouter(router).getAmountsOut(harvested, path);
        uint256 amountOutMin = (amounts[amounts.length-1] * 90)/100;
        IArbiDexRouter(router).swapExactTokensForTokens(harvested, amountOutMin, path, address(this), block.timestamp+120);

        uint256 compounded = IERC20(stakedToken).balanceOf(address(this));
        ISmartChefInitializable(staker).deposit(compounded);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Amount to deposit must be greater than zero");

        harvest();

        IERC20(stakedToken).transferFrom(address(msg.sender), address(this), _amount);
        uint256 feeAmount = (_amount * depositFee)/1000;
        _amount = _amount - feeAmount;
        user.amount += _amount;
        totalSupply += _amount;

        IERC20(stakedToken).transfer(treasury, feeAmount);

        ISmartChefInitializable(staker).deposit(_amount);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        require(_amount > 0, "Amount to withdraw cannot be zero");

        harvest();

        if (_amount > 0 && _amount <= user.amount) {
            user.amount = user.amount - _amount;
            uint256 adjustedAmount = (user.amount * getTotalSupply()) / totalSupply; 
            ISmartChefInitializable(staker).withdraw(adjustedAmount);
            IERC20(stakedToken).transfer(address(msg.sender), adjustedAmount);
        }

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Returns the adjusted share price
    */
    function adjustedTokenPerShare() public view returns (uint256 _amount) {
        return ((1 * (10 ** 18)) * getTotalSupply()) / totalSupply;
    }
    
    /*
     * @notice Returns the total supply of the staked token in this contract and the underlying staker
    */
    function getTotalSupply() public view returns (uint256 _amount) {
        (uint256 supply, ) = ISmartChefInitializable(staker).userInfo(address(this));
        supply += IERC20(stakedToken).balanceOf(address(this));
        return supply;
    }

    /*
     * @notce Recover a token that was accidentally sent to this contract
     * @param _token: The token that needs to be retrieved
     * @param _amount: The amount of tokens to be recovered
    */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Operations: Cannot be zero address");
        require(_token != stakedToken, "Operations: Cannot be staked token");
        require(_token != rewardToken, "Operations: Cannot be reward token");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Operations: Amount to transfer too high");
        IERC20(_token).transfer(treasury, _amount);
    }

    /*
     * @notce update the treasury's address
     * @param _treasury: New address that should receive treasury fees
    */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Address cannot be null");
        require(_treasury != treasury, "Address provided is the same as current");
        treasury = _treasury;
    }

    /*
     * @notce Update the deposit fee
     * @param _amount: New amount for the deposit fee
    */
    function setDepositFee(uint256 _amount) external onlyOwner {
        require(_amount >= 10, "Operations: Invalid deposit fee amount");
        require(_amount <= 500, "Operations: Invalid deposit fee amount");
        depositFee = _amount;
    }

    /*
     * @notce Update the performance fee
     * @param _amount: New amount for the performance fee
    */
    function setPerformanceFee(uint256 _amount) external onlyOwner {
        require(_amount >= 200, "Operations: Invalid performance fee amount");
        require(_amount <= 500, "Operations: Invalid performance fee amount");
        performanceFee = _amount;
    }
}