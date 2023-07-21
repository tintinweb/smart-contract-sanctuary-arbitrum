// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableOperable} from "src/common/UpgradeableOperable.sol";
import {ICreator} from "src/interfaces/ICreator.sol";
import {ILpsRegistry} from "src/interfaces/common/ILpsRegistry.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {IFarm} from "src/interfaces/IFarm.sol";
import {IMinimalInit} from "src/interfaces/IMinimalInit.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {IViewer} from "src/interfaces/IViewer.sol";
import {ISSOV} from "src/interfaces/option/dopex/ISSOV.sol";
import {IFactory} from "src/interfaces/IFactory.sol";
import {IZapUniV2} from "src/ZapUniV2.sol";

contract Factory is IFactory, UpgradeableOperable {
    struct InitData {
        ILPVault[] lpVaults;
        address[] vaultAddresses;
        address[] metavaults;
        address lpToken;
        address manager;
        address registry;
        ILpsRegistry registryContract;
    }

    address public gov;
    address public manager;
    address public keeper;
    address public incentiveReceiver;

    ICreator public creator;
    ILpsRegistry public registry;
    IViewer public viewer;
    IZapUniV2 public zap;

    uint256 public slippage;
    uint256 public maxRisk;
    uint256 public premium;
    uint256 public retentionIncentive;

    uint256 public nonce;
    // nonce -> Init Data
    mapping(uint256 => InitData) public initData;
    // underlyingToken -> Stage
    mapping(address => Stage) public stage;

    bool public toggle;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initialize Factory contract.
     * @param init Parameters needed to initialize factory.
     */
    function initialize(InitParams memory init) external initializer {
        __Governable_init(msg.sender);

        gov = msg.sender;

        creator = ICreator(init._creator);
        registry = ILpsRegistry(init._registry);
        viewer = IViewer(init._viewer);
        zap = IZapUniV2(init._zap);

        manager = init._manager;
        keeper = init._keeper;
        incentiveReceiver = init._incentiveReceiver;
        retentionIncentive = init._retentionIncentive;
        slippage = init._slippage;
        maxRisk = init._maxRisk;
        premium = init._premium;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Change metavault stage.
     * @param _underlyingAddress metavault underlying token address.
     * @param _stage metavault stage.
     */
    function changeStage(address _underlyingAddress, Stage _stage) external onlyGovernor {
        emit UpdateStage(_underlyingAddress, stage[_underlyingAddress], _stage);
        stage[_underlyingAddress] = _stage;
    }

    /**
     * @notice Update metavault governor.
     * @param _gov new metavault governor address.
     */
    function updateGov(address _gov) external onlyGovernor {
        gov = _gov;
    }

    /**
     * @notice Update Zap contract.
     * @param _zap zap contract address.
     */
    function updateZap(address _zap) external onlyGovernor {
        zap = IZapUniV2(_zap);
    }

    /**
     * @notice Update Creator contract.
     * @param _creator creator contract address.
     */
    function updateCreator(address _creator) external onlyGovernor {
        creator = ICreator(_creator);
    }

    /**
     * @notice Update Registry contract.
     * @param _registry registry contract address.
     */
    function updateRegistry(address _registry) external onlyGovernor {
        registry = ILpsRegistry(_registry);
    }

    /**
     * @notice Update keeper.
     * @param _keeper keeper address.
     */
    function updateKeeper(address _keeper) external onlyGovernor {
        keeper = _keeper;
    }

    /**
     * @notice Update Mabager contract.
     * @param _manager manager contract address.
     */
    function updateManager(address _manager) external onlyGovernor {
        manager = _manager;
    }

    /**
     * @notice Update Incentive Receiver.
     * @param _incentiveReceiver incentiveReceiver address.
     */
    function updateIncentiveReceiver(address _incentiveReceiver) external onlyGovernor {
        incentiveReceiver = _incentiveReceiver;
    }

    /**
     * @notice Update system slippage.
     * @param _slippage system slippage.
     */
    function updateSlippage(uint256 _slippage) external onlyGovernor {
        slippage = _slippage;
    }

    /**
     * @notice Update option max risk.
     * @param _maxRisk option max risk.
     */
    function updateMaxRisk(uint256 _maxRisk) external onlyGovernor {
        maxRisk = _maxRisk;
    }

    /**
     * @notice Update premium.
     * @param _premium option premium.
     */
    function updatePremium(uint256 _premium) external onlyGovernor {
        premium = _premium;
    }

    /**
     * @notice Update Retention Incentive.
     * @param _retentionIncentive retentionIncentive amount.
     */
    function updateRetentionIncentive(uint256 _retentionIncentive) external onlyGovernor {
        retentionIncentive = _retentionIncentive;
    }

    /**
     * @notice Toggle between only operator or free access to whitelist functions.
     */
    function pressToggle() external onlyGovernor {
        toggle = !toggle;
        emit Toggle(toggle);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY WHITELISTED                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Create new metavault.
     * @param params metavault create parameters.
     */
    function create(CreateParams memory params) external returns (uint256) {
        uint256 _nonce = nonce + 1;
        InitData storage _initData = initData[_nonce];

        _initData.registryContract = registry;
        _initData.registry = address(_initData.registryContract);

        _whitelisted(params._underlyingToken, _initData.registryContract);

        _initData.lpToken = _initData.registryContract.lpToken(params._underlyingToken);

        if (stage[params._underlyingToken] == Stage.CREATED || stage[params._underlyingToken] == Stage.CONFIGURED) {
            revert InvalidStage();
        }

        nonce = _nonce;

        address[] memory _implementations = creator.getImplementations();

        address[] memory _beacons = creator.getBeacons();

        address[] memory _metavaults = new address[](12);

        _metavaults[0] = params._underlyingToken;

        ICreator _creator = creator;

        // SWAP
        _metavaults[11] = _clone(_implementations[3]);
        IMinimalInit(_metavaults[11]).initializeSwap(_initData.registry);
        // LP
        _metavaults[10] = _clone(_implementations[2]);
        IMinimalInit(_metavaults[10]).initializeLP(_initData.lpToken, params._underlyingToken, slippage);
        // FARM
        _metavaults[9] = _clone(_implementations[1]);
        IMinimalInit(_metavaults[9]).initializeFarm(
            _initData.registryContract.poolID(params._underlyingToken),
            _initData.lpToken,
            _metavaults[10],
            _initData.registryContract.rewardToken(params._underlyingToken),
            _initData.registry,
            _metavaults[11],
            slippage
        );

        // OPTION ADAPTER
        _metavaults[7] = _implementations[4];
        _metavaults[8] = _implementations[5];

        // ROUTER
        _metavaults[4] = _creator.createDiamond(address(this));

        // COMPOUND STRATEGY
        _metavaults[5] = _creator.createBeacon(_beacons[0]);

        // OPTION STRATEGY
        _metavaults[6] = _creator.createBeacon(_beacons[1]);

        // VAULTS
        _metavaults[1] = _clone(_implementations[0]);
        IMinimalInit(_metavaults[1]).initializeVault(
            _initData.lpToken, params._bullName, params._bullName, IRouter.OptionStrategy.BULL
        );
        _metavaults[2] = _clone(_implementations[0]);
        IMinimalInit(_metavaults[2]).initializeVault(
            _initData.lpToken, params._bearName, params._bearName, IRouter.OptionStrategy.BEAR
        );
        _metavaults[3] = _clone(_implementations[0]);
        IMinimalInit(_metavaults[3]).initializeVault(
            _initData.lpToken, params._crabName, params._crabName, IRouter.OptionStrategy.CRAB
        );

        _initData.lpVaults.push(ILPVault(_metavaults[1]));
        _initData.lpVaults.push(ILPVault(_metavaults[2]));
        _initData.lpVaults.push(ILPVault(_metavaults[3]));

        _initData.vaultAddresses.push(_metavaults[1]);
        _initData.vaultAddresses.push(_metavaults[2]);
        _initData.vaultAddresses.push(_metavaults[3]);

        // Set Viewer Addresses
        viewer.setAddresses(
            _initData.lpToken,
            IViewer.Addresses({
                compoundStrategy: ICompoundStrategy(_metavaults[5]),
                optionStrategy: IOptionStrategy(_metavaults[6]),
                router: IRouter(_metavaults[4])
            })
        );

        // LP token, router, swapper and pairAdapter
        zap.setMetavault(_initData.lpToken, _metavaults[4], _metavaults[11], _metavaults[10]);

        stage[params._underlyingToken] = Stage.CREATED;

        _initData.metavaults = _metavaults;

        emit Create(_nonce, params._underlyingToken, Stage.CREATED, _initData.metavaults);

        return _nonce;
    }

    /**
     * @notice Setup new metavault.
     * @param _nonce metavault nonce.
     */
    function setup(uint256 _nonce) external {
        InitData memory _initData = initData[_nonce];
        ILpsRegistry _registry = registry;
        _whitelisted(_initData.metavaults[0], _registry);
        _initData.lpToken = _registry.lpToken(_initData.metavaults[0]);

        if (stage[_initData.metavaults[0]] != Stage.CREATED) {
            revert InvalidStage();
        }

        _initData.manager = manager;

        // Farm
        {
            IMinimalInit farm = IMinimalInit(_initData.metavaults[9]);
            farm.addOperator(_initData.metavaults[5]);
            farm.addOperator(address(zap));
            farm.addNewSwapper(_initData.metavaults[11]);
            farm.updateGovernor(gov);
        }

        // Swapper
        {
            IMinimalInit swap = IMinimalInit(_initData.metavaults[11]);
            swap.setSlippage(slippage);
            swap.addOperator(_initData.metavaults[6]);
            swap.addOperator(address(zap));
            swap.addOperator(_initData.metavaults[10]);
            swap.addOperator(_initData.metavaults[9]);
            swap.addOperator(_initData.metavaults[7]);
            swap.addOperator(_initData.metavaults[8]);
            swap.updateGovernor(gov);
        }

        // LP
        {
            IMinimalInit lp = IMinimalInit(_initData.metavaults[10]);
            lp.addOperator(_initData.metavaults[9]);
            lp.addOperator(_initData.metavaults[6]);
            lp.addNewSwapper(_initData.metavaults[11]);
            lp.addOperator(address(zap));
            lp.updateGovernor(gov);
        }

        // Option Call Apdater
        {
            IMinimalInit call_dopex = IMinimalInit(_initData.metavaults[7]);
            call_dopex.addOperator(_initData.metavaults[6]);
        }

        // Option Put Apdater
        {
            IMinimalInit put_dopex = IMinimalInit(_initData.metavaults[8]);
            put_dopex.addOperator(_initData.metavaults[6]);
        }

        // Option Strategy
        {
            IMinimalInit op = IMinimalInit(_initData.metavaults[6]);
            op.initializeOpStrategy(_initData.lpToken, _initData.metavaults[10], _initData.metavaults[11]);
            op.addOperator(_initData.metavaults[5]);
            op.addOperator(_initData.metavaults[7]);
            op.addOperator(_initData.metavaults[8]);
            op.addOperator(_initData.metavaults[4]);
            op.addOperator(_initData.manager);
            op.addProvider(_initData.metavaults[7]);
            op.addProvider(_initData.metavaults[8]);
            op.addKeeper(keeper);
            op.setCompoundStrategy(_initData.metavaults[5]);
            op.setDefaultProviders(_initData.metavaults[7], _initData.metavaults[8]);
            op.updateGovernor(gov);
        }

        // Compound Strategy
        {
            IMinimalInit cmp = IMinimalInit(_initData.metavaults[5]);
            cmp.initializeCmpStrategy(
                IFarm(_initData.metavaults[9]),
                IOptionStrategy(_initData.metavaults[6]),
                IRouter(_initData.metavaults[4]),
                _initData.lpVaults,
                _initData.lpToken,
                maxRisk
            );
            cmp.addOperator(_initData.metavaults[4]);
            cmp.addOperator(_initData.metavaults[6]);
            cmp.addOperator(_initData.manager);
            cmp.addKeeper(keeper);
            cmp.setUpIncentives(incentiveReceiver, retentionIncentive);
            cmp.updateGovernor(gov);
        }

        // Router
        {
            IMinimalInit router = IMinimalInit(_initData.metavaults[4]);
            router.initializeRouter(_initData.metavaults[5], _initData.metavaults[6], _initData.vaultAddresses, premium);
            router.transferOwnership(gov);
        }

        // Bull Vault
        {
            IMinimalInit bullVault = IMinimalInit(_initData.metavaults[1]);
            bullVault.addOperator(_initData.metavaults[4]);
            bullVault.addOperator(_initData.metavaults[5]);
            bullVault.setStrategies(_initData.metavaults[5]);
            bullVault.updateGovernor(gov);
        }

        // Bear Vault
        {
            IMinimalInit bearVault = IMinimalInit(_initData.metavaults[2]);
            bearVault.addOperator(_initData.metavaults[4]);
            bearVault.addOperator(_initData.metavaults[5]);
            bearVault.setStrategies(_initData.metavaults[5]);
            bearVault.updateGovernor(gov);
        }

        // Crab Vault
        {
            IMinimalInit crabVault = IMinimalInit(_initData.metavaults[3]);
            crabVault.addOperator(_initData.metavaults[4]);
            crabVault.addOperator(_initData.metavaults[5]);
            crabVault.setStrategies(_initData.metavaults[5]);
            crabVault.updateGovernor(gov);
        }

        stage[_initData.metavaults[0]] = Stage.CONFIGURED;

        emit Setup(_nonce, _initData.metavaults[0], Stage.CONFIGURED, _initData.metavaults);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   View                                     */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get metavaults addresses.
     * @param _nonce metavault nonce.
     */
    function getMetavault(uint256 _nonce) external view returns (address[] memory) {
        // 0  -> Underlying Token
        // 1  -> Bull Vault
        // 2  -> Bear Vault
        // 3  -> Crab Vault
        // 4  -> Router
        // 5  -> Compound Strategy
        // 6  -> Option Strategy
        // 7  -> Call Adapter
        // 8  -> Put Adapter
        // 9  -> Farm Adapter
        // 10 -> LP Adapter
        // 11 -> Swap Adapter
        return initData[_nonce].metavaults;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  PRIVATE                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify if caller can call a function.
     * @param _token metavault underlying token.
     * @param _registry lp token registry contract.
     */
    function _whitelisted(address _token, ILpsRegistry _registry) private view {
        if (!hasRole(OPERATOR, msg.sender) && !toggle) {
            revert CallerNotAllowed();
        }
        if (_registry.poolID(_token) == 0) {
            revert TokenNotWhitelisted();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) private returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Toggle(bool toggle);
    event Create(uint256 nonce, address indexed underlyingToken, Stage stage, address[] metavaults);
    event Setup(uint256 nonce, address indexed underlyingToken, Stage stage, address[] metavaults);
    event UpdateStage(address indexed underlyingToken, Stage oldStage, Stage newStage);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error InvalidStage();
    error CallerNotAllowed();
    error TokenNotWhitelisted();
    error ERC1167FailedCreateClone();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "./UpgradeableGovernable.sol";

abstract contract UpgradeableOperable is UpgradeableGovernable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Grant Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";
import {DiamondArgs} from "src/router/BeaconDiamond.sol";

interface ICreator {
    // GOV
    function setImplementations(address[] memory _impls) external;
    function setFacets(IDiamond.BeaconCut[] memory _facets) external;
    function updateDiamondInit(address _diamondInit) external;
    function updateInitData(bytes memory _initData) external;

    // VIEW
    function getFacets() external view returns (IDiamond.BeaconCut[] memory);
    function getImplementations() external view returns (address[] memory);
    function getBeacons() external view returns (address[] memory);

    // OPERATOR
    function createDiamond(address _owner) external returns (address);
    function createBeacon(address _beacon) external returns (address);
}

// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.10;

/**
 * @title LpsRegistry
 * @author JonesDAO
 * @notice Contract to store information about tokens and its liquidity pools pairs
 */
interface ILpsRegistry {
    function addWhitelistedLp(
        address _tokenIn,
        address _tokenOut,
        address _liquidityPool,
        address _rewardToken,
        uint256 _poolID
    ) external;

    function removeWhitelistedLp(address _tokenIn, address _tokenOut) external;

    function getLpAddress(address _tokenIn, address _tokenOut) external view returns (address);

    function lpToken(address _underlyingToken) external view returns (address);

    function poolID(address _underlyingToken) external view returns (uint256);

    function rewardToken(address _underlyingToken) external view returns (address);

    function updateGovernor(address _newGovernor) external;

    function initialize() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IRouter {
    /**
     * @notice Different types of vaults.
     */
    enum OptionStrategy {
        BULL,
        BEAR,
        CRAB
    }

    /**
     * @notice Deposit info struct, helps on deposit process (stack too deep).
     */
    struct DepositInfo {
        address receiver;
        OptionStrategy strategy;
        address thisAddress;
        uint256 epoch;
        uint64 endTime;
        uint256 optionBullRisk;
        uint256 optionBearRisk;
        address strategyAddress;
        address optionsAddress;
        ICompoundStrategy compoundStrategy;
        IOptionStrategy optionStrategy;
        IERC20 lpToken;
        ILPVault vault;
        uint256 assets;
        uint256 toFarm;
        uint256 toBuyOptions;
        uint256 shares;
    }

    /**
     * @notice Withdraw info struct, helps on withdraw process (stack too deep).
     */
    struct WithdrawInfo {
        uint256 currentEpoch;
        uint256 endTime;
        uint256 withdrawExchangeRate;
        uint256 currentBalance;
        uint256 sharesWithPenalty;
        uint256 lpAssets;
        uint256 retention;
        uint256 toTreasury;
        uint256 redemeed;
        address incentiveReceiver;
    }

    /**
     * @notice Cancel flip info struct, helps on cancelFlip (stack too deep).
     */
    struct CancelFlipInfo {
        uint256 commitEpoch;
        uint256 currentEpoch;
        uint256 endTime;
        uint256 finalShares;
        uint256 flipRate;
    }

    /**
     * @notice User withdraw signal struct.
     */
    struct WithdrawalSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        OptionStrategy strategy;
        uint256 redeemed;
    }

    /**
     * @notice User flip signal struct.
     */
    struct FlipSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        OptionStrategy oldStrategy;
        OptionStrategy newStrategy;
        uint256 redeemed;
    }

    /**
     * @notice Enable LP deposits to a Strategy Metavault.
     * @param _assets Amount of assets to be deposit
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _instant True if is instant deposit, false if is for the next epoch.
     * @param _receiver Who will receive the shares.
     * @return Amount of shares minted.
     */
    function deposit(uint256 _assets, OptionStrategy _strategy, bool _instant, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Get shares for previues epoch deposit.
     * @param _commitEpoch Amount of assets to be deposit
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return Amount of shares.
     */
    function claim(uint256 _commitEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal withdraw to the next epoch.
     * @param _receiver Who will receive the assets redeemed.
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _shares Amount of Metavault shares to redeem.
     * @return Target epoch.
     */
    function signalWithdraw(address _receiver, OptionStrategy _strategy, uint256 _shares) external returns (uint256);

    /**
     * @notice Cancel signal withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelSignal(uint256 _targetEpoch, OptionStrategy _strategy, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function withdraw(uint256 _targetEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Instant withdraw.
     * @param _shares Shares to redeem.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function instantWithdraw(uint256 _shares, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal flip.
     * @param _shares Shares to flip.
     * @param _oldtrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     */
    function signalFlip(uint256 _shares, OptionStrategy _oldtrategy, OptionStrategy _newStrategy, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Cancel Flip Signal.
     * @param _targetEpoch Signal target epoch.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelFlip(
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Withdraw flipped shares.
     * @param _targetEpoch Shares to flip.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function flipWithdraw(
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Update accounting when epoch finish.
     */
    function executeFinishEpoch() external;

    /**
     * @notice Total strategy next epoch deposit.
     */
    function nextEpochDeposits(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice User next epoch deposit for a strategy.
     */
    function userNextEpochDeposits(address _user, uint256 _epoch, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256);

    /**
     * @notice Get total withdraw signals.
     */
    function withdrawSignals(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice Get user withdraw signals per epoch per strategy.
     */
    function getWithdrawSignal(address _user, uint256 _targetEpoch, OptionStrategy _strategy)
        external
        view
        returns (WithdrawalSignal memory);

    /**
     * @notice Total Flip Signals.
     */
    function flipSignals(OptionStrategy _oldStrategy, OptionStrategy _newStrategy) external view returns (uint256);

    /**
     * @notice Get user flip signals.
     */
    function getFlipSignal(
        address _user,
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy
    ) external view returns (FlipSignal memory);

    /**
     * @notice Get premium.
     */
    function premium() external view returns (uint256);

    /**
     * @notice Get slippage.
     */
    function slippage() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ILPVault is IERC20 {
    /**
     * @notice get underlying token
     */
    function underlying() external returns (IERC20);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function mint(uint256 _shares, address _receiver) external returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function burn(address _account, uint256 _shares) external;
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewDeposit(uint256 _assets) external view returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewRedeem(uint256 _shares) external view returns (uint256);
    /**
     * @notice get Vault total assets
     */
    function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {ISSOV, IERC20} from "src/interfaces/option/dopex/ISSOV.sol";

interface IOption {
    enum OPTION_TYPE {
        CALLS,
        PUTS
    }

    struct ExecuteParams {
        uint256 currentEpoch;
        // strike price
        uint256[] _strikes;
        // % used in each strike;
        uint256[] _collateralEachStrike;
        uint256 _expiry;
        bytes _externalData;
    }

    // Data needed to settle the ITM options
    struct SettleParams {
        uint256 currentEpoch;
        uint256 optionEpoch;
        bytes _externalData;
    }

    // Data needed to execute a single option pruchase (stack too deep)
    struct SingleOptionInfo {
        ISSOV ssov;
        IERC20 collateralToken;
        address here;
        address collateralAddress;
        uint256 collateral;
        uint256 ssovEpoch;
        uint256 optionsAmount;
    }

    // Buys options.
    // Return avg option price in WETH
    function purchase(ExecuteParams calldata params) external;

    // Execute option pruchase in mid epoch
    function executeSingleOptionPurchase(uint256 _epoch, uint256 _strike, uint256 _collateral)
        external
        returns (uint256);

    // Settle ITM options
    function settle(SettleParams calldata params) external returns (uint256);

    // Get option price from given type and strike. On DopEx its returned in collateral token.
    function getOptionPrice(uint256 _strike) external view returns (uint256);

    // system epoch => option epoch
    function epochs(uint256 _epoch) external view returns (uint256);

    function strategy() external view returns (IRouter.OptionStrategy _strategy);

    // avg option price getting ExecuteParams buy the same options
    function optionType() external view returns (OPTION_TYPE);

    function getCurrentStrikes() external view returns (uint256[] memory);

    // Token used to buy options
    function getCollateralToken() external view returns (address);

    function geAllStrikestPrices() external view returns (uint256[] memory);

    function getAvailableOptions(uint256 _strike) external view returns (uint256);
    function position(address _optionStrategy, address _compoundStrategy) external view returns (uint256);

    function lpToCollateral(address _lp, uint256 _amount) external view returns (uint256);
    function getExpiry() external view returns (uint256);

    function amountOfOptions(address _optionStrategy, uint256 _epoch, uint256 _strikeIndex)
        external
        view
        returns (uint256);
    function pnl(address _optionStrategy, address _compoundStrategy) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IFarm {
    function rewardToken() external view returns (IERC20);

    function balance() external view returns (uint256);

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount, address _receiver) external;

    function earned() external view returns (uint256);

    function pendingRewards() external view returns (address[] memory, uint256[] memory);

    function pendingRewardsToLP() external view returns (uint256);

    function claim(address _receiver) external;

    function claimAndStake() external returns (uint256);

    function exit() external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISSOV} from "src/interfaces/option/dopex/ISSOV.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {IFarm} from "src/interfaces/IFarm.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";

interface IMinimalInit {
    // ACESSS
    function addOperator(address _newOperator) external;
    function addKeeper(address _keeper) external;
    function updateGovernor(address _newGovernor) external;
    function transferOwnership(address _newOwner) external;

    // UTILS
    function addProvider(address _provider) external;
    function setDefaultProviders(address _callProvider, address _putProvider) external;
    function addNewSwapper(address _swapper) external;
    function setSlippage(uint256 _slippage) external;
    function setStrategies(address _strategy) external;
    function setCompoundStrategy(address _strategy) external;
    function setUpIncentives(address _incentiveReceiver, uint256 _retentionIncentive) external;

    // INITS
    function initializeSwap(address _lpsRegistry) external;
    function initializeLP(address _lp, address _otherToken, uint256 _slippage) external;
    function initializeFarm(
        uint256 _pid,
        address _lp,
        address _lpAdapter,
        address _rewardToken,
        address _lpsRegistry,
        address _defaultSwapper,
        uint256 _defaultSlippage
    ) external;
    function initializeOptionAdapter(
        IOption.OPTION_TYPE _type,
        ISSOV _ssov,
        uint256 _slippage,
        IOptionStrategy _optionStrategy,
        ICompoundStrategy _compoundStrategy
    ) external;
    function initializeOpStrategy(address _lp, address _pairAdapter, address _swapper) external;
    function initializeRouter(
        address _compoundStrategy,
        address _optionStrategy,
        address[] calldata _strategyVaults,
        uint256 _premium
    ) external;
    function initializeCmpStrategy(
        IFarm _farm,
        IOptionStrategy _option,
        IRouter _router,
        ILPVault[] memory _vaults,
        address _lpToken,
        uint256 _maxRisk
    ) external;
    function initializeVault(
        address _asset,
        string memory _name,
        string memory _symbol,
        IRouter.OptionStrategy _vaultType
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";

interface ICompoundStrategy {
    /**
     * @notice Usefull Epoch Data
     */
    struct Epoch {
        // Start time of the epoch
        uint64 startTime;
        // When the Epoch expiries
        uint64 virtualEndTime;
        // When we finish the Epoch
        uint64 endTime;
        // % of Bull vault used to buy call options
        uint64 optionBullRisk;
        // % of Bear vault used to buy put options
        uint64 optionBearRisk;
        // Initial LP amount in the begin of the Epoch
        uint128 initialBullRatio;
        uint128 initialBearRatio;
        uint128 initialCrabRatio;
        // Withdraw Rates jLP -> LP
        uint128 withdrawBullExchangeRate;
        uint128 withdrawBearExchangeRate;
        // Flip Rates bullLP -> bearLP
        uint128 flipBullToBearExchangeRate;
        uint128 flipBullToCrabExchangeRate;
        uint128 flipBearToBullExchangeRate;
        uint128 flipBearToCrabExchangeRate;
        uint128 flipCrabToBullExchangeRate;
        uint128 flipCrabToBearExchangeRate;
        // Deposit Rates
        uint128 depositBullRatio;
        uint128 depositBearRatio;
        // Final amount of LP in the end of the Epoch
        uint128 finalBullRatio;
        uint128 finalBearRatio;
        uint128 finalCrabRatio;
    }

    /**
     * @notice Start epoch information, help on startEpoch (stack too deep)
     */
    struct StartEpochInfo {
        uint256 epoch;
        address thisAddress;
        uint256 currentLPBalance;
        uint256 farmBalance;
        uint256 initialBalanceSnapshot;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 crabAssets;
        uint256 totalBalance;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 toOptions;
        uint256 bullRatio;
        uint256 bearRatio;
        uint256 crabRatio;
    }

    /**
     * @notice General epoch information, help on endEpoch (stack too deep)
     */
    struct GeneralInfo {
        Epoch epochData;
        uint256 currentEpoch;
        uint256 endTime;
        address thisAddress;
        IRouter router;
        address routerAddress;
        ILPVault bullVault;
        ILPVault bearVault;
        ILPVault crabVault;
        IRouter.OptionStrategy bullStrat;
        IRouter.OptionStrategy bearStrat;
        IRouter.OptionStrategy crabStrat;
        IERC20 lpToken;
    }

    /**
     * @notice Flip signals information.
     */
    struct FlipInfo {
        uint256 bullToBear;
        uint256 bullToCrab;
        uint256 bearToBull;
        uint256 bearToCrab;
        uint256 crabToBull;
        uint256 crabToBear;
        uint256 redeemBullToBearAssets;
        uint256 redeemBullToCrabAssets;
        uint256 redeemBearToBullAssets;
        uint256 redeemBearToCrabAssets;
        uint256 redeemCrabToBullAssets;
        uint256 redeemCrabToBearAssets;
        uint256 bullToBearShares;
        uint256 bullToCrabShares;
        uint256 bearToBullShares;
        uint256 bearToCrabShares;
        uint256 crabToBearShares;
        uint256 crabToBullShares;
        uint256 bullToBearRate;
        uint256 bullToCrabRate;
        uint256 bearToBullRate;
        uint256 bearToCrabRate;
        uint256 crabToBullRate;
        uint256 crabToBearRate;
    }

    /**
     * @notice Withdraw signals information.
     */
    struct WithdrawInfo {
        uint256 bullShares;
        uint256 bearShares;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 totalSignals;
        uint256 bullRetention;
        uint256 bearRetention;
        uint256 retention;
        uint256 toTreasury;
        uint256 toPayBack;
        uint256 currentBalance;
        uint256 withdrawBullRate;
        uint256 withdrawBearRate;
    }

    /**
     * @notice Next epoch deposit information.
     */
    struct DepositInfo {
        uint256 depositBullAssets;
        uint256 depositBearAssets;
        uint256 depositBullShares;
        uint256 depositBearShares;
        uint256 depositBullRate;
        uint256 depositBearRate;
    }

    /**
     * @notice Auto compounds all the farming rewards.
     */
    function autoCompound() external;

    /**
     * @notice Handles LPs deposits accountability and staking
     * @param _amount Amount of LP tokens being deposited
     * @param _type Strategy which balance will be updated
     * @param _nextEpoch signal to not increase the balance of the vault immidiatly.
     */
    function deposit(uint256 _amount, IRouter.OptionStrategy _type, bool _nextEpoch) external;

    /**
     * @notice Withdraw LP assets.
     * @param _amountWithPenalty Amount to unstake
     * @param _receiver Who will receive the LP token
     */
    function instantWithdraw(uint256 _amountWithPenalty, IRouter.OptionStrategy _type, address _receiver) external;

    /**
     * @notice Get Strategy Assets; farm + here
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Get LP Vault Assets, overall LP for a Vault.
     */
    function vaultAssets(IRouter.OptionStrategy _type) external view returns (uint256);

    /**
     * @notice Get current LP Vault Balance, without pnl, borrowing LP and pending rewards.
     */
    function getVaultBalance(IRouter.OptionStrategy _type) external view returns (uint256);

    /**
     * @notice Get Current epoch.
     */
    function currentEpoch() external view returns (uint256);

    /**
     * @notice Get epoch Data.
     */
    function epochData(uint256 number) external view returns (Epoch memory);

    /**
     * @notice Get the LP Token.
     */
    function lpToken() external view returns (IERC20);

    /**
     * @notice Get retention incentive percentage.
     */
    function retentionIncentive() external view returns (uint256);

    /**
     * @notice Get the incentive receiver address.
     */
    function incentiveReceiver() external view returns (address);

    /**
     * @notice Get the three strategy Vaults; 0 => BULL, 1 => BEAR, 2 => CRAB
     */
    function getVaults() external view returns (ILPVault[] memory);

    /**
     * @notice Start new epoch.
     */
    function startEpoch(uint64 epochExpiry, uint64 optionBullRisk, uint64 optionBearRisk) external;

    /**
     * @notice Finish current epoch.
     */
    function endEpoch() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ISwap} from "src/interfaces/ISwap.sol";

interface IOptionStrategy {
    // One deposit can buy from different providers
    struct OptionParams {
        // Swap Data (WETH -> token needed to buy options)
        // Worst case we make 4 swaps
        bytes swapData;
        // Swappper to buy options (default: OneInch)
        ISwap swapper;
        // Amount of lp to BULL
        uint256 percentageLpBull;
    }

    struct Strike {
        // Strike price, eg: $1800
        uint256 price;
        // How much it cost to buy one option for the given strike
        uint256 costIndividual;
        // How much it was spent in total for this strike
        uint256 costTotal;
        // From the amount set to be spent on options, how much this strike represents of the total portion
        uint256 percentageOverTotalCollateral;
        // Current amount of options
        uint256 currentOptions;
    }

    // Index 0 is most profitable option
    struct ExecuteStrategy {
        uint256 currentEpoch;
        // Array of providers
        IOption[] providers;
        // amount of the broken lp that will go to the provider to purchase options
        uint256[] providerPercentage;
        // Each provider can have different strikes
        // Strikes according to the same order as percentageEachStrike. Using 8 decimals
        uint256[][] strikes;
        uint256[][] collateralEachStrike;
        // Used for Dopex's leave blank (0) for other providers.
        uint256[] expiry;
        // Extra data for options providers
        bytes[] externalData;
    }

    // Struct used to collect profits from options purchase
    struct CollectRewards {
        // System epoch
        uint256 currentEpoch;
        // Array of providers
        IOption[] providers;
        // Extra data for options providers
        bytes[] externalData;
    }

    // Deposits into OptionStrategy to execute options logic
    struct Budget {
        // Deposits to buy options
        uint128 totalDeposits;
        uint128 bullDeposits;
        uint128 bearDeposits;
        // Profits from options
        uint128 bullEarned;
        uint128 bearEarned;
        uint128 totalEarned;
    }

    struct DifferenceAndOverpaying {
        // Strike (eg: 1800e8)
        uint256 strikePrice;
        // How much it costs to buy strike
        uint256 strikeCost;
        // Amount of collateral going to given strike
        uint256 collateral;
        // ToFarm -> only in case options prices are now cheaper
        uint256 toFarm;
        // true -> means options prices are now higher than when strategy was executed
        // If its false, we are purchasing same amount of options with less collateral and sending extra to farm
        bool isOverpaying;
    }

    function deposit(uint256 _epoch, uint256 _amount, uint256 _bullDeposits, uint256 _bearDeposits) external;
    function middleEpochOptionsBuy(
        uint256 _epoch,
        IRouter.OptionStrategy _type,
        IOption _provider,
        uint256 _collateralAmount,
        uint256 _strike
    ) external returns (uint256);
    function afterMiddleEpochOptionsBuy(IRouter.OptionStrategy _type, uint256 _collateralAmount) external;
    function optionPosition(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (uint256);
    function deltaPrice(uint256 _epoch, uint256 usersAmountOfLp, IOption _provider)
        external
        view
        returns (DifferenceAndOverpaying[] memory);
    function dopexAdapter(IOption.OPTION_TYPE) external view returns (IOption);
    function startCrabStrategy(IRouter.OptionStrategy _strategyType, uint256 _epoch) external;
    function getBullProviders(uint256 epoch) external view returns (IOption[] memory);
    function getBearProviders(uint256 epoch) external view returns (IOption[] memory);
    function executeBullStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute) external;
    function executeBearStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute) external;
    function collectRewards(IOption.OPTION_TYPE _type, CollectRewards calldata _collect, bytes memory _externalData)
        external
        returns (uint256);
    function getBoughtStrikes(uint256 _epoch, IOption _provider) external view returns (Strike[] memory);
    function addBoughtStrikes(uint256 _epoch, IOption _provider, Strike memory _data) external;
    function updateOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike, Strike memory _data) external;
    function settleOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike) external;
    function borrowedLP(IRouter.OptionStrategy _type) external view returns (uint256);
    function executedStrategy(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {ICompoundStrategy} from "src/strategies/CompoundStrategy.sol";
import {IOptionStrategy} from "src/strategies/OptionStrategy.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IRouter} from "src/interfaces/IRouter.sol";

interface IViewer {
    struct Addresses {
        ICompoundStrategy compoundStrategy;
        IOptionStrategy optionStrategy;
        IRouter router;
    }

    /**
     *
     * @param _oldStrategy Current user's deposited strategy
     * @param _newStrategy New strategy user will be depositing
     * @param _user User that signaled flip
     * @param _targetEpoch User's corresponding flip epoch
     */
    function getFlipSignal(
        IRouter.OptionStrategy _oldStrategy,
        IRouter.OptionStrategy _newStrategy,
        address _user,
        uint256 _targetEpoch,
        address lp
    ) external view returns (IRouter.FlipSignal memory);

    /**
     * @param _strategy Bull/Bear/Crab
     * @param _targetEpoch Epoch the user will get his withdrawal
     * @param _user Owner of the assets
     * @return Struct with the user's signal information
     */
    function getWithdrawalSignal(IRouter.OptionStrategy _strategy, uint256 _targetEpoch, address _user, address lp)
        external
        view
        returns (IRouter.WithdrawalSignal memory);

    /**
     * @notice Get the vaults addresses
     * @param _strategy Bull/Bear/Crab
     * @return return the corresponding vault to given strategy type
     */
    function vaultAddresses(IRouter.OptionStrategy _strategy, address lp) external view returns (ILPVault);

    /**
     * @return Return the current Compound Strategy's epoch
     */
    function getEpochData(uint256 _epoch, address lp) external view returns (ICompoundStrategy.Epoch memory);

    /**
     * @return Returns the number of the current epoch
     */
    function currentEpoch(address lp) external view returns (uint256);

    /**
     * @param _strategy Bull/Bear/Crab
     * @return Amount of assets of the given vault
     */
    function totalAssets(IRouter.OptionStrategy _strategy, address lp) external view returns (uint256);

    /**
     * @param _strategy Bull/Bear/Crab
     * @param _user User that owns the shares
     * @return Amount of shares for given user
     */
    function balanceOf(IRouter.OptionStrategy _strategy, address _user, address lp) external view returns (uint256);

    /**
     * @param _strategy Bull/Bear/Crab
     * @param _amount Amount of shares
     * @return Amount of assets that will be received
     * @return Amount of incentive retention
     */
    function previewRedeem(IRouter.OptionStrategy _strategy, uint256 _amount, address lp)
        external
        view
        returns (uint256, uint256);

    /**
     * @param _strategy Bull/Bear/Crab
     * @param _amount Amount of assets
     * @return Amount of shares that will be received
     */
    function previewDeposit(IRouter.OptionStrategy _strategy, uint256 _amount, address lp)
        external
        view
        returns (uint256);

    /**
     * @param lp Address of the underlying LP token of given metavault.
     * @return addresses of the desired metavault
     */
    function getMetavault(address lp) external view returns (Addresses memory);

    /**
     * @param _newAddresses update Metavaults V2 contracts
     */
    function setAddresses(address lp, Addresses memory _newAddresses) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ISSOV {
    struct Addresses {
        address feeStrategy;
        address stakingStrategy;
        address optionPricing;
        address priceOracle;
        address volatilityOracle;
        address feeDistributor;
        address optionsTokenImplementation;
    }

    struct EpochData {
        bool expired;
        uint256 startTime;
        uint256 expiry;
        uint256 settlementPrice;
        uint256 totalCollateralBalance; // Premium + Deposits from all strikes
        uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
        uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
        uint256[] strikes;
        uint256[] totalRewardsCollected;
        uint256[] rewardDistributionRatios;
        address[] rewardTokensToDistribute;
    }

    struct EpochStrikeData {
        address strikeToken;
        uint256 totalCollateral;
        uint256 activeCollateral;
        uint256 totalPremiums;
        uint256 checkpointPointer;
        uint256[] rewardStoredForPremiums;
        uint256[] rewardDistributionRatiosForPremiums;
    }

    struct VaultCheckpoint {
        uint256 activeCollateral;
        uint256 totalCollateral;
        uint256 accruedPremium;
    }

    struct WritePosition {
        uint256 epoch;
        uint256 strike;
        uint256 collateralAmount;
        uint256 checkpointIndex;
        uint256[] rewardDistributionRatios;
    }

    function expire() external;

    function deposit(uint256 strikeIndex, uint256 amount, address user) external returns (uint256 tokenId);

    function purchase(uint256 strikeIndex, uint256 amount, address user)
        external
        returns (uint256 premium, uint256 totalFee);

    function settle(uint256 strikeIndex, uint256 amount, uint256 epoch, address to) external returns (uint256 pnl);

    function withdraw(uint256 tokenId, address to)
        external
        returns (uint256 collateralTokenWithdrawAmount, uint256[] memory rewardTokenWithdrawAmounts);

    function getUnderlyingPrice() external view returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function getVolatility(uint256 _strike) external view returns (uint256);

    function calculatePremium(uint256 _strike, uint256 _amount, uint256 _expiry)
        external
        view
        returns (uint256 premium);

    function calculatePnl(uint256 price, uint256 strike, uint256 amount, uint256 collateralExchangeRate)
        external
        pure
        returns (uint256);

    function calculatePurchaseFees(uint256 strike, uint256 amount) external view returns (uint256);

    function calculateSettlementFees(uint256) external view returns (uint256);

    function getEpochTimes(uint256 epoch) external view returns (uint256 start, uint256 end);

    function writePosition(uint256 tokenId)
        external
        view
        returns (
            uint256 epoch,
            uint256 strike,
            uint256 collateralAmount,
            uint256 checkpointIndex,
            uint256[] memory rewardDistributionRatios
        );

    function getEpochStrikeTokens(uint256 epoch) external view returns (address[] memory);

    function getEpochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function getLastVaultCheckpoint(uint256 epoch, uint256 strike) external view returns (VaultCheckpoint memory);

    function underlyingSymbol() external returns (string memory);

    function isPut() external view returns (bool);

    function addresses() external view returns (Addresses memory);

    function collateralToken() external view returns (IERC20);

    function currentEpoch() external view returns (uint256);

    function expireDelayTolerance() external returns (uint256);

    function collateralPrecision() external returns (uint256);

    function getEpochData(uint256 epoch) external view returns (EpochData memory);

    function epochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function balanceOf(address owner) external view returns (uint256);

    // Dopex management only
    function expire(uint256 _settlementPrice, uint256 _settlementCollateralExchangeRate) external;

    function bootstrap(uint256[] memory strikes, uint256 expiry, string memory expirySymbol) external;

    function addToContractWhitelist(address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {MiniChefV2Adapter} from "src/adapters/MiniChefV2Adapter.sol";
import {SushiSwapAdapter} from "src/adapters/SushiSwapAdapter.sol";
import {UniV2PairAdapter} from "src/adapters/UniV2PairAdapter.sol";
import {DopexAdapter} from "src/adapters/DopexAdapter.sol";
import {CompoundStrategy} from "src/strategies/CompoundStrategy.sol";
import {OptionStrategy} from "src/strategies/OptionStrategy.sol";
import {LPBaseVault} from "src/vault/LPBaseVault.sol";

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";
import {ILpsRegistry} from "src/interfaces/common/ILpsRegistry.sol";

interface IFactory {
    enum Stage {
        NON_CREATED,
        CREATED,
        CONFIGURED,
        OBSOLETE
    }

    struct InitParams {
        address _keeper;
        address _creator;
        address _manager;
        address _registry;
        address _viewer;
        address _zap;
        address _incentiveReceiver;
        uint256 _slippage;
        uint256 _maxRisk;
        uint256 _premium;
        uint256 _retentionIncentive;
    }

    struct CreateParams {
        address _underlyingToken;
        string _bullName;
        string _bearName;
        string _crabName;
    }

    // External
    function create(CreateParams memory params) external returns (uint256);
    function setup(uint256 _nonce) external;

    // View
    function registry() external view returns (ILpsRegistry);
    function getMetavault(uint256 _nonce) external view returns (address[] memory);

    // Only Gov
    function changeStage(address underlyingAddress, Stage _stage) external;
    function updateGov(address _gov) external;
    function updateCreator(address _creator) external;
    function updateRegistry(address _registry) external;
    function updateKeeper(address _keeper) external;
    function updateManager(address _manager) external;
    function updateSlippage(uint256 _slippage) external;
    function updateMaxRisk(uint256 _maxRisk) external;
    function updatePremium(uint256 _premium) external;
    function pressToggle() external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableOperableKeepable} from "src/common/UpgradeableOperableKeepable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable-contracts/security/ReentrancyGuardUpgradeable.sol";
import {IWeth} from "src/interfaces/common/IWeth.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";
import {IZapUniV2} from "src/interfaces/swap/IZapUniV2.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {ILP} from "src/interfaces/ILP.sol";

/**
 * @title ZapUniV2
 * @author JonesDAO
 * @notice Go from whitelisted assets to LP tokens and deposit into our strategies.
 */
contract ZapUniV2 is UpgradeableOperableKeepable, ReentrancyGuardUpgradeable, IZapUniV2 {
    //////////////////////////////////////////////////////////
    //                  INTERNAL DATA STRUCTURES
    //////////////////////////////////////////////////////////

    struct Metavault {
        bool allowed;
        ILP pairAdapter;
        IRouter router;
        ISwap swapper;
        address token0;
        address token1;
    }

    //////////////////////////////////////////////////////////
    //                  CONSTANTS
    //////////////////////////////////////////////////////////

    // @notice Wrapped Ether inherits @erc20
    IWeth private constant WETH = IWeth(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    //////////////////////////////////////////////////////////
    //                  STORAGE
    //////////////////////////////////////////////////////////

    // @notice Store deployed metavaults information
    // @param LP address
    // @returns Metavault struct
    mapping(address => Metavault) private getMetavault;

    //////////////////////////////////////////////////////////
    //                  INIT
    //////////////////////////////////////////////////////////

    function initialize() external initializer {
        __Governable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    //////////////////////////////////////////////////////////
    //                  ZAP!
    //////////////////////////////////////////////////////////

    /**
     * @notice Performs ZAP from asset to LP and deposits into the chosen Metavault.
     * @param pair Address of the liquidity pool for a given pair.
     * @param native Should be true if depositing native ETH
     * @param tokenIn Asset that will be zapped, can be any if `native` = true
     * @param amount Amount of assets that will be deposited
     * @return Amount of shares received
     */
    function zapIn(
        address pair,
        bool native,
        address tokenIn,
        uint256 amount,
        IRouter.OptionStrategy strategy,
        bool instant
    ) external payable nonReentrant returns (uint256) {
        // Checks if there is a Metavault for the given LP and returns it
        Metavault memory metavault = _getMetavault(pair);

        uint256 token0Amount;
        uint256 token1Amount;

        address token0 = metavault.token0;
        address token1 = metavault.token1;

        // If its not ETH nor WETH, convert half to WETH
        if (!native) {
            // Assert that tokenIn is part of the LP
            _verifyTokenIn(tokenIn, token0, token1);

            IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);

            (token0Amount, token1Amount) = _zapIn(tokenIn, metavault, amount);
        } else {
            WETH.deposit{value: msg.value}();

            (token0Amount, token1Amount) = _zapIn(address(WETH), metavault, msg.value);
        }

        uint256 received = _addLiquidity(metavault.pairAdapter, token0, token1, token0Amount, token1Amount);

        IERC20(pair).approve(address(metavault.router), received);

        uint256 shares = metavault.router.deposit(received, strategy, instant, msg.sender);

        emit ZapIn(tokenIn, native, amount, strategy);

        return shares;
    }

    //////////////////////////////////////////////////////////
    //                  OWNER
    //////////////////////////////////////////////////////////

    function setMetavault(address pair, address router, address swapper, address pairAdapter)
        external
        onlyOperatorOrKeeper
    {
        if (pair == address(0) || router == address(0) || swapper == address(0)) {
            revert ZeroAddress();
        }

        IUniswapV2Pair pair_ = IUniswapV2Pair(pair);

        address token0 = pair_.token0();
        address token1 = pair_.token1();

        getMetavault[pair] = Metavault({
            router: IRouter(router),
            allowed: true,
            token0: token0,
            token1: token1,
            swapper: ISwap(swapper),
            pairAdapter: ILP(pairAdapter)
        });

        emit UpdateMetavault(pair, true);
    }

    function retireMetavault(address pair) external onlyOperatorOrKeeper {
        getMetavault[pair].allowed = false;

        emit UpdateMetavault(pair, false);
    }

    function rescue(address tokenIn, uint256 amount, bool native) external onlyGovernor {
        if (native) {
            (bool success,) = payable(msg.sender).call{value: amount}("");
            if (!success) {
                revert CallFailed();
            }
        } else {
            IERC20(tokenIn).transfer(msg.sender, amount);
        }

        emit Rescue(tokenIn, native, amount);
    }

    //////////////////////////////////////////////////////////
    //                  VIEW
    //////////////////////////////////////////////////////////

    function getMetavaultInfo(address lp) external view returns (Metavault memory) {
        return _getMetavault(lp);
    }

    //////////////////////////////////////////////////////////
    //                  PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////

    function _zapIn(address tokenIn, Metavault memory metavault, uint256 amount)
        private
        returns (uint256 token0Amount, uint256 token1Amount)
    {
        if (tokenIn == metavault.token0) {
            token0Amount = amount / 2;
            token1Amount = _performSwap(metavault.swapper, tokenIn, metavault.token1, amount / 2);
        } else {
            token0Amount = _performSwap(metavault.swapper, tokenIn, metavault.token0, amount / 2);
            token1Amount = amount / 2;
        }
    }

    function _performSwap(ISwap swapper, address tokenIn, address tokenOut, uint256 amountIn)
        private
        returns (uint256)
    {
        // Build transaction
        // 0 slippage so uses swapper's default
        ISwap.SwapData memory swapData = ISwap.SwapData(tokenIn, tokenOut, amountIn, "");

        IERC20(tokenIn).approve(address(swapper), amountIn);

        uint256 received = swapper.swap(swapData);

        return received;
    }

    function _addLiquidity(ILP pairAdapter, address token0, address token1, uint256 amount0, uint256 amount1)
        private
        returns (uint256)
    {
        IERC20(token0).approve(address(pairAdapter), amount0);
        IERC20(token1).approve(address(pairAdapter), amount1);

        uint256 received = pairAdapter.buildWithBothTokens(token0, token1, amount0, amount1);

        return received;
    }

    function _verifyTokenIn(address tokenIn, address token0, address token1) private pure {
        if (tokenIn != token0 && tokenIn != token1) {
            revert NotPartOfTheLp(tokenIn);
        }
    }

    function _getMetavault(address pair) private view returns (Metavault memory) {
        Metavault memory metavault = getMetavault[pair];

        if (metavault.allowed) {
            return metavault;
        }

        revert NoMetavault(pair);
    }

    //////////////////////////////////////////////////////////
    //                  ERRORS
    //////////////////////////////////////////////////////////

    error NoMetavault(address pair);
    error NotPartOfTheLp(address token);
    error CallFailed();
    error ZeroAddress();

    //////////////////////////////////////////////////////////
    //                  EVENTS
    //////////////////////////////////////////////////////////

    event Rescue(address tokenOut, bool native, uint256 amount);
    event UpdateMetavault(address indexed pair, bool indexed allowed);
    event ZapIn(address tokenIn, bool native, uint256 amount, IRouter.OptionStrategy indexed strategy);

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {AccessControlUpgradeable} from "openzeppelin-upgradeable-contracts/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(GOVERNOR, _governor);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external virtual onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

interface IDiamond {
    enum BeaconCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct BeaconCut {
        address beaconAddress;
        BeaconCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(BeaconCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.
pragma solidity ^0.8.10;

import {LibDiamond} from "src/libraries/diamond/LibDiamond.sol";
import {IDiamondCut} from "src/interfaces/diamond/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/diamond/IDiamondLoupe.sol";
import {IERC173} from "src/interfaces/diamond/IERC173.sol";
import {IERC165} from "src/interfaces/diamond/IERC165.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

// This is used in diamond constructor
// more arguments are added to this struct
// this avoids stack too deep errors
struct DiamondArgs {
    address init;
    bytes initCalldata;
    address owner;
}

contract BeaconDiamond {
    constructor(IDiamondCut.BeaconCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

        // Code can be added here to perform actions and set state variables.
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

    /* -------------------------------------------------------------------------- */
    /*                                   Internal                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}

    function _fallback() internal virtual {
        _beforeFallback();
        address impl = LibDiamond._implementation();
        if (impl == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        _delegate(impl);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ISwap {
    struct SwapData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        bytes externalData;
    }

    function swap(SwapData memory) external returns (uint256);
    function batchSwap(SwapData[] memory) external returns (uint256[] memory);
    function swapTokensToEth(address _token, uint256 _amount) external;

    event AdapterSwap(
        address indexed swapper,
        address tokenIn,
        address tokenOut,
        address receiver,
        uint256 amountIn,
        uint256 amountOut
    );

    error NotImplemented();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {UpgradeableOperableKeepable} from "src/common/UpgradeableOperableKeepable.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IFarm} from "src/interfaces/IFarm.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";

contract CompoundStrategy is ICompoundStrategy, UpgradeableOperableKeepable {
    using FixedPointMathLib for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Internal representation of 100%
    uint256 private constant BASIS = 1e12;

    // @notice Current system epoch
    uint256 public currentEpoch;

    // @notice Max % of projected farm rewards used to buy options. Backstop for safety measures
    uint256 private maxRisk;

    // @notice Retention charged on withdrawals
    uint256 public retentionIncentive;

    // @notice Incentives target contract
    address public incentiveReceiver;

    // @dev Mapping of Epoch number -> Epoch struct that contains data about a given epoch
    mapping(uint256 => Epoch) private epoch;

    // @notice Each vault has its own balance
    mapping(IRouter.OptionStrategy => uint256) private vaultBalance;

    // @notice The LP token for this current Metavault
    IERC20 public lpToken;

    // @notice Product router
    IRouter private router;

    // @notice Vaults for the different strategies
    ILPVault[] public vaults;

    // @notice Lp farm adapter (eg: MinichefV2 adapter)
    IFarm private farm;

    // @notice The OptionStrategy contract that manages purchasing/settling options
    IOptionStrategy private option;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initializes CompoundStrategy transparent upgradeable proxy
     * @param _farm Lp farm adapter (eg: MinichefV2 adapter)
     * @param _option The OptionStrategy contract that manages purchasing/settling options
     * @param _router Product router
     * @param _vaults Vaults for the different strategies
     * @param _lpToken The LP token for this current Metavault
     * @param _maxRisk Max % of projected farm rewards used to buy options. Backstop for safety measuresco
     */
    function initializeCmpStrategy(
        IFarm _farm,
        IOptionStrategy _option,
        IRouter _router,
        ILPVault[] memory _vaults,
        address _lpToken,
        uint256 _maxRisk
    ) external initializer {
        __Governable_init(msg.sender);

        IERC20 lpToken_ = IERC20(_lpToken);

        lpToken = IERC20(_lpToken);

        maxRisk = _maxRisk;

        router = _router;

        vaults.push(_vaults[0]);
        vaults.push(_vaults[1]);
        vaults.push(_vaults[2]);

        farm = _farm;
        option = _option;

        // Farm approve
        lpToken_.approve(address(_farm), type(uint256).max);

        // Option approve
        lpToken_.approve(address(_option), type(uint256).max);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OPERATOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Handles LPs deposits accountability and staking
     * @param _amount Amount of LP tokens being deposited
     * @param _type Strategy which balance will be updated
     * @param _nextEpoch signal to not increase the balance of the vault immidiatly.
     */
    function deposit(uint256 _amount, IRouter.OptionStrategy _type, bool _nextEpoch) external onlyOperator {
        if (!_nextEpoch) {
            vaultBalance[_type] += _amount;
        }

        lpToken.approve(address(farm), _amount);

        // Stake the LP token
        farm.stake(_amount);

        // Send dust reward token to farm
        IERC20 rewardToken = farm.rewardToken();
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (rewardBalance > 0) {
            rewardToken.transfer(address(farm), rewardBalance);
        }
    }

    /**
     * @notice Withdraw LP assets.
     * @param _amountWithPenalty Amount to unstake
     * @param _receiver Who will receive the LP token
     */
    function instantWithdraw(uint256 _amountWithPenalty, IRouter.OptionStrategy _type, address _receiver)
        external
        onlyOperator
    {
        vaultBalance[_type] = vaultBalance[_type] > _amountWithPenalty ? vaultBalance[_type] - _amountWithPenalty : 0;
        farm.unstake(_amountWithPenalty, _receiver);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ONLY KEEPER                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Auto compounds all the farming rewards.
     */
    function autoCompound() external onlyOperatorOrKeeper {
        _autoCompound();
    }

    /**
     * @notice Start new epoch.
     */
    function startEpoch(uint64 epochExpiry, uint64 optionBullRisk, uint64 optionBearRisk)
        external
        onlyOperatorOrKeeper
    {
        // Stack too deep
        StartEpochInfo memory epochInfo;

        // Make sure last epoch finished
        // Only check if its not first epoch from this product
        epochInfo.epoch = currentEpoch;
        if (epoch[epochInfo.epoch].endTime == 0 && epochInfo.epoch > 0) {
            revert EpochOngoing();
        }

        // Next Epoch!
        unchecked {
            ++currentEpoch;
        }

        epochInfo.epoch = currentEpoch;

        // Review option risk
        if (optionBullRisk > maxRisk || optionBearRisk > maxRisk) {
            revert OutOfRange();
        }

        // Save the ratios (for APY)
        epochInfo.bullRatio = vaults[0].previewRedeem(BASIS);
        epochInfo.bearRatio = vaults[1].previewRedeem(BASIS);
        epochInfo.crabRatio = vaults[2].previewRedeem(BASIS);

        epochInfo.thisAddress = address(this);

        IERC20 _lpToken = lpToken;

        epochInfo.currentLPBalance = _lpToken.balanceOf(epochInfo.thisAddress);
        epochInfo.farmBalance = farm.balance();

        epochInfo.initialBalanceSnapshot = epochInfo.farmBalance + epochInfo.currentLPBalance;

        // Get total and indiviual vault balance (internal accounting)
        epochInfo.bullAssets = vaultBalance[IRouter.OptionStrategy.BULL];
        epochInfo.bearAssets = vaultBalance[IRouter.OptionStrategy.BEAR];
        epochInfo.crabAssets = vaultBalance[IRouter.OptionStrategy.CRAB];
        epochInfo.totalBalance = epochInfo.bullAssets + epochInfo.bearAssets + epochInfo.crabAssets;

        // Get how much LP belongs to strategy, then apply bull/bear risk
        epochInfo.bullAmount = epochInfo.totalBalance > 0
            ? epochInfo.initialBalanceSnapshot.mulDivDown(epochInfo.bullAssets, epochInfo.totalBalance).mulDivDown(
                optionBullRisk, BASIS
            )
            : 0;

        // Get how much LP belongs to strategy, then apply bull/bear risk
        epochInfo.bearAmount = epochInfo.totalBalance > 0
            ? epochInfo.initialBalanceSnapshot.mulDivDown(epochInfo.bearAssets, epochInfo.totalBalance).mulDivDown(
                optionBullRisk, BASIS
            )
            : 0;

        // Sum amounts to get how much LP are going to be broken in order to buy options
        epochInfo.toOptions = epochInfo.bullAmount + epochInfo.bearAmount;

        // If we do not have enough LP tokens to buy desired OptionAmount, we unstake some
        if (epochInfo.currentLPBalance < epochInfo.toOptions) {
            if (epochInfo.farmBalance == 0) {
                revert InsufficientFunds();
            }

            farm.unstake(epochInfo.toOptions - epochInfo.currentLPBalance, epochInfo.thisAddress);
        }

        // Reduce assets used to purchase options from vault balances
        vaultBalance[IRouter.OptionStrategy.BULL] = vaultBalance[IRouter.OptionStrategy.BULL] - epochInfo.bullAmount;
        vaultBalance[IRouter.OptionStrategy.BEAR] = vaultBalance[IRouter.OptionStrategy.BEAR] - epochInfo.bearAmount;

        // Deposit LP amount to Option Strategy
        if (epochInfo.toOptions > 0) {
            _lpToken.transfer(address(option), epochInfo.toOptions);
            option.deposit(epochInfo.epoch, epochInfo.toOptions, epochInfo.bullAmount, epochInfo.bearAmount);
        }
        // Balance after transfer to buy options
        epochInfo.currentLPBalance = _lpToken.balanceOf(epochInfo.thisAddress);

        // Stake whats left
        if (epochInfo.currentLPBalance > 0) {
            farm.stake(epochInfo.currentLPBalance);
        }

        uint64 epochInit = uint64(block.timestamp);

        epoch[epochInfo.epoch] = Epoch(
            epochInit,
            epochExpiry,
            0,
            optionBullRisk,
            optionBearRisk,
            uint128(epochInfo.bullRatio),
            uint128(epochInfo.bearRatio),
            uint128(epochInfo.crabRatio),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        emit StartEpoch(
            epochInfo.epoch,
            epochInit,
            epochExpiry,
            epochInfo.toOptions,
            epochInfo.bullAssets,
            epochInfo.bearAssets,
            epochInfo.crabAssets
        );
    }

    /**
     * @notice Finish current epoch.
     */
    function endEpoch() external onlyOperatorOrKeeper {
        _autoCompound();

        // Stack too deep
        GeneralInfo memory generalInfo;

        generalInfo.currentEpoch = currentEpoch;
        generalInfo.endTime = block.timestamp;
        generalInfo.epochData = epoch[generalInfo.currentEpoch];

        // Make sure Epoch has ended
        if (generalInfo.endTime < generalInfo.epochData.virtualEndTime) {
            revert EpochOngoing();
        }
        // Load to memory to save some casts
        generalInfo.thisAddress = address(this);
        generalInfo.routerAddress = address(router);

        generalInfo.bullVault = vaults[0];
        generalInfo.bearVault = vaults[1];
        generalInfo.crabVault = vaults[2];

        generalInfo.router = router;
        generalInfo.lpToken = lpToken;

        generalInfo.bullStrat = IRouter.OptionStrategy.BULL;
        generalInfo.bearStrat = IRouter.OptionStrategy.BEAR;
        generalInfo.crabStrat = IRouter.OptionStrategy.CRAB;

        // Flip
        FlipInfo memory flipInfo = _flip(generalInfo);

        // Withdraw Signals

        WithdrawInfo memory withdrawInfo = _withdraw(generalInfo);

        // Flip & Withdraw Rates

        flipInfo.bullToBearRate =
            flipInfo.bullToBear > 0 ? flipInfo.bullToBearShares.mulDivDown(1e30, flipInfo.bullToBear) : 0;
        flipInfo.bullToCrabRate =
            flipInfo.bullToCrab > 0 ? flipInfo.bullToCrabShares.mulDivDown(1e30, flipInfo.bullToCrab) : 0;
        flipInfo.bearToBullRate =
            flipInfo.bearToBull > 0 ? flipInfo.bearToBullShares.mulDivDown(1e30, flipInfo.bearToBull) : 0;
        flipInfo.bearToCrabRate =
            flipInfo.bearToCrab > 0 ? flipInfo.bearToCrabShares.mulDivDown(1e30, flipInfo.bearToCrab) : 0;
        flipInfo.crabToBullRate =
            flipInfo.crabToBull > 0 ? flipInfo.crabToBullShares.mulDivDown(1e30, flipInfo.crabToBull) : 0;
        flipInfo.crabToBearRate =
            flipInfo.crabToBear > 0 ? flipInfo.crabToBearShares.mulDivDown(1e30, flipInfo.crabToBear) : 0;

        withdrawInfo.withdrawBullRate = withdrawInfo.bullShares > 0
            ? (withdrawInfo.bullAssets - withdrawInfo.bullRetention).mulDivDown(BASIS, withdrawInfo.bullShares)
            : 0;
        withdrawInfo.withdrawBearRate = withdrawInfo.bearShares > 0
            ? (withdrawInfo.bearAssets - withdrawInfo.bearRetention).mulDivDown(BASIS, withdrawInfo.bearShares)
            : 0;

        // Next Epoch Deposits

        DepositInfo memory depositInfo = _deposit(generalInfo);

        // Update router accounting (refresh epoch)
        generalInfo.router.executeFinishEpoch();

        epoch[currentEpoch] = Epoch(
            generalInfo.epochData.startTime,
            generalInfo.epochData.virtualEndTime,
            uint64(generalInfo.endTime),
            generalInfo.epochData.optionBullRisk,
            generalInfo.epochData.optionBearRisk,
            generalInfo.epochData.initialBullRatio,
            generalInfo.epochData.initialBearRatio,
            generalInfo.epochData.initialCrabRatio,
            uint128(withdrawInfo.withdrawBullRate),
            uint128(withdrawInfo.withdrawBearRate),
            uint128(flipInfo.bullToBearRate),
            uint128(flipInfo.bullToCrabRate),
            uint128(flipInfo.bearToBullRate),
            uint128(flipInfo.bearToCrabRate),
            uint128(flipInfo.crabToBullRate),
            uint128(flipInfo.crabToBearRate),
            uint128(depositInfo.depositBullRate),
            uint128(depositInfo.depositBearRate),
            uint128(generalInfo.bullVault.previewRedeem(BASIS)),
            uint128(generalInfo.bearVault.previewRedeem(BASIS)),
            uint128(generalInfo.crabVault.previewRedeem(BASIS))
        );

        emit EndEpoch(generalInfo.currentEpoch, generalInfo.endTime, withdrawInfo.totalSignals, withdrawInfo.retention);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get epoch Data.
     */
    function epochData(uint256 _number) external view returns (Epoch memory) {
        return epoch[_number];
    }

    /**
     * @notice Get Strategy Assets; farm + here
     */
    function totalAssets() public view returns (uint256) {
        return farm.balance() + lpToken.balanceOf(address(this));
    }

    /**
     * @notice Get the three strategy Vaults; 0 => BULL, 1 => BEAR, 2 => CRAB
     */
    function getVaults() external view returns (ILPVault[] memory) {
        return vaults;
    }

    /**
     * @notice Get LP Vault Assets, overall LP for a Vault.
     */
    function vaultAssets(IRouter.OptionStrategy _type) external view returns (uint256) {
        if (_type != IRouter.OptionStrategy.CRAB) {
            // get pnl over lp that was spend to bought options
            try option.optionPosition(currentEpoch, _type) returns (uint256 pnl) {
                // also add amount of LP that was spend to bought options and pending farm rewards
                return vaultBalance[_type] + _vaultPendingRewards(_type) + pnl + option.borrowedLP(_type);
            } catch {
                return vaultBalance[_type] + _vaultPendingRewards(_type) + option.borrowedLP(_type);
            }
        } else {
            return vaultBalance[_type] + _vaultPendingRewards(_type);
        }
    }

    function getVaultBalance(IRouter.OptionStrategy _type) external view returns (uint256) {
        return vaultBalance[_type];
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Update Max Option Risk
     */
    function updateRisk(uint256 _maxRisk) external onlyGovernor {
        maxRisk = _maxRisk;
    }

    /**
     * @notice Update Router
     */
    function updateRouter(IRouter _router) external onlyGovernor {
        router = _router;
    }

    /**
     * @notice Update Option Strategy
     */
    function updateOption(address _option) external onlyGovernor {
        IERC20 _lpToken = lpToken;
        _lpToken.approve(address(option), 0);
        // New Option
        option = IOptionStrategy(_option);
        _lpToken.approve(_option, type(uint256).max);
    }

    /**
     * @notice Update Farm adapter
     */
    function updateFarm(address _farm) external onlyGovernor {
        farm.exit();
        lpToken.approve(address(farm), 0);
        // New Farm
        farm = IFarm(_farm);
        lpToken.approve(_farm, type(uint256).max);
        farm.stake(lpToken.balanceOf(address(this)));
    }

    /**
     * @notice Set UP incentive receiver and retention percentage.
     */
    function setUpIncentives(address _incentiveReceiver, uint256 _retentionIncentive) external onlyGovernor {
        incentiveReceiver = _incentiveReceiver;
        retentionIncentive = _retentionIncentive;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
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
    /*                                     PRIVATE                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get Vault proportional pending rewards from farm.
     */
    function _vaultPendingRewards(IRouter.OptionStrategy _type) private view returns (uint256) {
        try farm.pendingRewardsToLP() returns (uint256 pendingRewards) {
            return _vaultPortion(pendingRewards, _type);
        } catch {
            return 0;
        }
    }

    /**
     * @notice Given an specific amount, return the proportion for a specific vault.
     */
    function _vaultPortion(uint256 amount, IRouter.OptionStrategy _type) private view returns (uint256) {
        uint256 totalAssets_ = vaultBalance[IRouter.OptionStrategy.BULL] + vaultBalance[IRouter.OptionStrategy.BEAR]
            + vaultBalance[IRouter.OptionStrategy.CRAB];

        // Avoid underflow risk
        if (totalAssets_ < amount * vaultBalance[_type]) {
            return amount.mulDivDown(vaultBalance[_type], totalAssets_);
        }

        return 0;
    }

    /**
     * @notice Claim and stake farm rewards and update internal accounting.
     */
    function _autoCompound() private {
        // Claim and stake in farm
        uint256 earned = farm.claimAndStake();

        if (earned > 0) {
            // Distribute earning in vault balances
            uint256 bullAssets = vaultBalance[IRouter.OptionStrategy.BULL];
            uint256 bearAssets = vaultBalance[IRouter.OptionStrategy.BEAR];
            uint256 crabAssets = vaultBalance[IRouter.OptionStrategy.CRAB];
            uint256 totalBalance = bullAssets + bearAssets + crabAssets;

            uint256 bullEarned = earned.mulDivDown(bullAssets, totalBalance);
            uint256 bearEarned = earned.mulDivDown(bearAssets, totalBalance);
            uint256 crabEarned = earned - bullEarned - bearEarned;

            vaultBalance[IRouter.OptionStrategy.BULL] = vaultBalance[IRouter.OptionStrategy.BULL] + bullEarned;
            vaultBalance[IRouter.OptionStrategy.BEAR] = vaultBalance[IRouter.OptionStrategy.BEAR] + bearEarned;
            vaultBalance[IRouter.OptionStrategy.CRAB] = vaultBalance[IRouter.OptionStrategy.CRAB] + crabEarned;

            emit AutoCompound(earned, bullEarned, bearEarned, crabEarned, block.timestamp);
        }
    }

    /**
     * @notice Process flip from one vault to other.
     */
    function _flip(GeneralInfo memory generalInfo) private returns (FlipInfo memory flipInfo) {
        // Get flip signals
        flipInfo.bullToBear = generalInfo.router.flipSignals(generalInfo.bullStrat, generalInfo.bearStrat);
        flipInfo.bullToCrab = generalInfo.router.flipSignals(generalInfo.bullStrat, generalInfo.crabStrat);
        flipInfo.bearToBull = generalInfo.router.flipSignals(generalInfo.bearStrat, generalInfo.bullStrat);
        flipInfo.bearToCrab = generalInfo.router.flipSignals(generalInfo.bearStrat, generalInfo.crabStrat);
        flipInfo.crabToBull = generalInfo.router.flipSignals(generalInfo.crabStrat, generalInfo.bullStrat);
        flipInfo.crabToBear = generalInfo.router.flipSignals(generalInfo.crabStrat, generalInfo.bearStrat);

        // Calculate shares per signal
        flipInfo.redeemBullToBearAssets = generalInfo.bullVault.previewRedeem(flipInfo.bullToBear);
        flipInfo.redeemBullToCrabAssets = generalInfo.bullVault.previewRedeem(flipInfo.bullToCrab);
        flipInfo.redeemBearToBullAssets = generalInfo.bearVault.previewRedeem(flipInfo.bearToBull);
        flipInfo.redeemBearToCrabAssets = generalInfo.bearVault.previewRedeem(flipInfo.bearToCrab);
        flipInfo.redeemCrabToBullAssets = generalInfo.crabVault.previewRedeem(flipInfo.crabToBull);
        flipInfo.redeemCrabToBearAssets = generalInfo.crabVault.previewRedeem(flipInfo.crabToBear);

        // Remove all shares & balances
        generalInfo.bullVault.burn(generalInfo.routerAddress, flipInfo.bullToBear + flipInfo.bullToCrab);
        vaultBalance[generalInfo.bullStrat] =
            vaultBalance[generalInfo.bullStrat] - flipInfo.redeemBullToBearAssets - flipInfo.redeemBullToCrabAssets;

        generalInfo.bearVault.burn(generalInfo.routerAddress, flipInfo.bearToBull + flipInfo.bearToCrab);
        vaultBalance[generalInfo.bearStrat] =
            vaultBalance[generalInfo.bearStrat] - flipInfo.redeemBearToBullAssets - flipInfo.redeemBearToCrabAssets;

        generalInfo.crabVault.burn(generalInfo.routerAddress, flipInfo.crabToBull + flipInfo.crabToBear);
        vaultBalance[generalInfo.crabStrat] =
            vaultBalance[generalInfo.crabStrat] - flipInfo.redeemCrabToBullAssets - flipInfo.redeemCrabToBearAssets;

        // Add shares & balances
        flipInfo.bullToBearShares = generalInfo.bearVault.previewDeposit(flipInfo.redeemBullToBearAssets);
        flipInfo.bullToCrabShares = generalInfo.crabVault.previewDeposit(flipInfo.redeemBullToCrabAssets);
        flipInfo.bearToBullShares = generalInfo.bullVault.previewDeposit(flipInfo.redeemBearToBullAssets);
        flipInfo.bearToCrabShares = generalInfo.crabVault.previewDeposit(flipInfo.redeemBearToCrabAssets);
        flipInfo.crabToBearShares = generalInfo.bearVault.previewDeposit(flipInfo.redeemCrabToBearAssets);
        flipInfo.crabToBullShares = generalInfo.bullVault.previewDeposit(flipInfo.redeemCrabToBullAssets);

        generalInfo.bullVault.mint(flipInfo.bearToBullShares + flipInfo.crabToBullShares, generalInfo.routerAddress);
        vaultBalance[generalInfo.bullStrat] =
            vaultBalance[generalInfo.bullStrat] + flipInfo.redeemBearToBullAssets + flipInfo.redeemCrabToBullAssets;

        generalInfo.bearVault.mint(flipInfo.bullToBearShares + flipInfo.crabToBearShares, generalInfo.routerAddress);
        vaultBalance[generalInfo.bearStrat] =
            vaultBalance[generalInfo.bearStrat] + flipInfo.redeemBullToBearAssets + flipInfo.redeemCrabToBearAssets;

        generalInfo.crabVault.mint(flipInfo.bullToCrabShares + flipInfo.bearToCrabShares, generalInfo.routerAddress);
        vaultBalance[generalInfo.crabStrat] =
            vaultBalance[generalInfo.crabStrat] + flipInfo.redeemBullToCrabAssets + flipInfo.redeemBearToCrabAssets;
    }

    /**
     * @notice Process withdraw signals.
     */
    function _withdraw(GeneralInfo memory generalInfo) private returns (WithdrawInfo memory withdrawInfo) {
        // Get withdraw signals
        withdrawInfo.bullShares = generalInfo.router.withdrawSignals(generalInfo.bullStrat);
        withdrawInfo.bearShares = generalInfo.router.withdrawSignals(generalInfo.bearStrat);

        // Calculate assets per signal & total
        withdrawInfo.bullAssets = generalInfo.bullVault.previewRedeem(withdrawInfo.bullShares);
        withdrawInfo.bearAssets = generalInfo.bearVault.previewRedeem(withdrawInfo.bearShares);
        withdrawInfo.totalSignals = withdrawInfo.bullAssets + withdrawInfo.bearAssets;

        // Calculate incentive retention
        withdrawInfo.bullRetention = withdrawInfo.bullAssets.mulDivDown(retentionIncentive, BASIS);
        withdrawInfo.bearRetention = withdrawInfo.bearAssets.mulDivDown(retentionIncentive, BASIS);
        withdrawInfo.retention = withdrawInfo.bullRetention + withdrawInfo.bearRetention;

        withdrawInfo.toTreasury = withdrawInfo.retention.mulDivDown(2, 3);

        withdrawInfo.toPayBack = withdrawInfo.totalSignals - withdrawInfo.retention;

        withdrawInfo.currentBalance = lpToken.balanceOf(generalInfo.thisAddress);

        if (withdrawInfo.currentBalance < withdrawInfo.toPayBack + withdrawInfo.toTreasury) {
            farm.unstake(
                withdrawInfo.toPayBack + withdrawInfo.toTreasury - withdrawInfo.currentBalance, generalInfo.thisAddress
            );
        }

        // payback, send incentives & burn shares
        generalInfo.lpToken.transfer(generalInfo.routerAddress, withdrawInfo.toPayBack);
        generalInfo.lpToken.transfer(incentiveReceiver, withdrawInfo.toTreasury);

        generalInfo.bullVault.burn(generalInfo.routerAddress, withdrawInfo.bullShares);
        generalInfo.bearVault.burn(generalInfo.routerAddress, withdrawInfo.bearShares);
    }

    /**
     * @notice Process next epoch deposits.
     */
    function _deposit(GeneralInfo memory generalInfo) private returns (DepositInfo memory depositInfo) {
        // Get next epoch deposit
        depositInfo.depositBullAssets = generalInfo.router.nextEpochDeposits(generalInfo.bullStrat);
        depositInfo.depositBearAssets = generalInfo.router.nextEpochDeposits(generalInfo.bearStrat);

        // Get calculate their shares
        depositInfo.depositBullShares = generalInfo.bullVault.previewDeposit(depositInfo.depositBullAssets);
        depositInfo.depositBearShares = generalInfo.bearVault.previewDeposit(depositInfo.depositBearAssets);

        // Mint their shares
        generalInfo.bullVault.mint(depositInfo.depositBullShares, generalInfo.routerAddress);
        generalInfo.bearVault.mint(depositInfo.depositBearShares, generalInfo.routerAddress);

        // Calculate rates in order to claim the shares later
        depositInfo.depositBullRate = depositInfo.depositBullAssets > 0
            ? depositInfo.depositBullShares.mulDivDown(1e30, depositInfo.depositBullAssets)
            : 0;

        depositInfo.depositBearRate = depositInfo.depositBearAssets > 0
            ? depositInfo.depositBearShares.mulDivDown(1e30, depositInfo.depositBearAssets)
            : 0;

        // Update vault balances
        vaultBalance[generalInfo.bullStrat] = vaultBalance[generalInfo.bullStrat] + depositInfo.depositBullAssets;
        vaultBalance[generalInfo.bearStrat] = vaultBalance[generalInfo.bearStrat] + depositInfo.depositBearAssets;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event StartEpoch(
        uint256 epoch,
        uint64 startTime,
        uint256 virtualEndTime,
        uint256 optionsAmount,
        uint256 bullDeposits,
        uint256 bearDeposits,
        uint256 crabDeposits
    );
    event EndEpoch(uint256 epoch, uint256 endTime, uint256 withdrawSignals, uint256 retention);
    event AutoCompound(uint256 earned, uint256 bullEarned, uint256 bearEarned, uint256 crabEarned, uint256 timestamp);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error OutOfRange();
    error EpochOngoing();
    error FailSendETH();
    error InsufficientFunds();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {UpgradeableGovernable, UpgradeableOperableKeepable} from "src/common/UpgradeableOperableKeepable.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ILP} from "src/interfaces/ILP.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ISwap} from "src/interfaces/ISwap.sol";

contract OptionStrategy is IOptionStrategy, UpgradeableOperableKeepable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Internal representation of 100%
    uint256 private constant BASIS_POINTS = 1e12;

    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    // @notice The ERC20 LP token for this OptionStrategy's Metavault
    IERC20 public lpToken;

    // @notice Compound Strategy for current Metavault
    // Responsible for handling most of LPs logic
    ICompoundStrategy public compoundStrategy;

    // @notice Pair adapter, used mostly to build/break LPs
    ILP public pairAdapter;

    // @notice Default dex for this Metavault
    ISwap public swapper;

    // @notice Epoch -> Options Provider (Call/Put) -> {Strike settlement price, option cost}
    // if 0 - means we didnt buy any of this strike
    mapping(uint256 => mapping(IOption => Strike[])) public boughtStrikes;

    // @notice Check if the options provider is valid
    mapping(address => bool) public validProvider;

    // @notice Epoch providers
    mapping(uint256 => IOption[]) public bullProviders;
    mapping(uint256 => IOption[]) public bearProviders;

    // @notice Check if OptionStrategy (responsible for the options purchase logic) has been executed
    mapping(uint256 => mapping(IRouter.OptionStrategy => bool)) public executedStrategy;

    // @notice Epoch -> Budget (accoutability of assets distribution across Bull/Bear strategies)
    mapping(uint256 => Budget) public budget;

    // @notice Amount of LP tokens borrowed from strategy to be converted to options
    mapping(IRouter.OptionStrategy => uint256) public borrowedLP;

    // @notice Store collected "yield" for each strategy (Bull/Bear)
    mapping(uint256 => mapping(IOption.OPTION_TYPE => uint256)) public rewards;

    // @notice Get dopex adapter to be used in mid epoch deposits
    mapping(IOption.OPTION_TYPE => IOption) public dopexAdapter;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initializeOpStrategy(address _lp, address _pairAdapter, address _swapper) external initializer {
        __Governable_init(msg.sender);

        if (_lp == address(0) || _pairAdapter == address(0) || _swapper == address(0)) {
            revert ZeroAddress();
        }

        lpToken = IERC20(_lp);
        pairAdapter = ILP(_pairAdapter);
        swapper = ISwap(_swapper);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OPERATOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Deposit Lp assets to buy options.
     * @param _epoch Sytem epoch
     * @param _amount Total amount of assets
     * @param _bullAmount Amount of assets to buy bull options
     * @param _bearAmount Amount of assets to buy bear options
     */
    function deposit(uint256 _epoch, uint256 _amount, uint256 _bullAmount, uint256 _bearAmount) external onlyOperator {
        uint128 amount = uint128(_amount);

        uint128 amountBull = uint128(_bullAmount);
        uint128 amountBear = uint128(_bearAmount);

        Budget memory _budget = budget[_epoch];

        // Updates budget to include current epochs LPs spent in options
        budget[_epoch] = Budget({
            totalDeposits: _budget.totalDeposits + amount,
            bullDeposits: _budget.bullDeposits + amountBull,
            bearDeposits: _budget.bullDeposits + amountBear,
            bullEarned: _budget.bullEarned,
            bearEarned: _budget.bearEarned,
            totalEarned: _budget.totalEarned
        });

        // Increases strategy debt
        borrowedLP[IRouter.OptionStrategy.BULL] = _budget.bullDeposits + amountBull;
        borrowedLP[IRouter.OptionStrategy.BEAR] = _budget.bearDeposits + amountBear;

        emit DebtUpdated(IRouter.OptionStrategy.BULL, _budget.bullDeposits, borrowedLP[IRouter.OptionStrategy.BULL]);
        emit DebtUpdated(IRouter.OptionStrategy.BEAR, _budget.bullDeposits, borrowedLP[IRouter.OptionStrategy.BEAR]);

        emit Deposit(_epoch, _amount, amountBull, amountBear);
    }

    /**
     * @notice Performs an options purchase for user deposit when the strategies have already been executed
     * @param _epoch System epoch
     * @param _type Bull/Bear
     * @param _provider Options provider that is going to be used to buy
     * @param _collateralAmount Amount of LP that is going to be used
     * @param _strike Strike that is going to be bought
     */
    function middleEpochOptionsBuy(
        uint256 _epoch,
        IRouter.OptionStrategy _type,
        IOption _provider,
        uint256 _collateralAmount,
        uint256 _strike
    ) external onlyOperator returns (uint256) {
        uint128 collateralAmount_ = uint128(_collateralAmount);

        // Update budget to add more money spent in options
        Budget storage _budget = budget[_epoch];

        if (_type == IRouter.OptionStrategy.BULL) {
            _budget.bullDeposits = _budget.bullDeposits + collateralAmount_;
        } else {
            _budget.bearEarned = _budget.bearDeposits + collateralAmount_;
        }

        _budget.totalDeposits = _budget.totalDeposits + collateralAmount_;

        // Transfer LP to pairAdapter to perform the LP breaking and swap
        lpToken.transfer(address(pairAdapter), _collateralAmount);

        // Receive WETH from the break and swap process
        uint256 wethAmount = pairAdapter.performBreakAndSwap(_collateralAmount, swapper);

        // After receiving WETH, send ETH to options provider to perform the options purchase
        WETH.transfer(address(_provider), wethAmount);

        // Returns purchasing costs
        return _provider.executeSingleOptionPurchase(_epoch, _strike, wethAmount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                ONLY KEEPER                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Execute bull strategy.
     * @param _epoch Sytem epoch
     * @param _toSpend Total amount of assets (LP) to spend in the execution
     * @param _execute Params to execute the strategy with providers
     */
    function executeBullStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute)
        external
        onlyOperatorOrKeeper
    {
        // Send LP tokens to the pair adapter to handle the LP break/build
        lpToken.safeTransfer(address(pairAdapter), _toSpend);

        ILP.LpInfo memory lpInfo = ILP.LpInfo({swapper: swapper, externalData: ""});

        // Break LP to be used to buy options
        uint256 wethAmount = pairAdapter.breakLP(_toSpend, lpInfo);

        uint256 length = _execute.providers.length;

        if (length != _execute.providerPercentage.length || length != _execute.expiry.length) {
            revert LengthMismatch();
        }

        // To perform the options purchases, we need to have the needed collateral available here, otherwise reverts
        for (uint256 i; i < length;) {
            address providerAddress = address(_execute.providers[i]);

            if (!validProvider[providerAddress]) {
                revert InvalidProvider();
            }

            WETH.transfer(providerAddress, wethAmount.mulDivDown(_execute.providerPercentage[i], BASIS_POINTS));
            // Each provider can have different strikes format, on dopex we pass as the $ value, with 8 decimals
            _execute.providers[i].purchase(
                IOption.ExecuteParams(
                    _epoch,
                    _execute.strikes[i],
                    _execute.collateralEachStrike[i],
                    _execute.expiry[i],
                    _execute.externalData[i]
                )
            );

            unchecked {
                ++i;
            }
        }

        // Add used bull providers
        bullProviders[_epoch] = _execute.providers;
        executedStrategy[_epoch][IRouter.OptionStrategy.BULL] = true;

        emit BullStrategy(_epoch, _toSpend, wethAmount, _execute.providers, _execute.providerPercentage);
    }

    /**
     * @notice In case we decide not to buy options in current epoch for the given strategy, adjust acocuntability and send LP tokens to be auto-compounded
     * @param _strategyType Bull or Bear strategy.
     * @param _epoch Current epoch
     * @dev Only operator or keeper can call this function
     */
    function startCrabStrategy(IRouter.OptionStrategy _strategyType, uint256 _epoch) external onlyOperatorOrKeeper {
        Budget storage _budget = budget[_epoch];

        ICompoundStrategy compoundStrategy_ = compoundStrategy;

        // Original amount that was going to be directed to buy options
        uint256 toBuyOptions;

        // Get budget that was deposited
        if (_strategyType == IRouter.OptionStrategy.BULL) {
            toBuyOptions = _budget.bullDeposits;

            // Set to 0 since we are no longer spending the previous amount
            _budget.bullDeposits = 0;

            // Reduce from total deposits
            _budget.totalDeposits -= uint128(toBuyOptions);
        } else {
            toBuyOptions = _budget.bearDeposits;

            // Set to 0 since we are no longer spending the previous amount
            _budget.bearDeposits = 0;

            // Reduce from total deposits
            _budget.totalDeposits -= uint128(toBuyOptions);
        }

        // Send back the premium that would be used
        lpToken.safeTransfer(address(compoundStrategy_), toBuyOptions);

        // Send back the LP to CompoundStrategy and stake
        // No need to update debt since it was not increased
        compoundStrategy_.deposit(toBuyOptions, _strategyType, false);
        executedStrategy[_epoch][_strategyType] = true;

        emit DebtUpdated(_strategyType, borrowedLP[_strategyType], 0);
        borrowedLP[_strategyType] = 0;
        emit MigrateToCrabStrategy(_strategyType, uint128(toBuyOptions));
    }

    /**
     * @notice Execute bear strategy.
     * @param _epoch System epoch
     * @param _toSpend Total amount of assets to expend in the execution
     * @param _execute Params to execute the strategy with providers
     */
    function executeBearStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute)
        external
        onlyOperatorOrKeeper
    {
        lpToken.safeTransfer(address(pairAdapter), _toSpend);

        ILP.LpInfo memory lpInfo = ILP.LpInfo({swapper: swapper, externalData: ""});

        // Break LP
        uint256 wethAmount = pairAdapter.breakLP(_toSpend, lpInfo);

        uint256 length = _execute.providers.length;

        if (length != _execute.providerPercentage.length || length != _execute.expiry.length) {
            revert LengthMismatch();
        }

        for (uint256 i; i < length;) {
            address providerAddress = address(_execute.providers[i]);

            if (!validProvider[providerAddress]) {
                revert InvalidProvider();
            }

            if (_execute.collateralEachStrike[i].length != _execute.strikes[i].length) revert LengthMismatch();

            WETH.transfer(providerAddress, wethAmount.mulDivDown(_execute.providerPercentage[i], BASIS_POINTS));

            // Each provider can have different strikes format, on dopex we pass as the $ value, with 8 decimals
            _execute.providers[i].purchase(
                IOption.ExecuteParams(
                    _epoch,
                    _execute.strikes[i],
                    _execute.collateralEachStrike[i],
                    _execute.expiry[i],
                    _execute.externalData[i]
                )
            );

            unchecked {
                ++i;
            }
        }

        // Add used bear providers
        bearProviders[_epoch] = _execute.providers;
        executedStrategy[_epoch][IRouter.OptionStrategy.BEAR] = true;

        emit BearStrategy(_epoch, _toSpend, wethAmount, _execute.providers, _execute.providerPercentage);
    }

    /**
     * @notice Collect Option Rewards.
     * @param _type Type of strategy
     * @param _collect Params need to collect rewards
     * @param _externalData In case its needed for the Pair Adapter
     */
    function collectRewards(IOption.OPTION_TYPE _type, CollectRewards calldata _collect, bytes memory _externalData)
        external
        onlyOperatorOrKeeper
        returns (uint256)
    {
        uint256 length = _collect.providers.length;

        uint256 wethCollected;

        // Iterate through providers used this epoch and settle options if pnl > 0
        for (uint256 i; i < length;) {
            address providerAddress = address(_collect.providers[i]);
            if (!validProvider[providerAddress]) {
                revert InvalidProvider();
            }

            if (_type != IOption(_collect.providers[i]).optionType()) {
                revert InvalidType();
            }

            // Store rewards in WETH
            wethCollected = wethCollected
                + _collect.providers[i].settle(
                    IOption.SettleParams(
                        _collect.currentEpoch,
                        IOption(_collect.providers[i]).epochs(_collect.currentEpoch),
                        _collect.externalData[i]
                    )
                );

            unchecked {
                ++i;
            }
        }

        IRouter.OptionStrategy _vaultType =
            _type == IOption.OPTION_TYPE.CALLS ? IRouter.OptionStrategy.BULL : IRouter.OptionStrategy.BEAR;

        emit DebtUpdated(_vaultType, borrowedLP[_vaultType], 0);

        borrowedLP[_vaultType] = 0;

        emit CollectRewardsEpochEnd(_type, wethCollected, _collect.providers);

        if (wethCollected > 0) {
            // If we had a non zero PNL, send to the pair adapter in order to build the LP
            WETH.transfer(address(pairAdapter), wethCollected);

            // Struct containing information to build the LP
            ILP.LpInfo memory lpInfo = ILP.LpInfo({swapper: swapper, externalData: _externalData});

            // Effectively build LP and store amount received
            uint256 lpRewards = pairAdapter.buildLP(wethCollected, lpInfo);

            // Store received LP according to the epoch and strategy
            rewards[_collect.currentEpoch][_type] += lpRewards;

            Budget storage _budget = budget[_collect.currentEpoch];

            // Increase current epochs rewards
            if (_type == IOption.OPTION_TYPE.CALLS) {
                _budget.bullEarned = _budget.bullEarned + uint128(lpRewards);
            } else {
                _budget.bearEarned = _budget.bearEarned + uint128(lpRewards);
            }

            _budget.totalEarned = _budget.totalEarned + uint128(lpRewards);

            // Send profits to CompoundStrategy and stake it
            lpToken.transfer(address(compoundStrategy), lpRewards);
            compoundStrategy.deposit(lpRewards, _vaultType, false);

            return lpRewards;
        } else {
            return 0;
        }
    }

    /**
     * @notice Update Borrowed LP.
     * @param _type Bull/Bear
     * @param _collateralAmount Amount of LP that is going to be used
     */
    function afterMiddleEpochOptionsBuy(IRouter.OptionStrategy _type, uint256 _collateralAmount)
        external
        onlyOperator
    {
        // Increase debt (LP used to buy options)
        borrowedLP[_type] = borrowedLP[_type] + _collateralAmount;

        emit DebtUpdated(_type, borrowedLP[_type] - _collateralAmount, borrowedLP[_type]);
    }

    /**
     * @notice Add new Strike bought.
     * @param _epoch System epoch
     * @param _provider Option provider
     * @param _data Strike data to be add
     */
    function addBoughtStrikes(uint256 _epoch, IOption _provider, Strike memory _data) external onlyOperator {
        Strike[] storage current = boughtStrikes[_epoch][_provider];

        current.push(_data);

        emit AddBoughtStrike(_epoch, _provider, _data);
    }

    /**
     * @notice Settle strike bought.
     * @param _epoch System epoch
     * @param _provider Option provider
     * @param _strike strike to settle
     */
    function settleOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike) external onlyOperator {
        Strike[] storage current = boughtStrikes[_epoch][_provider];
        uint256 length = current.length;

        for (uint256 i; i < length;) {
            if (current[i].price == _strike) {
                current[i].currentOptions = 0;

                emit SettleOptionStrike(_epoch, _provider, current[i]);

                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Update strike bought.
     * @param _epoch System epoch
     * @param _provider Option provider
     * @param _strike strike to update
     * @param _data Strike data to be update
     */
    function updateOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike, Strike memory _data)
        external
        onlyOperator
    {
        Strike[] storage current = boughtStrikes[_epoch][_provider];
        uint256 length = current.length;

        for (uint256 i; i < length;) {
            if (current[i].price == _strike) {
                Strike memory before = current[i];

                current[i] = Strike({
                    price: _strike,
                    costIndividual: _data.costIndividual,
                    costTotal: _data.costTotal,
                    percentageOverTotalCollateral: _data.percentageOverTotalCollateral,
                    currentOptions: _data.currentOptions
                });

                emit UpdateOptionStrike(_epoch, before, current[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets Strike array containing data needed about bought strikes to perform mid epoch ingress
     * @param _epoch System epoch
     * @param _provider Option provider
     * @return Strikes bought and relevant information about them
     */
    function getBoughtStrikes(uint256 _epoch, IOption _provider) external view returns (Strike[] memory) {
        return boughtStrikes[_epoch][_provider];
    }

    /**
     * @notice Gets PNL quoted in LP token for all open options positions
     * @param _epoch System epoch
     * @param _type Bull/Bear
     * @return PNL quoted in LP tokens
     */
    function optionPosition(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (uint256) {
        uint256 totalPosition;
        uint256 _borrowedLP;

        // Get providers according to the strategy we are checking
        if (_type == IRouter.OptionStrategy.BULL) {
            IOption[] memory _providers = bullProviders[_epoch];
            uint256 length = _providers.length;

            for (uint256 i; i < length;) {
                // Gets what our option position is worth
                // position() returns ETH value
                totalPosition = totalPosition + _providers[i].position(address(this), address(compoundStrategy));

                unchecked {
                    ++i;
                }
            }

            _borrowedLP = borrowedLP[IRouter.OptionStrategy.BULL];
        } else {
            IOption[] memory _providers = bearProviders[_epoch];
            uint256 length = _providers.length;
            for (uint256 j; j < length;) {
                // Gets what our option position is worth
                // position() returns ETH value
                totalPosition = totalPosition + _providers[j].position(address(this), address(compoundStrategy));

                unchecked {
                    ++j;
                }
            }

            _borrowedLP = borrowedLP[IRouter.OptionStrategy.BEAR];
        }

        uint256 positionInLp;

        // If we made money on options, convert to LP
        if (totalPosition > 0) {
            positionInLp = pairAdapter.ETHtoLP(totalPosition);
        }

        // After converting options PNL to LP, check if its bigger than what was spent buying them
        if (positionInLp > _borrowedLP) {
            return positionInLp - _borrowedLP;
        }

        // If it reaches here it means we have no profit
        return 0;
    }

    function compareStrikes(uint256 _costPaid, uint256 _currentCost, uint256 _baseAmount)
        external
        pure
        returns (uint256 toBuyOptions, uint256 toFarm, bool isOverpaying)
    {
        return _compareStrikes(_costPaid, _currentCost, _baseAmount);
    }

    // Calculates the % of the difference between price paid for options and current price. Returns an array with the % that matches the indexes of the strikes.
    function deltaPrice(
        uint256 _epoch,
        // Users normal LP spent would be equivalent to the option risk. but since its a mid epoch deposit, it can be higher in order to offset options price appreciation
        // This the LP amount adjusted to the epochs risk profile.
        // To be calculated we get the user total LP amount, calculate option risk threshold, with this number we use the percentageOverTotalCollateral to get amount for each strike
        uint256 userAmountOfLp,
        IOption _provider
    ) external view returns (DifferenceAndOverpaying[] memory) {
        // Get what prices we have paid on each options strike when bootstrappig.
        // 0 means we didnt buy any of the given strike
        Strike[] memory _boughtStrikes = boughtStrikes[_epoch][_provider];

        DifferenceAndOverpaying[] memory amountCollateralEachStrike = new DifferenceAndOverpaying[](
                _boughtStrikes.length
            );

        for (uint256 i; i < _boughtStrikes.length;) {
            // Get current bought strike
            Strike memory current = _boughtStrikes[i];

            // Since we store the collateral each strike, we need to convert the user collateral amount destined to options to each strike
            // Based in Epochs risk
            // This is the "baseAmount"
            uint256 currentAmountOfLP = (current.percentageOverTotalCollateral * userAmountOfLp) / BASIS_POINTS;

            // Get price paid in strike (always in collateral token)
            uint256 costPaid = current.costIndividual;

            // Epoch strike price (eg: 1800e8)
            uint256 strike = current.price;

            // Get current price
            uint256 currentCost = _provider.getOptionPrice(strike);

            // Compare strikes and calculate amounts to buy options and to farm
            (uint256 toBuyOptions, uint256 toFarm, bool isOverpaying) =
                _compareStrikes(costPaid, currentCost, currentAmountOfLP);

            amountCollateralEachStrike[i] =
                DifferenceAndOverpaying(strike, currentCost, toBuyOptions, toFarm, isOverpaying);

            unchecked {
                ++i;
            }
        }

        // Return amount of collateral we need to use in each strike
        return amountCollateralEachStrike;
    }

    function getBullProviders(uint256 epoch) external view returns (IOption[] memory) {
        return bullProviders[epoch];
    }

    function getBearProviders(uint256 epoch) external view returns (IOption[] memory) {
        return bearProviders[epoch];
    }

    function getBudget(uint256 _epoch) external view returns (Budget memory) {
        return budget[_epoch];
    }

    /* -------------------------------------------------------------------------- */
    /*                                     PRIVATE                                */
    /* -------------------------------------------------------------------------- */

    // @notice Returns percentage increase or decrease of option price now comparing with the price on strategy execution
    function _calculatePercentageDifference(uint256 _priceBefore, uint256 _priceNow) private pure returns (uint256) {
        // Calculate the absolute difference between the two numbers
        uint256 diff = (_priceBefore > _priceNow) ? _priceBefore - _priceNow : _priceNow - _priceBefore;

        // Calculate the percentage using 1e12 as 100%
        return (diff * BASIS_POINTS) / _priceBefore;
    }

    /**
     * @notice Calculates how user's LP are going to be spread across options/farm in order to maintain the correct system proportions
     * @param _costPaid How much was paid for one option of the given strike
     * @param _currentCost How much this option is now worth
     * @param _baseAmount Calculated by getting the percentageOverTotatalCollateral
     * @return toBuyOptions How much of users deposited LP is going to be used to purchase options
     * @return toFarm How much of users deposited LP is going to be sent to the farm
     * @return isOverpaying If its true, it means options are now more expensive than at first epoch buy at strategy execution
     */
    function _compareStrikes(uint256 _costPaid, uint256 _currentCost, uint256 _baseAmount)
        private
        pure
        returns (uint256 toBuyOptions, uint256 toFarm, bool isOverpaying)
    {
        uint256 differencePercentage = _calculatePercentageDifference(_costPaid, _currentCost);

        if (_currentCost > _costPaid) {
            // If options are now more expensive, we will use a bigger amount of the user's LP
            toBuyOptions = _baseAmount.mulDivUp((BASIS_POINTS + differencePercentage), BASIS_POINTS);
            isOverpaying = true;
            toFarm = 0;
        } else {
            // If options are now cheaper, we will use a smaller amount of the user's LP
            toBuyOptions = _baseAmount.mulDivUp((BASIS_POINTS - differencePercentage), BASIS_POINTS);
            toFarm = _baseAmount - toBuyOptions;
            isOverpaying = false;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    function initApproves(address[] calldata _target, address[] calldata _token) external onlyGovernor {
        uint256 length = _target.length;

        if (length != _token.length) {
            revert LengthMismatch();
        }

        for (uint256 i; i < length;) {
            IERC20(_token[i]).approve(_target[i], type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    function addProvider(address _provider) public onlyGovernor {
        if (_provider == address(0)) {
            revert ZeroAddress();
        }

        validProvider[_provider] = true;

        emit AddOptionProvider(_provider);

        WETH.approve(_provider, type(uint256).max);
    }

    function batchAddProviders(address[] calldata _providers) external {
        uint256 length = _providers.length;

        for (uint256 i; i < length;) {
            addProvider(_providers[i]);

            unchecked {
                ++i;
            }
        }
    }

    function removeProvider(address _provider) public onlyGovernor {
        if (_provider == address(0)) {
            revert ZeroAddress();
        }

        validProvider[_provider] = false;

        emit RemoveOptionProvider(_provider);

        WETH.approve(_provider, 0);
    }

    function batchRemoveProviders(address[] calldata _providers) external {
        uint256 length = _providers.length;

        for (uint256 i; i < length;) {
            removeProvider(_providers[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setCompoundStrategy(address _compoundStrategy) external onlyGovernor {
        if (_compoundStrategy == address(0)) {
            revert ZeroAddress();
        }

        emit UpdateCompoundStrategy(address(compoundStrategy), _compoundStrategy);

        compoundStrategy = ICompoundStrategy(_compoundStrategy);
    }

    function updatePairAdapter(address _pairAdapter) external onlyGovernor {
        if (_pairAdapter == address(0)) {
            revert ZeroAddress();
        }

        emit UpdatePairAdapter(address(pairAdapter), _pairAdapter);

        pairAdapter = ILP(_pairAdapter);
    }

    function updateSwapper(address _swapper) external onlyGovernor {
        if (_swapper == address(0)) {
            revert ZeroAddress();
        }

        emit UpdateSwapper(address(swapper), _swapper);

        swapper = ISwap(_swapper);
    }

    function setDefaultProviders(address _bullProvider, address _bearProvider) external onlyGovernor {
        if (_bullProvider == address(0) || _bearProvider == address(0)) {
            revert ZeroAddress();
        }

        dopexAdapter[IOption.OPTION_TYPE.CALLS] = IOption(_bullProvider);
        dopexAdapter[IOption.OPTION_TYPE.PUTS] = IOption(_bullProvider);

        emit UpdateDefaultDopexProviders(_bullProvider, _bearProvider);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
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
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Deposit(uint256 indexed epoch, uint256 lpAmount, uint256 bullAmount, uint256 bearAmount);
    event BullStrategy(
        uint256 indexed epoch, uint128 toSpend, uint256 wethAmount, IOption[] providers, uint256[] amount
    );
    event DebtUpdated(IRouter.OptionStrategy indexed _strategy, uint256 oldDebt, uint256 currentDebt);
    event BearStrategy(
        uint256 indexed epoch, uint128 toSpend, uint256 wethAmount, IOption[] providers, uint256[] amount
    );
    event MigrateToCrabStrategy(IRouter.OptionStrategy indexed _from, uint128 _amount);
    event CollectRewardsEpochEnd(IOption.OPTION_TYPE indexed strategyType, uint256 wethColleccted, IOption[] providers);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);
    event AddBoughtStrike(uint256 indexed epoch, IOption provider, Strike newStrike);
    event SettleOptionStrike(uint256 indexed epoch, IOption provider, Strike strike);
    event UpdateOptionStrike(uint256 indexed epoch, Strike strikeBefore, Strike strikeAfter);
    event UpdateDefaultDopexProviders(address callsSsov, address putsSsov);
    event UpdateSwapper(address oldSwapper, address newSwapper);
    event UpdatePairAdapter(address oldPairAdapter, address newPairAdapter);
    event UpdateCompoundStrategy(address oldCompoundStrategy, address newCompoundStrategy);
    event RemoveOptionProvider(address removedOptionProvider);
    event AddOptionProvider(address newOptionProvider);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error ZeroAddress();
    error InvalidProvider();
    error InvalidBuilder();
    error InvalidType();
    error LengthMismatch();
    error InvalidCollateralUsage();
    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ILP} from "src/interfaces/ILP.sol";
import {IFarm} from "src/interfaces/IFarm.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {OperableKeepable, Governable} from "src/common/OperableKeepable.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "src/interfaces/common/IAggregatorV3.sol";
import {IMasterChefV2, MasterChefStructs, IRewarder} from "src/interfaces/farm/IMasterChefV2.sol";
import {AssetsPricing} from "src/libraries/AssetsPricing.sol";
import {ILpsRegistry} from "src/common/LpsRegistry.sol";

contract MiniChefV2Adapter is IFarm, OperableKeepable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    // @notice Info needed to perform a swap
    struct SwapData {
        // @param Swapper used
        ISwap swapper;
        // @param Encoded data we are passing to the swap
        bytes data;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // @notice MiniChefV2 ABI
    IMasterChefV2 public constant farm = IMasterChefV2(0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3);

    // @notice SUSHI token (emited in MiniChefV2 farms)
    IERC20 public constant SUSHI = IERC20(0xd4d42F0b6DEF4CE0383636770eF773390d85c61A);

    // @notice Wrapped ETH, base asset of LPs
    IERC20 public constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    // @notice Default swapper set in constructor = sushi
    ISwap public defaultSwapper;

    // @notice Default slippage used in swaps
    uint256 public defaultSlippage;

    ILpsRegistry private lpsRegistry;

    mapping(address => bool) public validSwapper;

    // @notice Pool identification for the systems LP token farm
    uint256 public pid;

    // @notice Underlying Metavault LP token
    IERC20 public lp;

    // @notice Pair adapter responsible mostly for build/break LP logic
    ILP public lpAdapter;

    // @notice Extra token emitted by some MinichefV2 farms.
    // If current farm doesnt have it, itll be set as address 0.
    IERC20 public rewardToken;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initializeFarm(
        uint256 _pid,
        address _lp,
        address _lpAdapter,
        address _rewardToken,
        address _lpsRegistry,
        address _defaultSwapper,
        uint256 _defaultSlippage
    ) external initializer {
        if (_lp == address(0) || _rewardToken == address(0) || _defaultSwapper == address(0)) {
            revert ZeroAddress();
        }

        pid = _pid;
        lp = IERC20(_lp);
        lpAdapter = ILP(_lpAdapter);
        rewardToken = IERC20(_rewardToken);
        defaultSwapper = ISwap(_defaultSwapper);
        lpsRegistry = ILpsRegistry(_lpsRegistry);

        defaultSlippage = _defaultSlippage;

        __Governable_init(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                ONLY OPERATOR                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Stake LP token from strategy.
     * @param _amount Value to stake.
     */
    function stake(uint256 _amount) external onlyOperator {
        address thisAddress = address(this);

        // Transfer the LP from the strategy to address(this)
        lp.safeTransferFrom(msg.sender, thisAddress, _amount);
        // Approve farm can we save this??
        lp.approve(address(farm), _amount);
        // Deposit for itself
        farm.deposit(pid, _amount, thisAddress);

        emit Stake(msg.sender, pid, _amount);
    }

    /**
     * @notice Unstake LP token and send to receiver.
     * @param _amount Value to stake.
     * @param _receiver Who will receive the LP.
     */
    function unstake(uint256 _amount, address _receiver) external onlyOperator {
        // Withdraw the LP tokens from Farm ands send to receiver
        farm.withdraw(pid, _amount, _receiver);
        emit UnStake(_receiver, pid, _amount);
    }

    /**
     * @notice Claim farm Rewards.
     * @param _receiver Who will receive the Rewards.
     */
    function claim(address _receiver) external onlyOperator {
        // Get the farm rewards
        farm.harvest(pid, _receiver);
        emit Harvest(_receiver, pid);
    }

    /**
     * @notice Claim yield, transform into LP and stake
     * @return Amount of LP tokens staked
     */
    function claimAndStake() external onlyOperator returns (uint256) {
        // Load extra token
        IERC20 extraToken = rewardToken;
        IERC20 sushi = SUSHI;
        address here = address(this);
        uint256 _pid = pid;

        // Review rewards

        try farm.pendingSushi(_pid, here) returns (uint256 pendingSushi) {
            if (pendingSushi > 0) {
                // Get the farm rewards
                farm.harvest(_pid, here);
                emit Harvest(here, _pid);
            } else {
                return 0;
            }
        } catch {
            return 0;
        }

        ISwap defaultSwapper_ = defaultSwapper;

        // Approvals
        address swapper = address(defaultSwapper_);

        // Get balances after harvesting
        uint256 sushiBalance = sushi.balanceOf(here);

        if (sushiBalance > 1e18) {
            // Not all farms emit a token besides sushi as reward
            if (address(extraToken) != address(0) && extraToken.balanceOf(address(this)) > 0) {
                uint256 extraTokenBalance = extraToken.balanceOf(here);
                extraToken.approve(swapper, extraTokenBalance);

                // Reward Token -> WETH. Amount out is calculated in the swapper
                ISwap.SwapData memory rewardTokenToWeth =
                    ISwap.SwapData(address(extraToken), address(WETH), extraTokenBalance, "");

                extraToken.approve(swapper, extraTokenBalance);

                defaultSwapper.swap(rewardTokenToWeth);
            }

            // Build transactions struct to pass in the batch swap
            // SUSHI -> WETH. Amount out is calculated in the swapper
            ISwap.SwapData memory sushiToWeth = ISwap.SwapData(address(sushi), address(WETH), sushiBalance, "");

            // Swap sushi to WETH
            sushi.approve(swapper, sushiBalance);

            defaultSwapper.swap(sushiToWeth);

            // Received WETH after swapping
            uint256 wethAmount = WETH.balanceOf(address(this));

            // Send to pair adapter to build the lp tokens
            WETH.safeTransfer(address(lpAdapter), wethAmount);

            // Struct to add LP and swap the WETH to underlying tokens of the LP token
            ILP.LpInfo memory lpInfo = ILP.LpInfo({swapper: defaultSwapper_, externalData: ""});

            // After building, execute the LP build and receive
            uint256 lpBalance = lpAdapter.buildLP(wethAmount, lpInfo);

            // After receiving the LP, stake into the farm
            lp.approve(address(farm), lpBalance);

            farm.deposit(_pid, lpBalance, here);

            emit Stake(here, _pid, lpBalance);

            return lpBalance;
        } else {
            return 0;
        }
    }

    /**
     * @notice Gets yield, convert to WETH and build LP
     * @dev Supposed to be used only if updating farm
     */
    function exit() external onlyOperator {
        // Load extra token
        IERC20 extraToken = rewardToken;
        IERC20 sushi = SUSHI;

        address here = address(this);
        // Get the farm rewards
        farm.harvest(pid, here);

        // Sushi balance after harvest
        uint256 sushiBalance = sushi.balanceOf(address(here));

        emit Harvest(here, pid);

        ISwap defaultSwapper_ = defaultSwapper;

        // Approvals
        address swapper = address(defaultSwapper_);

        sushi.approve(swapper, sushiBalance);

        // Build transactions struct to pass in the batch swap
        ISwap.SwapData memory sushiToWeth = ISwap.SwapData(address(sushi), address(WETH), sushiBalance, "");

        // Swap sushi & other token to WETH
        defaultSwapper_.swap(sushiToWeth);

        // Not all farms emit a token besides sushi as reward
        if (address(extraToken) != address(0) && extraToken.balanceOf(address(this)) > 0) {
            uint256 extraTokenBalance = extraToken.balanceOf(here);
            extraToken.approve(swapper, extraTokenBalance);

            // Reward Token -> WETH. Amount out is calculated in the swapper
            ISwap.SwapData memory rewardTokenToWeth =
                ISwap.SwapData(address(extraToken), address(WETH), extraTokenBalance, "");

            extraToken.approve(swapper, extraTokenBalance);

            defaultSwapper.swap(rewardTokenToWeth);
        }

        uint256 wethAmount = WETH.balanceOf(address(this));

        WETH.safeTransfer(address(lpAdapter), wethAmount);

        ILP.LpInfo memory lpInfo = ILP.LpInfo(defaultSwapper_, "");

        uint256 lpOutput = lpAdapter.buildLP(wethAmount, lpInfo);

        lp.safeTransfer(msg.sender, lpOutput);

        emit Exit(msg.sender, lpOutput);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ONLY KEEPER                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Swap Assets.
     * @param _swapper Swapper Contract.
     * @param _swapData Data needed to swap.
     */
    function swap(ISwap _swapper, ISwap.SwapData memory _swapData) external onlyKeeper {
        if (!validSwapper[address(_swapper)]) {
            revert InvalidSwapper();
        }

        _swapper.swap(_swapData);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    function pendingRewards() external view returns (address[] memory, uint256[] memory) {
        return _pendingRewards();
    }

    /**
     * @notice Gets pending rewards tokens and convert it to LP
     * @return Amount of LP we would receive by exchanging tokens to LP
     */
    function pendingRewardsToLP() external view returns (uint256) {
        (address[] memory assets, uint256[] memory amounts) = _pendingRewards();

        uint256 wethAmount;
        uint256 length = assets.length;
        address weth = address(WETH);

        for (uint256 i; i < length;) {
            // asset to ETH
            wethAmount = assets[i] != weth && amounts[i] > 0
                ? wethAmount + _assetToETH(assets[i], amounts[i])
                : wethAmount + amounts[i];

            unchecked {
                ++i;
            }
        }

        // If the yield position is worth > 0 WETH, simulate how much LP its worth
        return wethAmount > 0 ? lpAdapter.ETHtoLP(wethAmount) : 0;
    }

    /**
     * @notice Sushi rewards our pool can receive
     */
    function earned() external view returns (uint256) {
        return uint256(farm.userInfo(pid, address(this)).rewardDebt);
    }

    /**
     * @notice Amount of LP tokens deposited in the LP farm
     */
    function balance() external view returns (uint256) {
        return uint256(farm.userInfo(pid, address(this)).amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    // Rescue lost tokens
    function rescue(IERC20 _token, uint256 _amount, address _to) external onlyGovernor {
        _token.safeTransfer(_to, _amount);
    }

    function addNewStrategy(uint256 _pid, address _lp, address _rewardToken) external onlyGovernor {
        // Some checks
        if (_lp == address(0) || _rewardToken == address(0)) {
            revert ZeroAddress();
        }

        pid = _pid;
        lp = IERC20(_lp);
        rewardToken = IERC20(_rewardToken);
    }

    function addNewSwapper(address _swapper) external onlyGovernor {
        // Some checks
        if (_swapper == address(0)) {
            revert ZeroAddress();
        }

        validSwapper[_swapper] = true;
        WETH.approve(_swapper, type(uint256).max);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.safeTransfer(_to, assetBalance);
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

    function updateLPAdapter(address _lp) external onlyGovernor {
        if (_lp == address(0)) {
            revert ZeroAddress();
        }

        lpAdapter = ILP(_lp);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     PRIVATE                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Gets pending yield tokens and amounts
     */
    function _pendingRewards() private view returns (address[] memory, uint256[] memory) {
        uint256 _pid = pid;
        uint256 pendingSushi = farm.pendingSushi(_pid, address(this));

        // Sushi rewards distributor for the given PID
        IRewarder rewarder = farm.rewarder(_pid);

        if (address(rewarder) != address(0)) {
            (IERC20[] memory tokens, uint256[] memory rewards) =
                rewarder.pendingTokens(_pid, address(this), pendingSushi);

            uint256 length = rewards.length;

            address[] memory tokenAddresses = new address[](length + 1);
            uint256[] memory rewardAmounts = new uint256[](length + 1);

            for (uint256 i = 0; i < length;) {
                tokenAddresses[i] = address(tokens[i]);
                rewardAmounts[i] = rewards[i];
                unchecked {
                    ++i;
                }
            }

            tokenAddresses[length] = address(SUSHI);
            rewardAmounts[length] = pendingSushi;

            return (tokenAddresses, rewardAmounts);
        } else {
            address[] memory tokenAddresses = new address[](1);
            uint256[] memory rewardAmounts = new uint256[](1);

            tokenAddresses[0] = address(SUSHI);
            rewardAmounts[0] = pendingSushi;

            return (tokenAddresses, rewardAmounts);
        }
    }

    /**
     * @notice Gets how much WETH we would get by dumping it on LP
     * @param _asset The asset we are exchanging for WETH
     * @param _amount Amount of _asset
     * @return Amount in WETH
     */
    function _assetToETH(address _asset, uint256 _amount) public view returns (uint256) {
        address pair = lpsRegistry.getLpAddress(_asset, address(WETH));

        uint256 ethAmount = AssetsPricing.getAmountOut(pair, _amount, _asset, address(WETH));

        (bool success,) = _tryGetAssetDecimals(_asset);

        if (!success) {
            revert FailToGetAssetDecimals();
        }

        return ethAmount;
    }

    function _tryGetAssetDecimals(address asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) =
            asset_.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Stake(address from, uint256 pid, uint256 amount);
    event UnStake(address to, uint256 pid, uint256 amount);
    event Harvest(address to, uint256 pid);
    event Exit(address to, uint256 amount);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error ZeroAddress();
    error InvalidSwapper();
    error FailSendETH();
    error FailToGetAssetDecimals();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {OperableKeepable} from "src/common/OperableKeepable.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IUniswapV2Router} from "src/interfaces/farm/IUniswapV2Router.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {AssetsPricing} from "src/libraries/AssetsPricing.sol";
import {ILpsRegistry} from "src/common/LpsRegistry.sol";

contract SushiSwapAdapter is ISwap, OperableKeepable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // Sushi Swap Router
    IUniswapV2Router private constant SUSHI_ROUTER = IUniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    // @notice Internal representation of 100%
    uint256 private constant BASIS_POINTS = 1e12;

    // @notice Slippage to avoid reverts after simulations
    uint256 private slippage;

    // @notice Wrapped Ether
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Store the LP pair address for a given token0
    // tokenIn => tokenOut => LP
    // Use public function to get the LP address for the given route.
    mapping(address => mapping(address => address)) private lpAddress;

    ILpsRegistry private lpsRegistry;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initializeSwap(address _lpsRegistry) external initializer {
        slippage = (98 * 1e12) / 100;

        lpsRegistry = ILpsRegistry(_lpsRegistry);

        __Governable_init(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                ONLY OPERATOR                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Perform Swap.
     * @param _data Data needed for the swap.
     * @return Amount out
     */
    function swap(SwapData memory _data) external onlyOperatorOrKeeper returns (uint256) {
        return _swap(_data);
    }

    /**
     * @notice Perform Swap of any token to weth.
     * @param _token Asset to swap.
     * @param _amount Amount to swap.
     */
    function swapTokensToEth(address _token, uint256 _amount) external onlyOperatorOrKeeper {
        IUniswapV2Router router = SUSHI_ROUTER;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeApprove(address(router), _amount);

        address[] memory path = new address[](2);

        path[0] = _token;
        path[1] = WETH;

        address pair = lpsRegistry.getLpAddress(_token, WETH);

        // This takes in consideration slippage + fees
        uint256 min = AssetsPricing.getAmountOut(pair, _amount, _token, WETH);

        // Apply slippage to avoid an unlikely revert
        min = _applySlippage(min, slippage);

        uint256[] memory amounts = router.swapExactTokensForTokens(_amount, min, path, msg.sender, block.timestamp);

        emit AdapterSwap(address(this), _token, WETH, msg.sender, _amount, amounts[amounts.length - 1]);
    }

    /**
     * @notice Perform more than one swap
     * @param _data Data needed to do many swaps.
     * @return _amount Amounts out.
     */
    function batchSwap(SwapData[] memory _data) external returns (uint256[] memory) {
        uint256 length = _data.length;

        uint256[] memory outputs = new uint256[](length);

        for (uint256 i; i < length;) {
            outputs[i] = _swap(_data[i]);

            unchecked {
                ++i;
            }
        }

        return outputs;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Default slippage for safety measures
     * @param _slippage Default slippage
     */
    function setSlippage(uint256 _slippage) external onlyGovernor {
        if (_slippage == 0 || _slippage > BASIS_POINTS) revert InvalidSlippage();

        slippage = _slippage;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
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
    /*                                    PRIVATE                                 */
    /* -------------------------------------------------------------------------- */

    function _swap(SwapData memory _data) private returns (uint256) {
        // Send tokens from msg.sender to here
        IERC20(_data.tokenIn).safeTransferFrom(msg.sender, address(this), _data.amountIn);

        address pair = lpsRegistry.getLpAddress(_data.tokenIn, _data.tokenOut);

        uint256 minAmountOut;

        address[] memory path;

        // In case the swap is not to WETH, we are first converting it to WETH and then to the token out since WETH pair are more liquid.
        path = new address[](2);

        path[0] = _data.tokenIn;
        path[1] = _data.tokenOut;

        // Gets amount out in a single hop swap
        minAmountOut = AssetsPricing.getAmountOut(pair, _data.amountIn, _data.tokenIn, _data.tokenOut);

        // Apply slippage to avoid unlikely revert
        minAmountOut = _applySlippage(minAmountOut, slippage);

        // Approve Sushi router to spend received tokens
        IERC20(_data.tokenIn).safeApprove(address(SUSHI_ROUTER), _data.amountIn);

        if (minAmountOut > 0) {
            uint256[] memory amounts =
                SUSHI_ROUTER.swapExactTokensForTokens(_data.amountIn, minAmountOut, path, msg.sender, block.timestamp);

            emit AdapterSwap(
                address(this), _data.tokenIn, _data.tokenOut, msg.sender, _data.amountIn, amounts[amounts.length - 1]
            );

            return amounts[amounts.length - 1];
        } else {
            return 0;
        }
    }

    function _applySlippage(uint256 _amountOut, uint256 _slippage) private pure returns (uint256) {
        return _amountOut.mulDivDown(_slippage, BASIS_POINTS);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error InvalidSlippage();
    error ZeroAddress();
    error ZeroAmount(address _token);
    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {OperableKeepable} from "src/common/OperableKeepable.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "src/interfaces/farm/IUniswapV2Router.sol";
import {ILP} from "src/interfaces/ILP.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {AssetsPricing} from "src/libraries/AssetsPricing.sol";

contract UniV2PairAdapter is ILP, OperableKeepable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    // Needed for stack too deep
    struct AddLiquidity {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    // Info needed to perform a swap
    struct SwapData {
        // Swapper used
        ISwap swapper;
        // Encoded data we are passing to the swap
        bytes data;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Equivalent to 100%
    uint256 public constant BASIS_POINTS = 1e12;

    // @notice Router to perform transactions and liquidity management
    IUniswapV2Router public constant SUSHI_ROUTER = IUniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    // @notice Wrapped Ether
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    // @notice Non-WETH token for the pair
    IERC20 public otherToken;

    // @notice LP token for a given pair
    IUniswapV2Pair public lp;

    // @notice Tokens contained in the pair
    address public token0;
    address public token1;

    // @notice Slippage in 100%
    uint256 private slippage;

    // @notice Only swap through whitelisted dex'es
    mapping(address => bool) public validSwapper;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initializeLP(address _lp, address _otherToken, uint256 _slippage) external initializer {
        if (_slippage > BASIS_POINTS) {
            revert InvalidSlippage();
        }
        if (_lp == address(0) || _otherToken == address(0)) {
            revert ZeroValue();
        }

        IUniswapV2Pair lp_ = IUniswapV2Pair(_lp);

        lp = lp_;
        otherToken = IERC20(_otherToken);

        token0 = lp_.token0();
        token1 = lp_.token1();

        slippage = _slippage;

        __Governable_init(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                ONLY OPERATOR                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Provide liquidity to build LP.
     * @param _wethAmount WETH amount used to build LP.
     * @param _lpData Data needed to swap WETH to build LP.
     * @return Amount of LP Built
     */
    function buildLP(uint256 _wethAmount, LpInfo memory _lpData) public onlyOperator returns (uint256) {
        address WETH_ = address(WETH);

        // Convert half to otherToken to build the Lp token
        uint256 amountToSwap = _wethAmount / 2;

        // Build transaction to swap half of received WETH (token1) to token0
        ISwap.SwapData memory swapData = ISwap.SwapData({
            tokenIn: address(WETH_),
            tokenOut: address(otherToken),
            amountIn: amountToSwap,
            externalData: _lpData.externalData
        });

        // Get dex that will be used to make swap
        address swapper = address(_lpData.swapper);

        WETH.approve(swapper, amountToSwap);

        // Perform swap
        uint256 otherTokenReceived = _lpData.swapper.swap(swapData);

        // Approve Sushi Router to create Lp
        address sushiRouter_ = address(SUSHI_ROUTER);

        WETH.approve(sushiRouter_, amountToSwap);
        otherToken.approve(sushiRouter_, otherTokenReceived);

        uint256 lpReceived = _build(otherTokenReceived, amountToSwap);

        lp.transfer(msg.sender, lpReceived);

        return lpReceived;
    }

    function buildWithBothTokens(address _token0, address _token1, uint256 amount0, uint256 amount1)
        external
        onlyOperator
        returns (uint256)
    {
        IERC20 token0_ = IERC20(_token0);
        IERC20 token1_ = IERC20(_token1);

        token0_.safeTransferFrom(msg.sender, address(this), amount0);
        token1_.safeTransferFrom(msg.sender, address(this), amount1);

        token0_.approve(address(SUSHI_ROUTER), amount0);
        token1_.approve(address(SUSHI_ROUTER), amount1);

        (,, uint256 receivedLp) = SUSHI_ROUTER.addLiquidity(
            address(token0_), address(token1_), amount0, amount1, 0, 0, address(msg.sender), block.timestamp
        );

        return receivedLp;
    }

    /**
     * @notice Remove liquidity from LP and swap for WETH.
     * @param _lpAmount Amount to remove.
     * @param _lpData Swap removed asset for WETH.
     * @return Amount of WETH
     */
    function breakLP(uint256 _lpAmount, LpInfo memory _lpData) external onlyOperator returns (uint256) {
        // Break the chosen amount of LP
        _breakLP(_lpAmount);

        // Swap Other token -> WETH
        if (!validSwapper[address(_lpData.swapper)]) {
            revert InvalidSwapper();
        }

        // Gets amount of token0 after breaking
        uint256 otherTokenReceived = otherToken.balanceOf(address(this));

        // Convert token0 balance to WETH (token1)
        _lpData.swapper.swapTokensToEth(address(otherToken), otherTokenReceived);

        // Store received WETH
        uint256 wethAmount = WETH.balanceOf(address(this));

        WETH.transfer(msg.sender, wethAmount);

        emit BreakLP(address(lp), _lpAmount, wethAmount);

        return wethAmount;
    }

    /**
     * @notice Remove liquidity from LP and swap for WETH.
     * @param _lpAmount LP amount to remove.
     * @param _swapper Swap Contract.
     * @return Amount of WETH
     */
    function performBreakAndSwap(uint256 _lpAmount, ISwap _swapper) external onlyOperator returns (uint256) {
        _breakLP(_lpAmount);

        if (!validSwapper[address(_swapper)]) {
            revert InvalidSwapper();
        }

        // Swap Other token -> WETH
        IUniswapV2Pair _lpToken = lp;
        address _token0 = _lpToken.token0();
        if (_token0 == address(WETH)) {
            IERC20 _token = IERC20(_lpToken.token1());
            uint256 amount = _token.balanceOf(address(this));
            _token.approve(address(_swapper), amount);
            _swapper.swapTokensToEth(_lpToken.token1(), amount);
        } else {
            IERC20 _token = IERC20(_token0);
            uint256 amount = _token.balanceOf(address(this));
            _token.approve(address(_swapper), amount);
            _swapper.swapTokensToEth(_token0, amount);
        }

        uint256 wethBal = IERC20(WETH).balanceOf(address(this));

        IERC20(WETH).transfer(msg.sender, wethBal);

        emit BreakLP(address(_lpToken), _lpAmount, wethBal);

        return wethBal;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ONLY KEEPER                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Swap Assets.
     * @param _swapper Swapper Contract.
     * @param _swapData Data needed to swap.
     */
    function swap(ISwap _swapper, ISwap.SwapData memory _swapData) external onlyKeeper {
        if (!validSwapper[address(_swapper)]) {
            revert InvalidSwapper();
        }

        _swapper.swap(_swapData);
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    function ETHtoLP(uint256 _amount) external view returns (uint256) {
        return _ETHtoLP(_amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    function addNewSwapper(address _swapper) external onlyGovernor {
        // Some checks
        if (_swapper == address(0)) {
            revert ZeroAddress();
        }

        validSwapper[_swapper] = true;
        IERC20(token0).safeApprove(_swapper, type(uint256).max);
        IERC20(token1).safeApprove(_swapper, type(uint256).max);
    }

    function updateSlippage(uint256 _slippage) external onlyGovernor {
        if (_slippage > BASIS_POINTS) revert();

        slippage = _slippage;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
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
    /*                                    PRIVATE                                 */
    /* -------------------------------------------------------------------------- */

    function _validateSlippage(uint256 _amount) private view returns (uint256) {
        // Return minAmountOut
        return (_amount * slippage) / BASIS_POINTS;
    }

    function _breakLP(uint256 _lpAmount) private {
        // Load the LP token for the msg.sender (strategy)
        address lpAddress = address(lp);
        IERC20 lpToken = IERC20(lpAddress);
        uint256 slippage_ = slippage;

        // Few validations
        if (_lpAmount == 0) {
            revert ZeroValue();
        }

        // Use library to calculate an estimate of how much tokens we should receive
        (uint256 desireAmountA, uint256 desireAmountB) = AssetsPricing.breakFromLiquidityAmount(lpAddress, _lpAmount);

        // Approve SUSHI router to spend the LP
        lpToken.safeApprove(address(SUSHI_ROUTER), _lpAmount);

        // Remove liquidity using the numbers above and send to msg.sender and put the real received amounts in the tuple
        SUSHI_ROUTER.removeLiquidity(
            token0,
            token1, // Base token
            _lpAmount,
            desireAmountA.mulDivDown(slippage_, BASIS_POINTS),
            desireAmountB.mulDivDown(slippage_, BASIS_POINTS),
            address(this),
            block.timestamp
        );
    }

    function _build(uint256 otherTokenAmount, uint256 wethAmount) private returns (uint256) {
        AddLiquidity memory liquidityParams;

        address _otherToken = address(otherToken);

        if (_otherToken == token0) {
            liquidityParams.tokenA = _otherToken;
            liquidityParams.tokenB = address(WETH);
            liquidityParams.amountA = otherTokenAmount;
            liquidityParams.amountB = wethAmount;
        } else {
            liquidityParams.tokenA = address(WETH);
            liquidityParams.tokenB = _otherToken;
            liquidityParams.amountA = wethAmount;
            liquidityParams.amountB = otherTokenAmount;
        }

        // Use SUSHI router to add liquidity using the outputs of the 1inch swaps
        (,, uint256 liquidity) = SUSHI_ROUTER.addLiquidity(
            liquidityParams.tokenA,
            liquidityParams.tokenB,
            liquidityParams.amountA,
            liquidityParams.amountB,
            _validateSlippage(liquidityParams.amountA),
            _validateSlippage(liquidityParams.amountB),
            address(this),
            block.timestamp
        );

        emit BuildLP(
            liquidityParams.tokenA,
            liquidityParams.tokenB,
            liquidityParams.amountA,
            liquidityParams.amountB,
            address(lp),
            liquidity
        );

        // Return the new balance of msg.sender of the LP just created
        return liquidity;
    }

    /**
     * @notice Quotes zap in amount for adding liquidity pair from `_inputToken`.
     * @param _amount The amount of liquidity to calculate output
     * @return estimation of amount of LP tokens that will be available when zapping in.
     */
    function _ETHtoLP(uint256 _amount) private view returns (uint256) {
        IUniswapV2Pair _lp = lp;

        (uint112 reserveA, uint112 reserveB,) = _lp.getReserves();
        uint256 amountADesired;
        uint256 amountBDesired;

        if (token0 == address(WETH)) {
            amountADesired = _amount / 2;
            amountBDesired = SUSHI_ROUTER.quote(amountADesired, reserveA, reserveB);
        } else {
            amountBDesired = _amount / 2;
            amountADesired = SUSHI_ROUTER.quote(amountBDesired, reserveB, reserveA);
        }

        uint256 _totalSupply = _lp.totalSupply();

        uint256 liquidityA = amountADesired.mulDivDown(_totalSupply, reserveA);
        uint256 liquidityB = amountBDesired.mulDivDown(_totalSupply, reserveB);

        return liquidityA < liquidityB ? liquidityA : liquidityB;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event BuildLP(
        address indexed token0,
        address indexed token1,
        uint256 amountToken0,
        uint256 amountToken1,
        address indexed lpAddress,
        uint256 lpAmount
    );
    event BreakLP(address indexed lpAddress, uint256 lpAmount, uint256 wethAmount);
    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error ZeroValue();
    error ZeroAddress();
    error InvalidSwapper();
    error InvalidSlippage();
    error FailSendETH();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

// Abstract Classes
import {UpgradeableOperableKeepable} from "src/common/UpgradeableOperableKeepable.sol";
// Interfaces
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ISSOV, IERC20} from "src/interfaces/option/dopex/ISSOV.sol";
import {ISSOVViewer} from "src/interfaces/option/dopex/ISSOVViewer.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {IStableSwap} from "src/interfaces/swap/IStableSwap.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";
import {IVault} from "src/interfaces/swap/balancer/IVault.sol";
//Libraries
import {Curve2PoolAdapter} from "src/libraries/Curve2PoolAdapter.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {BalancerWstethAdapter} from "src/libraries/BalancerWstethAdapter.sol";
import {AssetsPricing} from "src/libraries/AssetsPricing.sol";

contract DopexAdapter is IOption, UpgradeableOperableKeepable {
    using FixedPointMathLib for uint256;
    using Curve2PoolAdapter for IStableSwap;
    using BalancerWstethAdapter for IVault;

    // Info needed to perform a swap
    struct SwapData {
        // Swapper used
        ISwap swapper;
        // Encoded data we are passing to the swap
        bytes data;
    }

    // Info needed execute options (stack too deep)
    struct ExecuteInfo {
        uint256[] collateralEachStrike;
        uint256 collateralAmount;
        uint256 optionsAmount;
        uint256 premium;
        uint256 totalFee;
        address strikeToken;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Represents 100% in our internal math.
    uint256 private constant BASIS_POINTS = 1e12;

    // @notice Used to calculate amounts on 18 decimals tokens
    uint256 private constant PRECISION = 1e18;

    // @notice USDC uses 6 decimals instead of "standard" 18
    uint256 private constant USDC_DECIMALS = 1e6;

    // @notice Used to find amount of available liquidity on dopex ssovs
    uint256 private constant DOPEX_BASIS = 1e8;

    // @notice Slippage to set in the swaps in order to remove risk of failing
    uint256 public slippage;

    // @notice Tokens used in the underlying logic
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 private constant wstETH = IERC20(0x5979D7b546E38E414F7E9822514be443A4800529);
    IERC20 private constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    // @notice DopEx contract that objectively buys/settles options
    ISSOV public ssov;

    // @notice SSOV's collateral token. Calls -> wstETH / Puts -> 2CRV
    IERC20 public collateralToken;

    // @notice Can either be CALLS or PUTS. We have one DopEx adapter for either option
    OPTION_TYPE public optionType;

    // @notice System epoch (same as the one in CompoundStrategy) => SSOV's epoch
    mapping(uint256 => uint256) public epochs;

    // TODO: Remove this before PRD deploy
    IOptionStrategy public optionStrategy;
    ICompoundStrategy public compoundStrategy;

    // @notice Metavaults Factory
    address private factory;

    // @notice DopEx viewer to fetch some info.
    ISSOVViewer public constant viewer = ISSOVViewer(0x9abE93F7A70998f1836C2Ee0E21988Ca87072001);

    // @notice Curve 2CRV (USDC-USDT)
    IStableSwap private constant CRV = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    // @notice Balancer Vault responsible for the swaps and pools
    IVault private constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    // @notice Sushi contract that routes the swaps
    address private constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    // @notice Sushi WETH_USDC pool
    address private constant WETH_USDC = 0x905dfCD5649217c42684f23958568e533C711Aa3;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initializes the transparent proxy of the DopExAdapter
     * @param _type Represent if its CALLS/PUTS adapter
     * @param _ssov DopEx SSOV for the given _type
     */
    function initializeOptionAdapter(address _factory, OPTION_TYPE _type, ISSOV _ssov, uint256 _slippage)
        external
        initializer
    {
        __Governable_init(msg.sender);

        if (address(_ssov) == address(0) || _factory == address(0)) {
            revert ZeroAddress();
        }

        if (_slippage > BASIS_POINTS) {
            revert OutOfRange();
        }

        // Store factory in storage
        factory = _factory;

        // Store ssov in storage
        ssov = _ssov;

        // Collateral token of given ssov
        collateralToken = _ssov.collateralToken();

        // Call or Put
        optionType = _type;

        // Internal Slippage
        slippage = _slippage;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY OPERATOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Buy options.
     * @param params Parameter needed to buy options.
     */
    function purchase(ExecuteParams calldata params) public onlyOperator {
        // Load desired SSOV from mapping.
        ISSOV _ssov = ssov;

        // Load the collateral token of the SSOV
        IERC20 _collateralToken = collateralToken;

        address thisAddress = address(this);

        // Swaps received WETH to options collateral token
        // wstETH for CALLS and 2crv for puts
        _swapToCollateral(WETH.balanceOf(thisAddress), address(_collateralToken), thisAddress);

        // Gets total collateral we have
        uint256 totalCollateral = _collateralToken.balanceOf(thisAddress);

        if (totalCollateral == 0) {
            revert NotEnoughCollateral();
        }

        // Approve for spending on DopEx
        _collateralToken.approve(address(_ssov), totalCollateral);

        // Store current SSOV epoch
        uint256 ssovEpoch = _ssov.currentEpoch();

        epochs[params.currentEpoch] = ssovEpoch;

        // Buy options
        _executeOptionsPurchase(
            _ssov,
            params.currentEpoch,
            totalCollateral,
            params._collateralEachStrike,
            params._expiry,
            params._strikes,
            thisAddress
        );

        // Emit event showing the prices of the strikes we bought and other relevant info
        emit SSOVPurchase(
            _ssov.currentEpoch(),
            params._strikes,
            params._collateralEachStrike,
            totalCollateral,
            address(_collateralToken)
        );
    }

    /**
     * @notice Exercise ITM options.
     * @param params Parameter needed to settle options.
     */
    function settle(SettleParams calldata params) public onlyOperator returns (uint256) {
        // Load ssov
        ISSOV _ssov = ssov;

        // Get current Epoch
        ISSOV.EpochData memory epochData = _ssov.getEpochData(params.optionEpoch);

        // These are the tokens receipts received when buying options
        address[] memory strikeTokens = viewer.getEpochStrikeTokens(params.optionEpoch, _ssov);

        // Get SSOV strikes from the chosen epoch
        // Numbers are USD value with 8 decimals
        uint256[] memory strikesToSettle = epochData.strikes;

        for (uint256 i = 0; i < strikeTokens.length;) {
            uint256 strike = strikesToSettle[i];

            // Get the receipt token of the desired strike
            IERC20 strikeToken = IERC20(strikeTokens[i]);

            // Get how many options we bought of the strike
            uint256 strikeTokenBalance = _getBoughtStrike(msg.sender, params.currentEpoch, strike).currentOptions;

            // Calcualate if the option is profitable (ITM)
            uint256 strikePnl = _ssov.calculatePnl(
                epochData.settlementPrice, strike, strikeTokenBalance, epochData.settlementCollateralExchangeRate
            );

            // Check if the strike was profitable and if we have this strike options
            if (strikeTokenBalance > 0 && strikePnl > 0) {
                // If profitable, approve and settle the option.
                strikeToken.approve(address(_ssov), strikeTokenBalance);

                // Settle options and receive collateral token. Calls - wstETH / Puts - 2CRV
                _ssov.settle(i, strikeTokenBalance, params.optionEpoch, address(this));

                // Update Option Strategy storage
                IOptionStrategy(msg.sender).settleOptionStrike(params.currentEpoch, IOption(address(this)), strike);
            }

            unchecked {
                ++i;
            }
        }

        // Get received tokens after settling
        uint256 rewards = collateralToken.balanceOf(address(this));

        // If options ended ITM we will receive > 0
        if (rewards > 0) {
            // Swap wstETH or 2CRV to WETH
            address collateralAddress = address(collateralToken);

            _swapToWeth(rewards, collateralAddress);

            // Received amount after converting collateral to WETH
            uint256 wethAmount = WETH.balanceOf(address(this));

            // Transfer to Option Strategy
            WETH.transfer(msg.sender, wethAmount);

            return wethAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Buy options in mid epoch.
     * @param _strike $ Value of the strike in 8 decimals.
     * @param _wethAmount Amount used to buy options.
     */
    function executeSingleOptionPurchase(uint256 _epoch, uint256 _strike, uint256 _wethAmount)
        external
        onlyOperator
        returns (uint256)
    {
        SingleOptionInfo memory info;

        info.ssov = ssov;

        info.collateralToken = collateralToken;

        info.here = address(this);

        info.collateralAddress = address(info.collateralToken);

        // Swap WETH received to collateral token
        _swapToCollateral(_wethAmount, info.collateralAddress, info.here);

        // Collateral that will be used to buy options
        info.collateral = info.collateralToken.balanceOf(info.here);

        // Store current SSOV epoch
        info.ssovEpoch = info.ssov.currentEpoch();

        // Returns how many optiosn we can buy with a given amount of collateral
        (info.optionsAmount,) =
            estimateOptionsPerToken(info.collateral, _strike, info.ssov.getEpochData(info.ssovEpoch).expiry);

        // Cant buy 0 options
        if (info.optionsAmount == 0) {
            revert ZeroAmount();
        }

        collateralToken.approve(address(info.ssov), info.collateral);

        // Purchase options and get costs
        (uint256 _premium, uint256 _fee) =
            info.ssov.purchase(_getStrikeIndex(info.ssov, _strike), info.optionsAmount, info.here);

        IOptionStrategy.Strike memory _optionStrike = _getBoughtStrike(msg.sender, _epoch, _strike);

        IOptionStrategy(msg.sender).updateOptionStrike(
            _epoch,
            IOption(info.here),
            _strike,
            IOptionStrategy.Strike({
                price: _optionStrike.price,
                costIndividual: _optionStrike.costIndividual,
                costTotal: _optionStrike.costTotal,
                percentageOverTotalCollateral: _optionStrike.percentageOverTotalCollateral,
                currentOptions: _optionStrike.currentOptions + info.optionsAmount
            })
        );

        emit SSOVSinglePurchase(info.ssovEpoch, info.collateral, info.optionsAmount, _premium + _fee);

        return _premium + _fee;
    }

    /* -------------------------------------------------------------------------- */
    /*                                     VIEW                                   */
    /* -------------------------------------------------------------------------- */

    // Get how much premium we are paying in total
    // Get the premium of each strike and sum, so we can store after epoch start and compare with other deposits
    function getTotalPremium(uint256[] calldata _strikes, uint256 _expiry)
        private
        view
        returns (uint256 _totalPremium)
    {
        uint256 precision = 10000e18;
        uint256 length = _strikes.length;

        for (uint256 i; i < length;) {
            // Get premium for the given strike, quoted in the underlying token
            _totalPremium += ssov.calculatePremium(_strikes[i], precision, _expiry);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets how many options we can get from an amount of tokens.
     * @param _tokenAmount Amount of options that can be bought, according to collateral and liquidity
     * @param _strike $ value in 8 decimals
     * @param _expiry When the option expire
     */
    function estimateOptionsPerToken(uint256 _tokenAmount, uint256 _strike, uint256 _expiry)
        public
        view
        returns (uint256, uint256)
    {
        ISSOV _option = ssov;

        // Get the strikes total options available
        uint256 availableAtDesiredStrike = getAvailableOptions(_strike);

        // The amount of tokens used to buy an amount of options is
        // the premium + purchase fee.
        // We calculate those values using `precision` as the amount.
        // Knowing how many tokens that cost we can estimate how many
        // Options we can buy using `_tokenAmount`
        uint256 precision = 10000e18;

        // Get premium, quoted in underlying token
        uint256 premiumPerOption = _option.calculatePremium(_strike, precision, _expiry);

        // Get premium for one option
        uint256 premiumSingleOption = _option.calculatePremium(_strike, PRECISION, _expiry);

        // Get Dopex purchase retention, quoted in underlying token
        uint256 feePerOption = _option.calculatePurchaseFees(_strike, precision);

        // Get Dopex purchase retention for one option
        uint256 feeSingleOption = _option.calculatePurchaseFees(_strike, PRECISION);

        // Return amount of options that can be bought
        uint256 amountThatCanBeBought = (_tokenAmount * precision) / (premiumPerOption + feePerOption);

        // If our simulation is bigger than total options available, we return the maximum we can buy (total options available)
        return (
            amountThatCanBeBought > availableAtDesiredStrike ? availableAtDesiredStrike : amountThatCanBeBought,
            premiumSingleOption + feeSingleOption
        );
    }

    // Gets option type and strike value in USD (8 decimals), returns liquidity in collateral token. Calls: wsteth / Puts: 2crv
    function getAvailableOptions(uint256 _strike) public view returns (uint256 availableAtDesiredStrike) {
        ISSOV _ssov = ssov;

        // Get SSOVs current epoch
        uint256 currentEpoch = _ssov.currentEpoch();

        // We subtract total amount of collateral for the amount of collateral bought
        availableAtDesiredStrike = _ssov.getEpochStrikeData(currentEpoch, _strike).totalCollateral
            - _ssov.getEpochStrikeData(currentEpoch, _strike).activeCollateral;

        // If its not a PUT ssov, we apply the collateralExchangeRate in order to get the final options amount at the desired strike
        if (!_ssov.isPut()) {
            availableAtDesiredStrike =
                (availableAtDesiredStrike * DOPEX_BASIS) / _ssov.getEpochData(currentEpoch).collateralExchangeRate;
        }
    }

    // Function to get the price (in collateral token) for the given strike.
    // @param _strike quoted in USD, with 8 decimals. 1e18 = 1 option
    function getOptionPrice(uint256 _strike) public view returns (uint256) {
        // Get SSOV for given input (calls/puts)
        ISSOV _ssov = ssov;

        // Get premium, quoted in underlying token
        uint256 premiumPerOption =
            _ssov.calculatePremium(_strike, PRECISION, _ssov.getEpochData(_ssov.currentEpoch()).expiry);

        // Get Dopex purchase retention, quoted in underlying token
        uint256 feePerOption = _ssov.calculatePurchaseFees(_strike, PRECISION);

        return premiumPerOption + feePerOption;
    }

    // Function to get the price (in collateral token) for all the epochs strikes.
    // @param _strike quoted in USD, with 8 decimals. 1e18 = 1 option
    function geAllStrikestPrices() public view returns (uint256[] memory) {
        // Get SSOV for given input (calls/puts)
        ISSOV _ssov = ssov;

        // Get current strike's strikes
        uint256[] memory currentStrikes = getCurrentStrikes();

        // Amount of strikes
        uint256 length = currentStrikes.length;

        // Output array
        uint256[] memory currentPrices = new uint256[](length);

        for (uint256 i; i < length;) {
            // Get premium, quoted in underlying token
            uint256 premiumPerOption =
                _ssov.calculatePremium(currentStrikes[i], PRECISION, _ssov.getEpochData(_ssov.currentEpoch()).expiry);

            // Get Dopex purchase retention, quoted in underlying token
            uint256 feePerOption = _ssov.calculatePurchaseFees(currentStrikes[i], PRECISION);

            // Get price in underlying token
            currentPrices[i] = premiumPerOption + feePerOption;

            unchecked {
                ++i;
            }
        }

        return currentPrices;
    }

    // In mid epoch deposits, we need to simulate how many options we can buy with the given LP and see if we have enough liquidity
    // This function given an amount of LP, gives the amount of collateral token we are receiving
    // We can use `estimateOptionsPerToken` to convert the receivable amount of collateral token to options.
    // @param _amount amount of lp tokens
    function lpToCollateral(address _lp, uint256 _amount) external view returns (uint256) {
        ISSOV _ssov = ssov;
        uint256 _amountOfEther;
        IUniswapV2Pair pair = IUniswapV2Pair(_lp);

        // Calls -> wstETH / Puts -> 2crv
        // First, lets get the notional value of `_amount`
        // Very precise but not 100%
        (uint256 token0Amount, uint256 token1Amount) = AssetsPricing.breakFromLiquidityAmount(_lp, _amount);

        // Amount of collateral
        uint256 collateral;

        uint256 wethAmount;

        // Convert received tokens from LP to WETH.
        // This function gets maxAmountOut and accounts for slippage + fees
        // We dont support LPs that doesnt have WETH in its composition (for now)
        if (pair.token0() == address(WETH)) {
            wethAmount += token0Amount + AssetsPricing.getAmountOut(_lp, token1Amount, pair.token1(), address(WETH));
        } else if (pair.token1() == address(WETH)) {
            wethAmount += token1Amount + AssetsPricing.getAmountOut(_lp, token0Amount, pair.token0(), address(WETH));
        } else {
            revert NoSupport();
        }

        // Uses 2crv
        if (_ssov.isPut()) {
            // Value in USDC that is later converted to 2CRV
            // AssetsPricing.ethPriceInUsdc() returns 6 decimals
            uint256 ethPriceInUsdc = AssetsPricing.getAmountOut(WETH_USDC, wethAmount, address(WETH), address(USDC));

            collateral = AssetsPricing.get2CrvAmountFromDeposit(ethPriceInUsdc);
        } else {
            // Calls use wstETH
            // Get ratio (18 decimals)
            uint256 ratio = AssetsPricing.wstEthRatio();

            // Calculate eth amount * wstEth oracle ratio and then "remove" decimals from oracle
            // Amount of ether = 18 decimals / Ratio oracle = 18 decimals
            collateral = (_amountOfEther * PRECISION) / ratio;
        }

        // We got previously the amount of collateral token converting the ETH part of the LP
        // Since the ETH part should have the same USD value of the other part, we just do the number we got * 2
        return collateral;
    }

    /**
     * @notice Gets current options bought per option strategy per strike
     */
    function amountOfOptions(address _optionStrategy, uint256 _epoch, uint256 _strikeIndex)
        external
        view
        returns (uint256)
    {
        ISSOV _ssov = ssov;
        uint256[] memory strikes = _ssov.getEpochData(_ssov.currentEpoch()).strikes;
        return _getBoughtStrike(_optionStrategy, _epoch, strikes[_strikeIndex]).currentOptions;
    }

    /**
     * @notice Gets PNL and convert to WETH if > 0
     */
    function position(address _optionStrategy, address _compoundStrategy) external view returns (uint256) {
        uint256 pnl_ = _pnl(_optionStrategy, _compoundStrategy);

        if (pnl_ > 0) {
            address collateralAddress = address(collateralToken);

            uint256 wethAmount;

            if (collateralAddress == address(CRV)) {
                // 18 decimals
                uint256 usdcAmount = CRV.calc_withdraw_one_coin(pnl_, 0);
                // 8 decimals
                uint256 usdcRatio = AssetsPricing.usdcPriceInUsd(USDC_DECIMALS);
                // 8 decimals
                uint256 ethRatio = AssetsPricing.ethPriceInUsd(PRECISION);

                wethAmount = usdcAmount.mulDivDown(usdcRatio * BASIS_POINTS, ethRatio);
            } else {
                uint256 ratio = AssetsPricing.wstEthRatio();
                wethAmount = pnl_.mulDivDown(ratio, PRECISION);
            }

            return wethAmount;
        }

        return 0;
    }

    // Simulate outcome of the bought options if we were exercising now
    function pnl(address _optionStrategy, address _compoundStrategy) external view returns (uint256) {
        return _pnl(_optionStrategy, _compoundStrategy);
    }

    function getCollateralToken() external view returns (address) {
        return address(collateralToken);
    }

    function strategy() external view override returns (IRouter.OptionStrategy _strategy) {
        if (optionType == OPTION_TYPE.CALLS) {
            return IRouter.OptionStrategy.BULL;
        } else {
            return IRouter.OptionStrategy.BEAR;
        }
    }

    /**
     * @notice Get current SSOV epoch expiry
     */
    function getExpiry() external view returns (uint256) {
        ISSOV _ssov = ssov;

        return _ssov.getEpochData(_ssov.currentEpoch()).expiry;
    }

    /**
     * @notice Get current epoch's strikes
     */
    function getCurrentStrikes() public view returns (uint256[] memory strikes) {
        ISSOV _ssov = ssov;

        return _ssov.getEpochData(_ssov.currentEpoch()).strikes;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ONLY FACTORY                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Add Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external override {
        if (!(hasRole(OPERATOR, msg.sender) || (msg.sender == factory))) {
            revert CallerIsNotAllowed();
        }

        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
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

    function updateFactory(address _factory) external onlyGovernor {
        factory = _factory;
    }

    /* -------------------------------------------------------------------------- */
    /*                                     PRIVATE                                */
    /* -------------------------------------------------------------------------- */

    function _executeOptionsPurchase(
        ISSOV _ssov,
        uint256 _epoch,
        uint256 _totalCollateral,
        uint256[] calldata _collateralEachStrike,
        uint256 _expiry,
        uint256[] calldata _strikes,
        address _thisAddress
    ) private {
        ExecuteInfo memory info;
        for (uint256 i; i < _strikes.length; ++i) {
            // If its 0 it means we are not buying any option in this strike
            if (_collateralEachStrike[i] == 0) continue;

            // Copy to memory to avoid Stack Too Deep
            info.collateralEachStrike = _collateralEachStrike;

            // Simulate how many options will be bought with the desidered collateral %
            // strikesToBuy needs to be in $ value. ie: $2100
            // IMPORTANT: _strikes[i] and _percentageEachStrike need to match DopEx strikes!!!

            info.collateralAmount = _totalCollateral.mulDivDown(_collateralEachStrike[i], BASIS_POINTS);
            (info.optionsAmount,) = estimateOptionsPerToken(info.collateralAmount, _strikes[i], _expiry);

            // Cant purchase 0 options
            if (info.optionsAmount == 0) revert ZeroAmount();

            // Buys options and sends to receiver
            (info.premium, info.totalFee) = _ssov.purchase(i, info.optionsAmount, _thisAddress);

            IOptionStrategy.Strike memory _optionStrike = _getBoughtStrike(msg.sender, _epoch, _strikes[i]);

            if (_optionStrike.currentOptions == 0) {
                // Add  the bought strike data to the storage of Option Strategy in order to handle mid epoch deposits
                IOptionStrategy(msg.sender).addBoughtStrikes(
                    _epoch,
                    IOption(_thisAddress),
                    IOptionStrategy.Strike({
                        price: _strikes[i],
                        costIndividual: (info.premium + info.totalFee).mulDivDown(PRECISION, info.optionsAmount),
                        costTotal: info.premium + info.totalFee,
                        percentageOverTotalCollateral: info.collateralEachStrike[i],
                        currentOptions: info.optionsAmount
                    })
                );
            } else {
                // Update the bought strike data to the storage of Option Strategy in order to handle mid epoch deposits
                IOptionStrategy(msg.sender).updateOptionStrike(
                    _epoch,
                    IOption(_thisAddress),
                    _strikes[i],
                    IOptionStrategy.Strike({
                        price: _strikes[i],
                        costIndividual: (
                            _optionStrike.costIndividual
                                + (info.premium + info.totalFee).mulDivDown(PRECISION, info.optionsAmount)
                            ) / 2,
                        costTotal: (_optionStrike.costTotal + info.premium + info.totalFee) / 2,
                        percentageOverTotalCollateral: (
                            _optionStrike.percentageOverTotalCollateral + info.collateralEachStrike[i]
                            ) / 2,
                        currentOptions: _optionStrike.currentOptions + info.optionsAmount
                    })
                );
            }
        }
    }

    // On calls swap wETH to wstETH / on puts swap to 2crv and return amount received of collateral token
    function _swapToCollateral(uint256 _wethAmount, address _collateralToken, address _thisAddress)
        private
        returns (uint256)
    {
        uint256 slippage_ = slippage;
        uint256 minAmountOut;

        if (_collateralToken == address(wstETH)) {
            uint256 ratio = AssetsPricing.wstEthRatio();

            minAmountOut = _wethAmount.mulDivDown(PRECISION, ratio).mulDivDown(slippage_, BASIS_POINTS);

            IERC20(_collateralToken).approve(address(BALANCER_VAULT), _wethAmount);

            return
                BALANCER_VAULT.swapWethToWstEth(_thisAddress, _thisAddress, _wethAmount, minAmountOut, block.timestamp);
        }

        // Get the USDC value of _wethAmount
        uint256 minStableAmount = AssetsPricing.ethPriceInUsdc(_wethAmount).mulDivDown(slippage_, BASIS_POINTS);

        // Simulate depositing USDC and minting 2crv, applying slippage_ in the final amount
        minAmountOut = AssetsPricing.get2CrvAmountFromDeposit(minStableAmount).mulDivDown(slippage_, BASIS_POINTS);

        WETH.approve(SUSHI_ROUTER, _wethAmount);

        return
            CRV.swapTokenFor2Crv(address(WETH), _wethAmount, address(USDC), minStableAmount, minAmountOut, _thisAddress);
    }

    function _swapToWeth(uint256 _collateralAmount, address _collateralToken) private returns (uint256) {
        uint256 slippage_ = slippage;
        uint256 minAmountOut;

        // Calls scenario
        if (_collateralToken == address(wstETH)) {
            uint256 ratio = AssetsPricing.wstEthRatio();

            // Get min amount out in WETH by converting WSTETH to WETH
            // Apply slippage to final result
            minAmountOut = _collateralAmount.mulDivDown(ratio, PRECISION).mulDivDown(slippage_, BASIS_POINTS);

            IERC20(_collateralToken).approve(address(BALANCER_VAULT), _collateralAmount);

            // Swap WSTETH -> WETH
            return BALANCER_VAULT.swapWstEthToWeth(
                address(this), address(this), _collateralAmount, minAmountOut, block.timestamp
            );
        }

        // Puts scenario
        // Simulate withdrawing 2CRV -> USDC
        // Returns 6 decimals
        uint256 amountOut = AssetsPricing.getUsdcAmountFromWithdraw(_collateralAmount);

        if (amountOut > 1e6) {
            uint256 ethPrice = AssetsPricing.ethPriceInUsd(PRECISION);
            uint256 usdcPrice = AssetsPricing.usdcPriceInUsd(USDC_DECIMALS);

            // Apply slippage to amount of USDC we get from 2CRV
            uint256 minStableAmount = amountOut.mulDivDown(slippage_, BASIS_POINTS);

            // WETH minAmountOut
            minAmountOut =
                minStableAmount.mulDivDown(usdcPrice * BASIS_POINTS, ethPrice).mulDivDown(slippage_, BASIS_POINTS);

            IERC20(_collateralToken).approve(SUSHI_ROUTER, _collateralAmount);

            return CRV.swap2CrvForToken(
                address(WETH), _collateralAmount, address(USDC), minStableAmount, minAmountOut, address(this)
            );
        }

        return 0;
    }

    /**
     * @notice Given the notional value of a strike, return its index
     */
    function _getStrikeIndex(ISSOV _ssov, uint256 _strike) private view returns (uint256) {
        uint256[] memory strikes = _ssov.getEpochData(_ssov.currentEpoch()).strikes;

        for (uint256 i; i < strikes.length; i++) {
            if (strikes[i] == _strike) return i;
        }

        revert StrikeNotFound(_strike);
    }

    /**
     * @notice return current option pnl
     * @return pnl_ if > 0, the amount of profit we will have, quoted in options collateral token
     */
    function _pnl(address _optionStrategy, address _compoundStrategy) private view returns (uint256 pnl_) {
        // Get SSOV for calls/puts
        ISSOV ssov_ = ssov;

        uint256 ssovEpoch = ssov_.currentEpoch();

        // Load strikes from current epoch for the given SSOV
        ISSOV.EpochData memory epochData = ssov_.getEpochData(ssovEpoch);
        uint256[] memory strikes = epochData.strikes;

        uint256 length = strikes.length;

        uint256 systemEpoch = ICompoundStrategy(_compoundStrategy).currentEpoch();

        // We need to take into account the paid cost of the option
        IOptionStrategy.Strike[] memory boughtStrikes =
            IOptionStrategy(_optionStrategy).getBoughtStrikes(systemEpoch, IOption(address(this)));

        // Check PNL checking individually PNL on each strike we bought
        for (uint256 i; i < length;) {
            // We get the amount of options we have by checking the balanceOf optionStrategy of the receipt token for the given strike
            uint256 options = _getBoughtStrike(_optionStrategy, systemEpoch, strikes[i]).currentOptions;

            // If we didnt buy any of this strikes' options, continue to the next strike
            if (options > 0) {
                // Puts do not need the field `collateralExchangeRate` so we cant set to 0. If its a CALL, we get from DoPex
                uint256 collateralExchangeRate =
                    optionType == IOption.OPTION_TYPE.PUTS ? 0 : epochData.collateralExchangeRate;

                // Calculate PNL given current underlying token price, strike value in $ (8 decimals) and amount of options we bought.
                pnl_ += ssov_.calculatePnl(ssov_.getUnderlyingPrice(), strikes[i], options, collateralExchangeRate);

                // Amount of collateral paid to buy options in the given strike (premium + fees)
                uint256 totalCostCurrentStrike = _getCostPaid(boughtStrikes, strikes[i]);

                // If pnl > premium + fees
                if (pnl_ > totalCostCurrentStrike) {
                    pnl_ = pnl_ - totalCostCurrentStrike;

                    if (pnl_ > 0) {
                        // Settlement fee is around 0.1% of PNL.
                        unchecked {
                            pnl_ -= ssov_.calculateSettlementFees(pnl_);
                        }
                    }
                } else {
                    pnl_ = 0;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get total cost for one of the purchased strikes
     * @param boughtStrikes Array containing relevant information about bougthStrikes
     * @param _strike Strike we are checking costs
     * @return Returns total costs quoted in options collateral token
     */
    function _getCostPaid(IOptionStrategy.Strike[] memory boughtStrikes, uint256 _strike)
        private
        pure
        returns (uint256)
    {
        uint256 length = boughtStrikes.length;

        for (uint256 i; i < length; i++) {
            if (boughtStrikes[i].price == _strike) return boughtStrikes[i].costTotal;

            unchecked {
                ++i;
            }
        }

        revert StrikeNotFound(_strike);
    }

    /**
     * @notice Get strike bought
     * @param _optionStrategy strategy that bought the strike
     * @param _epoch epoch were the strike was bought
     * @param _strike Stripe price
     * @return Returns Strike bouth
     */
    function _getBoughtStrike(address _optionStrategy, uint256 _epoch, uint256 _strike)
        private
        view
        returns (IOptionStrategy.Strike memory)
    {
        IOptionStrategy.Strike[] memory optionStrike =
            IOptionStrategy(_optionStrategy).getBoughtStrikes(_epoch, IOption(address(this)));

        uint256 length = optionStrike.length;

        for (uint256 i; i < length;) {
            if (optionStrike[i].price == _strike) return optionStrike[i];

            unchecked {
                ++i;
            }
        }

        IOptionStrategy.Strike memory emptyStrike;
        return emptyStrike; // return empty Strike
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposited Collateral Token amount
     * @param _tokenId token ID of the deposit
     */
    event SSOVDeposit(uint256 indexed _epoch, uint256 _strikeIndex, uint256 _amount, uint256 _tokenId);

    event SSOVPurchase(
        uint256 indexed _epoch, uint256[] strikes, uint256[] _percentageEachStrike, uint256 _amount, address _token
    );

    event SSOVSinglePurchase(uint256 indexed _epoch, uint256 _amount, uint256 _optionAmount, uint256 _cost);

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error OutOfRange();
    error NotEnoughCollateral();
    error NotFactory();
    error ZeroAmount();
    error FailSendETH();
    error StrikeNotFound(uint256 strikeNotionalValue);
    error NoSupport();
    error ZeroAddress();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC4626Initializable, IERC20} from "src/vault/ERC4626Initializable.sol";
import {OperableInitializable} from "src/common/OperableInitializable.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";

contract LPBaseVault is ILPVault, ERC4626Initializable, OperableInitializable {
    using FixedPointMathLib for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    // Compound Strategy Contract
    ICompoundStrategy public compoundStrategy;

    // Vault Underlying Asset; LP
    IERC20 public underlying;

    // Vault Type: BULL || BEAR || CRAB
    IRouter.OptionStrategy public vaultType;

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    function initializeVault(
        address _asset,
        string memory _name,
        string memory _symbol,
        IRouter.OptionStrategy _vaultType
    ) external initializer {
        if (_asset == address(0)) {
            revert ZeroAddress();
        }
        underlying = IERC20(_asset);
        vaultType = _vaultType;

        __ERC20_init(_name, _symbol);
        __ERC4626_init(underlying);
        __Governable_init(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                            OVERRIDE ERC4626 STANDARD                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev See {IERC4626-deposit}.
     */
    function deposit(uint256 assets, address receiver) public override onlyOperator returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");
        uint256 shares = previewDeposit(assets);
        _mint(receiver, shares);
        return shares;
    }

    /**
     * @notice Mints Vault shares to receiver.
     * @param _shares The amount of shares to mint.
     * @param _receiver The address to receive the minted assets.
     * @return shares minted
     */
    function mint(uint256 _shares, address _receiver)
        public
        override(ERC4626Initializable, ILPVault)
        onlyOperator
        returns (uint256)
    {
        _mint(_receiver, _shares);
        return _shares;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(uint256 assets, address receiver, address owner) public override onlyOperator returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        override
        onlyOperator
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }

    /**
     * @notice Burn Vault shares of account address.
     * @param _account Shares owner to be burned.
     * @param _shares Amount of shares to be burned.
     */
    function burn(address _account, uint256 _shares) public onlyOperator {
        _burn(_account, _shares);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */

    function totalAssets() public view virtual override(ERC4626Initializable, ILPVault) returns (uint256) {
        return compoundStrategy.vaultAssets(vaultType);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */

    function previewDeposit(uint256 _assets) public view override(ERC4626Initializable, ILPVault) returns (uint256) {
        return super.previewDeposit(_assets);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */

    function previewRedeem(uint256 _shares) public view override(ERC4626Initializable, ILPVault) returns (uint256) {
        return super.previewRedeem(_shares);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY GOVERNOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Sets the strategy contract for this contract.
     * @param _compoundStrategy The new strategy contract address.
     * @dev This function can only be called by the contract governor. Reverts if `_strategy` address is 0.
     */
    function setStrategies(address _compoundStrategy) external virtual onlyGovernor {
        if (_compoundStrategy == address(0)) {
            revert ZeroAddress();
        }
        compoundStrategy = ICompoundStrategy(_compoundStrategy);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ERRORS                                    */
    /* -------------------------------------------------------------------------- */

    error ZeroAddress();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "./UpgradeableGovernable.sol";

abstract contract UpgradeableOperableKeepable is UpgradeableGovernable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    /**
     * @notice Keeper role
     */
    bytes32 public constant KEEPER = bytes32("KEEPER");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper role revert.
     */
    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Operator role revert.
     */
    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Governor role revert.
     */
    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Add Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external virtual onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    /**
     * @notice Add Keeper role to _newKeeper.
     */
    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    /**
     * @notice Remove Keeper role from _keeper.
     */
    function removeKeeper(address _keeper) external onlyGovernor {
        _revokeRole(KEEPER, _keeper);

        emit KeeperRemoved(_keeper);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _keeper);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

interface IWeth is IERC20 {
    function deposit() external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";

interface IZapUniV2 {
    function zapIn(
        address pair,
        bool native,
        address tokenIn,
        uint256 amount,
        IRouter.OptionStrategy strategy,
        bool instant
    ) external payable returns (uint256);
    function setMetavault(address pair, address router, address swapper, address pairAdapter) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISwap} from "src/interfaces/ISwap.sol";

interface ILP {
    // Information needed to build a UniV2Pair
    struct LpInfo {
        ISwap swapper;
        bytes externalData;
    }

    function token0() external view returns (address);
    function token1() external view returns (address);

    function buildLP(uint256 _wethAmount, LpInfo memory _buildInfo) external returns (uint256);
    function breakLP(uint256 _lpAmount, LpInfo memory _swapData) external returns (uint256);
    function buildWithBothTokens(address token0, address token1, uint256 amount0, uint256 amount1)
        external
        returns (uint256);

    function ETHtoLP(uint256 _amount) external view returns (uint256);
    function performBreakAndSwap(uint256 _lpAmount, ISwap _swapper) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";
import {IBeacon} from "openzeppelin-contracts/proxy/beacon/IBeacon.sol";
import {IDiamondCut} from "src/interfaces/diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeBeacon to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForBeaconForCut(address _beaconAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectBeaconCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromBeaconWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveBeaconAddressMustBeZeroAddress(address _beaconAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    /**
     * @notice Diamond storage position.
     */
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /**
     * @notice Beacon and Selector position struct.
     */
    struct BeaconAddressAndSelectorPosition {
        address beaconAddress;
        uint16 selectorPosition;
    }

    /**
     * @notice Diamond storage.
     */
    struct DiamondStorage {
        // function selector => beacon address and selector position in selectors array
        mapping(bytes4 => BeaconAddressAndSelectorPosition) beaconAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    /**
     * @notice Get diamond storage.
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetBeacon(address indexed oldBeacon, address indexed newBeacon);

    /**
     * @notice Set owner.
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /**
     * @notice Get owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice If msg.sender not owner revert.
     */
    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.BeaconCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @notice Procces to Add, replace or Remove Facets.
     */
    function diamondCut(IDiamondCut.BeaconCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 length = _diamondCut.length;
        for (uint256 beaconIndex; beaconIndex < length;) {
            bytes4[] memory functionSelectors = _diamondCut[beaconIndex].functionSelectors;
            address beaconAddress = _diamondCut[beaconIndex].beaconAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForBeaconForCut(beaconAddress);
            }
            IDiamondCut.BeaconCutAction action = _diamondCut[beaconIndex].action;
            if (action == IDiamond.BeaconCutAction.Add) {
                addFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Replace) {
                replaceFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Remove) {
                removeFunctions(beaconAddress, functionSelectors);
            } else {
                revert IncorrectBeaconCutAction(uint8(action));
            }
            unchecked {
                ++beaconIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Procces to Add Facets.
     */
    function addFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        if (_beaconAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Add beacon has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            if (oldBeaconAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.beaconAddressAndSelectorPosition[selector] =
                BeaconAddressAndSelectorPosition(_beaconAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Replace Facets.
     */
    function replaceFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_beaconAddress == address(0)) {
            revert CannotReplaceFunctionsFromBeaconWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Replace beacont has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldBeaconAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldBeaconAddress == _beaconAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(selector);
            }
            if (oldBeaconAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old beacon address
            ds.beaconAddressAndSelectorPosition[selector].beaconAddress = _beaconAddress;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Remove Facets.
     */
    function removeFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_beaconAddress != address(0)) {
            revert RemoveBeaconAddressMustBeZeroAddress(_beaconAddress);
        }
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            BeaconAddressAndSelectorPosition memory oldBeaconAddressAndSelectorPosition =
                ds.beaconAddressAndSelectorPosition[selector];
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldBeaconAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldBeaconAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.beaconAddressAndSelectorPosition[lastSelector].selectorPosition =
                    oldBeaconAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.beaconAddressAndSelectorPosition[selector];

            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to initialize Diamond contract.
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /**
     * @notice Enforce contract.
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }

    /**
     * @notice get beacon implementation.
     */
    function _implementation() internal view returns (address) {
        return IBeacon(diamondStorage().beaconAddressAndSelectorPosition[msg.sig].beaconAddress).implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(IDiamond.BeaconCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Beacon {
        address beaconAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all beacon addresses and their four byte function selectors.
    /// @return beacons_ Beacon
    function beacons() external view returns (Beacon[] memory beacons_);

    /// @notice Gets all the function selectors supported by a specific beacon.
    /// @param _beacon The beacon address.
    /// @return beaconFunctionSelectors_
    function beaconFunctionSelectors(address _beacon)
        external
        view
        returns (bytes4[] memory beaconFunctionSelectors_);

    /// @notice Get all the beacon addresses used by a diamond.
    /// @return beaconAddresses_
    function beaconAddresses() external view returns (address[] memory beaconAddresses_);

    /// @notice Gets the beacon that supports the given selector.
    /// @dev If beacon is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return beaconAddress_ The beacon address.
    function beaconAddress(bytes4 _functionSelector) external view returns (address beaconAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {Governable} from "./Governable.sol";

abstract contract OperableKeepable is Governable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    /**
     * @notice Keeper role
     */
    bytes32 public constant KEEPER = bytes32("KEEPER");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper role revert.
     */
    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Operator role revert.
     */
    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Modifier if msg.sender has not Keeper or Governor role revert.
     */
    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Add Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    /**
     * @notice Add Keeper role to _newKeeper.
     */
    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    /**
     * @notice Remove Keeper role from _keeper.
     */
    function removeKeeper(address _keeper) external onlyGovernor {
        _revokeRole(KEEPER, _keeper);

        emit KeeperRemoved(_keeper);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _keeper);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
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
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

library MasterChefStructs {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}

library RewarderStructs {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unpaidRewards;
    }

    struct PoolInfo {
        uint128 accToken1PerShare;
        uint64 lastRewardTime;
    }
}

interface IRewarder {
    function userInfo(uint256 _pid, address _user) external view returns (RewarderStructs.UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (RewarderStructs.PoolInfo memory);

    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount)
        external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount)
        external
        view
        returns (IERC20[] memory, uint256[] memory);

    function rewardPerSecond() external returns (uint256);
}

interface IMasterChefV2 {
    function userInfo(uint256 _pid, address _user) external view returns (MasterChefStructs.UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (MasterChefStructs.PoolInfo memory);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    function rewarder(uint256 _pid) external view returns (IRewarder);

    function sushiPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IStableSwap} from "src/interfaces/swap/IStableSwap.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

/**
 * @title AssetsPricing
 * @author JonesDAO
 * @notice Helper contract to aggregate the process of fetching prices internally across Metavaults V2 product.
 */
library AssetsPricing {
    //////////////////////////////////////////////////////////
    //                  CONSTANTS
    //////////////////////////////////////////////////////////

    // @notice Chainlink ETH/USD oracle (8 decimals)
    IAggregatorV3 public constant ETH_ORACLE = IAggregatorV3(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    // @notice Chainlink USDC/USD oracle (8 decimals)
    IAggregatorV3 public constant USDC_ORACLE = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    // @notice Chainlink stETH/ETH oracle (18 decimals)
    IAggregatorV3 public constant ST_ETH_ORACLE = IAggregatorV3(0x07C5b924399cc23c24a95c8743DE4006a32b7f2a);

    // @notice Chainlink wstETH/stETH ratio oracle (18 decimals)
    IAggregatorV3 public constant WST_ETH_ORACLE = IAggregatorV3(0xB1552C5e96B312d0Bf8b554186F846C40614a540);

    // @notice Chainlink wstETH/ETH ratio oracle (18 decimals)
    IAggregatorV3 public constant WST_ETH_RATIO_ORACLE = IAggregatorV3(0xb523AE262D20A936BC152e6023996e46FDC2A95D);

    // @notice Curve's 2CRV
    IStableSwap public constant CRV = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    // @notice Used to normalize results to 18 decimals
    uint256 private constant STANDARD_DECIMALS = 1e18;

    // @notice Used to normalize USDC functions
    uint256 private constant USDC_DECIMALS = 1e6;

    //////////////////////////////////////////////////////////
    //                  UniV2 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @param _lp Pool that will happen the token swap
     * @param _amountIn Amount of tokens that will be swapped
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @return min amount of tokens with slippage applied
     */
    function getAmountOut(address _lp, uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256)
    {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(_lp, _tokenIn, _tokenOut);

        return UniswapV2Library.getAmountOut(_amountIn, reserveA, reserveB);
    }

    /**
     * @notice Get an estimation of token0 and token1 from breaking a given amount of LP
     * @param _lp LP token that will be used to simulate
     * @param _liquidityAmount Amount of LP tokens
     * @return Amount of token0
     * @return Amount of token1
     */
    function breakFromLiquidityAmount(address _lp, uint256 _liquidityAmount) public view returns (uint256, uint256) {
        uint256 totalLiquidity = IERC20(_lp).totalSupply();

        IERC20 _tokenA = IERC20(IUniswapV2Pair(_lp).token0());
        IERC20 _tokenB = IERC20(IUniswapV2Pair(_lp).token1());

        uint256 _amountA = (_tokenA.balanceOf(_lp) * _liquidityAmount) / totalLiquidity;
        uint256 _amountB = (_tokenB.balanceOf(_lp) * _liquidityAmount) / totalLiquidity;

        return (_amountA, _amountB);
    }

    /**
     * @notice Get estimation amount of LP tokens that will be received going from token0 or token1
     * @param _lp LP token that will be used to simulate
     * @param _tokenIn token0 or token1
     * @param _tokenAmount Amount of token0 or token1
     * @dev We dont verify it tokenIn is part of the LP because we do it in other parts of the code
     */
    function tokenToLiquidity(address _lp, address _tokenIn, uint256 _tokenAmount) public view returns (uint256) {
        (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(_lp).getReserves();
        uint256 totalToken;

        if (_tokenIn == IUniswapV2Pair(_lp).token0()) {
            totalToken = reserveA;
        } else {
            totalToken = reserveB;
        }

        uint256 totalSupply = IERC20(_lp).totalSupply();

        return (totalSupply * _tokenAmount) / (totalToken * 2);
    }

    //////////////////////////////////////////////////////////
    //                  ASSETS PRICING
    //////////////////////////////////////////////////////////

    /**
     * @notice Returns wstETH price quoted in USD
     * @dev Returns value in 8 decimals
     */
    function wstEthPriceInUsd(uint256 amount) external view returns (uint256) {
        (, int256 stEthPrice,,,) = ST_ETH_ORACLE.latestRoundData();
        (, int256 wstEthRatio_,,,) = WST_ETH_ORACLE.latestRoundData();

        uint256 priceInEth = (uint256(stEthPrice) * uint256(wstEthRatio_)) / STANDARD_DECIMALS;

        return (amount * priceInEth) / STANDARD_DECIMALS;
    }

    /**
     * @notice Returns an arbitrary amount of wETH quoted in USD
     * @dev Returns value in 8 decimals
     */
    function ethPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 ethPrice,,,) = ETH_ORACLE.latestRoundData();

        return (uint256(ethPrice) * amount) / STANDARD_DECIMALS;
    }

    function ethPriceInUsdc(uint256 amount) external view returns (uint256) {
        // 8 decimals + 6 decimals
        uint256 ethPriceInUsd_ = ethPriceInUsd(amount) * USDC_DECIMALS;
        uint256 usdcPriceInUsd_ = usdcPriceInUsd(USDC_DECIMALS);

        return ethPriceInUsd_ / usdcPriceInUsd_;
    }

    /**
     * @notice Returns wstETH quoted in ETH
     * @dev Returns value with 18 decimals
     */
    function wstEthRatio() external view returns (uint256) {
        (, int256 wstEthRatio_,,,) = WST_ETH_RATIO_ORACLE.latestRoundData();

        return uint256(wstEthRatio_);
    }

    /**
     * @notice Returns USD price of USDC
     * @dev Returns value with 8 decimals
     */
    function usdcPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 usdcPrice,,,) = USDC_ORACLE.latestRoundData();

        return (uint256(usdcPrice) * amount) / USDC_DECIMALS;
    }

    /**
     * @notice Returns the amount of 2crv that will be received from depositing given amount of USDC
     * @notice Since this is an unbalanced deposit, we may incur some positive or negative slippage
     * @dev 2crv = 18 decimals
     * @return 2crv amount that will be received
     */
    function get2CrvAmountFromDeposit(uint256 _usdcAmount) external view returns (uint256) {
        // First array element is USDC and second USDT, we pass it == true since its a deposit
        // Receive 2crv amount accounting for slippage but not fees
        return CRV.calc_token_amount([_usdcAmount, 0], true);
    }

    /**
     * @notice Returns amount of USDC that will be received by redeeming an amount of 2crv
     * @dev 6 decimals return
     * @return USDC amount
     */
    function getUsdcAmountFromWithdraw(uint256 _2crvAmount) public view returns (uint256) {
        return CRV.calc_withdraw_one_coin(_2crvAmount, 0);
    }

    function getUsdValueFromWithdraw(uint256 _2crvAmount) external view returns (uint256) {
        uint256 usdcAmount = getUsdcAmountFromWithdraw(_2crvAmount);

        return usdcPriceInUsd(usdcAmount);
    }
}

// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.10;

import {UpgradeableGovernable} from "src/common/UpgradeableGovernable.sol";
import {ILpsRegistry} from "src/interfaces/common/ILpsRegistry.sol";

/**
 * @title LpsRegistry
 * @author JonesDAO
 * @notice Contract to store information about tokens and its liquidity pools pairs
 */
contract LpsRegistry is ILpsRegistry, UpgradeableGovernable {
    // underlyingToken -> lpToken
    mapping(address => address) public lpToken;

    // underlyingToken -> poolId
    mapping(address => uint256) public poolID;

    // underlyingToken -> rewardToken
    mapping(address => address) public rewardToken;

    address private constant SUSHI = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant SUSHI_LP = 0x3221022e37029923aCe4235D812273C5A42C322d;

    function initialize() public initializer {
        __Governable_init(msg.sender);

        lpAddress[SUSHI][WETH] = SUSHI_LP;
        lpAddress[WETH][SUSHI] = SUSHI_LP;

        lpToken[SUSHI] = SUSHI_LP;
        poolID[SUSHI] = 0;
        rewardToken[SUSHI] = SUSHI;
    }

    //////////////////////////////////////////////////////////
    //                  STORAGE
    //////////////////////////////////////////////////////////

    /**
     * @notice Store the LP pair address for a given token0. Use public function to get the LP address for the given route.
     * @dev tokenIn => tokenOut => LP
     */
    mapping(address => mapping(address => address)) private lpAddress;

    //////////////////////////////////////////////////////////
    //                  GOVERNOR FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @notice Populates `lpAddress` for both ways swaps
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @param _liquidityPool Address of the sushi pool that contains both tokens
     */
    function addWhitelistedLp(
        address _tokenIn,
        address _tokenOut,
        address _liquidityPool,
        address _rewardToken,
        uint256 _poolID
    ) external onlyGovernor {
        if (_tokenIn == address(0) || _tokenOut == address(0) || _liquidityPool == address(0)) {
            revert ZeroAddress();
        }

        // Add support to both ways swaps since it occurs using same LP
        lpAddress[_tokenIn][_tokenOut] = _liquidityPool;
        lpAddress[_tokenOut][_tokenIn] = _liquidityPool;
        lpToken[_tokenIn] = _liquidityPool;
        poolID[_tokenIn] = _poolID;
        rewardToken[_tokenIn] = _rewardToken;
    }

    /**
     * @notice Sets 0 values for given LP and path
     * @param _tokenIn token0
     * @param _tokenOut token1
     */
    function removeWhitelistedLp(address _tokenIn, address _tokenOut) external onlyGovernor {
        if (_tokenIn == address(0) || _tokenOut == address(0)) {
            revert ZeroAddress();
        }

        lpAddress[_tokenIn][_tokenOut] = address(0);
        lpAddress[_tokenOut][_tokenIn] = address(0);
        lpToken[_tokenIn] = address(0);
        poolID[_tokenIn] = 0;
        rewardToken[_tokenIn] = address(0);
    }

    function updateGovernor(address _newGovernor) external override(ILpsRegistry, UpgradeableGovernable) onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    //////////////////////////////////////////////////////////
    //                  VIEW FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @notice Gets the address of the pool that contains the desired tokens
     * @param _tokenIn Received token
     * @param _tokenOut wanted token
     * @return Returns univ2 pool address for the given tokens
     * @dev will revert if there's no pool set for the given tokens
     */
    function getLpAddress(address _tokenIn, address _tokenOut) public view returns (address) {
        address pair = lpAddress[_tokenIn][_tokenOut];

        if (pair == address(0)) {
            revert ZeroAddress();
        }

        return pair;
    }

    error ZeroAddress();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {IUniswapV2Factory} from "src/interfaces/lp/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

interface IUniswapV2Router is IUniswapV2Factory, IUniswapV2Pair {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISSOV} from "src/interfaces/option/dopex/ISSOV.sol";

interface ISSOVViewer {
    function getEpochStrikeTokens(uint256 epoch, ISSOV ssov) external view returns (address[] memory strikeTokens);

    function walletOfOwner(address owner, ISSOV ssov) external view returns (uint256[] memory tokenIds);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, address receiver)
        external
        returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);
    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts, address receiver)
        external
        returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount, address receiver)
        external
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./IWETH.sol";
import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";

import "./ISignaturesValidator.sol";
import "./ITemporarilyPausable.sol";

pragma solidity ^0.8.10;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(address sender, address relayer, bool approved) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     *  without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId, IERC20 indexed tokenIn, IERC20 indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

// Interfaces
import {IStableSwap} from "src/interfaces/swap/IStableSwap.sol";
import {IUniswapV2Router02} from "src/interfaces/farm/IUniswapV2Router02.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

library Curve2PoolAdapter {
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    IUniswapV2Router02 constant sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

    /**
     * @notice Swaps a token for 2CRV
     * @param _inputToken The token to swap
     * @param _amount The token amount to swap
     * @param _stableToken The address of the stable token to swap the `_inputToken`
     * @param _minStableAmount The minimum output amount of `_stableToken`
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapTokenFor2Crv(
        IStableSwap self,
        address _inputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        address[] memory route = _swapTokenFor2CrvRoute(_inputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(_amount, _minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(self, _stableToken, stableOutput, _min2CrvAmount);

        emit SwapTokenFor2Crv(_amount, amountOut, _inputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForToken(
        IStableSwap self,
        address _outputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        uint256 stableAmount = swap2CrvForStable(self, _stableToken, _amount, _minStableAmount);

        address[] memory route = _swapStableForTokenRoute(_outputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(stableAmount, _minTokenAmount, route, _recipient, block.timestamp);

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(IStableSwap self, address _stableToken, uint256 _amount, uint256 _minStableAmount)
        public
        returns (uint256)
    {
        int128 stableIndex;

        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return self.remove_liquidity_one_coin(_amount, stableIndex, _minStableAmount);
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function swapStableFor2Crv(IStableSwap self, address _stableToken, uint256 _amount, uint256 _min2CrvAmount)
        public
        returns (uint256)
    {
        uint256[2] memory deposits;
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        IERC20(_stableToken).approve(address(self), _amount);

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    /**
     * @notice Get route to swap stable for other token.
     */
    function _swapStableForTokenRoute(address _outputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_outputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _stableToken;
            route[1] = _outputToken;
        } else {
            route = new address[](3);
            route[0] = _stableToken;
            route[1] = WETH;
            route[2] = _outputToken;
        }
        return route;
    }

    /**
     * @notice Get route to swap an asset for 2crv.
     */
    function _swapTokenFor2CrvRoute(address _inputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_inputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _inputToken;
            route[1] = _stableToken;
        } else {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = WETH;
            route[2] = _stableToken;
        }
        return route;
    }

    event Swap2CrvForToken(uint256 _amountIn, uint256 _amountOut, address _token);
    event SwapTokenFor2Crv(uint256 _amountIn, uint256 _amountOut, address _token);

    error INVALID_STABLE_TOKEN();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

// Interfaces
import {IVault} from "src/interfaces/swap/balancer/IVault.sol";
import {IAsset} from "src/interfaces/swap/balancer/IAsset.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

library BalancerWstethAdapter {
    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant wsteth = 0x5979D7b546E38E414F7E9822514be443A4800529;

    bytes32 public constant wethwstethPool = hex"36bf227d6bac96e2ab1ebb5492ecec69c691943f000200000000000000000316";

    /**
     * @notice Swap wEth to wsETH in balancer.
     */
    function swapWethToWstEth(
        IVault self,
        address fromAddress,
        address toAddress,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) public returns (uint256) {
        IVault.SingleSwap memory singleSwap =
            IVault.SingleSwap(wethwstethPool, IVault.SwapKind.GIVEN_IN, IAsset(weth), IAsset(wsteth), amountIn, "");

        IVault.FundManagement memory fundManagement =
            IVault.FundManagement(fromAddress, false, payable(toAddress), false);

        IERC20(weth).approve(address(self), amountIn);

        return self.swap(singleSwap, fundManagement, minAmountOut, deadline);
    }

    /**
     * @notice Swap wsETH to wETH in balancer.
     */
    function swapWstEthToWeth(
        IVault self,
        address fromAddress,
        address toAddress,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) public returns (uint256) {
        IVault.SingleSwap memory singleSwap =
            IVault.SingleSwap(wethwstethPool, IVault.SwapKind.GIVEN_IN, IAsset(wsteth), IAsset(weth), amountIn, "");

        IVault.FundManagement memory fundManagement =
            IVault.FundManagement(fromAddress, false, payable(toAddress), false);

        IERC20(weth).approve(address(self), amountIn);

        return self.swap(singleSwap, fundManagement, minAmountOut, deadline);
    }
}

// SPDX-License-Identifier: MIT
// MODIFICATION OF OpenZeppelin Contracts IN ORDER TO INITIALIZE BUT NOT UPGRADE
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import {ERC20Initializable, IERC20Metadata, IERC20} from "src/vault/ERC20Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
 * a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626Initializable is ERC20Initializable, IERC4626 {
    using Math for uint256;

    IERC20 private _asset;
    uint8 private _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20 asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20 asset_) internal onlyInitializing {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) =
            address(asset_).staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20Initializable) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC4626-asset}.
     */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * @dev See {IERC4626-totalAssets}.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /**
     * @dev See {IERC4626-convertToShares}.
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-convertToAssets}.
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-maxDeposit}.
     */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /**
     * @dev See {IERC4626-maxMint}.
     */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev See {IERC4626-maxWithdraw}.
     */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-maxRedeem}.
     */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-previewMint}.
     */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /**
     * @dev See {IERC4626-previewWithdraw}.
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /**
     * @dev See {IERC4626-previewRedeem}.
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-deposit}.
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /**
     * @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return (assets == 0 || supply == 0)
            ? _initialConvertToShares(assets, rounding)
            : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(uint256 assets, Math.Rounding /*rounding*/ )
        internal
        view
        virtual
        returns (uint256 shares)
    {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(uint256 shares, Math.Rounding /*rounding*/ )
        internal
        view
        virtual
        returns (uint256 assets)
    {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {Governable} from "./Governable.sol";

abstract contract OperableInitializable is Governable {
    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Only msg.sender with OPERATOR role can call the function.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                ONLY GOVERNOR                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Grant Operator role to _newOperator.
     */
    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

abstract contract Governable is Initializable, AccessControl {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal onlyInitializing {
        _grantRole(GOVERNOR, _governor);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

library SafeMathUniswap {
    /**
     * @notice Safe sum of uint256.
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    /**
     * @notice Safe subtraction of uint256.
     */
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    /**
     * @notice Safe multiplication of uint256.
     */
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    /**
     * @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order.
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /**
     * @notice Fetches and sorts the reserves for a pair.
     */
    function getReserves(address pair, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset.
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for the WETH token contract used internally for wrapping and unwrapping, to support
 * sending and receiving ETH in joins, swaps, and internal balance deposits and withdrawals.
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
// solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(bytes32 actionId, address account, address where) external view returns (bool);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (bool paused, uint256 pauseWindowEndTime, uint256 bufferPeriodEndTime);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IUniswapV2Router01} from "src/interfaces/farm/IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// MODIFICATION OF OpenZeppelin Contracts IN ORDER TO INITIALIZE BUT NOT UPGRADE
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Context} from "openzeppelin-contracts/utils/Context.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Initializable is Initializable, Context, IERC20, IERC20Metadata {
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
     * All two of these values are "immutable": they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}