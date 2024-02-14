// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IOmniseaDN404.sol";
import "./OmniseaDN404Proxy.sol";
import "../interfaces/IOmniseaDN404Factory.sol";
import {CreateParams} from "../structs/dn404/DN404Structs.sol";
import "../util/ReentrancyGuard.sol";

contract OmniseaDN404Factory is IOmniseaDN404Factory, ReentrancyGuard {
    address internal _manager;
    address public owner;
    address public scheduler;
    mapping(address => bool) public drops;

    event Created(address indexed collection);

    constructor(address _scheduler) {
        owner = msg.sender;
        scheduler = _scheduler;
    }

    function create(CreateParams calldata _params) external override nonReentrant {
        OmniseaDN404Proxy proxy = new OmniseaDN404Proxy();
        address proxyAddress = address(proxy);
        IOmniseaDN404(proxyAddress).initialize(_params, msg.sender, _manager, scheduler);
        drops[proxyAddress] = true;
        emit Created(proxyAddress);
    }

    function setManager(address manager_) external {
        require(msg.sender == owner);
        _manager = manager_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404 {
    function initialize(CreateParams memory params, address _owner, address _manager, address _scheduler) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external returns (uint256);
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function owner() external view returns (address);
    function dropsManager() external view returns (address);
    function endTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OmniseaDN404Proxy {
    fallback() external payable {
        _delegate(address(0xD6426F615d3D9E33E09CCeD64FD4588074e2ef8f));
    }

    receive() external payable {
        _delegate(address(0xD6426F615d3D9E33E09CCeD64FD4588074e2ef8f));
    }

    function _delegate(address _proxyTo) internal {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _proxyTo, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404Factory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    uint24 royaltyAmount;
    uint256 endTime;
    bool isEdition;
    uint256 premintQuantity;
}

struct MintParams {
    address to;
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
    address token;
    uint256 minToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Reentrancy guard mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unauthorized reentrant call.
    error Reentrancy();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.
    /// 9 bytes is large enough to avoid collisions with lower slots,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      REENTRANCY GUARD                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards a function from reentrancy.
    modifier nonReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
            sstore(_REENTRANCY_GUARD_SLOT, address())
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_REENTRANCY_GUARD_SLOT, codesize())
        }
    }

    /// @dev Guards a view function from read-only reentrancy.
    modifier nonReadReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }
}