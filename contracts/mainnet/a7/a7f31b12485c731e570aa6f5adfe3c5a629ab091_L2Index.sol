// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {AggregatorV2V3Interface} from "chainlink/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import {IL2Index} from "../interfaces/IL2Index.sol";
import {Currency, Index} from "../Index.sol";

contract L2Index is Index, IL2Index {
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    AggregatorV2V3Interface private sequencerUptimeFeed;

    error SequencerDown();
    error GracePeriodNotOver();

    constructor(
        string memory _name,
        string memory _symbol,
        Currency _reserve,
        address _governance,
        address _messenger,
        uint16 _maxDepositFeeInBPs,
        uint16 _maxRedemptionFeeInBPs,
        uint256 _maxAUMDilutionPerSecond,
        address _sequencerUptimeFeed
    )
        Index(
            _name,
            _symbol,
            _reserve,
            _governance,
            _messenger,
            _maxDepositFeeInBPs,
            _maxRedemptionFeeInBPs,
            _maxAUMDilutionPerSecond
        )
    {
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
    }

    function deposit(
        DepositParams calldata params,
        DepositCommandParams calldata commandParams,
        PermitParams calldata permitParams
    ) external payable override {
        _checkSequencer();
        _deposit(params, commandParams, permitParams);
    }

    function redeem(
        RedemptionParams calldata params,
        RedemptionCommandParams calldata commandParams,
        address forwardedSender
    ) external override returns (RedeemedInfo memory redeemed) {
        _checkSequencer();
        return _redeem(params, commandParams, forwardedSender);
    }

    function redeemK(RedeemKParams calldata params, address forwardedSender) external override {
        _checkSequencer();
        _redeemK(params, forwardedSender);
    }

    function setSequencerUptimeFeed(address _sequencerUptimeFeed) external onlyOwner {
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
    }

    function _checkSequencer() internal view {
        (, int256 answer, uint256 startedAt,,) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        if (answer != 0) revert SequencerDown();
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME) revert GracePeriodNotOver();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IL2Index {
    function setSequencerUptimeFeed(address _sequencerUptimeFeed) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IIndex} from "./interfaces/IIndex.sol";

import {Currency, CurrencyLib} from "./libraries/CurrencyLib.sol";
import {IndexCommandsLib} from "./libraries/IndexCommandsLib.sol";

import {BaseIndex, IERC20Permit} from "./BaseIndex.sol";

contract Index is BaseIndex, IIndex {
    using CurrencyLib for Currency;

    error InvalidCurrencies();

    constructor(
        string memory _name,
        string memory _symbol,
        Currency _reserve,
        address _governance,
        address _messenger,
        uint16 _maxDepositFeeInBPs,
        uint16 _maxRedemptionFeeInBPs,
        uint256 _maxAUMDilutionPerSecond
    )
        BaseIndex(
            _name,
            _symbol,
            _reserve,
            _governance,
            _messenger,
            _maxDepositFeeInBPs,
            _maxRedemptionFeeInBPs,
            _maxAUMDilutionPerSecond
        )
    {}

    function deposit(
        DepositParams calldata params,
        DepositCommandParams calldata commandParams,
        PermitParams calldata permitParams
    ) external payable virtual {
        _deposit(params, commandParams, permitParams);
    }

    function redeem(
        RedemptionParams calldata params,
        RedemptionCommandParams calldata commandParams,
        address forwardedSender
    ) external virtual returns (RedeemedInfo memory redeemed) {
        return _redeem(params, commandParams, forwardedSender);
    }

    function redeemK(RedeemKParams calldata params, address forwardedSender) external virtual {
        _redeemK(params, forwardedSender);
    }

    function _deposit(
        DepositParams calldata params,
        DepositCommandParams calldata commandParams,
        PermitParams calldata permitParams
    ) internal nonReentrant {
        bool callCommand = commandParams.command.target.addr() != address(0);
        if (permitParams.deadline != 0) {
            try IERC20Permit(Currency.unwrap(callCommand ? commandParams.currency : reserve)).permit(
                msg.sender,
                address(this),
                params.amount,
                permitParams.deadline,
                permitParams.v,
                permitParams.r,
                permitParams.s
            ) {} catch {}
        }

        _deposit(
            params,
            callCommand
                ? IndexCommandsLib.depositWithCommand(reserve, params, commandParams)
                : reserve.selfDeposit(params.amount)
        );
    }

    function _redeem(
        RedemptionParams calldata params,
        RedemptionCommandParams calldata commandParams,
        address forwardedSender
    ) internal nonReentrant returns (RedeemedInfo memory redeemed) {
        redeemed = _redeem(params, forwardedSender);

        // state haven't been changed since the last simulation
        if (redeemed.reserveValuation == params.expectedReserveValuation && redeemed.k >= params.AUMScaledK) {
            _burnSnapshot(params.config.shared.latestSnapshot, address(this), redeemed.k);
            IndexCommandsLib.executeCommands(
                redeemed.reserve, redeemed.k, params.config.shared.metadata, params.config.homeCurrencies, commandParams
            );
        } else {
            _transferRedeemed(params.recipient, params.config.shared.latestSnapshot, redeemed);
        }
    }

    function _redeemK(RedeemKParams calldata params, address forwardedSender) internal nonReentrant {
        if (redemptionConfigHash != keccak256(abi.encode(params.config))) revert IndexConfigHash();
        if (keccak256(abi.encode(params.currencies)) != currencyHashOf[params.snapshot]) revert InvalidCurrencies();

        _burnSnapshot(params.snapshot, _sender(params.config.forwarder, forwardedSender), params.k);

        IndexCommandsLib.executeCommands(
            0, params.k, params.config.shared.metadata, params.currencies, params.commandParams
        );
    }

    function _transferRedeemed(address recipient, uint256 snapshot, RedeemedInfo memory redeemed) internal {
        if (redeemed.reserve != 0) {
            reserve.transfer(recipient, redeemed.reserve);
        }

        if (redeemed.k != 0) {
            _transferSnapshot(snapshot, redeemed.k, address(this), recipient);
        }
    }
}

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IBaseIndex} from "./IBaseIndex.sol";

import {CommandLib} from "../libraries/CommandLib.sol";
import {Currency} from "../libraries/CurrencyLib.sol";

import {a160u96} from "../utils/a160u96.sol";

interface IIndex is IBaseIndex {
    struct DepositCommandParams {
        Currency currency;
        CommandLib.CommandTarget command;
    }

