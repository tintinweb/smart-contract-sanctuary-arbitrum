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

library StringTools {
    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {return "0";}

        uint temp = value;
        uint digits;

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

    function toString(bool value) internal pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function toString(address addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        return string(stringBytes);
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


interface IUriGenerator {
    function operator() external view returns (string memory);

    function getEncodedSvg(
        string memory stakeTokenSymbol,
        string memory rewardTokenSymbol,
        string memory stakedAmount,
        string memory stakeShare,
        string memory poolIndex
    ) external view returns (string memory);

    function getJSON(
        string memory name,
        string memory stakeToken,
        string memory rewardToken,
        string memory poolIndex,
        string memory encodedSvg,
        string memory stakedAmount,
        string memory availableRewards,
        string memory withdrawnRewards
    ) external pure returns (string memory);

    function getTokenURI(
        string memory json
    ) external pure returns (string memory);
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface StakingContract {
    function getNFTAttributes(
        IERC20 stakeToken,
        IERC20 rewardToken,
        uint256 poolIndex,
        uint256 tokenId
    ) external view returns (string memory, string memory, string memory, string memory);
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

    function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256){
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
    using StringTools for *;

    uint256 nextTokenId = 1;
    address public minter;
    StakingContract public stakingContract;
    IUriGenerator public uriGenerator = IUriGenerator(address(0));

    struct PoolIdentifier {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 poolIndex;
    }

    mapping(address => uint256[]) allTokenIdsOfUser;
    mapping(uint256 => uint256) public tokenIdToIndex;
    mapping(uint256 => uint256) public tokenIdToAllIndex;
    mapping(uint256 => PoolIdentifier) public tokenIdToPoolIdentifier;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => mapping(address => uint256[])))) public poolTypeAndOwnerToTokenId;

    constructor(string memory name, string memory symbol, address _minter, IUriGenerator _uriGenerator) {
        supportedInterfaces[0x5b5e139f] = true;
        nftName = name;
        nftSymbol = symbol;

        minter = _minter;
        stakingContract = StakingContract(_minter);
        uriGenerator = _uriGenerator;
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "Operation can only be performed by the minter.");
        _;
    }

    function addIdToAllIdList(address to, uint256 _tokenId) internal {
        tokenIdToAllIndex[_tokenId] = allTokenIdsOfUser[to].length;
        allTokenIdsOfUser[to].push(_tokenId);
    }

    function delIdFromAllIdList(address from, uint256 _tokenId) internal {
        uint256 length = allTokenIdsOfUser[from].length;
        require(length > 0, "Invalid Length");

        uint256 lastId = allTokenIdsOfUser[from][length - 1];
        uint256 currentIndex = tokenIdToAllIndex[_tokenId];

        allTokenIdsOfUser[from][currentIndex] = allTokenIdsOfUser[from][length - 1];
        tokenIdToAllIndex[lastId] = currentIndex;
        allTokenIdsOfUser[from].pop();

        delete tokenIdToAllIndex[_tokenId];
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal override {
        super._transferFrom(_from, _to, _tokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        IERC20 stakeToken = poolIdentifier.stakeToken;
        IERC20 rewardToken = poolIdentifier.rewardToken;
        uint256 poolIndex = poolIdentifier.poolIndex;

        uint256 tokenIndex = tokenIdToIndex[_tokenId];

        uint256 length = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].length;
        uint256 endingToken = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][length - 1];

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][tokenIndex] = endingToken;
        tokenIdToIndex[endingToken] = tokenIndex;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].pop();

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].push(_tokenId);
        tokenIdToIndex[_tokenId] = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].length - 1;

        delIdFromAllIdList(_from, _tokenId);
        addIdToAllIdList(_to, nextTokenId);
    }

    function mint(
        address _to,
        IERC20 stakeToken,
        IERC20 rewardToken,
        uint256 poolIndex
    ) external onlyMinter() returns (uint256 tokenId) {
        require(address(uriGenerator) != address(0), "Uri Generator has not been set yet.");
        _mint(_to, nextTokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[nextTokenId];
        poolIdentifier.stakeToken = stakeToken;
        poolIdentifier.rewardToken = rewardToken;
        poolIdentifier.poolIndex = poolIndex;

        tokenIdToIndex[nextTokenId] = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].length;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_to].push(nextTokenId);
        addIdToAllIdList(_to, nextTokenId);

        tokenId = nextTokenId;
        nextTokenId += 1;
    }

    function burn(address _from, uint256 _tokenId) external onlyMinter() {
        _burn(_from, _tokenId);

        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        IERC20 stakeToken = poolIdentifier.stakeToken;
        IERC20 rewardToken = poolIdentifier.rewardToken;
        uint256 poolIndex = poolIdentifier.poolIndex;

        uint256 tokenIndex = tokenIdToIndex[_tokenId];
        uint256 length = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].length;
        uint256 endingToken = poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][length - 1];

        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from][tokenIndex] = endingToken;
        tokenIdToIndex[endingToken] = tokenIndex;
        poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_from].pop();

        delIdFromAllIdList(_from, _tokenId);
    }

    function setTokenName(string calldata name) external onlyOwner() {
        nftName = name;
    }

    function setTokenSymbol(string calldata symbol) external onlyOwner() {
        nftSymbol = symbol;
    }

    function getTokenParameters(uint256 _tokenId) external view validNFToken(_tokenId) returns (IERC20, IERC20, uint256) {
        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];
        return (poolIdentifier.stakeToken, poolIdentifier.rewardToken, poolIdentifier.poolIndex);
    }

    function getEncodedSvg(
        PoolIdentifier storage poolIdentifier,
        string memory poolIndex,
        string memory stakedAmount,
        string memory stakeShare
    ) internal view returns (string memory) {
        return uriGenerator.getEncodedSvg(
            poolIdentifier.stakeToken.symbol(),
            poolIdentifier.rewardToken.symbol(),
            stakedAmount,
            stakeShare,
            poolIndex
        );
    }

    function getDetailsOfToken(PoolIdentifier storage poolIdentifier) internal view returns (string memory, string memory, string memory) {
        return (
            address(poolIdentifier.stakeToken).toString(),
            address(poolIdentifier.rewardToken).toString(),
            poolIdentifier.poolIndex.toString()
        );
    }

    function getTokenURI(
        PoolIdentifier storage poolIdentifier,
        string memory stakeToken,
        string memory rewardToken,
        string memory poolIndex,
        string memory stakedAmount,
        string memory stakeShare,
        string memory availableRewards,
        string memory withdrawnRewards
    ) internal view returns (string memory) {
        string memory encodedSvg = getEncodedSvg(poolIdentifier, poolIndex, stakedAmount, stakeShare);

        string memory json = uriGenerator.getJSON(
            nftName,
            stakeToken,
            rewardToken,
            poolIndex,
            encodedSvg,
            stakedAmount,
            availableRewards,
            withdrawnRewards
        );

        return uriGenerator.getTokenURI(json);
    }

    function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory) {
        PoolIdentifier storage poolIdentifier = tokenIdToPoolIdentifier[_tokenId];

        (string memory stakeToken, string memory rewardToken, string memory poolIndex) = getDetailsOfToken(poolIdentifier);
        (
            string memory stakedAmount,
            string memory stakeShare,
            string memory availableRewards,
            string memory withdrawnRewards
        ) = stakingContract.getNFTAttributes(poolIdentifier.stakeToken, poolIdentifier.rewardToken, poolIdentifier.poolIndex, _tokenId);

        return getTokenURI(poolIdentifier, stakeToken, rewardToken, poolIndex, stakedAmount, stakeShare, availableRewards, withdrawnRewards);
    }

    function getTokenIdsOfOwner(IERC20 stakeToken, IERC20 rewardToken, uint256 poolIndex, address _owner) external view returns (uint256[] memory) {
        return poolTypeAndOwnerToTokenId[stakeToken][rewardToken][poolIndex][_owner];
    }

    function getAllTokenIdsOfOwner(address _owner) external view returns (uint256[] memory) {
        return allTokenIdsOfUser[_owner];
    }
}