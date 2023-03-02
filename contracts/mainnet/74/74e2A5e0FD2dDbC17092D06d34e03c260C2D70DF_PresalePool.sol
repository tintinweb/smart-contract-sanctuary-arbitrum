pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

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
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.16;

interface IERC20Token {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function isMinter(address account) external returns (bool);
}

pragma solidity ^0.5.16;

interface IPresaleTimer {
    function isTierPresalePeriod() external view returns (bool);

    function isPresalePeriod() external view returns (bool);

    function isPresaleFinished() external view returns (bool);

    function isLiquidityEnabled() external view returns (bool);

    function isTierDistributionTime() external view returns (bool);

    function isTierClaimable(uint256 _timestamp) external view returns (bool);
}

pragma solidity ^0.5.16;

interface ITierLocker {
    function getAvailableUnlock(address _account)
        external
        view
        returns (uint256);

    function getUserTier(address account) external view returns (uint256);

    function getUserTierInfos(address account)
        external
        view
        returns (
            uint256 _tier,
            uint256 _lockedTimestamp,
            uint256 _amount
        );

    function getTierLockedAmount() external view returns (uint256[5] memory);

    function getTierCounts() external view returns (uint256[5] memory);

    function getTierBP(uint256 _userTier) external view returns (uint256);

    function calculateUserTierReward(address account, uint256 rewardToken)
        external
        view
        returns (uint256);

    function requestPool(string calldata _poolLink) external payable;

