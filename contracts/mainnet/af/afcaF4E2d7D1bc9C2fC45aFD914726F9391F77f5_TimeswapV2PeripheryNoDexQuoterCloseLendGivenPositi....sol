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

import {Math} from "./Math.sol";

/// @title Library for math utils for uint512
/// @author Timeswap Labs
library FullMath {
  using Math for uint256;

  /// @dev Reverts when modulo by zero.
  error ModuloByZero();

  /// @dev Reverts when add512 overflows over uint512.
  /// @param addendA0 The least significant part of first addend.
  /// @param addendA1 The most significant part of first addend.
  /// @param addendB0 The least significant part of second addend.
  /// @param addendB1 The most significant part of second addend.
  error AddOverflow(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1);

  /// @dev Reverts when sub512 underflows.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  error SubUnderflow(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1);

  /// @dev Reverts when div512To256 overflows over uint256.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  error DivOverflow(uint256 dividend0, uint256 dividend1, uint256 divisor);

  /// @dev Reverts when mulDiv overflows over uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  error MulDivOverflow(uint256 multiplicand, uint256 multiplier, uint256 divisor);

  /// @dev Calculates the sum of two uint512 numbers.
  /// @notice Reverts on overflow over uint512.
  /// @param addendA0 The least significant part of addendA.
  /// @param addendA1 The most significant part of addendA.
  /// @param addendB0 The least significant part of addendB.
  /// @param addendB1 The most significant part of addendB.
  /// @return sum0 The least significant part of sum.
  /// @return sum1 The most significant part of sum.
  function add512(
    uint256 addendA0,
    uint256 addendA1,
    uint256 addendB0,
    uint256 addendB1
  ) internal pure returns (uint256 sum0, uint256 sum1) {
    uint256 carry;
    assembly {
      sum0 := add(addendA0, addendB0)
      carry := lt(sum0, addendA0)
      sum1 := add(add(addendA1, addendB1), carry)
    }

    if (carry == 0 ? addendA1 > sum1 : (sum1 == 0 || addendA1 > sum1 - 1))
      revert AddOverflow(addendA0, addendA1, addendB0, addendB1);
  }

  /// @dev Calculates the difference of two uint512 numbers.
  /// @notice Reverts on underflow.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  /// @return difference0 The least significant part of difference.
  /// @return difference1 The most significant part of difference.
  function sub512(
    uint256 minuend0,
    uint256 minuend1,
    uint256 subtrahend0,
    uint256 subtrahend1
  ) internal pure returns (uint256 difference0, uint256 difference1) {
    assembly {
      difference0 := sub(minuend0, subtrahend0)
      difference1 := sub(sub(minuend1, subtrahend1), lt(minuend0, subtrahend0))
    }

    if (subtrahend1 > minuend1 || (subtrahend1 == minuend1 && subtrahend0 > minuend0))
      revert SubUnderflow(minuend0, minuend1, subtrahend0, subtrahend1);
  }

  /// @dev Calculate the product of two uint256 numbers that may result to uint512 product.
  /// @notice Can never overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product0 The least significant part of product.
  /// @return product1 The most significant part of product.
  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  /// @dev Divide 2 to 256 power by the divisor.
  /// @dev Rounds down the result.
  /// @notice Reverts when divide by zero.
  /// @param divisor The divisor.
  /// @return quotient The quotient.
  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  /// @dev Compute 2 to 256 power modulo the given value.
  /// @notice Reverts when modulo by zero.
  /// @param value The given value.
  /// @return result The result.
  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert ModuloByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }

  /// @dev Divide a uint512 number by uint256 number to return a uint512 number.
  /// @dev Rounds down the result.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor
  ) private pure returns (uint256 quotient0, uint256 quotient1) {
    if (dividend1 == 0) quotient0 = dividend0.div(divisor, false);
    else {
      uint256 q = div256(divisor);
      uint256 r = mod256(divisor);
      while (dividend1 != 0) {
        (uint256 t0, uint256 t1) = mul512(dividend1, q);
        (quotient0, quotient1) = add512(quotient0, quotient1, t0, t1);
        (t0, t1) = mul512(dividend1, r);
        (dividend0, dividend1) = add512(t0, t1, dividend0, 0);
      }
      (quotient0, quotient1) = add512(quotient0, quotient1, dividend0.div(divisor, false), 0);
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient The quotient.
  function div512To256(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient) {
    uint256 quotient1;
    (quotient, quotient1) = div512(dividend0, dividend1, divisor);

    if (quotient1 != 0) revert DivOverflow(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient, divisor);
      if (dividend1 > productA1 || dividend0 > productA0) quotient++;
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient0, uint256 quotient1) {
    (quotient0, quotient1) = div512(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient0, divisor);
      productA1 += (quotient1 * divisor);
      if (dividend1 > productA1 || dividend0 > productA0) {
        if (quotient0 == type(uint256).max) {
          quotient0 = 0;
          quotient1++;
        } else quotient0++;
      }
    }
  }

  /// @dev Multiply two uint256 number then divide it by a uint256 number.
  /// @notice Skips mulDiv if product of multiplicand and multiplier is uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function mulDiv(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 result) {
    (uint256 product0, uint256 product1) = mul512(multiplicand, multiplier);

    // Handle non-overflow cases, 256 by 256 division
    if (product1 == 0) return result = product0.div(divisor, roundUp);

    // Make sure the result is less than 2**256.
    // Also prevents divisor == 0
    if (divisor <= product1) revert MulDivOverflow(multiplicand, multiplier, divisor);

    unchecked {
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [product1 product0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(multiplicand, multiplier, divisor)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        product1 := sub(product1, gt(remainder, product0))
        product0 := sub(product0, remainder)
      }

      // Factor powers of two out of divisor
      // Compute largest power of two divisor of divisor.
      // Always >= 1.
      uint256 twos;
      twos = (0 - divisor) & divisor;
      // Divide denominator by power of two
      assembly {
        divisor := div(divisor, twos)
      }

      // Divide [product1 product0] by the factors of two
      assembly {
        product0 := div(product0, twos)
      }
      // Shift in bits from product1 into product0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      product0 |= product1 * twos;

      // Invert divisor mod 2**256
      // Now that divisor is an odd number, it has an inverse
      // modulo 2**256 such that divisor * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, divisor * inv = 1 mod 2**4
      uint256 inv;
      inv = (3 * divisor) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - divisor * inv; // inverse mod 2**8
      inv *= 2 - divisor * inv; // inverse mod 2**16
      inv *= 2 - divisor * inv; // inverse mod 2**32
      inv *= 2 - divisor * inv; // inverse mod 2**64
      inv *= 2 - divisor * inv; // inverse mod 2**128
      inv *= 2 - divisor * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of divisor. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and product1
      // is no longer required.
      result = product0 * inv;
    }

    if (roundUp && mulmod(multiplicand, multiplier, divisor) != 0) result++;
  }

  /// @dev Get the square root of a uint512 number.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function sqrt512(uint256 value0, uint256 value1, bool roundUp) internal pure returns (uint256 result) {
    if (value1 == 0) result = value0.sqrt(roundUp);
    else {
      uint256 estimate = sqrt512Estimate(value0, value1, type(uint256).max);
      result = type(uint256).max;
      while (estimate < result) {
        result = estimate;
        estimate = sqrt512Estimate(value0, value1, estimate);
      }

      if (roundUp) {
        (uint256 product0, uint256 product1) = mul512(result, result);
        if (value1 > product1 || value0 > product0) result++;
      }
    }
  }

  /// @dev An iterative process of getting sqrt512 following Newtonian method.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param currentEstimate The current estimate of the iteration.
  /// @param estimate The new estimate of the iteration.
  function sqrt512Estimate(
    uint256 value0,
    uint256 value1,
    uint256 currentEstimate
  ) private pure returns (uint256 estimate) {
    uint256 r0 = div512To256(value0, value1, currentEstimate, false);
    uint256 r1;
    (r0, r1) = add512(r0, 0, currentEstimate, 0);
    estimate = div512To256(r0, r1, 2, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for math related utils
/// @author Timeswap Labs
library Math {
  /// @dev Reverts when divide by zero.
  error DivideByZero();
  error Overflow();

  /// @dev Add two uint256.
  /// @notice May overflow.
  /// @param addend1 The first addend.
  /// @param addend2 The second addend.
  /// @return sum The sum.
  function unsafeAdd(uint256 addend1, uint256 addend2) internal pure returns (uint256 sum) {
    unchecked {
      sum = addend1 + addend2;
    }
  }

  /// @dev Subtract two uint256.
  /// @notice May underflow.
  /// @param minuend The minuend.
  /// @param subtrahend The subtrahend.
  /// @return difference The difference.
  function unsafeSub(uint256 minuend, uint256 subtrahend) internal pure returns (uint256 difference) {
    unchecked {
      difference = minuend - subtrahend;
    }
  }

  /// @dev Multiply two uint256.
  /// @notice May overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product The product.
  function unsafeMul(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product) {
    unchecked {
      product = multiplicand * multiplier;
    }
  }

  /// @dev Divide two uint256.
  /// @notice Reverts when divide by zero.
  /// @param dividend The dividend.
  /// @param divisor The divisor.
  //// @param roundUp Round up the result when true. Round down if false.
  /// @return quotient The quotient.
  function div(uint256 dividend, uint256 divisor, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend / divisor;

    if (roundUp && dividend % divisor != 0) quotient++;
  }

  /// @dev Shift right a uint256 number.
  /// @param dividend The dividend.
  /// @param divisorBit The divisor in bits.
  /// @param roundUp True if ceiling the result. False if floor the result.
  /// @return quotient The quotient.
  function shr(uint256 dividend, uint8 divisorBit, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend >> divisorBit;

    if (roundUp && dividend % (1 << divisorBit) != 0) quotient++;
  }

  /// @dev Gets the square root of a value.
  /// @param value The value being square rooted.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The resulting value of the square root.
  function sqrt(uint256 value, bool roundUp) internal pure returns (uint256 result) {
    if (value == type(uint256).max) return result = type(uint128).max;
    if (value == 0) return 0;
    unchecked {
      uint256 estimate = (value + 1) >> 1;
      result = value;
      while (estimate < result) {
        result = estimate;
        estimate = (value / estimate + estimate) >> 1;
      }
    }

    if (roundUp && result * result < value) result++;
  }

  /// @dev Gets the min of two uint256 number.
  /// @param value1 The first value to be compared.
  /// @param value2 The second value to be compared.
  /// @return result The min result.
  function min(uint256 value1, uint256 value2) internal pure returns (uint256 result) {
    return value1 < value2 ? value1 : value2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FullMath} from "./FullMath.sol";

/// @title library for converting strike prices.
/// @dev When strike is greater than uint128, the base token is denominated as token0 (which is the smaller address token).
/// @dev When strike is uint128, the base token is denominated as token1 (which is the larger address).
library StrikeConversion {
  /// @dev When zeroToOne, converts a number in multiple of strike.
  /// @dev When oneToZero, converts a number in multiple of 1 / strike.
  /// @param amount The amount to be converted.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function convert(uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) internal pure returns (uint256) {
    return
      zeroToOne
        ? FullMath.mulDiv(amount, strike, uint256(1) << 128, roundUp)
        : FullMath.mulDiv(amount, uint256(1) << 128, strike, roundUp);
  }

  /// @dev When toOne, converts a base denomination to token1 denomination.
  /// @dev When toZero, converts a base denomination to token0 denomination.
  /// @param amount The amount ot be converted. Token0 amount when zeroToOne. Token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param toOne ToOne if it is true, ToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function turn(uint256 amount, uint256 strike, bool toOne, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (toOne ? convert(amount, strike, true, roundUp) : amount)
        : (toOne ? amount : convert(amount, strike, false, roundUp));
  }

  /// @dev Combine and add token0Amount and token1Amount into base token amount.
  /// @param amount0 The token0 amount to be combined.
  /// @param amount1 The token1 amount to be combined.
  /// @param strike The strike multiple conversion.
  /// @param roundUp Round up the result when true. Round down if false.
  function combine(uint256 amount0, uint256 amount1, uint256 strike, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? amount0 + convert(amount1, strike, false, roundUp)
        : amount1 + convert(amount0, strike, true, roundUp);
  }

  /// @dev When zeroToOne, given a larger base amount, and token0 amount, get the difference token1 amount.
  /// @dev When oneToZero, given a larger base amount, and toekn1 amount, get the difference token0 amount.
  /// @param base The larger base amount.
  /// @param amount The token0 amount when zeroToOne, the token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function dif(
    uint256 base,
    uint256 amount,
    uint256 strike,
    bool zeroToOne,
    bool roundUp
  ) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (zeroToOne ? convert(base - amount, strike, true, roundUp) : base - convert(amount, strike, false, !roundUp))
        : (zeroToOne ? base - convert(amount, strike, true, !roundUp) : convert(base - amount, strike, false, roundUp));
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
  /// @param long1Amount The sum of long0AndToken0Amount and this amount is the total short amount burnt.
  /// @param token1Amount The amount of token1 withdrawn.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1Amount,
    uint256 token1Amount
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {ITimeswapV2PeripheryQuoterCloseLendGivenPosition} from "@timeswap-labs/v2-periphery/contracts/interfaces/lens/ITimeswapV2PeripheryQuoterCloseLendGivenPosition.sol";

import {IMulticall} from "../IMulticall.sol";

import {TimeswapV2PeripheryNoDexQuoterCloseLendGivenPositionParam} from "../../structs/lens/QuoterParam.sol";

/// @title An interface for TS-V2 Periphery NoDex Close Lend Given Position.
interface ITimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition is
  ITimeswapV2PeripheryQuoterCloseLendGivenPosition,
  IMulticall
{
  /// @dev The close lend given position function.
  /// @param param Close lend given position param.
  /// @return token0Amount
  /// @return token1Amount
  /// @return timeswapV2SqrtInterestRateAfter

  function closeLendGivenPosition(
    TimeswapV2PeripheryNoDexQuoterCloseLendGivenPositionParam calldata param,
    uint96 durationForward
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint160 timeswapV2SqrtInterestRateAfter);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenPosition} from "@timeswap-labs/v2-token/contracts/structs/Position.sol";

import {TimeswapV2PeripheryQuoterCloseLendGivenPosition} from "@timeswap-labs/v2-periphery/contracts/lens/TimeswapV2PeripheryQuoterCloseLendGivenPosition.sol";

import {TimeswapV2PeripheryCloseLendGivenPositionParam} from "@timeswap-labs/v2-periphery/contracts/structs/Param.sol";
import {TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam} from "@timeswap-labs/v2-periphery/contracts/structs/InternalParam.sol";
import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";

import {ITimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition} from "../interfaces/lens/ITimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition.sol";

import {OnlyOperatorReceiver} from "../base/OnlyOperatorReceiver.sol";

import {Multicall} from "../base/Multicall.sol";

import {TimeswapV2PeripheryNoDexQuoterCloseLendGivenPositionParam} from "../structs/lens/QuoterParam.sol";

contract TimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition is
  ITimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition,
  TimeswapV2PeripheryQuoterCloseLendGivenPosition,
  OnlyOperatorReceiver,
  Multicall
{
  constructor(
    address chosenOptionFactory,
    address chosenPoolFactory,
    address chosenTokens
  ) TimeswapV2PeripheryQuoterCloseLendGivenPosition(chosenOptionFactory, chosenPoolFactory, chosenTokens) {}

  /// @inheritdoc ITimeswapV2PeripheryNoDexQuoterCloseLendGivenPosition
  function closeLendGivenPosition(
    TimeswapV2PeripheryNoDexQuoterCloseLendGivenPositionParam memory param,
    uint96 durationForward
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint160 timeswapV2SqrtInterestRateAfter) {
    bytes memory data = abi.encode(param.isToken0);

    (token0Amount, token1Amount, data, timeswapV2SqrtInterestRateAfter) = closeLendGivenPosition(
      TimeswapV2PeripheryCloseLendGivenPositionParam({
        token0: param.token0,
        token1: param.token1,
        strike: param.strike,
        maturity: param.maturity,
        token0To: param.to,
        token1To: param.to,
        positionAmount: param.positionAmount,
        data: data
      }),
      durationForward
    );
  }

  function timeswapV2PeripheryCloseLendGivenPositionChoiceInternal(
    TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam memory param
  ) internal pure override returns (uint256 token0Amount, uint256 token1Amount, bytes memory data) {
    bool isToken0 = abi.decode(param.data, (bool));
    uint256 maxPrefferedTokenAmount = StrikeConversion.turn(param.tokenAmount, param.strike, !isToken0, false);
    uint256 prefferedTokenAmount = isToken0 ? param.token0Balance : param.token1Balance;
    uint256 otherTokenAmount;
    if (maxPrefferedTokenAmount <= prefferedTokenAmount) prefferedTokenAmount = maxPrefferedTokenAmount;
    else
      otherTokenAmount = StrikeConversion.dif(param.tokenAmount, prefferedTokenAmount, param.strike, isToken0, false);

    token0Amount = isToken0 ? prefferedTokenAmount : otherTokenAmount;
    token1Amount = isToken0 ? otherTokenAmount : prefferedTokenAmount;

    data = bytes("");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

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

import {ITimeswapV2PoolLeverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";

import {ITimeswapV2TokenBurnCallback} from "@timeswap-labs/v2-token/contracts/interfaces/callbacks/ITimeswapV2TokenBurnCallback.sol";

/// @title An interface for TS-V2 Periphery Close Lend Given Position
interface ITimeswapV2PeripheryQuoterCloseLendGivenPosition is
  ITimeswapV2PoolLeverageCallback,
  ITimeswapV2TokenBurnCallback,
  IERC1155Receiver
{
  error PassTokenBurnCallbackInfo(
    uint160 timeswapV2SqrtInterestRateAfter,
    uint256 token0Amount,
    uint256 token1Amount,
    bytes data
  );

  error PassPoolLeverageCallbackInfo(
    uint160 timeswapV2SqrtInterestRateAfter,
    uint256 token0Amount,
    uint256 token1Amount,
    bytes data
  );

  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Return the tokens address
  function tokens() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import {CatchError} from "@timeswap-labs/v2-library/contracts/CatchError.sol";

import {ITimeswapV2Option} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol";

import {TimeswapV2OptionBurnParam} from "@timeswap-labs/v2-option/contracts/structs/Param.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap} from "@timeswap-labs/v2-option/contracts/enums/Transaction.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/contracts/enums/Position.sol";

import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2Pool.sol";

import {TimeswapV2PoolLeverageParam} from "@timeswap-labs/v2-pool/contracts/structs/Param.sol";
import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "@timeswap-labs/v2-pool/contracts/structs/CallbackParam.sol";

import {TimeswapV2PoolLeverage} from "@timeswap-labs/v2-pool/contracts/enums/Transaction.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {ITimeswapV2Token} from "@timeswap-labs/v2-token/contracts/interfaces/ITimeswapV2Token.sol";

import {TimeswapV2TokenBurnParam} from "@timeswap-labs/v2-token/contracts/structs/Param.sol";
import {TimeswapV2TokenBurnCallbackParam} from "@timeswap-labs/v2-token/contracts/structs/CallbackParam.sol";

import {ITimeswapV2PeripheryQuoterCloseLendGivenPosition} from "../interfaces/lens/ITimeswapV2PeripheryQuoterCloseLendGivenPosition.sol";

import {TimeswapV2PeripheryCloseLendGivenPositionParam} from "../structs/Param.sol";
import {TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam} from "../structs/InternalParam.sol";

import {Verify} from "../libraries/Verify.sol";

abstract contract TimeswapV2PeripheryQuoterCloseLendGivenPosition is
  ITimeswapV2PeripheryQuoterCloseLendGivenPosition,
  ERC1155Receiver
{
  using CatchError for bytes;

  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2PeripheryQuoterCloseLendGivenPosition
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2PeripheryQuoterCloseLendGivenPosition
  address public immutable override poolFactory;
  /// @inheritdoc ITimeswapV2PeripheryQuoterCloseLendGivenPosition
  address public immutable override tokens;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenPoolFactory, address chosenTokens) {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
    tokens = chosenTokens;
  }

  function closeLendGivenPosition(
    TimeswapV2PeripheryCloseLendGivenPositionParam memory param,
    uint96 durationForward
  )
    internal
    returns (uint256 token0Amount, uint256 token1Amount, bytes memory data, uint160 timeswapV2SqrtInterestRateAfter)
  {
    data = abi.encode(param.token0To, param.token1To, param.positionAmount, durationForward, param.data);

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
          shortAmount: param.positionAmount,
          data: data
        })
      )
    {} catch (bytes memory reason) {
      data = reason.catchError(PassTokenBurnCallbackInfo.selector);
      (timeswapV2SqrtInterestRateAfter, token0Amount, token1Amount, data) = abi.decode(
        data,
        (uint160, uint256, uint256, bytes)
      );
    }
  }

  function timeswapV2TokenBurnCallback(
    TimeswapV2TokenBurnCallbackParam calldata param
  ) external returns (bytes memory data) {
    address token0To;
    address token1To;
    uint256 positionAmount;
    uint96 durationForward;
    (token0To, token1To, positionAmount, durationForward, data) = abi.decode(
      param.data,
      (address, address, uint256, uint96, bytes)
    );

    (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

    data = abi.encode(param.token0, param.token1, token0To, token1To, positionAmount, data);

    try
      ITimeswapV2Pool(poolPair).leverage(
        TimeswapV2PoolLeverageParam({
          strike: param.strike,
          maturity: param.maturity,
          long0To: address(this),
          long1To: address(this),
          transaction: TimeswapV2PoolLeverage.GivenSum,
          delta: positionAmount,
          data: data
        }),
        durationForward
      )
    {} catch (bytes memory reason) {
      data = reason.catchError(PassPoolLeverageCallbackInfo.selector);

      uint160 timeswapV2SqrtInterestRateAfter;
      uint256 token0Amount;
      uint256 token1Amount;
      (timeswapV2SqrtInterestRateAfter, token0Amount, token1Amount, data) = abi.decode(
        data,
        (uint160, uint256, uint256, bytes)
      );

      revert PassTokenBurnCallbackInfo(timeswapV2SqrtInterestRateAfter, token0Amount, token1Amount, data);
    }
  }

  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external override returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    address token0;
    address token1;
    address token0To;
    address token1To;
    uint256 positionAmount;
    (token0, token1, token0To, token1To, positionAmount, data) = abi.decode(
      param.data,
      (address, address, address, address, uint256, bytes)
    );

    Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    (long0Amount, long1Amount, data) = timeswapV2PeripheryCloseLendGivenPositionChoiceInternal(
      TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam({
        token0: token0,
        token1: token1,
        strike: param.strike,
        maturity: param.maturity,
        token0Balance: param.long0Balance,
        token1Balance: param.long1Balance,
        tokenAmount: param.longAmount,
        data: data
      })
    );

    data = abi.encode(token0, token1, token0To, token1To, positionAmount, data);
  }

  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external override returns (bytes memory data) {
    address token0;
    address token1;
    address token0To;
    address token1To;
    uint256 positionAmount;
    (token0, token1, token0To, token1To, positionAmount, data) = abi.decode(
      param.data,
      (address, address, address, address, uint256, bytes)
    );

    address optionPair = Verify.timeswapV2Pool(optionFactory, poolFactory, token0, token1);

    (, , uint256 shortAmountBurnt, ) = ITimeswapV2Option(optionPair).burn(
      TimeswapV2OptionBurnParam({
        strike: param.strike,
        maturity: param.maturity,
        token0To: token0To,
        token1To: token1To,
        transaction: TimeswapV2OptionBurn.GivenTokensAndLongs,
        amount0: param.long0Amount,
        amount1: param.long1Amount,
        data: bytes("")
      })
    );

    ITimeswapV2Option(optionPair).transferPosition(
      param.strike,
      param.maturity,
      msg.sender,
      TimeswapV2OptionPosition.Short,
      positionAmount - shortAmountBurnt
    );

    uint160 timeswapV2SqrtInterestRateAfter = ITimeswapV2Pool(msg.sender).sqrtInterestRate(
      param.strike,
      param.maturity
    );

    revert PassPoolLeverageCallbackInfo(timeswapV2SqrtInterestRateAfter, param.long0Amount, param.long1Amount, data);
  }

  function timeswapV2PeripheryCloseLendGivenPositionChoiceInternal(
    TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam memory param
  ) internal virtual returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";

library Verify {
  error CanOnlyBeCalledByOptionContract();

  error CanOnlyBeCalledByPoolContract();

  error CanOnlyBeCalledByTokensContract();

  error CanOnlyBeCalledByLiquidityTokensContract();

  function timeswapV2Option(address optionFactory, address token0, address token1) internal view {
    address optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    if (optionPair != msg.sender) revert CanOnlyBeCalledByOptionContract();
  }

  function timeswapV2Pool(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);

    address poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair != msg.sender) revert CanOnlyBeCalledByPoolContract();
  }

  function timeswapV2Token(address tokens) internal view {
    if (tokens != msg.sender) revert CanOnlyBeCalledByTokensContract();
  }

  function timeswapV2LiquidityToken(address liquidityTokens) internal view {
    if (liquidityTokens != msg.sender) revert CanOnlyBeCalledByLiquidityTokensContract();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct TimeswapV2PeripheryCollectProtocolFeesExcessLongChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryCollectTransactionFeesExcessLongChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryAddLiquidityGivenPrincipalChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 liquidityAmount;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryAddLiquidityGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 liquidityAmount;
  bytes data;
}

struct TimeswapV2PeripheryRemoveLiquidityAndFeesGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 token0Fees;
  uint256 token1Fees;
  uint256 tokenAmountFromPool;
  uint256 tokenAmountWithdraw;
  bytes data;
}

