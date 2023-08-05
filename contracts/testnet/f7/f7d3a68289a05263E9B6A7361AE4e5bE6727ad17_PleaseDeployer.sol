// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct OpenPositionInfo {
    uint256 id;
    uint256 openVersion;
    int256  qty;
    uint256 openTimestamp;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 tradingFee;
}

struct OpenPositionInfo2 {
    uint256 id;
    uint256 openVersion;
    int256  qty;
    uint256 openTimestamp;
    uint256 takerMargin;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {OpenPositionInfo, OpenPositionInfo2} from "./IMarketTrade.sol";

interface IPlease {
    event Open1(OpenPositionInfo[] position);
    event Open2(OpenPositionInfo[] position, address marketAddress);
    event Open3(OpenPositionInfo[] position, address indexed marketAddress);
    event Open4(address marketAddress, OpenPositionInfo position);
    event Open5(address indexed marketAddress, OpenPositionInfo position);
    event Open6(OpenPositionInfo position, uint256 marketAddress);
    event Open7(OpenPositionInfo position, uint256 indexed marketAddress);
    event Open8(uint256 marketAddress, OpenPositionInfo position);
    event Open9(uint256 indexed marketAddress, OpenPositionInfo position);


    event Open10(OpenPositionInfo2 position, uint256 marketAddress);
    event Open11(OpenPositionInfo2 position, uint256 indexed marketAddress);

    event OpenPositionNonIndexed(
        address marketAddress,
        uint256 positionId,
        OpenPositionInfo position
    );

    event PositionOpenNonIndexed(
        OpenPositionInfo position,
        address marketAddress,
        uint256 positionId
    );

    event OpenPosition(
        address indexed marketAddress,
        uint256 indexed positionId,
        OpenPositionInfo position
    );

    event PositionOpen(
        OpenPositionInfo position,
        address indexed marketAddress,
        uint256 indexed positionId
    );

    event InfoPosition(
        address indexed marketAddress,
        uint256 indexed positionId,
        uint256 id,
        uint256 openVersion,
        int256 qty,
        uint256 openTimestamp,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 tradingFee
    );

    event PositionInfo(
        uint256 id,
        uint256 openVersion,
        int256 qty,
        uint256 openTimestamp,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 tradingFee,
        address indexed marketAddress,
        uint256 indexed positionId
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPlease} from "./IPlease.sol";
import {OpenPositionInfo, OpenPositionInfo2} from "./IMarketTrade.sol";

// Uncomment this line to use co\nsole.log
// import "hardhat/console.sol";

contract Please is IPlease {
    function run() external {
        OpenPositionInfo memory info = OpenPositionInfo({
            id: 1,
            openVersion: 2,
            qty: 3,
            openTimestamp: 4,
            takerMargin: 5,
            makerMargin: 6,
            tradingFee: 7
        });

        OpenPositionInfo2 memory info2 = OpenPositionInfo2({
            id: 1,
            openVersion: 2,
            qty: 3,
            openTimestamp: 4,
            takerMargin: 5
        });

        OpenPositionInfo[] memory infos = new OpenPositionInfo[](1);
        infos[0] = info;

        emit Open1(infos);
        emit Open2(infos, address(this));
        emit Open3(infos, address(this));
        emit Open4(address(this), info);
        emit Open5(address(this), info);
        emit Open6(info, 1);
        emit Open7(info, 1);
        emit Open8(1, info);
        emit Open9(1, info);
        emit Open10(info2, 1);
        emit Open11(info2, 1);

        emit OpenPosition(address(this), 123, info);
        emit PositionOpen(info, address(this), 123);
        emit OpenPositionNonIndexed(address(this), 123, info);
        emit PositionOpenNonIndexed(info, address(this), 123);
        emit InfoPosition(address(this), 123, 1, 2, 3, 4, 5, 6, 7);
        emit PositionInfo(1, 2, 3, 4, 5, 6, 7, address(this), 123);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Please} from "./Please.sol";

contract PleaseDeployer {

    Please public immutable pleaseBase;
    mapping(address => address) public pleases;

    event PleaseCreated(address indexed please, address owner);

    constructor() payable {
        pleaseBase = new Please();
    }

    function create() external {
        address owner = msg.sender;
        require(pleases[owner] == address(0));
        Please newPlease = Please(Clones.clone(address(pleaseBase)));
        pleases[owner] = address(newPlease);
        emit PleaseCreated(address(newPlease), owner);
    }

}