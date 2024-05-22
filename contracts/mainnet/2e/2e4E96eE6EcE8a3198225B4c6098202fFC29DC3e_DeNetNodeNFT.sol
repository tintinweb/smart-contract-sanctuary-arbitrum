// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/
pragma solidity ^0.8.0;

interface ISimpleINFT {
    // Create or Transfer Node
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Return amount of Nodes by owner
    function balanceOf(address owner) external view returns (uint256);

    // Return Token ID by Node address
    function getNodeIDByAddress(address _node) external view returns (uint256);

    // Return owner address by Token ID
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMetaData {
    // Create or Update Node
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ipAddress,
        uint16 port
    );

    // Structure for Node
    struct DeNetNode{
        uint8[4] ipAddress; // for example [127,0,0,1]
        uint16 port;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 updatesCount;
        uint256 rank;
    }

    // Return Node info by token ID;
    // function nodeInfo(uint256 tokenId) external view returns (IMetaData.DeNetNode memory);
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);
}

interface IDeNetNodeNFT {
     function totalSupply() external view returns (uint256);

     // PoS Only can ecevute
     function addSuccessProof(address _nodeOwner) external;

     function getLastUpdateByAddress(address _user) external view returns(uint256);
     function getNodesRow(uint _startId, uint _endId) external view returns(IMetaData.DeNetNode[] memory);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    This Contract - ope of step for moving from rating to VDF, before VDF not realized.
*/

pragma solidity ^0.8.1;

import "./PoSAdmin.sol";
import "./interfaces/INodeNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleNFT is ISimpleINFT {
    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    mapping (address => uint256) public nodeByAddress;
    
    // Mapping from owner to token last token id
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "0x0 is blocked");
        return _ownedTokensCount[owner];
    }

    function getNodeIDByAddress(address _node) public override view returns (uint256) {
        require(nodeByAddress[_node] != 0, "NodeNFT.getNodeIDByAddress: Node does not exist");
        return nodeByAddress[_node];
    }
    
    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "0x0 is blocked");
        return owner;
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "0x0 is blocked");
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(address owner, uint256 tokenId) internal {
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }
    
    function _removeTokenFrom(address _from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == _from, "token owner is not true");
        _ownedTokensCount[_from] = _ownedTokensCount[_from] - 1;
        _tokenOwner[tokenId] = address(0);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenID) internal {
        require(_tokenOwner[_tokenID] != address(0), "token owner is 0x0");
        _ownedTokensCount[_from] = _ownedTokensCount[_from] - 1;
        _ownedTokensCount[_to] = _ownedTokensCount[_from] + 1;
        _tokenOwner[_tokenID] = _to;
        nodeByAddress[_from] = 0;
        nodeByAddress[_to] = _tokenID;
        emit Transfer(_from, _to, _tokenID);

    }
    
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0), "token owner is not 0x0");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to] + 1;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
}

