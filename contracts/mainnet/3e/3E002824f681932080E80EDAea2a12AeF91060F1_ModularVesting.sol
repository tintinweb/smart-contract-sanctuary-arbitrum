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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint amount) external returns (bool);
}

contract ModularVesting is Ownable, ReentrancyGuard {
	uint constant ONE_WEEK = 7 days;

	bool public vestingIsCreated;

	mapping(uint => Vesting) public vesting;

	IERC20 public token;

	address public constant investor1 =
		0xdec08cb92a506B88411da9Ba290f3694BE223c26;
	address public constant investor2 =
		0x198E18EcFdA347c6cdaa440E22b2ff89eaA2cB6f;
	address public constant investor3 =
		0x5BCf75FF702e90c889Ae5c41ee25aF364ABC77cb;
	address public constant investor4 =
		0x5b15BAa075982Ccc6Edc7C830646030757d5272d;

	// @notice                              provide full information of exact vesting
	struct Vesting {
		address owner; // The only owner can call vesting claim function
		uint claimCounter; // Currect claim number
		uint totalClaimNum; // Maximum amount of claims for this vesting
		uint nextUnlockDate; // Next date of tokens unlock
		uint tokensRemaining; // Remain amount of token
		uint tokenToUnclockPerCycle; // Amount of token can be uncloked each cycle
	}

	modifier checkLock(uint _index) {
		require(
			vesting[_index].owner == msg.sender,
			"Not an owner of this vesting"
		);
		require(
			block.timestamp > vesting[_index].nextUnlockDate,
			"Tokens are still locked"
		);
		require(vesting[_index].tokensRemaining > 0, "Nothing to claim");
		_;
	}

	constructor(IERC20 _token) {
		token = _token;
	}

	// @notice                             only contract deployer can call this method and only once
	function createVesting() external onlyOwner {
		require(!vestingIsCreated, "vesting is already created");
		vestingIsCreated = true;

		vesting[0] = Vesting(
			investor1,
			0,
			4,
			block.timestamp + ONE_WEEK,
			27_500 ether,
			6_875 ether
		);
		vesting[1] = Vesting(
			investor2,
			0,
			4,
			block.timestamp + ONE_WEEK,
			27_500 ether,
			6_875 ether
		);
		vesting[2] = Vesting(
			investor3,
			0,
			4,
			block.timestamp + ONE_WEEK,
			27_500 ether,
			6_875 ether
		);
		vesting[3] = Vesting(
			investor4,
			0,
			4,
			block.timestamp + ONE_WEEK,
			27_500 ether,
			6_875 ether
		);

		token.transfer(investor1, 6_875 ether);
		token.transfer(investor2, 6_875 ether);
		token.transfer(investor3, 6_875 ether);
		token.transfer(investor4, 6_875 ether);
	}

	// @notice                             please use _index from table below
	//
	// 0 - investor1
	// 1 - investor2
	// 2 - investor3
	// 3 - investor4

	function claim(uint256 _index) public checkLock(_index) nonReentrant {
		if (vesting[_index].claimCounter + 1 < vesting[_index].totalClaimNum) {
			uint toClaim = vesting[_index].tokenToUnclockPerCycle;

			vesting[_index].tokensRemaining -= toClaim;
			vesting[_index].nextUnlockDate =
				vesting[_index].nextUnlockDate +
				ONE_WEEK;
			vesting[_index].claimCounter++;
			token.transfer(msg.sender, toClaim);
		} else {
			token.transfer(msg.sender, vesting[_index].tokensRemaining);
			vesting[_index].tokensRemaining = 0;
		}
	}
}