    function getRequestPools() external view returns (address[] memory);
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";


library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./uniswapV2/interfaces/IUniswapRouter01.sol";
import "./uniswapV2/interfaces/IUniswapPair.sol";
import "./uniswapV2/interfaces/IWETH.sol";
import "./library/BasisPoints.sol";
import "./interfaces/ITierLocker.sol";
import "./interfaces/IERC20Token.sol";
import "./interfaces/IPresaleTimer.sol";

contract PresalePool is Ownable, ReentrancyGuard {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    IUniswapRouter01 public mainRouter;
    IUniswapPair public pair;
    IERC20 public rewardToken;
    address payable private WETH;

    IERC20 public depositToken;

    uint256 public maxBuyPerAddressBase;

    uint256 public dexEthBP;
    uint256 public launchpadTierBP;
    address payable[] public ethPools;
    uint256[] public ethPoolBPs;

    uint256 public dexTokenBP;
    uint256 public presaleTokenBP;
    address[] public tokenPools;
    uint256[] public tokenPoolBPs;

    uint256 public presalePrice;
    uint256 public presaleTierPriceBP;

    bool public hasSentToDEX;
    bool public hasIssuedTokens;
    bool public hasSentEth;
    bool public hasSwappedReward;

    uint256 public totalSupply;
    uint256 public totalPresaleTokens;
    uint256 public totalPrivateSaleTokens;
    uint256 public totalTokens;
    uint256 public totalSoldTokens;
    uint256 public totalDepositedEth;
    uint256 public totalEth;
    uint256 public totalReward;
    uint256 public finalEndTime;

    IERC20Token public token;
    IPresaleTimer public timer;
    ITierLocker public tierLock;

    uint256[] public tierCounts = [0, 0, 0, 0, 0];
    uint256[] public tierLockedAmounts;
    address[] public path;
    mapping(address => uint256) public userTierLevel;

    mapping(address => uint256) public depositAccounts;
    mapping(address => uint256) public accountEarnedToken;
    mapping(address => uint256) public accountClaimedToken;
    mapping(address => uint256) public accountClaimedReward;

    uint256 public totalDepositors;

    bool public pauseDeposit;

    modifier whenPresaleActive() {
        require(timer.isPresalePeriod(), "Presale not started yet.");
        _;
    }

    modifier whenPresaleFinished() {
        require(timer.isPresaleFinished(), "Presale not finished yet.");
        _;
    }

    modifier whenLiquidityEnabled() {
        require(
            timer.isLiquidityEnabled(),
            "Liquidity creation not enabled yet."
        );
        _;
    }

    modifier whenDistributionStarted() {
        require(
            timer.isTierDistributionTime(),
            "Tier distribution not started yet."
        );
        _;
    }

    modifier whenAddedLiquidity() {
        require(hasSentToDEX, "Liquidity not added yet.");
        _;
    }

    function initialize(
        uint256 _maxBuyPerAddressBase,
        uint256 _presalePrice,
        uint256 _presaleTierPriceBP,
        address _owner,
        address _timer,
        address _token,
        address _tierLock,
        address _mainRouter,
        address _pair,
        address payable _WETH,
        address _rewardToken
    ) external initializer {
        require(
            IERC20Token(_token).isMinter(address(this)),
            "Presale SC must be minter."
        );
        Ownable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = IERC20Token(_token);
        timer = IPresaleTimer(_timer);
        tierLock = ITierLocker(_tierLock);

        maxBuyPerAddressBase = _maxBuyPerAddressBase;

        presalePrice = _presalePrice;
        presaleTierPriceBP = _presaleTierPriceBP;

        mainRouter = IUniswapRouter01(_mainRouter);
        WETH = _WETH;
        rewardToken = IERC20(_rewardToken);
        pair = IUniswapPair(_pair);

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(_owner);
    }

    // Owner functions --------------------------------
    function setTotalPresaleTokens(
        uint256 _totalPresaleTokens,
        address _depositTokenAddress,
        uint256 _totalSupply
    ) external onlyOwner {
        totalPresaleTokens = _totalPresaleTokens;
        depositToken = IERC20(_depositTokenAddress);
        totalSupply = _totalSupply;
    }

    function setSwapInfo(
        address _pair,
        address _rewardToken,
        address[] calldata _path
    ) external onlyOwner {
        rewardToken = IERC20(_rewardToken);
        pair = IUniswapPair(_pair);
        delete path;
        for (uint256 i = 0; i < _path.length; i++) {
            path.push(_path[i]);
        }
    }

    function setEthPools(
        uint256 _dexEthBP,
        uint256 _launchpadTierBP,
        address payable[] calldata _ethPools,
        uint256[] calldata _ethPoolBPs
    ) external onlyOwner {
        require(
            _ethPools.length == _ethPoolBPs.length,
            "Must have exactly one etherPool addresses for each BP."
        );
        delete ethPools;
        delete ethPoolBPs;
        dexEthBP = _dexEthBP;
        launchpadTierBP = _launchpadTierBP;
        uint256 totalEthPoolsBP = _dexEthBP.add(_launchpadTierBP);
        for (uint256 i = 0; i < _ethPools.length; i++) {
            ethPools.push(_ethPools[i]);
            ethPoolBPs.push(_ethPoolBPs[i]);
            totalEthPoolsBP = totalEthPoolsBP.add(_ethPoolBPs[i]);
        }
        require(
            totalEthPoolsBP == 10000,
            "Must allocate exactly 100% (10000 BP) of ether to pools"
        );
    }

    function setTokenPools(
        uint256 _dexTokenBP,
        uint256 _presaleTokenBP,
        address[] calldata _tokenPools,
        uint256[] calldata _tokenPoolBPs
    ) external onlyOwner {
        require(
            _tokenPools.length == _tokenPoolBPs.length,
            "Must have exactly one tokenPool addresses for each BP."
        );
        delete tokenPools;
        delete tokenPoolBPs;
        dexTokenBP = _dexTokenBP;
        presaleTokenBP = _presaleTokenBP;
        uint256 totalTokenPoolBPs = _dexTokenBP.add(_presaleTokenBP);
        for (uint256 i = 0; i < _tokenPools.length; i++) {
            tokenPools.push(_tokenPools[i]);
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(
            totalTokenPoolBPs == 10000,
            "Must allocate exactly 100% (10000 BP) of tokens to pools"
        );
    }

    function setPrivateSaleTokens(
        address[] calldata _tokenHolders,
        uint256[] calldata _tokenAmounts
    ) external onlyOwner {
        require(
            _tokenHolders.length == _tokenAmounts.length,
            "Must have exactly one tokenholder addresses for each token amount."
        );
        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            if (_tokenAmounts[i] == 0) {
                totalPrivateSaleTokens = totalPrivateSaleTokens.sub(
                    accountEarnedToken[_tokenHolders[i]]
                );
                accountEarnedToken[_tokenHolders[i]] = 0;
            } else {
                totalPrivateSaleTokens = totalPrivateSaleTokens.add(
                    _tokenAmounts[i]
                );
            }
            accountEarnedToken[_tokenHolders[i]] = accountEarnedToken[
                _tokenHolders[i]
            ].add(_tokenAmounts[i]);
        }
    }

    function sendToDEX() external whenLiquidityEnabled nonReentrant {
        require(ethPools.length > 0, "Must have set ether pools");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToDEX, "Has already sent to DEX.");
        finalEndTime = now + 15;
        hasSentToDEX = true;
        totalTokens = totalSoldTokens.divBP(presaleTokenBP);
        uint256 dexTokens = totalTokens.mulBP(dexTokenBP);
        token.mint(address(this), dexTokens);
        token.approve(address(mainRouter), dexTokens);
        uint256 dexETH = 0;
        if (isETHMode()) {
            totalEth = address(this).balance;
            dexETH = totalEth.mulBP(dexEthBP);
            mainRouter.addLiquidityETH.value(dexETH)(
                address(token),
                dexTokens,
                dexTokens,
                dexETH,
                address(0x000000000000000000000000000000000000dEaD),
                finalEndTime
            );
        } else {
            totalEth = depositToken.balanceOf(address(this));
            dexETH = totalEth.mulBP(dexEthBP);
            depositToken.approve(address(mainRouter), dexETH);
            mainRouter.addLiquidity(
                address(depositToken),
                address(token),
                dexETH,
                dexTokens,
                dexETH,
                dexTokens,
                address(0x000000000000000000000000000000000000dEaD),
                finalEndTime
            );
        }
    }

