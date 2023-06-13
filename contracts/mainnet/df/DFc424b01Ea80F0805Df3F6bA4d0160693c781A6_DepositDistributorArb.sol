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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DepositDistributorArb is ERC1155Holder, Ownable, ReentrancyGuard {
    // ERC1155 token and deposit-related state variables
    IERC1155 public erc1155Token; // ERC1155 token interface

    uint256 private daoTokenId; // DAO token ID

    // Staking-related state variables
    mapping(address => uint256) public stakedAt; // Timestamp when a user staked their tokens
    mapping(address => uint256) public stakedTokens; // Mapping of staked tokens per user
    address[] public stakedUsers; // Array of staked user addresses
    mapping(address => uint256) public stakedBalances; // Mapping of staked token balances per user
    mapping(address => uint256) public stakedUserIndexes; // Mapping of user indexes in the stakedUsers array
    uint256 public constant MINIMUM_STAKING_DURATION = 21 days; // Minimum staking duration

    // Deposit-related state variables
    mapping(uint256 => uint256) public depositTimestamps; // Mapping of deposit timestamps
    mapping(address => uint256) public balances; // Mapping of user balances
    mapping(address => mapping(uint256 => bool)) private claimed; // Mapping of claimed deposits per user
    mapping(address => bool) public allowList; // Mapping of allowed addresses for depositing
    uint256 private totalDeposits; // Total deposits for rewards distribution
    uint256 private totalDeposited; // Total deposited funds in the contract

    uint256 private daoTokenTotalSupply; // Total supply of the DAO token

    // Beneficiary state variable
    address public beneficiary; // Address of the beneficiary for unclaimed rewards

    // Events declaration
    event Deposited(
        address indexed depositor,
        uint256 amount,
        uint256 totalDeposited
    );
    event Distributed(uint256 totalDistributed);
    event Claimed(address indexed claimer, uint256 amount);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed unstaker, uint256 amount);

    constructor(
        address _erc1155Token,
        uint256 _daoTokenId,
        address _beneficiary,
        uint256 _initialTotalSupply
    ) Ownable() {
        erc1155Token = IERC1155(_erc1155Token);
        daoTokenId = _daoTokenId;
        beneficiary = _beneficiary;
        daoTokenTotalSupply = _initialTotalSupply;
    }

    // Function to deposit funds restricted to addresses on the allow list
    function deposit(
        uint256 amount
    ) external payable onlyAllowList {
        require(msg.value == amount, "Incorrect deposit amount");

        totalDeposited += amount;
        distribute();

        depositTimestamps[totalDeposits] = block.timestamp;

        totalDeposits += 1;

        emit Deposited(msg.sender, amount, totalDeposited);
    }

    // Function to stake tokens
    function distribute() private  {

        if (stakedUsers.length == 0) {
        return;
    }


        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < stakedUsers.length; i++) {
            address member = stakedUsers[i];
            uint256 balance = stakedBalances[member];

            uint256 share = (balance * totalDeposited) / (daoTokenTotalSupply);
            balances[member] += share;
            totalDistributed += share;
        }

        uint256 unclaimedRewards = totalDeposited - totalDistributed;
        (bool success, ) = payable(beneficiary).call{value: unclaimedRewards}(
            ""
        );
        require(success, "Transfer failed.");
        totalDeposited = 0;

        emit Distributed(totalDistributed);
    }

    // Function to claim rewards restricted to DAO members
    function claim() external nonReentrant {
        require(balances[msg.sender] > 0, "No balance to claim");
        require(
            !claimed[msg.sender][totalDeposits],
            "Already claimed for this deposit"
        );
        require(isStaked(msg.sender), "Not staked");
        claimed[msg.sender][totalDeposits] = true;

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");

        emit Claimed(msg.sender, balance);
    }

    // Function to stake tokens
    function stake() external nonReentrant {
        uint256 userBalance = erc1155Token.balanceOf(msg.sender, daoTokenId);
        require(userBalance > 0, "Sender is not a member");
        require(stakedAt[msg.sender] == 0, "Already staked");

        erc1155Token.safeTransferFrom(
            msg.sender,
            address(this),
            daoTokenId,
            userBalance,
            ""
        );

        stakedAt[msg.sender] = block.timestamp;
        stakedTokens[msg.sender] = userBalance;
        stakedBalances[msg.sender] = userBalance;
        stakedUsers.push(msg.sender);
        stakedUserIndexes[msg.sender] = stakedUsers.length - 1;

        emit Staked(msg.sender, userBalance);
    }

    // Function to unstake tokens
    function unstake() external nonReentrant {
        require(stakedAt[msg.sender] > 0, "Not staked");
        uint256 stakedTime = block.timestamp - stakedAt[msg.sender];
        require(
            stakedTime >= MINIMUM_STAKING_DURATION,
            "Minimum staking duration not reached"
        );

        uint256 userStakedTokens = stakedTokens[msg.sender];
        erc1155Token.safeTransferFrom(
            address(this),
            msg.sender,
            daoTokenId,
            userStakedTokens,
            ""
        );

        stakedAt[msg.sender] = 0;
        stakedTokens[msg.sender] = 0;
        stakedBalances[msg.sender] = 0;

        uint256 userIndex = stakedUserIndexes[msg.sender];
        uint256 lastIndex = stakedUsers.length - 1;
        stakedUsers[userIndex] = stakedUsers[lastIndex];
        stakedUserIndexes[stakedUsers[userIndex]] = userIndex;
        stakedUsers.pop();

        emit Unstaked(msg.sender, userStakedTokens);
    }

    // Function to check whether a member is staked
    function isStaked(address member) public view returns (bool) {
        return stakedAt[member] > 0;
    }

    // Function to add an address to the allow list, restricted to the contract owner
    function addToAllowList(address _user) external onlyOwner {
        allowList[_user] = true;
    }

    // Function to remove an address from the allow list, restricted to the contract owner
    function removeFromAllowList(address _user) external onlyOwner {
        allowList[_user] = false;
    }

    // Modifier to restrict access to addresses on the allow list
    modifier onlyAllowList() {
        require(allowList[msg.sender], "Sender not on allow list");
        _;
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }

    receive() external payable {
        revert("Direct transfers not allowed");
    }

    // Function to get the total number of deposits made to the contract
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    // Function to get the total amount of funds deposited to the contract
    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }

    // Function to get the total supply of the DAO token
    function getDaoTokenTotalSupply() external view returns (uint256) {
        return daoTokenTotalSupply;
    }

    // Function to get the ID of the DAO token
    function getDaoTokenId() external view returns (uint256) {
        return daoTokenId;
    }

    function getStakedBalance(address user) public view returns (uint256) {
    return stakedBalances[user];

    }

    function getStakedTokens(address user) public view returns (uint256) {
    return stakedTokens[user];
    
    }

    function getBalance(address user) public view returns (uint256) {
    return balances[user];
    
    }

    // Function to check if a specific address has claimed rewards
    function hasClaimed(
        address user,
        uint256 depositIndex
    ) external view returns (bool) {
        return claimed[user][depositIndex];
    }

    // Function to check if a specific address has claimed rewards
}