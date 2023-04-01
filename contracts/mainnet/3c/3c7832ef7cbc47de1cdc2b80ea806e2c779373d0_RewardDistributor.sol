/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: GPL-3.0

/**
Use at least 11% slippage! (Recommended: 13%)

Discord: https://discord.gg/GwHHZgjQPg
Telegram: https://t.me/+LlxdYdyXOqlkYjBh
Twitter: https://twitter.com/ArbitrumPay
Medium: https://medium.com/@ArbiPay
Website: https://arbipay.app
For future links:
https://linktr.ee/arbipay

ArbiPay is a reward token on the Arbitrum blockchain celebrating the release of the ARB token.
Hold $APAY and earn $ARB. Claim your rewards on out website.
Let's print to the moooooon together!
*/

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


pragma solidity >=0.6.2;

interface IUniswapV2Factory {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity ^0.8.7;

contract Auth is Ownable {
    mapping (address => bool) internal authorizations;

    constructor() {
        authorizations[msg.sender] = true;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        authorizations[newOwner] = true;
        _transferOwnership(newOwner);
    }

    /** ======= MODIFIERS ======= */

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
}

pragma solidity ^0.8.7;

contract RewardDistributor  {
    using SafeMath for uint256;


    /** ======= GLOBAL PARAMS ======= */

    // Reward Token;
    address token;
   
    // Arb Token; 
    IERC20 EP = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548); // ARB

    // WETH;
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address ARB_ADDRESS = 0x912CE59144191C1204E64559FE8253a0e49E6548; // ARB

    // SushiSwap Router; 
    IUniswapV2Router02 router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;// excluded reward
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 seconds; //1 second;
    uint256 public minDistribution = 10 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;

    /** ======= CONSTRUCTOR ======= */

    /**
     *  Initializes the router and token address; 
     *  @param _router address of the router; 
     */
    constructor (address _router) {
        require(_router != address(0), "_router is zero address"); 

        // Initialize the router; 
        router = IUniswapV2Router02(_router);

        // Initialize the token; 
        token = msg.sender;
    }

    /** ======= EXTERNAL FUNCTIONS ======= */

    function claimReward() external {
        distributeReward(msg.sender);
    }


    /** ======= TOKEN ONLY FUNCTIONS ======= */

