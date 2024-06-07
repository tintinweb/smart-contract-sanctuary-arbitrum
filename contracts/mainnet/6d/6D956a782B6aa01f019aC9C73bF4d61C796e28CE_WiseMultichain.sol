// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract WiseMultichain is Ownable {
    enum Status {
        SUBMITTED,
        ACCEPTED,
        MERGED,
        REJECTED,
        SPAM
    }

    struct Submission {
        string data_cid;
        address submitter;
        Status status;
        uint256 stake;
        uint256 createdAt;
        uint256 updatedAt;
    }

    Submission[] public submissions;
    uint256 public stakeRequired = 0;
    uint256 public pageLength = 25; // Default page length set to 25
    event StatusChanged(uint256 indexed _index, Status indexed _status, string data_cid, address submitter, uint256 stake, uint256 updatedAt, uint256 createdAt);

    constructor() {
        transferOwnership(0x3cDB9bC080Efe321A797E7286d302B90227cc6De); // Deployer
    }

    function getSubmissionCount() public view returns (uint256) {
        return submissions.length;
    }

    function createSubmission(string calldata data) public payable {
        require(msg.value >= stakeRequired, "Stake Ether to create a submission.");
        uint256 currentTime = block.timestamp;
        submissions.push(Submission(data, msg.sender, Status.SUBMITTED, msg.value, currentTime, currentTime));
        emit StatusChanged(submissions.length - 1, Status.SUBMITTED, data, msg.sender, msg.value, currentTime, currentTime);
    }

    function approveSubmission(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.ACCEPTED;
        submissions[submissionIndex].updatedAt = block.timestamp;
        emit StatusChanged(submissionIndex, Status.ACCEPTED, submissions[submissionIndex].data_cid, submissions[submissionIndex].submitter, submissions[submissionIndex].stake, block.timestamp, submissions[submissionIndex].createdAt);
    }

    function rejectSubmission(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.REJECTED;
        submissions[submissionIndex].updatedAt = block.timestamp;
        emit StatusChanged(submissionIndex, Status.REJECTED, submissions[submissionIndex].data_cid, submissions[submissionIndex].submitter, submissions[submissionIndex].stake, block.timestamp, submissions[submissionIndex].createdAt);
    }

    function mergeSubmission(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.MERGED;
        submissions[submissionIndex].updatedAt = block.timestamp;
        emit StatusChanged(submissionIndex, Status.MERGED, submissions[submissionIndex].data_cid, submissions[submissionIndex].submitter, submissions[submissionIndex].stake, block.timestamp, submissions[submissionIndex].createdAt);
    }

    function markSubmissionAsSpam(uint256 submissionIndex) public onlyOwner {
        submissions[submissionIndex].status = Status.SPAM;
        submissions[submissionIndex].updatedAt = block.timestamp;
        emit StatusChanged(submissionIndex, Status.SPAM, submissions[submissionIndex].data_cid, submissions[submissionIndex].submitter, submissions[submissionIndex].stake, block.timestamp, submissions[submissionIndex].createdAt);
    }

    function changeSubmissionStake(uint256 _stakeRequired) public onlyOwner {
        stakeRequired = _stakeRequired;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // View Functions
    function getRecentSubmissionsByPage(uint256 page) public view returns (Submission[] memory) {
        uint256 submissionLength = submissions.length;
        uint256 paginationIndex = submissionLength - pageLength * (page + 1);
    
        // Adjust paginationIndex if it becomes negative
        if (int(paginationIndex) < 0) {
            paginationIndex = 0;
        }
    
        uint256 itemsToReturn = submissionLength - paginationIndex;
        if (itemsToReturn > pageLength) {
            itemsToReturn = pageLength;
        }
    
        Submission[] memory pageSubmissions = new Submission[](itemsToReturn);
        for (uint256 i = 0; i < itemsToReturn; i++) {
            pageSubmissions[i] = submissions[paginationIndex + i];
        }
    
        return pageSubmissions;
    }

    function getSubmissionsAtPage(uint256 page) public view returns (Submission[] memory) {
        uint256 paginationIndex = page * pageLength;
        uint256 submissionLength = submissions.length;
        uint256 remainingIndex = submissionLength - paginationIndex;
        uint256 arrAlloc = pageLength;
        if (remainingIndex < pageLength) {
            arrAlloc = remainingIndex;
        }
        Submission[] memory id = new Submission[](arrAlloc);

        uint256 index = 0;
        for (uint256 i = paginationIndex; i < paginationIndex + arrAlloc; i++) {
            Submission storage submission = submissions[i];
            id[index] = submission;
            index = index + 1;
        }
        return id;
    }

    function getDescSubmissionsAtPage(uint256 page) public view returns (Submission[] memory) {
        uint256 submissionLength = submissions.length;
        uint256 paginationIndex = submissionLength - (pageLength * (page + 1));
        Submission[] memory id = new Submission[](pageLength);

        uint256 index = 0;
        for (uint256 i = paginationIndex; i < paginationIndex + pageLength; i++) {
            Submission storage submission = submissions[i];
            if (submission.status != Status.SPAM) {
                id[index] = submission;
                index = index + 1;
            }
        }
        return id;
    }

    // TESTS
    function getSubmissionAtIndex(uint256 submissionIndex) public view returns (Submission memory) {
        return submissions[submissionIndex];
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