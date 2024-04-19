// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {StrategyProxy} from "./strategies/StrategyProxy.sol";
import {Storage} from "./Storage.sol";
import {Vault} from "./Vault.sol";
import {LimeProxy} from "./LimeProxy.sol";

/// @title Vault Deployer
/// @author Chainvisions
/// @notice A contract to handle vault deployments and configuration.

contract VaultDeployer {
    // Structure for a vault deployment
    struct Deployment {
        address vault;
        address strategy;
        address strategyImpl;
    }

    /// @notice Limestone token contract.
    address public immutable LIME_TOKEN;

    /// @notice Limestone's storage contract for transferring control over contracts.
    address public store;

    /// @notice Implementation contract to use for vault proxies.
    address public vaultImplementation;

    /// @notice Emitted on vault deployment.
    event VaultDeployment(address vault, address strategy, string vaultType);

    modifier onlyGovernance {
        require(Storage(store).isGovernance(msg.sender), "VaultDeployer: Caller not governance");
        _;
    }

    constructor(address _store, address _vaultImpl, address _limeToken) {
        LIME_TOKEN = _limeToken;
        store = _store;
        vaultImplementation = _vaultImpl;
    }
    
    /// @notice Deploys and configures a new vault contract.
    /// @param _underlying The underlying token that the vault accepts.
    /// @param _exitFee The exit fee charged by the vault on early withdrawal.
    /// @param _bytecode The bytecode of the vault's strategy contract implementation.
    /// @param _deployAsMaximizer Whether or not to deploy the vault as a maximizer.
    /// @return The deployed contracts that are part of the vault.
    function deployVault(
        address _underlying,
        uint256 _exitFee,
        bytes memory _bytecode,
        bool _deployAsMaximizer
    ) public returns (Deployment memory) {
        // Create a variable for the deployment metadata to return.
        Deployment memory deploymentData;

        // Deploy and initialize a new vault proxy.
        LimeProxy proxy = new LimeProxy(vaultImplementation);
        deploymentData.vault = address(proxy);
        Vault vaultProxy = Vault(address(proxy));
        vaultProxy.initializeVault(address(this), _underlying, 9999, _exitFee);

        // Deploy a new strategy contract.
        address strategyImpl = createDeploy(_bytecode);
        StrategyProxy strategyProxy = new StrategyProxy(strategyImpl);
        (bool initStatus, ) = address(strategyProxy).call(abi.encodeWithSignature("initializeStrategy(address,address)", address(this), address(proxy)));
        require(initStatus, "VaultDeployer: Strategy initialization failed");
        deploymentData.strategy = address(strategyProxy);
        deploymentData.strategyImpl = strategyImpl;

        vaultProxy.setStrategy(address(strategyProxy));

        // Handle vault configuration.
        vaultProxy.addRewardDistribution(address(strategyProxy));
        vaultProxy.addRewardToken(address(LIME_TOKEN), 900, true);
        if(_deployAsMaximizer) {
            // Fetch the reward token to add to the vault.
            (,bytes memory encodedReward) = address(strategyProxy).staticcall(abi.encodeWithSignature("targetVault()"));
            address vaultReward = abi.decode(encodedReward, (address));

            // Add the reward token to the vault with a reward duration of 1 hour.
            vaultProxy.addRewardToken(vaultReward, 900, false);
        }

        address _store = store;
        vaultProxy.setStorage(_store);
        (bool setSuccess, ) = address(strategyProxy).call(abi.encodeWithSignature("setStorage(address)", _store));
        require(setSuccess, "VaultDeployer: Storage set failed");

        emit VaultDeployment(address(proxy), address(strategyProxy), _deployAsMaximizer == false ? "autocompounding" : "maximizer");
        return deploymentData;
    }

    /// @notice Sets the storage contract address.
    /// @param _store Contract address to set `store` as.
    function setStorage(address _store) public onlyGovernance {
        store = _store;
    }

    /// @notice Sets the address of the vault implementation contract.
    /// @param _vaultImpl Address to set `vaultImplementation` as.
    function setVaultImplementation(
        address _vaultImpl
    ) public onlyGovernance {
        vaultImplementation = _vaultImpl;
    }

    function governance() public view returns (address) {
        return address(this);
    }

    function controller() public view returns (address) {
        return Storage(store).controller();
    }

    function isGovernance(address _account) public view returns (bool) {
        return (_account == governance());
    }

    function isController(address _account) public view returns (bool) {
        return (_account == controller());
    }

    function createDeploy(
        bytes memory _bytecode
    ) private returns (address) {
        address deployedContract;
        assembly {
            deployedContract := create(0, add(_bytecode, 0x20), mload(_bytecode))
            if iszero(extcodesize(deployedContract)) {
                revert(0, 0)
            }
        }

        return deployedContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUpgradeSource} from "../interfaces/IUpgradeSource.sol";
import {BaseUpgradeabilityProxy} from "../lib/BaseUpgradeabilityProxy.sol";

/// @title Limestone Strategy Proxy
/// @author Chainvisions
/// @notice Proxy for Limestone's strategy contracts.

contract StrategyProxy is BaseUpgradeabilityProxy {

    constructor(address _implementation) {
        _setImplementation(_implementation);
    }

    /**
    * The main logic. If the timer has elapsed and there is a schedule upgrade,
    * the governance can upgrade the strategy
    */
    function upgrade() external {
        (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
        require(should, "Strategy Proxy: Upgrade not scheduled");
        _upgradeTo(newImplementation);

        // The finalization needs to be executed on itself to update the storage of this proxy
        // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("finalizeUpgrade()")
        );

        require(success, "Strategy Proxy: Issue when finalizing the upgrade");
    }

    function implementation() external view returns (address) {
        return _implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IController} from "./interfaces/IController.sol";
import {IUpgradeSource} from "./interfaces/IUpgradeSource.sol";
import {VaultStorage} from "./VaultStorage.sol";
import {ControllableInit} from "./lib/ControllableInit.sol";
import {Errors, _require} from "./lib/Errors.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol";

/// @title Limestone Vault
/// @author Chainvisions
/// @notice Vault used for Limestone's yield optimization mechanisms.

contract Vault is ERC20Upgradeable, IUpgradeSource, ControllableInit, VaultStorage {
    using SafeMath for uint256;
    using SafeTransferLib for IERC20;
    using Address for address;

    /// @notice Implementation version of the vault contract.
    string public constant VERSION = "1.0.0";

    /// @notice Addresses permitted to inject rewards into the vault.
    mapping(address => bool) public rewardDistribution;

    /// @notice Reward tokens distributed by the vault.
    address[] public rewardTokens;

    /// @notice Reward duration for a specific reward token.
    mapping(address => uint256) public durationForToken;

    /// @notice Time when rewards for a specific reward token ends.
    mapping(address => uint256) public periodFinishForToken;

    /// @notice The amount of rewards distributed per second for a specific reward token.
    mapping(address => uint256) public rewardRateForToken;

    /// @notice The last time reward variables updated for a specific reward token.
    mapping(address => uint256) public lastUpdateTimeForToken;

    /// @notice Stored rewards per bToken for a specific reward token.
    mapping(address => uint256) public rewardPerTokenStoredForToken;

    /// @notice Whether or not a reward token is vested.
    mapping(address => bool) public tokenLockable;

    /// @notice The amount of rewards per bToken of a specific reward token paid to the user.
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;

    /// @notice The pending reward tokens for a user.
    mapping(address => mapping(address => uint256)) public rewardsForToken;
    
    /// @notice Timestamp of the user's last deposit.
    mapping(address => uint256) public lastDepositTimestamp;

    /// @notice Emitted when tokens are withdrawn from the vault.
    /// @param beneficiary User who withdrew tokens from the vault.
    /// @param amount Amount of tokens withdrawn from the vault.
    event Withdraw(address indexed beneficiary, uint256 amount);

    /// @notice Emitted when tokens are deposited into the vault.
    /// @param beneficiary User who deposited tokens into the vault.
    /// @param amount Amount of tokens deposited into the vault.
    event Deposit(address indexed beneficiary, uint256 amount);

    /// @notice Emitted when `underlying` is invested into the strategy.
    /// @param amount Amount of `underlying` invested into the strategy.
    event Invest(uint256 amount);

    /// @notice Emitted when a strategy switch is announced.
    /// @param newStrategy New strategy to switch to.
    /// @param time Time when the strategy switch is applicable.
    event StrategyAnnounced(address newStrategy, uint256 time);

    /// @notice Emitted when the vault's strategy is changed.
    /// @param newStrategy New strategy for the vault.
    /// @param oldStrategy Old strategy on the vault.
    event StrategyChanged(address newStrategy, address oldStrategy);

    /// @notice Emitted when a vault upgrade is announced.
    /// @param newImplementation New implementation for the vault.
    event UpgradeAnnounced(address newImplementation);

    /// @notice Emitted when a change in the vault early exit fee is queued.
    /// @param newFee New early exit fee on the vault.
    /// @param time Time when the exit fee change can be finalized.
    event ExitFeeChangeQueued(uint256 newFee, uint256 time);

    /// @notice Emitted when the vault early exit fee is changed.
    /// @param newFee New early exit fee on the vault.
    /// @param oldFee Old early exit fee on the vault.
    event ExitFeeChange(uint256 newFee, uint256 oldFee);

    /// @notice Emitted when rewards are paid out to a vault user.
    /// @param user User that the rewards are paid out to.
    /// @param rewardToken Reward token paid out to the user.
    /// @param amount Amount of `rewardToken` paid out to the user.
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 amount);

    /// @notice Emitted when rewards are injected into the vault.
    /// @param rewardToken Reward token injected into the vault.
    /// @param rewardAmount Amount of `rewardToken` injected.
    event RewardInjection(address indexed rewardToken, uint256 rewardAmount);

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _exitFee
    ) external initializer {
        _require(_toInvestNumerator <= 10000, Errors.NUMERATOR_ABOVE_MAX_BUFFER);

        __ERC20_init(
            string(abi.encodePacked("Limestone ", ERC20Upgradeable(_underlying).symbol())),
            string(abi.encodePacked("li", ERC20Upgradeable(_underlying).symbol()))
        );
        __Controllable_init(_storage);

        uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(_underlying).decimals());
        __VaultStorage_init(
            _underlying,
            _toInvestNumerator,
            underlyingUnit,
            12 hours,
            8 hours,
            _exitFee
        );
    }

    /// @notice Prevents a function from executing if no strategy is present.
    modifier whenStrategyDefined {
        _require(strategy() != address(0), Errors.UNDEFINED_STRATEGY);
        _;
    }

    /// @notice Prevents smart contracts from interacting if they are not whitelisted.
    /// This system is part of our security model as a method of preventing flashloan exploits.
    modifier defense {
        _require(
            msg.sender == tx.origin ||
            IController(controller()).whitelist(msg.sender),
            Errors.CALLER_NOT_WHITELISTED
        );
        _;
    }

    /// @notice Deposits `underlying` into the vault and mints shares to the user.
    /// @param _amount Amount of `underlying` to deposit into the vault.
    function deposit(uint256 _amount) external override {
        _deposit(_amount, msg.sender, msg.sender);
    }

    /// @notice Standard deposit function but with referral support.
    /// @param _amount Amount of `underlying` to deposit into the vault.
    /// @param _code Referral code for LIME points.
    function deposit(uint256 _amount, string memory _code) external {
        IController _controller = IController(controller());
        (address referrer, ) = _controller.referralInfo(msg.sender);
        if(referrer == address(0)) {
            _controller.registerReferral(_code, msg.sender);
        }
        _deposit(_amount, msg.sender, msg.sender);
    }

    /// @notice Deposits `underlying` for address `_for`. This is for whitelisted only
    /// as to avoid dusting attacks on vault depositor to siphon exit penalties.
    function depositFor(address _for, uint256 _amount) external override {
        _require(IController(controller()).whitelist(msg.sender), Errors.CALLER_NOT_WHITELISTED);
        _deposit(_amount, msg.sender, _for);
    }

    /// @notice Withdraws `underlying` from the vault.
    /// @param _numberOfShares Shares to burn for `underlying`.
    function withdraw(uint256 _numberOfShares) external override defense {
        _updateRewards(msg.sender);
        _require(totalSupply() > 0, Errors.VAULT_HAS_NO_SHARES);
        _require(_numberOfShares > 0, Errors.SHARES_MUST_NOT_BE_ZERO);
        uint256 supplySnapshot = totalSupply();
        _burn(msg.sender, _numberOfShares);

        uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
            .mul(_numberOfShares)
            .div(supplySnapshot);
        if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
            // Withdraw everything from the strategy to accurately check the share value.
            if (_numberOfShares == supplySnapshot) {
                IStrategy(strategy()).withdrawAllToVault();
            } else {
                uint256 missing = (underlyingAmountToWithdraw - underlyingBalanceInVault());
                IStrategy(strategy()).withdrawToVault(missing);
            }
            // Recalculate to improve accuracy.
            underlyingAmountToWithdraw = Math.min(underlyingBalanceWithInvestment()
                .mul(_numberOfShares)
                .div(supplySnapshot), underlyingBalanceInVault());
        }

        // Check if the user can exit without a penalty and if not, charge the exit penalty.
        IERC20 _underlying = IERC20(underlying());
        if(
            exitFee() > 0 
            && lastDepositTimestamp[msg.sender] + depositMaturityTime() > block.timestamp
            && !IController(controller()).feeExemptAddresses(msg.sender)
        ) {
            // Calculate fee.
            uint256 feeFromUnderlying = (underlyingAmountToWithdraw * exitFee()) / 10000;

            // Calculate split.
            uint256 protocolFee = feeFromUnderlying / 2;
            uint256 depositorFee = totalSupply() != 0   // We need to determine the fee by if there are existing depositors post-withdrawal.
                ? protocolFee                           // This is to ensure dust is not left-over in the vault afterwards.
                : 0;

            // Perform split.
            if(depositorFee > 0) {
                // If deposits exist post-withdrawal, collect protocol fees + reward existing deposits.
                _underlying.safeTransfer(controller(), protocolFee);
                _underlying.safeTransfer(msg.sender, (underlyingAmountToWithdraw - feeFromUnderlying));
            } else {
                // Else, no other depositors exist and the protocol gets the full fee.
                _underlying.safeTransfer(controller(), feeFromUnderlying);
                _underlying.safeTransfer(msg.sender, (underlyingAmountToWithdraw - feeFromUnderlying));
            }
        } else {
            _underlying.safeTransfer(msg.sender, underlyingAmountToWithdraw);
        }

        // Update the withdrawal amount for the holder.
        emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    /// @notice Collects all earned rewards from the vault for the user.
    function getReward() external override defense {
        _updateRewards(msg.sender);
        for(uint256 i; i < rewardTokens.length;) {
            _getReward(rewardTokens[i]);
            unchecked { ++i; }
        }
    }

    /// @notice Collects the user's rewards of the specified reward token.
    /// @param _rewardToken Reward token to claim.
    function getRewardByToken(
        address _rewardToken
    ) external override defense {
        _updateReward(msg.sender, _rewardToken);
        _getReward(_rewardToken);
    }

    /// @notice Invests `underlying` into the strategy to generate yields for the vault.
    function doHardWork() external override whenStrategyDefined onlyControllerOrGovernance {
        _invest();
        IStrategy(strategy()).doHardWork();
    }

    /// @notice Function used for rebalancing on the strategy.
    function rebalance() external override onlyControllerOrGovernance {
        withdrawAll();
        _invest();
    }

    /// @notice Finalizes or cancels upgrades by setting the next implementation address to 0.
    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    /// @notice Determines if the vault can be upgraded.
    /// @return If the vault can be upgraded and the new implementation address.
    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Gets the total value of the user's shares.
    /// @param _holder Address of the user.
    /// @return The user's shares in `underlying`.
    function underlyingBalanceWithInvestmentForHolder(address _holder) external view override returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (underlyingBalanceWithInvestment() * balanceOf(_holder)) / totalSupply();
    }

    /// @notice Schedules an upgrade to the vault.
    /// @param _impl Address of the new implementation.
    function scheduleUpgrade(address _impl) public onlyControllerOrGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + timelockDelay());
        emit UpgradeAnnounced(_impl);
    }

    /// @notice Queues a strategy switch on the vault.
    /// @param _strategy Address of the strategy.
    function announceStrategyUpdate(address _strategy) public onlyControllerOrGovernance {
        // Records a new timestamp
        uint256 when = (block.timestamp + timelockDelay());
        _setStrategyUpdateTime(when);
        _setFutureStrategy(_strategy);
        emit StrategyAnnounced(_strategy, when);
    }

    /// @notice Finalizes or cancels strategy updates, sets the pending strategy to 0.
    function finalizeStrategyUpdate() public onlyControllerOrGovernance {
        _setStrategyUpdateTime(0);
        _setFutureStrategy(address(0));
    }

    /// @notice Updates the current strategy address, the vault's timelock applies if the current strategy address is not 0x00.
    /// @param _strategy Address of the new strategy.
    function setStrategy(address _strategy) public override onlyControllerOrGovernance {
        _require(canUpdateStrategy(_strategy), Errors.CANNOT_UPDATE_STRATEGY);
        _require(_strategy != address(0), Errors.NEW_STRATEGY_CANNOT_BE_EMPTY);
        _require(IStrategy(_strategy).underlying() == underlying(), Errors.VAULT_AND_STRATEGY_UNDERLYING_MUST_MATCH);
        _require(IStrategy(_strategy).vault() == address(this), Errors.STRATEGY_DOES_NOT_BELONG_TO_VAULT);

        emit StrategyChanged(_strategy, strategy());
        rewardDistribution[_strategy] = true;
        if(_strategy != strategy()) {
            if(strategy() != address(0)) {
                IStrategy(strategy()).withdrawAllToVault();
            }
            _setStrategy(_strategy);
        }
        finalizeStrategyUpdate();
    }

    /// @notice Withdraws all tokens from the strategy to the vault.
    function withdrawAll() public override onlyControllerOrGovernance whenStrategyDefined {
        IStrategy(strategy()).withdrawAllToVault();
    }

    /// @notice Injects rewards into the vault.
    /// @param _rewardToken Token to reward, must be in the rewardTokens array.
    /// @param _amount Amount of `_rewardToken` to inject.
    function notifyRewardAmount(
        address _rewardToken,
        uint256 _amount
    ) public override {
        _updateRewards(address(0));
        _require(
            msg.sender == governance() 
            || rewardDistribution[msg.sender], 
            Errors.CALLER_NOT_GOV_OR_REWARD_DIST
        );

        _require(_amount < type(uint256).max / 1e18, Errors.NOTIF_AMOUNT_INVOKES_OVERFLOW);

        uint256 i = rewardTokenIndex(_rewardToken);
        _require(i != type(uint256).max, Errors.REWARD_INDICE_NOT_FOUND);

        if (block.timestamp >= periodFinishForToken[_rewardToken]) {
            rewardRateForToken[_rewardToken] = _amount / durationForToken[_rewardToken];
        } else {
            uint256 remaining = periodFinishForToken[_rewardToken] - block.timestamp;
            uint256 leftover = (remaining * rewardRateForToken[_rewardToken]);
            rewardRateForToken[_rewardToken] = (_amount + leftover) / durationForToken[_rewardToken];
        }
        lastUpdateTimeForToken[_rewardToken] = block.timestamp;
        periodFinishForToken[_rewardToken] = block.timestamp + durationForToken[_rewardToken];
    }

    /// @notice Gives the specified address the ability to inject rewards.
    /// @param _rewardDistribution Address to get reward distribution privileges 
    function addRewardDistribution(address _rewardDistribution) public onlyGovernance {
        rewardDistribution[_rewardDistribution] = true;
    }

    /// @notice Removes the specified address' ability to inject rewards.
    /// @param _rewardDistribution Address to lose reward distribution privileges
    function removeRewardDistribution(address _rewardDistribution) public onlyGovernance {
        rewardDistribution[_rewardDistribution] = false;
    }

    /// @notice Adds a reward token to the vault.
    /// @param _rewardToken Reward token to add.
    /// @param _duration Duration for distributing the token.
    /// @param _lockable Whether or not it should be locked when claimed.
    function addRewardToken(address _rewardToken, uint256 _duration, bool _lockable) public onlyGovernance {
        _require(rewardTokenIndex(_rewardToken) == type(uint256).max, Errors.REWARD_TOKEN_ALREADY_EXIST);
        _require(_duration > 0, Errors.DURATION_CANNOT_BE_ZERO);
        rewardTokens.push(_rewardToken);
        durationForToken[_rewardToken] = _duration;
        tokenLockable[_rewardToken] = _lockable;
    }

    /// @notice Removes a reward token from the vault.
    /// @param _rewardToken Reward token to remove from the vault.
    function removeRewardToken(address _rewardToken) public onlyGovernance {
        uint256 rewardIndex = rewardTokenIndex(_rewardToken);

        _require(rewardIndex != type(uint256).max, Errors.REWARD_TOKEN_DOES_NOT_EXIST);
        _require(periodFinishForToken[_rewardToken] < block.timestamp, Errors.REWARD_PERIOD_HAS_NOT_ENDED);
        _require(rewardTokens.length > 1, Errors.CANNOT_REMOVE_LAST_REWARD_TOKEN);
        uint256 lastIndex = rewardTokens.length - 1;

        rewardTokens[rewardIndex] = rewardTokens[lastIndex];

        rewardTokens.pop();
    }

    /// @notice Sets the vault's buffer.
    /// @param _numerator New buffer for the vault, precision 1000.
    function setVaultFractionToInvest(uint256 _numerator) public override onlyGovernance {
        _require(_numerator <= 10000, Errors.DENOMINATOR_MUST_BE_GTE_NUMERATOR);
        _setFractionToInvestNumerator(_numerator);
    }

    /// @notice Sets the reward distribution duration for `_rewardToken`.
    /// @param _rewardToken Reward token to set the duration of.
    function setDurationForToken(address _rewardToken, uint256 _duration) public onlyGovernance {
        uint256 i = rewardTokenIndex(_rewardToken);
        _require(i != type(uint256).max, Errors.REWARD_TOKEN_DOES_NOT_EXIST);
        _require(periodFinishForToken[_rewardToken] < block.timestamp, Errors.REWARD_PERIOD_HAS_NOT_ENDED);
        _require(_duration > 0, Errors.DURATION_CANNOT_BE_ZERO);
        durationForToken[_rewardToken] = _duration;
    }

    /// @notice Queues an update to the exit fee.
    /// @param _newExitFee New exit fee for the vault.
    function queueExitFeeChange(uint256 _newExitFee) public onlyGovernance {
        _setNextExitFee(_newExitFee);
        _setNextExitFeeTimestamp(block.timestamp + timelockDelay());
    }

    /// @notice Finalizes or cancels the exit fee change by setting the new fee to 0.
    function finalizeExitFeeChange() public onlyGovernance {
        _setNextExitFee(0);
        _setNextExitFeeTimestamp(0);
    }

    /// @notice Sets the exit fee of the vault. Should be called once `timelockDelay()` is over.
    /// @param _exitFee New exit fee, should be `nextExitFee()`
    function setExitFee(uint256 _exitFee) public onlyGovernance {
        _require(canUpdateExitFee(_exitFee), Errors.CANNOT_UPDATE_EXIT_FEE);
        uint256 oldFee = exitFee();
        _setExitFee(_exitFee);
        finalizeExitFeeChange();
        emit ExitFeeChange(_exitFee, oldFee);
    }

    function canUpdateExitFee(uint256 _exitFee) public view returns (bool) {
        return exitFee() == 0
            || (_exitFee == nextExitFee()
                && block.timestamp > nextExitFeeTimestamp()
                && nextExitFeeTimestamp() > 0);
    }

    /// @notice Returns the amount of `underlying` in the vault.
    /// @return How much `underlying` held in the vault itself.
    function underlyingBalanceInVault() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @notice The amount of tokens invested and held by the vault.
    /// @return The underlying held by the vault and strategy.
    function underlyingBalanceWithInvestment() public view override returns (uint256) {
        if (strategy() == address(0)) {
            // Initial state, when not set.
            return underlyingBalanceInVault();
        }
        return (underlyingBalanceInVault() + IStrategy(strategy()).investedUnderlyingBalance());
    }

    /// @notice Returns the price of 1 share in the vault.
    /// @return The vault share price.
    function getPricePerFullShare() public view override returns (uint256) {
        return totalSupply() == 0
            ? underlyingUnit()
            : (underlyingUnit() * underlyingBalanceWithInvestment()) / totalSupply();
    }

    /// @notice Returns the amount of decimals of the vault share token.
    /// @return The decimals of the share token, based on the decimals of the underlying token.
    function decimals() public view override returns (uint8) {
        return ERC20Upgradeable(underlying()).decimals();
    }

    /// @notice Determines if the strategy can be updated.
    /// @return Whether or not the strategy can be updated.
    function canUpdateStrategy(address _strategy) public view returns (bool) {
        return strategy() == address(0) // No strategy was set yet
        || (_strategy == futureStrategy()
            && block.timestamp > strategyUpdateTime()
            && strategyUpdateTime() > 0); // or the timelock has passed
    }

    /// @notice The amount available for investing into the strategy
    /// @return The amount that can be invested.
    function availableToInvestOut() public view returns (uint256) {
        uint256 wantInvestInTotal = (underlyingBalanceWithInvestment() * fractionToInvestNumerator()) / 10000;
        uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
        if (alreadyInvested >= wantInvestInTotal) {
            return 0;
        } else {
            uint256 remainingToInvest = (wantInvestInTotal - alreadyInvested);
            // wantInvestInTotal - alreadyInvested
            return remainingToInvest <= underlyingBalanceInVault()
                ? remainingToInvest : underlyingBalanceInVault();
        }
    }

    /// @notice Gets the index of `_rewardToken` in the `rewardTokens` array.
    /// @param _rewardToken Reward token to get the index of.
    /// @return The index of the reward token, it will return the max uint256 if it does not exist.
    function rewardTokenIndex(address _rewardToken) public view returns (uint256) {
        for(uint256 i; i < rewardTokens.length;) {
            if(rewardTokens[i] == _rewardToken) {
                return i;
            }
            unchecked { ++i; }
        }
        return type(uint256).max;
    } 

    /// @notice Calculates the last time rewards were applicable for a specific token.
    /// @param _rewardToken Reward token to calculate the time of.
    /// @return The last time rewards were applicable for `_rewardToken`.
    function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishForToken[_rewardToken]);
    }

    /// @notice Gets the amount of rewards per bToken for a specified reward token.
    /// @param _rewardToken Reward token to get the amount of rewards for.
    /// @return Amount of `_rewardToken` per bToken.
    function rewardPerToken(address _rewardToken) public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredForToken[_rewardToken];
        }
        return
            rewardPerTokenStoredForToken[_rewardToken].add(
                lastTimeRewardApplicable(_rewardToken)
                    .sub(lastUpdateTimeForToken[_rewardToken])
                    .mul(rewardRateForToken[_rewardToken])
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    /// @notice Gets the user's earnings by reward token address.
    /// @param _rewardToken Reward token to get earnings from.
    /// @param _account Address to get the earnings of.
    function earned(address _rewardToken, address _account) public view returns (uint256) {
        return
            ((balanceOf(_account)
                * (rewardPerToken(_rewardToken) - userRewardPerTokenPaidForToken[_rewardToken][_account]))
                 / 1e18)
                + rewardsForToken[_rewardToken][_account];
    }

    /// @notice Returns an array of all reward tokens on the vault.
    /// @return The vault's reward tokens in the form of an array.
    function vaultRewards() public view returns (address[] memory) {
        return (rewardTokens);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        _amount;
        if(
            _from != address(0) &&
            _to != address(0) &&
            !IController(controller()).feeExemptAddresses(_from)
        ) {
            // Prevents loophole from transferring bTokens to another
            // address to avoid the exit penalty.
            _require(
                block.timestamp >= lastDepositTimestamp[_from] + depositMaturityTime(),
                Errors.CANNOT_TRANSFER_IMMATURE_TOKENS
            );

            // Update rewards for the sender and recipient.
            _updateRewards(_from);
            _updateRewards(_to);

            // Boring....
            super._beforeTokenTransfer(_from, _to, _amount);
        }
    }

    function _invest() internal whenStrategyDefined {
        uint256 availableAmount = availableToInvestOut();
        if (availableAmount > 0) {
            IERC20(underlying()).safeTransfer(strategy(), availableAmount);
            emit Invest(availableAmount);
        }
    }

    function _deposit(uint256 _amount, address _sender, address _beneficiary) internal defense {
        _updateRewards(_beneficiary);
        _require(_amount > 0, Errors.CANNOT_DEPOSIT_ZERO);
        _require(_beneficiary != address(0), Errors.HOLDER_MUST_BE_DEFINED);

        uint256 toMint = totalSupply() == 0
            ? _amount
            : (_amount * totalSupply()) / underlyingBalanceWithInvestment();
        _mint(_beneficiary, toMint);

        lastDepositTimestamp[_beneficiary] = block.timestamp;

        IERC20(underlying()).safeTransferFrom(_sender, address(this), _amount);

        // Update the contribution amount for the beneficiary
        emit Deposit(_beneficiary, _amount);
    }

    function _updateRewards(address _account) internal {
        for(uint256 i; i < rewardTokens.length;) {
            address rewardToken = rewardTokens[i];
            rewardPerTokenStoredForToken[rewardToken] = rewardPerToken(rewardToken);
            lastUpdateTimeForToken[rewardToken] = lastTimeRewardApplicable(rewardToken);
            if (_account != address(0)) {
                rewardsForToken[rewardToken][_account] = earned(rewardToken, _account);
                userRewardPerTokenPaidForToken[rewardToken][_account] = rewardPerTokenStoredForToken[rewardToken];
            }
            unchecked { ++i; }
        }
    }

    function _updateReward(address _account, address _rewardToken) internal {
        rewardPerTokenStoredForToken[_rewardToken] = rewardPerToken(_rewardToken);
        lastUpdateTimeForToken[_rewardToken] = lastTimeRewardApplicable(_rewardToken);
        if (_account != address(0)) {
            rewardsForToken[_rewardToken][_account] = earned(_rewardToken, _account);
            userRewardPerTokenPaidForToken[_rewardToken][_account] = rewardPerTokenStoredForToken[_rewardToken];
        }
    }

    function _getReward(address _rewardToken) internal {
        uint256 rewards = earned(_rewardToken, msg.sender);
        if(rewards > 0) {
            rewardsForToken[_rewardToken][msg.sender] = 0;
            if(tokenLockable[_rewardToken]) {
                IController(controller()).mintTokens(msg.sender, rewards);
            } else {
                IERC20(_rewardToken).safeTransfer(msg.sender, rewards);
            }
            emit RewardPaid(msg.sender, _rewardToken, rewards);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUpgradeSource} from "./interfaces/IUpgradeSource.sol";
import {BaseUpgradeabilityProxy} from "./lib/BaseUpgradeabilityProxy.sol";

/// @title Limestone Proxy
/// @author Chainvisions
/// @notice Proxy for Limestone's contracts.

contract LimeProxy is BaseUpgradeabilityProxy {

    constructor(address _implementation) {
        _setImplementation(_implementation);
    }

    /**
    * The main logic. If the timer has elapsed and there is a schedule upgrade,
    * the governance can upgrade the contract
    */
    function upgrade() external {
        (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
        require(should, "Lime Proxy: Upgrade not scheduled");
        _upgradeTo(newImplementation);

        // The finalization needs to be executed on itself to update the storage of this proxy
        // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("finalizeUpgrade()")
        );

        require(success, "Lime Proxy: Issue when finalizing the upgrade");
    }

    function implementation() external view returns (address) {
        return _implementation();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUpgradeSource {
  function finalizeUpgrade() external;
  function shouldUpgrade() external view returns (bool, address);
}

// SPDX-License-Identifier: MIT
// COPIED AND MODIFIED FROM: @openzeppelin/upgrades.
pragma solidity ^0.8.0;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    impl = StorageSlot.getAddressSlot(slot).value;
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    StorageSlot.getAddressSlot(slot).value = newImplementation;
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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
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
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
        uint256 amount
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
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()
    function pendingYield() external view returns (uint256[] memory);

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;
    function depositFor(address, uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function underlyingUnit() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) external view returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ILimePoints} from "./ILimePoints.sol"; 

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function keepers(address) external view returns (bool);
    function referralCode(string memory) external view returns (address);
    function referrer(address) external view returns (address);
    function referralInfo(address) external view returns (address, string memory);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function mintTokens(address, uint256) external;
    function createReferralCode(string memory) external;
    function registerReferral(string memory, address) external;

    function limeToken() external view returns (ILimePoints);
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVault} from "./interfaces/IVault.sol";

/// @title Vault Storage
/// @author Chainvisions
/// @notice Contract that handles storage for primitive types in the Vault contract.

abstract contract VaultStorage is Initializable, IVault {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function __VaultStorage_init(
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _underlyingUnit,
        uint256 _timelockDelay,
        uint256 _depositMaturityTime,
        uint256 _exitFee
    ) internal initializer {
        _setUnderlying(_underlying);
        _setFractionToInvestNumerator(_toInvestNumerator);
        _setUnderlyingUnit(_underlyingUnit);
        _setTimelockDelay(_timelockDelay);
        _setDepositMaturityTime(_depositMaturityTime);
        _setExitFee(_exitFee);
    }

    /// @dev Strategy used for yield optimization.
    function strategy() public view override returns (address) {
        return _getAddress("strategy");
    }

    /// @dev Underlying token of the vault.
    function underlying() public view override returns (address) {
        return _getAddress("underlying");
    }

    /// @dev Unit of the underlying token.
    function underlyingUnit() public view override returns (uint256) {
        return _getUint256("underlyingUnit");
    }

    /// @dev Buffer for investing.
    function fractionToInvestNumerator() public view returns (uint256) {
        return _getUint256("fractionToInvestNumerator");
    }

    /// @dev Next implementation contract for the proxy.
    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    /// @dev Timestamp of when the next upgrade can be executed.
    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    /// @dev Timelock delay for strategy switches and upgrades.
    function timelockDelay() public view returns (uint256) {
        return _getUint256("timelockDelay");
    }

    /// @dev Next strategy contract for the vault.
    function futureStrategy() public view returns (address) {
        return _getAddress("futureStrategy");
    }

    /// @dev Timestamp of when the strategy switch can be executed.
    function strategyUpdateTime() public view returns (uint256) {
        return _getUint256("strategyUpdateTime");
    }

    /// @dev Minimum time since deposit to be able to exit without
    /// an exit penalty.
    function depositMaturityTime() public view returns (uint256) {
        return _getUint256("depositMaturityTime");
    }

    /// @dev Fee charged on exit if exiting the vault before
    /// the user's bTokens have matured.
    function exitFee() public view returns (uint256) {
        return _getUint256("exitFee");
    }

    /// @dev New exit fee after the timelock goes through.
    function nextExitFee() public view returns (uint256) {
        return _getUint256("nextExitFee");
    }

    /// @dev When the exit fee change can be finalized.
    function nextExitFeeTimestamp() internal view returns (uint256) {
        return _getUint256("nextExitFeeTimestamp");
    }

    function _setStrategy(address _address) internal {
        _setAddress("strategy", _address);
    }

    function _setUnderlying(address _address) internal {
        _setAddress("underlying", _address);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        _setUint256("underlyingUnit", _value);
    }

    function _setFractionToInvestNumerator(uint256 _value) internal {
        _setUint256("fractionToInvestNumerator", _value);
    }

    function _setNextImplementation(address _address) internal {
        _setAddress("nextImplementation", _address);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setTimelockDelay(uint256 _value) internal {
        _setUint256("timelockDelay", _value);
    }

    function _setFutureStrategy(address _address) internal {
        _setAddress("futureStrategy", _address);
    }

    function _setStrategyUpdateTime(uint256 _value) internal {
        _setUint256("strategyUpdateTime", _value);
    }

    function _setDepositMaturityTime(uint256 _value) internal {
        _setUint256("depositMaturityTime", _value);
    }

    function _setExitFee(uint256 _value) internal {
        _setUint256("exitFee", _value);
    }

    function _setNextExitFee(uint256 _value) internal {
        _setUint256("nextExitFee", _value);
    }

    function _setNextExitFeeTimestamp(uint256 _value) internal {
        _setUint256("nextExitFeeTimestamp", _value);
    }

    function _setUint256(string memory _key, uint256 _value) private {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) private view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _setAddress(string memory _key, address _value) private {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getAddress(string memory _key) private view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _setBool(string memory _key, bool _value) private {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getBool(string memory _key) private view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {GovernableInit, Storage} from "./GovernableInit.sol";

contract ControllableInit is GovernableInit {

  constructor() {}

  function __Controllable_init(address _storage) public initializer {
    __Governable_init_(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Controllable: Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "Controllable: The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BEL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BEL#" part is a known constant
        // (0x42454C23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42454C23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}


/// @title Beluga Errors Library
/// @author Chainvisions
/// @author Forked and modified from Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/helpers/BalancerErrors.sol)
/// @notice Library for efficiently handling errors on Beluga contracts with reduced bytecode size additions.

library Errors {
    // Vault
    uint256 internal constant NUMERATOR_ABOVE_MAX_BUFFER = 0;
    uint256 internal constant UNDEFINED_STRATEGY = 1;
    uint256 internal constant CALLER_NOT_WHITELISTED = 2;
    uint256 internal constant VAULT_HAS_NO_SHARES = 3;
    uint256 internal constant SHARES_MUST_NOT_BE_ZERO = 4;
    uint256 internal constant LOSSES_ON_DOHARDWORK = 5;
    uint256 internal constant CANNOT_UPDATE_STRATEGY = 6;
    uint256 internal constant NEW_STRATEGY_CANNOT_BE_EMPTY = 7;
    uint256 internal constant VAULT_AND_STRATEGY_UNDERLYING_MUST_MATCH = 8;
    uint256 internal constant STRATEGY_DOES_NOT_BELONG_TO_VAULT = 9;
    uint256 internal constant CALLER_NOT_GOV_OR_REWARD_DIST = 10;
    uint256 internal constant NOTIF_AMOUNT_INVOKES_OVERFLOW = 11;
    uint256 internal constant REWARD_INDICE_NOT_FOUND = 12;
    uint256 internal constant REWARD_TOKEN_ALREADY_EXIST = 13;
    uint256 internal constant DURATION_CANNOT_BE_ZERO = 14;
    uint256 internal constant REWARD_TOKEN_DOES_NOT_EXIST = 15;
    uint256 internal constant REWARD_PERIOD_HAS_NOT_ENDED = 16;
    uint256 internal constant CANNOT_REMOVE_LAST_REWARD_TOKEN = 17;
    uint256 internal constant DENOMINATOR_MUST_BE_GTE_NUMERATOR = 18;
    uint256 internal constant CANNOT_UPDATE_EXIT_FEE = 19;
    uint256 internal constant CANNOT_TRANSFER_IMMATURE_TOKENS = 20;
    uint256 internal constant CANNOT_DEPOSIT_ZERO = 21;
    uint256 internal constant HOLDER_MUST_BE_DEFINED = 22;

    // VeManager
    uint256 internal constant GOVERNORS_ONLY = 23;
    uint256 internal constant CALLER_NOT_STRATEGY = 24;
    uint256 internal constant GAUGE_INFO_ALREADY_EXISTS = 25;
    uint256 internal constant GAUGE_NON_EXISTENT = 26;

    // Strategies
    uint256 internal constant CALL_RESTRICTED = 27;
    uint256 internal constant STRATEGY_IN_EMERGENCY_STATE = 28;
    uint256 internal constant REWARD_POOL_UNDERLYING_MISMATCH = 29;
    uint256 internal constant UNSALVAGABLE_TOKEN = 30;

    // Strategy splitter.
    uint256 internal constant ARRAY_LENGTHS_DO_NOT_MATCH = 31;
    uint256 internal constant WEIGHTS_DO_NOT_ADD_UP = 32;
    uint256 internal constant REBALANCE_REQUIRED = 33;
    uint256 internal constant INDICE_DOES_NOT_EXIST = 34;

    // Controller
    uint256 internal constant CALLER_NOT_REFEREE = 35;
    uint256 internal constant REFERRAL_CODE_ALREADY_EXISTS = 36;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILimePoints {
    function mint(address, uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Storage} from "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

    bytes32 internal constant STORAGE_SLOT =
        keccak256('limestone.contracts.storage.lib.Governable');

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}