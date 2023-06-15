// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @title Interface a Pool needs to adhere.
library PoolConfiguration {
    event PauseState(bool newPauseState, uint256 blockTimestamp);

    struct Data {
        bool paused;
        address productAddress;
    }

    function load() internal pure returns (Data storage self) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.PoolConfiguration"));
        assembly {
            self.slot := s
        }
    }

    function setPauseState(Data storage self, bool state) internal {
        self.paused = state;
        emit PauseState(state, block.timestamp);
    }

    function setProductAddress(Data storage self, address _productAddress) internal {
        self.productAddress = _productAddress;
    }

    function whenNotPaused() internal view {
        require(!PoolConfiguration.load().paused, "Paused");
    }
}