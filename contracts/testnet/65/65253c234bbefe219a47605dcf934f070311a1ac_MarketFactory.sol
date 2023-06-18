// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./CloneFactory.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}



interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

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

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

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

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

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

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

library Counters {
    struct Counter {
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
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

interface IMarketplace {
    function key() external view returns(address);
    
    function redeemAndFee() external view returns(address);
}

interface IRedeemAndFee {
    function ableToCreatePrivateNFTforSale(address user) external view returns(bool);
    function ableToViewALLPrivateMetadata(address user) external view returns(bool);
    function getBlackList (address user) external view returns(bool);
    function flatFee() external view returns(uint);
}

interface ITier0 {
    function mint(address user, uint256 amount) external;
    function initialize(address owner, uint256 tokenId, uint256 capacity) external;
}

contract MarketFactory is ERC1155, CloneFactory {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    enum NFTtype{Default, FNFT, SNFT, PRIVATE, Tier0, MAX}
    address public marketplace;
    address public fNFTMarketplace;
    address public serviceMarketplace;
    address public owner;
    bool isInitial;
    address public tier0Contract;
    // uint public tier0TokenId;


    struct UserInfo {
        uint8 royaltyFee;
        uint8 royaltyShare;
        address user;
        NFTtype nftType;
        address tier0;
        // uint8 step;
    }

    struct PrivateMetadataInfo {
        mapping(address=>bool) ownerList;
        string metadata;
        bool isEncrypt;
        bool set;
    }

    mapping (address => uint[]) private userTokenInfo;
    mapping (uint => UserInfo) public userInfo;
    mapping (uint => string) private _tokenURIs;
    mapping (uint=>PrivateMetadataInfo) private _privateMetadata;

    string collectionInfo;      // collection metadata
    uint size;

    constructor() ERC1155("") {
        // initialize(msg.sender);
    }

    function initialize(address _owner) public {
        require(owner == address(0) && isInitial == false);
        owner = _owner;
        isInitial = true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getUserInfo(uint tokenId) external view returns(uint8 royaltyFee, uint8 royaltyShare, uint8 nftType, address tier0, address admin) {
        return (userInfo[tokenId].royaltyFee, userInfo[tokenId].royaltyShare, uint8(userInfo[tokenId].nftType), userInfo[tokenId].tier0, userInfo[tokenId].user);
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "MarketFactory: caller is not the owner");
        _;
    }

    modifier isBlackList() {
        require(false == IRedeemAndFee(IMarketplace(marketplace).redeemAndFee()).getBlackList(msg.sender), "MarketFactory: caller is blackLiser");
        _;
    }

    function createItem (
        uint amount,
        string memory _uri,
        uint8 _royaltyFee,
        NFTtype _type,
        uint _tier0,
        string memory _privateUri,
        bool isEncrypt,
        address user
    ) external isBlackList returns(uint) {
        require(_type != NFTtype.Tier0, "MarketFactory");
        return _createItem(amount, _uri, _royaltyFee, _type, _tier0, _privateUri, isEncrypt, user);
    }

    // function _createTier0() external {
    //     require(msg.sender == address(this), "MarketFactory:no permission");
    //     uint MAX = ~uint256(0);
    //     tier0TokenId = _createItem(MAX, "", 2, NFTtype.Tier0, 0, "", false, address(this));
    // }

    function _createItem(
        uint amount,
        string memory _uri,
        uint8 _royaltyFee,
        NFTtype _type,
        uint _tier0,
        string memory _privateUri,
        bool isEncrypt,
        address user
    ) private returns(uint) {
        address redeem = IMarketplace(marketplace).redeemAndFee();
        if(user != msg.sender)
            require(IRedeemAndFee(redeem).ableToViewALLPrivateMetadata(msg.sender), "MarketFactory:not angel");
        if(size != 0)
            require(size>=_tokenIds.current(), "MarketFactory: size limitation");
        require(_type < NFTtype.MAX, "MarketFactory: invalid type");
        if(_type == NFTtype.Tier0)
            require(user == address(this), "MarketFactory: tier0 not allow");
        if(_type == NFTtype.PRIVATE)
            require(IRedeemAndFee(redeem).ableToCreatePrivateNFTforSale(user), "MarketFactory: private metadata not allow");
        if(_type != NFTtype.FNFT)
            _tier0 = 0;
        else {
            require(_tier0 > 0 && _tier0 % 10 == 0, "MarketFactory: Invalid tier0 capacity2");
            amount = 1;
        }

        if(_type == NFTtype.SNFT) amount = 1;

        _tokenIds.increment();
        uint id = _tokenIds.current();
        _mint(user, id, amount, "");
        _tokenURIs[id] = _uri;
        userTokenInfo[user].push(id);
        userInfo[id].royaltyFee = _royaltyFee;
        userInfo[id].royaltyShare = 50;
        userInfo[id].user = user;
        userInfo[id].nftType = _type;
        if(_type == NFTtype.FNFT) {
            address subFactory = createClone(tier0Contract);
            userInfo[id].tier0 = subFactory;
            ITier0(subFactory).initialize(address(this), id, _tier0);
        }

        if(_type == NFTtype.PRIVATE) {
            _privateMetadata[id].ownerList[user] = true;
            _privateMetadata[id].metadata = _privateUri;
            _privateMetadata[id].isEncrypt = isEncrypt;
            _privateMetadata[id].set = true;
        }

        return id;
    }

    function mintNFT(uint tokenId, address taker, uint amount) external returns(uint id){
        _tokenIds.increment();
        uint newid = _tokenIds.current();
        _mint(taker, newid, amount, "");
        _tokenURIs[newid] = _tokenURIs[tokenId];
        userTokenInfo[taker].push(newid);
        userInfo[newid].royaltyFee = 2;
        userInfo[newid].royaltyShare = 50;
        userInfo[newid].user = taker;
        userInfo[newid].nftType = NFTtype.Default;
        return newid;
    }

    function updateRoyaltyFee(uint tokenId, uint8 _royaltyFee) external isBlackList {
        userInfo[tokenId].royaltyFee = _royaltyFee;
    }

    function setMarketplace(address _market) external onlyOwner {
        marketplace = _market;
        // IMarketFactory(address(this))._createTier0();
    }

    function setServiceMarketplace(address _market) external onlyOwner {
        serviceMarketplace = _market;
    }

    function setFNFTMarketplace(address _market) external onlyOwner {
        fNFTMarketplace = _market;
    }

    function setTier0(address _tier0) external onlyOwner {
        tier0Contract = _tier0;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setCollectionInfo(string memory _uri) external onlyOwner {
        collectionInfo = _uri;
    }

    function setSize(uint _size) external onlyOwner {
        size = _size;
    }

    // function decreaseTier0(uint tokenId, address user) external returns(uint8, uint256) {
    //     require(msg.sender == marketplace, "MarketFactory: not permit");
    //     require(userInfo[tokenId].nftType == NFTtype.FNFT, "MarketFactory: not FNFT");
    //     require(userInfo[tokenId].step < 10, "MarketFactory: sold out");
    //     require(isContain(tokenId, msg.sender), "MarketFactory: invalid user");
    //     uint amount = userInfo[tokenId].tier0Cnt * 1 / (10 - userInfo[tokenId].step);
    //     userInfo[tokenId].step++;
    //     IERC1155(this).safeTransferFrom(address(this), user, tier0TokenId, amount, "");
    //     return (userInfo[tokenId].step, amount);
    // }

    // function initialTier0(uint tokenId) external {
    //     require(msg.sender == marketplace, "MarketFactory: not permit");
    //     require(userInfo[tokenId].nftType == NFTtype.FNFT, "MarketFactory: not FNFT");
    //     // require(isContain(tokenId, msg.sender), "MarketFactory: invalid sender");
    //     userInfo[tokenId].step = 0;
    // }

    function isContain(uint tokenId, address user) public view returns(bool) {
        for(uint i = 0; i < userTokenInfo[user].length; i++) {
            if(tokenId == userTokenInfo[user][i]) return true;
        }
        return false;
    }

    function balanceOf(address account) public view returns (uint) {
        return userTokenInfo[account].length;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if(balanceOf(to, id) == 0) {
            userTokenInfo[to].push(id);
            if(_privateMetadata[id].set && _privateMetadata[id].ownerList[to] == false)
                _privateMetadata[id].ownerList[to] = true;
        }
        super.safeTransferFrom(from, to, id, amount, data);
        if(balanceOf(from, id) == 0) {
            uint len = userTokenInfo[from].length;
            for(uint i = 0; i < len; i++) {
                if(userTokenInfo[from][i] == id) {
                    userTokenInfo[from][i] = userTokenInfo[from][len-1];
                    userTokenInfo[from].pop();
                    break;
                }
            }
            if(_privateMetadata[id].set && _privateMetadata[id].ownerList[from] == true)
                _privateMetadata[id].ownerList[from] = false;
        }
        
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        for(uint j = 0; j < ids.length; j++) {
            uint id = ids[j];
            if(balanceOf(to, id) == 0) {
                userTokenInfo[to].push(id);
            }
            if(_privateMetadata[id].set && _privateMetadata[id].ownerList[to] == false)
                _privateMetadata[id].ownerList[to] = true;
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        for(uint j = 0; j < ids.length; j++) {
            uint id = ids[j];
            if(balanceOf(from, id) == 0) {
                uint len = userTokenInfo[from].length;
                for(uint i = 0; i < len; i++) {
                    if(userTokenInfo[from][i] == id) {
                        userTokenInfo[from][i] = userTokenInfo[from][len-1];
                        userTokenInfo[from].pop();
                        break;
                    }
                }
                if(_privateMetadata[id].set && _privateMetadata[id].ownerList[from] == true)
                _privateMetadata[id].ownerList[from] = false;
            }
        }
    }

    function hasPermissionPrivateMetadata(uint tokenId, address user) public view returns(bool) {
        return _privateMetadata[tokenId].ownerList[user];
    }

    function viewPrivateMetadata(uint tokenId, address user) external view returns(string memory metadata, bool isEncrypt, bool isValid) {
        address redeem = IMarketplace(marketplace).redeemAndFee();
        if(msg.sender == IMarketplace(marketplace).key() && IMarketplace(marketplace).key() != address(0)) {
            if(IRedeemAndFee(redeem).ableToViewALLPrivateMetadata(user) || hasPermissionPrivateMetadata(tokenId, user))
                return (_privateMetadata[tokenId].metadata, _privateMetadata[tokenId].isEncrypt, true);
        }
        if(IMarketplace(marketplace).key() == address(0) && hasPermissionPrivateMetadata(tokenId, user) == true) {
            return (_privateMetadata[tokenId].metadata, _privateMetadata[tokenId].isEncrypt, true);
        }
        return (bytes32ToString(keccak256(abi.encodePacked(_privateMetadata[tokenId].metadata))), false, false);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function getUserTokenInfo(address user) external view returns(uint[] memory ids) {
        if(IMarketplace(marketplace).key() == address(0)) {
            require(user == msg.sender);
        }
        ids = new uint[](userTokenInfo[user].length);
        for (uint i = 0; i < ids.length; i++) {
            ids[i] = userTokenInfo[user][i];
        }
        return ids;
    }

}