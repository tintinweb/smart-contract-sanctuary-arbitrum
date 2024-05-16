// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IToken {
    function transfer(address dst, uint256 rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Vesting contract for vesting token allocations
/// @dev Forked from https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
contract TreasuryVester is Ownable {
    /// @notice vesting token address
    address public immutable vestingToken;
    /// @notice wallet address that is vesting token allocation
    address public recipient;

    /// @notice amount of token that is being allocated for vesting
    uint256 public immutable vestingAmount;
    /// @notice timestamp of vesting start date
    uint256 public immutable vestingBegin;
    /// @notice timestamp of vesting cliff, aka. the time before which token cannot be claimed
    uint256 public immutable vestingCliff;
    /// @notice timestamp of vesting end date
    uint256 public immutable vestingEnd;
    /// @notice can it be revoked by owner
    bool public immutable revocable;

    /// @notice timestamp of last claim
    uint256 public lastUpdate;
    /// @notice set to true if vesting has been revoked
    bool public revoked;

    /// @param _vestingToken vesting token address
    /// @param _recipient wallet address that is vesting token allocation
    /// @param _vestingAmount amount of token that is being allocated for vesting
    /// @param _vestingBegin timestamp of vesting start date
    /// @param _vestingCliff timestamp of vesting cliff, aka. the time before which token cannot be claimed
    /// @param _vestingEnd timestamp of vesting end date
    /// @param _revocable can it be revoked by owner
    constructor(
        address _vestingToken,
        address _recipient,
        uint256 _vestingAmount,
        uint256 _vestingBegin,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        bool _revocable
    ) {
        require(_vestingCliff >= _vestingBegin, "TreasuryVester::constructor: cliff is too early");
        require(_vestingEnd > _vestingCliff, "TreasuryVester::constructor: end is too early");

        vestingToken = _vestingToken;
        recipient = _recipient;

        vestingAmount = _vestingAmount;
        vestingBegin = _vestingBegin;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        lastUpdate = _vestingBegin;

        revocable = _revocable;
    }

    /// @notice allows current recipient to update vesting wallet
    /// @param _recipient new wallet address that is going to vest token allocation
    function setRecipient(address _recipient) external {
        require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
        recipient = _recipient;
    }

    /// @notice revokes vesting
    /// @dev calls claim() to sent already vested token. The remaining is returned to the owner.
    function revoke() external onlyOwner {
        require(revocable, "TreasuryVester::revoke cannot revoke");
        require(!revoked, "TreasuryVester::revoke token already revoked");

        if (block.timestamp >= vestingCliff) claim();

        revoked = true;

        require(IToken(vestingToken).transfer(owner(), IToken(vestingToken).balanceOf(address(this))), "transfer failed");
    }

    /// @notice claim vested token
    function claim() public {
        require(!revoked, "TreasuryVester::claim vesting revoked");
        require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
        uint256 amount;

        if (block.timestamp >= vestingEnd) {
            amount = IToken(vestingToken).balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }

        require(IToken(vestingToken).transfer(recipient, amount), "transfer failed");
    }
}

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