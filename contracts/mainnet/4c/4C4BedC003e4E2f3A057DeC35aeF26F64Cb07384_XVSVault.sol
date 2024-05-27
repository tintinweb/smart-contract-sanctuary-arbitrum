// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

import "./IAccessControlManagerV5.sol";

/**
 * @title AccessControlledV5
 * @author Venus
 * @notice This contract is helper between access control manager and actual contract. This contract further inherited by other contract (using solidity 0.5.16)
 * to integrate access controlled mechanism. It provides initialise methods and verifying access methods.
 */
contract AccessControlledV5 {
    /// @notice Access control manager contract
    IAccessControlManagerV5 private _accessControlManager;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Emitted when access control manager contract address is changed
    event NewAccessControlManager(address oldAccessControlManager, address newAccessControlManager);

    /**
     * @notice Returns the address of the access control manager contract
     */
    function accessControlManager() external view returns (IAccessControlManagerV5) {
        return _accessControlManager;
    }

    /**
     * @dev Internal function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     */
    function _setAccessControlManager(address accessControlManager_) internal {
        require(address(accessControlManager_) != address(0), "invalid acess control manager address");
        address oldAccessControlManager = address(_accessControlManager);
        _accessControlManager = IAccessControlManagerV5(accessControlManager_);
        emit NewAccessControlManager(oldAccessControlManager, accessControlManager_);
    }

    /**
     * @notice Reverts if the call is not allowed by AccessControlManager
     * @param signature Method signature
     */
    function _checkAccessAllowed(string memory signature) internal view {
        bool isAllowedToCall = _accessControlManager.isAllowedToCall(msg.sender, signature);

        if (!isAllowedToCall) {
            revert("Unauthorized");
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

/**
 * @title IAccessControlManagerV5
 * @author Venus
 * @notice Interface implemented by the `AccessControlManagerV5` contract.
 */
interface IAccessControlManagerV5 {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
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

    /**
     * @notice Gives a function call permission to one single account
     * @dev this function can be called only from Role Admin or DEFAULT_ADMIN_ROLE
     * 		May emit a {RoleGranted} event.
     * @param contractAddress address of contract for which call permissions will be granted
     * @param functionSig signature e.g. "functionName(uint,bool)"
     */
    function giveCallPermission(address contractAddress, string calldata functionSig, address accountToPermit) external;

    /**
     * @notice Revokes an account's permission to a particular function call
     * @dev this function can be called only from Role Admin or DEFAULT_ADMIN_ROLE
     * 		May emit a {RoleRevoked} event.
     * @param contractAddress address of contract for which call permissions will be revoked
     * @param functionSig signature e.g. "functionName(uint,bool)"
     */
    function revokeCallPermission(
        address contractAddress,
        string calldata functionSig,
        address accountToRevoke
    ) external;

    /**
     * @notice Verifies if the given account can call a praticular contract's function
     * @dev Since the contract is calling itself this function, we can get contracts address with msg.sender
     * @param account address (eoa or contract) for which call permissions will be checked
     * @param functionSig signature e.g. "functionName(uint,bool)"
     * @return false if the user account cannot call the particular contract function
     *
     */
    function isAllowedToCall(address account, string calldata functionSig) external view returns (bool);

    function hasPermission(
        address account,
        address contractAddress,
        string calldata functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.5.16;

contract TimeManagerV5 {
    /// @dev The approximate number of seconds per year
    uint256 public constant SECONDS_PER_YEAR = 31_536_000;

    /// @notice Number of blocks per year or seconds per year
    uint256 public blocksOrSecondsPerYear;

    /// @dev Sets true when block timestamp is used
    bool public isTimeBased;

    /// @dev Sets true when contract is initialized
    bool private isInitialized;

    /// @notice Deprecated slot for _getCurrentSlot function pointer
    bytes8 private __deprecatedSlot1;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    /**
     * @dev Function to simply retrieve block number or block timestamp
     * @return Current block number or block timestamp
     */
    function getBlockNumberOrTimestamp() public view returns (uint256) {
        return isTimeBased ? _getBlockTimestamp() : _getBlockNumber();
    }

    /**
     * @dev Initializes the contract to use either blocks or seconds
     * @param timeBased_ A boolean indicating whether the contract is based on time or block
     * If timeBased is true than blocksPerYear_ param is ignored as blocksOrSecondsPerYear is set to SECONDS_PER_YEAR
     * @param blocksPerYear_ The number of blocks per year
     */
    function _initializeTimeManager(bool timeBased_, uint256 blocksPerYear_) internal {
        if (isInitialized) revert("Already initialized TimeManager");

        if (!timeBased_ && blocksPerYear_ == 0) {
            revert("Invalid blocks per year");
        }
        if (timeBased_ && blocksPerYear_ != 0) {
            revert("Invalid time based configuration");
        }

        isTimeBased = timeBased_;
        blocksOrSecondsPerYear = timeBased_ ? SECONDS_PER_YEAR : blocksPerYear_;
        isInitialized = true;
    }

    /**
     * @dev Returns the current timestamp in seconds
     * @return The current timestamp
     */
    function _getBlockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the current block number
     * @return The current block number
     */
    function _getBlockNumber() private view returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title IPrime
 * @author Venus
 * @notice Interface for Prime Token
 */
interface IPrime {
    /**
     * @notice Executed by XVSVault whenever user's XVSVault balance changes
     * @param user the account address whose balance was updated
     */
    function xvsUpdated(address user) external;

    /**
     * @notice accrues interest and updates score for an user for a specific market
     * @param user the account address for which to accrue interest and update score
     * @param market the market for which to accrue interest and update score
     */
    function accrueInterestAndUpdateScore(address user, address market) external;

    /**
     * @notice Distributes income from market since last distribution
     * @param vToken the market for which to distribute the income
     */
    function accrueInterest(address vToken) external;

    /**
     * @notice Returns if user is a prime holder
     * @param isPrimeHolder returns if the user is a prime holder
     */
    function isUserPrimeHolder(address user) external view returns (bool isPrimeHolder);
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        // solium-disable-next-line security/no-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts v4.3.2 (utils/cryptography/ECDSA.sol)

// SPDX-Copyright-Text: OpenZeppelin, 2021
// SPDX-Copyright-Text: Venus, 2021

pragma solidity ^0.5.16;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
contract ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for BEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2 ** 64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2 ** 16, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2 ** 127 && value < 2 ** 127, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2 ** 63 && value < 2 ** 63, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2 ** 31 && value < 2 ** 31, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2 ** 15 && value < 2 ** 15, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2 ** 7 && value < 2 ** 7, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: addition overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.5.16;
import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";

/**
 * @title XVS Store
 * @author Venus
 * @notice XVS Store responsible for distributing XVS rewards
 */
contract XVSStore {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice The Admin Address
    address public admin;

    /// @notice The pending admin address
    address public pendingAdmin;

    /// @notice The Owner Address
    address public owner;

    /// @notice The reward tokens
    mapping(address => bool) public rewardTokens;

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Event emitted when admin changed
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Event emitted when owner changed
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can");
        _;
    }

    /**
     * @notice Safely transfer rewards. Only active reward tokens can be sent using this function.
     * Only callable by owner
     * @dev Safe reward token transfer function, just in case if rounding error causes pool to not have enough tokens.
     * @param token Reward token to transfer
     * @param _to Destination address of the reward
     * @param _amount Amount to transfer
     */
    function safeRewardTransfer(address token, address _to, uint256 _amount) external onlyOwner {
        require(rewardTokens[token] == true, "only reward token can");

        if (address(token) != address(0)) {
            uint256 tokenBalance = IBEP20(token).balanceOf(address(this));
            if (_amount > tokenBalance) {
                IBEP20(token).safeTransfer(_to, tokenBalance);
            } else {
                IBEP20(token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * @notice Allows the admin to propose a new admin
     * Only callable admin
     * @param _admin Propose an account as admin of the XVS store
     */
    function setPendingAdmin(address _admin) external onlyAdmin {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = _admin;
        emit NewPendingAdmin(oldPendingAdmin, _admin);
    }

    /**
     * @notice Allows an account that is pending as admin to accept the role
     * nly calllable by the pending admin
     */
    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "only pending admin");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
        emit AdminTransferred(oldAdmin, admin);
    }

    /**
     * @notice Set the contract owner
     * @param _owner The address of the owner to set
     * Only callable admin
     */
    function setNewOwner(address _owner) external onlyAdmin {
        require(_owner != address(0), "new owner is the zero address");
        address oldOwner = owner;
        owner = _owner;
        emit OwnerTransferred(oldOwner, _owner);
    }

    /**
     * @notice Set or disable a reward token
     * @param _tokenAddress The address of a token to set as active or inactive
     * @param status Set whether a reward token is active or not
     */
    function setRewardToken(address _tokenAddress, bool status) external {
        require(msg.sender == admin || msg.sender == owner, "only admin or owner can");
        rewardTokens[_tokenAddress] = status;
    }

    /**
     * @notice Security function to allow the owner of the contract to withdraw from the contract
     * @param _tokenAddress Reward token address to withdraw
     * @param _amount Amount of token to withdraw
     */
    function emergencyRewardWithdraw(address _tokenAddress, uint256 _amount) external onlyOwner {
        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "../Utils/ECDSA.sol";
import "../Utils/SafeBEP20.sol";
import "../Utils/IBEP20.sol";
import "./XVSVaultStorage.sol";
import "../Tokens/Prime/IPrime.sol";
import "../Utils/SafeCast.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV5.sol";
import "@venusprotocol/solidity-utilities/contracts/TimeManagerV5.sol";

import { XVSStore } from "./XVSStore.sol";
import { XVSVaultProxy } from "./XVSVaultProxy.sol";

/**
 * @title XVS Vault
 * @author Venus
 * @notice The XVS Vault allows XVS holders to lock their XVS to recieve voting rights in Venus governance and are rewarded with XVS.
 */
contract XVSVault is XVSVaultStorage, ECDSA, AccessControlledV5, TimeManagerV5 {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice The upper bound for the lock period in a pool, 10 years
    uint256 public constant MAX_LOCK_PERIOD = 60 * 60 * 24 * 365 * 10;

    /// @notice Event emitted when deposit
    event Deposit(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when execute withrawal
    event ExecutedWithdrawal(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when request withrawal
    event RequestedWithdrawal(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChangedV2(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChangedV2(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice An event emitted when the reward store address is updated
    event StoreUpdated(address oldXvs, address oldStore, address newXvs, address newStore);

    /// @notice An event emitted when the withdrawal locking period is updated for a pool
    event WithdrawalLockingPeriodUpdated(address indexed rewardToken, uint indexed pid, uint oldPeriod, uint newPeriod);

    /// @notice An event emitted when the reward amount per block or second is modified for a pool
    event RewardAmountUpdated(address indexed rewardToken, uint oldReward, uint newReward);

    /// @notice An event emitted when a new pool is added
    event PoolAdded(
        address indexed rewardToken,
        uint indexed pid,
        address indexed token,
        uint allocPoints,
        uint rewardPerBlockOrSecond,
        uint lockPeriod
    );

    /// @notice An event emitted when a pool allocation points are updated
    event PoolUpdated(address indexed rewardToken, uint indexed pid, uint oldAllocPoints, uint newAllocPoints);

    /// @notice Event emitted when reward claimed
    event Claim(address indexed user, address indexed rewardToken, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when vault is paused
    event VaultPaused(address indexed admin);

    /// @notice Event emitted when vault is resumed after pause
    event VaultResumed(address indexed admin);

    /// @notice Event emitted when protocol logs a debt to a user due to insufficient funds for pending reward distribution
    event VaultDebtUpdated(
        address indexed rewardToken,
        address indexed userAddress,
        uint256 oldOwedAmount,
        uint256 newOwedAmount
    );

    /// @notice Emitted when prime token contract address is changed
    event NewPrimeToken(
        IPrime indexed oldPrimeToken,
        IPrime indexed newPrimeToken,
        address oldPrimeRewardToken,
        address newPrimeRewardToken,
        uint256 oldPrimePoolId,
        uint256 newPrimePoolId
    );

    /**
     * @notice XVSVault constructor
     */
    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @dev Prevents functions to execute when vault is paused.
     */
    modifier isActive() {
        require(!vaultPaused, "Vault is paused");
        _;
    }

    /**
     * @notice Pauses vault
     */
    function pause() external {
        _checkAccessAllowed("pause()");
        require(!vaultPaused, "Vault is already paused");
        vaultPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @notice Resume vault
     */
    function resume() external {
        _checkAccessAllowed("resume()");
        require(vaultPaused, "Vault is not paused");
        vaultPaused = false;
        emit VaultResumed(msg.sender);
    }

    /**
     * @notice Returns the number of pools with the specified reward token
     * @param rewardToken Reward token address
     * @return Number of pools that distribute the specified token as a reward
     */
    function poolLength(address rewardToken) external view returns (uint256) {
        return poolInfos[rewardToken].length;
    }

    /**
     * @notice Returns the number of reward tokens created per block or second
     * @param _rewardToken Reward token address
     * @return Number of reward tokens created per block or second
     */
    function rewardTokenAmountsPerBlock(address _rewardToken) external view returns (uint256) {
        return rewardTokenAmountsPerBlockOrSecond[_rewardToken];
    }

    /**
     * @notice Add a new token pool
     * @dev This vault DOES NOT support deflationary tokens — it expects that
     *   the amount of transferred tokens would equal the actually deposited
     *   amount. In practice this means that this vault DOES NOT support USDT
     *   and similar tokens (that do not provide these guarantees).
     * @param _rewardToken Reward token address
     * @param _allocPoint Number of allocation points assigned to this pool
     * @param _token Staked token
     * @param _rewardPerBlockOrSecond Initial reward per block or second, in terms of _rewardToken
     * @param _lockPeriod A period between withdrawal request and a moment when it's executable
     */
    function add(
        address _rewardToken,
        uint256 _allocPoint,
        IBEP20 _token,
        uint256 _rewardPerBlockOrSecond,
        uint256 _lockPeriod
    ) external {
        _checkAccessAllowed("add(address,uint256,address,uint256,uint256)");
        _ensureNonzeroAddress(_rewardToken);
        _ensureNonzeroAddress(address(_token));
        require(address(xvsStore) != address(0), "Store contract address is empty");
        require(_allocPoint > 0, "Alloc points must not be zero");

        massUpdatePools(_rewardToken);

        PoolInfo[] storage poolInfo = poolInfos[_rewardToken];

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Pool already added");
        }

        // We use balanceOf to get the supply amount, so shouldn't be possible to
        // configure pools with different reward token but the same staked token
        require(!isStakedToken[address(_token)], "Token exists in other pool");

        totalAllocPoints[_rewardToken] = totalAllocPoints[_rewardToken].add(_allocPoint);

        rewardTokenAmountsPerBlockOrSecond[_rewardToken] = _rewardPerBlockOrSecond;

        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlockOrSecond: getBlockNumberOrTimestamp(),
                accRewardPerShare: 0,
                lockPeriod: _lockPeriod
            })
        );
        isStakedToken[address(_token)] = true;

        XVSStore(xvsStore).setRewardToken(_rewardToken, true);

        emit PoolAdded(
            _rewardToken,
            poolInfo.length - 1,
            address(_token),
            _allocPoint,
            _rewardPerBlockOrSecond,
            _lockPeriod
        );
    }

    /**
     * @notice Update the given pool's reward allocation point
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _allocPoint Number of allocation points assigned to this pool
     */
    function set(address _rewardToken, uint256 _pid, uint256 _allocPoint) external {
        _checkAccessAllowed("set(address,uint256,uint256)");
        _ensureValidPool(_rewardToken, _pid);

        massUpdatePools(_rewardToken);

        PoolInfo[] storage poolInfo = poolInfos[_rewardToken];
        uint256 newTotalAllocPoints = totalAllocPoints[_rewardToken].sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        require(newTotalAllocPoints > 0, "Alloc points per reward token must not be zero");

        uint256 oldAllocPoints = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        totalAllocPoints[_rewardToken] = newTotalAllocPoints;

        emit PoolUpdated(_rewardToken, _pid, oldAllocPoints, _allocPoint);
    }

    /**
     * @notice Update the given reward token's amount per block or second
     * @param _rewardToken Reward token address
     * @param _rewardAmount Number of allocation points assigned to this pool
     */
    function setRewardAmountPerBlockOrSecond(address _rewardToken, uint256 _rewardAmount) external {
        _checkAccessAllowed("setRewardAmountPerBlockOrSecond(address,uint256)");
        require(XVSStore(xvsStore).rewardTokens(_rewardToken), "Invalid reward token");
        massUpdatePools(_rewardToken);
        uint256 oldReward = rewardTokenAmountsPerBlockOrSecond[_rewardToken];
        rewardTokenAmountsPerBlockOrSecond[_rewardToken] = _rewardAmount;

        emit RewardAmountUpdated(_rewardToken, oldReward, _rewardAmount);
    }

    /**
     * @notice Update the lock period after which a requested withdrawal can be executed
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _newPeriod New lock period
     */
    function setWithdrawalLockingPeriod(address _rewardToken, uint256 _pid, uint256 _newPeriod) external {
        _checkAccessAllowed("setWithdrawalLockingPeriod(address,uint256,uint256)");
        _ensureValidPool(_rewardToken, _pid);
        require(_newPeriod > 0 && _newPeriod < MAX_LOCK_PERIOD, "Invalid new locking period");
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        uint256 oldPeriod = pool.lockPeriod;
        pool.lockPeriod = _newPeriod;

        emit WithdrawalLockingPeriodUpdated(_rewardToken, _pid, oldPeriod, _newPeriod);
    }

    /**
     * @notice Deposit XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _amount The amount to deposit to vault
     */
    function deposit(address _rewardToken, uint256 _pid, uint256 _amount) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        _updatePool(_rewardToken, _pid);
        require(pendingWithdrawalsBeforeUpgrade(_rewardToken, _pid, msg.sender) == 0, "execute pending withdrawal");

        if (user.amount > 0) {
            uint256 pending = _computeReward(user, pool);
            if (pending > 0) {
                _transferReward(_rewardToken, msg.sender, pending);
                emit Claim(msg.sender, _rewardToken, _pid, pending);
            }
        }
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = _cumulativeReward(user, pool);

        // Update Delegate Amount
        if (address(pool.token) == xvsAddress) {
            _moveDelegates(address(0), delegates[msg.sender], safe96(_amount, "XVSVault::deposit: votes overflow"));
        }

        if (primeRewardToken == _rewardToken && _pid == primePoolId) {
            primeToken.xvsUpdated(msg.sender);
        }

        emit Deposit(msg.sender, _rewardToken, _pid, _amount);
    }

    /**
     * @notice Claim rewards for pool
     * @param _account The account for which to claim rewards
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     */
    function claim(address _account, address _rewardToken, uint256 _pid) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][_account];
        _updatePool(_rewardToken, _pid);
        require(pendingWithdrawalsBeforeUpgrade(_rewardToken, _pid, _account) == 0, "execute pending withdrawal");

        if (user.amount > 0) {
            uint256 pending = _computeReward(user, pool);

            if (pending > 0) {
                user.rewardDebt = _cumulativeReward(user, pool);

                _transferReward(_rewardToken, _account, pending);
                emit Claim(_account, _rewardToken, _pid, pending);
            }
        }
    }

    /**
     * @notice Pushes withdrawal request to the requests array and updates
     *   the pending withdrawals amount. The requests are always sorted
     *   by unlock time (descending) so that the earliest to execute requests
     *   are always at the end of the array.
     * @param _user The user struct storage pointer
     * @param _requests The user's requests array storage pointer
     * @param _amount The amount being requested
     */
    function pushWithdrawalRequest(
        UserInfo storage _user,
        WithdrawalRequest[] storage _requests,
        uint _amount,
        uint _lockedUntil
    ) internal {
        uint i = _requests.length;
        _requests.push(WithdrawalRequest(0, 0, 1));
        // Keep it sorted so that the first to get unlocked request is always at the end
        for (; i > 0 && _requests[i - 1].lockedUntil <= _lockedUntil; --i) {
            _requests[i] = _requests[i - 1];
        }
        _requests[i] = WithdrawalRequest(_amount, _lockedUntil.toUint128(), 1);
        _user.pendingWithdrawals = _user.pendingWithdrawals.add(_amount);
    }

    /**
     * @notice Pops the requests with unlock time < now from the requests
     *   array and deducts the computed amount from the user's pending
     *   withdrawals counter. Assumes that the requests array is sorted
     *   by unclock time (descending).
     * @dev This function **removes** the eligible requests from the requests
     *   array. If this function is called, the withdrawal should actually
     *   happen (or the transaction should be reverted).
     * @param _user The user struct storage pointer
     * @param _requests The user's requests array storage pointer
     * @return beforeUpgradeWithdrawalAmount The amount eligible for withdrawal before upgrade (this amount should be
     *   sent to the user, otherwise the state would be inconsistent).
     * @return afterUpgradeWithdrawalAmount The amount eligible for withdrawal after upgrade (this amount should be
     *   sent to the user, otherwise the state would be inconsistent).
     */
    function popEligibleWithdrawalRequests(
        UserInfo storage _user,
        WithdrawalRequest[] storage _requests
    ) internal returns (uint beforeUpgradeWithdrawalAmount, uint afterUpgradeWithdrawalAmount) {
        // Since the requests are sorted by their unlock time, we can just
        // pop them from the array and stop at the first not-yet-eligible one
        for (uint i = _requests.length; i > 0 && isUnlocked(_requests[i - 1]); --i) {
            if (_requests[i - 1].afterUpgrade == 1) {
                afterUpgradeWithdrawalAmount = afterUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            } else {
                beforeUpgradeWithdrawalAmount = beforeUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            }

            _requests.pop();
        }
        _user.pendingWithdrawals = _user.pendingWithdrawals.sub(
            afterUpgradeWithdrawalAmount.add(beforeUpgradeWithdrawalAmount)
        );
        return (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount);
    }

    /**
     * @notice Checks if the request is eligible for withdrawal.
     * @param _request The request struct storage pointer
     * @return True if the request is eligible for withdrawal, false otherwise
     */
    function isUnlocked(WithdrawalRequest storage _request) private view returns (bool) {
        return _request.lockedUntil <= block.timestamp;
    }

    /**
     * @notice Execute withdrawal to XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     */
    function executeWithdrawal(address _rewardToken, uint256 _pid) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][msg.sender];

        uint256 beforeUpgradeWithdrawalAmount;
        uint256 afterUpgradeWithdrawalAmount;

        (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount) = popEligibleWithdrawalRequests(user, requests);
        require(beforeUpgradeWithdrawalAmount > 0 || afterUpgradeWithdrawalAmount > 0, "nothing to withdraw");

        // Having both old-style and new-style requests is not allowed and shouldn't be possible
        require(beforeUpgradeWithdrawalAmount == 0 || afterUpgradeWithdrawalAmount == 0, "inconsistent state");

        if (beforeUpgradeWithdrawalAmount > 0) {
            _updatePool(_rewardToken, _pid);
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            XVSStore(xvsStore).safeRewardTransfer(_rewardToken, msg.sender, pending);
            user.amount = user.amount.sub(beforeUpgradeWithdrawalAmount);
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
            pool.token.safeTransfer(address(msg.sender), beforeUpgradeWithdrawalAmount);
        } else {
            user.amount = user.amount.sub(afterUpgradeWithdrawalAmount);
            totalPendingWithdrawals[_rewardToken][_pid] = totalPendingWithdrawals[_rewardToken][_pid].sub(
                afterUpgradeWithdrawalAmount
            );
            pool.token.safeTransfer(address(msg.sender), afterUpgradeWithdrawalAmount);
        }

        emit ExecutedWithdrawal(
            msg.sender,
            _rewardToken,
            _pid,
            beforeUpgradeWithdrawalAmount.add(afterUpgradeWithdrawalAmount)
        );
    }

    /**
     * @notice Returns before and after upgrade pending withdrawal amount
     * @param _requests The user's requests array storage pointer
     * @return beforeUpgradeWithdrawalAmount The amount eligible for withdrawal before upgrade
     * @return afterUpgradeWithdrawalAmount The amount eligible for withdrawal after upgrade
     */
    function getRequestedWithdrawalAmount(
        WithdrawalRequest[] storage _requests
    ) internal view returns (uint beforeUpgradeWithdrawalAmount, uint afterUpgradeWithdrawalAmount) {
        for (uint i = _requests.length; i > 0; --i) {
            if (_requests[i - 1].afterUpgrade == 1) {
                afterUpgradeWithdrawalAmount = afterUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            } else {
                beforeUpgradeWithdrawalAmount = beforeUpgradeWithdrawalAmount.add(_requests[i - 1].amount);
            }
        }
        return (beforeUpgradeWithdrawalAmount, afterUpgradeWithdrawalAmount);
    }

    /**
     * @notice Request withdrawal to XVSVault for XVS allocation
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _amount The amount to withdraw from the vault
     */
    function requestWithdrawal(address _rewardToken, uint256 _pid, uint256 _amount) external nonReentrant isActive {
        _ensureValidPool(_rewardToken, _pid);
        require(_amount > 0, "requested amount cannot be zero");
        UserInfo storage user = userInfos[_rewardToken][_pid][msg.sender];
        require(user.amount >= user.pendingWithdrawals.add(_amount), "requested amount is invalid");

        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][msg.sender];

        uint beforeUpgradeWithdrawalAmount;

        (beforeUpgradeWithdrawalAmount, ) = getRequestedWithdrawalAmount(requests);
        require(beforeUpgradeWithdrawalAmount == 0, "execute pending withdrawal");

        _updatePool(_rewardToken, _pid);
        uint256 pending = _computeReward(user, pool);
        _transferReward(_rewardToken, msg.sender, pending);

        uint lockedUntil = pool.lockPeriod.add(block.timestamp);

        pushWithdrawalRequest(user, requests, _amount, lockedUntil);
        totalPendingWithdrawals[_rewardToken][_pid] = totalPendingWithdrawals[_rewardToken][_pid].add(_amount);
        user.rewardDebt = _cumulativeReward(user, pool);

        // Update Delegate Amount
        if (address(pool.token) == xvsAddress) {
            _moveDelegates(
                delegates[msg.sender],
                address(0),
                safe96(_amount, "XVSVault::requestWithdrawal: votes overflow")
            );
        }

        if (primeRewardToken == _rewardToken && _pid == primePoolId) {
            primeToken.xvsUpdated(msg.sender);
        }

        emit Claim(msg.sender, _rewardToken, _pid, pending);
        emit RequestedWithdrawal(msg.sender, _rewardToken, _pid, _amount);
    }

    /**
     * @notice Get unlocked withdrawal amount
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return withdrawalAmount Amount that the user can withdraw
     */
    function getEligibleWithdrawalAmount(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (uint withdrawalAmount) {
        _ensureValidPool(_rewardToken, _pid);
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        // Since the requests are sorted by their unlock time, we can take
        // the entries from the end of the array and stop at the first
        // not-yet-eligible one
        for (uint i = requests.length; i > 0 && isUnlocked(requests[i - 1]); --i) {
            withdrawalAmount = withdrawalAmount.add(requests[i - 1].amount);
        }
        return withdrawalAmount;
    }

    /**
     * @notice Get requested amount
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return Total amount of requested but not yet executed withdrawals (including both executable and locked ones)
     */
    function getRequestedAmount(address _rewardToken, uint256 _pid, address _user) external view returns (uint256) {
        _ensureValidPool(_rewardToken, _pid);
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        return user.pendingWithdrawals;
    }

    /**
     * @notice Returns the array of withdrawal requests that have not been executed yet
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The User Address
     * @return An array of withdrawal requests
     */
    function getWithdrawalRequests(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (WithdrawalRequest[] memory) {
        _ensureValidPool(_rewardToken, _pid);
        return withdrawalRequests[_rewardToken][_pid][_user];
    }

    /**
     * @notice View function to see pending XVSs on frontend
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _user User address
     * @return Reward the user is eligible for in this pool, in terms of _rewardToken
     */
    function pendingReward(address _rewardToken, uint256 _pid, address _user) external view returns (uint256) {
        _ensureValidPool(_rewardToken, _pid);
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 supply = pool.token.balanceOf(address(this)).sub(totalPendingWithdrawals[_rewardToken][_pid]);
        uint256 curBlockNumberOrSecond = getBlockNumberOrTimestamp();
        uint256 rewardTokenPerBlockOrSecond = rewardTokenAmountsPerBlockOrSecond[_rewardToken];
        if (curBlockNumberOrSecond > pool.lastRewardBlockOrSecond && supply != 0) {
            uint256 multiplier = curBlockNumberOrSecond.sub(pool.lastRewardBlockOrSecond);
            uint256 reward = multiplier.mul(rewardTokenPerBlockOrSecond).mul(pool.allocPoint).div(
                totalAllocPoints[_rewardToken]
            );
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        (, uint256 afterUpgradeWithdrawalAmount) = getRequestedWithdrawalAmount(requests);
        return user.amount.sub(afterUpgradeWithdrawalAmount).mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools(address _rewardToken) internal {
        uint256 length = poolInfos[_rewardToken].length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(_rewardToken, pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     */
    function updatePool(address _rewardToken, uint256 _pid) external isActive {
        _ensureValidPool(_rewardToken, _pid);
        _updatePool(_rewardToken, _pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(address _rewardToken, uint256 _pid) internal {
        PoolInfo storage pool = poolInfos[_rewardToken][_pid];
        if (getBlockNumberOrTimestamp() <= pool.lastRewardBlockOrSecond) {
            return;
        }
        uint256 supply = pool.token.balanceOf(address(this));
        supply = supply.sub(totalPendingWithdrawals[_rewardToken][_pid]);
        if (supply == 0) {
            pool.lastRewardBlockOrSecond = getBlockNumberOrTimestamp();
            return;
        }
        uint256 curBlockNumberOrSecond = getBlockNumberOrTimestamp();
        uint256 multiplier = curBlockNumberOrSecond.sub(pool.lastRewardBlockOrSecond);
        uint256 reward = multiplier.mul(rewardTokenAmountsPerBlockOrSecond[_rewardToken]).mul(pool.allocPoint).div(
            totalAllocPoints[_rewardToken]
        );
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(supply));
        pool.lastRewardBlockOrSecond = getBlockNumberOrTimestamp();
    }

    function _ensureValidPool(address rewardToken, uint256 pid) internal view {
        require(pid < poolInfos[rewardToken].length, "vault: pool exists?");
    }

    /**
     * @notice Get user info with reward token address and pid
     * @param _rewardToken Reward token address
     * @param _pid Pool index
     * @param _user User address
     * @return amount Deposited amount
     * @return rewardDebt Reward debt (technical value used to track past payouts)
     * @return pendingWithdrawals Requested but not yet executed withdrawals
     */
    function getUserInfo(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (uint256 amount, uint256 rewardDebt, uint256 pendingWithdrawals) {
        _ensureValidPool(_rewardToken, _pid);
        UserInfo storage user = userInfos[_rewardToken][_pid][_user];
        amount = user.amount;
        rewardDebt = user.rewardDebt;
        pendingWithdrawals = user.pendingWithdrawals;
    }

    /**
     * @notice Gets the total pending withdrawal amount of a user before upgrade
     * @param _rewardToken The Reward Token Address
     * @param _pid The Pool Index
     * @param _user The address of the user
     * @return beforeUpgradeWithdrawalAmount Total pending withdrawal amount in requests made before the vault upgrade
     */
    function pendingWithdrawalsBeforeUpgrade(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) public view returns (uint256 beforeUpgradeWithdrawalAmount) {
        WithdrawalRequest[] storage requests = withdrawalRequests[_rewardToken][_pid][_user];
        (beforeUpgradeWithdrawalAmount, ) = getRequestedWithdrawalAmount(requests);
        return beforeUpgradeWithdrawalAmount;
    }

    /**
     * @notice Get the XVS stake balance of an account (excluding the pending withdrawals)
     * @param account The address of the account to check
     * @return The balance that user staked
     */
    function getStakeAmount(address account) internal view returns (uint96) {
        require(xvsAddress != address(0), "XVSVault::getStakeAmount: xvs address is not set");

        PoolInfo[] storage poolInfo = poolInfos[xvsAddress];

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (address(poolInfo[pid].token) == address(xvsAddress)) {
                UserInfo storage user = userInfos[xvsAddress][pid][account];
                return safe96(user.amount.sub(user.pendingWithdrawals), "XVSVault::getStakeAmount: votes overflow");
            }
        }
        return uint96(0);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external isActive {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isActive {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("XVSVault")), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ECDSA.recover(digest, v, r, s);
        require(nonce == nonces[signatory]++, "XVSVault::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "XVSVault::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = getStakeAmount(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChangedV2(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "XVSVault::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "XVSVault::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumberOrSecond = safe32(
            getBlockNumberOrTimestamp(),
            "XVSVault::_writeCheckpoint: block number or second exceeds 32 bits"
        );

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlockOrSecond == blockNumberOrSecond) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumberOrSecond, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChangedV2(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2 ** 96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /**
     * @notice Determine the xvs stake balance for an account
     * @param account The address of the account to check
     * @param blockNumberOrSecond The block number or second to get the vote balance at
     * @return The balance that user staked
     */
    function getPriorVotes(address account, uint256 blockNumberOrSecond) external view returns (uint96) {
        require(blockNumberOrSecond < getBlockNumberOrTimestamp(), "XVSVault::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlockOrSecond <= blockNumberOrSecond) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlockOrSecond > blockNumberOrSecond) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlockOrSecond == blockNumberOrSecond) {
                return cp.votes;
            } else if (cp.fromBlockOrSecond < blockNumberOrSecond) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /*** Admin Functions ***/

    function _become(XVSVaultProxy xvsVaultProxy) external {
        require(msg.sender == xvsVaultProxy.admin(), "only proxy admin can change brains");
        require(xvsVaultProxy._acceptImplementation() == 0, "change not authorized");
    }

    function setXvsStore(address _xvs, address _xvsStore) external onlyAdmin {
        _ensureNonzeroAddress(_xvs);
        _ensureNonzeroAddress(_xvsStore);

        address oldXvsContract = xvsAddress;
        address oldStore = xvsStore;
        require(oldXvsContract == address(0), "already initialized");

        xvsAddress = _xvs;
        xvsStore = _xvsStore;

        _notEntered = true;

        emit StoreUpdated(oldXvsContract, oldStore, _xvs, _xvsStore);
    }

    /**
     * @notice Sets the address of the prime token contract
     * @param _primeToken address of the prime token contract
     * @param _primeRewardToken address of reward token
     * @param _primePoolId pool id for reward
     */
    function setPrimeToken(IPrime _primeToken, address _primeRewardToken, uint256 _primePoolId) external onlyAdmin {
        require(address(_primeToken) != address(0), "prime token cannot be zero address");
        require(_primeRewardToken != address(0), "reward cannot be zero address");

        _ensureValidPool(_primeRewardToken, _primePoolId);

        emit NewPrimeToken(primeToken, _primeToken, primeRewardToken, _primeRewardToken, primePoolId, _primePoolId);

        primeToken = _primeToken;
        primeRewardToken = _primeRewardToken;
        primePoolId = _primePoolId;
    }

    /**
     * @dev Initializes the contract to use either blocks or seconds
     * @param timeBased_ A boolean indicating whether the contract is based on time or block
     * If timeBased is true than blocksPerYear_ param is ignored as blocksOrSecondsPerYear is set to SECONDS_PER_YEAR
     * @param blocksPerYear_ The number of blocks per year
     */
    function initializeTimeManager(bool timeBased_, uint256 blocksPerYear_) external onlyAdmin {
        _initializeTimeManager(timeBased_, blocksPerYear_);
    }

    /**
     * @notice Sets the address of the access control of this contract
     * @dev Admin function to set the access control address
     * @param newAccessControlAddress New address for the access control
     */
    function setAccessControl(address newAccessControlAddress) external onlyAdmin {
        _setAccessControlManager(newAccessControlAddress);
    }

    /**
     * @dev Reverts if the provided address is a zero address
     * @param address_ Address to check
     */
    function _ensureNonzeroAddress(address address_) internal pure {
        require(address_ != address(0), "zero address not allowed");
    }

    /**
     * @dev Transfers the reward to the user, taking into account the rewards store
     *   balance and the previous debt. If there are not enough rewards in the store,
     *   transfers the available funds and records the debt amount in pendingRewardTransfers.
     * @param rewardToken Reward token address
     * @param userAddress User address
     * @param amount Reward amount, in reward tokens
     */
    function _transferReward(address rewardToken, address userAddress, uint256 amount) internal {
        address xvsStore_ = xvsStore;
        uint256 storeBalance = IBEP20(rewardToken).balanceOf(xvsStore_);
        uint256 debtDueToFailedTransfers = pendingRewardTransfers[rewardToken][userAddress];
        uint256 fullAmount = amount.add(debtDueToFailedTransfers);

        if (fullAmount <= storeBalance) {
            if (debtDueToFailedTransfers != 0) {
                pendingRewardTransfers[rewardToken][userAddress] = 0;
                emit VaultDebtUpdated(rewardToken, userAddress, debtDueToFailedTransfers, 0);
            }
            XVSStore(xvsStore_).safeRewardTransfer(rewardToken, userAddress, fullAmount);
            return;
        }
        // Overflow isn't possible due to the check above
        uint256 newOwedAmount = fullAmount - storeBalance;
        pendingRewardTransfers[rewardToken][userAddress] = newOwedAmount;
        emit VaultDebtUpdated(rewardToken, userAddress, debtDueToFailedTransfers, newOwedAmount);
        XVSStore(xvsStore_).safeRewardTransfer(rewardToken, userAddress, storeBalance);
    }

    /**
     * @dev Computes cumulative reward for all user's shares
     * @param user UserInfo storage struct
     * @param pool PoolInfo storage struct
     */
    function _cumulativeReward(UserInfo storage user, PoolInfo storage pool) internal view returns (uint256) {
        return user.amount.sub(user.pendingWithdrawals).mul(pool.accRewardPerShare).div(1e12);
    }

    /**
     * @dev Computes the reward for all user's shares
     * @param user UserInfo storage struct
     * @param pool PoolInfo storage struct
     */
    function _computeReward(UserInfo storage user, PoolInfo storage pool) internal view returns (uint256) {
        return _cumulativeReward(user, pool).sub(user.rewardDebt);
    }
}

pragma solidity ^0.5.16;

contract XVSVaultErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./XVSVaultStorage.sol";
import "./XVSVaultErrorReporter.sol";

/**
 * @title XVS Vault Proxy
 * @author Venus
 * @notice XVS Vault Proxy contract
 */
contract XVSVaultProxy is XVSVaultAdminStorage, XVSVaultErrorReporter {
    /**
     * @notice Emitted when pendingXVSVaultImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingXVSVaultImplementation is accepted, which means XVS Vault implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingXVSVaultImplementation;

        pendingXVSVaultImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingXVSVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts new implementation of XVS Vault. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation
        if (msg.sender != pendingXVSVaultImplementation) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingXVSVaultImplementation;

        implementation = pendingXVSVaultImplementation;

        pendingXVSVaultImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingXVSVaultImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize)
            }
            default {
                return(free_mem_ptr, returndatasize)
            }
        }
    }
}

pragma solidity ^0.5.16;

import "../Utils/SafeMath.sol";
import "../Utils/IBEP20.sol";
import "../Tokens/Prime/IPrime.sol";

contract XVSVaultAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of XVS Vault
     */
    address public implementation;

    /**
     * @notice Pending brains of XVS Vault
     */
    address public pendingXVSVaultImplementation;
}

contract XVSVaultStorageV1 is XVSVaultAdminStorage {
    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;

    /// @notice The reward token store
    address public xvsStore;

    /// @notice The xvs token address
    address public xvsAddress;

    // Reward tokens created per block or second indentified by reward token address.
    mapping(address => uint256) public rewardTokenAmountsPerBlockOrSecond;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingWithdrawals;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 token; // Address of token contract to stake.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlockOrSecond; // Last block number or second that reward tokens distribution occurs.
        uint256 accRewardPerShare; // Accumulated per share, times 1e12. See below.
        uint256 lockPeriod; // Min time between withdrawal request and its execution.
    }

    // Infomation about a withdrawal request
    struct WithdrawalRequest {
        uint256 amount;
        uint128 lockedUntil;
        uint128 afterUpgrade;
    }

    // Info of each user that stakes tokens.
    mapping(address => mapping(uint256 => mapping(address => UserInfo))) internal userInfos;

    // Info of each pool.
    mapping(address => PoolInfo[]) public poolInfos;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    mapping(address => uint256) public totalAllocPoints;

    // Info of requested but not yet executed withdrawals
    mapping(address => mapping(uint256 => mapping(address => WithdrawalRequest[]))) internal withdrawalRequests;

    /// @notice DEPRECATED A record of each accounts delegate (before the voting power fix)
    mapping(address => address) private __oldDelegatesSlot;

    /// @notice A checkpoint for marking number of votes from a given block or second
    struct Checkpoint {
        uint32 fromBlockOrSecond;
        uint96 votes;
    }

    /// @notice DEPRECATED A record of votes checkpoints for each account, by index (before the voting power fix)
    mapping(address => mapping(uint32 => Checkpoint)) private __oldCheckpointsSlot;

    /// @notice DEPRECATED The number of checkpoints for each account (before the voting power fix)
    mapping(address => uint32) private __oldNumCheckpointsSlot;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
}

contract XVSVaultStorage is XVSVaultStorageV1 {
    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice Tracks pending withdrawals for all users for a particular reward token and pool id
    mapping(address => mapping(uint256 => uint256)) public totalPendingWithdrawals;

    /// @notice pause indicator for Vault
    bool public vaultPaused;

    /// @notice if the token is added to any of the pools
    mapping(address => bool) public isStakedToken;

    /// @notice Amount we owe to users because of failed transfer attempts
    mapping(address => mapping(address => uint256)) public pendingRewardTransfers;

    /// @notice Prime token contract address
    IPrime public primeToken;

    /// @notice Reward token for which prime token is issued for staking
    address public primeRewardToken;

    /// @notice Pool ID for which prime token is issued for staking
    uint256 public primePoolId;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}