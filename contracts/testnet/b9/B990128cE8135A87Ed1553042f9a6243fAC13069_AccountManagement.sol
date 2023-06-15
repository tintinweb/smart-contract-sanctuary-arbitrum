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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

/*
    Account contract for managing ephemeral accounts, player gaming status, and chips.
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IAccountManager.sol";

contract AccountManagement is IAccountManager, Ownable {
    // Accounts of all players
    mapping(address => Account) _accounts;

    // Collection of registered contracts to update `withholds` in `_accounts`
    //
    // # Warning
    // Not support yet multiple registed contracts for independent games.
    mapping(address => bool) public registeredContracts;

    // ephemeral => permanet account
    mapping(address => address) public accountMapping;

    // ERC20 Token type to swap with `chipEquity`
    address public token;

    // Exchange ratio where `chipEquity` = `ratio` * `token`
    uint256 public override ratio;

    // Minimal amount of tokens to deposit
    uint256 public minAmount;

    // Delay after which withholds can be repaid to players. Unit: Second
    uint256 public delay;

    // Largest game id which have been created
    uint256 public largestGameId;

    // Vig ratio with 2 decimals. For example, vig = 435 indicates 4.35%
    uint256 public vig;

    event ProfilePicUpdated(address indexed player, string indexed url);

    // Checks if there are enough chip equity.
    modifier enoughChips(address player, uint256 chipAmount) {
        require(_accounts[player].chipEquity >= chipAmount, "Not enough chips");
        _;
    }

    // Checks if the contract is registered.
    modifier onlyRegisteredContracts() {
        require(
            registeredContracts[msg.sender],
            "Not registered game contract"
        );
        _;
    }

    constructor(
        address _token,
        uint256 _ratio,
        uint256 _minAmount,
        uint256 _delay,
        uint256 _vig
    ) {
        token = _token;
        ratio = _ratio;
        minAmount = _minAmount;
        delay = _delay;
        vig = _vig;
        largestGameId = 0;
        _accounts[owner()].chipEquity = 0;
    }

    // Support saving the players owned nft as their profile pic
    function setProfilePic(string memory profilePic) external {
        _accounts[msg.sender].profilePic= profilePic;
        emit ProfilePicUpdated(msg.sender, profilePic);
    }

    // Returns the profile pic of the owner
    function getProfilePic(address owner) external view returns (string memory) {
        return _accounts[owner].profilePic;
    }

    // Deposits ERC20 tokens for chips.
    function deposit(uint256 tokenAmount) external payable override {
        require(tokenAmount > minAmount, "Amount less than minimum amount");
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        _accounts[msg.sender].chipEquity += tokenAmount * ratio;
    }

    // Withdraws chips for ERC20 tokens. Note that `withdraw` takes `chipAmount` but `deposit` takes `tokenAmount`.
    function withdraw(
        uint256 chipAmount
    ) external enoughChips(msg.sender, chipAmount) {
        uint256 tokenAmount = chipAmount / ratio;
        _accounts[msg.sender].chipEquity -= tokenAmount * ratio;
        IERC20(token).transfer(msg.sender, tokenAmount);
    }

    // Claims matured `withhold`s to `chipEquity` and returns the amount of unmatured chips.
    function claim() external returns (uint256) {
        uint256 maturedChips = 0;
        uint256 unmaturedChips = 0;
        uint256 index = 0;
        while (index < _accounts[msg.sender].withholds.length) {
            if (
                _accounts[msg.sender].withholds[index].maturityTime <=
                block.timestamp
            ) {
                maturedChips += _accounts[msg.sender].withholds[index].amount;
                removeWithhold(msg.sender, index);
            } else {
                unmaturedChips += _accounts[msg.sender].withholds[index].amount;
                index++;
            }
        }
        _accounts[msg.sender].chipEquity += maturedChips;
        return unmaturedChips;
    }

    // Authorizes `ephemeralAccount` for `permanentAccount` by a registered contract.
    //
    // # Note
    // We intentionally does not apply the following reset:
    // `accountMapping[_accounts[permanentAccount].ephemeralAccount] = address(0);`
    // Otherwise a malicious user could disable ephemeralAccount for all users.
    // This design choice indicates that a user can use previous ephemeral account
    // even if he has authorized a new ephemeral account.
    function authorize(
        address permanentAccount,
        address ephemeralAccount
    ) external onlyRegisteredContracts {
        if (accountMapping[ephemeralAccount] == permanentAccount) return;
        require(
            accountMapping[ephemeralAccount] == address(0),
            "Requested ephemeral account has been used"
        );
        _accounts[permanentAccount].ephemeralAccount = ephemeralAccount;
        accountMapping[ephemeralAccount] = permanentAccount;
    }

    // Returns `account` if it has not been registered as an ephemeral account;
    // otherwise returns the corresponding permanent account.
    function getPermanentAccount(
        address account
    ) external view returns (address) {
        if (accountMapping[account] == address(0)) {
            return account;
        } else {
            return accountMapping[account];
        }
    }

    // Checks if `permanentAccount` has authorized `ephemeralAccount`.
    function hasAuthorized(
        address permanentAccount,
        address ephemeralAccount
    ) external view override returns (bool) {
        return _accounts[permanentAccount].ephemeralAccount == ephemeralAccount;
    }

    // Gets the amount of chip equity.
    function getChipEquityAmount(
        address player
    ) external view override returns (uint256) {
        return _accounts[player].chipEquity;
    }

    function getChipEquityAmounts(
        address[] calldata players
    ) external view override returns (uint256[] memory chips) {
        chips = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; ++i) {
            chips[i] = _accounts[players[i]].chipEquity;
        }
    }

    // Gets the current game id of `player`.
    function getCurGameId(
        address player
    ) external view override returns (uint256) {
        return _accounts[player].gameId;
    }

    // Gets the largest game id.
    function getLargestGameId() external view override returns (uint256) {
        return largestGameId;
    }

    // Generates a new game id.
    function generateGameId()
        external
        override
        onlyRegisteredContracts
        returns (uint256)
    {
        return ++largestGameId;
    }

    // Joins a game with `gameId`, `buyIn`, and `isNewGame` on whether joining a new game or an existing game.
    // # Note: We prohibit players to join arbitrary game with `gameId`. We allow registered game contract to specify
    // `gameId` to resolve issues such as player collusion.
    function join(
        address permanentAccount,
        uint256 gameId,
        uint256 buyIn
    )
        external
        override
        onlyRegisteredContracts
        enoughChips(permanentAccount, buyIn)
    {
        require(
            _accounts[permanentAccount].gameId == 0,
            "Already joined a game"
        );
        _accounts[permanentAccount].gameId = gameId;
        _accounts[permanentAccount].chipEquity -= buyIn;
        _accounts[permanentAccount].withholds.push(
            Withhold({
                gameId: gameId,
                maturityTime: block.timestamp + delay,
                amount: buyIn
            })
        );
    }

    // Settles chips for `permanentAccount` and `gameId` by returning nearly `amount` (after `collectVigor`) chips to the player.
    // Chips are immediately repaid to `chipEquity` if `removeDelay`.
    function settleSinglePlayer(
        uint256 gameId,
        address permanentAccount,
        uint256 amount,
        bool collectVigor,
        bool removeDelay
    ) public onlyRegisteredContracts {
        require(
            _accounts[permanentAccount].gameId == gameId,
            "Player not in the game specified by gameId"
        );
        uint256 index = _accounts[permanentAccount].withholds.length - 1;
        uint256 betAmount = _accounts[permanentAccount].withholds[index].amount;
        if (amount > betAmount) {
            uint256 vigAmount = ((amount - betAmount) * vig) / 10000;
            vigAmount = collectVigor ? vigAmount : 0;
            _accounts[permanentAccount].withholds[index].amount =
                amount -
                vigAmount;
            _accounts[owner()].chipEquity += vigAmount;
        } else {
            _accounts[permanentAccount].withholds[index].amount = amount;
        }
        if (removeDelay) {
            _accounts[permanentAccount].chipEquity += _accounts[
                permanentAccount
            ].withholds[index].amount;
            removeWithhold(permanentAccount, index);
        }
        _accounts[permanentAccount].gameId = 0;
        emit Settled(
            permanentAccount,
            gameId,
            amount,
            collectVigor,
            removeDelay
        );
    }

    // Settles all players by iterating through `settle` on each player.
    function settle(
        uint256 gameId,
        address[] memory permanentAccounts,
        uint256[] memory amounts,
        bool collectVigor,
        bool removeDelay
    ) external onlyRegisteredContracts {
        require(gameId != 0, "Game has ended");
        for (uint8 i = 0; i < permanentAccounts.length; i++) {
            if (_accounts[permanentAccounts[i]].gameId == 0) {
                continue;
            }
            settleSinglePlayer(
                gameId,
                permanentAccounts[i],
                amounts[i],
                collectVigor,
                removeDelay
            );
        }
    }

    // Moves all chips from `from` to `to`.
    function move(address from, address to) internal {
        _accounts[to].chipEquity += _accounts[from].chipEquity;
        _accounts[from].chipEquity = 0;
    }

    // Registers a contract.
    function registerContract(address addr) external onlyOwner {
        if (!registeredContracts[addr]) {
            registeredContracts[addr] = true;
        }
    }

    // Unregisters a contract.
    function unregisterContract(address addr) external onlyOwner {
        if (registeredContracts[addr]) {
            registeredContracts[addr] = false;
        }
    }

    // Removes `index`-th withhold from `player`.
    function removeWithhold(address player, uint256 index) internal {
        _accounts[player].withholds[index] = _accounts[player].withholds[
            _accounts[player].withholds.length - 1
        ];
        _accounts[player].withholds.pop();
    }

    // @todo: test faceut, just give me chips
    function mintChips(address permanentAccount, uint256 amount) external {
        _accounts[permanentAccount].chipEquity += amount;
    }

    // Punishes `challenged` player by moving all his chips to `challenger`.
    // For other players, simply returns chips.
    function punish(
        uint256 gameId,
        address challenged,
        address challenger,
        address[] memory permanentAccounts
    ) external {
        for (uint256 i = 0; i < permanentAccounts.length; i++) {
            if (_accounts[permanentAccounts[i]].gameId == 0) {
                continue;
            }
            settleSinglePlayer(
                gameId,
                permanentAccounts[i],
                _accounts[permanentAccounts[i]]
                    .withholds[
                        _accounts[permanentAccounts[i]].withholds.length - 1
                    ]
                    .amount,
                false,
                true
            );
        }
        move(challenged, challenger);
        emit Punished(challenged, challenger, gameId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// Withhold information for a player and a specific game with `gameId`
struct Withhold {
    // Game Id
    uint256 gameId;
    // Time stamp after which the withheld chips is repaid to the player
    uint256 maturityTime;
    // Amount of chips under withhold
    uint256 amount;
}

// Account information for each permanent account.
struct Account {
    // Ephemeral account for in-game operations
    address ephemeralAccount;
    // Amount of chips owned by this account
    uint256 chipEquity;
    // Current game ID (1,2,...) if in game; Set to 0 if Not-In-Game.
    uint256 gameId;
    // An array of withheld chips
    Withhold[] withholds;
    // Link of the profile pic
    string profilePic;
}

interface IAccountManager {
    // `Challenged` is punished in `boardId` since `chanlleger` successfully challenged.
    event Punished(
        address indexed challenged,
        address indexed challenger,
        uint256 boardId
    );

    // Event that `permanentAccount` has received settlement funds of `amount` in `gameId`, considering whether `collectVigor` and receiving fund immediately (i.e., `removeDelay`).
    event Settled(
        address indexed permanentAccount,
        uint256 indexed gameId,
        uint256 indexed amount,
        bool collectVigor,
        bool removeDelay
    );

    // Generate a new game id.
    function generateGameId() external returns (uint256);

    // Joins a game with `gameId`, `buyIn`, and `isNewGame` on whether joining a new game or an existing game.
    //
    // # Note
    //
    // We prohibit players to join arbitrary game with `gameId`. We allow registered game contract to specify
    // `gameId` to resolve issues such as player collusion.
    function join(address player, uint256 gameId, uint256 buyIn) external;

    // Exchange ratio where `chipEquity` = `ratio` * `token`
    function ratio() external view returns (uint256);

    // ERC20 Token type to swap with `chipEquity`
    function token() external view returns (address);

    // Deposits ERC20 tokens for chips.
    function deposit(uint256 tokenAmount) external payable;

    // Authorizes `ephemeralAccount` for `permanentAccount` by a registered contract.
    function authorize(
        address permanentAccount,
        address ephemeralAccount
    ) external;

    // Checks if `permanentAccount` has authorized `ephemeralAccount`.
    function hasAuthorized(
        address permanentAccount,
        address ephemeralAccount
    ) external returns (bool);

    // Gets the largest game id which have been created.
    function getLargestGameId() external view returns (uint256);

    // Gets the current game id of `player`.
    function getCurGameId(address player) external view returns (uint256);

    // Returns the corresponding permanent account by ephemeral account
    function accountMapping(address ephemeral) external view returns (address);

    // Returns `account` if it has not been registered as an ephemeral account;
    // otherwise returns the corresponding permanent account.
    function getPermanentAccount(
        address account
    ) external view returns (address);

    // Gets the amount of chip equity.
    function getChipEquityAmount(
        address player
    ) external view returns (uint256);

    // Batch get the chip amounts of players
    function getChipEquityAmounts(
        address[] calldata players
    ) external view returns (uint256[] memory chips);

    // Punishes `challenged` player by moving all his chips to `challenger`.
    // For other players, simply returns chips.
    function punish(
        uint256 boardId,
        address challenged,
        address challenger,
        address[] memory permanentAccounts
    ) external;

    // Settles all players by iterating through `settle` on each player.
    function settle(
        uint256 gameId,
        address[] memory permanentAccount,
        uint256[] memory amount,
        bool collectVigor,
        bool removeDelay
    ) external;

    // Settles chips for `permanentAccount` and `gameId` by returning nearly `amount` (after `collectVigor`) chips to the player.
    // Chips are immediately repaid to `chipEquity` if `removeDelay`.
    function settleSinglePlayer(
        uint256 gameId,
        address permanentAccount,
        uint256 amount,
        bool collectVigor,
        bool removeDelay
    ) external;
}