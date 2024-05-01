// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.17;

import { IBulkActionsEntry } from "./interfaces/IBulkActionsEntry.sol";
import { ICegaState } from "./interfaces/ICegaState.sol";
import { IProduct } from "./interfaces/IProduct.sol";
import { IFCNVault } from "./interfaces/IFCNVault.sol";
import { FCNVaultMetadata, VaultStatus } from "./Structs.sol";

contract BulkActionsEntry is IBulkActionsEntry {
    // IMMUTABLES

    bytes32 public constant TRADER_ADMIN_ROLE = keccak256("TRADER_ADMIN_ROLE");

    ICegaState public immutable cegaState;

    // MODIFIERS

    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    // CONSTRUCTOR

    constructor(address _cegaState) {
        cegaState = ICegaState(_cegaState);
    }

    // EXTERNAL FUNCTIONS

    function bulkOpenVaultDeposits(address[] calldata vaultAddresses) external onlyTraderAdmin {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).openVaultDeposits(vaultAddresses[i]);
        }
    }

    function bulkProcessDepositQueues(ProcessQueueParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            _getProduct(params[i].vaultAddress).processDepositQueue(params[i].vaultAddress, params[i].maxProcessCount);
        }
    }

    function bulkSetTradeData(SetTradeDataParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            _getProduct(params[i].vaultAddress).setTradeData(
                params[i].vaultAddress,
                params[i].tradeDate,
                params[i].tradeExpiry,
                params[i].aprBps,
                params[i].tenorInDays
            );
        }
    }

    function bulkUpdateOptionBarriers(UpdateOptionBarrierParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            _getProduct(params[i].vaultAddress).updateOptionBarrier(
                params[i].vaultAddress,
                params[i].index,
                params[i].asset,
                params[i].strikeAbsoluteValue,
                params[i].barrierAbsoluteValue
            );
        }
    }

    function bulkSendAssetsToTrade(SendAssetsToTradeParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            FCNVaultMetadata memory metadata = _getProduct(params[i].vaultAddress).getVaultMetadata(
                params[i].vaultAddress
            );

            require(metadata.vaultStatus == VaultStatus.NotTraded, "500:WS");

            _getProduct(params[i].vaultAddress).sendAssetsToTrade(
                params[i].vaultAddress,
                params[i].receiver,
                metadata.underlyingAmount
            );
        }
    }

    function bulkCheckBarriers(address[] calldata vaultAddresses) external {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).checkBarriers(vaultAddresses[i]);
        }
    }

    function bulkCalculateCurrentYield(address[] calldata vaultAddresses) external {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).calculateCurrentYield(vaultAddresses[i]);
        }
    }

    function bulkCalculateVaultFinalPayoffs(address[] calldata vaultAddresses) external {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).calculateVaultFinalPayoff(vaultAddresses[i]);
        }
    }

    function bulkMoveAssetsToProducts(MoveAssetsToProductParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            FCNVaultMetadata memory metadata = _getProduct(params[i].vaultAddress).getVaultMetadata(
                params[i].vaultAddress
            );
            require(metadata.vaultStatus == VaultStatus.PayoffCalculated, "500:WS");
            require(params[i].amount + metadata.currentAssetAmount <= metadata.vaultFinalPayoff, "400:IncorrectAmount");

            cegaState.moveAssetsToProduct(params[i].productName, params[i].vaultAddress, params[i].amount);
        }
    }

    function bulkCollectFees(address[] calldata vaultAddresses) external onlyTraderAdmin {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).collectFees(vaultAddresses[i]);
        }
    }

    function bulkProcessWithdrawalQueues(ProcessQueueParams[] calldata params) external onlyTraderAdmin {
        for (uint256 i = 0; i < params.length; i++) {
            _getProduct(params[i].vaultAddress).processWithdrawalQueue(
                params[i].vaultAddress,
                params[i].maxProcessCount
            );
        }
    }

    function bulkRolloverVaults(address[] calldata vaultAddresses) external onlyTraderAdmin {
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            _getProduct(vaultAddresses[i]).rolloverVault(vaultAddresses[i]);
        }
    }

    // INTERNAL FUNCTIONS

    function _getProduct(address vaultAddress) internal view returns (IProduct) {
        return IProduct(IFCNVault(vaultAddress).fcnProduct());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBulkActionsEntry {
    // STRUCTS

    struct ProcessQueueParams {
        address vaultAddress;
        uint256 maxProcessCount;
    }

    struct SetTradeDataParams {
        address vaultAddress;
        uint256 tradeDate;
        uint256 tradeExpiry;
        uint256 aprBps;
        uint256 tenorInDays;
    }

    struct UpdateOptionBarrierParams {
        address vaultAddress;
        uint256 index;
        string asset;
        uint256 strikeAbsoluteValue;
        uint256 barrierAbsoluteValue;
    }

    struct SendAssetsToTradeParams {
        address vaultAddress;
        address receiver;
        uint256 amount;
    }

    struct MoveAssetsToProductParams {
        string productName;
        address vaultAddress;
        uint256 amount;
    }

    // FUNCTIONS

    function bulkOpenVaultDeposits(address[] calldata vaultAddresses) external;

    function bulkProcessDepositQueues(ProcessQueueParams[] calldata params) external;

    function bulkSetTradeData(SetTradeDataParams[] calldata params) external;

    function bulkUpdateOptionBarriers(UpdateOptionBarrierParams[] calldata params) external;

    function bulkSendAssetsToTrade(SendAssetsToTradeParams[] calldata params) external;

    function bulkCheckBarriers(address[] calldata vaultAddresses) external;

    function bulkCalculateCurrentYield(address[] calldata vaultAddresses) external;

    function bulkCalculateVaultFinalPayoffs(address[] calldata vaultAddresses) external;

    function bulkMoveAssetsToProducts(MoveAssetsToProductParams[] calldata params) external;

    function bulkCollectFees(address[] calldata vaultAddresses) external;

    function bulkProcessWithdrawalQueues(ProcessQueueParams[] calldata params) external;

    function bulkRolloverVaults(address[] calldata vaultAddresses) external;
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