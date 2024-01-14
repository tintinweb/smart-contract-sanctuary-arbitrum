// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "Rosa.sol";
import "Ownable.sol";

/**
 * @title PrivateLBE
 * @dev Contract for the private Liquidity Bootstrapping Event of Rosa Finance.
 * Inherits from Ownable contract.
 */
contract PrivateLBE is Ownable {
    Rosa public rosa;
    bool public paused = false;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public maxAllocation;
    uint256 public totalAllocatedTokens;
    address public rosaWallet;
    uint256 public vestingStartTime;
    uint256 public constant VESTING_PERIOD = 7 days;

    /**
     * @dev Struct for storing allocation information for a beneficiary.
     */
    struct AllocationInfo {
        uint256 totalTokens;
        uint256 claimedTokens;
    }

    /**
     * @dev Mapping of beneficiary addresses to their allocation info.
     */
    mapping(address => AllocationInfo) public allocations;

    // Events
    event TokenAllocation(address indexed beneficiary, uint256 amount);
    event TokenClaimed(address indexed claimer, uint256 amount);
    event EventPaused(bool paused);
    event EventResumed(bool paused);

    /**
     * @dev Constructor for initializing the contract.
     * @param _openingTime The timestamp when the event starts.
     * @param _closingTime The timestamp when the event ends.
     * @param _rosa The address of the Rosa token contract.
     * @param _owner The owner of the contract.
     * @param _vestingStartTime The timestamp when the vesting period starts.
     * @param _rosaWallet The address of the wallet holding the Rosa tokens.
     * @param _maxAllocation The maximum amount of tokens that can be allocated.
     */
    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        Rosa _rosa,
        address _owner,
        uint256 _vestingStartTime,
        address _rosaWallet,
        uint256 _maxAllocation
    ) Ownable(_owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        require(_openingTime >= block.timestamp, "Opening time must be after current block time");
        require(_closingTime >= _openingTime, "Closing time must be after opening time");
        require(address(_rosa) != address(0), "ROSA address cannot be 0");
        require(_vestingStartTime >= _closingTime, "Vesting start must be after opening time");
        require(_rosaWallet != address(0), "External wallet address cannot be 0");
        require(_maxAllocation > 0, "Max allocation must be greater than 0");

        openingTime = _openingTime;
        closingTime = _closingTime;
        rosa = _rosa;
        totalAllocatedTokens = 0;
        vestingStartTime = _vestingStartTime;
        rosaWallet = _rosaWallet;
        maxAllocation = _maxAllocation;
    }

    /**
     * @dev Modifier to ensure the LBE event is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "LBE is paused");
        _;
    }

    /**
     * @dev Modifier to ensure the LBE event is paused.
     */
    modifier whenPaused() {
        require(paused, "LBE is not paused");
        _;
    }

    /**
     * @dev Checks if the LBE event is open.
     * @return A boolean indicating whether the event is open.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime && !paused;
    }

    /**
     * @dev Checks if the LBE event has finished.
     * @return A boolean indicating whether the event has finished.
     */
    function hasFinished() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    /**
     * @dev Allows a user to claim their allocated tokens.
     */
    function claimTokens() external whenNotPaused {
        uint256 tokensToClaim = _calculateClaimableTokens(msg.sender);
        require(tokensToClaim > 0, "No tokens to claim.");

        AllocationInfo storage allocation = allocations[msg.sender];
        allocation.claimedTokens += tokensToClaim;

        uint256 externalWalletBalance = rosa.balanceOf(rosaWallet);
        require(externalWalletBalance >= tokensToClaim, "External wallet does not have enough tokens to distribute.");

        require(rosa.transferFrom(rosaWallet, msg.sender, tokensToClaim), "Failed to transfer tokens to claimer.");

        emit TokenClaimed(msg.sender, tokensToClaim);
    }

    /**
     * @dev Calculates the amount of tokens a user can claim.
     * @param _user The address of the user.
     * @return The amount of tokens the user can claim.
     */
    function _calculateClaimableTokens(address _user) internal view returns (uint256) {
        AllocationInfo storage allocation = allocations[_user];
        if (block.timestamp < vestingStartTime) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - vestingStartTime;
        uint256 vestedTokens;

        if (elapsedTime >= VESTING_PERIOD) {
            vestedTokens = allocation.totalTokens;
        } else {
            vestedTokens = (allocation.totalTokens * elapsedTime) / VESTING_PERIOD;
        }

        return vestedTokens - allocation.claimedTokens;
    }

    /**
     * @dev Returns the amount of tokens a user can claim.
     * @param _user The address of the user.
     * @return The amount of tokens the user can claim.
     */
    function getClaimableTokens(address _user) external view returns (uint256) {
        return _calculateClaimableTokens(_user);
    }

    /**
     * @dev Returns the total amount of tokens allocated to a user.
     * @param _user The address of the user.
     * @return The total amount of tokens allocated to the user.
     */
    function getUserAllocatedTokens(address _user) external view returns (uint256) {
        return allocations[_user].totalTokens;
    }

    /*** Admin Functions ***/

    /**
     * @dev Allocates tokens to a beneficiary.
     * @param _beneficiary The address of the beneficiary.
     * @param _tokenAmount The amount of tokens to allocate.
     */
    function _allocateTokens(address _beneficiary, uint256 _tokenAmount) external onlyOwner whenNotPaused {
        require(_beneficiary != address(0), "Beneficiary address cannot be 0");
        require(_tokenAmount > 0, "Token amount should be greater than 0");
        require(totalAllocatedTokens + _tokenAmount <= maxAllocation, "Exceeding max token allocation");

        AllocationInfo storage allocation = allocations[_beneficiary];
        allocation.totalTokens += _tokenAmount;

        totalAllocatedTokens += _tokenAmount;

        emit TokenAllocation(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Allocates tokens to a batch of beneficiaries.
     * @param _beneficiaries The addresses of the beneficiaries.
     * @param _tokenAmounts The amounts of tokens to allocate.
     */
    function _allocateTokensBatch(address[] memory _beneficiaries, uint256[] memory _tokenAmounts) external onlyOwner whenNotPaused {
        require(_beneficiaries.length == _tokenAmounts.length, "Mismatched array lengths.");
        require(_beneficiaries.length > 0, "Beneficiaries array is empty.");

        uint256 tempTotalAllocated = totalAllocatedTokens;

        // Combine validation and allocation loops
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != address(0), "Beneficiary address cannot be 0");
            require(_tokenAmounts[i] > 0, "Token amount should be greater than 0");

            tempTotalAllocated += _tokenAmounts[i];
            AllocationInfo storage allocation = allocations[_beneficiaries[i]];
            allocation.totalTokens += _tokenAmounts[i];

            emit TokenAllocation(_beneficiaries[i], _tokenAmounts[i]);
        }

        require(tempTotalAllocated <= maxAllocation, "Exceeding max token allocation");

        totalAllocatedTokens = tempTotalAllocated; // Single state change
    }

    /**
     * @dev Pauses the LBE event.
     */
    function _pause() external onlyOwner whenNotPaused {
        paused = true;
        emit EventPaused(paused);
    }

    /**
     * @dev Resumes the LBE event.
     */
    function _unpause() external onlyOwner whenPaused {
        paused = false;
        emit EventResumed(paused);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Rosa {
    /// @notice EIP-20 token name for this token
    string public constant name = "Rosa";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "ROSA";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public constant totalSupply = 600_000e18; // 600k Rosa

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Construct a new Rosa token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) {
        require(account != address(0));
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "Rosa::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = safe96(
            rawAmount,
            "Rosa::transfer: amount exceeds 96 bits"
        );
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "Rosa::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "Rosa::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            block.timestamp <= expiry,
            "Rosa::delegateBySig: signature expired"
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Rosa::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Rosa::delegateBySig: invalid nonce"
        );
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        uint224 votes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        require(votes <= type(uint96).max, "Rosa::getCurrentVotes: votes exceeds 96 bits");
        return uint96(votes);
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "Rosa::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            uint224 votes = checkpoints[account][nCheckpoints - 1].votes;
            require(votes <= type(uint96).max, "Rosa::getPriorVotes: votes exceeds 96 bits");
            return uint96(votes);
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center;
            unchecked {
                center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            }
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                require(cp.votes <= type(uint96).max, "Rosa::getPriorVotes: votes exceeds 96 bits");
                return uint96(cp.votes);
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        uint224 finalVotes = checkpoints[account][lower].votes;
        require(finalVotes <= type(uint96).max, "Rosa::getPriorVotes: votes exceeds 96 bits");
        return uint96(finalVotes);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            src != address(0),
            "Rosa::_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "Rosa::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "Rosa::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = add96(
            balances[dst],
            amount,
            "Rosa::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint224 srcRepOld;
                unchecked {
                    srcRepOld = srcRepNum > 0
                        ? checkpoints[srcRep][srcRepNum - 1].votes
                        : 0;
                }
                uint96 srcRepNew = sub96(
                    uint96(srcRepOld),
                    amount,
                    "Rosa::_moveVotes: vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, uint96(srcRepOld), srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint224 dstRepOld;
                unchecked {
                    dstRepOld = dstRepNum > 0
                        ? checkpoints[dstRep][dstRepNum - 1].votes
                        : 0;
                }
                uint96 dstRepNew = add96(
                    uint96(dstRepOld),
                    amount,
                    "Rosa::_moveVotes: vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, uint96(dstRepOld), dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "Rosa::_writeCheckpoint: block number exceeds 32 bits"
        );

        unchecked {
            if (
                nCheckpoints > 0 &&
                checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
            ) {
                checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(
                    blockNumber,
                    newVotes
                );
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n <= type(uint96).max, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        unchecked {
            uint96 c = a + b;
            require(c >= a, errorMessage);
            return c;
        }
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        
        unchecked {
            return a - b;
        }
    }

    function getChainId() internal view returns (uint256) {
        return block.chainid;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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