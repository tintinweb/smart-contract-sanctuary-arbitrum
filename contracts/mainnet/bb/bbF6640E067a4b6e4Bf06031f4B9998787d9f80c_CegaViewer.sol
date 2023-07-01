// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { FCNVaultViewer } from "./FCNVaultViewer.sol";
import { FCNProductViewer } from "./FCNProductViewer.sol";
import { LOVProductViewer } from "./LOVProductViewer.sol";

contract CegaViewer is FCNVaultViewer, FCNProductViewer, LOVProductViewer {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IProduct } from "../interfaces/IProduct.sol";
import { IFCNVault } from "../interfaces/IFCNVault.sol";
import { FCNVaultMetadata, FCNVaultAssetInfo } from "../Structs.sol";

contract FCNVaultViewer {
    function getSingleFCNVaultMetadata(
        address productAddress,
        address fcnVaultAddress
    ) external view returns (FCNVaultMetadata memory) {
        IProduct product = IProduct(productAddress);

        return product.getVaultMetadata(fcnVaultAddress);
    }

    function getSingleFCNVaultAssetInfo(
        address fcnVaultAddress,
        uint256 inputAssets,
        uint256 inputShares
    ) external view returns (FCNVaultAssetInfo memory) {
        IFCNVault vault = IFCNVault(fcnVaultAddress);

        return
            FCNVaultAssetInfo({
                vaultAddress: fcnVaultAddress,
                totalAssets: vault.totalAssets(),
                totalSupply: vault.totalSupply(),
                inputAssets: inputAssets,
                outputShares: vault.convertToShares(inputAssets),
                inputShares: inputShares,
                outputAssets: vault.convertToAssets(inputShares)
            });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFCNProduct } from "../interfaces/IFCNProduct.sol";
import { IFCNVault } from "../interfaces/IFCNVault.sol";
import { Deposit, FCNVaultMetadata, FCNVaultAssetInfo } from "../Structs.sol";

contract FCNProductViewer {
    struct FCNProductInfo {
        address asset;
        string name;
        uint256 managementFeeBps; // basis points
        uint256 yieldFeeBps; // basis points
        bool isDepositQueueOpen;
        uint256 maxDepositAmountLimit;
        uint256 sumVaultUnderlyingAmounts;
        uint256 queuedDepositsTotalAmount;
        uint256 queuedDepositsCount;
        address[] vaultAddresses;
    }

    function getFCNProductInfo(address fcnProductAddress) external view returns (FCNProductInfo memory) {
        IFCNProduct fcnProduct = IFCNProduct(fcnProductAddress);
        return
            FCNProductInfo({
                asset: fcnProduct.asset(),
                name: fcnProduct.name(),
                managementFeeBps: fcnProduct.managementFeeBps(),
                yieldFeeBps: fcnProduct.yieldFeeBps(),
                isDepositQueueOpen: fcnProduct.isDepositQueueOpen(),
                maxDepositAmountLimit: fcnProduct.maxDepositAmountLimit(),
                sumVaultUnderlyingAmounts: fcnProduct.sumVaultUnderlyingAmounts(),
                queuedDepositsTotalAmount: fcnProduct.queuedDepositsTotalAmount(),
                queuedDepositsCount: fcnProduct.queuedDepositsCount(),
                vaultAddresses: fcnProduct.getVaultAddresses()
            });
    }

    function getFCNProductUserQueuedDeposits(
        address fcnProductAddress,
        address userAddress
    ) external view returns (uint256 totalQueuedDeposits) {
        IFCNProduct fcnProduct = IFCNProduct(fcnProductAddress);
        uint256 queuedDepositsCount = fcnProduct.queuedDepositsCount();

        totalQueuedDeposits = 0;
        for (uint256 i = 0; i < queuedDepositsCount; i++) {
            Deposit memory d = fcnProduct.depositQueue(i);

            if (d.receiver == userAddress) {
                totalQueuedDeposits += d.amount;
            }
        }

        return totalQueuedDeposits;
    }

    function getFCNVaultMetadata(address productAddress) external view returns (FCNVaultMetadata[] memory) {
        IFCNProduct fcnProduct = IFCNProduct(productAddress);

        address[] memory vaultAddresses = fcnProduct.getVaultAddresses();

        FCNVaultMetadata[] memory vaultMetadata = new FCNVaultMetadata[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            vaultMetadata[i] = fcnProduct.getVaultMetadata(vaultAddresses[i]);
        }

        return vaultMetadata;
    }

    function getFCNVaultAssetInfo(
        address productAddress,
        uint256 inputAssets,
        uint256 inputShares
    ) external view returns (FCNVaultAssetInfo[] memory) {
        IFCNProduct fcnProduct = IFCNProduct(productAddress);

        address[] memory vaultAddresses = fcnProduct.getVaultAddresses();

        FCNVaultAssetInfo[] memory assetInfo = new FCNVaultAssetInfo[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            IFCNVault vault = IFCNVault(vaultAddresses[i]);

            assetInfo[i] = FCNVaultAssetInfo({
                vaultAddress: address(vault),
                totalAssets: vault.totalAssets(),
                totalSupply: vault.totalSupply(),
                inputAssets: inputAssets,
                outputShares: vault.convertToShares(inputAssets),
                inputShares: inputShares,
                outputAssets: vault.convertToAssets(inputShares)
            });
        }

        return assetInfo;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { LOVCalculations } from "../LOVCalculations.sol";
import { ILOVProduct } from "../interfaces/ILOVProduct.sol";
import { IFCNVault } from "../interfaces/IFCNVault.sol";
import { Deposit, FCNVaultMetadata, FCNVaultAssetInfo } from "../Structs.sol";

contract LOVProductViewer {
    struct LOVProductInfo {
        address asset;
        string name;
        uint256 managementFeeBps; // basis points
        uint256 yieldFeeBps; // basis points
    }

    function getLOVProductInfo(address lovProductAddress) external view returns (LOVProductInfo memory) {
        ILOVProduct lovProduct = ILOVProduct(lovProductAddress);
        return
            LOVProductInfo({
                asset: lovProduct.asset(),
                name: lovProduct.name(),
                managementFeeBps: lovProduct.managementFeeBps(),
                yieldFeeBps: lovProduct.yieldFeeBps()
            });
    }

    function getLOVProductUserQueuedDeposits(
        address fcnProductAddress,
        address userAddress,
        uint256 leverage
    ) external view returns (uint256 totalQueuedDeposits) {
        ILOVProduct lovProduct = ILOVProduct(fcnProductAddress);
        uint256 queuedDepositsCount = lovProduct.getDepositQueueCount(leverage);

        totalQueuedDeposits = 0;
        for (uint256 i = 0; i < queuedDepositsCount; i++) {
            Deposit memory d = lovProduct.depositQueues(leverage, i);

            if (d.receiver == userAddress) {
                totalQueuedDeposits += d.amount;
            }
        }

        return totalQueuedDeposits;
    }

    function getLOVProductQueuedDeposits(
        address fcnProductAddress,
        uint256 leverage
    ) external view returns (uint256 totalQueuedDeposits) {
        ILOVProduct lovProduct = ILOVProduct(fcnProductAddress);
        uint256 queuedDepositsCount = lovProduct.getDepositQueueCount(leverage);

        totalQueuedDeposits = 0;
        for (uint256 i = 0; i < queuedDepositsCount; i++) {
            Deposit memory d = lovProduct.depositQueues(leverage, i);

            totalQueuedDeposits += d.amount;
        }

        return totalQueuedDeposits;
    }

    function getLOVVaultMetadata(
        address productAddress,
        uint256 leverage
    ) external view returns (FCNVaultMetadata[] memory) {
        ILOVProduct lovProduct = ILOVProduct(productAddress);

        address[] memory vaultAddresses = lovProduct.getVaultAddresses(leverage);

        FCNVaultMetadata[] memory vaultMetadata = new FCNVaultMetadata[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            vaultMetadata[i] = lovProduct.getVaultMetadata(vaultAddresses[i]);
        }

        return vaultMetadata;
    }

    function getLOVVaultAssetInfo(
        address productAddress,
        uint256 leverage,
        uint256 inputAssets,
        uint256 inputShares
    ) external view returns (FCNVaultAssetInfo[] memory) {
        ILOVProduct lovProduct = ILOVProduct(productAddress);

        address[] memory vaultAddresses = lovProduct.getVaultAddresses(leverage);

        FCNVaultAssetInfo[] memory assetInfo = new FCNVaultAssetInfo[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            IFCNVault vault = IFCNVault(vaultAddresses[i]);

            assetInfo[i] = FCNVaultAssetInfo({
                vaultAddress: address(vault),
                totalAssets: vault.totalAssets(),
                totalSupply: vault.totalSupply(),
                inputAssets: inputAssets,
                outputShares: vault.convertToShares(inputAssets),
                inputShares: inputShares,
                outputAssets: vault.convertToAssets(inputShares)
            });
        }

        return assetInfo;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * Putting logic in viewer to save space in LOVProduct contract.
     * @param productAddress is the address of the LOVProduct
     * @param vaultAddress is the address of the vault
     * @param managementFeeBps is the management fee in bps
     * @param yieldFeeBps is the yield fee in bps
     */
    function calculateFees(
        address productAddress,
        address vaultAddress,
        uint256 managementFeeBps,
        uint256 yieldFeeBps
    ) public view returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee) {
        ILOVProduct lovProduct = ILOVProduct(productAddress);
        FCNVaultMetadata memory vaultMetadata = lovProduct.getVaultMetadata(vaultAddress);

        return
            LOVCalculations.calculateFees(
                vaultMetadata.underlyingAmount,
                vaultMetadata.vaultStart,
                vaultMetadata.tradeExpiry,
                vaultMetadata.vaultFinalPayoff,
                managementFeeBps,
                yieldFeeBps
            );
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios.
     * Putting logic in viewer to save space in LOVProduct contract.
     * @param productAddress is address of LOVProduct
     * @param vaultAddress is address of the vault
     * @param cegaStateAddress is address of CegaState
     */
    function calculateKnockInRatio(
        address productAddress,
        address vaultAddress,
        address cegaStateAddress
    ) public view returns (uint256 knockInRatio) {
        ILOVProduct lovProduct = ILOVProduct(productAddress);
        FCNVaultMetadata memory vaultMetadata = lovProduct.getVaultMetadata(vaultAddress);

        return
            LOVCalculations.calculateKnockInRatio(
                vaultMetadata.optionBarriers,
                vaultMetadata.optionBarriersCount,
                cegaStateAddress
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "../Structs.sol";

interface IProduct {
    // View functions
    function asset() external view returns (address);

    function cegaState() external view returns (address);

    function getVaultMetadata(address vaultAddress) external view returns (FCNVaultMetadata memory);

    function managementFeeBps() external view returns (uint256);

    function minDepositAmount() external view returns (uint256);

    function minWithdrawalAmount() external view returns (uint256);

    function name() external view returns (string memory);

    function vaults(
        address vaultAddress
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            VaultStatus,
            bool
        );

    function withdrawalQueues(address vaultAddress, uint256 index) external view returns (Withdrawal memory);

    function yieldFeeBps() external view returns (uint256);

    // External functions

    function addOptionBarrier(address vaultAddress, OptionBarrier calldata optionBarrier) external;

    function addToWithdrawalQueue(address vaultAddress, uint256 amountShares, address receiver) external;

    function calculateCurrentYield(address vaultAddress) external;

    function calculateVaultFinalPayoff(address vaultAddress) external returns (uint256 vaultFinalPayoff);

    function checkBarriers(address vaultAddress) external;

    function collectFees(address vaultAddress) external;

    function openVaultDeposits(address vaultAddress) external;

    function processDepositQueue(address vaultAddress, uint256 maxProcessCount) external;

    function processWithdrawalQueue(address vaultAddress, uint256 maxProcessCount) external;

    function receiveAssetsFromCegaState(address vaultAddress, uint256 amount) external;

    function removeOptionBarrier(address vaultAddress, uint256 index, string calldata _asset) external;

    function removeVault(uint256 index) external;

    function rolloverVault(address vaultAddress) external;

    function sendAssetsToTrade(address vaultAddress, address receiver, uint256 amount) external;

    function setIsDepositQueueOpen(bool _isDepositQueueOpen) external;

    function setKnockInStatus(address vaultAddress, bool newState) external;

    function setManagementFeeBps(uint256 _managementFeeBps) external;

    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) external;

    function setMinDepositAmount(uint256 _minDepositAmount) external;

    function setMinWithdrawalAmount(uint256 _minWithdrawalAmount) external;

    function setTradeData(
        address vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    ) external;

    function setVaultMetadata(address vaultAddress, FCNVaultMetadata calldata metadata) external;

    function setVaultStatus(address vaultAddress, VaultStatus _vaultStatus) external;

    function setYieldFeeBps(uint256 _yieldFeeBps) external;

    function updateOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    ) external;

    function updateOptionBarrierOracle(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        string memory newOracleName
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFCNVault is IERC20 {
    function asset() external view returns (address);

    function owner() external view returns (address);

    function fcnProduct() external view returns (address);

    function totalAssets() external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function redeem(uint256 shares) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

struct LeverageMetadata {
    bool isAllowed;
    bool isDepositQueueOpen;
    uint256 maxDepositAmountLimit;
    uint256 sumVaultUnderlyingAmounts;
    uint256 queuedDepositsTotalAmount;
    address[] vaultAddresses;
}

struct FCNVaultAssetInfo {
    address vaultAddress;
    uint256 totalAssets;
    uint256 totalSupply;
    uint256 inputAssets;
    uint256 outputShares;
    uint256 inputShares;
    uint256 outputAssets;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IProduct } from "./IProduct.sol";
import { Deposit } from "../Structs.sol";

interface IFCNProduct is IProduct {
    // View functions
    function calculateFees(
        address vaultAddress
    ) external view returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee);

    function calculateKnockInRatio(address vaultAddress) external view returns (uint256 knockInRatio);

    function depositQueue(uint256 index) external view returns (Deposit memory);

    function getVaultAddresses() external view returns (address[] memory);

    function isDepositQueueOpen() external view returns (bool);

    function maxDepositAmountLimit() external view returns (uint256);

    function queuedDepositsCount() external view returns (uint256);

    function queuedDepositsTotalAmount() external view returns (uint256);

    function sumVaultUnderlyingAmounts() external view returns (uint256);

    function vaultAddresses(uint256 index) external view returns (address);

    // External functions

    function addToDepositQueue(uint256 amount) external;

    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart
    ) external returns (address vaultAddress);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ICegaState } from "./interfaces/ICegaState.sol";

library LOVCalculations {
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_TO_DAYS = 86400;
    uint256 public constant BPS_DECIMALS = 10 ** 4;
    uint256 public constant LARGE_CONSTANT = 10 ** 18;
    uint256 public constant ORACLE_STALE_DELAY = 1 days;

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     */
    function calculateCurrentYield(FCNVaultMetadata storage self) public {
        require(self.vaultStatus == VaultStatus.Traded, "500:WS");
        uint256 currentTime = block.timestamp;

        if (currentTime > self.tradeExpiry) {
            self.vaultStatus = VaultStatus.TradeExpired;
            return;
        }

        uint256 numberOfDaysPassed = (currentTime - self.tradeDate) / SECONDS_TO_DAYS;

        self.totalCouponPayoff = calculateCouponPayment(self.underlyingAmount, self.aprBps, numberOfDaysPassed);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param cegaStateAddress is the address of the CegaState contract that stores the oracle addresses
     */
    function checkBarriers(FCNVaultMetadata storage self, address cegaStateAddress) public {
        if (self.isKnockedIn == true) {
            return;
        }

        require(self.vaultStatus == VaultStatus.Traded, "500:WS");

        for (uint256 i = 0; i < self.optionBarriersCount; i++) {
            OptionBarrier storage optionBarrier = self.optionBarriers[i];

            // Knock In: Check if current price is less than barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
                (, int256 answer, uint256 startedAt, , ) = IOracle(oracle).latestRoundData();
                require(block.timestamp - ORACLE_STALE_DELAY <= startedAt, "400:T");
                if (uint256(answer) <= optionBarrier.barrierAbsoluteValue) {
                    self.isKnockedIn = true;
                }
            }
        }
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateVaultFinalPayoff(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public returns (uint256) {
        uint256 totalPrincipal;
        uint256 totalCouponPayment;
        uint256 principalToReturnBps = BPS_DECIMALS;
        uint256 capitalLost = 0;

        require(
            (self.vaultStatus == VaultStatus.TradeExpired || self.vaultStatus == VaultStatus.PayoffCalculated),
            "500:WS"
        );

        // Calculate coupon payment
        totalCouponPayment = calculateCouponPayment(self.underlyingAmount, self.aprBps, self.tenorInDays);

        // Calculate principal
        if (self.isKnockedIn) {
            principalToReturnBps = calculateKnockInRatio(self, cegaStateAddress);
            capitalLost =
                (self.underlyingAmount * (BPS_DECIMALS - principalToReturnBps) * self.leverage) /
                BPS_DECIMALS;
        }

        if (capitalLost > self.underlyingAmount) {
            totalPrincipal = 0;
        } else {
            totalPrincipal = self.underlyingAmount - capitalLost;
        }
        uint256 vaultFinalPayoff = totalPrincipal + totalCouponPayment;
        self.totalCouponPayoff = totalCouponPayment;
        self.vaultFinalPayoff = vaultFinalPayoff;
        self.vaultStatus = VaultStatus.PayoffCalculated;
        return vaultFinalPayoff;
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios in bps.
     * Example return value: 42% = 4200 (bps)
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateKnockInRatio(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public view returns (uint256) {
        return calculateKnockInRatio(self.optionBarriers, self.optionBarriersCount, cegaStateAddress);
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios in bps.
     * Example return value: 42% = 4200 (bps)
     * @param optionBarriers are the vault's option barriers
     * @param optionBarriersCount is the number of option barriers
     * @param cegaStateAddress is address of cegaState
     */
    function calculateKnockInRatio(
        OptionBarrier[] memory optionBarriers,
        uint256 optionBarriersCount,
        address cegaStateAddress
    ) public view returns (uint256) {
        uint256 minRatioBps = LARGE_CONSTANT;
        for (uint256 i = 0; i < optionBarriersCount; i++) {
            OptionBarrier memory optionBarrier = optionBarriers[i];
            address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
            (, int256 answer, uint256 startedAt, , ) = IOracle(oracle).latestRoundData();
            require(block.timestamp - ORACLE_STALE_DELAY <= startedAt, "400:T");

            // Only calculate the ratio if it is a knock in barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                uint256 ratioBps = (uint256(answer) * LARGE_CONSTANT) / optionBarrier.strikeAbsoluteValue;
                minRatioBps = Math.min(ratioBps, minRatioBps);
            }
        }
        return ((minRatioBps * BPS_DECIMALS)) / LARGE_CONSTANT;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param managementFeeBps is the management fee in bps
     * @param yieldFeeBps is the yield fee in bps
     */
    function calculateFees(
        FCNVaultMetadata storage self,
        uint256 managementFeeBps,
        uint256 yieldFeeBps
    ) public view returns (uint256, uint256, uint256) {
        return
            calculateFees(
                self.underlyingAmount,
                self.vaultStart,
                self.tradeExpiry,
                self.vaultFinalPayoff,
                managementFeeBps,
                yieldFeeBps
            );
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param underlyingAmount is the amount of underlying asset in the vault
     * @param vaultStart is the timestamp when the vault was created
     * @param tradeExpiry is the timestamp when the vault trade expires
     * @param vaultFinalPayoff is the final payoff of the vault
     * @param managementFeeBps is the management fee in bps
     * @param yieldFeeBps is the yield fee in bps
     */
    function calculateFees(
        uint256 underlyingAmount,
        uint256 vaultStart,
        uint256 tradeExpiry,
        uint256 vaultFinalPayoff,
        uint256 managementFeeBps,
        uint256 yieldFeeBps
    ) public pure returns (uint256, uint256, uint256) {
        uint256 totalFee = 0;
        uint256 managementFee = 0;
        uint256 yieldFee = 0;

        uint256 numberOfDaysPassed = (tradeExpiry - vaultStart) / SECONDS_TO_DAYS;

        managementFee =
            (underlyingAmount * numberOfDaysPassed * managementFeeBps * LARGE_CONSTANT) /
            DAYS_IN_YEAR /
            BPS_DECIMALS /
            LARGE_CONSTANT;

        if (vaultFinalPayoff > underlyingAmount) {
            uint256 profit = vaultFinalPayoff - underlyingAmount;
            yieldFee = (profit * yieldFeeBps) / BPS_DECIMALS;
        }

        totalFee = managementFee + yieldFee;
        return (totalFee, managementFee, yieldFee);
    }

    /**
     * @notice Calculates the coupon payment accumulated for a given number of daysPassed
     * @param underlyingAmount is the amount of assets
     * @param aprBps is the apr in bps
     * @param daysPassed is the number of days that coupon payments have been accured for
     */
    function calculateCouponPayment(
        uint256 underlyingAmount,
        uint256 aprBps,
        uint256 daysPassed
    ) private pure returns (uint256) {
        return (underlyingAmount * daysPassed * aprBps * LARGE_CONSTANT) / DAYS_IN_YEAR / BPS_DECIMALS / LARGE_CONSTANT;
    }

    /**
     * @notice Gets the oracle address for a given optionBarrier
     * @param optionBarrier is the option barrier
     * @param cegaStateAddress is the address of the Cega state contract
     */
    function getOracleAddress(
        OptionBarrier memory optionBarrier,
        address cegaStateAddress
    ) private view returns (address) {
        ICegaState cegaState = ICegaState(cegaStateAddress);
        address oracle = cegaState.oracleAddresses(optionBarrier.oracleName);
        require(oracle != address(0), "400:Unregistered");
        return oracle;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IProduct } from "./IProduct.sol";
import { Deposit, LeverageMetadata } from "../Structs.sol";

interface ILOVProduct is IProduct {
    // View functions
    function depositQueues(uint256 leverage, uint256 index) external view returns (Deposit memory);

    function getDepositQueueCount(uint256 leverage) external view returns (uint256);

    function getVaultAddresses(uint256 leverage) external view returns (address[] memory);

    function leverages(uint256 leverage) external view returns (LeverageMetadata memory);

    // External functions
    function addToDepositQueue(uint256 leverage, address receiver) external;

    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart,
        uint256 _leverage
    ) external returns (address vaultAddress);

    function updateAllowedLeverage(uint256 _leverage, bool _isAllowed) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IAggregatorV3 } from "./IAggregatorV3.sol";
import { RoundData } from "../Structs.sol";

interface IOracle is IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function cegaState() external view returns (address);

    function oracleData() external view returns (RoundData[] memory);

    function nextRoundId() external view returns (uint80);

    function addNextRoundData(RoundData calldata _roundData) external;

    function updateRoundData(uint80 roundId, RoundData calldata _roundData) external;

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICegaState {
    function marketMakerAllowList(address marketMaker) external view returns (bool);

    function products(string memory productName) external view returns (address);

    function oracleAddresses(string memory oracleName) external view returns (address);

    function oracleNames() external view returns (string[] memory);

    function productNames() external view returns (string[] memory);

    function feeRecipient() external view returns (address);

    function isDefaultAdmin(address sender) external view returns (bool);

    function isTraderAdmin(address sender) external view returns (bool);

    function isOperatorAdmin(address sender) external view returns (bool);

    function isServiceAdmin(address sender) external view returns (bool);

    function getOracleNames() external view returns (string[] memory);

    function addOracle(string memory oracleName, address oracleAddress) external;

    function removeOracle(string memory oracleName) external;

    function getProductNames() external view returns (string[] memory);

    function addProduct(string memory productName, address product) external;

    function removeProduct(string memory productName) external;

    function updateMarketMakerPermission(address marketMaker, bool allow) external;

    function setFeeRecipient(address _feeRecipient) external;

    function moveAssetsToProduct(string memory productName, address vaultAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}