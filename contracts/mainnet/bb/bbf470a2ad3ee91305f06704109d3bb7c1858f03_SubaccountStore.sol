// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";

import {StoreController} from "./StoreController.sol";
import {Subaccount} from "../Subaccount.sol";

contract SubaccountStore is StoreController {
    mapping(address => Subaccount) public subaccountMap;

    address public operator;

    constructor(Authority _authority, address _setter) StoreController(_authority, _setter) {}

    function getSubaccount(address _address) external view returns (Subaccount) {
        return subaccountMap[_address];
    }

    function setSubaccount(address _address, Subaccount _subaccount) external isSetter {
        subaccountMap[_address] = _subaccount;
    }

    function removeSubaccount(address _address) external isSetter {
        delete subaccountMap[_address];
    }

    function setOperator(address _address) external isSetter {
        operator = _address;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Auth, Authority} from "@solmate/contracts/auth/Auth.sol";

abstract contract StoreController is Auth {
    address public setter;

    modifier isSetter() {
        if (setter != msg.sender) revert Unauthorized(setter, msg.sender);
        _;
    }

    constructor(Authority _authority, address _setter) Auth(address(0), _authority) {
        setter = _setter;

        emit AssignSetter(address(0), _setter, block.timestamp);
    }

    function switchSetter(address nextSetter) external requiresAuth {
        address oldSetter = setter;
        setter = nextSetter;

        emit AssignSetter(oldSetter, nextSetter, block.timestamp);
    }

    event AssignSetter(address from, address to, uint timestamp);

    error Unauthorized(address currentSetter, address sender);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {SubaccountStore} from "./store/SubaccountStore.sol";

contract Subaccount {
    SubaccountStore store;
    address public account;

    constructor(SubaccountStore _store, address _account) {
        store = _store;
        account = _account;
    }

    modifier onlyOperator() {
        if (msg.sender != store.operator()) revert Subaccount__NotCallbackCaller();
        _;
    }

    function execute(address _contract, bytes calldata _data) external payable onlyOperator returns (bool _success, bytes memory _returnData) {
        return _contract.call{value: msg.value, gas: gasleft()}(_data);
    }

    error Subaccount__NotCallbackCaller();
}