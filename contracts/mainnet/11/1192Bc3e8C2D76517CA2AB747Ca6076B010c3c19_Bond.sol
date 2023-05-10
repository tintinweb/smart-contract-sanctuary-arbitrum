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

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}

interface IRouter {
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);
    function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, Route[] calldata routes, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSimple(uint amountIn, uint amountOutMin, address tokenFrom, address tokenTo, bool stable, address to, uint256 deadline) external returns (uint[] memory amounts);
}

struct Route {
    address from;
    address to;
    bool stable;
}

/// @notice Buy back AGI and burn for deflation
/// @notice Only using WETH to buy back AGI
contract Bond is ReentrancyGuard{
    /// @notice Auragi token
    IERC20 public immutable AGI;
    /// @notice WETH token
    IWETH public immutable WETH;
    /// @notice Auragi router
    IRouter public immutable router;
    address public treasury;

    /// @notice duration between each burn
    uint internal constant DAY = 1 days;
    uint internal constant BURN_DURATION = 1 days;
    uint internal constant BURN_PERCENT = 2;    // 2%
    uint internal constant MAX_DURATION = 100/BURN_PERCENT;

    uint public wethBurned = 0;
    uint public agiBurned = 0;
    uint public ethDeposited = 0;
    uint public agiAllocated = 0;
    uint internal constant REFERRAL_BONUS = 5;       // 5%
    uint internal constant TOKEN_BONUS_PER_DAY = 5;  // 5%
    uint internal constant VEST_DURATION = 3;        // 3 days

    /// @notice Mapping of addresses who have Participated
    mapping(address => uint) public userBonds;
    mapping(address => mapping(uint => UserInfo)) public userBondInfos;  //users addresse => index => info

    /// @notice Mapping of referrals
    mapping(address => address) public referrals;   // user => referrer
    mapping(address => uint) public refFriends;     // referrer => friends
    mapping(address => uint) public refEarned;      // referrer => earned

    uint public startTime = 1683763200; // Thu May 11 2023 00:00:00 GMT+0000
    uint public endTime = startTime + 14 days;
    uint public lastBurned = startTime - 1 days;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    struct UserInfo{
        uint baseAmount;
        uint maxAmount;
        uint startTime;
        bool isClaimed;
        uint claimedAmount;
    }

    /// ============ Events ============
    event Burned(address from, uint256 wethAmount, uint256 agiAmount);
    event Deposited(address from, uint index, uint256 wethAmount, uint256 agiAmount);
    event Claimed(address user, uint256 index, uint256 agiAmount);

    constructor(address _agi, address _weth, address _router, address _treasury) {
        AGI = IERC20(_agi);
        WETH = IWETH(_weth);
        router = IRouter(_router);
        treasury = _treasury;
        WETH.approve(address(router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    modifier onlyBurnOnceTimePerDuration() {
        require(burnDurationsAvailable() > 0, "ALREADY_BURNED_THIS_DAY");
        _;
    }

    modifier onlyBondTime() {
        require(startTime < block.timestamp && block.timestamp < endTime, "NOT_BOND_TIME");
        _;
    }

    /// @notice using 2%/day balance WETH to buy back AGI token and burn each BURN_DURATION
    function buyBackAndBurn(Route[] calldata routes) external onlyBurnOnceTimePerDuration {
        uint _wethAmount = burnAmountAvailable();
        uint _agiAmount = 0;
        require(_wethAmount > 0, "Zero");

        (uint amountOut, bool stable) = router.getAmountOut(_wethAmount, address(WETH), address(AGI));

        if(routes.length > 0){
            require(routes[0].from == address(WETH) && routes[routes.length - 1].to == address(AGI), 'INVALID_PATH');
            uint[] memory amountsOut = router.getAmountsOut(_wethAmount, routes);
            if(amountsOut[amountsOut.length - 1] > amountOut){
                amountsOut = router.swapExactTokensForTokens(_wethAmount, amountsOut[amountsOut.length - 1] * 98 / 100, routes, address(DEAD), block.timestamp + 1000);
                _agiAmount = amountsOut[amountsOut.length - 1];
            }
        }

        if(amountOut > 0 && _agiAmount == 0){
            uint[] memory amountsOut = router.swapExactTokensForTokensSimple(_wethAmount, amountOut * 98 / 100, address(WETH), address(AGI), stable, address(DEAD), block.timestamp + 1000);
            _agiAmount = amountsOut[amountsOut.length - 1];
        }

        require(_agiAmount > 0, "AGI too small");
        agiBurned += _agiAmount;
        wethBurned += _wethAmount;
        lastBurned = block.timestamp / BURN_DURATION * BURN_DURATION;
        emit Burned(msg.sender, _wethAmount, _agiAmount);
    }

    /// @notice Deposit tokens to join BuyBackAndBurn program and receive rewards
    function deposit(uint amountIn, uint minAmountOut, Route[] calldata routes, address ref) external onlyBondTime nonReentrant {
        require(amountIn > 0, "Zero");
        if(routes.length > 0){
            require(routes[0].from != address(AGI), "FROM AGI");
            require(routes[routes.length - 1].to == address(WETH), 'INVALID_PATH');

            IERC20 token = IERC20(routes[0].from);
            token.transferFrom(msg.sender, address(this), amountIn);

            if(token.allowance(address(this), address(router)) < amountIn){
                token.approve(address(router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            }

            uint[] memory amountOuts = router.swapExactTokensForTokens(amountIn, minAmountOut, routes, address(this), block.timestamp + 1000);
            _updateForDeposit(msg.sender, ref, amountOuts[amountOuts.length - 1]);
        }else{
            WETH.transferFrom(msg.sender, address(this), amountIn);
            _updateForDeposit(msg.sender, ref, amountIn);
        }
    }

    function depositETH(address ref) external payable onlyBondTime nonReentrant {
        uint _ethAmount= msg.value;
        require(_ethAmount > 0, "Zero");
        WETH.deposit{value: _ethAmount}();
        _updateForDeposit(msg.sender, ref, _ethAmount);
    }

    /// @notice Calculate reward for users participate BuyBackAndBurn program
    function _updateForDeposit(address user, address ref, uint wethAmount) internal {
        uint _baseEarn = getDepositETHEarn(wethAmount);
        uint _maxEarn = _baseEarn * (100 + TOKEN_BONUS_PER_DAY * VEST_DURATION) / 100;
        require(_maxEarn <= availableAGi(), "over amount");
        uint _index = userBonds[user] + 1;
        userBonds[user] = _index;
        userBondInfos[user][_index] = UserInfo(_baseEarn, _maxEarn, block.timestamp, false, 0);

        ethDeposited += wethAmount;
        agiAllocated += _maxEarn;

        _referralBonus(msg.sender, ref, wethAmount);
        emit Deposited(user, _index, wethAmount, _maxEarn);
    }

    function _referralBonus(address user, address ref, uint wethAmount) internal {
        if(referrals[user] == address(0)){
            if(user != ref && ref != address(0)){
                referrals[user] = ref;
                refFriends[ref] += 1;
            }
        }
        if(referrals[user] != address(0)){
            uint refReward = wethAmount * REFERRAL_BONUS / 100;
            refEarned[referrals[user]] += refReward;
            WETH.transfer(referrals[user], refReward);
        }
    }

    function claim(uint index) external nonReentrant {
        address user = msg.sender;
        UserInfo storage _userinfo = userBondInfos[user][index];
        require(!_userinfo.isClaimed, "Claimed");
        (uint earned, , , ,) = getBondInfo(user, index);
        _userinfo.isClaimed = true;
        _userinfo.claimedAmount = earned;
        agiAllocated -= _userinfo.maxAmount;

        AGI.transfer(msg.sender, earned);
        emit Claimed(user, index, earned);
    }

    function getBondInfo(address user, uint index) public view returns(uint, uint, uint, uint, bool){
        UserInfo memory _userinfo = userBondInfos[user][index];
        uint earned = 0;
        if(_userinfo.isClaimed){
            earned = _userinfo.claimedAmount;
        }else{
            uint duration = (block.timestamp - _userinfo.startTime)/DAY;
            duration = duration < VEST_DURATION ? duration : 0;
            earned = _userinfo.baseAmount * (100 + duration * TOKEN_BONUS_PER_DAY)/100;
        }
       
        return (earned, _userinfo.baseAmount, _userinfo.maxAmount, _userinfo.startTime, _userinfo.isClaimed);
    }

    function getDepositEarn(uint amount, Route[] calldata routes) public view returns(uint) {
        require(routes[0].from != address(AGI) && routes[routes.length - 1].to == address(WETH), 'INVALID_PATH');
        uint[] memory amountsOut = router.getAmountsOut(amount, routes);

        return getDepositETHEarn(amountsOut[amountsOut.length - 1]);
    }

    function getDepositETHEarn(uint ethAmount) public view returns(uint) {
        (uint amount, ) = router.getAmountOut(ethAmount, address(WETH), address(AGI));
        return amount;
    }

    function wrapETH() external {
        require(address(this).balance > 0, "Zero");
        WETH.deposit{value: address(this).balance}();    
    }

    function wethBalance() public view returns(uint){
        return WETH.balanceOf(address(this));
    }

    function burnDurationsAvailable() public view returns(uint){
        return (block.timestamp - lastBurned)/BURN_DURATION > MAX_DURATION ? MAX_DURATION : (block.timestamp - lastBurned)/BURN_DURATION;
    }

    function burnAmountAvailable() public view returns(uint){
        return wethBalance() * burnDurationsAvailable() * BURN_PERCENT/100;
    }

    function availableAGi() public view returns(uint){
        return AGI.balanceOf(address(this)) - agiAllocated;
    }

    /// @notice Withdraw remain tokens to team's wallet after airdrop ended
    function withdraw() external {
        require(block.timestamp > endTime, "NOT_END");
        uint256 _amount = availableAGi();
        AGI.transfer(treasury, _amount);
    }
}