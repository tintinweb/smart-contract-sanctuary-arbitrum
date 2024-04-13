// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IFFixedSale {
    function totalPurchased(address user) external view returns (uint256);

    function totalPaymentReceived() external view returns (uint256);

    function salePrice() external view returns (uint256);
}

interface ICheckerNFT {
    function mint(address to, uint256 amount) external;
}

contract CheckerNFTClaim is Ownable2Step, Pausable, ReentrancyGuard {
    address public adminAddress;
    address public checkerNftAddress;
    address[] private _saleContractsArray;
    mapping(address => bool) internal _claimBlacklist;
    mapping(address => uint256) public totalNftClaimed;

    event EventAdminUpdated(address newAdmin);
    event EventClaim(address user, uint256 amount);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "only admin");
        _;
    }

    constructor(address checkerNft) {
        checkerNftAddress = checkerNft;
        adminAddress = msg.sender;
        _pause();
    }

    function updateAdmin(address admin) public onlyOwner {
        adminAddress = admin;
        emit EventAdminUpdated(admin);
    }

    function updateSaleContractsArray(
        address[] memory saleContracts
    ) public onlyOwner {
        _saleContractsArray = saleContracts;
    }

    function getSaleContractsArray() public view returns (address[] memory) {
        return _saleContractsArray;
    }

    function totalNftPurchased(address user) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _saleContractsArray.length; i++) {
            total += IFFixedSale(_saleContractsArray[i]).totalPurchased(user);
        }
        return total / 1e18;
    }

    function totalSaleTokensSold() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _saleContractsArray.length; i++) {
            uint256 salePrice = IFFixedSale(_saleContractsArray[i]).salePrice();
            uint256 totalPaymentReceived = IFFixedSale(_saleContractsArray[i])
                .totalPaymentReceived();
            uint256 totalTokensSold = 0;
            if (salePrice == 0) {
                totalTokensSold = 0;
            } else {
                totalTokensSold = (totalPaymentReceived * 1e18) / salePrice;
            }
            total += totalTokensSold;
        }
        return total / 1e18;
    }

    function unClaimedNftCount(address user) public view returns (uint256) {
        return totalNftPurchased(user) - totalNftClaimed[user];
    }

    function batchUnClaimedNftCount(address[] calldata userArray) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](userArray.length);
        for (uint256 i = 0; i < userArray.length; i++) {
            result[i] = unClaimedNftCount(userArray[i]);
        }
        return result;
    }

    function batchClaimedNftCount(address[] calldata userArray) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](userArray.length);
        for (uint256 i = 0; i < userArray.length; i++) {
            result[i] = totalNftClaimed[userArray[i]];
        }
        return result;
    }

    function claimAll() public whenNotPaused nonReentrant {
        require(!_claimBlacklist[msg.sender], "blacklisted user");
        _claimAll(msg.sender);
    }

    function claim(uint256 amount) public whenNotPaused nonReentrant {
        require(!_claimBlacklist[msg.sender], "blacklisted user");
        _claim(msg.sender, amount);
    }

    function _claim(address user, uint256 amount) internal {
        require(amount > 0, "amount should be greater than 0");
        require(
            amount <= unClaimedNftCount(user),
            "amount should be less than unclaimed nft count"
        );
        totalNftClaimed[user] += amount;

        
        ICheckerNFT(checkerNftAddress).mint(user,amount);
        

        emit EventClaim(user, amount);
    }

    function _claimAll(address user) internal {
        uint256 amount = unClaimedNftCount(user);
        if (amount == 0) {
            return;
        }

        totalNftClaimed[user] += amount;

        ICheckerNFT(checkerNftAddress).mint(user,amount);

        emit EventClaim(user, amount);
    }

    function adminClaim(address user, uint256 amount) public onlyAdmin {
        _claim(user, amount);
    }

    function inBlacklist(address user) public view returns (bool) {
        return _claimBlacklist[user];
    }

    function updateBlacklist(address user, bool val) public onlyAdmin {
        _claimBlacklist[user] = val;
    }

    function adminBatchClaim(
        address[] calldata userArray,
        uint256[] calldata amountArray
    ) public onlyAdmin {
        require(
            userArray.length == amountArray.length,
            "array length should be same"
        );
        for (uint256 i = 0; i < userArray.length; i++) {
            _claim(userArray[i], amountArray[i]);
        }
    }

    function adminBatchClaimAll(address[] calldata userArray) public onlyAdmin {
        for (uint256 i = 0; i < userArray.length; i++) {
            _claimAll(userArray[i]);
        }
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }
}