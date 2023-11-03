// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;






// 
// ██████╗  ██████╗ ██████╗  ██████╗ ████████╗    ██╗███████╗    ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗     ███████╗
// ██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝    ██║██╔════╝    ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝
// ██████╔╝██║   ██║██████╔╝██║   ██║   ██║       ██║███████╗    ██████╔╝██║   ██║██████╔╝██████╔╝██║     █████╗  
// ██╔══██╗██║   ██║██╔══██╗██║   ██║   ██║       ██║╚════██║    ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║     ██╔══╝  
// ██║  ██║╚██████╔╝██████╔╝╚██████╔╝   ██║       ██║███████║    ██║     ╚██████╔╝██║  ██║██║     ███████╗███████╗
// ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝       ╚═╝╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝
//                                                                                                                
// Robot Is Purple - generated with HeyMint.xyz Launchpad - https://nft-launchpad.heymint.xyz
// 








import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IAddressRelay} from "./interfaces/IAddressRelay.sol";
import {BaseConfig, TokenConfig} from "./libraries/HeyMintStorage.sol";

contract RobotIsPurple {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADDRESS_RELAY_SLOT =
        keccak256("heymint.launchpad.1155.addressRelay");

    /**
     * @notice Initializes the child contract with the base implementation address and the configuration settings
     * @param _name The name of the NFT
     * @param _symbol The symbol of the NFT
     * @param _baseConfig Base configuration settings
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _addressRelay,
        address _implementation,
        BaseConfig memory _baseConfig,
        TokenConfig[] memory _tokenConfig
    ) {
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = _implementation;
        StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value = _addressRelay;
        IAddressRelay addressRelay = IAddressRelay(_addressRelay);
        address implContract = addressRelay.fallbackImplAddress();
        (bool success, ) = implContract.delegatecall(
            abi.encodeWithSelector(
                0xd940392c,
                _name,
                _symbol,
                _baseConfig,
                _tokenConfig
            )
        );
        require(success);
    }

    /**
     * @dev Delegates the current call to nftImplementation
     *
     * This function does not return to its internal call site - it will return directly to the external caller.
     */
    fallback() external payable {
        IAddressRelay addressRelay = IAddressRelay(
            StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value
        );
        address implContract = addressRelay.getImplAddress(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implContract,
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

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRelay, Implementation} from "./interfaces/IAddressRelay.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

/**
 * @author Created by HeyMint Launchpad https://join.heymint.xyz
 * @notice This contract contains the base logic for ERC-721A tokens deployed with HeyMint
 */
contract AddressRelay is IAddressRelay, Ownable {
    mapping(bytes4 => address) public selectorToImplAddress;
    mapping(bytes4 => bool) public supportedInterfaces;
    bytes4[] selectors;
    address[] implAddresses;
    address public fallbackImplAddress;
    bool public relayFrozen;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // IERC165
        supportedInterfaces[0x7f5828d0] = true; // IERC173
        supportedInterfaces[0xd9b67a26] = true; // ERC-1155
        supportedInterfaces[0x0e89341c] = true; // ERC1155MetadataURI
        supportedInterfaces[0x2a55205a] = true; // IERC2981
    }

    /**
     * @notice Permanently freezes the relay so no more selectors can be added or removed
     */
    function freezeRelay() external onlyOwner {
        relayFrozen = true;
    }

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            selectorToImplAddress[selector] = _implAddress;
            selectors.push(selector);
        }
        bool implAddressExists = false;
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                implAddressExists = true;
                break;
            }
        }
        if (!implAddressExists) {
            implAddresses.push(_implAddress);
        }
    }

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            delete selectorToImplAddress[selector];
            uint256 selectorsLen = selectors.length;
            for (uint256 j = 0; j < selectorsLen; j++) {
                if (selectors[j] == selector) {
                    if (j != selectorsLen - 1) {
                        // if not last element, copy last to deleted element's slot
                        selectors[j] = selectors[selectorsLen - 1];
                    }
                    // pop last element
                    selectors.pop();
                    break;
                }
            }
        }
    }

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                // this just sets the value to 0, but doesn't remove it from the array
                delete implAddresses[i];
                break;
            }
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                delete selectorToImplAddress[selectors[i]];
                delete selectors[i];
            }
        }
    }

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        if (implAddress == address(0)) {
            implAddress = fallbackImplAddress;
        }
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns the implementation address for a given function selector. Throws an error if function does not exist.
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddressNoFallback(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory)
    {
        uint256 trueImplAddressCount = 0;
        uint256 implAddressesLength = implAddresses.length;
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] != address(0)) {
                trueImplAddressCount++;
            }
        }
        Implementation[] memory impls = new Implementation[](
            trueImplAddressCount
        );
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] == address(0)) {
                continue;
            }
            address implAddress = implAddresses[i];
            bytes4[] memory selectors_;
            uint256 selectorCount = 0;
            uint256 selectorsLength = selectors.length;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectorCount++;
                }
            }
            selectors_ = new bytes4[](selectorCount);
            uint256 selectorIndex = 0;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectors_[selectorIndex] = selectors[j];
                    selectorIndex++;
                }
            }
            impls[i] = Implementation(implAddress, selectors_);
        }
        return impls;
    }

    /**
     * @notice Return all the function selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory) {
        uint256 selectorCount = 0;
        uint256 selectorsLength = selectors.length;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorCount++;
            }
        }
        bytes4[] memory selectorArr = new bytes4[](selectorCount);
        uint256 selectorIndex = 0;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorArr[selectorIndex] = selectors[i];
                selectorIndex++;
            }
        }
        return selectorArr;
    }

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(
        address _fallbackAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        fallbackImplAddress = _fallbackAddress;
    }

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external onlyOwner {
        supportedInterfaces[_interfaceId] = _supported;
    }

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256(
    "diamond.storage.eip.712.permit"
);

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly {
        diamondStorage.slot := slot
    }
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
///      when using with a proxy, due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    bytes32 immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 immutable _NAME_HASH;
    bytes32 immutable _VERSION_HASH;

    constructor(string memory name, string memory version) {
        _EIP_712_DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
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
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner)
                revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC1155 = keccak256("diamond.storage.erc1155");

function s() pure returns (ERC1155DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC1155;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ERC1155DS {
    mapping(address => mapping(uint256 => uint256)) balanceOf;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// ------------- errors

error NotAuthorized();
error LengthMismatch();
error UnsafeRecipient();

/// @title ERC1155 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate ERC1155 (https://github.com/Rari-Capital/solmate)
abstract contract ERC1155UDS is EIP712PermitUDS("ERC1155Permit", "1") {
    ERC1155DS private __storageLayout; // storage layout for upgrade compatibility checks

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    /* ------------- virtual ------------- */

    function uri(uint256 id) public view virtual returns (string memory);

    /**
     * @dev Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any batch token transfer.
     */
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /* ------------- view ------------- */

    function balanceOf(
        address owner,
        uint256 id
    ) public view virtual returns (uint256) {
        return s().balanceOf[owner][id];
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        if (owners.length != ids.length) revert LengthMismatch();

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = s().balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function isApprovedForAll(
        address operator,
        address owner
    ) public view returns (bool) {
        return s().isApprovedForAll[operator][owner];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /* ------------- public ------------- */

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        _beforeTokenTransfer(msg.sender, from, to, id, amount, data);

        s().balanceOf[from][id] -= amount;
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual {
        if (ids.length != amounts.length) revert LengthMismatch();
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        _beforeBatchTokenTransfer(msg.sender, from, to, ids, amounts, data);

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            s().balanceOf[from][id] -= amount;
            s().balanceOf[to][id] += amount;

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            s().balanceOf[to][ids[i]] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            s().balanceOf[from][ids[i]] -= amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        s().balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

/// @dev computed as `keccak256("eip1967.proxy.implementation") - 1`
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT
    }
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT)
            revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(
                gas(),
                sload(ERC1967_PROXY_STORAGE_SLOT),
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {BaseConfig, TokenConfig, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC1155UDS} from "./ERC1155UDS.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";

contract HeyMintERC1155ExtensionA is
    HeyMintERC1155Upgradeable,
    IERC2981Upgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    // Default subscription address to use to enable royalty enforcement on certain exchanges like OpenSea
    address public constant CORI_SUBSCRIPTION_ADDRESS =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // Default subscription address to use as a placeholder for no royalty enforcement
    address public constant EMPTY_SUBSCRIPTION_ADDRESS =
        0x511af84166215d528ABf8bA6437ec4BEcF31934B;

    /**
     * @notice Initializes a new child deposit contract
     * @param _name The name of the collection
     * @param _symbol The symbol of the collection
     * @param _config Base configuration settings
     * @param _tokenConfig Array of token configuration settings
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config,
        TokenConfig[] memory _tokenConfig
    ) public initializer {
        __Ownable_init();
        __OperatorFilterer_init(
            _config.enforceRoyalties == true
                ? CORI_SUBSCRIPTION_ADDRESS
                : EMPTY_SUBSCRIPTION_ADDRESS,
            true
        );

        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.cfg = _config;
        state.name = _name;
        state.symbol = _symbol;
        for (uint i = 0; i < _tokenConfig.length; i++) {
            state.tokens[_tokenConfig[i].tokenId] = _tokenConfig[i];
            state.data.tokenIds.push(_tokenConfig[i].tokenId);
        }
    }

    // ============ BASE FUNCTIONALITY ============

    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(HeyMintERC1155Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function name() public view returns (string memory) {
        return HeyMintStorage.state().name;
    }

    function symbol() public view returns (string memory) {
        return HeyMintStorage.state().symbol;
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function permanentlyDisableTokenMinting(
        uint16 _tokenId
    ) external onlyOwner {
        HeyMintStorage.state().data.tokenMintingPermanentlyDisabled[
            _tokenId
        ] = true;
    }

    // ============ ERC-2981 ROYALTY ============

    /**
     * @notice Basic gas saving implementation of ERC-2981 royaltyInfo function with receiver set to the contract owner
     * @param _salePrice The sale price used to determine the royalty amount
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address payoutAddress = state.advCfg.royaltyPayoutAddress !=
            address(0x0)
            ? state.advCfg.royaltyPayoutAddress
            : owner();
        if (payoutAddress == address(0x0)) {
            return (payoutAddress, 0);
        }
        return (payoutAddress, (_salePrice * state.cfg.royaltyBps) / 10000);
    }

    /**
     * @notice Updates royalty basis points
     * @param _royaltyBps The new royalty basis points to use
     */
    function setRoyaltyBasisPoints(uint16 _royaltyBps) external onlyOwner {
        HeyMintStorage.state().cfg.royaltyBps = _royaltyBps;
    }

    /**
     * @notice Updates royalty payout address
     * @param _royaltyPayoutAddress The new royalty payout address to use
     */
    function setRoyaltyPayoutAddress(
        address _royaltyPayoutAddress
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .royaltyPayoutAddress = _royaltyPayoutAddress;
    }

    // ============ OPERATOR FILTER REGISTRY ============

    /**
     * @notice Override default ERC-1155 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155UDS) onlyAllowedOperatorApproval(operator) {
        return super.setApprovalForAll(operator, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, AdvancedConfig} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionB is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    /**
     * @notice Returns how many of a given token have been minted
     */
    function totalSupply(uint16 _tokenId) external view returns (uint16) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.data.totalSupply[_tokenId];
    }

    // ============ PUBLIC SALE ============

    /**
     * @notice To be updated by contract owner to allow public sale minting for a given token
     */
    function setTokenPublicSaleState(
        uint16 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price for a given token
     */
    function setTokenPublicPrice(
        uint16 _tokenId,
        uint32 _publicPrice
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicPrice = _publicPrice;
    }

    function setTokenMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _maxSupply >= state.data.totalSupply[_tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        state.tokens[_tokenId].maxSupply = _maxSupply;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address for a given token
     */
    function setTokenPublicMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPublicSaleStartTime(
        uint16 _tokenId,
        uint32 _publicSaleStartTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_publicSaleStartTime > block.timestamp, "TIME_IN_PAST");
        state.tokens[_tokenId].publicSaleStartTime = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPublicSaleEndTime(
        uint16 _tokenId,
        uint32 _publicSaleEndTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        require(
            state.tokens[_tokenId].publicSaleStartTime < _publicSaleEndTime,
            "END_TIME_BEFORE_START_TIME"
        );
        state.tokens[_tokenId].publicSaleEndTime = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePublicSaleTimes(
        uint16 _tokenId,
        bool _usePublicSaleTimes
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].usePublicSaleTimes = _usePublicSaleTimes;
    }

    function mintToken(
        uint16 _tokenId,
        uint16 _numTokens
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 totalSupply = state.data.totalSupply[_tokenId];
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        uint256 publicPrice = publicPriceInWei(_tokenId);
        require(
            state.tokens[_tokenId].publicSaleActive,
            "PUBLIC_SALE_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[
            msg.sender
        ][_tokenId] + _numTokens;
        uint16 publicMintsAllowedPerAddress = state
            .tokens[_tokenId]
            .publicMintsAllowedPerAddress;
        require(
            publicMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= publicMintsAllowedPerAddress,
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        uint16 newTotalSupply = totalSupply + _numTokens;
        uint16 _maxSupply = state.tokens[_tokenId].maxSupply;
        require(
            _maxSupply == 0 ||
                newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == publicPrice * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }
        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;

        _mint(msg.sender, _tokenId, _numTokens, "");

        if (_maxSupply != 0 && newTotalSupply == _maxSupply) {
            state.tokens[_tokenId].publicSaleActive = false;
        }
    }

    /**
     * @notice Returns the number of tokens minted by a specific address
     */
    function tokensMintedByAddress(
        address _address,
        uint16 _tokenId
    ) external view returns (uint16) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.data.tokensMintedByAddress[_address][_tokenId];
    }

    // ============ HEYMINT FEE ============

    // Address of the HeyMint admin
    address public constant heymintAdminAddress =
        0x52EA5F96f004d174470901Ba3F1984D349f0D3eF;

    /**
     * @notice Allows the heymintAdminAddress to set the heymint fee per token
     * @param _heymintFeePerToken The new fee per token in wei
     */
    function setHeymintFeePerToken(uint256 _heymintFeePerToken) external {
        require(msg.sender == heymintAdminAddress, "MUST_BE_HEYMINT_ADMIN");
        HeyMintStorage.state().data.heymintFeePerToken = _heymintFeePerToken;
    }

    // ============ PAYOUT ============

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external nonReentrant onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !anyTokenRefundGuaranteeActive(),
            "REFUND_GUARANTEE_STILL_ACTIVE"
        );
        uint256 balance = address(this).balance;
        if (state.advCfg.payoutAddresses.length == 0) {
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "TRANSFER_FAILED");
        } else {
            for (uint256 i = 0; i < state.advCfg.payoutAddresses.length; i++) {
                uint256 amount = (balance * state.advCfg.payoutBasisPoints[i]) /
                    10000;
                (bool success, ) = HeyMintStorage
                    .state()
                    .advCfg
                    .payoutAddresses[i]
                    .call{value: amount}("");
                require(success, "TRANSFER_FAILED");
            }
        }
    }

    /**
     * @notice Freeze all payout addresses & basis points so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        HeyMintStorage.state().advCfg.payoutAddressesFrozen = true;
    }

    /**
     * @notice Will return true if token holders can still return their tokens for a refund
     * @param _tokenId The token id
     */
    function refundGuaranteeActive(uint16 _tokenId) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return block.timestamp < state.tokens[_tokenId].refundEndsAt;
    }

    /**
     * Will return true if any token refund is still active
     */
    function anyTokenRefundGuaranteeActive() public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        for (uint256 i = 0; i < state.data.tokenIds.length; i++) {
            if (refundGuaranteeActive(state.data.tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     * @param _payoutAddresses The new payout addresses to use
     * @param _payoutBasisPoints The amount to pay out to each address in _payoutAddresses (in basis points)
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint16[] calldata _payoutBasisPoints
    ) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        require(!advCfg.payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        uint256 payoutBasisPointsLength = _payoutBasisPoints.length;
        require(
            _payoutAddresses.length == payoutBasisPointsLength,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPointsLength; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "BASIS_POINTS_MUST_EQUAL_10000");
        advCfg.payoutAddresses = _payoutAddresses;
        advCfg.payoutBasisPoints = _payoutBasisPoints;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig} from "../libraries/HeyMintStorage.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract HeyMintERC1155ExtensionC is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;
    using ECDSAUpgradeable for bytes32;

    // ============ PRESALE ============

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        require(_presaleSignerAddress != address(0));
        HeyMintStorage.state().cfg.presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        address presaleSignerAddress = HeyMintStorage
            .state()
            .cfg
            .presaleSignerAddress;
        return
            presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Returns the presale price in wei. Presale price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function presalePriceInWei(uint16 _tokenId) public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return uint256(state.tokens[_tokenId].presalePrice) * 10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting for a given token
     */
    function setTokenPresaleState(
        uint16 _tokenId,
        bool _presaleActiveState
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presaleActive = _presaleActiveState;
    }

    /**
     * @notice Update the presale mint price for a given token
     */
    function setTokenPresalePrice(
        uint16 _tokenId,
        uint32 _presalePrice
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presalePrice = _presalePrice;
    }

    function setTokenPresaleMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _maxSupply >= state.data.totalSupply[_tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        state.tokens[_tokenId].presaleMaxSupply = _maxSupply;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given address for a given token
     */
    function setTokenPresaleMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPresaleStartTime(
        uint16 _tokenId,
        uint32 _presaleStartTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_presaleStartTime > block.timestamp, "TIME_IN_PAST");
        state.tokens[_tokenId].presaleStartTime = _presaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPresaleEndTime(
        uint16 _tokenId,
        uint32 _presaleEndTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        require(
            state.tokens[_tokenId].presaleStartTime < _presaleEndTime,
            "END_TIME_BEFORE_START_TIME"
        );
        state.tokens[_tokenId].presaleEndTime = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePresaleTimes(
        uint16 _tokenId,
        bool _usePresaleTimes
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].usePresaleTimes = _usePresaleTimes;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPresaleTimeIsActive(
        uint16 _tokenId
    ) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].usePresaleTimes == false) {
            return true;
        }
        return
            block.timestamp >= state.tokens[_tokenId].presaleStartTime &&
            block.timestamp <= state.tokens[_tokenId].presaleEndTime;
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint16 _tokenId,
        uint16 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        TokenConfig storage tokenConfig = state.tokens[_tokenId];
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        uint256 presalePrice = presalePriceInWei(_tokenId);

        require(tokenConfig.presaleActive, "PRESALE_IS_NOT_ACTIVE");
        require(
            tokenPresaleTimeIsActive(_tokenId),
            "PRESALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        uint16 presaleMintsAllowedPerAddress = tokenConfig
            .presaleMintsAllowedPerAddress;
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[
            msg.sender
        ][_tokenId] + _numTokens;
        require(
            presaleMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= presaleMintsAllowedPerAddress,
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _maximumAllowedMints == 0 ||
                newTokensMintedByAddress <= _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _numTokens;
        require(
            state.tokens[_tokenId].maxSupply == 0 ||
                newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint16 presaleMaxSupply = tokenConfig.presaleMaxSupply;
        require(
            presaleMaxSupply == 0 || newTotalSupply <= presaleMaxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == presalePrice * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints, _tokenId)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }

        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;
        state.data.totalSupply[_tokenId] = newTotalSupply;

        _mint(msg.sender, _tokenId, _numTokens, "");

        if (presaleMaxSupply != 0 && newTotalSupply == presaleMaxSupply) {
            state.tokens[_tokenId].presaleActive = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig, Data, BurnToken} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionD is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ CONFIG ============

    /**
     * @notice Returns config storage variables for the contract
     */
    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            bool,
            uint16[] memory
        )
    {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return (
            state.cfg,
            state.advCfg,
            state.data.advancedConfigInitialized,
            state.data.tokenIds
        );
    }

    /**
     * @notice Updates the base configuration for the contract
     */
    function _updateBaseConfig(BaseConfig memory _baseConfig) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _baseConfig.heyMintFeeActive == state.cfg.heyMintFeeActive,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.enforceRoyalties == state.cfg.enforceRoyalties,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        state.cfg = _baseConfig;
    }

    /**
     * @notice Updates the base configuration for the contract
     */
    function updateBaseConfig(
        BaseConfig memory _baseConfig
    ) external onlyOwner {
        return _updateBaseConfig(_baseConfig);
    }

    /**
     * @notice Updates the advanced configuration for the contract
     */
    function _updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _advancedConfig.payoutAddresses.length ==
                _advancedConfig.payoutBasisPoints.length,
            "PAYOUT_ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _advancedConfig.payoutBasisPoints.length; i++) {
            totalBasisPoints += _advancedConfig.payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "BASIS_POINTS_MUST_EQUAL_10000");
        if (state.advCfg.payoutAddressesFrozen) {
            require(
                _advancedConfig.payoutAddressesFrozen,
                "PAYOUT_ADDRESSES_FROZEN"
            );
            bool payoutInfoChanged = false;
            for (
                uint256 i = 0;
                i < _advancedConfig.payoutAddresses.length;
                i++
            ) {
                if (
                    _advancedConfig.payoutAddresses[i] !=
                    state.advCfg.payoutAddresses[i]
                ) {
                    payoutInfoChanged = true;
                    break;
                }
            }
            require(!payoutInfoChanged, "PAYOUT_ADDRESSES_FROZEN");
            for (
                uint256 i = 0;
                i < _advancedConfig.payoutBasisPoints.length;
                i++
            ) {
                if (
                    _advancedConfig.payoutBasisPoints[i] !=
                    state.advCfg.payoutBasisPoints[i]
                ) {
                    payoutInfoChanged = true;
                    break;
                }
            }
            require(!payoutInfoChanged, "PAYOUT_ADDRESSES_FROZEN");
        }
        state.advCfg = _advancedConfig;
        state.data.advancedConfigInitialized = true;
    }

    /**
     * @notice Updates the advanced configuration for the contract
     */
    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external onlyOwner {
        return _updateAdvancedConfig(_advancedConfig);
    }

    /**
     * @notice Returns token storage variables for the contract
     */
    function getTokenSettings(
        uint16 tokenId
    ) external view returns (TokenConfig memory, BurnToken[] memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return (state.tokens[tokenId], state.burnTokens[tokenId]);
    }

    /**
     * @notice Creates or updates a token based on the tokenId
     */
    function upsertToken(TokenConfig memory _tokenConfig) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _tokenConfig.maxSupply >=
                state.data.totalSupply[_tokenConfig.tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        require(
            _tokenConfig.presaleMaxSupply >=
                state.data.totalSupply[_tokenConfig.tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        require(
            _tokenConfig.publicSaleStartTime == 0 ||
                _tokenConfig.publicSaleStartTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.publicSaleEndTime == 0 ||
                _tokenConfig.publicSaleEndTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.presaleStartTime == 0 ||
                _tokenConfig.presaleStartTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            _tokenConfig.presaleEndTime == 0 ||
                _tokenConfig.presaleEndTime > block.timestamp,
            "TIME_IN_PAST"
        );
        require(
            !state.data.tokenMetadataFrozen[_tokenConfig.tokenId] &&
                !state.data.allMetadataFrozen,
            "ALL_METADATA_FROZEN"
        );
        require(
            !state.data.tokenMetadataFrozen[_tokenConfig.tokenId] ||
                keccak256(bytes(_tokenConfig.tokenUri)) ==
                keccak256(bytes(state.tokens[_tokenConfig.tokenId].tokenUri)),
            "METADATA_FROZEN"
        );
        require(
            _tokenConfig.refundEndsAt >=
                state.tokens[_tokenConfig.tokenId].refundEndsAt,
            "REFUND_DURATION_CANNOT_BE_DECREASED"
        );
        require(
            state.tokens[_tokenConfig.tokenId].refundPrice == 0 ||
                state.tokens[_tokenConfig.tokenId].refundPrice ==
                _tokenConfig.refundPrice,
            "REFUND_PRICE_CANNOT_BE_CHANGED"
        );

        state.tokens[_tokenConfig.tokenId] = _tokenConfig;
        // add the token id to the tokenIds array if it doesn't already exist
        for (uint256 i = 0; i < state.data.tokenIds.length; i++) {
            if (state.data.tokenIds[i] == _tokenConfig.tokenId) {
                return;
            }
        }
        state.data.tokenIds.push(_tokenConfig.tokenId);
    }

    /**
     * @notice Updates all of the token IDs on the contract.
     */
    function _setTokenIds(uint16[] memory _tokenIds) internal {
        HeyMintStorage.State storage state = HeyMintStorage.state();

        uint256 oldLength = state.data.tokenIds.length;
        uint256 newLength = _tokenIds.length;

        // Update the existing token ids & push any new ones.
        for (uint256 i = 0; i < newLength; i++) {
            if (i < oldLength) {
                state.data.tokenIds[i] = _tokenIds[i];
                state.tokens[_tokenIds[i]].tokenId = _tokenIds[i];
            } else {
                state.data.tokenIds.push(_tokenIds[i]);
                state.tokens[_tokenIds[i]].tokenId = _tokenIds[i];
            }
        }

        // Pop any extra token ids.
        for (uint256 i = oldLength; i > newLength; i--) {
            state.data.tokenIds.pop();
        }
    }

    /**
     * @notice Updates all of the token IDs on the contract.
     */
    function setTokenIds(uint16[] memory _tokenIds) external onlyOwner {
        return _setTokenIds(_tokenIds);
    }

    /**
     * @notice Set the details of the tokens to be burned in order to mint a token
     * @param _tokenIds The ids of the token on the contract to update
     * @param _burnConfigs An array of arrays of all tokens required for burning
     */
    function _updateBurnTokens(
        uint16[] memory _tokenIds,
        BurnToken[][] memory _burnConfigs
    ) internal {
        require(
            _tokenIds.length == 0 || _tokenIds.length == _burnConfigs.length,
            "BURN_CONFIGS_LENGTH_MUST_MATCH_TOKENS_LENGTH"
        );
        HeyMintStorage.State storage state = HeyMintStorage.state();

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 tokenId = _tokenIds[i];

            uint256 oldBurnTokensLength = state.burnTokens[tokenId].length;
            uint256 newBurnTokensLength = _burnConfigs[i].length;

            // Update the existing BurnTokens and push any new BurnTokens
            for (uint256 j = 0; j < newBurnTokensLength; j++) {
                if (j < oldBurnTokensLength) {
                    state.burnTokens[tokenId][j] = _burnConfigs[i][j];
                } else {
                    state.burnTokens[tokenId].push(_burnConfigs[i][j]);
                }
            }

            // Pop any extra BurnTokens if the new array is shorter
            for (
                uint256 j = oldBurnTokensLength;
                j > newBurnTokensLength;
                j--
            ) {
                state.burnTokens[tokenId].pop();
            }
        }
    }

    /**
     * @notice Set the details of the tokens to be burned in order to mint a token
     * @param _tokenIds The ids of the token on the contract to update
     * @param _burnConfigs An array of arrays of all tokens required for burning
     */
    function updateBurnTokens(
        uint16[] calldata _tokenIds,
        BurnToken[][] calldata _burnConfigs
    ) external onlyOwner {
        return _updateBurnTokens(_tokenIds, _burnConfigs);
    }

    /**
     * @notice Update the full config (base config + adv config + all tokens + burn tokens) on the contract.
     */
    function updateFullConfig(
        BaseConfig memory _baseConfig,
        TokenConfig[] memory _tokenConfigs,
        AdvancedConfig memory _advancedConfig,
        BurnToken[][] memory _burnTokens
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _burnTokens.length == 0 ||
                _burnTokens.length == _tokenConfigs.length,
            "BURN_CONFIGS_LENGTH_MUST_MATCH_TOKENS_LENGTH"
        );
        uint16[] memory tokenIds = new uint16[](_tokenConfigs.length);
        for (uint256 i = 0; i < _tokenConfigs.length; i++) {
            tokenIds[i] = _tokenConfigs[i].tokenId;
        }
        _updateBaseConfig(_baseConfig);
        _updateAdvancedConfig(_advancedConfig);
        state.data.advancedConfigInitialized = true;
        _setTokenIds(tokenIds);
        _updateBurnTokens(tokenIds, _burnTokens);
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setTokenUri(
        uint16 _tokenId,
        string calldata _newTokenURI
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(!state.data.allMetadataFrozen, "ALL_METADATA_FROZEN");
        require(
            !state.data.tokenMetadataFrozen[_tokenId],
            "TOKEN_METADATA_FROZEN"
        );
        state.tokens[_tokenId].tokenUri = _newTokenURI;
    }

    /**
     * @notice Returns a token-specific URI, if configured. Otherwise, returns an empty string.
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.tokens[uint16(_tokenId)].tokenUri;
    }

    /**
     * @notice Update the global default ERC-1155 base URI
     */
    function setGlobalUri(string calldata _newTokenURI) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(!state.data.allMetadataFrozen, "ALL_METADATA_FROZEN");
        state.cfg.uriBase = _newTokenURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionE is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ FREEZING ============
    /**
     * @notice Freeze metadata for a specific token id so it can never be changed again
     */
    function freezeTokenMetadata(uint16 _tokenId) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (
            !state.data.tokenMetadataFrozen[_tokenId] &&
            bytes(state.tokens[_tokenId].tokenUri).length == 0
        ) {
            state.tokens[_tokenId].tokenUri = state.cfg.uriBase;
        }
        state.data.tokenMetadataFrozen[_tokenId] = true;
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
     */
    function freezeAllMetadata() external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.data.allMetadataFrozen = true;
    }

    // ============ GIFT ============

    /**
     * @notice Allow owner to send tokens without cost to multiple addresses
     */
    function giftTokens(
        uint16 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external payable onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        require(
            _receivers.length == _mintNumber.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalMints = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMints += _mintNumber[i];
        }
        // require either no tokenMaxSupply set or tokenMaxSupply not maxed out
        uint16 newtotalSupply = state.data.totalSupply[_tokenId] +
            uint16(totalMints);
        uint16 maxSupply = state.tokens[_tokenId].maxSupply;
        require(
            maxSupply == 0 || newtotalSupply <= maxSupply,
            "MINT_TOO_LARGE"
        );
        uint256 heymintFee = (totalMints * heymintFeePerToken()) / 10;
        require(msg.value == heymintFee, "PAYMENT_INCORRECT");
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }
        state.data.totalSupply[_tokenId] = newtotalSupply;
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mint(_receivers[i], _tokenId, _mintNumber[i], "");
        }
    }

    // ============ CREDIT CARD PAYMENT ============

    /**
     * @notice Returns an array of default addresses authorized to call creditCardMint
     */
    function getDefaultCreditCardMintAddresses()
        public
        pure
        returns (address[5] memory)
    {
        return [
            0xf3DB642663231887E2Ff3501da6E3247D8634A6D,
            0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB,
            0x9E733848061e4966c4a920d5b99a123459670aEe,
            0x7754B94345BCE520f8dd4F6a5642567603e90E10,
            0xdAb1a1854214684acE522439684a145E62505233
        ];
    }

    /**
     * @notice Set addresses authorized to call creditCardMint
     * @param _creditCardMintAddresses The custom addresses to authorize
     */
    function setCreditCardMintAddresses(
        address[] memory _creditCardMintAddresses
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .creditCardMintAddresses = _creditCardMintAddresses;
    }

    function creditCardMint(
        uint16 _tokenId,
        uint16 _numTokens,
        address _to
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address[5]
            memory defaultAddresses = getDefaultCreditCardMintAddresses();
        bool authorized = false;
        for (uint256 i = 0; i < defaultAddresses.length; i++) {
            if (msg.sender == defaultAddresses[i]) {
                authorized = true;
                break;
            }
        }
        if (!authorized) {
            for (
                uint256 i = 0;
                i < state.advCfg.creditCardMintAddresses.length;
                i++
            ) {
                if (msg.sender == state.advCfg.creditCardMintAddresses[i]) {
                    authorized = true;
                    break;
                }
            }
        }
        require(authorized, "NOT_AUTHORIZED_ADDRESS");
        require(state.tokens[_tokenId].publicSaleActive, "NOT_ACTIVE");
        require(tokenPublicSaleTimeIsActive(_tokenId), "NOT_ACTIVE");
        uint16 publicMintsAllowedPerAddress = state
            .tokens[_tokenId]
            .publicMintsAllowedPerAddress;
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[_to][
            _tokenId
        ] + _numTokens;
        require(
            publicMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _numTokens;
        uint16 maxSupply = state.tokens[_tokenId].maxSupply;
        require(newTotalSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");
        uint256 publicPrice = publicPriceInWei(_tokenId);
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        require(
            msg.value == publicPrice * _numTokens + heymintFee,
            "INVALID_PRICE_PAID"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }

        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;
        _mint(_to, _tokenId, _numTokens, "");

        if (maxSupply != 0 && newTotalSupply == maxSupply) {
            state.tokens[_tokenId].publicSaleActive = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig, BurnToken} from "../libraries/HeyMintStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {s} from "./ERC1155UDS.sol";

contract HeyMintERC1155ExtensionF is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ SOULBINDING ============

    /**
     * @notice Change the admin address used to transfer tokens if needed.
     * @param _adminAddress The new soulbound admin address
     */
    function setSoulboundAdminAddress(
        address _adminAddress
    ) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        require(!advCfg.soulbindAdminTransfersPermanentlyDisabled);
        advCfg.soulboundAdminAddress = _adminAddress;
    }

    /**
     * @notice Disallow admin transfers of soulbound tokens permanently.
     */
    function disableSoulbindAdminTransfersPermanently() external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        advCfg.soulboundAdminAddress = address(0);
        advCfg.soulbindAdminTransfersPermanentlyDisabled = true;
    }

    /**
     * @notice Turn soulbinding on or off
     * @param _tokenId The token to modify soulbinding for
     * @param _soulbindingActive If true soulbinding is active
     */
    function setSoulbindingState(
        uint16 _tokenId,
        bool _soulbindingActive
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .soulbindingActive = _soulbindingActive;
    }

    /**
     * @notice Allows an admin address to initiate token transfers if user wallets get hacked or lost
     * This function can only be used on soulbound tokens to prevent arbitrary transfers of normal tokens
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _tokenId The token id to transfer
     * @param _amount The number of tokens to transfer
     */
    function soulboundAdminTransfer(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _amount
    ) external {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !state.advCfg.soulbindAdminTransfersPermanentlyDisabled,
            "NOT_ACTIVE"
        );
        require(state.tokens[_tokenId].soulbindingActive, "NOT_ACTIVE");
        address adminAddress = state.advCfg.soulboundAdminAddress == address(0)
            ? owner()
            : state.advCfg.soulboundAdminAddress;
        require(msg.sender == adminAddress, "NOT_ADMIN");
        state.data.soulboundAdminTransferInProgress = true;
        s().isApprovedForAll[_from][adminAddress] = true;
        safeTransferFrom(_from, _to, _tokenId, _amount, "");
        state.data.soulboundAdminTransferInProgress = false;
        s().isApprovedForAll[_from][adminAddress] = false;
    }

    // ============ REFUND ============

    /**
     * @notice Returns the refund price in wei. Refund price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     * @param _tokenId The token id
     */
    function refundPriceInWei(uint16 _tokenId) public view returns (uint256) {
        return
            uint256(HeyMintStorage.state().tokens[_tokenId].refundPrice) *
            10 ** 13;
    }

    /**
     * @notice Will return true if token holders can still return their tokens for a refund
     * @param _tokenId The token id
     */
    function refundGuaranteeActive(uint16 _tokenId) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return block.timestamp < state.tokens[_tokenId].refundEndsAt;
    }

    /**
     * @notice Set the address where tokens are sent when refunded
     * @param _refundAddress The new refund address
     */
    function setRefundAddress(address _refundAddress) external onlyOwner {
        require(_refundAddress != address(0), "CANNOT_SEND_TO_ZERO_ADDRESS");
        HeyMintStorage.state().advCfg.refundAddress = _refundAddress;
    }

    /**
     * @notice Increase the period of time where token holders can still return their tokens for a refund
     * @param _tokenId The token id
     * @param _newRefundEndsAt The new timestamp when the refund period ends. Must be greater than the current timestamp
     */
    function increaseRefundEndsAt(
        uint16 _tokenId,
        uint32 _newRefundEndsAt
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _newRefundEndsAt > state.tokens[_tokenId].refundEndsAt,
            "MUST_INCREASE_DURATION"
        );
        HeyMintStorage.state().tokens[_tokenId].refundEndsAt = _newRefundEndsAt;
    }

    /**
     * @notice Refund token and return the refund price to the token owner.
     * @param _tokenId The id of the token to refund
     */
    function refund(uint16 _tokenId, uint256 _numTokens) external nonReentrant {
        require(refundGuaranteeActive(_tokenId), "REFUND_GUARANTEE_EXPIRED");
        require(
            balanceOf(msg.sender, _tokenId) >= _numTokens,
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        HeyMintStorage.State storage state = HeyMintStorage.state();

        address addressToSendToken = state.advCfg.refundAddress != address(0)
            ? state.advCfg.refundAddress
            : owner();

        safeTransferFrom(
            msg.sender,
            addressToSendToken,
            _tokenId,
            _numTokens,
            ""
        );

        uint256 refundPrice = refundPriceInWei(_tokenId);
        uint256 totalRefundAmount = refundPrice * _numTokens;

        (bool success, ) = payable(msg.sender).call{value: totalRefundAmount}(
            ""
        );
        require(success, "TRANSFER_FAILED");
    }

    // ============ BURN TO MINT ============

    // Address where burnt tokens are sent.
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Returns the burn payment in wei. Price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     * @param _tokenId The id of the token on the contract
     */
    function burnPaymentInWei(uint16 _tokenId) public view returns (uint256) {
        return
            uint256(HeyMintStorage.state().tokens[_tokenId].burnPayment) *
            10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     * @param _tokenId The id of the token on the contract
     * @param _burnClaimActive If true tokens can be burned in order to mint
     */
    function setBurnClaimState(
        uint16 _tokenId,
        bool _burnClaimActive
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        TokenConfig storage tokenCfg = state.tokens[_tokenId];
        if (_burnClaimActive) {
            require(state.burnTokens[_tokenId].length != 0, "NOT_CONFIGURED");
            require(tokenCfg.mintsPerBurn != 0, "NOT_CONFIGURED");
        }
        tokenCfg.burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Update the number of mints claimable per token burned
     * @param _tokenId The id of the token on the contract
     * @param _mintsPerBurn The new number of tokens that can be minted per burn transaction
     */
    function updateMintsPerBurn(
        uint16 _tokenId,
        uint8 _mintsPerBurn
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].burnClaimActive) {
            require(_mintsPerBurn > 0, "MUST_BE_AT_LEAST_1_IF_ACTIVE");
        }
        HeyMintStorage.state().tokens[_tokenId].mintsPerBurn = _mintsPerBurn;
    }

    /**
     * @notice Update the price required to be paid alongside a burn tx to mint (payment is per tx, not per token in the case of >1 mintsPerBurn)
     * @param _tokenId The id of the token on the contract
     * @param _burnPayment The new amount of payment required per burn transaction
     */
    function updatePaymentPerBurn(
        uint16 _tokenId,
        uint32 _burnPayment
    ) external onlyOwner {
        HeyMintStorage.state().tokens[_tokenId].burnPayment = _burnPayment;
    }

    /**
     * @notice Burn tokens from other contracts in order to mint tokens on this contract
     * @dev This contract must be approved by the caller to transfer the tokens being burned
     * @param _tokenId The id of the token to mint
     * @param _contracts The contracts of the tokens to burn in the same order as the array burnTokens
     * @param _tokenIdsToBurn Nested array of token ids to burn for 721 and amounts to burn for 1155 corresponding to _contracts
     * @param _tokensToMint The number of tokens to mint
     */
    function burnToMint(
        uint16 _tokenId,
        address[] calldata _contracts,
        uint256[][] calldata _tokenIdsToBurn,
        uint16 _tokensToMint
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 burnTokensLen = state.burnTokens[_tokenId].length;
        require(burnTokensLen > 0, "NOT_CONFIGURED");
        uint16 mintsPerBurn = state.tokens[_tokenId].mintsPerBurn;
        require(mintsPerBurn != 0, "NOT_CONFIGURED");
        require(state.tokens[_tokenId].burnClaimActive, "NOT_ACTIVE");
        require(
            _contracts.length == _tokenIdsToBurn.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        require(_contracts.length == burnTokensLen, "ARRAY_LENGTHS_MUST_MATCH");
        //uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _tokensToMint;
        require(
            state.data.totalSupply[_tokenId] + _tokensToMint <=
                state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 burnPayment = burnPaymentInWei(_tokenId);
        uint256 burnPaymentTotal = burnPayment * (_tokensToMint / mintsPerBurn);
        uint256 heymintFee = _tokensToMint * heymintFeePerToken();
        require(
            msg.value == burnPaymentTotal + heymintFee,
            "INVALID_PRICE_PAID"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        for (uint256 i = 0; i < burnTokensLen; i++) {
            BurnToken memory burnToken = state.burnTokens[_tokenId][i];
            require(
                burnToken.contractAddress == _contracts[i],
                "INCORRECT_CONTRACT"
            );
            if (burnToken.tokenType == 1) {
                uint256 _tokenIdsToBurnLength = _tokenIdsToBurn[i].length;
                require(
                    (_tokenIdsToBurnLength / burnToken.tokensPerBurn) *
                        mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                for (uint256 j = 0; j < _tokenIdsToBurnLength; j++) {
                    IERC721 burnContract = IERC721(_contracts[i]);
                    uint256 tokenId = _tokenIdsToBurn[i][j];
                    require(
                        burnContract.ownerOf(tokenId) == msg.sender,
                        "MUST_OWN_TOKEN"
                    );
                    burnContract.transferFrom(msg.sender, burnAddress, tokenId);
                }
            } else if (burnToken.tokenType == 2) {
                uint256 amountToBurn = _tokenIdsToBurn[i][0];
                require(
                    (amountToBurn / burnToken.tokensPerBurn) * mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                IERC1155 burnContract = IERC1155(_contracts[i]);
                require(
                    burnContract.balanceOf(msg.sender, burnToken.tokenId) >=
                        amountToBurn,
                    "MUST_OWN_TOKEN"
                );
                burnContract.safeTransferFrom(
                    msg.sender,
                    burnAddress,
                    burnToken.tokenId,
                    amountToBurn,
                    ""
                );
            }
        }

        state.data.totalSupply[_tokenId] += _tokensToMint;
        state.data.tokensMintedByAddress[msg.sender][_tokenId] += uint16(
            _tokensToMint
        );
        _mint(msg.sender, _tokenId, _tokensToMint, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, Data} from "../libraries/HeyMintStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HeyMintERC1155ExtensionG is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ FREE CLAIM ============

    /**
     * @notice To be updated by contract owner to allow free claiming tokens
     * @param _tokenId The id of the token to update
     * @param _freeClaimActive If true tokens can be claimed for free
     */
    function setFreeClaimState(
        uint16 _tokenId,
        bool _freeClaimActive
    ) external onlyOwner {
        TokenConfig storage tokenCfg = HeyMintStorage.state().tokens[_tokenId];
        if (_freeClaimActive) {
            require(
                tokenCfg.freeClaimContractAddress != address(0),
                "NOT_CONFIGURED"
            );
            require(tokenCfg.mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        }
        tokenCfg.freeClaimActive = _freeClaimActive;
    }

    /**
     * @notice Set the contract address of the NFT eligible for free claim
     * @param _tokenId The id of the token to update
     * @param _freeClaimContractAddress The new contract address
     */
    function setFreeClaimContractAddress(
        uint16 _tokenId,
        address _freeClaimContractAddress
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .freeClaimContractAddress = _freeClaimContractAddress;
    }

    /**
     * @notice Update the number of free mints claimable per token redeemed from the external ERC721 contract
     * @param _tokenId The id of the token to update
     * @param _mintsPerFreeClaim The new number of free mints per token redeemed
     */
    function updateMintsPerFreeClaim(
        uint16 _tokenId,
        uint8 _mintsPerFreeClaim
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .mintsPerFreeClaim = _mintsPerFreeClaim;
    }

    /**
     * @notice Check if an array of tokens is eligible for free claim
     * @param _tokenId The id of the token on this contract
     * @param _claimTokenIds The ids of the tokens to check
     */
    function checkFreeClaimEligibility(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external view returns (bool[] memory) {
        Data storage data = HeyMintStorage.state().data;
        bool[] memory eligible = new bool[](_claimTokenIds.length);
        for (uint256 i = 0; i < _claimTokenIds.length; i++) {
            eligible[i] = !data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]];
        }
        return eligible;
    }

    /**
     * @notice Free claim token when msg.sender owns the token in the external contract
     * @param _tokenId The id of the token to mint
     * @param _claimTokenIds The ids of the tokens to redeem
     */
    function freeClaim(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 mintsPerFreeClaim = state.tokens[_tokenId].mintsPerFreeClaim;
        uint256 tokenIdsLength = _claimTokenIds.length;
        uint256 totalMints = tokenIdsLength * mintsPerFreeClaim;
        address freeClaimContractAddress = state
            .tokens[_tokenId]
            .freeClaimContractAddress;
        require(
            state.tokens[_tokenId].freeClaimContractAddress != address(0),
            "NOT_CONFIGURED"
        );
        require(mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        require(state.tokens[_tokenId].freeClaimActive, "NOT_ACTIVE");
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] +
            uint16(totalMints);
        require(
            newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        if (state.cfg.heyMintFeeActive) {
            uint256 heymintFee = totalMints * heymintFeePerToken();
            require(msg.value == heymintFee, "PAYMENT_INCORRECT");
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        IERC721 ExternalERC721FreeClaimContract = IERC721(
            freeClaimContractAddress
        );
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            require(
                ExternalERC721FreeClaimContract.ownerOf(_claimTokenIds[i]) ==
                    msg.sender,
                "MUST_OWN_TOKEN"
            );
            require(
                !state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]],
                "TOKEN_ALREADY_CLAIMED"
            );
            state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]] = true;
        }

        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][_tokenId] += uint16(
            totalMints
        );
        _mint(msg.sender, _tokenId, totalMints, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title HeyMint ERC1155 Function Reference
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This is a function reference contract for Etherscan reference purposes only.
 * This contract includes all the functions from multiple implementation contracts.
 */
contract HeyMintERC1155Reference {
    struct BaseConfig {
        uint24 projectId;
        bool enforceRoyalties;
        uint16 royaltyBps;
        bool heyMintFeeActive;
        address presaleSignerAddress;
        string uriBase;
    }

    struct TokenConfig {
        uint16 tokenId;
        uint16 maxSupply;
        bool publicSaleActive;
        uint32 publicPrice;
        uint8 publicMintsAllowedPerAddress;
        bool usePublicSaleTimes;
        uint32 publicSaleStartTime;
        uint32 publicSaleEndTime;
        bool presaleActive;
        uint32 presalePrice;
        uint16 presaleMaxSupply;
        uint8 presaleMintsAllowedPerAddress;
        string tokenUri;
        bool usePresaleTimes;
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        address freeClaimContractAddress;
        uint16 mintsPerFreeClaim;
        bool freeClaimActive;
        uint32 burnPayment;
        uint16 mintsPerBurn;
        bool burnClaimActive;
        bool soulbindingActive;
        uint32 refundEndsAt;
        uint32 refundPrice;
    }

    struct AdvancedConfig {
        address royaltyPayoutAddress;
        uint16[] payoutBasisPoints;
        address[] payoutAddresses;
        bool payoutAddressesFrozen;
        address[] creditCardMintAddresses;
        bool soulbindAdminTransfersPermanentlyDisabled;
        address soulboundAdminAddress;
        address refundAddress;
    }

    struct BurnToken {
        address contractAddress;
        uint8 tokenType;
        uint8 tokensPerBurn;
        uint16 tokenId;
    }

    function CORI_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function DOMAIN_SEPARATOR() external view returns (bytes32) {}

    function EMPTY_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256) {}

    function balanceOfBatch(
        address[] memory owners,
        uint256[] memory ids
    ) external view returns (uint256[] memory balances) {}

    function defaultHeymintFeePerToken() external view returns (uint256) {}

    function heymintFeePerToken() external view returns (uint256) {}

    function heymintPayoutAddress() external view returns (address) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config,
        TokenConfig[] memory _tokenConfig
    ) external {}

    function isApprovedForAll(
        address operator,
        address owner
    ) external view returns (bool) {}

    function isOperatorFilterRegistryRevoked() external view returns (bool) {}

    function name() external view returns (string memory) {}

    function nonces(address owner) external view returns (uint256) {}

    function owner() external view returns (address) {}

    function pause() external {}

    function permanentlyDisableTokenMinting(uint16 _tokenId) external {}

    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) external {}

    function revokeOperatorFilterRegistry() external {}

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address, uint256) {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setRoyaltyBasisPoints(uint16 _royaltyBps) external {}

    function setRoyaltyPayoutAddress(address _royaltyPayoutAddress) external {}

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {}

    function symbol() external view returns (string memory) {}

    function transferOwnership(address newOwner) external {}

    function unpause() external {}

    function uri(uint256 _id) external view returns (string memory) {}

    function anyTokenRefundGuaranteeActive() external view returns (bool) {}

    function heymintAdminAddress() external view returns (address) {}

    function mintToken(uint16 _tokenId, uint16 _numTokens) external payable {}

    function publicPriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function refundGuaranteeActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function setHeymintFeePerToken(uint256 _heymintFeePerToken) external {}

    function setTokenMaxSupply(uint16 _tokenId, uint16 _maxSupply) external {}

    function setTokenPublicMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external {}

    function setTokenPublicPrice(
        uint16 _tokenId,
        uint32 _publicPrice
    ) external {}

    function setTokenPublicSaleEndTime(
        uint16 _tokenId,
        uint32 _publicSaleEndTime
    ) external {}

    function setTokenPublicSaleStartTime(
        uint16 _tokenId,
        uint32 _publicSaleStartTime
    ) external {}

    function setTokenPublicSaleState(
        uint16 _tokenId,
        bool _saleActiveState
    ) external {}

    function setTokenUsePublicSaleTimes(
        uint16 _tokenId,
        bool _usePublicSaleTimes
    ) external {}

    function tokenPublicSaleTimeIsActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function updatePayoutAddressesAndBasisPoints(
        address[] memory _payoutAddresses,
        uint16[] memory _payoutBasisPoints
    ) external {}

    function withdraw() external {}

    function presaleMint(
        bytes32 _messageHash,
        bytes memory _signature,
        uint16 _tokenId,
        uint16 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable {}

    function presalePriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function setPresaleSignerAddress(address _presaleSignerAddress) external {}

    function setTokenPresaleEndTime(
        uint16 _tokenId,
        uint32 _presaleEndTime
    ) external {}

    function setTokenPresaleMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external {}

    function setTokenPresaleMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external {}

    function setTokenPresalePrice(
        uint16 _tokenId,
        uint32 _presalePrice
    ) external {}

    function setTokenPresaleStartTime(
        uint16 _tokenId,
        uint32 _presaleStartTime
    ) external {}

    function setTokenPresaleState(
        uint16 _tokenId,
        bool _presaleActiveState
    ) external {}

    function setTokenUsePresaleTimes(
        uint16 _tokenId,
        bool _usePresaleTimes
    ) external {}

    function tokenPresaleTimeIsActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            bool,
            uint16[] memory
        )
    {}

    function getTokenSettings(
        uint16 tokenId
    ) external view returns (TokenConfig memory, BurnToken[] memory) {}

    function setGlobalUri(string memory _newTokenURI) external {}

    function setTokenUri(
        uint16 _tokenId,
        string memory _newTokenURI
    ) external {}

    function updateBaseConfig(BaseConfig memory _baseConfig) external {}

    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external {}

    function updateFullConfig(
        BaseConfig memory _baseConfig,
        TokenConfig[] memory _tokenConfigs,
        AdvancedConfig memory _advancedConfig,
        BurnToken[][] memory _burnTokens
    ) external {}

    function upsertToken(TokenConfig memory _tokenConfig) external {}

    function creditCardMint(
        uint16 _tokenId,
        uint16 _numTokens,
        address _to
    ) external payable {}

    function getDefaultCreditCardMintAddresses()
        external
        pure
        returns (address[5] memory)
    {}

    function giftTokens(
        uint16 _tokenId,
        address[] memory _receivers,
        uint256[] memory _mintNumber
    ) external payable {}

    function setCreditCardMintAddresses(
        address[] memory _creditCardMintAddresses
    ) external {}

    function burnAddress() external view returns (address) {}

    function burnPaymentInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function burnToMint(
        uint16 _tokenId,
        address[] memory _contracts,
        uint256[][] memory _tokenIdsToBurn,
        uint16 _tokensToMint
    ) external payable {}

    function disableSoulbindAdminTransfersPermanently() external {}

    function increaseRefundEndsAt(
        uint16 _tokenId,
        uint32 _newRefundEndsAt
    ) external {}

    function refund(uint16 _tokenId, uint256 _numTokens) external {}

    function refundPriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function setBurnClaimState(
        uint16 _tokenId,
        bool _burnClaimActive
    ) external {}

    function setRefundAddress(address _refundAddress) external {}

    function setSoulbindingState(
        uint16 _tokenId,
        bool _soulbindingActive
    ) external {}

    function setSoulboundAdminAddress(address _adminAddress) external {}

    function soulboundAdminTransfer(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _amount
    ) external {}

    function updateBurnTokens(
        uint16[] calldata _tokenIds,
        BurnToken[][] calldata _burnConfigs
    ) external {}

    function updateMintsPerBurn(
        uint16 _tokenId,
        uint8 _mintsPerBurn
    ) external {}

    function updatePaymentPerBurn(
        uint16 _tokenId,
        uint32 _burnPayment
    ) external {}

    function checkFreeClaimEligibility(
        uint16 _tokenId,
        uint256[] memory _claimTokenIds
    ) external view returns (bool[] memory) {}

    function freeClaim(
        uint16 _tokenId,
        uint256[] memory _claimTokenIds
    ) external payable {}

    function setFreeClaimContractAddress(
        uint16 _tokenId,
        address _freeClaimContractAddress
    ) external {}

    function setFreeClaimState(
        uint16 _tokenId,
        bool _freeClaimActive
    ) external {}

    function updateMintsPerFreeClaim(
        uint16 _tokenId,
        uint8 _mintsPerFreeClaim
    ) external {}

    function freezePayoutAddresses() external {}

    function freezeTokenMetadata(uint16 _tokenId) external {}

    function freezeAllMetadata() external {}

    function totalSupply(uint16 _tokenId) external view returns (uint16) {}

    function tokensMintedByAddress(
        address _address,
        uint16 _tokenId
    ) external view returns (uint16) {}

    function tokenURI(uint256 _tokenId) external view returns (string memory) {}

    function setTokenIds(uint16[] calldata _tokenIds) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Data, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC1155UDS} from "./ERC1155UDS.sol";
import {OwnableUDS} from "./OwnableUDS.sol";
import {PausableUDS} from "./PausableUDS.sol";
import {ReentrancyGuardUDS} from "./ReentrancyGuardUDS.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import {IERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

/**
 * @title HeyMintERC1155Upgradeable
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This contract contains shared logic to be inherited by all implementation contracts
 */
contract HeyMintERC1155Upgradeable is
    ERC1155UDS,
    OwnableUDS,
    PausableUDS,
    ReentrancyGuardUDS,
    RevokableOperatorFiltererUpgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    uint256 public constant defaultHeymintFeePerToken = 0.0007 ether;
    address public constant heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;

    // ============ BASE FUNCTIONALITY ============

    function uri(
        uint256 _id
    ) public view virtual override(ERC1155UDS) returns (string memory) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 id = uint16(_id);
        if (bytes(state.tokens[id].tokenUri).length > 0) {
            return state.tokens[id].tokenUri;
        }
        return state.cfg.uriBase;
    }

    /**
     * @notice Returns the owner of the contract
     */
    function owner()
        public
        view
        virtual
        override(OwnableUDS, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUDS.owner();
    }

    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155UDS) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     * Also prevents transfers from blocked operators.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155UDS) onlyAllowedOperator(from) {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     * Also prevents transfers from blocked operators.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public override(ERC1155UDS) onlyAllowedOperator(from) {
        for (uint256 i; i < ids.length; i++) {
            require(amounts[i] > 0, "AMOUNT_CANNOT_BE_ZERO");
        }
        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155UDS) notPaused onlyAllowedOperator(from) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (!state.data.soulboundAdminTransferInProgress) {
            require(
                !state.tokens[uint16(id)].soulbindingActive,
                "TOKEN_SOULBOUND"
            );
        }
    }

    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155UDS) notPaused onlyAllowedOperator(from) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (!state.data.soulboundAdminTransferInProgress) {
            for (uint256 i; i < ids.length; i++) {
                require(
                    !state.tokens[uint16(ids[i])].soulbindingActive,
                    "TOKEN_SOULBOUND"
                );
            }
        }
    }

    // ============ HEYMINT FEE ============

    /**
     * @notice Returns the HeyMint fee per token. If the fee is active but 0, the default fee is returned
     */
    function heymintFeePerToken() public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 fee = state.data.heymintFeePerToken;
        if (!state.cfg.heyMintFeeActive) {
            return 0;
        }
        return fee == 0 ? defaultHeymintFeePerToken : fee;
    }

    // ============ PUBLIC SALE ============

    /**
     * @notice Returns the public price in wei. Public price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function publicPriceInWei(uint16 _tokenId) public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return uint256(state.tokens[_tokenId].publicPrice) * 10 ** 13;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPublicSaleTimeIsActive(
        uint16 _tokenId
    ) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].usePublicSaleTimes == false) {
            return true;
        }
        return
            block.timestamp >= state.tokens[_tokenId].publicSaleStartTime &&
            block.timestamp <= state.tokens[_tokenId].publicSaleEndTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view virtual returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_PAUSABLE = keccak256(
    "diamond.storage.pausable"
);

function s() pure returns (PausableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_PAUSABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct PausableDS {
    uint256 paused;
}

// ------------- errors

error Paused();
error AlreadyPaused();
error AlreadyUnpaused();

/// @title Puasable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract PausableUDS {
    PausableDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- internal ------------- */

    function _pause() internal {
        if (s().paused == 2) revert AlreadyPaused();

        s().paused = 2;
    }

    function _unpause() internal {
        if (s().paused != 2) revert AlreadyUnpaused();

        s().paused = 1;
    }

    /* ------------- modifier ------------- */

    modifier notPaused() {
        if (s().paused == 2) revert Paused();

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_REENTRANCY_GUARD = keccak256(
    "diamond.storage.reentrancy.guard"
);

function s() pure returns (ReentrancyGuardDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_REENTRANCY_GUARD;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ReentrancyGuardDS {
    uint256 locked;
}

// ------------- errors

error ReentrancyNotPermitted();

/// @title Reentrancy Guard (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ReentrancyGuardUDS {
    ReentrancyGuardDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- modifier ------------- */

    modifier nonReentrant() {
        if (s().locked == 2) revert ReentrancyNotPermitted();

        s().locked = 2;

        _;

        s().locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct Implementation {
    address implAddress;
    bytes4[] selectors;
}

interface IAddressRelay {
    /**
     * @notice Returns the fallback implementation address
     */
    function fallbackImplAddress() external returns (address);

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external;

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external;

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(address _implAddress) external;

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address implAddress_);

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory impls_);

    /**
     * @notice Return all the fucntion selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory selectors_);

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(address _fallbackAddress) external;

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external;

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExchangeOperatorAddressList {
    /**
     * @notice Returns an integer representing the exchange a given operator address belongs to (0 if none)
     * @param _operatorAddress The operator address to map to an exchange
     */
    function operatorAddressToExchange(
        address _operatorAddress
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct BaseConfig {
    // Used to create a default HeyMint Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
    uint24 projectId;
    // If true, the default CORI subscription address will be used to enforce royalties with the Operator Filter Registry
    bool enforceRoyalties;
    // The royalty payout percentage in basis points
    uint16 royaltyBps;
    // If true, HeyMint fees will be charged for minting tokens
    bool heyMintFeeActive;
    // The address used to sign and validate presale mints
    address presaleSignerAddress;
    // The base URI for all token metadata
    string uriBase;
}

struct TokenConfig {
    uint16 tokenId;
    // Maximum supply of tokens that can be minted
    uint16 maxSupply;
    // If true tokens can be minted in the public sale
    bool publicSaleActive;
    // The price of a token in the public sale in 1/100,000 ETH - e.g. 1 = 0.00001 ETH, 100,000 = 1 ETH - multiply by 10^13 to get correct wei amount
    uint32 publicPrice;
    // The number of tokens that can be minted in the public sale per address
    uint8 publicMintsAllowedPerAddress;
    // If enabled, automatic start and stop times for the public sale will be enforced, otherwise ignored
    bool usePublicSaleTimes;
    // The automatic start time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleStartTime;
    // The automatic end time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
    uint32 publicSaleEndTime;
    // If true tokens can be minted in the presale
    bool presaleActive;
    // The price of a token in the presale in 1/100,000 ETH
    uint32 presalePrice;
    // Total number of tokens available for minting in the presale
    uint16 presaleMaxSupply;
    // The number of tokens that can be minted in the presale per address
    uint8 presaleMintsAllowedPerAddress;
    // The uri for this token (defaults to using uriBase if not set).
    string tokenUri;
    // If enabled, automatic start and stop times for the presale will be enforced, otherwise ignored
    bool usePresaleTimes;
    // The automatic start time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleStartTime;
    // The automatic end time for the presale (if usePresaleTimes is true and presaleActive is true)
    uint32 presaleEndTime;
    // Free claim
    address freeClaimContractAddress;
    uint16 mintsPerFreeClaim;
    bool freeClaimActive;
    // Burn to mint
    uint32 burnPayment;
    uint16 mintsPerBurn;
    bool burnClaimActive;
    // Soulbinding
    bool soulbindingActive;
    // If set, the UTC timestamp in seconds until which tokens are refundable for refundPrice
    uint32 refundEndsAt;
    // The amount returned to a user in a token refund in 1/100,000 ETH
    uint32 refundPrice;
}

struct AdvancedConfig {
    // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
    address royaltyPayoutAddress;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint16[] payoutBasisPoints;
    // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
    address[] payoutAddresses;
    // Permanenetly disables the ability to change payout addresses or basis points.
    bool payoutAddressesFrozen;
    // Custom addresses that are allowed to call the 'creditCardMint' function.
    address[] creditCardMintAddresses;
    // Soulbinding
    bool soulbindAdminTransfersPermanentlyDisabled;
    address soulboundAdminAddress;
    // The address where refunded tokens are returned. If not set, refunded tokens are sent to the contract owner.
    address refundAddress;
}

struct Data {
    // ============ BASE FUNCTIONALITY ============
    // All token ids on the contract
    uint16[] tokenIds;
    // HeyMint fee to be paid per minted token (if not set, defaults to defaultHeymintFeePerToken)
    uint256 heymintFeePerToken;
    // Keeps track of if advanced config settings have been initialized to prevent setting multiple times
    bool advancedConfigInitialized;
    // Keeps track of how many of each token have been minted.
    mapping(uint16 => uint16) totalSupply;
    // Keeps track of how many tokens each address has minted.
    mapping(address => mapping(uint16 => uint16)) tokensMintedByAddress;
    // If minting a token has been permanently disabled.
    mapping(uint16 => bool) tokenMintingPermanentlyDisabled;
    // Keeps track of token ids that have been used for free claim.
    mapping(uint16 => mapping(uint256 => bool)) tokenFreeClaimUsed;
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool soulboundAdminTransferInProgress;
    mapping(uint16 => bool) tokenMetadataFrozen;
    bool allMetadataFrozen;
}

struct BurnToken {
    // The contract address of the token to be burned
    address contractAddress;
    // The type of contract - 1 = ERC-721, 2 = ERC-1155
    uint8 tokenType;
    // The number of tokens to burn per mint
    uint8 tokensPerBurn;
    // The ID of the token on an ERC-1155 contract eligible for burn; unused for ERC-721
    uint16 tokenId;
}

library HeyMintStorage {
    struct State {
        string name;
        string symbol;
        BaseConfig cfg;
        mapping(uint16 => TokenConfig) tokens;
        mapping(uint16 => BurnToken[]) burnTokens;
        AdvancedConfig advCfg;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("heymint.launchpad.storage.erc1155");

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting Verification test tokens.
 */
contract EnumerableERC1155 is
    ERC1155Supply,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    using ECDSA for bytes32;

    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x0fE6E0D15E6F775138Ab556dE54B96d5C1358F3D;
    address public royaltyAddress = 0x7A4dF7B461f1bE3e88373a4d933aeefE2FAdcE71;
    address[] public payoutAddresses = [
        0xD3371FD388664Bd16A267788dbE977582B850f5b
    ];
    // Permanently freezes metadata for all tokens so they can never be changed
    bool public allMetadataFrozen = false;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    // The amount of tokens minted by a given address for a given token id
    mapping(address => mapping(uint256 => uint256))
        public tokensMintedByAddress;
    // Permanently freezes metadata for a specific token id so it can never be changed
    mapping(uint256 => bool) public tokenMetadataFrozen;
    // If true, the given token id can never be minted again
    mapping(uint256 => bool) public tokenMintingPermanentlyDisabled;
    mapping(uint256 => bool) public tokenPresaleSaleActive;
    mapping(uint256 => bool) public tokenPublicSaleActive;
    // If true, sale start and end times for the presale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePresaleTimes;
    // If true, sale start and end times for the public sale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePublicSaleTimes;
    mapping(uint256 => string) public tokenURI;
    // Maximum supply of tokens that can be minted for each token id. If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenMaxSupply;
    // If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenPresaleMaxSupply;
    mapping(uint256 => uint256) public tokenPresaleMintsPerAddress;
    mapping(uint256 => uint256) public tokenPresalePrice;
    mapping(uint256 => uint256) public tokenPresaleSaleEndTime;
    mapping(uint256 => uint256) public tokenPresaleSaleStartTime;
    mapping(uint256 => uint256) public tokenPublicMintsPerAddress;
    mapping(uint256 => uint256) public tokenPublicPrice;
    mapping(uint256 => uint256) public tokenPublicSaleEndTime;
    mapping(uint256 => uint256) public tokenPublicSaleStartTime;
    string public name = "Verification test";
    string public symbol = "VRT";
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 0;

    constructor()
        ERC1155(
            "ipfs://bafybeicin4rmb5y44r2a5jhwvobfgxutabetrttoi3u2po7pdymxt7dwdy/{id}"
        )
    {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        tokenPublicPrice[1] = 0.1 ether;
        tokenPublicMintsPerAddress[1] = 0;
        require(
            payoutAddresses.length == payoutBasisPoints.length,
            "PAYOUT_ARRAYS_NOT_SAME_LENGTH"
        );
        uint256 totalPayoutBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
            totalPayoutBasisPoints += payoutBasisPoints[i];
        }
        require(
            totalPayoutBasisPoints == 10000,
            "TOTAL_BASIS_POINTS_MUST_BE_10000"
        );
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
        _;
    }

    /**
     * @notice Returns a custom URI for each token id if set
     */
    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[_tokenId]).length == 0) {
            return super.uri(_tokenId);
        }
        return tokenURI[_tokenId];
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setURI(
        uint256 _tokenId,
        string calldata _newTokenURI
    ) external onlyOwner {
        require(
            !allMetadataFrozen && !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_BEEN_FROZEN"
        );
        tokenURI[_tokenId] = _newTokenURI;
    }

    /**
     * @notice Update the global default ERC-1155 base URI
     */
    function setGlobalURI(string calldata _newTokenURI) external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        _setURI(_newTokenURI);
    }

    /**
     * @notice Freeze metadata for a specific token id so it can never be changed again
     */
    function freezeTokenMetadata(uint256 _tokenId) external onlyOwner {
        require(
            !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_ALREADY_BEEN_FROZEN"
        );
        tokenMetadataFrozen[_tokenId] = true;
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
     */
    function freezeAllMetadata() external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        allMetadataFrozen = true;
    }

    /**
     * @notice Reduce the max supply of tokens for a given token id
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reduceMaxSupply(
        uint256 _tokenId,
        uint256 _newMaxSupply
    ) external onlyOwner {
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                _newMaxSupply < tokenMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        require(
            _newMaxSupply >= totalSupply(_tokenId),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        tokenMaxSupply[_tokenId] = _newMaxSupply;
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function permanentlyDisableTokenMinting(
        uint256 _tokenId
    ) external onlyOwner {
        tokenMintingPermanentlyDisabled[_tokenId] = true;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Allow owner to send tokens without cost to multiple addresses
     */
    function giftTokens(
        uint256 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external onlyOwner {
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMint += _mintNumber[i];
        }
        // require either no tokenMaxSupply set or tokenMaxSupply not maxed out
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + totalMint <= tokenMaxSupply[_tokenId],
            "MINT_TOO_LARGE"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mint(_receivers[i], _tokenId, _mintNumber[i], "");
        }
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting for a given token
     */
    function setTokenPublicSaleState(
        uint256 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        require(
            tokenPublicSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPublicSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the public mint price for a given token
     */
    function setTokenPublicPrice(
        uint256 _tokenId,
        uint256 _publicPrice
    ) external onlyOwner {
        tokenPublicPrice[_tokenId] = _publicPrice;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address for a given token
     */
    function setTokenPublicMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPublicMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPublicSaleStartTime(
        uint256 _tokenId,
        uint256 _publicSaleStartTime
    ) external onlyOwner {
        require(_publicSaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleStartTime[_tokenId] = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPublicSaleEndTime(
        uint256 _tokenId,
        uint256 _publicSaleEndTime
    ) external onlyOwner {
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleEndTime[_tokenId] = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePublicSaleTimes(
        uint256 _tokenId,
        bool _usePublicSaleTimes
    ) external onlyOwner {
        require(
            tokenUsePublicSaleTimes[_tokenId] != _usePublicSaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePublicSaleTimes[_tokenId] = _usePublicSaleTimes;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPublicSaleTimeIsActive(
        uint256 _tokenId
    ) public view returns (bool) {
        if (tokenUsePublicSaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPublicSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPublicSaleEndTime[_tokenId];
    }

    /**
     * @notice Allow for public minting of tokens for a given token
     */
    function mintToken(
        uint256 _tokenId,
        uint256 _numTokens
    ) external payable originalUser nonReentrant {
        require(tokenPublicSaleActive[_tokenId], "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPublicMintsPerAddress[_tokenId],
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <= tokenMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == tokenPublicPrice[_tokenId] * _numTokens,
            "PAYMENT_INCORRECT"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );

        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenMaxSupply[_tokenId]
        ) {
            tokenPublicSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting for a given token
     */
    function setTokenPresaleState(
        uint256 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        require(
            tokenPresaleSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPresaleSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price for a given token
     */
    function setTokenPresalePrice(
        uint256 _tokenId,
        uint256 _presalePrice
    ) external onlyOwner {
        tokenPresalePrice[_tokenId] = _presalePrice;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given address for a given token
     */
    function setTokenPresaleMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPresaleMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Reduce the presale max supply of tokens for a given token id
     * @param _newPresaleMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reducePresaleMaxSupply(
        uint256 _tokenId,
        uint256 _newPresaleMaxSupply
    ) external onlyOwner {
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                _newPresaleMaxSupply < tokenPresaleMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        tokenPresaleMaxSupply[_tokenId] = _newPresaleMaxSupply;
    }

    /**
     * @notice Update the start time for presale mint for a given token
     */
    function setTokenPresaleStartTime(
        uint256 _tokenId,
        uint256 _presaleStartTime
    ) external onlyOwner {
        require(_presaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleStartTime[_tokenId] = _presaleStartTime;
    }

    /**
     * @notice Update the end time for presale mint for a given token
     */
    function setTokenPresaleEndTime(
        uint256 _tokenId,
        uint256 _presaleEndTime
    ) external onlyOwner {
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleEndTime[_tokenId] = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic presale times for a given token
     */
    function setTokenUsePresaleTimes(
        uint256 _tokenId,
        bool _usePresaleTimes
    ) external onlyOwner {
        require(
            tokenUsePresaleTimes[_tokenId] != _usePresaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePresaleTimes[_tokenId] = _usePresaleTimes;
    }

    /**
     * @notice Returns if presale times are active for a given token
     */
    function tokenPresaleTimeIsActive(
        uint256 _tokenId
    ) public view returns (bool) {
        if (tokenUsePresaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPresaleSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPresaleSaleEndTime[_tokenId];
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        return
            presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable originalUser nonReentrant {
        require(tokenPresaleSaleActive[_tokenId], "PRESALE_IS_NOT_ACTIVE");
        require(
            tokenPresaleTimeIsActive(_tokenId),
            "PRESALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        require(
            tokenPresaleMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPresaleMintsPerAddress[_tokenId],
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _maximumAllowedMints == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <=
                tokenPresaleMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == tokenPresalePrice[_tokenId] * _numTokens,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints, _tokenId)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenPresaleMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenPresaleMaxSupply[_tokenId]
        ) {
            tokenPresaleSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Freeze all payout addresses and percentages so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_ALREADY_FROZEN");
        payoutAddressesFrozen = true;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint256[] calldata _payoutBasisPoints
    ) external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        require(
            _payoutAddresses.length == _payoutBasisPoints.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _payoutBasisPoints.length; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "TOTAL_BASIS_POINTS_MUST_BE_10000");
        payoutAddresses = _payoutAddresses;
        payoutBasisPoints = _payoutBasisPoints;
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 amount = (balance * payoutBasisPoints[i]) / 10000;
            (bool success, ) = payoutAddresses[i].call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }

    /**
     * @notice Override default ERC-1155 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Basic Enumerable ERC721 Contract
 * @author Ben Yu
 * @notice An ERC721Enumerable contract with basic functionality
 */
contract EnumerableERC721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 1000;

    string public baseTokenURI =
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/";
    bool public publicSaleActive;

    /**
     * @notice Initialize the contract
     */
    constructor() ERC721("Test Contract", "TEST") {
        // Start token IDs at 1
        supplyCounter.increment();
    }

    /**
     * @notice Override the default base URI function to provide a real base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allows for public minting of tokens
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint256 _mintNumber) external payable virtual {
        require(msg.value == PRICE * _mintNumber, "INVALID_PRICE");
        require((totalSupply() + _mintNumber) <= MAX_SUPPLY, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < _mintNumber; i++) {
            _safeMint(msg.sender, supplyCounter.current());
            supplyCounter.increment();
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     * @param _receivers Array of addresses to send tokens to
     * @param _mintNumber Number of tokens to send to each address
     */
    function gift(
        address[] calldata _receivers,
        uint256 _mintNumber
    ) external onlyOwner {
        require(
            (totalSupply() + (_receivers.length * _mintNumber)) <= MAX_SUPPLY,
            "MINT_TOO_LARGE"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            for (uint256 j = 0; j < _mintNumber; j++) {
                _safeMint(_receivers[i], supplyCounter.current());
                supplyCounter.increment();
            }
        }
    }

    /**
     * @notice Allow contract owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry when the init function is called.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    /// @notice Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

/**
 * @title  Upgradeable storage layout for RevokableOperatorFiltererUpgradeable.
 * @notice Upgradeable contracts must use a storage layout that can be used across upgrades.
 *         Only append new variables to the end of the layout.
 */
library RevokableOperatorFiltererUpgradeableStorage {
    struct Layout {
        /// @dev Whether the OperatorFilterRegistry has been revoked.
        bool _isOperatorFilterRegistryRevoked;
    }

    /// @dev The storage slot for the layout.
    bytes32 internal constant STORAGE_SLOT = keccak256("RevokableOperatorFiltererUpgradeable.contracts.storage");

    /// @dev The layout of the storage.
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently opt out of the OperatorFilterRegistry. The Registry
 *         itself has an "unregister" function, but if the contract is ownable, the owner can re-register at any point.
 *         As implemented, this abstract contract allows the contract owner to toggle the
 *         isOperatorFilterRegistryRevoked flag in order to permanently bypass the OperatorFilterRegistry checks.
 */
abstract contract RevokableOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    using RevokableOperatorFiltererUpgradeableStorage for RevokableOperatorFiltererUpgradeableStorage.Layout;

    error OnlyOwner();
    error AlreadyRevoked();

    event OperatorFilterRegistryRevoked();

    function __RevokableOperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe) internal {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(subscriptionOrRegistrantToCopy, subscribe);
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked
                && address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        if (RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked) {
            revert AlreadyRevoked();
        }
        RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked = true;
        emit OperatorFilterRegistryRevoked();
    }

    function isOperatorFilterRegistryRevoked() public view returns (bool) {
        return RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}