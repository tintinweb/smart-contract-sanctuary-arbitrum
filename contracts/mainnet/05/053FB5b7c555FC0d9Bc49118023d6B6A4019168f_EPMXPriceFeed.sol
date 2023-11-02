// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// admin roles
bytes32 constant BIG_TIMELOCK_ADMIN = 0x00; // It's primary admin.
bytes32 constant MEDIUM_TIMELOCK_ADMIN = keccak256("MEDIUM_TIMELOCK_ADMIN");
bytes32 constant SMALL_TIMELOCK_ADMIN = keccak256("SMALL_TIMELOCK_ADMIN");
bytes32 constant EMERGENCY_ADMIN = keccak256("EMERGENCY_ADMIN");
bytes32 constant GUARDIAN_ADMIN = keccak256("GUARDIAN_ADMIN");
bytes32 constant NFT_MINTER = keccak256("NFT_MINTER");
bytes32 constant TRUSTED_TOLERABLE_LIMIT_ROLE = keccak256("TRUSTED_TOLERABLE_LIMIT_ROLE");

// inter-contract interactions roles
bytes32 constant NO_FEE_ROLE = keccak256("NO_FEE_ROLE");
bytes32 constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
bytes32 constant PM_ROLE = keccak256("PM_ROLE");
bytes32 constant LOM_ROLE = keccak256("LOM_ROLE");
bytes32 constant BATCH_MANAGER_ROLE = keccak256("BATCH_MANAGER_ROLE");

// token constants
address constant NATIVE_CURRENCY = address(uint160(bytes20(keccak256("NATIVE_CURRENCY"))));
address constant USD = 0x0000000000000000000000000000000000000348;
uint256 constant USD_MULTIPLIER = 10 ** (18 - 8); // usd decimals in chainlink is 8
uint8 constant MAX_ASSET_DECIMALS = 18;

// time constants
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_DAY = 1 days;
uint256 constant HOUR = 1 hours;
uint256 constant TEN_WAD = 10 ether;

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./libraries/Errors.sol";

import {BIG_TIMELOCK_ADMIN} from "./Constants.sol";
import {IEPMXPriceFeed} from "./interfaces/IEPMXPriceFeed.sol";

