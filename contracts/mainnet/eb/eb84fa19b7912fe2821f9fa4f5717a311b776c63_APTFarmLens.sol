// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {
    IAPTFarmLens,
    IVaultFactory,
    IBaseVault,
    IStrategy,
    IAPTFarm,
    IRewarder,
    IJoeDexLens
} from "./interfaces/IAPTFarmLens.sol";

contract APTFarmLens is IAPTFarmLens {
    /**
     * @notice The vault factory contract
     */
    IVaultFactory public immutable override vaultFactory;

    /**
     * @notice The APT farm contract
     */
    IAPTFarm public immutable override aptFarm;

    /**
     * @notice The Joe Dex Lens contract
     */
    IJoeDexLens public immutable override dexLens;

    constructor(IVaultFactory _vaultFactory, IAPTFarm _aptFarm, IJoeDexLens _dexLens) {
        vaultFactory = _vaultFactory;
        aptFarm = _aptFarm;
        dexLens = _dexLens;
    }

    /**
     * @notice Returns data for every vault created by the vault factory
     * @return vaultsData The vault data array for every vault created by the vault factory
     */
    function getAllVaults() external view override returns (VaultData[] memory vaultsData) {
        vaultsData = _getAllVaults();
    }

    /**
     * @notice Returns paginated data for every vault created by the vault factory
     * @param vaultType The vault type
     * @param startId The start id
     * @param pageSize The amount of vaults to get
     * @return vaultsData The vault data array for every vault created by the vault factory
     */
    function getPaginatedVaultsFromType(IVaultFactory.VaultType vaultType, uint256 startId, uint256 pageSize)
        external
        view
        override
        returns (VaultData[] memory vaultsData)
    {
        vaultsData = _getVaults(vaultType, startId, pageSize);
    }

    /**
     * @notice Returns data for every vault that has a farm
     * @return farmsData The vault data array for every vault that has a farm
     */
    function getAllVaultsWithFarms() external view override returns (VaultData[] memory farmsData) {
        farmsData = _getAllVaultsWithFarms();
    }

    /**
     * @notice Returns paginated data for every vault that has a farm
     * @param startId The start id
     * @param pageSize The amount of vaults to get
     * @return farmsData The vault data array for every vault that has a farm
     */
    function getPaginatedVaultsWithFarms(uint256 startId, uint256 pageSize)
        external
        view
        override
        returns (VaultData[] memory farmsData)
    {
        farmsData = _getVaultsWithFarms(startId, pageSize);
    }

    /**
     * @notice Returns data for every vault created by the vault factory with the user's info
     * @param user The user's address
     * @return vaultsDataWithUserInfo The vault data array with the user's info
     */
    function getAllVaultsIncludingUserInfo(address user)
        external
        view
        override
        returns (VaultDataWithUserInfo[] memory vaultsDataWithUserInfo)
    {
        VaultData[] memory vaultsData = _getAllVaults();

        vaultsDataWithUserInfo = new VaultDataWithUserInfo[](vaultsData.length);

        for (uint256 i = 0; i < vaultsData.length; i++) {
            vaultsDataWithUserInfo[i] = _getVaultUserInfo(vaultsData[i], user);
        }
    }
    /**
     * @notice Returns paginated data for every vault created by the vault factory with the user's info
     * @param user The user's address
     * @param vaultType The vault type
     * @param startId The start id
     * @param pageSize The amount of vaults to get
     * @return vaultsDataWithUserInfo The vault data array with the user's info
     */

    function getPaginatedVaultsIncludingUserInfo(
        address user,
        IVaultFactory.VaultType vaultType,
        uint256 startId,
        uint256 pageSize
    ) external view override returns (VaultDataWithUserInfo[] memory vaultsDataWithUserInfo) {
        VaultData[] memory vaultsData = _getVaults(vaultType, startId, pageSize);

        vaultsDataWithUserInfo = new VaultDataWithUserInfo[](vaultsData.length);

        for (uint256 i = 0; i < vaultsData.length; i++) {
            vaultsDataWithUserInfo[i] = _getVaultUserInfo(vaultsData[i], user);
        }
    }

    /**
     * @notice Returns data for every vault that has a farm, with the user's info
     * @param user The user's address
     * @return farmsDataWithUserInfo The vault data array with the user's info
     */
    function getAllVaultsWithFarmsIncludingUserInfo(address user)
        external
        view
        override
        returns (VaultDataWithUserInfo[] memory farmsDataWithUserInfo)
    {
        VaultData[] memory farmsData = _getAllVaultsWithFarms();

        farmsDataWithUserInfo = new VaultDataWithUserInfo[](farmsData.length);

        for (uint256 i = 0; i < farmsData.length; i++) {
            farmsDataWithUserInfo[i] = _getVaultUserInfo(farmsData[i], user);
        }
    }

    /**
     * @notice Returns paginated data for every vault that has a farm, with the user's info
     * @param user The user's address
     * @param startId The start id
     * @param pageSize The amount of vaults to get
     * @return farmsDataWithUserInfo The vault data array with the user's info
     */
    function getPaginatedVaultsWithFarmsIncludingUserInfo(address user, uint256 startId, uint256 pageSize)
        external
        view
        override
        returns (VaultDataWithUserInfo[] memory farmsDataWithUserInfo)
    {
        VaultData[] memory farmsData = _getVaultsWithFarms(startId, pageSize);

        farmsDataWithUserInfo = new VaultDataWithUserInfo[](farmsData.length);

        for (uint256 i = 0; i < farmsData.length; i++) {
            farmsDataWithUserInfo[i] = _getVaultUserInfo(farmsData[i], user);
        }
    }

    /**
     * @dev Gets all the vaults created by the vault factory
     * @return vaultsData The vault data array
     */
    function _getAllVaults() internal view returns (VaultData[] memory vaultsData) {
        uint256 totalOracleVaults = vaultFactory.getNumberOfVaults(IVaultFactory.VaultType.Oracle);
        uint256 totalSimpleVaults = vaultFactory.getNumberOfVaults(IVaultFactory.VaultType.Simple);

        vaultsData = new VaultData[](totalOracleVaults + totalSimpleVaults);

        for (uint256 i = 0; i < totalOracleVaults; i++) {
            vaultsData[i] = _getVaultAt(IVaultFactory.VaultType.Oracle, i);
        }

        for (uint256 i = 0; i < totalSimpleVaults; i++) {
            vaultsData[totalOracleVaults + i] = _getVaultAt(IVaultFactory.VaultType.Simple, i);
        }
    }

    /**
     * @dev Gets all the vaults from the specified type created by the vault factory
     * @param vaultType The vault type
     * @param startId The start id
     * @param pageSize The amount of vaults to get
     * @return vaultsData The vault data array
     */
    function _getVaults(IVaultFactory.VaultType vaultType, uint256 startId, uint256 pageSize)
        internal
        view
        returns (VaultData[] memory vaultsData)
    {
        uint256 totalSimpleVaults = vaultFactory.getNumberOfVaults(vaultType);

        if (startId >= totalSimpleVaults) {
            return vaultsData;
        }

        if (startId + pageSize > totalSimpleVaults) {
            pageSize = totalSimpleVaults - startId;
        }

        vaultsData = new VaultData[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            vaultsData[i] = _getVaultAt(vaultType, startId + i);
        }
    }

    /**
     * @dev Gets all the vault of the specified type created at the specified index
     * @param vaultType The vault type
     * @param vaultId The vault id
     * @return vaultData The vault data
     */
    function _getVaultAt(IVaultFactory.VaultType vaultType, uint256 vaultId)
        internal
        view
        returns (VaultData memory vaultData)
    {
        IBaseVault vault = IBaseVault(vaultFactory.getVaultAt(vaultType, vaultId));
        vaultData = _getVault(vault, vaultType);
    }

    /**
     * @dev Gets the vault information
     * @param vault The vault address
     * @return vaultData The vault data
     */
    function _getVault(IBaseVault vault) internal view returns (VaultData memory vaultData) {
        IVaultFactory.VaultType vaultType = vaultFactory.getVaultType(address(vault));

        vaultData = _getVault(vault, vaultType);
    }

    /**
     * @dev Gets the vault information, considering that we already know the vault type
     * @param vault The vault address
     * @param vaultType The vault type
     * @return vaultData The vault data
     */
    function _getVault(IBaseVault vault, IVaultFactory.VaultType vaultType)
        internal
        view
        returns (VaultData memory vaultData)
    {
        FarmData memory farmInfo;
        if (aptFarm.hasFarm(address(vault))) {
            uint256 farmId = aptFarm.vaultFarmId(address(vault));
            farmInfo = _getFarm(farmId);
        }

        address tokenX = address(vault.getTokenX());
        address tokenY = address(vault.getTokenY());

        (uint256 tokenXBalance, uint256 tokenYBalance) = vault.getBalances();

        IStrategy strategy = vault.getStrategy();
        ILBPair lbPair = vault.getPair();

        vaultData = VaultData({
            vault: vault,
            vaultType: vaultType,
            strategy: strategy,
            strategyType: vaultFactory.getStrategyType(address(strategy)),
            isDepositsPaused: vault.isDepositsPaused(),
            isInEmergencyMode: address(strategy) == address(0) && (tokenXBalance > 0 || tokenYBalance > 0),
            lbPair: address(lbPair),
            lbPairBinStep: lbPair.getBinStep(),
            tokenX: tokenX,
            tokenY: tokenY,
            tokenXBalance: tokenXBalance,
            tokenYBalance: tokenYBalance,
            totalSupply: vault.totalSupply(),
            vaultBalanceUSD: _getVaultTokenUSDValue(vault, vault.totalSupply()),
            hasFarm: aptFarm.hasFarm(address(vault)),
            farmData: farmInfo
        });
    }

    /**
     * @dev Appends the user's info to the vault data
     * @param vaultData The vault data
     * @param user The user's address
     * @return vaultDataWithUserInfo The vault data with the user's info
     */
    function _getVaultUserInfo(VaultData memory vaultData, address user)
        internal
        view
        returns (VaultDataWithUserInfo memory vaultDataWithUserInfo)
    {
        uint256 userBalance = vaultData.vault.balanceOf(user);
        uint256 userBalanceUSD =
            vaultData.totalSupply == 0 ? 0 : vaultData.vaultBalanceUSD * userBalance / vaultData.totalSupply;

        FarmDataWithUserInfo memory farmDataWithUserInfo;

        if (vaultData.hasFarm) {
            farmDataWithUserInfo = _getFarmUserInfo(vaultData.farmData, user);
        }

        vaultDataWithUserInfo = VaultDataWithUserInfo({
            vaultData: vaultData,
            userBalance: userBalance,
            userBalanceUSD: userBalanceUSD,
            farmDataWithUserInfo: farmDataWithUserInfo
        });
    }

    /**
     * @dev Gets the farm data for every vault that has a farm
     * @return farmsData The farm data array
     */
    function _getAllVaultsWithFarms() internal view returns (VaultData[] memory farmsData) {
        farmsData = _getVaultsWithFarms(0, type(uint256).max);
    }

    /**
     * @dev Gets the paginated farm data for every vault that has a farm
     * @param startId The start id
     * @param pageSize The amount of farms to get
     * @return farmsData The farm data array
     */
    function _getVaultsWithFarms(uint256 startId, uint256 pageSize)
        internal
        view
        returns (VaultData[] memory farmsData)
    {
        uint256 totalFarms = aptFarm.farmLength();

        if (startId >= totalFarms) {
            return farmsData;
        }

        if (startId + pageSize > totalFarms) {
            pageSize = totalFarms - startId;
        }

        farmsData = new VaultData[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            IBaseVault vault = IBaseVault(address(aptFarm.farmInfo(startId + i).apToken));

            farmsData[i] = _getVault(vault);
        }
    }

    /**
     * @dev Gets the farm information for the specified farm
     * @param farmId The farm id
     * @return farmData The farm data
     */
    function _getFarm(uint256 farmId) internal view returns (FarmData memory farmData) {
        IAPTFarm.FarmInfo memory farmInfo = aptFarm.farmInfo(farmId);

        IBaseVault vault = IBaseVault(address(farmInfo.apToken));

        farmData = FarmData({
            farmId: farmId,
            joePerSec: farmInfo.joePerSec,
            rewarder: IRewarder(farmInfo.rewarder),
            aptBalance: farmInfo.apToken.balanceOf(address(aptFarm)),
            aptBalanceUSD: _getVaultTokenUSDValue(vault, farmInfo.apToken.balanceOf(address(aptFarm)))
        });
    }

    /**
     * @dev Appends the user's info to the farm data
     * @param farmData The farm data
     * @param user The user's address
     * @return farmDataWithUserInfo The farm data with the user's info
     */
    function _getFarmUserInfo(FarmData memory farmData, address user)
        internal
        view
        returns (FarmDataWithUserInfo memory farmDataWithUserInfo)
    {
        uint256 userBalance = aptFarm.userInfo(farmData.farmId, user).amount;
        uint256 userBalanceUSD =
            farmData.aptBalance == 0 ? 0 : farmData.aptBalanceUSD * userBalance / farmData.aptBalance;

        (uint256 pendingJoe,,, uint256 pendingBonusToken) = aptFarm.pendingTokens(farmData.farmId, user);

        farmDataWithUserInfo = FarmDataWithUserInfo({
            farmData: farmData,
            userBalance: userBalance,
            userBalanceUSD: userBalanceUSD,
            pendingJoe: pendingJoe,
            pendingBonusToken: pendingBonusToken
        });
    }

    /**
     * @dev Gets the vault token USD value
     * @param vault The vault address
     * @param amount The amount of vault tokens
     * @return tokenUSDValue The vault token USD value
     */
    function _getVaultTokenUSDValue(IBaseVault vault, uint256 amount) internal view returns (uint256 tokenUSDValue) {
        (address tokenX, address tokenY) = (address(vault.getTokenX()), address(vault.getTokenY()));
        (uint256 amountX, uint256 amountY) = vault.previewAmounts(amount);

        (uint256 tokenXPrice, uint256 tokenYPrice) =
            (dexLens.getTokenPriceUSD(tokenX), dexLens.getTokenPriceUSD(tokenY));

        tokenUSDValue = (amountX * tokenXPrice / (10 ** IERC20Metadata(tokenX).decimals()))
            + (amountY * tokenYPrice / (10 ** IERC20Metadata(tokenY).decimals()));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IJoeDexLens} from "joe-dex-lens/interfaces/IJoeDexLens.sol";

import {IBaseVault} from "joe-v2-vault/interfaces/IBaseVault.sol";
import {IStrategy} from "joe-v2-vault/interfaces/IStrategy.sol";
import {IVaultFactory} from "joe-v2-vault/interfaces/IVaultFactory.sol";

import {IAPTFarm} from "./IAPTFarm.sol";
import {IRewarder} from "./IRewarder.sol";

interface IAPTFarmLens {
    struct VaultData {
        IBaseVault vault;
        IVaultFactory.VaultType vaultType;
        IStrategy strategy;
        IVaultFactory.StrategyType strategyType;
        bool isDepositsPaused;
        bool isInEmergencyMode;
        address lbPair;
        uint256 lbPairBinStep;
        address tokenX;
        address tokenY;
        uint256 tokenXBalance;
        uint256 tokenYBalance;
        uint256 totalSupply;
        uint256 vaultBalanceUSD;
        bool hasFarm;
        FarmData farmData;
    }

    struct FarmData {
        uint256 farmId;
        uint256 joePerSec;
        IRewarder rewarder;
        uint256 aptBalance;
        uint256 aptBalanceUSD;
    }

    struct VaultDataWithUserInfo {
        VaultData vaultData;
        uint256 userBalance;
        uint256 userBalanceUSD;
        FarmDataWithUserInfo farmDataWithUserInfo;
    }

    struct FarmDataWithUserInfo {
        FarmData farmData;
        uint256 userBalance;
        uint256 userBalanceUSD;
        uint256 pendingJoe;
        uint256 pendingBonusToken;
    }

    function vaultFactory() external view returns (IVaultFactory);

    function aptFarm() external view returns (IAPTFarm);

    function dexLens() external view returns (IJoeDexLens);

    function getAllVaults() external view returns (VaultData[] memory vaultsData);

    function getPaginatedVaultsFromType(IVaultFactory.VaultType vaultType, uint256 startId, uint256 pageSize)
        external
        view
        returns (VaultData[] memory vaultsData);

    function getAllVaultsWithFarms() external view returns (VaultData[] memory farmsData);

    function getPaginatedVaultsWithFarms(uint256 startId, uint256 pageSize)
        external
        view
        returns (VaultData[] memory farmsData);

    function getAllVaultsIncludingUserInfo(address user)
        external
        view
        returns (VaultDataWithUserInfo[] memory vaultsDataWithUserInfo);

    function getPaginatedVaultsIncludingUserInfo(
        address user,
        IVaultFactory.VaultType vaultType,
        uint256 startId,
        uint256 pageSize
    ) external view returns (VaultDataWithUserInfo[] memory vaultsDataWithUserInfo);

    function getAllVaultsWithFarmsIncludingUserInfo(address user)
        external
        view
        returns (VaultDataWithUserInfo[] memory farmsDataWithUserInfo);

    function getPaginatedVaultsWithFarmsIncludingUserInfo(address user, uint256 startId, uint256 pageSize)
        external
        view
        returns (VaultDataWithUserInfo[] memory farmsDataWithUserInfo);
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

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IJoeFactory} from "joe-v2-1/interfaces/IJoeFactory.sol";
import {ILBFactory} from "joe-v2-1/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2-1/interfaces/ILBLegacyFactory.sol";
import {ISafeAccessControlEnumerable} from "solrary/access/ISafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Joe Dex Lens contract
/// @author Trader Joe
/// @notice The interface needed to interract with the Joe Dex Lens contract
interface IJoeDexLens is ISafeAccessControlEnumerable {
    error JoeDexLens__UnknownDataFeedType();
    error JoeDexLens__CollateralNotInPair(address pair, address collateral);
    error JoeDexLens__TokenNotInPair(address pair, address token);
    error JoeDexLens__SameTokens();
    error JoeDexLens__NativeToken();
    error JoeDexLens__DataFeedAlreadyAdded(address token, address dataFeed);
    error JoeDexLens__DataFeedNotInSet(address token, address dataFeed);
    error JoeDexLens__LengthsMismatch();
    error JoeDexLens__NullWeight();
    error JoeDexLens__InvalidChainLinkPrice();
    error JoeDexLens__V1ContractNotSet();
    error JoeDexLens__V2ContractNotSet();
    error JoeDexLens__V2_1ContractNotSet();
    error JoeDexLens__AlreadyInitialized();
    error JoeDexLens__InvalidDataFeed();
    error JoeDexLens__ZeroAddress();
    error JoeDexLens__SameDataFeed();

    /// @notice Enumerators of the different data feed types
    enum DataFeedType {
        V1,
        V2,
        V2_1,
        CHAINLINK
    }

    /// @notice Structure for data feeds, contains the data feed's address and its type.
    /// For V1/V2, the`dfAddress` should be the address of the pair
    /// For chainlink, the `dfAddress` should be the address of the aggregator
    struct DataFeed {
        address collateralAddress;
        address dfAddress;
        uint88 dfWeight;
        DataFeedType dfType;
    }

    /// @notice Structure for a set of data feeds
    /// `datafeeds` is the list of all the data feeds
    /// `indexes` is a mapping linking the address of a data feed to its index in the `datafeeds` list.
    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    event NativeDataFeedSet(address dfAddress);

    event DataFeedAdded(address token, DataFeed dataFeed);

    event DataFeedsWeightSet(address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address token, address dfAddress);

    function getWNative() external view returns (address wNative);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getLegacyFactoryV2() external view returns (ILBLegacyFactory legacyFactoryV2);

    function getFactoryV2_1() external view returns (ILBFactory factoryV2);

    function getDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function addDataFeed(address token, DataFeed calldata dataFeed) external;

    function setDataFeedWeight(address token, address dfAddress, uint88 newWeight) external;

    function removeDataFeed(address token, address dfAddress) external;

    function addDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;

    function setNativeDataFeed(address aggregator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IStrategy} from "./IStrategy.sol";
import {IVaultFactory} from "./IVaultFactory.sol";

/**
 * @title Base Vault Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Vaults
 */
interface IBaseVault is IERC20Upgradeable {
    error BaseVault__AlreadyWhitelisted(address user);
    error BaseVault__BurnMinShares();
    error BaseVault__DepositsPaused();
    error BaseVault__InvalidNativeAmount();
    error BaseVault__InvalidRecipient();
    error BaseVault__InvalidShares();
    error BaseVault__InvalidStrategy();
    error BaseVault__InvalidToken();
    error BaseVault__NoNativeToken();
    error BaseVault__NoQueuedWithdrawal();
    error BaseVault__MaxSharesExceeded();
    error BaseVault__NativeTransferFailed();
    error BaseVault__NotInEmergencyMode();
    error BaseVault__NotWhitelisted(address user);
    error BaseVault__OnlyFactory();
    error BaseVault__OnlyWNative();
    error BaseVault__OnlyStrategy();
    error BaseVault__SameStrategy();
    error BaseVault__SameWhitelistState();
    error BaseVault__ZeroAmount();
    error BaseVault__ZeroShares();
    error BaseVault__InvalidRound();
    error BaseVault__Unauthorized();

    struct QueuedWithdrawal {
        mapping(address => uint256) userWithdrawals;
        uint256 totalQueuedShares;
        uint128 totalAmountX;
        uint128 totalAmountY;
    }

    event Deposited(address indexed user, uint256 amountX, uint256 amountY, uint256 shares);

    event WithdrawalQueued(address indexed sender, address indexed user, uint256 indexed round, uint256 shares);

    event WithdrawalCancelled(address indexed sender, address indexed recipient, uint256 indexed round, uint256 shares);

    event WithdrawalRedeemed(
        address indexed sender,
        address indexed recipient,
        uint256 indexed round,
        uint256 shares,
        uint256 amountX,
        uint256 amountY
    );

    event WithdrawalExecuted(uint256 indexed round, uint256 totalQueuedQhares, uint256 amountX, uint256 amountY);

    event StrategySet(IStrategy strategy);

    event WhitelistStateChanged(bool state);

    event WhitelistAdded(address[] addresses);

    event WhitelistRemoved(address[] addresses);

    event Recovered(address token, address recipient, uint256 amount);

    event DepositsPaused();

    event DepositsResumed();

    event EmergencyMode();

    event EmergencyWithdrawal(address indexed sender, uint256 shares, uint256 amountX, uint256 amountY);

    function getFactory() external view returns (IVaultFactory);

    function getPair() external view returns (ILBPair);

    function getTokenX() external view returns (IERC20Upgradeable);

    function getTokenY() external view returns (IERC20Upgradeable);

    function getStrategy() external view returns (IStrategy);

    function getAumAnnualFee() external view returns (uint256);

    function getRange() external view returns (uint24 low, uint24 upper);

    function getOperators() external view returns (address defaultOperator, address operator);

    function getBalances() external view returns (uint256 amountX, uint256 amountY);

    function previewShares(uint256 amountX, uint256 amountY)
        external
        view
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function previewAmounts(uint256 shares) external view returns (uint256 amountX, uint256 amountY);

    function isDepositsPaused() external view returns (bool);

    function isWhitelistedOnly() external view returns (bool);

    function isWhitelisted(address user) external view returns (bool);

    function getCurrentRound() external view returns (uint256 round);

    function getQueuedWithdrawal(uint256 round, address user) external view returns (uint256 shares);

    function getTotalQueuedWithdrawal(uint256 round) external view returns (uint256 totalQueuedShares);

    function getCurrentTotalQueuedWithdrawal() external view returns (uint256 totalQueuedShares);

    function getRedeemableAmounts(uint256 round, address user)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function deposit(uint256 amountX, uint256 amountY)
        external
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function depositNative(uint256 amountX, uint256 amountY)
        external
        payable
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY);

    function queueWithdrawal(uint256 shares, address recipient) external returns (uint256 round);

    function cancelQueuedWithdrawal(uint256 shares) external returns (uint256 round);

    function redeemQueuedWithdrawal(uint256 round, address recipient)
        external
        returns (uint256 amountX, uint256 amountY);

    function redeemQueuedWithdrawalNative(uint256 round, address recipient)
        external
        returns (uint256 amountX, uint256 amountY);

    function emergencyWithdraw() external;

    function executeQueuedWithdrawals() external;

    function initialize(string memory name, string memory symbol) external;

    function setStrategy(IStrategy newStrategy) external;

    function setWhitelistState(bool state) external;

    function addToWhitelist(address[] calldata addresses) external;

    function removeFromWhitelist(address[] calldata addresses) external;

    function pauseDeposits() external;

    function resumeDeposits() external;

    function setEmergencyMode() external;

    function recoverERC20(IERC20Upgradeable token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IOneInchRouter} from "./IOneInchRouter.sol";
import {IVaultFactory} from "./IVaultFactory.sol";

/**
 * @title Strategy Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Vaults' Strategies
 */
interface IStrategy {
    error Strategy__OnlyFactory();
    error Strategy__OnlyVault();
    error Strategy__OnlyOperators();
    error Strategy__ZeroAmounts();
    error Strategy__InvalidAmount();
    error Strategy__InvalidToken();
    error Strategy__InvalidReceiver();
    error Strategy__InvalidRange();
    error Strategy__InvalidFee();
    error Strategy__ActiveIdSlippage();
    error Strategy__RangeAlreadySet();
    error Strategy__RangeTooWide();
    error Strategy__InvalidLength();

    event OperatorSet(address operator);

    event AumFeeCollected(
        address indexed sender, uint256 totalBalanceX, uint256 totalBalanceY, uint256 feeX, uint256 feeY
    );

    event AumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeReset();

    event RangeSet(uint24 low, uint24 upper);

    function getFactory() external view returns (IVaultFactory);

    function getVault() external pure returns (address);

    function getPair() external pure returns (ILBPair);

    function getTokenX() external pure returns (IERC20Upgradeable);

    function getTokenY() external pure returns (IERC20Upgradeable);

    function getRange() external view returns (uint24 low, uint24 upper);

    function getAumAnnualFee() external view returns (uint256 aumAnnualFee);

    function getLastRebalance() external view returns (uint256 lastRebalance);

    function getPendingAumAnnualFee() external view returns (bool isSet, uint256 pendingAumAnnualFee);

    function getOperator() external view returns (address);

    function getBalances() external view returns (uint256 amountX, uint256 amountY);

    function getIdleBalances() external view returns (uint256 amountX, uint256 amountY);

    function initialize() external;

    function withdrawAll() external;

    function rebalance(
        uint24 newLower,
        uint24 newUpper,
        uint24 desiredActiveId,
        uint24 slippageActiveId,
        uint256 amountX,
        uint256 amountY,
        bytes calldata distributions
    ) external;

    function swap(address executor, IOneInchRouter.SwapDescription memory desc, bytes memory data) external;

    function setOperator(address operator) external;

    function setPendingAumAnnualFee(uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IAggregatorV3} from "./IAggregatorV3.sol";
import {IStrategy} from "./IStrategy.sol";
import {IBaseVault} from "./IBaseVault.sol";

/**
 * @title Vault Factory Interface
 * @author Trader Joe
 * @notice Interface used to interact with the Factory for Liquidity Book Vaults
 */
interface IVaultFactory {
    error VaultFactory__VaultImplementationNotSet(VaultType vType);
    error VaultFactory__StrategyImplementationNotSet(StrategyType sType);
    error VaultFactory__InvalidType();
    error VaultFactory__InvalidOraclePrice();
    error VaultFactory__InvalidStrategy();
    error VaultFactory__InvalidFeeRecipient();
    error VaultFactory__InvalidOwner();
    error VaultFactory__InvalidLength();
    error VaultFactory__InvalidDecimals();

    enum VaultType {
        None,
        Simple,
        Oracle
    }

    enum StrategyType {
        None,
        Default
    }

    event VaultCreated(
        VaultType indexed vType,
        address indexed vault,
        ILBPair indexed lbPair,
        uint256 vaultIndex,
        address tokenX,
        address tokenY
    );

    event StrategyCreated(
        StrategyType indexed sType,
        address indexed strategy,
        address indexed vault,
        ILBPair lbPair,
        uint256 strategyIndex
    );

    event VaultImplementationSet(VaultType indexed vType, address indexed vaultImplementation);

    event StrategyImplementationSet(StrategyType indexed sType, address indexed strategyImplementation);

    event DefaultOperatorSet(address indexed sender, address indexed defaultOperator);

    event FeeRecipientSet(address indexed sender, address indexed feeRecipient);

    function getWNative() external view returns (address);

    function getVaultAt(VaultType vType, uint256 index) external view returns (address);

    function getVaultType(address vault) external view returns (VaultType);

    function getStrategyAt(StrategyType sType, uint256 index) external view returns (address);

    function getStrategyType(address strategy) external view returns (StrategyType);

    function getNumberOfVaults(VaultType vType) external view returns (uint256);

    function getNumberOfStrategies(StrategyType sType) external view returns (uint256);

    function getDefaultOperator() external view returns (address);

    function getFeeRecipient() external view returns (address);

    function getVaultImplementation(VaultType vType) external view returns (address);

    function getStrategyImplementation(StrategyType sType) external view returns (address);

    function batchRedeemQueuedWithdrawals(
        address[] calldata vaults,
        uint256[] calldata rounds,
        bool[] calldata withdrawNative
    ) external;

    function setVaultImplementation(VaultType vType, address vaultImplementation) external;

    function setStrategyImplementation(StrategyType sType, address strategyImplementation) external;

    function setDefaultOperator(address defaultOperator) external;

    function setOperator(IStrategy strategy, address operator) external;

    function setPendingAumAnnualFee(IBaseVault vault, uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee(IBaseVault vault) external;

    function setFeeRecipient(address feeRecipient) external;

    function createOracleVaultAndDefaultStrategy(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault, address strategy);

    function createSimpleVaultAndDefaultStrategy(ILBPair lbPair) external returns (address vault, address strategy);

    function createOracleVault(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault);

    function createSimpleVault(ILBPair lbPair) external returns (address vault);

    function createDefaultStrategy(IBaseVault vault) external returns (address strategy);

    function linkVaultToStrategy(IBaseVault vault, address strategy) external;

    function setWhitelistState(IBaseVault vault, bool state) external;

    function addToWhitelist(IBaseVault vault, address[] calldata addresses) external;

    function removeFromWhitelist(IBaseVault vault, address[] calldata addresses) external;

    function pauseDeposits(IBaseVault vault) external;

    function resumeDeposits(IBaseVault vault) external;

    function setEmergencyMode(IBaseVault vault) external;

    function recoverERC20(IBaseVault vault, IERC20Upgradeable token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IRewarder} from "./IRewarder.sol";

interface IAPTFarm {
    error APTFarm__InvalidAPToken();
    error APTFarm__ZeroAmount();
    error APTFarm__EmptyArray();
    error APTFarm__ZeroAddress();
    error APTFarm__InvalidJoePerSec();
    error APTFarm__InvalidFarmIndex();
    error APTFarm__TokenAlreadyHasFarm(address apToken);
    error APTFarm__InsufficientDeposit(uint256 deposit, uint256 amountWithdrawn);

    event Add(uint256 indexed pid, uint256 allocPoint, IERC20 indexed apToken, IRewarder indexed rewarder);
    event Set(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateFarm(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accJoePerShare);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount, uint256 unpaidAmount);
    event BatchHarvest(address indexed user, uint256[] pids);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Skim(address indexed token, address indexed to, uint256 amount);

    /**
     * @notice Info of each APTFarm user.
     * `amount` LP token amount the user has provided.
     * `rewardDebt` The amount of JOE entitled to the user.
     * `unpaidRewards` The amount of JOE that could not be transferred to the user.
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unpaidRewards;
    }

    /**
     * @notice Info of each APTFarm farm.
     * `apToken` Address of the LP token.
     * `accJoePerShare` Accumulated JOE per share.
     * `lastRewardTimestamp` Last timestamp that JOE distribution occurs.
     * `joePerSec` JOE tokens distributed per second.
     * `rewarder` Address of the rewarder contract that handles the distribution of bonus tokens.
     */
    struct FarmInfo {
        IERC20 apToken;
        uint256 accJoePerShare;
        uint256 lastRewardTimestamp;
        uint256 joePerSec;
        IRewarder rewarder;
    }

    function joe() external view returns (IERC20 joe);

    function hasFarm(address apToken) external view returns (bool hasFarm);

    function vaultFarmId(address apToken) external view returns (uint256 vaultFarmId);

    function apTokenBalances(IERC20 apToken) external view returns (uint256 apTokenBalance);

    function farmLength() external view returns (uint256 farmLength);

    function farmInfo(uint256 pid) external view returns (FarmInfo memory farmInfo);

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory userInfo);

    function add(uint256 joePerSec, IERC20 apToken, IRewarder rewarder) external;

    function set(uint256 pid, uint256 joePerSec, IRewarder rewarder, bool overwrite) external;

    function pendingTokens(uint256 pid, address user)
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function harvestRewards(uint256[] calldata pids) external;

    function emergencyWithdraw(uint256 pid) external;

    function skim(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onJoeReward(address user, uint256 newLpAmount, uint256 aptSupply) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/// @title Joe V1 Factory Interface
/// @notice Interface to interact with Joe V1 Factory
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBLegacyPair} from "./ILBLegacyPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBLegacyFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBLegacyPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBLegacyPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBLegacyPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBLegacyPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBLegacyPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint16 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBLegacyPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint256 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBLegacyPair LBPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

interface ISafeAccessControlEnumerable is ISafeOwnable {
    error SafeAccessControlEnumerable__OnlyRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__OnlyOwnerOrRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__RoleAlreadyGranted(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountAlreadyHasRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountDoesNotHaveRole(address account, bytes32 role);

    event RoleGranted(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleRevoked(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleAdminSet(address indexed sender, bytes32 indexed role, bytes32 indexed adminRole);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMemberAt(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IOneInchRouter {
    struct SwapDescription {
        IERC20Upgradeable srcToken;
        IERC20Upgradeable dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(address executor, SwapDescription calldata desc, bytes calldata permit, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Aggregator V3 Interface
 * @author Trader Joe
 * @notice Interface used to interact with Chainlink datafeeds.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBLegacyToken} from "./ILBLegacyToken.sol";

/// @title Liquidity Book Pair V2 Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBLegacyPair is ILBLegacyToken {
    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeesDistribution feesX;
        FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(address indexed sender, address indexed receiver, IERC20 token, uint256 amount, uint256 fee);

    event CompositionFee(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 feesX, uint256 feesY
    );

    event DepositedToBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event WithdrawnFromBin(
        address indexed sender, address indexed recipient, uint256 indexed id, uint256 amountX, uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (address);

    function getReservesAndId() external view returns (uint256 reserveX, uint256 reserveY, uint256 activeId);

    function getGlobalFees()
        external
        view
        returns (uint128 feesXTotal, uint128 feesYTotal, uint128 feesXProtocol, uint128 feesYProtocol);

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (uint256 cumulativeId, uint256 cumulativeAccumulator, uint256 cumulativeBinCrossed);

    function feeParameters() external view returns (FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(address receiver, IERC20 token, uint256 amount, bytes calldata data) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    ) external returns (uint256 amountXAddedToPair, uint256 amountYAddedToPair, uint256[] memory liquidityMinted);

    function burn(uint256[] calldata ids, uint256[] calldata amounts, address to)
        external
        returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ISafeOwnable {
    error SafeOwnable__OnlyOwner();
    error SafeOwnable__OnlyPendingOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PendingOwnerSet(address indexed owner, address indexed pendingOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address newPendingOwner) external;

    function becomeOwner() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "openzeppelin/utils/introspection/IERC165.sol";

/// @title Liquidity Book V2 Token Interface
/// @author Trader Joe
/// @notice Required interface of LBToken contract
interface ILBLegacyToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata id, uint256[] calldata amount)
        external;
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