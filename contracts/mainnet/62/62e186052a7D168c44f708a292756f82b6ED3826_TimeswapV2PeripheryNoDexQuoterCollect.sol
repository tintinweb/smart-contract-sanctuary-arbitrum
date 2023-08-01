// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
library BytesLib {
  /// @dev Slices the given byte stream
  /// @param _bytes the bytes stream
  /// @param _start the start position
  /// @param _length the length required

  function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, "slice_overflow");
    require(_bytes.length >= _start + _length, "slice_outOfBounds");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {BytesLib} from "./BytesLib.sol";

/// @title Library for catchError
/// @author Timeswap Labs
library CatchError {
  /// @dev Get the data passed from a given custom error.
  /// @dev It checks that the first four bytes of the reason has the same selector.
  /// @notice Will simply revert with the original error if the first four bytes is not the given selector.
  /// @param reason The data being inquired upon.
  /// @param selector The given conditional selector.
  function catchError(bytes memory reason, bytes4 selector) internal pure returns (bytes memory) {
    uint256 length = reason.length;

    if ((length - 4) % 32 == 0 && bytes4(reason) == selector) return BytesLib.slice(reason, 4, length - 4);

    assembly {
      revert(add(32, reason), mload(reason))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The three type of native token positions.
/// @dev Long0 is denominated as the underlying Token0.
/// @dev Long1 is denominated as the underlying Token1.
/// @dev When strike greater than uint128 then Short is denominated as Token0 (the base token denomination).
/// @dev When strike is uint128 then Short is denominated as Token1 (the base token denomination).
enum TimeswapV2OptionPosition {
  Long0,
  Long1,
  Short
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev Helper functions for the TimeswapOptionPosition enum.
library PositionLibrary {
  /// @dev Reverts when the given type of position is invalid.
  error InvalidPosition();

  /// @dev Checks that the position input is correct.
  /// @param position The position input.
  function check(TimeswapV2OptionPosition position) internal pure {
    if (uint256(position) >= 3) revert InvalidPosition();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different input for the mint transaction.
enum TimeswapV2OptionMint {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the burn transaction.
enum TimeswapV2OptionBurn {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the swap transaction.
enum TimeswapV2OptionSwap {
  GivenToken0AndLong0,
  GivenToken1AndLong1
}

/// @dev The different input for the collect transaction.
enum TimeswapV2OptionCollect {
  GivenShort,
  GivenToken0,
  GivenToken1
}

/// @title library for transaction checks
/// @author Timeswap Labs
/// @dev Helper functions for the all enums in this module.
library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev checks that the given input is correct.
  /// @param transaction the mint transaction input.
  function check(TimeswapV2OptionMint transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the burn transaction input.
  function check(TimeswapV2OptionBurn transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the swap transaction input.
  function check(TimeswapV2OptionSwap transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the collect transaction input.
  function check(TimeswapV2OptionCollect transaction) internal pure {
    if (uint256(transaction) >= 3) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionCollectCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#collect
/// @notice Any contract that calls ITimeswapV2Option#collect can optionally implement this interface.
interface ITimeswapV2OptionCollectCallback {
  /// @notice Called to `msg.sender` after initiating a collect from ITimeswapV2Option#collect.
  /// @dev In the implementation, you must have enough short positions for the collect transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The token0 and token1 will already transferred to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionCollectCallback(
    TimeswapV2OptionCollectCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "../enums/Position.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam} from "../structs/Param.sol";
import {StrikeAndMaturity} from "../structs/StrikeAndMaturity.sol";

/// @title An interface for a contract that deploys Timeswap V2 Option pair contracts
/// @notice A Timeswap V2 Option pair facilitates option mechanics between any two assets that strictly conform
/// to the ERC20 specification.
interface ITimeswapV2Option {
  /* ===== EVENT ===== */

  /// @dev Emits when a position is transferred.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param from The address of the caller of the transferPosition function.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  event TransferPosition(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  );

  /// @dev Emits when a mint transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param long0To The address of the recipient of long token0 position.
  /// @param long1To The address of the recipient of long token1 position.
  /// @param shortTo The address of the recipient of short position.
  /// @param token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @param shortAmount The amount of short minted.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a burn transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @param token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @param shortAmount The amount of short burnt.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a swap transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param tokenTo The address of the recipient of token0 or token1.
  /// @param longTo The address of the recipient of long token0 or long token1.
  /// @param isLong0toLong1 The direction of the swap. More information in the Transaction module.
  /// @param token0AndLong0Amount If the direction is from long0 to long1, the amount of token0 withdrawn and long0 burnt.
  /// If the direction is from long1 to long0, the amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount If the direction is from long0 to long1, the amount of token1 deposited and long1 minted.
  /// If the direction is from long1 to long0, the amount of token1 withdrawn and long1 burnt.
  event Swap(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address tokenTo,
    address longTo,
    bool isLong0toLong1,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount
  );

  /// @dev Emits when a collect transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param long0AndToken0Amount The amount of token0 withdrawn.
  /// @param long1AndToken1Amount The amount of token1 withdrawn.
  /// @param shortAmount The amount of short burnt.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1AndToken1Amount,
    uint256 shortAmount
  );

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the first ERC20 token address of the pair.
  function token0() external view returns (address);

  /// @dev Returns the second ERC20 token address of the pair.
  function token1() external view returns (address);

  /// @dev Get the strike and maturity of the option in the option enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Number of options being interacted.
  function numberOfOptions() external view returns (uint256);

  /// @dev Returns the total position of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The total position.
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /// @dev Returns the position of an owner of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param owner The address of the owner of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The user position.
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /* ===== UPDATE ===== */

  /// @dev Transfer position to another address.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external;

  /// @dev Mint position.
  /// Mint long token0 position when token0 is deposited.
  /// Mint long token1 position when token1 is deposited.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the mint function.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  /// @return data The additional data return.
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Burn short position.
  /// Withdraw token0, when long token0 is burnt.
  /// Withdraw token1, when long token1 is burnt.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the burn function.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev If the direction is from long token0 to long token1, burn long token0 and mint equivalent long token1,
  /// also deposit token1 and withdraw token0.
  /// If the direction is from long token1 to long token0, burn long token1 and mint equivalent long token0,
  /// also deposit token0 and withdraw token1.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the swap function.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  /// @return data The additional data return.
  function swap(
    TimeswapV2OptionSwapParam calldata param
  ) external returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data);

  /// @dev Burn short position, withdraw token0 and token1.
  /// @dev Can only be called after the maturity of the pool.
  /// @param param The parameters for the collect function.
  /// @return token0Amount The amount of token0 withdrawn.
  /// @return token1Amount The amount of token1 withdrawn.
  /// @return shortAmount The amount of short burnt.
  function collect(
    TimeswapV2OptionCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title The interface for the contract that deploys Timeswap V2 Option pair contracts
/// @notice The Timeswap V2 Option Factory facilitates creation of Timeswap V2 Options pair.
interface ITimeswapV2OptionFactory {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Option contract is created.
  /// @param caller The address of the caller of create function.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  event Create(address indexed caller, address indexed token0, address indexed token1, address optionPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of a Timeswap V2 Option.
  /// @dev Returns a zero address if the Timeswap V2 Option does not exist.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @return optionPair The address of the Timeswap V2 Option contract or a zero address.
  function get(address token0, address token1) external view returns (address optionPair);

  /// @dev Get the address of the option pair in the option pair enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (address optionPair);

  /// @dev The number of option pairs deployed.
  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Option based on pair parameters.
  /// @dev Cannot create a duplicate Timeswap V2 Option with the same pair parameters.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  function create(address token0, address token1) external returns (address optionPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {OptionPairLibrary} from "./OptionPair.sol";

import {ITimeswapV2OptionFactory} from "../interfaces/ITimeswapV2OptionFactory.sol";

/// @title library for option utils
/// @author Timeswap Labs
library OptionFactoryLibrary {
  using OptionPairLibrary for address;

  /// @dev reverts if the factory is the zero address.
  error ZeroFactoryAddress();

  /// @dev check if the factory address is not zero.
  /// @param optionFactory The factory address.
  function checkNotZeroFactory(address optionFactory) internal pure {
    if (optionFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Helper function to get the option pair address.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function get(address optionFactory, address token0, address token1) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
  }

  /// @dev Helper function to get the option pair address.
  /// @notice reverts when the option pair does not exist.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function getWithCheck(
    address optionFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = get(optionFactory, token0, token1);
    if (optionPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for optionPair utils
/// @author Timeswap Labs
library OptionPairLibrary {
  /// @dev Reverts when option address is zero.
  error ZeroOptionAddress();

  /// @dev Reverts when the pair has incorrect format.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  error InvalidOptionPair(address token0, address token1);

  /// @dev Reverts when the Timeswap V2 Option already exist.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  error OptionPairAlreadyExisted(address token0, address token1, address optionPair);

  /// @dev Checks if option address is not zero.
  /// @param optionPair The option pair address being inquired.
  function checkNotZeroAddress(address optionPair) internal pure {
    if (optionPair == address(0)) revert ZeroOptionAddress();
  }

  /// @dev Check if the pair tokens is in correct format.
  /// @notice Reverts if token0 is greater than or equal token1.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function checkCorrectFormat(address token0, address token1) internal pure {
    if (token0 >= token1) revert InvalidOptionPair(token0, token1);
  }

  /// @dev Check if the pair already existed.
  /// @notice Reverts if the pair is not a zero address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  function checkDoesNotExist(address token0, address token1, address optionPair) internal pure {
    if (optionPair != address(0)) revert OptionPairAlreadyExisted(token0, token1, optionPair);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Parameter for the mint callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be deposited and the long0 amount minted.
/// @param token1AndLong1Amount The token1 amount to be deposited and the long1 amount minted.
/// @param shortAmount The short amount minted.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the burn callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be withdrawn and the long0 amount burnt.
/// @param token1AndLong1Amount The token1 amount to be withdrawn and the long1 amount burnt.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the swap callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param isLong0ToLong1 True when swapping long0 for long1. False when swapping long1 for long0.
/// @param token0AndLong0Amount If isLong0ToLong1 is true, the amount of long0 burnt and token0 to be withdrawn.
/// If isLong0ToLong1 is false, the amount of long0 minted and token0 to be deposited.
/// @param token1AndLong1Amount If isLong0ToLong1 is true, the amount of long1 withdrawn and token0 to be deposited.
/// If isLong0ToLong1 is false, the amount of long1 burnt and token1 to be withdrawn.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionSwapCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

/// @dev Parameter for the collect callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0Amount The token0 amount to be withdrawn.
/// @param token1Amount The token1 amount to be withdrawn.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionCollectCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 shortAmount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter to call the mint function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 deposited, and amount of long0 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 deposited, and amount of long1 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the mint callback.
struct TimeswapV2OptionMintParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2OptionMint transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the burn function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 withdrawn, and amount of long0 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 withdrawn, and amount of long1 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the burn callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionBurnParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionBurn transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the swap function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param tokenTo The recipient of token0 when isLong0ToLong1 or token1 when isLong1ToLong0.
/// @param longTo The recipient of long1 positions when isLong0ToLong1 or long0 when isLong1ToLong0.
/// @param isLong0ToLong1 Transform long0 positions to long1 positions when true. Transform long1 positions to long0 positions when false.
/// @param transaction The type of swap transaction, more information in Transaction module.
/// @param amount If isLong0ToLong1 and transaction is GivenToken0AndLong0, this is the amount of token0 withdrawn, and the amount of long0 position burnt.
/// If isLong1ToLong0 and transaction is GivenToken0AndLong0, this is the amount of token0 to be deposited, and the amount of long0 position minted.
/// If isLong0ToLong1 and transaction is GivenToken1AndLong1, this is the amount of token1 to be deposited, and the amount of long1 position minted.
/// If isLong1ToLong0 and transaction is GivenToken1AndLong1, this is the amount of token1 withdrawn, and the amount of long1 position burnt.
/// @param data The data to be sent to the function, which will go to the swap callback.
struct TimeswapV2OptionSwapParam {
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  TimeswapV2OptionSwap transaction;
  uint256 amount;
  bytes data;
}

/// @dev The parameter to call the collect function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of collect transaction, more information in Transaction module.
/// @param amount If transaction is GivenShort, the amount of short position burnt.
/// If transaction is GivenToken0, the amount of token0 withdrawn.
/// If transaction is GivenToken1, the amount of token1 withdrawn.
/// @param data The data to be sent to the function, which will go to the collect callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionCollectParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionCollect transaction;
  uint256 amount;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.shortTo == address(0)) Error.zeroAddress();
    if (param.long0To == address(0)) Error.zeroAddress();
    if (param.long1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for swap transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.tokenTo == address(0)) Error.zeroAddress();
    if (param.longTo == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collect transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity >= blockTimestamp) Error.stillActive(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
  uint256 strike;
  uint256 maturity;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.8;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert MulticallFailed("Invalid Result");
        assembly {
          result := add(result, 0x04)
        }
        revert MulticallFailed(abi.decode(result, (string)));
      }

      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

abstract contract OnlyOperatorReceiver is IERC1155Receiver {
  function onERC1155Received(
    address operator,
    address,
    uint256,
    uint256,
    bytes memory
  ) external view override returns (bytes4) {
    if (operator != address(this)) return bytes4("");
    else return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) external pure override returns (bytes4) {
    return bytes4("");
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

  error MulticallFailed(string revertString);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryQuoterCollect} from "@timeswap-labs/v2-periphery/contracts/interfaces/lens/ITimeswapV2PeripheryQuoterCollect.sol";

import {TimeswapV2PeripheryNoDexQuoterCollectParam} from "../../structs/lens/QuoterParam.sol";

import {IMulticall} from "../IMulticall.sol";

/// @title An interface for TS-V2 Periphery NoDex Collect.
interface ITimeswapV2PeripheryNoDexQuoterCollect is ITimeswapV2PeripheryQuoterCollect, IMulticall {
  error MinTokenReached(uint256 tokenAmount, uint256 minTokenAmount);

  /// @dev The collect function.
  /// @param param collect param.
  /// @return token0Amount
  /// @return token1Amount
  function collect(
    TimeswapV2PeripheryNoDexQuoterCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PeripheryQuoterCollect} from "@timeswap-labs/v2-periphery/contracts/lens/TimeswapV2PeripheryQuoterCollect.sol";

import {TimeswapV2PeripheryCollectParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";

import {ITimeswapV2PeripheryNoDexQuoterCollect} from "../interfaces/lens/ITimeswapV2PeripheryNoDexQuoterCollect.sol";

import {TimeswapV2PeripheryNoDexQuoterCollectParam} from "../structs/lens/QuoterParam.sol";

import {OnlyOperatorReceiver} from "../base/OnlyOperatorReceiver.sol";
import {Multicall} from "../base/Multicall.sol";

contract TimeswapV2PeripheryNoDexQuoterCollect is
  TimeswapV2PeripheryQuoterCollect,
  ITimeswapV2PeripheryNoDexQuoterCollect,
  OnlyOperatorReceiver,
  Multicall
{
  constructor(
    address chosenOptionFactory,
    address chosenTokens,
    address chosenLiquidityTokens
  ) TimeswapV2PeripheryQuoterCollect(chosenOptionFactory, chosenTokens, chosenLiquidityTokens) {}

  function collect(
    TimeswapV2PeripheryNoDexQuoterCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount) {
    (token0Amount, token1Amount) = collect(
      TimeswapV2PeripheryCollectParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.isToken0 ? param.to : address(this),
        token1To: param.isToken0 ? address(this) : param.to,
        excessShortAmount: param.excessShortAmount
      })
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct TimeswapV2PeripheryNoDexQuoterAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  bool isToken0;
  uint256 tokenAmount;
  bytes erc1155Data;
}

struct TimeswapV2PeripheryNoDexQuoterRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  bool isToken0;
  uint160 liquidityAmount;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
}

struct TimeswapV2PeripheryNoDexQuoterCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 excessShortAmount;
}

struct TimeswapV2PeripheryNoDexQuoterLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 tokenAmount;
}

struct TimeswapV2PeripheryNoDexQuoterCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
}

struct TimeswapV2PeripheryNoDexQuoterBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 tokenAmount;
}

struct TimeswapV2PeripheryNoDexQuoterCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 positionAmount;
}

struct TimeswapV2PeripheryNoDexQuoterWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 positionAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {ITimeswapV2TokenBurnCallback} from "@timeswap-labs/v2-token/contracts/interfaces/callbacks/ITimeswapV2TokenBurnCallback.sol";
import {ITimeswapV2OptionCollectCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionCollectCallback.sol";

/// @title An interface for TS-V2 Periphery Collect
interface ITimeswapV2PeripheryQuoterCollect is
  IERC1155Receiver,
  ITimeswapV2TokenBurnCallback,
  ITimeswapV2OptionCollectCallback
{
  error PassTokenBurnCallbackInfo(uint256 shortAmount);
  error PassOptionCollectCallbackInfo(uint256 token0Amount, uint256 token1Amount);

  /// @dev Returns the option factory address.
  function optionFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);

  /// @dev Return the liquidity tokens address
  function liquidityTokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import {CatchError} from "@timeswap-labs/v2-library/contracts/CatchError.sol";

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {TimeswapV2OptionCollect} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";

import {TimeswapV2OptionCollectParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {ITimeswapV2LiquidityToken} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2LiquidityToken.sol";
import {TimeswapV2TokenBurnParam, TimeswapV2LiquidityTokenCollectParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";
import {TimeswapV2TokenBurnCallbackParam} from "@timeswap-labs/v2-token/contracts/structs/CallbackParam.sol";
import {TimeswapV2OptionCollectCallbackParam} from "@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol";
import {TimeswapV2LiquidityTokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {TimeswapV2PeripheryCollectParam} from "../structs/Param.sol";

import {ITimeswapV2PeripheryQuoterCollect} from "../interfaces/lens/ITimeswapV2PeripheryQuoterCollect.sol";

/// @title Abstract contract which specifies functions that are required for collect which are to be inherited for a specific DEX/Aggregator implementation
abstract contract TimeswapV2PeripheryQuoterCollect is ITimeswapV2PeripheryQuoterCollect, ERC1155Receiver {
  using CatchError for bytes;

  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryQuoterCollect
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryQuoterCollect
  address public immutable override tokens;
  /// @inheritdoc ITimeswapV2PeripheryQuoterCollect
  address public immutable override liquidityTokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenTokens, address chosenLiquidityTokens) {
    optionFactory = chosenOptionFactory;
    tokens = chosenTokens;
    liquidityTokens = chosenLiquidityTokens;
  }

  /// @notice the abstract implementation for collect function
  /// @param param for collect as mentioned in the TimeswapV2PeripheryCollectParam struct
  /// @return token0Amount is the token0Amount recieved
  /// @return token1Amount is the token1Amount recieved
  function collect(
    TimeswapV2PeripheryCollectParam memory param
  ) internal returns (uint256 token0Amount, uint256 token1Amount) {
    (, , uint256 shortAmount, uint256 shortReturnedAmount) = ITimeswapV2LiquidityToken(liquidityTokens)
      .feesEarnedAndShortReturnedOf(
        msg.sender,
        TimeswapV2LiquidityTokenPosition({
          token0: param.token0,
          token1: param.token1,
          strike: param.strike,
          maturity: param.maturity
        })
      );

    shortAmount += shortReturnedAmount;

    bytes memory data;
    if (param.excessShortAmount != 0) {
      data = abi.encode(shortAmount);

      try
        ITimeswapV2Token(tokens).burn(
          TimeswapV2TokenBurnParam({
            token0: param.token0,
            token1: param.token1,
            strike: param.strike,
            maturity: param.maturity,
            long0To: address(this),
            long1To: address(this),
            shortTo: address(this),
            long0Amount: 0,
            long1Amount: 0,
            shortAmount: param.excessShortAmount,
            data: data
          })
        )
      {} catch (bytes memory reason) {
        data = reason.catchError(PassTokenBurnCallbackInfo.selector);
        (shortAmount) = abi.decode(data, (uint256));
      }
    }

    address optionPair = OptionFactoryLibrary.getWithCheck(optionFactory, param.token0, param.token1);

    shortAmount = ITimeswapV2Option(optionPair).positionOf(
      param.strike,
      param.maturity,
      address(this),
      TimeswapV2OptionPosition.Short
    );

    try
      ITimeswapV2Option(optionPair).collect(
        TimeswapV2OptionCollectParam({
          strike: param.strike,
          maturity: param.maturity,
          token0To: param.token0To,
          token1To: param.token1To,
          transaction: TimeswapV2OptionCollect.GivenShort,
          amount: shortAmount,
          data: bytes("0")
        })
      )
    {} catch (bytes memory reason) {
      data = reason.catchError(PassOptionCollectCallbackInfo.selector);
      (token0Amount, token1Amount) = abi.decode(data, (uint256, uint256));
    }
  }

  /// @notice the abstract implementation for token burn function
  /// @param param params for  timeswapV2TokenBurnCallback
  /// @return data data passed as bytes in the param
  function timeswapV2TokenBurnCallback(
    TimeswapV2TokenBurnCallbackParam calldata param
  ) external pure returns (bytes memory data) {
    uint256 shortAmount = abi.decode(param.data, (uint256));

    shortAmount += param.shortAmount;

    data = bytes("");

    revert PassTokenBurnCallbackInfo(shortAmount);
  }

  /// @notice the abstract implementation for option collect callback function
  /// @param param params for  timeswapV2OptionCollectCallback
  /// @return data data passed as bytes in the param
  function timeswapV2OptionCollectCallback(
    TimeswapV2OptionCollectCallbackParam calldata param
  ) external pure returns (bytes memory data) {
    data = bytes("");

    revert PassOptionCollectCallbackInfo(param.token0Amount, param.token1Amount);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameter for calling the collect protocol fees function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param excessLong0To The receiver of any excess long0 ERC1155 tokens.
/// @param excessLong1To The receiver of any excess long1 ERC1155 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param long0Requested The maximum amount of long0 fees.
/// @param long1Requested The maximum amount of long1 fees.
/// @param shortRequested The maximum amount of short fees.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCollectProtocolFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
  bytes data;
}

/// @dev The parameter for calling the add liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param liquidityTo The receiver of the liquidity position ERC1155 tokens.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
/// @param erc1155Data The bytes data passed to the receiver of liquidity position ERC1155 tokens.
struct TimeswapV2PeripheryAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
  bytes erc1155Data;
}

/// @dev The parameter for calling the remove liquidity function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param liquidityAmount The amount of liquidity ERC1155 tokens to burn.
/// @param excessLong0Amount The amount of long0 ERC1155 tokens to include in matching long and short positions.
/// @param excessLong1Amount The amount of long1 ERC1155 tokens to include in matching long and short positions.
/// @param excessShortAmount The amount of short ERC1155 tokens to include in matching long and short positions.
struct TimeswapV2PeripheryRemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint160 liquidityAmount;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  bytes data;
}

/// @dev A struct describing how much fees and short returned are withdrawn from the pool.
/// @param long0Fees The number of long0 fees withdrwan from the pool.
/// @param long1Fees The number of long1 fees withdrwan from the pool.
/// @param shortFees The number of short fees withdrwan from the pool.
/// @param shortReturned The number of short returned withdrwan from the pool.
struct FeesAndReturnedDelta {
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  uint256 shortReturned;
}

/// @dev A struct describing how much long and short position are removed or added.
/// @param isRemoveLong0 True if long0 excess is removed from the user.
/// @param isRemoveLong1 True if long1 excess is removed from the user.
/// @param isRemoveShort True if short excess is removed from the user.
/// @param long0Amount The number of excess long0 is removed or added.
/// @param long1Amount The number of excess long1 is removed or added.
/// @param shortAmount The number of excess short is removed or added.
struct ExcessDelta {
  bool isRemoveLong0;
  bool isRemoveLong1;
  bool isRemoveShort;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
}

/// @dev The parameter for calling the collect function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param excessShortAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 excessShortAmount;
}

/// @dev The parameter for calling the lend given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of short position.
/// @param token0Amount The amount of token0 ERC20 tokens to deposit.
/// @param token1Amount The amount of token1 ERC20 tokens to deposit.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the close borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param to The receiver of the ERC20 tokens.
/// @param isLong0 True if the caller wants to close long0 positions, false if the caller wants to close long1 positions.
/// @param positionAmount The amount of chosen long positions to close.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the borrow given principal function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param token0Amount The amount of token0 ERC20 to borrow.
/// @param token1Amount The amount of token1 ERC20 to borrow.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

/// @dev The parameter for calling the borrow given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the long ERC1155 positions.
/// @param isLong0 True if the caller wants to receive long0 positions, false if the caller wants to receive long1 positions.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the close lend given position function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of long position to receive.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the rebalance function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param excessShortTo The receiver of any excess short ERC1155 tokens.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param givenLong0 True if the amount is in long0 position, false if the amount is in long1 position.
/// @param tokenAmount The amount of token amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryRebalanceParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address excessShortTo;
  bool isLong0ToLong1;
  bool givenLong0;
  uint256 tokenAmount;
  bytes data;
}

/// @dev The parameter for calling the redeem function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param token0AndLong0Amount The amount of token0 to receive and long0 to burn.
/// @param token1AndLong1Amount The amount of token1 to receive and long1 to burn.
struct TimeswapV2PeripheryRedeemParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
}

/// @dev The parameter for calling the transform function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param tokenTo The receiver of the ERC20 tokens.
/// @param longTo The receiver of the ERC1155 long positions.
/// @param isLong0ToLong1 True if transforming long0 position to long1 position, false if transforming long1 position to long0 position.
/// @param positionAmount The amount of long amount given isLong0ToLong1 and givenLong0.
/// @param data The bytes data passed to callback.
struct TimeswapV2PeripheryTransformParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  uint256 positionAmount;
  bytes data;
}

/// @dev The parameter for calling the withdraw function.
/// @param token0 The address of the smaller size ERC20 contract.
/// @param token1 The address of the larger size ERC20 contract.
/// @param strike The strike price of the position in UQ128.128.
/// @param maturity The maturity of the position in seconds.
/// @param token0To The receiver of any token0 ERC20 tokens.
/// @param token1To The receiver of any token1 ERC20 tokens.
/// @param positionAmount The amount of short ERC1155 tokens to burn.
struct TimeswapV2PeripheryWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 positionAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2TokenBurnCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2TokenBurnCallback {
  /// @dev Callback for `ITimeswapV2Token.burn`
  function timeswapV2TokenBurnCallback(
    TimeswapV2TokenBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title ERC-1155 Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC1155Enumerable is IERC1155 {
  /// @dev Returns the total amount of ids with positive supply stored by the contract.
  function totalIds() external view returns (uint256);

  /// @dev Returns the total supply of a token given its id.
  /// @param id The index of the queried token.
  function totalSupply(uint256 id) external view returns (uint256);

  /// @dev Returns a token ID owned by `owner` at a given `index` of its token list.
  /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /// @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
  /// Use along with {totalSupply} to enumerate all tokens.
  function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155Enumerable} from "./IERC1155Enumerable.sol";

import {TimeswapV2LiquidityTokenPosition} from "../structs/Position.sol";
import {TimeswapV2LiquidityTokenMintParam, TimeswapV2LiquidityTokenBurnParam, TimeswapV2LiquidityTokenCollectParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 liquidity token system
interface ITimeswapV2LiquidityToken is IERC1155Enumerable {
  error NotApprovedToTransferFees();

  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external view returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external view returns (address);

  /// @dev Returns the position Balance of the owner
  /// @param owner The owner of the token
  /// @param position The liquidity position
  function positionOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position
  ) external view returns (uint256 amount);

  /// @dev Returns the fee and short returned growth of the pool
  /// @param position The liquidity position
  /// @return long0FeeGrowth The long0 fee growth
  /// @return long1FeeGrowth The long1 fee growth
  /// @return shortFeeGrowth The short fee growth
  /// @return shortReturnedGrowth The short returned growth
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata position
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @dev Returns the fee and short returned growth of the pool
  /// @param position The liquidity position
  /// @param durationForward The time duration forward
  /// @return long0FeeGrowth The long0 fee growth
  /// @return long1FeeGrowth The long1 fee growth
  /// @return shortFeeGrowth The short fee growth
  /// @return shortReturnedGrowth The short returned growth
  function feesEarnedAndShortReturnedGrowth(
    TimeswapV2LiquidityTokenPosition calldata position,
    uint96 durationForward
  )
    external
    view
    returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth, uint256 shortReturnedGrowth);

  /// @param owner The address to query the fees earned and short returned of.
  /// @param position The liquidity token position.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @param owner The address to query the fees earned and short returned of.
  /// @param position The liquidity token position.
  /// @param durationForward The time duration forward
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  /// @return shortReturned The amount of short returned owned by the given address.
  function feesEarnedAndShortReturnedOf(
    address owner,
    TimeswapV2LiquidityTokenPosition calldata position,
    uint96 durationForward
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned);

  /// @dev Transfers position token TimeswapV2Token from `from` to `to`
  /// @param from The address to transfer position token from
  /// @param to The address to transfer position token to
  /// @param position The TimeswapV2Token Position to transfer
  /// @param liquidityAmount The amount of TimeswapV2Token Position to transfer
  /// @param erc1155Data Aribtrary custom data for erc1155 transfer
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2LiquidityTokenPosition calldata position,
    uint160 liquidityAmount,
    bytes calldata erc1155Data
  ) external;

  /// @dev mints TimeswapV2LiquidityToken as per the liqudityAmount
  /// @param param The TimeswapV2LiquidityTokenMintParam
  /// @return data Arbitrary data
  function mint(TimeswapV2LiquidityTokenMintParam calldata param) external returns (bytes memory data);

  /// @dev burns TimeswapV2LiquidityToken as per the liqudityAmount
  /// @param param The TimeswapV2LiquidityTokenBurnParam
  /// @return data Arbitrary data
  function burn(TimeswapV2LiquidityTokenBurnParam calldata param) external returns (bytes memory data);

  /// @dev collects fees as per the fees desired
  /// @param param The TimeswapV2LiquidityTokenBurnParam
  /// @return long0Fees Fees for long0
  /// @return long1Fees Fees for long1
  /// @return shortFees Fees for short
  /// @return shortReturned Short Returned
  function collect(
    TimeswapV2LiquidityTokenCollectParam calldata param
  )
    external
    returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, uint256 shortReturned, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {TimeswapV2TokenPosition} from "../structs/Position.sol";
import {TimeswapV2TokenMintParam, TimeswapV2TokenBurnParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 token system
/// @notice This interface is used to interact with TS-V2 positions
interface ITimeswapV2Token is IERC1155 {
  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the position Balance of the owner
  /// @param owner The owner of the token
  /// @param position type of option position (long0, long1, short)
  function positionOf(address owner, TimeswapV2TokenPosition calldata position) external view returns (uint256 amount);

  /// @dev Transfers position token TimeswapV2Token from `from` to `to`
  /// @param from The address to transfer position token from
  /// @param to The address to transfer position token to
  /// @param position The TimeswapV2Token Position to transfer
  /// @param amount The amount of TimeswapV2Token Position to transfer
  function transferTokenPositionFrom(
    address from,
    address to,
    TimeswapV2TokenPosition calldata position,
    uint256 amount
  ) external;

  /// @dev mints TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenMintParam
  /// @return data Arbitrary data
  function mint(TimeswapV2TokenMintParam calldata param) external returns (bytes memory data);

  /// @dev burns TimeswapV2Token as per postion and amount
  /// @param param The TimeswapV2TokenBurnParam
  function burn(TimeswapV2TokenBurnParam calldata param) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Amount The amount of long0 withdrawn.
/// @param long1Amount The amount of long1 withdrawn.
/// @param shortAmount The amount of short withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param liquidity The amount of liquidity increase.
/// @param data data
struct TimeswapV2LiquidityTokenMintCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint160 liquidityAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param liquidity The amount of liquidity decrease.
/// @param data data
struct TimeswapV2LiquidityTokenBurnCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint160 liquidityAmount;
  bytes data;
}

/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0Fees The amount of long0 fees withdrawn.
/// @param long1Fees The amount of long1 fees withdrawn.
/// @param shortFees The amount of short fees withdrawn.
/// @param data data
struct TimeswapV2LiquidityTokenCollectCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To The address of the recipient of TimeswapV2Token representing long0 position.
/// @param long1To The address of the recipient of TimeswapV2Token representing long1 position.
/// @param shortTo The address of the recipient of TimeswapV2Token representing short position.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To  The address of the recipient of long token0 position.
/// @param long1To The address of the recipient of long token1 position.
/// @param shortTo The address of the recipient of short position.
/// @param long0Amount  The amount of TimeswapV2Token long0  deposited and equivalent long0 position is withdrawn.
/// @param long1Amount The amount of TimeswapV2Token long1 deposited and equivalent long1 position is withdrawn.
/// @param shortAmount The amount of TimeswapV2Token short deposited and equivalent short position is withdrawn,
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for minting Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of TimeswapV2LiquidityToken.
/// @param liquidityAmount The amount of liquidity token deposited.
/// @param data Arbitrary data passed to the callback.
/// @param erc1155Data Arbitrary custojm data passed through erc115 minting.
struct TimeswapV2LiquidityTokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
  bytes erc1155Data;
}

/// @dev parameter for burning Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the liquidity token.
/// @param liquidityAmount The amount of liquidity token withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev parameter for collecting fees and shortReturned from Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param from The address of the owner of the fees and shortReturned;
/// @param long0FeesTo The address of the recipient of the long0 fees.
/// @param long1FeesTo The address of the recipient of the long1 fees.
/// @param shortFeesTo The address of the recipient of the short fees.
/// @param shortReturnedTo The address of the recipient of the short returned.
/// @param long0FeesDesired The maximum amount of long0Fees desired to be withdrawn.
/// @param long1FeesDesired The maximum amount of long1Fees desired to be withdrawn.
/// @param shortFeesDesired The maximum amount of shortFees desired to be withdrawn.
/// @param shortReturnedDesired The maximum amount of shortReturned desired to be withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address from;
  address long0FeesTo;
  address long1FeesTo;
  address shortFeesTo;
  address shortReturnedTo;
  uint256 long0FeesDesired;
  uint256 long1FeesDesired;
  uint256 shortFeesDesired;
  uint256 shortReturnedDesired;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks for token mint.
  function check(TimeswapV2TokenMintParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for token burn.
  function check(TimeswapV2TokenBurnParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token mint.
  function check(TimeswapV2LiquidityTokenMintParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token burn.
  function check(TimeswapV2LiquidityTokenBurnParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token collect.
  function check(TimeswapV2LiquidityTokenCollectParam memory param) internal pure {
    if (
      param.from == address(0) ||
      param.long0FeesTo == address(0) ||
      param.long1FeesTo == address(0) ||
      param.shortFeesTo == address(0) ||
      param.shortReturnedTo == address(0)
    ) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (
      param.long0FeesDesired == 0 &&
      param.long1FeesDesired == 0 &&
      param.shortFeesDesired == 0 &&
      param.shortReturnedDesired == 0
    ) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

/// @dev Struct for Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param position The position of the option.
struct TimeswapV2TokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  TimeswapV2OptionPosition position;
}

/// @dev Struct for Liquidity Token
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
struct TimeswapV2LiquidityTokenPosition {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
}

library PositionLibrary {
  /// @dev return keccak for key management for Token.
  function toKey(TimeswapV2TokenPosition memory timeswapV2TokenPosition) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2TokenPosition));
  }

  /// @dev return keccak for key management for Liquidity Token.
  function toKey(
    TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(timeswapV2LiquidityTokenPosition));
  }
}