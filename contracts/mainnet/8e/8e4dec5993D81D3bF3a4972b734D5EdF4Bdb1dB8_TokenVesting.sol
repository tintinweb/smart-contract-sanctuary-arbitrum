// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
@title Access Limiter to multiple owner-specified accounts.
@dev Exposes the onlyAdmin modifier, which will revert (ADMIN_ACCESS_REQUIRED) if the caller is not the owner nor the admin.
@notice An address with the role admin can grant that role to or revoke that role from any address via the function setAdmin().
*/
abstract contract AccessProtected is Context {
    mapping(address => bool) private _admins; // user address => admin? mapping
    uint public adminCount;

    event AdminAccessSet(address indexed _admin, bool _enabled);

    constructor() {
        _admins[_msgSender()] = true;
        adminCount = 1;
        emit AdminAccessSet(_msgSender(), true);
    }

    /**
     * Throws if called by any account that isn't an admin or an owner.
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "ADMIN_ACCESS_REQUIRED");
        _;
    }

    function isAdmin(address _addressToCheck) external view returns (bool) {
        return _admins[_addressToCheck];
    }

    /**
     * @notice Set/unset Admin Access for a given address.
     *
     * @param admin - Address of the new admin (or the one to be removed)
     * @param isEnabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool isEnabled) public onlyAdmin {
        require(admin != address(0), "INVALID_ADDRESS");
        require(_admins[admin] != isEnabled, "FLAG_ALREADY_PRESENT_FOR_ADDRESS");

        if (isEnabled) {
            adminCount++;
        } else {
            require(adminCount > 1, "AT_LEAST_ONE_ADMIN_REQUIRED");
            adminCount--;
        }

        _admins[admin] = isEnabled;
        emit AdminAccessSet(admin, isEnabled);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AccessProtected.sol";

/**
@title Access Limiter to multiple owner-specified accounts.
@dev An address with role admin can:
- Can allocate tokens owned by the contract to a given recipient through a vesting agreement via the functions createGrant() (one by one) and createGrantsBatch() (batch).
- Can withdraw unallocated tokens owned by the contract via the function withdrawAdmin().
- Can revoke an active grant for a given address via the function revokeGrant().
- Can withdraw any ERC20 token owner by the contract and different than the vested token via the function withdrawOtherToken().
*/
contract TokenVesting is Context, AccessProtected, ReentrancyGuard {
	using SafeERC20 for IERC20;

	// Address of the token that we're vesting
	IERC20 public immutable tokenAddress;

	// Current total vesting allocation
	uint256 public numTokensReservedForVesting = 0;

	/**
    @notice A structure representing a Grant - supporting linear and cliff vesting.
     */
	struct Grant {
		uint40 startTimestamp;
		uint40 endTimestamp;
		uint40 cliffReleaseTimestamp;
		uint40 releaseIntervalSecs; // used for calculating the vested amount
		uint256 linearVestAmount; // vesting allocation, excluding cliff
		uint256 claimedAmount; // claimed so far, excluding cliff
		uint112 cliffAmount;
		bool isActive; // revoked if false
		uint40 deactivationTimestamp;
	}

	mapping(address => Grant) internal grants;
	address[] internal vestingRecipients;

	/**
    @notice Emitted on creation of new Grant
     */
	event GrantCreated(address indexed _recipient, Grant _grant);

	/**
    @notice Emitted on withdrawal from Grant
     */
	event Claimed(address indexed _recipient, uint256 _withdrawalAmount);

	/**
    @notice Emitted on Grant revoke
     */
	event GrantRevoked(
		address indexed _recipient,
		uint256 _numTokensWithheld,
		Grant _grant
	);

	/**
    @notice Emitted on admin withdrawal
     */
	event AdminWithdrawn(address indexed _recipient, uint256 _amountRequested);

	/**
    @notice Construct the contract, taking the ERC20 token to be vested as the parameter.
    @dev The owner can set the token in question when creating the contract.
    */
	constructor(IERC20 _tokenAddress) {
		require(address(_tokenAddress) != address(0), "INVALID_ADDRESS");
		tokenAddress = _tokenAddress;
	}

	/**
    @notice Basic getter for a Grant.
    @param _recipient - Grant recipient wallet address
     */
	function getGrant(address _recipient) external view returns (Grant memory) {
		return grants[_recipient];
	}

	/**
    @notice Check if Recipient has an active grant attached.
    @dev
    * Grant is considered active if:
    * - is active
    * - start timestamp is greater than 0
    *
    * We can use startTimestamp as a criterion because it is only assigned a value in
    * createGrant, and it is never modified afterwards. Thus, startTimestamp will have a value
    * only if a grant has been created. Moreover, we need to verify
    * that the grant is active (since this is has_Active_Grant).
    */
	modifier hasActiveGrant(address _recipient) {
		Grant memory _grant = grants[_recipient];
		require(_grant.startTimestamp > 0, "NO_ACTIVE_GRANT");

		// We however still need the active check, since (due to the name of the function)
		// we want to only allow active grants
		require(_grant.isActive, "NO_ACTIVE_GRANT");

		_;
	}

	/**
    @notice Check if the recipient has no active grant attached.
    @dev Requires that all fields are unset
    */
	modifier hasNoGrant(address _recipient) {
		Grant memory _grant = grants[_recipient];
		// A grant is only created when its start timestamp is nonzero
		// So, a zero value for the start timestamp means the grant does not exist
		require(_grant.startTimestamp == 0, "GRANT_ALREADY_EXISTS");
		_;
	}

	/**
    @notice Calculate the vested amount for a given Grant, at a given timestamp.
    @param _grant The grant in question
    @param _referenceTs Timestamp for which we're calculating
     */
	function _baseVestedAmount(
		Grant memory _grant,
		uint40 _referenceTs
	) internal pure returns (uint256) {
		// Does the Grant exist?
		if (!_grant.isActive && _grant.deactivationTimestamp == 0) {
			return 0;
		}

        uint256 vestAmt;

		// Has the Grant ended?
		if (_referenceTs > _grant.endTimestamp) {
			_referenceTs = _grant.endTimestamp;
		}

		// Has the cliff passed?
		if (_referenceTs >= _grant.cliffReleaseTimestamp) {
			vestAmt += _grant.cliffAmount;
		}

		// Has the vesting started? If so, calculate the vested amount linearly
		if (_referenceTs > _grant.startTimestamp) {
			uint40 currentVestingDurationSecs = _referenceTs -
				_grant.startTimestamp;

			// Round to releaseIntervalSecs
			uint40 truncatedCurrentVestingDurationSecs = (currentVestingDurationSecs /
					_grant.releaseIntervalSecs) * _grant.releaseIntervalSecs;

			uint40 finalVestingDurationSecs = _grant.endTimestamp -
				_grant.startTimestamp;

			// Calculate vested amount
			uint256 linearVestAmount = (_grant.linearVestAmount *
				truncatedCurrentVestingDurationSecs) / finalVestingDurationSecs;

			vestAmt += linearVestAmount;
		}

		return vestAmt;
	}

	/**
    @notice Calculate the vested amount for a given Recipient, at a given Timestamp.
    @param _recipient - Grant recipient wallet address
    @param _referenceTs - Reference date timestamp
    */
	function vestedAmount(
		address _recipient,
		uint40 _referenceTs
	) public view returns (uint256) {
		Grant memory _grant = grants[_recipient];
		uint40 vestEndTimestamp = _grant.isActive
			? _referenceTs
			: _grant.deactivationTimestamp;
		return _baseVestedAmount(_grant, vestEndTimestamp);
	}

	/**
    @notice Return total allocation for a given Recipient.
    @param _recipient - Grant recipient wallet address
     */
	function grantAllocation(address _recipient) public view returns (uint256) {
		Grant memory _grant = grants[_recipient];
		return _baseVestedAmount(_grant, _grant.endTimestamp);
	}

	/**
    @notice Currently claimable amount for a given Recipient.
    @param _recipient - Grant recipient wallet address
    */
	function claimableAmount(address _recipient) public view returns (uint256) {
		Grant memory _grant = grants[_recipient];
		return
			vestedAmount(_recipient, uint40(block.timestamp)) -
			_grant.claimedAmount;
	}

	/**
    @notice Remaining allocation for Recipient. Total allocation minus already withdrawn amount.
    @param _recipient - Grant recipient wallet address
    */
	function finalClaimableAmount(
		address _recipient
	) external view returns (uint256) {
		Grant storage _grant = grants[_recipient];
		uint40 vestEndTimestamp = _grant.isActive
			? _grant.endTimestamp
			: _grant.deactivationTimestamp;
		return
			_baseVestedAmount(_grant, vestEndTimestamp) - _grant.claimedAmount;
	}

	/**
    @notice Get all active recipients
    */
	function allVestingRecipients() external view returns (address[] memory) {
		return vestingRecipients;
	}

	/**
    @notice Get active recipients count
    */
	function numVestingRecipients() external view returns (uint256) {
		return vestingRecipients.length;
	}

	/**
    @notice Create Grant logic, called by createGrant and createGrantsBatch.
    @dev Only input validation. Does not check if the startTimestamp is in the past to allow to back-allocate.
    @param _recipient - Grant recipient wallet address
    @param _startTimestamp - Vesting start date timestamp
    @param _endTimestamp - Vesting end date timestamp
    @param _cliffReleaseTimestamp - Lump sum cliff release date timestamp. Usually equal to _startTimestamp, must be <= _startTimestamp, or 0 if no cliff
    @param _releaseIntervalSecs - Time between releases, expressed in seconds
    @param _linearVestAmount - Allocation to be linearly vested between _startTimestamp and _endTimestamp (excluding cliff)
    @param _cliffAmount - The amount released at _cliffReleaseTimestamp. Can be 0 if _cliffReleaseTimestamp is also 0.
     */
	function _createGrantUnchecked(
		address _recipient,
		uint40 _startTimestamp,
		uint40 _endTimestamp,
		uint40 _cliffReleaseTimestamp,
		uint40 _releaseIntervalSecs,
		uint112 _linearVestAmount,
		uint112 _cliffAmount
	) private hasNoGrant(_recipient) {
		require(_recipient != address(0), "INVALID_ADDRESS");
		require(_linearVestAmount + _cliffAmount > 0, "INVALID_VESTED_AMOUNT");
		require(_startTimestamp > 0, "INVALID_START_TIMESTAMP");
		require(_startTimestamp < _endTimestamp, "INVALID_END_TIMESTAMP");
		require(_releaseIntervalSecs > 0, "INVALID_RELEASE_INTERVAL");
		require(
			(_endTimestamp - _startTimestamp) % _releaseIntervalSecs == 0,
			"INVALID_INTERVAL_LENGTH"
		);

		// Both or neither of cliff parameters must be set.
		// If cliff is set, the cliff timestamp must be before or at the vesting timestamp
		require(
			(_cliffReleaseTimestamp > 0 &&
				_cliffAmount > 0 &&
				_cliffReleaseTimestamp <= _startTimestamp) ||
				(_cliffReleaseTimestamp == 0 && _cliffAmount == 0),
			"INVALID_CLIFF"
		);

		Grant storage _grant = grants[_recipient];
		_grant.startTimestamp = _startTimestamp;
		_grant.endTimestamp = _endTimestamp;
		_grant.cliffReleaseTimestamp = _cliffReleaseTimestamp;
		_grant.releaseIntervalSecs = _releaseIntervalSecs;
		_grant.linearVestAmount = _linearVestAmount;
		_grant.cliffAmount = _cliffAmount;
		_grant.isActive = true;

		uint256 allocatedAmount = _cliffAmount + _linearVestAmount;

		// Can we afford to create a new Grant?
		require(
			tokenAddress.balanceOf(address(this)) >=
				numTokensReservedForVesting + allocatedAmount,
			"INSUFFICIENT_BALANCE"
		);

		numTokensReservedForVesting += allocatedAmount;
		vestingRecipients.push(_recipient);
		emit GrantCreated(_recipient, _grant);
	}

	/**
    @notice Create a grant based on the input parameters.
    @param _recipient - Grant recipient wallet address
    @param _startTimestamp - Vesting start date timestamp
    @param _endTimestamp - Vesting end date timestamp
    @param _cliffReleaseTimestamp - Lump sum cliff release date timestamp. Usually equal to _startTimestamp, must be <= _startTimestamp, or 0 if no cliff
    @param _releaseIntervalSecs - Time between releases, expressed in seconds
    @param _linearVestAmount - Allocation to be linearly vested between _startTimestamp and _endTimestamp (excluding cliff)
    @param _cliffAmount - The amount released at _cliffReleaseTimestamp. Can be 0 if _cliffReleaseTimestamp is also 0.
     */
	function createGrant(
		address _recipient,
		uint40 _startTimestamp,
		uint40 _endTimestamp,
		uint40 _cliffReleaseTimestamp,
		uint40 _releaseIntervalSecs,
		uint112 _linearVestAmount,
		uint112 _cliffAmount
	) external onlyAdmin {
		_createGrantUnchecked(
			_recipient,
			_startTimestamp,
			_endTimestamp,
			_cliffReleaseTimestamp,
			_releaseIntervalSecs,
			_linearVestAmount,
			_cliffAmount
		);
	}

	/**
    @notice Simple for loop sequential batch create. Takes n-th element of each array to create the Grant.
        @param _recipients - Array of Grant recipient wallet address
        @param _startTimestamps - Array of vesting start date timestamps
        @param _endTimestamps - Array of vesting end date timestamps
        @param _cliffReleaseTimestamps - Array of cliff release date timestamps
        @param _releaseIntervalsSecs - Array of time intervals between releases, expressed in seconds
        @param _linearVestAmounts - Array of allocations
        @param _cliffAmounts - Array of cliff release amounts
     */
	function createGrantsBatch(
		address[] memory _recipients,
		uint40[] memory _startTimestamps,
		uint40[] memory _endTimestamps,
		uint40[] memory _cliffReleaseTimestamps,
		uint40[] memory _releaseIntervalsSecs,
		uint112[] memory _linearVestAmounts,
		uint112[] memory _cliffAmounts
	) external onlyAdmin {
		uint256 length = _recipients.length;
		require(
			_startTimestamps.length == length &&
				_endTimestamps.length == length &&
				_cliffReleaseTimestamps.length == length &&
				_releaseIntervalsSecs.length == length &&
				_linearVestAmounts.length == length &&
				_cliffAmounts.length == length,
			"ARRAY_LENGTH_MISMATCH"
		);

		for (uint256 i = 0; i < length; i++) {
			_createGrantUnchecked(
				_recipients[i],
				_startTimestamps[i],
				_endTimestamps[i],
				_cliffReleaseTimestamps[i],
				_releaseIntervalsSecs[i],
				_linearVestAmounts[i],
				_cliffAmounts[i]
			);
		}
	}

	/**
    @notice Withdraw the claimable balance. Only callable by active Grant recipients.
     */
	function claim() external nonReentrant {
		Grant storage usrGrant = grants[_msgSender()];

		uint256 vested = vestedAmount(_msgSender(), uint40(block.timestamp));

		require(
			vested > usrGrant.claimedAmount,
			"NOTHING_TO_WITHDRAW"
		);

		uint256 amountRemaining = vested - usrGrant.claimedAmount;
		require(amountRemaining > 0, "NOTHING_TO_WITHDRAW");

		usrGrant.claimedAmount += amountRemaining;
		numTokensReservedForVesting -= amountRemaining;

		// Reentrancy: internal vars have been changed by now
		tokenAddress.safeTransfer(_msgSender(), amountRemaining);

		emit Claimed(_msgSender(), amountRemaining);
	}

	/**
    @notice Allow the owner to withdraw any balance not currently tied up in Grants
    @param _amountRequested - Amount to withdraw
     */
	function withdrawAdmin(
		uint256 _amountRequested
	) public onlyAdmin nonReentrant {
		uint256 amountRemaining = amountAvailableToWithdrawByAdmin();
		require(amountRemaining >= _amountRequested, "INSUFFICIENT_BALANCE");

		// Reentrancy: No changes to internal vars, only transfer
		tokenAddress.safeTransfer(_msgSender(), _amountRequested);

		emit AdminWithdrawn(_msgSender(), _amountRequested);
	}

	/**
    @notice Revoke active Grant. Grant must exist and be active.
    @param _recipient - Grant recipient wallet address
    */
	function revokeGrant(
		address _recipient
	) external onlyAdmin hasActiveGrant(_recipient) {
		Grant storage _grant = grants[_recipient];
		uint256 finalVestAmt = grantAllocation(_recipient);

		require(_grant.claimedAmount < finalVestAmt, "NO_UNVESTED_AMOUNT");

		_grant.isActive = false;
		_grant.deactivationTimestamp = uint40(block.timestamp);

		uint256 vestedSoFarAmt = vestedAmount(
			_recipient,
			uint40(block.timestamp)
		);
		uint256 amountRemaining = finalVestAmt - vestedSoFarAmt;
		numTokensReservedForVesting -= amountRemaining;

		emit GrantRevoked(
			_recipient,
			amountRemaining,
			_grant
		);
	}

	/**
    @notice Withdraw a token which isn't controlled by the vesting contract. Useful when someone accidentally sends tokens to the contract
    that arent the token that the contract is configured vest (tokenAddress).
    @param _otherTokenAddress - the token which we want to withdraw
     */
	function withdrawOtherToken(
		IERC20 _otherTokenAddress
	) external onlyAdmin nonReentrant {
		require(_otherTokenAddress != tokenAddress, "INVALID_TOKEN"); // tokenAddress address is already sure to be nonzero due to constructor
		uint256 balance = _otherTokenAddress.balanceOf(address(this));
		require(balance > 0, "INSUFFICIENT_BALANCE");
		_otherTokenAddress.safeTransfer(_msgSender(), balance);
	}

	/**
	 * @notice How many tokens are available to withdraw by the admin.
	 */
	function amountAvailableToWithdrawByAdmin() public view returns (uint256) {
		return
			tokenAddress.balanceOf(address(this)) - numTokensReservedForVesting;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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