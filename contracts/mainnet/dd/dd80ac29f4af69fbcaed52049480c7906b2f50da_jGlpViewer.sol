// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

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
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
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
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

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
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC4626.sol)

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
 * CAUTION: Deposits and withdrawals may incur unexpected slippage. Users should verify that the amount received of
 * shares or assets is as expected. EOAs should operate through a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20Metadata private immutable _asset;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20Metadata asset_) {
        _asset = asset_;
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
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
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

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets.mulDiv(10**decimals(), 10**_asset.decimals(), rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares.mulDiv(10**_asset.decimals(), 10**decimals(), rounding)
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
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
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20, IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IGmxRewardRouter} from "../interfaces/IGmxRewardRouter.sol";
import {IGlpManager, IGMXVault} from "../interfaces/IGlpManager.sol";
import {IJonesGlpVaultRouter} from "../interfaces/IJonesGlpVaultRouter.sol";
import {Operable, Governable} from "../common/Operable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {WhitelistController} from "src/common/WhitelistController.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {JonesGlpLeverageStrategy} from "src/glp/strategies/JonesGlpLeverageStrategy.sol";
import {JonesGlpStableVault} from "src/glp/vaults/JonesGlpStableVault.sol";

contract GlpAdapter is Operable, ReentrancyGuard {
    IJonesGlpVaultRouter public vaultRouter;
    IGmxRewardRouter public gmxRouter = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    IAggregatorV3 public oracle = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    IERC20 public glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);
    IERC20 public usdc = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    WhitelistController public controller;
    JonesGlpLeverageStrategy public strategy;
    JonesGlpStableVault public stableVault;

    uint256 public flexibleTotalCap;
    bool public hatlistStatus;
    bool public useFlexibleCap;

    mapping(address => bool) public isValid;

    uint256 public constant BASIS_POINTS = 1e12;

    constructor(address[] memory _tokens, address _controller, address _strategy, address _stableVault)
        Governable(msg.sender)
    {
        uint8 i = 0;
        for (; i < _tokens.length;) {
            _editToken(_tokens[i], true);
            unchecked {
                i++;
            }
        }

        controller = WhitelistController(_controller);
        strategy = JonesGlpLeverageStrategy(_strategy);
        stableVault = JonesGlpStableVault(_stableVault);
    }

    function zapToGlp(address _token, uint256 _amount, bool _compound)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        IERC20(_token).approve(gmxRouter.glpManager(), _amount);
        uint256 mintedGlp = gmxRouter.mintAndStakeGlp(_token, _amount, 0, 0);

        glp.approve(address(vaultRouter), mintedGlp);
        uint256 receipts = vaultRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function zapToGlpEth(bool _compound) external payable nonReentrant returns (uint256) {
        _onlyEOA();

        uint256 mintedGlp = gmxRouter.mintAndStakeGlpETH{value: msg.value}(0, 0);

        glp.approve(address(vaultRouter), mintedGlp);

        uint256 receipts = vaultRouter.depositGlp(mintedGlp, msg.sender, _compound);

        return receipts;
    }

    function redeemGlpBasket(uint256 _shares, bool _compound, address _token, bool _native)
        external
        nonReentrant
        validToken(_token)
        returns (uint256)
    {
        _onlyEOA();

        uint256 assetsReceived = vaultRouter.redeemGlpAdapter(_shares, _compound, _token, msg.sender, _native);

        return assetsReceived;
    }

    function depositGlp(uint256 _assets, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        glp.transferFrom(msg.sender, address(this), _assets);

        glp.approve(address(vaultRouter), _assets);

        uint256 receipts = vaultRouter.depositGlp(_assets, msg.sender, _compound);

        return receipts;
    }

    function depositStable(uint256 _assets, bool _compound) external nonReentrant returns (uint256) {
        _onlyEOA();

        if (useFlexibleCap) {
            _checkUsdcCap(_assets);
        }

        usdc.transferFrom(msg.sender, address(this), _assets);

        usdc.approve(address(vaultRouter), _assets);

        uint256 receipts = vaultRouter.depositStable(_assets, _compound, msg.sender);

        return receipts;
    }

    function updateGmxRouter(address _gmxRouter) external onlyGovernor {
        gmxRouter = IGmxRewardRouter(_gmxRouter);
    }

    function updateVaultRouter(address _vaultRouter) external onlyGovernor {
        vaultRouter = IJonesGlpVaultRouter(_vaultRouter);
    }

    function updateStrategy(address _strategy) external onlyGovernor {
        strategy = JonesGlpLeverageStrategy(_strategy);
    }

    function _editToken(address _token, bool _valid) internal {
        isValid[_token] = _valid;
    }

    function toggleHatlist(bool _status) external onlyGovernor {
        hatlistStatus = _status;
    }

    function toggleFlexibleCap(bool _status) external onlyGovernor {
        useFlexibleCap = _status;
    }

    function updateFlexibleCap(uint256 _newAmount) public onlyGovernor {
        //18 decimals -> $1mi = 1_000_000e18
        flexibleTotalCap = _newAmount;
    }

    function getFlexibleCap() public view returns (uint256) {
        return flexibleTotalCap; //18 decimals
    }

    function usingFlexibleCap() public view returns (bool) {
        return useFlexibleCap;
    }

    function usingHatlist() public view returns (bool) {
        return hatlistStatus;
    }

    function getUsdcCap() public view returns (uint256 usdcCap) {
        usdcCap = (flexibleTotalCap * (strategy.getTargetLeverage() - BASIS_POINTS)) / strategy.getTargetLeverage();
    }

    function belowCap(uint256 _amount) public view returns (bool) {
        uint256 increaseDecimals = 10;
        (, int256 lastPrice,,,) = oracle.latestRoundData(); //8 decimals
        uint256 price = uint256(lastPrice) * (10 ** increaseDecimals); //18 DECIMALS
        uint256 usdcCap = getUsdcCap(); //18 decimals
        uint256 stableTvl = stableVault.tvl(); //18 decimals
        uint256 denominator = 1e6;

        uint256 notional = (price * _amount) / denominator;

        if (stableTvl + notional > usdcCap) {
            return false;
        }

        return true;
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !controller.isWhitelistedContract(msg.sender)) {
            revert NotWhitelisted();
        }
    }

    function _checkUsdcCap(uint256 _amount) private view {
        if (!belowCap(_amount)) {
            revert OverUsdcCap();
        }
    }

    function editToken(address _token, bool _valid) external onlyGovernor {
        _editToken(_token, _valid);
    }

    modifier validToken(address _token) {
        require(isValid[_token], "Invalid token.");
        _;
    }

    error NotHatlisted();
    error OverUsdcCap();
    error NotWhitelisted();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract Governable is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Governable} from "./Governable.sol";

abstract contract Operable is Governable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Governable} from "./Governable.sol";

