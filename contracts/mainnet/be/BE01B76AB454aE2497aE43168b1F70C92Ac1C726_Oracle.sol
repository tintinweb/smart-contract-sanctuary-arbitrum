// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev The block of control information and data for comminicate
/// between user applications. Messages are the exchange medium
/// used by channels to send and receive data through cross-chain networks.
/// A message is sent from a source chain to a destination chain.
/// @param index The leaf index lives in channel's incremental mekle tree.
/// @param fromChainId The message source chain id.
/// @param from User application contract address which send the message.
/// @param toChainId The message destination chain id.
/// @param to User application contract address which receive the message.
/// @param gasLimit Gas limit for destination UA used.
/// @param encoded The calldata which encoded by ABI Encoding.
struct Message {
    address channel;
    uint256 index;
    uint256 fromChainId;
    address from;
    uint256 toChainId;
    address to;
    uint256 gasLimit;
    bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
}

/// @dev Hash of the message.
function hash(Message memory message) pure returns (bytes32) {
    return keccak256(abi.encode(message));
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IVerifier.sol";

abstract contract Verifier is IVerifier {
    /// @notice Fetch message hash.
    /// @param chainId The source chain id.
    /// @param channel The message channel.
    /// @param msgIndex The Message index.
    /// @return Message hash in source chain.
    function hashOf(uint256 chainId, address channel, uint256 msgIndex) public view virtual returns (bytes32);

    /// @inheritdoc IVerifier
    function verifyMessageProof(Message calldata message, bytes calldata) external view returns (bool) {
        // check oracle's message hash equal relayer's message hash
        return hashOf(message.fromChainId, message.channel, message.index) == hash(message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Verifier.sol";
import "../interfaces/IORMP.sol";

contract Oracle is Verifier {
    event SetFee(uint256 indexed chainId, uint256 fee);
    event SetApproved(address operator, bool approve);
    event Withdrawal(address indexed to, uint256 amt);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public immutable PROTOCOL;

    address public owner;
    // chainId => price
    mapping(uint256 => uint256) public feeOf;
    // operator => isApproved
    mapping(address => bool) public approvedOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyApproved() {
        require(isApproved(msg.sender), "!approve");
        _;
    }

    constructor(address dao, address ormp) {
        PROTOCOL = ormp;
        owner = dao;
    }

    receive() external payable {}

    function version() public pure returns (string memory) {
        return "2.1.0";
    }

    /// @dev Only could be called by owner.
    /// @param chainId The source chain id.
    /// @param channel The message channel.
    /// @param msgIndex The source chain message index.
    /// @param msgHash The source chain message hash corresponding to the channel.
    function importMessageHash(uint256 chainId, address channel, uint256 msgIndex, bytes32 msgHash)
        external
        onlyOwner
    {
        IORMP(PROTOCOL).importHash(chainId, channel, msgIndex, msgHash);
    }

    function hashOf(uint256 chainId, address channel, uint256 msgIndex) public view override returns (bytes32) {
        return IORMP(PROTOCOL).hashLookup(address(this), keccak256(abi.encode(chainId, channel, msgIndex)));
    }

    function changeOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setApproved(address operator, bool approve) external onlyOwner {
        approvedOf[operator] = approve;
        emit SetApproved(operator, approve);
    }

    function isApproved(address operator) public view returns (bool) {
        return approvedOf[operator];
    }

    function withdraw(address to, uint256 amount) external onlyApproved {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
        emit Withdrawal(to, amount);
    }

    function setFee(uint256 chainId, uint256 fee_) external onlyApproved {
        feeOf[chainId] = fee_;
        emit SetFee(chainId, fee_);
    }

    function fee(uint256 toChainId, address /*ua*/ ) public view returns (uint256) {
        uint256 f = feeOf[toChainId];
        require(f != 0, "!fee");
        return f;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Common.sol";

interface IORMP {
    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param refund Return extra fee to refund address.
    /// @return Return the hash of the message as message id.
    /// @param params General extensibility for relayer to custom functionality.
    function send(
        uint256 toChainId,
        address to,
        uint256 gasLimit,
        bytes calldata encoded,
        address refund,
        bytes calldata params
    ) external payable returns (bytes32);

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param ua User application contract address which send the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address ua, uint256 gasLimit, bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256);

    /// @dev Recv verified message and dispatch to destination user application address.
    /// @param message Verified receive message info.
    /// @param proof Message proof of this message.
    /// @return dispatchResult Result of the message dispatch.
    function recv(Message calldata message, bytes calldata proof) external payable returns (bool dispatchResult);

    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default config is used.
    /// @param ua User application contract address.
    function getAppConfig(address ua) external view returns (address oracle, address relayer);

    /// @notice Set user application config.
    /// @param oracle Oracle which user application choose.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external;

    function defaultUC() external view returns (address oracle, address relayer);

    /// @dev Check the msg if it is dispatched.
    /// @param msgHash Hash of the checked message.
    /// @return Return the dispatched result of the checked message.
    function dones(bytes32 msgHash) external view returns (bool);

    /// @dev Import hash by any oracle address.
    /// @notice Hash is an abstract of the proof system, it can be a block hash or a message root hash,
    ///  		specifically provided by oracles.
    /// @param chainId The source chain id.
    /// @param channel The message channel.
    /// @param msgIndex The source chain message index.
    /// @param hash_ The hash to import.
    function importHash(uint256 chainId, address channel, uint256 msgIndex, bytes32 hash_) external;

    /// @dev Fetch hash.
    /// @param oracle The oracle address.
    /// @param lookupKey The key for loop up hash.
    /// @return Return the hash imported by the oracle.
    function hashLookup(address oracle, bytes32 lookupKey) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Common.sol";

interface IVerifier {
    /// @notice Verify message proof
    /// @dev Message proof provided by relayer. Oracle should provide message root of
    ///      source chain, and verify the merkle proof of the message hash.
    /// @param message The message info.
    /// @param proof Proof of the message
    /// @return Result of the message verify.
    function verifyMessageProof(Message calldata message, bytes calldata proof) external view returns (bool);
}