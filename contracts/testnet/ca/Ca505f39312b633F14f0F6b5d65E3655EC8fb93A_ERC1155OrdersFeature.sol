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


interface IERC1155OrdersEvent {

    /// @dev Emitted whenever an `ERC1155SellOrder` is filled.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param erc1155Token The address of the ERC1155 token.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    /// @param erc1155FillAmount The amount of ERC1155 asset filled.
    /// @param orderHash The `ERC1155SellOrder` hash.
    event ERC1155SellOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20FillAmount,
        LibStructure.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount
    );

    /// @dev Emitted whenever an `ERC1155BuyOrder` is filled.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param erc1155Token The address of the ERC1155 token.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    /// @param erc1155FillAmount The amount of ERC1155 asset filled.
    /// @param orderHash The `ERC1155BuyOrder` hash.
    event ERC1155BuyOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20FillAmount,
        LibStructure.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount
    );

    /// @dev Emitted when an `ERC1155SellOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC1155SellOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        uint128 erc1155TokenAmount
    );

    /// @dev Emitted when an `ERC1155BuyOrder` is pre-signed.
    ///      Contains all the fields of the order.
    event ERC1155BuyOrderPreSigned(
        address maker,
        address taker,
        uint256 expiry,
        uint256 nonce,
        IERC20 erc20Token,
        uint256 erc20TokenAmount,
        LibNFTOrder.Fee[] fees,
        address erc1155Token,
        uint256 erc1155TokenId,
        LibNFTOrder.Property[] erc1155TokenProperties,
        uint128 erc1155TokenAmount
    );

    /// @dev Emitted whenever an `ERC1155Order` is cancelled.
    /// @param maker The maker of the order.
    /// @param nonce The nonce of the order that was cancelled.
    event ERC1155OrderCancelled(address maker, uint256 nonce);
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
import "../libs/LibSignature.sol";
import "./IERC1155OrdersEvent.sol";


/// @dev Feature for interacting with ERC1155 orders.
interface IERC1155OrdersFeature is IERC1155OrdersEvent {

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    function sellERC1155(
        LibNFTOrder.ERC1155BuyOrder calldata buyOrder,
        LibSignature.Signature calldata signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes calldata takerData
    ) external;

