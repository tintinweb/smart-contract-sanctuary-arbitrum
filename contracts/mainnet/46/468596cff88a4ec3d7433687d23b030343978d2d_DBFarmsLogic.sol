/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        // Clear approvals from the previous owner
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
interface RewardsPool {
    function mint(uint256 amount, IERC20 token, address recipient) external;
}
interface Master {
    function setTotalAllocPoint(uint256 _newValue) external;
    function setUser(uint _pid, address _account, DBFarmsLogic.UserInfo memory _user) external;
    function addUserBoosters(uint _pid, address _account, DBFarmsLogic.UserBoosters memory _userBoosters) external;
    function removeUserBoosters(uint _pid, address _account, DBFarmsLogic.UserBoosters memory _userBoosters) external;
    function pushToPool(DBFarmsLogic.PoolInfo memory pool) external;
    function setPool(uint _pid, DBFarmsLogic.PoolInfo memory _pool) external;
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function recoverToken(address _account, uint256 _amount, IERC20 _token) external;
    function recoverNft(address _account, uint256 _id, ERC721 _nft) external;
    function emitDeposit(address _account, uint256 _pid, uint256 _amount) external;
    function emitWithdraw(address _account, uint256 _pid, uint256 _amount) external;
    function emitEmergencyWithdraw(address _account, uint256 _pid, uint256 _amount) external;

    function getRewardToken() external view returns(IERC20);
    function getRewardWallet() external view returns(address);
    function getTotalAllocPoint() external view returns(uint256);
    function getMultiplier() external view returns(uint256);
    function getMaxBoost() external view returns(uint256);
    function getRewardPerSecond() external view returns(uint256);
    function getUser(uint _pid, address _account) external view returns(DBFarmsLogic.UserInfo memory);
    function getUserBoosters(uint _pid, address _account) external view returns(DBFarmsLogic.UserBoosters[] memory);
    function getPool(uint _pid) external view returns(DBFarmsLogic.PoolInfo memory);
    function getTotalPools() external view returns (uint);
    function getTvl(uint _pid) external view returns(uint256);
    function getUserBoostRate(uint256 _pid, address _account) external view returns (uint256);
}
interface Admin {
    function getVaultMultiplier() external view returns(uint256);
    function isAllowed(address account) external view returns (bool);
    function isBlocked(uint _pid) external view returns(bool);
}

