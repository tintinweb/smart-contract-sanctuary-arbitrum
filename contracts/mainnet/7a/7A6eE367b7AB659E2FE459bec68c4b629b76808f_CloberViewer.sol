// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberMarketFactoryV1.sol";
import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberPriceBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./interfaces/CloberOrderNFTDeployer.sol";
import "./PriceBook.sol";

contract CloberViewer is PriceBook {
    struct DepthInfo {
        uint256 price;
        uint256 priceIndex;
        uint256 quoteAmount;
        uint256 baseAmount;
    }

    struct OrderBookElement {
        uint256 price;
        uint256 amount;
    }

    uint16 private constant _DEFAULT_EXPLORATION_INDEX_COUNT = 256;

    CloberMarketFactory private immutable _factory;
    CloberMarketFactoryV1 private immutable _factoryV1;
    CloberOrderNFTDeployer private immutable _orderNFTDeployer;
    uint256 private immutable _cachedChainId;
    uint256 private immutable _v1PoolCount;

    uint128 private constant VOLATILE_A = 10000000000;
    uint128 private constant VOLATILE_R = 1001000000000000000;

    constructor(
        address factory,
        address factoryV1,
        uint256 cachedChainId,
        uint256 v1PoolCount
    ) PriceBook(VOLATILE_A, VOLATILE_R) {
        require(factory != address(0) || factoryV1 != address(0));
        _factory = CloberMarketFactory(factory);
        _factoryV1 = CloberMarketFactoryV1(factoryV1);
        _orderNFTDeployer = factory == address(0)
            ? CloberOrderNFTDeployer(address(0))
            : CloberOrderNFTDeployer(_factory.orderTokenDeployer());
        _cachedChainId = cachedChainId;
        if (factoryV1 == address(0)) v1PoolCount = 0;
        _v1PoolCount = v1PoolCount;
    }

    function getAllMarkets() external view returns (address[] memory markets) {
        unchecked {
            uint256 length;
            if (address(_factory) == address(0)) {
                length = _factoryV1.nonce();
                markets = new address[](length);
                for (uint256 i = 0; i < length; ++i) {
                    markets[i] = CloberOrderNFT(_factoryV1.computeTokenAddress(i)).market();
                }
            } else {
                length = _factory.nonce() + _v1PoolCount;

                markets = new address[](length);
                for (uint256 i = 0; i < _v1PoolCount; ++i) {
                    markets[i] = CloberOrderNFT(_factoryV1.computeTokenAddress(i)).market();
                }

                for (uint256 i = _v1PoolCount; i < length; ++i) {
                    bytes32 salt = keccak256(abi.encode(_cachedChainId, i - _v1PoolCount));
                    markets[i] = CloberOrderNFT(_orderNFTDeployer.computeTokenAddress(salt)).market();
                }
            }
        }
    }

    function getDepths(address market, bool isBidSide) external view returns (OrderBookElement[] memory) {
        return getDepths(market, isBidSide, _DEFAULT_EXPLORATION_INDEX_COUNT);
    }

    function getDepths(
        address market,
        bool isBidSide,
        uint16 explorationIndexCount
    ) public view returns (OrderBookElement[] memory elements) {
        unchecked {
            uint256 fromIndex = CloberOrderBook(market).bestPriceIndex(isBidSide);
            uint256 maxIndex = CloberPriceBook(CloberOrderBook(market).priceBook()).maxPriceIndex();
            OrderBookElement[] memory _elements = new OrderBookElement[](explorationIndexCount);
            uint256 count = 0;

            if (isBidSide) {
                uint16 toIndex = fromIndex > explorationIndexCount ? uint16(fromIndex) - explorationIndexCount : 0;
                for (uint16 index = uint16(fromIndex); index > toIndex; --index) {
                    uint256 i = fromIndex - index;
                    uint64 rawAmount = CloberOrderBook(market).getDepth(true, index);
                    if (rawAmount == 0) {
                        continue;
                    }
                    _elements[i].price = CloberOrderBook(market).indexToPrice(index);
                    _elements[i].amount = CloberOrderBook(market).rawToQuote(rawAmount);
                    ++count;
                }
            } else {
                // fromIndex + explorationIndexCount <= 2 * type(uint16).max, so it is safe from the overflow
                uint256 toIndex = fromIndex + explorationIndexCount > maxIndex
                    ? maxIndex
                    : fromIndex + explorationIndexCount;
                for (uint256 index = fromIndex; index < toIndex; ++index) {
                    uint256 i = index - fromIndex;
                    uint64 rawAmount = CloberOrderBook(market).getDepth(false, uint16(index));
                    if (rawAmount == 0) {
                        continue;
                    }
                    _elements[i].price = CloberOrderBook(market).indexToPrice(uint16(index));
                    _elements[i].amount = CloberOrderBook(market).rawToBase(rawAmount, uint16(index), false);
                    ++count;
                }
            }
            elements = new OrderBookElement[](count);
            count = 0;
            for (uint256 i = 0; i < _elements.length; ++i) {
                if (_elements[i].price != 0) {
                    elements[count] = _elements[i];
                    ++count;
                }
            }
        }
    }

    function getDepthsByPriceIndex(
        address market,
        bool isBid,
        uint16 fromIndex,
        uint16 toIndex
    ) public view returns (DepthInfo[] memory depths) {
        depths = new DepthInfo[](toIndex - fromIndex + 1);

        unchecked {
            for (uint16 index = fromIndex; index <= toIndex; ++index) {
                uint256 i = index - fromIndex;
                uint64 rawAmount = CloberOrderBook(market).getDepth(isBid, index);
                depths[i].price = CloberOrderBook(market).indexToPrice(index);
                depths[i].priceIndex = index;
                depths[i].quoteAmount = CloberOrderBook(market).rawToQuote(rawAmount);
                depths[i].baseAmount = CloberOrderBook(market).rawToBase(rawAmount, index, false);
            }
        }
    }

    function getDepthsByPrice(
        address market,
        bool isBid,
        uint256 fromPrice,
        uint256 toPrice
    ) external view returns (DepthInfo[] memory) {
        uint16 fromIndex;
        uint16 toIndex;
        CloberMarketFactoryV1.MarketInfo memory marketInfo;
        if (address(_factoryV1) != address(0)) marketInfo = _factoryV1.getMarketInfo(market);
        if (marketInfo.marketType == CloberMarketFactoryV1.MarketType.NONE) {
            (fromIndex, ) = CloberOrderBook(market).priceToIndex(fromPrice, true);
            (toIndex, ) = CloberOrderBook(market).priceToIndex(toPrice, false);
        } else if (marketInfo.marketType == CloberMarketFactoryV1.MarketType.VOLATILE) {
            require((marketInfo.a == VOLATILE_A) && (marketInfo.factor == VOLATILE_R));
            fromIndex = _volatilePriceToIndex(fromPrice, true);
            toIndex = _volatilePriceToIndex(toPrice, false);
        } else {
            fromIndex = _stablePriceToIndex(marketInfo.a, marketInfo.factor, fromPrice, true);
            toIndex = _stablePriceToIndex(marketInfo.a, marketInfo.factor, toPrice, false);
        }

        return getDepthsByPriceIndex(market, isBid, fromIndex, toIndex);
    }
}

// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

contract PriceBook {
    uint256 private immutable _a;
    uint256 private immutable _r0;
    uint256 private immutable _r1;
    uint256 private immutable _r2;
    uint256 private immutable _r3;
    uint256 private immutable _r4;
    uint256 private immutable _r5;
    uint256 private immutable _r6;
    uint256 private immutable _r7;
    uint256 private immutable _r8;
    uint256 private immutable _r9;
    uint256 private immutable _r10;
    uint256 private immutable _r11;
    uint256 private immutable _r12;
    uint256 private immutable _r13;
    uint256 private immutable _r14;
    uint256 private immutable _r15;
    uint256 private immutable _r16;

    uint16 public immutable maxPriceIndex;
    uint256 public immutable priceUpperBound;

    constructor(uint128 a_, uint128 r_) {
        uint256 castedR = uint256(r_);
        _a = a_;
        // precision of `_r0~16` is 2^64
        _r0 = (castedR << 64) / 10**18;
        // when `r_` <= 1
        if ((a_ * _r0) >> 64 <= a_) {
            revert("INVALID_COEFFICIENTS");
        }
        uint16 maxIndex_;
        uint256 maxPrice_ = 1 << 64;

        uint256 r;
        if (_r0 < type(uint256).max / _r0) {
            r = (_r0 * _r0) >> 64;
            maxIndex_ = maxIndex_ | 0x1;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r1 = r;

        if (_r1 < type(uint256).max / _r1) {
            r = (_r1 * _r1) >> 64;
            maxIndex_ = maxIndex_ | 0x2;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r2 = r;

        if (_r2 < type(uint256).max / _r2) {
            r = (_r2 * _r2) >> 64;
            maxIndex_ = maxIndex_ | 0x4;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r3 = r;

        if (_r3 < type(uint256).max / _r3) {
            r = (_r3 * _r3) >> 64;
            maxIndex_ = maxIndex_ | 0x8;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r4 = r;

        if (_r4 < type(uint256).max / _r4) {
            r = (_r4 * _r4) >> 64;
            maxIndex_ = maxIndex_ | 0x10;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r5 = r;

        if (_r5 < type(uint256).max / _r5) {
            r = (_r5 * _r5) >> 64;
            maxIndex_ = maxIndex_ | 0x20;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r6 = r;

        if (_r6 < type(uint256).max / _r6) {
            r = (_r6 * _r6) >> 64;
            maxIndex_ = maxIndex_ | 0x40;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r7 = r;

        if (_r7 < type(uint256).max / _r7) {
            r = (_r7 * _r7) >> 64;
            maxIndex_ = maxIndex_ | 0x80;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r8 = r;

        if (_r8 < type(uint256).max / _r8) {
            r = (_r8 * _r8) >> 64;
            maxIndex_ = maxIndex_ | 0x100;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r9 = r;

        if (_r9 < type(uint256).max / _r9) {
            r = (_r9 * _r9) >> 64;
            maxIndex_ = maxIndex_ | 0x200;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r10 = r;

        if (_r10 < type(uint256).max / _r10) {
            r = (_r10 * _r10) >> 64;
            maxIndex_ = maxIndex_ | 0x400;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r11 = r;

        if (_r11 < type(uint256).max / _r11) {
            r = (_r11 * _r11) >> 64;
            maxIndex_ = maxIndex_ | 0x800;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r12 = r;

        if (_r12 < type(uint256).max / _r12) {
            r = (_r12 * _r12) >> 64;
            maxIndex_ = maxIndex_ | 0x1000;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r13 = r;

        if (_r13 < type(uint256).max / _r13) {
            r = (_r13 * _r13) >> 64;
            maxIndex_ = maxIndex_ | 0x2000;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r14 = r;

        if (_r14 < type(uint256).max / _r14) {
            r = (_r14 * _r14) >> 64;
            maxIndex_ = maxIndex_ | 0x4000;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r15 = r;

        if (_r15 < type(uint256).max / _r15) {
            r = (_r15 * _r15) >> 64;
            maxIndex_ = maxIndex_ | 0x8000;
            maxPrice_ = r;
        } else {
            r = type(uint256).max;
        }
        _r16 = r;

        maxPriceIndex = maxIndex_;
        priceUpperBound = (maxPrice_ >> 64) * a_ + (((maxPrice_ & 0xffffffffffffffff) * a_) >> 64);
    }

    function _volatilePriceToIndex(uint256 price, bool roundingUp) internal view returns (uint16 index) {
        if (price < _a || price >= priceUpperBound) {
            revert("INVALID_PRICE");
        }
        index = 0;
        uint256 _correctedPrice = _a;
        uint256 shiftedPrice = (price + 1) << 64;

        unchecked {
            if (maxPriceIndex > 0x8000 && shiftedPrice > _r15 * _correctedPrice) {
                index = index | 0x8000;
                _correctedPrice = (_correctedPrice * _r15) >> 64;
            }
            if (maxPriceIndex > 0x4000 && shiftedPrice > _r14 * _correctedPrice) {
                index = index | 0x4000;
                _correctedPrice = (_correctedPrice * _r14) >> 64;
            }
            if (maxPriceIndex > 0x2000 && shiftedPrice > _r13 * _correctedPrice) {
                index = index | 0x2000;
                _correctedPrice = (_correctedPrice * _r13) >> 64;
            }
            if (maxPriceIndex > 0x1000 && shiftedPrice > _r12 * _correctedPrice) {
                index = index | 0x1000;
                _correctedPrice = (_correctedPrice * _r12) >> 64;
            }
            if (maxPriceIndex > 0x800 && shiftedPrice > _r11 * _correctedPrice) {
                index = index | 0x0800;
                _correctedPrice = (_correctedPrice * _r11) >> 64;
            }
            if (maxPriceIndex > 0x400 && shiftedPrice > _r10 * _correctedPrice) {
                index = index | 0x0400;
                _correctedPrice = (_correctedPrice * _r10) >> 64;
            }
            if (maxPriceIndex > 0x200 && shiftedPrice > _r9 * _correctedPrice) {
                index = index | 0x0200;
                _correctedPrice = (_correctedPrice * _r9) >> 64;
            }
            if (maxPriceIndex > 0x100 && shiftedPrice > _r8 * _correctedPrice) {
                index = index | 0x0100;
                _correctedPrice = (_correctedPrice * _r8) >> 64;
            }
            if (maxPriceIndex > 0x80 && shiftedPrice > _r7 * _correctedPrice) {
                index = index | 0x0080;
                _correctedPrice = (_correctedPrice * _r7) >> 64;
            }
            if (maxPriceIndex > 0x40 && shiftedPrice > _r6 * _correctedPrice) {
                index = index | 0x0040;
                _correctedPrice = (_correctedPrice * _r6) >> 64;
            }
            if (maxPriceIndex > 0x20 && shiftedPrice > _r5 * _correctedPrice) {
                index = index | 0x0020;
                _correctedPrice = (_correctedPrice * _r5) >> 64;
            }
            if (maxPriceIndex > 0x10 && shiftedPrice > _r4 * _correctedPrice) {
                index = index | 0x0010;
                _correctedPrice = (_correctedPrice * _r4) >> 64;
            }
            if (maxPriceIndex > 0x8 && shiftedPrice > _r3 * _correctedPrice) {
                index = index | 0x0008;
                _correctedPrice = (_correctedPrice * _r3) >> 64;
            }
            if (maxPriceIndex > 0x4 && shiftedPrice > _r2 * _correctedPrice) {
                index = index | 0x0004;
                _correctedPrice = (_correctedPrice * _r2) >> 64;
            }
            if (maxPriceIndex > 0x2 && shiftedPrice > _r1 * _correctedPrice) {
                index = index | 0x0002;
                _correctedPrice = (_correctedPrice * _r1) >> 64;
            }
            if (shiftedPrice > _r0 * _correctedPrice) {
                index = index | 0x0001;
                _correctedPrice = (_correctedPrice * _r0) >> 64;
            }
        }
        if (roundingUp && _correctedPrice < price) {
            unchecked {
                if (index >= maxPriceIndex) {
                    revert("INVALID_PRICE");
                }
                index += 1;
            }
        }
    }

    function _stablePriceToIndex(
        uint256 a,
        uint256 d,
        uint256 price,
        bool roundingUp
    ) internal pure returns (uint16 index) {
        if (price < a || price >= a + d * (2**16)) {
            revert("INVALID_PRICE");
        }
        index = uint16((price - a) / d);
        if (roundingUp && (price - a) % d > 0) {
            unchecked {
                if (index == type(uint16).max) {
                    revert("INVALID_PRICE");
                }
                index += 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactory {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the deployed GeometricPriceBook.
     * @return The address of the GeometricPriceBook.
     */
    function deployedGeometricPriceBook(uint128 a, uint128 r) external view returns (address);

    /**
     * @notice Returns the address of the deployed GeometricPriceBook.
     * @return The address of the GeometricPriceBook.
     */
    function deployedArithmeticPriceBook(uint128 a, uint128 d) external view returns (address);

    /**
     * @notice Returns the address of the MarketDeployer.
     * @return The address of the MarketDeployer.
     */
    function marketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the priceBookDeployer.
     * @return The address of the priceBookDeployer.
     */
    function priceBookDeployer() external view returns (address);

    /**
     * @notice Returns the address of the orderTokenDeployer.
     * @return The address of the orderTokenDeployer.
     */
    function orderTokenDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactoryV1 {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the VolatileMarketDeployer.
     * @return The address of the VolatileMarketDeployer.
     */
    function volatileMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the StableMarketDeployer.
     * @return The address of the StableMarketDeployer.
     */
    function stableMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    /**
     * @notice Computes the OrderNFT contract address.
     * @param marketNonce The nonce to compute the OrderNFT contract address via CREATE2.
     */
    function computeTokenAddress(uint256 marketNonce) external view returns (address);

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberOrderBook {
    /**
     * @notice Emitted when an order is created.
     * @param sender The address who sent the tokens to make the order.
     * @param user The address with the rights to claim the proceeds of the order.
     * @param rawAmount The ordered raw amount.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param options LSB: 0 - Ask, 1 - Bid.
     */
    event MakeOrder(
        address indexed sender,
        address indexed user,
        uint64 rawAmount,
        uint32 claimBounty,
        uint256 orderIndex,
        uint16 priceIndex,
        uint8 options
    );

    /**
     * @notice Emitted when an order takes from the order book.
     * @param sender The address who sent the tokens to take the order.
     * @param user The recipient address of the traded token.
     * @param priceIndex The price book index.
     * @param rawAmount The ordered raw amount.
     * @param options MSB: 0 - Limit, 1 - Market / LSB: 0 - Ask, 1 - Bid.
     */
    event TakeOrder(address indexed sender, address indexed user, uint16 priceIndex, uint64 rawAmount, uint8 options);

    /**
     * @notice Emitted when an order is canceled.
     * @param user The owner of the order.
     * @param rawAmount The raw amount remaining that was canceled.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBid The flag indicating whether it's a bid order or an ask order.
     */
    event CancelOrder(address indexed user, uint64 rawAmount, uint256 orderIndex, uint16 priceIndex, bool isBid);

    /**
     * @notice Emitted when the proceeds of an order is claimed.
     * @param claimer The address that initiated the claim.
     * @param user The owner of the order.
     * @param rawAmount The ordered raw amount.
     * @param bountyAmount The size of the claim bounty.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBase The flag indicating whether the user receives the base token or the quote token.
     */
    event ClaimOrder(
        address indexed claimer,
        address indexed user,
        uint64 rawAmount,
        uint256 bountyAmount,
        uint256 orderIndex,
        uint16 priceIndex,
        bool isBase
    );

    /**
     * @notice Emitted when a flash-loan is taken.
     * @param caller The caller address of the flash-loan.
     * @param borrower The address of the flash loan token receiver.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param earnedQuote The amount of quote tokens the protocol earned in quote tokens.
     * @param earnedBase The amount of base tokens the protocol earned in base tokens.
     */
    event Flash(
        address indexed caller,
        address indexed borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 earnedQuote,
        uint256 earnedBase
    );

    /**
     * @notice A struct that represents an order.
     * @param amount The raw amount not filled yet. In case of a stale order, the amount not claimed yet.
     * @param claimBounty The bounty amount in gwei that can be collected by the party that fully claims the order.
     * @param owner The address of the order owner.
     */
    struct Order {
        uint64 amount;
        uint32 claimBounty;
        address owner;
    }

    /**
     * @notice A struct that represents a block trade log.
     * @param blockTime The timestamp of the block.
     * @param askVolume The volume taken on the ask side.
     * @param bidVolume The volume taken on the bid side.
     * @param open The price book index on the open.
     * @param high The highest price book index in the block.
     * @param low The lowest price book index in the block.
     * @param close The price book index on the close.
     */
    struct BlockTradeLog {
        uint64 blockTime;
        uint64 askVolume;
        uint64 bidVolume;
        uint16 open;
        uint16 high;
        uint16 low;
        uint16 close;
    }

    /**
     * @notice Take orders better or equal to the given priceIndex and make an order with the remaining tokens.
     * @dev `msg.value` will be used as the claimBounty.
     * @param user The taker/maker address.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param baseAmount The base token amount to trade, utilized by asks.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - Post only.
     * @param data Custom callback data
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Returns the expected input amount and output amount.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * Bid & expendInput => Used as input amount.
     * Bid & !expendInput => Not used.
     * Ask & expendInput => Not used.
     * Ask & !expendInput => Used as output amount.
     * @param baseAmount The base token amount to trade.
     * Bid & expendInput => Not used.
     * Bid & !expendInput => Used as output amount.
     * Ask & expendInput => Used as input amount.
     * Ask & !expendInput => Not used.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     */
    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256, uint256);

    /**
     * @notice Take opens orders until certain conditions are met.
     * @param user The taker address.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     * @param data Custom callback data.
     */
    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external;

    /**
     * @notice Cancel orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param receiver The address to receive canceled tokens.
     * @param orderKeys The order keys of the orders to cancel.
     */
    function cancel(address receiver, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Claim the proceeds of orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param claimer The address to receive the claim bounties.
     * @param orderKeys The order keys of the orders to claim.
     */
    function claim(address claimer, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Get the claimable proceeds of an order.
     * @param orderKey The order key of the order.
     * @return claimableRawAmount The claimable raw amount.
     * @return claimableAmount The claimable amount after fees.
     * @return feeAmount The maker fee to be paid on claim.
     * @return rebateAmount The rebate to be received on claim.
     */
    function getClaimable(OrderKey calldata orderKey)
        external
        view
        returns (
            uint64 claimableRawAmount,
            uint256 claimableAmount,
            uint256 feeAmount,
            uint256 rebateAmount
        );

    /**
     * @notice Flash loan the tokens in the OrderBook.
     * @param borrower The address to receive the loan.
     * @param quoteAmount The quote token amount to borrow.
     * @param baseAmount The base token amount to borrow.
     * @param data The user's custom callback data.
     */
    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Returns the quote unit amount.
     * @return The amount that one raw amount represent in quote tokens.
     */
    function quoteUnit() external view returns (uint256);

    /**
     * @notice Returns the maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The maker fee. 100 = 1bp.
     */
    function makerFee() external view returns (int24);

    /**
     * @notice Returns the take fee
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The taker fee. 100 = 1bps.
     */
    function takerFee() external view returns (uint24);

    /**
     * @notice Returns the address of the order NFT contract.
     * @return The address of the order NFT contract.
     */
    function orderToken() external view returns (address);

    /**
     * @notice Returns the address of the quote token.
     * @return The address of the quote token.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the address of the base token.
     * @return The address of the base token.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the current total open amount at the given price.
     * @param isBid The flag to choose which side to check the depth for.
     * @param priceIndex The price book index.
     * @return The total open amount.
     */
    function getDepth(bool isBid, uint16 priceIndex) external view returns (uint64);

    /**
     * @notice Returns the fee balance that has not been collected yet.
     * @return quote The current fee balance for the quote token.
     * @return base The current fee balance for the base token.
     */
    function getFeeBalance() external view returns (uint128 quote, uint128 base);

    /**
     * @notice Returns the amount of tokens that can be collected by the host.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the host.
     */
    function uncollectedHostFees(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that can be collected by the dao treasury.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the dao treasury.
     */
    function uncollectedProtocolFees(address token) external view returns (uint256);

    /**
     * @notice Returns whether the order book is empty or not.
     * @param isBid The flag to choose which side to check the emptiness of.
     * @return Whether the order book is empty or not on that side.
     */
    function isEmpty(bool isBid) external view returns (bool);

    /**
     * @notice Returns the order information.
     * @param orderKey The order key of the order.
     * @return The order struct of the given order key.
     */
    function getOrder(OrderKey calldata orderKey) external view returns (Order memory);

    /**
     * @notice Returns the lowest ask price index or the highest bid price index.
     * @param isBid Returns the lowest ask price if false, highest bid price if true.
     * @return The current price index. If the order book is empty, it will revert.
     */
    function bestPriceIndex(bool isBid) external view returns (uint16);

    /**
     * @notice Returns the current block trade log index.
     * @return The current block trade log index.
     */
    function blockTradeLogIndex() external view returns (uint16);

    /**
     * @notice Returns the block trade log for a certain index.
     * @param index The block trade log index used to query the block trade log.
     * @return The queried block trade log.
     */
    function blockTradeLogs(uint16 index) external view returns (BlockTradeLog memory);

    /**
     * @notice Returns the address of the price book.
     * @return The address of the price book.
     */
    function priceBook() external view returns (address);

    /**
     * @notice Converts a raw amount to its corresponding base amount using a given price index.
     * @param rawAmount The raw amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted base amount.
     */
    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint256);

    /**
     * @notice Converts a raw amount to its corresponding quote amount.
     * @param rawAmount The raw amount to be converted.
     * @return The converted quote amount.
     */
    function rawToQuote(uint64 rawAmount) external view returns (uint256);

    /**
     * @notice Converts a base amount to its corresponding raw amount using a given price index.
     * @param baseAmount The base amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint64);

    /**
     * @notice Converts a quote amount to its corresponding raw amount.
     * @param quoteAmount The quote amount to be converted.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function quoteToRaw(uint256 quoteAmount, bool roundingUp) external view returns (uint64);

    /**
     * @notice Collects fees for either the protocol or host.
     * @param token The token address to collect. It should be the quote token or the base token.
     * @param destination The destination address to transfer fees.
     * It should be the dao treasury address or the host address.
     */
    function collectFees(address token, address destination) external;

    /**
     * @notice Change the owner of the order.
     * @dev Only the OrderToken contract can call this function.
     * @param orderKey The order key of the order.
     * @param newOwner The new owner address.
     */
    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external;

    /**
     * @notice Converts the price index into the actual price.
     * @param priceIndex The price book index.
     * @return price The actual price.
     */
    function indexToPrice(uint16 priceIndex) external view returns (uint256);

    /**
     * @notice Returns the price book index closest to the provided price.
     * @param price Provided price.
     * @param roundingUp Determines whether to round up or down.
     * @return index The price book index.
     * @return correctedPrice The actual price for the price book index.
     */
    function priceToIndex(uint256 price, bool roundingUp) external view returns (uint16 index, uint256 correctedPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/**
 * @notice A struct that represents a unique key for an order.
 * @param isBid The flag indicating whether it's a bid order or an ask order.
 * @param priceIndex The price book index.
 * @param orderIndex The order index.
 */
struct OrderKey {
    bool isBid;
    uint16 priceIndex;
    uint256 orderIndex;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./CloberOrderKey.sol";

interface CloberOrderNFT is IERC721, IERC721Metadata {
    /**
     * @notice Returns the base URI for the metadata of this NFT collection.
     * @return The base URI for the metadata of this NFT collection.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the contract URI for the metadata of this NFT collection.
     * @return The contract URI for the metadata of this NFT collection.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the address of the market contract that manages this token.
     * @return The address of the market contract that manages this token.
     */
    function market() external view returns (address);

    /**
     * @notice Returns the address of contract owner.
     * @return The address of the contract owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Called when a new token is minted.
     * @param to The receiver address of the minted token.
     * @param tokenId The id of the token minted.
     */
    function onMint(address to, uint256 tokenId) external;

    /**
     * @notice Called when a token is burned.
     * @param tokenId The id of the token burned.
     */
    function onBurn(uint256 tokenId) external;

    /**
     * @notice Changes the base URI for the metadata of this NFT collection.
     * @param newBaseURI The new base URI for the metadata of this NFT collection.
     */
    function changeBaseURI(string memory newBaseURI) external;

    /**
     * @notice Changes the contract URI for the metadata of this NFT collection.
     * @param newContractURI The new contract URI for the metadata of this NFT collection.
     */
    function changeContractURI(string memory newContractURI) external;

    /**
     * @notice Decodes a token id into an order key.
     * @param id The id to decode.
     * @return The order key corresponding to the given id.
     */
    function decodeId(uint256 id) external pure returns (OrderKey memory);

    /**
     * @notice Encodes an order key to a token id.
     * @param orderKey The order key to encode.
     * @return The id corresponding to the given order key.
     */
    function encodeId(OrderKey memory orderKey) external pure returns (uint256);

    /**
     * @notice Cancels orders with token ids.
     * @dev Only the OrderCanceler can call this function.
     * @param from The address of the owner of the tokens.
     * @param tokenIds The ids of the tokens to cancel.
     * @param receiver The address to send the underlying assets to.
     */
    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberOrderNFTDeployer {
    /**
     * @notice Deploys the OrderNFT contract.
     * @param salt The salt to compute the OrderNFT contract address via CREATE2.
     */
    function deploy(bytes32 salt) external returns (address);

    /**
     * @notice Computes the OrderNFT contract address.
     * @param salt The salt to compute the OrderNFT contract address via CREATE2.
     */
    function computeTokenAddress(bytes32 salt) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberPriceBook {
    /**
     * @notice Returns the biggest price book index supported.
     * @return The biggest price book index supported.
     */
    function maxPriceIndex() external view returns (uint16);

    /**
     * @notice Returns the upper bound of prices supported.
     * @dev The price upper bound can be greater than `indexToPrice(maxPriceIndex())`.
     * @return The the upper bound of prices supported.
     */
    function priceUpperBound() external view returns (uint256);

    /**
     * @notice Converts the price index into the actual price.
     * @param priceIndex The price book index.
     * @return price The actual price.
     */
    function indexToPrice(uint16 priceIndex) external view returns (uint256);

    /**
     * @notice Returns the price book index closest to the provided price.
     * @param price Provided price.
     * @param roundingUp Determines whether to round up or down.
     * @return index The price book index.
     * @return correctedPrice The actual price for the price book index.
     */
    function priceToIndex(uint256 price, bool roundingUp) external view returns (uint16 index, uint256 correctedPrice);
}