    function issueTokens() external whenLiquidityEnabled whenAddedLiquidity {
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        for (uint256 i = 0; i < tokenPools.length; ++i) {
            if (tokenPoolBPs[i] > 0) {
                token.mint(tokenPools[i], totalTokens.mulBP(tokenPoolBPs[i]));
            }
        }
        token.mint(address(this), totalSoldTokens.add(totalPrivateSaleTokens));
        uint256 _allMinted = totalTokens.add(totalPrivateSaleTokens);
        if (_allMinted < totalSupply) {
            token.mint(tokenPools[0], totalSupply.sub(_allMinted));
        }
    }

    function sendEth()
        external
        whenLiquidityEnabled
        whenAddedLiquidity
        nonReentrant
    {
        require(!hasSentEth, "Has already sent Eth.");
        hasSentEth = true;
        bool _ok = true;
        for (uint256 i = 0; i < ethPools.length; ++i) {
            if (ethPoolBPs[i] > 0) {
                if (isETHMode()) {
                    ethPools[i].transfer(totalEth.mulBP(ethPoolBPs[i]));
                } else {
                    bool _result = depositToken.transfer(
                        ethPools[i],
                        totalEth.mulBP(ethPoolBPs[i])
                    );
                    if (!_result) _ok = false;
                }
            }
        }
        require(_ok, "Token Transfer failed.");
        totalReward = totalEth.mulBP(launchpadTierBP);
    }

    function setTierLockedAmounts() external onlyOwner {
        delete tierLockedAmounts;
        delete tierCounts;
        uint256[5] memory _tierLockedAmounts = tierLock.getTierLockedAmount();
        uint256[5] memory _tierCounts = tierLock.getTierCounts();
        for (uint256 i = 0; i < _tierLockedAmounts.length; i++) {
            tierLockedAmounts.push(_tierLockedAmounts[i]);
            tierCounts.push(_tierCounts[i]);
        }
    }

