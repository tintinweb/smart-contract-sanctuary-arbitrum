// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibStructure.sol";


interface IERC721OrdersEvent {

    /// @dev Emitted whenever an `ERC721SellOrder` is filled.
    /// @param orderHash The `ERC721SellOrder` hash.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20TokenAmount The amount of ERC20 token to sell.
    /// @param erc721Token The address of the ERC721 token.
    /// @param erc721TokenId The ID of the ERC721 asset.
    event ERC721SellOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibStructure.Fee[] fees,
        address erc721Token,
        uint256 erc721TokenId
    );

    /// @dev Emitted whenever an `ERC721BuyOrder` is filled.
    /// @param orderHash The `ERC721BuyOrder` hash.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20TokenAmount The amount of ERC20 token to buy.
    /// @param erc721Token The address of the ERC721 token.
    /// @param erc721TokenId The ID of the ERC721 asset.
    event ERC721BuyOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibStructure.Fee[] fees,
        address erc721Token,
        uint256 erc721TokenId
    );

    /// @dev Emitted when an `ERC721SellOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC721SellOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc721Token,
        uint256 erc721TokenId
    );

    /// @dev Emitted when an `ERC721BuyOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC721BuyOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc721Token,
        uint256 erc721TokenId,
        LibNFTOrder.Property[] nftProperties
    );

    /// @dev Emitted whenever an `ERC721Order` is cancelled.
    /// @param maker The maker of the order.
    /// @param nonce The nonce of the order that was cancelled.
    event ERC721OrderCancelled(address maker, uint256 nonce);

    /// @dev Emitted HashNonceIncremented.
    event HashNonceIncremented(address maker, uint256 newHashNonce);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/


pragma solidity ^0.8.17;

import "../libs/LibSignature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibStructure.sol";

interface IMatchOrderFeature {

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    /// @param items [96 bits(erc20TokenAmount) + 160 bits(nftId)].
    struct BasicCollection {
        address nftAddress;
        bytes32 fee;
        bytes32[] items;
    }

    struct OrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    struct Collection {
        address nftAddress;
        bytes32 fee;
        OrderItem[] items;
    }

    /// @param data1 [48 bits(nonce) + 48 bits(startNonce) + 160 bits(maker)]
    /// @param data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(reserved) + 160 bits(erc20Token)]
    /// @param data3 [8 bits(signatureType) + 8 bits(v) + 80 bits(reserved) + 160 bits(platformFeeRecipient)]
    struct SellOrderParam {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
        BasicCollection[] basicCollections;
        Collection[] collections;
    }

    struct BuyOrderParam {
        LibNFTOrder.NFTBuyOrder order;
        LibSignature.Signature signature;
        bytes extraData;
    }

    function matchOrder(
        SellOrderParam calldata sellOrderParam,
        BuyOrderParam calldata buyOrderParam
    ) external returns (uint256 profit);

