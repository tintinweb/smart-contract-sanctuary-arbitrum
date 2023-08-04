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
interface Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
interface Farms {
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

    //read
    function getUser(uint _pid, address _account) external view returns(UserInfo memory);
    function getPool(uint _pid) external view returns(PoolInfo memory);
    function getTotalPools() external view returns (uint);
    function pendingRewards(uint256 _pid, address _account) external view returns (uint256);
    function getLogicContract() external view returns(address);
    function getRewardPerSecond() external view returns(uint256);
    function getMultiplier() external view returns(uint256);
    function getTotalAllocPoint() external view returns(uint256);
    function getTvl(uint _pid) external view returns(uint256);

    //write
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}
interface Vaults {
    function mintRewards(uint256 _pid, uint256 _amount, IERC20 _token, address _recipient) external;

    function getRouter() external view returns (address);
    function getTeamWallet() external view returns (address);
    function getRewardWallet() external view returns (address);
}

contract DBVault {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewards;
        uint256 lastStaked;
    }

    uint internal poolId;
    address internal vaults;

    IERC20 internal DBX = IERC20(0x0b257fe969d8782fAcb4ec790682C1d4d3dF1551);
    IERC20 internal vDBX = IERC20(0xc71E4a725c10B38Ddb35BE8aB3d1D77fEd89093F);
    IERC20 internal DBC = IERC20(0x745f63CA36E0cfDFAc4bf0AFe07120dC7e1E0042);
    IERC20 internal WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    Farms internal farms = Farms(0xf2f1565a3801742C42286E2C6717460dFB9aE9CD);
    
    constructor(uint _pid, address _vaults) {
        poolId = _pid;
        vaults = _vaults;
    }

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user);
    event AddAdmin(address indexed user);
    event RemoveAdmin(address indexed user);

    uint256 internal debt = 0;
    uint256 internal accPerShare;
    mapping(address => UserInfo) internal userInfo;

    mapping(address => uint256) internal periodLastReset;
    mapping(address => uint256) internal allTimeTracking;
    mapping(address => uint256) internal periodTracking;

    modifier isVaults() {
        require(vaults == msg.sender, "Vault-isAdmin: caller is not the vaults sc");
        _;
    }

    /* ---------- ReadFunctions ---------- */
    function getPoolId() public view returns (uint256) {
        return poolId;
    }
    function getUser(address _account) public view returns(UserInfo memory) {
        return userInfo[_account];
    }
    function getDebt() public view returns (uint256) {
        return debt;
    }
    function getAccPerShare() public view returns (uint256) {
        return accPerShare;
    }    
    function getPeriodLastReset(address _token) public view returns (uint256) {
        return periodLastReset[_token];
    }
    function getPeriodTracking(address _token) public view returns (uint256) {
        return periodTracking[_token];
    }
    function getAllTimeTracking(address _token) public view returns (uint256) {
        return allTimeTracking[_token];
    }

    /* ---------- WriteFunctions ---------- */
    function deposit(uint256 _amount, address _account) isVaults public {
        UserInfo storage user = userInfo[_account];
        Farms.PoolInfo memory pool = farms.getPool(poolId);
        require(pool.isLp, "Vault-Deposit: pool not allowed");
        require(_amount > 0, "Vault-Deposit: amount must be larger than 0");
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewards = user.rewards.add(pending);
                debt = debt.add(pending);
            }
        }
        IERC20 lpToken = IERC20(pool.lpToken);
        require(lpToken.balanceOf(msg.sender) >= _amount, "Vault-Deposit: balance to low");
        require(lpToken.allowance(msg.sender, address(this)) >= _amount, "Vault-Deposit: amount not approved");
        lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 userAmount = _amount.mul(99).div(100);
        uint256 teamAmount = _amount.sub(userAmount);
        user.amount = user.amount.add(userAmount);
        user.rewardDebt = user.amount.mul(accPerShare).div(1e18);
        user.lastStaked = block.timestamp;
        lpToken.approve(farms.getLogicContract(), userAmount);
        farms.deposit(poolId, userAmount);
        lpToken.transfer(Vaults(vaults).getTeamWallet(), teamAmount);
        periodTracking[address(lpToken)] = periodTracking[address(lpToken)].add(teamAmount);
        allTimeTracking[address(lpToken)] = allTimeTracking[address(lpToken)].add(teamAmount);
        emit Deposit(_account, _amount);
    }  
    function withdraw(uint256 _amount, address _account) isVaults public {
        UserInfo storage user = userInfo[_account];
        Farms.PoolInfo memory pool = farms.getPool(poolId);
        require(pool.isLp, "Vault-Withdraw: pool not allowed");
        require(user.amount >= _amount, "Vault-Withdraw: amount is larger than staked balance");
        uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            user.rewards = user.rewards.add(pending);
            debt = debt.add(pending);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accPerShare).div(1e18);
        farms.withdraw(poolId, _amount);   
        IERC20 lpToken = IERC20(pool.lpToken);
        uint256 userAmount = _amount;
        if (user.lastStaked.add(259200) > block.timestamp) {
            userAmount = _amount.mul(99).div(100);
            uint256 teamAmount = _amount.sub(userAmount);
            lpToken.transfer(Vaults(vaults).getTeamWallet(), teamAmount);
            periodTracking[address(lpToken)] = periodTracking[address(lpToken)].add(teamAmount);
            allTimeTracking[address(lpToken)] = allTimeTracking[address(lpToken)].add(teamAmount);
        }
        lpToken.transfer(_account, userAmount);
        emit Withdraw(_account, userAmount);
    }
    function emergencyWithdraw(address _account) isVaults public {
        UserInfo storage user = userInfo[_account];
        Farms.PoolInfo memory pool = farms.getPool(poolId);
        require(pool.isLp, "Vault-EmergencyWithdraw: pool not allowed");
        farms.withdraw(poolId, user.amount);
        IERC20 lpToken = IERC20(pool.lpToken);
        uint256 userAmount = user.amount;
        if (user.lastStaked.add(259200) > block.timestamp) {
            userAmount = user.amount.mul(99).div(100);
            uint256 teamAmount = user.amount.sub(userAmount);
            lpToken.transfer(Vaults(vaults).getTeamWallet(), teamAmount);
            periodTracking[address(lpToken)] = periodTracking[address(lpToken)].add(teamAmount);
            allTimeTracking[address(lpToken)] = allTimeTracking[address(lpToken)].add(teamAmount);
        }
        lpToken.transfer(_account, userAmount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(_account, user.amount);
    }
    function harvest(address _account) isVaults public {
        Farms.PoolInfo memory pool = farms.getPool(poolId);
        require(pool.isLp, "Vault-Harvest: pool not allowed");
        UserInfo storage user = userInfo[_account];
        uint256 pending = user.rewards;
        if (user.amount > 0) {
            pending = pending.add(user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt));
        }
        require(pending > 0, "Vault-Harvest: no rewards pending");
        require(farms.getUser(0, address(this)).amount >= pending, "Vault-Harvest: rewards pool low");
        farms.withdraw(0, pending);

        address[] memory path;
        path = new address[](3);
        path[0] = address(DBX);
        path[1] = address(WETH);
        path[2] = address(DBC);
        uint256[] memory amountOut = Router(Vaults(vaults).getRouter()).getAmountsOut(pending.mul(30).div(100), path);

        uint256 fee = pending.mul(50).div(100);
        DBX.transfer(_account, pending.mul(50).div(100));
        DBX.transfer(Vaults(vaults).getRewardWallet(), fee);
        Vaults(vaults).mintRewards(poolId, amountOut[2], DBC, _account);
        Vaults(vaults).mintRewards(poolId, pending.mul(20).div(100), vDBX, _account);
        debt = debt.sub(user.rewards);
        user.rewards = 0;
        user.rewardDebt = user.amount.mul(accPerShare).div(1e18);
        periodTracking[address(DBX)] = periodTracking[address(DBX)].add(fee);
        allTimeTracking[address(DBX)] = allTimeTracking[address(DBX)].add(fee);
    }
    function autoCompound() isVaults public {
        farms.withdraw(0, 0);
        farms.withdraw(poolId, 0);
        uint256 balance = DBX.balanceOf(address(this));
        uint256 totalStaked = farms.getUser(poolId, address(this)).amount;
        if(balance > 0 && totalStaked > 0) {
            accPerShare = accPerShare.add(balance.mul(1e18).div(totalStaked));
        }
        if(balance > 0) {
            DBX.approve(farms.getLogicContract(), balance);
            farms.deposit(0, balance);
        }
    }    
    function pendingRewards(address _account) public view returns (uint256, uint256, uint256) {
        Farms.PoolInfo memory pool = farms.getPool(poolId);
        require(pool.isLp, "Vault-Pending: pool not allowed");
        UserInfo storage user = userInfo[_account];
        uint256 pending = user.rewards;

        if (user.amount > 0) {
            uint256 reward = farms.pendingRewards(poolId, address(this));
            uint256 dbxReward = farms.pendingRewards(0, address(this));
            uint256 accRate = accPerShare.add(reward.mul(1e18).div(farms.getUser(poolId, address(this)).amount));
            accRate = accRate.add(dbxReward.mul(1e18).div(farms.getUser(poolId, address(this)).amount));
            pending = pending.add(user.amount.mul(accRate).div(1e18).sub(user.rewardDebt));
        }

        if (pending == 0) {
            return (0, 0, 0);
        } else {
            address[] memory path;
            path = new address[](3);
            path[0] = address(DBX);
            path[1] = address(WETH);
            path[2] = address(DBC);
            uint256[] memory amountOut = Router(Vaults(vaults).getRouter()).getAmountsOut(pending.mul(30).div(100), path);

            uint256 pendingDbx = pending.mul(50).div(100);
            uint256 pendingDbc = amountOut[2];
            uint256 pendinVdbx = pending.mul(20).div(100);

            return (pendingDbx, pendingDbc, pendinVdbx);
        }
    }
    function resetPeriodTracking(address _token) isVaults public {
        periodLastReset[_token] = block.timestamp;
        periodTracking[_token] = 0;
    }
}