contract SimpleMetaData is SimpleNFT, IMetaData {
    // Token name
    string internal _name;
    
    // Token symbol
    string internal _symbol;

    // Rank degradation per update
    uint256 internal _degradation = 10;

    mapping(uint256 => DeNetNode) private _node;

    constructor(string  memory name_, string  memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    
    function nodeInfo(uint256 tokenId) public override view returns (DeNetNode memory) {
        require(_exists(tokenId), "node not found");
        return _node[tokenId];
    }
    
    function _setNodeInfo(uint256 tokenId,  uint8[4] calldata ip, uint16 port) internal {
        require(_exists(tokenId), "node not found");
        
        _node[tokenId].ipAddress = ip;
        _node[tokenId].port = port;
        if (_node[tokenId].createdAt == 0) {
            _node[tokenId].createdAt = block.timestamp;
        } else {
            // degradation rank for update node
            if (_node[tokenId].rank < _degradation) {
                _node[tokenId].rank = 0;
            } else {
                _node[tokenId].rank = _node[tokenId].rank - _degradation;
            }
        }
        _node[tokenId].updatedAt = block.timestamp;
        _node[tokenId].updatesCount += 1;

        
        
        emit UpdateNodeStatus(msg.sender, tokenId, ip, port);
    }

    function forceUpdateNode(uint256 nodeID, uint8[4] memory ip, uint16 port) internal {
        require(_exists(nodeID), "node not found");
        _node[nodeID].ipAddress = ip;
        _node[nodeID].port = port;
    }
    
    function _burnNode(address owner, uint256 tokenId) internal  {
        super._burn(owner, tokenId);
        
        // Clear metadata (if any)
        if (_node[tokenId].createdAt != 0) {
            delete _node[tokenId];
        }
    }

    function _increaseRank(uint256 tokenId) internal {
        _node[tokenId].rank = _node[tokenId].rank + 1;
        _node[tokenId].updatedAt = block.timestamp;
    }
}

/**
*@dev This code is for a contract called DeNetNodeNFT. It is a type of non-fungible token (NFT) that is used to represent nodes in a decentralized network. The code sets up the parameters for the NFT, such as the maximum number of nodes and the amount of time before a node is considered inactive. It also sets up functions to create, update, and steal nodes, as well as to add and remove users from a whitelist. Finally, it has a function to get the last update time for a given user address.
*/
contract DeNetNodeNFT is SimpleMetaData, PoSAdmin, IDeNetNodeNFT {    
    uint256 public nextNodeID = 1;
    uint256 public maxNodeID = 10; // Start Amount Of Nodes
    uint256 public nodesAvailable = 0;
    uint256 public maxAlivePeriod = TIME_1D; // ~ 7 days
    uint256 public proofsBeforeIncreaseMaxNodeID = 10000;
    uint256 public successProofsCount = 0;
    address public rentGasTokenAddress;
    
    constructor (string memory _name, string memory _symbol, address _pos) SimpleMetaData(_name, _symbol) PoSAdmin(_pos){
        sync();
    }

    function _afterSync()  internal  override{
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        rentGasTokenAddress =  contractStorage.getContractAddressViaName("renttby", NETWORK_ID);
    }

    function setMaxAlivePeriod(uint newPeriod) public onlyDAO {
        require(newPeriod > TIME_7D && newPeriod <= TIME_30D, "setMaxAlivePeriod: new time not in rage (7d->30d)");
        maxAlivePeriod = newPeriod;
    }

    /**
        @dev means, if node with ID have same amount of storage gastoken, they can be node,
        example: nodeId = 10, gastoken required 10 * 1e17. (100 id for 10.0 TB)
    */
    function isAddressHaveGastokenToBeNode(address nodeAddress, uint nodeId) public view returns (bool) {
        uint gastokenBalance = IERC20(gasTokenAddress).balanceOf(nodeAddress);
        uint rentGasTokenBalance = IERC20(rentGasTokenAddress).balanceOf(nodeAddress);
        uint etherBalance = nodeAddress.balance;

        if (rentGasTokenAddress != 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) {
            etherBalance = 0;
        } else {
            rentGasTokenBalance = rentGasTokenBalance * 100;
            etherBalance = etherBalance * 100;
        }

        return gastokenBalance + rentGasTokenBalance + etherBalance >= nodeId * 1e17;
    }

    /*
        @dev ProofOfStorage call this method every time, when node send success proof 
    */
    function addSuccessProof(address _nodeOwner) public override onlyPoS {
        // Check is address registered as node
        require(nodeByAddress[_nodeOwner] != 0, "NodeNFT: this address not registered as node");
        
        // Check is address have required amount of gastoken.
        require(isAddressHaveGastokenToBeNode(_nodeOwner, nodeByAddress[_nodeOwner]), "NodeNFT: this address have not required storage gastoken balance");

        // Increase rank for this node 
        _increaseRank(nodeByAddress[_nodeOwner]);
        
        // Increase successProofsCount and maxNodeID if necessary
        if (successProofsCount + 1000 >= proofsBeforeIncreaseMaxNodeID) {
            proofsBeforeIncreaseMaxNodeID = proofsBeforeIncreaseMaxNodeID * 102 / 100;
            successProofsCount = 0;
            maxNodeID = maxNodeID + 1;
        }
        successProofsCount = successProofsCount + 1000;            
    }

    function restore(address old) external onlyOwner {
        if (old != address(0)) {
            IDeNetNodeNFT oldNFT = IDeNetNodeNFT(old);
            ISimpleINFT oldOwner = SimpleMetaData(old);
            IMetaData data = IMetaData(old);

            uint count = oldNFT.totalSupply();

            for (uint i = 1; i <= count; i++) {
                address owner = oldOwner.ownerOf(i);
                _mint(owner, nextNodeID);
                nodeByAddress[owner] = nextNodeID;
                DeNetNode memory node = data.nodeInfo(nextNodeID);

                forceUpdateNode(nextNodeID, node.ipAddress, node.port);
                nextNodeID++;
                nodesAvailable++;
            }
        }
    }


    function createNode(uint8[4] calldata ip, uint16 port) public returns (uint256){
        // Check if nodes limit not exceeded
        require(maxNodeID > nodesAvailable, "Max node count limit exceeded");       

        // Check if user have not nodes
        require(nodeByAddress[msg.sender] == 0, "This address already have node");

        // Check is address have required amount of gastoken.
        require(isAddressHaveGastokenToBeNode(msg.sender, nextNodeID), "NodeNFT: this address have not required storage gastoken balance");

        _mint(msg.sender, nextNodeID);
        _setNodeInfo(nextNodeID, ip, port);
        nodeByAddress[msg.sender] = nextNodeID;
        nextNodeID += 1;
        nodesAvailable += 1;
        return nextNodeID - 1;
    } 
    
    function updateNode(uint256 nodeID, uint8[4] calldata ip, uint16 port) public {
        require(ownerOf(nodeID) == msg.sender, "only nft owner can update node");
        _setNodeInfo(nodeID, ip, port);
    }

    function totalSupply() public override view returns (uint256) {
        return nextNodeID - 1;
    }

    /**
    * @dev  his function allows a user to steal a node from another user. It checks if the node exists, if the receiver already has a node, and if the node is alive. If all of these conditions are met, it transfers the node from its old owner to the new owner and increases its rank.
    */
    function stealNode(uint256 _nodeID, address _to) public {
        require(_exists(_nodeID), "Attacked node not found");
        require(nodeByAddress[_to] == 0, "Reciever already have node");

        DeNetNode memory _tmpNode = nodeInfo(_nodeID);
        address _oldOwner = ownerOf(_nodeID);

        // Verify that reach alive period or have not amount of storage gastoken
        require(
                block.timestamp - _tmpNode.updatedAt > maxAlivePeriod ||
                isAddressHaveGastokenToBeNode(_oldOwner, _nodeID) != true,
                "NodeNFT: Node is alive"
        );

        // Verify that reciever have required amount of storage gastoken
        require(
                isAddressHaveGastokenToBeNode(_to, _nodeID),
                "NodeNFT: reciever have not required amount of storage gastoken"
        );

        _transferFrom(_oldOwner, _to, _nodeID);
        _increaseRank(_nodeID);
    }

    function getLastUpdateByAddress(address _user) external override view returns(uint256) {
        return nodeInfo(getNodeIDByAddress(_user)).updatedAt;
    }

    function getNodesRow(uint _startId, uint _endId) external override view returns (DeNetNode[] memory) {
        DeNetNode[] memory _returns = new DeNetNode[](_endId - _startId);
        for (uint i = 0; i < (_endId - _startId); i++) {
            _returns[i] = nodeInfo(i + _startId);
        }
        return _returns;
    }

}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract PoSAdmin  is IPoSAdmin, Ownable, StringNumbersConstant {
    address public proofOfStorageAddress = address(0);
    address public storagePairTokenAddress = address(0);
    address public contractStorageAddress;
    address public daoContractAddress;
    address public gasTokenAddress;
    address public gasTokenMined;
    
    constructor (address _contractStorageAddress) {
        contractStorageAddress = _contractStorageAddress;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "PoSAdmin.msg.sender != POS");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        proofOfStorageAddress = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
        storagePairTokenAddress = contractStorage.getContractAddressViaName("pairtoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        gasTokenAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        gasTokenMined = contractStorage.getContractAddressViaName("gastoken_mined", NETWORK_ID);
        emit ChangePoSAddress(proofOfStorageAddress);
        _afterSync();
    }

    function _afterSync() internal virtual {}
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
   uint public constant STORAGE_100GB_IN_MB = 102400; // 100 GB;
  
   // nax blocks after proof depends of network, most of them 256 is ok
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   // Polygon Network Settigns
   address public constant PAIR_TOKEN_START_ADDRESS = 0x081Ec4c0e30159C8259BAD8F4887f83010a681DC; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x15968404140CFB148365577D669477E1615557C0; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 2241;

   // StorageToken Default Vars
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
}