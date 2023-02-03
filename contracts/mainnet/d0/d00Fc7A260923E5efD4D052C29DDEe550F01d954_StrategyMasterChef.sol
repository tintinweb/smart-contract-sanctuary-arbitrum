// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib0.8/upgrable/Ownable.sol";
import "../../lib0.8/erc20/SafeERC20.sol";

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

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint256);
    function kLast() external view returns (uint256);
}

interface IUniswapRouterETH {
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

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IChef {
    function deposit(uint256 _pid, uint256 _amount, address _to) external;

    function withdraw(uint256 _pid, uint256 _amount, address _to) external;

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function userInfo(
        uint256,
        address
    ) external view returns(
        uint256 amount,
        uint256 boostAmount
    );
}

contract FeeManager is Ownable, Pausable {

    struct CommonAddresses {
        address vault;
        address unirouter;
        address keeper;
        address strategist;
        address dinoFeeRecipient;
        address dinoFeeConfig;
    }

    IUniswapRouterETH public unirouter;

    uint256 constant public WITHDRAWAL_FEE_CAP = 50;
    uint256 constant public DINO_FEE_CAP = 1000;
    uint256 constant public WITHDRAWAL_MAX = 10000;
    uint256 internal withdrawalFee = 10;

   // performance fees: 1 -> 1 / 1000
    uint256 public dinoFee = 10;
    
    bool public harvestOnDeposit;

    address public vault;  


    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;
    uint256 public autoMinSwap;

    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetDinoFee(uint256 dinoFee);
    event SetVault(address vault);

    constructor(
        CommonAddresses memory _commonAddresses
    ) {
        vault = _commonAddresses.vault;
        unirouter = IUniswapRouterETH(_commonAddresses.unirouter);
        // keeper = _commonAddresses.keeper;
        // strategist = _commonAddresses.strategist;
    }

    modifier onlyManager() {
        require(msg.sender == owner(), "!manager");
        _;
    }

    function setUnirouter(IUniswapRouterETH _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

     function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit SetVault(_vault);
    }

    // adjust withdrawal fee
    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    function setDinoFee(uint256 _fee) public onlyManager {
        require(_fee <= DINO_FEE_CAP, "!cap");
        withdrawalFee = _fee;
        emit SetDinoFee(dinoFee);
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit, uint256 _autoMinSwap) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
        autoMinSwap = _autoMinSwap;
        if (harvestOnDeposit) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(10);
        }
    }
}

contract StrategyMasterChef is Ownable, FeeManager {
    using SafeERC20 for IERC20;

    // Tokens used
    IERC20 public want;
    address public native;
    address public output;
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    IChef public chef;
    uint256 public poolId;

    uint256 shareTotal;
    uint256 public lastHarvest;

    constructor(
        IChef chef_,
        IERC20 want_,
        uint256 poolId_,
        CommonAddresses memory _commonAddresses,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route
        ) FeeManager(_commonAddresses) {
        Ownable.__Ownable_init();
        chef = chef_;
        want = want_;
        poolId = poolId_;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2Pair(address(want)).token0();
        require(_outputToLp0Route[0] == output, "outputToLp0Route[0] != output");
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0, "outputToLp0Route[last] != lpToken0");
        outputToLp0Route = _outputToLp0Route;

        lpToken1 = IUniswapV2Pair(address(want)).token1();
        require(_outputToLp1Route[0] == output, "outputToLp1Route[0] != output");
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1, "outputToLp1Route[last] != lpToken1");
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(address(chef), type(uint).max);
        IERC20(output).safeApprove(address(unirouter), type(uint).max);

        IERC20(lpToken0).safeApprove(address(unirouter), 0);
        IERC20(lpToken0).safeApprove(address(unirouter), type(uint).max);

        IERC20(lpToken1).safeApprove(address(unirouter), 0);
        IERC20(lpToken1).safeApprove(address(unirouter), type(uint).max);
    }

    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            chef.deposit(poolId, wantBal, address(this));
        }
        
    }

    function beforeDeposit() external virtual {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest();
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");
        _harvest();

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            chef.withdraw(poolId, _amount - wantBal, address(this));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = wantBal * withdrawalFee / WITHDRAWAL_MAX;
            wantBal = wantBal - withdrawalFeeAmount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
    }

    function _harvest() internal whenNotPaused {
        chef.harvest(poolId, address(this));
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees();
            addLiquidity();
            deposit();
            lastHarvest = block.timestamp;
        }
    }

    function chargeFees() internal {
        want.safeTransfer(owner(), want.balanceOf(address(this)) * dinoFee / DINO_FEE_CAP);
    }

    function addLiquidity() internal {
      uint256 outputHalf = IERC20(output).balanceOf(address(this)) / 2;
      if(outputHalf < autoMinSwap || harvestOnDeposit == false) return;
      if (lpToken0 != output) {
          IUniswapRouterETH(unirouter).swapExactTokensForTokens(
              outputHalf, 0, outputToLp0Route, address(this), block.timestamp
          );
      }

      if (lpToken1 != output) {
          IUniswapRouterETH(unirouter).swapExactTokensForTokens(
              outputHalf, 0, outputToLp1Route, address(this), block.timestamp
          );
      }

      uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
      uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
      IUniswapRouterETH(unirouter).addLiquidity(
        lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp
     );
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }
 
    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount,) = chef.userInfo(poolId, address(this));
        return _amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "../erc20/Initializable.sol";
import "./Context.sol";

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
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "../erc20/Initializable.sol";

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

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function _safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!APPROVE_FAILED');
    }
    function safeApprove(IERC20 token, address to, uint value) internal {
        if (value > 0 && token.allowance(msg.sender, to) > 0) _safeApprove(token, to, 0);
        return _safeApprove(token, to, value);
    }

    function safeTransfer(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!TRANSFER_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, '!ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


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

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(initializing, "Initializable: contract is not initializing");
    _;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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