// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITroveStreetPunks {

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function walletOfOwner(address _address) external view returns (uint256[] memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITroveStreetPunksMetadata.sol";
import "./ITroveStreetPunksReward.sol";
import "./ITroveStreetPunks.sol";

contract TroveStreetPunksStakingTest is Ownable {

    struct StakingInfo {
        uint256 unlockTimestamp;
        uint256 startTimestamp;
        uint256 bonusEnd;
        uint256 bonus;
    }

    uint256 public constant TOKENS_PER_SECOND = 0.0002315 ether;
    uint256 public constant LOCK_SECONDS = 15 minutes;
    uint256 public constant MAX_SUPPLY = 10000;

    address public TOKEN = 0x98Ae7097937C1a49d03f1A3B9D352A2B4604DBAD;

    uint256 public endTimestamp = 1672531199;

    uint256 public bonusTimestamp;
    uint256 public bonusValue;

    address public metadataAddress;
    address public rewardAddress;

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => StakingInfo) private stakingInfo;

    uint256[] private allTokens;
    mapping(uint256 => uint256) private allTokensIndex;
    mapping(uint256 => uint256) private ownedTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private ownedTokens;

    constructor() { }

    function setTokenAddress(address _address) external onlyOwner {
        TOKEN = _address;
    }

    function emergencyUnlock(uint256 _tokenId, address _to) external onlyOwner {
        require(owners[_tokenId] == address(0), "Must be sent directly to contract");
        ITroveStreetPunks(TOKEN).transferFrom(address(this), _to, _tokenId);
    }

    function setEndTimestamp(uint256 _timestamp) external onlyOwner {
        require(_timestamp > block.timestamp, "Must end in the future");
        endTimestamp = _timestamp;
    }

    function setMetadataAddress(address _address) external onlyOwner {
        metadataAddress = _address;
    }

    function setRewardAddress(address _address) external onlyOwner {
        rewardAddress = _address;
    }

    function setBonus(uint256 _timestamp, uint256 _value) external onlyOwner {
        bonusTimestamp = _timestamp;
        bonusValue = _value;
    }

    function transferBatch(uint256[] memory _id, address _to) external {
        address owner = _msgSender();
        uint256 length = _id.length;
        
        for (uint256 i; i < length; i ++) {
            ITroveStreetPunks(TOKEN).transferFrom(owner, _to, _id[i]);
        }
    }

    function stakeBatch(uint256[] memory _id, uint256[] memory _dna, bytes[] memory _signature) external {
        uint256 length = _id.length;

        for (uint256 i; i < length; i ++) {
            stake(_id[i], _dna[i], _signature[i]);
        }
    }

    function unstakeBatch(uint256[] memory _id) external {
        uint256 length = _id.length;

        for (uint256 i; i < length; i ++) {
            unstake(_id[i]);
        }
    }

    function claimBatch(uint256[] memory _id) external {
        uint256 length = _id.length;

        for (uint256 i; i < length; i ++) {
            claim(_id[i]);
        }
    }

    function emergencyUnstakeBatch(uint256[] memory _id) external {
        uint256 length = _id.length;

        for (uint256 i; i < length; i ++) {
            emergencyUnstake(_id[i]);
        }
    }

    function wallet(address _address) 
        external 
        view 
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        (
            uint256[] memory unlocked, 
            uint256[] memory locked
        ) = walletOfOwnerSplit(_address);

        return (
            totalSupply(),
            ITroveStreetPunks(TOKEN).totalSupply(),
            ITroveStreetPunksReward(rewardAddress).balanceOf(_address),
            rewardsOf(_address),
            ITroveStreetPunks(TOKEN).walletOfOwner(_address),
            unlocked,
            locked
        );
    }

    function resource(uint256 _tokenId) 
        external 
        view 
        returns (
            string memory,
            uint256,
            StakingInfo memory
        ) 
    {
        StakingInfo memory info = stakingInfo[_tokenId];

        return (
            ITroveStreetPunks(TOKEN).tokenURI(_tokenId),
            _rewardOf(info, block.timestamp),
            info
        );
    }

    function stake(uint256 _tokenId, uint256 _dna, bytes memory _signature) public {
        uint256 timestamp = block.timestamp;

        require(endTimestamp > timestamp, "Staking has ended");
        require(owners[_tokenId] == address(0), "Token already staked");

        address owner = _msgSender();

        _addTokenToAllTokensEnumeration(_tokenId);
        _addTokenToOwnerEnumeration(owner, _tokenId);

        owners[_tokenId] = owner;
        balances[owner] += 1;

        StakingInfo storage info = stakingInfo[_tokenId];

        info.startTimestamp = timestamp;

        if (info.unlockTimestamp == 0) {
            info.unlockTimestamp = timestamp + LOCK_SECONDS;
        }

        if (bonusTimestamp > timestamp) {
            info.bonusEnd = bonusTimestamp;
            info.bonus = bonusValue;
        }

        if (!ITroveStreetPunksMetadata(metadataAddress).exists(_tokenId)) {
            ITroveStreetPunksMetadata(metadataAddress).supplyDna(_tokenId, _dna, _signature);
        }

        ITroveStreetPunks(TOKEN).transferFrom(owner, address(this), _tokenId);
    }

    function unstake(uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);

        require(_msgSender() == owner, "Sender is not owner");

        _removeTokenFromOwnerEnumeration(owner, _tokenId);
        _removeTokenFromAllTokensEnumeration(_tokenId);

        delete owners[_tokenId];
        balances[owner] -= 1;

        StakingInfo storage info = stakingInfo[_tokenId];

        uint256 timestamp = block.timestamp;

        require(_breedable(info, timestamp), "Token still locked");

        uint256 amount = _rewardOf(info, timestamp);
        
        info.startTimestamp = 0;
        info.bonusEnd = 0;
        info.bonus = 0;

        if (amount > 0) {
            ITroveStreetPunksReward(rewardAddress).mint(owner, amount);
        }

        ITroveStreetPunks(TOKEN).transferFrom(address(this), owner, _tokenId);
    }

    function claim(uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);

        require(_msgSender() == owner, "Sender is not owner");

        StakingInfo storage info = stakingInfo[_tokenId];

        uint256 timestamp = block.timestamp;

        uint256 amount = _rewardOf(info, timestamp);

        info.startTimestamp = timestamp;

        if (amount > 0) {
            ITroveStreetPunksReward(rewardAddress).mint(owner, amount);
        }
    }

    function emergencyUnstake(uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);

        require(_msgSender() == owner, "Sender is not owner");

        _removeTokenFromOwnerEnumeration(owner, _tokenId);
        _removeTokenFromAllTokensEnumeration(_tokenId);

        delete owners[_tokenId];
        balances[owner] -= 1;

        StakingInfo storage info = stakingInfo[_tokenId];

        require(_breedable(info, block.timestamp), "Token still locked");
        
        info.startTimestamp = 0;
        info.bonusEnd = 0;
        info.bonus = 0;

        ITroveStreetPunks(TOKEN).transferFrom(address(this), owner, _tokenId);
    }

    function walletOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 count = balanceOf(_address);
        uint256[] memory ids = new uint256[](count);

        for (uint256 i; i < count; i ++) {
            ids[i] = tokenOfOwnerByIndex(_address, i);
        }

        return ids;
    }

    function walletOfOwnerSplit(address _address) 
        public 
        view 
        returns (
            uint256[] memory,
            uint256[] memory
        ) 
    {
        uint256 count = balanceOf(_address);
        uint256[] memory unlocked = new uint256[](count + 1);
        uint256[] memory locked = new uint256[](count + 1);
        uint256 tokenId;
        uint256 uid;
        uint256 lid;

        for (uint256 i; i < count; i ++) {

            tokenId = tokenOfOwnerByIndex(_address, i);

            if (breedable(tokenId)) {
                unlocked[uid ++] = tokenId;
            } else {
                locked[lid ++] = tokenId;
            }
 
        }

        unlocked[uid] = MAX_SUPPLY; 
        locked[lid] = MAX_SUPPLY;   

        return (
            unlocked,
            locked
        );
    }

    function rewardOf(uint256 _tokenId) public view returns (uint256) {
        StakingInfo memory info = infoOf(_tokenId);
        return _rewardOf(info, block.timestamp);
    }

    function rewardsOf(address _address) public view returns (uint256) {
        uint256[] memory ids = walletOfOwner(_address);
        uint256 length = ids.length;
        uint256 amount;

        uint256 timestamp = block.timestamp;

        for (uint256 i; i < length; i ++) {
            amount += _rewardOf(stakingInfo[ids[i]], timestamp);
        }

        return amount;
    }

    function breedable(uint256 _tokenId) public view returns (bool) {
        uint256 unlockTimestamp = stakingInfo[_tokenId].unlockTimestamp;

        return unlockTimestamp != 0 && unlockTimestamp < block.timestamp;
    }
    
    function infoOf(uint256 _tokenId) public view returns (StakingInfo memory) {
        StakingInfo memory info = stakingInfo[_tokenId];
        require(info.unlockTimestamp != 0, "No staking history");
        return info;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = owners[_tokenId];
        require(owner != address(0), "Token not staked");
        return owner;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Invalid address");
        return balances[_owner];
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner), "Owner index out of bounds");
        return ownedTokens[_owner][_index];
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply(), "Global index out of bounds");
        return allTokens[_index];
    }

    function _breedable(StakingInfo memory _info, uint256 _timestamp) internal pure returns (bool) {
        return _info.unlockTimestamp < _timestamp;
    }

    function _calculateReward(uint256 _start, uint256 _end, uint256 _deadline, uint256 _rate) internal pure returns (uint256) {
        uint256 end = _end < _deadline ? _end : _deadline;

        if (end > _start)
            return (end - _start) * _rate;
            
        return 0;
    }

    function _rewardOf(StakingInfo memory _info, uint256 _timestamp) internal view returns (uint256) {
        if (_info.startTimestamp == 0)
            return 0;

        uint256 amount = _calculateReward(_info.startTimestamp, _timestamp, endTimestamp, TOKENS_PER_SECOND);
        amount += _calculateReward(_info.startTimestamp, _timestamp, _info.bonusEnd, _info.bonus);

        return amount;
    }

    function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
        uint256 length = balanceOf(_to);

        ownedTokens[_to][length] = _tokenId;
        ownedTokensIndex[_tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 _tokenId) private {
        allTokensIndex[_tokenId] = allTokens.length;

        allTokens.push(_tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
        uint256 lastTokenIndex = balanceOf(_from) - 1;
        uint256 tokenIndex = ownedTokensIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];

            ownedTokens[_from][tokenIndex] = lastTokenId;
            ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete ownedTokensIndex[_tokenId];
        delete ownedTokens[_from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
        uint256 lastTokenIndex = allTokens.length - 1;
        uint256 tokenIndex = allTokensIndex[_tokenId];

        uint256 lastTokenId = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastTokenId;
        allTokensIndex[lastTokenId] = tokenIndex;

        delete allTokensIndex[_tokenId];

        allTokens.pop();
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

pragma solidity ^0.8.9;

interface ITroveStreetPunksMetadata {

    function supplyDna(uint256 _tokenId, uint256 _dna, bytes memory _signature) external;

    function metadataOf(uint256 _tokenId) external view returns (string memory);

    function traitsOf(uint256 _tokenId) external view returns (uint256[] memory);

    function dnaOf(uint256 _tokenId) external view returns (uint256);

    function exists(uint256 _tokenId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITroveStreetPunksReward {

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);

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