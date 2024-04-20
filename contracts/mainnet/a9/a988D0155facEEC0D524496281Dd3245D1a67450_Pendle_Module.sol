// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";
import "../../../utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
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

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view virtual returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(
        bytes4 interfaceId,
        bool status
    ) internal virtual {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Proxy } from '../../Proxy.sol';
import { IDiamondBase } from './IDiamondBase.sol';
import { DiamondBaseStorage } from './DiamondBaseStorage.sol';

/**
 * @title EIP-2535 "Diamond" proxy base contract
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
abstract contract DiamondBase is IDiamondBase, Proxy {
    /**
     * @inheritdoc Proxy
     */
    function _getImplementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        // inline storage layout retrieval uses less gas
        DiamondBaseStorage.Layout storage l;
        bytes32 slot = DiamondBaseStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        implementation = address(bytes20(l.facets[msg.sig]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IProxy } from '../../IProxy.sol';

interface IDiamondBase is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondReadable } from './IDiamondReadable.sol';

/**
 * @title EIP-2535 "Diamond" proxy introspection contract
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
abstract contract DiamondReadable is IDiamondReadable {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view returns (Facet[] memory diamondFacets) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        diamondFacets = new Facet[](l.selectorCount);

        uint8[] memory numFacetSelectors = new uint8[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (diamondFacets[facetIndex].target == facet) {
                        diamondFacets[facetIndex].selectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                diamondFacets[numFacets].target = facet;
                diamondFacets[numFacets].selectors = new bytes4[](
                    l.selectorCount
                );
                diamondFacets[numFacets].selectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }

        // setting the number of facets
        assembly {
            mstore(diamondFacets, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        selectors = new bytes4[](l.selectorCount);

        uint256 numSelectors;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                if (facet == address(bytes20(l.facets[selector]))) {
                    selectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        // set the number of selectors in the array
        assembly {
            mstore(selectors, numSelectors)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        addresses = new address[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facet == addresses[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                addresses[numFacets] = facet;
                numFacets++;
            }
        }

        // set the number of facet addresses in the array
        assembly {
            mstore(addresses, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet) {
        facet = address(bytes20(DiamondBaseStorage.layout().facets[selector]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritableInternal } from './IDiamondWritableInternal.sol';

abstract contract DiamondWritableInternal is IDiamondWritableInternal {
    using AddressUtils for address;

    bytes32 private constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 private constant CLEAR_SELECTOR_MASK =
        bytes32(uint256(0xffffffff << 224));

    /**
     * @notice update functions callable on Diamond proxy
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function _diamondCut(
        FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];
                FacetCutAction action = facetCut.action;

                if (facetCut.selectors.length == 0)
                    revert DiamondWritable__SelectorNotSpecified();

                if (action == FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = _addFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == FacetCutAction.REPLACE) {
                    _replaceFacetSelectors(l, facetCut);
                } else if (action == FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = _removeFacetSelectors(
                        l,
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            _initialize(target, data);
        }
    }

    function _addFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (
                facetCut.target != address(this) &&
                !facetCut.target.isContract()
            ) revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) != address(0))
                    revert DiamondWritable__SelectorAlreadyAdded();

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function _removeFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.target != address(0))
                revert DiamondWritable__RemoveTargetNotZeroAddress();

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                if (address(bytes20(oldFacet)) == address(0))
                    revert DiamondWritable__SelectorNotFound();

                if (address(bytes20(oldFacet)) == address(this))
                    revert DiamondWritable__SelectorIsImmutable();

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function _replaceFacetSelectors(
        DiamondBaseStorage.Layout storage l,
        FacetCut memory facetCut
    ) internal {
        unchecked {
            if (!facetCut.target.isContract())
                revert DiamondWritable__TargetHasNoCode();

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                if (oldFacetAddress == address(0))
                    revert DiamondWritable__SelectorNotFound();
                if (oldFacetAddress == address(this))
                    revert DiamondWritable__SelectorIsImmutable();
                if (oldFacetAddress == facetCut.target)
                    revert DiamondWritable__ReplaceTargetIsIdentical();

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function _initialize(address target, bytes memory data) private {
        if ((target == address(0)) != (data.length == 0))
            revert DiamondWritable__InvalidInitializationParameters();

        if (target != address(0)) {
            if (target != address(this)) {
                if (!target.isContract())
                    revert DiamondWritable__TargetHasNoCode();
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IDiamondWritableInternal {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    error DiamondWritable__InvalidInitializationParameters();
    error DiamondWritable__RemoveTargetNotZeroAddress();
    error DiamondWritable__ReplaceTargetIsIdentical();
    error DiamondWritable__SelectorAlreadyAdded();
    error DiamondWritable__SelectorIsImmutable();
    error DiamondWritable__SelectorNotFound();
    error DiamondWritable__SelectorNotSpecified();
    error DiamondWritable__TargetHasNoCode();

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        if (!implementation.isContract())
            revert Proxy__ImplementationIsNotContract();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title   Fee Controller
 * @notice  Set and take the protocol fee used by all vaults
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract FeeController is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_PROTOCOL_FEE = 5e17; // 50% - Mantissa format (1e18 = 100%)

    uint256 public protocolFee;
    address public feeReceiver;

    /**
     * @notice  Constructs the FeeController contract
     * @param   _protocolFee    Protocol fee fraction (mantissa format, 1e18 = 100%)
     * @param   _feeReceiver    Address receiving fees
     */
    constructor(uint256 _protocolFee, address _feeReceiver) {
        if (_protocolFee > MAX_PROTOCOL_FEE) revert FeeController__ExcessiveProtocolFee();
        if (_feeReceiver == address(0)) revert FeeController__ZeroAddress();
        protocolFee = _protocolFee;
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice  Withdraws fees from the contract
     * @dev     Can only be called by the contract owner.
     * @param   _tokens Tokens to withdraw
     */
    function withdrawFees(IERC20[] calldata _tokens) external onlyOwner {
        for (uint256 i; i < _tokens.length; ) {
            if (address(_tokens[i]) == address(0)) revert FeeController__ZeroAddress();
            uint256 balance = _tokens[i].balanceOf(address(this));
            if (balance > 0) _tokens[i].safeTransfer(feeReceiver, balance);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the protocol fee
     * @dev    Can only be called by the contract owner.
     * @param  _protocolFee New protocol fee in mantissa format (1e18 = 100%)
     */
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        if (_protocolFee > MAX_PROTOCOL_FEE) revert FeeController__ExcessiveProtocolFee();
        emit NewProtocolFee(protocolFee, _protocolFee);
        protocolFee = _protocolFee;
    }

    /**
     * @notice Sets the fee receiver address
     * @dev    Can only be called by the contract owner.
     * @param  _feeReceiver New fee receiver address
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        if (_feeReceiver == address(0)) revert FeeController__ZeroAddress();
        emit NewFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    event NewProtocolFee(uint256 oldProtocolFee, uint256 newProtocolFee);
    event NewFeeReceiver(address oldFeeReceiver, address newFeeReceiver);

    error FeeController__ExcessiveProtocolFee();
    error FeeController__ZeroAddress();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PublicVault } from "../PublicVault.sol";
import { IVaultDeployer } from "../interfaces/IVaultDeployer.sol";
import { IVault } from "../interfaces/IVault.sol";

/**
 * @title   Public Vault Deployer
 * @notice  Deploy public vaults
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 * @custom:developer    zug
 */
contract PublicVaultDeployer is IVaultDeployer {
    /**
     * @inheritdoc IVaultDeployer
     */
    function createVault(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _strategy,
        address _admin,
        address _vaultController,
        uint256 _maxDeposits
    ) external override returns (IVault) {
        PublicVault vault = new PublicVault(_asset, _name, _symbol, _strategy, _admin, _vaultController, _maxDeposits);
        return vault;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { Strategy_MVP } from "../trader/strategies/Strategy_MVP.sol";
import { TraderV0InitializerParams } from "../trader/trader/ITraderV0.sol";

/**
 * @title   Strategy Deployer
 * @notice  Deploy Strategy_MVP instances
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 * @custom:developer    zug
 */
contract StrategyDeployer {
    /**
     * @notice  Construct a new Strategy_MVP instance
     * @dev     The 'msg.sender' is passed as the vault setter address.
     * @dev     Facets and cutters MUST be provided in corresponding order
     * @dev     The first cutter and facet must belong to TraderV0.
     *
     * @param   _admin              Address to which the admin role is assigned
     * @param   _operator           Address to which the operator role is assigned
     * @param   _traderV0Params     Initialization parameters for TraderV0
     * @param   _cutters            Array of cutter addresses for strategy configuration
     * @param   _facets             Array of facet addresses for strategy configuration
     * @return  strategy            The newly created Strategy_MVP contract instance
     */

    function createStrategy(
        address _admin,
        address _operator,
        TraderV0InitializerParams memory _traderV0Params,
        address[] memory _cutters,
        address[] memory _facets
    ) external returns (Strategy_MVP) {
        Strategy_MVP strategy = new Strategy_MVP(_admin, _operator, msg.sender, _traderV0Params, _cutters, _facets);
        return strategy;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVault } from "../interfaces/IVault.sol";
import { IVaultDeployer } from "../interfaces/IVaultDeployer.sol";

import { PublicVaultDeployer } from "./PublicVaultDeployer.sol";
import { WhitelistedVaultDeployer } from "./WhitelistedVaultDeployer.sol";
import { StrategyDeployer } from "./StrategyDeployer.sol";
import { PublicVault } from "../PublicVault.sol";
import { WhitelistedVault } from "../WhitelistedVault.sol";
import { Strategy_MVP } from "../trader/strategies/Strategy_MVP.sol";
import { ITraderV0, TraderV0InitializerParams } from "../trader/trader/ITraderV0.sol";

/**
 * @title   Vault Factory
 * @notice  Factory contract for creating new vaults and strategies
 * @author  Vaultus Finance
 * @custom:developer BowTiedPickle
 * @custom:developer zug
 */
contract VaultFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // ---------- CONSTANTS ----------

    /// @notice Maximum allowable management fee as percentage of base assets per year, in units of 1e18 = 100%
    uint256 public constant MAX_MANAGEMENT_FEE = 5e16; // 5%

    /// @notice Maximum allowable management fee as percentage of base assets per year, where 1e18 = 100%
    uint256 public constant MAX_PERFORMANCE_FEE = 1e17; // 10%

    /// @notice Maximum BASIC vault creation fee in USDC
    uint256 public constant MAX_USDC_BASIC_VAULT_FEE = 100e6; // 100 USDC

    /// @notice Maximum PRO vault creation fee in USDC
    uint256 public constant MAX_USDC_PRO_VAULT_FEE = 200e6; // 200 USDC

    /// @notice Enum for differentiating between basic and pro vault types
    enum VaultType {
        Basic,
        Pro
    }

    /// @notice Enum for differentiating between public and whitelisted vault access
    enum VaultAccess {
        Public,
        Whitelisted
    }

    // ---------- STATE VARIABLES ----------

    /**
     * @notice  Module configuration
     * @param   facet               Facet address
     * @param   cutter              Cutter address
     * @param   necessaryTokens     List of tokens necessary for the module to function (eg. WETH, internal tokens)
     * @param   necessaryApprovals  List of addresses to which approvals are necessary for the module to function
     */
    struct ModuleConfig {
        address facet;
        address cutter;
        EnumerableSet.AddressSet necessaryTokens;
        EnumerableSet.AddressSet necessaryApprovals;
    }

    /// @notice Configuration for vault modules, including facets, cutters, and necessary tokens/approvals
    mapping(uint256 => ModuleConfig) internal modules;

    /// @notice Total number of configured modules
    uint256 public configuredModuleCount = 15;

    /**
     * @notice  Underlying asset configuration
     * @dev     Deposit limits are in units of the underlying asset
     * @dev     If a deposit limit is set to 0, the asset is not supported
     * @param   maxProDepositLimit      Maximum deposit limit for pro tier vaults
     * @param   maxBasicDepositLimit    Maximum deposit limit for basic tier vaults
     */
    struct UnderlyingConfig {
        uint256 maxProDepositLimit;
        uint256 maxBasicDepositLimit;
    }

    /// @notice Configuration for underlying assets, including deposit limits for different vault types
    mapping(address => UnderlyingConfig) public underlyingConfigs;

    /// @notice Set of whitelisted tokens that can be used in vaults or traded by strategies
    EnumerableSet.AddressSet internal whitelistedTokens;

    /// @notice Addresses whitelisted to create pro tier vaults
    mapping(address => bool) public whitelistedOperators;

    /// @notice Basic vault creation fee
    uint256 public basicVaultFee;

    /// @notice Pro vault creation fee
    uint256 public proVaultFee;

    /// @notice USDC token
    IERC20 public immutable usdc;

    /// @notice Public vault deployer contract
    PublicVaultDeployer public publicVaultDeployer;

    /// @notice Whitelisted vault deployer contract
    WhitelistedVaultDeployer public whitelistedVaultDeployer;

    /// @notice Contract responsible for deploying new strategies
    StrategyDeployer public strategyDeployer;

    /// @notice Address with administrative control over new vaults
    address public vaultController;

    /// @notice Address responsible for handling protocol fees
    address public feeController;

    // ---------- REGISTRY VARIABLES ----------

    /// @dev    Tracks all vaults created by the factory
    EnumerableSet.AddressSet internal vaults;

    // ---------- CONSTRUCTOR ----------

    /**
     * @param   _publicVaultDeployer        Public vault deployer address
     * @param   _whitelistedVaultDeployer   Whitelisted vault deployer address
     * @param   _strategyDeployer           Strategy deployer address
     * @param   _vaultController            Vault controller address
     * @param   _feeController              Fee controller address
     * @param   _usdcAddress                USDC token address
     * @param   _basicVaultFee              Basic vault creation fee
     * @param   _proVaultFee                Pro vault creation fee
     */
    constructor(
        address _publicVaultDeployer,
        address _whitelistedVaultDeployer,
        address _strategyDeployer,
        address _vaultController,
        address _feeController,
        address _usdcAddress,
        uint256 _basicVaultFee,
        uint256 _proVaultFee
    ) {
        if (
            _publicVaultDeployer == address(0) ||
            _whitelistedVaultDeployer == address(0) ||
            _strategyDeployer == address(0) ||
            _vaultController == address(0) ||
            _feeController == address(0) ||
            _usdcAddress == address(0)
        ) revert VaultFactory__ZeroAddress();

        if (_basicVaultFee > MAX_USDC_BASIC_VAULT_FEE || _proVaultFee > MAX_USDC_PRO_VAULT_FEE) revert VaultFactory__ExcessiveVaultFee();

        // Assign param addresses to the state variables
        publicVaultDeployer = PublicVaultDeployer(_publicVaultDeployer);
        whitelistedVaultDeployer = WhitelistedVaultDeployer(_whitelistedVaultDeployer);
        strategyDeployer = StrategyDeployer(_strategyDeployer);
        vaultController = _vaultController;
        feeController = _feeController;
        usdc = IERC20(_usdcAddress);
        basicVaultFee = _basicVaultFee;
        proVaultFee = _proVaultFee;
    }

    // ---------- PUBLIC FUNCTIONS ----------

    /**
     * @param   vaultType       Vault type
     * @param   asset           Underlying asset of the vault
     * @param   name            Vault name
     * @param   symbol          Vault symbol
     * @param   operator        Strategy operator address
     * @param   depositLimit    Initial maximum deposits allowed
     * @param   managementFee   Management fee
     * @param   performanceFee  Performance fee
     * @param   moduleSelection Bitmask of modules to enable
     * @param   allowedTokens   List of tokens allowed to be handled by the strategy
     */
    struct VaultConstructorParams {
        VaultType vaultType;
        VaultAccess vaultAccess;
        address asset;
        string name;
        string symbol;
        address operator;
        address feeReceiver;
        uint256 depositLimit;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 moduleSelection;
        address[] allowedTokens;
    }

    /**
     * @notice  Construct new instances of the vault and strategy contracts
     * @dev     WARNING: Double-check your inputs before calling this function. Many values cannot be changed after deployment.
     * @param   _params         Vault constructor parameters
     * @return  vault           Vault address
     * @return  strategy        Strategy address
     */
    function createVault(VaultConstructorParams calldata _params) external returns (address, address) {
        // Invalidity checks
        if (_params.asset == address(0) || _params.operator == address(0)) revert VaultFactory__ZeroAddress();
        if (bytes(_params.name).length == 0 || bytes(_params.symbol).length == 0) revert VaultFactory__EmptyString();
        if (_params.managementFee > MAX_MANAGEMENT_FEE) revert VaultFactory__ExcessiveManagementFee();
        if (_params.performanceFee > MAX_PERFORMANCE_FEE) revert VaultFactory__ExcessivePerformanceFee();

        bool assetInAllowed;
        for (uint256 i; i < _params.allowedTokens.length; ) {
            if (!whitelistedTokens.contains(_params.allowedTokens[i])) revert VaultFactory__TokenNotWhitelisted();
            if (_params.allowedTokens[i] == _params.asset) {
                assetInAllowed = true;
            }
            unchecked {
                i++;
            }
        }
        if (!assetInAllowed) revert VaultFactory__AssetNotInAllowedTokens();

        UnderlyingConfig memory config = underlyingConfigs[_params.asset];
        uint256 maxDepositLimit;
        if (_params.vaultType == VaultType.Pro) {
            if (!whitelistedOperators[msg.sender]) revert VaultFactory__NotWhitelisted();
            maxDepositLimit = config.maxProDepositLimit;
        } else {
            maxDepositLimit = config.maxBasicDepositLimit;
        }

        if (maxDepositLimit == 0) revert VaultFactory__AssetNotSupported();
        if (_params.depositLimit == 0 || _params.depositLimit > maxDepositLimit) revert VaultFactory__MaxDepositOutsideBounds();

        // Require vault creation fee payment
        uint256 feeAmount = _params.vaultType == VaultType.Pro ? proVaultFee : basicVaultFee;
        if (!usdc.transferFrom(msg.sender, feeController, feeAmount)) revert VaultFactory__VaultFeePaymentFailed();

        // Setup modules
        (
            address[] memory moduleCutters,
            address[] memory moduleFacets,
            address[] memory necessaryTokens,
            address[] memory necessaryApprovals
        ) = getModuleInfo(_params.moduleSelection);

        // Create strategy
        address strategy = address(
            strategyDeployer.createStrategy(
                vaultController,
                _params.operator,
                TraderV0InitializerParams(
                    _params.name,
                    _params.feeReceiver,
                    feeController,
                    concatenateAddressArrays(_params.allowedTokens, necessaryTokens),
                    necessaryApprovals,
                    _params.performanceFee,
                    _params.managementFee
                ),
                moduleCutters,
                moduleFacets
            )
        );

        // Create vault
        IVaultDeployer deployer = _params.vaultAccess == VaultAccess.Public
            ? IVaultDeployer(publicVaultDeployer)
            : IVaultDeployer(whitelistedVaultDeployer);

        address vault = address(
            deployer.createVault(
                IERC20(_params.asset),
                _params.name,
                _params.symbol,
                strategy,
                _params.operator,
                vaultController,
                _params.depositLimit
            )
        );
        vaults.add(vault);
        emit NewVault(vault, strategy, uint256(_params.moduleSelection), uint8(_params.vaultType), uint8(_params.vaultAccess));

        // Configuration
        ITraderV0(payable(strategy)).setVault(vault);
        IAccessControl(strategy).renounceRole(bytes32(keccak256("VAULT_SETTER_ROLE")));

        return (vault, strategy);
    }

    // ---------- INTERNAL FUNCTIONS ----------

    /**
     * @notice  Retrieves information about the configured modules based on a selection bitmask
     * @dev     The first index of the `moduleCutters` and `moduleFacets` arrays always corresponds to the TraderV0 module.
     *
     * @param   moduleSelection     Bitmask representing the selection of modules, where the 0th bit corresponds to module ID 1
     * @return  moduleCutters       Array of addresses representing the cutters for the selected modules
     * @return  moduleFacets        Array of addresses representing the facets for the selected modules
     * @return  necessaryTokens     Array of token addresses required by the selected modules
     * @return  necessaryApprovals  Array of addresses to which approvals are necessary for the selected modules
     */
    function getModuleInfo(
        uint256 moduleSelection
    ) internal view returns (address[] memory, address[] memory, address[] memory, address[] memory) {
        address[] memory moduleFacets = new address[](configuredModuleCount);
        address[] memory moduleCutters = new address[](configuredModuleCount);

        uint256 necessaryTokensLength;
        uint256 necessaryApprovalsLength;

        // TraderV0
        moduleFacets[0] = modules[0].facet;
        moduleCutters[0] = modules[0].cutter;
        necessaryTokensLength += modules[0].necessaryTokens.length();
        necessaryApprovalsLength += modules[0].necessaryApprovals.length();

        for (uint256 i = 1; i < configuredModuleCount; ) {
            if (moduleSelection & (1 << (i - 1)) == (1 << (i - 1))) {
                ModuleConfig storage module = modules[i];
                moduleFacets[i] = module.facet;
                moduleCutters[i] = module.cutter;
                necessaryTokensLength += module.necessaryTokens.length();
                necessaryApprovalsLength += module.necessaryApprovals.length();
            }
            unchecked {
                ++i;
            }
        }

        address[] memory necessaryTokens = new address[](necessaryTokensLength);
        address[] memory necessaryApprovals = new address[](necessaryApprovalsLength);
        uint256 necessaryTokensIndex;
        uint256 necessaryApprovalsIndex;

        for (uint256 i; i < moduleFacets.length; ) {
            if (moduleFacets[i] != address(0)) {
                ModuleConfig storage module = modules[i];
                for (uint256 j; j < module.necessaryTokens.length(); ) {
                    necessaryTokens[necessaryTokensIndex] = module.necessaryTokens.at(j);
                    unchecked {
                        ++necessaryTokensIndex;
                        ++j;
                    }
                }
                for (uint256 j; j < module.necessaryApprovals.length(); ) {
                    necessaryApprovals[necessaryApprovalsIndex] = module.necessaryApprovals.at(j);
                    unchecked {
                        ++necessaryApprovalsIndex;
                        ++j;
                    }
                }
            }
            unchecked {
                ++i;
            }
        }

        return (moduleCutters, moduleFacets, necessaryTokens, necessaryApprovals);
    }

    /// @dev utility function for concatenating two arrays of addresses
    function concatenateAddressArrays(address[] memory _a, address[] memory _b) internal pure returns (address[] memory) {
        address[] memory result = new address[](_a.length + _b.length);
        uint256 index;
        for (uint256 i; i < _a.length; ) {
            result[index] = _a[i];
            unchecked {
                ++index;
                ++i;
            }
        }
        for (uint256 i; i < _b.length; ) {
            result[index] = _b[i];
            unchecked {
                ++index;
                ++i;
            }
        }
        return result;
    }

    // ---------- VIEW FUNCTIONS ----------

    /**
     * @notice  Get the list of whitelisted tokens
     * @return  List of whitelisted tokens
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return whitelistedTokens.values();
    }

    /**
     * @notice  Get whether a token is whitelisted
     * @return  True if the token is whitelisted
     */
    function isWhitelistedToken(address _token) external view returns (bool) {
        return whitelistedTokens.contains(_token);
    }

    /**
     * @param   facet               Module facet
     * @param   cutter              Module cutter
     * @param   necessaryTokens     List of tokens necessary for the module to function (eg. WETH, internal tokens)
     * @param   necessaryApprovals  List of addresses to which approvals are necessary for the module to function
     */
    struct ModuleConfigOutput {
        address facet;
        address cutter;
        address[] necessaryTokens;
        address[] necessaryApprovals;
    }

    /**
     * @notice  Get the configuration details for a module
     * @param   _moduleId   Module ID
     * @return  Module configuration
     */
    function getModule(uint256 _moduleId) external view returns (ModuleConfigOutput memory) {
        ModuleConfig storage module = modules[_moduleId];
        return ModuleConfigOutput(module.facet, module.cutter, module.necessaryTokens.values(), module.necessaryApprovals.values());
    }

    /**
     * @notice  Get the list of vaults
     * @return  List of vaults
     */
    function getVaults() external view returns (address[] memory) {
        return vaults.values();
    }

    /**
     * @notice  Get the number of vaults
     * @return  Number of vaults
     */
    function getVaultCount() external view returns (uint256) {
        return vaults.length();
    }

    /**
     * @notice  Get a vault by index
     * @param   _index  Index of the vault
     * @return  Vault address
     */
    function getVaultAt(uint256 _index) external view returns (address) {
        return vaults.at(_index);
    }

    /**
     * @notice  Get whether a vault is registered
     * @param   _vault  Vault address
     * @return  True if the vault is registered
     */
    function isVault(address _vault) external view returns (bool) {
        return vaults.contains(_vault);
    }

    // ---------- RESTRICTED FUNCTIONS ----------

    /**
     * @notice Sets the public vault deployer
     * @param  _publicVaultDeployer         New public vault deployer address
     */
    function setPublicVaultDeployer(address _publicVaultDeployer) external onlyOwner {
        if (_publicVaultDeployer == address(0)) revert VaultFactory__ZeroAddress();
        emit NewVaultDeployer(address(publicVaultDeployer), _publicVaultDeployer, uint8(VaultAccess.Public));
        publicVaultDeployer = PublicVaultDeployer(_publicVaultDeployer);
    }

    /**
     * @notice Sets the whitelisted vault deployer
     * @param  _whitelistedVaultDeployer    New whitelisted vault deployer address
     */
    function setWhitelistedVaultDeployer(address _whitelistedVaultDeployer) external onlyOwner {
        if (_whitelistedVaultDeployer == address(0)) revert VaultFactory__ZeroAddress();
        emit NewVaultDeployer(address(whitelistedVaultDeployer), _whitelistedVaultDeployer, uint8(VaultAccess.Whitelisted));
        whitelistedVaultDeployer = WhitelistedVaultDeployer(_whitelistedVaultDeployer);
    }

    /**
     * @notice  Sets the strategy deployer
     * @param   _strategyDeployer   New strategy deployer address
     */
    function setStrategyDeployer(address _strategyDeployer) external onlyOwner {
        if (_strategyDeployer == address(0)) revert VaultFactory__ZeroAddress();
        emit NewStrategyDeployer(address(strategyDeployer), _strategyDeployer);
        strategyDeployer = StrategyDeployer(_strategyDeployer);
    }

    /**
     * @notice  Sets the vault controller
     * @param   _vaultController    New vault controller address
     */
    function setVaultController(address _vaultController) external onlyOwner {
        if (_vaultController == address(0)) revert VaultFactory__ZeroAddress();
        emit NewVaultController(vaultController, _vaultController);
        vaultController = _vaultController;
    }

    /**
     * @notice  Sets the fee controller
     * @param   _feeController  New fee controller address
     */
    function setFeeController(address _feeController) external onlyOwner {
        if (_feeController == address(0)) revert VaultFactory__ZeroAddress();
        emit NewFeeController(feeController, _feeController);
        feeController = _feeController;
    }

    /**
     * @notice  Sets the basic vault creation fee
     * @param   _amount     New basic vault creation fee
     */
    function setBasicVaultFee(uint256 _amount) external onlyOwner {
        if (_amount > MAX_USDC_BASIC_VAULT_FEE) revert VaultFactory__ExcessiveVaultFee();
        emit NewVaultFee(false, basicVaultFee, _amount);
        basicVaultFee = _amount;
    }

    /**
     * @notice  Sets the pro vault creation fee
     * @param   _amount     New pro vault creation fee
     */
    function setProVaultFee(uint256 _amount) external onlyOwner {
        if (_amount > MAX_USDC_PRO_VAULT_FEE) revert VaultFactory__ExcessiveVaultFee();
        emit NewVaultFee(true, proVaultFee, _amount);
        proVaultFee = _amount;
    }

    /**
     * @notice  Set operator whitelist status for a list of addresses
     * @param   _addresses      List of addresses
     * @param   _whitelisted    List of whitelist statuses
     */
    function setOperatorWhitelist(address[] calldata _addresses, bool[] calldata _whitelisted) external onlyOwner {
        if (_addresses.length != _whitelisted.length) revert VaultFactory__LengthMismatch();
        for (uint256 i; i < _addresses.length; ) {
            whitelistedOperators[_addresses[i]] = _whitelisted[i];
            emit Whitelisted(_addresses[i], _whitelisted[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice  Set underlying configuration for a list of assets
     * @param   _assets         List of assets
     * @param   _configs        List of underlying configurations
     */
    function setUnderlyingConfiguration(address[] calldata _assets, UnderlyingConfig[] calldata _configs) external onlyOwner {
        if (_assets.length != _configs.length) revert VaultFactory__LengthMismatch();
        for (uint256 i; i < _assets.length; ) {
            underlyingConfigs[_assets[i]] = _configs[i];
            emit NewUnderlyingConfig(_assets[i], _configs[i].maxProDepositLimit, _configs[i].maxBasicDepositLimit);
            unchecked {
                i++;
            }
        }
    }

    struct ModuleConfigInput {
        address facet;
        address cutter;
        address[] necessaryTokens;
        bool[] necessaryTokenAdd;
        address[] necessaryApprovals;
        bool[] necessaryApprovalsAdd;
    }

    /**
     * @notice  Set module configuration for a list of modules
     * @dev     Facet and cutter addresses may be set to the zero address to disable the module
     * @dev     Module IDs greater than the configured module count will not be fetched in a call to `getModuleInfo`
     * @param   _moduleIds      List of module IDs
     * @param   _configs        List of module configurations
     */
    function setModuleConfiguration(uint256[] calldata _moduleIds, ModuleConfigInput[] calldata _configs) external onlyOwner {
        if (_moduleIds.length != _configs.length) revert VaultFactory__LengthMismatch();
        for (uint256 i; i < _moduleIds.length; ) {
            if (_configs[i].necessaryTokens.length != _configs[i].necessaryTokenAdd.length) revert VaultFactory__LengthMismatch();
            if (_configs[i].necessaryApprovals.length != _configs[i].necessaryApprovalsAdd.length) revert VaultFactory__LengthMismatch();

            ModuleConfig storage module = modules[_moduleIds[i]];
            module.facet = _configs[i].facet;
            module.cutter = _configs[i].cutter;
            for (uint256 j; j < _configs[i].necessaryTokens.length; ) {
                if (_configs[i].necessaryTokenAdd[j]) {
                    module.necessaryTokens.add(_configs[i].necessaryTokens[j]);
                } else {
                    module.necessaryTokens.remove(_configs[i].necessaryTokens[j]);
                }
                unchecked {
                    j++;
                }
            }
            for (uint256 j; j < _configs[i].necessaryApprovals.length; ) {
                if (_configs[i].necessaryApprovalsAdd[j]) {
                    module.necessaryApprovals.add(_configs[i].necessaryApprovals[j]);
                } else {
                    module.necessaryApprovals.remove(_configs[i].necessaryApprovals[j]);
                }
                unchecked {
                    j++;
                }
            }

            emit NewModuleConfig(_moduleIds[i], _configs[i].facet, _configs[i].cutter);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice  Set the number of configured modules
     * @param   _count  New module count
     */
    function setModuleCount(uint256 _count) external onlyOwner {
        if (_count == 0) revert VaultFactory__ModuleCountTooLow();
        configuredModuleCount = _count;
        emit NewModuleCount(_count);
    }

    /**
     * @notice  Set whitelist status for a list of tokens
     * @param   _tokens         List of token addresses
     * @param   _whitelisted    List of whitelist statuses
     */
    function setTokenWhitelist(address[] calldata _tokens, bool[] calldata _whitelisted) external onlyOwner {
        if (_tokens.length != _whitelisted.length) revert VaultFactory__LengthMismatch();
        for (uint256 i; i < _tokens.length; ) {
            if (_whitelisted[i]) {
                whitelistedTokens.add(_tokens[i]);
            } else {
                whitelistedTokens.remove(_tokens[i]);
            }
            emit TokenWhitelisted(_tokens[i], _whitelisted[i]);
            unchecked {
                i++;
            }
        }
    }

    // ---------- EVENTS ----------

    event NewVaultDeployer(address indexed oldDeployer, address indexed newDeployer, uint8 access);
    event NewVault(address indexed vault, address indexed strategy, uint256 indexed moduleSelection, uint8 vaultType, uint8 vaultAccess);
    event NewStrategyDeployer(address indexed oldDeployer, address indexed newDeployer);
    event NewVaultController(address indexed oldController, address indexed newController);
    event NewFeeController(address indexed oldController, address indexed newController);
    event NewVaultFee(bool indexed isPro, uint256 oldFee, uint256 newFee);
    event NewUnderlyingConfig(address indexed underlying, uint256 maxProDepositLimit, uint256 maxBasicDepositLimit);
    event NewModuleConfig(uint256 indexed moduleId, address facet, address cutter);
    event NewModuleCount(uint256 count);
    event Whitelisted(address indexed account, bool whitelisted);
    event TokenWhitelisted(address indexed token, bool whitelisted);

    // ---------- ERRORS ----------

    error VaultFactory__ZeroAddress();
    error VaultFactory__EmptyString();
    error VaultFactory__LengthMismatch();
    error VaultFactory__MaxDepositOutsideBounds();
    error VaultFactory__ExcessiveManagementFee();
    error VaultFactory__ExcessivePerformanceFee();
    error VaultFactory__ExcessiveVaultFee();
    error VaultFactory__VaultFeePaymentFailed();
    error VaultFactory__NotWhitelisted();
    error VaultFactory__AssetNotSupported();
    error VaultFactory__AssetNotInAllowedTokens();
    error VaultFactory__TokenNotWhitelisted();
    error VaultFactory__ModuleCountTooLow();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WhitelistedVault } from "../WhitelistedVault.sol";
import { IVaultDeployer } from "../interfaces/IVaultDeployer.sol";
import { IVault } from "../interfaces/IVault.sol";

/**
 * @title   Whitelisted Vault Deployer
 * @notice  Deploy whitelisted vaults
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 * @custom:developer    zug
 */
contract WhitelistedVaultDeployer is IVaultDeployer {
    /**
     * @inheritdoc IVaultDeployer
     */
    function createVault(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _strategy,
        address _admin,
        address _vaultController,
        uint256 _maxDeposits
    ) external override returns (IVault) {
        WhitelistedVault vault = new WhitelistedVault(_asset, _name, _symbol, _strategy, _admin, _vaultController, _maxDeposits);
        return vault;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IFeeController {
    // ---------- CONSTANTS ----------

    function MAX_PROTOCOL_FEE() external view returns (uint256);

    // ---------- STATE VARIABLES ----------

    function protocolFee() external view returns (uint256);

    // ---------- RESTRICTED FUNCTIONS ----------

    function setProtocolFee(uint256 _protocolFee) external;

    // ---------- EVENTS ----------

    event NewProtocolFee(uint256 oldProtocolFee, uint256 newProtocolFee);

    // ---------- ERRORS ----------
    error FeeController__ExcessiveProtocolFee();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

struct Epoch {
    uint256 fundingStart;
    uint256 epochStart;
    uint256 epochEnd;
}

/**
 * @title   IVault
 * @dev     Interface for Vaultus Finance Investment Vaults
 * @author  Valtus Finance
 * @custom:developer zug
 */
interface IVault {
    function VAULT_ACCESS() external view returns (uint8);

    function asset() external returns (address);

    function startEpoch(uint80 _fundingStart, uint80 _epochStart, uint80 _epochEnd) external;

    function setMaxDeposits(uint256 _newMax) external;

    function custodyFunds() external returns (uint256);

    function returnFunds(uint256 _amount) external;

    function getCurrentEpoch() external view returns (uint256);

    function getCurrentEpochInfo() external view returns (Epoch memory);

    function isFunding() external view returns (bool);

    function isInEpoch() external view returns (bool);

    function notCustodiedAndDuringFunding() external view returns (bool);

    function notCustodiedAndNotDuringEpoch() external view returns (bool);

    function maxDeposit(address receiver) external view returns (uint256);

    function maxMint(address receiver) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "./IVault.sol";

/**
 * @author  Vaultus Finance
 */
interface IVaultDeployer {
    /**
     * @notice  Creates a new vault instance
     * @param   _asset              Underlying asset of the vault.
     * @param   _name               Name of the vault.
     * @param   _symbol             Symbol of the vault.
     * @param   _strategy           Address of the strategy for the vault.
     * @param   _admin              Admin address for the vault.
     * @param   _vaultController    Address of the vault controller.
     * @param   _maxDeposits        Initial maximum deposits allowed in the vault, in units of the underlying asset
     * @return  vault               Newly created vault address in IVault form.
     */
    function createVault(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _strategy,
        address _admin,
        address _vaultController,
        uint256 _maxDeposits
    ) external returns (IVault);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./interfaces/IVault.sol";

/**
 * @title   Vaultus Finance Public Investment Vault v0.1.0
 * @notice  Deposit an ERC-20 to earn yield via managed trading
 * @notice  Public variant: anyone can participate in the vault
 * @dev     ERC-4626 compliant
 * @dev     Does not support rebasing or transfer fee tokens.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle, zug
 */
contract PublicVault is ERC4626, Ownable, IVault {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // ----- Events -----

    event EpochStarted(uint256 indexed epoch, uint256 fundingStart, uint256 epochStart, uint256 epochEnd);
    event FundsCustodied(uint256 indexed epoch, uint256 amount);
    event FundsReturned(uint256 indexed epoch, uint256 amount);
    event NewMaxDeposits(uint256 oldMax, uint256 newMax);

    // ----- State Variables -----

    uint256 public constant MAX_EPOCH_DURATION = 30 days;
    uint256 public constant MIN_FUNDING_DURATION = 2 days;

    mapping(uint256 => Epoch) public epochs;
    Counters.Counter internal epochId;

    /// @notice Whether the epoch has been started
    bool public started;

    /// @notice Whether funds are currently out with the custodian
    bool public custodied;

    /// @notice Amount of funds sent to custodian
    uint256 public custodiedAmount;

    /// @notice Address which can take custody of funds to execute strategies during an epoch
    address public immutable strategy;

    /// @notice Protocol governance address
    address public immutable governance;

    /// @notice Maximum allowable deposits to the vault
    uint256 public maxDeposits;

    /// @notice Current deposits
    uint256 public totalDeposits;

    /// @notice Vault's visibility 0 for public
    uint8 public constant VAULT_ACCESS = 0;

    // ----- Modifiers -----

    modifier onlyStrategy() {
        require(msg.sender == strategy, "!strategy");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier notCustodied() {
        require(!custodied, "custodied");
        _;
    }

    modifier duringFunding() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart, "!funding");
        _;
    }

    modifier notDuringEpoch() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) < epoch.epochStart || uint80(block.timestamp) >= epoch.epochEnd, "during");
        _;
    }

    modifier duringEpoch() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) >= epoch.epochStart && uint80(block.timestamp) < epoch.epochEnd, "!during");
        _;
    }

    // ----- Construction -----

    /**
     * @param   _asset          Underlying asset of the vault
     * @param   _name           Vault name
     * @param   _symbol         Vault symbol
     * @param   _strategy       Strategy address
     * @param   _admin          Admin address
     * @param   _governance     Governance address
     * @param   _maxDeposits    Initial maximum deposits allowed
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _strategy,
        address _admin,
        address _governance,
        uint256 _maxDeposits
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        require(_strategy != address(0) && _governance != address(0) && _admin != address(0), "!zeroAddr");
        strategy = _strategy;
        governance = _governance;
        maxDeposits = _maxDeposits;
        _transferOwnership(_admin);
    }

    // ----- Admin Functions -----

    /**
     * @notice  Start a new epoch and set its time parameters
     * @param   _fundingStart Start timestamp of the funding phase in unix epoch seconds
     * @param   _epochStart   Start timestamp of the epoch in unix epoch seconds
     * @param   _epochEnd     End timestamp of the epoch in unix epoch seconds
     */
    function startEpoch(uint80 _fundingStart, uint80 _epochStart, uint80 _epochEnd) external override onlyOwner notDuringEpoch {
        require(!started || !custodied, "!allowed");
        require(
            _epochEnd > _epochStart && _epochStart >= _fundingStart + MIN_FUNDING_DURATION && _fundingStart >= uint80(block.timestamp),
            "!timing"
        );
        require(_epochEnd <= _epochStart + MAX_EPOCH_DURATION, "!epochLen");

        epochId.increment();
        uint256 currentEpoch = getCurrentEpoch();
        Epoch storage epoch = epochs[currentEpoch];

        epoch.fundingStart = _fundingStart;
        epoch.epochStart = _epochStart;
        epoch.epochEnd = _epochEnd;

        started = true;

        emit EpochStarted(currentEpoch, _fundingStart, _epochStart, _epochEnd);
    }

    /**
     * @notice  Set new maximum deposit limit
     * @param   _newMax New maximum deposit limit
     */
    function setMaxDeposits(uint256 _newMax) external override onlyGovernance {
        emit NewMaxDeposits(maxDeposits, _newMax);
        maxDeposits = _newMax;
    }

    // ----- Strategy Functions -----

    /**
     * @notice  Take custody of the vault's funds for the purpose of executing trading strategies
     */
    function custodyFunds() external override onlyStrategy notCustodied duringEpoch returns (uint256) {
        uint256 amount = totalAssets();
        require(amount > 0, "!amount");

        custodied = true;
        custodiedAmount = amount;
        IERC20(asset()).safeTransfer(strategy, amount);

        emit FundsCustodied(epochId.current(), amount);
        return amount;
    }

    /**
     * @notice  Return custodied funds to the vault
     * @param   _amount     Amount to return
     * @dev     The strategy is responsible for returning the whole sum taken into custody.
     *          Losses may be sustained during the trading, in which case the investors will suffer a loss.
     *          Returning the funds ends the epoch.
     */
    function returnFunds(uint256 _amount) external override onlyStrategy {
        require(custodied, "!custody");
        require(_amount > 0, "!amount");
        IERC20(asset()).safeTransferFrom(strategy, address(this), _amount);

        uint256 currentEpoch = getCurrentEpoch();
        Epoch storage epoch = epochs[currentEpoch];
        epoch.epochEnd = uint80(block.timestamp);

        custodiedAmount = 0;
        custodied = false;
        started = false;
        totalDeposits = totalAssets();

        emit FundsReturned(currentEpoch, _amount);
    }

    // ----- View Functions -----

    /**
     * @notice  Get the current epoch ID
     * @return  Current epoch ID
     */
    function getCurrentEpoch() public view override returns (uint256) {
        return epochId.current();
    }

    /**
     * @notice  Get the current epoch information
     * @return  Current epoch information
     */
    function getCurrentEpochInfo() external view override returns (Epoch memory) {
        return epochs[epochId.current()];
    }

    /**
     * @notice  View whether the contract state is in funding phase
     * @return  True if in funding phase
     */
    function isFunding() external view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart;
    }

    /**
     * @notice  View whether the contract state is in epoch phase
     * @return  True if in epoch phase
     */
    function isInEpoch() external view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return uint80(block.timestamp) >= epoch.epochStart && uint80(block.timestamp) < epoch.epochEnd;
    }

    /**
     * @notice  Returns true if notCustodied and duringFunding modifiers would pass
     * @dev     Only to be used with previewDeposit and previewMint
     */
    function notCustodiedAndDuringFunding() public view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return (!custodied && (uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart));
    }

    /**
     * @notice  Returns true if notCustodied and notDuringEpoch modifiers would pass
     * @dev     Only to be used with previewRedeem and previewWithdraw
     */
    function notCustodiedAndNotDuringEpoch() public view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return (!custodied && (uint80(block.timestamp) < epoch.epochStart || uint80(block.timestamp) >= epoch.epochEnd));
    }

    // ----- Overrides -----

    /// @dev    See EIP-4626
    function asset() public view override(ERC4626, IVault) returns (address) {
        return ERC4626.asset();
    }

    /// @dev    See EIP-4626
    function maxDeposit(address) public view override(ERC4626, IVault) returns (uint256) {
        if (custodied) return 0;
        return totalDeposits > maxDeposits ? 0 : maxDeposits - totalDeposits;
    }

    /// @dev    See EIP-4626
    function maxMint(address) public view override(ERC4626, IVault) returns (uint256) {
        return convertToShares(maxDeposit(msg.sender));
    }

    /// @dev    See EIP-4626
    function deposit(uint256 assets, address receiver) public override(ERC4626, IVault) notCustodied duringFunding returns (uint256) {
        require(assets <= maxDeposit(receiver), "!maxDeposit");
        return ERC4626.deposit(assets, receiver);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if not during funding window
    function previewDeposit(uint256 assets) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndDuringFunding()) ? ERC4626.previewDeposit(assets) : 0;
    }

    /// @dev    See EIP-4626
    function mint(uint256 shares, address receiver) public override(ERC4626, IVault) notCustodied duringFunding returns (uint256) {
        require(shares <= maxMint(receiver), "!maxMint");
        return ERC4626.mint(shares, receiver);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if not during funding window
    function previewMint(uint256 shares) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndDuringFunding()) ? ERC4626.previewMint(shares) : 0;
    }

    /// @dev    See EIP-4626
    function withdraw(
        uint256 assets,
        address receiver,
        address _owner
    ) public override(ERC4626, IVault) notCustodied notDuringEpoch returns (uint256) {
        return ERC4626.withdraw(assets, receiver, _owner);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if funds are custodied or during epoch
    function previewWithdraw(uint256 assets) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndNotDuringEpoch()) ? ERC4626.previewWithdraw(assets) : 0;
    }

    /// @dev    See EIP-4626
    function redeem(
        uint256 shares,
        address receiver,
        address _owner
    ) public override(ERC4626, IVault) notCustodied notDuringEpoch returns (uint256) {
        return ERC4626.redeem(shares, receiver, _owner);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if funds are custodied or during epoch
    function previewRedeem(uint256 shares) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndNotDuringEpoch()) ? ERC4626.previewRedeem(shares) : 0;
    }

    /// @dev    See EIP-4626
    function totalAssets() public view override(ERC4626, IVault) returns (uint256) {
        return custodied ? custodiedAmount : IERC20(asset()).balanceOf(address(this));
    }

    /// @dev    See EIP-4626
    // (uint256 assets, uint256 shares)
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        ERC4626._deposit(caller, receiver, assets, shares);
        totalDeposits += assets;
    }

    /// @dev    See EIP-4626
    // (uint256 assets, uint256 shares)
    function _withdraw(address caller, address receiver, address _owner, uint256 assets, uint256 shares) internal override {
        if (totalDeposits > assets) {
            totalDeposits -= assets;
        } else {
            totalDeposits = 0;
        }
        ERC4626._withdraw(caller, receiver, _owner, assets, shares);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../trader/modules/camelot/v3LP/ICamelot_V3LP_Module.sol";
import "../trader/modules/odos/swap/IOdos_V3Swap_Module.sol";

import "../trader/trader/ITraderV0.sol";

import "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import "@solidstate/contracts/introspection/ERC165/base/IERC165Base.sol";
import "@solidstate/contracts/access/access_control/IAccessControl.sol";

import "hardhat/console.sol";

contract SelectorHelper {
    // solhint-disable no-console

    function camelotV3Selectors() external view {
        console.log("\n");
        console.log("odos_v3_swap ");
        console.logBytes4(IOdos_V3Swap_Module.odos_v3_swap.selector);
        console.log("camelot_v3_mint ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_mint.selector);
        console.log("camelot_v3_increaseLiquidity ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_increaseLiquidity.selector);
        console.log("camelot_v3_decreaseLiquidity ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_decreaseLiquidity.selector);
        console.log("camelot_v3_collect ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_collect.selector);
        console.log("camelot_v3_burn ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_burn.selector);
        console.log("camelot_v3_decreaseLiquidityAndCollect ");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityAndCollect.selector);
        console.log("camelot_v3_decreaseLiquidityCollectAndBurn");
        console.logBytes4(ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityCollectAndBurn.selector);
    }

    function traderInterfaces() external view {
        console.log("\n");
        console.log("ITraderV0.interfaceId");
        console.logBytes4(type(ITraderV0).interfaceId);
        console.log("IDiamondReadable.interfaceId");
        console.logBytes4(type(IDiamondReadable).interfaceId);
        console.log("IERC165Base.interfaceId");
        console.logBytes4(type(IERC165Base).interfaceId);
        console.log("IAccessControl.interfaceId");
        console.logBytes4(type(IAccessControl).interfaceId);
    }

    function forbiddenSelectors() external view {
        console.log("\n");
        console.log("initializeTraderV0 ");
        console.logBytes4(ITraderV0.initializeTraderV0.selector);
    }

    // solhint-enable no-console
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

contract TestFixture_AaveMathHelper {
    using WadRayMath for uint256;

    function getBalanceFromTimestamps(uint256 rate, uint256 bal, uint40 start, uint256 end) external pure returns (uint256) {
        uint256 interest = MathUtils.calculateCompoundedInterest(rate, start, end);

        return bal.rayMul(interest);
    }
}

/**
 * @title MathUtils library
 * @author Aave
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/
    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
        unchecked {
            result = result / SECONDS_PER_YEAR;
        }

        return WadRayMath.RAY + result;
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
     * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
     * error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return WadRayMath.RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
     **/
    function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
        return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
    }
}

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract TestFixture_ERC20 is ERC20PresetMinterPauser {
    uint8 public tokenDecimals = 18;

    constructor(string memory _name, string memory _symbol) ERC20PresetMinterPauser(_name, _symbol) {}

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function mintTo(address _to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(_to, amount);
    }

    function setTokenDecimals(uint8 _newDecimals) external {
        tokenDecimals = _newDecimals;
    }

    function grantMinterRole() external {
        grantRole(MINTER_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract TestFixture_ERC721 is ERC721PresetMinterPauserAutoId {
    using Counters for Counters.Counter;

    string baseURI = "https://ipfs.io/ipfs/QmfBsmEtHT9CbBnDUfEw5UEdPueHG7iKizhK5SyUyVpgru/";
    Counters.Counter public _tokenIdTracker;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseUri) {
        baseURI = _baseUri;
        _tokenIdTracker.increment();
    }

    function mint() public {
        _mint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function mintTo(address _to) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        _mint(_to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function mintSpecific(address _to, uint256 _tokenId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
        _mint(_to, _tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    function setBaseUri(string calldata _newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestFixture_MaliciousExecutor {
    IERC20 immutable usdc;

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
    }

    function executePath(bytes calldata data, uint256[] memory inputAmount) external payable {
        usdc.transfer(msg.sender, 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract TestFixture_MathHelper {
    using SafeMath for uint256;

    function estimateLiquidity(
        uint256 amountA,
        uint256 amountB,
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 kLast,
        uint256 feeDenomiator,
        uint256 ownerFeeShare
    ) external pure returns (uint256) {
        totalSupply += feeAmount(reservesA, reservesB, totalSupply, kLast, feeDenomiator, ownerFeeShare);

        // Calculate mint amount
        uint256 optimalB = amountA.mul(reservesB) / (reservesA);
        uint256 optimalA = amountB.mul(reservesA) / (reservesB);

        if (optimalB <= amountB) {
            return Math.min(amountA.mul(totalSupply) / (reservesA), optimalB.mul(totalSupply) / (reservesB));
        } else {
            return Math.min(optimalA.mul(totalSupply) / (reservesA), amountB.mul(totalSupply) / (reservesB));
        }
    }

    function _k(uint256 balance0, uint256 balance1) internal pure returns (uint256) {
        return balance0.mul(balance1);
    }

    function feeAmount(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 kLast,
        uint256 feeDenominator,
        uint256 ownerFeeShare
    ) internal pure returns (uint256) {
        uint256 rootK = Math.sqrt(_k(uint256(reservesA), uint256(reservesB)));
        uint256 rootKLast = Math.sqrt(kLast);
        uint256 d = (feeDenominator.mul(100) / ownerFeeShare).sub(100);
        uint256 numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
        uint256 denominator = rootK.mul(d).add(rootKLast.mul(100));
        return numerator / denominator;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface TestTokenSale {
    function purchase() external payable returns (uint256);
}

contract TestFixture_MinterBot {
    function purchase(address _target) external payable returns (uint256) {
        return TestTokenSale(_target).purchase{ value: msg.value }();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface TestTokenSalePhase4 {
    function purchaseWhitelist(bytes32[] calldata _proof) external payable returns (uint256);

    function purchasePublic() external payable returns (uint256);
}

contract TestFixture_MinterBotPhase4 {
    function purchaseWhitelist(bytes32[] calldata _proof, address _target) external payable returns (uint256) {
        return TestTokenSalePhase4(_target).purchaseWhitelist{ value: msg.value }(_proof);
    }

    function purchasePublic(address _target) external payable returns (uint256) {
        return TestTokenSalePhase4(_target).purchasePublic{ value: msg.value }();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../trader/diamonds/StrategyDiamond.sol";
import "../trader/trader/ITraderV0.sol";
import "../trader/trader/TraderV0_Cutter.sol";
import "../trader/modules/aave/Aave_Lending_Cutter.sol";

/**
 * Vaultus Finance https://www.vaultusfinance.io/
 * @title   TestFixture_Strategy_AaveModule
 * @notice  Tests Aave module
 * @dev     Employs a non-upgradeable version of the EIP-2535 Diamonds pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TestFixture_Strategy_AaveModule is StrategyDiamond, TraderV0_Cutter, Aave_Lending_Cutter {
    constructor(
        address _admin,
        address _operator,
        address _traderFacet,
        TraderV0InitializerParams memory _traderV0Params,
        address _aaveFacet
    ) StrategyDiamond(_admin, _operator) {
        cut_TraderV0(_traderFacet, _traderV0Params);
        cut(_aaveFacet);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../trader/diamonds/StrategyDiamond.sol";
import "../trader/trader/ITraderV0.sol";
import "../trader/trader/TraderV0_Cutter.sol";
import "../trader/modules/gmx/glp/GMX_GLP_Cutter.sol";

/**
 * Vaultus Finance https://www.vaultusfinance.io/
 * @title   TestFixture_Strategy_GLPModule
 * @notice  Tests GMX GLP module
 * @dev     Employs a non-upgradeable version of the EIP-2535 Diamonds pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TestFixture_Strategy_GLPModule is StrategyDiamond, TraderV0_Cutter, GMX_GLP_Cutter {
    constructor(
        address _admin,
        address _operator,
        address _traderFacet,
        TraderV0InitializerParams memory _traderV0Params,
        address _glpFacet
    ) StrategyDiamond(_admin, _operator) {
        cut_TraderV0(_traderFacet, _traderV0Params);
        cut(_glpFacet);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../trader/diamonds/StrategyDiamond.sol";
import "../trader/trader/ITraderV0.sol";
import "../trader/trader/TraderV0_Cutter.sol";
import "../trader/modules/vaultus/rescue/Vaultus_Rescue_Cutter.sol";

/**
 * Vaultus Finance https://www.vaultusfinance.io/
 * @title   TestFixture_Strategy_VaultusRescue
 * @notice  Tests GMX GLP module
 * @dev     Employs a non-upgradeable version of the EIP-2535 Diamonds pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TestFixture_Strategy_VaultusRescue is StrategyDiamond, TraderV0_Cutter, Vaultus_Rescue_Cutter {
    constructor(
        address _admin,
        address _operator,
        address _traderFacet,
        TraderV0InitializerParams memory _traderV0Params,
        address _facet
    ) StrategyDiamond(_admin, _operator) {
        cut_TraderV0(_traderFacet, _traderV0Params);
        cut(_facet);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../trader/diamonds/StrategyDiamond.sol";
import "../trader/trader/ITraderV0.sol";
import "../trader/trader/TraderV0_Cutter.sol";

/**
 * Vaultus Finance https://www.vaultusfinance.io/
 * @title   TestFixture_TrivialStrategy
 * @notice  Tests TraderV0
 * @dev     Employs a non-upgradeable version of the EIP-2535 Diamonds pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TestFixture_TrivialStrategy is StrategyDiamond, TraderV0_Cutter {
    constructor(
        address _admin,
        address _operator,
        address _traderFacet,
        TraderV0InitializerParams memory _traderV0Params
    ) StrategyDiamond(_admin, _operator) {
        cut_TraderV0(_traderFacet, _traderV0Params);
        _grantRole(keccak256("VAULT_SETTER_ROLE"), _admin);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import "@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol";
import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "@solidstate/contracts/access/access_control/AccessControl.sol";

import "../modules/vaultus/Vaultus_Common_Roles.sol";

/**
 * @title   Vaultus Strategy Diamond
 * @notice  Provides core EIP-2535 Diamond and Access Control capabilities
 * @dev     This implementation excludes diamond Cut functions, making its facets immutable once deployed
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract StrategyDiamond is
    DiamondBase,
    DiamondReadable,
    DiamondWritableInternal,
    AccessControl,
    ERC165Base,
    Vaultus_Common_Roles
{
    constructor(address _admin, address _operator) {
        require(_admin != address(0) && _operator != address(0), "StrategyDiamond: Zero address");

        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IAccessControl).interfaceId, true);

        // set roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _operator);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 **/
interface IAaveIncentivesController {
    /**
     * @dev Emitted during `handleAction`, `claimRewards` and `claimRewardsOnBehalf`
     * @param user The user that accrued rewards
     * @param amount The amount of accrued rewards
     */
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted during `claimRewards` and `claimRewardsOnBehalf`
     * @param user The address that accrued rewards
     * @param to The address that will be receiving the rewards
     * @param claimer The address that performed the claim
     * @param amount The amount of rewards
     */
    event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

    /**
     * @dev Emitted during `setClaimer`
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @notice Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index
     * @return The emission per second
     * @return The last updated timestamp
     **/
    function getAssetData(address asset) external view returns (uint256, uint256, uint256);

    /**
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset) external view returns (uint128, uint128, uint256);

    /**
     * @notice Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @notice Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @notice Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

    /**
     * @notice Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the pool
     * @param totalSupply The total supply of the asset in the pool
     **/
    function handleAction(address asset, uint256 userBalance, uint256 totalSupply) external;

    /**
     * @notice Returns the total of rewards of a user, already accrued + not yet accrued
     * @param assets The assets to accumulate rewards for
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @notice Claims reward for a user, on the assets of the pool, accumulating the pending rewards
     * @param assets The assets to accumulate rewards for
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.
     * @dev The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The assets to accumulate rewards for
     * @param amount The amount of rewards to claim
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @return The amount of rewards claimed
     **/
    function claimRewardsOnBehalf(address[] calldata assets, uint256 amount, address user, address to) external returns (uint256);

    /**
     * @notice Returns the unclaimed rewards of the user
     * @param user The address of the user
     * @return The unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @notice Returns the user index for a specific asset
     * @param user The address of the user
     * @param asset The asset to incentivize
     * @return The user index for the asset
     */
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The address of the reward token
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The precision used in the incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import { IAaveIncentivesController } from "./IAaveIncentivesController.sol";
import { IPool } from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 * @author Aave
 * @notice Interface for the initialize function common between debt tokens
 **/
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this aToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        IAaveIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { IPoolAddressesProvider } from "./IPoolAddressesProvider.sol";
import { DataTypes } from "./DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     **/
    event MintUnbacked(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode);

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     **/
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode);

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    event SwapBorrowRateMode(address indexed reserve, address indexed user, DataTypes.InterestRateMode interestRateMode);

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     **/
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     **/
    function backUnbacked(address asset, uint256 amount, uint256 fee) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveAToken) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
     * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to aToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Configures a new category for the eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    /**
     * @notice Returns the data of an eMode category
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple Aave markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import { IInitializableDebtToken } from "./IInitializableDebtToken.sol";

/**
 * @title IStableDebtToken
 * @author Aave
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 **/
interface IStableDebtToken is IInitializableDebtToken {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted (user entered amount + balance increase from interest)
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param avgStableRate The next average stable rate after the minting
     * @param newTotalSupply The next total supply of the stable debt token after the action
     **/
    event Mint(
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is burned
     * @param from The address from which the debt will be burned
     * @param amount The amount being burned (user entered amount - balance increase from interest)
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The the increase in balance since the last action of the user
     * @param avgStableRate The next average stable rate after the burning
     * @param newTotalSupply The next total supply of the stable debt token after the action
     **/
    event Burn(
        address indexed from,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @notice Mints debt token to the `onBehalfOf` address.
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     * @return True if it is the first borrow, false otherwise
     * @return The total stable debt
     * @return The average stable borrow rate
     **/
    function mint(address user, address onBehalfOf, uint256 amount, uint256 rate) external returns (bool, uint256, uint256);

    /**
     * @notice Burns debt of `user`
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest the user earned
     * @param from The address from which the debt will be burned
     * @param amount The amount of debt tokens getting burned
     * @return The total stable debt
     * @return The average stable borrow rate
     **/
    function burn(address from, uint256 amount) external returns (uint256, uint256);

    /**
     * @notice Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     **/
    function getAverageStableRate() external view returns (uint256);

    /**
     * @notice Returns the stable rate of the user debt
     * @param user The address of the user
     * @return The stable rate of the user
     **/
    function getUserStableRate(address user) external view returns (uint256);

    /**
     * @notice Returns the timestamp of the last update of the user
     * @param user The address of the user
     * @return The timestamp
     **/
    function getUserLastUpdated(address user) external view returns (uint40);

    /**
     * @notice Returns the principal, the total supply, the average stable rate and the timestamp for the last update
     * @return The principal
     * @return The total supply
     * @return The average stable rate
     * @return The timestamp of the last update
     **/
    function getSupplyData() external view returns (uint256, uint256, uint256, uint40);

    /**
     * @notice Returns the timestamp of the last update of the total supply
     * @return The timestamp
     **/
    function getTotalSupplyLastUpdated() external view returns (uint40);

    /**
     * @notice Returns the total supply and the average stable rate
     * @return The total supply
     * @return The average rate
     **/
    function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

    /**
     * @notice Returns the principal debt balance of the user
     * @return The debt balance of the user since the last burn/mint action
     **/
    function principalBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this stableDebtToken (E.g. WETH for stableDebtWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IAlgebraSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter is IAlgebraSwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface IAlgebraPool {
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );
}

// solhint-disable-next-line compiler-version
pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo() external view returns (uint256 _ownerFeeShare, address _feeTo);
}

// solhint-disable-next-line compiler-version
pragma solidity >=0.5.0;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);

    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);

    function kLast() external view returns (uint256);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data, address referrer) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface ICamelotRouter is IUniswapV2Router01 {
    function getPair(address token1, address token2) external view returns (address);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INFTHandler is IERC721Receiver {
    function onNFTHarvest(address operator, address to, uint256 tokenId, uint256 grailAmount, uint256 xGrailAmount) external returns (bool);

    function onNFTAddToPosition(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);

    function onNFTWithdraw(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTPool is IERC721 {
    function factory() external view returns (address);

    function lastTokenId() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function hasDeposits() external view returns (bool);

    function getPoolInfo()
        external
        view
        returns (
            address lpToken,
            address grailToken,
            address sbtToken,
            uint256 lastRewardTime,
            uint256 accRewardsPerShare,
            uint256 lpSupply,
            uint256 lpSupplyWithMultiplier,
            uint256 allocPoint
        );

    function getStakingPosition(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 amount,
            uint256 amountWithMultiplier,
            uint256 startLockTime,
            uint256 lockDuration,
            uint256 lockMultiplier,
            uint256 rewardDebt,
            uint256 boostPoints,
            uint256 totalMultiplier
        );

    function boost(uint256 userAddress, uint256 amount) external;

    function unboost(uint256 userAddress, uint256 amount) external;

    function createPosition(uint256 amount, uint256 lockDuration) external;

    function addToPosition(uint256 tokenId, uint256 amountToAdd) external;

    function harvestPosition(uint256 tokenId) external;

    function withdrawFromPosition(uint256 tokenId, uint256 amountToWithdraw) external;

    function renewLockPosition(uint256 tokenId) external;

    function lockPosition(uint256 tokenId, uint256 lockDuration) external;

    function splitPosition(uint256 tokenId, uint256 splitAmount) external;

    function mergePositions(uint256[] calldata tokenIds, uint256 lockDuration) external;

    function emergencyWithdraw(uint256 tokenId) external;
}

pragma solidity ^0.8.13;

interface INFTPoolFactory {
    function getPool(address _lpToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INitroPool {
    event Deposit(address indexed userAddress, uint256 tokenId, uint256 amount);
    event Harvest(address indexed userAddress, IERC20 rewardsToken, uint256 pending);
    event Withdraw(address indexed userAddress, uint256 tokenId, uint256 amount);
    event EmergencyWithdraw(address indexed userAddress, uint256 tokenId, uint256 amount);

    function withdraw(uint256 tokenId) external;

    function emergencyWithdraw(uint256 tokenId) external;

    function harvest() external;

    function factory() external view returns (address);

    function userTokenId(address account, uint256 index) external view returns (uint256);

    function tokenIdOwner(uint256 index) external view returns (uint256);

    function userTokenIdsLength(address account) external view returns (uint256);
}

pragma solidity ^0.8.13;

interface INitroPoolFactory {
    function getNftPoolPublishedNitroPool(address nftPoolAddress, uint256 index) external view returns (address);

    function getNitroPool(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface INonfungiblePositionManager {
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint88 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function multicall(bytes[] calldata data) external;

    function refundNativeToken() external;

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable;

    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function sweepToken(address token, uint256 amountMinimum, address recipient) external;

    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external;
}

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/**
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *     The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 * @dev Version bumped to solidity 0.8.13 by BowTiedPickle
 */
pragma solidity ^0.8.13;

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IOrderBook {
    function getSwapOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct SwapOrder {
        address account;
        address[] path;
        uint256 amountIn;
        uint256 minOut;
        uint256 triggerRatio;
        bool triggerAboveThreshold;
        bool shouldUnwrap;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(address) external view returns (uint256);

    function decreaseOrdersIndex(address) external view returns (uint256);

    function increaseOrders(address, uint256 _orderIndex) external view returns (IncreaseOrder memory);

    function decreaseOrders(address, uint256 _orderIndex) external view returns (DecreaseOrder memory);

    function swapOrders(address, uint256 _orderIndex) external view returns (SwapOrder memory);

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event CancelSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event UpdateSwapOrder(
        address indexed account,
        uint256 ordexIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event ExecuteSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 amountOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRewardRouterV2 {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;

    function compound() external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function unstakeGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRouter {
    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;

    function directPoolDeposit(address _token, uint256 _amount) external;

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external payable;

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface IOdosRouter {
    /// @dev Contains all information needed to describe an input token being swapped from
    struct inputToken {
        address tokenAddress;
        uint256 amountIn;
        address receiver;
        bytes permit;
    }
    /// @dev Contains all information needed to describe an output token being swapped to
    struct outputToken {
        address tokenAddress;
        uint256 relativeValue;
        address receiver;
    }

    function swap(
        inputToken[] memory inputs,
        outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) external payable returns (uint256[] memory amountsOut, uint256 gasLeft);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../pendle_libraries/MarketApproxLib.sol";
import "./IPAllActionTypeV3.sol";

interface IPActionAddRemoveLiqV3 {
    event AddLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyUsed,
        uint256 netPtUsed,
        uint256 netLpOut
    );

    event AddLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenIn,
        address receiver,
        uint256 netTokenUsed,
        uint256 netPtUsed,
        uint256 netLpOut,
        uint256 netSyInterm
    );

    event AddLiquiditySinglePt(address indexed caller, address indexed market, address indexed receiver, uint256 netPtIn, uint256 netLpOut);

    event AddLiquiditySingleSy(address indexed caller, address indexed market, address indexed receiver, uint256 netSyIn, uint256 netLpOut);

    event AddLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netSyInterm
    );

    event AddLiquiditySingleSyKeepYt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netSyIn,
        uint256 netSyMintPy,
        uint256 netLpOut,
        uint256 netYtOut
    );

    event AddLiquiditySingleTokenKeepYt(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netTokenIn,
        uint256 netLpOut,
        uint256 netYtOut,
        uint256 netSyMintPy,
        uint256 netSyInterm
    );

    event RemoveLiquidityDualSyAndPt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netSyOut
    );

    event RemoveLiquidityDualTokenAndPt(
        address indexed caller,
        address indexed market,
        address indexed tokenOut,
        address receiver,
        uint256 netLpToRemove,
        uint256 netPtOut,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    event RemoveLiquiditySinglePt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netPtOut
    );

    event RemoveLiquiditySingleSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        uint256 netLpToRemove,
        uint256 netSyOut
    );

    event RemoveLiquiditySingleToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        uint256 netLpToRemove,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    function addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external payable returns (uint256 netLpOut, uint256 netPtUsed, uint256 netSyInterm);

    function addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);

    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netLpOut, uint256 netSyFee, uint256 netSyInterm);

    function addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netLpOut, uint256 netSyFee);

    function addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy, uint256 netSyInterm);

    function addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) external returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMintPy);

    function removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        uint256 minPtOut
    ) external returns (uint256 netTokenOut, uint256 netPtOut, uint256 netSyInterm);

    function removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) external returns (uint256 netSyOut, uint256 netPtOut);

    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netPtOut, uint256 netSyFee);

    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netSyOut, uint256 netSyFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPMarketSwapCallback.sol";
import "./IPLimitRouter.sol";

interface IPActionCallbackV3 is IPMarketSwapCallback, IPLimitRouterCallback {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../pendle_libraries/MarketApproxLib.sol";
import "./IPAllActionTypeV3.sol";

struct Call3Misc {
    bool allowFailure;
    bytes callData;
}

interface IPActionMiscV3 {
    struct Result {
        bool success;
        bytes returnData;
    }

    event MintSyFromToken(
        address indexed caller,
        address indexed tokenIn,
        address indexed SY,
        address receiver,
        uint256 netTokenIn,
        uint256 netSyOut
    );

    event RedeemSyToToken(
        address indexed caller,
        address indexed tokenOut,
        address indexed SY,
        address receiver,
        uint256 netSyIn,
        uint256 netTokenOut
    );

    event MintPyFromSy(address indexed caller, address indexed receiver, address indexed YT, uint256 netSyIn, uint256 netPyOut);

    event RedeemPyToSy(address indexed caller, address indexed receiver, address indexed YT, uint256 netPyIn, uint256 netSyOut);

    event MintPyFromToken(
        address indexed caller,
        address indexed tokenIn,
        address indexed YT,
        address receiver,
        uint256 netTokenIn,
        uint256 netPyOut,
        uint256 netSyInterm
    );

    event RedeemPyToToken(
        address indexed caller,
        address indexed tokenOut,
        address indexed YT,
        address receiver,
        uint256 netPyIn,
        uint256 netTokenOut,
        uint256 netSyInterm
    );

    function mintSyFromToken(
        address receiver,
        address SY,
        uint256 minSyOut,
        TokenInput calldata input
    ) external payable returns (uint256 netSyOut);

    function redeemSyToToken(
        address receiver,
        address SY,
        uint256 netSyIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut);

    function mintPyFromToken(
        address receiver,
        address YT,
        uint256 minPyOut,
        TokenInput calldata input
    ) external payable returns (uint256 netPyOut, uint256 netSyInterm);

    function redeemPyToToken(
        address receiver,
        address YT,
        uint256 netPyIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyInterm);

    function mintPyFromSy(address receiver, address YT, uint256 netSyIn, uint256 minPyOut) external returns (uint256 netPyOut);

    function redeemPyToSy(address receiver, address YT, uint256 netPyIn, uint256 minSyOut) external returns (uint256 netSyOut);

    function redeemDueInterestAndRewards(address user, address[] calldata sys, address[] calldata yts, address[] calldata markets) external;

    function swapTokenToToken(
        address receiver,
        uint256 minTokenOut,
        TokenInput calldata inp
    ) external payable returns (uint256 netTokenOut);

    function swapTokenToTokenViaSy(
        address receiver,
        address SY,
        TokenInput calldata input,
        address tokenRedeemSy,
        uint256 minTokenOut
    ) external payable returns (uint256 netTokenOut, uint256 netSyInterm);

    function boostMarkets(address[] memory markets) external;

    function multicall(Call3Misc[] calldata calls) external payable returns (Result[] memory res);

    function simulate(address target, bytes calldata data) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../pendle_libraries/MarketApproxLib.sol";
import "./IPAllActionTypeV3.sol";

interface IPActionSwapPTV3 {
    event SwapPtAndSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        int256 netPtToAccount,
        int256 netSyToAccount
    );

    event SwapPtAndToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        int256 netPtToAccount,
        int256 netTokenToAccount,
        uint256 netSyInterm
    );

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactSyForPt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netPtOut, uint256 netSyFee);

    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactPtForSy(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netSyOut, uint256 netSyFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../pendle_libraries/MarketApproxLib.sol";
import "./IPAllActionTypeV3.sol";

interface IPActionSwapYTV3 {
    event SwapYtAndSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        int256 netYtToAccount,
        int256 netSyToAccount
    );

    event SwapYtAndToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        int256 netYtToAccount,
        int256 netTokenToAccount,
        uint256 netSyInterm
    );

    event SwapPtAndYt(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        int256 netPtToAccount,
        int256 netYtToAccount
    );

    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netYtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netYtOut, uint256 netSyFee);

    function swapExactYtForToken(
        address receiver,
        address market,
        uint256 exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapExactPtForYt(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minYtOut,
        ApproxParams calldata guessTotalPtToSwap
    ) external returns (uint256 netYtOut, uint256 netSyFee);

    function swapExactYtForPt(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minPtOut,
        ApproxParams calldata guessTotalPtFromSwap
    ) external returns (uint256 netPtOut, uint256 netSyFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IPSwapAggregator.sol";
import "./IPLimitRouter.sol";

struct TokenInput {
    // Token/Sy data
    address tokenIn;
    uint256 netTokenIn;
    address tokenMintSy;
    // aggregator data
    address pendleSwap;
    SwapData swapData;
}

struct TokenOutput {
    // Token/Sy data
    address tokenOut;
    uint256 minTokenOut;
    address tokenRedeemSy;
    // aggregator data
    address pendleSwap;
    SwapData swapData;
}

struct LimitOrderData {
    address limitRouter;
    uint256 epsSkipMarket; // only used for swap operations, will be ignored otherwise
    FillOrderParams[] normalFills;
    FillOrderParams[] flashFills;
    bytes optData;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPActionAddRemoveLiqV3.sol";
import "./IPActionSwapPTV3.sol";
import "./IPActionSwapYTV3.sol";
import "./IPActionMiscV3.sol";
import "./IPActionCallbackV3.sol";
import "./IDiamondLoupe.sol";

interface IPAllActionV3 is IPActionAddRemoveLiqV3, IPActionSwapPTV3, IPActionSwapYTV3, IPActionMiscV3, IPActionCallbackV3, IDiamondLoupe {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPGauge {
    function totalActiveSupply() external view returns (uint256);

    function activeBalance(address user) external view returns (uint256);

    // only available for newer factories. please check the verified contracts
    event RedeemRewards(address indexed user, uint256[] rewardsOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPInterestManagerYT {
    event CollectInterestFee(uint256 amountInterestFee);

    function userInterest(address user) external view returns (uint128 lastPYIndex, uint128 accruedInterest);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPInterestManagerYTV2 {
    function userInterest(address user) external view returns (uint128 lastInterestIndex, uint128 accruedInterest, uint256 lastPYIndex);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./PYIndex.sol";

interface IPLimitOrderType {
    enum OrderType {
        SY_FOR_PT,
        PT_FOR_SY,
        SY_FOR_YT,
        YT_FOR_SY
    }

    // Fixed-size order part with core information
    struct StaticOrder {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
    }

    struct FillResults {
        uint256 totalMaking;
        uint256 totalTaking;
        uint256 totalFee;
        uint256 totalNotionalVolume;
        uint256[] netMakings;
        uint256[] netTakings;
        uint256[] netFees;
        uint256[] notionalVolumes;
    }
}

struct Order {
    uint256 salt;
    uint256 expiry;
    uint256 nonce;
    IPLimitOrderType.OrderType orderType;
    address token;
    address YT;
    address maker;
    address receiver;
    uint256 makingAmount;
    uint256 lnImpliedRate;
    uint256 failSafeRate;
    bytes permit;
}

struct FillOrderParams {
    Order order;
    bytes signature;
    uint256 makingAmount;
}

interface IPLimitRouterCallback is IPLimitOrderType {
    function limitRouterCallback(
        uint256 actualMaking,
        uint256 actualTaking,
        uint256 totalFee,
        bytes memory data
    ) external returns (bytes memory);
}

interface IPLimitRouter is IPLimitOrderType {
    struct OrderStatus {
        uint128 filledAmount;
        uint128 remaining;
    }

    event OrderCanceled(address indexed maker, bytes32 indexed orderHash);

    event OrderFilledV2(
        bytes32 indexed orderHash,
        OrderType indexed orderType,
        address indexed YT,
        address token,
        uint256 netInputFromMaker,
        uint256 netOutputToMaker,
        uint256 feeAmount,
        uint256 notionalVolume,
        address maker,
        address taker
    );

    // @dev actualMaking, actualTaking are in the SY form
    function fill(
        FillOrderParams[] memory params,
        address receiver,
        uint256 maxTaking,
        bytes calldata optData,
        bytes calldata callback
    ) external returns (uint256 actualMaking, uint256 actualTaking, uint256 totalFee, bytes memory callbackReturn);

    function feeRecipient() external view returns (address);

    function hashOrder(Order memory order) external view returns (bytes32);

    function cancelSingle(Order calldata order) external;

    function cancelBatch(Order[] calldata orders) external;

    function orderStatusesRaw(
        bytes32[] memory orderHashes
    ) external view returns (uint256[] memory remainingsRaw, uint256[] memory filledAmounts);

    function orderStatuses(
        bytes32[] memory orderHashes
    ) external view returns (uint256[] memory remainings, uint256[] memory filledAmounts);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function simulate(address target, bytes calldata data) external payable;

    /* --- Deprecated events --- */

    // deprecate on 7/1/2024, prior to official launch
    event OrderFilled(
        bytes32 indexed orderHash,
        OrderType indexed orderType,
        address indexed YT,
        address token,
        uint256 netInputFromMaker,
        uint256 netOutputToMaker,
        uint256 feeAmount,
        uint256 notionalVolume
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPPrincipalToken.sol";
import "./IPYieldToken.sol";
import "./IStandardizedYield.sol";
import "./IPGauge.sol";
import "./MarketMathCore.sol";

interface IPMarket is IERC20Metadata, IPGauge {
    event Mint(address indexed receiver, uint256 netLpMinted, uint256 netSyUsed, uint256 netPtUsed);

    event Burn(address indexed receiverSy, address indexed receiverPt, uint256 netLpBurned, uint256 netSyOut, uint256 netPtOut);

    event Swap(
        address indexed caller,
        address indexed receiver,
        int256 netPtOut,
        int256 netSyOut,
        uint256 netSyFee,
        uint256 netSyToReserve
    );

    event UpdateImpliedRate(uint256 indexed timestamp, uint256 lnLastImpliedRate);

    event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew);

    function mint(
        address receiver,
        uint256 netSyDesired,
        uint256 netPtDesired
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function burn(address receiverSy, address receiverPt, uint256 netLpToBurn) external returns (uint256 netSyOut, uint256 netPtOut);

    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactPt(
        address receiver,
        uint256 exactPtOut,
        bytes calldata data
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function redeemRewards(address user) external returns (uint256[] memory);

    function readState(address router) external view returns (MarketState memory market);

    function observe(uint32[] memory secondsAgos) external view returns (uint216[] memory lnImpliedRateCumulative);

    function increaseObservationsCardinalityNext(uint16 cardinalityNext) external;

    function readTokens() external view returns (IStandardizedYield _SY, IPPrincipalToken _PT, IPYieldToken _YT);

    function getRewardTokens() external view returns (address[] memory);

    function isExpired() external view returns (bool);

    function expiry() external view returns (uint256);

    function observations(uint256 index) external view returns (uint32 blockTimestamp, uint216 lnImpliedRateCumulative, bool initialized);

    function _storage()
        external
        view
        returns (
            int128 totalPt,
            int128 totalSy,
            uint96 lastLnImpliedRate,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPMarketSwapCallback {
    function swapCallback(int256 ptToAccount, int256 syToAccount, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IPMarket.sol";

interface IPMarketV3 is IPMarket {
    function getNonOverrideLnFeeRateRoot() external view returns (uint80);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPPrincipalToken is IERC20Metadata {
    function burnByYT(address user, uint256 amount) external;

    function mintByYT(address user, uint256 amount) external;

    function initialize(address _YT) external;

    function SY() external view returns (address);

    function YT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

struct SwapData {
    SwapType swapType;
    address extRouter;
    bytes extCalldata;
    bool needScale;
}

enum SwapType {
    NONE,
    KYBERSWAP,
    ONE_INCH,
    // ETH_WETH not used in Aggregator
    ETH_WETH
}

interface IPSwapAggregator {
    function swap(address tokenIn, uint256 amountIn, SwapData calldata swapData) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewardManager.sol";
import "./IPInterestManagerYT.sol";

interface IPYieldToken is IERC20Metadata, IRewardManager, IPInterestManagerYT {
    event NewInterestIndex(uint256 indexed newIndex);

    event Mint(address indexed caller, address indexed receiverPT, address indexed receiverYT, uint256 amountSyToMint, uint256 amountPYOut);

    event Burn(address indexed caller, address indexed receiver, uint256 amountPYToRedeem, uint256 amountSyOut);

    event RedeemRewards(address indexed user, uint256[] amountRewardsOut);

    event RedeemInterest(address indexed user, uint256 interestOut);

    event CollectRewardFee(address indexed rewardToken, uint256 amountRewardFee);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256 amountPYOut);

    function redeemPY(address receiver) external returns (uint256 amountSyOut);

    function redeemPYMulti(
        address[] calldata receivers,
        uint256[] calldata amountPYToRedeems
    ) external returns (uint256[] memory amountSyOuts);

    function redeemDueInterestAndRewards(
        address user,
        bool redeemInterest,
        bool redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function pyIndexCurrent() external returns (uint256);

    function pyIndexStored() external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function SY() external view returns (address);

    function PT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function doCacheIndexSameBlock() external view returns (bool);

    function pyIndexLastUpdatedBlock() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewardManager.sol";
import "./IPInterestManagerYTV2.sol";

interface IPYieldTokenV2 is IERC20Metadata, IRewardManager, IPInterestManagerYTV2 {
    event Mint(address indexed caller, address indexed receiverPT, address indexed receiverYT, uint256 amountSyToMint, uint256 amountPYOut);

    event Burn(address indexed caller, address indexed receiver, uint256 amountPYToRedeem, uint256 amountSyOut);

    event RedeemRewards(address indexed user, uint256[] amountRewardsOut);

    event RedeemInterest(address indexed user, uint256 interestOut);

    event WithdrawFeeToTreasury(uint256[] amountRewardsOut, uint256 syOut);

    event CollectInterestFee(uint256 amountInterestFee);

    event CollectRewardFee(address indexed rewardToken, uint256 amountRewardFee);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256 amountPYOut);

    function redeemPY(address receiver) external returns (uint256 amountSyOut);

    function redeemPYMulti(
        address[] calldata receivers,
        uint256[] calldata amountPYToRedeems
    ) external returns (uint256[] memory amountSyOuts);

    function redeemDueInterestAndRewards(
        address user,
        bool redeemInterest,
        bool redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function pyIndexCurrent() external returns (uint256);

    function pyIndexStored() external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function SY() external view returns (address);

    function PT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function doCacheIndexSameBlock() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IRewardManager {
    function userReward(address token, address user) external view returns (uint128 index, uint128 accrued);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStandardizedYield is IERC20Metadata {
    /// @dev Emitted when any base tokens is deposited to mint shares
    event Deposit(address indexed caller, address indexed receiver, address indexed tokenIn, uint256 amountDeposited, uint256 amountSyOut);

    /// @dev Emitted when any shares are redeemed for base tokens
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountSyToRedeem,
        uint256 amountTokenOut
    );

    /// @dev check `assetInfo()` for more information
    enum AssetType {
        TOKEN,
        LIQUIDITY
    }

    /// @dev Emitted when (`user`) claims their rewards
    event ClaimRewards(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    /**
     * @notice mints an amount of shares by depositing a base token.
     * @param receiver shares recipient address
     * @param tokenIn address of the base tokens to mint shares
     * @param amountTokenToDeposit amount of base tokens to be transferred from (`msg.sender`)
     * @param minSharesOut reverts if amount of shares minted is lower than this
     * @return amountSharesOut amount of shares minted
     * @dev Emits a {Deposit} event
     *
     * Requirements:
     * - (`tokenIn`) must be a valid base token.
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut);

    /**
     * @notice redeems an amount of base tokens by burning some shares
     * @param receiver recipient address
     * @param amountSharesToRedeem amount of shares to be burned
     * @param tokenOut address of the base token to be redeemed
     * @param minTokenOut reverts if amount of base token redeemed is lower than this
     * @param burnFromInternalBalance if true, burns from balance of `address(this)`, otherwise burns from `msg.sender`
     * @return amountTokenOut amount of base tokens redeemed
     * @dev Emits a {Redeem} event
     *
     * Requirements:
     * - (`tokenOut`) must be a valid base token.
     */
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);

    /**
     * @notice exchangeRate * syBalance / 1e18 must return the asset balance of the account
     * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of sy
     he can mint must be X * exchangeRate / 1e18
     * @dev SYUtils's assetToSy & syToAsset should be used instead of raw multiplication
     & division
     */
    function exchangeRate() external view returns (uint256 res);

    /**
     * @notice claims reward for (`user`)
     * @param user the user receiving their rewards
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     * @dev
     * Emits a `ClaimRewards` event
     * See {getRewardTokens} for list of reward tokens
     */
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

    /**
     * @notice get the amount of unclaimed rewards for (`user`)
     * @param user the user to check for
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     */
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts);

    function rewardIndexesCurrent() external returns (uint256[] memory indexes);

    function rewardIndexesStored() external view returns (uint256[] memory indexes);

    /**
     * @notice returns the list of reward token addresses
     */
    function getRewardTokens() external view returns (address[] memory);

    /**
     * @notice returns the address of the underlying yield token
     */
    function yieldToken() external view returns (address);

    /**
     * @notice returns all tokens that can mint this SY
     */
    function getTokensIn() external view returns (address[] memory res);

    /**
     * @notice returns all tokens that can be redeemed by this SY
     */
    function getTokensOut() external view returns (address[] memory res);

    function isValidTokenIn(address token) external view returns (bool);

    function isValidTokenOut(address token) external view returns (bool);

    function previewDeposit(address tokenIn, uint256 amountTokenToDeposit) external view returns (uint256 amountSharesOut);

    function previewRedeem(address tokenOut, uint256 amountSharesToRedeem) external view returns (uint256 amountTokenOut);

    /**
     * @notice This function contains information to interpret what the asset is
     * @return assetType the type of the asset (0 for ERC20 tokens, 1 for AMM liquidity tokens,
        2 for bridged yield bearing tokens like wstETH, rETH on Arbi whose the underlying asset doesn't exist on the chain)
     * @return assetAddress the address of the asset
     * @return assetDecimals the decimals of the asset
     */
    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../pendle_libraries/PMath.sol";
import "../pendle_libraries/LogExpMath.sol";

import "./PYIndex.sol";
import "../pendle_libraries/MiniHelpers.sol";
import "../pendle_libraries/Errors.sol";

struct MarketState {
    int256 totalPt;
    int256 totalSy;
    int256 totalLp;
    address treasury;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 expiry;
    /// fee data ///
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent; // base 100
    /// last trade data ///
    uint256 lastLnImpliedRate;
}

// params that are expensive to compute, therefore we pre-compute them
struct MarketPreCompute {
    int256 rateScalar;
    int256 totalAsset;
    int256 rateAnchor;
    int256 feeRate;
}

// solhint-disable ordering
library MarketMathCore {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;
    using PYIndexLib for PYIndex;

    int256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    uint256 internal constant DAY = 86400;
    uint256 internal constant IMPLIED_RATE_TIME = 365 * DAY;

    int256 internal constant MAX_MARKET_PROPORTION = (1e18 * 96) / 100;

    using PMath for uint256;
    using PMath for int256;

    /*///////////////////////////////////////////////////////////////
                UINT FUNCTIONS TO PROXY TO CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired,
        uint256 blockTime
    ) internal pure returns (uint256 lpToReserve, uint256 lpToAccount, uint256 syUsed, uint256 ptUsed) {
        (int256 _lpToReserve, int256 _lpToAccount, int256 _syUsed, int256 _ptUsed) = addLiquidityCore(
            market,
            syDesired.Int(),
            ptDesired.Int(),
            blockTime
        );

        lpToReserve = _lpToReserve.Uint();
        lpToAccount = _lpToAccount.Uint();
        syUsed = _syUsed.Uint();
        ptUsed = _ptUsed.Uint();
    }

    function removeLiquidity(
        MarketState memory market,
        uint256 lpToRemove
    ) internal pure returns (uint256 netSyToAccount, uint256 netPtToAccount) {
        (int256 _syToAccount, int256 _ptToAccount) = removeLiquidityCore(market, lpToRemove.Int());

        netSyToAccount = _syToAccount.Uint();
        netPtToAccount = _ptToAccount.Uint();
    }

    function swapExactPtForSy(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToMarket,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToAccount, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToMarket.neg(),
            blockTime
        );

        netSyToAccount = _netSyToAccount.Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function swapSyForExactPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToAccount,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToMarket, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToAccount.Int(),
            blockTime
        );

        netSyToMarket = _netSyToAccount.neg().Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    /*///////////////////////////////////////////////////////////////
                    CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidityCore(
        MarketState memory market,
        int256 syDesired,
        int256 ptDesired,
        uint256 blockTime
    ) internal pure returns (int256 lpToReserve, int256 lpToAccount, int256 syUsed, int256 ptUsed) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (syDesired == 0 || ptDesired == 0) revert Errors.MarketZeroAmountsInput();
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        if (market.totalLp == 0) {
            lpToAccount = PMath.sqrt((syDesired * ptDesired).Uint()).Int() - MINIMUM_LIQUIDITY;
            lpToReserve = MINIMUM_LIQUIDITY;
            syUsed = syDesired;
            ptUsed = ptDesired;
        } else {
            int256 netLpByPt = (ptDesired * market.totalLp) / market.totalPt;
            int256 netLpBySy = (syDesired * market.totalLp) / market.totalSy;
            if (netLpByPt < netLpBySy) {
                lpToAccount = netLpByPt;
                ptUsed = ptDesired;
                syUsed = (market.totalSy * lpToAccount) / market.totalLp;
            } else {
                lpToAccount = netLpBySy;
                syUsed = syDesired;
                ptUsed = (market.totalPt * lpToAccount) / market.totalLp;
            }
        }

        if (lpToAccount <= 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalSy += syUsed;
        market.totalPt += ptUsed;
        market.totalLp += lpToAccount + lpToReserve;
    }

    function removeLiquidityCore(
        MarketState memory market,
        int256 lpToRemove
    ) internal pure returns (int256 netSyToAccount, int256 netPtToAccount) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (lpToRemove == 0) revert Errors.MarketZeroAmountsInput();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        netSyToAccount = (lpToRemove * market.totalSy) / market.totalLp;
        netPtToAccount = (lpToRemove * market.totalPt) / market.totalLp;

        if (netSyToAccount == 0 && netPtToAccount == 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalLp = market.totalLp.subNoNeg(lpToRemove);
        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount);
    }

    function executeTradeCore(
        MarketState memory market,
        PYIndex index,
        int256 netPtToAccount,
        uint256 blockTime
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();
        if (market.totalPt <= netPtToAccount) revert Errors.MarketInsufficientPtForTrade(market.totalPt, netPtToAccount);

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        MarketPreCompute memory comp = getMarketPreCompute(market, index, blockTime);

        (netSyToAccount, netSyFee, netSyToReserve) = calcTrade(market, comp, index, netPtToAccount);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        _setNewMarketStateTrade(market, comp, index, netPtToAccount, netSyToAccount, netSyToReserve, blockTime);
    }

    function getMarketPreCompute(
        MarketState memory market,
        PYIndex index,
        uint256 blockTime
    ) internal pure returns (MarketPreCompute memory res) {
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        uint256 timeToExpiry = market.expiry - blockTime;

        res.rateScalar = _getRateScalar(market, timeToExpiry);
        res.totalAsset = index.syToAsset(market.totalSy);

        if (market.totalPt == 0 || res.totalAsset == 0) revert Errors.MarketZeroTotalPtOrTotalAsset(market.totalPt, res.totalAsset);

        res.rateAnchor = _getRateAnchor(market.totalPt, market.lastLnImpliedRate, res.totalAsset, res.rateScalar, timeToExpiry);
        res.feeRate = _getExchangeRateFromImpliedRate(market.lnFeeRateRoot, timeToExpiry);
    }

    function calcTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        int256 preFeeExchangeRate = _getExchangeRate(market.totalPt, comp.totalAsset, comp.rateScalar, comp.rateAnchor, netPtToAccount);

        int256 preFeeAssetToAccount = netPtToAccount.divDown(preFeeExchangeRate).neg();
        int256 fee = comp.feeRate;

        if (netPtToAccount > 0) {
            int256 postFeeExchangeRate = preFeeExchangeRate.divDown(fee);
            if (postFeeExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(postFeeExchangeRate);

            fee = preFeeAssetToAccount.mulDown(PMath.IONE - fee);
        } else {
            fee = ((preFeeAssetToAccount * (PMath.IONE - fee)) / fee).neg();
        }

        int256 netAssetToReserve = (fee * market.reserveFeePercent.Int()) / PERCENTAGE_DECIMALS;
        int256 netAssetToAccount = preFeeAssetToAccount - fee;

        netSyToAccount = netAssetToAccount < 0 ? index.assetToSyUp(netAssetToAccount) : index.assetToSy(netAssetToAccount);
        netSyFee = index.assetToSy(fee);
        netSyToReserve = index.assetToSy(netAssetToReserve);
    }

    function _setNewMarketStateTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount,
        int256 netSyToAccount,
        int256 netSyToReserve,
        uint256 blockTime
    ) internal pure {
        uint256 timeToExpiry = market.expiry - blockTime;

        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount + netSyToReserve);

        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            index.syToAsset(market.totalSy),
            comp.rateScalar,
            comp.rateAnchor,
            timeToExpiry
        );

        if (market.lastLnImpliedRate == 0) revert Errors.MarketZeroLnImpliedRate();
    }

    function _getRateAnchor(
        int256 totalPt,
        uint256 lastLnImpliedRate,
        int256 totalAsset,
        int256 rateScalar,
        uint256 timeToExpiry
    ) internal pure returns (int256 rateAnchor) {
        int256 newExchangeRate = _getExchangeRateFromImpliedRate(lastLnImpliedRate, timeToExpiry);

        if (newExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(newExchangeRate);

        {
            int256 proportion = totalPt.divDown(totalPt + totalAsset);

            int256 lnProportion = _logProportion(proportion);

            rateAnchor = newExchangeRate - lnProportion.divDown(rateScalar);
        }
    }

    /// @notice Calculates the current market implied rate.
    /// @return lnImpliedRate the implied rate
    function _getLnImpliedRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) internal pure returns (uint256 lnImpliedRate) {
        // This will check for exchange rates < PMath.IONE
        int256 exchangeRate = _getExchangeRate(totalPt, totalAsset, rateScalar, rateAnchor, 0);

        // exchangeRate >= 1 so its ln >= 0
        uint256 lnRate = exchangeRate.ln().Uint();

        lnImpliedRate = (lnRate * IMPLIED_RATE_TIME) / timeToExpiry;
    }

    /// @notice Converts an implied rate to an exchange rate given a time to expiry. The
    /// formula is E = e^rt
    function _getExchangeRateFromImpliedRate(uint256 lnImpliedRate, uint256 timeToExpiry) internal pure returns (int256 exchangeRate) {
        uint256 rt = (lnImpliedRate * timeToExpiry) / IMPLIED_RATE_TIME;

        exchangeRate = LogExpMath.exp(rt.Int());
    }

    function _getExchangeRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        int256 netPtToAccount
    ) internal pure returns (int256 exchangeRate) {
        int256 numerator = totalPt.subNoNeg(netPtToAccount);

        int256 proportion = (numerator.divDown(totalPt + totalAsset));

        if (proportion > MAX_MARKET_PROPORTION) revert Errors.MarketProportionTooHigh(proportion, MAX_MARKET_PROPORTION);

        int256 lnProportion = _logProportion(proportion);

        exchangeRate = lnProportion.divDown(rateScalar) + rateAnchor;

        if (exchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(exchangeRate);
    }

    function _logProportion(int256 proportion) internal pure returns (int256 res) {
        if (proportion == PMath.IONE) revert Errors.MarketProportionMustNotEqualOne();

        int256 logitP = proportion.divDown(PMath.IONE - proportion);

        res = logitP.ln();
    }

    function _getRateScalar(MarketState memory market, uint256 timeToExpiry) internal pure returns (int256 rateScalar) {
        rateScalar = (market.scalarRoot * IMPLIED_RATE_TIME.Int()) / timeToExpiry.Int();
        if (rateScalar <= 0) revert Errors.MarketRateScalarBelowZero(rateScalar);
    }

    function setInitialLnImpliedRate(MarketState memory market, PYIndex index, int256 initialAnchor, uint256 blockTime) internal pure {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        int256 totalAsset = index.syToAsset(market.totalSy);
        uint256 timeToExpiry = market.expiry - blockTime;
        int256 rateScalar = _getRateScalar(market, timeToExpiry);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.lastLnImpliedRate = _getLnImpliedRate(market.totalPt, totalAsset, rateScalar, initialAnchor, timeToExpiry);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./IPYieldToken.sol";
import "./IPPrincipalToken.sol";

import "./SYUtils.sol";
import "../pendle_libraries/PMath.sol";

type PYIndex is uint256;

library PYIndexLib {
    using PMath for uint256;
    using PMath for int256;

    function newIndex(IPYieldToken YT) internal returns (PYIndex) {
        return PYIndex.wrap(YT.pyIndexCurrent());
    }

    function syToAsset(PYIndex index, uint256 syAmount) internal pure returns (uint256) {
        return SYUtils.syToAsset(PYIndex.unwrap(index), syAmount);
    }

    function assetToSy(PYIndex index, uint256 assetAmount) internal pure returns (uint256) {
        return SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount);
    }

    function assetToSyUp(PYIndex index, uint256 assetAmount) internal pure returns (uint256) {
        return SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount);
    }

    function syToAssetUp(PYIndex index, uint256 syAmount) internal pure returns (uint256) {
        uint256 _index = PYIndex.unwrap(index);
        return SYUtils.syToAssetUp(_index, syAmount);
    }

    function syToAsset(PYIndex index, int256 syAmount) internal pure returns (int256) {
        int256 sign = syAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.syToAsset(PYIndex.unwrap(index), syAmount.abs())).Int();
    }

    function assetToSy(PYIndex index, int256 assetAmount) internal pure returns (int256) {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }

    function assetToSyUp(PYIndex index, int256 assetAmount) internal pure returns (int256) {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

library SYUtils {
    uint256 internal constant ONE = 1e18;

    function syToAsset(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate) / ONE;
    }

    function syToAssetUp(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate + ONE - 1) / ONE;
    }

    function assetToSy(uint256 exchangeRate, uint256 assetAmount) internal pure returns (uint256) {
        return (assetAmount * ONE) / exchangeRate;
    }

    function assetToSyUp(uint256 exchangeRate, uint256 assetAmount) internal pure returns (uint256) {
        return (assetAmount * ONE + exchangeRate - 1) / exchangeRate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

library Errors {
    // BulkSeller
    error BulkInsufficientSyForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInsufficientTokenForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInSufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error BulkInSufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error BulkInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error BulkNotMaintainer();
    error BulkNotAdmin();
    error BulkSellerAlreadyExisted(address token, address SY, address bulk);
    error BulkSellerInvalidToken(address token, address SY);
    error BulkBadRateTokenToSy(uint256 actualRate, uint256 currentRate, uint256 eps);
    error BulkBadRateSyToToken(uint256 actualRate, uint256 currentRate, uint256 eps);

    // APPROX
    error ApproxFail();
    error ApproxParamsInvalid(uint256 guessMin, uint256 guessMax, uint256 eps);
    error ApproxBinarySearchInputInvalid(uint256 approxGuessMin, uint256 approxGuessMax, uint256 minGuessMin, uint256 maxGuessMax);

    // MARKET + MARKET MATH CORE
    error MarketExpired();
    error MarketZeroAmountsInput();
    error MarketZeroAmountsOutput();
    error MarketZeroLnImpliedRate();
    error MarketInsufficientPtForTrade(int256 currentAmount, int256 requiredAmount);
    error MarketInsufficientPtReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketZeroTotalPtOrTotalAsset(int256 totalPt, int256 totalAsset);
    error MarketExchangeRateBelowOne(int256 exchangeRate);
    error MarketProportionMustNotEqualOne();
    error MarketRateScalarBelowZero(int256 rateScalar);
    error MarketScalarRootBelowZero(int256 scalarRoot);
    error MarketProportionTooHigh(int256 proportion, int256 maxProportion);

    error OracleUninitialized();
    error OracleTargetTooOld(uint32 target, uint32 oldest);
    error OracleZeroCardinality();

    error MarketFactoryExpiredPt();
    error MarketFactoryInvalidPt();
    error MarketFactoryMarketExists();

    error MarketFactoryLnFeeRateRootTooHigh(uint80 lnFeeRateRoot, uint256 maxLnFeeRateRoot);
    error MarketFactoryOverriddenFeeTooHigh(uint80 overriddenFee, uint256 marketLnFeeRateRoot);
    error MarketFactoryReserveFeePercentTooHigh(uint8 reserveFeePercent, uint8 maxReserveFeePercent);
    error MarketFactoryZeroTreasury();
    error MarketFactoryInitialAnchorTooLow(int256 initialAnchor, int256 minInitialAnchor);
    error MFNotPendleMarket(address addr);

    // ROUTER
    error RouterInsufficientLpOut(uint256 actualLpOut, uint256 requiredLpOut);
    error RouterInsufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error RouterInsufficientPtOut(uint256 actualPtOut, uint256 requiredPtOut);
    error RouterInsufficientYtOut(uint256 actualYtOut, uint256 requiredYtOut);
    error RouterInsufficientPYOut(uint256 actualPYOut, uint256 requiredPYOut);
    error RouterInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error RouterInsufficientSyRepay(uint256 actualSyRepay, uint256 requiredSyRepay);
    error RouterInsufficientPtRepay(uint256 actualPtRepay, uint256 requiredPtRepay);
    error RouterNotAllSyUsed(uint256 netSyDesired, uint256 netSyUsed);

    error RouterTimeRangeZero();
    error RouterCallbackNotPendleMarket(address caller);
    error RouterInvalidAction(bytes4 selector);
    error RouterInvalidFacet(address facet);

    error RouterKyberSwapDataZero();

    error SimulationResults(bool success, bytes res);

    // YIELD CONTRACT
    error YCExpired();
    error YCNotExpired();
    error YieldContractInsufficientSy(uint256 actualSy, uint256 requiredSy);
    error YCNothingToRedeem();
    error YCPostExpiryDataNotSet();
    error YCNoFloatingSy();

    // YieldFactory
    error YCFactoryInvalidExpiry();
    error YCFactoryYieldContractExisted();
    error YCFactoryZeroExpiryDivisor();
    error YCFactoryZeroTreasury();
    error YCFactoryInterestFeeRateTooHigh(uint256 interestFeeRate, uint256 maxInterestFeeRate);
    error YCFactoryRewardFeeRateTooHigh(uint256 newRewardFeeRate, uint256 maxRewardFeeRate);

    // SY
    error SYInvalidTokenIn(address token);
    error SYInvalidTokenOut(address token);
    error SYZeroDeposit();
    error SYZeroRedeem();
    error SYInsufficientSharesOut(uint256 actualSharesOut, uint256 requiredSharesOut);
    error SYInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);

    // SY-specific
    error SYQiTokenMintFailed(uint256 errCode);
    error SYQiTokenRedeemFailed(uint256 errCode);
    error SYQiTokenRedeemRewardsFailed(uint256 rewardAccruedType0, uint256 rewardAccruedType1);
    error SYQiTokenBorrowRateTooHigh(uint256 borrowRate, uint256 borrowRateMax);

    error SYCurveInvalidPid();
    error SYCurve3crvPoolNotFound();

    error SYApeDepositAmountTooSmall(uint256 amountDeposited);
    error SYBalancerInvalidPid();
    error SYInvalidRewardToken(address token);

    error SYStargateRedeemCapExceeded(uint256 amountLpDesired, uint256 amountLpRedeemable);

    error SYBalancerReentrancy();

    error NotFromTrustedRemote(uint16 srcChainId, bytes path);

    // Liquidity Mining
    error VCInactivePool(address pool);
    error VCPoolAlreadyActive(address pool);
    error VCZeroVePendle(address user);
    error VCExceededMaxWeight(uint256 totalWeight, uint256 maxWeight);
    error VCEpochNotFinalized(uint256 wTime);
    error VCPoolAlreadyAddAndRemoved(address pool);

    error VEInvalidNewExpiry(uint256 newExpiry);
    error VEExceededMaxLockTime();
    error VEInsufficientLockTime();
    error VENotAllowedReduceExpiry();
    error VEZeroAmountLocked();
    error VEPositionNotExpired();
    error VEZeroPosition();
    error VEZeroSlope(uint128 bias, uint128 slope);
    error VEReceiveOldSupply(uint256 msgTime);

    error GCNotPendleMarket(address caller);
    error GCNotVotingController(address caller);

    error InvalidWTime(uint256 wTime);
    error ExpiryInThePast(uint256 expiry);
    error ChainNotSupported(uint256 chainId);

    error FDTotalAmountFundedNotMatch(uint256 actualTotalAmount, uint256 expectedTotalAmount);
    error FDEpochLengthMismatch();
    error FDInvalidPool(address pool);
    error FDPoolAlreadyExists(address pool);
    error FDInvalidNewFinishedEpoch(uint256 oldFinishedEpoch, uint256 newFinishedEpoch);
    error FDInvalidStartEpoch(uint256 startEpoch);
    error FDInvalidWTimeFund(uint256 lastFunded, uint256 wTime);
    error FDFutureFunding(uint256 lastFunded, uint256 currentWTime);

    error BDInvalidEpoch(uint256 epoch, uint256 startTime);

    // Cross-Chain
    error MsgNotFromSendEndpoint(uint16 srcChainId, bytes path);
    error MsgNotFromReceiveEndpoint(address sender);
    error InsufficientFeeToSendMsg(uint256 currentFee, uint256 requiredFee);
    error ApproxDstExecutionGasNotSet();
    error InvalidRetryData();

    // GENERIC MSG
    error ArrayLengthMismatch();
    error ArrayEmpty();
    error ArrayOutOfBounds();
    error ZeroAddress();
    error FailedToSendEther();
    error InvalidMerkleProof();

    error OnlyLayerZeroEndpoint();
    error OnlyYT();
    error OnlyYCFactory();
    error OnlyWhitelisted();

    // Swap Aggregator
    error SAInsufficientTokenIn(address tokenIn, uint256 amountExpected, uint256 amountActual);
    error UnsupportedSelector(uint256 aggregatorType, bytes4 selector);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.4;

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, "Invalid exponent");

            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, "out of bounds");
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that r`esult. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2 ** 255, "x out of bounds");
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, "y out of bounds");
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT, "product out of bounds");

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./PMath.sol";
import "./MarketMathCore.sol";

struct ApproxParams {
    uint256 guessMin;
    uint256 guessMax;
    uint256 guessOffchain; // pass 0 in to skip this variable
    uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
    uint256 eps; // the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
    // to 1e15 (1e18/1000 = 0.1%)
}

/// Further explanation of the eps. Take swapExactSyForPt for example. To calc the corresponding amount of Pt to swap out,
/// it's necessary to run an approximation algorithm, because by default there only exists the Pt to Sy formula
/// To approx, the 5 values above will have to be provided, and the approx process will run as follows:
/// mid = (guessMin + guessMax) / 2 // mid here is the current guess of the amount of Pt out
/// netSyNeed = calcSwapSyForExactPt(mid)
/// if (netSyNeed > exactSyIn) guessMax = mid - 1 // since the maximum Sy in can't exceed the exactSyIn
/// else guessMin = mid (1)
/// For the (1), since netSyNeed <= exactSyIn, the result might be usable. If the netSyNeed is within eps of
/// exactSyIn (ex eps=0.1% => we have used 99.9% the amount of Sy specified), mid will be chosen as the final guess result

/// for guessOffchain, this is to provide a shortcut to guessing. The offchain SDK can precalculate the exact result
/// before the tx is sent. When the tx reaches the contract, the guessOffchain will be checked first, and if it satisfies the
/// approximation, it will be used (and save all the guessing). It's expected that this shortcut will be used in most cases
/// except in cases that there is a trade in the same market right before the tx

library MarketApproxPtInLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap in
     *     - Try swapping & get netSyOut
     *     - Stop when netSyOut greater & approx minSyOut
     *     - guess & approx is for netPtIn
     */
    function approxSwapPtForExactSy(
        MarketState memory market,
        PYIndex index,
        uint256 minSyOut,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtIn*/ uint256, /*netSyOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);
            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            if (netSyOut >= minSyOut) {
                if (PMath.isAGreaterApproxB(netSyOut, minSyOut, approx.eps)) {
                    return (guess, netSyOut, netSyFee);
                }
                approx.guessMax = guess;
            } else {
                approx.guessMin = guess;
            }
        }
        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap in
     *     - Flashswap the corresponding amount of SY out
     *     - Pair those amount with exactSyIn SY to tokenize into PT & YT
     *     - PT to repay the flashswap, YT transferred to user
     *     - Stop when the amount of SY to be pulled to tokenize PT to repay loan approx the exactSyIn
     *     - guess & approx is for netYtOut (also netPtIn)
     */
    function approxSwapExactSyForYt(
        MarketState memory market,
        PYIndex index,
        uint256 exactSyIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, index.syToAsset(exactSyIn));
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        // at minimum we will flashswap exactSyIn since we have enough SY to payback the PT loan

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            uint256 netSyToTokenizePt = index.assetToSyUp(guess);

            // for sure netSyToTokenizePt >= netSyOut since we are swapping PT to SY
            uint256 netSyToPull = netSyToTokenizePt - netSyOut;

            if (netSyToPull <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyToPull, exactSyIn, approx.eps)) {
                    return (guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args5 {
        MarketState market;
        PYIndex index;
        uint256 totalPtIn;
        uint256 netSyHolding;
        uint256 blockTime;
        ApproxParams approx;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap to SY
     *     - Swap PT to SY
     *     - Pair the remaining PT with the SY to add liquidity
     *     - Stop when the ratio of PT / totalPt & SY / totalSy is approx
     *     - guess & approx is for netPtSwap
     */
    function approxSwapPtToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalPtIn,
        uint256 _netSyHolding,
        uint256 _blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtSwap*/ uint256, /*netSyFromSwap*/ uint256 /*netSyFee*/) {
        Args5 memory a = Args5(_market, _index, _totalPtIn, _netSyHolding, _blockTime, approx);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(a.market, comp));
            approx.guessMax = PMath.min(approx.guessMax, a.totalPtIn);
            validateApprox(approx);
            require(a.market.totalLp != 0, "no existing lp");
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 syNumerator, uint256 ptNumerator, uint256 netSyOut, uint256 netSyFee, ) = calcNumerators(
                a.market,
                a.index,
                a.totalPtIn,
                a.netSyHolding,
                comp,
                guess
            );

            if (PMath.isAApproxB(syNumerator, ptNumerator, approx.eps)) {
                return (guess, netSyOut, netSyFee);
            }

            if (syNumerator <= ptNumerator) {
                // needs more SY --> swap more PT
                approx.guessMin = guess + 1;
            } else {
                // needs less SY --> swap less PT
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    function calcNumerators(
        MarketState memory market,
        PYIndex index,
        uint256 totalPtIn,
        uint256 netSyHolding,
        MarketPreCompute memory comp,
        uint256 guess
    ) internal pure returns (uint256 syNumerator, uint256 ptNumerator, uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve) {
        (netSyOut, netSyFee, netSyToReserve) = calcSyOut(market, comp, index, guess);

        uint256 newTotalPt = uint256(market.totalPt) + guess;
        uint256 newTotalSy = (uint256(market.totalSy) - netSyOut - netSyToReserve);

        // it is desired that
        // (netSyOut + netSyHolding) / newTotalSy = netPtRemaining / newTotalPt
        // which is equivalent to
        // (netSyOut + netSyHolding) * newTotalPt = netPtRemaining * newTotalSy

        syNumerator = (netSyOut + netSyHolding) * newTotalPt;
        ptNumerator = (totalPtIn - guess) * newTotalSy;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swap to SY
     *     - Flashswap the corresponding amount of SY out
     *     - Tokenize all the SY into PT + YT
     *     - PT to repay the flashswap, YT transferred to user
     *     - Stop when the additional amount of PT to pull to repay the loan approx the exactPtIn
     *     - guess & approx is for totalPtToSwap
     */
    function approxSwapExactPtForYt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtOut*/ uint256, /*totalPtToSwap*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, exactPtIn);
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtIn(market, comp));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(market, comp, index, guess);

            uint256 netAssetOut = index.syToAsset(netSyOut);

            // guess >= netAssetOut since we are swapping PT to SY
            uint256 netPtToPull = guess - netAssetOut;

            if (netPtToPull <= exactPtIn) {
                if (PMath.isASmallerApproxB(netPtToPull, exactPtIn, approx.eps)) {
                    return (netAssetOut, guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyOut(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtIn
    ) internal pure returns (uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyOut, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(comp, index, -int256(netPtIn));
        netSyOut = uint256(_netSyOut);
        netSyFee = uint256(_netSyFee);
        netSyToReserve = uint256(_netSyToReserve);
    }

    function nextGuess(ApproxParams memory approx, uint256 iter) internal pure returns (uint256) {
        if (iter == 0 && approx.guessOffchain != 0) return approx.guessOffchain;
        if (approx.guessMin <= approx.guessMax) return (approx.guessMin + approx.guessMax) / 2;
        revert Errors.ApproxFail();
    }

    /// INTENDED TO BE CALLED BY WHEN GUESS.OFFCHAIN == 0 ONLY ///

    function validateApprox(ApproxParams memory approx) internal pure {
        if (approx.guessMin > approx.guessMax || approx.eps > PMath.ONE) {
            revert Errors.ApproxParamsInvalid(approx.guessMin, approx.guessMax, approx.eps);
        }
    }

    function calcMaxPtIn(MarketState memory market, MarketPreCompute memory comp) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 hi = uint256(comp.totalAsset) - 1;

        while (low != hi) {
            uint256 mid = (low + hi + 1) / 2;
            if (calcSlope(comp, market.totalPt, int256(mid)) < 0) hi = mid - 1;
            else low = mid;
        }
        return low;
    }

    function calcSlope(MarketPreCompute memory comp, int256 totalPt, int256 ptToMarket) internal pure returns (int256) {
        int256 diffAssetPtToMarket = comp.totalAsset - ptToMarket;
        int256 sumPt = ptToMarket + totalPt;

        require(diffAssetPtToMarket > 0 && sumPt > 0, "invalid ptToMarket");

        int256 part1 = (ptToMarket * (totalPt + comp.totalAsset)).divDown(sumPt * diffAssetPtToMarket);

        int256 part2 = sumPt.divDown(diffAssetPtToMarket).ln();
        int256 part3 = PMath.IONE.divDown(comp.rateScalar);

        return comp.rateAnchor - (part1 - part2).mulDown(part3);
    }
}

library MarketApproxPtOutLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Calculate the amount of SY needed
     *     - Stop when the netSyIn is smaller approx exactSyIn
     *     - guess & approx is for netSyIn
     */
    function approxSwapExactSyForPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactSyIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyIn, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            if (netSyIn <= exactSyIn) {
                if (PMath.isASmallerApproxB(netSyIn, exactSyIn, approx.eps)) {
                    return (guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }

        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Flashswap that amount of PT & pair with YT to redeem SY
     *     - Use the SY to repay the flashswap debt and the remaining is transferred to user
     *     - Stop when the netSyOut is greater approx the minSyOut
     *     - guess & approx is for netSyOut
     */
    function approxSwapYtForExactSy(
        MarketState memory market,
        PYIndex index,
        uint256 minSyOut,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netYtIn*/ uint256, /*netSyOut*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            // no limit on min
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            uint256 netAssetToRepay = index.syToAssetUp(netSyOwed);
            uint256 netSyOut = index.assetToSy(guess - netAssetToRepay);

            if (netSyOut >= minSyOut) {
                if (PMath.isAGreaterApproxB(netSyOut, minSyOut, approx.eps)) {
                    return (guess, netSyOut, netSyFee);
                }
                approx.guessMax = guess;
            } else {
                approx.guessMin = guess + 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args6 {
        MarketState market;
        PYIndex index;
        uint256 totalSyIn;
        uint256 netPtHolding;
        uint256 blockTime;
        ApproxParams approx;
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Swap that amount of PT out
     *     - Pair the remaining PT with the SY to add liquidity
     *     - Stop when the ratio of PT / totalPt & SY / totalSy is approx
     *     - guess & approx is for netPtFromSwap
     */
    function approxSwapSyToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalSyIn,
        uint256 _netPtHolding,
        uint256 _blockTime,
        ApproxParams memory _approx
    ) internal pure returns (uint256, /*netPtFromSwap*/ uint256, /*netSySwap*/ uint256 /*netSyFee*/) {
        Args6 memory a = Args6(_market, _index, _totalSyIn, _netPtHolding, _blockTime, _approx);

        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        if (a.approx.guessOffchain == 0) {
            // no limit on min
            a.approx.guessMax = PMath.min(a.approx.guessMax, calcMaxPtOut(comp, a.market.totalPt));
            validateApprox(a.approx);
            require(a.market.totalLp != 0, "no existing lp");
        }

        for (uint256 iter = 0; iter < a.approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(a.approx, iter);

            (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve) = calcSyIn(a.market, comp, a.index, guess);

            if (netSyIn > a.totalSyIn) {
                a.approx.guessMax = guess - 1;
                continue;
            }

            uint256 syNumerator;
            uint256 ptNumerator;

            {
                uint256 newTotalPt = uint256(a.market.totalPt) - guess;
                uint256 netTotalSy = uint256(a.market.totalSy) + netSyIn - netSyToReserve;

                // it is desired that
                // (netPtFromSwap + netPtHolding) / newTotalPt = netSyRemaining / netTotalSy
                // which is equivalent to
                // (netPtFromSwap + netPtHolding) * netTotalSy = netSyRemaining * newTotalPt

                ptNumerator = (guess + a.netPtHolding) * netTotalSy;
                syNumerator = (a.totalSyIn - netSyIn) * newTotalPt;
            }

            if (PMath.isAApproxB(ptNumerator, syNumerator, a.approx.eps)) {
                return (guess, netSyIn, netSyFee);
            }

            if (ptNumerator <= syNumerator) {
                // needs more PT
                a.approx.guessMin = guess + 1;
            } else {
                // needs less PT
                a.approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    /**
     * @dev algorithm:
     *     - Bin search the amount of PT to swapExactOut
     *     - Flashswap that amount of PT out
     *     - Pair all the PT with the YT to redeem SY
     *     - Use the SY to repay the flashswap debt
     *     - Stop when the amount of YT required to pair with PT is approx exactYtIn
     *     - guess & approx is for netPtFromSwap
     */
    function approxSwapExactYtForPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactYtIn,
        uint256 blockTime,
        ApproxParams memory approx
    ) internal pure returns (uint256, /*netPtOut*/ uint256, /*totalPtSwapped*/ uint256 /*netSyFee*/) {
        MarketPreCompute memory comp = market.getMarketPreCompute(index, blockTime);
        if (approx.guessOffchain == 0) {
            approx.guessMin = PMath.max(approx.guessMin, exactYtIn);
            approx.guessMax = PMath.min(approx.guessMax, calcMaxPtOut(comp, market.totalPt));
            validateApprox(approx);
        }

        for (uint256 iter = 0; iter < approx.maxIteration; ++iter) {
            uint256 guess = nextGuess(approx, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(market, comp, index, guess);

            uint256 netYtToPull = index.syToAssetUp(netSyOwed);

            if (netYtToPull <= exactYtIn) {
                if (PMath.isASmallerApproxB(netYtToPull, exactYtIn, approx.eps)) {
                    return (guess - netYtToPull, guess, netSyFee);
                }
                approx.guessMin = guess;
            } else {
                approx.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyIn(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtOut
    ) internal pure returns (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyIn, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(comp, index, int256(netPtOut));

        // all safe since totalPt and totalSy is int128
        netSyIn = uint256(-_netSyIn);
        netSyFee = uint256(_netSyFee);
        netSyToReserve = uint256(_netSyToReserve);
    }

    function calcMaxPtOut(MarketPreCompute memory comp, int256 totalPt) internal pure returns (uint256) {
        int256 logitP = (comp.feeRate - comp.rateAnchor).mulDown(comp.rateScalar).exp();
        int256 proportion = logitP.divDown(logitP + PMath.IONE);
        int256 numerator = proportion.mulDown(totalPt + comp.totalAsset);
        int256 maxPtOut = totalPt - numerator;
        // only get 99.9% of the theoretical max to accommodate some precision issues
        return (uint256(maxPtOut) * 999) / 1000;
    }

    function nextGuess(ApproxParams memory approx, uint256 iter) internal pure returns (uint256) {
        if (iter == 0 && approx.guessOffchain != 0) return approx.guessOffchain;
        if (approx.guessMin <= approx.guessMax) return (approx.guessMin + approx.guessMax) / 2;
        revert Errors.ApproxFail();
    }

    function validateApprox(ApproxParams memory approx) internal pure {
        if (approx.guessMin > approx.guessMax || approx.eps > PMath.ONE) {
            revert Errors.ApproxParamsInvalid(approx.guessMin, approx.guessMax, approx.eps);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./PMath.sol";
import "./LogExpMath.sol";

import "../pendle_interfaces/PYIndex.sol";
import "./MiniHelpers.sol";
import "./Errors.sol";

struct MarketState {
    int256 totalPt;
    int256 totalSy;
    int256 totalLp;
    address treasury;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 expiry;
    /// fee data ///
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent; // base 100
    /// last trade data ///
    uint256 lastLnImpliedRate;
}

// params that are expensive to compute, therefore we pre-compute them
struct MarketPreCompute {
    int256 rateScalar;
    int256 totalAsset;
    int256 rateAnchor;
    int256 feeRate;
}

// solhint-disable ordering
library MarketMathCore {
    using PMath for uint256;
    using PMath for int256;
    using LogExpMath for int256;
    using PYIndexLib for PYIndex;

    int256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    uint256 internal constant DAY = 86400;
    uint256 internal constant IMPLIED_RATE_TIME = 365 * DAY;

    int256 internal constant MAX_MARKET_PROPORTION = (1e18 * 96) / 100;

    using PMath for uint256;
    using PMath for int256;

    /*///////////////////////////////////////////////////////////////
                UINT FUNCTIONS TO PROXY TO CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired,
        uint256 blockTime
    ) internal pure returns (uint256 lpToReserve, uint256 lpToAccount, uint256 syUsed, uint256 ptUsed) {
        (int256 _lpToReserve, int256 _lpToAccount, int256 _syUsed, int256 _ptUsed) = addLiquidityCore(
            market,
            syDesired.Int(),
            ptDesired.Int(),
            blockTime
        );

        lpToReserve = _lpToReserve.Uint();
        lpToAccount = _lpToAccount.Uint();
        syUsed = _syUsed.Uint();
        ptUsed = _ptUsed.Uint();
    }

    function removeLiquidity(
        MarketState memory market,
        uint256 lpToRemove
    ) internal pure returns (uint256 netSyToAccount, uint256 netPtToAccount) {
        (int256 _syToAccount, int256 _ptToAccount) = removeLiquidityCore(market, lpToRemove.Int());

        netSyToAccount = _syToAccount.Uint();
        netPtToAccount = _ptToAccount.Uint();
    }

    function swapExactPtForSy(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToMarket,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToAccount, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToMarket.neg(),
            blockTime
        );

        netSyToAccount = _netSyToAccount.Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function swapSyForExactPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToAccount,
        uint256 blockTime
    ) internal pure returns (uint256 netSyToMarket, uint256 netSyFee, uint256 netSyToReserve) {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToAccount.Int(),
            blockTime
        );

        netSyToMarket = _netSyToAccount.neg().Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    /*///////////////////////////////////////////////////////////////
                    CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidityCore(
        MarketState memory market,
        int256 syDesired,
        int256 ptDesired,
        uint256 blockTime
    ) internal pure returns (int256 lpToReserve, int256 lpToAccount, int256 syUsed, int256 ptUsed) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (syDesired == 0 || ptDesired == 0) revert Errors.MarketZeroAmountsInput();
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        if (market.totalLp == 0) {
            lpToAccount = PMath.sqrt((syDesired * ptDesired).Uint()).Int() - MINIMUM_LIQUIDITY;
            lpToReserve = MINIMUM_LIQUIDITY;
            syUsed = syDesired;
            ptUsed = ptDesired;
        } else {
            int256 netLpByPt = (ptDesired * market.totalLp) / market.totalPt;
            int256 netLpBySy = (syDesired * market.totalLp) / market.totalSy;
            if (netLpByPt < netLpBySy) {
                lpToAccount = netLpByPt;
                ptUsed = ptDesired;
                syUsed = (market.totalSy * lpToAccount) / market.totalLp;
            } else {
                lpToAccount = netLpBySy;
                syUsed = syDesired;
                ptUsed = (market.totalPt * lpToAccount) / market.totalLp;
            }
        }

        if (lpToAccount <= 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalSy += syUsed;
        market.totalPt += ptUsed;
        market.totalLp += lpToAccount + lpToReserve;
    }

    function removeLiquidityCore(
        MarketState memory market,
        int256 lpToRemove
    ) internal pure returns (int256 netSyToAccount, int256 netPtToAccount) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (lpToRemove == 0) revert Errors.MarketZeroAmountsInput();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        netSyToAccount = (lpToRemove * market.totalSy) / market.totalLp;
        netPtToAccount = (lpToRemove * market.totalPt) / market.totalLp;

        if (netSyToAccount == 0 && netPtToAccount == 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalLp = market.totalLp.subNoNeg(lpToRemove);
        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount);
    }

    function executeTradeCore(
        MarketState memory market,
        PYIndex index,
        int256 netPtToAccount,
        uint256 blockTime
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();
        if (market.totalPt <= netPtToAccount) revert Errors.MarketInsufficientPtForTrade(market.totalPt, netPtToAccount);

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        MarketPreCompute memory comp = getMarketPreCompute(market, index, blockTime);

        (netSyToAccount, netSyFee, netSyToReserve) = calcTrade(market, comp, index, netPtToAccount);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        _setNewMarketStateTrade(market, comp, index, netPtToAccount, netSyToAccount, netSyToReserve, blockTime);
    }

    function getMarketPreCompute(
        MarketState memory market,
        PYIndex index,
        uint256 blockTime
    ) internal pure returns (MarketPreCompute memory res) {
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        uint256 timeToExpiry = market.expiry - blockTime;

        res.rateScalar = _getRateScalar(market, timeToExpiry);
        res.totalAsset = index.syToAsset(market.totalSy);

        if (market.totalPt == 0 || res.totalAsset == 0) revert Errors.MarketZeroTotalPtOrTotalAsset(market.totalPt, res.totalAsset);

        res.rateAnchor = _getRateAnchor(market.totalPt, market.lastLnImpliedRate, res.totalAsset, res.rateScalar, timeToExpiry);
        res.feeRate = _getExchangeRateFromImpliedRate(market.lnFeeRateRoot, timeToExpiry);
    }

    function calcTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount
    ) internal pure returns (int256 netSyToAccount, int256 netSyFee, int256 netSyToReserve) {
        int256 preFeeExchangeRate = _getExchangeRate(market.totalPt, comp.totalAsset, comp.rateScalar, comp.rateAnchor, netPtToAccount);

        int256 preFeeAssetToAccount = netPtToAccount.divDown(preFeeExchangeRate).neg();
        int256 fee = comp.feeRate;

        if (netPtToAccount > 0) {
            int256 postFeeExchangeRate = preFeeExchangeRate.divDown(fee);
            if (postFeeExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(postFeeExchangeRate);

            fee = preFeeAssetToAccount.mulDown(PMath.IONE - fee);
        } else {
            fee = ((preFeeAssetToAccount * (PMath.IONE - fee)) / fee).neg();
        }

        int256 netAssetToReserve = (fee * market.reserveFeePercent.Int()) / PERCENTAGE_DECIMALS;
        int256 netAssetToAccount = preFeeAssetToAccount - fee;

        netSyToAccount = netAssetToAccount < 0 ? index.assetToSyUp(netAssetToAccount) : index.assetToSy(netAssetToAccount);
        netSyFee = index.assetToSy(fee);
        netSyToReserve = index.assetToSy(netAssetToReserve);
    }

    function _setNewMarketStateTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount,
        int256 netSyToAccount,
        int256 netSyToReserve,
        uint256 blockTime
    ) internal pure {
        uint256 timeToExpiry = market.expiry - blockTime;

        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount + netSyToReserve);

        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            index.syToAsset(market.totalSy),
            comp.rateScalar,
            comp.rateAnchor,
            timeToExpiry
        );

        if (market.lastLnImpliedRate == 0) revert Errors.MarketZeroLnImpliedRate();
    }

    function _getRateAnchor(
        int256 totalPt,
        uint256 lastLnImpliedRate,
        int256 totalAsset,
        int256 rateScalar,
        uint256 timeToExpiry
    ) internal pure returns (int256 rateAnchor) {
        int256 newExchangeRate = _getExchangeRateFromImpliedRate(lastLnImpliedRate, timeToExpiry);

        if (newExchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(newExchangeRate);

        {
            int256 proportion = totalPt.divDown(totalPt + totalAsset);

            int256 lnProportion = _logProportion(proportion);

            rateAnchor = newExchangeRate - lnProportion.divDown(rateScalar);
        }
    }

    /// @notice Calculates the current market implied rate.
    /// @return lnImpliedRate the implied rate
    function _getLnImpliedRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) internal pure returns (uint256 lnImpliedRate) {
        // This will check for exchange rates < PMath.IONE
        int256 exchangeRate = _getExchangeRate(totalPt, totalAsset, rateScalar, rateAnchor, 0);

        // exchangeRate >= 1 so its ln >= 0
        uint256 lnRate = exchangeRate.ln().Uint();

        lnImpliedRate = (lnRate * IMPLIED_RATE_TIME) / timeToExpiry;
    }

    /// @notice Converts an implied rate to an exchange rate given a time to expiry. The
    /// formula is E = e^rt
    function _getExchangeRateFromImpliedRate(uint256 lnImpliedRate, uint256 timeToExpiry) internal pure returns (int256 exchangeRate) {
        uint256 rt = (lnImpliedRate * timeToExpiry) / IMPLIED_RATE_TIME;

        exchangeRate = LogExpMath.exp(rt.Int());
    }

    function _getExchangeRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        int256 netPtToAccount
    ) internal pure returns (int256 exchangeRate) {
        int256 numerator = totalPt.subNoNeg(netPtToAccount);

        int256 proportion = (numerator.divDown(totalPt + totalAsset));

        if (proportion > MAX_MARKET_PROPORTION) revert Errors.MarketProportionTooHigh(proportion, MAX_MARKET_PROPORTION);

        int256 lnProportion = _logProportion(proportion);

        exchangeRate = lnProportion.divDown(rateScalar) + rateAnchor;

        if (exchangeRate < PMath.IONE) revert Errors.MarketExchangeRateBelowOne(exchangeRate);
    }

    function _logProportion(int256 proportion) internal pure returns (int256 res) {
        if (proportion == PMath.IONE) revert Errors.MarketProportionMustNotEqualOne();

        int256 logitP = proportion.divDown(PMath.IONE - proportion);

        res = logitP.ln();
    }

    function _getRateScalar(MarketState memory market, uint256 timeToExpiry) internal pure returns (int256 rateScalar) {
        rateScalar = (market.scalarRoot * IMPLIED_RATE_TIME.Int()) / timeToExpiry.Int();
        if (rateScalar <= 0) revert Errors.MarketRateScalarBelowZero(rateScalar);
    }

    function setInitialLnImpliedRate(MarketState memory market, PYIndex index, int256 initialAnchor, uint256 blockTime) internal pure {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        int256 totalAsset = index.syToAsset(market.totalSy);
        uint256 timeToExpiry = market.expiry - blockTime;
        int256 rateScalar = _getRateScalar(market, timeToExpiry);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.lastLnImpliedRate = _getLnImpliedRate(market.totalPt, totalAsset, rateScalar, initialAnchor, timeToExpiry);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

library MiniHelpers {
    function isCurrentlyExpired(uint256 expiry) internal view returns (bool) {
        return (expiry <= block.timestamp);
    }

    function isExpired(uint256 expiry, uint256 blockTime) internal pure returns (bool) {
        return (expiry <= blockTime);
    }

    function isTimeInThePast(uint256 timestamp) internal view returns (bool) {
        return (timestamp <= block.timestamp); // same definition as isCurrentlyExpired
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

/* solhint-disable private-vars-leading-underscore, reason-string */

library PMath {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant IONE = 1e18; // 18 decimal places

    function subMax0(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >= b ? a - b : 0);
        }
    }

    function subNoNeg(int256 a, int256 b) internal pure returns (int256) {
        require(a >= b, "negative");
        return a - b; // no unchecked since if b is very negative, a - b might overflow
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        unchecked {
            return product / ONE;
        }
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        unchecked {
            return product / IONE;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 aInflated = a * ONE;
        unchecked {
            return aInflated / b;
        }
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        int256 aInflated = a * IONE;
        unchecked {
            return aInflated / b;
        }
    }

    function rawDivUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function square(uint256 x) internal pure returns (uint256) {
        return x * x;
    }

    function squareDown(uint256 x) internal pure returns (uint256) {
        return mulDown(x, x);
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    function neg(int256 x) internal pure returns (int256) {
        return x * (-1);
    }

    function neg(uint256 x) internal pure returns (int256) {
        return Int(x) * (-1);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y ? x : y);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return (x > y ? x : y);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y ? x : y);
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return (x < y ? x : y);
    }

    /*///////////////////////////////////////////////////////////////
                               SIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Int(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max));
        return int256(x);
    }

    function Int128(int256 x) internal pure returns (int128) {
        require(type(int128).min <= x && x <= type(int128).max);
        return int128(x);
    }

    function Int128(uint256 x) internal pure returns (int128) {
        return Int128(Int(x));
    }

    /*///////////////////////////////////////////////////////////////
                               UNSIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Uint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function Uint32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function Uint64(uint256 x) internal pure returns (uint64) {
        require(x <= type(uint64).max);
        return uint64(x);
    }

    function Uint112(uint256 x) internal pure returns (uint112) {
        require(x <= type(uint112).max);
        return uint112(x);
    }

    function Uint96(uint256 x) internal pure returns (uint96) {
        require(x <= type(uint96).max);
        return uint96(x);
    }

    function Uint128(uint256 x) internal pure returns (uint128) {
        require(x <= type(uint128).max);
        return uint128(x);
    }

    function Uint192(uint256 x) internal pure returns (uint192) {
        require(x <= type(uint192).max);
        return uint192(x);
    }

    function isAApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return mulDown(b, ONE - eps) <= a && a <= mulDown(b, ONE + eps);
    }

    function isAGreaterApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a >= b && a <= mulDown(b, ONE + eps);
    }

    function isASmallerApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a <= b && a >= mulDown(b, ONE - eps);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 * @dev Version bumped to solidity 0.8.13 by BowTiedPickle
 */
pragma solidity ^0.8.13;

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../vaultus/Vaultus_Common_Roles.sol";
import "../../external/aave_interfaces/IPool.sol";

/**
 * @title   Vaultus Aave Lending Base
 * @notice  Allows lending and borrowing via the Aave Pool Contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Aave_Lending_Base is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice Aave lending pool address
    IPool public immutable aave_pool;

    /// @notice Maximum borrow allowed as mantissa fraction of Aave max LTV (100% = 1e18)
    uint256 public constant MAX_LTV_FACTOR = 0.8e18;
    /// @dev Mantissa factor
    uint256 internal constant MANTISSA_FACTOR = 1e18;
    /// @dev Basis factor for Aave LTV conversion (100% = 1e4)
    uint256 internal constant BASIS_FACTOR = 1e4;

    /**
     * @notice Sets the address of the Aave lending pool
     * @param _aave_pool Aave lending pool address
     */
    constructor(address _aave_pool) {
        require(_aave_pool != address(0), "Aave_Lending_Base: Zero address");
        aave_pool = IPool(_aave_pool);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Supplies the given amount of asset into the Aave lending pool
     * @param   asset           Address of asset to supply
     * @param   amount          Amount of asset to supply
     * @param   onBehalfOf      Recipient of supply position
     * @param   referralCode    Aave referral code
     */
    function aave_supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_aave_supply(asset, amount, onBehalfOf, referralCode);

        aave_pool.supply(asset, amount, onBehalfOf, referralCode);
    }

    /**
     * @notice  Withdraws the given amount of asset from the Aave lending pool
     * @param   asset   Address of asset to withdraw
     * @param   amount  Amount of asset to withdraw
     * @param   to      Recipient of withdraw
     */
    function aave_withdraw(address asset, uint256 amount, address to) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_aave_withdraw(asset, amount, to);

        aave_pool.withdraw(asset, amount, to);
    }

    /**
     * @notice  Borrows the given amount of asset from the Aave lending pool
     * @dev     The borrow amount must not cause the total debt to exceed a fraction of Aave's allowable max LTV
     * @param   asset               Address of asset to borrow
     * @param   amount              Amount of asset to borrow
     * @param   interestRateMode    Interest rate mode
     * @param   referralCode        Aave referral code
     * @param   onBehalfOf          Recipient of borrow
     */
    function aave_borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_aave_borrow(asset, amount, interestRateMode, referralCode, onBehalfOf);

        aave_pool.borrow(asset, amount, interestRateMode, referralCode, onBehalfOf);

        (uint256 totalCollateralBase, uint256 totalDebtBase, , , uint256 ltv, ) = aave_pool.getUserAccountData(onBehalfOf);
        uint256 maxDebtBase = (totalCollateralBase * ltv * MAX_LTV_FACTOR) / (BASIS_FACTOR * MANTISSA_FACTOR);
        require(totalDebtBase <= maxDebtBase, "Aave_Lending_Base: Borrow amount exceeds max LTV"); // solhint-disable-line reason-string
    }

    /**
     * @notice  Repays the given amount of asset to the Aave lending pool
     * @param   asset               Address of asset to repay
     * @param   amount              Amount of asset to repay
     * @param   interestRateMode    Interest rate mode
     * @param   onBehalfOf          Repayment recipient
     */
    function aave_repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_aave_repay(asset, amount, interestRateMode, onBehalfOf);

        aave_pool.repay(asset, amount, interestRateMode, onBehalfOf);
    }

    /**
     * @notice  Swaps the borrow rate mode for the given asset
     * @param   asset               Address of asset to swap borrow rate mode
     * @param   interestRateMode    Interest rate mode
     */
    function aave_swapBorrowRateMode(address asset, uint256 interestRateMode) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_aave_swapBorrowRateMode(asset, interestRateMode);

        aave_pool.swapBorrowRateMode(asset, interestRateMode);
    }

    /**
     * @notice  Sets the user's eMode
     * @param   categoryId  Category id
     */
    function aave_setUserEMode(uint8 categoryId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        aave_pool.setUserEMode(categoryId);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for aave_supply
     * @param   asset           Address of asset to supply
     * @param   amount          Amount of asset to supply
     * @param   onBehalfOf      Recipient of supply position
     * @param   referralCode    Aave referral code
     */
    function inputGuard_aave_supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) internal virtual {}

    /**
     * @notice  Validates inputs for aave_withdraw
     * @param   asset   Address of asset to withdraw
     * @param   amount  Amount of asset to withdraw
     * @param   to      Recipient of withdraw
     */
    function inputGuard_aave_withdraw(address asset, uint256 amount, address to) internal virtual {}

    /**
     * @notice  Validates inputs for aave_borrow
     * @param   asset               Address of asset to borrow
     * @param   amount              Amount of asset to borrow
     * @param   interestRateMode    Interest rate mode
     * @param   referralCode        Aave referral code
     * @param   to                  Recipient of borrow
     */
    function inputGuard_aave_borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address to
    ) internal virtual {}

    /**
     * @notice  Validates inputs for aave_repay
     * @param   asset               Address of asset to repay
     * @param   amount              Amount of asset to repay
     * @param   interestRateMode    Interest rate mode
     * @param   to                  Repayment recipient
     */
    function inputGuard_aave_repay(address asset, uint256 amount, uint256 interestRateMode, address to) internal virtual {}

    /**
     * @notice  Validates inputs for aave_swapBorrowRateMode
     * @param   asset               Address of asset to swap interest rate modes
     * @param   interestRateMode    Interest rate mode
     */
    function inputGuard_aave_swapBorrowRateMode(address asset, uint256 interestRateMode) internal virtual {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IAave_Lending_Module.sol";

/**
 * @title   Vaultus Aave Lending Cutter
 * @notice  Cutter to enable diamonds contract to call Aave lending and borrowing functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Aave_Lending_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IAave_Lending_Module functions
     * @param   _facet  Aave_Lending_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Aave_Lending_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](6);

        selectors[selectorIndex++] = IAave_Lending_Module.aave_supply.selector;
        selectors[selectorIndex++] = IAave_Lending_Module.aave_withdraw.selector;
        selectors[selectorIndex++] = IAave_Lending_Module.aave_borrow.selector;
        selectors[selectorIndex++] = IAave_Lending_Module.aave_repay.selector;
        selectors[selectorIndex++] = IAave_Lending_Module.aave_swapBorrowRateMode.selector;
        selectors[selectorIndex++] = IAave_Lending_Module.aave_setUserEMode.selector;

        _setSupportsInterface(type(IAave_Lending_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Aave_Lending_Base.sol";
import "../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus Aave Lending Module
 * @notice  Validates inputs from Aave Lending Base functions
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Aave_Lending_Module is Aave_Lending_Base, Vaultus_Trader_Storage {
    /**
     * @notice  Sets the address of the Aave lending pool
     * @param   _aave_pool    Aave lending pool address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _aave_pool) Aave_Lending_Base(_aave_pool) {}

    // (address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
    /// @inheritdoc Aave_Lending_Base
    function inputGuard_aave_supply(address asset, uint256, address onBehalfOf, uint16) internal view override {
        validateToken(asset);
        require(onBehalfOf == address(this), "GuardError: Invalid recipient");
    }

    // (address asset, uint256 amount, address to)
    /// @inheritdoc Aave_Lending_Base
    function inputGuard_aave_withdraw(address asset, uint256, address to) internal view override {
        validateToken(asset);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    /// @inheritdoc Aave_Lending_Base
    function inputGuard_aave_borrow(
        address asset,
        uint256, // amount
        uint256, // interestRateMode
        uint16, // referralCode
        address to
    ) internal view override {
        validateToken(asset);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    // (address asset, uint256 amount, uint256 interestRateMode, address to)
    /// @inheritdoc Aave_Lending_Base
    function inputGuard_aave_repay(address asset, uint256, uint256, address to) internal view override {
        validateToken(asset);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    // (address asset, uint256 interestRateMode)
    /// @inheritdoc Aave_Lending_Base
    function inputGuard_aave_swapBorrowRateMode(address asset, uint256) internal view override {
        validateToken(asset);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../external/aave_interfaces/IPool.sol";

/**
 * @title   Vaultus Aave Lending Module Interface
 * @notice  Allows lending and borrowing via the Aave Pool Contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IAave_Lending_Module {
    // ---------- Functions ----------

    function aave_supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function aave_withdraw(address asset, uint256 amount, address to) external;

    function aave_borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address to) external;

    function aave_repay(address asset, uint256 amount, uint256 interestRateMode, address to) external;

    function aave_swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    function aave_setUserEMode(uint8 categoryId) external;

    // ---------- Getters ----------

    function aave_pool() external view returns (IPool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/ICamelotRouter.sol";

/**
 * @title   Vaultus Camelot LP Base
 * @notice  Allows adding and removing liquidity via the CamelotRouter contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_LP_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage {
    // solhint-disable var-name-mixedcase
    using SafeERC20 for IERC20;

    /// @notice Camelot router address
    address public immutable camelot_router;
    /// @notice Weth address
    address public immutable weth;

    /**
     * @notice Sets the address of the Camelot router and WETH token
     * @param _camelot_router   Camelot router address
     * @param _weth             WETH token address
     */
    constructor(address _camelot_router, address _weth) {
        // solhint-disable-next-line reason-string
        require(_camelot_router != address(0) && _weth != address(0), "Camelot_Common_Storage: Zero address");
        camelot_router = _camelot_router;
        weth = _weth;
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Adds liquidity via the Camelot router
     * @param   tokenA          1st token address
     * @param   tokenB          2nd token address
     * @param   amountADesired  Desired amount of tokenA
     * @param   amountBDesired  Desired amount of tokenB
     * @param   amountAMin      Minimum amout of tokenA to receive
     * @param   amountBMin      Minimum amout of tokenB to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function camelot_addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);

        ICamelotRouter(camelot_router).addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @notice  Adds liquidity via the Camelot router using native token
     * @param   valueIn             Msg.value to send with tx
     * @param   token               Token address
     * @param   amountTokenDesired  Desired amount of token
     * @param   amountTokenMin      Minimum amout of token to receive
     * @param   amountETHMin        Minimum amout of ETH to receive
     * @param   to                  Recipient of liquidity position
     * @param   deadline            Deadline for tx
     */
    function camelot_addLiquidityETH(
        uint valueIn,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_addLiquidityETH(valueIn, token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);

        ICamelotRouter(camelot_router).addLiquidityETH{ value: valueIn }(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    /**
     * @notice  Removes liquidity via the Camelot router
     * @param   tokenA          1st token address
     * @param   tokenB          2nd token address
     * @param   liquidity       Amount of liquidity to remove
     * @param   amountAMin      Minimum amout of tokenA to receive
     * @param   amountBMin      Minimum amout of tokenB to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function camelot_removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

        address pair = ICamelotRouter(camelot_router).getPair(tokenA, tokenB);
        IERC20(pair).approve(camelot_router, liquidity);

        ICamelotRouter(camelot_router).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @notice  Removes liquidity via the Camelot router
     * @param   token           Token address
     * @param   liquidity       Amount of liquidity to remove
     * @param   amountTokenMin  Minimum amout of token to receive
     * @param   amountETHMin    Minimum amout of ETH to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function camelot_removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);

        address pair = ICamelotRouter(camelot_router).getPair(token, weth);
        IERC20(pair).approve(camelot_router, liquidity);

        ICamelotRouter(camelot_router).removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for camelot_addLiquidity
     * @param   tokenA          1st token address
     * @param   tokenB          2nd token address
     * @param   amountADesired  Desired amount of tokenA
     * @param   amountBDesired  Desired amount of tokenB
     * @param   amountAMin      Minimum amout of tokenA to receive
     * @param   amountBMin      Minimum amout of tokenB to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function inputGuard_camelot_addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_addLiquidityETH
     * @param   valueIn             Msg.value to send with tx
     * @param   token               Token address
     * @param   amountTokenDesired  Desired amount of token
     * @param   amountTokenMin      Minimum amout of token to receive
     * @param   amountETHMin        Minimum amout of ETH to receive
     * @param   to                  Recipient of liquidity position
     * @param   deadline            Deadline for tx
     */
    function inputGuard_camelot_addLiquidityETH(
        uint valueIn,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_removeLiquidity
     * @param   tokenA          1st token address
     * @param   tokenB          2nd token address
     * @param   liquidity       Amount of liquidity to remove
     * @param   amountAMin      Minimum amout of tokenA to receive
     * @param   amountBMin      Minimum amout of tokenB to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function inputGuard_camelot_removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_removeLiquidityETH
     * @param   token           Token address
     * @param   liquidity       Amount of liquidity to remove
     * @param   amountTokenMin  Minimum amout of token to receive
     * @param   amountETHMin    Minimum amout of ETH to receive
     * @param   to              Recipient of liquidity position
     * @param   deadline        Deadline for tx
     */
    function inputGuard_camelot_removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_LP_Module.sol";

/**
 * @title   Vaultus Camelot LP Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot LP functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_LP_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_LP_Module functions
     * @param   _facet  Camelot_LP_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_LP_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](4);

        selectors[selectorIndex++] = ICamelot_LP_Module.camelot_addLiquidity.selector;
        selectors[selectorIndex++] = ICamelot_LP_Module.camelot_addLiquidityETH.selector;
        selectors[selectorIndex++] = ICamelot_LP_Module.camelot_removeLiquidity.selector;
        selectors[selectorIndex++] = ICamelot_LP_Module.camelot_removeLiquidityETH.selector;

        _setSupportsInterface(type(ICamelot_LP_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Camelot_LP_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus Camelot LP Module
 * @notice  Allows adding and removing liquidity via the Camelot Router contract
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_LP_Module is Camelot_LP_Base, Vaultus_Trader_Storage {
    /**
     * @notice Sets the address of the Camelot router and Weth token
     * @param _camelot_router   Camelot router address
     * @param _weth             WETH token address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _camelot_router, address _weth) Camelot_LP_Base(_camelot_router, _weth) {}

    // ---------- Input Guards ----------

    /// @inheritdoc Camelot_LP_Base
    function inputGuard_camelot_addLiquidity(
        address tokenA,
        address tokenB,
        uint, // amountADesired
        uint, // amountBDesired
        uint, // amountAMin
        uint, // amountBMin
        address to,
        uint // deadline
    ) internal view override {
        validateToken(tokenA);
        validateToken(tokenB);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    /// @inheritdoc Camelot_LP_Base
    function inputGuard_camelot_addLiquidityETH(
        uint, // valueIn
        address token,
        uint, // amountTokenDesired
        uint, // amountTokenMin
        uint, // amountETHMin
        address to,
        uint // deadline
    ) internal view override {
        validateToken(token);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    /// @inheritdoc Camelot_LP_Base
    function inputGuard_camelot_removeLiquidity(
        address tokenA,
        address tokenB,
        uint, // liquidity
        uint, // amountAMin
        uint, // amountBMin
        address to,
        uint // deadline
    ) internal view override {
        validateToken(tokenA);
        validateToken(tokenB);
        require(to == address(this), "GuardError: Invalid recipient");
    }

    /// @inheritdoc Camelot_LP_Base
    function inputGuard_camelot_removeLiquidityETH(
        address token,
        uint, // liquidity
        uint, // amountTokenMin
        uint, // amountETHMin
        address to,
        uint // deadline
    ) internal view override {
        validateToken(token);
        require(to == address(this), "GuardError: Invalid recipient");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Camelot LP Module Interface
 * @notice  Allows adding and removing liquidity via the CamelotRouter contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_LP_Module {
    // ---------- Functions ----------

    function camelot_addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;

    function camelot_addLiquidityETH(
        uint valueIn,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;

    function camelot_removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;

    function camelot_removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;

    // ---------- Getters ----------
    function camelot_router() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INFTPool.sol";
import "../../../external/camelot_interfaces/INFTPoolFactory.sol";

/**
 * @title   Vaultus Camelot NFTPool Base
 * @notice  Allows integration with Camelot NFT Pools
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the pool address is valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_NFTPool_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage, IERC721Receiver {
    using SafeERC20 for IERC20;

    // ---------- Functions ----------

    /**
     * @notice  Creates a position in a Camelot NFT pool
     * @param   _poolAddress    NFT pool address
     * @param   _amount         Amount of asset to add to position
     * @param   _lockDuration   Lock duration for the position
     */
    function camelot_nftpool_createPosition(
        address _poolAddress,
        uint256 _amount,
        uint256 _lockDuration
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_createPosition(_poolAddress, _amount, _lockDuration);

        (address pair, , , , , , , ) = INFTPool(_poolAddress).getPoolInfo();
        IERC20(pair).approve(_poolAddress, _amount);

        INFTPool(_poolAddress).createPosition(_amount, _lockDuration);
    }

    /**
     * @notice  Adds to a position in a Camelot NFT pool
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _amountToAdd    Amount to add to position
     */
    function camelot_nftpool_addToPosition(
        address _poolAddress,
        uint256 _tokenId,
        uint256 _amountToAdd
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_addToPosition(_poolAddress, _tokenId, _amountToAdd);

        (address pair, , , , , , , ) = INFTPool(_poolAddress).getPoolInfo();
        IERC20(pair).approve(_poolAddress, _amountToAdd);

        INFTPool(_poolAddress).addToPosition(_tokenId, _amountToAdd);
    }

    /**
     * @notice  Harvests rewards from an NFT pool position
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     */
    function camelot_nftpool_harvestPosition(address _poolAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_harvestPosition(_poolAddress, _tokenId);

        INFTPool(_poolAddress).harvestPosition(_tokenId);
    }

    /**
     * @notice  Withdraws from an NFT pool position
     * @param   _poolAddress        NFT pool address
     * @param   _tokenId            Token id of position
     * @param   _amountToWithdraw   Amount to withdraw
     */
    function camelot_nftpool_withdrawFromPosition(
        address _poolAddress,
        uint256 _tokenId,
        uint256 _amountToWithdraw
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_withdrawFromPosition(_poolAddress, _tokenId, _amountToWithdraw);

        INFTPool(_poolAddress).withdrawFromPosition(_tokenId, _amountToWithdraw);
    }

    /**
     * @notice  Renews a current lock on an NFT pool position
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     */
    function camelot_nftpool_renewLockPosition(address _poolAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_renewLockPosition(_poolAddress, _tokenId);

        INFTPool(_poolAddress).renewLockPosition(_tokenId);
    }

    /**
     * @notice  Locks an NFT pool position
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _lockDuration   Duration to lock position
     */
    function camelot_nftpool_lockPosition(
        address _poolAddress,
        uint256 _tokenId,
        uint256 _lockDuration
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_lockPosition(_poolAddress, _tokenId, _lockDuration);

        INFTPool(_poolAddress).lockPosition(_tokenId, _lockDuration);
    }

    /**
     * @notice  Splits an NFT pool position into two positions
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _splitAmount    Amount to split into a new position
     */
    function camelot_nftpool_splitPosition(
        address _poolAddress,
        uint256 _tokenId,
        uint256 _splitAmount
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_splitPosition(_poolAddress, _tokenId, _splitAmount);

        INFTPool(_poolAddress).splitPosition(_tokenId, _splitAmount);
    }

    /**
     * @notice  Merges two NFT pool positions
     * @param   _poolAddress    NFT pool address
     * @param   _tokenIds       NFT pool token ids
     * @param   _lockDuration   Lock duration
     */
    function camelot_nftpool_mergePositions(
        address _poolAddress,
        uint256[] calldata _tokenIds,
        uint256 _lockDuration
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_mergePositions(_poolAddress, _tokenIds, _lockDuration);

        INFTPool(_poolAddress).mergePositions(_tokenIds, _lockDuration);
    }

    /**
     * @notice  Emergency withdraws from NFT pool
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        NFT pool token id
     */
    function camelot_nftpool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nftpool_emergencyWithdraw(_poolAddress, _tokenId);

        INFTPool(_poolAddress).emergencyWithdraw(_tokenId);
    }

    // ---------- Callbacks ----------

    /**
     * @notice Returns 'IERC721.onERC721Received.selector'
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Returns true to represent a valid NFT harvester
     */
    function onNFTHarvest(
        address, // operator
        address, // to
        uint256, // tokenId
        uint256, // grailAmount
        uint256 // xGrailAmount
    ) external pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns true to represent a valid NFT position handler
     */
    // (address operator, uint256 tokenId, uint256 lpAmount)
    function onNFTAddToPosition(address, uint256, uint256) external pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns true to represent a valid NFT position handler
     */
    // (address operator, uint256 tokenId, uint256 lpAmount)
    function onNFTWithdraw(address, uint256, uint256) external pure returns (bool) {
        return true;
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for camelot_nftpool_createPosition
     * @param   _poolAddress    NFT pool address
     * @param   _amount         Amount of asset to add to position
     * @param   _lockDuration   Lock duration for the position
     */
    function inputGuard_camelot_nftpool_createPosition(address _poolAddress, uint256 _amount, uint256 _lockDuration) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_addToPosition
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _amountToAdd    Amount to add to position
     */
    function inputGuard_camelot_nftpool_addToPosition(address _poolAddress, uint256 _tokenId, uint256 _amountToAdd) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_harvestPosition
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     */
    function inputGuard_camelot_nftpool_harvestPosition(address _poolAddress, uint256 _tokenId) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_withdrawFromPosition
     * @param   _poolAddress        NFT pool address
     * @param   _tokenId            Token id of position
     * @param   _amountToWithdraw   Amount to withdraw
     */
    function inputGuard_camelot_nftpool_withdrawFromPosition(
        address _poolAddress,
        uint256 _tokenId,
        uint256 _amountToWithdraw
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_renewLockPosition
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     */
    function inputGuard_camelot_nftpool_renewLockPosition(address _poolAddress, uint256 _tokenId) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_lockPosition
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _lockDuration   Duration to lock position
     */
    function inputGuard_camelot_nftpool_lockPosition(address _poolAddress, uint256 _tokenId, uint256 _lockDuration) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_splitPosition
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        Token id of position
     * @param   _splitAmount    Amount to split into a new position
     */
    function inputGuard_camelot_nftpool_splitPosition(address _poolAddress, uint256 _tokenId, uint256 _splitAmount) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_mergePositions
     * @param   _poolAddress    NFT pool address
     * @param   _tokenIds       NFT pool token ids
     * @param   _lockDuration   Lock duration
     */
    function inputGuard_camelot_nftpool_mergePositions(
        address _poolAddress,
        uint256[] calldata _tokenIds,
        uint256 _lockDuration
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nftpool_emergencyWithdraw
     * @param   _poolAddress    NFT pool address
     * @param   _tokenId        NFT pool token id
     */
    function inputGuard_camelot_nftpool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_NFTPool_Module.sol";

/**
 * @title   Vaultus Camelot NFTPool Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot nft pool functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_NFTPool_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_NFTPool_Module functions
     * @param   _facet  Camelot_NFTPool_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_NFTPool_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](13);

        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_createPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_addToPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_harvestPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_withdrawFromPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_renewLockPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_lockPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_splitPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_mergePositions.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.camelot_nftpool_emergencyWithdraw.selector;

        selectors[selectorIndex++] = ICamelot_NFTPool_Module.onERC721Received.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.onNFTHarvest.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.onNFTAddToPosition.selector;
        selectors[selectorIndex++] = ICamelot_NFTPool_Module.onNFTWithdraw.selector;

        _setSupportsInterface(type(ICamelot_NFTPool_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Camelot_NFTPool_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";
import "../../../external/camelot_interfaces/INFTPool.sol";

/**
 * @title   Vaultus Camelot NFTPool Module
 * @notice  Allows integration with Camelot NFT Pools
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_NFTPool_Module is Camelot_NFTPool_Base, Vaultus_Trader_Storage {
    // ---------- Input Guards ----------

    /// @inheritdoc Camelot_NFTPool_Base
    function inputGuard_camelot_nftpool_createPosition(
        address _poolAddress,
        uint256, //_amount
        uint256 _lockDuration
    ) internal view override {
        validateNFTPool(_poolAddress);
        Epoch memory currentInfo = getTraderV0Storage().vault.getCurrentEpochInfo();
        // solhint-disable-next-line reason-string
        require(block.timestamp + _lockDuration < currentInfo.epochEnd, "InputGuard: Invalid lock duration");
    }

    /// @inheritdoc Camelot_NFTPool_Base
    // (address _poolAddress, uint256 _tokenId, uint256 _amountToAdd)
    function inputGuard_camelot_nftpool_addToPosition(address _poolAddress, uint256, uint256) internal view override {
        validateNFTPool(_poolAddress);
    }

    /// @inheritdoc Camelot_NFTPool_Base
    // (address _poolAddress, uint256 _tokenId)
    function inputGuard_camelot_nftpool_harvestPosition(address _poolAddress, uint256) internal view override {
        validateNFTPool(_poolAddress);
    }

    /// @inheritdoc Camelot_NFTPool_Base
    function inputGuard_camelot_nftpool_withdrawFromPosition(
        address _poolAddress,
        uint256, // _tokenId
        uint256 // _amountToWithdraw
    ) internal view override {
        validateNFTPool(_poolAddress);
    }

    /// @inheritdoc Camelot_NFTPool_Base
    function inputGuard_camelot_nftpool_renewLockPosition(address _poolAddress, uint256 _tokenId) internal view override {
        validateNFTPool(_poolAddress);
        Epoch memory currentInfo = getTraderV0Storage().vault.getCurrentEpochInfo();
        (, , , uint256 _lockDuration, , , , ) = INFTPool(_poolAddress).getStakingPosition(_tokenId);
        // solhint-disable-next-line reason-string
        require(block.timestamp + _lockDuration < currentInfo.epochEnd, "InputGuard: Invalid lock duration");
    }

    /// @inheritdoc Camelot_NFTPool_Base
    // (address _poolAddress, uint256 _tokenId, uint256 _lockDuration)
    function inputGuard_camelot_nftpool_lockPosition(address _poolAddress, uint256, uint256 _lockDuration) internal view override {
        validateNFTPool(_poolAddress);
        Epoch memory currentInfo = getTraderV0Storage().vault.getCurrentEpochInfo();
        // solhint-disable-next-line reason-string
        require(block.timestamp + _lockDuration < currentInfo.epochEnd, "InputGuard: Invalid lock duration");
    }

    /// @inheritdoc Camelot_NFTPool_Base
    // (address _poolAddress, uint256 _tokenId, uint256 _splitAmount)
    function inputGuard_camelot_nftpool_splitPosition(address _poolAddress, uint256, uint256) internal view override {
        validateNFTPool(_poolAddress);
    }

    /// @inheritdoc Camelot_NFTPool_Base
    function inputGuard_camelot_nftpool_mergePositions(
        address _poolAddress,
        uint256[] calldata, //_tokenIds
        uint256 _lockDuration
    ) internal view override {
        validateNFTPool(_poolAddress);
        Epoch memory currentInfo = getTraderV0Storage().vault.getCurrentEpochInfo();
        // solhint-disable-next-line reason-string
        require(block.timestamp + _lockDuration < currentInfo.epochEnd, "InputGuard: Invalid lock duration");
    }

    /// @inheritdoc Camelot_NFTPool_Base
    // (address _poolAddress, uint256 _tokenId)
    function inputGuard_camelot_nftpool_emergencyWithdraw(address _poolAddress, uint256) internal view override {
        validateNFTPool(_poolAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Camelot NFTPool Module Interface
 * @notice  Allows integration with Camelot NFT Pools
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_NFTPool_Module {
    // ---------- Functions ----------

    function camelot_nftpool_createPosition(address _poolAddress, uint256 _amount, uint256 _lockDuration) external;

    function camelot_nftpool_addToPosition(address _poolAddress, uint256 _tokenId, uint256 _amountToAdd) external;

    function camelot_nftpool_harvestPosition(address _poolAddress, uint256 _tokenId) external;

    function camelot_nftpool_withdrawFromPosition(address _poolAddress, uint256 _tokenId, uint256 _amountToWithdraw) external;

    function camelot_nftpool_renewLockPosition(address _poolAddress, uint256 _tokenId) external;

    function camelot_nftpool_lockPosition(address _poolAddress, uint256 _tokenId, uint256 _lockDuration) external;

    function camelot_nftpool_splitPosition(address _poolAddress, uint256 _tokenId, uint256 _splitAmount) external;

    function camelot_nftpool_mergePositions(address _poolAddress, uint256[] calldata _tokenIds, uint256 _lockDuration) external;

    function camelot_nftpool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external;

    // ---------- Callbacks ----------

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);

    function onNFTHarvest(
        address operator,
        address to,
        uint256 tokenId,
        uint256 grailAmount,
        uint256 xGrailAmount
    ) external pure returns (bool);

    function onNFTAddToPosition(address operator, uint256 tokenId, uint256 lpAmount) external pure returns (bool);

    function onNFTWithdraw(address operator, uint256 tokenId, uint256 lpAmount) external pure returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INitroPool.sol";

/**
 * @title   Vaultus Camelot NitroPool Base
 * @notice  Allows integration with Camelot Nitro Pools
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the pool address is acceptable
 *              2. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_NitroPool_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage {
    // ---------- Functions ----------

    /**
     * @notice  Transfers an NFT pool token id to a Camelot nitro pool
     * @param   _nitroPoolAddress   Address of Camelot nitro pool
     * @param   _nftPoolAddress     Address of Camelot NFT pool
     * @param   _tokenId            Token id to transfer
     */
    function camelot_nitropool_transfer(
        address _nitroPoolAddress,
        address _nftPoolAddress,
        uint256 _tokenId
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nitropool_transfer(_nitroPoolAddress, _nftPoolAddress, _tokenId);

        IERC721(_nftPoolAddress).safeTransferFrom(address(this), _nitroPoolAddress, _tokenId);
    }

    /**
     * @notice  Withdraws an NFT pool token id from a Camelot nitro pool
     * @param   _poolAddress    Address of Camelot nitro pool
     * @param   _tokenId        Token id to withdraw
     */
    function camelot_nitropool_withdraw(address _poolAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nitropool_withdraw(_poolAddress, _tokenId);

        INitroPool(_poolAddress).withdraw(_tokenId);
    }

    /**
     * @notice  Emergency withdraws an NFT pool token id from a Camelot nitro pool
     * @param   _poolAddress    Address of Camelot nitro pool
     * @param   _tokenId        Token id to withdraw
     */
    function camelot_nitropool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nitropool_emergencyWithdraw(_poolAddress, _tokenId);

        INitroPool(_poolAddress).emergencyWithdraw(_tokenId);
    }

    /**
     * @notice  Harvests rewards from a Camelot nitro pool
     * @param   _poolAddress    Address of Camelot nitro pool
     */
    function camelot_nitropool_harvest(address _poolAddress) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_nitropool_harvest(_poolAddress);

        INitroPool(_poolAddress).harvest();
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for camelot_nitropool_transfer
     * @param   _nitroPoolAddress   Address of Camelot nitro pool
     * @param   _nftPoolAddress     Address of Camelot NFT pool
     * @param   _tokenId            Token id to transfer
     */
    function inputGuard_camelot_nitropool_transfer(address _nitroPoolAddress, address _nftPoolAddress, uint256 _tokenId) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nitropool_withdraw
     * @param   _poolAddress    Address of Camelot nitro pool
     * @param   _tokenId        Token id to withdraw
     */
    function inputGuard_camelot_nitropool_withdraw(address _poolAddress, uint256 _tokenId) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nitropool_emergencyWithdraw
     * @param   _poolAddress    Address of Camelot nitro pool
     * @param   _tokenId        Token id to withdraw
     */
    function inputGuard_camelot_nitropool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_nitropool_harvest
     * @param   _poolAddress    Address of Camelot nitro pool
     */
    function inputGuard_camelot_nitropool_harvest(address _poolAddress) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_NitroPool_Module.sol";

/**
 * @title   Vaultus Camelot NitroPool Cutter
 * @notice  Cutter to enable diamonds contract to interact with Camelot nitro pools
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_NitroPool_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_NitroPool_Module functions
     * @param   _facet  Camelot_NitroPool_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_NitroPool_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](4);

        selectors[selectorIndex++] = ICamelot_NitroPool_Module.camelot_nitropool_transfer.selector;
        selectors[selectorIndex++] = ICamelot_NitroPool_Module.camelot_nitropool_withdraw.selector;
        selectors[selectorIndex++] = ICamelot_NitroPool_Module.camelot_nitropool_emergencyWithdraw.selector;
        selectors[selectorIndex++] = ICamelot_NitroPool_Module.camelot_nitropool_harvest.selector;

        _setSupportsInterface(type(ICamelot_NitroPool_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Camelot_NitroPool_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";
import "../../../external/camelot_interfaces/INitroPoolFactory.sol";

/**
 * @title   Vaultus Camelot NitroPool Module
 * @notice  Allows integration with Camelot Nitro Pools
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_NitroPool_Module is Camelot_NitroPool_Base {
    // ---------- Input Guards ----------

    /// @inheritdoc Camelot_NitroPool_Base
    function inputGuard_camelot_nitropool_transfer(
        address _nitroPoolAddress,
        address _nftPoolAddress,
        uint256 // _tokenId
    ) internal view override {
        validateNFTPool(_nftPoolAddress);
        validateNitroPool(_nitroPoolAddress);
    }

    /// @inheritdoc Camelot_NitroPool_Base
    // (address _nitroPoolAddress, uint256 _tokenId)
    function inputGuard_camelot_nitropool_withdraw(address _nitroPoolAddress, uint256) internal view override {
        validateNitroPool(_nitroPoolAddress);
    }

    /// @inheritdoc Camelot_NitroPool_Base
    // (address _nitroPoolAddress, uint256 _tokenId)
    function inputGuard_camelot_nitropool_emergencyWithdraw(address _nitroPoolAddress, uint256) internal view override {
        validateNitroPool(_nitroPoolAddress);
    }

    /// @inheritdoc Camelot_NitroPool_Base
    function inputGuard_camelot_nitropool_harvest(address _nitroPoolAddress) internal view override {
        validateNitroPool(_nitroPoolAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Camelot NitroPool Module Interface
 * @notice  Allows integration with Camelot Nitro Pools
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_NitroPool_Module {
    // ---------- Functions ----------

    function camelot_nitropool_transfer(address _nitroPoolAddress, address _nftPoolAddress, uint256 _tokenId) external;

    function camelot_nitropool_withdraw(address _poolAddress, uint256 _tokenId) external;

    function camelot_nitropool_emergencyWithdraw(address _poolAddress, uint256 _tokenId) external;

    function camelot_nitropool_harvest(address _poolAddress) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../vaultus/Vaultus_Common_Roles.sol";

/**
 * @title   Vaultus Camelot Common Storage
 * @notice  Protocol addresses and constants used by all Camelot modules
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_Common_Storage is Vaultus_Common_Roles {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct CamelotCommonStorage {
        /// @notice Set of allowed Camelot NFT pools
        EnumerableSet.AddressSet allowedNFTPools;
        /// @notice Set of allowed Camelot nitro pools
        EnumerableSet.AddressSet allowedNitroPools;
        /// @notice Set of allowed Odos executors
        EnumerableSet.AddressSet allowedExecutors;
        /// @notice Set of allowed Camelot V3 pools to be input receivers
        EnumerableSet.AddressSet allowedReceivers;
    }

    /// @dev    EIP-2535 Diamond Storage struct location
    bytes32 internal constant CAMELOT_POSITION = bytes32(uint256(keccak256("Camelot_Common.storage")) - 1);

    function getCamelotCommonStorage() internal pure returns (CamelotCommonStorage storage storageStruct) {
        bytes32 position = CAMELOT_POSITION;
        // solhint-disable no-inline-assembly
        assembly {
            storageStruct.slot := position
        }
    }

    // --------- Internal Functions ---------

    /**
     * @notice  Validates a Camelot NFT pool
     * @param   _pool   Pool address
     */
    function validateNFTPool(address _pool) internal view {
        require(getCamelotCommonStorage().allowedNFTPools.contains(_pool), "Invalid NFT Pool");
    }

    /**
     * @notice  Validates a Camelot nitro pool
     * @param   _pool   Pool address
     */
    function validateNitroPool(address _pool) internal view {
        require(getCamelotCommonStorage().allowedNitroPools.contains(_pool), "Invalid Nitro Pool");
    }

    /**
     * @notice  Validates an Odos executor
     * @param   _executor   Executor address
     */
    function validateExecutor(address _executor) internal view {
        require(getCamelotCommonStorage().allowedExecutors.contains(_executor), "Invalid Executor");
    }

    /**
     * @notice  Validates an Odos input receiver
     * @param   _receiver   Input receiver address
     */
    function validateReceiver(address _receiver) internal view {
        require(getCamelotCommonStorage().allowedReceivers.contains(_receiver), "Invalid Receiver");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_Storage_Module.sol";

/**
 * @title   Vaultus Camelot Storage Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot storage functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_Storage_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_Storage_Module functions
     * @param   _facet  Camelot_Storage_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_Storage_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](8);

        selectors[selectorIndex++] = ICamelot_Storage_Module.manageNFTPools.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.manageNitroPools.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.manageExecutors.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.manageReceivers.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.getAllowedNFTPools.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.getAllowedNitroPools.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.getAllowedExecutors.selector;
        selectors[selectorIndex++] = ICamelot_Storage_Module.getAllowedReceivers.selector;

        _setSupportsInterface(type(ICamelot_Storage_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INFTPool.sol";
import "../../../external/camelot_interfaces/INFTPoolFactory.sol";
import "../../../external/camelot_interfaces/INitroPoolFactory.sol";

/**
 * @title   Vaultus Camelot Storage Module
 * @notice  Manage Camelot storage
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_Storage_Module is AccessControl, Camelot_Common_Storage {
    // solhint-disable var-name-mixedcase
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Camelot NFT pool factory address
    INFTPoolFactory public immutable camelot_nftpool_factory;
    /// @notice Camelot Nitro pool factory address
    INitroPoolFactory public immutable camelot_nitropool_factory;

    /**
     * @notice Sets the address of the Camelot nft pool factory
     * @param _camelot_nftpool_factory  Camelot nft pool factory address
     */
    constructor(address _camelot_nftpool_factory, address _camelot_nitropool_factory) {
        camelot_nftpool_factory = INFTPoolFactory(_camelot_nftpool_factory);
        camelot_nitropool_factory = INitroPoolFactory(_camelot_nitropool_factory);
    }

    // solhint-enable var-name-mixedcase

    /**
     * @notice Adds or removes batch of nft pools to the set of allowed nft pools
     * @param _pools    Array of pool addresses
     * @param _status   Array of statuses
     */
    function manageNFTPools(address[] calldata _pools, bool[] calldata _status) external onlyRole(EXECUTOR_ROLE) {
        // solhint-disable-next-line reason-string
        require(_pools.length == _status.length, "Camelot_Storage_Module: Length mismatch");
        for (uint256 i; i < _pools.length; ) {
            _manageNFTPool(_pools[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a pool from the set of allowed nft pools
     * @param _pool     Pool address
     * @param _status   Status
     */
    function _manageNFTPool(address _pool, bool _status) internal {
        if (_status) {
            (address lptoken, , , , , , , ) = INFTPool(_pool).getPoolInfo();
            // solhint-disable-next-line reason-string
            require(camelot_nftpool_factory.getPool(lptoken) == _pool, "Camelot_Storage_Module: Invalid pool");
            getCamelotCommonStorage().allowedNFTPools.add(_pool);
        } else {
            getCamelotCommonStorage().allowedNFTPools.remove(_pool);
        }
    }

    /**
     * @notice Adds or removes batch of nitro pools to the set of allowed nitro pools
     * @param _pools    Array of pool addresses
     * @param _status   Array of statuses
     */
    function manageNitroPools(
        address[] calldata _pools,
        bool[] calldata _status,
        uint256[] calldata _indexes
    ) external onlyRole(EXECUTOR_ROLE) {
        // solhint-disable-next-line reason-string
        uint256 poolsLen = _pools.length;
        // solhint-disable-next-line reason-string
        require(poolsLen == _status.length && poolsLen == _indexes.length, "Camelot_Storage_Module: Length mismatch");
        for (uint256 i; i < poolsLen; ) {
            _manageNitroPool(_pools[i], _status[i], _indexes[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a pool from the set of allowed nitro pools
     * @param _pool     Pool address
     * @param _status   Status
     */
    function _manageNitroPool(address _pool, bool _status, uint256 _index) internal {
        if (_status) {
            address nitroPool = camelot_nitropool_factory.getNitroPool(_index);
            // solhint-disable-next-line reason-string
            require(nitroPool == _pool, "Camelot_Storage_Module: Pool/index mismatch");
            getCamelotCommonStorage().allowedNitroPools.add(_pool);
        } else {
            getCamelotCommonStorage().allowedNitroPools.remove(_pool);
        }
    }

    /**
     * @notice Adds or removes batch of executors to the set of allowed executors
     * @param _executors    Array of executor addresses
     * @param _status       Array of statuses
     */
    function manageExecutors(address[] calldata _executors, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_executors.length == _status.length, "Camelot_Storage_Module: Length mismatch");
        for (uint256 i; i < _executors.length; ) {
            _manageExecutor(_executors[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove an executor from the set of allowed executors
     * @param _executor     Executor address
     * @param _status       Status
     */
    function _manageExecutor(address _executor, bool _status) internal {
        // solhint-disable-next-line reason-string
        require(_executor != address(0), "Camelot_Storage_Module: Zero address");
        if (_status) {
            getCamelotCommonStorage().allowedExecutors.add(_executor);
        } else {
            getCamelotCommonStorage().allowedExecutors.remove(_executor);
        }
    }

    /**
     * @notice Adds or removes batch of receivers to the set of allowed receivers
     * @param _receivers    Array of receiver addresses
     * @param _status       Array of statuses
     */
    function manageReceivers(address[] calldata _receivers, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_receivers.length == _status.length, "Camelot_Storage_Module: Length mismatch");
        for (uint256 i; i < _receivers.length; ) {
            _manageReceiver(_receivers[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a receiver from the set of allowed receivers
     * @param _receiver     Receiver address
     * @param _status       Status
     */
    function _manageReceiver(address _receiver, bool _status) internal {
        // solhint-disable-next-line reason-string
        require(_receiver != address(0), "Camelot_Storage_Module: Zero address");
        if (_status) {
            getCamelotCommonStorage().allowedReceivers.add(_receiver);
        } else {
            getCamelotCommonStorage().allowedReceivers.remove(_receiver);
        }
    }

    // --------- Views ---------

    /**
     * @notice  Returns all allowed NFT Pools
     */
    function getAllowedNFTPools() external view returns (address[] memory) {
        return getCamelotCommonStorage().allowedNFTPools.values();
    }

    /**
     * @notice  Returns all allowed Nitro Pools
     */
    function getAllowedNitroPools() external view returns (address[] memory) {
        return getCamelotCommonStorage().allowedNitroPools.values();
    }

    /**
     * @notice  Returns all allowed Executors
     */
    function getAllowedExecutors() external view returns (address[] memory) {
        return getCamelotCommonStorage().allowedExecutors.values();
    }

    /**
     * @notice  Returns all allowed Receivers
     */
    function getAllowedReceivers() external view returns (address[] memory) {
        return getCamelotCommonStorage().allowedReceivers.values();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/camelot_interfaces/INFTPoolFactory.sol";

/**
 * @title   Vaultus Camelot Storage Module Interface
 * @notice  Allows interacting with Camelot common storage
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_Storage_Module {
    // --------- External Functions ---------

    function manageNFTPools(address[] calldata _pools, bool[] calldata _status) external;

    function manageNitroPools(address[] calldata _pools, bool[] calldata _status, uint256[] calldata _indexes) external;

    function manageExecutors(address[] calldata _executors, bool[] calldata _status) external;

    function manageReceivers(address[] calldata _receivers, bool[] calldata _status) external;

    // --------- Getter Functions ---------

    function camelot_nftpool_factory() external view returns (INFTPoolFactory);

    function getAllowedNFTPools() external view returns (address[] memory);

    function getAllowedNitroPools() external view returns (address[] memory);

    function getAllowedExecutors() external view returns (address[] memory);

    function getAllowedReceivers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/ICamelotRouter.sol";

/**
 * @title   Vaultus Camelot Swap Base
 * @notice  Allows direct swapping via the CamelotRouter contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path is acceptable.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_Swap_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage {
    // solhint-disable var-name-mixedcase

    /// @notice Camelot router address
    address public immutable camelot_router;

    /**
     * @notice Sets the address of the Camelot router
     * @param _camelot_router   Camelot router address
     */
    constructor(address _camelot_router) {
        require(_camelot_router != address(0), "Camelot_Swap_Base: Zero address");
        camelot_router = _camelot_router;
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Swaps exact tokens for tokens using CamelotRouter
     * @param   amountIn        The amount of token to send
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function camelot_swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_swapExactTokensForTokens(amountIn, amountOutMin, path, to, referrer, deadline);

        ICamelotRouter(camelot_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            referrer,
            deadline
        );
    }

    /**
     * @notice  Swaps exact ETH for tokens using CamelotRouter
     * @param   valueIn         Msg.value to send with tx
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function camelot_swapExactETHForTokens(
        uint valueIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_swapExactETHForTokens(valueIn, amountOutMin, path, to, referrer, deadline);

        ICamelotRouter(camelot_router).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: valueIn }(
            amountOutMin,
            path,
            to,
            referrer,
            deadline
        );
    }

    /**
     * @notice  Swaps exact tokens for ETH using CamelotRouter
     * @param   amountIn        The amount of tokens to send
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function camelot_swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_swapExactTokensForETH(amountIn, amountOutMin, path, to, referrer, deadline);

        ICamelotRouter(camelot_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            referrer,
            deadline
        );
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for camelot_swapExactTokensForTokens
     * @param   amountIn        The amount of token to send
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function inputGuard_camelot_swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_swapExactETHForTokens
     * @param   valueIn         Msg.value to send with tx
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function inputGuard_camelot_swapExactETHForTokens(
        uint valueIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_swapExactTokensForETH
     * @param   amountIn        The amount of tokens to send
     * @param   amountOutMin    The min amount of token to receive
     * @param   path            The path of the swap
     * @param   referrer        Referrer address
     * @param   to              The address of the recipient
     * @param   deadline        The deadline of the tx
     */
    function inputGuard_camelot_swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_Swap_Module.sol";

/**
 * @title   Vaultus Camelot Swap Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot swap functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_Swap_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_Swap_Module functions
     * @param   _facet  Camelot_Swap_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_Swap_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](3);

        selectors[selectorIndex++] = ICamelot_Swap_Module.camelot_swapExactTokensForTokens.selector;
        selectors[selectorIndex++] = ICamelot_Swap_Module.camelot_swapExactETHForTokens.selector;
        selectors[selectorIndex++] = ICamelot_Swap_Module.camelot_swapExactTokensForETH.selector;

        _setSupportsInterface(type(ICamelot_Swap_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Camelot_Swap_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus Camelot Swap Module
 * @notice  Allows direct swapping via the Camelot Router contract
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_Swap_Module is Camelot_Swap_Base, Vaultus_Trader_Storage {
    /**
     * @notice Sets the address of the Camelot router
     * @param _camelot_router   Camelot router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _camelot_router) Camelot_Swap_Base(_camelot_router) {}

    // ---------- Input Guards ----------

    /// @inheritdoc Camelot_Swap_Base
    function inputGuard_camelot_swapExactTokensForTokens(
        uint, // amountIn
        uint, // amountOutMin
        address[] calldata path,
        address to,
        address referrer,
        uint // deadline
    ) internal view override {
        validateSwapPath(path);
        require(to == address(this), "GuardError: Invalid recipient");
        require(referrer == address(this), "GuardError: Invalid referrer");
    }

    /// @inheritdoc Camelot_Swap_Base
    function inputGuard_camelot_swapExactETHForTokens(
        uint, // amountIn
        uint, // amountOutMin
        address[] calldata path,
        address to,
        address referrer,
        uint // deadline
    ) internal view override {
        validateSwapPath(path);
        require(to == address(this), "GuardError: Invalid recipient");
        require(referrer == address(this), "GuardError: Invalid referrer");
    }

    /// @inheritdoc Camelot_Swap_Base
    function inputGuard_camelot_swapExactTokensForETH(
        uint, // amountIn
        uint, // amountOutMin
        address[] calldata path,
        address to,
        address referrer,
        uint // deadline
    ) internal view override {
        validateSwapPath(path);
        require(to == address(this), "GuardError: Invalid recipient");
        require(referrer == address(this), "GuardError: Invalid referrer");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Camelot Swap Module Interface
 * @notice  Allows direct swapping via the CamelotRouter contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_Swap_Module {
    // ---------- Functions ----------

    function camelot_swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function camelot_swapExactETHForTokens(
        uint valueIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function camelot_swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    // ---------- Getters ----------

    function camelot_router() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";

/**
 * @title   Vaultus Camelot V3 Base
 * @notice  Allows adding and removing liquidity via the NonfungiblePositionManager contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_V3LP_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage {
    // solhint-disable var-name-mixedcase

    /// @notice Algebra position manager address
    INonfungiblePositionManager public immutable position_manager;

    /**
     * @notice  Sets the address of the Algebra position manager
     * @param   _position_manager   Algebra position manager address
     */
    constructor(address _position_manager) {
        // solhint-disable-next-line reason-string
        require(_position_manager != address(0), "Camelot_V3_Base: Zero address");
        position_manager = INonfungiblePositionManager(_position_manager);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Mints a new CamelotV3 liquidity position via the position manager
     * @param   valueIn     Msg.value to send with tx
     * @param   params      Mint params
     */
    function camelot_v3_mint(
        uint256 valueIn,
        INonfungiblePositionManager.MintParams calldata params
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant returns (uint256 tokenId) {
        inputGuard_camelot_v3_mint(valueIn, params);
        (tokenId, , , ) = position_manager.mint{ value: valueIn }(params);
        position_manager.refundNativeToken();
    }

    /**
     * @notice  Increases liquidity in CamelotV3 liquidity position
     * @param   valueIn     Msg.value to send with tx
     * @param   params      Increase liquidity params
     */
    function camelot_v3_increaseLiquidity(
        uint256 valueIn,
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_v3_increaseLiquidity(valueIn, params);
        position_manager.increaseLiquidity{ value: valueIn }(params);
        position_manager.refundNativeToken();
    }

    /**
     * @notice  Decreases liquidity in CamelotV3 liquidity position
     * @dev     Input guard is not needed for this function
     * @param   params  Decrease liquidity params
     */
    function camelot_v3_decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata params
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        position_manager.decreaseLiquidity(params);
    }

    /**
     * @notice  Collects outstanding owed tokens from the position manager
     * @param   params  Collect params
     */
    function camelot_v3_collect(INonfungiblePositionManager.CollectParams memory params) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_v3_collect(params);
        position_manager.collect(params);
    }

    /**
     * @notice  Burns a CamelotV3 liquidity position
     * @dev     Input guard is not needed for this function
     * @param   tokenId     Token id to burn
     */
    function camelot_v3_burn(uint256 tokenId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        position_manager.burn(tokenId);
    }

    /**
     * @notice  Helper function to decrease liquidity and collect from position manager
     * @dev     Only collect input guard is used within this function
     * @param   decreaseParams  Decrease liquidity params
     * @param   collectParams   Collect params
     */
    function camelot_v3_decreaseLiquidityAndCollect(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_v3_collect(collectParams);
        position_manager.decreaseLiquidity(decreaseParams);
        position_manager.collect(collectParams);
    }

    /**
     * @notice  Helper function to decrease liquidity, collect and burn liquidity position
     * @dev     Only collect input guard is used within this function
     * @param   decreaseParams  Decrease liquidity params
     * @param   collectParams   Collect params
     * @param   tokenId         Token id to burn
     */
    function camelot_v3_decreaseLiquidityCollectAndBurn(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams,
        uint256 tokenId
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_camelot_v3_collect(collectParams);
        position_manager.decreaseLiquidity(decreaseParams);
        position_manager.collect(collectParams);
        position_manager.burn(tokenId);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for camelot_v3_mint
     * @param   valueIn     Msg.value to send with tx
     * @param   params      Mint params
     */
    function inputGuard_camelot_v3_mint(uint256 valueIn, INonfungiblePositionManager.MintParams calldata params) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_v3_increaseLiquidity
     * @param   valueIn     Msg.value to send with tx
     * @param   params      Increase liquidity params
     */
    function inputGuard_camelot_v3_increaseLiquidity(
        uint256 valueIn,
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) internal virtual {}

    /**
     * @notice  Validates inputs for camelot_v3_collect
     * @param   params  Collect params
     */
    function inputGuard_camelot_v3_collect(INonfungiblePositionManager.CollectParams memory params) internal virtual {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_V3LP_Module.sol";

/**
 * @title   Vaultus Camelot V3 Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot v3 LP functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_V3LP_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_V3LP_Module functions
     * @param   _facet  Camelot_V3LP_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_V3LP_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](7);

        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_mint.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_burn.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_collect.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_increaseLiquidity.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_decreaseLiquidity.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityAndCollect.selector;
        selectors[selectorIndex++] = ICamelot_V3LP_Module.camelot_v3_decreaseLiquidityCollectAndBurn.selector;

        _setSupportsInterface(type(ICamelot_V3LP_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Camelot_V3LP_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";

/**
 * @title   Vaultus Camelot V3 LP Module
 * @notice  Allows adding and removing liquidity via the NonfungiblePositionManager contract
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_V3LP_Module is Camelot_V3LP_Base, Vaultus_Trader_Storage {
    /**
     * @notice  Sets the address of the Algebra position manager
     * @param   _position_manager   Algebra position manager address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _position_manager) Camelot_V3LP_Base(_position_manager) {}

    // ---------- Input Guards ----------

    /// @inheritdoc Camelot_V3LP_Base
    // (uint256 valueIn, INonfungiblePositionManager.MintParams calldata params)
    function inputGuard_camelot_v3_mint(uint256, INonfungiblePositionManager.MintParams calldata params) internal view override {
        validateToken(params.token0);
        validateToken(params.token1);
        require(params.recipient == address(this), "GuardError: Invalid recipient");
    }

    /// @inheritdoc Camelot_V3LP_Base
    function inputGuard_camelot_v3_increaseLiquidity(
        uint256, // valueIn
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) internal view override {
        require(position_manager.ownerOf(params.tokenId) == address(this), "GuardError: Invalid tokenId");
    }

    /// @inheritdoc Camelot_V3LP_Base
    function inputGuard_camelot_v3_collect(INonfungiblePositionManager.CollectParams memory params) internal view override {
        require(params.recipient == address(this), "GuardError: Invalid recipient");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../storage/Camelot_Common_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";

/**
 * @title   Vaultus Camelot V3 LP Module Interface
 * @notice  Allows adding and removing liquidity via the NonfungiblePositionManager contract
 * @notice  Allows swapping via the OdosRouter contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_V3LP_Module {
    // ---------- Functions ----------

    function camelot_v3_mint(uint256 valueIn, INonfungiblePositionManager.MintParams calldata params) external returns (uint256);

    function camelot_v3_burn(uint256 tokenId) external;

    function camelot_v3_collect(INonfungiblePositionManager.CollectParams memory params) external;

    function camelot_v3_increaseLiquidity(uint256 valueIn, INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external;

    function camelot_v3_decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external;

    function camelot_v3_decreaseLiquidityAndCollect(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams
    ) external;

    function camelot_v3_decreaseLiquidityCollectAndBurn(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata decreaseParams,
        INonfungiblePositionManager.CollectParams memory collectParams,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../storage/Camelot_Common_Storage.sol";
import { ISwapRouter } from "../../../external/algebra_interfaces/ISwapRouter.sol";

/**
 * @title   Vaultus Camelot V3 Swap Base
 * @notice  Allows swapping tokens via the Camelot V3 Algebra swap router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Camelot_V3Swap_Base is AccessControl, ReentrancyGuard, Camelot_Common_Storage {
    // solhint-disable var-name-mixedcase

    /// @notice Algebra swap router address
    ISwapRouter public immutable swap_router;

    /**
     * @notice  Sets the address of the Algebra swap router
     * @param   _swap_router    Algebra swap router address
     */
    constructor(address _swap_router) {
        // solhint-disable-next-line reason-string
        require(_swap_router != address(0), "Camelot_V3Swap_Base: Zero address");
        swap_router = ISwapRouter(_swap_router);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInputSingle(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountOut) {
        inputGuard_camelot_v3Swap_exactInputSingle(params);
        amountOut = swap_router.exactInputSingle(params);
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInput(
        ISwapRouter.ExactInputParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountOut) {
        inputGuard_camelot_v3Swap_exactInput(params);
        amountOut = swap_router.exactInput(params);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function camelot_v3Swap_exactOutputSingle(
        ISwapRouter.ExactOutputSingleParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountIn) {
        inputGuard_camelot_v3Swap_exactOutputSingle(params);
        amountIn = swap_router.exactOutputSingle(params);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function camelot_v3Swap_exactOutput(
        ISwapRouter.ExactOutputParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountIn) {
        inputGuard_camelot_v3Swap_exactOutput(params);
        amountIn = swap_router.exactOutput(params);
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external onlyRole(EXECUTOR_ROLE) returns (uint256 amountOut) {
        inputGuard_camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens(params);
        amountOut = swap_router.exactInputSingleSupportingFeeOnTransferTokens(params);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    function inputGuard_camelot_v3Swap_exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) internal virtual {}

    function inputGuard_camelot_v3Swap_exactInput(ISwapRouter.ExactInputParams calldata params) internal virtual {}

    function inputGuard_camelot_v3Swap_exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params) internal virtual {}

    function inputGuard_camelot_v3Swap_exactOutput(ISwapRouter.ExactOutputParams calldata params) internal virtual {}

    function inputGuard_camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens(
        ISwapRouter.ExactInputSingleParams calldata params
    ) internal virtual {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ICamelot_V3Swap_Module.sol";

/**
 * @title   Vaultus Camelot V3 Swap Cutter
 * @notice  Cutter to enable diamonds contract to call Camelot v3 Swap functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_V3Swap_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ICamelot_V3Swap_Module functions
     * @param   _facet  Camelot_V3Swap_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Camelot_V3Swap_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](5);

        selectors[selectorIndex++] = ICamelot_V3Swap_Module.camelot_v3Swap_exactInputSingle.selector;
        selectors[selectorIndex++] = ICamelot_V3Swap_Module.camelot_v3Swap_exactInput.selector;
        selectors[selectorIndex++] = ICamelot_V3Swap_Module.camelot_v3Swap_exactOutputSingle.selector;
        selectors[selectorIndex++] = ICamelot_V3Swap_Module.camelot_v3Swap_exactOutput.selector;
        selectors[selectorIndex++] = ICamelot_V3Swap_Module.camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens.selector;

        _setSupportsInterface(type(ICamelot_V3Swap_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { ISwapRouter } from "../../../external/algebra_interfaces/ISwapRouter.sol";
import { BytesLib } from "../../../external/camelot_libraries/BytesLib.sol";

import { Vaultus_Trader_Storage } from "../../vaultus/Vaultus_Trader_Storage.sol";
import { Camelot_V3Swap_Base } from "./Camelot_V3Swap_Base.sol";

/**
 * @title   Vaultus Camelot V3 Swap Module
 * @notice  Allows swapping tokens via the Camelot V3 Algebra swap router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Camelot_V3Swap_Module is Camelot_V3Swap_Base, Vaultus_Trader_Storage {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /**
     * @notice  Sets the address of the Algebra swap router
     * @param   _swap_router    Algebra swap router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _swap_router) Camelot_V3Swap_Base(_swap_router) {}

    // ---------- Input Guards ----------

    function inputGuard_camelot_v3Swap_exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) internal view override {
        validateToken(params.tokenIn);
        validateToken(params.tokenOut);
        if (params.recipient != address(this)) revert Camelot_V3Swap__InvalidRecipient();
    }

    function inputGuard_camelot_v3Swap_exactInput(ISwapRouter.ExactInputParams calldata params) internal view override {
        validateBytesPath(params.path);
        if (params.recipient != address(this)) revert Camelot_V3Swap__InvalidRecipient();
    }

    function inputGuard_camelot_v3Swap_exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params) internal view override {
        validateToken(params.tokenIn);
        validateToken(params.tokenOut);
        if (params.recipient != address(this)) revert Camelot_V3Swap__InvalidRecipient();
    }

    function inputGuard_camelot_v3Swap_exactOutput(ISwapRouter.ExactOutputParams calldata params) internal view override {
        validateBytesPath(params.path);
        if (params.recipient != address(this)) revert Camelot_V3Swap__InvalidRecipient();
    }

    function inputGuard_camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens(
        ISwapRouter.ExactInputSingleParams calldata params
    ) internal view override {
        validateToken(params.tokenIn);
        validateToken(params.tokenOut);
        if (params.recipient != address(this)) revert Camelot_V3Swap__InvalidRecipient();
    }

    // ---------- Internal ----------
    function validateBytesPath(bytes memory path) internal view {
        uint256 size = path.length / ADDR_SIZE;
        for (uint256 i; i < size; i++) {
            validateToken(path.toAddress(i * ADDR_SIZE));
        }
    }

    // ---------- Errors ----------

    error Camelot_V3Swap__InvalidRecipient();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { ISwapRouter } from "../../../external/algebra_interfaces/ISwapRouter.sol";

/**
 * @title   Vaultus Camelot V3 Swap Base
 * @notice  Allows swapping tokens via the Camelot V3 Algebra swap router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ICamelot_V3Swap_Module {
    // ---------- Functions ----------

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInputSingle(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInput(ISwapRouter.ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function camelot_v3Swap_exactOutputSingle(
        ISwapRouter.ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function camelot_v3Swap_exactOutput(ISwapRouter.ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function camelot_v3Swap_exactInputSingleSupportingFeeOnTransferTokens(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IETHWrapper_Module.sol";

/**
 * @title   ETHWrapper Cutter
 * @notice  Cutter to enable diamonds contract to call ETH wrapping and unwrapping functions
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
contract ETHWrapper_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the diamond with IETHWrapper functions
     * @param   _facet  ETHWrapper facet address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "ETHWrapper_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](2);

        selectors[selectorIndex++] = IETHWrapper.wrapETH.selector;
        selectors[selectorIndex++] = IETHWrapper.unwrapETH.selector;

        _setSupportsInterface(type(IETHWrapper).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../../trader/external/IWETH.sol";
import "../vaultus/Vaultus_Trader_Storage.sol";
import "../vaultus/Vaultus_Common_Roles.sol";
import "./IETHWrapper_Module.sol";

/**
 * @title   ETH Wrapper Facet
 * @notice  Wraps and unwraps ETH
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer zug
 */
contract ETHWrapper_Module is IETHWrapper, AccessControl, Vaultus_Common_Roles, ReentrancyGuard {
    IWETH public immutable weth;

    constructor(address _wethAddress) {
        require(_wethAddress != address(0), "ETHWrapper: Zero Address");
        weth = IWETH(_wethAddress);
    }

    function wrapETH(uint256 amount) external onlyRole(EXECUTOR_ROLE) {
        // solhint-disable-next-line reason-string
        require(amount > 0, "Wrap amount must be greater than 0");
        weth.deposit{ value: amount }();
    }

    function unwrapETH(uint256 amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        // solhint-disable-next-line reason-string
        require(amount > 0, "Unwrap amount must be greater than 0");
        weth.withdraw(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   ETH Wrapper Interface
 * @notice  Interfaces with ETH wrapper
 * @author  Vaultus Finance
 * @custom:developer zug
 */
interface IETHWrapper {
    function wrapETH(uint256 amount) external;

    function unwrapETH(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../../vaultus/Vaultus_Common_Roles.sol";
import "../../../external/gmx_interfaces/IRewardRouterV2.sol";

/**
 * @title   Vaultus GMX GLP Base
 * @notice  Allows depositing, withdrawing, and claiming rewards in the GLP ecosystem
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the input and output tokens are acceptable.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @custom:developer    BowTiedPickle
 */
abstract contract GMX_GLP_Base is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice GMX GLP reward router address
    IRewardRouterV2 public immutable gmx_GLPRewardRouter;
    /// @notice GMX reward router address
    IRewardRouterV2 public immutable gmx_GMXRewardRouter;

    /**
     * @notice Sets the address of the GMX reward router and GMX GLP reward router
     * @param _gmx_GLPRewardRouter  GMX GLP reward router address
     * @param _gmx_GMXRewardRouter  GMX reward router address
     */
    constructor(address _gmx_GLPRewardRouter, address _gmx_GMXRewardRouter) {
        require(_gmx_GLPRewardRouter != address(0) && _gmx_GMXRewardRouter != address(0), "GMX_GLP_Base: Zero address");
        gmx_GLPRewardRouter = IRewardRouterV2(_gmx_GLPRewardRouter);
        gmx_GMXRewardRouter = IRewardRouterV2(_gmx_GMXRewardRouter);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice Mint and stakes GLP
     * @param _token    Token address to stake
     * @param _amount   Amount of token to stake
     * @param _minUsdg  Min Usdg to receive
     * @param _minGlp   Min GLP to receive
     */
    function gmx_mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant returns (uint256) {
        inputGuard_gmx_mintAndStakeGlp(_token, _amount, _minUsdg, _minGlp);

        return gmx_GLPRewardRouter.mintAndStakeGlp(_token, _amount, _minUsdg, _minGlp);
    }

    /**
     * @notice Mint and stakes GLP with native token
     * @param _valueIn  Msg.value to send with tx
     * @param _minUsdg  Min Usdg to receive
     * @param _minGlp   Min GLP to receive
     */
    function gmx_mintAndStakeGlpETH(
        uint256 _valueIn,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant returns (uint256) {
        inputGuard_gmx_mintAndStakeGlpETH(_valueIn, _minUsdg, _minGlp);

        return gmx_GLPRewardRouter.mintAndStakeGlpETH{ value: _valueIn }(_minUsdg, _minGlp);
    }

    /**
     * @notice Unstakes and redeems GLP
     * @param _tokenOut     Token address to unstake
     * @param _glpAmount    Amount of GLP to unstake
     * @param _minOut       Min amount to receive
     * @param _receiver     Recipient
     */
    function gmx_unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant returns (uint256) {
        inputGuard_gmx_unstakeAndRedeemGlp(_tokenOut, _glpAmount, _minOut, _receiver);

        return gmx_GLPRewardRouter.unstakeAndRedeemGlp(_tokenOut, _glpAmount, _minOut, _receiver);
    }

    /**
     * @notice Unstakes GMX
     * @param _amount   Amount of GMX to unstake
     */
    function gmx_unstakeGmx(uint256 _amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        gmx_GMXRewardRouter.unstakeGmx(_amount);
    }

    /**
     * @notice Unstakes esGMX
     * @param _amount   Amount of esGMX to unstake
     */
    function gmx_unstakeEsGmx(uint256 _amount) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        gmx_GMXRewardRouter.unstakeEsGmx(_amount);
    }

    /**
     * @notice Unstakes and redeems GLP to native token
     * @param _glpAmount    Amount of GLP to unstake
     * @param _minOut       Min amount to receive
     * @param _receiver     Recipient
     */
    function gmx_unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant returns (uint256) {
        inputGuard_gmx_unstakeAndRedeemGlpETH(_glpAmount, _minOut, _receiver);

        return gmx_GLPRewardRouter.unstakeAndRedeemGlpETH(_glpAmount, _minOut, _receiver);
    }

    /**
     * @notice Claims rewards from GMX reward router
     */
    function gmx_claim() external onlyRole(EXECUTOR_ROLE) nonReentrant {
        gmx_GMXRewardRouter.claim();
    }

    /**
     * @notice Compounds rewards from GMX reward router
     */
    function gmx_compound() external onlyRole(EXECUTOR_ROLE) nonReentrant {
        gmx_GMXRewardRouter.compound();
    }

    /**
     * @notice Handles rewards from GMX reward router
     * @param _shouldClaimGmx               Should claim GMX
     * @param _shouldStakeGmx               Should stake GMX
     * @param _shouldClaimEsGmx             Should claim esGMX
     * @param _shouldStakeEsGmx             Should stake esGMX
     * @param _shouldStakeMultiplierPoints  Should stake multiplier points
     * @param _shouldClaimWeth              Should claim WETH
     * @param _shouldConvertWethToEth       Should convert WETH to ETH
     */
    function gmx_handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            _shouldConvertWethToEth
        );

        gmx_GMXRewardRouter.handleRewards(
            _shouldClaimGmx,
            _shouldStakeGmx,
            _shouldClaimEsGmx,
            _shouldStakeEsGmx,
            _shouldStakeMultiplierPoints,
            _shouldClaimWeth,
            _shouldConvertWethToEth
        );
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice Validates inputs for gmx_mintAndStakeGlp
     * @param _token    Token address to stake
     * @param _amount   Amount of token to stake
     * @param _minUsdg  Min Usdg to receive
     * @param _minGlp   Min GLP to receive
     */
    function inputGuard_gmx_mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) internal virtual {}

    /**
     * @notice Validates inputs for gmx_mintAndStakeGlpETH
     * @param _valueIn  Msg.value to send with tx
     * @param _minUsdg  Min Usdg to receive
     * @param _minGlp   Min GLP to receive
     */
    function inputGuard_gmx_mintAndStakeGlpETH(uint256 _valueIn, uint256 _minUsdg, uint256 _minGlp) internal virtual {}

    /**
     * @notice Validates inputs for gmx_unstakeAndRedeemGlp
     * @param _tokenOut     Token address to unstake
     * @param _glpAmount    Amount of GLP to unstake
     * @param _minOut       Min amount to receive
     * @param _receiver     Recipient
     */
    function inputGuard_gmx_unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_unstakeAndRedeemGlpETH
     * @param _glpAmount    Amount of GLP to unstake
     * @param _minOut       Min amount to receive
     * @param _receiver     Recipient
     */
    function inputGuard_gmx_unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) internal virtual {}

    /**
     * @notice Validates inputs for gmx_handleRewards
     * @param _shouldClaimGmx               Should claim GMX
     * @param _shouldStakeGmx               Should stake GMX
     * @param _shouldClaimEsGmx             Should claim esGMX
     * @param _shouldStakeEsGmx             Should stake esGMX
     * @param _shouldStakeMultiplierPoints  Should stake multiplier points
     * @param _shouldClaimWeth              Should claim WETH
     * @param _shouldConvertWethToEth       Should convert WETH to ETH
     */
    function inputGuard_gmx_handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IGMX_GLP_Module.sol";

/**
 * @title   Vaultus GMX GLP Cutter
 * @notice  Cutter to enable diamonds contract to call GMX GLP functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_GLP_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IGMX_GLP_Module functions
     * @param   _facet  GMX_GLP_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "GMX_GLP_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](9);

        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_mintAndStakeGlp.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_mintAndStakeGlpETH.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_unstakeAndRedeemGlp.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_unstakeAndRedeemGlpETH.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_claim.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_compound.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_handleRewards.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_unstakeGmx.selector;
        selectors[selectorIndex++] = IGMX_GLP_Module.gmx_unstakeEsGmx.selector;

        _setSupportsInterface(type(IGMX_GLP_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "./GMX_GLP_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus GMX GLP Module
 * @notice  Allows depositing, withdrawing, and claiming rewards in the GLP ecosystem
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the input and output tokens are acceptable.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Provides a base set of protections against critical threats, override these only if explicitly necessary.
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_GLP_Module is GMX_GLP_Base, Vaultus_Trader_Storage {
    /**
     * @notice Sets the address of the GMX reward router and GMX GLP reward router
     * @param _gmx_GLPRewardRouter  GMX GLP reward router address
     * @param _gmx_GMXRewardRouter  GMX reward router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _gmx_GLPRewardRouter, address _gmx_GMXRewardRouter) GMX_GLP_Base(_gmx_GLPRewardRouter, _gmx_GMXRewardRouter) {}

    // ---------- Hooks ----------

    /// @inheritdoc GMX_GLP_Base
    // (address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
    function inputGuard_gmx_mintAndStakeGlp(address _token, uint256, uint256, uint256) internal virtual override {
        validateToken(_token);
    }

    /// @inheritdoc GMX_GLP_Base
    function inputGuard_gmx_unstakeAndRedeemGlp(
        address _tokenOut,
        uint256, // _glpAmount
        uint256, // _minOut
        address _receiver
    ) internal virtual override {
        validateToken(_tokenOut);
        require(_receiver == address(this), "GMX_GLP_Module: Invalid receiver");
    }

    /// @inheritdoc GMX_GLP_Base
    function inputGuard_gmx_unstakeAndRedeemGlpETH(
        uint256, // _glpAmount
        uint256, // _minOut
        address payable _receiver
    ) internal virtual override {
        require(_receiver == address(this), "GMX_GLP_Module: Invalid receiver");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRewardRouterV2.sol";

/**
 * @title   Vaultus GMX GLP Module Interface
 * @notice  Allows depositing, withdrawing, and claiming rewards in the GLP ecosystem
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IGMX_GLP_Module {
    // ---------- Functions ----------
    function gmx_mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);

    function gmx_mintAndStakeGlpETH(uint256 _valueIn, uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function gmx_unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);

    function gmx_unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function gmx_claim() external;

    function gmx_compound() external;

    function gmx_handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function gmx_unstakeGmx(uint256 _amount) external;

    function gmx_unstakeEsGmx(uint256 _amount) external;

    // ---------- Getters ----------

    function gmx_GLPRewardRouter() external returns (IRewardRouterV2);

    function gmx_GMXRewardRouter() external returns (IRewardRouterV2);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../../vaultus/Vaultus_Common_Roles.sol";
import "../../../external/gmx_interfaces/IOrderBook.sol";
import "../../../external/gmx_interfaces/IRouter.sol";

/**
 * @title   Vaultus GMX OrderBook Base
 * @notice  Allows limit orders to be opened on the GMX Order Book
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path, index token, and collateral token are acceptable.
 *              2. Inheritor MAY check position size and direction if desired.
 *              3. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Several functions are payable to allow passing an execution fee to the Order Book.
 *          The base contract does not enforce a source of execution fee ETH.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract GMX_OrderBook_Base is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice GMX Router address
    IRouter public immutable gmx_router;
    /// @notice GMX OrderBook address
    IOrderBook public immutable gmx_orderBook;

    /**
     * @notice Sets the address of the GMX Router and OrderBook
     * @param _gmx_router       GMX Router address
     * @param _gmx_orderBook    GMX OrderBook address
     */
    constructor(address _gmx_router, address _gmx_orderBook) {
        require(_gmx_router != address(0) && _gmx_orderBook != address(0), "GMX_OrderBook_Base: Zero Address");
        gmx_router = IRouter(_gmx_router);
        gmx_orderBook = IOrderBook(_gmx_orderBook);
    }

    // solhint-enable var-name-mixedcase

    /**
     * @notice  Approves the GMX Order Book plugin in the GMX router
     * @dev     This is an initialization function which should not be added to any diamond's selectors
     */
    function init_GMX_OrderBook() external {
        gmx_router.approvePlugin(address(gmx_orderBook));
    }

    // ---------- Functions ----------

    /**
     * @notice Creates a GMX increase order
     * @param _path                     Token path
     * @param _amountIn                 Amount in
     * @param _indexToken               Index token address
     * @param _minOut                   Minimum output amount
     * @param _sizeDelta                Size delta
     * @param _collateralToken          Collateral token address
     * @param _isLong                   Is long order
     * @param _triggerPrice             Trigger price
     * @param _triggerAboveThreshold    Trigger if above thresold
     * @param _executionFee             Execution fee
     * @param _shouldWrap               Should wrap native token
     */
    function gmx_createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_createIncreaseOrder(
            _path,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap
        );

        uint256 msgValue = _shouldWrap ? _amountIn + _executionFee : _executionFee;

        gmx_orderBook.createIncreaseOrder{ value: msgValue }(
            _path,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap
        );
    }

    /**
     * @notice Creates a GMX decrease order
     * @param _indexToken               Index token address
     * @param _sizeDelta                Size delta
     * @param _collateralToken          Collateral token address
     * @param _collateralDelta          Collateral delta
     * @param _isLong                   Is long position
     * @param _triggerPrice             Trigger price
     * @param _triggerAboveThreshold    Trigger above threshold
     * @param _executionFee             Execution fee
     */
    function gmx_createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_createDecreaseOrder(
            _indexToken,
            _sizeDelta,
            _collateralToken,
            _collateralDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );

        gmx_orderBook.createDecreaseOrder{ value: _executionFee }(
            _indexToken,
            _sizeDelta,
            _collateralToken,
            _collateralDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    /**
     * @notice Creates a GMX swap order
     * @param _path                     Token path
     * @param _amountIn                 Amount in
     * @param _minOut                   Minimum amount out
     * @param _triggerRatio             Trigger ratio
     * @param _triggerAboveThreshold    Trigger above threshold
     * @param _executionFee             Execution fee
     * @param _shouldWrap               Should wrap native token
     * @param _shouldUnwrap             Should unwrap native token
     */
    function gmx_createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_createSwapOrder(
            _path,
            _amountIn,
            _minOut,
            _triggerRatio,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap,
            _shouldUnwrap
        );

        uint256 msgValue = _shouldWrap ? _amountIn + _executionFee : _executionFee;

        gmx_orderBook.createSwapOrder{ value: msgValue }(
            _path,
            _amountIn,
            _minOut,
            _triggerRatio,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap,
            _shouldUnwrap
        );
    }

    /**
     * @notice Updates a GMX increase order
     * @param _orderIndex               Order index
     * @param _sizeDelta                Size delta
     * @param _triggerPrice             New trigger price
     * @param _triggerAboveThreshold    New trigger above threshold
     */
    function gmx_updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_updateIncreaseOrder(_orderIndex, _sizeDelta, _triggerPrice, _triggerAboveThreshold);

        gmx_orderBook.updateIncreaseOrder(_orderIndex, _sizeDelta, _triggerPrice, _triggerAboveThreshold);
    }

    /**
     * @notice Updates a GMX decrease order
     * @param _orderIndex               Order index
     * @param _collateralDelta          Collateral delta
     * @param _sizeDelta                Size delta
     * @param _triggerPrice             New trigger price
     * @param _triggerAboveThreshold    New trigger above threshold
     */
    function gmx_updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_updateDecreaseOrder(_orderIndex, _collateralDelta, _sizeDelta, _triggerPrice, _triggerAboveThreshold);

        gmx_orderBook.updateDecreaseOrder(_orderIndex, _collateralDelta, _sizeDelta, _triggerPrice, _triggerAboveThreshold);
    }

    /**
     * @notice Cancels a GMX increase order
     * @dev    The refunded execution fee is sent to the caller irrespective of who created the order
     * @param _orderIndex   Order index
     */
    function gmx_cancelIncreaseOrder(uint256 _orderIndex) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_cancelIncreaseOrder(_orderIndex);

        uint256 refund = getFeeForIncreaseOrder(_orderIndex);
        gmx_orderBook.cancelIncreaseOrder(_orderIndex);

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Cancels a GMX decrease order
     * @dev    The refunded execution fee is sent to the caller irrespective of who created the order
     * @param _orderIndex   Order index
     */
    function gmx_cancelDecreaseOrder(uint256 _orderIndex) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_cancelDecreaseOrder(_orderIndex);

        uint256 refund = getFeeForDecreaseOrder(_orderIndex);
        gmx_orderBook.cancelDecreaseOrder(_orderIndex);

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Cancels a GMX swap order
     * @dev    The refunded execution fee is sent to the caller irrespective of who created the order
     * @param _orderIndex   Order index
     */
    function gmx_cancelSwapOrder(uint256 _orderIndex) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_cancelSwapOrder(_orderIndex);

        uint256 refund = getFeeForSwapOrder(_orderIndex);
        gmx_orderBook.cancelSwapOrder(_orderIndex);

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @notice Cancels multiple GMX orders
     * @dev    The refunded execution fee is sent to the caller irrespective of who created the order
     * @param _swapOrderIndexes         Array of swap order indexes
     * @param _increaseOrderIndexes     Array of increase order indexes
     * @param _decreaseOrderIndexes     Array of decrease order indexes
     */
    function gmx_cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_cancelMultiple(_swapOrderIndexes, _increaseOrderIndexes, _decreaseOrderIndexes);

        uint256 refund;
        for (uint256 i; i < _swapOrderIndexes.length; ) {
            refund += getFeeForSwapOrder(_swapOrderIndexes[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i; i < _increaseOrderIndexes.length; ) {
            refund += getFeeForIncreaseOrder(_increaseOrderIndexes[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i; i < _decreaseOrderIndexes.length; ) {
            refund += getFeeForDecreaseOrder(_decreaseOrderIndexes[i]);
            unchecked {
                i++;
            }
        }

        gmx_orderBook.cancelMultiple(_swapOrderIndexes, _increaseOrderIndexes, _decreaseOrderIndexes);

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    // ---------- Internal ----------

    /**
     * @notice Gets the execution fee for a GMX increase order
     */
    function getFeeForIncreaseOrder(uint256 _orderIndex) internal view returns (uint256) {
        return gmx_orderBook.increaseOrders(address(this), _orderIndex).executionFee;
    }

    /**
     * @notice Gets the execution fee for a GMX decrease order
     */
    function getFeeForDecreaseOrder(uint256 _orderIndex) internal view returns (uint256) {
        return gmx_orderBook.decreaseOrders(address(this), _orderIndex).executionFee;
    }

    /**
     * @notice Gets the execution fee for a GMX swap order
     */
    function getFeeForSwapOrder(uint256 _orderIndex) internal view returns (uint256) {
        (, , , , , , , , uint256 executionFee) = gmx_orderBook.getSwapOrder(address(this), _orderIndex);
        return executionFee;
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice Validates inputs for gmx_createIncreaseOrder
     * @param _path                     Token path
     * @param _amountIn                 Amount in
     * @param _indexToken               Index token address
     * @param _minOut                   Minimum output amount
     * @param _sizeDelta                Size delta
     * @param _collateralToken          Collateral token address
     * @param _isLong                   Is long order
     * @param _triggerPrice             Trigger price
     * @param _triggerAboveThreshold    Trigger if above thresold
     * @param _executionFee             Execution fee
     * @param _shouldWrap               Should wrap native token
     */
    function inputGuard_gmx_createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_createDecreaseOrder
     * @param _indexToken               Index token address
     * @param _sizeDelta                Size delta
     * @param _collateralToken          Collateral token address
     * @param _collateralDelta          Collateral delta
     * @param _isLong                   Is long position
     * @param _triggerPrice             Trigger price
     * @param _triggerAboveThreshold    Trigger above threshold
     * @param _executionFee             Execution fee
     */
    function inputGuard_gmx_createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_createSwapOrder
     * @param _path                     Token path
     * @param _amountIn                 Amount in
     * @param _minOut                   Minimum amount out
     * @param _triggerRatio             Trigger ratio
     * @param _triggerAboveThreshold    Trigger above threshold
     * @param _executionFee             Execution fee
     * @param _shouldWrap               Should wrap native token
     * @param _shouldUnwrap             Should unwrap native token
     */
    function inputGuard_gmx_createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_updateIncreaseOrder
     * @param _orderIndex               Order index
     * @param _sizeDelta                Size delta
     * @param _triggerPrice             New trigger price
     * @param _triggerAboveThreshold    New trigger above threshold
     */
    function inputGuard_gmx_updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_updateDecreaseOrder
     * @param _orderIndex               Order index
     * @param _collateralDelta          Collateral delta
     * @param _sizeDelta                Size delta
     * @param _triggerPrice             New trigger price
     * @param _triggerAboveThreshold    New trigger above threshold
     */
    function inputGuard_gmx_updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelIncreaseOrder
     * @param _orderIndex   Order index
     */
    function inputGuard_gmx_cancelIncreaseOrder(uint256 _orderIndex) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelDecreaseOrder
     * @param _orderIndex   Order index
     */
    function inputGuard_gmx_cancelDecreaseOrder(uint256 _orderIndex) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelSwapOrder
     * @param _orderIndex   Order index
     */
    function inputGuard_gmx_cancelSwapOrder(uint256 _orderIndex) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelMultiple
     * @param _swapOrderIndexes         Array of swap order indexes
     * @param _increaseOrderIndexes     Array of increase order indexes
     * @param _decreaseOrderIndexes     Array of decrease order indexes
     */
    function inputGuard_gmx_cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IGMX_OrderBook_Module.sol";

/**
 * @title   Vaultus GMX OrderBook Cutter
 * @notice  Cutter to enable diamonds contract to call GMX limit order functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_OrderBook_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IGMX_OrderBook_Module functions
     * @param   _facet  GMX_OrderBook_Module address
     */
    function cut(address _facet) external {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "GMX_OrderBook_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](9);

        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_createIncreaseOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_createDecreaseOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_createSwapOrder.selector;

        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_updateIncreaseOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_updateDecreaseOrder.selector;

        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_cancelIncreaseOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_cancelDecreaseOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_cancelSwapOrder.selector;
        selectors[selectorIndex++] = IGMX_OrderBook_Module.gmx_cancelMultiple.selector;

        _setSupportsInterface(type(IGMX_OrderBook_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        bytes memory payload = abi.encodeWithSelector(IGMX_OrderBook_Module.init_GMX_OrderBook.selector);

        _diamondCut(facetCuts, _facet, payload);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./GMX_OrderBook_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus GMX OrderBook Module
 * @notice  Allows limit orders to be opened on the GMX Order Book
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path, index token, and collateral token are acceptable.
 *              2. Inheritor MAY check position size and direction if desired.
 *              3. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Several functions are payable to allow passing an execution fee to the Order Book.
 *          Execution fee ETH must be provided with msg.value.
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_OrderBook_Module is GMX_OrderBook_Base, Vaultus_Trader_Storage {
    /**
     * @notice Sets the address of the GMX Router and OrderBook
     * @param _gmx_router       GMX Router address
     * @param _gmx_orderBook    GMX OrderBook address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _gmx_router, address _gmx_orderBook) GMX_OrderBook_Base(_gmx_router, _gmx_orderBook) {}

    // ----- GMX OrderBook Module -----

    /// @inheritdoc GMX_OrderBook_Base
    function inputGuard_gmx_createIncreaseOrder(
        address[] memory _path,
        uint256, // _amountIn
        address _indexToken,
        uint256, // _minOut
        uint256, // _sizeDelta
        address _collateralToken,
        bool, // _isLong
        uint256, // _triggerPrice
        bool, // _triggerAboveThreshold
        uint256 _executionFee,
        bool // _shouldWrap
    ) internal view virtual override {
        validateSwapPath(_path);
        validateToken(_indexToken);
        validateToken(_collateralToken);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
    }

    /// @inheritdoc GMX_OrderBook_Base
    function inputGuard_gmx_createDecreaseOrder(
        address _indexToken,
        uint256, // _sizeDelta
        address _collateralToken,
        uint256, // _collateralDelta
        bool, // _isLong
        uint256, // _triggerPrice
        bool, // _triggerAboveThreshold
        uint256 _executionFee
    ) internal view virtual override {
        validateToken(_indexToken);
        validateToken(_collateralToken);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
    }

    /// @inheritdoc GMX_OrderBook_Base
    function inputGuard_gmx_createSwapOrder(
        address[] memory _path,
        uint256, // _amountIn
        uint256, // _minOut
        uint256, // _triggerRatio // tokenB / tokenA
        bool, // _triggerAboveThreshold
        uint256 _executionFee,
        bool, // _shouldWrap
        bool // _shouldUnwrap
    ) internal view virtual override {
        validateSwapPath(_path);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";
import "../../../external/gmx_interfaces/IOrderBook.sol";

/**
 * @title   Vaultus GMX OrderBook Module Interface
 * @notice  Allows limit orders to be opened on the GMX Order Book
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IGMX_OrderBook_Module {
    function init_GMX_OrderBook() external;

    // ---------- Functions ----------

    function gmx_createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function gmx_createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) external payable;

    function gmx_createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function gmx_updateIncreaseOrder(uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) external;

    function gmx_updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function gmx_cancelIncreaseOrder(uint256 _orderIndex) external;

    function gmx_cancelDecreaseOrder(uint256 _orderIndex) external;

    function gmx_cancelSwapOrder(uint256 _orderIndex) external;

    function gmx_cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);

    function gmx_orderBook() external view returns (IOrderBook);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../../vaultus/Vaultus_Common_Roles.sol";
import "../../../external/gmx_interfaces/IRouter.sol";
import "../../../external/gmx_interfaces/IPositionRouter.sol";

/**
 * @title   Vaultus GMX PositionRouter Base
 * @notice  Allows leveraged long/short positions to be opened on the GMX Position Router
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path and index token are acceptable.
 *              2. Inheritor MAY check size, leverage, and option direction if desired.
 *              3. Inheritor MUST validate the callback target address.
 *              4. Inheritor MUST validate the receiver address.
 *              5. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Several functions are payable to allow passing an execution fee to the Position Router.
 *          The base contract does not enforce a source of execution fee ETH.
 * @dev     WARNING: This module can leave a strategy with a balance of native ETH.
 *          It MUST be deployed alongside another module capable of withdrawing native ETH or swapping it to a mandate token.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract GMX_PositionRouter_Base is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice GMX Router address
    IRouter public immutable gmx_router;
    /// @notice GMX PositionRouter address
    IPositionRouter public immutable gmx_positionRouter;

    /**
     * @notice  Sets the addresses of the GMX Router and PositionRouter
     * @param   _gmx_router             GMX Router address
     * @param   _gmx_positionRouter     GMX PositionRouter address
     */
    constructor(address _gmx_router, address _gmx_positionRouter) {
        // solhint-disable-next-line reason-string
        require(_gmx_router != address(0) && _gmx_positionRouter != address(0), "GMX_PositionRouter_Base: Zero Address");
        gmx_router = IRouter(_gmx_router);
        gmx_positionRouter = IPositionRouter(_gmx_positionRouter);
    }

    // solhint-enable var-name-mixedcase

    /**
     * @notice  Approves the GMX PositionRouter plugin on the GMX Router
     * @dev     This is an initialization function which should not be added to any diamond's selectors
     */
    function init_GMX_PositionRouter() external {
        gmx_router.approvePlugin(address(gmx_positionRouter));
    }

    // ---------- Functions ----------

    /**
     * @notice  Creates a positionRouter increase position
     * @dev     Approval must be handled via another function
     * @param _path             Token path
     * @param _indexToken       Index token
     * @param _amountIn         Amount in
     * @param _minOut           Minimum amount out
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _acceptablePrice  Acceptable price
     * @param _executionFee     Execution fee
     * @param _referralCode     Referral code
     * @param _callbackTarget   Callback target
     */
    function gmx_createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant returns (bytes32) {
        inputGuard_gmx_createIncreasePosition(
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            _callbackTarget
        );

        return
            gmx_positionRouter.createIncreasePosition{ value: _executionFee }(
                _path,
                _indexToken,
                _amountIn,
                _minOut,
                _sizeDelta,
                _isLong,
                _acceptablePrice,
                _executionFee,
                _referralCode,
                _callbackTarget
            );
    }

    /**
     * @notice  Creates a positionRouter increase position with native token
     * @dev     Approval must be handled via another function
     * @dev     Note the _amountIn parameter, which does not exist in the direct GMX call
     * @param _valueIn          Msg.value to send with tx
     * @param _path             Token path
     * @param _indexToken       Index token
     * @param _minOut           Minimum amount out
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _acceptablePrice  Acceptable price
     * @param _executionFee     Execution fee
     * @param _referralCode     Referral code
     * @param _callbackTarget   Callback target
     */
    function gmx_createIncreasePositionETH(
        uint256 _valueIn,
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant returns (bytes32) {
        inputGuard_gmx_createIncreasePositionETH(
            _valueIn,
            _path,
            _indexToken,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            _callbackTarget
        );

        return
            gmx_positionRouter.createIncreasePositionETH{ value: _valueIn + _executionFee }(
                _path,
                _indexToken,
                _minOut,
                _sizeDelta,
                _isLong,
                _acceptablePrice,
                _executionFee,
                _referralCode,
                _callbackTarget
            );
    }

    /**
     * @notice  Creates a positionRouter decrease position
     * @dev     Approval must be handled via another function
     * @param _path             Path
     * @param _indexToken       Index token address
     * @param _collateralDelta  Collateral delta
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _receiver         Receiver address
     * @param _acceptablePrice  Acceptable price
     * @param _minOut           Minimum amount out
     * @param _executionFee     Execution fee
     * @param _withdrawETH      Withdraw ETH
     * @param _callbackTarget   Callback target
     */
    function gmx_createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable onlyRole(EXECUTOR_ROLE) nonReentrant returns (bytes32) {
        inputGuard_gmx_createDecreasePosition(
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            _withdrawETH,
            _callbackTarget
        );

        return
            gmx_positionRouter.createDecreasePosition{ value: _executionFee }(
                _path,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                _receiver,
                _acceptablePrice,
                _minOut,
                _executionFee,
                _withdrawETH,
                _callbackTarget
            );
    }

    /**
     * @notice Cancels a PositionRouter increase position
     * @param _key                  Key
     * @param _executionFeeReceiver Execution fee receiver address
     */
    function gmx_cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external onlyRole(EXECUTOR_ROLE) returns (bool) {
        inputGuard_gmx_cancelIncreasePosition(_key, _executionFeeReceiver);

        bool result = gmx_positionRouter.cancelIncreasePosition(_key, _executionFeeReceiver);
        return result;
    }

    /**
     * @notice Cancels a PositionRouter decrease position
     * @param _key                  Key
     * @param _executionFeeReceiver Execution fee receiver address
     */
    function gmx_cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external onlyRole(EXECUTOR_ROLE) returns (bool) {
        inputGuard_gmx_cancelDecreasePosition(_key, _executionFeeReceiver);

        bool result = gmx_positionRouter.cancelDecreasePosition(_key, _executionFeeReceiver);
        return result;
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for gmx_createIncreasePosition
     * @dev     Override this in the parent strategy to protect against unacceptable input
     * @dev     Must revert on unacceptable input
     * @param _path             Token path
     * @param _indexToken       Index token
     * @param _amountIn         Amount in
     * @param _minOut           Minimum amount out
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _acceptablePrice  Acceptable price
     * @param _executionFee     Execution fee
     * @param _referralCode     Referral code
     * @param _callbackTarget   Callback target
     */
    function inputGuard_gmx_createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) internal virtual {}

    /**
     * @notice  Validates inputs for gmx_createIncreasePositionETH
     * @param _valueIn          Msg.value to send with tx
     * @param _path             Token path
     * @param _indexToken       Index token
     * @param _minOut           Minimum amount out
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _acceptablePrice  Acceptable price
     * @param _executionFee     Execution fee
     * @param _referralCode     Referral code
     * @param _callbackTarget   Callback target
     */
    function inputGuard_gmx_createIncreasePositionETH(
        uint256 _valueIn,
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) internal virtual {}

    /**
     * @notice  Validates inputs for gmx_createDecreasePosition
     * @dev     Override this in the parent strategy to protect against unacceptable input
     * @dev     Must revert on unacceptable input
     * @param _path             Path
     * @param _indexToken       Index token address
     * @param _collateralDelta  Collateral delta
     * @param _sizeDelta        Size delta
     * @param _isLong           Is long position
     * @param _receiver         Receiver address
     * @param _acceptablePrice  Acceptable price
     * @param _minOut           Minimum amount out
     * @param _executionFee     Execution fee
     * @param _withdrawETH      Withdraw ETH
     * @param _callbackTarget   Callback target
     */
    function inputGuard_gmx_createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelIncreasePosition
     * @param _key                  Key
     * @param _executionFeeReceiver Execution fee receiver address
     */
    function inputGuard_gmx_cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) internal virtual {}

    /**
     * @notice Validates inputs for gmx_cancelDecreasePosition
     * @param _key                  Key
     * @param _executionFeeReceiver Execution fee receiver address
     */
    function inputGuard_gmx_cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) internal virtual {}
    // solhint-disable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IGMX_PositionRouter_Module.sol";

/**
 * @title   Vaultus GMX PositionRouter Cutter
 * @notice  Cutter to enable diamonds contract to call GMX position router functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_PositionRouter_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IGMX_PositionRouter_Module functions
     * @param   _facet  GMX_PositionRouter_Module address
     */
    function cut(address _facet) external {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "GMX_PositionRouter_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](5);

        selectors[selectorIndex++] = IGMX_PositionRouter_Module.gmx_createIncreasePosition.selector;
        selectors[selectorIndex++] = IGMX_PositionRouter_Module.gmx_createIncreasePositionETH.selector;
        selectors[selectorIndex++] = IGMX_PositionRouter_Module.gmx_createDecreasePosition.selector;
        selectors[selectorIndex++] = IGMX_PositionRouter_Module.gmx_cancelIncreasePosition.selector;
        selectors[selectorIndex++] = IGMX_PositionRouter_Module.gmx_cancelDecreasePosition.selector;

        _setSupportsInterface(type(IGMX_PositionRouter_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        bytes memory payload = abi.encodeWithSelector(IGMX_PositionRouter_Module.init_GMX_PositionRouter.selector);

        _diamondCut(facetCuts, _facet, payload);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./GMX_PositionRouter_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus GMX PositionRouter Module
 * @notice  Allows leveraged long/short positions to be opened on the GMX Position Router
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path and index token are acceptable.
 *              2. Inheritor MAY check size, leverage, and option direction if desired.
 *              3. Inheritor MUST validate the callback target address.
 *              4. Inheritor MUST validate the receiver address.
 *              5. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Several functions are payable to allow passing an execution fee to the Position Router.
 *          Execution fee ETH must be provided with msg.value.
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_PositionRouter_Module is GMX_PositionRouter_Base, Vaultus_Trader_Storage {
    /**
     * @notice  Sets the addresses of the GMX Router and PositionRouter
     * @param   _gmx_router             GMX Router address
     * @param   _gmx_positionRouter     GMX PositionRouter address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _gmx_router, address _gmx_positionRouter) GMX_PositionRouter_Base(_gmx_router, _gmx_positionRouter) {}

    // ----- GMX PositionRouter Module -----

    /// @inheritdoc GMX_PositionRouter_Base
    function inputGuard_gmx_createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256, // _amountIn
        uint256, // _minOut
        uint256, // _sizeDelta
        bool, // _isLong
        uint256, // _acceptablePrice
        uint256 _executionFee,
        bytes32, // _referralCode
        address _callbackTarget
    ) internal view virtual override {
        validateSwapPath(_path);
        validateToken(_indexToken);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
        require(_callbackTarget == address(0), "GuardError: GMX callback target");
    }

    /// @inheritdoc GMX_PositionRouter_Base
    function inputGuard_gmx_createIncreasePositionETH(
        uint256, // _valueIn
        address[] memory _path,
        address _indexToken,
        uint256, // _minOut
        uint256, // _sizeDelta
        bool, // _isLong
        uint256, // _acceptablePrice
        uint256 _executionFee,
        bytes32, // _referralCode
        address _callbackTarget
    ) internal view virtual override {
        validateSwapPath(_path);
        validateToken(_indexToken);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
        require(_callbackTarget == address(0), "GuardError: GMX callback target");
    }

    /// @inheritdoc GMX_PositionRouter_Base
    function inputGuard_gmx_createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256, // _collateralDelta
        uint256, // _sizeDelta
        bool, // _isLong
        address _receiver,
        uint256, // _acceptablePrice
        uint256, // _minOut
        uint256 _executionFee,
        bool, // _withdrawETH
        address _callbackTarget
    ) internal view virtual override {
        validateSwapPath(_path);
        validateToken(_indexToken);
        require(_executionFee == msg.value, "GuardError: GMX execution fee");
        // solhint-disable-next-line reason-string
        require(_receiver == address(this), "GuardError: GMX DecreasePosition recipient");
        require(_callbackTarget == address(0), "GuardError: GMX callback target");
    }

    // bytes32 _key, address payable _executionFeeReceiver
    function inputGuard_gmx_cancelIncreasePosition(bytes32, address payable _executionFeeReceiver) internal view virtual override {
        // solhint-disable-next-line reason-string
        require(
            _hasRole(EXECUTOR_ROLE, _executionFeeReceiver) || _hasRole(DEFAULT_ADMIN_ROLE, _executionFeeReceiver),
            "GuardError: GMX CancelIncreasePosition recipient"
        );
    }

    // bytes32 _key, address payable _executionFeeReceiver
    function inputGuard_gmx_cancelDecreasePosition(bytes32, address payable _executionFeeReceiver) internal view virtual override {
        // solhint-disable-next-line reason-string
        require(
            _hasRole(EXECUTOR_ROLE, _executionFeeReceiver) || _hasRole(DEFAULT_ADMIN_ROLE, _executionFeeReceiver),
            "GuardError: GMX CancelDecreasePosition recipient"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";
import "../../../external/gmx_interfaces/IPositionRouter.sol";

/**
 * @title   Vaultus GMX PositionRouter Module Interface
 * @notice  Allows leveraged long/short positions to be opened on the GMX Position Router
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IGMX_PositionRouter_Module {
    // ---------- Functions ----------

    function init_GMX_PositionRouter() external;

    /**
     * @dev     Approval must be handled via another function
     */
    function gmx_createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    /**
     * @dev     Note the _valueIn parameter, which does not exist in the direct GMX call
     * @param   _valueIn    Wei of the contract's ETH to transfer as msg.value with the createIncreasePosition call
     */
    function gmx_createIncreasePositionETH(
        uint256 _valueIn,
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function gmx_createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function gmx_cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function gmx_cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);

    function gmx_positionRouter() external view returns (IPositionRouter);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../../vaultus/Vaultus_Common_Roles.sol";
import "../../../external/gmx_interfaces/IRouter.sol";

/**
 * @title   Vaultus GMX Swap Base
 * @notice  Allows direct swapping via the GMX Router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path is acceptable.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract GMX_Swap_Base is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice GMX router address
    IRouter public immutable gmx_router;

    /**
     * @notice  Sets the addresses of the GMX router
     * @param   _gmx_router    GMX router address
     */
    constructor(address _gmx_router) {
        require(_gmx_router != address(0), "GMX_Swap_Base: Zero Address");
        gmx_router = IRouter(_gmx_router);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Swaps tokens for tokens using GMX router
     * @param   _path       The path of the swap
     * @param   _amountIn   The amount of token to send
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function gmx_swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_swap(_path, _amountIn, _minOut, _receiver);

        gmx_router.swap(_path, _amountIn, _minOut, _receiver);
    }

    /**
     * @notice  Swaps ETH for tokens using GMX router
     * @param   _valueIn    Msg.value to send with tx
     * @param   _path       The path of the swap
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function gmx_swapETHToTokens(
        uint256 _valueIn,
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_swapETHToTokens(_valueIn, _path, _minOut, _receiver);

        gmx_router.swapETHToTokens{ value: _valueIn }(_path, _minOut, _receiver);
    }

    /**
     * @notice  Swaps tokens for ETH using GMX router
     * @param   _path       The path of the swap
     * @param   _amountIn   The amount of ETH to send
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function gmx_swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_gmx_swapTokensToETH(_path, _amountIn, _minOut, _receiver);

        gmx_router.swapTokensToETH(_path, _amountIn, _minOut, _receiver);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for gmx_swap
     * @param   _path       The path of the swap
     * @param   _amountIn   The amount of ETH to send
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function inputGuard_gmx_swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) internal virtual {}

    /**
     * @notice  Validates inputs for gmx_swapETHToTokens
     * @param   _valueIn    Msg.value to send with tx
     * @param   _path       The path of the swap
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function inputGuard_gmx_swapETHToTokens(
        uint256 _valueIn,
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) internal virtual {}

    /**
     * @notice  Validates inputs for gmx_swapTokensToETH
     * @param   _path       The path of the swap
     * @param   _amountIn   The amount of ETH to send
     * @param   _minOut     The min amount of token to receive
     * @param   _receiver   The address of the recipient
     */
    function inputGuard_gmx_swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) internal virtual {}
    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IGMX_Swap_Module.sol";

/**
 * @title   Vaultus GMX Swap Cutter
 * @notice  Cutter to enable diamonds contract to call GMX swap functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_Swap_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IGMX_Swap_Module functions
     * @param   _facet  GMX_Swap_Module address
     */
    function cut(address _facet) external {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "GMX_Swap_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](3);

        selectors[selectorIndex++] = IGMX_Swap_Module.gmx_swap.selector;
        selectors[selectorIndex++] = IGMX_Swap_Module.gmx_swapETHToTokens.selector;
        selectors[selectorIndex++] = IGMX_Swap_Module.gmx_swapTokensToETH.selector;

        _setSupportsInterface(type(IGMX_Swap_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./GMX_Swap_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";

/**
 * @title   Vaultus GMX Swap Module
 * @notice  Allows direct swapping via the GMX Router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the swap path is acceptable.
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract GMX_Swap_Module is GMX_Swap_Base, Vaultus_Trader_Storage {
    /**
     * @notice  Sets the addresses of the GMX router
     * @param   _gmx_router    GMX router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _gmx_router) GMX_Swap_Base(_gmx_router) {}

    // ----- GMX Swap Module -----

    /// @inheritdoc GMX_Swap_Base
    function inputGuard_gmx_swap(
        address[] memory _path,
        uint256, // _amountIn
        uint256, // _minOut
        address _receiver
    ) internal view virtual override {
        validateSwapPath(_path);
        require(_receiver == address(this), "GuardError: GMX swap recipient");
    }

    /// @inheritdoc GMX_Swap_Base
    function inputGuard_gmx_swapETHToTokens(
        uint256, // _valueIn
        address[] memory _path,
        uint256, // _minOut
        address _receiver
    ) internal view virtual override {
        validateSwapPath(_path);
        require(_receiver == address(this), "GuardError: GMX swap recipient");
    }

    /// @inheritdoc GMX_Swap_Base
    function inputGuard_gmx_swapTokensToETH(
        address[] memory _path,
        uint256, // _amountIn
        uint256, // _minOut
        address payable _receiver
    ) internal view virtual override {
        validateSwapPath(_path);
        require(_receiver == address(this), "GuardError: GMX swap recipient");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../../../external/gmx_interfaces/IRouter.sol";

/**
 * @title   Vaultus GMX Swap Module Interface
 * @notice  Allows direct swapping via the GMX Router contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IGMX_Swap_Module {
    // ---------- Functions ----------
    function gmx_swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function gmx_swapETHToTokens(uint256 _valueIn, address[] memory _path, uint256 _minOut, address _receiver) external;

    function gmx_swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;

    // ---------- Getters ----------

    function gmx_router() external view returns (IRouter);
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

interface ICutter {
    function cut(address _facet) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Odos Storage Module Interface
 * @notice  Allows interacting with Odos common storage
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IOdos_Storage_Module {
    // --------- External Functions ---------

    function manageExecutors(address[] calldata _executors, bool[] calldata _status) external;

    function manageReceivers(address[] calldata _receivers, bool[] calldata _status) external;

    // --------- Getter Functions ---------

    function getAllowedExecutors() external view returns (address[] memory);

    function getAllowedReceivers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../vaultus/Vaultus_Common_Roles.sol";

/**
 * @title   Vaultus Odos Common Storage
 * @notice  Protocol addresses and constants used by all Odos modules
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Odos_Common_Storage is Vaultus_Common_Roles {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct OdosCommonStorage {
        /// @notice Set of allowed Odos executors
        EnumerableSet.AddressSet allowedExecutors;
        /// @notice Set of allowed Odos pools to be input receivers
        EnumerableSet.AddressSet allowedReceivers;
    }

    /// @dev    EIP-2535 Diamond Storage struct location
    bytes32 internal constant ODOS_POSITION = bytes32(uint256(keccak256("Odos_Common.storage")) - 1);

    function getOdosCommonStorage() internal pure returns (OdosCommonStorage storage storageStruct) {
        bytes32 position = ODOS_POSITION;
        // solhint-disable no-inline-assembly
        assembly {
            storageStruct.slot := position
        }
    }

    // --------- Internal Functions ---------

    /**
     * @notice  Validates an Odos executor
     * @param   _executor   Executor address
     */
    function validateExecutor(address _executor) internal view {
        require(getOdosCommonStorage().allowedExecutors.contains(_executor), "Invalid Executor");
    }

    /**
     * @notice  Validates an Odos input receiver
     * @param   _receiver   Input receiver address
     */
    function validateReceiver(address _receiver) internal view {
        require(getOdosCommonStorage().allowedReceivers.contains(_receiver), "Invalid Receiver");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IOdos_Storage_Module.sol";

/**
 * @title   Vaultus Odos Storage Cutter
 * @notice  Cutter to enable diamonds contract to call Odos storage functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Odos_Storage_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IOdos_Storage_Module functions
     * @param   _facet  Odos_Storage_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Odos_Storage_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](4);

        selectors[selectorIndex++] = IOdos_Storage_Module.manageExecutors.selector;
        selectors[selectorIndex++] = IOdos_Storage_Module.manageReceivers.selector;
        selectors[selectorIndex++] = IOdos_Storage_Module.getAllowedExecutors.selector;
        selectors[selectorIndex++] = IOdos_Storage_Module.getAllowedReceivers.selector;

        _setSupportsInterface(type(IOdos_Storage_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Odos_Common_Storage.sol";

/**
 * @title   Vaultus Odos Storage Module
 * @notice  Manage Odos storage
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Odos_Storage_Module is AccessControl, Odos_Common_Storage {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Adds or removes batch of executors to the set of allowed executors
     * @param _executors    Array of executor addresses
     * @param _status       Array of statuses
     */
    function manageExecutors(address[] calldata _executors, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_executors.length == _status.length, "Odos_Storage_Module: Length mismatch");
        for (uint256 i; i < _executors.length; ) {
            _manageExecutor(_executors[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove an executor from the set of allowed executors
     * @param _executor     Executor address
     * @param _status       Status
     */
    function _manageExecutor(address _executor, bool _status) internal {
        // solhint-disable-next-line reason-string
        require(_executor != address(0), "Odos_Storage_Module: Zero address");
        if (_status) {
            getOdosCommonStorage().allowedExecutors.add(_executor);
        } else {
            getOdosCommonStorage().allowedExecutors.remove(_executor);
        }
    }

    /**
     * @notice Adds or removes batch of receivers to the set of allowed receivers
     * @param _receivers    Array of receiver addresses
     * @param _status       Array of statuses
     */
    function manageReceivers(address[] calldata _receivers, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_receivers.length == _status.length, "Odos_Storage_Module: Length mismatch");
        for (uint256 i; i < _receivers.length; ) {
            _manageReceiver(_receivers[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a receiver from the set of allowed receivers
     * @param _receiver     Receiver address
     * @param _status       Status
     */
    function _manageReceiver(address _receiver, bool _status) internal {
        // solhint-disable-next-line reason-string
        require(_receiver != address(0), "Odos_Storage_Module: Zero address");
        if (_status) {
            getOdosCommonStorage().allowedReceivers.add(_receiver);
        } else {
            getOdosCommonStorage().allowedReceivers.remove(_receiver);
        }
    }

    // --------- Views ---------

    /**
     * @notice  Returns all allowed Executors
     */
    function getAllowedExecutors() external view returns (address[] memory) {
        return getOdosCommonStorage().allowedExecutors.values();
    }

    /**
     * @notice  Returns all allowed Receivers
     */
    function getAllowedReceivers() external view returns (address[] memory) {
        return getOdosCommonStorage().allowedReceivers.values();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../external/odos_interfaces/IOdosRouter.sol";
import "../storage/Odos_Common_Storage.sol";

/**
 * @title   Vaultus Odos V3 Swap Module Interface
 * @notice  Allows swapping via the OdosRouter contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IOdos_V3Swap_Module {
    // ---------- Functions ----------

    function odos_v3_swap(
        uint256 valueIn,
        IOdosRouter.inputToken[] memory inputs,
        IOdosRouter.outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../storage/Odos_Common_Storage.sol";
import "../../../external/odos_interfaces/IOdosRouter.sol";

/**
 * @title   Vaultus Odos V3 Swap Base
 * @notice  Allows swapping via the OdosRouter contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Odos_V3Swap_Base is AccessControl, ReentrancyGuard, Odos_Common_Storage {
    // solhint-disable var-name-mixedcase

    /// @notice Odos router address
    IOdosRouter public immutable odos_router;

    /**
     * @notice  Sets the address of the Odos router
     * @param   _odos_router    Odos router address
     */
    constructor(address _odos_router) {
        // solhint-disable-next-line reason-string
        require(_odos_router != address(0), "Odos_V3Swap_Base: Zero address");
        odos_router = IOdosRouter(_odos_router);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /**
     * @notice  Performs a swap via the Odos router
     * @dev     This function uses the Odos router
     * @param   valueIn         Msg.value to send with the swap
     * @param   inputs          List of input token structs for the path being executed
     * @param   outputs         List of output token structs for the path being executed
     * @param   valueOutQuote   Value of destination tokens quoted for the path
     * @param   valueOutMin     Minimum amount of value out the user will accept
     * @param   executor        Address of contract that will execute the path
     * @param   pathDefinition  Encoded path definition for executor
     */
    function odos_v3_swap(
        uint256 valueIn,
        IOdosRouter.inputToken[] memory inputs,
        IOdosRouter.outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_odos_v3_swap(valueIn, inputs, outputs, valueOutQuote, valueOutMin, executor, pathDefinition);
        odos_router.swap{ value: valueIn }(inputs, outputs, valueOutQuote, valueOutMin, executor, pathDefinition);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    /**
     * @notice  Validates inputs for odos_v3_swap
     * @param   valueIn         Msg.value to send with the swap
     * @param   inputs          List of input token structs for the path being executed
     * @param   outputs         List of output token structs for the path being executed
     * @param   valueOutQuote   Value of destination tokens quoted for the path
     * @param   valueOutMin     Minimum amount of value out the user will accept
     * @param   executor        Address of contract that will execute the path
     * @param   pathDefinition  Encoded path definition for executor
     */
    function inputGuard_odos_v3_swap(
        uint256 valueIn,
        IOdosRouter.inputToken[] memory inputs,
        IOdosRouter.outputToken[] memory outputs,
        uint256 valueOutQuote,
        uint256 valueOutMin,
        address executor,
        bytes calldata pathDefinition
    ) internal virtual {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IOdos_V3Swap_Module.sol";

/**
 * @title   Vaultus Odos V3 Swap Cutter
 * @notice  Cutter to enable diamonds contract to call Odos v3 Swap functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Odos_V3Swap_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IOdos_V3Swap_Module functions
     * @param   _facet  Odos_V3Swap_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Odos_V3Swap_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](1);

        selectors[selectorIndex++] = IOdos_V3Swap_Module.odos_v3_swap.selector;

        _setSupportsInterface(type(IOdos_V3Swap_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./Odos_V3Swap_Base.sol";
import "../../vaultus/Vaultus_Trader_Storage.sol";
import "../../../external/camelot_interfaces/INonfungiblePositionManager.sol";

/**
 * @title   Vaultus Camelot V3 Swap Module
 * @notice  Allows swapping via the OdosRouter contract
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Odos_V3Swap_Module is Odos_V3Swap_Base, Vaultus_Trader_Storage {
    /**
     * @notice  Sets the address of the Algebra position manager and Odos router
     * @param   _odos_router        Odos router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _odos_router) Odos_V3Swap_Base(_odos_router) {}

    // ---------- Input Guards ----------

    /// @inheritdoc Odos_V3Swap_Base
    function inputGuard_odos_v3_swap(
        uint256, // valueIn
        IOdosRouter.inputToken[] memory inputs,
        IOdosRouter.outputToken[] memory outputs,
        uint256 valueOutQuote, // valueOutQuote
        uint256, // valueOutMin
        address executor, // executor
        bytes calldata // pathDefinition
    ) internal view override {
        // solhint-disable-next-line reason-string
        require(valueOutQuote == type(uint256).max, "GuardError: Invalid valueOutQuote");
        validateExecutor(executor);
        uint256 len = inputs.length;
        for (uint i; i < len; ) {
            if (inputs[i].receiver != executor) validateReceiver(inputs[i].receiver);
            if (inputs[i].tokenAddress != address(0)) validateToken(inputs[i].tokenAddress);
            unchecked {
                ++i;
            }
        }
        len = outputs.length;
        for (uint i; i < len; ) {
            if (outputs[i].tokenAddress != address(0)) validateToken(outputs[i].tokenAddress);
            require(outputs[i].receiver == address(this), "GuardError: Invalid recipient");
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { TokenInput, ApproxParams, LimitOrderData, TokenOutput } from "../../../external/pendle_interfaces/IPAllActionV3.sol";

/**
 * @title   Vaultus Pendle Module Interface
 * @notice  Allows direct interacting with the Pendle Router contract
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
interface IPendle_Module {
    // ---------- Functions ----------
    function approve(address _token, address _spender, uint256 _amount) external;

    function pendle_addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external;

    function pendle_addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external;

    function pendle_addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy,
        LimitOrderData calldata limit
    ) external;

    function pendle_addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external;

    function pendle_addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external;

    function pendle_addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput calldata input
    ) external;

    function pendle_addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) external;

    function pendle_removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        uint256 minPtOut
    ) external;

    function pendle_removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) external;

    function pendle_removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external;

    function pendle_removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external;

    function pendle_removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactSyForPt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactPtForSy(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactYtForToken(
        address receiver,
        address market,
        uint256 exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external;

    function pendle_swapExactPtForYt(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minYtOut,
        ApproxParams calldata guessTotalPtToSwap
    ) external;

    function pendle_swapExactYtForPt(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minPtOut,
        ApproxParams calldata guessTotalPtFromSwap
    ) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_mintSyFromToken(address receiver, address SY, uint256 minSyOut, TokenInput calldata input) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_redeemSyToToken(address receiver, address SY, uint256 netSyIn, TokenOutput calldata output) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_mintPyFromToken(address receiver, address YT, uint256 minPyOut, TokenInput calldata input) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_redeemPyToToken(address receiver, address YT, uint256 netPyIn, TokenOutput calldata output) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_mintPyFromSy(address receiver, address YT, uint256 netSyIn, uint256 minPyOut) external;

    // solhint-disable-next-line var-name-mixedcase
    function pendle_redeemPyToSy(address receiver, address YT, uint256 netPyIn, uint256 minSyOut) external;

    function pendle_redeemDueInterestAndRewards(
        address user,
        address[] calldata sys,
        address[] calldata yts,
        address[] calldata markets
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// solhint-disable-next-line max-line-length
import { IPAllActionV3, TokenInput, ApproxParams, LimitOrderData, TokenOutput } from "../../../external/pendle_interfaces/IPAllActionV3.sol";

import { Vaultus_Trader_Storage } from "../../vaultus/Vaultus_Trader_Storage.sol";
import { Pendle_Common_Storage } from "../storage/Pendle_Common_Storage.sol";

/**
 * @title   Vaultus Pendle Base
 * @notice  Allows all Pendle V3 Router functions to be called by the inheriting contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that every input and output tokens are acceptable.
 *              2. Inheritor MUST ensure that every contract address is acceptable.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *              5. Inheritor MAY enforce any criteria on amounts if desired.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
abstract contract Pendle_Base is AccessControl, ReentrancyGuard, Vaultus_Trader_Storage, Pendle_Common_Storage {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    //solhint-disable var-name-mixedcase

    /// @notice The pendle router address
    IPAllActionV3 public immutable pendle_router;

    constructor(address _pendle_router) {
        if (_pendle_router == address(0)) revert Pendle_Base_ZeroAddress();
        pendle_router = IPAllActionV3(_pendle_router);
    }

    // ---------- Functions ----------
    // solhint-enable var-name-mixedcase

    /**
     * @notice  Approve a whitelisted spender to handle one of the whitelisted tokens
     * @param   _token      Token to set approval for
     * @param   _spender    Spending address
     * @param   _amount     Token amount
     */
    function approve(address _token, address _spender, uint256 _amount) external virtual onlyRole(EXECUTOR_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        PendleCommonStorage storage p = getPendleCommonStorage();

        if (!(s.allowedTokens.contains(_token))) {
            require(p.allowedPendleTokens.contains(_token), "!token");
            validatePendleRouter(_spender);
        } else {
            require(s.allowedTokens.contains(_token), "!token");
            require(s.allowedSpenders.contains(_spender), "!spender");
        }

        IERC20(_token).approve(_spender, _amount);
    }

    // Liquidity
    /**
     * @notice  Adds liquidity to a market using both Yield-bearing Tokens and Principal Tokens
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   input            Token input details
     * @param   netPtDesired     Desired amount of Principal tokens
     * @param   minLpOut         Minimum amount of LP receipt tokens to receive
     */
    function pendle_addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquidityDualTokenAndPt(receiver, market, input, netPtDesired, minLpOut);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.addLiquidityDualTokenAndPt{ value: valueToPass }(receiver, market, input, netPtDesired, minLpOut);
    }

    /**
     * @notice  Adds liquidity to a market using both Standardized Yield and Principal tokens
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netSyDesired     Desired amount of Standardized Yield tokens
     * @param   netPtDesired     Desired amount of Principal tokens
     * @param   minLpOut         Minimum amount of LP receipt tokens to receive
     */
    function pendle_addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquidityDualSyAndPt(receiver, market, netSyDesired, netPtDesired, minLpOut);
        pendle_router.addLiquidityDualSyAndPt(receiver, market, netSyDesired, netPtDesired, minLpOut);
    }

    /**
     * @notice  Adds liquidity to a market using a Principal token
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netPtIn          Amount of Principal tokens to supply
     * @param   minLpOut         Minimum amount of LP receipt tokens to receive
     * @param   guessPtSwapToSy  Approximation parameters for swapping Principal token to Standardized Yield token
     * @param   limit            Limit order data
     */
    function pendle_addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquiditySinglePt(receiver, market, netPtIn, minLpOut, guessPtSwapToSy, limit);
        pendle_router.addLiquiditySinglePt(receiver, market, netPtIn, minLpOut, guessPtSwapToSy, limit);
    }

    /**
     * @notice  Adds liquidity to a market using a single Yield-bearing token
     * @param   receiver                Address of the receiver
     * @param   market                  Address of the market
     * @param   minLpOut                Minimum amount of LP receipt tokens to receive
     * @param   guessPtReceivedFromSy   Approximation parameters for guessing the amount of PT tokens received from SY tokens
     * @param   input                   Token input details
     * @param   limit                   Limit order data
     */
    function pendle_addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquiditySingleToken(receiver, market, minLpOut, guessPtReceivedFromSy, input, limit);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.addLiquiditySingleToken{ value: valueToPass }(receiver, market, minLpOut, guessPtReceivedFromSy, input, limit);
    }

    /**
     * @notice  Adds liquidity to a market using a single Standardized Yield token
     * @param   receiver                Address of the receiver
     * @param   market                  Address of the market
     * @param   netSyIn                 Amount of Standardized Yield tokens to supply
     * @param   minLpOut                Amount of LP receipt tokens to receive
     * @param   guessPtReceivedFromSy   Parameters for guessing the amount of Principal tokens received from Standardized Yield tokens
     * @param   limit                   Limit order data
     */
    function pendle_addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquiditySingleSy(receiver, market, netSyIn, minLpOut, guessPtReceivedFromSy, limit);
        pendle_router.addLiquiditySingleSy(receiver, market, netSyIn, minLpOut, guessPtReceivedFromSy, limit);
    }

    /**
     * @notice  Adds liquidity to a market using a single Yield-bearing token while keeping the Yield token
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   minLpOut         Minimum amount of LP receipt tokens to receive
     * @param   minYtOut         Minimum amount of Yield tokens to receive
     * @param   input            Token input details
     */
    function pendle_addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput calldata input
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquiditySingleTokenKeepYt(receiver, market, minLpOut, minYtOut, input);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.addLiquiditySingleTokenKeepYt{ value: valueToPass }(receiver, market, minLpOut, minYtOut, input);
    }

    /**
     * @notice  Adds liquidity to a market using a single Standardized Yield token while keeping the Yield token
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netSyIn          Amount of Standardized Yield tokens to supply
     * @param   minLpOut         Minimum amount of LP receipt tokens to receive
     * @param   minYtOut         Minimum amount of Yield tokens to receive
     */
    function pendle_addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_addLiquiditySingleSyKeepYt(receiver, market, netSyIn, minLpOut, minYtOut);
        pendle_router.addLiquiditySingleSyKeepYt(receiver, market, netSyIn, minLpOut, minYtOut);
    }

    /**
     * @notice  Withdraws liquidity from a market receiving both Yield-bearing token and Principal token in return
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netLpToRemove    Amount of LP receipt tokens to withdraw
     * @param   output           Token output details
     * @param   minPtOut         Minimum amount of Principal tokens to receive
     */
    function pendle_removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        uint256 minPtOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_removeLiquidityDualTokenAndPt(receiver, market, netLpToRemove, output, minPtOut);
        pendle_router.removeLiquidityDualTokenAndPt(receiver, market, netLpToRemove, output, minPtOut);
    }

    /**
     * @notice  Withdraws liquidity from a market receiving both Standardized Yield and Principal tokens in return
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netLpToRemove    Amount of LP receipt tokens to withdraw
     * @param   minSyOut         Minimum amount of Standardized Yield tokens to receive
     * @param   minPtOut         Minimum amount of Principal tokens to receive
     */
    function pendle_removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_removeLiquidityDualSyAndPt(receiver, market, netLpToRemove, minSyOut, minPtOut);
        pendle_router.removeLiquidityDualSyAndPt(receiver, market, netLpToRemove, minSyOut, minPtOut);
    }

    /**
     * @notice  Withdraws liquidity from a market receiving a single Principal token in return
     * @param   receiver                Address of the receiver
     * @param   market                  Address of the market
     * @param   netLpToRemove           Amount of LP receipt tokens to withdraw
     * @param   minPtOut                Minimum amount of Principal tokens to receive
     * @param   guessPtReceivedFromSy   Approximation parameters for guessing the amount of PT tokens received from SY tokens
     * @param   limit                   Limit order data
     */
    function pendle_removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_removeLiquiditySinglePt(receiver, market, netLpToRemove, minPtOut, guessPtReceivedFromSy, limit);
        pendle_router.removeLiquiditySinglePt(receiver, market, netLpToRemove, minPtOut, guessPtReceivedFromSy, limit);
    }

    /**
     * @notice  Withdraws liquidity from a market receiving a single Yield-bearing token in return
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netLpToRemove    Amount of LP receipt tokens to withdraw
     * @param   output           Token output details
     * @param   limit            Limit order data
     */
    function pendle_removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_removeLiquiditySingleToken(receiver, market, netLpToRemove, output, limit);
        pendle_router.removeLiquiditySingleToken(receiver, market, netLpToRemove, output, limit);
    }

    /**
     * @notice  Withdraws liquidity from a market receiving a single Standardized Yield token in return
     * @param   receiver         Address of the receiver
     * @param   market           Address of the market
     * @param   netLpToRemove    Amount of LP receipt tokens to withdraw
     * @param   minSyOut         Minimum amount of Standardized Yield tokens to receive
     * @param   limit            Limit order data
     */
    function pendle_removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_removeLiquiditySingleSy(receiver, market, netLpToRemove, minSyOut, limit);
        pendle_router.removeLiquiditySingleSy(receiver, market, netLpToRemove, minSyOut, limit);
    }

    // Swap

    /**
     * @notice  Swaps an exact amount of Yield-bearing Token for Principal token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   minPtOut        Minimum amount of Principal tokens to receive
     * @param   guessPtOut      Approximation parameters for guessing the amount of Principal tokens received
     * @param   input           Token input details
     * @param   limit           Limit order data
     */
    function pendle_swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactTokenForPt(receiver, market, minPtOut, guessPtOut, input, limit);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.swapExactTokenForPt{ value: valueToPass }(receiver, market, minPtOut, guessPtOut, input, limit);
    }

    /**
     * @notice  Swaps an exact amount of Standardized Yield token for Principal token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   exactSyIn       Exact amount of Standardized Yield tokens to swap
     * @param   minPtOut        Minimum amount of Principal tokens to receive
     * @param   guessPtOut      Approximation parameters for guessing the amount of Principal tokens received
     * @param   limit           Limit order data
     */
    function pendle_swapExactSyForPt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactSyForPt(receiver, market, exactSyIn, minPtOut, guessPtOut, limit);
        pendle_router.swapExactSyForPt(receiver, market, exactSyIn, minPtOut, guessPtOut, limit);
    }

    /**
     * @notice  Swaps an exact amount of Principal token for Yield-bearing token
     * @param   receiver       Address of the receiver
     * @param   market         Address of the market
     * @param   exactPtIn      Exact amount of Principal tokens to swap
     * @param   output         Output token data
     * @param   limit          Limit order data
     */
    function pendle_swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactPtForToken(receiver, market, exactPtIn, output, limit);
        pendle_router.swapExactPtForToken(receiver, market, exactPtIn, output, limit);
    }

    /**
     * @notice  Swaps an exact amount of Principal token for Standardized Yield token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   exactPtIn       Exact amount of Principal tokens to swap
     * @param   minSyOut        Minimum amount of Standardized Yield tokens to receive
     * @param   limit           Limit order data
     */
    function pendle_swapExactPtForSy(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactPtForSy(receiver, market, exactPtIn, minSyOut, limit);
        pendle_router.swapExactPtForSy(receiver, market, exactPtIn, minSyOut, limit);
    }

    /**
     * @notice  Swaps an exact amount of Yield-bearing token for Yield token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   minYtOut        Minimum amount of Yield tokens to receive
     * @param   guessYtOut      Approximate amount of Yield tokens to receive
     * @param   input           Token input data
     * @param   limit           Limit order data
     */
    function pendle_swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactTokenForYt(receiver, market, minYtOut, guessYtOut, input, limit);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.swapExactTokenForYt{ value: valueToPass }(receiver, market, minYtOut, guessYtOut, input, limit);
    }

    /**
     * @notice  Swaps an exact amount of Standardized Yield token for Yield token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   exactSyIn       Exact amount of Standardized Yield tokens to swap
     * @param   minYtOut        Minimum amount of Yield tokens to receive
     * @param   guessYtOut      Approximate amount of Yield tokens to receive
     * @param   limit           Limit order data
     */
    function pendle_swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactSyForYt(receiver, market, exactSyIn, minYtOut, guessYtOut, limit);
        pendle_router.swapExactSyForYt(receiver, market, exactSyIn, minYtOut, guessYtOut, limit);
    }

    /**
     * @notice  Swaps an exact amount of Yield token for Yield-bearing token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   exactYtIn       Exact amount of Yield tokens to swap
     * @param   output          Token output data
     * @param   limit           Limit order data
     */
    function pendle_swapExactYtForToken(
        address receiver,
        address market,
        uint256 exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactYtForToken(receiver, market, exactYtIn, output, limit);
        pendle_router.swapExactYtForToken(receiver, market, exactYtIn, output, limit);
    }

    /**
     * @notice  Swaps an exact amount of Yield token for Standardized Yield token
     * @param   receiver        Address of the receiver
     * @param   market          Address of the market
     * @param   exactYtIn       Exact amount of Yield tokens to swap
     * @param   minSyOut        Minimum amount of Standardized Yield tokens to receive
     * @param   limit           Limit order data
     */
    function pendle_swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactYtForSy(receiver, market, exactYtIn, minSyOut, limit);
        pendle_router.swapExactYtForSy(receiver, market, exactYtIn, minSyOut, limit);
    }

    /**
     * @notice  Swaps an exact amount of Principal token for Yield token
     * @param   receiver                Address of the receiver
     * @param   market                  Address of the market
     * @param   exactPtIn               Exact amount of Principal tokens to swap
     * @param   minYtOut                Minimum amount of Yield tokens to receive
     * @param   guessTotalPtToSwap      Approximate total amount of Principal tokens to swap
     */
    function pendle_swapExactPtForYt(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minYtOut,
        ApproxParams calldata guessTotalPtToSwap
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactPtForYt(receiver, market, exactPtIn, minYtOut, guessTotalPtToSwap);
        pendle_router.swapExactPtForYt(receiver, market, exactPtIn, minYtOut, guessTotalPtToSwap);
    }

    /**
     * @notice  Swaps an exact amount of Yield token for Principal token
     * @param   receiver                Address of the receiver
     * @param   market                  Address of the market
     * @param   exactYtIn               Exact amount of Yield tokens to swap
     * @param   minPtOut                Minimum amount of Principal tokens to receive
     * @param   guessTotalPtFromSwap    Approximate total amount of Principal tokens from swap
     */
    function pendle_swapExactYtForPt(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minPtOut,
        ApproxParams calldata guessTotalPtFromSwap
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_swapExactYtForPt(receiver, market, exactYtIn, minPtOut, guessTotalPtFromSwap);
        pendle_router.swapExactYtForPt(receiver, market, exactYtIn, minPtOut, guessTotalPtFromSwap);
    }

    // --------- Misc ---------
    // solhint-disable var-name-mixedcase

    /**
     * @notice  Mints Standardized Yield tokens in exchange for Yield-bearing token
     * @param   receiver        Address of the receiver
     * @param   SY              Address of the Standardized Yield token
     * @param   minSyOut        Minimum amount of Standardized Yield tokens to mint
     * @param   input           Token input data
     */
    function pendle_mintSyFromToken(
        address receiver,
        address SY,
        uint256 minSyOut,
        TokenInput calldata input
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_mintSyFromToken(receiver, SY, minSyOut, input);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.mintSyFromToken{ value: valueToPass }(receiver, SY, minSyOut, input);
    }

    /**
     * @notice  Reedems Yield-bearing token in exchange for Standardized Yield tokens
     * @param   receiver        Address of the receiver
     * @param   SY              Address of the Standardized Yield token
     * @param   netSyIn         Amount of Standardized Yield tokens to redeem
     * @param   output          Token output data
     */
    function pendle_redeemSyToToken(
        address receiver,
        address SY,
        uint256 netSyIn,
        TokenOutput calldata output
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_redeemSyToToken(receiver, SY, netSyIn, output);
        pendle_router.redeemSyToToken(receiver, SY, netSyIn, output);
    }

    /**
     * @notice  Mints Principal and Yield tokens in exchange for Yield-bearing token
     * @param   receiver        Address of the receiver
     * @param   YT              Address of the Yield token
     * @param   minPyOut        Minimum amount of Principal tokens to mint
     * @param   input           Token input data
     */
    function pendle_mintPyFromToken(
        address receiver,
        address YT,
        uint256 minPyOut,
        TokenInput calldata input
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_mintPyFromToken(receiver, YT, minPyOut, input);
        uint256 valueToPass = input.tokenIn == address(0) ? input.netTokenIn : 0;
        pendle_router.mintPyFromToken{ value: valueToPass }(receiver, YT, minPyOut, input);
    }

    /**
     * @notice  Reedems Yield-bearing token in exchange for Principal and Yield tokens
     * @param   receiver        Address of the receiver
     * @param   YT              Address of the Yield token
     * @param   netPyIn         Amount of Principal tokens to redeem
     * @param   output          Token output data
     */
    function pendle_redeemPyToToken(
        address receiver,
        address YT,
        uint256 netPyIn,
        TokenOutput calldata output
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_redeemPyToToken(receiver, YT, netPyIn, output);
        pendle_router.redeemPyToToken(receiver, YT, netPyIn, output);
    }

    /**
     * @notice  Mints Principal and Yield tokens in exchange for Standardized Yield token
     * @param   receiver        Address of the receiver
     * @param   YT              Address of the Yield token
     * @param   netSyIn         Amount of Standardized Yield tokens to mint from
     * @param   minPyOut        Minimum amount of Principal tokens to mint
     */
    function pendle_mintPyFromSy(
        address receiver,
        address YT,
        uint256 netSyIn,
        uint256 minPyOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_mintPyFromSy(receiver, YT, netSyIn, minPyOut);
        pendle_router.mintPyFromSy(receiver, YT, netSyIn, minPyOut);
    }

    /**
     * @notice  Reedems Principal and Yield tokens in exchange for Standardized Yield tokens
     * @param   receiver        Address of the receiver
     * @param   YT              Address of the Yield token
     * @param   netPyIn         Amount of Principal tokens to redeem
     * @param   minSyOut        Minimum amount of Standardized Yield tokens to redeem to
     */
    function pendle_redeemPyToSy(
        address receiver,
        address YT,
        uint256 netPyIn,
        uint256 minSyOut
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_redeemPyToSy(receiver, YT, netPyIn, minSyOut);
        pendle_router.redeemPyToSy(receiver, YT, netPyIn, minSyOut);
    }

    /**
     * @notice  Redeem the accrued interest and rewards from both the LP position and Yield Tokens
     * @param   user            Address of the user
     * @param   sys             Array of Standardized Yield token addresses
     * @param   yts             Array of Yield token addresses
     * @param   markets         Array of market addresses
     */
    function pendle_redeemDueInterestAndRewards(
        address user,
        address[] calldata sys,
        address[] calldata yts,
        address[] calldata markets
    ) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        inputGuard_pendle_redeemDueInterestAndRewards(user, sys, yts, markets);
        pendle_router.redeemDueInterestAndRewards(user, sys, yts, markets);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    // Liquidity

    function inputGuard_pendle_addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256 netPtDesired,
        uint256 minLpOut
    ) internal virtual {}

    function inputGuard_pendle_addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netSyDesired,
        uint256 netPtDesired,
        uint256 minLpOut
    ) internal virtual {}

    function inputGuard_pendle_addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_addLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256 minLpOut,
        uint256 minYtOut,
        TokenInput calldata input
    ) internal virtual {}

    function inputGuard_pendle_addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256 netSyIn,
        uint256 minLpOut,
        uint256 minYtOut
    ) internal virtual {}

    function inputGuard_pendle_removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        uint256 minPtOut
    ) internal virtual {}

    function inputGuard_pendle_removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        uint256 minPtOut
    ) internal virtual {}

    function inputGuard_pendle_removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) internal virtual {}

    // Swap

    function inputGuard_pendle_swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactSyForPt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactPtForSy(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactYtForToken(
        address receiver,
        address market,
        uint256 exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut,
        LimitOrderData calldata limit
    ) internal virtual {}

    function inputGuard_pendle_swapExactPtForYt(
        address receiver,
        address market,
        uint256 exactPtIn,
        uint256 minYtOut,
        ApproxParams calldata guessTotalPtToSwap
    ) internal virtual {}

    function inputGuard_pendle_swapExactYtForPt(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minPtOut,
        ApproxParams calldata guessTotalPtFromSwap
    ) internal virtual {}

    // Misc
    // solhint-disable var-name-mixedcase

    function inputGuard_pendle_mintSyFromToken(
        address receiver,
        address SY,
        uint256 minSyOut,
        TokenInput calldata input
    ) internal virtual {}

    function inputGuard_pendle_redeemSyToToken(
        address receiver,
        address SY,
        uint256 netSyIn,
        TokenOutput calldata output
    ) internal virtual {}

    function inputGuard_pendle_mintPyFromToken(
        address receiver,
        address YT,
        uint256 minPyOut,
        TokenInput calldata input
    ) internal virtual {}

    function inputGuard_pendle_redeemPyToToken(
        address receiver,
        address YT,
        uint256 netPyIn,
        TokenOutput calldata output
    ) internal virtual {}

    function inputGuard_pendle_mintPyFromSy(address receiver, address YT, uint256 netSyIn, uint256 minPyOut) internal virtual {}

    function inputGuard_pendle_redeemPyToSy(address receiver, address YT, uint256 netPyIn, uint256 minSyOut) internal virtual {}

    function inputGuard_pendle_redeemDueInterestAndRewards(
        address user,
        address[] calldata sys,
        address[] calldata yts,
        address[] calldata markets
    ) internal virtual {}

    // solhint-enable var-name-mixedcase

    // --------- Errors ---------

    error Pendle_Base_ZeroAddress();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { DiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import { ERC165Base } from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import { IPendle_Module } from "./IPendle_Module.sol";
import { ITraderV0 } from "../../../trader/ITraderV0.sol";

/**
 * @title   Vaultus Pendle Module Cutter
 * @notice  Cutter to enable diamonds contract to call Pendle functions
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
contract Pendle_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IPendle_Module functions
     * @param   _facet  Pendle_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        if (_facet == address(0)) revert Pendle_Cutter_InvalidFacetAddress();

        uint256 selectorIndex;
        // Register
        bytes4[] memory oldApprove = new bytes4[](1);
        oldApprove[0] = ITraderV0.approve.selector;

        bytes4[] memory selectors = new bytes4[](30);

        selectors[selectorIndex++] = IPendle_Module.approve.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquidityDualTokenAndPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquidityDualSyAndPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquiditySinglePt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquiditySingleToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquiditySingleSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquiditySingleTokenKeepYt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_addLiquiditySingleSyKeepYt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_removeLiquidityDualTokenAndPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_removeLiquidityDualSyAndPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_removeLiquiditySinglePt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_removeLiquiditySingleToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_removeLiquiditySingleSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactTokenForPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactSyForPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactPtForToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactPtForSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactTokenForYt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactSyForYt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactYtForToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactYtForSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactPtForYt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_swapExactYtForPt.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_mintSyFromToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_redeemSyToToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_mintPyFromToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_redeemPyToToken.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_mintPyFromSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_redeemPyToSy.selector;
        selectors[selectorIndex++] = IPendle_Module.pendle_redeemDueInterestAndRewards.selector;

        _setSupportsInterface(type(IPendle_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](2);
        facetCuts[0] = FacetCut({ target: address(0), action: FacetCutAction.REMOVE, selectors: oldApprove });
        facetCuts[1] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }

    // Error
    error Pendle_Cutter_InvalidFacetAddress();
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// solhint-disable-next-line max-line-length
import { TokenInput, ApproxParams, LimitOrderData, TokenOutput, Order, SwapType } from "../../../external/pendle_interfaces/IPAllActionV3.sol";
import { BytesLib } from "../../../external/uniswapv3_libraries/BytesLib.sol";
import { Path } from "../../../external/uniswapv3_libraries/Path.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { Vaultus_Trader_Storage } from "../../vaultus/Vaultus_Trader_Storage.sol";
import { Pendle_Base } from "./Pendle_Base.sol";

/**
 * @title   Vaultus Pendle Module
 * @notice  Allows interacting with the Pendle contract
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
contract Pendle_Module is Pendle_Base {
    using BytesLib for bytes;
    using Path for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice  Sets the address of the Pendle V3 router
     * @param   _router    Pendle V3 router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _router) Pendle_Base(_router) {}

    // ---------- Input Guards ----------

    function inputGuard_pendle_addLiquidityDualTokenAndPt(
        address receiver,
        address market,
        TokenInput calldata input,
        uint256, //netPtDesired,
        uint256 //minLpOut
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenInput(input);
    }

    function inputGuard_pendle_addLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256, // netSyDesired,
        uint256, // netPtDesired,
        uint256 // minLpOut
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
    }

    function inputGuard_pendle_addLiquiditySinglePt(
        address receiver,
        address market,
        uint256, //netPtIn,
        uint256, //minLpOut,
        ApproxParams calldata, //guessPtSwapToSy,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_addLiquiditySingleToken(
        address receiver,
        address market,
        uint256, //minLpOut,
        ApproxParams calldata, // guessPtReceivedFromSy,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenInput(input);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_addLiquiditySingleSy(
        address receiver,
        address market,
        uint256, // netSyIn,
        uint256, // minLpOut,
        ApproxParams calldata, // guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_addLiquiditySingleTokenKeepYt(
        address receiver,
        address market,
        uint256, // minLpOut,
        uint256, // minYtOut,
        TokenInput calldata input
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenInput(input);
    }

    function inputGuard_pendle_addLiquiditySingleSyKeepYt(
        address receiver,
        address market,
        uint256, // netSyIn,
        uint256, // minLpOut,
        uint256 // minYtOut
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
    }

    function inputGuard_pendle_removeLiquidityDualTokenAndPt(
        address receiver,
        address market,
        uint256, // netLpToRemove,
        TokenOutput calldata output,
        uint256 // minPtOut
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenOutput(output);
    }

    function inputGuard_pendle_removeLiquidityDualSyAndPt(
        address receiver,
        address market,
        uint256, // netLpToRemove,
        uint256, // minSyOut,
        uint256 // minPtOut
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
    }

    function inputGuard_pendle_removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256, // netLpToRemove,
        uint256, // minPtOut,
        ApproxParams calldata, // guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256, // netLpToRemove,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenOutput(output);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_removeLiquiditySingleSy(
        address receiver,
        address market,
        uint256, // netLpToRemove,
        uint256, // minSyOut,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactTokenForPt(
        address receiver,
        address market,
        uint256, // minPtOut,
        ApproxParams calldata, // guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenInput(input);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactSyForPt(
        address receiver,
        address market,
        uint256, //exactSyIn,
        uint256, // minPtOut,
        ApproxParams calldata, // guessPtOut,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactPtForToken(
        address receiver,
        address market,
        uint256, // exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenOutput(output);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactPtForSy(
        address receiver,
        address market,
        uint256, // exactPtIn,
        uint256, // minSyOut,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactTokenForYt(
        address receiver,
        address market,
        uint256, // minYtOut,
        ApproxParams calldata, // guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenInput(input);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactSyForYt(
        address receiver,
        address market,
        uint256, // exactSyIn,
        uint256, // minYtOut,
        ApproxParams calldata, // guessYtOut,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactYtForToken(
        address receiver,
        address market,
        uint256, // exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateTokenOutput(output);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactYtForSy(
        address receiver,
        address market,
        uint256, // exactYtIn,
        uint256, // minSyOut,
        LimitOrderData calldata limit
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
        validateLimitOrderData(limit);
    }

    function inputGuard_pendle_swapExactPtForYt(
        address receiver,
        address market,
        uint256, //exactPtIn,
        uint256, //minYtOut,
        ApproxParams calldata //guessTotalPtToSwap
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
    }

    function inputGuard_pendle_swapExactYtForPt(
        address receiver,
        address market,
        uint256, //exactYtIn,
        uint256, //minPtOut,
        ApproxParams calldata // guessTotalPtFromSwap
    ) internal virtual override {
        validateReceiver(receiver);
        validatePendleMarket(market);
    }

    // solhint-disable var-name-mixedcase

    function inputGuard_pendle_mintSyFromToken(
        address receiver,
        address SY,
        uint256, // minSyOut,
        TokenInput calldata input
    ) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(SY);
        validateTokenInput(input);
    }

    function inputGuard_pendle_redeemSyToToken(
        address receiver,
        address SY,
        uint256, //netSyIn,
        TokenOutput calldata output
    ) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(SY);
        validateTokenOutput(output);
    }

    function inputGuard_pendle_mintPyFromToken(
        address receiver,
        address YT,
        uint256, // minPyOut,
        TokenInput calldata input
    ) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(YT);
        validateTokenInput(input);
    }

    function inputGuard_pendle_redeemPyToToken(
        address receiver,
        address YT,
        uint256, //netPyIn,
        TokenOutput calldata output
    ) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(YT);
        validateTokenOutput(output);
    }

    function inputGuard_pendle_mintPyFromSy(address receiver, address YT, uint256, uint256) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(YT);
    }

    function inputGuard_pendle_redeemPyToSy(address receiver, address YT, uint256, uint256) internal virtual override {
        validateReceiver(receiver);
        validateThisToken(YT);
    }

    function inputGuard_pendle_redeemDueInterestAndRewards(
        address, // user,
        address[] calldata sys, //sys,
        address[] calldata yts, //yts,
        address[] calldata markets
    ) internal virtual override {
        for (uint256 i = 0; i < sys.length; i++) {
            validateThisToken(sys[i]);
        }

        for (uint256 i = 0; i < yts.length; i++) {
            validateThisToken(yts[i]);
        }

        for (uint256 i = 0; i < markets.length; i++) {
            validatePendleMarket(markets[i]);
        }
    }

    // solhint-enable var-name-mixedcase

    // ---------- Internal Helpers ----------

    function validateTokenInput(TokenInput calldata input) internal view {
        validateThisToken(input.tokenIn);
        validateThisToken(input.tokenMintSy);
        validatePendleRouter(input.pendleSwap);
        validateSwapType(input.swapData.swapType);
    }

    function validateTokenOutput(TokenOutput calldata output) internal view {
        validateThisToken(output.tokenOut);
        validateThisToken(output.tokenRedeemSy);
        validatePendleRouter(output.pendleSwap);
        validateSwapType(output.swapData.swapType);
    }

    function validateLimitOrderData(LimitOrderData calldata limit) internal view {
        validatePendleRouter(limit.limitRouter);

        for (uint256 i = 0; i < limit.normalFills.length; i++) {
            validateOrder(limit.normalFills[i].order);
        }

        for (uint256 i = 0; i < limit.flashFills.length; i++) {
            validateOrder(limit.flashFills[i].order);
        }
    }

    function validateOrder(Order calldata order) internal view {
        validateThisToken(order.token);
        validateThisToken(order.YT);
        validateReceiver(order.receiver);
    }

    function validateReceiver(address receiver) internal view {
        if (receiver != address(this)) {
            revert Pendle_Module_InvalidReceiver();
        }
    }

    function validateSwapType(SwapType swapType) internal pure {
        if (swapType != SwapType.NONE && swapType != SwapType.ETH_WETH) revert Pendle_Module_InvalidSwapType();
    }

    function validateThisToken(address _token) internal view {
        TraderV0Storage storage s = getTraderV0Storage();
        if (!(s.allowedTokens.contains(_token))) {
            validatePendleToken(_token);
        }
    }

    // ---------- Errors ----------

    error Pendle_Module_InvalidReceiver();
    error Pendle_Module_InvalidSwapType();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IPendle_Storage_Module {
    // --------- External Functions ---------

    function managePendleMarkets(address[] calldata _markets, bool[] calldata _status) external;

    function managePendleTokens(address[] calldata _markets, bool[] calldata _status) external;

    function managePendleRouters(address[] calldata _routers, bool[] calldata _status) external;

    // --------- Getter Functions ---------

    function getAllowedPendleMarkets() external view returns (address[] memory);

    function getAllowedPendleTokens() external view returns (address[] memory);

    function getAllowedPendleRouters() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Vaultus_Common_Roles } from "../../vaultus/Vaultus_Common_Roles.sol";

/**
 * @title   Vaultus Pendle Common Storage
 * @notice  Protocol addresses and constants used by Pendle modules
 * @author  Vaultus Finance
 * @custom:developer    zug
 */

abstract contract Pendle_Common_Storage is Vaultus_Common_Roles {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PendleCommonStorage {
        /// @notice Set of allowed Pendle V3 markets
        EnumerableSet.AddressSet allowedPendleMarkets;
        /// @notice Set of allowed Pendle V3 tokens
        EnumerableSet.AddressSet allowedPendleTokens;
        /// @notice Set of allowed Pendle V3 routers
        EnumerableSet.AddressSet allowedPendleRouters;
    }

    /// @dev    EIP-2535 Diamond Storage struct location
    bytes32 internal constant PENDLE_POSITION = bytes32(uint256(keccak256("Pendle_Common.storage")) - 1);

    function getPendleCommonStorage() internal pure returns (PendleCommonStorage storage storageStruct) {
        bytes32 position = PENDLE_POSITION;
        // solhint-disable no-inline-assembly
        assembly {
            storageStruct.slot := position
        }
    }

    // --------- Internal Functions ---------

    /**
     * @notice  Validates a Pendle V3 market
     * @param   _market   Market address
     */
    function validatePendleMarket(address _market) internal view {
        if (!getPendleCommonStorage().allowedPendleMarkets.contains(_market)) revert Pendle_Common_Storage_InvalidPendleMarket();
    }

    /**
     * @notice  Validates a Pendle V3 token
     * @param   _token   Pendle Token address
     */
    function validatePendleToken(address _token) internal view {
        if (!getPendleCommonStorage().allowedPendleTokens.contains(_token)) revert Pendle_Common_Storage_InvalidPendleToken();
    }

    /**
     * @notice Validates a Pendle V3 Limit Router
     * @param _router   Router address
     */
    function validatePendleRouter(address _router) internal view {
        if (!getPendleCommonStorage().allowedPendleRouters.contains(_router)) revert Pendle_Common_Storage_InvalidPendleRouter();
    }

    // Errors
    error Pendle_Common_Storage_InvalidPendleMarket();
    error Pendle_Common_Storage_InvalidPendleToken();
    error Pendle_Common_Storage_InvalidPendleRouter();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IPendle_Storage_Module.sol";

/**
 * @title   Vaultus Pendle Storage Cutter
 * @notice  Cutter to enable diamonds contract to call Pendle storage functions
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
contract Pendle_Storage_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IPendle_Storage_Module functions
     * @param   _facet  Pendle_Storage_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        if (_facet == address(0)) revert Pendle_Storage_Cutter_InvalidFacetAddress();

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](6);

        selectors[selectorIndex++] = IPendle_Storage_Module.managePendleMarkets.selector;
        selectors[selectorIndex++] = IPendle_Storage_Module.managePendleTokens.selector;
        selectors[selectorIndex++] = IPendle_Storage_Module.managePendleRouters.selector;

        selectors[selectorIndex++] = IPendle_Storage_Module.getAllowedPendleMarkets.selector;
        selectors[selectorIndex++] = IPendle_Storage_Module.getAllowedPendleTokens.selector;
        selectors[selectorIndex++] = IPendle_Storage_Module.getAllowedPendleRouters.selector;

        _setSupportsInterface(type(IPendle_Storage_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }

    // Error
    error Pendle_Storage_Cutter_InvalidFacetAddress();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { Pendle_Common_Storage } from "./Pendle_Common_Storage.sol";

/**
 * @title   Vaultus Pendle Storage Module
 * @notice  Manage Pendle storage
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    zug
 */
contract Pendle_Storage_Module is AccessControl, Pendle_Common_Storage {
    // solhint-disable var-name-mixedcase
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Adds or removes batch of markets to the set of allowed markets
     * @param _markets  Array of market addresses
     * @param _status   Array of statuses
     */
    function managePendleMarkets(address[] calldata _markets, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        if (_markets.length != _status.length) revert Pendle_Storage_Module_LengthMismatch();
        for (uint256 i; i < _markets.length; ) {
            _managePendleMarket(_markets[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a market from the set of allowed markets
     * @param _market   Market address
     * @param _status   Status
     */
    function _managePendleMarket(address _market, bool _status) internal {
        if (_status) {
            getPendleCommonStorage().allowedPendleMarkets.add(_market);
        } else {
            getPendleCommonStorage().allowedPendleMarkets.remove(_market);
        }
    }

    /**
     * @notice Adds or removes batch of tokens to the set of Pendle allowed tokens
     * @param _tokens  Array of Pendle token addresses
     * @param _status   Array of statuses
     */
    function managePendleTokens(address[] calldata _tokens, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        if (_tokens.length != _status.length) revert Pendle_Storage_Module_LengthMismatch();
        for (uint256 i; i < _tokens.length; ) {
            _managePendleToken(_tokens[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a token from the set of Pendle allowed tokens
     * @param _token    Pendle token address
     * @param _status   Status
     */
    function _managePendleToken(address _token, bool _status) internal {
        if (_status) {
            getPendleCommonStorage().allowedPendleTokens.add(_token);
        } else {
            getPendleCommonStorage().allowedPendleTokens.remove(_token);
        }
    }

    /**
     * @notice Adds or removes batch of routers to the set of allowed routers
     * @param _routers  Array of router
     * @param _status   Array of statuses
     */
    function managePendleRouters(address[] calldata _routers, bool[] calldata _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //solhint-disable-next-line reason-string
        if (_routers.length != _status.length) revert Pendle_Storage_Module_LengthMismatch();
        for (uint256 i; i < _routers.length; ) {
            _managePendleRouter(_routers[i], _status[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function to add or remove a router from the set of allowed routers
     * @param _router   Router address
     * @param _status   Status
     */
    function _managePendleRouter(address _router, bool _status) internal {
        if (_status) {
            getPendleCommonStorage().allowedPendleRouters.add(_router);
        } else {
            getPendleCommonStorage().allowedPendleRouters.remove(_router);
        }
    }

    // ---------- External View Functions ----------

    /**
     * @notice Returns all allowed Markets
     */
    function getAllowedPendleMarkets() external view returns (address[] memory) {
        return getPendleCommonStorage().allowedPendleMarkets.values();
    }

    /**
     * @notice Returns all allowed Markets
     */
    function getAllowedPendleTokens() external view returns (address[] memory) {
        return getPendleCommonStorage().allowedPendleTokens.values();
    }

    /**
     * @notice Returns all allowed Routers
     */
    function getAllowedPendleRouters() external view returns (address[] memory) {
        return getPendleCommonStorage().allowedPendleRouters.values();
    }

    // ---------- Errors ----------

    error Pendle_Storage_Module_LengthMismatch();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IV3SwapRouter } from "../../../external/uniswapv3_interfaces/IV3SwapRouter.sol";

/**
 * @title   Vaultus Uniswap V3 Swap Module
 * @notice  Allows swapping tokens via the Uniswap V3 swap router contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface IUniswap_V3Swap_Module {
    // ---------- Functions ----------

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function uniswap_v3Swap_exactInputSingle(
        IV3SwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function uniswap_v3Swap_exactInput(IV3SwapRouter.ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function uniswap_v3Swap_exactOutputSingle(
        IV3SwapRouter.ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function uniswap_v3Swap_exactOutput(IV3SwapRouter.ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import { IUniswap_V3Swap_Module } from "./IUniswap_V3Swap_Module.sol";
import { Vaultus_Common_Roles } from "../../vaultus/Vaultus_Common_Roles.sol";
import { IV3SwapRouter } from "../../../external/uniswapv3_interfaces/IV3SwapRouter.sol";

/**
 * @title   Vaultus Uniswap V3 Swap Base
 * @notice  Allows swapping tokens via the Uniswap V3 swap router contract
 * @dev     The inputGuard functions are designed to be overriden by the inheriting contract.
 *          Key assumptions:
 *              1. Inheritor MUST ensure that the tokens are valid
 *              2. Inheritor MAY enforce any criteria on amounts if desired.
 *              3. Inheritor MUST validate the receiver address.
 *              4. Input guards MUST revert if their criteria are not met.
 *          Failure to meet these assumptions may result in unsafe behavior!
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Uniswap_V3Swap_Base is IUniswap_V3Swap_Module, AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    // solhint-disable var-name-mixedcase

    /// @notice Uniswap swap router address
    IV3SwapRouter public immutable swap_router;

    /**
     * @notice  Sets the address of the Uniswap swap router
     * @param   _swap_router    Uniswap swap router address
     */
    constructor(address _swap_router) {
        // solhint-disable-next-line reason-string
        require(_swap_router != address(0), "Uniswap_V3Swap_Base: Zero address");
        swap_router = IV3SwapRouter(_swap_router);
    }

    // solhint-enable var-name-mixedcase

    // ---------- Functions ----------

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function uniswap_v3Swap_exactInputSingle(
        IV3SwapRouter.ExactInputSingleParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountOut) {
        inputGuard_uniswap_v3Swap_exactInputSingle(params);
        amountOut = swap_router.exactInputSingle(params);
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function uniswap_v3Swap_exactInput(
        IV3SwapRouter.ExactInputParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountOut) {
        inputGuard_uniswap_v3Swap_exactInput(params);
        amountOut = swap_router.exactInput(params);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function uniswap_v3Swap_exactOutputSingle(
        IV3SwapRouter.ExactOutputSingleParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountIn) {
        inputGuard_uniswap_v3Swap_exactOutputSingle(params);
        amountIn = swap_router.exactOutputSingle(params);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function uniswap_v3Swap_exactOutput(
        IV3SwapRouter.ExactOutputParams calldata params
    ) external payable onlyRole(EXECUTOR_ROLE) returns (uint256 amountIn) {
        inputGuard_uniswap_v3Swap_exactOutput(params);
        amountIn = swap_router.exactOutput(params);
    }

    // ---------- Hooks ----------
    // solhint-disable no-empty-blocks

    function inputGuard_uniswap_v3Swap_exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) internal virtual {}

    function inputGuard_uniswap_v3Swap_exactInput(IV3SwapRouter.ExactInputParams calldata params) internal virtual {}

    function inputGuard_uniswap_v3Swap_exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) internal virtual {}

    function inputGuard_uniswap_v3Swap_exactOutput(IV3SwapRouter.ExactOutputParams calldata params) internal virtual {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./IUniswap_V3Swap_Module.sol";

/**
 * @title   Vaultus Uniswap V3 Swap Cutter
 * @notice  Cutter to enable diamonds contract to call Uniswap v3 Swap functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Uniswap_V3Swap_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IUniswap_V3Swap_Module functions
     * @param   _facet  Uniswap_V3Swap_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Uniswap_V3Swap_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](4);

        selectors[selectorIndex++] = IUniswap_V3Swap_Module.uniswap_v3Swap_exactInputSingle.selector;
        selectors[selectorIndex++] = IUniswap_V3Swap_Module.uniswap_v3Swap_exactInput.selector;
        selectors[selectorIndex++] = IUniswap_V3Swap_Module.uniswap_v3Swap_exactOutputSingle.selector;
        selectors[selectorIndex++] = IUniswap_V3Swap_Module.uniswap_v3Swap_exactOutput.selector;

        _setSupportsInterface(type(IUniswap_V3Swap_Module).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });

        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IV3SwapRouter } from "../../../external/uniswapv3_interfaces/IV3SwapRouter.sol";
import { BytesLib } from "../../../external/uniswapv3_libraries/BytesLib.sol";
import { Path } from "../../../external/uniswapv3_libraries/Path.sol";

import { Vaultus_Trader_Storage } from "../../vaultus/Vaultus_Trader_Storage.sol";
import { Uniswap_V3Swap_Base } from "./Uniswap_V3Swap_Base.sol";

/**
 * @title   Vaultus Uniswap V3 Swap Module
 * @notice  Allows swapping tokens via the Uniswap V3 swap router contract
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Uniswap_V3Swap_Module is Uniswap_V3Swap_Base, Vaultus_Trader_Storage {
    using BytesLib for bytes;
    using Path for bytes;

    /**
     * @notice  Sets the address of the Uniswap swap router
     * @param   _swap_router    Uniswap swap router address
     */
    // solhint-disable-next-line var-name-mixedcase, no-empty-blocks
    constructor(address _swap_router) Uniswap_V3Swap_Base(_swap_router) {}

    // ---------- Input Guards ----------

    function inputGuard_uniswap_v3Swap_exactInputSingle(IV3SwapRouter.ExactInputSingleParams calldata params) internal view override {
        validateToken(params.tokenIn);
        validateToken(params.tokenOut);
        if (params.recipient != address(this)) revert Uniswap_V3Swap__InvalidRecipient();
    }

    function inputGuard_uniswap_v3Swap_exactInput(IV3SwapRouter.ExactInputParams calldata params) internal view override {
        validateBytesPath(params.path);
        if (params.recipient != address(this)) revert Uniswap_V3Swap__InvalidRecipient();
    }

    function inputGuard_uniswap_v3Swap_exactOutputSingle(IV3SwapRouter.ExactOutputSingleParams calldata params) internal view override {
        validateToken(params.tokenIn);
        validateToken(params.tokenOut);
        if (params.recipient != address(this)) revert Uniswap_V3Swap__InvalidRecipient();
    }

    function inputGuard_uniswap_v3Swap_exactOutput(IV3SwapRouter.ExactOutputParams calldata params) internal view override {
        validateBytesPath(params.path);
        if (params.recipient != address(this)) revert Uniswap_V3Swap__InvalidRecipient();
    }

    // ---------- Internal ----------
    function validateBytesPath(bytes memory path) internal view {
        uint256 pools = path.numPools();
        for (uint256 i; i < pools; ) {
            (address tokenA, address tokenB, ) = path.decodeFirstPool();
            validateToken(tokenA);
            validateToken(tokenB);
            path = path.skipToken();
            unchecked {
                ++i;
            }
        }
    }

    // ---------- Errors ----------

    error Uniswap_V3Swap__InvalidRecipient();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * ----- DO NOT USE IN PRODUCTION -----
 *
 * @title   Vaultus Rescue Module
 * @notice  Allows arbitrary calls to any address
 * @dev     Intended to retrieve funds in the event of an integration bug
 * @dev     WARNING - NOT FOR PRODUCTION USE - WHITELISTED TEAM FUNDED STRATEGIES ONLY
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle

 * ----- DO NOT USE IN PRODUCTION -----
 */
interface IVaultus_Rescue_Module {
    function arbitraryCall(address _target, uint256 _value, bytes calldata _data) external;

    function arbitraryMulticall(address[] calldata _targets, uint256[] calldata _values, bytes[] calldata _datas) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

import "./IVaultus_Rescue_Module.sol";

/**
 * @title   Vaultus Rescue Cutter
 * @notice  Cutter to enable diamonds contract to make arbitrary call
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Vaultus_Rescue_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with IVaultus_Rescue_Module functions
     * @param   _facet  Vaultus_Rescue_Module address
     */
    function cut(address _facet) public {
        // solhint-disable-next-line reason-string
        require(_facet != address(0), "Vaultus_Rescue_Cutter: _facet cannot be 0 address");

        uint256 selectorIndex;
        // Register
        bytes4[] memory selectors = new bytes4[](2);

        selectors[selectorIndex++] = IVaultus_Rescue_Module.arbitraryCall.selector;
        selectors[selectorIndex++] = IVaultus_Rescue_Module.arbitraryMulticall.selector;

        _setSupportsInterface(type(IVaultus_Rescue_Module).interfaceId, true);

        // Diamond cut
        FacetCut[] memory facetCuts = new FacetCut[](1);
        facetCuts[0] = FacetCut({ target: _facet, action: FacetCutAction.ADD, selectors: selectors });
        _diamondCut(facetCuts, address(0), "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../Vaultus_Common_Roles.sol";

/**
 * ----- DO NOT USE IN PRODUCTION -----
 *
 * @title   Vaultus Rescue Module
 * @notice  Allows arbitrary calls to any address
 * @dev     Intended to retrieve funds in the event of an integration bug
 * @dev     WARNING - NOT FOR PRODUCTION USE - WHITELISTED TEAM FUNDED STRATEGIES ONLY
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle

 * ----- DO NOT USE IN PRODUCTION -----
 */
contract Vaultus_Rescue_Module is AccessControl, ReentrancyGuard, Vaultus_Common_Roles {
    /**
     * @notice  Allows arbitrary calls to any address
     * @dev     WARNING - NOT FOR PRODUCTION USE - WHITELISTED TEAM FUNDED STRATEGIES ONLY
     * @param   _target     Target address
     * @param   _value      Wei to pass as msg.value
     * @param   _data       Call data
     */
    function arbitraryCall(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external nonReentrant onlyRole(EXECUTOR_ROLE) returns (bytes memory) {
        (bool success, bytes memory data) = _target.call{ value: _value }(_data);
        require(success, "Vaultus_Rescue_Module: Call Fail");
        return data;
    }

    /**
     * @notice  Allows multiple arbitrary calls to any address
     * @dev     WARNING - NOT FOR PRODUCTION USE - WHITELISTED TEAM FUNDED STRATEGIES ONLY
     * @param   _targets    Array of target addresses
     * @param   _values     Array of wei to pass as msg.value
     * @param   _datas      Array of call data
     */
    function arbitraryMulticall(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _datas
    ) external nonReentrant onlyRole(EXECUTOR_ROLE) returns (bytes[] memory) {
        require(_targets.length == _values.length && _values.length == _datas.length, "Vaultus_Rescue_Module: Invalid Input Lengths");
        bytes[] memory returnData = new bytes[](_targets.length);
        for (uint256 i; i < _targets.length; ) {
            (bool success, bytes memory data) = _targets[i].call{ value: _values[i] }(_datas[i]);
            require(success, "Vaultus_Rescue_Module: Call Fail");
            returnData[i] = data;
            unchecked {
                ++i;
            }
        }
        return returnData;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title   Vaultus Common Roles
 * @notice  Access control roles available to all strategy contracts
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Vaultus_Common_Roles {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IVault, Epoch } from "../../../interfaces/IVault.sol";
import { IFeeController } from "../../../interfaces/IFeeController.sol";

/**
 * @title   Vaultus VT Trader Storage
 * @notice  Contains storage variables and functions common to all traders
 * @dev     Storage follows diamond pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
abstract contract Vaultus_Trader_Storage {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TraderV0Storage {
        /// @notice Strategy name
        string name;
        /// @notice Address receiving fees
        address feeReceiver;
        /// @notice Vault address
        IVault vault;
        /// @notice Underlying asset of the strategy's vault
        IERC20 baseAsset;
        /// @notice Fee controller address
        IFeeController feeController;
        /// @notice Performance fee as percentage of profits, in units of 1e18 = 100%
        uint256 performanceFeeRate;
        /// @notice Management fee as percentage of base assets, in units of 1e18 = 100%
        uint256 managementFeeRate;
        /// @notice Timestamp when funds were taken into custody, in Unix epoch seconds
        uint256 custodyTime;
        /// @notice Amount of base asset taken into custody
        uint256 custodiedAmount;
        /// @notice True if vault controller has signed off on funds return
        bool returnSignalled;
        /// @notice Accumulated management and performance fees due to the operator
        uint256 operatorFees;
        /// @notice Accumulated management and performance fees due to the protocol
        uint256 protocolFees;
        /// @notice Tokens which can be held or handled by this contract
        EnumerableSet.AddressSet allowedTokens;
        /// @notice Addresses which can be approved by this contract
        EnumerableSet.AddressSet allowedSpenders;
        /// @notice Whether the contract has been initialized
        bool initialized;
    }

    /// @dev    EIP-2535 Diamond Storage struct location
    bytes32 internal constant TRADERV0_POSITION = bytes32(uint256(keccak256("TraderV0.storage")) - 1);

    /**
     * @return  storageStruct   TraderV0Storage storage pointer
     */
    function getTraderV0Storage() internal pure returns (TraderV0Storage storage storageStruct) {
        bytes32 position = TRADERV0_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageStruct.slot := position
        }
    }

    // --------- Internal Functions ---------

    /**
     * @notice  Validates a swap path
     * @param   _path   Array of token addresses to validate
     */
    function validateSwapPath(address[] memory _path) internal view {
        TraderV0Storage storage s = getTraderV0Storage();
        uint256 len = _path.length;
        for (uint256 i; i < len; ) {
            require(s.allowedTokens.contains(_path[i]), "Invalid swap path");
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Validates a single token address
     * @param   _token  Address of token to validate
     */
    function validateToken(address _token) internal view {
        require(getTraderV0Storage().allowedTokens.contains(_token), "Invalid token");
    }
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

import "../diamonds/StrategyDiamond.sol";

import "../trader/ITraderV0_Cutter.sol";
import "../modules/ICutter.sol";

/**
 * Vaultus Finance
 * @title   Vaultus MVP Strategy
 * @notice  Executes a user-defined trading strategy
 * @dev     Supports protocol integrations where the cutter does not require input calldata
 * @dev     Employs a non-upgradeable version of the EIP-2535 Diamonds pattern
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract Strategy_MVP is StrategyDiamond {
    bytes32 public constant VAULT_SETTER_ROLE = keccak256("VAULT_SETTER_ROLE");

    // solhint-disable avoid-low-level-calls

    /**
     * @notice  Construct a new Strategy_MVP instance
     * @param   _admin              Address to which admin role is assigned
     * @param   _operator           Address to which operator role is assigned
     * @param   _vaultSetter        Address to which vault setter role is assigned
     * @param   _traderV0Params     TraderV0 initialization parameters
     * @param   _cutters            Array of cutter addresses
     * @param   _facets             Array of facet addresses
     * @dev     Facets and cutters must be in the same order
     * @dev     The first cutter and facet must belong to TraderV0
     */
    constructor(
        address _admin,
        address _operator,
        address _vaultSetter,
        TraderV0InitializerParams memory _traderV0Params,
        address[] memory _cutters,
        address[] memory _facets
    ) StrategyDiamond(_admin, _operator) {
        if (_cutters.length != _facets.length) revert Strategy__LengthMismatch();

        (bool success, ) = _cutters[0].delegatecall(
            abi.encodeWithSelector(ITraderV0_Cutter.cut_TraderV0.selector, _facets[0], _traderV0Params)
        );
        if (!success) revert Strategy__DelegatecallFailed();

        _grantRole(VAULT_SETTER_ROLE, _vaultSetter);

        for (uint256 i = 1; i < _cutters.length; ) {
            if (_cutters[i] != address(0)) {
                (success, ) = _cutters[i].delegatecall(abi.encodeWithSelector(ICutter.cut.selector, _facets[i]));
                if (!success) revert Strategy__DelegatecallFailed();
            }

            unchecked {
                i++;
            }
        }
    }

    // ---------- ERRORS ----------

    error Strategy__LengthMismatch();
    error Strategy__ZeroAddress();
    error Strategy__DelegatecallFailed();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ITraderV0.sol";

/**
 * @title   Vaultus Trader V0 Cutter Interface
 * @notice  Cutter to enable diamonds contract to call trader core functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ITraderV0_Cutter {
    /**
     * @notice  "Cuts" the strategy diamond with ITraderV0 functions
     * @param   _traderFacet        TraderV0 address
     * @param   _traderV0Params     Initialization parameters
     */
    function cut_TraderV0(address _traderFacet, TraderV0InitializerParams memory _traderV0Params) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IVault.sol";

/**
 * @param   _name                       Strategy name
 * @param   _allowedTokens              ERC-20 tokens to include in the strategy's mandate
 * @param   _allowedSpenders            Addresses which can receive ERC-20 token approval
 * @param   _initialPerformanceFeeRate  Initial value of the performance fee, in units of 1e18 = 100%
 * @param   _initialManagementFeeRate   Initial value of the management fee, in units of 1e18 = 100%
 */
struct TraderV0InitializerParams {
    string _name;
    address _feeReceiver;
    address _feeController;
    address[] _allowedTokens;
    address[] _allowedSpenders;
    uint256 _initialPerformanceFeeRate;
    uint256 _initialManagementFeeRate;
}

/**
 * @title   Vaultus Trader V0 Core Interface
 * @notice  Interfaces with the Vault contract, handling custody, returning, and fee-taking
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
interface ITraderV0 {
    // ---------- Construction and Initialization ----------

    function initializeTraderV0(TraderV0InitializerParams calldata _params) external;

    /**
     * @notice  Set this strategy's vault address
     * @dev     May only be set once
     * @param   _vault  Vault address
     */
    function setVault(address _vault) external;

    // ---------- Operation ----------

    /**
     * @notice  Approve a whitelisted spender to handle one of the whitelisted tokens
     * @param   _token      Token to set approval for
     * @param   _spender    Spending address
     * @param   _amount     Token amount
     */
    function approve(address _token, address _spender, uint256 _amount) external;

    /**
     * @notice  Take custody of the vault's funds
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function custodyFunds() external;

    /**
     * @notice  Signal that the vault's funds are ready to be returned
     */
    function signalReturn() external;

    /**
     * @notice  Return the vault's funds and take fees if enabled
     * @dev     WARNING: Unwind all positions back into the base asset before returning funds.
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function returnFunds() external;

    /**
     * @notice  Withdraw all accumulated fees
     * @dev     This should be done before the start of the next epoch to avoid fees becoming mixed with vault funds
     */
    function withdrawFees() external;

    // --------- Configuration ----------

    /**
     * @notice  Set new performance and management fees
     * @notice  May not be set while funds are custodied
     * @param   _performanceFeeRate     New management fee (100% = 1e18)
     * @param   _managementFeeRate      New management fee (100% = 1e18)
     */
    function setFeeRates(uint256 _performanceFeeRate, uint256 _managementFeeRate) external;

    /**
     * @notice  Set a new fee receiver address
     * @param   _feeReceiver   Address which will receive fees from the contract
     */
    function setFeeReceiver(address _feeReceiver) external;

    /**
     * @notice  Set a new fee controller address
     * @param   _feeController   Address which can set fee rates
     */
    function setFeeController(address _feeController) external;

    // --------- View Functions ---------

    /**
     * @notice  View all tokens the contract is allowed to handle
     * @return  List of token addresses
     */
    function getAllowedTokens() external view returns (address[] memory);

    /**
     * @notice  View all addresses which can recieve token approvals
     * @return  List of addresses
     */
    function getAllowedSpenders() external view returns (address[] memory);

    // ----- State Variable Getters -----

    /// @notice Strategy name
    function name() external view returns (string memory);

    /// @notice Address receiving fees
    function feeReceiver() external view returns (address);

    /// @notice Vault address
    function vault() external view returns (IVault);

    /// @notice Underlying asset of the strategy's vault
    function baseAsset() external view returns (IERC20);

    /// @notice Address which can set fee rates
    function feeController() external view returns (address);

    /// @notice Performance fee as percentage of profits, in units of 1e18 = 100%
    function performanceFeeRate() external view returns (uint256);

    /// @notice Management fee as percentage of base assets, in units of 1e18 = 100%
    function managementFeeRate() external view returns (uint256);

    /// @notice Timestamp when funds were taken into custody, in Unix epoch seconds
    function custodyTime() external view returns (uint256);

    /// @notice Amount of base asset taken into custody
    function custodiedAmount() external view returns (uint256);

    /// @notice Accumulated management and performance fees
    function operatorFees() external view returns (uint256);

    /// @notice Accumulated protocol fees
    function protocolFees() external view returns (uint256);

    /// @notice Whether the vault has signalled that funds are ready to be returned
    function returnSignalled() external view returns (bool);

    /// @notice Maximum allowable performance fee as percentage of profits, in units of 1e18 = 100%
    function MAX_PERFORMANCE_FEE_RATE() external view returns (uint256);

    /// @notice Maximum allowable management fee as percentage of base assets per year, in units of 1e18 = 100%
    function MAX_MANAGEMENT_FEE_RATE() external view returns (uint256);

    // --------- Hooks ---------

    receive() external payable;

    // ----- Events -----

    event ReturnSignalled();

    event FundsReturned(
        uint256 startBalance,
        uint256 endBalance,
        uint256 performanceFee,
        uint256 managementFee,
        uint256 operatorFee,
        uint256 protocolFee
    );
    event FeesWithdrawn(address indexed withdrawer, uint256 operatorAmount, uint256 protocolAmount);

    event FeesSet(uint256 oldPerformanceFee, uint256 newPerformanceFee, uint256 oldManagementFee, uint256 newManagementFee);
    event FeeReceiverSet(address oldFeeReceiver, address newFeeReceiver);
    event FeeControllerSet(address oldFeeController, address newFeeController);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/proxy/diamond/writable/DiamondWritableInternal.sol";
import "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import "./ITraderV0.sol";

/**
 * @title   Vaultus Trader V0 Cutter
 * @notice  Cutter to enable diamonds contract to call trader core functions
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TraderV0_Cutter is DiamondWritableInternal, ERC165Base {
    /**
     * @notice  "Cuts" the strategy diamond with ITraderV0 functions
     * @param   _traderFacet        TraderV0 address
     * @param   _traderV0Params     Initialization parameters
     */
    function cut_TraderV0(address _traderFacet, TraderV0InitializerParams memory _traderV0Params) public {
        // solhint-disable-next-line reason-string
        require(_traderFacet != address(0), "TraderV0_Cutter: _traderFacet must not be 0 address");

        uint256 selectorIndex;
        // Register TraderV0
        bytes4[] memory traderSelectors = new bytes4[](25);

        traderSelectors[selectorIndex++] = ITraderV0.setVault.selector;
        traderSelectors[selectorIndex++] = ITraderV0.approve.selector;
        traderSelectors[selectorIndex++] = ITraderV0.custodyFunds.selector;
        traderSelectors[selectorIndex++] = ITraderV0.signalReturn.selector;
        traderSelectors[selectorIndex++] = ITraderV0.returnFunds.selector;
        traderSelectors[selectorIndex++] = ITraderV0.withdrawFees.selector;

        traderSelectors[selectorIndex++] = ITraderV0.setFeeRates.selector;
        traderSelectors[selectorIndex++] = ITraderV0.setFeeReceiver.selector;
        traderSelectors[selectorIndex++] = ITraderV0.setFeeController.selector;

        traderSelectors[selectorIndex++] = ITraderV0.getAllowedTokens.selector;
        traderSelectors[selectorIndex++] = ITraderV0.getAllowedSpenders.selector;

        traderSelectors[selectorIndex++] = ITraderV0.name.selector;
        traderSelectors[selectorIndex++] = ITraderV0.feeReceiver.selector;
        traderSelectors[selectorIndex++] = ITraderV0.vault.selector;
        traderSelectors[selectorIndex++] = ITraderV0.baseAsset.selector;
        traderSelectors[selectorIndex++] = ITraderV0.feeController.selector;
        traderSelectors[selectorIndex++] = ITraderV0.performanceFeeRate.selector;
        traderSelectors[selectorIndex++] = ITraderV0.managementFeeRate.selector;
        traderSelectors[selectorIndex++] = ITraderV0.custodyTime.selector;
        traderSelectors[selectorIndex++] = ITraderV0.custodiedAmount.selector;
        traderSelectors[selectorIndex++] = ITraderV0.operatorFees.selector;
        traderSelectors[selectorIndex++] = ITraderV0.protocolFees.selector;
        traderSelectors[selectorIndex++] = ITraderV0.returnSignalled.selector;
        traderSelectors[selectorIndex++] = ITraderV0.MAX_PERFORMANCE_FEE_RATE.selector;
        traderSelectors[selectorIndex++] = ITraderV0.MAX_MANAGEMENT_FEE_RATE.selector;

        _setSupportsInterface(type(ITraderV0).interfaceId, true);

        // Diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({ target: _traderFacet, action: FacetCutAction.ADD, selectors: traderSelectors });
        bytes memory payload = abi.encodeWithSelector(ITraderV0.initializeTraderV0.selector, _traderV0Params);

        _diamondCut(facetCuts, _traderFacet, payload); // Can add initializations to this call
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../modules/vaultus/Vaultus_Trader_Storage.sol";
import "../modules/vaultus/Vaultus_Common_Roles.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IFeeController.sol";
import "./ITraderV0.sol";

/**
 * @title   Vaultus Trader Core V0
 * @notice  Interfaces with the Vault contract, handling custody, returning, and fee-taking
 * @dev     Warning: This contract is intended for use as a facet of diamond proxy contracts.
 *          Calling it directly may produce unintended or undesirable results.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle
 */
contract TraderV0 is ITraderV0, AccessControl, Vaultus_Common_Roles, Vaultus_Trader_Storage {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant VAULT_SETTER_ROLE = keccak256("VAULT_SETTER_ROLE");

    /// @dev Unit denominator of fee rates
    uint256 public constant FEE_DENOMINATOR = 1e18;
    /// @notice Maximum allowable management fee as percentage of base assets per year, in units of 1e18 = 100%
    uint256 public immutable MAX_PERFORMANCE_FEE_RATE; // solhint-disable-line var-name-mixedcase
    /// @notice Maximum allowable management fee as percentage of base assets per year, in units of 1e18 = 100%
    uint256 public immutable MAX_MANAGEMENT_FEE_RATE; // solhint-disable-line var-name-mixedcase

    // ---------- Construction and Initialization ----------

    /**
     * @param   _MAX_PERFORMANCE_FEE_RATE   Maximum performance fee as percentage of profits (100% = 1e18)
     * @param   _MAX_MANAGEMENT_FEE_RATE    Maximum management fee as percentage of assets (100% = 1e18)
     */
    // solhint-disable-next-line var-name-mixedcase
    constructor(uint256 _MAX_PERFORMANCE_FEE_RATE, uint256 _MAX_MANAGEMENT_FEE_RATE) {
        MAX_PERFORMANCE_FEE_RATE = _MAX_PERFORMANCE_FEE_RATE;
        MAX_MANAGEMENT_FEE_RATE = _MAX_MANAGEMENT_FEE_RATE;
    }

    /**
     * @notice  Initialize the trader parameters
     * @dev     Should ONLY be called through cut_TraderV0.
     *          Adding this function selector to the Diamond will result in a CRITICAL vulnerabiilty.
     * @param   _params     Initialization parameters
     */
    function initializeTraderV0(TraderV0InitializerParams calldata _params) external {
        TraderV0Storage storage s = getTraderV0Storage();
        require(!s.initialized, "TraderV0: Initializer");
        s.initialized = true;

        s.name = _params._name;
        uint256 len = _params._allowedTokens.length;
        require(len > 0, "!tokens");
        for (uint256 i; i < len; ++i) {
            s.allowedTokens.add(_params._allowedTokens[i]);
        }

        len = _params._allowedSpenders.length;
        require(len > 0, "!spenders");
        for (uint256 i; i < len; ++i) {
            s.allowedSpenders.add(_params._allowedSpenders[i]);
        }

        require(
            MAX_PERFORMANCE_FEE_RATE >= _params._initialPerformanceFeeRate && MAX_MANAGEMENT_FEE_RATE >= _params._initialManagementFeeRate,
            "!rates"
        );
        s.performanceFeeRate = _params._initialPerformanceFeeRate;
        s.managementFeeRate = _params._initialManagementFeeRate;

        require(_params._feeReceiver != address(0), "!feeReceiver");
        s.feeReceiver = _params._feeReceiver;

        require(_params._feeController != address(0), "!feeController");
        s.feeController = IFeeController(_params._feeController);
    }

    /**
     * @notice  Set this strategy's vault address
     * @dev     May only be set once
     * @param   _vault  Vault address
     */
    function setVault(address _vault) external virtual onlyRole(VAULT_SETTER_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(_vault != address(0), "!vault");
        require(address(s.vault) == address(0), "!set");
        s.baseAsset = IERC20(IVault(_vault).asset());
        s.vault = IVault(_vault);
    }

    // ---------- Operation ----------

    /**
     * @notice  Approve a whitelisted spender to handle one of the whitelisted tokens
     * @param   _token      Token to set approval for
     * @param   _spender    Spending address
     * @param   _amount     Token amount
     */
    function approve(address _token, address _spender, uint256 _amount) external virtual onlyRole(EXECUTOR_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();

        require(s.allowedTokens.contains(_token), "!token");
        require(s.allowedSpenders.contains(_spender), "!spender");

        IERC20(_token).approve(_spender, _amount);
    }

    /**
     * @notice  Take custody of the vault's funds
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function custodyFunds() external virtual onlyRole(EXECUTOR_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(s.operatorFees + s.protocolFees == 0, "!fees");
        s.custodyTime = block.timestamp;
        s.custodiedAmount = s.vault.custodyFunds();
    }

    /**
     * @notice  Signal that the vault's funds are ready to be returned
     */
    function signalReturn() external virtual onlyRole(EXECUTOR_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(s.custodyTime > 0, "!custodied");
        require(!s.returnSignalled, "Signalled");
        s.returnSignalled = true;
        emit ReturnSignalled();
    }

    /**
     * @notice  Return the vault's funds and take fees if enabled
     * @dev     WARNING: Unwind all positions back into the base asset before returning funds.
     * @dev     Relies on Vault contract to revert if called out of sequence.
     */
    function returnFunds() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(s.returnSignalled, "!signalled");
        uint256 balance = s.baseAsset.balanceOf(address(this));
        uint256 cachedCustodiedAmount = s.custodiedAmount;
        uint256 profit = balance > cachedCustodiedAmount ? balance - cachedCustodiedAmount : 0;

        uint256 performanceFee = (profit * s.performanceFeeRate) / FEE_DENOMINATOR;
        uint256 managementFee = (cachedCustodiedAmount * s.managementFeeRate * (block.timestamp - s.custodyTime)) /
            365 days /
            FEE_DENOMINATOR;

        // If fees exceed balance, take no fees
        if (performanceFee + managementFee > balance) {
            performanceFee = 0;
            managementFee = 0;
        }

        uint256 protocolFeeFraction = s.feeController.protocolFee();
        uint256 protocolFee = ((performanceFee * protocolFeeFraction) + (managementFee * protocolFeeFraction)) / FEE_DENOMINATOR;
        uint256 operatorFee = performanceFee + managementFee - protocolFee; // TODO verify nonrevert conditions

        s.operatorFees = s.operatorFees + operatorFee;
        s.protocolFees = s.protocolFees + protocolFee;
        s.custodiedAmount = 0;
        s.custodyTime = 0;
        s.returnSignalled = false;

        s.baseAsset.approve(address(s.vault), balance - performanceFee - managementFee);
        s.vault.returnFunds(balance - performanceFee - managementFee);

        emit FundsReturned(cachedCustodiedAmount, balance, performanceFee, managementFee, operatorFee, protocolFee);
    }

    /**
     * @notice  Withdraw all accumulated fees
     * @dev     This must be done before the start of the next epoch to avoid fees becoming mixed with vault funds
     */
    function withdrawFees() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(s.operatorFees + s.protocolFees > 0, "!fees");
        uint256 operatorAmount = s.operatorFees;
        uint256 protocolAmount = s.protocolFees;
        s.operatorFees = 0;
        s.protocolFees = 0;
        s.baseAsset.safeTransfer(s.feeReceiver, operatorAmount);
        s.baseAsset.safeTransfer(address(s.feeController), protocolAmount);
        emit FeesWithdrawn(msg.sender, operatorAmount, protocolAmount);
    }

    // --------- Configuration ----------

    /**
     * @notice  Set new performance and management fees
     * @notice  May not be set while funds are custodied
     * @param   _performanceFeeRate     New management fee (100% = 1e18)
     * @param   _managementFeeRate      New management fee (100% = 1e18)
     */
    function setFeeRates(uint256 _performanceFeeRate, uint256 _managementFeeRate) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        TraderV0Storage storage s = getTraderV0Storage();
        require(_performanceFeeRate <= MAX_PERFORMANCE_FEE_RATE && _managementFeeRate <= MAX_MANAGEMENT_FEE_RATE, "!rates");
        require(s.custodyTime == 0, "Custodied");
        emit FeesSet(s.performanceFeeRate, _performanceFeeRate, s.managementFeeRate, _managementFeeRate);
        s.performanceFeeRate = _performanceFeeRate;
        s.managementFeeRate = _managementFeeRate;
    }

    /**
     * @notice  Set a new fee receiver address
     * @param   _feeReceiver   Address which will receive fees from the contract
     */
    function setFeeReceiver(address _feeReceiver) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeReceiver != address(0), "!zeroAddress");
        TraderV0Storage storage s = getTraderV0Storage();
        emit FeeReceiverSet(s.feeReceiver, _feeReceiver);
        s.feeReceiver = _feeReceiver;
    }

    /**
     * @notice  Set a new fee controller address
     * @param   _feeController   Address which will control the protocol fees
     */
    function setFeeController(address _feeController) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeController != address(0), "!zeroAddress");
        TraderV0Storage storage s = getTraderV0Storage();
        emit FeeControllerSet(address(s.feeController), _feeController);
        s.feeController = IFeeController(_feeController);
    }

    // --------- View Functions ---------

    /**
     * @notice  View all tokens the contract is allowed to handle
     * @return  List of token addresses
     */
    function getAllowedTokens() external view returns (address[] memory) {
        return getTraderV0Storage().allowedTokens.values();
    }

    /**
     * @notice  View all addresses which can recieve token approvals
     * @return  List of addresses
     */
    function getAllowedSpenders() external view returns (address[] memory) {
        return getTraderV0Storage().allowedSpenders.values();
    }

    // ----- State Variable Getters -----

    /// @notice Strategy name
    function name() external view returns (string memory) {
        return getTraderV0Storage().name;
    }

    /// @notice Address receiving fees
    function feeReceiver() external view returns (address) {
        return getTraderV0Storage().feeReceiver;
    }

    /// @notice Vault address
    function vault() external view returns (IVault) {
        return getTraderV0Storage().vault;
    }

    /// @notice Underlying asset of the strategy's vault
    function baseAsset() external view returns (IERC20) {
        return getTraderV0Storage().baseAsset;
    }

    /// @notice Address which can set fee rates
    function feeController() external view returns (address) {
        return address(getTraderV0Storage().feeController);
    }

    /// @notice Performance fee as percentage of profits, in units of 1e18 = 100%
    function performanceFeeRate() external view returns (uint256) {
        return getTraderV0Storage().performanceFeeRate;
    }

    /// @notice Management fee as percentage of base assets, in units of 1e18 = 100%
    function managementFeeRate() external view returns (uint256) {
        return getTraderV0Storage().managementFeeRate;
    }

    /// @notice Timestamp when funds were taken into custody, in Unix epoch seconds
    function custodyTime() external view returns (uint256) {
        return getTraderV0Storage().custodyTime;
    }

    /// @notice Amount of base asset taken into custody
    function custodiedAmount() external view returns (uint256) {
        return getTraderV0Storage().custodiedAmount;
    }

    /// @notice Accumulated management and performance fees
    function operatorFees() external view returns (uint256) {
        return getTraderV0Storage().operatorFees;
    }

    /// @notice Accumulated protocol fees
    function protocolFees() external view returns (uint256) {
        return getTraderV0Storage().protocolFees;
    }

    /// @notice Whether the vault has signalled that funds are ready to be returned
    function returnSignalled() external view returns (bool) {
        return getTraderV0Storage().returnSignalled;
    }

    // --------- Hooks ---------

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./interfaces/IVault.sol";

/**
 * @title   Vaultus Finance Whitelisted Investment Vault v0.1.0
 * @notice  Deposit an ERC-20 to earn yield via managed trading
 * @notice  Whitelisted variant: only allowed users can deposit into vault
 * @dev     ERC-4626 compliant
 * @dev     Does not support rebasing or transfer fee tokens.
 * @author  Vaultus Finance
 * @custom:developer    BowTiedPickle, zug
 */
contract WhitelistedVault is ERC4626, Ownable, IVault {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // ----- Events -----

    /**
     * @notice  Emitted when a new epoch starts
     * @param   epoch The epoch number that has started
     * @param   fundingStart The timestamp from which funding can begin
     * @param   epochStart The timestamp at which the epoch starts
     * @param   epochEnd The timestamp at which the epoch ends
     */
    event EpochStarted(uint256 indexed epoch, uint256 fundingStart, uint256 epochStart, uint256 epochEnd);

    /**
     * @notice  Emitted when funds are sent to the custodian for trading
     * @param   epoch The current epoch during which funds are custodied
     * @param   amount The amount of funds that have been custodied
     */
    event FundsCustodied(uint256 indexed epoch, uint256 amount);

    /**
     * @notice  Emitted when funds are returned from custodian after trading
     * @param   epoch The epoch during which funds were traded
     * @param   amount The amount of funds that have been returned
     */
    event FundsReturned(uint256 indexed epoch, uint256 amount);

    /**
     * @notice  Emitted when the maximum deposit limit is updated
     * @param   oldMax The previous maximum deposit limit
     * @param   newMax The new updated maximum deposit limit
     */
    event NewMaxDeposits(uint256 oldMax, uint256 newMax);

    /**
     * @notice Emitted when the whitelist status of a user is updated
     * @dev This event logs the address and the new status regarding the whitelist
     * @param user The address of the user whose whitelist status has changed
     * @param status The new whitelist status of the user; `true` for whitelisted, `false` for not whitelisted
     */
    event NewWhitelistStatus(address indexed user, bool status);

    // ----- State Variables -----

    /// @notice The maximum duration an epoch can last
    uint256 public constant MAX_EPOCH_DURATION = 30 days;
    uint256 public constant MIN_FUNDING_DURATION = 2 days;

    /// @dev Mapping of epoch IDs to their corresponding Epoch structs
    mapping(uint256 => Epoch) public epochs;

    /// @dev Counter to keep track of the current epoch ID
    Counters.Counter internal epochId;

    /// @notice Flag to indicate whether the current epoch has started
    bool public started;

    /// @notice Flag to indicate whether the funds are currently with the custodian
    bool public custodied;

    /// @notice The amount of funds currently custodied
    uint256 public custodiedAmount;

    /// @notice Address which can take custody of funds to execute strategies during an epoch
    address public immutable strategy;

    /// @notice Protocol governance address
    address public immutable governance;

    /// @notice The maximum amount of deposits allowed into the vault
    uint256 public maxDeposits;

    /// @notice The total amount of deposits currently in the vault
    uint256 public totalDeposits;

    /// @notice Vault's visibility 1 for public
    uint8 public constant VAULT_ACCESS = 1;

    /// @notice Mapping of users to whether they are whitelisted to deposit into the vault
    mapping(address => bool) public whitelisted;

    // ----- Modifiers -----
    // TODO: maybe comments here are unnecessary, for now ill just document every single thing

    /// @dev Ensures that the function is called only by the strategy
    modifier onlyStrategy() {
        require(msg.sender == strategy, "!strategy");
        _;
    }

    /// @dev Ensures that the function is called only by governance
    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /// @dev Ensures that the function is called when no funds are custodied
    modifier notCustodied() {
        require(!custodied, "custodied");
        _;
    }

    /// @dev Ensures that the function is called during the funding phase of an epoch
    modifier duringFunding() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart, "!funding");
        _;
    }

    /// @dev Ensures that the function is called when not during the active trading phase of an epoch
    modifier notDuringEpoch() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) < epoch.epochStart || uint80(block.timestamp) >= epoch.epochEnd, "during");
        _;
    }

    /// @dev Ensures that the function is called during the active trading phase of an epoch
    modifier duringEpoch() {
        Epoch storage epoch = epochs[epochId.current()];
        require(uint80(block.timestamp) >= epoch.epochStart && uint80(block.timestamp) < epoch.epochEnd, "!during");
        _;
    }

    /// @dev Ensures that the function is called by a whitelisted address
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "!whitelisted");
        _;
    }

    // ----- Construction -----

    /**
     * @notice  Initializes a new vault contract
     *
     * @param   _asset          ERC-20 token that is the vault's underlying asset
     * @param   _name           Name of the vault token
     * @param   _symbol         Symbol of the vault token
     * @param   _strategy       Strategy address: manages the vault's funds
     * @param   _admin          Admin address: can start new epochs
     * @param   _governance     Governance address: can set new maximum deposits
     * @param   _maxDeposits    Initial maximum deposits allowed
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _strategy,
        address _admin,
        address _governance,
        uint256 _maxDeposits
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        require(_strategy != address(0) && _governance != address(0) && _admin != address(0), "!zeroAddr");
        strategy = _strategy;
        governance = _governance;
        maxDeposits = _maxDeposits;
        _transferOwnership(_admin);
    }

    // ----- Admin Functions -----

    /**
     * @notice  Start a new investment epoch with specified timing parameters
     * @dev     Can only be called by the owner when not during an active epoch and when funds are not custodied.
     *          Emits the EpochStarted event upon success.
     * @param   _fundingStart The timestamp from which funding can begin
     * @param   _epochStart The timestamp at which the epoch officially starts
     * @param   _epochEnd The timestamp at which the epoch ends
     *          The epoch timings must adhere to the preset duration constraints.
     */
    function startEpoch(uint80 _fundingStart, uint80 _epochStart, uint80 _epochEnd) external override onlyOwner notDuringEpoch {
        require(!started || !custodied, "!allowed");
        require(
            _epochEnd > _epochStart && _epochStart >= _fundingStart + MIN_FUNDING_DURATION && _fundingStart >= uint80(block.timestamp),
            "!timing"
        );
        require(_epochEnd <= _epochStart + MAX_EPOCH_DURATION, "!epochLen");

        epochId.increment();
        uint256 currentEpoch = getCurrentEpoch();
        Epoch storage epoch = epochs[currentEpoch];

        epoch.fundingStart = _fundingStart;
        epoch.epochStart = _epochStart;
        epoch.epochEnd = _epochEnd;

        started = true;

        emit EpochStarted(currentEpoch, _fundingStart, _epochStart, _epochEnd);
    }

    /**
     * @notice  Update the maximum deposit limit for the vault
     * @dev     Can only be called by the owner. Emits the NewMaxDeposits event upon success.
     * @param   _newMax The new maximum deposit limit to be set for the vault
     */
    function setMaxDeposits(uint256 _newMax) external override onlyGovernance {
        emit NewMaxDeposits(maxDeposits, _newMax);
        maxDeposits = _newMax;
    }

    /**
     * @notice Set the whitelist status for a single address
     * @dev Can only be called by the contract owner. Emits NewWhitelistStatus event.
     * @param _user The address of the user to update whitelist status for
     * @param _status The whitelist status to set for the user
     */
    function setWhitelistStatus(address _user, bool _status) external onlyOwner {
        _modifyWhitelist(_user, _status);
    }

    /**
     * @notice Set the whitelist statuses for multiple addresses
     * @dev Can only be called by the contract owner. Emits NewWhitelistStatus event for each user.
     * @param _users The addresses of the users to update whitelist statuses for
     * @param _statuses The whitelist statuses to set for the users
     */
    function setWhitelistStatuses(address[] calldata _users, bool[] calldata _statuses) external onlyOwner {
        uint256 len = _users.length;
        require(_statuses.length == len, "!len");

        for (uint256 i; i < len; ++i) {
            _modifyWhitelist(_users[i], _statuses[i]);
        }
    }

    /**
     * @dev Internal function to modify whitelist status for a user
     * @param _user The address of the user to update whitelist status for
     * @param _status The whitelist status to set for the user
     */
    function _modifyWhitelist(address _user, bool _status) internal {
        whitelisted[_user] = _status;
        emit NewWhitelistStatus(_user, _status);
    }

    // ----- Strategy Functions -----

    /**
     * @notice Take custody of the vault's funds for trading purposes during an active epoch
     * @dev Can only be called by the assigned strategy, when funds are not already custodied, and during an active epoch.
     *      Transfers the total assets to the strategy's address and marks the funds as custodied.
     *      Emits the FundsCustodied event upon success.
     * @return The amount of funds that were custodied for trading
     */
    function custodyFunds() external override onlyStrategy notCustodied duringEpoch returns (uint256) {
        uint256 amount = totalAssets();
        require(amount > 0, "!amount");

        custodied = true;
        custodiedAmount = amount;
        IERC20(asset()).safeTransfer(strategy, amount);

        emit FundsCustodied(epochId.current(), amount);
        return amount;
    }

    /**
     * @notice Return funds to the vault after trading has concluded
     * @dev Can only be called by the assigned strategy when funds are currently custodied.
     *      The strategy is responsible for returning the entire sum taken into custody.
     *      Marks the end of the current epoch and updates the state accordingly.
     *      Emits the FundsReturned event upon successful return of funds.
     *      Losses may be sustained during the trading which is returned by strategy, in which case the investors will suffer a loss.
     * @param _amount The amount of funds being returned to the vault
     */
    function returnFunds(uint256 _amount) external override onlyStrategy {
        require(custodied, "!custody");
        require(_amount > 0, "!amount");
        IERC20(asset()).safeTransferFrom(strategy, address(this), _amount);

        uint256 currentEpoch = getCurrentEpoch();
        Epoch storage epoch = epochs[currentEpoch];
        epoch.epochEnd = uint80(block.timestamp);

        custodiedAmount = 0;
        custodied = false;
        started = false;
        totalDeposits = totalAssets();

        emit FundsReturned(currentEpoch, _amount);
    }

    // ----- View Functions -----

    /**
     * @notice  Retrieve the ID of the current epoch
     * @dev     The current epoch ID is determined by the internal epochId counter.
     * @return  The ID of the current epoch
     */
    function getCurrentEpoch() public view override returns (uint256) {
        return epochId.current();
    }

    /**
     * @notice  Get information about the current epoch
     * @dev     The information includes start and end times, as well as funding start time.
     * @return  The Epoch struct containing the current epoch's details
     */
    function getCurrentEpochInfo() external view override returns (Epoch memory) {
        return epochs[epochId.current()];
    }

    /**
     * @notice  Check if the vault is currently in the funding phase
     * @dev     The funding phase is between the funding start time and the epoch start time.
     * @return  True if the contract is in the funding phase, false otherwise
     */
    function isFunding() external view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart;
    }

    /**
     * @notice  Determine if the vault is within an active epoch
     * @dev     An active epoch is between the epoch start and end times.
     * @return  True if the contract is within an epoch phase, false otherwise
     */
    function isInEpoch() external view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return uint80(block.timestamp) >= epoch.epochStart && uint80(block.timestamp) < epoch.epochEnd;
    }

    /**
     * @notice  Check if deposits and mints are currently allowed
     * @dev     Deposits and mints are allowed when the vault is not custodied and during the funding phase.
     * @return  True if deposits and mints are currently allowed, false otherwise
     */
    function notCustodiedAndDuringFunding() public view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return (!custodied && (uint80(block.timestamp) >= epoch.fundingStart && uint80(block.timestamp) < epoch.epochStart));
    }

    /**
     * @notice  Check if withdraws and redeems are currently allowed
     * @dev     Withdraws and redeems are allowed when the vault is not custodied and not during an active epoch.
     * @return  True if withdraws and redeems are currently allowed, false otherwise
     */
    function notCustodiedAndNotDuringEpoch() public view override returns (bool) {
        Epoch storage epoch = epochs[epochId.current()];
        return (!custodied && (uint80(block.timestamp) < epoch.epochStart || uint80(block.timestamp) >= epoch.epochEnd));
    }

    // ----- Overrides -----

    /// @dev    See EIP-4626
    function asset() public view override(ERC4626, IVault) returns (address) {
        return ERC4626.asset();
    }

    /// @dev    See EIP-4626
    function maxDeposit(address) public view override(ERC4626, IVault) returns (uint256) {
        if (custodied) return 0;
        return totalDeposits > maxDeposits ? 0 : maxDeposits - totalDeposits;
    }

    /// @dev    See EIP-4626
    function maxMint(address) public view override(ERC4626, IVault) returns (uint256) {
        return convertToShares(maxDeposit(msg.sender));
    }

    /// @dev    See EIP-4626
    function deposit(
        uint256 assets,
        address receiver
    ) public override(ERC4626, IVault) notCustodied duringFunding onlyWhitelisted returns (uint256) {
        require(assets <= maxDeposit(receiver), "!maxDeposit");
        return ERC4626.deposit(assets, receiver);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if not during funding window
    function previewDeposit(uint256 assets) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndDuringFunding()) ? ERC4626.previewDeposit(assets) : 0;
    }

    /// @dev    See EIP-4626
    function mint(
        uint256 shares,
        address receiver
    ) public override(ERC4626, IVault) notCustodied duringFunding onlyWhitelisted returns (uint256) {
        require(shares <= maxMint(receiver), "!maxMint");
        return ERC4626.mint(shares, receiver);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if not during funding window
    function previewMint(uint256 shares) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndDuringFunding()) ? ERC4626.previewMint(shares) : 0;
    }

    /**
     * @notice Withdraw the underlying asset from the vault in exchange for vault shares
     * @dev Overrides the ERC4626 withdraw function. Can only be called when not custodied and not during an epoch.
     * @param assets The amount of the underlying asset to withdraw
     * @param receiver The address that will receive the underlying assets
     * @param _owner The address that the withdrawn shares are burned from
     * @return - The amount of shares burned
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address _owner
    ) public override(ERC4626, IVault) notCustodied notDuringEpoch onlyWhitelisted returns (uint256) {
        return ERC4626.withdraw(assets, receiver, _owner);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if funds are custodied or during epoch
    function previewWithdraw(uint256 assets) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndNotDuringEpoch()) ? ERC4626.previewWithdraw(assets) : 0;
    }

    /**
     * @notice Redeem vault shares in exchange for the underlying asset
     * @dev Overrides the ERC4626 redeem function. Can only be called when not custodied and not during an epoch.
     * @param shares The amount of shares to redeem
     * @param receiver The address that will receive the underlying assets
     * @param _owner The address that the redeemed shares are burned from
     * @return - The amount of underlying assets withdrawn
     */
    function redeem(
        uint256 shares,
        address receiver,
        address _owner
    ) public override(ERC4626, IVault) notCustodied notDuringEpoch onlyWhitelisted returns (uint256) {
        return ERC4626.redeem(shares, receiver, _owner);
    }

    /// @dev    See EIP-4626
    /// @notice Will return 0 if funds are custodied or during epoch
    function previewRedeem(uint256 shares) public view override(ERC4626, IVault) returns (uint256) {
        return (notCustodiedAndNotDuringEpoch()) ? ERC4626.previewRedeem(shares) : 0;
    }

    /// @dev    See EIP-4626
    function totalAssets() public view override(ERC4626, IVault) returns (uint256) {
        return custodied ? custodiedAmount : IERC20(asset()).balanceOf(address(this));
    }

    /**
     * @notice Internal function to handle the deposit logic
     * @dev Overrides the ERC4626 _deposit function. Updates the totalDeposits state variable.
     * @param caller The address that is making the deposit
     * @param receiver The address that will receive the vault shares
     * @param assets The amount of the underlying asset being deposited in uint256
     * @param shares The amount of shares being minted in uint256
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        ERC4626._deposit(caller, receiver, assets, shares);
        totalDeposits += assets;
    }

    /**
     * @notice Internal function to handle the withdraw logic
     * @dev Overrides the ERC4626 _withdraw function. Updates the totalDeposits state variable.
     * @param caller The address that is making the withdrawal
     * @param receiver The address that will receive the underlying assets
     * @param _owner The address that the withdrawn shares are burned from
     * @param assets The amount of the underlying asset being withdrawn in uint256
     * @param shares The amount of shares being burned in uint256
     */
    function _withdraw(address caller, address receiver, address _owner, uint256 assets, uint256 shares) internal override {
        if (totalDeposits > assets) {
            totalDeposits -= assets;
        } else {
            totalDeposits = 0;
        }
        ERC4626._withdraw(caller, receiver, _owner, assets, shares);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}