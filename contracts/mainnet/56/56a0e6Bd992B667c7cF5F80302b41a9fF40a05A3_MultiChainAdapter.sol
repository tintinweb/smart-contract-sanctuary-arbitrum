// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILZEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint specified by our chainId.
    // @param _dstChainId - the destination chain identifier
    // @param _dstContractAddress - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId, 
        bytes calldata _dstContractAddress, 
        bytes calldata _payload, 
        address payable _refundAddress, 
        address _zroPaymentAddress, 
        bytes calldata _adapterParams
    ) external payable;
}

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

interface IAdapter {
    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
    }
    function send (uint256 chainId, address nft, uint256 tokenId, string calldata name, string calldata symbol, string calldata tokenURI, address recipient, IAdapter.RoyaltyData calldata royalty) external payable;
}

interface IReceiver {
    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
    }
    function receiveNFT (address nft, string calldata name, string calldata symbol, string calldata tokenURI, uint256 tokenId, address recipient, RoyaltyData calldata royalty) external;
}

contract MultiChainAdapter is IAdapter, Ownable, ILayerZeroReceiver {

    mapping(uint256 => uint16) public connections;
    event LogAddConnection(uint256 chainId, uint16 chainIdLZ);

    IReceiver immutable public receiver;
    ILZEndpoint immutable public endpoint;

    constructor (IReceiver receiver_, ILZEndpoint endpoint_, address owner_) {
        receiver = receiver_;
        endpoint = endpoint_;
        _transferOwnership(owner_);
    }

    function init(bytes calldata) public payable {}

    function send(uint256 chainId, address nft, uint256 tokenId, string calldata name, string calldata symbol, string calldata tokenURI, address recipient, IAdapter.RoyaltyData calldata royalty) external payable override {
        require(msg.sender == address(receiver));

        bytes memory payload;
        {
            payload = abi.encode(nft, tokenId, name, symbol, tokenURI, recipient, royalty);
        }

        uint16 chainIdLz = connections[chainId];
        require(chainIdLz != 0);
        // expectancy of sender/receiver deployed at the same address across networks
        // fee refund to the EOA that originated the tx
        // change gas amount being relayed potentially
        // TODO: TEST amount of gas needed for LZ
        endpoint.send{value: msg.value}(chainIdLz, abi.encodePacked(address(this)), payload, payable(tx.origin), address(0), bytes(""));
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress,uint64 _nonce, bytes calldata _payload) external override {
        require(msg.sender == address(endpoint));
        address fromAddress;
        assembly {
            fromAddress := mload(add(_srcAddress, 20))
        }
        require(fromAddress == address(this));

        (address nft, uint256 tokenId, string memory name, string memory symbol, string memory tokenURI, address recipient, IReceiver.RoyaltyData memory royalty) = abi.decode(_payload, (address, uint256, string, string, string, address, IReceiver.RoyaltyData));

        receiver.receiveNFT(nft, name, symbol, tokenURI, tokenId, recipient, royalty);
    }

    function addConnection(uint256 chainId, uint16 chainIdLZ) external onlyOwner {
        connections[chainId] = chainIdLZ;
        emit LogAddConnection(chainId, chainIdLZ);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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