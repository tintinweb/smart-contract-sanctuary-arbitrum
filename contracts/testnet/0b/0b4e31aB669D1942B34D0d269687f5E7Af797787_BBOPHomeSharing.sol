/**
 *Submitted for verification at Arbiscan on 2023-01-12
*/

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// File contracts/BBOPHomeSharing.sol

// import openzeppelin contracts for utils address and signature

contract BBOPHomeSharing {
    // contract owner (BBOP)
    address private administrator;

    event storePayment(
        address indexed _from,
        uint256 _amount,
        uint256 _timestamp,
        string _identifier
    );

    enum State {
        Created,
        Locked,
        Released,
        Inactive,
        Refunded,
        Cancelled,
        Paid,
        InProgress,
        Dispute
    }

    // Payer Entity
    struct Payer {
        string identifier;
        uint256 amount;
        address hostAddress;
        address payerAddress;
        bool isHostSigned;
        bool isPayerSigned;
        uint256 deposit;
        State state;
    }

    // create a mapping to store the address that send the request, the amount of the request and a identifier received from the request
    mapping(string => Payer) public bookingsPayedTransactions;

    // modifier condition(bool condition_) {
    //     require(condition_);
    //     _;
    // }

    constructor() {
        administrator = msg.sender;
    }

    // function to receive the payment from the user and store the amount and the identifier in the mapping
    function logPayedBooking(
        uint256 _amount,
        string memory _identifier,
        address _hostAddress,
        bool _isHostSigned,
        bool _isPayerSigned,
        uint256 _deposit
    ) internal {
        bookingsPayedTransactions[_identifier] = Payer(
            _identifier,
            _amount,
            _hostAddress,
            msg.sender,
            _isHostSigned,
            _isPayerSigned,
            _deposit,
            State.Paid
        );

        emit storePayment(msg.sender, _amount, block.timestamp, _identifier);
    }

    // function to receive the payment to the contract and log the payment in the mapping
    function payBooking(
        string memory _identifier,
        address _hostAddress,
        uint256 _deposit
    ) external payable {
        require(
            msg.value > 0,
            "You need to send some Ether, in order to pay for booking"
        );
        // Require that the identifier is not already in the mapping
        require(
            bookingsPayedTransactions[_identifier].amount == 0,
            "The booking is already payed"
        );

        // extract the deposit from the amount and store the deposit in the mapping
        logPayedBooking(
            msg.value,
            _identifier,
            _hostAddress,
            false,
            false,
            _deposit
        );
    }

    // function to return all the values stored in the mapping if the user is the owner of the contract
    function getPayedBookingDetails(string memory _identifier)
        public
        view
        returns (Payer memory)
    {
        Payer memory payerOfbooking = bookingsPayedTransactions[_identifier];
        return payerOfbooking;
    }

    // function to take the amount from the contract and send it to the host address using the identifier received from the request and the
    // user address using openzeppelin address and signature --> PAYOUT
    function payoutToHost(string memory _identifier, bytes memory _signature)
        public
    {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.payerAddress ==
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(abi.encodePacked(_identifier))
                    ),
                    _signature
                ),
            "The information provided is not correct, signature does not match"
        );

        // require to check if the transaction is already paid and InProgress
        require(
            payerOfbooking.state == State.InProgress,
            "The transaction is not locked or already paid"
        );

        // require to check if the booking was signed by the host
        require(
            payerOfbooking.isHostSigned == true,
            "The booking was not signed by the host"
        );

        // send payment to host
        payable(payerOfbooking.hostAddress).transfer(payerOfbooking.amount);

        // send deposit to payer
        payable(payerOfbooking.payerAddress).transfer(payerOfbooking.deposit);

        payerOfbooking.state = State.Released;
    }

    // sign the transaction from the host and change the value of the isHostSigned to true in the mapping if the identifier is the same received from the request
    // and the user address is the same as the host address
    function signBookingFromHost(
        string memory _identifier,
        bytes memory _signature
    ) public {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.hostAddress ==
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(abi.encodePacked(_identifier))
                    ),
                    _signature
                ),
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.state == State.Paid,
            "The booking is not in paid state"
        );
        payerOfbooking.isHostSigned = true;
        payerOfbooking.state = State.InProgress;
    }

    // method that receive a signature from the contract owner and change the state of the booking to released and send the amount to the host address
    function releaseBookingByAdmin(
        string memory _identifier,
        bytes memory _signature
    ) public {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            administrator ==
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(abi.encodePacked(_identifier))
                    ),
                    _signature
                ),
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.state == State.InProgress,
            "The booking is not in Payour in Progress state"
        );
        payable(payerOfbooking.hostAddress).transfer(payerOfbooking.amount);
        payerOfbooking.state = State.Released;
    }

    function releaseBookingByAdminV2(string memory _identifier) public payable {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            administrator == msg.sender,
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.state == State.InProgress,
            "The booking is not in Payour in Progress state"
        );

        require(
            payerOfbooking.isHostSigned || payerOfbooking.isHostSigned,
            "A signature is required for Host or Guest"
        );

        payable(payerOfbooking.hostAddress).transfer(payerOfbooking.amount);
        payerOfbooking.state = State.Released;
    }

    function signAndPayoutGuest(string memory _identifier) public payable {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        // check if the booking is Released
        require(
            payerOfbooking.state != State.Released,
            "Booking was released already"
        );
        require(
            payerOfbooking.state == State.InProgress,
            "The booking is not in InProgress state"
        );
        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.payerAddress == msg.sender,
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.isHostSigned == true,
            "The booking was not signed by the host"
        );

        payerOfbooking.isPayerSigned = true;
        payerOfbooking.state = State.Released;

        // extract the amount from the booking minus the deposit
        uint256 amountToPay = payerOfbooking.amount - payerOfbooking.deposit;

        // release the amount to the host
        payable(payerOfbooking.hostAddress).transfer(amountToPay);
        // send deposit to payer
        payable(payerOfbooking.payerAddress).transfer(payerOfbooking.deposit);
    }

    function signAndPayoutHost(string memory _identifier) public payable {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        // check if the booking is Released
        require(
            payerOfbooking.state != State.Released,
            "Booking was released already"
        );
        require(
            payerOfbooking.state == State.InProgress,
            "The booking is not in InProgress state"
        );
        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.hostAddress == msg.sender,
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.isPayerSigned == true,
            "The booking was not signed by the guest"
        );

        payerOfbooking.isHostSigned = true;
        payerOfbooking.state = State.Released;

        // extract the amount from the booking minus the deposit
        uint256 amountToPay = payerOfbooking.amount - payerOfbooking.deposit;

        // release the amount to the host
        payable(payerOfbooking.hostAddress).transfer(amountToPay);
        // send deposit to payer
        payable(payerOfbooking.payerAddress).transfer(payerOfbooking.deposit);
    }

    // method were the Host Sign the transaction and the state of booking is updated to InProgress
    function signBookingFromHostV2(string memory _identifier) public {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.hostAddress == msg.sender,
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.state == State.Paid,
            "The booking is not in paid state"
        );
        payerOfbooking.isHostSigned = true;
        payerOfbooking.state = State.InProgress;
    }

    // method were the Guest Sign the transaction and the state of booking is updated to InProgress
    function signBookingFromGuest(string memory _identifier) public {
        // select the Payer from the mapping using the string received from the request
        Payer storage payerOfbooking = bookingsPayedTransactions[_identifier];

        require(
            keccak256(abi.encodePacked(payerOfbooking.identifier)) ==
                keccak256(abi.encodePacked(_identifier)),
            "The information provided is not correct, identifier does not match"
        );
        require(
            payerOfbooking.payerAddress == msg.sender,
            "The information provided is not correct, signature does not match"
        );
        require(
            payerOfbooking.state == State.Paid,
            "The booking is not in paid state"
        );

        require(
            payerOfbooking.isHostSigned == false,
            "You should use the correct method to release the payment"
        );

        payerOfbooking.isPayerSigned = true;
        payerOfbooking.state = State.InProgress;
    }
}