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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IDarwinVester} from "./interface/IDarwinVester.sol";
import {IDarwin} from "./interface/IDarwin.sol";
import {IEvoturesNFT} from "./interface/IEvoturesNFT.sol";

/// @title Darwin Vester
contract DarwinVester is IDarwinVester, ReentrancyGuard, Ownable, IERC721Receiver {

    /// @notice Percentage of monthly interest (0.625%, 7.5% in a year)
    uint256 public constant INTEREST = 625;
    /// @notice Number of months thru which vested darwin will be fully withdrawable
    uint256 public constant MONTHS = 12;
    /// @notice Above in seconds
    uint256 public constant VESTING_TIME = MONTHS * (30 days);

    mapping(address => UserInfo) public userInfo;
    address[] users;
    uint[] atLaunch;

    /// @notice The Darwin token
    IERC20 public darwin;
    /// @notice Vest user address
    address public deployer;
    mapping(address => bool) public supportedNFT;

    bool private _isInitialized;

    modifier onlyInitialized() {
        if (!_isInitialized) {
            revert NotInitialized();
        }
        _;
    }

    modifier onlyVestUser() {
        if (userInfo[msg.sender].vested > 0) {
            revert NotVestUser();
        }
        _;
    }

    constructor(address[] memory _users, uint[] memory _atLaunch, uint[] memory _due, address[] memory _supportedNFTs) {
        require(_users.length == _due.length && _due.length == _atLaunch.length, "Vester: Invalid _userInfo");
        for (uint i = 0; i < _users.length; i++) {
            userInfo[_users[i]].vested = _due[i] - _atLaunch[i];
        }
        users = _users;
        atLaunch = _atLaunch;
        deployer = msg.sender;
        for (uint i = 0; i < _supportedNFTs.length; i++) {
            supportedNFT[_supportedNFTs[i]] = true;
        }
    }

    function init(address _darwin) external {
        require (msg.sender == deployer, "Vester: Caller not Deployer");
        require (address(darwin) == address(0), "Vester: Darwin already set");
        darwin = IERC20(_darwin);
    }

    function startVesting() external {
        require(!_isInitialized, "Vester: Already initialized");
        _isInitialized = true;
        for (uint i = 0; i < users.length; i++) {
            emit Vest(users[i], userInfo[users[i]].vested);

            userInfo[users[i]].claimed = 0;
            userInfo[users[i]].withdrawn = 0;
            userInfo[users[i]].vestTimestamp = block.timestamp;
            IERC20(address(darwin)).transfer(users[i], atLaunch[i]);
        }
    }

    // Withdraws darwin from contract and also claims any minted darwin. If _amount == 0, does not withdraw but just claim.
    function withdraw(uint _amount) external onlyInitialized onlyVestUser nonReentrant {
        _withdraw(msg.sender, _amount);
    }

    function _withdraw(address _user, uint _amount) internal {
        _claim(_user);
        if (_amount > 0) {
            uint withdrawable = withdrawableDarwin(_user);
            if (_amount > withdrawable) {
                revert AmountExceedsWithdrawable();
            }
            userInfo[_user].vested -= _amount;
            userInfo[_user].withdrawn += _amount;
            if (!darwin.transfer(_user, _amount)) {
                revert TransferFailed();
            }
            emit Withdraw(_user, _amount);
        }
    }

    function _claim(address _user) internal {
        uint claimAmount = claimableDarwin(msg.sender);
        if (claimAmount > 0) {
            userInfo[_user].claimed += claimAmount;
            IDarwin(address(darwin)).mint(_user, claimAmount);
            emit Claim(_user, claimAmount);
        }
    }

    function stakeEvoture(address _nft, uint16 _tokenId) external nonReentrant {
        require(userInfo[msg.sender].nft == address(0), "DarwinVester: NFT_ALREADY_STAKED");
        require(supportedNFT[_nft], "DarwinVester: UNSUPPORTED_NFT");

        _claim(msg.sender);
        IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
        userInfo[msg.sender].nft = _nft;
        userInfo[msg.sender].boost = IEvoturesNFT(_nft).multipliers(_tokenId);
        userInfo[msg.sender].tokenId = _tokenId;

        emit StakeEvoture(msg.sender, _tokenId, userInfo[msg.sender].boost);
    }

    function withdrawEvoture() external nonReentrant {
        require(userInfo[msg.sender].nft != address(0), "DarwinVester: NO_NFT_TO_WITHDRAW");

        _claim(msg.sender);
        IERC721(userInfo[msg.sender].nft).safeTransferFrom(address(this), msg.sender, userInfo[msg.sender].tokenId);
        userInfo[msg.sender].nft = address(0);
        userInfo[msg.sender].boost = 0;
        userInfo[msg.sender].tokenId = 0;

        emit WithdrawEvoture(msg.sender, userInfo[msg.sender].tokenId);
    }

    function addSupportedNFT(address _nft) external {
        require(msg.sender == deployer, "DarwinVester: CALLER_IS_NOT_DEV");
        supportedNFT[_nft] = true;
    }

    function removeSupportedNFT(address _nft) external {
        require(msg.sender == deployer, "DarwinVester: CALLER_IS_NOT_DEV");
        supportedNFT[_nft] = false;
    }

    function withdrawableDarwin(address _user) public view returns(uint256 withdrawable) {
        uint vested = userInfo[_user].vested;
        if (vested == 0) {
            return 0;
        }
        uint withdrawn = userInfo[_user].withdrawn;
        uint start = userInfo[_user].vestTimestamp;
        uint passedMonthsFromStart = (block.timestamp - start) / (30 days);
        if (passedMonthsFromStart > MONTHS) {
            passedMonthsFromStart = MONTHS;
        }
        withdrawable = (((vested + withdrawn) * passedMonthsFromStart) / MONTHS) - withdrawn;
        if (withdrawable > vested) {
            withdrawable = vested;
        }
    }

    function claimableDarwin(address _user) public view returns(uint256 claimable) {
        uint vested = userInfo[_user].vested;
        if (vested == 0) {
            return 0;
        }
        uint claimed = userInfo[_user].claimed;
        uint boost = userInfo[_user].boost;
        uint start = userInfo[_user].vestTimestamp;
        uint passedMonthsFromStart = (block.timestamp - start) / (30 days);
        claimable = (((vested * INTEREST) / 100000) * passedMonthsFromStart) - claimed;

        if (boost > 0) {
            claimable += ((claimable * boost) / 1000);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import {IStakedDarwin} from "./IStakedDarwin.sol";

interface IDarwin {

    event ExcludedFromReflection(address account, bool isExcluded);
    event SetPaused(uint timestamp);
    event SetUnpaused(uint timestamp);

    // PUBLIC
    function distributeRewards(uint256 amount) external;
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

    // COMMUNITY
    // function upgradeTo(address newImplementation) external; RESTRICTED
    // function upgradeToAndCall(address newImplementation, bytes memory data) external payable; RESTRICTED
    function setMinter(address user_, bool canMint_) external; // RESTRICTED
    function setMaintenance(address _addr, bool _hasRole) external; // RESTRICTED
    function setSecurity(address _addr, bool _hasRole) external; // RESTRICTED
    function setUpgrader(address _account, bool _hasRole) external; // RESTRICTED
    function setReceiveRewards(address account, bool shouldReceive) external; // RESTRICTED
    function communityPause() external; // RESTRICTED
    function communityUnPause() external;

    // FACTORY
    function registerDarwinSwapPair(address _pair) external;

    // MAINTENANCE
    function setDarwinSwapFactory(address _darwinSwapFactory) external;
    function setDarwinStaking(address _darwinStaking) external;
    function setMasterChef(address _masterChef) external;

    // MINTER
    function mint(address account, uint256 amount) external;

    // VIEW
    function isPaused() external view returns (bool);
    function stakedDarwin() external view returns(IStakedDarwin);
    function MAX_SUPPLY() external pure returns(uint256);

    // BURN
    function burn(uint256 amount) external;

    /// TransferFrom amount is greater than allowance
    error InsufficientAllowance();
    /// Only the DarwinCommunity can call this function
    error OnlyDarwinCommunity();

    /// Input cannot be the zero address
    error ZeroAddress();
    /// Amount cannot be 0
    error ZeroAmount();
    /// Arrays must be the same length
    error InvalidArrayLengths();

    /// Holding limit exceeded
    error HoldingLimitExceeded();
    /// Sell limit exceeded
    error SellLimitExceeded();
    /// Paused
    error Paused();
    error AccountAlreadyExcluded();
    error AccountNotExcluded();

    /// Max supply reached, cannot mint more Darwin
    error MaxSupplyReached();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Interface for the Darwin Vester
interface IDarwinVester {

    /// Presale contract is already initialized
    error AlreadyInitialized();
    /// Presale contract is not initialized
    error NotInitialized();
    /// Caller is not private sale
    error NotPrivateSale();
    /// Caller is not vester
    error NotVestUser();
    /// Parameter cannot be the zero address
    error ZeroAddress();
    /// Selected amount exceeds the withdrawable amount
    error AmountExceedsWithdrawable();
    /// Selected amount exceeds the claimable amount
    error AmountExceedsClaimable();
    /// Attempted transfer failed
    error TransferFailed();

    event Vest(address indexed user, uint indexed vestAmount);
    event Withdraw(address indexed user, uint indexed withdrawAmount);
    event Claim(address indexed user, uint indexed claimAmount);

    event StakeEvoture(address indexed user, uint indexed evotureTokenId, uint indexed multiplier);
    event WithdrawEvoture(address indexed user, uint indexed evotureTokenId);

    struct UserInfo {
        uint256 withdrawn;
        uint256 vested;
        uint256 vestTimestamp;
        uint256 claimed;
        uint256 boost;
        address nft;
        uint256 tokenId;
    }
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

interface IEvoturesNFT {

    function mint(uint8 _evotures, uint8 _boosters, address to) external payable;
    function chainlinkMint(uint256[] memory _randomWords, uint8 _evotures, uint8 boosters_, address _minter) external;

    function BOOSTER_PRICE() external view returns(uint64);
    function dev() external view returns(address);
    function multipliers(uint16 id) external view returns(uint16 mult);
}

pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}