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

pragma solidity ^0.8.14;

import "./interfaces/IDarwinSwapERC20.sol";

contract DarwinSwapERC20 is IDarwinSwapERC20 {
    string public constant name = "DarwinSwap Pair";
    string public constant symbol = "DARWIN-LP";
    uint8 public constant decimals = 18;
    uint  internal _totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        _totalSupply = _totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "DarwinSwap: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "DarwinSwap: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function totalSupply() public view virtual returns (uint) {}
}

pragma solidity ^0.8.14;

import "./DarwinSwapPair.sol";
import "./DarwinLiquidityBundles.sol";
import "./LiquidityInjector.sol";

import {IDarwinSwapRouter} from "./interfaces/IDarwinSwapRouter.sol";
import {IDarwinSwapFactory, IDarwinLiquidityBundles} from "./interfaces/IDarwinSwapFactory.sol";
import {IDarwinMasterChef} from "./interfaces/IMasterChef.sol";

contract DarwinSwapFactory is IDarwinSwapFactory {
    address public dev;
    address public router;
    address public lister;
    address public feeTo;
    IDarwinLiquidityBundles public liquidityBundles;
    IDarwinMasterChef public masterChef;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    bytes32 public constant INIT_CODE_HASH = keccak256(abi.encodePacked(type(DarwinSwapPair).creationCode));

    constructor(address _lister, IDarwinMasterChef _masterChef) {
        dev = msg.sender;
        lister = _lister;
        masterChef = _masterChef;
        // Create LiquidityBundles contract
        bytes memory bytecode = type(DarwinLiquidityBundles).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        address _liquidityBundles;
        assembly {
            _liquidityBundles := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        liquidityBundles = IDarwinLiquidityBundles(_liquidityBundles);
    }

    modifier onlyDev() {
        require(msg.sender == dev, "DarwinSwap: CALLER_NOT_DEV");
        _;
    }

    modifier onlyLister() {
        require(msg.sender == lister, "DarwinSwap: CALLER_NOT_LISTER_CONTRACT");
        _;
    }

    function createPair(address tokenA, address tokenB) external onlyLister returns (address pair) {
        require(tokenA != tokenB, "DarwinSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "DarwinSwap: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "DarwinSwap: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(DarwinSwapPair).creationCode;
        bytes memory bytecode2 = type(LiquidityInjector).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address _liquidityInjector;
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
            _liquidityInjector := create2(0, add(bytecode2, 32), mload(bytecode2), salt)
        }
        ILiquidityInjector(_liquidityInjector).initialize(pair, token0, token1);
        IDarwinSwapPair(pair).initialize(token0, token1, _liquidityInjector);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyDev {
        feeTo = _feeTo;
    }

    function setDev(address _dev) external onlyDev {
        dev = _dev;
    }

    function setLister(address _lister) external onlyDev {
        lister = _lister;
    }

    function setRouter(address _router) external onlyDev {
        require(router == address(0), "DarwinSwapFactory: INVALID");
        router = _router;
        liquidityBundles.initialize(_router, masterChef, IDarwinSwapRouter(_router).WETH());
    }
}

pragma solidity ^0.8.14;

import "./DarwinSwapERC20.sol";

import "./interfaces/IDarwinSwapPair.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDarwinSwapFactory.sol";
import "./interfaces/IDarwinSwapCallee.sol";

import "./libraries/Math.sol";
import "./libraries/Tokenomics2Library.sol";

contract DarwinSwapPair is IDarwinSwapPair, DarwinSwapERC20 {

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public liquidityInjector;

    address public factory;
    address public router;
    address public token0;
    address public token1;

    uint256 private _reserve0;           // uses single storage slot, accessible via getReserves
    uint256 private _reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // _reserve0 * _reserve1, as of immediately after the most recent liquidity event

    uint private _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1, "DarwinSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    modifier onlyLiquidityInjector() {
        require(msg.sender == liquidityInjector, "DarwinSwapPair: CALLER_NOT_ANTIDUMP");
        _;
    }

    function getReserves() public view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast) {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value, address otherToken) private {
        // NOTE: DarwinSwap: TOKS1_BUY
        if (otherToken != address(0)) {
            value -= Tokenomics2Library.handleToks1Buy(token, value, otherToken, factory);
        }
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TRANSFER_FAILED");
    }

    constructor() {
        factory = msg.sender;
        router = IDarwinSwapFactory(factory).router();
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _liquidityInjector) external {
        require(msg.sender == factory, "DarwinSwap: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        liquidityInjector = _liquidityInjector;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint256 reserve0, uint256 reserve1) private {
        require(balance0 <= type(uint256).max && balance1 <= type(uint256).max, "DarwinSwap: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += (reserve1 / reserve0) * timeElapsed;
            price1CumulativeLast += (reserve0 / reserve1) * timeElapsed;
        }
        _reserve0 = uint256(balance0);
        _reserve1 = uint256(balance1);
        _blockTimestampLast = blockTimestamp;
        emit Sync(_reserve0, _reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/2th of the growth in sqrt(k) to feeTo
    // and mint 1/6th to liquidityBundles contract
    function _mintFee(uint256 reserve0, uint256 reserve1) private returns (bool feeOn) {
        address feeTo = IDarwinSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(reserve0 * reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    {
                        uint numerator = totalSupply() * (rootK - rootKLast);
                        uint denominator = rootK + rootKLast;
                        uint liquidity = numerator / denominator;
                        if (liquidity > 0) _mint(feeTo, liquidity);
                    }
                    {
                        uint numerator = totalSupply() * (rootK - rootKLast);
                        uint denominator = rootK + rootKLast * 5;
                        uint liquidity = numerator / denominator;
                        if (liquidity > 0) _mint(address(IDarwinSwapFactory(factory).liquidityBundles()), liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint256 reserve0, uint256 reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        bool feeOn = _mintFee(reserve0, reserve1);
        uint totSupply = totalSupply(); // gas savings, must be defined here since totalSupply() can update in _mintFee
        if (totSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min((amount0 * totSupply) / reserve0, (amount1 * totSupply) / reserve1);
        }
        require(liquidity > 0, "DarwinSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) kLast = _reserve0 * _reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint256 reserve0, uint256 reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(reserve0, reserve1);
        uint totSupply = totalSupply(); // gas savings, must be defined here since totalSupply() can update in _mintFee
        amount0 = liquidity * balance0 / totSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / totSupply; // using balances ensures pro-rata distribution
        // require(amount0 > 0 && amount1 > 0, "DarwinSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0, address(0));
        _safeTransfer(_token1, to, amount1, address(0));
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) kLast = _reserve0 * _reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address[2] memory firstAndLastInPath) external lock {
        require(msg.sender == router, "DarwinSwap::swap: FORBIDDEN");
        require(amount0Out > 0 || amount1Out > 0, "DarwinSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 reserve0, uint256 reserve1,) = getReserves(); // gas savings
        require(amount0Out < reserve0 && amount1Out < reserve1, "DarwinSwap: INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, "DarwinSwap: INVALID_TO");
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out, firstAndLastInPath[0]); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out, firstAndLastInPath[0]); // optimistically transfer tokens
        if (data.length > 0) IDarwinSwapCallee(to).darwinSwapCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "DarwinSwap: INSUFFICIENT_INPUT_AMOUNT");
        /* { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
        uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
        require(balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * (1000**2), "DarwinSwap: K");
        } */

        if (firstAndLastInPath[1] != address(0)) {
            // NOTE: TOKS2_SELL
            Tokenomics2Library.handleToks2Sell(amount0In > 0 ? token0 : token1, amount0In > amount1In ? amount0In : amount1In, firstAndLastInPath[1], factory);
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }
        if (firstAndLastInPath[0] != address(0)) {
            // NOTE: TOKS2_BUY
            Tokenomics2Library.handleToks2Buy(amount0Out > 0 ? token0 : token1, amount0Out > amount1Out ? amount0Out : amount1Out, firstAndLastInPath[0], to, factory);
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }

        _update(balance0, balance1, reserve0, reserve1);
        _emitSwap(amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // NOTE: This emits the Swap event. Separate from swap() to avoid stack too deep errors.
    function _emitSwap(uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address to) internal {
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // Allows liqInj guard to call this simpler swap function to spend less gas
    function swapWithoutToks(address tokenIn, uint amountIn) external lock onlyLiquidityInjector {
        (uint reserveIn, uint reserveOut, address tokenOut) = token0 == tokenIn ? (_reserve0, _reserve1, token1) : (_reserve1, _reserve0, token0);
        uint amountOut = DarwinSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - _reserve0, address(0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - _reserve1, address(0));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
    }

    // Overrides totalSupply to include also the liquidityInjector liquidity
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
        /* uint _baseSupply = _totalSupply;
        if (_reserve0 == 0 || _reserve1 == 0) {
            return _baseSupply;
        }
        uint liqInjReserve0 = IERC20(token0).balanceOf(liquidityInjector);
        uint liqInjReserve1 = IERC20(token1).balanceOf(liquidityInjector);
        uint _liqInjLiq = Math.min((liqInjReserve0 * _totalSupply) / _reserve0, (liqInjReserve1 * _totalSupply) / _reserve1);
        return _baseSupply + _liqInjLiq; */
    }
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

interface IDarwinSwapCallee {
    function darwinSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity ^0.8.14;

interface IDarwinSwapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
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

// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

interface IDarwinSwapLister {
    struct TokenInfo {
        OwnTokenomicsInfo ownToks; //? The original token's tokenomics
        TokenomicsInfo addedToks; //? Tokenomics "added" by DarwinSwap
        TokenStatus status; //? Token status
        address validator; //? If a Darwin team validator has verified this token (with whatever outcome), this is their address. Otherwise it equals the address(0)
        address owner; //? The owner of the token contract
        address feeReceiver; //? Where will the fees go
        bool valid; //? Only true if the token has been POSITIVELY validated by a Darwin team validator
        bool official; //? Only true if the token is either Darwin, WBNB, or a selected list of tokens like USDT, USDC, etc. If "official" is true, other tokens paired with this token will be able to execute tokenomics, if any
        string purpose; //? Why are you sending the fees to the feeReceiver address? Is it a treasury? Will it be used for buybacks? Marketing?
        uint unlockTime; //? Time when the tax lock will end (and taxes will be modifiable again). 0 if no lock.
    }

    struct OwnTokenomicsInfo {
        uint tokenTaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenTaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
    }

    struct TokenomicsInfo {
        uint tokenA1TaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB1TaxOnSell; //? The Toks 1.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenB on buys (100%: 10000)
        uint tokenA2TaxOnSell; //? The Toks 2.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB2TaxOnSell; //? The Toks 2.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenB on buys (100%: 10000)
        uint refundOnSell; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on sells
        uint refundOnBuy; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on buys
        uint tokenB1SellToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnSell) of Tokenomics 1.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB1BuyToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnBuy) of Tokenomics 1.0 applied to the other token that will be used, on buys, to refill the LI
        uint tokenB2SellToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnSell) of Tokenomics 2.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB2BuyToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnBuy) of Tokenomics 2.0 applied to the other token that will be used, on buys, to refill the LI
    }

    enum TokenStatus {
        UNLISTED, //? This token is not listed on DarwinSwap
        LISTED, //? This token has been listed on DarwinSwap
        BANNED //? This token and its owner are banned from listing on DarwinSwap (because it has been recognized as harmful during a verification)
    }

    struct Token {
        string name;
        string symbol;
        address addr;
        uint decimals;
    }

    event TokenListed(address indexed tokenAddress, TokenInfo indexed listingInfo);
    event TaxLockPeriodUpdated(address indexed tokenAddress, uint indexed newUnlockDate);
    event TokenBanned(address indexed tokenAddress, address indexed ownerAddress);

    function maxTok1Tax() external view returns (uint);
    function maxTok2Tax() external view returns (uint);

    function isValidator(address user) external view returns (bool);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function tokenInfo(address _token) external view returns(TokenInfo memory);
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

// SPDX-License-Identifier: BSL-1.1

import {IERC20} from "./IERC20.sol";

pragma solidity ^0.8.14;

interface ILiquidityInjector {
    event BuyBackAndPair(IERC20 tokenSold, IERC20 tokenBought, uint amountSold, uint amountBought);

    function initialize(address _pair, address token0, address token1) external;
    function buyBackAndPair(IERC20 _buyToken) external;
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

import "../interfaces/IDarwinSwapPair.sol";
import "../interfaces/IDarwinSwapFactory.sol";

library DarwinSwapLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "DarwinSwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "DarwinSwapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                IDarwinSwapFactory(factory).INIT_CODE_HASH()
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDarwinSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "DarwinSwapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "DarwinSwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, "DarwinSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "DarwinSwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "DarwinSwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "DarwinSwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity ^0.8.14;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import "../interfaces/IDarwinSwapLister.sol";
import "../interfaces/IDarwinSwapPair.sol";
import "../libraries/DarwinSwapLibrary.sol";

library Tokenomics2Library {

    bytes4 private constant _TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant _TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the sender with Tokenomics 1.0 on the sold token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Sell(
        address sellToken,
        address from,
        uint256 value,
        address buyToken,
        address factory
    ) public returns(uint sellTaxAmount) {
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics1.0 sell tax value applied to itself
            uint sellTokenA1 = (value * sellTokenInfo.addedToks.tokenA1TaxOnSell) / 10000;

            if (sellTokenA1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, sellTokenInfo.feeReceiver, sellTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A1");
            }

            sellTaxAmount += sellTokenA1;
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // If BUYTOKEN's liqInj is active, send the tokenomics1.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB1BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB1BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B1");
            }

            // BUYTOKEN tokenomics1.0 buy tax value applied to SELLTOKEN
            uint buyTokenB1 = (value * buyTokenInfo.addedToks.tokenB1TaxOnBuy) / 10000;

            if (buyTokenB1 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFERFROM, from, buyTokenInfo.feeReceiver, buyTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B1");
            }

            sellTaxAmount += buyTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the receiver (well, actually sends LESS tokens to the receiver) with Tokenomics 1.0 on the bought token, both from the sold token and the bought token. Returns the taxed amount.
    function handleToks1Buy(
        address buyToken,
        uint value,
        address sellToken,
        address factory
    ) public returns(uint buyTaxAmount) {
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = IDarwinSwapLister(IDarwinSwapFactory(factory).lister()).tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics1.0 buy tax value applied to itself
            uint buyTokenA1 = (value * buyTokenInfo.addedToks.tokenA1TaxOnBuy) / 10000;

            if (buyTokenA1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A1");
            }

            buyTaxAmount += buyTokenA1;
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // If SELLTOKEN's liqInj is active, send the tokenomics1.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB1SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB1SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B1");
            }

            // SELLTOKEN tokenomics1.0 sell tax value applied to BUYTOKEN
            uint sellTokenB1 = (value * sellTokenInfo.addedToks.tokenB1TaxOnSell) / 10000;

            if (sellTokenB1 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB1));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B1");
            }

            buyTaxAmount += sellTokenB1;
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the sold token, both from the sold token and the bought token.
    function handleToks2Sell(
        address sellToken,
        uint value,
        address buyToken,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund and makes it
            if (sellTokenInfo.addedToks.refundOnSell > 0) {
                uint refundA1WithA2 = (value * sellTokenInfo.addedToks.refundOnSell) / 10000;

                // TODO: SHOULD AVOID USING TX.ORIGIN
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, tx.origin, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_SELL_A2");
            }

            // If SELLTOKEN's liqInj is active, send the tokenomics2.0 sell tax value applied to BUYTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (sellTokenInfo.addedToks.tokenB2SellToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(buyToken, sellToken, factory, value, sellTokenInfo.addedToks.tokenB2SellToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_SELL_B2");
            }

            // SELLTOKEN tokenomics2.0 sell tax value applied to itself
            uint sellTokenA2 = (value * sellTokenInfo.addedToks.tokenA2TaxOnSell) / 10000;

            if (sellTokenA2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_A2");
            }
        }

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // BUYTOKEN tokenomics2.0 buy tax value applied to SELLTOKEN
            uint buyTokenB2 = (value * buyTokenInfo.addedToks.tokenB2TaxOnBuy) / 10000;

            if (buyTokenB2 > 0) {
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_B2");
            }
        }
    }

    // TODO: Make sure this actually does correct and enough calculations
    // Taxes the LP with Tokenomics 2.0 on the bought token, both from the bought token and the sold token.
    function handleToks2Buy(
        address buyToken,
        uint value,
        address sellToken,
        address to,
        address factory
    ) public {
        IDarwinSwapLister lister = IDarwinSwapLister(IDarwinSwapFactory(factory).lister());
        IDarwinSwapLister.TokenInfo memory buyTokenInfo = lister.tokenInfo(buyToken);
        IDarwinSwapLister.TokenInfo memory sellTokenInfo = lister.tokenInfo(sellToken);

        if (buyTokenInfo.valid && sellTokenInfo.official) {
            // Calculates eventual tokenomics1.0 refund
            if (buyTokenInfo.addedToks.refundOnBuy > 0) {
                uint refundA1WithA2 = (value * buyTokenInfo.addedToks.refundOnBuy) / 10000;

                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, to, refundA1WithA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: REFUND_FAILED_BUY_A2");
            }

            // If BUYTOKEN's liqInj is active, send the tokenomics2.0 buy tax value applied to SELLTOKEN to the pair's liqInj guard
            //? liqInj ONLY WORKS ON [2]PATH SWAPS
            address pair = IDarwinSwapFactory(factory).getPair(sellToken, buyToken);
            if (buyTokenInfo.addedToks.tokenB2BuyToLI > 0 && pair != address(0)) {
                uint refill = handleLIRefill(sellToken, buyToken, factory, value, buyTokenInfo.addedToks.tokenB2BuyToLI);
                address liqInj = IDarwinSwapPair(pair).liquidityInjector();
                (bool success, bytes memory data) = sellToken.call(abi.encodeWithSelector(_TRANSFER, liqInj, refill));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: ANTIDUMP_FAILED_BUY_B2");
            }

            // BUYTOKEN tokenomics2.0 buy tax value applied to itself
            uint buyTokenA2 = (value * buyTokenInfo.addedToks.tokenA2TaxOnBuy) / 10000;

            if (buyTokenA2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, buyTokenInfo.feeReceiver, buyTokenA2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_BUY_A2");
            }
        }

        if (sellTokenInfo.valid && buyTokenInfo.official) {
            // SELLTOKEN tokenomics2.0 sell tax value applied to BUYTOKEN
            uint sellTokenB2 = (value * sellTokenInfo.addedToks.tokenB2TaxOnSell) / 10000;

            if (sellTokenB2 > 0) {
                (bool success, bytes memory data) = buyToken.call(abi.encodeWithSelector(_TRANSFER, sellTokenInfo.feeReceiver, sellTokenB2));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "DarwinSwap: TAX_FAILED_SELL_B2");
            }
        }
    }

    function handleLIRefill(address antiDumpToken, address otherToken, address factory, uint value, uint otherTokenB2OtherToLI) public view returns(uint refill) {
        (uint antiDumpReserve, uint otherReserve) = DarwinSwapLibrary.getReserves(factory, antiDumpToken, otherToken);
        refill = (DarwinSwapLibrary.getAmountOut(value, otherReserve, antiDumpReserve) * otherTokenB2OtherToLI) / 10000;
    }

    // Ensures that the limitations we've set for taxes are respected
    function ensureTokenomics(IDarwinSwapLister.TokenInfo memory tokInfo, uint maxTok1Tax, uint maxTok2Tax, uint maxTotalTax) public pure returns(bool valid) {
        IDarwinSwapLister.TokenomicsInfo memory toks = tokInfo.addedToks;
        IDarwinSwapLister.OwnTokenomicsInfo memory ownToks = tokInfo.ownToks;

        uint tax1OnSell =   toks.tokenA1TaxOnSell + toks.tokenB1TaxOnSell + toks.tokenB1SellToLI;
        uint tax1OnBuy =    toks.tokenA1TaxOnBuy +  toks.tokenB1TaxOnBuy +  toks.tokenB1BuyToLI;
        uint tax2OnSell =   toks.tokenA2TaxOnSell + toks.tokenB2TaxOnSell + toks.refundOnSell +     toks.tokenB2SellToLI;
        uint tax2OnBuy =    toks.tokenA2TaxOnBuy +  toks.tokenB2TaxOnBuy +  toks.refundOnBuy +      toks.tokenB2BuyToLI;

        valid = tax1OnSell <= maxTok1Tax && tax1OnBuy <= maxTok1Tax && tax2OnSell <= maxTok2Tax && tax2OnBuy <= maxTok2Tax &&
                (toks.refundOnSell <= (ownToks.tokenTaxOnSell / 2)) && (toks.refundOnBuy <= (ownToks.tokenTaxOnBuy / 2)) &&
                (tax1OnBuy + tax1OnSell + tax2OnBuy + tax2OnSell <= maxTotalTax);
    }

    // Removes 5% from added tokenomics, to leave it for LP providers.
    function adjustTokenomics(IDarwinSwapLister.TokenomicsInfo calldata addedToks) public pure returns(IDarwinSwapLister.TokenomicsInfo memory returnToks) {
        returnToks.tokenA1TaxOnBuy = addedToks.tokenA1TaxOnBuy - (addedToks.tokenA1TaxOnBuy * 5) / 100;
        returnToks.tokenA1TaxOnSell = addedToks.tokenA1TaxOnSell - (addedToks.tokenA1TaxOnSell * 5) / 100;
        returnToks.tokenA2TaxOnBuy = addedToks.tokenA2TaxOnBuy - (addedToks.tokenA2TaxOnBuy * 5) / 100;
        returnToks.tokenA2TaxOnSell = addedToks.tokenA2TaxOnSell - (addedToks.tokenA2TaxOnSell * 5) / 100;
        returnToks.tokenB1TaxOnBuy = addedToks.tokenB1TaxOnBuy - (addedToks.tokenB1TaxOnBuy * 5) / 100;
        returnToks.tokenB1TaxOnSell = addedToks.tokenB1TaxOnSell - (addedToks.tokenB1TaxOnSell * 5) / 100;
        returnToks.tokenB2TaxOnBuy = addedToks.tokenB2TaxOnBuy - (addedToks.tokenB2TaxOnBuy * 5) / 100;
        returnToks.tokenB2TaxOnSell = addedToks.tokenB2TaxOnSell - (addedToks.tokenB2TaxOnSell * 5) / 100;
        returnToks.refundOnBuy = addedToks.refundOnBuy - (addedToks.refundOnBuy * 5) / 100;
        returnToks.refundOnSell = addedToks.refundOnSell - (addedToks.refundOnSell * 5) / 100;
        returnToks.tokenB1SellToLI = addedToks.tokenB1SellToLI - (addedToks.tokenB1SellToLI * 5) / 100;
        returnToks.tokenB1BuyToLI = addedToks.tokenB1BuyToLI - (addedToks.tokenB1BuyToLI * 5) / 100;
        returnToks.tokenB2SellToLI = addedToks.tokenB2SellToLI - (addedToks.tokenB2SellToLI * 5) / 100;
        returnToks.tokenB2BuyToLI = addedToks.tokenB2BuyToLI - (addedToks.tokenB2BuyToLI * 5) / 100;
    }
}

// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import {IDarwinSwapPair} from "./interfaces/IDarwinSwapPair.sol";
import {IDarwinSwapFactory} from "./interfaces/IDarwinSwapFactory.sol";
import {IDarwinSwapLister} from "./interfaces/IDarwinSwapLister.sol";
import {IDarwinSwapRouter} from "./interfaces/IDarwinSwapRouter.sol";
import {ILiquidityInjector} from "./interfaces/ILiquidityInjector.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract LiquidityInjector is ILiquidityInjector {
    IDarwinSwapFactory public immutable factory;
    IDarwinSwapPair public pair;
    IDarwinSwapRouter public router;
    IDarwinSwapLister public lister;
    address public dev;
    IERC20 public token0;
    IERC20 public token1;

    modifier onlyTeamOrDev() {
        require(msg.sender == dev || msg.sender == lister.tokenInfo(address(token0)).owner || msg.sender == lister.tokenInfo(address(token1)).owner, "LiquidityInjector: CALLER_NOT_TOKEN_TEAM_OR_DEV");
        _;
    }

    constructor() {
        factory = IDarwinSwapFactory(msg.sender);
    }

    function initialize(address _pair, address _token0, address _token1) external {
        require(msg.sender == address(factory), "LiquidityInjector: CALLER_NOT_FACTORY");
        pair = IDarwinSwapPair(_pair);
        router = IDarwinSwapRouter(factory.router());
        lister = IDarwinSwapLister(factory.lister());
        dev = factory.dev();
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        token0.approve(address(router), type(uint).max);
        token1.approve(address(router), type(uint).max);
        token0.approve(address(pair), type(uint).max);
        token1.approve(address(pair), type(uint).max);
    }

    function buyBackAndPair(IERC20 _sellToken) public onlyTeamOrDev {
        IERC20 _buyToken = address(_sellToken) == address(token1) ? token0 : token1;

        // Return if there is no buyToken balance in the liqInj
        if (_buyToken.balanceOf(address(this)) == 0) {
            if (_sellToken.balanceOf(address(this)) > 0) {
                buyBackAndPair(_buyToken);
            }
            return;
        }
        
        IDarwinSwapLister.TokenInfo memory tokenInfo = lister.tokenInfo(address(_sellToken));

        // Return if liqInj is not a thing for this token
        if (tokenInfo.addedToks.tokenB1SellToLI + tokenInfo.addedToks.tokenB1BuyToLI + tokenInfo.addedToks.tokenB2SellToLI + tokenInfo.addedToks.tokenB2BuyToLI == 0) {
            return;
        }

        // SWAP
        pair.swapWithoutToks(address(_buyToken), _buyToken.balanceOf(address(this)) / 2);
        uint balanceSellToken = _sellToken.balanceOf(address(this));
        uint balanceBuyToken = _buyToken.balanceOf(address(this));

        // PAIR
        router.addLiquidityWithoutReceipt(address(_sellToken), address(_buyToken), balanceSellToken, balanceBuyToken, block.timestamp + 600);

        emit BuyBackAndPair(_buyToken, _sellToken, balanceBuyToken, balanceSellToken);
    }

    receive() external payable {}
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