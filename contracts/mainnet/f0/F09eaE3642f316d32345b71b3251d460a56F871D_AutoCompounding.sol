// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// GLP RewardRouterV2 interface
interface IRewardRouterV2 {
  function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
  function handleRewards(
    bool _shouldClaimGmx,
    bool _shouldStakeGmx,
    bool _shouldClaimEsGmx,
    bool _shouldStakeEsGmx,
    bool _shouldStakeMultiplierPoints,
    bool _shouldClaimWeth,
    bool _shouldConvertWethToEth
  ) external;
}

interface IGlpManager {
  function getAum(bool maximise) external view returns (uint256);
}

interface IExchangeRateOracle { // Chainlink compatible
  function latestRoundData()
    external
    view
    returns (
      uint80, // roundId,
      int256, // answer,
      uint256, // startedAt,
      uint256, // updatedAt,
      uint80 // answeredInRound
    );
}

 // Receives WETH from the GLP vault and compounds it into more GLP before sending it back to the vault.

contract AutoCompounding is Ownable { 
  uint256 public constant PRICE_FEED_FRESHNESS = 24*60*60; // 24h after which price feed is considered stale

  IERC20 public constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IERC20 public constant GLP = IERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903); // Fee + Staked GLP (fsGLP)
  IERC20 public constant SGLP = IERC20(0x2F546AD4eDD93B956C8999Be404cdCAFde3E89AE); 
  IERC20 public constant rawGLP = IERC20(0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258);

  IRewardRouterV2 public constant GlpRewardRouterV2 = IRewardRouterV2(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
  IGlpManager public constant GLPManager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);

  IExchangeRateOracle public constant ethUsdOracle = IExchangeRateOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

  address public vault;
  uint256 public acceptableSlippage = 1; // in %

  uint256 public totalPurchased;

  uint256 public sensibleMinimumWethToCompound = 1_000_000_000_000_000; // 0.001 WETH 

  event AcceptableSlippageUpdated(address updater, uint256 newAcceptableSlippage);
  event GlpPurchased(uint256 amountWethSpent, uint256 amountGlpPurchased);
  event Harvest(uint256 amount);
  event MintLockTimeUpdated(address updater, uint256 newMintLockTime);
  event SensibleMinimumWethToCompoundUpdated(address updater, uint256 newSensibleMinimum);
  event VaultUpdated(address updater, address newVault);

  constructor() {}

  // @dev sends any GLP balanceOf(address(this)) back to vault if possible
  // and purchases new GLP with all available WETH balance
  function compound() public {
    require(msg.sender == vault, "Unauthorized");
    purchaseGlp();
    sendGlpToVault();
  }

  function purchaseGlp() internal {
    uint256 wethBalance = WETH.balanceOf(address(this));
    if(wethBalance < sensibleMinimumWethToCompound) {
      return; // nothing to do
    }

    // approve WETH balance
    WETH.approve(address(GLPManager), wethBalance);

    // calculate acceptable minAmounts and slippage
    uint256 currentEthUsdPrice = getEthUsdExchangeRate();
    uint256 purchaseValue = wethBalance * currentEthUsdPrice / 1e8;  // exchange rate 8 decimals, weth 18, required 18, remove 8
    uint256 minAcceptableUsdValue = purchaseValue * (100-acceptableSlippage) / 100; // 18 decimals

    uint256 currentGlpPrice = GLPManager.getAum(true) / rawGLP.totalSupply() * 1e6; // 30 decimals - 18 = 12, + 6 = 18 decimals
    uint256 minAcceptableGlpAmount = minAcceptableUsdValue / currentGlpPrice * 1e18; // 18 decimals

    // buy GLP
    uint256 amountPurchased = GlpRewardRouterV2.mintAndStakeGlp(
      address(WETH),           // token to buy GLP with
      wethBalance,             // amount of token to use for the purchase
      minAcceptableUsdValue,   // the minimum acceptable USD value of the GLP purchased
      minAcceptableGlpAmount   // the minimum acceptable GLP amount
    );

    totalPurchased += amountPurchased;
    uint256 wethBalanceAfter = WETH.balanceOf(address(this));

    emit GlpPurchased(wethBalance-wethBalanceAfter, amountPurchased);
  }

  // @dev GLP is only transferable 15min+ after last mint
  // since this can be called as part of regular deposit/withdraw txs
  // we don't require/revert but simply return if the 15min haven't passed
  function sendGlpToVault() internal {
    uint256 balance = GLP.balanceOf(address(this));
    if(balance == 0) {
      return; // nothing to do
    }
    SGLP.transfer(vault, balance);
  }

  function getEthUsdExchangeRate() public view returns (uint256) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint256 startedAt*/,
      uint256 timestamp,
      /*uint80 answeredInRound*/
    ) = ethUsdOracle.latestRoundData();
    require(price > 0, "invalid price");
    require(timestamp > block.timestamp-PRICE_FEED_FRESHNESS, "price feed stale"); 
    return uint256(price);
  }

  // @dev compounds esGMX & multiplier points and 
  // sends weth to address(this).
  // We need it here since rewards accrue in the time between 
  // purchaseGlp() and sendGlpToVault() 15+ min later
  function harvest() external onlyOwner {
    uint256 balanceBefore = WETH.balanceOf(address(this));

    GlpRewardRouterV2.handleRewards(
      false, // _shouldClaimGmx
      false, // _shoudlStakeGmx
      true, // _shouldClaimEsGmx
      true, // _shouldStakeEsGmx
      true, // _shouldStakeMultiplierPoints
      true, // _shouldClaimWeth
      false // _shouldConvertWethToEth
    );

    uint256 balanceAfter = WETH.balanceOf(address(this));
    uint256 harvestedEthAmount = balanceAfter-balanceBefore;

    emit Harvest(harvestedEthAmount);
  }

  /*****************************
   * 
   *      ADMIN functions
   * 
   *****************************/
  function setVault(address _newVault) public onlyOwner {
    vault = _newVault;
    emit VaultUpdated(msg.sender, vault);
  }

  function setAcceptableSlippage(uint256 _newAcceptableSlippage) public onlyOwner {
    acceptableSlippage = _newAcceptableSlippage;
    emit AcceptableSlippageUpdated(msg.sender, acceptableSlippage);
  }

  function setSensibleMinimumWethToCompound(uint _newValue) public onlyOwner {
    sensibleMinimumWethToCompound = _newValue;
    emit SensibleMinimumWethToCompoundUpdated(msg.sender, sensibleMinimumWethToCompound);
  }


  // emergency recover
  function recover(address _tokenAddress) public onlyOwner {
    IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this)));
  }

  function recoverETH(address payable _to) public onlyOwner payable {
    (bool sent,) = _to.call{ value: address(this).balance }("");
    require(sent, "failed to send ETH");
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