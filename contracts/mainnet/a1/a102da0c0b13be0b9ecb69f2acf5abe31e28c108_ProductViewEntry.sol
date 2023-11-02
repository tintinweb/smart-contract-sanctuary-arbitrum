// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

enum DCSOptionType {
    BuyLow,
    SellHigh
}

enum SettlementStatus {
    NotAuctioned,
    Auctioned,
    InitialPremiumPaid,
    AwaitingSettlement,
    Settled,
    Defaulted
}

struct DCSProductCreationParams {
    uint128 maxDepositAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    address quoteAssetAddress;
    address baseAssetAddress;
    DCSOptionType dcsOptionType;
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
}

struct DCSProduct {
    uint32 id;
    bool isDepositQueueOpen;
    uint128 maxDepositAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 sumVaultUnderlyingAmounts; //revisit later
    address[] vaults;
    DCSOptionType dcsOptionType;
    address quoteAssetAddress; // should be immutable
    address baseAssetAddress; // should be immutable
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
}

struct DCSVault {
    SettlementStatus settlementStatus;
    bool isPayoffInDepositAsset;
    uint256 aprBps;
    uint256 initialSpotPrice;
    uint256 strikePrice;
    uint256 totalYield;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IProductViewEntry {
    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IProductViewEntry } from "./interfaces/IProductViewEntry.sol";
import { CegaStorage, CegaGlobalStorage } from "../storage/CegaStorage.sol";

contract ProductViewEntry is IProductViewEntry, CegaStorage {
    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.strategyOfProduct[productId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracleEntry {
    enum DataSource {
        None,
        Pyth
    }

    event DataSourceAdapterSet(DataSource dataSource, address adapter);

    /// @notice Gets `asset` price at `timestamp` in terms of USD using `dataSource`
    function getSinglePrice(
        address asset,
        uint64 timestamp,
        DataSource dataSource
    ) external view returns (uint256);

    /// @notice Gets `baseAsset` price at `timestamp` in terms of `quoteAsset` using `dataSource`
    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint64 timestamp,
        DataSource dataSource
    ) external view returns (uint256);

    /// @notice Sets data source adapter
    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external;

    function getTargetDecimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { CegaGlobalStorage } from "../Structs.sol";

contract CegaStorage {
    bytes32 private constant CEGA_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.global.storage")) - 1);

    function getStorage() internal pure returns (CegaGlobalStorage storage ds) {
        bytes32 position = CEGA_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { DCSProduct, DCSVault } from "./cega-strategies/dcs/DCSStructs.sol";
import { IOracleEntry } from "./oracle-entry/interfaces/IOracleEntry.sol";

uint32 constant DCS_STRATEGY_ID = 1;

struct DepositQueue {
    uint128 queuedDepositsTotalAmount;
    mapping(address => uint128) amounts;
    address[] depositors;
}

struct Withdrawer {
    address account;
    uint32 nextProductId;
}

struct WithdrawalQueue {
    uint256 queuedWithdrawalSharesAmount;
    mapping(address => mapping(uint32 => uint256)) amounts;
    Withdrawer[] withdrawers;
}

struct CegaGlobalStorage {
    // Global information
    uint32 strategyIdCounter;
    uint32 productIdCounter;
    uint32[] strategyIds;
    mapping(uint32 => uint32) strategyOfProduct;
    mapping(address => Vault) vaults;
    // DCS information
    mapping(uint32 => DCSProduct) dcsProducts;
    mapping(uint32 => DepositQueue) dcsDepositQueues;
    mapping(address => DCSVault) dcsVaults;
    mapping(address => WithdrawalQueue) dcsWithdrawalQueues;
    // vaultAddress => (timestamp => price)
    mapping(address => mapping(uint64 => uint256)) oraclePriceOverride;
}

struct Vault {
    uint32 productId;
    uint256 yieldFeeBps;
    uint256 managementFeeBps;
    uint256 vaultStartDate;
    uint40 tradeStartDate;
    address auctionWinner;
    address underlyingAsset;
    uint256 totalAssets;
    VaultStatus vaultStatus;
    uint256 auctionWinnerTokenId;
    IOracleEntry.DataSource dataSource;
    bool isInDispute;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct MMNFTMetadata {
    address vaultAddress;
    uint40 tradeStartDate;
    uint40 tradeEndDate;
}