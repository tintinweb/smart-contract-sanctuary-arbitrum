// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

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

pragma solidity 0.8.17;

import "./adapters/interfaces/IEWhitelist.sol";
import "../interfaces/IAuthority.sol";
import "../../utils/storageSlot/StorageSlot.sol";

/// @title EWhitelist - Allows whitelisting of tokens.
/// @author Gabriele Rigo - <[email protected]>
/// @notice This contract has its own storage, which could potentially clash with pool storage if the allocated slot were already used by the implementation.
/// Warning: careful with upgrades as pool only accesses isWhitelistedToken view method. Other methods are locked and should never be approved by governance.
contract EWhitelist is IEWhitelist {
    bytes32 internal constant _EWHITELIST_TOKEN_WHITELIST_SLOT =
        0x03de6a299bc35b64db5b38a8b5dbbc4bab6e4b5a493067f0fbe40d83350a610f;

    address private immutable authority;

    struct WhitelistSlot {
        mapping(address => bool) isWhitelisted;
    }

    modifier onlyAuthorized() {
        _assertCallerIsAuthorized();
        _;
    }

    constructor(address newAuthority) {
        assert(_EWHITELIST_TOKEN_WHITELIST_SLOT == bytes32(uint256(keccak256("ewhitelist.token.whitelist")) - 1));
        authority = newAuthority;
    }

    /// @inheritdoc IEWhitelist
    function whitelistToken(address token) public override onlyAuthorized {
        require(_isContract(token), "EWHITELIST_INPUT_NOT_CONTRACT_ERROR");
        require(!_getWhitelistSlot().isWhitelisted[token], "EWHITELIST_TOKEN_ALREADY_WHITELISTED_ERROR");
        _getWhitelistSlot().isWhitelisted[token] = true;
        emit Whitelisted(token, true);
    }

    /// @inheritdoc IEWhitelist
    function removeToken(address token) public override onlyAuthorized {
        require(_getWhitelistSlot().isWhitelisted[token], "EWHITELIST_TOKEN_ALREADY_REMOVED_ERROR");
        delete (_getWhitelistSlot().isWhitelisted[token]);
        emit Whitelisted(token, false);
    }

    /// @inheritdoc IEWhitelist
    function batchUpdateTokens(address[] calldata tokens, bool[] memory whitelisted) external override {
        for (uint256 i = 0; i < tokens.length; i++) {
            // if upgrading (to i.e. using an internal method), always assert only authority can call batch method
            whitelisted[i] == true ? whitelistToken(tokens[i]) : removeToken(tokens[i]);
        }
    }

    /// @inheritdoc IEWhitelist
    function isWhitelistedToken(address token) external view override returns (bool) {
        return _getWhitelistSlot().isWhitelisted[token];
    }

    /// @inheritdoc IEWhitelist
    function getAuthority() public view override returns (address) {
        return authority;
    }

    function _getWhitelistSlot() internal pure returns (WhitelistSlot storage s) {
        assembly {
            s.slot := _EWHITELIST_TOKEN_WHITELIST_SLOT
        }
    }

    function _assertCallerIsAuthorized() private view {
        require(IAuthority(getAuthority()).isWhitelister(msg.sender), "EWHITELIST_CALLER_NOT_WHITELISTER_ERROR");
    }

    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

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

pragma solidity >=0.8.0 <0.9.0;

/// @title EWhitelist Interface - Allows interaction with the whitelist extension contract.
/// @author Gabriele Rigo - <[email protected]>
interface IEWhitelist {
    /// @notice Emitted when a token is whitelisted or removed.
    /// @param token Address pf the target token.
    /// @param isWhitelisted Boolean the token is added or removed.
    event Whitelisted(address indexed token, bool isWhitelisted);

    /// @notice Allows a whitelister to whitelist a token.
    /// @param token Address of the target token.
    function whitelistToken(address token) external;

    /// @notice Allows a whitelister to remove a token.
    /// @param token Address of the target token.
    function removeToken(address token) external;

    /// @notice Allows a whitelister to whitelist/remove a list of tokens.
    /// @param tokens Address array to tokens.
    /// @param whitelisted Bollean array the token is to be whitelisted or removed.
    function batchUpdateTokens(address[] calldata tokens, bool[] memory whitelisted) external;

    /// @notice Returns whether a token has been whitelisted.
    /// @param token Address of the target token.
    /// @return Boolean the token is whitelisted.
    function isWhitelistedToken(address token) external view returns (bool);

    /// @notice Returns the address of the authority contract.
    /// @return Address of the authority contract.
    function getAuthority() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

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

pragma solidity >=0.7.0 <0.9.0;

/// @title Authority Interface - Allows interaction with the Authority contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IAuthority {
    /// @notice Adds a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionAdded(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the  method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionRemoved(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes an approved method.
    /// @dev Removes a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event RemovedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    /// @notice Approves a new method.
    /// @dev Adds a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter  Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event WhitelistedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    enum Role {
        ADAPTER,
        FACTORY,
        WHITELISTER
    }

    /// @notice Mapping of permission type to bool.
    /// @param Mapping of type of permission to bool is authorized.
    struct Permission {
        mapping(Role => bool) authorized;
    }

    /// @notice Allows a whitelister to whitelist a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    /// @notice We do not save list of approved as better queried by events.
    function addMethod(bytes4 selector, address adapter) external;

    /// @notice Allows a whitelister to remove a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    function removeMethod(bytes4 selector, address adapter) external;

    /// @notice Allows owner to set extension adapter address.
    /// @param adapter Address of the target adapter.
    /// @param isWhitelisted Bool whitelisted.
    function setAdapter(address adapter, bool isWhitelisted) external;

    /// @notice Allows an admin to set factory permission.
    /// @param factory Address of the target factory.
    /// @param isWhitelisted Bool whitelisted.
    function setFactory(address factory, bool isWhitelisted) external;

    /// @notice Allows the owner to set whitelister permission.
    /// @param whitelister Address of the whitelister.
    /// @param isWhitelisted Bool whitelisted.
    /// @notice Whitelister permission is required to approve methods in extensions adapter.
    function setWhitelister(address whitelister, bool isWhitelisted) external;

    /// @notice Returns the address of the adapter associated to the signature.
    /// @param selector Hex of the method signature.
    /// @return Address of the adapter.
    function getApplicationAdapter(bytes4 selector) external view returns (address);

    /// @notice Provides whether a factory is whitelisted.
    /// @param target Address of the target factory.
    /// @return Bool is whitelisted.
    function isWhitelistedFactory(address target) external view returns (bool);

    /// @notice Provides whether an address is whitelister.
    /// @param target Address of the target whitelister.
    /// @return Bool is whitelisted.
    function isWhitelister(address target) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}