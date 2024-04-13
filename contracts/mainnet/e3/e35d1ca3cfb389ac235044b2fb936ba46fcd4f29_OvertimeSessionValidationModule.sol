// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ECDSA } from "solady/utils/ECDSA.sol";

import { IFactory } from "../interfaces/IFactory.sol";
import { IOvertimeUserFactory } from "../interfaces/IOvertimeUserFactory.sol";
import { ISessionValidationModule, UserOperation } from "../interfaces/ISessionValidationModule.sol";
import { ISmartAccount } from "../interfaces/ISmartAccount.sol";

/**
 * @dev This error is raised when the selector is not execute, execute_ncC, executeBatch or executeBatch_y6U
 */
error InvalidExecuteSelector();

/**
 * @dev This error is raised when the selector is not supported by the OvertimeUser contract
 */
error UnsupportedSelector();

/**
 * @dev This error is raised when the userOp is trying to send a non-zero value of ether in the call
 */
error NonZeroValue();

/**
 * @dev This error is raised when the amount is higher than the allowed one in the session
 */
error MaxAmount();

/**
 * @dev This error is raised when the destination contract is not the expected one
 */
error WrongDestination();

/**
 * @dev This error is raised when the slippage is higher than the expected one
 */
error Slippage();

/**
 * @title ERC20 Session Validation Module for Biconomy Smart Accounts.
 * @dev Validates userOps for ERC20 transfers and approvals using a session key signature.
 *         - Recommended to use with standard ERC20 tokens only
 *         - Can be used with any method of any contract which implement
 *           method(address, uint256) interface
 */
