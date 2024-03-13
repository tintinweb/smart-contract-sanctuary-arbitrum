// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {RedstoneConsumerNumericBase} from
    "@redstone-finance/evm-connector/contracts/core/RedstoneConsumerNumericBase.sol";

import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";
import {IncorrectPriceException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

/// @dev Max period that the payload can be backward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_DELAY_SECONDS = 10 minutes;

/// @dev Max period that the payload can be forward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

/// @dev Max number of authorized signers
uint256 constant MAX_SIGNERS = 10;

interface IRedstonePriceFeedExceptions {
    /// @notice Thrown when trying to construct a price feed with incorrect signers threshold
    error IncorrectSignersThresholdException();

    /// @notice Thrown when the provided set of signers is smaller than the threshold
    error NotEnoughSignersException();

    /// @notice Thrown when the provided set of signers contains duplicates
    error DuplicateSignersException();

    /// @notice Thrown when attempting to push an update with the payload that is older than the last
    ///         update payload, or too far from the current block timestamp
    error RedstonePayloadTimestampIncorrect();

    /// @notice Thrown when data package timestamp is not equal to expected payload timestamp
    error DataPackageTimestampIncorrect();
}

interface IRedstonePriceFeedEvents {
    /// @notice Emitted when a successful price update is pushed
    /// @param price New USD price of the token with 8 decimals
    event UpdatePrice(uint256 price);
}

/// @title Redstone price feed
contract RedstonePriceFeed is
    IUpdatablePriceFeed,
    IRedstonePriceFeedExceptions,
    IRedstonePriceFeedEvents,
    RedstoneConsumerNumericBase
{
    using SafeCast for uint256;

    PriceFeedType public constant override priceFeedType = PriceFeedType.REDSTONE_ORACLE;
    uint256 public constant override version = 3_00;
    uint8 public constant override decimals = 8;
    bool public constant override skipPriceCheck = false;
    bool public constant override updatable = true;

    /// @notice Token for which the prices are provided
    address public immutable token;

    /// @notice ID of the asset in Redstone's payload
    bytes32 public immutable dataFeedId;

    address public immutable signerAddress0;
    address public immutable signerAddress1;
    address public immutable signerAddress2;
    address public immutable signerAddress3;
    address public immutable signerAddress4;
    address public immutable signerAddress5;
    address public immutable signerAddress6;
    address public immutable signerAddress7;
    address public immutable signerAddress8;
    address public immutable signerAddress9;

    /// @dev Minimal number of unique signatures from authorized signers required to validate a payload
    uint8 internal immutable _signersThreshold;

    /// @notice The last stored price value
    uint128 public lastPrice;

    /// @notice The timestamp of the last update's payload
    uint40 public lastPayloadTimestamp;

    constructor(address _token, bytes32 _dataFeedId, address[MAX_SIGNERS] memory _signers, uint8 signersThreshold) {
        if (signersThreshold == 0 || signersThreshold > MAX_SIGNERS) revert IncorrectSignersThresholdException();
        unchecked {
            uint256 numSigners;
            for (uint256 i; i < MAX_SIGNERS; ++i) {
                if (_signers[i] == address(0)) continue;
                for (uint256 j = i + 1; j < MAX_SIGNERS; ++j) {
                    if (_signers[j] == _signers[i]) revert DuplicateSignersException();
                }
                ++numSigners;
            }
            if (numSigners < signersThreshold) revert NotEnoughSignersException();
        }

        token = _token;
        dataFeedId = _dataFeedId; // U:[RPF-1]

        signerAddress0 = _signers[0];
        signerAddress1 = _signers[1];
        signerAddress2 = _signers[2];
        signerAddress3 = _signers[3];
        signerAddress4 = _signers[4];
        signerAddress5 = _signers[5];
        signerAddress6 = _signers[6];
        signerAddress7 = _signers[7];
        signerAddress8 = _signers[8];
        signerAddress9 = _signers[9];

        _signersThreshold = signersThreshold; // U:[RPF-1]
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked(ERC20(token).symbol(), " / USD Redstone price feed")); // U:[RPF-1]
    }

    /// @notice Returns the USD price of the token with 8 decimals and the last update timestamp
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(uint256(lastPrice)), 0, lastPayloadTimestamp, 0); // U:[RPF-2]
    }

    /// @notice Saves validated price retrieved from the passed Redstone payload
    /// @param data A data blob with with 2 parts:
    ///        - A timestamp expected to be in all Redstone data packages
    ///        - Redstone payload with price update
    function updatePrice(bytes calldata data) external override {
        (uint256 expectedPayloadTimestamp,) = abi.decode(data, (uint256, bytes));

        // We want to minimize price update execution, in case, e.g., when several users submit
        // the same price update in a short span of time. So only updates with a larger payload timestamp
        // are fully validated and applied
        if (expectedPayloadTimestamp <= lastPayloadTimestamp) return; // U:[RPF-4]

        // We validate and set the payload timestamp here. Data packages' timestamps being equal
        // to the expected timestamp is checked in `validateTimestamp()`, which is called
        // from inside `getOracleNumericValueFromTxMsg`
        _validateExpectedPayloadTimestamp(expectedPayloadTimestamp);
        lastPayloadTimestamp = uint40(expectedPayloadTimestamp); // U:[RPF-2,5]

        uint256 priceValue = getOracleNumericValueFromTxMsg(dataFeedId); // U:[RPF-7]

        if (priceValue == 0) revert IncorrectPriceException(); // U:[RPF-8]

        if (priceValue != lastPrice) {
            lastPrice = priceValue.toUint128(); // U:[RPF-2,5]
            emit UpdatePrice(priceValue); // U:[RPF-2,5]
        }
    }

    /// @notice Returns the number of unique signatures required to validate a payload
    function getUniqueSignersThreshold() public view virtual override returns (uint8) {
        return _signersThreshold;
    }

    /// @notice Returns the index of the provided signer or reverts if the address is not a signer
    function getAuthorisedSignerIndex(address signerAddress) public view virtual override returns (uint8) {
        if (signerAddress == address(0)) revert SignerNotAuthorised(signerAddress);

        if (signerAddress == signerAddress0) return 0;
        if (signerAddress == signerAddress1) return 1;
        if (signerAddress == signerAddress2) return 2;
        if (signerAddress == signerAddress3) return 3;
        if (signerAddress == signerAddress4) return 4;
        if (signerAddress == signerAddress5) return 5;
        if (signerAddress == signerAddress6) return 6;
        if (signerAddress == signerAddress7) return 7;
        if (signerAddress == signerAddress8) return 8;
        if (signerAddress == signerAddress9) return 9;

        revert SignerNotAuthorised(signerAddress); // U:[RPF-6]
    }

    /// @notice Validates that a timestamp in a data package is valid
    /// @dev Sanity checks on the timestamp are performed earlier in the update,
    ///      when the lastPayloadTimestamp is being set
    /// @param receivedTimestampMilliseconds Timestamp in the data package, in milliseconds
    function validateTimestamp(uint256 receivedTimestampMilliseconds) public view override {
        uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;

        if (receivedTimestampSeconds != lastPayloadTimestamp) {
            revert DataPackageTimestampIncorrect(); // U:[RPF-3]
        }
    }

    /// @dev Validates that the expected payload timestamp is not older than the last payload's,
    ///      and not too far from the current block's
    /// @param expectedPayloadTimestamp Timestamp expected to be in all of the incoming payload's packages
    function _validateExpectedPayloadTimestamp(uint256 expectedPayloadTimestamp) internal view {
        if ((block.timestamp < expectedPayloadTimestamp)) {
            if ((expectedPayloadTimestamp - block.timestamp) > MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
                revert RedstonePayloadTimestampIncorrect(); // U:[RPF-9]
            }
        } else if ((block.timestamp - expectedPayloadTimestamp) > MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
            revert RedstonePayloadTimestampIncorrect(); // U:[RPF-9]
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./RedstoneConsumerBase.sol";

/**
 * @title The base contract for Redstone consumers' contracts that allows to
 * securely calculate numeric redstone oracle values
 * @author The Redstone Oracles team
 * @dev This contract can extend other contracts to allow them
 * securely fetch Redstone oracle data from transactions calldata
 */
abstract contract RedstoneConsumerNumericBase is RedstoneConsumerBase {
  /**
   * @dev This function can be used in a consumer contract to securely extract an
   * oracle value for a given data feed id. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedId bytes32 value that uniquely identifies the data feed
   * @return Extracted and verified numeric oracle value for the given data feed id
   */
  function getOracleNumericValueFromTxMsg(bytes32 dataFeedId)
    internal
    view
    virtual
    returns (uint256)
  {
    bytes32[] memory dataFeedIds = new bytes32[](1);
    dataFeedIds[0] = dataFeedId;
    return getOracleNumericValuesFromTxMsg(dataFeedIds)[0];
  }

  /**
   * @dev This function can be used in a consumer contract to securely extract several
   * numeric oracle values for a given array of data feed ids. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIds array
   */
  function getOracleNumericValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    virtual
    returns (uint256[] memory)
  {
    return _securelyExtractOracleValuesFromTxMsg(dataFeedIds);
  }

  /**
   * @dev This function works similarly to the `getOracleNumericValuesFromTxMsg` with the
   * only difference that it allows to request oracle data for an array of data feeds
   * that may contain duplicates
   * 
   * @param dataFeedIdsWithDuplicates An array of data feed identifiers (duplicates are allowed)
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIdsWithDuplicates array
   */
  function getOracleNumericValuesWithDuplicatesFromTxMsg(bytes32[] memory dataFeedIdsWithDuplicates) internal view returns (uint256[] memory) {
    // Building an array without duplicates
    bytes32[] memory dataFeedIdsWithoutDuplicates = new bytes32[](dataFeedIdsWithDuplicates.length);
    bool alreadyIncluded;
    uint256 uniqueDataFeedIdsCount = 0;

    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      // Checking if current element is already included in `dataFeedIdsWithoutDuplicates`
      alreadyIncluded = false;
      for (uint256 indexWithoutDup = 0; indexWithoutDup < uniqueDataFeedIdsCount; indexWithoutDup++) {
        if (dataFeedIdsWithoutDuplicates[indexWithoutDup] == dataFeedIdsWithDuplicates[indexWithDup]) {
          alreadyIncluded = true;
          break;
        }
      }

      // Adding if not included
      if (!alreadyIncluded) {
        dataFeedIdsWithoutDuplicates[uniqueDataFeedIdsCount] = dataFeedIdsWithDuplicates[indexWithDup];
        uniqueDataFeedIdsCount++;
      }
    }

    // Overriding dataFeedIdsWithoutDuplicates.length
    // Equivalent to: dataFeedIdsWithoutDuplicates.length = uniqueDataFeedIdsCount;
    assembly {
      mstore(dataFeedIdsWithoutDuplicates, uniqueDataFeedIdsCount)
    }

    // Requesting oracle values (without duplicates)
    uint256[] memory valuesWithoutDuplicates = getOracleNumericValuesFromTxMsg(dataFeedIdsWithoutDuplicates);

    // Preparing result values array
    uint256[] memory valuesWithDuplicates = new uint256[](dataFeedIdsWithDuplicates.length);
    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      for (uint256 indexWithoutDup = 0; indexWithoutDup < dataFeedIdsWithoutDuplicates.length; indexWithoutDup++) {
        if (dataFeedIdsWithDuplicates[indexWithDup] == dataFeedIdsWithoutDuplicates[indexWithoutDup]) {
          valuesWithDuplicates[indexWithDup] = valuesWithoutDuplicates[indexWithoutDup];
          break;
        }
      }
    }

    return valuesWithDuplicates;
  }
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE,
    WRAPPED_AAVE_V2_ORACLE,
    COMPOUND_V2_ORACLE,
    BALANCER_STABLE_LP_ORACLE,
    BALANCER_WEIGHTED_LP_ORACLE,
    CURVE_CRYPTO_ORACLE,
    THE_SAME_AS,
    REDSTONE_ORACLE,
    ERC4626_VAULT_ORACLE,
    NETWORK_DEPENDENT,
    CURVE_USD_ORACLE
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { PriceFeedType } from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

/// @title Price feed interface
interface IPriceFeed {
    function priceFeedType() external view returns (PriceFeedType);

    function version() external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function skipPriceCheck() external view returns (bool);

    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80);
}

