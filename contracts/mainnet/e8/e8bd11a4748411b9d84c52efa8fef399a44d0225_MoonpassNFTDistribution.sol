// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { MoonpassInitializer, RequestSignature } from "../../interfaces/IMoonpassContract.sol";
import { IMoonpassNFTDistribution, NFTDistributionInitializer, SetNFTCollectionRequest, AddNFTAllocationsRequest, RemoveNFTAllocationsRequest } from "../../interfaces/token-distribution/nft/IMoonpassNFTDistribution.sol";
import { MoonpassTokenDistribution } from "../MoonpassTokenDistribution.sol";
import { Token, TokenLibrary } from "../../types/Token.sol";
import { MoonpassRoles } from "../../auth/MoonpassRoles.sol";

contract MoonpassNFTDistribution is
  IMoonpassNFTDistribution,
  MoonpassTokenDistribution
{
  using TokenLibrary for Token;

  bytes32 internal constant SET_NFT_COLLECTION_TYPEHASH = keccak256("SetNFTCollectionRequest(uint256 nftNetworkId,address nftAddress,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant RESET_ALLOCATIONS_TYPEHASH = keccak256("ResetNFTAllocationsRequest(RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant ADD_ALLOCATIONS_TYPEHASH = keccak256("AddNFTAllocationsRequest(uint256[] tokenIds,uint256[] deposits,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant REMOVE_ALLOCATIONS_TYPEHASH = keccak256("RemoveNFTAllocationsRequest(uint256[] tokenIds,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");

  uint256 constant DEPOSIT_MASK = 18446744073709551615;
  uint256 constant DEPOSIT_BITS = 64;
  uint256 constant DEPOSIT_SLOTS = 256 / DEPOSIT_BITS;
  uint256 constant DEPOSIT_DECIMALS = 4;
  uint256 constant TOKEN_MASK = MASK_32;
  uint256 constant TOKEN_BITS = 32;
  uint256 constant TOKEN_SLOTS = 256 / TOKEN_BITS;

  struct MoonpassNFTDistributionStorage {
    uint256 _nftNetworkId;
    address _nftAddress;
    uint256 _decimalsGap;
    uint256 _maxAllocationIndex;
  }

  bytes32 private constant MoonpassNFTDistributionStorageLocation = 0xd581d835ebfbc96743dca8a21ec649c36be6c867b7e595a8b88d31eef342ea64;

  function _getMoonpassNFTDistributionStorage()
    internal
    pure 
    returns (MoonpassNFTDistributionStorage storage $) 
  {
    assembly {
      $.slot := MoonpassNFTDistributionStorageLocation
    }
  }

  function initialize(
    NFTDistributionInitializer calldata data,
    MoonpassInitializer calldata moonpass
  )
    initializer
    public
  {
    __TokenDistribution_init(data.distribution, moonpass);
    _setNFTCollection(data.nftNetworkId, data.nftAddress);
  }

  function allocationOf(
    uint256 tokenId
  ) 
    external 
    view 
    returns(
      uint256 balanceAmount,
      uint256 depositAmount,
      uint256 releasedAmount,
      uint256 withdrawableAmount,
      uint256 withdrawnAmount
    )
  {
    balanceAmount = _balanceOf(tokenId);
    depositAmount = _resolveDeposit(tokenId);
    releasedAmount = _releasedAt(tokenId, block.timestamp);
    withdrawableAmount = _withdrawableAt(tokenId, block.timestamp);
    withdrawnAmount = _resolveWithdrawn(tokenId);
  }

  function depositOf(
    uint256 tokenId
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _resolveDeposit(tokenId);
  }

  function balanceOf(
    uint256 tokenId
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _balanceOf(tokenId);
  }

  function withdrawn(
    uint256 tokenId
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _resolveWithdrawn(tokenId);
  }

  function withdrawable(
    uint256 tokenId
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _withdrawableAt(tokenId, block.timestamp);
  }

  function withdrawableAt(
    uint256 tokenId,
    uint256 timestamp
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _withdrawableAt(tokenId, timestamp);
  }

  function released(
    uint256 tokenId
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _releasedAt(tokenId, block.timestamp);
  }

  function releasedAt(
    uint256 tokenId,
    uint256 timestamp
  )
    external
    view
    returns(
      uint256 amount
    )
  {
    amount = _releasedAt(tokenId, timestamp);
  }

  function withdraw(
    uint256 tokenId,
    address to
  )
    external
    whenNotPaused
    whenCommitted
    onlyRole(MoonpassRoles.NFT_DISTRIBUTION_WITHDRAW_ROLE)
  {
    _withdraw(tokenId, to, _withdrawableAt(tokenId, block.timestamp));
  }

  function withdraw(
    uint256 tokenId,
    address to,
    uint256 amount
  )
    external
    whenNotPaused
    whenCommitted
    onlyRole(MoonpassRoles.NFT_DISTRIBUTION_WITHDRAW_ROLE)
  {
    _withdraw(tokenId, to, amount);
  }

  function nftCollection() 
    external 
    view 
    returns (
      uint256 nftNetworkId,
      address nftAddress
    )
  {
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    nftNetworkId = $._nftNetworkId;
    nftAddress = $._nftAddress;
  }

  function setNFTCollection(
    SetNFTCollectionRequest calldata request,
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      SET_NFT_COLLECTION_TYPEHASH,
      request.nftNetworkId,
      request.nftAddress,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _setNFTCollection(request.nftNetworkId, request.nftAddress);
  }

  function setNFTCollection(
    uint256 _nftNetworkId,
    address _nftAddress
  )
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _setNFTCollection(_nftNetworkId, _nftAddress);
  }

  function addAllocations(
    AddNFTAllocationsRequest calldata request,
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      keccak256(abi.encodePacked(request.tokenIds)),
      keccak256(abi.encodePacked(request.deposits)),
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _addAllocations(request.tokenIds, request.deposits);
  }

  function addAllocations(
    uint256[] calldata tokenIds,
    uint256[] calldata deposits
  )
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _addAllocations(tokenIds, deposits);
  }

  function removeAllocations(
    RemoveNFTAllocationsRequest calldata request,
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      REMOVE_ALLOCATIONS_TYPEHASH,
      keccak256(abi.encodePacked(request.tokenIds)),
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _removeAllocations(request.tokenIds);
  }

  function removeAllocations(
    uint256[] calldata tokenIds
  )
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _removeAllocations(tokenIds);
  }

  function resetAllocations(
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      RESET_ALLOCATIONS_TYPEHASH,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _resetAllocations();
  }

  function resetAllocations()
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _resetAllocations();
  }

  function _resolveDeposit(
    uint256 tokenId
  )
    internal
    override
    view
    returns(
      uint256 deposit
    )
  {
    MoonpassTokenDistributionStorage storage $$ = _getMoonpassTokenDistributionStorage();
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    deposit = ($$._allocations[tokenId / DEPOSIT_SLOTS] >> (tokenId % DEPOSIT_SLOTS * DEPOSIT_BITS) & DEPOSIT_MASK) * $._decimalsGap;
  }

  function _withdraw(
    uint256 tokenId,
    address to,
    uint256 amount
  )
    private
  {
    if(to == address(0)) {
      revert InvalidAddressError();
    }
    if(amount == 0) {
      revert InvalidWithdrawAmountError();
    }

    uint256 availableAmount = _withdrawableAt(tokenId, block.timestamp);
    if(availableAmount < amount) {
      revert InsufficientFundsError(tokenId, amount, availableAmount);
    }
    MoonpassTokenDistributionStorage storage $$ = _getMoonpassTokenDistributionStorage();
    $$._totalWithdrawals++;
    $$._totalWithdrawalsValue += amount;
    $$._withdrawals[tokenId] += amount;

    $$._token.transfer(to, amount);

    emit NFTAllocationWithdraw(tokenId, to, amount);
  }

  function _setNFTCollection(
    uint256 nftNetworkId,
    address nftAddress
  )
    internal
  {
    if(nftAddress == address(0)) {
      revert InvalidAddressError();
    }
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    $._nftNetworkId = nftNetworkId;
    $._nftAddress = nftAddress;

    emit NFTDistributionCollectionChange(nftNetworkId, nftAddress);
  }

  function _onTokenChange(Token newToken)
    internal
    override
  {
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    $._decimalsGap = 10 ** (newToken.decimals() - DEPOSIT_DECIMALS);
  }

  function _addAllocations(
    uint256[] calldata tokenIds,
    uint256[] calldata deposits
  )
    internal    
  {
    uint256 deposit;
    uint256 tokenId;

    for(uint256 i = 0; i < deposits.length * DEPOSIT_SLOTS; i++) {
      deposit = deposits[i / DEPOSIT_SLOTS] >> (i % DEPOSIT_SLOTS * DEPOSIT_BITS) & DEPOSIT_MASK;
      if(deposit == 0) continue;
      tokenId = tokenIds[i / TOKEN_SLOTS] >> (i % TOKEN_SLOTS * TOKEN_BITS) & TOKEN_MASK;
      
      _addAllocation(tokenId, deposit);
    }
  }
  

  function _addAllocation(
    uint256 tokenId,
    uint256 deposit
  )
    internal
  {
    MoonpassTokenDistributionStorage storage $$ = _getMoonpassTokenDistributionStorage();
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    uint256 slot;
    uint256 bits;
    uint256 currentDeposit = _resolveDeposit(tokenId);

    slot = tokenId / DEPOSIT_SLOTS;
    bits = tokenId % DEPOSIT_SLOTS * DEPOSIT_BITS;
    $$._allocations[slot] = ($$._allocations[slot] & ~(DEPOSIT_MASK << bits)) | (deposit << bits);

    $._maxAllocationIndex = Math.max($._maxAllocationIndex, slot);
    $$._totalDeposits += currentDeposit == 0 ? 1 : 0;
    $$._totalDepositsValue += deposit * $._decimalsGap;
    $$._totalDepositsValue -= currentDeposit;

    emit NFTAllocationCreate(tokenId, deposit * $._decimalsGap);
  }

  function _removeAllocations(
    uint256[] calldata tokenIds
  )
    internal
  {
    uint256 deposit;
    uint256 tokenId;
    uint256 amount;
    uint256 total;
    MoonpassTokenDistributionStorage storage $$ = _getMoonpassTokenDistributionStorage();
    for(uint256 i = 0; i < tokenIds.length * TOKEN_SLOTS; i++) {
      tokenId = tokenIds[i / TOKEN_SLOTS] >> (i % TOKEN_SLOTS * TOKEN_BITS) & TOKEN_MASK;
      deposit = _resolveDeposit(tokenId);
      if(deposit == 0) continue;

      $$._allocations[tokenId / DEPOSIT_SLOTS] &= ~(DEPOSIT_MASK << tokenId % DEPOSIT_SLOTS * DEPOSIT_BITS);

      total++;
      amount += deposit;

      emit NFTAllocationRemove(tokenId);
    }

    $$._totalDeposits -= total;
    $$._totalDepositsValue -= amount; // Decimal gaps embedded
  }

  function _resetAllocations()
    internal
  {
    MoonpassNFTDistributionStorage storage $ = _getMoonpassNFTDistributionStorage();
    MoonpassTokenDistributionStorage storage $$ = _getMoonpassTokenDistributionStorage();
    for(uint i = 0; i <= $._maxAllocationIndex; i++) {
      $$._allocations[i] = 0;
    }
    $$._totalDeposits = 0;
    $$._totalDepositsValue = 0;
    $._maxAllocationIndex = 0;
    emit NFTAllocationsReset();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

interface IMoonpassContract
{
  function authorizer() external view returns(address authorizerAddress);

  function setAuthorizer(address authorizerAddress) external;

  function setAuthorizer(SetAuthorizerRequest calldata request, RequestSignature calldata signature) external;

  function version() external view returns (uint64);

  error InvalidAddressError();
  error InvalidRequestError();

  event AuthorizerChange(address authorizationManager);
}

struct MoonpassInitializer {
  address owner;
  address authorizer;
}

struct SetAuthorizerRequest {
  address authorizerAddress;
}

struct RequestSignature {
  uint8 v;
  bytes32 r;
  bytes32 s;
  uint256 expiry;
  uint256 nonce;
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

import { MoonpassInitializer, RequestSignature } from "../../IMoonpassContract.sol";
import { IMoonpassTokenDistribution, TokenDistributionInitializer } from "../IMoonpassTokenDistribution.sol";

interface IMoonpassNFTDistribution is 
  IMoonpassTokenDistribution
{
  function initialize(NFTDistributionInitializer calldata data, MoonpassInitializer calldata moonpass) external;

  function allocationOf(uint256 tokenId) external view returns(uint256 balanceAmount, uint256 depositAmount, uint256 releasedAmount, uint256 withdrawableAmount, uint256 withdrawnAmount);

  function depositOf(uint256 tokenId) external view returns(uint256 amount);
  
  function balanceOf(uint256 tokenId) external view returns(uint256 amount);

  function withdrawn(uint256 tokenId) external view returns(uint256 amount);

  function withdrawable(uint256 tokenId) external view returns(uint256 amount);

  function withdrawableAt(uint256 tokenId, uint256 timestamp) external view returns(uint256 amount);
    
  function released(uint256 tokenId) external view returns(uint256 amount);

  function releasedAt(uint256 tokenId, uint256 timestamp) external view returns(uint256 amount);
  
  function withdraw(uint256 tokenId, address to, uint256 amount) external;

  function withdraw(uint256 tokenId, address to) external;

  function nftCollection() external view returns (uint256 nftNetworkId, address nftAddress);

  function setNFTCollection(SetNFTCollectionRequest calldata request, RequestSignature calldata signature) external;

  function setNFTCollection(uint256 nftNetworkId, address nftAddress) external;

  function addAllocations(AddNFTAllocationsRequest calldata request,RequestSignature calldata signature) external;

  function addAllocations(uint256[] calldata tokenIds, uint256[] calldata deposits) external;

  function removeAllocations(RemoveNFTAllocationsRequest calldata request,RequestSignature calldata signature) external;

  function removeAllocations(uint256[] calldata tokenIds) external;

  function resetAllocations(RequestSignature calldata signature) external;

  function resetAllocations() external;

  event NFTDistributionCollectionChange(uint256 indexed nftNetworkId, address indexed nftAddress);
  event NFTAllocationRemove(uint256 indexed tokenId);
  event NFTAllocationsReset();
  event NFTAllocationCreate(uint256 indexed tokenId, uint256 indexed deposit);
  event NFTAllocationWithdraw(uint256 indexed tokenId, address indexed to, uint256 indexed amount);
  
  error InsufficientFundsError(uint256 tokenId, uint256 requested, uint256 available);
  error InvalidWithdrawAmountError();
}

struct NFTDistributionInitializer {
  TokenDistributionInitializer distribution;
  uint256 nftNetworkId;
  address nftAddress;
}

struct SetNFTCollectionRequest {
  uint256 nftNetworkId;
  address nftAddress;
}

struct AddNFTAllocationsRequest {
  uint256[] tokenIds;
  uint256[] deposits;
}

struct RemoveNFTAllocationsRequest {
  uint256[] tokenIds;
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

import { MoonpassInitializer, RequestSignature } from "../interfaces/IMoonpassContract.sol";
import { IMoonpassTokenDistribution, TokenDistributionInitializer, ClawbackRequest, SetTokenRequest, SetNameRequest, SetVestingsRequest, VestingSchedule } from "../interfaces/token-distribution/IMoonpassTokenDistribution.sol";
import { Token, TokenLibrary } from "../types/Token.sol";
import { MoonpassContract } from "../MoonpassContract.sol";
import { MoonpassRoles } from "../auth/MoonpassRoles.sol";

contract MoonpassTokenDistribution is
  IMoonpassTokenDistribution,
  MoonpassContract
{
  using TokenLibrary for Token;

  bytes32 internal constant CLAWBACK_TYPEHASH = keccak256("ClawbackRequest(address to,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant SET_TOKEN_TYPEHASH = keccak256("SetTokenRequest(address tokenAddress,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant SET_NAME_TYPEHASH = keccak256("SetNameRequest(string name,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant SET_VESTINGS_TYPEHASH = keccak256("SetVestingsRequest(uint256[] vestingsData,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 internal constant COMMIT_TYPEHASH = keccak256("CommitRequest(RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");

  uint256 public constant ONE_HUNDRED_PERCENT = 100 * (10 ** 4);
  uint256 internal constant MASK_32 = 4294967295;

  struct MoonpassTokenDistributionStorage {
    string _name;
    Token _token;
    uint256 _committed;
    uint256 _totalDeposits;
    uint256 _totalDepositsValue;
    uint256 _totalWithdrawals;
    uint256 _totalWithdrawalsValue;

    uint256[] _vestings;
    mapping(uint256 => uint256) _allocations;
    mapping(uint256 => uint256) _withdrawals;
  }

  bytes32 private constant MoonpassTokenDistributionStorageLocation = 0x17c81b7724de13b337e53af0b0bdf03a08a4b7236f0f52e022a14a1a2a5ec8b0;

  function _getMoonpassTokenDistributionStorage()
    internal
    pure 
    returns (MoonpassTokenDistributionStorage storage $) 
  {
    assembly {
      $.slot := MoonpassTokenDistributionStorageLocation
    }
  }

  function __TokenDistribution_init(
    TokenDistributionInitializer calldata data,
    MoonpassInitializer calldata moonpass
  )
    onlyInitializing
    internal
  {
    __Moonpass_init(moonpass);
    _setName(data.name);
    _setToken(data.tokenAddress);
  }

  function committed()
    external
    view 
    returns(
      bool isCommitted
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    isCommitted = $._committed == 1;
  }

  function available()
    external
    view
    returns(
      uint256 percentage
    )
  {
    percentage = _availableAt(block.timestamp);
  }

  function availableAt(
    uint256 timestamp
  )
    external
    view
    returns(
      uint256 percentage
    )
  {
    percentage = _availableAt(timestamp);
  }

  function vestings()
    external
    view
    returns(
      VestingSchedule[] memory schedules
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    uint256 start;
    uint256 end;
    uint256 percentage;
    uint256 length = $._vestings.length;
    schedules = new VestingSchedule[](length);
    for(uint256 i = 0; i < length; i++) {
      (start, end, percentage) = _parseVesting($._vestings[i]);
      schedules[i] = VestingSchedule(start, end, percentage);
    }
  }

  function balance()
    external
    view 
    returns(uint256 amount)
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    amount = $._token.balanceOfSelf();
  }

  function requiredBalance()
    external
    view
    returns(uint256 amount)
  {
    amount = _requiredBalanceAt(block.timestamp);
  }

  function requiredBalanceAt(
    uint256 timestamp
  ) 
    external
    view 
    returns(uint256 amount)
  {
    amount = _requiredBalanceAt(timestamp);
  }

  function commitment()
    external
    view
    returns(
      bool isCommitted,
      uint256 depositsAmount,
      uint256 withdrawalsAmount,
      uint256 balanceAmount,
      uint256 requiredBalanceAmount
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    isCommitted = $._committed == 1;
    depositsAmount = $._totalDepositsValue;
    withdrawalsAmount = $._totalWithdrawalsValue;
    balanceAmount = $._token.balanceOfSelf();
    requiredBalanceAmount = _requiredBalanceAt(block.timestamp);
  }

  function deposits()
    external
    view
    returns(
      uint256 count,
      uint256 amount
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    count = $._totalDeposits;
    amount = $._totalDepositsValue;
  }

  function withdrawals()
    external
    view
    returns(
      uint256 count,
      uint256 amount
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    count = $._totalWithdrawals;
    amount = $._totalWithdrawalsValue;
  }

  function name()
    external 
    view 
    returns(
      string memory distributionName
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    distributionName = $._name;
  }

  function setName(
    SetNameRequest calldata request,
    RequestSignature calldata signature
  ) 
    external
  {
    bytes memory data = abi.encode(
      SET_NAME_TYPEHASH,
      request.name,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));
    
    _setName(request.name);
  }

  function setName(
    string calldata distributionName
  ) 
    external
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _setName(distributionName);
  }

  function token()
    external
    view
    returns(
      address tokenAddress
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    tokenAddress = Token.unwrap($._token);
  }

  function setToken(
    SetTokenRequest calldata request,
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      SET_TOKEN_TYPEHASH,
      request.tokenAddress,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));
    
    _setToken(request.tokenAddress);
  }

  function setToken(
    address tokenAddress
  )
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _setToken(tokenAddress);
  }

  function setVestings(
    SetVestingsRequest calldata request,
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      SET_TOKEN_TYPEHASH,
      keccak256(abi.encodePacked(request.vestingsData)),
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));
    
    _setVestings(request.vestingsData);
  }

  function setVestings(
    uint256[] calldata vestingsData
  )
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _setVestings(vestingsData);
  }

  function commit(
    RequestSignature calldata signature
  )
    external
    whenNotCommitted
  {
    bytes memory data = abi.encode(
      COMMIT_TYPEHASH,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _commit();
  }

  function commit()
    external
    whenNotCommitted
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _commit();
  }

  function clawback(
    ClawbackRequest calldata request,
    RequestSignature calldata signature
  )
    external
  {
    bytes memory data = abi.encode(
      CLAWBACK_TYPEHASH,
      request.to,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE, _signerFrom(data, signature));

    _clawback(request.to);
  }

  function clawback(
    address to
  )
    external
    onlyRole(MoonpassRoles.DISTRIBUTION_MANAGER_ROLE)
  {
    _clawback(to);
  }

  function _setToken(
    address tokenAddress
  )
    internal
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    if($._totalDeposits > 0) {
      revert DepositsFoundError();
    }
    $._token = Token.wrap(tokenAddress);
    _onTokenChange($._token);

    emit DistributionTokenChange(tokenAddress);
  }

  function _setName(
    string calldata distributionName
  )
    internal
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    $._name = distributionName;
    emit DistributionNameChange();
  }

  function _onTokenChange(Token newToken)
    internal
    virtual
  {}

  function _setVestings(
    uint256[] calldata vestingsData
  )
    internal
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
   $._vestings = vestingsData;

    emit DistributionVestingsChange(vestingsData);
  }

  function _commit()
    internal
  {
    _validateVestings();
    _validateDeposits();
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    $._committed = 1;

    emit DistributionCommit();
  }

  function _balanceOf(
    uint256 allocation
  )
    internal
    view
    returns(
      uint256 balanceAmount
    )
  {
    balanceAmount = _resolveDeposit(allocation) - _resolveWithdrawn(allocation);
  }

  function _requiredBalanceAt(
    uint256 timestamp
  ) 
    internal
    view 
    returns(uint256 amount)
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    amount = ($._totalDepositsValue * _availableAt(timestamp) / ONE_HUNDRED_PERCENT) - $._totalWithdrawalsValue;
  }

  function _withdrawableAt(
    uint256 allocation,
    uint256 timestamp
  )
    internal
    view
    returns(
      uint256 withdrawableAmount
    )
  {
    uint256 released = _releasedAt(allocation, timestamp);
    uint256 withdrawn = _resolveWithdrawn(allocation);
    if(withdrawn > released) {
      withdrawableAmount = 0;
    } else {
      withdrawableAmount = released - withdrawn;
    }
  }

  function _releasedAt(
    uint256 allocation,
    uint256 timestamp
  )
    internal
    view
    returns(
      uint256 releasedAmount
    )
  {
    releasedAmount = _resolveDeposit(allocation) * _availableAt(timestamp) / ONE_HUNDRED_PERCENT;
  }

  function _parseVesting(
    uint256 vestingData
  )
    internal
    pure
    returns(
      uint256 start,
      uint256 end,
      uint256 percentage
    )
  {
    start = (vestingData >> 64) & MASK_32;
    end = (vestingData >> 32) & MASK_32;
    percentage = vestingData & MASK_32;
  }

  function _resolveDeposit(
    uint256 allocation
  )
    internal
    virtual
    view
    returns(
      uint256 deposit
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    deposit = $._allocations[allocation];
  }

  function _resolveWithdrawn(
    uint256 allocation
  )
    internal
    virtual
    view
    returns(
      uint256 withdrawn
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    withdrawn = $._withdrawals[allocation];
  }

  function _availableAt(uint256 timestamp)
    internal
    view
    returns(
      uint256 percentage
    )
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    uint256 length = $._vestings.length;
    uint256 current = 0;
    for(uint256 i = 0; i < length; i++) {
      current = _availableByVestingAt($._vestings[i], timestamp);
      if(current == 0) {
        break;
      }
      percentage += current;
    }
  }

  function _availableByVestingAt(
    uint256 vestingData,
    uint256 timestamp
  )
    internal
    pure
    returns(
      uint256 availablePercentage
    )
  {
    (uint256 start, uint256 end, uint256 percentage) = _parseVesting(vestingData);
    availablePercentage = start >= timestamp ? 
      0 : end < timestamp ?
        percentage : (timestamp - start) * percentage / (end - start);
  }

  function _validateDeposits()
    internal
    view
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    if($._totalDeposits == 0 || $._totalDepositsValue == 0) {
      revert MissingAllocationsError();
    }
  }

  function _validateVestings()
    internal
    view
  {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    uint256 length = $._vestings.length;
    uint256 previousEnd = 0;
    uint256 totalPercentage;
    uint256 start;
    uint256 end;
    uint256 percentage;

    if(length == 0) revert InvalidVestingsError();
    
    for(uint256 i = 0; i < length; i++) {
      (start, end, percentage) = _parseVesting($._vestings[i]);
      if(start > end
        || percentage == 0
        || percentage > ONE_HUNDRED_PERCENT
        || previousEnd > start
      ) {
        revert InvalidVestingError(i);
      }
      totalPercentage += percentage;
      previousEnd = end;
    }

    if(totalPercentage != ONE_HUNDRED_PERCENT) revert InvalidVestingsError();
  }

  function _clawback(
    address to
  )
    private
  {
    if(to == address(0)) {
      revert InvalidAddressError();
    }
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    uint256 tokenBalance = $._token.balanceOfSelf();
    if($._committed == 1) {
      uint256 required = _requiredBalanceAt(block.timestamp);
      if(tokenBalance <= required) {
        revert NoBalanceToClawbackError();
      }
      $._token.transfer(to, tokenBalance - required);
    } else {
      $._token.transfer(to, tokenBalance);
    }

    emit DistributionClawback(to);
  }

  modifier whenNotCommitted {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    if($._committed == 1) {
      revert DistributionIsCommittedError();
    }
    _;
  }

  modifier whenCommitted {
    MoonpassTokenDistributionStorage storage $ = _getMoonpassTokenDistributionStorage();
    if($._committed == 0) {
      revert DistributionNotCommittedError();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

type Token is address;

using {greaterThan as >, lessThan as <, equals as ==} for Token global;

function equals(Token token, Token other) pure returns (bool) {
  return Token.unwrap(token) == Token.unwrap(other);
}

function greaterThan(Token token, Token other) pure returns (bool) {
  return Token.unwrap(token) > Token.unwrap(other);
}

function lessThan(Token token, Token other) pure returns (bool) {
  return Token.unwrap(token) < Token.unwrap(other);
}

/// @title TokenLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library TokenLibrary {
  using TokenLibrary for Token;

  /// @notice Thrown when a native transfer fails
  error NativeTransferFailed();

  /// @notice Thrown when an ERC20 transfer fails
  error ERC20TransferFailed();

  Token public constant NATIVE = Token.wrap(address(0));

  function transfer(Token token, address to, uint256 amount) internal {
    // implementation from
    // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

    bool success;
    if (token.isNative()) {
      assembly {
        // Transfer the ETH and store if it succeeded or not.
        success := call(gas(), to, amount, 0, 0, 0, 0)
      }

      if (!success) revert NativeTransferFailed();
    } else {
      assembly {
        // We'll write our calldata to this slot below, but restore it later.
        let memPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
        mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
        mstore(4, to) // Append the "to" argument.
        mstore(36, amount) // Append the "amount" argument.

        success :=
          and(
            // Set success to whether the call reverted, if not we check it either
            // returned exactly 1 (can't just be non-zero data), or had no return data.
            or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
            // We use 68 because that's the total length of our calldata (4 + 32 * 2)
            // Counterintuitively, this call() must be positioned after the or() in the
            // surrounding and() because and() evaluates its arguments from right to left.
            call(gas(), token, 0, 0, 68, 0, 32)
          )

        mstore(0x60, 0) // Restore the zero slot to zero.
        mstore(0x40, memPointer) // Restore the memPointer.
      }

      if (!success) revert ERC20TransferFailed();
    }
  }

  function balanceOfSelf(Token token) internal view returns (uint256) {
    if (token.isNative()) {
      return address(this).balance;
    } else {
      return IERC20Metadata(Token.unwrap(token)).balanceOf(address(this));
    }
  }

  function balanceOf(Token token, address owner) internal view returns (uint256) {
    if (token.isNative()) {
      return owner.balance;
    } else {
      return IERC20Metadata(Token.unwrap(token)).balanceOf(owner);
    }
  }

  function decimals(Token token) internal view returns (uint256) {
    if (token.isNative()) {
      return 18;
    } else {
      return IERC20Metadata(Token.unwrap(token)).decimals();
    }
  }

  function name(Token token) internal view returns (string memory) {
    if (token.isNative()) {
      return "native";
    } else {
      return IERC20Metadata(Token.unwrap(token)).name();
    }
  }

  function symbol(Token token) internal view returns (string memory) {
    if (token.isNative()) {
      return "native";
    } else {
      return IERC20Metadata(Token.unwrap(token)).symbol();
    }
  }

  function isNative(Token token) internal pure returns (bool) {
    return Token.unwrap(token) == Token.unwrap(NATIVE);
  }
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

library MoonpassRoles {
  bytes32 public constant FACTORY_MANAGER_ROLE = keccak256("FACTORY_MANAGER_ROLE");
  bytes32 public constant DISTRIBUTION_MANAGER_ROLE = keccak256("DISTRIBUTION_MANAGER_ROLE");
  bytes32 public constant NFT_DISTRIBUTION_WITHDRAW_ROLE = keccak256("NFT_DISTRIBUTION_WITHDRAW_ROLE");
  bytes32 public constant ACCOUNT_DISTRIBUTION_WITHDRAW_ROLE = keccak256("ACCOUNT_DISTRIBUTION_WITHDRAW_ROLE");

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  bytes32 public constant CLAIM_ADMIN_ROLE = keccak256("CLAIM_ADMIN_ROLE");
  bytes32 public constant CLAIM_MANAGER_ROLE = keccak256("CLAIM_MANAGER_ROLE");
  bytes32 public constant CLAIM_TRUSTEE_ROLE = keccak256("CLAIM_TRUSTEE_ROLE");
  bytes32 public constant VAULT_TRUSTEE_ROLE = keccak256("VAULT_TRUSTEE_ROLE");

  bytes32 public constant AUTH_DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 public constant AUTH_MANAGER_ROLE = keccak256("AUTH_MANAGER_ROLE");
  bytes32 public constant AUTH_MASTER_ROLE = keccak256("AUTH_MASTER_ROLE");

  bytes32 public constant NFT_ADMIN_ROLE = keccak256("NFT_ADMIN_ROLE");
  bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");
  bytes32 public constant NFT_MINTER_ROLE = keccak256("NFT_MINTER_ROLE");

  bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
  bytes32 public constant PROPOSAL_MANAGER_ROLE = keccak256("PROPOSAL_MANAGER_ROLE");
  bytes32 public constant FUNDRAISER_MANAGER_ROLE = keccak256("FUNDRAISER_MANAGER_ROLE");

  bytes32 public constant NFT_MINTER_TRUSTEE_ROLE = keccak256("NFT_MINTER_TRUSTEE_ROLE");
  bytes32 public constant NFT_TRUSTEE_ROLE = keccak256("NFT_TRUSTEE_ROLE");
  bytes32 public constant PROPOSAL_TRUSTEE_ROLE = keccak256("PROPOSAL_TRUSTEE_ROLE");
  bytes32 public constant STAKING_TRUSTEE_ROLE = keccak256("STAKING_TRUSTEE_ROLE");
  bytes32 public constant FUNDRAISER_TRUSTEE_ROLE = keccak256("FUNDRAISER_TRUSTEE_ROLE");
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

import { RequestSignature } from "../IMoonpassContract.sol";

interface IMoonpassTokenDistribution
{
  function committed() external view returns(bool isCommitted);

  function available() external view returns(uint256 percentage);

  function availableAt(uint256 timestamp) external view returns(uint256 percentage);

  function balance() external view returns(uint256 amount);

  function requiredBalance() external view returns(uint256 amount);

  function requiredBalanceAt(uint256 timestamp) external view returns(uint256 amount);

  function commitment() external view returns(bool isCommitted, uint256 depositsAmount, uint256 withdrawalsAmount, uint256 balanceAmount, uint256 requiredBalanceAmount);

  function deposits() external view returns(uint256 count, uint256 amount);

  function withdrawals() external view returns(uint256 count, uint256 amount);

  function name() external view returns(string memory distributionName);

  function setName(SetNameRequest calldata request, RequestSignature calldata signature) external;

  function setName(string calldata distributionName) external;

  function token() external view returns(address tokenAddress);

  function setToken(SetTokenRequest calldata request, RequestSignature calldata signature) external;

  function setToken(address tokenAddress) external;

  function setVestings(SetVestingsRequest calldata request, RequestSignature calldata signature) external;

  function setVestings(uint256[] calldata vestingsData) external;

  function commit(RequestSignature calldata signature) external;

  function commit() external;

  function vestings() external view returns(VestingSchedule[] memory schedules);

  function clawback(ClawbackRequest calldata request, RequestSignature calldata signature) external;

  function clawback(address to) external;

  event DistributionClawback(address indexed to);
  event DistributionCommit();
  event DistributionVestingsChange(uint256[] indexed vestings);
  event DistributionTokenChange(address indexed tokenAddress);
  event DistributionNameChange();

  error InvalidVestingError(uint256 index);
  error InvalidVestingsError();
  error MissingAllocationsError();
  error DistributionIsCommittedError();
  error DistributionNotCommittedError();
  error NoBalanceToClawbackError();
  error DepositsFoundError();
}

struct TokenDistributionInitializer {
  string name;
  address tokenAddress;
}

struct ClawbackRequest {
  address to;
}

struct SetTokenRequest {
  address tokenAddress;
}

struct SetNameRequest {
  string name;
}

struct SetVestingsRequest {
  uint256[] vestingsData;
}

struct VestingSchedule {
  uint256 start;
  uint256 end;
  uint256 percentage;
}

// SPDX-License-Identifier: Proprietary
/**

  Moonpass Token Management Platform. All rights reserved.
  
  Access https://moonpass.io to learn more.

*/

pragma solidity ^0.8.18;

import { IMoonpassContract, MoonpassInitializer, SetAuthorizerRequest, RequestSignature } from "./interfaces/IMoonpassContract.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MoonpassRoles } from "./auth/MoonpassRoles.sol";

contract MoonpassContract is
  IMoonpassContract,
  OwnableUpgradeable,
  PausableUpgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable
{
  using ECDSA for bytes32;
  using ERC165Checker for address;

  bytes32 public constant SET_AUTHORIZER_TYPEHASH = keccak256("SetAuthorizerRequest(address authorizerAddress,RequestContext context)RequestContext(address requester,uint256 expiry,uint256 nonce)");
  bytes32 public constant CONTEXT_TYPEHASH = 0x08c0db72018bde0ea5215618bdbdfe278d6c1fae34ae3cfa2ef60ce156906175;

  struct MoonpassContractStorage {
    address _authorizer;
  }

  bytes32 private constant MoonpassContractStorageLocation = 0xcf1e3c2eec56b7a457652c54121209bbbd2922d418d6ab903c014713a5d410e2;

  function _getMoonpassContractStorage()
    private
    pure 
    returns (MoonpassContractStorage storage $) 
  {
    assembly {
      $.slot := MoonpassContractStorageLocation
    }
  }

  function __Moonpass_init(
    MoonpassInitializer calldata data
  )
    internal
    onlyInitializing
  {
    __Pausable_init();
    __EIP712_init("moonpass", "1.1");
    __Ownable_init(data.owner);
    __UUPSUpgradeable_init();
    _setAuthorizer(data.authorizer);
  }

  function setAuthorizer(
    address authorizerAddress
  )
    external
    onlyRole(MoonpassRoles.AUTH_MANAGER_ROLE)
  {
    _setAuthorizer(authorizerAddress);
  }

  function setAuthorizer(
    SetAuthorizerRequest calldata request,
    RequestSignature calldata signature
  ) 
    external
  {
    bytes memory data = abi.encode(
      SET_AUTHORIZER_TYPEHASH,
      request.authorizerAddress,
      _encodeContext(signature)
    );
    _checkRole(MoonpassRoles.AUTH_MANAGER_ROLE, _signerFrom(data, signature));

    _setAuthorizer(request.authorizerAddress);
  }

  function version()
    external 
    view 
    returns (uint64)
  {
    return _getInitializedVersion();
  }

  function _encodeContext(
    RequestSignature calldata signature
  )
    internal
    view
    returns(
      bytes32 hashed
    )
  {
    _checkContext(signature);
    hashed = keccak256(
      abi.encode(
        CONTEXT_TYPEHASH,
        _msgSender(),
        signature.expiry,
        signature.nonce
      )
    );
  }

  function _checkContext(
    RequestSignature calldata signature
  )
    internal
    virtual
    view
  {
    // Nonce check is optional for child implentations
    if(signature.expiry < block.timestamp) {
      revert InvalidRequestError();
    }
  }

  function _signerFrom(
    bytes memory data,
    RequestSignature calldata signature
  )
    internal
    view
    returns(
      address signer
    )
  {
    return _hashTypedDataV4(keccak256(data)).recover(signature.v, signature.r, signature.s);
  }

  function pause() 
    public
    onlyRole(MoonpassRoles.PAUSER_ROLE)
  {
    _pause();
  }

  function unpause()
    public
    onlyRole(MoonpassRoles.PAUSER_ROLE)
  {
    _unpause();
  }

  function authorizer()
    public
    view
    returns(address authorizerAddress)
  {
    MoonpassContractStorage storage $ = _getMoonpassContractStorage();
    authorizerAddress = $._authorizer;
  }

  function _hasRole(
    bytes32 role
  )
    internal
    view
    returns (bool)
  {
    return _hasRole(role, _msgSender());
  }

  function _hasRole(
    bytes32 role,
    address account
  )
    internal
    view
    returns (bool)
  {
    return IAccessControl(authorizer()).hasRole(role, account);
  }

  function _checkRole(
    bytes32 role
  )
    internal
    view
  {
    _checkRole(role, _msgSender());
  }

  function _checkRole(
    bytes32 role,
    address account
  )
    internal
    view
  {
    if(!_hasRole(role, account)) {
      revert IAccessControl.AccessControlUnauthorizedAccount(account, role);
    }
  }

  function _setAuthorizer(
    address authorizerAddress
  )
    internal
  {
    if(!authorizerAddress.supportsInterface(type(IAccessControl).interfaceId)) {
      revert InvalidAddressError();
    }
    MoonpassContractStorage storage $ = _getMoonpassContractStorage();
    $._authorizer = authorizerAddress;

    emit AuthorizerChange(authorizerAddress);
  }

  function _authorizeUpgrade(
    address newImplementation
  )
    internal
    override
  {
    // Recover from bad upgrades
    if(authorizer() == address(0)) {
      return;
    }
    _checkRole(MoonpassRoles.UPGRADER_ROLE);
  }

  modifier onlyRole(
    bytes32 role
  )
  {
    _checkRole(role);
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.20;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 */
abstract contract EIP712Upgradeable is Initializable, IERC5267 {
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @custom:storage-location erc7201:openzeppelin.storage.EIP712
    struct EIP712Storage {
        /// @custom:oz-renamed-from _HASHED_NAME
        bytes32 _hashedName;
        /// @custom:oz-renamed-from _HASHED_VERSION
        bytes32 _hashedVersion;

        string _name;
        string _version;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.EIP712")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EIP712StorageLocation = 0xa16a46d94261c7517cc8ff89f61c0ce93598e3c849801011dee649a6a557d100;

    function _getEIP712Storage() private pure returns (EIP712Storage storage $) {
        assembly {
            $.slot := EIP712StorageLocation
        }
    }

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        EIP712Storage storage $ = _getEIP712Storage();
        $._name = name;
        $._version = version;

        // Reset prior values in storage if upgrading
        $._hashedName = 0;
        $._hashedVersion = 0;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        EIP712Storage storage $ = _getEIP712Storage();
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        require($._hashedName == 0 && $._hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal view virtual returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal view virtual returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = $._hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = $._hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeCall(IERC165.supportsInterface, (interfaceId));

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.20;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}