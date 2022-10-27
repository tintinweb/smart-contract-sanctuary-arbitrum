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

pragma solidity 0.8.17;

import {OwnedUninitialized as Owned} from "../../utils/owned/OwnedUninitialized.sol";
import {IAuthority} from "../interfaces/IAuthority.sol";

/// @title Authority - Allows to set up the base rules of the protocol.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract Authority is Owned, IAuthority {
    mapping(bytes4 => address) private _adapterBySelector;
    mapping(address => Permission) private _permission;
    mapping(Role => address[]) private _roleToList;

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "AUTHORITY_SENDER_NOT_WHITELISTER_ERROR");
        _;
    }

    constructor(address newOwner) {
        owner = newOwner;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @inheritdoc IAuthority
    function addMethod(bytes4 selector, address adapter) external override onlyWhitelister {
        require(_permission[adapter].authorized[Role.ADAPTER], "ADAPTER_NOT_WHITELISTED_ERROR");
        require(_adapterBySelector[selector] == address(0), "SELECTOR_EXISTS_ERROR");
        _adapterBySelector[selector] = adapter;
        emit WhitelistedMethod(msg.sender, adapter, selector);
    }

    /// @inheritdoc IAuthority
    function removeMethod(bytes4 selector, address adapter) external override onlyWhitelister {
        require(_adapterBySelector[selector] != address(0), "AUTHORITY_METHOD_NOT_APPROVED_ERROR");
        delete _adapterBySelector[selector];
        emit RemovedMethod(msg.sender, adapter, selector);
    }

    /// @inheritdoc IAuthority
    function setWhitelister(address whitelister, bool isWhitelisted) external override onlyOwner {
        _changePermission(whitelister, isWhitelisted, Role.WHITELISTER);
    }

    /// @inheritdoc IAuthority
    function setAdapter(address adapter, bool isWhitelisted) external override onlyOwner {
        _changePermission(adapter, isWhitelisted, Role.ADAPTER);
    }

    /// @inheritdoc IAuthority
    function setFactory(address factory, bool isWhitelisted) external override onlyOwner {
        _changePermission(factory, isWhitelisted, Role.FACTORY);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IAuthority
    function isWhitelistedFactory(address target) external view override returns (bool) {
        return _permission[target].authorized[Role.FACTORY];
    }

    function getApplicationAdapter(bytes4 selector) external view override returns (address) {
        return _adapterBySelector[selector];
    }

    /// @inheritdoc IAuthority
    function isWhitelister(address target) public view override returns (bool) {
        return _permission[target].authorized[Role.WHITELISTER];
    }

    /*
     * PRIVATE METHODS
     */
    function _changePermission(
        address target,
        bool isWhitelisted,
        Role role
    ) private {
        require(target != address(0), "AUTHORITY_TARGET_NULL_ADDRESS_ERROR");
        if (isWhitelisted) {
            require(!_permission[target].authorized[role], "ALREADY_WHITELISTED_ERROR");
            _permission[target].authorized[role] = isWhitelisted;
            _roleToList[role].push(target);
            emit PermissionAdded(msg.sender, target, uint8(role));
        } else {
            require(_permission[target].authorized[role], "NOT_ALREADY_WHITELISTED");
            delete _permission[target].authorized[role];
            uint256 length = _roleToList[role].length;
            for (uint256 i = 0; i < length; i++) {
                if (_roleToList[role][i] == target) {
                    _roleToList[role][i] = _roleToList[role][length - 1];
                    _roleToList[role].pop();
                    emit PermissionRemoved(msg.sender, target, uint8(role));

                    break;
                }
            }
        }
    }
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

pragma solidity >=0.7.0 <0.9.0;

/// @title Rigoblock V3 Pool Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IOwnedUninitialized {
    /// @notice Emitted when new owner is set.
    /// @param old Address of the previous owner.
    /// @param current Address of the new owner.
    event NewOwner(address indexed old, address indexed current);

    /// @notice Allows current owner to set a new owner address.
    /// @dev Method restricted to owner.
    /// @param newOwner Address of the new owner.
    function setOwner(address newOwner) external;

    /// @notice Returns the address of the owner.
    /// @return Address of the owner.
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

import {IOwnedUninitialized} from "./IOwnedUninitialized.sol";

abstract contract OwnedUninitialized is IOwnedUninitialized {
    /// @inheritdoc IOwnedUninitialized
    address public override owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNED_CALLER_IS_NOT_OWNER_ERROR");
        _;
    }

    /// @inheritdoc IOwnedUninitialized
    function setOwner(address newOwner) public override onlyOwner {
        require(newOwner != address(0));
        address oldOWner = newOwner;
        owner = newOwner;
        emit NewOwner(oldOWner, newOwner);
    }
}