contract DBFarmsLogic {
    using SafeMath for uint256;

    address internal masterContract;
    address internal adminContract;
    address public owner;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 totalIn;
        uint256 totalOut;
        uint256 totalRewards;
    }
    struct PoolInfo {
        string name;
        IERC20 lpToken;
        bool isLp;
        uint256 allocPoint;
        uint256 lastTimestamp;
        uint256 accPerShare;
        ERC721[] boosters;
        string[] boostersMetaData;
        uint256[] boostersPerc;
    }
    struct UserBoosters {
        ERC721 booster;
        uint256 tokenId;
    }

    constructor(address _masterContract, address _adminContract, address _owner) {
        masterContract = _masterContract;
        adminContract = _adminContract;
        owner = _owner;
    }

    /* ---------- AdminManagement ---------- */
    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "not owner");
        owner = _newOwner;
    }
    function setAdminContract(address _newAdminContract) public {
        require(msg.sender == owner, "not owner");
        adminContract = _newAdminContract;
    }

    /* ---------- PoolManagement ---------- */
    function addPool(string memory _name, uint256 _allocPoint, IERC20 _lpToken, bool _isLp) public {
        require(msg.sender == masterContract, "not auth");
        massUpdatePools();
        ERC721[] memory boosters;
        string[] memory boostersMetaData;
        uint256[] memory boostersPerc;
        Master(masterContract).setTotalAllocPoint(Master(masterContract).getTotalAllocPoint().add(_allocPoint));
        Master(masterContract).pushToPool(PoolInfo({name: _name, lpToken: _lpToken, isLp: _isLp, allocPoint: _allocPoint, lastTimestamp: block.timestamp, accPerShare: 0, boosters: boosters, boostersMetaData: boostersMetaData, boostersPerc: boostersPerc}));
    }
    function setPool(uint256 _pid, uint256 _allocPoint) public {
        require(msg.sender == masterContract, "not auth");
        massUpdatePools();
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        uint256 prevAllocPoint = pool.allocPoint;
        pool.allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            uint256 totalAllocPoint = Master(masterContract).getTotalAllocPoint();
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            Master(masterContract).setTotalAllocPoint(totalAllocPoint);
            Master(masterContract).setPool(_pid, pool);
        }
    }
    function updatePool(uint256 _pid) public {
        require(msg.sender == masterContract, "not auth");
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        if (block.timestamp <= pool.lastTimestamp) {
            return;
        }
        uint256 lpSupply = Master(masterContract).getTvl(_pid);
        if (lpSupply == 0) {
            pool.lastTimestamp = block.timestamp;
            return;
        }
        uint256 secs = block.timestamp.sub(pool.lastTimestamp);
        uint256 rate = Master(masterContract).getRewardPerSecond().mul(Master(masterContract).getMultiplier()).div(1000);
        uint256 reward = secs.mul(rate).mul(pool.allocPoint).div(Master(masterContract).getTotalAllocPoint());
        pool.accPerShare = pool.accPerShare.add(reward.mul(1e18).div(lpSupply));
        pool.lastTimestamp = block.timestamp;
        Master(masterContract).setPool(_pid, pool);
    }
    function massUpdatePools() internal {
        uint256 length = Master(masterContract).getTotalPools();
        for (uint256 pid = 0; pid < length; ++pid) {
            Master(masterContract).updatePool(pid);
        }
    }
    function addBooster() public view {
        require(msg.sender == masterContract, "not auth");
        revert("not avail");
    }
    function setBooster(uint256 _pid, ERC721 _booster, string memory _boosterMetaData, uint256 _boosterPerc) public {
        require(msg.sender == masterContract, "not auth");
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        uint nftId = 0;
        for (uint i = 0; i < pool.boosters.length; i++) {
            if (pool.boosters[i] == _booster) {
                nftId = i;
                break;
            }
        }
        if (nftId > 0) {
            pool.boostersMetaData[nftId] = _boosterMetaData;
            pool.boostersPerc[nftId] = _boosterPerc;
            Master(masterContract).setPool(_pid, pool);
        } else {
            return;
        }
    }

    /* ---------- StakingManagement ---------- */
    function deposit(uint256 _pid, uint256 _amount, address _account) public {
        require(msg.sender == masterContract, "not auth");
        if(!Admin(adminContract).isAllowed(_account)) {
            require(!Admin(adminContract).isBlocked(_pid), "farm blocked");
        }
        Master(masterContract).updatePool(_pid);
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        UserInfo memory user = Master(masterContract).getUser(_pid, _account);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                if(Admin(adminContract).isAllowed(_account)) {
                    pending = pending.mul(Admin(adminContract).getVaultMultiplier()).div(100);
                }
                user.totalRewards = user.totalRewards.add(pending);
                RewardsPool(Master(masterContract).getRewardWallet()).mint(pending, Master(masterContract).getRewardToken(), _account);
            }
        }
        if (_amount > 0) {
            pool.lpToken.transferFrom(_account, masterContract, _amount);
            user.totalIn = user.totalIn.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e18);
        Master(masterContract).setUser(_pid, _account, user);
        Master(masterContract).emitDeposit(_account, _pid, _amount);
    }
    function withdraw(uint256 _pid, uint256 _amount, address _account) public {
        require(msg.sender == masterContract, "not auth");
        Master(masterContract).updatePool(_pid);
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        UserInfo memory user = Master(masterContract).getUser(_pid, _account);
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            if(Admin(adminContract).isAllowed(_account)) {
                pending = pending.mul(Admin(adminContract).getVaultMultiplier()).div(100);
            }
            user.totalRewards = user.totalRewards.add(pending);
            RewardsPool(Master(masterContract).getRewardWallet()).mint(pending, Master(masterContract).getRewardToken(), _account);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            user.totalOut = user.totalOut.add(_amount);
            Master(masterContract).recoverToken(_account, _amount, pool.lpToken);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e18);
        Master(masterContract).setUser(_pid, _account, user);
        Master(masterContract).emitWithdraw(_account, _pid, _amount);
    }
    function emergencyWithdraw(uint256 _pid, address _account) public {
        require(msg.sender == masterContract, "not auth");
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        UserInfo memory user = Master(masterContract).getUser(_pid, _account);
        user.totalOut = user.totalOut.add(user.amount);
        Master(masterContract).recoverToken(_account, user.amount, pool.lpToken);
        user.amount = 0;
        user.rewardDebt = 0;
        Master(masterContract).setUser(_pid, _account, user);
        Master(masterContract).emitEmergencyWithdraw(_account, _pid, user.amount);
    }
    function boost(uint256 _pid, address _account, ERC721 _booster, uint256 _tokenId) public view {
        require(msg.sender == masterContract, "not auth");
        _pid = 0;
        _account = address(0);
        _tokenId = _tokenId;
        _booster = _booster;
        revert("not complete");
    }
    function unboost(uint256 _pid, address _account, ERC721 _booster, uint256 _tokenId) public view {
        require(msg.sender == masterContract, "not auth");
        _pid = 0;
        _account = address(0);
        _tokenId = _tokenId;
        _booster = _booster;
        revert("not complete");
    }
    function compound(uint256 _pid, address _account) public view {
        require(msg.sender == masterContract, "not auth");
        _pid = 0;
        _account = address(0);
        revert("not complete");
    }
    function zapIn(uint256 _pid, address _account, uint256 _amount, address _token) public payable {
        require(msg.sender == masterContract, "not auth");
        require(msg.value == _amount, "false");
        _pid = 0;
        _amount = 0;
        _account = address(0);
        _token = address(0);
        revert("not complete");
    }
    function pendingRewards(uint256 _pid, address _account) public view returns(uint256) {
        require(msg.sender == masterContract, "not auth");
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        UserInfo memory user = Master(masterContract).getUser(_pid, _account);
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = Master(masterContract).getTvl(_pid);
        if (block.timestamp > pool.lastTimestamp && lpSupply != 0) {
            uint256 secs = block.timestamp.sub(pool.lastTimestamp);
            uint256 rate = Master(masterContract).getRewardPerSecond().mul(Master(masterContract).getMultiplier()).div(1000);
            uint256 reward = secs.mul(rate).mul(pool.allocPoint).div(Master(masterContract).getTotalAllocPoint());
            accPerShare = accPerShare.add(reward.mul(1e18).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
        if (pending == 0) {
            return 0;
        } else {
            if(Admin(adminContract).isAllowed(_account)) {
                pending = pending.mul(Admin(adminContract).getVaultMultiplier()).div(100);
            }
            return pending;
        }
    }
    function getUserBoostRate(uint256 _pid, address _account) public view returns (uint256) {        
        require(msg.sender == masterContract, "not auth");
        UserBoosters[] memory userBoosters = Master(masterContract).getUserBoosters(_pid, _account);        
        PoolInfo memory pool = Master(masterContract).getPool(_pid);
        uint256 perc = 0;
        for(uint i = 0; i < pool.boosters.length; i++){
            for(uint x = 0; x < userBoosters.length; x++) {
                if(pool.boosters[i] == userBoosters[x].booster) {
                    perc = perc.add(pool.boostersPerc[i]);
                }
            }
        }
        return perc;
    }
}