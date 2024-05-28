// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { WETHGateway } from "@radiant-v2-core/lending/WETHGateway.sol";
import { Errors } from "./libraries/Errors.sol";
import { RizLendingPoolConfigurator } from "./riz-lending/RizLendingPoolConfigurator.sol";
import { RizLendingPool } from "./riz-lending/RizLendingPool.sol";
import {
    RizLendingPoolAddressesProvider,
    IRizLendingPoolAddressesProvider
} from "./riz-lending/RizLendingPoolAddressesProvider.sol";
import { ILendingPoolAddressesProvider } from "@radiant-v2-core/interfaces/ILendingPoolAddressesProvider.sol";
import { ILendingPoolConfigurator } from "@radiant-v2-core/interfaces/ILendingPoolConfigurator.sol";
import { LendingRateOracle } from "@radiant-v2-core/mocks/oracle/LendingRateOracle.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { BadDebtManager } from "./BadDebtManager.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AToken } from "@radiant-v2-core/lending/tokenization/AToken.sol";

/// @title RizRegistry
/// @author Radiant
/// @dev This upgradeable contract does not require a ProxyAdmin, and it is compatible with `UUPSUpgradeable`.
contract RizRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Clones for address;
    //////////////// <*_*> Constants <*_*> ////////////////

    bytes32 public constant LENDING_POOL = "LENDING_POOL";
    bytes32 public constant LENDING_POOL_ADDRESSES_PROVIDER = "LENDING_POOL_ADDRESSES_PROVIDER";
    bytes32 public constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
    bytes32 public constant LENDING_POOL_COLLATERAL_MANAGER = "COLLATERAL_MANAGER";
    bytes32 public constant DATA_PROVIDER = "DATA_PROVIDER";
    bytes32 public constant LEVERAGER = "LEVERAGER";
    bytes32 public constant ATOKEN = "ATOKEN";
    bytes32 public constant STABLE_DEBT_TOKEN = "STABLE_DEBT_TOKEN";
    bytes32 public constant VARIABLE_DEBT_TOKEN = "VARIABLE_DEBT_TOKEN";
    bytes32 public constant INTEREST_RATE_STRATEGY = "INTEREST_RATE_STRATEGY";
    bytes32 public constant BAD_DEBT_MANAGER = "BAD_DEBT_MANAGER";

    //////////////// <*_*> Storage <*_*> ////////////////
    mapping(bytes32 => address) public implementations;
    mapping(address => bool) private _isValidAddressProvider;
    mapping(address => bool) private _lendingPools;
    mapping(string => address) public _marketIdToAddressProvider;
    address[] private _addressesProvidersList;

    address public emergencyAdmin;
    address public treasury;
    address public oracle;

    WETHGateway public wEthGateway;

    //////////////// =^..^= Events =^..^= ////////////////
    event WethGatewaySet(address wethGateway);
    event BadDebtManagerSet(address badDebtManager);
    event ImplementationSet(bytes32 indexed id, address implementation);
    event ImplementationSet(bytes32 indexed id, address implementation, address addressProvider);
    event PoolRegistered(address addressProvider, string marketId);
    event EmergencyAdminSet(address newEmergencyAdmin);
    event TreasurySet(address newTreasury);
    event OracleSet(address newOracle);
    event EnabledBorrowingOnReserve(address addressProvider, address asset, bool stableBorrowRateEnabled);
    event BorrowingDisabledOnReserve(address addressProvider, address asset);
    event ReserveInterestRateStrategyChanged(
        address lendingPoolAddressesProvider, address asset, address rateStrategyAddress
    );
    event StableRateEnabledOnReserve(address lendingPoolAddressesProvider, address asset);
    event StableRateDisabledOnReserve(address lendingPoolAddressesProvider, address asset);
    event ReserveActivated(address lendingPoolAddressesProvider, address asset);
    event ReserveDeactivated(address lendingPoolAddressesProvider, address asset);
    event ReserveFrozen(address lendingPoolAddressesProvider, address asset);
    event ReserveUnfrozen(address lendingPoolAddressesProvider, address asset);
    event ReserveFactorChanged(address lendingPoolAddressesProvider, address asset, uint256 reserveFactor);
    event LendingPoolToggled(address lendingPool, bool enabled);
    event OracleRouterSet(address addressProvider, address oracleRouter);
    event TreasuryAddressUpdated(address newTreasury);

    error TransferFailed();

    constructor() {
        _disableInitializers();
    }

    ////////////////// ô¿ô External and Public Functions ô¿ô //////////////////

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @notice View that returns the address of the address provider by market id
    /// @param marketId_ The market id
    function getAddressProviderByMarketId(string calldata marketId_) external view returns (address) {
        return _marketIdToAddressProvider[marketId_];
    }

    /// @notice View that returns all address providers
    /// @return The list of address providers
    function getAddressProvidersList() external view returns (address[] memory) {
        return _addressesProvidersList;
    }

    /// @notice Function to validate if given LendingPool is registered in the RizRegistry and active
    /// @param pool The address of the LendingPool
    function isLendingPoolValid(address pool) external view returns (bool) {
        return _lendingPools[pool];
    }

    /// @notice Update the status of a LendingPool
    /// @param addressProvider The address of the address provider
    /// @param status The new status of the LendingPool (true = active, false = inactive)
    function updateLendingPoolStatus(address addressProvider, bool status) external {
        if (!_isValidAddressProvider[address(addressProvider)]) {
            revert Errors.NoAddressProvider();
        }

        RizLendingPoolAddressesProvider provider = RizLendingPoolAddressesProvider(addressProvider);

        address configurator = provider.getLendingPoolConfigurator();
        if (msg.sender != configurator) {
            revert Errors.NotLPConfigurator();
        }

        address pool = provider.getLendingPool();
        if (!_lendingPools[pool]) {
            revert Errors.InvalidLendingPool();
        }

        _lendingPools[pool] = status;
        emit LendingPoolToggled(pool, status);
    }

    /// @notice Create and register a new lending pool
    /// @param marketId_ The market id
    function addPool(string calldata marketId_) external onlyOwner {
        if (
            implementations[LENDING_POOL_ADDRESSES_PROVIDER] == address(0)
                || implementations[BAD_DEBT_MANAGER] == address(0)
        ) {
            revert Errors.NotAContract();
        }
        // Deploy LendingPoolAddressesProvider
        address addressProviderAddr = Clones.clone(implementations[LENDING_POOL_ADDRESSES_PROVIDER]);
        RizLendingPoolAddressesProvider addressProvider = RizLendingPoolAddressesProvider(addressProviderAddr);
        addressProvider.initialize(marketId_);
        LendingRateOracle lendingRateOracle = new LendingRateOracle();
        addressProvider.setPoolAdmin(address(this));
        addressProvider.setLendingRateOracle(address(lendingRateOracle));
        addressProvider.setEmergencyAdmin(emergencyAdmin);
        addressProvider.setLiquidationFeeTo(treasury);
        addressProvider.setLendingPoolImpl(implementations[LENDING_POOL]);
        addressProvider.setLendingPoolConfiguratorImpl(implementations[LENDING_POOL_CONFIGURATOR]);
        address lendingPool = addressProvider.getLendingPool();
        wEthGateway.authorizeLendingPool(lendingPool);
        // Add LendingPool address to _isPoolRegistered mapping
        _lendingPools[addressProvider.getLendingPool()] = true;
        addressProvider.setPriceOracle(oracle);
        // Deploy bad debt manager
        address badDebtManager = Clones.clone(implementations[BAD_DEBT_MANAGER]);
        BadDebtManager(badDebtManager).initialize(lendingPool, owner());
        addressProvider.setBadDebtManager(badDebtManager);

        addressProvider.setLendingPoolCollateralManager(implementations[LENDING_POOL_COLLATERAL_MANAGER]);
        _registerPool(address(addressProvider), marketId_);
    }

    /// @notice Set the implementation of a contract by its id. Reverts if the implementation is not a contract
    /// @param implId The id of the contract
    /// @param implAddress The address of the implementation
    /// @param notifyAllProviders True if `implId` is applicable to update at all providers
    function setImplementation(bytes32 implId, address implAddress, bool notifyAllProviders) external onlyOwner {
        // Make sure the implementation is a contract
        if (!implAddress.isContract()) {
            revert Errors.NotAContract();
        }
        implementations[implId] = implAddress;

        if (notifyAllProviders) {
            uint256 providersCount = _addressesProvidersList.length;
            for (uint256 i; i < providersCount;) {
                if (_isValidAddressProvider[_addressesProvidersList[i]]) {
                    if (implId == LENDING_POOL) {
                        ILendingPoolAddressesProvider(_addressesProvidersList[i]).setLendingPoolImpl(implAddress);
                    } else if (implId == LENDING_POOL_CONFIGURATOR) {
                        ILendingPoolAddressesProvider(_addressesProvidersList[i]).setLendingPoolConfiguratorImpl(
                            implAddress
                        );
                    } else {
                        ILendingPoolAddressesProvider(_addressesProvidersList[i]).setAddressAsProxy(implId, implAddress);
                    }
                    emit ImplementationSet(implId, implAddress, _addressesProvidersList[i]);
                }
                unchecked {
                    i++;
                }
            }
        } else {
            emit ImplementationSet(implId, implAddress);
        }
    }

    /// @notice Set the emergency admin for all addresses providers
    /// @param newEmergencyAdmin The new emergency admin
    function setEmergencyAdmin(address newEmergencyAdmin) external onlyOwner {
        emergencyAdmin = newEmergencyAdmin;

        uint256 providersCount = _addressesProvidersList.length;
        for (uint256 i; i < providersCount;) {
            ILendingPoolAddressesProvider(_addressesProvidersList[i]).setEmergencyAdmin(newEmergencyAdmin);

            unchecked {
                i++;
            }
        }
        emit EmergencyAdminSet(newEmergencyAdmin);
    }

    /// @notice Set the WETH gateway
    /// @param wethGateway_ The address of the WETH gateway
    function setWethGateway(address payable wethGateway_) external onlyOwner {
        // Make sure the WETH gateway is a contract
        if (!address(wethGateway_).isContract()) {
            revert Errors.NotAContract();
        }
        wEthGateway = WETHGateway(wethGateway_);
        emit WethGatewaySet(wethGateway_);
    }

    /// @notice Sets the treasury address
    /// @param treasury_ The address of the treasury
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
        emit TreasurySet(treasury_);
    }

    /// @notice Sets the oracle address
    /// @param oracle_ The address of the oracle
    function setOracle(address oracle_) external onlyOwner {
        // Make sure the oracle is a contract
        if (!oracle_.isContract()) {
            revert Errors.NotAContract();
        }
        oracle = oracle_;
        emit OracleSet(oracle_);
    }

    /// @notice Sets borrow caps
    /// @param addressProvider The address of the address provider
    /// @param assets The assets to set the borrow caps
    /// @param borrowCaps The borrow caps
    function setBorrowCaps(address addressProvider, address[] calldata assets, uint256[] calldata borrowCaps)
        external
        onlyOwner
    {
        address configurator = ILendingPoolAddressesProvider(addressProvider).getLendingPoolConfigurator();
        for (uint256 i; i < assets.length;) {
            RizLendingPoolConfigurator(configurator).setBorrowCap(assets[i], borrowCaps[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Sets supply caps
    /// @param addressProvider The address of the address provider
    /// @param assets The assets to set the supply caps
    /// @param supplyCaps The supply caps
    function setSupplyCaps(address addressProvider, address[] calldata assets, uint256[] calldata supplyCaps)
        external
        onlyOwner
    {
        address configurator = ILendingPoolAddressesProvider(addressProvider).getLendingPoolConfigurator();
        for (uint256 i; i < assets.length;) {
            RizLendingPoolConfigurator(configurator).setSupplyCap(assets[i], supplyCaps[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Emergency transfer of Ether from weth gateway
    /// @param token The token to transfer
    /// @param to The recipient of the transfer
    /// @param amount The amount to send
    function emergencyTokenTransferFromGateway(address token, address to, uint256 amount) external onlyOwner {
        wEthGateway.emergencyTokenTransfer(token, to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransferFromGateway(address to, uint256 amount) external onlyOwner {
        wEthGateway.emergencyEtherTransfer(to, amount);
    }

    ////////////////// ô¿ô Internal Functions ô¿ô  //////////////////

    /// @notice Register a new address provider
    /// @param addressProvider_ The address of the address provider
    /// @param marketId_ The market id
    function _registerPool(address addressProvider_, string calldata marketId_) internal {
        uint256 providersCount = _addressesProvidersList.length;

        for (uint256 i; i < providersCount;) {
            if (_addressesProvidersList[i] == addressProvider_) {
                revert Errors.PoolRegisteredAlready();
            }
            unchecked {
                i++;
            }
        }

        _addressesProvidersList.push(addressProvider_);
        _isValidAddressProvider[addressProvider_] = true;
        _marketIdToAddressProvider[marketId_] = addressProvider_;
        emit PoolRegistered(addressProvider_, marketId_);
    }

    ////////////////// ¿ô¿ Proxy Functions ¿ô¿  //////////////////

    /// @notice Sets the interest rate strategy of a reserve
    /// @param lendingPoolAddressesProvider The address of the LP address provider
    /// @param asset The address of the underlying asset of the reserve
    /// @param rateStrategyAddress The new address of the interest strategy contract
    function setReserveInterestRateStrategyAddress(
        address lendingPoolAddressesProvider,
        address asset,
        address rateStrategyAddress
    ) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
        emit ReserveInterestRateStrategyChanged(lendingPoolAddressesProvider, asset, rateStrategyAddress);
    }

    /// @notice Permissioned function to swap oracle router in the LendingPoolAddressesProvider
    /// @param lendingPoolAddressesProvider The address of the address provider
    /// @param oracleRouter The address of the oracle router
    function setOracleRouter(address lendingPoolAddressesProvider, address oracleRouter) external onlyOwner {
        // Make sure new oracle is a contract
        if (!oracleRouter.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }
        ILendingPoolAddressesProvider(lendingPoolAddressesProvider).setPriceOracle(oracleRouter);
        emit OracleRouterSet(lendingPoolAddressesProvider, oracleRouter);
    }

    /// @notice Permissioned function to set a new receiver of the liquidationFee in the LendingPoolAddressesProvider
    /// @param lendingPoolAddressesProvider The address of the address provider
    /// @param liquidationFeeTo The address which receives the liquidation fee
    /// @dev When the `liquidationFeeTo` is the zero address the full fee goes to the liquidator
    function setLiquidationFeeTo(address lendingPoolAddressesProvider, address liquidationFeeTo) external onlyOwner {
        // Make sure addressProvider is valid
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }
        ILendingPoolAddressesProvider(lendingPoolAddressesProvider).setLiquidationFeeTo(liquidationFeeTo);
    }

    /// @notice Initialize Reserve helper function as Riz Registry is the owner of the Configurator
    /// @param input The input data for the reserve initialization
    /// @param lendingPoolAddressesProvider The address of the LP address provider
    /// @param initializingAmount The amount to deposit into the reserve
    function initReserve(
        address lendingPoolAddressesProvider,
        ILendingPoolConfigurator.InitReserveInput[] memory input,
        uint256 initializingAmount
    ) external onlyOwner {
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }
        // Make sure every asset in the input is a contract
        for (uint256 i; i < input.length;) {
            if (!input[i].underlyingAsset.isContract()) {
                revert Errors.NotAContract();
            }
            unchecked {
                i++;
            }
        }

        address lp = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPool();
        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator(configurator).batchInitReserve(input);

        // Additional step to perform an initial deposit into the reserve
        for (uint256 i; i < input.length;) {
            address reserve = input[i].underlyingAsset;
            IERC20(reserve).safeTransferFrom(msg.sender, address(this), initializingAmount);
            IERC20(reserve).approve(address(lp), initializingAmount);
            RizLendingPool(lp).deposit(address(reserve), initializingAmount, address(this), 0);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Enables borrowing on a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the asset
    /// @param stableBorrowRateEnabled True if stable borrow rate is enabled, false otherwise
    function enableBorrowingOnReserve(address lendingPoolAddressesProvider, address asset, bool stableBorrowRateEnabled)
        external
        onlyOwner
    {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.enableBorrowingOnReserve(asset, stableBorrowRateEnabled);
        emit EnabledBorrowingOnReserve(lendingPoolAddressesProvider, asset, stableBorrowRateEnabled);
    }

    /// @notice Disables borrowing on a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the asset
    function disableBorrowingOnReserve(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.disableBorrowingOnReserve(asset);
        emit BorrowingDisabledOnReserve(lendingPoolAddressesProvider, asset);
    }

    /// @notice Riz configure reserve as collateral
    /// @param asset The address of the asset
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param ltv The loan to value
    /// @param liquidationThreshold The liquidation threshold
    /// @param liquidationBonus The liquidation bonus
    function configureReserveAsCollateral(
        address asset,
        address lendingPoolAddressesProvider,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.configureReserveAsCollateral(asset, ltv, liquidationThreshold, liquidationBonus);
    }

    /// @notice Enable stable rate borrowing on a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function enableReserveStableRate(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.enableReserveStableRate(asset);
        emit StableRateEnabledOnReserve(lendingPoolAddressesProvider, asset);
    }

    /// @notice Disable stable rate borrowing on a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function disableReserveStableRate(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.disableReserveStableRate(asset);
        emit StableRateDisabledOnReserve(lendingPoolAddressesProvider, asset);
    }

    /// @notice Activates a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function activateReserve(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.activateReserve(asset);
        emit ReserveActivated(lendingPoolAddressesProvider, asset);
    }

    /// @notice Deactivates a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function deactivateReserve(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.deactivateReserve(asset);
        emit ReserveDeactivated(lendingPoolAddressesProvider, asset);
    }

    /// @notice Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap but allows
    /// repayments, liquidations, rate rebalances and withdrawals
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function freezeReserve(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.freezeReserve(asset);
        emit ReserveFrozen(lendingPoolAddressesProvider, asset);
    }

    /// @notice Unfreezes a reserve.
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    function unfreezeReserve(address lendingPoolAddressesProvider, address asset) external onlyOwner {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.unfreezeReserve(asset);
        emit ReserveUnfrozen(lendingPoolAddressesProvider, asset);
    }

    /// @notice Updates the reserve factor of a reserve
    /// @param lendingPoolAddressesProvider The address of the LendingPoolAddressesProvider
    /// @param asset The address of the underlying asset of the reserve
    /// @param reserveFactor The new reserve factor of the reserve
    function setReserveFactor(address lendingPoolAddressesProvider, address asset, uint256 reserveFactor)
        external
        onlyOwner
    {
        // Make sure asset is a contract
        if (!asset.isContract()) {
            revert Errors.NotAContract();
        }
        if (_isValidAddressProvider[lendingPoolAddressesProvider] == false) {
            revert Errors.NoAddressProvider();
        }

        address configurator = ILendingPoolAddressesProvider(lendingPoolAddressesProvider).getLendingPoolConfigurator();
        RizLendingPoolConfigurator configuratorContract = RizLendingPoolConfigurator(configurator);
        configuratorContract.setReserveFactor(asset, reserveFactor);
        emit ReserveFactorChanged(lendingPoolAddressesProvider, asset, reserveFactor);
    }

    /// @notice Updates the treasury address of a reserve
    /// @param asset The address of the asset to update
    /// @param newTreasury The new treasury address of the reserve
    function setTreasuryAddress(address asset, address newTreasury) external onlyOwner {
        // Make sure new address is valid
        if (newTreasury == address(0)) {
            revert Errors.AddressZero();
        }

        AToken(asset).setTreasuryAddress(newTreasury);
        emit TreasuryAddressUpdated(newTreasury);
    }

    function _deployCopyFromFromImpl(address implementation, string memory marketId) internal returns (address addr) {
        if (implementation == address(0)) {
            revert Errors.NotAContract();
        }
        bytes memory code = implementation.code;

        //then remove the last 128 bytes from `code`

        bytes memory bytecode = abi.encodePacked(code, marketId);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    /// @notice Overriden to check onlyOwner can upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IAToken} from "../interfaces/IAToken.sol";
import {ReserveConfiguration} from "./libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "./libraries/configuration/UserConfiguration.sol";
import {Helpers} from "./libraries/helpers/Helpers.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";

contract WETHGateway is IWETHGateway, Ownable {
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using UserConfiguration for DataTypes.UserConfigurationMap;

	IWETH internal immutable WETH;

	/**
	 * @dev Sets the WETH address and the LendingPoolAddressesProvider address. Infinite approves lending pool.
	 * @param weth Address of the Wrapped Ether contract
	 **/
	constructor(address weth) {
		WETH = IWETH(weth);
	}

	function authorizeLendingPool(address lendingPool) external onlyOwner {
		WETH.approve(lendingPool, type(uint256).max);
	}

	/**
	 * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
	 * is minted.
	 * @param lendingPool address of the targeted underlying lending pool
	 * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
	 * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
	 **/
	function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable {
		WETH.deposit{value: msg.value}();
		ILendingPool(lendingPool).deposit(address(WETH), msg.value, onBehalfOf, referralCode);
	}

	function depositETHWithAutoDLP(address lendingPool, address onBehalfOf, uint16 referralCode) external payable {
		WETH.deposit{value: msg.value}();
		ILendingPool(lendingPool).depositWithAutoDLP(address(WETH), msg.value, onBehalfOf, referralCode);
	}

	/**
	 * @dev withdraws the WETH _reserves of msg.sender.
	 * @param lendingPool address of the targeted underlying lending pool
	 * @param amount amount of aWETH to withdraw and receive native ETH
	 * @param to address of the user who will receive native ETH
	 */
	function withdrawETH(address lendingPool, uint256 amount, address to) external {
		IAToken aWETH = IAToken(ILendingPool(lendingPool).getReserveData(address(WETH)).aTokenAddress);
		uint256 userBalance = aWETH.balanceOf(msg.sender);
		uint256 amountToWithdraw = amount;

		// if amount is equal to uint256(-1), the user wants to redeem everything
		if (amount == type(uint256).max) {
			amountToWithdraw = userBalance;
		}
		aWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
		ILendingPool(lendingPool).withdraw(address(WETH), amountToWithdraw, address(this));
		WETH.withdraw(amountToWithdraw);
		_safeTransferETH(to, amountToWithdraw);
	}

	/**
	 * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
	 * @param lendingPool address of the targeted underlying lending pool
	 * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
	 * @param rateMode the rate mode to repay
	 * @param onBehalfOf the address for which msg.sender is repaying
	 */
	function repayETH(address lendingPool, uint256 amount, uint256 rateMode, address onBehalfOf) external payable {
		(uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebtMemory(
			onBehalfOf,
			ILendingPool(lendingPool).getReserveData(address(WETH))
		);

		uint256 paybackAmount = DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.STABLE
			? stableDebt
			: variableDebt;

		if (amount < paybackAmount) {
			paybackAmount = amount;
		}
		require(msg.value >= paybackAmount, "msg.value is less than repayment amount");
		WETH.deposit{value: paybackAmount}();
		ILendingPool(lendingPool).repay(address(WETH), paybackAmount, rateMode, onBehalfOf);

		// refund remaining dust eth
		if (msg.value > paybackAmount) _safeTransferETH(msg.sender, msg.value - paybackAmount);
	}

	/**
	 * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `LendingPool.borrow`.
	 * @param lendingPool address of the targeted underlying lending pool
	 * @param amount the amount of ETH to borrow
	 * @param interesRateMode the interest rate mode
	 * @param referralCode integrators are assigned a referral code and can potentially receive rewards
	 */
	function borrowETH(address lendingPool, uint256 amount, uint256 interesRateMode, uint16 referralCode) external {
		ILendingPool(lendingPool).borrow(address(WETH), amount, interesRateMode, referralCode, msg.sender);
		WETH.withdraw(amount);
		_safeTransferETH(msg.sender, amount);
	}

	/**
	 * @dev transfer ETH to an address, revert if it fails.
	 * @param to recipient of the transfer
	 * @param value the amount to send
	 */
	function _safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "ETH_TRANSFER_FAILED");
	}

	/**
	 * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
	 * direct transfers to the contract address.
	 * @param token token to transfer
	 * @param to recipient of the transfer
	 * @param amount amount to send
	 */
	function emergencyTokenTransfer(address token, address to, uint256 amount) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	/**
	 * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
	 * due selfdestructs or transfer ether to pre-computated contract address before deployment.
	 * @param to recipient of the transfer
	 * @param amount amount to send
	 */
	function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
		_safeTransferETH(to, amount);
	}

	/**
	 * @dev Get WETH address used by WETHGateway
	 */
	function getWETHAddress() external view returns (address) {
		return address(WETH);
	}

	/**
	 * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
	 */
	receive() external payable {
		require(msg.sender == address(WETH), "Receive not allowed");
	}

	/**
	 * @dev Revert fallback calls
	 */
	fallback() external payable {
		revert("Fallback not allowed");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    // Common errors
    error AddressZero();
    error AmountZero();
    error NotAContract();
    error NotAuthorized();

    // Oracle specific errors
    error NoFeedSet();
    error NoFallbackFeedSet();
    error NoPriceAvailable();
    error PoolDisabled();
    error PoolNotDisabled();
    // Oracle specific errors
    error RoundNotComplete();

    // Oracles General errors
    error InvalidOracleProviderType();
    error InvalidFeed();

    // Riz Registry errors
    error PoolRegisteredAlready();
    error NoAddressProvider();
    error NotLPConfigurator();

    // Riz LockZap errors
    error CannotRizZap();
    error InvalidLendingPool();
    error InvalidRatio();
    error InvalidLockLength();
    error SlippageTooHigh();
    error SpecifiedSlippageExceedLimit();
    error InvalidZapETHSource();
    error ReceivedETHOnAlternativeAssetZap();
    error InsufficientETH();
    error EthTransferFailed();
    error SwapFailed(address asset, uint256 amount);
    error WrongRoute(address fromToken, address toToken);

    // Riz Leverager errors
    error ReceiveNotAllowed();
    error FallbackNotAllowed();

    /// @notice Disallow a loop count of 0
    error InvalidLoopCount();

    /// @notice Thrown when deployer sets the margin too high
    error MarginTooHigh();

    // Revenue Management errors
    error OutputTokenConfigLengthMismatch();
    error InputTokenConfigLengthMismatch();
    error IndexOutOfBounds();
    error OutputTokenBalanceOutOfRange();
    error TokenAlreadyAdded();
    error TokenNotPresent();
    error PercentageMismatch();
    error InvalidSwapStrategy();
    error DexSwapFailed();
    error ReceivedLessThanMinOutput();
    error InvalidInputData();
    error AddressNotApproved();

    // Bad Debt Manager errors
    error OnlyLendingPool();
    error UserAlreadyWithdrawn();
    error BadDebtIsZero();
    error UserAllowanceZero();
    error NotEmergencyAdmin();
    error InvalidAssetsLength();
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { VersionedInitializable } from
    "@radiant-v2-core/lending/libraries/aave-upgradeability/VersionedInitializable.sol";
import { InitializableImmutableAdminUpgradeabilityProxy } from
    "@radiant-v2-core/lending/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import { ReserveConfiguration } from "@radiant-v2-core/lending/libraries/configuration/ReserveConfiguration.sol";
import { ILendingPoolAddressesProvider } from "@radiant-v2-core/interfaces/ILendingPoolAddressesProvider.sol";
import { ILendingPool } from "@radiant-v2-core/interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Errors } from "@radiant-v2-core/lending/libraries/helpers/Errors.sol";
import { Errors as RizErrors } from "../libraries/Errors.sol";
import { PercentageMath } from "@radiant-v2-core/lending/libraries/math/PercentageMath.sol";
import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";
import { IInitializableDebtToken } from "@radiant-v2-core/interfaces/IInitializableDebtToken.sol";
import { IInitializableAToken } from "@radiant-v2-core/interfaces/IInitializableAToken.sol";
import { IAaveIncentivesController } from "@radiant-v2-core/interfaces/IAaveIncentivesController.sol";
import { ILendingPoolConfigurator } from "@radiant-v2-core/interfaces/ILendingPoolConfigurator.sol";
import { RizRegistry } from "../RizRegistry.sol";
import { IRizLendingPool } from "../interfaces/Riz/IRizLendingPool.sol";
import { IRizLendingPoolAddressesProvider } from "../interfaces/Riz/IRizLendingPoolAddressesProvider.sol";

/**
 * @title LendingPoolConfigurator contract
 * @author Aave
 * @dev Implements the configuration methods for the Aave protocol
 *
 */
contract RizLendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigurator {
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 public constant BIPS_DIVISOR = 10_000;

    ILendingPoolAddressesProvider internal addressesProvider;
    ILendingPool internal pool;

    modifier onlyPoolAdmin() {
        require(addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
        _;
    }

    modifier onlyEmergencyAdmin() {
        require(addressesProvider.getEmergencyAdmin() == msg.sender, Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN);
        _;
    }

    uint256 internal constant CONFIGURATOR_REVISION = 0x1;

    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(ILendingPoolAddressesProvider provider) public initializer {
        addressesProvider = provider;
        pool = ILendingPool(addressesProvider.getLendingPool());
    }

    /**
     * @dev Initializes reserves in batch
     *
     */
    function batchInitReserve(InitReserveInput[] calldata input) external onlyPoolAdmin {
        ILendingPool cachedPool = pool;
        uint256 length = input.length;
        for (uint256 i = 0; i < length;) {
            _initReserve(cachedPool, input[i]);
            unchecked {
                i++;
            }
        }
    }

    function _initReserve(ILendingPool _pool, InitReserveInput calldata input) internal {
        address aTokenProxyAddress = _initTokenWithProxy(
            input.aTokenImpl,
            abi.encodeCall(
                IInitializableAToken.initialize,
                (
                    _pool,
                    input.treasury,
                    input.underlyingAsset,
                    IAaveIncentivesController(input.incentivesController),
                    input.underlyingAssetDecimals,
                    input.aTokenName,
                    input.aTokenSymbol,
                    input.params
                )
            )
        );
        address stableDebtTokenProxyAddress = _initTokenWithProxy(
            input.stableDebtTokenImpl,
            abi.encodeCall(
                IInitializableDebtToken.initialize,
                (
                    _pool,
                    input.underlyingAsset,
                    IAaveIncentivesController(input.incentivesController),
                    input.underlyingAssetDecimals,
                    input.stableDebtTokenName,
                    input.stableDebtTokenSymbol,
                    input.params
                )
            )
        );
        // stableDebt is not added to incentives controller
        // GEIST does not support stable lending

        address variableDebtTokenProxyAddress = _initTokenWithProxy(
            input.variableDebtTokenImpl,
            abi.encodeCall(
                IInitializableDebtToken.initialize,
                (
                    _pool,
                    input.underlyingAsset,
                    IAaveIncentivesController(input.incentivesController),
                    input.underlyingAssetDecimals,
                    input.variableDebtTokenName,
                    input.variableDebtTokenSymbol,
                    input.params
                )
            )
        );

        _pool.initReserve(
            input.underlyingAsset,
            aTokenProxyAddress,
            stableDebtTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(input.underlyingAsset);

        currentConfig.setDecimals(input.underlyingAssetDecimals);

        currentConfig.setActive(true);
        currentConfig.setFrozen(false);

        pool.setConfiguration(input.underlyingAsset, currentConfig.data);

        emit ReserveInitialized(
            input.underlyingAsset,
            aTokenProxyAddress,
            stableDebtTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress
        );
    }

    /**
     * @dev Updates the aToken implementation for the reserve
     *
     */
    function updateAToken(UpdateATokenInput calldata input) external onlyPoolAdmin {
        ILendingPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        (,,, uint256 decimals,) = cachedPool.getConfiguration(input.asset).getParamsMemory();

        bytes memory encodedCall = abi.encodeCall(
            IInitializableAToken.initialize,
            (
                cachedPool,
                input.treasury,
                input.asset,
                IAaveIncentivesController(input.incentivesController),
                uint8(decimals),
                input.name,
                input.symbol,
                input.params
            )
        );

        _upgradeTokenImplementation(reserveData.aTokenAddress, input.implementation, encodedCall);

        emit ATokenUpgraded(input.asset, reserveData.aTokenAddress, input.implementation);
    }

    /**
     * @dev Updates the stable debt token implementation for the reserve
     *
     */
    function updateStableDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
        ILendingPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        (,,, uint256 decimals,) = cachedPool.getConfiguration(input.asset).getParamsMemory();

        bytes memory encodedCall = abi.encodeCall(
            IInitializableDebtToken.initialize,
            (
                cachedPool,
                input.asset,
                IAaveIncentivesController(input.incentivesController),
                uint8(decimals),
                input.name,
                input.symbol,
                input.params
            )
        );

        _upgradeTokenImplementation(reserveData.stableDebtTokenAddress, input.implementation, encodedCall);

        emit StableDebtTokenUpgraded(input.asset, reserveData.stableDebtTokenAddress, input.implementation);
    }

    /**
     * @dev Updates the variable debt token implementation for the asset
     *
     */
    function updateVariableDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
        ILendingPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        (,,, uint256 decimals,) = cachedPool.getConfiguration(input.asset).getParamsMemory();

        bytes memory encodedCall = abi.encodeCall(
            IInitializableDebtToken.initialize,
            (
                cachedPool,
                input.asset,
                IAaveIncentivesController(input.incentivesController),
                uint8(decimals),
                input.name,
                input.symbol,
                input.params
            )
        );

        _upgradeTokenImplementation(reserveData.variableDebtTokenAddress, input.implementation, encodedCall);

        emit VariableDebtTokenUpgraded(input.asset, reserveData.variableDebtTokenAddress, input.implementation);
    }

    /**
     * @dev Enables borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
     *
     */
    function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setBorrowingEnabled(true);
        currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

        pool.setConfiguration(asset, currentConfig.data);

        emit BorrowingEnabledOnReserve(asset, stableBorrowRateEnabled);
    }

    /**
     * @dev Disables borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function disableBorrowingOnReserve(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setBorrowingEnabled(false);

        pool.setConfiguration(asset, currentConfig.data);
        emit BorrowingDisabledOnReserve(asset);
    }

    /**
     * @dev Configures the reserve collateralization parameters
     * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means
     * 100.00%
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered
     * undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always above 100%. A
     * value of 105%
     * means the liquidator will receive a 5% bonus
     *
     */
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        //validation of the parameters: the LTV can
        //only be lower or equal than the liquidation threshold
        //(otherwise a loan against the asset would cause instantaneous liquidation)
        require(ltv <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            require(liquidationBonus > PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            require(
                liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
                Errors.LPC_INVALID_CONFIGURATION
            );
        } else {
            require(liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
            //if the liquidation threshold is being set to 0,
            // the reserve is being disabled as collateral. To do so,
            //we need to ensure no liquidity is deposited
            _checkNoLiquidity(asset);
        }

        currentConfig.setLtv(ltv);
        currentConfig.setLiquidationThreshold(liquidationThreshold);
        currentConfig.setLiquidationBonus(liquidationBonus);

        pool.setConfiguration(asset, currentConfig.data);

        emit CollateralConfigurationChanged(asset, ltv, liquidationThreshold, liquidationBonus);
    }

    /**
     * @dev Enable stable rate borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function enableReserveStableRate(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setStableRateBorrowingEnabled(true);

        pool.setConfiguration(asset, currentConfig.data);

        emit StableRateEnabledOnReserve(asset);
    }

    /**
     * @dev Disable stable rate borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function disableReserveStableRate(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setStableRateBorrowingEnabled(false);

        pool.setConfiguration(asset, currentConfig.data);

        emit StableRateDisabledOnReserve(asset);
    }

    /**
     * @dev Activates a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function activateReserve(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setActive(true);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveActivated(asset);
    }

    /**
     * @dev Deactivates a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function deactivateReserve(address asset) external onlyPoolAdmin {
        _checkNoLiquidity(asset);

        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setActive(false);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveDeactivated(asset);
    }

    /**
     * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
     *  but allows repayments, liquidations, rate rebalances and withdrawals
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function freezeReserve(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setFrozen(true);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveFrozen(asset);
    }

    /**
     * @dev Unfreezes a reserve
     * @param asset The address of the underlying asset of the reserve
     *
     */
    function unfreezeReserve(address asset) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setFrozen(false);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveUnfrozen(asset);
    }

    /**
     * @notice Updates the borrow cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newBorrowCap The new borrow cap of the reserve
     * @custom:borrow-and-supply-caps
     */
    function setBorrowCap(address asset, uint256 newBorrowCap) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);
        uint256 oldBorrowCap = currentConfig.getBorrowCap();
        currentConfig.setBorrowCap(newBorrowCap);
        pool.setConfiguration(asset, currentConfig.data);
        emit BorrowCapChanged(asset, oldBorrowCap, newBorrowCap);
    }

    /**
     * @notice Updates the supply cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newSupplyCap The new supply cap of the reserve
     * @custom:borrow-and-supply-caps
     */
    function setSupplyCap(address asset, uint256 newSupplyCap) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);
        uint256 oldSupplyCap = currentConfig.getSupplyCap();
        currentConfig.setSupplyCap(newSupplyCap);
        pool.setConfiguration(asset, currentConfig.data);
        emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
    }

    /**
     * @dev Updates the reserve factor of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param reserveFactor The new reserve factor of the reserve
     *
     */
    function setReserveFactor(address asset, uint256 reserveFactor) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setReserveFactor(reserveFactor);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveFactorChanged(asset, reserveFactor);
    }

    /**
     * @dev Sets the interest rate strategy of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The new address of the interest strategy contract
     *
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external onlyPoolAdmin {
        pool.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
        emit ReserveInterestRateStrategyChanged(asset, rateStrategyAddress);
    }

    /**
     * @dev pauses or unpauses all the actions of the protocol, including aToken transfers
     * @param val true if protocol needs to be paused, false otherwise
     *
     */
    function setPoolPause(bool val) external onlyEmergencyAdmin {
        pool.setPause(val);
    }

    /// @dev Shuts down the pool
    /// @param badDebt The amount of bad debt to be set
    function poolShutdown(uint256 badDebt) external onlyEmergencyAdmin {
        IRizLendingPool(address(pool)).shutdown(badDebt);
        address rizRegistryAddress = IRizLendingPoolAddressesProvider(address(addressesProvider)).getRizRegistry();
        RizRegistry rizRegistry = RizRegistry(rizRegistryAddress);
        rizRegistry.updateLendingPoolStatus(address(addressesProvider), false);
    }

    function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
        InitializableImmutableAdminUpgradeabilityProxy proxy =
            new InitializableImmutableAdminUpgradeabilityProxy(address(this));

        proxy.initialize(implementation, initParams);

        return address(proxy);
    }

    function _upgradeTokenImplementation(address proxyAddress, address implementation, bytes memory initParams)
        internal
    {
        InitializableImmutableAdminUpgradeabilityProxy proxy =
            InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));

        proxy.upgradeToAndCall(implementation, initParams);
    }

    function _checkNoLiquidity(address asset) internal view {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

        uint256 availableLiquidity = IERC20Metadata(asset).balanceOf(reserveData.aTokenAddress);

        require(availableLiquidity == 0 && reserveData.currentLiquidityRate == 0, Errors.LPC_RESERVE_LIQUIDITY_NOT_0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ILendingPoolAddressesProvider } from "@radiant-v2-core/interfaces/ILendingPoolAddressesProvider.sol";
import {
    RizLendingPoolAddressesProvider, IRizLendingPoolAddressesProvider
} from "./RizLendingPoolAddressesProvider.sol";
import { ILendingPoolCollateralManager } from "@radiant-v2-core/interfaces/ILendingPoolCollateralManager.sol";
import { IAToken } from "@radiant-v2-core/interfaces/IAToken.sol";
import { RizAToken } from "../tokenization/RizAToken.sol";
import { IVariableDebtToken } from "@radiant-v2-core/interfaces/IVariableDebtToken.sol";
import { IPriceOracleGetter } from "@radiant-v2-core/interfaces/IPriceOracleGetter.sol";
import { IStableDebtToken } from "@radiant-v2-core/interfaces/IStableDebtToken.sol";
import { ILendingPool } from "@radiant-v2-core/interfaces/ILendingPool.sol";
import { ILeverager } from "@radiant-v2-core/interfaces/ILeverager.sol";
import { VersionedInitializable } from
    "@radiant-v2-core/lending/libraries/aave-upgradeability/VersionedInitializable.sol";
import { Helpers } from "@radiant-v2-core/lending/libraries/helpers/Helpers.sol";
import { Errors } from "@radiant-v2-core/lending/libraries/helpers/Errors.sol";
import { Errors as RizErrors } from "../libraries/Errors.sol";
import { WadRayMath } from "@radiant-v2-core/lending/libraries/math/WadRayMath.sol";
import { PercentageMath } from "@radiant-v2-core/lending/libraries/math/PercentageMath.sol";
import { ReserveLogic } from "@radiant-v2-core/lending/libraries/logic/ReserveLogic.sol";
import { GenericLogic } from "@radiant-v2-core/lending/libraries/logic/GenericLogic.sol";
import { ValidationLogic } from "@radiant-v2-core/lending/libraries/logic/ValidationLogic.sol";
import { ReserveConfiguration } from "@radiant-v2-core/lending/libraries/configuration/ReserveConfiguration.sol";
import { UserConfiguration } from "@radiant-v2-core/lending/libraries/configuration/UserConfiguration.sol";
import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";
import { RizLendingPoolStorage } from "./RizLendingPoolStorage.sol";
import { IRizLendingPool } from "../interfaces/Riz/IRizLendingPool.sol";
import { BadDebtManager } from "../BadDebtManager.sol";
import { OracleRouter } from "../OracleRouter.sol";
import { EmergencyWithdraw } from "../libraries/EmergencyWithdraw.sol";

/**
 * @title LendingPool contract
 * @dev Main point of interaction with an Aave protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Swap their loans between variable and stable rate
 *   # Enable/disable their deposits as collateral rebalance stable rate borrow positions
 *   # Liquidate positions
 * - To be covered by a proxy contract, owned by the LendingPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendingPoolConfigurator contract defined also in the
 *   RizLendingPoolAddressesProvider
 * @author Aave
 *
 */
contract RizLendingPool is VersionedInitializable, IRizLendingPool, RizLendingPoolStorage {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using EmergencyWithdraw for EmergencyWithdraw.Params;

    uint256 public constant LENDINGPOOL_REVISION = 0x1;
    uint256 public constant BIPS_DIVISOR = 10_000;

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier whenNotPausedOrShutdown() {
        _whenNotPaused();
        _whenNotShutdown();
        _;
    }

    modifier onlyLendingPoolConfigurator() {
        _onlyLendingPoolConfigurator();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, Errors.LP_IS_PAUSED);
    }

    function _whenNotShutdown() internal view {
        if (_shutdown) {
            revert RizErrors.PoolDisabled();
        }
    }

    function _onlyLendingPoolConfigurator() internal view {
        require(
            _addressesProvider.getLendingPoolConfigurator() == msg.sender,
            Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR
        );
    }

    function getRevision() internal pure override returns (uint256) {
        return LENDINGPOOL_REVISION;
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Function is invoked by the proxy contract when the LendingPool contract is added to the
     * RizLendingPoolAddressesProvider of the market.
     * - Caching the address of the LendingPoolAddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the RizLendingPoolAddressesProvider
     *
     */
    function initialize(IRizLendingPoolAddressesProvider provider) public override initializer {
        _addressesProvider = provider;
        _maxStableRateBorrowSizePercent = 2500;
        _maxNumberOfReserves = 4;
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        public
        virtual
        whenNotPausedOrShutdown
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        ValidationLogic.validateDeposit(reserve, amount);

        address aToken = reserve.aTokenAddress;

        reserve.updateState();
        reserve.updateInterestRates(asset, aToken, amount, 0);

        IERC20(asset).safeTransferFrom(msg.sender, aToken, amount);

        if (IAToken(aToken).balanceOf(onBehalfOf) == 0) {
            _usersConfig[onBehalfOf].setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, onBehalfOf);
        }

        /// @custom:borrow-and-supply-caps
        ValidationLogic.validateSupplyCap(reserve, amount);

        IAToken(aToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @notice Emergency withdrawal logic in case pool is bricked. This flow is different from the normal withdraw,
     * as when pool is bricked, users can no longer choose which assets they are going to withdraw. Instead, we are
     * going
     * to distribute the assets in the pool to the users in a "fair" way, by slashing withdrawal amount
     * Also, it is important to note, that each user will get a proportion of assets based on their ratio in the pool
     * The formula to calculate the amount to be withdrawn is:
     * amountToWithdraw = (userDeposit - userDebt)
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     *
     */
    function withdraw(address asset, uint256 amount, address to) external virtual whenNotPaused returns (uint256) {
        // If pool is bricked, we have to perform the emergency withdrawal. User doesn't decide the amount to withdraw
        // and the assets to withdraw
        if (_shutdown) {
            _emergencyWithdraw(msg.sender, to);
            return 0;
        }
        DataTypes.ReserveData storage reserve = _reserves[asset];

        address aToken = reserve.aTokenAddress;

        uint256 userBalance = IAToken(aToken).balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        ValidationLogic.validateWithdraw(
            asset,
            amountToWithdraw,
            userBalance,
            _reserves,
            _usersConfig[msg.sender],
            _reservesList,
            _reservesCount,
            _addressesProvider.getPriceOracle()
        );

        reserve.updateState();

        reserve.updateInterestRates(asset, aToken, 0, amountToWithdraw);

        if (amountToWithdraw == userBalance) {
            _usersConfig[msg.sender].setUsingAsCollateral(reserve.id, false);
            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }

        IAToken(aToken).burn(msg.sender, to, amountToWithdraw, reserve.liquidityIndex);

        emit Withdraw(asset, msg.sender, to, amountToWithdraw);

        return amountToWithdraw;
    }

    /// @dev Emergency withdrawal
    function _emergencyWithdraw(address owner, address to) internal {
        address[] memory reservesList = new address[](_reservesCount);

        for (uint256 i = 0; i < _reservesCount; i++) {
            reservesList[i] = _reservesList[i];
        }

        EmergencyWithdraw.Params memory params = EmergencyWithdraw.Params({
            totalUserDepositsUSD: 0,
            totalUserDebtsUSD: 0,
            reservesList: reservesList,
            reservesCount: _reservesCount,
            badDebtManagerAddress: _addressesProvider.getBadDebtManager()
        });

        EmergencyWithdraw.emergencyWithdraw(owner, to, params, _reserves);
    }

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     *
     */
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external
        virtual
        whenNotPausedOrShutdown
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        _executeBorrow(
            ExecuteBorrowParams(
                asset, msg.sender, onBehalfOf, amount, interestRateMode, reserve.aTokenAddress, referralCode, true
            )
        );
    }

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     *
     */
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf)
        external
        virtual
        whenNotPausedOrShutdown
        returns (uint256)
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(onBehalfOf, reserve);

        DataTypes.InterestRateMode interestRateMode = DataTypes.InterestRateMode(rateMode);

        ValidationLogic.validateRepay(reserve, amount, interestRateMode, onBehalfOf, stableDebt, variableDebt);

        uint256 paybackAmount = interestRateMode == DataTypes.InterestRateMode.STABLE ? stableDebt : variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }

        reserve.updateState();

        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            IStableDebtToken(reserve.stableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
        } else {
            IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
                onBehalfOf, paybackAmount, reserve.variableBorrowIndex
            );
        }

        address aToken = reserve.aTokenAddress;
        reserve.updateInterestRates(asset, aToken, paybackAmount, 0);

        if (stableDebt.add(variableDebt).sub(paybackAmount) == 0) {
            _usersConfig[onBehalfOf].setBorrowing(reserve.id, false);
        }

        IERC20(asset).safeTransferFrom(msg.sender, aToken, paybackAmount);

        IAToken(aToken).handleRepayment(msg.sender, paybackAmount);

        emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);

        return paybackAmount;
    }

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     *
     */
    function swapBorrowRateMode(address asset, uint256 rateMode) external virtual whenNotPausedOrShutdown {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(msg.sender, reserve);

        DataTypes.InterestRateMode interestRateMode = DataTypes.InterestRateMode(rateMode);

        ValidationLogic.validateSwapRateMode(
            reserve, _usersConfig[msg.sender], stableDebt, variableDebt, interestRateMode
        );

        reserve.updateState();

        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            IStableDebtToken(reserve.stableDebtTokenAddress).burn(msg.sender, stableDebt);
            IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
                msg.sender, msg.sender, stableDebt, reserve.variableBorrowIndex
            );
        } else {
            IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
                msg.sender, variableDebt, reserve.variableBorrowIndex
            );
            IStableDebtToken(reserve.stableDebtTokenAddress).mint(
                msg.sender, msg.sender, variableDebt, reserve.currentStableBorrowRate
            );
        }

        reserve.updateInterestRates(asset, reserve.aTokenAddress, 0, 0);

        emit Swap(asset, msg.sender, rateMode);
    }

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much
     * has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     *
     */
    function rebalanceStableBorrowRate(address asset, address user) external virtual whenNotPausedOrShutdown {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        IERC20 stableDebtToken = IERC20(reserve.stableDebtTokenAddress);
        IERC20 variableDebtToken = IERC20(reserve.variableDebtTokenAddress);
        address aTokenAddress = reserve.aTokenAddress;

        uint256 stableDebt = IERC20(stableDebtToken).balanceOf(user);

        ValidationLogic.validateRebalanceStableBorrowRate(
            reserve, asset, stableDebtToken, variableDebtToken, aTokenAddress
        );

        reserve.updateState();

        IStableDebtToken(address(stableDebtToken)).burn(user, stableDebt);
        IStableDebtToken(address(stableDebtToken)).mint(user, user, stableDebt, reserve.currentStableBorrowRate);

        reserve.updateInterestRates(asset, aTokenAddress, 0, 0);

        emit RebalanceStableBorrowRate(asset, user);
    }

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     *
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external
        virtual
        whenNotPausedOrShutdown
    {
        DataTypes.ReserveData storage reserve = _reserves[asset];

        ValidationLogic.validateSetUseReserveAsCollateral(
            reserve,
            asset,
            useAsCollateral,
            _reserves,
            _usersConfig[msg.sender],
            _reservesList,
            _reservesCount,
            _addressesProvider.getPriceOracle()
        );

        _usersConfig[msg.sender].setUsingAsCollateral(reserve.id, useAsCollateral);

        if (useAsCollateral) {
            emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
        } else {
            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }
    }

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the
     * liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     *
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external virtual whenNotPausedOrShutdown {
        address collateralManager = _addressesProvider.getLendingPoolCollateralManager();
        address liquidationFeeTo = _addressesProvider.getLiquidationFeeTo();
        if (liquidationFeeTo == address(0)) {
            liquidationFeeTo = msg.sender;
        }

        //solium-disable-next-line
        (bool success, bytes memory result) = collateralManager.delegatecall(
            abi.encodeCall(
                ILendingPoolCollateralManager.liquidationCall,
                (collateralAsset, debtAsset, user, debtToCover, receiveAToken, liquidationFeeTo)
            )
        );

        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);

        (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

        require(returnCode == 0, string(abi.encodePacked(returnMessage)));
    }

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     *
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateral the total collateral in USD to 8 decimals of the user
     * @return totalDebt the total debt in USD to 8 decimals of the user
     * @return availableBorrows the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     *
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        (totalCollateral, totalDebt, ltv, currentLiquidationThreshold, healthFactor) = GenericLogic
            .calculateUserAccountData(
            user, _reserves, _usersConfig[user], _reservesList, _reservesCount, _addressesProvider.getPriceOracle()
        );

        // The GenericLogic library retains the method name `calculateAvailableBorrowsETH` for
        // historical reasons but returns the amount in usd to 8 decimals
        availableBorrows = GenericLogic.calculateAvailableBorrowsETH(totalCollateral, totalDebt, ltv);
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     *
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
        return _reserves[asset].configuration;
    }

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     *
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory) {
        return _usersConfig[user];
    }

    /**
     * @dev Returns the normalized income per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view virtual returns (uint256) {
        return _reserves[asset].getNormalizedIncome();
    }

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256) {
        return _reserves[asset].getNormalizedDebt();
    }

    /**
     * @dev Returns if the LendingPool is paused
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /// @notice Returns the shutdown state of the pool
    function isShutdown() external view returns (bool) {
        return _shutdown;
    }

    /**
     * @dev Returns the list of the initialized reserves
     *
     */
    function getReservesList() external view returns (address[] memory) {
        address[] memory _activeReserves = new address[](_reservesCount);

        for (uint256 i = 0; i < _reservesCount;) {
            _activeReserves[i] = _reservesList[i];
            unchecked {
                i++;
            }
        }
        return _activeReserves;
    }

    /**
     * @dev Returns the cached LendingPoolAddressesProvider connected to this contract
     *
     */
    function getAddressesProvider() external view returns (IRizLendingPoolAddressesProvider) {
        return _addressesProvider;
    }

    /**
     * @dev Returns the percentage of available liquidity that can be borrowed at once at stable rate
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() public view returns (uint256) {
        return _maxStableRateBorrowSizePercent;
    }

    /**
     * @dev Returns the maximum number of reserves supported to be listed in this LendingPool
     */
    function MAX_NUMBER_RESERVES() public view returns (uint256) {
        return _maxNumberOfReserves;
    }

    /**
     * @dev Validates and finalizes an aToken transfer
     * - Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external whenNotPausedOrShutdown {
        require(msg.sender == _reserves[asset].aTokenAddress, Errors.LP_CALLER_MUST_BE_AN_ATOKEN);

        ValidationLogic.validateTransfer(
            from, _reserves, _usersConfig[from], _reservesList, _reservesCount, _addressesProvider.getPriceOracle()
        );

        uint256 reserveId = _reserves[asset].id;

        if (from != to) {
            if (balanceFromBefore.sub(amount) == 0) {
                DataTypes.UserConfigurationMap storage fromConfig = _usersConfig[from];
                fromConfig.setUsingAsCollateral(reserveId, false);
                emit ReserveUsedAsCollateralDisabled(asset, from);
            }

            if (balanceToBefore == 0 && amount != 0) {
                DataTypes.UserConfigurationMap storage toConfig = _usersConfig[to];
                toConfig.setUsingAsCollateral(reserveId, true);
                emit ReserveUsedAsCollateralEnabled(asset, to);
            }
        }
    }

    /**
     * @dev Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * - Only callable by the LendingPoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param aTokenAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     *
     */
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external onlyLendingPoolConfigurator {
        require(Address.isContract(asset), Errors.LP_NOT_CONTRACT);
        _reserves[asset].init(aTokenAddress, stableDebtAddress, variableDebtAddress, interestRateStrategyAddress);
        _addReserveToList(asset);
    }

    /**
     * @dev Updates the address of the interest rate strategy contract
     * - Only callable by the LendingPoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     *
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
        external
        onlyLendingPoolConfigurator
    {
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /**
     * @dev Sets the configuration bitmap of the reserve as a whole
     * - Only callable by the LendingPoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     *
     */
    function setConfiguration(address asset, uint256 configuration) external onlyLendingPoolConfigurator {
        _reserves[asset].configuration.data = configuration;
    }

    /**
     * @dev Set the _pause state of a reserve
     * - Only callable by the LendingPoolConfigurator contract
     * @param val `true` to pause the reserve, `false` to un-pause it
     */
    function setPause(bool val) external onlyLendingPoolConfigurator {
        _paused = val;
        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    /// @notice Shuts down the lending pool
    /// @notice Warning: this operation is irreversible, and the lending pool will not be able to operate anymore except
    /// for withdrawal
    /// @param badDebt The amount of bad debt to be recorded
    function shutdown(uint256 badDebt) external onlyLendingPoolConfigurator {
        if (_shutdown) {
            return;
        }
        _shutdown = true;
        // Get bad debt manager
        address badDebtManager = IRizLendingPoolAddressesProvider(_addressesProvider).getBadDebtManager();
        BadDebtManager(badDebtManager).snapshot(badDebt);
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        uint256 interestRateMode;
        address aTokenAddress;
        uint16 referralCode;
        bool releaseUnderlying;
    }

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {
        DataTypes.ReserveData storage reserve = _reserves[vars.asset];
        DataTypes.UserConfigurationMap storage userConfig = _usersConfig[vars.onBehalfOf];

        address oracle = _addressesProvider.getPriceOracle();

        uint256 amountInETH = IPriceOracleGetter(oracle).getAssetPrice(vars.asset).mul(vars.amount).div(
            10 ** reserve.configuration.getDecimals()
        );

        ValidationLogic.validateBorrow(
            vars.asset,
            reserve,
            vars.onBehalfOf,
            vars.amount,
            amountInETH,
            vars.interestRateMode,
            _maxStableRateBorrowSizePercent,
            _reserves,
            userConfig,
            _reservesList,
            _reservesCount,
            oracle
        );

        reserve.updateState();
        /// @custom:borrow-and-supply-caps
        ValidationLogic.validateBorrowCap(reserve, vars.amount);
        uint256 currentStableRate = 0;

        bool isFirstBorrowing = false;
        if (DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE) {
            currentStableRate = reserve.currentStableBorrowRate;

            isFirstBorrowing = IStableDebtToken(reserve.stableDebtTokenAddress).mint(
                vars.user, vars.onBehalfOf, vars.amount, currentStableRate
            );
        } else {
            isFirstBorrowing = IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
                vars.user, vars.onBehalfOf, vars.amount, reserve.variableBorrowIndex
            );
        }

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(vars.asset, vars.aTokenAddress, 0, vars.releaseUnderlying ? vars.amount : 0);

        if (vars.releaseUnderlying) {
            IAToken(vars.aTokenAddress).transferUnderlyingTo(vars.user, vars.amount);
        }

        emit Borrow(
            vars.asset,
            vars.user,
            vars.onBehalfOf,
            vars.amount,
            vars.interestRateMode,
            DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE
                ? currentStableRate
                : reserve.currentVariableBorrowRate,
            vars.referralCode
        );
    }

    function _addReserveToList(address asset) internal {
        uint256 reservesCount = _reservesCount;

        require(reservesCount < _maxNumberOfReserves, Errors.LP_NO_MORE_RESERVES_ALLOWED);

        bool reserveAlreadyAdded = _reserves[asset].id != 0 || _reservesList[0] == asset;

        if (!reserveAlreadyAdded) {
            _reserves[asset].id = uint8(reservesCount);
            _reservesList[reservesCount] = asset;

            _reservesCount = reservesCount + 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { InitializableImmutableAdminUpgradeabilityProxy } from
    "@radiant-v2-core/lending/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import { ILendingPool } from "@radiant-v2-core/interfaces/ILendingPool.sol";
import { IRizLendingPoolAddressesProvider } from "../interfaces/Riz/IRizLendingPoolAddressesProvider.sol";

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 *
 */
contract RizLendingPoolAddressesProvider is Initializable, OwnableUpgradeable, IRizLendingPoolAddressesProvider {
    string private _marketId;
    mapping(bytes32 => address) private _addresses;
    address private _liquidationFeeTo;
    address public leverager;
    address public badDebtManager;
    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
    bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
    bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER = "COLLATERAL_MANAGER";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";
    bytes32 private constant RIZ_REGISTRY = "RIZ_REGISTRY";

    event LeveragerSet(address leverager);
    event BadDebtManagerSet(address badDebtManager);
    event RizRegistryUpdated(address rizRegistry);

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory marketId) external initializer {
        __Ownable_init();
        _setMarketId(marketId);
    }

    /**
     * @dev Returns the id of the Aave market to which this contracts points to
     * @return The market id
     *
     */
    function getMarketId() external view returns (string memory) {
        return _marketId;
    }

    /**
     * @dev Allows to set the market which this LendingPoolAddressesProvider represents
     * @param marketId The market id
     */
    function setMarketId(string memory marketId) external onlyOwner {
        _setMarketId(marketId);
    }

    /// @dev Sets the address of the leverager
    /// @param _leverager The address of the leverager
    function setLeverager(address _leverager) external onlyOwner {
        leverager = _leverager;
        emit LeveragerSet(_leverager);
    }

    /// @dev Sets the address of the bad debt manager
    /// @param _badDebtManager The address of the bad debt manager
    function setBadDebtManager(address _badDebtManager) external onlyOwner {
        badDebtManager = _badDebtManager;
        emit BadDebtManagerSet(_badDebtManager);
    }

    /**
     * @dev General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `implementationAddress`
     * IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param implementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address implementationAddress) external onlyOwner {
        _updateImpl(id, implementationAddress);
        emit AddressSet(id, implementationAddress, true);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view returns (address) {
        return _addresses[id];
    }

    /**
     * @dev Returns the address of the LendingPool proxy
     * @return The LendingPool proxy address
     *
     */
    function getLendingPool() external view returns (address) {
        return getAddress(LENDING_POOL);
    }

    /**
     * @dev Updates the implementation of the LendingPool, or creates the proxy
     * setting the new `pool` implementation on the first time calling it
     * @param pool The new LendingPool implementation
     *
     */
    function setLendingPoolImpl(address pool) external onlyOwner {
        _updateImpl(LENDING_POOL, pool);
        emit LendingPoolUpdated(pool);
    }

    /**
     * @dev Returns the address of the LendingPoolConfigurator proxy
     * @return The LendingPoolConfigurator proxy address
     *
     */
    function getLendingPoolConfigurator() external view returns (address) {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    /// @dev Returns the address of the leverager
    /// @return The address of the leverager
    function getLeverager() external view returns (address) {
        return leverager;
    }

    /// @dev Returns the address of the bad debt manager
    /// @return The address of the bad debt manager
    function getBadDebtManager() external view returns (address) {
        return badDebtManager;
    }

    /**
     * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
     * setting the new `configurator` implementation on the first time calling it
     * @param configurator The new LendingPoolConfigurator implementation
     *
     */
    function setLendingPoolConfiguratorImpl(address configurator) external onlyOwner {
        _updateImpl(LENDING_POOL_CONFIGURATOR, configurator);
        emit LendingPoolConfiguratorUpdated(configurator);
    }

    /**
     * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
     * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
     * the addresses are changed directly
     * @return The address of the LendingPoolCollateralManager
     *
     */
    function getLendingPoolCollateralManager() external view returns (address) {
        return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
    }

    /**
     * @dev Updates the address of the LendingPoolCollateralManager
     * @param manager The new LendingPoolCollateralManager address
     *
     */
    function setLendingPoolCollateralManager(address manager) external onlyOwner {
        _addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
        emit LendingPoolCollateralManagerUpdated(manager);
    }

    /**
     * @dev Returns the address of the RizRegistry proxy
     * @return The RizRegistry proxy address
     *
     */
    function getRizRegistry() external view returns (address) {
        return getAddress(RIZ_REGISTRY);
    }

    /**
     * @dev Updates the address of the RizRegistry
     * @param rizRegistry The new RizRegistry address
     */
    function setRizRegistry(address rizRegistry) external onlyOwner {
        _addresses[RIZ_REGISTRY] = rizRegistry;
        emit RizRegistryUpdated(rizRegistry);
    }

    /**
     * @dev The functions below are getters/setters of addresses that are outside the context
     * of the protocol hence the upgradable proxy pattern is not used
     *
     */
    function getPoolAdmin() external view returns (address) {
        return getAddress(POOL_ADMIN);
    }

    function setPoolAdmin(address admin) external onlyOwner {
        _addresses[POOL_ADMIN] = admin;
        emit ConfigurationAdminUpdated(admin);
    }

    function getEmergencyAdmin() external view returns (address) {
        return getAddress(EMERGENCY_ADMIN);
    }

    function setEmergencyAdmin(address emergencyAdmin) external onlyOwner {
        _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
        emit EmergencyAdminUpdated(emergencyAdmin);
    }

    function getPriceOracle() external view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address priceOracle) external onlyOwner {
        _addresses[PRICE_ORACLE] = priceOracle;
        emit PriceOracleUpdated(priceOracle);
    }

    function getLendingRateOracle() external view returns (address) {
        return getAddress(LENDING_RATE_ORACLE);
    }

    function setLendingRateOracle(address lendingRateOracle) external onlyOwner {
        _addresses[LENDING_RATE_ORACLE] = lendingRateOracle;
        emit LendingRateOracleUpdated(lendingRateOracle);
    }

    function getLiquidationFeeTo() external view returns (address) {
        return _liquidationFeeTo;
    }

    function setLiquidationFeeTo(address liquidationFeeTo) external onlyOwner {
        _liquidationFeeTo = liquidationFeeTo;
    }

    /**
     * @dev Internal function to update the implementation of a specific proxied component of the protocol
     * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
     *   as implementation and calls the initialize() function on the proxy
     * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     *
     */
    function _updateImpl(bytes32 id, address newAddress) internal {
        address payable proxyAddress = payable(_addresses[id]);

        InitializableImmutableAdminUpgradeabilityProxy proxy =
            InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeCall(ILendingPool.initialize, IRizLendingPoolAddressesProvider(address(this)));

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
            proxy.initialize(newAddress, params);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    function _setMarketId(string memory marketId) internal {
        _marketId = marketId;
        emit MarketIdSet(marketId);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;

	function getLiquidationFeeTo() external view returns (address);

	function setLiquidationFeeTo(address liquidationFeeTo) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {
	struct InitReserveInput {
		address aTokenImpl;
		address stableDebtTokenImpl;
		address variableDebtTokenImpl;
		uint8 underlyingAssetDecimals;
		address interestRateStrategyAddress;
		address underlyingAsset;
		address treasury;
		address incentivesController;
		uint256 allocPoint;
		string underlyingAssetName;
		string aTokenName;
		string aTokenSymbol;
		string variableDebtTokenName;
		string variableDebtTokenSymbol;
		string stableDebtTokenName;
		string stableDebtTokenSymbol;
		bytes params;
	}

	struct UpdateATokenInput {
		address asset;
		address treasury;
		address incentivesController;
		string name;
		string symbol;
		address implementation;
		bytes params;
	}

	struct UpdateDebtTokenInput {
		address asset;
		address incentivesController;
		string name;
		string symbol;
		address implementation;
		bytes params;
	}

	/**
	 * @dev Emitted when a reserve is initialized.
	 * @param asset The address of the underlying asset of the reserve
	 * @param aToken The address of the associated aToken contract
	 * @param stableDebtToken The address of the associated stable rate debt token
	 * @param variableDebtToken The address of the associated variable rate debt token
	 * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
	 **/
	event ReserveInitialized(
		address indexed asset,
		address indexed aToken,
		address stableDebtToken,
		address variableDebtToken,
		address interestRateStrategyAddress
	);

	/**
	 * @dev Emitted when borrowing is enabled on a reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
	 **/
	event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);

	/**
	 * @dev Emitted when borrowing is disabled on a reserve
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event BorrowingDisabledOnReserve(address indexed asset);

	/**
	 * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
	 * @param asset The address of the underlying asset of the reserve
	 * @param ltv The loan to value of the asset when used as collateral
	 * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
	 * @param liquidationBonus The bonus liquidators receive to liquidate this asset
	 **/
	event CollateralConfigurationChanged(
		address indexed asset,
		uint256 ltv,
		uint256 liquidationThreshold,
		uint256 liquidationBonus
	);

	/**
	 * @dev Emitted when stable rate borrowing is enabled on a reserve
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event StableRateEnabledOnReserve(address indexed asset);

	/**
	 * @dev Emitted when stable rate borrowing is disabled on a reserve
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event StableRateDisabledOnReserve(address indexed asset);

	/**
	 * @dev Emitted when a reserve is activated
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event ReserveActivated(address indexed asset);

	/**
	 * @dev Emitted when a reserve is deactivated
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event ReserveDeactivated(address indexed asset);

	/**
	 * @dev Emitted when a reserve is frozen
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event ReserveFrozen(address indexed asset);

	/**
	 * @dev Emitted when a reserve is unfrozen
	 * @param asset The address of the underlying asset of the reserve
	 **/
	event ReserveUnfrozen(address indexed asset);

	/**
	 * @dev Emitted when a reserve factor is updated
	 * @param asset The address of the underlying asset of the reserve
	 * @param factor The new reserve factor
	 **/
	event ReserveFactorChanged(address indexed asset, uint256 factor);

	/**
	 * @dev Emitted when the borrow cap of a reserve is updated.
	 * @param asset The address of the underlying asset of the reserve
	 * @param oldBorrowCap The old borrow cap
	 * @param newBorrowCap The new borrow cap
	 */
	event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

	/**
	 * @dev Emitted when the supply cap of a reserve is updated.
	 * @param asset The address of the underlying asset of the reserve
	 * @param oldSupplyCap The old supply cap
	 * @param newSupplyCap The new supply cap
	 */
	event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

	/**
	 * @dev Emitted when the reserve decimals are updated
	 * @param asset The address of the underlying asset of the reserve
	 * @param decimals The new decimals
	 **/
	event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

	/**
	 * @dev Emitted when a reserve interest strategy contract is updated
	 * @param asset The address of the underlying asset of the reserve
	 * @param strategy The new address of the interest strategy contract
	 **/
	event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

	/**
	 * @dev Emitted when an aToken implementation is upgraded
	 * @param asset The address of the underlying asset of the reserve
	 * @param proxy The aToken proxy address
	 * @param implementation The new aToken implementation
	 **/
	event ATokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

	/**
	 * @dev Emitted when the implementation of a stable debt token is upgraded
	 * @param asset The address of the underlying asset of the reserve
	 * @param proxy The stable debt token proxy address
	 * @param implementation The new aToken implementation
	 **/
	event StableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

	/**
	 * @dev Emitted when the implementation of a variable debt token is upgraded
	 * @param asset The address of the underlying asset of the reserve
	 * @param proxy The variable debt token proxy address
	 * @param implementation The new aToken implementation
	 **/
	event VariableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {ILendingRateOracle} from "../../interfaces/ILendingRateOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingRateOracle is ILendingRateOracle, Ownable {
	mapping(address => uint256) borrowRates;
	mapping(address => uint256) liquidityRates;

	function getMarketBorrowRate(address _asset) external view override returns (uint256) {
		return borrowRates[_asset];
	}

	function setMarketBorrowRate(address _asset, uint256 _rate) external override onlyOwner {
		borrowRates[_asset] = _rate;
	}

	function getMarketLiquidityRate(address _asset) external view returns (uint256) {
		return liquidityRates[_asset];
	}

	function setMarketLiquidityRate(address _asset, uint256 _rate) external onlyOwner {
		liquidityRates[_asset] = _rate;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { RizLendingPool } from "./riz-lending/RizLendingPool.sol";
import { RizLendingPoolAddressesProvider } from "./riz-lending/RizLendingPoolAddressesProvider.sol";
import { OracleRouter } from "./OracleRouter.sol";
import { Errors } from "./libraries/Errors.sol";
import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BadDebtManager is OwnableUpgradeable {
    ///////////////////// ô¿ô Constants ô¿ô /////////////////////
    uint256 public constant BIPS_HIGH_PRECISION_DIVISOR = 1_000_000_000;
    uint256 public constant DENOMINATOR = 1e18;
    ///////////////////// ô¿ô Storage ô¿ô /////////////////////
    /// @dev Token prices mapping for snapshotting
    mapping(address => uint256) public tokenPrices;
    /// @dev Asset ratios mapping for snapshotting.
    /// @dev For example, if pool has 50% RIZ and 50% USDC, then assetRatios[RIZ] = 50% and assetRatios[USDC] = 50%
    mapping(address => uint256) public assetRatios;
    /// @dev Mapping to store all user's emergency withdrawals. Each user can only withdraw once
    mapping(address => bool) public emergencyWithdrawals;
    /// @dev The lower the ratio, the more slashing will be done to each user withdrawing
    uint256 public slashingRatio;
    address public rizLendingPool;

    modifier onlyLendingPool() {
        if (msg.sender != rizLendingPool) {
            revert Errors.InvalidLendingPool();
        }
        _;
    }

    ///////////////////// ô¿ô Events ô¿ô /////////////////////
    event ParamsSetManually(address[] assets, uint256[] prices, uint256[] ratios, uint256 slashingRatio);
    event Snapshot(uint256 badDebt, uint256 slashingRatio);
    event UserEmergencyWithdrawal(address indexed user);

    /// @dev Constructor with disabled initializers
    constructor() {
        _disableInitializers();
    }

    function initialize(address _rizLendingPool, address _owner) public initializer {
        // Make sure that the lending pool address is not 0 and _owner is not 0
        if (_rizLendingPool == address(0) || _owner == address(0)) {
            revert Errors.AddressZero();
        }
        rizLendingPool = _rizLendingPool;
        _transferOwnership(_owner);
    }

    ////////////////// ô¿ô External and Public Functions ô¿ô //////////////////

    /// @notice Function to set the total deposits and borrows
    /// @param _badDebt Amount of bad debt
    function snapshot(uint256 _badDebt) external onlyLendingPool {
        if (_badDebt == 0) {
            revert Errors.BadDebtIsZero();
        }
        _snapshot(_badDebt);
    }

    /// @notice Function to set user withdrawal status
    /// @param _user User address
    function setEmergencyWithdrawal(address _user) external onlyLendingPool {
        emergencyWithdrawals[_user] = true;
        emit UserEmergencyWithdrawal(_user);
    }

    /// @notice Emergency admin can set prices, ratios and slashing ratio manually in case something goes wrong
    function setParamsForEmergencyWithdrawals(
        address[] calldata _assets,
        uint256[] calldata _prices,
        uint256[] calldata _ratios,
        uint256 _slashingRatio
    ) external onlyOwner {
        // Check that there are no 0 addresses in the assets array
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == address(0)) {
                revert Errors.AddressZero();
            }
        }
        if (_assets.length == 0 || _prices.length == 0 || _ratios.length == 0) {
            revert Errors.InvalidAssetsLength();
        }
        if (_assets.length != _prices.length || _assets.length != _ratios.length) {
            revert Errors.InvalidAssetsLength();
        }
        for (uint256 i = 0; i < _assets.length; i++) {
            tokenPrices[_assets[i]] = _prices[i];
            assetRatios[_assets[i]] = _ratios[i];
        }
        slashingRatio = _slashingRatio;
        emit ParamsSetManually(_assets, _prices, _ratios, _slashingRatio);
    }

    /// @notice Function to check if user has already withdrawn
    /// @param _user User address
    function hasUserWithdrawn(address _user) external view returns (bool) {
        return emergencyWithdrawals[_user];
    }

    /// @notice Getter to get snapshotted price of the asset
    /// @param _asset Asset address
    function getAssetPrice(address _asset) external view returns (uint256) {
        return tokenPrices[_asset];
    }

    /// @notice Getter to get snapshotted asset ratio
    /// @param _asset Asset address
    function getAssetRatio(address _asset) external view returns (uint256) {
        return assetRatios[_asset];
    }

    ////////////////// ô¿ô Internal Functions ô¿ô //////////////////
    /// @notice Function to snapshot the prices of the particular lending pool reserve assets
    /// @notice it is also calculating the asset ratios in the bricked lending pool
    function _snapshot(uint256 _badDebt) internal {
        RizLendingPool pool = RizLendingPool(rizLendingPool);
        address[] memory reserves = pool.getReservesList();
        address addressesProvider = address(pool.getAddressesProvider());
        OracleRouter oracleRouter =
            OracleRouter(payable(RizLendingPoolAddressesProvider(addressesProvider).getPriceOracle()));
        // Iterate through each reserve, get current oracle price and snapshot it
        uint256[] memory assetsLiquidity = new uint256[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            address reserve = reserves[i];
            // Price is in 1e18 precision
            uint256 price = OracleRouter(oracleRouter).getAssetPrice(reserve);
            tokenPrices[reserve] = price;
            DataTypes.ReserveData memory currentConfig = pool.getReserveData(reserve);
            // Now we need to calculate total asset liquidity sitting in atoken and variable debt token
            uint256 assetLiquidity = IERC20(reserve).balanceOf(currentConfig.aTokenAddress);
            assetsLiquidity[i] = assetLiquidity;
        }
        // Now that we have all the prices, we know all the tokens liquidities sitting in the pool, we can calculate
        // Their relative ratios to one another in USD
        uint256 totalLiquidityUSD = 0;
        for (uint256 i = 0; i < assetsLiquidity.length; i++) {
            totalLiquidityUSD += (assetsLiquidity[i] * tokenPrices[reserves[i]]) / DENOMINATOR;
        }
        for (uint256 i = 0; i < assetsLiquidity.length; i++) {
            // Now that we calculated the prices, we can calculate the asset ratios based on their USD values
            assetRatios[reserves[i]] = (assetsLiquidity[i] * tokenPrices[reserves[i]] * BIPS_HIGH_PRECISION_DIVISOR)
                / totalLiquidityUSD / DENOMINATOR;
        }

        // We need to calculate slashing ratio.
        // Formula is: (totalRemainingLiquidityUSD / totalRemainingLiquidityUSD + badDebt). Precision needs to be high
        slashingRatio = (totalLiquidityUSD * BIPS_HIGH_PRECISION_DIVISOR) / (totalLiquidityUSD + _badDebt);
        emit Snapshot(_badDebt, slashingRatio);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAToken} from "../../interfaces/IAToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IMiddleFeeDistribution} from "../../interfaces/IMiddleFeeDistribution.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";

/**
 * @title Aave ERC20 AToken
 * @dev Implementation of the interest bearing token for the Aave protocol
 * @author Aave
 */
contract AToken is VersionedInitializable, IncentivizedERC20("ATOKEN_IMPL", "ATOKEN_IMPL", 0), IAToken {
	using WadRayMath for uint256;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	bytes public constant EIP712_REVISION = bytes("1");
	bytes32 internal constant EIP712_DOMAIN =
		keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
	bytes32 public constant PERMIT_TYPEHASH =
		keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	uint256 public constant ATOKEN_REVISION = 0x2;

	/// @dev owner => next valid nonce to submit with permit()
	mapping(address => uint256) public _nonces;

	bytes32 public DOMAIN_SEPARATOR;

	address internal _treasury;
	IAaveIncentivesController internal _incentivesController;

	error AddressZero();

	event TreasuryAddressUpdated(address indexed treasury);

	modifier onlyLendingPool() {
		require(_msgSender() == address(_pool), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
		_;
	}

	modifier onlyPoolAdmin() {
		ILendingPoolAddressesProvider lpAddressProvider = ILendingPoolAddressesProvider(_pool.getAddressesProvider());
		require(lpAddressProvider.getPoolAdmin() == msg.sender, Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR);
		_;
	}

	function getRevision() internal pure virtual override returns (uint256) {
		return ATOKEN_REVISION;
	}

	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev Initializes the aToken
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param treasury The address of the Aave treasury, receiving the fees on this aToken
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
	 * @param aTokenName The name of the aToken
	 * @param aTokenSymbol The symbol of the aToken
	 */
	function initialize(
		ILendingPool pool,
		address treasury,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 aTokenDecimals,
		string calldata aTokenName,
		string calldata aTokenSymbol,
		bytes calldata params
	) external override initializer {
		uint256 chainId;

		//solium-disable-next-line
		assembly {
			chainId := chainid()
		}

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(EIP712_DOMAIN, keccak256(bytes(aTokenName)), keccak256(EIP712_REVISION), chainId, address(this))
		);

		_setName(aTokenName);
		_setSymbol(aTokenSymbol);
		_setDecimals(aTokenDecimals);

		_pool = pool;
		_treasury = treasury;
		_underlyingAsset = underlyingAsset;
		_incentivesController = incentivesController;

		emit Initialized(
			underlyingAsset,
			address(pool),
			treasury,
			address(incentivesController),
			aTokenDecimals,
			aTokenName,
			aTokenSymbol,
			params
		);
	}

	/**
	 * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
	 * - Only callable by the LendingPool, as extra state updates there need to be managed
	 * @param user The owner of the aTokens, getting them burned
	 * @param receiverOfUnderlying The address that will receive the underlying
	 * @param amount The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	function burn(
		address user,
		address receiverOfUnderlying,
		uint256 amount,
		uint256 index
	) external override onlyLendingPool {
		uint256 amountScaled = amount.rayDiv(index);
		require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
		_burn(user, amountScaled);

		IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

		emit Transfer(user, address(0), amount);
		emit Burn(user, receiverOfUnderlying, amount, index);
	}

	/**
	 * @dev Mints `amount` aTokens to `user`
	 * - Only callable by the LendingPool, as extra state updates there need to be managed
	 * @param user The address receiving the minted tokens
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 * @return `true` if the the previous balance of the user was 0
	 */
	function mint(address user, uint256 amount, uint256 index) external override onlyLendingPool returns (bool) {
		uint256 previousBalance = super.balanceOf(user);

		uint256 amountScaled = amount.rayDiv(index);
		require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
		_mint(user, amountScaled);

		emit Transfer(address(0), user, amount);
		emit Mint(user, amount, index);

		return previousBalance == 0;
	}

	/**
	 * @dev Mints aTokens to the reserve treasury
	 * - Only callable by the LendingPool
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 */
	function mintToTreasury(uint256 amount, uint256 index) external override onlyLendingPool {
		if (amount == 0) {
			return;
		}

		address treasury = _treasury;

		// Compared to the normal mint, we don't check for rounding errors.
		// The amount to mint can easily be very small since it is a fraction of the interest ccrued.
		// In that case, the treasury will experience a (very small) loss, but it
		// wont cause potentially valid transactions to fail.
		_mint(treasury, amount.rayDiv(index));

		emit Transfer(address(0), treasury, amount);
		emit Mint(treasury, amount, index);
	}

	/**
	 * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
	 * - Only callable by the LendingPool
	 * @param from The address getting liquidated, current owner of the aTokens
	 * @param to The recipient
	 * @param value The amount of tokens getting transferred
	 **/
	function transferOnLiquidation(address from, address to, uint256 value) external override onlyLendingPool {
		// Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
		// so no need to emit a specific event here
		_transfer(from, to, value, false);

		emit Transfer(from, to, value);
	}

	/**
	 * @dev Calculates the balance of the user: principal balance + interest generated by the principal
	 * @param user The user whose balance is calculated
	 * @return The balance of the user
	 **/
	function balanceOf(address user) public view override(IncentivizedERC20, IERC20) returns (uint256) {
		return super.balanceOf(user).rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
	}

	/**
	 * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
	 * updated stored balance divided by the reserve's liquidity index at the moment of the update
	 * @param user The user whose balance is calculated
	 * @return The scaled balance of the user
	 **/
	function scaledBalanceOf(address user) external view override returns (uint256) {
		return super.balanceOf(user);
	}

	/**
	 * @dev Returns the scaled balance of the user and the scaled total supply.
	 * @param user The address of the user
	 * @return The scaled balance of the user
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
		return (super.balanceOf(user), super.totalSupply());
	}

	/**
	 * @dev calculates the total supply of the specific aToken
	 * since the balance of every single user increases over time, the total supply
	 * does that too.
	 * @return the current total supply
	 **/
	function totalSupply() public view override(IncentivizedERC20, IERC20) returns (uint256) {
		uint256 currentSupplyScaled = super.totalSupply();

		if (currentSupplyScaled == 0) {
			return 0;
		}

		return currentSupplyScaled.rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
	}

	/**
	 * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
	 * @return the scaled total supply
	 **/
	function scaledTotalSupply() public view virtual override returns (uint256) {
		return super.totalSupply();
	}

	/**
	 * @dev Returns the address of the Aave treasury, receiving the fees on this aToken
	 **/
	function RESERVE_TREASURY_ADDRESS() public view returns (address) {
		return _treasury;
	}

	/**
	 * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 **/
	function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
		return _underlyingAsset;
	}

	/**
	 * @dev Returns the address of the lending pool where this aToken is used
	 **/
	function POOL() public view returns (ILendingPool) {
		return _pool;
	}

	/**
	 * @dev For internal usage in the logic of the parent contract IncentivizedERC20
	 **/
	function _getIncentivesController() internal view override returns (IAaveIncentivesController) {
		return _incentivesController;
	}

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view override returns (IAaveIncentivesController) {
		return _getIncentivesController();
	}

	/**
	 * @dev Updates the treasury address
	 * @param treasury The new treasury address
	 */
	function setTreasuryAddress(address treasury) external onlyPoolAdmin {
		if (treasury == address(0)) revert AddressZero();
		_treasury = treasury;
		emit TreasuryAddressUpdated(treasury);
	}

	/**
	 * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
	 * assets in borrow(), withdraw() and flashLoan()
	 * @param target The recipient of the aTokens
	 * @param amount The amount getting transferred
	 * @return The amount transferred
	 **/
	function transferUnderlyingTo(address target, uint256 amount) external override onlyLendingPool returns (uint256) {
		IERC20(_underlyingAsset).safeTransfer(target, amount);
		return amount;
	}

	/**
	 * @dev Invoked to execute actions on the aToken side after a repayment.
	 * @param user The user executing the repayment
	 * @param amount The amount getting repaid
	 **/
	function handleRepayment(address user, uint256 amount) external override onlyLendingPool {}

	/**
	 * @dev implements the permit function as for
	 * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
	 * @param owner The owner of the funds
	 * @param spender The spender
	 * @param value The amount
	 * @param deadline The deadline timestamp, type(uint256).max for max deadline
	 * @param v Signature param
	 * @param s Signature param
	 * @param r Signature param
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		require(owner != address(0), "INVALID_OWNER");
		//solium-disable-next-line
		require(block.timestamp <= deadline, "INVALID_EXPIRATION");
		uint256 currentValidNonce = _nonces[owner];
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
			)
		);
		require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
		_nonces[owner] = currentValidNonce.add(1);
		_approve(owner, spender, value);
	}

	/**
	 * @dev Transfers the aTokens between two users. Validates the transfer
	 * (ie checks for valid HF after the transfer) if required
	 * @param from The source address
	 * @param to The destination address
	 * @param amount The amount getting transferred
	 * @param validate `true` if the transfer needs to be validated
	 **/
	function _transfer(address from, address to, uint256 amount, bool validate) internal {
		address underlyingAsset = _underlyingAsset;
		ILendingPool pool = _pool;

		uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

		uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
		uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

		super._transfer(from, to, amount.rayDiv(index));

		if (validate) {
			pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
		}

		emit BalanceTransfer(from, to, amount, index);
	}

	/**
	 * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
	 * @param from The source address
	 * @param to The destination address
	 * @param amount The amount getting transferred
	 **/
	function _transfer(address from, address to, uint256 amount) internal override {
		_transfer(from, to, amount, true);
	}
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IWETH {
	function balanceOf(address) external returns (uint256);

	function deposit() external payable;

	function withdraw(uint256) external;

	function approve(address guy, uint256 wad) external returns (bool);

	function transferFrom(address src, address dst, uint256 wad) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function allowance(address owner, address spender) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IWETHGateway {
	function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;

	function withdrawETH(address lendingPool, uint256 amount, address onBehalfOf) external;

	function repayETH(address lendingPool, uint256 amount, uint256 rateMode, address onBehalfOf) external payable;

	function borrowETH(address lendingPool, uint256 amount, uint256 interesRateMode, uint16 referralCode) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../lending/libraries/types/DataTypes.sol";

interface ILendingPool {
	/**
	 * @dev Emitted on deposit()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
	 * @param amount The amount deposited
	 * @param referral The referral code used
	 **/
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on withdraw()
	 * @param reserve The address of the underlyng asset being withdrawn
	 * @param user The address initiating the withdrawal, owner of aTokens
	 * @param to Address that will receive the underlying
	 * @param amount The amount to be withdrawn
	 **/
	event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

	/**
	 * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
	 * @param reserve The address of the underlying asset being borrowed
	 * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
	 * initiator of the transaction on flashLoan()
	 * @param onBehalfOf The address that will be getting the debt
	 * @param amount The amount borrowed out
	 * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
	 * @param borrowRate The numeric rate at which the user has borrowed
	 * @param referral The referral code used
	 **/
	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on repay()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The beneficiary of the repayment, getting his debt reduced
	 * @param repayer The address of the user initiating the repay(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

	/**
	 * @dev Emitted on swapBorrowRateMode()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user swapping his rate mode
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on rebalanceStableBorrowRate()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user for which the rebalance has been executed
	 **/
	event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The address of the flash loan receiver contract
	 * @param initiator The address initiating the flash loan
	 * @param asset The address of the asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param premium The fee flash borrowed
	 * @param referralCode The referral code used
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	/**
	 * @dev Emitted when the pause is triggered.
	 */
	event Paused();

	/**
	 * @dev Emitted when the pause is lifted.
	 */
	event Unpaused();

	/**
	 * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
	 * LendingPoolCollateral manager using a DELEGATECALL
	 * This allows to have the events in the generated ABI for LendingPool.
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	/**
	 * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
	 * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
	 * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
	 * gets added to the LendingPool ABI
	 * @param reserve The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	function initialize(ILendingPoolAddressesProvider provider) external;

	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(address asset, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 **/
	function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
	 * @param asset The address of the underlying asset borrowed
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 **/
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The address of the underlying asset deposited
	 * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
	 **/
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
	 * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
	 *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	/**
	 * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
	 * as long as the amount taken plus a fee is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * For further details please visit https://developers.aave.com
	 * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
	 * @param assets The addresses of the assets being flash-borrowed
	 * @param amounts The amounts amounts being flash-borrowed
	 * @param modes Types of the debt to open if the flash loan is not returned:
	 *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
	 *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
	 * @param params Variadic packed params to pass to the receiver as extra information
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function flashLoan(
		address receiverAddress,
		address[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	/**
	 * @dev Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateral the total collateral in USD to 8 decimals of the user
	 * @return totalDebt the total debt in USD to 8 decimals of the user
	 * @return availableBorrows the borrowing power left of the user
	 * @return currentLiquidationThreshold the liquidation threshold of the user
	 * @return ltv the loan to value of the user
	 * @return healthFactor the current health factor of the user
	 **/
	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateral,
			uint256 totalDebt,
			uint256 availableBorrows,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	/**
	 * @dev Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 **/
	function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @dev Returns the configuration of the user across all the reserves
	 * @param user The user address
	 * @return The configuration of the user
	 **/
	function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

	/**
	 * @dev Returns the normalized income normalized income of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve's normalized income
	 */
	function getReserveNormalizedIncome(address asset) external view returns (uint256);

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve normalized variable debt
	 */
	function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableAToken} from "./IInitializableAToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";
import {ILendingPool} from "./ILendingPool.sol";

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
	/**
	 * @dev Emitted after the mint action
	 * @param from The address performing the mint
	 * @param value The amount being
	 * @param index The new liquidity index of the reserve
	 **/
	event Mint(address indexed from, uint256 value, uint256 index);

	/**
	 * @dev Mints `amount` aTokens to `user`
	 * @param user The address receiving the minted tokens
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 * @return `true` if the the previous balance of the user was 0
	 */
	function mint(address user, uint256 amount, uint256 index) external returns (bool);

	/**
	 * @dev Emitted after aTokens are burned
	 * @param from The owner of the aTokens, getting them burned
	 * @param target The address that will receive the underlying
	 * @param value The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

	/**
	 * @dev Emitted during the transfer action
	 * @param from The user whose tokens are being transferred
	 * @param to The recipient
	 * @param value The amount being transferred
	 * @param index The new liquidity index of the reserve
	 **/
	event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

	/**
	 * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
	 * @param user The owner of the aTokens, getting them burned
	 * @param receiverOfUnderlying The address that will receive the underlying
	 * @param amount The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

	/**
	 * @dev Mints aTokens to the reserve treasury
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 */
	function mintToTreasury(uint256 amount, uint256 index) external;

	/**
	 * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
	 * @param from The address getting liquidated, current owner of the aTokens
	 * @param to The recipient
	 * @param value The amount of tokens getting transferred
	 **/
	function transferOnLiquidation(address from, address to, uint256 value) external;

	/**
	 * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
	 * assets in borrow(), withdraw() and flashLoan()
	 * @param user The recipient of the underlying
	 * @param amount The amount getting transferred
	 * @return The amount transferred
	 **/
	function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

	/**
	 * @dev Invoked to execute actions on the aToken side after a repayment.
	 * @param user The user executing the repayment
	 * @param amount The amount getting repaid
	 **/
	function handleRepayment(address user, uint256 amount) external;

	/**
	 * @dev Updates the treasury address
	 * @param treasury The new treasury address
	 */
	function setTreasuryAddress(address treasury) external;

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);

	/**
	 * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 **/
	function UNDERLYING_ASSET_ADDRESS() external view returns (address);

	/**
	 * @dev Returns the address of the lending pool where this aToken is used
	 **/
	function POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
	uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
	uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
	uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
	uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
	uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
	uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

	///@custom:borrow-and-supply-caps
	uint256 internal constant BORROW_CAP_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
	uint256 internal constant SUPPLY_CAP_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

	/// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
	uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
	uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
	uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
	uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
	uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
	uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
	uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
	uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

	///@custom:borrow-and-supply-caps
	uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
	uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;

	uint256 constant MAX_VALID_LTV = 65535;
	uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
	uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
	uint256 constant MAX_VALID_DECIMALS = 255;
	uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

	///@custom:borrow-and-supply-caps
	uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
	uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;

	/**
	 * @dev Sets the Loan to Value of the reserve
	 * @param self The reserve configuration
	 * @param ltv the new ltv
	 **/
	function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
		require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

		self.data = (self.data & LTV_MASK) | ltv;
	}

	/**
	 * @dev Gets the Loan to Value of the reserve
	 * @param self The reserve configuration
	 * @return The loan to value
	 **/
	function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return self.data & ~LTV_MASK;
	}

	/**
	 * @dev Sets the liquidation threshold of the reserve
	 * @param self The reserve configuration
	 * @param threshold The new liquidation threshold
	 **/
	function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
		require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

		self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation threshold of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation threshold
	 **/
	function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the liquidation bonus of the reserve
	 * @param self The reserve configuration
	 * @param bonus The new liquidation bonus
	 **/
	function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
		require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

		self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation bonus of the reserve
	 * @param self The reserve configuration
	 * @return The liquidation bonus
	 **/
	function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the decimals of the underlying asset of the reserve
	 * @param self The reserve configuration
	 * @param decimals The decimals
	 **/
	function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
		require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

		self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the decimals of the underlying asset of the reserve
	 * @param self The reserve configuration
	 * @return The decimals of the asset
	 **/
	function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the active state of the reserve
	 * @param self The reserve configuration
	 * @param active The active state
	 **/
	function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
		self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the active state of the reserve
	 * @param self The reserve configuration
	 * @return The active state
	 **/
	function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~ACTIVE_MASK) != 0;
	}

	/**
	 * @dev Sets the frozen state of the reserve
	 * @param self The reserve configuration
	 * @param frozen The frozen state
	 **/
	function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
		self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the frozen state of the reserve
	 * @param self The reserve configuration
	 * @return The frozen state
	 **/
	function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~FROZEN_MASK) != 0;
	}

	/**
	 * @dev Enables or disables borrowing on the reserve
	 * @param self The reserve configuration
	 * @param enabled True if the borrowing needs to be enabled, false otherwise
	 **/
	function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
		self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The borrowing state
	 **/
	function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
		return (self.data & ~BORROWING_MASK) != 0;
	}

	/**
	 * @dev Enables or disables stable rate borrowing on the reserve
	 * @param self The reserve configuration
	 * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
	 **/
	function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
		self.data =
			(self.data & STABLE_BORROWING_MASK) |
			(uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the stable rate borrowing state of the reserve
	 * @param self The reserve configuration
	 * @return The stable rate borrowing state
	 **/
	function getStableRateBorrowingEnabled(
		DataTypes.ReserveConfigurationMap storage self
	) internal view returns (bool) {
		return (self.data & ~STABLE_BORROWING_MASK) != 0;
	}

	/**
	 * @dev Sets the reserve factor of the reserve
	 * @param self The reserve configuration
	 * @param reserveFactor The reserve factor
	 **/
	function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
		require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

		self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the reserve factor of the reserve
	 * @param self The reserve configuration
	 * @return The reserve factor
	 **/
	function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
		return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
	}

	/**
	 * @notice Sets the borrow cap of the reserve
	 * @param self The reserve configuration
	 * @param borrowCap The borrow cap
	 * @custom:borrow-and-supply-caps
	 */
	function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap) internal pure {
		require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

		self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
	}

	/**
	 * @notice Gets the borrow cap of the reserve
	 * @param self The reserve configuration
	 * @return The borrow cap
	 * @custom:borrow-and-supply-caps
	 */
	function getBorrowCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
		return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
	}

	/**
	 * @notice Sets the supply cap of the reserve
	 * @param self The reserve configuration
	 * @param supplyCap The supply cap
	 * @custom:borrow-and-supply-caps
	 */
	function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
		require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

		self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
	}

	/**
	 * @notice Gets the supply cap of the reserve
	 * @param self The reserve configuration
	 * @return The supply cap
	 * @custom:borrow-and-supply-caps
	 */
	function getSupplyCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
		return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the configuration flags of the reserve
	 * @param self The reserve configuration
	 * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
	 **/
	function getFlags(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool, bool, bool, bool) {
		uint256 dataLocal = self.data;

		return (
			(dataLocal & ~ACTIVE_MASK) != 0,
			(dataLocal & ~FROZEN_MASK) != 0,
			(dataLocal & ~BORROWING_MASK) != 0,
			(dataLocal & ~STABLE_BORROWING_MASK) != 0
		);
	}

	/**
	 * @dev Gets the configuration paramters of the reserve
	 * @param self The reserve configuration
	 * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
	 **/
	function getParams(
		DataTypes.ReserveConfigurationMap storage self
	) internal view returns (uint256, uint256, uint256, uint256, uint256) {
		uint256 dataLocal = self.data;

		return (
			dataLocal & ~LTV_MASK,
			(dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
			(dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
			(dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
		);
	}

	/**
	 * @dev Gets the configuration paramters of the reserve from a memory object
	 * @param self The reserve configuration
	 * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
	 **/
	function getParamsMemory(
		DataTypes.ReserveConfigurationMap memory self
	) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
		return (
			self.data & ~LTV_MASK,
			(self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
			(self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
			(self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
		);
	}

	/**
	 * @dev Gets the configuration flags of the reserve from a memory object
	 * @param self The reserve configuration
	 * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
	 **/
	function getFlagsMemory(
		DataTypes.ReserveConfigurationMap memory self
	) internal pure returns (bool, bool, bool, bool) {
		return (
			(self.data & ~ACTIVE_MASK) != 0,
			(self.data & ~FROZEN_MASK) != 0,
			(self.data & ~BORROWING_MASK) != 0,
			(self.data & ~STABLE_BORROWING_MASK) != 0
		);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
	uint256 internal constant BORROWING_MASK = 0x5555555555555555555555555555555555555555555555555555555555555555;

	/**
	 * @dev Sets if the user is borrowing the reserve identified by reserveIndex
	 * @param self The configuration object
	 * @param reserveIndex The index of the reserve in the bitmap
	 * @param borrowing True if the user is borrowing the reserve, false otherwise
	 **/
	function setBorrowing(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex, bool borrowing) internal {
		require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
		self.data = (self.data & ~(1 << (reserveIndex * 2))) | (uint256(borrowing ? 1 : 0) << (reserveIndex * 2));
	}

	/**
	 * @dev Sets if the user is using as collateral the reserve identified by reserveIndex
	 * @param self The configuration object
	 * @param reserveIndex The index of the reserve in the bitmap
	 * @param usingAsCollateral True if the user is usin the reserve as collateral, false otherwise
	 **/
	function setUsingAsCollateral(
		DataTypes.UserConfigurationMap storage self,
		uint256 reserveIndex,
		bool usingAsCollateral
	) internal {
		require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
		self.data =
			(self.data & ~(1 << (reserveIndex * 2 + 1))) |
			(uint256(usingAsCollateral ? 1 : 0) << (reserveIndex * 2 + 1));
	}

	/**
	 * @dev Used to validate if a user has been using the reserve for borrowing or as collateral
	 * @param self The configuration object
	 * @param reserveIndex The index of the reserve in the bitmap
	 * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
	 **/
	function isUsingAsCollateralOrBorrowing(
		DataTypes.UserConfigurationMap memory self,
		uint256 reserveIndex
	) internal pure returns (bool) {
		require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
		return (self.data >> (reserveIndex * 2)) & 3 != 0;
	}

	/**
	 * @dev Used to validate if a user has been using the reserve for borrowing
	 * @param self The configuration object
	 * @param reserveIndex The index of the reserve in the bitmap
	 * @return True if the user has been using a reserve for borrowing, false otherwise
	 **/
	function isBorrowing(
		DataTypes.UserConfigurationMap memory self,
		uint256 reserveIndex
	) internal pure returns (bool) {
		require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
		return (self.data >> (reserveIndex * 2)) & 1 != 0;
	}

	/**
	 * @dev Used to validate if a user has been using the reserve as collateral
	 * @param self The configuration object
	 * @param reserveIndex The index of the reserve in the bitmap
	 * @return True if the user has been using a reserve as collateral, false otherwise
	 **/
	function isUsingAsCollateral(
		DataTypes.UserConfigurationMap memory self,
		uint256 reserveIndex
	) internal pure returns (bool) {
		require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
		return (self.data >> (reserveIndex * 2 + 1)) & 1 != 0;
	}

	/**
	 * @dev Used to validate if a user has been borrowing from any reserve
	 * @param self The configuration object
	 * @return True if the user has been borrowing any reserve, false otherwise
	 **/
	function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
		return self.data & BORROWING_MASK != 0;
	}

	/**
	 * @dev Used to validate if a user has not been using any reserve
	 * @param self The configuration object
	 * @return True if the user has been borrowing any reserve, false otherwise
	 **/
	function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
		return self.data == 0;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Helpers library
 * @author Aave
 */
library Helpers {
	/**
	 * @dev Fetches the user current stable and variable debt balances
	 * @param user The user address
	 * @param reserve The reserve data object
	 * @return The stable and variable debt balance
	 **/
	function getUserCurrentDebt(
		address user,
		DataTypes.ReserveData storage reserve
	) internal view returns (uint256, uint256) {
		return (
			IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
			IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
		);
	}

	function getUserCurrentDebtMemory(
		address user,
		DataTypes.ReserveData memory reserve
	) internal view returns (uint256, uint256) {
		return (
			IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
			IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
		);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		///@custom:borrow-and-supply-caps
		//bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
		//bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	enum InterestRateMode {
		NONE,
		STABLE,
		VARIABLE
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	uint256 private lastInitializedRevision = 0;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		uint256 revision = getRevision();
		bool isTopLevelCall = !initializing;

		require(
			isTopLevelCall && (revision > lastInitializedRevision || !initialized),
			"Contract instance has already been initialized"
		);

		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
			lastInitializedRevision = revision;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/**
	 * @dev returns the revision number of the contract
	 * Needs to be defined in the inherited class as a constant.
	 **/
	function getRevision() internal pure virtual returns (uint256);

	function _disableInitializers() internal virtual {
		require(!initializing, "Initializable: contract is initializing");
		if (!initialized) {
			lastInitializedRevision = getRevision();
			initialized = true;
		}
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "./BaseImmutableAdminUpgradeabilityProxy.sol";
import "../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
	BaseImmutableAdminUpgradeabilityProxy,
	InitializableUpgradeabilityProxy
{
	constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {}

	/**
	 * @dev Only fall back when the sender is not the admin.
	 */
	function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
		BaseImmutableAdminUpgradeabilityProxy._willFallback();
	}
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
	//common errors
	string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
	string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

	//contract specific errors
	string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
	string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
	string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
	string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
	string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
	string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
	string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
	string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
	string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
	string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
	string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
	string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
	string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
	string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
	string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
	string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
	string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
	string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
	string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
	string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
	string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
	string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
	string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
	string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
	string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
	string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
	string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
	string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
	string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
	string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
	string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
	string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
	string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
	string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
	string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
	string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
	string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
	string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
	string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
	string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
	string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
	string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
	string public constant MATH_ADDITION_OVERFLOW = "49";
	string public constant MATH_DIVISION_BY_ZERO = "50";
	string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
	string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
	string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
	string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
	string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
	string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
	string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
	string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
	string public constant LP_FAILED_COLLATERAL_SWAP = "60";
	string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
	string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
	string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
	string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
	string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
	string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
	string public constant RC_INVALID_LTV = "67";
	string public constant RC_INVALID_LIQ_THRESHOLD = "68";
	string public constant RC_INVALID_LIQ_BONUS = "69";
	string public constant RC_INVALID_DECIMALS = "70";
	string public constant RC_INVALID_RESERVE_FACTOR = "71";
	string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
	string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
	string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
	string public constant UL_INVALID_INDEX = "77";
	string public constant LP_NOT_CONTRACT = "78";
	string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
	string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

	/**
	 * @dev Custom Radiant codes added +200 to avoid conflicts with the AaveV2/V3 ones
	 * @custom:borrow-and-supply-caps
	 */
	string public constant INVALID_BORROW_CAP = "201"; // Invalid borrow cap value
	string public constant INVALID_SUPPLY_CAP = "202"; // Invalid supply cap value
	string public constant BORROW_CAP_EXCEEDED = "203"; // Borrow cap is exceeded
	string public constant SUPPLY_CAP_EXCEEDED = "204"; // Supply cap is exceeded

	enum CollateralManagerErrors {
		NO_ERROR,
		NO_COLLATERAL_AVAILABLE,
		COLLATERAL_CANNOT_BE_LIQUIDATED,
		CURRRENCY_NOT_BORROWED,
		HEALTH_FACTOR_ABOVE_THRESHOLD,
		NOT_ENOUGH_LIQUIDITY,
		NO_ACTIVE_RESERVE,
		HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
		INVALID_EQUAL_ASSETS_TO_SWAP,
		FROZEN_RESERVE
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
	uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
	uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

	/**
	 * @dev Executes a percentage multiplication
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The percentage of value
	 **/
	function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
		if (value == 0 || percentage == 0) {
			return 0;
		}

		require(value <= (type(uint256).max - HALF_PERCENT) / percentage, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
	}

	/**
	 * @dev Executes a percentage division
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The value divided the percentage
	 **/
	function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
		require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfPercentage = percentage / 2;

		require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableDebtToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Aave
 **/
interface IInitializableDebtToken {
	/**
	 * @dev Emitted when a debt token is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param debtTokenDecimals the decimals of the debt token
	 * @param debtTokenName the name of the debt token
	 * @param debtTokenSymbol the symbol of the debt token
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address incentivesController,
		uint8 debtTokenDecimals,
		string debtTokenName,
		string debtTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the debt token.
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
	 * @param debtTokenName The name of the token
	 * @param debtTokenSymbol The symbol of the token
	 */
	function initialize(
		ILendingPool pool,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 debtTokenDecimals,
		string memory debtTokenName,
		string memory debtTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
	/**
	 * @dev Emitted when an aToken is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param treasury The address of the treasury
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param aTokenDecimals the decimals of the underlying
	 * @param aTokenName the name of the aToken
	 * @param aTokenSymbol the symbol of the aToken
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address treasury,
		address incentivesController,
		uint8 aTokenDecimals,
		string aTokenName,
		string aTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the aToken
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param treasury The address of the Aave treasury, receiving the fees on this aToken
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
	 * @param aTokenName The name of the aToken
	 * @param aTokenSymbol The symbol of the aToken
	 */
	function initialize(
		ILendingPool pool,
		address treasury,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 aTokenDecimals,
		string calldata aTokenName,
		string calldata aTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
	event RewardsAccrued(address indexed user, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

	event ClaimerSet(address indexed user, address indexed claimer);

	/*
	 * @dev Returns the configuration of the distribution for a certain asset
	 * @param asset The address of the reference asset of the distribution
	 * @return The asset index, the emission per second and the last updated timestamp
	 **/
	function getAssetData(address asset) external view returns (uint256, uint256, uint256);

	/**
	 * @dev Whitelists an address to claim the rewards on behalf of another address
	 * @param user The address of the user
	 * @param claimer The address of the claimer
	 */
	function setClaimer(address user, address claimer) external;

	/**
	 * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
	 * @param user The address of the user
	 * @return The claimer address
	 */
	function getClaimer(address user) external view returns (address);

	/**
	 * @dev Configure assets for a certain rewards emission
	 * @param assets The assets to incentivize
	 * @param emissionsPerSecond The emission for each asset
	 */
	function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
	 * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
	 * @param amount Amount of rewards to claim
	 * @param user Address to check and claim rewards
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewardsOnBehalf(
		address[] calldata assets,
		uint256 amount,
		address user,
		address to
	) external returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @return the unclaimed user rewards
	 */
	function getUserUnclaimedRewards(address user) external view returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @param asset The asset to incentivize
	 * @return the user index for the asset
	 */
	function getUserAssetData(address user, address asset) external view returns (uint256);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function REWARD_TOKEN() external view returns (address);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function PRECISION() external view returns (uint8);

	/**
	 * @dev Gets the distribution end timestamp of the emissions
	 */
	function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import { IRizLendingPoolAddressesProvider } from "./IRizLendingPoolAddressesProvider.sol";
import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";

interface IRizLendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     *
     */
    event Deposit(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     *
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     *
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     *
     */
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     *
     */
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     *
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     *
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     *
     */
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     *
     */
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emergency Withdrawal
     */
    event EmergencyWithdrawal(address indexed user, uint256 usdAmountWithdrawn);

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the
     * liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     *
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     *
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    function initialize(IRizLendingPoolAddressesProvider provider) external;

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     *
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     *
     */
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     *
     */
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     *
     */
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much
     * has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     *
     */
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     *
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the
     * liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     *
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     *
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     *
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     *
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     *
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (IRizLendingPoolAddressesProvider);

    function setPause(bool val) external;

    function shutdown(uint256 badDebt) external;

    function paused() external view returns (bool);

    function isShutdown() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import { ILendingPoolAddressesProvider } from "@radiant-v2-core/interfaces/ILendingPoolAddressesProvider.sol";

interface IRizLendingPoolAddressesProvider is ILendingPoolAddressesProvider {
    function getLeverager() external view returns (address);
    function getBadDebtManager() external view returns (address);
    function getRizRegistry() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title ILendingPoolCollateralManager
 * @author Aave
 * @notice Defines the actions involving management of collateral in the protocol.
 **/
interface ILendingPoolCollateralManager {
	/**
	 * @dev Emitted when a borrower is liquidated
	 * @param collateral The address of the collateral being liquidated
	 * @param principal The address of the reserve
	 * @param user The address of the user being liquidated
	 * @param debtToCover The total amount liquidated
	 * @param liquidatedCollateralAmount The amount of collateral being liquidated
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken true if the liquidator wants to receive aTokens, false otherwise
	 **/
	event LiquidationCall(
		address indexed collateral,
		address indexed principal,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken,
		address liquidationFeeTo
	);

	/**
	 * @dev Emitted when a reserve is disabled as collateral for an user
	 * @param reserve The address of the reserve
	 * @param user The address of the user
	 **/
	event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted when a reserve is enabled as collateral for an user
	 * @param reserve The address of the reserve
	 * @param user The address of the user
	 **/
	event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

	/**
	 * @dev Users can invoke this function to liquidate an undercollateralized position.
	 * @param collateral The address of the collateral to liquidated
	 * @param principal The address of the principal reserve
	 * @param user The address of the borrower
	 * @param debtToCover The amount of principal that the liquidator wants to repay
	 * @param receiveAToken true if the liquidators wants to receive the aTokens, false if
	 * he wants to receive the underlying asset directly
	 **/
	function liquidationCall(
		address collateral,
		address principal,
		address user,
		uint256 debtToCover,
		bool receiveAToken,
		address liquidationFeeTo
	) external returns (uint256, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { AToken } from "@radiant-v2-core/lending/tokenization/AToken.sol";
import { Errors } from "@radiant-v2-core/lending/libraries/helpers/Errors.sol";
import { Errors as RizErrors } from "../libraries/Errors.sol";
import { RizLendingPool } from "../riz-lending/RizLendingPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WadRayMath } from "@radiant-v2-core/lending/libraries/math/WadRayMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RizAToken is AToken {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    event EmergencyTransfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emergency withdrawal function. Please note, that this should be ONLY called in case
    /// pool is bricked and all users need to withdraw their funds in ratio defined in BadDebtManager
    /// NOTE: This will not burn AToken supplies of users as we need to identify their proportion of
    /// the underlying asset and transfer it to them
    function emergencyWithdrawal(address user, address receiverOfUnderlying, uint256 amount, uint256 index)
        external
        onlyLendingPool
    {
        // We need to check that RizLendingPool is bricked
        if (!RizLendingPool(address(_pool)).isShutdown()) {
            revert RizErrors.PoolNotDisabled();
        }
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        // Transfer without burning. At this stage if pool is bricked, we don't really care about atoken supply anymore
        // and will try to distribute all assets across depositors in a weighted manner
        IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

        emit EmergencyTransfer(user, receiverOfUnderlying, amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
	/**
	 * @dev Emitted after the mint action
	 * @param from The address performing the mint
	 * @param onBehalfOf The address of the user on which behalf minting has been performed
	 * @param value The amount to be minted
	 * @param index The last index of the reserve
	 **/
	event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

	/**
	 * @dev Mints debt token to the `onBehalfOf` address
	 * @param user The address receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The address receiving the debt tokens
	 * @param amount The amount of debt being minted
	 * @param index The variable debt index of the reserve
	 * @return `true` if the the previous balance of the user is 0
	 **/
	function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);

	/**
	 * @dev Emitted when variable debt is burnt
	 * @param user The user which debt has been burned
	 * @param amount The amount of debt being burned
	 * @param index The index of the user
	 **/
	event Burn(address indexed user, uint256 amount, uint256 index);

	/**
	 * @dev Burns user variable debt
	 * @param user The user which debt is burnt
	 * @param index The variable debt index of the reserve
	 **/
	function burn(address user, uint256 amount, uint256 index) external;

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
	/**
	 * @dev returns the asset price in ETH
	 * @param asset the address of the asset
	 * @return the ETH price of the asset
	 **/
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IStableDebtToken
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 * @author Aave
 **/

interface IStableDebtToken is IInitializableDebtToken {
	/**
	 * @dev Emitted when new stable debt is minted
	 * @param user The address of the user who triggered the minting
	 * @param onBehalfOf The recipient of stable debt tokens
	 * @param amount The amount minted
	 * @param currentBalance The current balance of the user
	 * @param balanceIncrease The increase in balance since the last action of the user
	 * @param newRate The rate of the debt after the minting
	 * @param avgStableRate The new average stable rate after the minting
	 * @param newTotalSupply The new total supply of the stable debt token after the action
	 **/
	event Mint(
		address indexed user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 newRate,
		uint256 avgStableRate,
		uint256 newTotalSupply
	);

	/**
	 * @dev Emitted when new stable debt is burned
	 * @param user The address of the user
	 * @param amount The amount being burned
	 * @param currentBalance The current balance of the user
	 * @param balanceIncrease The the increase in balance since the last action of the user
	 * @param avgStableRate The new average stable rate after the burning
	 * @param newTotalSupply The new total supply of the stable debt token after the action
	 **/
	event Burn(
		address indexed user,
		uint256 amount,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 avgStableRate,
		uint256 newTotalSupply
	);

	/**
	 * @dev Mints debt token to the `onBehalfOf` address.
	 * - The resulting rate is the weighted average between the rate of the new debt
	 * and the rate of the previous debt
	 * @param user The address receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The address receiving the debt tokens
	 * @param amount The amount of debt tokens to mint
	 * @param rate The rate of the debt being minted
	 **/
	function mint(address user, address onBehalfOf, uint256 amount, uint256 rate) external returns (bool);

	/**
	 * @dev Burns debt of `user`
	 * - The resulting rate is the weighted average between the rate of the new debt
	 * and the rate of the previous debt
	 * @param user The address of the user getting his debt burned
	 * @param amount The amount of debt tokens getting burned
	 **/
	function burn(address user, uint256 amount) external;

	/**
	 * @dev Returns the average rate of all the stable rate loans.
	 * @return The average stable rate
	 **/
	function getAverageStableRate() external view returns (uint256);

	/**
	 * @dev Returns the stable rate of the user debt
	 * @return The stable rate of the user
	 **/
	function getUserStableRate(address user) external view returns (uint256);

	/**
	 * @dev Returns the timestamp of the last update of the user
	 * @return The timestamp
	 **/
	function getUserLastUpdated(address user) external view returns (uint40);

	/**
	 * @dev Returns the principal, the total supply and the average stable rate
	 **/
	function getSupplyData() external view returns (uint256, uint256, uint256, uint40);

	/**
	 * @dev Returns the timestamp of the last update of the total supply
	 * @return The timestamp
	 **/
	function getTotalSupplyLastUpdated() external view returns (uint40);

	/**
	 * @dev Returns the total supply and the average stable rate
	 **/
	function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

	/**
	 * @dev Returns the principal debt balance of the user
	 * @return The debt balance of the user since the last burn/mint action
	 **/
	function principalBalanceOf(address user) external view returns (uint256);

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface ILeverager {
	function wethToZap(address user) external view returns (uint256);

	function zapWETHWithBorrow(uint256 amount, address borrower) external returns (uint256 liquidity);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
	uint256 internal constant WAD = 1e18;
	uint256 internal constant halfWAD = WAD / 2;

	uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;

	uint256 internal constant WAD_RAY_RATIO = 1e9;

	/**
	 * @return One ray, 1e27
	 **/
	function ray() internal pure returns (uint256) {
		return RAY;
	}

	/**
	 * @return One wad, 1e18
	 **/

	function wad() internal pure returns (uint256) {
		return WAD;
	}

	/**
	 * @return Half ray, 1e27/2
	 **/
	function halfRay() internal pure returns (uint256) {
		return halfRAY;
	}

	/**
	 * @return Half ray, 1e18/2
	 **/
	function halfWad() internal pure returns (uint256) {
		return halfWAD;
	}

	/**
	 * @dev Multiplies two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a*b, in wad
	 **/
	function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * b + halfWAD) / WAD;
	}

	/**
	 * @dev Divides two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a/b, in wad
	 **/
	function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfB = b / 2;

		require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * WAD + halfB) / b;
	}

	/**
	 * @dev Multiplies two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a*b, in ray
	 **/
	function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * b + halfRAY) / RAY;
	}

	/**
	 * @dev Divides two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a/b, in ray
	 **/
	function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfB = b / 2;

		require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * RAY + halfB) / b;
	}

	/**
	 * @dev Casts ray down to wad
	 * @param a Ray
	 * @return a casted to wad, rounded half up to the nearest wad
	 **/
	function rayToWad(uint256 a) internal pure returns (uint256) {
		uint256 halfRatio = WAD_RAY_RATIO / 2;
		uint256 result = halfRatio + a;
		require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

		return result / WAD_RAY_RATIO;
	}

	/**
	 * @dev Converts wad up to ray
	 * @param a Wad
	 * @return a converted in ray
	 **/
	function wadToRay(uint256 a) internal pure returns (uint256) {
		uint256 result = a * WAD_RAY_RATIO;
		require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
		return result;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAToken} from "../../../interfaces/IAToken.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
	using SafeMath for uint256;
	using WadRayMath for uint256;
	using PercentageMath for uint256;
	using SafeERC20 for IERC20;

	/**
	 * @dev Emitted when the state of a reserve is updated
	 * @param asset The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed asset,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	using ReserveLogic for DataTypes.ReserveData;
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

	/**
	 * @dev Returns the ongoing normalized income for the reserve
	 * A value of 1e27 means there is no income. As time passes, the income is accrued
	 * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
	 * @param reserve The reserve object
	 * @return the normalized income. expressed in ray
	 **/
	function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
		uint40 timestamp = reserve.lastUpdateTimestamp;

		//solium-disable-next-line
		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return reserve.liquidityIndex;
		}

		uint256 cumulated = MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
			reserve.liquidityIndex
		);

		return cumulated;
	}

	/**
	 * @dev Returns the ongoing normalized variable debt for the reserve
	 * A value of 1e27 means there is no debt. As time passes, the income is accrued
	 * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
	 * @param reserve The reserve object
	 * @return The normalized variable debt. expressed in ray
	 **/
	function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
		uint40 timestamp = reserve.lastUpdateTimestamp;

		//solium-disable-next-line
		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return reserve.variableBorrowIndex;
		}

		uint256 cumulated = MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
			reserve.variableBorrowIndex
		);

		return cumulated;
	}

	/**
	 * @dev Updates the liquidity cumulative index and the variable borrow index.
	 * @param reserve the reserve object
	 **/
	function updateState(DataTypes.ReserveData storage reserve) internal {
		uint256 scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledTotalSupply();
		uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
		uint256 previousLiquidityIndex = reserve.liquidityIndex;
		uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

		(uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) = _updateIndexes(
			reserve,
			scaledVariableDebt,
			previousLiquidityIndex,
			previousVariableBorrowIndex,
			lastUpdatedTimestamp
		);

		_mintToTreasury(
			reserve,
			scaledVariableDebt,
			previousVariableBorrowIndex,
			newLiquidityIndex,
			newVariableBorrowIndex,
			lastUpdatedTimestamp
		);
	}

	/**
	 * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example to accumulate
	 * the flashloan fee to the reserve, and spread it between all the depositors
	 * @param reserve The reserve object
	 * @param totalLiquidity The total liquidity available in the reserve
	 * @param amount The amount to accomulate
	 **/
	function cumulateToLiquidityIndex(
		DataTypes.ReserveData storage reserve,
		uint256 totalLiquidity,
		uint256 amount
	) internal {
		uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

		uint256 result = amountToLiquidityRatio.add(WadRayMath.ray());

		result = result.rayMul(reserve.liquidityIndex);
		require(result <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

		reserve.liquidityIndex = uint128(result);
	}

	/**
	 * @dev Initializes a reserve
	 * @param reserve The reserve object
	 * @param aTokenAddress The address of the overlying atoken contract
	 * @param interestRateStrategyAddress The address of the interest rate strategy contract
	 **/
	function init(
		DataTypes.ReserveData storage reserve,
		address aTokenAddress,
		address stableDebtTokenAddress,
		address variableDebtTokenAddress,
		address interestRateStrategyAddress
	) external {
		require(reserve.aTokenAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

		reserve.liquidityIndex = uint128(WadRayMath.ray());
		reserve.variableBorrowIndex = uint128(WadRayMath.ray());
		reserve.aTokenAddress = aTokenAddress;
		reserve.stableDebtTokenAddress = stableDebtTokenAddress;
		reserve.variableDebtTokenAddress = variableDebtTokenAddress;
		reserve.interestRateStrategyAddress = interestRateStrategyAddress;
	}

	struct UpdateInterestRatesLocalVars {
		address stableDebtTokenAddress;
		uint256 availableLiquidity;
		uint256 totalStableDebt;
		uint256 newLiquidityRate;
		uint256 newStableRate;
		uint256 newVariableRate;
		uint256 avgStableRate;
		uint256 totalVariableDebt;
	}

	/**
	 * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
	 * @param reserve The address of the reserve to be updated
	 * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
	 * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
	 **/
	function updateInterestRates(
		DataTypes.ReserveData storage reserve,
		address reserveAddress,
		address aTokenAddress,
		uint256 liquidityAdded,
		uint256 liquidityTaken
	) internal {
		UpdateInterestRatesLocalVars memory vars;

		vars.stableDebtTokenAddress = reserve.stableDebtTokenAddress;

		(vars.totalStableDebt, vars.avgStableRate) = IStableDebtToken(vars.stableDebtTokenAddress)
			.getTotalSupplyAndAvgRate();

		//calculates the total variable debt locally using the scaled total supply instead
		//of totalSupply(), as it's noticeably cheaper. Also, the index has been
		//updated by the previous updateState() call
		vars.totalVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledTotalSupply().rayMul(
			reserve.variableBorrowIndex
		);

		(vars.newLiquidityRate, vars.newStableRate, vars.newVariableRate) = IReserveInterestRateStrategy(
			reserve.interestRateStrategyAddress
		).calculateInterestRates(
				reserveAddress,
				aTokenAddress,
				liquidityAdded,
				liquidityTaken,
				vars.totalStableDebt,
				vars.totalVariableDebt,
				vars.avgStableRate,
				reserve.configuration.getReserveFactor()
			);
		require(vars.newLiquidityRate <= type(uint128).max, Errors.RL_LIQUIDITY_RATE_OVERFLOW);
		require(vars.newStableRate <= type(uint128).max, Errors.RL_STABLE_BORROW_RATE_OVERFLOW);
		require(vars.newVariableRate <= type(uint128).max, Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW);

		reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
		reserve.currentStableBorrowRate = uint128(vars.newStableRate);
		reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

		emit ReserveDataUpdated(
			reserveAddress,
			vars.newLiquidityRate,
			vars.newStableRate,
			vars.newVariableRate,
			reserve.liquidityIndex,
			reserve.variableBorrowIndex
		);
	}

	struct MintToTreasuryLocalVars {
		uint256 currentStableDebt;
		uint256 principalStableDebt;
		uint256 previousStableDebt;
		uint256 currentVariableDebt;
		uint256 previousVariableDebt;
		uint256 avgStableRate;
		uint256 cumulatedStableInterest;
		uint256 totalDebtAccrued;
		uint256 amountToMint;
		uint256 reserveFactor;
		uint40 stableSupplyUpdatedTimestamp;
	}

	/**
	 * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
	 * specific asset.
	 * @param reserve The reserve reserve to be updated
	 * @param scaledVariableDebt The current scaled total variable debt
	 * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
	 * @param newLiquidityIndex The new liquidity index
	 * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
	 **/
	function _mintToTreasury(
		DataTypes.ReserveData storage reserve,
		uint256 scaledVariableDebt,
		uint256 previousVariableBorrowIndex,
		uint256 newLiquidityIndex,
		uint256 newVariableBorrowIndex,
		uint40 timestamp
	) internal {
		MintToTreasuryLocalVars memory vars;

		vars.reserveFactor = reserve.configuration.getReserveFactor();

		if (vars.reserveFactor == 0) {
			return;
		}

		//fetching the principal, total stable debt and the avg stable rate
		(
			vars.principalStableDebt,
			vars.currentStableDebt,
			vars.avgStableRate,
			vars.stableSupplyUpdatedTimestamp
		) = IStableDebtToken(reserve.stableDebtTokenAddress).getSupplyData();

		//calculate the last principal variable debt
		vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);

		//calculate the new total supply after accumulation of the index
		vars.currentVariableDebt = scaledVariableDebt.rayMul(newVariableBorrowIndex);

		//calculate the stable debt until the last timestamp update
		vars.cumulatedStableInterest = MathUtils.calculateCompoundedInterest(
			vars.avgStableRate,
			vars.stableSupplyUpdatedTimestamp,
			timestamp
		);

		vars.previousStableDebt = vars.principalStableDebt.rayMul(vars.cumulatedStableInterest);

		//debt accrued is the sum of the current debt minus the sum of the debt at the last update
		vars.totalDebtAccrued = vars.currentVariableDebt.add(vars.currentStableDebt).sub(vars.previousVariableDebt).sub(
			vars.previousStableDebt
		);

		vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

		if (vars.amountToMint != 0) {
			IAToken(reserve.aTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
		}
	}

	/**
	 * @dev Updates the reserve indexes and the timestamp of the update
	 * @param reserve The reserve reserve to be updated
	 * @param scaledVariableDebt The scaled variable debt
	 * @param liquidityIndex The last stored liquidity index
	 * @param variableBorrowIndex The last stored variable borrow index
	 **/
	function _updateIndexes(
		DataTypes.ReserveData storage reserve,
		uint256 scaledVariableDebt,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex,
		uint40 timestamp
	) internal returns (uint256, uint256) {
		uint256 currentLiquidityRate = reserve.currentLiquidityRate;

		uint256 newLiquidityIndex = liquidityIndex;
		uint256 newVariableBorrowIndex = variableBorrowIndex;

		//only cumulating if there is any income being produced
		if (currentLiquidityRate > 0) {
			uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
			newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
			require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

			reserve.liquidityIndex = uint128(newLiquidityIndex);

			//as the liquidity rate might come only from stable rate loans, we need to ensure
			//that there is actual variable debt before accumulating
			if (scaledVariableDebt != 0) {
				uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
					reserve.currentVariableBorrowRate,
					timestamp
				);
				newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
				require(newVariableBorrowIndex <= type(uint128).max, Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW);
				reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
			}
		}

		//solium-disable-next-line
		reserve.lastUpdateTimestamp = uint40(block.timestamp);
		return (newLiquidityIndex, newVariableBorrowIndex);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title GenericLogic library
 * @author Aave
 * @title Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
	using ReserveLogic for DataTypes.ReserveData;
	using SafeMath for uint256;
	using WadRayMath for uint256;
	using PercentageMath for uint256;
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using UserConfiguration for DataTypes.UserConfigurationMap;

	uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

	struct balanceDecreaseAllowedLocalVars {
		uint256 decimals;
		uint256 liquidationThreshold;
		uint256 totalCollateralInETH;
		uint256 totalDebtInETH;
		uint256 avgLiquidationThreshold;
		uint256 amountToDecreaseInETH;
		uint256 collateralBalanceAfterDecrease;
		uint256 liquidationThresholdAfterDecrease;
		uint256 healthFactorAfterDecrease;
		bool reserveUsageAsCollateralEnabled;
	}

	/**
	 * @dev Checks if a specific balance decrease is allowed
	 * (i.e. doesn't bring the user borrow position health factor under HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
	 * @param asset The address of the underlying asset of the reserve
	 * @param user The address of the user
	 * @param amount The amount to decrease
	 * @param reservesData The data of all the reserves
	 * @param userConfig The user configuration
	 * @param reserves The list of all the active reserves
	 * @param oracle The address of the oracle contract
	 * @return true if the decrease of the balance is allowed
	 **/
	function balanceDecreaseAllowed(
		address asset,
		address user,
		uint256 amount,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap calldata userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) external view returns (bool) {
		if (!userConfig.isBorrowingAny() || !userConfig.isUsingAsCollateral(reservesData[asset].id)) {
			return true;
		}

		balanceDecreaseAllowedLocalVars memory vars;

		(, vars.liquidationThreshold, , vars.decimals, ) = reservesData[asset].configuration.getParams();

		if (vars.liquidationThreshold == 0) {
			return true;
		}

		(vars.totalCollateralInETH, vars.totalDebtInETH, , vars.avgLiquidationThreshold, ) = calculateUserAccountData(
			user,
			reservesData,
			userConfig,
			reserves,
			reservesCount,
			oracle
		);

		if (vars.totalDebtInETH == 0) {
			return true;
		}

		vars.amountToDecreaseInETH = IPriceOracleGetter(oracle).getAssetPrice(asset).mul(amount).div(
			10 ** vars.decimals
		);

		vars.collateralBalanceAfterDecrease = vars.totalCollateralInETH.sub(vars.amountToDecreaseInETH);

		//if there is a borrow, there can't be 0 collateral
		if (vars.collateralBalanceAfterDecrease == 0) {
			return false;
		}

		vars.liquidationThresholdAfterDecrease = vars
			.totalCollateralInETH
			.mul(vars.avgLiquidationThreshold)
			.sub(vars.amountToDecreaseInETH.mul(vars.liquidationThreshold))
			.div(vars.collateralBalanceAfterDecrease);

		uint256 healthFactorAfterDecrease = calculateHealthFactorFromBalances(
			vars.collateralBalanceAfterDecrease,
			vars.totalDebtInETH,
			vars.liquidationThresholdAfterDecrease
		);

		return healthFactorAfterDecrease >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
	}

	struct CalculateUserAccountDataVars {
		uint256 reserveUnitPrice;
		uint256 tokenUnit;
		uint256 compoundedLiquidityBalance;
		uint256 compoundedBorrowBalance;
		uint256 decimals;
		uint256 ltv;
		uint256 liquidationThreshold;
		uint256 i;
		uint256 healthFactor;
		uint256 totalCollateralInETH;
		uint256 totalDebtInETH;
		uint256 avgLtv;
		uint256 avgLiquidationThreshold;
		uint256 reservesLength;
		bool healthFactorBelowThreshold;
		address currentReserveAddress;
		bool usageAsCollateralEnabled;
		bool userUsesReserveAsCollateral;
	}

	/**
	 * @dev Calculates the user data across the reserves.
	 * this includes the total liquidity/collateral/borrow balances in ETH,
	 * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
	 * @param user The address of the user
	 * @param reservesData Data of all the reserves
	 * @param userConfig The configuration of the user
	 * @param reserves The list of the available reserves
	 * @param oracle The price oracle address
	 * @return The total collateral and total debt of the user in ETH, the avg ltv, liquidation threshold and the HF
	 **/
	function calculateUserAccountData(
		address user,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap memory userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) internal view returns (uint256, uint256, uint256, uint256, uint256) {
		CalculateUserAccountDataVars memory vars;

		if (userConfig.isEmpty()) {
			return (0, 0, 0, 0, type(uint256).max);
		}
		for (vars.i = 0; vars.i < reservesCount; vars.i++) {
			if (!userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
				continue;
			}

			vars.currentReserveAddress = reserves[vars.i];
			DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

			(vars.ltv, vars.liquidationThreshold, , vars.decimals, ) = currentReserve.configuration.getParams();

			vars.tokenUnit = 10 ** vars.decimals;
			vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(vars.currentReserveAddress);

			if (vars.liquidationThreshold != 0 && userConfig.isUsingAsCollateral(vars.i)) {
				vars.compoundedLiquidityBalance = IERC20(currentReserve.aTokenAddress).balanceOf(user);

				uint256 liquidityBalanceETH = vars.reserveUnitPrice.mul(vars.compoundedLiquidityBalance).div(
					vars.tokenUnit
				);

				vars.totalCollateralInETH = vars.totalCollateralInETH.add(liquidityBalanceETH);

				vars.avgLtv = vars.avgLtv.add(liquidityBalanceETH.mul(vars.ltv));
				vars.avgLiquidationThreshold = vars.avgLiquidationThreshold.add(
					liquidityBalanceETH.mul(vars.liquidationThreshold)
				);
			}

			if (userConfig.isBorrowing(vars.i)) {
				vars.compoundedBorrowBalance = IERC20(currentReserve.stableDebtTokenAddress).balanceOf(user);
				vars.compoundedBorrowBalance = vars.compoundedBorrowBalance.add(
					IERC20(currentReserve.variableDebtTokenAddress).balanceOf(user)
				);

				vars.totalDebtInETH = vars.totalDebtInETH.add(
					vars.reserveUnitPrice.mul(vars.compoundedBorrowBalance).div(vars.tokenUnit)
				);
			}
		}

		vars.avgLtv = vars.totalCollateralInETH > 0 ? vars.avgLtv.div(vars.totalCollateralInETH) : 0;
		vars.avgLiquidationThreshold = vars.totalCollateralInETH > 0
			? vars.avgLiquidationThreshold.div(vars.totalCollateralInETH)
			: 0;

		vars.healthFactor = calculateHealthFactorFromBalances(
			vars.totalCollateralInETH,
			vars.totalDebtInETH,
			vars.avgLiquidationThreshold
		);
		return (
			vars.totalCollateralInETH,
			vars.totalDebtInETH,
			vars.avgLtv,
			vars.avgLiquidationThreshold,
			vars.healthFactor
		);
	}

	/**
	 * @dev Calculates the health factor from the corresponding balances
	 * @param totalCollateralInETH The total collateral in ETH
	 * @param totalDebtInETH The total debt in ETH
	 * @param liquidationThreshold The avg liquidation threshold
	 * @return The health factor calculated from the balances provided
	 **/
	function calculateHealthFactorFromBalances(
		uint256 totalCollateralInETH,
		uint256 totalDebtInETH,
		uint256 liquidationThreshold
	) internal pure returns (uint256) {
		if (totalDebtInETH == 0) return type(uint256).max;

		return (totalCollateralInETH.percentMul(liquidationThreshold)).wadDiv(totalDebtInETH);
	}

	/**
	 * @dev Calculates the equivalent amount in ETH that an user can borrow, depending on the available collateral and the
	 * average Loan To Value
	 * @param totalCollateralInETH The total collateral in ETH
	 * @param totalDebtInETH The total borrow balance
	 * @param ltv The average loan to value
	 * @return the amount available to borrow in ETH for the user
	 **/

	function calculateAvailableBorrowsETH(
		uint256 totalCollateralInETH,
		uint256 totalDebtInETH,
		uint256 ltv
	) internal pure returns (uint256) {
		uint256 availableBorrowsETH = totalCollateralInETH.percentMul(ltv);

		if (availableBorrowsETH < totalDebtInETH) {
			return 0;
		}

		availableBorrowsETH = availableBorrowsETH.sub(totalDebtInETH);
		return availableBorrowsETH;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {StableDebtToken} from "../../tokenization/StableDebtToken.sol";

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
	using ReserveLogic for DataTypes.ReserveData;
	using SafeMath for uint256;
	using WadRayMath for uint256;
	using PercentageMath for uint256;
	using SafeERC20 for IERC20;
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using UserConfiguration for DataTypes.UserConfigurationMap;

	uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
	uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

	/**
	 * @dev Validates a deposit action
	 * @param reserve The reserve object on which the user is depositing
	 * @param amount The amount to be deposited
	 */
	function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
		(bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

		require(amount != 0, Errors.VL_INVALID_AMOUNT);
		require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
		require(!isFrozen, Errors.VL_RESERVE_FROZEN);
	}

	/**
	 * @dev Validates the supply cap of a deposit action
	 * NOTE: This validation is excluded from the general `validateDeposit()` to ensure the reserve
	 * update state has already been executed.
	 * @custom:borrow-and-supply-caps
	 */
	function validateSupplyCap(DataTypes.ReserveData storage reserve, uint256 amount) external view {
		uint256 supplyCap = reserve.configuration.getSupplyCap() * (10 ** reserve.configuration.getDecimals());
		require(
			// Computing token.totalSupply() for aToken using index directly to save gas cost
			supplyCap == 0 ||
				((IScaledBalanceToken(reserve.aTokenAddress).scaledTotalSupply()).rayMul(reserve.liquidityIndex) +
					amount) <=
				supplyCap,
			Errors.SUPPLY_CAP_EXCEEDED
		);
	}

	/**
	 * @dev Validates a withdraw action
	 * @param reserveAddress The address of the reserve
	 * @param amount The amount to be withdrawn
	 * @param userBalance The balance of the user
	 * @param reservesData The reserves state
	 * @param userConfig The user configuration
	 * @param reserves The addresses of the reserves
	 * @param reservesCount The number of reserves
	 * @param oracle The price oracle
	 */
	function validateWithdraw(
		address reserveAddress,
		uint256 amount,
		uint256 userBalance,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap storage userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) external view {
		require(amount != 0, Errors.VL_INVALID_AMOUNT);
		require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

		(bool isActive, , , ) = reservesData[reserveAddress].configuration.getFlags();
		require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

		require(
			GenericLogic.balanceDecreaseAllowed(
				reserveAddress,
				msg.sender,
				amount,
				reservesData,
				userConfig,
				reserves,
				reservesCount,
				oracle
			),
			Errors.VL_TRANSFER_NOT_ALLOWED
		);
	}

	struct ValidateBorrowLocalVars {
		uint256 currentLtv;
		uint256 currentLiquidationThreshold;
		uint256 amountOfCollateralNeededETH;
		uint256 userCollateralBalanceETH;
		uint256 userBorrowBalanceETH;
		uint256 availableLiquidity;
		uint256 healthFactor;
		bool isActive;
		bool isFrozen;
		bool borrowingEnabled;
		bool stableRateBorrowingEnabled;
	}

	/**
	 * @dev Validates a borrow action
	 * @param asset The address of the asset to borrow
	 * @param reserve The reserve state from which the user is borrowing
	 * @param userAddress The address of the user
	 * @param amount The amount to be borrowed
	 * @param amountInETH The amount to be borrowed, in ETH
	 * @param interestRateMode The interest rate mode at which the user is borrowing
	 * @param maxStableLoanPercent The max amount of the liquidity that can be borrowed at stable rate, in percentage
	 * @param reservesData The state of all the reserves
	 * @param userConfig The state of the user for the specific reserve
	 * @param reserves The addresses of all the active reserves
	 * @param oracle The price oracle
	 */

	function validateBorrow(
		address asset,
		DataTypes.ReserveData storage reserve,
		address userAddress,
		uint256 amount,
		uint256 amountInETH,
		uint256 interestRateMode,
		uint256 maxStableLoanPercent,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap storage userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) external view {
		ValidateBorrowLocalVars memory vars;

		(vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.stableRateBorrowingEnabled) = reserve
			.configuration
			.getFlags();

		require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
		require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
		require(amount != 0, Errors.VL_INVALID_AMOUNT);

		require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

		//validate interest rate mode
		require(
			uint256(DataTypes.InterestRateMode.VARIABLE) == interestRateMode ||
				uint256(DataTypes.InterestRateMode.STABLE) == interestRateMode,
			Errors.VL_INVALID_INTEREST_RATE_MODE_SELECTED
		);

		(
			vars.userCollateralBalanceETH,
			vars.userBorrowBalanceETH,
			vars.currentLtv,
			vars.currentLiquidationThreshold,
			vars.healthFactor
		) = GenericLogic.calculateUserAccountData(
			userAddress,
			reservesData,
			userConfig,
			reserves,
			reservesCount,
			oracle
		);

		require(vars.userCollateralBalanceETH > 0, Errors.VL_COLLATERAL_BALANCE_IS_0);

		require(
			vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
			Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
		);

		//add the current already borrowed amount to the amount requested to calculate the total collateral needed.
		vars.amountOfCollateralNeededETH = vars.userBorrowBalanceETH.add(amountInETH).percentDiv(vars.currentLtv); //LTV is calculated in percentage

		require(
			vars.amountOfCollateralNeededETH <= vars.userCollateralBalanceETH,
			Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
		);

		/**
		 * Following conditions need to be met if the user is borrowing at a stable rate:
		 * 1. Reserve must be enabled for stable rate borrowing
		 * 2. Users cannot borrow from the reserve if their collateral is (mostly) the same currency
		 *    they are borrowing, to prevent abuses.
		 * 3. Users will be able to borrow only a portion of the total available liquidity
		 **/

		if (interestRateMode == uint256(DataTypes.InterestRateMode.STABLE)) {
			//check if the borrow mode is stable and if stable rate borrowing is enabled on this reserve

			require(vars.stableRateBorrowingEnabled, Errors.VL_STABLE_BORROWING_NOT_ENABLED);

			require(
				!userConfig.isUsingAsCollateral(reserve.id) ||
					reserve.configuration.getLtv() == 0 ||
					amount > IERC20(reserve.aTokenAddress).balanceOf(userAddress),
				Errors.VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY
			);

			vars.availableLiquidity = IERC20(asset).balanceOf(reserve.aTokenAddress);

			//calculate the max available loan size in stable rate mode as a percentage of the
			//available liquidity
			uint256 maxLoanSizeStable = vars.availableLiquidity.percentMul(maxStableLoanPercent);

			require(amount <= maxLoanSizeStable, Errors.VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE);
		}
	}

	/**
	 * @dev Validates the borrow cap of a borrow action
	 * NOTE: This validation is excluded from the general `validateBorrow()` to ensure the reserve
	 * update state has already been executed.
	 * @custom:borrow-and-supply-caps
	 */
	function validateBorrowCap(DataTypes.ReserveData storage reserve, uint256 amount) external view {
		uint256 borrowCap = reserve.configuration.getBorrowCap() * (10 ** reserve.configuration.getDecimals());
		if (borrowCap != 0) {
			// Computing token.totalSupply() for variable debt using index directly to save gas cost
			uint256 variableDebt = (IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledTotalSupply()).rayMul(
				reserve.variableBorrowIndex
			);
			// Stable token.totalSupply() method computes accumulated debt from average stable rate not available in reserve data.
			uint256 stableDebt = StableDebtToken(reserve.stableDebtTokenAddress).totalSupply();
			uint256 totalDebt = variableDebt + stableDebt + amount;
			require(totalDebt <= borrowCap, Errors.BORROW_CAP_EXCEEDED);
		}
	}

	/**
	 * @dev Validates a repay action
	 * @param reserve The reserve state from which the user is repaying
	 * @param amountSent The amount sent for the repayment. Can be an actual value or uint256(-1)
	 * @param onBehalfOf The address of the user msg.sender is repaying for
	 * @param stableDebt The borrow balance of the user
	 * @param variableDebt The borrow balance of the user
	 */
	function validateRepay(
		DataTypes.ReserveData storage reserve,
		uint256 amountSent,
		DataTypes.InterestRateMode rateMode,
		address onBehalfOf,
		uint256 stableDebt,
		uint256 variableDebt
	) external view {
		bool isActive = reserve.configuration.getActive();

		require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

		require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

		require(
			(stableDebt > 0 && DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.STABLE) ||
				(variableDebt > 0 && DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.VARIABLE),
			Errors.VL_NO_DEBT_OF_SELECTED_TYPE
		);

		require(
			amountSent != type(uint256).max || msg.sender == onBehalfOf,
			Errors.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
		);
	}

	/**
	 * @dev Validates a swap of borrow rate mode.
	 * @param reserve The reserve state on which the user is swapping the rate
	 * @param userConfig The user reserves configuration
	 * @param stableDebt The stable debt of the user
	 * @param variableDebt The variable debt of the user
	 * @param currentRateMode The rate mode of the borrow
	 */
	function validateSwapRateMode(
		DataTypes.ReserveData storage reserve,
		DataTypes.UserConfigurationMap storage userConfig,
		uint256 stableDebt,
		uint256 variableDebt,
		DataTypes.InterestRateMode currentRateMode
	) external view {
		(bool isActive, bool isFrozen, , bool stableRateEnabled) = reserve.configuration.getFlags();

		require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
		require(!isFrozen, Errors.VL_RESERVE_FROZEN);

		if (currentRateMode == DataTypes.InterestRateMode.STABLE) {
			require(stableDebt > 0, Errors.VL_NO_STABLE_RATE_LOAN_IN_RESERVE);
		} else if (currentRateMode == DataTypes.InterestRateMode.VARIABLE) {
			require(variableDebt > 0, Errors.VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE);
			/**
			 * user wants to swap to stable, before swapping we need to ensure that
			 * 1. stable borrow rate is enabled on the reserve
			 * 2. user is not trying to abuse the reserve by depositing
			 * more collateral than he is borrowing, artificially lowering
			 * the interest rate, borrowing at variable, and switching to stable
			 **/
			require(stableRateEnabled, Errors.VL_STABLE_BORROWING_NOT_ENABLED);

			require(
				!userConfig.isUsingAsCollateral(reserve.id) ||
					reserve.configuration.getLtv() == 0 ||
					stableDebt.add(variableDebt) > IERC20(reserve.aTokenAddress).balanceOf(msg.sender),
				Errors.VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY
			);
		} else {
			revert(Errors.VL_INVALID_INTEREST_RATE_MODE_SELECTED);
		}
	}

	/**
	 * @dev Validates a stable borrow rate rebalance action
	 * @param reserve The reserve state on which the user is getting rebalanced
	 * @param reserveAddress The address of the reserve
	 * @param stableDebtToken The stable debt token instance
	 * @param variableDebtToken The variable debt token instance
	 * @param aTokenAddress The address of the aToken contract
	 */
	function validateRebalanceStableBorrowRate(
		DataTypes.ReserveData storage reserve,
		address reserveAddress,
		IERC20 stableDebtToken,
		IERC20 variableDebtToken,
		address aTokenAddress
	) external view {
		(bool isActive, , , ) = reserve.configuration.getFlags();

		require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

		//if the usage ratio is below 95%, no rebalances are needed
		uint256 totalDebt = stableDebtToken.totalSupply().add(variableDebtToken.totalSupply()).wadToRay();
		uint256 availableLiquidity = IERC20(reserveAddress).balanceOf(aTokenAddress).wadToRay();
		uint256 usageRatio = totalDebt == 0 ? 0 : totalDebt.rayDiv(availableLiquidity.add(totalDebt));

		//if the liquidity rate is below REBALANCE_UP_THRESHOLD of the max variable APR at 95% usage,
		//then we allow rebalancing of the stable rate positions.

		uint256 currentLiquidityRate = reserve.currentLiquidityRate;
		uint256 maxVariableBorrowRate = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
			.getMaxVariableBorrowRate();

		require(
			usageRatio >= REBALANCE_UP_USAGE_RATIO_THRESHOLD &&
				currentLiquidityRate <= maxVariableBorrowRate.percentMul(REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD),
			Errors.LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
		);
	}

	/**
	 * @dev Validates the action of setting an asset as collateral
	 * @param reserve The state of the reserve that the user is enabling or disabling as collateral
	 * @param reserveAddress The address of the reserve
	 * @param reservesData The data of all the reserves
	 * @param userConfig The state of the user for the specific reserve
	 * @param reserves The addresses of all the active reserves
	 * @param oracle The price oracle
	 */
	function validateSetUseReserveAsCollateral(
		DataTypes.ReserveData storage reserve,
		address reserveAddress,
		bool useAsCollateral,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap storage userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) external view {
		uint256 underlyingBalance = IERC20(reserve.aTokenAddress).balanceOf(msg.sender);

		require(underlyingBalance > 0, Errors.VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0);

		require(
			useAsCollateral ||
				GenericLogic.balanceDecreaseAllowed(
					reserveAddress,
					msg.sender,
					underlyingBalance,
					reservesData,
					userConfig,
					reserves,
					reservesCount,
					oracle
				),
			Errors.VL_DEPOSIT_ALREADY_IN_USE
		);
	}

	/**
	 * @dev Validates a flashloan action
	 * @param assets The assets being flashborrowed
	 * @param amounts The amounts for each asset being borrowed
	 **/
	function validateFlashloan(address[] memory assets, uint256[] memory amounts) internal pure {
		require(assets.length == amounts.length, Errors.VL_INCONSISTENT_FLASHLOAN_PARAMS);
	}

	/**
	 * @dev Validates the liquidation action
	 * @param collateralReserve The reserve data of the collateral
	 * @param principalReserve The reserve data of the principal
	 * @param userConfig The user configuration
	 * @param userHealthFactor The user's health factor
	 * @param userStableDebt Total stable debt balance of the user
	 * @param userVariableDebt Total variable debt balance of the user
	 **/
	function validateLiquidationCall(
		DataTypes.ReserveData storage collateralReserve,
		DataTypes.ReserveData storage principalReserve,
		DataTypes.UserConfigurationMap storage userConfig,
		uint256 userHealthFactor,
		uint256 userStableDebt,
		uint256 userVariableDebt
	) internal view returns (uint256, string memory) {
		if (!collateralReserve.configuration.getActive() || !principalReserve.configuration.getActive()) {
			return (uint256(Errors.CollateralManagerErrors.NO_ACTIVE_RESERVE), Errors.VL_NO_ACTIVE_RESERVE);
		}

		if (userHealthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
			return (
				uint256(Errors.CollateralManagerErrors.HEALTH_FACTOR_ABOVE_THRESHOLD),
				Errors.LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
			);
		}

		bool isCollateralEnabled = collateralReserve.configuration.getLiquidationThreshold() > 0 &&
			userConfig.isUsingAsCollateral(collateralReserve.id);

		//if collateral isn't enabled as collateral by user, it cannot be liquidated
		if (!isCollateralEnabled) {
			return (
				uint256(Errors.CollateralManagerErrors.COLLATERAL_CANNOT_BE_LIQUIDATED),
				Errors.LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED
			);
		}

		if (userStableDebt == 0 && userVariableDebt == 0) {
			return (
				uint256(Errors.CollateralManagerErrors.CURRRENCY_NOT_BORROWED),
				Errors.LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
			);
		}

		return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.LPCM_NO_ERRORS);
	}

	/**
	 * @dev Validates an aToken transfer
	 * @param from The user from which the aTokens are being transferred
	 * @param reservesData The state of all the reserves
	 * @param userConfig The state of the user for the specific reserve
	 * @param reserves The addresses of all the active reserves
	 * @param oracle The price oracle
	 */
	function validateTransfer(
		address from,
		mapping(address => DataTypes.ReserveData) storage reservesData,
		DataTypes.UserConfigurationMap storage userConfig,
		mapping(uint256 => address) storage reserves,
		uint256 reservesCount,
		address oracle
	) internal view {
		(, , , , uint256 healthFactor) = GenericLogic.calculateUserAccountData(
			from,
			reservesData,
			userConfig,
			reserves,
			reservesCount,
			oracle
		);

		require(healthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.VL_TRANSFER_NOT_ALLOWED);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import { UserConfiguration } from "@radiant-v2-core/lending/libraries/configuration/UserConfiguration.sol";
import { ReserveConfiguration } from "@radiant-v2-core/lending/libraries/configuration/ReserveConfiguration.sol";
import { ReserveLogic } from "@radiant-v2-core/lending/libraries/logic/ReserveLogic.sol";
import { IRizLendingPoolAddressesProvider } from "../interfaces/Riz/IRizLendingPoolAddressesProvider.sol";
import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";

contract RizLendingPoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IRizLendingPoolAddressesProvider internal _addressesProvider;

    mapping(address => DataTypes.ReserveData) internal _reserves;
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => address) internal _reservesList;

    uint256 internal _reservesCount;

    bool internal _paused;

    bool internal _shutdown;

    uint256 internal _maxStableRateBorrowSizePercent;

    ///@dev FlashLoan premium state variable kept but not used: May-2024
    uint256 internal _flashLoanPremiumTotal;

    uint256 internal _maxNumberOfReserves;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { IOracleRouter } from "./interfaces/IOracleRouter.sol";
import { Errors } from "./libraries/Errors.sol";
import { IAggregatorV2V3 } from "./interfaces/IAggregatorV2V3.sol";
import { IPyth } from "./interfaces/IPyth.sol";
import { PythStructs } from "./interfaces/PythStructs.sol";

contract OracleRouter is Ownable, IOracleRouter {
    struct PriceFeedData {
        /// required by Chainlink
        address feedAddress;
        /// required by Pyth and API3
        bytes32 feedId;
        uint256 heartbeat;
        OracleProviderType oracleProviderType;
        bool isSet;
    }

    struct OracleProvider {
        address oracleProviderAddress;
        function(PriceFeedData memory) view returns (bool, uint256) getPrice;
    }

    //////////////// <*_*> Storage <*_*> ////////////////
    mapping(address => PriceFeedData) public feeds;
    mapping(address => PriceFeedData) public fallbackFeeds;
    mapping(IOracleRouter.OracleProviderType => OracleProvider) private oracleProviders;

    uint256 public constant BASE_CURRENCY_UNIT = 1e18;

    ////////////////// =^..^= Events =^..^= //////////////////
    event FeedUpdated(address asset, address feedAddress, bytes32 feedId, uint256 heartbeat);
    event FallbackFeedUpdated(address asset, address feedAddress, bytes32 feedId, uint256 heartbeat);
    event PricesUpdated();

    constructor(address _pyth) Ownable() {
        oracleProviders[OracleProviderType.Chainlink] = OracleProvider(address(0x0), _getChainlinkPrice);
        oracleProviders[OracleProviderType.Pyth] = OracleProvider(_pyth, _getPythPrice);
    }

    ////////////////// ô¿ô External and Public Functions ô¿ô //////////////////
    receive() external payable { }

    /// @notice Get the price of an asset
    /// @param asset The address of the asset
    function getAssetPrice(address asset) public view override returns (uint256) {
        PriceFeedData memory feed = feeds[address(asset)];

        if (!feed.isSet) {
            revert Errors.NoFeedSet();
        }

        bool success;
        uint256 price;
        (success, price) = oracleProviders[feed.oracleProviderType].getPrice(feed);
        // If the price is not available, try the fallback feed
        if (!success) {
            feed = fallbackFeeds[address(asset)];
            // If there is no fallback feed, revert
            if (!feed.isSet) {
                revert Errors.NoFallbackFeedSet();
            }
            (success, price) = oracleProviders[feed.oracleProviderType].getPrice(feed);
            // If the price is not available from the fallback feed, revert
            if (!success) {
                revert Errors.NoPriceAvailable();
            }
        }
        // Price cannot be 0
        if (price == 0) {
            revert Errors.NoPriceAvailable();
        }
        return price;
    }

    /// @notice Get the prices of multiple assets
    /// @param assets The addresses of the assets
    /// @return uint256[] The prices of the assets
    function getAssetsPrices(address[] calldata assets) external view override returns (uint256[] memory) {
        uint256 length = assets.length;
        uint256[] memory prices = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            prices[i] = getAssetPrice(assets[i]);
            unchecked {
                i++;
            }
        }
        return prices;
    }

    /// @notice Get the source of an asset. Tries to get the primary feed, then the fallback feed address
    /// @notice If no feed is set, returns address(0)
    /// @param asset The address of the asset
    /// @return address The address of the feed
    function getSourceOfAsset(address asset) external view override returns (address) {
        PriceFeedData memory feed = feeds[address(asset)];
        if (feed.isSet) {
            return feed.feedAddress;
            // Check fallback feed if no primary feed is set
        } else {
            feed = fallbackFeeds[address(asset)];
            if (feed.isSet) {
                return feed.feedAddress;
            }
        }
        return address(0);
    }

    /// @notice Set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle, CL is 0, Pyth is 1 and so on
    /// @param isFallback True if the feed is a fallback
    function setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        IOracleRouter.OracleProviderType _oracleType,
        bool isFallback
    ) external override onlyOwner {
        _setAssetSource(_asset, _feedAddress, _feedId, _heartbeat, _oracleType, isFallback);
    }

    /**
     * @notice Updates multiple price feeds on Pyth oracle
     * @param priceUpdateData received from Pyth network and used to update the oracle
     */
    function updateUnderlyingPrices(bytes[] calldata priceUpdateData) external override {
        IPyth pyth = IPyth(oracleProviders[OracleProviderType.Pyth].oracleProviderAddress);
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{ value: fee }(priceUpdateData);

        emit PricesUpdated();
    }

    ////////////////// ô¿ô Internal Functions ô¿ô  //////////////////

    /// @notice Get the underlying price of an asset from a Chainlink aggregator
    /// @param feed The feed data
    /// @return bool True if the price is available, false if not
    /// @return uint256 The price of the asset
    function _getChainlinkPrice(PriceFeedData memory feed) internal view returns (bool, uint256) {
        IAggregatorV2V3 chainlinkAggregator = IAggregatorV2V3(feed.feedAddress);
        uint256 decimalDelta = uint256(18) - (chainlinkAggregator.decimals());
        (, int256 answer,, uint256 updatedAt,) = chainlinkAggregator.latestRoundData();
        return
            block.timestamp <= updatedAt + feed.heartbeat ? (true, uint256(answer) * (10 ** decimalDelta)) : (false, 0);
    }

    /// @notice return price of an asset from Pyth
    /// @param feed contains feedId required by Pyth
    /// @return bool True if the price is available, false if not
    /// @return uint256 The price of the asset scaled to 1e18
    function _getPythPrice(PriceFeedData memory feed) internal view returns (bool, uint256) {
        IPyth pyth = IPyth(oracleProviders[OracleProviderType.Pyth].oracleProviderAddress);

        PythStructs.Price memory priceData = pyth.getPriceUnsafe(feed.feedId);
        return block.timestamp <= priceData.publishTime + feed.heartbeat
            ? (true, uint256(int256(priceData.price)) * (10 ** (18 - SignedMath.abs(priceData.expo))))
            : (false, 0);
    }

    /// @notice Internal function to set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle
    /// @param isFallback True if the feed is a fallback
    function _setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        IOracleRouter.OracleProviderType _oracleType,
        bool isFallback
    ) internal {
        if (_oracleType == OracleProviderType.Chainlink) {
            if (_feedAddress == address(0)) {
                revert Errors.InvalidFeed();
            }
        } else if (_oracleType == OracleProviderType.Pyth) {
            if (_feedId == bytes32(0) && _feedAddress != address(0)) {
                revert Errors.InvalidFeed();
            }
        } else {
            revert Errors.InvalidOracleProviderType();
        }

        if (!isFallback) {
            feeds[_asset] = PriceFeedData(_feedAddress, _feedId, _heartbeat, _oracleType, true);
            emit FeedUpdated(_asset, _feedAddress, _feedId, _heartbeat);
        } else {
            fallbackFeeds[_asset] = PriceFeedData(_feedAddress, _feedId, _heartbeat, _oracleType, true);
            emit FallbackFeedUpdated(_asset, _feedAddress, _feedId, _heartbeat);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { DataTypes } from "@radiant-v2-core/lending/libraries/types/DataTypes.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Errors as RizErrors } from "../libraries/Errors.sol";
import { BadDebtManager } from "../BadDebtManager.sol";
import { RizAToken } from "../tokenization/RizAToken.sol";

/// @title EmergencyWithdraw library
/// @author Radiant
library EmergencyWithdraw {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Params {
        uint256 totalUserDepositsUSD;
        uint256 totalUserDebtsUSD;
        address[] reservesList;
        uint256 reservesCount;
        address badDebtManagerAddress;
    }

    uint256 public constant DEFAULT_DENOMINATOR = 1e18;
    uint256 public constant BIPS_HIGH_PRECISION_DIVISOR = 1_000_000_000;

    event EmergencyWithdrawal(address indexed user, uint256 usdAmountWithdrawn);

    /// @dev Emergency withdrawal
    function emergencyWithdraw(
        address owner,
        address to,
        Params memory params,
        mapping(address => DataTypes.ReserveData) storage reserves
    ) external {
        BadDebtManager badDebtManager = BadDebtManager(params.badDebtManagerAddress);
        // Check if user has already withdrawn
        if (badDebtManager.hasUserWithdrawn(owner)) {
            revert RizErrors.UserAlreadyWithdrawn();
        }
        // First, we need to calculate user's total USD allowance to withdraw which is:
        // Σ(userDepositTokenX, userDepositTokenY) ... - Σ(userDebtTokenX, userDebtTokenY) ...
        // To do this, we should iterate over all reserve tokens and calculate the total amount of
        // user's deposits and debts in USD
        uint256[] memory _cacheReserveRatios = new uint256[](params.reservesCount);
        for (uint256 i = 0; i < params.reservesCount; i++) {
            address reserveAddress = params.reservesList[i];
            DataTypes.ReserveData memory reserve = reserves[reserveAddress];
            uint256 userDeposit = IERC20(reserve.aTokenAddress).balanceOf(owner);
            // NOTE: For Riz markets stable debt tokens are not used, so we can safely ignore them
            uint256 userDebt = IERC20(reserve.variableDebtTokenAddress).balanceOf(owner);
            // Note that, to calculate USD values we take snapshotted prices from BadDebtManager
            uint256 reserveUSDPrice = badDebtManager.getAssetPrice(reserveAddress);
            params.totalUserDepositsUSD += userDeposit.mul(reserveUSDPrice).div(DEFAULT_DENOMINATOR);
            params.totalUserDebtsUSD += userDebt.mul(reserveUSDPrice).div(DEFAULT_DENOMINATOR);
            _cacheReserveRatios[i] = badDebtManager.getAssetRatio(reserveAddress);
        }
        // If user allowance is 0 or they are responsible for bad debt, we can't proceed with the emergency withdrawal
        if (params.totalUserDepositsUSD < params.totalUserDebtsUSD || params.totalUserDepositsUSD == 0) {
            revert RizErrors.UserAllowanceZero();
        }
        uint256 userAllowanceUSD = params.totalUserDepositsUSD - params.totalUserDebtsUSD;

        // Now, we got to find out the ratios between tokens user will receive. This can be obtained from
        // BadDebtManager,
        // as the ratios were calculated during the snapshot(bricking) the lending pool. Note, that ratios are
        // represented
        // in BPS, so we need to divide them by PRECISION_DIVISOR to get the actual USD amount user will receive by each
        // token
        uint256[] memory _userAllowances = new uint256[](params.reservesCount);
        for (uint256 i = 0; i < params.reservesCount; i++) {
            // User allowance should also be slashed by BDM.slashingRatio
            uint256 _userAllowanceSlashed =
                userAllowanceUSD.mul(badDebtManager.slashingRatio()).div(BIPS_HIGH_PRECISION_DIVISOR);
            _userAllowances[i] = _userAllowanceSlashed.mul(_cacheReserveRatios[i]).div(BIPS_HIGH_PRECISION_DIVISOR);
        }
        // User allowances are denominated in USD, so we need to convert them to the actual amount of tokens.
        // Note that we will take prices from bad debt manager as well, as they were calculated during the snapshot
        for (uint256 i = 0; i < params.reservesCount; i++) {
            address reserveAddress = params.reservesList[i];
            DataTypes.ReserveData memory reserve = reserves[reserveAddress];
            uint256 reserveUSDPrice = badDebtManager.getAssetPrice(reserveAddress);
            uint256 userAllowanceInReserve = _userAllowances[i].div(reserveUSDPrice).mul(DEFAULT_DENOMINATOR);
            RizAToken(reserve.aTokenAddress).emergencyWithdrawal(
                owner, to, userAllowanceInReserve, reserve.liquidityIndex
            );
        }
        // Set emergency withdrawal status for user
        badDebtManager.setEmergencyWithdrawal(owner);
        emit EmergencyWithdrawal(to, userAllowanceUSD);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title ILendingRateOracle interface
 * @notice Interface for the Aave borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
 **/

interface ILendingRateOracle {
	/**
    @dev returns the market borrow rate in ray
    **/
	function getMarketBorrowRate(address asset) external view returns (uint256);

	/**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
	function setMarketBorrowRate(address asset, uint256 rate) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Context} from "../../dependencies/openzeppelin/contracts/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) internal _balances;

	mapping(address => mapping(address => uint256)) private _allowances;
	uint256 internal _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	ILendingPool internal _pool;
	address internal _underlyingAsset;

	constructor(string memory name_, string memory symbol_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
	}

	/**
	 * @return The name of the token
	 **/
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @return The symbol of the token
	 **/
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @return The decimals of the token
	 **/
	function decimals() public view returns (uint8) {
		return _decimals;
	}

	/**
	 * @return The total supply of the token
	 **/
	function totalSupply() public view virtual returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @return The balance of the token
	 **/
	function balanceOf(address account) public view virtual returns (uint256) {
		return _balances[account];
	}

	/**
	 * @return Abstract function implemented by the child aToken/debtToken.
	 * Done this way in order to not break compatibility with previous versions of aTokens/debtTokens
	 **/
	function _getIncentivesController() internal view virtual returns (IAaveIncentivesController);

	/**
	 * @dev Executes a transfer of tokens from _msgSender() to recipient
	 * @param recipient The recipient of the tokens
	 * @param amount The amount of tokens being transferred
	 * @return `true` if the transfer succeeds, `false` otherwise
	 **/
	function transfer(address recipient, uint256 amount) public virtual returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		emit Transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev Returns the allowance of spender on the tokens owned by owner
	 * @param owner The owner of the tokens
	 * @param spender The user allowed to spend the owner's tokens
	 * @return The amount of owner's tokens spender is allowed to spend
	 **/
	function allowance(address owner, address spender) public view virtual returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev Allows `spender` to spend the tokens owned by _msgSender()
	 * @param spender The user allowed to spend _msgSender() tokens
	 * @return `true`
	 **/
	function approve(address spender, uint256 amount) public virtual returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
	 * @param sender The owner of the tokens
	 * @param recipient The recipient of the tokens
	 * @param amount The amount of tokens being transferred
	 * @return `true` if the transfer succeeds, `false` otherwise
	 **/
	function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
		);
		emit Transfer(sender, recipient, amount);
		return true;
	}

	/**
	 * @dev Increases the allowance of spender to spend _msgSender() tokens
	 * @param spender The user allowed to spend on behalf of _msgSender()
	 * @param addedValue The amount being added to the allowance
	 * @return `true`
	 **/
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	/**
	 * @dev Decreases the allowance of spender to spend _msgSender() tokens
	 * @param spender The user allowed to spend on behalf of _msgSender()
	 * @param subtractedValue The amount being subtracted to the allowance
	 * @return `true`
	 **/
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
		);
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

		if (address(_getIncentivesController()) != address(0)) {
			// uint256 currentTotalSupply = _totalSupply;
			_getIncentivesController().handleActionBefore(sender);
			if (sender != recipient) {
				_getIncentivesController().handleActionBefore(recipient);
			}
		}

		_balances[sender] = senderBalance;
		uint256 recipientBalance = _balances[recipient].add(amount);
		_balances[recipient] = recipientBalance;

		if (address(_getIncentivesController()) != address(0)) {
			uint256 currentTotalSupply = _totalSupply;
			_getIncentivesController().handleActionAfter(sender, _balances[sender], currentTotalSupply);
			if (sender != recipient) {
				_getIncentivesController().handleActionAfter(recipient, _balances[recipient], currentTotalSupply);
			}
		}
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		uint256 currentTotalSupply = _totalSupply.add(amount);
		uint256 accountBalance = _balances[account].add(amount);
		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionBefore(account);
		}
		_totalSupply = currentTotalSupply;
		_balances[account] = accountBalance;
		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionAfter(account, accountBalance, currentTotalSupply);
		}
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 currentTotalSupply = _totalSupply.sub(amount);
		uint256 accountBalance = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");

		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionBefore(account);
		}

		_totalSupply = currentTotalSupply;
		_balances[account] = accountBalance;

		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionAfter(account, accountBalance, currentTotalSupply);
		}
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _setName(string memory newName) internal {
		_name = newName;
	}

	function _setSymbol(string memory newSymbol) internal {
		_symbol = newSymbol;
	}

	function _setDecimals(uint8 newDecimals) internal {
		_decimals = newDecimals;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

	function getAssetPrice() external view returns (uint256) {
		ILendingPoolAddressesProvider provider = _pool.getAddressesProvider();
		address oracle = provider.getPriceOracle();
		return IPriceOracle(oracle).getAssetPrice(_underlyingAsset);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import {IFeeDistribution} from "./IMultiFeeDistribution.sol";

interface IMiddleFeeDistribution is IFeeDistribution {
	function forwardReward(address[] memory _rewardTokens) external;

	function getRdntTokenAddress() external view returns (address);

	function getMultiFeeDistributionAddress() external view returns (address);

	function operationExpenseRatio() external view returns (uint256);

	function operationExpenses() external view returns (address);

	function isRewardToken(address) external view returns (bool);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IScaledBalanceToken {
	/**
	 * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
	 * updated stored balance divided by the reserve's liquidity index at the moment of the update
	 * @param user The user whose balance is calculated
	 * @return The scaled balance of the user
	 **/
	function scaledBalanceOf(address user) external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the user and the scaled total supply.
	 * @param user The address of the user
	 * @return The scaled balance of the user
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

	/**
	 * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
	 * @return The scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol";

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks. The admin role is stored in an immutable, which
 * helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
	address immutable ADMIN;

	constructor(address _admin) {
		ADMIN = _admin;
	}

	modifier ifAdmin() {
		if (msg.sender == ADMIN) {
			_;
		} else {
			_fallback();
		}
	}

	/**
	 * @return _address The address of the proxy admin.
	 */
	function admin() external ifAdmin returns (address _address) {
		return ADMIN;
	}

	/**
	 * @return _address The address of the implementation.
	 */
	function implementation() external ifAdmin returns (address _address) {
		return _implementation();
	}

	/**
	 * @dev Upgrade the backing implementation of the proxy.
	 * Only the admin can call this function.
	 * @param newImplementation Address of the new implementation.
	 */
	function upgradeTo(address newImplementation) external ifAdmin {
		_upgradeTo(newImplementation);
	}

	/**
	 * @dev Upgrade the backing implementation of the proxy and call a function
	 * on the new implementation.
	 * This is useful to initialize the proxied contract.
	 * @param newImplementation Address of the new implementation.
	 * @param data Data to send as msg.data in the low level call.
	 * It should include the signature and the parameters of the function to be called, as described in
	 * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
	 */
	function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
		_upgradeTo(newImplementation);
		(bool success, ) = newImplementation.delegatecall(data);
		require(success);
	}

	/**
	 * @dev Only fall back when the sender is not the admin.
	 */
	function _willFallback() internal virtual override {
		require(msg.sender != ADMIN, "Cannot call fallback function from the proxy admin");
		super._willFallback();
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
	/**
	 * @dev Contract initializer.
	 * @param _logic Address of the initial implementation.
	 * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
	 * It should include the signature and the parameters of the function to be called, as described in
	 * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
	 * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
	 */
	function initialize(address _logic, bytes memory _data) public payable {
		require(_implementation() == address(0));
		assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
		_setImplementation(_logic);
		if (_data.length > 0) {
			(bool success, ) = _logic.delegatecall(_data);
			require(success);
		}
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Aave
 */
interface IReserveInterestRateStrategy {
	function baseVariableBorrowRate() external view returns (uint256);

	function getMaxVariableBorrowRate() external view returns (uint256);

	function calculateInterestRates(
		address reserve,
		uint256 availableLiquidity,
		uint256 totalStableDebt,
		uint256 totalVariableDebt,
		uint256 averageStableBorrowRate,
		uint256 reserveFactor
	) external view returns (uint256, uint256, uint256);

	function calculateInterestRates(
		address reserve,
		address aToken,
		uint256 liquidityAdded,
		uint256 liquidityTaken,
		uint256 totalStableDebt,
		uint256 totalVariableDebt,
		uint256 averageStableBorrowRate,
		uint256 reserveFactor
	) external view returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {WadRayMath} from "./WadRayMath.sol";

library MathUtils {
	using SafeMath for uint256;
	using WadRayMath for uint256;

	/// @dev Ignoring leap years
	uint256 internal constant SECONDS_PER_YEAR = 365 days;

	/**
	 * @dev Function to calculate the interest accumulated using a linear interest rate formula
	 * @param rate The interest rate, in ray
	 * @param lastUpdateTimestamp The timestamp of the last update of the interest
	 * @return The interest rate linearly accumulated during the timeDelta, in ray
	 **/

	function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
		//solium-disable-next-line
		uint256 timeDifference = block.timestamp.sub(uint256(lastUpdateTimestamp));

		return (rate.mul(timeDifference) / SECONDS_PER_YEAR).add(WadRayMath.ray());
	}

	/**
	 * @dev Function to calculate the interest using a compounded interest rate formula
	 * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
	 *
	 *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
	 *
	 * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
	 * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
	 *
	 * @param rate The interest rate, in ray
	 * @param lastUpdateTimestamp The timestamp of the last update of the interest
	 * @return The interest rate compounded during the timeDelta, in ray
	 **/
	function calculateCompoundedInterest(
		uint256 rate,
		uint40 lastUpdateTimestamp,
		uint256 currentTimestamp
	) internal pure returns (uint256) {
		//solium-disable-next-line
		uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

		if (exp == 0) {
			return WadRayMath.ray();
		}

		uint256 expMinusOne = exp - 1;

		uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

		uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

		uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
		uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

		uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
		uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

		return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
	}

	/**
	 * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
	 * @param rate The interest rate (in ray)
	 * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
	 **/
	function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
		return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title StableDebtToken
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @author Aave
 **/
contract StableDebtToken is IStableDebtToken, DebtTokenBase {
	using WadRayMath for uint256;
	using SafeMath for uint256;

	uint256 public constant DEBT_TOKEN_REVISION = 0x1;

	uint256 internal _avgStableRate;
	mapping(address => uint40) internal _timestamps;
	mapping(address => uint256) internal _usersStableRate;
	uint40 internal _totalSupplyTimestamp;

	IAaveIncentivesController internal _incentivesController;

	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev Initializes the debt token.
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
	 * @param debtTokenName The name of the token
	 * @param debtTokenSymbol The symbol of the token
	 */
	function initialize(
		ILendingPool pool,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 debtTokenDecimals,
		string memory debtTokenName,
		string memory debtTokenSymbol,
		bytes calldata params
	) public override initializer {
		_setName(debtTokenName);
		_setSymbol(debtTokenSymbol);
		_setDecimals(debtTokenDecimals);

		_pool = pool;
		_underlyingAsset = underlyingAsset;
		_incentivesController = incentivesController;

		emit Initialized(
			underlyingAsset,
			address(pool),
			address(incentivesController),
			debtTokenDecimals,
			debtTokenName,
			debtTokenSymbol,
			params
		);
	}

	/**
	 * @dev Gets the revision of the stable debt token implementation
	 * @return The debt token implementation revision
	 **/
	function getRevision() internal pure virtual override returns (uint256) {
		return DEBT_TOKEN_REVISION;
	}

	/**
	 * @dev Returns the average stable rate across all the stable rate debt
	 * @return the average stable rate
	 **/
	function getAverageStableRate() external view virtual override returns (uint256) {
		return _avgStableRate;
	}

	/**
	 * @dev Returns the timestamp of the last user action
	 * @return The last update timestamp
	 **/
	function getUserLastUpdated(address user) external view virtual override returns (uint40) {
		return _timestamps[user];
	}

	/**
	 * @dev Returns the stable rate of the user
	 * @param user The address of the user
	 * @return The stable rate of user
	 **/
	function getUserStableRate(address user) external view virtual override returns (uint256) {
		return _usersStableRate[user];
	}

	/**
	 * @dev Calculates the current user debt balance
	 * @return The accumulated debt of the user
	 **/
	function balanceOf(address account) public view virtual override returns (uint256) {
		uint256 accountBalance = super.balanceOf(account);
		uint256 stableRate = _usersStableRate[account];
		if (accountBalance == 0) {
			return 0;
		}
		uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(stableRate, _timestamps[account]);
		return accountBalance.rayMul(cumulatedInterest);
	}

	struct MintLocalVars {
		uint256 previousSupply;
		uint256 nextSupply;
		uint256 amountInRay;
		uint256 newStableRate;
		uint256 currentAvgStableRate;
	}

	/**
	 * @dev Mints debt token to the `onBehalfOf` address.
	 * -  Only callable by the LendingPool
	 * - The resulting rate is the weighted average between the rate of the new debt
	 * and the rate of the previous debt
	 * @param user The address receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The address receiving the debt tokens
	 * @param amount The amount of debt tokens to mint
	 * @param rate The rate of the debt being minted
	 **/
	function mint(
		address user,
		address onBehalfOf,
		uint256 amount,
		uint256 rate
	) external override onlyLendingPool returns (bool) {
		MintLocalVars memory vars;

		if (user != onBehalfOf) {
			_decreaseBorrowAllowance(onBehalfOf, user, amount);
		}

		(, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(onBehalfOf);

		vars.previousSupply = totalSupply();
		vars.currentAvgStableRate = _avgStableRate;
		vars.nextSupply = _totalSupply = vars.previousSupply.add(amount);

		vars.amountInRay = amount.wadToRay();

		vars.newStableRate = _usersStableRate[onBehalfOf]
			.rayMul(currentBalance.wadToRay())
			.add(vars.amountInRay.rayMul(rate))
			.rayDiv(currentBalance.add(amount).wadToRay());

		require(vars.newStableRate <= type(uint128).max, Errors.SDT_STABLE_DEBT_OVERFLOW);
		_usersStableRate[onBehalfOf] = vars.newStableRate;

		//solium-disable-next-line
		_totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(block.timestamp);

		// Calculates the updated average stable rate
		vars.currentAvgStableRate = _avgStableRate = vars
			.currentAvgStableRate
			.rayMul(vars.previousSupply.wadToRay())
			.add(rate.rayMul(vars.amountInRay))
			.rayDiv(vars.nextSupply.wadToRay());

		_mint(onBehalfOf, amount.add(balanceIncrease), vars.previousSupply);

		emit Transfer(address(0), onBehalfOf, amount);

		emit Mint(
			user,
			onBehalfOf,
			amount,
			currentBalance,
			balanceIncrease,
			vars.newStableRate,
			vars.currentAvgStableRate,
			vars.nextSupply
		);

		return currentBalance == 0;
	}

	/**
	 * @dev Burns debt of `user`
	 * @param user The address of the user getting his debt burned
	 * @param amount The amount of debt tokens getting burned
	 **/
	function burn(address user, uint256 amount) external override onlyLendingPool {
		(, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(user);

		uint256 previousSupply = totalSupply();
		uint256 newAvgStableRate = 0;
		uint256 nextSupply = 0;
		uint256 userStableRate = _usersStableRate[user];

		// Since the total supply and each single user debt accrue separately,
		// there might be accumulation errors so that the last borrower repaying
		// mght actually try to repay more than the available debt supply.
		// In this case we simply set the total supply and the avg stable rate to 0
		if (previousSupply <= amount) {
			_avgStableRate = 0;
			_totalSupply = 0;
		} else {
			nextSupply = _totalSupply = previousSupply.sub(amount);
			uint256 firstTerm = _avgStableRate.rayMul(previousSupply.wadToRay());
			uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

			// For the same reason described above, when the last user is repaying it might
			// happen that user rate * user balance > avg rate * total supply. In that case,
			// we simply set the avg rate to 0
			if (secondTerm >= firstTerm) {
				newAvgStableRate = _avgStableRate = _totalSupply = 0;
			} else {
				newAvgStableRate = _avgStableRate = firstTerm.sub(secondTerm).rayDiv(nextSupply.wadToRay());
			}
		}

		if (amount == currentBalance) {
			_usersStableRate[user] = 0;
			_timestamps[user] = 0;
		} else {
			//solium-disable-next-line
			_timestamps[user] = uint40(block.timestamp);
		}
		//solium-disable-next-line
		_totalSupplyTimestamp = uint40(block.timestamp);

		if (balanceIncrease > amount) {
			uint256 amountToMint = balanceIncrease.sub(amount);
			_mint(user, amountToMint, previousSupply);
			emit Mint(
				user,
				user,
				amountToMint,
				currentBalance,
				balanceIncrease,
				userStableRate,
				newAvgStableRate,
				nextSupply
			);
		} else {
			uint256 amountToBurn = amount.sub(balanceIncrease);
			_burn(user, amountToBurn, previousSupply);
			emit Burn(user, amountToBurn, currentBalance, balanceIncrease, newAvgStableRate, nextSupply);
		}

		emit Transfer(user, address(0), amount);
	}

	/**
	 * @dev Calculates the increase in balance since the last user interaction
	 * @param user The address of the user for which the interest is being accumulated
	 * @return The previous principal balance, the new principal balance and the balance increase
	 **/
	function _calculateBalanceIncrease(address user) internal view returns (uint256, uint256, uint256) {
		uint256 previousPrincipalBalance = super.balanceOf(user);

		if (previousPrincipalBalance == 0) {
			return (0, 0, 0);
		}

		// Calculation of the accrued interest since the last accumulation
		uint256 balanceIncrease = balanceOf(user).sub(previousPrincipalBalance);

		return (previousPrincipalBalance, previousPrincipalBalance.add(balanceIncrease), balanceIncrease);
	}

	/**
	 * @dev Returns the principal and total supply, the average borrow rate and the last supply update timestamp
	 **/
	function getSupplyData() public view override returns (uint256, uint256, uint256, uint40) {
		uint256 avgRate = _avgStableRate;
		return (super.totalSupply(), _calcTotalSupply(avgRate), avgRate, _totalSupplyTimestamp);
	}

	/**
	 * @dev Returns the the total supply and the average stable rate
	 **/
	function getTotalSupplyAndAvgRate() public view override returns (uint256, uint256) {
		uint256 avgRate = _avgStableRate;
		return (_calcTotalSupply(avgRate), avgRate);
	}

	/**
	 * @dev Returns the total supply
	 **/
	function totalSupply() public view override returns (uint256) {
		return _calcTotalSupply(_avgStableRate);
	}

	/**
	 * @dev Returns the timestamp at which the total supply was updated
	 **/
	function getTotalSupplyLastUpdated() public view override returns (uint40) {
		return _totalSupplyTimestamp;
	}

	/**
	 * @dev Returns the principal debt balance of the user from
	 * @param user The user's address
	 * @return The debt balance of the user since the last burn/mint action
	 **/
	function principalBalanceOf(address user) external view virtual override returns (uint256) {
		return super.balanceOf(user);
	}

	/**
	 * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 **/
	function UNDERLYING_ASSET_ADDRESS() public view returns (address) {
		return _underlyingAsset;
	}

	/**
	 * @dev Returns the address of the lending pool where this aToken is used
	 **/
	function POOL() public view returns (ILendingPool) {
		return _pool;
	}

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view override returns (IAaveIncentivesController) {
		return _getIncentivesController();
	}

	/**
	 * @dev For internal usage in the logic of the parent contracts
	 **/
	function _getIncentivesController() internal view override returns (IAaveIncentivesController) {
		return _incentivesController;
	}

	/**
	 * @dev For internal usage in the logic of the parent contracts
	 **/
	function _getUnderlyingAssetAddress() internal view override returns (address) {
		return _underlyingAsset;
	}

	/**
	 * @dev For internal usage in the logic of the parent contracts
	 **/
	function _getLendingPool() internal view override returns (ILendingPool) {
		return _pool;
	}

	/**
	 * @dev Calculates the total supply
	 * @param avgRate The average rate at which the total supply increases
	 * @return The debt balance of the user since the last burn/mint action
	 **/
	function _calcTotalSupply(uint256 avgRate) internal view virtual returns (uint256) {
		uint256 principalSupply = super.totalSupply();

		if (principalSupply == 0) {
			return 0;
		}

		uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(avgRate, _totalSupplyTimestamp);

		return principalSupply.rayMul(cumulatedInterest);
	}

	/**
	 * @dev Mints stable debt tokens to an user
	 * @param account The account receiving the debt tokens
	 * @param amount The amount being minted
	 * @param oldTotalSupply the total supply before the minting event
	 **/
	function _mint(address account, uint256 amount, uint256 oldTotalSupply) internal {
		uint256 oldAccountBalance = _balances[account];
		if (address(_incentivesController) != address(0)) {
			_incentivesController.handleActionBefore(account);
		}
		_balances[account] = oldAccountBalance.add(amount);
		if (address(_incentivesController) != address(0)) {
			_incentivesController.handleActionAfter(account, oldAccountBalance, oldTotalSupply);
		}
	}

	/**
	 * @dev Burns stable debt tokens of an user
	 * @param account The user getting his debt burned
	 * @param amount The amount being burned
	 * @param oldTotalSupply The total supply before the burning event
	 **/
	function _burn(address account, uint256 amount, uint256 oldTotalSupply) internal {
		uint256 oldAccountBalance = _balances[account];
		if (address(_incentivesController) != address(0)) {
			_incentivesController.handleActionBefore(account);
		}
		_balances[account] = oldAccountBalance.sub(amount, Errors.SDT_BURN_EXCEEDS_BALANCE);
		if (address(_incentivesController) != address(0)) {
			_incentivesController.handleActionAfter(account, oldAccountBalance, oldTotalSupply);
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@radiant-v2-core/interfaces/IPriceOracleGetter.sol";

interface IOracleRouter is IPriceOracleGetter {
    enum OracleProviderType {
        Chainlink,
        Pyth
    }
    // TODO: Add more oracle providers
    /**
     * @notice Get the underlying price of a kToken asset
     * @param asset to get the underlying price of
     * @return The underlying asset price
     *  Zero means the price is unavailable.
     */

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param assets The list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /// @notice Gets the address of the source for an asset address
    /// @param asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address asset) external view returns (address);

    /// @notice Set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle
    /// @param isFallback True if the feed is a fallback
    function setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        OracleProviderType _oracleType,
        bool isFallback
    ) external;

    /**
     * @notice Updates multiple price feeds on Pyth oracle
     * @param priceUpdateData received from Pyth network and used to update the oracle
     */
    function updateUnderlyingPrices(bytes[] calldata priceUpdateData) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface IAggregatorV2V3 {
    //
    // V2 Interface:
    //
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    //
    // V3 Interface:
    //
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices
/// safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint256 validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within
    /// `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint256 publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

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
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
	/***********
    @dev returns the asset price in ETH
     */
	function getAssetPrice(address asset) external view returns (uint256);

	/***********
    @dev sets the asset price, in wei
     */
	function setAssetPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
	function exit(bool claimRewards) external;

	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

	function rdntToken() external view returns (IMintableToken);

	function getPriceProvider() external view returns (address);

	function lockInfo(address user) external view returns (LockedBalance[] memory);

	function autocompoundDisabled(address user) external view returns (bool);

	function defaultLockIndex(address _user) external view returns (uint256);

	function autoRelockDisabled(address user) external view returns (bool);

	function totalBalance(address user) external view returns (uint256);

	function lockedBalance(address user) external view returns (uint256);

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);

	function getBalances(address _user) external view returns (Balances memory);

	function zapVestingToLp(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function userSlippage(address) external view returns (uint256);

	function claimFromConverter(address) external;

	function vestTokens(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 bountyAmt);

	function setAutocompound(bool state, uint256 slippage) external;

	function setUserSlippage(uint256 slippage) external;

	function toggleAutocompound() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
		//solium-disable-next-line
		assembly {
			impl := sload(slot)
		}
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

		//solium-disable-next-line
		assembly {
			sstore(slot, newImplementation)
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {ILendingPool} from "../../../interfaces/ILendingPool.sol";
import {ICreditDelegationToken} from "../../../interfaces/ICreditDelegationToken.sol";
import {VersionedInitializable} from "../../libraries/aave-upgradeability/VersionedInitializable.sol";
import {IncentivizedERC20} from "../IncentivizedERC20.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DebtTokenBase
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 * @author Aave
 */

abstract contract DebtTokenBase is
	IncentivizedERC20("DEBTTOKEN_IMPL", "DEBTTOKEN_IMPL", 0),
	VersionedInitializable,
	ICreditDelegationToken
{
	using SafeMath for uint256;

	mapping(address => mapping(address => uint256)) internal _borrowAllowances;

	/**
	 * @dev Only lending pool can call functions marked by this modifier
	 **/
	modifier onlyLendingPool() {
		require(_msgSender() == address(_getLendingPool()), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
		_;
	}

	/**
	 * @dev delegates borrowing power to a user on the specific debt token
	 * @param delegatee the address receiving the delegated borrowing power
	 * @param amount the maximum amount being delegated. Delegation will still
	 * respect the liquidation constraints (even if delegated, a delegatee cannot
	 * force a delegator HF to go below 1)
	 **/
	function approveDelegation(address delegatee, uint256 amount) external override {
		_borrowAllowances[_msgSender()][delegatee] = amount;
		emit BorrowAllowanceDelegated(_msgSender(), delegatee, _getUnderlyingAssetAddress(), amount);
	}

	/**
	 * @dev returns the borrow allowance of the user
	 * @param fromUser The user to giving allowance
	 * @param toUser The user to give allowance to
	 * @return the current allowance of toUser
	 **/
	function borrowAllowance(address fromUser, address toUser) external view override returns (uint256) {
		return _borrowAllowances[fromUser][toUser];
	}

	/**
	 * @dev Being non transferrable, the debt token does not implement any of the
	 * standard ERC20 functions for transfer and allowance.
	 **/
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		recipient;
		amount;
		revert("TRANSFER_NOT_SUPPORTED");
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		owner;
		spender;
		revert("ALLOWANCE_NOT_SUPPORTED");
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		spender;
		amount;
		revert("APPROVAL_NOT_SUPPORTED");
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		sender;
		recipient;
		amount;
		revert("TRANSFER_NOT_SUPPORTED");
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
		spender;
		addedValue;
		revert("ALLOWANCE_NOT_SUPPORTED");
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
		spender;
		subtractedValue;
		revert("ALLOWANCE_NOT_SUPPORTED");
	}

	function _decreaseBorrowAllowance(address delegator, address delegatee, uint256 amount) internal {
		uint256 newAllowance = _borrowAllowances[delegator][delegatee].sub(amount, Errors.BORROW_ALLOWANCE_NOT_ENOUGH);

		_borrowAllowances[delegator][delegatee] = newAllowance;

		emit BorrowAllowanceDelegated(delegator, delegatee, _getUnderlyingAssetAddress(), newAllowance);
	}

	function _getUnderlyingAssetAddress() internal view virtual returns (address);

	function _getLendingPool() internal view virtual returns (ILendingPool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function removeReward(address _rewardToken) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
	function mint(address _receiver, uint256 _amount) external returns (bool);

	function burn(uint256 _amount) external returns (bool);

	function setMinter(address _minter) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
	/**
	 * @dev Fallback function.
	 * Implemented entirely in `_fallback`.
	 */
	fallback() external payable {
		_fallback();
	}

	/**
	 * @return The Address of the implementation.
	 */
	function _implementation() internal view virtual returns (address);

	/**
	 * @dev Delegates execution to an implementation contract.
	 * This is a low level function that doesn't return to its internal call site.
	 * It will return to the external caller whatever the implementation returns.
	 * @param implementation Address to delegate.
	 */
	function _delegate(address implementation) internal {
		//solium-disable-next-line
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
	 * @dev Function that is run as the first thing in the fallback function.
	 * Can be redefined in derived contracts to add functionality.
	 * Redefinitions must call super._willFallback().
	 */
	function _willFallback() internal virtual {}

	/**
	 * @dev fallback implementation.
	 * Extracted to enable manual triggering.
	 */
	function _fallback() internal {
		_willFallback();
		_delegate(_implementation());
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface ICreditDelegationToken {
	event BorrowAllowanceDelegated(address indexed fromUser, address indexed toUser, address asset, uint256 amount);

	/**
	 * @dev delegates borrowing power to a user on the specific debt token
	 * @param delegatee the address receiving the delegated borrowing power
	 * @param amount the maximum amount being delegated. Delegation will still
	 * respect the liquidation constraints (even if delegated, a delegatee cannot
	 * force a delegator HF to go below 1)
	 **/
	function approveDelegation(address delegatee, uint256 amount) external;

	/**
	 * @dev returns the borrow allowance of the user
	 * @param fromUser The user to giving allowance
	 * @param toUser The user to give allowance to
	 * @return the current allowance of toUser
	 **/
	function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}