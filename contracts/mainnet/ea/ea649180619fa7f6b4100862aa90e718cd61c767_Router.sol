// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2024 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.20;

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IUnderlyingVault} from "src/interfaces/vaults/IUnderlyingVault.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {IWhitelistController} from "src/interfaces/IWhitelistController.sol";
import {IRouterV1} from "src/interfaces/glp/IRouterV1.sol";
import {ITrackerV1} from "src/interfaces/glp/ITrackerV1.sol";
import {IWhitelistControllerV1} from "src/interfaces/glp/IWhitelistControllerV1.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract Router is IRouter, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using FixedPointMathLib for uint256;

    ///@notice Stack too deep
    struct WithdrawVars {
        uint256 assets;
        uint256 shares;
        uint256 strategyRetention;
        uint256 withdrawRetention;
        IWhitelistController.RoleInfo roleInfo;
        address thisAddress;
        uint256 usdcBalance;
        uint256 toWithdraw;
        uint256 retention;
        uint256 toUser;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    address private constant gov = 0xc8ce0aC725f914dBf1D743D51B6e222b79F479f1;

    /// @notice User roles and whitelisted contracts
    IWhitelistController public whitelistController;

    /// @notice ERC4626 Vault
    IUnderlyingVault public underlyingVault;

    /// @notice Socket address
    address public socket;

    /// @notice USDC Contract
    IERC20 private USDC;

    /// @notice User => Request (Recorded user action data)
    mapping(address => Request) public withdrawRequests;

    /// @notice User => target epoch => bool (True if user redemeed old withdraw request)
    mapping(address => mapping(uint256 => bool)) public redemeed;
    /// @notice User => bool (True if user mifrated old uncompound position)
    mapping(address => bool) public migrated;

    /// @notice total withdraw requests
    uint256 public totalWithdrawRequests;

    /// @notice Old Contracts to allow migration
    IRouterV1 public routerV1;
    ITrackerV1 public trackerV1;
    IWhitelistControllerV1 public controllerV1;
    IERC20 private OLD_jUSDC;
    uint256 public regularRatio;

    /// @notice Incentives
    address public incentiveReceiver;
    uint256 public withdrawCooldown;

    uint256 public constant BASIS_POINTS = 1e12;

    /* -------------------------------------------------------------------------- */
    /*                                 INITIALIZE                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address _routerV1,
        address _trackerV1,
        address _controllerV1,
        address _whitelistController,
        address _underlyingVault,
        address _incentiveReceiver,
        uint256 _compoundUVRT,
        uint256 _unCompoundUVRT,
        uint256 _jusdc
    ) external initializer {
        if (msg.sender != gov) {
            revert NotRightCaller();
        }

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        routerV1 = IRouterV1(_routerV1);
        trackerV1 = ITrackerV1(_trackerV1);
        controllerV1 = IWhitelistControllerV1(_controllerV1);

        whitelistController = IWhitelistController(_whitelistController);
        underlyingVault = IUnderlyingVault(_underlyingVault);
        socket = 0x88616cB9499F32Ff6A784B66B60aABF0bCf0df39;

        incentiveReceiver = _incentiveReceiver;

        withdrawCooldown = 2 weeks;

        USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        OLD_jUSDC = IERC20(0xe66998533a1992ecE9eA99cDf47686F4fc8458E0);

        _initializeMigration(_compoundUVRT, _unCompoundUVRT, _jusdc);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EXTERNAL                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Mints Vault shares to receiver by depositing underlying tokens.
     * @param _assets The amount of assets to deposit.
     * @param _receiver The address who will receive the shares.
     * @return shares The amount that were minted and received.
     */
    function deposit(uint256 _assets, address _receiver) external nonReentrant whenNotPaused returns (uint256) {
        _onlyEOA();

        if (_assets == 0) {
            revert ZeroAmount();
        }

        /// @notice Calculate Shares
        uint256 shares = underlyingVault.previewDeposit(_assets);

        /// @notice transfer USDC to Underlying Vault
        USDC.transferFrom(msg.sender, address(underlyingVault), _assets);

        /// @notice mint jUSDC
        underlyingVault.mint(shares, _receiver);

        emit Deposit(msg.sender, _assets, _receiver, shares);

        return shares;
    }

    /**
     * @notice Mints Vault shares to receiver by receiving underlying tokens comming from other chains.
     * @param _receiver The address who will receive the shares.
     * @return shares The amount that were minted and received.
     */
    function multichainDeposit(address _receiver) external nonReentrant whenNotPaused returns (uint256) {
        uint256 amount = USDC.allowance(msg.sender, address(this));

        if (amount == 0) {
            return 0;
        }

        if (!_onlySocket()) {
            USDC.transferFrom(msg.sender, _receiver, amount);
            return 0;
        }

        /// @notice Calculate Shares
        uint256 shares = underlyingVault.previewDeposit(amount);

        /// @notice transfer USDC to Underlying Vault
        USDC.transferFrom(msg.sender, address(underlyingVault), amount);

        /// @notice mint UVRT
        underlyingVault.mint(shares, _receiver);

        emit Deposit(msg.sender, amount, _receiver, shares);

        return shares;
    }

    /**
     * @notice Requests to withdraw the given amount of shares from the message sender's balance.
     * The withdrawal request will be added to the total amount of withdrawal requests, and will be
     * added to the user's total withdrawal requests.
     *
     * @param _shares The amount of shares to withdraw.
     * @param _receiver The address that will receive the assets.
     * @param _minAmountOut Min Amount that should be received.
     * @param _enforceData The data needed to enforce payback.
     * @return true if msg.sender bypass cooldown.
     * @return Amount of assets.
     */
    function withdrawRequest(uint256 _shares, address _receiver, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        nonReentrant
        returns (bool, uint256)
    {
        _onlyEOA();

        if (_shares == 0) {
            revert ZeroAmount();
        }

        WithdrawVars memory vars;

        /// @notice Calculate Assets
        vars.assets = underlyingVault.previewRedeem(_shares);

        /// @notice get user role
        vars.roleInfo = whitelistController.getUserInfo(msg.sender);

        vars.thisAddress = address(this);

        /// @notice burn jUSDC
        underlyingVault.burn(msg.sender, _shares);

        /// @notice Insant Withdraw
        if (vars.roleInfo.BYPASS_COOLDOWN) {
            /// @notice get USDC
            vars.usdcBalance = USDC.balanceOf(address(underlyingVault));

            vars.strategyRetention;

            /// @notice if not enough USDC in vault, force payback.
            if (vars.assets > vars.usdcBalance) {
                vars.strategyRetention = underlyingVault.enforcePayBack(vars.assets - vars.usdcBalance, _enforceData);
            }

            vars.toWithdraw = vars.assets - vars.strategyRetention;

            /// @notice get USDC from vault
            underlyingVault.withdraw(vars.toWithdraw, vars.thisAddress, vars.thisAddress);

            vars.retention;

            if (incentiveReceiver != address(0)) {
                /// @notice charge incentive retention
                vars.retention = vars.assets.mulDivDown(vars.roleInfo.INCENTIVE_RETENTION, BASIS_POINTS);

                USDC.transfer(incentiveReceiver, vars.retention);
            }

            vars.toUser = vars.toWithdraw > vars.retention ? vars.toWithdraw - vars.retention : 0;

            if (vars.toUser < _minAmountOut) {
                revert NotEnoughAssets();
            }

            if (vars.toUser > 0) {
                USDC.transfer(_receiver, vars.toUser);
            }

            emit Withdraw(msg.sender, vars.assets, _receiver, vars.retention + vars.strategyRetention);

            return (true, vars.toUser);
        } else {

            /// @notice get USDC here for custody
            uint256 usdcBalance = USDC.balanceOf(address(underlyingVault));

            uint256 strategyRetention;

            /// @notice if not enough USDC in vault, force payback.
            if (vars.assets > usdcBalance) {
                strategyRetention = underlyingVault.enforcePayBack(vars.assets - usdcBalance, _enforceData);
            }

            uint256 toWithdraw = vars.assets - strategyRetention;

            /// @notice get USDC from vault
            underlyingVault.withdraw(toWithdraw, vars.thisAddress, vars.thisAddress);

            Request storage _withdrawRequests = withdrawRequests[msg.sender];
            
            _withdrawRequests.assets = _withdrawRequests.assets + toWithdraw;
            _withdrawRequests.strategyRetention = _withdrawRequests.strategyRetention + strategyRetention;
            _withdrawRequests.withdrawRetention = vars.roleInfo.INCENTIVE_RETENTION;
            _withdrawRequests.timestamp = block.timestamp;

            totalWithdrawRequests = totalWithdrawRequests + toWithdraw;

            emit WithdrawRequest(msg.sender, toWithdraw);

            return (false, vars.assets);
        }
    }

    /**
     * @notice Cancel requests to withdraw.
     * @notice New Shares will be calculated based on asset vaule.
     * @notice If there is any strategy retention you will lose it.
     */
    function cancelWithdrawRequest() external nonReentrant returns (uint256) {
        Request storage _withdrawRequests = withdrawRequests[msg.sender];

        if (_withdrawRequests.assets == 0) {
            revert InsufficientFunds();
        }

        if (block.timestamp >= _withdrawRequests.timestamp + withdrawCooldown) {
            revert CooldownAlreadyPass();
        }

        uint256 assets = _withdrawRequests.assets;

        delete withdrawRequests[msg.sender];

        totalWithdrawRequests = totalWithdrawRequests - assets;

        /// @notice Calculate Shares
        uint256 shares = underlyingVault.previewDeposit(assets);

        /// @notice transfer USDC to Underlying Vault
        USDC.transfer(address(underlyingVault), assets);

        /// @notice mint jUSDC
        underlyingVault.mint(shares, msg.sender);

        emit CancelWithdrawRequest(msg.sender, assets, shares);

        return shares;
    }

    /**
     * @notice Withdraws the given amount of assets from the message sender's balance to the specified receiver.
     * @param _receiver The address that will receive the assets.
     * @param _minAmountOut Min Amount that should be received.
     * @param _enforceData The data needed to enforce payback.
     * @dev Reverts with InsufficientRequest If the user has not made a withdrawal request.
     * Reverts with WithdrawCooldown If the user's last withdrawal request was made less than the minimum withdrawal period ago.
     */

    function withdraw(address _receiver, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        nonReentrant
        returns (uint256)
    {
        _onlyEOA();

        Request storage _withdrawRequests = withdrawRequests[msg.sender];

        if (_withdrawRequests.assets == 0) {
            revert InsufficientFunds();
        }

        if (block.timestamp < _withdrawRequests.timestamp + withdrawCooldown) {
            revert CooldownNotMeet();
        }

        WithdrawVars memory vars;

        vars.assets = _withdrawRequests.assets;
        vars.strategyRetention = _withdrawRequests.strategyRetention;
        vars.withdrawRetention = _withdrawRequests.withdrawRetention;

        delete withdrawRequests[msg.sender];

        totalWithdrawRequests = totalWithdrawRequests - vars.assets;

        vars.retention;
        
        if (incentiveReceiver != address(0)) {
            /// @notice charge incentive retention
            vars.retention = (vars.assets + vars.strategyRetention).mulDivDown(vars.withdrawRetention, BASIS_POINTS);
            USDC.transfer(incentiveReceiver, vars.retention);
        }


        vars.toUser = vars.assets > vars.retention ? vars.assets - vars.retention : 0;

        if (vars.toUser < _minAmountOut) {
            revert NotEnoughAssets();
        }

        if (vars.toUser > 0) {
            USDC.transfer(_receiver, vars.toUser);
        }

        emit Withdraw(msg.sender, vars.assets, _receiver, vars.retention + vars.strategyRetention);

        return vars.toUser;
    }

    /**
     * @notice Users can redeem stable assets from the old system.
     * @param _epoch Target epoch.
     * @param _minAmountOut Min Amount that should be received.
     * @param _enforceData The data needed to enforce payback.
     * @return Amount of stables reeemed.
     */
    function redeemStable(uint256 _epoch, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        nonReentrant
        returns (uint256)
    {
        _onlyEOA();

        WithdrawVars memory vars;

        (uint256 targetEpoch, uint256 commitedAssets, bool redeemed,) = routerV1.withdrawSignal(msg.sender, _epoch);

        /// @notice get user role
        IWhitelistControllerV1.RoleInfo memory roleInfo = controllerV1.getRoleInfo(controllerV1.getUserRole(msg.sender));

        if (!roleInfo.jUSDC_BYPASS_TIME && routerV1.currentEpoch() < targetEpoch) {
            revert CooldownNotMeet();
        }

        if (redeemed || redemeed[msg.sender][_epoch]) {
            revert AlreadyRedemeed();
        }

        /// @notice Reduce to 6 decimals
        commitedAssets = commitedAssets / BASIS_POINTS;

        if (commitedAssets == 0) {
            revert InsufficientFunds();
        }

        vars.thisAddress = address(this);

        /// @notice get USDC
        vars.usdcBalance = USDC.balanceOf(address(underlyingVault));

        vars.strategyRetention;

        /// @notice if not enough USDC in vault, force payback.
        if (commitedAssets > vars.usdcBalance) {
            vars.strategyRetention = underlyingVault.enforcePayBack(commitedAssets - vars.usdcBalance, _enforceData);
        }

        vars.toWithdraw = commitedAssets - vars.strategyRetention;

        /// @notice get USDC from vault
        underlyingVault.withdraw(vars.toWithdraw, vars.thisAddress, vars.thisAddress);

        vars.retention;

        if (incentiveReceiver != address(0)) {
            /// @notice charge incentive retention
            vars.retention = commitedAssets.mulDivDown(roleInfo.jUSDC_RETENTION, BASIS_POINTS);
            USDC.transfer(incentiveReceiver, vars.retention);
        }

        vars.toUser = vars.toWithdraw > vars.retention ? vars.toWithdraw - vars.retention : 0;

        if (vars.toUser < _minAmountOut) {
            revert NotEnoughAssets();
        }

        if (vars.toUser > 0) {
            USDC.transfer(msg.sender, vars.toUser);
        }

        redemeed[msg.sender][_epoch] = true;

        emit Withdraw(msg.sender, commitedAssets, msg.sender, vars.retention + vars.strategyRetention);

        return vars.toUser;
    }

    /**
     * @notice Migrate old positions for new positions.
     * @return New uncompounding position.
     * @return New shares jUSDC.
     */
    function migratePosition() external nonReentrant returns (uint256, uint256) {
        _onlyEOA();

        address thisAddress = address(this);

        uint256 unCompoundBalance = trackerV1.stakedAmount(msg.sender);

        uint256 newjUSDC = unCompoundBalance.mulDivDown(regularRatio, BASIS_POINTS * BASIS_POINTS);

        if (newjUSDC > 0 && !migrated[msg.sender]) {
            migrated[msg.sender] = true;
            underlyingVault.transfer(msg.sender, newjUSDC);
        } else {
            newjUSDC = 0;
        }

        uint256 compoundAmount = OLD_jUSDC.allowance(msg.sender, thisAddress);

        if (compoundAmount > 0) {
            OLD_jUSDC.transferFrom(msg.sender, thisAddress, compoundAmount);
            underlyingVault.transfer(msg.sender, compoundAmount);
        }

        emit MigratePosition(msg.sender, unCompoundBalance, compoundAmount, newjUSDC, compoundAmount);

        return (newjUSDC, compoundAmount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Only Owner                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Update Internal Contracts.
     * @param _whitelistController New Role Controller.
     * @param _underlyingVault New underlying vault.
     * @param _routerV1 Old router tracker.
     * @param _trackerV1 Old tracker.
     */
    function updateInternalContracts(
        address _whitelistController,
        address _underlyingVault,
        address _routerV1,
        address _trackerV1
    ) external onlyOwner {
        whitelistController = IWhitelistController(_whitelistController);
        underlyingVault = IUnderlyingVault(_underlyingVault);
        routerV1 = IRouterV1(_routerV1);
        trackerV1 = ITrackerV1(_trackerV1);
    }

    /**
     * @notice Update Tokens.
     */
    function updateTokens(address _usdc, address _oldjusdc) external onlyOwner {
        USDC = IERC20(_usdc);
        OLD_jUSDC = IERC20(_oldjusdc);
    }

    /**
     * @notice Update Cooldown.
     */
    function updateCooldown(uint256 _withdrawCooldown) external onlyOwner {
        withdrawCooldown = _withdrawCooldown;
    }

    /**
     * @notice Update Incentive Receiver.
     */
    function updateIncentiveReceiver(address _incentiveReceiver) external onlyOwner {
        incentiveReceiver = _incentiveReceiver;
    }

    /**
     * @notice Update Ratio.
     */
    function updateRatio(uint256 _unCompoundRatio) external onlyOwner {
        regularRatio = _unCompoundRatio;
    }

    /**
     * @notice Update Socket.
     */
    function updateSocket(address _socket) external onlyOwner {
        socket = _socket;
    }

    /**
     * @notice Pause Deposits.
     */
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyOwner {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            if (_assets[i] == address(OLD_jUSDC)) {
                revert OldjUSDCFrozen();
            }

            IERC20 asset_ = IERC20(_assets[i]);
            uint256 assetBalance = asset_.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset_.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Private                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initialize Migration.
     */
    function _initializeMigration(uint256 _compoundUvrt, uint256 _usersUvrt, uint256 _jusdc) private {
        if (regularRatio > 0) {
            revert AlreadyCalled();
        }

        uint256 nonjUSDC = _usersUvrt.mulDivDown(_jusdc, _compoundUvrt);

        /// @notice mint total jUSDC
        underlyingVault.mint(nonjUSDC + _jusdc, address(this));

        regularRatio = nonjUSDC.mulDivDown(BASIS_POINTS * BASIS_POINTS, _usersUvrt);
    }

    /**
     * @notice Only EOA.
     */
    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !whitelistController.isWhitelistedContract(msg.sender)) {
            revert CallerIsNotWhitelisted();
        }
    }

    /**
     * @notice Only Socket Contract
     */
    function _onlySocket() private view returns (bool) {
        if (msg.sender == socket) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
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
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUnderlyingVault {
    function burn(address account, uint256 shares) external;
    function mint(uint256 shares, address receiver) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address /*owner*/ ) external returns (uint256);

    function receiveRewards(uint256 amount) external;
    function borrow(uint256 amount) external;
    function payBack(uint256 amount, uint256 incentives) external;
    function enforcePayBack(uint256 amount, bytes calldata enforceData) external returns (uint256);

    function transfer(address user, uint256 amount) external returns (bool);

    function retentionRefund(uint256 amount, bytes memory enforceData) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function borrowableAmount(address strategy) external view returns (uint256);
    function cap(address strategy) external view returns (uint256);
    function totalAssets() external view returns (uint256);

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
    event ReceiveRewards(address indexed sender, uint256 amount, uint256 totalAssets, uint256 totalSupply);
    event Borrowed(address indexed to, uint256 amount, uint256 totalDebt);
    event PayBack(address indexed from, uint256 amount, uint256 incentives, uint256 totalDebt);
    event EnforcePayback(uint256 amount, uint256 retention, uint256 totalAssets, uint256 totalDebt);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error NotEnoughFunds();
    error CallerIsNotStrategy();
    error FailSendETH();
    error NotRightCaller();
    error CapReached();
    error StalePrice();
    error InvalidPrice();
    error StalePriceUpdate();
    error SequencerDown();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    struct Request {
        uint256 assets;
        uint256 strategyRetention;
        uint256 withdrawRetention;
        uint256 timestamp;
    }

    function deposit(uint256 _assets, address _receiver) external returns (uint256);
    function multichainDeposit(address _receiver) external returns (uint256);
    function withdrawRequest(uint256 _shares, address _receiver, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        returns (bool, uint256);
    function cancelWithdrawRequest() external returns (uint256);

    function withdraw(address _receiver, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        returns (uint256);
    function redeemStable(uint256 _epoch, uint256 _minAmountOut, bytes calldata _enforceData)
        external
        returns (uint256);

    function migratePosition() external returns (uint256, uint256);

    function withdrawRequests(address _user) external view returns (uint256, uint256, uint256, uint256);
    function totalWithdrawRequests() external view returns (uint256);

    function incentiveReceiver() external view returns (address);
    function withdrawCooldown() external view returns (uint256);

    event Deposit(address indexed owner, uint256 assets, address receiver, uint256 shares);
    event WithdrawRequest(address indexed owner, uint256 assets);
    event CancelWithdrawRequest(address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed owner, uint256 assets, address receiver, uint256 retention);
    event MigratePosition(
        address indexed owner, uint256 oldAssets, uint256 oldjUSDC, uint256 newAssets, uint256 newjUSDC
    );
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    error ZeroAmount();
    error InsufficientFunds();
    error OldjUSDCFrozen();
    error CooldownNotMeet();
    error CooldownAlreadyPass();
    error FailSendETH();
    error AlreadyRedemeed();
    error AlreadyCalled();
    error NotRightCaller();
    error NotEnoughAssets();
    error CallerIsNotWhitelisted();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWhitelistController {
    struct RoleInfo {
        bool BYPASS_COOLDOWN;
        uint256 INCENTIVE_RETENTION;
    }

    function addToWhitelist(address _account) external;
    function removeFromWhitelist(address _account) external;
    function bulkAddToWhitelist(address[] calldata _accounts) external;
    function bulkRemoveFromWhitelist(address[] calldata _accounts) external;

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getUserRole(address _user) external view returns (bytes32);
    function getRoleInfo(bytes32 _role) external view returns (RoleInfo memory);
    function getDefaultRole() external view returns (RoleInfo memory);
    function getUserInfo(address _user) external view returns (RoleInfo memory);
    function isWhitelistedContract(address _account) external view returns (bool);

    error NotRightCaller();
    error RoleNotExits();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouterV1 {
    function currentEpoch() external view returns (uint256);
    function withdrawSignal(address user, uint256 epoch) external view returns (uint256, uint256, bool, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrackerV1 {
    function stakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWhitelistControllerV1 {
    struct RoleInfo {
        bool jGLP_BYPASS_CAP;
        bool jUSDC_BYPASS_TIME;
        uint256 jGLP_RETENTION;
        uint256 jUSDC_RETENTION;
    }

    function isInternalContract(address _account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getUserRole(address _user) external view returns (bytes32);
    function getRoleInfo(bytes32 _role) external view returns (RoleInfo memory);
    function getDefaultRole() external view returns (RoleInfo memory);
    function isWhitelistedContract(address _account) external view returns (bool);
    function addToInternalContract(address _account) external;
    function addToWhitelistContracts(address _account) external;
    function removeFromInternalContract(address _account) external;
    function removeFromWhitelistContract(address _account) external;
    function bulkAddToWhitelistContracts(address[] calldata _accounts) external;
    function bulkRemoveFromWhitelistContract(address[] calldata _accounts) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}