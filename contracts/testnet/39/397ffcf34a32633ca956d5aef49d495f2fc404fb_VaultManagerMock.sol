// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollector {

    /*==================== Public Functions *====================*/
    
    function calculateDistribution(uint256 _amountToDistribute, uint64 _ratio) external pure returns(uint256 amount_);
    function distributeFeesAllGovernance() external;
    function distributeFeesAll() external;
    function syncLastDistribution() external;
    function syncWhitelistedTokens() external;

    /*==================== Events *====================*/

    event CollectedWagerFees(
        address tokenAddress,
        uint256 amountCollected
    );

    event CollectedSwapFees(
        address tokenAddress,
        uint256 amountCollected
    );

    event NothingToDistribute(
        address token
    );

    event DistributionComplete(
        address token,
        uint256 toWLP,
        uint256 toStakers,
        uint256 toBuyBack,
        uint256 toCore
    );

    event DistributionSet(
        uint64 ratioWLP,
        uint64 ratioStaking,
        uint64 buybackRatio,
        uint64 ratioCore
    );

    event SyncTokens();
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================================================== EVENTS GMX ===========================================================*/
    event BuyUSDW(
        address account, 
        address token, 
        uint256 tokenAmount, 
        uint256 usdwAmount, 
        uint256 feeBasisPoints
    );
    event SellUSDW(
        address account, 
        address token, 
        uint256 usdwAmount, 
        uint256 tokenAmount, 
        uint256 feeBasisPoints
    );
    event Swap(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 indexed amountOut, 
        uint256 indexed amountOutAfterFees, 
        uint256 indexed feeBasisPoints
    );
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdwAmount(address token, uint256 amount);
    event DecreaseUsdwAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    /*================================================== Operational Functions GMX =================================================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function whitelistedTokenCount() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawSwapFees(address _token) external returns (uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceFeed() external view returns (address);
    function getFeeBasisPoints(
        address _token, 
        uint256 _usdwDelta, 
        uint256 _feeBasisPoints, 
        uint256 _taxBasisPoints, 
        bool _increment
    ) external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    /*==================== Events WINR  *====================*/

    event PlayerPayout(
        address recipient,
        uint256 amountPayoutTotal
    );

    event WagerFeesCollected(
        address tokenAddress,
        uint256 usdValueFee,
        uint256 feeInTokenCharged
    );

    event PayinWLP(
        address tokenInAddress,
        uint256 amountPayin,
        uint256 usdValueProfit
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    /*==================== Operational Functions WINR *====================*/
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFee() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function withdrawWagerFees(address _token) external returns (uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);

    function payout(
        address[2] memory _tokens,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount
    ) external;

    function rebalanceWithdraw(
        address _tokenToRebalanceWith,
        uint256 _amountToRebalanceWith
    ) external;

    function rebalanceDeposit(
        address _tokenInDeposited,
        uint256 _amountDeposited
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
    function getBuyUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSellUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdwAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VaultManagerSettingsMock.sol";

import "../../interfaces/core/IVault.sol";


/// @dev This contract designed to easing token transfers broadcasting information between contracts
contract VaultManagerMock is VaultManagerSettingsMock {
  /*==================================================== Events ===========================================================*/

  event Escrow(address sender, address token, uint256 amount);
  event Payback(address recipient, address token, uint256 amount);
  event Withdraw(address token, uint256 amount);

  /*==================================================== State ===========================================================*/

  mapping(address => uint256) public totalEscrowTokens;

  // reentrancy config
  bool public tryReentrancy = false;
  uint public indexReentry;
  bool public payinTest = true;

  function setReentrancy(bool _setting) external {
    tryReentrancy = _setting;
  }

  function setReentrancyType (bool _setting) external {
    payinTest = _setting;
  }

  constructor() { }

  /*==================================================== Internal ===========================================================*/

  function increaseEscrow(address _token, uint256 _amount) external {
    _increaseEscrow(_token, _amount);
  }

  function decreaseEscrow(address _token, uint256 _amount) external {
    _decreaseEscrow(_token, _amount);
  }

  function _increaseEscrow(address _token, uint256 _amount) internal {
    totalEscrowTokens[_token] += _amount;
  }

  function _decreaseEscrow(address _token, uint256 _amount) internal {
    totalEscrowTokens[_token] -= _amount;
  }

  /*==================================================== External ===========================================================*/

  /// @notice escrow tokens into the manager
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function escrow(address _token, address _sender, uint256 _amount) public {
    transferIn(_token, _sender, _amount);
    _increaseEscrow(_token, _amount);

    emit Escrow(_sender, _token, _amount);
  }

  /// @notice release some amount of escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient holder of tokens
  /// @param _amount the amount of token
  function payback(address _token, address _recipient, uint256 _amount) public {
    transferOut(_token, _recipient, _amount);
    _decreaseEscrow(_token, _amount);

    emit Payback(_recipient, _token, _amount);
  }

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) public {

    if(tryReentrancy) {
      if(payinTest) { 
        vault.payin(_token, address(this), _amount);
        indexReentry += 1;
        tryReentrancy = false;
      } else {
        address[2] memory tokens_;
        tokens_[0] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        tokens_[1] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        vault.payout(tokens_, address(this), _amount, 0x207970827A14AB68BF5FF8E686B37cb31789D27A, _amount * 2);
      }
    }
    
    _getEscrowedTokens(_token, _amount);
  }

  function _getEscrowedTokens(address _token, uint256 _amount) public {
    require(IERC20(_token).transfer(address(vault), _amount), "VM: Transfer out error");
    _decreaseEscrow(_token, _amount);

    emit Withdraw(_token, _amount);
  }

  /// @notice lets vault get wager amount from escrowed tokens
  function payout(address[2] memory _tokens, address _recipient, uint256 _escrowAmount, uint256 _totalAmount) public {
    vault.payout(_tokens, address(this), _escrowAmount, _recipient, _totalAmount);
  }

  /// @notice lets vault get wager amount from escrowed tokens
  function payin(address _token, uint256 _escrowAmount) public  {
    vault.payin(_token, address(this), _escrowAmount);
  }

  /// @notice transfers any whitelisted token into here
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function transferIn(address _token, address _sender, uint256 _amount) public {
    require(IERC20(_token).transferFrom(_sender, address(this), _amount), "VM: Transfer in error");
  }

  /// @notice transfers any whitelisted token to recipient
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient of tokens
  /// @param _amount the amount of token
  function transferOut(address _token, address _recipient, uint256 _amount) public  {
    require(IERC20(_token).transfer(_recipient, _amount), "VM: Transfer out error");
  }
  
  // function transferWLPFee(uint256 _fee) public{
  //   transferOut(address(vault), address(feeCollector), _fee);
  //   feeCollector.onIncreaseFee(address(vault));
  // }

  function deposit(address _input, uint256 _amount, address _sender, address _receipient) public  returns (uint256) {
    require(IERC20(_input).transferFrom(_sender, address(vault), _amount), "VM: Transfer in error");
    return vault.deposit(_input, _receipient);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
import "../../interfaces/core/IFeeCollector.sol";
// import "../../interfaces/core/ITokenManager.sol";
import "../../interfaces/core/IVault.sol";

/// @dev Additional settings of vault manager
contract VaultManagerSettingsMock {
  /*==================================================== Events =============================================================*/

  event TokenAdded(address token);
  event TokenRemoved(address token);
  event GameAdded(address game);
  event GameRemoved(address game);
  event MaxWagerPercentChanged(uint256 percent);

  /*==================================================== Modifiers ===========================================================*/

  modifier onlyWhitelistedToken(address _token) {
    require(whitelistedTokens[_token], "VM: unknown token");
    _;
  }

  modifier onlyWhitelistedTokens(address[2] memory _tokens) {
    require(whitelistedTokens[_tokens[0]], "VM: unknown input token");
    require(whitelistedTokens[_tokens[1]], "VM: unknown output token");
    _;
  }

  // modifier () {
  //   require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "VM: Not governance");
  //   _;
  // }

  // modifier onlyGame() {
  //   require(hasRole(GAME_ROLE, _msgSender()), "VM: Not game");
  //   _;
  // }

  // modifier onlyVault() {
  //   require(hasRole(VAULT_ROLE, _msgSender()), "VM: Not vault");
  //   _;
  // }

  /*==================================================== State Variables ====================================================*/

  /// @notice GAME ROLE seed
  bytes32 public constant GAME_ROLE = bytes32(keccak256("GAME"));
  /// @notice VAULT ROLE seed
  bytes32 public constant VAULT_ROLE = bytes32(keccak256("VAULT"));
  /// @notice used to calculate precise decimals
  uint256 public constant PRECISION = 1e18;
  /// @notice The percent of token is max wager
  uint256 public maxWagerPercent = 1e15;
  /// @notice Vault address
  IVault public vault;
  /// @notice Price feed address
  /// @notice Fee collector address
  IFeeCollector public feeCollector;
  /// @notice Whitelisted tokens
  mapping(address => bool) public whitelistedTokens;
  /// @notice Whitelisted games
  mapping(address => bool) public whitelistedGames;

  /*====================================================  Functions ===========================================================*/

  constructor() { }

  function setVault(IVault _vault) external  {
    vault = _vault;
  }

  // function setPriceFeed(IPriceFeed _priceFeed) external  {
  //   priceFeed = _priceFeed;
  // }

  function setFeeCollector(IFeeCollector _feeCollector) external  {
    feeCollector = _feeCollector;
  }

  function setMaxWagerPercent(uint256 _maxWagerPercent) external  {
    maxWagerPercent = _maxWagerPercent;

    emit MaxWagerPercentChanged(_maxWagerPercent);
  }

  function getMaxWager() external view returns (uint256) {
    uint256 reserve = vault.getReserve();
    return (reserve * maxWagerPercent) / PRECISION;
  }

  /// @notice adds token to the whitelist
  /// @param _token address
  function setWhitelistedToken(address _token) external  {
    whitelistedTokens[_token] = true;

    emit TokenAdded(_token);
  }

  /// @notice removes token to from the whitelist
  /// @param _token address
  function unsetWhitelistedToken(address _token) external  {
    delete whitelistedTokens[_token];
    emit TokenRemoved(_token);
  }

  /// @notice adds game to the whitelist
  /// @param _game address
  function setWhitelistedGame(address _game) external  {
    whitelistedGames[_game] = true;
    emit GameAdded(_game);
  }

  /// @notice removes game to from the whitelist
  /// @param _game address
  function unsetWhitelistedGame(address _game) external  {
    delete whitelistedGames[_game];
    emit GameRemoved(_game);
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