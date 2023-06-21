//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "openzeppelin/contracts/access/Ownable2Step.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

enum Phase {
    Closed,
    Presale,
    Public
}

/// @title Stumble Upon Rumble - Token Offering Contract
/// @notice This contract is designed to manage the sale of the stumble upon rumble erc20 token.
/// @notice Each purchaser will be allocated 1 share for each wei USDC committed.
/// @notice Presale purchasers will be allocated an additional % bonus on top of all presale shares purchased, and have the opportunity to earn a large ticket boost.
/// @notice The contract defines a maximum threshold, which is the maximum intended fundraise.
/// @notice Token distribution will be determined by the number of shares sold. Total Tokens / Total Shares.

contract TokenOffering is Ownable2Step {
    struct UserShares {
        uint64 presaleShares;
        uint64 publicShares;
        uint64 usdcDeposited;
    }

    uint64 immutable maximumThreshold;
    uint64 immutable walletLimit;
    uint64 immutable presaleBoost;
    uint64 immutable largeTicketBoost;
    uint64 immutable largeTicketThreshold;

    uint64 private presaleShares;
    uint64 private publicShares;

    Phase public phase;

    IERC20 public usdc;

    mapping(address purchaser => UserShares) private shareTracking;
    mapping(address purchaser => bool allowed) public allowList;
    address[] public purchasers;

    /// @notice Event emitted when a purchase occurs
    /// @param purchaser The address of the purchaser
    /// @param USDCvalue The amount of USDC used for the purchase
    /// @param shares The amount of shares purchased
    event Purchase(address indexed purchaser, uint64 USDCvalue, uint64 shares);

    /// @notice Event emitted when the contract phase changes
    /// @param phase The new phase of the contract
    event PhaseChanged(Phase indexed phase);

    constructor(
        address _usdc,
        uint64 _maximumThreshold,
        uint64 _walletLimit,
        uint64 _presaleBoost,
        uint64 _largeTicketBoost,
        uint64 _largeTicketThreshold
    ) {
        require(_presaleBoost >= 100000, "Presale boost must be greater than 1000.");
        require(_largeTicketBoost >= 100000, "Large ticket boost must be greater than 1000.");
        require(_largeTicketThreshold > 0, "Large ticket threshold must be greater than 0.");
        require(_walletLimit < _maximumThreshold, "Wallet limit must be less than maximum threshold.");
        require(_usdc != address(0), "USDC cannot be zero address.");
        maximumThreshold = _maximumThreshold;
        walletLimit = _walletLimit;
        presaleBoost = _presaleBoost;
        largeTicketBoost = _largeTicketBoost;
        largeTicketThreshold = _largeTicketThreshold;
        usdc = IERC20(_usdc);
    }

    /// @dev Allows a user to purchase tokens during the public phase
    /// @param amount The amount of USDC the user wants to commit
    function purchasePublic(uint64 amount) external {
        require(phase == Phase.Public, "Public phase must be active.");
        require(usdc.balanceOf(address(this)) + amount <= maximumThreshold, "Fundraise has reached maximum threshold.");
        usdc.transferFrom(msg.sender, address(this), amount);
        publicShares += amount;
        shareTracking[msg.sender].publicShares += amount;
        shareTracking[msg.sender].usdcDeposited += amount;
        purchasers.push(msg.sender);
        emit Purchase(msg.sender, amount, amount);
    }

    /// @dev Allows a user to purchase tokens during the presale phase
    /// @param amount The amount of USDC the user wants to commit
    function purchasePresale(uint64 amount) external {
        require(phase == Phase.Presale, "Presale must be active.");
        require(allowList[msg.sender], "User must be on allowlist.");
        require(usdc.balanceOf(address(this)) + amount <= maximumThreshold, "Fundraise has reached maximum threshold.");
        uint64 currentUserDeposit = shareTracking[msg.sender].usdcDeposited;
        require(shareTracking[msg.sender].usdcDeposited + amount <= walletLimit, "User has reached wallet limit.");

        usdc.transferFrom(msg.sender, address(this), amount);

        uint64 totalSharesToAdd = amount;

        if (currentUserDeposit + amount >= largeTicketThreshold) {
            totalSharesToAdd = (totalSharesToAdd * largeTicketBoost) / 100000;
            if (currentUserDeposit < largeTicketThreshold) {
                totalSharesToAdd += _addBoostForPriorShares();
            }
        }

        presaleShares += totalSharesToAdd;
        shareTracking[msg.sender].presaleShares += totalSharesToAdd;
        shareTracking[msg.sender].usdcDeposited += amount;
        purchasers.push(msg.sender);

        emit Purchase(msg.sender, amount, totalSharesToAdd);
    }

    /// @dev Allows the contract owner to cycle through the contract phases
    function cyclePhase() external onlyOwner {
        if (phase == Phase.Closed) {
            phase = Phase.Presale;
        } else if (phase == Phase.Presale) {
            phase = Phase.Public;
        } else if (phase == Phase.Public) {
            phase = Phase.Closed;
        }
        emit PhaseChanged(phase);
    }

    /// @notice Returns the total number of shares
    /// @return The total number of shares
    function getTotalShares() external view returns (uint64) {
        return ((presaleShares * presaleBoost) / 100000) + publicShares;
    }

    /// @notice Returns the number of shares owned by a user
    /// @param _address The address of the user
    /// @return The number of shares owned by the user
    function getUserShares(address _address) external view returns (uint64) {
        if (allowList[_address]) {
            uint64 presaleSharesUser = (shareTracking[_address].presaleShares * presaleBoost) / 100000;
            return presaleSharesUser + shareTracking[_address].publicShares;
        } else {
            return shareTracking[_address].publicShares;
        }
    }

    /// @notice Returns a list of all purchaser addresses
    /// @return An array containing all purchaser addresses
    function getAllPurchasers() external view returns (address[] memory) {
        return purchasers;
    }

    /// @dev Allows the contract owner to withdraw funds from the contract
    function withdrawFunds() external onlyOwner {
        require(phase == Phase.Closed, "Fundraise must be closed.");
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    /// @dev Allows the contract owner to add users to the allowlist
    /// @param _addresses An array of addresses to be added to the allowlist
    function setAllowlist(address[] calldata _addresses) external onlyOwner {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length; i++) {
            allowList[_addresses[i]] = true;
        }
    }

    function _addBoostForPriorShares() internal view returns (uint64) {
        uint64 priorShares = shareTracking[msg.sender].presaleShares;
        uint64 boostToAdd = ((priorShares * largeTicketBoost) / 100000) - priorShares;
        return boostToAdd;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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