// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { ISwapFactory } from "./interfaces/ISwapFactory.sol";
import { Rebaser } from "./Rebaser.sol";

contract Erection is Ownable, IERC20 {

    struct DailyTransfer {
        uint256 startTime;
        uint256 endTime;
        uint256 periodTransfers;
    }

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    ISwapRouter public swapRouter;
    address public swapPair;
    address public immutable USDC;
    address public admin;

    bool public rebaseEnabled;
    bool public inRebase;    
    uint256 private quoteBase = 1 * 10**3;
    uint256 public targetPrice;
    uint256 public rebaseThreshold = 9900; // 99%
    uint256 public minRebasePercent = 10100; // 101%
    uint256 public rebaseAdjustFactor = 7000; // 70%
    uint256 public currentDate;
    uint256 public lastRebase;
    uint256 public currentPrice;
    uint256 public quoteTime;

    uint256 public constant DIVISOR = 10000;

    Rebaser public rebaser;

    mapping (address => bool) public isAddressWhitelistedIn;
    mapping (address => bool) public isAddressWhitelistedOut;
    mapping (address => bool) public isAddressBlacklistedIn;
    mapping (address => bool) public isAddressBlacklistedOut;
    mapping (address => bool) public isContractWhitelisted;

    bool public transferLimitEnabled = true;
    uint256 public dailyPercentLimit = 200; // 2%
    uint256 public dailyUSDLimit = 10000 * 10**18; // $10,000
    uint256 public transferLimit = 100000 * 10**18;

    mapping (address => DailyTransfer) public dailyTransfers;

    event Rebased(
        uint256 rebasedFromPrice, 
        uint256 rebasedToPrice, 
        uint256 usdcSwapped, 
        uint256 usdcAdded, 
        uint256 erectionBurned, 
        uint256 rebasedTimestamp
    );
    event UpdatedTarget(uint256 targetPrice, uint256 dailyUSDLimit, uint256 transferLimit, uint256 currentDate);
    event AdminUpdated(address newAdmin);
    event AdminRenounced();

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 _startDate,
        address _teamAddress,
        address _usdc,
        address _router
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(_msgSender(), (totalSupply_ * 10**_decimals));

        currentDate = _startDate;

        USDC = _usdc;

        admin = msg.sender;

        swapRouter = ISwapRouter(_router);
        swapPair = ISwapFactory(swapRouter.factory())
        .createPair(address(this), USDC);

        rebaser = new Rebaser(_router, _usdc, msg.sender, _teamAddress, swapPair);

        rebaser.setTeamAddress(_teamAddress);
        rebaser.setSwapPair(swapPair);

        isContractWhitelisted[swapPair] = true;
        isContractWhitelisted[address(swapRouter)] = true;
        isContractWhitelisted[address(this)] = true;
        isContractWhitelisted[address(rebaser)] = true;

        isAddressWhitelistedOut[swapPair] = true;
        isAddressWhitelistedOut[address(swapRouter)] = true;
        isAddressWhitelistedOut[address(this)] = true;
        isAddressWhitelistedOut[address(rebaser)] = true;
        isAddressWhitelistedOut[msg.sender] = true;
    }

    function setRebaseEnabled(bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        rebaseEnabled = flag;
        rebaser.setRebaseEnabled(flag);
    }

    function setRebaseThreshold(uint256 _percent) external {
        require(msg.sender == admin, "Caller not allowed");
        rebaseThreshold = DIVISOR - _percent;
    }

    function setMinRebasePercent(uint256 _percent) external {
        require(msg.sender == admin, "Caller not allowed");
        minRebasePercent = _percent + DIVISOR;
    }

    function setRebaseAdjustFactor(uint256 _percent) external {
        require(msg.sender == admin, "Caller not allowed");
        rebaseAdjustFactor = DIVISOR - _percent;
    }

    function setTransferLimitEnabled(bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        transferLimitEnabled = flag;
    }
    
    function setTransferLimit(uint256 _amount) external {
        require(msg.sender == admin, "Caller not allowed");
        transferLimit = _amount;
    }

    function setDailyPercentLimit(uint256 _percent) external {
        require(msg.sender == admin, "Caller not allowed");
        dailyPercentLimit = _percent;
    }

    /// Functions to whitelist selected wallets
    function setWhitelistWalletOut(address wallet, bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        isAddressWhitelistedOut[wallet] = flag;
    }
    function setWhitelistWalletIn(address wallet, bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        isAddressWhitelistedIn[wallet] = flag;
    }
    function setContractWhitelisted(address contr, bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        isContractWhitelisted[contr] = flag;
    }

    /// Function to blacklist and restrict buys to selected wallets
    function setBlacklistIn(address wallet, bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        isAddressBlacklistedIn[wallet] = flag;
    }
    function setBlacklistOut(address wallet, bool flag) external {
        require(msg.sender == admin, "Caller not allowed");
        isAddressBlacklistedOut[wallet] = flag;
    }

    function changeAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Caller not allowed");
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function renounceAdminRole() external {
        require(msg.sender == admin, "Caller not allowed");
        admin = address(0);
        emit AdminRenounced();
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        require(
            !isAddressBlacklistedOut[msg.sender] && 
            !isAddressBlacklistedIn[recipient], 
            "Erection: recip is blacklisted"
        );
        if(!transferLimitEnabled || isAddressWhitelistedOut[msg.sender]) {
            _transfer(_msgSender(), recipient, amount);

            return true;

        } else if(dailyTransfers[msg.sender].endTime < block.timestamp) {
            require(amount <= transferLimit, "Erection: exceeds daily limit");
            dailyTransfers[msg.sender].startTime = block.timestamp;
            dailyTransfers[msg.sender].endTime = block.timestamp + 1 days;
            dailyTransfers[msg.sender].periodTransfers = amount;

            _transfer(_msgSender(), recipient, amount);

            return true;

        } else {
            require(
                dailyTransfers[msg.sender].periodTransfers + amount <= transferLimit, 
                "Erection: exceeds daily limit"
            );

            dailyTransfers[msg.sender].periodTransfers = dailyTransfers[msg.sender].periodTransfers + amount;

            _transfer(_msgSender(), recipient, amount);

            return true; 
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        require(
            !isAddressBlacklistedOut[sender] && 
            !isAddressBlacklistedIn[recipient], 
            "Erection: recip is blacklisted"
        );
        if(!transferLimitEnabled || isAddressWhitelistedOut[sender] || isAddressWhitelistedIn[recipient]) {
            _transfer(sender, recipient, amount);

            _approve(
                sender, 
                _msgSender(), 
                _allowances[sender][_msgSender()] - amount
            );
            return true;

        } else if(dailyTransfers[sender].endTime < block.timestamp) {
            require(amount <= transferLimit, "Erection: exceeds daily limit");

            dailyTransfers[sender].startTime = block.timestamp;
            dailyTransfers[sender].endTime = block.timestamp + 1 days;
            dailyTransfers[sender].periodTransfers = amount;

            _transfer(sender, recipient, amount);

            _approve(
                sender, 
                _msgSender(), 
                _allowances[sender][_msgSender()] - amount
            );
            return true;

        } else {
            require(
                dailyTransfers[sender].periodTransfers + amount <= transferLimit, 
                "Erection: exceeds daily limit"
            );

            dailyTransfers[sender].periodTransfers = dailyTransfers[sender].periodTransfers + amount;

            _transfer(sender, recipient, amount);

            _approve(
                sender, 
                _msgSender(), 
                _allowances[sender][_msgSender()] - amount
            );
            return true;
        }
    }

    // Remove bnb that is sent here by mistake
    function removeBNB(uint256 amount, address to) external onlyOwner{
        payable(to).transfer(amount);
      }

    // Remove tokens that are sent here by mistake
    function removeToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(), 
            spender, 
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve the zero address");
        require(spender != address(0), "ERC20: approve the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: from the zero address");
        require(recipient != address(0), "ERC20: to the zero address");
        require(!_isContract(sender) && !_isContract(recipient), "Erection: no contracts");
        require(
            isContractWhitelisted[sender] || 
            isContractWhitelisted[recipient] || 
            sender == tx.origin || 
            recipient == tx.origin, 
            "Erection: no proxy contract"
        );           

        if(rebaseEnabled) { 
            currentPrice = (quoteBase * 10**30) / getQuote(); 
        
            if(!inRebase) {
                if(block.timestamp > currentDate + 1 days) {
                    currentDate = currentDate + 1 days;
                    if(currentPrice * rebaseAdjustFactor / DIVISOR >= targetPrice * minRebasePercent / DIVISOR) {
                        targetPrice = (currentPrice * rebaseAdjustFactor) / DIVISOR;
                    } else {
                        targetPrice = (targetPrice * minRebasePercent) / DIVISOR;
                    }
                    dailyUSDLimit = (IERC20(USDC).balanceOf(swapPair) * dailyPercentLimit) / DIVISOR;
                    transferLimit = (dailyUSDLimit * 10**36) / currentPrice;

                    emit UpdatedTarget(targetPrice, dailyUSDLimit, transferLimit, currentDate);
                } else if((currentPrice * rebaseAdjustFactor) / DIVISOR > targetPrice) {
                    targetPrice = (currentPrice * rebaseAdjustFactor) / DIVISOR;
                    dailyUSDLimit = (IERC20(USDC).balanceOf(swapPair) * dailyPercentLimit) / DIVISOR;
                    transferLimit = (dailyUSDLimit * 10**36) / currentPrice;

                    emit UpdatedTarget(targetPrice, dailyUSDLimit, transferLimit, currentDate);
                }
        
                if(currentPrice <= (targetPrice * rebaseThreshold) / DIVISOR && recipient == swapPair) {
                    inRebase = true;
                    lastRebase = block.timestamp;
                    uint256 prePrice = currentPrice;
                    (uint256 swapAmount, uint256 addAmount, uint256 burnAmount) = 
                        rebaser.rebase(currentPrice, targetPrice);
                    currentPrice = (quoteBase * 10**30) / getQuote();
                    emit Rebased(prePrice, currentPrice, swapAmount, addAmount, burnAmount, block.timestamp);
                }
            }
        }

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);

        inRebase = false;  
    }

    function getQuote() internal view returns (uint256) {
        address[] memory quotePath = new address[](2);
            quotePath[0] = USDC;
            quotePath[1] = address(this);                    

        uint256[] memory fetchedQuote = swapRouter.getAmountsOut(quoteBase, quotePath);

        return fetchedQuote[1];
    } 

    function _isContract(address _addr) internal view returns (bool) {
        if (isContractWhitelisted[_addr]){
            return false;
        } else {
            uint256 size;
            assembly {
                size := extcodesize(_addr)
            }
            return size > 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { ISwapPair } from "./interfaces/ISwapPair.sol";
import { IRebaser } from "./interfaces/IRebaser.sol";

contract Rebaser is IRebaser {

    address public _token;
    address public admin;
    bool private inRebase;
    bool public rebaseEnabled;

    uint256 public liquidityUnlockTime;
    uint256 public percentToRemove = 9800; // 98%
    uint256 public divisor = 10000;
    uint256 public teamFee = 5 * 10**5; // $0.50
    address public teamAddress;

    ISwapRouter public swapRouter;
    address public immutable USDC;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public swapPair;
    ISwapPair public pair;
    address public tokenA;
    address public tokenB;

    event LiquidityLocked(uint256 lockedLiquidityAmount, uint256 liquidityLockExpiration);
    event AdminUpdated(address newAdmin);
    event AdminRenounced();

    modifier onlyAdmin {
        require(msg.sender == admin, "Caller not Admin");
        _;
    }

    modifier lockTheSwap {
        inRebase = true;
        _;
        inRebase = false;
    }

    modifier onlyToken() {
        require(msg.sender == _token, "Caller not Token"); 
        _;
    }

    constructor(address _router, address _usdc, address _admin, address _teamAddress, address _pair) {
        swapRouter = ISwapRouter(_router);
        _token = msg.sender;
        USDC = _usdc;
        admin = _admin;
        teamAddress = _teamAddress;

        swapPair = _pair;
        pair = ISwapPair(_pair);

        tokenA = pair.token0();
        tokenB = pair.token1();
    }

    receive() external payable {}
   
    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function renounceAdminRole() external onlyAdmin {
        admin = address(0);
        emit AdminRenounced();
    }

    function setRebaseEnabled(bool flag) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        rebaseEnabled = flag;
    }

    function setPercentToRemove(uint256 _percent) external onlyAdmin {
        percentToRemove = _percent;
    }

    function setTeamAddress(address _teamAddress) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        teamAddress = _teamAddress;
    }

    function setTeamFee(uint256 _amount) external onlyAdmin {
        teamFee = _amount;
    }

    function setSwapPair(address _pair) external override {
        require(msg.sender == admin || msg.sender == _token, "Erection: caller not allowed");
        swapPair = _pair;
        pair = ISwapPair(_pair);

        tokenA = pair.token0();
        tokenB = pair.token1();
    }

    function depositAndLockLiquidity(uint256 _amount, uint256 _unlockTime) external onlyAdmin {
        require(liquidityUnlockTime <= _unlockTime, "Can not shorten lock time");
        IERC20(swapPair).transferFrom(msg.sender, address(this), _amount);
        liquidityUnlockTime = _unlockTime;
        emit LiquidityLocked(_amount, _unlockTime);
    }

    function rebase(
        uint256 currentPrice, 
        uint256 targetPrice
    ) external override onlyToken lockTheSwap returns (
        uint256 amountToSwap,
        uint256 amountUSDCtoAdd,
        uint256 burnAmount
    ) {
        if(rebaseEnabled){
            removeLiquidity();
            uint256 balanceUSDC = IERC20(USDC).balanceOf(address(this));
            (uint reserve0, uint reserve1,) = pair.getReserves();
            uint256 adjustment = (((targetPrice * 10**18) / currentPrice) - 10**18) / 2;
            if(pair.token0() == USDC) {  
                uint256 reserve0Needed = (reserve0 * (adjustment + 10**18)) /  10**18;
                amountToSwap = reserve0Needed - reserve0;
            } else if(pair.token1() == USDC) {
                uint256 reserve1Needed = (reserve1 * (adjustment + 10**18)) / 10**18;
                amountToSwap = reserve1Needed - reserve1;
            }
            uint256 amountUSDCAvailable = balanceUSDC - amountToSwap;
            amountUSDCtoAdd = amountUSDCAvailable - teamFee;
            buyTokens(amountToSwap, amountUSDCtoAdd);
            IERC20(USDC).transfer(teamAddress, teamFee);
            burnAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(BURN_ADDRESS, burnAmount);
        } 
    }

    // Remove bnb that is sent here by mistake
    function removeBNB(uint256 amount, address to) external onlyAdmin{
        payable(to).transfer(amount);
      }

    // Remove tokens that are sent here by mistake
    function removeToken(IERC20 token, uint256 amount, address to) external onlyAdmin {
        if (block.timestamp < liquidityUnlockTime) {
            require(token != IERC20(swapPair), "Liquidity is locked");
        }
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    function removeLiquidity() internal {
        uint256 amountToRemove = (IERC20(swapPair).balanceOf(address(this)) * percentToRemove) / divisor;
       
        IERC20(swapPair).approve(address(swapRouter), amountToRemove);
        
        // Remove the liquidity
        swapRouter.removeLiquidity(
            tokenA,
            tokenB,
            amountToRemove,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }

    function buyTokens(uint256 amountToSwap, uint256 amountUSDCtoAdd) internal {
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = _token;

        IERC20(USDC).approve(address(swapRouter), amountToSwap);

        swapRouter.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        addLiquidity(amountUSDCtoAdd); 
    }

    function addLiquidity(uint256 amountUSDCtoAdd) internal {
        uint256 amountTokenToAdd = IERC20(_token).balanceOf(address(this));
       
        IERC20(_token).approve(address(swapRouter), amountTokenToAdd);
        IERC20(USDC).approve(address(swapRouter), amountUSDCtoAdd);
        
        // Add the liquidity
        swapRouter.addLiquidity(
            _token,
            USDC,
            amountTokenToAdd,
            amountUSDCtoAdd,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapFactory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import { ISwapRouter01 } from "./ISwapRouter01.sol";

interface ISwapRouter is ISwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function factory() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IRebaser {
    function rebase(
        uint256 currentPrice, 
        uint256 targetPrice
    ) external returns (
        uint256 amountToSwap,
        uint256 amountUSDTtoAdd,
        uint256 burnAmount
    );
    function setTeamAddress(address _teamAddress) external;
    function setRebaseEnabled(bool flag) external;
    function setSwapPair(address _pair) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface ISwapPair {

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

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