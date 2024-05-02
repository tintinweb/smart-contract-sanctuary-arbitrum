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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title IGuildAddressesProviderRegistry
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for an Guild Addresses Provider Registry.
 **/
interface IGuildAddressesProviderRegistry {
    /**
     * @dev Emitted when a new AddressesProvider is registered.
     * @param addressesProvider The address of the registered GuildAddressesProvider
     * @param id The id of the registered GuildAddressesProvider
     */
    event AddressesProviderRegistered(address indexed addressesProvider, uint256 indexed id);

    /**
     * @dev Emitted when an AddressesProvider is unregistered.
     * @param addressesProvider The address of the unregistered GuildAddressesProvider
     * @param id The id of the unregistered GuildAddressesProvider
     */
    event AddressesProviderUnregistered(address indexed addressesProvider, uint256 indexed id);

    /**
     * @notice Returns the list of registered addresses providers
     * @return The list of addresses providers
     **/
    function getAddressesProvidersList() external view returns (address[] memory);

    /**
     * @notice Returns the id of a registered GuildAddressesProvider
     * @param addressesProvider The address of the GuildAddressesProvider
     * @return The id of the GuildAddressesProvider or 0 if is not registered
     */
    function getAddressesProviderIdByAddress(address addressesProvider) external view returns (uint256);

    /**
     * @notice Returns the address of a registered GuildAddressesProvider
     * @param id The id of the market
     * @return The address of the GuildAddressesProvider with the given id or zero address if it is not registered
     */
    function getAddressesProviderAddressById(uint256 id) external view returns (address);

    /**
     * @notice Registers an addresses provider
     * @dev The GuildAddressesProvider must not already be registered in the registry
     * @dev The id must not be used by an already registered GuildAddressesProvider
     * @param provider The address of the new GuildAddressesProvider
     * @param id The id for the new GuildAddressesProvider, referring to the market it belongs to
     **/
    function registerAddressesProvider(address provider, uint256 id) external;

    /**
     * @notice Removes an addresses provider from the list of registered addresses providers
     * @param provider The GuildAddressesProvider address
     **/
    function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Ownable2Step} from "../../dependencies/@openzeppelin/contracts/access/Ownable2Step.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IGuildAddressesProviderRegistry} from "../../interfaces/IGuildAddressesProviderRegistry.sol";

/**
 * @title GuildAddressesProviderRegistry
 * @author Covenant Labs (cloned from AAVE core v3 commit d5fafce)
 * @notice Main registry of GuildAddressesProvider of Covenant Guilds.
 * @dev Used for indexing purposes of Covenant Guilds. The id assigned to a GuildAddressesProvider refers to the
 * Guild it is connected with, for example with `1` for the Guild, etc
 **/
