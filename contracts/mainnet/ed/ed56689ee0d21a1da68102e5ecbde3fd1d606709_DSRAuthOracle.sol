// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { AccessControl } from 'openzeppelin-contracts/contracts/access/AccessControl.sol';

import { DSROracleBase, IDSROracle } from './DSROracleBase.sol';
import { IDSRAuthOracle }            from './interfaces/IDSRAuthOracle.sol';

/**
 * @title  DSRAuthOracle
 * @notice DSR Oracle that allows permissioned setting of the pot data.
 */
contract DSRAuthOracle is AccessControl, DSROracleBase, IDSRAuthOracle {

    uint256 private constant RAY = 1e27;

    bytes32 public constant DATA_PROVIDER_ROLE = keccak256('DATA_PROVIDER_ROLE');

    uint256 public maxDSR;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DATA_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);

        maxDSR = RAY;
    }

    function setMaxDSR(uint256 _maxDSR) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxDSR >= RAY, 'DSRAuthOracle/invalid-max-dsr');

        maxDSR = _maxDSR;
        emit SetMaxDSR(_maxDSR);
    }

    function setPotData(IDSROracle.PotData calldata nextData) external onlyRole(DATA_PROVIDER_ROLE) {
        IDSROracle.PotData memory previousData = _data;

        if (_data.rho == 0) {
            // This is a first update
            // No need to run checks
            _setPotData(nextData);
            return;
        }

        // Perform sanity checks to minimize damage in case of malicious data being proposed

        // Enforce non-decreasing values of rho in case of message reordering
        // The same timestamp is allowed as the other values will only change upon increasing rho
        require(nextData.rho >= previousData.rho, 'DSRAuthOracle/invalid-rho');

        // Timestamp must be in the past
        require(nextData.rho <= block.timestamp, 'DSRAuthOracle/invalid-rho');

        // DSR sanity bounds
        uint256 _maxDSR = maxDSR;
        require(nextData.dsr >= RAY,     'DSRAuthOracle/invalid-dsr');
        require(nextData.dsr <= _maxDSR, 'DSRAuthOracle/invalid-dsr');

        // `chi` must be non-decreasing
        require(nextData.chi >= previousData.chi, 'DSRAuthOracle/invalid-chi');

        // Accumulation cannot be larger than the time elapsed at the max dsr
        uint256 chiMax = _rpow(_maxDSR, nextData.rho - previousData.rho) * previousData.chi / RAY;
        require(nextData.chi <= chiMax, 'DSRAuthOracle/invalid-chi');

        _setPotData(nextData);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

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
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
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
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
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
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
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
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { IDSROracle } from './interfaces/IDSROracle.sol';

/**
 * @title  DSROracleBase
 * @notice Base functionality for all DSR oracles.
 */
abstract contract DSROracleBase is IDSROracle {

    uint256 private constant RAY = 1e27;

    IDSROracle.PotData internal _data;

    function _setPotData(IDSROracle.PotData memory nextData) internal {
        _data = nextData;

        emit SetPotData(nextData);
    }

    function getPotData() external override view returns (IDSROracle.PotData memory) {
        return _data;
    }

    function getDSR() external override view returns (uint256) {
        return _data.dsr;
    }

    function getChi() external override view returns (uint256) {
        return _data.chi;
    }

    function getRho() external override view returns (uint256) {
        return _data.rho;
    }

    function getAPR() external override view returns (uint256) {
        unchecked {
            return (_data.dsr - RAY) * 365 days;
        }
    }

    function getConversionRate() external override view returns (uint256) {
        return getConversionRate(block.timestamp);
    }

    function getConversionRate(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");

        uint256 duration;
        unchecked {
            duration = timestamp - rho;
        }
        return _rpow(d.dsr, duration) * uint256(d.chi) / RAY;
    }

    function getConversionRateBinomialApprox() external override view returns (uint256) {
        return getConversionRateBinomialApprox(block.timestamp);
    }

    // Copied and slightly modified from https://github.com/aave/aave-v3-core/blob/42103522764546a4eeb856b741214fa5532be52a/contracts/protocol/libraries/math/MathUtils.sol#L50
    function getConversionRateBinomialApprox(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");
        
        uint256 exp;
        uint256 rate;
        unchecked {
            exp = timestamp - rho;
            rate = d.dsr - RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rate * rate / RAY;
            basePowerThree = basePowerTwo * rate / RAY;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return d.chi * (RAY + (rate * exp) + secondTerm + thirdTerm) / RAY;
    }

    function getConversionRateLinearApprox() external override view returns (uint256) {
        return getConversionRateLinearApprox(block.timestamp);
    }

    function getConversionRateLinearApprox(uint256 timestamp) public override view returns (uint256) {
        IDSROracle.PotData memory d = _data;
        uint256 rho = d.rho;
        if (timestamp == rho) return d.chi;
        require(timestamp >= rho, "DSROracleBase/invalid-timestamp");
        
        uint256 duration;
        uint256 rate;
        unchecked {
            duration = timestamp - rho;
            rate = uint256(d.dsr) - RAY;
        }
        return (rate * duration + RAY) * uint256(d.chi) / RAY;
    }

    // Copied from https://github.com/makerdao/sdai/blob/e6f8cfa1d638b1ef1c6187a1d18f73b21d2754a2/src/SavingsDai.sol#L118
    function _rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := RAY} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := RAY } default { z := x }
                let half := div(RAY, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, RAY)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IDSROracle } from './IDSROracle.sol';

