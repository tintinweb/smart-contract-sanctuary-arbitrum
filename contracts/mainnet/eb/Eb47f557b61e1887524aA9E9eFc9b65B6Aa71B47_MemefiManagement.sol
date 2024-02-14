// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

pragma solidity ^0.8.18;

interface IMemefiSwapable {
    function swapToMemefi(uint256 _ethToMemefiRate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IMemefiManagement {
    function treasury() external returns (address);

    function signer() external returns (address);

    function rewardDistributor() external returns (address);

    function mainAdmin() external returns (address);

    function hasRole(
        uint256 role,
        address walletAddress
    ) external view returns (bool);

    function uniqueRoleAddress(
        uint256 uniqueRole
    ) external view returns (address);

    function memefiToken() external returns (address);

    function storageSlot(uint256 _slot) external view returns (string memory);

    function feesDistributor() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMemefiManagement} from "./IMemefiManagement.sol";
import {IMemefiSwapable} from "../keys/IMemefiSwapable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MemefiManagement is Ownable, IMemefiManagement {
    event NewTreasury(address newTreasury);
    event NewSigner(address newSigner);
    event NewRewardDistributor(address newDistributor);
    event NewUniqueRole(
        uint256 indexed uniqueRoleId,
        address indexed walletAddress
    );
    event NewRole(
        uint256 indexed role,
        address indexed walletAddress,
        bool status
    );
    event NewStringStorageSlot(uint256 indexed storageSlot, string info);

    address public treasury;
    address public signer;
    address public rewardDistributor;
    address public memefiToken;
    address public memefiKeys;
    address public feesDistributor;

    //Role Number => Address => Has role boolean
    mapping(uint256 => mapping(address => bool)) internal _hasRole;

    // Role number => Address
    mapping(uint256 => address) internal _uniqueRole;

    // String storage (useful for storing uri)
    mapping(uint256 => string) internal _stringStorage;

    // RevealId => Erc721 contract address => erc721 tokenId => revealed boolean
    mapping(uint256 => mapping(address => mapping(uint256 => bool)))
        internal _erc721revealed;

    // RevealId => Address => uint256
    mapping(uint256 => mapping(address => uint256)) internal _revealAddress;

    constructor(
        address _mainAdmin,
        address _treasury,
        address _signer,
        address _rewardDistributor,
        address _memefiToken,
        string memory _initialBaseUri
    ) Ownable(_mainAdmin) {
        treasury = _treasury;
        emit NewTreasury(_treasury);
        signer = _signer;
        emit NewSigner(_signer);
        rewardDistributor = _rewardDistributor;
        emit NewRewardDistributor(_rewardDistributor);
        memefiToken = _memefiToken;
        _stringStorage[1] = _initialBaseUri;
        emit NewStringStorageSlot(1, _initialBaseUri);
    }

    function calculateMemefiForSwap(
        uint256 _ethToMemefiRate
    ) public view returns (uint256) {
        uint256 balanceEth = address(memefiKeys).balance +
            address(feesDistributor).balance;
        return (balanceEth * _ethToMemefiRate) / 1 ether;
    }

    function setSwap(uint256 _ethToMemefiRate) external onlyOwner {
        require(_ethToMemefiRate > 0, "Rate must be greater than 0");
        IERC20 token = IERC20(memefiToken);
        uint256 calculatedMemefi = calculateMemefiForSwap(_ethToMemefiRate);
        token.transferFrom(msg.sender, address(this), calculatedMemefi);
        token.approve(memefiKeys, type(uint256).max);
        IMemefiSwapable(memefiKeys).swapToMemefi(_ethToMemefiRate);
        token.approve(feesDistributor, type(uint256).max);
        IMemefiSwapable(feesDistributor).swapToMemefi(_ethToMemefiRate);
    }

    function setFeesDistributor(address _feesDistributor) external onlyOwner {
        require(feesDistributor == address(0), "Already set");
        feesDistributor = _feesDistributor;
    }

    function setMemefiKeys(address _memefiKeys) external onlyOwner {
        require(memefiKeys == address(0), "Already set");
        memefiKeys = _memefiKeys;
    }

    function isRevealed(
        uint256 _revealId,
        address _erc721Contract,
        uint256 _tokenId
    ) external view returns (bool) {
        return _erc721revealed[_revealId][_erc721Contract][_tokenId];
    }

    function revealNft(
        uint256 _revealId,
        address _erc721Contract,
        uint256 _tokenId
    ) external onlyOwner {
        _erc721revealed[_revealId][_erc721Contract][_tokenId] = true;
    }

    function setStringStorageSlot(
        uint256 _storageSlot,
        string memory _info
    ) external onlyOwner {
        _stringStorage[_storageSlot] = _info;
        emit NewStringStorageSlot(_storageSlot, _info);
    }

    function setNewTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Treasury cannot be 0");
        treasury = _newTreasury;
        emit NewTreasury(_newTreasury);
    }

    function setNewSigner(address _newSigner) external onlyOwner {
        require(_newSigner != address(0), "Signer cannot be 0");
        signer = _newSigner;
        emit NewSigner(_newSigner);
    }

    function setNewRewardDistributor(
        address _newDistibutor
    ) external onlyOwner {
        require(_newDistibutor != address(0), "Reward distributor cannot be 0");
        rewardDistributor = _newDistibutor;
        emit NewRewardDistributor(_newDistibutor);
    }

    function mainAdmin() external view returns (address) {
        return owner();
    }

    function setRole(
        uint256 role,
        address walletAddress,
        bool status
    ) external onlyOwner {
        _hasRole[role][walletAddress] = status;
        emit NewRole(role, walletAddress, status);
    }

    function hasRole(
        uint256 role,
        address walletAddress
    ) external view returns (bool) {
        return _hasRole[role][walletAddress];
    }

    function setUniqueRole(
        uint256 uniqueRoleId,
        address walletAddress
    ) external onlyOwner {
        _uniqueRole[uniqueRoleId] = walletAddress;
        emit NewUniqueRole(uniqueRoleId, walletAddress);
    }

    function uniqueRoleAddress(
        uint256 uniqueRole
    ) external view returns (address) {
        return _uniqueRole[uniqueRole];
    }

    function storageSlot(uint256 _slot) external view returns (string memory) {
        return _stringStorage[_slot];
    }

    function withdrawMemefi() external onlyOwner {
        uint256 memefiBalance = IERC20(memefiToken).balanceOf(address(this));
        IERC20(memefiToken).transfer(msg.sender, memefiBalance);
    }
}