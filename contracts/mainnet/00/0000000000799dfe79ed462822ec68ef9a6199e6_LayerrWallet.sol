// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/**
 * @title LayerrWallet
 * @author 0xth0mas (Layerr)
 * @notice A multi-sig smart contract wallet with support for
 *         both transactions that are chain-specific and 
 *         transactions that are replayable on all chains that
 *         the contract is deployed on.
 */
contract LayerrWallet {

    /// @dev Defines call parameters for transactions 
    struct Call {
        uint256 nonce;
        address to;
        uint256 value;
        bytes data;
        uint256 gas;
    }

    /// @dev Thrown when non-address(this) attempts to call external functions that must be called from address(this)
    error InvalidCaller();

    /// @dev Thrown when signatures are supplied out of order, signatures must be supplied in ascending signer id order
    error SignaturesOutOfOrder();

    /// @dev Thrown when attempting to add a signer that already exists
    error AddressAlreadySigner();

    /// @dev Thrown when attempting to remove an address that is not currently a signer
    error AddressNotSigner();

    /**
     *  @dev Thrown when remove signer/threshold update would make it impossible to execute a transaction
     *       or when a transaction is submitted without enough signatures to meet the threshold.
     */
    error NotEnoughSigners();

    /// @dev Thrown when the supplied call's nonce is not the current nonce for the contract
    error InvalidNonce();

    /// @dev Thrown when attempting to call the add/remove signer and threshold functions with a chain-specific call
    error CannotCallSelf();

    /// @dev Thrown when the call results in a revert
    error CallFailed(); 

    /// @dev Emitted when removing a signer
    event SignerRemoved(address indexed signer);
    /// @dev Emitted when adding a signer
    event SignerAdded(address indexed signer, uint256 indexed signerId);

    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant CHAINLESS_EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,address verifyingContract)"
    );

    bytes32 constant CALL_TYPEHASH = keccak256(
        "Call(uint256 nonce,address to,uint256 value,bytes data,uint256 gas)"
    );

    bytes32 private immutable _cachedDomainSeparator;
    bytes32 private immutable _cachedChainlessDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    string private constant _name = "LayerrWallet";
    string private constant _version = "1.0";

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /// @dev mapping of signer addresses to their id, addresses with id of 0 are not valid signers
    mapping(address => uint256) public signerIds;

    /// @dev the minimum number of valid signatures to execute a transaction
    uint32 public minimumSignatures;

    /// @dev the number of signers that are currently authorized to sign a transaction
    uint32 public currentSigners;

    /// @dev the current nonce for transactions that can only be executed on a specific chain
    uint32 public chainCallNonce;

    /// @dev the current nonce for transactions that can be executed across all chains
    uint32 public chainlessCallNonce;

    /// @dev the signer id that will be given to the next signer added
    uint32 private nextSignerId;

    constructor() {
        _hashedName = keccak256(bytes(_name));
        _hashedVersion = keccak256(bytes(_version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedChainlessDomainSeparator = _buildChainlessDomainSeparator();
        _cachedThis = address(this);

        signerIds[0x3A366622378D846E8Fcee6F06F2f199Fb3349e9d] = 1;
        signerIds[0x1602B3707A9213A313bc21337Ae93c947b4929B4] = 2;
        signerIds[0x1C535EC3b6A2952eD9c8459d0a5A682aC847092D] = 3;
        signerIds[0x3C5E6B4292Ed35e8973400bEF77177A9e84e8E6e] = 4;
        currentSigners = 4;
        nextSignerId = 5;
        minimumSignatures = 2;
    }

    /**
     * @notice Chainless calls are not chain specific and can be replayed on any chain
     *         that the contract is deployed to.
     * @dev This is intended to be used for protocol updates that need to be applied 
     *      across all chains.
     * @param call struct containing the details of the call transaction to execute
     * @param signatures signatures to validate the call
     */
    function chainlessCall(Call calldata call, bytes[] calldata signatures) external {
        if(call.nonce != chainlessCallNonce) revert InvalidNonce();

        bytes32 callDigest = _getChainlessCallSignatureDigest(_getCallHash(call));

        uint256 lastSignerId;
        uint256 currentSignerId;
        uint256 validSignatures;

        for(uint256 signatureIndex;signatureIndex < signatures.length;) {
            currentSignerId = signerIds[_recoverCallSigner(callDigest, signatures[signatureIndex])];
            if(currentSignerId <= lastSignerId) revert SignaturesOutOfOrder();
            lastSignerId = currentSignerId;

            unchecked {
                ++validSignatures;
                ++signatureIndex;
            }
        }

        if(validSignatures < minimumSignatures) revert NotEnoughSigners();
        unchecked { ++chainlessCallNonce; }

        if(!_execute(call.to, call.value, call.data, call.gas)) { revert CallFailed(); }
    }

    /**
     * @notice Chain calls are chain specific and cannot be replayed to other chains.
     * @dev This is intended to be used for transactions that are chain-specific 
     *      such as treasury management where values and addresses that values are being
     *      sent to may differ from chain to chain.
     * @param call struct containing the details of the call transaction to execute
     * @param signatures signatures to validate the call
     */
    function chainCall(Call calldata call, bytes[] calldata signatures) external {
        if(call.nonce != chainCallNonce) revert InvalidNonce();
        if(call.to == address(this)) revert CannotCallSelf();

        bytes32 callDigest = _getCallSignatureDigest(_getCallHash(call));

        uint256 lastSignerId;
        uint256 currentSignerId;
        uint256 validSignatures;

        for(uint256 signatureIndex;signatureIndex < signatures.length;) {
            currentSignerId = signerIds[_recoverCallSigner(callDigest, signatures[signatureIndex])];
            if(currentSignerId <= lastSignerId) revert SignaturesOutOfOrder();
            lastSignerId = currentSignerId;

            unchecked {
                ++validSignatures;
                ++signatureIndex;
            }
        }

        if(validSignatures < minimumSignatures) revert NotEnoughSigners();
        unchecked { ++chainCallNonce; }

        if(!_execute(call.to, call.value, call.data, call.gas)) { revert CallFailed(); }
    }

    /**
     * @notice Adds a signer to the smart contract wallet
     * @dev This increments the number of current signers but does not change thresholds
     * @param signer address to add as a valid signer
     */
    function addSigner(address signer) external {
        if(msg.sender != address(this)) revert InvalidCaller();
        if(signerIds[signer] > 0) revert AddressAlreadySigner();

        uint256 newSignerId = nextSignerId;
        signerIds[signer] = newSignerId;

        unchecked {
            ++currentSigners;
            ++nextSignerId;
        }

        emit SignerAdded(signer, newSignerId);
    }

    /**
     * @notice Removes a signer from the smart contract wallet
     * @dev This decreases the number of current signers and validates that it will
     *      not create a situation where the threshold is greater than current signers
     * @param signer address to be removed as a signer
     */
    function removeSigner(address signer) external {
        if(msg.sender != address(this)) revert InvalidCaller();
        if(signerIds[signer] == 0) revert AddressNotSigner();

        signerIds[signer] = 0;

        unchecked {
            --currentSigners;
        }

        if(minimumSignatures > currentSigners) revert NotEnoughSigners();

        emit SignerRemoved(signer);
    }

    /**
     * @notice Sets the minimum number of signatures to execute a transaction
     * @dev This enforces minimum signatures > 0 and current signers > minimum
     * @param _minimumSignatures the threshold of valid signatures to execute a transaction
     */
    function setMinimumSignatures(uint256 _minimumSignatures) external {
        if(msg.sender != address(this)) revert InvalidCaller();

        if(_minimumSignatures == 0) revert NotEnoughSigners();
        if(_minimumSignatures > currentSigners) revert NotEnoughSigners();

        minimumSignatures = uint32(_minimumSignatures);
    }

    function _execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 gasAmount
    ) internal returns (bool success) {
        assembly {
            if iszero(gasAmount) {
                gasAmount := gas()
            }
            let ptr := mload(0x40)
            calldatacopy(ptr, data.offset, data.length)
            success := call(gasAmount, to, value, ptr, data.length, 0, 0)
        }
    }
    
    function _recoverCallSigner(
        bytes32 digest,
        bytes calldata signature
    ) internal pure returns (address signer) {
        signer = _recover(digest, signature);
    }

    function _getCallSignatureDigest(bytes32 callHash) internal view returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), callHash)
        );
    }

    function _getChainlessCallSignatureDigest(bytes32 callHash) internal view returns (bytes32 digest) {
        digest = keccak256(
            abi.encodePacked("\x19\x01", _chainlessDomainSeparator(), callHash)
        );
    }

    function _getCallHash(
        Call calldata call
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded = abi.encode(
            CALL_TYPEHASH,
            call.nonce,
            call.to,
            call.value,
            keccak256(call.data),
            call.gas
        );
        hash = keccak256(encoded);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparator() private view returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     * @dev Returns the chainless domain separator.
     */
    function _chainlessDomainSeparator() private view returns (bytes32 separator) {
        separator = _cachedChainlessDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildChainlessDomainSeparator();
        }
    }

    /**
     *  @dev Returns if the cached domain separator has been invalidated.
     */ 
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _buildChainlessDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CHAINLESS_EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    address(this)
                )
            );
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    fallback() external payable { }
    receive() external payable { }
}