/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ISocket {
    /**
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint256 transmissionFees;
        uint256 switchboardFees;
        uint256 executionFee;
    }

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (bytes32 msgId);

    struct MessageDetails {
        bytes32 msgId;
        uint256 executionFee;
        uint256 msgGasLimit;
        bytes payload;
        bytes decapacitorProof;
    }

    /**
     * @notice executes a message
     * @param packetId packet id
     * @param localPlug local plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        bytes32 packetId,
        address localPlug,
        ISocket.MessageDetails calldata messageDetails_,
        bytes memory signature
    ) external;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    function getPlugConfig(
        address plugAddress_,
        uint256 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        );

    /**
     * @notice returns chain slug
     * @return chainSlug current chain slug
     */
    function chainSlug() external view returns (uint256 chainSlug);

    function capacitors__(address, uint256) external view returns (address);

    function decapacitors__(address, uint256) external view returns (address);

    function messageCount() external view returns (uint256);

    function packetIdRoots(bytes32 packetId_) external view returns (bytes32);

    function rootProposedAt(bytes32 packetId_) external view returns (uint256);

    function messageExecuted(bytes32 msgId_) external view returns (bool);
}

abstract contract PlugBase {
    address public owner;
    ISocket public socket;

    constructor(address socket_) {
        owner = msg.sender;
        socket = ISocket(socket_);
    }

    //
    // Modifiers
    //
    modifier onlyOwner() {
        require(msg.sender == owner, "no auth");
        _;
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        socket.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(
        uint256 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes memory payload_
    ) internal {
        socket.outbound{value: fees_}(chainSlug_, gasLimit_, payload_);
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;

    function _getChainSlug() internal view returns (uint256) {
        return socket.chainSlug();
    }

    // owner related functions

    function removeOwner() external onlyOwner {
        owner = address(0);
    }
}

interface IExecutionManager {
    function isExecutor(
        bytes32 packedMessage,
        bytes memory sig
    ) external view returns (address, bool);

    function payFees(uint256 msgGasLimit, uint32 dstSlug) external payable;

    function getMinFees(
        uint256 msgGasLimit,
        uint32 dstSlug
    ) external view returns (uint256);

    function updateExecutionFees(
        address executor,
        uint256 executionFees,
        bytes32 msgId
    ) external;
}

interface IGasPriceOracle {
    function relativeGasPrice(
        uint32 dstChainSlug
    ) external view returns (uint256);

    function sourceGasPrice() external view returns (uint256);
}

interface ITransmitManager {
    function checkTransmitter(
        uint32 siblingSlug,
        bytes32 digest,
        bytes calldata signature
    ) external view returns (address, bool);

    function sealGasLimit() external view returns (uint256);
}

interface ISwitchboard {
    function registerCapacitor(
        uint256 siblingChainSlug_,
        address capacitor_,
        uint256 maxPacketSize_
    ) external;

    function allowPacket(
        bytes32 root,
        bytes32 packetId,
        uint32 srcChainSlug,
        uint256 proposeTime
    ) external view returns (bool);

    function getMinFees(
        uint32 dstChainSlug_
    ) external view returns (uint256, uint256);
}

interface ICapacitor {
    /**
     * @notice emits the message details when it arrives
     * @param packedMessage the message packed with payload, fees and config
     * @param packetCount an incremental id assigned to each new packet
     * @param newRootHash the packed message hash (to be replaced with the root hash of the merkle tree)
     */
    event MessageAdded(
        bytes32 packedMessage,
        uint64 packetCount,
        bytes32 newRootHash
    );

    /**
     * @notice adds the packed message to a packet
     * @dev this should be only executable by socket
     * @dev it will be later replaced with a function adding each message to a merkle tree
     * @param packedMessage the message packed with payload, fees and config
     */
    function addPackedMessage(bytes32 packedMessage) external;

    /**
     * @notice returns the latest packet details which needs to be sealed
     * @return root root hash of the latest packet which is not yet sealed
     * @return packetCount latest packet id which is not yet sealed
     */
    function getNextPacketToBeSealed()
        external
        view
        returns (bytes32 root, uint64 packetCount);

    /**
     * @notice returns the root of packet for given id
     * @param id the id assigned to packet
     * @return root root hash corresponding to given id
     */
    function getRootByCount(uint64 id) external view returns (bytes32 root);

    /**
     * @notice seals the packet
     * @dev also indicates the packet is ready to be shipped and no more messages can be added now.
     * @dev this should be executable by socket only
     * @return root root hash of the packet
     * @return packetCount id of the packed sealed
     */
    function sealPacket(
        uint256 batchSize_
    ) external returns (bytes32 root, uint64 packetCount);

    function getLatestPacketCount() external view returns (uint256);
}

interface IKing {
    function king() external view returns (address);
}

interface IGimmeMonies {
    function sendMonies(bytes calldata) external;
}

interface IRandom {
    function guess(bytes calldata) external returns (uint256);
}

contract CommonPlug is PlugBase {
    // Egg Types
    bytes32 public constant STEPPER = keccak256(abi.encode("STEPPER"));
    bytes32 public constant MAKE_IT_RAIN =
        keccak256(abi.encode("MAKE_IT_RAIN"));
    bytes32 public constant ORDER_CHECK = keccak256(abi.encode("ORDER_CHECK"));
    bytes32 public constant KING = keccak256(abi.encode("KING"));
    bytes32 public constant TRAVELLER = keccak256(abi.encode("TRAVELLER"));
    bytes32 public constant WINDOW = keccak256(abi.encode("WINDOW"));
    bytes32 public constant ADDRESS_ASSEMBLE =
        keccak256(abi.encode("ADDRESS_ASSEMBLE"));
    bytes32 public constant GIMME_MONIES =
        keccak256(abi.encode("GIMME_MONIES"));
    bytes32 public constant RANDOM = keccak256(abi.encode("RANDOM"));
    bytes32 public constant SIG_MAKER = keccak256(abi.encode("SIG_MAKER"));
    bytes32 public constant SIMILAR_DEPLOYER =
        keccak256(abi.encode("SIMILAR_DEPLOYER"));
    bytes32 public constant BLOCK_HASH_CHAIN =
        keccak256(abi.encode("BLOCK_HASH_CHAIN"));
    bytes32 public constant GATED_COUNT = keccak256(abi.encode("GATED_COUNT"));
    bytes32 public constant POISON_PILL = keccak256(abi.encode("POISON_PILL"));
    bytes32 public constant IMBALANCE = keccak256(abi.encode("IMBALANCE"));

    // STEPPER
    bytes32 constant STEPPER_ADD = keccak256(abi.encode("ADD"));
    bytes32 constant STEPPER_SUB = keccak256(abi.encode("SUB"));
    uint256 public stepper_count = 10;

    // GATED_COUNT
    bytes32 constant OPEN_GATE = keccak256(abi.encode("OPEN"));
    bytes32 constant INCREASE_COUNT = keccak256(abi.encode("INCREASE"));
    bool public isGateOpen = true;
    uint256 public gated_count = 10;

    // POISON_PILL
    mapping(address => mapping(address => bool)) public poisonPill_codes;

    // MAKE_IT_RAIN
    mapping(uint256 => mapping(address => uint256))
        public makeItRain_executionCounts;

    // Block Hash Chain
    // sender -> (srcChainSlug -> blockNumber -> blockHash)
    mapping(address => mapping(uint256 => mapping(uint256 => bytes32)))
        public blockHashChain_blockHashes;

    // ORDER_CHECK
    mapping(uint256 => uint256) public orderCheck_timestamps;

    // KING
    address public king;

    // TRAVELLER
    mapping(address => string) public traveller_messages;

    // WINDOW
    uint256 public window_startBlock;

    // ASSEMBLE
    mapping(address => bytes32) public assemble_assembledAddress;

    // Random
    mapping(uint256 => address) public random_guesser;

    // SIG MAKER
    mapping(address => uint8) public sigMaker_v;
    mapping(address => bytes32) public sigMaker_r;
    mapping(address => bytes32) public sigMaker_s;

    //  SIMILAR_DEPLOYER
    mapping(address => address) public similarDeployer_address;

    // IMBALANCE
    uint256  public imbalance_count;

    constructor(address socket_) PlugBase(socket_) {}

    // Common outbound
    function outbound(
        uint256 toChainSlug_,
        uint256 dstGasLimit,
        bytes32 eggType,
        bytes calldata data
    ) external payable {
        require(
            eggType != TRAVELLER && eggType != BLOCK_HASH_CHAIN,
            "Use the outbound function of traveller"
        );
        bytes memory newdata = abi.encode(eggType, msg.sender, data);
        _outbound(toChainSlug_, dstGasLimit, msg.value, newdata);
    }

    // IMBALANCE
    receive() external payable {}
    function imbalance_claim() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _imbalance_receiveInbound(
        uint256,
        address,
        bytes memory
    ) internal {
        if (imbalance_count == 0) {
            imbalance_count = 1;
        }
        if (address(this).balance > 0) {
            imbalance_count *= 2;
        } else {
            imbalance_count -= 1;
        }
    }

    // STEPPER
    // function stepper_outbound(uint256 toChainSlug_, uint256 dstGasLimit, bytes calldata data) external payable {
    //     _outbound(toChainSlug_, dstGasLimit, msg.value, data);
    // }

    function _stepper_receiveInbound(
        uint256,
        address sender,
        bytes memory payload
    ) internal {
        bytes32 op = abi.decode(payload, (bytes32));
        unchecked {
            if (op == STEPPER_ADD) stepper_count++;
            else stepper_count--;
        }
    }

    // MAKE_IT_RAIN
    function _makeItRain_receiveInbound(
        uint256,
        address sender,
        bytes memory
    ) internal {
        makeItRain_executionCounts[block.number][sender]++;
    }

    // function makeItRain_outbound(
    //     uint256 chainSlug_,
    //     uint256 gasLimit,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(chainSlug_, gasLimit, msg.value, data);
    // }

    // ORDER_CHECK
    function _orderCheck_receiveInbound(
        uint256 siblingChainSlug_,
        address,
        bytes memory
    ) internal {
        orderCheck_timestamps[siblingChainSlug_] = block.timestamp;
    }

    // function orderCheck_outbound(
    //     uint256 chainSlug_,
    //     uint256 gasLimit,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(chainSlug_, gasLimit, msg.value, data);
    // }

    // KING
    // function king_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _king_receiveInbound(
        uint256,
        address,
        bytes memory data
    ) internal {
        address impl = abi.decode(data, (address));
        king = IKing(impl).king();
    }

    // TRAVALLER
    function getChainString(uint256 type_) public view returns (string memory) {
        if (block.chainid == 137) {
            if (type_ == 1) return "POLYGON";
            if (type_ == 2) return "SO";
        } else if (block.chainid == 42161) {
            if (type_ == 1) return "ARBITRUM";
            if (type_ == 2) return "CK";
        } else if (block.chainid == 56) {
            if (type_ == 1) return "BSC";
            if (type_ == 2) return "ET";
        } else if (block.chainid == 10) {
            if (type_ == 1) return "OPTIMISM";
            if (type_ == 2) return "!";
        } else {
            return "ETHEREUM";
        }
    }

    function _travaller_outbound(
        uint256 toChainSlug_,
        uint256 dstGasLimit_,
        uint256 type_
    ) external payable {
        if (bytes(traveller_messages[msg.sender]).length == 0)
            traveller_messages[msg.sender] = getChainString(type_);

        bytes memory payload = abi.encode(type_, traveller_messages[msg.sender]);
            
        _outbound(
            toChainSlug_,
            dstGasLimit_,
            msg.value,
            abi.encode(
                TRAVELLER,
                msg.sender,
                payload
            )
        );
    }

    function _traveller_receiveInbound(
        uint256,
        address sender,
        bytes memory data
    ) internal {
        (uint256 type_, string memory decodedString) = abi.decode(
            data,
            (uint256, string)
        );
        if (type_ == 0) traveller_messages[sender] = "";
        else
            traveller_messages[sender] = string.concat(
                decodedString,
                getChainString(type_)
            );
    }

    // WINDOW
    // function window_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _window_receiveInbound(uint256, address, bytes memory) internal {
        if (window_startBlock == 0) window_startBlock = block.number;
    }

    // Address, Assemble!
    // function assemble_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    // user will have to send 5 messages to get the address. can increase this number if required
    function _assemble_receiveInbound(
        uint256,
        address sender,
        bytes memory data
    ) internal {
        bytes32 assemblePart = abi.decode(data, (bytes32));
        if (assemblePart == bytes32(0))
            assemble_assembledAddress[sender] = bytes32(0);
        else {
            assemble_assembledAddress[sender] = bytes32(
                (uint256(assemble_assembledAddress[sender]) << 32) |
                    uint256(assemblePart)
            );
        }
    }

    // GIMME_MONIES
    // function gimmeMonies_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _gimmeMonies_receiveInbound(
        uint256,
        address,
        bytes memory data
    ) internal {
        (address impl, bytes memory externalData) = abi.decode(data, (address, bytes));
        IGimmeMonies(impl).sendMonies(externalData);
    }

    // Random
    // function random_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _random_receiveInbound(
        uint256 srcChainSlug_,
        address sender,
        bytes memory data
    ) internal {
        uint256 currentGuess = uint256(
            keccak256(
                abi.encodePacked(srcChainSlug_, block.timestamp, block.number)
            )
        ) % 10;
        (address impl, bytes memory externalData) = abi.decode(data, (address, bytes));
        if (impl == address(0)) return;
        uint256 userGuess = IRandom(impl).guess(externalData);
        if (currentGuess == userGuess) {
            random_guesser[srcChainSlug_] = sender;
        }
    }

    // Sig Maker
    // function sigMaker_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     bytes memory finalData = abi.encode(SIG_MAKER, data);
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, finalData);
    // }

    function _sigMaker_receiveInbound(
        uint256 srcChainSlug_,
        address sender,
        bytes memory data
    ) internal {
        if (srcChainSlug_ == 137) {
            uint8 v = abi.decode(data, (uint8));
            sigMaker_v[sender] = v;
        } else if (srcChainSlug_ == 56) {
            bytes32 r = abi.decode(data, (bytes32));
            sigMaker_r[sender] = r;
        } else if (srcChainSlug_ == 42161) {
            bytes32 s = abi.decode(data, (bytes32));
            sigMaker_s[sender] = s;
        }
    }

    // Similar deployer
    function _similarDeployer_receiveInbound(
        uint256,
        address sender,
        bytes memory data
    ) internal {
        (uint256 salt, bytes memory bytecode) = abi.decode(data, (uint256, bytes));

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        address deploymentAddress = address(uint160(uint256(hash)));
        similarDeployer_address[sender] = deploymentAddress;
    }

    // Block Hash Chain
    function _blockHashChain_outbound(
        uint256 toChainSlug_,
        uint256 dstGasLimit_
    ) external payable {
        bytes32 blockHashPrevious = blockhash(block.number - 1);
        bytes memory payload = abi.encode(
            block.number - 1,
            blockHashPrevious
        );

        _outbound(
            toChainSlug_,
            dstGasLimit_,
            msg.value,
            abi.encode(
                BLOCK_HASH_CHAIN,
                msg.sender,
                payload
            )
        );
    }

    function _blockHashChain_receiveInbound(
        uint256 srcChainSlug_,
        address sender,
        bytes memory payload
    ) internal {
        (uint256 blockNumber, bytes32 blockHash) = abi.decode(
            payload,
            (uint256, bytes32)
        );
        blockHashChain_blockHashes[sender][srcChainSlug_][
            blockNumber
        ] = blockHash;
    }

    function _gatedCount_receiveInbound(
        uint256,
        address,
        bytes memory payload
    ) internal {
        bytes32 op = abi.decode(payload, (bytes32));
        if (op == OPEN_GATE) {
            if (!isGateOpen) isGateOpen = true;
        }

        if (op == INCREASE_COUNT) {
            if (isGateOpen) gated_count = gated_count + 1;
            isGateOpen = false;
        }
    }

    function _poisonPill_receiveInbound(
        uint256,
        address sender,
        bytes memory payload
    ) internal {
        address pill = abi.decode(payload, (address));
        uint256 size;
        assembly {
            size := extcodesize(pill)
        }

        if (size > 0) poisonPill_codes[sender][pill] = true;
    }

    function _receiveInbound(
        uint256 srcChainSlug_,
        bytes memory payload_
    ) internal virtual override {
        (bytes32 eggType, address sender, bytes memory data) = abi.decode(
            payload_,
            (bytes32, address, bytes)
        );

        if (eggType == STEPPER) {
            _stepper_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == MAKE_IT_RAIN) {
            _makeItRain_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == ORDER_CHECK) {
            _orderCheck_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == KING) {
            _king_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == TRAVELLER) {
            _traveller_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == WINDOW) {
            _window_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == ADDRESS_ASSEMBLE) {
            _assemble_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == GIMME_MONIES) {
            _gimmeMonies_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == RANDOM) {
            _random_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == SIG_MAKER) {
            _sigMaker_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == SIMILAR_DEPLOYER) {
            _similarDeployer_receiveInbound(
                srcChainSlug_,
                sender,
                data
            );
        } else if (eggType == BLOCK_HASH_CHAIN) {
            _blockHashChain_receiveInbound(
                srcChainSlug_,
                sender,
                data
            );
        } else if (eggType == GATED_COUNT) {
            _gatedCount_receiveInbound(srcChainSlug_, sender, data);
        } else if (eggType == IMBALANCE) {
            _imbalance_receiveInbound(srcChainSlug_, sender, data);
        }
    }
}