// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./WETHelper.sol";
import "../../lib0.8/upgrable/Ownable.sol";
import "./interfaces/IPermit.sol";


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPool {
  function assetOf (address token) external view returns (address);

  function deposit(
    address token,
    uint256 amount,
    address to,
    uint256 deadline
  ) external returns (uint256 liquidity);

  function swap(
    address fromToken,
    address toToken,
    uint256 fromAmount,
    uint256 minimumToAmount,
    address to, 
    uint256 deadline
  ) external returns (uint256);

  function withdraw(
    address token,
    uint256 liquidity,
    uint256 minimumAmount,
    address to,
    uint256 deadline
  ) external returns (uint256 amount);
}

interface IFarm {
  function depositFor(uint256, uint256, address) external;
}

interface IERC20 {
  function approve(address, uint256) external;
  function transfer(address, uint256) external;
  function transferFrom(address, address, uint256) external;
}

contract PoolProxyV2 is Ownable {


  IFarm public farm;
  address public WETH;
  WETHelper public wethelper;

  function initialize(IFarm farm_, address weth_) public initializer {
      Ownable.__Ownable_init();
      farm = farm_;
      WETH = weth_;
      wethelper = new WETHelper();
  }

  receive() external payable {
    assert(msg.sender == WETH);
  }

  function deposit(address token, uint256 amount, uint256 pid, IPool pool_, bool isStake) 
    public payable returns (uint256 liquidity) {
      if(amount > 0) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
      }
      if(token == WETH) {
        IWETH(WETH).deposit{value: msg.value}();
        amount += msg.value;
      }
      IERC20(token).approve(address(pool_), amount);
      if(isStake){
        liquidity = pool_.deposit(token, amount, address(this), block.timestamp + 1800);
        address asset = pool_.assetOf(token);
        IERC20(asset).approve(address(farm), liquidity);
        farm.depositFor(pid, liquidity, msg.sender); 
      }else{
        liquidity = pool_.deposit(token, amount, msg.sender, block.timestamp + 1800);
      }
  }

  function depositWithPermit(address token, uint256 amount, uint256 pid, IPool pool_, bool isStake, bytes memory signature)
     external payable
    {
        _permit(token, msg.sender, signature);
        deposit(token, amount, pid, pool_, isStake);
  }

  function stake (
    address lpToken,
    uint256 pid,
    uint256 amount
  ) public {
    IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
    IERC20(lpToken).approve(address(farm), amount);
    farm.depositFor(pid, amount, msg.sender);
  }

  function stakeWithPermit(
    address lpToken,
    uint256 pid,
    uint256 amount,
    bytes memory signature
  ) external {
    _permit(lpToken, msg.sender, signature);
    stake(lpToken, pid, amount);
  }

  function swap(
      address fromToken,
      address toToken,
      uint256 fromAmount,
      uint256 minimumToAmount,
      IPool pool_
  ) public payable{
    if(fromAmount > 0) {
      IERC20(fromToken).transferFrom(msg.sender, address(this), fromAmount);
    }
    if(fromToken == WETH){
      IWETH(WETH).deposit{value: msg.value}();
      fromAmount += msg.value;
    }      
    IERC20(fromToken).approve(address(pool_), fromAmount);
    if(toToken == WETH){
      uint256 liquidity = pool_.swap(fromToken, WETH, fromAmount, minimumToAmount, address(this), block.timestamp + 1800);
      IERC20(WETH).transfer(address(wethelper), liquidity);
      wethelper.withdraw(WETH, msg.sender, liquidity);
    }else{
      pool_.swap(fromToken, toToken, fromAmount, minimumToAmount, msg.sender, block.timestamp + 1800); 
    }

  }


  function swapWithPermit(
      address fromToken,
      address toToken,
      uint256 fromAmount,
      uint256 minimumToAmount,
      IPool pool_,
      bytes memory signature  
  ) external payable{
      _permit(fromToken, msg.sender, signature);
      swap(fromToken,toToken,fromAmount,minimumToAmount,pool_);
  }


  function withdraw(
      address token,
      uint256 liquidity,
      uint256 minimumAmount,
      IPool pool_
  ) public {
      address asset = pool_.assetOf(token);
      IERC20(asset).transferFrom(msg.sender, address(this), liquidity);
      IERC20(asset).approve(address(pool_), liquidity);
      if(token == WETH){
        uint256 actualToAmount = pool_.withdraw(token, liquidity, minimumAmount, address(this), block.timestamp + 1800);
        IERC20(WETH).transfer(address(wethelper), actualToAmount);
        wethelper.withdraw(WETH, msg.sender, actualToAmount);
      }else{
        pool_.withdraw(token, liquidity, minimumAmount, msg.sender, block.timestamp + 1800);
      }
      
  }


  function withdrawWithPermit(
      address token,
      uint256 liquidity,
      uint256 minimumAmount,
      IPool pool_,
      bytes memory signature  
  ) external {
      address asset = pool_.assetOf(token);
      _permit(asset, msg.sender, signature);
      withdraw(token,liquidity,minimumAmount,pool_);

  }

  function _permit(address token, address owner, bytes memory signature) internal {
      (uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(signature,(uint256,uint256,uint8,bytes32,bytes32));
      IPermit(token).permit(owner, address(this), value, deadline, v, r, s);
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
pragma solidity >= 0.8.0;

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETHelper {
    function withdraw(uint) external;
}
//weth  transfer
contract WETHelper {
    receive() external payable {
    }
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, '!WETHelper: ETH_TRANSFER_FAILED');
    }
    function withdraw(address _eth, address _to, uint256 _amount) public {
        IWETHelper(_eth).withdraw(_amount);
        safeTransferETH(_to, _amount);
    }
}