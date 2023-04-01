/**
 *Submitted for verification at Arbiscan on 2023-03-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library AddressUtils {
    function isContract(address _address) internal view returns (bool addressCheck){
        bytes32 codeHash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codeHash := extcodehash(_address)}
        // solhint-disable-line
        addressCheck = (codeHash != 0x0 && codeHash != accountHash);
    }
}

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

interface ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract SupportsInterface is ERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true;
    }

    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}

abstract contract NFTokenMetadata is ERC721Metadata {
    string internal nftName;
    string internal nftSymbol;

    function name() external override view returns (string memory _name) {
        _name = nftName;
    }

    function symbol() external override view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
}

abstract contract NFToken is ERC721, NFTokenMetadata, SupportsInterface {
    using AddressUtils for address;

    string constant ZERO_ADDRESS = "003001";
    string constant NOT_VALID_NFT = "003002";
    string constant NOT_OWNER_OR_OPERATOR = "003003";
    string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
    string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
    string constant NFT_ALREADY_EXISTS = "003006";
    string constant NOT_OWNER = "003007";
    string constant IS_OWNER = "003008";

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping(uint256 => address) internal idToOwner;
    mapping(uint256 => address) internal idToApproval;
    mapping(address => uint256) private ownerToNFTokenCount;
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_APPROVED_OR_OPERATOR
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }

    constructor() {
        supportedInterfaces[0x80ac58cd] = true;
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, IS_OWNER);

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), ZERO_ADDRESS);
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external override view returns (address _owner){
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), NOT_VALID_NFT);
    }

    function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, NOT_OWNER);
        require(_to != address(0), ZERO_ADDRESS);

        _transferFrom(tokenOwner, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        transferFrom(_from, _to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal virtual {
        _clearApproval(_tokenId);

        _removeNFToken(_from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(address tokenOwner, uint256 _tokenId) internal virtual validNFToken(_tokenId) {
        require(tokenOwner == idToOwner[_tokenId], "Invalid tokenOwner specified.");
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    function _clearApproval(uint256 _tokenId) private {
        delete idToApproval[_tokenId];
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NFT_ERC_721 is NFToken, Ownable {
    uint256 nextTokenId = 1;
    string imageUrl = "";

    constructor(string memory name, string memory symbol) {
        nftName = name;
        nftSymbol = symbol;
    }

    function setTokenName(string calldata name) external onlyOwner() {
        nftName = name;
    }

    function setTokenSymbol(string calldata symbol) external onlyOwner() {
        nftSymbol = symbol;
    }

    function setImageUrl(string calldata url) external onlyOwner() {
        imageUrl = url;
    }

    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        string memory uri = string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(string(
                    abi.encodePacked(
                        "{"
                            "\"name\":\"", nftName, "\","
                            "\"image\":\"", imageUrl, "\""
                        "}"
                    ))
                )
            )
        ));
        return uri;
    }

    function mint(address _to) external onlyOwner() {
        super._mint(_to, nextTokenId);
        nextTokenId += 1;
    }

    function burn(uint256 _tokenId) external {
        super._burn(msg.sender, _tokenId);
    }
}