    /**
     *  Sets the minPeriod and minDistribution values; 
     */
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(shares[shareholder].amount > 0){
            distributeReward(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeRewards(shares[shareholder].amount);
    }

    /**
     *  Swaps ETH to ARB and updates totals; 
     */
    function deposit() external payable onlyToken {
        uint256 balanceBefore = EP.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(EP);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = EP.balanceOf(address(this)).sub(balanceBefore);

        totalRewards = totalRewards.add(amount);
        rewardsPerShare = rewardsPerShare.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    /**
     *  Distributes the earnings to shareholders;  
     *  @param _gas the amount of gas given to the transaction; 
     */
    function process(uint256 _gas) external onlyToken {
        // Get total shareholders; 
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { 
            return; 
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        // Iterate untill theres no more gas AND we have no more shareholders to distribute;  
        while(gasUsed < _gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            // Distribute Shares; 
            if(shouldDistribute(shareholders[currentIndex])){
                distributeReward(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }


    /** ======= INTERNAL VIEW FUNCTIONS ======= */

    /**
     *  Checks if contract should distribute earnings to shareholder; 
     *  @param _shareholder address of the holder; 
     *  @return bool value of the result; 
     */
    function shouldDistribute(address _shareholder) internal view returns (bool) {
        // Check 
        // Check unpaid earnings are higher than minDistribution; 
        return 
            shareholderClaims[_shareholder] + minPeriod < block.timestamp
        && 
            getUnpaidEarnings(_shareholder) > minDistribution;
    }

    /**
     *  Calculates the unpaidEarnings for given shareholder;  
     *  @param _shareholder address of the holder;
     *  @return  value of unpaid earnings; 
     */
    function getUnpaidEarnings(address _shareholder) public view returns (uint256) {
        // Make shure address has shares; 
        if(shares[_shareholder].amount == 0){ 
            return 0; 
        }

        uint256 shareholderTotalRewards = getCumulativeRewards(shares[_shareholder].amount);
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;

        if(shareholderTotalRewards <= shareholderTotalExcluded){ 
            return 0; 
        }

        return shareholderTotalRewards.sub(shareholderTotalExcluded);
    }

    /**
     *  Calculates the rewards for given share amout;  
     *  @param _share amount of shares;
     *  @return  amount of rewards; 
     */
    function getCumulativeRewards(uint256 _share) internal view returns (uint256) {
        return _share.mul(rewardsPerShare).div(rewardsPerShareAccuracyFactor);
    }

    /** ======= INTERNAL FUNCTIONS ======= */

    /**
     *  Distributes the earnings to the shareholder;  
     *  @param _shareholder address of the holder; 
     */
    function distributeReward(address _shareholder) internal {

        // Make shure the shareholder has shares; 
        if(shares[_shareholder].amount == 0){ 
            return; 
        }

        // Get the shareholder earnings; 
        uint256 amount = getUnpaidEarnings(_shareholder);

        // If shareholder has earnings distribute; 
        if(amount > 0){
            // Update totals; 
            totalDistributed = totalDistributed.add(amount);
            // Transfer the shares to holder; 
            EP.transfer(_shareholder, amount);
            // Update holderClaims; 
            shareholderClaims[_shareholder] = block.timestamp;
            // Update holder totals; 
            shares[_shareholder].totalRealised = shares[_shareholder].totalRealised.add(amount);
            shares[_shareholder].totalExcluded = getCumulativeRewards(shares[_shareholder].amount);
        }
    }

    /**
     *  Adds shareholder to the mapping and array;  
     *  @param _shareholder address of the new holder;
     */
    function addShareholder(address _shareholder) internal {
        shareholderIndexes[_shareholder] = shareholders.length;
        shareholders.push(_shareholder);
    }

    /**
     *  Remove shareholder from the mapping and array;  
     *  @param _shareholder address of the holder to remove;
     */
    function removeShareholder(address _shareholder) internal {
        shareholders[shareholderIndexes[_shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[_shareholder];
        shareholders.pop();
    }

    function setEP(address _ep) external onlyToken {
        EP = IERC20(_ep);
    }


    /** ======= MODIFIERS ======= */

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    /**
     *  Modifier to make shure the function is only called by the divToken; 
     */
    modifier onlyToken() {
        require(msg.sender == token); _;
    }
}

contract ArbiPay is Auth {

  using SafeMath for uint256;

  /** ======= EVENTS ======= */

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event AutoLiquify(uint256 _amountETHLiquidity, uint256 _amountToLiquify);
  event BuybackMultiplierActive(uint256 _duration);

  /** ======= ERC20 PARAMS ======= */

  string constant _name =  "TestArbiPay";
  string constant _symbol = "TESTAPAY";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
  
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowances;

  /** ======= GLOBAL PARAMS ======= */

  uint256 public constant MASK = type(uint128).max;

  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = address(0);

  address public EP = address(0);
  address public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  
  IUniswapV2Router02 public router;
  address public routerAddress; 
  address public pair;

  RewardDistributor distributor;
  address public distributorAddress;

  uint256 distributorGas = 500000;

  // Anti-bot and anti-whale mappings and variables
  mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
  mapping(address => bool) blacklisted;
  bool public transferDelayEnabled = true;

  // 10% Fee in total; 
  uint256 totalFee = 1000;
  uint256 feeDenominator = 10000;
  
  // 2% goes to providing liquidity to the pair; 
  uint256 liquidityFee = 200;
  // 4% Goes to the reflections for token holders; 
  uint256 reflectionFee = 400;
  // 2% Goes to jackpot;
  uint256 jackpotFee = 200;
  // 2% Goes to the dev team; 
  uint256 devFee = 200;

  uint256 buybackFee = 0;

  //liq address
  address public autoLiquidityReceiver = address(0); 

  // Address that gets the jackpot fee's; 
  address public jackpotFeeReceiver = address(0);

  // Dev address that recives the devFees;
  address public devFeeReceiver = address(0); 


  uint256 targetLiquidity = 1000;
  uint256 targetLiquidityDenominator = 100;

  uint256 public _maxTxAmount = _totalSupply.div(200); // 0.5%
  uint256 public _maxWallet = _totalSupply.div(50); // 2%

  mapping (address => bool) isFeeExempt;        
  mapping (address => bool) isTxLimitExempt;    
  mapping (address => bool) isRewardExempt;   
  mapping (address => bool) public isFree;     

  // BlockNumber of launch; 
  uint256 public launchedAt;
  // Timestamp of launch; 
  uint256 public launchedAtTimestamp;

  uint256 buybackMultiplierNumerator = 200;
  uint256 buybackMultiplierDenominator = 100;
  uint256 buybackMultiplierLength = 30 minutes;

  uint256 buybackMultiplierTriggeredAt;

  bool public autoBuybackEnabled = false;

  mapping (address => bool) buyBacker;

  uint256 autoBuybackCap;
  uint256 autoBuybackAccumulator;
  uint256 autoBuybackAmount;
  uint256 autoBuybackBlockPeriod;
  uint256 autoBuybackBlockLast;

  bool public swapEnabled = true;
  uint256 public swapThreshold = _totalSupply / 100; // 1%;

  bool inSwap;

  /** ======= CONSTRUCTOR ======= */

  constructor (
    address _router,
    address _jackpot,
    address _ep
  ) {
    EP = _ep;

    autoLiquidityReceiver = msg.sender; 
    jackpotFeeReceiver = _jackpot;
    devFeeReceiver = msg.sender; 

    routerAddress = _router;
    // Initialize the router; 
    router = IUniswapV2Router02(_router);

    // Make a pair for WETH/ARB; 
    pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));

    _allowances[address(this)][address(_router)] = type(uint256).max;

    // Create a new Divdistributor contract; 
    distributor = new RewardDistributor(_router);

    // Set the address; 
    distributorAddress = address(distributor);

    isFree[msg.sender] = true;
    isFeeExempt[msg.sender] = true;
    isTxLimitExempt[msg.sender] = true;
    isRewardExempt[pair] = true;
    isRewardExempt[address(this)] = true;
    isRewardExempt[DEAD] = true;
    buyBacker[msg.sender] = true;

    autoLiquidityReceiver = msg.sender;

    // Approve the router with totalSupply; 
    approve(_router, type(uint256).max);

    // Approve the pair with totalSupply; 
    approve(address(pair), type(uint256).max);
    
    // Send totalSupply to msg.sender; 
    _balances[msg.sender] = _totalSupply;

    // Emit transfer event; 
    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  /** ======= PUBLIC VIEW FUNCTIONS ======= */

  function getTotalFee() public view returns (uint256) {
    return totalFee;
  }

  function getCirculatingSupply() public view returns (uint256) {
      return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
  }

  function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
      return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
  }

  function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
      return getLiquidityBacking(accuracy) > target;
  }

  function isBlacklisted(address account) public view returns (bool) {
      return blacklisted[account];
  }


  /** ======= ERC20 FUNCTIONS ======= */

  function totalSupply() external view returns (uint256) { 
    return _totalSupply; 
  }

  function decimals() external pure returns (uint8) { 
    return _decimals; 
  }

  function symbol() external pure returns (string memory) { 
    return _symbol; 
  }

  function name() external pure  returns (string memory) { 
    return _name; 
  }

  function balanceOf(address account) public view returns (uint256) { 
    return _balances[account]; 
  }

  function allowance(address holder, address spender) public view returns (uint256) { 
    return _allowances[holder][spender]; 
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function approveMax(address spender) external returns (bool) {
      return approve(spender, _totalSupply);
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    if(_allowances[sender][msg.sender] != _totalSupply){
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
    }
    return _transferFrom(sender, recipient, amount);
  }


  function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
    require(!blacklisted[sender],"Sender blacklisted");
    require(!blacklisted[recipient],"Receiver blacklisted");

    // If in swap just do a basic transfer. Same as normal ERC20 transferFrom function;
    if(inSwap) { 
        return _basicTransfer(sender, recipient, amount); 
    }

    // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
    if (transferDelayEnabled) {
        if (
            recipient != owner() &&
            recipient != routerAddress &&
            recipient != pair
        ) {
            require(
                _holderLastTransferTimestamp[tx.origin] + 1 <
                    block.number,
                "_transfer:: Transfer Delay enabled.  Only one purchase per two blocks allowed."
            );
            _holderLastTransferTimestamp[tx.origin] = block.number;
        }
    }
      
    bool isSell = recipient == pair || recipient == routerAddress;
    
    checkTxLimit(sender, amount);
    
    // Max wallet check excluding pair and router
    if (!isSell && !isFree[recipient]){
        require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
    }
    
    // No swapping on buy and tx
    if (isSell) {
        if(shouldSwapBack()){ 
            swapBack(); 
        }
        if(shouldAutoBuyback()){ 
            triggerAutoBuyback(); 
        }
    }
    

    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

    uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;

    _balances[recipient] = _balances[recipient].add(amountReceived);

    if(!isRewardExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
    if(!isRewardExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

    try distributor.process(distributorGas) {} catch {}

    emit Transfer(sender, recipient, amountReceived);
    return true;
  }

  function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    _balances[recipient] = _balances[recipient].add(amount);
    return true;
  }

  /** ======= INTERNAL VIEW FUNCTIONS ======= */

 
  function checkTxLimit(address _sender, uint256 _amount) internal view {
    require(_amount <= _maxTxAmount || isTxLimitExempt[_sender], "TX Limit Exceeded");
  }

  function shouldTakeFee(address _sender, address _recipient) internal view returns (bool) {
    bool _takeFee = !isFeeExempt[_sender];
    if(_takeFee) {
    _takeFee = (_sender == pair || _recipient == pair);
    }
    return _takeFee;
  }

  function shouldSwapBack() internal view returns (bool) {
    return 
      msg.sender != pair
        && 
      !inSwap
        && 
      swapEnabled
        && 
      _balances[address(this)] >= swapThreshold;
  }

  function shouldAutoBuyback() internal view returns (bool) {
    return 
      msg.sender != pair
        && 
      !inSwap
        && 
      autoBuybackEnabled
        && 
      autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && 
      address(this).balance >= autoBuybackAmount;
  }

  function launched() internal view returns (bool) {
    return launchedAt != 0;
  }

  /** ======= INTERNAL FUNCTIONS ======= */

  function takeFee(address _sender, uint256 _amount) internal returns (uint256) {
    // Calculate the fee amount; 
    uint256 feeAmount = _amount.mul(totalFee).div(feeDenominator);

    // Add the fee to the contract balance; 
    _balances[address(this)] = _balances[address(this)].add(feeAmount);

    emit Transfer(_sender, address(this), feeAmount);

    return _amount.sub(feeAmount);
  }

  function triggerAutoBuyback() internal {
    // Buy tokens and send them to burn address; 
    buyTokens(autoBuybackAmount, DEAD);
    // Update params: 
    autoBuybackBlockLast = block.number;
    autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    // Set autoBuybackEnabled if needed;
    if(autoBuybackAccumulator > autoBuybackCap){ 
      autoBuybackEnabled = false; 
    }
  }

  function swapBack() internal swapping {

    uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;

    uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);

    uint256 amountToSwap = _balances[address(this)].sub(amountToLiquify);

    uint256 balanceBefore = address(this).balance;

    address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = WETH;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amountToSwap,
        0,
        path,
        address(this),
        block.timestamp
    );
    uint256 amountETH = address(this).balance.sub(balanceBefore);

    uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

    uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);

    // Calculate the amount used for reflection fee's; 
    uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
    // Calculate the amount used for jackpot fee's: 
    uint256 amountETHJackpot = amountETH.mul(jackpotFee).div(totalETHFee);

    // Send the reward fee's to the distributor; 
    distributor.deposit{value: amountETHReflection}();

    // Send the jackpot fee's; 
    payable(jackpotFeeReceiver).transfer(amountETHJackpot);
    
    // Handle the liquidity adding; 
    if(amountToLiquify > 0){
        router.addLiquidityETH{value: amountETHLiquidity}(
            address(this),
            amountToLiquify,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
        emit AutoLiquify(amountETHLiquidity, amountToLiquify);
    }

    // Send the dev fee's; 
    payable(devFeeReceiver).transfer(address(this).balance);
  }

  function buyTokens(uint256 _amount, address _to) internal swapping {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(this);

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
        0,
        path,
        _to,
        block.timestamp
    );
  }

  

  /** ======= AUTHORIZED ONLY FUNCTIONS ======= */

  function clearBuybackMultiplier() external authorized {
    buybackMultiplierTriggeredAt = 0;
  }

  function launch() public authorized {
    require(launchedAt == 0, "Already launched");
    launchedAt = block.number;
    launchedAtTimestamp = block.timestamp;
  }
  
  function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
    autoBuybackEnabled = _enabled;
    autoBuybackCap = _cap;
    autoBuybackAccumulator = 0;
    autoBuybackAmount = _amount;
    autoBuybackBlockPeriod = _period;
    autoBuybackBlockLast = block.number;
  }

  function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
    require(numerator / denominator <= 2 && numerator > denominator);
    buybackMultiplierNumerator = numerator;
    buybackMultiplierDenominator = denominator;
    buybackMultiplierLength = length;
  }

  function setMaxWallet(uint256 amount) external authorized {
    require(amount >= _totalSupply / 1000);
    _maxWallet = amount;
  }

  function setTxLimit(uint256 amount) external authorized {
      require(amount >= _totalSupply / 1000);
      _maxTxAmount = amount;
  }

  function setIsRewardExempt(address holder, bool exempt) external authorized {
    require(holder != address(this) && holder != pair);
    isRewardExempt[holder] = exempt;
    if(exempt){
        distributor.setShare(holder, 0);
    }else{
        distributor.setShare(holder, _balances[holder]);
    }
  }

  function setIsFeeExempt(address holder, bool exempt) external authorized {
    isFeeExempt[holder] = exempt;
  }

  function setIsTxLimitExempt(address holder, bool exempt) external authorized {
    isTxLimitExempt[holder] = exempt;
  }
  
  function setFees(
    uint256 _liquidityFee, 
    uint256 _buybackFee, 
    uint256 _reflectionFee, 
    uint256 _jackpotFee,
    uint256 _devFee,
    uint256 _feeDenominator
  ) external authorized {
    liquidityFee = _liquidityFee;
    buybackFee = _buybackFee;
    reflectionFee = _reflectionFee;
    jackpotFee = _jackpotFee;
    devFee = _devFee;
    totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_jackpotFee).add(devFee);
    feeDenominator = _feeDenominator;
    require(totalFee < feeDenominator / 4);
  }

