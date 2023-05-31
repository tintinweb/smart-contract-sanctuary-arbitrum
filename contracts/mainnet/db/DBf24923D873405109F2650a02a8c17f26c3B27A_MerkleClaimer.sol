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
pragma solidity 0.8.16;

import { IGenericRewardDistributor } from "./interfaces/IGenericRewardDistributor.sol";
import { OwnableWithTransfer } from "./utils/OwnableWithTransfer.sol";

// import "hardhat/console.sol";

struct RewardClaim {
	address distributor;
	uint256 amount;
	bytes32[] proof;
}

/// @title MerkleClaimer
/// @notice This contract claims rewards from multiple merkle distributors
contract MerkleClaimer is OwnableWithTransfer {
	mapping(address => bool) public whitelist;

	/// @param merkleDistributors whitelisted reward distributors
	constructor(address[] memory merkleDistributors) OwnableWithTransfer(msg.sender) {
		for (uint256 i = 0; i < merkleDistributors.length; ++i) {
			whitelist[merkleDistributors[i]] = true;
		}
	}

	/// @notice whitelists a reward distributor
	/// @param _address the address to whitelist
	function updateWhitelist(address _address, bool status) external onlyOwner {
		whitelist[_address] = status;
		emit UpdateWhitelist(_address, status);
	}

	/// @notice Claims rewards from multiple rewardDistributors.
	/// @param account The account to claim for
	/// @param claims The claims to make
	function claim(address account, RewardClaim[] calldata claims) external {
		for (uint256 i = 0; i < claims.length; ++i) {
			// only whitelisted distributors can be claimed from
			if (!whitelist[claims[i].distributor]) revert NotWhitelisted();
			IGenericRewardDistributor(claims[i].distributor).claim(
				account,
				claims[i].amount,
				claims[i].proof
			);
		}
	}

	error NotWhitelisted();
	event UpdateWhitelist(address indexed _address, bool status);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IbSect, IveSect } from "./ITokens.sol";

interface IRewardDistributorEvents {
	/// @dev Emits when a user claims tokens
	event Claimed(address indexed account, uint256 amount, bool indexed historic);

	/// @dev Emits when the owner replaces the merkle root
	event RootUpdated(bytes32 oldRoot, bytes32 indexed newRoot);

	/// @dev Emitted from a special function after updating the root to index allocations
	event TokenAllocated(address indexed account, uint8 indexed campaignId, uint256 amount);
}

interface IGenericRewardDistributor is IRewardDistributorEvents {
	/// @dev Returns the token distributed by this contract.
	function token() external view returns (IERC20);

	/// @dev Returns the current merkle root containing total claimable balances
	function merkleRoot() external view returns (bytes32);

	/// @dev Returns the total amount of token claimed by the user
	function claimed(address user) external view returns (uint256);

	// Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
	/// @dev Claims the given amount of the token for the account. Reverts if the inputs are not a leaf in the tree
	///      or the total claimed amount for the account is more than the leaf amount.
	function claim(
		address account,
		uint256 totalAmount,
		bytes32[] calldata merkleProof
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IbSect is IERC20 {
	// Sets the price of the lbTokens in underlying tokens
	function setPrice(uint256 price_) external;

	// Mint new bTokens tokens to the specified address
	function mintTo(address to, uint256 amount) external;

	// Convert bTokens to underlying tokens
	function convert(uint256 amount) external;

	// Claim underlying tokens held by the contract
	function claimUnderlying(address to) external;
}

interface IveSect is IERC20 {
	function setVeToken(address veToken_) external;

	function mintTo(address to, uint256 amount) external;

	function convertToLock(uint256 amount) external;

	function addValueToLock(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// loosely based on https://docs.synthetix.io/contracts/source/contracts/Owned

/// @title OwnableWithTransfer
/// @notice Contract module which provides a basic access control mechanism with
/// safe ownership transfer.
abstract contract OwnableWithTransfer {
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		if (msg.sender != owner) revert NotOwner();
		_;
	}

	constructor(address _owner) {
		if (_owner == address(0)) revert OwnerCannotBeZero();
		owner = _owner;
		emit OwnershipTransferred(address(0), _owner);
	}

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, _pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		if (msg.sender != pendingOwner) revert OnlyPendingOwner();
		pendingOwner = address(0);
		owner = pendingOwner;
		emit OwnershipTransferred(owner, pendingOwner);
	}

	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	error OwnerCannotBeZero();
	error OnlyPendingOwner();
	error NotOwner();
}