    function emergencyEthWithdrawl()
        external
        whenLiquidityEnabled
        whenAddedLiquidity
        nonReentrant
        onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }

    function emergencyTokenWithdraw(address _tokenAddr)
        external
        whenDistributionStarted
        whenAddedLiquidity
        nonReentrant
        onlyOwner
    {
        IERC20(_tokenAddr).transfer(
            msg.sender,
            IERC20(_tokenAddr).balanceOf(address(this))
        );
    }

    function setDepositPause(bool val) external onlyOwner {
        pauseDeposit = val;
    }

    // user functions
    function deposit(address payable _referrer, uint256 _amount)
        public
        payable
        whenPresaleActive
        nonReentrant
    {
        require(!pauseDeposit, "Deposits are paused.");
        require(
            _referrer == address(0x0),
            "Referrer is not used in this version."
        );
        uint256 depositVal = msg.value;
        if (isETHMode()) {
            require(depositVal == _amount, "Invalid ETH amount");
        } else {
            require(msg.value == 0, "Invalid Token amount");
            depositVal = _amount;
        }
        if (timer.isTierPresalePeriod()) {
            require(
                depositAccounts[msg.sender].add(depositVal) <=
                    maxBuyPerAddressBase.mul(tierLock.getUserTier(msg.sender)),
                "Deposit exceeds max buy per address for addresses."
            );
            require(
                tierLock.getUserTier(msg.sender) > 0,
                "User need to have tier"
            );
        } else {
            require(
                depositAccounts[msg.sender].add(depositVal) <=
                    maxBuyPerAddressBase,
                "Deposit exceeds max buy per address for addresses."
            );
        }

        uint256 tokensToIssue = depositVal.mul(10**18).div(
            calculateRatePerEth()
        );
        require(
            totalSoldTokens.add(tokensToIssue) <= totalPresaleTokens,
            "Presale Done"
        );
        if (!isETHMode()) {
            uint256 allowance = depositToken.allowance(
                msg.sender,
                address(this)
            );
            require(depositVal <= allowance, "Insufficient allowance.");

            bool _ok = depositToken.transferFrom(
                msg.sender,
                address(this),
                depositVal
            );
            require(_ok, "Transfer from failed.");
        }

        depositAccounts[msg.sender] = depositAccounts[msg.sender].add(
            depositVal
        );
        totalDepositedEth = totalDepositedEth.add(depositVal);
        totalSoldTokens = totalSoldTokens.add(tokensToIssue);

        accountEarnedToken[msg.sender] = accountEarnedToken[msg.sender].add(
            tokensToIssue
        );
    }

    function redeem() external whenLiquidityEnabled whenAddedLiquidity {
        uint256 claimable = calculateReedemable(msg.sender);
        require(claimable > 0, "Must have claimable amount.");
        require(accountClaimedToken[msg.sender] == 0, "Already claimed user.");
        accountClaimedToken[msg.sender] = claimable;
        token.transfer(msg.sender, claimable);
    }

    function calculateReedemable(address _account)
        public
        view
        returns (uint256)
    {
        if (!hasSentToDEX) return 0;
        uint256 earnedToken = accountEarnedToken[_account];
        uint256 claimable = earnedToken.sub(accountClaimedToken[_account]);
        return claimable;
    }

    function redeemTier() external whenDistributionStarted {
        require(hasSentEth, "Must have sent Eth before any redeem tiers.");
        uint256 claimable = calculateReedemableTier(msg.sender);
        require(claimable > 0, "Must have claimable amount.");
        require(accountClaimedReward[msg.sender] == 0, "Already claimed user.");
        accountClaimedReward[msg.sender] = claimable; // Eth/usdt unit
        uint256 swappedReward = 0;
        if (isETHMode()) {
            swappedReward = xETH2Reward(claimable, address(pair));
        } else {
            uint256 _allowance = depositToken.allowance(
                address(this),
                address(mainRouter)
            );
            if (_allowance < claimable) {
                depositToken.approve(address(mainRouter), totalReward);
            }
            swappedReward = xTOKEN2Reward(claimable, path);
        }
        rewardToken.transfer(msg.sender, swappedReward);
    }

    function calculateReedemableTier(address _account)
        public
        view
        returns (uint256)
    {
        (
            uint256 _tier,
            uint256 _lockedTimestamp,
            uint256 _lockedAmount
        ) = tierLock.getUserTierInfos(_account);
        if (_tier == 0) return 0;
        if (!timer.isTierClaimable(_lockedTimestamp)) return 0;
        if (_lockedAmount == 0) return 0;
        if (tierLockedAmounts[_tier] <= 0) return 0;
        uint256 _earnedReward = totalReward
            .mulBP(tierLock.getTierBP(_tier))
            .mul(_lockedAmount)
            .div(tierLockedAmounts[_tier]);
        uint256 claimable = _earnedReward.sub(accountClaimedReward[_account]);
        return claimable;
    }

    function calculateRatePerEth() public view returns (uint256) {
        if (timer.isTierPresalePeriod()) return presalePrice;
        return presalePrice.addBP(presaleTierPriceBP);
    }

    function isETHMode() public view returns (bool) {
        return (address(depositToken) == address(0));
    }

    // internal functions
    function xETH2Reward(uint256 _amountETH, address _pair)
        internal
        returns (
            uint256 // _amountReward
        )
    {
        require(isETHMode(), "Please use ERC20 functions.");
        IWETH(WETH).deposit.value(_amountETH)();
        _safeTransfer(address(WETH), _pair, _amountETH);
        uint256 _amountReward = _toERC20(_pair, _amountETH);
        hasSwappedReward = true;
        return _amountReward;
    }

    function xTOKEN2Reward(uint256 _amountToken, address[] memory _path)
        internal
        returns (
            uint256 // _amountReward
        )
    {
        require(!isETHMode(), "Please use ETH functions.");
        require(_amountToken > 0, "Amount invalid");
        require(_path.length > 0, "Swap Path invalid");
        finalEndTime = now + 15;
        hasSwappedReward = true;
        uint256[] memory _amounts = mainRouter.getAmountsOut(
            _amountToken,
            _path
        );
        mainRouter.swapExactTokensForTokens(
            _amountToken,
            0,
            _path,
            address(this),
            finalEndTime
        );
        return _amounts[_path.length - 1];
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).transfer(_to, _amount);
    }

    // newly added code for ERC20 conversion
    function _toERC20(address _pair, uint256 _amountInWeth)
        internal
        returns (
            uint256 // amountOut
        )
    {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(_pair)
            .getReserves();
        address token0 = IUniswapPair(_pair).token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == WETH
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountInWithFee = _amountInWeth.mul(9975);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        uint256 _amountOut = numerator / denominator;
        (uint256 amount0Out, uint256 amount1Out) = token0 == WETH
            ? (uint256(0), _amountOut)
            : (_amountOut, uint256(0));
        IUniswapPair(_pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            new bytes(0)
        );
        return _amountOut;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

interface IUniswapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

interface IUniswapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}