    struct PermitParams {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct RedemptionCommandParams {
        CommandLib.CommandTarget[] currencyCommands;
        Currency[] additionalCurrencies;
    }

    struct RedeemKParams {
        uint256 snapshot;
        uint256 k;
        a160u96[] currencies;
        RedemptionConfig config;
        RedemptionCommandParams commandParams;
    }

    function deposit(
        DepositParams calldata params,
        DepositCommandParams calldata callbackParams,
        PermitParams calldata permitParams
    ) external payable;

    function redeem(
        RedemptionParams calldata params,
        RedemptionCommandParams calldata commandParams,
        address forwardedSender
    ) external returns (RedeemedInfo memory redeemed);

    function redeemK(RedeemKParams calldata params, address forwardedSender) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {a160u96} from "../utils/a160u96.sol";

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
    using FixedPointMathLib for uint256;
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
    /// @param currency Currency to approve
    /// @param spender Address of spender
    /// @param amount Currency amount to approve
    function approve(Currency currency, address spender, uint256 amount) internal {
        if (isNative(currency)) return;
        IERC20(Currency.unwrap(currency)).forceApprove(spender, amount);
    }

    /// @notice Deposits a specified amount of a given currency into the contract
    /// @dev Handles both native and ERC20 token deposits
    /// @param currency The currency to deposit
    /// @param amount The amount of currency to deposit
    /// @return deposited The actual amount deposited
    function selfDeposit(Currency currency, uint96 amount) internal returns (uint96 deposited) {
        if (currency.isNative()) {
            if (msg.value < amount) revert AmountExceedsBalance();
            deposited = amount;
        } else {
            IERC20 token = IERC20(Currency.unwrap(currency));
            uint256 _balance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            // safe cast, transferred amount is <= 2^96-1
            deposited = SafeCastLib.safeCastTo96(token.balanceOf(address(this)) - _balance);
        }
    }

    /// @notice Withdraws a specified amount of a given currency to a specified address
    /// @param currency The currency and amount to withdraw (a160u96 format)
    /// @param kAmount The K amount to withdraw (in kind of currency)
    /// @param to The address to which the currency will be withdrawn
    /// @return amount The actual amount withdrawn
    function withdraw(a160u96 currency, uint256 kAmount, address to) internal returns (uint96 amount) {
        amount = uint96(kAmount.mulWadDown(currency.value()));
        if (to != address(this)) {
            currency.currency().transfer(to, amount);
        }
    }

    /// @notice Returns the balance of a given currency for a specific account
    /// @param currency The currency to check
    /// @param account The address of the account
    /// @return The balance of the specified currency for the given account
    function balanceOf(Currency currency, address account) internal view returns (uint256) {
        return currency.isNative() ? account.balance : IERC20(Currency.unwrap(currency)).balanceOf(account);
    }

    /// @notice Returns the balance of a given currency for this contract
    /// @param currency The currency to check
    /// @return The balance of the specified currency for this contract
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        return currency.isNative() ? address(this).balance : IERC20(Currency.unwrap(currency)).balanceOf(address(this));
    }

