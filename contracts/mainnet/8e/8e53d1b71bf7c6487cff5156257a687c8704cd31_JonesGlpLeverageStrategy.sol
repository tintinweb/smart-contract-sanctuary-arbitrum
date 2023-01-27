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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 Jones DAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Governable, OperableKeepable} from "../../common/OperableKeepable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IJonesBorrowableVault} from "../../interfaces/IJonesBorrowableVault.sol";
import {IJonesUsdVault} from "../../interfaces/IJonesUsdVault.sol";
import {IJonesGlpRewardDistributor} from "../../interfaces/IJonesGlpRewardDistributor.sol";
import {IAggregatorV3} from "../../interfaces/IAggregatorV3.sol";
import {IGmxRewardRouter} from "../../interfaces/IGmxRewardRouter.sol";
import {IJonesGlpLeverageStrategy} from "../../interfaces/IJonesGlpLeverageStrategy.sol";
import {IGlpManager} from "../../../src/interfaces/IGlpManager.sol";
import {IGMXVault} from "../../../src/interfaces/IGMXVault.sol";
import {IRewardTracker} from "../../../src/interfaces/IRewardTracker.sol";

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
        address _stable
    ) Governable(msg.sender) ReentrancyGuard() {
        stableVault = _stableVault;
        glpVault = _glpVault;
        distributor = _distributor;

        stable = IERC20(_stable);
        glp = IERC20(_glp);

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
        (uint256 glpAmount,) = _getRequiredGlpAmount(_amountAfterRetention + 2);

        routerV2.unstakeAndRedeemGlp(address(stable), glpAmount, _amountAfterRetention, address(this));

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
            vault.getFeeBasisPoints(usdc, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);

        uint256 glpRequired = (glpAmount * GMX_BASIS) / (GMX_BASIS - retentionBasisPoints);

        (uint256 theoreticalStables,) = _sellGlpStableSimulation(glpRequired);

        while (theoreticalStables < _stableAmount - 2) {
            retentionBasisPoints = retentionBasisPoints + 1;
            glpRequired = (glpAmount * GMX_BASIS) / (GMX_BASIS - retentionBasisPoints);
            (theoreticalStables,) = _sellGlpStableSimulation(glpRequired);
        }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface IJonesBorrowableVault is IERC4626 {
    function borrow(uint256 _amount) external returns (uint256);
    function repay(uint256 _amount) external returns (uint256);
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