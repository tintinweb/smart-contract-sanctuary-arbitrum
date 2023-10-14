// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './CoordSet.sol';
import './CellMap.sol';
import './CellMath.sol';
import './ExpandableMap.sol';
import './Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

struct BuyRequest {
    // Pixel coords are packed into uint32 for efficiency
    uint32 cell;
    address owner;
    uint8 color;
}

contract ArbitrumLife is
    Ownable,
    CoordSet,
    CellMap,
    ExpandableMap,
    ReentrancyGuard
{
    // Tax for reselling or repainting that goes to the dev
    uint8 private immutable resellTaxToDev = 1; // percentage
    // Tax for reselling that goes to the previous owner (on top of 100% of
    // their initial deposit).
    uint8 private immutable resellTaxToOwner = 9; // percentage
    // pre-computed values for exponentially increasing price,
    // set in the contract constructor.
    uint256[256] private _prices;

    // Anyone can listen for the following events or use eth_getLogs to
    // reconstruct the entire history. Note that color values are not stored in
    // the contract, because they do not matter for the economic side of things.
    // Colors only persists in logs.

    // New cell bought for base price
    event NewCellBought(uint32 cell, address owner, uint8 color);
    // Cell repainted by its owner
    event CellRepainted(uint32 cell, address owner, uint8 color);
    // Cell repainted by another user
    event CellResold(
        uint32 cell,
        address oldOwner,
        address newOwner,
        uint8 color
    );

    constructor(
        uint256 basePrice,
        address developer,
        uint32 unlockedMapSize,
        uint16 mapUnlockStep,
        uint8 mapUnlockPercentage
    )
        ExpandableMap(unlockedMapSize, mapUnlockStep, mapUnlockPercentage)
        Ownable(developer)
    {
        // Precompute prices exponentially increasing with each resell
        uint256 priceAccum = basePrice;
        uint256 totalPercentage = 100 + resellTaxToDev + resellTaxToOwner;
        for (uint i = 0; i < 256; ++i) {
            _prices[i] = priceAccum;
            priceAccum = (priceAccum * totalPercentage) / 100;
        }
    }

    // Withdraw function for developer
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Compute the total price without buying. Used by the app to give a price
    // estimate before the user buys
    function estimateCells(
        BuyRequest[] calldata reqs
    ) public view returns (uint256 price) {
        uint reqsLength = reqs.length;
        uint total = 0;

        for (uint i = 0; i < reqsLength; i++) {
            (uint toOwner, , uint toDeveloper, , ) = estimateRequest(reqs[i]);
            total += toDeveloper + toOwner;
        }

        return total;
    }

    // The main function of the contract the users interact with.
    function buyCells(
        BuyRequest[] calldata reqs
    ) external payable nonReentrant {
        uint reqsLength = reqs.length;
        uint toDeveloperTotal = 0;
        uint toOwnersTotal = 0;
        uint32 newPixelCount = 0;

        for (uint i = 0; i < reqsLength; i++) {
            BuyRequest calldata req = reqs[i];
            (
                uint toOwner,
                address cellOwner,
                uint toDeveloper,
                uint8 resells,
                bool alreadyBought
            ) = estimateRequest(req);

            toDeveloperTotal += toDeveloper;
            toOwnersTotal += toOwner;

            if (alreadyBought) {
                // Cell is already owned
                if (msg.sender == req.owner) {
                    // if *we* own this cell
                    // We don't need to update address map, because ownership is
                    // not going to be changed
                    emit CellRepainted(req.cell, msg.sender, req.color);
                } else {
                    // if someone else owns this cell
                    // Nullify old owner's ownership of the cell
                    _set(req.owner, req.cell, 0);
                    // Set ourselves as the cell owner
                    _set(msg.sender, req.cell, resells);
                    payable(cellOwner).transfer(toOwner);
                    emit CellResold(req.cell, req.owner, msg.sender, req.color);
                }
            } else {
                // first buy
                {
                    (uint16 y, uint16 x) = cellToCoords(req.cell);
                    _setCoords(y, x);
                }
                _set(msg.sender, req.cell, 1);
                newPixelCount++;
                emit NewCellBought(req.cell, msg.sender, req.color);
            }
        }

        require(
            msg.value == toDeveloperTotal + toOwnersTotal,
            'Amount does not match'
        );

        paintNewPixels(newPixelCount);
    }

    function getResellPrice(uint8 resells) public view returns (uint256) {
        return _prices[resells];
    }

    function estimateRequest(
        BuyRequest calldata req
    )
        private
        view
        returns (
            uint toOwner,
            address owner,
            uint toDeveloper,
            uint8 resells,
            bool alreadyBought
        )
    {
        require(req.color != 0, 'Color code must be in range [1,255]');

        {
            (uint16 y, uint16 x) = cellToCoords(req.cell);
            require(isUnlocked(y, x), 'The pixel is not within unlocked area');
            alreadyBought = getCoords(y, x);
        }

        if (alreadyBought) {
            // This cell is already colored.
            uint8 soldTimes = lookup(req.owner, req.cell);

            require(
                soldTimes != 0,
                'Wrong address provided - cell ownership has changed'
            );

            if (msg.sender == req.owner) {
                // we own this cell
                // we only pay developer tax, cell resells is untouched.
                toDeveloper =
                    (getResellPrice(soldTimes) * resellTaxToDev) /
                    100;
                // We return the old resells without updating
                resells = soldTimes;
            } else {
                // Someone else owns this cell.
                // We must pay to the previous owner.
                if (soldTimes != 255) {
                    resells = soldTimes + 1;
                } else {
                    resells = soldTimes;
                }

                owner = req.owner;
                uint256 price = getResellPrice(soldTimes);

                toDeveloper = (price * resellTaxToDev) / 100;
                toOwner = price - toDeveloper;
            }
        } else {
            // This cell is not colored. Pay base price.
            toDeveloper += _prices[0];
        }

        return (toOwner, owner, toDeveloper, resells, alreadyBought);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address, address);

    constructor(address ownerAddr) {
        _owner = ownerAddr;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, 'Caller is not the owner.');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (_owner != newOwner) {
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** This contract implements world expansion and boundary checks for new pixels
 */
contract ExpandableMap {
    uint32 private _unlockedMapSize;
    uint16 private immutable _mapUnlockStep;
    uint8 private immutable _mapUnlockPercentage;
    uint64 private _paintedPixels = 0;

    event WorldExpanded(uint32 size);

    constructor(
        uint32 unlockedMapSize,
        uint16 mapUnlockStep,
        uint8 mapUnlockPercentage
    ) {
        _unlockedMapSize = unlockedMapSize;
        _mapUnlockStep = mapUnlockStep;
        _mapUnlockPercentage = mapUnlockPercentage;
    }

    function isUnlocked(
        uint16 y,
        uint16 x
    ) public view returns (bool unlocked) {
        uint256 upperBound = 2 ** 15 + _unlockedMapSize / 2;
        uint256 lowerBound = 2 ** 15 - _unlockedMapSize / 2;
        return (y < upperBound &&
            y >= lowerBound &&
            x < upperBound &&
            x >= lowerBound);
    }

    // Expand the unlocked area if _mapUnlockPercentage of unlocked pixels are
    // already painted.
    function expandIfNeeded() private {
        uint256 currentSize = uint256(_unlockedMapSize) ** 2;
        if (
            uint256(_paintedPixels) >=
            (currentSize * _mapUnlockPercentage) / 100
        ) {
            unchecked {
                bool noOverflow = _unlockedMapSize + _mapUnlockStep >
                    _unlockedMapSize;
                if (noOverflow) {
                    _unlockedMapSize += _mapUnlockStep;
                    emit WorldExpanded(_unlockedMapSize);
                }
            }
        }
    }

    // Add a number of pixels to the counter
    function paintNewPixels(uint32 newPixelCount) internal {
        unchecked {
            if (_paintedPixels + newPixelCount <= type(uint32).max) {
                _paintedPixels += newPixelCount;
                expandIfNeeded();
            }
        }
    }

    function getUnlockedWorldSize() public view returns (uint32) {
        return _unlockedMapSize;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** This contract implements a specialized (x, y) => bool mapping that uses
    storage optimally (1 bit per cell).
 */
contract CoordSet {
    uint8 public immutable CHUNK_SIZE = 4;

    mapping(uint32 => uint256) private owners;

    // Close cells are likely to be in the same chunk
    function coordsToChunk(
        uint16 y,
        uint16 x
    ) public pure returns (uint32 chunk, uint8 offsetBits) {
        return (
            (uint32(y / CHUNK_SIZE) << 16) | uint32(x / CHUNK_SIZE),
            // calculate offset in bits relative to chunk start.
            (uint8(y % CHUNK_SIZE) * CHUNK_SIZE + uint8(x % CHUNK_SIZE)) << 3
        );
    }

    function _setCoords(uint16 y, uint16 x) internal {
        (uint32 chunk, uint8 offsetBits) = coordsToChunk(y, x);
        owners[chunk] = owners[chunk] | (1 << offsetBits);
    }

    function getCoords(uint16 y, uint16 x) public view returns (bool) {
        (uint32 chunk, uint8 offsetBits) = coordsToChunk(y, x);
        uint256 bitmap = owners[chunk];
        return (bitmap >> offsetBits) & 1 == 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CellMath {
    function coordsToCell(
        uint16 y,
        uint16 x
    ) public pure returns (uint32 cell) {
        return (uint32(y) << 16) + x;
    }

    function cellToCoords(
        uint32 cell
    ) public pure returns (uint16 y, uint16 x) {
        return (uint16(cell >> 16), uint16(cell));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './CellMath.sol';

/** This contract implements a lookup table for (address x chunk) keys that are
    packed together in a `uint256`.

    coords conversion to chunk IDs is implemented with locality in mind (close
    coordinates are more likely to have the same chunk ID), which helps reduce
    the average cost for painting a large number of cells located closely.

    Lookups return a uint8 value, which means that each lookup key contains
    256/8 = 32 tightly packed `resells` values.
    That's why chunks are of size 4 x 8 = 32.
 */
contract CellMap is CellMath {
    mapping(uint256 => uint256) private _m;

    function toKey(
        address addr,
        uint32 chunk
    ) public pure returns (uint256 key) {
        return (uint256(chunk) << 160) | uint256(uint160(addr));
    }

    function chunkOf(
        uint16 y,
        uint16 x
    ) public pure returns (uint32 chunk, uint8 offsetBits) {
        return (
            // first 16 bits occupied by Y coord of the chunk,
            // second 16 bits occupied by X coord of the chunk
            // equivalent to a tuple (y / 8, x / 4) packed into a single uint32
            (uint32(y >> 3) << 16) | uint32(x >> 2),
            // Find bit offset that corresponds to the coordinates.
            // Since we are dealing with rectangular chunks, coords of
            // (y, x) cell relative to the chunk will be
            //
            //      (yRel, xRel) = (y % WIDTH, x % HEIGHT).
            //
            // So, the absolute bit shift must be (yRel * WIDTH + xRel) * 8.
            (uint8(y % 8) * 4 + uint8(x % 4)) * 8
        );
    }

    function _set(address addr, uint32 cell, uint8 resells) internal {
        (uint16 y, uint16 x) = cellToCoords(cell);
        (uint32 chunk, uint8 offsetBits) = chunkOf(y, x);
        uint256 key = toKey(addr, chunk);
        // mask contains 1s everywhere except of bits we want to update
        uint256 mask = type(uint256).max ^ (0xFF << offsetBits);
        _m[key] = (// overwrite target bits with bits from `resells`
        (uint256(resells) << offsetBits) |
            // overwrite 8 target bits with 0s
            (_m[key] & mask));
    }

    function lookup(
        address addr,
        uint32 cell
    ) public view returns (uint8 resells) {
        (uint16 y, uint16 x) = cellToCoords(cell);
        (uint32 chunk, uint8 offsetBits) = chunkOf(y, x);
        return uint8(_m[toKey(addr, chunk)] >> offsetBits);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}