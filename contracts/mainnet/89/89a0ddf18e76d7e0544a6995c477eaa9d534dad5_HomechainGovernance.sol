// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IIndex} from "../interfaces/IIndex.sol";
import {IConfigBuilder} from "../interfaces/IConfigBuilder.sol";
import {IConfigMigration} from "../interfaces/IConfigMigration.sol";
import {IHomechainOmnichainMessenger} from "../interfaces/IHomechainOmnichainMessenger.sol";
import {IPriceOracleDeployer} from "../price-oracles/interfaces/IPriceOracleDeployer.sol";
import {IVault} from "../interfaces/IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

import {Governance} from "./Governance.sol";

contract HomechainGovernance is Governance {
    event SetConfigBuilder(address);

    error Forbidden();

    function startIndexRebalancing(address index) external onlyOwner {
        IIndex(index).startIndexRebalancing();
    }

    function setInitialConfig(address index, address configBuilder, IConfigBuilder.Config calldata baseConfig)
        external
        onlyOwner
    {
        if (IConfigBuilder(configBuilder).configHash() != bytes32(0)) revert Forbidden();

        IIndex(index).startIndexRebalancing();

        IIndex.Config memory config;
        (IIndex.DepositConfig memory depositConfig, IIndex.RedemptionConfig memory redemptionConfig) =
            IConfigBuilder(configBuilder).setConfig(baseConfig);
        IIndex(index).setConfig(config, depositConfig, redemptionConfig);

        emit SetConfigBuilder(configBuilder);
    }

    function configure(address messenger, address index, address orderBook, address builder) external onlyOwner {
        IHomechainOmnichainMessenger(messenger).configure(index, orderBook, builder);
    }

    function setConfig(address configBuilder, IConfigBuilder.Config calldata baseConfig) external onlyOwner {
        if (IConfigBuilder(configBuilder).configHash() == bytes32(0)) revert Forbidden();

        IConfigBuilder(configBuilder).setConfig(baseConfig);
    }

    function updateConfig(
        address index,
        address configBuilder,
        IIndex.Config calldata prevConfig,
        IConfigBuilder.Config calldata baseConfig
    ) external onlyOwner {
        if (IConfigBuilder(configBuilder).configHash() == bytes32(0)) revert Forbidden();

        IIndex(index).startIndexRebalancing();

        (IIndex.DepositConfig memory depositConfig, IIndex.RedemptionConfig memory redemptionConfig) =
            IConfigBuilder(configBuilder).setConfig(baseConfig);

        IIndex(index).setConfig(prevConfig, depositConfig, redemptionConfig);
    }

    function startRebalancing(
        address configBuilder,
        IConfigBuilder.StartRebalancingParams calldata params,
        bytes calldata data
    ) external payable onlyOwner {
        IConfigBuilder(configBuilder).startRebalancing{value: msg.value}(params, data);
    }

    function startReserveRebalancing(
        address configBuilder,
        IConfigBuilder.StartReserveRebalancingParams calldata params,
        bytes calldata data
    ) external payable onlyOwner {
        IConfigBuilder(configBuilder).startReserveRebalancing{value: msg.value}(params, data);
    }

    function finishRebalancing(
        address index,
        address configBuilder,
        address messenger,
        IVault.RebalancingResult[] calldata results,
        IConfigBuilder.Config calldata config,
        IHomechainOmnichainMessenger.LzConfig calldata lzConfig,
        IIndex.Config calldata currentConfig
    ) external onlyOwner {
        (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption) =
            IConfigBuilder(configBuilder).finishRebalancing(results, config);
        IIndex(index).setConfig(currentConfig, deposit, redemption);
        IHomechainOmnichainMessenger(messenger).setLayerZeroConfig(lzConfig);
    }

    function setLayerZeroConfig(address messenger, IHomechainOmnichainMessenger.LzConfig calldata lzConfig)
        external
        onlyOwner
    {
        IHomechainOmnichainMessenger(messenger).setLayerZeroConfig(lzConfig);
    }

    function setFeePool(address index, address feePool) external onlyOwner {
        IIndex(index).setFeePool(feePool);
    }

    function setPriceSourceMapper(address priceOracleDeployer, address mapper) external onlyOwner {
        IPriceOracleDeployer(priceOracleDeployer).setPriceSourceMapper(mapper);
    }

    function setSequencerUptimeFeed(address priceOracleDeployer, address feed) external onlyOwner {
        IPriceOracleDeployer(priceOracleDeployer).setSequencerUptimeFeed(feed);
    }

    function registerChain(address configBuilder, uint256 chainId) external onlyOwner {
        IConfigBuilder(configBuilder).registerChain(chainId);
    }

    function registerCurrencies(address index, address messenger, Currency[] calldata currencies) external onlyOwner {
        IHomechainOmnichainMessenger(messenger).currenciesUpdated(IIndex(index).registerCurrencies(currencies));
    }

    function migrateConfig(address newConfigBuilder, IConfigMigration.State calldata state) external onlyOwner {
        IConfigMigration(newConfigBuilder).setState(state);

        emit SetConfigBuilder(newConfigBuilder);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVault} from "./IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IIndex is IVault {
    struct IndexState {
        uint128 totalSupply;
        uint96 fees;
        uint32 lastAUMAccrualTimestamp;
        uint96 reserve;
    }

    struct Config {
        uint256 latestSnapshot; // needed to get the latest k value
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address staticPriceOracle;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct DepositConfig {
        Config shared;
        FeeConfig fee;
    }

    struct RedemptionConfig {
        Config shared;
        FeeConfig fee;
        address forwarder;
        a160u96[] homeCurrencies; // Reserve currency + Vault's currencies
    }

    struct DepositParams {
        DepositConfig config;
        address recipient;
        bytes payload;
    }

    struct RedemptionParams {
        RedemptionConfig config;
        address owner;
        uint128 shares;
        bytes payload;
    }

    struct RedemptionInfo {
        uint256 reserveValuation;
        uint256 totalValuation;
        uint256 totalReserveShares;
        uint128 totalSupplyAfterAUMAccrual;
        uint256 totalKBeforeRedeem;
        uint256 accountBalanceSharesBeforeRedeem;
        uint96 accountReserveRedeemed;
        uint256 accountReserveSharesRedeemed;
        uint256 accountKRedeemed;
        uint256 reservePriceInQ128;
    }

    error IndexConfigHash();
    error IndexConfigMismatch();
    error IndexInitialConfig();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error ZeroAddressTransfer();
    error InvalidSender();
    error ZeroDeposit();

    function deposit(DepositParams calldata params, address cbTarget, bytes calldata cbData)
        external
        payable
        returns (uint256 shares);

    function redeem(RedemptionParams calldata params, address forwardedSender, address recipient)
        external
        returns (RedemptionInfo memory redeemed);

    function startIndexRebalancing() external;

    function setConfig(
        Config calldata _prevConfig,
        DepositConfig calldata _depositConfig,
        RedemptionConfig calldata _redemptionConfig
    ) external;

    function setFeePool(address feePool) external;

    function accrueFee(address recipient) external;

    function reserve() external view returns (Currency);
    function reserveBalance() external view returns (uint96);
    function kSelf() external view returns (uint256);
    function fees() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IIndex} from "./IIndex.sol";
import {IVault} from "./IVault.sol";
import {ICurrencyMetadata} from "./ICurrencyMetadata.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IConfigBuilder {
    struct Anatomy {
        uint256[] chainIdSet;
        uint256[][] currencyIdSets;
    }

    struct SharedConfig {
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct Config {
        SharedConfig shared;
        FeeConfig depositFee;
        FeeConfig redemptionFee;
    }

    struct StartReserveRebalancingParams {
        Anatomy anatomy;
        uint256[] chainIds;
        Currency[][] currencies;
    }

    struct StartRebalancingParams {
        Anatomy anatomy;
        Anatomy newAnatomy;
        uint256[] chainIds;
        Currency[][] currencies;
        uint256[] newWeights;
        uint256[] orderCounts; // count of orders for current anatomy chains
        bytes payload;
    }

    function startRebalancing(StartRebalancingParams calldata params, bytes calldata data) external payable;

    function startReserveRebalancing(StartReserveRebalancingParams calldata params, bytes calldata data)
        external
        payable;

    function finishRebalancing(IVault.RebalancingResult[] calldata results, IConfigBuilder.Config calldata config)
        external
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function chainRebalancingFinished(uint256 chainId, bytes32 resultHash) external;

    function currenciesUpdated(ICurrencyMetadata.RegisteredMetadata calldata result) external;

    function registerChain(uint256 chainId) external;

    function setMessenger(address _messenger) external;

    function setConfig(IConfigBuilder.Config memory _config)
        external
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function configs(Config calldata _config)
        external
        view
        returns (IIndex.DepositConfig memory deposit, IIndex.RedemptionConfig memory redemption);

    function configHash() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {a160u96} from "../utils/a160u96.sol";

interface IConfigMigration {
    struct State {
        uint8 pendingChainCount;
        uint256[] snapshotChainIndexSet;
        uint256[] weights;
        uint256[] chainIds;
        uint256[] chainIdSet;
        uint256[] activeChainIds;
        bytes32 chainsHash;
        bytes32 configHash;
        bytes32 anatomyHash;
        uint256 latestSnapshot;
        address staticPriceOracle;
        a160u96[] homeCurrencies;
        ChainState[] chainStates;
    }

    struct ChainState {
        bytes32 currenciesHash;
        bytes32 resultHash;
    }

    function setState(State calldata _state) external;
    function getState() external view returns (State memory _state);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOmnichainMessenger} from "./IOmnichainMessenger.sol";
import {IVault} from "./IVault.sol";

import {u16x15} from "../utils/u16x15.sol";
import {RebalancingLib} from "../libraries/RebalancingLib.sol";
import {EscrowCallLib} from "../escrow/libraries/EscrowCallLib.sol";

interface IHomechainOmnichainMessenger is IOmnichainMessenger {
    struct LzConfig {
        u16x15 eIds;
        uint256[] minGas;
    }

    struct Batches {
        address escrow;
        RemoteData[] data;
    }

    struct RemoteData {
        bytes[] callbacks;
        uint256[] additionalGas;
        uint256 airdropAmount;
    }

    struct SendParams {
        LzConfig config;
        Range[] ranges;
        EscrowCallLib.Trade[][] trades;
        EscrowCallLib.Target escrowCallback;
        Batches[] batches;
        address zroPaymentAddress;
        bytes packedRecipient;
    }

    struct Range {
        uint256 start;
        uint256 end;
    }

    struct Retry {
        uint16 eid;
        bytes[] options;
        bytes[] callbacks;
    }

    function configure(address index, address orderBook, address builder) external;

    function setLayerZeroConfig(LzConfig calldata config) external;

    function currenciesUpdated(IVault.RegisterCurrenciesResult calldata result) external;

    function broadcastOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders calldata homeChainOrders,
        bytes32[] calldata chainOrdersHash,
        IVault.CurrencyWithdrawal[] calldata withdrawals,
        bytes calldata lzParams
    ) external payable;

    function broadcastReserveOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders[] calldata chainOrders,
        bytes calldata lzParams
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {a160u96} from "../../utils/a160u96.sol";

interface IPriceOracleDeployer {
    function deploy(uint256[] calldata chainIds, a160u96[][] calldata currencyBalances)
        external
        returns (address staticPriceOracle);

    function setPriceSourceMapper(address _priceSourceMapper) external;

    function setSequencerUptimeFeed(address _feed) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IVault {
    struct CurrencyWithdrawal {
        uint256[] currencyIndexSet;
        uint96[] amounts;
    }

    struct SnapshotAnatomy {
        a160u96[] currencies;
        uint256[] currencyIndexSet;
    }

    struct EndRebalancingParams {
        a160u96[] anatomyCurrencies;
        SnapshotAnatomy newAnatomy;
        CurrencyWithdrawal withdrawals;
        uint256 lastKBalance;
        Currency[] currencies;
    }

    struct RebalancingResult {
        uint256 chainId;
        uint256 snapshot;
        uint256[] currencyIdSet;
        a160u96[] currencies;
    }

    struct RegisterCurrenciesResult {
        Currency[] currencies;
        bytes32 currenciesHash;
    }

    function setOrderBook(address _orderBook) external;
    function setMessenger(address _messenger) external;

    function startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) external;

    function finishRebalancingPhase(EndRebalancingParams calldata params) external returns (bytes32);
    function transferLatestSnapshot(address recipient, uint256 kAmountWads) external returns (uint256);
    function withdraw(uint256 snapshot, uint256 kAmount, address recipient) external;
    function registerCurrencies(Currency[] calldata currencies) external returns (RegisterCurrenciesResult memory);

    function donate(Currency currency, bytes memory data) external;
    function consume(Currency currency, uint96 amount, address target, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

type Currency is address;

using {eq as ==, neq as !=} for Currency global;

function eq(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function neq(Currency currency, Currency other) pure returns (bool) {
    return !eq(currency, other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
/// @author Modified from Uniswap (https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol)
library CurrencyLib {
    using SafeERC20 for IERC20;
    using CurrencyLib for Currency;

    /// @dev Currency wrapper for native currency
    Currency public constant NATIVE = Currency.wrap(address(0));

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when deposit amount exceeds current balance
    error AmountExceedsBalance();

    /// @notice Transfers currency
    ///
    /// @param currency Currency to transfer
    /// @param to Address of recipient
    /// @param amount Currency amount ot transfer
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (amount == 0) return;
        // implementation from
        // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

        bool success;
        if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, freeMemoryPointer, 68, 0, 32)
                    )
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    /// @notice Approves currency
    ///
    /// @param currency Currency to approve
    /// @param spender Address of spender
    /// @param amount Currency amount to approve
    function approve(Currency currency, address spender, uint256 amount) internal {
        if (isNative(currency)) return;
        IERC20(Currency.unwrap(currency)).forceApprove(spender, amount);
    }

    /// @notice Returns the balance of a given currency for a specific account
    ///
    /// @param currency The currency to check
    /// @param account The address of the account
    ///
    /// @return The balance of the specified currency for the given account
    function balanceOf(Currency currency, address account) internal view returns (uint256) {
        return currency.isNative() ? account.balance : IERC20(Currency.unwrap(currency)).balanceOf(account);
    }

    /// @notice Returns the balance of a given currency for this contract
    ///
    /// @param currency The currency to check
    ///
    /// @return The balance of the specified currency for this contract
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        return currency.isNative() ? address(this).balance : IERC20(Currency.unwrap(currency)).balanceOf(address(this));
    }

    /// @notice Checks if the specified currency is the native currency
    ///
    /// @param currency The currency to check
    ///
    /// @return `true` if the specified currency is the native currency, `false` otherwise
    function isNative(Currency currency) internal pure returns (bool) {
        return currency == NATIVE;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IBlockingApp} from "../interfaces/IBlockingApp.sol";
import {IOrderBook} from "../interfaces/IOrderBook.sol";
import {IOmnichainMessenger, Currency} from "../interfaces/IOmnichainMessenger.sol";
import {IVault} from "../interfaces/IVault.sol";

import {GovernanceSignatureChecker} from "./libraries/GovernanceSignatureChecker.sol";

contract Governance is UUPSUpgradeable, OwnableUpgradeable {
    using GovernanceSignatureChecker for GovernanceSignatureChecker.Signature;

    mapping(address => bool) public isSigner;

    uint256 public nonce;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function setIsSigner(address signer, bool _isSigner) external onlyOwner {
        isSigner[signer] = _isSigner;
    }

    function setOrderBook(address vault, address orderBook) external onlyOwner {
        IVault(vault).setOrderBook(orderBook);
    }

    function setEscrowDeployer(address messenger, address escrowDeployer) external onlyOwner {
        IOmnichainMessenger(messenger).setEscrowDeployer(escrowDeployer);
    }

    function setMessenger(address target, address messenger) external onlyOwner {
        IVault(target).setMessenger(messenger);
    }

    function updateFundManager(address orderBook, address fundManager, bool isAllowed) external onlyOwner {
        IOrderBook(orderBook).updateFundManager(fundManager, isAllowed);
    }

    function setPriceOracle(address orderBook, address priceOracle) external onlyOwner {
        IOrderBook(orderBook).setPriceOracle(priceOracle);
    }

    function setMaxSlippageInBP(address orderBook, uint16 maxSlippageInBP) external onlyOwner {
        IOrderBook(orderBook).setMaxSlippageInBP(maxSlippageInBP);
    }

    function setConfig(address messenger, uint16 version, uint16 eid, uint256 configType, bytes calldata config)
        external
        onlyOwner
    {
        IBlockingApp(messenger).setConfig(version, eid, configType, config);
    }

    function setSendVersion(address messenger, uint16 version) external onlyOwner {
        IBlockingApp(messenger).setSendVersion(version);
    }

    function setReceiveVersion(address messenger, uint16 version) external onlyOwner {
        IBlockingApp(messenger).setReceiveVersion(version);
    }

    function forceResumeReceive(address messenger, uint16 srcEid, bytes calldata srcAddress) external onlyOwner {
        IBlockingApp(messenger).forceResumeReceive(srcEid, srcAddress);
    }

    function setTrustedRemote(
        address messenger,
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        IBlockingApp.PoolIds calldata poolIds
    ) external onlyOwner {
        IBlockingApp(messenger).setTrustedRemote(remoteChainId, remoteEid, minGasAmount, path, poolIds);
    }

    function withdrawCurrency(address messenger, Currency currency, address to, uint256 amount) external onlyOwner {
        IOmnichainMessenger(messenger).withdrawCurrency(currency, to, amount);
    }

    function setBridgingInfo(address messenger, IOmnichainMessenger.BridgingInfo[] calldata _infos)
        external
        onlyOwner
    {
        IOmnichainMessenger(messenger).setBridgingInfo(_infos);
    }

    function transferContractOwnership(address owned, address newOwner) external onlyOwner {
        Owned(owned).transferOwnership(newOwner);
    }

    function finishVaultRebalancing(
        address messenger,
        IOrderBook.FinishOrderExecutionParams calldata orderBookParams,
        IVault.EndRebalancingParams calldata params,
        IOmnichainMessenger.SgParams[] calldata sgParams,
        IOmnichainMessenger.LzParams calldata lzParams,
        address refundAddress,
        GovernanceSignatureChecker.Signature calldata sig
    ) external payable {
        if (msg.sender != owner()) {
            sig.checkSignature(
                abi.encode(orderBookParams, params, sgParams, lzParams, payable(refundAddress)), nonce++, isSigner
            );
        }

        IOmnichainMessenger(messenger).finishVaultRebalancing{value: msg.value}(
            orderBookParams, params, sgParams, lzParams, payable(refundAddress)
        );
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

type a160u96 is uint256;

using {addr, unpack, unpackRaw, currency, value, eq as ==, neq as !=} for a160u96 global;

error AddressMismatch(address, address);

function neq(a160u96 a, a160u96 b) pure returns (bool) {
    return !eq(a, b);
}

function eq(a160u96 a, a160u96 b) pure returns (bool) {
    return a160u96.unwrap(a) == a160u96.unwrap(b);
}

function currency(a160u96 packed) pure returns (Currency) {
    return Currency.wrap(addr(packed));
}

function addr(a160u96 packed) pure returns (address) {
    return address(uint160(a160u96.unwrap(packed)));
}

function value(a160u96 packed) pure returns (uint96) {
    return uint96(a160u96.unwrap(packed) >> 160);
}

function unpack(a160u96 packed) pure returns (Currency _curr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _curr = Currency.wrap(address(uint160(raw)));
    _value = uint96(raw >> 160);
}

function unpackRaw(a160u96 packed) pure returns (address _addr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _addr = address(uint160(raw));
    _value = uint96(raw >> 160);
}

library A160U96Factory {
    function create(address _addr, uint96 _value) internal pure returns (a160u96) {
        return a160u96.wrap((uint256(_value) << 160) | uint256(uint160(_addr)));
    }

    function create(Currency _currency, uint96 _value) internal pure returns (a160u96) {
        return create(Currency.unwrap(_currency), _value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

interface ICurrencyMetadata {
    struct RegisteredMetadata {
        uint256 chainId;
        CurrencyMetadata[] metadata;
        bytes32 currenciesHash;
    }

    struct CurrencyMetadata {
        string name;
        string symbol;
        uint8 decimals;
        Currency currency;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOrderBook} from "./IOrderBook.sol";
import {IVault} from "./IVault.sol";
import {IStargateRouter} from "./stargate/IStargateRouter.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IOmnichainMessenger {
    struct BridgingInfo {
        uint256 finalDstChainId;
        Currency localCurrency;
    }

    struct HashedResult {
        uint256 chainId;
        bytes32 hash;
    }

    struct LzParams {
        bytes[] options;
        address zroPaymentAddress;
    }

    struct SgParams {
        IStargateRouter.lzTxObj lzTxObj;
        uint256 minAmountLD;
    }

    function withdrawCurrency(Currency currency, address to, uint256 amount) external;

    function setOrderBook(address orderBook) external;
    function setEscrowDeployer(address escrowDeployer) external;

    function setBridgingInfo(BridgingInfo[] calldata _infos) external;

    function pushIncomingOrders(
        uint256 srcChainId,
        IOrderBook.BoughtOrder[] memory boughtOrders,
        uint256 boughtOrdersTotalAmount,
        Currency currency,
        uint256 receivedAmount
    ) external;

    function finishVaultRebalancing(
        IOrderBook.FinishOrderExecutionParams calldata orderBookParams,
        IVault.EndRebalancingParams calldata params,
        SgParams[] calldata sgParams,
        LzParams calldata lzParams,
        address payable refundAddress
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

type u16x15 is uint256;

using {length, at} for u16x15 global;

function at(u16x15 packed, uint256 index) pure returns (uint16 value) {
    assembly ("memory-safe") {
        value := shr(mul(index, 16), packed)
    }
}

function length(u16x15 packed) pure returns (uint256 value) {
    assembly ("memory-safe") {
        value := shr(240, packed)
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Currency} from "./CurrencyLib.sol";
import {BitSet} from "./BitSet.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OrderLib} from "./OrderLib.sol";
import {PriceLib} from "../price-oracles/libraries/PriceLib.sol";
import {StackLib} from "./StackLib.sol";

import {IVault} from "../interfaces/IVault.sol";
import {IConfigBuilder} from "../interfaces/IConfigBuilder.sol";

/// @title RebalancingLib
/// @notice Library for managing order creation during rebalancing
library RebalancingLib {
    using SafeCastLib for *;
    using BitSet for *;
    using FixedPointMathLib for *;
    using PriceLib for *;
    using StackLib for StackLib.Node;

    /// @dev Represents the orders for a specific chain
    struct ChainOrders {
        OrderLib.Order[] orders;
        uint128 incomingOrders;
    }

    /// @dev Represents the valuation information for the assets
    struct ValuationInfo {
        uint96[] balances;
        uint256[] prices;
        uint256 totalValuation;
    }

    /// @dev Represents the result of the rebalancing process
    struct RebalancingResult {
        ChainOrders[] chainOrders;
        IVault.CurrencyWithdrawal[] withdrawals;
        uint256[] chainIdSet;
        uint256[] counters;
    }

    struct RebalancingVars {
        StackLib.Node sellDeltas;
        StackLib.Node buyDeltas;
        uint256 targetInBase;
        uint256 currentInBase;
        uint256 i;
        uint256 j;
        uint256 priorChainIndex;
        uint256 activeChainIndex;
        uint256 currencyIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
        bytes32 currenciesHash;
        uint256[] counters;
        bool priorChain;
        bool activeChain;
        bool priorAsset;
    }

    struct ReserveRebalancingVars {
        uint256 orderCount;
        uint96 utilized;
        uint256 i;
        uint256 j;
        uint256 lastIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
    }

    uint256 internal constant MAX_WEIGHT = type(uint16).max;

    /// @notice Thrown when the currencies hash does not match the expected value
    /// @param chainId The chainId that the hash is associated with
    error CurrenciesHashMismatch(uint256 chainId);

    /// @notice Thrown when the total weight of the rebalancing weights is not equal to MAX_WEIGHT
    error TotalWeight();

    /// @notice Thrown when there are unutilized weights in the rebalancing weights
    error UnutilizedWeights();

    /// @notice Thrown when the chains hash does not match the expected value
    error ChainsHashMismatch();

    /// @notice Previews the rebalancing orders based on the given parameters
    ///
    /// @param currenciesHashOf The mapping of chain IDs to their currencies hash
    /// @param valuationInfo The valuation information for the assets
    /// @param params The start rebalancing parameters
    /// @param chainsHash The expected hash of the chain IDs
    ///
    /// @return result The rebalancing result containing the chain orders, withdrawals, and counters
    function previewRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        ValuationInfo memory valuationInfo,
        IConfigBuilder.StartRebalancingParams calldata params,
        bytes32 chainsHash
    ) internal view returns (RebalancingResult memory result) {
        result.chainIdSet = params.anatomy.chainIdSet.addAll(params.newAnatomy.chainIdSet);
        result.chainOrders = new ChainOrders[](result.chainIdSet.size());
        result.withdrawals = new IVault.CurrencyWithdrawal[](result.chainOrders.length);

        result.counters = new uint256[](result.chainOrders.length);

        RebalancingVars memory vars;
        for (; vars.i < params.chainIds.length;) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            vars.priorChain = params.anatomy.chainIdSet.contains(vars.i);
            vars.activeChain = params.newAnatomy.chainIdSet.contains(vars.i);
            if (vars.activeChain || vars.priorChain) {
                if (vars.priorChain) {
                    result.chainOrders[vars.orderIndex].orders =
                        new OrderLib.Order[](params.orderCounts[vars.orderIndex]);
                    result.withdrawals[vars.orderIndex] = IVault.CurrencyWithdrawal(
                        BitSet.create(params.currencies[vars.orderIndex].length),
                        new uint96[](params.anatomy.currencyIdSets[vars.priorChainIndex].size())
                    );
                }

                IVault.CurrencyWithdrawal memory withdrawal = result.withdrawals[vars.orderIndex];

                vars.currenciesHash = bytes32(0);
                Currency[] calldata currencies = params.currencies[vars.orderIndex];
                for (vars.j = 0; vars.j < currencies.length;) {
                    vars.currenciesHash = keccak256(abi.encode(vars.currenciesHash, currencies[vars.j]));
                    vars.priorAsset =
                        vars.priorChain && params.anatomy.currencyIdSets[vars.priorChainIndex].contains(vars.j);

                    vars.targetInBase = vars.activeChain
                        && params.newAnatomy.currencyIdSets[vars.activeChainIndex].contains(vars.j)
                        ? valuationInfo.totalValuation.mulDivUp(params.newWeights[vars.weightIndex++], MAX_WEIGHT)
                        : 0;

                    vars.currentInBase = vars.priorAsset
                        ? valuationInfo.balances[vars.currencyIndex].convertToBaseUp(
                            valuationInfo.prices[vars.currencyIndex]
                        )
                        : 0;

                    if (vars.currentInBase < vars.targetInBase) {
                        uint256 delta = vars.targetInBase - vars.currentInBase;
                        vars.buyDeltas =
                            vars.buyDeltas.push(delta, vars.orderIndex, currencies[vars.j], params.chainIds[vars.i]);
                    } else if (vars.currentInBase > vars.targetInBase) {
                        // result will never exceed type(uint96).max.
                        uint96 assets = uint96(
                            valuationInfo.balances[vars.currencyIndex].mulDivDown(
                                vars.currentInBase - vars.targetInBase, vars.currentInBase
                            )
                        );

                        if (assets != 0) {
                            vars.sellDeltas = vars.sellDeltas.push(
                                vars.currentInBase - vars.targetInBase,
                                assets,
                                vars.orderIndex,
                                currencies[vars.j],
                                valuationInfo.prices[vars.currencyIndex]
                            );

                            withdrawal.amounts[withdrawal.currencyIndexSet.size()] = assets;
                            withdrawal.currencyIndexSet.add(vars.j);
                        }
                    }

                    unchecked {
                        if (vars.priorAsset) ++vars.currencyIndex;
                        ++vars.j;
                    }
                }

                if (vars.currenciesHash != currenciesHashOf[vars.i]) {
                    revert CurrenciesHashMismatch(params.chainIds[vars.i]);
                }

                (vars.sellDeltas, vars.buyDeltas) =
                    _createOrders(result.chainOrders, vars.sellDeltas, vars.buyDeltas, result.counters);

                unchecked {
                    if (vars.priorChain) ++vars.priorChainIndex;
                    if (vars.activeChain) ++vars.activeChainIndex;
                    ++vars.orderIndex;
                }
            }

            unchecked {
                ++vars.i;
            }
        }

        if (params.newWeights.length != vars.weightIndex) revert UnutilizedWeights();
        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    /// @notice Previews the reserve rebalancing orders based on the given parameters
    ///
    /// @param currenciesHashOf The mapping of chain IDs to their currencies hash
    /// @param weights The array of weights for the reserve assets
    /// @param params The start reserve rebalancing parameters
    /// @param reserveAmount The total amount of reserve assets
    /// @param reserve The reserve currency
    /// @param chainsHash The expected hash of the chain IDs
    ///
    /// @return orders The array of chain orders for the reserve rebalancing
    function previewReserveRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        uint256[] memory weights,
        IConfigBuilder.StartReserveRebalancingParams calldata params,
        uint96 reserveAmount,
        Currency reserve,
        bytes32 chainsHash
    ) internal view returns (ChainOrders[] memory orders) {
        orders = new ChainOrders[](params.anatomy.chainIdSet.size());

        ReserveRebalancingVars memory vars;
        vars.orderCount = weights.length;
        vars.lastIndex = vars.orderCount - 1;

        orders[0].orders = new OrderLib.Order[](vars.orderCount);

        for (; vars.i < params.chainIds.length; ++vars.i) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            if (!params.anatomy.chainIdSet.contains(vars.i)) continue;

            bytes32 currenciesHash;
            Currency[] calldata currencies = params.currencies[vars.orderIndex];
            for (vars.j = 0; vars.j < currencies.length; ++vars.j) {
                currenciesHash = keccak256(abi.encode(currenciesHash, currencies[vars.j]));

                if (params.anatomy.currencyIdSets[vars.orderIndex].contains(vars.j)) {
                    uint96 orderSellAmount = vars.weightIndex == vars.lastIndex
                        ? reserveAmount - vars.utilized
                        : reserveAmount.mulDivDown(weights[vars.weightIndex], MAX_WEIGHT).safeCastTo96();
                    orders[0].orders[vars.weightIndex] = OrderLib.Order(
                        orderSellAmount,
                        OrderLib.OrderId(reserve, currencies[vars.j], currencies[vars.j], params.chainIds[vars.i])
                    );

                    unchecked {
                        if (vars.orderIndex != 0 && orderSellAmount != 0) {
                            ++orders[vars.orderIndex].incomingOrders;
                        }
                        vars.utilized += orderSellAmount;
                        ++vars.weightIndex;
                    }
                }
            }

            if (currenciesHash != currenciesHashOf[vars.i]) revert CurrenciesHashMismatch(params.chainIds[vars.i]);

            unchecked {
                ++vars.orderIndex;
            }
        }

        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    /// @notice Checks if the total weight is equal to the maximum weight
    ///
    /// @dev This function reverts if the sum of the weights is not equal to MAX_WEIGHT
    ///
    /// @param weights The array of weights to check
    function checkTotalWeight(uint256[] calldata weights) internal pure {
        uint256 total;
        for (uint256 i; i < weights.length; ++i) {
            total += weights[i];
        }
        if (total != MAX_WEIGHT) revert TotalWeight();
    }

    /// @dev Creates the rebalancing orders by matching sell and buy deltas
    ///
    /// @param orders The array of chain orders to populate
    /// @param sellDeltas The stack of sell deltas
    /// @param buyDeltas The stack of buy deltas
    /// @param counters The array of order counters for each chain
    ///
    /// @return The updated sell and buy delta stacks after creating the orders
    function _createOrders(
        ChainOrders[] memory orders,
        StackLib.Node memory sellDeltas,
        StackLib.Node memory buyDeltas,
        uint256[] memory counters
    ) internal pure returns (StackLib.Node memory, StackLib.Node memory) {
        // while one of lists is not empty
        while (sellDeltas.notEmpty() && buyDeltas.notEmpty()) {
            // get first nodes from both lists
            StackLib.Data memory sell = sellDeltas.peek();
            StackLib.Data memory buy = buyDeltas.peek();

            uint256 fill = Math.min(sell.delta, buy.delta);
            sell.delta -= fill;
            buy.delta -= fill;

            uint256 sellAmount = Math.min(fill.convertToAssetsUp(sell.data), sell.availableAssets);
            sell.availableAssets -= sellAmount;

            orders[sell.orderIndex].orders[counters[sell.orderIndex]++] = OrderLib.Order(
                sellAmount.safeCastTo96(), OrderLib.OrderId(sell.currency, buy.currency, buy.currency, buy.data)
            );

            // increment "fence" counter
            if (buy.orderIndex != sell.orderIndex && sellAmount != 0) {
                ++orders[buy.orderIndex].incomingOrders;
            }

            // remove nodes with zero delta. Notice, both deltas can be set to zero.
            if (sell.delta == 0) {
                sellDeltas = sellDeltas.pop();
            }
            if (buy.delta == 0) {
                buyDeltas = buyDeltas.pop();
            }
        }

        return (sellDeltas, buyDeltas);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {CurrencyLib, Currency} from "src/libraries/CurrencyLib.sol";

library EscrowCallLib {
    using CurrencyLib for Currency;

    struct Trade {
        bool skipRevert;
        Currency currency;
        address allowanceTarget;
        address addr;
        uint256 value;
        bytes data;
    }

    struct Target {
        bool skipRevert;
        address addr;
        uint256 value;
        bytes data;
    }

    error SelfCall();
    error TradeFailed();
    error TargetFailed();

    function callNotSelf(Trade memory self) internal {
        if (self.addr == address(this)) revert SelfCall();

        uint256 balance = self.currency.balanceOfSelf();
        bool approve = self.allowanceTarget != address(0) && balance != 0;
        if (approve) self.currency.approve(self.allowanceTarget, balance);

        // if currency is Native and no value passed - use current balance as value
        if (self.currency.isNative() && self.value == 0) self.value = balance;

        (bool success, bytes memory returnData) = self.addr.call{value: self.value}(self.data);
        if (!self.skipRevert && !success) {
            if (returnData.length == 0) revert TradeFailed();

            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        if (approve) self.currency.approve(self.allowanceTarget, 0);
    }

    function callNotSelf(Target memory self) internal {
        if (self.addr == address(this)) revert SelfCall();

        (bool success, bytes memory returnData) = self.addr.call{value: self.value}(self.data);
        if (!self.skipRevert && !success) {
            if (returnData.length == 0) revert TargetFailed();

            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ILayerZeroReceiver} from "layerzero/interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "layerzero/interfaces/ILayerZeroUserApplicationConfig.sol";

interface IBlockingApp is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    struct PoolIds {
        uint128 src;
        uint128 dst;
    }

    function setConfig(uint16 version, uint16 eid, uint256 configType, bytes calldata config) external;

    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function setTrustedRemote(
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        PoolIds calldata poolIds
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {OrderLib} from "../libraries/OrderLib.sol";

/// @title IOrderBook interface
interface IOrderBook {
    struct TradeParams {
        address target;
        bytes data;
    }

    struct BoughtOrder {
        // Bought amount of local buy currency, sell amount on the remote
        uint256 amount;
        // Buy currency on the remote
        Currency buyCurrency;
    }

    struct PendingOrder {
        uint256 chainId;
        Currency currency;
        uint256 totalBought;
        BoughtOrder[] orders;
    }

    struct FinishOrderExecutionParams {
        OrderLib.OrderId[] orderIds;
        uint256[] idIndices;
        uint256[] pendingOrderCounts;
    }

    struct ExecuteOrderParams {
        OrderLib.OrderId orderId;
        uint96 sell;
        TradeParams tradeParams;
        bytes payload;
    }

    event OrderFilled(bytes32 indexed id, uint256 sold, uint256 bought);

    function receiveIncomingOrders(OrderLib.Order[] calldata orders, Currency currency, uint256 amount) external;
    function removeDustOrders(uint256 _incomingOrders) external;

    function setOrders(uint256 _incomingOrders, OrderLib.Order[] calldata orders) external;

    /// @notice Execute the given local order
    /// @param params Execute order data
    function executeOrder(ExecuteOrderParams calldata params) external;

    function finishOrderExecution(FinishOrderExecutionParams calldata params)
        external
        returns (PendingOrder[] memory pendingOrders);

    function updateFundManager(address fundManager, bool isAllowed) external;

    function setMessenger(address messenger) external;

    function setPriceOracle(address priceOracle) external;

    function setMaxSlippageInBP(uint16 maxSlippageInBP) external;

    function orderOf(OrderLib.OrderId calldata orderIdParams) external view returns (uint96 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {ECDSA} from "solady/utils/ECDSA.sol";

library GovernanceSignatureChecker {
    struct Signature {
        bytes32 r;
        bytes32 vs;
        uint256 deadline;
    }

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,uint256 nonce,uint256 deadline)")
    bytes32 internal constant DOMAIN_HASH = hex"479bd6f425c042dfaa9ed75259de375d9761f9e3c091a2e704d5fe0d3ad6b478";
    // keccak256(bytes("GovernanceSignatureChecker"))
    bytes32 internal constant NAME_HASH = hex"3f1c186694ebb44ae5cdc1c198dc51d2680cd5825c19c47eaa41a4560808bb00";
    // keccak256(bytes("1"))
    bytes32 internal constant VERSION_HASH = hex"c89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6";

    error InvalidSigner();
    error Expired();

    function checkSignature(
        Signature calldata sig,
        bytes memory data,
        uint256 nonce,
        mapping(address => bool) storage isSigner
    ) internal {
        if (block.timestamp > sig.deadline) revert Expired();

        bytes32 eip712DomainHash = keccak256(
            abi.encode(DOMAIN_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this), nonce, sig.deadline)
        );

        address signer =
            ECDSA.recover(keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, keccak256(data))), sig.r, sig.vs);

        if (!isSigner[signer]) revert InvalidSigner();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall; // extra gas, if calling smart contract,
        uint256 dstNativeAmount; // amount of dust dropped in destination wallet
        bytes dstNativeAddr; // destination wallet for dust
    }

    function swap(
        uint16 _dstEid,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstEid,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title BitSet
/// @notice A library for managing bitsets
library BitSet {
    uint256 private constant WORD_SHIFT = 8;

    /// @notice Checks if the next bit is set in the given word starting from the given bit position
    ///
    /// @param word The word to check
    /// @param bit The bit position
    ///
    /// @return r True if the next bit is set, false otherwise
    function hasNext(uint256 word, uint256 bit) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := and(shr(bit, word), 1)
        }
    }

    /// @notice Finds the position of the next set bit in the given word starting from the given bit position
    ///
    /// @dev This function uses a lookup table approach to find the position of the next set bit.
    ///      It first shifts the word right by the given bit position and then checks the lower 3 bits
    ///      of the resulting word to determine the position of the next set bit.
    ///      If no set bit is found, it returns 256 to indicate that there are no more set bits.
    ///
    /// @param word The word to search
    /// @param b The starting bit position
    ///
    /// @return nb The position of the next set bit
    function find(uint256 word, uint256 b) internal pure returns (uint256 nb) {
        assembly ("memory-safe") {
            let w := shr(b, word)
            switch w
            case 0 {
                // no more bits
                nb := 256
            }
            default {
                // 0b000 = 0
                // 0b001 = 1
                // 0b010 = 2
                // 0b011 = 3
                // 0b100 = 4
                // 0b101 = 5
                // 0b110 = 6
                // 0b111 = 7
                switch and(w, 7)
                case 0 { nb := add(lsb(w), b) }
                case 2 { nb := add(b, 1) }
                case 4 { nb := add(b, 2) }
                case 6 { nb := add(b, 1) }
                default { nb := b }
            }

            function lsb(x) -> r {
                if iszero(x) { revert(0, 0) }
                r := 255
                switch gt(and(x, 0xffffffffffffffffffffffffffffffff), 0)
                case 1 { r := sub(r, 128) }
                case 0 { x := shr(128, x) }

                switch gt(and(x, 0xffffffffffffffff), 0)
                case 1 { r := sub(r, 64) }
                case 0 { x := shr(64, x) }

                switch gt(and(x, 0xffffffff), 0)
                case 1 { r := sub(r, 32) }
                case 0 { x := shr(32, x) }

                switch gt(and(x, 0xffff), 0)
                case 1 { r := sub(r, 16) }
                case 0 { x := shr(16, x) }

                switch gt(and(x, 0xff), 0)
                case 1 { r := sub(r, 8) }
                case 0 { x := shr(8, x) }

                switch gt(and(x, 0xf), 0)
                case 1 { r := sub(r, 4) }
                case 0 { x := shr(4, x) }

                switch gt(and(x, 0x3), 0)
                case 1 { r := sub(r, 2) }
                case 0 { x := shr(2, x) }

                switch gt(and(x, 0x1), 0)
                case 1 { r := sub(r, 1) }
            }
        }
    }

    /// @notice Computes the value at the given word index and bit position
    ///
    /// @param wordIndex The index of the word
    /// @param bit The bit position within the word
    ///
    /// @return r The computed value
    function valueAt(uint256 wordIndex, uint256 bit) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := or(shl(8, wordIndex), bit)
        }
    }

    /// @notice Creates a new bitset with the given maximum size
    ///
    /// @param maxSize The maximum size of the bitset
    ///
    /// @return bitset The created bitset
    function create(uint256 maxSize) internal pure returns (uint256[] memory bitset) {
        bitset = new uint256[](_capacity(maxSize));
    }

    /// @notice Checks if the given value is contained in the bitset
    ///
    /// @param bitset The bitset to check
    /// @param value The value to search for
    ///
    /// @return _contains True if the value is contained in the bitset, false otherwise
    function contains(uint256[] memory bitset, uint256 value) internal pure returns (bool _contains) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        if (wordIndex < bitset.length) {
            _contains = (bitset[wordIndex] & (1 << bit)) != 0;
        }
    }

    /// @notice Adds the given value to the bitset
    ///
    /// @param bitset The bitset to modify
    /// @param value The value to add
    ///
    /// @return The modified bitset
    function add(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] |= (1 << bit);
        return bitset;
    }

    /// @notice Adds all elements from bitset b to bitset a
    ///
    /// @param a The destination bitset
    /// @param b The source bitset
    ///
    /// @return c The resulting bitset
    function addAll(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory c) {
        (uint256 min, uint256 max) = a.length < b.length ? (a.length, b.length) : (b.length, a.length);
        c = new uint256[](max);
        uint256 i;
        for (; i < min; ++i) {
            c[i] = a[i] | b[i];
        }
        // copy leftover elements from a
        for (; i < a.length; ++i) {
            c[i] = a[i];
        }
        // copy leftover elements from b
        for (; i < b.length; ++i) {
            c[i] = b[i];
        }
    }

    /// @notice Removes the given value from the bitset
    ///
    /// @param bitset The bitset to modify
    /// @param value The value to remove
    ///
    /// @return The modified bitset
    function remove(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] &= ~(1 << bit);
        return bitset;
    }

    /// @notice Computes the size (number of set bits) of the bitset
    ///
    /// @param bitset The bitset to compute the size of
    ///
    /// @return count The number of set bits in the bitset
    function size(uint256[] memory bitset) internal pure returns (uint256 count) {
        for (uint256 i; i < bitset.length; ++i) {
            count += _countSetBits(bitset[i]);
        }
    }

    /// @dev Computes the word index and bit position for the given value
    ///
    /// @param value The value to compute the offsets for
    ///
    /// @return wordIndex The index of the word containing the value
    /// @return bit The bit position within the word
    function _bitOffset(uint256 value) private pure returns (uint256 wordIndex, uint8 bit) {
        assembly ("memory-safe") {
            wordIndex := shr(8, value)
            // mask bits that don't fit the first wordIndex's bits
            // n % 2^i = n & (2^i - 1)
            bit := and(value, 255)
        }
    }

    /// @dev Computes the number of words required to store the given maximum size
    ///
    /// @param maxSize The maximum size of the bitset
    ///
    /// @return words The number of words required
    function _capacity(uint256 maxSize) private pure returns (uint256 words) {
        // round up
        words = (maxSize + type(uint8).max) >> WORD_SHIFT;
    }

    /// @dev Counts the number of set bits in the given word using Brian Kernighan's algorithm
    ///
    /// @param x The word to count the set bits of
    ///
    /// @return count The number of set bits in the word
    function _countSetBits(uint256 x) private pure returns (uint256 count) {
        // Brian Kernighan's Algorithm
        // This algorithm counts the number of set bits in a word by repeatedly
        // clearing the least significant set bit until the word becomes zero.
        while (x != 0) {
            unchecked {
                // cannot overflow, x > 0
                x = x & (x - 1);
                ++count;
            }
        }
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title OrderLib
/// @notice Library for managing orders
library OrderLib {
    struct OrderId {
        // Sell currency of order
        Currency sellCurrency;
        // Local buy currency of order
        Currency localBuyCurrency;
        // Final destination buy currency of order
        Currency finalDestinationBuyCurrency;
        // Final destination chainId of order
        uint256 finalDestinationChainId;
    }

    struct Order {
        // Sell amount of order
        uint96 sellAmount;
        // Id params of order
        OrderId idParams;
    }

    struct OrderRegistry {
        // Sell amount of given order
        mapping(bytes32 => uint96) orderOf;
        // Hash of registry state
        bytes32 ordersHash;
    }

    /// @notice Emitted when a new order is created
    event NewOrder(
        uint256 sellAmount,
        Currency indexed sellCurrency,
        Currency localBuyCurrency,
        Currency indexed finalDestinationBuyCurrency,
        uint256 finalDestinationChainId
    );

    /// @notice Thrown when there's a mismatch in order hashes
    error OrderHashMismatch();

    /// @notice Thrown when an order is not filled
    /// @param id The id of the order that was not filled
    error OrderNotFilled(bytes32 id);

    /// @notice Sets multiple orders in the registry
    ///
    /// @param self The order registry where orders are stored
    /// @param orders An array of orders to set in the registry
    function set(OrderRegistry storage self, Order[] calldata orders) internal {
        bytes32 newHash = self.ordersHash;
        for (uint256 i; i < orders.length; ++i) {
            if (orders[i].sellAmount == 0) continue;

            OrderId calldata params = orders[i].idParams;
            // don't need to create order for the same currency within a single chain, as it's already in the final destination
            if (params.sellCurrency != params.localBuyCurrency || params.finalDestinationChainId != block.chainid) {
                bytes32 idKey = id(params);
                newHash = keccak256(abi.encode(newHash, idKey));
                self.orderOf[idKey] += orders[i].sellAmount;

                emit NewOrder(
                    orders[i].sellAmount,
                    params.sellCurrency,
                    params.localBuyCurrency,
                    params.finalDestinationBuyCurrency,
                    params.finalDestinationChainId
                );
            }
        }
        self.ordersHash = newHash;
    }

    /// @notice Fills a specific order from the registry
    ///
    /// @param self The order registry
    /// @param orderId The id params of the order to fill
    /// @param sell The sell amount of the order
    function fill(OrderRegistry storage self, OrderId calldata orderId, uint96 sell) internal {
        self.orderOf[id(orderId)] -= sell;
    }

    /// @notice Resets the orders in the registry
    ///
    /// @param self The order registry to reset
    ///
    /// @param orderIds An array of order id parameters to reset
    function reset(OrderRegistry storage self, OrderId[] calldata orderIds) internal {
        bytes32 ordersHash;
        for (uint256 i; i < orderIds.length; ++i) {
            bytes32 idKey = id(orderIds[i]);
            ordersHash = keccak256(abi.encode(ordersHash, idKey));

            if (self.orderOf[idKey] != 0) revert OrderNotFilled(idKey);
        }

        if (ordersHash != self.ordersHash) revert OrderHashMismatch();

        self.ordersHash = bytes32(0);
    }

    /// @notice Retrieves the sell amount of a specific order
    /// @param self The order registry
    ///
    /// @param orderId The id parameters of the order to retrieve
    ///
    /// @return The sell amount of the specified order
    function get(OrderRegistry storage self, OrderId calldata orderId) internal view returns (uint96) {
        return self.orderOf[id(orderId)];
    }

    /// @dev Generates a unique id for an order based on its parameters
    ///
    /// @param self The order id parameters
    ///
    /// @return A unique bytes32 id for the order
    function id(OrderId calldata self) internal pure returns (bytes32) {
        return keccak256(abi.encode(self));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title PriceLib
/// @notice A library for handling fixed-point arithmetic for prices
library PriceLib {
    using FixedPointMathLib for uint256;

    /// @dev 2**128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint16 internal constant PRICE_ORACLE_DECIMALS = 18;
    uint256 internal constant DECIMALS_MULTIPLIER = 10 ** PRICE_ORACLE_DECIMALS;

    /// @notice Converts (down) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsDown(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivDown(price, Q128);
    }

    /// @notice Converts (up) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsUp(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivUp(price, Q128);
    }

    /// @notice Converts (down) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseDown(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivDown(Q128, price);
    }

    /// @notice Converts (up) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseUp(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivUp(Q128, price);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title StackLib
/// @notice A library for managing a stack data
library StackLib {
    /// @dev Represents the data held in each stack node
    struct Data {
        // Index of order
        uint256 orderIndex;
        // Currency of order
        Currency currency;
        // Amount of order
        uint256 delta;
        // `price` for sell, `chainId` for buy
        uint256 data;
        // Available asset for sell data, 0 for buy data
        uint256 availableAssets;
    }

    /// @dev Represents a node in the stack
    struct Node {
        // Pointer to the next node
        uint256 next;
        // Value of the node
        Data value;
    }

    /// @notice Pushes a new sell order onto the stack
    ///
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param availableAssets The number of assets available for selling
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param price The price of the assets in the order
    ///
    /// @return newNode The new node created with the given data
    function push(
        Node memory head,
        uint256 delta,
        uint256 availableAssets,
        uint256 orderIndex,
        Currency currency,
        uint256 price
    ) internal pure returns (Node memory newNode) {
        newNode.value = Data(orderIndex, currency, delta, price, availableAssets);

        assembly {
            // Store the address of the current head in the new node's 'next'
            mstore(newNode, head)
        }
    }

    /// @notice Pushes a new buy order onto the stack
    ///
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param chainId The chain ID associated with the buy order
    ///
    /// @return newNode The new node created with the given data
    function push(Node memory head, uint256 delta, uint256 orderIndex, Currency currency, uint256 chainId)
        internal
        pure
        returns (Node memory newNode)
    {
        newNode.value = Data(orderIndex, currency, delta, chainId, 0);

        assembly {
            // Store the address of the current head in the new node's 'next'
            mstore(newNode, head)
        }
    }

    /// @notice Pops the top value from the stack
    ///
    /// @param head The current head of the stack
    ///
    /// @return nextNode The next node in the stack after popping
    function pop(Node memory head) internal pure returns (Node memory nextNode) {
        assembly {
            // Load the address of the next node (which head points to)
            nextNode := mload(head)
        }
    }

    /// @notice Checks if the stack is not empty
    ///
    /// @param head The head of the stack to check
    ///
    /// @return `true` if the stack is not empty, `false` otherwise
    function notEmpty(Node memory head) internal pure returns (bool) {
        return head.next != 0 || head.value.delta != 0;
    }

    /// @notice Retrieves the value of the top node of the stack
    ///
    /// @param head The head of the stack
    ///
    /// @return The data value of the top node of the stack
    function peek(Node memory head) internal pure returns (Data memory) {
        return head.value;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
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
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
///
/// @dev Note:
/// - The recovery functions use the ecrecover precompile (0x1).
/// - As of Solady version 0.0.68, the `recover` variants will revert upon recovery failure.
///   This is for more safety by default.
///   Use the `tryRecover` variants if you need to get the zero address back
///   upon recovery failure instead.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The signature is invalid.
    error InvalidSignature();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recover(bytes32 hash, bytes memory signature) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TRY-RECOVER OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // WARNING!
    // These functions will NOT revert upon recovery failure.
    // Instead, they will return the zero address upon recovery failure.
    // It is critical that the returned address is NEVER compared against
    // a zero address (e.g. an uninitialized address variable).

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
}