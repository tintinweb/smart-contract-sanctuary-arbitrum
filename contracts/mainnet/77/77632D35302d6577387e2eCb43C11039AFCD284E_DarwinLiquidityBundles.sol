// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: BSL-1.1

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDarwin} from "../darwin-token-contracts/contracts/interface/IDarwin.sol";

import {IDarwinSwapRouter} from "./interfaces/IDarwinSwapRouter.sol";
import {IDarwinSwapPair} from "./interfaces/IDarwinSwapPair.sol";
import {IDarwinSwapFactory} from "./interfaces/IDarwinSwapFactory.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IDarwinLiquidityBundles} from "./interfaces/IDarwinLiquidityBundles.sol";
import {IDarwinMasterChef} from "./interfaces/IMasterChef.sol";

contract DarwinLiquidityBundles is Ownable, IDarwinLiquidityBundles {

    /*///////////////////////////////////////////////////////////////
                                Variables
    //////////////////////////////////////////////////////////////*/

    IDarwinSwapFactory public darwinFactory;
    IDarwinMasterChef public masterChef;
    IDarwinSwapRouter public darwinRouter;
    address public WETH;
    uint256 public constant LOCK_PERIOD = 365 days;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    // User address -> LP Token address -> User info
    mapping(address => mapping(address => User)) public userInfo;
    // Token address -> total amount of LP for this bundle
    mapping(address => uint256) public totalLpAmount;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        darwinFactory = IDarwinSwapFactory(msg.sender);
    }

    function initialize(address _darwinRouter, IDarwinMasterChef _masterChef, address _WETH) external {
        require(msg.sender == address(darwinFactory), "DarwinLiquidityBundles: INVALID");
        masterChef = _masterChef;
        darwinRouter = IDarwinSwapRouter(_darwinRouter);
        WETH = _WETH;
    }

    function tokenInfo(address _token) public view returns (uint tokenAmount, uint priceInWeth) {
        tokenAmount = IERC20(_token).balanceOf(address(this));

        if (darwinFactory.getPair(_token, WETH) == address(0)) {
            return (tokenAmount, 0);
        }

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;

        // get pair price in WETH on DarwinSwap
        try darwinRouter.getAmountsOut(10 ** IERC20(_token).decimals(), path) returns (uint256[] memory prices) {
            priceInWeth = prices[1];
        } catch {
            priceInWeth = 0;
        }
    }

    /// @notice Enter a Bundle
    /// @dev This functions takes an amount of ETH from a user and pairs it with a X amount of _token (already present in the contract), and locks it for a year. After the lock ends, the user will be able to not only withdraw the ETH he provided, but also the respective token amount.
    /// @param _token The bundle token address
    /// @param _desiredTokenAmount The amount of the token to pair ETH with
    function enterBundle(
        address _token,
        uint _desiredTokenAmount
    ) external payable {
        (uint tokenAmount, uint priceInWeth) = tokenInfo(_token);
        if (_desiredTokenAmount > tokenAmount) {
            _desiredTokenAmount = tokenAmount;
        }

        uint256 ethValue = (_desiredTokenAmount * priceInWeth) / (10 ** IERC20(_token).decimals());
        require(msg.value >= ethValue, "DarwinLiquidityBundles: INSUFFICIENT_ETH");
        if (ethValue == 0) {
            ethValue = msg.value;
        }

        IERC20(_token).approve(address(darwinRouter), _desiredTokenAmount);
        (uint amountToken, uint amountETH, uint liquidity) = darwinRouter.addLiquidityETH{value: ethValue}(
            _token,
            _desiredTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 600
        );

        User storage user = userInfo[msg.sender][_token];

        totalLpAmount[_token] += liquidity;
        user.lpAmount += liquidity;
        user.lockEnd = block.timestamp + LOCK_PERIOD;
        user.bundledEth += amountETH;
        user.bundledToken += amountToken;

        // refund dust ETH, if any
        if (msg.value > amountETH) {
            (bool success,) = payable(msg.sender).call{value: (msg.value - amountETH)}("");
            require(success, "DarwinLiquidityBundles: ETH_TRANSFER_FAILED");
        }

        address pair = darwinFactory.getPair(_token, WETH);
        if (masterChef.poolExistence(IERC20(pair))) {
            IERC20(pair).approve(address(masterChef), liquidity);
            masterChef.depositByLPToken(IERC20(pair), liquidity, false, 0);
            user.inMasterchef = true;
        }

        emit EnterBundle(msg.sender, amountToken, amountETH, block.timestamp, block.timestamp + LOCK_PERIOD);
    }

    /// @notice Exit from a Bundle
    /// @dev If the lock period of the interested user on the interested token has ended, withdraws the bundled LP and burns eventual earned darwin (if the bundle was an inMasterchef one)
    /// @param _token The bundle token address
    function exitBundle(
        address _token
    ) external {
        User storage user = userInfo[msg.sender][_token];

        require(user.lockEnd <= block.timestamp, "DarwinLiquidityBundles: LOCK_NOT_ENDED");
        require(user.lpAmount > 0, "DarwinLiquidityBundles: NO_BUNDLED_LP");

        // If pool exists on masterchef and bundle is staked on it, withdraw from it
        uint lpAmount;
        address pair = darwinFactory.getPair(_token, WETH);
        if (masterChef.poolExistence(IERC20(pair)) && user.inMasterchef) {
            lpAmount = IERC20(pair).balanceOf(address(this));
            uint pid;
            IDarwinMasterChef.PoolInfo[] memory poolInfo = masterChef.poolInfo();
            for (uint i = 0; i < poolInfo.length; i++) {
                if (address(poolInfo[i].lpToken) == pair) {
                    pid = i;
                }
            }
            masterChef.withdrawByLPToken(IERC20(pair), masterChef.userInfo(pid, address(this)).amount);
            lpAmount = IERC20(pair).balanceOf(address(this)) - lpAmount;
            user.inMasterchef = false;
            // Burn eventual earned darwin
            if (masterChef.darwin().balanceOf(address(this)) > 0) {
                IDarwin(address(masterChef.darwin())).burn(masterChef.darwin().balanceOf(address(this)));
            }
        }
        if (lpAmount == 0) {
            lpAmount = user.lpAmount;
        }

        IERC20(darwinFactory.getPair(_token, WETH)).approve(address(darwinRouter), lpAmount);
        (uint256 amountToken, uint256 amountETH) = darwinRouter.removeLiquidityETH(
            _token,
            lpAmount,
            0,
            0,
            address(msg.sender),
            block.timestamp + 600
        );

        totalLpAmount[_token] -= user.lpAmount;
        user.lpAmount = 0;
        user.bundledEth = 0;
        user.bundledToken = 0;

        emit ExitBundle(msg.sender, amountToken, amountETH, block.timestamp);
    }

    /// @notice Harvest Darwin from an inMasterchef bundle, and re-lock the bundle for a year
    /// @dev If the lock period of the interested user on the interested token has ended, withdraws the earned Darwin and locks the bundle in for 1 more year
    /// @param _token The bundle token address
    function harvestAndRelock(
        address _token
    ) external {
        User storage user = userInfo[msg.sender][_token];

        require(user.lockEnd <= block.timestamp, "DarwinLiquidityBundles: LOCK_NOT_ENDED");
        require(user.lpAmount > 0 && user.inMasterchef, "DarwinLiquidityBundles: NO_BUNDLE_OR_NOT_IN_MASTERCHEF");

        address pair = darwinFactory.getPair(_token, WETH);
        masterChef.withdrawByLPToken(IERC20(pair), 0);

        // Send eventual earned darwin to user
        uint amountDarwin = masterChef.darwin().balanceOf(address(this));
        if (amountDarwin > 0) {
            masterChef.darwin().transfer(msg.sender, amountDarwin);
        }

        // Re-lock for 1 year
        user.lockEnd = block.timestamp + LOCK_PERIOD;

        emit HarvestAndRelock(msg.sender, amountDarwin, block.timestamp);
    }

    /// @notice Updates a LP token by destructuring it and eventually swapping
    /// @param _lpToken The interested LP token address
    function update(address _lpToken) external {
        IDarwinSwapPair pair = IDarwinSwapPair(_lpToken);
        uint liquidity = IERC20(address(pair)).balanceOf(address(this));
        if (liquidity > 0) {
            IERC20(address(pair)).approve(address(darwinRouter), liquidity);
            address token = pair.token0() == WETH ? pair.token1() : pair.token0();
            (, uint amountETH) = darwinRouter.removeLiquidityETH(token, liquidity, 0, 0, address(this), block.timestamp + 600);

            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = token;
            darwinRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(0, path, address(this), block.timestamp + 600);
        }
    }

    // How much TOKEN and ETH is being holded in the bundle
    function holdings(address _user, address _token) external view returns(uint256 eth, uint256 token) {
        User memory user = userInfo[_user][_token];
        (uint reserve0, uint reserve1,) = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).getReserves();
        uint reserveEth = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).token0() == darwinRouter.WETH() ? reserve0 : reserve1;
        uint reserveToken = IDarwinSwapPair(darwinFactory.getPair(_token, WETH)).token0() == darwinRouter.WETH() ? reserve1 : reserve0;
        reserveEth = (reserveEth * user.lpAmount) / IERC20(darwinFactory.getPair(_token, WETH)).totalSupply();
        reserveToken = (reserveToken * user.lpAmount) / IERC20(darwinFactory.getPair(_token, WETH)).totalSupply();
        eth = reserveEth;
        token = reserveToken;
    }

    // (For bundles that have a respective masterchef farm) - How much pending darwin for this bundle
    function pendingDarwin(address _user, address _token) external view returns(uint256) {
        User memory user = userInfo[_user][_token];
        if (user.inMasterchef) {
            uint pid;
            IDarwinMasterChef.PoolInfo[] memory poolInfo = masterChef.poolInfo();
            for (uint i = 0; i < poolInfo.length; i++) {
                if (address(poolInfo[i].lpToken) == darwinFactory.getPair(_token, WETH)) {
                    pid = i;
                }
            }
            if (totalLpAmount[_token] > 0) {
                return (masterChef.pendingDarwin(pid, address(this)) * user.lpAmount) / totalLpAmount[_token];
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    // (For bundles that didn't have a respective masterchef farm at first but after bundling they have one) - Stake bundled LP in MasterChef to earn darwin
    function stakeBundleInMasterChef(address _token) external {
        User storage user = userInfo[msg.sender][_token];
        require(user.lpAmount > 0 && !user.inMasterchef, "DarwinLiquidityBundles: NO_BUNDLE_OR_ALREADY_STAKED");
        
        address pair = darwinFactory.getPair(_token, WETH);
        require (masterChef.poolExistence(IERC20(pair)), "DarwinLiquidityBundles: NO_SUCH_POOL_IN_MASTERCHEF");
        
        IERC20(pair).approve(address(masterChef), user.lpAmount);
        masterChef.depositByLPToken(IERC20(pair), user.lpAmount, false, 0);
        user.inMasterchef = true;

        emit StakeInMasterchef(msg.sender, user.lpAmount, block.timestamp);
    }


    receive() external payable {}
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: BSL-1.1

import {IDarwinMasterChef} from "./IMasterChef.sol";

interface IDarwinLiquidityBundles {

    struct User {
        uint256 lpAmount;
        uint256 lockEnd;
        uint256 bundledEth;
        uint256 bundledToken;
        bool inMasterchef;
    }

    event EnterBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp,
        uint256 lockEnd
    );

    event ExitBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp
    );

    event StakeInMasterchef(
        address indexed user,
        uint256 liquidity,
        uint256 timestamp
    );

    event HarvestAndRelock(
        address indexed user,
        uint256 amountDarwin,
        uint256 timestamp
    );

    function initialize(address _darwinRouter, IDarwinMasterChef _masterChef, address _WETH) external;
    function update(address _lpToken) external;
}

pragma solidity ^0.8.14;

import "./IDarwinLiquidityBundles.sol";
import "./IMasterChef.sol";

interface IDarwinSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function dev() external view returns (address);
    function lister() external view returns (address);
    function feeTo() external view returns (address);
    function router() external view returns (address);
    function liquidityBundles() external view returns (IDarwinLiquidityBundles);
    function masterChef() external view returns (IDarwinMasterChef);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function INIT_CODE_HASH() external pure returns(bytes32);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setDev(address) external;
    function setLister(address) external;
    function setRouter(address) external;
}