    function matchOrders(bytes[] calldata datas, bool revertIfIncomplete) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../vendor/IPropertyValidator.sol";


/// @dev A library for common NFT order operations.
library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }

    struct OrderInfoV2 {
        bytes32 structHash;
        bytes32 orderHash;
        OrderStatus status;
        uint128 orderAmount;
        uint128 remainingAmount;
    }

    // The type hash for sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTSellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _NFT_SELL_ORDER_TYPE_HASH = 0xed676c7f3e8232a311454799b1cf26e75b4abc90c9bf06c9f7e8e79fcc7fe14d;

    // The type hash for buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTBuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "Property[] nftProperties,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _NFT_BUY_ORDER_TYPE_HASH = 0xa525d336300f566329800fcbe82fd263226dc27d6c109f060d9a4a364281521c;

    // The type hash for ERC1155 sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155SellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_SELL_ORDER_TYPE_HASH = 0x3529b5920cc48ecbceb24e9c51dccb50fefd8db2cf05d36e356aeb1754e19eda;

    // The type hash for ERC1155 buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155BuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "Property[] erc1155TokenProperties,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_BUY_ORDER_TYPE_HASH = 0x1a6eaae1fbed341e0974212ec17f035a9d419cadc3bf5154841cbf7fd605ba48;

    // keccak256(abi.encodePacked(
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _FEE_TYPE_HASH = 0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    // keccak256(abi.encodePacked(
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _PROPERTY_TYPE_HASH = 0x6292cf854241cb36887e639065eca63b3af9f7f70270cebeda4c29b6d3bc65e8;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(keccak256(abi.encode(
    //    _PROPERTY_TYPE_HASH,
    //    address(0),
    //    keccak256("")
    // ))));
    bytes32 private constant _NULL_PROPERTY_STRUCT_HASH = 0x720ee400a9024f6a49768142c339bf09d2dd9056ab52d20fbe7165faba6e142d;

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    function asNFTSellOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    function asNFTSellOrder(ERC1155SellOrder memory erc1155SellOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := erc1155SellOrder }
    }

    function asNFTSellOrder(ERC1155BuyOrder memory erc1155BuyOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := erc1155BuyOrder }
    }

    function asNFTBuyOrder(ERC1155BuyOrder memory erc1155BuyOrder) internal pure returns (NFTBuyOrder memory order) {
        assembly { order := erc1155BuyOrder }
    }

    function asERC1155SellOrder(NFTSellOrder memory nftSellOrder) internal pure returns (ERC1155SellOrder memory order) {
        assembly { order := nftSellOrder }
    }

    function asERC1155BuyOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (ERC1155BuyOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    // @dev Get the struct hash of an sell order.
    /// @param order The sell order.
    /// @return structHash The struct hash of the order.
    function getNFTSellOrderStructHash(NFTSellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 288) // order + (32 * 9)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 352 /* 32 * 11 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an buy order.
    /// @param order The buy order.
    /// @return structHash The struct hash of the order.
    function getNFTBuyOrderStructHash(NFTBuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.nftProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     propertiesHash,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return structHash The struct hash of the order.
    function getERC1155SellOrderStructHash(ERC1155SellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return structHash The struct hash of the order.
    function getERC1155BuyOrderStructHash(ERC1155BuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.erc1155TokenProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     propertiesHash,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 352) // order + (32 * 11)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 416 /* 32 * 13 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    // Hashes the `properties` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _propertiesHash(Property[] memory properties) private pure returns (bytes32 propertiesHash) {
        uint256 numProperties = properties.length;
        // We give `properties.length == 0` and `properties.length == 1`
        // special treatment because we expect these to be the most common.
        if (numProperties == 0) {
            propertiesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numProperties == 1) {
            Property memory property = properties[0];
            if (address(property.propertyValidator) == address(0) && property.propertyData.length == 0) {
                propertiesHash = _NULL_PROPERTY_STRUCT_HASH;
            } else {
                // propertiesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
                //     _PROPERTY_TYPE_HASH,
                //     properties[0].propertyValidator,
                //     keccak256(properties[0].propertyData)
                // ))));
                bytes32 dataHash = keccak256(property.propertyData);
                assembly {
                    // Load free memory pointer
                    let mem := mload(64)
                    mstore(mem, _PROPERTY_TYPE_HASH)
                    // property.propertyValidator
                    mstore(add(mem, 32), and(ADDRESS_MASK, mload(property)))
                    // keccak256(property.propertyData)
                    mstore(add(mem, 64), dataHash)
                    mstore(mem, keccak256(mem, 96))
                    propertiesHash := keccak256(mem, 32)
                }
            }
        } else {
            bytes32[] memory propertyStructHashArray = new bytes32[](numProperties);
            for (uint256 i = 0; i < numProperties; i++) {
                propertyStructHashArray[i] = keccak256(abi.encode(
                        _PROPERTY_TYPE_HASH, properties[i].propertyValidator, keccak256(properties[i].propertyData)));
            }
            assembly {
                propertiesHash := keccak256(add(propertyStructHashArray, 32), mul(numProperties, 32))
            }
        }
    }

    // Hashes the `fees` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _feesHash(Fee[] memory fees) private pure returns (bytes32 feesHash) {
        uint256 numFees = fees.length;
        // We give `fees.length == 0` and `fees.length == 1`
        // special treatment because we expect these to be the most common.
        if (numFees == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numFees == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPE_HASH,
            //     fees[0].recipient,
            //     fees[0].amount,
            //     keccak256(fees[0].feeData)
            // ))));
            Fee memory fee = fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPE_HASH)
                // fee.recipient
                mstore(add(mem, 32), and(ADDRESS_MASK, mload(fee)))
                // fee.amount
                mstore(add(mem, 64), mload(add(fee, 32)))
                // keccak256(fee.feeData)
                mstore(add(mem, 96), dataHash)
                mstore(mem, keccak256(mem, 128))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](numFees);
            for (uint256 i = 0; i < numFees; i++) {
                feeStructHashArray[i] = keccak256(abi.encode(_FEE_TYPE_HASH, fees[i].recipient, fees[i].amount, keccak256(fees[i].feeData)));
            }
            assembly {
                feesHash := keccak256(add(feeStructHashArray, 32), mul(numFees, 32))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED,
        EIP712_BULK,
        EIP712_1271,
        EIP712_BULK_1271
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library LibStructure {

    uint256 constant ORDER_KIND_DUTCH_AUCTION = 1;
    uint256 constant ORDER_KIND_ENGLISH_AUCTION = 2;
    uint256 constant ORDER_KIND_BATCH_OFFER_ERC721S = 8;

    struct Fee {
        address recipient;
        uint256 amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library LibTypeHash {

    //keccak256(abi.encodePacked(
    //    "BulkOrder(",
    //        "NFTSellOrder[2] tree"
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "NFTSellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "uint256 hashNonce",
    //    ")"
    //));
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H1 = 0xd34f03762ce1f357d7a826ecb4627841b188c269566aeb2a73e284d84cd78912;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H2 = 0xbe8fa00d5b6a4c861c69d133d99ca46b741eb30c6909efbec15c237de29df561;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H3 = 0xa4e6352852d88baa542528c5d7dd37687543ba5b2ee63f207a5e03fe4544415e;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H4 = 0x65ba80d235ecf7aec7cb17b9ba7cae23869c6f5338039d07c01170985202f1fb;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H5 = 0xb187dd134be01439b73639695a8858e0f1a24e73eb2b2a4cb0720b4dbda5ffd9;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H6 = 0x698d310ab6eafea7429fc10c1541820159abd99d4f97b0ac55a280c6fa034862;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H7 = 0x7d140482f96d81136b0473b9da1642229f2ace5516157987dd911fd86933752e;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H8 = 0x43ddc7bd2b79f0fce3d28ffe218973cdfc75db4d262dc7e68e78c43ddb2139d5;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H9 = 0xb2bb85f1bb297265004ee4385dfaa05cfc37266a01321161d983471d7e59d6f3;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H10 = 0xa3796aeaba14ca1c62562b30874fa4418b6b722d3092259608f09eeba1df16e8;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H11 = 0x3c9e717430c9ada5e01143f5e8a7c4a9285b0a8b818ae99cb471f764b6e432ea;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H12 = 0x42a852d8385b94b31ae1f6c15cf66b195eafe58bf051f8a16c803876f55da687;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H13 = 0xb793175426ec3a64dfc1ec27ca103f2368b0117fc08c4bbb1fa3b6ad133c2934;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H14 = 0x4ccffbfa05cf55a8156a9a2d539974bc99a792b040f07f8bcb9da8a8c50496b1;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H15 = 0xb19809e8a69fb92b9b3d5dcf8ed27878cebc770f6c81f317d4092f1d6ef38804;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H16 = 0xa09a903f341da4dd111eff50adb9c12edb83525d28f67eca2891dddbdba73659;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H17 = 0x9891e291bb672c5a78451aee982906c1cce43e4e5bc7397770c58fc4decd9039;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H18 = 0xd7c0b9608ad661aa8a552e080abdbeb17b5d35a0c523f385f3b6575823940ef5;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H19 = 0x8576b675cd395ceb837f22d2a7ecaa6de131eb69b16f017cee7c562896099bc0;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H20 = 0x23b44e24d7f76cbaf701cc1e9f071db3bdb8a724bbcb88b18f8c5694b082dd9f;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H21 = 0xc9ee72afde7c567fd7341fe62b02bca4ccf8705bcf6aac1e68ad25eed57fb755;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H22 = 0xa3dd9c0bf81fb4bfb232fe287cf1f5ce8561446f2f2319231bc4db0b3a2441c8;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H23 = 0x5309812ac587bdacbfd514f846f4bba837fe11edf3d82ec3338af8877192ffcd;
    bytes32 private constant _BULK_ERC721_SELL_ORDER_TYPE_HASH_H24 = 0x5379dceee9dc69ff1c99801b6c20a1933258d5e57119464510dff80bf19b529c;

    //keccak256(abi.encodePacked(
    //    "BulkOrder(",
    //        "NFTBuyOrder[2] tree"
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "NFTBuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "Property[] nftProperties,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    //));
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H1 = 0xb32e6b07ca7f956efdb96d28fed6462c6d478d4f66692a6773741b404ff85f74;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H2 = 0x9f75ca91e1048cc22959b86e890a322468993b0042056da157f2b412c6448a67;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H3 = 0x0b9237358bc0780db84404e8ac4354d9f65ad89d2f69ee36feef85323cc50e56;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H4 = 0x1d7449e626c1883d0a685a1eda892c4ebbec2fee5314d96df22ec6075af7e6da;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H5 = 0x3bd53d6120daeed6dfbe380dea0375dc8998073981bdb5b77d06c322e9f2d647;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H6 = 0x5ee31cf4765667f4d0fb661820bbfe26e1583a3035f58a2fa02f1bba4e6fbd6c;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H7 = 0xb608f4e4a9cd3cfd2c8cfccdad26888534996b0ae42be788464d9f617736ca9a;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H8 = 0x46b6148f58b19871db49b6f83360c40fa5c1245310a5a68a58ebd575aa83ed13;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H9 = 0xa8a9bda09e5a02cacb2dead999ab5f3a42c31378575a118d3610c7fcd0f5f589;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H10 = 0x104d0c688b877378c48931b8ab8d4cd40b91a284864372a291f5f0781080320a;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H11 = 0x566bb180c8b6c356458ac8ac2b1f94a344f13ad2cab2a0368fb5e0f63995271c;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H12 = 0xea284288a7b9efcb7bfa8960c9fee47e83a928c769634a8ccd84de1f04ab5cca;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H13 = 0x07f743265e8e61a1b890adf806926567cc011ebdfa491d5accc08a0c353056f2;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H14 = 0x3cb41bc57327bfc80e77688d75fd37ae8d661f2d347e724e8f5e417022f9796f;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H15 = 0xc79245b07759ae6288019cddb41b3cf90ca8ee2f5c8339d99b111efc6544a867;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H16 = 0xacd68817a805cfc3b06f56b3bbb5fcbdf8e945abd065de4c81c580533f7a600a;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H17 = 0xd57701e882860956e3f7872db1e179d6b8fc8e13a5398bb6af893a5e42e77839;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H18 = 0x2f3ed58d4e1d0a4c76f70032ee82f302118bfbadf3b0c39721868115a2bb020b;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H19 = 0x185fae4db124d03654cdc4beefd2f59ae93e9cc2f04eda3d86eefc6ad69fb653;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H20 = 0x8284117e9b7752fa6a09985a8ad343a0f36e4399dc23841b852b06f61c494944;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H21 = 0x4645af7b9f125b178e9090156cc187c311456985f773afde066dad652981a8db;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H22 = 0x15c4e80ebf08449122359b63924db2ae4aefad40b75bef4b6a4325cf2f72ce9c;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H23 = 0xa18f3d5fd85a19d6b8db5ebd2d5e31db3fb730b2d30a046b473c0137a2fc8056;
    bytes32 private constant _BULK_ERC721_BUY_ORDER_TYPE_HASH_H24 = 0x637175f391c9fa3e7d2456fc5f4d663cb628d453586604ba35d7a0f2d89f958b;

    //keccak256(abi.encodePacked(
    //    "BulkOrder(",
    //        "ERC1155BuyOrder[2] tree",
    //    ")",
    //    "ERC1155BuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "Property[] erc1155TokenProperties,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    //));
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H1 = 0x06ebd50d9a0478e933167ddd59b33aad59b9601007b8ab0644d5317274fa477c;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H2 = 0x4332f3188d5bb5242a3a339824172cfb862da9a98bdf15d2f3848f8783766dd5;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H3 = 0x87b864a12bd96bac99659ad9646f04c0f6c39acb3483c86a40a47827ef897335;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H4 = 0x42515109fd2a179614d2a474ec133d28e5bce67542bbef6a1b1fb62b25da339f;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H5 = 0xaa709ab5849d659b0353cb57d3c90683b42e2b8e62557bb8e223575b36a29193;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H6 = 0x93111c998b9ec794d3f7f9f78520127bdb0c6bda5828c2d7635acd22950e6a37;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H7 = 0xb3ca47945f9f0e15d66c40ea7e058f536b2786ad1dd0092e38b818c9c103ddf4;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H8 = 0x56dacd6541283724269fe4e1e594041051c468721515df149e93087f9f08d366;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H9 = 0x00eb4936508848784f84148e6991b8871b33b7294b5244fba02750707efb3b59;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H10 = 0x1714ec693e1151b0d729959f2cea29a73169e92f732ea954aa1b34a268bc0a87;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H11 = 0x65114dd56a2f51a81c23d9e3a188eb19f23fbd857cf8b82b07628097cb996c0f;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H12 = 0x12ea41af8949c9b9a1ff2f736c9f66f9f73d951d3fcc82fbc259bcd209b44cc8;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H13 = 0x4f9a50789d3b21f7488444c8cd2127cd053f392bf178b58c30ec77626b771b2c;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H14 = 0xd123519b5ba947f405714106adf05c84cf33d1f4fabdf6b8b0d39bc019cbfdc3;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H15 = 0xbda87bfa1b02253d1a998f3573de8dcba18f231b599dc8d2274ad5704cb1d38c;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H16 = 0xcd80c0f13a214422a206fabdaa05d589907caba334846313f26a8d232877a5f4;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H17 = 0xb1a57f9ea04d4ce6d097926804b8a8093ae1a2f8f548cc514ae40770c871de7e;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H18 = 0x6d7c4ff60fce4c988ada572ff5447cfd4115329b5d98772281a5e8384e9d113d;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H19 = 0x5f36116fda20ab7b32eb8caf91980ccefa90ef7a3f0bbfe050288fb8d003e84d;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H20 = 0xfae6e9c50581dae3168b4d985e5d97e7e2c9230247637dc61b2259d889a0d383;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H21 = 0x6dcc44cb1bc3ba7c371b85bdedc36c93946f2b76443e1162f193c3f6f6921ba5;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H22 = 0x3175465e5d744b6896e381eda137c21e735b1d28df7df35b8c99b1d1313b2221;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H23 = 0xdbd25fdd09ccad35a5d6f9f4b983752a7db2bcc81d60b7a5042abb6a557b5ec0;
    bytes32 private constant _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H24 = 0x951ea5e5cd28bc4be27643958417c4d76f998d804c5dd114174e944d60ea7d80;

    //keccak256(abi.encodePacked(
    //    "BulkOrder(",
    //        "ERC1155SellOrder[2] tree",
    //    ")",
    //    "ERC1155SellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    //));
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H1 = 0x98ecfe335964f1c75a9fbc1ac09d96f38f4b76ef34bc91e020753da9f53842db;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H2 = 0x68140a04e66c153b96cc3550581d3c4d4fe676083a450663d2cb6cb8fc6049e3;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H3 = 0xcc351e5ce3ce59e09411444fb47a0ed5c81d167385f80329025fa9847f3809bd;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H4 = 0x7d835ba6b53caf45cff44b32c90a2f43c9641194bce2af0e8f6ab5fd51603e80;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H5 = 0x4b27d7de68e63c133276559cc95ce5b9f2418c437ab2e4b7e4ce02cfe7ca8cc5;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H6 = 0x0c46e3bf3dbac98caa1e79b1cb24de788a81830a6e30810409723ba7e1a1820a;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H7 = 0x041ffd89cad44d5f041ae3166443fdd24ec1f890e7f64cd642185de4363da859;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H8 = 0xfd925040fdc34d1b50bcef1115dae86e54fa5b1c6e89a659238bfa74b2395eb1;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H9 = 0x4b6378efc359f95cbfe7c37a7fca3cd34f57dcb7ce1f721c964d089531977885;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H10 = 0xa4a65c47d8a899d136c581a5c57ec4fb5b4329042754936f70d4fff7af51837b;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H11 = 0xfc5ae170f6e44d4ad79f7d94f322bf4fd9fc0b41d0bb0fb1fb2b6dfd563dd964;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H12 = 0x3fb3022fda65abb26316b0c72c3d2f962c800868753a27beabace6efcdd8334a;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H13 = 0xde54bd845f838a6c5599548857be4589d75ba88d68e82bcf8d89962bacc4f6cf;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H14 = 0x52308297d15ed521cafe62c0945ff9af8a62b888debc2b879e6f9cc3896e592d;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H15 = 0x8fee599ac99cbbf0795116166352544be9516045cce3643818ae72e1d1ad24bb;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H16 = 0x051605fd459d5d59ab7873250cb2b004789a911b52e0f55ad32195d0bc4f5b62;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H17 = 0x1d29a58d82356bdf924acc53b9f890ac7efa738fd59cb3f16b70e86aa5e0a25a;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H18 = 0x1963a1fcdd9b3fc88a6cc3bd53127ee988baaa8ea0a7fabf325d11a60344f9f8;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H19 = 0x675063352969ab8c1c71721e93dcb69bd3de91fdf9748e02e8a1212810f2ada7;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H20 = 0x7650bef40c048ceb24dc5711910f6632f103ebc4a5e9a6c4741e8b7dd7f75a84;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H21 = 0x222f8eab7ad36e71989d876c302c6a33fd83b7436e350388bd52462f898742c4;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H22 = 0x897b52e5b5e2f870b8c69ff86065cd777f10944c933bd37faff29c35f77c5908;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H23 = 0xa28cb7f810ce8e8a9d81a9d48764417ec6b03b271d5074210c56c1e2f1f8e084;
    bytes32 private constant _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H24 = 0xeb15c282d3dd0d3bb6bc268a4d8b652628a8e1ec03a1019d0ec66f15511c6817;

    function getBulkERC721SellOrderTypeHash(uint256 height) internal pure returns (bytes32) {
        if (height < 7) {
            if (height == 2) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H2;
            }
            if (height == 3) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H3;
            }
            if (height == 4) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H4;
            }
            if (height == 5) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H5;
            }
            if (height == 1) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H1;
            }
            if (height == 6) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H6;
            }
        }
        if (height < 13) {
            if (height == 7) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H7;
            }
            if (height == 8) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H8;
            }
            if (height == 9) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H9;
            }
            if (height == 10) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H10;
            }
            if (height == 11) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H11;
            }
            if (height == 12) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H12;
            }
        }

        if (height < 19) {
            if (height == 13) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H13;
            }
            if (height == 14) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H14;
            }
            if (height == 15) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H15;
            }
            if (height == 16) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H16;
            }
            if (height == 17) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H17;
            }
            if (height == 18) {
                return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H18;
            }
        }
        if (height == 19) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H19;
        }
        if (height == 20) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H20;
        }
        if (height == 21) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H21;
        }
        if (height == 22) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H22;
        }
        if (height == 23) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H23;
        }
        if (height == 24) {
            return _BULK_ERC721_SELL_ORDER_TYPE_HASH_H24;
        }
        revert("getBulkERC721SellOrderTypeHash error");
    }

    function getBulkERC721BuyOrderTypeHash(uint256 height) internal pure returns (bytes32) {
        if (height < 7) {
            if (height == 2) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H2;
            }
            if (height == 3) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H3;
            }
            if (height == 4) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H4;
            }
            if (height == 5) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H5;
            }
            if (height == 1) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H1;
            }
            if (height == 6) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H6;
            }
        }
        if (height < 13) {
            if (height == 7) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H7;
            }
            if (height == 8) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H8;
            }
            if (height == 9) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H9;
            }
            if (height == 10) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H10;
            }
            if (height == 11) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H11;
            }
            if (height == 12) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H12;
            }
        }

        if (height < 19) {
            if (height == 13) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H13;
            }
            if (height == 14) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H14;
            }
            if (height == 15) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H15;
            }
            if (height == 16) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H16;
            }
            if (height == 17) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H17;
            }
            if (height == 18) {
                return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H18;
            }
        }
        if (height == 19) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H19;
        }
        if (height == 20) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H20;
        }
        if (height == 21) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H21;
        }
        if (height == 22) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H22;
        }
        if (height == 23) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H23;
        }
        if (height == 24) {
            return _BULK_ERC721_BUY_ORDER_TYPE_HASH_H24;
        }
        revert("getBulkERC721BuyOrderTypeHash error");
    }

    function getBulkERC1155SellOrderTypeHash(uint256 height) internal pure returns (bytes32) {
        if (height < 7) {
            if (height == 2) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H2;
            }
            if (height == 3) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H3;
            }
            if (height == 4) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H4;
            }
            if (height == 5) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H5;
            }
            if (height == 1) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H1;
            }
            if (height == 6) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H6;
            }
        }
        if (height < 13) {
            if (height == 7) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H7;
            }
            if (height == 8) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H8;
            }
            if (height == 9) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H9;
            }
            if (height == 10) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H10;
            }
            if (height == 11) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H11;
            }
            if (height == 12) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H12;
            }
        }

        if (height < 19) {
            if (height == 13) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H13;
            }
            if (height == 14) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H14;
            }
            if (height == 15) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H15;
            }
            if (height == 16) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H16;
            }
            if (height == 17) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H17;
            }
            if (height == 18) {
                return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H18;
            }
        }
        if (height == 19) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H19;
        }
        if (height == 20) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H20;
        }
        if (height == 21) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H21;
        }
        if (height == 22) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H22;
        }
        if (height == 23) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H23;
        }
        if (height == 24) {
            return _BULK_ERC1155_SELL_ORDER_TYPE_HASH_H24;
        }
        revert("getBulkERC1155SellOrderTypeHash error");
    }

    function getBulkERC1155BuyOrderTypeHash(uint256 height) internal pure returns (bytes32) {
        if (height < 7) {
            if (height == 2) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H2;
            }
            if (height == 3) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H3;
            }
            if (height == 4) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H4;
            }
            if (height == 5) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H5;
            }
            if (height == 1) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H1;
            }
            if (height == 6) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H6;
            }
        }
        if (height < 13) {
            if (height == 7) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H7;
            }
            if (height == 8) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H8;
            }
            if (height == 9) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H9;
            }
            if (height == 10) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H10;
            }
            if (height == 11) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H11;
            }
            if (height == 12) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H12;
            }
        }

        if (height < 19) {
            if (height == 13) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H13;
            }
            if (height == 14) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H14;
            }
            if (height == 15) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H15;
            }
            if (height == 16) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H16;
            }
            if (height == 17) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H17;
            }
            if (height == 18) {
                return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H18;
            }
        }
        if (height == 19) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H19;
        }
        if (height == 20) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H20;
        }
        if (height == 21) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H21;
        }
        if (height == 22) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H22;
        }
        if (height == 23) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H23;
        }
        if (height == 24) {
            return _BULK_ERC1155_BUY_ORDER_TYPE_HASH_H24;
        }
        revert("getBulkERC1155BuyOrderTypeHash error");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "../../storage/LibCommonNftOrdersStorage.sol";
