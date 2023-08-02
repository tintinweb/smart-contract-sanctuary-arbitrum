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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.17;

contract RockPaperScissors is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Moves {
        None,
        Rock,
        Paper,
        Scissors
    }

    enum Stages {
        None,
        WaitForOpponent,
        WaitForReveal,
        ReadyForFinalize,
        Draw,
        DrawWaitForOpponent,
        Done
    }

    /**
     * @dev Winner outcomes
     */
    enum WinnerOutcomes {
        None,
        PlayerA,
        PlayerB,
        Draw
    }

    struct Player {
        address playerAddress;
        Moves move;
        bytes32 encrMove;
    }

    /**
     * @dev game metadata
     */
    struct GameData {
        uint256 gameId;
        address currency;
        uint256 gameBalance;
        Player playerA;
        Player playerB;
        Stages stage;
        WinnerOutcomes winner;
        uint64 revealDeadline;
        bool active;
    }

    /// --- Variables
    uint256 gameIds;
    /// @dev fee amount in percent (BP 1000 = 10%)
    uint256 public fee;
    /// @dev min bet amount in wei
    uint256 public minBetAmount;
    /// @dev deadline for reveal move in game
    uint64 public revealTime;

    /// --- mappings
    /**
     * @notice Keep game data
     *
     * uint256 = gameId
     * GameData = game metadata
     */
    mapping(uint256 => GameData) public gamesData;

    /**
     * @notice Show if game has active draw status
     * uint256 = gameId
     * bool = status draw
     */
    mapping(uint256 => bool) public draws;

    /// --- errors
    error EarlyCall();
    error OnlyCreator();
    error ZeroAddress();
    error InvalidMove();
    error NotActiveDraw();
    error AlreadyRevealed();
    error AlreadyConnected();
    error InvalidBetAmount();
    error IncorrectGameStage();
    error AlreadyMovedInDraw();
    error RevealDeadlinePassed();
    error InvalidStageForReveal();
    error InvalidStageForJoinGame();
    error CallerNotGameParticipant();
    error NonActiveOrNonexistentGame();
    error InvalidData(bytes32, bytes32);
    error WrongSender();

    /// --- events
    event RevealTimeSettled(uint256 indexed timestamp);
    event MinBetValueSettled(uint256 indexed minBetAmount);
    event FeeAmountWithdrawn(uint256 indexed amount, address indexed currency);
    event TokenTransferred(
        address indexed from,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event YouHaveDraw(uint256 indexed id);
    event FeeAmountSettled(uint256 indexed id);
    event DrawReadyForReveal(
        uint256 indexed id,
        address indexed playerA,
        address indexed playerB
    );
    event GameDataAdded(uint256 indexed id, address indexed creator);
    event PlayerConnectedToGame(
        uint256 indexed id,
        address indexed player,
        address playerA,
        address playerB
    );
    event GameCanceled(
        uint256 indexed id,
        address indexed player,
        uint256 indexed amount
    );
    event GameCreated(
        uint256 indexed id,
        address indexed creator,
        address indexed currency
    );
    event GameBalanceWithdrawn(
        uint256 indexed id,
        address indexed receiver,
        uint256 indexed amount
    );
    event MoveRevealed(
        uint256 indexed id,
        address indexed player,
        Moves indexed value,
        address playerA,
        address playerB
    );
    event HiddenMoveAddedToDraw(
        uint256 indexed id,
        address indexed playerAddress,
        bytes32 indexed hiddenMove,
        address playerA,
        address playerB
    );
    event TechnicalDefeatWithdrawn(
        uint256 indexed id,
        address indexed sender,
        address player,
        uint256 indexed paybackAmount
    );
    event JointTechnicalDefeatWithdrawn(
        uint256 indexed id,
        address indexed sender,
        uint256 indexed amount,
        address playerA,
        address playerB
    );
    event WinnerPaid(
        uint256 indexed id,
        address indexed winner,
        uint256 amount,
        address indexed secondPlayer,
        uint256 fee,
        address currency
    );

    /// --- modifiers
    /// @dev check if game is active
    modifier isGameExist(uint256 _gameId) {
        if (!gamesData[_gameId].active) revert NonActiveOrNonexistentGame();
        _;
    }

    /// @dev check if caller is game participant
    modifier onlyParticipant(uint256 _gameId) {
        address _playerA;
        address _playerB;
        (_playerA, _playerB) = getGamePlayersAddress(_gameId);

        if (_playerA != msg.sender && _playerB != msg.sender)
            revert CallerNotGameParticipant();
        _;
    }

    /// --- Constructor
    constructor(
        uint64 _revealTime,
        uint256 _fee,
        uint256 _minBetAmount,
        address _owner
    ) ReentrancyGuard() {
        setRevealTime(_revealTime);
        setFee(_fee);
        setMinBetAmount(_minBetAmount);
        setOwner(_owner);
    }

    /**
     * @dev Create new instance of game and add hashed PlayerA move data.
     * @param hiddenMove hash of caller move generated uot of blockchain
     * @param currency address of token or address(0) for ETH
     * @param amount bet amount
     *
     * @notice
     * hiddenMove === keccak256(abi.encodePacked(salt, move, msg.sender))
     * where:
     * salt === secret created by caller
     * move === caller choice from list "Rock", "Paper", "Scissors" only
     * msg.sender === sender address
     */

    function createGame(
        bytes32 hiddenMove,
        address currency,
        uint256 amount,
        address playerB
    ) external {
        // check if amount > minBetTokenAmount
        if (amount < minBetAmount) revert InvalidBetAmount();

        // check if currency is not a zeroAddress
        if (currency == address(0)) revert ZeroAddress();

        // protect from private game self-connection
        if (msg.sender == playerB) revert AlreadyConnected();

        // return new game id
        uint256 gameId = _addGameData(
            msg.sender,
            hiddenMove,
            currency,
            amount,
            playerB
        );

        // transfer tokens to contract
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);

        emit GameCreated(gameId, msg.sender, currency);
    }

    /// @dev Add game data to storage
    function _addGameData(
        address _creator,
        bytes32 _hiddenMove,
        address _currency,
        uint256 _amount,
        address _playerB
    ) internal returns (uint256) {
        gameIds ++;
        uint256 newGameId = gameIds;

        GameData storage data = gamesData[newGameId];
        data.gameId = newGameId;
        data.currency = _currency;
        data.gameBalance = _amount;

        data.playerA = Player({
            playerAddress: _creator,
            move: Moves.None,
            encrMove: _hiddenMove
        });

        data.stage = Stages.WaitForOpponent;
        data.active = true;

        gamesData[newGameId] = data;

        if (_playerB != address(0)) {
            data.playerB.playerAddress = _playerB;

            emit CreatedPrivateGame(newGameId, _creator, _playerB);
        }

        emit GameDataAdded(newGameId, _creator);

        return newGameId;
    }

    event CreatedPrivateGame(
        uint256 indexed id,
        address indexed playerA,
        address indexed playerB
    );

    /**
     * @dev Added PlayerB to existing game.
     *
     * @param gameId game Id which caller want participate.
     * @param hiddenMove hash of caller move generated uot of blockchain.
     *
     * @notice
     * hiddenMove === keccak256(abi.encodePacked(salt, move, msg.sender))
     * where:
     * salt === secret created by caller
     * move === caller choice from list "Rock", "Paper", "Scissors" only
     * msg.sender === sender address
     */
    function connectToGame(
        uint256 gameId,
        bytes32 hiddenMove
    ) external isGameExist(gameId) {
        GameData storage data = gamesData[gameId];
        // check game stage
        if (Stages.WaitForOpponent != data.stage)
            revert InvalidStageForJoinGame();

        // protect from self-connection
        if (msg.sender == data.playerA.playerAddress) revert AlreadyConnected();

        // add second player data to game data
        if (data.playerB.playerAddress == address(0)) {
            data.playerB.playerAddress = msg.sender;
            _addPlayerDataToGame(gameId, hiddenMove);
        } else {
            if (data.playerB.playerAddress != msg.sender) revert WrongSender();
            _addPlayerDataToGame(gameId, hiddenMove);
        }

        // transfer tokens to contract
        IERC20(data.currency).safeTransferFrom(
            msg.sender,
            address(this),
            data.gameBalance
        );

        data.gameBalance += data.gameBalance;

        emit PlayerConnectedToGame(
            gameId,
            msg.sender,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );
    }

    /// @dev Add player data to game data
    function _addPlayerDataToGame(
        uint256 _gameId,
        bytes32 _hiddenMove
    ) internal {
        GameData storage data = gamesData[_gameId];

        data.playerB.move = Moves.None;
        data.playerB.encrMove = _hiddenMove;
        data.stage = Stages.WaitForReveal;
        data.revealDeadline = uint64(block.timestamp + revealTime);

        gamesData[_gameId] = data;
    }

    /**
     * @notice Reveal data.
     * @param move caller choice from list "Rock", "Paper", "Scissors" only
     * @param salt secret created by caller.
     */
    function revealMove(
        uint256 gameId,
        Moves move,
        string memory salt
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        // check move
        if (move != Moves.Rock && move != Moves.Paper && move != Moves.Scissors)
            revert InvalidMove();
        // check stage
        if (Stages.WaitForReveal != gamesData[gameId].stage)
            revert InvalidStageForReveal();
        // check deadline
        if (block.timestamp > gamesData[gameId].revealDeadline)
            revert RevealDeadlinePassed();

        // generate incr move for sender
        bytes32 encrMove = keccak256(abi.encodePacked(salt, move, msg.sender));

        Stages _stage = _revealPlayerMove(gameId, encrMove, move);

        if (_stage == Stages.ReadyForFinalize) {
            WinnerOutcomes winner = getWhoWon(gameId);
            if (winner == WinnerOutcomes.Draw) {
                draws[gameId] = true;
                gamesData[gameId].stage = Stages.Draw;

                delete gamesData[gameId].playerA.encrMove;
                delete gamesData[gameId].playerB.encrMove;
                delete gamesData[gameId].playerA.move;
                delete gamesData[gameId].playerB.move;

                emit YouHaveDraw(gameId);
            } else {
                _finalizeGame(gameId, gamesData[gameId], winner);
            }
        }
    }

    /// @dev Reveal player move & return new stage after second reveal
    function _revealPlayerMove(
        uint256 gameId,
        bytes32 encrMove,
        Moves _move
    ) private returns (Stages stage) {
        GameData storage data = gamesData[gameId];
        if (msg.sender == data.playerA.playerAddress) {
            if (data.playerA.move != Moves.None) revert AlreadyRevealed();
            if (encrMove != data.playerA.encrMove)
                revert InvalidData(encrMove, data.playerA.encrMove);
            // add move to game data
            data.playerA.move = _move;
        } else {
            if (data.playerB.move != Moves.None) revert AlreadyRevealed();
            if (encrMove != data.playerB.encrMove)
                revert InvalidData(encrMove, data.playerB.encrMove);
            data.playerB.move = _move;
        }

        if (
            data.playerA.move != Moves.None && data.playerB.move != Moves.None
        ) {
            data.stage = Stages.ReadyForFinalize;
        }

        gamesData[gameId] = data;

        emit MoveRevealed(
            gameId,
            msg.sender,
            _move,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );

        return data.stage;
    }

    /// @dev Finalize game & transfer funds to winner & fee to owner. If draw - init draw stage
    function _finalizeGame(
        uint256 gameId,
        GameData storage data,
        WinnerOutcomes winner
    ) internal {
        data.active = false;

        uint256 feeAmount = (data.gameBalance * fee) / 10000;
        uint256 winnerPot = data.gameBalance - feeAmount;

        data.gameBalance = 0;

        // get winner address
        address winnerAddress = winner == WinnerOutcomes.PlayerA
            ? data.playerA.playerAddress
            : data.playerB.playerAddress;
        // get lose address
        address loseAddress = winner == WinnerOutcomes.PlayerA
            ? data.playerB.playerAddress
            : data.playerA.playerAddress;

        if (draws[gameId]) {
            delete draws[gameId];
        }

        data.winner = winner;
        data.stage = Stages.Done;

        gamesData[gameId] = data;

        // transfer feeAmount to owner address
        _safeTransferToken(gamesData[gameId].currency, owner(), feeAmount);
        emit FeeAmountWithdrawn(feeAmount, gamesData[gameId].currency);

        // transfer tokens to winner
        _safeTransferToken(
            gamesData[gameId].currency,
            winnerAddress,
            winnerPot
        );

        emit WinnerPaid(
            gameId,
            winnerAddress,
            winnerPot,
            loseAddress,
            feeAmount,
            data.currency
        );
    }

    /// @dev Add encrypted move to draw game. If both players added moves - init reveal stage
    function addDrawMove(
        uint256 gameId,
        bytes32 newHiddenMove
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        if (!draws[gameId]) revert NotActiveDraw();
        GameData memory data = gamesData[gameId];

        if (msg.sender == data.playerA.playerAddress) {
            // check if player already moved
            if (data.playerA.encrMove != bytes32(0))
                revert AlreadyMovedInDraw();

            data.playerA.encrMove = newHiddenMove;
            data.stage = Stages.DrawWaitForOpponent;

            if (data.playerB.encrMove != bytes32(0)) {
                data.stage = Stages.WaitForReveal;
                emit DrawReadyForReveal(
                    gameId,
                    data.playerA.playerAddress,
                    data.playerB.playerAddress
                );
            }
        } else {
            // check if player already moved
            if (data.playerB.encrMove != bytes32(0))
                revert AlreadyMovedInDraw();

            data.playerB.encrMove = newHiddenMove;
            data.stage = Stages.DrawWaitForOpponent;

            if (data.playerA.encrMove != bytes32(0)) {
                data.stage = Stages.WaitForReveal;
                emit DrawReadyForReveal(
                    gameId,
                    data.playerA.playerAddress,
                    data.playerB.playerAddress
                );
            }
        }
        gamesData[gameId] = data;

        emit HiddenMoveAddedToDraw(
            gameId,
            msg.sender,
            newHiddenMove,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );
    }

    /**
     * @dev Cancel game by ID and return money to player A.
     *
     * @param gameId specific gameId for cancel
     */
    function cancelGame(uint256 gameId) external isGameExist(gameId) {
        if (gamesData[gameId].playerA.playerAddress != msg.sender)
            revert OnlyCreator();

        _cancelGame(gameId);
    }

    ///@dev Cancel game by ID and return money to game creator. No fee.
    function _cancelGame(uint256 gameId) internal {
        GameData memory data = gamesData[gameId];

        if (data.stage != Stages.WaitForOpponent) revert IncorrectGameStage();

        uint256 amount = gamesData[gameId].gameBalance;

        data.gameBalance = 0;
        data.stage = Stages.Done;
        data.active = false;

        gamesData[gameId] = data;

        _withdrawGameBalance(gameId, amount, msg.sender);

        emit GameCanceled(gameId, msg.sender, amount);
    }

    /**
     * @dev technical defeat by timeout
     */
    function technicalDefeat(
        uint256 gameId
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        if (gamesData[gameId].playerB.playerAddress == address(0)) {
            _cancelGame(gameId);
            return;
        }

        _technicalDefeat(gameId);
    }

    ///@dev technical defeat by timeout expirations
    function _technicalDefeat(uint256 gameId) internal {
        GameData memory data = gamesData[gameId];
        if (block.timestamp < data.revealDeadline) revert EarlyCall();

        uint256 feeAmount = (data.gameBalance * fee) / 10000;
        uint256 payBackAmount = data.gameBalance - feeAmount;

        // transfer feeAmount to owner address
        _safeTransferToken(gamesData[gameId].currency, owner(), feeAmount);
        emit FeeAmountWithdrawn(feeAmount, gamesData[gameId].currency);

        data.gameBalance = 0;
        data.stage = Stages.Done;
        data.active = false;

        gamesData[gameId] = data;

        if (
            data.playerB.move == Moves.None && data.playerA.move == Moves.None
        ) {
            uint256 eachPlayerPayBackAmount = payBackAmount / 2;

            _withdrawGameBalance(
                gameId,
                eachPlayerPayBackAmount,
                data.playerA.playerAddress
            );
            _withdrawGameBalance(
                gameId,
                eachPlayerPayBackAmount,
                data.playerB.playerAddress
            );

            emit JointTechnicalDefeatWithdrawn(
                gameId,
                msg.sender,
                eachPlayerPayBackAmount,
                data.playerA.playerAddress,
                data.playerB.playerAddress
            );
        } else {
            address winnerAddress = data.playerA.move == Moves.None
                ? data.playerB.playerAddress
                : data.playerA.playerAddress;

            // technical defeat winner
            gamesData[gameId].winner = winnerAddress ==
                data.playerA.playerAddress
                ? WinnerOutcomes.PlayerA
                : WinnerOutcomes.PlayerB;

            _withdrawGameBalance(gameId, payBackAmount, winnerAddress);

            emit TechnicalDefeatWithdrawn(
                gameId,
                msg.sender,
                winnerAddress,
                payBackAmount
            );
        }
    }

    /**
     * @dev Withdraw game balance to player
     *
     * @param gameId specific gameId for withdraw
     */
    function _withdrawGameBalance(
        uint256 gameId,
        uint256 amount,
        address receiver
    ) internal {
        _safeTransferToken(gamesData[gameId].currency, receiver, amount);

        emit GameBalanceWithdrawn(gameId, receiver, amount);
    }

    /// @dev return game wi address by game id
    function _calcWinner(
        Moves movePlayerA,
        Moves movePlayerB
    ) private pure returns (WinnerOutcomes winner) {
        if (movePlayerA == movePlayerB) {
            winner = WinnerOutcomes.Draw;
        } else if (
            (movePlayerA == Moves.Rock && movePlayerB == Moves.Scissors) ||
            (movePlayerA == Moves.Paper && movePlayerB == Moves.Rock) ||
            (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)
        ) {
            winner = WinnerOutcomes.PlayerA;
        } else {
            winner = WinnerOutcomes.PlayerB;
        }

        return winner;
    }

    /// @dev return active games ids in range for pagination by game id
    function getActiveGamesIds(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](to - from);
        uint256 counter = 0;

        for (uint256 i = from; i < to; i++) {
            if (gamesData[i].active) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /// @dev return active games ids in range for pagination by game id without Player B
    function getActiveGamesWithoutPlayerB(
        uint256 from,
        uint256 to
    ) public view returns (GameData[] memory) {
        GameData[] memory _gamesData = new GameData[](to - from);
        uint256 counter = 0;

        for (uint256 i = from; i <= to; i++) {
            (, address playerB) = getGamePlayersAddress(i);
            if (gamesData[i].active && playerB == address(0)) {
                _gamesData[counter] = getGameData(i);
                counter++;
            }
        }
        return _gamesData;
    }

    /// @dev return games data for pagination by game id in range
    function getGamesData(
        uint256 from,
        uint256 to
    ) public view returns (GameData[] memory) {
        GameData[] memory _gamesData = new GameData[](to + 1 - from);
        uint256 counter = 0;

        for (uint256 i = from; i <= to; i++) {
            _gamesData[counter] = getGameData(i);
            counter++;
        }

        return _gamesData;
    }

    /// @dev get game players address
    function getGamePlayersAddress(
        uint256 gameId
    ) public view returns (address playerA, address playerB) {
        GameData memory gameData = gamesData[gameId];
        playerA = gameData.playerA.playerAddress;
        playerB = gameData.playerB.playerAddress;

        return (playerA, playerB);
    }

    /// @dev return participant's moves of the game
    function getGamePlayersMoves(
        uint256 gameId
    ) public view returns (Moves moveA, Moves moveB) {
        return (gamesData[gameId].playerA.move, gamesData[gameId].playerB.move);
    }

    /// @dev return game stage
    function getGameStage(uint256 gameId) public view returns (Stages stage) {
        return gamesData[gameId].stage;
    }

    /// @dev return all data of the game
    function getGameData(uint256 gameId) public view returns (GameData memory) {
        return gamesData[gameId];
    }

    /// @dev return current game id (last created game)
    function getCurrentGameId() public view returns (uint256) {
        return gameIds;
    }

    /// @dev return game balance
    function getGameBalance(uint256 gameId) public view returns (uint256) {
        return (gamesData[gameId].gameBalance);
    }

    /// @dev return if game is active
    function isGameActive(uint256 gameId) public view virtual returns (bool) {
        return gamesData[gameId].active;
    }

    /// @dev return winner of the game
    function getWhoWon(
        uint256 gameId
    ) public view returns (WinnerOutcomes winner) {
        GameData memory game = gamesData[gameId];
        winner = _calcWinner(game.playerA.move, game.playerB.move);

        return winner;
    }

    /// --- Owner methods ---
    /// @dev set min bet amount
    function setMinBetAmount(uint256 _minBetAmount) public onlyOwner {
        if (_minBetAmount <= 0 wei) revert InvalidBetAmount();

        minBetAmount = _minBetAmount;

        emit MinBetValueSettled(_minBetAmount);
    }

    /// --- Owner methods ---
    /// @dev set owner
    function setOwner(address _owner) public onlyOwner {
        transferOwnership(_owner);
    }

    /**
     * @dev Contract owner initiate technical defeat by timeout.
     *
     * @param _gameIds array of game ids
     */
    function technicalDefeatOwner(
        uint256[] memory _gameIds
    ) external onlyOwner {
        for (uint256 i = 0; i < _gameIds.length; i++) {
            _technicalDefeat(_gameIds[i]);
        }
    }

    /**
     * @dev Set limit amount of game for user
     * @param newFee percent of fee for game
     */
    function setFee(uint256 newFee) public onlyOwner {

        fee = newFee;

        emit FeeAmountSettled(newFee);
    }

    /**
     * @dev Set current reveal time
     * @param newTime time of deadline for reveal
     */
    function setRevealTime(uint64 newTime) public onlyOwner {
        revealTime = newTime;

        emit RevealTimeSettled(revealTime);
    }

    function _safeTransferToken(
        address _currency,
        address _to,
        uint256 _amount
    ) private nonReentrant {
        if (_to == address(0)) revert ZeroAddress();
        IERC20(_currency).safeTransfer(_to, _amount);

        emit TokenTransferred(msg.sender, _to, _currency, _amount);
    }
}