// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {AccountRails} from "../../cores/account/AccountRails.sol";
import {Account} from "../../cores/account/Account.sol";
import {IEntryPoint} from "../../lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "../../lib/ERC4337/utils/UserOperation.sol";
import {ValidatorsStorage} from "../../validator/ValidatorsStorage.sol";
import {Initializable} from "../../lib/initializable/Initializable.sol";
import {Access} from "../../access/Access.sol";
import {IPermissions} from "../../access/permissions/interface/IPermissions.sol";
import {Extensions} from "../../extension/Extensions.sol";
import {Operations} from "../../lib/Operations.sol";
import {ERC6551AccountLib} from "../../lib/ERC6551/lib/ERC6551AccountLib.sol";
import {IERC721} from "../ERC721/interface/IERC721.sol";
import {IERC721AccountRails} from "./interface/IERC721AccountRails.sol";
import {ERC6551Account, IERC6551Account} from "../../lib/ERC6551/ERC6551Account.sol";
import {ERC6551AccountStorage} from "../../lib/ERC6551/ERC6551AccountStorage.sol";
import {IERC6551AccountGroup} from "../../lib/ERC6551AccountGroup/interface/IERC6551AccountGroup.sol";

/// @notice An ERC-4337 Account bound to an ERC-721 token via ERC-6551
contract ERC721AccountRails is AccountRails, ERC6551Account, Initializable, IERC721AccountRails {
    /*====================
        INITIALIZATION
    ====================*/

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    constructor(address _entryPointAddress) Account(_entryPointAddress) Initializable() {}

    /// @inheritdoc IERC721AccountRails
    /// @notice Important that it is assumed the caller of this function is trusted by the Account Group
    function initialize(bytes memory initData) external initializer {
        if (initData.length > 0) {
            // make msg.sender an ADMIN to ensure they have all permissions for further initialization
            _addPermission(Operations.ADMIN, msg.sender);
            Address.functionDelegateCall(address(this), initData);
            // remove sender ADMIN permissions
            _removePermission(Operations.ADMIN, msg.sender);
        }
    }

    receive() external payable override(Extensions, IERC6551Account) {}

    /*==============
        METADATA
    ==============*/

    /// @inheritdoc AccountRails
    function supportsInterface(bytes4 interfaceId) public view override(AccountRails, ERC6551Account) returns (bool) {
        return AccountRails.supportsInterface(interfaceId) || ERC6551Account.supportsInterface(interfaceId);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @inheritdoc Account
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual override {
        if (!_isAuthorized(Operations.ADMIN, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.ADMIN, msg.sender);
        }

        _updateState();
        IEntryPoint(entryPoint).withdrawTo(recipient, amount);
    }

    function _checkSenderIsEntryPoint() internal virtual override {
        _updateState();
        super._checkSenderIsEntryPoint();
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultValidateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 /*missingAccountFunds*/ )
        internal
        view
        virtual
        override
        returns (bool)
    {
        // recover signer address and any error
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(userOpHash, userOp.signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;

        // return true only if signer is owner, owner-delegated, or AccountGroup admin
        return _isAuthorized(Operations.ADMIN, signer);
    }

    /// @dev When evaluating signatures that don't contain the `VALIDATOR_FLAG`, authenticate only the owner
    function _defaultIsValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // support non-modular signatures by recovering signer address and reverting malleable or invalid signatures
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
        // return if signature is malformed
        if (err != ECDSA.RecoverError.NoError) return false;

        // return true only if signer is owner, owner-delegated, or AccountGroup admin
        return _isAuthorized(Operations.ADMIN, signer);
    }

    function _isValidSigner(address signer, bytes memory) internal view override returns (bool) {
        return hasPermission(Operations.CALL, signer);
    }

    function _updateState() internal virtual override {
        ERC6551AccountStorage.layout().state++;
    }

    /// @dev According to ERC6551, functions that modify state must alter the `uint256 state` variable
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        override
        returns (address guard, bytes memory checkBeforeData)
    {
        _updateState();
        super._beforeExecuteCall(to, value, data);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    function owner() public view override returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();
        return _tokenOwner(chainId, tokenContract, tokenId);
    }

    function _tokenOwner(uint256 chainId, address tokenContract, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        if (chainId != block.chainid) return address(0);
        if (tokenContract.code.length == 0) return address(0);

        try IERC721(tokenContract).ownerOf(tokenId) returns (address _owner) {
            return _owner;
        } catch {
            return address(0);
        }
    }

    /// @dev Sensitive account operations restricted to three tiered authorization hierarchy:
    ///   TBA owner || TBA permission || AccountGroup admin
    /// This provides owner autonomy, owner-delegated permissions, and multichain AccountGroup management
    function _isAuthorized(bytes8 _operation, address _sender) internal view returns (bool) {
        // check sender is TBA owner or has been granted relevant permission (or admin) on this account
        if (hasPermission(_operation, _sender)) return true;

        // allow AccountGroup admins to manage accounts on non-origin chains
        return _isAccountGroupAdmin(_sender);
    }

    /// @dev On non-origin chains, `owner()` returns the zero address, so multichain upgrades
    /// are enabled by permitting trusted AccountGroup admins
    function _isAccountGroupAdmin(address _sender) internal view returns (bool) {
        // fetch GroupAccount from contract bytecode
        bytes32 bytecodeSalt = ERC6551AccountLib.salt(address(this));
        address accountGroup = address(bytes20(bytecodeSalt));

        return IPermissions(accountGroup).hasPermission(Operations.ADMIN, _sender);
    }

    function _checkCanUpdateValidators() internal virtual override {
        _updateState();
        if (!_isAuthorized(Operations.VALIDATOR, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.VALIDATOR, msg.sender);
        }
    }

    function _checkCanUpdatePermissions() internal override {
        _updateState();
        if (!_isAuthorized(Operations.PERMISSIONS, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.PERMISSIONS, msg.sender);
        }
    }

    function _checkCanUpdateGuards() internal override {
        _updateState();
        if (!_isAuthorized(Operations.GUARDS, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.GUARDS, msg.sender);
        }
    }

    function _checkCanUpdateInterfaces() internal override {
        _updateState();
        if (!_isAuthorized(Operations.INTERFACE, msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.INTERFACE, msg.sender);
        }
    }

    /// @dev Changes to extensions restricted to TBA owner or AccountGroupAdmin to prevent mutiny
    function _checkCanUpdateExtensions() internal override {
        _updateState();

        // revert if sender is neither owner nor AccountGroup admin, exclude permissions on this account
        (uint256 chainId,,) = ERC6551AccountLib.token();
        if (chainId == block.chainid) {
            require(msg.sender == owner(), "NOT_OWNER");
        } else if (!_isAccountGroupAdmin(msg.sender)) {
            revert IPermissions.PermissionDoesNotExist(Operations.ADMIN, msg.sender);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        // fetch GroupAccount from contract bytecode in the context of delegatecall
        bytes32 bytecodeSalt = ERC6551AccountLib.salt(address(this));
        address accountGroup = address(bytes20(bytecodeSalt));

        _updateState();
        IERC6551AccountGroup(accountGroup).checkValidAccountUpgrade(msg.sender, address(this), newImplementation);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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
        }
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.13;

import {Rails} from "../../Rails.sol";
import {Account} from "../../cores/account/Account.sol";
import {IAccount} from "../../lib/ERC4337/interface/IAccount.sol";
import {IEntryPoint} from "../../lib/ERC4337/interface/IEntryPoint.sol";
import {UserOperation} from "../../lib/ERC4337/utils/UserOperation.sol";
import {Validators} from "../../validator/Validators.sol";
import {IValidator} from "../../validator/interface/IValidator.sol";
import {Operations} from "../../lib/Operations.sol";
import {Access} from "../../access/Access.sol";
import {SupportsInterface} from "../../lib/ERC165/SupportsInterface.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {ERC1155Receiver} from "openzeppelin-contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {IERC1155Receiver} from "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title Station Network Account Abstract Contract
/// @author 👦🏻👦🏻.eth

/// @dev This abstract contract provides scaffolding for Station's Account signature validation
/// ERC1271 and ERC4337 compliance in combination with Rails's Permissions system
/// to provide convenient and modular private key management on an infrastructural level
abstract contract AccountRails is Account, Rails, Validators, IERC1271 {
    /*=============
        ACCOUNT
    ==============*/

    /// @dev Function enabling EIP-4337 compliance as a smart contract wallet account
    /// @param userOp The UserOperation to validate before executing
    /// @param userOpHash Hash of the UserOperation data, used as signature digest
    /// @param missingAccountFunds Delta representing this account's missing funds in the EntryPoint contract
    /// Corresponds to minimum native currency that must be transferred to the EntryPoint to complete execution
    /// Can be 0 if this account has already deposited enough funds or if a paymaster is used
    /// @notice To craft the signature, string concatenation or `abi.encodePacked` *must* be used
    /// Zero-padded data will fail. Ie: `abi.encodePacked(validatorData, signer, currentRSV)` is correct
    /**
     *   @return validationData A packed uint256 of three concatenated variables
     *   ie: `uint256(abi.encodePacked(address authorizor, uint48 validUntil, uint48 validAfter))`
     *   where `authorizer` can be one of the following:
     *       1. A signature aggregator contract, inheriting IAggregator.sol, to use for validation
     *       2. An exit status code `bytes20(0x01)` representing signature validation failure
     *       3. An empty `bytes20(0x0)` representing successful signature validation
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        public
        virtual
        returns (uint256 validationData)
    {
        // only EntryPoint should call this function to prevent frontrunning of valid signatures
        _checkSenderIsEntryPoint();

        bytes32 ethSignedUserOpHash = ECDSA.toEthSignedMessageHash(userOpHash);

        // extract validator address using cheap calldata slicing before decoding
        bytes8 flag = bytes8(userOp.signature[:8]);
        address validator = address(bytes20(userOp.signature[12:32]));

        if (flag == VALIDATOR_FLAG && isValidator(validator)) {
            bytes memory formattedSig = userOp.signature[32:];

            // copy userOp into memory and format for Validator module
            UserOperation memory formattedUserOp = userOp;
            formattedUserOp.signature = formattedSig;

            uint256 ret =
                IValidator(validator).validateUserOp(formattedUserOp, ethSignedUserOpHash, missingAccountFunds);

            // if validator rejects sig, terminate early with status code 1
            if (ret != 0) return ret;
        } else {
            // support non-modular signatures by default
            // authenticate signer, terminating early with status code 1 on failure
            bool validSigner = _defaultValidateUserOp(userOp, ethSignedUserOpHash, missingAccountFunds);
            if (!validSigner) return 1;
        }

        /// @notice BLS sig aggregator and timestamp expiry are not currently supported by this contract
        /// so `bytes20(0x0)` and `bytes6(0x0)` suffice. To enable support for aggregator and timestamp expiry,
        /// override the following params
        bytes20 authorizer;
        bytes6 validUntil;
        bytes6 validAfter;

        validationData = uint256(bytes32(abi.encodePacked(authorizer, validUntil, validAfter)));

        /// @notice nonce collision is managed entirely by the EntryPoint, but validation hook optionality
        /// for child contracts is provided here as `_checkNonce()` may be overridden
        _checkNonce();

        // check fee payment
        if (missingAccountFunds != 0) {
            _preFund(missingAccountFunds);
        }
    }

    /// @dev Function to recover a signer address from the provided hash and signature
    /// and then verify whether the recovered signer address is a recognized Turnkey
    /// @param hash The 32 byte digest derived by hashing signed message data. Sadly, name is canonical in ERC1271.
    /// @param signature The signature to be verified via recovery. Must be prepended with validator address
    /// @notice To craft the signature, string concatenation or `abi.encodePacked` *must* be used
    /// Zero-padded data will fail. Ie: `abi.encodePacked(validatorData, signer, currentRSV)` is correct
    /// @return magicValue The 4-byte value representing signature validity, as defined by EIP1271
    /// Can be one of three values:
    ///   - `this.isValidSignature.selector` indicates a valid signature
    ///   - `bytes4(hex'ffffffff')` indicates a signature failure bubbled up from an external modular validator
    ///   - `bytes4(0)` indicates a default signature failure, ie not using the modular `VALIDATOR_FLAG`
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        // set start index
        uint256 start = 0x20;
        // try extracting packed validator data to check for modular validation format
        bytes32 data;
        assembly {
            data := mload(add(signature, start))
        }
        (bytes8 flag, address validator) = (bytes8(data), address(uint160(uint256(data))));

        // collision of a signature's first 8 bytes with flag is very unlikely; impossible when incl validator address
        if (flag == VALIDATOR_FLAG && isValidator(validator)) {
            uint256 len = signature.length - start;
            bytes memory formattedSig = new bytes(len);

            // copy relevant data into new bytes array, ie `abi.encodePacked(signer, nestedSig)`
            for (uint256 i; i < len; ++i) {
                formattedSig[i] = signature[start + i];
            }

            // format call for Validator module
            bytes4 ret = IValidator(validator).isValidSignature(hash, formattedSig);

            // validator will return either correct `magicValue` or error code `INVALID_SIGNER`
            magicValue = ret;
        } else {
            // support non-modular signatures by default
            // authenticate signer using overridden internal func
            bool validSigner = _defaultIsValidSignature(hash, signature);
            // return `bytes4(0)` if default signature validation also fails
            magicValue = validSigner ? this.isValidSignature.selector : bytes4(0);
        }
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev Function to recover and authenticate a signer address in the context of `isValidSignature()`,
    /// called only on signatures that were not constructed using the modular verification flag
    /// @notice Accounts do not express opinion on whether the `signer` is encoded into `userOp.signature`,
    /// so the OZ ECDSA library should be used rather than the SignatureChecker
    function _defaultIsValidSignature(bytes32 hash, bytes memory signature) internal view virtual returns (bool);

    /// @dev Function to recover and authenticate a signer address in the context of `validateUserOp()`,
    /// called only on signatures that were not constructed using the modular verification flag
    /// @notice Accounts do not express opinion on whether the `signer` is available, ie encoded into `userOp.signature`,
    /// so the OZ ECDSA library should be used rather than the SignatureChecker
    function _defaultValidateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        internal
        view
        virtual
        returns (bool);

    /// @dev View function to limit callers to only the EntryPoint contract of this chain
    function _checkSenderIsEntryPoint() internal virtual {
        if (msg.sender != entryPoint) revert NotEntryPoint(msg.sender);
    }

    /// @dev Since nonce management and collision checks are handled entirely by the EntryPoint,
    /// this function is left empty for contracts inheriting from this one to use EntryPoint's defaults
    /// If sequential `UserOperation` nonce ordering is desired, override this, eg: `require(nonce < type(uint64).max)`
    function _checkNonce() internal view virtual {}

    /// @dev Function to pre-fund the EntryPoint contract with delta of native currency funds required for a UserOperation
    /// By default, this function only sends enough funds to complete the current context's UserOperation
    /// Override if sending custom amounts > `_missingAccountFunds` (or < if reverts are preferrable)
    function _preFund(uint256 _missingAccountFunds) internal virtual {
        (bool r,) = payable(msg.sender).call{value: _missingAccountFunds}("");
        require(r);
    }

    /*===============
        OVERRIDES
    ===============*/

    /// @dev Declare explicit ERC165 support for ERC1271 interface in addition to existing interfaces
    /// @param interfaceId The interfaceId to check for support
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Rails, Validators, ERC1155Receiver)
        returns (bool)
    {
        return (
            interfaceId == type(IERC1271).interfaceId || interfaceId == type(IAccount).interfaceId
                || interfaceId == type(IERC1155Receiver).interfaceId || Rails.supportsInterface(interfaceId)
                || Validators.supportsInterface(interfaceId)
        );
    }

    /// @dev Provides control over adding and removing recognized validator contracts
    /// only to either the owner or entities possessing `ADMIN` or `VALIDATOR` permissions
    /// @notice Can be overridden for more restrictive access if desired
    function _checkCanUpdateValidators() internal virtual override {
        _checkPermission(Operations.VALIDATOR, msg.sender);
    }

    /// @dev Provides control over Turnkey addresses to the owner only
    /// @notice Permission to `addPermission(Operations.CALL_PERMIT)`, which is the intended
    /// function call to be called by the owner for adding valid signer accounts such as Turnkeys,
    /// is restricted to only the owner
    function _checkCanUpdatePermissions() internal virtual override {
        _checkPermission(Operations.PERMISSIONS, msg.sender);
    }

    function _checkCanUpdateGuards() internal virtual override {
        _checkPermission(Operations.GUARDS, msg.sender);
    }

    /// @dev Permission to `Call::call()` via signature validation is restricted to either
    /// the EntryPoint, the owner, or entities possessing the `CALL`or `ADMIN` permissions
    /// @notice Mutiny by Turnkeys is prevented by granting them only the `CALL_PERMIT` permission
    function _checkCanExecuteCall() internal view virtual override {
        bool auth = (msg.sender == entryPoint || hasPermission(Operations.CALL, msg.sender));
        if (!auth) revert PermissionDoesNotExist(Operations.CALL, msg.sender);
    }

    /// @dev Provides control over ERC165 layout to addresses with `INTERFACE` permission
    function _checkCanUpdateInterfaces() internal virtual override {
        _checkPermission(Operations.INTERFACE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/ERC4337/interface/IAccount.sol";
import "../../lib/ERC4337/interface/IEntryPoint.sol";
import "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";
import "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev This contract provides the basic logic for implementing the IAccount interface - validateUserOp
abstract contract Account is IAccount, ERC721Holder, ERC1155Holder {
    /// @dev This chain's EntryPoint contract address
    address public immutable entryPoint;

    /// @dev 8-Byte value signaling support for modular validation schema developed by GroupOS
    /// @notice To use, prepend signatures with a 32-byte word packed with 8-byte flag and target validator address,
    /// Leaving 4 empty bytes inbetween the packed values.
    /// Ie: `bytes32 validatorData == 0xf88284b100000000 | bytes32(uint256(uint160(address(callPermitValidator))));`
    bytes8 public constant VALIDATOR_FLAG = bytes8(bytes4(keccak256("VALIDATORFLAG"))) & 0xFFFFFFFF00000000;

    /// @param _entryPointAddress The contract address for this chain's ERC-4337 EntryPoint contract
    /// Official address for the most recent EntryPoint version is `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789`
    constructor(address _entryPointAddress) {
        entryPoint = _entryPointAddress;
    }

    /// @dev View function to view the EntryPoint's deposit balance for this Account
    function getEntryPointBalance() public view returns (uint256) {
        return IEntryPoint(entryPoint).balanceOf(address(this));
    }

    /// @dev Function to pre-fund the EntryPoint contract's `depositTo()` function
    /// using payable call context + this contract's native currency balance
    function preFundEntryPoint() public payable virtual {
        // `address(this).balance` includes `msg.value`
        uint256 totalFunds = address(this).balance;
        IEntryPoint(entryPoint).depositTo{value: totalFunds}(address(this));
    }

    /// @dev Function to withdraw funds using the EntryPoint's `withdrawTo()` function
    /// @param recipient The address to receive from the EntryPoint balance
    /// @param amount The amount of funds to withdraw from the EntryPoint
    function withdrawFromEntryPoint(address payable recipient, uint256 amount) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IStakeManager} from "./IStakeManager.sol";
import {UserOperation} from "../utils/UserOperation.sol";

/// @title ERC-4337 IEntryPoint Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the EIP-4337 spec,
/// used to interface with each chain's ERC-4337 singleton EntryPoint contract
interface IEntryPoint is IStakeManager {
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external;

    function simulateValidation(UserOperation calldata userOp) external;

    function getNonce(address sender, uint192 key) external view returns (uint256 nonce);

    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        IAggregator aggregator;
        bytes signature;
    }

    error ValidationResult(ReturnInfo returnInfo, StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    error ValidationResultWithAggregation(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo
    );

    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    struct AggregatorStakeInfo {
        address actualAggregator;
        StakeInfo stakeInfo;
    }
}

/// @notice GroupOS does not make use of BLS aggregated signatures
/// This interface is required only for compiling the spec
// @todo Look into the benefits and drawbacks (if any) of supporting aggregated signatures
interface IAggregator {
    function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

    function aggregateSignatures(UserOperation[] calldata userOps)
        external
        view
        returns (bytes memory aggregatesSignature);

    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ValidatorsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Validators")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x501077102342bdb85f23d25bb36efd0f86b07c38e46b63bec983266db4374200;

    struct Layout {
        address[] _validators;
        mapping(address => ValidatorData) _validatorData;
    }

    struct ValidatorData {
        uint24 index;
        bool exists;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IInitializable} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializable {
    /*===========
        LOCK
    ===========*/

    /// @dev Logic implementation contract disables `initialize()` from being called
    /// to prevent privilege escalation and 'exploding kitten' attacks
    /// @notice This applies to all child contracts inheriting from this one and use its constructor
    constructor() {
        _disableInitializers();
    }

    function _disableInitializers() internal virtual {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();

        if (layout._initializing) {
            revert AlreadyInitialized();
        }
        if (layout._initialized == false) {
            layout._initialized = true;
            emit Initialized();
        }
    }

    /*===============
        MODIFIERS
    ===============*/

    modifier initializer() {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        if (layout._initialized) {
            revert AlreadyInitialized();
        }
        layout._initializing = true;

        _;

        layout._initializing = false;
        layout._initialized = true;
        emit Initialized();
    }

    modifier onlyInitializing() {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        if (!layout._initializing) {
            revert NotInitializing();
        }

        _;
    }

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IInitializable
    function initialized() public view returns (bool) {
        InitializableStorage.Layout storage layout = InitializableStorage.layout();
        return layout._initialized;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Permissions} from "./permissions/Permissions.sol";
import {PermissionsStorage} from "./permissions/PermissionsStorage.sol";
import {Operations} from "../lib/Operations.sol";

abstract contract Access is Permissions {
    /// @dev Supports multiple owner implementations, e.g. explicit storage vs NFT-owner (ERC-6551)
    function owner() public view virtual returns (address);

    /// @dev Function to check one of 3 permissions criterion is true: owner, admin, or explicit permission
    /// @param operation The explicit permission to check permission for
    /// @param account The account address whose permission will be checked
    /// @return _ Boolean value declaring whether or not the address possesses permission for the operation
    function hasPermission(bytes8 operation, address account) public view override returns (bool) {
        // 3 tiers: has operation permission, has admin permission, or is owner
        if (super.hasPermission(operation, account)) {
            return true;
        }
        if (operation != Operations.ADMIN && super.hasPermission(Operations.ADMIN, account)) {
            return true;
        }
        return account == owner();
    }

    /// @inheritdoc Permissions
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PermissionsStorage} from "../PermissionsStorage.sol";

interface IPermissions {
    struct Permission {
        bytes8 operation;
        address account;
        uint40 updatedAt;
    }

    // events
    event PermissionAdded(bytes8 indexed operation, address indexed account);
    event PermissionRemoved(bytes8 indexed operation, address indexed account);

    // errors
    error PermissionAlreadyExists(bytes8 operation, address account);
    error PermissionDoesNotExist(bytes8 operation, address account);

    /// @dev Function to hash an operation's `name` and typecast it to 8-bytes
    function hashOperation(string memory name) external view returns (bytes8);

    /// @dev Function to check that an address retains the permission for an operation
    /// @param operation An 8-byte value derived by hashing the operation name and typecasting to bytes8
    /// @param account The address to query against storage for permission
    function hasPermission(bytes8 operation, address account) external view returns (bool);

    /// @dev Function to get an array of all existing Permission structs.
    function getAllPermissions() external view returns (Permission[] memory permissions);

    /// @dev Function to add permission for an address to carry out an operation
    /// @param operation The operation to permit
    /// @param account The account address to be granted permission for the operation
    function addPermission(bytes8 operation, address account) external;

    /// @dev Function to remove permission for an address to carry out an operation
    /// @param operation The operation to restrict
    /// @param account The account address whose permission to remove
    function removePermission(bytes8 operation, address account) external;

    /// @dev Function to provide reverts when checks for `hasPermission()` fails
    /// @param operation The operation to check
    /// @param account The account address whose permission to check
    function checkPermission(bytes8 operation, address account) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtensions} from "./interface/IExtensions.sol";
import {IExtension} from "./interface/IExtension.sol";
import {ExtensionsStorage} from "./ExtensionsStorage.sol";
import {Contract} from "../lib/Contract.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Extensions - A contract for managing contract extensions via function delegation
/// @notice This abstract contract provides functionality for extending function selectors using external contracts.
abstract contract Extensions is IExtensions {
    /*==================
        CALL ROUTING
    ==================*/

    /// @dev Fallback function to delegate calls to extension contracts.
    /// @param '' The data from which `msg.sig` and `msg.data` are grabbed to craft a delegatecall
    /// @return '' The return data from using delegatecall on the extension contract.
    fallback(bytes calldata) external payable virtual returns (bytes memory) {
        // Obtain the implementation address for the function selector.
        address implementation = extensionOf(msg.sig);
        // Delegate the call to the extension contract.
        return Address.functionDelegateCall(implementation, msg.data); // library checks for target contract existence
    }

    receive() external payable virtual {}

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IExtensions
    function hasExtended(bytes4 selector) public view virtual override returns (bool) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation != address(0);
    }

    /// @inheritdoc IExtensions
    function extensionOf(bytes4 selector) public view virtual returns (address implementation) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        return layout._extensions[selector].implementation;
    }

    /// @inheritdoc IExtensions
    function getAllExtensions() public view virtual returns (Extension[] memory extensions) {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        uint256 len = layout._selectors.length;
        extensions = new Extension[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = layout._selectors[i];
            ExtensionsStorage.ExtensionData memory extension = layout._extensions[selector];
            extensions[i] = Extension(
                selector,
                extension.implementation,
                extension.updatedAt,
                IExtension(extension.implementation).signatureOf(selector)
            );
        }
        return extensions;
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IExtensions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set an extension contract for a given selector.
    /// @param selector The function selector for which to add an extension contract.
    /// @param implementation The extension contract address containing code to extend a selector
    function setExtension(bytes4 selector, address implementation) public virtual canUpdateExtensions {
        _setExtension(selector, implementation);
    }

    /// @dev Function to remove an extension for a given selector.
    /// @param selector The function selector for which to remove its extension contract.
    function removeExtension(bytes4 selector) public virtual canUpdateExtensions {
        _removeExtension(selector);
    }

    /*===============
        INTERNALS
    ===============*/

    function _setExtension(bytes4 selector, address implementation) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        Contract._requireContract(implementation);
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        address oldImplementation = oldExtension.implementation;
        if (oldImplementation != address(0)) {
            // update existing Extension, reverting if `implementation` is unchanged
            if (implementation == oldImplementation) {
                revert ExtensionUnchanged(selector, oldImplementation, implementation);
            }

            // update only necessary struct members to save on SSTOREs
            layout._extensions[selector].updatedAt = uint40(block.timestamp);
            layout._extensions[selector].implementation = implementation;
        } else {
            // add new Extension
            // new length will be `len + 1`, so this extension has index `len`
            ExtensionsStorage.ExtensionData memory extension = ExtensionsStorage.ExtensionData(
                uint24(layout._selectors.length), uint40(block.timestamp), implementation
            );

            layout._extensions[selector] = extension;
            layout._selectors.push(selector); // set new selector at index and increment length
        }

        emit ExtensionUpdated(selector, oldImplementation, implementation);
    }

    function _removeExtension(bytes4 selector) internal {
        ExtensionsStorage.Layout storage layout = ExtensionsStorage.layout();
        ExtensionsStorage.ExtensionData memory oldExtension = layout._extensions[selector];
        if (oldExtension.implementation == address(0)) revert ExtensionDoesNotExist(selector);

        uint256 lastIndex = layout._selectors.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldExtension.index < lastIndex) {
            bytes4 lastSelector = layout._selectors[lastIndex];
            ExtensionsStorage.ExtensionData memory lastExtension = layout._extensions[lastSelector];
            lastExtension.index = oldExtension.index;
            layout._selectors[oldExtension.index] = lastSelector;
            layout._extensions[lastSelector] = lastExtension;
        }
        delete layout._extensions[selector];
        layout._selectors.pop(); // delete extension in last index and decrement length

        emit ExtensionUpdated(selector, oldExtension.implementation, address(0));
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateExtensions() {
        _checkCanUpdateExtensions();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set extensions
    /// @notice Should revert upon failure.
    function _checkCanUpdateExtensions() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Operations {
    bytes8 constant ADMIN = 0xfd45ddde6135ec42; // hashOperation("ADMIN");
    bytes8 constant MINT = 0x38381131ea27ecba; // hashOperation("MINT");
    bytes8 constant BURN = 0xf951edb3fd4a16a3; // hashOperation("BURN");
    bytes8 constant TRANSFER = 0x5cc15eb80ba37777; // hashOperation("TRANSFER");
    bytes8 constant METADATA = 0x0e5de49ee56c0bd3; // hashOperation("METADATA");
    bytes8 constant PERMISSIONS = 0x96bbcfa480f6f1a8; // hashOperation("PERMISSIONS");
    bytes8 constant GUARDS = 0x53cbed5bdabf52cc; // hashOperation("GUARDS");
    bytes8 constant VALIDATOR = 0xa95257aebefccffa; // hashOperation("VALIDATOR");
    bytes8 constant CALL = 0x706a455ca44ffc9f; // hashOperation("CALL");
    bytes8 constant INTERFACE = 0x4a9bf2931aa5eae4; // hashOperation("INTERFACE");
    bytes8 constant INITIALIZE_ACCOUNT = 0x18b11501aca1cd5e; // hashOperation("INITIALIZE_ACCOUNT");

    // TODO: deprecate and find another way versus anti-pattern
    // permits are enabling the permission, but only through set up modules/extension logic
    // e.g. someone can approve new members to mint, but cannot circumvent the module for taking payment
    bytes8 constant MINT_PERMIT = 0x0b6c53f325d325d3; // hashOperation("MINT_PERMIT");
    bytes8 constant BURN_PERMIT = 0x6801400fea7cd7c7; // hashOperation("BURN_PERMIT");
    bytes8 constant TRANSFER_PERMIT = 0xa994951607abf93b; // hashOperation("TRANSFER_PERMIT");
    bytes8 constant CALL_PERMIT = 0xc8d1733b0840734c; // hashOperation("CALL_PERMIT");
    bytes8 constant INITIALIZE_ACCOUNT_PERMIT = 0x449384b01ca84f74; // hashOperation("INITIALIZE_ACCOUNT_PERMIT");

    /// @dev Function to provide the signature string corresponding to an 8-byte operation
    /// @param name The signature string for an 8-byte operation. Empty for unrecognized operations.
    function nameOperation(bytes8 operation) public pure returns (string memory name) {
        if (operation == ADMIN) {
            return "ADMIN";
        } else if (operation == MINT) {
            return "MINT";
        } else if (operation == BURN) {
            return "BURN";
        } else if (operation == TRANSFER) {
            return "TRANSFER";
        } else if (operation == METADATA) {
            return "METADATA";
        } else if (operation == PERMISSIONS) {
            return "PERMISSIONS";
        } else if (operation == GUARDS) {
            return "GUARDS";
        } else if (operation == VALIDATOR) {
            return "VALIDATOR";
        } else if (operation == CALL) {
            return "CALL";
        } else if (operation == INTERFACE) {
            return "INTERFACE";
        } else if (operation == MINT_PERMIT) {
            return "MINT_PERMIT";
        } else if (operation == BURN_PERMIT) {
            return "BURN_PERMIT";
        } else if (operation == TRANSFER_PERMIT) {
            return "TRANSFER_PERMIT";
        } else if (operation == CALL_PERMIT) {
            return "CALL_PERMIT";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/Create2.sol";
import {ERC6551BytecodeLib} from "../ERC6551Registry.sol";

library ERC6551AccountLib {
    function computeAddress(
        address registry,
        address _implementation,
        bytes32 _salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal pure returns (address) {
        bytes32 bytecodeHash =
            keccak256(ERC6551BytecodeLib.getCreationCode(_implementation, _salt, chainId, tokenContract, tokenId));

        return Create2.computeAddress(_salt, bytecodeHash, registry);
    }

    function isERC6551Account(address account, address expectedImplementation, address registry)
        internal
        view
        returns (bool)
    {
        // invalid bytecode size
        if (account.code.length != 0xAD) return false;

        address _implementation = implementation(account);

        // implementation does not exist
        if (_implementation.code.length == 0) return false;

        // invalid implementation
        if (_implementation != expectedImplementation) return false;

        (bytes32 _salt, uint256 chainId, address tokenContract, uint256 tokenId) = context(account);

        return account == computeAddress(registry, _implementation, _salt, chainId, tokenContract, tokenId);
    }

    function implementation(address account) internal view returns (address _implementation) {
        assembly {
            // copy proxy implementation (0x14 bytes)
            extcodecopy(account, 0xC, 0xA, 0x14)
            _implementation := mload(0x00)
        }
    }

    function implementation() internal view returns (address _implementation) {
        return implementation(address(this));
    }

    function token(address account) internal view returns (uint256, address, uint256) {
        bytes memory encodedData = new bytes(0x60);

        assembly {
            // copy 0x60 bytes from end of context
            extcodecopy(account, add(encodedData, 0x20), 0x4d, 0x60)
        }

        return abi.decode(encodedData, (uint256, address, uint256));
    }

    function token() internal view returns (uint256, address, uint256) {
        return token(address(this));
    }

    function salt(address account) internal view returns (bytes32) {
        bytes memory encodedData = new bytes(0x20);

        assembly {
            // copy 0x20 bytes from beginning of context
            extcodecopy(account, add(encodedData, 0x20), 0x2d, 0x20)
        }

        return abi.decode(encodedData, (bytes32));
    }

    function salt() internal view returns (bytes32) {
        return salt(address(this));
    }

    function context(address account) internal view returns (bytes32, uint256, address, uint256) {
        bytes memory encodedData = new bytes(0x80);

        assembly {
            // copy full context (0x80 bytes)
            extcodecopy(account, add(encodedData, 0x20), 0x2D, 0x80)
        }

        return abi.decode(encodedData, (bytes32, uint256, address, uint256));
    }

    function context() internal view returns (bytes32, uint256, address, uint256) {
        return context(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721 {
    // events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // errors
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApprovalInvalidOperator();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    error MintERC2309QuantityExceedsLimit();
    error OwnershipNotInitializedForExtraData();
    error ExceedsMaxMintBatchSize(uint256 quantity);

    // ERC721 spec
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // base
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function totalBurned() external view returns (uint256);
    function numberMinted(address tokenOwner) external view returns (uint256);
    function numberBurned(address tokenOwner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice using the consistent Access layer, expose external functions for interacting with core logic
interface IERC721AccountRails {
    error ImplementationNotApproved(address implementation);

    /// @dev Initialize the ERC721AccountRails contract with the initialization data.
    /// @param initData Additional initialization data if required by the contract.
    function initialize(bytes calldata initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountLib} from "./lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "./interface/IERC6551Account.sol";
import {ERC6551AccountStorage} from "./ERC6551AccountStorage.sol";

abstract contract ERC6551Account is IERC6551Account {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC6551Account).interfaceId;
    }

    function isValidSigner(address signer, bytes calldata data) external view returns (bytes4 magicValue) {
        if (_isValidSigner(signer, data)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function token() public view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        return ERC6551AccountLib.token();
    }

    function state() public view returns (uint256) {
        return ERC6551AccountStorage.layout().state;
    }

    function _updateState() internal virtual;

    function _isValidSigner(address signer, bytes memory) internal view virtual returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library ERC6551AccountStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.ERC6551Account")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0xa0f58fa5523f3cd0666c678d77377af6b951392a937ada077eff4c3675457d00;

    struct Layout {
        uint256 state;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551AccountGroup {
    function getAccountInitializer(address account) external view returns (address initializer);
    function checkValidAccountUpgrade(address sender, address account, address implementation) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Multicall} from "openzeppelin-contracts/utils/Multicall.sol";
import {Access} from "./access/Access.sol";
import {Guards} from "./guard/Guards.sol";
import {Extensions} from "./extension/Extensions.sol";
import {SupportsInterface} from "./lib/ERC165/SupportsInterface.sol";
import {Execute} from "./lib/Execute.sol";
import {Operations} from "./lib/Operations.sol";

/**
 * A Solidity framework for creating complex and evolving onchain structures.
 * All Rails-inherited contracts receive a batteries-included contract development kit.
 */
abstract contract Rails is Access, Guards, Extensions, SupportsInterface, Execute, Multicall, UUPSUpgradeable {
    /// @dev Function to return the contractURI for child contracts inheriting this one
    /// Unimplemented to abstract away this functionality and render it opt-in
    /// @return uri The returned contractURI string
    function contractURI() public view virtual returns (string memory uri) {}

    /// @inheritdoc SupportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Access, Guards, Extensions, SupportsInterface, Execute)
        returns (bool)
    {
        return Access.supportsInterface(interfaceId) || Guards.supportsInterface(interfaceId)
            || Extensions.supportsInterface(interfaceId) || SupportsInterface.supportsInterface(interfaceId)
            || Execute.supportsInterface(interfaceId);
    }

    /// @inheritdoc Execute
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        override
        returns (address guard, bytes memory checkBeforeData)
    {
        return checkGuardBefore(Operations.CALL, abi.encode(to, value, data));
    }

    /// @inheritdoc Execute
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual
        override
    {
        checkGuardAfter(guard, checkBeforeData, executeData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UserOperation} from "../../ERC4337/utils/UserOperation.sol";

/// @title ERC-4337 IAccount Interface
/// @author Original EIP-4337 Spec Authors: https://eips.ethereum.org/EIPS/eip-4337

/// @dev Interface contract taken from the original EIP-4337 spec,
/// used to signify ERC-4337 compliance for smart account wallets inheriting from this contract
interface IAccount {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IValidators} from "./interface/IValidators.sol";
import {ValidatorsStorage} from "./ValidatorsStorage.sol";

abstract contract Validators is IValidators {
    /// @inheritdoc IValidators
    function isValidator(address validator) public view virtual returns (bool) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validatorData[validator].exists;
    }

    /// @inheritdoc IValidators
    function getAllValidators() public view returns (address[] memory validators) {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();
        return layout._validators;
    }

    /// @inheritdoc IValidators
    function addValidator(address validator) external {
        _checkCanUpdateValidators();
        _addValidator(validator);
    }

    /// @inheritdoc IValidators
    function removeValidator(address validator) external {
        _checkCanUpdateValidators();
        _removeValidator(validator);
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IValidators).interfaceId;
    }

    /*===============
        INTERNALS
    ===============*/

    function _addValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();

        // check to prevent adding duplicate addresses to `_validators` array
        if (layout._validatorData[validator].exists) {
            revert ValidatorAlreadyExists(validator);
        }

        ValidatorsStorage.ValidatorData memory data = ValidatorsStorage.ValidatorData(
            uint24(layout._validators.length),
            true // ValidatorData.exists
        );
        layout._validatorData[validator] = data;
        layout._validators.push(validator);

        emit ValidatorAdded(validator);
    }

    function _removeValidator(address validator) internal {
        ValidatorsStorage.Layout storage layout = ValidatorsStorage.layout();

        ValidatorsStorage.ValidatorData memory oldValidatorData = layout._validatorData[validator];
        // check to prevent removing 0th index address in `_validators` array
        if (!oldValidatorData.exists) {
            revert ValidatorDoesNotExist(validator);
        }

        uint256 lastIndex = layout._validators.length - 1;
        // if removing validator not at the end of the array, swap it to last in array
        if (oldValidatorData.index < lastIndex) {
            address lastValidator = layout._validators[lastIndex];
            // in case new struct members are added, write with entire struct despite redundant `exists`
            layout._validatorData[lastValidator] = oldValidatorData;
            layout._validators[oldValidatorData.index] = lastValidator;
        }

        delete layout._validatorData[validator];
        layout._validators.pop(); // delete validator in last index and decrement length

        emit ValidatorRemoved(validator);
    }

    /// @dev Function to be implemented with desired access control
    function _checkCanUpdateValidators() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UserOperation} from "../../lib/ERC4337/utils/UserOperation.sol";

interface IValidator {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);

    function isValidSignature(bytes32 userOpHash, bytes calldata signature) external view returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISupportsInterface} from "./ISupportsInterface.sol";
import {SupportsInterfaceStorage} from "./SupportsInterfaceStorage.sol";

abstract contract SupportsInterface is ISupportsInterface {
    /// @dev For explicit EIP165 compliance, the interfaceId of the standard IERC165 implementation
    /// which is derived from `bytes4(keccak256('supportsInterface(bytes4)'))`
    /// is stored directly as a constant in order to preserve Rails's ERC7201 namespace pattern
    bytes4 public constant erc165Id = 0x01ffc9a7;

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc ISupportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc ISupportsInterface
    function addInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _addInterface(interfaceId);
    }

    /// @inheritdoc ISupportsInterface
    function removeInterface(bytes4 interfaceId) external virtual canUpdateInterfaces {
        _removeInterface(interfaceId);
    }

    /*===============
        INTERNALS
    ===============*/

    /// @dev To remain EIP165 compliant, this function must not be called with `bytes4(type(uint32).max)`
    /// Setting `0xffffffff` as true by providing it as `interfaceId` will disable support of EIP165 in child contracts
    function _supportsInterface(bytes4 interfaceId) internal view returns (bool) {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        return interfaceId == erc165Id || layout._supportsInterface[interfaceId];
    }

    function _addInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (layout._supportsInterface[interfaceId]) revert InterfaceAlreadyAdded(interfaceId);
        layout._supportsInterface[interfaceId] = true;
    }

    function _removeInterface(bytes4 interfaceId) internal {
        SupportsInterfaceStorage.Layout storage layout = SupportsInterfaceStorage.layout();
        if (!layout._supportsInterface[interfaceId]) revert InterfaceNotAdded(interfaceId);
        delete layout._supportsInterface[interfaceId];
    }

    /*====================
        AUTHORIZATION
    ====================*/

    modifier canUpdateInterfaces() {
        _checkCanUpdateInterfaces();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set interfaces
    /// @notice Should revert upon failure.
    function _checkCanUpdateInterfaces() internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

pragma solidity ^0.8.13;

/// @title ERC-4337 IStakeManager Interface
/// @author Live ERC-4337 EntryPoint Contract Deployment:
/// https://etherscan.io/address/0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789#code

/// @dev Interface contract taken from the live ERC-4337 EntryPoint,
/// used to manage deposits and withdrawals for IEntryPoint interface

interface IStakeManager {
    event Deposited(address indexed account, uint256 totalDeposit);

    event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

    /// Emitted when stake or unstake delay are modified
    event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

    /**
     * @param deposit the entity's deposit
     * @param staked true if this entity is staked.
     * @param stake actual amount of ether staked for this entity.
     * @param unstakeDelaySec minimum delay to withdraw the stake.
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 10^15 eth
     *    48 bit for full timestamp
     *    32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    // //API struct used by getStakeInfo and simulateValidation
    // struct StakeInfo {
    //     uint256 stake;
    //     uint256 unstakeDelaySec;
    // }

    /// @return info - full deposit information of given account
    function getDepositInfo(address account) external view returns (DepositInfo memory info);

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IInitializable {
    // events
    event Initialized();

    // errors
    error AlreadyInitialized();
    error NotInitializing();
    error CannotInitializeWhileConstructing();

    /// @dev View function to return whether a proxy contract has been initialized.
    function initialized() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library InitializableStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Initializable")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x8ca77559b51bdadaef66f8dec08105b4dd195463fda0f501696f5581b908dc00;

    struct Layout {
        bool _initialized;
        bool _initializing;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPermissions} from "./interface/IPermissions.sol";
import {PermissionsStorage as Storage} from "./PermissionsStorage.sol";

abstract contract Permissions is IPermissions {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IPermissions
    function checkPermission(bytes8 operation, address account) public view {
        _checkPermission(operation, account);
    }

    /// @inheritdoc IPermissions
    function hasPermission(bytes8 operation, address account) public view virtual returns (bool) {
        Storage.PermissionData memory permission = Storage.layout()._permissions[Storage._packKey(operation, account)];
        return permission.exists;
    }

    /// @inheritdoc IPermissions
    function getAllPermissions() public view returns (Permission[] memory permissions) {
        Storage.Layout storage layout = Storage.layout();
        uint256 len = layout._permissionKeys.length;
        permissions = new Permission[](len);
        for (uint256 i; i < len; i++) {
            uint256 permissionKey = layout._permissionKeys[i];
            (bytes8 operation, address account) = Storage._unpackKey(permissionKey);
            Storage.PermissionData memory permission = layout._permissions[permissionKey];
            permissions[i] = Permission(operation, account, permission.updatedAt);
        }
        return permissions;
    }

    /// @inheritdoc IPermissions
    function hashOperation(string memory name) public pure returns (bytes8) {
        return Storage._hashOperation(name);
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IPermissions).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IPermissions
    function addPermission(bytes8 operation, address account) public virtual {
        _checkCanUpdatePermissions();
        _addPermission(operation, account);
    }

    /// @inheritdoc IPermissions
    function removePermission(bytes8 operation, address account) public virtual {
        if (account != msg.sender) {
            _checkCanUpdatePermissions();
        }
        _removePermission(operation, account);
    }

    /*===============
        INTERNALS
    ===============*/

    function _addPermission(bytes8 operation, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        if (layout._permissions[permissionKey].exists) {
            revert PermissionAlreadyExists(operation, account);
        }
        // new length will be `len + 1`, so this permission has index `len`
        Storage.PermissionData memory permission =
            Storage.PermissionData(uint24(layout._permissionKeys.length), uint40(block.timestamp), true);

        layout._permissions[permissionKey] = permission;
        layout._permissionKeys.push(permissionKey); // set new permissionKey at index and increment length

        emit PermissionAdded(operation, account);
    }

    function _removePermission(bytes8 operation, address account) internal {
        Storage.Layout storage layout = Storage.layout();
        uint256 permissionKey = Storage._packKey(operation, account);
        Storage.PermissionData memory oldPermissionData = layout._permissions[permissionKey];
        if (!oldPermissionData.exists) {
            revert PermissionDoesNotExist(operation, account);
        }

        uint256 lastIndex = layout._permissionKeys.length - 1;
        // if removing item not at the end of the array, swap item with last in array
        if (oldPermissionData.index < lastIndex) {
            uint256 lastPermissionKey = layout._permissionKeys[lastIndex];
            Storage.PermissionData memory lastPermissionData = layout._permissions[lastPermissionKey];
            lastPermissionData.index = oldPermissionData.index;
            layout._permissionKeys[oldPermissionData.index] = lastPermissionKey;
            layout._permissions[lastPermissionKey] = lastPermissionData;
        }
        delete layout._permissions[permissionKey];
        layout._permissionKeys.pop(); // delete guard in last index and decrement length

        emit PermissionRemoved(operation, account);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier onlyPermission(bytes8 operation) {
        _checkPermission(operation, msg.sender);
        _;
    }

    /// @dev Function to ensure `account` has permission to carry out `operation`
    function _checkPermission(bytes8 operation, address account) internal view {
        if (!hasPermission(operation, account)) revert PermissionDoesNotExist(operation, account);
    }

    /// @dev Function to implement access control restricting setter functions
    function _checkCanUpdatePermissions() internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PermissionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Permissions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x9c5c344d590e19b509d94e6539bcccae12bdf46ca0b9e14840beae558bd13e00;

    struct Layout {
        uint256[] _permissionKeys;
        mapping(uint256 => PermissionData) _permissions;
    }

    struct PermissionData {
        uint24 index; //              [0..23]
        uint40 updatedAt; //          [24..63]
        bool exists; //              [64-71]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    /* 
    .  Here is a rundown demonstrating the packing mechanic for `_packKey(adminOp, address(type(uint160).max))`:
    .  ```return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);```     
    .  Left-pack account by typecasting to uint256: 
    .  ```addressToUint == 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff```
    .  Shift left 64 bits, ie 8 bytes, which in hex is 16 digits: 
    .  ```leftShift64 == 0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000```
    .  Left-pack operation by typecasting to uint256: 
    .  ```op == 0x000000000000000000000000000000000000000000000000df8b4c520ffe197c```
    .  Or packed operation against packed + shifted account: 
    .  ```_packedKey == 0x00000000ffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c```
    */
    function _packKey(bytes8 operation, address account) internal pure returns (uint256) {
        // `operation` cast to uint64 to keep it on the small Endian side, packed with account to its left; leftmost 4 bytes remain empty
        return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);
    }

    function _unpackKey(uint256 key) internal pure returns (bytes8 operation, address account) {
        operation = bytes8(uint64(key));
        account = address(uint160(key >> 64));
        return (operation, account);
    }

    function _hashOperation(string memory name) internal pure returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(name)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtensions {
    struct Extension {
        bytes4 selector;
        address implementation;
        uint40 updatedAt;
        string signature;
    }

    // events
    event ExtensionUpdated(bytes4 indexed selector, address indexed oldExtension, address indexed newExtension);

    // errors
    error ExtensionDoesNotExist(bytes4 selector);
    error ExtensionAlreadyExists(bytes4 selector);
    error ExtensionUnchanged(bytes4 selector, address oldImplementation, address newImplementation);

    /// @dev Function to check whether the given selector is mapped to an extension contract
    /// @param selector The function selector to query
    /// @return '' Boolean value identifying if the given selector is extended or not
    function hasExtended(bytes4 selector) external view returns (bool);

    /// @dev Function to get the extension contract address extending a specific func selector.
    /// @param selector The function selector to query for its extension.
    /// @return implementation The address of the extension contract for the function.
    function extensionOf(bytes4 selector) external view returns (address implementation);

    /// @dev Function to get an array of all registered extension contracts.
    /// @return extensions An array containing information about all registered extensions.
    function getAllExtensions() external view returns (Extension[] memory extensions);

    /// @dev Function to set a extension contract for a specific function selector.
    /// @param selector The function selector for which to set an extension contract.
    /// @param implementation The address of the extension contract to map to a function.
    function setExtension(bytes4 selector, address implementation) external;

    /// @dev Function to remove the extension contract for a function.
    /// @param selector The function selector for which to remove its extension.
    function removeExtension(bytes4 selector) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtension {
    /// @dev Function to get the signature string for a specific function selector.
    /// @param selector The function selector to query.
    /// @return signature The signature string for the given function.
    function signatureOf(bytes4 selector) external pure returns (string memory signature);

    /// @dev Function to get an array of all recognized function selectors.
    /// @return selectors An array containing all 4-byte function selectors.
    function getAllSelectors() external pure returns (bytes4[] memory selectors);

    /// @dev Function to get an array of all recognized function signature strings.
    /// @return signatures An array containing all function signature strings.
    function getAllSignatures() external pure returns (string[] memory signatures);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library ExtensionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Extensions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x24b223a3be882d5d1d257152fdb15a02ae59c6d11e58bc0c17888d15a9b15b00;

    struct Layout {
        bytes4[] _selectors;
        mapping(bytes4 => ExtensionData) _extensions;
    }

    struct ExtensionData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

library Contract {
    error InvalidContract(address implementation);

    function _requireContract(address implementation) internal view {
        if (!Address.isContract(implementation)) revert InvalidContract(implementation);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/utils/Create2.sol";

interface IERC6551Registry {
    /**
     * @dev The registry MUST emit the ERC6551AccountCreated event upon successful account creation
     */
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev The registry MUST revert with AccountCreationFailed error if the create2 operation fails
     */
    error AccountCreationFailed();

    /**
     * @dev Creates a token bound account for a non-fungible token
     *
     * If account has already been created, returns the account address without calling create2
     *
     * If initData is not empty and account has not yet been created, calls account with
     * provided initData after creation
     *
     * Emits ERC6551AccountCreated event
     *
     * @return the address of the account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address);

    /**
     * @dev Returns the computed token bound account address for a non-fungible token
     *
     * @return The computed address of the token bound account
     */
    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address);
}

library ERC6551BytecodeLib {
    /**
     * @dev Returns the creation code of the token bound account for a non-fungible token
     *
     * @return the creation code of the token bound account
     */
    function getCreationCode(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
            implementation_,
            hex"5af43d82803e903d91602b57fd5bf3",
            abi.encode(salt_, chainId_, tokenContract_, tokenId_)
        );
    }
}

contract ERC6551Registry is IERC6551Registry {
    /**
     * @dev {See IERC6551Registry-createAccount}
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        bytes memory code = ERC6551BytecodeLib.getCreationCode(implementation, salt, chainId, tokenContract, tokenId);

        address _account = Create2.computeAddress(salt, keccak256(code));

        if (_account.code.length != 0) return _account;

        emit ERC6551AccountCreated(_account, implementation, salt, chainId, tokenContract, tokenId);

        assembly {
            _account := create2(0, add(code, 0x20), mload(code), salt)
        }

        if (_account == address(0)) revert AccountCreationFailed();

        return _account;
    }

    /**
     * @dev {See IERC6551Registry-account}
     */
    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash =
            keccak256(ERC6551BytecodeLib.getCreationCode(implementation, salt, chainId, tokenContract, tokenId));

        return Create2.computeAddress(salt, bytecodeHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev the ERC-165 identifier for this interface is `0x6faff5f1`
interface IERC6551Account {
    /**
     * @dev Allows the account to receive Ether
     *
     * Accounts MUST implement a `receive` function
     *
     * Accounts MAY perform arbitrary logic to restrict conditions
     * under which Ether can be received
     */
    receive() external payable;

    /**
     * @dev Returns the identifier of the non-fungible token which owns the account
     *
     * The return value of this function MUST be constant - it MUST NOT change over time
     *
     * @return chainId       The EIP-155 ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId       The ID of the token
     */
    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /**
     * @dev Returns a value that SHOULD be modified each time the account changes state
     *
     * @return The current account state
     */
    function state() external view returns (uint256);

    /**
     * @dev Returns a magic value indicating whether a given signer is authorized to act on behalf
     * of the account
     *
     * MUST return the bytes4 magic value 0x523e3260 if the given signer is valid
     *
     * By default, the holder of the non-fungible token the account is bound to MUST be considered
     * a valid signer
     *
     * Accounts MAY implement additional authorization logic which invalidates the holder as a
     * signer or grants signing permissions to other non-holder accounts
     *
     * @param  signer     The address to check signing authorization for
     * @param  context    Additional data used to determine whether the signer is valid
     * @return magicValue Magic value indicating whether the signer is valid
     */
    function isValidSigner(address signer, bytes calldata context) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuards} from "./interface/IGuards.sol";
import {GuardsInternal} from "./GuardsInternal.sol";

abstract contract Guards is GuardsInternal {
    /*===========
        VIEWS
    ===========*/

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IGuards).interfaceId;
    }

    /*=============
        SETTERS
    =============*/

    /// @dev Function to set a guard contract for a given operation.
    /// @param operation The operation for which to add a guard contract.
    /// @param implementation The guard contract address containing code to hook before and after operations
    /// @notice Due to EXTCODESIZE check within `_requireContract()`, this function will revert if called
    /// during the constructor of the contract at `implementation`. Deploy `implementation` contract first.
    function setGuard(bytes8 operation, address implementation) public virtual canUpdateGuards {
        _setGuard(operation, implementation);
    }

    /// @dev Function to remove a guard for a given operation.
    /// @param operation The operation for which to remove its guard contract.
    function removeGuard(bytes8 operation) public virtual canUpdateGuards {
        _removeGuard(operation);
    }

    /*===================
        AUTHORIZATION
    ===================*/

    modifier canUpdateGuards() {
        _checkCanUpdateGuards();
        _;
    }

    /// @dev Function to check if caller possesses sufficient permission to set Guards
    /// @notice Should revert upon failure.
    function _checkCanUpdateGuards() internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

/// @title Execute - A contract for executing calls to other contracts
/// @notice This abstract contract provides functionality for executing *only* calls to other contracts
abstract contract Execute {
    event Executed(address indexed executor, address indexed to, uint256 value, bytes data);

    /// @dev Execute a call to another contract with the specified target address, value, and data.
    /// @param to The address of the target contract to call.
    /// @param value The amount of native currency to send with the call.
    /// @param data The call's data.
    /// @return executeData The return data from the executed call.
    function executeCall(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = _call(to, value, data);
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    /// @notice Temporary backwards compatibility with offchain API
    function execute(address to, uint256 value, bytes calldata data) public returns (bytes memory executeData) {
        _checkCanExecuteCall();
        (address guard, bytes memory checkBeforeData) = _beforeExecuteCall(to, value, data);
        executeData = _call(to, value, data);
        _afterExecuteCall(guard, checkBeforeData, executeData);
        emit Executed(msg.sender, to, value, data);
        return executeData;
    }

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(Execute).interfaceId;
    }

    function _call(address to, uint256 value, bytes calldata data) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @dev Internal function to check if the caller has permission to execute calls.
    function _checkCanExecuteCall() internal view virtual;

    /// @dev Hook to perform pre-call checks and return guard information.
    function _beforeExecuteCall(address to, uint256 value, bytes calldata data)
        internal
        virtual
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Hook to perform post-call checks.
    function _afterExecuteCall(address guard, bytes memory checkBeforeData, bytes memory executeData)
        internal
        virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IValidators {
    error NotEntryPoint(address caller);
    error ValidatorAlreadyExists(address validator);
    error ValidatorDoesNotExist(address validator);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    /// @dev View function to check whether given address has been added as validator
    function isValidator(address validator) external view returns (bool);
    /// @dev View function to retrieve all validators from storage
    function getAllValidators() external view returns (address[] memory validators);
    /// @dev Function to add the address of a Validator module to storage
    function addValidator(address validator) external;
    /// @dev Function to remove the address of a Validator module from storage
    function removeValidator(address validator) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISupportsInterface {
    // events
    event InterfaceAdded(bytes4 indexed interfaceId);
    event InterfaceRemoved(bytes4 indexed interfaceId);

    // errors
    error InterfaceAlreadyAdded(bytes4 interfaceId);
    error InterfaceNotAdded(bytes4 interfaceId);

    /// @dev Function to implement ERC-165 compliance
    /// @param interfaceId The interface identifier to check.
    /// @return _ Boolean indicating whether the contract supports the specified interface.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @dev Function to add support for a specific interface.
    /// @param interfaceId The interface identifier to add support for.
    function addInterface(bytes4 interfaceId) external;

    /// @dev Function to remove support for a specific interface.
    /// @param interfaceId The interface identifier to remove support for.
    function removeInterface(bytes4 interfaceId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SupportsInterfaceStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.SupportsInterface")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x95a5ecff3e5709ffcdce1ca934c4b897d39c8a95719755d12b7d1e124ce29700;

    struct Layout {
        mapping(bytes4 => bool) _supportsInterface;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuards {
    struct Guard {
        bytes8 operation;
        address implementation;
        uint40 updatedAt;
    }

    // events
    event GuardUpdated(bytes8 indexed operation, address indexed oldGuard, address indexed newGuard);

    // errors
    error GuardDoesNotExist(bytes8 operation);
    error GuardUnchanged(bytes8 operation, address oldImplementation, address newImplementation);
    error GuardRejected(bytes8 operation, address guard);

    /// @dev Perform checks before executing a specific operation and return guard information.
    /// @param operation The operation identifier to check.
    /// @param data Additional data associated with the operation.
    /// @return guard The address of the guard contract responsible for the operation.
    /// @return checkBeforeData Additional data from the guard contract's checkBefore function.
    function checkGuardBefore(bytes8 operation, bytes calldata data)
        external
        view
        returns (address guard, bytes memory checkBeforeData);

    /// @dev Perform checks after executing an operation.
    /// @param guard The address of the guard contract responsible for the operation.
    /// @param checkBeforeData Additional data obtained from the guard's checkBefore function.
    /// @param executionData The execution data associated with the operation.
    function checkGuardAfter(address guard, bytes calldata checkBeforeData, bytes calldata executionData)
        external
        view;

    /// @dev Get the guard contract address responsible for a specific operation.
    /// @param operation The operation identifier.
    /// @return implementation The address of the guard contract for the operation.
    function guardOf(bytes8 operation) external view returns (address implementation);

    /// @dev Get an array of all registered guard contracts.
    /// @return Guards An array containing information about all registered guard contracts.
    function getAllGuards() external view returns (Guard[] memory Guards);

    /// @dev Set a guard contract for a specific operation.
    /// @param operation The operation identifier for which to set the guard contract.
    /// @param implementation The address of the guard contract to set.
    function setGuard(bytes8 operation, address implementation) external;

    /// @dev Remove the guard contract for a specific operation.
    /// @param operation The operation identifier for which to remove the guard contract.
    function removeGuard(bytes8 operation) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuards} from "./interface/IGuards.sol";
import {IGuard} from "./interface/IGuard.sol";
import {GuardsStorage} from "./GuardsStorage.sol";
import {Contract} from "../lib/Contract.sol";

abstract contract GuardsInternal is IGuards {
    using GuardsStorage for address;
    /*===========
        HOOKS
    ===========*/

    /// @inheritdoc IGuards
    function checkGuardBefore(bytes8 operation, bytes memory data)
        public
        view
        returns (address guard, bytes memory checkBeforeData)
    {
        guard = guardOf(operation);
        if (guard.autoReject()) {
            revert GuardRejected(operation, guard);
        } else if (guard.autoApprove()) {
            return (guard, "");
        }

        checkBeforeData = IGuard(guard).checkBefore(msg.sender, data); // revert will cascade

        return (guard, checkBeforeData);
    }

    /// @inheritdoc IGuards
    function checkGuardAfter(address guard, bytes memory checkBeforeData, bytes memory executionData) public view {
        // only check guard if not autoApprove, autoReject will have already reverted
        if (!guard.autoApprove()) {
            IGuard(guard).checkAfter(checkBeforeData, executionData); // revert will cascade
        }
    }

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IGuards
    function guardOf(bytes8 operation) public view returns (address implementation) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        return layout._guards[operation].implementation;
    }

    /// @inheritdoc IGuards
    function getAllGuards() public view virtual returns (Guard[] memory guards) {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        uint256 len = layout._operations.length;
        guards = new Guard[](len);
        for (uint256 i; i < len; i++) {
            bytes8 operation = layout._operations[i];
            GuardsStorage.GuardData memory guard = layout._guards[operation];
            guards[i] = Guard(operation, guard.implementation, guard.updatedAt);
        }
        return guards;
    }

    /*=============
        SETTERS
    =============*/

    function _setGuard(bytes8 operation, address implementation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        // require implementation is contract unless it is MAX_ADDRESS
        if (implementation != GuardsStorage.MAX_ADDRESS) {
            Contract._requireContract(implementation); // fails on adding address(0) here
        }

        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation != address(0)) {
            // update

            if (implementation == oldGuard.implementation) {
                revert GuardUnchanged(operation, oldGuard.implementation, implementation);
            }
            GuardsStorage.GuardData memory newGuard =
                GuardsStorage.GuardData(uint24(oldGuard.index), uint40(block.timestamp), implementation);
            layout._guards[operation] = newGuard;
        } else {
            // add

            // new length will be `len + 1`, so this guard has index `len`
            GuardsStorage.GuardData memory guard =
                GuardsStorage.GuardData(uint24(layout._operations.length), uint40(block.timestamp), implementation);
            layout._guards[operation] = guard;
            layout._operations.push(operation); // set new operation at index and increment length
        }

        emit GuardUpdated(operation, oldGuard.implementation, implementation);
    }

    function _removeGuard(bytes8 operation) internal {
        GuardsStorage.Layout storage layout = GuardsStorage.layout();
        GuardsStorage.GuardData memory oldGuard = layout._guards[operation];
        if (oldGuard.implementation == address(0)) revert GuardDoesNotExist(operation);

        uint256 lastIndex = layout._operations.length - 1;
        // if removing extension not at the end of the array, swap extension with last in array
        if (oldGuard.index < lastIndex) {
            bytes8 lastOperation = layout._operations[lastIndex];
            GuardsStorage.GuardData memory lastGuard = layout._guards[lastOperation];
            lastGuard.index = oldGuard.index;
            layout._operations[oldGuard.index] = lastOperation;
            layout._guards[lastOperation] = lastGuard;
        }
        delete layout._guards[operation];
        layout._operations.pop(); // delete guard in last index and decrement length

        emit GuardUpdated(operation, oldGuard.implementation, address(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuard {
    function checkBefore(address operator, bytes calldata data) external view returns (bytes memory checkBeforeData);
    function checkAfter(bytes calldata checkBeforeData, bytes calldata executionData) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library GuardsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Guards")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x68fdbc9be968974abe602a5cbdd43c5fd2f2d66bfde2f0188149c63e523d4d00;
    address internal constant MAX_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    struct Layout {
        bytes8[] _operations;
        mapping(bytes8 => GuardData) _guards;
    }

    struct GuardData {
        uint24 index; //           [0..23]
        uint40 updatedAt; //       [24..63]
        address implementation; // [64..223]
    }
    // thought: add parameters `bool useBefore` and `bool useAfter` to configure if a guard should use both checks or just one

    enum CheckType {
        BEFORE,
        AFTER
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev Function to check for guards that have been set to the max address,
    /// signaling automatic rejection of an operation
    function autoReject(address guard) internal pure returns (bool) {
        return guard == MAX_ADDRESS;
    }

    /// @dev Function to check for guards that have been set to the zero address,
    /// signaling automatic approval of an operation
    function autoApprove(address guard) internal pure returns (bool) {
        return guard == address(0);
    }
}