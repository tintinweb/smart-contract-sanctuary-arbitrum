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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
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
contract BuyBackAndBurn {
    /// @notice Auragi token
    IERC20 public immutable AGI;
    /// @notice WETH token
    IWETH public immutable WETH;
    /// @notice Auragi router
    IRouter public immutable router;

    /// @notice duration between each burn
    uint internal constant BURN_DURATION = 1 days;
    uint internal constant BURN_PERCENT = 1;    // 1%
    uint public lastBurned = block.timestamp;
    uint public wethBurned = 0;
    uint public agiBurned = 0;
    uint public totalETHDeposit = 0;
    uint public totalAGIVestRemain = 0;

    uint internal constant REFERRAL_BONUS = 5; // 5%
    uint internal constant TOKEN_BONUS = 5;    // 5%
    uint internal constant VEST_DURATION = 5 days;
    uint internal constant DAY = 1 days;
    /// @notice Mapping of addresses who have Participated
    mapping(address => uint) public userParticipates;

    /// @notice Mapping users addresse => index => info
    mapping(address => mapping(uint => UserInfo)) public userParticipateInfos;

    struct UserInfo{
        uint vestAmount;
        uint startTime;
        uint claimed;
    }

    /// ============ Events ============
    event Burned(address from, uint256 wethAmount, uint256 agiAmount);
    event Deposited(address from, uint256 amount);

    constructor(address _agi, address _weth, address _router) {
        AGI = IERC20(_agi);
        WETH = IWETH(_weth);
        router = IRouter(_router);
        WETH.approve(address(router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    modifier onlyBurnOnceTimePerDuration() {
        require(burnDurationsAvailable() > 0, "ALREADY_BURNED_THIS_DAY");
        _;
    }

    /// @notice using 1%/day balance WETH to buy back AGI token and burn each BURN_DURATION
    function buyBackAndBurn(Route[] calldata routes) external onlyBurnOnceTimePerDuration {
        uint _wethAmount = wethBalance() * burnDurationsAvailable() * BURN_PERCENT/100;
        uint _agiAmount = 0;

        require(_wethAmount > 0, "Zero");

        (uint amountOut, bool stable) = router.getAmountOut(_wethAmount, address(WETH), address(AGI));
        if(routes.length > 0){
            require(routes[routes.length - 1].to == address(AGI), 'INVALID_PATH');
            uint[] memory amountsOut = router.getAmountsOut(_wethAmount, routes);
            if(amountsOut[amountsOut.length - 1] > amountOut){
                amountsOut = router.swapExactTokensForTokens(_wethAmount, amountsOut[amountsOut.length - 1] * 98 / 100, routes, address(0), block.timestamp + 1000);
                _agiAmount = amountsOut[amountsOut.length - 1];
            }
        }

        if(_agiAmount == 0){
            uint[] memory amountsOut = router.swapExactTokensForTokensSimple(_wethAmount, amountOut * 98 / 100, address(WETH), address(AGI), stable, address(this), block.timestamp + 1000);
            _agiAmount = amountsOut[amountsOut.length - 1];
        }

        agiBurned += _agiAmount;
        wethBurned += _wethAmount;
        lastBurned = block.timestamp / BURN_DURATION * BURN_DURATION;
        emit Burned(msg.sender, _wethAmount, _agiAmount);
    }

    /// @notice Deposit tokens to join BuyBackAndBurn program and receive rewards
    function deposit(uint amountIn, uint minAmountOut, Route[] calldata routes, address ref) external {
        require(amountIn > 0, "Zero");
        require(routes[0].from != address(AGI), "!AGI");
        require(routes[routes.length - 1].to == address(WETH), 'INVALID_PATH');

        IERC20 token = IERC20(routes[0].from);
        _safeTransferFrom(address(token), msg.sender, address(this), amountIn);

        if(token.allowance(address(this), address(router)) < amountIn){
            token.approve(address(router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }

        uint[] memory amountOuts = router.swapExactTokensForTokens(amountIn, minAmountOut, routes, address(this), block.timestamp + 1000);
        _calculateDeposit(amountOuts[amountOuts.length - 1], msg.sender, ref);
        emit Deposited(msg.sender, amountIn);
    }

    function depositETH(address ref) external payable {
        uint _ethAmount= msg.value;
        require(_ethAmount > 0, "Zero");
        WETH.deposit{value: _ethAmount}();
        _calculateDeposit(_ethAmount, msg.sender, ref);
        emit Deposited(msg.sender, _ethAmount);
    }

    function claim() external {
        address sender = msg.sender;
        uint count = userParticipates[sender];
        uint earned = 0;
        for(uint i = 0; i < count; i++){
            UserInfo storage _userinfo = userParticipateInfos[sender][i+1];
            uint duration = (block.timestamp - _userinfo.startTime)/DAY * DAY;
            duration = duration < VEST_DURATION ? duration : VEST_DURATION;
            uint vestedAmount = _userinfo.vestAmount * duration / VEST_DURATION;
            earned += vestedAmount - _userinfo.claimed;
            _userinfo.claimed = vestedAmount;
        }
        AGI.transfer(msg.sender, earned);
        totalAGIVestRemain -= earned;
    }

    function getEarned(address user) public view returns(uint){
        uint count = userParticipates[user];
        uint earned = 0;
        for(uint i = 0; i < count; i++){
            UserInfo memory _userinfo = userParticipateInfos[user][i+1];
            uint duration = (block.timestamp - _userinfo.startTime)/DAY * DAY;
            duration = duration < VEST_DURATION ? duration : VEST_DURATION;
            earned += (_userinfo.vestAmount * duration / VEST_DURATION) - _userinfo.claimed;
            
        }
        return earned;
    }

    function getDepositEarn(uint amount, Route[] calldata routes) public view returns(uint) {
        require(routes[0].from != address(AGI) && routes[routes.length - 1].to == address(WETH), 'INVALID_PATH');
        uint[] memory amountsOut = router.getAmountsOut(amount, routes);

        return getDepositETHEarn(amountsOut[amountsOut.length - 1]);
    }

    function getDepositETHEarn(uint ethAmount) public view returns(uint) {
        (uint amount, ) = router.getAmountOut(ethAmount, address(WETH), address(AGI));
        return amount * (100 + TOKEN_BONUS) / 100;
    }

    /// @notice Calculate reward for users participate BuyBackAndBurn program
    function _calculateDeposit(uint wethAmount, address user, address ref) internal {
        uint _agiEarn = getDepositETHEarn(wethAmount);
        require(_agiEarn + totalAGIVestRemain <= AGI.balanceOf(address(this)), "over amount");
        uint index = userParticipates[user] + 1;

        userParticipates[user] = index;
        UserInfo memory userInfo = UserInfo(_agiEarn, block.timestamp, 0);

        userParticipateInfos[user][index] = userInfo;
        totalETHDeposit += wethAmount;
        totalAGIVestRemain += _agiEarn;
        if(ref != address(0)){
            WETH.transfer(ref, wethAmount * REFERRAL_BONUS / 100);
        }
    }

    function wrapETH() external {
        require(address(this).balance > 0, "Zero");
        WETH.deposit{value: address(this).balance}();    
    }

    function wethBalance() public view returns(uint){
        return WETH.balanceOf(address(this));
    }

    function burnDurationsAvailable() public view returns(uint){
        return (block.timestamp - lastBurned)/BURN_DURATION > 100 ? 100: (block.timestamp - lastBurned)/BURN_DURATION;
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0, "TOKEN NULL");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "FAIL");
    }
}