contract GuildAddressesProviderRegistry is Ownable2Step, IGuildAddressesProviderRegistry {
    // Map of address provider ids (addressesProvider => id)
    mapping(address => uint256) private _addressesProviderToId;
    // Map of id to address provider (id => addressesProvider)
    mapping(uint256 => address) private _idToAddressesProvider;
    // List of addresses providers
    address[] private _addressesProvidersList;
    // Map of address provider list indexes (addressesProvider => indexInList)
    mapping(address => uint256) private _addressesProvidersIndexes;

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract.
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    /// @inheritdoc IGuildAddressesProviderRegistry
    function getAddressesProvidersList() external view override returns (address[] memory) {
        return _addressesProvidersList;
    }

    /// @inheritdoc IGuildAddressesProviderRegistry
    function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
        require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
        require(_idToAddressesProvider[id] == address(0), Errors.INVALID_ADDRESSES_PROVIDER_ID);
        require(_addressesProviderToId[provider] == 0, Errors.ADDRESSES_PROVIDER_ALREADY_ADDED);

        _addressesProviderToId[provider] = id;
        _idToAddressesProvider[id] = provider;

        _addToAddressesProvidersList(provider);
        emit AddressesProviderRegistered(provider, id);
    }

    /// @inheritdoc IGuildAddressesProviderRegistry
    function unregisterAddressesProvider(address provider) external override onlyOwner {
        require(_addressesProviderToId[provider] != 0, Errors.ADDRESSES_PROVIDER_NOT_REGISTERED);
        uint256 oldId = _addressesProviderToId[provider];
        _idToAddressesProvider[oldId] = address(0);
        _addressesProviderToId[provider] = 0;

        _removeFromAddressesProvidersList(provider);

        emit AddressesProviderUnregistered(provider, oldId);
    }

    /// @inheritdoc IGuildAddressesProviderRegistry
    function getAddressesProviderIdByAddress(address addressesProvider) external view override returns (uint256) {
        return _addressesProviderToId[addressesProvider];
    }

    /// @inheritdoc IGuildAddressesProviderRegistry
    function getAddressesProviderAddressById(uint256 id) external view override returns (address) {
        return _idToAddressesProvider[id];
    }

    /**
     * @notice Adds the addresses provider address to the list.
     * @param provider The address of the GuildAddressesProvider
     */
    function _addToAddressesProvidersList(address provider) internal {
        _addressesProvidersIndexes[provider] = _addressesProvidersList.length;
        _addressesProvidersList.push(provider);
    }

    /**
     * @notice Removes the addresses provider address from the list.
     * @param provider The address of the GuildAddressesProvider
     */
    function _removeFromAddressesProvidersList(address provider) internal {
        uint256 index = _addressesProvidersIndexes[provider];

        _addressesProvidersIndexes[provider] = 0;

        // Swap the index of the last addresses provider in the list with the index of the provider to remove
        uint256 lastIndex = _addressesProvidersList.length - 1;
        if (index < lastIndex) {
            address lastProvider = _addressesProvidersList[lastIndex];
            _addressesProvidersList[index] = lastProvider;
            _addressesProvidersIndexes[lastProvider] = index;
        }
        _addressesProvidersList.pop();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @author Covenant Labs
 * @notice Defines the error messages emitted by the different contracts of the Covenant protocol
 */
library Errors {
    string public constant LOCKED = "0"; // 'Guild is locked'
    string public constant NOT_CONTRACT = "1"; // 'Address is not a contract'
    string public constant AMOUNT_NEED_TO_BE_GREATER = "2"; // 'A greater amount needed for action'
    string public constant TRANSFER_FAIL = "3"; // 'Failed to transfer'
    string public constant NOT_APPROVED = "4"; // 'Not approved'
    string public constant NOT_ENOUGH_BALANCE = "5"; // 'Not enough balance'
    string public constant ASSET_NEEDS_TO_BE_APPROVED = "6"; // 'Asset needs to be whitelisted'
    string public constant OPERATION_NOT_SUPPORTED = "7"; // 'Operation not supported'
    string public constant OPERATION_NOT_AUTHORIZED = "8"; // 'Operation not authorized, not enough permissions for the operation'
    string public constant REFINANCE_INVALID_TIMESTAMP = "9"; // 'The current block has a timestamp that is older vs that last refinance'
    string public constant NOT_ENOUGH_COLLATERAL = "10"; // 'Not enough collateral'
    string public constant AMOUNT_NEED_TO_MORE_THAN_ZERO = "11"; // '"Your asset amount must be greater then you are trying to deposit"'
    string public constant CANNOT_BURN_MORE_THAN_CURRENT_DEBT = "12"; // "Amount exceeds current debt level"
    string public constant UNHEALTHY_POSITION = "13"; // Users position is currently higher than liquidation threshold
    string public constant CANNOT_LIQUIDATE_HEALTHY = "14"; // Cannot liqudate healthy users position
    string public constant WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE = "15"; // Amount exceeds max withdrawable amount
    string public constant HELPER_INSUFFICIENT_FUNDS = "16"; // Internal error, insufficient funds to place on dex as requested
    string public constant AMOUNT_NEEDS_TO_EQUAL_COLLATERAL_VALUE = "17"; // Amount needs to be the same to exchange money for collateral
    string public constant AMOUNT_NEEDS_TO_LOWER_THAN_DEBT = "18"; // Amount needs to be lower than current debt level
    string public constant NOT_ENOUGH_Z_TOKENS = "19"; // "Not enough zTokens in account"
    string public constant PRICE_LIMIT_OUT_OF_BOUNDS = "20"; // "PerpetualDebt.sol - price limit initialization out of bounds"
    string public constant PRICE_LIMIT_ERROR = "21"; // "PerpetualDebt.sol - price limit min larger than max"
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "22"; // "ACLManager.sol - cannot set a 0x0 address as admin"
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "23"; // "GuildAddressesProviderRegistry.sol - cannot set ID 0"
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "24"; // 'GuildAddressesProviderRegistry.sol - Guild addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER = "25"; // 'The address of the guild addresses provider is invalid'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "26"; // 'GuildAddressesProviderRegistry.sol - Reserve has already been added to collateral list'
    string public constant CALLER_NOT_GUILD_ADMIN = "27"; // 'The caller of the function is not a guild admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "28"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_GUILD_OR_EMERGENCY_ADMIN = "29"; // 'The caller of the function is not a guild or emergency admin'
    string public constant CALLER_NOT_RISK_OR_GUILD_ADMIN = "30"; // 'The caller of the function is not a risk or guild admin'
    string public constant TRANSFER_INVALID_SENDER = "31"; // 'ERC20: Cannot send from address 0'
    string public constant TRANSFER_INVALID_RECEIVER = "32"; // 'ERC20: Cannot send to address 0'
    string public constant CALLER_MUST_BE_GUILD = "33"; // 'The caller of the function must be the guild'
    string public constant GUILD_ADDRESSES_DO_NOT_MATCH = "34"; // 'Incorrect Guild address when initializing token'
    string public constant PERPETUAL_DEBT_ALREADY_INITIALIZED = "35"; // 'Perpetual Debt structure already initialized'
    string public constant DEX_ORACLE_ALREADY_INITIALIZED = "36"; // 'Dex Oracle structure already initialized'
    string public constant DEX_ORACLE_POOL_NOT_INITIALIZED = "37"; // 'Dex pool should be initialized before Dex oracle'
    string public constant CALLER_NOT_GUILD_CONFIGURATOR = "38"; // 'The caller of the function is not the guild configurator contract'
    string public constant COLLATERAL_ALREADY_ADDED = "39"; // 'Collateral has already been added to collateral list'
    string public constant NO_MORE_COLLATERALS_ALLOWED = "40"; // 'Maximum amount of collaterals in the guild reached'
    string public constant INVALID_LTV = "41"; // 'Invalid ltv parameter for the collateral'
    string public constant INVALID_LIQ_THRESHOLD = "42"; // 'Invalid liquidity threshold parameter for the collateral'
    string public constant INVALID_LIQ_BONUS = "43"; // 'Invalid liquidity bonus parameter for the collateral'
    string public constant INVALID_DECIMALS = "44"; // 'Invalid decimals parameter of the underlying asset of the collateral'
    string public constant INVALID_SUPPLY_CAP = "45"; // 'Invalid supply cap for the collateral'
    string public constant INVALID_PROTOCOL_DISTRIBUTION_FEE = "46"; // 'Invalid protocol distribution fee for the perpetual debt'
    string public constant ZERO_ADDRESS_NOT_VALID = "47"; // 'Zero address not valid'
    string public constant COLLATERAL_NOT_LISTED = "48"; // 'Collateral is not listed (not initialized or has been dropped)'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "49"; // 'The collateral balance is 0'
    string public constant LTV_VALIDATION_FAILED = "50"; // 'Ltv validation failed'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "51"; // 'Health factor is lower than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "52"; // 'There is not enough collateral to cover a new borrow'
    string public constant INVALID_COLLATERAL_PARAMS = "53"; //'Invalid risk parameters for the collateral'
    string public constant INVALID_AMOUNT = "54"; // 'Amount must be greater than 0'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "55"; //'User cannot withdraw more than the available balance'
    string public constant COLLATERAL_INACTIVE = "56"; //'Action requires an active collateral'
    string public constant SUPPLY_CAP_EXCEEDED = "57"; // 'Supply cap is exceeded'
    string public constant ACL_MANAGER_NOT_SET = "58"; // 'The ACL Manager has not been set for the addresses provider'
    string public constant ARRAY_SIZE_MISMATCH = "59"; // 'The arrays are of different sizes'
    string public constant DEX_POOL_DOES_NOT_CONTAIN_ASSET_PAIR = "60"; // 'The dex pool does not contain pricing info for token pair'
    string public constant ASSET_NOT_TRACKED_IN_ORACLE = "61"; // 'The asset is not tracked by the pricing oracle'
    string public constant INVALID_MINT_CAP = "62"; //  'Invalid mint cap for the perpetual debt'
    string public constant DEBT_PAUSED = "63"; //  'Action requires a non-paused debt'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "64"; // 'Action requires health factor to be below liquidation threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "65"; // 'The collateral chosen cannot be liquidated'
    string public constant USER_HAS_NO_DEBT = "66"; // 'User has no debt to be liquidated'
    string public constant INSUFFICIENT_CREDIT_DELEGATION = "67"; //  'Insufficient credit delegation to 3rd party borrower'
    string public constant INSUFFICIENT_TOKENIN_FOR_TARGET_TOKENOUT = "68"; //  'Insufficient tokenIn to swap for target tokenOut value'
    string public constant COLLATERAL_FROZEN = "69"; // 'Action cannot be performed because the collateral is frozen'
    string public constant COLLATERAL_PAUSED = "70"; // 'Action cannot be performed because the collateral is paused'
    string public constant PERPETUAL_DEBT_FROZEN = "71"; // 'Action cannot be performed because the perpetual debt is frozen'
    string public constant PERPETUAL_DEBT_PAUSED = "72"; // 'Action cannot be performed because the perpetual debt is paused'
    string public constant TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "73"; // 'Account does not have sufficient allowance to transfer on behalf of other account'
    string public constant NEGATIVE_ALLOWANCE_NOT_ALLOWED = "74"; // 'Cannot allocate negative value for allowances'
    string public constant INSUFFICIENT_BALANCE_TO_BURN = "75"; // 'Cannot burn more than amount in balance'
    string public constant TRANSFER_EXCEEDS_BALANCE = "76"; // 'ERC20: Transfer amount exceeds balance'
    string public constant PERPETUAL_DEBT_CAP_EXCEEDED = "77"; // 'Perpetual debt cap is exceeded'
    string public constant NEGATIVE_DELEGATION_NOT_ALLOWED = "78"; // 'Cannot allocate negative value for delegation allowances'
    string public constant ORACLE_LOOKBACKPERIOD_IS_ZERO = "79"; // 'Collateral oracle should have lookback period greater than 0'
    string public constant ORACLE_CARDINALITY_IS_ZERO = "80"; // 'Collateral oracle should have pool cardinality greater than 0'
    string public constant ORACLE_CARDINALITY_MONOTONICALLY_INCREASES = "81"; // The cardinality of the oracle is monotonically increasing and cannot bet lowered
    string public constant ORACLE_ASSET_MISMATCH = "82"; // Asset in oracle does not match proxy asset address
    string public constant ORACLE_BASE_CURRENCY_MISMATCH = "83"; // Base currency in oracle does not match proxy base currency address
    string public constant NO_ORACLE_PROXY_PRICE_SOURCE = "84"; // Oracle proxy does not have a price source
    string public constant CANNOT_BE_ZERO = "85"; // The value cannot be 0
    string public constant REQUIRES_OVERRIDE = "86"; // Function requires override
    string public constant GUILD_MISMATCH = "87"; // Function requires override
    string public constant ORACLE_PROXY_TOKENS_NOT_SET_PROPERLY = "88"; // Function requires override
    string public constant POSITIVE_COLLATERAL_BALANCE = "89"; // Cannot only perform action if guild balance is positive
    string public constant INVALID_ROLE = "90"; // Role exceeds MAX_LIMIT
    string public constant MAX_NUM_ROLES_EXCEEDED = "91"; // Role can't exceed MAX_NUM_OF_ROLES
    string public constant INVALID_PROTOCOL_SERVICE_FEE = "92"; // Protocol service fee larger than max allowed
    string public constant INVALID_PROTOCOL_MINT_FEE = "93"; // Protocol mint fee larger than max allowed
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "94"; // PriceOracleSentinel check failed
    string public constant LOOKBACK_PERIOD_IS_NOT_ZERO = "95"; // lookback period must be 0
    string public constant LOOKBACK_PERIOD_END_LT_START = "96"; // lookbackPeriodEnd can't be less than lookbackPeriodStart
    string public constant PRICE_CANNOT_BE_ZERO = "97"; // Oracle price cannot be zero
    string public constant INVALID_PROTOCOL_SWAP_FEE = "98"; // Protocol swap fee larger than max allowed
    string public constant COLLATERAL_CANNOT_COVER_EXISTING_BORROW = "99"; // 'Collateral remaining after withdrawal would not cover existing borrow'
    string public constant CALLER_NOT_GUILD_OR_GUILD_ADMIN = "A0"; // 'The caller of the function is not the guild or guild admin'
    string public constant NOT_ENOUGH_MONEY_IN_GUILD_TO_SWAP = "A1"; // 'There is not enough money in the Guild treasury for a successfull swap and debt burn'
    string public constant MONEY_DOES_NOT_MATCH = "A2"; // 'Guild or Oracle cannot be initialized with a Money token that differs from the other.
    string public constant ORACLE_ADDRESS_CANNOT_BE_ZERO = "A3"; // 'A valid address needs to be used when updating the Oracle
    string public constant ORACLE_NOT_SET = "A4"; // 'An oracle has not been registered with guildAddressProvider

    string public constant OWNABLE_ONLY_OWNER = "Ownable: caller is not the owner";
}