    /// @dev Sells multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param datas The encoded `sellERC1155` calldatas.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    function batchSellERC1155s(bytes[] calldata datas, bool revertIfIncomplete) external;

    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param taker The address to receive ERC1155. If this parameter
    ///        is zero, transfer ERC1155 to `msg.sender`.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    function buyERC1155Ex(
        LibNFTOrder.ERC1155SellOrder calldata sellOrder,
        LibSignature.Signature calldata signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes calldata takerData
    ) external payable;

    /// @dev Cancel a single ERC1155 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC1155Order(uint256 orderNonce) external;

    /// @dev Cancel multiple ERC1155 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC1155Orders(uint256[] calldata orderNonces) external;

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155TokenAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param takers The address to receive ERC1155.
    /// @param takerDatas The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `takerData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC1155sEx(
        LibNFTOrder.ERC1155SellOrder[] calldata sellOrders,
        LibSignature.Signature[] calldata signatures,
        address[] calldata takers,
        uint128[] calldata erc1155TokenAmounts,
        bytes[] calldata takerDatas,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    /// @dev Callback for the ERC1155 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC1155 asset if
    ///      a valid ERC1155 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC1155 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the asset being transferred.
    /// @param value The amount being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC1155 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0xf23a6e61),
    ///         indicating that the callback succeeded.
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4 success);

    /// @dev Approves an ERC1155 sell order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 sell order.
    function preSignERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order) external;

    /// @dev Approves an ERC1155 buy order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 buy order.
    function preSignERC1155BuyOrder(LibNFTOrder.ERC1155BuyOrder calldata order) external;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 sell order. Reverts if not.
    /// @param order The ERC1155 sell order.
    /// @param signature The signature to validate.
    function validateERC1155SellOrderSignature(
        LibNFTOrder.ERC1155SellOrder calldata order,
        LibSignature.Signature calldata signature
    ) external view;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 sell order. Reverts if not.
    /// @param order The ERC1155 sell order.
    /// @param signature The signature to validate.
    function validateERC1155SellOrderSignature(
        LibNFTOrder.ERC1155SellOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata takerData
    ) external view;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 buy order. Reverts if not.
    /// @param order The ERC1155 buy order.
    /// @param signature The signature to validate.
    function validateERC1155BuyOrderSignature(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature
    ) external view;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 buy order. Reverts if not.
    /// @param order The ERC1155 buy order.
    /// @param signature The signature to validate.
    function validateERC1155BuyOrderSignature(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata takerData
    ) external view;

    /// @dev Get the order info for an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return orderInfo Infor about the order.
    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    /// @dev Get the order info for an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return orderInfo Infor about the order.
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    /// @dev Get the EIP-712 hash of an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return orderHash The order hash.
    function getERC1155SellOrderHash(LibNFTOrder.ERC1155SellOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the EIP-712 hash of an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return orderHash The order hash.
    function getERC1155BuyOrderHash(LibNFTOrder.ERC1155BuyOrder calldata order)
        external
        view
        returns (bytes32 orderHash);

    /// @dev Get the order nonce status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the order.
    /// @param nonceRange Order status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        order nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The order status bit vector for the
    ///         given maker and nonce range.
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange)
        external
        view
        returns (uint256);

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC1155 asset.
    /// @param buyOrder Order buying an ERC1155 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchERC1155Order(
        LibNFTOrder.ERC1155SellOrder calldata sellOrder,
        LibNFTOrder.ERC1155BuyOrder calldata buyOrder,
        LibSignature.Signature calldata sellOrderSignature,
        LibSignature.Signature calldata buyOrderSignature,
        bytes calldata sellTakerData,
        bytes calldata buyTakerData
    ) external returns (uint256 profit);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library LibMultiCall {

    uint256 private constant SELECTOR_MASK = (0xffffffff << 224);

    function _multiCall(address impl, bytes4 selector, bytes[] calldata datas, bool revertIfIncomplete) internal {
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

                // Copy the calldata to memory[0 - dataLength]
                calldatacopy(0, add(ptrData, 0x20), dataLength)

                // Check the data selector
                if eq(and(mload(0), SELECTOR_MASK), selector) {
                    if delegatecall(gas(), impl, 0, dataLength, 0, 0) {
                        someSuccess := 1
                        continue
                    }

                    if revertIfIncomplete {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                    continue
                }

                if revertIfIncomplete {
                    _revertSelectorMismatch()
                }
            }

            if iszero(someSuccess) {
                _revertNoCallSuccess()
            }

            function _revertDatasError() {
                // revert("_multiCall: data error")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000165f6d756c746943616c6c3a2064617461206572726f72000000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }

            function _revertSelectorMismatch() {
                // revert("_multiCall: selector mismatch")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001d5f6d756c746943616c6c3a2073656c6563746f72206d69736d617463)
                mstore(0x60, 0x6800000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }

            function _revertNoCallSuccess() {
                // revert("_multiCall: all calls failed")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001c5f6d756c746943616c6c3a20616c6c2063616c6c73206661696c6564)
                mstore(0x60, 0)
                revert(0, 0x64)
            }
        }
    }
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

import "../../fixins/FixinERC1155Spender.sol";
import "../../storage/LibCommonNftOrdersStorage.sol";
import "../../storage/LibERC1155OrdersStorage.sol";
import "../interfaces/IERC1155OrdersFeature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "../libs/LibTypeHash.sol";
import "../libs/LibMultiCall.sol";
import "./NFTOrders.sol";


/// @dev Feature for interacting with ERC1155 orders.
contract ERC1155OrdersFeature is
    IERC1155OrdersFeature,
    FixinERC1155Spender,
    NFTOrders
{
    using LibNFTOrder for LibNFTOrder.ERC1155SellOrder;
    using LibNFTOrder for LibNFTOrder.ERC1155BuyOrder;
    using LibNFTOrder for LibNFTOrder.NFTSellOrder;
    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev The magic return value indicating the success of a `onERC1155Received`.
    bytes4 private constant ERC1155_RECEIVED_MAGIC_BYTES = this.onERC1155Received.selector;
    bytes4 private constant SELL_ERC1155_SELECTOR = this.sellERC1155.selector;

    uint256 private constant ORDER_NONCE_MASK = (1 << 184) - 1;

    constructor(IEtherToken weth) NFTOrders(weth) {
    }

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    function sellERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes memory takerData
    ) external override {
        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                takerData
            )
        );
    }

    function batchSellERC1155s(bytes[] calldata datas, bool revertIfIncomplete) external override {
        LibMultiCall._multiCall(_implementation, SELL_ERC1155_SELECTOR, datas, revertIfIncomplete);
    }

    function buyERC1155Ex(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes memory takerData
    ) external override payable {
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        _buyERC1155(sellOrder, signature, erc1155BuyAmount, taker, takerData);

        // Refund
        if (address(this).balance != ethBalanceBefore) {
            _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
        }
    }

    /// @dev Cancel a single ERC1155 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC1155Order(uint256 orderNonce) public override {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (orderNonce & 255);
        // Update order cancellation bit vector to indicate that the order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC1155OrdersStorage.getStorage().orderCancellationByMaker
            [msg.sender][uint248((orderNonce >> 8) & ORDER_NONCE_MASK)] |= flag;

        emit ERC1155OrderCancelled(msg.sender, orderNonce);
    }

    /// @dev Cancel multiple ERC1155 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC1155Orders(uint256[] calldata orderNonces) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelERC1155Order(orderNonces[i]);
        }
    }

    function batchBuyERC1155sEx(
        LibNFTOrder.ERC1155SellOrder[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        address[] calldata takers,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory takerDatas,
        bool revertIfIncomplete
    ) external override payable returns (bool[] memory successes) {
        uint256 length = sellOrders.length;
        require(
            length == signatures.length &&
            length == takers.length &&
            length == erc1155FillAmounts.length &&
            length == takerDatas.length,
            "ARRAY_LENGTH_MISMATCH"
        );

        successes = new bool[](length);
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        bool someSuccess = false;
        if (revertIfIncomplete) {
            for (uint256 i; i < length; ) {
                // Will revert if _buyERC1155 reverts.
                _buyERC1155(sellOrders[i], signatures[i], erc1155FillAmounts[i], takers[i], takerDatas[i]);
                successes[i] = true;
                someSuccess = true;
                unchecked { i++; }
            }
        } else {
            for (uint256 i; i < length; ) {
                // Delegatecall `buyERC1155FromProxy` to catch swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this.buyERC1155FromProxy.selector,
                        sellOrders[i],
                        signatures[i],
                        erc1155FillAmounts[i],
                        takers[i],
                        takerDatas[i]
                    )
                );
                if (successes[i]) {
                    someSuccess = true;
                }
                unchecked { i++; }
            }
        }
        require(someSuccess, "batchBuyERC1155sEx/NO_ORDER_FILLED");

        // Refund
       _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    // @Note `buyERC1155FromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function buyERC1155FromProxy(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 buyAmount,
        address taker,
        bytes memory takerData
    ) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _buyERC1155(sellOrder, signature, buyAmount, taker, takerData);
    }

    /// @dev Callback for the ERC1155 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC1155 asset if
    ///      a valid ERC1155 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC1155 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param tokenId The ID of the asset being transferred.
    /// @param value The amount being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC1155 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0xf23a6e61),
    ///         indicating that the callback succeeded.
    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4 success) {
        // Decode the order, signature, and `unwrapNativeToken` from
        // `data`. If `data` does not encode such parameters, this
        // will throw.
        (
            LibNFTOrder.ERC1155BuyOrder memory buyOrder,
            LibSignature.Signature memory signature,
            bool unwrapNativeToken,
            bytes memory takerData
        ) = abi.decode(
            data,
            (LibNFTOrder.ERC1155BuyOrder, LibSignature.Signature, bool, bytes)
        );

        // `onERC1155Received` is called by the ERC1155 token contract.
        // Check that it matches the ERC1155 token in the order.
        require(msg.sender == buyOrder.erc1155Token, "ERC1155_TOKEN_MISMATCH_ERROR");
        require(value <= type(uint128).max, "ERC1155_VALUE_OVERFLOW");

        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                uint128(value),
                tokenId,
                unwrapNativeToken,
                operator,       // taker
                address(this),  // owner (we hold the NFT currently)
                takerData
            )
        );

        return ERC1155_RECEIVED_MAGIC_BYTES;
    }

    /// @dev Approves an ERC1155 sell order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 sell order.
    function preSignERC1155SellOrder(LibNFTOrder.ERC1155SellOrder memory order) external override {
        require(order.maker == msg.sender, "ONLY_MAKER");

        uint256 hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker];
        require(hashNonce < type(uint128).max);

        bytes32 orderHash = getERC1155SellOrderHash(order);
        LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned = uint128(hashNonce + 1);

        emit ERC1155SellOrderPreSigned(
            order.maker,
            order.taker,
            order.expiry,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            order.fees,
            order.erc1155Token,
            order.erc1155TokenId,
            order.erc1155TokenAmount
        );
    }

    /// @dev Approves an ERC1155 buy order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 buy order.
    function preSignERC1155BuyOrder(LibNFTOrder.ERC1155BuyOrder memory order) external override {
        require(order.maker == msg.sender, "ONLY_MAKER");

        uint256 hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker];
        require(hashNonce < type(uint128).max, "HASH_NONCE_OUTSIDE");

        bytes32 orderHash = getERC1155BuyOrderHash(order);
        LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned = uint128(hashNonce + 1);

        emit ERC1155BuyOrderPreSigned(
            order.maker,
            order.taker,
            order.expiry,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            order.fees,
            order.erc1155Token,
            order.erc1155TokenId,
            order.erc1155TokenProperties,
            order.erc1155TokenAmount
        );
    }

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellERC1155` and `onERC1155Received`.
    function _sellERC1155(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal {
        bytes32 orderHash;
        (buyOrder.erc20TokenAmount, orderHash) = _sellNFT(
            buyOrder.asNFTBuyOrder(),
            signature,
            params
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            params.taker,
            params.tokenId,
            params.sellAmount,
            orderHash
        );
    }

    function _buyERC1155(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 buyAmount,
        address taker,
        bytes memory takerData
    ) internal {
        require(taker != address(this), "_buyERC1155/TAKER_CANNOT_SELF");
        if (taker == address(0)) {
            taker = msg.sender;
        }

        bytes32 orderHash;
        (sellOrder.erc20TokenAmount, orderHash) = _buyNFT(
            sellOrder.asNFTSellOrder(),
            signature,
            buyAmount,
            taker,
            takerData
        );

        _emitEventSellOrderFilled(
            sellOrder,
            taker,
            buyAmount,
            orderHash
        );
    }

    function _emitEventSellOrderFilled(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        address taker,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) internal {
        LibStructure.Fee[] memory fees = new LibStructure.Fee[](sellOrder.fees.length);
        for (uint256 i; i < sellOrder.fees.length; ) {
            fees[i].recipient = sellOrder.fees[i].recipient;
            unchecked {
                fees[i].amount = sellOrder.fees[i].amount * erc1155FillAmount / sellOrder.erc1155TokenAmount;
            }
            sellOrder.erc20TokenAmount += fees[i].amount;
            unchecked { ++i; }
        }

        emit ERC1155SellOrderFilled(
            orderHash,
            sellOrder.maker,
            taker,
            sellOrder.nonce,
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            fees,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            erc1155FillAmount
        );
    }

    function _emitEventBuyOrderFilled(
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155FillAmount,
        bytes32 orderHash
    ) internal {
        LibStructure.Fee[] memory fees = new LibStructure.Fee[](buyOrder.fees.length);
        for (uint256 i; i < buyOrder.fees.length; ) {
            fees[i].recipient = buyOrder.fees[i].recipient;
            unchecked {
                fees[i].amount = buyOrder.fees[i].amount * erc1155FillAmount / buyOrder.erc1155TokenAmount;
            }
            buyOrder.erc20TokenAmount += fees[i].amount;
            unchecked { ++i; }
        }

        emit ERC1155BuyOrderFilled(
            orderHash,
            buyOrder.maker,
            taker,
            buyOrder.nonce,
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            fees,
            buyOrder.erc1155Token,
            erc1155TokenId,
            erc1155FillAmount
        );
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 sell order. Reverts if not.
    /// @param order The ERC1155 sell order.
    /// @param signature The signature to validate.
    function validateERC1155SellOrderSignature(
        LibNFTOrder.ERC1155SellOrder memory order,
        LibSignature.Signature memory signature
    ) external override view {
        _validateOrderSignature(getERC1155SellOrderHash(order), signature, order.maker);
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 sell order. Reverts if not.
    /// @param order The ERC1155 sell order.
    /// @param signature The signature to validate.
    function validateERC1155SellOrderSignature(
        LibNFTOrder.ERC1155SellOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory takerData
    ) external override view {
        if (
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            (bytes32 hash, ) = _getBulkValidateHashAndExtraData(false, _getSellOrderStructHash(order), takerData);
            _validateOrderSignature(hash, signature, order.maker);
        } else {
            _validateOrderSignature(getERC1155SellOrderHash(order), signature, order.maker);
        }
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 buy order. Reverts if not.
    /// @param order The ERC1155 buy order.
    /// @param signature The signature to validate.
    function validateERC1155BuyOrderSignature(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature
    ) external override view {
        _validateOrderSignature(getERC1155BuyOrderHash(order), signature, order.maker);
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 buy order. Reverts if not.
    /// @param order The ERC1155 buy order.
    /// @param signature The signature to validate.
    function validateERC1155BuyOrderSignature(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory takerData
    ) external override view {
        if (
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            (bytes32 hash, ) = _getBulkValidateHashAndExtraData(true, _getBuyOrderStructHash(order), takerData);
            _validateOrderSignature(hash, signature, order.maker);
        } else {
            _validateOrderSignature(getERC1155BuyOrderHash(order), signature, order.maker);
        }
    }

    function _isOrderPreSigned(bytes32 orderHash, address maker) internal override view returns(bool) {
        return LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned ==
        LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1;
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal override {
        _transferERC1155AssetFrom(token, from, to, tokenId, amount);
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTSellOrder memory /* order */,
        bytes32 orderHash,
        uint128 fillAmount
    ) internal override {
        LibERC1155OrdersStorage.getStorage().orderState[orderHash].filledAmount += fillAmount;
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTBuyOrder memory /* order */,
        bytes32 orderHash,
        uint128 fillAmount
    ) internal override {
        LibERC1155OrdersStorage.getStorage().orderState[orderHash].filledAmount += fillAmount;
    }

    /// @dev Get the order info for an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return orderInfo Infor about the order.
    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder memory order)
        external
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        LibNFTOrder.OrderInfoV2 memory info = _getOrderInfo(order.asNFTSellOrder());
        orderInfo.orderHash = info.orderHash;
        orderInfo.status = info.status;
        orderInfo.orderAmount = info.orderAmount;
        orderInfo.remainingAmount = info.remainingAmount;
        return orderInfo;
    }

    /// @dev Get the order info for an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return orderInfo Infor about the order.
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder memory order)
        external
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        LibNFTOrder.OrderInfoV2 memory info = _getOrderInfo(order.asNFTBuyOrder());
        orderInfo.orderHash = info.orderHash;
        orderInfo.status = info.status;
        orderInfo.orderAmount = info.orderAmount;
        orderInfo.remainingAmount = info.remainingAmount;
        return orderInfo;
    }

    /// @dev Get the EIP-712 hash of an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return orderHash The order hash.
    function getERC1155SellOrderHash(LibNFTOrder.ERC1155SellOrder memory order)
        public
        override
        view
        returns (bytes32 orderHash)
    {
        return _getEIP712Hash(_getSellOrderStructHash(order));
    }

    /// @dev Get the EIP-712 hash of an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return orderHash The order hash.
    function getERC1155BuyOrderHash(LibNFTOrder.ERC1155BuyOrder memory order)
        public
        override
        view
        returns (bytes32 orderHash)
    {
        return _getEIP712Hash(_getBuyOrderStructHash(order));
    }

    /// @dev Get the order nonce status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the order.
    /// @param nonceRange Order status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        order nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The order status bit vector for the
    ///         given maker and nonce range.
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange)
        external
        override
        view
        returns (uint256)
    {
        uint248 range = uint248(nonceRange & ORDER_NONCE_MASK);
        return LibERC1155OrdersStorage.getStorage().orderCancellationByMaker[maker][range];
    }

    /// @dev Get the order info for an NFT sell order.
    /// @param nftSellOrder The NFT sell order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTSellOrder memory nftSellOrder)
        internal
        override
        view
        returns (LibNFTOrder.OrderInfoV2 memory orderInfo)
    {
        LibNFTOrder.ERC1155SellOrder memory order = nftSellOrder.asERC1155SellOrder();
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.structHash = _getSellOrderStructHash(order);
        orderInfo.orderHash = _getEIP712Hash(orderInfo.structHash);

        uint256 orderBitVector;
        {
            LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
            orderInfo.remainingAmount = order.erc1155TokenAmount - stor.orderState[orderInfo.orderHash].filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint248 nonceRange = uint248((order.nonce >> 8) & ORDER_NONCE_MASK);
            orderBitVector = stor.orderCancellationByMaker[order.maker][nonceRange];
        }

        // Check for listingTime.
        if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (order.nonce & 255);
        if (orderInfo.remainingAmount == 0 || (orderBitVector & flag) != 0) {
            orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
            return orderInfo;
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    /// @dev Get the order info for an NFT buy order.
    /// @param nftBuyOrder The NFT buy order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTBuyOrder memory nftBuyOrder)
        internal
        override
        view
        returns (LibNFTOrder.OrderInfoV2 memory orderInfo)
    {
        LibNFTOrder.ERC1155BuyOrder memory order = nftBuyOrder.asERC1155BuyOrder();

        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.structHash = _getBuyOrderStructHash(order);
        orderInfo.orderHash = _getEIP712Hash(orderInfo.structHash);

        uint256 orderBitVector;
        {
            LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
            orderInfo.remainingAmount = order.erc1155TokenAmount - stor.orderState[orderInfo.orderHash].filledAmount;

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint248 nonceRange = uint248((order.nonce >> 8) & ORDER_NONCE_MASK);
            orderBitVector = stor.orderCancellationByMaker[order.maker][nonceRange];
        }

        // Only buy orders with `erc1155TokenId` == 0 can be property orders.
        if (order.erc1155TokenProperties.length > 0 && order.erc1155TokenId != 0) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (address(order.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for listingTime.
        if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (order.nonce & 255);
        if (orderInfo.remainingAmount == 0 || (orderBitVector & flag) != 0) {
            orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
            return orderInfo;
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    function _getBuyOrderStructHash(LibNFTOrder.ERC1155BuyOrder memory order) internal view returns(bytes32) {
        return LibNFTOrder.getERC1155BuyOrderStructHash(
            order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
        );
    }

    function _getSellOrderStructHash(LibNFTOrder.ERC1155SellOrder memory order) internal view returns(bytes32) {
        return LibNFTOrder.getERC1155SellOrderStructHash(
            order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]
        );
    }

    function _getBulkBuyOrderTypeHash(uint256 height) internal override pure returns (bytes32) {
        return LibTypeHash.getBulkERC1155BuyOrderTypeHash(height);
    }

    function _getBulkSellOrderTypeHash(uint256 height) internal override pure returns (bytes32) {
        return LibTypeHash.getBulkERC1155SellOrderTypeHash(height);
    }

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC1155 asset.
    /// @param buyOrder Order buying an ERC1155 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchERC1155Order(
        LibNFTOrder.ERC1155SellOrder memory sellOrder,
        LibNFTOrder.ERC1155BuyOrder memory buyOrder,
        LibSignature.Signature memory sellOrderSignature,
        LibSignature.Signature memory buyOrderSignature,
        bytes memory sellTakerData,
        bytes memory buyTakerData
    ) external override returns (uint256 profit) {
        // The ERC1155 tokens must match
        require(sellOrder.erc1155Token == buyOrder.erc1155Token, "ERC1155_TOKEN_MISMATCH_ERROR");

        LibNFTOrder.OrderInfoV2 memory sellOrderInfo = _getOrderInfo(sellOrder.asNFTSellOrder());
        LibNFTOrder.OrderInfoV2 memory buyOrderInfo = _getOrderInfo(buyOrder.asNFTBuyOrder());

        // English Auction
        if (sellOrder.expiry >> 252 == LibStructure.ORDER_KIND_ENGLISH_AUCTION) {
            require(
                sellOrderInfo.orderAmount == sellOrderInfo.remainingAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.orderAmount &&
                sellOrderInfo.orderAmount == buyOrderInfo.remainingAmount,
                "UNMATCH_ORDER_AMOUNT"
            );
        }

        // fillAmount = min(sellOrder.remainingAmount, buyOrder.remainingAmount)
        uint128 erc1155FillAmount =
            sellOrderInfo.remainingAmount < buyOrderInfo.remainingAmount ?
            sellOrderInfo.remainingAmount :
            buyOrderInfo.remainingAmount;

        _validateSellOrder(
            sellOrder.asNFTSellOrder(),
            sellOrderSignature,
            sellOrderInfo,
            buyOrder.maker,
            erc1155FillAmount,
            sellTakerData
        );
        _validateBuyOrder(
            buyOrder.asNFTBuyOrder(),
            buyOrderSignature,
            buyOrderInfo,
            sellOrder.maker,
            sellOrder.erc1155TokenId,
            erc1155FillAmount,
            buyTakerData
        );

        // Reset sellOrder.erc20TokenAmount
        if (erc1155FillAmount != sellOrderInfo.orderAmount) {
            sellOrder.erc20TokenAmount = _ceilDiv(
                sellOrder.erc20TokenAmount * erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }
        // Reset buyOrder.erc20TokenAmount
        if (erc1155FillAmount != buyOrderInfo.orderAmount) {
            buyOrder.erc20TokenAmount =
                buyOrder.erc20TokenAmount * erc1155FillAmount / buyOrderInfo.orderAmount;
        }

        // English Auction
        if (sellOrder.expiry >> 252 == LibStructure.ORDER_KIND_ENGLISH_AUCTION) {
            _resetEnglishAuctionERC20AmountAndFees(
                sellOrder.asNFTSellOrder(),
                buyOrder.erc20TokenAmount,
                erc1155FillAmount,
                sellOrderInfo.orderAmount
            );
        }

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC1155 asset from seller to buyer.
        _transferERC1155AssetFrom(
            sellOrder.erc1155Token,
            sellOrder.maker,
            buyOrder.maker,
            sellOrder.erc1155TokenId,
            erc1155FillAmount
        );

        // Handle the ERC20 side of the order:
        if (
            address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS &&
            buyOrder.erc20Token == WETH
        ) {
            // The sell order specifies ETH, while the buy order specifies WETH.
            // The orders are still compatible with one another, but we'll have
            // to unwrap the WETH on behalf of the buyer.

            // Step 1: Transfer WETH from the buyer to the EP.
            //         Note that we transfer `buyOrder.erc20TokenAmount`, which
            //         is the amount the buyer signaled they are willing to pay
            //         for the ERC1155 asset, which may be more than the seller's
            //         ask.
            _transferERC20TokensFrom(
                address(WETH),
                buyOrder.maker,
                address(this),
                buyOrder.erc20TokenAmount
            );
            // Step 2: Unwrap the WETH into ETH. We unwrap the entire
            //         `buyOrder.erc20TokenAmount`.
            //         The ETH will be used for three purposes:
            //         - To pay the seller
            //         - To pay fees for the sell order
            //         - Any remaining ETH will be sent to
            //           `msg.sender` as profit.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrder.maker), sellOrder.erc20TokenAmount);

            // Step 4: Pay fees for the buy order. Note that these are paid
            //         in _WETH_ by the _buyer_. By signing the buy order, the
            //         buyer signals that they are willing to spend a total
            //         of `erc20TokenAmount` _plus_ fees, all denominated in
            //         the `erc20Token`, which in this case is WETH.
            _payFees(
                buyOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 5: Pay fees for the sell order. The `erc20Token` of the
            //         sell order is ETH, so the fees are paid out in ETH.
            //         There should be `spread` wei of ETH remaining in the
            //         EP at this point, which we will use ETH to pay the
            //         sell order fees.
            uint256 sellOrderFees = _payFees(
                sellOrder.asNFTSellOrder(),
                address(this), // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                true           // useNativeToken
            );

            // Step 6: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
               _transferEth(payable(msg.sender), profit);
            }
        } else {
            // ERC20 tokens must match
            require(sellOrder.erc20Token == buyOrder.erc20Token, "ERC20_TOKEN_MISMATCH_ERROR");

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            //         Note that we transfer `sellOrder.erc20TokenAmount`, which
            //         is at most `buyOrder.erc20TokenAmount`.
            _transferERC20TokensFrom(
                address(buyOrder.erc20Token),
                buyOrder.maker,
                sellOrder.maker,
                sellOrder.erc20TokenAmount
            );

            // Step 2: Pay fees for the buy order. Note that these are paid
            //         by the buyer. By signing the buy order, the buyer signals
            //         that they are willing to spend a total of
            //         `buyOrder.erc20TokenAmount` _plus_ `buyOrder.fees`.
            _payFees(
                buyOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                buyOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 3: Pay fees for the sell order. These are paid by the buyer
            //         as well. After paying these fees, we may have taken more
            //         from the buyer than they agreed to in the buy order. If
            //         so, we revert in the following step.
            uint256 sellOrderFees = _payFees(
                sellOrder.asNFTSellOrder(),
                buyOrder.maker, // payer
                erc1155FillAmount,
                sellOrderInfo.orderAmount,
                false           // useNativeToken
            );

            // Step 4: We calculate the profit as:
            //         profit = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount - sellOrderFees
            //                = spread - sellOrderFees
            //         I.e. the buyer would've been willing to pay up to `profit`
            //         more to buy the asset, so instead that amount is sent to
            //         `msg.sender` as the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferERC20TokensFrom(
                    address(buyOrder.erc20Token),
                    buyOrder.maker,
                    msg.sender,
                    profit
                );
            }
        }

        _emitEventSellOrderFilled(
            sellOrder,
            buyOrder.maker, // taker
            erc1155FillAmount,
            sellOrderInfo.orderHash
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            sellOrder.maker, // taker
            sellOrder.erc1155TokenId,
            erc1155FillAmount,
            buyOrderInfo.orderHash
        );
    }
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
import "../../fixins/FixinEIP712.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/IEtherToken.sol";
import "../../vendor/IPropertyValidator.sol";
import "../../vendor/IFeeRecipient.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibStructure.sol";


/// @dev Abstract base contract inherited by ERC721OrdersFeature and NFTOrders
abstract contract NFTOrders is FixinEIP712, FixinTokenSpender {

    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev Native token pseudo-address.
    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherToken internal immutable WETH;
    /// @dev The implementation address of this feature.
    address internal immutable _implementation;
    /// @dev The magic return value indicating the success of a `validateProperty`.
    bytes4 private constant PROPERTY_CALLBACK_MAGIC_BYTES = IPropertyValidator.validateProperty.selector;
    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;

    constructor(IEtherToken weth) {
        require(address(weth) != address(0), "WETH_ADDRESS_ERROR");
        WETH = weth;
        // Remember this feature's original address.
        _implementation = address(this);
    }

    struct SellParams {
        uint128 sellAmount;
        uint256 tokenId;
        bool unwrapNativeToken;
        address taker;
        address currentNftOwner;
        bytes takerData;
    }

    // Core settlement logic for selling an NFT asset.
    function _sellNFT(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal returns (uint256 erc20FillAmount, bytes32 orderHash) {
        LibNFTOrder.OrderInfoV2 memory orderInfo = _getOrderInfo(buyOrder);
        orderHash = orderInfo.orderHash;

        // Check that the order can be filled.
        _validateBuyOrder(buyOrder, signature, orderInfo, params.taker, params.tokenId, params.sellAmount, params.takerData);

        // Calculate erc20 pay amount.
        erc20FillAmount = (params.sellAmount == orderInfo.orderAmount) ?
            buyOrder.erc20TokenAmount : buyOrder.erc20TokenAmount * params.sellAmount / orderInfo.orderAmount;

        if (params.unwrapNativeToken && buyOrder.erc20Token == WETH) {
            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            _transferERC20TokensFrom(address(WETH), buyOrder.maker, address(this), erc20FillAmount);

            // Unwrap WETH into ETH.
            WETH.withdraw(erc20FillAmount);

            // Send ETH to the seller.
            _transferEth(payable(params.taker), erc20FillAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(address(buyOrder.erc20Token), buyOrder.maker, params.taker, erc20FillAmount);
        }

        // Transfer the NFT asset to the buyer.
        // If this function is called from the
        // `onNFTReceived` callback the Exchange Proxy
        // holds the asset. Otherwise, transfer it from
        // the seller.
        _transferNFTAssetFrom(buyOrder.nft, params.currentNftOwner, buyOrder.maker, params.tokenId, params.sellAmount);

        // The buyer pays the order fees.
        _payFees(buyOrder.asNFTSellOrder(), buyOrder.maker, params.sellAmount, orderInfo.orderAmount, false);
    }

    // Core settlement logic for buying an NFT asset.
    function _buyNFT(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 buyAmount,
        address taker,
        bytes memory takerData
    ) internal returns (uint256 erc20FillAmount, bytes32 orderHash) {
        LibNFTOrder.OrderInfoV2 memory orderInfo = _getOrderInfo(sellOrder);
        orderHash = orderInfo.orderHash;

        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, taker, buyAmount, takerData);

        // Dutch Auction
        if (sellOrder.expiry >> 252 == LibStructure.ORDER_KIND_DUTCH_AUCTION) {
            uint256 count = (sellOrder.expiry >> 64) & 0xffffffff;
            if (count > 0) {
                _resetDutchAuctionERC20AmountAndFees(sellOrder, count);
            }
        }

        // Calculate erc20 pay amount.
        erc20FillAmount = (buyAmount == orderInfo.orderAmount) ?
            sellOrder.erc20TokenAmount : _ceilDiv(sellOrder.erc20TokenAmount * buyAmount, orderInfo.orderAmount);

        // Transfer the NFT asset to the buyer.
        _transferNFTAssetFrom(sellOrder.nft, sellOrder.maker, taker, sellOrder.nftId, buyAmount);

        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payFees(sellOrder, address(this), buyAmount, orderInfo.orderAmount, true);
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(address(sellOrder.erc20Token), msg.sender, sellOrder.maker, erc20FillAmount);

            // The buyer pays fees.
            _payFees(sellOrder, msg.sender, buyAmount, orderInfo.orderAmount, false);
        }
    }

    function _validateSellOrder(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfoV2 memory orderInfo,
        address taker,
        uint128 buyAmount,
        bytes memory takerData
    ) internal {
        // Taker must match the order taker, if one is specified.
        require(sellOrder.taker == address(0) || sellOrder.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check amount.
        require(buyAmount <= orderInfo.remainingAmount, "_validateOrder/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(sellOrder, orderInfo.orderHash, buyAmount);

        // Check the signature.
        if (
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            (bytes32 validateHash, ) = _getBulkValidateHashAndExtraData(false, orderInfo.structHash, takerData);
            _validateOrderSignature(validateHash, signature, sellOrder.maker);
        } else {
            _validateOrderSignature(orderInfo.orderHash, signature, sellOrder.maker);
        }
    }

    function _validateBuyOrder(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfoV2 memory orderInfo,
        address taker,
        uint256 tokenId,
        uint128 sellAmount,
        bytes memory takerData
    ) internal {
        // The ERC20 token cannot be ETH.
        require(address(buyOrder.erc20Token) != NATIVE_TOKEN_ADDRESS, "_validateOrder/TOKEN_MISMATCH");

        // Taker must match the order taker, if one is specified.
        require(buyOrder.taker == address(0) || buyOrder.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check amount.
        require(sellAmount <= orderInfo.remainingAmount, "_validateOrder/EXCEEDS_REMAINING_AMOUNT");

        // Update the order state.
        _updateOrderState(buyOrder, orderInfo.orderHash, sellAmount);

        if (
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            (bytes32 validateHash, bytes memory extraData) = _getBulkValidateHashAndExtraData(true, orderInfo.structHash, takerData);

            // Validate properties.
            _validateOrderProperties(buyOrder, orderInfo.orderHash, tokenId, extraData);

            // Check the signature.
            _validateOrderSignature(validateHash, signature, buyOrder.maker);
        } else {
            // Validate properties.
            _validateOrderProperties(buyOrder, orderInfo.orderHash, tokenId, takerData);

            // Check the signature.
            _validateOrderSignature(orderInfo.orderHash, signature, buyOrder.maker);
        }
    }

    function _resetDutchAuctionERC20AmountAndFees(LibNFTOrder.NFTSellOrder memory order, uint256 count) internal view {
        require(count <= 100000000, "COUNT_OUT_OF_SIDE");

        uint256 listingTime = (order.expiry >> 32) & 0xffffffff;
        uint256 denominator = ((order.expiry & 0xffffffff) - listingTime) * 100000000;
        uint256 multiplier = (block.timestamp - listingTime) * count;

        // Reset erc20TokenAmount
        uint256 amount = order.erc20TokenAmount;
        order.erc20TokenAmount = amount - amount * multiplier / denominator;

        // Reset fees
        for (uint256 i = 0; i < order.fees.length; i++) {
            amount = order.fees[i].amount;
            order.fees[i].amount = amount - amount * multiplier / denominator;
        }
    }

    function _resetEnglishAuctionERC20AmountAndFees(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        uint256 buyERC20Amount,
        uint256 fillAmount,
        uint256 orderAmount
    ) internal pure {
        uint256 sellOrderFees = _calcTotalFeesPaid(sellOrder.fees, fillAmount, orderAmount);
        uint256 sellTotalAmount = sellOrderFees + sellOrder.erc20TokenAmount;
        if (buyERC20Amount != sellTotalAmount) {
            uint256 spread = buyERC20Amount - sellTotalAmount;
            uint256 sum;

            // Reset fees
            if (sellTotalAmount > 0) {
                for (uint256 i = 0; i < sellOrder.fees.length; i++) {
                    uint256 diff = spread * sellOrder.fees[i].amount / sellTotalAmount;
                    sellOrder.fees[i].amount += diff;
                    sum += diff;
                }
            }

            // Reset erc20TokenAmount
            sellOrder.erc20TokenAmount += spread - sum;
        }
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }

    function _calcTotalFeesPaid(LibNFTOrder.Fee[] memory fees, uint256 fillAmount, uint256 orderAmount) private pure returns (uint256 totalFeesPaid) {
        if (fillAmount == orderAmount) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount;
            }
        } else {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount * fillAmount / orderAmount;
            }
        }
        return totalFeesPaid;
    }

    function _payFees(
        LibNFTOrder.NFTSellOrder memory order,
        address payer,
        uint128 fillAmount,
        uint128 orderAmount,
        bool useNativeToken
    ) internal returns (uint256 totalFeesPaid) {
        for (uint256 i; i < order.fees.length; ) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            uint256 feeFillAmount = (fillAmount == orderAmount) ? fee.amount : fee.amount * fillAmount / orderAmount;

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                if (feeFillAmount > 0) {
                    // Transfer ERC20 token from payer to recipient.
                    _transferERC20TokensFrom(address(order.erc20Token), payer, fee.recipient, feeFillAmount);
                }
            }

            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                require(fee.recipient.code.length != 0, "_payFees/INVALID_FEE_RECIPIENT");

                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(order.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );

                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "_payFees/CALLBACK_FAILED");
            }

            // Sum the fees paid
            totalFeesPaid += feeFillAmount;
            unchecked { i++; }
        }
        return totalFeesPaid;
    }

    function _validateOrderProperties(
        LibNFTOrder.NFTBuyOrder memory order,
        bytes32 orderHash,
        uint256 tokenId,
        bytes memory data
    ) internal view {
        // If no properties are specified, check that the given
        // `tokenId` matches the one specified in the order.
        if (order.nftProperties.length == 0) {
            require(tokenId == order.nftId, "_validateProperties/TOKEN_ID_ERR");
        } else {
            // Validate each property
            for (uint256 i; i < order.nftProperties.length; ) {
                LibNFTOrder.Property memory property = order.nftProperties[i];
                // `address(0)` is interpreted as a no-op. Any token ID
                // will satisfy a property with `propertyValidator == address(0)`.
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
        bool isBuyOrder,
        bytes32 leaf,
        bytes memory takerData
    ) internal view returns(
        bytes32 validateHash,
        bytes memory data
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

        if (isBuyOrder) {
            validateHash = _getEIP712Hash(
                keccak256(abi.encode(_getBulkBuyOrderTypeHash(proofsLength), root))
            );
        } else {
            validateHash = _getEIP712Hash(
                keccak256(abi.encode(_getBulkSellOrderTypeHash(proofsLength), root))
            );
        }
        return (validateHash, data);
    }

    function _isOrderPreSigned(bytes32 orderHash, address maker) internal virtual view returns(bool);

    function _validateOrderSignature(
        bytes32 hash, LibSignature.Signature memory signature, address maker
    ) internal view {
        if (
            signature.signatureType == LibSignature.SignatureType.EIP712 ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK
        ) {
            require(maker != address(0), "INVALID_SIGNER");
            require(maker == ecrecover(hash, signature.v, signature.r, signature.s), "INVALID_SIGNATURE");
        } else if (
            signature.signatureType == LibSignature.SignatureType.EIP712_1271 ||
            signature.signatureType == LibSignature.SignatureType.EIP712_BULK_1271
        ) {
            uint256 v = signature.v;
            bytes32 r = signature.r;
            bytes32 s = signature.s;
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
        } else if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            require(maker != address(0), "INVALID_SIGNER");
            require(_isOrderPreSigned(hash, maker), "PRESIGNED_INVALID_SIGNER");
        } else {
            revert("INVALID_SIGNATURE_TYPE");
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(address token, address from, address to, uint256 tokenId, uint256 amount) internal virtual;

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(LibNFTOrder.NFTSellOrder memory order, bytes32 orderHash, uint128 fillAmount) internal virtual;

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(LibNFTOrder.NFTBuyOrder memory order, bytes32 orderHash, uint128 fillAmount) internal virtual;

    /// @dev Get the order info for an NFT sell order.
    /// @param nftSellOrder The NFT sell order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTSellOrder memory nftSellOrder) internal virtual view returns (LibNFTOrder.OrderInfoV2 memory);

    /// @dev Get the order info for an NFT buy order.
    /// @param nftBuyOrder The NFT buy order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTBuyOrder memory nftBuyOrder) internal virtual view returns (LibNFTOrder.OrderInfoV2 memory);

    function _getBulkBuyOrderTypeHash(uint256 height) internal virtual pure returns (bytes32);

    function _getBulkSellOrderTypeHash(uint256 height) internal virtual pure returns (bytes32);
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


/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {

    bytes32 private constant DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME = keccak256("ElementEx");
    bytes32 private constant VERSION = keccak256("1.0.0");

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", keccak256(abi.encode(DOMAIN, NAME, VERSION, block.chainid, address(this))), structHash));
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


/// @dev Helpers for moving ERC1155 assets around.
abstract contract FixinERC1155Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers an ERC1155 asset from `owner` to `to`.
    /// @param token The address of the ERC1155 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferERC1155AssetFrom(
        address token,
        address owner,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        internal
    {
        require(token.code.length != 0, "_transferERC1155/INVALID_TOKEN");
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(ptr, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)
            mstore(add(ptr, 0x64), amount)
            mstore(add(ptr, 0x84), 0xa0)
            mstore(add(ptr, 0xa4), 0)

            success := call(gas(), token, 0, ptr, 0xc4, 0, 0)
        }
        require(success != 0, "_transferERC1155/TRANSFER_FAILED");
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


/// @dev Storage helpers for `ERC1155OrdersFeature`.
library LibERC1155OrdersStorage {

    struct OrderState {
        // The amount (denominated in the ERC1155 asset)
        // that the order has been filled by.
        uint128 filledAmount;
        // Whether the order has been pre-signed.
        uint128 preSigned;
    }

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping from order hash to order state:
        mapping(bytes32 => OrderState) orderState;
        // maker => nonce range => order cancellation bit vector
        mapping(address => mapping(uint248 => uint256)) orderCancellationByMaker;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_ERC1155_ORDERS;
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