    /// @notice Checks if the specified currency is the native currency
    /// @param currency The currency to check
    /// @return `true` if the specified currency is the native currency, `false` otherwise
    function isNative(Currency currency) internal pure returns (bool) {
        return currency == NATIVE;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IIndex} from "../interfaces/IIndex.sol";

import {CommandLib} from "./CommandLib.sol";
import {CurrencyLib, SafeCastLib, Currency} from "./CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

library IndexCommandsLib {
    using CurrencyLib for *;

    error InvalidDepositData();
    error CurrencyBalanceOverdraft(CommandLib.BalanceState);

    function depositWithCommand(
        Currency reserve,
        IIndex.DepositParams calldata params,
        IIndex.DepositCommandParams calldata commandParams
    ) internal returns (uint96 deposited) {
        uint256 reserveBefore = _getBalance(reserve);
        uint256 balanceBefore = _getBalance(commandParams.currency);

        commandParams.currency.selfDeposit(params.amount);

        CommandLib.callCommand(
            commandParams.command,
            params.config.shared.metadata,
            CommandLib.BalanceState(commandParams.currency, balanceBefore)
        );

        if (commandParams.currency.balanceOfSelf() < balanceBefore) revert InvalidDepositData();

        deposited = SafeCastLib.safeCastTo96(reserve.balanceOfSelf() - reserveBefore);
    }

    function executeCommands(
        uint96 reserve,
        uint256 k,
        address metadata,
        a160u96[] calldata currencies,
        IIndex.RedemptionCommandParams calldata commandParams
    ) internal {
        uint256 currenciesLength = currencies.length;
        uint256 length = currenciesLength + commandParams.additionalCurrencies.length;
        CommandLib.BalanceState[] memory balanceStates = new CommandLib.BalanceState[](length);

        for (uint256 i; i < currenciesLength; ++i) {
            balanceStates[i] = _balanceState(currencies[i], k);
        }

        for (uint256 i; i < commandParams.additionalCurrencies.length; ++i) {
            balanceStates[currenciesLength + i] = CommandLib.BalanceState(
                commandParams.additionalCurrencies[i], commandParams.additionalCurrencies[i].balanceOfSelf()
            );
        }

        balanceStates[0].minBalance -= reserve;

        CommandLib.executeCommands(commandParams.currencyCommands, metadata, balanceStates);

        for (uint256 i; i < length; ++i) {
            _checkOverdraft(balanceStates[i]);
        }
    }

    function _balanceState(a160u96 currency, uint256 k)
        internal
        returns (CommandLib.BalanceState memory balanceState)
    {
        uint256 withdrawn = currency.withdraw(k, address(this));
        Currency _currency = currency.currency();
        return CommandLib.BalanceState(_currency, _currency.balanceOfSelf() - withdrawn);
    }

    function _checkOverdraft(CommandLib.BalanceState memory balanceState) internal view {
        if (balanceState.currency.balanceOfSelf() < balanceState.minBalance) {
            revert CurrencyBalanceOverdraft(balanceState);
        }
    }

    function _getBalance(Currency currency) private view returns (uint256 balance) {
        balance = currency.balanceOfSelf();
        if (currency.isNative()) balance -= msg.value;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {IBaseIndex} from "./interfaces/IBaseIndex.sol";

import {Currency} from "./libraries/CurrencyLib.sol";
import {IndexLib} from "./libraries/IndexLib.sol";

import {Vault, CurrencyRegistryLib} from "./Vault.sol";

abstract contract BaseIndex is Vault, IBaseIndex, IERC20Metadata, IERC20Permit {
    uint8 internal constant INDEX_REBALANCING_FLAG = 0x10;

    uint256 private immutable INITIAL_CHAIN_ID;
    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR;

    uint16 private immutable maxDepositFeeBPs;
    uint16 private immutable maxRedemptionFeeBPs;
    uint256 private immutable maxAUMDilutionPerSecond;

    Currency public immutable reserve;

    /// @inheritdoc IERC20Metadata
    uint8 public immutable override decimals = 18;
    /// @inheritdoc IERC20Metadata
    string public override name;
    /// @inheritdoc IERC20Metadata
    string public override symbol;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    IndexState internal state;
    bytes32 internal sharedConfigHash;
    bytes32 internal depositConfigHash;
    bytes32 internal redemptionConfigHash;

    event ConfigUpdated(bytes);
    event Deposit(address indexed sender, address indexed owner, uint256 reserve, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 shares,
        uint256 k,
        uint256 reserve
    );

    constructor(
        string memory _name,
        string memory _symbol,
        Currency _reserve,
        address _governance,
        address _messenger,
        uint16 _maxDepositFeeInBPs,
        uint16 _maxRedemptionFeeInBPs,
        uint256 _maxAUMDilutionPerSecond
    ) Vault(_governance, _messenger) {
        reserve = _reserve;
        name = _name;
        symbol = _symbol;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

        state.lastAUMAccrualTimestamp = uint32(block.timestamp);

        maxDepositFeeBPs = _maxDepositFeeInBPs;
        maxRedemptionFeeBPs = _maxRedemptionFeeInBPs;
        maxAUMDilutionPerSecond = _maxAUMDilutionPerSecond;

        CurrencyRegistryLib.registerCurrency(registry, _reserve);
    }

    function startIndexRebalancing() external onlyOwner {
        rebalancingFlags |= INDEX_REBALANCING_FLAG;
    }

    /// @dev sanitization is done externally - ensure that home assets include reserve to simplify before-after currency balance caching in redemptions
    function setConfig(
        Config calldata _prevConfig,
        DepositConfig calldata _depositConfig,
        RedemptionConfig calldata _redemptionConfig
    ) external onlyOwner {
        if (rebalancingFlags == 0) revert Rebalancing();

        bytes memory encodedConfig = abi.encode(_depositConfig.shared);
        if (keccak256(encodedConfig) != keccak256(abi.encode(_redemptionConfig.shared))) {
            revert IndexConfigMismatch();
        }

        // during initial config setup index consists of a single asset on home chain – reserve
        if (sharedConfigHash == hex"") {
            if (_redemptionConfig.homeCurrencies.length != 1) revert IndexInitialConfig();
        } else {
            if (sharedConfigHash != keccak256(abi.encode(_prevConfig))) revert IndexConfigMismatch();

            uint96 AUMFee;
            IndexState memory _state = state;
            (_state.totalSupply, AUMFee) = IndexLib.accrueAUMFee(_prevConfig, _state, maxAUMDilutionPerSecond);
            if (AUMFee != 0) {
                _state.fees += AUMFee;
                state = _state;

                emit IndexLib.FeeAccrued(0, AUMFee);
            }
        }

        if (
            _depositConfig.fee.BPs > maxDepositFeeBPs || _redemptionConfig.fee.BPs > maxRedemptionFeeBPs
                || _depositConfig.shared.AUMDilutionPerSecond > maxAUMDilutionPerSecond
        ) revert IndexLib.FeeExceedsMaxFee();

        sharedConfigHash = keccak256(encodedConfig);
        depositConfigHash = keccak256(abi.encode(_depositConfig));
        redemptionConfigHash = keccak256(abi.encode(_redemptionConfig));

        rebalancingFlags &= ~INDEX_REBALANCING_FLAG;

        emit ConfigUpdated(encodedConfig);
    }

    function accrueFee(address recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddressTransfer();

        uint96 _fees = state.fees;
        balanceOf[recipient] += _fees;
        state.fees = 0;

        emit IndexLib.FeeSettled(_fees);
        emit Transfer(address(0), recipient, _fees);
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _spendAllowance(amount, from, msg.sender);
        _transfer(from, to, amount);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (deadline < block.timestamp) revert PermitDeadlineExpired();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSigner();

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function reserveBalance() external view returns (uint96) {
        return state.reserve;
    }

    function kSelf() external view returns (uint256) {
        return kBalanceWads[anatomySnapshot][address(this)];
    }

    /// @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        return state.totalSupply;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddressTransfer();

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _spendAllowance(uint256 amount, address from, address to) internal {
        uint256 allowed = allowance[from][to]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) {
            allowance[from][to] = allowed - amount;
        }
    }

    function _deposit(DepositParams calldata params, uint96 deposited) internal {
        if (params.recipient == address(0)) revert ZeroAddressTransfer();

        _checkStateAndConfig(depositConfigHash, keccak256(abi.encode(params.config)));

        IndexState memory _state = state;
        uint256 shares = IndexLib.deposit(
            params,
            _state,
            IndexLib.Info(
                kBalanceWads[params.config.shared.latestSnapshot][address(this)],
                maxAUMDilutionPerSecond,
                maxDepositFeeBPs
            ),
            deposited
        );

        state = _state;
        balanceOf[params.recipient] += shares;

        emit Deposit(msg.sender, params.recipient, deposited, shares);
        emit Transfer(address(0), params.recipient, shares);
    }

    function _redeem(RedemptionParams calldata params, address forwardedSender)
        internal
        returns (RedeemedInfo memory redeemed)
    {
        _checkStateAndConfig(redemptionConfigHash, keccak256(abi.encode(params.config)));

        address sender = _sender(params.config.forwarder, forwardedSender);

        if (sender != params.owner) {
            _spendAllowance(params.shares, params.owner, sender);
        }

        IndexState memory _state = state;
        redeemed = IndexLib.redeem(
            sender,
            params,
            _state,
            IndexLib.Info(
                kBalanceWads[params.config.shared.latestSnapshot][address(this)],
                maxAUMDilutionPerSecond,
                maxRedemptionFeeBPs
            )
        );
        state = _state;

        balanceOf[params.owner] -= params.shares;

        emit Withdraw(sender, params.recipient, params.owner, params.shares, redeemed.k, redeemed.reserve);
        emit Transfer(params.owner, address(0), params.shares);
    }

    function _startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) internal override {
        if (rebalancingFlags & INDEX_REBALANCING_FLAG == 0) revert Rebalancing();

        uint96 reserveAmount = state.reserve;
        unaccountedBalanceOf[reserve] += reserveAmount;
        state.reserve = 0;

        emit Donate(reserve, reserveAmount);

        super._startRebalancingPhase(withdrawals);
    }

    function _sender(address forwarder, address forwardedSender) internal view returns (address sender) {
        if (forwarder != address(0)) {
            if (msg.sender != forwarder) revert InvalidSender();
            sender = forwardedSender;
        } else {
            sender = msg.sender;
        }
    }

    function _checkStateAndConfig(bytes32 storedHash, bytes32 newConfigHash) private view {
        if (rebalancingFlags != 0) revert Rebalancing();
        if (storedHash != newConfigHash) revert IndexConfigHash();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVault} from "./IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IBaseIndex is IVault {
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
        uint96 amount;
        address recipient;
        bytes payload;
    }

    struct RedemptionParams {
        RedemptionConfig config;
        uint256 expectedReserveValuation;
        uint256 AUMScaledK;
        address owner;
        uint128 shares;
        bytes payload;
        address payable recipient;
    }

    struct RedeemedInfo {
        uint96 reserve;
        uint256 reserveValuation;
        uint256 k;
    }

    error IndexConfigHash();
    error IndexConfigMismatch();
    error IndexInitialConfig();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error ZeroAddressTransfer();
    error InvalidSender();

    function startIndexRebalancing() external;

    function setConfig(
        Config calldata _prevConfig,
        DepositConfig calldata _depositConfig,
        RedemptionConfig calldata _redemptionConfig
    ) external;

    function accrueFee(address recipient) external;

    function reserve() external view returns (Currency);
    function reserveBalance() external view returns (uint96);
    function kSelf() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IValidator} from "../interfaces/IValidator.sol";

import {CurrencyLib, Currency} from "./CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

library CommandLib {
    using CurrencyLib for Currency;

    struct CommandTarget {
        a160u96 target;
        address spender;
        bool mapTarget;
        bytes[] datas;
        uint256[] packedConfigs;
    }

    struct BalanceState {
        Currency currency;
        uint256 minBalance;
    }

    struct Info {
        a160u96 target;
        address spender;
        bytes data;
    }

    uint256 internal constant PACKED_CONFIG_TARGET_CONFIG_BITS = 4;
    uint256 internal constant PACKED_CONFIG_SIZE_BITS = 20;
    uint256 internal constant PACKED_CONFIG_MASK = ~(type(uint256).max << PACKED_CONFIG_SIZE_BITS);

    error CallFailed(bytes);

    function callCommand(CommandTarget calldata command, address validator, BalanceState memory currencyState)
        internal
    {
        BalanceState[] memory currencyStates = new BalanceState[](1);
        currencyStates[0] = currencyState;

        _executeCommand(command, IValidator(validator), currencyStates);
    }

    function executeCommands(CommandTarget[] calldata commands, address validator, BalanceState[] memory currencyStates)
        internal
    {
        for (uint256 i; i < commands.length; ++i) {
            _executeCommand(commands[i], IValidator(validator), currencyStates);
        }
    }

    function _executeCommand(CommandTarget calldata cmd, IValidator validator, BalanceState[] memory currencyStates)
        internal
    {
        // only-target flag is set, batch call can be executed
        if (!cmd.mapTarget) validator.validate(currencyStates, cmd.target, cmd.packedConfigs);

        uint256 k;
        for (uint256 j; j < cmd.packedConfigs.length; ++j) {
            for (uint256 pc = cmd.packedConfigs[j]; pc != 0; pc >>= PACKED_CONFIG_SIZE_BITS) {
                BalanceState memory state = currencyStates[uint16(pc >> PACKED_CONFIG_TARGET_CONFIG_BITS) - 1];
                if (cmd.mapTarget) {
                    Info memory info = validator.mapTarget(state, cmd.target, pc & PACKED_CONFIG_MASK, cmd.datas[k]);
                    _call(state.currency, info.target, info.spender, info.data);
                } else {
                    _call(state.currency, cmd.target, cmd.spender, cmd.datas[k]);
                }

                unchecked {
                    // cannot overflow,
                    ++k;
                }
            }
        }
    }

    function _call(Currency currency, a160u96 target, address spender, bytes memory data)
        private
        returns (bool success, bytes memory returnData)
    {
        bool approve = spender != address(0);
        if (approve) currency.approve(spender, type(uint256).max);

        (address targetAddr, uint96 value) = target.unpackRaw();
        (success, returnData) = targetAddr.call{value: value}(data);
        if (!success) revert CallFailed(returnData);

        if (approve) currency.approve(spender, 0);
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IIndexMetadata} from "../interfaces/IIndexMetadata.sol";
import {IBaseIndex} from "../interfaces/IBaseIndex.sol";

import {IStaticPriceOracle} from "../price-oracles/interfaces/IStaticPriceOracle.sol";

import {FeeMathLib} from "./FeeMathLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IndexConversionLib} from "./IndexConversionLib.sol";
import {PriceLib} from "../price-oracles/libraries/PriceLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

library IndexLib {
    using FixedPointMathLib for uint256;
    using PriceLib for *;

    struct Info {
        uint256 kSelf;
        uint256 maxAUMDilutionPerSecond;
        uint16 maxFeeBPs;
    }

    event FeeAccrued(uint96 baseFee, uint96 AUMFee);
    event FeeSettled(uint96 fee);

    error ZeroShares();
    error FeeExceedsMaxFee();

    function deposit(
        IBaseIndex.DepositParams calldata params,
        IBaseIndex.IndexState memory state,
        Info memory info,
        uint96 deposited
    ) internal returns (uint256 netShares) {
        // accrue AUM fee
        (uint128 totalSupplyAfterAUMAccrual, uint96 AUMFee) =
            accrueAUMFee(params.config.shared, state, info.maxAUMDilutionPerSecond);

        uint128 grossShares;
        {
            (uint256 totalAssets,, uint256 reservePrice) =
                totalAssets(params.config.shared, params.payload, state.reserve, info.kSelf);
            grossShares = IndexConversionLib.convertToShares(
                SafeCastLib.safeCastTo96(deposited.convertToBaseDown(reservePrice)),
                totalSupplyAfterAUMAccrual,
                totalAssets
            );
        }

        uint96 depositFee;
        (netShares, depositFee) =
            _getFee(true, msg.sender, info.maxFeeBPs, grossShares, params.config.fee, params.config.shared, state);

        state.fees += depositFee + AUMFee;
        emit FeeAccrued(depositFee, AUMFee);

        if (netShares == 0) revert ZeroShares();

        state.reserve += deposited;
        state.totalSupply = totalSupplyAfterAUMAccrual + grossShares;
    }

    function redeem(
        address sender,
        IBaseIndex.RedemptionParams calldata params,
        IBaseIndex.IndexState memory state,
        Info memory info
    ) internal returns (IBaseIndex.RedeemedInfo memory redeemed) {
        if (params.shares == 0) revert ZeroShares();

        (uint128 totalSupplyAfterAUMAccrual, uint96 AUMFee) =
            accrueAUMFee(params.config.shared, state, info.maxAUMDilutionPerSecond);

        (uint128 netShares, uint96 redemptionFee) =
            _getFee(false, sender, info.maxFeeBPs, params.shares, params.config.fee, params.config.shared, state);

        state.fees += redemptionFee + AUMFee;
        emit FeeAccrued(redemptionFee, AUMFee);

        (uint256 totalAssets, uint256 reserveValuation, uint256 reservePrice) =
            totalAssets(params.config.shared, params.payload, state.reserve, info.kSelf);

        uint256 reserveSharesRedeemed;
        (redeemed.reserve, reserveSharesRedeemed) = _calculateReserveRedeemed(
            netShares, totalSupplyAfterAUMAccrual, state.reserve, reserveValuation, totalAssets
        );
        redeemed.reserveValuation = redeemed.reserve.convertToBaseDown(reservePrice);
        redeemed.k = _calculateKRedeemed(info.kSelf, reserveSharesRedeemed, netShares, totalSupplyAfterAUMAccrual);

        state.totalSupply = totalSupplyAfterAUMAccrual - netShares;
        state.reserve -= redeemed.reserve;
    }

    function totalAssets(
        IBaseIndex.Config calldata config,
        bytes calldata payload,
        uint256 reserveBalance,
        uint256 kSelf
    ) internal returns (uint256 totalAssets, uint256 reserveValuation, uint256 reservePrice) {
        (reservePrice, totalAssets) = IStaticPriceOracle(config.staticPriceOracle).valuation(payload);
        reserveValuation = reserveBalance.convertToBaseDown(reservePrice);
        totalAssets = totalAssets.mulWadDown(kSelf) + reserveValuation;
    }

    function accrueAUMFee(
        IBaseIndex.Config calldata config,
        IBaseIndex.IndexState memory state,
        uint256 maxAUMDilutionPerSecond
    ) internal view returns (uint128 totalSupplyAfterAUMAccrual, uint96 AUMFee) {
        uint256 AUMDilutionPerSecond;
        if (config.useCustomAUMFee) {
            AUMDilutionPerSecond = IIndexMetadata(config.metadata).AUMDilutionPerSecond(config, state);
            if (AUMDilutionPerSecond > maxAUMDilutionPerSecond) revert FeeExceedsMaxFee();
        } else {
            // AUMDilutionPerSecond cannot exceed max, config setter shouldn't allow that
            AUMDilutionPerSecond = config.AUMDilutionPerSecond;
        }

        uint32 AUMAccrualTimestamp;
        (totalSupplyAfterAUMAccrual, AUMAccrualTimestamp, AUMFee) = FeeMathLib.accrueTotalSupplyAUMFee(
            AUMDilutionPerSecond, state.totalSupply, state.lastAUMAccrualTimestamp, block.timestamp
        );
        state.lastAUMAccrualTimestamp = AUMAccrualTimestamp;
    }

    function _getFee(
        bool isDeposit,
        address sender,
        uint16 maxFeeBPs,
        uint128 shares,
        IBaseIndex.FeeConfig calldata fee,
        IBaseIndex.Config calldata config,
        IBaseIndex.IndexState memory state
    ) private view returns (uint128 netShares, uint96 fees) {
        uint16 feeBPs = fee.BPs;
        if (fee.useCustomCallback) {
            feeBPs = isDeposit
                ? IIndexMetadata(config.metadata).depositFeeInBPs(config, state, shares, sender)
                : IIndexMetadata(config.metadata).redemptionFeeInBPs(config, state, shares, sender);
            if (feeBPs > maxFeeBPs) revert FeeExceedsMaxFee();
        }
        return FeeMathLib.accrueFee(shares, feeBPs);
    }

    function _calculateReserveRedeemed(
        uint256 netRedeemedShares,
        uint256 totalSupplyAfterAUMAccrual,
        uint96 reserveBalance,
        uint256 reserveValuation,
        uint256 totalValuation
    ) private pure returns (uint96 reserveRedeemed, uint256 reserveSharesRedeemed) {
        uint256 totalReserveShares;
        if (totalValuation != 0) {
            totalReserveShares = reserveValuation.mulDivUp(totalSupplyAfterAUMAccrual, totalValuation);
        }

        reserveSharesRedeemed = netRedeemedShares < totalReserveShares ? netRedeemedShares : totalReserveShares;
        if (totalReserveShares != 0) {
            // safe cast, reserve shares * (2^96-1) / total reserve shares <= (2^96-1)
            reserveRedeemed = uint96(reserveSharesRedeemed.mulDivDown(reserveBalance, totalReserveShares));
        }
    }

    function _calculateKRedeemed(
        uint256 totalFixedAnatomyShares,
        uint256 reserveSharesRedeemed,
        uint256 netRedeemedShares,
        uint256 totalSupplyAfterAUMAccrual
    ) private pure returns (uint256 kRedeemed) {
        unchecked {
            // cannot overflow, burned reserve shares are always less than or equal to total supply
            uint256 totalSupplyAfterReserveRedemption = totalSupplyAfterAUMAccrual - reserveSharesRedeemed;
            // cannot overflow, burned reserve shares are always less than or equal to net redeemed shares
            if (totalSupplyAfterReserveRedemption == 0) return 0;

            uint256 sharesAfterReserveRedemption = netRedeemedShares - reserveSharesRedeemed;
            return sharesAfterReserveRedemption.mulDivDown(totalFixedAnatomyShares, totalSupplyAfterReserveRedemption);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IPhutureOnDonationCallback} from "./interfaces/IPhutureOnDonationCallback.sol";
import {IPhutureOnConsumeCallback} from "./interfaces/IPhutureOnConsumeCallback.sol";
import {IVault} from "./interfaces/IVault.sol";

import {BitSet} from "./libraries/BitSet.sol";
import {CurrencyLib, Currency} from "./libraries/CurrencyLib.sol";
import {AnatomyValidationLib} from "./libraries/AnatomyValidationLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {a160u96} from "./utils/a160u96.sol";
import {CurrencyRegistryLib} from "./libraries/CurrencyRegistryLib.sol";

import {Extsload} from "./Extsload.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract Vault is IVault, Owned, ReentrancyGuard, Extsload {
    using BitSet for uint256[];
    using CurrencyLib for *;
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using CurrencyRegistryLib for CurrencyRegistryLib.Registry;

    uint8 internal constant VAULT_REBALANCING_FLAG = 0x01;

    uint8 internal rebalancingFlags;

    address internal orderBook;
    address internal messenger;
    uint256 internal anatomySnapshot;

    CurrencyRegistryLib.Registry internal registry;

    // packed currency balances for snapshot
    mapping(uint256 => a160u96[]) internal currenciesOf;

    mapping(uint256 => bytes32) internal currencyHashOf;
    // bit set, stores if currency balance exists for snapshot
    mapping(uint256 => uint256[]) internal currencySetOf;

    mapping(Currency => uint96) internal unaccountedBalanceOf;

    // k balance for snapshot
    mapping(uint256 => mapping(address => uint256)) public kBalanceWads;

    event SnapshotTransfer(uint256 snapshot, uint256 amount, address indexed from, address indexed to);
    event StartRebalancing(uint256 snapshot, uint256 kBalance, CurrencyWithdrawal withdrawals);
    event FinishRebalancing(uint256 snapshot, a160u96[] currencies);
    event Donate(Currency currency, uint256 amount);
    event Consume(Currency currency, uint256 amount);

    error Forbidden();
    error HashMismatch();
    error Rebalancing();
    error InvalidWithdrawal();

    modifier only(address addr) {
        _checkSender(addr);
        _;
    }

    constructor(address _owner, address _messenger) Owned(_owner) {
        messenger = _messenger;
        currencyHashOf[0] = keccak256(abi.encode(new a160u96[](0)));
    }

    receive() external payable {}

    function setMessenger(address _messenger) external only(owner) {
        messenger = _messenger;
    }

    function setOrderBook(address _orderBook) external only(owner) {
        orderBook = _orderBook;
    }

    function startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) external only(messenger) {
        _startRebalancingPhase(withdrawals);
    }

    function finishRebalancingPhase(EndRebalancingParams calldata params)
        external
        only(messenger)
        returns (bytes32 resultHash)
    {
        uint8 _rebalancingFlags = rebalancingFlags;
        if (_rebalancingFlags == 0) revert Rebalancing();

        uint256 snapshot = anatomySnapshot;

        // check if anatomy and withdrawal hashes match the stored version
        // hash allows us to recover anatomy and withdrawals from memory
        if (currencyHashOf[snapshot] != keccak256(abi.encode(params.withdrawals, params.lastKBalance))) {
            revert HashMismatch();
        }

        uint256 lastSnapshot;
        unchecked {
            // cannot overflow, snapshot > 0
            lastSnapshot = snapshot - 1;
        }

        if (currencyHashOf[lastSnapshot] != keccak256(abi.encode(params.anatomyCurrencies))) {
            revert HashMismatch();
        }

        AnatomyValidationLib.validate(
            unaccountedBalanceOf, currencySetOf[lastSnapshot], registry.currenciesHash, params
        );

        currenciesOf[snapshot] = params.newAnatomy.currencies;
        currencyHashOf[snapshot] = keccak256(abi.encode(params.newAnatomy.currencies));
        currencySetOf[snapshot] = params.newAnatomy.currencyIndexSet;

        // issue the new sub index k shares
        kBalanceWads[snapshot][address(this)] = FixedPointMathLib.WAD;
        emit SnapshotTransfer(snapshot, FixedPointMathLib.WAD, address(0), address(this));

        // end vault rebalancing phase
        rebalancingFlags = _rebalancingFlags & ~VAULT_REBALANCING_FLAG;

        emit FinishRebalancing(snapshot, params.newAnatomy.currencies);

        resultHash = keccak256(
            abi.encode(
                RebalancingResult(
                    block.chainid, snapshot, params.newAnatomy.currencyIndexSet, params.newAnatomy.currencies
                )
            )
        );
    }

    function donate(Currency currency, bytes memory data) external nonReentrant only(orderBook) {
        uint256 balanceBefore = currency.balanceOfSelf();

        IPhutureOnDonationCallback(msg.sender).phutureOnDonationCallbackV1(data);

        uint96 delta = (currency.balanceOfSelf() - balanceBefore).safeCastTo96();
        unaccountedBalanceOf[currency] += delta;
        emit Donate(currency, delta);
    }

    function consume(Currency currency, uint96 amount, address target, bytes calldata data) external only(orderBook) {
        if (rebalancingFlags == 0) revert Rebalancing();

        unaccountedBalanceOf[currency] -= amount;

        currency.transfer(target, amount);
        IPhutureOnConsumeCallback(target).phutureOnConsumeCallbackV1(data);

        emit Consume(currency, amount);
    }

    function registerCurrencies(Currency[] calldata currencies)
        external
        only(owner)
        returns (RegisterCurrenciesResult memory result)
    {
        result.currencies = currencies;
        for (uint256 i; i < currencies.length; ++i) {
            result.currenciesHash = registry.registerCurrency(currencies[i]);
        }
    }

    function transferLatestSnapshot(address recipient, uint256 kAmountWads)
        external
        only(messenger)
        returns (uint256 snapshot)
    {
        if (rebalancingFlags != 0) revert Rebalancing();

        snapshot = anatomySnapshot;
        _transferSnapshot(snapshot, kAmountWads, address(this), recipient);
    }

    function withdraw(uint256 snapshot, uint256 kAmount, address recipient) external {
        _burnSnapshot(snapshot, msg.sender, kAmount);

        a160u96[] memory currencies = currenciesOf[snapshot];
        uint256 length = currencies.length;

        for (uint256 i; i < length; ++i) {
            currencies[i].withdraw(kAmount, recipient);
        }
    }

    function _startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) internal virtual {
        if (rebalancingFlags & VAULT_REBALANCING_FLAG != 0) revert Rebalancing();

        uint256 snapshot = anatomySnapshot;

        Currency[] memory currencies = registry.currencies;
        uint256[] memory currencySet = currencySetOf[snapshot];
        uint256 withdrawalIndex;
        for (uint256 i; i < currencies.length; ++i) {
            if (withdrawals.currencyIndexSet.contains(i)) {
                if (!currencySet.contains(i)) revert InvalidWithdrawal();

                unaccountedBalanceOf[currencies[i]] += withdrawals.amounts[withdrawalIndex];

                unchecked {
                    ++withdrawalIndex;
                }
            }
        }

        // enter rebalancing phase
        uint256 kBalance = kBalanceWads[snapshot][address(this)];

        _burnSnapshot(snapshot, address(this), kBalance);

        currencyHashOf[++snapshot] = keccak256(abi.encode(withdrawals, kBalance));
        rebalancingFlags |= VAULT_REBALANCING_FLAG;
        anatomySnapshot = snapshot;

        emit StartRebalancing(snapshot, kBalance, withdrawals);
    }

    function _burnSnapshot(uint256 snapshot, address from, uint256 kAmountWads) internal {
        if (kAmountWads == 0) return;

        kBalanceWads[snapshot][from] -= kAmountWads;
        emit SnapshotTransfer(snapshot, kAmountWads, from, address(0));
    }

    function _transferSnapshot(uint256 snapshot, uint256 kAmountWads, address from, address recipient) internal {
        kBalanceWads[snapshot][from] -= kAmountWads;
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            kBalanceWads[snapshot][recipient] += kAmountWads;
        }
        emit SnapshotTransfer(snapshot, kAmountWads, from, recipient);
    }