/// @title Updatable price feed interface
interface IUpdatablePriceFeed is IPriceFeed {
    function updatable() external view returns (bool);

    function updatePrice(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";
import "./RedstoneDefaultsLib.sol";
import "./CalldataExtractor.sol";
import "../libs/BitmapLib.sol";
import "../libs/SignatureLib.sol";

/**
 * @title The base contract with the main Redstone logic
 * @author The Redstone Oracles team
 * @dev Do not use this contract directly in consumer contracts, take a
 * look at `RedstoneConsumerNumericBase` and `RedstoneConsumerBytesBase` instead
 */
abstract contract RedstoneConsumerBase is CalldataExtractor {
  using SafeMath for uint256;

  error GetDataServiceIdNotImplemented();

  /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDDEN IN CHILD CONTRACTS) ========== */

  /**
   * @dev This function must be implemented by the child consumer contract.
   * It should return dataServiceId which DataServiceWrapper will use if not provided explicitly .
   * If not overridden, value will always have to be provided explicitly in DataServiceWrapper.
   * @return dataServiceId being consumed by contract
   */
  function getDataServiceId() public view virtual returns (string memory) {
    revert GetDataServiceIdNotImplemented();
  }

  /**
   * @dev This function must be implemented by the child consumer contract.
   * It should return a unique index for a given signer address if the signer
   * is authorised, otherwise it should revert
   * @param receivedSigner The address of a signer, recovered from ECDSA signature
   * @return Unique index for a signer in the range [0..255]
   */
  function getAuthorisedSignerIndex(address receivedSigner) public view virtual returns (uint8);

  /**
   * @dev This function may be overridden by the child consumer contract.
   * It should validate the timestamp against the current time (block.timestamp)
   * It should revert with a helpful message if the timestamp is not valid
   * @param receivedTimestampMilliseconds Timestamp extracted from calldata
   */
  function validateTimestamp(uint256 receivedTimestampMilliseconds) public view virtual {
    RedstoneDefaultsLib.validateTimestamp(receivedTimestampMilliseconds);
  }

  /**
   * @dev This function should be overridden by the child consumer contract.
   * @return The minimum required value of unique authorised signers
   */
  function getUniqueSignersThreshold() public view virtual returns (uint8) {
    return 1;
  }

  /**
   * @dev This function may be overridden by the child consumer contract.
   * It should aggregate values from different signers to a single uint value.
   * By default, it calculates the median value
   * @param values An array of uint256 values from different signers
   * @return Result of the aggregation in the form of a single number
   */
  function aggregateValues(uint256[] memory values) public view virtual returns (uint256) {
    return RedstoneDefaultsLib.aggregateValues(values);
  }

  /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDDEN) ========== */

