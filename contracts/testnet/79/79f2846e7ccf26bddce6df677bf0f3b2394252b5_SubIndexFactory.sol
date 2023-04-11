// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "./libraries/SubIndexLib.sol";

import {ISubIndexFactory} from "./interfaces/ISubIndexFactory.sol";

contract SubIndexFactory is ISubIndexFactory {
    uint256 internal _lastId;

    mapping(uint256 => SubIndexLib.SubIndex) internal _subIndexes;

    function createSubIndex(uint256 chainId, address[] memory assets, uint256[] memory balances)
        external
        returns (uint256 id)
    {
        // TODO: only orderer
        if (assets.length != balances.length) {
            revert();
        }

        unchecked {
            id = ++_lastId;
        }

        _subIndexes[id] = SubIndexLib.SubIndex(id, chainId, assets, balances);
    }

    function subIndexOf(uint256 id) external view returns (SubIndexLib.SubIndex memory) {
        return _subIndexes[id];
    }

    function subIndexesOf(uint256[] calldata ids) external view returns (SubIndexLib.SubIndex[] memory result) {
        result = new SubIndexLib.SubIndex[](ids.length);

        for (uint256 i; i < ids.length;) {
            result[i] = _subIndexes[ids[i]];
            unchecked {
                i = i + 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

interface ISubIndexFactory {
    function createSubIndex(uint256 chainId, address[] memory assets, uint256[] memory balances)
        external
        returns (uint256 id);

    function subIndexOf(uint256 id) external view returns (SubIndexLib.SubIndex memory);

    function subIndexesOf(uint256[] calldata ids) external view returns (SubIndexLib.SubIndex[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library SubIndexLib {
    struct SubIndex {
        // TODO: make it uint128 ?
        uint256 id;
        uint256 chainId;
        address[] assets;
        uint256[] balances;
    }

    uint32 internal constant TOTAL_SUPPLY = type(uint32).max;
}