abstract contract OperableKeepable is Governable {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    modifier onlyOperatorOrKeeper() {
        if (!(hasRole(OPERATOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    modifier onlyGovernorOrKeeper() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(KEEPER, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        _revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);

    error CallerIsNotKeeper();

    error CallerIsNotAllowed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Pausable {
    bool private _paused;
    bool private _emergencyPaused;

    constructor() {
        _paused = false;
        _emergencyPaused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function emergencyPaused() public view returns (bool) {
        return _emergencyPaused;
    }

    function _requireNotPaused() internal view {
        if (paused()) {
            revert ErrorPaused();
        }
    }

    function _requireNotEmergencyPaused() internal view {
        if (emergencyPaused()) {
            revert ErrorEmergencyPaused();
        }
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function _emergencyPause() internal whenNotEmergencyPaused {
        _paused = true;
        _emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }

    function _emergencyUnpause() internal whenEmergencyPaused {
        _emergencyPaused = false;
        _paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    modifier whenPaused() {
        if (!paused()) {
            revert ErrorNotPaused();
        }
        _;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenEmergencyPaused() {
        if (!emergencyPaused()) {
            revert ErrorNotEmergencyPaused();
        }
        _;
    }

    modifier whenNotEmergencyPaused() {
        _requireNotEmergencyPaused();
        _;
    }

    event Paused(address _account);
    event Unpaused(address _account);
    event EmergencyPaused(address _account);
    event EmergencyUnpaused(address _account);

    error ErrorPaused();
    error ErrorEmergencyPaused();
    error ErrorNotPaused();
    error ErrorNotEmergencyPaused();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IWhitelistController} from "../interfaces/IWhitelistController.sol";

contract WhitelistController is IWhitelistController, AccessControl, Ownable {
    mapping(bytes32 => IWhitelistController.RoleInfo) public roleInfo;
    mapping(address => bytes32) public userInfo;
    mapping(bytes32 => bool) public roleExists;

    bytes32 private constant INTERNAL = bytes32("INTERNAL");
    bytes32 private constant WHITELISTED_CONTRACTS = bytes32("WHITELISTED_CONTRACTS");
    uint256 public constant BASIS_POINTS = 1e12;

    constructor() {
        IWhitelistController.RoleInfo memory DEFAULT_ROLE = IWhitelistController.RoleInfo(false, false, 3e10, 97e8);

        bytes32 defaultRole = bytes32(0);
        createRole(defaultRole, DEFAULT_ROLE);
    }

    function updateDefaultRole(uint256 _jglpRetention, uint256 _jusdcRetention) public onlyOwner {
        IWhitelistController.RoleInfo memory NEW_DEFAULT_ROLE =
            IWhitelistController.RoleInfo(false, false, _jglpRetention, _jusdcRetention);

        bytes32 defaultRole = bytes32(0);
        createRole(defaultRole, NEW_DEFAULT_ROLE);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        override(IWhitelistController, AccessControl)
        returns (bool)
    {
        return super.hasRole(role, account);
    }

    function isInternalContract(address _account) public view returns (bool) {
        return hasRole(INTERNAL, _account);
    }

    function isWhitelistedContract(address _account) public view returns (bool) {
        return hasRole(WHITELISTED_CONTRACTS, _account);
    }

    function addToRole(bytes32 ROLE, address _account) public onlyOwner validRole(ROLE) {
        _addRoleUser(ROLE, _account);
    }

    function addToInternalContract(address _account) public onlyOwner {
        _grantRole(INTERNAL, _account);
    }

    function addToWhitelistContracts(address _account) public onlyOwner {
        _grantRole(WHITELISTED_CONTRACTS, _account);
    }

    function bulkAddToWhitelistContracts(address[] calldata _accounts) public onlyOwner {
        uint256 length = _accounts.length;
        for (uint8 i = 0; i < length;) {
            _grantRole(WHITELISTED_CONTRACTS, _accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function createRole(bytes32 _roleName, IWhitelistController.RoleInfo memory _roleInfo) public onlyOwner {
        roleExists[_roleName] = true;
        roleInfo[_roleName] = _roleInfo;
    }

    function _addRoleUser(bytes32 _role, address _user) internal {
        userInfo[_user] = _role;
    }

    function getUserRole(address _user) public view returns (bytes32) {
        return userInfo[_user];
    }

    function getDefaultRole() public view returns (IWhitelistController.RoleInfo memory) {
        bytes32 defaultRole = bytes32(0);
        return getRoleInfo(defaultRole);
    }

    function getRoleInfo(bytes32 _role) public view returns (IWhitelistController.RoleInfo memory) {
        return roleInfo[_role];
    }

    function removeUserFromRole(address _user) public onlyOwner {
        bytes32 zeroRole = bytes32(0x0);
        userInfo[_user] = zeroRole;
    }

    function removeFromInternalContract(address _account) public onlyOwner {
        _revokeRole(INTERNAL, _account);
    }

    function removeFromWhitelistContract(address _account) public onlyOwner {
        _revokeRole(WHITELISTED_CONTRACTS, _account);
    }

    function bulkRemoveFromWhitelistContract(address[] calldata _accounts) public onlyOwner {
        uint256 length = _accounts.length;
        for (uint8 i = 0; i < length;) {
            _revokeRole(WHITELISTED_CONTRACTS, _accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    modifier validRole(bytes32 _role) {
        require(roleExists[_role], "Role does not exist!");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IGMXVault} from "src/interfaces/IGMXVault.sol";
import {JonesGlpVault} from "src/glp/vaults/JonesGlpVault.sol";
import {JonesGlpVaultRouter} from "src/glp/JonesGlpVaultRouter.sol";
import {JonesGlpLeverageStrategy} from "src/glp/strategies/JonesGlpLeverageStrategy.sol";
import {GlpJonesRewards} from "src/glp/rewards/GlpJonesRewards.sol";
import {JonesGlpRewardTracker} from "src/glp/rewards/JonesGlpRewardTracker.sol";
import {JonesGlpStableVault} from "src/glp/vaults/JonesGlpStableVault.sol";
import {JonesGlpCompoundRewards} from "src/glp/rewards/JonesGlpCompoundRewards.sol";
import {WhitelistController} from "src/common/WhitelistController.sol";
import {IWhitelistController} from "src/interfaces/IWhitelistController.sol";
import {IGlpManager, IGMXVault} from "../interfaces/IGlpManager.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC20, IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {GlpAdapter} from "src/adapters/GlpAdapter.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract jGlpViewer is OwnableUpgradeable {
    using Math for uint256;

    IAggregatorV3 public constant oracle = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    uint256 public constant PRECISION = 1e30;
    uint256 public constant GMX_BASIS = 1e4;
    uint256 public constant GLP_DECIMALS = 1e18;
    uint256 public constant BASIS_POINTS = 1e12;

    IGlpManager public constant manager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    IERC20 public constant glp = IERC20(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf);

    struct Contracts {
        JonesGlpVault glpVault;
        JonesGlpVaultRouter router;
        GlpJonesRewards jonesRewards;
        JonesGlpRewardTracker glpTracker;
        JonesGlpRewardTracker stableTracker;
        JonesGlpLeverageStrategy strategy;
        JonesGlpStableVault stableVault;
        JonesGlpCompoundRewards glpCompounder;
        JonesGlpCompoundRewards stableCompounder;
        IGMXVault gmxVault;
        WhitelistController controller;
        GlpAdapter adapter;
    }

    Contracts public contracts;

    function initialize(Contracts memory _contracts) external initializer {
        __Ownable_init();

        contracts = _contracts;
    }

    // Glp Functions
    // GLP Vault: User deposit GLP are minted GVRT
    // GLP Reward Tracker: Are staked GVRT
    // GLP Compounder: Manage GVRT on behalf of the user are minted jGLP
    function getGlpTvl() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); //8 decimals
        uint256 totalAssets = getTotalGlp(); // total glp
        uint256 USDC = contracts.strategy.getStableGlpValue(totalAssets); // GMX GLP Redeem for USDC
        return USDC.mulDiv(uint256(lastPrice), 1e8);
    }

    function getTotalGlp() public view returns (uint256) {
        return contracts.glpVault.totalAssets(); //total glp
    }

    function getGlpMaxCap() public view returns (uint256) {
        return contracts.router.getMaxCapGlp();
    }

    function getGlpClaimableRewards(address _user) public view returns (uint256) {
        return contracts.glpTracker.claimable(_user);
    }

    function getGlpPriceUsd() public view returns (uint256) {
        return contracts.strategy.getStableGlpValue(GLP_DECIMALS); // USDC Price of sell 1 glp (1e18)
    }

    function getStakedGVRT(address _user) public view returns (uint256) {
        return contracts.glpTracker.stakedAmount(_user); // GVRT
    }

    function sharesToGlp(uint256 _shares) public view returns (uint256) {
        return contracts.glpVault.previewRedeem(_shares); // GVRT -> GLP
    }

    function getGVRT(uint256 _shares) public view returns (uint256) {
        return contracts.glpCompounder.previewRedeem(_shares); // jGLP -> GVRT
    }

    function getjGlp(address _user) public view returns (uint256) {
        return contracts.glpCompounder.balanceOf(_user); // jGLP
    }

    function getGlp(address _user, bool _compound) public view returns (uint256) {
        uint256 GVRT;
        if (_compound) {
            uint256 jGLP = getjGlp(_user); //jGLP
            GVRT = getGVRT(jGLP); // jGLP -> GVRT
        } else {
            GVRT = getStakedGVRT(_user); // GVRT
        }
        return sharesToGlp(GVRT); // GVRT -> GLP
    }

    function getGlpRatio(uint256 _jGLP) public view returns (uint256) {
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        return sharesToGlp(GVRT); // GVRT -> GLP
    }

    function getGlpRatioWithoutRetention(uint256 _jGLP) public view returns (uint256) {
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        uint256 glpPrice = ((manager.getAum(false) + manager.getAum(true)) / 2).mulDiv(
            GLP_DECIMALS, glp.totalSupply(), Math.Rounding.Down
        ); // 30 decimals
        uint256 glpDebt = contracts.strategy.stableDebt().mulDiv(PRECISION * BASIS_POINTS, glpPrice, Math.Rounding.Down); // 18 decimals
        uint256 strategyGlpBalance = glp.balanceOf(address(contracts.strategy)); // 18 decimals
        if (glpDebt > strategyGlpBalance) {
            return 0;
        }
        uint256 underlyingGlp = strategyGlpBalance - glpDebt; // 18 decimals
        return GVRT.mulDiv(underlyingGlp, contracts.glpVault.totalSupply(), Math.Rounding.Down); // GVRT -> GLP
    }

    // This function do not include the compound() before the redemption
    // which means the shares will be a little lower
    function getPreviewGlpDeposit(uint256 _assets, bool _compound) public view returns (uint256, uint256) {
        uint256 glpMintIncentives = contracts.strategy.glpMintIncentive(_assets);
        uint256 assetsToDeposit = _assets - glpMintIncentives;
        uint256 GVRT = contracts.glpVault.previewDeposit(assetsToDeposit);
        uint256 shares;
        if (_compound) {
            shares = contracts.glpCompounder.previewDeposit(GVRT);
        }
        return (shares, glpMintIncentives);
    }

    // Function to get the GLP amount retained by GMX when the user causes a deleverage(withdrawing)
    function getGMXDeleverageIncentive(uint256 _glpAmount) public view returns (uint256) {
        uint256 PRECISION = 1e30; // GMX uses 30 decimals
        uint256 GLP_DECIMALS = 1e18;
        uint256 USDC_DECIMALS = 1e6;

        uint256 amountToDeleverage = _glpAmount.mulDiv(contracts.strategy.getTargetLeverage() - BASIS_POINTS, BASIS_POINTS);

        IGMXVault vault = IGMXVault(manager.vault());

        // GLP price
        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmountUsdc = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(usdc));
        redemptionAmountUsdc = redemptionAmountUsdc.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals

        uint256 retentionBasisPoints = _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);
    
        return retentionBasisPoints;
    }

    // This function do not include the compound() before the redemption,
    // which means the final amount is a little higher
    function getGlpRedemption(uint256 _jGLP, address _caller) public view returns (uint256, uint256) {
        // GVRT Ratio without compounding
        uint256 GVRT = getGVRT(_jGLP); // jGLP -> GVRT
        uint256 GLP = sharesToGlp(GVRT); // GVRT -> GLP
        uint256 deleverageRetention = contracts.strategy.glpRedeemRetention(GLP); // GMX retention to deleverage
        GLP = GLP - deleverageRetention;

        // Get caller role and incentive retention
        bytes32 role = contracts.controller.getUserRole(_caller);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(role);

        uint256 retention = GLP.mulDiv(info.jGLP_RETENTION, BASIS_POINTS, Math.Rounding.Down); // Protocol retention
        return (GLP - retention, deleverageRetention + retention);
    }

    // USDC Functions
    // USDC Vault: User deposit USDC are minted UVRT
    // USDC Reward Tracker: Are staked UVRT
    // USDC Compounder: Manage UVRT on behalf of the user are minted jUSDC
    function getUSDCTvl() public view returns (uint256) {
        return contracts.stableVault.tvl(); // USDC Price * total USDC
    }

    function getTotalUSDC() public view returns (uint256) {
        return contracts.stableVault.totalAssets(); //total USDC
    }

    function getStakedUVRT(address _user) public view returns (uint256) {
        return contracts.stableTracker.stakedAmount(_user); // UVRT
    }

    function getUSDCClaimableRewards(address _user) public view returns (uint256) {
        return contracts.stableTracker.claimable(_user);
    }

    function sharesToUSDC(uint256 _shares) public view returns (uint256) {
        return contracts.stableVault.previewRedeem(_shares); // UVRT -> USDC
    }

    function getUVRT(uint256 _shares) public view returns (uint256) {
        return contracts.stableCompounder.previewRedeem(_shares); // jUSDC -> UVRT
    }

    function getjUSDC(address _user) public view returns (uint256) {
        return contracts.stableCompounder.balanceOf(_user); // jUSDC
    }

    function getUSDC(address _user, bool _compound) public view returns (uint256) {
        uint256 UVRT;
        if (_compound) {
            uint256 jUSDC = getjUSDC(_user); // jUSDC
            UVRT = getUVRT(jUSDC); // jUSDC -> UVRT
        } else {
            UVRT = getStakedUVRT(_user); // UVRT
        }
        return sharesToUSDC(UVRT); // UVRT -> USDC
    }

    function getUSDCRatio(uint256 _jUSDC) public view returns (uint256) {
        uint256 UVRT = getUVRT(_jUSDC); // jUSDC -> UVRT
        return sharesToUSDC(UVRT); // UVRT -> USDC
    }

    // This function do not include the compound() before the redemption
    // which means the shares will be a little lower
    function getPreviewUSDCDeposit(uint256 _assets, bool _compound) public view returns (uint256) {
        uint256 UVRT = contracts.stableVault.previewDeposit(_assets);
        uint256 shares;
        if (_compound) {
            shares = contracts.stableCompounder.previewDeposit(UVRT);
        }
        return shares;
    }

    // This function do not include the compound() before the redemption,
    // which means the final amount is a little higher
    function getUSDCRedemption(uint256 _jUSDC, address _caller) public view returns (uint256, uint256) {
        // GVRT Ratio without compounding
        uint256 UVRT = getUVRT(_jUSDC); // jUSDC -> UVRT
        uint256 USDC = sharesToUSDC(UVRT); // UVRT -> USDC

        uint256 stableVaultBalance = IERC20(usdc).balanceOf(address(contracts.stableVault));
        uint256 stablesFromVault = stableVaultBalance < USDC ? stableVaultBalance : USDC;

        uint256 gmxIncentive;

        if (stablesFromVault < USDC) {
            uint256 difference = USDC - stablesFromVault;
            gmxIncentive =
                (difference * contracts.strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
        }

        uint256 remainderStables = USDC - gmxIncentive; // GMX retention to deleverage

        // Get caller role and incentive retention
        bytes32 role = contracts.controller.getUserRole(_caller);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(role);

        uint256 retention = USDC.mulDiv(info.jUSDC_RETENTION, BASIS_POINTS, Math.Rounding.Down);

        uint256 realRetention;

        if (gmxIncentive < retention) {
            realRetention = retention - gmxIncentive;
            return (remainderStables - realRetention, retention);
        } else {
            realRetention = 0;
            return (remainderStables - realRetention, gmxIncentive);
        }
    }

    //Incentive due leverage, happen on every glp deposit
    function getGlpDepositIncentive(uint256 _glpAmount) public view returns (uint256) {
        return contracts.strategy.glpMintIncentive(_glpAmount);
    }

    function getGlpRedeemRetention(uint256 _glpAmount) public view returns (uint256) {
        return contracts.strategy.glpRedeemRetention(_glpAmount); //18 decimals
    }

    function getRedeemStableGMXIncentive(uint256 _stableAmount) public view returns (uint256) {
        return contracts.strategy.getRedeemStableGMXIncentive(_stableAmount);
    }

    // Jones emissiones available rewards

    function getJonesRewards(address _user) public view returns (uint256) {
        return contracts.jonesRewards.rewards(_user);
    }

    // User Role Info

    function getUserRoleInfo(address _user) public view returns (bool, bool, uint256, uint256) {
        bytes32 userRole = contracts.controller.getUserRole(_user);
        IWhitelistController.RoleInfo memory info = contracts.controller.getRoleInfo(userRole);

        return (info.jGLP_BYPASS_CAP, info.jUSDC_BYPASS_TIME, info.jGLP_RETENTION, info.jUSDC_RETENTION);
    }

    // User Withdraw Signal
    function getUserSignal(address _user, uint256 _epoch)
        public
        view
        returns (uint256 targetEpoch, uint256 commitedShares, bool redeemed, bool compound)
    {
        (targetEpoch, commitedShares, redeemed, compound) = contracts.router.withdrawSignal(_user, _epoch);
    }

    // Pause Functions
    function isRouterPaused() public view returns (bool) {
        return contracts.router.paused();
    }

    function isStableVaultPaused() public view returns (bool) {
        return contracts.stableVault.paused();
    }

    function isGlpVaultPaused() public view returns (bool) {
        return contracts.glpVault.paused();
    }

    //Strategy functions

    function getTargetLeverage() public view returns (uint256) {
        return contracts.strategy.getTargetLeverage();
    }

    function getUnderlyingGlp() public view returns (uint256) {
        return contracts.strategy.getUnderlyingGlp();
    }

    function getStrategyTvl() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); // 8 decimals
        uint256 totalGlp = glp.balanceOf(address(contracts.strategy)); // 18 decimals
        uint256 USDC = contracts.strategy.getStableGlpValue(totalGlp); // GMX GLP Redeem for USDC 6 decimals
        return USDC.mulDiv(uint256(lastPrice), 1e8);
    }

    function getStableDebt() public view returns (uint256) {
        (, int256 lastPrice,,,) = oracle.latestRoundData(); // 8 decimals
        return contracts.strategy.stableDebt().mulDiv(uint256(lastPrice), 1e8);
    }

    // Current Epoch
    function currentEpoch() public view returns (uint256) {
        return contracts.router.currentEpoch();
    }

    //Owner functions

    function updateGlpVault(address _newGlpVault) external onlyOwner {
        contracts.glpVault = JonesGlpVault(_newGlpVault);
    }

    function updateGlpVaultRouter(address _newGlpVaultRouter) external onlyOwner {
        contracts.router = JonesGlpVaultRouter(_newGlpVaultRouter);
    }

    function updateGlpRewardTracker(address _newGlpTracker) external onlyOwner {
        contracts.glpTracker = JonesGlpRewardTracker(_newGlpTracker);
    }

    function updateStableRewardTracker(address _newStableTracker) external onlyOwner {
        contracts.stableTracker = JonesGlpRewardTracker(_newStableTracker);
    }

    function updateJonesGlpLeverageStrategy(address _newJonesGlpLeverageStrategy) external onlyOwner {
        contracts.strategy = JonesGlpLeverageStrategy(_newJonesGlpLeverageStrategy);
    }

    function updateJonesGlpStableVault(address _newJonesGlpStableVault) external onlyOwner {
        contracts.stableVault = JonesGlpStableVault(_newJonesGlpStableVault);
    }

    function updatejGlpJonesGlpCompoundRewards(address _newJonesGlpCompoundRewards) external onlyOwner {
        contracts.glpCompounder = JonesGlpCompoundRewards(_newJonesGlpCompoundRewards);
    }

    function updateAdapter(address _newAdapter) external onlyOwner {
        contracts.adapter = GlpAdapter(_newAdapter);
    }

    function updatejUSDCJonesGlpCompoundRewards(address _newJonesUSDCCompoundRewards) external onlyOwner {
        contracts.stableCompounder = JonesGlpCompoundRewards(_newJonesUSDCCompoundRewards);
    }

    function updateJonesRewards(address _jonesRewards) external onlyOwner {
        contracts.jonesRewards = GlpJonesRewards(_jonesRewards);
    }

    function updateDeployment(Contracts memory _contracts) external onlyOwner {
        contracts = _contracts;
    }

    // This amount do not include the withdraw glp retention
    // you have to discount the glp withdraw retentions before using this function
    function previewRedeemGlp(address _token, uint256 _glpAmount) public view returns (uint256, uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply()); // 18 decimals

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(_token)); // 18 decimals

        redemptionAmount = redemptionAmount.mulDiv(10 ** token.decimals(), GLP_DECIMALS);

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return (redemptionAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS), retentionBasisPoints);
    }

    function previewMintGlp(address _token, uint256 _assetAmount) public view returns (uint256, uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 assetPrice = vault.getMinPrice(_token); // 30 decimals

        uint256 usdgAmount = _assetAmount.mulDiv(assetPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        uint256 amountAfterRetentions = _assetAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS); // 6 decimals

        uint256 mintAmount = amountAfterRetentions.mulDiv(assetPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        return (aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg), retentionBasisPoints); // 18 decimals
    }

    function getMintGlpIncentive(address _token, uint256 _assetAmount) public view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 assetPrice = vault.getMinPrice(_token); // 30 decimals

        uint256 usdgAmount = _assetAmount.mulDiv(assetPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, 10 ** token.decimals()); // 18 decimals

        return vault.getFeeBasisPoints(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
    }

    function getRedeemGlpRetention(address _token, uint256 _glpAmount) public view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        IERC20Metadata token = IERC20Metadata(_token);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(_token));

        redemptionAmount = redemptionAmount.mulDiv(10 ** token.decimals(), GLP_DECIMALS);

        return _getGMXBasisRetention(_token, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);
    }

    function _getGMXBasisRetention(
        address _token,
        uint256 _usdgDelta,
        uint256 _retentionBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        IGMXVault vault = contracts.gmxVault;

        if (!vault.hasDynamicFees()) return _retentionBasisPoints;

        uint256 initialAmount = _increment ? vault.usdgAmounts(_token) : vault.usdgAmounts(_token) - _usdgDelta;

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) return _retentionBasisPoints;

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mulDiv(initialDiff, targetAmount);
            return rebateBps > _retentionBasisPoints ? 0 : _retentionBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mulDiv(averageDiff, targetAmount);
        return _retentionBasisPoints + taxBps;
    }

    //Use when flexible cap status is TRUE
    //Returns 18 decimals
    function getUsdcCap() public view returns (uint256) {
        return contracts.adapter.getUsdcCap();
    }

    function usingFlexibleCap() public view returns (bool) {
        return contracts.adapter.usingFlexibleCap();
    }

    function usingHatlist() public view returns (bool) {
        return contracts.adapter.usingHatlist();
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {Pausable} from "../common/Pausable.sol";
import {WhitelistController} from "../common/WhitelistController.sol";
import {JonesGlpVault} from "./vaults/JonesGlpVault.sol";
import {JonesGlpStableVault} from "./vaults/JonesGlpStableVault.sol";
import {Governable} from "../common/Governable.sol";
import {GlpJonesRewards} from "./rewards/GlpJonesRewards.sol";
import {IGmxRewardRouter} from "../interfaces/IGmxRewardRouter.sol";
import {IWhitelistController} from "../interfaces/IWhitelistController.sol";
import {IJonesGlpLeverageStrategy} from "../interfaces/IJonesGlpLeverageStrategy.sol";
import {IIncentiveReceiver} from "../interfaces/IIncentiveReceiver.sol";
import {IJonesGlpRewardTracker} from "../interfaces/IJonesGlpRewardTracker.sol";
import {GlpAdapter} from "../adapters/GlpAdapter.sol";
import {IJonesGlpCompoundRewards} from "../interfaces/IJonesGlpCompoundRewards.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Errors} from "src/interfaces/Errors.sol";

contract JonesGlpVaultRouter is Governable, Pausable, ReentrancyGuard {
    bool public initialized;

    struct WithdrawalSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        bool redeemed;
        bool compound;
    }

    IGmxRewardRouter private constant router = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    address private constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    JonesGlpVault private glpVault;
    JonesGlpStableVault private glpStableVault;
    IJonesGlpLeverageStrategy public strategy;
    GlpJonesRewards private jonesRewards;
    IJonesGlpRewardTracker public glpRewardTracker;
    IJonesGlpRewardTracker public stableRewardTracker;
    IJonesGlpCompoundRewards private stableCompoundRewards;
    IJonesGlpCompoundRewards private glpCompoundRewards;
    IWhitelistController private whitelistController;
    IIncentiveReceiver private incentiveReceiver;
    GlpAdapter private adapter;

    IERC20 private glp;
    IERC20 private stable;

    // vault asset -> reward tracker
    mapping(address => IJonesGlpRewardTracker) public rewardTrackers;
    // vault asset -> reward compounder
    mapping(address => IJonesGlpCompoundRewards) public rewardCompounder;

    mapping(address => mapping(uint256 => WithdrawalSignal)) private userSignal;

    uint256 private constant BASIS_POINTS = 1e12;
    uint256 private constant EPOCH_DURATION = 1 days;
    uint256 public EXIT_COOLDOWN;

    constructor(
        JonesGlpVault _glpVault,
        JonesGlpStableVault _glpStableVault,
        IJonesGlpLeverageStrategy _strategy,
        GlpJonesRewards _jonesRewards,
        IJonesGlpRewardTracker _glpRewardTracker,
        IJonesGlpRewardTracker _stableRewardTracker,
        IJonesGlpCompoundRewards _glpCompoundRewards,
        IJonesGlpCompoundRewards _stableCompoundRewards,
        IWhitelistController _whitelistController,
        IIncentiveReceiver _incentiveReceiver
    ) Governable(msg.sender) {
        glpVault = _glpVault;
        glpStableVault = _glpStableVault;
        strategy = _strategy;
        jonesRewards = _jonesRewards;
        glpRewardTracker = _glpRewardTracker;
        stableRewardTracker = _stableRewardTracker;
        glpCompoundRewards = _glpCompoundRewards;
        stableCompoundRewards = _stableCompoundRewards;
        whitelistController = _whitelistController;

        incentiveReceiver = _incentiveReceiver;
    }

    function initialize(address _glp, address _stable, address _adapter) external onlyGovernor {
        if (initialized) {
            revert Errors.AlreadyInitialized();
        }

        rewardTrackers[_glp] = glpRewardTracker;
        rewardTrackers[_stable] = stableRewardTracker;
        rewardCompounder[_glp] = glpCompoundRewards;
        rewardCompounder[_stable] = stableCompoundRewards;

        glp = IERC20(_glp);
        stable = IERC20(_stable);
        adapter = GlpAdapter(_adapter);

        initialized = true;
    }

    // ============================= Whitelisted functions ================================ //

    /**
     * @notice The Adapter contract can deposit GLP to the system on behalf of the _sender
     * @param _assets Amount of assets deposited
     * @param _sender address of who is deposit the assets
     * @param _compound optional compounding rewards
     * @return Amount of shares jGLP minted
     */
    function depositGlp(uint256 _assets, address _sender, bool _compound) external whenNotPaused returns (uint256) {
        _onlyInternalContract(); //can only be adapter or compounder

        bytes32 role = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(role);

        IJonesGlpLeverageStrategy _strategy = strategy;
        JonesGlpVault _glpVault = glpVault;

        uint256 assetsUsdValue = _strategy.getStableGlpValue(_assets);
        uint256 underlyingUsdValue = _strategy.getStableGlpValue(_strategy.getUnderlyingGlp());
        uint256 maxTvlGlp = getMaxCapGlp();

        if ((assetsUsdValue + underlyingUsdValue) * BASIS_POINTS > maxTvlGlp && !info.jGLP_BYPASS_CAP) {
            revert Errors.MaxGlpTvlReached();
        }

        if (_compound) {
            glpCompoundRewards.compound();
        }

        (uint256 compoundShares, uint256 vaultShares) = _deposit(_glpVault, _sender, _assets, _compound);

        _strategy.onGlpDeposit(_assets);

        if (_compound) {
            emit DepositGlp(_sender, _assets, compoundShares, _compound);
            return compoundShares;
        }

        emit DepositGlp(_sender, _assets, vaultShares, _compound);

        return vaultShares;
    }

    /**
     * @notice Users & Whitelist contract can redeem GLP from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @return Amount of GLP remdeemed
     */
    function redeemGlp(uint256 _shares, bool _compound)
        external
        whenNotEmergencyPaused
        nonReentrant
        returns (uint256)
    {
        _onlyEOA();

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, msg.sender);
        }

        glpRewardTracker.withdraw(msg.sender, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlp(glpAmount, msg.sender, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice User & Whitelist contract can redeem GLP using any asset of GLP basket from the system
     * @param _shares Amount of jGLP deposited to redeem GLP
     * @param _compound flag if the rewards are compounding
     * @param _token address of asset token
     * @param _user address of the user that will receive the assets
     * @param _native flag if the user will receive raw ETH
     * @return Amount of assets redeemed
     */
    function redeemGlpAdapter(uint256 _shares, bool _compound, address _token, address _user, bool _native)
        external
        whenNotEmergencyPaused
        nonReentrant
        returns (uint256)
    {
        if (msg.sender != address(adapter)) {
            revert Errors.OnlyAdapter();
        }

        if (_compound) {
            glpCompoundRewards.compound();
            _shares = _unCompoundGlp(_shares, _user);
        }
        glpRewardTracker.withdraw(_user, _shares);
        JonesGlpVault _glpVault = glpVault;

        uint256 glpAmount = _glpVault.previewRedeem(_shares);

        _glpVault.burn(address(this), _shares);

        //We can't send glpAmount - retention here because it'd mess our rebalance
        glpAmount = strategy.onGlpRedeem(glpAmount);

        if (glpAmount > 0) {
            glpAmount = _distributeGlpAdapter(glpAmount, _user, _token, _native, _compound);
        }

        return glpAmount;
    }

    /**
     * @notice adapter & compounder can deposit Stable assets to the system
     * @param _assets Amount of Stables deposited
     * @param _compound optional compounding rewards
     * @return Amount of shares jUSDC minted
     */
    function depositStable(uint256 _assets, bool _compound, address _user) external whenNotPaused returns (uint256) {
        _onlyInternalContract(); //can only be adapter or compounder

        if (_compound) {
            stableCompoundRewards.compound();
        }

        (uint256 shares, uint256 track) = _deposit(glpStableVault, _user, _assets, _compound);

        if (_user != address(rewardCompounder[address(stable)])) {
            jonesRewards.stake(_user, track);
        }

        strategy.onStableDeposit();

        emit DepositStables(_user, _assets, shares, _compound);

        return shares;
    }

    /**
     * @notice Users can signal a stable redeem or redeem directly if user has the role to do it.
     * @dev The Jones & Stable rewards stop here
     * @param _shares Amount of shares jUSDC to redeem
     * @param _compound flag if the rewards are compounding
     * @return Epoch when will be possible the redeem or the amount of stables received in case user has special role
     */
    function stableWithdrawalSignal(uint256 _shares, bool _compound)
        external
        whenNotEmergencyPaused
        returns (uint256)
    {
        _onlyEOA();

        bytes32 userRole = whitelistController.getUserRole(msg.sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        uint256 targetEpoch = currentEpoch() + EXIT_COOLDOWN;
        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][targetEpoch];

        if (userWithdrawalSignal.commitedShares > 0) {
            revert Errors.WithdrawalSignalAlreadyDone();
        }

        if (_compound) {
            stableCompoundRewards.compound();
            uint256 assets = stableCompoundRewards.previewRedeem(_shares);
            uint256 assetDeposited = stableCompoundRewards.totalAssetsToDeposits(msg.sender, assets);
            jonesRewards.getReward(msg.sender);
            jonesRewards.withdraw(msg.sender, assetDeposited);
            _shares = _unCompoundStables(_shares);
        } else {
            jonesRewards.getReward(msg.sender);
            jonesRewards.withdraw(msg.sender, _shares);
        }

        rewardTrackers[address(stable)].withdraw(msg.sender, _shares);

        if (info.jUSDC_BYPASS_TIME) {
            return _redeemDirectly(_shares, info.jUSDC_RETENTION, _compound);
        }

        userSignal[msg.sender][targetEpoch] = WithdrawalSignal(targetEpoch, _shares, false, _compound);

        emit StableWithdrawalSignal(msg.sender, _shares, targetEpoch, _compound);

        return targetEpoch;
    }

    function _redeemDirectly(uint256 _shares, uint256 _retention, bool _compound) private returns (uint256) {
        uint256 stableAmount = glpStableVault.previewRedeem(_shares);
        uint256 stablesFromVault = _borrowStables(stableAmount);
        uint256 gmxIncentive;

        IJonesGlpLeverageStrategy _strategy = strategy;

        // Only redeem from strategy if there is not enough on the vault
        if (stablesFromVault < stableAmount) {
            uint256 difference = stableAmount - stablesFromVault;
            gmxIncentive = (difference * _strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
            _strategy.onStableRedeem(difference, difference - gmxIncentive);
        }

        uint256 remainderStables = stableAmount - gmxIncentive;

        IERC20 stableToken = stable;

        if (stableToken.balanceOf(address(this)) < remainderStables) {
            revert Errors.NotEnoughStables();
        }

        glpStableVault.burn(address(this), _shares);

        uint256 retention = ((stableAmount * _retention) / BASIS_POINTS);

        uint256 realRetention = gmxIncentive < retention ? retention - gmxIncentive : 0;

        uint256 amountAfterRetention = remainderStables - realRetention;

        if (amountAfterRetention > 0) {
            stableToken.transfer(msg.sender, amountAfterRetention);
        }

        if (realRetention > 0) {
            stableToken.approve(address(stableRewardTracker), realRetention);
            stableRewardTracker.depositRewards(realRetention);
        }

        // Information needed to calculate stable retentions
        emit RedeemStable(msg.sender, amountAfterRetention, retention, realRetention, _compound);

        return amountAfterRetention;
    }

    /**
     * @notice Users can cancel the signal to stable redeem
     * @param _epoch Target epoch
     * @param _compound true if the rewards should be compound
     */
    function cancelStableWithdrawalSignal(uint256 _epoch, bool _compound) external {
        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][_epoch];

        if (userWithdrawalSignal.redeemed) {
            revert Errors.WithdrawalAlreadyCompleted();
        }

        uint256 snapshotCommitedShares = userWithdrawalSignal.commitedShares;

        if (snapshotCommitedShares == 0) {
            return;
        }

        userWithdrawalSignal.commitedShares = 0;
        userWithdrawalSignal.targetEpoch = 0;
        userWithdrawalSignal.compound = false;

        IJonesGlpRewardTracker tracker = stableRewardTracker;

        jonesRewards.stake(msg.sender, snapshotCommitedShares);

        if (_compound) {
            stableCompoundRewards.compound();
            IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];
            IERC20(address(glpStableVault)).approve(address(compounder), snapshotCommitedShares);
            compounder.deposit(snapshotCommitedShares, msg.sender);
        } else {
            IERC20(address(glpStableVault)).approve(address(tracker), snapshotCommitedShares);
            tracker.stake(msg.sender, snapshotCommitedShares);
        }

        // Update struct storage
        userSignal[msg.sender][_epoch] = userWithdrawalSignal;

        emit CancelStableWithdrawalSignal(msg.sender, snapshotCommitedShares, _compound);
    }

    /**
     * @notice Users can redeem stable assets from the system
     * @param _epoch Target epoch
     * @return Amount of stables reeemed
     */
    function redeemStable(uint256 _epoch) external whenNotEmergencyPaused returns (uint256) {
        bytes32 userRole = whitelistController.getUserRole(msg.sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        WithdrawalSignal memory userWithdrawalSignal = userSignal[msg.sender][_epoch];

        if (currentEpoch() < userWithdrawalSignal.targetEpoch || userWithdrawalSignal.targetEpoch == 0) {
            revert Errors.NotRightEpoch();
        }

        if (userWithdrawalSignal.redeemed) {
            revert Errors.WithdrawalAlreadyCompleted();
        }

        if (userWithdrawalSignal.commitedShares == 0) {
            revert Errors.WithdrawalWithNoShares();
        }

        uint256 stableAmount = glpStableVault.previewRedeem(userWithdrawalSignal.commitedShares);

        uint256 stablesFromVault = _borrowStables(stableAmount);

        uint256 gmxIncentive;

        IJonesGlpLeverageStrategy _strategy = strategy;

        // Only redeem from strategy if there is not enough on the vault
        if (stablesFromVault < stableAmount) {
            uint256 difference = stableAmount - stablesFromVault;
            gmxIncentive = (difference * _strategy.getRedeemStableGMXIncentive(difference) * 1e8) / BASIS_POINTS;
            _strategy.onStableRedeem(difference, difference - gmxIncentive);
        }

        uint256 remainderStables = stableAmount - gmxIncentive;

        IERC20 stableToken = stable;

        if (stableToken.balanceOf(address(this)) < remainderStables) {
            revert Errors.NotEnoughStables();
        }

        glpStableVault.burn(address(this), userWithdrawalSignal.commitedShares);

        userSignal[msg.sender][_epoch] = WithdrawalSignal(
            userWithdrawalSignal.targetEpoch, userWithdrawalSignal.commitedShares, true, userWithdrawalSignal.compound
        );

        uint256 retention = ((stableAmount * info.jUSDC_RETENTION) / BASIS_POINTS);

        uint256 realRetention = gmxIncentive < retention ? retention - gmxIncentive : 0;

        uint256 amountAfterRetention = remainderStables - realRetention;

        if (amountAfterRetention > 0) {
            stableToken.transfer(msg.sender, amountAfterRetention);
        }

        if (realRetention > 0) {
            stableToken.approve(address(stableRewardTracker), realRetention);
            stableRewardTracker.depositRewards(realRetention);
        }

        // Information needed to calculate stable retention
        emit RedeemStable(msg.sender, amountAfterRetention, retention, realRetention, userWithdrawalSignal.compound);

        return amountAfterRetention;
    }

    /**
     * @notice User & Whitelist contract can claim their rewards
     * @return Stable rewards comming from Stable deposits
     * @return ETH rewards comming from GLP deposits
     * @return Jones rewards comming from jones emission
     */
    function claimRewards() external returns (uint256, uint256, uint256) {
        strategy.claimGlpRewards();

        uint256 stableRewards = stableRewardTracker.claim(msg.sender);

        stable.transfer(msg.sender, stableRewards);

        uint256 glpRewards = glpRewardTracker.claim(msg.sender);

        IERC20(weth).transfer(msg.sender, glpRewards);

        uint256 _jonesRewards = jonesRewards.getReward(msg.sender);

        emit ClaimRewards(msg.sender, stableRewards, glpRewards, _jonesRewards);

        return (stableRewards, glpRewards, _jonesRewards);
    }

    /**
     * @notice User Compound rewards
     * @param _stableDeposits Amount of stable shares to compound
     * @param _glpDeposits Amount of glp shares to compound
     * @return Amount of USDC shares
     * @return Amount of GLP shares
     */
    function compoundRewards(uint256 _stableDeposits, uint256 _glpDeposits) external returns (uint256, uint256) {
        return (compoundStableRewards(_stableDeposits), compoundGlpRewards(_glpDeposits));
    }

    /**
     * @notice User UnCompound rewards
     * @param _stableDeposits Amount of stable shares to uncompound
     * @param _glpDeposits Amount of glp shares to uncompound
     * @return Amount of USDC shares
     * @return Amount of GLP shares
     */
    function unCompoundRewards(uint256 _stableDeposits, uint256 _glpDeposits, address _user)
        external
        returns (uint256, uint256)
    {
        return (unCompoundStableRewards(_stableDeposits), unCompoundGlpRewards(_glpDeposits, _user));
    }

    /**
     * @notice User Compound GLP rewards
     * @param _shares Amount of glp shares to compound
     * @return Amount of jGLP shares
     */
    function compoundGlpRewards(uint256 _shares) public returns (uint256) {
        glpCompoundRewards.compound();
        // claim rewards & mint GLP

        IJonesGlpLeverageStrategy _strategy = strategy;

        _strategy.claimGlpRewards();
        uint256 rewards = glpRewardTracker.claim(msg.sender); // WETH

        uint256 rewardShares;
        if (rewards != 0) {
            IERC20(weth).approve(router.glpManager(), rewards);
            uint256 glpAmount = router.mintAndStakeGlp(weth, rewards, 0, 0);

            // vault deposit GLP to get jGLP
            glp.approve(address(glpVault), glpAmount);
            rewardShares = glpVault.deposit(glpAmount, address(this));
        }

        // withdraw jGlp
        uint256 currentShares = glpRewardTracker.withdraw(msg.sender, _shares);

        // Stake in Rewards Tracker & Deposit into compounder
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(glp)];
        uint256 totalShares = currentShares + rewardShares;
        IERC20(address(glpVault)).approve(address(compounder), totalShares);
        uint256 shares = compounder.deposit(totalShares, msg.sender);

        emit CompoundGlp(msg.sender, totalShares);

        return shares;
    }

    /**
     * @notice User UnCompound GLP rewards
     * @param _shares Amount of glp shares to uncompound
     * @return Amount of GLP shares
     */
    function unCompoundGlpRewards(uint256 _shares, address _user) public returns (uint256) {
        glpCompoundRewards.compound();
        return _unCompoundGlp(_shares, _user);
    }

    /**
     * @notice User Compound Stable rewards
     * @param _shares Amount of stable shares to compound
     * @return Amount of jUSDC shares
     */
    function compoundStableRewards(uint256 _shares) public returns (uint256) {
        stableCompoundRewards.compound();
        // claim rewards & deposit USDC
        strategy.claimGlpRewards();
        uint256 rewards = stableRewardTracker.claim(msg.sender); // USDC

        // vault deposit USDC to get jUSDC
        uint256 rewardShares;
        if (rewards > 0) {
            stable.approve(address(glpStableVault), rewards);
            rewardShares = glpStableVault.deposit(rewards, address(this));
        }

        // withdraw jUSDC
        uint256 currentShares = stableRewardTracker.withdraw(msg.sender, _shares);

        // Stake in Rewards Tracker & Deposit into compounder
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];
        uint256 totalShares = currentShares + rewardShares;
        IERC20(address(glpStableVault)).approve(address(compounder), totalShares);
        uint256 shares = compounder.deposit(totalShares, msg.sender);

        emit CompoundStables(msg.sender, totalShares);

        return shares;
    }

    /**
     * @notice User UnCompound rewards
     * @param _shares Amount of stable shares to uncompound
     * @return Amount of USDC shares
     */
    function unCompoundStableRewards(uint256 _shares) public returns (uint256) {
        stableCompoundRewards.compound();
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];

        uint256 assets = compounder.previewRedeem(_shares);
        uint256 assetsDeposited = compounder.totalAssetsToDeposits(msg.sender, assets);

        uint256 difference = assets - assetsDeposited;
        if (difference > 0) {
            jonesRewards.stake(msg.sender, difference);
        }

        return _unCompoundStables(_shares);
    }

    // ============================= External functions ================================ //
    /**
     * @notice Return user withdrawal signal
     * @param user address of user
     * @param epoch address of user
     * @return Targe Epoch
     * @return Commited shares
     * @return Redeem boolean
     */
    function withdrawSignal(address user, uint256 epoch) external view returns (uint256, uint256, bool, bool) {
        WithdrawalSignal memory userWithdrawalSignal = userSignal[user][epoch];
        return (
            userWithdrawalSignal.targetEpoch,
            userWithdrawalSignal.commitedShares,
            userWithdrawalSignal.redeemed,
            userWithdrawalSignal.compound
        );
    }

    /**
     * @notice Return the max amount of GLP that can be deposit in order to be alaign with the target leverage
     * @return GLP Cap
     */
    function getMaxCapGlp() public view returns (uint256) {
        return (glpStableVault.tvl() * BASIS_POINTS) / (strategy.getTargetLeverage() - BASIS_POINTS); // 18 decimals
    }

    // ============================= Governor functions ================================ //
    /**
     * @notice Set exit cooldown length in days
     * @param _days amount of days a user needs to wait to withdraw his stables
     */
    function setExitCooldown(uint256 _days) external onlyGovernor {
        EXIT_COOLDOWN = _days * EPOCH_DURATION;
    }

    /**
     * @notice Set Jones Rewards Contract
     * @param _jonesRewards Contract that manage Jones Rewards
     */
    function setJonesRewards(GlpJonesRewards _jonesRewards) external onlyGovernor {
        jonesRewards = _jonesRewards;
    }

    /**
     * @notice Set Leverage Strategy Contract
     * @param _leverageStrategy Leverage Strategy address
     */
    function setLeverageStrategy(address _leverageStrategy) external onlyGovernor {
        strategy = IJonesGlpLeverageStrategy(_leverageStrategy);
    }

    /**
     * @notice Set Stable Compound Contract
     * @param _stableCompoundRewards Stable Compound address
     */
    function setStableCompoundRewards(address _stableCompoundRewards) external onlyGovernor {
        stableCompoundRewards = IJonesGlpCompoundRewards(_stableCompoundRewards);
        rewardCompounder[address(stable)] = stableCompoundRewards;
    }

    /**
     * @notice Set GLP Compound Contract
     * @param _glpCompoundRewards GLP Compound address
     */
    function setGlpCompoundRewards(address _glpCompoundRewards) external onlyGovernor {
        glpCompoundRewards = IJonesGlpCompoundRewards(_glpCompoundRewards);
        rewardCompounder[address(glp)] = glpCompoundRewards;
    }

    /**
     * @notice Set Stable Tracker Contract
     * @param _stableRewardTracker Stable Tracker address
     */
    function setStableRewardTracker(address _stableRewardTracker) external onlyGovernor {
        stableRewardTracker = IJonesGlpRewardTracker(_stableRewardTracker);
        rewardTrackers[address(stable)] = stableRewardTracker;
    }

    /**
     * @notice Set GLP Tracker Contract
     * @param _glpRewardTracker GLP Tracker address
     */
    function setGlpRewardTracker(address _glpRewardTracker) external onlyGovernor {
        glpRewardTracker = IJonesGlpRewardTracker(_glpRewardTracker);
        rewardTrackers[address(glp)] = glpRewardTracker;
    }

    /**
     * @notice Set a new incentive Receiver address
     * @param _newIncentiveReceiver Incentive Receiver Address
     */
    function setIncentiveReceiver(address _newIncentiveReceiver) external onlyGovernor {
        incentiveReceiver = IIncentiveReceiver(_newIncentiveReceiver);
    }

    /**
     * @notice Set GLP Adapter Contract
     * @param _adapter GLP Adapter address
     */
    function setGlpAdapter(address _adapter) external onlyGovernor {
        adapter = GlpAdapter(_adapter);
    }

    // ============================= Private functions ================================ //

    function _deposit(IERC4626 _vault, address _caller, uint256 _assets, bool compound)
        private
        returns (uint256, uint256)
    {
        IERC20 asset = IERC20(_vault.asset());
        address adapterAddress = address(adapter);
        IJonesGlpRewardTracker tracker = rewardTrackers[address(asset)];

        if (msg.sender == adapterAddress) {
            asset.transferFrom(adapterAddress, address(this), _assets);
        } else {
            asset.transferFrom(_caller, address(this), _assets);
        }

        uint256 vaultShares = _vaultDeposit(_vault, _assets);

        uint256 compoundShares;

        if (compound) {
            IJonesGlpCompoundRewards compounder = rewardCompounder[address(asset)];
            IERC20(address(_vault)).approve(address(compounder), vaultShares);
            compoundShares = compounder.deposit(vaultShares, _caller);
        } else {
            IERC20(address(_vault)).approve(address(tracker), vaultShares);
            tracker.stake(_caller, vaultShares);
        }

        return (compoundShares, vaultShares);
    }

    function _distributeGlp(uint256 _amount, address _dest, bool _compound) private returns (uint256) {
        uint256 retention = _chargeIncentive(_amount, _dest);
        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        uint256 glpAfterRetention = _amount - retention;

        glp.transfer(_dest, glpAfterRetention);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, glpAfterRetention, retention, wethAmount, address(0), 0, _compound);

        return glpAfterRetention;
    }

    function _distributeGlpAdapter(uint256 _amount, address _dest, address _token, bool _native, bool _compound)
        private
        returns (uint256)
    {
        uint256 retention = _chargeIncentive(_amount, _dest);

        uint256 wethAmount;

        if (retention > 0) {
            wethAmount = router.unstakeAndRedeemGlp(weth, retention, 0, address(this));
            uint256 jonesRetention = (wethAmount * 2) / 3;
            IERC20(weth).approve(address(incentiveReceiver), jonesRetention);
            incentiveReceiver.deposit(weth, jonesRetention);
            IERC20(weth).approve(address(glpRewardTracker), wethAmount - jonesRetention);

            glpRewardTracker.depositRewards(wethAmount - jonesRetention);
        }

        if (_native) {
            uint256 ethAmount = router.unstakeAndRedeemGlpETH(_amount - retention, 0, payable(_dest));

            // Information needed to calculate glp retention
            emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, address(0), ethAmount, _compound);

            return ethAmount;
        }

        uint256 assetAmount = router.unstakeAndRedeemGlp(_token, _amount - retention, 0, _dest);

        // Information needed to calculate glp retention
        emit RedeemGlp(_dest, _amount - retention, retention, wethAmount, _token, 0, _compound);

        return assetAmount;
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    function _borrowStables(uint256 _amount) private returns (uint256) {
        JonesGlpStableVault stableVault = glpStableVault;

        uint256 balance = stable.balanceOf(address(stableVault));
        if (balance == 0) {
            return 0;
        }

        uint256 amountToBorrow = balance < _amount ? balance : _amount;

        emit BorrowStables(amountToBorrow);

        return stableVault.borrow(amountToBorrow);
    }

    function _chargeIncentive(uint256 _withdrawAmount, address _sender) private view returns (uint256) {
        bytes32 userRole = whitelistController.getUserRole(_sender);
        IWhitelistController.RoleInfo memory info = whitelistController.getRoleInfo(userRole);

        return (_withdrawAmount * info.jGLP_RETENTION) / BASIS_POINTS;
    }

    function _unCompoundGlp(uint256 _shares, address _user) private returns (uint256) {
        if (msg.sender != address(adapter) && msg.sender != _user) {
            revert Errors.OnlyAuthorized();
        }

        IJonesGlpCompoundRewards compounder = rewardCompounder[address(glp)];

        uint256 shares = compounder.redeem(_shares, _user);

        emit unCompoundGlp(_user, _shares);

        return shares;
    }

    function _unCompoundStables(uint256 _shares) private returns (uint256) {
        IJonesGlpCompoundRewards compounder = rewardCompounder[address(stable)];

        uint256 shares = compounder.redeem(_shares, msg.sender);

        emit unCompoundStables(msg.sender, _shares);

        return shares;
    }

    function _vaultDeposit(IERC4626 _vault, uint256 _assets) private returns (uint256) {
        address asset = _vault.asset();
        address vaultAddress = address(_vault);
        uint256 vaultShares;
        if (_vault.asset() == address(glp)) {
            uint256 glpMintIncentives = strategy.glpMintIncentive(_assets);

            uint256 assetsToDeposit = _assets - glpMintIncentives;

            IERC20(asset).approve(vaultAddress, assetsToDeposit);

            vaultShares = _vault.deposit(assetsToDeposit, address(this));
            if (glpMintIncentives > 0) {
                glp.transfer(vaultAddress, glpMintIncentives);
            }

            emit VaultDeposit(vaultAddress, _assets, glpMintIncentives);
        } else {
            IERC20(asset).approve(vaultAddress, _assets);
            vaultShares = _vault.deposit(_assets, address(this));
            emit VaultDeposit(vaultAddress, _assets, 0);
        }
        return vaultShares;
    }

    function _onlyInternalContract() private view {
        if (!whitelistController.isInternalContract(msg.sender)) {
            revert Errors.CallerIsNotInternalContract();
        }
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin && !whitelistController.isWhitelistedContract(msg.sender)) {
            revert Errors.CallerIsNotWhitelisted();
        }
    }

    function togglePause() external onlyGovernor {
        if (paused()) {
            _unpause();
            return;
        }

        _pause();
    }

    function toggleEmergencyPause() external onlyGovernor {
        if (emergencyPaused()) {
            _emergencyUnpause();
            return;
        }

        _emergencyPause();
    }

    /**
     * @notice Emergency withdraw UVRT in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        IERC20 UVRT = IERC20(address(glpStableVault));
        uint256 currentBalance = UVRT.balanceOf(address(this));

        if (currentBalance == 0) {
            return;
        }

        UVRT.transfer(_to, currentBalance);

        emit EmergencyWithdraw(_to, currentBalance);
    }

    event DepositGlp(address indexed _to, uint256 _amount, uint256 _sharesReceived, bool _compound);
    event DepositStables(address indexed _to, uint256 _amount, uint256 _sharesReceived, bool _compound);
    event VaultDeposit(address indexed vault, uint256 _amount, uint256 _retention);
    event RedeemGlp(
        address indexed _to,
        uint256 _amount,
        uint256 _retentions,
        uint256 _ethRetentions,
        address _token,
        uint256 _ethAmount,
        bool _compound
    );
    event RedeemStable(
        address indexed _to, uint256 _amount, uint256 _retentions, uint256 _realRetentions, bool _compound
    );
    event ClaimRewards(address indexed _to, uint256 _stableAmount, uint256 _wEthAmount, uint256 _amountJones);
    event CompoundGlp(address indexed _to, uint256 _amount);
    event CompoundStables(address indexed _to, uint256 _amount);
    event unCompoundGlp(address indexed _to, uint256 _amount);
    event unCompoundStables(address indexed _to, uint256 _amount);
    event StableWithdrawalSignal(
        address indexed sender, uint256 _shares, uint256 indexed _targetEpochTs, bool _compound
    );
    event CancelStableWithdrawalSignal(address indexed sender, uint256 _shares, bool _compound);
    event BorrowStables(uint256 indexed _amountBorrowed);
    event EmergencyWithdraw(address indexed _to, uint256 indexed _amount);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Operable, Governable} from "src/common/Operable.sol";
import {IJonesGlpOldRewards} from "src/interfaces/IJonesGlpOldRewards.sol";

contract GlpJonesRewards is Operable, ReentrancyGuard {
    IERC20 public immutable rewardsToken;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    IJonesGlpOldRewards oldReward;

    constructor(address _rewardToken, address _oldJonesRewards) Governable(msg.sender) ReentrancyGuard() {
        rewardsToken = IERC20(_rewardToken);
        oldReward = IJonesGlpOldRewards(_oldJonesRewards);
    }

    // ============================= Modifiers ================================ //

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            uint256 oldBalance = oldReward.balanceOf(_account);
            if (oldBalance > 0) {
                oldReward.getReward(_account);
                oldReward.withdraw(_account, oldBalance);
                balanceOf[_account] += oldBalance;
                totalSupply += oldBalance;
                emit Stake(_account, oldBalance);
            }
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    // ============================= Operator functions ================================ //

    /**
     * @notice Virtual Stake, an accountability of the deposit
     * @dev No asset are transferred here is it just the accountability
     * @param _user Address of depositor
     * @param _amount Amount deposited
     */
    function stake(address _user, uint256 _amount) external onlyOperator updateReward(_user) {
        if (_amount > 0) {
            balanceOf[_user] += _amount;
            totalSupply += _amount;
        }
        emit Stake(_user, _amount);
    }

    /**
     * @notice Virtual withdraw, an accountability of the withdraw
     * @dev No asset have to be transfer here is it just the accountability
     * @param _user Address of withdrawal
     * @param _amount Amount to withdraw
     */
    function withdraw(address _user, uint256 _amount) external onlyOperator updateReward(_user) {
        if (_amount > 0) {
            balanceOf[_user] -= _amount;
            totalSupply -= _amount;
        }

        emit Withdraw(_user, _amount);
    }

    /**
     * @notice Transfer respective rewards, Jones emissions, to the _user address
     * @param _user Address where the rewards are transferred
     * @return Amount of rewards, Jones emissions
     */
    function getReward(address _user) external onlyOperator updateReward(_user) nonReentrant returns (uint256) {
        uint256 reward = rewards[_user];
        if (reward > 0) {
            rewards[_user] = 0;
            rewardsToken.transfer(_user, reward);
        }

        emit GetReward(_user, reward);

        return reward;
    }

    // ============================= Public functions ================================ //

    /**
     * @notice Return the last time a reward was applie
     * @return Timestamp when the last reward happened
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    /**
     * @notice Return the amount of reward per tokend deposited
     * @return Amount of rewards, jones emissions
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    /**
     * @notice Return the total jones emissions earned by an user
     * @return Total emissions earned
     */
    function earned(address _user) public view returns (uint256) {
        return ((balanceOf[_user] * (rewardPerToken() - userRewardPerTokenPaid[_user])) / 1e18) + rewards[_user];
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set the duration of the rewards
     * @param _duration timestamp based duration
     */
    function setRewardsDuration(uint256 _duration) external onlyGovernor {
        if (block.timestamp <= finishAt) {
            revert DurationNotFinished();
        }

        duration = _duration;

        emit UpdateRewardsDuration(finishAt, _duration + block.timestamp);
    }

    /**
     * @notice Notify Reward Amount for a specific _amount
     * @param _amount AMount to calculate the rewards
     */
    function notifyRewardAmount(uint256 _amount) external onlyGovernor updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        if (rewardRate == 0) {
            revert ZeroRewardRate();
        }
        if (rewardRate * duration > rewardsToken.balanceOf(address(this))) {
            revert NotEnoughBalance();
        }

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;

        emit NotifyRewardAmount(_amount, finishAt);
    }

    // ============================= Private functions ================================ //
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    // ============================= Events ================================ //

    event Stake(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _to, uint256 _amount);
    event GetReward(address indexed _to, uint256 _rewards);
    event UpdateRewardsDuration(uint256 _oldEnding, uint256 _newEnding);
    event NotifyRewardAmount(uint256 _amount, uint256 _finishAt);

    // ============================= Errors ================================ //

    error ZeroRewardRate();
    error NotEnoughBalance();
    error DurationNotFinished();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable} from "src/common/Governable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OperableKeepable} from "src/common/OperableKeepable.sol";
import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {JonesGlpVaultRouter} from "src/glp/JonesGlpVaultRouter.sol";
import {IJonesGlpCompoundRewards} from "src/interfaces/IJonesGlpCompoundRewards.sol";
import {IJonesGlpRewardTracker} from "src/interfaces/IJonesGlpRewardTracker.sol";
import {IIncentiveReceiver} from "src/interfaces/IIncentiveReceiver.sol";
import {GlpJonesRewards} from "src/glp/rewards/GlpJonesRewards.sol";

contract JonesGlpCompoundRewards is IJonesGlpCompoundRewards, ERC20, OperableKeepable, ReentrancyGuard {
    using Math for uint256;

    uint256 public constant BASIS_POINTS = 1e12;

    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant glp = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    IGmxRewardRouter public gmxRouter = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);

    IERC20 public asset;
    IERC20Metadata public vaultToken;

    uint256 public stableRetentionPercentage;
    uint256 public glpRetentionPercentage;

    uint256 public totalAssets; // total assets;
    uint256 public totalAssetsDeposits; // total assets deposits;

    mapping(address => uint256) public receiptBalance; // assets deposits

    JonesGlpVaultRouter public router;
    IJonesGlpRewardTracker public tracker;
    IIncentiveReceiver public incentiveReceiver;
    GlpJonesRewards public jonesRewards;

    constructor(
        uint256 _stableRetentionPercentage,
        uint256 _glpRetentionPercentage,
        IIncentiveReceiver _incentiveReceiver,
        IJonesGlpRewardTracker _tracker,
        GlpJonesRewards _jonesRewards,
        IERC20 _asset,
        IERC20Metadata _vaultToken,
        string memory _name,
        string memory _symbol
    ) Governable(msg.sender) ERC20(_name, _symbol) ReentrancyGuard() {
        if (_stableRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }
        if (_glpRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }

        stableRetentionPercentage = _stableRetentionPercentage;
        glpRetentionPercentage = _glpRetentionPercentage;
        incentiveReceiver = _incentiveReceiver;
        jonesRewards = _jonesRewards;

        asset = _asset;
        vaultToken = _vaultToken;

        tracker = _tracker;
    }

    // ============================= Keeper Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function compound() external onlyOperatorOrKeeper {
        _compound();
    }

    // ============================= Operable Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function deposit(uint256 _assets, address _receiver) external nonReentrant onlyOperator returns (uint256) {
        uint256 shares = previewDeposit(_assets);
        _deposit(_receiver, _assets, shares);

        return shares;
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function redeem(uint256 _shares, address _receiver) external nonReentrant onlyOperator returns (uint256) {
        uint256 assets = previewRedeem(_shares);
        _withdraw(_receiver, assets, _shares);

        return assets;
    }

    // ============================= Public Functions ================================ //

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @inheritdoc IJonesGlpCompoundRewards
     */
    function totalAssetsToDeposits(address recipient, uint256 assets) public view returns (uint256) {
        uint256 totalRecipientAssets = _convertToAssets(balanceOf(recipient), Math.Rounding.Down);
        return assets.mulDiv(receiptBalance[recipient], totalRecipientAssets, Math.Rounding.Down);
    }

    // ============================= Governor Functions ================================ //

    /**
     * @notice Transfer all Glp managed by this contract to an address
     * @param _to Address to transfer funds
     */
    function emergencyGlpWithdraw(address _to) external onlyGovernor {
        _compound();
        router.redeemGlp(tracker.stakedAmount(address(this)), false);
        asset.transfer(_to, asset.balanceOf(address(this)));
    }

    /**
     * @notice Transfer all Stable assets managed by this contract to an address
     * @param _to Address to transfer funds
     */
    function emergencyStableWithdraw(address _to) external onlyGovernor {
        _compound();
        router.stableWithdrawalSignal(tracker.stakedAmount(address(this)), false);
        asset.transfer(_to, asset.balanceOf(address(this)));
    }

    /**
     * @notice Set new router contract
     * @param _router New router contract
     */
    function setRouter(JonesGlpVaultRouter _router) external onlyGovernor {
        router = _router;
    }

    /**
     * @notice Set new retention received
     * @param _incentiveReceiver New retention received
     */
    function setIncentiveReceiver(IIncentiveReceiver _incentiveReceiver) external onlyGovernor {
        incentiveReceiver = _incentiveReceiver;
    }

    /**
     * @notice Set new reward tracker contract
     * @param _tracker New reward tracker contract
     */
    function setRewardTracker(IJonesGlpRewardTracker _tracker) external onlyGovernor {
        tracker = _tracker;
    }

    /**
     * @notice Set new asset
     * @param _asset New asset
     */
    function setAsset(IERC20Metadata _asset) external onlyGovernor {
        asset = _asset;
    }

    /**
     * @notice Set new vault token
     * @param _vaultToken New vault token contract
     */
    function setVaultToken(IERC20Metadata _vaultToken) external onlyGovernor {
        vaultToken = _vaultToken;
    }

    /**
     * @notice Set new gmx router contract
     * @param _gmxRouter New gmx router contract
     */
    function setGmxRouter(IGmxRewardRouter _gmxRouter) external onlyGovernor {
        gmxRouter = _gmxRouter;
    }

    /**
     * @notice Set new retentions
     * @param _stableRetentionPercentage New stable retention
     * @param _glpRetentionPercentage New glp retention
     */
    function setNewRetentions(uint256 _stableRetentionPercentage, uint256 _glpRetentionPercentage)
        external
        onlyGovernor
    {
        if (_stableRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }
        if (_glpRetentionPercentage > BASIS_POINTS) {
            revert RetentionPercentageOutOfRange();
        }

        stableRetentionPercentage = _stableRetentionPercentage;
        glpRetentionPercentage = _glpRetentionPercentage;
    }

    /**
     * @notice Set Jones Rewards Contract
     * @param _jonesRewards Contract that manage Jones Rewards
     */
    function setJonesRewards(GlpJonesRewards _jonesRewards) external onlyGovernor {
        jonesRewards = _jonesRewards;
    }

    // ============================= Private Functions ================================ //

    function _deposit(address receiver, uint256 assets, uint256 shares) private {
        vaultToken.transferFrom(msg.sender, address(this), assets);

        receiptBalance[receiver] = receiptBalance[receiver] + assets;

        vaultToken.approve(address(tracker), assets);
        tracker.stake(address(this), assets);

        totalAssetsDeposits = totalAssetsDeposits + assets;
        totalAssets = tracker.stakedAmount(address(this));

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function _withdraw(address receiver, uint256 assets, uint256 shares) private {
        uint256 depositAssets = totalAssetsToDeposits(receiver, assets);

        _burn(receiver, shares);

        receiptBalance[receiver] = receiptBalance[receiver] - depositAssets;

        totalAssetsDeposits = totalAssetsDeposits - depositAssets;

        tracker.withdraw(address(this), assets);

        vaultToken.approve(address(tracker), assets);
        tracker.stake(receiver, assets);

        totalAssets = tracker.stakedAmount(address(this));

        emit Withdraw(msg.sender, receiver, assets, shares);
    }

    function _compound() private {
        (uint256 stableRewards, uint256 glpRewards,) = router.claimRewards();
        if (glpRewards > 0) {
            uint256 retention = _retention(glpRewards, glpRetentionPercentage);
            if (retention > 0) {
                IERC20(weth).approve(address(incentiveReceiver), retention);
                incentiveReceiver.deposit(weth, retention);
                glpRewards = glpRewards - retention;
            }

            IERC20(weth).approve(gmxRouter.glpManager(), glpRewards);
            uint256 glpAmount = gmxRouter.mintAndStakeGlp(weth, glpRewards, 0, 0);
            glpRewards = glpAmount;

            IERC20(glp).approve(address(router), glpRewards);
            router.depositGlp(glpRewards, address(this), false);
            totalAssets = tracker.stakedAmount(address(this));

            // Information needed to calculate compounding rewards per Vault
            emit Compound(glpRewards, totalAssets, retention);
        }
        if (stableRewards > 0) {
            uint256 retention = _retention(stableRewards, stableRetentionPercentage);
            if (retention > 0) {
                IERC20(usdc).approve(address(incentiveReceiver), retention);
                incentiveReceiver.deposit(usdc, retention);
                stableRewards = stableRewards - retention;
            }

            IERC20(usdc).approve(address(router), stableRewards);
            router.depositStable(stableRewards, false, address(this));
            totalAssets = tracker.stakedAmount(address(this));

            // Information needed to calculate compounding rewards per Vault
            emit Compound(stableRewards, totalAssets, retention);
        }
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) private view returns (uint256 shares) {
        uint256 supply = totalSupply();

        return (assets == 0 || supply == 0)
            ? assets.mulDiv(10 ** decimals(), 10 ** vaultToken.decimals(), rounding)
            : assets.mulDiv(supply, totalAssets, rounding);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) private view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? shares.mulDiv(10 ** vaultToken.decimals(), 10 ** decimals(), rounding)
            : shares.mulDiv(totalAssets, supply, rounding);
    }

    function _retention(uint256 _rewards, uint256 _retentionPercentage) private pure returns (uint256) {
        return (_rewards * _retentionPercentage) / BASIS_POINTS;
    }

    function internalTransfer(address from, address to, uint256 amount) private {
        uint256 assets = previewRedeem(amount);
        uint256 depositAssets = totalAssetsToDeposits(from, assets);
        receiptBalance[from] = receiptBalance[from] - depositAssets;
        receiptBalance[to] = receiptBalance[to] + depositAssets;
        if (address(asset) == usdc) {
            jonesRewards.getReward(from);
            jonesRewards.withdraw(from, depositAssets);
            jonesRewards.stake(to, depositAssets);
        }
    }

    /// ============================= ERC20 Functions ================================ //

    function name() public view override returns (string memory) {
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        return super.symbol();
    }

    function decimals() public view override returns (uint8) {
        return super.decimals();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        internalTransfer(msg.sender, to, amount);
        return super.transfer(to, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        internalTransfer(from, to, amount);
        return super.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable, OperableKeepable} from "../../common/OperableKeepable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IJonesGlpRewardDistributor} from "../../interfaces/IJonesGlpRewardDistributor.sol";
import {IJonesGlpRewardTracker} from "../../interfaces/IJonesGlpRewardTracker.sol";
import {IJonesGlpRewardsSwapper} from "../../interfaces/IJonesGlpRewardsSwapper.sol";
import {IIncentiveReceiver} from "../../interfaces/IIncentiveReceiver.sol";

contract JonesGlpRewardTracker is IJonesGlpRewardTracker, OperableKeepable, ReentrancyGuard {
    uint256 public constant PRECISION = 1e30;

    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address public immutable sharesToken;
    address public immutable rewardToken;

    IJonesGlpRewardDistributor public distributor;
    IJonesGlpRewardsSwapper public swapper;
    IIncentiveReceiver public incentiveReceiver;

    uint256 public wethRewards;
    uint256 public cumulativeRewardPerShare;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public previousCumulatedRewardPerShare;
    mapping(address => uint256) public cumulativeRewards;

    uint256 public totalStakedAmount;
    mapping(address => uint256) public stakedAmounts;

    constructor(address _sharesToken, address _rewardToken, address _distributor, address _incentiveReceiver)
        Governable(msg.sender)
        ReentrancyGuard()
    {
        if (_sharesToken == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_rewardToken == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_distributor == address(0)) {
            revert AddressCannotBeZeroAddress();
        }
        if (_incentiveReceiver == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        sharesToken = _sharesToken;
        rewardToken = _rewardToken;
        distributor = IJonesGlpRewardDistributor(_distributor);
        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
    }

    // ============================= Operator functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function stake(address _account, uint256 _amount) external onlyOperator returns (uint256) {
        if (_amount == 0) {
            revert AmountCannotBeZero();
        }
        _stake(_account, _amount);
        return _amount;
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function withdraw(address _account, uint256 _amount) external onlyOperator returns (uint256) {
        if (_amount == 0) {
            revert AmountCannotBeZero();
        }

        _withdraw(_account, _amount);
        return _amount;
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function claim(address _account) external onlyOperator returns (uint256) {
        return _claim(_account);
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function updateRewards() external nonReentrant onlyOperatorOrKeeper {
        _updateRewards(address(0));
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function depositRewards(uint256 _rewards) external onlyOperator {
        if (_rewards == 0) {
            revert AmountCannotBeZero();
        }
        uint256 totalShares = totalStakedAmount;
        IERC20(rewardToken).transferFrom(msg.sender, address(this), _rewards);

        if (totalShares != 0) {
            cumulativeRewardPerShare = cumulativeRewardPerShare + ((_rewards * PRECISION) / totalShares);
            emit UpdateRewards(msg.sender, _rewards, totalShares, cumulativeRewardPerShare);
        } else {
            IERC20(rewardToken).approve(address(incentiveReceiver), _rewards);
            incentiveReceiver.deposit(rewardToken, _rewards);
        }
    }

    // ============================= External functions ================================ //

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function claimable(address _account) external view returns (uint256) {
        uint256 shares = stakedAmounts[_account];
        if (shares == 0) {
            return claimableReward[_account];
        }
        uint256 totalShares = totalStakedAmount;
        uint256 pendingRewards = distributor.pendingRewards(address(this)) * PRECISION;
        uint256 nextCumulativeRewardPerShare = cumulativeRewardPerShare + (pendingRewards / totalShares);
        return claimableReward[_account]
            + ((shares * (nextCumulativeRewardPerShare - previousCumulatedRewardPerShare[_account])) / PRECISION);
    }

    /**
     * @inheritdoc IJonesGlpRewardTracker
     */
    function stakedAmount(address _account) external view returns (uint256) {
        return stakedAmounts[_account];
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set a new distributor contract
     * @param _distributor New distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        if (_distributor == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        distributor = IJonesGlpRewardDistributor(_distributor);
    }

    /**
     * @notice Set a new swapper contract
     * @param _swapper New swapper address
     */
    function setSwapper(address _swapper) external onlyGovernor {
        if (_swapper == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        swapper = IJonesGlpRewardsSwapper(_swapper);
    }

    /**
     * @notice Set a new incentive receiver contract
     * @param _incentiveReceiver New incentive receiver address
     */
    function setIncentiveReceiver(address _incentiveReceiver) external onlyGovernor {
        if (_incentiveReceiver == address(0)) {
            revert AddressCannotBeZeroAddress();
        }

        incentiveReceiver = IIncentiveReceiver(_incentiveReceiver);
    }

    // ============================= Private functions ================================ //

    function _stake(address _account, uint256 _amount) private nonReentrant {
        IERC20(sharesToken).transferFrom(msg.sender, address(this), _amount);

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account] + _amount;
        totalStakedAmount = totalStakedAmount + _amount;
        emit Stake(_account, _amount);
    }

    function _withdraw(address _account, uint256 _amount) private nonReentrant {
        _updateRewards(_account);

        uint256 amountStaked = stakedAmounts[_account];
        if (_amount > amountStaked) {
            revert AmountExceedsStakedAmount(); // Error camel case
        }

        stakedAmounts[_account] = amountStaked - _amount;

        totalStakedAmount = totalStakedAmount - _amount;

        IERC20(sharesToken).transfer(msg.sender, _amount);
        emit Withdraw(_account, _amount);
    }

    function _claim(address _account) private nonReentrant returns (uint256) {
        _updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken).transfer(msg.sender, tokenAmount);
            emit Claim(_account, tokenAmount);
        }

        return tokenAmount;
    }

    function _updateRewards(address _account) private {
        uint256 rewards = distributor.distributeRewards(); // get new rewards for the distributor

        if (IERC4626(sharesToken).asset() == usdc && rewards > 0) {
            wethRewards = wethRewards + rewards;
            if (swapper.minAmountOut(wethRewards) > 0) {
                // enough weth to swap
                IERC20(weth).approve(address(swapper), wethRewards);
                rewards = swapper.swapRewards(wethRewards);
                wethRewards = 0;
            }
        }

        uint256 totalShares = totalStakedAmount;

        uint256 _cumulativeRewardPerShare = cumulativeRewardPerShare;
        if (totalShares > 0 && rewards > 0 && wethRewards == 0) {
            _cumulativeRewardPerShare = _cumulativeRewardPerShare + ((rewards * PRECISION) / totalShares);
            cumulativeRewardPerShare = _cumulativeRewardPerShare; // add new rewards to cumulative rewards
            // Information needed to calculate rewards
            emit UpdateRewards(_account, rewards, totalShares, cumulativeRewardPerShare);
        }

        // cumulativeRewardPerShare can only increase
        // so if cumulativeRewardPerShare is zero, it means there are no rewards yet
        if (_cumulativeRewardPerShare == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 shares = stakedAmounts[_account];

            uint256 accountReward =
                (shares * (_cumulativeRewardPerShare - previousCumulatedRewardPerShare[_account])) / PRECISION;
            uint256 _claimableReward = claimableReward[_account] + accountReward;
            claimableReward[_account] = _claimableReward; // add new user rewards to cumulative user rewards
            previousCumulatedRewardPerShare[_account] = _cumulativeRewardPerShare; // Important to not have more rewards than expected

            if (_claimableReward > 0 && shares > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account] + accountReward;
                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable, OperableKeepable} from "src/common/OperableKeepable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IJonesBorrowableVault} from "src/interfaces/IJonesBorrowableVault.sol";
import {IJonesUsdVault} from "src/interfaces/IJonesUsdVault.sol";
import {IJonesGlpRewardDistributor} from "src/interfaces/IJonesGlpRewardDistributor.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IGmxRewardRouter} from "src/interfaces/IGmxRewardRouter.sol";
import {IJonesGlpLeverageStrategy} from "src/interfaces/IJonesGlpLeverageStrategy.sol";
import {IGlpManager} from "src/interfaces/IGlpManager.sol";
import {IGMXVault} from "src/interfaces/IGMXVault.sol";
import {IRewardTracker} from "src/interfaces/IRewardTracker.sol";

contract JonesGlpLeverageStrategy is IJonesGlpLeverageStrategy, OperableKeepable, ReentrancyGuard {
    using Math for uint256;

    struct LeverageConfig {
        uint256 target;
        uint256 min;
        uint256 max;
    }

    IGmxRewardRouter constant routerV1 = IGmxRewardRouter(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
    IGmxRewardRouter constant routerV2 = IGmxRewardRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    IGlpManager constant glpManager = IGlpManager(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    address constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    uint256 public constant PRECISION = 1e30;
    uint256 public constant BASIS_POINTS = 1e12;
    uint256 public constant GMX_BASIS = 1e4;
    uint256 public constant USDC_DECIMALS = 1e6;
    uint256 public constant GLP_DECIMALS = 1e18;

    IERC20 public stable;
    IERC20 public glp;

    IJonesBorrowableVault stableVault;
    IJonesBorrowableVault glpVault;

    IJonesGlpRewardDistributor distributor;

    uint256 public stableDebt;

    LeverageConfig public leverageConfig;

    constructor(
        IJonesBorrowableVault _stableVault,
        IJonesBorrowableVault _glpVault,
        IJonesGlpRewardDistributor _distributor,
        LeverageConfig memory _leverageConfig,
        address _glp,
        address _stable,
        uint256 _stableDebt
    ) Governable(msg.sender) ReentrancyGuard() {
        stableVault = _stableVault;
        glpVault = _glpVault;
        distributor = _distributor;

        stable = IERC20(_stable);
        glp = IERC20(_glp);

        stableDebt = _stableDebt;

        _setLeverageConfig(_leverageConfig);
    }

    // ============================= Operator functions ================================ //

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpDeposit(uint256 _amount) external nonReentrant onlyOperator {
        _borrowGlp(_amount);
        if (leverage() < getTargetLeverage()) {
            _leverage(_amount);
        }
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onGlpRedeem(uint256 _amount) external nonReentrant onlyOperator returns (uint256) {
        if (_amount > getUnderlyingGlp()) {
            revert NotEnoughUnderlyingGlp();
        }

        uint256 glpRedeemRetention = glpRedeemRetention(_amount);
        uint256 assetsToRedeem = _amount - glpRedeemRetention;

        glp.transfer(msg.sender, assetsToRedeem);

        uint256 underlying = getUnderlyingGlp();
        uint256 leverageAmount = glp.balanceOf(address(this)) - underlying;
        uint256 protocolExcess = ((underlying * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS);
        uint256 excessGlp;
        if (leverageAmount < protocolExcess) {
            excessGlp = leverageAmount;
        } else {
            excessGlp = ((_amount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals
        }

        if (leverageAmount >= excessGlp && leverage() > getTargetLeverage()) {
            _deleverage(excessGlp);
        }

        underlying = getUnderlyingGlp();
        if (underlying > 0) {
            _rebalance(underlying);
        }

        emit Deleverage(excessGlp, assetsToRedeem);

        return assetsToRedeem;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onStableDeposit() external nonReentrant onlyOperator {
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function onStableRedeem(uint256 _amount, uint256 _amountAfterRetention) external onlyOperator returns (uint256) {
        uint256 strategyStables = stable.balanceOf(address(stableVault));
        uint256 expectedStables = _amountAfterRetention > strategyStables ? _amountAfterRetention - strategyStables : 0;

        if (expectedStables > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(expectedStables + 2);
            uint256 stableAmount =
                routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, expectedStables, address(this));
            if (stableAmount + strategyStables < _amountAfterRetention) {
                revert NotEnoughStables();
            }
        }

        stable.transfer(msg.sender, _amountAfterRetention);

        stableDebt = stableDebt - _amount;

        return _amountAfterRetention;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function claimGlpRewards() external nonReentrant onlyOperatorOrKeeper {
        routerV1.handleRewards(false, false, true, true, true, true, false);

        uint256 rewards = IERC20(weth).balanceOf(address(this));

        uint256 currentLeverage = leverage();

        IERC20(weth).approve(address(distributor), rewards);
        distributor.splitRewards(rewards, currentLeverage, utilization());

        // Information needed to calculate rewards per Vault
        emit ClaimGlpRewards(
            tx.origin,
            msg.sender,
            rewards,
            block.timestamp,
            currentLeverage,
            glp.balanceOf(address(this)),
            getUnderlyingGlp(),
            glpVault.totalSupply(),
            stableDebt,
            stableVault.totalSupply()
            );
    }

    // ============================= Public functions ================================ //

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function utilization() public view returns (uint256) {
        uint256 borrowed = stableDebt;
        uint256 available = stable.balanceOf(address(stableVault));
        uint256 total = borrowed + available;

        if (total == 0) {
            return 0;
        }

        return (borrowed * BASIS_POINTS) / total;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function leverage() public view returns (uint256) {
        uint256 glpTvl = getUnderlyingGlp(); // 18 Decimals

        if (glpTvl == 0) {
            return 0;
        }

        if (stableDebt == 0) {
            return 1 * BASIS_POINTS;
        }

        return ((glp.balanceOf(address(this)) * BASIS_POINTS) / glpTvl); // 12 Decimals;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getUnderlyingGlp() public view returns (uint256) {
        uint256 currentBalance = glp.balanceOf(address(this));

        if (currentBalance == 0) {
            return 0;
        }

        if (stableDebt > 0) {
            (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);
            return currentBalance > glpAmount ? currentBalance - glpAmount : 0;
        } else {
            return currentBalance;
        }
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getStableGlpValue(uint256 _glpAmount) public view returns (uint256) {
        (uint256 _value,) = _sellGlpStableSimulation(_glpAmount);
        return _value;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function buyGlpStableSimulation(uint256 _stableAmount) public view returns (uint256) {
        return _buyGlpStableSimulation(_stableAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredStableAmount(uint256 _glpAmount) external view returns (uint256) {
        (uint256 stableAmount,) = _getRequiredStableAmount(_glpAmount);
        return stableAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRequiredGlpAmount(uint256 _stableAmount) external view returns (uint256) {
        (uint256 glpAmount,) = _getRequiredGlpAmount(_stableAmount);
        return glpAmount;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getRedeemStableGMXIncentive(uint256 _stableAmount) external view returns (uint256) {
        (, uint256 gmxRetention) = _getRequiredGlpAmount(_stableAmount);
        return gmxRetention;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpMintIncentive(uint256 _glpAmount) public view returns (uint256) {
        return _glpMintIncentive(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function glpRedeemRetention(uint256 _glpAmount) public view returns (uint256) {
        return _glpRedeemRetention(_glpAmount);
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMaxLeverage() public view returns (uint256) {
        return leverageConfig.max;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getMinLeverage() public view returns (uint256) {
        return leverageConfig.min;
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getGMXCapDifference() public view returns (uint256) {
        return _getGMXCapDifference();
    }

    /**
     * @inheritdoc IJonesGlpLeverageStrategy
     */
    function getTargetLeverage() public view returns (uint256) {
        return leverageConfig.target;
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Set Leverage Configuration
     * @dev Precision is based on 1e12 as 1x leverage
     * @param _target Target leverage
     * @param _min Min Leverage
     * @param _max Max Leverage
     * @param rebalance_ If is true trigger a rebalance
     */
    function setLeverageConfig(uint256 _target, uint256 _min, uint256 _max, bool rebalance_) public onlyGovernor {
        _setLeverageConfig(LeverageConfig(_target, _min, _max));
        emit SetLeverageConfig(_target, _min, _max);
        if (rebalance_) {
            _rebalance(getUnderlyingGlp());
        }
    }

    /**
     * @notice Set new glp address
     * @param _glp GLP address
     */
    function setGlpAddress(address _glp) external onlyGovernor {
        address oldGlp = address(glp);
        glp = IERC20(_glp);
        emit UpdateGlpAddress(oldGlp, _glp);
    }

    /**
     * @notice Set new stable address
     * @param _stable Stable addresss
     */
    function setStableAddress(address _stable) external onlyGovernor {
        address oldStable = address(stable);
        stable = IERC20(_stable);
        emit UpdateStableAddress(oldStable, _stable);
    }

    /**
     * @notice Emergency withdraw GLP in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        uint256 currentBalance = glp.balanceOf(address(this));

        if (currentBalance == 0) {
            return;
        }

        glp.transfer(_to, currentBalance);

        emit EmergencyWithdraw(_to, currentBalance);
    }

    /**
     * @notice GMX function to signal transfer position
     * @param _to address to send the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function transferAccount(address _to, address _gmxRouter) external onlyGovernor {
        if (_to == address(0)) {
            revert ZeroAddressError();
        }

        IGmxRewardRouter(_gmxRouter).signalTransfer(_to);
    }

    /**
     * @notice GMX function to accept transfer position
     * @param _sender address to receive the funds
     * @param _gmxRouter address of gmx router with the function
     */
    function acceptAccountTransfer(address _sender, address _gmxRouter) external onlyGovernor {
        IGmxRewardRouter gmxRouter = IGmxRewardRouter(_gmxRouter);

        gmxRouter.acceptTransfer(_sender);
    }

    // ============================= Keeper functions ================================ //

    /**
     * @notice Using by the bot to rebalance if is it needed
     */
    function rebalance() external onlyKeeper {
        _rebalance(getUnderlyingGlp());
    }

    /**
     * @notice Deleverage & pay stable debt
     */
    function unwind() external onlyGovernorOrKeeper {
        _setLeverageConfig(LeverageConfig(BASIS_POINTS + 1, BASIS_POINTS, BASIS_POINTS + 2));
        _liquidate();
    }

    /**
     * @notice Using by the bot to leverage Up if is needed
     */
    function leverageUp(uint256 _stableAmount) external onlyKeeper {
        uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

        if (availableForBorrowing == 0) {
            return;
        }

        uint256 oldLeverage = leverage();

        _stableAmount = _adjustToGMXCap(_stableAmount);

        if (_stableAmount < 1e4) {
            return;
        }

        if (availableForBorrowing < _stableAmount) {
            _stableAmount = availableForBorrowing;
        }

        uint256 stableToBorrow = _stableAmount - stable.balanceOf(address(this));

        stableVault.borrow(stableToBorrow);
        emit BorrowStable(stableToBorrow);

        stableDebt = stableDebt + stableToBorrow;

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), _stableAmount);
        routerV2.mintAndStakeGlp(stableAsset, _stableAmount, 0, 0);

        uint256 newLeverage = leverage();

        if (newLeverage > getMaxLeverage()) {
            revert OverLeveraged();
        }

        emit LeverageUp(stableDebt, oldLeverage, newLeverage);
    }

    /**
     * @notice Using by the bot to leverage Down if is needed
     */
    function leverageDown(uint256 _glpAmount) external onlyKeeper {
        uint256 oldLeverage = leverage();

        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), _glpAmount, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        uint256 newLeverage = leverage();

        if (newLeverage < getMinLeverage()) {
            revert UnderLeveraged();
        }

        emit LeverageDown(stableDebt, oldLeverage, newLeverage);
    }

    // ============================= Private functions ================================ //

    function _rebalance(uint256 _glpDebt) private {
        uint256 currentLeverage = leverage();

        LeverageConfig memory currentLeverageConfig = leverageConfig;

        if (currentLeverage < currentLeverageConfig.min) {
            uint256 missingGlp = (_glpDebt * (currentLeverageConfig.target - currentLeverage)) / BASIS_POINTS; // 18 Decimals

            (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

            stableToDeposit = _adjustToGMXCap(stableToDeposit);

            if (stableToDeposit < 1e4) {
                return;
            }

            uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

            if (availableForBorrowing == 0) {
                return;
            }

            if (availableForBorrowing < stableToDeposit) {
                stableToDeposit = availableForBorrowing;
            }

            uint256 stableToBorrow = stableToDeposit - stable.balanceOf(address(this));

            stableVault.borrow(stableToBorrow);
            emit BorrowStable(stableToBorrow);

            stableDebt = stableDebt + stableToBorrow;

            address stableAsset = address(stable);
            IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);
            routerV2.mintAndStakeGlp(stableAsset, stableToDeposit, 0, 0);

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        if (currentLeverage > currentLeverageConfig.max) {
            uint256 excessGlp = (_glpDebt * (currentLeverage - currentLeverageConfig.target)) / BASIS_POINTS;

            uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), excessGlp, 0, address(this));

            uint256 currentStableDebt = stableDebt;

            if (stablesReceived <= currentStableDebt) {
                _repayStable(stablesReceived);
            } else {
                _repayStable(currentStableDebt);
            }

            emit Rebalance(_glpDebt, currentLeverage, leverage(), tx.origin);

            return;
        }

        return;
    }

    function _liquidate() private {
        if (stableDebt == 0) {
            return;
        }

        uint256 glpBalance = glp.balanceOf(address(this));

        (uint256 glpAmount,) = _getRequiredGlpAmount(stableDebt + 2);

        if (glpAmount > glpBalance) {
            glpAmount = glpBalance;
        }

        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        emit Liquidate(stablesReceived);
    }

    function _borrowGlp(uint256 _amount) private returns (uint256) {
        glpVault.borrow(_amount);

        emit BorrowGlp(_amount);

        return _amount;
    }

    function _repayStable(uint256 _amount) internal returns (uint256) {
        stable.approve(address(stableVault), _amount);

        uint256 updatedAmount = stableDebt - stableVault.repay(_amount);

        stableDebt = updatedAmount;

        return updatedAmount;
    }

    function _setLeverageConfig(LeverageConfig memory _config) private {
        if (
            _config.min >= _config.max || _config.min >= _config.target || _config.max <= _config.target
                || _config.min < BASIS_POINTS
        ) {
            revert InvalidLeverageConfig();
        }

        leverageConfig = _config;
    }

    function _getRequiredGlpAmount(uint256 _stableAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of glp nedeed to get a few less stables than expected
        // If you have to get an amount greater or equal of _stableAmount, use _stableAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMaxPrice(usdc); // 30 decimals

        uint256 glpSupply = glp.totalSupply();

        uint256 glpPrice = manager.getAum(false).mulDiv(GLP_DECIMALS, glpSupply, Math.Rounding.Down); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION, Math.Rounding.Down) * BASIS_POINTS; // 18 decimals

        uint256 glpAmount = _stableAmount.mulDiv(usdcPrice, glpPrice, Math.Rounding.Down) * BASIS_POINTS; // 18 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        uint256 glpRequired = (glpAmount * GMX_BASIS) / (GMX_BASIS - retentionBasisPoints);

        return (glpRequired, retentionBasisPoints);
    }

    function _getRequiredStableAmount(uint256 _glpAmount) private view returns (uint256, uint256) {
        // Working as expected, will get the amount of stables nedeed to get a few less glp than expected
        // If you have to get an amount greater or equal of _glpAmount, use _glpAmount + 2
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 glpPrice = manager.getAum(true).mulDiv(GLP_DECIMALS, glp.totalSupply(), Math.Rounding.Down); // 30 decimals

        uint256 stableAmount = _glpAmount.mulDiv(glpPrice, usdcPrice, Math.Rounding.Down); // 18 decimals

        uint256 usdgAmount = _glpAmount.mulDiv(glpPrice, PRECISION, Math.Rounding.Down); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        return ((stableAmount * GMX_BASIS / (GMX_BASIS - retentionBasisPoints)) / BASIS_POINTS, retentionBasisPoints); // 18 decimals
    }

    function _leverage(uint256 _glpAmount) private {
        uint256 missingGlp = ((_glpAmount * (leverageConfig.target - BASIS_POINTS)) / BASIS_POINTS); // 18 Decimals

        (uint256 stableToDeposit,) = _getRequiredStableAmount(missingGlp); // 6 Decimals

        stableToDeposit = _adjustToGMXCap(stableToDeposit);

        if (stableToDeposit < 1e4) {
            return;
        }

        uint256 availableForBorrowing = stable.balanceOf(address(stableVault));

        if (availableForBorrowing == 0) {
            return;
        }

        if (availableForBorrowing < stableToDeposit) {
            stableToDeposit = availableForBorrowing;
        }

        uint256 stableToBorrow = stableToDeposit - stable.balanceOf(address(this));

        stableVault.borrow(stableToBorrow);
        emit BorrowStable(stableToBorrow);

        stableDebt = stableDebt + stableToBorrow;

        address stableAsset = address(stable);
        IERC20(stableAsset).approve(routerV2.glpManager(), stableToDeposit);
        uint256 glpMinted = routerV2.mintAndStakeGlp(stableAsset, stableToDeposit, 0, 0);

        emit Leverage(_glpAmount, glpMinted);
    }

    function _deleverage(uint256 _excessGlp) private returns (uint256) {
        uint256 stablesReceived = routerV2.unstakeAndRedeemGlp(address(stable), _excessGlp, 0, address(this));

        uint256 currentStableDebt = stableDebt;

        if (stablesReceived <= currentStableDebt) {
            _repayStable(stablesReceived);
        } else {
            _repayStable(currentStableDebt);
        }

        return stablesReceived;
    }

    function _adjustToGMXCap(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 mintAmount = _buyGlpStableSimulation(_stableAmount);

        uint256 currentUsdgAmount = vault.usdgAmounts(usdc);

        uint256 nextAmount = currentUsdgAmount + mintAmount;
        uint256 maxUsdgAmount = vault.maxUsdgAmounts(usdc);

        if (nextAmount > maxUsdgAmount) {
            (uint256 requiredStables,) = _getRequiredStableAmount(maxUsdgAmount - currentUsdgAmount);
            return requiredStables;
        } else {
            return _stableAmount;
        }
    }

    function _getGMXCapDifference() private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 currentUsdgAmount = vault.usdgAmounts(usdc);

        uint256 maxUsdgAmount = vault.maxUsdgAmounts(usdc);

        return maxUsdgAmount - currentUsdgAmount;
    }

    function _buyGlpStableSimulation(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 retentionBasisPoints =
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);

        uint256 amountAfterRetention = _stableAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS); // 6 decimals

        uint256 mintAmount = amountAfterRetention.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _buyGlpStableSimulationWhitoutRetention(uint256 _stableAmount) private view returns (uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 aumInUsdg = manager.getAumInUsdg(true);

        uint256 usdcPrice = vault.getMinPrice(usdc); // 30 decimals

        uint256 usdgAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        usdgAmount = usdgAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        uint256 mintAmount = _stableAmount.mulDiv(usdcPrice, PRECISION); // 6 decimals

        mintAmount = mintAmount.mulDiv(GLP_DECIMALS, USDC_DECIMALS); // 18 decimals

        return aumInUsdg == 0 ? mintAmount : mintAmount.mulDiv(glp.totalSupply(), aumInUsdg); // 18 decimals
    }

    function _sellGlpStableSimulation(uint256 _glpAmount) private view returns (uint256, uint256) {
        IGlpManager manager = glpManager;
        IGMXVault vault = IGMXVault(manager.vault());

        address usdc = address(stable);

        uint256 usdgAmount = _glpAmount.mulDiv(manager.getAumInUsdg(false), glp.totalSupply());

        uint256 redemptionAmount = usdgAmount.mulDiv(PRECISION, vault.getMaxPrice(usdc));

        redemptionAmount = redemptionAmount.mulDiv(USDC_DECIMALS, GLP_DECIMALS); // 6 decimals

        uint256 retentionBasisPoints =
            _getGMXBasisRetention(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        return (redemptionAmount.mulDiv(GMX_BASIS - retentionBasisPoints, GMX_BASIS), retentionBasisPoints);
    }

    function _glpMintIncentive(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToMint = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); // 18 Decimals
        (uint256 stablesNeeded, uint256 gmxIncentive) = _getRequiredStableAmount(amountToMint + 2);
        uint256 incentiveInStables = stablesNeeded.mulDiv(gmxIncentive, GMX_BASIS);
        return _buyGlpStableSimulationWhitoutRetention(incentiveInStables); // retention in glp
    }

    function _glpRedeemRetention(uint256 _glpAmount) private view returns (uint256) {
        uint256 amountToRedeem = _glpAmount.mulDiv(leverageConfig.target - BASIS_POINTS, BASIS_POINTS); //18
        (, uint256 gmxRetention) = _sellGlpStableSimulation(amountToRedeem + 2);
        uint256 retentionInGlp = amountToRedeem.mulDiv(gmxRetention, GMX_BASIS);
        return retentionInGlp;
    }

    function _getGMXBasisRetention(
        address _token,
        uint256 _usdgDelta,
        uint256 _retentionBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        IGMXVault vault = IGMXVault(glpManager.vault());

        if (!vault.hasDynamicFees()) return _retentionBasisPoints;

        uint256 initialAmount = _increment ? vault.usdgAmounts(_token) : vault.usdgAmounts(_token) - _usdgDelta;

        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) return _retentionBasisPoints;

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mulDiv(initialDiff, targetAmount);
            return rebateBps > _retentionBasisPoints ? 0 : _retentionBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mulDiv(averageDiff, targetAmount);
        return _retentionBasisPoints + taxBps;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {JonesUsdVault} from "../../vaults/JonesUsdVault.sol";
import {JonesBorrowableVault} from "../../vaults/JonesBorrowableVault.sol";
import {JonesOperableVault} from "../../vaults/JonesOperableVault.sol";
import {JonesGovernableVault} from "../../vaults/JonesGovernableVault.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IStakedGlp} from "../../interfaces/IStakedGlp.sol";
import {IJonesGlpLeverageStrategy} from "../../interfaces/IJonesGlpLeverageStrategy.sol";

abstract contract JonesBaseGlpVault is JonesOperableVault, JonesUsdVault, JonesBorrowableVault {
    IJonesGlpLeverageStrategy public strategy;
    address internal receiver;

    constructor(IAggregatorV3 _oracle, IERC20Metadata _asset, string memory _name, string memory _symbol)
        JonesGovernableVault(msg.sender)
        JonesUsdVault(_oracle)
        ERC4626(_asset)
        ERC20(_name, _symbol)
    {}

    // ============================= Operable functions ================================ //

    /**
     * @dev See {openzeppelin-IERC4626-deposit}.
     */
    function deposit(uint256 _assets, address _receiver)
        public
        virtual
        override(JonesOperableVault, ERC4626)
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-mint}.
     */
    function mint(uint256 _shares, address _receiver)
        public
        override(JonesOperableVault, ERC4626)
        whenNotPaused
        returns (uint256)
    {
        return super.mint(_shares, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-withdraw}.
     */
    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        virtual
        override(JonesOperableVault, ERC4626)
        returns (uint256)
    {
        return super.withdraw(_assets, _receiver, _owner);
    }

    /**
     * @dev See {openzeppelin-IERC4626-redeem}.
     */
    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        virtual
        override(JonesOperableVault, ERC4626)
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }

    /**
     * @notice Set new strategy address
     * @param _strategy Strategy Contract
     */
    function setStrategyAddress(IJonesGlpLeverageStrategy _strategy) external onlyGovernor {
        strategy = _strategy;
    }

    function setExcessReceiver(address _receiver) external onlyGovernor {
        receiver = _receiver;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesBaseGlpVault} from "./JonesBaseGlpVault.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract JonesGlpStableVault is JonesBaseGlpVault {
    uint256 public constant BASIS_POINTS = 1e12;

    constructor()
        JonesBaseGlpVault(
            IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3),
            IERC20Metadata(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8),
            "USDC Vault Receipt Token",
            "UVRT"
        )
    {}

    // ============================= Public functions ================================ //

    function deposit(uint256 _assets, address _receiver)
        public
        override(JonesBaseGlpVault)
        whenNotPaused
        returns (uint256)
    {
        _validate();
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-_burn}.
     */
    function burn(address _user, uint256 _amount) public onlyOperator {
        _validate();
        _burn(_user, _amount);
    }

    /**
     * @notice Return total asset deposited
     * @return Amount of asset deposited
     */
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets() + strategy.stableDebt();
    }

    // ============================= Governor functions ================================ //

    /**
     * @notice Emergency withdraw USDC in this contract
     * @param _to address to send the funds
     */
    function emergencyWithdraw(address _to) external onlyGovernor {
        IERC20 underlyingAsset = IERC20(super.asset());

        uint256 balance = underlyingAsset.balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        underlyingAsset.transfer(_to, balance);
    }

    // ============================= Private functions ================================ //

    function _validate() private {
        uint256 shares = totalSupply() / BASIS_POINTS;
        uint256 assets = totalAssets();
        address stable = asset();

        if (assets > shares) {
            uint256 ratioExcess = assets - shares;
            IERC20(stable).transfer(receiver, ratioExcess);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesBaseGlpVault} from "./JonesBaseGlpVault.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IStakedGlp} from "../../interfaces/IStakedGlp.sol";
import {IJonesGlpLeverageStrategy} from "../../interfaces/IJonesGlpLeverageStrategy.sol";

contract JonesGlpVault is JonesBaseGlpVault {
    uint256 private freezedAssets;

    constructor()
        JonesBaseGlpVault(
            IAggregatorV3(0xDFE51CC551949704E5C52C7BB98DCC3fd934E7fa),
            IERC20Metadata(0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf),
            "GLP Vault Receipt Token",
            "GVRT"
        )
    {}
    // ============================= Public functions ================================ //

    function deposit(uint256 _assets, address _receiver)
        public
        override(JonesBaseGlpVault)
        whenNotPaused
        returns (uint256)
    {
        _validate();
        return super.deposit(_assets, _receiver);
    }

    /**
     * @dev See {openzeppelin-IERC4626-_burn}.
     */
    function burn(address _user, uint256 _amount) public onlyOperator {
        _validate();
        _burn(_user, _amount);
    }

    /**
     * @notice Return total asset deposited
     * @return Amount of asset deposited
     */
    function totalAssets() public view override returns (uint256) {
        if (freezedAssets != 0) {
            return freezedAssets;
        }

        return super.totalAssets() + strategy.getUnderlyingGlp();
    }

    // ============================= Private functions ================================ //

    function _validate() private {
        IERC20 asset = IERC20(asset());
        uint256 balance = asset.balanceOf(address(this));

        if (balance > 0) {
            asset.transfer(receiver, balance);
        }
    }
}

//SPDX-License-Identifier:  MIT
pragma solidity ^0.8.10;

interface Errors {
    error AlreadyInitialized();
    error CallerIsNotInternalContract();
    error CallerIsNotWhitelisted();
    error InvalidWithdrawalRetention();
    error MaxGlpTvlReached();
    error CannotSettleEpochInFuture();
    error EpochAlreadySettled();
    error EpochNotSettled();
    error WithdrawalAlreadyCompleted();
    error WithdrawalWithNoShares();
    error WithdrawalSignalAlreadyDone();
    error NotRightEpoch();
    error NotEnoughStables();
    error NoEpochToSettle();
    error CannotCancelWithdrawal();
    error AddressCannotBeZeroAddress();
    error OnlyAdapter();
    error OnlyAuthorized();
    error DoesntHavePermission();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IGMXVault {
    function whitelistedTokens(address) external view returns (bool);

    function stableTokens(address) external view returns (bool);

    function shortableTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function getTargetUsdgAmount(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IGMXVault} from "./IGMXVault.sol";

interface IGlpManager {
    function getAum(bool _maximize) external view returns (uint256);
    function getAumInUsdg(bool _maximize) external view returns (uint256);
    function vault() external view returns (address);
    function glp() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGmxRewardRouter {
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);

    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);

    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver)
        external
        returns (uint256);

    function glpManager() external view returns (address);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
    function pendingReceivers(address input) external returns (address);
    function stakeEsGmx(uint256 _amount) external;
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IIncentiveReceiver {
    function deposit(address _token, uint256 _amount) external;

    function addDepositor(address _depositor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface IJonesBorrowableVault is IERC4626 {
    function borrow(uint256 _amount) external returns (uint256);
    function repay(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpCompoundRewards {
    event Deposit(address indexed _caller, address indexed receiver, uint256 _assets, uint256 _shares);
    event Withdraw(address indexed _caller, address indexed receiver, uint256 _assets, uint256 _shares);
    event Compound(uint256 _rewards, uint256 _totalAssets, uint256 _retentions);

    /**
     * @notice Deposit assets into this contract and get shares
     * @param assets Amount of assets to be deposit
     * @param receiver Address Owner of the deposit
     * @return Amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /**
     * @notice Withdraw the deposited assets
     * @param shares Amount to shares to be burned to get the assets
     * @param receiver Address who will receive the assets
     * @return Amount of assets redemeed
     */
    function redeem(uint256 shares, address receiver) external returns (uint256);

    /**
     * @notice Claim cumulative rewards & stake them
     */
    function compound() external;

    /**
     * @notice Preview how many shares will obtain when deposit
     * @param assets Amount to shares to be deposit
     * @return Amount of shares to be minted
     */
    function previewDeposit(uint256 assets) external view returns (uint256);

    /**
     * @notice Preview how many assets will obtain when redeem
     * @param shares Amount to shares to be redeem
     * @return Amount of assets to be redeemed
     */
    function previewRedeem(uint256 shares) external view returns (uint256);

    /**
     * @notice Convert recipent compounded assets into un-compunding assets
     * @param assets Amount to be converted
     * @param recipient address of assets owner
     * @return Amount of un-compounding assets
     */
    function totalAssetsToDeposits(address recipient, uint256 assets) external view returns (uint256);

    error AddressCannotBeZeroAddress();
    error AmountCannotBeZero();
    error AmountExceedsStakedAmount();
    error RetentionPercentageOutOfRange();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpLeverageStrategy {
    /**
     * @notice React to a GLP deposit, borrow GLO from Vault & relabance
     * @param _amount Amount of GLP deposited
     */
    function onGlpDeposit(uint256 _amount) external;

    /**
     * @notice React to a GLP redeem, pay stable debt if is need and transfer GLP to the user
     * @param _amount Amount that the user is attempting to redeem
     * @return Amount of GLP to redeem
     */
    function onGlpRedeem(uint256 _amount) external returns (uint256);

    /**
     * @notice React to a Stable deposit, relabance if is needed
     */
    function onStableDeposit() external;

    /**
     * @notice Redeem GLP for stables
     * @param _amount Amount of stables to reduce from debt
     * @param _amountAfterRetention Amount of stables getting from redeem GLP
     * @return Amount of stables getting from redeem GLP
     */
    function onStableRedeem(uint256 _amount, uint256 _amountAfterRetention) external returns (uint256);

    /**
     * @notice Claim GLP rewards from GMX and split them
     */
    function claimGlpRewards() external;

    /**
     * @notice Return the current utilization of stable Vault
     * @dev Precision is based on 1e12 as 100% percent
     * @return The % of utilization
     */
    function utilization() external view returns (uint256);

    /**
     * @notice Return the current GLP leverage position
     * @dev Precision is based on 1e12 as 1x leverage
     * @return Leverage position
     */
    function leverage() external view returns (uint256);

    /**
     * @notice Return the amount of GLP that represent 1x of leverage
     * @return Amount of GLP
     */
    function getUnderlyingGlp() external view returns (uint256);

    /**
     * @notice Return the stable debt
     * @return Amount of stable debt
     */
    function stableDebt() external view returns (uint256);

    /**
     * @notice Get the stable value of sell _amount of GLP
     * @param _glpAmount Amount of GLP
     * @return Stables getting from _glpAmount of GLP
     */
    function getStableGlpValue(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP amount minted with USDC
     * @param _stableAmount Amount of USDC
     * @return Stables Amount of simulated GLP
     */
    function buyGlpStableSimulation(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Get the required USDC amount to mint _glpAmount of GLP
     * @param _glpAmount Amount of GLP to be minted
     * @return Amount of stables required to mint _glpAmount of GLP
     */
    function getRequiredStableAmount(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP amount required to redeem _stableAmount of USDC
     * @param _stableAmount Amount of USDC
     * @return Stables Amount of simulated GLP amount required to redeem _stableAmount of USDC
     */
    function getRequiredGlpAmount(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Get the simulated GLP mint retention on a glp deposit
     * @param _glpAmount Amount of GLP deposited
     * @return GLP Amount of retention
     */
    function glpMintIncentive(uint256 _glpAmount) external view returns (uint256);

    /**
     * @notice Get GMX incentive to redeem stables
     * @param _stableAmount Amount of stables
     * @return GMX retention to redeem stables
     */
    function getRedeemStableGMXIncentive(uint256 _stableAmount) external view returns (uint256);

    /**
     * @notice Return max leverage configuration
     * @return Max leverage
     */
    function getMaxLeverage() external view returns (uint256);

    /**
     * @notice Return min leverage configuration
     * @return Min leverage
     */
    function getMinLeverage() external view returns (uint256);

    /**
     * @notice Return target leverage configuration
     * @return Target leverage
     */
    function getTargetLeverage() external view returns (uint256);

    /**
     * @notice Return the amount of GLP to reach the GMX cap for USDC
     * @return Cap Difference
     */
    function getGMXCapDifference() external view returns (uint256);

    /**
     * @notice Get the simulated GLP redeem retention on a glp redeem
     * @param _glpAmount Amount of GLP redeemed
     * @return GLP Amount of retention
     */
    function glpRedeemRetention(uint256 _glpAmount) external view returns (uint256);

    event Rebalance(
        uint256 _glpDebt, uint256 indexed _currentLeverage, uint256 indexed _newLeverage, address indexed _sender
    );
    event GetUnderlyingGlp(uint256 _amount);
    event SetLeverageConfig(uint256 _target, uint256 _min, uint256 _max);
    event ClaimGlpRewards(
        address indexed _origin,
        address indexed _sender,
        uint256 _rewards,
        uint256 _timestamp,
        uint256 _leverage,
        uint256 _glpBalance,
        uint256 _underlyingGlp,
        uint256 _glpShares,
        uint256 _stableDebt,
        uint256 _stableShares
    );

    event Liquidate(uint256 indexed _stablesReceived);
    event BorrowGlp(uint256 indexed _amount);
    event BorrowStable(uint256 indexed _amount);
    event RepayStable(uint256 indexed _amount);
    event RepayGlp(uint256 indexed _amount);
    event EmergencyWithdraw(address indexed _to, uint256 indexed _amount);
    event UpdateStableAddress(address _oldStableAddress, address _newStableAddress);
    event UpdateGlpAddress(address _oldGlpAddress, address _newGlpAddress);
    event Leverage(uint256 _glpDeposited, uint256 _glpMinted);
    event LeverageUp(uint256 _stableDebt, uint256 _oldLeverage, uint256 _currentLeverage);
    event LeverageDown(uint256 _stableDebt, uint256 _oldLeverage, uint256 _currentLeverage);
    event Deleverage(uint256 _glpAmount, uint256 _glpRedeemed);

    error ZeroAddressError();
    error InvalidLeverageConfig();
    error InvalidSlippage();
    error ReachedSlippageTolerance();
    error OverLeveraged();
    error UnderLeveraged();
    error NotEnoughUnderlyingGlp();
    error NotEnoughStables();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpOldRewards {
    function balanceOf(address _user) external returns (uint256);
    function getReward(address _user) external returns (uint256);
    function withdraw(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardDistributor {
    event Distribute(uint256 amount);
    event SplitRewards(uint256 _glpRewards, uint256 _stableRewards, uint256 _jonesRewards);

    /**
     * @notice Send the pool rewards to the tracker
     * @dev This function is called from the Reward Tracker
     * @return Amount of rewards sent
     */
    function distributeRewards() external returns (uint256);

    /**
     * @notice Split the rewards comming from GMX
     * @param _amount of rewards to be splited
     * @param _leverage current strategy leverage
     * @param _utilization current stable pool utilization
     */
    function splitRewards(uint256 _amount, uint256 _leverage, uint256 _utilization) external;

    /**
     * @notice Return the pending rewards to be distributed of a pool
     * @param _pool Address of the Reward Tracker pool
     * @return Amount of pending rewards
     */
    function pendingRewards(address _pool) external view returns (uint256);

    error AddressCannotBeZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardTracker {
    event Stake(address indexed depositor, uint256 amount);
    event Withdraw(address indexed _account, uint256 _amount);
    event Claim(address indexed receiver, uint256 amount);
    event UpdateRewards(address indexed _account, uint256 _rewards, uint256 _totalShares, uint256 _rewardPerShare);

    /**
     * @notice Stake into this contract assets to start earning rewards
     * @param _account Owner of the stake and future rewards
     * @param _amount Assets to be staked
     * @return Amount of assets staked
     */
    function stake(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Withdraw the staked assets
     * @param _account Owner of the assets to be withdrawn
     * @param _amount Assets to be withdrawn
     * @return Amount of assets witdrawed
     */
    function withdraw(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Claim _account cumulative rewards
     * @dev Reward token will be transfer to the _account
     * @param _account Owner of the rewards
     * @return Amount of reward tokens transferred
     */
    function claim(address _account) external returns (uint256);

    /**
     * @notice Return _account claimable rewards
     * @dev No reward token are transferred
     * @param _account Owner of the rewards
     * @return Amount of reward tokens that can be claim
     */
    function claimable(address _account) external view returns (uint256);

    /**
     * @notice Return _account staked amount
     * @param _account Owner of the staking
     * @return Staked amount
     */
    function stakedAmount(address _account) external view returns (uint256);

    /**
     * @notice Update global cumulative reward
     * @dev No reward token are transferred
     */
    function updateRewards() external;

    /**
     * @notice Deposit rewards
     * @dev Transfer from called here
     * @param _rewards Amount of reward asset transferer
     */
    function depositRewards(uint256 _rewards) external;

    error AddressCannotBeZeroAddress();
    error AmountCannotBeZero();
    error AmountExceedsStakedAmount();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpRewardsSwapper {
    event Swap(address indexed _tokenIn, uint256 _amountIn, address indexed _tokenOut, uint256 _amountOut);

    /**
     * @notice Swap eth rewards to USDC
     * @param _amountIn amount of rewards to swap
     * @return amount of USDC swapped
     */
    function swapRewards(uint256 _amountIn) external returns (uint256);

    /**
     * @notice Return min amount out of USDC due a weth in amount considering the slippage tolerance
     * @param _amountIn amount of weth rewards to swap
     * @return min output amount of USDC
     */
    function minAmountOut(uint256 _amountIn) external view returns (uint256);

    error InvalidSlippage();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IJonesGlpVaultRouter {
    function depositGlp(uint256 _assets, address _sender, bool _compound) external returns (uint256);
    function depositStable(uint256 _assets, bool _compound, address _user) external returns (uint256);
    function redeemGlpAdapter(uint256 _shares, bool _compound, address _token, address _user, bool _native)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAggregatorV3} from "./IAggregatorV3.sol";

interface IJonesUsdVault {
    function priceOracle() external view returns (IAggregatorV3);
    function tvl() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount)
        external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStakedGlp {
    function stakedGlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWhitelistController {
    struct RoleInfo {
        bool jGLP_BYPASS_CAP;
        bool jUSDC_BYPASS_TIME;
        uint256 jGLP_RETENTION;
        uint256 jUSDC_RETENTION;
    }

    function isInternalContract(address _account) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getUserRole(address _user) external view returns (bytes32);
    function getRoleInfo(bytes32 _role) external view returns (IWhitelistController.RoleInfo memory);
    function getDefaultRole() external view returns (IWhitelistController.RoleInfo memory);
    function isWhitelistedContract(address _account) external view returns (bool);
    function addToInternalContract(address _account) external;
    function addToWhitelistContracts(address _account) external;
    function removeFromInternalContract(address _account) external;
    function removeFromWhitelistContract(address _account) external;
    function bulkAddToWhitelistContracts(address[] calldata _accounts) external;
    function bulkRemoveFromWhitelistContract(address[] calldata _accounts) external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {IJonesBorrowableVault} from "../interfaces/IJonesBorrowableVault.sol";
import {Pausable} from "../common/Pausable.sol";

abstract contract JonesBorrowableVault is JonesGovernableVault, ERC4626, IJonesBorrowableVault, Pausable {
    bytes32 public constant BORROWER = bytes32("BORROWER");

    modifier onlyBorrower() {
        if (!hasRole(BORROWER, msg.sender)) {
            revert CallerIsNotBorrower();
        }
        _;
    }

    function addBorrower(address _newBorrower) external onlyGovernor {
        _grantRole(BORROWER, _newBorrower);

        emit BorrowerAdded(_newBorrower);
    }

    function removeBorrower(address _borrower) external onlyGovernor {
        _revokeRole(BORROWER, _borrower);

        emit BorrowerRemoved(_borrower);
    }

    function togglePause() external onlyGovernor {
        if (paused()) {
            _unpause();
            return;
        }

        _pause();
    }

    function borrow(uint256 _amount) external virtual onlyBorrower whenNotPaused returns (uint256) {
        IERC20(asset()).transfer(msg.sender, _amount);

        emit AssetsBorrowed(msg.sender, _amount);

        return _amount;
    }

    function repay(uint256 _amount) external virtual onlyBorrower returns (uint256) {
        IERC20(asset()).transferFrom(msg.sender, address(this), _amount);

        emit AssetsRepayed(msg.sender, _amount);

        return _amount;
    }

    event BorrowerAdded(address _newBorrower);
    event BorrowerRemoved(address _borrower);
    event AssetsBorrowed(address _borrower, uint256 _amount);
    event AssetsRepayed(address _borrower, uint256 _amount);

    error CallerIsNotBorrower();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract JonesGovernableVault is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

abstract contract JonesOperableVault is JonesGovernableVault, ERC4626 {
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    function addOperator(address _newOperator) external onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    function deposit(uint256 _assets, address _receiver) public virtual override onlyOperator returns (uint256) {
        return super.deposit(_assets, _receiver);
    }

    function mint(uint256 _shares, address _receiver) public virtual override onlyOperator returns (uint256) {
        return super.mint(_shares, _receiver);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        virtual
        override
        onlyOperator
        returns (uint256)
    {
        return super.withdraw(_assets, _receiver, _owner);
    }

    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        virtual
        override
        onlyOperator
        returns (uint256)
    {
        return super.redeem(_shares, _receiver, _owner);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {JonesGovernableVault} from "./JonesGovernableVault.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {IJonesUsdVault} from "../interfaces/IJonesUsdVault.sol";

abstract contract JonesUsdVault is JonesGovernableVault, ERC4626, IJonesUsdVault {
    IAggregatorV3 public priceOracle;

    constructor(IAggregatorV3 _priceOracle) {
        priceOracle = _priceOracle;
    }

    function setPriceAggregator(IAggregatorV3 _newPriceOracle) external onlyGovernor {
        emit PriceOracleUpdated(address(priceOracle), address(_newPriceOracle));

        priceOracle = _newPriceOracle;
    }

    function tvl() external view returns (uint256) {
        return _toUsdValue(totalAssets());
    }

    function _toUsdValue(uint256 _value) internal view returns (uint256) {
        IAggregatorV3 oracle = priceOracle;

        (, int256 currentPrice,,,) = oracle.latestRoundData();

        uint8 totalDecimals = IERC20Metadata(asset()).decimals() + oracle.decimals();
        uint8 targetDecimals = 18;

        return totalDecimals > targetDecimals
            ? (_value * uint256(currentPrice)) / 10 ** (totalDecimals - targetDecimals)
            : (_value * uint256(currentPrice)) * 10 ** (targetDecimals - totalDecimals);
    }

    event PriceOracleUpdated(address _oldPriceOracle, address _newPriceOracle);
}