import "../../storage/LibERC721OrdersStorage.sol";
import "../../vendor/IPropertyValidator.sol";
import "../../vendor/IFeeRecipient.sol";
import "../../vendor/IEtherToken.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../fixins/FixinERC721Spender.sol";
import "../libs/LibTypeHash.sol";
import "../interfaces/IERC721OrdersEvent.sol";
import "../interfaces/IMatchOrderFeature.sol";

struct SellOrderInfo {
    bytes32 orderHash;
    address maker;
    uint256 listingTime;
    uint256 expiryTime;
    uint256 startNonce;
    address erc20Token;
    address platformFeeRecipient;
    bytes32 basicCollectionsHash;
    bytes32 collectionsHash;
    uint256 hashNonce;
    uint256 erc20TokenAmount;
    uint256 platformFeeAmount;
    address royaltyFeeRecipient;
    uint256 royaltyFeeAmount;
    address erc721Token;
    uint256 erc721TokenID;
    uint256 nonce;
}

/// @dev Feature for interacting with ERC721 orders.
contract MatchOrderFeature is IMatchOrderFeature, IERC721OrdersEvent, FixinTokenSpender, FixinERC721Spender  {

    uint256 internal constant ORDER_NONCE_MASK = (1 << 184) - 1;
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_64 = (1 << 64) - 1;
    uint256 internal constant MASK_48 = (1 << 48) - 1;
    uint256 internal constant MASK_32 = (1 << 32) - 1;
    uint256 internal constant MASK_16 = (1 << 16) - 1;

    uint256 internal constant MASK_SELECTOR = 0xffffffff << 224;
    uint256 constant STORAGE_ID_PROXY = 1 << 128;

    // keccak256("")
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(
    //    "BatchSignedERC721Orders(address maker,uint256 listingTime,uint256 expiryTime,uint256 startNonce,address erc20Token,address platformFeeRecipient,BasicCollection[] basicCollections,Collection[] collections,uint256 hashNonce)",
    //    "BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)",
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH = 0x2d8cbbbc696e7292c3b5beb38e1363d34ff11beb8c3456c14cb938854597b9ed;
    // keccak256("BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)")
    bytes32 internal constant _BASIC_COLLECTION_TYPE_HASH = 0x12ad29288fd70022f26997a9958d9eceb6e840ceaa79b72ea5945ba87e4d33b0;
    // keccak256(abi.encodePacked(
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _COLLECTION_TYPE_HASH = 0xb9f488d48cec782be9ecdb74330c9c6a33c236a8022d8a91a4e4df4e81b51620;
    // keccak256("OrderItem(uint256 erc20TokenAmount,uint256 nftId)")
    bytes32 internal constant _ORDER_ITEM_TYPE_HASH = 0x5f93394997caa49a9382d44a75e3ce6a460f32b39870464866ac994f8be97afe;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant DOMAIN = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("ElementEx")
    bytes32 internal constant NAME = 0x27b14c20196091d9cd90ca9c473d3ad1523b00ddf487a9b7452a8a119a16b98c;
    // keccak256("1.0.0")
    bytes32 internal constant VERSION = 0x06c015bd22b4c69690933c1058878ebdfef31f9aaae40bbe86d8a09fe1b2972c;

    /// @dev The WETH token contract.
    IEtherToken internal immutable WETH;
    /// @dev The implementation address of this feature.
    address internal immutable _IMPL;
    /// @dev The magic return value indicating the success of a `validateProperty`.
    bytes4 internal constant PROPERTY_CALLBACK_MAGIC_BYTES = IPropertyValidator.validateProperty.selector;
    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 internal constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(IEtherToken weth) {
        require(address(weth) != address(0), "WETH_ADDRESS_ERROR");
        WETH = weth;
        _IMPL = address(this);
    }

    function matchOrders(bytes[] calldata datas, bool revertIfIncomplete) external override {
        address implMatchOrder = _IMPL;
        address implMatchERC721Order;
        address implMatchERC1155Order;
        assembly {
            let someSuccess := 0
            let ptrEnd := add(datas.offset, mul(datas.length, 0x20))
            for { let ptr := datas.offset } lt(ptr, ptrEnd) { ptr := add(ptr, 0x20) } {
                let ptrData := add(datas.offset, calldataload(ptr))

                // Check the data length
                let dataLength := calldataload(ptrData)
                if lt(dataLength, 0x4) {
                    if revertIfIncomplete {
                        _revertDatasError()
                    }
                    continue
                }

                let impl
                let selector := and(calldataload(add(ptrData, 0x20)), MASK_SELECTOR)
                switch selector
                // matchOrder
                case 0xed03aa3c00000000000000000000000000000000000000000000000000000000 {
                    impl := implMatchOrder
                }
                // matchERC721Order
                case 0xe2f5f57200000000000000000000000000000000000000000000000000000000 {
                    if iszero(implMatchERC721Order) {
                        implMatchERC721Order := _getImplementation(selector)
                    }
                    impl := implMatchERC721Order
                }
                // matchERC1155Order
                case 0xd8abf66700000000000000000000000000000000000000000000000000000000 {
                    if iszero(implMatchERC1155Order) {
                        implMatchERC1155Order := _getImplementation(selector)
                    }
                    impl := implMatchERC1155Order
                }

                if impl {
                    calldatacopy(0, add(ptrData, 0x20), dataLength)
                    if delegatecall(gas(), impl, 0, dataLength, 0, 0) {
                        someSuccess := 1
                        continue
                    }
                    if revertIfIncomplete {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }

                if revertIfIncomplete {
                    _revertSelectorMismatch()
                }
            }

            if iszero(someSuccess) {
                _revertNoCallSuccess()
            }

            function _getImplementation(selector) -> impl {
                mstore(0x0, selector)
                mstore(0x20, STORAGE_ID_PROXY)
                impl := sload(keccak256(0x0, 0x40))
            }

            function _revertDatasError() {
                // revert("matchOrders: data error")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000176d617463684f72646572733a2064617461206572726f720000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }

            function _revertSelectorMismatch() {
                // revert("matchOrders: selector mismatch")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001e6d617463684f72646572733a2073656c6563746f72206d69736d6174)
                mstore(0x60, 0x6368000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }

            function _revertNoCallSuccess() {
                // revert("matchOrders: no calls success")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001d6d617463684f72646572733a206e6f2063616c6c7320737563636573)
                mstore(0x60, 0x7300000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }
        }
    }

    function matchOrder(
        SellOrderParam memory sellOrderParam,
        BuyOrderParam memory buyOrderParam
    )
        external
        override
        returns (uint256 profit)
    {
        SellOrderInfo memory sellOrderInfo = _checkupSellOrder(sellOrderParam);
        bytes32 buyOrderHash = _checkupBuyOrder(buyOrderParam, sellOrderInfo.maker, sellOrderInfo.erc721TokenID);

        LibNFTOrder.NFTBuyOrder memory buyOrder = buyOrderParam.order;
        require(sellOrderInfo.erc721Token == buyOrder.nft, "matchOrder: erc721 token mismatch");
        require(sellOrderInfo.erc20TokenAmount <= buyOrder.erc20TokenAmount, "matchOrder: erc20TokenAmount mismatch");

        uint256 amountToSeller;
        unchecked {
            amountToSeller = sellOrderInfo.erc20TokenAmount - sellOrderInfo.platformFeeAmount - sellOrderInfo.royaltyFeeAmount;
            profit = buyOrder.erc20TokenAmount - sellOrderInfo.erc20TokenAmount;
        }

        // Transfer the ERC721 asset from seller to buyer.
        _transferERC721AssetFrom(sellOrderInfo.erc721Token, sellOrderInfo.maker, buyOrder.maker, sellOrderInfo.erc721TokenID);

        if (sellOrderInfo.erc20Token == NATIVE_TOKEN_ADDRESS && buyOrder.erc20Token == WETH) {
            // Step 1: Transfer WETH from the buyer to element.
            _transferERC20TokensFrom(address(WETH), buyOrder.maker, address(this), buyOrder.erc20TokenAmount);

            // Step 2: Unwrap the WETH into ETH.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrderInfo.maker), amountToSeller);

            // Step 4: Pay fees for the buy order.
            _payFees(buyOrder);

            // Step 5: Pay fees for the sell order.
            _payFees(sellOrderInfo, address(0), true);

            // Step 6: Transfer the profit to msg.sender.
            _transferEth(payable(msg.sender), profit);
        } else {
            // Check ERC20 tokens
            require(sellOrderInfo.erc20Token == address(buyOrder.erc20Token), "matchOrder: erc20 token mismatch");

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrderInfo.erc20Token, buyOrder.maker, sellOrderInfo.maker, amountToSeller);

            // Step 2: Pay fees for the buy order.
            _payFees(buyOrder);

            // Step 3: Pay fees for the sell order.
            _payFees(sellOrderInfo, buyOrder.maker, false);

            // Step 4: Transfer the profit to msg.sender.
            _transferERC20TokensFrom(sellOrderInfo.erc20Token, buyOrder.maker, msg.sender, profit);
        }

        _emitEventSellOrderFilled(sellOrderInfo, buyOrder.maker);
        _emitEventBuyOrderFilled(buyOrder, sellOrderInfo.maker, sellOrderInfo.erc721TokenID, buyOrderHash);
    }

    function _checkupBuyOrder(
        BuyOrderParam memory param, address taker, uint256 tokenId
    ) internal returns (bytes32) {
        LibNFTOrder.NFTBuyOrder memory order = param.order;
        uint256 expiry = order.expiry >> 252;

        // Check maker.
        require(order.maker != address(0), "checkupBuyOrder: invalid maker");

        // Check erc20Token.
        require(address(order.erc20Token) != NATIVE_TOKEN_ADDRESS, "checkupBuyOrder: invalid erc20Token");

        // Check taker.
        require(order.taker == address(0) || order.taker == taker, "checkupBuyOrder: invalid taker");

        // Check listingTime.
        require(block.timestamp >= ((order.expiry >> 32) & MASK_32), "checkupBuyOrder: check listingTime failed");

        // Check expiryTime.
        require(block.timestamp < (order.expiry & MASK_32), "checkupBuyOrder: check expiryTime failed");

        // Check orderStatus.
        if (_isOrderFilledOrCancelled(order.maker, order.nonce)) {
            revert("checkupBuyOrder: order is filled");
        }

        bytes32 leaf = LibNFTOrder.getNFTBuyOrderStructHash(order, _getHashNonce(order.maker));
        bytes32 orderHash = _getEIP712Hash(leaf);

        // Check batch offer order.
        uint128 orderAmount = 1;
        if (expiry >> 252 == LibStructure.ORDER_KIND_BATCH_OFFER_ERC721S) {
            orderAmount = uint128((expiry >> 64) & MASK_32);
            uint128 filledAmount = LibERC721OrdersStorage.getStorage().filledAmount[orderHash];
            require(filledAmount < orderAmount, "checkupBuyOrder: order is filled");

            // Update order status.
            unchecked {
                LibERC721OrdersStorage.getStorage().filledAmount[orderHash] = (filledAmount + 1);
            }

            // Requires `nftProperties.length` > 0.
            require(order.nftProperties.length > 0, "checkupBuyOrder: invalid order kind");
        } else {
            // Update order status.
            _setOrderStatusBit(order.maker, order.nonce);
        }

        bytes32 validateHash = orderHash;
        bytes memory extraData = param.extraData;
        LibSignature.Signature memory signature = param.signature;

        // Bulk signature.
        if (
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            (validateHash, extraData) = _getBulkValidateHashAndExtraData(leaf, param.extraData);
        }

        // Validate properties.
        _validateOrderProperties(order, orderHash, tokenId, extraData);

        // Check the signature.
        _validateOrderSignature(
            validateHash,
            order.maker,
            signature.signatureType,
            signature.v,
            signature.r,
            signature.s
        );

        if (orderAmount > 1) {
            unchecked {
                order.erc20TokenAmount /= orderAmount;
                for (uint256 i; i < order.fees.length; i++) {
                    order.fees[i].amount /= orderAmount;
                }
            }
        }
        return orderHash;
    }

    /// data1 [48 bits(nonce) + 48 bits(startNonce) + 160 bits(maker)]
    /// data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(reserved) + 160 bits(erc20Token)]
    /// data3 [8 bits(signatureType) + 8 bits(v) + 80 bits(reserved) + 160 bits(platformFeeRecipient)]
    function _checkupSellOrder(SellOrderParam memory param) internal returns (SellOrderInfo memory info) {
        uint256 data1 = param.data1;
        uint256 data2 = param.data2;
        uint256 data3 = param.data3;

        info.nonce = data1 >> 208;
        info.startNonce = (data1 >> 160) & MASK_48;
        info.maker = address(uint160(data1 & MASK_160));
        info.listingTime = data2 >> 224;
        info.expiryTime = (data2 >> 192) & MASK_32;
        info.erc20Token = address(uint160(data2 & MASK_160));
        info.platformFeeRecipient = address(uint160(data3 & MASK_160));
        info.hashNonce = _getHashNonce(info.maker);

        // Check nonce.
        require(info.startNonce <= info.nonce, "checkupSellOrder: invalid nonce");

        // Check maker.
        require(info.maker != address(0), "checkupSellOrder: invalid maker");

        // Check listingTime.
        require(block.timestamp >= info.listingTime, "checkupSellOrder: check listingTime failed");

        // Check expiryTime.
        require(block.timestamp < info.expiryTime, "checkupSellOrder: check expiryTime failed");

        // Check orderStatus.
        if (_isOrderFilledOrCancelled(info.maker, info.nonce)) {
            revert("checkupSellOrder: order is filled");
        }

        // Update order status.
        _setOrderStatusBit(info.maker, info.nonce);

        // Get collectionsHash.
        _storeCollectionsHashToOrderInfo(param.basicCollections, param.collections, info);

        // structHash = keccak256(abi.encode(
        //     _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH,
        //     maker,
        //     listingTime,
        //     expiryTime,
        //     startNonce,
        //     erc20Token,
        //     platformFeeRecipient,
        //     basicCollectionsHash,
        //     collectionsHash,
        //     hashNonce
        // ));
        bytes32 structHash;
        assembly {
            mstore(info, _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH)
            structHash := keccak256(info, 0x140 /* 10 * 32 */)
        }
        info.orderHash = _getEIP712Hash(structHash);

        LibSignature.SignatureType signatureType;
        uint8 v;
        assembly {
            signatureType := byte(0, data3)
            v := byte(1, data3)
        }
        require(
            signatureType == LibSignature.SignatureType.EIP712 ||
            signatureType == LibSignature.SignatureType.EIP712_1271,
            "checkupSellOrder: invalid signatureType"
        );

        _validateOrderSignature(
            info.orderHash,
            info.maker,
            signatureType,
            v,
            param.r,
            param.s
        );
    }

    function _decodeSellOrderFee(SellOrderInfo memory outInfo, bytes32 fee) internal pure {
        uint256 platformFeePercentage;
        uint256 royaltyFeePercentage;
        address royaltyFeeRecipient;
        assembly {
            // fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)]
            platformFeePercentage := and(shr(176, fee), MASK_16)
            royaltyFeePercentage := and(shr(160, fee), MASK_16)
            royaltyFeeRecipient := and(fee, MASK_160)
        }
        outInfo.royaltyFeeRecipient = royaltyFeeRecipient;

        if (royaltyFeeRecipient == address(0)) {
            royaltyFeePercentage = 0;
        }
        if (outInfo.platformFeeRecipient == address(0)) {
            platformFeePercentage = 0;
        }

        unchecked {
            require(platformFeePercentage + royaltyFeePercentage <= 10000, "checkupSellOrder: fees percentage exceeds the limit");
            outInfo.platformFeeAmount = outInfo.erc20TokenAmount * platformFeePercentage / 10000;
            if (royaltyFeePercentage != 0) {
                outInfo.royaltyFeeAmount = outInfo.erc20TokenAmount * royaltyFeePercentage / 10000;
            }
        }
    }

    function _storeCollectionsHashToOrderInfo(
        BasicCollection[] memory basicCollections,
        Collection[] memory collections,
        SellOrderInfo memory outInfo
    ) internal pure {
        uint256 current;
        bool isTargetFind;
        uint256 targetIndex;
        unchecked {
            targetIndex = outInfo.nonce - outInfo.startNonce;
        }

        if (basicCollections.length == 0) {
            outInfo.basicCollectionsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            bytes32 ptr;
            bytes32 ptrHashArray;
            assembly {
                ptr := mload(0x40) // free memory pointer
                ptrHashArray := add(ptr, 0x80)
                mstore(ptr, _BASIC_COLLECTION_TYPE_HASH)
            }

            uint256 collectionsLength = basicCollections.length;
            for (uint256 i; i < collectionsLength; ) {
                BasicCollection memory collection = basicCollections[i];
                address nftAddress = collection.nftAddress;
                bytes32 fee = collection.fee;
                bytes32[] memory items = collection.items;
                uint256 itemsLength = items.length;

                if (!isTargetFind) {
                    unchecked {
                        uint256 next = current + itemsLength;
                        if (targetIndex >= current && targetIndex < next) {
                            isTargetFind = true;
                            outInfo.erc721Token = nftAddress;

                            uint256 item = uint256(items[targetIndex - current]);
                            outInfo.erc721TokenID = item & MASK_160;
                            outInfo.erc20TokenAmount = item >> 160;
                            _decodeSellOrderFee(outInfo, fee);
                        } else {
                            current = next;
                        }
                    }
                }

                assembly {
                    mstore(add(ptr, 0x20), nftAddress)
                    mstore(add(ptr, 0x40), fee)
                    mstore(add(ptr, 0x60), keccak256(add(items, 0x20), mul(itemsLength, 0x20)))
                    mstore(ptrHashArray, keccak256(ptr, 0x80))

                    ptrHashArray := add(ptrHashArray, 0x20)
                    i := add(i, 1)
                }
            }

            assembly {
                // store basicCollectionsHash
                mstore(add(outInfo, 0xe0), keccak256(add(ptr, 0x80), mul(collectionsLength, 0x20)))
            }
        }

        if (collections.length == 0) {
            outInfo.collectionsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            bytes32 ptr;
            bytes32 ptrHashArray;
            assembly {
                ptr := mload(0x40) // free memory pointer
                ptrHashArray := add(ptr, 0x80)
            }

            uint256 collectionsLength = collections.length;
            for (uint256 i; i < collectionsLength; ) {
                Collection memory collection = collections[i];
                address nftAddress = collection.nftAddress;
                bytes32 fee = collection.fee;
                OrderItem[] memory items = collection.items;
                uint256 itemsLength = items.length;

                if (!isTargetFind) {
                    unchecked {
                        uint256 next = current + itemsLength;
                        if (targetIndex >= current && targetIndex < next) {
                            isTargetFind = true;
                            outInfo.erc721Token = nftAddress;

                            OrderItem memory item = items[targetIndex - current];
                            outInfo.erc721TokenID = item.nftId;
                            outInfo.erc20TokenAmount = item.erc20TokenAmount;
                            _decodeSellOrderFee(outInfo, fee);
                        } else {
                            current = next;
                        }
                    }
                }

                bytes32 ptrItemHashArray = ptrHashArray;
                assembly {
                    mstore(ptr, _ORDER_ITEM_TYPE_HASH)
                }

                for (uint256 j; j < itemsLength; ) {
                    uint256 erc20TokenAmount = items[j].erc20TokenAmount;
                    uint256 nftId = items[j].nftId;
                    assembly {
                        mstore(add(ptr, 0x20), erc20TokenAmount)
                        mstore(add(ptr, 0x40), nftId)
                        mstore(ptrItemHashArray, keccak256(ptr, 0x60))

                        ptrItemHashArray := add(ptrItemHashArray, 0x20)
                        j := add(j, 1)
                    }
                }

                assembly {
                    mstore(ptr, _COLLECTION_TYPE_HASH)
                    mstore(add(ptr, 0x20), nftAddress)
                    mstore(add(ptr, 0x40), fee)
                    mstore(add(ptr, 0x60), keccak256(ptrHashArray, mul(itemsLength, 0x20)))
                    mstore(ptrHashArray, keccak256(ptr, 0x80))

                    ptrHashArray := add(ptrHashArray, 0x20)
                    i := add(i, 1)
                }
            }

            assembly {
                // store collectionsHash
                mstore(add(outInfo, 0x100), keccak256(add(ptr, 0x80), mul(collectionsLength, 0x20)))
            }
        }
        require(isTargetFind, "checkupSellOrder: invalid nonce");
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32 eip712Hash) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            mstore(ptr, DOMAIN)
            mstore(add(ptr, 0x20), NAME)
            mstore(add(ptr, 0x40), VERSION)
            mstore(add(ptr, 0x60), chainid())
            mstore(add(ptr, 0x80), address())

            mstore(add(ptr, 0x20), keccak256(ptr, 0xa0))
            mstore(add(ptr, 0x40), structHash)
            mstore(ptr, 0x1901)
            eip712Hash := keccak256(add(ptr, 0x1e), 0x42)
        }
    }

    function _getHashNonce(address maker) internal view returns (uint256) {
        return LibCommonNftOrdersStorage.getStorage().hashNonces[maker];
    }

    function _updateBuyOrderState(LibNFTOrder.NFTBuyOrder memory order, bytes32 orderHash) internal {
        if (order.expiry >> 252 == LibStructure.ORDER_KIND_BATCH_OFFER_ERC721S) {
            LibERC721OrdersStorage.getStorage().filledAmount[orderHash] += 1;
        } else {
            _setOrderStatusBit(order.maker, order.nonce);
        }
    }

    function _isOrderFilledOrCancelled(address maker, uint256 nonce) internal view returns(bool) {
        // Order status bit vectors are indexed by maker address and the
        // upper 248 bits of the order nonce. We define `nonceRange` to be
        // these 248 bits.
        uint248 nonceRange = uint248((nonce >> 8) & ORDER_NONCE_MASK);

        // `orderStatusByMaker` is indexed by maker and nonce.
        uint256 orderStatusBitVector =
            LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][nonceRange];

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);

        // If the designated bit is set, the order has been cancelled or
        // previously filled.
        return orderStatusBitVector & flag != 0;
    }

    function _setOrderStatusBit(address maker, uint256 nonce) internal {
        // Order status bit vectors are indexed by maker address and the
        // upper 248 bits of the order nonce. We define `nonceRange` to be
        // these 248 bits.
        uint248 nonceRange = uint248((nonce >> 8) & ORDER_NONCE_MASK);

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);

        // Update order status bit vector to indicate that the given order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][nonceRange] |= flag;
    }

    function _validateOrderSignature(
        bytes32 hash,
        address maker,
        LibSignature.SignatureType signatureType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        if (
            signatureType == LibSignature.SignatureType.EIP712 ||
            signatureType == LibSignature.SignatureType.EIP712_BULK
        ) {
            require(maker == ecrecover(hash, v, r, s), "INVALID_SIGNATURE");
        } else if (
            signatureType == LibSignature.SignatureType.EIP712_1271 ||
            signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            assembly {
                let ptr := mload(0x40) // free memory pointer

                // selector for `isValidSignature(bytes32,bytes)`
                mstore(ptr, 0x1626ba7e)
                mstore(add(ptr, 0x20), hash)
                mstore(add(ptr, 0x40), 0x40)
                mstore(add(ptr, 0x60), 0x41)
                mstore(add(ptr, 0x80), r)
                mstore(add(ptr, 0xa0), s)
                mstore(add(ptr, 0xc0), shl(248, v))

                if iszero(extcodesize(maker)) {
                    _revertInvalidSigner()
                }

                // Call signer with `isValidSignature` to validate signature.
                if iszero(staticcall(gas(), maker, add(ptr, 0x1c), 0xa5, ptr, 0x20)) {
                    _revertInvalidSignature()
                }

                // Check for returnData.
                if iszero(eq(mload(ptr), 0x1626ba7e00000000000000000000000000000000000000000000000000000000)) {
                    _revertInvalidSignature()
                }

                function _revertInvalidSigner() {
                    // revert("INVALID_SIGNER")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000000e494e56414c49445f5349474e45520000000000000000000000000000)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }

                function _revertInvalidSignature() {
                    // revert("INVALID_SIGNATURE")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x00000011494e56414c49445f5349474e41545552450000000000000000000000)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        } else if (signatureType == LibSignature.SignatureType.PRESIGNED) {
            if (
                LibERC721OrdersStorage.getStorage().preSigned[hash] !=
                LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1
            ) {
                revert("PRESIGNED_INVALID_SIGNER");
            }
        } else {
            revert("INVALID_SIGNATURE_TYPE");
        }
    }

    function _validateOrderProperties(
        LibNFTOrder.NFTBuyOrder memory order,
        bytes32 orderHash,
        uint256 tokenId,
        bytes memory data
    ) internal view {
        if (order.nftProperties.length == 0) {
            require(order.nftId == tokenId, "_validateProperties/TOKEN_ID_ERROR");
        } else {
            require(order.nftId == 0, "_validateProperties/TOKEN_ID_ERROR");
            for (uint256 i; i < order.nftProperties.length; ) {
                LibNFTOrder.Property memory property = order.nftProperties[i];
                if (address(property.propertyValidator) != address(0)) {
                    require(address(property.propertyValidator).code.length != 0, "INVALID_PROPERTY_VALIDATOR");

                    // Call the property validator and throw a descriptive error
                    // if the call reverts.
                    bytes4 result = property.propertyValidator.validateProperty(
                        order.nft, tokenId, orderHash, property.propertyData, data
                    );

                    // Check for the magic success bytes
                    require(result == PROPERTY_CALLBACK_MAGIC_BYTES, "PROPERTY_VALIDATION_FAILED");
                }
                unchecked { i++; }
            }
        }
    }

    function _getBulkValidateHashAndExtraData(
        bytes32 leaf, bytes memory takerData
    ) internal view returns(
        bytes32 validateHash, bytes memory data
    ) {
        uint256 proofsLength;
        bytes32 root = leaf;
        assembly {
            // takerData = 32bytes[length] + 32bytes[head] + [proofsData] + [data]
            let ptrHead := add(takerData, 0x20)

            // head = 4bytes[dataLength] + 1bytes[proofsLength] + 24bytes[unused] + 3bytes[proofsKey]
            let head := mload(ptrHead)
            let dataLength := shr(224, head)
            proofsLength := byte(4, head)
            let proofsKey := and(head, 0xffffff)

            // require(proofsLength != 0)
            if iszero(proofsLength) {
                _revertTakerDataError()
            }

            // require(32 + proofsLength * 32 + dataLength == takerData.length)
            if iszero(eq(add(0x20, add(shl(5, proofsLength), dataLength)), mload(takerData))) {
                _revertTakerDataError()
            }

            // Compute remaining proofs.
            let ptrAfterHead := add(ptrHead, 0x20)
            let ptrProofNode := ptrAfterHead

            for { let i } lt(i, proofsLength) { i := add(i, 1) } {
                // Check if the current bit of the key is set.
                switch and(shr(i, proofsKey), 0x1)
                case 0 {
                    mstore(ptrHead, root)
                    mstore(ptrAfterHead, mload(ptrProofNode))
                }
                case 1 {
                    mstore(ptrHead, mload(ptrProofNode))
                    mstore(ptrAfterHead, root)
                }

                root := keccak256(ptrHead, 0x40)
                ptrProofNode := add(ptrProofNode, 0x20)
            }

            data := sub(ptrProofNode, 0x20)
            mstore(data, dataLength)

            function _revertTakerDataError() {
                // revert("TakerData error")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000000f54616b657244617461206572726f7200000000000000000000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }
        }

        bytes32 typeHash = LibTypeHash.getBulkERC721BuyOrderTypeHash(proofsLength);
        validateHash = _getEIP712Hash(keccak256(abi.encode(typeHash, root)));
        return (validateHash, data);
    }

    function _payFees(SellOrderInfo memory info, address payer, bool useNativeToken) internal {
        if (useNativeToken) {
            if (info.platformFeeAmount != 0) {
                _transferEth(payable(info.platformFeeRecipient), info.platformFeeAmount);
            }
            if (info.royaltyFeeAmount != 0) {
                _transferEth(payable(info.royaltyFeeRecipient), info.royaltyFeeAmount);
            }
        } else {
            if (info.platformFeeAmount != 0) {
                _transferERC20TokensFrom(info.erc20Token, payer, info.platformFeeRecipient, info.platformFeeAmount);
            }
            if (info.royaltyFeeAmount != 0) {
                _transferERC20TokensFrom(info.erc20Token, payer, info.royaltyFeeRecipient, info.royaltyFeeAmount);
            }
        }
    }

    function _payFees(LibNFTOrder.NFTBuyOrder memory order) internal {
        for (uint256 i; i < order.fees.length; ) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            // Transfer ERC20 token from payer to recipient.
            _transferERC20TokensFrom(address(order.erc20Token), order.maker, fee.recipient, fee.amount);

            if (fee.feeData.length > 0) {
                require(fee.recipient.code.length != 0, "_payFees/INVALID_FEE_RECIPIENT");

                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    address(order.erc20Token),
                    fee.amount,
                    fee.feeData
                );

                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "_payFees/CALLBACK_FAILED");
            }

            unchecked { i++; }
        }
    }

    function _emitEventSellOrderFilled(SellOrderInfo memory info, address taker) internal {
        emit ERC721SellOrderFilled(
            info.orderHash,
            info.maker,
            taker,
            info.nonce,
            IERC20(info.erc20Token),
            info.erc20TokenAmount,
            _getFees(info),
            info.erc721Token,
            info.erc721TokenID
        );
    }

    function _getFees(SellOrderInfo memory info) internal pure returns(LibStructure.Fee[] memory fees) {
        if (info.platformFeeRecipient != address(0)) {
            if (info.royaltyFeeRecipient != address(0)) {
                fees = new LibStructure.Fee[](2);
                fees[1].recipient = info.royaltyFeeRecipient;
                fees[1].amount = info.royaltyFeeAmount;
            } else {
                fees = new LibStructure.Fee[](1);
            }
            fees[0].recipient = info.platformFeeRecipient;
            fees[0].amount = info.platformFeeAmount;
        } else {
            if (info.royaltyFeeRecipient != address(0)) {
                fees = new LibStructure.Fee[](1);
                fees[0].recipient = info.royaltyFeeRecipient;
                fees[0].amount = info.royaltyFeeAmount;
            } else {
                fees = new LibStructure.Fee[](0);
            }
        }
    }

    function _emitEventBuyOrderFilled(
        LibNFTOrder.NFTBuyOrder memory order,
        address taker,
        uint256 nftId,
        bytes32 orderHash
    ) internal {
        LibNFTOrder.Fee[] memory list = order.fees;
        LibStructure.Fee[] memory fees = new LibStructure.Fee[](list.length);
        for (uint256 i; i < fees.length; ) {
            fees[i].recipient = list[i].recipient;
            fees[i].amount = list[i].amount;
            order.erc20TokenAmount += list[i].amount;
            unchecked { ++i; }
        }

        emit ERC721BuyOrderFilled(
            orderHash,
            order.maker,
            taker,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            fees,
            order.nft,
            nftId
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;


/// @dev Helpers for moving ERC721 assets around.
abstract contract FixinERC721Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfer an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _transferERC721AssetFrom(address token, address owner, address to, uint256 tokenId) internal {
        require(token.code.length != 0, "_transferERC721/INVALID_TOKEN");
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), token, 0, ptr, 0x64, 0, 0)
        }
        require(success != 0, "_transferERC721/TRANSFER_FAILED");
    }

    /// @dev Safe transfer an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _safeTransferERC721AssetFrom(address token, address owner, address to, uint256 tokenId) internal {
        require(token.code.length != 0, "_safeTransferERC721AssetFrom/INVALID_TOKEN");
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256)
            mstore(ptr, 0x42842e0e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
        }
        require(success != 0, "_safeTransferERC721/TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(address token, address owner, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        require(token.code.length != 0, "_transferERC20/INVALID_TOKEN");

        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), token, 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success,) = recipient.call{value: amount}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "./LibStorage.sol";


library LibCommonNftOrdersStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
        // The current nonce for the maker represents the only valid nonce that can be signed by the maker
        // If a signature was signed with a nonce that's different from the one stored in nonces, it
        // will fail validation.
        mapping(address => uint256) hashNonces;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_COMMON_NFT_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "./LibStorage.sol";


/// @dev Storage helpers for `ERC721OrdersFeature`.
library LibERC721OrdersStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // maker => nonce range => order status bit vector
        mapping(address => mapping(uint248 => uint256)) orderStatusByMaker;
        // order hash => preSigned
        mapping(bytes32 => uint256) preSigned;
        // order hash => filledAmount
        mapping(bytes32 => uint128) filledAmount;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_ERC721_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;


/// @dev Common storage helpers
library LibStorage {

    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 constant STORAGE_ID_PROXY = 1 << 128;
    uint256 constant STORAGE_ID_SIMPLE_FUNCTION_REGISTRY = 2 << 128;
    uint256 constant STORAGE_ID_OWNABLE = 3 << 128;
    uint256 constant STORAGE_ID_COMMON_NFT_ORDERS = 4 << 128;
    uint256 constant STORAGE_ID_ERC721_ORDERS = 5 << 128;
    uint256 constant STORAGE_ID_ERC1155_ORDERS = 6 << 128;
    uint256 constant STORAGE_ID_REENTRANCY_GUARD = 7 << 128;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IEtherToken is IERC20 {
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;


interface IFeeRecipient {

    /// @dev A callback function invoked in the ERC721Feature for each ERC721
    ///      order fee that get paid. Integrators can make use of this callback
    ///      to implement arbitrary fee-handling logic, e.g. splitting the fee
    ///      between multiple parties.
    /// @param tokenAddress The address of the token in which the received fee is
    ///        denominated. `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` indicates
    ///        that the fee was paid in the native token (e.g. ETH).
    /// @param amount The amount of the given token received.
    /// @param feeData Arbitrary data encoded in the `Fee` used by this callback.
    /// @return success The selector of this function (0x0190805e),
    ///         indicating that the callback succeeded.
    function receiveZeroExFeeCallback(address tokenAddress, uint256 amount, bytes calldata feeData) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.17;


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param orderHash The order hash.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes32 orderHash,
        bytes calldata propertyData,
        bytes calldata takerData
    ) external view returns(bytes4);
}