contract OvertimeSessionValidationModule is ISessionValidationModule {
    uint256 private constant SELECTOR_LENGTH = 4;

    constructor() { }

    /**
     * @dev validates that the call (destinationContract, callValue, funcCallData)
     * complies with the Session Key permissions represented by sessionKeyData
     * @param destinationContract address of the contract to be called
     * @param callValue value to be sent with the call
     * @param _funcCallData the data for the call. is parsed inside the SVM
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     * param _callSpecificData additional data, specific to the call, not used here
     * @return sessionKey address of the sessionKey that signed the userOp
     * for example to store a list of allowed tokens or receivers
     */
    function validateSessionParams(
        address destinationContract,
        uint256 callValue,
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData,
        bytes memory /*_callSpecificData*/
    )
        external
        pure
        virtual
        override
        returns (address)
    {
        return _validateSessionParams(destinationContract, callValue, _funcCallData, _sessionKeyData);
    }

    /**
     * @dev validates that the call (destinationContract, callValue, funcCallData)
     * complies with the Session Key permissions represented by sessionKeyData
     * @param destinationContract address of the contract to be called
     * @param callValue value to be sent with the call
     * @param _funcCallData the data for the call. is parsed inside the SVM
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     * @return sessionKey address of the sessionKey that signed the userOp
     * for example to store a list of allowed tokens or receivers
     */
    function _validateSessionParams(
        address destinationContract,
        uint256 callValue,
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData
    )
        internal
        pure
        virtual
        returns (address)
    {
        // Decode the session key data
        (address sessionKey, address factory,) = abi.decode(_sessionKeyData, (address, address, bytes));

        if (callValue != 0) {
            revert NonZeroValue();
        }

        if (destinationContract != factory) revert WrongDestination();

        bytes4 selector = bytes4(_funcCallData[0:4]);

        if (selector == IOvertimeUserFactory.buySingle.selector) {
            validateSingleBuy(_funcCallData, _sessionKeyData);
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.buySingleWithDifferentCollateral.selector) {
            validateSingleBuyDifferentCollateral(_funcCallData, _sessionKeyData);
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.buyParlay.selector) {
            validateParlayBuy(_funcCallData, _sessionKeyData);
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.buyParlayWithDifferentCollateral.selector) {
            validateParlayBuyDifferentCollateral(_funcCallData, _sessionKeyData);
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.exerciseSingle.selector) {
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.exerciseSingleWithDifferentCollateral.selector) {
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.exerciseParlay.selector) {
            return sessionKey;
        } else if (selector == IOvertimeUserFactory.exerciseParlayWithDifferentCollateral.selector) {
            return sessionKey;
        }

        revert UnsupportedSelector();
    }

    function validateSingleBuy(bytes calldata _funcCallData, bytes calldata _sessionKeyData) internal pure {
        (,,,, uint256 maxAmountNative, uint256 slippage) =
            abi.decode(_sessionKeyData, (address, address, address[], uint256[], uint256, uint256));

        (
            // address market
            ,
            // uint8 position
            ,
            // uint256 payout
            ,
            uint256 desiredAmount,
            uint256 additionalSlippage,
            // address referrer
        ) = abi.decode(_funcCallData[4:], (address, uint8, uint, uint, uint, address));

        if (desiredAmount > maxAmountNative) {
            revert MaxAmount();
        }

        if (additionalSlippage != slippage) {
            revert Slippage();
        }
    }

    function validateSingleBuyDifferentCollateral(
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData
    )
        internal
        pure
    {
        (,, address[] memory collaterals, uint256[] memory maxAmount,, uint256 slippage) =
            abi.decode(_sessionKeyData, (address, address, address[], uint256[], uint256, uint256));

        (
            // address market
            ,
            // uint8 position
            ,
            // uint256 payout
            ,
            uint256 desiredAmount,
            uint256 additionalSlippage,
            address collateral,
            // address referrer
        ) = abi.decode(_funcCallData[4:], (address, uint8, uint, uint, uint, address, address));

        uint256 maxAmountCollateral;
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i] == collateral) {
                maxAmountCollateral = maxAmount[i];
                break;
            }
        }

        if (desiredAmount > maxAmountCollateral) {
            revert MaxAmount();
        }

        if (additionalSlippage != slippage) {
            revert Slippage();
        }
    }

    function validateParlayBuy(bytes calldata _funcCallData, bytes calldata _sessionKeyData) internal pure {
        (,,,, uint256 maxAmountNative, uint256 slippage) =
            abi.decode(_sessionKeyData, (address, address, address[], uint256[], uint256, uint256));

        (
            // address[] memory sportMarkets
            ,
            // uint[] memory positions
            ,
            , // uint256 expectedPayout
            uint256 desiredAmount,
            uint256 additionalSlippage,
            // address referrer
        ) = abi.decode(_funcCallData[4:], (address[], uint256[], uint256, uint256, uint256, address));

        if (desiredAmount > maxAmountNative) {
            revert MaxAmount();
        }

        if (additionalSlippage > slippage) {
            revert Slippage();
        }
    }

    function validateParlayBuyDifferentCollateral(
        bytes calldata _funcCallData,
        bytes calldata _sessionKeyData
    )
        internal
        pure
    {
        (,,,, uint256 maxAmountNative, uint256 slippage) =
            abi.decode(_sessionKeyData, (address, address, address[], uint256[], uint256, uint256));

        (
            // address[] memory sportMarkets
            ,
            // uint[] memory positions
            ,
            , // uint256 expectedPayout
            uint256 desiredAmount,
            uint256 additionalSlippage,
            ,
            // address referrer
        ) = abi.decode(_funcCallData[4:], (address[], uint256[], uint256, uint256, uint256, address, address));

        if (desiredAmount > maxAmountNative) {
            revert MaxAmount();
        }

        if (additionalSlippage > slippage) {
            revert Slippage();
        }
    }

    /**
     * @dev validates if the _op (UserOperation) matches the SessionKey permissions
     * and that _op has been signed by this SessionKey
     * Please mind the decimals of your exact token when setting maxAmount
     * @param _op User Operation to be validated.
     * @param _userOpHash Hash of the User Operation to be validated.
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     * @param _sessionKeySignature Signature over the the _userOpHash.
     * @return true if the _op is valid, false otherwise.
     */
    function validateSessionUserOp(
        UserOperation calldata _op,
        bytes32 _userOpHash,
        bytes calldata _sessionKeyData,
        bytes calldata _sessionKeySignature
    )
        external
        view
        override
        returns (bool)
    {
        bytes4 selector = bytes4(_op.callData[0:4]);
        if (selector != EXECUTE_OPTIMIZED_SELECTOR && selector != EXECUTE_SELECTOR) {
            revert InvalidExecuteSelector();
        }

        bytes calldata callData = _op.callData;

        uint160 destContract;
        uint256 callValue;
        bytes calldata data;
        assembly {
            //offset of the first 32-byte arg is 0x4
            destContract := calldataload(add(callData.offset, SELECTOR_LENGTH))
            //offset of the second 32-byte arg is 0x24 = 0x4 (SELECTOR_LENGTH) + 0x20 (first 32-byte arg)
            callValue := calldataload(add(callData.offset, 0x24))

            //we get the data offset from the calldata itself, so no assumptions are made about the data layout
            let dataOffset :=
                add(
                    add(callData.offset, 0x04),
                    //offset of the bytes arg is stored after selector and two first 32-byte args
                    // 0x4+0x20+0x20=0x44
                    calldataload(add(callData.offset, 0x44))
                )

            let length := calldataload(dataOffset)
            //data itself starts after the length which is another 32bytes word, so we add 0x20
            data.offset := add(dataOffset, 0x20)
            data.length := length
        }

        return _validateSessionParams(address(destContract), callValue, data, _sessionKeyData)
            == ECDSA.recover(ECDSA.toEthSignedMessageHash(_userOpHash), _sessionKeySignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
///
/// @dev Note:
/// - The recovery functions use the ecrecover precompile (0x1).
/// - As of Solady version 0.0.68, the `recover` variants will revert upon recovery failure.
///   This is for more safety by default.
///   Use the `tryRecover` variants if you need to get the zero address back
///   upon recovery failure instead.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The signature is invalid.
    error InvalidSignature();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recover(bytes32 hash, bytes memory signature) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TRY-RECOVER OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // WARNING!
    // These functions will NOT revert upon recovery failure.
    // Instead, they will return the zero address upon recovery failure.
    // It is critical that the returned address is NEVER compared against
    // a zero address (e.g. an uninitialized address variable).

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

interface IFactory {
    function getUser(address wallet) external view returns (address);
    function isDeployed(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IOvertimeUserFactory {
    error MastercopyInitialized();
    error ParametersNotSet();
    error Slippage();

    event OvertimeUserCreated(address indexed wallet, address indexed owner);

    function buySingle(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external;
    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external;

    function buyParlay(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external;
    function buyParlayWithDifferentCollateral(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external;

    function exerciseSingle(address market) external;
    function exerciseSingleWithDifferentCollateral(address market, address collateral, bool toEth) external;

    function exerciseParlay(address market) external;
    function exerciseParlayWithDifferentCollateral(address market, address collateral, bool toEth) external;

    function setMastercopy(address _mastercopy) external;
    function createUser(address referrer) external returns (address clone);
    function getUser(address _owner) external view returns (address wallet);

    function isDeployed(address wallet) external view returns (bool);
    function isWrapper(address wallet) external view returns (bool);

    function resetVariables() external;
    function setFactoryVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external;

    function version() external view returns (uint256);
    function parametersVersion(address) external view returns (uint256);

    function sportsAMM() external view returns (address);
    function parlayMarketsAMM() external view returns (address);
    function overtimeReferrer() external view returns (address);
    function feeManager() external view returns (address);

    function susd() external view returns (address);
    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

abstract contract ISessionValidationModule {
    // execute(address,uint256,bytes)
    bytes4 public constant EXECUTE_SELECTOR = 0xb61d27f6;
    // execute_ncC(address,uint256,bytes)
    bytes4 public constant EXECUTE_OPTIMIZED_SELECTOR = 0x0000189a;

    /**
     * @dev validates if the _op (UserOperation) matches the SessionKey permissions
     * and that _op has been signed by this SessionKey
     * @param _op User Operation to be validated.
     * @param _userOpHash Hash of the User Operation to be validated.
     * @param _sessionKeyData SessionKey data, that describes sessionKey permissions
     * @param _sessionKeySignature Signature over the the _userOpHash.
     * @return true if the _op is valid, false otherwise.
     */
    function validateSessionUserOp(
        UserOperation calldata _op,
        bytes32 _userOpHash,
        bytes calldata _sessionKeyData,
        bytes calldata _sessionKeySignature
    )
        external
        virtual
        returns (bool);

    /**
     * @dev validates that the call (destinationContract, callValue, funcCallData)
     * complies with the Session Key permissions represented by sessionKeyData
     * @param destinationContract address of the contract to be called
     * @param callValue value to be sent with the call
     * @param funcCallData the data for the call.
     * is parsed inside the Session Validation Module (SVM)
     * @param sessionKeyData SessionKey data, that describes sessionKey permissions
     */
    function validateSessionParams(
        address destinationContract,
        uint256 callValue,
        bytes calldata funcCallData,
        bytes calldata sessionKeyData,
        bytes calldata callSpecificData
    )
        external
        virtual
        returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.20;

/* solhint-disable func-name-mixedcase */

interface ISmartAccount {
    /**
     * @dev Interface function with the standard name for execute_ncC
     * @param dest Address of the contract to call
     * @param value Amount of native tokens to send along with the transaction
     * @param func Data of the transaction
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * @dev Execute a transaction (called by entryPoint)
     * @notice Name is optimized for this method to be cheaper to be called
     * @param dest Address of the contract to call
     * @param value Amount of native tokens to send along with the transaction
     * @param func Data of the transaction
     */
    function execute_ncC(address dest, uint256 value, bytes calldata func) external;

    /**
     * @dev Interface function with the standard name for executeBatch_y6U
     * @param dest Addresses of the contracts to call
     * @param value Amounts of native tokens to send along with the transactions
     * @param func Data of the transactions
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;

    /**
     * @dev Execute a sequence of transactions
     * @notice Name is optimized for this method to be cheaper to be called
     * @param dest Addresses of the contracts to call
     * @param value Amounts of native tokens to send along with the transactions
     * @param func Data of the transactions
     */
    function executeBatch_y6U(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
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

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }