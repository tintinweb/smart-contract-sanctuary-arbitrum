// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IConfigurable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getConfig(bytes32 configKey) external view returns (bytes32);

    function setConfig(bytes32 configKey, bytes32 value) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./LibTypeCast.sol";

struct ConfigSet {
    mapping(bytes32 => bytes32) values;
}

library LibConfigSet {
    using LibTypeCast for bytes32;
    using LibTypeCast for address;
    using LibTypeCast for uint256;
    using LibTypeCast for bool;

    event SetValue(bytes32 key, bytes32 value);
    error InvalidAddress(bytes32 key);

    // ================================== single functions ======================================
    function setBytes32(ConfigSet storage store, bytes32 key, bytes32 value) internal {
        store.values[key] = value;
        emit SetValue(key, value);
    }

    function getBytes32(ConfigSet storage store, bytes32 key) internal view returns (bytes32) {
        return store.values[key];
    }

    function getUint256(ConfigSet storage store, bytes32 key) internal view returns (uint256) {
        return store.values[key].toUint256();
    }

    function getAddress(ConfigSet storage store, bytes32 key) internal view returns (address) {
        return store.values[key].toAddress();
    }

    function mustGetAddress(ConfigSet storage store, bytes32 key) internal view returns (address) {
        address a = getAddress(store, key);
        if (a == address(0)) {
            revert InvalidAddress(key);
        }
        return a;
    }

    function getBoolean(ConfigSet storage store, bytes32 key) internal view returns (bool) {
        return store.values[key].toBoolean();
    }

    function toBytes32(address a) internal pure returns (bytes32) {
        return bytes32(bytes20(a));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

bytes32 constant WETH_TOKEN = keccak256("WETH_TOKEN");
bytes32 constant SMLP_TOKEN = keccak256("SMLP_TOKEN");
bytes32 constant MUX_TOKEN = keccak256("MUX_TOKEN");
bytes32 constant MCB_TOKEN = keccak256("MCB_TOKEN");
bytes32 constant MLP_TOKEN = keccak256("MLP_TOKEN");

// ======================================== JuniorVault ========================================
bytes32 constant MUX_REWARD_ROUTER = keccak256("MUX_REWARD_ROUTER");
bytes32 constant MUX_LIQUIDITY_POOL = keccak256("MUX_LIQUIDITY_POOL");
bytes32 constant ASSET_SUPPLY_CAP = keccak256("ASSET_SUPPLY_CAP");

// ======================================== SeniorVault ========================================
bytes32 constant LOCK_TYPE = keccak256("LOCK_TYPE");
bytes32 constant LOCK_PERIOD = keccak256("LOCK_PERIOD");
bytes32 constant LOCK_PENALTY_RATE = keccak256("LOCK_PENALTY_RATE");
bytes32 constant LOCK_PENALTY_RECIPIENT = keccak256("LOCK_PENALTY_RECIPIENT");
bytes32 constant MAX_BORROWS = keccak256("MAX_BORROWS");
// bytes32 constant ASSET_SUPPLY_CAP = keccak256("ASSET_SUPPLY_CAP");

// ======================================== Router ========================================
bytes32 constant TARGET_LEVERAGE = keccak256("TARGET_LEVERAGE");
bytes32 constant REBALANCE_THRESHOLD = keccak256("REBALANCE_THRESHOLD");
bytes32 constant REBALANCE_THRESHOLD_USD = keccak256("REBALANCE_THRESHOLD_USD");
// bytes32 constant MUX_LIQUIDITY_POOL = keccak256("MUX_LIQUIDITY_POOL");
bytes32 constant LIQUIDATION_LEVERAGE = keccak256("LIQUIDATION_LEVERAGE"); // 10%
bytes32 constant MUX_ORDER_BOOK = keccak256("MUX_ORDER_BOOK");

// ======================================== ROLES ========================================
bytes32 constant DEFAULT_ADMIN = 0;
bytes32 constant HANDLER_ROLE = keccak256("HANDLER_ROLE");
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

//==================
uint256 constant ONE = 1e18;

// ======================================== AAVE =========================================
bytes32 constant AAVE_POOL = keccak256("AAVE_POOL");
bytes32 constant AAVE_TOKEN = keccak256("AAVE_TOKEN");
bytes32 constant AAVE_REWARDS_CONTROLLER = keccak256("AAVE_REWARDS_CONTROLLER");
bytes32 constant AAVE_EXTRA_REWARD_TOKEN = keccak256("AAVE_EXTRA_REWARD_TOKEN");

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

library LibTypeCast {
    bytes32 private constant ADDRESS_GUARD_MASK =
        0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;

    function toAddress(bytes32 v) internal pure returns (address) {
        require(v & ADDRESS_GUARD_MASK == 0, "LibTypeCast::INVALID");
        return address(bytes20(v));
    }

    function toBytes32(address v) internal pure returns (bytes32) {
        return bytes32(bytes20(v));
    }

    function toUint256(bytes32 v) internal pure returns (uint256) {
        return uint256(v);
    }

    function toBytes32(uint256 v) internal pure returns (bytes32) {
        return bytes32(v);
    }

    function toBoolean(bytes32 v) internal pure returns (bool) {
        uint256 n = toUint256(v);
        require(n == 0 || n == 1, "LibTypeCast::INVALID");
        return n == 1;
    }

    function toBytes32(bool v) internal pure returns (bytes32) {
        return toBytes32(v ? 1 : 0);
    }

    function toUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "LibTypeCast::OVERFLOW");
        return uint96(n);
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "LibTypeCast::OVERFLOW");
        return uint32(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../interfaces/IConfigurable.sol";
import "../libraries/LibTypeCast.sol";
import "./Type.sol";

/**
 * @title SeniorConfig
 * @notice SeniorConfig is designed to assist administrators in managing variables within the Mux Tranche Protocol.
 * However, it is not a mandatory component, as users can still directly use the setConfig interface and Key-Value (KV) approach to configure and customize the protocol settings. \
 * The SeniorConfig module provides an additional layer of convenience and flexibility for administrators to manage and update the protocol's variables.
 */
contract SeniorConfig {
    using LibTypeCast for bytes32;
    using LibTypeCast for uint256;
    using LibTypeCast for address;

    IConfigurable public seniorVault;

    modifier onlyAdmin() {
        require(seniorVault.hasRole(DEFAULT_ADMIN, msg.sender), "SeniorConfig::ADMIN_ONLY");
        _;
    }

    constructor(address configurable_) {
        require(configurable_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault = IConfigurable(configurable_);
    }

    function lockPeriod() public view virtual returns (uint256) {
        return seniorVault.getConfig(LOCK_PERIOD).toUint256();
    }

    function lockPenaltyRate() public view virtual returns (uint256) {
        return seniorVault.getConfig(LOCK_PENALTY_RATE).toUint256();
    }

    function lockPenaltyRecipient() public view virtual returns (address) {
        return seniorVault.getConfig(LOCK_PENALTY_RECIPIENT).toAddress();
    }

    function maxBorrows() public view virtual returns (uint256) {
        return seniorVault.getConfig(MAX_BORROWS).toUint256();
    }

    function maxBorrowsByVault(address vault) public view virtual returns (uint256) {
        return seniorVault.getConfig(keccak256(abi.encode(MAX_BORROWS, vault))).toUint256();
    }

    function aavePool() public view virtual returns (address) {
        return seniorVault.getConfig(AAVE_POOL).toAddress();
    }

    function aaveToken() public view virtual returns (address) {
        return seniorVault.getConfig(AAVE_TOKEN).toAddress();
    }

    function aaveRewardsController() public view virtual returns (address) {
        return seniorVault.getConfig(AAVE_REWARDS_CONTROLLER).toAddress();
    }

    function aaveExtraRewardToken() public view virtual returns (address) {
        return seniorVault.getConfig(AAVE_EXTRA_REWARD_TOKEN).toAddress();
    }

    function assetSupplyCap() public view virtual returns (uint256) {
        return seniorVault.getConfig(ASSET_SUPPLY_CAP).toUint256();
    }

    function setLockPeriod(uint256 lockPeriod_) public virtual onlyAdmin {
        seniorVault.setConfig(LOCK_PERIOD, lockPeriod_.toBytes32());
    }

    function setLockPenaltyRate(uint256 lockPenaltyRate_) public virtual onlyAdmin {
        require(lockPenaltyRate_ <= ONE, "SeniorConfig::INVALID_RATE");
        seniorVault.setConfig(LOCK_PENALTY_RATE, lockPenaltyRate_.toBytes32());
    }

    function setLockPenaltyRecipient(address lockPenaltyRecipient_) public virtual onlyAdmin {
        require(lockPenaltyRecipient_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(LOCK_PENALTY_RECIPIENT, lockPenaltyRecipient_.toBytes32());
    }

    function setMaxBorrows(uint256 maxBorrows_) public virtual onlyAdmin {
        seniorVault.setConfig(MAX_BORROWS, maxBorrows_.toBytes32());
    }

    function setMaxBorrowsByVault(address vault, uint256 maxBorrows_) public virtual onlyAdmin {
        require(vault != address(0), "JuniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(keccak256(abi.encode(MAX_BORROWS, vault)), maxBorrows_.toBytes32());
    }

    function setAssetSupplyCap(uint256 newAssetCap) public virtual onlyAdmin {
        seniorVault.setConfig(ASSET_SUPPLY_CAP, newAssetCap.toBytes32());
    }

    function setAavePool(address aavePool_) public virtual onlyAdmin {
        require(aavePool_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(AAVE_POOL, aavePool_.toBytes32());
    }

    function setAaveToken(address aaveToken_) public virtual onlyAdmin {
        require(aaveToken_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(AAVE_TOKEN, aaveToken_.toBytes32());
    }

    function setAaveRewardsController(address aaveRewardsController_) public virtual onlyAdmin {
        require(aaveRewardsController_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(AAVE_REWARDS_CONTROLLER, aaveRewardsController_.toBytes32());
    }

    function setAaveExtraRewardToken(address aaveExtraRewardToken_) public virtual onlyAdmin {
        require(aaveExtraRewardToken_ != address(0), "SeniorConfig::INVALID_ADDRESS");
        seniorVault.setConfig(AAVE_EXTRA_REWARD_TOKEN, aaveExtraRewardToken_.toBytes32());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../libraries/LibConfigSet.sol";
import "../libraries/LibDefines.sol";

struct SeniorStateStore {
    bytes32[50] __offsets;
    // config
    ConfigSet config;
    // balance properties
    address asset;
    uint8 assetDecimals;
    uint256 totalAssets;
    uint256 totalSupply;
    uint256 previousBalance;
    uint256 totalBorrows;
    // assets borrowed to junior vaults
    mapping(address => uint256) borrows;
    mapping(address => uint256) balances;
    mapping(address => uint256) timelocks;
    uint256 aaveSuppliedBalance;
    uint256 aaveLastUpdateTime;
    bytes32[18] __reserves;
}