/**
 * @title  IDSRAuthOracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSRAuthOracle is IDSROracle {

    /** 
     * @notice Emitted when the maxDSR is updated.
     */
    event SetMaxDSR(uint256 maxDSR);

    /**
     * @notice The data provider role.
     */
    function DATA_PROVIDER_ROLE() external view returns (bytes32);

    /**
     * @notice Get the max dsr.
     */
    function maxDSR() external view returns (uint256);

    /**
     * @notice Set the max dsr.
     * @param  maxDSR The max dsr.
     * @dev    Only callable by the admin role.
     */
    function setMaxDSR(uint256 maxDSR) external;

    /**
     * @notice Update the pot data.
     * @param  data The max dsr.
     * @dev    Only callable by the data provider role.
     */
    function setPotData(IDSROracle.PotData calldata data) external;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

/**
 * @title  IDSROracle
 * @notice Consolidated DSR reporting along with some convenience functions.
 */
interface IDSROracle {

    struct PotData {
        uint96  dsr;  // Dai Savings Rate in per-second value [ray]
        uint120 chi;  // Last computed conversion rate [ray]
        uint40  rho;  // Last computed timestamp [seconds]
    }

    /**
     * @notice Emitted when the PotData is updated.
     * @param  nextData The new PotData struct.
     */
    event SetPotData(PotData nextData);

    /**
     * @notice Retrieve the current PotData: dsr, chi, and rho.
     * @return The current PotData struct.
     */
    function getPotData() external view returns (PotData memory);

    /**
     * @notice Get the current Dai Savings Rate.
     * @return The Dai Savings Rate in per-second value [ray].
     */
    function getDSR() external view returns (uint256);

    /**
     * @notice Get the last computed conversion rate.
     * @return The last computed conversion rate [ray].
     */
    function getChi() external view returns (uint256);

    /**
     * @notice Get the last computed timestamp.
     * @return The last computed timestamp [seconds].
     */
    function getRho() external view returns (uint256);

    /**
     * @notice Get the Annual Percentage Rate.
     * @return The APR.
     */
    function getAPR() external view returns (uint256);

    /**
     * @notice Get the conversion rate at the current timestamp.
     * @return The conversion rate.
     */
    function getConversionRate() external view returns (uint256);

    /**
     * @notice Get the conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the conversion rate.
     * @return The conversion rate.
     */
    function getConversionRate(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at the current timestamp.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox() external view returns (uint256);

    /**
     * @notice Get the binomial approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the binomial approximated conversion rate.
     * @return The binomial approximated conversion rate.
     */
    function getConversionRateBinomialApprox(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at the current timestamp.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox() external view returns (uint256);

    /**
     * @notice Get the linear approximated conversion rate at a specified timestamp.
     * @dev    Timestamp must be greater than or equal to the current timestamp.
     * @param  timestamp The timestamp at which to retrieve the linear approximated conversion rate.
     * @return The linear approximated conversion rate.
     */
    function getConversionRateLinearApprox(uint256 timestamp) external view returns (uint256);

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