struct TimeswapV2PeripheryLendGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPositionInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryTransformInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

struct TimeswapV2PeripheryRebalanceInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 excessShortAmount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

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

struct TimeswapV2PeripheryCollectTransactionFeesParam {
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

struct TimeswapV2PeripheryCollectTransactionFeesAfterMaturityParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint256 shortRequested;
}

struct TimeswapV2PeripheryAddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address liquidityTo;
  uint256 token0Amount;
  uint256 token1Amount;
  bytes data;
}

struct TimeswapV2PeripheryRemoveLiquidityAndFeesGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  uint160 liquidityAmount;
  bytes data;
}

struct FeesDelta {
  bool isWithdrawLong0Fees;
  bool isWithdrawLong1Fees;
  bool isWithdrawShortFees;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
}

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

/// @dev The different kind of mint transactions.
enum TimeswapV2PoolMint {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenLarger
}

/// @dev The different kind of burn transactions.
enum TimeswapV2PoolBurn {
  GivenLiquidity,
  GivenLong,
  GivenShort,
  GivenSmaller
}

/// @dev The different kind of deleverage transactions.
enum TimeswapV2PoolDeleverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of leverage transactions.
enum TimeswapV2PoolLeverage {
  GivenDeltaSqrtInterestRate,
  GivenLong,
  GivenShort,
  GivenSum
}

