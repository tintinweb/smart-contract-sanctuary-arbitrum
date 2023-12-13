// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./openzeppelin/Initializable.sol";
import "../IERC20.sol";
import "../TransferHelper.sol";
import "./SupportedTokens.sol";
import "./IERC165-SupportsInterface.sol";
import "./DVaultConfig.sol";



interface IERC721 {

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function balanceOf(address _owner) external view returns (uint256);
}

interface EverRiseNFT is IERC721 {

    function withdrawRewards() external;
    function unclaimedRewardsBalance(address) external view returns (uint256);
    function getTotalRewards(address) external view returns (uint256);
}

interface IERC1155 {

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external; 
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

interface IERC721Receiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(address _operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}

contract DVault is Initializable, IERC721Receiver, IERC1155Receiver {
    using TransferHelper for IERC20;

    enum VaultStatus {
        LOCKED,
        UNLOCKED
    }

    enum BlockStatus {
        FALSE,
        TRUE
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct NFTList {
        address token;
        uint256 tokenId;
        TokenType tokenType;
        uint256 amount;
    }

    struct Balance {
        address token;
        uint256 balance;
        uint8 decimals;
    }

    struct VaultDetails {
        string name;
        address owner1;
        address owner2;
        string uri;
        VaultStatus owner1Status;
        VaultStatus owner2Status;
        VaultStatus status;
        uint256 lockTime;
        uint256 lockInitiatedTime;
        address lockInitiatedAddress;
        uint256 unlockInitiatedTime;
        bool owner1BlockStatus;
        bool owner2BlockStatus;
    }

    string public _name;
    address public _owner1;
    address public _owner2;
    string public _uri;
    DVaultConfig _vaultConfig;
    address public _factory;
    uint256 public deadline;
    uint256 public deadlineInitiated;
    address deadlineInitiatedOwner;

    SupportedTokens public _globalList;
    mapping (address => bool) _supportedTokens;
    address[] _tokensList;
    uint256 public _unlockInitiatedTime;

    VaultStatus _vaultStatus;
    VaultStatus _owner1Status;
    VaultStatus _owner2Status;
    mapping(address => bool) _ownerBlockStatus;

    error CurrentlyLocked(); //0x34ae7439
    error CurrentlyUnLocked(); //0xc799605c
    error TokenNotSupported(); //0x3dd1b305
    error NotZeroAddress(); //0x66385fa3
    error FailedETHSend(); //0xaf3f2195
    error InsufficientBalance(); //0xf4d678b8
    error UnAuthorized(); //0xbe245983
    error TimeLocked(); //0x56f38557
    error AlreadyTimeLocked(); //0x6341b790
    error NotEnoughRewards(); //0x1e6918b1
    error BlockedOwner(); //0x1c248638
    error AlreadyBlocked(); //0x196a151c
    error InvalidOwner(); //0x49e27cff

    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    constructor() {}

    function initialize(string memory name, address owner1, address owner2, address factory, string memory uri, DVaultConfig vaultConfig, SupportedTokens globalList) public initializer {
        _name = name;
        _owner1 = owner1;
        _owner2 = owner2;
        _factory = factory;
        _uri = uri;
        _vaultConfig = vaultConfig;
        _globalList = globalList;
    }

    receive() external payable  {}

    fallback() external payable {}

    modifier authorizedOwner() {
        if (msg.sender != _owner1 && msg.sender != _owner2) revert UnAuthorized();
        _;
    }

    modifier onlyFactory() {
        if (msg.sender != _factory) revert UnAuthorized();
        _;
    }

    modifier notBlocked() {
        if (_ownerBlockStatus[msg.sender]) revert BlockedOwner();
        _;
    }

    modifier supportedToken(address token) {
        if (token != address(0) && !isTokenSupported(token)) revert TokenNotSupported();
        _;
    }

    modifier unLocked() {
        if (_vaultStatus == VaultStatus.LOCKED) revert CurrentlyLocked();
        _;
    }

    modifier locked() {
        if (_vaultStatus == VaultStatus.UNLOCKED) revert CurrentlyUnLocked();
        _;
    }

    modifier completelyLocked() {
        if (_owner1Status == VaultStatus.UNLOCKED || _owner2Status == VaultStatus.UNLOCKED) revert CurrentlyUnLocked();
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount should be greater than 0");
        _;
    }

    function addSupportedToken(address token) external authorizedOwner notBlocked {
        require (!_supportedTokens[token], "Already Supported");
        _supportedTokens[token] = true;
        _tokensList.push(token);
    }

    function getTokensList() public view returns (address[] memory) {
        return _tokensList;
    }

    function isSupportedToken(address token) public view returns (bool) {
        return _supportedTokens[token];
    }

    function isTokenSupported(address token) public view returns (bool) {
        return isSupportedToken(token) || SupportedTokens(_globalList).isSupportedToken(token);
    }

    function updateName(string memory name) external authorizedOwner notBlocked {
        _name = name;
    }

    function updateLogo(string memory uri) external authorizedOwner notBlocked {
        _uri = uri;
    }

    function isAuthorizedOwner(address addr) external view returns (bool) {
        return ((addr == _owner1 || addr == _owner2) && !_ownerBlockStatus[addr]);
    }

    function initiateTimeLock(uint256 time) external authorizedOwner completelyLocked {
        if (deadline > block.timestamp) revert AlreadyTimeLocked();
        deadlineInitiatedOwner = msg.sender;
        deadlineInitiated = time + block.timestamp;
    }

    function approveTimeLock() external authorizedOwner completelyLocked {
        if (msg.sender == deadlineInitiatedOwner) revert UnAuthorized();
        if (_vaultConfig.getCollectTimelockFee()) {
            _collectFee(_vaultConfig.getTimeLockFeeTokenAddress(), _vaultConfig.getFeeAddress(), _vaultConfig.getTimeLockFeeAmount());
        }
        deadline = deadlineInitiated;
        deadlineInitiated = 0;
    }

    function rejectTimeLock() external authorizedOwner completelyLocked {
        deadlineInitiated = 0;
    }

    function blockOtherOwner() external authorizedOwner notBlocked locked {

        if (msg.sender == _owner1) {
            if (_owner2Status == VaultStatus.LOCKED) revert UnAuthorized();
            if (_ownerBlockStatus[_owner2]) revert AlreadyBlocked();
            _ownerBlockStatus[_owner2] = true;
        } else {
            if (_owner1Status == VaultStatus.LOCKED) revert UnAuthorized();
            if (_ownerBlockStatus[_owner1]) revert AlreadyBlocked();
            _ownerBlockStatus[_owner1] = true;
        }
    }

    function updateOwner(address oldOwner, address newOwner) external onlyFactory locked {
        if (oldOwner != _owner1 && oldOwner != _owner2) revert InvalidOwner();
        if (newOwner == _owner1 || newOwner == _owner2) revert InvalidOwner();
        if (oldOwner == _owner1) {
            if (_owner1Status == VaultStatus.LOCKED) revert CurrentlyLocked();
            _owner1 = newOwner;
            _owner1Status = VaultStatus.LOCKED;
        } else if (oldOwner == _owner2) {
            if (_owner2Status == VaultStatus.LOCKED) revert CurrentlyLocked();
            _owner2 = newOwner;
            _owner2Status = VaultStatus.LOCKED;
        }
        emit OwnerUpdated(oldOwner, newOwner);
    }

    function getLockTime() public view returns (uint256) {
        if (deadline > block.timestamp) return deadline - block.timestamp;
        return 0;
    }

    function lockVault() external authorizedOwner notBlocked unLocked {
        _owner1Status = VaultStatus.LOCKED;
        _owner2Status = VaultStatus.LOCKED;
        _vaultStatus = VaultStatus.LOCKED;
    }

    function updateLockStatus() external authorizedOwner notBlocked locked {
        if (msg.sender == _owner1) {
            if (_owner1Status == VaultStatus.LOCKED) revert CurrentlyLocked();
            if (block.timestamp > _unlockInitiatedTime + 365 days) {
                _owner2Status = VaultStatus.UNLOCKED;
                _vaultStatus = VaultStatus.UNLOCKED;
            }
        } else {
            if (_owner2Status == VaultStatus.LOCKED) revert CurrentlyLocked();
            if (block.timestamp > _unlockInitiatedTime + 365 days) {
                _owner1Status = VaultStatus.UNLOCKED;
                _vaultStatus = VaultStatus.UNLOCKED;
            }
        }
    }

    function unlockVault() external authorizedOwner locked {
        if (block.timestamp < deadline) revert TimeLocked();
        if (_vaultConfig.getCollectUnlockFee()) {
            _collectFee(_vaultConfig.getUnlockVaultFeeTokenAddress(), _vaultConfig.getFeeAddress(), _vaultConfig.getUnlockVaultFeeAmount());
        }

        if (msg.sender == _owner1) _owner1Status = VaultStatus.UNLOCKED;
        else _owner2Status = VaultStatus.UNLOCKED;

        _unlockInitiatedTime = block.timestamp;

        if (_owner1Status == VaultStatus.UNLOCKED && _owner2Status == VaultStatus.UNLOCKED) _vaultStatus = VaultStatus.UNLOCKED;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getUnlockInitiatedTime() public view returns (uint256) {
        return block.timestamp - _unlockInitiatedTime;
    }

    function getTimeLockInitiatedTime() public view returns (uint256) {
        if (deadlineInitiated > block.timestamp) return deadlineInitiated - block.timestamp;
        return 0;
    }

    function approveToken(address token, uint256 amount) external authorizedOwner notBlocked unLocked {
        require(_globalList.isSupportedToken(token), "Token is not supported");
        IERC20(token).approve(_factory, amount);
    }

    function _collectFee(address token, address feeAddress, uint256 amount) internal {
        bool isNFTExists;
        if (_vaultConfig.getCheckForNFT() && IERC721(_vaultConfig.getNFTAddress()).balanceOf(address(this)) > 0) isNFTExists = true;
        if (!isNFTExists) {
            if (token == address(0)) {
                if (address(this).balance < amount) revert InsufficientBalance();
                _transfer(feeAddress, amount);
            } else {
                if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();
                IERC20(token).safeTransfer(feeAddress, amount);
            }
        }
    }

    function transferOut(address token, address to, uint256 amount) external authorizedOwner notBlocked unLocked supportedToken(token) validAmount(amount) {        
        if (token == address(0)) {
            if (address(this).balance < amount) revert InsufficientBalance();
            _transfer(to, amount);
        } else {
            if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function transferNFTOut(address token, address to, uint256 tokenId, TokenType tokenType, uint256 amount) public authorizedOwner notBlocked unLocked validAmount(amount) {
        if (tokenType == TokenType.ERC721) {
            IERC721(token).safeTransferFrom(address(this), to, tokenId);

        } else if (tokenType == TokenType.ERC1155) {
            IERC1155(token).safeTransferFrom(address(this), to, tokenId, amount, "");
        }
    }

    function transferMultipleNFTsOut(NFTList[] calldata nftList, address to) external authorizedOwner notBlocked unLocked {
        uint256 length = nftList.length;
        for (uint i; i < length; i++) {
            transferNFTOut(nftList[i].token, to, nftList[i].tokenId, nftList[i].tokenType, nftList[i].amount);
        }
    }

    function _transfer(address to, uint256 amount) internal {
        if (to == address(0)) revert NotZeroAddress();
        (bool success, ) = payable(to).call{value: amount}("");
        
        if (!success) revert FailedETHSend();
    }

    function getUserTokens() external view returns (address[] memory) {
        return getTokensList();
    }

    function getGlobalTokens() external view returns (address[] memory) {
        return SupportedTokens(_globalList).getTokensList();
    }

    function getVaultDetails() external view returns (VaultDetails memory) {
        return VaultDetails(_name, _owner1, _owner2, _uri, _owner1Status, _owner2Status, _vaultStatus, getLockTime(), getTimeLockInitiatedTime(), deadlineInitiatedOwner, getUnlockInitiatedTime(), _ownerBlockStatus[_owner1], _ownerBlockStatus[_owner2]);
    }

    function claimRewards() external authorizedOwner notBlocked {
        uint256 availableRewards = unclaimedRewardsBalance();
        if (availableRewards == 0) revert NotEnoughRewards();

        EverRiseNFT(_vaultConfig.getEverRiseNFTAddress()).withdrawRewards();
    }

    function unclaimedRewardsBalance() public view returns (uint256) {
        return EverRiseNFT(_vaultConfig.getEverRiseNFTAddress()).unclaimedRewardsBalance(address(this));
    }

    function totalRewards() public view returns (uint256) {
        return EverRiseNFT(_vaultConfig.getEverRiseNFTAddress()).getTotalRewards(address(this));
    }

    function onERC721Received(address, address, uint256, bytes calldata ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./openzeppelin/Ownable.sol";

interface Metadata {

    function decimals() external view returns (uint8);
}

contract DVaultConfig is Ownable {

    address _feeAddress = 0x89A674E8ef54554a0519885295d4FC5d972De140;
    address _unlockVaultFeeTokenAddress;
    uint256 _unlockVaultFeeAmount;
    address _timeLockFeeTokenAddress;
    uint256 _timeLockFeeAmount;
    bool _collectUnlockFee;
    bool _collectTimeLockFee;
    address _nftAddress = address(0x5D37f5da50051d729Fc60E36EE493bBcddD1fb1c);
    bool _checkForNFT;
    address everRiseNFTStakeAddress = 0x23cD2E6b283754Fd2340a75732f9DdBb5d11807e;
    address everRiseAddress = 0xC17c30e98541188614dF99239cABD40280810cA3;



    constructor() Ownable(msg.sender) {

    }

    function setFeeAddress(address feeAddress) external onlyOwner {
        _feeAddress = feeAddress;
    }

    function setUnlockVaultFeeDetails(address feeToken, uint256 amount, uint256 fractionalDecimals) external onlyOwner {
        _unlockVaultFeeTokenAddress = feeToken;
        uint8 decimals = 18;
        if (feeToken != address(0)) {
            decimals = Metadata(feeToken).decimals();
        }
        _unlockVaultFeeAmount = (amount * 10**decimals) / 10 ** fractionalDecimals;
    }

    function setTimelockFeeDetails(address feeToken, uint256 amount, uint256 fractionalDecimals) external onlyOwner {
        _timeLockFeeTokenAddress = feeToken;
        uint8 decimals = 18;
        if (feeToken != address(0)) {
            decimals = Metadata(feeToken).decimals();
        }
        _timeLockFeeAmount = (amount * 10**decimals) / 10 ** fractionalDecimals;
    }

    function setCollectUnlockFee(bool unlock) external onlyOwner {
        _collectUnlockFee = unlock;
    }

    function setCollectTimelockFee(bool timelock) external onlyOwner {
        _collectTimeLockFee = timelock;
    }

    function setNFTAddress(address addr) external onlyOwner {
        _nftAddress = addr;
    }

    function setCheckForNFT(bool flag) external onlyOwner {
        _checkForNFT = flag;
    }

    function updateEverRiseInfo(address erAddress, address erStakeAddress) external onlyOwner {
        everRiseAddress = erAddress;
        everRiseNFTStakeAddress = erStakeAddress;
    }

    function getEverriseAddress() external view returns (address) {
        return everRiseAddress;
    }

    function getEverRiseNFTAddress() external view returns (address) {
        return everRiseNFTStakeAddress;
    }

    function getCheckForNFT() external view returns (bool) {
        return _checkForNFT;
    }

    function getNFTAddress() external view returns (address) {
        return _nftAddress;
    }

    function getFeeAddress() external view returns (address) {
        return _feeAddress;
    }

    function getUnlockVaultFeeTokenAddress() external view returns (address) {
        return _unlockVaultFeeTokenAddress;
    }

    function getUnlockVaultFeeAmount() external view returns (uint256) {
        return _unlockVaultFeeAmount;
    }

    function getCollectUnlockFee() external view returns (bool) {
        return _collectUnlockFee;
    }

    function getCollectTimelockFee() external view returns (bool) {
        return _collectTimeLockFee;
    }

    function getTimeLockFeeTokenAddress() external view returns (address) {
        return _timeLockFeeTokenAddress;
    }

    function getTimeLockFeeAmount() external view returns (uint256) {
        return _timeLockFeeAmount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./openzeppelin/Clones.sol";
import "./DVault.sol";
import "../IERC20.sol";
import "../TransferHelper.sol";
import "./SupportedTokens.sol";
import "./DVaultConfig.sol";

enum VaultStatus {
        LOCKED,
        UNLOCKED
}

struct VaultDetails {
        string name;
        address owner1;
        address owner2;
        string uri;
        VaultStatus owner1Status;
        VaultStatus owner2Status;
        VaultStatus status;
        uint256 lockTime;
        uint256 lockInitiatedTime;
        address lockInitiatedAddress;
        uint256 unlockInitiatedTime;
        bool owner1BlockStatus;
        bool owner2BlockStatus;
}

interface IDVault {
    function isAuthorizedOwner(address addr) external view returns (bool);
    function getVaultDetails() external view returns (VaultDetails memory);
    function updateOwner(address oldOwner, address newOwner) external;
}

contract DVaultFactory is Ownable {

    using TransferHelper for IERC20;

    uint256 _counter;
    bool _counterUpdated;
    address _implementation;
    mapping(uint256 => address) _allVaults;
    mapping(address => uint256[]) _userVaults;
    SupportedTokens _globalList;
    address[] _whitelistedTokens;
    address _createVaultFeeTokenAddress;
    uint256 _createVaultFeeAmount;
    bool _isCollectCreateFee;
    address _feeAddress = 0x89A674E8ef54554a0519885295d4FC5d972De140;
    address _riseBurnAddress = address(0xdead);
    address public _riseAddress = 0xC17c30e98541188614dF99239cABD40280810cA3;
    uint256 public _riseBurnAmount = 20_000 * 10 ** 18;
    bool _isBurnRise;
    uint256 public _owner1Limit = 2;
    uint256 public _owner2Limit = 2;
    bool _createVault = true;
    bool _enableMultipleVaults;
    address _superOwner;
    bool _ownerAuthorized;

    DVaultConfig _vaultConfig;

    error TokenNotSupported(); //0x3dd1b305
    error InsufficientAmount(); //0x5945ea56
    error FailedETHSend(); //0xaf3f2195
    error NotZeroAddress(); //0x66385fa3
    error NotAuthorized(); //0xea8e4eb5
    error MultipleVaultsNotAllowed(); //0x76fe3111
    error CurrentlyLocked();


    constructor() Ownable(msg.sender) {
        _implementation = address(new DVault());
        _globalList = new SupportedTokens();
        _vaultConfig = new DVaultConfig();
        _superOwner = msg.sender;
    }

    modifier authorized() {
        if (!_ownerAuthorized) revert NotAuthorized();
        _;
    } 

    receive() external payable  {}

    fallback() external payable {}

    function setSuperOwner(address addr) external {
        if (msg.sender != _superOwner) revert NotAuthorized();
        require(!isContract(addr), "Super Owner can not be a contract");
        _superOwner = addr;
    }

    function setOwnerAuthorized(bool flag) external {
        if (msg.sender != _superOwner) revert NotAuthorized();
        _ownerAuthorized = flag;
    }

    function getOwnerAuthorized() external view returns (bool) {
        return _ownerAuthorized;
    }

    function getSuperOwner() external view returns (address) {
        return _superOwner;
    }

    function setEnableMultipleVaults(bool flag) external onlyOwner {
        _enableMultipleVaults = flag;
    }

    function setOwner1Limit(uint256 value) external onlyOwner {
        _owner1Limit = value;
    }

    function setOwner2Limit(uint256 value) external onlyOwner {
        _owner2Limit = value;
    }

    function setIsRiseBurn(bool flag) external onlyOwner {
        _isBurnRise = flag;
    }

    function setCreateVault(bool flag) external onlyOwner {
        _createVault = flag;
    }

    function setRiseAddress(address newAddress) external onlyOwner {
        _riseAddress = newAddress;
    }

    function setRiseBurnAddress(address newAddress) external onlyOwner {
        _riseBurnAddress = newAddress;
    }

    function setRiseBurnAmount(uint256 amount, uint256 decimals) external onlyOwner {
        _riseBurnAmount = (amount * 10**18) / 10 ** decimals;
    }

    function getRiseBurnAmount() external view returns (uint256) {
        return _riseBurnAmount;
    }

    function setFeeAddress(address feeAddress) external onlyOwner {
        _feeAddress = feeAddress;
    }

    function setConfigFeeAddress(address feeAddress) external onlyOwner {
        _vaultConfig.setFeeAddress(feeAddress);
    }

    function getFeeAddress() external view returns (address) {
        return _feeAddress;
    }

    function setCreateVaultFee(address feeToken, uint256 amount, uint256 fractionalDecimals) external onlyOwner {
        _createVaultFeeTokenAddress = feeToken;
        uint8 decimals = 18;
        if (feeToken != address(0)) {
            decimals = Metadata(feeToken).decimals();
        }
        _createVaultFeeAmount = (amount * 10**decimals) / 10 ** fractionalDecimals;
    }

    function setIsCollectCreateFee(bool create) external onlyOwner {
        _isCollectCreateFee = create;
    }

    function getCreateVaultFeeTokenAddress() external view returns (address) {
        return _createVaultFeeTokenAddress;
    }

    function getCreateVaultFeeAmount() external view returns (uint256) {
        return _createVaultFeeAmount;
    }

    function getIsCollectCreateFee() external view returns (bool) {
        return _isCollectCreateFee;
    }

    function createVaultClone(string calldata name, address owner2, string calldata uri) external payable returns (address) {
        require(_createVault, "Create Vault is not allowed");
        require(msg.sender != owner2, "Same Address is not allowed");
        require(!isContract(owner2), "Owner2 can not be a contract");
        
        if (_userVaults[msg.sender].length > _owner1Limit - 1 || _userVaults[owner2].length > _owner2Limit - 1) {
            if (!_enableMultipleVaults) revert MultipleVaultsNotAllowed();
            if (_isCollectCreateFee) collectCreateFee();
        }

        if (_isBurnRise) {
            IERC20(_riseAddress).safeTransferFrom(msg.sender, address(this), _riseBurnAmount);
            IERC20(_riseAddress).safeTransfer(_riseBurnAddress, _riseBurnAmount);
        }

        address payable clonedVault = payable(Clones.clone(_implementation));
        DVault(clonedVault).initialize(name, msg.sender, owner2, address(this), uri, _vaultConfig,  _globalList);

        _counter++;
        _allVaults[_counter] = address(clonedVault);
        _userVaults[msg.sender].push(_counter);
        _userVaults[owner2].push(_counter);
        return clonedVault;
    }

    function collectCreateFee() internal {
        if (_createVaultFeeTokenAddress == address(0)) {
            if (msg.value < _createVaultFeeAmount) revert InsufficientAmount();
            _transfer(_feeAddress, _createVaultFeeAmount);
        } else {
            IERC20(_createVaultFeeTokenAddress).safeTransferFrom(msg.sender, _feeAddress, _createVaultFeeAmount);
        }
    }

    function _transfer(address to, uint256 amount) internal {
        if (to == address(0)) revert NotZeroAddress();
        (bool success, ) = payable(to).call{value: amount}("");
        
        if (!success) revert FailedETHSend();
    }

    function transferToVault(uint256 id, address token, uint256 amount) external {
        address vaultAddress = _allVaults[id];
        if (vaultAddress == address(0)) revert NotZeroAddress();
        if (!_globalList.isSupportedToken(token)) revert TokenNotSupported();
        require(amount > 0, "Amount should be greater than 0");
        uint256 initial = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 newAmount = IERC20(token).balanceOf(address(this)) - initial;
        require(amount == newAmount, "Amounts Mismatch");
        IERC20(token).safeTransfer(vaultAddress, amount);
    }

    function transferFromVault(uint256 id, address token, uint256 amount) external {
        address vaultAddress = _allVaults[id];
        if (vaultAddress == address(0)) revert NotZeroAddress();
        if (!_globalList.isSupportedToken(token)) revert TokenNotSupported();
        if (!IDVault(vaultAddress).isAuthorizedOwner(msg.sender)) revert NotAuthorized();
        VaultDetails memory details = IDVault(vaultAddress).getVaultDetails();
        if (details.status == VaultStatus.LOCKED) revert CurrentlyLocked();
        require(amount > 0, "Amount should be greater than 0");
        uint256 initial = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(vaultAddress, address(this), amount);
        uint256 newAmount = IERC20(token).balanceOf(address(this)) - initial;
        require(amount == newAmount, "Amounts Mismatch");
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // Introduced in V3
    function updateOwner(uint256 vault_id, address oldOwner, address newOwner) external {
        address vaultAddress = _allVaults[vault_id];
        if (vaultAddress == address(0)) revert NotZeroAddress();
        if (!IDVault(vaultAddress).isAuthorizedOwner(msg.sender)) revert NotAuthorized();
        require(!isContract(newOwner), "New Owner can not be a contract");
        
        if (_userVaults[newOwner].length > _owner2Limit - 1) {
            if (!_enableMultipleVaults) revert MultipleVaultsNotAllowed();
            if (_isCollectCreateFee) collectCreateFee();
        }
        IDVault(vaultAddress).updateOwner(oldOwner, newOwner);
        _userVaults[newOwner].push(vault_id);

        uint length = _userVaults[oldOwner].length;
        for (uint i = 0; i < length; i++) {
            if (_userVaults[oldOwner][i] == vault_id) {
                _userVaults[oldOwner][i] = _userVaults[oldOwner][length - 1];
                break;
            }
        }
        _userVaults[oldOwner].pop();
    }



    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getVault(uint256 id) public view returns (address) {
        return _allVaults[id];
    }

    function addSupportedToken(address token, bool whitelisted) external onlyOwner {
        _globalList.addSupportedToken(token);
        if (whitelisted) _whitelistedTokens.push(token);
    }

    function setUnlockVaultFee(address feeToken, uint256 amount, uint256 fractionalDecimals) external onlyOwner authorized {
        _vaultConfig.setUnlockVaultFeeDetails(feeToken, amount, fractionalDecimals);
    }

    function setTimelockFee(address feeToken, uint256 amount, uint256 fractionalDecimals) external onlyOwner authorized {
        _vaultConfig.setTimelockFeeDetails(feeToken, amount, fractionalDecimals);
    }

    function setNFTAddress(address addr) external onlyOwner authorized {
        _vaultConfig.setNFTAddress(addr);
    }

    function setUnlockFeeFlag(bool unlock) external onlyOwner authorized {
        _vaultConfig.setCollectUnlockFee(unlock);
    }

    function setTimelockFeeFlag(bool timelock) external onlyOwner authorized {
        _vaultConfig.setCollectTimelockFee(timelock);
    }

    function setCheckForNFFlag(bool flag) external onlyOwner authorized {
        _vaultConfig.setCheckForNFT(flag);
    }

    function updateEverRiseInfo(address erAddress, address erStakeAddress) external onlyOwner authorized {
        _vaultConfig.updateEverRiseInfo(erAddress, erStakeAddress);
    }

    function getWhiteListedTokens() external view returns (address[] memory) {
        return _whitelistedTokens;
    }

    function setCounter(uint256 value) external onlyOwner {
        require(!_counterUpdated, "Already Updated");
        _counter = value;
        _counterUpdated = true;
    }

    function getCounter() public view returns (uint256) {
        return _counter;
    }

    function getVaults(address user) external view returns (uint256[] memory) {
        return _userVaults[user];
    }

    function getTimeLockFeeTokenAddress() external view returns (address) {
        return _vaultConfig.getTimeLockFeeTokenAddress();
    }

    function getTimeLockFeeAmount() external view returns (uint256) {
        return _vaultConfig.getTimeLockFeeAmount();
    }

    function getCollectTimeLockFee() external view returns (bool) {
        return _vaultConfig.getCollectTimelockFee();
    }

    function getUnlockVaultFeeTokenAddress() external view returns (address) {
        return _vaultConfig.getUnlockVaultFeeTokenAddress();
    }

    function getUnlockVaultFeeAmount() external view returns (uint256) {
        return _vaultConfig.getUnlockVaultFeeAmount();
    }

    function getCollectUnlockFee() external view returns (bool) {
        return _vaultConfig.getCollectUnlockFee();
    }

    function getConfigFeeAddress() external view returns (address) {
        return _vaultConfig.getFeeAddress();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.19;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.19;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
pragma solidity ^0.8.19;

import "./openzeppelin/Ownable.sol";

contract SupportedTokens is Ownable {

    mapping (address => bool) _supportedTokens;
    address[] _tokensList;

    error NotZeroAddress();

    constructor() Ownable(msg.sender) {
    }

    function addSupportedToken(address token) external onlyOwner {
        if (token == address(0)) revert NotZeroAddress();
        require (!_supportedTokens[token], "Already Supported");
        _supportedTokens[token] = true;
        _tokensList.push(token);
    }

    function getTokensList() public view returns (address[] memory) {
        return _tokensList;
    }

    function isSupportedToken(address token) public view returns (bool) {
        return _supportedTokens[token];
    }

}