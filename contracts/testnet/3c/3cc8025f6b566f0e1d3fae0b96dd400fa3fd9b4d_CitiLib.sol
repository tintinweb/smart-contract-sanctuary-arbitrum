// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

library CitiLib {
    // forgefmt: disable-next-item
    function unpackExtraData(uint96 extraData)
        public
        pure
        returns (
            uint8 timesYoinked,
            uint40 seed
        )
    {
        return (
            uint8(extraData),
            uint40(extraData >> 8)
        );
    }

    // forgefmt: disable-next-item
    function packExtraData(
        uint8 timesYoinked,
        uint40 seed
    )
        public
        pure
        returns (uint96 extraData)
    {
        return
            uint96(timesYoinked) |
            (uint96(seed) << 8);
    }

    // forgefmt: disable-next-item
    function unpackAux(uint224 aux)
        public
        pure
        returns (
            uint32 multiplier,
            uint128 lastDistance,
            uint64 lastTimestamp
        )
    {
        return (
            uint32(aux),
            uint128(aux >> 32),
            uint64(aux >> 160)
        );
    }

    // forgefmt: disable-next-item
    function packAux(
        uint32 multiplier,
        uint128 lastDistance,
        uint64 lastTimestamp
    )
        public
        pure
        returns (uint224 aux)
    {
        return
            uint224(multiplier) |
            (uint224(lastDistance) << 32) |
            (uint224(lastTimestamp) << 160);
    }
}