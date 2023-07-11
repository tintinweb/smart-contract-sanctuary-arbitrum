// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PaymentStorage } from "../storage/PaymentStorage.sol";
import { AccessControlStorage } from "../storage/AccessControlStorage.sol";
import { Calculator } from  "../internals/Calculator.sol";
import "../libraries/Structs.sol";

contract ManagerFacet is Calculator {

    error AddressIsZero();
    error InvalidAmount();
    error InvalidBaseFee();
    error InvalidFeeDiscount();
    error InvalidServiceID();
    error UnauthService();
    error ServiceTerminated();
    error InsufficientBalance();

    event BaseFeeChanged(uint feeRatio);
    event FeeDiscountChanged(address user, uint discountRatio);
    event TokenRegisterChanged(address addr, bool enable);
    event TemplateAddressChanged(address addr);
    event WithdrawServiceIncome(address indexed caller, address token, address to, uint amount);
    event AccountTypeChanged(address indexed user, uint indexed accountType);
    event TerminateService(bytes32 indexed id, address indexed caller, address buyer, address seller, uint amount, uint fee);

    function isRegisteredToken(address _token) external view returns (bool) {
        return PaymentStorage.layout().registeredToken[_token];
    }

    function getTemplateAddress() external view returns (address) {
        return PaymentStorage.layout().template;
    }

    function getBaseFee() external view returns (uint) {
        return PaymentStorage.layout().baseFee;
    }

    function getProtocolIncome(address _token) external view returns (uint) {
        return PaymentStorage.layout().protocolIncome[_token];
    }

    function registerToken(address _token) external {
        if (_token == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();
        
        PaymentStorage.layout().registeredToken[_token] = true;
        emit TokenRegisterChanged(_token, true);
    }

    function unregisterToken(address _token) external {
        if (_token == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();
        
        PaymentStorage.layout().registeredToken[_token] = false;
        emit TokenRegisterChanged(_token, false);
    }

    function setTemplateAddress(address _addr) external {
        if (_addr == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();

        PaymentStorage.layout().template = _addr;
        emit TemplateAddressChanged(_addr);
    }

    function setBaseFee(uint _feeRatio) external {
        if (_feeRatio > 100000) revert InvalidBaseFee();
        AccessControlStorage.enforceIsOwner();

        PaymentStorage.layout().baseFee = _feeRatio;
        emit BaseFeeChanged(_feeRatio);
    }

    function setUserFeeDiscount(address _user, uint _discount) external {
        if (_user == address(0)) revert AddressIsZero();
        if (_discount > 100) revert InvalidFeeDiscount();
        AccessControlStorage.enforceIsOwner();

        PaymentStorage.layout().userAccounts[_user].feeDiscount = _discount;
        emit FeeDiscountChanged(_user, _discount);
    }

    function withdrawProtocolIncome(address _token, address _to, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        AccessControlStorage.enforceIsOwner();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (_amount > layout.protocolIncome[_token]) revert InsufficientBalance();

        unchecked {
            layout.protocolIncome[_token] -= _amount;
        }
        IERC20(_token).transfer(_to, _amount);

        emit WithdrawServiceIncome(msg.sender, _token, _to, _amount);
    }

    function setAccountType(address _user, AccountType _type) external {
        if (_user == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();

        PaymentStorage.layout().userAccounts[_user].accountType = _type;
        emit AccountTypeChanged(_user, uint(_type));
    }

    function terminateByBusiness(bytes32 _id, uint _amount) external {
        _terminate(_id, _amount, false);
    }

    function terminateByOwner(bytes32 _id, uint _amount) external {
        _terminate(_id, _amount, true);
    }

    function _terminate(
        bytes32 _id,
        uint _amount,
        bool _force
    ) internal {
        if (_id == bytes32(0)) revert InvalidServiceID();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];

        if (service.terminated) revert ServiceTerminated();

        if (_force) {
            AccessControlStorage.enforceIsOwner();
        } else {
            if (service.seller != msg.sender) revert UnauthService();
        }

        // avoid mutating original value
        uint deposit = service.security;
        if (deposit < _amount) revert InsufficientBalance();

        uint fee;
        address token = service.token;
        // Overflow not possible: the sum of all balances is capped by usdt totalSupply, and the sum is preserved by
        unchecked {
            if (_amount == 0) {
                layout.userAccounts[service.buyer].balances[token] += deposit;
                service.security = 0;
            } else {
                uint remaining = deposit - _amount;
                fee = _getServiceFee(service.seller, _amount);
                layout.userAccounts[service.buyer].balances[token] += remaining;
                layout.userAccounts[service.seller].balances[token] += (_amount - fee);
                layout.protocolIncome[token] += fee;
                service.security = 0;
            }
        }
        service.terminated = true;
        
        emit TerminateService(_id, msg.sender, service.buyer, service.seller, _amount, fee);
    }

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
    uint feeDiscount;
    mapping(address => uint) balances;
}

struct Service {
    bool terminated;
    address token;
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
        address template;
        uint baseFee;
        mapping(address => bool) registeredToken;
        mapping(address => uint) protocolIncome;
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