contract EPMXPriceFeed is IEPMXPriceFeed, AggregatorV2V3Interface {
    uint80 internal constant MAX_UINT80_HEX = type(uint80).max;

    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    address public immutable registry;
    uint8 public override decimals = 8; // USD decimals
    uint80 private _currentRound;
    RoundData private _latestRoundData;
    mapping(uint80 => RoundData) private _answers;

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _registry) {
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @notice Retrieves the latest answer from the oracle.
     * @return The latest answer, with a precision of 8 decimal (USD decimals).
     */
    function latestAnswer() external view override returns (int256) {
        return _latestRoundData.answer;
    }

    /**
     * @notice Returns the latest round data.
     * @return roundId The ID of the latest round.
     * @return answer The answer provided in the latest round.
     * @return startedAt The timestamp when the latest round started.
     * @return updatedAt The timestamp when the latest round was updated.
     * @return answeredInRound The round in which the latest answer was provided.
     */
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (
            _latestRoundData.roundId,
            _latestRoundData.answer,
            _latestRoundData.startedAt,
            _latestRoundData.updatedAt,
            _latestRoundData.answeredInRound
        );
    }

    /**
     * @notice Retrieves the latest timestamp of the round data.
     * @return The latest timestamp of when the round was updated, in seconds (UTC).
     */
    function latestTimestamp() external view override returns (uint256) {
        return _latestRoundData.updatedAt;
    }

    /**
     * @notice Retrieves the answer for a given round ID.
     * @param roundId The round ID for which to get the answer.
     * @return The answer previously set with setAnswer().
     */
    function getAnswer(uint256 roundId) external view override returns (int256) {
        if (roundId > MAX_UINT80_HEX) {
            return 0;
        }
        return _answers[uint80(roundId)].answer;
    }

    /**
     * @notice Retrieves the timestamp of a given round ID.
     * @param roundId The round ID for which to retrieve the timestamp.
     * @return The timestamp when the round was last updated.
     */
    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        if (roundId > MAX_UINT80_HEX) {
            return 0;
        }
        return _answers[uint80(roundId)].updatedAt;
    }

    /**
     * @notice Retrieves the latest round ID.
     * @return The latest round ID.
     */
    function latestRound() external view override returns (uint256) {
        return _latestRoundData.roundId;
    }

    /**
     * @inheritdoc IEPMXPriceFeed
     */
    function setAnswer(int256 answer) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        _latestRoundData.answer = answer;
        _latestRoundData.roundId = _currentRound;
        _latestRoundData.startedAt = block.timestamp;
        _latestRoundData.updatedAt = block.timestamp;
        _latestRoundData.answeredInRound = _currentRound;
        _answers[_currentRound] = _latestRoundData;
        _currentRound++;
        emit AnswerUpdated(answer, _latestRoundData.roundId, block.timestamp);
    }

    /**
     * @notice Retrieves the data for a specific round.
     * @param _roundId The ID of the round to retrieve data for.
     * @return roundId The ID of the round.
     * @return answer The answer for the round.
     * @return startedAt The timestamp when the round started.
     * @return updatedAt The timestamp when the round was last updated.
     * @return answeredInRound The ID of the round in which the answer was computed.
     */
    function getRoundData(uint80 _roundId) public view override returns (uint80, int256, uint256, uint256, uint80) {
        RoundData memory roundData = _answers[_roundId];
        return (
            roundData.roundId,
            roundData.answer,
            roundData.startedAt,
            roundData.updatedAt,
            roundData.answeredInRound
        );
    }

    /**
     * @notice Returns the description of the contract.
     * @return The description string "EPMX / USD".
     */
    function description() public pure override returns (string memory) {
        return "EPMX / USD";
    }

    /**
     * @notice This function provides the version number of the contract.
     */
    function version() public pure override returns (uint256) {
        return 0;
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IEPMXPriceFeed {
    /**
     * @notice Sets the answer for the current round.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param answer The answer to be set with a precision of 8 decimal (USD decimals).
     */
    function setAnswer(int256 answer) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// solhint-disable-next-line func-visibility
function _require(bool condition, bytes4 selector) pure {
    if (!condition) _revert(selector);
}

// solhint-disable-next-line func-visibility
function _revert(bytes4 selector) pure {
    // solhint-disable-next-line no-inline-assembly
    assembly ("memory-safe") {
        let free_mem_ptr := mload(64)
        mstore(free_mem_ptr, selector)
        revert(free_mem_ptr, 4)
    }
}

library Errors {
    event Log(bytes4 error);

    //common
    error ADDRESS_NOT_SUPPORTED();
    error FORBIDDEN();
    error AMOUNT_IS_0();
    error CALLER_IS_NOT_TRADER();
    error CONDITION_INDEX_IS_OUT_OF_BOUNDS();
    error INVALID_PERCENT_NUMBER();
    error INVALID_SECURITY_BUFFER();
    error INVALID_MAINTENANCE_BUFFER();
    error TOKEN_ADDRESS_IS_ZERO();
    error IDENTICAL_TOKEN_ADDRESSES();
    error ASSET_DECIMALS_EXCEEDS_MAX_VALUE();
    error CAN_NOT_ADD_WITH_ZERO_ADDRESS();
    error SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT();
    error TOKEN_NOT_SUPPORTED();
    error INSUFFICIENT_DEPOSIT();
    error DEPOSIT_IN_THIRD_ASSET_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error SHOULD_NOT_HAVE_DUPLICATES();
    error DEPOSITED_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error DEPOSIT_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    // error LIMIT_PRICE_IS_ZERO();
    error BUCKET_IS_NOT_ACTIVE();
    error DIFFERENT_DATA_LENGTH();
    error RECIPIENT_OR_SENDER_MUST_BE_ON_WHITE_LIST();
    error SLIPPAGE_TOLERANCE_EXCEEDED();
    error OPERATION_NOT_SUPPORTED();
    error SENDER_IS_BLACKLISTED();
    error NATIVE_CURRENCY_CANNOT_BE_ASSET();
    error DISABLED_TRANSFER_NATIVE_CURRENCY();
    error INVALID_AMOUNT();

    // bonus executor
    error CALLER_IS_NOT_NFT();
    error BONUS_FOR_BUCKET_ALREADY_ACTIVATED();
    error WRONG_LENGTH();
    error BONUS_DOES_NOT_EXIST();
    error CALLER_IS_NOT_DEBT_TOKEN();
    error CALLER_IS_NOT_P_TOKEN();
    error MAX_BONUS_COUNT_EXCEEDED();
    error TIER_IS_NOT_ACTIVE();
    error BONUS_PERCENT_IS_ZERO();

    // bucket
    error INCORRECT_LIQUIDITY_MINING_PARAMS();
    error PAIR_PRICE_DROP_IS_NOT_CORRECT();
    error ASSET_IS_NOT_SUPPORTED();
    error BUCKET_OUTSIDE_PRIMEX_PROTOCOL();
    error DEADLINE_IS_PASSED();
    error DEADLINE_IS_NOT_PASSED();
    error BUCKET_IS_NOT_LAUNCHED();
    error BURN_AMOUNT_EXCEEDS_PROTOCOL_DEBT();
    error LIQUIDITY_INDEX_OVERFLOW();
    error BORROW_INDEX_OVERFLOW();
    error BAR_OVERFLOW();
    error LAR_OVERFLOW();
    error UR_IS_MORE_THAN_1();
    error ASSET_ALREADY_SUPPORTED();
    error DEPOSIT_IS_MORE_AMOUNT_PER_USER();
    error DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT();
    error MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD();
    error WITHDRAW_RATE_IS_MORE_10_PERCENT();
    error INVALID_FEE_BUFFER();
    error RESERVE_RATE_SHOULD_BE_LESS_THAN_1();
    error MAX_TOTAL_DEPOSIT_IS_ZERO();
    error AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO();
    error NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET();

    // p/debt token, PMXToken
    error BUCKET_IS_IMMUTABLE();
    error INVALID_MINT_AMOUNT();
    error INVALID_BURN_AMOUNT();
    error TRANSFER_NOT_SUPPORTED();
    error APPROVE_NOT_SUPPORTED();
    error CALLER_IS_NOT_BUCKET();
    error CALLER_IS_NOT_A_BUCKET_FACTORY();
    error CALLER_IS_NOT_P_TOKEN_RECEIVER();
    error DURATION_MUST_BE_MORE_THAN_0();
    error INCORRECT_ID();
    error THERE_ARE_NO_LOCK_DEPOSITS();
    error LOCK_TIME_IS_NOT_EXPIRED();
    error TRANSFER_AMOUNT_EXCEED_ALLOWANCE();
    error CALLER_IS_NOT_A_MINTER();
    error ACTION_ONLY_WITH_AVAILABLE_BALANCE();
    error FEE_DECREASER_CALL_FAILED();
    error TRADER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error INTEREST_INCREASER_CALL_FAILED();
    error LENDER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error DEPOSIT_DOES_NOT_EXIST();
    error RECIPIENT_IS_BLACKLISTED();

    //LOM
    error ORDER_CAN_NOT_BE_FILLED();
    error ORDER_DOES_NOT_EXIST();
    error ORDER_IS_NOT_SPOT();
    error LEVERAGE_MUST_BE_MORE_THAN_1();
    error CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN();
    error SHOULD_HAVE_OPEN_CONDITIONS();
    error INCORRECT_LEVERAGE();
    error INCORRECT_DEADLINE();
    error LEVERAGE_SHOULD_BE_1();
    error LEVERAGE_EXCEEDS_MAX_LEVERAGE();
    error SHOULD_OPEN_POSITION();
    error IS_SPOT_ORDER();
    error SHOULD_NOT_HAVE_CLOSE_CONDITIONS();
    error ORDER_HAS_EXPIRED();

    // LiquidityMiningRewardDistributor
    error BUCKET_IS_NOT_STABLE();
    error ATTEMPT_TO_WITHDRAW_MORE_THAN_DEPOSITED();
    error WITHDRAW_PMX_BY_ADMIN_FORBIDDEN();

    // nft
    error TOKEN_IS_BLOCKED();
    error ONLY_MINTERS();
    error PROGRAM_IS_NOT_ACTIVE();
    error CALLER_IS_NOT_OWNER();
    error TOKEN_IS_ALREADY_ACTIVATED();
    error WRONG_NETWORK();
    error ID_DOES_NOT_EXIST();
    error WRONG_URIS_LENGTH();

    // PM
    error ASSET_ADDRESS_NOT_SUPPORTED();
    error IDENTICAL_ASSET_ADDRESSES();
    error POSITION_DOES_NOT_EXIST();
    error AMOUNT_IS_MORE_THAN_POSITION_AMOUNT();
    error BORROWED_AMOUNT_IS_ZERO();
    error IS_SPOT_POSITION();
    error AMOUNT_IS_MORE_THAN_DEPOSIT();
    error DECREASE_AMOUNT_IS_ZERO();
    error INSUFFICIENT_DEPOSIT_SIZE();
    error IS_NOT_RISKY_OR_CANNOT_BE_CLOSED();
    error BUCKET_SHOULD_BE_UNDEFINED();
    error DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0();
    error POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error ADDRESS_IS_ZERO();
    error WRONG_TRUSTED_MULTIPLIER();
    error POSITION_SIZE_EXCEEDED();
    error POSITION_BUCKET_IS_INCORRECT();
    error THERE_MUST_BE_AT_LEAST_ONE_POSITION();
    error NOTHING_TO_CLOSE();

    // BatchManager
    error PARAMS_LENGTH_MISMATCH();
    error BATCH_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error CLOSE_CONDITION_IS_NOT_CORRECT();
    error SOLD_ASSET_IS_INCORRECT();

    // Price Oracle
    error ZERO_EXCHANGE_RATE();
    error NO_PRICEFEED_FOUND();
    error NO_PRICE_DROP_FEED_FOUND();

    //DNS
    error INCORRECT_FEE_RATE();
    error BUCKET_ALREADY_FROZEN();
    error BUCKET_IS_ALREADY_ADDED();
    error DEX_IS_ALREADY_ACTIVATED();
    error DEX_IS_ALREADY_FROZEN();
    error DEX_IS_ALREADY_ADDED();
    error BUCKET_NOT_ADDED();
    error DEX_NOT_ACTIVE();
    error BUCKET_ALREADY_ACTIVATED();
    error DEX_NOT_ADDED();
    error BUCKET_IS_INACTIVE();
    error WITHDRAWAL_NOT_ALLOWED();
    error BUCKET_IS_ALREADY_DEPRECATED();

    // Primex upkeep
    error NUMBER_IS_0();

    //referral program, WhiteBlackList
    error CALLER_ALREADY_REGISTERED();
    error MISMATCH();
    error PARENT_NOT_WHITELISTED();
    error ADDRESS_ALREADY_WHITELISTED();
    error ADDRESS_ALREADY_BLACKLISTED();
    error ADDRESS_NOT_BLACKLISTED();
    error ADDRESS_NOT_WHITELISTED();
    error ADDRESS_NOT_UNLISTED();
    error ADDRESS_IS_WHITELISTED();
    error ADDRESS_IS_NOT_CONTRACT();

    //Reserve
    error BURN_AMOUNT_IS_ZERO();
    error CALLER_IS_NOT_EXECUTOR();
    error ADDRESS_NOT_PRIMEX_BUCKET();
    error NOT_SUFFICIENT_RESERVE_BALANCE();
    error INCORRECT_TRANSFER_RESTRICTIONS();

    //Vault
    error AMOUNT_EXCEEDS_AVAILABLE_BALANCE();
    error INSUFFICIENT_FREE_ASSETS();
    error CALLER_IS_NOT_SPENDER();

    //Pricing Library
    error IDENTICAL_ASSETS();
    error SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO();
    error DIFFERENT_PRICE_DEX_AND_ORACLE();
    error TAKE_PROFIT_IS_LTE_LIMIT_PRICE();
    error STOP_LOSS_IS_GTE_LIMIT_PRICE();
    error STOP_LOSS_IS_LTE_LIQUIDATION_PRICE();
    error INSUFFICIENT_POSITION_SIZE();
    error INCORRECT_PATH();
    error DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0();
    error INCORRECT_CM_TYPE();

    // Token transfers
    error TOKEN_TRANSFER_IN_FAILED();
    error TOKEN_TRANSFER_IN_OVERFLOW();
    error TOKEN_TRANSFER_OUT_FAILED();
    error NATIVE_TOKEN_TRANSFER_FAILED();

    // Conditional Managers
    error LOW_PRICE_ROUND_IS_LESS_HIGH_PRICE_ROUND();
    error TRAILING_DELTA_IS_INCORRECT();
    error DATA_FOR_ROUND_DOES_NOT_EXIST();
    error HIGH_PRICE_TIMESTAMP_IS_INCORRECT();
    error NO_PRICE_FEED_INTERSECTION();
    error SHOULD_BE_CCM();
    error SHOULD_BE_COM();

    //Lens
    error DEPOSITED_AMOUNT_IS_0();
    error SPOT_DEPOSITED_ASSET_SHOULD_BE_EQUAL_BORROWED_ASSET();
    error ZERO_ASSET_ADDRESS();
    error ASSETS_SHOULD_BE_DIFFERENT();
    error ZERO_SHARES();
    error SHARES_AMOUNT_IS_GREATER_THAN_AMOUNT_TO_SELL();
    error NO_ACTIVE_DEXES();

    //Bots
    error WRONG_BALANCES();
    error INVALID_INDEX();
    error INVALID_DIVIDER();
    error ARRAYS_LENGTHS_IS_NOT_EQUAL();
    error DENOMINATOR_IS_0();

    //DexAdapter
    error ZERO_AMOUNT_IN();
    error ZERO_AMOUNT();
    error UNKNOWN_DEX_TYPE();
    error REVERTED_WITHOUT_A_STRING_TRY_TO_CHECK_THE_ANCILLARY_DATA();
    error DELTA_OF_TOKEN_OUT_HAS_POSITIVE_VALUE();
    error DELTA_OF_TOKEN_IN_HAS_NEGATIVE_VALUE();
    error QUOTER_IS_NOT_PROVIDED();
    error DEX_ROUTER_NOT_SUPPORTED();
    error QUOTER_NOT_SUPPORTED();
    error SWAP_DEADLINE_PASSED();

    //SpotTradingRewardDistributor
    error PERIOD_DURATION_IS_ZERO();
    error REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_PERIOD_IS_NOT_CORRECT();

    //ActivityRewardDistributor
    error TOTAL_REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_DAY_IS_NOT_CORRECT();
    error ZERO_BUCKET_ADDRESS();
    //KeeperRewardDistributor
    error INCORRECT_PART_IN_REWARD();

    //Treasury
    error TRANSFER_RESTRICTIONS_NOT_MET();
    error INSUFFICIENT_NATIVE_TOKEN_BALANCE();
    error INSUFFICIENT_TOKEN_BALANCE();
    error EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME();
    error EXCEEDED_MAX_SPENDING_LIMITS();
    error SPENDING_LIMITS_ARE_INCORRECT();
    error SPENDER_IS_NOT_EXIST();
}