// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Base Authenticator abstract contract
abstract contract Authenticator {
    bytes4 internal constant PROPOSE_SELECTOR = bytes4(keccak256("propose(address,string,(address,bytes),bytes)"));
    bytes4 internal constant VOTE_SELECTOR = bytes4(keccak256("vote(address,uint256,uint8,(uint8,bytes)[],string)"));
    bytes4 internal constant UPDATE_PROPOSAL_SELECTOR =
        bytes4(keccak256("updateProposal(address,uint256,(address,bytes),string)"));

    /// @dev Forwards a call to the target contract.
    function _call(address target, bytes4 functionSelector, bytes memory data) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = target.call(abi.encodePacked(functionSelector, data));
        if (!success) {
            // If the call failed, we revert with the propagated error message.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Authenticator } from "./Authenticator.sol";

/// @title Vanilla Authenticator
contract VanillaAuthenticator is Authenticator {
    function authenticate(address target, bytes4 functionSelector, bytes memory data) external {
        // No authentication is performed.
        _call(target, functionSelector, data);
    }
}