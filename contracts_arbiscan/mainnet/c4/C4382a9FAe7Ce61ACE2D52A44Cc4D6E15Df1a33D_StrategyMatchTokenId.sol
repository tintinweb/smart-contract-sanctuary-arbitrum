// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStrategy} from "./interfaces/IStrategy.sol";
import {Orders} from "./libraries/Orders.sol";


contract StrategyMatchTokenId is IStrategy {
    uint256 public immutable fee;

    constructor(uint256 _fee) {
        fee = _fee;
    }

    function canExecuteTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        override
        returns (bool, uint256, uint256)
    {
        return (
            ((makerBid.price == takerAsk.price) &&
                (makerBid.tokenId == takerAsk.tokenId) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp)),
            makerBid.tokenId,
            makerBid.amount
        );
    }

    function canExecuteTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        view
        override
        returns (bool, uint256, uint256)
    {
        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            makerAsk.tokenId,
            makerAsk.amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Orders} from "../libraries/Orders.sol";

interface IStrategy {
    function fee() external view returns (uint256);

    function canExecuteTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Orders {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }
}