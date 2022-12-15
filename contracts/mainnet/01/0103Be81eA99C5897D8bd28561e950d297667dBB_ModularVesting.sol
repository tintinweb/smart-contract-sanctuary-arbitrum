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
		0x6ee6481Aa4Ca96c480D128EBc0e8181E3821c1e1;
	address public constant investor2 =
		0x4696260a63EA4cccCF3Ff51a2074556BA7d75277;
	address public constant investor3 =
		0x60C36d452545eDBbf73b908133D017b2A7236238;
	address public constant investor4 =
		0x3Ed8054413a6687aB726102cDF9bA35D17414073;
	address public constant investor5 =
		0x74Aca5d86FEabac1F57D2da6ad79dE7e0D3383fB;

	address public constant investor10 =
		0x74B78D678C4E61160eAbc404984fbDa0c284780C;
	address public constant investor11 =
		0xBD46404D72bc76f552c40a2Dd21531047c03379f;
	address public constant investor12 =
		0x2fECD7448f3dA7a7d8222079010C210e11a67433;
	address public constant investor13 =
		0xc32DE44a997fb08AECfae72E8fe0D4B71aade4D0;
	address public constant investor14 =
		0x37e4C892Cf5e8dc1312AFD790Ad975F72C6851E9;

	address public constant investor20 =
		0xA24f6D8605C92431386c9Cc60957B503B854049E;
	address public constant investor21 =
		0x6314AbFc9E5dd1B28c204fc26809A73016273646;
	address public constant investor22 =
		0xAbA746D8db5E71324b14B23CBb399Ef9cbeB80Fd;
	address public constant investor23 =
		0xBFf6B8b72669a94F24d45b07A3f0C8bf6E836726;
	address public constant investor24 =
		0x1C9360D23B9F0bEF051F05699aC7F2B0ab4a47A7;

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
			32_000 ether,
			8_000 ether
		);
		vesting[1] = Vesting(
			investor2,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[2] = Vesting(
			investor3,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[3] = Vesting(
			investor4,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[4] = Vesting(
			investor5,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);

		vesting[5] = Vesting(
			investor10,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[6] = Vesting(
			investor11,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[7] = Vesting(
			investor12,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[8] = Vesting(
			investor13,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);
		vesting[9] = Vesting(
			investor14,
			0,
			4,
			block.timestamp + ONE_WEEK,
			32_000 ether,
			8_000 ether
		);

		vesting[10] = Vesting(
			investor20,
			0,
			4,
			block.timestamp + ONE_WEEK,
			16_000 ether,
			4_000 ether
		);
		vesting[11] = Vesting(
			investor21,
			0,
			4,
			block.timestamp + ONE_WEEK,
			16_000 ether,
			4_000 ether
		);
		vesting[12] = Vesting(
			investor22,
			0,
			4,
			block.timestamp + ONE_WEEK,
			16_000 ether,
			4_000 ether
		);
		vesting[13] = Vesting(
			investor23,
			0,
			4,
			block.timestamp + ONE_WEEK,
			16_000 ether,
			4_000 ether
		);
		vesting[14] = Vesting(
			investor24,
			0,
			4,
			block.timestamp + ONE_WEEK,
			16_000 ether,
			4_000 ether
		);

		token.transfer(investor1, 8_000 ether);
		token.transfer(investor2, 8_000 ether);
		token.transfer(investor3, 8_000 ether);
		token.transfer(investor4, 8_000 ether);
		token.transfer(investor5, 8_000 ether);

		token.transfer(investor10, 8_000 ether);
		token.transfer(investor11, 8_000 ether);
		token.transfer(investor12, 8_000 ether);
		token.transfer(investor13, 8_000 ether);
		token.transfer(investor14, 8_000 ether);

		token.transfer(investor20, 4_000 ether);
		token.transfer(investor21, 4_000 ether);
		token.transfer(investor22, 4_000 ether);
		token.transfer(investor23, 4_000 ether);
		token.transfer(investor24, 4_000 ether);
	}

	// @notice                             please use _index from table below
	//
	// 0 - investor1
	// 1 - investor2
	// 2 - investor3
	// 3 - investor4
	// 4 - investor5

	// 5 - investor10
	// 6 - investor11
	// 7 - investor12
	// 8 - investor13
	// 9 - investor14

	// 10 - investor20
	// 11 - investor21
	// 12 - investor22
	// 13 - investor23
	// 14 - investor24

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