pragma solidity ^0.8.14;

interface IDarwinSwapPair {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function liquidityInjector() external view returns (address);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address[2] memory firstAndLastInPath) external;
    function skim(address to) external;
    function sync() external;

    function swapWithoutToks(address tokenIn, uint amountIn) external;

    function initialize(address, address, address) external;
}

pragma solidity ^0.8.14;

interface IDarwinSwapRouter {
    // [[[[[ ROUTER 01 FUNCTIONS ]]]]]

    function factory() external view returns (address);
    function WETH() external view returns (address);

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
    function addLiquidityWithoutReceipt(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        uint deadline
    ) external;
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);


    // [[[[[ ROUTER 02 FUNCTIONS ]]]]]

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

pragma solidity ^0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function owner() external view returns (address);
    function getOwner() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

interface IDarwinMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lockedAmount;   // The part of `amount` that is locked.
        uint256 lockEnd;        // Timestamp of end of lock of the locked amount.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARWINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarwinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarwinPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. DARWINs to distribute per second.
        uint256 lastRewardTime;     // Last time DARWINs distribution occurs.
        uint256 accDarwinPerShare;  // Accumulated DARWINs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
    }

    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool);
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool);
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo() external view returns (PoolInfo[] memory);
    function poolExistence(IERC20) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function darwin() external view returns (IERC20);
    function dev() external view returns (address);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import {IStakedDarwin} from "./IStakedDarwin.sol";