    function _checkSender(address addr) private view {
        if (msg.sender != addr) revert Forbidden();
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {CommandLib} from "../libraries/CommandLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IValidator {
    function validate(
        CommandLib.BalanceState[] calldata currencyStates,
        a160u96 target,
        uint256[] calldata packedConfigs
    ) external;

    function mapTarget(
        CommandLib.BalanceState calldata currencyState,
        a160u96 target,
        uint256 packedConfig,
        bytes calldata data
    ) external returns (CommandLib.Info memory targetInfo);

    function updateTarget(address target, bool isAllowed) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IFeeQuoter} from "./IFeeQuoter.sol";
import {IValidator} from "../interfaces/IValidator.sol";

interface IIndexMetadata is IFeeQuoter, IValidator {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

interface IStaticPriceOracle {
    function valuation(bytes calldata) external returns (uint256 _reservePrice, uint256 _valuation);

    function pricesAndBalances(bytes calldata) external returns (uint256[] memory _prices, uint96[] memory _balances);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

library FeeMathLib {
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;

    uint16 internal constant MAX_BPS = 10_000;

    uint256 private constant RATE_SCALE_BASE = 1e27;

    /// AUMDilutionPerSecond = ((1 + k) ** (1 / 365 days)) * 10e27
    /// k - AUM fee in % (100% = 1)
    function accrueTotalSupplyAUMFee(
        uint256 AUMDilutionPerSecond,
        uint128 totalSupply,
        uint32 lastAUMAccrualTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint128 newTotalSupply, uint32 newLastAUMAccrualTimestamp, uint96 AUMFee) {
        newTotalSupply = totalSupply;
        newLastAUMAccrualTimestamp = uint32(currentTimestamp);
        if (AUMDilutionPerSecond != 0) {
            uint256 timePassed;
            unchecked {
                timePassed = newLastAUMAccrualTimestamp - lastAUMAccrualTimestamp;
            }

            if (timePassed != 0) {
                uint256 numerator = AUMDilutionPerSecond.rpow(timePassed, RATE_SCALE_BASE) - RATE_SCALE_BASE;
                AUMFee = totalSupply.mulDivDown(numerator, RATE_SCALE_BASE).safeCastTo96();
                newTotalSupply += AUMFee;
            }
        }
    }

    function accrueFee(uint128 grossShares, uint16 feeBPs) internal pure returns (uint128 netShares, uint96 fee) {
        unchecked {
            fee = uint256(grossShares).mulDivDown(feeBPs, MAX_BPS).safeCastTo96();
            netShares = grossShares - fee;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title A library for converting assets and shares
library IndexConversionLib {
    using SafeCastLib for uint256;
    using FixedPointMathLib for *;

    /// @dev Initial price should be 100 USD
    /// 10 ** (indexDecimals - initialPriceScalingFactor) / 10 ** (PRICE_ORACLE_DECIMALS) = 10 ** (16) / 10 ** (18) = 1e-2.
    uint128 private constant PRICE_SCALING_FACTOR = 1e2;

    /// @notice Converts asset amount to shares based on the supply and valuation
    /// @param assets The amount of assets (in base) to be converted
    /// @param supply The total supply of shares
    /// @param valuation The total valuation of assets
    /// @return The number of shares corresponding to the given asset amount
    function convertToShares(uint96 assets, uint128 supply, uint256 valuation) internal pure returns (uint128) {
        return (supply == 0 ? assets / PRICE_SCALING_FACTOR : assets.mulDivDown(supply, valuation)).safeCastTo128();
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IPhutureOnDonationCallback {
    function phutureOnDonationCallbackV1(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IPhutureOnConsumeCallback {
    function phutureOnConsumeCallbackV1(bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library BitSet {
    uint256 private constant WORD_SHIFT = 8;

    function hasNext(uint256 word, uint256 bit) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := and(shr(bit, word), 1)
        }
    }

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

    function valueAt(uint256 wordIndex, uint256 bit) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := or(shl(8, wordIndex), bit)
        }
    }

    function create(uint256 maxSize) internal pure returns (uint256[] memory bitset) {
        bitset = new uint256[](_capacity(maxSize));
    }

    function contains(uint256[] memory bitset, uint256 value) internal pure returns (bool _contains) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        if (wordIndex < bitset.length) {
            _contains = (bitset[wordIndex] & (1 << bit)) != 0;
        }
    }

    function add(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] |= (1 << bit);
        return bitset;
    }

    // a + b, add all elements of b from a
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

    function remove(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] &= ~(1 << bit);
        return bitset;
    }

    function size(uint256[] memory bitset) internal pure returns (uint256 count) {
        for (uint256 i; i < bitset.length; ++i) {
            count += _countSetBits(bitset[i]);
        }
    }

    function _bitOffset(uint256 value) private pure returns (uint256 wordIndex, uint8 bit) {
        assembly ("memory-safe") {
            wordIndex := shr(8, value)
            // mask bits that don't fit the first wordIndex's bits
            // n % 2^i = n & (2^i - 1)
            bit := and(value, 255)
        }
    }

    function _capacity(uint256 maxSize) private pure returns (uint256 words) {
        // round up
        words = (maxSize + type(uint8).max) >> WORD_SHIFT;
    }

    function _countSetBits(uint256 x) private pure returns (uint256 count) {
        // Brian Kernighan’s Algorithm
        while (x != 0) {
            unchecked {
                // cannot overflow, x > 0
                x = x & (x - 1);
                ++count;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IVault} from "../interfaces/IVault.sol";

import {BitSet} from "./BitSet.sol";
import {CurrencyLib, Currency} from "./CurrencyLib.sol";
import {a160u96, A160U96Factory} from "../utils/a160u96.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library AnatomyValidationLib {
    using CurrencyLib for *;
    using FixedPointMathLib for uint256;
    using BitSet for uint256[];

    struct Indexes {
        uint256 anatomy;
        uint256 newAnatomy;
        uint256 withdrawal;
    }

    error CurrenciesHashMismatch();
    error ExcessNewAnatomyCurrencyIndex(uint256 currencyIndex);
    error NewAnatomyCurrencyIndexNotFound(uint256 currencyIndex);
    error NewAnatomyCurrencyCountMismatch(uint256 expectedCount);
    error NewAnatomyCurrencyIndexSetSizeMismatch(uint256 expectedCount);
    error NewAnatomyCurrencyMismatch(a160u96 expectedCurrency);

    function validate(
        mapping(Currency => uint96) storage unaccountedBalanceOf,
        uint256[] memory anatomyCurrencyIndexSet,
        bytes32 currenciesHash,
        IVault.EndRebalancingParams calldata params
    ) internal {
        Indexes memory indexes;
        bytes32 _currenciesHash;
        for (uint256 i; i < params.currencies.length; ++i) {
            Currency currency = params.currencies[i];

            _currenciesHash = keccak256(abi.encode(_currenciesHash, currency));

            uint96 balance = unaccountedBalanceOf[currency];
            if (balance != 0) delete unaccountedBalanceOf[currency];

            if (anatomyCurrencyIndexSet.contains(i)) {
                balance += uint96(params.lastKBalance.mulWadDown(params.anatomyCurrencies[indexes.anatomy].value()));

                if (params.withdrawals.currencyIndexSet.contains(i)) {
                    balance -= params.withdrawals.amounts[indexes.withdrawal];

                    unchecked {
                        ++indexes.withdrawal;
                    }
                }

                unchecked {
                    ++indexes.anatomy;
                }
            }

            if (balance == 0) {
                // new anatomy shouldn't contain any currencies without balances
                if (params.newAnatomy.currencyIndexSet.contains(i)) revert ExcessNewAnatomyCurrencyIndex(i);
            } else {
                // new anatomy must contain all non-zero currency balances
                if (!params.newAnatomy.currencyIndexSet.contains(i)) revert NewAnatomyCurrencyIndexNotFound(i);

                a160u96 _currency = A160U96Factory.create(currency, balance);
                if (params.newAnatomy.currencies[indexes.newAnatomy] != _currency) {
                    revert NewAnatomyCurrencyMismatch(_currency);
                }

                unchecked {
                    // cannot overflow, new anatomy index < (old anatomy + updates)
                    ++indexes.newAnatomy;
                }
            }
        }

        if (_currenciesHash != currenciesHash) revert CurrenciesHashMismatch();

        if (indexes.newAnatomy != params.newAnatomy.currencies.length) {
            revert NewAnatomyCurrencyCountMismatch(indexes.newAnatomy);
        }

        if (indexes.newAnatomy != params.newAnatomy.currencyIndexSet.size()) {
            revert NewAnatomyCurrencyIndexSetSizeMismatch(indexes.newAnatomy);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title A library for managing a registry of currencies
library CurrencyRegistryLib {
    /// @dev Represents a currency registry
    struct Registry {
        // Array of registered assets
        Currency[] currencies;
        // Hash of registry state
        bytes32 currenciesHash;
        // Registered flag for given currency
        mapping(Currency => bool) registered;
    }

    /// @dev Thrown when trying to register an already registered currency.
    error Registered(Currency);

    /// @notice Registers a new currency in the registry
    /// @param self The registry where the currency will be registered
    /// @param currency The currency to register
    /// @return newHash The new hash of the updated registry
    function registerCurrency(Registry storage self, Currency currency) internal returns (bytes32 newHash) {
        if (self.registered[currency]) revert Registered(currency);

        self.currencies.push(currency);
        newHash = keccak256(abi.encode(self.currenciesHash, currency));
        self.currenciesHash = newHash;
        self.registered[currency] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @author Modified from RageTrade (https://github.com/RageTrade/core/blob/main/contracts/utils/Extsload.sol)
abstract contract Extsload {
    function extsload(bytes32 slot) external view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(slot)
        }
    }

    function extsload(bytes32[] memory slots) external view returns (bytes32[] memory) {
        assembly ("memory-safe") {
            let end := add(32, add(slots, mul(mload(slots), 32)))
            for { let ptr := add(slots, 32) } lt(ptr, end) { ptr := add(ptr, 32) } { mstore(ptr, sload(mload(ptr))) }
        }

        return slots;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IBaseIndex} from "./IBaseIndex.sol";

interface IFeeQuoter {
    function depositFeeInBPs(
        IBaseIndex.Config calldata config,
        IBaseIndex.IndexState calldata state,
        uint128 depositedShares,
        address sender
    ) external view returns (uint16 feeInBPs);

    function redemptionFeeInBPs(
        IBaseIndex.Config calldata config,
        IBaseIndex.IndexState calldata state,
        uint128 redeemedShares,
        address sender
    ) external view returns (uint16 feeInBPs);

    function AUMDilutionPerSecond(IBaseIndex.Config calldata config, IBaseIndex.IndexState calldata state)
        external
        view
        returns (uint256 dilutionPerSecond);
}