  function setFeeReceivers(address _autoLiquidityReceiver, address _jackpotFeeReceiver, address _devFeeReceiver) external authorized {
      autoLiquidityReceiver = _autoLiquidityReceiver;
      jackpotFeeReceiver = _jackpotFeeReceiver;
      devFeeReceiver = _devFeeReceiver;
  }

  function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
      swapEnabled = _enabled;
      swapThreshold = _amount;
  }

  function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
      targetLiquidity = _target;
      targetLiquidityDenominator = _denominator;
  }

  function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
      distributor.setDistributionCriteria(_minPeriod, _minDistribution);
  }

  function setDistributorSettings(uint256 gas) external authorized {
      require(gas < 1000000);
      distributorGas = gas;
  }

  /** ======= OWNER ONLY FUNCTION ======= */

  function Collect() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  function setFree(address holder) public onlyOwner {
    isFree[holder] = true;
  }
  
  function unSetFree(address holder) public onlyOwner {
    isFree[holder] = false;
  }
  
  function checkFree(address holder) public view onlyOwner returns(bool){
    return isFree[holder];
  }

  function blacklist(address _black) public onlyOwner {
    blacklisted[_black] = true;
  }

  function unblacklist(address _black) public onlyOwner {
    blacklisted[_black] = false;
  }

  // disable Transfer delay - cannot be reenabled
  function disableTransferDelay() external onlyOwner returns (bool) {
    transferDelayEnabled = false;
    return true;
  }

  function setEP(address _ep) public onlyOwner {
    EP = _ep;
    distributor.setEP(_ep);
  }

  /** ======= MODIFIERS ======= */

  modifier swapping() { 
    inSwap = true; 
    _; 
    inSwap = false; 
  }

  modifier onlyBuybacker() { 
    require(buyBacker[msg.sender] == true, "");
    _; 
  }

  // Make contract able to recive ETH; 
  receive() external payable {}
  
}