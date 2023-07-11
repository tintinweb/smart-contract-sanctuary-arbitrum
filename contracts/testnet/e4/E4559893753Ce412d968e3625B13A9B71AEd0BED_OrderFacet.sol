// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/Clones.sol";
import { PaymentStorage } from "../storage/PaymentStorage.sol";
import { AccessControlStorage } from "../storage/AccessControlStorage.sol";
import { ITemplate } from "../interfaces/ITemplate.sol";
import { Calculator } from  "../internals/Calculator.sol";
import "../libraries/Structs.sol";

contract OrderFacet is Calculator {

    error InvalidAmount();
    error InvalidServiceID();
    error AddressIsZero();
    error AccountTypeLimit();
    error ArrayMismatch();

    event SubscribeService(bytes32 indexed id, address buyer, address seller, uint security);
    event OneTimePayment(bytes32 indexed id, address receiver, address token, uint amount, uint fee);
    event SubscriptionBilling(bytes32[] ids, uint[] amounts, uint[] fees);

    function getPredictAddress(bytes32 _id) external view returns (address) {
        return Clones.predictDeterministicAddress(PaymentStorage.layout().template, _id);
    }

    function estimateServiceFee(uint _amount) external view returns (uint) {
        if (_amount == 0) return 0;
        return _getServiceFee(msg.sender, _amount);
    }

    function subscribe(bytes32 _id, address _token, address _buyer, address _seller) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_token == address(0)) revert AddressIsZero();
        if (_buyer == address(0)) revert AddressIsZero();
        // seller must be busniess, busniess address will not be zero
        // if (_seller == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();

        ITemplate template = ITemplate(Clones.cloneDeterministic(PaymentStorage.layout().template, _id));
        uint amount = template.withdrawToken(_token, address(this));
        _subscribe(_id, _buyer, _seller, amount);
    }

    function settle(bytes32 _id, address _token, address _receiver) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_token == address(0)) revert AddressIsZero();
        if (_receiver == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();

        ITemplate template = ITemplate(Clones.cloneDeterministic(layout.template, _id));
        uint amount = template.withdrawToken(_token, address(this));
        uint fee = _getServiceFee(_receiver, amount);

        unchecked {
            layout.userAccounts[_receiver].balance += (amount - fee);
            layout.serviceIncome += fee;
        }

        emit OneTimePayment(_id, _receiver, _token, amount, fee);
    }

    function billing(
        bytes32[] calldata _ids,
        uint[] calldata _amounts
    ) external {
        AccessControlStorage.enforceIsOwner();

        uint len = _ids.length;
        if (len != _amounts.length) revert ArrayMismatch();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        uint userBalance;
        uint userSecurity;
        uint remainingAmount;

        bytes32[] memory subIds = new bytes32[](len);
        uint[] memory bills = new uint[](len);
        uint[] memory fees = new uint[](len);
        
        unchecked {
            for (uint i; i < len; ) {
                bytes32 id = _ids[i];
                if (id == bytes32(0)) revert InvalidServiceID();

                Service storage service = layout.subscription[id];
                address buyer = service.buyer;
                address seller = service.seller;
                uint amount = _amounts[i];
                if (amount == 0) revert InvalidAmount();
                uint fee = _getServiceFee(seller, amount);

                Account storage buyerAccount = layout.userAccounts[buyer];
                userBalance = buyerAccount.balance;
                userSecurity = service.security;

                if (userBalance + userSecurity < amount) continue;

                if (userBalance < amount) {
                    remainingAmount = amount - userBalance;
                    buyerAccount.balance = 0;
                    service.security = userSecurity - remainingAmount;
                } else {
                    buyerAccount.balance -= amount;
                }

                service.lastConsume = amount;
                layout.userAccounts[seller].balance += (amount - fee);
                layout.serviceIncome += fee;

                subIds[i] = id;
                bills[i] = amount;
                fees[i] = fee;

                ++i;
            }
        }

        emit SubscriptionBilling(subIds, bills, fees);
    }

    function _subscribe(
        bytes32 _id,
        address _buyer,
        address _seller,
        uint _amount
    ) internal {
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (layout.subscription[_id].buyer != address(0)) revert InvalidServiceID();
        if (layout.userAccounts[_seller].accountType != AccountType.Business) revert AccountTypeLimit();

        Service storage service = layout.subscription[_id];
        service.buyer = _buyer;
        service.seller = _seller;
        unchecked {
            service.security = _amount;
            service.lastConsume = _amount / 2;
        }
        
        emit SubscribeService(_id, _buyer, _seller, _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITemplate {

    function withdrawToken(address _token, address _target) external returns (uint amount);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { PaymentStorage } from "../storage/PaymentStorage.sol";

abstract contract Calculator {
    
    function _getServiceFee(address _user, uint _amount) internal view returns (uint) {
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        uint baseFee = layout.baseFee;
        if (baseFee == 0) return 0;
        unchecked {
            uint discount = layout.userAccounts[_user].feeDiscount;

            if (discount == 0) {
                return _amount * baseFee / 100_000;
            }

            return _amount * baseFee * discount / 10_000_000;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum AccountType {
    Personal,
    Business
}

// user account
struct Account {
    AccountType accountType;
    uint balance;
    uint feeDiscount;
}

struct Service {
    bool terminated;
    address buyer;
    address seller;
    uint security;
    uint lastConsume;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library AccessControlStorage {

    using EnumerableSet for EnumerableSet.AddressSet;

    error NotRoleAuthorizedError(bytes32, address user);

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT = keccak256('contracts.storage.AccessControl');

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function setContractOwner(address account) internal {
        layout().roles[DEFAULT_ADMIN_ROLE].members.add(account);
        emit RoleGranted(DEFAULT_ADMIN_ROLE, account, msg.sender);
    }

    function enforceIsOwner() internal view {
        if (!layout().roles[DEFAULT_ADMIN_ROLE].members.contains(msg.sender)) 
            revert NotRoleAuthorizedError(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function enforceIsRole(bytes32 role) internal view {
        if (!layout().roles[role].members.contains(msg.sender)) 
            revert NotRoleAuthorizedError(role, msg.sender);
    }

    function enforceIsRole(bytes32 role, address user) internal view {
        if (!layout().roles[role].members.contains(user)) 
            revert NotRoleAuthorizedError(role, user);
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../libraries/Structs.sol";

library PaymentStorage {

    bytes32 internal constant STORAGE_SLOT = keccak256('contracts.storage.Payment');

    struct Layout {
        address usdt;
        address template;
        uint baseFee;
        uint serviceIncome;
        mapping(address => Account) userAccounts;
        mapping(bytes32 => Service) subscription;

        uint[60] _gaps;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}