interface IDarwin {

    event ExcludedFromReflection(address account, bool isExcluded);
    event SetPaused(uint timestamp);
    event SetUnpaused(uint timestamp);

    // PUBLIC
    function distributeRewards(uint256 amount) external;
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

    // COMMUNITY
    // function upgradeTo(address newImplementation) external; RESTRICTED
    // function upgradeToAndCall(address newImplementation, bytes memory data) external payable; RESTRICTED
    function setMinter(address user_, bool canMint_) external; // RESTRICTED
    function setMaintenance(address _addr, bool _hasRole) external; // RESTRICTED
    function setSecurity(address _addr, bool _hasRole) external; // RESTRICTED
    function setUpgrader(address _account, bool _hasRole) external; // RESTRICTED
    function setReceiveRewards(address account, bool shouldReceive) external; // RESTRICTED
    function communityPause() external; // RESTRICTED
    function communityUnPause() external;

    // FACTORY
    function registerDarwinSwapPair(address _pair) external;

    // MAINTENANCE
    function setDarwinSwapFactory(address _darwinSwapFactory) external;
    function setDarwinStaking(address _darwinStaking) external;
    function setMasterChef(address _masterChef) external;

    // MINTER
    function mint(address account, uint256 amount) external;

    // VIEW
    function isPaused() external view returns (bool);
    function stakedDarwin() external view returns(IStakedDarwin);
    function MAX_SUPPLY() external pure returns(uint256);

    // BURN
    function burn(uint256 amount) external;

    /// TransferFrom amount is greater than allowance
    error InsufficientAllowance();
    /// Only the DarwinCommunity can call this function
    error OnlyDarwinCommunity();

    /// Input cannot be the zero address
    error ZeroAddress();
    /// Amount cannot be 0
    error ZeroAmount();
    /// Arrays must be the same length
    error InvalidArrayLengths();

    /// Holding limit exceeded
    error HoldingLimitExceeded();
    /// Sell limit exceeded
    error SellLimitExceeded();
    /// Paused
    error Paused();
    error AccountAlreadyExcluded();
    error AccountNotExcluded();

    /// Max supply reached, cannot mint more Darwin
    error MaxSupplyReached();
}

pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}