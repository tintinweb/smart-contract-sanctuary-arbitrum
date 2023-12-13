/**
 *Submitted for verification at Arbiscan.io on 2023-12-12
*/

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(
        address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel
    );
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
        external
        payable
        returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet)
        external
        pure
        returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint256 numGuardians) external pure returns (uint256 numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade)
        external
        pure
        returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId)
        external
        pure
        returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

/// @title minimal interface for erc20 
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      This is a reduced version of the library.
 */

library BytesLib {
    uint256 private constant freeMemoryPtr = 0x40;
    uint256 private constant maskModulo32 = 0x1f;
    /**
     * Size of word read by `mload` instruction.
     */
    uint256 private constant memoryWord = 32;
    uint256 internal constant uint8Size = 1;
    uint256 internal constant uint16Size = 2;
    uint256 internal constant uint32Size = 4;
    uint256 internal constant uint64Size = 8;
    uint256 internal constant uint128Size = 16;
    uint256 internal constant uint256Size = 32;
    uint256 internal constant addressSize = 20;
    /**
     * Bits in 12 bytes.
     */
    uint256 private constant bytes12Bits = 96;

    function slice(bytes memory buffer, uint256 startIndex, uint256 length) internal pure returns (bytes memory) {
        unchecked {
            require(length + 31 >= length, "slice_overflow");
        }
        require(buffer.length >= startIndex + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly ("memory-safe") {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(freeMemoryPtr)

            switch iszero(length)
            case 0 {
                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(length, maskModulo32)
                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let startOffset := add(lengthmod, mul(memoryWord, iszero(lengthmod)))

                let dst := add(tempBytes, startOffset)
                let end := add(dst, length)

                for { let src := add(add(buffer, startOffset), startIndex) } lt(dst, end) {
                    dst := add(dst, memoryWord)
                    src := add(src, memoryWord)
                } { mstore(dst, mload(src)) }

                // Update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // Note that negating bitwise the `maskModulo32` produces a mask that aligns addressing to 32 bytes.
                mstore(freeMemoryPtr, and(add(dst, maskModulo32), not(maskModulo32)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default { mstore(freeMemoryPtr, add(tempBytes, memoryWord)) }

            // Store the length of the buffer
            // We need to do it even if the length is zero because Solidity does not garbage collect
            mstore(tempBytes, length)
        }

        return tempBytes;
    }

    function toAddress(bytes memory buffer, uint256 startIndex) internal pure returns (address) {
        require(buffer.length >= startIndex + addressSize, "toAddress_outOfBounds");
        address tempAddress;

        assembly ("memory-safe") {
            // We want to shift into the lower 12 bytes and leave the upper 12 bytes clear.
            tempAddress := shr(bytes12Bits, mload(add(add(buffer, memoryWord), startIndex)))
        }

        return tempAddress;
    }

    function toUint8(bytes memory buffer, uint256 startIndex) internal pure returns (uint8) {
        require(buffer.length > startIndex, "toUint8_outOfBounds");

        // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
        uint256 startOffset = startIndex + uint8Size;
        uint8 tempUint;
        assembly ("memory-safe") {
            tempUint := mload(add(buffer, startOffset))
        }
        return tempUint;
    }

    function toUint16(bytes memory buffer, uint256 startIndex) internal pure returns (uint16) {
        uint256 endIndex = startIndex + uint16Size;
        require(buffer.length >= endIndex, "toUint16_outOfBounds");

        uint16 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint32(bytes memory buffer, uint256 startIndex) internal pure returns (uint32) {
        uint256 endIndex = startIndex + uint32Size;
        require(buffer.length >= endIndex, "toUint32_outOfBounds");

        uint32 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint64(bytes memory buffer, uint256 startIndex) internal pure returns (uint64) {
        uint256 endIndex = startIndex + uint64Size;
        require(buffer.length >= endIndex, "toUint64_outOfBounds");

        uint64 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint128(bytes memory buffer, uint256 startIndex) internal pure returns (uint128) {
        uint256 endIndex = startIndex + uint128Size;
        require(buffer.length >= endIndex, "toUint128_outOfBounds");

        uint128 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint256(bytes memory buffer, uint256 startIndex) internal pure returns (uint256) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toUint256_outOfBounds");

        uint256 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toBytes32(bytes memory buffer, uint256 startIndex) internal pure returns (bytes32) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toBytes32_outOfBounds");

        bytes32 tempBytes32;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempBytes32 := mload(add(buffer, endIndex))
        }
        return tempBytes32;
    }
}

/// @title ProxyPayload provides replay-protected payload construction for relaying messages through wormhole
/// @dev regardless of the payload type, the format of data is always
/// @dev (_nonce, _emittingChainId, _payloadData) where _payloadData is payload specific
contract ProxyPayload {
    using BytesLib for bytes;
    /// address of the wormhole bridge contract deployed on the network
    address public immutable wormholeBridgeContract;
    /// the number of confirmations needed for the wormhole network to attest to a message
    uint8 public immutable wormholeFinality;
    /// @dev nonce is incremented for every message sent through wormhole
    /// @dev allows for replay protection of messages
    uint256 public nonce;
    /// @dev the chainId of the network this contract is deployed using wormhole's chainid standard
    /// @dev chainId reference https://github.com/wormhole-foundation/wormhole/blob/08455a7770f516265273cd67f6353116367490ae/sdk/rust/core/src/chain.rs#L9
    /// @dev used in combination with nonce for replay protection
    uint16 public immutable wormholeChainId;

    /// @dev PayloadType identifies the type of payload being sent through wormhole
    enum PayloadType {
        RegisterUserAccount,
        DepositFunds,
        WithdrawFunds,
        /// @dev used as a catch all for invalid messages
        None
    }

    /// @dev WormholeMessage bundles together a payload identifier, and payload contents to relay through wormhole
    struct WormholeMessage {
        /// @dev the payload type indicating the action to perform via the proxy auth program
        PayloadType payloadType;
        /// @dev the actual data being sent as the payload
        bytes data;
    }

    constructor(address _wormholeBridgContract, uint16 _wormholeChainId, uint8 _wormholeFinality) {
        wormholeChainId = _wormholeChainId;
        wormholeFinality = _wormholeFinality;
        wormholeBridgeContract = _wormholeBridgContract;
    }

    /// @notice encodes a wormhole message to register a user account
    /// @param _user the address of the user account being registered
    function newRegisterUserAccountMessage(address _user) public view returns (WormholeMessage memory) {
        return WormholeMessage({
            payloadType: PayloadType.RegisterUserAccount,
            data: abi.encodePacked(nonce, wormholeChainId, _user)
        });
    }

    /// @notice encodes a wormhole message to deposit funds for the user account
    /// @param _user the user depositing the funds
    /// @param _token the token that is being deposited
    /// @param _amount the amount of `_token` to deposit
    function newDepositFundsMessage(address _user, address _token, uint256 _amount) public view returns (WormholeMessage memory) {
        return WormholeMessage({
            payloadType: PayloadType.DepositFunds,
            data: abi.encodePacked(nonce, wormholeChainId, _user, _token, _amount)
        });
    }

    /// @notice encodes a wormhole message to withdraw funds from the user
    /// @param _user the user withdrawing the funds
    /// @param _token the token that is being withdrawn
    /// @param _amount the amount of `_token` to withdraw   
    function newWithdrawFundsMessage(address _user, address _token, uint256 _amount) public view returns (WormholeMessage memory) {
        return WormholeMessage({
            payloadType: PayloadType.WithdrawFunds,
            data: abi.encodePacked(nonce, wormholeChainId, _user, _token, _amount)
        });
    }

    /// @notice encodes a wormhole message to withdraw funds from the user and increments the global nonce
    /// @param _user the user withdrawing the funds
    /// @param _token the token that is being withdrawn
    /// @param _amount the amount of `_token` to withdraw   
    function encodeWithdrawFundsMessage(address _user, address _token, uint256 _amount) internal returns (WormholeMessage memory) {
        WormholeMessage memory message = newWithdrawFundsMessage(_user, _token, _amount);
        nonce += 1;
        return message;
    }

    /// @notice encodes a wormhole message to deposit funds for the user account and increments the global nonce
    /// @param _user the user depositing the funds
    /// @param _token the token that is being deposited
    /// @param _amount the amount of `_token` to deposit
    function encodeDepositFundsMessage(address _user, address _token, uint256 _amount) internal returns (WormholeMessage memory) {
        WormholeMessage memory message = newDepositFundsMessage(_user, _token, _amount);
        nonce += 1;
        return message;
    }

    /// @notice encodes a wormhole message to register a user account and increments the global nonce
    /// @param _user the address of the user account being registered
    function encodeRegisterUserAccountMessage(address _user) internal returns (WormholeMessage memory) {
        WormholeMessage memory message = newRegisterUserAccountMessage(_user);
        nonce += 1;
        return message;
    }

    /**
     * @notice Encodes the WormholeMessage struct into bytes
     * @param parsedMessage WormholeMessage struct with arbitrary HelloWorld message
     * @return encodedMessage WormholeMessage encoded into bytes
     */

    function encodeMessage(WormholeMessage memory parsedMessage) public pure returns (bytes memory encodedMessage) {
        // Convert message string to bytes so that we can use the .length attribute.
        // The length of the arbitrary messages needs to be encoded in the message
        // so that the corresponding decode function can decode the message properly.
        bytes memory encodedMessagePayload = abi.encodePacked(parsedMessage.data);

        // return the encoded message
        encodedMessage =
            abi.encodePacked(parsedMessage.payloadType, uint16(encodedMessagePayload.length), encodedMessagePayload);
    }

    /**
     * @notice Decodes bytes into WormholeMessage struct
     * @dev Verifies the payloadID
     * @param encodedMessage encoded arbitrary HelloWorld message
     * @return parsedMessage WormholeMessage struct with arbitrary WormholeMessage message
     */
    function decodeMessage(bytes memory encodedMessage) public pure returns (WormholeMessage memory parsedMessage) {
        // starting index for byte parsing
        uint256 index = 0;

        // parse and verify the payloadID
        parsedMessage.payloadType = PayloadType(encodedMessage.toUint8(index));
        require(parsedMessage.payloadType != PayloadType.None, "invalid payload");
        index += 1;

        // parse the message string length
        uint256 messageLength = encodedMessage.toUint16(index);
        index += 2;

        // parse the message string
        bytes memory messageBytes = encodedMessage.slice(index, messageLength);
        parsedMessage.data = messageBytes;
        index += messageLength;

        // confirm that the message was the expected length
        require(index == encodedMessage.length, "invalid message length");
    }

}

/// @title ProxyAuth provides authenticated execution of solana program instructions via wormhole
/// todo - restrict tokens that can be deposited
/// todo - restrict emitters
/// todo - add pending withdrawal queue
contract ProxyAuth is ProxyPayload {
    using BytesLib for bytes;

    /// address of the deployer and contract owner
    address internal immutable deployer;

    // tokens that are accepted for deposit
    mapping (address => bool) public allowedTokens;

    /// @dev identifies users that have registered via the proxy auth program
    /// @notice registration is set to true when the transaction sending the RegistUserAccount payload to wormhole is confirmed
    mapping (address => bool) public registeredUsers;
    /// @dev maps registerUserAddress => token => tokenBalance
    mapping (address => mapping(address => uint256)) public userDeposits;

    /**
     * Wormhole chain ID to known emitter address mapping. xDapps using
     * Wormhole should register all deployed contracts on each chain to
     * verify that messages being consumed are from trusted contracts.
     */
    mapping(uint16 => bytes32) registeredEmitters;

    // verified message hash to received message mapping
    mapping(bytes32 => bytes) receivedMessages;

    // verified message hash to boolean
    mapping(bytes32 => bool) consumedMessages;

    constructor(address _wormholeBridgContract, uint16 _wormholeChainId, uint8 _wormholeFinality) ProxyPayload(
        _wormholeBridgContract, _wormholeChainId, _wormholeFinality
    ) {
        deployer = msg.sender;
    }

    function setAllowedTokens(address _token) external {
        require(msg.sender == deployer, "not_deployer");
        allowedTokens[_token] = true;
    }

    function registerUserAccount() public returns (uint64 messageSequence) {
        // TODO: restrict access to msg.sender
        require(!registeredUsers[msg.sender], "already_registered");
        
        WormholeMessage memory message = encodeRegisterUserAccountMessage(msg.sender);

        // skip for now as its not possible for this to happen
        // enforce a max size for the arbitrary message
        //require(abi.encodePacked(_message).length < type(uint16).max, "message too large");

        IWormhole wormhole = IWormhole(wormholeBridgeContract);
        uint256 wormholeFee = wormhole.messageFee();

        /// encode the message into the wire format used for relaying through wormhole
        bytes memory encodedMessage = encodeMessage(message);

        // set registration status before sending the message
        registeredUsers[msg.sender] = true;

        // Send the user registration message by calling publishMessage on the
        // Wormhole core contract and paying the Wormhole protocol fee.
        messageSequence = wormhole.publishMessage{value: wormholeFee}(
            0, // batchID
            encodedMessage,
            wormholeFinality
        );
    }

    function depositFunds(address _token, uint256 _amount) public returns (uint64 messageSequence) {
        require(registeredUsers[msg.sender], "not_registered");
        require(allowedTokens[_token], "token_not_allowed");

        // todo: enable this during production
        // transfer tokens to the contract
        //IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // increment their balance
        userDeposits[msg.sender][_token] += _amount;

        WormholeMessage memory message = encodeDepositFundsMessage(msg.sender, _token, _amount);
        
        // skip for now as its not possible for this to happen
        // enforce a max size for the arbitrary message
        //require(abi.encodePacked(_message).length < type(uint16).max, "message too large");

        IWormhole wormhole = IWormhole(wormholeBridgeContract);
        uint256 wormholeFee = wormhole.messageFee();

        // encode the message into the wire format used for relaying through wormhole
        bytes memory encodedMessage = encodeMessage(message);

        // Send the deposit funds message by calling publishMessage on the
        // Wormhole core contract and paying the Wormhole protocol fee.
        messageSequence = wormhole.publishMessage{value: wormholeFee}(
            0, // batchID
            encodedMessage,
            wormholeFinality
        );
    }

    function withdrawFunds(address _token, uint256 _amount) public returns (uint64 messageSequence) {
        
        require(registeredUsers[msg.sender], "not_registered");
        require(allowedTokens[_token], "token_not_allowed");
        
        // decrement their balance
        userDeposits[msg.sender][_token] -= _amount;

        WormholeMessage memory message = encodeWithdrawFundsMessage(msg.sender, _token, _amount);

        // skip for now as its not possible for this to happen
        // enforce a max size for the arbitrary message
        //require(abi.encodePacked(_message).length < type(uint16).max, "message too large");

        IWormhole wormhole = IWormhole(wormholeBridgeContract);
        uint256 wormholeFee = wormhole.messageFee();

        bytes memory encodedMessage = encodeMessage(message);

        // Send the withdraw funds message by calling publishMessage on the
        // Wormhole core contract and paying the Wormhole protocol fee.
        messageSequence = wormhole.publishMessage{value: wormholeFee}(
            0, // batchID
            encodedMessage,
            wormholeFinality
        );
    }

    /**
     * @notice Consumes arbitrary HelloWorld messages sent by registered emitters
     * @dev The arbitrary message is verified by the Wormhole core endpoint
     * `verifyVM`.
     * Reverts if:
     * - `encodedMessage` is not attested by the Wormhole network
     * - `encodedMessage` was sent by an unregistered emitter
     * - `encodedMessage` was consumed already
     * @param encodedMessage verified Wormhole message containing arbitrary
     * HelloWorld message.
     */
    function receiveMessage(bytes memory encodedMessage) public {
        // call the Wormhole core contract to parse and verify the encodedMessage
        (IWormhole.VM memory wormholeMessage, bool valid, string memory reason) =
            IWormhole(wormholeBridgeContract).parseAndVerifyVM(encodedMessage);

        // confirm that the Wormhole core contract verified the message
        require(valid, reason);

        // verify that this message was emitted by a registered emitter
        require(verifyEmitter(wormholeMessage), "unknown emitter");

        // decode the message payload into the WormholeMessage struct
        WormholeMessage memory parsedMessage = decodeMessage(wormholeMessage.payload);

        /**
         * Check to see if this message has been consumed already. If not,
         * save the parsed message in the receivedMessages mapping.
         *
         * This check can protect against replay attacks in xDapps where messages are
         * only meant to be consumed once.
         */
        require(!isMessageConsumed(wormholeMessage.hash), "message already consumed");
        consumeMessage(wormholeMessage.hash, parsedMessage.data);
    }

    /**
     * @notice Registers foreign emitters (HelloWorld contracts) with this contract
     * @dev Only the deployer (owner) can invoke this method
     * @param emitterChainId Wormhole chainId of the contract being registered
     * See https://book.wormhole.com/reference/contracts.html for more information.
     * @param emitterAddress 32-byte address of the contract being registered. For EVM
     * contracts the first 12 bytes should be zeros.
     */
    function registerEmitter(uint16 emitterChainId, bytes32 emitterAddress) public {
        require(msg.sender == deployer);
        // sanity check the emitterChainId and emitterAddress input values
        require(
            emitterChainId != 0 && emitterChainId != wormholeChainId, "emitterChainId cannot equal 0 or this chainId"
        );
        require(emitterAddress != bytes32(0), "emitterAddress cannot equal bytes32(0)");

        // update the registeredEmitters state variable
        setEmitter(emitterChainId, emitterAddress);
    }

    function getRegisteredEmitter(uint16 emitterChainId) public view returns (bytes32) {
        return registeredEmitters[emitterChainId];
    }

    function isMessageConsumed(bytes32 hash) public view returns (bool) {
        return consumedMessages[hash];
    }

    function isUserRegistered(address _user) public view returns (bool) { return registeredUsers[_user]; }

    function depositedFunds(address _user, address _token) public view returns (uint256) {
        return userDeposits[_user][_token];
    }

    function consumeMessage(bytes32 hash, bytes memory message) internal {
        receivedMessages[hash] = message;
        consumedMessages[hash] = true;
    }

    function setEmitter(uint16 chainId, bytes32 emitter) internal {
        registeredEmitters[chainId] = emitter;
    }

    function verifyEmitter(IWormhole.VM memory vm) internal view returns (bool) {
        // Verify that the sender of the Wormhole message is a trusted
        // HelloWorld contract.
        return getRegisteredEmitter(vm.emitterChainId) == vm.emitterAddress;
    }
}