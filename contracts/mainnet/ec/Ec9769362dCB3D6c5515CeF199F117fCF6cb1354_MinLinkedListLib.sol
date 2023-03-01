// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./FullMath.sol";

/// @notice Struct containing limit order data
struct LimitOrder {
    uint32 id;
    address owner;
    uint256 amount0;
    uint256 amount1;
}

/// @notice Struct for linked list node
/// @dev Each order id is mapped to a Node in the linked list
struct Node {
    uint32 prev;
    uint32 next;
    bool active;
}

/// @notice Struct for linked list sorted by price in non-decreasing order.
/// Used to store ask limit orders in the order book.
/// @dev Each order id is mapped to a Node and a LimitOrder
struct MinLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @notice Struct for linked list sorted in non-increasing order
/// Used to store bid limit orders in the order book.
/// @dev Each order id is mapped to a Node and a Limit Order
struct MaxLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @title MinLinkedListLib
/// @notice Library for linked list sorted in non-decreasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the lowest
/// possible price, and order 1 should be initialized with the highest
library MinLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly less than the price of order id1
    function compare(
        MinLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id0].amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MinLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the lowest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MinLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MinLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MinLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is less than the price of order id1
    function mockCompare(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

/// @title MaxLinkedListLib
/// @notice Library for linked list sorted in non-increasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the highest
/// possible price, and order 1 should be initialized with the lowest
library MaxLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly greater than the price of order id1
    function compare(
        MaxLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id0].amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MaxLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the highest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MaxLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MaxLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MaxLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is greater than the price of order id1
    function mockCompare(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                amount0,
                listData.idToLimitOrder[id1].amount0,
                amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.

        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

library FullMath {
    /// @notice Returns a*b/denominator, throws if remainder is not 0
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        require(denominator != 0, "Can not divide with 0");
        uint256 remainder = 0;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        require(remainder == 0, "Divison has a positive remainder");
        return Math.mulDiv(a, b, denominator);
    }

    /// @notice Returns true if a*b < c*d
    function mulCompare(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal pure returns (bool result) {
        uint256 prod0; // Least significant 256 bits of the product a*b
        uint256 prod1; // Most significant 256 bits of the product a*b
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 prod2; // Least significant 256 bits of the product c*d
        uint256 prod3; // Most significant 256 bits of the product c*d
        assembly {
            let mm := mulmod(c, d, not(0))
            prod2 := mul(c, d)
            prod3 := sub(sub(mm, prod2), lt(mm, prod2))
        }

        if (prod1 < prod3) return true;
        if (prod3 < prod1) return false;
        if (prod0 < prod2) return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}