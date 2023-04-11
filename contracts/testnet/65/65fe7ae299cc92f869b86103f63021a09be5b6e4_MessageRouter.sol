// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";

import {MessageLib} from "./libraries/MessageLib.sol";

import {IIndexClient} from "./interfaces/IIndexClient.sol";
import {BridgingExecutor} from "./interfaces/BridgingExecutor.sol";

interface MessageRouterErrors {
    error MessageRouterBridgingImplementationNotFound(uint8 action);
}

contract MessageRouter is MessageRouterErrors, Owned {
    struct BridgingImplementationInfo {
        uint8 action;
        address bridgingImplementation;
    }

    /// @dev action => BridgingImplementation
    mapping(uint8 => address) internal bridgingImplementations;

    constructor(address owner) Owned(owner) {}

    function setBridgingImplementations(BridgingImplementationInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            BridgingImplementationInfo calldata info = infos[i];
            bridgingImplementations[info.action] = info.bridgingImplementation;
        }
    }

    function generateTargets(MessageLib.Payload calldata payload, address receiver)
        external
        view
        returns (MessageLib.Target[] memory targets)
    {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload, receiver);
    }

    function estimateFee(MessageLib.Payload calldata payload, address receiver)
        external
        view
        returns (uint256 gasFee)
    {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        MessageLib.Target[] memory targets =
            BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload, receiver);
        uint256 length = targets.length;
        for (uint256 i; i < length;) {
            gasFee += targets[i].value;
            unchecked {
                i = i + 1;
            }
        }
    }

    function getBridgingImplementation(uint8 action) internal view returns (address) {
        address bridgingImplementation = bridgingImplementations[action];
        if (bridgingImplementation == address(0)) {
            revert MessageRouterBridgingImplementationNotFound(action);
        }
        return bridgingImplementation;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "../libraries/MessageLib.sol";

interface BridgingExecutor {
    function getTargetExecutionData(MessageLib.Payload calldata payload, address receiver)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

/// @title IIndexClient interface
/// @notice Contains index minting and burning logic
interface IIndexClient {
    /// @notice Emits each time when index is minted
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @notice Emits each time when index is burnt
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /// @notice Deposits reserve assets and mints index
    ///
    /// @param reserveAssets Amount of reserve asset
    /// @param receiver Address of index receiver
    ///
    /// @param indexShares Amount of minted index
    function deposit(uint256 reserveAssets, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 indexShares);

    /// @notice Burns index and withdraws reserveAssets
    ///
    /// @param indexShares Amount of index to burn
    /// @param receiver Address of assets receiver
    /// @param owner Address of index owner
    /// @param subIndexes List of SubIndexes
    ///
    /// @param reserveAssets Amount of withdrawn assets
    function redeem(
        uint256 indexShares,
        address receiver,
        address owner,
        uint96 reserveCached,
        bytes calldata redeemData,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external payable returns (uint256 reserveAssets);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library MessageLib {
    struct Message {
        uint8 action;
        address receiver;
        bytes messageBody;
    }

    struct Target {
        uint256 value;
        address target;
        bytes data;
    }

    struct Payload {
        bytes body;
        uint8 action;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_YIELD = 2;
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