/// @dev The different kind of rebalance transactions.
enum TimeswapV2PoolRebalance {
  GivenLong0,
  GivenLong1
}

library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev Function to revert with the error InvalidTransaction.
  function invalidTransaction() internal pure {
    revert InvalidTransaction();
  }

  /// @dev Sanity checks for the mint parameters.
  function check(TimeswapV2PoolMint transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the burn parameters.
  function check(TimeswapV2PoolBurn transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the deleverage parameters.
  function check(TimeswapV2PoolDeleverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the leverage parameters.
  function check(TimeswapV2PoolLeverage transaction) internal pure {
    if (uint256(transaction) >= 4) revert InvalidTransaction();
  }

  /// @dev Sanity checks for the rebalance parameters.
  function check(TimeswapV2PoolRebalance transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the leverage function.
interface ITimeswapV2PoolLeverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @dev The long0 positions and long1 positions will already be minted to the recipients.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

interface IOwnableTwoSteps {
  /// @dev Emits when the pending owner is chosen.
  /// @param pendingOwner The new pending owner.
  event SetOwner(address pendingOwner);

  /// @dev Emits when the pending owner accepted and become the new owner.
  /// @param owner The new owner.
  event AcceptOwner(address owner);

  /// @dev The address of the current owner.
  /// @return address
  function owner() external view returns (address);

  /// @dev The address of the current pending owner.
  /// @notice The address can be zero which signifies no pending owner.
  /// @return address
  function pendingOwner() external view returns (address);

  /// @dev The owner sets the new pending owner.
  /// @notice Can only be called by the owner.
  /// @param chosenPendingOwner The newly chosen pending owner.
  function setPendingOwner(address chosenPendingOwner) external;

  /// @dev The pending owner accepts being the new owner.
  /// @notice Can only be called by the pending owner.
  function acceptOwner() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeAndMaturity} from "@timeswap-labs/v2-option/contracts/structs/StrikeAndMaturity.sol";

import {TimeswapV2PoolAddFeesParam, TimeswapV2PoolCollectParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "../structs/Param.sol";

/// @title An interface for Timeswap V2 Pool contract.
interface ITimeswapV2Pool {
  /// @dev Emits when liquidity position is transferred.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param from The sender of liquidity position.
  /// @param to The receipeint of liquidity position.
  /// @param liquidityAmount The amount of liquidity position transferred.
  event TransferLiquidity(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint160 liquidityAmount
  );

  /// @dev Emits when fees is transferred.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param from The sender of fees position.
  /// @param to The receipeint of fees position.
  /// @param long0Fees The amount of long0 position fees transferred.
  /// @param long1Fees The amount of long1 position fees transferred.
  /// @param shortFees The amount of short position fees transferred.
  event TransferFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees
  );

  /// @dev Emits when fees is added from a user.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param to The receipeint of fees position.
  /// @param long0Fees The amount of long0 position fees received.
  /// @param long1Fees The amount of long1 position fees received.
  /// @param shortFees The amount of short position fees received.
  event AddFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees
  );

  /// @dev Emits when protocol fees are withdrawn by the factory contract owner.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectProtocolFees function.
  /// @param long0To The recipient of long0 position fees.
  /// @param long1To The recipient of long1 position fees.
  /// @param shortTo The recipient of short position fees.
  /// @param long0Amount The amount of long0 position fees withdrawn.
  /// @param long1Amount The amount of long1 position fees withdrawn.
  /// @param shortAmount The amount of short position fees withdrawn.
  event CollectProtocolFees(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when transaction fees are withdrawn by a liquidity provider.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the collectTransactionFees function.
  /// @param long0To The recipient of long0 position fees.
  /// @param long1To The recipient of long1 position fees.
  /// @param shortTo The recipient of short position fees.
  /// @param long0Amount The amount of long0 position fees withdrawn.
  /// @param long1Amount The amount of long1 position fees withdrawn.
  /// @param shortAmount The amount of short position fees withdrawn.
  event CollectTransactionFee(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when the mint transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the mint function.
  /// @param to The recipient of liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions minted.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions deposited.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when the burn transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the burn function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param shortTo The recipient of short positions.
  /// @param liquidityAmount The amount of liquidity positions burnt.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions withdrawn.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint160 liquidityAmount,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when deleverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the deleverage function.
  /// @param to The recipient of short positions.
  /// @param long0Amount The amount of long0 positions deposited.
  /// @param long1Amount The amount of long1 positions deposited.
  /// @param shortAmount The amount of short positions withdrawn.
  event Deleverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when leverage transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the leverage function.
  /// @param long0To The recipient of long0 positions.
  /// @param long1To The recipient of long1 positions.
  /// @param long0Amount The amount of long0 positions withdrawn.
  /// @param long1Amount The amount of long1 positions withdrawn.
  /// @param shortAmount The amount of short positions deposited.
  event Leverage(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    uint256 long0Amount,
    uint256 long1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when rebalance transaction is called.
  /// @param strike The strike of the option and pool.
  /// @param maturity The maturity of the option and pool.
  /// @param caller The caller of the rebalance function.
  /// @param to If isLong0ToLong1 then recipient of long0 positions, ekse recipient of long1 positions.
  /// @param isLong0ToLong1 Long0ToLong1 if true. Long1ToLong0 if false.
  /// @param long0Amount If isLong0ToLong1, amount of long0 positions deposited.
  /// If isLong1ToLong0, amount of long0 positions withdrawn.
  /// @param long1Amount If isLong0ToLong1, amount of long1 positions withdrawn.
  /// If isLong1ToLong0, amount of long1 positions deposited.
  event Rebalance(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address to,
    bool isLong0ToLong1,
    uint256 long0Amount,
    uint256 long1Amount
  );

  error Quote();

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function poolFactory() external view returns (address);

  /// @dev Returns the Timeswap V2 Option of the pair.
  function optionPair() external view returns (address);

  /// @dev Returns the transaction fee earned by the liquidity providers.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the protocol fee earned by the protocol.
  function protocolFee() external view returns (uint256);

  /// @dev Get the strike and maturity of the pool in the pool enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Get the number of pools being interacted.
  function numberOfPools() external view returns (uint256);

  /// @dev Returns the total amount of liquidity in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return liquidityAmount The liquidity amount of the pool.
  function totalLiquidity(uint256 strike, uint256 maturity) external view returns (uint160 liquidityAmount);

  /// @dev Returns the square root of the interest rate of the pool.
  /// @dev the square root of interest rate is z/(x+y) where z is the short amount, x+y is the long0 amount, and y is the long1 amount.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return rate The square root of the interest rate of the pool.
  function sqrtInterestRate(uint256 strike, uint256 maturity) external view returns (uint160 rate);

  /// @dev Returns the amount of liquidity owned by the given address.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the liquidity of.
  /// @return liquidityAmount The amount of liquidity owned by the given address.
  function liquidityOf(uint256 strike, uint256 maturity, address owner) external view returns (uint160 liquidityAmount);

  /// @dev It calculates the global fee growth, which is fee increased per unit of liquidity token.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return  shortFeeGrowth The global fee increased per unit of liquidity token for short.
  function feeGrowth(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth);

  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  function feesEarnedOf(
    uint256 strike,
    uint256 maturity,
    address owner
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees);

  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees);

  /// @dev Returns the amount of long0 and long1 in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool.
  /// @return long1Amount The amount of long1 in the pool.
  function totalLongBalance(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 long0Amount, uint256 long1Amount);

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    uint256 strike,
    uint256 maturity
  ) external view returns (uint256 longAmount, uint256 shortAmount);

  /* ===== UPDATE ===== */

  /// @dev Updates the fee growth.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  function update(uint256 strike, uint256 maturity) external;

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param to The recipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred
  function transferLiquidity(uint256 strike, uint256 maturity, address to, uint160 liquidityAmount) external;

  /// @dev Transfer fees earned of the sender to another address.
  /// @notice Does not transfer the liquidity positions of the sender.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param to The recipient of the transaction fees.
  /// @param long0Fees The amount of long0 position fees transferred.
  /// @param long1Fees The amount of long1 position fees transferred.
  /// @param shortFees The amount of short position fees transferred.
  function transferFees(
    uint256 strike,
    uint256 maturity,
    address to,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees
  ) external;

  /// @dev Transfer long0, long1, and/or short to fees storage.
  /// @param param The parameters of addFees.
  /// @return data the data used for the callbacks.
  function addFees(TimeswapV2PoolAddFeesParam calldata param) external returns (bytes memory data);

  /// @dev initializes the pool with the given parameters.
  /// @param strike The strike price of the pool.
  /// @param maturity The maturity of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(uint256 strike, uint256 maturity, uint160 rate) external;

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectProtocolFees.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    TimeswapV2PoolCollectParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount);

  /// @dev Collects the transaction fees of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param param The parameters of the collectTransactionFee.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectTransactionFees(
    TimeswapV2PoolCollectParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the mint function
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    TimeswapV2PoolMintParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param param it is a struct that contains the parameters of the burn function
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param durationForward The duration of time moved forward.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    TimeswapV2PoolBurnParam calldata param,
    uint96 durationForward
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the deleverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    TimeswapV2PoolDeleverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @notice Will always revert with error Quote after the final callback.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param durationForward The duration of time moved forward.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    TimeswapV2PoolLeverageParam calldata param,
    uint96 durationForward
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param param it is a struct that contains the parameters of the rebalance function
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  /// @return data the data used for the callbacks.
  function rebalance(
    TimeswapV2PoolRebalanceParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/// @title The interface for the contract that deploys Timeswap V2 Pool pair contracts
/// @notice The Timeswap V2 Pool Factory facilitates creation of Timeswap V2 Pool pair.
interface ITimeswapV2PoolFactory is IOwnableTwoSteps {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Pool contract is created.
  /// @param caller The address of the caller of create function.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  event Create(address caller, address option, address poolPair);

  /* ===== VIEW ===== */

  /// @dev Returns the fixed transaction fee used by all created Timeswap V2 Pool contract.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the fixed protocol fee used by all created Timeswap V2 Pool contract.
  function protocolFee() external view returns (uint256);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param option The address of the option contract used by the pool.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address option) external view returns (address poolPair);

  function getByIndex(uint256 id) external view returns (address optionPair);

  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Pool based on option parameter.
  /// @dev Cannot create a duplicate Timeswap V2 Pool with the same option parameter.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  function create(address option) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "../interfaces/ITimeswapV2PoolFactory.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title library for calculating poolFactory functions
/// @author Timeswap Labs
library PoolFactoryLibrary {
  using OptionFactoryLibrary for address;

  /// @dev Reverts when pool factory address is zero.
  error ZeroFactoryAddress();

  /// @dev Checks if the pool factory address is zero.
  /// @param poolFactory The pool factory address which is needed to be checked.
  function checkNotZeroFactory(address poolFactory) internal pure {
    if (poolFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Get the option pair address and pool pair address.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address. Zero address if not deployed.
  /// @return poolPair The retrieved pool pair address. Zero address if not deployed.
  function get(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.get(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);
  }

  /// @dev Get the option pair address and pool pair address.
  /// @notice Reverts when the option or the pool is not deployed.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address.
  /// @return poolPair The retrieved pool pair address.
  function getWithCheck(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.getWithCheck(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameters for the add fees callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Fees The amount of long0 position required by the pool from msg.sender.
/// @param long1Fees The amount of long1 position required by the pool from msg.sender.
/// @param shortFees The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolAddFeesCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev The parameters for the mint choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the mint callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that will be withdrawn.
/// @param long1Amount The amount of long1 position that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the deleverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the deleverage callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that can be withdrawn.
/// @param long1Amount The amount of long1 position that can be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the rebalance callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param long0Amount When Long0ToLong1, the amount of long0 position required by the pool from msg.sender.
/// When Long1ToLong0, the amount of long0 position that can be withdrawn.
/// @param long1Amount When Long0ToLong1, the amount of long1 position that can be withdrawn.
/// When Long1ToLong0, the amount of long1 position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolRebalanceCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 long0Amount;
  uint256 long1Amount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter for addFees functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The owner of the fees received.
/// @param long0Fees The amount of long0 position to be received.
/// @param long1Fees The amount of long1 position to be received.
/// @param shortFees The amount of short position to be received.
/// @param data The data to be sent to the function, which will go to the add fees callback.
struct TimeswapV2PoolAddFeesParam {
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev The parameter for collectTransactionFees and collectProtocolFees functions.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param long0Requested The maximum amount of long0 positions wanted.
/// @param long1Requested The maximum amount of long1 positions wanted.
/// @param shortRequested The maximum amount of short positions wanted.
struct TimeswapV2PoolCollectParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
}

/// @dev The parameter for mint function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of liquidity positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity minted. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// @param data The data to be sent to the function, which will go to the mint choice callback.
struct TimeswapV2PoolMintParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolMint transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for burn function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param delta If transaction is GivenLiquidity, the amount of liquidity burnt. Note that this value must be uint160.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the burn choice callback.
struct TimeswapV2PoolBurnParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2PoolBurn transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for deleverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to The recipient of short positions.
/// @param transaction The type of deleverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the decrease in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be deposited.
/// If transaction is GivenShort, the amount of short position to be withdrawn.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be deposited, and short position to be withdrawn.
/// @param data The data to be sent to the function, which will go to the deleverage choice callback.
struct TimeswapV2PoolDeleverageParam {
  uint256 strike;
  uint256 maturity;
  address to;
  TimeswapV2PoolDeleverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for leverage function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param transaction The type of leverage transaction, more information in Transaction module.
/// @param delta If transaction is GivenDeltaSqrtInterestRate, the increase in square root interest rate.
/// If transaction is GivenLong, the amount of long position in base denomination to be withdrawn.
/// If transaction is GivenShort, the amount of short position to be deposited.
/// If transaction is  GivenSum, the sum amount of long position in base denomination to be withdrawn, and short position to be deposited.
/// @param data The data to be sent to the function, which will go to the leverage choice callback.
struct TimeswapV2PoolLeverageParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  TimeswapV2PoolLeverage transaction;
  uint256 delta;
  bytes data;
}

/// @dev The parameter for rebalance function.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param to When Long0ToLong1, the recipient of long1 positions.
/// When Long1ToLong0, the recipient of long0 positions.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param transaction The type of rebalance transaction, more information in Transaction module.
/// @param delta If transaction is GivenLong0 and Long0ToLong1, the amount of long0 positions to be deposited.
/// If transaction is GivenLong0 and Long1ToLong0, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long0ToLong1, the amount of long1 positions to be withdrawn.
/// If transaction is GivenLong1 and Long1ToLong0, the amount of long1 positions to be deposited.
/// @param data The data to be sent to the function, which will go to the rebalance callback.
struct TimeswapV2PoolRebalanceParam {
  uint256 strike;
  uint256 maturity;
  address to;
  bool isLong0ToLong1;
  TimeswapV2PoolRebalance transaction;
  uint256 delta;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for addFees transaction.
  function check(TimeswapV2PoolAddFeesParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.long0Fees == 0 && param.long1Fees == 0 && param.shortFees == 0) Error.zeroInput();
    if (param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collectTransactionFees or collectProtocolFees transaction.
  function check(TimeswapV2PoolCollectParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Requested == 0 && param.long1Requested == 0 && param.shortRequested == 0 && param.strike == 0)
      Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for deleverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolDeleverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for leverage transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolLeverageParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.long0To == address(0) || param.long1To == address(0)) Error.zeroAddress();

    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for rebalance transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2PoolRebalanceParam memory param, uint96 blockTimestamp) internal pure {
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.to == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.delta == 0 || param.strike == 0) Error.zeroInput();
  }
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
/// @param long0Fees The amount of long0 required by the contract from msg.sender.
/// @param long1Fees The amount of long1 required by the contract from msg.sender.
/// @param shortFees The amount of short required by the contract from msg.sender.
/// @param data data
struct TimeswapV2LiquidityTokenAddFeesCallbackParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
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
struct TimeswapV2LiquidityTokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
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

/// @dev parameter for adding long0, long1, and short into fees storage.
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the fees.
/// @param long0Fees The amount of long0 to be deposited.
/// @param long1Fees The amount of long1 to be deposited.
/// @param shortFees The amount of short to be deposited.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenAddFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev parameter for collecting fees from Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the fees.
/// @param long0FeesDesired The maximum amount of long0Fees desired to be withdrawn.
/// @param long1FeesDesired The maximum amount of long1Fees desired to be withdrawn.
/// @param shortFeesDesired The maximum amount of shortFees desired to be withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 long0FeesDesired;
  uint256 long1FeesDesired;
  uint256 shortFeesDesired;
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

  /// @dev Sanity checks for liquidity add fees.
  function check(TimeswapV2LiquidityTokenAddFeesParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Fees == 0 && param.long1Fees == 0 && param.shortFees == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token collect.
  function check(TimeswapV2LiquidityTokenCollectParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0FeesDesired == 0 && param.long1FeesDesired == 0 && param.shortFeesDesired == 0) Error.zeroInput();
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