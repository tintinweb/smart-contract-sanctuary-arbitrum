// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CoreRef} from "../refs/CoreRef.sol";
import {IPCVGuardian} from "./IPCVGuardian.sol";
import {IPCVDeposit} from "./IPCVDeposit.sol";
import {CoreRefPausableLib} from "../libs/CoreRefPausableLib.sol";
import {TribeRoles} from "../core/TribeRoles.sol";

/// @notice PCV Guardian is a contract to safeguard protocol funds
/// by being able to withdraw whitelisted PCV deposits to an immutable safe address
contract PCVGuardian is IPCVGuardian, CoreRef {
    using CoreRefPausableLib for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    ///@notice set of whitelisted pcvDeposit addresses for withdrawal
    EnumerableSet.AddressSet private whitelistAddresses;

    ///@notice safe address where PCV funds can be withdrawn to
    address public immutable safeAddress;

    constructor(
        address _core,
        address _safeAddress,
        address[] memory _whitelistAddresses
    ) CoreRef(_core) {
        safeAddress = _safeAddress;

        // improbable to ever overflow
        unchecked {
            for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
                _addWhitelistAddress(_whitelistAddresses[i]);
            }
        }
    }

    /// @dev checks if a pcv deposit address is whitelisted, reverts if not
    modifier onlyWhitelist(address pcvDeposit) {
        require(
            isWhitelistAddress(pcvDeposit),
            "PCVGuardian: Provided address is not whitelisted"
        );
        _;
    }

    // ---------- Read-Only API ----------

    /// @notice returns true if the the provided address is a valid destination to withdraw funds from
    /// @param pcvDeposit the pcvDeposit address to check if whitelisted
    function isWhitelistAddress(address pcvDeposit)
        public
        view
        override
        returns (bool)
    {
        return whitelistAddresses.contains(pcvDeposit);
    }

    /// @notice returns all whitelisted pcvDeposit addresses
    function getWhitelistAddresses()
        public
        view
        override
        returns (address[] memory)
    {
        return whitelistAddresses.values();
    }

    // ---------- Governor-Only State-Changing API ----------

    /// @notice governor-only method to whitelist a pcvDeposit address to withdraw funds from
    /// @param pcvDeposit the address to whitelist
    function addWhitelistAddress(address pcvDeposit)
        external
        override
        onlyGovernor
    {
        _addWhitelistAddress(pcvDeposit);
    }

    /// @notice batch version of addWhiteListaddress
    /// @param _whitelistAddresses the addresses to whitelist, as calldata
    function addWhitelistAddresses(address[] calldata _whitelistAddresses)
        external
        override
        onlyGovernor
    {
        // improbable to ever overflow
        unchecked {
            for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
                _addWhitelistAddress(_whitelistAddresses[i]);
            }
        }
    }

    // ---------- Governor-Or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to remove pcvDeposit address from the whitelist to withdraw funds from
    /// @param pcvDeposit the address to remove from whitelist
    function removeWhitelistAddress(address pcvDeposit)
        external
        override
        onlyGuardianOrGovernor
    {
        _removeWhitelistAddress(pcvDeposit);
    }

    /// @notice batch version of removeWhitelistAddress
    /// @param _whitelistAddresses the addresses to remove from whitelist
    function removeWhitelistAddresses(address[] calldata _whitelistAddresses)
        external
        override
        onlyGuardianOrGovernor
    {
        // improbable to ever overflow
        unchecked {
            for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
                _removeWhitelistAddress(_whitelistAddresses[i]);
            }
        }
    }

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param amount the amount to withdraw
    function withdrawToSafeAddress(address pcvDeposit, uint256 amount)
        external
        override
        hasAnyOfThreeRoles(
            TribeRoles.GOVERNOR,
            TribeRoles.GUARDIAN,
            TribeRoles.PCV_GUARD
        )
        onlyWhitelist(pcvDeposit)
    {
        _withdrawToSafeAddress(pcvDeposit, amount);
    }

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw all at once funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    function withdrawAllToSafeAddress(address pcvDeposit)
        external
        override
        hasAnyOfThreeRoles(
            TribeRoles.GOVERNOR,
            TribeRoles.GUARDIAN,
            TribeRoles.PCV_GUARD
        )
        onlyWhitelist(pcvDeposit)
    {
        _withdrawToSafeAddress(pcvDeposit, IPCVDeposit(pcvDeposit).balance());
    }

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw an ERC20 from a pcv deposit, by calling the withdrawERC20() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    /// @param amount the amount of funds to withdraw
    function withdrawERC20ToSafeAddress(
        address pcvDeposit,
        address token,
        uint256 amount
    )
        external
        override
        hasAnyOfThreeRoles(
            TribeRoles.GOVERNOR,
            TribeRoles.GUARDIAN,
            TribeRoles.PCV_GUARD
        )
        onlyWhitelist(pcvDeposit)
    {
        _withdrawERC20ToSafeAddress(pcvDeposit, token, amount);
    }

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw all of an ERC20 balance from a pcv deposit, by calling the withdrawERC20() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    function withdrawAllERC20ToSafeAddress(address pcvDeposit, address token)
        external
        override
        hasAnyOfThreeRoles(
            TribeRoles.GOVERNOR,
            TribeRoles.GUARDIAN,
            TribeRoles.PCV_GUARD
        )
        onlyWhitelist(pcvDeposit)
    {
        _withdrawERC20ToSafeAddress(
            pcvDeposit,
            token,
            IERC20(token).balanceOf(pcvDeposit)
        );
    }

    // ---------- Internal Functions ----------

    function _withdrawToSafeAddress(address pcvDeposit, uint256 amount)
        internal
    {
        if (pcvDeposit._paused()) {
            pcvDeposit._unpause();
            IPCVDeposit(pcvDeposit).withdraw(safeAddress, amount);
            pcvDeposit._pause();
        } else {
            IPCVDeposit(pcvDeposit).withdraw(safeAddress, amount);
        }

        emit PCVGuardianWithdrawal(pcvDeposit, amount);
    }

    function _withdrawERC20ToSafeAddress(
        address pcvDeposit,
        address token,
        uint256 amount
    ) internal {
        IPCVDeposit(pcvDeposit).withdrawERC20(token, safeAddress, amount);
        emit PCVGuardianERC20Withdrawal(pcvDeposit, token, amount);
    }

    function _addWhitelistAddress(address pcvDeposit) internal {
        require(
            whitelistAddresses.add(pcvDeposit),
            "PCVGuardian: Failed to add address to whitelist"
        );
        emit WhitelistAddressAdded(pcvDeposit);
    }

    function _removeWhitelistAddress(address pcvDeposit) internal {
        require(
            whitelistAddresses.remove(pcvDeposit),
            "PCVGuardian: Failed to remove address from whitelist"
        );
        emit WhitelistAddressRemoved(pcvDeposit);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private immutable _core;
    IVolt private immutable _volt;
    IERC20 private immutable _vcon;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    constructor(address coreAddress) {
        _core = ICore(coreAddress);

        _volt = ICore(coreAddress).volt();
        _vcon = ICore(coreAddress).vcon();

        _setContractAdminRole(ICore(coreAddress).GOVERN_ROLE());
    }

    function _initialize() internal {} // no-op for backward compatibility

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) || isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyGovernorOrGuardianOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
                _core.isGuardian(msg.sender) ||
                isContractAdmin(msg.sender),
            "CoreRef: Caller is not governor or guardian or admin"
        );
        _;
    }

    // Named onlyTribeRole to prevent collision with OZ onlyRole modifier
    modifier onlyTribeRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }

    // Modifiers to allow any combination of roles
    modifier hasAnyOfTwoRoles(bytes32 role1, bytes32 role2) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfThreeRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFourRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier hasAnyOfFiveRoles(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        bytes32 role4,
        bytes32 role5
    ) {
        require(
            _core.hasRole(role1, msg.sender) ||
                _core.hasRole(role2, msg.sender) ||
                _core.hasRole(role3, msg.sender) ||
                _core.hasRole(role4, msg.sender) ||
                _core.hasRole(role5, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyVolt() {
        require(msg.sender == address(_volt), "CoreRef: Caller is not VOLT");
        _;
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole)
        external
        override
        onlyGovernor
    {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin)
        public
        view
        override
        returns (bool)
    {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function volt() public view override returns (IVolt) {
        return _volt;
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function vcon() public view override returns (IERC20) {
        return _vcon;
    }

    /// @notice volt balance of contract
    /// @return volt amount held
    function voltBalance() public view override returns (uint256) {
        return _volt.balanceOf(address(this));
    }

    /// @notice vcon balance of contract
    /// @return vcon amount held
    function vconBalance() public view override returns (uint256) {
        return _vcon.balanceOf(address(this));
    }

    function _burnVoltHeld() internal {
        _volt.burn(voltBalance());
    }

    function _mintVolt(address to, uint256 amount) internal virtual {
        if (amount != 0) {
            _volt.mint(to, amount);
        }
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(
            oldContractAdminRole,
            newContractAdminRole
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title IPCVGuardian
/// @notice an interface for defining how the PCVGuardian functions
/// @dev any implementation of this contract should be granted the roles of Guardian and PCVController in order to work correctly
interface IPCVGuardian {
    // ---------- Events ----------

    event WhitelistAddressAdded(address indexed pcvDeposit);

    event WhitelistAddressRemoved(address indexed pcvDeposit);

    event PCVGuardianWithdrawal(address indexed pcvDeposit, uint256 amount);

    event PCVGuardianERC20Withdrawal(
        address indexed pcvDeposit,
        address indexed token,
        uint256 amount
    );

    // ---------- Read-Only API ----------

    /// @notice returns true if the pcvDeposit address is whitelisted
    /// @param pcvDeposit the address to check
    function isWhitelistAddress(address pcvDeposit)
        external
        view
        returns (bool);

    /// @notice returns all whitelisted addresses
    function getWhitelistAddresses() external view returns (address[] memory);

    // ---------- Governor-Only State-Changing API ----------

    /// @notice governor-only method to whitelist a pcvDeposit address to withdraw funds from
    /// @param pcvDeposit the address to whitelist
    function addWhitelistAddress(address pcvDeposit) external;

    /// @notice batch version of addWhitelistAddress
    /// @param whitelistAddresses the pcvDespoit addresses to whitelist, as calldata
    function addWhitelistAddresses(address[] calldata whitelistAddresses)
        external;

    // ---------- Governor-or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to remove pcvDeposit address from the whitelist to withdraw funds from
    /// @param pcvDeposit the address to un-whitelist
    function removeWhitelistAddress(address pcvDeposit) external;

    /// @notice batch version of removeWhitelistAddress
    /// @param whitelistAddresses the addresses to un-whitelist
    function removeWhitelistAddresses(address[] calldata whitelistAddresses)
        external;

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param amount the amount to withdraw
    function withdrawToSafeAddress(address pcvDeposit, uint256 amount) external;

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw all at once funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    function withdrawAllToSafeAddress(address pcvDeposit) external;

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw an ERC20 from a pcv deposit, by calling the withdrawERC20() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    /// @param amount the amount of funds to withdraw
    function withdrawERC20ToSafeAddress(
        address pcvDeposit,
        address token,
        uint256 amount
    ) external;

    /// @notice governor-or-guardian-or-pcv-guard method to withdraw all of an ERC20 balance from a pcv deposit, by calling the withdrawERC20() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param token the address of the token to withdraw
    function withdrawAllERC20ToSafeAddress(address pcvDeposit, address token)
        external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPCVDepositBalances.sol";

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH(address payable to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {CoreRef} from "../refs/CoreRef.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @title PausableLib
/// @notice PausableLib is a library that can be used to pause and unpause contracts, among other utilities.
/// @dev This library should only be used on contracts that implement CoreRef.
library CoreRefPausableLib {
    function _pause(address _pauseableCoreRefAddress) internal {
        CoreRef(_pauseableCoreRefAddress).pause();
    }

    function _unpause(address _pauseableCoreRefAddress) internal {
        CoreRef(_pauseableCoreRefAddress).unpause();
    }

    function _paused(address _pauseableCoreRefAddres)
        internal
        view
        returns (bool)
    {
        return CoreRef(_pauseableCoreRefAddres).paused();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 @title Tribe DAO ACL Roles
 @notice Holds a complete list of all roles which can be held by contracts inside Tribe DAO.
         Roles are broken up into 3 categories:
         * Major Roles - the most powerful roles in the Tribe DAO which should be carefully managed.
         * Admin Roles - roles with management capability over critical functionality. Should only be held by automated or optimistic mechanisms
         * Minor Roles - operational roles. May be held or managed by shorter optimistic timelocks or trusted multisigs.
 */
library TribeRoles {
    /*///////////////////////////////////////////////////////////////
                                 Major Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice the ultimate role of Tribe. Controls all other roles and protocol functionality.
    bytes32 internal constant GOVERNOR = keccak256("GOVERN_ROLE");

    /// @notice the protector role of Tribe. Admin of pause, veto, revoke, and minor roles
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /// @notice the role which can arbitrarily move PCV in any size from any contract
    bytes32 internal constant PCV_CONTROLLER = keccak256("PCV_CONTROLLER_ROLE");

    /// @notice can mint FEI arbitrarily
    bytes32 internal constant MINTER = keccak256("MINTER_ROLE");

    ///@notice is able to withdraw whitelisted PCV deposits to a safe address
    bytes32 internal constant PCV_GUARD = keccak256("PCV_GUARD_ROLE");

    /*///////////////////////////////////////////////////////////////
                                 Admin Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice can manage the majority of Tribe protocol parameters. Sets boundaries for MINOR_PARAM_ROLE.
    bytes32 internal constant PARAMETER_ADMIN = keccak256("PARAMETER_ADMIN");

    /// @notice admin of PCVGuardian
    bytes32 internal constant PCV_GUARDIAN_ADMIN =
        keccak256("PCV_GUARDIAN_ADMIN_ROLE");

    /// @notice manages the granting and revocation of PCV Guard roles
    bytes32 internal constant PCV_GUARD_ADMIN =
        keccak256("PCV_GUARD_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                                 Minor Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice capable of adding an address to multi rate limited
    bytes32 internal constant ADD_MINTER_ROLE = keccak256("ADD_MINTER_ROLE");

    /// @notice capable of changing PCV Deposit and Global Rate Limited Minter in the PSM
    bytes32 internal constant PSM_ADMIN_ROLE = keccak256("PSM_ADMIN_ROLE");
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(
        bytes32 indexed oldContractAdminRole,
        bytes32 indexed newContractAdminRole
    );

    // ----------- Governor only state changing api -----------

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);

    function voltBalance() external view returns (uint256);

    function vconBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IPermissions} from "./IPermissions.sol";
import {IVolt, IERC20} from "../volt/IVolt.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------
    event VoltUpdate(IERC20 indexed _volt);
    event VconUpdate(IERC20 indexed _vcon);

    // ----------- Getters -----------

    function volt() external view returns (IVolt);

    function vcon() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IPermissionsRead.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl, IPermissionsRead {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IVolt is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title Permissions Read interface
/// @author Fei Protocol
interface IPermissionsRead {
    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title a PCV Deposit interface for only balance getters
/// @author Fei Protocol
interface IPCVDepositBalances {
    // ----------- Getters -----------

    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndVolt() external view returns (uint256, uint256);
}