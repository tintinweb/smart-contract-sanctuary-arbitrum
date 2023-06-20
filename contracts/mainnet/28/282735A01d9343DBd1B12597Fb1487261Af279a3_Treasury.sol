// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IRiskVault.sol";
import "Operator.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "IAavePoolV3.sol";
import "IGlpVault.sol";
import "Abs.sol";
import "IAavePoolV3.sol";
import "ISwapRouter.sol";

/**
 * @dev Sharplabs Treasury Contract. It provides an interface for governance accounts to 
 * operate the pool contract and also accepts parameters uploaded from off-chain by governance to 
 * ensure the system runs smoothly. 
 *
 * It also provides a pause mechanism to temporarily halt the system's operation 
 * in case of emergencies (users' on-chain funds are safe).
 */
contract Treasury is Operator, ReentrancyGuard {

    using Address for address;
    using SafeERC20 for IERC20;
    using Abs for int256;

    address public share;
    address public governance;
    address public riskOnPool;

    uint256 public epoch;
    uint256 public startTime;
    uint256 public period = 24 hours;
    uint256 public riskOnPoolRatio;
    uint256 public lastEpochPoint;

    // flags
    bool public initialized = false;
    address public weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public glpVault = address(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address public aaveV3 = address(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    address public usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public usdcRiskOnVault = address(0x07Cf4384b5B5Bb90c796b7C23986A4f12898BcAC);

    event Initialized(address indexed executor, uint256 at);
    event EpochUpdated(uint256 indexed atEpoch, uint256 timestamp);

    modifier onlyGovernance() {
        require(governance == msg.sender, "caller is not the governance");
        _;
    }

    modifier notInitialized() {
        require(!initialized, "already initialized");
        _;
    }

    event GlpVaultUpdated(uint256 indexed atEpoch, address _glpVault);
    event AaveV3Updated(uint256 indexed atEpoch, address _aaveV3);

    receive() payable external {}
    
    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return lastEpochPoint + period;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    /* ========== CONFIG ========== */

    function setPeriod(uint _period) external onlyGovernance {
        require(_period > 0, "period cannot be zero");
        period = _period;
    }

    function setPool(address _riskOnPool) external onlyOperator {
        require(_riskOnPool != address(0), "pool address cannot be zero address");
        riskOnPool = _riskOnPool;
    }

    function setRiskOnPoolRatio(uint _riskOnPoolRatio) external onlyGovernance {
        require(_riskOnPoolRatio > 0, "ratio cannot be zero");
        riskOnPoolRatio = _riskOnPoolRatio;
    }

    function setGlpFee(uint _glpInFee, uint _glpOutFee) external onlyGovernance {
        IRiskVault(riskOnPool).setGlpFee(_glpInFee, _glpOutFee);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == operator() || msg.sender == governance);
        require(_governance != address(0), "governance address cannot be zero address");
        governance = _governance;
    }

    function setGlpVault(address _glpVault) external onlyOperator {
        require(_glpVault != address(0), "address can not be zero address");
        glpVault = _glpVault;
        emit GlpVaultUpdated(epoch, _glpVault);
    }

    function setAaveV3(address _aaveV3) external onlyOperator {
        require(_aaveV3 != address(0), "address can not be zero address");
        aaveV3 = _aaveV3;
        emit AaveV3Updated(epoch, _aaveV3);
    }

    function initialize(
        address _share,
        address _governance,
        address _riskOnPool,
        uint256 _riskOnPoolRatio,
        uint256 _startTime
    ) public notInitialized {
        require(_share != address(0), "share address can not be zero address");
        require(_governance != address(0), "governance address can not be zero address");
        require(_riskOnPool != address(0), "riskOnPool address can not be zero address");
        share = _share;
        governance = _governance;
        riskOnPool = _riskOnPool;
        riskOnPoolRatio = _riskOnPoolRatio;
        startTime = _startTime;
        lastEpochPoint = _startTime;
        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function weth_price() public view returns (uint256) {
        return IGlpVault(glpVault).getMinPrice(weth);
    }

    function weth_price_precision() public view  returns (uint256) {
        return IGlpVault(glpVault).PRICE_PRECISION();
    }

    function wsteth_price() public view returns (uint256) {
        return weth_price() * IRiskVault(riskOnPool).share_price() / 10 ** IRiskVault(riskOnPool).share_price_decimals();
    }

    function wsteth_price_precision() public view returns (uint256) {
        return weth_price_precision();
    }

    // required usd collateral in the contract with 1e18 precision
    function getRequiredUsdCollateral() public view returns (uint256) {
        IRiskVault vault = IRiskVault(riskOnPool);
        uint256 wstethValue = (vault.total_supply_wait() + vault.total_supply_staked() + vault.total_supply_withdraw()) * (wsteth_price() * 1e6 / wsteth_price_precision()) / 1e6;
        if (vault.total_supply_reward() >= 0) {
            return wstethValue + vault.total_supply_reward().abs() * weth_price() / weth_price_precision();
        } else {
            return wstethValue - vault.total_supply_reward().abs() * weth_price() / weth_price_precision();
        }
    }

    // get total usd value in the contract with 1e18 precision
    function getUsdValue() public view returns (uint256){
        (uint256 totalCollateralBase,uint256 totalDebtBase,,,,) = IAavePoolV3(aaveV3).getUserAccountData(riskOnPool);
        uint256 aaveValue = (totalCollateralBase - totalDebtBase) * 1e10;
        // wetETH
        uint256 tokenValue = IERC20(share).balanceOf(riskOnPool) * wsteth_price() / wsteth_price_precision();
        // WETH
        tokenValue = tokenValue + IERC20(weth).balanceOf(riskOnPool) * weth_price() / weth_price_precision();
        // ETH
        tokenValue = tokenValue + riskOnPool.balance * weth_price() / weth_price_precision();
        // USDC
        tokenValue = tokenValue + IERC20(usdc).balanceOf(riskOnPool) * 1e12;

        IRiskVault vault = IRiskVault(usdcRiskOnVault);
        uint256 stakedValue = vault.balance_wait(riskOnPool) * 1e12;
        stakedValue = stakedValue + vault.balance_staked(riskOnPool) * 1e12;
        stakedValue = stakedValue + vault.balance_withdraw(riskOnPool) * 1e12;
        int256 _reward = vault.balance_reward(riskOnPool);
        if (_reward >= 0){
            stakedValue = stakedValue + _reward.abs() * 1e12;
        }else{
            stakedValue = stakedValue - _reward.abs() * 1e12;
        }
        return aaveValue + tokenValue + stakedValue;
    }


    function supplyBorrow(uint256 _supplyAmount, uint256 _borrowAmount, uint16 _referralCode) external onlyGovernance {
        IRiskVault(riskOnPool).supplyBorrow(_supplyAmount, _borrowAmount, _referralCode);
    }

    function repayWithdraw(uint256 _repayAmount, uint256 _withdrawAmount) external onlyGovernance {
        IRiskVault(riskOnPool).repayWithdraw(_repayAmount, _withdrawAmount);
    }
    
    function stakeRiskOn(uint256 _amount) external onlyGovernance {
        IRiskVault(riskOnPool).stakeByGov(_amount);
    }

    function withdrawRequestRiskOn(uint256 _amount) external onlyGovernance {
        IRiskVault(riskOnPool).withdrawRequestByGov(_amount);
    }

    function withdrawRiskOn(uint256 _amount) external onlyGovernance {
        IRiskVault(riskOnPool).withdrawByGov(_amount);
    }

    // send funds(ERC20 tokens) to pool
    function sendPoolFunds(address _token, uint _amount) external onlyGovernance {
        require(_amount <= IERC20(_token).balanceOf(address(this)), "insufficient funds");
        IERC20(_token).safeTransfer(riskOnPool, _amount);
    }

    // send funds(ETH) to pool
    function sendPoolFundsETH(uint _amount) external onlyGovernance {
        require(_amount <= address(this).balance, "insufficient funds");
        Address.sendValue(payable(riskOnPool), _amount);
    }


    // withdraw pool funds(ERC20 tokens) to specified address
    function withdrawPoolFunds(address _token, uint256 _amount, address _to) external onlyGovernance {
        IRiskVault(riskOnPool).treasuryWithdrawFunds(_token, _amount, _to);
        require(getRequiredUsdCollateral() * riskOnPoolRatio / 100 <= getUsdValue(), "low collateral: cannot withdraw pool funds");
    }

    // withdraw pool funds(ERC20 tokens) to specified address
    function withdrawPoolFundsWETHToETH(uint256 _amount, address _to) external onlyGovernance {
        IRiskVault(riskOnPool).treasuryWithdrawFundsWETHToETH(_amount, _to);
        require(getRequiredUsdCollateral() * riskOnPoolRatio / 100 <= getUsdValue(), "low collateral: cannot withdraw pool funds");
    }

    // withdraw pool funds(ETH) to specified address
    function withdrawPoolFundsETH(uint _amount, address _to) external onlyGovernance {
        require(_amount <= riskOnPool.balance, "insufficient funds");
        IRiskVault(riskOnPool).treasuryWithdrawFundsETH(_amount, _to);
        require(getRequiredUsdCollateral() * riskOnPoolRatio / 100 <= getUsdValue(), "low collateral: cannot withdraw pool funds");
    }

    function swapPoolWethToToken(uint256 wethAmount, address _token, uint256 minAmountOut, uint24 _fee) external onlyGovernance {
        IRiskVault(riskOnPool).treasuryWithdrawFunds(weth, wethAmount, address(this));
        
        ISwapRouter swapRouter = ISwapRouter(uniV3Router);
        IERC20(weth).safeApprove(uniV3Router, 0);
        IERC20(weth).safeApprove(uniV3Router, wethAmount);
        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: weth,
                tokenOut: _token,
                fee: _fee,
                recipient: riskOnPool,
                deadline: block.timestamp,
                amountIn: wethAmount,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            })
        );
        require(getRequiredUsdCollateral() * riskOnPoolRatio / 100 <= getUsdValue(), "low collateral: cannot withdraw pool funds");
    }

    function swapPoolTokenToWeth(address _token, uint256 _tokenAmount, uint256 minWethAmountOut, uint24 _fee) external onlyGovernance {
        IRiskVault(riskOnPool).treasuryWithdrawFunds(_token, _tokenAmount, address(this));
        
        ISwapRouter swapRouter = ISwapRouter(uniV3Router);
        IERC20(_token).safeApprove(uniV3Router, 0);
        IERC20(_token).safeApprove(uniV3Router, _tokenAmount);
        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _token,
                tokenOut: weth,
                fee: _fee,
                recipient: riskOnPool,
                deadline: block.timestamp,
                amountIn: _tokenAmount,
                amountOutMinimum: minWethAmountOut,
                sqrtPriceLimitX96: 0
            })
        );
        require(getRequiredUsdCollateral() * riskOnPoolRatio / 100 <= getUsdValue(), "low collateral: cannot withdraw pool funds");
    }

    // allocate rewards
    function allocateReward(int256 amount) external onlyGovernance {
        IRiskVault(riskOnPool).allocateReward(amount);
    }

    // deposit funds from gov wallet to treasury
    function deposit(address _token, uint256 amount) external onlyGovernance {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount);
    }

    // withdraw funds(ERC20 tokens) from treasury to the gov wallet
    function withdraw(address _token, uint256 amount) external onlyGovernance {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    // withdraw funds(ETH) from treasury to the gov wallet
    function withdrawETH(uint256 amount) external nonReentrant onlyGovernance {
        require(amount <= address(this).balance, "insufficient funds");
        Address.sendValue(payable(msg.sender), amount);
    }

    // trigger by the governance wallet at the end of each epoch
    function handleStakeRequest(address[] memory _address) external onlyGovernance {
        IRiskVault(riskOnPool).handleStakeRequest(_address);
    }

    // trigger by the governance wallet at the end of each epoch
    function handleWithdrawRequest(address[] memory _address) external onlyGovernance {
        IRiskVault(riskOnPool).handleWithdrawRequest(_address);
    }
    
    function removeWithdrawRequest(address[] memory _address) external onlyGovernance {
        IRiskVault(riskOnPool).removeWithdrawRequest(_address);
    }

    function setAaveUserEMode(uint8 categoryId) external onlyGovernance {
        IRiskVault(riskOnPool).setAaveUserEMode(categoryId);
    }

    // trigger by the governance wallet at the end of each epoch
    function updateEpoch() external onlyGovernance {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");
        epoch += 1;
        lastEpochPoint += period;
        emit EpochUpdated(epoch, block.timestamp);
    }

    // update capacity of each pool
    function updateCapacity(uint _riskOnPoolCapacity) external onlyGovernance {
        IRiskVault(riskOnPool).setCapacity(_riskOnPoolCapacity);
    } 

    // temporarily halt the system's operations
    function pause() external onlyGovernance {
        IRiskVault(riskOnPool).pause();
    }

    // recover the system's operations
    function unpause() external onlyGovernance {
        IRiskVault(riskOnPool).unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRiskVault {
    function stake(uint256 _amount) external payable;
    function withdraw_request(uint256 _amount) external payable;
    function withdraw(uint256 _amount) external;

    function stakeByGov(uint256 _amount) external;
    function withdrawRequestByGov(uint256 _amount) external;
    function withdrawByGov(uint256 _amount) external;

    function supplyBorrow(uint256 _supplyAmount, uint256 _borrowAmount, uint16 _referralCode) external;
    function repayWithdraw(uint256 _repayAmount, uint256 _withdrawAmount) external;

    function treasuryWithdrawFunds(address _token, uint256 amount, address to) external;
    function treasuryWithdrawFundsWETHToETH(uint256 amount, address to) external;
    function treasuryWithdrawFundsETH(uint256 amount, address to) external;

    function allocateReward(int256 amount) external;
    function handleStakeRequest(address[] memory _address) external;
    function handleWithdrawRequest(address[] memory _address) external;

    function removeWithdrawRequest(address[] memory _address) external;
    function setCapacity(uint256 _capacity) external;
    function setAaveUserEMode(uint8 categoryId) external;

    function pause() external;
    function unpause() external;
    function setGlpFee(uint256 _glpInFee, uint256 _glpOutFee) external;

    function balance_wait(address account) external view returns (uint256);
    function balance_staked(address account) external view returns (uint256);
    function balance_withdraw(address account) external view returns (uint256);
    function balance_reward(address account) external view returns (int256);

    function total_supply_wait() external view returns (uint256);
    function total_supply_staked() external view returns (uint256);
    function total_supply_withdraw() external view returns (uint256);
    function total_supply_reward() external view returns (int256);

    function share_price()external view returns (uint256);
    function share_price_decimals()external view returns (uint256);

    function gasthreshold() external view returns (uint256);
    function fee() external view returns (uint256);
    function glpInFee() external view returns (uint256);
    function glpOutFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "Context.sol";
import "Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

pragma solidity 0.8.13;

import "Context.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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

pragma solidity 0.8.13;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.13;

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.13;

interface IAavePoolV3{
    function supply(address asset,uint256 amount,address onBehalfOf,uint16 referralCode)external;
    function withdraw(bytes32 args)external;
    function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf)external;
    function repay(bytes32 args)external;
    function setUserEMode(uint8 categoryId) external;

    function getUserEMode(address user) external view returns (uint256);
    function getUserAccountData(address account) external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IGlpVault {
    function getMinPrice(address) external view returns (uint);
    function PRICE_PRECISION() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library Abs {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(-x);
        } else {
            return uint256(x);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}