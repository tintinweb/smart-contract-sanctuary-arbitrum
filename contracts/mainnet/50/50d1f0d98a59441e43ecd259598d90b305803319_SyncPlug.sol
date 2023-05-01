/**
 *Submitted for verification at Arbiscan on 2023-04-29
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
        bytes calldata payload_
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

contract SyncPlug is PlugBase {

    // Egg Types
    uint256 public constant STEPPER = 1;
    uint256 public constant MAKE_IT_RAIN = 2;
    uint256 public constant ORDER_CHECK = 3;
    uint256 public constant KING = 4;
    uint256 public constant TRAVELLER = 5;
    uint256 public constant WINDOW = 6;
    uint256 public constant ADDRESS_ASSEMBLE = 7;
    uint256 public constant GIMME_MONIES = 8;
    uint256 public constant RANDOM = 9;
    uint256 public constant SIG_MAKER = 10;
    uint256 public constant SIMILAR_DEPLOYER = 11;

    // STEPPER
    bytes32 constant STEPPER_ADD = keccak256(abi.encode("ADD"));
    bytes32 constant STEPPER_SUB = keccak256(abi.encode("SUB"));
    uint256 public stepper_count = 10;

    // MAKE_IT_RAIN
    mapping (uint256 => mapping(address => uint256)) makeItRain_executionCounts;

    // ORDER_CHECK
    mapping (uint256 => uint256) orderCheck_timestamps;

    // KING
    address public king;

    // TRAVELLER
    mapping(address => string) public traveller_messages;

    // WINDOW
    uint256 public window_startBlock;

    // ASSEMBLE 
    mapping(address => bytes32) assemble_assembledAddress;

    // Random 
    mapping(uint256 => address ) random_guesser;

    // SIG MAKER
    mapping(address => uint8) sigMaker_v;
    mapping(address => bytes32) sigMaker_r;
    mapping(address => bytes32) sigMaker_s;

    //  SIMILAR_DEPLOYER
    mapping(address => address) similarDeployer_address;

    // // socket address
    ISocket public socket__;

    constructor(
        address socket_
    ) PlugBase(socket_) {
        socket__ = ISocket(socket_);
    }

    // Common outbound
    function outbound(uint256 toChainSlug_, uint256 dstGasLimit, bytes calldata data) external payable {
        (uint256 eggType) = abi.decode(data, (uint256));
        require(eggType != TRAVELLER, "Use the outbound function of traveller");   
        _outbound(toChainSlug_, dstGasLimit, msg.value, data);
    }

    // STEPPER
    // function stepper_outbound(uint256 toChainSlug_, uint256 dstGasLimit, bytes calldata data) external payable {
    //     _outbound(toChainSlug_, dstGasLimit, msg.value, data);
    // }

    function _stepper_receiveInbound(
        uint256,
        bytes memory payload
    ) internal {
        bytes32 op = abi.decode(payload, (bytes32));
        unchecked {
            if (op == STEPPER_ADD) stepper_count++;
            else stepper_count--;
        }
    }

    // MAKE_IT_RAIN
    function _makeItRain_receiveInbound(uint256, bytes memory data) internal {
        (address sender) = abi.decode(data, (address));
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
    function _orderCheck_receiveInbound(uint256 siblingChainSlug_, bytes memory) internal {
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
        bytes memory data
    ) internal  {
        address impl = abi.decode(data, (address));
        king = IKing(impl).king();
    }

    // TRAVALLER 
    function getChainString(uint256 type_) public view returns (string memory) {
        if (block.chainid == 137 || block.chainid == 80001) {
            if (type_==1) return "POLYGON";
            if (type_==2) return "SO";
        } else if (block.chainid == 42161 || block.chainid == 421613) {
            if (type_==1) return "ARBITRUM";
            if (type_==2) return "CK";
        } else if (block.chainid == 56 || block.chainid == 97) {
            if (type_==1) return "BSC";
            if (type_==2) return "ET";
        } else if (block.chainid == 10 || block.chainid == 420) {
            if (type_==1) return "OPTIMISM";
            if (type_==2) return "!";
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

        _outbound(
            toChainSlug_,
            dstGasLimit_,
            msg.value,
            abi.encode(TRAVELLER, type_, msg.sender, traveller_messages[msg.sender])
        );
    }

    function _traveller_receiveInbound(
        uint256,
        bytes memory data
    ) internal {
        (uint256 type_, address sender, string memory decodedString) = abi.decode(
            data,
            (uint256, address, string)
        );
        if (type_==0) traveller_messages[sender] = "";
        else traveller_messages[sender] = string.concat(decodedString, getChainString(type_));
    }

    // WINDOW 
    // function window_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _window_receiveInbound(
        uint256,
        bytes memory
    ) internal  {
        if (window_startBlock==0) window_startBlock = block.number;
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
        bytes memory data
    ) internal  {
        (bytes32 assemblePart, address sender) = abi.decode(
            data,
            (bytes32, address)
        );
        if (assemblePart==bytes32(0)) assemble_assembledAddress[sender] = bytes32(0);

        else {
            assemble_assembledAddress[sender] = bytes32(
            uint256(assemble_assembledAddress[sender]) << 32 | 
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
        bytes calldata data
    ) internal  {
        address impl = abi.decode(data, (address));
        IGimmeMonies(impl).sendMonies(data[32:]);
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
        bytes calldata data
    ) internal  {

        uint256 currentGuess = uint256(keccak256(abi.encodePacked(srcChainSlug_, block.timestamp, block.number)))%10;
        (address impl, address user) = abi.decode(data, (address, address));
        if (impl == address(0)) return;
        uint256 userGuess = IRandom(impl).guess(data[64:]);
        if (currentGuess==userGuess) {
            random_guesser[srcChainSlug_] = user;
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
        bytes calldata data
    ) internal  {
        if (srcChainSlug_== 137 || srcChainSlug_==80001) {
            (uint8 v, address sender) = abi.decode(data, (uint8, address)) ;
            sigMaker_v[sender] = v;
        } else if (srcChainSlug_== 56 || srcChainSlug_==97) {
            (bytes32 r, address sender) = abi.decode(data, (bytes32, address)) ;
            sigMaker_r[sender] = r;
        } else if (srcChainSlug_== 42161 || srcChainSlug_==42163) {
            (bytes32 s, address sender) = abi.decode(data, (bytes32, address)) ;
            sigMaker_s[sender] = s;
        } 
    }

    // Similar deployer
    // function similarDeployer_outbound(
    //     uint256 toChainSlug_,
    //     uint256 dstGasLimit_,
    //     bytes calldata data
    // ) external payable {
    //     _outbound(toChainSlug_, dstGasLimit_, msg.value, data);
    // }

    function _similarDeployer_receiveInbound(
        uint256,
        bytes calldata data
    ) internal  {
        (uint256 salt, address sender) = abi.decode(data, (uint256, address));
        bytes calldata bytecode = data[64:];

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

    
    function _receiveInbound(
        uint256 srcChainSlug_,
        bytes calldata payload_
    ) internal virtual override {
        uint256 eggType = abi.decode(payload_, (uint256));

        if (eggType == STEPPER) {
            _stepper_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == MAKE_IT_RAIN) {
            _makeItRain_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == ORDER_CHECK) {
            _orderCheck_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == KING) {
            _king_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == TRAVELLER) {
            _traveller_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == WINDOW) {
            _window_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == ADDRESS_ASSEMBLE) {
            _assemble_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == GIMME_MONIES) {
            _gimmeMonies_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == RANDOM) {
            _random_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == SIG_MAKER) {
            _sigMaker_receiveInbound(srcChainSlug_, payload_[32:]);
        } else if (eggType == SIMILAR_DEPLOYER) {
            _similarDeployer_receiveInbound(srcChainSlug_, payload_[32:]);
        } 
    }
}