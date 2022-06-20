// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Math.sol";
import "../interfaces/ISplitter.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/IGauge.sol";
import "../proxy/ControllableV3.sol";
import "./ERC4626Upgradeable.sol";

/// @title Vault for storing underlying tokens and managing them with strategy splitter.
/// @author belbix
contract TetuVaultV2 is ERC4626Upgradeable, ControllableV3, ITetuVaultV2 {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant VAULT_VERSION = "2.0.0";
  /// @dev Denominator for buffer calculation. 100% of the buffer amount.
  uint private constant BUFFER_DENOMINATOR = 100_000;
  /// @dev Denominator for fee calculation.
  uint constant public FEE_DENOMINATOR = 100_000;
  /// @dev Max 1% fee.
  uint constant public MAX_FEE = FEE_DENOMINATOR / 100;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Strategy splitter. Should be setup after deploy.
  ISplitter public splitter;
  /// @dev Connected gauge for stakeless rewards
  IGauge public gauge;
  /// @dev Dedicated contract for holding insurance for covering share price loss.
  IVaultInsurance public insurance;
  /// @dev Percent of assets that will always stay in this vault.
  uint public buffer;

  /// @dev Maximum amount for withdraw. Max UINT256 by default.
  uint internal _maxWithdrawAssets;
  /// @dev Maximum amount for redeem. Max UINT256 by default.
  uint internal _maxRedeemShares;
  /// @dev Maximum amount for deposit. Max UINT256 by default.
  uint internal _maxDepositAssets;
  /// @dev Maximum amount for mint. Max UINT256 by default.
  uint internal _maxMintShares;
  /// @dev Fee for deposit/mint actions. Zero by default.
  uint public depositFee;
  /// @dev Fee for withdraw/redeem actions. Zero by default.
  uint public withdrawFee;

  /// @dev Trigger doHardwork on invest action. Enabled by default.
  bool public doHardWorkOnInvest;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event Init(
    address controller,
    address asset,
    string name,
    string symbol,
    address gauge,
    uint buffer
  );
  event SplitterChanged(address oldValue, address newValue);
  event BufferChanged(uint oldValue, uint newValue);
  event Invest(address splitter, uint amount);
  event MaxWithdrawChanged(uint maxAssets, uint maxShares);
  event MaxDepositChanged(uint maxAssets, uint maxShares);
  event FeeChanged(uint depositFee, uint withdrawFee);
  event DoHardWorkOnInvestChanged(bool oldValue, bool newValue);
  event FeeTransfer(uint amount);
  event LossCovered(uint amount);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external initializer override {
    require(_buffer <= BUFFER_DENOMINATOR, "!BUFFER");
    require(_gauge != address(0), "!GAUGE");
    require(IControllable(_gauge).isController(controller_), "!GAUGE_CONTROLLER");

    __ERC4626_init(_asset, _name, _symbol);
    __Controllable_init(controller_);

    gauge = IGauge(_gauge);
    buffer = _buffer;

    // set defaults
    _maxWithdrawAssets = type(uint).max;
    _maxRedeemShares = type(uint).max;
    _maxDepositAssets = type(uint).max - 1;
    _maxMintShares = type(uint).max - 1;
    doHardWorkOnInvest = true;

    emit Init(
      controller_,
      address(_asset),
      _name,
      _symbol,
      _gauge,
      _buffer
    );
  }

  function initInsurance(IVaultInsurance _insurance) external override {
    require(address(insurance) == address(0), "INITED");
    require(_insurance.vault() == address(this), "!VAULT");
    require(_insurance.asset() == address(asset), "!ASSET");
    insurance = _insurance;
  }

  // *************************************************************
  //                      GOV ACTIONS
  // *************************************************************

  /// @dev Set new buffer value. Should be lower than denominator.
  function setBuffer(uint _buffer) external {
    require(isGovernance(msg.sender), "DENIED");
    require(_buffer <= BUFFER_DENOMINATOR, "BUFFER");

    emit BufferChanged(buffer, _buffer);
    buffer = _buffer;
  }

  /// @dev Set maximum available to deposit amounts.
  ///      Could be zero values in emergency case when need to pause malicious actions.
  function setMaxDeposit(uint maxAssets, uint maxShares) external {
    require(isGovernance(msg.sender), "DENIED");

    _maxDepositAssets = maxAssets;
    _maxMintShares = maxShares;
    emit MaxDepositChanged(maxAssets, maxShares);
  }

  /// @dev Set maximum available to withdraw amounts.
  ///      Could be zero values in emergency case when need to pause malicious actions.
  function setMaxWithdraw(uint maxAssets, uint maxShares) external {
    require(isGovernance(msg.sender), "DENIED");

    _maxWithdrawAssets = maxAssets;
    _maxRedeemShares = maxShares;
    emit MaxWithdrawChanged(maxAssets, maxShares);
  }

  /// @dev Set deposit/withdraw fees
  function setFees(uint _depositFee, uint _withdrawFee) external {
    require(isGovernance(msg.sender), "DENIED");
    require(_depositFee <= MAX_FEE && _withdrawFee <= MAX_FEE, "TOO_HIGH");

    depositFee = _depositFee;
    withdrawFee = _withdrawFee;
    emit FeeChanged(_depositFee, _withdrawFee);
  }

  /// @dev If activated will call doHardWork on splitter on each invest action.
  function setDoHardWorkOnInvest(bool value) external {
    require(isGovernance(msg.sender), "DENIED");
    emit DoHardWorkOnInvestChanged(doHardWorkOnInvest, value);
    doHardWorkOnInvest = value;
  }

  /// @dev Change splitter address. If old value exist properly withdraw and remove allowance.
  function setSplitter(address _splitter) external override {
    address oldSplitter = address(splitter);
    IERC20 _asset = asset;
    require(oldSplitter == address(0)
      || IController(controller()).vaultController() == msg.sender, "DENIED");
    require(ISplitter(_splitter).asset() == address(_asset), "WRONG_UNDERLYING");
    require(ISplitter(_splitter).vault() == address(this), "WRONG_VAULT");
    require(IControllable(_splitter).isController(controller()), "WRONG_CONTROLLER");
    if (oldSplitter != address(0)) {
      _asset.safeApprove(oldSplitter, 0);
      ISplitter(oldSplitter).withdrawAllToVault();
    }
    _asset.safeApprove(_splitter, 0);
    _asset.safeApprove(_splitter, type(uint).max);
    splitter = ISplitter(_splitter);
    emit SplitterChanged(oldSplitter, _splitter);
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Total amount of the underlying asset that is “managed” by Vault
  function totalAssets() public view override returns (uint) {
    return asset.balanceOf(address(this)) + splitter.totalAssets();
  }

  /// @dev Amount of assets under control of strategy splitter.
  function splitterAssets() external view returns (uint) {
    return splitter.totalAssets();
  }

  /// @dev Price of 1 full share
  function sharePrice() external view returns (uint) {
    uint units = 10 ** uint256(decimals());
    uint totalSupply_ = _totalSupply;
    return totalSupply_ == 0
    ? units
    : units * totalAssets() / totalSupply_;
  }

  // *************************************************************
  //                 DEPOSIT LOGIC
  // *************************************************************

  function previewDeposit(uint assets) public view virtual override returns (uint) {
    uint shares = convertToShares(assets);
    return shares - (shares * depositFee / FEE_DENOMINATOR);
  }

  function previewMint(uint shares) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    if (supply != 0) {
      uint assets = shares.mulDivUp(totalAssets(), supply);
      return assets * FEE_DENOMINATOR / (FEE_DENOMINATOR - depositFee);
    } else {
      return shares * FEE_DENOMINATOR / (FEE_DENOMINATOR - depositFee);
    }
  }

  /// @dev Calculate available to invest amount and send this amount to splitter
  function afterDeposit(uint assets, uint) internal override {
    address _splitter = address(splitter);
    IERC20 _asset = asset;
    uint _depositFee = depositFee;
    // send fee to insurance contract
    if (_depositFee != 0) {
      uint toFees = assets * _depositFee / FEE_DENOMINATOR;
      _asset.safeTransfer(address(insurance), toFees);
      emit FeeTransfer(toFees);
    }
    uint256 toInvest = _availableToInvest(_splitter, _asset);
    // invest only when buffer is filled
    if (toInvest > 0) {

      // need to check recursive hardworks
      if (doHardWorkOnInvest && !ISplitter(_splitter).isHardWorking()) {
        ISplitter(_splitter).doHardWork();
      }

      _asset.safeTransfer(_splitter, toInvest);
      ISplitter(_splitter).investAll();
      emit Invest(_splitter, toInvest);
    }
  }

  /// @notice Returns amount of assets ready to invest to the splitter
  function _availableToInvest(address _splitter, IERC20 _asset) internal view returns (uint) {
    uint _buffer = buffer;
    if (_splitter == address(0) || _buffer == BUFFER_DENOMINATOR) {
      return 0;
    }
    uint assetsInVault = _asset.balanceOf(address(this));
    uint assetsInSplitter = ISplitter(_splitter).totalAssets();
    uint wantInvestTotal = (assetsInVault + assetsInSplitter)
    * (BUFFER_DENOMINATOR - _buffer) / BUFFER_DENOMINATOR;
    if (assetsInSplitter >= wantInvestTotal) {
      return 0;
    } else {
      uint remainingToInvest = wantInvestTotal - assetsInSplitter;
      return remainingToInvest <= assetsInVault ? remainingToInvest : assetsInVault;
    }
  }

  // *************************************************************
  //                 WITHDRAW LOGIC
  // *************************************************************

  function withdrawAll() external {
    redeem(balanceOf(msg.sender), msg.sender, msg.sender);
  }

  function previewWithdraw(uint assets) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    uint _totalAssets = totalAssets();
    if (_totalAssets == 0) {
      return assets;
    }
    uint shares = assets.mulDivUp(supply, _totalAssets);
    shares = shares * FEE_DENOMINATOR / (FEE_DENOMINATOR - withdrawFee);
    return supply == 0 ? assets : shares;
  }

  function previewRedeem(uint shares) public view virtual override returns (uint) {
    shares = shares - (shares * withdrawFee / FEE_DENOMINATOR);
    return convertToAssets(shares);
  }

  function maxDeposit(address) public view override returns (uint) {
    return _maxDepositAssets;
  }

  function maxMint(address) public view override returns (uint) {
    return _maxMintShares;
  }

  function maxWithdraw(address owner) public view override returns (uint) {
    return Math.min(_maxWithdrawAssets, convertToAssets(_balances[owner]));
  }

  function maxRedeem(address owner) public view override returns (uint) {
    return Math.min(_maxRedeemShares, _balances[owner]);
  }

  /// @dev Internal hook for getting necessary assets from splitter.
  function beforeWithdraw(
    uint assets,
    uint shares
  ) internal override {
    uint _withdrawFee = withdrawFee;
    uint fromSplitter;
    if (_withdrawFee != 0) {
      // add fee amount
      fromSplitter = assets * FEE_DENOMINATOR / (FEE_DENOMINATOR - _withdrawFee);
    } else {
      fromSplitter = assets;
    }

    IERC20 _asset = asset;
    uint balance = _asset.balanceOf(address(this));
    // if not enough balance in the vault withdraw from strategies
    if (balance < fromSplitter) {
      _processWithdrawFromSplitter(
        fromSplitter,
        shares,
        _totalSupply,
        buffer,
        splitter,
        balance
      );
    }
    balance = _asset.balanceOf(address(this));
    require(assets <= balance, "SLIPPAGE");

    // send fee amount to insurance for keep correct calculations
    // in case of compensation it will lead to double transfer
    // but we assume that it will be rare case
    if (_withdrawFee != 0) {
      // we should compensate possible slippage from user fee too
      uint toFees = Math.min(fromSplitter - assets, balance - assets);
      if (toFees != 0) {
        _asset.safeTransfer(address(insurance), toFees);
        emit FeeTransfer(toFees);
      }
    }
  }

  /// @dev Do necessary calculation for withdrawing from splitter and move assets to vault.
  ///      If splitter not defined must not be called.
  function _processWithdrawFromSplitter(
    uint assetsNeed,
    uint shares,
    uint totalSupply_,
    uint _buffer,
    ISplitter _splitter,
    uint assetsInVault
  ) internal {
    // withdraw everything from the splitter to accurately check the share value
    if (shares == totalSupply_) {
      _splitter.withdrawAllToVault();
    } else {
      uint assetsInSplitter = _splitter.totalAssets();
      // we should always have buffer amount inside the vault
      uint missing = (assetsInSplitter + assetsInVault)
      * _buffer / BUFFER_DENOMINATOR
      + assetsNeed;
      missing = Math.min(missing, assetsInSplitter);
      // if zero should be resolved on splitter side
      _splitter.withdrawToVault(missing);
    }

  }

  // *************************************************************
  //                 INSURANCE LOGIC
  // *************************************************************

  function coverLoss(uint amount) external override {
    require(msg.sender == address(splitter), "!SPLITTER");
    IVaultInsurance _insurance = insurance;
    uint balance = asset.balanceOf(address(_insurance));
    uint fromFees = Math.min(amount, balance);
    _insurance.transferToVault(fromFees);
    emit LossCovered(fromFees);
  }

  // *************************************************************
  //                 GAUGE HOOK
  // *************************************************************

  /// @dev Connect this vault to the gauge for non-contract addresses.
  function _afterTokenTransfer(
    address from,
    address to,
    uint
  ) internal override {
    if (isNotSmartContract(from)) {
      gauge.handleBalanceChange(from);
    }
    if (isNotSmartContract(to)) {
      gauge.handleBalanceChange(to);
    }
  }

  /// @notice Return true if given address is not a smart contract but a wallet address
  /// @dev it is not 100% guarantee after EIP-3074 implementation
  ///       use it as an additional check
  /// @param _adr Address for check
  /// @return true if the address is a wallet
  function isNotSmartContract(address _adr) private view returns (bool) {
    return _adr == tx.origin;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IVaultInsurance.sol";
import "./IERC20.sol";

interface ITetuVaultV2 {

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IGauge {

  function veIds(address stakingToken, address account) external view returns (uint);

  function getReward(
    address stakingToken,
    address account,
    address[] memory tokens
  ) external;

  function getAllRewards(
    address stakingToken,
    address account
  ) external;

  function getAllRewardsForTokens(
    address[] memory stakingTokens,
    address account
  ) external;

  function attachVe(address stakingToken, address account, uint veId) external;

  function detachVe(address stakingToken, address account, uint veId) external;

  function handleBalanceChange(address account) external;

  function notifyRewardAmount(address stakingToken, address token, uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/ERC20Upgradeable.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../interfaces/IERC4626.sol";
import "../lib/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @author belbix - adopted to proxy pattern + add ReentrancyGuard
abstract contract ERC4626Upgradeable is ERC20Upgradeable, ReentrancyGuard, IERC4626 {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint;

  /// @dev The address of the underlying token used for the Vault uses for accounting,
  ///      depositing, and withdrawing
  IERC20 public asset;

  function __ERC4626_init(
    IERC20 _asset,
    string memory _name,
    string memory _symbol
  ) internal onlyInitializing {
    __ERC20_init(_name, _symbol);
    asset = _asset;
  }

  function decimals() public view override returns (uint8) {
    return IERC20Metadata(address(asset)).decimals();
  }

  /*//////////////////////////////////////////////////////////////
  //             DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @dev Mints vault shares to receiver by depositing exactly amount of assets.
  function deposit(
    uint assets,
    address receiver
  ) public nonReentrant virtual override returns (uint shares) {
    require(assets <= maxDeposit(receiver), "MAX");

    shares = previewDeposit(assets);
    // Check for rounding error since we round down in previewDeposit.
    require(shares != 0, "ZERO_SHARES");

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function mint(
    uint shares,
    address receiver
  ) public nonReentrant virtual override returns (uint assets) {
    require(shares <= maxMint(receiver), "MAX");

    assets = previewMint(shares);
    // No need to check for rounding error, previewMint rounds up.

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function withdraw(
    uint assets,
    address receiver,
    address owner
  ) public nonReentrant virtual override returns (uint shares) {
    require(assets <= maxWithdraw(owner), "MAX");

    shares = previewWithdraw(assets);
    // No need to check for rounding error, previewWithdraw rounds up.

    if (msg.sender != owner) {
      uint allowed = _allowances[owner][msg.sender];
      // Saves gas for limited approvals.
      if (allowed != type(uint).max) _allowances[owner][msg.sender] = allowed - shares;
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  /// @dev Redeems shares from owner and sends assets to receiver.
  function redeem(
    uint shares,
    address receiver,
    address owner
  ) public nonReentrant virtual override returns (uint assets) {
    require(shares <= maxRedeem(owner), "MAX");

    if (msg.sender != owner) {
      uint allowed = _allowances[owner][msg.sender];
      // Saves gas for limited approvals.
      if (allowed != type(uint).max) _allowances[owner][msg.sender] = allowed - shares;
    }

    assets = previewRedeem(shares);
    // Check for rounding error since we round down in previewRedeem.
    require(assets != 0, "ZERO_ASSETS");

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  /*//////////////////////////////////////////////////////////////
  //                  ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @dev Total amount of the underlying asset that is “managed” by Vault
  function totalAssets() public view virtual override returns (uint);

  function convertToShares(uint assets) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }

  function convertToAssets(uint shares) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
  }

  function previewDeposit(uint assets) public view virtual override returns (uint) {
    return convertToShares(assets);
  }

  function previewMint(uint shares) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
  }

  function previewWithdraw(uint assets) public view virtual override returns (uint) {
    uint supply = _totalSupply;
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
  }

  function previewRedeem(uint shares) public view virtual override returns (uint) {
    return convertToAssets(shares);
  }

  ///////////////////////////////////////////////////////////////
  //           DEPOSIT/WITHDRAWAL LIMIT LOGIC
  ///////////////////////////////////////////////////////////////

  function maxDeposit(address) public view virtual override returns (uint) {
    return type(uint).max - 1;
  }

  function maxMint(address) public view virtual override returns (uint) {
    return type(uint).max - 1;
  }

  function maxWithdraw(address owner) public view virtual override returns (uint) {
    return convertToAssets(_balances[owner]);
  }

  function maxRedeem(address owner) public view virtual override returns (uint) {
    return _balances[owner];
  }

  ///////////////////////////////////////////////////////////////
  //                INTERNAL HOOKS LOGIC
  ///////////////////////////////////////////////////////////////

  function beforeWithdraw(uint assets, uint shares) internal virtual {}

  function afterDeposit(uint assets, uint shares) internal virtual {}

  /**
 * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
  modifier initializer() {
    bool isTopLevelCall = _setInitializedVersion(1);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
  modifier reinitializer(uint8 version) {
    bool isTopLevelCall = _setInitializedVersion(version);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(version);
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
  function _disableInitializers() internal virtual {
    _setInitializedVersion(type(uint8).max);
  }

  function _setInitializedVersion(uint8 version) private returns (bool) {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
    // of initializers, because in other contexts the contract may have been reentered.
    if (_initializing) {
      require(
        version == 1 && !Address.isContract(address(this)),
        "Initializable: contract is already initialized"
      );
      return false;
    } else {
      require(_initialized < version, "Initializable: contract is already initialized");
      _initialized = version;
      return true;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function vaultController() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/AddressUpgradeable.sol
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
  function sendValue(address payable recipient, uint amount) internal {
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
    uint value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint value,
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "../interfaces/IERC20Metadata.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/ERC20Upgradeable.sol
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Metadata {

  mapping(address => uint) internal _balances;

  mapping(address => mapping(address => uint)) internal _allowances;

  uint internal _totalSupply;

  string private _name;
  string private _symbol;

  /*//////////////////////////////////////////////////////////////
  //                   EIP-2612 STORAGE
  //////////////////////////////////////////////////////////////*/

  uint internal INITIAL_CHAIN_ID;

  bytes32 internal INITIAL_DOMAIN_SEPARATOR;

  mapping(address => uint) public nonces;

  /**
   * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
  function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;

    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  /**
   * @dev Returns the name of the token.
     */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
     */
  function totalSupply() public view virtual override returns (uint) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
     */
  function balanceOf(address account) public view virtual override returns (uint) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
  function transfer(address to, uint amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
     */
  function allowance(address owner, address spender) public view virtual override returns (uint) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
  function approve(address spender, uint amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
  function transferFrom(
    address from,
    address to,
    uint amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
  function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
  function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
    address owner = _msgSender();
    uint currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
  unchecked {
    _approve(owner, spender, currentAllowance - subtractedValue);
  }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
  function _transfer(
    address from,
    address to,
    uint amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
  unchecked {
    _balances[from] = fromBalance - amount;
  }
    _balances[to] += amount;

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
  function _mint(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
  function _burn(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
  unchecked {
    _balances[account] = accountBalance - amount;
  }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
  function _approve(
    address owner,
    address spender,
    uint amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
  function _spendAllowance(
    address owner,
    address spender,
    uint amount
  ) internal virtual {
    uint currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
    unchecked {
      _approve(owner, spender, currentAllowance - amount);
    }
    }
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _afterTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual {}

  /*//////////////////////////////////////////////////////////////
  //                      EIP-2612 LOGIC
  // https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol
  //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual {
    require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
  unchecked {
    address recoveredAddress = ecrecover(
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR(),
          keccak256(
            abi.encode(
              keccak256(
                "Permit(address owner,address spender,uint value,uint nonce,uint deadline)"
              ),
              owner,
              spender,
              value,
              nonces[owner]++,
              deadline
            )
          )
        )
      ),
      v,
      r,
      s
    );

    require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

    _allowances[recoveredAddress][spender] = value;
  }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
    keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint chainId,address verifyingContract)"),
        keccak256(bytes(_name)),
        keccak256("1"),
        block.chainid,
        address(this)
      )
    );
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[42] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/token/ERC20/utils/SafeERC20.sol
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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
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
    uint value
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
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
  unchecked {
    uint oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint newAllowance = oldAllowance - value;
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

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC4626 {

  event Deposit(address indexed caller, address indexed owner, uint assets, uint shares);

  event Withdraw(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint assets,
    uint shares
  );


  function deposit(uint assets, address receiver) external returns (uint shares);

  function mint(uint shares, address receiver) external returns (uint assets);

  function withdraw(
    uint assets,
    address receiver,
    address owner
  ) external returns (uint shares);

  function redeem(
    uint shares,
    address receiver,
    address owner
  ) external returns (uint assets);

  function totalAssets() external view returns (uint);

  function convertToShares(uint assets) external view returns (uint);

  function convertToAssets(uint shares) external view returns (uint);

  function previewDeposit(uint assets) external view returns (uint);

  function previewMint(uint shares) external view returns (uint);

  function previewWithdraw(uint assets) external view returns (uint);

  function previewRedeem(uint shares) external view returns (uint);

  function maxDeposit(address) external view returns (uint);

  function maxMint(address) external view returns (uint);

  function maxWithdraw(address owner) external view returns (uint);

  function maxRedeem(address owner) external view returns (uint);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*//////////////////////////////////////////////////////////////
  //SIMPLIFIED FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  uint internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded up.
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  /*//////////////////////////////////////////////////////////////
  //LOW LEVEL FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // First, divide z - 1 by the denominator and add 1.
    // We allow z - 1 to underflow if z is 0, because we multiply the
    // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function rpow(
    uint x,
    uint n,
    uint scalar
  ) internal pure returns (uint z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
        // 0 ** 0 = 1
          z := scalar
        }
        default {
        // 0 ** n = 0
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
        // If n is even, store scalar in z for now.
          z := scalar
        }
        default {
        // If n is odd, store x in z for now.
          z := x
        }

      // Shifting right by 1 is like dividing by 2.
        let half := shr(1, scalar)

        for {
        // Shift n right by 1 before looping to halve it.
          n := shr(1, n)
        } n {
        // Shift n right by 1 each iteration to halve it.
          n := shr(1, n)
        } {
        // Revert immediately if x ** 2 would overflow.
        // Equivalent to iszero(eq(div(xx, x), x)) here.
          if shr(128, x) {
            revert(0, 0)
          }

        // Store x squared.
          let xx := mul(x, x)

        // Round to the nearest number.
          let xxRound := add(xx, half)

        // Revert if xx + half overflowed.
          if lt(xxRound, xx) {
            revert(0, 0)
          }

        // Set x to scaled xxRound.
          x := div(xxRound, scalar)

        // If n is even:
          if mod(n, 2) {
          // Compute z * x.
            let zx := mul(z, x)

          // If z * x overflowed:
            if iszero(eq(div(zx, x), z)) {
            // Revert if x is non-zero.
              if iszero(iszero(x)) {
                revert(0, 0)
              }
            }

          // Round to the nearest number.
            let zxRound := add(zx, half)

          // Revert if zx + half overflowed.
            if lt(zxRound, zx) {
              revert(0, 0)
            }

          // Return properly scaled zxRound.
            z := div(zxRound, scalar)
          }
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
  // GENERAL NUMBER UTILITIES
  //////////////////////////////////////////////////////////////*/

  function sqrt(uint x) internal pure returns (uint z) {
    assembly {
    // Start off with z at 1.
      z := 1

    // Used below to help find a nearby power of 2.
      let y := x

    // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
      // Equivalent to 2 ** z.
        z := shl(1, z)
      }

    // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

    // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

    // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/ContextUpgradeable.sol
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {
  }

  function __Context_init_unchained() internal onlyInitializing {
  }
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
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