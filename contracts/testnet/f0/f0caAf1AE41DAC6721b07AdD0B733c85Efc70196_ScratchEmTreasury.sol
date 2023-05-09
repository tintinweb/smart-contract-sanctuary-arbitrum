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

interface IScratchEmTreasury {
    function gameDeposit(address token, uint256 amount) external;

    function gameWithdraw(address to, address token, uint256 amount) external;

    function gameResult(address to, address token, uint256 amount) external;

    function claimRewardsByGame(
        address user,
        address token,
        uint amount
    ) external;

    function nonceLock(
        uint nonce,
        address user,
        address token,
        uint256 amount
    ) external payable;

    function nonceUnlock(
        uint nonce,
        uint8 swapType,
        address[] calldata path,
        uint burnCut,
        uint afterTransferCut,
        address afterTransferToken,
        address afterTransferAddress
    ) external;

    function nonceRevert(uint nonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IScratchGames {
    function scratchAndClaimAllCardsTreasury() external;

    function scratchAllCardsTreasury() external;

    function burnAllCardsTreasury() external;

    function endMint(uint256 _nonce, uint256[] calldata rngList) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISushiswapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IScratchEmTreasury.sol";
import "./interfaces/IScratchGames.sol";

import "./interfaces/ISushiswapRouter.sol";

contract ScratchEmTreasury is Ownable, IScratchEmTreasury, ReentrancyGuard {
    /// TOKEN VARIABLES
    address[] public playableTokens;
    mapping(address => bool) public isPlayableToken;

    mapping(address => uint256) public unclaimedRewards;

    ISushiswapRouter public sushiRouter;

    IERC20 public immutable SEMT;

    uint public lockedSEMT = 85000 * 10 ** 9;

    /// user => token => amount
    mapping(address => mapping(address => uint256))
        public unclaimedRewardsPerUser;

    mapping(address => mapping(address => bool)) internal hasRewardsInGame;
    mapping(address => address[]) internal gamesWithRewards;

    mapping(address => mapping(uint256 => uint)) public nonceLocked;
    mapping(address => mapping(uint256 => address)) public nonceToken;
    mapping(address => mapping(uint256 => address)) public nonceUser;

    /// GAME VARIABLES
    mapping(address => bool) public isGame;

    /// EVENTS

    event PlayableTokenAdded(address token);
    event PlayableTokenRemoved(address token);

    event Deposit(address token, uint256 amount);
    event Withdraw(address token, uint256 amount);

    event GameAdded(address game);
    event GameRemoved(address game);

    event GameDeposit(address from, address token, uint256 amount);
    event GameWithdraw(address token, uint256 amount, address to);

    event NonceLocked(address user, address token, uint256 amount);
    event NonceUnlocked(address user, address token, uint256 amount);

    event GameResulted(address game, address token, uint256 amount);
    event RewardsClaimed(address user, address token, uint256 amount);

    /// MODIFIERS

    /// @notice only games can call
    modifier onlyGame() {
        require(
            isGame[msg.sender],
            "ScratchEmTreasury: only games can call this function"
        );
        _;
    }

    /// @notice only playable tokens can be used
    modifier onlyPlayableToken(address token) {
        require(
            isPlayableToken[token],
            "ScratchEmTreasury: token is not playable"
        );
        _;
    }

    /// CONSTRUCTOR
    constructor(
        address[] memory _playableTokens,
        address _sushiRouter,
        address _semt
    ) {
        for (uint256 i = 0; i < _playableTokens.length; i++) {
            playableTokens.push(_playableTokens[i]);
            isPlayableToken[_playableTokens[i]] = true;
        }
        sushiRouter = ISushiswapRouter(_sushiRouter);
        SEMT = IERC20(_semt);
        isPlayableToken[_semt] = true;
    }

    /// SETTERS

    /// @notice set the sushi router
    /// @param _sushiRouter address of sushi router
    function setSushiRouter(address _sushiRouter) external onlyOwner {
        sushiRouter = ISushiswapRouter(_sushiRouter);
    }

    /// TOKEN CONTROL

    /// @notice add a token to the list of playable tokens
    /// @param token address of token to add
    function addPlayableToken(address token) external onlyOwner {
        playableTokens.push(token);
        isPlayableToken[token] = true;
        emit PlayableTokenAdded(token);
    }

    /// @notice remove a token from the list of playable tokens
    /// @param token address of token to remove
    function removePlayableToken(
        address token
    ) external onlyOwner onlyPlayableToken(token) {
        for (uint256 i = 0; i < playableTokens.length; i++) {
            if (playableTokens[i] == token) {
                playableTokens[i] = playableTokens[playableTokens.length - 1];
                playableTokens.pop();
                break;
            }
        }
        emit PlayableTokenRemoved(token);
    }

    function addSEMTLockAmount(uint _amount) external onlyOwner {
        lockedSEMT += _amount;
    }

    /// GAME CONTROL

    /// @notice add a game to the list of playable games
    /// @param game address of game to add
    function addGame(address game) external onlyOwner {
        require(!isGame[game], "ScratchEmTreasury: game is already playable");
        isGame[game] = true;
        emit GameAdded(game);
    }

    /// @notice remove a game from the list of playable games
    /// @param game address of game to remove
    function removeGame(address game) external onlyOwner {
        require(isGame[game], "ScratchEmTreasury: game is not playable");
        isGame[game] = false;
        emit GameRemoved(game);
    }

    function gameDeposit(
        address token,
        uint256 amount
    ) external onlyPlayableToken(token) nonReentrant onlyGame {
        if (!hasRewardsInGame[tx.origin][msg.sender]) {
            gamesWithRewards[tx.origin].push(msg.sender);
            hasRewardsInGame[tx.origin][msg.sender] = true;
        }
        bool success = IERC20(token).transferFrom(
            tx.origin,
            address(this),
            amount
        );
        require(success, "ScratchEmTreasury: transfer failed");
        emit GameDeposit(tx.origin, token, amount);
    }

    function gameWithdraw(
        address to,
        address token,
        uint256 amount
    ) external onlyPlayableToken(token) nonReentrant onlyGame {
        require(
            unclaimedRewards[token] >= amount,
            "ScratchEmTreasury: not enough unclaimed rewards"
        );
        bool success = IERC20(token).transfer(to, amount);
        require(success, "ScratchEmTreasury: transfer failed");
        emit GameWithdraw(token, amount, to);
    }

    function gameResult(
        address to,
        address token,
        uint256 amount
    ) external nonReentrant onlyPlayableToken(token) onlyGame {
        if (!hasRewardsInGame[to][msg.sender]) {
            gamesWithRewards[to].push(msg.sender);
            hasRewardsInGame[to][msg.sender] = true;
        }
        unclaimedRewards[token] += amount;
        unclaimedRewardsPerUser[to][token] =
            unclaimedRewardsPerUser[to][token] +
            amount;
        if (token == address(SEMT) && lockedSEMT > 0) {
            if (amount > lockedSEMT) {
                lockedSEMT -= amount;
            } else {
                lockedSEMT = 0;
            }
        }
        emit GameResulted(to, token, amount);
    }

    function nonceLock(
        uint nonce,
        address user,
        address token,
        uint256 amount
    ) external payable onlyGame {
        if (!hasRewardsInGame[tx.origin][msg.sender]) {
            gamesWithRewards[tx.origin].push(msg.sender);
            hasRewardsInGame[tx.origin][msg.sender] = true;
        }
        if (token == address(0)) {
            nonceLocked[msg.sender][nonce] = amount;
            nonceUser[msg.sender][nonce] = user;
            unclaimedRewards[token] += msg.value;
        } else {
            nonceLocked[msg.sender][nonce] = amount;
            nonceToken[msg.sender][nonce] = token;
            nonceUser[msg.sender][nonce] = user;
            unclaimedRewards[token] += amount;
            IERC20(token).transferFrom(user, address(this), amount);
        }
        emit NonceLocked(user, token, amount);
    }

    /// @notice unlock a nonce
    /// @param nonce nonce to unlock
    /// @param swapType type of swap to perform
    /// (0 = no swap, 1 = swap from token to ETH, 2 = swap from ETH to token, 3 = swap from token to token)
    /// @param path path to swap through
    /// @param burnCut amount to burn
    /// @param afterTransferCut amount to transfer after swap
    /// @param afterTransferToken token to transfer after swap
    /// @param afterTransferAddress address to transfer after swap
    function nonceUnlock(
        uint nonce,
        uint8 swapType,
        address[] calldata path,
        uint burnCut,
        uint afterTransferCut,
        address afterTransferToken,
        address afterTransferAddress
    ) external onlyGame {
        require(
            nonceLocked[msg.sender][nonce] > 0,
            "ScratchEmTreasury: nonce not locked"
        );
        address token = nonceToken[msg.sender][nonce];
        address user = nonceUser[msg.sender][nonce];
        uint256 amount = nonceLocked[msg.sender][nonce];
        nonceLocked[msg.sender][nonce] = 0;
        unclaimedRewards[token] -= amount;
        if (burnCut > 0) {
            _burnToken(amount, token, burnCut);
        }
        if (swapType == 1) {
            _swapTokensForETH(amount, path);
        } else if (swapType == 2) {
            _swapETHForTokens(amount, path);
        } else if (swapType == 3) {
            _swapTokensForTokens(amount, path);
        }
        if (afterTransferCut > 0) {
            uint afterTransferAmount = (amount * afterTransferCut) / 100;
            IERC20(afterTransferToken).transfer(
                afterTransferAddress,
                afterTransferAmount
            );
        }
        emit NonceUnlocked(user, token, 0);
    }

    function _burnToken(
        uint amount,
        address token,
        uint256 burnCut
    ) internal returns (uint256) {
        amount = (amount * burnCut) / 100;
        IERC20(token).transfer(
            0x000000000000000000000000000000000000dEaD,
            amount
        );
        return amount;
    }

    function _swapETHForTokens(uint amount, address[] calldata path) internal {
        sushiRouter.swapExactETHForTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function _swapTokensForETH(uint amount, address[] calldata path) internal {
        IERC20(path[0]).approve(address(sushiRouter), amount);
        sushiRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function _swapTokensForTokens(
        uint amount,
        address[] calldata path
    ) internal {
        IERC20(path[0]).approve(address(sushiRouter), amount);
        sushiRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function nonceRevert(uint nonce) external onlyGame {
        require(
            nonceLocked[msg.sender][nonce] > 0,
            "ScratchEmTreasury: nonce not locked"
        );
        address token = nonceToken[msg.sender][nonce];
        address user = nonceUser[msg.sender][nonce];
        uint256 amount = nonceLocked[msg.sender][nonce];
        nonceLocked[msg.sender][nonce] = 0;
        unclaimedRewards[token] -= amount;
        IERC20(token).transfer(user, amount);
        emit NonceUnlocked(user, token, amount);
    }

    function claimableRewards(
        address user
    ) public view returns (uint256[] memory total) {
        total = new uint256[](playableTokens.length);
        for (uint256 i = 0; i < playableTokens.length; i++) {
            total[i] = unclaimedRewardsPerUser[user][playableTokens[i]];
        }
    }

    function claimRewards() external nonReentrant {
        address[] memory _games = gamesWithRewards[msg.sender];
        for (uint256 i = 0; i < _games.length; i++) {
            IScratchGames(_games[i]).scratchAndClaimAllCardsTreasury();
        }
        for (uint256 i = 0; i < playableTokens.length; i++) {
            address token = playableTokens[i];
            uint256 amount = unclaimedRewardsPerUser[msg.sender][token];
            if (amount > 0) {
                unclaimedRewardsPerUser[msg.sender][token] = 0;
                unclaimedRewards[token] -= amount;
                bool success = IERC20(token).transfer(msg.sender, amount);
                require(success, "ScratchEmTreasury: transfer failed");
                emit RewardsClaimed(msg.sender, token, amount);
            }
        }
    }

    function claimRewardsByGame(
        address user,
        address token,
        uint amount
    ) external nonReentrant onlyPlayableToken(token) onlyGame {
        require(
            unclaimedRewardsPerUser[user][token] >= amount,
            "ScratchEmTreasury: not enough unclaimed rewards"
        );
        unclaimedRewards[token] -= amount;
        unclaimedRewardsPerUser[user][token] -= amount;
        bool success = IERC20(token).transfer(user, amount);
        require(success, "ScratchEmTreasury: transfer failed");
        emit RewardsClaimed(user, token, amount);
    }

    function scratchAllCardsTreasury() external {
        address[] memory _games = gamesWithRewards[msg.sender];
        for (uint256 i = 0; i < _games.length; i++) {
            IScratchGames(_games[i]).scratchAllCardsTreasury();
        }
    }

    function burnAllCardsTreasury() external {
        address[] memory _games = gamesWithRewards[msg.sender];
        for (uint256 i = 0; i < _games.length; i++) {
            IScratchGames(_games[i]).burnAllCardsTreasury();
        }
    }

    /// DEPOSIT AND WITHDRAW

    function deposit(
        address token,
        uint256 amount
    ) external onlyPlayableToken(token) {
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "ScratchEmTreasury: transfer failed");
        emit Deposit(token, amount);
    }

    function withdraw(
        address token,
        uint256 amount
    ) external onlyOwner onlyPlayableToken(token) {
        require(amount > 0, "ScratchEmTreasury: amount must be greater than 0");
        uint balance = IERC20(token).balanceOf(address(this));
        if (token == address(SEMT)) {
            require(
                balance - unclaimedRewards[token] - lockedSEMT >= amount,
                "ScratchEmTreasury: not enough balance"
            );
        } else {
            require(
                balance - unclaimedRewards[token] >= amount,
                "ScratchEmTreasury: not enough balance"
            );
        }
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "ScratchEmTreasury: transfer failed");
        emit Withdraw(token, amount);
    }

    function withdrawAll(
        address token
    ) external onlyOwner onlyPlayableToken(token) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        bool success;
        if (token == address(SEMT)) {
            require(
                balance - unclaimedRewards[token] - lockedSEMT >= 0,
                "ScratchEmTreasury: not enough balance"
            );
            success = IERC20(token).transfer(
                msg.sender,
                balance - unclaimedRewards[token] - lockedSEMT
            );
        } else {
            require(
                balance - unclaimedRewards[token] >= 0,
                "ScratchEmTreasury: not enough balance"
            );
            success = IERC20(token).transfer(
                msg.sender,
                balance - unclaimedRewards[token]
            );
        }
        require(success, "ScratchEmTreasury: transfer failed");
        emit Withdraw(token, balance - unclaimedRewards[token]);
    }
}