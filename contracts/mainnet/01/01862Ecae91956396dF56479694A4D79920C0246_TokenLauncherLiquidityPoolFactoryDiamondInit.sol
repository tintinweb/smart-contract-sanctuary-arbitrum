// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibTokenLauncherLiquidityPoolFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.tokenlauncher.liquiditypool.factory.diamond.storage");

    struct DiamondStorage {
        address vaultFactory;
        uint256 currentBlockLiquidityPoolRegistered;
        mapping(address => address[]) liquidityPoolTokensByToken;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { LibTokenLauncherLiquidityPoolFactoryStorage } from "../libraries/LibTokenLauncherLiquidityPoolFactoryStorage.sol";

contract TokenLauncherLiquidityPoolFactoryDiamondInit {
    struct InitDiamondArgs {
        address vaultFactory;
    }

    function init(InitDiamondArgs memory _input) external {
        LibTokenLauncherLiquidityPoolFactoryStorage.DiamondStorage storage ds = LibTokenLauncherLiquidityPoolFactoryStorage.diamondStorage();

        ds.vaultFactory = _input.vaultFactory;
    }
}