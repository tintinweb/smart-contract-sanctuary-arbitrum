/**
 *Submitted for verification at Arbiscan on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
            if (returndata.length > 0) {
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

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
 
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

  
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NFTStake is Ownable, ERC721Holder {

    IERC20 internal R_Token;
    ERC721 internal NFT;

    bool public paused = true;
    
    uint256 public rvalue = 15740740740741;
    uint256 public totalStaked = 0;
    uint256 public uAdr = 0;
    uint256 public pending = 0;

    struct DataBase {
        address _user;
        uint256 _TokenId;
        uint256 _IsStaked;
        uint256 _StakedTime;
        uint256 _lastClaimed;
    }
    struct ClaimDataBase {
        uint256 _bonusToClaim;
    }

    mapping (address => DataBase[]) public userRecord;
    mapping (address => ClaimDataBase) public claimRecord;
    mapping (uint256 => address) public accountIndex;
    mapping (address => uint256) public accountIDs;
    mapping (uint256 => uint256) public stakedIndex;

    constructor(address _nftAdr, address _token) {
        R_Token = IERC20(_token);
        NFT = ERC721(_nftAdr);
    }

	function setRval(uint256 _rval) public onlyOwner {
		rvalue = _rval;
	}

    function distribute() public onlyOwner {
        uint256 monthlyRewards = ((rvalue * 10000) * 2678400);
        uint256 scBal = ((R_Token.balanceOf(address(this))) - pending);
        uint256 leftToDist = 0;
        if (scBal > monthlyRewards) { leftToDist = (scBal - monthlyRewards); }
        if (leftToDist > 0)
        {  
            uint256 perNFT = (leftToDist / 2) / totalStaked;
            for(uint i = 0; i < uAdr; i++)
            {
                if (stakedIndex[i] > 0)
                {
                    claimRecord[accountIndex[i]]._bonusToClaim += (perNFT * stakedIndex[i]);
                    pending += (perNFT * stakedIndex[i]);
                }
            }
            burn(leftToDist / 2);
        }
    }

    function backupDist() public onlyOwner {
        uint256 monthlyRewards = (rvalue * 10000) * 2678400;
        uint256 scBal = ((R_Token.balanceOf(address(this))) - pending);
        uint256 leftToDist = 0;
        if (scBal > monthlyRewards) { leftToDist = (scBal - monthlyRewards); }
        if (leftToDist > 0)
        {  
            leftToDist = (leftToDist / 2);
            R_Token.transfer(msg.sender,leftToDist);
            burn(leftToDist);
        }
    }

    function checkBonus() public view returns (uint256) {
        if (claimRecord[msg.sender]._bonusToClaim > 0)
        {
            return claimRecord[msg.sender]._bonusToClaim;
        }
        else
        {
            return 0;
        }
    }

    function claimBonus() public {
        uint256 bonus = claimRecord[msg.sender]._bonusToClaim;
        require(bonus > 0, "You have no bonus left to claim!");
        require(R_Token.balanceOf(address(this)) >= bonus, "Oops, nothing left in the reward pool");
        claimRecord[msg.sender]._bonusToClaim = 0;
        pending -= bonus;
        R_Token.transfer(msg.sender,bonus);
    }

    function viewAccounts(uint256 from, uint256 to) public view returns (address[] memory) {
        address[] memory theAccounts = new address[](to - from);
        uint x = 0;
        for (uint i = from-1; i < to; i++) {
            if (stakedIndex[i] > 0)
            {
                theAccounts[x] = accountIndex[i];
                x++;
            }
        }
        return theAccounts;
    }

    function stake(uint256[] calldata _tokenIds) public {
        for(uint i =0; i < _tokenIds.length; i++)
        {
            stakeSingle(_tokenIds[i]);
        }
    }

    function stakeSingle(uint _tokenId) public {
        require(!paused,"Staking is Currently Paused!!");
        address account = msg.sender;
        NFT.safeTransferFrom(account, address(this) , _tokenId,"");
        uint userRegistery = getlength(account);
        bool swipper;
        if(userRegistery > 0) {
            DataBase[] storage update = userRecord[account];
            uint i = 0;
            while(i < userRegistery) {
                if(userRecord[account][i]._TokenId == _tokenId) {
                    update[i]._IsStaked = 1;
                    update[i]._StakedTime = block.timestamp;
                    update[i]._lastClaimed = block.timestamp;
                    swipper = true;
                    break;
                }
                i++;
            }
        }
        if(!swipper) {
            userRecord[account].push(
                DataBase({
                    _user: account,
                    _TokenId: _tokenId,
                    _IsStaked: 1,
                    _StakedTime: block.timestamp,
                    _lastClaimed: block.timestamp
                })
            );
        }
        totalStaked += 1;
        if (accountIDs[account] == 0)
        {
            accountIndex[uAdr] = account;
            stakedIndex[uAdr] += 1;
            accountIDs[account] = uAdr;
            uAdr += 1;
        }
        else
        {            
            stakedIndex[accountIDs[account]] += 1;
        }
    }    

    function claimReward() public {
        require(!paused,"Staking is Currently Paused!!");
        address account = msg.sender;
        uint256 totalSecondsCount;
        uint userRegistery = getlength(account);
        if(userRegistery > 0) {
            DataBase[] storage update = userRecord[account];
            uint i = 0;
            while(i < userRegistery) {
                uint256 second = 0;
                if(update[i]._IsStaked == 1) {
                    second = block.timestamp - update[i]._lastClaimed;
                    totalSecondsCount += second;
                    update[i]._lastClaimed =  block.timestamp;
                }
                i++;
            }
        }
        else{
            revert("Error: No Record Found!!");
        }
        uint256 subtotalReward = rvalue * totalSecondsCount;
        if(subtotalReward > 0) {
            R_Token.transfer(account,subtotalReward);
        }
        else {
            revert("Please Wait till the reward Get Generated!!");
        }

    }

    function unstake(uint256[] calldata _tokenIds) public {
        for(uint i =0; i < _tokenIds.length; i++)
        {
            unstakeSingle(_tokenIds[i]);
        }
    }

    function unstakeSingle(uint _tokenId) public {
        require(!paused,"Staking is Currently Paused!!");
        address account = msg.sender;
        uint userRegistery = getlength(account);
        uint[] memory checkIds = getStakeNftId(account);
        uint i;
        bool found;
        uint totalNftReward;
        while(i < userRegistery) {
            if(checkIds[i] == _tokenId) {
                found = true;
                break;
            }
            i++;
        }
        if(found) {
            if(userRegistery > 0) {
                DataBase[] storage update = userRecord[account];
                uint j = 0;
                while(j < userRegistery) {
                    uint256 second = 0;
                    if(update[j]._TokenId == _tokenId) {
                        second = block.timestamp - update[j]._lastClaimed;
                        totalNftReward += second;
                        update[j]._lastClaimed =  block.timestamp;
                        update[j]._IsStaked = 0;
                        break;
                    }
                    j++;
                }
            }
            totalStaked -= 1;
            stakedIndex[accountIDs[account]] -= 1;
            uint256 totalRewardonNft = rvalue * totalNftReward;
            R_Token.transfer(account,totalRewardonNft);
            NFT.transferFrom(address(this),account, _tokenId);
        }
        else{
            revert("Error: No Record Found!!");
        }
        
    }
    
    function checkReward(address _adr) public view returns (uint256) {
        address account = _adr;
        uint256 totalSecondsCount;
        uint userRegistery = getlength(account);
        if(userRegistery > 0) {
            DataBase[] storage update = userRecord[account];
            uint i = 0;
            while(i < userRegistery) {
                uint256 second = 0;
                if(update[i]._IsStaked == 1) {
                    second = block.timestamp - update[i]._lastClaimed;
                    totalSecondsCount += second;
                }
                i++;
            }
        }
        uint256 subtotalReward = rvalue * totalSecondsCount;
        if(subtotalReward > 0) {
            return subtotalReward;
        }
        else {
            return 0;
        }

    }

    function getStakeNftId(address _adr) public view returns (uint256[] memory) {
        address account = _adr;
        uint userRegistery = getlength(account);
        uint256[] memory ownedTokenIds = new uint256[](userRegistery);

        if(userRegistery > 0) {
            DataBase[] storage rec = userRecord[account];
            uint i = 0;
            while(i < userRegistery) {
                if(rec[i]._IsStaked == 1) {
                    ownedTokenIds[i] = rec[i]._TokenId;
                }
                i++;
            }
        }
        else {
            revert("Error: No Record Found!!");
        }
        return ownedTokenIds;   
    }
    
    function getlength(address _adr) internal view returns (uint) {
        return userRecord[_adr].length;
    }

    function rescueTokens(address _adr) public onlyOwner {
        IERC20(_adr).transfer(msg.sender,IERC20(_adr).balanceOf(address(this)));
    }

    function rescueNft(uint _id,address recipient) public onlyOwner {
        NFT.transferFrom(address(this),recipient, _id);
    }

    function setPaused(bool _status) public onlyOwner {
        paused = _status;
    }
    function burn(uint256 amount) public onlyOwner {        
        address deadAdd = 0x000000000000000000000000000000000000dEaD;        
        R_Token.transfer(deadAdd,amount);
    }
}