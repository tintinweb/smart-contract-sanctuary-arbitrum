/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// File: contracts/Address.sol



pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
// File: contracts/IERC20.sol



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// File: contracts/SafeERC20.sol



pragma solidity ^0.8.0;




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
// File: contracts/ReentrancyGuard.sol



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
     * by making the `nonReentrant` function external, and make it call a
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
// File: contracts/Context.sol



pragma solidity ^0.8.0;

/*
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
// File: contracts/Pausable.sol



pragma solidity ^0.8.0;

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// File: contracts/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/Prediction-DICE.sol


pragma solidity ^0.8.0;









/**
 * @title ABPrediction
 */
contract ABPrediction is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    address public adminAddress; // address of the admin, power user and treasurer
    address public operatorAddress; // address of the operator, empowered to create and resolve markets

    uint256 public minGuessAmount; // minimum guessing amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public currentRound = 0;

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

    mapping(uint256 => mapping(address => GuessInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;

    enum Position {
        Push,
        A,
        B
    }

    enum RoundStatus {
        Active,
        Locked,
        Closed
    }

    struct Round {
        uint256 roundId;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 totalAmountGuessed;
        uint256 aAmount;
        uint256 bAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        string description;
        Position closeResult;
        RoundStatus roundStatus;
    }

    struct GuessInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event GuessA(address indexed sender, uint256 indexed epoch, uint256 amount);
    event GuessB(address indexed sender, uint256 indexed epoch, uint256 amount);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event ActivateRound (address indexed sender, uint256 indexed roundId, string description);
    event LockRound(uint256 indexed roundId, RoundStatus status);
    event EndRound(uint256 indexed roundId, RoundStatus status, Position result);

    event NewAdminAddress(address admin);
    event NewMinGuessAmount(uint256 indexed epoch, uint256 minGuessAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOperatorAddress(address operator);

    event Pause(uint256 indexed timestamp);

    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );

    event StartRound(uint256 indexed epoch);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
    * @notice Constructor
    * @param _adminAddress: admin address
    * @param _operatorAddress: operator address
    * @param _minGuessAmount: minimum required to make a guess amounts (in wei)
    * @param _treasuryFee: treasury fee (1000 = 10%)
    */
    constructor(
        IERC20 _token,
        address _adminAddress,
        address _operatorAddress,
        uint256 _minGuessAmount,
        uint256 _treasuryFee
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        token = _token;
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        minGuessAmount = _minGuessAmount;
        treasuryFee = _treasuryFee;
    }

    /**
    * @notice guess A position
    * @param _roundId: roundId
    */
    function guessA(uint256 _roundId, uint256 _amount) external nonReentrant notContract {
        require(rounds[_roundId].roundStatus == RoundStatus.Active, "round is not active");
        require(_guessable(_roundId), "Round not guessable");
        require(_amount >= minGuessAmount, "Guess amount must be greater than minGuessAmount");    
        require(ledger[_roundId][msg.sender].amount == 0, "Can only guess once per round");   
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[_roundId];
        round.totalAmountGuessed = round.totalAmountGuessed + amount;
        round.aAmount = round.aAmount + amount;

        // Update user data
        GuessInfo storage guessInfo = ledger[_roundId][msg.sender];
        guessInfo.position = Position.A;
        guessInfo.amount = amount;
        userRounds[msg.sender].push(_roundId);

        emit GuessA(msg.sender, _roundId, amount);
    }


    /**
    * @notice guess B position
    * @param _roundId: roundId
    */
    function guessB(uint256 _roundId, uint256 _amount) external nonReentrant notContract {
        require(rounds[_roundId].roundStatus == RoundStatus.Active, "round is not active");
        require(_guessable(_roundId), "Round not guessable");
        require(_amount >= minGuessAmount, "guess amount must be greater than minGuessAmount");
        require(ledger[_roundId][msg.sender].amount == 0, "Can only guess once per round");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Update round data
        uint256 amount = _amount;
        Round storage round = rounds[_roundId];
        round.totalAmountGuessed = round.totalAmountGuessed + amount;
        round.bAmount = round.bAmount + amount;

        // Update user data
        GuessInfo storage guessInfo = ledger[_roundId][msg.sender];
        guessInfo.position = Position.B;
        guessInfo.amount = amount;
        userRounds[msg.sender].push(_roundId);

        emit GuessB(msg.sender, _roundId, amount);
    }

    /**
    * @notice Claim reward for an array of rounds
    * @param _roundIds: array of rounds
    */
    function claim(uint256[] calldata _roundIds) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < _roundIds.length; i++) {
            Round memory thisRound = rounds[_roundIds[i]];
            require(thisRound.startTimestamp != 0, "Round has not started");
            require(block.timestamp > thisRound.closeTimestamp, "Round has not ended");
            require(thisRound.roundStatus == RoundStatus.Closed, "Round is not closed");
            uint256 addedReward = 0;

            // Round valid, claim rewards
            if ((thisRound.closeResult == Position.A) || (thisRound.closeResult == Position.B)){
                require(claimable(_roundIds[i], msg.sender), "Not eligible for claim");
                addedReward = (ledger[_roundIds[i]][msg.sender].amount * thisRound.rewardAmount) / thisRound.rewardBaseCalAmount;
            }
            // Round pushed, refund guess amount
            else {
                require(refundable(_roundIds[i], msg.sender), "Not eligible for refund");
                addedReward = ledger[_roundIds[i]][msg.sender].amount;
            }

            ledger[_roundIds[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, _roundIds[i], addedReward);
        }

        if (reward > 0) {
            token.safeTransfer(msg.sender, reward);
        }
    }

    /**
    * @notice Activate round
    * @param _description: what are users guessing about?
    * @param _h: if not open, amount of hours until market locks
    * @param _m: if not open, amount of minutes until market locks
    */
    function activateRound(string memory _description, uint256 _h, uint256 _m) external onlyOperator {
        Round storage thisRound = rounds[currentRound];
        thisRound.roundId = currentRound;
        thisRound.startTimestamp = block.timestamp;
        thisRound.lockTimestamp = block.timestamp + ((_h * 1 hours) + (_m * 1 minutes));
        thisRound.roundStatus = RoundStatus.Active;
        thisRound.description = _description;
        thisRound.totalAmountGuessed = 0;
        emit ActivateRound(msg.sender, currentRound, _description);
        currentRound += 1;
    }

    /**
    * @notice Lock round
    * @param _roundId: id of round to lock
    */
    function lockRound(uint256 _roundId) external onlyOperator {
        require(_roundId <= currentRound, "round doesn't exist");
        require(rounds[_roundId].roundStatus == RoundStatus.Active, "round is not active");
        require(rounds[_roundId].startTimestamp != 0, "Can only lock round after round has started");
        Round storage round = rounds[_roundId];
        round.lockTimestamp = block.timestamp;
        round.roundStatus = RoundStatus.Locked;
        emit LockRound(_roundId, round.roundStatus);
    }

    /**
    * @notice End round
    * @param _roundId: roundId
    * @param _finalPosition: result of bet
    */
    function endRound(uint256 _roundId, Position _finalPosition) external onlyOperator {
        require(block.timestamp >= rounds[_roundId].lockTimestamp, "Can only end round after lockTimestamp");
        require(rounds[_roundId].roundStatus == RoundStatus.Locked, "Round active or already closed");
        Round storage round = rounds[_roundId];
        round.roundStatus = RoundStatus.Closed;
        round.closeResult = _finalPosition;
        round.closeTimestamp = block.timestamp;
        _calculateRewards(_roundId);
        emit EndRound(_roundId, round.roundStatus, round.closeResult);
    }

    /**
    * @notice Claim all rewards in treasury
    * @dev Callable by admin
    */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        token.safeTransfer(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
    * @notice Set minGuessAmount
    * @dev Callable by admin
    */
    function setMinGuessAmount(uint256 _minGuessAmount) external onlyAdmin {
        require(_minGuessAmount != 0, "Must be more than 0");
        minGuessAmount = _minGuessAmount;

        emit NewMinGuessAmount(currentRound, minGuessAmount);
    }

    /**
    * @notice Set operator address
    * @dev Callable by admin
    */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    /**
    * @notice Set treasury fee
    * @dev Callable by admin
    */
    function setTreasuryFee(uint256 _treasuryFee) external onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentRound, treasuryFee);
    }

    /**
    * @notice It allows the owner to recover tokens sent to the contract by mistake
    * @param _token: token address
    * @param _amount: token amount
    * @dev Callable by owner
    */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(token), "Cannot be base token address");
        IERC20(_token).safeTransfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

    /**
    * @notice Set admin address
    * @dev Callable by owner
    */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
    * @notice Returns all rounds
    */
    function getRounds() public view returns(Round[] memory) {
        Round[] memory allRounds = new Round[](currentRound);
        for(uint256 i = 0; i < currentRound; i++) {
            Round memory r = rounds[i];
            allRounds[i] = r;
        }
        return (allRounds);
    }

    /**
    * @notice Returns Round struct for each specific round
    * @param _rounds: Which rounds information to return
    */
    function getSpecificRounds(uint256[] memory _rounds) public view returns(Round[] memory) {
        Round[] memory specificRounds = new Round[](_rounds.length);
        for (uint256 i = 0; i < _rounds.length; i++) {
            Round memory r = rounds[_rounds[i]];
            specificRounds[i] = r;
        }
        return (specificRounds);
    }

    /**
    * @notice Returns round epochs and guess information for a user that has participated
    * @param user: user address
    * @param cursor: cursor
    * @param size: size
    */
    function getUserRounds(address user, uint256 cursor, uint256 size)
        external
        view
        returns (
            uint256[] memory,
            GuessInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        GuessInfo[] memory guessInfo = new GuessInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            guessInfo[i] = ledger[values[i]][user];
        }

        return (values, guessInfo, cursor + length);
    }

    /**
    * @notice Returns round epochs length
    * @param _user: user address
    */
    function getUserRoundsLength(address _user) external view returns (uint256) {
        return userRounds[_user].length;
    }

    /**
    * @notice Check if user is eligible for rewards for this round
    * @param _roundId: _roundId
    * @param _user: user address
    */
    function claimable(uint256 _roundId, address _user) public view returns (bool) {
        GuessInfo memory guessInfo = ledger[_roundId][_user];
        Round memory round = rounds[_roundId];
        if (round.closeResult == Position.Push) {
            return false;
        }
        return
            guessInfo.amount != 0 &&
            !guessInfo.claimed &&
            ((round.closeResult == Position.A && guessInfo.position == Position.A) ||
                (round.closeResult == Position.B && guessInfo.position == Position.B));
    }

    /**
    * @notice Check if user is eligible for refund for this round
    * @param _roundId: _roundIds
    * @param _user: user address
    */
    function refundable(uint256 _roundId, address _user) public view returns (bool) {
        GuessInfo memory guessInfo = ledger[_roundId][_user];
        Round memory round = rounds[_roundId];
        return
            !guessInfo.claimed &&
            block.timestamp > round.closeTimestamp &&
            round.closeResult == Position.Push &&
            guessInfo.amount != 0;
    }

    /**
    * @notice Calculate rewards for round
    * @param _epoch: epoch
    */
    function _calculateRewards(uint256 _epoch) internal {
        require(rounds[_epoch].rewardBaseCalAmount == 0 && rounds[_epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = rounds[_epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        // A wins
        if (round.closeResult == Position.A) {
            rewardBaseCalAmount = round.aAmount;
            treasuryAmt = (round.totalAmountGuessed * treasuryFee) / 10000;
            rewardAmount = round.totalAmountGuessed - treasuryAmt;
        }
        // B wins
        else if (round.closeResult == Position.B) {
            rewardBaseCalAmount = round.bAmount;
            treasuryAmt = (round.totalAmountGuessed * treasuryFee) / 10000;
            rewardAmount = round.totalAmountGuessed - treasuryAmt;
        }
        // No one wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = 0;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(_epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt);
    }

    /**
    * @notice Determine if a round is valid for receiving guesss
    * Round must have started and locked
    * Current timestamp must be within startTimestamp and closeTimestamp
    */
    function _guessable(uint256 _epoch) internal view returns (bool) {
        return
            rounds[_epoch].startTimestamp != 0 &&
            block.timestamp > rounds[_epoch].startTimestamp &&
            block.timestamp < rounds[_epoch].lockTimestamp &&
            rounds[_epoch].roundStatus == RoundStatus.Active;
    }

    /**
    * @notice Transfer underlying network token ETH on ETH/MATIC on POLYGON etc. (native token) in a safe way
    * @param to: address to transfer native token to
    * @param value: token amount to transfer (in wei)
    */
    function _safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TOKEN_TRANSFER_FAILED");
    }

    /**
    * @notice Returns true if `account` is a contract.
    * @param account: account address
    */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}