  /**
   * @dev This is an internal helpful function for secure extraction oracle values
   * from the tx calldata. Security is achieved by signatures verification, timestamp
   * validation, and aggregating values from different authorised signers into a
   * single numeric value. If any of the required conditions (e.g. too old timestamp or
   * insufficient number of authorised signers) do not match, the function will revert.
   *
   * Note! You should not call this function in a consumer contract. You can use
   * `getOracleNumericValuesFromTxMsg` or `getOracleNumericValueFromTxMsg` instead.
   *
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in dataFeedIds array
   */
  function _securelyExtractOracleValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    returns (uint256[] memory)
  {
    // Initializing helpful variables and allocating memory
    uint256[] memory uniqueSignerCountForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[] memory signersBitmapForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[][] memory valuesForDataFeeds = new uint256[][](dataFeedIds.length);
    for (uint256 i = 0; i < dataFeedIds.length; i++) {
      // The line below is commented because newly allocated arrays are filled with zeros
      // But we left it for better readability
      // signersBitmapForDataFeedIds[i] = 0; // <- setting to an empty bitmap
      valuesForDataFeeds[i] = new uint256[](getUniqueSignersThreshold());
    }

    // Extracting the number of data packages from calldata
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;

    // Saving current free memory pointer
    uint256 freeMemPtr;
    assembly {
      freeMemPtr := mload(FREE_MEMORY_PTR)
    }

    // Data packages extraction in a loop
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      // Extract data package details and update calldata offset
      uint256 dataPackageByteSize = _extractDataPackage(
        dataFeedIds,
        uniqueSignerCountForDataFeedIds,
        signersBitmapForDataFeedIds,
        valuesForDataFeeds,
        calldataNegativeOffset
      );
      calldataNegativeOffset += dataPackageByteSize;

      // Shifting memory pointer back to the "safe" value
      assembly {
        mstore(FREE_MEMORY_PTR, freeMemPtr)
      }
    }

