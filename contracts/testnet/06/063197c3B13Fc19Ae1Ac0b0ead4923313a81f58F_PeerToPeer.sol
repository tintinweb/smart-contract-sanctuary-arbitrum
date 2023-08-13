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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error Peer__TransferFailed();
error Peer__NotAutorized();
error Peer__PositionIsClosed();
error Peer__NotEnoughBuyToken();
error Peer__SellTransferFailed();
error Peer__BuyTransferFailed();
error Peer__PositionIsNotTaken();
error Peer__PositionIsFinished();

contract PeerToPeer is ReentrancyGuard, Ownable, Pausable {
    struct Token {
        uint256 tokenId;
        string name;
        string symbol;
        address tokenAddress;
    }

    struct Position {
        uint256 positionId;
        uint256 createdDate;
        address sellerAddress;
        string sellToken;
        string buyToken;
        uint256 sellTokenQuantity;
        uint256 exchangeRate;
        uint256 buyTokenQuantity;
        bool open;
        bool finished;
    }

    string[] public tokenSymbols;
    mapping(string => Token) public tokens;
    mapping(uint256 => Position) public positions;
    uint256 public currentPositionId = 1;
    uint256 public currentTokenId = 1;
    uint256[] public positionIds;

    mapping(address => uint256[]) public positionIdsByAddress;

    //Store amount of all tokens
    mapping(string => uint256) public totalTokens;

    //Events
    event PositionAdded(
        address indexed seller,
        string sellToken,
        uint256 tokenQuantity,
        uint256 rate
    );

    event PositionCanceled(
        address indexed seller,
        uint256 positionId,
        uint256 tokenQuantity
    );

    event PositionTaken(
        address indexed buyer,
        uint256 positionId,
        uint256 sellTokenQuantity,
        uint256 buyTokenQuantity
    );

    event PositionWithdraw(
        address indexed seller,
        uint256 positionId,
        uint256 buyTokenQuantity
    );

    event Pause();
    event Unpause();

    //Main functions

    function addToken(
        string calldata _name,
        string calldata _symbol,
        address _tokenAddress
    ) external onlyOwner {
        tokenSymbols.push(_symbol);
        tokens[_symbol] = Token(currentTokenId, _name, _symbol, _tokenAddress);
        currentTokenId += 1;
    }

    function deleteToken(uint256 _tokenId) external onlyOwner {
        string memory tokenSymbol = tokenSymbols[_tokenId - 1];
        delete tokenSymbols[_tokenId - 1];
        delete tokens[tokenSymbol];
    }

    function getTokenSymbols() public view returns (string[] memory) {
        return tokenSymbols;
    }

    function getToken(
        string calldata _tokenSymbol
    ) public view returns (Token memory) {
        return tokens[_tokenSymbol];
    }

    function addPosition(
        string calldata _sellToken,
        string calldata _buyToken,
        uint256 _sellTokenQuantity,
        uint256 _exchangeRate
    ) external whenNotPaused {
        if (tokens[_sellToken].tokenId == 0) {
            revert Peer__NotAutorized();
        }
        if (tokens[_buyToken].tokenId == 0) {
            revert Peer__NotAutorized();
        }
        positions[currentPositionId] = Position(
            currentPositionId,
            block.timestamp,
            msg.sender,
            _sellToken,
            _buyToken,
            _sellTokenQuantity,
            _exchangeRate,
            (_sellTokenQuantity * _exchangeRate) / 10 ** 18,
            true,
            false
        );
        positionIdsByAddress[msg.sender].push(currentPositionId);
        positionIds.push(currentPositionId);
        currentPositionId += 1;
        totalTokens[_sellToken] += _sellTokenQuantity;

        bool success = IERC20(tokens[_sellToken].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _sellTokenQuantity
        );
        if (!success) {
            revert Peer__TransferFailed();
        }
        emit PositionAdded(
            msg.sender,
            _sellToken,
            _sellTokenQuantity,
            _exchangeRate / 10 ** 18
        );
    }

    function getPositionIds() public view returns (uint256[] memory) {
        return positionIds;
    }

    function getPositionIdsForAddress()
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[msg.sender];
    }

    function getPositionById(
        uint256 _positionId
    ) external view returns (Position memory) {
        return positions[_positionId];
    }

    function cancelPosition(
        uint256 _positionId
    ) external nonReentrant whenNotPaused {
        if (positions[_positionId].sellerAddress != msg.sender) {
            revert Peer__NotAutorized();
        }
        if (positions[_positionId].open != true) {
            revert Peer__PositionIsClosed();
        }
        positions[_positionId].open = false;
        positions[_positionId].finished = true;
        delete positionIds[_positionId - 1];
        // delete positionIdsByAddress[msg.sender][_positionId];

        bool success = IERC20(
            tokens[positions[_positionId].sellToken].tokenAddress
        ).transfer(msg.sender, positions[_positionId].sellTokenQuantity);
        if (!success) {
            revert Peer__TransferFailed();
        }

        // delete positions[_positionId];

        emit PositionCanceled(
            msg.sender,
            _positionId,
            positions[_positionId].sellTokenQuantity
        );
    }

    function takePosition(
        uint256 _positionId
    ) external nonReentrant whenNotPaused {
        if (positions[_positionId].open != true) {
            revert Peer__PositionIsClosed();
        }

        uint256 buyTokenQuantityInBuyer = IERC20(
            tokens[positions[_positionId].buyToken].tokenAddress
        ).balanceOf(msg.sender);

        uint256 buyTokenQuantityInPosition = positions[_positionId]
            .buyTokenQuantity;

        if (buyTokenQuantityInBuyer < buyTokenQuantityInPosition) {
            revert Peer__NotEnoughBuyToken();
        }
        positions[_positionId].open = false;
        delete positionIds[_positionId - 1];

        //Need approve function in frontend??
        bool buySuccess = IERC20(
            tokens[positions[_positionId].buyToken].tokenAddress
        ).transferFrom(msg.sender, address(this), buyTokenQuantityInPosition);
        if (!buySuccess) {
            revert Peer__BuyTransferFailed();
        }

        bool sellSuccess = IERC20(
            tokens[positions[_positionId].sellToken].tokenAddress
        ).transfer(msg.sender, positions[_positionId].sellTokenQuantity);
        if (!sellSuccess) {
            revert Peer__SellTransferFailed();
        }

        emit PositionTaken(
            msg.sender,
            _positionId,
            positions[_positionId].sellTokenQuantity,
            buyTokenQuantityInPosition
        );
    }

    function withdrawPosition(
        uint256 _positionId
    ) external nonReentrant whenNotPaused {
        if (positions[_positionId].sellerAddress != msg.sender) {
            revert Peer__NotAutorized();
        }
        if (positions[_positionId].open == true) {
            revert Peer__PositionIsNotTaken();
        }
        if (positions[_positionId].finished == true) {
            revert Peer__PositionIsFinished();
        }
        positions[_positionId].finished = true;

        bool success = IERC20(
            tokens[positions[_positionId].buyToken].tokenAddress
        ).transfer(msg.sender, positions[_positionId].buyTokenQuantity);
        if (!success) {
            revert Peer__TransferFailed();
        }

        // delete positions[_positionId];
        // delete positionIdsByAddress[msg.sender][_positionId];

        emit PositionWithdraw(
            msg.sender,
            _positionId,
            positions[_positionId].buyTokenQuantity
        );
    }

    //Pause functions
    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }
}