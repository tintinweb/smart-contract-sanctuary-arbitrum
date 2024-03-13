// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

// solhint-disable-next-line
import {AccessControlEnumerableUpgradeable, AccessControlUpgradeable} from "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IAccessControl} from "@oz/access/IAccessControl.sol";
import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "kresko-lib/token/ERC20Upgradeable.sol";
import {SafeTransfer} from "kresko-lib/token/SafeTransfer.sol";

import {Role} from "common/Constants.sol";
import {Errors} from "common/Errors.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {IERC165} from "vendor/IERC165.sol";
import {IKISS} from "kiss/interfaces/IKISS.sol";
import {IVaultExtender} from "vault/interfaces/IVaultExtender.sol";
import {IVault} from "vault/interfaces/IVault.sol";

/* solhint-disable not-rely-on-time */

/**
 * @title Kresko Integrated Stable System
 * This is a non-rebasing Kresko Asset, intended to be paired with KreskoVault shares (vKISS) token.
 * @author Kresko
 */
contract KISS is IKISS, ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    using SafeTransfer for ERC20Upgradeable;

    address public kresko;
    address public vKISS;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 dec_,
        address admin_,
        address kresko_,
        address vKISS_
    ) external initializer {
        if (kresko_.code.length == 0) revert Errors.NOT_A_CONTRACT(kresko_);

        __ERC20Upgradeable_init(name_, symbol_, dec_);

        // Setup the admin
        _grantRole(Role.DEFAULT_ADMIN, admin_);
        _grantRole(Role.ADMIN, admin_);

        // Setup the protocol
        kresko = kresko_;
        _grantRole(Role.OPERATOR, kresko_);

        // Setup vault
        vKISS = vKISS_;
    }

    modifier onlyContract() {
        if (msg.sender.code.length == 0) revert Errors.NOT_A_CONTRACT(msg.sender);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Writes                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKISS
    function issue(uint256 _amount, address _to) public override onlyRole(Role.OPERATOR) returns (uint256) {
        _mint(_to, _amount);
        return _amount;
    }

    /// @inheritdoc IKISS
    function destroy(uint256 _amount, address _from) external onlyRole(Role.OPERATOR) returns (uint256) {
        _burn(_from, _amount);
        return _amount;
    }

    /// @inheritdoc IVaultExtender
    function vaultDeposit(
        address _assetAddr,
        uint256 _assets,
        address _receiver
    ) external returns (uint256 sharesOut, uint256 assetFee) {
        ERC20Upgradeable(_assetAddr).safeTransferFrom(msg.sender, address(this), _assets);

        ERC20Upgradeable(_assetAddr).approve(vKISS, _assets);
        (sharesOut, assetFee) = IVault(vKISS).deposit(_assetAddr, _assets, address(this));

        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, sharesOut);
    }

    /// @inheritdoc IVaultExtender
    function vaultMint(
        address _assetAddr,
        uint256 _shares,
        address _receiver
    ) external returns (uint256 assetsIn, uint256 assetFee) {
        (assetsIn, assetFee) = IVault(vKISS).previewMint(_assetAddr, _shares);
        ERC20Upgradeable(_assetAddr).safeTransferFrom(msg.sender, address(this), assetsIn);

        ERC20Upgradeable(_assetAddr).approve(vKISS, assetsIn);
        IVault(vKISS).mint(_assetAddr, _shares, address(this));

        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, _shares);
    }

    /// @inheritdoc IVaultExtender
    function vaultWithdraw(
        address _assetAddr,
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 sharesIn, uint256 assetFee) {
        (sharesIn, assetFee) = IVault(vKISS).previewWithdraw(_assetAddr, _assets);
        withdrawFrom(_owner, address(this), sharesIn);
        address receiver = _receiver == address(0) ? _owner : _receiver;
        IVault(vKISS).withdraw(_assetAddr, _assets, receiver, address(this));
    }

    /// @inheritdoc IVaultExtender
    function vaultRedeem(
        address _assetAddr,
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assetsOut, uint256 assetFee) {
        withdrawFrom(_owner, address(this), _shares);
        address receiver = _receiver == address(0) ? _owner : _receiver;
        (assetsOut, assetFee) = IVault(vKISS).redeem(_assetAddr, _shares, receiver, address(this));
    }

    /// @inheritdoc IVaultExtender
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 max, uint256 feePaid) {
        (uint256 assetsOut, uint256 fee) = IVault(vKISS).previewRedeem(assetAddr, _balances[owner]);
        uint256 balance = ERC20Upgradeable(assetAddr).balanceOf(vKISS);

        if (assetsOut + fee > balance) {
            (max, fee) = IVault(vKISS).previewWithdraw(assetAddr, balance);
        } else {
            return (_balances[owner], fee);
        }
    }

    /// @inheritdoc IVaultExtender
    function deposit(uint256 _shares, address _receiver) external {
        ERC20Upgradeable(vKISS).transferFrom(msg.sender, address(this), _shares);
        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _mint(receiver, _shares);
    }

    /// @inheritdoc IVaultExtender
    function withdraw(uint256 _amount, address _receiver) external {
        address receiver = _receiver == address(0) ? msg.sender : _receiver;
        _withdraw(msg.sender, receiver, _amount);
    }

    /// @inheritdoc IVaultExtender
    function withdrawFrom(address _from, address _to, uint256 _amount) public {
        if (msg.sender != _from) {
            uint256 allowed = _allowances[_from][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) _allowances[_from][msg.sender] = allowed - _amount;
        }

        _withdraw(_from, _to, _amount);
    }

    /// @inheritdoc IKISS
    function pause() public onlyContract onlyRole(Role.ADMIN) {
        super._pause();
    }

    /// @inheritdoc IKISS
    function unpause() public onlyContract onlyRole(Role.ADMIN) {
        _unpause();
    }

    /// @inheritdoc IKISS
    function grantRole(
        bytes32 _role,
        address _to
    ) public override(IKISS, AccessControlUpgradeable, IAccessControl) onlyRole(Role.ADMIN) {
        if (_role == Role.OPERATOR && _to.code.length == 0) revert Errors.NOT_A_CONTRACT(_to);
        _grantRole(_role, _to);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IKISS
    function exchangeRate() external view returns (uint256) {
        return IVault(vKISS).exchangeRate();
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToShares(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertManyToShares(uint256[] calldata assets) external pure returns (uint256[] calldata shares) {
        return assets;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertToAssets(uint256 shares) external pure returns (uint256) {
        return shares;
    }

    /// @inheritdoc IKreskoAssetIssuer
    function convertManyToAssets(uint256[] calldata shares) external pure returns (uint256[] calldata assets) {
        return shares;
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return (interfaceId != 0xffffffff &&
            (interfaceId == type(IKISS).interfaceId ||
                interfaceId == type(IKreskoAssetIssuer).interfaceId ||
                interfaceId == 0x01ffc9a7 ||
                interfaceId == 0x36372b07 ||
                super.supportsInterface(interfaceId)));
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    function _withdraw(address from, address to, uint256 amount) internal {
        _burn(from, amount);
        ERC20Upgradeable(vKISS).transfer(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (paused()) revert Errors.PAUSED(address(this));
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
pragma solidity ^0.8.0;

import {IERC165} from "vendor/IERC165.sol";
import {IKreskoAssetIssuer} from "kresko-asset/IKreskoAssetIssuer.sol";
import {IVaultExtender} from "vault/interfaces/IVaultExtender.sol";
import {IERC20Permit} from "kresko-lib/token/IERC20Permit.sol";

interface IKISS is IERC20Permit, IVaultExtender, IKreskoAssetIssuer, IERC165 {
    function vKISS() external view returns (address);

    function kresko() external view returns (address);

    /**
     * @notice This function adds KISS to circulation
     * Caller must be a contract and have the OPERATOR_ROLE
     * @param _amount amount to mint
     * @param _to address to mint tokens to
     * @return uint256 amount minted
     */
    function issue(uint256 _amount, address _to) external override returns (uint256);

    /**
     * @notice This function removes KISS from circulation
     * Caller must be a contract and have the OPERATOR_ROLE
     * @param _amount amount to burn
     * @param _from address to burn tokens from
     * @return uint256 amount burned
     *
     * @inheritdoc IKreskoAssetIssuer
     */
    function destroy(uint256 _amount, address _from) external override returns (uint256);

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
     * @notice Exchange rate of vKISS to USD.
     * @return rate vKISS/USD exchange rate.
     * @custom:signature exchangeRate()
     * @custom:selector 0x3ba0b9a9
     */
    function exchangeRate() external view returns (uint256 rate);

    /**
     * @notice Overrides `AccessControl.grantRole` for following:
     * @notice EOA cannot be granted Role.OPERATOR role
     * @param _role role to grant
     * @param _to address to grant role for
     */
    function grantRole(bytes32 _role, address _to) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultExtender {
    event Deposit(address indexed _from, address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, address indexed _to, uint256 _amount);

    /**
     * @notice Deposit tokens to vault for shares and convert them to equal amount of extender token.
     * @param _assetAddr Supported vault asset address
     * @param _assets amount of `_assetAddr` to deposit
     * @param _receiver Address receive extender tokens
     * @return sharesOut amount of shares/extender tokens minted
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultDeposit(
        address _assetAddr,
        uint256 _assets,
        address _receiver
    ) external returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice Deposit supported vault assets to receive `_shares`, depositing the shares for equal amount of extender token.
     * @param _assetAddr Supported vault asset address
     * @param _receiver Address receive extender tokens
     * @param _shares Amount of shares to receive
     * @return assetsIn Amount of assets for `_shares`
     * @return assetFee Amount of `_assetAddr` vault took as fee
     */

    /**
     * @notice Vault mint, an external state-modifying function.
     * @param _assetAddr The asset addr address.
     * @param _shares The shares (uint256).
     * @param _receiver The receiver address.
     * @return assetsIn An uint256 value.
     * @return assetFee An uint256 value.
     * @custom:signature vaultMint(address,uint256,address)
     * @custom:selector 0x0c8daea9
     */
    function vaultMint(
        address _assetAddr,
        uint256 _shares,
        address _receiver
    ) external returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice Withdraw supported vault asset, burning extender tokens and withdrawing shares from vault.
     * @param _assetAddr Supported vault asset address
     * @param _assets amount of `_assetAddr` to deposit
     * @param _receiver Address receive extender tokens
     * @param _owner Owner of extender tokens
     * @return sharesIn amount of shares/extender tokens burned
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultWithdraw(
        address _assetAddr,
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 sharesIn, uint256 assetFee);

    /**
     * @notice  Withdraw supported vault asset for  `_shares` of extender tokens.
     * @param _assetAddr Token to deposit into vault for shares.
     * @param _shares amount of extender tokens to burn
     * @param _receiver Address to receive assets withdrawn
     * @param _owner Owner of extender tokens
     * @return assetsOut amount of assets out
     * @return assetFee amount of `_assetAddr` vault took as fee
     */
    function vaultRedeem(
        address _assetAddr,
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice Max redeem for underlying extender token.
     * @param assetAddr The withdraw asset address.
     * @param owner The extender token owner.
     * @return max Maximum amount withdrawable.
     * @return fee Fee paid if max is withdrawn.
     * @custom:signature maxRedeem(address,address)
     * @custom:selector 0x95b734fb
     */
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 max, uint256 fee);

    /**
     * @notice Deposit shares for equal amount of extender token.
     * @param _shares amount of vault shares to deposit
     * @param _receiver address to mint extender tokens to
     * @dev Does not return a value
     */
    function deposit(uint256 _shares, address _receiver) external;

    /**
     * @notice Withdraw shares for equal amount of extender token.
     * @param _amount amount of vault extender tokens to burn
     * @param _receiver address to send shares to
     * @dev Does not return a value
     */
    function withdraw(uint256 _amount, address _receiver) external;

    /**
     * @notice Withdraw shares for equal amount of extender token with allowance.
     * @param _from address to burn extender tokens from
     * @param _to address to send shares to
     * @param _amount amount to convert
     * @dev Does not return a value
     */
    function withdrawFrom(address _from, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VaultAsset, VaultConfiguration} from "vault/VTypes.sol";

interface IVault {
    /* -------------------------------------------------------------------------- */
    /*                                Functionality                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice This function deposits `assetsIn` of `asset`, regardless of the amount of vault shares minted.
     * @notice If depositFee > 0, `depositFee` of `assetsIn` is sent to the fee recipient.
     * @dev emits Deposit(caller, receiver, asset, assetsIn, sharesOut);
     * @param assetAddr Asset to deposit.
     * @param assetsIn Amount of `asset` to deposit.
     * @param receiver Address to receive `sharesOut` of vault shares.
     * @return sharesOut Amount of vault shares minted for `assetsIn`.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function deposit(
        address assetAddr,
        uint256 assetsIn,
        address receiver
    ) external returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice This function mints `sharesOut` of vault shares, regardless of the amount of `asset` received.
     * @notice If depositFee > 0, `depositFee` of `assetsIn` is sent to the fee recipient.
     * @param assetAddr Asset to deposit.
     * @param sharesOut Amount of vault shares desired to mint.
     * @param receiver Address to receive `sharesOut` of shares.
     * @return assetsIn Assets used to mint `sharesOut` of vault shares.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Deposit(caller, receiver, asset, assetsIn, sharesOut);
     */
    function mint(address assetAddr, uint256 sharesOut, address receiver) external returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice This function burns `sharesIn` of shares from `owner`, regardless of the amount of `asset` received.
     * @notice If withdrawFee > 0, `withdrawFee` of `assetsOut` is sent to the fee recipient.
     * @param assetAddr Asset to redeem.
     * @param sharesIn Amount of vault shares to redeem.
     * @param receiver Address to receive the redeemed assets.
     * @param owner Owner of vault shares.
     * @return assetsOut Amount of `asset` used for redeem `assetsOut`.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Withdraw(caller, receiver, asset, owner, assetsOut, sharesIn);
     */
    function redeem(
        address assetAddr,
        uint256 sharesIn,
        address receiver,
        address owner
    ) external returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice This function withdraws `assetsOut` of assets, regardless of the amount of vault shares required.
     * @notice If withdrawFee > 0, `withdrawFee` of `assetsOut` is sent to the fee recipient.
     * @param assetAddr Asset to withdraw.
     * @param assetsOut Amount of `asset` desired to withdraw.
     * @param receiver Address to receive the withdrawn assets.
     * @param owner Owner of vault shares.
     * @return sharesIn Amount of vault shares used to withdraw `assetsOut` of `asset`.
     * @return assetFee Amount of fees paid in `asset`.
     * @dev emits Withdraw(caller, receiver, asset, owner, assetsOut, sharesIn);
     */
    function withdraw(
        address assetAddr,
        uint256 assetsOut,
        address receiver,
        address owner
    ) external returns (uint256 sharesIn, uint256 assetFee);

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns the current vault configuration
     * @return config Vault configuration struct
     */
    function getConfig() external view returns (VaultConfiguration memory config);

    /**
     * @notice Returns the total value of all assets in the shares contract in USD WAD precision.
     */
    function totalAssets() external view returns (uint256 result);

    /**
     * @notice Array of all assets
     */
    function allAssets() external view returns (VaultAsset[] memory assets);

    /**
     * @notice Assets array used for iterating through the assets in the shares contract
     */
    function assetList(uint256 index) external view returns (address assetAddr);

    /**
     * @notice Returns the asset struct for a given asset
     * @param asset Supported asset address
     * @return asset Asset struct for `asset`
     */
    function assets(address) external view returns (VaultAsset memory asset);

    function assetPrice(address assetAddr) external view returns (uint256);

    /**
     * @notice This function is used for previewing the amount of shares minted for `assetsIn` of `asset`.
     * @param assetAddr Supported asset address
     * @param assetsIn Amount of `asset` in.
     * @return sharesOut Amount of vault shares minted.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewDeposit(address assetAddr, uint256 assetsIn) external view returns (uint256 sharesOut, uint256 assetFee);

    /**
     * @notice This function is used for previewing `assetsIn` of `asset` required to mint `sharesOut` of vault shares.
     * @param assetAddr Supported asset address
     * @param sharesOut Desired amount of vault shares to mint.
     * @return assetsIn Amount of `asset` required.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewMint(address assetAddr, uint256 sharesOut) external view returns (uint256 assetsIn, uint256 assetFee);

    /**
     * @notice This function is used for previewing `assetsOut` of `asset` received for `sharesIn` of vault shares.
     * @param assetAddr Supported asset address
     * @param sharesIn Desired amount of vault shares to burn.
     * @return assetsOut Amount of `asset` received.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewRedeem(address assetAddr, uint256 sharesIn) external view returns (uint256 assetsOut, uint256 assetFee);

    /**
     * @notice This function is used for previewing `sharesIn` of vault shares required to burn for `assetsOut` of `asset`.
     * @param assetAddr Supported asset address
     * @param assetsOut Desired amount of `asset` out.
     * @return sharesIn Amount of vault shares required.
     * @return assetFee Amount of fees paid in `asset`.
     */
    function previewWithdraw(address assetAddr, uint256 assetsOut) external view returns (uint256 sharesIn, uint256 assetFee);

    /**
     * @notice Returns the maximum deposit amount of `asset`
     * @param assetAddr Supported asset address
     * @return assetsIn Maximum depositable amount of assets.
     */
    function maxDeposit(address assetAddr) external view returns (uint256 assetsIn);

    /**
     * @notice Returns the maximum mint using `asset`
     * @param assetAddr Supported asset address.
     * @param owner Owner of assets.
     * @return sharesOut Maximum mint amount.
     */
    function maxMint(address assetAddr, address owner) external view returns (uint256 sharesOut);

    /**
     * @notice Returns the maximum redeemable amount for `user`
     * @param assetAddr Supported asset address.
     * @param owner Owner of vault shares.
     * @return sharesIn Maximum redeemable amount of `shares` (vault share balance)
     */
    function maxRedeem(address assetAddr, address owner) external view returns (uint256 sharesIn);

    /**
     * @notice Returns the maximum redeemable amount for `user`
     * @param assetAddr Supported asset address.
     * @param owner Owner of vault shares.
     * @return amountOut Maximum amount of `asset` received.
     */
    function maxWithdraw(address assetAddr, address owner) external view returns (uint256 amountOut);

    /**
     * @notice Returns the exchange rate of one vault share to USD.
     * @return rate Exchange rate of one vault share to USD in wad precision.
     */
    function exchangeRate() external view returns (uint256 rate);

    /* -------------------------------------------------------------------------- */
    /*                                    Admin                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Adds a new asset to the vault
     * @param assetConfig Asset to add
     */
    function addAsset(VaultAsset memory assetConfig) external returns (VaultAsset memory);

    /**
     * @notice Removes an asset from the vault
     * @param assetAddr Asset address to remove
     * emits assetRemoved(asset, block.timestamp);
     */
    function removeAsset(address assetAddr) external;

    /**
     * @notice Current governance sets a new governance address
     * @param newGovernance The new governance address
     */
    function setGovernance(address newGovernance) external;

    function acceptGovernance() external;

    /**
     * @notice Current governance sets a new fee recipient address
     * @param newFeeRecipient The new fee recipient address
     */
    function setFeeRecipient(address newFeeRecipient) external;

    /**
     * @notice Sets a new oracle for a asset
     * @param assetAddr Asset to set the oracle for
     * @param feedAddr Feed to set
     * @param newStaleTime Time in seconds for the feed to be considered stale
     */
    function setAssetFeed(address assetAddr, address feedAddr, uint24 newStaleTime) external;

    /**
     * @notice Sets a new oracle decimals
     * @param newDecimals New oracle decimal precision
     */
    function setFeedPricePrecision(uint8 newDecimals) external;

    /**
     * @notice Sets the max deposit amount for a asset
     * @param assetAddr Asset to set the max deposits for
     * @param newMaxDeposits Max deposits to set
     */
    function setMaxDeposits(address assetAddr, uint248 newMaxDeposits) external;

    /**
     * @notice Sets the enabled status for a asset
     * @param assetAddr Asset to set the enabled status for
     * @param isEnabled Enabled status to set
     */
    function setAssetEnabled(address assetAddr, bool isEnabled) external;

    /**
     * @notice Sets the deposit fee for a asset
     * @param assetAddr Asset to set the deposit fee for
     * @param newDepositFee Fee to set
     */
    function setDepositFee(address assetAddr, uint16 newDepositFee) external;

    /**
     * @notice Sets the withdraw fee for a asset
     * @param assetAddr Asset to set the withdraw fee for
     * @param newWithdrawFee Fee to set
     */
    function setWithdrawFee(address assetAddr, uint16 newWithdrawFee) external;

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "kresko-lib/token/IERC20.sol";
import {IAggregatorV3} from "kresko-lib/vendor/IAggregatorV3.sol";

/**
 * @notice Asset struct for deposit assets in contract
 * @param token The ERC20 token
 * @param feed IAggregatorV3 feed for the asset
 * @param staleTime Time in seconds for the feed to be considered stale
 * @param maxDeposits Max deposits allowed for the asset
 * @param depositFee Deposit fee of the asset
 * @param withdrawFee Withdraw fee of the asset
 * @param enabled Enabled status of the asset
 */
struct VaultAsset {
    IERC20 token;
    IAggregatorV3 feed;
    uint24 staleTime;
    uint8 decimals;
    uint32 depositFee;
    uint32 withdrawFee;
    uint248 maxDeposits;
    bool enabled;
}

/**
 * @notice Vault configuration struct
 * @param sequencerUptimeFeed The feed address for the sequencer uptime
 * @param sequencerGracePeriodTime The grace period time for the sequencer
 * @param governance The governance address
 * @param feeRecipient The fee recipient address
 * @param oracleDecimals The oracle decimals
 */
struct VaultConfiguration {
    address sequencerUptimeFeed;
    uint96 sequencerGracePeriodTime;
    address governance;
    address pendingGovernance;
    address feeRecipient;
    uint8 oracleDecimals;
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
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
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