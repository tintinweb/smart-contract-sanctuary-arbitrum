// solhint-disable no-empty-blocks
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {AccessControlEnumerableUpgradeable} from "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";
import {ERC20Upgradeable} from "kresko-lib/token/ERC20Upgradeable.sol";
import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IERC165} from "vendor/IERC165.sol";
import {PercentageMath} from "libs/PercentageMath.sol";
import {Percents, Role} from "common/Constants.sol";
import {Errors} from "common/Errors.sol";
import {IKreskoAssetAnchor} from "./IKreskoAssetAnchor.sol";
import {Rebaser} from "./Rebaser.sol";
import {IKreskoAsset, ISyncable} from "./IKreskoAsset.sol";

/**
 * @title Kresko Synthethic Asset, rebasing ERC20 with underlying wrapping.
 * @author Kresko
 * @notice Rebases to adjust for stock splits and reverse stock splits
 * @notice Minting, burning and rebasing can only be performed by the `Role.OPERATOR`
 */

contract KreskoAsset is ERC20Upgradeable, AccessControlEnumerableUpgradeable, PausableUpgradeable, IKreskoAsset {
    using SafeTransfer for IERC20;
    using SafeTransfer for address payable;
    using Rebaser for uint256;
    using PercentageMath for uint256;

    Rebase private rebasing;
    bool public isRebased;
    address public kresko;
    address public anchor;
    Wrapping private wrapping;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _admin,
        address _kresko,
        address _underlying,
        address _feeRecipient,
        uint48 _openFee,
        uint40 _closeFee
    ) external initializer {
        // SetupERC20
        __ERC20Upgradeable_init(_name, _symbol, _decimals);

        // Setup pausable
        __Pausable_init();

        // Setup the protocol
        kresko = _kresko;
        _grantRole(Role.OPERATOR, _kresko);

        // Setup the state
        _grantRole(Role.ADMIN, msg.sender);
        setUnderlying(_underlying);
        setFeeRecipient(_feeRecipient);
        setOpenFee(_openFee);
        setCloseFee(_closeFee);
        // Revoke admin rights after state setup
        _revokeRole(Role.ADMIN, msg.sender);

        // Setup the admin
        _grantRole(Role.DEFAULT_ADMIN, _admin);
        _grantRole(Role.ADMIN, _admin);
    }

    /// @inheritdoc IKreskoAsset
    function setAnchorToken(address _anchor) external {
        if (_anchor == address(0)) revert Errors.ZERO_ADDRESS();

        // allows easy initialization from anchor itself
        if (anchor != address(0)) _checkRole(Role.ADMIN);

        anchor = _anchor;
        _grantRole(Role.OPERATOR, _anchor);
    }

    /// @inheritdoc IKreskoAsset
    function setUnderlying(address _underlyingAddr) public onlyRole(Role.ADMIN) {
        wrapping.underlying = _underlyingAddr;
        if (_underlyingAddr != address(0)) {
            wrapping.underlyingDecimals = IERC20(wrapping.underlying).decimals();
        }
    }

    /// @inheritdoc IKreskoAsset
    function enableNativeUnderlying(bool _enabled) external onlyRole(Role.ADMIN) {
        wrapping.nativeUnderlyingEnabled = _enabled;
    }

    /// @inheritdoc IKreskoAsset
    function setFeeRecipient(address _feeRecipient) public onlyRole(Role.ADMIN) {
        if (_feeRecipient == address(0)) revert Errors.ZERO_ADDRESS();
        wrapping.feeRecipient = payable(_feeRecipient);
    }

    /// @inheritdoc IKreskoAsset
    function setOpenFee(uint48 _openFee) public onlyRole(Role.ADMIN) {
        if (_openFee > Percents.HUNDRED) revert Errors.INVALID_FEE(_assetId(), _openFee, Percents.HUNDRED);
        wrapping.openFee = _openFee;
    }

    /// @inheritdoc IKreskoAsset
    function setCloseFee(uint40 _closeFee) public onlyRole(Role.ADMIN) {
        if (_closeFee > Percents.HUNDRED) revert Errors.INVALID_FEE(_assetId(), _closeFee, Percents.HUNDRED);
        wrapping.closeFee = _closeFee;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Read                                    */
    /* -------------------------------------------------------------------------- */
    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return (interfaceId != 0xffffffff &&
            (interfaceId == type(IKreskoAsset).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07 ||
                super.supportsInterface(interfaceId)));
    }

    function wrappingInfo() external view override returns (Wrapping memory) {
        return wrapping;
    }

    /// @inheritdoc IKreskoAsset
    function rebaseInfo() external view override returns (Rebase memory) {
        return rebasing;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _totalSupply.rebase(rebasing);
    }

    /// @inheritdoc IERC20
    function balanceOf(address _account) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _balances[_account].rebase(rebasing);
    }

    /// @inheritdoc IERC20
    function allowance(address _owner, address _account) public view override(ERC20Upgradeable, IERC20) returns (uint256) {
        return _allowances[_owner][_account];
    }

    /// @inheritdoc IKreskoAsset
    function pause() public onlyRole(Role.ADMIN) {
        _pause();
    }

    /// @inheritdoc IKreskoAsset
    function unpause() public onlyRole(Role.ADMIN) {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Write                                   */
    /* -------------------------------------------------------------------------- */
    /// @inheritdoc IKreskoAsset
    function reinitializeERC20(
        string memory _name,
        string memory _symbol,
        uint8 _version
    ) external onlyRole(Role.ADMIN) reinitializer(_version) {
        __ERC20Upgradeable_init(_name, _symbol, decimals);
    }

    /// @inheritdoc IERC20
    function approve(address _spender, uint256 _amount) public override(ERC20Upgradeable, IERC20) returns (bool) {
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address _to, uint256 _amount) public override(ERC20Upgradeable, IERC20) returns (bool) {
        return _transfer(msg.sender, _to, _amount);
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override(ERC20Upgradeable, IERC20) returns (bool) {
        uint256 allowed = allowance(_from, msg.sender); // Saves gas for unlimited approvals.

        if (allowed != type(uint256).max) {
            if (_amount > allowed) revert Errors.NO_ALLOWANCE(msg.sender, _from, _amount, allowed);
            _allowances[_from][msg.sender] -= _amount;
        }

        return _transfer(_from, _to, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Restricted                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKreskoAsset
    function rebase(uint248 _denominator, bool _positive, address[] calldata _pools) external onlyRole(Role.ADMIN) {
        if (_denominator < 1 ether) revert Errors.INVALID_DENOMINATOR(_assetId(), _denominator, 1 ether);
        if (_denominator == 1 ether) {
            isRebased = false;
            rebasing = Rebase(0, false);
        } else {
            isRebased = true;
            rebasing = Rebase(_denominator, _positive);
        }
        uint256 length = _pools.length;
        for (uint256 i; i < length; ) {
            ISyncable(_pools[i]).sync();
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IKreskoAsset
    function mint(address _to, uint256 _amount) external onlyRole(Role.OPERATOR) {
        _requireNotPaused();
        _mint(_to, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function burn(address _from, uint256 _amount) external onlyRole(Role.OPERATOR) {
        _requireNotPaused();
        _burn(_from, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function wrap(address _to, uint256 _amount) external {
        _requireNotPaused();

        address underlying = wrapping.underlying;
        if (underlying == address(0)) {
            revert Errors.WRAP_NOT_SUPPORTED();
        }

        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 openFee = wrapping.openFee;
        if (openFee > 0) {
            uint256 fee = _amount.percentMul(openFee);
            _amount -= fee;
            IERC20(underlying).safeTransfer(address(wrapping.feeRecipient), fee);
        }

        _amount = _adjustDecimals(_amount, wrapping.underlyingDecimals, decimals);

        IKreskoAssetAnchor(anchor).wrap(_amount);
        _mint(_to, _amount);

        emit Wrap(address(this), underlying, _to, _amount);
    }

    /// @inheritdoc IKreskoAsset
    function unwrap(address _to, uint256 _amount, bool _receiveNative) external {
        _requireNotPaused();

        address underlying = wrapping.underlying;
        if (underlying == address(0)) {
            revert Errors.WRAP_NOT_SUPPORTED();
        }

        uint256 adjustedAmount = _adjustDecimals(_amount, wrapping.underlyingDecimals, decimals);

        IKreskoAssetAnchor(anchor).unwrap(adjustedAmount);
        _burn(msg.sender, adjustedAmount);

        bool allowNative = _receiveNative && wrapping.nativeUnderlyingEnabled;

        uint256 closeFee = wrapping.closeFee;
        if (closeFee > 0) {
            uint256 fee = _amount.percentMul(closeFee);
            _amount -= fee;

            if (!allowNative) {
                IERC20(underlying).safeTransfer(wrapping.feeRecipient, fee);
            } else {
                wrapping.feeRecipient.safeTransferETH(fee);
            }
        }
        if (!allowNative) {
            IERC20(underlying).safeTransfer(_to, _amount);
        } else {
            payable(_to).safeTransferETH(_amount);
        }

        emit Unwrap(address(this), underlying, msg.sender, _amount);
    }

    receive() external payable {
        _requireNotPaused();
        if (!wrapping.nativeUnderlyingEnabled) revert Errors.NATIVE_TOKEN_DISABLED(_assetId());

        uint256 amount = msg.value;
        if (amount == 0) revert Errors.ZERO_AMOUNT(_assetId());

        uint256 openFee = wrapping.openFee;
        if (openFee > 0) {
            uint256 fee = amount.percentMul(openFee);
            amount -= fee;
            wrapping.feeRecipient.safeTransferETH(fee);
        }

        IKreskoAssetAnchor(anchor).wrap(amount);
        _mint(msg.sender, amount);

        emit Wrap(address(this), address(0), msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internal                                  */
    /* -------------------------------------------------------------------------- */

    function _mint(address _to, uint256 _amount) internal override {
        uint256 normalizedAmount = _amount.unrebase(rebasing);
        unchecked {
            _totalSupply += normalizedAmount;
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[_to] += normalizedAmount;
        }
        // Emit user input amount, not the maybe unrebased amount.
        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal override {
        uint256 normalizedAmount = _amount.unrebase(rebasing);

        _balances[_from] -= normalizedAmount;
        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= normalizedAmount;
        }

        emit Transfer(_from, address(0), _amount);
    }

    /// @dev Internal balances are always unrebased, events emitted are not.
    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        _requireNotPaused();
        uint256 bal = balanceOf(_from);
        if (_amount > bal) revert Errors.NOT_ENOUGH_BALANCE(_from, _amount, bal);
        uint256 normalizedAmount = _amount.unrebase(rebasing);

        _balances[_from] -= normalizedAmount;
        unchecked {
            _balances[_to] += normalizedAmount;
        }

        // Emit user input amount, not the maybe unrebased amount.
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function _adjustDecimals(uint256 _amount, uint8 _fromDecimal, uint8 _toDecimal) internal pure returns (uint256) {
        if (_fromDecimal == _toDecimal) return _amount;
        return
            _fromDecimal < _toDecimal
                ? _amount * (10 ** (_toDecimal - _fromDecimal))
                : _amount / (10 ** (_fromDecimal - _toDecimal));
    }

    function _assetId() internal view returns (Errors.ID memory) {
        return Errors.ID(symbol, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";
import {AccessControlUpgradeable} from "../AccessControlUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControlEnumerable
    struct AccessControlEnumerableStorage {
        mapping(bytes32 role => EnumerableSet.AddressSet) _roleMembers;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlEnumerable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlEnumerableStorageLocation = 0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000;

    function _getAccessControlEnumerableStorage() private pure returns (AccessControlEnumerableStorage storage $) {
        assembly {
            $.slot := AccessControlEnumerableStorageLocation
        }
    }

    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        return $._roleMembers[role].length();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool granted = super._grantRole(role, account);
        if (granted) {
            $._roleMembers[role].add(account);
        }
        return granted;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
        AccessControlEnumerableStorage storage $ = _getAccessControlEnumerableStorage();
        bool revoked = super._revokeRole(role, account);
        if (revoked) {
            $._roleMembers[role].remove(account);
        }
        return revoked;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

error APPROVE_FAILED(address, address, address, uint256);
error ETH_TRANSFER_FAILED(address, uint256);
error TRANSFER_FAILED(address, address, address, uint256);

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransfer {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) revert ETH_TRANSFER_FAILED(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TRANSFER_FAILED(address(token), from, to, amount);
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success)
            revert TRANSFER_FAILED(address(token), msg.sender, to, amount);
    }

    function safeApprove(IERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success)
            revert APPROVE_FAILED(address(token), msg.sender, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

/* solhint-disable var-name-mixedcase */
/* solhint-disable not-rely-on-time */
/* solhint-disable func-name-mixedcase */
/* solhint-disable no-empty-blocks */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @author Kresko: modified to an upgradeable
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.

abstract contract ERC20Upgradeable is Initializable, IERC20Permit {
    /* -------------------------------------------------------------------------- */
    /*                                ERC20 Storage                               */
    /* -------------------------------------------------------------------------- */

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    /* -------------------------------------------------------------------------- */
    /*                                  EIP-2612                                  */
    /* -------------------------------------------------------------------------- */

    mapping(address => uint256) public nonces;

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20Upgradeable_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    READ                                    */
    /* -------------------------------------------------------------------------- */

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ERC20 Logic                                */
    /* -------------------------------------------------------------------------- */

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);

        _balances[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);

        uint256 allowed = _allowances[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            _allowances[from][msg.sender] = allowed - amount;

        _balances[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               EIP-2612 Logic                               */
    /* -------------------------------------------------------------------------- */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline)
            revert PERMIT_DEADLINE_EXPIRED(
                owner,
                spender,
                deadline,
                block.timestamp
            );

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
            if (recoveredAddress == address(0) || recoveredAddress != owner)
                revert INVALID_SIGNER(owner, recoveredAddress);

            _allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Internals                                 */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);

        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        _balances[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // Silence state mutability warning without generating bytecode.
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev PercentageMath are defined by default with 2 decimals of precision (100.00).
 * The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     **/
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings: https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     **/
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Enums                                   */
/* -------------------------------------------------------------------------- */
library Enums {
    /**
     * @dev Minter fees for minting and burning.
     * Open = 0
     * Close = 1
     */
    enum MinterFee {
        Open,
        Close
    }
    /**
     * @notice Swap fee types for shared collateral debt pool swaps.
     * Open = 0
     * Close = 1
     */
    enum SwapFee {
        In,
        Out
    }
    /**
     * @notice Configurable oracle types for assets.
     * Empty = 0
     * Redstone = 1,
     * Chainlink = 2,
     * API3 = 3,
     * Vault = 4
     * Pyth = 5
     */
    enum OracleType {
        Empty,
        Redstone,
        Chainlink,
        API3,
        Vault,
        Pyth
    }

    /**
     * @notice Protocol core actions.
     * Deposit = 0
     * Withdraw = 1,
     * Repay = 2,
     * Borrow = 3,
     * Liquidate = 4
     * SCDPDeposit = 5,
     * SCDPSwap = 6,
     * SCDPWithdraw = 7,
     * SCDPRepay = 8,
     * SCDPLiquidation = 9
     * SCDPFeeClaim = 10
     * SCDPCover = 11
     */
    enum Action {
        Deposit,
        Withdraw,
        Repay,
        Borrow,
        Liquidation,
        SCDPDeposit,
        SCDPSwap,
        SCDPWithdraw,
        SCDPRepay,
        SCDPLiquidation,
        SCDPFeeClaim,
        SCDPCover
    }
}

/* -------------------------------------------------------------------------- */
/*                               Access Control                               */
/* -------------------------------------------------------------------------- */

library Role {
    /// @dev Meta role for all roles.
    bytes32 internal constant DEFAULT_ADMIN = 0x00;
    /// @dev keccak256("kresko.roles.minter.admin")
    bytes32 internal constant ADMIN = 0xb9dacdf02281f2e98ddbadaaf44db270b3d5a916342df47c59f77937a6bcd5d8;
    /// @dev keccak256("kresko.roles.minter.operator")
    bytes32 internal constant OPERATOR = 0x112e48a576fb3a75acc75d9fcf6e0bc670b27b1dbcd2463502e10e68cf57d6fd;
    /// @dev keccak256("kresko.roles.minter.manager")
    bytes32 internal constant MANAGER = 0x46925e0f0cc76e485772167edccb8dc449d43b23b55fc4e756b063f49099e6a0;
    /// @dev keccak256("kresko.roles.minter.safety.council")
    bytes32 internal constant SAFETY_COUNCIL = 0x9c387ecf1663f9144595993e2c602b45de94bf8ba3a110cb30e3652d79b581c0;
}

/* -------------------------------------------------------------------------- */
/*                                    MISC                                    */
/* -------------------------------------------------------------------------- */

library Constants {
    /// @dev Set the initial value to 1, (not hindering possible gas refunds by setting it to 0 on exit).
    uint8 internal constant NOT_ENTERED = 1;
    uint8 internal constant ENTERED = 2;
    uint8 internal constant NOT_INITIALIZING = 1;
    uint8 internal constant INITIALIZING = 2;

    bytes32 internal constant ZERO_BYTES32 = bytes32("");
    /// @dev The min oracle decimal precision
    uint256 internal constant MIN_ORACLE_DECIMALS = 8;
    /// @dev The minimum collateral amount for a kresko asset.
    uint256 internal constant MIN_KRASSET_COLLATERAL_AMOUNT = 1e12;

    /// @dev The maximum configurable minimum debt USD value. 8 decimals.
    uint256 internal constant MAX_MIN_DEBT_VALUE = 1_000 * 1e8; // $1,000
}

library Percents {
    uint16 internal constant ONE = 0.01e4;
    uint16 internal constant HUNDRED = 1e4;
    uint16 internal constant TWENTY_FIVE = 0.25e4;
    uint16 internal constant FIFTY = 0.50e4;
    uint16 internal constant MAX_DEVIATION = TWENTY_FIVE;

    uint16 internal constant BASIS_POINT = 1;
    /// @dev The maximum configurable close fee.
    uint16 internal constant MAX_CLOSE_FEE = 0.25e4; // 25%

    /// @dev The maximum configurable open fee.
    uint16 internal constant MAX_OPEN_FEE = 0.25e4; // 25%

    /// @dev The maximum configurable protocol fee per asset for collateral pool swaps.
    uint16 internal constant MAX_SCDP_FEE = 0.5e4; // 50%

    /// @dev The minimum configurable minimum collateralization ratio.
    uint16 internal constant MIN_LT = HUNDRED + ONE; // 101%
    uint16 internal constant MIN_MCR = HUNDRED + ONE + ONE; // 102%

    /// @dev The minimum configurable liquidation incentive multiplier.
    /// This means liquidator only receives equal amount of collateral to debt repaid.
    uint16 internal constant MIN_LIQ_INCENTIVE = HUNDRED;

    /// @dev The maximum configurable liquidation incentive multiplier.
    /// This means liquidator receives 25% bonus collateral compared to the debt repaid.
    uint16 internal constant MAX_LIQ_INCENTIVE = 1.25e4; // 125%
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

interface IErrorFieldProvider {
    function symbol() external view returns (string memory);
}

/* solhint-disable max-line-length */
library Errors {
    struct ID {
        string symbol;
        address addr;
    }

    function id(address _addr) internal view returns (ID memory) {
        if (_addr.code.length > 0) return ID(IErrorFieldProvider(_addr).symbol(), _addr);
        return ID("", _addr); // not a token
    }

    function symbol(address _addr) internal view returns (string memory symbol_) {
        if (_addr.code.length > 0) return IErrorFieldProvider(_addr).symbol();
    }

    error ADDRESS_HAS_NO_CODE(address);
    error NOT_INITIALIZING();
    error TO_WAD_AMOUNT_IS_NEGATIVE(int256);
    error COMMON_ALREADY_INITIALIZED();
    error MINTER_ALREADY_INITIALIZED();
    error SCDP_ALREADY_INITIALIZED();
    error STRING_HEX_LENGTH_INSUFFICIENT();
    error SAFETY_COUNCIL_NOT_ALLOWED();
    error SAFETY_COUNCIL_SETTER_IS_NOT_ITS_OWNER(address);
    error SAFETY_COUNCIL_ALREADY_EXISTS(address given, address existing);
    error MULTISIG_NOT_ENOUGH_OWNERS(address, uint256 owners, uint256 required);
    error ACCESS_CONTROL_NOT_SELF(address who, address self);
    error MARKET_CLOSED(ID, string);
    error SCDP_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error MINTER_ASSET_ECONOMY(ID, uint256 seizeReductionPct, ID, uint256 repayIncreasePct);
    error INVALID_TICKER(ID, string ticker);
    error PYTH_EP_ZERO();
    error ASSET_NOT_ENABLED(ID);
    error ASSET_SET_FEEDS_FAILED(ID);
    error ASSET_CANNOT_BE_USED_TO_COVER(ID);
    error ASSET_PAUSED_FOR_THIS_ACTION(ID, uint8 action);
    error ASSET_NOT_MINTER_COLLATERAL(ID);
    error ASSET_NOT_FEE_ACCUMULATING_ASSET(ID);
    error ASSET_NOT_SHARED_COLLATERAL(ID);
    error ASSET_NOT_MINTABLE_FROM_MINTER(ID);
    error ASSET_NOT_SWAPPABLE(ID);
    error ASSET_DOES_NOT_HAVE_DEPOSITS(ID);
    error ASSET_CANNOT_BE_FEE_ASSET(ID);
    error ASSET_NOT_VALID_DEPOSIT_ASSET(ID);
    error ASSET_ALREADY_ENABLED(ID);
    error ASSET_ALREADY_DISABLED(ID);
    error ASSET_DOES_NOT_EXIST(ID);
    error ASSET_ALREADY_EXISTS(ID);
    error ASSET_IS_VOID(ID);
    error INVALID_ASSET(ID);
    error CANNOT_REMOVE_COLLATERAL_THAT_HAS_USER_DEPOSITS(ID);
    error CANNOT_REMOVE_SWAPPABLE_ASSET_THAT_HAS_DEBT(ID);
    error INVALID_CONTRACT_KRASSET(ID krAsset);
    error INVALID_CONTRACT_KRASSET_ANCHOR(ID anchor, ID krAsset);
    error NOT_SWAPPABLE_KRASSET(ID);
    error IDENTICAL_ASSETS(ID);
    error WITHDRAW_NOT_SUPPORTED();
    error MINT_NOT_SUPPORTED();
    error DEPOSIT_NOT_SUPPORTED();
    error REDEEM_NOT_SUPPORTED();
    error NATIVE_TOKEN_DISABLED(ID);
    error EXCEEDS_ASSET_DEPOSIT_LIMIT(ID, uint256 deposits, uint256 limit);
    error EXCEEDS_ASSET_MINTING_LIMIT(ID, uint256 deposits, uint256 limit);
    error UINT128_OVERFLOW(ID, uint256 deposits, uint256 limit);
    error INVALID_SENDER(address, address);
    error INVALID_MIN_DEBT(uint256 invalid, uint256 valid);
    error INVALID_SCDP_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_MCR(uint256 invalid, uint256 valid);
    error MLR_CANNOT_BE_LESS_THAN_LIQ_THRESHOLD(uint256 mlt, uint256 lt);
    error INVALID_LIQ_THRESHOLD(uint256 lt, uint256 min, uint256 max);
    error INVALID_PROTOCOL_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ASSET_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_ORACLE_DEVIATION(uint256 invalid, uint256 valid);
    error INVALID_ORACLE_TYPE(uint8 invalid);
    error INVALID_FEE_RECIPIENT(address invalid);
    error INVALID_LIQ_INCENTIVE(ID, uint256 invalid, uint256 min, uint256 max);
    error INVALID_KFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_CFACTOR(ID, uint256 invalid, uint256 valid);
    error INVALID_MINTER_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_PRICE_PRECISION(uint256 decimals, uint256 valid);
    error INVALID_COVER_THRESHOLD(uint256 threshold, uint256 max);
    error INVALID_COVER_INCENTIVE(uint256 incentive, uint256 min, uint256 max);
    error INVALID_DECIMALS(ID, uint256 decimals);
    error INVALID_FEE(ID, uint256 invalid, uint256 valid);
    error INVALID_FEE_TYPE(uint8 invalid, uint8 valid);
    error INVALID_VAULT_PRICE(string ticker, address);
    error INVALID_API3_PRICE(string ticker, address);
    error INVALID_CL_PRICE(string ticker, address);
    error INVALID_PRICE(ID, address oracle, int256 price);
    error INVALID_KRASSET_OPERATOR(ID, address invalidOperator, address validOperator);
    error INVALID_DENOMINATOR(ID, uint256 denominator, uint256 valid);
    error INVALID_OPERATOR(ID, address who, address valid);
    error INVALID_SUPPLY_LIMIT(ID, uint256 invalid, uint256 valid);
    error NEGATIVE_PRICE(address asset, int256 price);
    error INVALID_PYTH_PRICE(bytes32 id, uint256 price);
    error STALE_PRICE(string ticker, uint256 price, uint256 timeFromUpdate, uint256 threshold);
    error STALE_PUSH_PRICE(
        ID asset,
        string ticker,
        int256 price,
        uint8 oracleType,
        address feed,
        uint256 timeFromUpdate,
        uint256 threshold
    );
    error PRICE_UNSTABLE(uint256 primaryPrice, uint256 referencePrice, uint256 deviationPct);
    error ZERO_OR_STALE_VAULT_PRICE(ID, address, uint256);
    error ZERO_OR_STALE_PRICE(string ticker, uint8[2] oracles);
    error STALE_ORACLE(uint8 oracleType, address feed, uint256 time, uint256 staleTime);
    error ZERO_OR_NEGATIVE_PUSH_PRICE(ID asset, string ticker, int256 price, uint8 oracleType, address feed);
    error UNSUPPORTED_ORACLE(string ticker, uint8 oracle);
    error NO_PUSH_ORACLE_SET(string ticker);
    error NO_VIEW_PRICE_AVAILABLE(string ticker);
    error NOT_SUPPORTED_YET();
    error WRAP_NOT_SUPPORTED();
    error BURN_AMOUNT_OVERFLOW(ID, uint256 burnAmount, uint256 debtAmount);
    error PAUSED(address who);
    error L2_SEQUENCER_DOWN();
    error FEED_ZERO_ADDRESS(string ticker);
    error INVALID_SEQUENCER_UPTIME_FEED(address);
    error NO_MINTED_ASSETS(address who);
    error NO_COLLATERALS_DEPOSITED(address who);
    error ONLY_WHITELISTED();
    error BLACKLISTED();
    error MISSING_PHASE_3_NFT();
    error MISSING_PHASE_2_NFT();
    error MISSING_PHASE_1_NFT();
    error CANNOT_RE_ENTER();
    error PYTH_ID_ZERO(string ticker);
    error ARRAY_LENGTH_MISMATCH(string ticker, uint256 arr1, uint256 arr2);
    error COLLATERAL_VALUE_GREATER_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error COLLATERAL_VALUE_GREATER_THAN_COVER_THRESHOLD(uint256 collateralValue, uint256 minCollateralValue, uint48 ratio);
    error ACCOUNT_COLLATERAL_VALUE_LESS_THAN_REQUIRED(
        address who,
        uint256 collateralValue,
        uint256 minCollateralValue,
        uint32 ratio
    );
    error COLLATERAL_VALUE_LESS_THAN_REQUIRED(uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_HEALTHY_ACCOUNT(address who, uint256 collateralValue, uint256 minCollateralValue, uint32 ratio);
    error CANNOT_LIQUIDATE_SELF();
    error LIQUIDATION_AMOUNT_GREATER_THAN_DEBT(ID repayAsset, uint256 repayAmount, uint256 availableAmount);
    error LIQUIDATION_SEIZED_LESS_THAN_EXPECTED(ID, uint256, uint256);
    error LIQUIDATION_VALUE_IS_ZERO(ID repayAsset, ID seizeAsset);
    error ACCOUNT_HAS_NO_DEPOSITS(address who, ID);
    error WITHDRAW_AMOUNT_GREATER_THAN_DEPOSITS(address who, ID, uint256 requested, uint256 deposits);
    error ACCOUNT_KRASSET_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ACCOUNT_COLLATERAL_NOT_FOUND(address account, ID, address[] accountCollaterals);
    error ARRAY_INDEX_OUT_OF_BOUNDS(ID element, uint256 index, address[] elements);
    error ELEMENT_DOES_NOT_MATCH_PROVIDED_INDEX(ID element, uint256 index, address[] elements);
    error NO_FEES_TO_CLAIM(ID asset, address claimer);
    error REPAY_OVERFLOW(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error INCOME_AMOUNT_IS_ZERO(ID incomeAsset);
    error NO_LIQUIDITY_TO_GIVE_INCOME_FOR(ID incomeAsset, uint256 userDeposits, uint256 totalDeposits);
    error NOT_ENOUGH_SWAP_DEPOSITS_TO_SEIZE(ID repayAsset, ID seizeAsset, uint256 invalid, uint256 valid);
    error SWAP_ROUTE_NOT_ENABLED(ID assetIn, ID assetOut);
    error RECEIVED_LESS_THAN_DESIRED(ID, uint256 invalid, uint256 valid);
    error SWAP_ZERO_AMOUNT_IN(ID tokenIn);
    error INVALID_WITHDRAW(ID withdrawAsset, uint256 sharesIn, uint256 assetsOut);
    error ROUNDING_ERROR(ID asset, uint256 sharesIn, uint256 assetsOut);
    error MAX_DEPOSIT_EXCEEDED(ID asset, uint256 assetsIn, uint256 maxDeposit);
    error COLLATERAL_AMOUNT_LOW(ID krAssetCollateral, uint256 amount, uint256 minAmount);
    error MINT_VALUE_LESS_THAN_MIN_DEBT_VALUE(ID, uint256 value, uint256 minRequiredValue);
    error NOT_A_CONTRACT(address who);
    error NO_ALLOWANCE(address spender, address owner, uint256 requested, uint256 allowed);
    error NOT_ENOUGH_BALANCE(address who, uint256 requested, uint256 available);
    error SENDER_NOT_OPERATOR(ID, address sender, address kresko);
    error ZERO_SHARES_FROM_ASSETS(ID, uint256 assets, ID);
    error ZERO_SHARES_OUT(ID, uint256 assets);
    error ZERO_SHARES_IN(ID, uint256 assets);
    error ZERO_ASSETS_FROM_SHARES(ID, uint256 shares, ID);
    error ZERO_ASSETS_OUT(ID, uint256 shares);
    error ZERO_ASSETS_IN(ID, uint256 shares);
    error ZERO_ADDRESS();
    error ZERO_DEPOSIT(ID);
    error ZERO_AMOUNT(ID);
    error ZERO_WITHDRAW(ID);
    error ZERO_MINT(ID);
    error SDI_DEBT_REPAY_OVERFLOW(uint256 debt, uint256 repay);
    error ZERO_REPAY(ID, uint256 repayAmount, uint256 seizeAmount);
    error ZERO_BURN(ID);
    error ZERO_DEBT(ID);
    error UPDATE_FEE_OVERFLOW(uint256 sent, uint256 required);
    error BatchResult(uint256 timestamp, bytes[] results);
    /**
     * @notice Cannot directly rethrow or redeclare panic errors in try/catch - so using a similar error instead.
     * @param code The panic code received.
     */
    error Panicked(uint256 code);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAccessControlEnumerable} from "@oz/access/extensions/IAccessControlEnumerable.sol";
import {IERC165} from "vendor/IERC165.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";

import {IKreskoAssetIssuer} from "./IKreskoAssetIssuer.sol";
import {IERC4626Upgradeable} from "./IERC4626Upgradeable.sol";

interface IKreskoAssetAnchor is IKreskoAssetIssuer, IERC4626Upgradeable, IERC20Permit, IAccessControlEnumerable, IERC165 {
    function totalAssets() external view override(IERC4626Upgradeable) returns (uint256);

    /**
     * @notice Updates ERC20 metadata for the token in case eg. a ticker change
     * @param _name new name for the asset
     * @param _symbol new symbol for the asset
     * @param _version number that must be greater than latest emitted `Initialized` version
     */
    function reinitializeERC20(string memory _name, string memory _symbol, uint8 _version) external;

    /**
     * @notice Mint Kresko Anchor Asset to Kresko Asset (Only KreskoAsset can call)
     * @param assets The assets (uint256).
     */
    function wrap(uint256 assets) external;

    /**
     * @notice Burn Kresko Anchor Asset to Kresko Asset (Only KreskoAsset can call)
     * @param assets The assets (uint256).
     */

    function unwrap(uint256 assets) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {FixedPointMath} from "libs/FixedPointMath.sol";
import {IKreskoAsset} from "./IKreskoAsset.sol";

library Rebaser {
    using FixedPointMath for uint256;

    /**
     * @notice Unrebase a value by a given rebase struct.
     * @param self The value to unrebase.
     * @param _rebase The rebase struct.
     * @return The unrebased value.
     */
    function unrebase(uint256 self, IKreskoAsset.Rebase storage _rebase) internal view returns (uint256) {
        if (_rebase.denominator == 0) return self;
        return _rebase.positive ? self.divWadDown(_rebase.denominator) : self.mulWadDown(_rebase.denominator);
    }

    /**
     * @notice Rebase a value by a given rebase struct.
     * @param self The value to rebase.
     * @param _rebase The rebase struct.
     * @return The rebased value.
     */
    function rebase(uint256 self, IKreskoAsset.Rebase storage _rebase) internal view returns (uint256) {
        if (_rebase.denominator == 0) return self;
        return _rebase.positive ? self.mulWadDown(_rebase.denominator) : self.divWadDown(_rebase.denominator);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {IAccessControlEnumerable} from "@oz/access/extensions/IAccessControlEnumerable.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";
import {IERC165} from "vendor/IERC165.sol";

interface ISyncable {
    function sync() external;
}

interface IKreskoAsset is IERC20Permit, IAccessControlEnumerable, IERC165 {
    event Wrap(address indexed asset, address underlying, address indexed to, uint256 amount);
    event Unwrap(address indexed asset, address underlying, address indexed to, uint256 amount);

    /**
     * @notice Rebase information
     * @param positive supply increasing/reducing rebase
     * @param denominator the denominator for the operator, 1 ether = 1
     */
    struct Rebase {
        uint248 denominator;
        bool positive;
    }

    /**
     * @notice Wrapping information for the Kresko Asset
     * @param underlying If available, this is the corresponding on-chain underlying token.
     * @param underlyingDecimals Decimals of the underlying token.
     * @param openFee Possible fee when wrapping from underlying to KrAsset.
     * @param closeFee Possible fee when wrapping from KrAsset to underlying.
     * @param nativeUnderlyingEnabled Whether native underlying can be sent used for wrapping.
     * @param feeRecipient Fee recipient.
     */
    struct Wrapping {
        address underlying;
        uint8 underlyingDecimals;
        uint48 openFee;
        uint40 closeFee;
        bool nativeUnderlyingEnabled;
        address payable feeRecipient;
    }

    function kresko() external view returns (address);

    function rebaseInfo() external view returns (Rebase memory);

    function wrappingInfo() external view returns (Wrapping memory);

    function isRebased() external view returns (bool);

    /**
     * @notice Perform a rebase, changing the denumerator and its operator
     * @param _denominator the denumerator for the operator, 1 ether = 1
     * @param _positive supply increasing/reducing rebase
     * @param _pools UniswapV2Pair address to sync so we wont get rekt by skim() calls.
     * @dev denumerator values 0 and 1 ether will disable the rebase
     */
    function rebase(uint248 _denominator, bool _positive, address[] calldata _pools) external;

    /**
     * @notice Updates ERC20 metadata for the token in case eg. a ticker change
     * @param _name new name for the asset
     * @param _symbol new symbol for the asset
     * @param _version number that must be greater than latest emitted `Initialized` version
     */
    function reinitializeERC20(string memory _name, string memory _symbol, uint8 _version) external;

    /**
     * @notice Mints tokens to an address.
     * @dev Only callable by operator.
     * @dev Internal balances are always unrebased, events emitted are not.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns tokens from an address.
     * @dev Only callable by operator.
     * @dev Internal balances are always unrebased, events emitted are not.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @notice  Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;

    /**
     * @notice Deposit underlying tokens to receive equal value of krAsset (-fee).
     * @param _to The address to send tokens to.
     * @param _amount The amount (uint256).
     */
    function wrap(address _to, uint256 _amount) external;

    /**
     * @notice Withdraw kreskoAsset to receive underlying tokens / native (-fee).
     * @param _to The address to send unwrapped tokens to.
     * @param _amount The amount (uint256).
     * @param _receiveNative bool whether to receive underlying as native
     */
    function unwrap(address _to, uint256 _amount, bool _receiveNative) external;

    /**
     * @notice Sets anchor token address
     * @dev Has modifiers: onlyRole.
     * @param _anchor The anchor address.
     */
    function setAnchorToken(address _anchor) external;

    /**
     * @notice Enables depositing native token ETH in case of krETH
     * @dev Has modifiers: onlyRole.
     * @param _enabled The enabled (bool).
     */
    function enableNativeUnderlying(bool _enabled) external;

    /**
     * @notice Sets fee recipient address
     * @dev Has modifiers: onlyRole.
     * @param _feeRecipient The fee recipient address.
     */
    function setFeeRecipient(address _feeRecipient) external;

    /**
     * @notice Sets deposit fee
     * @dev Has modifiers: onlyRole.
     * @param _openFee The open fee (uint48).
     */
    function setOpenFee(uint48 _openFee) external;

    /**
     * @notice Sets withdraw fee
     * @dev Has modifiers: onlyRole.
     * @param _closeFee The open fee (uint48).
     */
    function setCloseFee(uint40 _closeFee) external;

    /**
     * @notice Sets underlying token address (and its decimals)
     * @notice Zero address will disable functionality provided for the underlying.
     * @dev Has modifiers: onlyRole.
     * @param _underlyingAddr The underlying address.
     */
    function setUnderlying(address _underlyingAddr) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "../IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "./IERC20.sol";

/* solhint-disable func-name-mixedcase */

interface IERC20Permit is IERC20 {
    error PERMIT_DEADLINE_EXPIRED(address, address, uint256, uint256);
    error INVALID_SIGNER(address, address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

/// @title KreskoAsset issuer interface
/// @author Kresko
/// @notice Contract that allows minting and burning through Kresko.
/// @dev All mintable assets in Kresko must implement this. (enforced through introspection)
interface IKreskoAssetIssuer {
    /**
     * @notice Mints @param _assets of krAssets for @param _to,
     * @notice Mints relative @return _shares of anchor tokens.
     */
    function issue(uint256 _assets, address _to) external returns (uint256 shares);

    /**
     * @notice Burns @param _assets of krAssets from @param _from,
     * @notice Burns relative @return _shares of anchor tokens.
     */
    function destroy(uint256 _assets, address _from) external returns (uint256 shares);

    /**
     * @notice Preview conversion from KrAsset amount: @param assets to matching amount of Anchor tokens: @return shares
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Preview conversion from Anchor token amount: @param shares to matching KrAsset amount: @return assets
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Preview conversion from Anchor token amounts: @param shares to matching amounts of KrAssets: @return assets
     */
    function convertManyToAssets(uint256[] calldata shares) external view returns (uint256[] memory assets);

    /**
     * @notice Preview conversion from KrAsset amounts: @param assets to matching amounts of Anchor tokens: @return shares
     */
    function convertManyToShares(uint256[] calldata assets) external view returns (uint256[] memory shares);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IKreskoAsset} from "./IKreskoAsset.sol";

interface IERC4626Upgradeable {
    /**
     * @notice The underlying Kresko Asset
     */
    function asset() external view returns (IKreskoAsset);

    /**
     * @notice Deposit KreskoAssets for equivalent amount of anchor tokens
     * @param assets Amount of KreskoAssets to deposit
     * @param receiver Address to send shares to
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Withdraw KreskoAssets for equivalent amount of anchor tokens
     * @param assets Amount of KreskoAssets to withdraw
     * @param receiver Address to send KreskoAssets to
     * @param owner Address to burn shares from
     * @return shares Amount of shares burned
     * @dev shares are burned from owner, not msg.sender
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256 assets);

    function maxRedeem(address owner) external view returns (uint256 assets);

    function maxWithdraw(address owner) external view returns (uint256 assets);

    /**
     * @notice Mint shares of anchor tokens for equivalent amount of KreskoAssets
     * @param shares Amount of shares to mint
     * @param receiver Address to send shares to
     * @return assets Amount of KreskoAssets redeemed
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Track the underlying amount
     * @return Total supply for the underlying
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Redeem shares of anchor for KreskoAssets
     * @param shares Amount of shares to redeem
     * @param receiver Address to send KreskoAssets to
     * @param owner Address to burn shares from
     * @return assets Amount of KreskoAssets redeemed
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMath {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(uint256 x, uint256 n, uint256 scalar) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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