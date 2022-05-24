// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./QiDaoSimpleBorrower.sol";
// import "forge-std/console.sol";

contract QiDaoSimpleBorrowerArbitrumWBTC is QiDaoSimpleBorrower {
  using SafeERC20 for IERC20;

  address internal constant MAI_ADDRESS = 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d;
  address internal constant VAULT_ADDRESS = 0xB237f4264938f0903F5EC120BB1Aa4beE3562FfF;
  address internal constant TOKEN_ADDRESS = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address internal constant QI_ADDRESS = 0xB9C8F0d3254007eE4b98970b94544e473Cd610EC;
  address internal constant GELATO_OPS_ADDRESS = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

  constructor() QiDaoSimpleBorrower(MAI_ADDRESS, VAULT_ADDRESS, TOKEN_ADDRESS, QI_ADDRESS, GELATO_OPS_ADDRESS) {
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC20Metadata.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
// import "forge-std/console.sol";

/// @title QiDao Simple Borrow Contract
/// @dev This is an abstract contract that must be implemented for each vault type.
abstract contract QiDaoSimpleBorrower is UUPSUpgradeable {
  using SafeERC20 for IERC20;

  function _authorizeUpgrade(address) internal override onlyOwner {}

  // Constants
  enum RebalanceType { NONE, BORROW, REPAY }
  uint constant PRICE_PRECISION = 1e8; // qidao oracles are USD with 1e8 decimals
  uint constant CDR_PRECISION = 1e4; // 4 decimals of precision, e.g. 11500 = 115%

  // Immutables (set by child contract)

  address immutable owner; // Owner of this contract
  address immutable maiAddress; // Address of the MAI token
  address immutable tokenAddress; // Address of the underlying token in the vault
  address immutable qiAddress; // Address of the QI token
  address immutable vaultAddress; // QiDao vault address
  address immutable gelatoOpsAddress;

  // Storage variables: do not change order or remove, as this contract must be upgradeable

  // folder stuff
  uint public vaultId; // QiDao vault ID (created upon initialization)
  uint public targetCdr; // target CDR
  uint public maxCdr; // borrow more when above this CDR

  // Modifiers

  modifier onlyOwner() {
    require(owner == msg.sender, "not owner");
    _;
  }

  modifier onlyOwnerOrGelato() {
    require(owner == msg.sender || gelatoOpsAddress == msg.sender, "not owner or gelato");
    _;
  }

  modifier onlyInitialized() {
    require(vaultId != 0, "not initialized");
    _;
  }

  // Initialization

  // sets immutable variables only, as this will be deployed behind a proxy
  constructor(address _maiAddress, address _vaultAddress, address _tokenAddress, address _qiAddress, address _gelatoOpsAddress) {
    owner = msg.sender;
    maiAddress = _maiAddress;
    vaultAddress = _vaultAddress;
    tokenAddress = _tokenAddress;
    qiAddress = _qiAddress;
    gelatoOpsAddress = _gelatoOpsAddress;
  }

  /// @notice create a vault and initialize storage variables
  function initialize(
    uint _targetCdr,
    uint _maxCdr
  ) external onlyOwner {
    require(vaultId == 0, "already initialized");
    _setTargetCdr(_targetCdr);
    _setMaxCdr(_maxCdr);
    IERC20(tokenAddress).safeApprove(vaultAddress, type(uint).max);
    IERC20(maiAddress).safeApprove(vaultAddress, type(uint).max);
    vaultId = QiDaoVault(vaultAddress).createVault();
  }

  // External

  /// @param _vaultId new vault ID (must be owned by this contract)
  function setVaultId(uint _vaultId) external onlyOwner {
    require(vaultId == 0, "already initialized");
    vaultId = _vaultId;
  }

  /// @param _targetCdr target collateral:debt ratio with 4 decimals of precision, e.g. "11500" for 115%
  function setTargetCdr(uint _targetCdr) external onlyOwner onlyInitialized {
    _setTargetCdr(_targetCdr);
  }

  /// @param _maxCdr max collateral:debt ratio with 4 decimals of precision, e.g. "11500" for 115%
  function setMaxCdr(uint _maxCdr) external onlyOwner onlyInitialized {
    _setMaxCdr(_maxCdr);
  }

  /// @notice Rebalances the vault based on the target CDR by either borrowing or repaying if necessary.
  function rebalance() external onlyOwnerOrGelato onlyInitialized {
    RebalanceType rt = _getRebalanceType();
    require(rt != RebalanceType.NONE, "no rebalance needed");

    if (rt == RebalanceType.BORROW) {
      _borrow();
    } else if (rt == RebalanceType.REPAY) {
      _repay();
    }
  }

  function checkRebalanceGelato() external view returns (bool canExec, bytes memory execPayload) {
    RebalanceType rt = _getRebalanceType();

    if (rt != RebalanceType.NONE) {
      canExec = true;
      execPayload = abi.encodeWithSelector(QiDaoSimpleBorrower.rebalance.selector);
    }
  }

  /// @notice deposits collateral tokens from this contract to the QiDao vault.
  /// @param _amount amount of tokens to deposit
  function depositCollateral(uint _amount) external onlyOwner onlyInitialized {
    _depositCollateral(_amount);
  }

  function repay(uint _amount) external onlyOwner onlyInitialized {
    require(_amount <= maiBalance(), "not enough mai to repay");
    QiDaoVault(vaultAddress).payBackToken(vaultId, _amount);
  }

  /// @notice withdraws collateral tokens from the QiDao vault.
  function withdrawCollateral(uint _amount) external onlyOwner onlyInitialized {
    _withdrawCollateral(_amount);
  }

  /// @notice withdraws collateral tokens from this contract.
  function withdrawTokens(uint _amount) external onlyOwner onlyInitialized {
    require(_amount <= tokenBalance(), "not enough tokens to withdraw");
    IERC20(tokenAddress).safeTransfer(owner, _amount);
  }

  /// @notice withdraws full balance of Qi tokens from this contract.
  function withdrawQi(uint _amount) external onlyOwner onlyInitialized {
    require(_amount <= qiBalance(), "not enough qi to withdraw");
    IERC20(qiAddress).safeTransfer(owner, _amount);
  }

  /// @notice withdraws full balance of MAI tokens from this contract.
  function withdrawMai(uint _amount) external onlyOwner onlyInitialized {
    require(_amount <= maiBalance(), "not enough MAI to withdraw");
    IERC20(maiAddress).safeTransfer(owner, _amount);
  }

  /// @notice withdraw the balance of a token from the contract
  /// @param _token token address
  /// @param _amount token amount
  function rescueToken(address _token, uint _amount) external onlyOwner {
    if (_token == address(0)) {
      payable(owner).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(owner, _amount);
    }
  }

  /// @notice "bails out" by transferring the underlying vault NFT to the owner
  /// after this function is called, the folder can be initialized again if needed
  function bailout() external onlyOwner onlyInitialized {
    QiDaoVault(vaultAddress).safeTransferFrom(address(this), owner, vaultId);
    vaultId = 0; // clear vaultId
  }

  // Public

  function targetMaxCdrAvg() view public returns (uint) {
    if (targetCdr == type(uint).max || maxCdr == type(uint).max) {
      return type(uint).max;
    }

    return (targetCdr + maxCdr) / 2;
  }

  /// @return amount of MAI that can be borrowed based on the CDR that we are targeting.
  /// The return value of this function will also be capped at the current debt ceiling of vault.
  /// Expressed with 1e18 decimals of precision.
  function availableBorrows() view public returns (uint) {
    uint borrowsBasedOnCdr = _availableBorrowsByTargetMaxCdrAvg();
    uint borrowsBasedOnMai = QiDaoVault(vaultAddress).getDebtCeiling();

    // return the min
    return borrowsBasedOnCdr < borrowsBasedOnMai ? borrowsBasedOnCdr : borrowsBasedOnMai;
  }

  /// @return number of underlying tokens in this contract
  function tokenBalance() view public returns (uint) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  /// @return number of Qi tokens in this contract
  function qiBalance() view public returns (uint) {
    return IERC20(qiAddress).balanceOf(address(this));
  }

  /// @return number of MAI tokens in this contract
  function maiBalance() view public returns (uint) {
    return IERC20(maiAddress).balanceOf(address(this));
  }

  /// @return amount of MAI debt in the QiDao vault
  function vaultDebt() view public returns (uint) {
    return QiDaoVault(vaultAddress).vaultDebt(vaultId);
  }

  /// @return amount of collateral locked in the QiDao vault
  function vaultCollateral() view public returns (uint) {
    return QiDaoVault(vaultAddress).vaultCollateral(vaultId);
  }

  /// @return current CDR for this vault, expressed with CDR_PRECISION decimals of precision
  function vaultCdr() view public returns (uint) {
    uint debt = vaultDebt();
    return debt == 0 ? type(uint).max : _vaultCollateralValue() * CDR_PRECISION / debt;
  }

  // Internal

  function _borrow() internal {
    uint borrowAmount = availableBorrows();
    require(borrowAmount > 0, "no borrows available");
    QiDaoVault(vaultAddress).borrowToken(vaultId, borrowAmount);
  }

  function _repay() internal {
    uint targetDebt = _vaultCollateralValue() * CDR_PRECISION / targetMaxCdrAvg();
    uint currentDebt = vaultDebt();
    require(targetDebt < currentDebt, "no need to repay");
    uint targetAmountToRepay = currentDebt - targetDebt;
    uint maiBal = maiBalance();
    require(maiBal > 0, "no tokens to repay with");
    uint amountToRepay = maiBal < targetAmountToRepay ? maiBal : targetAmountToRepay;
    QiDaoVault(vaultAddress).payBackToken(vaultId, amountToRepay);
  }

  function _setTargetCdr(uint _targetCdr) internal {
    require(_targetCdr > _vaultMinimumCdr(), "targetCdr too low");
    targetCdr = _targetCdr;
  }

  function _setMaxCdr(uint _maxCdr) internal {
    require(_maxCdr > _vaultMinimumCdr(), "maxCdr too low");
    require(_maxCdr > targetCdr, "maxCdr must be gt targetCdr");
    maxCdr = _maxCdr;
  }

  function _depositCollateral(uint _amount) internal {
    require(_amount > 0, "must deposit more than 0 tokens");
    require(_amount <= tokenBalance(), "not enough collateral to deposit");
    QiDaoVault(vaultAddress).depositCollateral(vaultId, _amount);
  }

  function _withdrawCollateral(uint _amount) internal {
    QiDaoVault(vaultAddress).withdrawCollateral(vaultId, _amount);
  }

  function _getRebalanceType() view internal returns (RebalanceType rt) {
    if (vaultId == 0) {
      return RebalanceType.NONE; // not initialized
    }

    if (vaultCollateral() == 0) {
      return RebalanceType.NONE; // vault has no collateral
    }

    uint cdr = vaultCdr();

    if ((cdr > maxCdr) && (availableBorrows() > 0)) {
      rt = RebalanceType.BORROW;
    } else if (cdr < targetCdr && maiBalance() > 0) {
      rt = RebalanceType.REPAY;
    }
  }

  function _collateralPrice() view internal returns (uint) {
    uint price = QiDaoVault(vaultAddress).getEthPriceSource();
    uint decimals = _tokenDecimals();

    if (decimals < 18) {
      return price * (10 ** (18 - decimals));
    } else {
      return price;
    }
  }

  /// @return approximate USD value of the vault collateral, expressed with 1e18 decimals of precision
  function _vaultCollateralValue() view internal returns (uint) {
    return vaultCollateral() * _collateralPrice() / PRICE_PRECISION;
  }

  /// @return Minimum CDR for this vault, expressed with CDR_PRECISION decimals of precision
  function _vaultMinimumCdr() view internal returns (uint) {
    return QiDaoVault(vaultAddress)._minimumCollateralPercentage() * CDR_PRECISION / 1e2;
  }

  function _maiBalance() view internal returns (uint) {
    return IERC20(maiAddress).balanceOf(address(this));
  }

  function _tokenDecimals() view internal returns (uint) {
    return IERC20Metadata(tokenAddress).decimals();
  }

  function _availableBorrowsByTargetMaxCdrAvg() view internal returns (uint) {
    uint maxTotalBorrowsInCollateral = _vaultCollateralValue() * CDR_PRECISION / targetMaxCdrAvg();
    uint debt = vaultDebt();
    return maxTotalBorrowsInCollateral > debt ? maxTotalBorrowsInCollateral - debt : 0;
  }

  // allow receiving NFT xfer
  function onERC721Received(address, address, uint256, bytes calldata) pure external returns (bytes4) {
    return QiDaoSimpleBorrower.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IYVault {
  function withdraw(uint shares) external;
  function deposit(uint amount) external;
}

interface IAPool {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying) external;
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount, bool _use_underlying) external;
}

interface IVGHST {
  function enter(uint256 _amount) external;
  function leave(uint256 _share) external;
}

interface IUniswapV2Pair {
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
  event Sync(uint112 reserve0, uint112 reserve1);
  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);
  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

interface QiDaoVault {
  function _minimumCollateralPercentage() external view returns (uint256);

  function approve(address to, uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256);

  function baseURI() external view returns (string memory);

  function borrowToken(uint256 vaultID, uint256 amount) external;

  function burn(uint256 amountToken) external;

  function changeEthPriceSource(address ethPriceSourceAddress) external;

  function checkCollateralPercentage(uint256 vaultID)
      external
      view
      returns (uint256);

  function checkCost(uint256 vaultID) external view returns (uint256);

  function checkExtract(uint256 vaultID) external view returns (uint256);

  function checkLiquidation(uint256 vaultID) external view returns (bool);

  function closingFee() external view returns (uint256);

  function collateral() external view returns (address);

  function createVault() external returns (uint256);

  function debtRatio() external view returns (uint256);

  function depositCollateral(uint256 vaultID, uint256 amount) external;

  function destroyVault(uint256 vaultID) external;

  function ethPriceSource() external view returns (address);

  function exists(uint256 vaultID) external view returns (bool);

  function gainRatio() external view returns (uint256);

  function getApproved(uint256 tokenId) external view returns (address);

  function getClosingFee() external view returns (uint256);

  function getDebtCeiling() external view returns (uint256);

  function getEthPriceSource() external view returns (uint256);

  function getPaid() external;

  function getTokenPriceSource() external view returns (uint256);

  function isApprovedForAll(address owner, address operator)
      external
      view
      returns (bool);

  function isOwner() external view returns (bool);

  function liquidateVault(uint256 vaultID) external;

  function mai() external view returns (address);

  function maticDebt(address) external view returns (uint256);

  function name() external view returns (string memory);

  function owner() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function payBackToken(uint256 vaultID, uint256 amount) external;

  function priceSourceDecimals() external view returns (uint256);

  function renounceOwnership() external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
  ) external;

  function setApprovalForAll(address to, bool approved) external;

  function setDebtRatio(uint256 _debtRatio) external;

  function setGainRatio(uint256 _gainRatio) external;

  function setMinCollateralRatio(uint256 minimumCollateralPercentage)
      external;

  function setStabilityPool(address _pool) external;

  function setTokenURI(string memory _uri) external;

  function setTreasury(uint256 _treasury) external;

  function stabilityPool() external view returns (address);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index)
      external
      view
      returns (uint256);

  function tokenPeg() external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalBorrowed() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function transferOwnership(address newOwner) external;

  function treasury() external view returns (uint256);

  function uri() external view returns (string memory);

  function vaultCollateral(uint256) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaultDebt(uint256) external view returns (uint256);

  function withdrawCollateral(uint256 vaultID, uint256 amount) external;
}

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changeProtectionMode(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function setToInvest(uint256 _value) external;

  function doHardWork() external;

  function rebalance() external;

  function disableLock() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external view returns (uint256);

  function userLastDepositTs(address _user) external view returns (uint256);

  function userBoostTs(address _user) external view returns (uint256);

  function userLockTs(address _user) external view returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function depositFeeNumerator() external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);
}

uint160 constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
uint160 constant MAX_SQRT_RATIO_MINUS_ONE = 1461446703485210103287273052203988822378723970341;

interface IUniswapV3Pool {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}