    // Validating numbers of unique signers and calculating aggregated values for each dataFeedId
    return _getAggregatedValues(valuesForDataFeeds, uniqueSignerCountForDataFeedIds);
  }

  /**
   * @dev This is a private helpful function, which extracts data for a data package based
   * on the given negative calldata offset, verifies them, and in the case of successful
   * verification updates the corresponding data package values in memory
   *
   * @param dataFeedIds an array of unique data feed identifiers
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   * @param signersBitmapForDataFeedIds an array of signer bitmaps for data feeds
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param calldataNegativeOffset negative calldata offset for the given data package
   *
   * @return An array of the aggregated values
   */
  function _extractDataPackage(
    bytes32[] memory dataFeedIds,
    uint256[] memory uniqueSignerCountForDataFeedIds,
    uint256[] memory signersBitmapForDataFeedIds,
    uint256[][] memory valuesForDataFeeds,
    uint256 calldataNegativeOffset
  ) private view returns (uint256) {
    uint256 signerIndex;

    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    // We use scopes to resolve problem with too deep stack
    {
      uint48 extractedTimestamp;
      address signerAddress;
      bytes32 signedHash;
      bytes memory signedMessage;
      uint256 signedMessageBytesCount;

      signedMessageBytesCount = dataPointsCount.mul(eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS)
        + DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS; //DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS

      uint256 timestampCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS);

      uint256 signedMessageCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + SIG_BS + signedMessageBytesCount);

      assembly {
        // Extracting the signed message
        signedMessage := extractBytesFromCalldata(
          signedMessageCalldataOffset,
          signedMessageBytesCount
        )

        // Hashing the signed message
        signedHash := keccak256(add(signedMessage, BYTES_ARR_LEN_VAR_BS), signedMessageBytesCount)

        // Extracting timestamp
        extractedTimestamp := calldataload(timestampCalldataOffset)

        function initByteArray(bytesCount) -> ptr {
          ptr := mload(FREE_MEMORY_PTR)
          mstore(ptr, bytesCount)
          ptr := add(ptr, BYTES_ARR_LEN_VAR_BS)
          mstore(FREE_MEMORY_PTR, add(ptr, bytesCount))
        }

        function extractBytesFromCalldata(offset, bytesCount) -> extractedBytes {
          let extractedBytesStartPtr := initByteArray(bytesCount)
          calldatacopy(
            extractedBytesStartPtr,
            offset,
            bytesCount
          )
          extractedBytes := sub(extractedBytesStartPtr, BYTES_ARR_LEN_VAR_BS)
        }
      }

      // Validating timestamp
      validateTimestamp(extractedTimestamp);

      // Verifying the off-chain signature against on-chain hashed data
      signerAddress = SignatureLib.recoverSignerAddress(
        signedHash,
        calldataNegativeOffset + SIG_BS
      );
      signerIndex = getAuthorisedSignerIndex(signerAddress);
    }

    // Updating helpful arrays
    {
      bytes32 dataPointDataFeedId;
      uint256 dataPointValue;
      for (uint256 dataPointIndex = 0; dataPointIndex < dataPointsCount; dataPointIndex++) {
        // Extracting data feed id and value for the current data point
        (dataPointDataFeedId, dataPointValue) = _extractDataPointValueAndDataFeedId(
          calldataNegativeOffset,
          eachDataPointValueByteSize,
          dataPointIndex
        );

        for (
          uint256 dataFeedIdIndex = 0;
          dataFeedIdIndex < dataFeedIds.length;
          dataFeedIdIndex++
        ) {
          if (dataPointDataFeedId == dataFeedIds[dataFeedIdIndex]) {
            uint256 bitmapSignersForDataFeedId = signersBitmapForDataFeedIds[dataFeedIdIndex];

            if (
              !BitmapLib.getBitFromBitmap(bitmapSignersForDataFeedId, signerIndex) && /* current signer was not counted for current dataFeedId */
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex] < getUniqueSignersThreshold()
            ) {
              // Increase unique signer counter
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex]++;

              // Add new value
              valuesForDataFeeds[dataFeedIdIndex][
                uniqueSignerCountForDataFeedIds[dataFeedIdIndex] - 1
              ] = dataPointValue;

              // Update signers bitmap
              signersBitmapForDataFeedIds[dataFeedIdIndex] = BitmapLib.setBitInBitmap(
                bitmapSignersForDataFeedId,
                signerIndex
              );
            }

            // Breaking, as there couldn't be several indexes for the same feed ID
            break;
          }
        }
      }
    }

    // Return total data package byte size
    return
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS +
      (eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS) *
      dataPointsCount;
  }

  /**
   * @dev This is a private helpful function, which aggregates values from different
   * authorised signers for the given arrays of values for each data feed
   *
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   *
   * @return An array of the aggregated values
   */
  function _getAggregatedValues(
    uint256[][] memory valuesForDataFeeds,
    uint256[] memory uniqueSignerCountForDataFeedIds
  ) private view returns (uint256[] memory) {
    uint256[] memory aggregatedValues = new uint256[](valuesForDataFeeds.length);
    uint256 uniqueSignersThreshold = getUniqueSignersThreshold();

    for (uint256 dataFeedIndex = 0; dataFeedIndex < valuesForDataFeeds.length; dataFeedIndex++) {
      if (uniqueSignerCountForDataFeedIds[dataFeedIndex] < uniqueSignersThreshold) {
        revert InsufficientNumberOfUniqueSigners(
          uniqueSignerCountForDataFeedIds[dataFeedIndex],
          uniqueSignersThreshold);
      }
      uint256 aggregatedValueForDataFeedId = aggregateValues(valuesForDataFeeds[dataFeedIndex]);
      aggregatedValues[dataFeedIndex] = aggregatedValueForDataFeedId;
    }

    return aggregatedValues;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

/**
 * @title The base contract with helpful constants
 * @author The Redstone Oracles team
 * @dev It mainly contains redstone-related values, which improve readability
 * of other contracts (e.g. CalldataExtractor and RedstoneConsumerBase)
 */
contract RedstoneConstants {
  // === Abbreviations ===
  // BS - Bytes size
  // PTR - Pointer (memory location)
  // SIG - Signature

  // Solidity and YUL constants
  uint256 internal constant STANDARD_SLOT_BS = 32;
  uint256 internal constant FREE_MEMORY_PTR = 0x40;
  uint256 internal constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 internal constant FUNCTION_SIGNATURE_BS = 4;
  uint256 internal constant REVERT_MSG_OFFSET = 68; // Revert message structure described here: https://ethereum.stackexchange.com/a/66173/106364
  uint256 internal constant STRING_ERR_MESSAGE_MASK = 0x08c379a000000000000000000000000000000000000000000000000000000000;

  // RedStone protocol consts
  uint256 internal constant SIG_BS = 65;
  uint256 internal constant TIMESTAMP_BS = 6;
  uint256 internal constant DATA_PACKAGES_COUNT_BS = 2;
  uint256 internal constant DATA_POINTS_COUNT_BS = 3;
  uint256 internal constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
  uint256 internal constant DATA_POINT_SYMBOL_BS = 32;
  uint256 internal constant DEFAULT_DATA_POINT_VALUE_BS = 32;
  uint256 internal constant UNSIGNED_METADATA_BYTE_SIZE_BS = 3;
  uint256 internal constant REDSTONE_MARKER_BS = 9; // byte size of 0x000002ed57011e0000
  uint256 internal constant REDSTONE_MARKER_MASK = 0x0000000000000000000000000000000000000000000000000002ed57011e0000;

  // Derived values (based on consts)
  uint256 internal constant TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS = 104; // SIG_BS + DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + STANDARD_SLOT_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_BS = 78; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS + SIG_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS = 13; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
  uint256 internal constant REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS = 41; // REDSTONE_MARKER_BS + STANDARD_SLOT_BS

  // Error messages
  error CalldataOverOrUnderFlow();
  error IncorrectUnsignedMetadataSize();
  error InsufficientNumberOfUniqueSigners(uint256 receivedSignersCount, uint256 requiredSignersCount);
  error EachSignerMustProvideTheSameValue();
  error EmptyCalldataPointersArr();
  error InvalidCalldataPointer();
  error CalldataMustHaveValidPayload();
  error SignerNotAuthorised(address receivedSigner);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "../libs/NumericArrayLib.sol";

/**
 * @title Default implementations of virtual redstone consumer base functions
 * @author The Redstone Oracles team
 */
library RedstoneDefaultsLib {
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS = 3 minutes;
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

  error TimestampFromTooLongFuture(uint256 receivedTimestampSeconds, uint256 blockTimestamp);
  error TimestampIsTooOld(uint256 receivedTimestampSeconds, uint256 blockTimestamp);

  function validateTimestamp(uint256 receivedTimestampMilliseconds) internal view {
    // Getting data timestamp from future seems quite unlikely
    // But we've already spent too much time with different cases
    // Where block.timestamp was less than dataPackage.timestamp.
    // Some blockchains may case this problem as well.
    // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
    // and allow data "from future" but with a small delay
    uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;

    if (block.timestamp < receivedTimestampSeconds) {
      if ((receivedTimestampSeconds - block.timestamp) > DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
        revert TimestampFromTooLongFuture(receivedTimestampSeconds, block.timestamp);
      }
    } else if ((block.timestamp - receivedTimestampSeconds) > DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
      revert TimestampIsTooOld(receivedTimestampSeconds, block.timestamp);
    }
  }

  function aggregateValues(uint256[] memory values) internal pure returns (uint256) {
    return NumericArrayLib.pickMedian(values);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";

/**
 * @title The base contract with the main logic of data extraction from calldata
 * @author The Redstone Oracles team
 * @dev This contract was created to reuse the same logic in the RedstoneConsumerBase
 * and the ProxyConnector contracts
 */
contract CalldataExtractor is RedstoneConstants {
  using SafeMath for uint256;

  error DataPackageTimestampMustNotBeZero();
  error DataPackageTimestampsMustBeEqual();
  error RedstonePayloadMustHaveAtLeastOneDataPackage();

  function extractTimestampsAndAssertAllAreEqual() public pure returns (uint256 extractedTimestamp) {
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);

    if (dataPackagesCount == 0) {
      revert RedstonePayloadMustHaveAtLeastOneDataPackage();
    }

    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      uint256 dataPackageByteSize = _getDataPackageByteSize(calldataNegativeOffset);

      // Extracting timestamp for the current data package
      uint48 dataPackageTimestamp; // uint48, because timestamp uses 6 bytes
      uint256 timestampNegativeOffset = (calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS);
      uint256 timestampOffset = msg.data.length - timestampNegativeOffset;
      assembly {
        dataPackageTimestamp := calldataload(timestampOffset)
      }

      if (dataPackageTimestamp == 0) {
        revert DataPackageTimestampMustNotBeZero();
      }

      if (extractedTimestamp == 0) {
        extractedTimestamp = dataPackageTimestamp;
      } else if (dataPackageTimestamp != extractedTimestamp) {
        revert DataPackageTimestampsMustBeEqual();
      }

      calldataNegativeOffset += dataPackageByteSize;
    }
  }

  function _getDataPackageByteSize(uint256 calldataNegativeOffset) internal pure returns (uint256) {
    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    return
      dataPointsCount *
      (DATA_POINT_SYMBOL_BS + eachDataPointValueByteSize) +
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
  }

  function _extractByteSizeOfUnsignedMetadata() internal pure returns (uint256) {
    // Checking if the calldata ends with the RedStone marker
    bool hasValidRedstoneMarker;
    assembly {
      let calldataLast32Bytes := calldataload(sub(calldatasize(), STANDARD_SLOT_BS))
      hasValidRedstoneMarker := eq(
        REDSTONE_MARKER_MASK,
        and(calldataLast32Bytes, REDSTONE_MARKER_MASK)
      )
    }
    if (!hasValidRedstoneMarker) {
      revert CalldataMustHaveValidPayload();
    }

    // Using uint24, because unsigned metadata byte size number has 3 bytes
    uint24 unsignedMetadataByteSize;
    if (REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      unsignedMetadataByteSize := calldataload(
        sub(calldatasize(), REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS)
      )
    }
    uint256 calldataNegativeOffset = unsignedMetadataByteSize
      + UNSIGNED_METADATA_BYTE_SIZE_BS
      + REDSTONE_MARKER_BS;
    if (calldataNegativeOffset + DATA_PACKAGES_COUNT_BS > msg.data.length) {
      revert IncorrectUnsignedMetadataSize();
    }
    return calldataNegativeOffset;
  }

  // We return uint16, because unsigned metadata byte size number has 2 bytes
  function _extractDataPackagesCountFromCalldata(uint256 calldataNegativeOffset)
    internal
    pure
    returns (uint16 dataPackagesCount)
  {
    uint256 calldataNegativeOffsetWithStandardSlot = calldataNegativeOffset + STANDARD_SLOT_BS;
    if (calldataNegativeOffsetWithStandardSlot > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      dataPackagesCount := calldataload(
        sub(calldatasize(), calldataNegativeOffsetWithStandardSlot)
      )
    }
    return dataPackagesCount;
  }

  function _extractDataPointValueAndDataFeedId(
    uint256 calldataNegativeOffsetForDataPackage,
    uint256 defaultDataPointValueByteSize,
    uint256 dataPointIndex
  ) internal pure virtual returns (bytes32 dataPointDataFeedId, uint256 dataPointValue) {
    uint256 negativeOffsetToDataPoints = calldataNegativeOffsetForDataPackage + DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
    uint256 dataPointNegativeOffset = negativeOffsetToDataPoints.add(
      (1 + dataPointIndex).mul((defaultDataPointValueByteSize + DATA_POINT_SYMBOL_BS))
    );
    uint256 dataPointCalldataOffset = msg.data.length.sub(dataPointNegativeOffset);
    assembly {
      dataPointDataFeedId := calldataload(dataPointCalldataOffset)
      dataPointValue := calldataload(add(dataPointCalldataOffset, DATA_POINT_SYMBOL_BS))
    }
  }

  function _extractDataPointsDetailsForDataPackage(uint256 calldataNegativeOffsetForDataPackage)
    internal
    pure
    returns (uint256 dataPointsCount, uint256 eachDataPointValueByteSize)
  {
    // Using uint24, because data points count byte size number has 3 bytes
    uint24 dataPointsCount_;

    // Using uint32, because data point value byte size has 4 bytes
    uint32 eachDataPointValueByteSize_;

    // Extract data points count
    uint256 negativeCalldataOffset = calldataNegativeOffsetForDataPackage + SIG_BS;
    uint256 calldataOffset = msg.data.length.sub(negativeCalldataOffset + STANDARD_SLOT_BS);
    assembly {
      dataPointsCount_ := calldataload(calldataOffset)
    }

    // Extract each data point value size
    calldataOffset = calldataOffset.sub(DATA_POINTS_COUNT_BS);
    assembly {
      eachDataPointValueByteSize_ := calldataload(calldataOffset)
    }

    // Prepare returned values
    dataPointsCount = dataPointsCount_;
    eachDataPointValueByteSize = eachDataPointValueByteSize_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library BitmapLib {
  function setBitInBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (uint256) {
    return bitmap | (1 << bitIndex);
  }

  function getBitFromBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (bool) {
    uint256 bitAtIndex = bitmap & (1 << bitIndex);
    return bitAtIndex > 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SignatureLib {
  uint256 constant ECDSA_SIG_R_BS = 32;
  uint256 constant ECDSA_SIG_S_BS = 32;

  function recoverSignerAddress(bytes32 signedHash, uint256 signatureCalldataNegativeOffset)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      let signatureCalldataStartPos := sub(calldatasize(), signatureCalldataNegativeOffset)
      r := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_R_BS)
      s := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_S_BS)
      v := byte(0, calldataload(signatureCalldataStartPos)) // last byte of the signature memory array
    }
    return ecrecover(signedHash, v, r, s);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NumericArrayLib {
  // This function sort array in memory using bubble sort algorithm,
  // which performs even better than quick sort for small arrays

  uint256 constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 constant UINT256_VALUE_BS = 32;

  error CanNotPickMedianOfEmptyArray();

  // This function modifies the array
  function pickMedian(uint256[] memory arr) internal pure returns (uint256) {
    if (arr.length == 0) {
      revert CanNotPickMedianOfEmptyArray();
    }
    sort(arr);
    uint256 middleIndex = arr.length / 2;
    if (arr.length % 2 == 0) {
      uint256 sum = SafeMath.add(arr[middleIndex - 1], arr[middleIndex]);
      return sum / 2;
    } else {
      return arr[middleIndex];
    }
  }

  function sort(uint256[] memory arr) internal pure {
    assembly {
      let arrLength := mload(arr)
      let valuesPtr := add(arr, BYTES_ARR_LEN_VAR_BS)
      let endPtr := add(valuesPtr, mul(arrLength, UINT256_VALUE_BS))
      for {
        let arrIPtr := valuesPtr
      } lt(arrIPtr, endPtr) {
        arrIPtr := add(arrIPtr, UINT256_VALUE_BS) // arrIPtr += 32
      } {
        for {
          let arrJPtr := valuesPtr
        } lt(arrJPtr, arrIPtr) {
          arrJPtr := add(arrJPtr, UINT256_VALUE_BS) // arrJPtr += 32
        } {
          let arrI := mload(arrIPtr)
          let arrJ := mload(arrJPtr)
          if lt(arrI, arrJ) {
            mstore(arrIPtr, arrJ)
            mstore(arrJPtr, arrI)
          }
        }
      }
    }
  }
}